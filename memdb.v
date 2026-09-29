@[translated]
module main

type MemVfs = Sqlite3_vfs

struct MemStore {
	sz      Sqlite3_int64
	szAlloc Sqlite3_int64
	szMax   Sqlite3_int64
	aData   &u8
	pMutex  &Sqlite3_mutex
	nMmap   int
	mFlags  u32
	nRdLock int
	nWrLock int
	nRef    int
	zFName  &i8
}

struct MemFile {
	base   Sqlite3_file
	pStore &MemStore
	eLock  int
}

struct MemFS {
	nMemStore  int
	apMemStore &&MemStore
}

@[weak]
__global memdb_g MemFS

@[c:'memdbEnter']
fn memdb_enter(p &MemStore) {
	sqlite3_mutex_enter(p.pMutex)
}

@[c:'memdbLeave']
fn memdb_leave(p &MemStore) {
	sqlite3_mutex_leave(p.pMutex)
}

@[c:'memdbClose']
fn memdb_close(p_file &Sqlite3_file) int {
	c2v_gc_register_thread()
	p := (&MemFile(voidptr(p_file))).pStore
	if p.zFName {
		i := 0
		p_vfs_mutex := sqlite3_mutex_alloc_vdup4(11)
		sqlite3_mutex_enter(p_vfs_mutex)
		for i = 0; (i < memdb_g.nMemStore); i++ {
			if usize(memdb_g.apMemStore[i]) == usize(p) {
				memdb_enter(p)
				if p.nRef == 1 {
					memdb_g.apMemStore[i] = memdb_g.apMemStore[c2v_prefix_add(unsafe { &memdb_g.nMemStore }, -1)]
					if memdb_g.nMemStore == 0 {
						sqlite3_free(voidptr(memdb_g.apMemStore))
						memdb_g.apMemStore = 0
					}
				}
				break
			}
		}
		sqlite3_mutex_leave(p_vfs_mutex)
	} else {
		memdb_enter(p)
	}
	p.nRef--
	if p.nRef <= 0 {
		if p.mFlags & u32(1) {
			sqlite3_free(voidptr(p.aData))
		}
		memdb_leave(p)
		sqlite3_mutex_free(p.pMutex)
		sqlite3_free(voidptr(p))
	} else {
		memdb_leave(p)
	}
	return 0
}

@[c:'memdbRead']
fn memdb_read(p_file &Sqlite3_file, z_buf voidptr, i_amt int, i_ofst Sqlite_int64) int {
	c2v_gc_register_thread()
	p := (&MemFile(voidptr(p_file))).pStore
	memdb_enter(p)
	if i_ofst + Sqlite_int64(i_amt) > p.sz {
		C.memset(voidptr(z_buf), 0, u64(i_amt))
		if i_ofst < p.sz {
			C.memcpy(voidptr(z_buf), voidptr(p.aData + i_ofst), u64(p.sz - i_ofst))
		}
		memdb_leave(p)
		return 10 | (2 << 8)
	}
	C.memcpy(voidptr(z_buf), voidptr(p.aData + i_ofst), u64(i_amt))
	memdb_leave(p)
	return 0
}

@[c:'memdbEnlarge']
fn memdb_enlarge(p &MemStore, new_sz Sqlite3_int64) int {
	p_new := &u8(0)
	if (p.mFlags & u32(2)) == u32(0) || (p.nMmap > 0) {
		return 13
	}
	if new_sz > p.szMax {
		return 13
	}
	new_sz *= Sqlite3_int64(2)
	if new_sz > p.szMax {
		new_sz = p.szMax
	}
	p_new = &u8(sqlite3_realloc_vdup3(voidptr(p.aData), U64(new_sz)))
	if usize(p_new) == usize(0) {
		return 10 | (12 << 8)
	}
	p.aData = p_new
	p.szAlloc = new_sz
	return 0
}

@[c:'memdbWrite']
fn memdb_write(p_file &Sqlite3_file, z voidptr, i_amt int, i_ofst Sqlite_int64) int {
	c2v_gc_register_thread()
	p := (&MemFile(voidptr(p_file))).pStore
	memdb_enter(p)
	if (p.mFlags & u32(4)) {
		memdb_leave(p)
		return 10 | (3 << 8)
	}
	if i_ofst + Sqlite_int64(i_amt) > p.sz {
		rc := 0
		if i_ofst + Sqlite_int64(i_amt) > p.szAlloc && c2v_assign[int](unsafe { &rc }, int(memdb_enlarge(p, i_ofst + Sqlite_int64(i_amt)))) != 0 {
			memdb_leave(p)
			return rc
		}
		if i_ofst > p.sz {
			C.memset(voidptr(p.aData + p.sz), 0, u64(i_ofst - p.sz))
		}
		p.sz = i_ofst + Sqlite_int64(i_amt)
	}
	C.memcpy(voidptr(p.aData + i_ofst), voidptr(z), u64(i_amt))
	memdb_leave(p)
	return 0
}

@[c:'memdbTruncate']
fn memdb_truncate(p_file &Sqlite3_file, size Sqlite_int64) int {
	c2v_gc_register_thread()
	p := (&MemFile(voidptr(p_file))).pStore
	rc := 0
	memdb_enter(p)
	if size > p.sz {
		rc = 11
	} else {
		p.sz = size
	}
	memdb_leave(p)
	return rc
}

@[c:'memdbSync']
fn memdb_sync(p_file &Sqlite3_file, flags int) int {
	c2v_gc_register_thread()

	return 0
}

@[c:'memdbFileSize']
fn memdb_file_size(p_file &Sqlite3_file, p_size &Sqlite_int64) int {
	c2v_gc_register_thread()
	p := (&MemFile(voidptr(p_file))).pStore
	memdb_enter(p)
	unsafe { *p_size = p.sz }
	memdb_leave(p)
	return 0
}

@[c:'memdbLock']
fn memdb_lock(p_file &Sqlite3_file, e_lock int) int {
	c2v_gc_register_thread()
	p_this := &MemFile(voidptr(p_file))
	p := p_this.pStore
	rc := 0
	if e_lock <= p_this.eLock {
		return 0
	}
	memdb_enter(p)
	if e_lock > 1 && (p.mFlags & u32(4)) {
		rc = 8
	} else {
		match e_lock {
			1 {
				if p.nWrLock > 0 {
					rc = 5
				} else {
					p.nRdLock++
				}
				unsafe { goto c2v_switch_end_12
				 }

				unsafe { goto c2v_case_12_2
				 }
			}
			2, 3 {
				c2v_case_12_2:
				if (p_this.eLock == 1) {
					if p.nWrLock > 0 {
						rc = 5
					} else {
						p.nWrLock = 1
					}
				}
			}
			else {
				if p.nRdLock > 1 {
					rc = 5
				} else if p_this.eLock == 1 {
					p.nWrLock = 1
				}
			}
		}
		c2v_switch_end_12:
	}
	if rc == 0 {
		p_this.eLock = e_lock
	}
	memdb_leave(p)
	return rc
}

@[c:'memdbUnlock']
fn memdb_unlock(p_file &Sqlite3_file, e_lock int) int {
	c2v_gc_register_thread()
	p_this := &MemFile(voidptr(p_file))
	p := p_this.pStore
	if e_lock >= p_this.eLock {
		return 0
	}
	memdb_enter(p)
	if e_lock == 1 {
		if (p_this.eLock > 1) {
			p.nWrLock--
		}
	} else {
		if p_this.eLock > 1 {
			p.nWrLock--
		}
		p.nRdLock--
	}
	p_this.eLock = e_lock
	memdb_leave(p)
	return 0
}

@[c:'memdbFileControl']
fn memdb_file_control(p_file &Sqlite3_file, op int, p_arg voidptr) int {
	c2v_gc_register_thread()
	p := (&MemFile(voidptr(p_file))).pStore
	rc := 12
	memdb_enter(p)
	if op == 12 {
		mut __c2v_lhs_tmp_69 := unsafe { &&u8(p_arg) }
		unsafe { *__c2v_lhs_tmp_69 = sqlite3_mprintf(c'memdb(%p,%lld)', voidptr(p.aData), p.sz) }
		rc = 0
	}
	if op == 36 {
		i_limit := (unsafe { *&Sqlite3_int64(p_arg) })
		if i_limit < p.sz {
			if i_limit < Sqlite3_int64(0) {
				i_limit = p.szMax
			} else {
				i_limit = p.sz
			}
		}
		p.szMax = i_limit
		mut __c2v_lhs_tmp_70 := unsafe { &Sqlite3_int64(p_arg) }
		unsafe { *__c2v_lhs_tmp_70 = i_limit }
		rc = 0
	}
	memdb_leave(p)
	return rc
}

@[c:'memdbDeviceCharacteristics']
fn memdb_device_characteristics(p_file &Sqlite3_file) int {
	c2v_gc_register_thread()

	return 1 | 4096 | 512 | 1024
}

@[c:'memdbFetch']
fn memdb_fetch(p_file &Sqlite3_file, i_ofst Sqlite3_int64, i_amt int, pp &voidptr) int {
	c2v_gc_register_thread()
	p := (&MemFile(voidptr(p_file))).pStore
	memdb_enter(p)
	if i_ofst + Sqlite3_int64(i_amt) > p.sz || (p.mFlags & u32(2)) != u32(0) {
		unsafe { *pp = 0 }
	} else {
		p.nMmap++
		unsafe { *pp = voidptr((p.aData + i_ofst)) }
	}
	memdb_leave(p)
	return 0
}

@[c:'memdbUnfetch']
fn memdb_unfetch(p_file &Sqlite3_file, i_ofst Sqlite3_int64, p_page voidptr) int {
	c2v_gc_register_thread()
	p := (&MemFile(voidptr(p_file))).pStore

	memdb_enter(p)
	p.nMmap--
	memdb_leave(p)
	return 0
}

@[c:'memdbOpen']
fn memdb_open(p_vfs &Sqlite3_vfs, z_name &i8, p_fd &Sqlite3_file, flags int, p_out_flags &int) int {
	c2v_gc_register_thread()
	p_file := &MemFile(voidptr(p_fd))
	p := unsafe { &MemStore(nil) }
	sz_name := 0

	C.memset(voidptr(p_file), 0, sizeof(MemFile))
	sz_name = sqlite3_strlen30(z_name)
	if sz_name > 1 && (int(z_name[0]) == i8(`/`) || int(z_name[0]) == i8(`\\`)) {
		i := 0
		p_vfs_mutex := sqlite3_mutex_alloc_vdup4(11)
		sqlite3_mutex_enter(p_vfs_mutex)
		for i = 0; i < memdb_g.nMemStore; i++ {
			if C.strcmp(memdb_g.apMemStore[i].zFName, z_name) == 0 {
				p = memdb_g.apMemStore[i]
				break
			}
		}
		if usize(p) == usize(0) {
			ap_new := &&MemStore(0)
			p = sqlite3_malloc_vdup2(sizeof(MemStore) + u64(I64(sz_name)) + u64(3))
			if usize(p) == usize(0) {
				sqlite3_mutex_leave(p_vfs_mutex)
				return 7
			}
			ap_new = sqlite3_realloc_vdup3(voidptr(memdb_g.apMemStore), sizeof(&MemStore) * u64((I64(1) + I64(memdb_g.nMemStore))))
			if usize(ap_new) == usize(0) {
				sqlite3_free(voidptr(p))
				sqlite3_mutex_leave(p_vfs_mutex)
				return 7
			}
			ap_new[memdb_g.nMemStore++] = p
			memdb_g.apMemStore = ap_new
			C.memset(voidptr(p), 0, sizeof(MemStore))
			p.mFlags = u32(2 | 1)
			p.szMax = sqlite3Config.mxMemdbSize
			p.zFName = &i8(voidptr(unsafe { p + 1 }))
			C.memcpy(voidptr(p.zFName), voidptr(z_name), u64(sz_name + 1))
			p.pMutex = sqlite3_mutex_alloc(0)
			if usize(p.pMutex) == usize(0) {
				memdb_g.nMemStore--
				sqlite3_free(voidptr(p))
				sqlite3_mutex_leave(p_vfs_mutex)
				return 7
			}
			p.nRef = 1
			memdb_enter(p)
		} else {
			memdb_enter(p)
			p.nRef++
		}
		sqlite3_mutex_leave(p_vfs_mutex)
	} else {
		p = sqlite3_malloc_vdup2(U64(sizeof(MemStore)))
		if usize(p) == usize(0) {
			return 7
		}
		C.memset(voidptr(p), 0, sizeof(MemStore))
		p.mFlags = u32(2 | 1)
		p.szMax = sqlite3Config.mxMemdbSize
	}
	p_file.pStore = p
	if usize(p_out_flags) != usize(0) {
		unsafe { *p_out_flags = flags | 128 }
	}
	p_fd.pMethods = &memdb_io_methods
	memdb_leave(p)
	return 0
}

@[c:'memdbAccess']
fn memdb_access(p_vfs &Sqlite3_vfs, z_path &i8, flags int, p_res_out &int) int {
	c2v_gc_register_thread()

	unsafe { *p_res_out = 0 }
	return 0
}

@[c:'memdbFullPathname']
fn memdb_full_pathname(p_vfs &Sqlite3_vfs, z_path &i8, n_out int, z_out &i8) int {
	c2v_gc_register_thread()

	sqlite3_snprintf(n_out, z_out, c'%s', voidptr(z_path))
	return 0
}

@[c:'memdbDlOpen']
fn memdb_dl_open(p_vfs &Sqlite3_vfs, z_path &i8) voidptr {
	c2v_gc_register_thread()
	return (&Sqlite3_vfs(p_vfs.pAppData)).xDlOpen((&Sqlite3_vfs(p_vfs.pAppData)), z_path)
}

@[c:'memdbDlError']
fn memdb_dl_error(p_vfs &Sqlite3_vfs, n_byte int, z_err_msg &i8) {
	c2v_gc_register_thread()
	(&Sqlite3_vfs(p_vfs.pAppData)).xDlError((&Sqlite3_vfs(p_vfs.pAppData)), n_byte, z_err_msg)
}

@[c:'memdbDlSym']
fn memdb_dl_sym(p_vfs &Sqlite3_vfs, p voidptr, z_sym &i8) C2vFn_666e202829 {
	c2v_gc_register_thread()
	return (&Sqlite3_vfs(p_vfs.pAppData)).xDlSym((&Sqlite3_vfs(p_vfs.pAppData)), p, z_sym)
}

@[c:'memdbDlClose']
fn memdb_dl_close(p_vfs &Sqlite3_vfs, p_handle voidptr) {
	c2v_gc_register_thread()
	(&Sqlite3_vfs(p_vfs.pAppData)).xDlClose((&Sqlite3_vfs(p_vfs.pAppData)), voidptr(p_handle))
}

@[c:'memdbRandomness']
fn memdb_randomness(p_vfs &Sqlite3_vfs, n_byte int, z_buf_out &i8) int {
	c2v_gc_register_thread()
	return (&Sqlite3_vfs(p_vfs.pAppData)).xRandomness((&Sqlite3_vfs(p_vfs.pAppData)), n_byte, z_buf_out)
}

@[c:'memdbSleep']
fn memdb_sleep(p_vfs &Sqlite3_vfs, n_micro int) int {
	c2v_gc_register_thread()
	return (&Sqlite3_vfs(p_vfs.pAppData)).xSleep((&Sqlite3_vfs(p_vfs.pAppData)), n_micro)
}

@[c:'memdbGetLastError']
fn memdb_get_last_error(p_vfs &Sqlite3_vfs, a int, b &i8) int {
	c2v_gc_register_thread()
	return (&Sqlite3_vfs(p_vfs.pAppData)).xGetLastError((&Sqlite3_vfs(p_vfs.pAppData)), a, b)
}

@[c:'memdbCurrentTimeInt64']
fn memdb_current_time_int64(p_vfs &Sqlite3_vfs, p &Sqlite3_int64) int {
	c2v_gc_register_thread()
	return (&Sqlite3_vfs(p_vfs.pAppData)).xCurrentTimeInt64((&Sqlite3_vfs(p_vfs.pAppData)), p)
}

@[c:'memdbFromDbSchema']
fn memdb_from_db_schema(db &Sqlite3, z_schema &i8) &MemFile {
	p := unsafe { &MemFile(nil) }
	p_store := &MemStore(0)
	rc := sqlite3_file_control(db, z_schema, 7, voidptr(&&MemFile(c2v_address_of(&p))))
	if rc {
		return unsafe { nil }
	}
	if usize(p.base.pMethods) != usize(&memdb_io_methods) {
		return unsafe { nil }
	}
	p_store = p.pStore
	memdb_enter(p_store)
	if usize(p_store.zFName) != usize(0) {
		p = 0
	}
	memdb_leave(p_store)
	return p
}

fn sqlite3_serialize(db &Sqlite3, z_schema &i8, pi_size &Sqlite3_int64, m_flags u32) &u8 {
	c2v_gc_register_thread()
	p := &MemFile(0)
	i_db := 0
	p_bt := &Btree(0)
	sz := Sqlite3_int64(0)
	sz_page := 0
	p_stmt := unsafe { &Sqlite3_stmt(nil) }
	p_out := unsafe { &u8(nil) }
	z_sql := &i8(0)
	rc := 0
	sqlite3_mutex_enter(db.mutex)
	if usize(z_schema) == usize(0) {
		z_schema = db.aDb[0].zDbSName
	}
	p = memdb_from_db_schema(db, z_schema)
	i_db = sqlite3_find_db_name(db, z_schema)
	if pi_size {
		unsafe { *pi_size = Sqlite3_int64(-1) }
	}
	if i_db < 0 {
		unsafe { goto serialize_out
		 }
	}
	if p {
		p_store := p.pStore
		if pi_size {
			unsafe { *pi_size = p_store.sz }
		}
		if m_flags & u32(1) {
			p_out = p_store.aData
		} else {
			p_out = &u8(sqlite3_malloc64(Sqlite3_uint64(p_store.sz)))
			if p_out {
				C.memcpy(voidptr(p_out), voidptr(p_store.aData), u64(p_store.sz))
			}
		}
		unsafe { goto serialize_out
		 }
	}
	p_bt = db.aDb[i_db].pBt
	if usize(p_bt) == usize(0) {
		unsafe { goto serialize_out
		 }
	}
	sz_page = sqlite3_btree_get_page_size(p_bt)
	z_sql = sqlite3_mprintf(c'PRAGMA "%w".page_count', voidptr(z_schema))
	rc = if z_sql {
		sqlite3_prepare_v2(db, z_sql, -1, &&Sqlite3_stmt(&&Sqlite3_stmt(c2v_address_of(&p_stmt))), unsafe { &&u8(nil) })
	} else {
		7
	}
	sqlite3_free(voidptr(z_sql))
	if rc {
		unsafe { goto serialize_out
		 }
	}
	rc = sqlite3_step(p_stmt)
	if rc == 100 {
		sz = sqlite3_column_int64(p_stmt, 0) * Sqlite3_int64(sz_page)
		if sz == Sqlite3_int64(0) {
			sqlite3_reset(p_stmt)
			sqlite3_exec(db, c'BEGIN IMMEDIATE; COMMIT;', unsafe { nil }, unsafe { nil }, unsafe { &&u8(nil) })
			rc = sqlite3_step(p_stmt)
			if rc == 100 {
				sz = sqlite3_column_int64(p_stmt, 0) * Sqlite3_int64(sz_page)
			}
		}
		if pi_size {
			unsafe { *pi_size = sz }
		}
		if m_flags & u32(1) {
			p_out = 0
		} else {
			p_out = &u8(sqlite3_malloc64(Sqlite3_uint64(sz)))
			if p_out {
				n_page := sqlite3_column_int(p_stmt, 0)
				p_pager := sqlite3_btree_pager(p_bt)
				pgno := 0
				for pgno = 1; pgno <= n_page; pgno++ {
					p_page := unsafe { &DbPage(nil) }
					p_to := p_out + (Sqlite3_int64(sz_page) * Sqlite3_int64((pgno - 1)))
					rc = sqlite3_pager_get(p_pager, Pgno(pgno), &&DbPage(c2v_address_of(&p_page)), 0)
					if rc == 0 {
						C.memcpy(voidptr(p_to), voidptr(sqlite3_pager_get_data(p_page)), u64(sz_page))
					} else {
						C.memset(voidptr(p_to), 0, u64(sz_page))
					}
					sqlite3_pager_unref(p_page)
				}
			}
		}
	}
	sqlite3_finalize(p_stmt)
	serialize_out:
	sqlite3_mutex_leave(db.mutex)
	return p_out
}

fn sqlite3_deserialize(db &Sqlite3, z_schema &i8, p_data &u8, sz_db Sqlite3_int64, sz_buf Sqlite3_int64, m_flags u32) int {
	c2v_gc_register_thread()
	p := &MemFile(0)
	z_sql := &i8(0)
	p_stmt := unsafe { &Sqlite3_stmt(nil) }
	rc := 0
	i_db := 0
	sqlite3_mutex_enter(db.mutex)
	if usize(z_schema) == usize(0) {
		z_schema = db.aDb[0].zDbSName
	}
	i_db = sqlite3_find_db_name(db, z_schema)
	if i_db < 2 && i_db != 0 {
		rc = 1
		unsafe { goto end_deserialize
		 }
	}
	z_sql = sqlite3_mprintf(c'ATTACH x AS %Q', voidptr(z_schema))
	if usize(z_sql) == usize(0) {
		rc = 7
	} else {
		rc = sqlite3_prepare_v2(db, z_sql, -1, &&Sqlite3_stmt(&&Sqlite3_stmt(c2v_address_of(&p_stmt))), unsafe { &&u8(nil) })
		sqlite3_free(voidptr(z_sql))
	}
	if rc {
		unsafe { goto end_deserialize
		 }
	}
	db.init.iDb = U8(i_db)
	db.init.reopenMemdb = u32(1)
	sqlite3_step(p_stmt)
	db.init.reopenMemdb = u32(0)
	rc = sqlite3_finalize(p_stmt)
	if rc != 0 {
		unsafe { goto end_deserialize
		 }
	}
	p = memdb_from_db_schema(db, z_schema)
	if usize(p) == usize(0) {
		rc = 1
	} else {
		p_store := p.pStore
		p_store.aData = p_data
		p_data = 0
		p_store.sz = sz_db
		p_store.szAlloc = sz_buf
		p_store.szMax = sz_buf
		if p_store.szMax < sqlite3Config.mxMemdbSize {
			p_store.szMax = sqlite3Config.mxMemdbSize
		}
		p_store.mFlags = m_flags
		rc = 0
	}
	end_deserialize:
	if !isnil(p_data) && (m_flags & u32(1)) != u32(0) {
		sqlite3_free(voidptr(p_data))
	}
	sqlite3_mutex_leave(db.mutex)
	return rc
}

@[c:'sqlite3IsMemdb']
fn sqlite3_is_memdb(p_vfs &Sqlite3_vfs) int {
	return int(usize(p_vfs) == usize(&memdb_vfs))
}

@[c:'sqlite3MemdbInit']
fn sqlite3_memdb_init() int {
	p_lower := sqlite3_vfs_find(unsafe { nil })
	sz := u32(0)
	if (usize(p_lower) == usize(0)) {
		return 1
	}
	sz = u32(p_lower.szOsFile)
	memdb_vfs.pAppData = p_lower
	if u64(sz) < sizeof(MemFile) {
		sz = u32(sizeof(MemFile))
	}
	memdb_vfs.szOsFile = int(sz)
	return sqlite3_vfs_register(&memdb_vfs, 0)
}
