@[translated]
module main

@[c:'corruptSchema']
fn corrupt_schema(p_data &InitData, az_obj &&u8, z_extra &i8) {
	db := p_data.db
	if db.mallocFailed {
		p_data.rc = 7
	} else if usize(p_data.pzErrMsg[0]) != usize(0) {
	} else if p_data.mInitFlags & u32(7) {
		if !corrupt_schema_az_alter_type_inited {
			c2v_static_init := [c'rename', c'drop column', c'add column', c'drop constraint']!
			for c2v_i_0, c2v_element_0 in c2v_static_init {
				corrupt_schema_az_alter_type[c2v_i_0] = c2v_element_0
			}
			corrupt_schema_az_alter_type_inited = true
		}

		unsafe { *p_data.pzErrMsg = sqlite3_mp_rintf(db, c'error in %s %s after %s: %s', voidptr(az_obj[0]), voidptr(az_obj[1]), voidptr(corrupt_schema_az_alter_type[(p_data.mInitFlags & u32(7)) - u32(1)]), voidptr(z_extra)) }
		p_data.rc = 1
	} else if db.flags & U64(1) {
		p_data.rc = sqlite3_corrupt_error(46)
	} else {
		z := &i8(0)
		z_obj := if az_obj[1] { az_obj[1] } else { c'?' }
		z = sqlite3_mp_rintf(db, c'malformed database schema (%s)', voidptr(z_obj))
		if !isnil(z_extra) && int(z_extra[0]) {
			z = sqlite3_mp_rintf(db, c'%z - %s', voidptr(z), voidptr(z_extra))
		}
		unsafe { *p_data.pzErrMsg = z }
		p_data.rc = sqlite3_corrupt_error(53)
	}
}

@[c:'sqlite3IndexHasDuplicateRootPage']
fn sqlite3_index_has_duplicate_root_page(p_index &Index) int {
	p := &Index(0)
	for p = p_index.pTable.pIndex; p; p = p.pNext {
		if p.tnum == p_index.tnum && usize(p) != usize(p_index) {
			return 1
		}
	}
	return 0
}

@[c:'sqlite3InitCallback']
fn sqlite3_init_callback(p_init voidptr, argc int, argv &&u8, not_used &&u8) int {
	c2v_gc_register_thread()
	p_data := &InitData(p_init)
	db := p_data.db
	i_db := p_data.iDb

	db.mDbFlags |= u32(64)
	if usize(argv) == usize(0) {
		return 0
	}
	p_data.nInitRow++
	if db.mallocFailed {
		corrupt_schema(p_data, argv, unsafe { nil })
		return 1
	}
	if usize(argv[3]) == usize(0) {
		corrupt_schema(p_data, argv, unsafe { nil })
	} else if !isnil(argv[4]) && `c` == int(sqlite3UpperToLower[u8(argv[4][0])]) && `r` == int(sqlite3UpperToLower[u8(argv[4][1])]) {
		rc := 0
		saved_i_db := db.init.iDb
		p_stmt := &Sqlite3_stmt(0)
		0
		db.init.iDb = U8(i_db)
		if sqlite3_get_ui_nt32(argv[3], &db.init.newTnum) == 0 || (db.init.newTnum > p_data.mxPage && p_data.mxPage > Pgno(0)) {
			if sqlite3Config.bExtraSchemaChecks {
				corrupt_schema(p_data, argv, c'invalid rootpage')
			}
		}
		db.init.orphanTrigger = u32(0)
		db.init.azInit = &&u8(argv)
		p_stmt = 0
		sqlite3_prepare_vdup12(db, argv[4], -1, u32(0), unsafe { nil }, &&Sqlite3_stmt(&&Sqlite3_stmt(c2v_address_of(&p_stmt))), unsafe { &&u8(nil) })
		rc = db.errCode
		db.init.iDb = saved_i_db
		if 0 != rc {
			if db.init.orphanTrigger {
			} else {
				if rc > p_data.rc {
					p_data.rc = rc
				}
				if rc == 7 {
					sqlite3_oom_fault(db)
				} else if rc != 9 && (rc & 255) != 6 {
					corrupt_schema(p_data, argv, sqlite3_errmsg(db))
				}
			}
		}
		db.init.azInit = unsafe { &sqlite3StdType[0] }
		sqlite3_finalize(p_stmt)
	} else if usize(argv[1]) == usize(0) || (usize(argv[4]) != usize(0) && int(argv[4][0]) != 0) {
		corrupt_schema(p_data, argv, unsafe { nil })
	} else {
		p_index := &Index(0)
		p_index = sqlite3_find_index(db, argv[1], db.aDb[i_db].zDbSName)
		if usize(p_index) == usize(0) {
			corrupt_schema(p_data, argv, c'orphan index')
		} else if sqlite3_get_ui_nt32(argv[3], &p_index.tnum) == 0 || p_index.tnum < Pgno(2) || p_index.tnum > p_data.mxPage || sqlite3_index_has_duplicate_root_page(p_index) {
			if sqlite3Config.bExtraSchemaChecks {
				corrupt_schema(p_data, argv, c'invalid rootpage')
			}
		}
	}
	return 0
}

@[c:'sqlite3InitOne']
fn sqlite3_init_one(db &Sqlite3, i_db int, pz_err_msg &&u8, m_flags u32) int {
	rc := 0
	i := 0
	size := 0
	p_db := &Db(0)
	az_arg := [6]&i8{}
	meta := [5]int{}
	init_data := InitData{}
	z_schema_tab_name := &i8(0)
	opened_transaction := 0
	mask := int(((db.mDbFlags & u32(64)) | u32(~64)))
	db.init.busy = U8(1)
	az_arg[0] = c'table'
	z_schema_tab_name = (if (!0) && (i_db == 1) { c'sqlite_temp_master' } else { c'sqlite_master' })
	az_arg[1] = z_schema_tab_name
	az_arg[2] = az_arg[1]
	az_arg[3] = c'1'
	az_arg[4] = c'CREATE TABLE x(type text,name text,tbl_name text,rootpage int,sql text)'
	az_arg[5] = 0
	init_data.db = db
	init_data.iDb = i_db
	init_data.rc = 0
	init_data.pzErrMsg = pz_err_msg
	init_data.mInitFlags = m_flags
	init_data.nInitRow = u32(0)
	init_data.mxPage = Pgno(0)
	sqlite3_init_callback(voidptr(&init_data), 5, &&u8(unsafe { &az_arg[0] }), unsafe { &&u8(nil) })
	db.mDbFlags &= u32(mask)
	if init_data.rc {
		rc = init_data.rc
		unsafe { goto error_out
		 }
	}
	p_db = unsafe { db.aDb + i_db }
	if usize(p_db.pBt) == usize(0) {
		db.aDb[1].pSchema.schemaFlags |= 1
		rc = 0
		unsafe { goto error_out
		 }
	}
	sqlite3_btree_enter(p_db.pBt)
	if sqlite3_btree_txn_state(p_db.pBt) == 0 {
		rc = sqlite3_btree_begin_trans(p_db.pBt, 0, unsafe { nil })
		if rc != 0 {
			sqlite3_set_string(pz_err_msg, db, sqlite3_err_str(rc))
			unsafe { goto initone_error_out
			 }
		}
		opened_transaction = 1
	}
	for i = 0; i < 5; i++ {
		sqlite3_btree_get_meta(p_db.pBt, i + 1, &u32(voidptr(unsafe { &meta[0] + i })))
	}
	if (db.flags & U64(33554432)) != U64(0) {
		C.memset(voidptr(unsafe { &meta[0] }), 0, sizeof([5]int))
	}
	p_db.pSchema.schema_cookie = meta[1 - 1]
	if meta[5 - 1] {
		if i_db == 0 && (db.mDbFlags & u32(64)) == u32(0) {
			encoding := U8(0)
			encoding = U8(int(U8(meta[5 - 1])) & 3)
			if int(encoding) == 0 {
				encoding = U8(1)
			}
			sqlite3_set_text_encoding(db, encoding)
		} else {
			if (meta[5 - 1] & 3) != int(db.enc) {
				sqlite3_set_string(pz_err_msg, db, c'attached databases must use the same text encoding as main database')
				rc = 1
				unsafe { goto initone_error_out
				 }
			}
		}
	}
	p_db.pSchema.enc = db.enc
	if p_db.pSchema.cache_size == 0 {
		size = sqlite3_abs_int32(meta[3 - 1])
		if size == 0 {
			size = -2000
		}
		p_db.pSchema.cache_size = size
		sqlite3_btree_set_cache_size(p_db.pBt, p_db.pSchema.cache_size)
	}
	p_db.pSchema.file_format = U8(meta[2 - 1])
	if int(p_db.pSchema.file_format) == 0 {
		p_db.pSchema.file_format = U8(1)
	}
	if int(p_db.pSchema.file_format) > 4 {
		sqlite3_set_string(pz_err_msg, db, c'unsupported file format')
		rc = 1
		unsafe { goto initone_error_out
		 }
	}
	if i_db == 0 && meta[2 - 1] >= 4 {
		db.flags &= ~U64(2)
	}
	init_data.mxPage = sqlite3_btree_last_page(p_db.pBt)
	z_sql := &i8(0)
	z_sql = sqlite3_mp_rintf(db, c'SELECT*FROM"%w".%s ORDER BY rowid', voidptr(db.aDb[i_db].zDbSName), voidptr(z_schema_tab_name))
	x_auth := unsafe { Sqlite3_xauth(nil) }
	x_auth = db.xAuth
	db.xAuth = 0
	rc = sqlite3_exec(db, z_sql, sqlite3_init_callback, voidptr(&init_data), unsafe { &&u8(nil) })
	db.xAuth = x_auth
	if rc == 0 {
		rc = init_data.rc
	}
	sqlite3_db_free(db, voidptr(z_sql))
	if rc == 0 {
		sqlite3_analysis_load(db, i_db)
	}
	if db.mallocFailed {
		rc = 7
		sqlite3_reset_all_schemas_of_connection(db)
		p_db = unsafe { db.aDb + i_db }
	} else if rc == 0 || ((db.flags & U64(134217728)) && rc != 7) {
		db.aDb[i_db].pSchema.schemaFlags |= 1
		rc = 0
	}
	initone_error_out:
	if opened_transaction {
		sqlite3_btree_commit(p_db.pBt)
	}
	sqlite3_btree_leave(p_db.pBt)
	error_out:
	if rc {
		if rc == 7 || rc == (10 | (12 << 8)) {
			sqlite3_oom_fault(db)
		}
		sqlite3_reset_one_schema(db, i_db)
	}
	db.init.busy = U8(0)
	return rc
}

@[c:'sqlite3Init']
fn sqlite3_init(db &Sqlite3, pz_err_msg &&u8) int {
	i := 0
	rc := 0

	commit_internal := int(!(db.mDbFlags & u32(1)))
	db.enc = db.aDb[0].pSchema.enc
	if !((int(db.aDb[0].pSchema.schemaFlags) & 1) == 1) {
		rc = sqlite3_init_one(db, 0, pz_err_msg, u32(0))
		if rc {
			return rc
		}
	}
	for i = db.nDb - 1; i > 0; i-- {
		if !((int(db.aDb[i].pSchema.schemaFlags) & 1) == 1) {
			rc = sqlite3_init_one(db, i, pz_err_msg, u32(0))
			if rc {
				return rc
			}
		}
	}
	if commit_internal {
		sqlite3_commit_internal_changes(db)
	}
	return 0
}

@[c:'sqlite3ReadSchema']
fn sqlite3_read_schema(p_parse &Parse) int {
	rc := 0
	db := p_parse.db
	if !db.init.busy {
		rc = sqlite3_init(db, &&u8(&p_parse.zErrMsg))
		if rc != 0 {
			p_parse.rc = rc
			p_parse.nErr++
		} else if db.noSharedCache {
			db.mDbFlags |= u32(16)
		}
	}
	return rc
}

@[c:'schemaIsValid']
fn schema_is_valid(p_parse &Parse) {
	db := p_parse.db
	i_db := 0
	rc := 0
	cookie := 0
	for i_db = 0; i_db < db.nDb; i_db++ {
		opened_transaction := 0
		p_bt := db.aDb[i_db].pBt
		if usize(p_bt) == usize(0) {
			continue
		}
		if sqlite3_btree_txn_state(p_bt) == 0 {
			rc = sqlite3_btree_begin_trans(p_bt, 0, unsafe { nil })
			if rc == 7 || rc == (10 | (12 << 8)) {
				sqlite3_oom_fault(db)
				p_parse.rc = 7
			}
			if rc != 0 {
				return
			}
			opened_transaction = 1
		}
		sqlite3_btree_get_meta(p_bt, 1, &u32(c2v_address_of(&cookie)))
		if cookie != db.aDb[i_db].pSchema.schema_cookie {
			if ((int(db.aDb[i_db].pSchema.schemaFlags) & 1) == 1) {
				p_parse.rc = 17
			}
			sqlite3_reset_one_schema(db, i_db)
		}
		if opened_transaction {
			sqlite3_btree_commit(p_bt)
		}
	}
}

@[c:'sqlite3SchemaToIndex']
fn sqlite3_schema_to_index(db &Sqlite3, p_schema &Schema) int {
	i := -32768
	if p_schema {
		for i = 0; 1; i++ {
			if usize(db.aDb[i].pSchema) == usize(p_schema) {
				break
			}
		}
	}
	return i
}

@[c:'sqlite3ParseObjectReset']
fn sqlite3_parse_object_reset(p_parse &Parse) {
	db := p_parse.db
	if p_parse.aTableLock {
		sqlite3_db_nn_free_nn(db, voidptr(p_parse.aTableLock))
	}
	for p_parse.pCleanup {
		p_cleanup := p_parse.pCleanup
		p_parse.pCleanup = p_cleanup.pNext
		p_cleanup.xCleanup(db, voidptr(p_cleanup.pPtr))
		sqlite3_db_nn_free_nn(db, voidptr(p_cleanup))
	}
	if p_parse.aLabel {
		sqlite3_db_nn_free_nn(db, voidptr(p_parse.aLabel))
	}
	if p_parse.pConstExpr {
		sqlite3_expr_list_delete(db, p_parse.pConstExpr)
	}
	db.lookaside.bDisable -= u32(p_parse.disableLookaside)
	db.lookaside.sz = U16(if db.lookaside.bDisable { 0 } else { int(db.lookaside.szTrue) })
	db.pParse = p_parse.pOuterParse
}

@[c:'sqlite3ParserAddCleanup']
fn sqlite3_parser_add_cleanup(p_parse &Parse, x_cleanup fn (&Sqlite3, voidptr), p_ptr voidptr) voidptr {
	p_cleanup := &ParseCleanup(0)
	if sqlite3_fault_sim(300) {
		p_cleanup = 0
		sqlite3_oom_fault(p_parse.db)
	} else {
		p_cleanup = sqlite3_db_malloc_raw(p_parse.db, U64(sizeof(ParseCleanup)))
	}
	if p_cleanup {
		p_cleanup.pNext = p_parse.pCleanup
		p_parse.pCleanup = p_cleanup
		p_cleanup.pPtr = p_ptr
		p_cleanup.xCleanup = x_cleanup
	} else {
		x_cleanup(p_parse.db, voidptr(p_ptr))
		p_ptr = 0
	}
	return p_ptr
}

@[c:'sqlite3ParseObjectInit']
fn sqlite3_parse_object_init(p_parse &Parse, db &Sqlite3) {
	C.memset(voidptr(((&i8(voidptr(p_parse))) + (u64(usize(__offsetof(Parse, zErrMsg)))))), 0, ((u64(usize(__offsetof(Parse, aTempReg)))) - (u64(usize(__offsetof(Parse, zErrMsg))))))
	C.memset(voidptr(((&i8(voidptr(p_parse))) + (u64(usize(__offsetof(Parse, sLastToken)))))), 0, (sizeof(Parse) - (u64(usize(__offsetof(Parse, sLastToken))))))
	p_parse.pOuterParse = db.pParse
	db.pParse = p_parse
	p_parse.db = db
	if db.mallocFailed {
		sqlite3_error_msg(p_parse, c'out of memory')
	}
}

@[c:'sqlite3Prepare']
fn sqlite3_prepare_vdup12(db &Sqlite3, z_sql &i8, n_bytes int, prep_flags u32, p_reprepare &Vdbe, pp_stmt &&Sqlite3_stmt, pz_tail &&u8) int {
	rc := 0
	i := 0
	s_parse := Parse{}
	C.memset(voidptr(((&i8(c2v_address_of(&s_parse))) + (u64(usize(__offsetof(Parse, zErrMsg)))))), 0, ((u64(usize(__offsetof(Parse, aTempReg)))) - (u64(usize(__offsetof(Parse, zErrMsg))))))
	C.memset(voidptr(((&i8(c2v_address_of(&s_parse))) + (u64(usize(__offsetof(Parse, sLastToken)))))), 0, (sizeof(Parse) - (u64(usize(__offsetof(Parse, sLastToken))))))
	s_parse.pOuterParse = db.pParse
	db.pParse = &s_parse
	s_parse.db = db
	if p_reprepare {
		s_parse.pReprepare = p_reprepare
		s_parse.explain = U8(sqlite3_stmt_isexplain(&Sqlite3_stmt(voidptr(p_reprepare))))
	} else {
	}
	if db.mallocFailed {
		sqlite3_error_msg(&s_parse, c'out of memory')
		rc = 7
		db.errCode = rc
		unsafe { goto end_prepare
		 }
	}
	if prep_flags & u32(1) {
		s_parse.disableLookaside++
		db.lookaside.bDisable++
		db.lookaside.sz = U16(0)
	}
	s_parse.prepFlags = U8(prep_flags & u32(255))
	if !db.noSharedCache {
		for i = 0; i < db.nDb; i++ {
			p_bt := db.aDb[i].pBt
			if p_bt {
				rc = sqlite3_btree_schema_locked(p_bt)
				if rc {
					z_db := db.aDb[i].zDbSName
					sqlite3_error_with_msg(db, rc, c'database schema is locked: %s', voidptr(z_db))
					0
					unsafe { goto end_prepare
					 }
				}
			}
		}
	}
	if db.pDisconnect {
		sqlite3_vtab_unlock_list(db)
	}
	if n_bytes >= 0 && (n_bytes == 0 || int(z_sql[n_bytes - 1]) != 0) {
		z_sql_copy := &i8(0)
		mx_len := db.aLimit[1]
		0
		0
		if n_bytes > mx_len {
			sqlite3_error_with_msg(db, 18, c'statement too long')
			rc = sqlite3_api_exit(db, 18)
			unsafe { goto end_prepare
			 }
		}
		z_sql_copy = sqlite3_db_str_nd_up(db, z_sql, U64(n_bytes))
		if z_sql_copy {
			sqlite3_run_parser(&s_parse, z_sql_copy)
			s_parse.zTail = unsafe { z_sql + (i64((isize(s_parse.zTail) - isize(z_sql_copy)) / isize(sizeof(i8)))) }
			sqlite3_db_free(db, voidptr(z_sql_copy))
		} else {
			s_parse.zTail = unsafe { z_sql + n_bytes }
		}
	} else {
		sqlite3_run_parser(&s_parse, z_sql)
	}
	if pz_tail {
		unsafe { *pz_tail = s_parse.zTail }
	}
	if int(db.init.busy) == 0 {
		sqlite3_vdbe_set_sql(s_parse.pVdbe, z_sql, int((i64((isize(s_parse.zTail) - isize(z_sql)) / isize(sizeof(i8))))), U8(prep_flags))
	}
	if db.mallocFailed {
		s_parse.rc = 7
		s_parse.checkSchema = Bft(0)
	}
	if s_parse.rc != 0 && s_parse.rc != 101 {
		if int(s_parse.checkSchema) && int(db.init.busy) == 0 {
			schema_is_valid(&s_parse)
		}
		if s_parse.pVdbe {
			sqlite3_vdbe_finalize(s_parse.pVdbe)
		}
		rc = s_parse.rc
		if s_parse.zErrMsg {
			sqlite3_error_with_msg(db, rc, c'%s', voidptr(s_parse.zErrMsg))
			sqlite3_db_free(db, voidptr(s_parse.zErrMsg))
		} else {
			sqlite3_error(db, rc)
		}
	} else {
		unsafe { *pp_stmt = &Sqlite3_stmt(voidptr(s_parse.pVdbe)) }
		rc = 0
		sqlite3_error_clear(db)
	}
	for s_parse.pTriggerPrg {
		pt := s_parse.pTriggerPrg
		s_parse.pTriggerPrg = pt.pNext
		sqlite3_db_free(db, voidptr(pt))
	}
	end_prepare:
	sqlite3_parse_object_reset(&s_parse)
	return rc
}

@[c:'sqlite3LockAndPrepare']
fn sqlite3_lock_and_prepare(db &Sqlite3, z_sql &i8, n_bytes int, prep_flags u32, p_old &Vdbe, pp_stmt &&Sqlite3_stmt, pz_tail &&u8) int {
	rc := 0
	cnt := 0
	unsafe { *pp_stmt = 0 }
	if !sqlite3_safety_check_ok(db) || usize(z_sql) == usize(0) {
		return sqlite3_misuse_error(853)
	}
	sqlite3_mutex_enter(db.mutex)
	sqlite3_btree_enter_all(db)
	for {
		rc = sqlite3_prepare_vdup12(db, z_sql, n_bytes, prep_flags, p_old, pp_stmt, pz_tail)
		if rc == 0 || int(db.mallocFailed) {
			break
		}
		cnt++
		if !((rc == (1 | (2 << 8)) && (cnt <= 25)) || (rc == 17 && (if true {
			sqlite3_reset_one_schema(db, -1)
			cnt
		} else {
			0
		}) == 1)) {
			break
		}
	}
	sqlite3_btree_leave_all(db)
	rc = sqlite3_api_exit(db, rc)
	db.busyHandler.nBusy = 0
	sqlite3_mutex_leave(db.mutex)
	return rc
}

@[c:'sqlite3Reprepare']
fn sqlite3_reprepare(p &Vdbe) int {
	rc := 0
	p_new := &Sqlite3_stmt(0)
	z_sql := &i8(0)
	db := &Sqlite3(0)
	prep_flags := U8(0)
	z_sql = sqlite3_sql(&Sqlite3_stmt(voidptr(p)))
	db = sqlite3_vdbe_db(p)
	prep_flags = sqlite3_vdbe_prepare_flags(p)
	rc = sqlite3_lock_and_prepare(db, z_sql, -1, u32(prep_flags), p, &&Sqlite3_stmt(&&Sqlite3_stmt(c2v_address_of(&p_new))), unsafe { &&u8(nil) })
	if rc {
		if rc == 7 {
			sqlite3_oom_fault(db)
		}
		return rc
	} else {
	}
	sqlite3_vdbe_swap(&Vdbe(voidptr(p_new)), p)
	sqlite3_transfer_bindings_vdup8(p_new, &Sqlite3_stmt(voidptr(p)))
	sqlite3_vdbe_reset_step_result(&Vdbe(voidptr(p_new)))
	sqlite3_vdbe_finalize(&Vdbe(voidptr(p_new)))
	return 0
}

fn sqlite3_prepare(db &Sqlite3, z_sql &i8, n_bytes int, pp_stmt &&Sqlite3_stmt, pz_tail &&u8) int {
	c2v_gc_register_thread()
	rc := 0
	rc = sqlite3_lock_and_prepare(db, z_sql, n_bytes, u32(0), unsafe { nil }, pp_stmt, pz_tail)
	return rc
}

fn sqlite3_prepare_v2(db &Sqlite3, z_sql &i8, n_bytes int, pp_stmt &&Sqlite3_stmt, pz_tail &&u8) int {
	c2v_gc_register_thread()
	rc := 0
	rc = sqlite3_lock_and_prepare(db, z_sql, n_bytes, u32(128), unsafe { nil }, pp_stmt, pz_tail)
	return rc
}

fn sqlite3_prepare_v3(db &Sqlite3, z_sql &i8, n_bytes int, prep_flags u32, pp_stmt &&Sqlite3_stmt, pz_tail &&u8) int {
	c2v_gc_register_thread()
	rc := 0
	rc = sqlite3_lock_and_prepare(db, z_sql, n_bytes, u32(128) | (prep_flags & u32(63)), unsafe { nil }, pp_stmt, pz_tail)
	return rc
}

@[c:'sqlite3Prepare16']
fn sqlite3_prepare16_vdup13(db &Sqlite3, z_sql voidptr, n_bytes int, prep_flags u32, pp_stmt &&Sqlite3_stmt, pz_tail &voidptr) int {
	z_sql8 := &i8(0)
	z_tail8 := unsafe { &i8(nil) }
	rc := 0
	unsafe { *pp_stmt = 0 }
	if !sqlite3_safety_check_ok(db) || usize(z_sql) == usize(0) {
		return sqlite3_misuse_error(1004)
	}
	if n_bytes >= 0 {
		sz := 0
		z := &i8(z_sql)
		for sz = 0; sz < n_bytes && (int(z[sz]) != 0 || int(z[sz + 1]) != 0); sz += 2 {
		}
		n_bytes = sz
	} else {
		sz := 0
		z := &i8(z_sql)
		for sz = 0; int(z[sz]) != 0 || int(z[sz + 1]) != 0; sz += 2 {
		}
		n_bytes = sz
	}
	sqlite3_mutex_enter(db.mutex)
	z_sql8 = sqlite3_utf16to8(db, voidptr(z_sql), n_bytes, U8(2))
	if z_sql8 {
		rc = sqlite3_lock_and_prepare(db, z_sql8, -1, prep_flags, unsafe { nil }, pp_stmt, &&u8(&&i8(c2v_address_of(&z_tail8))))
	}
	if !isnil(z_tail8) && !isnil(pz_tail) {
		chars_parsed := sqlite3_utf8_char_len(z_sql8, int((i64((isize(z_tail8) - isize(z_sql8)) / isize(sizeof(i8))))))
		unsafe { *pz_tail = &U8(z_sql) + sqlite3_utf16_byte_len(voidptr(z_sql), n_bytes, chars_parsed) }
	}
	sqlite3_db_free(db, voidptr(z_sql8))
	rc = sqlite3_api_exit(db, rc)
	sqlite3_mutex_leave(db.mutex)
	return rc
}

fn sqlite3_prepare16(db &Sqlite3, z_sql voidptr, n_bytes int, pp_stmt &&Sqlite3_stmt, pz_tail &voidptr) int {
	c2v_gc_register_thread()
	rc := 0
	rc = sqlite3_prepare16_vdup13(db, voidptr(z_sql), n_bytes, u32(0), pp_stmt, pz_tail)
	return rc
}

fn sqlite3_prepare16_v2(db &Sqlite3, z_sql voidptr, n_bytes int, pp_stmt &&Sqlite3_stmt, pz_tail &voidptr) int {
	c2v_gc_register_thread()
	rc := 0
	rc = sqlite3_prepare16_vdup13(db, voidptr(z_sql), n_bytes, u32(128), pp_stmt, pz_tail)
	return rc
}

fn sqlite3_prepare16_v3(db &Sqlite3, z_sql voidptr, n_bytes int, prep_flags u32, pp_stmt &&Sqlite3_stmt, pz_tail &voidptr) int {
	c2v_gc_register_thread()
	rc := 0
	rc = sqlite3_prepare16_vdup13(db, voidptr(z_sql), n_bytes, u32(128) | (prep_flags & u32(63)), pp_stmt, pz_tail)
	return rc
}
