@[translated]
module main

fn sqlite3_set_authorizer(db &Sqlite3, x_auth fn (voidptr, int, &i8, &i8, &i8, &i8) int, p_arg voidptr) int {
	c2v_gc_register_thread()
	sqlite3_mutex_enter(db.mutex)
	db.xAuth = C2vFn_666e2028766f69647074722c20696e742c202669382c202669382c202669382c202669382920696e74(voidptr(x_auth))
	db.pAuthArg = p_arg
	sqlite3_expire_prepared_statements(db, 1)
	sqlite3_mutex_leave(db.mutex)
	return 0
}

@[c:'sqliteAuthBadReturnCode']
fn sqlite_auth_bad_return_code(p_parse &Parse) {
	sqlite3_error_msg(p_parse, c'authorizer malfunction')
	p_parse.rc = 1
}

@[c:'sqlite3AuthReadCol']
fn sqlite3_auth_read_col(p_parse &Parse, z_tab &i8, z_col &i8, i_db int) int {
	db := p_parse.db
	z_db := db.aDb[i_db].zDbSName
	rc := 0
	if db.init.busy {
		return 0
	}
	rc = db.xAuth(voidptr(db.pAuthArg), 20, z_tab, z_col, z_db, p_parse.zAuthContext)
	if rc == 1 {
		z := sqlite3_mprintf(c'%s.%s', voidptr(z_tab), voidptr(z_col))
		if db.nDb > 2 || i_db != 0 {
			z = sqlite3_mprintf(c'%s.%z', voidptr(z_db), voidptr(z))
		}
		sqlite3_error_msg(p_parse, c'access to %z is prohibited', voidptr(z))
		p_parse.rc = 23
	} else if rc != 2 && rc != 0 {
		sqlite_auth_bad_return_code(p_parse)
	}
	return rc
}

@[c:'sqlite3AuthRead']
fn sqlite3_auth_read(p_parse &Parse, p_expr &Expr, p_schema &Schema, p_tab_list &SrcList) {
	p_tab := unsafe { &Table(nil) }
	z_col := &i8(0)
	i_src := 0
	i_db := 0
	i_col := 0
	i_db = sqlite3_schema_to_index(p_parse.db, p_schema)
	if i_db < 0 {
		return
	}
	if int(p_expr.op) == 78 {
		p_tab = p_parse.pTriggerTab
	} else {
		for i_src = 0; i_src < p_tab_list.nSrc; i_src++ {
			if p_expr.iTable == c2v_at(&p_tab_list.a[0], isize(i_src)).iCursor {
				p_tab = c2v_at(&p_tab_list.a[0], isize(i_src)).pSTab
				break
			}
		}
	}
	i_col = int(p_expr.iColumn)
	if usize(p_tab) == usize(0) {
		return
	}
	if i_col >= 0 {
		z_col = p_tab.aCol[i_col].zCnName
	} else if int(p_tab.iPKey) >= 0 {
		z_col = p_tab.aCol[p_tab.iPKey].zCnName
	} else {
		z_col = c'ROWID'
	}
	if 2 == sqlite3_auth_read_col(p_parse, p_tab.zName, z_col, i_db) {
		p_expr.op = U8(122)
	}
}

@[c:'sqlite3AuthCheck']
fn sqlite3_auth_check(p_parse &Parse, code int, z_arg1 &i8, z_arg2 &i8, z_arg3 &i8) int {
	db := p_parse.db
	rc := 0
	if isnil(db.xAuth) || int(db.init.busy) || (int(p_parse.eParseMode) != 0) {
		return 0
	}
	rc = db.xAuth(voidptr(db.pAuthArg), code, z_arg1, z_arg2, z_arg3, p_parse.zAuthContext)
	if rc == 1 {
		sqlite3_error_msg(p_parse, c'not authorized')
		p_parse.rc = 23
	} else if rc != 0 && rc != 2 {
		rc = 1
		sqlite_auth_bad_return_code(p_parse)
	}
	return rc
}

@[c:'sqlite3AuthContextPush']
fn sqlite3_auth_context_push(p_parse &Parse, p_context &AuthContext, z_context &i8) {
	p_context.pParse = p_parse
	p_context.zAuthContext = p_parse.zAuthContext
	p_parse.zAuthContext = z_context
}

@[c:'sqlite3AuthContextPop']
fn sqlite3_auth_context_pop(p_context &AuthContext) {
	if p_context.pParse {
		p_context.pParse.zAuthContext = p_context.zAuthContext
		p_context.pParse = 0
	}
}
