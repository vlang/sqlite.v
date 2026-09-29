@[translated]
module main

struct SorterFile {
	pFd  &Sqlite3_file
	iEof I64
}

struct SorterList {
	pList   &SorterRecord
	aMemory &U8
	szPMA   I64
}

struct MergeEngine {
	nTree  int
	pTask  &SortSubtask
	aTree  &int
	aReadr &PmaReader
}

type SorterCompare = fn (&SortSubtask, &int, voidptr, int, voidptr, int) int

struct SortSubtask {
	pThread   &SQLiteThread
	bDone     int
	nPMA      int
	pSorter   &VdbeSorter
	pUnpacked &UnpackedRecord
	list      SorterList
	xCompare  SorterCompare
	file      SorterFile
	file2     SorterFile
	nSpill    U64
}

struct VdbeSorter {
	mnPmaSize   int
	mxPmaSize   int
	mxKeysize   int
	pgsz        int
	pReader     &PmaReader
	pMerger     &MergeEngine
	db          &Sqlite3
	pKeyInfo    &KeyInfo
	pUnpacked   &UnpackedRecord
	list        SorterList
	iMemory     int
	nMemory     int
	bUsePMA     U8
	bUseThreads U8
	iPrev       U8
	nTask       U8
	typeMask    U8
	aTask       [1]SortSubtask
}

struct PmaReader {
	iReadOff I64
	iEof     I64
	nAlloc   int
	nKey     int
	pFd      &Sqlite3_file
	aAlloc   &U8
	aKey     &U8
	aBuffer  &U8
	nBuffer  int
	aMap     &U8
	pIncr    &IncrMerger
}

struct IncrMerger {
	pTask      &SortSubtask
	pMerger    &MergeEngine
	iStartOff  I64
	mxSz       int
	bEof       int
	bUseThread int
	aFile      [2]SorterFile
}

struct PmaWriter {
	eFWErr    int
	aBuffer   &U8
	nBuffer   int
	iBufStart int
	iBufEnd   int
	iWriteOff I64
	pFd       &Sqlite3_file
	nPmaSpill U64
}

union SorterRecord_u {
	pNext &SorterRecord
	iNext int
}

struct SorterRecord {
	nVal int
	u    SorterRecord_u
}

@[c:'vdbePmaReaderClear']
fn vdbe_pma_reader_clear(p_readr &PmaReader) {
	sqlite3_free(voidptr(p_readr.aAlloc))
	sqlite3_free(voidptr(p_readr.aBuffer))
	if p_readr.aMap {
		sqlite3_os_unfetch(p_readr.pFd, I64(0), voidptr(p_readr.aMap))
	}
	vdbe_incr_free(p_readr.pIncr)
	C.memset(voidptr(p_readr), 0, sizeof(PmaReader))
}

@[c:'vdbePmaReadBlob']
fn vdbe_pma_read_blob(p &PmaReader, n_byte int, pp_out &&U8) int {
	i_buf := 0
	n_avail := 0
	if p.aMap {
		unsafe { *pp_out = p.aMap + p.iReadOff }
		p.iReadOff += I64(n_byte)
		return 0
	}
	i_buf = int(p.iReadOff % I64(p.nBuffer))
	if i_buf == 0 {
		n_read := 0
		rc := 0
		if (p.iEof - p.iReadOff) > I64(p.nBuffer) {
			n_read = p.nBuffer
		} else {
			n_read = int((p.iEof - p.iReadOff))
		}
		rc = sqlite3_os_read(p.pFd, voidptr(p.aBuffer), n_read, p.iReadOff)
		if rc != 0 {
			return rc
		}
	}
	n_avail = p.nBuffer - i_buf
	if n_byte <= n_avail {
		unsafe { *pp_out = p.aBuffer + i_buf }
		p.iReadOff += I64(n_byte)
	} else {
		n_rem := 0
		if p.nAlloc < n_byte {
			a_new := &U8(0)
			n_new := (if Sqlite3_int64(128) > (Sqlite3_int64(2) * Sqlite3_int64(p.nAlloc)) {
				Sqlite3_int64(128)
			} else {
				(Sqlite3_int64(2) * Sqlite3_int64(p.nAlloc))
			})
			for Sqlite3_int64(n_byte) > n_new {
				n_new = n_new * Sqlite3_int64(2)
			}
			a_new = sqlite3_realloc_vdup3(voidptr(p.aAlloc), U64(n_new))
			if isnil(a_new) {
				return 7
			}
			p.nAlloc = int(n_new)
			p.aAlloc = a_new
		}
		C.memcpy(voidptr(p.aAlloc), voidptr(unsafe { p.aBuffer + i_buf }), u64(n_avail))
		p.iReadOff += I64(n_avail)
		n_rem = n_byte - n_avail
		for n_rem > 0 {
			rc := 0
			n_copy := 0
			a_next := unsafe { &U8(nil) }
			n_copy = n_rem
			if n_rem > p.nBuffer {
				n_copy = p.nBuffer
			}
			rc = vdbe_pma_read_blob(p, n_copy, &&U8(&&U8(c2v_address_of(&a_next))))
			if rc != 0 {
				return rc
			}
			C.memcpy(voidptr(unsafe { p.aAlloc + (n_byte - n_rem) }), voidptr(a_next), u64(n_copy))
			n_rem -= n_copy
		}
		unsafe { *pp_out = p.aAlloc }
	}
	return 0
}

@[c:'vdbePmaReadVarint']
fn vdbe_pma_read_varint(p &PmaReader, pn_out &U64) int {
	i_buf := 0
	if p.aMap {
		p.iReadOff += I64(sqlite3_get_varint(unsafe { p.aMap + p.iReadOff }, pn_out))
	} else {
		i_buf = int(p.iReadOff % I64(p.nBuffer))
		if i_buf && (p.nBuffer - i_buf) >= 9 {
			p.iReadOff += I64(sqlite3_get_varint(unsafe { p.aBuffer + i_buf }, pn_out))
		} else {
			a_varint := [16]U8{}
			a := &U8(0)

			i := 0
			rc := 0

			for {
				rc = vdbe_pma_read_blob(p, 1, &&U8(&&U8(c2v_address_of(&a))))
				if rc {
					return rc
				}
				a_varint[(i++) & 15] = a[0]
				if !((int(a[0]) & 128) != 0) {
					break
				}
			}
			sqlite3_get_varint(unsafe { &a_varint[0] }, pn_out)
		}
	}
	return 0
}

@[c:'vdbeSorterMapFile']
fn vdbe_sorter_map_file(p_task &SortSubtask, p_file &SorterFile, pp &&U8) int {
	rc := 0
	if p_file.iEof <= I64(p_task.pSorter.db.nMaxSorterMmap) {
		p_fd := p_file.pFd
		if p_fd.pMethods.iVersion >= 3 {
			rc = sqlite3_os_fetch(p_fd, I64(0), int(p_file.iEof), &voidptr(voidptr(pp)))
		}
	}
	return rc
}

@[c:'vdbePmaReaderSeek']
fn vdbe_pma_reader_seek(p_task &SortSubtask, p_readr &PmaReader, p_file &SorterFile, i_off I64) int {
	rc := 0
	if sqlite3_fault_sim(201) {
		return 10 | (1 << 8)
	}
	if p_readr.aMap {
		sqlite3_os_unfetch(p_readr.pFd, I64(0), voidptr(p_readr.aMap))
		p_readr.aMap = 0
	}
	p_readr.iReadOff = i_off
	p_readr.iEof = p_file.iEof
	p_readr.pFd = p_file.pFd
	rc = vdbe_sorter_map_file(p_task, p_file, &&U8(&p_readr.aMap))
	if rc == 0 && usize(p_readr.aMap) == usize(0) {
		pgsz := p_task.pSorter.pgsz
		i_buf := int(p_readr.iReadOff % I64(pgsz))
		if usize(p_readr.aBuffer) == usize(0) {
			p_readr.aBuffer = &U8(sqlite3_malloc_vdup2(U64(pgsz)))
			if usize(p_readr.aBuffer) == usize(0) {
				rc = 7
			}
			p_readr.nBuffer = pgsz
		}
		if rc == 0 && i_buf {
			n_read := pgsz - i_buf
			if (p_readr.iReadOff + I64(n_read)) > p_readr.iEof {
				n_read = int((p_readr.iEof - p_readr.iReadOff))
			}
			rc = sqlite3_os_read(p_readr.pFd, voidptr(unsafe { p_readr.aBuffer + i_buf }), n_read, p_readr.iReadOff)
		}
	}
	return rc
}

@[c:'vdbePmaReaderNext']
fn vdbe_pma_reader_next(p_readr &PmaReader) int {
	rc := 0
	n_rec := U64(0)
	if p_readr.iReadOff >= p_readr.iEof {
		p_incr := p_readr.pIncr
		b_eof := 1
		if p_incr {
			rc = vdbe_incr_swap(p_incr)
			if rc == 0 && p_incr.bEof == 0 {
				rc = vdbe_pma_reader_seek(p_incr.pTask, p_readr, unsafe { &p_incr.aFile[0] + 0 }, p_incr.iStartOff)
				b_eof = 0
			}
		}
		if b_eof {
			vdbe_pma_reader_clear(p_readr)
			return rc
		}
	}
	if rc == 0 {
		rc = vdbe_pma_read_varint(p_readr, &n_rec)
	}
	if rc == 0 {
		p_readr.nKey = int(n_rec)
		rc = vdbe_pma_read_blob(p_readr, int(n_rec), &&U8(&p_readr.aKey))
	}
	return rc
}

@[c:'vdbePmaReaderInit']
fn vdbe_pma_reader_init(p_task &SortSubtask, p_file &SorterFile, i_start I64, p_readr &PmaReader, pn_byte &I64) int {
	rc := 0
	rc = vdbe_pma_reader_seek(p_task, p_readr, p_file, i_start)
	if rc == 0 {
		n_byte := U64(0)
		rc = vdbe_pma_read_varint(p_readr, &n_byte)
		p_readr.iEof = I64(U64(p_readr.iReadOff) + n_byte)
		unsafe { *pn_byte += n_byte }
	}
	if rc == 0 {
		rc = vdbe_pma_reader_next(p_readr)
	}
	return rc
}

@[c:'vdbeSorterCompareTail']
fn vdbe_sorter_compare_tail(p_task &SortSubtask, pb_key2_cached &int, p_key1 voidptr, n_key1 int, p_key2 voidptr, n_key2 int) int {
	r2 := p_task.pUnpacked
	if (unsafe { *pb_key2_cached }) == 0 {
		sqlite3_vdbe_record_unpack(n_key2, voidptr(p_key2), r2)
		unsafe { *pb_key2_cached = 1 }
	}
	return sqlite3_vdbe_record_compare_with_skip(n_key1, voidptr(p_key1), r2, 1)
}

@[c:'vdbeSorterCompare']
fn vdbe_sorter_compare(p_task &SortSubtask, pb_key2_cached &int, p_key1 voidptr, n_key1 int, p_key2 voidptr, n_key2 int) int {
	c2v_gc_register_thread()
	r2 := p_task.pUnpacked
	if !(unsafe { *pb_key2_cached }) {
		sqlite3_vdbe_record_unpack(n_key2, voidptr(p_key2), r2)
		unsafe { *pb_key2_cached = 1 }
	}
	return sqlite3_vdbe_record_compare(n_key1, voidptr(p_key1), r2)
}

@[c:'vdbeSorterCompareText']
fn vdbe_sorter_compare_text(p_task &SortSubtask, pb_key2_cached &int, p_key1 voidptr, n_key1 int, p_key2 voidptr, n_key2 int) int {
	c2v_gc_register_thread()
	p1 := &U8(p_key1)
	p2 := &U8(p_key2)
	v1 := unsafe { p1 + p1[0] }
	v2 := unsafe { p2 + p2[0] }
	n1 := 0
	n2 := 0
	res := 0
	n1 = int(u32((unsafe { *(p1 + 1) })))
	if n1 >= 128 {
		sqlite3_get_varint32((unsafe { p1 + 1 }), &u32(c2v_address_of(&n1)))
	}
	n2 = int(u32((unsafe { *(p2 + 1) })))
	if n2 >= 128 {
		sqlite3_get_varint32((unsafe { p2 + 1 }), &u32(c2v_address_of(&n2)))
	}
	res = C.memcmp(voidptr(v1), voidptr(v2), u64(((if n1 < n2 { n1 } else { n2 }) - 13) / 2))
	if res == 0 {
		res = n1 - n2
	}
	if res == 0 {
		if int(p_task.pSorter.pKeyInfo.nKeyField) > 1 {
			res = vdbe_sorter_compare_tail(p_task, pb_key2_cached, voidptr(p_key1), n_key1, voidptr(p_key2), n_key2)
		}
	} else {
		if p_task.pSorter.pKeyInfo.aSortFlags[0] {
			res = res * -1
		}
	}
	return res
}

@[c:'vdbeSorterCompareInt']
fn vdbe_sorter_compare_int(p_task &SortSubtask, pb_key2_cached &int, p_key1 voidptr, n_key1 int, p_key2 voidptr, n_key2 int) int {
	c2v_gc_register_thread()
	p1 := &U8(p_key1)
	p2 := &U8(p_key2)
	s1 := int(p1[1])
	s2 := int(p2[1])
	v1 := unsafe { p1 + p1[0] }
	v2 := unsafe { p2 + p2[0] }
	res := 0
	if s1 == s2 {
		if !vdbe_sorter_compare_int_a_len_inited {
			c2v_static_init := [U8(0), U8(1), U8(2), U8(3), U8(4), U8(6), U8(8), U8(0), U8(0), U8(0)]
			for c2v_i_0, c2v_element_0 in c2v_static_init {
				vdbe_sorter_compare_int_a_len[c2v_i_0] = c2v_element_0
			}
			vdbe_sorter_compare_int_a_len_inited = true
		}

		n := vdbe_sorter_compare_int_a_len[s1]
		i := 0
		res = 0
		for i = 0; i < int(n); i++ {
			res = int(v1[i]) - int(v2[i])
			if res != 0 {
				if ((int(v1[0]) ^ int(v2[0])) & 128) != 0 {
					res = if int(v1[0]) & 128 { -1 } else { 1 }
				}
				break
			}
		}
	} else if s1 > 7 && s2 > 7 {
		res = s1 - s2
	} else {
		if s2 > 7 {
			res = 1
		} else if s1 > 7 {
			res = -1
		} else {
			res = s1 - s2
		}
		if res > 0 {
			if int((unsafe { *v1 })) & 128 {
				res = -1
			}
		} else {
			if int((unsafe { *v2 })) & 128 {
				res = 1
			}
		}
	}
	if res == 0 {
		if int(p_task.pSorter.pKeyInfo.nKeyField) > 1 {
			res = vdbe_sorter_compare_tail(p_task, pb_key2_cached, voidptr(p_key1), n_key1, voidptr(p_key2), n_key2)
		}
	} else if p_task.pSorter.pKeyInfo.aSortFlags[0] {
		res = res * -1
	}
	return res
}

@[c:'sqlite3VdbeSorterInit']
fn sqlite3_vdbe_sorter_init(db &Sqlite3, n_field int, p_csr &VdbeCursor) int {
	pgsz := 0
	i := 0
	p_sorter := &VdbeSorter(0)
	p_key_info := &KeyInfo(0)
	sz_key_info := 0
	sz := I64(0)
	rc := 0
	n_worker := 0
	if sqlite3_temp_in_memory(db) || int(sqlite3Config.bCoreMutex) == 0 {
		n_worker = 0
	} else {
		n_worker = db.aLimit[11]
	}
	sz_key_info = int(((u64(usize(__offsetof(KeyInfo, aColl)))) + u64(p_csr.pKeyInfo.nAllField) * sizeof(voidptr)))
	sz = I64(((u64(usize(__offsetof(VdbeSorter, aTask)))) + u64((n_worker + 1)) * sizeof(SortSubtask)))
	p_sorter = &VdbeSorter(sqlite3_db_malloc_zero(db, U64(sz + I64(sz_key_info))))
	p_csr.uc.pSorter = p_sorter
	if usize(p_sorter) == usize(0) {
		rc = 7
	} else {
		p_bt := db.aDb[0].pBt
		p_key_info = &KeyInfo(voidptr((&U8(voidptr(p_sorter)) + sz)))
		p_sorter.pKeyInfo = p_key_info
		C.memcpy(voidptr(p_key_info), voidptr(p_csr.pKeyInfo), u64(sz_key_info))
		p_key_info.db = 0
		if n_field && n_worker == 0 {
			p_key_info.nKeyField = U16(n_field)
		}
		sqlite3_btree_enter(p_bt)
		pgsz = sqlite3_btree_get_page_size(p_bt)
		p_sorter.pgsz = pgsz
		sqlite3_btree_leave(p_bt)
		p_sorter.nTask = U8(n_worker + 1)
		p_sorter.iPrev = U8((n_worker - 1))
		p_sorter.bUseThreads = U8((int(p_sorter.nTask) > 1))
		p_sorter.db = db
		for i = 0; i < int(p_sorter.nTask); i++ {
			p_task := unsafe { &p_sorter.aTask[0] + i }
			p_task.pSorter = p_sorter
		}
		if !sqlite3_temp_in_memory(db) {
			mx_cache := I64(0)
			sz_pma := sqlite3Config.szPma
			p_sorter.mnPmaSize = int(sz_pma * u32(pgsz))
			mx_cache = I64(db.aDb[0].pSchema.cache_size)
			if mx_cache < I64(0) {
				mx_cache = mx_cache * I64(-1024)
			} else {
				mx_cache = mx_cache * I64(pgsz)
			}
			mx_cache = (if mx_cache < I64((1 << 29)) { mx_cache } else { I64((1 << 29)) })
			p_sorter.mxPmaSize = (if p_sorter.mnPmaSize > (int(mx_cache)) {
				p_sorter.mnPmaSize
			} else {
				(int(mx_cache))
			})
			if int(sqlite3Config.bSmallMalloc) == 0 {
				p_sorter.nMemory = pgsz
				p_sorter.list.aMemory = &U8(sqlite3_malloc_vdup2(U64(pgsz)))
				if isnil(p_sorter.list.aMemory) {
					rc = 7
				}
			}
		}
		if int(p_key_info.nAllField) < 13 && (usize((&p_key_info.aColl[0])[0]) == usize(0) || usize((&p_key_info.aColl[0])[0]) == usize(db.pDfltColl)) && (int(p_key_info.aSortFlags[0]) & 2) == 0 {
			p_sorter.typeMask = U8(1 | 2)
		}
	}
	return rc
}

@[c:'vdbeSorterRecordFree']
fn vdbe_sorter_record_free(db &Sqlite3, p_record &SorterRecord) {
	p := &SorterRecord(0)
	p_next := &SorterRecord(0)
	for p = p_record; p; p = p_next {
		p_next = p.u.pNext
		sqlite3_db_free(db, voidptr(p))
	}
}

@[c:'vdbeSortSubtaskCleanup']
fn vdbe_sort_subtask_cleanup(db &Sqlite3, p_task &SortSubtask) {
	sqlite3_db_free(db, voidptr(p_task.pUnpacked))
	if p_task.list.aMemory {
		sqlite3_free(voidptr(p_task.list.aMemory))
	} else {
		vdbe_sorter_record_free(unsafe { nil }, p_task.list.pList)
	}
	if p_task.file.pFd {
		sqlite3_os_close_free(p_task.file.pFd)
	}
	if p_task.file2.pFd {
		sqlite3_os_close_free(p_task.file2.pFd)
	}
	C.memset(voidptr(p_task), 0, sizeof(SortSubtask))
}

@[c:'vdbeSorterJoinThread']
fn vdbe_sorter_join_thread(p_task &SortSubtask) int {
	rc := 0
	if p_task.pThread {
		p_ret := (voidptr(i64(1)))
		sqlite3_thread_join(p_task.pThread, &p_ret)
		rc = (int(i64(p_ret)))
		p_task.bDone = 0
		p_task.pThread = 0
	}
	return rc
}

@[c:'vdbeSorterCreateThread']
fn vdbe_sorter_create_thread(p_task &SortSubtask, x_task fn (voidptr) voidptr, p_in voidptr) int {
	return sqlite3_thread_create(&&SQLiteThread(&p_task.pThread), x_task, voidptr(p_in))
}

@[c:'vdbeSorterJoinAll']
fn vdbe_sorter_join_all(p_sorter &VdbeSorter, rcin int) int {
	rc := rcin
	i := 0
	for i = int(p_sorter.nTask) - 1; i >= 0; i-- {
		p_task := unsafe { &p_sorter.aTask[0] + i }
		rc2 := vdbe_sorter_join_thread(p_task)
		if rc == 0 {
			rc = rc2
		}
	}
	return rc
}

@[c:'vdbeMergeEngineNew']
fn vdbe_merge_engine_new(n_reader int) &MergeEngine {
	n := 2
	n_byte := I64(0)
	p_new := &MergeEngine(0)
	for n < n_reader {
		n += n
	}
	n_byte = I64(sizeof(MergeEngine) + u64(n) * (sizeof(int) + sizeof(PmaReader)))
	p_new = unsafe { if sqlite3_fault_sim(100) {
		&MergeEngine(nil)
	} else {
		&MergeEngine(sqlite3_malloc_zero(U64(n_byte)))
	} }
	if p_new {
		p_new.nTree = n
		p_new.pTask = 0
		p_new.aReadr = &PmaReader(voidptr(unsafe { p_new + 1 }))
		p_new.aTree = &int(voidptr(unsafe { p_new.aReadr + n }))
	}
	return p_new
}

@[c:'vdbeMergeEngineFree']
fn vdbe_merge_engine_free(p_merger &MergeEngine) {
	i := 0
	if p_merger {
		for i = 0; i < p_merger.nTree; i++ {
			vdbe_pma_reader_clear(unsafe { p_merger.aReadr + i })
		}
	}
	sqlite3_free(voidptr(p_merger))
}

@[c:'vdbeIncrFree']
fn vdbe_incr_free(p_incr &IncrMerger) {
	if p_incr {
		if p_incr.bUseThread {
			vdbe_sorter_join_thread(p_incr.pTask)
			if p_incr.aFile[0].pFd {
				sqlite3_os_close_free(p_incr.aFile[0].pFd)
			}
			if p_incr.aFile[1].pFd {
				sqlite3_os_close_free(p_incr.aFile[1].pFd)
			}
		}
		vdbe_merge_engine_free(p_incr.pMerger)
		sqlite3_free(voidptr(p_incr))
	}
}

@[c:'sqlite3VdbeSorterReset']
fn sqlite3_vdbe_sorter_reset(db &Sqlite3, p_sorter &VdbeSorter) {
	i := 0
	vdbe_sorter_join_all(p_sorter, 0)
	if p_sorter.pReader {
		vdbe_pma_reader_clear(p_sorter.pReader)
		sqlite3_db_free(db, voidptr(p_sorter.pReader))
		p_sorter.pReader = 0
	}
	vdbe_merge_engine_free(p_sorter.pMerger)
	p_sorter.pMerger = 0
	for i = 0; i < int(p_sorter.nTask); i++ {
		p_task := unsafe { &p_sorter.aTask[0] + i }
		vdbe_sort_subtask_cleanup(db, p_task)
		p_task.pSorter = p_sorter
	}
	if usize(p_sorter.list.aMemory) == usize(0) {
		vdbe_sorter_record_free(unsafe { nil }, p_sorter.list.pList)
	}
	p_sorter.list.pList = 0
	p_sorter.list.szPMA = I64(0)
	p_sorter.bUsePMA = U8(0)
	p_sorter.iMemory = 0
	p_sorter.mxKeysize = 0
	sqlite3_db_free(db, voidptr(p_sorter.pUnpacked))
	p_sorter.pUnpacked = 0
}

@[c:'sqlite3VdbeSorterClose']
fn sqlite3_vdbe_sorter_close(db &Sqlite3, p_csr &VdbeCursor) {
	p_sorter := &VdbeSorter(0)
	p_sorter = p_csr.uc.pSorter
	if p_sorter {
		ii := 0
		for ii = 0; ii < int(p_sorter.nTask); ii++ {
			db.nSpill += c2v_at(&p_sorter.aTask[0], isize(ii)).nSpill
		}
		sqlite3_vdbe_sorter_reset(db, p_sorter)
		sqlite3_free(voidptr(p_sorter.list.aMemory))
		sqlite3_db_free(db, voidptr(p_sorter))
		p_csr.uc.pSorter = 0
	}
}

@[c:'vdbeSorterExtendFile']
fn vdbe_sorter_extend_file(db &Sqlite3, p_fd &Sqlite3_file, n_byte I64) {
	if n_byte <= I64(db.nMaxSorterMmap) && p_fd.pMethods.iVersion >= 3 {
		p := voidptr(0)
		chunksize := 4 * 1024
		sqlite3_os_file_control_hint(p_fd, 6, voidptr(&chunksize))
		sqlite3_os_file_control_hint(p_fd, 5, voidptr(&n_byte))
		sqlite3_os_fetch(p_fd, I64(0), int(n_byte), &p)
		if p {
			sqlite3_os_unfetch(p_fd, I64(0), voidptr(p))
		}
	}
}

@[c:'vdbeSorterOpenTempFile']
fn vdbe_sorter_open_temp_file(db &Sqlite3, n_extend I64, pp_fd &&Sqlite3_file) int {
	rc := 0
	if sqlite3_fault_sim(202) {
		return 10 | (13 << 8)
	}
	rc = sqlite3_os_open_malloc(db.pVfs, unsafe { nil }, pp_fd, 4096 | 2 | 4 | 16 | 8, &rc)
	if rc == 0 {
		max := I64(2147418112)
		sqlite3_os_file_control_hint((unsafe { *pp_fd }), 18, voidptr(c2v_address_of(&max)))
		if n_extend > I64(0) {
			vdbe_sorter_extend_file(db, (unsafe { *pp_fd }), n_extend)
		}
	}
	return rc
}

@[c:'vdbeSortAllocUnpacked']
fn vdbe_sort_alloc_unpacked(p_task &SortSubtask) int {
	if usize(p_task.pUnpacked) == usize(0) {
		p_task.pUnpacked = sqlite3_vdbe_alloc_unpacked_record(p_task.pSorter.pKeyInfo)
		if usize(p_task.pUnpacked) == usize(0) {
			return 7
		}
		p_task.pUnpacked.nField = p_task.pSorter.pKeyInfo.nKeyField
		p_task.pUnpacked.errCode = U8(0)
	}
	return 0
}

@[c:'vdbeSorterMerge']
fn vdbe_sorter_merge(p_task &SortSubtask, p1 &SorterRecord, p2 &SorterRecord) &SorterRecord {
	p_final := unsafe { &SorterRecord(nil) }
	pp := &&SorterRecord(c2v_address_of(&p_final))
	b_cached := 0
	for {
		res := 0
		res = p_task.xCompare(p_task, &b_cached, voidptr((voidptr((&SorterRecord(p1) + 1)))), p1.nVal, voidptr((voidptr((&SorterRecord(p2) + 1)))), p2.nVal)
		if res <= 0 {
			unsafe { *pp = p1 }
			pp = &p1.u.pNext
			p1 = p1.u.pNext
			if usize(p1) == usize(0) {
				unsafe { *pp = p2 }
				break
			}
		} else {
			unsafe { *pp = p2 }
			pp = &p2.u.pNext
			p2 = p2.u.pNext
			b_cached = 0
			if usize(p2) == usize(0) {
				unsafe { *pp = p1 }
				break
			}
		}
	}
	return p_final
}

@[c:'vdbeSorterGetCompare']
fn vdbe_sorter_get_compare(p &VdbeSorter) SorterCompare {
	if int(p.typeMask) == 1 {
		return vdbe_sorter_compare_int
	} else if int(p.typeMask) == 2 {
		return vdbe_sorter_compare_text
	}
	return vdbe_sorter_compare
}

@[c:'vdbeSorterSort']
fn vdbe_sorter_sort(p_task &SortSubtask, p_list &SorterList) int {
	i := 0
	p := &SorterRecord(0)
	rc := 0
	a_slot := [64]&SorterRecord{}
	rc = vdbe_sort_alloc_unpacked(p_task)
	if rc != 0 {
		return rc
	}
	p = p_list.pList
	p_task.xCompare = vdbe_sorter_get_compare(p_task.pSorter)
	C.memset(voidptr(unsafe { &a_slot[0] }), 0, sizeof([64]&SorterRecord))
	for p {
		p_next := &SorterRecord(0)
		if p_list.aMemory {
			if usize(&U8(voidptr(p))) == usize(p_list.aMemory) {
				p_next = 0
			} else {
				p_next = &SorterRecord(voidptr(unsafe { p_list.aMemory + p.u.iNext }))
			}
		} else {
			p_next = p.u.pNext
		}
		p.u.pNext = 0
		for i = 0; a_slot[i]; i++ {
			p = vdbe_sorter_merge(p_task, p, a_slot[i])
			a_slot[i] = 0
		}
		a_slot[i] = p
		p = p_next
	}
	p = 0
	for i = 0; i < 64; i++ {
		if usize(a_slot[i]) == usize(0) {
			continue
		}
		p = if p { vdbe_sorter_merge(p_task, p, a_slot[i]) } else { a_slot[i] }
	}
	p_list.pList = p
	return int(p_task.pUnpacked.errCode)
}

@[c:'vdbePmaWriterInit']
fn vdbe_pma_writer_init(p_fd &Sqlite3_file, p &PmaWriter, n_buf int, i_start I64) {
	C.memset(voidptr(p), 0, sizeof(PmaWriter))
	p.aBuffer = &U8(sqlite3_malloc_vdup2(U64(n_buf)))
	if isnil(p.aBuffer) {
		p.eFWErr = 7
	} else {
		p.iBufStart = int((i_start % I64(n_buf)))
		p.iBufEnd = p.iBufStart
		p.iWriteOff = i_start - I64(p.iBufStart)
		p.nBuffer = n_buf
		p.pFd = p_fd
	}
}

@[c:'vdbePmaWriteBlob']
fn vdbe_pma_write_blob(p &PmaWriter, p_data &U8, n_data int) {
	n_rem := n_data
	for n_rem > 0 && p.eFWErr == 0 {
		n_copy := n_rem
		if n_copy > (p.nBuffer - p.iBufEnd) {
			n_copy = p.nBuffer - p.iBufEnd
		}
		C.memcpy(voidptr(unsafe { p.aBuffer + p.iBufEnd }), voidptr(unsafe { p_data + (n_data - n_rem) }), u64(n_copy))
		p.iBufEnd += n_copy
		if p.iBufEnd == p.nBuffer {
			p.eFWErr = sqlite3_os_write(p.pFd, voidptr(unsafe { p.aBuffer + p.iBufStart }), p.iBufEnd - p.iBufStart, p.iWriteOff + I64(p.iBufStart))
			p.nPmaSpill += U64((p.iBufEnd - p.iBufStart))
			p.iBufEnd = 0
			p.iBufStart = p.iBufEnd
			p.iWriteOff += I64(p.nBuffer)
		}
		n_rem -= n_copy
	}
}

@[c:'vdbePmaWriterFinish']
fn vdbe_pma_writer_finish(p &PmaWriter, pi_eof &I64, pn_spill &U64) int {
	rc := 0
	if p.eFWErr == 0 && !isnil(p.aBuffer) && p.iBufEnd > p.iBufStart {
		p.eFWErr = sqlite3_os_write(p.pFd, voidptr(unsafe { p.aBuffer + p.iBufStart }), p.iBufEnd - p.iBufStart, p.iWriteOff + I64(p.iBufStart))
		p.nPmaSpill += U64((p.iBufEnd - p.iBufStart))
	}
	unsafe { *pi_eof = (p.iWriteOff + I64(p.iBufEnd)) }
	unsafe { *pn_spill += p.nPmaSpill }
	sqlite3_free(voidptr(p.aBuffer))
	rc = p.eFWErr
	C.memset(voidptr(p), 0, sizeof(PmaWriter))
	return rc
}

@[c:'vdbePmaWriteVarint']
fn vdbe_pma_write_varint(p &PmaWriter, i_val U64) {
	n_byte := 0
	a_byte := [10]U8{}
	n_byte = sqlite3_put_varint(&a_byte[0], i_val)
	vdbe_pma_write_blob(p, &a_byte[0], n_byte)
}

@[c:'vdbeSorterListToPMA']
fn vdbe_sorter_list_to_pma(p_task &SortSubtask, p_list &SorterList) int {
	db := p_task.pSorter.db
	rc := 0
	writer := PmaWriter{}
	C.memset(voidptr(&writer), 0, sizeof(PmaWriter))
	if usize(p_task.file.pFd) == usize(0) {
		rc = vdbe_sorter_open_temp_file(db, I64(0), &&Sqlite3_file(&p_task.file.pFd))
	}
	if rc == 0 {
		vdbe_sorter_extend_file(db, p_task.file.pFd, p_task.file.iEof + p_list.szPMA + I64(9))
	}
	if rc == 0 {
		rc = vdbe_sorter_sort(p_task, p_list)
	}
	if rc == 0 {
		p := &SorterRecord(0)
		p_next := unsafe { &SorterRecord(nil) }
		vdbe_pma_writer_init(p_task.file.pFd, &writer, p_task.pSorter.pgsz, p_task.file.iEof)
		p_task.nPMA++
		vdbe_pma_write_varint(&writer, U64(p_list.szPMA))
		for p = p_list.pList; p; p = p_next {
			p_next = p.u.pNext
			vdbe_pma_write_varint(&writer, U64(p.nVal))
			vdbe_pma_write_blob(&writer, (voidptr((&SorterRecord(p) + 1))), p.nVal)
			if usize(p_list.aMemory) == usize(0) {
				sqlite3_free(voidptr(p))
			}
		}
		p_list.pList = p
		rc = vdbe_pma_writer_finish(&writer, &p_task.file.iEof, &p_task.nSpill)
	}
	return rc
}

@[c:'vdbeMergeEngineStep']
fn vdbe_merge_engine_step(p_merger &MergeEngine, pb_eof &int) int {
	rc := 0
	i_prev := p_merger.aTree[1]
	p_task := p_merger.pTask
	rc = vdbe_pma_reader_next(unsafe { p_merger.aReadr + i_prev })
	if rc == 0 {
		i := 0
		p_readr1 := &PmaReader(0)
		p_readr2 := &PmaReader(0)
		b_cached := 0
		p_readr1 = unsafe { p_merger.aReadr + (i_prev & 65534) }
		p_readr2 = unsafe { p_merger.aReadr + (i_prev | 1) }
		for i = (p_merger.nTree + i_prev) / 2; i > 0; i = i / 2 {
			i_res := 0
			if usize(p_readr1.pFd) == usize(0) {
				i_res = 1
			} else if usize(p_readr2.pFd) == usize(0) {
				i_res = -1
			} else {
				i_res = p_task.xCompare(p_task, &b_cached, voidptr(p_readr1.aKey), p_readr1.nKey, voidptr(p_readr2.aKey), p_readr2.nKey)
			}
			if i_res < 0 || (i_res == 0 && usize(p_readr1) < usize(p_readr2)) {
				p_merger.aTree[i] = int((i64((isize(p_readr1) - isize(p_merger.aReadr)) / isize(sizeof(PmaReader)))))
				p_readr2 = unsafe { p_merger.aReadr + p_merger.aTree[i ^ 1] }
				b_cached = 0
			} else {
				if p_readr1.pFd {
					b_cached = 0
				}
				p_merger.aTree[i] = int((i64((isize(p_readr2) - isize(p_merger.aReadr)) / isize(sizeof(PmaReader)))))
				p_readr1 = unsafe { p_merger.aReadr + p_merger.aTree[i ^ 1] }
			}
		}
		unsafe { *pb_eof = (usize(p_merger.aReadr[p_merger.aTree[1]].pFd) == usize(0)) }
	}
	return if rc == 0 { int(p_task.pUnpacked.errCode) } else { rc }
}

@[c:'vdbeSorterFlushThread']
fn vdbe_sorter_flush_thread(p_ctx voidptr) voidptr {
	c2v_gc_register_thread()
	p_task := &SortSubtask(p_ctx)
	rc := 0
	rc = vdbe_sorter_list_to_pma(p_task, &p_task.list)
	p_task.bDone = 1
	return voidptr(i64(rc))
}

@[c:'vdbeSorterFlushPMA']
fn vdbe_sorter_flush_pma(p_sorter &VdbeSorter) int {
	rc := 0
	i := 0
	p_task := unsafe { &SortSubtask(nil) }
	n_worker := (int(p_sorter.nTask) - 1)
	p_sorter.bUsePMA = U8(1)
	for i = 0; i < n_worker; i++ {
		i_test := (int(p_sorter.iPrev) + i + 1) % n_worker
		p_task = unsafe { &p_sorter.aTask[0] + i_test }
		if p_task.bDone {
			rc = vdbe_sorter_join_thread(p_task)
		}
		if rc != 0 || usize(p_task.pThread) == usize(0) {
			break
		}
	}
	if rc == 0 {
		if i == n_worker {
			rc = vdbe_sorter_list_to_pma(unsafe { &p_sorter.aTask[0] + n_worker }, &p_sorter.list)
		} else {
			a_mem := &U8(0)
			p_ctx := &voidptr(0)
			a_mem = p_task.list.aMemory
			p_ctx = voidptr(p_task)
			p_sorter.iPrev = U8((i64((isize(p_task) - isize(unsafe { &p_sorter.aTask[0] })) / isize(sizeof(SortSubtask)))))
			p_task.list = p_sorter.list
			p_sorter.list.pList = 0
			p_sorter.list.szPMA = I64(0)
			if a_mem {
				p_sorter.list.aMemory = a_mem
				p_sorter.nMemory = sqlite3_malloc_size(voidptr(a_mem))
			} else if p_sorter.list.aMemory {
				p_sorter.list.aMemory = sqlite3_malloc_vdup2(U64(p_sorter.nMemory))
				if isnil(p_sorter.list.aMemory) {
					return 7
				}
			}
			rc = vdbe_sorter_create_thread(p_task, vdbe_sorter_flush_thread, voidptr(p_ctx))
		}
	}
	return rc
}

@[c:'sqlite3VdbeSorterWrite']
fn sqlite3_vdbe_sorter_write(p_csr &VdbeCursor, p_val &Mem) int {
	p_sorter := &VdbeSorter(0)
	rc := 0
	p_new := &SorterRecord(0)
	b_flush := 0
	n_req := I64(0)
	npma := I64(0)
	t := 0
	p_sorter = p_csr.uc.pSorter
	t = int(u32((unsafe { *(&U8(voidptr(p_val.z + 1))) })))
	if t >= 128 {
		sqlite3_get_varint32((&U8(voidptr(unsafe { p_val.z + 1 }))), &u32(c2v_address_of(&t)))
	}
	if t > 0 && t < 10 && t != 7 {
		p_sorter.typeMask &= 1
	} else if t > 10 && (t & 1) {
		p_sorter.typeMask &= 2
	} else {
		p_sorter.typeMask = U8(0)
	}
	n_req = I64(u64(p_val.n) + sizeof(SorterRecord))
	npma = I64(p_val.n + sqlite3_varint_len(U64(p_val.n)))
	if p_sorter.mxPmaSize {
		if p_sorter.list.aMemory {
			b_flush = p_sorter.iMemory && (I64(p_sorter.iMemory) + n_req) > I64(p_sorter.mxPmaSize)
		} else {
			b_flush = ((p_sorter.list.szPMA > I64(p_sorter.mxPmaSize)) || (p_sorter.list.szPMA > I64(p_sorter.mnPmaSize) && sqlite3_heap_nearly_full()))
		}
		if b_flush {
			rc = vdbe_sorter_flush_pma(p_sorter)
			p_sorter.list.szPMA = I64(0)
			p_sorter.iMemory = 0
		}
	}
	p_sorter.list.szPMA += npma
	if npma > I64(p_sorter.mxKeysize) {
		p_sorter.mxKeysize = int(npma)
	}
	if p_sorter.list.aMemory {
		n_min := int(I64(p_sorter.iMemory) + n_req)
		if n_min > p_sorter.nMemory {
			a_new := &U8(0)
			n_new := Sqlite3_int64(2) * Sqlite3_int64(p_sorter.nMemory)
			i_list_off := -1
			if p_sorter.list.pList {
				i_list_off = int(i64((isize(&U8(voidptr(p_sorter.list.pList))) - isize(p_sorter.list.aMemory)) / isize(sizeof(U8))))
			}
			for n_new < Sqlite3_int64(n_min) {
				n_new = n_new * Sqlite3_int64(2)
			}
			if n_new > Sqlite3_int64(p_sorter.mxPmaSize) {
				n_new = Sqlite3_int64(p_sorter.mxPmaSize)
			}
			if n_new < Sqlite3_int64(n_min) {
				n_new = Sqlite3_int64(n_min)
			}
			a_new = sqlite3_realloc_vdup3(voidptr(p_sorter.list.aMemory), U64(n_new))
			if isnil(a_new) {
				return 7
			}
			if i_list_off >= 0 {
				p_sorter.list.pList = &SorterRecord(voidptr(unsafe { a_new + i_list_off }))
			}
			p_sorter.list.aMemory = a_new
			p_sorter.nMemory = int(n_new)
		}
		p_new = &SorterRecord(voidptr(unsafe { p_sorter.list.aMemory + p_sorter.iMemory }))
		p_sorter.iMemory += ((n_req + I64(7)) & I64(~7))
		if p_sorter.list.pList {
			p_new.u.iNext = int((i64((isize(&U8(voidptr(p_sorter.list.pList))) - isize(p_sorter.list.aMemory)) / isize(sizeof(U8)))))
		}
	} else {
		p_new = &SorterRecord(sqlite3_malloc_vdup2(U64(n_req)))
		if usize(p_new) == usize(0) {
			return 7
		}
		p_new.u.pNext = p_sorter.list.pList
	}
	C.memcpy(voidptr((voidptr((&SorterRecord(p_new) + 1)))), voidptr(p_val.z), u64(p_val.n))
	p_new.nVal = p_val.n
	p_sorter.list.pList = p_new
	return rc
}

@[c:'vdbeIncrPopulate']
fn vdbe_incr_populate(p_incr &IncrMerger) int {
	rc := 0
	rc2 := 0
	i_start := p_incr.iStartOff
	p_out := unsafe { &p_incr.aFile[0] + 1 }
	p_task := p_incr.pTask
	p_merger := p_incr.pMerger
	writer := PmaWriter{}
	vdbe_pma_writer_init(p_out.pFd, &writer, p_task.pSorter.pgsz, i_start)
	for rc == 0 {
		dummy := 0
		p_reader := unsafe { p_merger.aReadr + p_merger.aTree[1] }
		n_key := p_reader.nKey
		i_eof := writer.iWriteOff + I64(writer.iBufEnd)
		if usize(p_reader.pFd) == usize(0) {
			break
		}
		if (i_eof + I64(n_key) + I64(sqlite3_varint_len(U64(n_key)))) > (i_start + I64(p_incr.mxSz)) {
			break
		}
		vdbe_pma_write_varint(&writer, U64(n_key))
		vdbe_pma_write_blob(&writer, p_reader.aKey, n_key)
		rc = vdbe_merge_engine_step(p_incr.pMerger, &dummy)
	}
	rc2 = vdbe_pma_writer_finish(&writer, &p_out.iEof, &p_task.nSpill)
	if rc == 0 {
		rc = rc2
	}
	return rc
}

@[c:'vdbeIncrPopulateThread']
fn vdbe_incr_populate_thread(p_ctx voidptr) voidptr {
	c2v_gc_register_thread()
	p_incr := &IncrMerger(p_ctx)
	p_ret := (voidptr(i64(vdbe_incr_populate(p_incr))))
	p_incr.pTask.bDone = 1
	return p_ret
}

@[c:'vdbeIncrBgPopulate']
fn vdbe_incr_bg_populate(p_incr &IncrMerger) int {
	p := voidptr(p_incr)
	return vdbe_sorter_create_thread(p_incr.pTask, vdbe_incr_populate_thread, voidptr(p))
}

@[c:'vdbeIncrSwap']
fn vdbe_incr_swap(p_incr &IncrMerger) int {
	rc := 0
	if p_incr.bUseThread {
		rc = vdbe_sorter_join_thread(p_incr.pTask)
		if rc == 0 {
			f0 := p_incr.aFile[0]
			p_incr.aFile[0] = p_incr.aFile[1]
			p_incr.aFile[1] = f0
		}
		if rc == 0 {
			if p_incr.aFile[0].iEof == p_incr.iStartOff {
				p_incr.bEof = 1
			} else {
				rc = vdbe_incr_bg_populate(p_incr)
			}
		}
	} else {
		rc = vdbe_incr_populate(p_incr)
		p_incr.aFile[0] = p_incr.aFile[1]
		if p_incr.aFile[0].iEof == p_incr.iStartOff {
			p_incr.bEof = 1
		}
	}
	return rc
}

@[c:'vdbeIncrMergerNew']
fn vdbe_incr_merger_new(p_task &SortSubtask, p_merger &MergeEngine, pp_out &&IncrMerger) int {
	rc := 0
	p_incr := c2v_assign[&IncrMerger](pp_out, if sqlite3_fault_sim(100) {
		&IncrMerger(0)
	} else {
		&IncrMerger(sqlite3_malloc_zero(U64(sizeof(IncrMerger))))
	})
	if p_incr {
		p_incr.pMerger = p_merger
		p_incr.pTask = p_task
		p_incr.mxSz = (if (p_task.pSorter.mxKeysize + 9) > (p_task.pSorter.mxPmaSize / 2) {
			(p_task.pSorter.mxKeysize + 9)
		} else {
			(p_task.pSorter.mxPmaSize / 2)
		})
		p_task.file2.iEof += I64(p_incr.mxSz)
	} else {
		vdbe_merge_engine_free(p_merger)
		rc = 7
	}
	return rc
}

@[c:'vdbeIncrMergerSetThreads']
fn vdbe_incr_merger_set_threads(p_incr &IncrMerger) {
	p_incr.bUseThread = 1
	p_incr.pTask.file2.iEof -= I64(p_incr.mxSz)
}

@[c:'vdbeMergeEngineCompare']
fn vdbe_merge_engine_compare(p_merger &MergeEngine, i_out int) {
	i1 := 0
	i2 := 0
	i_res := 0
	p1 := &PmaReader(0)
	p2 := &PmaReader(0)
	if i_out >= (p_merger.nTree / 2) {
		i1 = (i_out - p_merger.nTree / 2) * 2
		i2 = i1 + 1
	} else {
		i1 = p_merger.aTree[i_out * 2]
		i2 = p_merger.aTree[i_out * 2 + 1]
	}
	p1 = unsafe { p_merger.aReadr + i1 }
	p2 = unsafe { p_merger.aReadr + i2 }
	if usize(p1.pFd) == usize(0) {
		i_res = i2
	} else if usize(p2.pFd) == usize(0) {
		i_res = i1
	} else {
		p_task := p_merger.pTask
		b_cached := 0
		res := 0
		res = p_task.xCompare(p_task, &b_cached, voidptr(p1.aKey), p1.nKey, voidptr(p2.aKey), p2.nKey)
		if res <= 0 {
			i_res = i1
		} else {
			i_res = i2
		}
	}
	p_merger.aTree[i_out] = i_res
}

@[c:'vdbeMergeEngineInit']
fn vdbe_merge_engine_init(p_task &SortSubtask, p_merger &MergeEngine, e_mode int) int {
	rc := 0
	i := 0
	n_tree := 0
	p_merger.pTask = p_task
	n_tree = p_merger.nTree
	for i = 0; i < n_tree; i++ {
		if 8 > 0 && e_mode == 2 {
			rc = vdbe_pma_reader_next(unsafe { p_merger.aReadr + (n_tree - i - 1) })
		} else {
			rc = vdbe_pma_reader_incr_init(unsafe { p_merger.aReadr + i }, 0)
		}
		if rc != 0 {
			return rc
		}
	}
	for i = p_merger.nTree - 1; i > 0; i-- {
		vdbe_merge_engine_compare(p_merger, i)
	}
	return int(p_task.pUnpacked.errCode)
}

@[c:'vdbePmaReaderIncrMergeInit']
fn vdbe_pma_reader_incr_merge_init(p_readr &PmaReader, e_mode int) int {
	rc := 0
	p_incr := p_readr.pIncr
	p_task := p_incr.pTask
	db := p_task.pSorter.db
	rc = vdbe_merge_engine_init(p_task, p_incr.pMerger, e_mode)
	if rc == 0 {
		mx_sz := p_incr.mxSz
		if p_incr.bUseThread {
			rc = vdbe_sorter_open_temp_file(db, I64(mx_sz), &&Sqlite3_file(&p_incr.aFile[0].pFd))
			if rc == 0 {
				rc = vdbe_sorter_open_temp_file(db, I64(mx_sz), &&Sqlite3_file(&p_incr.aFile[1].pFd))
			}
		} else {
			if usize(p_task.file2.pFd) == usize(0) {
				rc = vdbe_sorter_open_temp_file(db, p_task.file2.iEof, &&Sqlite3_file(&p_task.file2.pFd))
				p_task.file2.iEof = I64(0)
			}
			if rc == 0 {
				p_incr.aFile[1].pFd = p_task.file2.pFd
				p_incr.iStartOff = p_task.file2.iEof
				p_task.file2.iEof += I64(mx_sz)
			}
		}
	}
	if rc == 0 && p_incr.bUseThread {
		rc = vdbe_incr_populate(p_incr)
	}
	if rc == 0 && (8 == 0 || e_mode != 1) {
		rc = vdbe_pma_reader_next(p_readr)
	}
	return rc
}

@[c:'vdbePmaReaderBgIncrInit']
fn vdbe_pma_reader_bg_incr_init(p_ctx voidptr) voidptr {
	c2v_gc_register_thread()
	p_reader := &PmaReader(p_ctx)
	p_ret := (voidptr(i64(vdbe_pma_reader_incr_merge_init(p_reader, 1))))
	p_reader.pIncr.pTask.bDone = 1
	return p_ret
}

@[c:'vdbePmaReaderIncrInit']
fn vdbe_pma_reader_incr_init(p_readr &PmaReader, e_mode int) int {
	p_incr := p_readr.pIncr
	rc := 0
	if p_incr {
		if p_incr.bUseThread {
			p_ctx := voidptr(p_readr)
			rc = vdbe_sorter_create_thread(p_incr.pTask, vdbe_pma_reader_bg_incr_init, voidptr(p_ctx))
		} else {
			rc = vdbe_pma_reader_incr_merge_init(p_readr, e_mode)
		}
	}
	return rc
}

@[c:'vdbeMergeEngineLevel0']
fn vdbe_merge_engine_level0(p_task &SortSubtask, npma int, pi_offset &I64, pp_out &&MergeEngine) int {
	p_new := &MergeEngine(0)
	i_off := (unsafe { *pi_offset })
	i := 0
	rc := 0
	p_new = vdbe_merge_engine_new(npma)
	unsafe { *pp_out = p_new }
	if usize(p_new) == usize(0) {
		rc = 7
	}
	for i = 0; i < npma && rc == 0; i++ {
		n_dummy := I64(0)
		p_readr := unsafe { p_new.aReadr + i }
		rc = vdbe_pma_reader_init(p_task, &p_task.file, i_off, p_readr, &n_dummy)
		i_off = p_readr.iEof
	}
	if rc != 0 {
		vdbe_merge_engine_free(p_new)
		unsafe { *pp_out = 0 }
	}
	unsafe { *pi_offset = i_off }
	return rc
}

@[c:'vdbeSorterTreeDepth']
fn vdbe_sorter_tree_depth(npma int) int {
	n_depth := 0
	n_div := I64(16)
	for n_div < I64(npma) {
		n_div = n_div * I64(16)
		n_depth++
	}
	return n_depth
}

@[c:'vdbeSorterAddToTree']
fn vdbe_sorter_add_to_tree(p_task &SortSubtask, n_depth int, i_seq int, p_root &MergeEngine, p_leaf &MergeEngine) int {
	rc := 0
	n_div := 1
	i := 0
	p := p_root
	p_incr := &IncrMerger(0)
	rc = vdbe_incr_merger_new(p_task, p_leaf, &&IncrMerger(&&IncrMerger(c2v_address_of(&p_incr))))
	for i = 1; i < n_depth; i++ {
		n_div = n_div * 16
	}
	for i = 1; i < n_depth && rc == 0; i++ {
		i_iter := (i_seq / n_div) % 16
		p_readr := unsafe { p.aReadr + i_iter }
		if usize(p_readr.pIncr) == usize(0) {
			p_new := vdbe_merge_engine_new(16)
			if usize(p_new) == usize(0) {
				rc = 7
			} else {
				rc = vdbe_incr_merger_new(p_task, p_new, &&IncrMerger(&p_readr.pIncr))
			}
		}
		if rc == 0 {
			p = p_readr.pIncr.pMerger
			n_div = n_div / 16
		}
	}
	if rc == 0 {
		p.aReadr[i_seq % 16].pIncr = p_incr
	} else {
		vdbe_incr_free(p_incr)
	}
	return rc
}

@[c:'vdbeSorterMergeTreeBuild']
fn vdbe_sorter_merge_tree_build(p_sorter &VdbeSorter, pp_out &&MergeEngine) int {
	p_main := unsafe { &MergeEngine(nil) }
	rc := 0
	i_task := 0
	if int(p_sorter.nTask) > 1 {
		p_main = vdbe_merge_engine_new(int(p_sorter.nTask))
		if usize(p_main) == usize(0) {
			rc = 7
		}
	}
	for i_task = 0; rc == 0 && i_task < int(p_sorter.nTask); i_task++ {
		p_task := unsafe { &p_sorter.aTask[0] + i_task }
		if 8 == 0 || p_task.nPMA {
			p_root := unsafe { &MergeEngine(nil) }
			n_depth := vdbe_sorter_tree_depth(p_task.nPMA)
			i_read_off := I64(0)
			if p_task.nPMA <= 16 {
				rc = vdbe_merge_engine_level0(p_task, p_task.nPMA, &i_read_off, &&MergeEngine(&&MergeEngine(c2v_address_of(&p_root))))
			} else {
				i := 0
				i_seq := 0
				p_root = vdbe_merge_engine_new(16)
				if usize(p_root) == usize(0) {
					rc = 7
				}
				for i = 0; i < p_task.nPMA && rc == 0; i += 16 {
					p_merger := unsafe { &MergeEngine(nil) }
					n_reader := 0
					n_reader = (if (p_task.nPMA - i) < 16 { (p_task.nPMA - i) } else { 16 })
					rc = vdbe_merge_engine_level0(p_task, n_reader, &i_read_off, &&MergeEngine(&&MergeEngine(c2v_address_of(&p_merger))))
					if rc == 0 {
						rc = vdbe_sorter_add_to_tree(p_task, n_depth, i_seq++, p_root, p_merger)
					}
				}
			}
			if rc == 0 {
				if usize(p_main) != usize(0) {
					rc = vdbe_incr_merger_new(p_task, p_root, &&IncrMerger(&p_main.aReadr[i_task].pIncr))
				} else {
					p_main = p_root
				}
			} else {
				vdbe_merge_engine_free(p_root)
			}
		}
	}
	if rc != 0 {
		vdbe_merge_engine_free(p_main)
		p_main = 0
	}
	unsafe { *pp_out = p_main }
	return rc
}

@[c:'vdbeSorterSetupMerge']
fn vdbe_sorter_setup_merge(p_sorter &VdbeSorter) int {
	rc := 0
	p_task0 := unsafe { &p_sorter.aTask[0] + 0 }
	p_main := unsafe { &MergeEngine(nil) }
	db := p_task0.pSorter.db
	i := 0
	x_compare := vdbe_sorter_get_compare(p_sorter)
	for i = 0; i < int(p_sorter.nTask); i++ {
		mut __c2v_lhs_tmp_88 := c2v_at(&p_sorter.aTask[0], isize(i))
		__c2v_lhs_tmp_88.xCompare = x_compare
	}
	rc = vdbe_sorter_merge_tree_build(p_sorter, &&MergeEngine(&&MergeEngine(c2v_address_of(&p_main))))
	if rc == 0 {
		if p_sorter.bUseThreads {
			i_task := 0
			p_readr := unsafe { &PmaReader(nil) }
			p_last := unsafe { &p_sorter.aTask[0] + (int(p_sorter.nTask) - 1) }
			rc = vdbe_sort_alloc_unpacked(p_last)
			if rc == 0 {
				p_readr = &PmaReader(sqlite3_db_malloc_zero(db, U64(sizeof(PmaReader))))
				p_sorter.pReader = p_readr
				if usize(p_readr) == usize(0) {
					rc = 7
				}
			}
			if rc == 0 {
				rc = vdbe_incr_merger_new(p_last, p_main, &&IncrMerger(&p_readr.pIncr))
				if rc == 0 {
					vdbe_incr_merger_set_threads(p_readr.pIncr)
					for i_task = 0; i_task < (int(p_sorter.nTask) - 1); i_task++ {
						p_incr := &IncrMerger(0)
						p_incr = p_main.aReadr[i_task].pIncr
						if p_incr {
							vdbe_incr_merger_set_threads(p_incr)
						}
					}
					for i_task = 0; rc == 0 && i_task < int(p_sorter.nTask); i_task++ {
						p := unsafe { p_main.aReadr + i_task }
						rc = vdbe_pma_reader_incr_init(p, 1)
					}
				}
				p_main = 0
			}
			if rc == 0 {
				rc = vdbe_pma_reader_incr_merge_init(p_readr, 2)
			}
		} else {
			rc = vdbe_merge_engine_init(p_task0, p_main, 0)
			p_sorter.pMerger = p_main
			p_main = 0
		}
	}
	if rc != 0 {
		vdbe_merge_engine_free(p_main)
	}
	return rc
}

@[c:'sqlite3VdbeSorterRewind']
fn sqlite3_vdbe_sorter_rewind(p_csr &VdbeCursor, pb_eof &int) int {
	p_sorter := &VdbeSorter(0)
	rc := 0
	p_sorter = p_csr.uc.pSorter
	if int(p_sorter.bUsePMA) == 0 {
		if p_sorter.list.pList {
			unsafe { *pb_eof = 0 }
			rc = vdbe_sorter_sort(unsafe { &p_sorter.aTask[0] + 0 }, &p_sorter.list)
		} else {
			unsafe { *pb_eof = 1 }
		}
		return rc
	}
	rc = vdbe_sorter_flush_pma(p_sorter)
	rc = vdbe_sorter_join_all(p_sorter, rc)
	if rc == 0 {
		rc = vdbe_sorter_setup_merge(p_sorter)
		unsafe { *pb_eof = 0 }
	}
	return rc
}

@[c:'sqlite3VdbeSorterNext']
fn sqlite3_vdbe_sorter_next(db &Sqlite3, p_csr &VdbeCursor) int {
	p_sorter := &VdbeSorter(0)
	rc := 0
	p_sorter = p_csr.uc.pSorter
	if p_sorter.bUsePMA {
		if p_sorter.bUseThreads {
			rc = vdbe_pma_reader_next(p_sorter.pReader)
			if rc == 0 && usize(p_sorter.pReader.pFd) == usize(0) {
				rc = 101
			}
		} else {
			res := 0
			rc = vdbe_merge_engine_step(p_sorter.pMerger, &res)
			if rc == 0 && res {
				rc = 101
			}
		}
	} else {
		p_free := p_sorter.list.pList
		p_sorter.list.pList = p_free.u.pNext
		p_free.u.pNext = 0
		if usize(p_sorter.list.aMemory) == usize(0) {
			vdbe_sorter_record_free(db, p_free)
		}
		rc = if p_sorter.list.pList { 0 } else { 101 }
	}
	return rc
}

@[c:'vdbeSorterRowkey']
fn vdbe_sorter_rowkey(p_sorter &VdbeSorter, pn_key &int) voidptr {
	p_key := &voidptr(0)
	if p_sorter.bUsePMA {
		p_reader := &PmaReader(0)
		if p_sorter.bUseThreads {
			p_reader = p_sorter.pReader
		} else {
			p_reader = unsafe { p_sorter.pMerger.aReadr + p_sorter.pMerger.aTree[1] }
		}
		unsafe { *pn_key = p_reader.nKey }
		p_key = p_reader.aKey
	} else {
		unsafe { *pn_key = p_sorter.list.pList.nVal }
		p_key = (voidptr((&SorterRecord(p_sorter.list.pList) + 1)))
	}
	return p_key
}

@[c:'sqlite3VdbeSorterRowkey']
fn sqlite3_vdbe_sorter_rowkey(p_csr &VdbeCursor, p_out &Mem) int {
	p_sorter := &VdbeSorter(0)
	p_key := &voidptr(0)
	n_key := 0
	p_sorter = p_csr.uc.pSorter
	p_key = vdbe_sorter_rowkey(p_sorter, &n_key)
	if sqlite3_vdbe_mem_clear_and_resize(p_out, n_key) {
		return 7
	}
	p_out.n = n_key
	p_out.flags = U16((int(p_out.flags) & ~(3519 | 1024)) | 16)
	C.memcpy(voidptr(p_out.z), voidptr(p_key), u64(n_key))
	return 0
}

@[c:'sqlite3VdbeSorterCompare']
fn sqlite3_vdbe_sorter_compare(p_csr &VdbeCursor, p_val &Mem, n_key_col int, p_res &int) int {
	p_sorter := &VdbeSorter(0)
	r2 := &UnpackedRecord(0)
	p_key_info := &KeyInfo(0)
	i := 0
	p_key := &voidptr(0)
	n_key := 0
	p_sorter = p_csr.uc.pSorter
	r2 = p_sorter.pUnpacked
	p_key_info = p_csr.pKeyInfo
	if usize(r2) == usize(0) {
		p_sorter.pUnpacked = sqlite3_vdbe_alloc_unpacked_record(p_key_info)
		r2 = p_sorter.pUnpacked
		if usize(r2) == usize(0) {
			return 7
		}
		r2.nField = U16(n_key_col)
	}
	p_key = vdbe_sorter_rowkey(p_sorter, &n_key)
	sqlite3_vdbe_record_unpack(n_key, voidptr(p_key), r2)
	for i = 0; i < n_key_col; i++ {
		if int(r2.aMem[i].flags) & 1 {
			unsafe { *p_res = -1 }
			return 0
		}
	}
	unsafe { *p_res = sqlite3_vdbe_record_compare(p_val.n, voidptr(p_val.z), r2) }
	return 0
}
