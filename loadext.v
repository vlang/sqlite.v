@[translated]
module main

@[c:'sqlite3LoadExtension']
fn sqlite3_load_extension_vdup11(db &Sqlite3, z_file &i8, z_proc &i8, pz_err_msg &&u8) int {
	p_vfs := db.pVfs
	handle := &voidptr(0)
	x_init := unsafe { Sqlite3_loadext_entry(nil) }
	z_errmsg := unsafe { &i8(nil) }
	z_entry := &i8(0)
	z_alt_entry := unsafe { &i8(nil) }
	a_handle := &voidptr(0)
	n_msg := U64(C.strlen(z_file))
	ii := 0
	rc := 0
	if !sqlite3_load_extension_vdup11_az_endings_inited {
		c2v_static_init := [c'dylib']!
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_load_extension_vdup11_az_endings[c2v_i_0] = c2v_element_0
		}
		sqlite3_load_extension_vdup11_az_endings_inited = true
	}

	if pz_err_msg {
		unsafe { *pz_err_msg = 0 }
	}
	if (db.flags & U64(65536)) == U64(0) {
		if pz_err_msg {
			unsafe { *pz_err_msg = sqlite3_mprintf(c'not authorized') }
		}
		return 1
	}
	z_entry = if z_proc { z_proc } else { c'sqlite3_extension_init' }
	if n_msg > U64(1024) {
		unsafe { goto extension_not_found
		 }
	}
	if n_msg == U64(0) {
		unsafe { goto extension_not_found
		 }
	}
	handle = sqlite3_os_dl_open(p_vfs, z_file)
	for ii = 0; ii < 1 && usize(handle) == usize(0); ii++ {
		z_alt_file := sqlite3_mprintf(c'%s.%s', voidptr(z_file), voidptr(sqlite3_load_extension_vdup11_az_endings[ii]))
		if usize(z_alt_file) == usize(0) {
			return 7
		}
		if n_msg + U64(C.strlen(sqlite3_load_extension_vdup11_az_endings[ii])) + U64(1) <= U64(1024) {
			handle = sqlite3_os_dl_open(p_vfs, z_alt_file)
		}
		sqlite3_free(voidptr(z_alt_file))
	}
	if usize(handle) == usize(0) {
		unsafe { goto extension_not_found
		 }
	}
	x_init = C2vFn_666e20282653716c697465332c20262675382c202653716c697465335f6170695f726f7574696e65732920696e74(voidptr(sqlite3_os_dl_sym(p_vfs, handle, z_entry)))
	if isnil(x_init) && usize(z_proc) == usize(0) {
		i_file := 0
		i_entry := 0
		c := 0

		nc_file := sqlite3_strlen30(z_file)
		cnt := 0
		z_alt_entry = &i8(sqlite3_malloc64(Sqlite3_uint64(nc_file + 30)))
		if usize(z_alt_entry) == usize(0) {
			sqlite3_os_dl_close(p_vfs, voidptr(handle))
			return 7
		}
		for {
			C.memcpy(voidptr(z_alt_entry), voidptr(c'sqlite3_'), u64(8))
			for i_file = nc_file - 1; i_file >= 0 && !(int(z_file[i_file]) == i8(`/`)); i_file-- {
			}
			i_file++
			if sqlite3_strnicmp(z_file + i_file, c'lib', 3) == 0 {
				i_file += 3
			}
			for i_entry = 8; true; i_file++ {
				c = int(z_file[i_file])
				if !(c != 0 && c != `.`) {
					break
				}
				if (int(sqlite3CtypeMap[u8(c)]) & 2) || (cnt && (int(sqlite3CtypeMap[u8(c)]) & 4)) {
					z_alt_entry[i_entry++] = i8(sqlite3UpperToLower[u32(c)])
				}
			}
			C.memcpy(voidptr(z_alt_entry + i_entry), voidptr(c'_init'), u64(6))
			z_entry = z_alt_entry
			x_init = C2vFn_666e20282653716c697465332c20262675382c202653716c697465335f6170695f726f7574696e65732920696e74(voidptr(sqlite3_os_dl_sym(p_vfs, handle, z_entry)))
			if !(isnil(x_init) && (c2v_prefix_add(unsafe { &cnt }, 1)) < 2) {
				break
			}
		}
	}
	if isnil(x_init) {
		if pz_err_msg {
			n_msg += U64(C.strlen(z_entry) + u64(300))
			z_errmsg = &i8(sqlite3_malloc64(n_msg))
			unsafe { *pz_err_msg = z_errmsg }
			if z_errmsg {
				sqlite3_snprintf(int(n_msg), z_errmsg, c'no entry point [%s] in shared library [%s]', voidptr(z_entry), voidptr(z_file))
				sqlite3_os_dl_error(p_vfs, int(n_msg - U64(1)), z_errmsg)
			}
		}
		sqlite3_os_dl_close(p_vfs, voidptr(handle))
		sqlite3_free(voidptr(z_alt_entry))
		return 1
	}
	sqlite3_free(voidptr(z_alt_entry))
	rc = x_init(db, &&u8(&&i8(c2v_address_of(&z_errmsg))), &sqlite3Apis)
	if rc {
		if rc == (0 | (1 << 8)) {
			return 0
		}
		if pz_err_msg {
			unsafe { *pz_err_msg = sqlite3_mprintf(c'error during initialization: %s', voidptr(z_errmsg)) }
		}
		sqlite3_free(voidptr(z_errmsg))
		sqlite3_os_dl_close(p_vfs, voidptr(handle))
		return 1
	}
	a_handle = sqlite3_db_malloc_zero(db, U64(sizeof(handle) * u64((db.nExtension + 1))))
	if usize(a_handle) == usize(0) {
		return 7
	}
	if db.nExtension > 0 {
		C.memcpy(voidptr(a_handle), voidptr(db.aExtension), sizeof(handle) * u64(db.nExtension))
	}
	sqlite3_db_free(db, voidptr(db.aExtension))
	db.aExtension = a_handle
	db.aExtension[db.nExtension++] = handle
	return 0
	extension_not_found:
	if pz_err_msg {
		n_msg += U64(300)
		z_errmsg = &i8(sqlite3_malloc64(n_msg))
		unsafe { *pz_err_msg = z_errmsg }
		if z_errmsg {
			sqlite3_snprintf(int(n_msg), z_errmsg, c'unable to open shared library [%.*s]', 1024, voidptr(z_file))
			sqlite3_os_dl_error(p_vfs, int(n_msg - U64(1)), z_errmsg)
		}
	}
	return 1
}

fn sqlite3_load_extension(db &Sqlite3, z_file &i8, z_proc &i8, pz_err_msg &&u8) int {
	c2v_gc_register_thread()
	rc := 0
	sqlite3_mutex_enter(db.mutex)
	rc = sqlite3_load_extension_vdup11(db, z_file, z_proc, pz_err_msg)
	rc = sqlite3_api_exit(db, rc)
	sqlite3_mutex_leave(db.mutex)
	return rc
}

@[c:'sqlite3CloseExtensions']
fn sqlite3_close_extensions(db &Sqlite3) {
	i := 0
	for i = 0; i < db.nExtension; i++ {
		sqlite3_os_dl_close(db.pVfs, voidptr(db.aExtension[i]))
	}
	sqlite3_db_free(db, voidptr(db.aExtension))
}

fn sqlite3_enable_load_extension(db &Sqlite3, onoff int) int {
	sqlite3_mutex_enter(db.mutex)
	if onoff {
		db.flags |= U64(65536 | 131072)
	} else {
		db.flags &= ~U64((65536 | 131072))
	}
	sqlite3_mutex_leave(db.mutex)
	return 0
}

struct Sqlite3AutoExtList {
	nExt u32
	aExt &voidptr
}

fn sqlite3_auto_extension(x_init fn ()) int {
	c2v_gc_register_thread()
	rc := 0
	rc = sqlite3_initialize()
	if rc {
		return rc
	} else {
		i := u32(0)
		mutex := sqlite3_mutex_alloc_vdup4(2)
		sqlite3_mutex_enter(mutex)
		for i = u32(0); i < sqlite3Autoext.nExt; i++ {
			if sqlite3Autoext.aExt[i] == x_init {
				break
			}
		}
		if i == sqlite3Autoext.nExt {
			n_byte := U64(u64((sqlite3Autoext.nExt + u32(1))) * sizeof(voidptr))
			a_new := &voidptr(0)
			a_new = sqlite3_realloc64(voidptr(sqlite3Autoext.aExt), n_byte)
			if usize(a_new) == usize(0) {
				rc = 7
			} else {
				sqlite3Autoext.aExt = a_new
				sqlite3Autoext.aExt[sqlite3Autoext.nExt] = x_init
				sqlite3Autoext.nExt++
			}
		}
		sqlite3_mutex_leave(mutex)
		return rc
	}
}

fn sqlite3_cancel_auto_extension(x_init fn ()) int {
	c2v_gc_register_thread()
	mutex := sqlite3_mutex_alloc_vdup4(2)
	i := 0
	n := 0
	sqlite3_mutex_enter(mutex)
	for i = int(sqlite3Autoext.nExt) - 1; i >= 0; i-- {
		if sqlite3Autoext.aExt[i] == x_init {
			sqlite3Autoext.nExt--
			sqlite3Autoext.aExt[i] = sqlite3Autoext.aExt[sqlite3Autoext.nExt]
			n++
			break
		}
	}
	sqlite3_mutex_leave(mutex)
	return n
}

fn sqlite3_reset_auto_extension() {
	c2v_gc_register_thread()
	if sqlite3_initialize() == 0 {
		mutex := sqlite3_mutex_alloc_vdup4(2)
		sqlite3_mutex_enter(mutex)
		sqlite3_free(voidptr(sqlite3Autoext.aExt))
		sqlite3Autoext.aExt = 0
		sqlite3Autoext.nExt = u32(0)
		sqlite3_mutex_leave(mutex)
	}
}

@[c:'sqlite3AutoLoadExtensions']
fn sqlite3_auto_load_extensions(db &Sqlite3) {
	i := u32(0)
	go_ := 1
	rc := 0
	x_init := unsafe { Sqlite3_loadext_entry(nil) }
	if sqlite3Autoext.nExt == u32(0) {
		return
	}
	for i = u32(0); go_; i++ {
		z_errmsg := &i8(0)
		mutex := sqlite3_mutex_alloc_vdup4(2)
		p_thunk := &sqlite3Apis
		sqlite3_mutex_enter(mutex)
		if i >= sqlite3Autoext.nExt {
			x_init = 0
			go_ = 0
		} else {
			x_init = C2vFn_666e20282653716c697465332c20262675382c202653716c697465335f6170695f726f7574696e65732920696e74(voidptr(sqlite3Autoext.aExt[i]))
		}
		sqlite3_mutex_leave(mutex)
		z_errmsg = 0
		if !isnil(x_init) && c2v_assign[int](unsafe { &rc }, int(x_init(db, &&u8(&&i8(c2v_address_of(&z_errmsg))), p_thunk))) != 0 {
			sqlite3_error_with_msg(db, rc, c'automatic extension loading failed: %s', voidptr(z_errmsg))
			go_ = 0
		}
		sqlite3_free(voidptr(z_errmsg))
	}
}
