@[translated]
module main

@[c:'execSql']
fn exec_sql(db &Sqlite3, pz_err_msg &&u8, z_sql &i8) int {
	p_stmt := &Sqlite3_stmt(0)
	rc := 0
	rc = sqlite3_prepare_v2(db, z_sql, -1, &&Sqlite3_stmt(&&Sqlite3_stmt(c2v_address_of(&p_stmt))), unsafe { &&u8(nil) })
	if rc != 0 {
		return rc
	}
	for {
		rc = sqlite3_step(p_stmt)
		if !(100 == rc) {
			break
		}
		z_sub_sql := &i8(voidptr(sqlite3_column_text(p_stmt, 0)))
		if !isnil(z_sub_sql) && (C.strncmp(z_sub_sql, c'CRE', u64(3)) == 0 || C.strncmp(z_sub_sql, c'INS', u64(3)) == 0) {
			rc = exec_sql(db, pz_err_msg, z_sub_sql)
			if rc != 0 {
				break
			}
		}
	}
	if rc == 101 {
		rc = 0
	}
	if rc {
		sqlite3_set_string(pz_err_msg, db, sqlite3_errmsg(db))
	}
	sqlite3_finalize(p_stmt)
	return rc
}

@[c:'execSqlF']
@[c2v_variadic]
fn exec_sql_f(db &Sqlite3, pz_err_msg &&u8, z_sql &i8, ...) int {
	z := &i8(0)
	ap := C.va_list{}
	rc := 0
	C.va_start(ap, z_sql)
	z = sqlite3_vm_printf(db, z_sql, ap)
	C.va_end(ap)
	if usize(z) == usize(0) {
		return 7
	}
	rc = exec_sql(db, pz_err_msg, z)
	sqlite3_db_free(db, voidptr(z))
	return rc
}

@[c:'sqlite3Vacuum']
fn sqlite3_vacuum(p_parse &Parse, p_nm_param &Token, p_into &Expr) {
	mut p_nm := p_nm_param
	v := sqlite3_get_vdbe(p_parse)
	i_db := 0
	if usize(v) == usize(0) {
		unsafe { goto build_vacuum_end
		 }
	}
	if p_parse.nErr {
		unsafe { goto build_vacuum_end
		 }
	}
	if p_nm {
		i_db = sqlite3_two_part_name(p_parse, p_nm, p_nm, &&Token(&&Token(c2v_address_of(&p_nm))))
		if i_db < 0 {
			unsafe { goto build_vacuum_end
			 }
		}
	}
	if i_db != 1 {
		i_into_reg := 0
		if !isnil(p_into) && sqlite3_resolve_self_reference(p_parse, unsafe { nil }, 0, p_into, unsafe { nil }) == 0 {
			i_into_reg = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			sqlite3_expr_code(p_parse, p_into, i_into_reg)
		}
		sqlite3_vdbe_add_op2(v, 5, i_db, i_into_reg)
		sqlite3_vdbe_uses_btree(v, i_db)
	}
	build_vacuum_end:
	sqlite3_expr_delete(p_parse.db, p_into)
	return
}

@[c:'sqlite3RunVacuum']
fn sqlite3_run_vacuum(pz_err_msg &&u8, db &Sqlite3, i_db int, p_out &Sqlite3_value) int {
	rc := 0
	p_main := &Btree(0)
	p_temp := &Btree(0)
	saved_m_db_flags := u32(0)
	saved_flags := U64(0)
	saved_n_change := I64(0)
	saved_n_total_change := I64(0)
	saved_open_flags := u32(0)
	saved_m_trace := U8(0)
	p_db := unsafe { &Db(nil) }
	is_mem_db := 0
	n_res := 0
	n_db := 0
	z_db_main := &i8(0)
	z_out := &i8(0)
	pgflags := u32(1)
	i_random := U64(0)
	z_db_vacuum := [42]i8{}
	if !db.autoCommit {
		sqlite3_set_string(pz_err_msg, db, c'cannot VACUUM from within a transaction')
		return 1
	}
	if db.nVdbeActive > 1 {
		sqlite3_set_string(pz_err_msg, db, c'cannot VACUUM - SQL statements in progress')
		return 1
	}
	saved_open_flags = db.openFlags
	if p_out {
		if sqlite3_value_type(p_out) != 3 {
			sqlite3_set_string(pz_err_msg, db, c'non-text filename')
			return 1
		}
		z_out = &i8(voidptr(sqlite3_value_text(p_out)))
		db.openFlags &= u32(~1)
		db.openFlags |= u32(4 | 2)
	} else {
		z_out = c''
	}
	saved_flags = db.flags
	saved_m_db_flags = db.mDbFlags
	saved_n_change = db.nChange
	saved_n_total_change = db.nTotalChange
	saved_m_trace = db.mTrace
	db.flags |= U64(1 | 512) | (U64(64) << 32) | (U64(16) << 32) | (U64(32) << 32)
	db.mDbFlags |= u32(2 | 4)
	db.flags &= ~U64((U64(16384 | 4096 | 268435456) | (U64(1) << 32)))
	db.mTrace = U8(0)
	z_db_main = db.aDb[i_db].zDbSName
	p_main = db.aDb[i_db].pBt
	is_mem_db = sqlite3_pager_is_memdb(sqlite3_btree_pager(p_main))
	sqlite3_randomness(int(sizeof(i_random)), voidptr(&i_random))
	sqlite3_snprintf(int(sizeof([42]i8)), unsafe { &i8(&z_db_vacuum[0]) }, c'vacuum_%016llx', i_random)
	n_db = db.nDb
	rc = exec_sql_f(db, pz_err_msg, c'ATTACH %Q AS %s', voidptr(z_out), voidptr(&z_db_vacuum[0]))
	db.openFlags = saved_open_flags
	if rc != 0 {
		unsafe { goto end_of_vacuum
		 }
	}
	p_db = unsafe { db.aDb + n_db }
	p_temp = p_db.pBt
	n_res = sqlite3_btree_get_requested_reserve(p_main)
	if p_out {
		id := sqlite3_pager_file(sqlite3_btree_pager(p_temp))
		sz := I64(0)
		z_filename := &i8(0)
		if usize(id.pMethods) != usize(0) && (sqlite3_os_file_size(id, &sz) != 0 || sz > I64(0)) {
			rc = 1
			sqlite3_set_string(pz_err_msg, db, c'output file already exists')
			unsafe { goto end_of_vacuum
			 }
		}
		db.mDbFlags |= u32(8)
		pgflags = u32(U64(db.aDb[i_db].safety_level) | (db.flags & U64(56)))
		z_filename = sqlite3_btree_get_filename(p_temp)
		if z_filename {
			n_new := int(sqlite3_uri_int64(z_filename, c'reserve', Sqlite3_int64(n_res)))
			if n_new >= 0 && n_new <= 255 {
				n_res = n_new
			}
		}
	}
	sqlite3_btree_set_cache_size(p_temp, db.aDb[i_db].pSchema.cache_size)
	sqlite3_btree_set_spill_size(p_temp, sqlite3_btree_set_spill_size(p_main, 0))
	sqlite3_btree_set_pager_flags(p_temp, pgflags | u32(32))
	rc = exec_sql(db, pz_err_msg, c'BEGIN')
	if rc != 0 {
		unsafe { goto end_of_vacuum
		 }
	}
	rc = sqlite3_btree_begin_trans(p_main, if usize(p_out) == usize(0) { 2 } else { 0 }, unsafe { nil })
	if rc != 0 {
		unsafe { goto end_of_vacuum
		 }
	}
	if sqlite3_pager_get_journal_mode(sqlite3_btree_pager(p_main)) == 5 && usize(p_out) == usize(0) {
		db.nextPagesize = 0
	}
	if sqlite3_btree_set_page_size(p_temp, sqlite3_btree_get_page_size(p_main), n_res, 0) || (!is_mem_db && sqlite3_btree_set_page_size(p_temp, db.nextPagesize, n_res, 0)) || int(db.mallocFailed) {
		rc = 7
		unsafe { goto end_of_vacuum
		 }
	}
	sqlite3_btree_set_auto_vacuum(p_temp, if int(db.nextAutovac) >= 0 {
		int(db.nextAutovac)
	} else {
		sqlite3_btree_get_auto_vacuum(p_main)
	})
	db.init.iDb = U8(n_db)
	rc = exec_sql_f(db, pz_err_msg, c'SELECT sql FROM "%w".sqlite_schema WHERE type=\'table\'AND name<>\'sqlite_sequence\' AND coalesce(rootpage,1)>0', voidptr(z_db_main))
	if rc != 0 {
		unsafe { goto end_of_vacuum
		 }
	}
	rc = exec_sql_f(db, pz_err_msg, c'SELECT sql FROM "%w".sqlite_schema WHERE type=\'index\'', voidptr(z_db_main))
	if rc != 0 {
		unsafe { goto end_of_vacuum
		 }
	}
	db.init.iDb = U8(0)
	rc = exec_sql_f(db, pz_err_msg, c'SELECT\'INSERT INTO %s.\'||quote(name)||\' SELECT*FROM"%w".\'||quote(name)FROM %s.sqlite_schema WHERE type=\'table\'AND coalesce(rootpage,1)>0', voidptr(&z_db_vacuum[0]), voidptr(z_db_main), voidptr(&z_db_vacuum[0]))
	db.mDbFlags &= u32(~4)
	if rc != 0 {
		unsafe { goto end_of_vacuum
		 }
	}
	rc = exec_sql_f(db, pz_err_msg, c'INSERT INTO %s.sqlite_schema SELECT*FROM "%w".sqlite_schema WHERE type IN(\'view\',\'trigger\') OR(type=\'table\'AND rootpage=0)', voidptr(&z_db_vacuum[0]), voidptr(z_db_main))
	if rc {
		unsafe { goto end_of_vacuum
		 }
	}
	meta := u32(0)
	i := 0
	if !sqlite3_run_vacuum_a_copy_inited {
		c2v_static_init := [u8(1), u8(1), u8(3), u8(0), u8(5), u8(0), u8(6), u8(0), u8(8), u8(0)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_run_vacuum_a_copy[c2v_i_0] = c2v_element_0
		}
		sqlite3_run_vacuum_a_copy_inited = true
	}

	for i = 0; i < 10; i += 2 {
		sqlite3_btree_get_meta(p_main, int(sqlite3_run_vacuum_a_copy[i]), &meta)
		rc = sqlite3_btree_update_meta(p_temp, int(sqlite3_run_vacuum_a_copy[i]), meta + u32(sqlite3_run_vacuum_a_copy[i + 1]))
		if (rc != 0) {
			unsafe { goto end_of_vacuum
			 }
		}
	}
	if usize(p_out) == usize(0) {
		rc = sqlite3_btree_copy_file(p_main, p_temp)
	}
	if rc != 0 {
		unsafe { goto end_of_vacuum
		 }
	}
	rc = sqlite3_btree_commit(p_temp)
	if rc != 0 {
		unsafe { goto end_of_vacuum
		 }
	}
	if usize(p_out) == usize(0) {
		sqlite3_btree_set_auto_vacuum(p_main, sqlite3_btree_get_auto_vacuum(p_temp))
	}
	if usize(p_out) == usize(0) {
		n_res = sqlite3_btree_get_requested_reserve(p_temp)
		rc = sqlite3_btree_set_page_size(p_main, sqlite3_btree_get_page_size(p_temp), n_res, 1)
	}
	end_of_vacuum:
	db.init.iDb = U8(0)
	db.mDbFlags = saved_m_db_flags
	db.flags = saved_flags
	db.nChange = saved_n_change
	db.nTotalChange = saved_n_total_change
	db.mTrace = saved_m_trace
	sqlite3_btree_set_page_size(p_main, -1, 0, 1)
	db.autoCommit = U8(1)
	if p_db {
		sqlite3_btree_close(p_db.pBt)
		p_db.pBt = 0
		p_db.pSchema = 0
	}
	sqlite3_reset_all_schemas_of_connection(db)
	return rc
}
