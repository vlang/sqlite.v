@[translated]
module main

struct PagerSavepoint {
	iOffset            I64
	iHdrOffset         I64
	pInSavepoint       &Bitvec
	nOrig              Pgno
	iSubRec            Pgno
	bTruncateOnRelease int
	aWalData           [4]u32
}

struct Pager {
	pVfs              &Sqlite3_vfs
	exclusiveMode     U8
	journalMode       U8
	useJournal        U8
	noSync            U8
	fullSync          U8
	extraSync         U8
	syncFlags         U8
	walSyncFlags      U8
	tempFile          U8
	noLock            U8
	readOnly          U8
	memDb             U8
	memVfs            U8
	eState            U8
	eLock             U8
	changeCountDone   U8
	setSuper          U8
	doNotSpill        U8
	subjInMemory      U8
	bUseFetch         U8
	hasHeldSharedLock U8
	dbSize            Pgno
	dbOrigSize        Pgno
	dbFileSize        Pgno
	dbHintSize        Pgno
	errCode           int
	nRec              int
	cksumInit         u32
	nSubRec           u32
	pInJournal        &Bitvec
	fd                &Sqlite3_file
	jfd               &Sqlite3_file
	sjfd              &Sqlite3_file
	journalOff        I64
	journalHdr        I64
	pBackup           &Sqlite3_backup
	aSavepoint        &PagerSavepoint
	nSavepoint        int
	iDataVersion      u32
	dbFileVers        [16]i8
	nMmapOut          int
	szMmap            Sqlite3_int64
	pMmapFreelist     &PgHdr
	nExtra            U16
	nReserve          I16
	vfsFlags          u32
	sectorSize        u32
	mxPgno            Pgno
	lckPgno           Pgno
	pageSize          I64
	journalSizeLimit  I64
	zFilename         &i8
	zJournal          &i8
	xBusyHandler      fn (voidptr) int
	pBusyHandlerArg   voidptr
	aStat             [4]u32
	xReiniter         fn (&DbPage)
	xGet              fn (&Pager, Pgno, &&DbPage, int) int
	pTmpSpace         &i8
	pPCache           &PCache
	pWal              &Wal
	zWal              &i8
}

@[c:'sqlite3PagerDirectReadOk']
fn sqlite3_pager_direct_read_ok(p_pager &Pager, pgno Pgno) int {
	if usize(p_pager.fd.pMethods) == usize(0) {
		return 0
	}
	if sqlite3_pc_ache_is_dirty(p_pager.pPCache) {
		return 0
	}
	if p_pager.pWal {
		i_read := u32(0)
		sqlite3_wal_find_frame(p_pager.pWal, pgno, &i_read)
		if i_read {
			return 0
		}
	}
	if (p_pager.fd.pMethods.xDeviceCharacteristics(p_pager.fd) & 32768) == 0 {
		return 0
	}
	return 1
}

@[c:'setGetterMethod']
fn set_getter_method(p_pager &Pager) {
	if p_pager.errCode {
		p_pager.xGet = get_page_error
	} else if p_pager.bUseFetch {
		p_pager.xGet = get_page_mm_ap
	} else {
		p_pager.xGet = get_page_normal
	}
}

@[c:'subjRequiresPage']
fn subj_requires_page(p_pg &PgHdr) int {
	p_pager := p_pg.pPager
	p := &PagerSavepoint(0)
	pgno := p_pg.pgno
	i := 0
	for i = 0; i < p_pager.nSavepoint; i++ {
		p = unsafe { p_pager.aSavepoint + i }
		if p.nOrig >= pgno && 0 == sqlite3_bitvec_test_not_null(p.pInSavepoint, pgno) {
			for i = i + 1; i < p_pager.nSavepoint; i++ {
				p_pager.aSavepoint[i].bTruncateOnRelease = 0
			}
			return 1
		}
	}
	return 0
}

fn read32bits(fd &Sqlite3_file, offset I64, p_res &u32) int {
	ac := [4]u8{}
	rc := sqlite3_os_read(fd, voidptr(unsafe { &ac[0] }), int(sizeof([4]u8)), offset)
	if rc == 0 {
		unsafe { *p_res = sqlite3_get4byte(&ac[0]) }
	}
	return rc
}

fn write32bits(fd &Sqlite3_file, offset I64, val u32) int {
	ac := [4]i8{}
	sqlite3_put4byte(&U8(voidptr(unsafe { &ac[0] })), val)
	return sqlite3_os_write(fd, voidptr(unsafe { &ac[0] }), 4, offset)
}

@[c:'pagerUnlockDb']
fn pager_unlock_db(p_pager &Pager, e_lock int) int {
	rc := 0
	if (usize(p_pager.fd.pMethods) != usize(0)) {
		rc = if int(p_pager.noLock) { 0 } else { sqlite3_os_unlock(p_pager.fd, e_lock) }
		if int(p_pager.eLock) != (4 + 1) {
			p_pager.eLock = U8(e_lock)
		}
	}
	p_pager.changeCountDone = p_pager.tempFile
	return rc
}

@[c:'pagerLockDb']
fn pager_lock_db(p_pager &Pager, e_lock int) int {
	rc := 0
	if int(p_pager.eLock) < e_lock || int(p_pager.eLock) == (4 + 1) {
		rc = if int(p_pager.noLock) { 0 } else { sqlite3_os_lock(p_pager.fd, e_lock) }
		if rc == 0 && (int(p_pager.eLock) != (4 + 1) || e_lock == 4) {
			p_pager.eLock = U8(e_lock)
		}
	}
	return rc
}

@[c:'jrnlBufferSize']
fn jrnl_buffer_size(p_pager &Pager) int {
	return 0
}

@[c:'freeSuperJournal']
fn free_super_journal(z_super &i8) {
	if z_super {
		sqlite3_free(voidptr(unsafe { z_super + -4 }))
	}
}

@[c:'readSuperJournal']
fn read_super_journal(p_jrnl &Sqlite3_file, n_super U64, pz_super &&u8) int {
	rc := 0
	len := u32(0)
	sz_j := I64(0)
	cksum := u32(0)
	a_magic := [8]u8{}
	z_out := unsafe { &i8(nil) }
	unsafe { *pz_super = 0 }
	rc = sqlite3_os_file_size(p_jrnl, &sz_j)
	mut __c2v_condition_5 := false
	mut __c2v_condition_6 := false
	__c2v_condition_6 = 0 != rc
	__c2v_condition_5 = __c2v_condition_6
	if !__c2v_condition_5 {
		mut __c2v_condition_7 := false
		__c2v_condition_7 = sz_j < I64(16)
		__c2v_condition_5 = __c2v_condition_7
	}
	if !__c2v_condition_5 {
		mut __c2v_condition_8 := false
		__c2v_condition_8 = 0 != c2v_assign[int](unsafe { &rc }, int(read32bits(p_jrnl, sz_j - I64(16), &len)))
		__c2v_condition_5 = __c2v_condition_8
	}
	if !__c2v_condition_5 {
		mut __c2v_condition_9 := false
		__c2v_condition_9 = U64(len) >= n_super
		__c2v_condition_5 = __c2v_condition_9
	}
	if !__c2v_condition_5 {
		mut __c2v_condition_10 := false
		__c2v_condition_10 = I64(len) > sz_j - I64(16)
		__c2v_condition_5 = __c2v_condition_10
	}
	if !__c2v_condition_5 {
		mut __c2v_condition_11 := false
		__c2v_condition_11 = len == u32(0)
		__c2v_condition_5 = __c2v_condition_11
	}
	if !__c2v_condition_5 {
		mut __c2v_condition_12 := false
		__c2v_condition_12 = 0 != c2v_assign[int](unsafe { &rc }, int(read32bits(p_jrnl, sz_j - I64(12), &cksum)))
		__c2v_condition_5 = __c2v_condition_12
	}
	if !__c2v_condition_5 {
		mut __c2v_condition_13 := false
		__c2v_condition_13 = 0 != c2v_assign[int](unsafe { &rc }, int(sqlite3_os_read(p_jrnl, voidptr(unsafe { &a_magic[0] }), 8, sz_j - I64(8))))
		__c2v_condition_5 = __c2v_condition_13
	}
	if !__c2v_condition_5 {
		mut __c2v_condition_14 := false
		__c2v_condition_14 = C.memcmp(voidptr(unsafe { &a_magic[0] }), voidptr(unsafe { &aJournalMagic[0] }), u64(8))
		__c2v_condition_5 = __c2v_condition_14
	}
	if __c2v_condition_5 {
		return rc
	}
	z_out = &i8(sqlite3_malloc_zero(U64(u32(4) + len + u32(2))))
	if isnil(z_out) {
		rc = 7
	} else {
		z_out = unsafe { z_out + 4 }
		rc = sqlite3_os_read(p_jrnl, voidptr(z_out), int(len), sz_j - I64(16) - I64(len))
		if 0 == rc {
			u := u32(0)
			for u = u32(0); u < len; u++ {
				cksum -= u32(z_out[u])
			}
		}
		if rc != 0 || cksum || int(z_out[0]) == 0 {
			free_super_journal(z_out)
			z_out = 0
		}
	}
	unsafe { *pz_super = z_out }
	return rc
}

@[c:'journalHdrOffset']
fn journal_hdr_offset(p_pager &Pager) I64 {
	offset := I64(0)
	c := p_pager.journalOff
	if c {
		offset = ((c - I64(1)) / I64(p_pager.sectorSize) + I64(1)) * I64(p_pager.sectorSize)
	}
	return offset
}

@[c:'zeroJournalHdr']
fn zero_journal_hdr(p_pager &Pager, do_truncate int) int {
	rc := 0
	if p_pager.journalOff {
		i_limit := p_pager.journalSizeLimit
		if do_truncate || i_limit == I64(0) {
			rc = sqlite3_os_truncate(p_pager.jfd, I64(0))
		} else {
			if !zero_journal_hdr_zero_hdr_inited {
				c2v_static_init := [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0)]
				for c2v_i_0, c2v_element_0 in c2v_static_init {
					zero_journal_hdr_zero_hdr[c2v_i_0] = c2v_element_0
				}
				zero_journal_hdr_zero_hdr_inited = true
			}

			rc = sqlite3_os_write(p_pager.jfd, voidptr(unsafe { &zero_journal_hdr_zero_hdr[0] }), int(sizeof([28]i8)), I64(0))
		}
		if rc == 0 && !p_pager.noSync {
			rc = sqlite3_os_sync(p_pager.jfd, 16 | int(p_pager.syncFlags))
		}
		if rc == 0 && i_limit > I64(0) {
			sz := I64(0)
			rc = sqlite3_os_file_size(p_pager.jfd, &sz)
			if rc == 0 && sz > i_limit {
				rc = sqlite3_os_truncate(p_pager.jfd, i_limit)
			}
		}
	}
	return rc
}

@[c:'writeJournalHdr']
fn write_journal_hdr(p_pager &Pager) int {
	rc := 0
	z_header := p_pager.pTmpSpace
	n_header := u32(p_pager.pageSize)
	n_write := u32(0)
	ii := 0
	if n_header > p_pager.sectorSize {
		n_header = p_pager.sectorSize
	}
	for ii = 0; ii < p_pager.nSavepoint; ii++ {
		if p_pager.aSavepoint[ii].iHdrOffset == I64(0) {
			p_pager.aSavepoint[ii].iHdrOffset = p_pager.journalOff
		}
	}
	p_pager.journalOff = journal_hdr_offset(p_pager)
	p_pager.journalHdr = p_pager.journalOff
	if int(p_pager.noSync) || (int(p_pager.journalMode) == 4) || (sqlite3_os_device_characteristics(p_pager.fd) & 512) {
		C.memcpy(voidptr(z_header), voidptr(unsafe { &aJournalMagic[0] }), sizeof([8]u8))
		sqlite3_put4byte(&U8(voidptr(unsafe { z_header + sizeof([8]u8) })), u32(4294967295))
	} else {
		C.memset(voidptr(z_header), 0, sizeof([8]u8) + u64(4))
	}
	if int(p_pager.journalMode) != 4 {
		sqlite3_randomness(int(sizeof(u32)), voidptr(&p_pager.cksumInit))
	}
	sqlite3_put4byte(&U8(voidptr(unsafe { z_header + (sizeof([8]u8) + u64(4)) })), p_pager.cksumInit)
	sqlite3_put4byte(&U8(voidptr(unsafe { z_header + (sizeof([8]u8) + u64(8)) })), p_pager.dbOrigSize)
	sqlite3_put4byte(&U8(voidptr(unsafe { z_header + (sizeof([8]u8) + u64(12)) })), p_pager.sectorSize)
	sqlite3_put4byte(&U8(voidptr(unsafe { z_header + (sizeof([8]u8) + u64(16)) })), u32(p_pager.pageSize))
	C.memset(voidptr(unsafe { z_header + (sizeof([8]u8) + u64(20)) }), 0, u64(n_header) - (sizeof([8]u8) + u64(20)))
	for n_write = u32(0); rc == 0 && n_write < p_pager.sectorSize; n_write += n_header {
		rc = sqlite3_os_write(p_pager.jfd, voidptr(z_header), int(n_header), p_pager.journalOff)
		p_pager.journalOff += I64(n_header)
	}
	return rc
}

@[c:'readJournalHdr']
fn read_journal_hdr(p_pager &Pager, is_hot int, journal_size I64, pnr_ec &u32, p_db_size &u32) int {
	rc := 0
	a_magic := [8]u8{}
	i_hdr_off := I64(0)
	p_pager.journalOff = journal_hdr_offset(p_pager)
	if p_pager.journalOff + I64(p_pager.sectorSize) > journal_size {
		return 101
	}
	i_hdr_off = p_pager.journalOff
	if is_hot || i_hdr_off != p_pager.journalHdr {
		rc = sqlite3_os_read(p_pager.jfd, voidptr(unsafe { &a_magic[0] }), int(sizeof([8]u8)), i_hdr_off)
		if rc {
			return rc
		}
		if C.memcmp(voidptr(unsafe { &a_magic[0] }), voidptr(unsafe { &aJournalMagic[0] }), sizeof([8]u8)) != 0 {
			return 101
		}
	}
	rc = read32bits(p_pager.jfd, i_hdr_off + I64(8), pnr_ec)
	mut __c2v_condition_15 := false
	mut __c2v_condition_16 := false
	__c2v_condition_16 = 0 != rc
	__c2v_condition_15 = __c2v_condition_16
	if !__c2v_condition_15 {
		mut __c2v_condition_17 := false
		__c2v_condition_17 = 0 != c2v_assign[int](unsafe { &rc }, int(read32bits(p_pager.jfd, i_hdr_off + I64(12), &p_pager.cksumInit)))
		__c2v_condition_15 = __c2v_condition_17
	}
	if !__c2v_condition_15 {
		mut __c2v_condition_18 := false
		__c2v_condition_18 = 0 != c2v_assign[int](unsafe { &rc }, int(read32bits(p_pager.jfd, i_hdr_off + I64(16), p_db_size)))
		__c2v_condition_15 = __c2v_condition_18
	}
	if __c2v_condition_15 {
		return rc
	}
	if p_pager.journalOff == I64(0) {
		i_page_size := u32(0)
		i_sector_size := u32(0)
		rc = read32bits(p_pager.jfd, i_hdr_off + I64(20), &i_sector_size)
		if 0 != rc || 0 != c2v_assign[int](unsafe { &rc }, int(read32bits(p_pager.jfd, i_hdr_off + I64(24), &i_page_size))) {
			return rc
		}
		if i_page_size == u32(0) {
			i_page_size = u32(p_pager.pageSize)
		}
		mut __c2v_condition_19 := false
		mut __c2v_condition_20 := false
		__c2v_condition_20 = i_page_size < u32(512)
		__c2v_condition_19 = __c2v_condition_20
		if !__c2v_condition_19 {
			mut __c2v_condition_21 := false
			__c2v_condition_21 = i_sector_size < u32(32)
			__c2v_condition_19 = __c2v_condition_21
		}
		if !__c2v_condition_19 {
			mut __c2v_condition_22 := false
			__c2v_condition_22 = i_page_size > u32(65536)
			__c2v_condition_19 = __c2v_condition_22
		}
		if !__c2v_condition_19 {
			mut __c2v_condition_23 := false
			__c2v_condition_23 = i_sector_size > u32(65536)
			__c2v_condition_19 = __c2v_condition_23
		}
		if !__c2v_condition_19 {
			mut __c2v_condition_24 := false
			__c2v_condition_24 = ((i_page_size - u32(1)) & i_page_size) != u32(0)
			__c2v_condition_19 = __c2v_condition_24
		}
		if !__c2v_condition_19 {
			mut __c2v_condition_25 := false
			__c2v_condition_25 = ((i_sector_size - u32(1)) & i_sector_size) != u32(0)
			__c2v_condition_19 = __c2v_condition_25
		}
		if __c2v_condition_19 {
			return 101
		}
		rc = sqlite3_pager_set_pagesize(p_pager, &i_page_size, -1)
		p_pager.sectorSize = i_sector_size
	}
	p_pager.journalOff += I64(p_pager.sectorSize)
	return rc
}

@[c:'writeSuperJournal']
fn write_super_journal(p_pager &Pager, z_super &i8) int {
	rc := 0
	n_super := 0
	i_hdr_off := I64(0)
	jrnl_size := I64(0)
	cksum := u32(0)
	if isnil(z_super) || int(p_pager.journalMode) == 4 || !(usize(p_pager.jfd.pMethods) != usize(0)) {
		return 0
	}
	p_pager.setSuper = U8(1)
	for n_super = 0; z_super[n_super]; n_super++ {
		cksum += u32(z_super[n_super])
	}
	if p_pager.fullSync {
		p_pager.journalOff = journal_hdr_offset(p_pager)
	}
	i_hdr_off = p_pager.journalOff
	rc = write32bits(p_pager.jfd, i_hdr_off, p_pager.lckPgno)
	mut __c2v_condition_26 := false
	mut __c2v_condition_27 := false
	__c2v_condition_27 = (0 != rc)
	__c2v_condition_26 = __c2v_condition_27
	if !__c2v_condition_26 {
		mut __c2v_condition_28 := false
		__c2v_condition_28 = (0 != c2v_assign[int](unsafe { &rc }, int(sqlite3_os_write(p_pager.jfd, voidptr(z_super), n_super, i_hdr_off + I64(4)))))
		__c2v_condition_26 = __c2v_condition_28
	}
	if !__c2v_condition_26 {
		mut __c2v_condition_29 := false
		__c2v_condition_29 = (0 != c2v_assign[int](unsafe { &rc }, int(write32bits(p_pager.jfd, i_hdr_off + I64(4) + I64(n_super), u32(n_super)))))
		__c2v_condition_26 = __c2v_condition_29
	}
	if !__c2v_condition_26 {
		mut __c2v_condition_30 := false
		__c2v_condition_30 = (0 != c2v_assign[int](unsafe { &rc }, int(write32bits(p_pager.jfd, i_hdr_off + I64(4) + I64(n_super) + I64(4), cksum))))
		__c2v_condition_26 = __c2v_condition_30
	}
	if !__c2v_condition_26 {
		mut __c2v_condition_31 := false
		__c2v_condition_31 = (0 != c2v_assign[int](unsafe { &rc }, int(sqlite3_os_write(p_pager.jfd, voidptr(unsafe { &aJournalMagic[0] }), 8, i_hdr_off + I64(4) + I64(n_super) + I64(8)))))
		__c2v_condition_26 = __c2v_condition_31
	}
	if __c2v_condition_26 {
		return rc
	}
	p_pager.journalOff += I64((n_super + 20))
	rc = sqlite3_os_file_size(p_pager.jfd, &jrnl_size)
	if 0 == rc && jrnl_size > p_pager.journalOff {
		rc = sqlite3_os_truncate(p_pager.jfd, p_pager.journalOff)
	}
	return rc
}

fn pager_reset(p_pager &Pager) {
	p_pager.iDataVersion++
	sqlite3_backup_restart(p_pager.pBackup)
	sqlite3_pcache_clear(p_pager.pPCache)
}

@[c:'sqlite3PagerDataVersion']
fn sqlite3_pager_data_version(p_pager &Pager) u32 {
	return p_pager.iDataVersion
}

@[c:'releaseAllSavepoints']
fn release_all_savepoints(p_pager &Pager) {
	ii := 0
	for ii = 0; ii < p_pager.nSavepoint; ii++ {
		sqlite3_bitvec_destroy(p_pager.aSavepoint[ii].pInSavepoint)
	}
	if !p_pager.exclusiveMode || sqlite3_journal_is_in_memory(p_pager.sjfd) {
		sqlite3_os_close(p_pager.sjfd)
	}
	sqlite3_free(voidptr(p_pager.aSavepoint))
	p_pager.aSavepoint = 0
	p_pager.nSavepoint = 0
	p_pager.nSubRec = u32(0)
}

@[c:'addToSavepointBitvecs']
fn add_to_savepoint_bitvecs(p_pager &Pager, pgno Pgno) int {
	ii := 0
	rc := 0
	for ii = 0; ii < p_pager.nSavepoint; ii++ {
		p := unsafe { p_pager.aSavepoint + ii }
		if pgno <= p.nOrig {
			rc |= sqlite3_bitvec_set(p.pInSavepoint, pgno)
		}
	}
	return rc
}

fn pager_unlock(p_pager &Pager) {
	sqlite3_bitvec_destroy(p_pager.pInJournal)
	p_pager.pInJournal = 0
	release_all_savepoints(p_pager)
	if (usize(p_pager.pWal) != usize(0)) {
		if int(p_pager.eState) == 6 {
			sqlite3_wal_end_write_transaction(p_pager.pWal)
		}
		sqlite3_wal_end_read_transaction(p_pager.pWal)
		p_pager.eState = U8(0)
	} else if !p_pager.exclusiveMode {
		rc := 0
		i_dc := if (usize(p_pager.fd.pMethods) != usize(0)) {
			sqlite3_os_device_characteristics(p_pager.fd)
		} else {
			0
		}
		if 0 == (i_dc & 2048) || 1 != (int(p_pager.journalMode) & 5) {
			sqlite3_os_close(p_pager.jfd)
		}
		rc = pager_unlock_db(p_pager, 0)
		if rc != 0 && int(p_pager.eState) == 6 {
			p_pager.eLock = U8((4 + 1))
		}
		p_pager.eState = U8(0)
	}
	if p_pager.errCode {
		if int(p_pager.tempFile) == 0 {
			pager_reset(p_pager)
			p_pager.changeCountDone = U8(0)
			p_pager.eState = U8(0)
		} else {
			p_pager.eState = U8((if (usize(p_pager.jfd.pMethods) != usize(0)) { 0 } else { 1 }))
		}
		if p_pager.bUseFetch {
			sqlite3_os_unfetch(p_pager.fd, I64(0), unsafe { nil })
		}
		p_pager.errCode = 0
		set_getter_method(p_pager)
	}
	p_pager.journalOff = I64(0)
	p_pager.journalHdr = I64(0)
	p_pager.setSuper = U8(0)
}

fn pager_error(p_pager &Pager, rc int) int {
	rc2 := rc & 255
	if rc2 == 13 || rc2 == 10 {
		p_pager.errCode = rc
		p_pager.eState = U8(6)
		set_getter_method(p_pager)
	}
	return rc
}

@[c:'pagerFlushOnCommit']
fn pager_flush_on_commit(p_pager &Pager, b_commit int) int {
	if int(p_pager.tempFile) == 0 {
		return 1
	}
	if !b_commit {
		return 0
	}
	if !(usize(p_pager.fd.pMethods) != usize(0)) {
		return 0
	}
	return int((sqlite3_pc_ache_percent_dirty(p_pager.pPCache) >= 25))
}

fn pager_end_transaction(p_pager &Pager, has_super int, b_commit int) int {
	rc := 0
	rc2 := 0
	if int(p_pager.eState) < 2 && int(p_pager.eLock) < 2 {
		return 0
	}
	release_all_savepoints(p_pager)
	if (usize(p_pager.jfd.pMethods) != usize(0)) {
		if sqlite3_journal_is_in_memory(p_pager.jfd) {
			sqlite3_os_close(p_pager.jfd)
		} else if int(p_pager.journalMode) == 3 {
			if p_pager.journalOff == I64(0) {
				rc = 0
			} else {
				rc = sqlite3_os_truncate(p_pager.jfd, I64(0))
				if rc == 0 && int(p_pager.fullSync) {
					rc = sqlite3_os_sync(p_pager.jfd, int(p_pager.syncFlags))
				}
			}
			p_pager.journalOff = I64(0)
		} else if int(p_pager.journalMode) == 1 || (int(p_pager.exclusiveMode) && int(p_pager.journalMode) < 5) {
			rc = zero_journal_hdr(p_pager, has_super || int(p_pager.tempFile))
			p_pager.journalOff = I64(0)
		} else {
			b_delete := int(!p_pager.tempFile)
			sqlite3_os_close(p_pager.jfd)
			if b_delete {
				rc = sqlite3_os_delete(p_pager.pVfs, p_pager.zJournal, int(p_pager.extraSync))
			}
		}
	}
	sqlite3_bitvec_destroy(p_pager.pInJournal)
	p_pager.pInJournal = 0
	p_pager.nRec = 0
	if rc == 0 {
		if int(p_pager.memDb) || pager_flush_on_commit(p_pager, b_commit) {
			sqlite3_pcache_clean_all(p_pager.pPCache)
		} else {
			sqlite3_pcache_clear_writable(p_pager.pPCache)
		}
		sqlite3_pcache_truncate(p_pager.pPCache, p_pager.dbSize)
	}
	if (usize(p_pager.pWal) != usize(0)) {
		rc2 = sqlite3_wal_end_write_transaction(p_pager.pWal)
	} else if rc == 0 && b_commit && p_pager.dbFileSize > p_pager.dbSize {
		rc = pager_truncate(p_pager, p_pager.dbSize)
	}
	if rc == 0 && b_commit {
		rc = sqlite3_os_file_control(p_pager.fd, 22, unsafe { nil })
		if rc == 12 {
			rc = 0
		}
	}
	if !p_pager.exclusiveMode && (!(usize(p_pager.pWal) != usize(0)) || sqlite3_wal_exclusive_mode(p_pager.pWal, 0)) {
		rc2 = pager_unlock_db(p_pager, 1)
	}
	p_pager.eState = U8(1)
	p_pager.setSuper = U8(0)
	return if rc == 0 { rc2 } else { rc }
}

@[c:'pagerUnlockAndRollback']
fn pager_unlock_and_rollback(p_pager &Pager) {
	if int(p_pager.eState) != 6 && int(p_pager.eState) != 0 {
		if int(p_pager.eState) >= 2 {
			sqlite3_begin_benign_malloc()
			sqlite3_pager_rollback(p_pager)
			sqlite3_end_benign_malloc()
		} else if !p_pager.exclusiveMode {
			pager_end_transaction(p_pager, 0, 0)
		}
	} else if int(p_pager.eState) == 6 && int(p_pager.journalMode) == 4 && (usize(p_pager.jfd.pMethods) != usize(0)) {
		err_code := p_pager.errCode
		e_lock := p_pager.eLock
		p_pager.eState = U8(0)
		p_pager.errCode = 0
		p_pager.eLock = U8(4)
		pager_playback(p_pager, 1)
		p_pager.errCode = err_code
		p_pager.eLock = e_lock
	}
	pager_unlock(p_pager)
}

fn pager_cksum(p_pager &Pager, a_data &U8) u32 {
	cksum := p_pager.cksumInit
	i := int(p_pager.pageSize - I64(200))
	for i > 0 {
		cksum += u32(a_data[i])
		i -= 200
	}
	return cksum
}

fn pager_playback_one_page(p_pager &Pager, p_offset &I64, p_done &Bitvec, is_main_jrnl int, is_savepnt int) int {
	rc := 0
	p_pg := &PgHdr(0)
	pgno := Pgno(0)
	cksum := u32(0)
	a_data := &i8(0)
	jfd := &Sqlite3_file(0)
	is_synced := 0
	a_data = p_pager.pTmpSpace
	jfd = if is_main_jrnl { p_pager.jfd } else { p_pager.sjfd }
	rc = read32bits(jfd, (unsafe { *p_offset }), &pgno)
	if rc != 0 {
		return rc
	}
	rc = sqlite3_os_read(jfd, voidptr(&U8(voidptr(a_data))), int(p_pager.pageSize), (unsafe { *p_offset }) + I64(4))
	if rc != 0 {
		return rc
	}
	unsafe { *p_offset += p_pager.pageSize + I64(4) + I64(is_main_jrnl * 4) }
	if pgno == Pgno(0) || pgno == p_pager.lckPgno {
		return 101
	}
	if pgno > Pgno(p_pager.dbSize) || sqlite3_bitvec_test(p_done, pgno) {
		return 0
	}
	if is_main_jrnl {
		rc = read32bits(jfd, (unsafe { *p_offset }) - I64(4), &cksum)
		if rc {
			return rc
		}
		if !is_savepnt && pager_cksum(p_pager, &U8(voidptr(a_data))) != cksum {
			return 101
		}
	}
	if !isnil(p_done) && c2v_assign[int](unsafe { &rc }, int(sqlite3_bitvec_set(p_done, pgno))) != 0 {
		return rc
	}
	if pgno == Pgno(1) && int(p_pager.nReserve) != int((&U8(voidptr(a_data)))[20]) {
		p_pager.nReserve = I16((&U8(voidptr(a_data)))[20])
	}
	if (usize(p_pager.pWal) != usize(0)) {
		p_pg = 0
	} else {
		p_pg = sqlite3_pager_lookup(p_pager, pgno)
	}
	if is_main_jrnl {
		is_synced = int(p_pager.noSync) || ((unsafe { *p_offset }) <= p_pager.journalHdr)
	} else {
		is_synced = (usize(p_pg) == usize(0) || 0 == (int(p_pg.flags) & 8))
	}
	if (usize(p_pager.fd.pMethods) != usize(0)) && (int(p_pager.eState) >= 4 || int(p_pager.eState) == 0) && is_synced {
		ofst := I64((pgno - Pgno(1))) * I64(p_pager.pageSize)
		rc = sqlite3_os_write(p_pager.fd, voidptr(&U8(voidptr(a_data))), int(p_pager.pageSize), ofst)
		if pgno > p_pager.dbFileSize {
			p_pager.dbFileSize = pgno
		}
		if p_pager.pBackup {
			sqlite3_backup_update(p_pager.pBackup, pgno, &U8(voidptr(a_data)))
		}
	} else if !is_main_jrnl && usize(p_pg) == usize(0) {
		p_pager.doNotSpill |= 2
		rc = sqlite3_pager_get(p_pager, pgno, unsafe { &&DbPage(&&PgHdr(c2v_address_of(&p_pg))) }, 1)
		p_pager.doNotSpill &= ~2
		if rc != 0 {
			return rc
		}
		sqlite3_pcache_make_dirty(p_pg)
	}
	if p_pg {
		p_data := &voidptr(0)
		p_data = p_pg.pData
		C.memcpy(voidptr(p_data), voidptr(&U8(voidptr(a_data))), u64(p_pager.pageSize))
		p_pager.xReiniter(unsafe { &DbPage(p_pg) })
		if pgno == Pgno(1) {
			C.memcpy(voidptr(&p_pager.dbFileVers), voidptr(unsafe { (&U8(p_data)) + 24 }), sizeof([16]i8))
		}
		sqlite3_pcache_release(p_pg)
	}
	return rc
}

@[c:'pagerIsSuperJrnlName']
fn pager_is_super_jrnl_name(z_super &i8) int {
	n_super := sqlite3_strlen30(z_super)
	ii := 0
	if n_super < 4 {
		return 0
	}
	if int(z_super[n_super - 3]) != i8(`9`) {
		return 0
	}
	if n_super < 12 {
		return 0
	}
	if C.memcmp(voidptr(unsafe { z_super + (n_super - 12) }), voidptr(c'-mj'), u64(3)) {
		return 0
	}
	for ii = n_super - 9; ii < n_super; ii++ {
		if (int(sqlite3CtypeMap[u8(z_super[ii])]) & 8) == 0 {
			return 0
		}
	}
	return 1
}

fn pager_delsuper(p_pager &Pager, z_super &i8) int {
	p_vfs := p_pager.pVfs
	rc := 0
	p_super := &Sqlite3_file(0)
	p_journal := &Sqlite3_file(0)
	z_super_journal := unsafe { &i8(nil) }
	n_super_journal := I64(0)
	z_journal := &i8(0)
	z_free := unsafe { &i8(nil) }
	b_seen := 0
	if pager_is_super_jrnl_name(z_super) == 0 {
		return 0
	}
	p_super = &Sqlite3_file(sqlite3_malloc_zero(U64(I64(2) * I64(p_vfs.szOsFile))))
	if isnil(p_super) {
		rc = 7
		p_journal = 0
	} else {
		flags := (1 | 16384)
		rc = sqlite3_os_open(p_vfs, z_super, p_super, flags, unsafe { nil })
		p_journal = &Sqlite3_file(voidptr(((&U8(voidptr(p_super))) + p_vfs.szOsFile)))
	}
	if rc != 0 {
		unsafe { goto delsuper_out
		 }
	}
	rc = sqlite3_os_file_size(p_super, &n_super_journal)
	if rc != 0 {
		unsafe { goto delsuper_out
		 }
	}
	z_free = &i8(sqlite3_malloc_vdup2(U64(I64(4) + n_super_journal + I64(2))))
	if isnil(z_free) {
		rc = 7
		unsafe { goto delsuper_out
		 }
	} else {
	}
	z_free[3] = i8(0)
	z_free[2] = z_free[3]
	z_free[1] = z_free[2]
	z_free[0] = z_free[1]
	z_super_journal = unsafe { z_free + 4 }
	rc = sqlite3_os_read(p_super, voidptr(z_super_journal), int(n_super_journal), I64(0))
	if rc != 0 {
		unsafe { goto delsuper_out
		 }
	}
	z_super_journal[n_super_journal] = i8(0)
	z_super_journal[n_super_journal + I64(1)] = i8(0)
	z_journal = z_super_journal
	for I64((i64((isize(z_journal) - isize(z_super_journal)) / isize(sizeof(i8))))) < n_super_journal {
		if C.strcmp(z_journal, p_pager.zJournal) == 0 {
			b_seen = 1
		} else {
			exists := 0
			rc = sqlite3_os_access(p_vfs, z_journal, 0, &exists)
			if rc != 0 {
				unsafe { goto delsuper_out
				 }
			}
			if exists {
				z_super_ptr := unsafe { &i8(nil) }
				c := 0
				flags := (1 | 16384)
				rc = sqlite3_os_open(p_vfs, z_journal, p_journal, flags, unsafe { nil })
				if rc != 0 {
					unsafe { goto delsuper_out
					 }
				}
				rc = read_super_journal(p_journal, U64(1) + U64(p_vfs.mxPathname), &&u8(&&i8(c2v_address_of(&z_super_ptr))))
				sqlite3_os_close(p_journal)
				if rc != 0 {
					unsafe { goto delsuper_out
					 }
				}
				c = usize(z_super_ptr) != usize(0) && C.strcmp(z_super_ptr, z_super) == 0
				free_super_journal(z_super_ptr)
				if c {
					unsafe { goto delsuper_out
					 }
				}
			}
		}
		c2v_pointer_prefix(voidptr(&z_journal), z_journal, isize((sqlite3_strlen30(z_journal) + 1)))
	}
	sqlite3_os_close(p_super)
	if b_seen {
		rc = sqlite3_os_delete(p_vfs, z_super, 0)
	}
	delsuper_out:
	sqlite3_free(voidptr(z_free))
	if p_super {
		sqlite3_os_close(p_super)
		sqlite3_free(voidptr(p_super))
	}
	return rc
}

fn pager_truncate(p_pager &Pager, n_page Pgno) int {
	rc := 0
	if (usize(p_pager.fd.pMethods) != usize(0)) && (int(p_pager.eState) >= 4 || int(p_pager.eState) == 0) {
		current_size := I64(0)
		new_size := I64(0)

		sz_page := int(p_pager.pageSize)
		rc = sqlite3_os_file_size(p_pager.fd, &current_size)
		new_size = I64(sz_page) * I64(n_page)
		if rc == 0 && current_size != new_size {
			if current_size > new_size {
				rc = sqlite3_os_truncate(p_pager.fd, new_size)
			} else if (current_size + I64(sz_page)) <= new_size {
				p_tmp := p_pager.pTmpSpace
				C.memset(voidptr(p_tmp), 0, u64(sz_page))
				sqlite3_os_file_control_hint(p_pager.fd, 5, voidptr(&new_size))
				rc = sqlite3_os_write(p_pager.fd, voidptr(p_tmp), sz_page, new_size - I64(sz_page))
			}
			if rc == 0 {
				p_pager.dbFileSize = n_page
			}
		}
	}
	return rc
}

@[c:'sqlite3SectorSize']
fn sqlite3_sector_size(p_file &Sqlite3_file) int {
	i_ret := sqlite3_os_sector_size(p_file)
	if i_ret < 32 {
		i_ret = 512
	} else if i_ret > 65536 {
		i_ret = 65536
	}
	return i_ret
}

@[c:'setSectorSize']
fn set_sector_size(p_pager &Pager) {
	if int(p_pager.tempFile) || (sqlite3_os_device_characteristics(p_pager.fd) & 4096) != 0 {
		p_pager.sectorSize = u32(512)
	} else {
		p_pager.sectorSize = u32(sqlite3_sector_size(p_pager.fd))
	}
}

fn pager_playback(p_pager &Pager, is_hot int) int {
	p_vfs := p_pager.pVfs
	sz_j := I64(0)
	n_rec := u32(0)
	u := u32(0)
	mx_pg := Pgno(0)
	rc := 0
	res := 1
	z_super := unsafe { &i8(nil) }
	need_pager_reset := 0
	n_playback := 0
	saved_page_size := u32(p_pager.pageSize)
	rc = sqlite3_os_file_size(p_pager.jfd, &sz_j)
	if rc != 0 {
		unsafe { goto end_playback
		 }
	}
	rc = read_super_journal(p_pager.jfd, U64(I64(1) + I64(p_pager.pVfs.mxPathname)), &&u8(&&i8(c2v_address_of(&z_super))))
	if rc == 0 && !isnil(z_super) {
		rc = sqlite3_os_access(p_vfs, z_super, 0, &res)
	}
	if rc != 0 || !res {
		unsafe { goto end_playback
		 }
	}
	p_pager.journalOff = I64(0)
	need_pager_reset = is_hot
	for {
		rc = read_journal_hdr(p_pager, is_hot, sz_j, &n_rec, &mx_pg)
		if rc != 0 {
			if rc == 101 {
				rc = 0
			}
			unsafe { goto end_playback
			 }
		}
		if n_rec == u32(4294967295) {
			n_rec = u32(int(((sz_j - I64(p_pager.sectorSize)) / (p_pager.pageSize + I64(8)))))
		}
		if n_rec == u32(0) && !is_hot && p_pager.journalHdr + I64(p_pager.sectorSize) == p_pager.journalOff {
			n_rec = u32(int(((sz_j - p_pager.journalOff) / (p_pager.pageSize + I64(8)))))
		}
		if p_pager.journalOff == I64(p_pager.sectorSize) {
			rc = pager_truncate(p_pager, mx_pg)
			if rc != 0 {
				unsafe { goto end_playback
				 }
			}
			p_pager.dbSize = mx_pg
			if p_pager.mxPgno < mx_pg {
				p_pager.mxPgno = mx_pg
			}
		}
		for u = u32(0); u < n_rec; u++ {
			if need_pager_reset {
				pager_reset(p_pager)
				need_pager_reset = 0
			}
			rc = pager_playback_one_page(p_pager, &p_pager.journalOff, unsafe { nil }, 1, 0)
			if rc == 0 {
				n_playback++
			} else {
				if rc == 101 {
					p_pager.journalOff = sz_j
					break
				} else if rc == (10 | (2 << 8)) {
					rc = 0
					unsafe { goto end_playback
					 }
				} else {
					unsafe { goto end_playback
					 }
				}
			}
		}
	}
	end_playback:
	if rc == 0 {
		rc = sqlite3_pager_set_pagesize(p_pager, &saved_page_size, -1)
	}
	p_pager.changeCountDone = p_pager.tempFile
	if rc == 0 && (int(p_pager.eState) >= 4 || int(p_pager.eState) == 0) {
		rc = sqlite3_pager_sync(p_pager, unsafe { nil })
	}
	if rc == 0 {
		rc = pager_end_transaction(p_pager, usize(z_super) != usize(0), 0)
	}
	if rc == 0 && !isnil(z_super) && res {
		rc = pager_delsuper(p_pager, z_super)
	}
	if is_hot && n_playback {
		sqlite3_log((27 | (2 << 8)), c'recovered %d pages from %s', n_playback, voidptr(p_pager.zJournal))
	}
	free_super_journal(z_super)
	set_sector_size(p_pager)
	return rc
}

@[c:'readDbPage']
fn read_db_page(p_pg &PgHdr) int {
	p_pager := p_pg.pPager
	rc := 0
	i_frame := u32(0)
	if (usize(p_pager.pWal) != usize(0)) {
		rc = sqlite3_wal_find_frame(p_pager.pWal, p_pg.pgno, &i_frame)
		if rc {
			return rc
		}
	}
	if i_frame {
		rc = sqlite3_wal_read_frame(p_pager.pWal, i_frame, int(p_pager.pageSize), p_pg.pData)
	} else {
		i_offset := I64((p_pg.pgno - Pgno(1))) * I64(p_pager.pageSize)
		rc = sqlite3_os_read(p_pager.fd, voidptr(p_pg.pData), int(p_pager.pageSize), i_offset)
		if rc == (10 | (2 << 8)) {
			rc = 0
		}
	}
	if p_pg.pgno == Pgno(1) {
		if rc {
			C.memset(p_pager.dbFileVers, 255, sizeof([16]i8))
		} else {
			db_file_vers := unsafe { (&U8(p_pg.pData)) + 24 }
			C.memcpy(voidptr(&p_pager.dbFileVers), voidptr(db_file_vers), sizeof([16]i8))
		}
	}
	return rc
}

fn pager_write_changecounter(p_pg &PgHdr) {
	change_counter := u32(0)
	if (usize(p_pg) == usize(0)) {
		return
	}
	change_counter = sqlite3_get4byte(&U8(voidptr(unsafe { &p_pg.pPager.dbFileVers[0] }))) + u32(1)
	sqlite3_put4byte(&U8(voidptr((&i8(p_pg.pData)))) + 24, change_counter)
	sqlite3_put4byte(&U8(voidptr((&i8(p_pg.pData)))) + 92, change_counter)
	sqlite3_put4byte(&U8(voidptr((&i8(p_pg.pData)))) + 96, u32(3053004))
}

@[c:'pagerUndoCallback']
fn pager_undo_callback(p_ctx voidptr, i_pg Pgno) int {
	c2v_gc_register_thread()
	rc := 0
	p_pager := &Pager(p_ctx)
	p_pg := &PgHdr(0)
	p_pg = sqlite3_pager_lookup(p_pager, i_pg)
	if p_pg {
		if sqlite3_pcache_page_refcount(p_pg) == I64(1) {
			sqlite3_pcache_drop(p_pg)
		} else {
			rc = read_db_page(p_pg)
			if rc == 0 {
				p_pager.xReiniter(unsafe { &DbPage(p_pg) })
			}
			sqlite3_pager_unref_not_null(unsafe { &DbPage(p_pg) })
		}
	}
	sqlite3_backup_restart(p_pager.pBackup)
	return rc
}

@[c:'pagerRollbackWal']
fn pager_rollback_wal(p_pager &Pager) int {
	rc := 0
	p_list := &PgHdr(0)
	p_pager.dbSize = p_pager.dbOrigSize
	rc = sqlite3_wal_undo(p_pager.pWal, pager_undo_callback, voidptr(p_pager))
	p_list = sqlite3_pcache_dirty_list(p_pager.pPCache)
	for !isnil(p_list) && rc == 0 {
		p_next := p_list.pDirty
		rc = pager_undo_callback(voidptr(p_pager), p_list.pgno)
		p_list = p_next
	}
	return rc
}

@[c:'pagerWalFrames']
fn pager_wal_frames(p_pager &Pager, p_list_param &PgHdr, n_truncate Pgno, is_commit int) int {
	mut p_list := p_list_param
	rc := 0
	n_list := 0
	p := &PgHdr(0)
	if is_commit {
		pp_next := &&PgHdr(c2v_address_of(&p_list))
		n_list = 0
		for p = p_list; true; p = p.pDirty {
			unsafe { *pp_next = p }
			if !(usize((unsafe { *pp_next })) != usize(0)) {
				break
			}
			if p.pgno <= n_truncate {
				pp_next = &p.pDirty
				n_list++
			}
		}
	} else {
		n_list = 1
	}
	p_pager.aStat[2] += u32(n_list)
	if p_list.pgno == Pgno(1) {
		pager_write_changecounter(p_list)
	}
	rc = sqlite3_wal_frames(p_pager.pWal, int(p_pager.pageSize), p_list, n_truncate, is_commit, int(p_pager.walSyncFlags))
	if rc == 0 && !isnil(p_pager.pBackup) {
		for p = p_list; p; p = p.pDirty {
			sqlite3_backup_update(p_pager.pBackup, p.pgno, &U8(p.pData))
		}
	}
	return rc
}

@[c:'pagerBeginReadTransaction']
fn pager_begin_read_transaction(p_pager &Pager) int {
	rc := 0
	changed := 0
	sqlite3_wal_end_read_transaction(p_pager.pWal)
	rc = sqlite3_wal_begin_read_transaction(p_pager.pWal, &changed)
	if rc != 0 || changed {
		pager_reset(p_pager)
		if p_pager.bUseFetch {
			sqlite3_os_unfetch(p_pager.fd, I64(0), unsafe { nil })
		}
	}
	return rc
}

@[c:'pagerPagecount']
fn pager_pagecount(p_pager &Pager, pn_page &Pgno) int {
	n_page := Pgno(0)
	n_page = sqlite3_wal_dbsize(p_pager.pWal)
	if n_page == Pgno(0) && (usize(p_pager.fd.pMethods) != usize(0)) {
		n := I64(0)
		rc := sqlite3_os_file_size(p_pager.fd, &n)
		if rc != 0 {
			return rc
		}
		n_page = Pgno(((n + p_pager.pageSize - I64(1)) / p_pager.pageSize))
	}
	if n_page > p_pager.mxPgno {
		p_pager.mxPgno = Pgno(n_page)
	}
	unsafe { *pn_page = n_page }
	return 0
}

@[c:'pagerOpenWalIfPresent']
fn pager_open_wal_if_present(p_pager &Pager) int {
	rc := 0
	if !p_pager.tempFile {
		is_wal := 0
		rc = sqlite3_os_access(p_pager.pVfs, p_pager.zWal, 0, &is_wal)
		if rc == 0 {
			if is_wal {
				n_page := Pgno(0)
				rc = pager_pagecount(p_pager, &n_page)
				if rc {
					return rc
				}
				if n_page == Pgno(0) {
					rc = sqlite3_os_delete(p_pager.pVfs, p_pager.zWal, 0)
				} else {
					rc = sqlite3_pager_open_wal(p_pager, unsafe { nil })
				}
			} else if int(p_pager.journalMode) == 5 {
				p_pager.journalMode = U8(0)
			}
		}
	}
	return rc
}

@[c:'pagerPlaybackSavepoint']
fn pager_playback_savepoint(p_pager &Pager, p_savepoint &PagerSavepoint) int {
	sz_j := I64(0)
	i_hdr_off := I64(0)
	rc := 0
	p_done := unsafe { &Bitvec(nil) }
	if p_savepoint {
		p_done = sqlite3_bitvec_create(p_savepoint.nOrig)
		if isnil(p_done) {
			return 7
		}
	}
	p_pager.dbSize = if p_savepoint { p_savepoint.nOrig } else { p_pager.dbOrigSize }
	p_pager.changeCountDone = p_pager.tempFile
	if isnil(p_savepoint) && (usize(p_pager.pWal) != usize(0)) {
		return pager_rollback_wal(p_pager)
	}
	sz_j = p_pager.journalOff
	if !isnil(p_savepoint) && !(usize(p_pager.pWal) != usize(0)) {
		i_hdr_off = if p_savepoint.iHdrOffset { p_savepoint.iHdrOffset } else { sz_j }
		p_pager.journalOff = p_savepoint.iOffset
		for rc == 0 && p_pager.journalOff < i_hdr_off {
			rc = pager_playback_one_page(p_pager, &p_pager.journalOff, p_done, 1, 1)
		}
	} else {
		p_pager.journalOff = I64(0)
	}
	for rc == 0 && p_pager.journalOff < sz_j {
		ii := u32(0)
		njr_ec := u32(0)
		dummy := u32(0)
		rc = read_journal_hdr(p_pager, 0, sz_j, &njr_ec, &dummy)
		if njr_ec == u32(0) && p_pager.journalHdr + I64(p_pager.sectorSize) == p_pager.journalOff {
			njr_ec = u32(((sz_j - p_pager.journalOff) / (p_pager.pageSize + I64(8))))
		}
		for ii = u32(0); rc == 0 && ii < njr_ec && p_pager.journalOff < sz_j; ii++ {
			rc = pager_playback_one_page(p_pager, &p_pager.journalOff, p_done, 1, 1)
		}
	}
	if p_savepoint {
		ii := u32(0)
		offset := I64(p_savepoint.iSubRec) * (I64(4) + p_pager.pageSize)
		if (usize(p_pager.pWal) != usize(0)) {
			rc = sqlite3_wal_savepoint_undo(p_pager.pWal, &p_savepoint.aWalData[0])
		}
		for ii = p_savepoint.iSubRec; rc == 0 && ii < p_pager.nSubRec; ii++ {
			rc = pager_playback_one_page(p_pager, &offset, p_done, 0, 1)
		}
	}
	sqlite3_bitvec_destroy(p_done)
	if rc == 0 {
		p_pager.journalOff = sz_j
	}
	return rc
}

@[c:'sqlite3PagerSetCachesize']
fn sqlite3_pager_set_cachesize(p_pager &Pager, mx_page int) {
	sqlite3_pcache_set_cachesize(p_pager.pPCache, mx_page)
}

@[c:'sqlite3PagerSetSpillsize']
fn sqlite3_pager_set_spillsize(p_pager &Pager, mx_page int) int {
	return sqlite3_pcache_set_spillsize(p_pager.pPCache, mx_page)
}

@[c:'pagerFixMaplimit']
fn pager_fix_maplimit(p_pager &Pager) {
	fd := p_pager.fd
	if (usize(fd.pMethods) != usize(0)) && fd.pMethods.iVersion >= 3 {
		sz := Sqlite3_int64(0)
		sz = p_pager.szMmap
		p_pager.bUseFetch = U8((sz > Sqlite3_int64(0)))
		set_getter_method(p_pager)
		sqlite3_os_file_control_hint(p_pager.fd, 18, voidptr(&sz))
	}
}

@[c:'sqlite3PagerSetMmapLimit']
fn sqlite3_pager_set_mmap_limit(p_pager &Pager, sz_mmap Sqlite3_int64) {
	p_pager.szMmap = sz_mmap
	pager_fix_maplimit(p_pager)
}

@[c:'sqlite3PagerShrink']
fn sqlite3_pager_shrink(p_pager &Pager) {
	sqlite3_pcache_shrink(p_pager.pPCache)
}

@[c:'sqlite3PagerSetFlags']
fn sqlite3_pager_set_flags(p_pager &Pager, pg_flags u32) {
	level := pg_flags & u32(7)
	if int(p_pager.tempFile) || level == u32(1) {
		p_pager.noSync = U8(1)
		p_pager.fullSync = U8(0)
		p_pager.extraSync = U8(0)
	} else {
		p_pager.noSync = U8(0)
		p_pager.fullSync = U8(if level >= u32(3) { 1 } else { 0 })
		if level == u32(4) {
			p_pager.extraSync = U8(1)
		} else {
			p_pager.extraSync = U8(0)
		}
	}
	if p_pager.noSync {
		p_pager.syncFlags = U8(0)
	} else if pg_flags & u32(8) {
		p_pager.syncFlags = U8(3)
	} else {
		p_pager.syncFlags = U8(2)
	}
	p_pager.walSyncFlags = U8((int(p_pager.syncFlags) << 2))
	if p_pager.fullSync {
		p_pager.walSyncFlags |= int(p_pager.syncFlags)
	}
	if (pg_flags & u32(16)) && !p_pager.noSync {
		p_pager.walSyncFlags |= (3 << 2)
	}
	if pg_flags & u32(32) {
		p_pager.doNotSpill &= ~1
	} else {
		p_pager.doNotSpill |= 1
	}
}

@[c:'pagerOpentemp']
fn pager_opentemp(p_pager &Pager, p_file &Sqlite3_file, vfs_flags int) int {
	rc := 0
	vfs_flags |= 2 | 4 | 16 | 8
	rc = sqlite3_os_open(p_pager.pVfs, unsafe { nil }, p_file, vfs_flags, unsafe { nil })
	return rc
}

@[c:'sqlite3PagerSetBusyHandler']
fn sqlite3_pager_set_busy_handler(p_pager &Pager, x_busy_handler fn (voidptr) int, p_busy_handler_arg voidptr) {
	ap := &voidptr(0)
	p_pager.xBusyHandler = x_busy_handler
	p_pager.pBusyHandlerArg = p_busy_handler_arg
	ap = &voidptr(&p_pager.xBusyHandler)
	sqlite3_os_file_control_hint(p_pager.fd, 15, voidptr(ap))
}

@[c:'sqlite3PagerSetPagesize']
fn sqlite3_pager_set_pagesize(p_pager &Pager, p_page_size &u32, n_reserve int) int {
	rc := 0
	page_size := (unsafe { *p_page_size })
	if (int(p_pager.memDb) == 0 || p_pager.dbSize == Pgno(0)) && sqlite3_pcache_ref_count(p_pager.pPCache) == I64(0) && page_size && page_size != u32(p_pager.pageSize) {
		p_new := unsafe { &i8(nil) }
		n_byte := I64(0)
		if int(p_pager.eState) > 0 && (usize(p_pager.fd.pMethods) != usize(0)) {
			rc = sqlite3_os_file_size(p_pager.fd, &n_byte)
		}
		if rc == 0 {
			p_new = &i8(sqlite3_page_malloc(int(page_size + u32(8))))
			if isnil(p_new) {
				rc = 7
			} else {
				C.memset(voidptr(p_new + page_size), 0, u64(8))
			}
		}
		if rc == 0 {
			pager_reset(p_pager)
			rc = sqlite3_pcache_set_page_size(p_pager.pPCache, int(page_size))
		}
		if rc == 0 {
			sqlite3_page_free(voidptr(p_pager.pTmpSpace))
			p_pager.pTmpSpace = p_new
			p_pager.dbSize = Pgno(((n_byte + I64(page_size) - I64(1)) / I64(page_size)))
			p_pager.pageSize = I64(page_size)
			p_pager.lckPgno = Pgno((u32(sqlite3PendingByte) / page_size)) + Pgno(1)
		} else {
			sqlite3_page_free(voidptr(p_new))
		}
	}
	unsafe { *p_page_size = u32(p_pager.pageSize) }
	if rc == 0 {
		if n_reserve < 0 {
			n_reserve = int(p_pager.nReserve)
		}
		p_pager.nReserve = I16(n_reserve)
		pager_fix_maplimit(p_pager)
	}
	return rc
}

@[c:'sqlite3PagerTempSpace']
fn sqlite3_pager_temp_space(p_pager &Pager) voidptr {
	return p_pager.pTmpSpace
}

@[c:'sqlite3PagerMaxPageCount']
fn sqlite3_pager_max_page_count(p_pager &Pager, mx_page Pgno) Pgno {
	if mx_page > Pgno(0) {
		p_pager.mxPgno = mx_page
	}
	return p_pager.mxPgno
}

@[c:'sqlite3PagerReadFileheader']
fn sqlite3_pager_read_fileheader(p_pager &Pager, n int, p_dest &u8) int {
	rc := 0
	C.memset(voidptr(p_dest), 0, u64(n))
	if (usize(p_pager.fd.pMethods) != usize(0)) {
		rc = sqlite3_os_read(p_pager.fd, voidptr(p_dest), n, I64(0))
		if rc == (10 | (2 << 8)) {
			rc = 0
		}
	}
	return rc
}

@[c:'sqlite3PagerPagecount']
fn sqlite3_pager_pagecount(p_pager &Pager, pn_page &int) {
	unsafe { *pn_page = int(p_pager.dbSize) }
}

fn pager_wait_on_lock(p_pager &Pager, locktype int) int {
	rc := 0
	for {
		rc = pager_lock_db(p_pager, locktype)
		if !(rc == 5 && p_pager.xBusyHandler(voidptr(p_pager.pBusyHandlerArg))) {
			break
		}
	}
	return rc
}

@[c:'sqlite3PagerTruncateImage']
fn sqlite3_pager_truncate_image(p_pager &Pager, n_page Pgno) {
	p_pager.dbSize = n_page
}

@[c:'pagerSyncHotJournal']
fn pager_sync_hot_journal(p_pager &Pager) int {
	rc := 0
	if !p_pager.noSync {
		rc = sqlite3_os_sync(p_pager.jfd, 2)
	}
	if rc == 0 {
		rc = sqlite3_os_file_size(p_pager.jfd, &p_pager.journalHdr)
	}
	return rc
}

@[c:'pagerAcquireMapPage']
fn pager_acquire_map_page(p_pager &Pager, pgno Pgno, p_data voidptr, pp_page &&PgHdr) int {
	p := &PgHdr(0)
	if p_pager.pMmapFreelist {
		p = p_pager.pMmapFreelist
		unsafe { *pp_page = p }
		p_pager.pMmapFreelist = p.pDirty
		p.pDirty = 0
		C.memset(voidptr(p.pExtra), 0, u64(8))
	} else {
		p = &PgHdr(sqlite3_malloc_zero(U64(sizeof(PgHdr) + u64(p_pager.nExtra))))
		unsafe { *pp_page = p }
		if usize(p) == usize(0) {
			sqlite3_os_unfetch(p_pager.fd, I64((pgno - Pgno(1))) * p_pager.pageSize, voidptr(p_data))
			return 7
		}
		p.pExtra = voidptr(unsafe { p + 1 })
		p.flags = U16(32)
		p.nRef = I64(1)
		p.pPager = p_pager
	}
	p.pgno = pgno
	p.pData = p_data
	p_pager.nMmapOut++
	return 0
}

@[c:'pagerReleaseMapPage']
fn pager_release_map_page(p_pg &PgHdr) {
	p_pager := p_pg.pPager
	p_pager.nMmapOut--
	p_pg.pDirty = p_pager.pMmapFreelist
	p_pager.pMmapFreelist = p_pg
	sqlite3_os_unfetch(p_pager.fd, I64((p_pg.pgno - Pgno(1))) * p_pager.pageSize, voidptr(p_pg.pData))
}

@[c:'pagerFreeMapHdrs']
fn pager_free_map_hdrs(p_pager &Pager) {
	p := &PgHdr(0)
	p_next := &PgHdr(0)
	for p = p_pager.pMmapFreelist; p; p = p_next {
		p_next = p.pDirty
		sqlite3_free(voidptr(p))
	}
}

@[c:'databaseIsUnmoved']
fn database_is_unmoved(p_pager &Pager) int {
	b_has_moved := 0
	rc := 0
	if p_pager.tempFile {
		return 0
	}
	if p_pager.dbSize == Pgno(0) {
		return 0
	}
	rc = sqlite3_os_file_control(p_pager.fd, 20, voidptr(&b_has_moved))
	if rc == 12 {
		rc = 0
	} else if rc == 0 && b_has_moved {
		rc = (8 | (4 << 8))
	}
	return rc
}

@[c:'sqlite3PagerClose']
fn sqlite3_pager_close(p_pager &Pager, db &Sqlite3) int {
	p_tmp := &U8(voidptr(p_pager.pTmpSpace))
	sqlite3_begin_benign_malloc()
	pager_free_map_hdrs(p_pager)
	p_pager.exclusiveMode = U8(0)
	a := unsafe { &U8(nil) }
	if !isnil(db) && U64(0) == (db.flags & U64(2048)) && 0 == database_is_unmoved(p_pager) {
		a = p_tmp
	}
	sqlite3_wal_close(p_pager.pWal, db, int(p_pager.walSyncFlags), int(p_pager.pageSize), a)
	p_pager.pWal = 0
	pager_reset(p_pager)
	if p_pager.memDb {
		pager_unlock(p_pager)
	} else {
		if (usize(p_pager.jfd.pMethods) != usize(0)) {
			pager_error(p_pager, pager_sync_hot_journal(p_pager))
		}
		pager_unlock_and_rollback(p_pager)
	}
	sqlite3_end_benign_malloc()
	sqlite3_os_close(p_pager.jfd)
	sqlite3_os_close(p_pager.fd)
	sqlite3_page_free(voidptr(p_tmp))
	sqlite3_pcache_close(p_pager.pPCache)
	sqlite3_free(voidptr(p_pager))
	return 0
}

@[c:'sqlite3PagerRef']
fn sqlite3_pager_ref(p_pg &DbPage) {
	sqlite3_pcache_ref(unsafe { &PgHdr(p_pg) })
}

@[c:'syncJournal']
fn sync_journal(p_pager &Pager, new_hdr int) int {
	rc := 0
	rc = sqlite3_pager_exclusive_lock(p_pager)
	if rc != 0 {
		return rc
	}
	if !p_pager.noSync {
		if (usize(p_pager.jfd.pMethods) != usize(0)) && int(p_pager.journalMode) != 4 {
			i_dc := sqlite3_os_device_characteristics(p_pager.fd)
			if 0 == (i_dc & 512) {
				i_next_hdr_offset := I64(0)
				a_magic := [8]U8{}
				z_header := [12]U8{}
				C.memcpy(voidptr(unsafe { &z_header[0] }), voidptr(unsafe { &aJournalMagic[0] }), sizeof([8]u8))
				sqlite3_put4byte(&U8(unsafe { &z_header[0] + sizeof([8]u8) }), u32(p_pager.nRec))
				i_next_hdr_offset = journal_hdr_offset(p_pager)
				rc = sqlite3_os_read(p_pager.jfd, voidptr(unsafe { &a_magic[0] }), 8, i_next_hdr_offset)
				if rc == 0 && 0 == C.memcmp(voidptr(unsafe { &a_magic[0] }), voidptr(unsafe { &aJournalMagic[0] }), u64(8)) {
					if !sync_journal_zerobyte_inited {
						sync_journal_zerobyte = U8(0)
						sync_journal_zerobyte_inited = true
					}

					rc = sqlite3_os_write(p_pager.jfd, voidptr(&sync_journal_zerobyte), 1, i_next_hdr_offset)
				}
				if rc != 0 && rc != (10 | (2 << 8)) {
					return rc
				}
				if int(p_pager.fullSync) && 0 == (i_dc & 1024) {
					rc = sqlite3_os_sync(p_pager.jfd, int(p_pager.syncFlags))
					if rc != 0 {
						return rc
					}
				}
				rc = sqlite3_os_write(p_pager.jfd, voidptr(unsafe { &z_header[0] }), int(sizeof([12]U8)), p_pager.journalHdr)
				if rc != 0 {
					return rc
				}
			}
			if 0 == (i_dc & 1024) {
				rc = sqlite3_os_sync(p_pager.jfd, int(p_pager.syncFlags) | (if int(p_pager.syncFlags) == 3 {
					16
				} else {
					0
				}))
				if rc != 0 {
					return rc
				}
			}
			p_pager.journalHdr = p_pager.journalOff
			if new_hdr && 0 == (i_dc & 512) {
				p_pager.nRec = 0
				rc = write_journal_hdr(p_pager)
				if rc != 0 {
					return rc
				}
			}
		} else {
			p_pager.journalHdr = p_pager.journalOff
		}
	}
	sqlite3_pcache_clear_sync_flags(p_pager.pPCache)
	p_pager.eState = U8(4)
	return 0
}

fn pager_write_pagelist(p_pager &Pager, p_list &PgHdr) int {
	rc := 0
	if !(usize(p_pager.fd.pMethods) != usize(0)) {
		rc = pager_opentemp(p_pager, p_pager.fd, int(p_pager.vfsFlags))
	}
	if rc == 0 && p_pager.dbHintSize < p_pager.dbSize && (!isnil(p_list.pDirty) || p_list.pgno > p_pager.dbHintSize) {
		sz_file := p_pager.pageSize * Sqlite3_int64(p_pager.dbSize)
		sqlite3_os_file_control_hint(p_pager.fd, 5, voidptr(&sz_file))
		p_pager.dbHintSize = p_pager.dbSize
	}
	for rc == 0 && !isnil(p_list) {
		pgno := p_list.pgno
		if pgno <= p_pager.dbSize && 0 == (int(p_list.flags) & 16) {
			offset := I64((pgno - Pgno(1))) * I64(p_pager.pageSize)
			p_data := &i8(0)
			if p_list.pgno == Pgno(1) {
				pager_write_changecounter(p_list)
			}
			p_data = &i8(p_list.pData)
			rc = sqlite3_os_write(p_pager.fd, voidptr(p_data), int(p_pager.pageSize), offset)
			if pgno == Pgno(1) {
				C.memcpy(voidptr(&p_pager.dbFileVers), voidptr(unsafe { p_data + 24 }), sizeof([16]i8))
			}
			if pgno > p_pager.dbFileSize {
				p_pager.dbFileSize = pgno
			}
			p_pager.aStat[2]++
			sqlite3_backup_update(p_pager.pBackup, pgno, &U8(p_list.pData))
		} else {
		}
		p_list = p_list.pDirty
	}
	return rc
}

@[c:'openSubJournal']
fn open_sub_journal(p_pager &Pager) int {
	rc := 0
	if !(usize(p_pager.sjfd.pMethods) != usize(0)) {
		flags := 8192 | 2 | 4 | 16 | 8
		n_stmt_spill := sqlite3Config.nStmtSpill
		if int(p_pager.journalMode) == 4 || int(p_pager.subjInMemory) {
			n_stmt_spill = -1
		}
		rc = sqlite3_journal_open(p_pager.pVfs, unsafe { nil }, p_pager.sjfd, flags, n_stmt_spill)
	}
	return rc
}

@[c:'subjournalPage']
fn subjournal_page(p_pg &PgHdr) int {
	rc := 0
	p_pager := p_pg.pPager
	if int(p_pager.journalMode) != 2 {
		rc = open_sub_journal(p_pager)
		if rc == 0 {
			p_data := p_pg.pData
			offset := I64(p_pager.nSubRec) * (I64(4) + p_pager.pageSize)
			p_data2 := &i8(0)
			p_data2 = &i8(p_data)
			rc = write32bits(p_pager.sjfd, offset, p_pg.pgno)
			if rc == 0 {
				rc = sqlite3_os_write(p_pager.sjfd, voidptr(p_data2), int(p_pager.pageSize), offset + I64(4))
			}
		}
	}
	if rc == 0 {
		p_pager.nSubRec++
		rc = add_to_savepoint_bitvecs(p_pager, p_pg.pgno)
	}
	return rc
}

@[c:'subjournalPageIfRequired']
fn subjournal_page_if_required(p_pg &PgHdr) int {
	if subj_requires_page(p_pg) {
		return subjournal_page(p_pg)
	} else {
		return 0
	}
}

@[c:'pagerStress']
fn pager_stress(p voidptr, p_pg &PgHdr) int {
	c2v_gc_register_thread()
	p_pager := &Pager(p)
	rc := 0
	if p_pager.errCode {
		return 0
	}
	if int(p_pager.doNotSpill) && ((int(p_pager.doNotSpill) & (2 | 1)) != 0 || (int(p_pg.flags) & 8) != 0) {
		return 0
	}
	p_pager.aStat[3]++
	p_pg.pDirty = 0
	if (usize(p_pager.pWal) != usize(0)) {
		rc = subjournal_page_if_required(p_pg)
		if rc == 0 {
			rc = pager_wal_frames(p_pager, p_pg, Pgno(0), 0)
		}
	} else {
		if int(p_pg.flags) & 8 || int(p_pager.eState) == 3 {
			rc = sync_journal(p_pager, 1)
		}
		if rc == 0 {
			rc = pager_write_pagelist(p_pager, p_pg)
		}
	}
	if rc == 0 {
		sqlite3_pcache_make_clean(p_pg)
	}
	return pager_error(p_pager, rc)
}

@[c:'sqlite3PagerFlush']
fn sqlite3_pager_flush(p_pager &Pager) int {
	rc := p_pager.errCode
	if !p_pager.memDb {
		p_list := sqlite3_pcache_dirty_list(p_pager.pPCache)
		for rc == 0 && !isnil(p_list) {
			p_next := p_list.pDirty
			if p_list.nRef == I64(0) {
				rc = pager_stress(voidptr(p_pager), p_list)
			}
			p_list = p_next
		}
	}
	return rc
}

@[c:'sqlite3PagerOpen']
fn sqlite3_pager_open(p_vfs &Sqlite3_vfs, pp_pager &&Pager, z_filename &i8, n_extra int, flags int, vfs_flags int, x_reinit fn (&DbPage)) int {
	p_ptr := &U8(0)
	p_pager := unsafe { &Pager(nil) }
	rc := 0
	temp_file := 0
	mem_db := 0
	mem_jm := 0
	read_only := 0
	journal_file_size := 0
	z_pathname := unsafe { &i8(nil) }
	n_pathname := 0
	use_journal := int((flags & 1) == 0)
	pcache_size := sqlite3_pcache_size()
	sz_page_dflt := u32(4096)
	z_uri := unsafe { &i8(nil) }
	n_uri_byte := 1
	journal_file_size = ((sqlite3_journal_size(p_vfs) + 7) & ~7)
	unsafe { *pp_pager = 0 }
	if flags & 2 {
		mem_db = 1
		if !isnil(z_filename) && int(z_filename[0]) {
			z_pathname = sqlite3_db_str_dup(unsafe { nil }, z_filename)
			if usize(z_pathname) == usize(0) {
				return 7
			}
			n_pathname = sqlite3_strlen30(z_pathname)
			z_filename = 0
		}
	}
	if !isnil(z_filename) && int(z_filename[0]) {
		z := &i8(0)
		n_pathname = p_vfs.mxPathname + 1
		z_pathname = &i8(sqlite3_db_malloc_raw(unsafe { nil }, U64(I64(2) * I64(n_pathname))))
		if usize(z_pathname) == usize(0) {
			return 7
		}
		z_pathname[0] = i8(0)
		rc = sqlite3_os_full_pathname(p_vfs, z_filename, n_pathname, z_pathname)
		if rc != 0 {
			if rc == (0 | (2 << 8)) {
				if vfs_flags & 16777216 {
					rc = (14 | (6 << 8))
				} else {
					rc = 0
				}
			}
		}
		n_pathname = sqlite3_strlen30(z_pathname)
		z_uri = unsafe { z_filename + (sqlite3_strlen30(z_filename) + 1) }
		z = z_uri
		for (unsafe { *z }) {
			c2v_pointer_prefix(voidptr(&z), z, isize(C.strlen(z) + u64(1)))
			c2v_pointer_prefix(voidptr(&z), z, isize(C.strlen(z) + u64(1)))
		}
		n_uri_byte = int((i64((isize(unsafe { z + 1 }) - isize(z_uri)) / isize(sizeof(i8)))))
		if rc == 0 && n_pathname + 8 > p_vfs.mxPathname {
			rc = sqlite3_cantopen_error(4863)
		}
		if rc != 0 {
			sqlite3_db_free(unsafe { nil }, voidptr(z_pathname))
			return rc
		}
	}
	p_ptr = &U8(sqlite3_malloc_zero(U64((((sizeof(Pager)) + u64(7)) & u64(~7)) + u64(((pcache_size + 7) & ~7)) + u64(((p_vfs.szOsFile + 7) & ~7))) + U64(journal_file_size) * U64(2) + U64(8) + U64(4) + U64(n_pathname) + U64(1) + U64(n_uri_byte) + U64(n_pathname) + U64(8) + U64(1) + U64(n_pathname) + U64(4) + U64(1) + U64(3)))
	if isnil(p_ptr) {
		sqlite3_db_free(unsafe { nil }, voidptr(z_pathname))
		return 7
	}
	p_pager = &Pager(voidptr(p_ptr))
	c2v_pointer_prefix(voidptr(&p_ptr), p_ptr, isize((((sizeof(Pager)) + u64(7)) & u64(~7))))
	p_pager.pPCache = &PCache(voidptr(p_ptr))
	c2v_pointer_prefix(voidptr(&p_ptr), p_ptr, isize(((pcache_size + 7) & ~7)))
	p_pager.fd = &Sqlite3_file(voidptr(p_ptr))
	c2v_pointer_prefix(voidptr(&p_ptr), p_ptr, isize(((p_vfs.szOsFile + 7) & ~7)))
	p_pager.sjfd = &Sqlite3_file(voidptr(p_ptr))
	c2v_pointer_prefix(voidptr(&p_ptr), p_ptr, isize(journal_file_size))
	p_pager.jfd = &Sqlite3_file(voidptr(p_ptr))
	c2v_pointer_prefix(voidptr(&p_ptr), p_ptr, isize(journal_file_size))
	C.memcpy(voidptr(p_ptr), voidptr(&&Pager(c2v_address_of(&p_pager))), u64(8))
	c2v_pointer_prefix(voidptr(&p_ptr), p_ptr, isize(8))
	c2v_pointer_prefix(voidptr(&p_ptr), p_ptr, isize(4))
	p_pager.zFilename = &i8(voidptr(p_ptr))
	if n_pathname > 0 {
		C.memcpy(voidptr(p_ptr), voidptr(z_pathname), u64(n_pathname))
		c2v_pointer_prefix(voidptr(&p_ptr), p_ptr, isize(n_pathname + 1))
		if z_uri {
			C.memcpy(voidptr(p_ptr), voidptr(z_uri), u64(n_uri_byte))
			c2v_pointer_prefix(voidptr(&p_ptr), p_ptr, isize(n_uri_byte))
		} else {
			c2v_pointer_postfix(voidptr(&p_ptr), p_ptr, isize(1))
		}
	}
	if n_pathname > 0 {
		p_pager.zJournal = &i8(voidptr(p_ptr))
		C.memcpy(voidptr(p_ptr), voidptr(z_pathname), u64(n_pathname))
		c2v_pointer_prefix(voidptr(&p_ptr), p_ptr, isize(n_pathname))
		C.memcpy(voidptr(p_ptr), voidptr(c'-journal'), u64(8))
		c2v_pointer_prefix(voidptr(&p_ptr), p_ptr, isize(8 + 1))
	} else {
		p_pager.zJournal = 0
	}
	if n_pathname > 0 {
		p_pager.zWal = &i8(voidptr(p_ptr))
		C.memcpy(voidptr(p_ptr), voidptr(z_pathname), u64(n_pathname))
		c2v_pointer_prefix(voidptr(&p_ptr), p_ptr, isize(n_pathname))
		C.memcpy(voidptr(p_ptr), voidptr(c'-wal'), u64(4))
		c2v_pointer_prefix(voidptr(&p_ptr), p_ptr, isize(4 + 1))
	} else {
		p_pager.zWal = 0
	}

	if n_pathname {
		sqlite3_db_free(unsafe { nil }, voidptr(z_pathname))
	}
	p_pager.pVfs = p_vfs
	p_pager.vfsFlags = u32(vfs_flags)
	if !isnil(z_filename) && int(z_filename[0]) {
		fout := 0
		rc = sqlite3_os_open(p_vfs, p_pager.zFilename, p_pager.fd, vfs_flags, &fout)
		mem_jm = (fout & 128) != 0
		p_pager.memVfs = mem_jm
		read_only = (fout & 1) != 0
		if rc == 0 {
			i_dc := sqlite3_os_device_characteristics(p_pager.fd)
			if !read_only {
				set_sector_size(p_pager)
				if sz_page_dflt < p_pager.sectorSize {
					if p_pager.sectorSize > u32(8192) {
						sz_page_dflt = u32(8192)
					} else {
						sz_page_dflt = u32(p_pager.sectorSize)
					}
				}
			}
			p_pager.noLock = U8(sqlite3_uri_boolean(p_pager.zFilename, c'nolock', 0))
			if (i_dc & 8192) != 0 || sqlite3_uri_boolean(p_pager.zFilename, c'immutable', 0) {
				vfs_flags |= 1
				unsafe { goto act_like_temp_file
				 }
			}
		}
	} else {
		act_like_temp_file:
		temp_file = 1
		p_pager.eState = U8(1)
		p_pager.eLock = U8(4)
		p_pager.noLock = U8(1)
		read_only = (vfs_flags & 1)
	}
	if rc == 0 {
		rc = sqlite3_pager_set_pagesize(p_pager, &sz_page_dflt, -1)
	}
	if rc == 0 {
		n_extra = ((n_extra + 7) & ~7)
		rc = sqlite3_pcache_open(int(sz_page_dflt), n_extra, !mem_db, unsafe { if !mem_db {
			pager_stress
		} else {
			C2vFn_666e2028766f69647074722c202650674864722920696e74(voidptr(0))
		} }, voidptr(p_pager), p_pager.pPCache)
	}
	if rc != 0 {
		sqlite3_os_close(p_pager.fd)
		sqlite3_page_free(voidptr(p_pager.pTmpSpace))
		sqlite3_free(voidptr(p_pager))
		return rc
	}
	p_pager.useJournal = U8(use_journal)
	p_pager.mxPgno = u32(4294967294)
	p_pager.tempFile = U8(temp_file)
	p_pager.exclusiveMode = U8(temp_file)
	p_pager.changeCountDone = p_pager.tempFile
	p_pager.memDb = U8(mem_db)
	p_pager.readOnly = U8(read_only)
	sqlite3_pager_set_flags(p_pager, u32((2 + 1) | 32))
	p_pager.nExtra = U16(n_extra)
	p_pager.journalSizeLimit = I64(-1)
	set_sector_size(p_pager)
	if !use_journal {
		p_pager.journalMode = U8(2)
	} else if mem_db || mem_jm {
		p_pager.journalMode = U8(4)
	}
	p_pager.xReiniter = x_reinit
	set_getter_method(p_pager)
	unsafe { *pp_pager = p_pager }
	return 0
}

fn sqlite3_database_file_object(z_name &i8) &Sqlite3_file {
	c2v_gc_register_thread()
	p_pager := &Pager(0)
	p := &i8(0)
	for int(z_name[-1]) != 0 || int(z_name[-2]) != 0 || int(z_name[-3]) != 0 || int(z_name[-4]) != 0 {
		c2v_pointer_postfix(voidptr(&z_name), z_name, isize(-1))
	}
	p = z_name - 4 - sizeof(voidptr)
	p_pager = unsafe { *&&Pager(voidptr(p)) }
	return p_pager.fd
}

@[c:'hasHotJournal']
fn has_hot_journal(p_pager &Pager, p_exists &int) int {
	p_vfs := p_pager.pVfs
	rc := 0
	exists := 1
	jrnl_open := int(!!(usize(p_pager.jfd.pMethods) != usize(0)))
	unsafe { *p_exists = 0 }
	if !jrnl_open {
		rc = sqlite3_os_access(p_vfs, p_pager.zJournal, 0, &exists)
	}
	if rc == 0 && exists {
		locked := 0
		rc = sqlite3_os_check_reserved_lock(p_pager.fd, &locked)
		if rc == 0 && !locked {
			n_page := Pgno(0)
			rc = pager_pagecount(p_pager, &n_page)
			if rc == 0 {
				if n_page == Pgno(0) && !jrnl_open {
					sqlite3_begin_benign_malloc()
					if pager_lock_db(p_pager, 2) == 0 {
						sqlite3_os_delete(p_vfs, p_pager.zJournal, 0)
						if !p_pager.exclusiveMode {
							pager_unlock_db(p_pager, 1)
						}
					}
					sqlite3_end_benign_malloc()
				} else {
					if !jrnl_open {
						f := 1 | 2048
						rc = sqlite3_os_open(p_vfs, p_pager.zJournal, p_pager.jfd, f, &f)
					}
					if rc == 0 {
						first := U8(0)
						rc = sqlite3_os_read(p_pager.jfd, voidptr(c2v_address_of(&first)), 1, I64(0))
						if rc == (10 | (2 << 8)) {
							rc = 0
						}
						if !jrnl_open {
							sqlite3_os_close(p_pager.jfd)
						}
						unsafe { *p_exists = (int(first) != 0) }
					} else if rc == 14 {
						unsafe { *p_exists = 1 }
						rc = 0
					}
				}
			}
		}
	}
	return rc
}

@[c:'sqlite3PagerSharedLock']
fn sqlite3_pager_shared_lock(p_pager &Pager) int {
	rc := 0
	if !(usize(p_pager.pWal) != usize(0)) && int(p_pager.eState) == 0 {
		b_hot_journal := 1
		rc = pager_wait_on_lock(p_pager, 1)
		if rc != 0 {
			unsafe { goto failed
			 }
		}
		if int(p_pager.eLock) <= 1 {
			rc = has_hot_journal(p_pager, &b_hot_journal)
		}
		if rc != 0 {
			unsafe { goto failed
			 }
		}
		if b_hot_journal {
			if p_pager.readOnly {
				rc = (8 | (3 << 8))
				unsafe { goto failed
				 }
			}
			rc = pager_lock_db(p_pager, 4)
			if rc != 0 {
				unsafe { goto failed
				 }
			}
			if !(usize(p_pager.jfd.pMethods) != usize(0)) && int(p_pager.journalMode) != 2 {
				p_vfs := p_pager.pVfs
				b_exists := 0
				rc = sqlite3_os_access(p_vfs, p_pager.zJournal, 0, &b_exists)
				if rc == 0 && b_exists {
					fout := 0
					f := 2 | 2048
					rc = sqlite3_os_open(p_vfs, p_pager.zJournal, p_pager.jfd, f, &fout)
					if rc == 0 && fout & 1 {
						rc = sqlite3_cantopen_error(5384)
						sqlite3_os_close(p_pager.jfd)
					}
				}
			}
			if (usize(p_pager.jfd.pMethods) != usize(0)) {
				rc = pager_sync_hot_journal(p_pager)
				if rc == 0 {
					rc = pager_playback(p_pager, !p_pager.tempFile)
					p_pager.eState = U8(0)
				}
			} else if !p_pager.exclusiveMode {
				pager_unlock_db(p_pager, 1)
			}
			if rc != 0 {
				pager_error(p_pager, rc)
				unsafe { goto failed
				 }
			}
		}
		if !p_pager.tempFile && int(p_pager.hasHeldSharedLock) {
			db_file_vers := [16]i8{}
			rc = sqlite3_os_read(p_pager.fd, voidptr(&db_file_vers), int(sizeof([16]i8)), I64(24))
			if rc != 0 {
				if rc != (10 | (2 << 8)) {
					unsafe { goto failed
					 }
				}
				C.memset(voidptr(unsafe { &db_file_vers[0] }), 0, sizeof([16]i8))
			}
			if C.memcmp(p_pager.dbFileVers, voidptr(unsafe { &db_file_vers[0] }), sizeof([16]i8)) != 0 {
				pager_reset(p_pager)
				if p_pager.bUseFetch {
					sqlite3_os_unfetch(p_pager.fd, I64(0), unsafe { nil })
				}
			}
		}
		rc = pager_open_wal_if_present(p_pager)
	}
	if (usize(p_pager.pWal) != usize(0)) {
		rc = pager_begin_read_transaction(p_pager)
	}
	if int(p_pager.tempFile) == 0 && int(p_pager.eState) == 0 && rc == 0 {
		rc = pager_pagecount(p_pager, &p_pager.dbSize)
	}
	failed:
	if rc != 0 {
		pager_unlock(p_pager)
	} else {
		p_pager.eState = U8(1)
		p_pager.hasHeldSharedLock = U8(1)
	}
	return rc
}

@[c:'pagerUnlockIfUnused']
fn pager_unlock_if_unused(p_pager &Pager) {
	if sqlite3_pcache_ref_count(p_pager.pPCache) == I64(0) {
		pager_unlock_and_rollback(p_pager)
	}
}

@[c:'getPageNormal']
fn get_page_normal(p_pager &Pager, pgno Pgno, pp_page &&DbPage, flags int) int {
	c2v_gc_register_thread()
	rc := 0
	p_pg := &PgHdr(0)
	no_content := U8(0)
	p_base := &Sqlite3_pcache_page(0)
	if pgno == Pgno(0) {
		return sqlite3_corrupt_error(5597)
	}
	p_base = sqlite3_pcache_fetch(p_pager.pPCache, pgno, 3)
	if usize(p_base) == usize(0) {
		p_pg = 0
		rc = sqlite3_pcache_fetch_stress(p_pager.pPCache, pgno, &&Sqlite3_pcache_page(&&Sqlite3_pcache_page(c2v_address_of(&p_base))))
		if rc != 0 {
			unsafe { goto pager_acquire_err
			 }
		}
		if usize(p_base) == usize(0) {
			rc = 7
			unsafe { goto pager_acquire_err
			 }
		}
	}
	unsafe { *pp_page = sqlite3_pcache_fetch_finish(p_pager.pPCache, pgno, p_base) }
	p_pg = unsafe { *pp_page }
	no_content = U8((flags & 1) != 0)
	if !isnil(p_pg.pPager) && !no_content {
		p_pager.aStat[0]++
		return 0
	} else {
		if pgno == p_pager.lckPgno {
			rc = sqlite3_corrupt_error(5629)
			unsafe { goto pager_acquire_err
			 }
		}
		p_pg.pPager = p_pager
		if !(usize(p_pager.fd.pMethods) != usize(0)) || p_pager.dbSize < pgno || int(no_content) {
			if pgno > p_pager.mxPgno {
				rc = 13
				if pgno <= p_pager.dbSize {
					sqlite3_pcache_release(p_pg)
					p_pg = 0
				}
				unsafe { goto pager_acquire_err
				 }
			}
			if no_content {
				sqlite3_begin_benign_malloc()
				if pgno <= p_pager.dbOrigSize {
					sqlite3_bitvec_set(p_pager.pInJournal, pgno)
				}
				add_to_savepoint_bitvecs(p_pager, pgno)
				sqlite3_end_benign_malloc()
			}
			C.memset(voidptr(p_pg.pData), 0, u64(p_pager.pageSize))
		} else {
			p_pager.aStat[1]++
			rc = read_db_page(p_pg)
			if rc != 0 {
				unsafe { goto pager_acquire_err
				 }
			}
		}
	}
	return 0
	pager_acquire_err:
	if p_pg {
		sqlite3_pcache_drop(p_pg)
	}
	pager_unlock_if_unused(p_pager)
	unsafe { *pp_page = 0 }
	return rc
}

@[c:'getPageMMap']
fn get_page_mm_ap(p_pager &Pager, pgno Pgno, pp_page &&DbPage, flags int) int {
	c2v_gc_register_thread()
	rc := 0
	p_pg := unsafe { &PgHdr(nil) }
	i_frame := u32(0)
	b_mmap_ok := int((pgno > Pgno(1) && (int(p_pager.eState) == 1 || (flags & 2))))
	if pgno <= Pgno(1) && pgno == Pgno(0) {
		return sqlite3_corrupt_error(5712)
	}
	if b_mmap_ok && (usize(p_pager.pWal) != usize(0)) {
		rc = sqlite3_wal_find_frame(p_pager.pWal, pgno, &i_frame)
		if rc != 0 {
			unsafe { *pp_page = 0 }
			return rc
		}
	}
	if b_mmap_ok && i_frame == u32(0) {
		p_data := voidptr(0)
		rc = sqlite3_os_fetch(p_pager.fd, I64((pgno - Pgno(1))) * p_pager.pageSize, int(p_pager.pageSize), &p_data)
		if rc == 0 && !isnil(p_data) {
			if int(p_pager.eState) > 1 || int(p_pager.tempFile) {
				p_pg = sqlite3_pager_lookup(p_pager, pgno)
			}
			if usize(p_pg) == usize(0) {
				rc = pager_acquire_map_page(p_pager, pgno, voidptr(p_data), &&PgHdr(&&PgHdr(c2v_address_of(&p_pg))))
			} else {
				sqlite3_os_unfetch(p_pager.fd, I64((pgno - Pgno(1))) * p_pager.pageSize, voidptr(p_data))
			}
			if p_pg {
				unsafe { *pp_page = p_pg }
				return 0
			}
		}
		if rc != 0 {
			unsafe { *pp_page = 0 }
			return rc
		}
	}
	return get_page_normal(p_pager, pgno, pp_page, flags)
}

@[c:'getPageError']
fn get_page_error(p_pager &Pager, pgno Pgno, pp_page &&DbPage, flags int) int {
	c2v_gc_register_thread()

	unsafe { *pp_page = 0 }
	return p_pager.errCode
}

@[c:'sqlite3PagerGet']
fn sqlite3_pager_get(p_pager &Pager, pgno Pgno, pp_page &&DbPage, flags int) int {
	return p_pager.xGet(p_pager, pgno, pp_page, flags)
}

@[c:'sqlite3PagerLookup']
fn sqlite3_pager_lookup(p_pager &Pager, pgno Pgno) &DbPage {
	p_page := &Sqlite3_pcache_page(0)
	p_page = sqlite3_pcache_fetch(p_pager.pPCache, pgno, 0)
	if usize(p_page) == usize(0) {
		return unsafe { nil }
	}
	return sqlite3_pcache_fetch_finish(p_pager.pPCache, pgno, p_page)
}

@[c:'sqlite3PagerUnrefNotNull']
fn sqlite3_pager_unref_not_null(p_pg &DbPage) {
	if int(p_pg.flags) & 32 {
		pager_release_map_page(unsafe { &PgHdr(p_pg) })
	} else {
		sqlite3_pcache_release(unsafe { &PgHdr(p_pg) })
	}
}

@[c:'sqlite3PagerUnref']
fn sqlite3_pager_unref(p_pg &DbPage) {
	if p_pg {
		sqlite3_pager_unref_not_null(p_pg)
	}
}

@[c:'sqlite3PagerUnrefPageOne']
fn sqlite3_pager_unref_page_one(p_pg &DbPage) {
	p_pager := &Pager(0)
	p_pager = p_pg.pPager
	sqlite3_pcache_release(unsafe { &PgHdr(p_pg) })
	pager_unlock_if_unused(p_pager)
}

fn pager_open_journal(p_pager &Pager) int {
	rc := 0
	p_vfs := p_pager.pVfs
	if p_pager.errCode {
		return p_pager.errCode
	}
	if !(usize(p_pager.pWal) != usize(0)) && int(p_pager.journalMode) != 2 {
		p_pager.pInJournal = sqlite3_bitvec_create(p_pager.dbSize)
		if usize(p_pager.pInJournal) == usize(0) {
			return 7
		}
		if !(usize(p_pager.jfd.pMethods) != usize(0)) {
			if int(p_pager.journalMode) == 4 {
				sqlite3_mem_journal_open(p_pager.jfd)
			} else {
				flags := 2 | 4
				n_spill := 0
				if p_pager.tempFile {
					flags |= (8 | 4096)
					flags |= 16
					n_spill = sqlite3Config.nStmtSpill
				} else {
					flags |= 2048
					n_spill = jrnl_buffer_size(p_pager)
				}
				rc = database_is_unmoved(p_pager)
				if rc == 0 {
					rc = sqlite3_journal_open(p_vfs, p_pager.zJournal, p_pager.jfd, flags, n_spill)
				}
			}
		}
		if rc == 0 {
			p_pager.nRec = 0
			p_pager.journalOff = I64(0)
			p_pager.setSuper = U8(0)
			p_pager.journalHdr = I64(0)
			rc = write_journal_hdr(p_pager)
		}
	}
	if rc != 0 {
		sqlite3_bitvec_destroy(p_pager.pInJournal)
		p_pager.pInJournal = 0
		p_pager.journalOff = I64(0)
	} else {
		p_pager.eState = U8(3)
	}
	return rc
}

@[c:'sqlite3PagerBegin']
fn sqlite3_pager_begin(p_pager &Pager, ex_flag int, subj_in_memory int) int {
	rc := 0
	if p_pager.errCode {
		return p_pager.errCode
	}
	p_pager.subjInMemory = U8(subj_in_memory)
	if int(p_pager.eState) == 1 {
		if (usize(p_pager.pWal) != usize(0)) {
			if int(p_pager.exclusiveMode) && sqlite3_wal_exclusive_mode(p_pager.pWal, -1) {
				rc = pager_lock_db(p_pager, 4)
				if rc != 0 {
					return rc
				}
				sqlite3_wal_exclusive_mode(p_pager.pWal, 1)
			}
			rc = sqlite3_wal_begin_write_transaction(p_pager.pWal)
		} else {
			rc = pager_lock_db(p_pager, 2)
			if rc == 0 && ex_flag {
				rc = pager_wait_on_lock(p_pager, 4)
			}
		}
		if rc == 0 {
			p_pager.eState = U8(2)
			p_pager.dbHintSize = p_pager.dbSize
			p_pager.dbFileSize = p_pager.dbSize
			p_pager.dbOrigSize = p_pager.dbSize
			p_pager.journalOff = I64(0)
		}
	}
	return rc
}

@[c:'pagerAddPageToRollbackJournal']
fn pager_add_page_to_rollback_journal(p_pg &PgHdr) int {
	p_pager := p_pg.pPager
	rc := 0
	cksum := u32(0)
	p_data2 := &i8(0)
	i_off := p_pager.journalOff
	p_data2 = &i8(p_pg.pData)
	cksum = pager_cksum(p_pager, &U8(voidptr(p_data2)))
	p_pg.flags |= 8
	rc = write32bits(p_pager.jfd, i_off, p_pg.pgno)
	if rc != 0 {
		return rc
	}
	rc = sqlite3_os_write(p_pager.jfd, voidptr(p_data2), int(p_pager.pageSize), i_off + I64(4))
	if rc != 0 {
		return rc
	}
	rc = write32bits(p_pager.jfd, i_off + p_pager.pageSize + I64(4), cksum)
	if rc != 0 {
		return rc
	}
	p_pager.journalOff += I64(8) + p_pager.pageSize
	p_pager.nRec++
	rc = sqlite3_bitvec_set(p_pager.pInJournal, p_pg.pgno)
	rc |= add_to_savepoint_bitvecs(p_pager, p_pg.pgno)
	return rc
}

fn pager_write(p_pg &PgHdr) int {
	p_pager := p_pg.pPager
	rc := 0
	if int(p_pager.eState) == 2 {
		rc = pager_open_journal(p_pager)
		if rc != 0 {
			return rc
		}
	}
	sqlite3_pcache_make_dirty(p_pg)
	if usize(p_pager.pInJournal) != usize(0) && sqlite3_bitvec_test_not_null(p_pager.pInJournal, p_pg.pgno) == 0 {
		if p_pg.pgno <= p_pager.dbOrigSize {
			rc = pager_add_page_to_rollback_journal(p_pg)
			if rc != 0 {
				return rc
			}
		} else {
			if int(p_pager.eState) != 4 {
				p_pg.flags |= 8
			}
		}
	}
	p_pg.flags |= 4
	if p_pager.nSavepoint > 0 {
		rc = subjournal_page_if_required(p_pg)
	}
	if p_pager.dbSize < p_pg.pgno {
		p_pager.dbSize = p_pg.pgno
	}
	return rc
}

@[c:'pagerWriteLargeSector']
fn pager_write_large_sector(p_pg &PgHdr) int {
	rc := 0
	n_page_count := Pgno(0)
	pg1 := Pgno(0)
	n_page := 0
	ii := 0
	need_sync := 0
	p_pager := p_pg.pPager
	n_page_per_sector := Pgno((I64(p_pager.sectorSize) / p_pager.pageSize))
	p_pager.doNotSpill |= 4
	pg1 = ((p_pg.pgno - Pgno(1)) & ~(n_page_per_sector - Pgno(1))) + Pgno(1)
	n_page_count = p_pager.dbSize
	if p_pg.pgno > n_page_count {
		n_page = int((p_pg.pgno - pg1) + Pgno(1))
	} else if (pg1 + n_page_per_sector - Pgno(1)) > n_page_count {
		n_page = int(n_page_count + Pgno(1) - pg1)
	} else {
		n_page = int(n_page_per_sector)
	}
	for ii = 0; ii < n_page && rc == 0; ii++ {
		pg := pg1 + Pgno(ii)
		p_page := &PgHdr(0)
		if pg == p_pg.pgno || !sqlite3_bitvec_test(p_pager.pInJournal, pg) {
			if pg != p_pager.lckPgno {
				rc = sqlite3_pager_get(p_pager, pg, unsafe { &&DbPage(&&PgHdr(c2v_address_of(&p_page))) }, 0)
				if rc == 0 {
					rc = pager_write(p_page)
					if int(p_page.flags) & 8 {
						need_sync = 1
					}
					sqlite3_pager_unref_not_null(unsafe { &DbPage(p_page) })
				}
			}
		} else {
			p_page = sqlite3_pager_lookup(p_pager, pg)
			if usize(p_page) != usize(0) {
				if int(p_page.flags) & 8 {
					need_sync = 1
				}
				sqlite3_pager_unref_not_null(unsafe { &DbPage(p_page) })
			}
		}
	}
	if rc == 0 && need_sync {
		for ii = 0; ii < n_page; ii++ {
			p_page := sqlite3_pager_lookup(p_pager, pg1 + Pgno(ii))
			if p_page {
				p_page.flags |= 8
				sqlite3_pager_unref_not_null(unsafe { &DbPage(p_page) })
			}
		}
	}
	p_pager.doNotSpill &= ~4
	return rc
}

@[c:'sqlite3PagerWrite']
fn sqlite3_pager_write(p_pg &PgHdr) int {
	p_pager := p_pg.pPager
	if (int(p_pg.flags) & 4) != 0 && p_pager.dbSize >= p_pg.pgno {
		if p_pager.nSavepoint {
			return subjournal_page_if_required(p_pg)
		}
		return 0
	} else if p_pager.errCode {
		return p_pager.errCode
	} else if p_pager.sectorSize > u32(p_pager.pageSize) {
		return pager_write_large_sector(p_pg)
	} else {
		return pager_write(p_pg)
	}
}

@[c:'sqlite3PagerDontWrite']
fn sqlite3_pager_dont_write(p_pg &PgHdr) {
	p_pager := p_pg.pPager
	if !p_pager.tempFile && (int(p_pg.flags) & 2) && p_pager.nSavepoint == 0 {
		p_pg.flags |= 16
		p_pg.flags &= ~4
	}
}

fn pager_incr_changecounter(p_pager &Pager, is_direct_mode int) int {
	rc := 0

	if !p_pager.changeCountDone && p_pager.dbSize > Pgno(0) {
		p_pg_hdr := &PgHdr(0)
		rc = sqlite3_pager_get(p_pager, Pgno(1), unsafe { &&DbPage(&&PgHdr(c2v_address_of(&p_pg_hdr))) }, 0)
		if !0 && (rc == 0) {
			rc = sqlite3_pager_write(unsafe { &DbPage(p_pg_hdr) })
		}
		if rc == 0 {
			pager_write_changecounter(p_pg_hdr)
			if 0 {
				z_buf := &voidptr(0)
				z_buf = p_pg_hdr.pData
				if rc == 0 {
					rc = sqlite3_os_write(p_pager.fd, voidptr(z_buf), int(p_pager.pageSize), I64(0))
					p_pager.aStat[2]++
				}
				if rc == 0 {
					p_copy := voidptr(unsafe { (&i8(z_buf)) + 24 })
					C.memcpy(voidptr(&p_pager.dbFileVers), voidptr(p_copy), sizeof([16]i8))
					p_pager.changeCountDone = U8(1)
				}
			} else {
				p_pager.changeCountDone = U8(1)
			}
		}
		sqlite3_pager_unref(unsafe { &DbPage(p_pg_hdr) })
	}
	return rc
}

@[c:'sqlite3PagerSync']
fn sqlite3_pager_sync(p_pager &Pager, z_super &i8) int {
	rc := 0
	p_arg := voidptr(z_super)
	rc = sqlite3_os_file_control(p_pager.fd, 21, voidptr(p_arg))
	if rc == 12 {
		rc = 0
	}
	if rc == 0 && !p_pager.noSync {
		rc = sqlite3_os_sync(p_pager.fd, int(p_pager.syncFlags))
	}
	return rc
}

@[c:'sqlite3PagerExclusiveLock']
fn sqlite3_pager_exclusive_lock(p_pager &Pager) int {
	rc := p_pager.errCode
	if rc == 0 {
		if 0 == (usize(p_pager.pWal) != usize(0)) {
			rc = pager_wait_on_lock(p_pager, 4)
		}
	}
	return rc
}

@[c:'sqlite3PagerCommitPhaseOne']
fn sqlite3_pager_commit_phase_one(p_pager &Pager, z_super &i8, no_sync int) int {
	rc := 0
	if p_pager.errCode {
		return p_pager.errCode
	}
	if sqlite3_fault_sim(400) {
		return 10
	}
	if int(p_pager.eState) < 3 {
		return 0
	}
	if 0 == pager_flush_on_commit(p_pager, 1) {
		sqlite3_backup_restart(p_pager.pBackup)
	} else {
		p_list := &PgHdr(0)
		if (usize(p_pager.pWal) != usize(0)) {
			p_page_one := unsafe { &PgHdr(nil) }
			p_list = sqlite3_pcache_dirty_list(p_pager.pPCache)
			if usize(p_list) == usize(0) {
				rc = sqlite3_pager_get(p_pager, Pgno(1), unsafe { &&DbPage(&&PgHdr(c2v_address_of(&p_page_one))) }, 0)
				p_list = p_page_one
				p_list.pDirty = 0
			}
			if p_list {
				rc = pager_wal_frames(p_pager, p_list, p_pager.dbSize, 1)
			}
			sqlite3_pager_unref(unsafe { &DbPage(p_page_one) })
			if rc == 0 {
				sqlite3_pcache_clean_all(p_pager.pPCache)
			}
		} else {
			rc = pager_incr_changecounter(p_pager, 0)
			if rc != 0 {
				unsafe { goto commit_phase_one_exit
				 }
			}
			rc = write_super_journal(p_pager, z_super)
			if rc != 0 {
				unsafe { goto commit_phase_one_exit
				 }
			}
			rc = sync_journal(p_pager, 0)
			if rc != 0 {
				unsafe { goto commit_phase_one_exit
				 }
			}
			p_list = sqlite3_pcache_dirty_list(p_pager.pPCache)
			if 0 == 0 {
				rc = pager_write_pagelist(p_pager, p_list)
			}
			if rc != 0 {
				unsafe { goto commit_phase_one_exit
				 }
			}
			sqlite3_pcache_clean_all(p_pager.pPCache)
			if p_pager.dbSize > p_pager.dbFileSize {
				n_new := p_pager.dbSize - int(Pgno((p_pager.dbSize == p_pager.lckPgno)))
				rc = pager_truncate(p_pager, n_new)
				if rc != 0 {
					unsafe { goto commit_phase_one_exit
					 }
				}
			}
			if !no_sync {
				rc = sqlite3_pager_sync(p_pager, z_super)
			}
		}
	}
	commit_phase_one_exit:
	if rc == 0 && !(usize(p_pager.pWal) != usize(0)) {
		p_pager.eState = U8(5)
	}
	return rc
}

@[c:'sqlite3PagerCommitPhaseTwo']
fn sqlite3_pager_commit_phase_two(p_pager &Pager) int {
	rc := 0
	if p_pager.errCode {
		return p_pager.errCode
	}
	p_pager.iDataVersion++
	if int(p_pager.eState) == 2 && int(p_pager.exclusiveMode) && int(p_pager.journalMode) == 1 {
		p_pager.eState = U8(1)
		return 0
	}
	rc = pager_end_transaction(p_pager, int(p_pager.setSuper), 1)
	return pager_error(p_pager, rc)
}

@[c:'sqlite3PagerRollback']
fn sqlite3_pager_rollback(p_pager &Pager) int {
	rc := 0
	if int(p_pager.eState) == 6 {
		return p_pager.errCode
	}
	if int(p_pager.eState) <= 1 {
		return 0
	}
	if (usize(p_pager.pWal) != usize(0)) {
		rc2 := 0
		rc = sqlite3_pager_savepoint(p_pager, 2, -1)
		rc2 = pager_end_transaction(p_pager, int(p_pager.setSuper), 0)
		if rc == 0 {
			rc = rc2
		}
	} else if !(usize(p_pager.jfd.pMethods) != usize(0)) || int(p_pager.eState) == 2 {
		e_state := int(p_pager.eState)
		rc = pager_end_transaction(p_pager, 0, 0)
		if !p_pager.memDb && e_state > 2 {
			p_pager.errCode = 4
			p_pager.eState = U8(6)
			set_getter_method(p_pager)
			return rc
		}
	} else {
		rc = pager_playback(p_pager, 0)
	}
	return pager_error(p_pager, rc)
}

@[c:'sqlite3PagerIsreadonly']
fn sqlite3_pager_isreadonly(p_pager &Pager) U8 {
	return p_pager.readOnly
}

@[c:'sqlite3PagerMemUsed']
fn sqlite3_pager_mem_used(p_pager &Pager) int {
	per_page_size := int(p_pager.pageSize + I64(p_pager.nExtra) + I64(int((sizeof(PgHdr) + u64(5) * sizeof(voidptr)))))
	return int(I64(per_page_size * sqlite3_pcache_pagecount(p_pager.pPCache) + sqlite3_malloc_size(voidptr(p_pager))) + p_pager.pageSize)
}

@[c:'sqlite3PagerPageRefcount']
fn sqlite3_pager_page_refcount(p_page &DbPage) int {
	return int(sqlite3_pcache_page_refcount(unsafe { &PgHdr(p_page) }))
}

@[c:'sqlite3PagerCacheStat']
fn sqlite3_pager_cache_stat(p_pager &Pager, e_stat int, reset int, pn_val &U64) {
	e_stat -= 7
	unsafe { *pn_val += U64(p_pager.aStat[e_stat]) }
	if reset {
		p_pager.aStat[e_stat] = u32(0)
	}
}

@[c:'sqlite3PagerIsMemdb']
fn sqlite3_pager_is_memdb(p_pager &Pager) int {
	return int(p_pager.tempFile || int(p_pager.memVfs))
}

@[c:'pagerOpenSavepoint']
fn pager_open_savepoint(p_pager &Pager, n_savepoint int) int {
	rc := 0
	n_current := p_pager.nSavepoint
	ii := 0
	mut a_new := &PagerSavepoint(0)
	a_new = &PagerSavepoint(sqlite3_realloc_vdup3(voidptr(p_pager.aSavepoint), U64(sizeof(PagerSavepoint) * u64(n_savepoint))))
	if isnil(a_new) {
		return 7
	}
	C.memset(voidptr(unsafe { a_new + n_current }), 0, u64((n_savepoint - n_current)) * sizeof(PagerSavepoint))
	p_pager.aSavepoint = a_new
	for ii = n_current; ii < n_savepoint; ii++ {
		a_new[ii].nOrig = p_pager.dbSize
		if (usize(p_pager.jfd.pMethods) != usize(0)) && p_pager.journalOff > I64(0) {
			a_new[ii].iOffset = p_pager.journalOff
		} else {
			a_new[ii].iOffset = I64(p_pager.sectorSize)
		}
		a_new[ii].iSubRec = p_pager.nSubRec
		a_new[ii].pInSavepoint = sqlite3_bitvec_create(p_pager.dbSize)
		a_new[ii].bTruncateOnRelease = 1
		if isnil(a_new[ii].pInSavepoint) {
			return 7
		}
		if (usize(p_pager.pWal) != usize(0)) {
			sqlite3_wal_savepoint(p_pager.pWal, &a_new[ii].aWalData[0])
		}
		p_pager.nSavepoint = ii + 1
	}
	return rc
}

@[c:'sqlite3PagerOpenSavepoint']
fn sqlite3_pager_open_savepoint(p_pager &Pager, n_savepoint int) int {
	if n_savepoint > p_pager.nSavepoint && int(p_pager.useJournal) {
		return pager_open_savepoint(p_pager, n_savepoint)
	} else {
		return 0
	}
}

@[c:'sqlite3PagerSavepoint']
fn sqlite3_pager_savepoint(p_pager &Pager, op int, i_savepoint int) int {
	rc := p_pager.errCode
	if rc == 0 && i_savepoint < p_pager.nSavepoint {
		ii := 0
		n_new := 0
		n_new = i_savepoint + (if (op == 1) { 0 } else { 1 })
		for ii = n_new; ii < p_pager.nSavepoint; ii++ {
			sqlite3_bitvec_destroy(p_pager.aSavepoint[ii].pInSavepoint)
		}
		p_pager.nSavepoint = n_new
		if op == 1 {
			p_rel := unsafe { p_pager.aSavepoint + n_new }
			if p_rel.bTruncateOnRelease && (usize(p_pager.sjfd.pMethods) != usize(0)) {
				if sqlite3_journal_is_in_memory(p_pager.sjfd) {
					sz := (p_pager.pageSize + I64(4)) * I64(p_rel.iSubRec)
					rc = sqlite3_os_truncate(p_pager.sjfd, sz)
				}
				p_pager.nSubRec = p_rel.iSubRec
			}
		} else if (usize(p_pager.pWal) != usize(0)) || (usize(p_pager.jfd.pMethods) != usize(0)) {
			p_savepoint := unsafe { if (n_new == 0) {
				&PagerSavepoint(nil)
			} else {
				p_pager.aSavepoint + (n_new - 1)
			} }
			rc = pager_playback_savepoint(p_pager, p_savepoint)
		}
	}
	return rc
}

@[c:'sqlite3PagerFilename']
fn sqlite3_pager_filename(p_pager &Pager, null_if_mem_db int) &i8 {
	if !sqlite3_pager_filename_z_fake_inited {
		c2v_static_init := [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_pager_filename_z_fake[c2v_i_0] = c2v_element_0
		}
		sqlite3_pager_filename_z_fake_inited = true
	}

	if null_if_mem_db && (int(p_pager.memDb) || sqlite3_is_memdb(p_pager.pVfs)) {
		return unsafe { &sqlite3_pager_filename_z_fake[0] + 4 }
	} else {
		return p_pager.zFilename
	}
}

@[c:'sqlite3PagerVfs']
fn sqlite3_pager_vfs(p_pager &Pager) &Sqlite3_vfs {
	return p_pager.pVfs
}

@[c:'sqlite3PagerFile']
fn sqlite3_pager_file(p_pager &Pager) &Sqlite3_file {
	return p_pager.fd
}

@[c:'sqlite3PagerJrnlFile']
fn sqlite3_pager_jrnl_file(p_pager &Pager) &Sqlite3_file {
	return if p_pager.pWal { sqlite3_wal_file(p_pager.pWal) } else { p_pager.jfd }
}

@[c:'sqlite3PagerJournalname']
fn sqlite3_pager_journalname(p_pager &Pager) &i8 {
	return p_pager.zJournal
}

@[c:'sqlite3PagerMovepage']
fn sqlite3_pager_movepage(p_pager &Pager, p_pg &DbPage, pgno Pgno, is_commit int) int {
	p_pg_old := &PgHdr(0)
	need_sync_pgno := Pgno(0)
	rc := 0
	orig_pgno := Pgno(0)
	if p_pager.tempFile {
		rc = sqlite3_pager_write(p_pg)
		if rc {
			return rc
		}
	}
	if (int(p_pg.flags) & 2) != 0 && 0 != c2v_assign[int](unsafe { &rc }, int(subjournal_page_if_required(unsafe { &PgHdr(p_pg) }))) {
		return rc
	}
	if (int(p_pg.flags) & 8) && !is_commit {
		need_sync_pgno = p_pg.pgno
	}
	p_pg.flags &= ~8
	p_pg_old = sqlite3_pager_lookup(p_pager, pgno)
	if p_pg_old {
		if (p_pg_old.nRef > I64(1)) {
			sqlite3_pager_unref_not_null(unsafe { &DbPage(p_pg_old) })
			return sqlite3_corrupt_error(7278)
		}
		p_pg.flags |= (int(p_pg_old.flags) & 8)
		if p_pager.tempFile {
			sqlite3_pcache_move(p_pg_old, p_pager.dbSize + Pgno(1))
		} else {
			sqlite3_pcache_drop(p_pg_old)
		}
	}
	orig_pgno = p_pg.pgno
	sqlite3_pcache_move(unsafe { &PgHdr(p_pg) }, pgno)
	sqlite3_pcache_make_dirty(unsafe { &PgHdr(p_pg) })
	if int(p_pager.tempFile) && !isnil(p_pg_old) {
		sqlite3_pcache_move(p_pg_old, orig_pgno)
		sqlite3_pager_unref_not_null(unsafe { &DbPage(p_pg_old) })
	}
	if need_sync_pgno {
		p_pg_hdr := &PgHdr(0)
		rc = sqlite3_pager_get(p_pager, need_sync_pgno, unsafe { &&DbPage(&&PgHdr(c2v_address_of(&p_pg_hdr))) }, 0)
		if rc != 0 {
			if need_sync_pgno <= p_pager.dbOrigSize {
				sqlite3_bitvec_clear(p_pager.pInJournal, need_sync_pgno, voidptr(p_pager.pTmpSpace))
			}
			return rc
		}
		p_pg_hdr.flags |= 8
		sqlite3_pcache_make_dirty(p_pg_hdr)
		sqlite3_pager_unref_not_null(unsafe { &DbPage(p_pg_hdr) })
	}
	return 0
}

@[c:'sqlite3PagerRekey']
fn sqlite3_pager_rekey(p_pg &DbPage, i_new Pgno, flags U16) {
	p_pg.flags = flags
	sqlite3_pcache_move(unsafe { &PgHdr(p_pg) }, i_new)
}

@[c:'sqlite3PagerGetData']
fn sqlite3_pager_get_data(p_pg &DbPage) voidptr {
	return p_pg.pData
}

@[c:'sqlite3PagerGetExtra']
fn sqlite3_pager_get_extra(p_pg &DbPage) voidptr {
	return p_pg.pExtra
}

@[c:'sqlite3PagerLockingMode']
fn sqlite3_pager_locking_mode(p_pager &Pager, e_mode int) int {
	if e_mode >= 0 && !p_pager.tempFile && !sqlite3_wal_heap_memory(p_pager.pWal) {
		p_pager.exclusiveMode = U8(e_mode)
	}
	return int(p_pager.exclusiveMode)
}

@[c:'sqlite3PagerSetJournalMode']
fn sqlite3_pager_set_journal_mode(p_pager &Pager, e_mode int) int {
	e_old := p_pager.journalMode
	if p_pager.memDb {
		if e_mode != 4 && e_mode != 2 {
			e_mode = int(e_old)
		}
	}
	if e_mode != int(e_old) {
		p_pager.journalMode = U8(e_mode)
		if !p_pager.exclusiveMode && (int(e_old) & 5) == 1 && (e_mode & 1) == 0 {
			sqlite3_os_close(p_pager.jfd)
			if int(p_pager.eLock) >= 2 {
				sqlite3_os_delete(p_pager.pVfs, p_pager.zJournal, 0)
			} else {
				rc := 0
				state := int(p_pager.eState)
				if state == 0 {
					rc = sqlite3_pager_shared_lock(p_pager)
				}
				if int(p_pager.eState) == 1 {
					rc = pager_lock_db(p_pager, 2)
				}
				if rc == 0 {
					sqlite3_os_delete(p_pager.pVfs, p_pager.zJournal, 0)
				}
				if rc == 0 && state == 1 {
					pager_unlock_db(p_pager, 1)
				} else if state == 0 {
					pager_unlock(p_pager)
				}
			}
		} else if e_mode == 2 || e_mode == 4 {
			sqlite3_os_close(p_pager.jfd)
		}
	}
	return int(p_pager.journalMode)
}

@[c:'sqlite3PagerGetJournalMode']
fn sqlite3_pager_get_journal_mode(p_pager &Pager) int {
	return int(p_pager.journalMode)
}

@[c:'sqlite3PagerOkToChangeJournalMode']
fn sqlite3_pager_ok_to_change_journal_mode(p_pager &Pager) int {
	if int(p_pager.eState) >= 3 {
		return 0
	}
	if ((usize(p_pager.jfd.pMethods) != usize(0)) && p_pager.journalOff > I64(0)) {
		return 0
	}
	return 1
}

@[c:'sqlite3PagerJournalSizeLimit']
fn sqlite3_pager_journal_size_limit(p_pager &Pager, i_limit I64) I64 {
	if i_limit >= I64(-1) {
		p_pager.journalSizeLimit = i_limit
		sqlite3_wal_limit(p_pager.pWal, i_limit)
	}
	return p_pager.journalSizeLimit
}

@[c:'sqlite3PagerBackupPtr']
fn sqlite3_pager_backup_ptr(p_pager &Pager) &&Sqlite3_backup {
	return &p_pager.pBackup
}

@[c:'sqlite3PagerClearCache']
fn sqlite3_pager_clear_cache(p_pager &Pager) {
	if int(p_pager.tempFile) == 0 {
		pager_reset(p_pager)
	}
}

@[c:'sqlite3PagerCheckpoint']
fn sqlite3_pager_checkpoint(p_pager &Pager, db &Sqlite3, e_mode int, pn_log &int, pn_ckpt &int) int {
	rc := 0
	if usize(p_pager.pWal) == usize(0) && int(p_pager.journalMode) == 5 {
		sqlite3_exec(db, c'PRAGMA table_list', unsafe { nil }, unsafe { nil }, unsafe { &&u8(nil) })
	}
	if p_pager.pWal {
		rc = sqlite3_wal_checkpoint_vdup9(p_pager.pWal, db, e_mode, (unsafe { if e_mode <= 0 {
			C2vFn_666e2028766f69647074722920696e74(voidptr(0))
		} else {
			p_pager.xBusyHandler
		} }), voidptr(p_pager.pBusyHandlerArg), int(p_pager.walSyncFlags), int(p_pager.pageSize), &U8(voidptr(p_pager.pTmpSpace)), pn_log, pn_ckpt)
	}
	return rc
}

@[c:'sqlite3PagerWalCallback']
fn sqlite3_pager_wal_callback(p_pager &Pager) int {
	return sqlite3_wal_callback(p_pager.pWal)
}

@[c:'sqlite3PagerWalSupported']
fn sqlite3_pager_wal_supported(p_pager &Pager) int {
	p_methods := p_pager.fd.pMethods
	if p_pager.noLock {
		return 0
	}
	return int(p_pager.exclusiveMode || (p_methods.iVersion >= 2 && !isnil(p_methods.xShmMap)))
}

@[c:'pagerExclusiveLock']
fn pager_exclusive_lock(p_pager &Pager) int {
	rc := 0
	e_orig_lock := U8(0)
	e_orig_lock = p_pager.eLock
	rc = pager_lock_db(p_pager, 4)
	if rc != 0 {
		pager_unlock_db(p_pager, int(e_orig_lock))
	}
	return rc
}

@[c:'pagerOpenWal']
fn pager_open_wal(p_pager &Pager) int {
	rc := 0
	if p_pager.exclusiveMode {
		rc = pager_exclusive_lock(p_pager)
	}
	if rc == 0 {
		rc = sqlite3_wal_open(p_pager.pVfs, p_pager.fd, p_pager.zWal, int(p_pager.exclusiveMode), p_pager.journalSizeLimit, &&Wal(&p_pager.pWal))
	}
	pager_fix_maplimit(p_pager)
	return rc
}

@[c:'sqlite3PagerOpenWal']
fn sqlite3_pager_open_wal(p_pager &Pager, pb_open &int) int {
	rc := 0
	if !p_pager.tempFile && isnil(p_pager.pWal) {
		if !sqlite3_pager_wal_supported(p_pager) {
			return 14
		}
		sqlite3_os_close(p_pager.jfd)
		rc = pager_open_wal(p_pager)
		if rc == 0 {
			p_pager.journalMode = U8(5)
			p_pager.eState = U8(0)
		}
	} else {
		unsafe { *pb_open = 1 }
	}
	return rc
}

@[c:'sqlite3PagerCloseWal']
fn sqlite3_pager_close_wal(p_pager &Pager, db &Sqlite3) int {
	rc := 0
	if isnil(p_pager.pWal) {
		logexists := 0
		rc = pager_lock_db(p_pager, 1)
		if rc == 0 {
			rc = sqlite3_os_access(p_pager.pVfs, p_pager.zWal, 0, &logexists)
		}
		if rc == 0 && logexists {
			rc = pager_open_wal(p_pager)
		}
	}
	if rc == 0 && !isnil(p_pager.pWal) {
		rc = pager_exclusive_lock(p_pager)
		if rc == 0 {
			rc = sqlite3_wal_close(p_pager.pWal, db, int(p_pager.walSyncFlags), int(p_pager.pageSize), &U8(voidptr(p_pager.pTmpSpace)))
			p_pager.pWal = 0
			pager_fix_maplimit(p_pager)
			if rc && !p_pager.exclusiveMode {
				pager_unlock_db(p_pager, 1)
			}
		}
	}
	return rc
}
