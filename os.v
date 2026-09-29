@[translated]
module main

@[c:'sqlite3OsClose']
fn sqlite3_os_close(p_id &Sqlite3_file) {
	if p_id.pMethods {
		p_id.pMethods.xClose(p_id)
		p_id.pMethods = 0
	}
}

@[c:'sqlite3OsRead']
fn sqlite3_os_read(id &Sqlite3_file, p_buf voidptr, amt int, offset I64) int {
	return id.pMethods.xRead(id, voidptr(p_buf), amt, offset)
}

@[c:'sqlite3OsWrite']
fn sqlite3_os_write(id &Sqlite3_file, p_buf voidptr, amt int, offset I64) int {
	return id.pMethods.xWrite(id, voidptr(p_buf), amt, offset)
}

@[c:'sqlite3OsTruncate']
fn sqlite3_os_truncate(id &Sqlite3_file, size I64) int {
	return id.pMethods.xTruncate(id, size)
}

@[c:'sqlite3OsSync']
fn sqlite3_os_sync(id &Sqlite3_file, flags int) int {
	return if flags { id.pMethods.xSync(id, flags) } else { 0 }
}

@[c:'sqlite3OsFileSize']
fn sqlite3_os_file_size(id &Sqlite3_file, p_size &I64) int {
	return id.pMethods.xFileSize(id, unsafe { &Sqlite3_int64(p_size) })
}

@[c:'sqlite3OsLock']
fn sqlite3_os_lock(id &Sqlite3_file, lock_type int) int {
	return id.pMethods.xLock(id, lock_type)
}

@[c:'sqlite3OsUnlock']
fn sqlite3_os_unlock(id &Sqlite3_file, lock_type int) int {
	return id.pMethods.xUnlock(id, lock_type)
}

@[c:'sqlite3OsCheckReservedLock']
fn sqlite3_os_check_reserved_lock(id &Sqlite3_file, p_res_out &int) int {
	return id.pMethods.xCheckReservedLock(id, p_res_out)
}

@[c:'sqlite3OsFileControl']
fn sqlite3_os_file_control(id &Sqlite3_file, op int, p_arg voidptr) int {
	if usize(id.pMethods) == usize(0) {
		return 12
	}
	return id.pMethods.xFileControl(id, op, voidptr(p_arg))
}

@[c:'sqlite3OsFileControlHint']
fn sqlite3_os_file_control_hint(id &Sqlite3_file, op int, p_arg voidptr) {
	if id.pMethods {
		id.pMethods.xFileControl(id, op, voidptr(p_arg))
	}
}

@[c:'sqlite3OsSectorSize']
fn sqlite3_os_sector_size(id &Sqlite3_file) int {
	x_sector_size := id.pMethods.xSectorSize
	return if x_sector_size { x_sector_size(id) } else { 4096 }
}

@[c:'sqlite3OsDeviceCharacteristics']
fn sqlite3_os_device_characteristics(id &Sqlite3_file) int {
	if (usize(id.pMethods) == usize(0)) {
		return 0
	}
	return id.pMethods.xDeviceCharacteristics(id)
}

@[c:'sqlite3OsShmLock']
fn sqlite3_os_shm_lock(id &Sqlite3_file, offset int, n int, flags int) int {
	return id.pMethods.xShmLock(id, offset, n, flags)
}

@[c:'sqlite3OsShmBarrier']
fn sqlite3_os_shm_barrier(id &Sqlite3_file) {
	id.pMethods.xShmBarrier(id)
}

@[c:'sqlite3OsShmUnmap']
fn sqlite3_os_shm_unmap(id &Sqlite3_file, delete_flag int) int {
	return id.pMethods.xShmUnmap(id, delete_flag)
}

@[c:'sqlite3OsShmMap']
fn sqlite3_os_shm_map(id &Sqlite3_file, i_page int, pgsz int, b_extend int, pp &voidptr) int {
	return id.pMethods.xShmMap(id, i_page, pgsz, b_extend, pp)
}

@[c:'sqlite3OsFetch']
fn sqlite3_os_fetch(id &Sqlite3_file, i_off I64, i_amt int, pp &voidptr) int {
	return id.pMethods.xFetch(id, i_off, i_amt, pp)
}

@[c:'sqlite3OsUnfetch']
fn sqlite3_os_unfetch(id &Sqlite3_file, i_off I64, p voidptr) int {
	return id.pMethods.xUnfetch(id, i_off, voidptr(p))
}

@[c:'sqlite3OsOpen']
fn sqlite3_os_open(p_vfs &Sqlite3_vfs, z_path &i8, p_file &Sqlite3_file, flags int, p_flags_out &int) int {
	rc := 0
	rc = p_vfs.xOpen(p_vfs, z_path, p_file, flags & 17334143, p_flags_out)
	return rc
}

@[c:'sqlite3OsDelete']
fn sqlite3_os_delete(p_vfs &Sqlite3_vfs, z_path &i8, dir_sync int) int {
	return if !isnil(p_vfs.xDelete) { p_vfs.xDelete(p_vfs, z_path, dir_sync) } else { 0 }
}

@[c:'sqlite3OsAccess']
fn sqlite3_os_access(p_vfs &Sqlite3_vfs, z_path &i8, flags int, p_res_out &int) int {
	return p_vfs.xAccess(p_vfs, z_path, flags, p_res_out)
}

@[c:'sqlite3OsFullPathname']
fn sqlite3_os_full_pathname(p_vfs &Sqlite3_vfs, z_path &i8, n_path_out int, z_path_out &i8) int {
	z_path_out[0] = i8(0)
	return p_vfs.xFullPathname(p_vfs, z_path, n_path_out, z_path_out)
}

@[c:'sqlite3OsDlOpen']
fn sqlite3_os_dl_open(p_vfs &Sqlite3_vfs, z_path &i8) voidptr {
	return p_vfs.xDlOpen(p_vfs, z_path)
}

@[c:'sqlite3OsDlError']
fn sqlite3_os_dl_error(p_vfs &Sqlite3_vfs, n_byte int, z_buf_out &i8) {
	p_vfs.xDlError(p_vfs, n_byte, z_buf_out)
}

@[c:'sqlite3OsDlSym']
fn sqlite3_os_dl_sym(p_vfs &Sqlite3_vfs, p_hdle voidptr, z_sym &i8) C2vFn_666e202829 {
	return p_vfs.xDlSym(p_vfs, p_hdle, z_sym)
}

@[c:'sqlite3OsDlClose']
fn sqlite3_os_dl_close(p_vfs &Sqlite3_vfs, p_handle voidptr) {
	p_vfs.xDlClose(p_vfs, voidptr(p_handle))
}

@[c:'sqlite3OsRandomness']
fn sqlite3_os_randomness(p_vfs &Sqlite3_vfs, n_byte int, z_buf_out &i8) int {
	if sqlite3Config.iPrngSeed {
		C.memset(voidptr(z_buf_out), 0, u64(n_byte))
		if (n_byte > int(sizeof(u32))) {
			n_byte = int(sizeof(u32))
		}
		C.memcpy(voidptr(z_buf_out), voidptr(&sqlite3Config.iPrngSeed), u64(n_byte))
		return 0
	} else {
		return p_vfs.xRandomness(p_vfs, n_byte, z_buf_out)
	}
}

@[c:'sqlite3OsSleep']
fn sqlite3_os_sleep(p_vfs &Sqlite3_vfs, n_micro int) int {
	return p_vfs.xSleep(p_vfs, n_micro)
}

@[c:'sqlite3OsGetLastError']
fn sqlite3_os_get_last_error(p_vfs &Sqlite3_vfs) int {
	return if p_vfs.xGetLastError { p_vfs.xGetLastError(p_vfs, 0, unsafe { nil }) } else { 0 }
}

@[c:'sqlite3OsCurrentTimeInt64']
fn sqlite3_os_current_time_int64(p_vfs &Sqlite3_vfs, p_time_out &Sqlite3_int64) int {
	rc := 0
	if p_vfs.iVersion >= 2 && !isnil(p_vfs.xCurrentTimeInt64) {
		rc = p_vfs.xCurrentTimeInt64(p_vfs, p_time_out)
	} else {
		r := 0.0
		rc = p_vfs.xCurrentTime(p_vfs, &r)
		unsafe { *p_time_out = sqlite3_real_to_i64(r * 8.64E+7) }
	}
	return rc
}

@[c:'sqlite3OsOpenMalloc']
fn sqlite3_os_open_malloc(p_vfs &Sqlite3_vfs, z_file &i8, pp_file &&Sqlite3_file, flags int, p_out_flags &int) int {
	rc := 0
	p_file := &Sqlite3_file(0)
	p_file = &Sqlite3_file(sqlite3_malloc_zero(U64(p_vfs.szOsFile)))
	if p_file {
		rc = sqlite3_os_open(p_vfs, z_file, p_file, flags, p_out_flags)
		if rc != 0 {
			sqlite3_free(voidptr(p_file))
			unsafe { *pp_file = 0 }
		} else {
			unsafe { *pp_file = p_file }
		}
	} else {
		unsafe { *pp_file = 0 }
		rc = 7
	}
	return rc
}

@[c:'sqlite3OsCloseFree']
fn sqlite3_os_close_free(p_file &Sqlite3_file) {
	sqlite3_os_close(p_file)
	sqlite3_free(voidptr(p_file))
}

@[c:'sqlite3OsInit']
fn sqlite3_os_init_vdup0() int {
	p := sqlite3_malloc(10)
	if usize(p) == usize(0) {
		return 7
	}
	sqlite3_free(voidptr(p))
	return sqlite3_os_init()
}

fn sqlite3_vfs_find(z_vfs &i8) &Sqlite3_vfs {
	c2v_gc_register_thread()
	p_vfs := unsafe { &Sqlite3_vfs(nil) }
	mutex := &Sqlite3_mutex(0)
	rc := sqlite3_initialize()
	if rc {
		return unsafe { nil }
	}
	mutex = sqlite3_mutex_alloc_vdup4(2)
	sqlite3_mutex_enter(mutex)
	for p_vfs = vfsList; p_vfs; p_vfs = p_vfs.pNext {
		if usize(z_vfs) == usize(0) {
			break
		}
		if C.strcmp(z_vfs, p_vfs.zName) == 0 {
			break
		}
	}
	sqlite3_mutex_leave(mutex)
	return p_vfs
}

@[c:'vfsUnlink']
fn vfs_unlink(p_vfs &Sqlite3_vfs) {
	if usize(p_vfs) == usize(0) {
	} else if usize(vfsList) == usize(p_vfs) {
		vfsList = p_vfs.pNext
	} else if vfsList {
		p := vfsList
		for !isnil(p.pNext) && usize(p.pNext) != usize(p_vfs) {
			p = p.pNext
		}
		if usize(p.pNext) == usize(p_vfs) {
			p.pNext = p_vfs.pNext
		}
	}
}

fn sqlite3_vfs_register(p_vfs &Sqlite3_vfs, make_dflt int) int {
	c2v_gc_register_thread()
	mutex := &Sqlite3_mutex(0)
	rc := sqlite3_initialize()
	if rc {
		return rc
	}
	mutex = sqlite3_mutex_alloc_vdup4(2)
	sqlite3_mutex_enter(mutex)
	vfs_unlink(p_vfs)
	if make_dflt || usize(vfsList) == usize(0) {
		p_vfs.pNext = vfsList
		vfsList = p_vfs
	} else {
		p_vfs.pNext = vfsList.pNext
		vfsList.pNext = p_vfs
	}
	sqlite3_mutex_leave(mutex)
	return 0
}

fn sqlite3_vfs_unregister(p_vfs &Sqlite3_vfs) int {
	c2v_gc_register_thread()
	mutex := &Sqlite3_mutex(0)
	rc := sqlite3_initialize()
	if rc {
		return rc
	}
	mutex = sqlite3_mutex_alloc_vdup4(2)
	sqlite3_mutex_enter(mutex)
	vfs_unlink(p_vfs)
	sqlite3_mutex_leave(mutex)
	return 0
}
