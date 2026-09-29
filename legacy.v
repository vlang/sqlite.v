@[translated]
module main

fn sqlite3_exec(db &Sqlite3, z_sql &i8, x_callback Sqlite3_callback, p_arg voidptr, pz_err_msg &&u8) int {
	c2v_gc_register_thread()
	rc := 0
	z_leftover := &i8(0)
	p_stmt := unsafe { &Sqlite3_stmt(nil) }
	az_cols := unsafe { &&u8(nil) }
	callback_is_init := 0
	if !sqlite3_safety_check_ok(db) {
		return sqlite3_misuse_error(43)
	}
	if usize(z_sql) == usize(0) {
		z_sql = c''
	}
	sqlite3_mutex_enter(db.mutex)
	sqlite3_error(db, 0)
	for rc == 0 && int(z_sql[0]) {
		n_col := 0
		az_vals := unsafe { &&u8(nil) }
		p_stmt = 0
		rc = sqlite3_prepare_v2(db, z_sql, -1, &&Sqlite3_stmt(&&Sqlite3_stmt(c2v_address_of(&p_stmt))), &&u8(&&i8(c2v_address_of(&z_leftover))))
		if rc != 0 {
			continue
		}
		if isnil(p_stmt) {
			z_sql = z_leftover
			continue
		}
		callback_is_init = 0
		for {
			i := 0
			rc = sqlite3_step(p_stmt)
			if !isnil(x_callback) && (100 == rc || (101 == rc && !callback_is_init && db.flags & U64(256))) {
				if !callback_is_init {
					n_col = sqlite3_column_count(p_stmt)
					az_cols = sqlite3_db_malloc_raw(db, U64(u64((2 * n_col + 1)) * sizeof(voidptr)))
					if usize(az_cols) == usize(0) {
						unsafe { goto exec_out
						 }
					}
					for i = 0; i < n_col; i++ {
						az_cols[i] = &i8(sqlite3_column_name(p_stmt, i))
					}
					callback_is_init = 1
				}
				if rc == 100 {
					az_vals = unsafe { az_cols + n_col }
					for i = 0; i < n_col; i++ {
						az_vals[i] = &i8(voidptr(sqlite3_column_text(p_stmt, i)))
						if isnil(az_vals[i]) && sqlite3_column_type(p_stmt, i) != 5 {
							sqlite3_oom_fault(db)
							unsafe { goto exec_out
							 }
						}
					}
					az_vals[i] = 0
				}
				if x_callback(voidptr(p_arg), n_col, az_vals, az_cols) {
					rc = 4
					sqlite3_vdbe_finalize(&Vdbe(voidptr(p_stmt)))
					p_stmt = 0
					sqlite3_error(db, 4)
					unsafe { goto exec_out
					 }
				}
			}
			if rc != 100 {
				rc = sqlite3_vdbe_finalize(&Vdbe(voidptr(p_stmt)))
				p_stmt = 0
				z_sql = z_leftover
				for (int(sqlite3CtypeMap[u8(z_sql[0])]) & 1) {
					c2v_pointer_postfix(voidptr(&z_sql), z_sql, isize(1))
				}
				break
			}
		}
		sqlite3_db_free(db, voidptr(az_cols))
		az_cols = 0
	}
	exec_out:
	if p_stmt {
		sqlite3_vdbe_finalize(&Vdbe(voidptr(p_stmt)))
	}
	sqlite3_db_free(db, voidptr(az_cols))
	rc = sqlite3_api_exit(db, rc)
	if rc != 0 && !isnil(pz_err_msg) {
		unsafe { *pz_err_msg = sqlite3_db_str_dup(nil, sqlite3_errmsg(db)) }
		if usize((unsafe { *pz_err_msg })) == usize(0) {
			rc = 7
			sqlite3_error(db, 7)
		}
	} else if pz_err_msg {
		unsafe { *pz_err_msg = 0 }
	}
	sqlite3_mutex_leave(db.mutex)
	return rc
}
