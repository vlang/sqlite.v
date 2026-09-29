@[translated]
module main

struct FileChunk {
	pNext  &FileChunk
	zChunk [8]U8
}

struct FilePoint {
	iOffset Sqlite3_int64
	pChunk  &FileChunk
}

struct MemJournal {
	pMethod    &Sqlite3_io_methods
	nChunkSize int
	nSpill     int
	pFirst     &FileChunk
	endpoint   FilePoint
	readpoint  FilePoint
	flags      int
	pVfs       &Sqlite3_vfs
	zJournal   &i8
}

@[c:'memjrnlRead']
fn memjrnl_read(p_jfd &Sqlite3_file, z_buf voidptr, i_amt int, i_ofst Sqlite_int64) int {
	c2v_gc_register_thread()
	p := &MemJournal(voidptr(p_jfd))
	z_out := &U8(z_buf)
	n_read := i_amt
	i_chunk_offset := 0
	p_chunk := &FileChunk(0)
	if (Sqlite_int64(i_amt) + i_ofst) > p.endpoint.iOffset {
		return 10 | (2 << 8)
	}
	if p.readpoint.iOffset != i_ofst || i_ofst == Sqlite_int64(0) {
		i_off := Sqlite3_int64(0)
		for p_chunk = p.pFirst; !isnil(p_chunk) && (i_off + Sqlite3_int64(p.nChunkSize)) <= i_ofst; p_chunk = p_chunk.pNext {
			i_off += Sqlite3_int64(p.nChunkSize)
		}
	} else {
		p_chunk = p.readpoint.pChunk
	}
	i_chunk_offset = int((i_ofst % Sqlite_int64(p.nChunkSize)))
	for {
		i_space := p.nChunkSize - i_chunk_offset
		n_copy := (if n_read < (p.nChunkSize - i_chunk_offset) {
			n_read
		} else {
			(p.nChunkSize - i_chunk_offset)
		})
		C.memcpy(voidptr(z_out), voidptr(&U8(unsafe { &p_chunk.zChunk[0] }) + i_chunk_offset), u64(n_copy))
		c2v_pointer_prefix(voidptr(&z_out), z_out, isize(n_copy))
		n_read -= i_space
		i_chunk_offset = 0
		if !(n_read >= 0 && usize(c2v_assign[&FileChunk](unsafe { &p_chunk }, p_chunk.pNext)) != usize(0) && n_read > 0) {
			break
		}
	}
	p.readpoint.iOffset = if p_chunk { i_ofst + Sqlite_int64(i_amt) } else { Sqlite_int64(0) }
	p.readpoint.pChunk = p_chunk
	return 0
}

@[c:'memjrnlFreeChunks']
fn memjrnl_free_chunks(p_first &FileChunk) {
	p_iter := &FileChunk(0)
	p_next := &FileChunk(0)
	for p_iter = p_first; p_iter; p_iter = p_next {
		p_next = p_iter.pNext
		sqlite3_free(voidptr(p_iter))
	}
}

@[c:'memjrnlCreateFile']
fn memjrnl_create_file(p &MemJournal) int {
	rc := 0
	p_real := &Sqlite3_file(voidptr(p))
	copy := (unsafe { *p })
	C.memset(voidptr(p), 0, sizeof(MemJournal))
	rc = sqlite3_os_open(copy.pVfs, copy.zJournal, p_real, copy.flags, unsafe { nil })
	if rc == 0 {
		n_chunk := copy.nChunkSize
		i_off := I64(0)
		p_iter := &FileChunk(0)
		for p_iter = copy.pFirst; p_iter; p_iter = p_iter.pNext {
			if i_off + I64(n_chunk) > copy.endpoint.iOffset {
				n_chunk = int(copy.endpoint.iOffset - i_off)
			}
			rc = sqlite3_os_write(p_real, voidptr(&U8(unsafe { &p_iter.zChunk[0] })), n_chunk, i_off)
			if rc {
				break
			}
			i_off += I64(n_chunk)
		}
		if rc == 0 {
			memjrnl_free_chunks(copy.pFirst)
		}
	}
	if rc != 0 {
		sqlite3_os_close(p_real)
		unsafe { *p = copy }
	}
	return rc
}

@[c:'memjrnlWrite']
fn memjrnl_write(p_jfd &Sqlite3_file, z_buf voidptr, i_amt int, i_ofst Sqlite_int64) int {
	c2v_gc_register_thread()
	p := &MemJournal(voidptr(p_jfd))
	n_write := i_amt
	z_write := &U8(z_buf)
	if p.nSpill > 0 && (Sqlite_int64(i_amt) + i_ofst) > Sqlite_int64(p.nSpill) {
		rc := memjrnl_create_file(p)
		if rc == 0 {
			rc = sqlite3_os_write(p_jfd, voidptr(z_buf), i_amt, i_ofst)
		}
		return rc
	} else {
		if i_ofst > Sqlite_int64(0) && i_ofst != p.endpoint.iOffset {
			memjrnl_truncate(p_jfd, i_ofst)
		}
		if i_ofst == Sqlite_int64(0) && !isnil(p.pFirst) {
			C.memcpy(voidptr(&U8(unsafe { &p.pFirst.zChunk[0] })), voidptr(z_buf), u64(i_amt))
		} else {
			for n_write > 0 {
				p_chunk := p.endpoint.pChunk
				i_chunk_offset := int((p.endpoint.iOffset % Sqlite3_int64(p.nChunkSize)))
				i_space := (if n_write < (p.nChunkSize - i_chunk_offset) {
					n_write
				} else {
					(p.nChunkSize - i_chunk_offset)
				})
				if i_chunk_offset == 0 {
					p_new := &FileChunk(sqlite3_malloc(int((sizeof(FileChunk) + u64((p.nChunkSize - 8))))))
					if isnil(p_new) {
						return 10 | (12 << 8)
					}
					p_new.pNext = 0
					if p_chunk {
						p_chunk.pNext = p_new
					} else {
						p.pFirst = p_new
					}
					p.endpoint.pChunk = p_new
					p_chunk = p.endpoint.pChunk
				}
				C.memcpy(voidptr(&U8(unsafe { &p_chunk.zChunk[0] }) + i_chunk_offset), voidptr(z_write), u64(i_space))
				c2v_pointer_prefix(voidptr(&z_write), z_write, isize(i_space))
				n_write -= i_space
				p.endpoint.iOffset += Sqlite3_int64(i_space)
			}
		}
	}
	return 0
}

@[c:'memjrnlTruncate']
fn memjrnl_truncate(p_jfd &Sqlite3_file, size Sqlite_int64) int {
	c2v_gc_register_thread()
	p := &MemJournal(voidptr(p_jfd))
	if size < p.endpoint.iOffset {
		p_iter := unsafe { &FileChunk(nil) }
		if size == Sqlite_int64(0) {
			memjrnl_free_chunks(p.pFirst)
			p.pFirst = 0
		} else {
			i_off := I64(p.nChunkSize)
			for p_iter = p.pFirst; !isnil(p_iter) && i_off < size; p_iter = p_iter.pNext {
				i_off += I64(p.nChunkSize)
			}
			if p_iter {
				memjrnl_free_chunks(p_iter.pNext)
				p_iter.pNext = 0
			}
		}
		p.endpoint.pChunk = p_iter
		p.endpoint.iOffset = size
		p.readpoint.pChunk = 0
		p.readpoint.iOffset = Sqlite3_int64(0)
	}
	return 0
}

@[c:'memjrnlClose']
fn memjrnl_close(p_jfd &Sqlite3_file) int {
	c2v_gc_register_thread()
	p := &MemJournal(voidptr(p_jfd))
	memjrnl_free_chunks(p.pFirst)
	return 0
}

@[c:'memjrnlSync']
fn memjrnl_sync(p_jfd &Sqlite3_file, flags int) int {
	c2v_gc_register_thread()

	return 0
}

@[c:'memjrnlFileSize']
fn memjrnl_file_size(p_jfd &Sqlite3_file, p_size &Sqlite_int64) int {
	c2v_gc_register_thread()
	p := &MemJournal(voidptr(p_jfd))
	unsafe { *p_size = Sqlite_int64(p.endpoint.iOffset) }
	return 0
}

@[c:'sqlite3JournalOpen']
fn sqlite3_journal_open(p_vfs &Sqlite3_vfs, z_name &i8, p_jfd &Sqlite3_file, flags int, n_spill int) int {
	p := &MemJournal(voidptr(p_jfd))
	C.memset(voidptr(p), 0, sizeof(MemJournal))
	if n_spill == 0 {
		return sqlite3_os_open(p_vfs, z_name, p_jfd, flags, unsafe { nil })
	}
	if n_spill > 0 {
		p.nChunkSize = n_spill
	} else {
		p.nChunkSize = int(u64(8 + 1024) - sizeof(FileChunk))
	}
	p_jfd.pMethods = &Sqlite3_io_methods(&memJournalMethods)
	p.nSpill = n_spill
	p.flags = flags
	p.zJournal = z_name
	p.pVfs = p_vfs
	return 0
}

@[c:'sqlite3MemJournalOpen']
fn sqlite3_mem_journal_open(p_jfd &Sqlite3_file) {
	sqlite3_journal_open(unsafe { nil }, unsafe { nil }, p_jfd, 0, -1)
}

@[c:'sqlite3JournalIsInMemory']
fn sqlite3_journal_is_in_memory(p &Sqlite3_file) int {
	return int(usize(p.pMethods) == usize(&memJournalMethods))
}

@[c:'sqlite3JournalSize']
fn sqlite3_journal_size(p_vfs &Sqlite3_vfs) int {
	return if p_vfs.szOsFile > (int(sizeof(MemJournal))) {
		p_vfs.szOsFile
	} else {
		(int(sizeof(MemJournal)))
	}
}
