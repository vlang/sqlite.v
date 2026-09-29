@[translated]
module main

struct TableLock {
	iDb         int
	iTab        Pgno
	isWriteLock U8
	zLockName   &i8
}

@[c:'lockTable']
fn lock_table(p_parse &Parse, i_db int, i_tab Pgno, is_write_lock U8, z_name &i8) {
	p_toplevel := &Parse(0)
	i := 0
	n_bytes := 0
	p := &TableLock(0)
	p_toplevel = (if p_parse.pToplevel { p_parse.pToplevel } else { p_parse })
	for i = 0; i < p_toplevel.nTableLock; i++ {
		p = unsafe { p_toplevel.aTableLock + i }
		if p.iDb == i_db && p.iTab == i_tab {
			p.isWriteLock = U8((int(p.isWriteLock) || int(is_write_lock)))
			return
		}
	}
	n_bytes = int(sizeof(TableLock) * u64((p_toplevel.nTableLock + 1)))
	p_toplevel.aTableLock = sqlite3_db_realloc_or_free(p_toplevel.db, voidptr(p_toplevel.aTableLock), U64(n_bytes))
	if p_toplevel.aTableLock {
		p = unsafe { p_toplevel.aTableLock + p_toplevel.nTableLock++ }
		p.iDb = i_db
		p.iTab = i_tab
		p.isWriteLock = is_write_lock
		p.zLockName = z_name
	} else {
		p_toplevel.nTableLock = 0
		sqlite3_oom_fault(p_toplevel.db)
	}
}

@[c:'sqlite3TableLock']
fn sqlite3_table_lock(p_parse &Parse, i_db int, i_tab Pgno, is_write_lock U8, z_name &i8) {
	if i_db == 1 {
		return
	}
	if !sqlite3_btree_sharable(p_parse.db.aDb[i_db].pBt) {
		return
	}
	lock_table(p_parse, i_db, i_tab, is_write_lock, z_name)
}

@[c:'codeTableLocks']
fn code_table_locks(p_parse &Parse) {
	i := 0
	p_vdbe := p_parse.pVdbe
	for i = 0; i < p_parse.nTableLock; i++ {
		p := unsafe { p_parse.aTableLock + i }
		p1 := p.iDb
		sqlite3_vdbe_add_op4(p_vdbe, 171, p1, int(p.iTab), int(p.isWriteLock), p.zLockName, (-1))
	}
}

@[c:'sqlite3FinishCoding']
fn sqlite3_finish_coding(p_parse &Parse) {
	db := &Sqlite3(0)
	v := &Vdbe(0)
	i_db := 0
	i := 0

	db = p_parse.db
	if p_parse.nested {
		return
	}
	if p_parse.nErr {
		if db.mallocFailed {
			p_parse.rc = 7
		}
		return
	}
	v = p_parse.pVdbe
	if usize(v) == usize(0) {
		if db.init.busy {
			p_parse.rc = 101
			return
		}
		v = sqlite3_get_vdbe(p_parse)
		if usize(v) == usize(0) {
			p_parse.rc = 1
		}
	}
	if v {
		if p_parse.bReturning {
			p_returning := &Returning(0)
			addr_rewind := 0
			reg := 0
			p_returning = p_parse.u1.d.pReturning
			if p_returning.nRetCol {
				sqlite3_vdbe_add_op0(v, 85)
				addr_rewind = sqlite3_vdbe_add_op1(v, 36, p_returning.iRetCur)
				0
				reg = p_returning.iRetReg
				for i = 0; i < p_returning.nRetCol; i++ {
					sqlite3_vdbe_add_op3(v, 96, p_returning.iRetCur, i, reg + i)
				}
				sqlite3_vdbe_add_op2(v, 86, reg, i)
				sqlite3_vdbe_add_op2(v, 40, p_returning.iRetCur, addr_rewind + 1)
				0
				sqlite3_vdbe_jump_here(v, addr_rewind)
			}
		}
		sqlite3_vdbe_add_op0(v, 72)
		sqlite3_vdbe_jump_here(v, 0)
		i_db = 0
		for {
			p_schema := &Schema(0)
			if ((p_parse.cookieMask & ((YDbMask(1)) << i_db)) != YDbMask(0)) == 0 {
				unsafe { goto c2v_do_next_97
				 }
			}
			sqlite3_vdbe_uses_btree(v, i_db)
			p_schema = db.aDb[i_db].pSchema
			sqlite3_vdbe_add_op4_int(v, 2, i_db, ((p_parse.writeMask & ((YDbMask(1)) << i_db)) != YDbMask(0)), p_schema.schema_cookie, p_schema.iGeneration)
			if int(db.init.busy) == 0 {
				sqlite3_vdbe_change_p5(v, U16(1))
			}
			0
			c2v_do_next_97:
			i_db++
			if !(i_db < db.nDb) {
				break
			}
		}
		for i = 0; i < p_parse.nVtabLock; i++ {
			vtab := &i8(voidptr(sqlite3_get_vt_able(db, p_parse.apVtabLock[i])))
			sqlite3_vdbe_add_op4(v, 172, 0, 0, 0, vtab, (-12))
		}
		p_parse.nVtabLock = 0
		if p_parse.nTableLock {
			code_table_locks(p_parse)
		}
		if p_parse.pAinc {
			sqlite3_autoincrement_begin(p_parse)
		}
		if p_parse.pConstExpr {
			pel := p_parse.pConstExpr
			p_parse.okConstFactor = Bft(0)
			for i = 0; i < pel.nExpr; i++ {
				sqlite3_expr_code(p_parse, c2v_at(&pel.a[0], isize(i)).pExpr, c2v_at(&pel.a[0], isize(i)).u.iConstExprReg)
			}
		}
		if p_parse.bReturning {
			p_ret := &Returning(0)
			p_ret = p_parse.u1.d.pReturning
			if p_ret.nRetCol {
				sqlite3_vdbe_add_op2(v, 120, p_ret.iRetCur, p_ret.nRetCol)
			}
		}
		sqlite3_vdbe_goto(v, 1)
	}
	if p_parse.nErr == 0 {
		sqlite3_vdbe_make_ready(v, p_parse)
		p_parse.rc = 101
	} else {
		p_parse.rc = 1
	}
}

@[c:'sqlite3NestedParse']
@[c2v_variadic]
fn sqlite3_nested_parse(p_parse &Parse, z_format &i8, ...) {
	ap := C.va_list{}
	z_sql := &i8(0)
	db := p_parse.db
	saved_db_flags := db.mDbFlags
	save_buf := [136]i8{}
	if p_parse.nErr {
		return
	}
	if p_parse.eParseMode {
		return
	}
	C.va_start(ap, z_format)
	z_sql = sqlite3_vm_printf(db, z_format, ap)
	C.va_end(ap)
	if usize(z_sql) == usize(0) {
		if !db.mallocFailed {
			p_parse.rc = 18
		}
		p_parse.nErr++
		return
	}
	p_parse.nested++
	C.memcpy(voidptr(unsafe { &save_buf[0] }), voidptr(((&i8(voidptr(p_parse))) + (u64(usize(__offsetof(Parse, sLastToken)))))), (sizeof(Parse) - (u64(usize(__offsetof(Parse, sLastToken))))))
	C.memset(voidptr(((&i8(voidptr(p_parse))) + (u64(usize(__offsetof(Parse, sLastToken)))))), 0, (sizeof(Parse) - (u64(usize(__offsetof(Parse, sLastToken))))))
	db.mDbFlags |= u32(2)
	sqlite3_run_parser(p_parse, z_sql)
	db.mDbFlags = saved_db_flags
	sqlite3_db_free(db, voidptr(z_sql))
	C.memcpy(voidptr(((&i8(voidptr(p_parse))) + (u64(usize(__offsetof(Parse, sLastToken)))))), voidptr(unsafe { &save_buf[0] }), (sizeof(Parse) - (u64(usize(__offsetof(Parse, sLastToken))))))
	p_parse.nested--
}

@[c:'sqlite3FindTable']
fn sqlite3_find_table(db &Sqlite3, z_name &i8, z_database &i8) &Table {
	p := unsafe { &Table(nil) }
	i := 0
	if z_database {
		for i = 0; i < db.nDb; i++ {
			if sqlite3_str_ic_mp(z_database, db.aDb[i].zDbSName) == 0 {
				break
			}
		}
		if i >= db.nDb {
			if sqlite3_str_ic_mp(z_database, c'main') == 0 {
				i = 0
			} else {
				return unsafe { nil }
			}
		}
		p = sqlite3_hash_find(&db.aDb[i].pSchema.tblHash, z_name)
		if usize(p) == usize(0) && sqlite3_strnicmp(z_name, c'sqlite_', 7) == 0 {
			if i == 1 {
				mut __c2v_condition_62 := false
				mut __c2v_condition_63 := false
				__c2v_condition_63 = sqlite3_str_ic_mp(z_name + 7, unsafe { c'sqlite_temp_schema' + 7 }) == 0
				__c2v_condition_62 = __c2v_condition_63
				if !__c2v_condition_62 {
					mut __c2v_condition_64 := false
					__c2v_condition_64 = sqlite3_str_ic_mp(z_name + 7, unsafe { c'sqlite_schema' + 7 }) == 0
					__c2v_condition_62 = __c2v_condition_64
				}
				if !__c2v_condition_62 {
					mut __c2v_condition_65 := false
					__c2v_condition_65 = sqlite3_str_ic_mp(z_name + 7, unsafe { c'sqlite_master' + 7 }) == 0
					__c2v_condition_62 = __c2v_condition_65
				}
				if __c2v_condition_62 {
					p = sqlite3_hash_find(&db.aDb[1].pSchema.tblHash, c'sqlite_temp_master')
				}
			} else {
				if sqlite3_str_ic_mp(z_name + 7, unsafe { c'sqlite_schema' + 7 }) == 0 {
					p = sqlite3_hash_find(&db.aDb[i].pSchema.tblHash, c'sqlite_master')
				}
			}
		}
	} else {
		p = sqlite3_hash_find(&db.aDb[1].pSchema.tblHash, z_name)
		if p {
			return p
		}
		p = sqlite3_hash_find(&db.aDb[0].pSchema.tblHash, z_name)
		if p {
			return p
		}
		for i = 2; i < db.nDb; i++ {
			p = sqlite3_hash_find(&db.aDb[i].pSchema.tblHash, z_name)
			if p {
				break
			}
		}
		if usize(p) == usize(0) && sqlite3_strnicmp(z_name, c'sqlite_', 7) == 0 {
			if sqlite3_str_ic_mp(z_name + 7, unsafe { c'sqlite_schema' + 7 }) == 0 {
				p = sqlite3_hash_find(&db.aDb[0].pSchema.tblHash, c'sqlite_master')
			} else if sqlite3_str_ic_mp(z_name + 7, unsafe { c'sqlite_temp_schema' + 7 }) == 0 {
				p = sqlite3_hash_find(&db.aDb[1].pSchema.tblHash, c'sqlite_temp_master')
			}
		}
	}
	return p
}

@[c:'sqlite3LocateTable']
fn sqlite3_locate_table(p_parse &Parse, flags u32, z_name &i8, z_dbase &i8) &Table {
	p := &Table(0)
	db := p_parse.db
	if (db.mDbFlags & u32(16)) == u32(0) && 0 != sqlite3_read_schema(p_parse) {
		return unsafe { nil }
	}
	p = sqlite3_find_table(db, z_name, z_dbase)
	if usize(p) == usize(0) {
		if (int(p_parse.prepFlags) & 4) == 0 && int(db.init.busy) == 0 {
			p_mod := &Module(sqlite3_hash_find(&db.aModule, z_name))
			if usize(p_mod) == usize(0) && sqlite3_strnicmp(z_name, c'pragma_', 7) == 0 {
				p_mod = sqlite3_pragma_vtab_register(db, z_name)
			}
			if usize(p_mod) == usize(0) && sqlite3_strnicmp(z_name, c'json', 4) == 0 {
				p_mod = sqlite3_json_vtab_register(db, z_name)
			}
			if !isnil(p_mod) && sqlite3_vtab_eponymous_table_init(p_parse, p_mod) {
				0
				return p_mod.pEpoTab
			}
		}
		if flags & u32(2) {
			return unsafe { nil }
		}
		p_parse.checkSchema = Bft(1)
	} else if (int(p.eTabType) == 1) && (int(p_parse.prepFlags) & 4) != 0 {
		p = 0
	}
	if usize(p) == usize(0) {
		z_msg := if flags & u32(1) { c'no such view' } else { c'no such table' }
		if z_dbase {
			sqlite3_error_msg(p_parse, c'%s: %s.%s', voidptr(z_msg), voidptr(z_dbase), voidptr(z_name))
		} else {
			sqlite3_error_msg(p_parse, c'%s: %s', voidptr(z_msg), voidptr(z_name))
		}
	} else {
	}
	return p
}

@[c:'sqlite3LocateTableItem']
fn sqlite3_locate_table_item(p_parse &Parse, flags u32, p &SrcItem) &Table {
	z_db := &i8(0)
	if p.fg.fixedSchema {
		i_db := sqlite3_schema_to_index(p_parse.db, p.u4.pSchema)
		z_db = p_parse.db.aDb[i_db].zDbSName
	} else {
		z_db = p.u4.zDatabase
	}
	return sqlite3_locate_table(p_parse, flags, p.zName, z_db)
}

@[c:'sqlite3PreferredTableName']
fn sqlite3_preferred_table_name(z_name &i8) &i8 {
	if sqlite3_strnicmp(z_name, c'sqlite_', 7) == 0 {
		if sqlite3_str_ic_mp(z_name + 7, unsafe { c'sqlite_master' + 7 }) == 0 {
			return unsafe { &i8(&c'sqlite_schema'[0]) }
		}
		if sqlite3_str_ic_mp(z_name + 7, unsafe { c'sqlite_temp_master' + 7 }) == 0 {
			return unsafe { &i8(&c'sqlite_temp_schema'[0]) }
		}
	}
	return z_name
}

@[c:'sqlite3FindIndex']
fn sqlite3_find_index(db &Sqlite3, z_name &i8, z_db &i8) &Index {
	p := unsafe { &Index(nil) }
	i := 0
	for i = 0; i < db.nDb; i++ {
		j := if (i < 2) { i ^ 1 } else { i }
		p_schema := db.aDb[j].pSchema
		if !isnil(z_db) && sqlite3_db_is_named(db, j, z_db) == 0 {
			continue
		}
		p = sqlite3_hash_find(&p_schema.idxHash, z_name)
		if p {
			break
		}
	}
	return p
}

@[c:'sqlite3FreeIndex']
fn sqlite3_free_index(db &Sqlite3, p &Index) {
	sqlite3_delete_index_samples(db, p)
	sqlite3_expr_delete(db, p.pPartIdxWhere)
	sqlite3_expr_list_delete(db, p.aColExpr)
	sqlite3_db_free(db, voidptr(p.zColAff))
	if p.isResized {
		sqlite3_db_free(db, voidptr(p.azColl))
	}
	sqlite3_db_free(db, voidptr(p))
}

@[c:'sqlite3UnlinkAndDeleteIndex']
fn sqlite3_unlink_and_delete_index(db &Sqlite3, i_db int, z_idx_name &i8) {
	p_index := &Index(0)
	p_hash := &Hash(0)
	p_hash = &db.aDb[i_db].pSchema.idxHash
	p_index = sqlite3_hash_insert(p_hash, z_idx_name, unsafe { nil })
	if p_index {
		if usize(p_index.pTable.pIndex) == usize(p_index) {
			p_index.pTable.pIndex = p_index.pNext
		} else {
			p := &Index(0)
			p = p_index.pTable.pIndex
			for !isnil(p) && usize(p.pNext) != usize(p_index) {
				p = p.pNext
			}
			if (!isnil(p) && usize(p.pNext) == usize(p_index)) {
				p.pNext = p_index.pNext
			}
		}
		sqlite3_free_index(db, p_index)
	}
	db.mDbFlags |= u32(1)
}

@[c:'sqlite3CollapseDatabaseArray']
fn sqlite3_collapse_database_array(db &Sqlite3) {
	i := 0
	j := 0

	j = 2
	for i = 2; i < db.nDb; i++ {
		p_db := unsafe { db.aDb + i }
		if usize(p_db.pBt) == usize(0) {
			sqlite3_db_free(db, voidptr(p_db.zDbSName))
			p_db.zDbSName = 0
			continue
		}
		if j < i {
			db.aDb[j] = db.aDb[i]
		}
		j++
	}
	db.nDb = j
	if db.nDb <= 2 && usize(db.aDb) != usize(unsafe { &db.aDbStatic[0] }) {
		C.memcpy(db.aDbStatic, voidptr(db.aDb), u64(2) * sizeof(Db))
		sqlite3_db_free(db, voidptr(db.aDb))
		db.aDb = unsafe { &db.aDbStatic[0] }
	}
}

@[c:'sqlite3ResetOneSchema']
fn sqlite3_reset_one_schema(db &Sqlite3, i_db int) {
	i := 0
	if i_db >= 0 {
		db.aDb[i_db].pSchema.schemaFlags |= 8
		db.aDb[1].pSchema.schemaFlags |= 8
		db.mDbFlags &= u32(~16)
	}
	if db.nSchemaLock == u32(0) {
		for i = 0; i < db.nDb; i++ {
			if ((int(db.aDb[i].pSchema.schemaFlags) & 8) == 8) {
				sqlite3_schema_clear(voidptr(db.aDb[i].pSchema))
			}
		}
	}
}

@[c:'sqlite3ResetAllSchemasOfConnection']
fn sqlite3_reset_all_schemas_of_connection(db &Sqlite3) {
	i := 0
	sqlite3_btree_enter_all(db)
	for i = 0; i < db.nDb; i++ {
		p_db := unsafe { db.aDb + i }
		if p_db.pSchema {
			if db.nSchemaLock == u32(0) {
				sqlite3_schema_clear(voidptr(p_db.pSchema))
			} else {
				db.aDb[i].pSchema.schemaFlags |= 8
			}
		}
	}
	db.mDbFlags &= u32(~(1 | 16))
	sqlite3_vtab_unlock_list(db)
	sqlite3_btree_leave_all(db)
	if db.nSchemaLock == u32(0) {
		sqlite3_collapse_database_array(db)
	}
}

@[c:'sqlite3CommitInternalChanges']
fn sqlite3_commit_internal_changes(db &Sqlite3) {
	db.mDbFlags &= u32(~1)
}

@[c:'sqlite3ColumnSetExpr']
fn sqlite3_column_set_expr(p_parse &Parse, p_tab &Table, p_col &Column, p_expr &Expr) {
	p_list := &ExprList(0)
	p_list = p_tab.u.tab.pDfltList
	if int(p_col.iDflt) == 0 || (usize(p_list) == usize(0)) || (p_list.nExpr < int(p_col.iDflt)) {
		p_col.iDflt = U16(if usize(p_list) == usize(0) { 1 } else { p_list.nExpr + 1 })
		p_tab.u.tab.pDfltList = sqlite3_expr_list_append(p_parse, p_list, p_expr)
	} else {
		sqlite3_expr_delete(p_parse.db, c2v_at(&p_list.a[0], isize(int(p_col.iDflt) - 1)).pExpr)
		mut __c2v_lhs_tmp_105 := unsafe { c2v_at(&p_list.a[0], isize(int(p_col.iDflt) - 1)) }
		__c2v_lhs_tmp_105.pExpr = p_expr
	}
}

@[c:'sqlite3ColumnExpr']
fn sqlite3_column_expr(p_tab &Table, p_col &Column) &Expr {
	if int(p_col.iDflt) == 0 {
		return unsafe { nil }
	}
	if !(int(p_tab.eTabType) == 0) {
		return unsafe { nil }
	}
	if (usize(p_tab.u.tab.pDfltList) == usize(0)) {
		return unsafe { nil }
	}
	if (p_tab.u.tab.pDfltList.nExpr < int(p_col.iDflt)) {
		return unsafe { nil }
	}
	return c2v_at(&p_tab.u.tab.pDfltList.a[0], isize(int(p_col.iDflt) - 1)).pExpr
}

@[c:'sqlite3ColumnSetColl']
fn sqlite3_column_set_coll(db &Sqlite3, p_col &Column, z_coll &i8) {
	n_coll := I64(0)
	n := I64(0)
	z_new := &i8(0)
	n = I64(sqlite3_strlen30(p_col.zCnName) + 1)
	if int(p_col.colFlags) & 4 {
		n += I64(sqlite3_strlen30(p_col.zCnName + n) + 1)
	}
	n_coll = I64(sqlite3_strlen30(z_coll) + 1)
	z_new = &i8(sqlite3_db_realloc(db, voidptr(p_col.zCnName), U64(n_coll + n)))
	if z_new {
		p_col.zCnName = z_new
		C.memcpy(voidptr(p_col.zCnName + n), voidptr(z_coll), u64(n_coll))
		p_col.colFlags |= 512
	}
}

@[c:'sqlite3ColumnColl']
fn sqlite3_column_coll(p_col &Column) &i8 {
	z := &i8(0)
	if (int(p_col.colFlags) & 512) == 0 {
		return unsafe { nil }
	}
	z = p_col.zCnName
	for (unsafe { *z }) {
		c2v_pointer_postfix(voidptr(&z), z, isize(1))
	}
	if int(p_col.colFlags) & 4 {
		for {
			c2v_pointer_postfix(voidptr(&z), z, isize(1))
			if !(unsafe { *z }) {
				break
			}
		}
	}
	return z + 1
}

@[c:'sqlite3DeleteColumnNames']
fn sqlite3_delete_column_names(db &Sqlite3, p_table &Table) {
	i := 0
	p_col := &Column(0)
	p_col = p_table.aCol
	if usize(p_col) != usize(0) {
		for i = 0; i < int(p_table.nCol); i++ {
			sqlite3_db_free(db, voidptr(p_col.zCnName))
			c2v_pointer_postfix(voidptr(&p_col), p_col, isize(1))
		}
		sqlite3_db_nn_free_nn(db, voidptr(p_table.aCol))
		if (int(p_table.eTabType) == 0) {
			sqlite3_expr_list_delete(db, p_table.u.tab.pDfltList)
		}
		if usize(db.pnBytesFreed) == usize(0) {
			p_table.aCol = 0
			p_table.nCol = I16(0)
			if (int(p_table.eTabType) == 0) {
				p_table.u.tab.pDfltList = 0
			}
		}
	}
}

@[c:'deleteTable']
fn delete_table(db &Sqlite3, p_table &Table) {
	p_index := &Index(0)
	p_next := &Index(0)

	for p_index = p_table.pIndex; p_index; p_index = p_next {
		p_next = p_index.pNext
		if usize(db.pnBytesFreed) == usize(0) && !(int(p_table.eTabType) == 1) {
			z_name := p_index.zName
			sqlite3_hash_insert(&p_index.pSchema.idxHash, z_name, unsafe { nil })
		}
		sqlite3_free_index(db, p_index)
	}
	if (int(p_table.eTabType) == 0) {
		sqlite3_fk_delete(db, p_table)
	} else if (int(p_table.eTabType) == 1) {
		sqlite3_vtab_clear(db, p_table)
	} else {
		sqlite3_select_delete(db, p_table.u.view.pSelect)
	}
	sqlite3_delete_column_names(db, p_table)
	sqlite3_db_free(db, voidptr(p_table.zName))
	sqlite3_db_free(db, voidptr(p_table.zColAff))
	sqlite3_expr_list_delete(db, p_table.pCheck)
	sqlite3_db_free(db, voidptr(p_table))
}

@[c:'sqlite3DeleteTable']
fn sqlite3_delete_table(db &Sqlite3, p_table &Table) {
	if isnil(p_table) {
		return
	}
	if usize(db.pnBytesFreed) == usize(0) && (c2v_prefix_add(unsafe { &p_table.nTabRef }, u32(-1))) > u32(0) {
		return
	}
	delete_table(db, p_table)
}

@[c:'sqlite3DeleteTableGeneric']
fn sqlite3_delete_table_generic(db &Sqlite3, p_table voidptr) {
	c2v_gc_register_thread()
	sqlite3_delete_table(db, &Table(p_table))
}

@[c:'sqlite3UnlinkAndDeleteTable']
fn sqlite3_unlink_and_delete_table(db &Sqlite3, i_db int, z_tab_name &i8) {
	p := &Table(0)
	p_db := &Db(0)
	0
	p_db = unsafe { db.aDb + i_db }
	p = sqlite3_hash_insert(&p_db.pSchema.tblHash, z_tab_name, unsafe { nil })
	sqlite3_delete_table(db, p)
	db.mDbFlags |= u32(1)
}

@[c:'sqlite3NameFromToken']
fn sqlite3_name_from_token(db &Sqlite3, p_name &Token) &i8 {
	z_name := &i8(0)
	if p_name {
		z_name = sqlite3_db_str_nd_up(db, &i8(p_name.z), U64(p_name.n))
		sqlite3_dequote(z_name)
	} else {
		z_name = 0
	}
	return z_name
}

@[c:'sqlite3OpenSchemaTable']
fn sqlite3_open_schema_table(p &Parse, i_db int) {
	v := sqlite3_get_vdbe(p)
	sqlite3_table_lock(p, i_db, Pgno(1), U8(1), c'sqlite_master')
	sqlite3_vdbe_add_op4_int(v, 116, 0, 1, i_db, 5)
	if p.nTab == 0 {
		p.nTab = 1
	}
}

@[c:'sqlite3FindDbName']
fn sqlite3_find_db_name(db &Sqlite3, z_name &i8) int {
	i := -1
	if z_name {
		p_db := &Db(0)
		i = (db.nDb - 1)
		for p_db = unsafe { db.aDb + i }; i >= 0; i-- {
			if 0 == sqlite3_stricmp(p_db.zDbSName, z_name) {
				break
			}
			if i == 0 && 0 == sqlite3_stricmp(c'main', z_name) {
				break
			}
			c2v_pointer_postfix(voidptr(&p_db), p_db, isize(-1))
		}
	}
	return i
}

@[c:'sqlite3FindDb']
fn sqlite3_find_db(db &Sqlite3, p_name &Token) int {
	i := 0
	z_name := &i8(0)
	z_name = sqlite3_name_from_token(db, p_name)
	i = sqlite3_find_db_name(db, z_name)
	sqlite3_db_free(db, voidptr(z_name))
	return i
}

@[c:'sqlite3TwoPartName']
fn sqlite3_two_part_name(p_parse &Parse, p_name1 &Token, p_name2 &Token, p_unqual &&Token) int {
	i_db := 0
	db := p_parse.db
	if p_name2.n > u32(0) {
		if db.init.busy {
			sqlite3_error_msg(p_parse, c'corrupt database')
			return -1
		}
		unsafe { *p_unqual = p_name2 }
		i_db = sqlite3_find_db(db, p_name1)
		if i_db < 0 {
			sqlite3_error_msg(p_parse, c'unknown database %T', voidptr(p_name1))
			return -1
		}
	} else {
		i_db = int(db.init.iDb)
		unsafe { *p_unqual = p_name1 }
	}
	return i_db
}

@[c:'sqlite3WritableSchema']
fn sqlite3_writable_schema(db &Sqlite3) int {
	0
	0
	0
	0
	return int((db.flags & U64((1 | 268435456))) == U64(1))
}

@[c:'sqlite3CheckObjectName']
fn sqlite3_check_object_name(p_parse &Parse, z_name &i8, z_type &i8, z_tbl_name &i8) int {
	db := p_parse.db
	if sqlite3_writable_schema(db) || int(db.init.imposterTable) || !sqlite3Config.bExtraSchemaChecks {
		return 0
	}
	if db.init.busy {
		if sqlite3_stricmp(z_type, db.init.azInit[0]) || sqlite3_stricmp(z_name, db.init.azInit[1]) || sqlite3_stricmp(z_tbl_name, db.init.azInit[2]) {
			sqlite3_error_msg(p_parse, c'')
			return 1
		}
	} else {
		if (int(p_parse.nested) == 0 && 0 == sqlite3_strnicmp(z_name, c'sqlite_', 7)) || (sqlite3_read_only_shadow_tables(db) && sqlite3_shadow_table_name(db, z_name)) {
			sqlite3_error_msg(p_parse, c'object name reserved for internal use: %s', voidptr(z_name))
			return 1
		}
	}
	return 0
}

@[c:'sqlite3PrimaryKeyIndex']
fn sqlite3_primary_key_index(p_tab &Table) &Index {
	p := &Index(0)
	for p = p_tab.pIndex; !isnil(p) && !(int(p.idxType) == 2); p = p.pNext {
	}
	return p
}

@[c:'sqlite3TableColumnToIndex']
fn sqlite3_table_column_to_index(p_idx &Index, i_col int) int {
	i := 0
	i_col16 := I16(0)
	i_col16 = I16(i_col)
	for i = 0; i < int(p_idx.nColumn); i++ {
		if int(i_col16) == int(p_idx.aiColumn[i]) {
			return i
		}
	}
	return -1
}

@[c:'sqlite3StorageColumnToTable']
fn sqlite3_storage_column_to_table(p_tab &Table, i_col I16) I16 {
	if p_tab.tabFlags & u32(32) {
		i := 0
		for i = 0; i <= int(i_col); i++ {
			if int(p_tab.aCol[i].colFlags) & 32 {
				i_col++
			}
		}
	}
	return i_col
}

@[c:'sqlite3TableColumnToStorage']
fn sqlite3_table_column_to_storage(p_tab &Table, i_col I16) I16 {
	i := 0
	n := I16(0)
	if (p_tab.tabFlags & u32(32)) == u32(0) || int(i_col) < 0 {
		return i_col
	}
	i = 0
	for n = I16(0); i < int(i_col); i++ {
		if (int(p_tab.aCol[i].colFlags) & 32) == 0 {
			n++
		}
	}
	if int(p_tab.aCol[i].colFlags) & 32 {
		return I16(int(p_tab.nNVCol) + i - int(n))
	} else {
		return n
	}
}

@[c:'sqlite3ForceNotReadOnly']
fn sqlite3_force_not_read_only(p_parse &Parse) {
	i_reg := c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	v := sqlite3_get_vdbe(p_parse)
	if v {
		sqlite3_vdbe_add_op3(v, 4, 0, i_reg, (-1))
		sqlite3_vdbe_uses_btree(v, 0)
	}
}

@[c:'sqlite3StartTable']
fn sqlite3_start_table(p_parse &Parse, p_name1 &Token, p_name2 &Token, is_temp int, is_view int, is_virtual int, no_err int) {
	p_table := &Table(0)
	z_name := unsafe { &i8(nil) }
	db := p_parse.db
	v := &Vdbe(0)
	i_db := 0
	p_name := &Token(0)
	if int(db.init.busy) && db.init.newTnum == Pgno(1) {
		i_db = int(db.init.iDb)
		z_name = sqlite3_db_str_dup(db, unsafe { if (!0) && (i_db == 1) {
			c'sqlite_temp_master'
		} else {
			c'sqlite_master'
		} })
		p_name = p_name1
	} else {
		i_db = sqlite3_two_part_name(p_parse, p_name1, p_name2, &&Token(&&Token(c2v_address_of(&p_name))))
		if i_db < 0 {
			return
		}
		if !0 && is_temp && p_name2.n > u32(0) && i_db != 1 {
			sqlite3_error_msg(p_parse, c'temporary table name must be unqualified')
			return
		}
		if !0 && is_temp {
			i_db = 1
		}
		z_name = sqlite3_name_from_token(db, p_name)
		if (int(p_parse.eParseMode) >= 2) {
			sqlite3_rename_token_map(p_parse, voidptr(z_name), p_name)
		}
	}
	p_parse.sNameToken = unsafe { *p_name }
	if usize(z_name) == usize(0) {
		return
	}
	if sqlite3_check_object_name(p_parse, z_name, unsafe { if is_view { c'view' } else { c'table' } }, z_name) {
		unsafe { goto begin_table_error
		 }
	}
	if int(db.init.iDb) == 1 {
		is_temp = 1
	}
	if !sqlite3_start_table_a_code_inited {
		c2v_static_init := [U8(2), U8(4), U8(8), U8(6)]!
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_start_table_a_code[c2v_i_0] = c2v_element_0
		}
		sqlite3_start_table_a_code_inited = true
	}

	z_db := db.aDb[i_db].zDbSName
	if sqlite3_auth_check(p_parse, 18, unsafe { if (!0) && (is_temp == 1) {
		c'sqlite_temp_master'
	} else {
		c'sqlite_master'
	} }, unsafe { nil }, z_db) {
		unsafe { goto begin_table_error
		 }
	}
	if !is_virtual && sqlite3_auth_check(p_parse, int(sqlite3_start_table_a_code[is_temp + 2 * is_view]), z_name, unsafe { nil }, z_db) {
		unsafe { goto begin_table_error
		 }
	}
	if !(int(p_parse.eParseMode) != 0) {
		z_db_2 := db.aDb[i_db].zDbSName
		if 0 != sqlite3_read_schema(p_parse) {
			unsafe { goto begin_table_error
			 }
		}
		p_table = sqlite3_find_table(db, z_name, z_db_2)
		if p_table {
			if !no_err {
				sqlite3_error_msg(p_parse, c'%s %T already exists', voidptr((if (int(p_table.eTabType) == 2) {
					c'view'
				} else {
					c'table'
				})), voidptr(p_name))
			} else {
				sqlite3_code_verify_schema(p_parse, i_db)
				sqlite3_force_not_read_only(p_parse)
			}
			unsafe { goto begin_table_error
			 }
		}
		if usize(sqlite3_find_index(db, z_name, z_db_2)) != usize(0) {
			sqlite3_error_msg(p_parse, c'there is already an index named %s', voidptr(z_name))
			unsafe { goto begin_table_error
			 }
		}
	}
	p_table = sqlite3_db_malloc_zero(db, U64(sizeof(Table)))
	if usize(p_table) == usize(0) {
		p_parse.rc = 7
		p_parse.nErr++
		unsafe { goto begin_table_error
		 }
	}
	p_table.zName = z_name
	p_table.iPKey = I16(-1)
	p_table.pSchema = db.aDb[i_db].pSchema
	p_table.nTabRef = u32(1)
	p_table.nRowLogEst = LogEst(200)
	p_parse.pNewTable = p_table
	if !db.init.busy && usize(c2v_assign[&Vdbe](unsafe { &v }, sqlite3_get_vdbe(p_parse))) != usize(0) {
		addr1 := 0
		file_format := 0
		reg1 := 0
		reg2 := 0
		reg3 := 0

		if !sqlite3_start_table_null_row_inited {
			c2v_static_init := [i8(6), i8(0), i8(0), i8(0), i8(0), i8(0)]
			for c2v_i_0, c2v_element_0 in c2v_static_init {
				sqlite3_start_table_null_row[c2v_i_0] = c2v_element_0
			}
			sqlite3_start_table_null_row_inited = true
		}

		sqlite3_begin_write_operation(p_parse, 1, i_db)
		if is_virtual {
			sqlite3_vdbe_add_op0(v, 172)
		}
		p_parse.u1.cr.regRowid = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		reg1 = p_parse.u1.cr.regRowid
		p_parse.u1.cr.regRoot = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		reg2 = p_parse.u1.cr.regRoot
		reg3 = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		sqlite3_vdbe_add_op3(v, 101, i_db, reg3, 2)
		sqlite3_vdbe_uses_btree(v, i_db)
		addr1 = sqlite3_vdbe_add_op1(v, 16, reg3)
		0
		file_format = if (db.flags & U64(2)) != U64(0) { 1 } else { 4 }
		sqlite3_vdbe_add_op3(v, 102, i_db, 2, file_format)
		sqlite3_vdbe_add_op3(v, 102, i_db, 5, int(db.enc))
		sqlite3_vdbe_jump_here(v, addr1)
		if is_view || is_virtual {
			sqlite3_vdbe_add_op2(v, 73, 0, reg2)
		} else {
			p_parse.u1.cr.addrCrTab = sqlite3_vdbe_add_op3(v, 149, i_db, reg2, 1)
		}
		sqlite3_open_schema_table(p_parse, i_db)
		sqlite3_vdbe_add_op2(v, 129, 0, reg1)
		sqlite3_vdbe_add_op4(v, 79, 6, reg3, 0, unsafe { &i8(&sqlite3_start_table_null_row[0]) }, (-1))
		sqlite3_vdbe_add_op3(v, 130, 0, reg3, reg1)
		sqlite3_vdbe_change_p5(v, U16(8))
		sqlite3_vdbe_add_op0(v, 124)
	} else if db.init.imposterTable {
		p_table.tabFlags |= u32(131072)
		if int(db.init.imposterTable) >= 2 {
			p_table.tabFlags |= u32(1)
		}
	}
	return
	begin_table_error:
	p_parse.checkSchema = Bft(1)
	sqlite3_db_free(db, voidptr(z_name))
	return
}

@[c:'sqlite3DeleteReturning']
fn sqlite3_delete_returning(db &Sqlite3, p_arg voidptr) {
	c2v_gc_register_thread()
	p_ret := &Returning(p_arg)
	p_hash := &Hash(0)
	p_hash = &db.aDb[1].pSchema.trigHash
	sqlite3_hash_insert(p_hash, unsafe { &i8(&p_ret.zName[0]) }, unsafe { nil })
	sqlite3_expr_list_delete(db, p_ret.pReturnEL)
	sqlite3_db_free(db, voidptr(p_ret))
}

@[c:'sqlite3AddReturning']
fn sqlite3_add_returning(p_parse &Parse, p_list &ExprList) {
	p_ret := &Returning(0)
	p_hash := &Hash(0)
	db := p_parse.db
	if p_parse.pNewTrigger {
		sqlite3_error_msg(p_parse, c'cannot use RETURNING in a trigger')
	} else {
	}
	p_parse.bReturning = Bft(1)
	p_ret = sqlite3_db_malloc_zero(db, U64(sizeof(Returning)))
	if usize(p_ret) == usize(0) {
		sqlite3_expr_list_delete(db, p_list)
		return
	}
	p_parse.u1.d.pReturning = p_ret
	p_ret.pParse = p_parse
	p_ret.pReturnEL = p_list
	sqlite3_parser_add_cleanup(p_parse, sqlite3_delete_returning, voidptr(p_ret))
	0
	if db.mallocFailed {
		return
	}
	sqlite3_snprintf(int(sizeof([40]i8)), unsafe { &i8(&p_ret.zName[0]) }, c'sqlite_returning_%p', voidptr(p_parse))
	p_ret.retTrig.zName = unsafe { &p_ret.zName[0] }
	p_ret.retTrig.op = U8(151)
	p_ret.retTrig.tr_tm = U8(2)
	p_ret.retTrig.bReturning = U8(1)
	p_ret.retTrig.pSchema = db.aDb[1].pSchema
	p_ret.retTrig.pTabSchema = db.aDb[1].pSchema
	p_ret.retTrig.step_list = &p_ret.retTStep
	p_ret.retTStep.op = U8(151)
	p_ret.retTStep.pTrig = &p_ret.retTrig
	p_ret.retTStep.pExprList = p_list
	p_hash = &db.aDb[1].pSchema.trigHash
	if usize(sqlite3_hash_insert(p_hash, unsafe { &i8(&p_ret.zName[0]) }, voidptr(&p_ret.retTrig))) == usize(&p_ret.retTrig) {
		sqlite3_oom_fault(db)
	}
}

@[c:'sqlite3AddColumn']
fn sqlite3_add_column(p_parse &Parse, s_name Token, s_type Token) {
	p := &Table(0)
	i := 0
	z := &i8(0)
	z_type := &i8(0)
	p_col := &Column(0)
	db := p_parse.db
	a_new := &Column(0)
	e_type := U8(0)
	sz_est := U8(1)
	affinity := i8(65)
	p = p_parse.pNewTable
	if usize(p) == usize(0) {
		return
	}
	if int(p.nCol) + 1 > db.aLimit[2] {
		sqlite3_error_msg(p_parse, c'too many columns on %s', voidptr(p.zName))
		return
	}
	if !(int(p_parse.eParseMode) >= 2) {
		sqlite3_dequote_token(&s_name)
	}
	if s_type.n >= u32(16) && sqlite3_strnicmp(s_type.z + (s_type.n - u32(6)), c'always', 6) == 0 {
		s_type.n -= u32(6)
		for (s_type.n > u32(0)) && (int(sqlite3CtypeMap[u8(s_type.z[s_type.n - u32(1)])]) & 1) {
			s_type.n--
		}
		if s_type.n >= u32(9) && sqlite3_strnicmp(s_type.z + (s_type.n - u32(9)), c'generated', 9) == 0 {
			s_type.n -= u32(9)
			for s_type.n > u32(0) && (int(sqlite3CtypeMap[u8(s_type.z[s_type.n - u32(1)])]) & 1) {
				s_type.n--
			}
		}
	}
	if s_type.n >= u32(3) {
		sqlite3_dequote_token(&s_type)
		for i = 0; i < 6; i++ {
			if s_type.n == u32(sqlite3_std_type_len[i]) && sqlite3_strnicmp(s_type.z, sqlite3StdType[i], int(s_type.n)) == 0 {
				s_type.n = u32(0)
				e_type = U8(i + 1)
				affinity = sqlite3_std_type_affinity[i]
				if int(affinity) <= 66 {
					sz_est = U8(5)
				}
				break
			}
		}
	}
	z = &i8(sqlite3_db_malloc_raw(db, U64(I64(s_name.n) + I64(1) + I64(s_type.n) + int(I64((s_type.n > u32(0)))))))
	if usize(z) == usize(0) {
		return
	}
	if (int(p_parse.eParseMode) >= 2) {
		sqlite3_rename_token_map(p_parse, voidptr(z), &s_name)
	}
	C.memcpy(voidptr(z), voidptr(s_name.z), u64(s_name.n))
	z[s_name.n] = i8(0)
	sqlite3_dequote(z)
	if int(p.nCol) && sqlite3_column_index(p, z) >= 0 {
		sqlite3_error_msg(p_parse, c'duplicate column name: %s', voidptr(z))
		sqlite3_db_free(db, voidptr(z))
		return
	}
	a_new = sqlite3_db_realloc(db, voidptr(p.aCol), u64((I64(p.nCol) + I64(1))) * sizeof(Column))
	if usize(a_new) == usize(0) {
		sqlite3_db_free(db, voidptr(z))
		return
	}
	p.aCol = a_new
	p_col = unsafe { p.aCol + p.nCol }
	C.memset(voidptr(p_col), 0, sizeof(Column))
	p_col.zCnName = z
	p_col.hName = sqlite3_str_ih_ash(z)
	0
	if s_type.n == u32(0) {
		p_col.affinity = affinity
		p_col.eCType = u32(e_type)
		p_col.szEst = sz_est
	} else {
		z_type = z + sqlite3_strlen30(z) + 1
		C.memcpy(voidptr(z_type), voidptr(s_type.z), u64(s_type.n))
		z_type[s_type.n] = i8(0)
		sqlite3_dequote(z_type)
		p_col.affinity = sqlite3_affinity_type(z_type, p_col)
		p_col.colFlags |= 4
	}
	if int(p.nCol) <= 255 {
		h := U8(u64(p_col.hName) % sizeof([16]U8))
		p.aHx[h] = U8(p.nCol)
	}
	p.nCol++
	p.nNVCol++
	p_parse.u1.cr.constraintName.n = u32(0)
}

@[c:'sqlite3AddNotNull']
fn sqlite3_add_not_null(p_parse &Parse, on_error int) {
	p := &Table(0)
	p_col := &Column(0)
	p = p_parse.pNewTable
	if usize(p) == usize(0) || (int(p.nCol) < 1) {
		return
	}
	p_col = unsafe { p.aCol + (int(p.nCol) - 1) }
	p_col.notNull = u32(U8(on_error))
	p.tabFlags |= u32(2048)
	if int(p_col.colFlags) & 8 {
		p_idx := &Index(0)
		for p_idx = p.pIndex; p_idx; p_idx = p_idx.pNext {
			if int(p_idx.aiColumn[0]) == int(p.nCol) - 1 {
				p_idx.uniqNotNull = u32(1)
			}
		}
	}
}

@[c:'sqlite3AffinityType']
fn sqlite3_affinity_type(z_in &i8, p_col &Column) i8 {
	h := u32(0)
	aff := i8(67)
	z_char := unsafe { &i8(nil) }
	for z_in[0] {
		x := (unsafe { *&U8(voidptr(z_in)) })
		h = (h << 8) + u32(sqlite3UpperToLower[x])
		c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1))
		if h == u32(((`c` << 24) + (`h` << 16) + (`a` << 8) + int(`r`))) {
			aff = i8(66)
			z_char = z_in
		} else if h == u32(((`c` << 24) + (`l` << 16) + (`o` << 8) + int(`b`))) {
			aff = i8(66)
		} else if h == u32(((`t` << 24) + (`e` << 16) + (`x` << 8) + int(`t`))) {
			aff = i8(66)
		} else if h == u32(((`b` << 24) + (`l` << 16) + (`o` << 8) + int(`b`))) && (int(aff) == 67 || int(aff) == 69) {
			aff = i8(65)
			if int(z_in[0]) == i8(`(`) {
				z_char = z_in
			}
		} else if h == u32(((`r` << 24) + (`e` << 16) + (`a` << 8) + int(`l`))) && int(aff) == 67 {
			aff = i8(69)
		} else if h == u32(((`f` << 24) + (`l` << 16) + (`o` << 8) + int(`a`))) && int(aff) == 67 {
			aff = i8(69)
		} else if h == u32(((`d` << 24) + (`o` << 16) + (`u` << 8) + int(`b`))) && int(aff) == 67 {
			aff = i8(69)
		} else if (h & u32(16777215)) == u32(((`i` << 16) + (`n` << 8) + int(`t`))) {
			aff = i8(68)
			break
		}
	}
	if p_col {
		v := 0
		if int(aff) < 67 {
			if z_char {
				for z_char[0] {
					if (int(sqlite3CtypeMap[u8(z_char[0])]) & 4) {
						sqlite3_get_int32(z_char, &v)
						break
					}
					c2v_pointer_postfix(voidptr(&z_char), z_char, isize(1))
				}
			} else {
				v = 16
			}
		}
		v = v / 4 + 1
		if v > 255 {
			v = 255
		}
		p_col.szEst = U8(v)
	}
	return aff
}

@[c:'sqlite3AddDefaultValue']
fn sqlite3_add_default_value(p_parse &Parse, p_expr &Expr, z_start &i8, z_end &i8) {
	p := &Table(0)
	p_col := &Column(0)
	db := p_parse.db
	p = p_parse.pNewTable
	if usize(p) != usize(0) {
		is_init := int(db.init.busy && int(db.init.iDb) != 1)
		p_col = unsafe { p.aCol + (int(p.nCol) - 1) }
		if !sqlite3_expr_is_constant_or_function(p_expr, U8(is_init)) {
			sqlite3_error_msg(p_parse, c'default value of column [%s] is not constant', voidptr(p_col.zCnName))
		} else if int(p_col.colFlags) & 96 {
			0
			0
			sqlite3_error_msg(p_parse, c'cannot use DEFAULT on a generated column')
		} else {
			x := Expr{}
			p_dflt_expr := &Expr(0)

			C.memset(voidptr(&x), 0, sizeof(x))
			x.op = U8(181)
			x.u.zToken = sqlite3_db_span_dup(db, z_start, z_end)
			x.pLeft = p_expr
			x.flags = u32(8192)
			p_dflt_expr = sqlite3_expr_dup(db, &x, 1)
			sqlite3_db_free(db, voidptr(x.u.zToken))
			sqlite3_column_set_expr(p_parse, p, p_col, p_dflt_expr)
		}
	}
	if (int(p_parse.eParseMode) >= 2) {
		sqlite3_rename_expr_unmap(p_parse, p_expr)
	}
	sqlite3_expr_delete(db, p_expr)
}

@[c:'sqlite3StringToId']
fn sqlite3_string_to_id(p &Expr) {
	if int(p.op) == 118 {
		p.op = U8(60)
	} else if int(p.op) == 114 && int(p.pLeft.op) == 118 {
		p.pLeft.op = U8(60)
	}
}

@[c:'makeColumnPartOfPrimaryKey']
fn make_column_part_of_primary_key(p_parse &Parse, p_col &Column) {
	p_col.colFlags |= 1
	if int(p_col.colFlags) & 96 {
		0
		0
		sqlite3_error_msg(p_parse, c'generated columns cannot be part of the PRIMARY KEY')
	}
}

@[c:'sqlite3AddPrimaryKey']
fn sqlite3_add_primary_key(p_parse &Parse, p_list &ExprList, on_error int, auto_inc int, sort_order int) {
	p_tab := p_parse.pNewTable
	p_col := unsafe { &Column(nil) }
	i_col := -1
	i := 0

	n_term := 0
	if usize(p_tab) == usize(0) {
		unsafe { goto primary_key_exit
		 }
	}
	if p_tab.tabFlags & u32(4) {
		sqlite3_error_msg(p_parse, c'table "%s" has more than one primary key', voidptr(p_tab.zName))
		unsafe { goto primary_key_exit
		 }
	}
	p_tab.tabFlags |= u32(4)
	if usize(p_list) == usize(0) {
		i_col = int(p_tab.nCol) - 1
		p_col = unsafe { p_tab.aCol + i_col }
		make_column_part_of_primary_key(p_parse, p_col)
		n_term = 1
	} else {
		n_term = p_list.nExpr
		for i = 0; i < n_term; i++ {
			pce_xpr := sqlite3_expr_skip_collate(c2v_at(&p_list.a[0], isize(i)).pExpr)
			sqlite3_string_to_id(pce_xpr)
			if int(pce_xpr.op) == 60 {
				i_col = sqlite3_column_index(p_tab, pce_xpr.u.zToken)
				if i_col >= 0 {
					p_col = unsafe { p_tab.aCol + i_col }
					make_column_part_of_primary_key(p_parse, p_col)
				}
			}
		}
	}
	if n_term == 1 && !isnil(p_col) && int(p_col.eCType) == 4 && sort_order != 1 {
		if (int(p_parse.eParseMode) >= 2) && !isnil(p_list) {
			pce_xpr := sqlite3_expr_skip_collate(c2v_at(&p_list.a[0], isize(0)).pExpr)
			sqlite3_rename_token_remap(p_parse, voidptr(&p_tab.iPKey), voidptr(pce_xpr))
		}
		p_tab.iPKey = I16(i_col)
		p_tab.keyConf = U8(on_error)
		p_tab.tabFlags |= u32(auto_inc * 8)
		if p_list {
			p_parse.iPkSortOrder = c2v_at(&p_list.a[0], isize(0)).fg.sortFlags
		}
		sqlite3_has_explicit_nulls(p_parse, p_list)
	} else if auto_inc {
		sqlite3_error_msg(p_parse, c'AUTOINCREMENT is only allowed on an INTEGER PRIMARY KEY')
	} else {
		sqlite3_create_index(p_parse, unsafe { nil }, unsafe { nil }, unsafe { nil }, p_list, on_error, unsafe { nil }, unsafe { nil }, sort_order, 0, U8(2))
		p_list = 0
	}
	primary_key_exit:
	sqlite3_expr_list_delete(p_parse.db, p_list)
	return
}

@[c:'sqlite3AddCheckConstraint']
fn sqlite3_add_check_constraint(p_parse &Parse, p_check_expr &Expr, z_start &i8, z_end &i8) {
	p_tab := p_parse.pNewTable
	db := p_parse.db
	if !isnil(p_tab) && !(int(p_parse.eParseMode) == 1) && !sqlite3_btree_is_readonly(db.aDb[db.init.iDb].pBt) {
		p_tab.pCheck = sqlite3_expr_list_append(p_parse, p_tab.pCheck, p_check_expr)
		if p_parse.u1.cr.constraintName.n {
			sqlite3_expr_list_set_name(p_parse, p_tab.pCheck, &p_parse.u1.cr.constraintName, 1)
		} else {
			t := Token{}
			for z_start = unsafe { z_start + 1 }; (int(sqlite3CtypeMap[u8(z_start[0])]) & 1); z_start = unsafe { z_start + 1 } {
			}
			for (int(sqlite3CtypeMap[u8(z_end[-1])]) & 1) {
				c2v_pointer_postfix(voidptr(&z_end), z_end, isize(-1))
			}
			t.z = z_start
			t.n = u32(int((i64((isize(z_end) - isize(t.z)) / isize(sizeof(i8))))))
			sqlite3_expr_list_set_name(p_parse, p_tab.pCheck, &t, 1)
		}
	} else {
		sqlite3_expr_delete(p_parse.db, p_check_expr)
	}
}

@[c:'sqlite3AddCollateType']
fn sqlite3_add_collate_type(p_parse &Parse, p_token &Token) {
	p := &Table(0)
	i := 0
	z_coll := &i8(0)
	db := &Sqlite3(0)
	p = p_parse.pNewTable
	if usize(p) == usize(0) || (int(p_parse.eParseMode) >= 2) {
		return
	}
	i = int(p.nCol) - 1
	db = p_parse.db
	z_coll = sqlite3_name_from_token(db, p_token)
	if isnil(z_coll) {
		return
	}
	if sqlite3_locate_coll_seq(p_parse, z_coll) {
		p_idx := &Index(0)
		sqlite3_column_set_coll(db, unsafe { p.aCol + i }, z_coll)
		for p_idx = p.pIndex; p_idx; p_idx = p_idx.pNext {
			if int(p_idx.aiColumn[0]) == i {
				p_idx.azColl[0] = sqlite3_column_coll(unsafe { p.aCol + i })
			}
		}
	}
	sqlite3_db_free(db, voidptr(z_coll))
}

@[c:'sqlite3AddGenerated']
fn sqlite3_add_generated(p_parse &Parse, p_expr &Expr, p_type &Token) {
	e_type := U8(32)
	p_tab := p_parse.pNewTable
	p_col := &Column(0)
	if usize(p_tab) == usize(0) {
		unsafe { goto generated_done
		 }
	}
	p_col = unsafe { p_tab.aCol + (int(p_tab.nCol) - 1) }
	if (int(p_parse.eParseMode) == 1) {
		sqlite3_error_msg(p_parse, c'virtual tables cannot use computed columns')
		unsafe { goto generated_done
		 }
	}
	if int(p_col.iDflt) > 0 {
		unsafe { goto generated_error
		 }
	}
	if p_type {
		if p_type.n == u32(7) && sqlite3_strnicmp(c'virtual', p_type.z, 7) == 0 {
		} else if p_type.n == u32(6) && sqlite3_strnicmp(c'stored', p_type.z, 6) == 0 {
			e_type = U8(64)
		} else {
			unsafe { goto generated_error
			 }
		}
	}
	if int(e_type) == 32 {
		p_tab.nNVCol--
	}
	p_col.colFlags |= int(e_type)
	p_tab.tabFlags |= u32(e_type)
	if int(p_col.colFlags) & 1 {
		make_column_part_of_primary_key(p_parse, p_col)
	}
	if !isnil(p_expr) && int(p_expr.op) == 60 {
		p_expr = sqlite3_pe_xpr(p_parse, 173, p_expr, unsafe { nil })
	}
	if !isnil(p_expr) && int(p_expr.op) != 72 {
		p_expr.affExpr = p_col.affinity
	}
	sqlite3_column_set_expr(p_parse, p_tab, p_col, p_expr)
	p_expr = 0
	unsafe { goto generated_done
	 }
	generated_error:
	sqlite3_error_msg(p_parse, c'error in generated column "%s"', voidptr(p_col.zCnName))
	generated_done:
	sqlite3_expr_delete(p_parse.db, p_expr)
}

@[c:'sqlite3ChangeCookie']
fn sqlite3_change_cookie(p_parse &Parse, i_db int) {
	db := p_parse.db
	v := p_parse.pVdbe
	sqlite3_vdbe_add_op3(v, 102, i_db, 1, int((u32(1) + u32(db.aDb[i_db].pSchema.schema_cookie))))
}

@[c:'identLength']
fn ident_length(z &i8) I64 {
	n := I64(0)
	for n = I64(0); (unsafe { *z }); n++ {
		if int((unsafe { *z })) == i8(`\"`) {
			n++
		}
		c2v_pointer_postfix(voidptr(&z), z, isize(1))
	}
	return n + I64(2)
}

@[c:'identPut']
fn ident_put(z &i8, p_idx &int, z_signed_ident &i8) {
	z_ident := &u8(voidptr(z_signed_ident))
	i := 0
	j := 0
	need_quote := 0

	i = unsafe { *p_idx }
	for j = 0; z_ident[j]; j++ {
		if !(int(sqlite3CtypeMap[u8(z_ident[j])]) & 6) && int(z_ident[j]) != `_` {
			break
		}
	}
	need_quote = (int(sqlite3CtypeMap[u8(z_ident[0])]) & 4) || sqlite3_keyword_code(z_ident, j) != 60 || int(z_ident[j]) != 0 || j == 0
	if need_quote {
		z[i++] = i8(`\"`)
	}
	for j = 0; z_ident[j]; j++ {
		z[i++] = i8(z_ident[j])
		if int(z_ident[j]) == `\"` {
			z[i++] = i8(`\"`)
		}
	}
	if need_quote {
		z[i++] = i8(`\"`)
	}
	z[i] = i8(0)
	unsafe { *p_idx = i }
}

@[c:'createTableStmt']
fn create_table_stmt(db &Sqlite3, p &Table) &i8 {
	i := 0
	k := 0
	len := 0

	n := I64(0)
	z_stmt := &i8(0)
	z_sep := &i8(0)
	z_sep2 := &i8(0)
	z_end := &i8(0)

	p_col := &Column(0)
	n = I64(0)
	p_col = p.aCol
	for i = 0; i < int(p.nCol); i++ {
		n += ident_length(p_col.zCnName) + I64(5)
		c2v_pointer_postfix(voidptr(&p_col), p_col, isize(1))
	}
	n += ident_length(p.zName)
	if n < I64(50) {
		z_sep = c''
		z_sep2 = c','
		z_end = c')'
	} else {
		z_sep = c'\n  '
		z_sep2 = c',\n  '
		z_end = c'\n)'
	}
	n += I64(35 + 6 * int(p.nCol))
	z_stmt = &i8(sqlite3_db_malloc_raw(unsafe { nil }, U64(n)))
	if usize(z_stmt) == usize(0) {
		sqlite3_oom_fault(db)
		return unsafe { nil }
	}
	C.memcpy(voidptr(z_stmt), voidptr(c'CREATE TABLE '), u64(13))
	k = 13
	ident_put(z_stmt, &k, p.zName)
	z_stmt[k++] = i8(`(`)
	p_col = p.aCol
	for i = 0; i < int(p.nCol); i++ {
		if !create_table_stmt_az_type_inited {
			c2v_static_init := [c'', c' TEXT', c' NUM', c' INT', c' REAL', c' NUM']
			for c2v_i_0, c2v_element_0 in c2v_static_init {
				create_table_stmt_az_type[c2v_i_0] = c2v_element_0
			}
			create_table_stmt_az_type_inited = true
		}

		z_type := &i8(0)
		len = sqlite3_strlen30(z_sep)
		C.memcpy(voidptr(unsafe { z_stmt + k }), voidptr(z_sep), u64(len))
		k += len
		z_sep = z_sep2
		ident_put(z_stmt, &k, p_col.zCnName)
		0
		0
		0
		0
		0
		0
		z_type = create_table_stmt_az_type[int(p_col.affinity) - 65]
		len = sqlite3_strlen30(z_type)
		C.memcpy(voidptr(unsafe { z_stmt + k }), voidptr(z_type), u64(len))
		k += len
		c2v_pointer_postfix(voidptr(&p_col), p_col, isize(1))
	}
	len = sqlite3_strlen30(z_end)
	C.memcpy(voidptr(unsafe { z_stmt + k }), voidptr(z_end), u64(len + 1))
	return z_stmt
}

@[c:'resizeIndexObject']
fn resize_index_object(p_parse &Parse, p_idx &Index, n int) int {
	z_extra := &i8(0)
	n_byte := U64(0)
	db := &Sqlite3(0)
	if int(p_idx.nColumn) >= n {
		return 0
	}
	db = p_parse.db
	0
	n_byte = U64((sizeof(voidptr) + sizeof(LogEst) + sizeof(I16) + u64(1))) * U64(n)
	z_extra = &i8(sqlite3_db_malloc_zero(db, n_byte))
	if usize(z_extra) == usize(0) {
		return 7
	}
	C.memcpy(voidptr(z_extra), voidptr(p_idx.azColl), sizeof(voidptr) * u64(p_idx.nColumn))
	p_idx.azColl = &&u8(voidptr(z_extra))
	c2v_pointer_prefix(voidptr(&z_extra), z_extra, isize(sizeof(voidptr) * u64(n)))
	C.memcpy(voidptr(z_extra), voidptr(p_idx.aiRowLogEst), sizeof(LogEst) * u64((int(p_idx.nKeyCol) + 1)))
	p_idx.aiRowLogEst = &LogEst(voidptr(z_extra))
	c2v_pointer_prefix(voidptr(&z_extra), z_extra, isize(sizeof(LogEst) * u64(n)))
	C.memcpy(voidptr(z_extra), voidptr(p_idx.aiColumn), sizeof(I16) * u64(p_idx.nColumn))
	p_idx.aiColumn = &I16(voidptr(z_extra))
	c2v_pointer_prefix(voidptr(&z_extra), z_extra, isize(sizeof(I16) * u64(n)))
	C.memcpy(voidptr(z_extra), voidptr(p_idx.aSortOrder), u64(p_idx.nColumn))
	p_idx.aSortOrder = &U8(voidptr(z_extra))
	p_idx.nColumn = U16(n)
	p_idx.isResized = u32(1)
	return 0
}

@[c:'estimateTableWidth']
fn estimate_table_width(p_tab &Table) {
	w_table := u32(0)
	p_tab_col := &Column(0)
	i := 0
	i = int(p_tab.nCol)
	for p_tab_col = p_tab.aCol; i > 0; i-- {
		w_table += u32(p_tab_col.szEst)
		c2v_pointer_postfix(voidptr(&p_tab_col), p_tab_col, isize(1))
	}
	if int(p_tab.iPKey) < 0 {
		w_table++
	}
	p_tab.szTabRow = sqlite3_log_est(U64(w_table * u32(4)))
}

@[c:'estimateIndexWidth']
fn estimate_index_width(p_idx &Index) {
	w_index := u32(0)
	i := 0
	a_col := p_idx.pTable.aCol
	for i = 0; i < int(p_idx.nColumn); i++ {
		x := p_idx.aiColumn[i]
		w_index += u32(if int(x) < 0 { 1 } else { int(a_col[x].szEst) })
	}
	p_idx.szIdxRow = sqlite3_log_est(U64(w_index * u32(4)))
}

@[c:'hasColumn']
fn has_column(ai_col &I16, n_col int, x int) int {
	for n_col-- > 0 {
		if x == int((unsafe { *(c2v_pointer_postfix(voidptr(&ai_col), ai_col, isize(1))) })) {
			return 1
		}
	}
	return 0
}

@[c:'isDupColumn']
fn is_dup_column(p_idx &Index, n_key int, p_pk &Index, i_col int) int {
	i := 0
	j := 0

	0
	j = int(p_pk.aiColumn[i_col])
	for i = 0; i < n_key; i++ {
		if int(p_idx.aiColumn[i]) == j && sqlite3_str_ic_mp(p_idx.azColl[i], p_pk.azColl[i_col]) == 0 {
			return 1
		}
	}
	return 0
}

@[c:'recomputeColumnsNotIndexed']
fn recompute_columns_not_indexed(p_idx &Index) {
	m := Bitmask(0)
	j := 0
	p_tab := p_idx.pTable
	for j = int(p_idx.nColumn) - 1; j >= 0; j-- {
		x := int(p_idx.aiColumn[j])
		if x >= 0 && (int(p_tab.aCol[x].colFlags) & 32) == 0 {
			0
			0
			if x < (int((sizeof(Bitmask) * u64(8)))) - 1 {
				m |= ((Bitmask(1)) << x)
			}
		}
	}
	p_idx.colNotIdxed = ~m
}

@[c:'convertToWithoutRowidTable']
fn convert_to_without_rowid_table(p_parse &Parse, p_tab &Table) {
	p_idx := &Index(0)
	p_pk := &Index(0)
	n_pk := 0
	n_extra := 0
	i := 0
	j := 0

	db := p_parse.db
	v := p_parse.pVdbe
	if !db.init.imposterTable {
		for i = 0; i < int(p_tab.nCol); i++ {
			if (int(p_tab.aCol[i].colFlags) & 1) != 0 && (int(p_tab.aCol[i].notNull) == 0) {
				p_tab.aCol[i].notNull = u32(2)
			}
		}
		p_tab.tabFlags |= u32(2048)
	}
	if p_parse.u1.cr.addrCrTab {
		sqlite3_vdbe_change_p3(v, p_parse.u1.cr.addrCrTab, 2)
	}
	if int(p_tab.iPKey) >= 0 {
		p_list := &ExprList(0)
		ipk_token := Token{}
		sqlite3_token_init(&ipk_token, p_tab.aCol[p_tab.iPKey].zCnName)
		p_list = sqlite3_expr_list_append(p_parse, unsafe { nil }, sqlite3_expr_alloc(db, 60, &ipk_token, 0))
		if usize(p_list) == usize(0) {
			p_tab.tabFlags &= u32(~128)
			return
		}
		if (int(p_parse.eParseMode) >= 2) {
			sqlite3_rename_token_remap(p_parse, voidptr(c2v_at(&p_list.a[0], isize(0)).pExpr), voidptr(&p_tab.iPKey))
		}
		mut __c2v_lhs_tmp_106 := c2v_at(&p_list.a[0], isize(0))
		__c2v_lhs_tmp_106.fg.sortFlags = p_parse.iPkSortOrder
		p_tab.iPKey = I16(-1)
		sqlite3_create_index(p_parse, unsafe { nil }, unsafe { nil }, unsafe { nil }, p_list, int(p_tab.keyConf), unsafe { nil }, unsafe { nil }, 0, 0, U8(2))
		if p_parse.nErr {
			p_tab.tabFlags &= u32(~128)
			return
		}
		p_pk = sqlite3_primary_key_index(p_tab)
	} else {
		p_pk = sqlite3_primary_key_index(p_tab)
		j = 1
		for i = 1; i < int(p_pk.nKeyCol); i++ {
			if is_dup_column(p_pk, j, p_pk, i) {
				p_pk.nColumn--
			} else {
				0
				p_pk.azColl[j] = p_pk.azColl[i]
				p_pk.aSortOrder[j] = p_pk.aSortOrder[i]
				p_pk.aiColumn[j++] = p_pk.aiColumn[i]
			}
		}
		p_pk.nKeyCol = U16(j)
	}
	p_pk.isCovering = u32(1)
	if !db.init.imposterTable {
		p_pk.uniqNotNull = u32(1)
	}
	p_pk.nColumn = p_pk.nKeyCol
	n_pk = p_pk.nColumn
	if !isnil(v) && p_pk.tnum > Pgno(0) {
		sqlite3_vdbe_change_opcode(v, int(p_pk.tnum), U8(9))
	}
	p_pk.tnum = p_tab.tnum
	for p_idx = p_tab.pIndex; p_idx; p_idx = p_idx.pNext {
		n := 0
		if (int(p_idx.idxType) == 2) {
			continue
		}
		n = 0
		for i = 0; i < n_pk; i++ {
			if !is_dup_column(p_idx, int(p_idx.nKeyCol), p_pk, i) {
				0
				n++
			}
		}
		if n == 0 {
			p_idx.nColumn = p_idx.nKeyCol
			continue
		}
		if resize_index_object(p_parse, p_idx, int(p_idx.nKeyCol) + n) {
			return
		}
		i = 0
		for j = int(p_idx.nKeyCol); i < n_pk; i++ {
			if !is_dup_column(p_idx, int(p_idx.nKeyCol), p_pk, i) {
				0
				p_idx.aiColumn[j] = p_pk.aiColumn[i]
				p_idx.azColl[j] = p_pk.azColl[i]
				if p_pk.aSortOrder[i] {
					p_idx.bAscKeyBug = u32(1)
				}
				j++
			}
		}
	}
	n_extra = 0
	for i = 0; i < int(p_tab.nCol); i++ {
		if !has_column(p_pk.aiColumn, n_pk, i) && (int(p_tab.aCol[i].colFlags) & 32) == 0 {
			n_extra++
		}
	}
	if resize_index_object(p_parse, p_pk, n_pk + n_extra) {
		return
	}
	i = 0
	for j = n_pk; i < int(p_tab.nCol); i++ {
		if !has_column(p_pk.aiColumn, j, i) && (int(p_tab.aCol[i].colFlags) & 32) == 0 {
			z_coll := sqlite3_column_coll(unsafe { p_tab.aCol + i })
			p_pk.aiColumn[j] = I16(i)
			p_pk.azColl[j] = if z_coll { z_coll } else { &sqlite3StrBINARY[0] }
			j++
		}
	}
	recompute_columns_not_indexed(p_pk)
}

@[c:'sqlite3IsShadowTableOf']
fn sqlite3_is_shadow_table_of(db &Sqlite3, p_tab &Table, z_name &i8) int {
	n_name := 0
	p_mod := &Module(0)
	if !(int(p_tab.eTabType) == 1) {
		return 0
	}
	n_name = sqlite3_strlen30(p_tab.zName)
	if sqlite3_strnicmp(z_name, p_tab.zName, n_name) != 0 {
		return 0
	}
	if int(z_name[n_name]) != i8(`_`) {
		return 0
	}
	p_mod = &Module(sqlite3_hash_find(&db.aModule, p_tab.u.vtab.azArg[0]))
	if usize(p_mod) == usize(0) {
		return 0
	}
	if p_mod.pModule.iVersion < 3 {
		return 0
	}
	if isnil(p_mod.pModule.xShadowName) {
		return 0
	}
	return p_mod.pModule.xShadowName(z_name + n_name + 1)
}

@[c:'sqlite3MarkAllShadowTablesOf']
fn sqlite3_mark_all_shadow_tables_of(db &Sqlite3, p_tab &Table) {
	n_name := 0
	p_mod := &Module(0)
	k := &HashElem(0)
	p_mod = &Module(sqlite3_hash_find(&db.aModule, p_tab.u.vtab.azArg[0]))
	if usize(p_mod) == usize(0) {
		return
	}
	if (usize(p_mod.pModule) == usize(0)) {
		return
	}
	if p_mod.pModule.iVersion < 3 {
		return
	}
	if isnil(p_mod.pModule.xShadowName) {
		return
	}
	n_name = sqlite3_strlen30(p_tab.zName)
	for k = p_tab.pSchema.tblHash.first; k; k = k.next {
		p_other := &Table(k.data)
		if !(int(p_other.eTabType) == 0) {
			continue
		}
		if p_other.tabFlags & u32(4096) {
			continue
		}
		if sqlite3_strnicmp(p_other.zName, p_tab.zName, n_name) == 0 && int(p_other.zName[n_name]) == i8(`_`) && p_mod.pModule.xShadowName(p_other.zName + n_name + 1) {
			p_other.tabFlags |= u32(4096)
		}
	}
}

@[c:'sqlite3ShadowTableName']
fn sqlite3_shadow_table_name(db &Sqlite3, z_name &i8) int {
	z_tail := &i8(0)
	p_tab := &Table(0)
	z_copy := &i8(0)
	z_tail = C.strrchr(z_name, `_`)
	if usize(z_tail) == usize(0) {
		return 0
	}
	z_copy = sqlite3_db_str_nd_up(db, z_name, U64(int((i64((isize(z_tail) - isize(z_name)) / isize(sizeof(i8)))))))
	p_tab = unsafe { if z_copy { sqlite3_find_table(db, z_copy, nil) } else { &Table(nil) } }
	sqlite3_db_free(db, voidptr(z_copy))
	if usize(p_tab) == usize(0) {
		return 0
	}
	if !(int(p_tab.eTabType) == 1) {
		return 0
	}
	return sqlite3_is_shadow_table_of(db, p_tab, z_name)
}

@[c:'sqlite3EndTable']
fn sqlite3_end_table(p_parse &Parse, p_cons &Token, p_end &Token, tab_opts u32, p_select &Select) {
	p := &Table(0)
	db := p_parse.db
	i_db := 0
	p_idx := &Index(0)
	if usize(p_end) == usize(0) && usize(p_select) == usize(0) {
		return
	}
	p = p_parse.pNewTable
	if usize(p) == usize(0) {
		return
	}
	if usize(p_select) == usize(0) && sqlite3_shadow_table_name(db, p.zName) {
		p.tabFlags |= u32(4096)
	}
	if db.init.busy {
		if !isnil(p_select) || (!(int(p.eTabType) == 0) && db.init.newTnum) {
			sqlite3_error_msg(p_parse, c'')
			return
		}
		p.tnum = db.init.newTnum
		if p.tnum == Pgno(1) {
			p.tabFlags |= u32(1)
		}
	}
	if tab_opts & u32(65536) {
		ii := 0
		p.tabFlags |= u32(65536)
		for ii = 0; ii < int(p.nCol); ii++ {
			p_col := unsafe { p.aCol + ii }
			if int(p_col.eCType) == 0 {
				if int(p_col.colFlags) & 4 {
					sqlite3_error_msg(p_parse, c'unknown datatype for %s.%s: "%s"', voidptr(p.zName), voidptr(p_col.zCnName), voidptr(sqlite3_column_type_vdup1(p_col, c'')))
				} else {
					sqlite3_error_msg(p_parse, c'missing datatype for %s.%s', voidptr(p.zName), voidptr(p_col.zCnName))
				}
				return
			} else if int(p_col.eCType) == 1 {
				p_col.affinity = i8(65)
			}
			if (int(p_col.colFlags) & 1) != 0 && int(p.iPKey) != ii && int(p_col.notNull) == 0 {
				p_col.notNull = u32(2)
				p.tabFlags |= u32(2048)
			}
		}
	}
	if tab_opts & u32(128) {
		if (p.tabFlags & u32(8)) {
			sqlite3_error_msg(p_parse, c'AUTOINCREMENT not allowed on WITHOUT ROWID tables')
			return
		}
		if (p.tabFlags & u32(4)) == u32(0) {
			sqlite3_error_msg(p_parse, c'PRIMARY KEY missing on table %s', voidptr(p.zName))
			return
		}
		p.tabFlags |= u32(128 | 512)
		convert_to_without_rowid_table(p_parse, p)
	}
	i_db = sqlite3_schema_to_index(db, p.pSchema)
	if p.pCheck {
		sqlite3_resolve_self_reference(p_parse, p, 4, unsafe { nil }, p.pCheck)
		if p_parse.nErr {
			sqlite3_expr_list_delete(db, p.pCheck)
			p.pCheck = 0
		} else {
			0
		}
	}
	if p.tabFlags & u32(96) {
		ii := 0
		nng := 0

		0
		0
		for ii = 0; ii < int(p.nCol); ii++ {
			col_flags := u32(p.aCol[ii].colFlags)
			if (col_flags & u32(96)) != u32(0) {
				px := sqlite3_column_expr(p, unsafe { p.aCol + ii })
				0
				0
				if sqlite3_resolve_self_reference(p_parse, p, 8, px, unsafe { nil }) {
					sqlite3_column_set_expr(p_parse, p, unsafe { p.aCol + ii }, sqlite3_expr_alloc(db, 122, unsafe { nil }, 0))
				}
			} else {
				nng++
			}
		}
		if nng == 0 {
			sqlite3_error_msg(p_parse, c'must have at least one non-generated column')
			return
		}
	}
	estimate_table_width(p)
	for p_idx = p.pIndex; p_idx; p_idx = p_idx.pNext {
		estimate_index_width(p_idx)
	}
	if !db.init.busy {
		n := 0
		v := &Vdbe(0)
		z_type := &i8(0)
		z_type2 := &i8(0)
		z_stmt := &i8(0)
		v = sqlite3_get_vdbe(p_parse)
		if (usize(v) == usize(0)) {
			return
		}
		sqlite3_vdbe_add_op1(v, 124, 0)
		if (int(p.eTabType) == 0) {
			z_type = c'table'
			z_type2 = c'TABLE'
		} else {
			z_type = c'view'
			z_type2 = c'VIEW'
		}
		if p_select {
			dest := SelectDest{}
			reg_yield := 0
			addr_top := 0
			reg_rec := 0
			reg_rowid := 0
			addr_ins_loop := 0
			p_sel_tab := &Table(0)
			i_csr := 0
			if (int(p_parse.eParseMode) != 0) {
				p_parse.rc = 1
				p_parse.nErr++
				return
			}
			mut __c2v_postfix_value_11 := p_parse.nTab
			p_parse.nTab++
			i_csr = __c2v_postfix_value_11
			reg_yield = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			reg_rec = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			reg_rowid = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			sqlite3_may_abort(p_parse)
			sqlite3_vdbe_add_op3(v, 116, i_csr, p_parse.u1.cr.regRoot, i_db)
			sqlite3_vdbe_change_p5(v, U16(16))
			addr_top = sqlite3_vdbe_current_addr(v) + 1
			sqlite3_vdbe_add_op3(v, 11, reg_yield, 0, addr_top)
			if p_parse.nErr {
				return
			}
			p_sel_tab = sqlite3_result_set_of_select(p_parse, p_select, i8(65))
			if usize(p_sel_tab) == usize(0) {
				return
			}
			p.nNVCol = p_sel_tab.nCol
			p.nCol = p.nNVCol
			p.aCol = p_sel_tab.aCol
			p_sel_tab.nCol = I16(0)
			p_sel_tab.aCol = 0
			sqlite3_delete_table(db, p_sel_tab)
			sqlite3_select_dest_init(&dest, 11, reg_yield)
			sqlite3_select(p_parse, p_select, &dest)
			if p_parse.nErr {
				return
			}
			sqlite3_vdbe_end_coroutine(v, reg_yield)
			sqlite3_vdbe_jump_here(v, addr_top - 1)
			addr_ins_loop = sqlite3_vdbe_add_op1(v, 12, dest.iSDParm)
			0
			sqlite3_vdbe_add_op3(v, 99, dest.iSdst, dest.nSdst, reg_rec)
			sqlite3_table_affinity(v, p, 0)
			sqlite3_vdbe_add_op2(v, 129, i_csr, reg_rowid)
			sqlite3_vdbe_add_op3(v, 130, i_csr, reg_rec, reg_rowid)
			sqlite3_vdbe_goto(v, addr_ins_loop)
			sqlite3_vdbe_jump_here(v, addr_ins_loop)
			sqlite3_vdbe_add_op1(v, 124, i_csr)
		}
		if p_select {
			z_stmt = create_table_stmt(db, p)
		} else {
			p_end2 := if tab_opts { &p_parse.sLastToken } else { p_end }
			n = int((i64((isize(p_end2.z) - isize(p_parse.sNameToken.z)) / isize(sizeof(i8)))))
			if int(p_end2.z[0]) != i8(`;`) {
				n += p_end2.n
			}
			z_stmt = sqlite3_mp_rintf(db, c'CREATE %s %.*s', voidptr(z_type2), n, voidptr(p_parse.sNameToken.z))
		}
		sqlite3_nested_parse(p_parse, c"UPDATE %Q.sqlite_master SET type='%s', name=%Q, tbl_name=%Q, rootpage=#%d, sql=%Q WHERE rowid=#%d", voidptr(db.aDb[i_db].zDbSName), voidptr(z_type), voidptr(p.zName), voidptr(p.zName), p_parse.u1.cr.regRoot, voidptr(z_stmt), p_parse.u1.cr.regRowid)
		sqlite3_db_free(db, voidptr(z_stmt))
		sqlite3_change_cookie(p_parse, i_db)
		if (p.tabFlags & u32(8)) != u32(0) && !(int(p_parse.eParseMode) != 0) {
			p_db := unsafe { db.aDb + i_db }
			if usize(p_db.pSchema.pSeqTab) == usize(0) {
				sqlite3_nested_parse(p_parse, c'CREATE TABLE %Q.sqlite_sequence(name,seq)', voidptr(p_db.zDbSName))
			}
		}
		sqlite3_vdbe_add_parse_schema_op(v, i_db, sqlite3_mp_rintf(db, c"tbl_name='%q' AND type!='trigger'", voidptr(p.zName)), U16(0))
		if p.tabFlags & u32(96) {
			sqlite3_vdbe_add_op4(v, 150, 1, 0, 0, sqlite3_mp_rintf(db, c'SELECT*FROM"%w"."%w"', voidptr(db.aDb[i_db].zDbSName), voidptr(p.zName)), (-7))
		}
	}
	if db.init.busy {
		p_old := &Table(0)
		p_schema := p.pSchema
		p_old = sqlite3_hash_insert(&p_schema.tblHash, p.zName, voidptr(p))
		if p_old {
			sqlite3_oom_fault(db)
			return
		}
		p_parse.pNewTable = 0
		db.mDbFlags |= u32(1)
		if C.strcmp(p.zName, c'sqlite_sequence') == 0 {
			p.pSchema.pSeqTab = p
		}
	}
	if isnil(p_select) && (int(p.eTabType) == 0) {
		if usize(p_cons.z) == usize(0) {
			p_cons = p_end
		}
		p.u.tab.addColOffset = 13 + int((i64((isize(p_cons.z) - isize(p_parse.sNameToken.z)) / isize(sizeof(i8)))))
	}
}

@[c:'sqlite3CreateView']
fn sqlite3_create_view(p_parse &Parse, p_begin &Token, p_name1 &Token, p_name2 &Token, pcn_ames &ExprList, p_select &Select, is_temp int, no_err int) {
	p := &Table(0)
	n := 0
	z := &i8(0)
	s_end := Token{}
	s_fix := DbFixer{}
	p_name := unsafe { &Token(nil) }
	i_db := 0
	db := p_parse.db
	if int(p_parse.nVar) > 0 {
		sqlite3_error_msg(p_parse, c'parameters are not allowed in views')
		unsafe { goto create_view_fail
		 }
	}
	sqlite3_start_table(p_parse, p_name1, p_name2, is_temp, 1, 0, no_err)
	p = p_parse.pNewTable
	if usize(p) == usize(0) || p_parse.nErr {
		unsafe { goto create_view_fail
		 }
	}
	p.tabFlags |= u32(512)
	sqlite3_two_part_name(p_parse, p_name1, p_name2, &&Token(&&Token(c2v_address_of(&p_name))))
	i_db = sqlite3_schema_to_index(db, p.pSchema)
	sqlite3_fix_init(&s_fix, p_parse, i_db, c'view', p_name)
	if sqlite3_fix_select(&s_fix, p_select) {
		unsafe { goto create_view_fail
		 }
	}
	p_select.selFlags |= u32(2097152)
	if (int(p_parse.eParseMode) >= 2) {
		p.u.view.pSelect = p_select
		p_select = 0
	} else {
		p.u.view.pSelect = sqlite3_select_dup(db, p_select, 1)
	}
	p.pCheck = sqlite3_expr_list_dup(db, pcn_ames, 1)
	p.eTabType = U8(2)
	if db.mallocFailed {
		unsafe { goto create_view_fail
		 }
	}
	s_end = p_parse.sLastToken
	if int(s_end.z[0]) != i8(`;`) {
		c2v_pointer_prefix(voidptr(&s_end.z), s_end.z, isize(s_end.n))
	}
	s_end.n = u32(0)
	n = int((i64((isize(s_end.z) - isize(p_begin.z)) / isize(sizeof(i8)))))
	z = p_begin.z
	for (int(sqlite3CtypeMap[u8(z[n - 1])]) & 1) {
		n--
	}
	s_end.z = unsafe { z + (n - 1) }
	s_end.n = u32(1)
	sqlite3_end_table(p_parse, unsafe { nil }, &s_end, u32(0), unsafe { nil })
	create_view_fail:
	sqlite3_select_delete(db, p_select)
	if (int(p_parse.eParseMode) >= 2) {
		sqlite3_rename_exprlist_unmap(p_parse, pcn_ames)
	}
	sqlite3_expr_list_delete(db, pcn_ames)
	return
}

@[c:'viewGetColumnNames']
fn view_get_column_names(p_parse &Parse, p_table &Table) int {
	p_sel_tab := &Table(0)
	p_sel := &Select(0)
	n_err := 0
	db := p_parse.db
	rc := 0
	x_auth := unsafe { Sqlite3_xauth(nil) }
	if (int(p_table.eTabType) == 1) {
		db.nSchemaLock++
		rc = sqlite3_vtab_call_connect(p_parse, p_table)
		db.nSchemaLock--
		return rc
	}
	if int(p_table.nCol) < 0 {
		sqlite3_error_msg(p_parse, c'view %s is circularly defined', voidptr(p_table.zName))
		return 1
	}
	p_sel = sqlite3_select_dup(db, p_table.u.view.pSelect, 0)
	if p_sel {
		e_parse_mode := p_parse.eParseMode
		n_tab := p_parse.nTab
		n_select := p_parse.nSelect
		p_parse.eParseMode = U8(0)
		sqlite3_src_list_assign_cursors(p_parse, p_sel.pSrc)
		p_table.nCol = I16(-1)
		db.lookaside.bDisable++
		db.lookaside.sz = U16(0)
		x_auth = db.xAuth
		db.xAuth = 0
		p_sel_tab = sqlite3_result_set_of_select(p_parse, p_sel, i8(64))
		db.xAuth = x_auth
		p_parse.nTab = n_tab
		p_parse.nSelect = n_select
		if usize(p_sel_tab) == usize(0) {
			p_table.nCol = I16(0)
			n_err++
		} else if p_table.pCheck {
			sqlite3_columns_from_expr_list(p_parse, p_table.pCheck, &p_table.nCol, &&Column(&p_table.aCol))
			if p_parse.nErr == 0 && int(p_table.nCol) == p_sel.pEList.nExpr {
				sqlite3_subquery_column_types(p_parse, p_table, p_sel, i8(64))
			}
		} else {
			p_table.nCol = p_sel_tab.nCol
			p_table.aCol = p_sel_tab.aCol
			p_table.tabFlags |= (p_sel_tab.tabFlags & u32(98))
			p_sel_tab.nCol = I16(0)
			p_sel_tab.aCol = 0
		}
		p_table.nNVCol = p_table.nCol
		sqlite3_delete_table(db, p_sel_tab)
		sqlite3_select_delete(db, p_sel)
		db.lookaside.bDisable--
		db.lookaside.sz = U16(if db.lookaside.bDisable { 0 } else { int(db.lookaside.szTrue) })
		p_parse.eParseMode = e_parse_mode
	} else {
		n_err++
	}
	p_table.pSchema.schemaFlags |= 2
	if db.mallocFailed {
		sqlite3_delete_column_names(db, p_table)
	}
	return n_err + p_parse.nErr
}

@[c:'sqlite3ViewGetColumnNames']
fn sqlite3_view_get_column_names(p_parse &Parse, p_table &Table) int {
	if !(int(p_table.eTabType) == 1) && int(p_table.nCol) > 0 {
		return 0
	}
	return view_get_column_names(p_parse, p_table)
}

@[c:'sqliteViewResetAll']
fn sqlite_view_reset_all(db &Sqlite3, idx int) {
	i := &HashElem(0)
	if !((int(db.aDb[idx].pSchema.schemaFlags) & 2) == 2) {
		return
	}
	for i = db.aDb[idx].pSchema.tblHash.first; i; i = i.next {
		p_tab := &Table(i.data)
		if (int(p_tab.eTabType) == 2) {
			sqlite3_delete_column_names(db, p_tab)
		}
	}
	db.aDb[idx].pSchema.schemaFlags &= ~2
}

@[c:'sqlite3RootPageMoved']
fn sqlite3_root_page_moved(db &Sqlite3, i_db int, i_from Pgno, i_to Pgno) {
	p_elem := &HashElem(0)
	p_hash := &Hash(0)
	p_db := &Db(0)
	p_db = unsafe { db.aDb + i_db }
	p_hash = &p_db.pSchema.tblHash
	for p_elem = p_hash.first; p_elem; p_elem = p_elem.next {
		p_tab := &Table(p_elem.data)
		if p_tab.tnum == i_from {
			p_tab.tnum = i_to
		}
	}
	p_hash = &p_db.pSchema.idxHash
	for p_elem = p_hash.first; p_elem; p_elem = p_elem.next {
		p_idx := &Index(p_elem.data)
		if p_idx.tnum == i_from {
			p_idx.tnum = i_to
		}
	}
}

@[c:'destroyRootPage']
fn destroy_root_page(p_parse &Parse, i_table int, i_db int) {
	v := sqlite3_get_vdbe(p_parse)
	r1 := sqlite3_get_temp_reg(p_parse)
	if i_table < 2 {
		sqlite3_error_msg(p_parse, c'corrupt schema')
	}
	sqlite3_vdbe_add_op3(v, 146, i_table, r1, i_db)
	sqlite3_may_abort(p_parse)
	sqlite3_nested_parse(p_parse, c'UPDATE %Q.sqlite_master SET rootpage=%d WHERE #%d AND rootpage=#%d', voidptr(p_parse.db.aDb[i_db].zDbSName), i_table, r1, r1)
	sqlite3_release_temp_reg(p_parse, r1)
}

@[c:'destroyTable']
fn destroy_table(p_parse &Parse, p_tab &Table) {
	i_tab := p_tab.tnum
	i_destroyed := Pgno(0)
	for {
		p_idx := &Index(0)
		i_largest := Pgno(0)
		if i_destroyed == Pgno(0) || i_tab < i_destroyed {
			i_largest = i_tab
		}
		for p_idx = p_tab.pIndex; p_idx; p_idx = p_idx.pNext {
			i_idx := p_idx.tnum
			if (i_destroyed == Pgno(0) || (i_idx < i_destroyed)) && i_idx > i_largest {
				i_largest = i_idx
			}
		}
		if i_largest == Pgno(0) {
			return
		} else {
			i_db := sqlite3_schema_to_index(p_parse.db, p_tab.pSchema)
			destroy_root_page(p_parse, int(i_largest), i_db)
			i_destroyed = i_largest
		}
	}
}

@[c:'sqlite3ClearStatTables']
fn sqlite3_clear_stat_tables(p_parse &Parse, i_db int, z_type &i8, z_name &i8) {
	i := 0
	z_db_name := p_parse.db.aDb[i_db].zDbSName
	for i = 1; i <= 4; i++ {
		z_tab := [24]i8{}
		sqlite3_snprintf(int(sizeof([24]i8)), unsafe { &i8(&z_tab[0]) }, c'sqlite_stat%d', i)
		if sqlite3_find_table(p_parse.db, unsafe { &i8(&z_tab[0]) }, z_db_name) {
			sqlite3_nested_parse(p_parse, c'DELETE FROM %Q.%s WHERE %s=%Q', voidptr(z_db_name), voidptr(&z_tab[0]), voidptr(z_type), voidptr(z_name))
		}
	}
}

@[c:'sqlite3CodeDropTable']
fn sqlite3_code_drop_table(p_parse &Parse, p_tab &Table, i_db int, is_view int) {
	v := &Vdbe(0)
	db := p_parse.db
	p_trigger := &Trigger(0)
	p_db := unsafe { db.aDb + i_db }
	v = sqlite3_get_vdbe(p_parse)
	sqlite3_begin_write_operation(p_parse, 1, i_db)
	if (int(p_tab.eTabType) == 1) {
		sqlite3_vdbe_add_op0(v, 172)
	}
	p_trigger = sqlite3_trigger_list(p_parse, p_tab)
	for p_trigger {
		sqlite3_drop_trigger_ptr(p_parse, p_trigger)
		p_trigger = p_trigger.pNext
	}
	if p_tab.tabFlags & u32(8) {
		sqlite3_nested_parse(p_parse, c'DELETE FROM %Q.sqlite_sequence WHERE name=%Q', voidptr(p_db.zDbSName), voidptr(p_tab.zName))
	}
	sqlite3_nested_parse(p_parse, c"DELETE FROM %Q.sqlite_master WHERE tbl_name=%Q and type!='trigger'", voidptr(p_db.zDbSName), voidptr(p_tab.zName))
	if !is_view && !(int(p_tab.eTabType) == 1) {
		destroy_table(p_parse, p_tab)
	}
	if (int(p_tab.eTabType) == 1) {
		sqlite3_vdbe_add_op4(v, 174, i_db, 0, 0, p_tab.zName, 0)
		sqlite3_may_abort(p_parse)
	}
	sqlite3_vdbe_add_op4(v, 153, i_db, 0, 0, p_tab.zName, 0)
	sqlite3_change_cookie(p_parse, i_db)
	sqlite_view_reset_all(db, i_db)
}

@[c:'sqlite3ReadOnlyShadowTables']
fn sqlite3_read_only_shadow_tables(db &Sqlite3) int {
	if (db.flags & U64(268435456)) != U64(0) && usize(db.pVtabCtx) == usize(0) && db.nVdbeExec == 0 && !(db.nVTrans > 0 && usize(db.aVTrans) == usize(0)) {
		return 1
	}
	return 0
}

@[c:'tableMayNotBeDropped']
fn table_may_not_be_dropped(db &Sqlite3, p_tab &Table) int {
	if sqlite3_strnicmp(p_tab.zName, c'sqlite_', 7) == 0 {
		if sqlite3_strnicmp(p_tab.zName + 7, c'stat', 4) == 0 {
			return 0
		}
		if sqlite3_strnicmp(p_tab.zName + 7, c'parameters', 10) == 0 {
			return 0
		}
		return 1
	}
	if (p_tab.tabFlags & u32(4096)) != u32(0) && sqlite3_read_only_shadow_tables(db) {
		return 1
	}
	if p_tab.tabFlags & u32(32768) {
		return 1
	}
	return 0
}

@[c:'sqlite3DropTable']
fn sqlite3_drop_table(p_parse &Parse, p_name &SrcList, is_view int, no_err int) {
	p_tab := &Table(0)
	v := &Vdbe(0)
	db := p_parse.db
	i_db := 0
	if db.mallocFailed {
		unsafe { goto exit_drop_table
		 }
	}
	if sqlite3_read_schema(p_parse) {
		unsafe { goto exit_drop_table
		 }
	}
	if no_err {
		db.suppressErr++
	}
	p_tab = sqlite3_locate_table_item(p_parse, u32(is_view), unsafe { &p_name.a[0] + 0 })
	if no_err {
		db.suppressErr--
	}
	if usize(p_tab) == usize(0) {
		if no_err {
			sqlite3_code_verify_named_schema(p_parse, c2v_at(&p_name.a[0], isize(0)).u4.zDatabase)
			sqlite3_force_not_read_only(p_parse)
		}
		unsafe { goto exit_drop_table
		 }
	}
	i_db = sqlite3_schema_to_index(db, p_tab.pSchema)
	if (int(p_tab.eTabType) == 1) && sqlite3_view_get_column_names(p_parse, p_tab) {
		unsafe { goto exit_drop_table
		 }
	}
	code := 0
	z_tab := (if (!0) && (i_db == 1) { c'sqlite_temp_master' } else { c'sqlite_master' })
	z_db := db.aDb[i_db].zDbSName
	z_arg2 := unsafe { &i8(nil) }
	if sqlite3_auth_check(p_parse, 9, z_tab, unsafe { nil }, z_db) {
		unsafe { goto exit_drop_table
		 }
	}
	if is_view {
		if !0 && i_db == 1 {
			code = 15
		} else {
			code = 17
		}
	} else if (int(p_tab.eTabType) == 1) {
		code = 30
		z_arg2 = sqlite3_get_vt_able(db, p_tab).pMod.zName
	} else {
		if !0 && i_db == 1 {
			code = 13
		} else {
			code = 11
		}
	}
	if sqlite3_auth_check(p_parse, code, p_tab.zName, z_arg2, z_db) {
		unsafe { goto exit_drop_table
		 }
	}
	if sqlite3_auth_check(p_parse, 9, p_tab.zName, unsafe { nil }, z_db) {
		unsafe { goto exit_drop_table
		 }
	}
	if table_may_not_be_dropped(db, p_tab) {
		sqlite3_error_msg(p_parse, c'table %s may not be dropped', voidptr(p_tab.zName))
		unsafe { goto exit_drop_table
		 }
	}
	if is_view && !(int(p_tab.eTabType) == 2) {
		sqlite3_error_msg(p_parse, c'use DROP TABLE to delete table %s', voidptr(p_tab.zName))
		unsafe { goto exit_drop_table
		 }
	}
	if !is_view && (int(p_tab.eTabType) == 2) {
		sqlite3_error_msg(p_parse, c'use DROP VIEW to delete view %s', voidptr(p_tab.zName))
		unsafe { goto exit_drop_table
		 }
	}
	v = sqlite3_get_vdbe(p_parse)
	if v {
		sqlite3_begin_write_operation(p_parse, 1, i_db)
		if !is_view {
			sqlite3_clear_stat_tables(p_parse, i_db, c'tbl', p_tab.zName)
			sqlite3_fk_drop_table(p_parse, p_name, p_tab)
		}
		sqlite3_code_drop_table(p_parse, p_tab, i_db, is_view)
	}
	exit_drop_table:
	sqlite3_src_list_delete(db, p_name)
}

@[c:'sqlite3CreateForeignKey']
fn sqlite3_create_foreign_key(p_parse &Parse, p_from_col &ExprList, p_to &Token, p_to_col &ExprList, flags int) {
	db := p_parse.db
	pfk_ey := unsafe { &FKey(nil) }
	p_next_to := &FKey(0)
	p := p_parse.pNewTable
	n_byte := I64(0)
	i := 0
	n_col := 0
	z := &i8(0)
	if usize(p) == usize(0) || (int(p_parse.eParseMode) == 1) {
		unsafe { goto fk_end
		 }
	}
	if usize(p_from_col) == usize(0) {
		i_col := int(p.nCol) - 1
		if (i_col < 0) {
			unsafe { goto fk_end
			 }
		}
		if !isnil(p_to_col) && p_to_col.nExpr != 1 {
			sqlite3_error_msg(p_parse, c'foreign key on %s should reference only one column of table %T', voidptr(p.aCol[i_col].zCnName), voidptr(p_to))
			unsafe { goto fk_end
			 }
		}
		n_col = 1
	} else if !isnil(p_to_col) && p_to_col.nExpr != p_from_col.nExpr {
		sqlite3_error_msg(p_parse, c'number of columns in foreign key does not match the number of columns in the referenced table')
		unsafe { goto fk_end
		 }
	} else {
		n_col = p_from_col.nExpr
	}
	n_byte = I64(((u64(usize(__offsetof(FKey, aCol)))) + u64(n_col) * sizeof(SColMap)) + u64(p_to.n) + u64(1))
	if p_to_col {
		for i = 0; i < p_to_col.nExpr; i++ {
			n_byte += I64(sqlite3_strlen30(c2v_at(&p_to_col.a[0], isize(i)).zEName) + 1)
		}
	}
	pfk_ey = sqlite3_db_malloc_zero(db, U64(n_byte))
	if usize(pfk_ey) == usize(0) {
		unsafe { goto fk_end
		 }
	}
	pfk_ey.pFrom = p
	pfk_ey.pNextFrom = p.u.tab.pFKey
	z = &i8(voidptr(unsafe { &pfk_ey.aCol[0] + n_col }))
	pfk_ey.zTo = z
	if (int(p_parse.eParseMode) >= 2) {
		sqlite3_rename_token_map(p_parse, voidptr(z), p_to)
	}
	C.memcpy(voidptr(z), voidptr(p_to.z), u64(p_to.n))
	z[p_to.n] = i8(0)
	sqlite3_dequote(z)
	c2v_pointer_prefix(voidptr(&z), z, isize(p_to.n + u32(1)))
	pfk_ey.nCol = n_col
	if usize(p_from_col) == usize(0) {
		mut __c2v_lhs_tmp_107 := c2v_at(&pfk_ey.aCol[0], isize(0))
		__c2v_lhs_tmp_107.iFrom = int(p.nCol) - 1
	} else {
		for i = 0; i < n_col; i++ {
			j := 0
			for j = 0; j < int(p.nCol); j++ {
				if sqlite3_str_ic_mp(p.aCol[j].zCnName, c2v_at(&p_from_col.a[0], isize(i)).zEName) == 0 {
					mut __c2v_lhs_tmp_108 := c2v_at(&pfk_ey.aCol[0], isize(i))
					__c2v_lhs_tmp_108.iFrom = j
					break
				}
			}
			if j >= int(p.nCol) {
				sqlite3_error_msg(p_parse, c'unknown column "%s" in foreign key definition', voidptr(c2v_at(&p_from_col.a[0], isize(i)).zEName))
				unsafe { goto fk_end
				 }
			}
			if (int(p_parse.eParseMode) >= 2) {
				sqlite3_rename_token_remap(p_parse, voidptr(unsafe { &pfk_ey.aCol[0] + i }), voidptr(c2v_at(&p_from_col.a[0], isize(i)).zEName))
			}
		}
	}
	if p_to_col {
		for i = 0; i < n_col; i++ {
			n := sqlite3_strlen30(c2v_at(&p_to_col.a[0], isize(i)).zEName)
			mut __c2v_lhs_tmp_109 := c2v_at(&pfk_ey.aCol[0], isize(i))
			__c2v_lhs_tmp_109.zCol = z
			if (int(p_parse.eParseMode) >= 2) {
				sqlite3_rename_token_remap(p_parse, voidptr(z), voidptr(c2v_at(&p_to_col.a[0], isize(i)).zEName))
			}
			C.memcpy(voidptr(z), voidptr(c2v_at(&p_to_col.a[0], isize(i)).zEName), u64(n))
			z[n] = i8(0)
			c2v_pointer_prefix(voidptr(&z), z, isize(n + 1))
		}
	}
	pfk_ey.isDeferred = U8(0)
	pfk_ey.aAction[0] = U8((flags & 255))
	pfk_ey.aAction[1] = U8(((flags >> 8) & 255))
	p_next_to = &FKey(sqlite3_hash_insert(&p.pSchema.fkeyHash, pfk_ey.zTo, voidptr(pfk_ey)))
	if usize(p_next_to) == usize(pfk_ey) {
		sqlite3_oom_fault(db)
		unsafe { goto fk_end
		 }
	}
	if p_next_to {
		pfk_ey.pNextTo = p_next_to
		p_next_to.pPrevTo = pfk_ey
	}
	p.u.tab.pFKey = pfk_ey
	pfk_ey = 0
	fk_end:
	sqlite3_db_free(db, voidptr(pfk_ey))
	sqlite3_expr_list_delete(db, p_from_col)
	sqlite3_expr_list_delete(db, p_to_col)
}

@[c:'sqlite3DeferForeignKey']
fn sqlite3_defer_foreign_key(p_parse &Parse, is_deferred int) {
	p_tab := &Table(0)
	pfk_ey := &FKey(0)
	p_tab = p_parse.pNewTable
	if usize(p_tab) == usize(0) {
		return
	}
	if (!(int(p_tab.eTabType) == 0)) {
		return
	}
	pfk_ey = p_tab.u.tab.pFKey
	if usize(pfk_ey) == usize(0) {
		return
	}
	pfk_ey.isDeferred = U8(is_deferred)
}

@[c:'sqlite3RefillIndex']
fn sqlite3_refill_index(p_parse &Parse, p_index &Index, mem_root_page int) {
	p_tab := p_index.pTable
	i_tab := p_parse.nTab++
	i_idx := p_parse.nTab++
	i_sorter := 0
	addr1 := 0
	addr2 := 0
	tnum := Pgno(0)
	i_part_idx_label := 0
	v := &Vdbe(0)
	p_key := &KeyInfo(0)
	reg_record := 0
	db := p_parse.db
	i_db := sqlite3_schema_to_index(db, p_index.pSchema)
	if sqlite3_auth_check(p_parse, 27, p_index.zName, unsafe { nil }, db.aDb[i_db].zDbSName) {
		return
	}
	sqlite3_table_lock(p_parse, i_db, p_tab.tnum, U8(1), p_tab.zName)
	v = sqlite3_get_vdbe(p_parse)
	if usize(v) == usize(0) {
		return
	}
	if mem_root_page >= 0 {
		tnum = Pgno(mem_root_page)
	} else {
		tnum = p_index.tnum
	}
	p_key = sqlite3_key_info_of_index(p_parse, p_index)
	mut __c2v_postfix_value_12 := p_parse.nTab
	p_parse.nTab++
	i_sorter = __c2v_postfix_value_12
	sqlite3_vdbe_add_op4(v, 121, i_sorter, 0, int(p_index.nKeyCol), &i8(voidptr(sqlite3_key_info_ref(p_key))), (-9))
	sqlite3_open_table(p_parse, i_tab, i_db, p_tab, 114)
	addr1 = sqlite3_vdbe_add_op2(v, 36, i_tab, 0)
	0
	reg_record = sqlite3_get_temp_reg(p_parse)
	sqlite3_multi_write(p_parse)
	sqlite3_generate_index_key(p_parse, p_index, i_tab, reg_record, 0, &i_part_idx_label, unsafe { nil }, 0)
	sqlite3_vdbe_add_op2(v, 141, i_sorter, reg_record)
	sqlite3_resolve_part_idx_label(p_parse, i_part_idx_label)
	sqlite3_vdbe_add_op2(v, 40, i_tab, addr1 + 1)
	0
	sqlite3_vdbe_jump_here(v, addr1)
	if mem_root_page < 0 {
		sqlite3_vdbe_add_op2(v, 147, int(tnum), i_db)
	}
	sqlite3_vdbe_add_op4(v, 116, i_idx, int(tnum), i_db, &i8(voidptr(p_key)), (-9))
	sqlite3_vdbe_change_p5(v, U16(1 | (if (mem_root_page >= 0) { 16 } else { 0 })))
	addr1 = sqlite3_vdbe_add_op2(v, 34, i_sorter, 0)
	0
	if (int(p_index.onError) != 0) {
		j2 := sqlite3_vdbe_goto(v, 1)
		addr2 = sqlite3_vdbe_current_addr(v)
		0
		sqlite3_vdbe_add_op4_int(v, 134, i_sorter, j2, reg_record, int(p_index.nKeyCol))
		0
		sqlite3_unique_constraint(p_parse, 2, p_index)
		sqlite3_vdbe_jump_here(v, j2)
	} else {
		sqlite3_may_abort(p_parse)
		addr2 = sqlite3_vdbe_current_addr(v)
	}
	sqlite3_vdbe_add_op3(v, 135, i_sorter, reg_record, i_idx)
	if !p_index.bAscKeyBug {
		sqlite3_vdbe_add_op1(v, 139, i_idx)
	}
	sqlite3_vdbe_add_op2(v, 140, i_idx, reg_record)
	sqlite3_vdbe_change_p5(v, U16(16))
	sqlite3_release_temp_reg(p_parse, reg_record)
	sqlite3_vdbe_add_op2(v, 38, i_sorter, addr2)
	0
	sqlite3_vdbe_jump_here(v, addr1)
	sqlite3_vdbe_add_op1(v, 124, i_tab)
	sqlite3_vdbe_add_op1(v, 124, i_idx)
	sqlite3_vdbe_add_op1(v, 124, i_sorter)
}

@[c:'sqlite3AllocateIndexObject']
fn sqlite3_allocate_index_object(db &Sqlite3, n_col int, n_extra int, pp_extra &&u8) &Index {
	p := &Index(0)
	n_byte := I64(0)
	n_byte = I64((((sizeof(Index)) + u64(7)) & u64(~7)) + (((sizeof(voidptr) * u64(n_col)) + u64(7)) & u64(~7)) + (((sizeof(LogEst) * u64((n_col + 1)) + sizeof(I16) * u64(n_col) + sizeof(U8) * u64(n_col)) + u64(7)) & u64(~7)))
	p = sqlite3_db_malloc_zero(db, U64(n_byte + I64(n_extra)))
	if p {
		p_extra := (&i8(voidptr(p))) + (((sizeof(Index)) + u64(7)) & u64(~7))
		p.azColl = &&u8(voidptr(p_extra))
		c2v_pointer_prefix(voidptr(&p_extra), p_extra, isize((((sizeof(voidptr) * u64(n_col)) + u64(7)) & u64(~7))))
		p.aiRowLogEst = &LogEst(voidptr(p_extra))
		c2v_pointer_prefix(voidptr(&p_extra), p_extra, isize(sizeof(LogEst) * u64((n_col + 1))))
		p.aiColumn = &I16(voidptr(p_extra))
		c2v_pointer_prefix(voidptr(&p_extra), p_extra, isize(sizeof(I16) * u64(n_col)))
		p.aSortOrder = &U8(voidptr(p_extra))
		p.nColumn = U16(n_col)
		p.nKeyCol = U16((n_col - 1))
		unsafe { *pp_extra = (&i8(voidptr(p))) + n_byte }
	}
	return p
}

@[c:'sqlite3HasExplicitNulls']
fn sqlite3_has_explicit_nulls(p_parse &Parse, p_list &ExprList) int {
	if p_list {
		i := 0
		for i = 0; i < p_list.nExpr; i++ {
			if c2v_at(&p_list.a[0], isize(i)).fg.bNulls {
				sf := c2v_at(&p_list.a[0], isize(i)).fg.sortFlags
				sqlite3_error_msg(p_parse, c'unsupported use of NULLS %s', voidptr(if (int(sf) == 0 || int(sf) == 3) {
					c'FIRST'
				} else {
					c'LAST'
				}))
				return 1
			}
		}
	}
	return 0
}

@[c:'sqlite3CreateIndex']
fn sqlite3_create_index(p_parse &Parse, p_name1 &Token, p_name2 &Token, p_tbl_name &SrcList, p_list &ExprList, on_error int, p_start &Token, ppi_where &Expr, sort_order int, if_not_exist int, idx_type U8) {
	p_tab := unsafe { &Table(nil) }
	p_index := unsafe { &Index(nil) }
	z_name := unsafe { &i8(nil) }
	n_name := 0
	i := 0
	j := 0

	s_fix := DbFixer{}
	sort_order_mask := 0
	db := p_parse.db
	p_db := &Db(0)
	i_db := 0
	p_name := unsafe { &Token(nil) }
	p_list_item := &ExprList_item(0)
	n_extra := 0
	n_extra_col := 0
	z_extra := unsafe { &i8(nil) }
	p_pk := unsafe { &Index(nil) }
	if p_parse.nErr {
		unsafe { goto exit_create_index
		 }
	}
	if (int(p_parse.eParseMode) == 1) && int(idx_type) != 2 {
		unsafe { goto exit_create_index
		 }
	}
	if 0 != sqlite3_read_schema(p_parse) {
		unsafe { goto exit_create_index
		 }
	}
	if sqlite3_has_explicit_nulls(p_parse, p_list) {
		unsafe { goto exit_create_index
		 }
	}
	if usize(p_tbl_name) != usize(0) {
		i_db = sqlite3_two_part_name(p_parse, p_name1, p_name2, &&Token(&&Token(c2v_address_of(&p_name))))
		if i_db < 0 {
			unsafe { goto exit_create_index
			 }
		}
		if !db.init.busy {
			p_tab = sqlite3_src_list_lookup(p_parse, p_tbl_name)
			if p_name2.n == u32(0) && !isnil(p_tab) && usize(p_tab.pSchema) == usize(db.aDb[1].pSchema) {
				i_db = 1
			}
		}
		sqlite3_fix_init(&s_fix, p_parse, i_db, c'index', p_name)
		if sqlite3_fix_src_list(&s_fix, p_tbl_name) {
		}
		p_tab = sqlite3_locate_table_item(p_parse, u32(0), unsafe { &p_tbl_name.a[0] + 0 })
		if usize(p_tab) == usize(0) {
			unsafe { goto exit_create_index
			 }
		}
		if i_db == 1 && usize(db.aDb[i_db].pSchema) != usize(p_tab.pSchema) {
			sqlite3_error_msg(p_parse, c'cannot create a TEMP index on non-TEMP table "%s"', voidptr(p_tab.zName))
			unsafe { goto exit_create_index
			 }
		}
		if !((p_tab.tabFlags & u32(128)) == u32(0)) {
			p_pk = sqlite3_primary_key_index(p_tab)
		}
	} else {
		p_tab = p_parse.pNewTable
		if isnil(p_tab) {
			unsafe { goto exit_create_index
			 }
		}
		i_db = sqlite3_schema_to_index(db, p_tab.pSchema)
	}
	p_db = unsafe { db.aDb + i_db }
	if sqlite3_strnicmp(p_tab.zName, c'sqlite_', 7) == 0 && int(db.init.busy) == 0 && usize(p_tbl_name) != usize(0) {
		sqlite3_error_msg(p_parse, c'table %s may not be indexed', voidptr(p_tab.zName))
		unsafe { goto exit_create_index
		 }
	}
	if (int(p_tab.eTabType) == 2) {
		sqlite3_error_msg(p_parse, c'views may not be indexed')
		unsafe { goto exit_create_index
		 }
	}
	if (int(p_tab.eTabType) == 1) {
		sqlite3_error_msg(p_parse, c'virtual tables may not be indexed')
		unsafe { goto exit_create_index
		 }
	}
	if p_name {
		z_name = sqlite3_name_from_token(db, p_name)
		if usize(z_name) == usize(0) {
			unsafe { goto exit_create_index
			 }
		}
		if 0 != sqlite3_check_object_name(p_parse, z_name, c'index', p_tab.zName) {
			unsafe { goto exit_create_index
			 }
		}
		if !(int(p_parse.eParseMode) >= 2) {
			if !db.init.busy {
				if usize(sqlite3_find_table(db, z_name, p_db.zDbSName)) != usize(0) {
					sqlite3_error_msg(p_parse, c'there is already a table named %s', voidptr(z_name))
					unsafe { goto exit_create_index
					 }
				}
			}
			if usize(sqlite3_find_index(db, z_name, p_db.zDbSName)) != usize(0) {
				if !if_not_exist {
					sqlite3_error_msg(p_parse, c'index %s already exists', voidptr(z_name))
				} else {
					sqlite3_code_verify_schema(p_parse, i_db)
					sqlite3_force_not_read_only(p_parse)
				}
				unsafe { goto exit_create_index
				 }
			}
		}
	} else {
		n := 0
		p_loop := &Index(0)
		p_loop = p_tab.pIndex
		for n = 1; p_loop;  {
			p_loop = p_loop.pNext
			n++
		}
		z_name = sqlite3_mp_rintf(db, c'sqlite_autoindex_%s_%d', voidptr(p_tab.zName), n)
		if usize(z_name) == usize(0) {
			unsafe { goto exit_create_index
			 }
		}
		if (int(p_parse.eParseMode) != 0) {
			z_name[7]++
		}
	}
	if !(int(p_parse.eParseMode) >= 2) {
		z_db := p_db.zDbSName
		if sqlite3_auth_check(p_parse, 18, unsafe { if (!0) && (i_db == 1) {
			c'sqlite_temp_master'
		} else {
			c'sqlite_master'
		} }, unsafe { nil }, z_db) {
			unsafe { goto exit_create_index
			 }
		}
		i = 1
		if !0 && i_db == 1 {
			i = 3
		}
		if sqlite3_auth_check(p_parse, i, z_name, p_tab.zName, z_db) {
			unsafe { goto exit_create_index
			 }
		}
	}
	if usize(p_list) == usize(0) {
		prev_col := Token{}
		p_col := unsafe { p_tab.aCol + (int(p_tab.nCol) - 1) }
		p_col.colFlags |= 8
		sqlite3_token_init(&prev_col, p_col.zCnName)
		p_list = sqlite3_expr_list_append(p_parse, unsafe { nil }, sqlite3_expr_alloc(db, 60, &prev_col, 0))
		if usize(p_list) == usize(0) {
			unsafe { goto exit_create_index
			 }
		}
		sqlite3_expr_list_set_sort_order(p_list, sort_order, -1)
	} else {
		sqlite3_expr_list_check_length(p_parse, p_list, c'index')
		if p_parse.nErr {
			unsafe { goto exit_create_index
			 }
		}
	}
	for i = 0; i < p_list.nExpr; i++ {
		p_expr := c2v_at(&p_list.a[0], isize(i)).pExpr
		if int(p_expr.op) == 114 {
			n_extra += (1 + sqlite3_strlen30(p_expr.u.zToken))
		}
	}
	n_name = sqlite3_strlen30(z_name)
	n_extra_col = if p_pk { int(p_pk.nKeyCol) } else { 1 }
	p_index = sqlite3_allocate_index_object(db, p_list.nExpr + n_extra_col, n_name + n_extra + 1, &&u8(&&i8(c2v_address_of(&z_extra))))
	if db.mallocFailed {
		unsafe { goto exit_create_index
		 }
	}
	p_index.zName = z_extra
	c2v_pointer_prefix(voidptr(&z_extra), z_extra, isize(n_name + 1))
	C.memcpy(voidptr(p_index.zName), voidptr(z_name), u64(n_name + 1))
	p_index.pTable = p_tab
	p_index.onError = U8(on_error)
	p_index.uniqNotNull = u32(on_error != 0)
	p_index.idxType = u32(idx_type)
	p_index.pSchema = db.aDb[i_db].pSchema
	p_index.nKeyCol = U16(p_list.nExpr)
	if ppi_where {
		sqlite3_resolve_self_reference(p_parse, p_tab, 2, ppi_where, unsafe { nil })
		p_index.pPartIdxWhere = ppi_where
		ppi_where = 0
	}
	if int(p_db.pSchema.file_format) >= 4 {
		sort_order_mask = -1
	} else {
		sort_order_mask = 0
	}
	p_list_item = unsafe { &p_list.a[0] }
	if (int(p_parse.eParseMode) >= 2) {
		p_index.aColExpr = p_list
		p_list = 0
	}
	for i = 0; i < int(p_index.nKeyCol); i++ {
		pce_xpr := &Expr(0)
		requested_sort_order := 0
		z_coll := &i8(0)
		sqlite3_string_to_id(p_list_item.pExpr)
		sqlite3_resolve_self_reference(p_parse, p_tab, 32, p_list_item.pExpr, unsafe { nil })
		if p_parse.nErr {
			unsafe { goto exit_create_index
			 }
		}
		pce_xpr = sqlite3_expr_skip_collate(p_list_item.pExpr)
		if int(pce_xpr.op) != 168 {
			if usize(p_tab) == usize(p_parse.pNewTable) {
				sqlite3_error_msg(p_parse, c'expressions prohibited in PRIMARY KEY and UNIQUE constraints')
				unsafe { goto exit_create_index
				 }
			}
			if usize(p_index.aColExpr) == usize(0) {
				p_index.aColExpr = p_list
				p_list = 0
			}
			j = (-2)
			p_index.aiColumn[i] = I16((-2))
			p_index.uniqNotNull = u32(0)
			p_index.bHasExpr = u32(1)
		} else {
			j = int(pce_xpr.iColumn)
			if j < 0 {
				j = int(p_tab.iPKey)
			} else {
				if int(p_tab.aCol[j].notNull) == 0 {
					p_index.uniqNotNull = u32(0)
				}
				if int(p_tab.aCol[j].colFlags) & 32 {
					p_index.bHasVCol = u32(1)
					p_index.bHasExpr = u32(1)
				}
			}
			p_index.aiColumn[i] = I16(j)
		}
		z_coll = 0
		if int(p_list_item.pExpr.op) == 114 {
			n_coll := 0
			z_coll = p_list_item.pExpr.u.zToken
			n_coll = sqlite3_strlen30(z_coll) + 1
			C.memcpy(voidptr(z_extra), voidptr(z_coll), u64(n_coll))
			z_coll = z_extra
			c2v_pointer_prefix(voidptr(&z_extra), z_extra, isize(n_coll))
			n_extra -= n_coll
		} else if j >= 0 {
			z_coll = sqlite3_column_coll(unsafe { p_tab.aCol + j })
		}
		if isnil(z_coll) {
			z_coll = unsafe { &sqlite3StrBINARY[0] }
		}
		if !db.init.busy && isnil(sqlite3_locate_coll_seq(p_parse, z_coll)) {
			unsafe { goto exit_create_index
			 }
		}
		p_index.azColl[i] = z_coll
		requested_sort_order = int(p_list_item.fg.sortFlags) & sort_order_mask
		p_index.aSortOrder[i] = U8(requested_sort_order)
		c2v_pointer_postfix(voidptr(&p_list_item), p_list_item, isize(1))
	}
	if p_pk {
		for j = 0; j < int(p_pk.nKeyCol); j++ {
			x := int(p_pk.aiColumn[j])
			if is_dup_column(p_index, int(p_index.nKeyCol), p_pk, j) {
				p_index.nColumn--
			} else {
				0
				p_index.aiColumn[i] = I16(x)
				p_index.azColl[i] = p_pk.azColl[j]
				p_index.aSortOrder[i] = p_pk.aSortOrder[j]
				i++
			}
		}
	} else {
		p_index.aiColumn[i] = I16((-1))
		p_index.azColl[i] = unsafe { &sqlite3StrBINARY[0] }
	}
	sqlite3_default_row_est(p_index)
	if usize(p_parse.pNewTable) == usize(0) {
		estimate_index_width(p_index)
	}
	recompute_columns_not_indexed(p_index)
	if usize(p_tbl_name) != usize(0) && int(p_index.nColumn) >= int(p_tab.nCol) {
		p_index.isCovering = u32(1)
		for j = 0; j < int(p_tab.nCol); j++ {
			if j == int(p_tab.iPKey) {
				continue
			}
			if sqlite3_table_column_to_index(p_index, j) >= 0 {
				continue
			}
			p_index.isCovering = u32(0)
			break
		}
	}
	if usize(p_tab) == usize(p_parse.pNewTable) {
		p_idx := &Index(0)
		for p_idx = p_tab.pIndex; p_idx; p_idx = p_idx.pNext {
			k := 0
			if int(p_idx.nKeyCol) != int(p_index.nKeyCol) {
				continue
			}
			for k = 0; k < int(p_idx.nKeyCol); k++ {
				z1 := &i8(0)
				z2 := &i8(0)
				if int(p_idx.aiColumn[k]) != int(p_index.aiColumn[k]) {
					break
				}
				z1 = p_idx.azColl[k]
				z2 = p_index.azColl[k]
				if sqlite3_str_ic_mp(z1, z2) {
					break
				}
			}
			if k == int(p_idx.nKeyCol) {
				if int(p_idx.onError) != int(p_index.onError) {
					if !(int(p_idx.onError) == 11 || int(p_index.onError) == 11) {
						sqlite3_error_msg(p_parse, c'conflicting ON CONFLICT clauses specified', 0)
					}
					if int(p_idx.onError) == 11 {
						p_idx.onError = p_index.onError
					}
				}
				if int(idx_type) == 2 {
					p_idx.idxType = u32(idx_type)
				}
				if (int(p_parse.eParseMode) >= 2) {
					p_index.pNext = p_parse.pNewIndex
					p_parse.pNewIndex = p_index
					p_index = 0
				}
				unsafe { goto exit_create_index
				 }
			}
		}
	}
	if !(int(p_parse.eParseMode) >= 2) {
		if db.init.busy {
			p := &Index(0)
			if usize(p_tbl_name) != usize(0) {
				p_index.tnum = db.init.newTnum
				if sqlite3_index_has_duplicate_root_page(p_index) {
					sqlite3_error_msg(p_parse, c'invalid rootpage')
					p_parse.rc = sqlite3_corrupt_error(4396)
					unsafe { goto exit_create_index
					 }
				}
			}
			p = sqlite3_hash_insert(&p_index.pSchema.idxHash, p_index.zName, voidptr(p_index))
			if p {
				sqlite3_oom_fault(db)
				unsafe { goto exit_create_index
				 }
			}
			db.mDbFlags |= u32(1)
		} else if ((p_tab.tabFlags & u32(128)) == u32(0)) || usize(p_tbl_name) != usize(0) {
			v := &Vdbe(0)
			z_stmt := &i8(0)
			i_mem := c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			v = sqlite3_get_vdbe(p_parse)
			if usize(v) == usize(0) {
				unsafe { goto exit_create_index
				 }
			}
			sqlite3_begin_write_operation(p_parse, 1, i_db)
			p_index.tnum = Pgno(sqlite3_vdbe_add_op0(v, 189))
			sqlite3_vdbe_add_op3(v, 149, i_db, i_mem, 2)
			if p_start {
				n := int(u32(int((i64((isize(p_parse.sLastToken.z) - isize(p_name.z)) / isize(sizeof(i8)))))) + p_parse.sLastToken.n)
				if int(p_name.z[n - 1]) == i8(`;`) {
					n--
				}
				z_stmt = sqlite3_mp_rintf(db, c'CREATE%s INDEX %.*s', voidptr(if on_error == 0 {
					c''
				} else {
					c' UNIQUE'
				}), n, voidptr(p_name.z))
			} else {
				z_stmt = 0
			}
			sqlite3_nested_parse(p_parse, c"INSERT INTO %Q.sqlite_master VALUES('index',%Q,%Q,#%d,%Q);", voidptr(db.aDb[i_db].zDbSName), voidptr(p_index.zName), voidptr(p_tab.zName), i_mem, voidptr(z_stmt))
			sqlite3_db_free(db, voidptr(z_stmt))
			if p_tbl_name {
				sqlite3_refill_index(p_parse, p_index, i_mem)
				sqlite3_change_cookie(p_parse, i_db)
				sqlite3_vdbe_add_parse_schema_op(v, i_db, sqlite3_mp_rintf(db, c"name='%q' AND type='index'", voidptr(p_index.zName)), U16(0))
				sqlite3_vdbe_add_op2(v, 168, 0, 1)
			}
			sqlite3_vdbe_jump_here(v, int(p_index.tnum))
		}
	}
	if int(db.init.busy) || usize(p_tbl_name) == usize(0) {
		p_index.pNext = p_tab.pIndex
		p_tab.pIndex = p_index
		p_index = 0
	} else if (int(p_parse.eParseMode) >= 2) {
		p_parse.pNewIndex = p_index
		p_index = 0
	}
	exit_create_index:
	if p_index {
		sqlite3_free_index(db, p_index)
	}
	if p_tab {
		pp_from := &&Index(0)
		p_this := &Index(0)
		for pp_from = &p_tab.pIndex; true; pp_from = &p_this.pNext {
			p_this = unsafe { *pp_from }
			if !(usize(p_this) != usize(0)) {
				break
			}
			p_next := &Index(0)
			if int(p_this.onError) != 5 {
				continue
			}
			for {
				p_next = p_this.pNext
				if !(usize(p_next) != usize(0) && int(p_next.onError) != 5) {
					break
				}
				unsafe { *pp_from = p_next }
				p_this.pNext = p_next.pNext
				p_next.pNext = p_this
				pp_from = &p_next.pNext
			}
			break
		}
	}
	sqlite3_expr_delete(db, ppi_where)
	sqlite3_expr_list_delete(db, p_list)
	sqlite3_src_list_delete(db, p_tbl_name)
	sqlite3_db_free(db, voidptr(z_name))
}

@[c:'sqlite3DefaultRowEst']
fn sqlite3_default_row_est(p_idx &Index) {
	if !sqlite3_default_row_est_a_val_inited {
		c2v_static_init := [LogEst(33), LogEst(32), LogEst(30), LogEst(28), LogEst(26)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_default_row_est_a_val[c2v_i_0] = c2v_element_0
		}
		sqlite3_default_row_est_a_val_inited = true
	}

	a := p_idx.aiRowLogEst
	x := LogEst(0)
	n_copy := (if 5 < int(p_idx.nKeyCol) { 5 } else { int(p_idx.nKeyCol) })
	i := 0
	x = p_idx.pTable.nRowLogEst
	if int(x) < 99 {
		x = LogEst(99)
		p_idx.pTable.nRowLogEst = x
	}
	if usize(p_idx.pPartIdxWhere) != usize(0) {
		x -= 10
	}
	a[0] = x
	C.memcpy(voidptr(unsafe { a + 1 }), voidptr(unsafe { &sqlite3_default_row_est_a_val[0] }), u64(n_copy) * sizeof(LogEst))
	for i = n_copy + 1; i <= int(p_idx.nKeyCol); i++ {
		a[i] = LogEst(23)
	}
	if (int(p_idx.onError) != 0) {
		a[p_idx.nKeyCol] = LogEst(0)
	}
}

@[c:'sqlite3DropIndex']
fn sqlite3_drop_index(p_parse &Parse, p_name &SrcList, if_exists int) {
	p_index := &Index(0)
	v := &Vdbe(0)
	db := p_parse.db
	i_db := 0
	if db.mallocFailed {
		unsafe { goto exit_drop_index
		 }
	}
	if 0 != sqlite3_read_schema(p_parse) {
		unsafe { goto exit_drop_index
		 }
	}
	p_index = sqlite3_find_index(db, c2v_at(&p_name.a[0], isize(0)).zName, c2v_at(&p_name.a[0], isize(0)).u4.zDatabase)
	if usize(p_index) == usize(0) {
		if !if_exists {
			sqlite3_error_msg(p_parse, c'no such index: %S', voidptr(&p_name.a[0]))
		} else {
			sqlite3_code_verify_named_schema(p_parse, c2v_at(&p_name.a[0], isize(0)).u4.zDatabase)
			sqlite3_force_not_read_only(p_parse)
		}
		p_parse.checkSchema = Bft(1)
		unsafe { goto exit_drop_index
		 }
	}
	if int(p_index.idxType) != 0 {
		sqlite3_error_msg(p_parse, c'index associated with UNIQUE or PRIMARY KEY constraint cannot be dropped', 0)
		unsafe { goto exit_drop_index
		 }
	}
	i_db = sqlite3_schema_to_index(db, p_index.pSchema)
	code := 10
	p_tab := p_index.pTable
	z_db := db.aDb[i_db].zDbSName
	z_tab := (if (!0) && (i_db == 1) { c'sqlite_temp_master' } else { c'sqlite_master' })
	if sqlite3_auth_check(p_parse, 9, z_tab, unsafe { nil }, z_db) {
		unsafe { goto exit_drop_index
		 }
	}
	if !0 && i_db == 1 {
		code = 12
	}
	if sqlite3_auth_check(p_parse, code, p_index.zName, p_tab.zName, z_db) {
		unsafe { goto exit_drop_index
		 }
	}
	v = sqlite3_get_vdbe(p_parse)
	if v {
		sqlite3_begin_write_operation(p_parse, 1, i_db)
		sqlite3_nested_parse(p_parse, c"DELETE FROM %Q.sqlite_master WHERE name=%Q AND type='index'", voidptr(db.aDb[i_db].zDbSName), voidptr(p_index.zName))
		sqlite3_clear_stat_tables(p_parse, i_db, c'idx', p_index.zName)
		sqlite3_change_cookie(p_parse, i_db)
		destroy_root_page(p_parse, int(p_index.tnum), i_db)
		sqlite3_vdbe_add_op4(v, 155, i_db, 0, 0, p_index.zName, 0)
	}
	exit_drop_index:
	sqlite3_src_list_delete(db, p_name)
}

@[c:'sqlite3ArrayAllocate']
fn sqlite3_array_allocate(db &Sqlite3, p_array voidptr, sz_entry int, pn_entry &int, p_idx &int) voidptr {
	z := &i8(0)
	n := Sqlite3_int64(c2v_assign[int](p_idx, int((unsafe { *pn_entry }))))
	if (n & (n - Sqlite3_int64(1))) == Sqlite3_int64(0) {
		sz := if (n == Sqlite3_int64(0)) { Sqlite3_int64(1) } else { Sqlite3_int64(2) * n }
		p_new := sqlite3_db_realloc(db, voidptr(p_array), U64(sz * Sqlite3_int64(sz_entry)))
		if usize(p_new) == usize(0) {
			unsafe { *p_idx = -1 }
			return p_array
		}
		p_array = p_new
	}
	z = &i8(p_array)
	C.memset(voidptr(unsafe { z + (n * Sqlite3_int64(sz_entry)) }), 0, u64(sz_entry))
	unsafe { (*pn_entry)++ }
	return p_array
}

@[c:'sqlite3IdListAppend']
fn sqlite3_id_list_append(p_parse &Parse, p_list &IdList, p_token &Token) &IdList {
	db := p_parse.db
	i := 0
	if usize(p_list) == usize(0) {
		p_list = sqlite3_db_malloc_zero(db, U64(((u64(usize(__offsetof(IdList, a)))) + u64(1) * sizeof(IdList_item))))
		if usize(p_list) == usize(0) {
			return unsafe { nil }
		}
	} else {
		p_new := &IdList(0)
		p_new = sqlite3_db_realloc(db, voidptr(p_list), U64(((u64(usize(__offsetof(IdList, a)))) + u64((p_list.nId + 1)) * sizeof(IdList_item))))
		if usize(p_new) == usize(0) {
			sqlite3_id_list_delete(db, p_list)
			return unsafe { nil }
		}
		p_list = p_new
	}
	mut __c2v_postfix_value_13 := p_list.nId
	p_list.nId++
	i = __c2v_postfix_value_13
	mut __c2v_lhs_tmp_110 := c2v_at(&p_list.a[0], isize(i))
	__c2v_lhs_tmp_110.zName = sqlite3_name_from_token(db, p_token)
	if (int(p_parse.eParseMode) >= 2) && !isnil(c2v_at(&p_list.a[0], isize(i)).zName) {
		sqlite3_rename_token_map(p_parse, voidptr(c2v_at(&p_list.a[0], isize(i)).zName), p_token)
	}
	return p_list
}

@[c:'sqlite3IdListDelete']
fn sqlite3_id_list_delete(db &Sqlite3, p_list &IdList) {
	i := 0
	if usize(p_list) == usize(0) {
		return
	}
	for i = 0; i < p_list.nId; i++ {
		sqlite3_db_free(db, voidptr(c2v_at(&p_list.a[0], isize(i)).zName))
	}
	sqlite3_db_nn_free_nn(db, voidptr(p_list))
}

@[c:'sqlite3IdListIndex']
fn sqlite3_id_list_index(p_list &IdList, z_name &i8) int {
	i := 0
	for i = 0; i < p_list.nId; i++ {
		if sqlite3_str_ic_mp(c2v_at(&p_list.a[0], isize(i)).zName, z_name) == 0 {
			return i
		}
	}
	return -1
}

@[c:'sqlite3SrcListEnlarge']
fn sqlite3_src_list_enlarge(p_parse &Parse, p_src &SrcList, n_extra int, i_start int) &SrcList {
	i := 0
	if u32(p_src.nSrc) + u32(n_extra) > p_src.nAlloc {
		p_new := &SrcList(0)
		n_alloc := Sqlite3_int64(2) * Sqlite3_int64(p_src.nSrc) + Sqlite3_int64(n_extra)
		db := p_parse.db
		if p_src.nSrc + n_extra >= 200 {
			sqlite3_error_msg(p_parse, c'too many FROM clause terms, max: %d', 200)
			return unsafe { nil }
		}
		if n_alloc > Sqlite3_int64(200) {
			n_alloc = Sqlite3_int64(200)
		}
		p_new = sqlite3_db_realloc(db, voidptr(p_src), ((u64(usize(__offsetof(SrcList, a)))) + u64(n_alloc) * sizeof(SrcItem)))
		if usize(p_new) == usize(0) {
			return unsafe { nil }
		}
		p_src = p_new
		p_src.nAlloc = u32(n_alloc)
	}
	for i = p_src.nSrc - 1; i >= i_start; i-- {
		(&p_src.a[0])[i + n_extra] = (&p_src.a[0])[i]
	}
	p_src.nSrc += n_extra
	C.memset(voidptr(unsafe { &p_src.a[0] + i_start }), 0, sizeof(SrcItem) * u64(n_extra))
	for i = i_start; i < i_start + n_extra; i++ {
		mut __c2v_lhs_tmp_111 := c2v_at(&p_src.a[0], isize(i))
		__c2v_lhs_tmp_111.iCursor = -1
	}
	return p_src
}

@[c:'sqlite3SrcListAppend']
fn sqlite3_src_list_append(p_parse &Parse, p_list &SrcList, p_table &Token, p_database &Token) &SrcList {
	p_item := &SrcItem(0)
	db := &Sqlite3(0)
	db = p_parse.db
	if usize(p_list) == usize(0) {
		p_list = sqlite3_db_malloc_raw_nn(p_parse.db, U64(((u64(usize(__offsetof(SrcList, a)))) + u64(1) * sizeof(SrcItem))))
		if usize(p_list) == usize(0) {
			return unsafe { nil }
		}
		p_list.nAlloc = u32(1)
		p_list.nSrc = 1
		C.memset(voidptr(unsafe { &p_list.a[0] + 0 }), 0, sizeof(SrcItem))
		mut __c2v_lhs_tmp_112 := c2v_at(&p_list.a[0], isize(0))
		__c2v_lhs_tmp_112.iCursor = -1
	} else {
		p_new := sqlite3_src_list_enlarge(p_parse, p_list, 1, p_list.nSrc)
		if usize(p_new) == usize(0) {
			sqlite3_src_list_delete(db, p_list)
			return unsafe { nil }
		} else {
			p_list = p_new
		}
	}
	p_item = unsafe { &p_list.a[0] + (p_list.nSrc - 1) }
	if !isnil(p_database) && usize(p_database.z) == usize(0) {
		p_database = 0
	}
	if p_database {
		p_item.zName = sqlite3_name_from_token(db, p_database)
		p_item.u4.zDatabase = sqlite3_name_from_token(db, p_table)
	} else {
		p_item.zName = sqlite3_name_from_token(db, p_table)
		p_item.u4.zDatabase = 0
	}
	return p_list
}

@[c:'sqlite3SrcListAssignCursors']
fn sqlite3_src_list_assign_cursors(p_parse &Parse, p_list &SrcList) {
	i := 0
	p_item := &SrcItem(0)
	if p_list {
		i = 0
		for p_item = unsafe { &p_list.a[0] }; i < p_list.nSrc; i++ {
			if p_item.iCursor >= 0 {
				unsafe { goto c2v_for_next_107
				 }
			}
			mut __c2v_postfix_value_14 := p_parse.nTab
			p_parse.nTab++
			p_item.iCursor = __c2v_postfix_value_14
			if p_item.fg.isSubquery {
				sqlite3_src_list_assign_cursors(p_parse, p_item.u4.pSubq.pSelect.pSrc)
			}
			c2v_for_next_107:
			c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
		}
	}
}

@[c:'sqlite3SubqueryDelete']
fn sqlite3_subquery_delete(db &Sqlite3, p_subq &Subquery) {
	sqlite3_select_delete(db, p_subq.pSelect)
	sqlite3_db_free(db, voidptr(p_subq))
}

@[c:'sqlite3SubqueryDetach']
fn sqlite3_subquery_detach(db &Sqlite3, p_item &SrcItem) &Select {
	p_sel := &Select(0)
	p_sel = p_item.u4.pSubq.pSelect
	sqlite3_db_free(db, voidptr(p_item.u4.pSubq))
	p_item.u4.pSubq = 0
	p_item.fg.isSubquery = u32(0)
	return p_sel
}

@[c:'sqlite3SrcListDelete']
fn sqlite3_src_list_delete(db &Sqlite3, p_list &SrcList) {
	i := 0
	p_item := &SrcItem(0)
	if usize(p_list) == usize(0) {
		return
	}
	p_item = unsafe { &p_list.a[0] }
	for i = 0; i < p_list.nSrc; i++ {
		if p_item.zName {
			sqlite3_db_nn_free_nn(db, voidptr(p_item.zName))
		}
		if p_item.zAlias {
			sqlite3_db_nn_free_nn(db, voidptr(p_item.zAlias))
		}
		if p_item.fg.isSubquery {
			sqlite3_subquery_delete(db, p_item.u4.pSubq)
		} else if int(p_item.fg.fixedSchema) == 0 && usize(p_item.u4.zDatabase) != usize(0) {
			sqlite3_db_nn_free_nn(db, voidptr(p_item.u4.zDatabase))
		}
		if p_item.fg.isIndexedBy {
			sqlite3_db_free(db, voidptr(p_item.u1.zIndexedBy))
		}
		if p_item.fg.isTabFunc {
			sqlite3_expr_list_delete(db, p_item.u1.pFuncArg)
		}
		sqlite3_delete_table(db, p_item.pSTab)
		if p_item.fg.isUsing {
			sqlite3_id_list_delete(db, p_item.u3.pUsing)
		} else if p_item.u3.pOn {
			sqlite3_expr_delete(db, p_item.u3.pOn)
		}
		c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
	}
	sqlite3_db_nn_free_nn(db, voidptr(p_list))
}

@[c:'sqlite3SrcItemAttachSubquery']
fn sqlite3_src_item_attach_subquery(p_parse &Parse, p_item &SrcItem, p_select &Select, dup_select int) int {
	p := &Subquery(0)
	if p_item.fg.fixedSchema {
		p_item.u4.pSchema = 0
		p_item.fg.fixedSchema = u32(0)
	} else if usize(p_item.u4.zDatabase) != usize(0) {
		sqlite3_db_free(p_parse.db, voidptr(p_item.u4.zDatabase))
		p_item.u4.zDatabase = 0
	}
	if dup_select {
		p_select = sqlite3_select_dup(p_parse.db, p_select, 0)
		if usize(p_select) == usize(0) {
			return 0
		}
	}
	p_item.u4.pSubq = sqlite3_db_malloc_raw_nn(p_parse.db, U64(sizeof(Subquery)))
	p = p_item.u4.pSubq
	if usize(p) == usize(0) {
		sqlite3_select_delete(p_parse.db, p_select)
		return 0
	}
	p_item.fg.isSubquery = u32(1)
	p.pSelect = p_select
	C.memset(voidptr((&i8(voidptr(p))) + sizeof(&Select)), 0, sizeof(Subquery) - sizeof(&Select))
	return 1
}

@[c:'sqlite3SrcListAppendFromTerm']
fn sqlite3_src_list_append_from_term(p_parse &Parse, p &SrcList, p_table &Token, p_database &Token, p_alias &Token, p_subquery &Select, p_on_using &OnOrUsing) &SrcList {
	p_item := &SrcItem(0)
	db := p_parse.db
	if isnil(p) && usize(p_on_using) != usize(0) && (!isnil(p_on_using.pOn) || !isnil(p_on_using.pUsing)) {
		sqlite3_error_msg(p_parse, c'a JOIN clause is required before %s', voidptr((if p_on_using.pOn {
			c'ON'
		} else {
			c'USING'
		})))
		unsafe { goto append_from_error
		 }
	}
	p = sqlite3_src_list_append(p_parse, p, p_table, p_database)
	if usize(p) == usize(0) {
		unsafe { goto append_from_error
		 }
	}
	p_item = unsafe { &p.a[0] + (p.nSrc - 1) }
	if (int(p_parse.eParseMode) >= 2) && !isnil(p_item.zName) {
		p_token := if (!isnil(p_database) && !isnil(p_database.z)) { p_database } else { p_table }
		sqlite3_rename_token_map(p_parse, voidptr(p_item.zName), p_token)
	}
	if p_alias.n {
		p_item.zAlias = sqlite3_name_from_token(db, p_alias)
	}
	if p_subquery {
		if sqlite3_src_item_attach_subquery(p_parse, p_item, p_subquery, 0) {
			if p_subquery.selFlags & u32(2048) {
				p_item.fg.isNestedFrom = u32(1)
			}
		}
	}
	if usize(p_on_using) == usize(0) {
		p_item.u3.pOn = 0
	} else if p_on_using.pUsing {
		p_item.fg.isUsing = u32(1)
		p_item.u3.pUsing = p_on_using.pUsing
	} else {
		p_item.u3.pOn = p_on_using.pOn
	}
	return p
	append_from_error:
	sqlite3_clear_on_or_using(db, p_on_using)
	sqlite3_select_delete(db, p_subquery)
	return unsafe { nil }
}

@[c:'sqlite3SrcListIndexedBy']
fn sqlite3_src_list_indexed_by(p_parse &Parse, p &SrcList, p_indexed_by &Token) {
	if !isnil(p) && p_indexed_by.n > u32(0) {
		p_item := &SrcItem(0)
		p_item = unsafe { &p.a[0] + (p.nSrc - 1) }
		if p_indexed_by.n == u32(1) && isnil(p_indexed_by.z) {
			p_item.fg.notIndexed = u32(1)
		} else {
			p_item.u1.zIndexedBy = sqlite3_name_from_token(p_parse.db, p_indexed_by)
			p_item.fg.isIndexedBy = u32(1)
		}
	}
}

@[c:'sqlite3SrcListAppendList']
fn sqlite3_src_list_append_list(p_parse &Parse, p1 &SrcList, p2 &SrcList) &SrcList {
	0
	if p2 {
		n_old := p1.nSrc
		p_new := sqlite3_src_list_enlarge(p_parse, p1, p2.nSrc, n_old)
		if usize(p_new) == usize(0) {
			sqlite3_src_list_delete(p_parse.db, p2)
		} else {
			p1 = p_new
			C.memcpy(voidptr(unsafe { &p1.a[0] + n_old }), p2.a, u64(p2.nSrc) * sizeof(SrcItem))
			mut __c2v_lhs_tmp_113 := c2v_at(&p1.a[0], isize(0))
			__c2v_lhs_tmp_113.fg.jointype |= (64 & int(c2v_at(&p2.a[0], isize(0)).fg.jointype))
			sqlite3_db_free(p_parse.db, voidptr(p2))
		}
	}
	return p1
}

@[c:'sqlite3SrcListFuncArgs']
fn sqlite3_src_list_func_args(p_parse &Parse, p &SrcList, p_list &ExprList) {
	if p {
		p_item := unsafe { &p.a[0] + (p.nSrc - 1) }
		p_item.u1.pFuncArg = p_list
		p_item.fg.isTabFunc = u32(1)
	} else {
		sqlite3_expr_list_delete(p_parse.db, p_list)
	}
}

@[c:'sqlite3SrcListShiftJoinType']
fn sqlite3_src_list_shift_join_type(p_parse &Parse, p &SrcList) {
	if !isnil(p) && p.nSrc > 1 {
		i := p.nSrc - 1
		all_flags := U8(0)
		for {
			all_flags |= int(c2v_assign[u8](unsafe { &c2v_at(&p.a[0], isize(i)).fg.jointype }, u8(c2v_at(&p.a[0], isize(i - 1)).fg.jointype)))
			i--
			if !(i > 0) {
				break
			}
		}
		mut __c2v_lhs_tmp_114 := c2v_at(&p.a[0], isize(0))
		__c2v_lhs_tmp_114.fg.jointype = U8(0)
		if int(all_flags) & 16 {
			for i = p.nSrc - 1; (i > 0) && (int(c2v_at(&p.a[0], isize(i)).fg.jointype) & 16) == 0; i-- {
			}
			i--
			for {
				mut __c2v_lhs_tmp_115 := c2v_at(&p.a[0], isize(i))
				__c2v_lhs_tmp_115.fg.jointype |= 64
				i--
				if !(i >= 0) {
					break
				}
			}
		}
	}
}

@[c:'sqlite3BeginTransaction']
fn sqlite3_begin_transaction(p_parse &Parse, type_ int) {
	db := &Sqlite3(0)
	v := &Vdbe(0)
	i := 0
	db = p_parse.db
	if sqlite3_auth_check(p_parse, 22, c'BEGIN', unsafe { nil }, unsafe { nil }) {
		return
	}
	v = sqlite3_get_vdbe(p_parse)
	if isnil(v) {
		return
	}
	if type_ != 7 {
		for i = 0; i < db.nDb; i++ {
			e_txn_type := 0
			p_bt := db.aDb[i].pBt
			if !isnil(p_bt) && sqlite3_btree_is_readonly(p_bt) {
				e_txn_type = 0
			} else if type_ == 9 {
				e_txn_type = 2
			} else {
				e_txn_type = 1
			}
			sqlite3_vdbe_add_op2(v, 2, i, e_txn_type)
			sqlite3_vdbe_uses_btree(v, i)
		}
	}
	sqlite3_vdbe_add_op0(v, 1)
}

@[c:'sqlite3EndTransaction']
fn sqlite3_end_transaction(p_parse &Parse, e_type int) {
	v := &Vdbe(0)
	is_rollback := 0
	is_rollback = e_type == 12
	if sqlite3_auth_check(p_parse, 22, unsafe { if is_rollback { c'ROLLBACK' } else { c'COMMIT' } }, unsafe { nil }, unsafe { nil }) {
		return
	}
	v = sqlite3_get_vdbe(p_parse)
	if v {
		sqlite3_vdbe_add_op2(v, 1, 1, is_rollback)
	}
}

@[c:'sqlite3Savepoint']
fn sqlite3_savepoint(p_parse &Parse, op int, p_name &Token) {
	z_name := sqlite3_name_from_token(p_parse.db, p_name)
	if z_name {
		v := sqlite3_get_vdbe(p_parse)
		if !sqlite3_savepoint_az_inited {
			c2v_static_init := [c'BEGIN', c'RELEASE', c'ROLLBACK']
			for c2v_i_0, c2v_element_0 in c2v_static_init {
				sqlite3_savepoint_az[c2v_i_0] = c2v_element_0
			}
			sqlite3_savepoint_az_inited = true
		}

		if isnil(v) || sqlite3_auth_check(p_parse, 32, sqlite3_savepoint_az[op], z_name, unsafe { nil }) {
			sqlite3_db_free(p_parse.db, voidptr(z_name))
			return
		}
		sqlite3_vdbe_add_op4(v, 0, op, 0, 0, z_name, (-7))
	}
}

@[c:'sqlite3OpenTempDatabase']
fn sqlite3_open_temp_database(p_parse &Parse) int {
	db := p_parse.db
	if usize(db.aDb[1].pBt) == usize(0) && !p_parse.explain {
		rc := 0
		p_bt := &Btree(0)
		static flags := 2 | 4 | 16 | 8 | 512
		rc = sqlite3_btree_open(db.pVfs, unsafe { nil }, db, &&Btree(&&Btree(c2v_address_of(&p_bt))), 0, flags)
		if rc != 0 {
			sqlite3_error_msg(p_parse, c'unable to open a temporary database file for storing temporary tables')
			p_parse.rc = rc
			return 1
		}
		db.aDb[1].pBt = p_bt
		if 7 == sqlite3_btree_set_page_size(p_bt, db.nextPagesize, 0, 0) {
			sqlite3_oom_fault(db)
			return 1
		}
	}
	return 0
}

@[c:'sqlite3CodeVerifySchemaAtToplevel']
fn sqlite3_code_verify_schema_at_toplevel(p_toplevel &Parse, i_db int) {
	if ((p_toplevel.cookieMask & ((YDbMask(1)) << i_db)) != YDbMask(0)) == 0 {
		p_toplevel.cookieMask |= ((YDbMask(1)) << i_db)
		if !0 && i_db == 1 {
			sqlite3_open_temp_database(p_toplevel)
		}
	}
}

@[c:'sqlite3CodeVerifySchema']
fn sqlite3_code_verify_schema(p_parse &Parse, i_db int) {
	sqlite3_code_verify_schema_at_toplevel(unsafe { if p_parse.pToplevel {
		p_parse.pToplevel
	} else {
		p_parse
	} }, i_db)
}

@[c:'sqlite3CodeVerifyNamedSchema']
fn sqlite3_code_verify_named_schema(p_parse &Parse, z_db &i8) {
	db := p_parse.db
	i := 0
	for i = 0; i < db.nDb; i++ {
		p_db := unsafe { db.aDb + i }
		if !isnil(p_db.pBt) && (isnil(z_db) || 0 == sqlite3_str_ic_mp(z_db, p_db.zDbSName)) {
			sqlite3_code_verify_schema(p_parse, i)
		}
	}
}

@[c:'sqlite3BeginWriteOperation']
fn sqlite3_begin_write_operation(p_parse &Parse, set_statement int, i_db int) {
	p_toplevel := (if p_parse.pToplevel { p_parse.pToplevel } else { p_parse })
	sqlite3_code_verify_schema_at_toplevel(p_toplevel, i_db)
	p_toplevel.writeMask |= ((YDbMask(1)) << i_db)
	p_toplevel.isMultiWrite |= set_statement
}

@[c:'sqlite3MultiWrite']
fn sqlite3_multi_write(p_parse &Parse) {
	p_toplevel := (if p_parse.pToplevel { p_parse.pToplevel } else { p_parse })
	p_toplevel.isMultiWrite = U8(1)
}

@[c:'sqlite3MayAbort']
fn sqlite3_may_abort(p_parse &Parse) {
	p_toplevel := (if p_parse.pToplevel { p_parse.pToplevel } else { p_parse })
	p_toplevel.mayAbort = Bft(1)
}

@[c:'sqlite3HaltConstraint']
fn sqlite3_halt_constraint(p_parse &Parse, err_code int, on_error int, p4 &i8, p4type I8, p5_errmsg U8) {
	v := &Vdbe(0)
	v = sqlite3_get_vdbe(p_parse)
	if on_error == 2 {
		sqlite3_may_abort(p_parse)
	}
	sqlite3_vdbe_add_op4(v, 72, err_code, on_error, 0, p4, int(p4type))
	sqlite3_vdbe_change_p5(v, U16(p5_errmsg))
}

@[c:'sqlite3UniqueConstraint']
fn sqlite3_unique_constraint(p_parse &Parse, on_error int, p_idx &Index) {
	z_err := &i8(0)
	j := 0
	err_msg := StrAccum{}
	p_tab := p_idx.pTable
	sqlite3_str_accum_init(&err_msg, p_parse.db, unsafe { nil }, 0, p_parse.db.aLimit[0])
	if p_idx.aColExpr {
		sqlite3_str_appendf(unsafe { &Sqlite3_str(&err_msg) }, c"index '%q'", voidptr(p_idx.zName))
	} else {
		for j = 0; j < int(p_idx.nKeyCol); j++ {
			z_col := &i8(0)
			z_col = p_tab.aCol[p_idx.aiColumn[j]].zCnName
			if j {
				sqlite3_str_append(unsafe { &Sqlite3_str(&err_msg) }, c', ', 2)
			}
			sqlite3_str_appendall(unsafe { &Sqlite3_str(&err_msg) }, p_tab.zName)
			sqlite3_str_append(unsafe { &Sqlite3_str(&err_msg) }, c'.', 1)
			sqlite3_str_appendall(unsafe { &Sqlite3_str(&err_msg) }, z_col)
		}
	}
	z_err = sqlite3_str_accum_finish(&err_msg)
	sqlite3_halt_constraint(p_parse, if (int(p_idx.idxType) == 2) {
		(19 | (6 << 8))
	} else {
		(19 | (8 << 8))
	}, on_error, z_err, I8((-7)), U8(2))
}

@[c:'sqlite3RowidConstraint']
fn sqlite3_rowid_constraint(p_parse &Parse, on_error int, p_tab &Table) {
	z_msg := &i8(0)
	rc := 0
	if int(p_tab.iPKey) >= 0 {
		z_msg = sqlite3_mp_rintf(p_parse.db, c'%s.%s', voidptr(p_tab.zName), voidptr(p_tab.aCol[p_tab.iPKey].zCnName))
		rc = (19 | (6 << 8))
	} else {
		z_msg = sqlite3_mp_rintf(p_parse.db, c'%s.rowid', voidptr(p_tab.zName))
		rc = (19 | (10 << 8))
	}
	sqlite3_halt_constraint(p_parse, rc, on_error, z_msg, I8((-7)), U8(2))
}

@[c:'collationMatch']
fn collation_match(z_coll &i8, p_index &Index) int {
	i := 0
	for i = 0; i < int(p_index.nColumn); i++ {
		z := p_index.azColl[i]
		if 0 == sqlite3_str_ic_mp(z, z_coll) {
			return 1
		}
	}
	return 0
}

@[c:'sqlite3Reindex']
fn sqlite3_reindex(p_parse &Parse, p_name1 &Token, p_name2 &Token) {
	z := unsafe { &i8(nil) }
	z_db := unsafe { &i8(nil) }
	i_re_db := -1
	db := p_parse.db
	p_obj_name := &Token(0)
	b_match := 0
	z_coll := unsafe { &i8(nil) }
	p_re_tab := unsafe { &Table(nil) }
	p_re_index := unsafe { &Index(nil) }
	is_expr_idx := 0
	b_all := 0
	if 0 != sqlite3_read_schema(p_parse) {
		return
	}
	if usize(p_name1) == usize(0) {
		b_match = 1
		b_all = 1
	} else if (usize(p_name2) == usize(0)) || usize(p_name2.z) == usize(0) {
		z = sqlite3_name_from_token(p_parse.db, p_name1)
		if usize(z) == usize(0) {
			return
		}
	} else {
		i_re_db = sqlite3_two_part_name(p_parse, p_name1, p_name2, &&Token(&&Token(c2v_address_of(&p_obj_name))))
		if i_re_db < 0 {
			return
		}
		z = sqlite3_name_from_token(db, p_obj_name)
		if usize(z) == usize(0) {
			return
		}
		z_db = db.aDb[i_re_db].zDbSName
	}
	if !b_all {
		if usize(z_db) == usize(0) && sqlite3_str_ic_mp(z, c'expressions') == 0 {
			is_expr_idx = 1
			b_match = 1
		}
		if usize(z_db) == usize(0) && usize(sqlite3_find_coll_seq(db, db.enc, z, 0)) != usize(0) {
			z_coll = z
			b_match = 1
		}
		if usize(z_coll) == usize(0) && usize(c2v_assign[&Table](unsafe { &p_re_tab }, sqlite3_find_table(db, z, z_db))) != usize(0) {
			b_match = 1
		}
		if usize(z_coll) == usize(0) && usize(c2v_assign[&Index](unsafe { &p_re_index }, sqlite3_find_index(db, z, z_db))) != usize(0) {
			b_match = 1
		}
	}
	if b_match {
		i_db := 0
		k := &HashElem(0)
		p_tab := &Table(0)
		p_idx := &Index(0)
		p_db := &Db(0)
		i_db = 0
		for p_db = db.aDb; i_db < db.nDb; i_db++ {
			if i_re_db >= 0 && i_re_db != i_db {
				unsafe { goto c2v_for_next_111
				 }
			}
			for k = p_db.pSchema.tblHash.first; k; k = k.next {
				p_tab = &Table(k.data)
				if (int(p_tab.eTabType) == 1) {
					continue
				}
				for p_idx = p_tab.pIndex; p_idx; p_idx = p_idx.pNext {
					if b_all || usize(p_tab) == usize(p_re_tab) || usize(p_idx) == usize(p_re_index) || (is_expr_idx && int(p_idx.bHasExpr)) || (usize(z_coll) != usize(0) && collation_match(z_coll, p_idx)) {
						sqlite3_begin_write_operation(p_parse, 0, i_db)
						sqlite3_refill_index(p_parse, p_idx, -1)
					}
				}
			}
			c2v_for_next_111:
			c2v_pointer_postfix(voidptr(&p_db), p_db, isize(1))
		}
	} else {
		sqlite3_error_msg(p_parse, c'unable to identify the object to be reindexed')
	}
	sqlite3_db_free(db, voidptr(z))
	return
}

@[c:'sqlite3KeyInfoOfIndex']
fn sqlite3_key_info_of_index(p_parse &Parse, p_idx &Index) &KeyInfo {
	i := 0
	n_col := int(p_idx.nColumn)
	n_key := int(p_idx.nKeyCol)
	p_key := &KeyInfo(0)
	if p_parse.nErr {
		return unsafe { nil }
	}
	if p_idx.uniqNotNull {
		p_key = sqlite3_key_info_alloc(p_parse.db, n_key, n_col - n_key)
	} else {
		p_key = sqlite3_key_info_alloc(p_parse.db, n_col, 0)
	}
	if p_key {
		for i = 0; i < n_col; i++ {
			z_coll := p_idx.azColl[i]
			(&p_key.aColl[0])[i] = unsafe { if usize(z_coll) == usize(&sqlite3StrBINARY[0]) {
				&CollSeq(nil)
			} else {
				sqlite3_locate_coll_seq(p_parse, z_coll)
			} }
			p_key.aSortFlags[i] = p_idx.aSortOrder[i]
		}
		if p_parse.nErr {
			if int(p_idx.bNoQuery) == 0 && !isnil(sqlite3_hash_find(&p_idx.pSchema.idxHash, p_idx.zName)) {
				p_idx.bNoQuery = u32(1)
				p_parse.rc = (1 | (2 << 8))
			}
			sqlite3_key_info_unref(p_key)
			p_key = 0
		}
	}
	return p_key
}

@[c:'sqlite3CteNew']
fn sqlite3_cte_new(p_parse &Parse, p_name &Token, p_arglist &ExprList, p_query &Select, e_m10d U8) &Cte {
	p_new := &Cte(0)
	db := p_parse.db
	p_new = sqlite3_db_malloc_zero(db, U64(sizeof(Cte)))
	if db.mallocFailed {
		sqlite3_expr_list_delete(db, p_arglist)
		sqlite3_select_delete(db, p_query)
	} else {
		p_new.pSelect = p_query
		p_new.pCols = p_arglist
		p_new.zName = sqlite3_name_from_token(p_parse.db, p_name)
		p_new.eM10d = e_m10d
	}
	return p_new
}

@[c:'cteClear']
fn cte_clear(db &Sqlite3, p_cte &Cte) {
	sqlite3_expr_list_delete(db, p_cte.pCols)
	sqlite3_select_delete(db, p_cte.pSelect)
	sqlite3_db_free(db, voidptr(p_cte.zName))
}

@[c:'sqlite3CteDelete']
fn sqlite3_cte_delete(db &Sqlite3, p_cte &Cte) {
	cte_clear(db, p_cte)
	sqlite3_db_free(db, voidptr(p_cte))
}

@[c:'sqlite3WithAdd']
fn sqlite3_with_add(p_parse &Parse, p_with &With, p_cte &Cte) &With {
	db := p_parse.db
	p_new := &With(0)
	z_name := &i8(0)
	if usize(p_cte) == usize(0) {
		return p_with
	}
	z_name = p_cte.zName
	if !isnil(z_name) && !isnil(p_with) {
		i := 0
		for i = 0; i < p_with.nCte; i++ {
			if sqlite3_str_ic_mp(z_name, c2v_at(&p_with.a[0], isize(i)).zName) == 0 {
				sqlite3_error_msg(p_parse, c'duplicate WITH table name: %s', voidptr(z_name))
			}
		}
	}
	if p_with {
		p_new = sqlite3_db_realloc(db, voidptr(p_with), U64(((u64(usize(__offsetof(With, a)))) + u64((p_with.nCte + 1)) * sizeof(Cte))))
	} else {
		p_new = sqlite3_db_malloc_zero(db, U64(((u64(usize(__offsetof(With, a)))) + u64(1) * sizeof(Cte))))
	}
	if db.mallocFailed {
		sqlite3_cte_delete(db, p_cte)
		p_new = p_with
	} else {
		(&p_new.a[0])[p_new.nCte++] = unsafe { *p_cte }
		sqlite3_db_free(db, voidptr(p_cte))
	}
	return p_new
}

@[c:'sqlite3WithDelete']
fn sqlite3_with_delete(db &Sqlite3, p_with &With) {
	if p_with {
		i := 0
		for i = 0; i < p_with.nCte; i++ {
			cte_clear(db, unsafe { &p_with.a[0] + i })
		}
		sqlite3_db_free(db, voidptr(p_with))
	}
}

@[c:'sqlite3WithDeleteGeneric']
fn sqlite3_with_delete_generic(db &Sqlite3, p_with voidptr) {
	c2v_gc_register_thread()
	sqlite3_with_delete(db, &With(p_with))
}
