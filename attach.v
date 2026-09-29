@[translated]
module main

@[c:'resolveAttachExpr']
fn resolve_attach_expr(p_name &NameContext, p_expr &Expr) int {
	rc := 0
	if p_expr {
		if int(p_expr.op) != 60 {
			rc = sqlite3_resolve_expr_names(p_name, p_expr)
		} else {
			p_expr.op = U8(118)
		}
	}
	return rc
}

@[c:'sqlite3DbIsNamed']
fn sqlite3_db_is_named(db &Sqlite3, i_db int, z_name &i8) int {
	return int((sqlite3_str_ic_mp(db.aDb[i_db].zDbSName, z_name) == 0 || (i_db == 0 && sqlite3_str_ic_mp(c'main', z_name) == 0)))
}

@[c:'attachFunc']
fn attach_func(context &Sqlite3_context, not_used int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	i := 0
	rc := 0
	db := sqlite3_context_db_handle(context)
	z_name := &i8(0)
	z_file := &i8(0)
	z_path := unsafe { &i8(nil) }
	z_err := unsafe { &i8(nil) }
	flags := u32(0)
	a_new := &Db(0)
	p_new := unsafe { &Db(nil) }
	z_err_dyn := unsafe { &i8(nil) }
	p_vfs := &Sqlite3_vfs(0)

	z_file = &i8(voidptr(sqlite3_value_text(argv[0])))
	z_name = &i8(voidptr(sqlite3_value_text(argv[1])))
	if usize(z_file) == usize(0) {
		z_file = c''
	}
	if usize(z_name) == usize(0) {
		z_name = c''
	}
	if db.init.reopenMemdb {
		p_new_bt := unsafe { &Btree(nil) }
		p_new = unsafe { db.aDb + db.init.iDb }
		if sqlite3_btree_txn_state(p_new.pBt) != 0 || sqlite3_btree_is_in_backup(p_new.pBt) {
			rc = 5
			unsafe { goto attach_error
			 }
		}
		p_vfs = sqlite3_vfs_find(c'memdb')
		if usize(p_vfs) == usize(0) {
			return
		}
		rc = sqlite3_btree_open(p_vfs, c'x\000', db, &&Btree(&&Btree(c2v_address_of(&p_new_bt))), 0, 256)
		if rc == 0 {
			p_new_schema := sqlite3_schema_get(db, p_new_bt)
			if p_new_schema {
				sqlite3_btree_close(p_new.pBt)
				p_new.pBt = p_new_bt
				p_new.pSchema = p_new_schema
			} else {
				sqlite3_btree_close(p_new_bt)
				rc = 7
			}
		}
		if rc {
			unsafe { goto attach_error
			 }
		}
	} else {
		if db.nDb >= db.aLimit[7] + 2 {
			z_err_dyn = sqlite3_mp_rintf(db, c'too many attached databases - max %d', db.aLimit[7])
			unsafe { goto attach_error
			 }
		}
		for i = 0; i < db.nDb; i++ {
			if sqlite3_db_is_named(db, i, z_name) {
				z_err_dyn = sqlite3_mp_rintf(db, c'database %s is already in use', voidptr(z_name))
				unsafe { goto attach_error
				 }
			}
		}
		if usize(db.aDb) == usize(unsafe { &db.aDbStatic[0] }) {
			a_new = sqlite3_db_malloc_raw_nn(db, U64(sizeof(Db) * u64(3)))
			if usize(a_new) == usize(0) {
				return
			}
			C.memcpy(voidptr(a_new), voidptr(db.aDb), sizeof(Db) * u64(2))
		} else {
			a_new = sqlite3_db_realloc(db, voidptr(db.aDb), sizeof(Db) * u64((I64(1) + I64(db.nDb))))
			if usize(a_new) == usize(0) {
				return
			}
		}
		db.aDb = a_new
		p_new = unsafe { db.aDb + db.nDb }
		C.memset(voidptr(p_new), 0, sizeof(Db))
		flags = db.openFlags
		rc = sqlite3_parse_uri(db.pVfs.zName, z_file, &flags, &&Sqlite3_vfs(&&Sqlite3_vfs(c2v_address_of(&p_vfs))), &&u8(&&i8(c2v_address_of(&z_path))), &&u8(&&i8(c2v_address_of(&z_err))))
		if rc != 0 {
			if rc == 7 {
				sqlite3_oom_fault(db)
			}
			sqlite3_result_error(context, z_err, -1)
			sqlite3_free(voidptr(z_err))
			return
		}
		if (db.flags & (U64(32) << 32)) == U64(0) {
			flags &= u32(~(4 | 2))
			flags |= u32(1)
		} else if (db.flags & (U64(16) << 32)) == U64(0) {
			flags &= u32(~4)
		}
		flags |= u32(256)
		rc = sqlite3_btree_open(p_vfs, z_path, db, &&Btree(&p_new.pBt), 0, int(flags))
		db.nDb++
		p_new.zDbSName = sqlite3_db_str_dup(db, z_name)
	}
	db.noSharedCache = U8(0)
	if rc == 19 {
		rc = 1
		z_err_dyn = sqlite3_mp_rintf(db, c'database is already attached')
	} else if rc == 0 {
		p_pager := &Pager(0)
		p_new.pSchema = sqlite3_schema_get(db, p_new.pBt)
		if isnil(p_new.pSchema) {
			rc = 7
		} else if int(p_new.pSchema.file_format) && int(p_new.pSchema.enc) != int(db.enc) {
			z_err_dyn = sqlite3_mp_rintf(db, c'attached databases must use the same text encoding as main database')
			rc = 1
		}
		sqlite3_btree_enter(p_new.pBt)
		p_pager = sqlite3_btree_pager(p_new.pBt)
		sqlite3_pager_locking_mode(p_pager, int(db.dfltLockMode))
		sqlite3_btree_secure_delete(p_new.pBt, sqlite3_btree_secure_delete(db.aDb[0].pBt, -1))
		sqlite3_btree_set_pager_flags(p_new.pBt, u32(U64(3) | (db.flags & U64(56))))
		sqlite3_btree_leave(p_new.pBt)
	}
	p_new.safety_level = U8(2 + 1)
	if rc == 0 && usize(p_new.zDbSName) == usize(0) {
		rc = 7
	}
	sqlite3_free_filename(z_path)
	if rc == 0 {
		sqlite3_btree_enter_all(db)
		db.init.iDb = U8(0)
		db.mDbFlags &= u32(~16)
		if !db.init.reopenMemdb {
			rc = sqlite3_init(db, &&u8(&&i8(c2v_address_of(&z_err_dyn))))
		}
		sqlite3_btree_leave_all(db)
	}
	if rc {
		if (!db.init.reopenMemdb) {
			i_db := db.nDb - 1
			if db.aDb[i_db].pBt {
				sqlite3_btree_close(db.aDb[i_db].pBt)
				db.aDb[i_db].pBt = 0
				db.aDb[i_db].pSchema = 0
			}
			sqlite3_reset_all_schemas_of_connection(db)
			db.nDb = i_db
			if rc == 7 || rc == (10 | (12 << 8)) {
				sqlite3_oom_fault(db)
				sqlite3_db_free(db, voidptr(z_err_dyn))
				z_err_dyn = sqlite3_mp_rintf(db, c'out of memory')
			} else if usize(z_err_dyn) == usize(0) {
				z_err_dyn = sqlite3_mp_rintf(db, c'unable to open database: %s', voidptr(z_file))
			}
		}
		unsafe { goto attach_error
		 }
	}
	return
	attach_error:
	if z_err_dyn {
		sqlite3_result_error(context, z_err_dyn, -1)
		sqlite3_db_free(db, voidptr(z_err_dyn))
	}
	if rc {
		sqlite3_result_error_code(context, rc)
	}
}

@[c:'detachFunc']
fn detach_func(context &Sqlite3_context, not_used int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z_name := &i8(voidptr(sqlite3_value_text(argv[0])))
	db := sqlite3_context_db_handle(context)
	i := 0
	p_db := unsafe { &Db(nil) }
	p_entry := &HashElem(0)
	z_err := [128]i8{}

	if usize(z_name) == usize(0) {
		z_name = c''
	}
	for i = 0; i < db.nDb; i++ {
		p_db = unsafe { db.aDb + i }
		if usize(p_db.pBt) == usize(0) {
			continue
		}
		if sqlite3_db_is_named(db, i, z_name) {
			break
		}
	}
	if i >= db.nDb {
		sqlite3_snprintf(int(sizeof([128]i8)), unsafe { &i8(&z_err[0]) }, c'no such database: %s', voidptr(z_name))
		unsafe { goto detach_error
		 }
	}
	if i < 2 {
		sqlite3_snprintf(int(sizeof([128]i8)), unsafe { &i8(&z_err[0]) }, c'cannot detach database %s', voidptr(z_name))
		unsafe { goto detach_error
		 }
	}
	if sqlite3_btree_txn_state(p_db.pBt) != 0 || sqlite3_btree_is_in_backup(p_db.pBt) {
		sqlite3_snprintf(int(sizeof([128]i8)), unsafe { &i8(&z_err[0]) }, c'database %s is locked', voidptr(z_name))
		unsafe { goto detach_error
		 }
	}
	p_entry = db.aDb[1].pSchema.trigHash.first
	for p_entry {
		p_trig := &Trigger(p_entry.data)
		if usize(p_trig.pTabSchema) == usize(p_db.pSchema) {
			p_trig.pTabSchema = p_trig.pSchema
		}
		p_entry = p_entry.next
	}
	sqlite3_btree_close(p_db.pBt)
	p_db.pBt = 0
	p_db.pSchema = 0
	sqlite3_collapse_database_array(db)
	return
	detach_error:
	sqlite3_result_error(context, unsafe { &i8(&z_err[0]) }, -1)
}

@[c:'codeAttach']
fn code_attach(p_parse &Parse, type_ int, p_func &FuncDef, p_auth_arg &Expr, p_filename &Expr, p_dbname &Expr, p_key &Expr) {
	rc := 0
	s_name := NameContext{}
	v := &Vdbe(0)
	db := p_parse.db
	reg_args := 0
	if 0 != sqlite3_read_schema(p_parse) {
		unsafe { goto attach_end
		 }
	}
	if p_parse.nErr {
		unsafe { goto attach_end
		 }
	}
	C.memset(voidptr(&s_name), 0, sizeof(NameContext))
	s_name.pParse = p_parse
	if 0 != resolve_attach_expr(&s_name, p_filename) || 0 != resolve_attach_expr(&s_name, p_dbname) || 0 != resolve_attach_expr(&s_name, p_key) {
		unsafe { goto attach_end
		 }
	}
	if p_auth_arg {
		z_auth_arg := &i8(0)
		if int(p_auth_arg.op) == 118 {
			z_auth_arg = p_auth_arg.u.zToken
		} else {
			z_auth_arg = 0
		}
		rc = sqlite3_auth_check(p_parse, type_, z_auth_arg, unsafe { nil }, unsafe { nil })
		if rc != 0 {
			unsafe { goto attach_end
			 }
		}
	}
	v = sqlite3_get_vdbe(p_parse)
	reg_args = sqlite3_get_temp_range(p_parse, 4)
	sqlite3_expr_code(p_parse, p_filename, reg_args)
	sqlite3_expr_code(p_parse, p_dbname, reg_args + 1)
	sqlite3_expr_code(p_parse, p_key, reg_args + 2)
	if v {
		sqlite3_vdbe_add_function_call(p_parse, 0, reg_args + 3 - int(p_func.nArg), reg_args + 3, int(p_func.nArg), p_func, 0)
		sqlite3_vdbe_add_op1(v, 168, (type_ == 24))
	}
	attach_end:
	sqlite3_expr_delete(db, p_filename)
	sqlite3_expr_delete(db, p_dbname)
	sqlite3_expr_delete(db, p_key)
}

@[c:'sqlite3Detach']
fn sqlite3_detach(p_parse &Parse, p_dbname &Expr) {
	if !sqlite3_detach_detach_func_2_inited {
		sqlite3_detach_detach_func_2 = FuncDef{
			nArg: I16(1)
			funcFlags: u32(1)
			pUserData: 0
			pNext: 0
			xSFunc: detach_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sqlite_detach'
			u: FuncDef_u{}
		}

		sqlite3_detach_detach_func_2_inited = true
	}

	code_attach(p_parse, 25, &sqlite3_detach_detach_func_2, p_dbname, unsafe { nil }, unsafe { nil }, p_dbname)
}

@[c:'sqlite3Attach']
fn sqlite3_attach(p_parse &Parse, p &Expr, p_dbname &Expr, p_key &Expr) {
	if !sqlite3_attach_attach_func_2_inited {
		sqlite3_attach_attach_func_2 = FuncDef{
			nArg: I16(3)
			funcFlags: u32(1)
			pUserData: 0
			pNext: 0
			xSFunc: attach_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sqlite_attach'
			u: FuncDef_u{}
		}

		sqlite3_attach_attach_func_2_inited = true
	}

	code_attach(p_parse, 24, &sqlite3_attach_attach_func_2, p, p, p_dbname, p_key)
}

@[c:'fixExprCb']
fn fix_expr_cb(p &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	p_fix := p.u.pFix
	if !p_fix.bTemp {
		p_expr.flags |= u32(1073741824)
	}
	if int(p_expr.op) == 157 {
		if p_fix.pParse.db.init.busy {
			p_expr.op = U8(122)
		} else {
			sqlite3_error_msg(p_fix.pParse, c'%s cannot use variables', voidptr(p_fix.zType))
			return 2
		}
	}
	return 0
}

@[c:'fixSelectCb']
fn fix_select_cb(p &Walker, p_select &Select) int {
	c2v_gc_register_thread()
	p_fix := p.u.pFix
	i := 0
	p_item := &SrcItem(0)
	db := p_fix.pParse.db
	i_db := sqlite3_find_db_name(db, p_fix.zDb)
	p_list := p_select.pSrc
	if (usize(p_list) == usize(0)) {
		return 0
	}
	i = 0
	for p_item = unsafe { &p_list.a[0] }; i < p_list.nSrc; i++ {
		if int(p_fix.bTemp) == 0 && int(p_item.fg.isSubquery) == 0 {
			if int(p_item.fg.fixedSchema) == 0 && usize(p_item.u4.zDatabase) != usize(0) {
				if i_db != sqlite3_find_db_name(db, p_item.u4.zDatabase) {
					sqlite3_error_msg(p_fix.pParse, c'%s %T cannot reference objects in database %s', voidptr(p_fix.zType), voidptr(p_fix.pName), voidptr(p_item.u4.zDatabase))
					return 2
				}
				sqlite3_db_free(db, voidptr(p_item.u4.zDatabase))
				p_item.fg.notCte = u32(1)
				p_item.fg.hadSchema = u32(1)
			}
			p_item.u4.pSchema = p_fix.pSchema
			p_item.fg.fromDDL = u32(1)
			p_item.fg.fixedSchema = u32(1)
		}
		if int(c2v_at(&p_list.a[0], isize(i)).fg.isUsing) == 0 && sqlite3_walk_expr(&p_fix.w, c2v_at(&p_list.a[0], isize(i)).u3.pOn) {
			return 2
		}
		c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
	}
	if p_select.pWith {
		for i = 0; i < p_select.pWith.nCte; i++ {
			if sqlite3_walk_select(p, c2v_at(&p_select.pWith.a[0], isize(i)).pSelect) {
				return 2
			}
		}
	}
	return 0
}

@[c:'sqlite3FixInit']
fn sqlite3_fix_init(p_fix &DbFixer, p_parse &Parse, i_db int, z_type &i8, p_name &Token) {
	db := p_parse.db
	p_fix.pParse = p_parse
	p_fix.zDb = db.aDb[i_db].zDbSName
	p_fix.pSchema = db.aDb[i_db].pSchema
	p_fix.zType = z_type
	p_fix.pName = p_name
	p_fix.bTemp = U8((i_db == 1))
	p_fix.w.pParse = p_parse
	p_fix.w.xExprCallback = fix_expr_cb
	p_fix.w.xSelectCallback = fix_select_cb
	p_fix.w.xSelectCallback2 = sqlite3_walk_win_defn_dummy_callback
	p_fix.w.walkerDepth = 0
	p_fix.w.eCode = U16(0)
	p_fix.w.u.pFix = p_fix
}

@[c:'sqlite3FixSrcList']
fn sqlite3_fix_src_list(p_fix &DbFixer, p_list &SrcList) int {
	res := 0
	if p_list {
		s := Select{}
		C.memset(voidptr(&s), 0, sizeof(s))
		s.pSrc = p_list
		res = sqlite3_walk_select(&p_fix.w, &s)
	}
	return res
}

@[c:'sqlite3FixSelect']
fn sqlite3_fix_select(p_fix &DbFixer, p_select &Select) int {
	return sqlite3_walk_select(&p_fix.w, p_select)
}

@[c:'sqlite3FixExpr']
fn sqlite3_fix_expr(p_fix &DbFixer, p_expr &Expr) int {
	return sqlite3_walk_expr(&p_fix.w, p_expr)
}

@[c:'sqlite3FixTriggerStep']
fn sqlite3_fix_trigger_step(p_fix &DbFixer, p_step &TriggerStep) int {
	for p_step {
		if sqlite3_walk_select(&p_fix.w, p_step.pSelect) || sqlite3_walk_expr(&p_fix.w, p_step.pWhere) || sqlite3_walk_expr_list(&p_fix.w, p_step.pExprList) || sqlite3_fix_src_list(p_fix, p_step.pSrc) {
			return 1
		}
		p_up := &Upsert(0)
		for p_up = p_step.pUpsert; p_up; p_up = p_up.pNextUpsert {
			mut __c2v_condition_57 := false
			mut __c2v_condition_58 := false
			__c2v_condition_58 = sqlite3_walk_expr_list(&p_fix.w, p_up.pUpsertTarget)
			__c2v_condition_57 = __c2v_condition_58
			if !__c2v_condition_57 {
				mut __c2v_condition_59 := false
				__c2v_condition_59 = sqlite3_walk_expr(&p_fix.w, p_up.pUpsertTargetWhere)
				__c2v_condition_57 = __c2v_condition_59
			}
			if !__c2v_condition_57 {
				mut __c2v_condition_60 := false
				__c2v_condition_60 = sqlite3_walk_expr_list(&p_fix.w, p_up.pUpsertSet)
				__c2v_condition_57 = __c2v_condition_60
			}
			if !__c2v_condition_57 {
				mut __c2v_condition_61 := false
				__c2v_condition_61 = sqlite3_walk_expr(&p_fix.w, p_up.pUpsertWhere)
				__c2v_condition_57 = __c2v_condition_61
			}
			if __c2v_condition_57 {
				return 1
			}
		}
		p_step = p_step.pNext
	}
	return 0
}
