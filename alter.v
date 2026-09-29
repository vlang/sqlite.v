@[translated]
module main

@[c:'isAlterableTable']
fn is_alterable_table(p_parse &Parse, p_tab &Table) int {
	if 0 == sqlite3_strnicmp(p_tab.zName, c'sqlite_', 7) || (p_tab.tabFlags & u32(32768)) != u32(0) || ((p_tab.tabFlags & u32(4096)) != u32(0) && sqlite3_read_only_shadow_tables(p_parse.db)) {
		sqlite3_error_msg(p_parse, c'table %s may not be altered', voidptr(p_tab.zName))
		return 1
	}
	return 0
}

@[c:'renameTestSchema']
fn rename_test_schema(p_parse &Parse, z_db &i8, b_temp int, z_when &i8, b_no_dqs int) {
	p_parse.colNamesSet = Bft(1)
	sqlite3_nested_parse(p_parse, c'SELECT 1 FROM "%w".sqlite_master WHERE name NOT LIKE \'sqliteX_%%\' ESCAPE \'X\' AND sql NOT LIKE \'create virtual%%\' AND sqlite_rename_test(%Q, sql, type, name, %d, %Q, %d)=NULL ', voidptr(z_db), voidptr(z_db), b_temp, voidptr(z_when), b_no_dqs)
	if b_temp == 0 {
		sqlite3_nested_parse(p_parse, c"SELECT 1 FROM temp.sqlite_master WHERE name NOT LIKE 'sqliteX_%%' ESCAPE 'X' AND sql NOT LIKE 'create virtual%%' AND sqlite_rename_test(%Q, sql, type, name, 1, %Q, %d)=NULL ", voidptr(z_db), voidptr(z_when), b_no_dqs)
	}
}

@[c:'renameFixQuotes']
fn rename_fix_quotes(p_parse &Parse, z_db &i8, b_temp int) {
	sqlite3_nested_parse(p_parse, c'UPDATE "%w".sqlite_master SET sql = sqlite_rename_quotefix(%Q, sql)WHERE name NOT LIKE \'sqliteX_%%\' ESCAPE \'X\' AND sql NOT LIKE \'create virtual%%\'', voidptr(z_db), voidptr(z_db))
	if b_temp == 0 {
		sqlite3_nested_parse(p_parse, c"UPDATE temp.sqlite_master SET sql = sqlite_rename_quotefix('temp', sql)WHERE name NOT LIKE 'sqliteX_%%' ESCAPE 'X' AND sql NOT LIKE 'create virtual%%'")
	}
}

@[c:'renameReloadSchema']
fn rename_reload_schema(p_parse &Parse, i_db int, p5 U16) {
	v := p_parse.pVdbe
	if v {
		sqlite3_change_cookie(p_parse, i_db)
		sqlite3_vdbe_add_parse_schema_op(p_parse.pVdbe, i_db, unsafe { nil }, p5)
		if i_db != 1 {
			sqlite3_vdbe_add_parse_schema_op(p_parse.pVdbe, 1, unsafe { nil }, p5)
		}
	}
}

@[c:'sqlite3AlterRenameTable']
fn sqlite3_alter_rename_table(p_parse &Parse, p_src &SrcList, p_name &Token) {
	i_db := 0
	z_db := &i8(0)
	p_tab := &Table(0)
	z_name := unsafe { &i8(nil) }
	db := p_parse.db
	n_tab_name := 0
	z_tab_name := &i8(0)
	v := &Vdbe(0)
	pvt_ab := unsafe { &VTable(nil) }
	if db.mallocFailed {
		unsafe { goto exit_rename_table
		 }
	}
	p_tab = sqlite3_locate_table_item(p_parse, u32(0), unsafe { &p_src.a[0] + 0 })
	if isnil(p_tab) {
		unsafe { goto exit_rename_table
		 }
	}
	i_db = sqlite3_schema_to_index(p_parse.db, p_tab.pSchema)
	z_db = db.aDb[i_db].zDbSName
	z_name = sqlite3_name_from_token(db, p_name)
	if isnil(z_name) {
		unsafe { goto exit_rename_table
		 }
	}
	if !isnil(sqlite3_find_table(db, z_name, z_db)) || !isnil(sqlite3_find_index(db, z_name, z_db)) || sqlite3_is_shadow_table_of(db, p_tab, z_name) {
		sqlite3_error_msg(p_parse, c'there is already another table or index with this name: %s', voidptr(z_name))
		unsafe { goto exit_rename_table
		 }
	}
	if 0 != is_alterable_table(p_parse, p_tab) {
		unsafe { goto exit_rename_table
		 }
	}
	if 0 != sqlite3_check_object_name(p_parse, z_name, c'table', z_name) {
		unsafe { goto exit_rename_table
		 }
	}
	if (int(p_tab.eTabType) == 2) {
		sqlite3_error_msg(p_parse, c'view %s may not be altered', voidptr(p_tab.zName))
		unsafe { goto exit_rename_table
		 }
	}
	if sqlite3_auth_check(p_parse, 26, z_db, p_tab.zName, unsafe { nil }) {
		unsafe { goto exit_rename_table
		 }
	}
	if sqlite3_view_get_column_names(p_parse, p_tab) {
		unsafe { goto exit_rename_table
		 }
	}
	if (int(p_tab.eTabType) == 1) {
		pvt_ab = sqlite3_get_vt_able(db, p_tab)
		if isnil(pvt_ab.pVtab.pModule.xRename) {
			pvt_ab = 0
		}
	}
	v = sqlite3_get_vdbe(p_parse)
	if usize(v) == usize(0) {
		unsafe { goto exit_rename_table
		 }
	}
	sqlite3_may_abort(p_parse)
	z_tab_name = p_tab.zName
	n_tab_name = sqlite3_utf8_char_len(z_tab_name, -1)
	sqlite3_nested_parse(p_parse, c'UPDATE "%w".sqlite_master SET sql = sqlite_rename_table(%Q, type, name, sql, %Q, %Q, %d) WHERE (type!=\'index\' OR tbl_name=%Q COLLATE nocase)AND   name NOT LIKE \'sqliteX_%%\' ESCAPE \'X\'', voidptr(z_db), voidptr(z_db), voidptr(z_tab_name), voidptr(z_name), (i_db == 1), voidptr(z_tab_name))
	sqlite3_nested_parse(p_parse, c"UPDATE %Q.sqlite_master SET tbl_name = %Q, name = CASE WHEN type='table' THEN %Q WHEN name LIKE 'sqliteX_autoindex%%' ESCAPE 'X'      AND type='index' THEN 'sqlite_autoindex_' || %Q || substr(name,%d+18) ELSE name END WHERE tbl_name=%Q COLLATE nocase AND (type='table' OR type='index' OR type='trigger');", voidptr(z_db), voidptr(z_name), voidptr(z_name), voidptr(z_name), n_tab_name, voidptr(z_tab_name))
	if sqlite3_find_table(db, c'sqlite_sequence', z_db) {
		sqlite3_nested_parse(p_parse, c'UPDATE "%w".sqlite_sequence set name = %Q WHERE name = %Q', voidptr(z_db), voidptr(z_name), voidptr(p_tab.zName))
	}
	if i_db != 1 {
		sqlite3_nested_parse(p_parse, c"UPDATE sqlite_temp_schema SET sql = sqlite_rename_table(%Q, type, name, sql, %Q, %Q, 1), tbl_name = CASE WHEN tbl_name=%Q COLLATE nocase AND   sqlite_rename_test(%Q, sql, type, name, 1, 'after rename', 0) THEN %Q ELSE tbl_name END WHERE type IN ('view', 'trigger')", voidptr(z_db), voidptr(z_tab_name), voidptr(z_name), voidptr(z_tab_name), voidptr(z_db), voidptr(z_name))
	}
	if pvt_ab {
		i := c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		sqlite3_vdbe_load_string(v, i, z_name)
		sqlite3_vdbe_add_op4(v, 179, i, 0, 0, &i8(voidptr(pvt_ab)), (-12))
	}
	rename_reload_schema(p_parse, i_db, U16(1))
	rename_test_schema(p_parse, z_db, i_db == 1, c'after rename', 0)
	exit_rename_table:
	sqlite3_src_list_delete(db, p_src)
	sqlite3_db_free(db, voidptr(z_name))
}

@[c:'sqlite3ErrorIfNotEmpty']
fn sqlite3_error_if_not_empty(p_parse &Parse, z_db &i8, z_tab &i8, z_err &i8) {
	sqlite3_nested_parse(p_parse, c'SELECT raise(ABORT,%Q) FROM "%w"."%w"', voidptr(z_err), voidptr(z_db), voidptr(z_tab))
}

@[c:'sqlite3AlterFinishAddColumn']
fn sqlite3_alter_finish_add_column(p_parse &Parse, p_col_def &Token) {
	p_new := &Table(0)
	p_tab := &Table(0)
	i_db := 0
	z_db := &i8(0)
	z_tab := &i8(0)
	z_col := &i8(0)
	p_col := &Column(0)
	p_dflt := &Expr(0)
	db := &Sqlite3(0)
	v := &Vdbe(0)
	r1 := 0
	db = p_parse.db
	if p_parse.nErr {
		return
	}
	p_new = p_parse.pNewTable
	i_db = sqlite3_schema_to_index(db, p_new.pSchema)
	z_db = db.aDb[i_db].zDbSName
	z_tab = unsafe { p_new.zName + 16 }
	p_col = unsafe { p_new.aCol + (int(p_new.nCol) - 1) }
	p_dflt = sqlite3_column_expr(p_new, p_col)
	p_tab = sqlite3_find_table(db, z_tab, z_db)
	if sqlite3_auth_check(p_parse, 26, z_db, p_tab.zName, unsafe { nil }) {
		return
	}
	if int(p_col.colFlags) & 1 {
		sqlite3_error_msg(p_parse, c'Cannot add a PRIMARY KEY column')
		return
	}
	if p_new.pIndex {
		sqlite3_error_msg(p_parse, c'Cannot add a UNIQUE column')
		return
	}
	if (int(p_col.colFlags) & 96) == 0 {
		if !isnil(p_dflt) && int(p_dflt.pLeft.op) == 122 {
			p_dflt = 0
		}
		if (db.flags & U64(16384)) && !isnil(p_new.u.tab.pFKey) && !isnil(p_dflt) {
			sqlite3_error_if_not_empty(p_parse, z_db, z_tab, c'Cannot add a REFERENCES column with non-NULL default value')
		}
		if int(p_col.notNull) && isnil(p_dflt) {
			sqlite3_error_if_not_empty(p_parse, z_db, z_tab, c'Cannot add a NOT NULL column with default value NULL')
		}
		if p_dflt {
			p_val := unsafe { &Sqlite3_value(nil) }
			rc := 0
			rc = sqlite3_value_from_expr(db, p_dflt, U8(1), U8(65), &&Sqlite3_value(&&Sqlite3_value(c2v_address_of(&p_val))))
			if rc != 0 {
				return
			}
			if isnil(p_val) {
				sqlite3_error_if_not_empty(p_parse, z_db, z_tab, c'Cannot add a column with non-constant default')
			}
			sqlite3_value_free_vdup7(p_val)
		}
	} else if int(p_col.colFlags) & 64 {
		sqlite3_error_if_not_empty(p_parse, z_db, z_tab, c'cannot add a STORED column')
	}
	z_col = sqlite3_db_str_nd_up(db, &i8(p_col_def.z), U64(p_col_def.n))
	if z_col {
		z_end := unsafe { z_col + (p_col_def.n - u32(1)) }
		for usize(z_end) > usize(z_col) && (int((unsafe { *z_end })) == i8(`;`) || (int(sqlite3CtypeMap[u8((unsafe { *z_end }))]) & 1)) {
			mut __c2v_lhs_tmp_103 := unsafe { c2v_pointer_postfix(voidptr(&z_end), z_end, isize(-1)) }
			unsafe { *__c2v_lhs_tmp_103 = i8(`\0`) }
		}
		sqlite3_nested_parse(p_parse, c'UPDATE "%w".sqlite_master SET sql = printf(\'%%.%ds, \',sql) || %Q || substr(sql,1+length(printf(\'%%.%ds\',sql))) WHERE type = \'table\' AND name = %Q', voidptr(z_db), p_new.u.tab.addColOffset, voidptr(z_col), p_new.u.tab.addColOffset, voidptr(z_tab))
		sqlite3_db_free(db, voidptr(z_col))
	}
	v = sqlite3_get_vdbe(p_parse)
	if v {
		r1 = sqlite3_get_temp_reg(p_parse)
		sqlite3_vdbe_add_op3(v, 101, i_db, r1, 2)
		sqlite3_vdbe_uses_btree(v, i_db)
		sqlite3_vdbe_add_op2(v, 88, r1, -2)
		sqlite3_vdbe_add_op2(v, 61, r1, sqlite3_vdbe_current_addr(v) + 2)
		0
		sqlite3_vdbe_add_op3(v, 102, i_db, 2, 3)
		sqlite3_release_temp_reg(p_parse, r1)
		rename_reload_schema(p_parse, i_db, U16(3))
		if usize(p_new.pCheck) != usize(0) || (int(p_col.notNull) && (int(p_col.colFlags) & 96) != 0) || (p_tab.tabFlags & u32(65536)) != u32(0) {
			sqlite3_nested_parse(p_parse, c"SELECT CASE WHEN quick_check GLOB 'CHECK*' THEN raise(ABORT,'CHECK constraint failed') WHEN quick_check GLOB 'non-* value in*' THEN raise(ABORT,'type mismatch on DEFAULT') ELSE raise(ABORT,'NOT NULL constraint failed') END  FROM pragma_quick_check(%Q,%Q) WHERE quick_check GLOB 'CHECK*' OR quick_check GLOB 'NULL*' OR quick_check GLOB 'non-* value in*'", voidptr(z_tab), voidptr(z_db))
		}
	}
}

@[c:'sqlite3AlterBeginAddColumn']
fn sqlite3_alter_begin_add_column(p_parse &Parse, p_src &SrcList) {
	p_new := &Table(0)
	p_tab := &Table(0)
	i_db := 0
	i := 0
	n_alloc := 0
	db := p_parse.db
	if db.mallocFailed {
		unsafe { goto exit_begin_add_column
		 }
	}
	p_tab = sqlite3_locate_table_item(p_parse, u32(0), unsafe { &p_src.a[0] + 0 })
	if isnil(p_tab) {
		unsafe { goto exit_begin_add_column
		 }
	}
	if (int(p_tab.eTabType) == 1) {
		sqlite3_error_msg(p_parse, c'virtual tables may not be altered')
		unsafe { goto exit_begin_add_column
		 }
	}
	if (int(p_tab.eTabType) == 2) {
		sqlite3_error_msg(p_parse, c'Cannot add a column to a view')
		unsafe { goto exit_begin_add_column
		 }
	}
	if 0 != is_alterable_table(p_parse, p_tab) {
		unsafe { goto exit_begin_add_column
		 }
	}
	sqlite3_may_abort(p_parse)
	i_db = sqlite3_schema_to_index(db, p_tab.pSchema)
	p_new = &Table(sqlite3_db_malloc_zero(db, U64(sizeof(Table))))
	if isnil(p_new) {
		unsafe { goto exit_begin_add_column
		 }
	}
	p_parse.pNewTable = p_new
	p_new.nTabRef = u32(1)
	p_new.nCol = p_tab.nCol
	n_alloc = (((int(p_new.nCol) - 1) / 8) * 8) + 8
	p_new.aCol = &Column(sqlite3_db_malloc_zero(db, U64(sizeof(Column) * u64(u32(n_alloc)))))
	p_new.zName = sqlite3_mp_rintf(db, c'sqlite_altertab_%s', voidptr(p_tab.zName))
	if isnil(p_new.aCol) || isnil(p_new.zName) {
		unsafe { goto exit_begin_add_column
		 }
	}
	C.memcpy(voidptr(p_new.aCol), voidptr(p_tab.aCol), sizeof(Column) * usize(p_new.nCol))
	for i = 0; i < int(p_new.nCol); i++ {
		p_col := unsafe { p_new.aCol + i }
		p_col.zCnName = sqlite3_db_str_dup(db, p_col.zCnName)
		p_col.hName = sqlite3_str_ih_ash(p_col.zCnName)
	}
	p_new.u.tab.pDfltList = sqlite3_expr_list_dup(db, p_tab.u.tab.pDfltList, 0)
	p_new.pSchema = db.aDb[i_db].pSchema
	p_new.u.tab.addColOffset = p_tab.u.tab.addColOffset
	exit_begin_add_column:
	sqlite3_src_list_delete(db, p_src)
	return
}

@[c:'isRealTable']
fn is_real_table(p_parse &Parse, p_tab &Table, i_op int) int {
	z_type := unsafe { &i8(nil) }
	if (int(p_tab.eTabType) == 2) {
		z_type = c'view'
	}
	if (int(p_tab.eTabType) == 1) {
		z_type = c'virtual table'
	}
	if z_type {
		az_msg := [c'rename columns of', c'drop column from', c'edit constraints of']

		sqlite3_error_msg(p_parse, c'cannot %s %s "%s"', voidptr(az_msg[i_op]), voidptr(z_type), voidptr(p_tab.zName))
		return 1
	}
	return 0
}

@[c:'sqlite3AlterRenameColumn']
fn sqlite3_alter_rename_column(p_parse &Parse, p_src &SrcList, p_old &Token, p_new &Token) {
	db := p_parse.db
	p_tab := &Table(0)
	i_col := 0
	z_old := unsafe { &i8(nil) }
	z_new := unsafe { &i8(nil) }
	z_db := &i8(0)
	i_schema := 0
	b_quote := 0
	p_tab = sqlite3_locate_table_item(p_parse, u32(0), unsafe { &p_src.a[0] + 0 })
	if isnil(p_tab) {
		unsafe { goto exit_rename_column
		 }
	}
	if 0 != is_alterable_table(p_parse, p_tab) {
		unsafe { goto exit_rename_column
		 }
	}
	if 0 != is_real_table(p_parse, p_tab, 0) {
		unsafe { goto exit_rename_column
		 }
	}
	i_schema = sqlite3_schema_to_index(db, p_tab.pSchema)
	z_db = db.aDb[i_schema].zDbSName
	if sqlite3_auth_check(p_parse, 26, z_db, p_tab.zName, unsafe { nil }) {
		unsafe { goto exit_rename_column
		 }
	}
	z_old = sqlite3_name_from_token(db, p_old)
	if isnil(z_old) {
		unsafe { goto exit_rename_column
		 }
	}
	i_col = sqlite3_column_index(p_tab, z_old)
	if i_col < 0 {
		sqlite3_error_msg(p_parse, c'no such column: "%T"', voidptr(p_old))
		unsafe { goto exit_rename_column
		 }
	}
	rename_test_schema(p_parse, z_db, i_schema == 1, c'', 0)
	rename_fix_quotes(p_parse, z_db, i_schema == 1)
	sqlite3_may_abort(p_parse)
	z_new = sqlite3_name_from_token(db, p_new)
	if isnil(z_new) {
		unsafe { goto exit_rename_column
		 }
	}
	b_quote = (int(sqlite3CtypeMap[u8(p_new.z[0])]) & 128)
	sqlite3_nested_parse(p_parse, c'UPDATE "%w".sqlite_master SET sql = sqlite_rename_column(sql, type, name, %Q, %Q, %d, %Q, %d, %d) WHERE name NOT LIKE \'sqliteX_%%\' ESCAPE \'X\'  AND (type != \'index\' OR tbl_name = %Q)', voidptr(z_db), voidptr(z_db), voidptr(p_tab.zName), i_col, voidptr(z_new), b_quote, i_schema == 1, voidptr(p_tab.zName))
	sqlite3_nested_parse(p_parse, c"UPDATE temp.sqlite_master SET sql = sqlite_rename_column(sql, type, name, %Q, %Q, %d, %Q, %d, 1) WHERE type IN ('trigger', 'view')", voidptr(z_db), voidptr(p_tab.zName), i_col, voidptr(z_new), b_quote)
	rename_reload_schema(p_parse, i_schema, U16(1))
	rename_test_schema(p_parse, z_db, i_schema == 1, c'after rename', 1)
	exit_rename_column:
	sqlite3_src_list_delete(db, p_src)
	sqlite3_db_free(db, voidptr(z_old))
	sqlite3_db_free(db, voidptr(z_new))
	return
}

struct RenameToken {
	p     voidptr
	t     Token
	pNext &RenameToken
}

struct RenameCtx {
	pList &RenameToken
	nList int
	iCol  int
	pTab  &Table
	zOld  &i8
}

@[c:'sqlite3RenameTokenMap']
fn sqlite3_rename_token_map(p_parse &Parse, p_ptr voidptr, p_token &Token) voidptr {
	p_new := &RenameToken(0)
	0
	if (int(p_parse.eParseMode) != 3) {
		p_new = sqlite3_db_malloc_zero(p_parse.db, U64(sizeof(RenameToken)))
		if p_new {
			p_new.p = p_ptr
			p_new.t = unsafe { *p_token }
			p_new.pNext = p_parse.pRename
			p_parse.pRename = p_new
		}
	}
	return p_ptr
}

@[c:'sqlite3RenameTokenRemap']
fn sqlite3_rename_token_remap(p_parse &Parse, p_to voidptr, p_from voidptr) {
	p := &RenameToken(0)
	0
	for p = p_parse.pRename; p; p = p.pNext {
		if usize(p.p) == usize(p_from) {
			p.p = p_to
			break
		}
	}
}

@[c:'renameUnmapExprCb']
fn rename_unmap_expr_cb(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	p_parse := p_walker.pParse
	sqlite3_rename_token_remap(p_parse, unsafe { nil }, voidptr(p_expr))
	if ((p_expr.flags & u32((16777216 | 33554432))) == u32(0)) {
		sqlite3_rename_token_remap(p_parse, unsafe { nil }, voidptr(&p_expr.y.pTab))
	}
	return 0
}

@[c:'renameWalkWith']
fn rename_walk_with(p_walker &Walker, p_select &Select) {
	p_with := p_select.pWith
	if p_with {
		p_parse := p_walker.pParse
		i := 0
		p_copy := unsafe { &With(nil) }
		if (c2v_at(&p_with.a[0], isize(0)).pSelect.selFlags & u32(64)) == u32(0) {
			p_copy = sqlite3_with_dup(p_parse.db, p_with)
			p_copy = sqlite3_with_push(p_parse, p_copy, U8(1))
		}
		for i = 0; i < p_with.nCte; i++ {
			p := c2v_at(&p_with.a[0], isize(i)).pSelect
			snc := NameContext{}
			C.memset(voidptr(&snc), 0, sizeof(snc))
			snc.pParse = p_parse
			if p_copy {
				sqlite3_select_prep(snc.pParse, p, &snc)
			}
			if snc.pParse.db.mallocFailed {
				return
			}
			sqlite3_walk_select(p_walker, p)
			sqlite3_rename_exprlist_unmap(p_parse, c2v_at(&p_with.a[0], isize(i)).pCols)
		}
		if !isnil(p_copy) && usize(p_parse.pWith) == usize(p_copy) {
			p_parse.pWith = p_copy.pOuter
		}
	}
}

@[c:'unmapColumnIdlistNames']
fn unmap_column_idlist_names(p_parse &Parse, p_id_list &IdList) {
	ii := 0
	for ii = 0; ii < p_id_list.nId; ii++ {
		sqlite3_rename_token_remap(p_parse, unsafe { nil }, voidptr(c2v_at(&p_id_list.a[0], isize(ii)).zName))
	}
}

@[c:'renameUnmapSelectCb']
fn rename_unmap_select_cb(p_walker &Walker, p &Select) int {
	c2v_gc_register_thread()
	p_parse := p_walker.pParse
	i := 0
	if p_parse.nErr {
		return 2
	}
	0
	0
	if p.selFlags & u32((2097152 | 67108864)) {
		return 1
	}
	if p.pEList {
		p_list := p.pEList
		for i = 0; i < p_list.nExpr; i++ {
			if !isnil(c2v_at(&p_list.a[0], isize(i)).zEName) && int(c2v_at(&p_list.a[0], isize(i)).fg.eEName) == 0 {
				sqlite3_rename_token_remap(p_parse, unsafe { nil }, voidptr(c2v_at(&p_list.a[0], isize(i)).zEName))
			}
		}
	}
	if p.pSrc {
		p_src := p.pSrc
		for i = 0; i < p_src.nSrc; i++ {
			sqlite3_rename_token_remap(p_parse, unsafe { nil }, voidptr(c2v_at(&p_src.a[0], isize(i)).zName))
			if int(c2v_at(&p_src.a[0], isize(i)).fg.isUsing) == 0 {
				sqlite3_walk_expr(p_walker, c2v_at(&p_src.a[0], isize(i)).u3.pOn)
			} else {
				unmap_column_idlist_names(p_parse, c2v_at(&p_src.a[0], isize(i)).u3.pUsing)
			}
		}
	}
	rename_walk_with(p_walker, p)
	return 0
}

@[c:'sqlite3RenameExprUnmap']
fn sqlite3_rename_expr_unmap(p_parse &Parse, p_expr &Expr) {
	e_mode := p_parse.eParseMode
	s_walker := Walker{}
	C.memset(voidptr(&s_walker), 0, sizeof(Walker))
	s_walker.pParse = p_parse
	s_walker.xExprCallback = rename_unmap_expr_cb
	s_walker.xSelectCallback = rename_unmap_select_cb
	p_parse.eParseMode = U8(3)
	sqlite3_walk_expr(&s_walker, p_expr)
	p_parse.eParseMode = e_mode
}

@[c:'sqlite3RenameExprlistUnmap']
fn sqlite3_rename_exprlist_unmap(p_parse &Parse, pel_ist &ExprList) {
	if pel_ist {
		i := 0
		s_walker := Walker{}
		C.memset(voidptr(&s_walker), 0, sizeof(Walker))
		s_walker.pParse = p_parse
		s_walker.xExprCallback = rename_unmap_expr_cb
		sqlite3_walk_expr_list(&s_walker, pel_ist)
		for i = 0; i < pel_ist.nExpr; i++ {
			if (int(c2v_at(&pel_ist.a[0], isize(i)).fg.eEName) == 0) {
				sqlite3_rename_token_remap(p_parse, unsafe { nil }, voidptr(c2v_at(&pel_ist.a[0], isize(i)).zEName))
			}
		}
	}
}

@[c:'renameTokenFree']
fn rename_token_free(db &Sqlite3, p_token &RenameToken) {
	p_next := &RenameToken(0)
	p := &RenameToken(0)
	for p = p_token; p; p = p_next {
		p_next = p.pNext
		sqlite3_db_free(db, voidptr(p))
	}
}

@[c:'renameTokenFind']
fn rename_token_find(p_parse &Parse, p_ctx &RenameCtx, p_ptr voidptr) &RenameToken {
	pp := &&RenameToken(0)
	if (usize(p_ptr) == usize(0)) {
		return unsafe { nil }
	}
	for pp = &p_parse.pRename; (unsafe { *pp }); pp = &(unsafe { *pp }).pNext {
		if usize((unsafe { *pp }).p) == usize(p_ptr) {
			p_token := (unsafe { *pp })
			if p_ctx {
				unsafe { *pp = p_token.pNext }
				p_token.pNext = p_ctx.pList
				p_ctx.pList = p_token
				p_ctx.nList++
			}
			return p_token
		}
	}
	return unsafe { nil }
}

@[c:'renameColumnSelectCb']
fn rename_column_select_cb(p_walker &Walker, p &Select) int {
	c2v_gc_register_thread()
	if p.selFlags & u32((2097152 | 67108864)) {
		0
		0
		return 1
	}
	rename_walk_with(p_walker, p)
	return 0
}

@[c:'renameColumnExprCb']
fn rename_column_expr_cb(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	p := p_walker.u.pRename
	if int(p_expr.op) == 78 && int(p_expr.iColumn) == p.iCol && usize(p_walker.pParse.pTriggerTab) == usize(p.pTab) {
		rename_token_find(p_walker.pParse, p, voidptr(p_expr))
	} else if int(p_expr.op) == 168 && int(p_expr.iColumn) == p.iCol && ((p_expr.flags & u32((16777216 | 33554432))) == u32(0)) && usize(p.pTab) == usize(p_expr.y.pTab) {
		rename_token_find(p_walker.pParse, p, voidptr(p_expr))
	}
	return 0
}

@[c:'renameColumnTokenNext']
fn rename_column_token_next(p_ctx &RenameCtx) &RenameToken {
	p_best := p_ctx.pList
	p_token := &RenameToken(0)
	pp := &&RenameToken(0)
	for p_token = p_best.pNext; p_token; p_token = p_token.pNext {
		if usize(p_token.t.z) > usize(p_best.t.z) {
			p_best = p_token
		}
	}
	for pp = &p_ctx.pList; usize((unsafe { *pp })) != usize(p_best); pp = &(unsafe { *pp }).pNext {
		0
	}
	unsafe { *pp = p_best.pNext }
	return p_best
}

@[c:'errorMPrintf']
@[c2v_variadic]
fn error_mp_rintf(p_ctx &Sqlite3_context, z_fmt &i8, ...) {
	db := sqlite3_context_db_handle(p_ctx)
	z_err := unsafe { &i8(nil) }
	ap := C.va_list{}
	C.va_start(ap, z_fmt)
	z_err = sqlite3_vm_printf(db, z_fmt, ap)
	C.va_end(ap)
	if z_err {
		sqlite3_result_error(p_ctx, z_err, -1)
		sqlite3_db_free(db, voidptr(z_err))
	} else {
		sqlite3_result_error_nomem(p_ctx)
	}
}

@[c:'renameColumnParseError']
fn rename_column_parse_error(p_ctx &Sqlite3_context, z_when &i8, p_type &Sqlite3_value, p_object &Sqlite3_value, p_parse &Parse) {
	zt := &i8(voidptr(sqlite3_value_text(p_type)))
	zn := &i8(voidptr(sqlite3_value_text(p_object)))
	z_err := &i8(0)
	z_err = sqlite3_mp_rintf(p_parse.db, c'error in %s %s%s%s: %s', voidptr(zt), voidptr(zn), voidptr((if int(z_when[0]) {
		c' '
	} else {
		c''
	})), voidptr(z_when), voidptr(p_parse.zErrMsg))
	sqlite3_result_error(p_ctx, z_err, -1)
	sqlite3_db_free(p_parse.db, voidptr(z_err))
}

@[c:'renameColumnElistNames']
fn rename_column_elist_names(p_parse &Parse, p_ctx &RenameCtx, pel_ist &ExprList, z_old &i8) {
	if pel_ist {
		i := 0
		for i = 0; i < pel_ist.nExpr; i++ {
			z_name := c2v_at(&pel_ist.a[0], isize(i)).zEName
			if (int(c2v_at(&pel_ist.a[0], isize(i)).fg.eEName) == 0) && (usize(z_name) != usize(0)) && 0 == sqlite3_stricmp(z_name, z_old) {
				rename_token_find(p_parse, p_ctx, voidptr(z_name))
			}
		}
	}
}

@[c:'renameColumnIdlistNames']
fn rename_column_idlist_names(p_parse &Parse, p_ctx &RenameCtx, p_id_list &IdList, z_old &i8) {
	if p_id_list {
		i := 0
		for i = 0; i < p_id_list.nId; i++ {
			z_name := c2v_at(&p_id_list.a[0], isize(i)).zName
			if 0 == sqlite3_stricmp(z_name, z_old) {
				rename_token_find(p_parse, p_ctx, voidptr(z_name))
			}
		}
	}
}

@[c:'renameParseSql']
fn rename_parse_sql(p &Parse, z_db &i8, db &Sqlite3, z_sql &i8, b_temp int) int {
	rc := 0
	flags := U64(0)
	sqlite3_parse_object_init(p, db)
	if usize(z_sql) == usize(0) {
		return 7
	}
	if sqlite3_strnicmp(z_sql, c'CREATE ', 7) != 0 {
		return sqlite3_corrupt_error(1168)
	}
	if b_temp {
		db.init.iDb = U8(1)
	} else {
		i_db := sqlite3_find_db_name(db, z_db)
		db.init.iDb = U8(i_db)
	}
	p.eParseMode = U8(2)
	p.db = db
	p.nQueryLoop = LogEst(1)
	flags = db.flags
	0
	db.flags |= (U64(64) << 32)
	rc = sqlite3_run_parser(p, z_sql)
	db.flags = flags
	if db.mallocFailed {
		rc = 7
	}
	if rc == 0 && (usize(p.pNewTable) == usize(0) && usize(p.pNewIndex) == usize(0) && usize(p.pNewTrigger) == usize(0)) {
		rc = sqlite3_corrupt_error(1189)
	}
	db.init.iDb = U8(0)
	return rc
}

@[c:'renameEditSql']
fn rename_edit_sql(p_ctx &Sqlite3_context, p_rename &RenameCtx, z_sql &i8, z_new &i8, b_quote int) int {
	n_new := I64(sqlite3_strlen30(z_new))
	n_sql := I64(sqlite3_strlen30(z_sql))
	db := sqlite3_context_db_handle(p_ctx)
	rc := 0
	z_quot := unsafe { &i8(nil) }
	z_out := &i8(0)
	n_quot := I64(0)
	z_buf1 := unsafe { &i8(nil) }
	z_buf2 := unsafe { &i8(nil) }
	if z_new {
		z_quot = sqlite3_mp_rintf(db, c'"%w" ', voidptr(z_new))
		if usize(z_quot) == usize(0) {
			return 7
		} else {
			n_quot = I64(sqlite3_strlen30(z_quot) - 1)
		}
		z_out = &i8(sqlite3_db_malloc_zero(db, U64(n_sql) + U64(p_rename.nList) * U64(n_quot) + U64(1)))
	} else {
		z_out = &i8(sqlite3_db_malloc_zero(db, (U64(2) * U64(n_sql) + U64(1)) * U64(3)))
		if z_out {
			z_buf1 = unsafe { z_out + (n_sql * I64(2) + I64(1)) }
			z_buf2 = unsafe { z_out + (n_sql * I64(4) + I64(2)) }
		}
	}
	if z_out {
		n_out := n_sql
		C.memcpy(voidptr(z_out), voidptr(z_sql), usize(n_sql))
		for p_rename.pList {
			i_off := 0
			n_replace := I64(0)
			z_replace := &i8(0)
			p_best := rename_column_token_next(p_rename)
			if z_new {
				if b_quote == 0 && sqlite3_is_id_char((unsafe { *&U8(voidptr(p_best.t.z)) })) {
					n_replace = n_new
					z_replace = z_new
				} else {
					n_replace = n_quot
					z_replace = z_quot
					if int(p_best.t.z[p_best.t.n]) == i8(`\"`) {
						n_replace++
					}
				}
			} else {
				C.memcpy(voidptr(z_buf1), voidptr(p_best.t.z), u64(p_best.t.n))
				z_buf1[p_best.t.n] = i8(0)
				sqlite3_dequote(z_buf1)
				sqlite3_snprintf(int((n_sql * I64(2))), z_buf2, c'%Q%s', voidptr(z_buf1), voidptr(if int(p_best.t.z[p_best.t.n]) == i8(`\'`) {
					c' '
				} else {
					c''
				}))
				z_replace = z_buf2
				n_replace = I64(sqlite3_strlen30(z_replace))
			}
			i_off = int((i64((isize(p_best.t.z) - isize(z_sql)) / isize(sizeof(i8)))))
			if I64(p_best.t.n) != n_replace {
				C.memmove(voidptr(unsafe { z_out + (I64(i_off) + n_replace) }), voidptr(unsafe { z_out + (u32(i_off) + p_best.t.n) }), u64(n_out - I64((u32(i_off) + p_best.t.n))))
				n_out += n_replace - I64(p_best.t.n)
				z_out[n_out] = i8(`\0`)
			}
			C.memcpy(voidptr(unsafe { z_out + i_off }), voidptr(z_replace), u64(n_replace))
			sqlite3_db_free(db, voidptr(p_best))
		}
		sqlite3_result_text(p_ctx, z_out, -1, (C2vFn_666e2028766f696470747229(voidptr(-1))))
		sqlite3_db_free(db, voidptr(z_out))
	} else {
		rc = 7
	}
	sqlite3_free(voidptr(z_quot))
	return rc
}

@[c:'renameSetENames']
fn rename_set_en_ames(pel_ist &ExprList, val int) {
	if pel_ist {
		i := 0
		for i = 0; i < pel_ist.nExpr; i++ {
			mut __c2v_lhs_tmp_104 := c2v_at(&pel_ist.a[0], isize(i))
			__c2v_lhs_tmp_104.fg.eEName = u32(val & 3)
		}
	}
}

@[c:'renameResolveTrigger']
fn rename_resolve_trigger(p_parse &Parse) int {
	db := p_parse.db
	p_new := p_parse.pNewTrigger
	p_step := &TriggerStep(0)
	snc := NameContext{}
	rc := 0
	C.memset(voidptr(&snc), 0, sizeof(snc))
	snc.pParse = p_parse
	p_parse.pTriggerTab = sqlite3_find_table(db, p_new.table, db.aDb[sqlite3_schema_to_index(db, p_new.pTabSchema)].zDbSName)
	p_parse.eTriggerOp = p_new.op
	if p_parse.pTriggerTab {
		rc = sqlite3_view_get_column_names(p_parse, p_parse.pTriggerTab) != 0
	}
	if rc == 0 && !isnil(p_new.pWhen) {
		rc = sqlite3_resolve_expr_names(&snc, p_new.pWhen)
	}
	for p_step = p_new.step_list; rc == 0 && !isnil(p_step); p_step = p_step.pNext {
		if p_step.pSelect {
			sqlite3_select_prep(p_parse, p_step.pSelect, &snc)
			if p_parse.nErr {
				rc = p_parse.rc
			}
		}
		if rc == 0 && !isnil(p_step.pSrc) {
			p_src := sqlite3_src_list_dup(db, p_step.pSrc, 0)
			if p_src {
				p_sel := sqlite3_select_new(p_parse, p_step.pExprList, p_src, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, u32(0), unsafe { nil })
				if usize(p_sel) == usize(0) {
					p_step.pExprList = 0
					p_src = 0
					rc = 7
				} else {
					rename_set_en_ames(p_step.pExprList, 1)
					sqlite3_select_prep(p_parse, p_sel, unsafe { nil })
					rename_set_en_ames(p_step.pExprList, 0)
					rc = if p_parse.nErr { 1 } else { 0 }
					if p_step.pExprList {
						p_sel.pEList = 0
					}
					p_sel.pSrc = 0
					sqlite3_select_delete(db, p_sel)
				}
				if p_step.pSrc {
					i := 0
					for i = 0; i < p_step.pSrc.nSrc && rc == 0; i++ {
						p := unsafe { &p_step.pSrc.a[0] + i }
						if p.fg.isSubquery {
							sqlite3_select_prep(p_parse, p.u4.pSubq.pSelect, unsafe { nil })
						}
					}
				}
				if db.mallocFailed {
					rc = 7
				}
				snc.pSrcList = p_src
				if rc == 0 && !isnil(p_step.pWhere) {
					rc = sqlite3_resolve_expr_names(&snc, p_step.pWhere)
				}
				if rc == 0 {
					rc = sqlite3_resolve_expr_list_names(&snc, p_step.pExprList)
				}
				if !isnil(p_step.pUpsert) && rc == 0 {
					p_upsert := p_step.pUpsert
					p_upsert.pUpsertSrc = p_src
					snc.uNC.pUpsert = p_upsert
					snc.ncFlags = 512
					rc = sqlite3_resolve_expr_list_names(&snc, p_upsert.pUpsertTarget)
					if rc == 0 {
						p_upsert_set := p_upsert.pUpsertSet
						rc = sqlite3_resolve_expr_list_names(&snc, p_upsert_set)
					}
					if rc == 0 {
						rc = sqlite3_resolve_expr_names(&snc, p_upsert.pUpsertWhere)
					}
					if rc == 0 {
						rc = sqlite3_resolve_expr_names(&snc, p_upsert.pUpsertTargetWhere)
					}
					snc.ncFlags = 0
				}
				snc.pSrcList = 0
				sqlite3_src_list_delete(db, p_src)
			} else {
				rc = 7
			}
		}
	}
	return rc
}

@[c:'renameWalkTrigger']
fn rename_walk_trigger(p_walker &Walker, p_trigger &Trigger) {
	p_step := &TriggerStep(0)
	sqlite3_walk_expr(p_walker, p_trigger.pWhen)
	for p_step = p_trigger.step_list; p_step; p_step = p_step.pNext {
		sqlite3_walk_select(p_walker, p_step.pSelect)
		sqlite3_walk_expr(p_walker, p_step.pWhere)
		sqlite3_walk_expr_list(p_walker, p_step.pExprList)
		if p_step.pUpsert {
			p_upsert := p_step.pUpsert
			sqlite3_walk_expr_list(p_walker, p_upsert.pUpsertTarget)
			sqlite3_walk_expr_list(p_walker, p_upsert.pUpsertSet)
			sqlite3_walk_expr(p_walker, p_upsert.pUpsertWhere)
			sqlite3_walk_expr(p_walker, p_upsert.pUpsertTargetWhere)
		}
		if p_step.pSrc {
			i := 0
			p_src := p_step.pSrc
			for i = 0; i < p_src.nSrc; i++ {
				if c2v_at(&p_src.a[0], isize(i)).fg.isSubquery {
					sqlite3_walk_select(p_walker, c2v_at(&p_src.a[0], isize(i)).u4.pSubq.pSelect)
				}
			}
		}
	}
}

@[c:'renameParseCleanup']
fn rename_parse_cleanup(p_parse &Parse) {
	db := p_parse.db
	p_idx := &Index(0)
	if p_parse.pVdbe {
		sqlite3_vdbe_finalize(p_parse.pVdbe)
	}
	sqlite3_delete_table(db, p_parse.pNewTable)
	for {
		p_idx = p_parse.pNewIndex
		if !(usize(p_idx) != usize(0)) {
			break
		}
		p_parse.pNewIndex = p_idx.pNext
		sqlite3_free_index(db, p_idx)
	}
	sqlite3_delete_trigger(db, p_parse.pNewTrigger)
	sqlite3_db_free(db, voidptr(p_parse.zErrMsg))
	rename_token_free(db, p_parse.pRename)
	sqlite3_parse_object_reset(p_parse)
}

@[c:'renameColumnFunc']
fn rename_column_func(context &Sqlite3_context, not_used int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	db := sqlite3_context_db_handle(context)
	s_ctx := RenameCtx{}
	z_sql := &i8(voidptr(sqlite3_value_text(argv[0])))
	z_db := &i8(voidptr(sqlite3_value_text(argv[3])))
	z_table := &i8(voidptr(sqlite3_value_text(argv[4])))
	i_col := sqlite3_value_int(argv[5])
	z_new := &i8(voidptr(sqlite3_value_text(argv[6])))
	b_quote := sqlite3_value_int(argv[7])
	b_temp := sqlite3_value_int(argv[8])
	z_old := &i8(0)
	rc := 0
	s_parse := Parse{}
	s_walker := Walker{}
	p_idx := &Index(0)
	i := 0
	p_tab := &Table(0)
	x_auth := db.xAuth

	if usize(z_sql) == usize(0) {
		return
	}
	if usize(z_table) == usize(0) {
		return
	}
	if usize(z_new) == usize(0) {
		return
	}
	if i_col < 0 {
		return
	}
	sqlite3_btree_enter_all(db)
	p_tab = sqlite3_find_table(db, z_table, z_db)
	if usize(p_tab) == usize(0) || i_col >= int(p_tab.nCol) {
		sqlite3_btree_leave_all(db)
		return
	}
	z_old = p_tab.aCol[i_col].zCnName
	C.memset(voidptr(&s_ctx), 0, sizeof(s_ctx))
	s_ctx.iCol = (if (i_col == int(p_tab.iPKey)) { -1 } else { i_col })
	db.xAuth = 0
	rc = rename_parse_sql(&s_parse, z_db, db, z_sql, b_temp)
	C.memset(voidptr(&s_walker), 0, sizeof(Walker))
	s_walker.pParse = &s_parse
	s_walker.xExprCallback = rename_column_expr_cb
	s_walker.xSelectCallback = rename_column_select_cb
	s_walker.u.pRename = &s_ctx
	s_ctx.pTab = p_tab
	if rc != 0 {
		unsafe { goto renameColumnFunc_done
		 }
	}
	if s_parse.pNewTable {
		if (int(s_parse.pNewTable.eTabType) == 2) {
			p_select := s_parse.pNewTable.u.view.pSelect
			p_select.selFlags &= ~u32(2097152)
			s_parse.rc = 0
			sqlite3_select_prep(&s_parse, p_select, unsafe { nil })
			rc = (if int(db.mallocFailed) { 7 } else { s_parse.rc })
			if rc == 0 {
				sqlite3_walk_select(&s_walker, p_select)
			}
			if rc != 0 {
				unsafe { goto renameColumnFunc_done
				 }
			}
		} else if (int(s_parse.pNewTable.eTabType) == 0) {
			bfk_only := sqlite3_stricmp(z_table, s_parse.pNewTable.zName)
			pfk_ey := &FKey(0)
			s_ctx.pTab = s_parse.pNewTable
			if bfk_only == 0 {
				if i_col < int(s_parse.pNewTable.nCol) {
					rename_token_find(&s_parse, &s_ctx, voidptr(s_parse.pNewTable.aCol[i_col].zCnName))
				}
				if s_ctx.iCol < 0 {
					rename_token_find(&s_parse, &s_ctx, voidptr(&s_parse.pNewTable.iPKey))
				}
				sqlite3_walk_expr_list(&s_walker, s_parse.pNewTable.pCheck)
				for p_idx = s_parse.pNewTable.pIndex; p_idx; p_idx = p_idx.pNext {
					sqlite3_walk_expr_list(&s_walker, p_idx.aColExpr)
				}
				for p_idx = s_parse.pNewIndex; p_idx; p_idx = p_idx.pNext {
					sqlite3_walk_expr_list(&s_walker, p_idx.aColExpr)
				}
				for i = 0; i < int(s_parse.pNewTable.nCol); i++ {
					p_expr := sqlite3_column_expr(s_parse.pNewTable, unsafe { s_parse.pNewTable.aCol + i })
					sqlite3_walk_expr(&s_walker, p_expr)
				}
			}
			for pfk_ey = s_parse.pNewTable.u.tab.pFKey; pfk_ey; pfk_ey = pfk_ey.pNextFrom {
				for i = 0; i < pfk_ey.nCol; i++ {
					if bfk_only == 0 && c2v_at(&pfk_ey.aCol[0], isize(i)).iFrom == i_col {
						rename_token_find(&s_parse, &s_ctx, voidptr(unsafe { &pfk_ey.aCol[0] + i }))
					}
					if 0 == sqlite3_stricmp(pfk_ey.zTo, z_table) && 0 == sqlite3_stricmp(c2v_at(&pfk_ey.aCol[0], isize(i)).zCol, z_old) {
						rename_token_find(&s_parse, &s_ctx, voidptr(c2v_at(&pfk_ey.aCol[0], isize(i)).zCol))
					}
				}
			}
		}
	} else if s_parse.pNewIndex {
		sqlite3_walk_expr_list(&s_walker, s_parse.pNewIndex.aColExpr)
		sqlite3_walk_expr(&s_walker, s_parse.pNewIndex.pPartIdxWhere)
	} else {
		p_step := &TriggerStep(0)
		rc = rename_resolve_trigger(&s_parse)
		if rc != 0 {
			unsafe { goto renameColumnFunc_done
			 }
		}
		for p_step = s_parse.pNewTrigger.step_list; p_step; p_step = p_step.pNext {
			if p_step.pSrc {
				p_target := sqlite3_locate_table_item(&s_parse, u32(0), unsafe { &p_step.pSrc.a[0] + 0 })
				if usize(p_target) == usize(p_tab) {
					if p_step.pUpsert {
						p_upsert_set := p_step.pUpsert.pUpsertSet
						rename_column_elist_names(&s_parse, &s_ctx, p_upsert_set, z_old)
					}
					rename_column_idlist_names(&s_parse, &s_ctx, p_step.pIdList, z_old)
					rename_column_elist_names(&s_parse, &s_ctx, p_step.pExprList, z_old)
				}
			}
		}
		if usize(s_parse.pTriggerTab) == usize(p_tab) {
			rename_column_idlist_names(&s_parse, &s_ctx, s_parse.pNewTrigger.pColumns, z_old)
		}
		rename_walk_trigger(&s_walker, s_parse.pNewTrigger)
	}
	rc = rename_edit_sql(context, &s_ctx, z_sql, z_new, b_quote)
	renameColumnFunc_done:
	if rc != 0 {
		if rc == 1 && sqlite3_writable_schema(db) {
			sqlite3_result_value(context, argv[0])
		} else if s_parse.zErrMsg {
			rename_column_parse_error(context, c'', argv[1], argv[2], &s_parse)
		} else {
			sqlite3_result_error_code(context, rc)
		}
	}
	rename_parse_cleanup(&s_parse)
	rename_token_free(db, s_ctx.pList)
	db.xAuth = x_auth
	sqlite3_btree_leave_all(db)
}

@[c:'renameTableExprCb']
fn rename_table_expr_cb(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	p := p_walker.u.pRename
	if int(p_expr.op) == 168 && ((p_expr.flags & u32((16777216 | 33554432))) == u32(0)) && usize(p.pTab) == usize(p_expr.y.pTab) {
		rename_token_find(p_walker.pParse, p, voidptr(&p_expr.y.pTab))
	}
	return 0
}

@[c:'renameTableSelectCb']
fn rename_table_select_cb(p_walker &Walker, p_select &Select) int {
	c2v_gc_register_thread()
	i := 0
	p := p_walker.u.pRename
	p_src := p_select.pSrc
	if p_select.selFlags & u32((2097152 | 67108864)) {
		0
		0
		return 1
	}
	if (usize(p_src) == usize(0)) {
		return 2
	}
	for i = 0; i < p_src.nSrc; i++ {
		p_item := unsafe { &p_src.a[0] + i }
		if usize(p_item.pSTab) == usize(p.pTab) {
			rename_token_find(p_walker.pParse, p, voidptr(p_item.zName))
		}
	}
	rename_walk_with(p_walker, p_select)
	return 0
}

@[c:'renameTableFunc']
fn rename_table_func(context &Sqlite3_context, not_used int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	db := sqlite3_context_db_handle(context)
	z_db := &i8(voidptr(sqlite3_value_text(argv[0])))
	z_input := &i8(voidptr(sqlite3_value_text(argv[3])))
	z_old := &i8(voidptr(sqlite3_value_text(argv[4])))
	z_new := &i8(voidptr(sqlite3_value_text(argv[5])))
	b_temp := sqlite3_value_int(argv[6])

	if !isnil(z_input) && !isnil(z_old) && !isnil(z_new) {
		s_parse := Parse{}
		rc := 0
		b_quote := 1
		s_ctx := RenameCtx{}
		s_walker := Walker{}
		x_auth := db.xAuth
		db.xAuth = 0
		sqlite3_btree_enter_all(db)
		C.memset(voidptr(&s_ctx), 0, sizeof(RenameCtx))
		s_ctx.pTab = sqlite3_find_table(db, z_old, z_db)
		C.memset(voidptr(&s_walker), 0, sizeof(Walker))
		s_walker.pParse = &s_parse
		s_walker.xExprCallback = rename_table_expr_cb
		s_walker.xSelectCallback = rename_table_select_cb
		s_walker.u.pRename = &s_ctx
		rc = rename_parse_sql(&s_parse, z_db, db, z_input, b_temp)
		if rc == 0 {
			is_legacy := int((db.flags & U64(67108864)))
			if s_parse.pNewTable {
				p_tab := s_parse.pNewTable
				if (int(p_tab.eTabType) == 2) {
					if is_legacy == 0 {
						p_select := p_tab.u.view.pSelect
						snc := NameContext{}
						C.memset(voidptr(&snc), 0, sizeof(snc))
						snc.pParse = &s_parse
						p_select.selFlags &= ~u32(2097152)
						sqlite3_select_prep(&s_parse, p_tab.u.view.pSelect, &snc)
						if s_parse.nErr {
							rc = s_parse.rc
						} else {
							sqlite3_walk_select(&s_walker, p_tab.u.view.pSelect)
						}
					}
				} else {
					if (is_legacy == 0 || (db.flags & U64(16384))) && !(int(p_tab.eTabType) == 1) {
						pfk_ey := &FKey(0)
						for pfk_ey = p_tab.u.tab.pFKey; pfk_ey; pfk_ey = pfk_ey.pNextFrom {
							if sqlite3_stricmp(pfk_ey.zTo, z_old) == 0 {
								rename_token_find(&s_parse, &s_ctx, voidptr(pfk_ey.zTo))
							}
						}
					}
					if sqlite3_stricmp(z_old, p_tab.zName) == 0 {
						s_ctx.pTab = p_tab
						if is_legacy == 0 {
							sqlite3_walk_expr_list(&s_walker, p_tab.pCheck)
						}
						rename_token_find(&s_parse, &s_ctx, voidptr(p_tab.zName))
					}
				}
			} else if s_parse.pNewIndex {
				rename_token_find(&s_parse, &s_ctx, voidptr(s_parse.pNewIndex.zName))
				if is_legacy == 0 {
					sqlite3_walk_expr(&s_walker, s_parse.pNewIndex.pPartIdxWhere)
				}
			} else {
				p_trigger := s_parse.pNewTrigger
				p_step := &TriggerStep(0)
				if 0 == sqlite3_stricmp(s_parse.pNewTrigger.table, z_old) && usize(s_ctx.pTab.pSchema) == usize(p_trigger.pTabSchema) {
					rename_token_find(&s_parse, &s_ctx, voidptr(s_parse.pNewTrigger.table))
				}
				if is_legacy == 0 {
					rc = rename_resolve_trigger(&s_parse)
					if rc == 0 {
						rename_walk_trigger(&s_walker, p_trigger)
						for p_step = p_trigger.step_list; p_step; p_step = p_step.pNext {
							if p_step.pSrc {
								i := 0
								for i = 0; i < p_step.pSrc.nSrc; i++ {
									p_item := unsafe { &p_step.pSrc.a[0] + i }
									if 0 == sqlite3_stricmp(p_item.zName, z_old) {
										rename_token_find(&s_parse, &s_ctx, voidptr(p_item.zName))
									}
								}
							}
						}
					}
				}
			}
		}
		if rc == 0 {
			rc = rename_edit_sql(context, &s_ctx, z_input, z_new, b_quote)
		}
		if rc != 0 {
			if rc == 1 && sqlite3_writable_schema(db) {
				sqlite3_result_value(context, argv[3])
			} else if s_parse.zErrMsg {
				rename_column_parse_error(context, c'', argv[1], argv[2], &s_parse)
			} else {
				sqlite3_result_error_code(context, rc)
			}
		}
		rename_parse_cleanup(&s_parse)
		rename_token_free(db, s_ctx.pList)
		sqlite3_btree_leave_all(db)
		db.xAuth = x_auth
	}
	return
}

@[c:'renameQuotefixExprCb']
fn rename_quotefix_expr_cb(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	if int(p_expr.op) == 118 && (p_expr.flags & u32(128)) {
		rename_token_find(p_walker.pParse, p_walker.u.pRename, voidptr(p_expr))
	}
	return 0
}

@[c:'renameQuotefixFunc']
fn rename_quotefix_func(context &Sqlite3_context, not_used int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	db := sqlite3_context_db_handle(context)
	z_db := &i8(voidptr(sqlite3_value_text(argv[0])))
	z_input := &i8(voidptr(sqlite3_value_text(argv[1])))
	x_auth := db.xAuth
	db.xAuth = 0
	sqlite3_btree_enter_all(db)

	if !isnil(z_db) && !isnil(z_input) {
		rc := 0
		s_parse := Parse{}
		rc = rename_parse_sql(&s_parse, z_db, db, z_input, 0)
		if rc == 0 {
			s_ctx := RenameCtx{}
			s_walker := Walker{}
			C.memset(voidptr(&s_ctx), 0, sizeof(RenameCtx))
			C.memset(voidptr(&s_walker), 0, sizeof(Walker))
			s_walker.pParse = &s_parse
			s_walker.xExprCallback = rename_quotefix_expr_cb
			s_walker.xSelectCallback = rename_column_select_cb
			s_walker.u.pRename = &s_ctx
			if s_parse.pNewTable {
				if (int(s_parse.pNewTable.eTabType) == 2) {
					p_select := s_parse.pNewTable.u.view.pSelect
					p_select.selFlags &= ~u32(2097152)
					s_parse.rc = 0
					sqlite3_select_prep(&s_parse, p_select, unsafe { nil })
					rc = (if int(db.mallocFailed) { 7 } else { s_parse.rc })
					if rc == 0 {
						sqlite3_walk_select(&s_walker, p_select)
					}
				} else {
					i := 0
					sqlite3_walk_expr_list(&s_walker, s_parse.pNewTable.pCheck)
					for i = 0; i < int(s_parse.pNewTable.nCol); i++ {
						sqlite3_walk_expr(&s_walker, sqlite3_column_expr(s_parse.pNewTable, unsafe { s_parse.pNewTable.aCol + i }))
					}
				}
			} else if s_parse.pNewIndex {
				sqlite3_walk_expr_list(&s_walker, s_parse.pNewIndex.aColExpr)
				sqlite3_walk_expr(&s_walker, s_parse.pNewIndex.pPartIdxWhere)
			} else {
				rc = rename_resolve_trigger(&s_parse)
				if rc == 0 {
					rename_walk_trigger(&s_walker, s_parse.pNewTrigger)
				}
			}
			if rc == 0 {
				rc = rename_edit_sql(context, &s_ctx, z_input, unsafe { nil }, 0)
			}
			rename_token_free(db, s_ctx.pList)
		}
		if rc != 0 {
			if sqlite3_writable_schema(db) && rc == 1 {
				sqlite3_result_value(context, argv[1])
			} else {
				sqlite3_result_error_code(context, rc)
			}
		}
		rename_parse_cleanup(&s_parse)
	}
	db.xAuth = x_auth
	sqlite3_btree_leave_all(db)
}

@[c:'renameTableTest']
fn rename_table_test(context &Sqlite3_context, not_used int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	db := sqlite3_context_db_handle(context)
	z_db := &i8(voidptr(sqlite3_value_text(argv[0])))
	z_input := &i8(voidptr(sqlite3_value_text(argv[1])))
	b_temp := sqlite3_value_int(argv[4])
	is_legacy := int((db.flags & U64(67108864)))
	z_when := &i8(voidptr(sqlite3_value_text(argv[5])))
	b_no_dqs := sqlite3_value_int(argv[6])
	x_auth := db.xAuth
	db.xAuth = 0

	if !isnil(z_db) && !isnil(z_input) {
		rc := 0
		s_parse := Parse{}
		flags := db.flags
		if b_no_dqs {
			db.flags &= U64(~(1073741824 | 536870912))
		}
		rc = rename_parse_sql(&s_parse, z_db, db, z_input, b_temp)
		db.flags = flags
		if rc == 0 {
			if is_legacy == 0 && !isnil(s_parse.pNewTable) && (int(s_parse.pNewTable.eTabType) == 2) {
				snc := NameContext{}
				C.memset(voidptr(&snc), 0, sizeof(snc))
				snc.pParse = &s_parse
				sqlite3_select_prep(&s_parse, s_parse.pNewTable.u.view.pSelect, &snc)
				if s_parse.nErr {
					rc = s_parse.rc
				}
			} else if s_parse.pNewTrigger {
				if is_legacy == 0 {
					rc = rename_resolve_trigger(&s_parse)
				}
				if rc == 0 {
					i1 := sqlite3_schema_to_index(db, s_parse.pNewTrigger.pTabSchema)
					i2 := sqlite3_find_db_name(db, z_db)
					if i1 == i2 {
						sqlite3_result_int(context, 1)
					}
				}
			}
		}
		if rc != 0 && !isnil(z_when) && !sqlite3_writable_schema(db) {
			rename_column_parse_error(context, z_when, argv[2], argv[3], &s_parse)
		}
		rename_parse_cleanup(&s_parse)
	}
	db.xAuth = x_auth
}

@[c:'getConstraintToken']
fn get_constraint_token(z &U8, pi_token &int) int {
	i_off := 0
	t := 0
	for {
		i_off += sqlite3_get_token(unsafe { z + i_off }, &t)
		if !(t == 184 || t == 185) {
			break
		}
	}
	unsafe { *pi_token = t }
	if t == 22 {
		n_nest := 1
		for n_nest > 0 {
			i_off += sqlite3_get_token(unsafe { z + i_off }, &t)
			if t == 22 {
				n_nest++
			} else if t == 23 {
				t = 22
				n_nest--
			} else if t == 186 {
				break
			}
		}
	}
	unsafe { *pi_token = t }
	return i_off
}

@[c:'dropColumnFunc']
fn drop_column_func(context &Sqlite3_context, not_used int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	db := sqlite3_context_db_handle(context)
	i_schema := sqlite3_value_int(argv[0])
	z_sql := &i8(voidptr(sqlite3_value_text(argv[1])))
	i_col := sqlite3_value_int(argv[2])
	z_db := db.aDb[i_schema].zDbSName
	rc := 0
	s_parse := Parse{}
	p_col := &RenameToken(0)
	p_tab := &Table(0)
	z_end := &i8(0)
	z_new := unsafe { &i8(nil) }
	x_auth := db.xAuth
	db.xAuth = 0

	rc = rename_parse_sql(&s_parse, z_db, db, z_sql, i_schema == 1)
	if rc != 0 {
		unsafe { goto drop_column_done
		 }
	}
	p_tab = s_parse.pNewTable
	if usize(p_tab) == usize(0) || int(p_tab.nCol) == 1 || i_col >= int(p_tab.nCol) {
		rc = sqlite3_corrupt_error(2204)
		unsafe { goto drop_column_done
		 }
	}
	if i_col < int(p_tab.nCol) - 1 {
		p_end := &RenameToken(0)
		p_col = rename_token_find(&s_parse, unsafe { nil }, voidptr(p_tab.aCol[i_col].zCnName))
		p_end = rename_token_find(&s_parse, unsafe { nil }, voidptr(p_tab.aCol[i_col + 1].zCnName))
		z_end = &i8(p_end.t.z)
	} else {
		e_tok := 0
		p_col = rename_token_find(&s_parse, unsafe { nil }, voidptr(p_tab.aCol[i_col - 1].zCnName))
		for {
			c2v_pointer_prefix(voidptr(&p_col.t.z), p_col.t.z, isize(get_constraint_token(&U8(voidptr(p_col.t.z)), &e_tok)))
			if !(e_tok != 25) {
				break
			}
		}
		c2v_pointer_postfix(voidptr(&p_col.t.z), p_col.t.z, isize(-1))
		z_end = &i8(unsafe { z_sql + p_tab.u.tab.addColOffset })
	}
	z_new = sqlite3_mp_rintf(db, c'%.*s%s', i64((isize(p_col.t.z) - isize(z_sql)) / isize(sizeof(i8))), voidptr(z_sql), voidptr(z_end))
	sqlite3_result_text(context, z_new, -1, (C2vFn_666e2028766f696470747229(voidptr(-1))))
	sqlite3_free(voidptr(z_new))
	drop_column_done:
	rename_parse_cleanup(&s_parse)
	db.xAuth = x_auth
	if rc != 0 {
		sqlite3_result_error_code(context, rc)
	}
}

@[c:'sqlite3AlterDropColumn']
fn sqlite3_alter_drop_column(p_parse &Parse, p_src &SrcList, p_name &Token) {
	db := p_parse.db
	p_tab := &Table(0)
	i_db := 0
	z_db := &i8(0)
	z_col := unsafe { &i8(nil) }
	i_col := 0
	if db.mallocFailed {
		unsafe { goto exit_drop_column
		 }
	}
	p_tab = sqlite3_locate_table_item(p_parse, u32(0), unsafe { &p_src.a[0] + 0 })
	if isnil(p_tab) {
		unsafe { goto exit_drop_column
		 }
	}
	if 0 != is_alterable_table(p_parse, p_tab) {
		unsafe { goto exit_drop_column
		 }
	}
	if 0 != is_real_table(p_parse, p_tab, 1) {
		unsafe { goto exit_drop_column
		 }
	}
	z_col = sqlite3_name_from_token(db, p_name)
	if usize(z_col) == usize(0) {
		unsafe { goto exit_drop_column
		 }
	}
	i_col = sqlite3_column_index(p_tab, z_col)
	if i_col < 0 {
		sqlite3_error_msg(p_parse, c'no such column: "%T"', voidptr(p_name))
		unsafe { goto exit_drop_column
		 }
	}
	if int(p_tab.aCol[i_col].colFlags) & (1 | 8) {
		sqlite3_error_msg(p_parse, c'cannot drop %s column: "%s"', voidptr(if (int(p_tab.aCol[i_col].colFlags) & 1) {
			c'PRIMARY KEY'
		} else {
			c'UNIQUE'
		}), voidptr(z_col))
		unsafe { goto exit_drop_column
		 }
	}
	if int(p_tab.nCol) <= 1 {
		sqlite3_error_msg(p_parse, c'cannot drop column "%s": no other columns exist', voidptr(z_col))
		unsafe { goto exit_drop_column
		 }
	}
	i_db = sqlite3_schema_to_index(db, p_tab.pSchema)
	z_db = db.aDb[i_db].zDbSName
	if sqlite3_auth_check(p_parse, 26, z_db, p_tab.zName, z_col) {
		unsafe { goto exit_drop_column
		 }
	}
	rename_test_schema(p_parse, z_db, i_db == 1, c'', 0)
	rename_fix_quotes(p_parse, z_db, i_db == 1)
	sqlite3_nested_parse(p_parse, c'UPDATE "%w".sqlite_master SET sql = sqlite_drop_column(%d, sql, %d) WHERE (type==\'table\' AND tbl_name=%Q COLLATE nocase)', voidptr(z_db), i_db, i_col, voidptr(p_tab.zName))
	rename_reload_schema(p_parse, i_db, U16(2))
	rename_test_schema(p_parse, z_db, i_db == 1, c'after drop column', 1)
	if p_parse.nErr == 0 && (int(p_tab.aCol[i_col].colFlags) & 32) == 0 {
		i := 0
		addr := 0
		reg := 0
		reg_rec := 0
		p_pk := unsafe { &Index(nil) }
		n_field := 0
		i_cur := 0
		v := sqlite3_get_vdbe(p_parse)
		mut __c2v_postfix_value_8 := p_parse.nTab
		p_parse.nTab++
		i_cur = __c2v_postfix_value_8
		sqlite3_open_table(p_parse, i_cur, i_db, p_tab, 116)
		addr = sqlite3_vdbe_add_op1(v, 36, i_cur)
		0
		reg = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		if ((p_tab.tabFlags & u32(128)) == u32(0)) {
			sqlite3_vdbe_add_op2(v, 137, i_cur, reg)
			p_parse.nMem += int(p_tab.nCol)
		} else {
			p_pk = sqlite3_primary_key_index(p_tab)
			p_parse.nMem += int(p_pk.nColumn)
			for i = 0; i < int(p_pk.nKeyCol); i++ {
				sqlite3_vdbe_add_op3(v, 96, i_cur, i, reg + i + 1)
			}
			n_field = int(p_pk.nKeyCol)
		}
		reg_rec = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		for i = 0; i < int(p_tab.nCol); i++ {
			if i != i_col && (int(p_tab.aCol[i].colFlags) & 32) == 0 {
				reg_out := 0
				if p_pk {
					i_pos := sqlite3_table_column_to_index(p_pk, i)
					i_col_pos := sqlite3_table_column_to_index(p_pk, i_col)
					if i_pos < int(p_pk.nKeyCol) {
						continue
					}
					reg_out = reg + 1 + i_pos - int((i_pos > i_col_pos))
				} else {
					reg_out = reg + 1 + n_field
				}
				if i == int(p_tab.iPKey) {
					sqlite3_vdbe_add_op2(v, 77, 0, reg_out)
				} else {
					aff := p_tab.aCol[i].affinity
					if int(aff) == 69 {
						p_tab.aCol[i].affinity = i8(67)
					}
					sqlite3_expr_code_get_column_of_table(v, p_tab, i_cur, i, reg_out)
					p_tab.aCol[i].affinity = aff
				}
				n_field++
			}
		}
		if n_field == 0 {
			p_parse.nMem++
			sqlite3_vdbe_add_op2(v, 77, 0, reg + 1)
			n_field = 1
		}
		sqlite3_vdbe_add_op3(v, 99, reg + 1, n_field, reg_rec)
		if p_pk {
			sqlite3_vdbe_add_op4_int(v, 140, i_cur, reg_rec, reg + 1, int(p_pk.nKeyCol))
		} else {
			sqlite3_vdbe_add_op3(v, 130, i_cur, reg_rec, reg)
		}
		sqlite3_vdbe_change_p5(v, U16(2))
		sqlite3_vdbe_add_op2(v, 40, i_cur, addr + 1)
		0
		sqlite3_vdbe_jump_here(v, addr)
	}
	exit_drop_column:
	sqlite3_db_free(db, voidptr(z_col))
	sqlite3_src_list_delete(db, p_src)
}

@[c:'getWhitespace']
fn get_whitespace(z &U8) int {
	n_ret := 0
	for {
		t := 0
		n := int(sqlite3_get_token(unsafe { z + n_ret }, &t))
		if t != 184 && t != 185 {
			break
		}
		n_ret += n
	}
	return n_ret
}

@[c:'getConstraint']
fn get_constraint(z &U8) int {
	i_off := 0
	t := 0
	for {
		n := get_constraint_token(unsafe { z + i_off }, &t)
		if t == 120 || t == 123 || t == 19 || t == 124 || t == 125 || t == 121 || t == 114 || t == 126 || t == 133 || t == 23 || t == 25 || t == 186 || t == 24 || t == 96 {
			break
		}
		i_off += n
	}
	return i_off
}

@[c:'quotedCompare']
fn quoted_compare(ctx &Sqlite3_context, t int, z_quote &U8, n_quote int, z_cmp &U8, p_res &int) int {
	z_copy := unsafe { &i8(nil) }
	if t == 186 {
		unsafe { *p_res = 1 }
		return 0
	}
	z_copy = &i8(sqlite3_malloc_zero(U64(n_quote + 1)))
	if usize(z_copy) == usize(0) {
		sqlite3_result_error_nomem(ctx)
		return 7
	}
	C.memcpy(voidptr(z_copy), voidptr(z_quote), u64(n_quote))
	sqlite3_dequote(z_copy)
	unsafe { *p_res = sqlite3_stricmp(&i8(z_copy), &i8(voidptr(z_cmp))) }
	sqlite3_free(voidptr(z_copy))
	return 0
}

@[c:'skipCreateTable']
fn skip_create_table(ctx &Sqlite3_context, z_sql &U8, pi_off &int) int {
	i_off := 0
	if usize(z_sql) == usize(0) {
		return 1
	}
	for {
		t := 0
		i_off += sqlite3_get_token(unsafe { z_sql + i_off }, &t)
		if t == 22 {
			break
		}
		if t == 186 {
			sqlite3_result_error_code(ctx, sqlite3_corrupt_error(2499))
			return 1
		}
	}
	unsafe { *pi_off = i_off }
	return 0
}

@[c:'dropConstraintFunc']
fn drop_constraint_func(ctx &Sqlite3_context, not_used int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z_sql := sqlite3_value_text(argv[0])
	z_cons := unsafe { &U8(nil) }
	i_not_null := -1
	ii := 0
	i_off := 0
	i_start := 0
	i_end := 0
	z_new := unsafe { &i8(nil) }
	t := 0
	db := &Sqlite3(0)

	if usize(z_sql) == usize(0) {
		return
	}
	if skip_create_table(ctx, z_sql, &i_off) {
		return
	}
	if sqlite3_value_type(argv[1]) == 1 {
		i_not_null = sqlite3_value_int(argv[1])
	} else {
		z_cons = sqlite3_value_text(argv[1])
	}
	for ii = 0; i_end == 0; ii++ {
		for {
			i_start = i_off
			i_off += get_constraint_token(unsafe { z_sql + i_off }, &t)
			if t == 120 && (!isnil(z_cons) || i_not_null == ii) {
				n_tok := 0
				cmp := 1
				i_off += get_whitespace(unsafe { z_sql + i_off })
				n_tok = get_constraint_token(unsafe { z_sql + i_off }, &t)
				if z_cons {
					if quoted_compare(ctx, t, unsafe { z_sql + i_off }, n_tok, z_cons, &cmp) {
						return
					}
				}
				i_off += n_tok
				n_tok = get_constraint_token(unsafe { z_sql + i_off }, &t)
				if t == 120 || t == 121 || t == 114 || t == 25 || t == 23 || t == 96 || t == 24 {
					t = 125
				} else {
					i_off += n_tok
					i_off += get_constraint(unsafe { z_sql + i_off })
				}
				if cmp == 0 || (i_not_null >= 0 && t == 19) {
					if t != 19 && t != 125 {
						error_mp_rintf(ctx, c'constraint may not be dropped: %s', voidptr(z_cons))
						return
					}
					i_end = i_off
					break
				}
			} else if t == 19 && i_not_null == ii {
				i_end = i_off + get_constraint(unsafe { z_sql + i_off })
				break
			} else if t == 23 || t == 186 {
				i_end = -1
				break
			} else if t == 25 {
				break
			}
		}
	}
	if i_end <= 0 {
		if z_cons {
			error_mp_rintf(ctx, c'no such constraint: %s', voidptr(z_cons))
		} else {
			sqlite3_result_text(ctx, &i8(voidptr(z_sql)), -1, (C2vFn_666e2028766f696470747229(voidptr(-1))))
		}
	} else {
		z_space := c' '
		i_end += get_whitespace(unsafe { z_sql + i_end })
		sqlite3_get_token(unsafe { z_sql + i_end }, &t)
		if t == 23 || t == 25 {
			z_space = c''
			if int(z_sql[i_start - 1]) == `,` {
				i_start--
			}
		}
		db = sqlite3_context_db_handle(ctx)
		z_new = sqlite3_mp_rintf(db, c'%.*s%s%s', i_start, voidptr(z_sql), voidptr(z_space), voidptr(unsafe { z_sql + i_end }))
		sqlite3_result_text(ctx, z_new, -1, (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))))
	}
}

@[c:'addConstraintFunc']
fn add_constraint_func(ctx &Sqlite3_context, not_used int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z_sql := sqlite3_value_text(argv[0])
	z_cons := &i8(voidptr(sqlite3_value_text(argv[1])))
	i_col := sqlite3_value_int(argv[2])
	i_off := 0
	ii := 0
	z_new := unsafe { &i8(nil) }
	t := 0
	db := &Sqlite3(0)

	if skip_create_table(ctx, z_sql, &i_off) {
		return
	}
	for ii = 0; ii <= i_col || (i_col < 0 && t != 23); ii++ {
		i_off += get_constraint_token(unsafe { z_sql + i_off }, &t)
		for {
			n_tok := get_constraint_token(unsafe { z_sql + i_off }, &t)
			if t == 25 || t == 23 {
				break
			}
			if t == 186 {
				sqlite3_result_error_code(ctx, sqlite3_corrupt_error(2677))
				return
			}
			i_off += n_tok
		}
	}
	i_off += get_whitespace(unsafe { z_sql + i_off })
	db = sqlite3_context_db_handle(ctx)
	if i_col < 0 {
		z_new = sqlite3_mp_rintf(db, c'%.*s, %s%s', i_off, voidptr(z_sql), voidptr(z_cons), voidptr(unsafe { z_sql + i_off }))
	} else {
		z_new = sqlite3_mp_rintf(db, c'%.*s %s%s', i_off, voidptr(z_sql), voidptr(z_cons), voidptr(unsafe { z_sql + i_off }))
	}
	sqlite3_result_text(ctx, z_new, -1, (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))))
}

@[c:'alterFindCol']
fn alter_find_col(p_parse &Parse, p_tab &Table, p_col &Token, pi_col &int) int {
	db := p_parse.db
	z_name := sqlite3_name_from_token(db, p_col)
	rc := 7
	i_col := -1
	if z_name {
		i_col = sqlite3_column_index(p_tab, z_name)
		if i_col < 0 {
			sqlite3_error_msg(p_parse, c'no such column: %s', voidptr(z_name))
			rc = 1
		} else {
			rc = 0
		}
	}
	if rc == 0 {
		z_db := db.aDb[sqlite3_schema_to_index(db, p_tab.pSchema)].zDbSName
		z_col := p_tab.aCol[i_col].zCnName
		if sqlite3_auth_check(p_parse, 26, z_db, p_tab.zName, z_col) {
			p_tab = 0
		}
	}
	sqlite3_db_free(db, voidptr(z_name))
	unsafe { *pi_col = i_col }
	return rc
}

@[c:'alterFindTable']
fn alter_find_table(p_parse &Parse, p_src &SrcList, pi_db &int, pz_db &&u8, b_auth int) &Table {
	db := p_parse.db
	p_tab := unsafe { &Table(nil) }
	p_tab = sqlite3_locate_table_item(p_parse, u32(0), unsafe { &p_src.a[0] + 0 })
	if p_tab {
		i_db := sqlite3_schema_to_index(db, p_tab.pSchema)
		unsafe { *pz_db = db.aDb[i_db].zDbSName }
		unsafe { *pi_db = i_db }
		if 0 != is_real_table(p_parse, p_tab, 2) || 0 != is_alterable_table(p_parse, p_tab) {
			p_tab = 0
		}
	}
	if !isnil(p_tab) && b_auth {
		if sqlite3_auth_check(p_parse, 26, (unsafe { *pz_db }), p_tab.zName, unsafe { nil }) {
			p_tab = 0
		}
	}
	sqlite3_src_list_delete(db, p_src)
	return p_tab
}

@[c:'sqlite3AlterDropConstraint']
fn sqlite3_alter_drop_constraint(p_parse &Parse, p_src &SrcList, p_cons &Token, p_col &Token) {
	db := p_parse.db
	p_tab := unsafe { &Table(nil) }
	i_db := 0
	z_db := unsafe { &i8(nil) }
	z_arg := unsafe { &i8(nil) }
	p_tab = alter_find_table(p_parse, p_src, &i_db, &&u8(&&i8(c2v_address_of(&z_db))), usize(p_cons) != usize(0))
	if isnil(p_tab) {
		return
	}
	if p_cons {
		z := sqlite3_name_from_token(db, p_cons)
		z_arg = sqlite3_mp_rintf(db, c'%Q', voidptr(z))
		sqlite3_db_free(db, voidptr(z))
	} else {
		i_col := 0
		if alter_find_col(p_parse, p_tab, p_col, &i_col) {
			return
		}
		z_arg = sqlite3_mp_rintf(db, c'%d', i_col)
	}
	sqlite3_nested_parse(p_parse, c'UPDATE "%w".sqlite_master SET sql = sqlite_drop_constraint(sql, %s) WHERE type=\'table\' AND tbl_name=%Q COLLATE nocase', voidptr(z_db), voidptr(z_arg), voidptr(p_tab.zName))
	sqlite3_db_free(db, voidptr(z_arg))
	rename_reload_schema(p_parse, i_db, U16(4))
}

@[c:'failConstraintFunc']
fn fail_constraint_func(ctx &Sqlite3_context, not_used int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z_text := &i8(voidptr(sqlite3_value_text(argv[0])))
	err := sqlite3_value_int(argv[1])

	sqlite3_result_error(ctx, z_text, -1)
	sqlite3_result_error_code(ctx, err)
}

@[c:'alterRtrimConstraint']
fn alter_rtrim_constraint(db &Sqlite3, p_cons &i8, n_cons int) int {
	z_tmp := &U8(voidptr(sqlite3_mp_rintf(db, c'%.*s', n_cons, voidptr(p_cons))))
	i_off := 0
	i_end := 0
	if usize(z_tmp) == usize(0) {
		return 0
	}
	for {
		t := 0
		n_token := int(sqlite3_get_token(unsafe { z_tmp + i_off }, &t))
		if t == 186 {
			break
		}
		if t != 184 && (t != 185 || int(z_tmp[i_off]) != `-`) {
			i_end = i_off + n_token
		}
		i_off += n_token
	}
	sqlite3_db_free(db, voidptr(z_tmp))
	return i_end
}

@[c:'sqlite3AlterSetNotNull']
fn sqlite3_alter_set_not_null(p_parse &Parse, p_src &SrcList, p_col &Token, p_first &Token) {
	p_tab := unsafe { &Table(nil) }
	i_col := 0
	i_db := 0
	z_db := unsafe { &i8(nil) }
	p_cons := unsafe { &i8(nil) }
	n_cons := 0
	p_tab = alter_find_table(p_parse, p_src, &i_db, &&u8(&&i8(c2v_address_of(&z_db))), 0)
	if isnil(p_tab) {
		return
	}
	if alter_find_col(p_parse, p_tab, p_col, &i_col) {
		return
	}
	p_cons = p_first.z
	n_cons = alter_rtrim_constraint(p_parse.db, p_cons, int(i64((isize(p_parse.sLastToken.z) - isize(p_cons)) / isize(sizeof(i8)))))
	sqlite3_nested_parse(p_parse, c"SELECT sqlite_fail('constraint failed', %d) FROM %Q.%Q AS x WHERE x.%.*s IS NULL", 19, voidptr(z_db), voidptr(p_tab.zName), int(p_col.n), voidptr(p_col.z))
	sqlite3_nested_parse(p_parse, c'UPDATE "%w".sqlite_master SET sql = sqlite_add_constraint(sqlite_drop_constraint(sql, %d), %.*Q, %d) WHERE type=\'table\' AND tbl_name=%Q COLLATE nocase', voidptr(z_db), i_col, n_cons, voidptr(p_cons), i_col, voidptr(p_tab.zName))
	rename_reload_schema(p_parse, i_db, U16(4))
}

@[c:'findConstraintFunc']
fn find_constraint_func(ctx &Sqlite3_context, not_used int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z_sql := unsafe { &U8(nil) }
	z_cons := unsafe { &U8(nil) }
	i_off := 0
	t := 0

	z_sql = sqlite3_value_text(argv[0])
	z_cons = sqlite3_value_text(argv[1])
	if usize(z_sql) == usize(0) || usize(z_cons) == usize(0) {
		return
	}
	for t != 22 && t != 186 {
		i_off += sqlite3_get_token(unsafe { z_sql + i_off }, &t)
	}
	for {
		i_off += get_constraint_token(unsafe { z_sql + i_off }, &t)
		if t == 120 {
			n_tok := 0
			cmp := 0
			i_off += get_whitespace(unsafe { z_sql + i_off })
			n_tok = get_constraint_token(unsafe { z_sql + i_off }, &t)
			if quoted_compare(ctx, t, unsafe { z_sql + i_off }, n_tok, z_cons, &cmp) {
				return
			}
			if cmp == 0 {
				sqlite3_result_int(ctx, 1)
				return
			}
		} else if t == 186 {
			break
		}
	}
	sqlite3_result_int(ctx, 0)
}

@[c:'sqlite3AlterAddConstraint']
fn sqlite3_alter_add_constraint(p_parse &Parse, p_src &SrcList, p_first &Token, p_name &Token, z_expr &i8, n_expr int, p_expr &Expr) {
	p_tab := unsafe { &Table(nil) }
	i_db := 0
	z_db := unsafe { &i8(nil) }
	p_cons := unsafe { &i8(nil) }
	n_cons := 0
	rc := 0
	p_tab = alter_find_table(p_parse, p_src, &i_db, &&u8(&&i8(c2v_address_of(&z_db))), 1)
	if isnil(p_tab) {
		sqlite3_expr_delete(p_parse.db, p_expr)
		return
	}
	rc = sqlite3_resolve_self_reference(p_parse, p_tab, 4, p_expr, unsafe { nil })
	sqlite3_expr_delete(p_parse.db, p_expr)
	if rc {
		return
	}
	if p_name {
		z_name := sqlite3_name_from_token(p_parse.db, p_name)
		sqlite3_nested_parse(p_parse, c'SELECT sqlite_fail(\'constraint %q already exists\', %d) FROM "%w".sqlite_master WHERE type=\'table\' AND tbl_name=%Q COLLATE nocase AND sqlite_find_constraint(sql, %Q)', voidptr(z_name), 1, voidptr(z_db), voidptr(p_tab.zName), voidptr(z_name))
		sqlite3_db_free(p_parse.db, voidptr(z_name))
	}
	sqlite3_nested_parse(p_parse, c"SELECT sqlite_fail('constraint failed', %d) FROM %Q.%Q WHERE (%.*s) IS NOT TRUE", 19, voidptr(z_db), voidptr(p_tab.zName), n_expr, voidptr(z_expr))
	p_cons = p_first.z
	n_cons = alter_rtrim_constraint(p_parse.db, p_cons, int(i64((isize(p_parse.sLastToken.z) - isize(p_cons)) / isize(sizeof(i8)))))
	sqlite3_nested_parse(p_parse, c'UPDATE "%w".sqlite_master SET sql = sqlite_add_constraint(sql, %.*Q, -1) WHERE type=\'table\' AND tbl_name=%Q COLLATE nocase', voidptr(z_db), n_cons, voidptr(p_cons), voidptr(p_tab.zName))
	rename_reload_schema(p_parse, i_db, U16(4))
}

@[c:'sqlite3AlterFunctions']
fn sqlite3_alter_functions() {
	if !sqlite3_alter_functions_a_alter_table_funcs_inited {
		c2v_static_init := [FuncDef{
			nArg: I16(9)
			funcFlags: u32(8388608 | 262144 | 1 | 2048)
			pUserData: 0
			pNext: 0
			xSFunc: rename_column_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sqlite_rename_column'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(7)
			funcFlags: u32(8388608 | 262144 | 1 | 2048)
			pUserData: 0
			pNext: 0
			xSFunc: rename_table_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sqlite_rename_table'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(7)
			funcFlags: u32(8388608 | 262144 | 1 | 2048)
			pUserData: 0
			pNext: 0
			xSFunc: rename_table_test
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sqlite_rename_test'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(3)
			funcFlags: u32(8388608 | 262144 | 1 | 2048)
			pUserData: 0
			pNext: 0
			xSFunc: drop_column_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sqlite_drop_column'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 262144 | 1 | 2048)
			pUserData: 0
			pNext: 0
			xSFunc: rename_quotefix_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sqlite_rename_quotefix'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 262144 | 1 | 2048)
			pUserData: 0
			pNext: 0
			xSFunc: drop_constraint_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sqlite_drop_constraint'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 262144 | 1 | 2048)
			pUserData: 0
			pNext: 0
			xSFunc: fail_constraint_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sqlite_fail'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(3)
			funcFlags: u32(8388608 | 262144 | 1 | 2048)
			pUserData: 0
			pNext: 0
			xSFunc: add_constraint_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sqlite_add_constraint'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 262144 | 1 | 2048)
			pUserData: 0
			pNext: 0
			xSFunc: find_constraint_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sqlite_find_constraint'
			u: FuncDef_u{}
		}]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_alter_functions_a_alter_table_funcs[c2v_i_0] = c2v_element_0
		}
		sqlite3_alter_functions_a_alter_table_funcs_inited = true
	}

	sqlite3_insert_builtin_funcs(&sqlite3_alter_functions_a_alter_table_funcs[0], 9)
}
