@[translated]
module main

struct VtabCtx {
	pVTable   &VTable
	pTab      &Table
	pPrior    &VtabCtx
	bDeclared int
}

@[c:'sqlite3VtabCreateModule']
fn sqlite3_vtab_create_module(db &Sqlite3, z_name &i8, p_module &Sqlite3_module, p_aux voidptr, x_destroy fn (voidptr)) &Module {
	p_mod := &Module(0)
	p_del := &Module(0)
	z_copy := &i8(0)
	if usize(p_module) == usize(0) {
		z_copy = &i8(z_name)
		p_mod = 0
	} else {
		n_name := sqlite3_strlen30(z_name)
		p_mod = &Module(sqlite3_malloc_vdup2(U64(sizeof(Module) + u64(n_name) + u64(1))))
		if usize(p_mod) == usize(0) {
			sqlite3_oom_fault(db)
			return unsafe { nil }
		}
		z_copy = &i8(voidptr((unsafe { p_mod + 1 })))
		C.memcpy(voidptr(z_copy), voidptr(z_name), u64(n_name + 1))
		p_mod.zName = z_copy
		p_mod.pModule = p_module
		p_mod.pAux = p_aux
		p_mod.xDestroy = x_destroy
		p_mod.pEpoTab = 0
		p_mod.nRefModule = 1
	}
	p_del = &Module(sqlite3_hash_insert(&db.aModule, z_copy, voidptr(p_mod)))
	if p_del {
		if usize(p_del) == usize(p_mod) {
			sqlite3_oom_fault(db)
			sqlite3_db_free(db, voidptr(p_del))
			p_mod = 0
		} else {
			sqlite3_vtab_eponymous_table_clear(db, p_del)
			sqlite3_vtab_module_unref(db, p_del)
		}
	}
	return p_mod
}

@[c:'createModule']
fn create_module(db &Sqlite3, z_name &i8, p_module &Sqlite3_module, p_aux voidptr, x_destroy fn (voidptr)) int {
	rc := 0
	sqlite3_mutex_enter(db.mutex)
	sqlite3_vtab_create_module(db, z_name, p_module, voidptr(p_aux), x_destroy)
	rc = sqlite3_api_exit(db, rc)
	if rc != 0 && !isnil(x_destroy) {
		x_destroy(voidptr(p_aux))
	}
	sqlite3_mutex_leave(db.mutex)
	return rc
}

fn sqlite3_create_module(db &Sqlite3, z_name &i8, p_module &Sqlite3_module, p_aux voidptr) int {
	c2v_gc_register_thread()
	return create_module(db, z_name, p_module, voidptr(p_aux), unsafe { nil })
}

fn sqlite3_create_module_v2(db &Sqlite3, z_name &i8, p_module &Sqlite3_module, p_aux voidptr, x_destroy fn (voidptr)) int {
	c2v_gc_register_thread()
	return create_module(db, z_name, p_module, voidptr(p_aux), x_destroy)
}

fn sqlite3_drop_modules(db &Sqlite3, az_names &&u8) int {
	c2v_gc_register_thread()
	p_this := &HashElem(0)
	p_next := &HashElem(0)

	sqlite3_mutex_enter(db.mutex)
	for p_this = db.aModule.first; p_this; p_this = p_next {
		p_mod := &Module(p_this.data)
		p_next = p_this.next
		if az_names {
			ii := 0
			for ii = 0; usize(az_names[ii]) != usize(0) && C.strcmp(az_names[ii], p_mod.zName) != 0; ii++ {
			}
			if usize(az_names[ii]) != usize(0) {
				continue
			}
		}
		create_module(db, p_mod.zName, unsafe { nil }, unsafe { nil }, unsafe { nil })
	}
	sqlite3_mutex_leave(db.mutex)
	return 0
}

@[c:'sqlite3VtabModuleUnref']
fn sqlite3_vtab_module_unref(db &Sqlite3, p_mod &Module) {
	p_mod.nRefModule--
	if p_mod.nRefModule == 0 {
		if p_mod.xDestroy {
			p_mod.xDestroy(voidptr(p_mod.pAux))
		}
		sqlite3_db_free(db, voidptr(p_mod))
	}
}

@[c:'sqlite3VtabLock']
fn sqlite3_vtab_lock(pvt_ab &VTable) {
	pvt_ab.nRef++
}

@[c:'sqlite3GetVTable']
fn sqlite3_get_vt_able(db &Sqlite3, p_tab &Table) &VTable {
	p_vtab := &VTable(0)
	for p_vtab = p_tab.u.vtab.p; !isnil(p_vtab) && usize(p_vtab.db) != usize(db); p_vtab = p_vtab.pNext {
	}
	return p_vtab
}

@[c:'sqlite3VtabUnlock']
fn sqlite3_vtab_unlock(pvt_ab &VTable) {
	db := pvt_ab.db
	pvt_ab.nRef--
	if pvt_ab.nRef == 0 {
		p := pvt_ab.pVtab
		if p {
			p.pModule.xDisconnect(p)
		}
		sqlite3_vtab_module_unref(pvt_ab.db, pvt_ab.pMod)
		sqlite3_db_free(db, voidptr(pvt_ab))
	}
}

@[c:'vtabDisconnectAll']
fn vtab_disconnect_all(db &Sqlite3, p &Table) &VTable {
	p_ret := unsafe { &VTable(nil) }
	pvt_able := &VTable(0)
	pvt_able = p.u.vtab.p
	p.u.vtab.p = 0
	for pvt_able {
		db2 := pvt_able.db
		p_next := pvt_able.pNext
		if usize(db2) == usize(db) {
			p_ret = pvt_able
			p.u.vtab.p = p_ret
			p_ret.pNext = 0
		} else {
			pvt_able.pNext = db2.pDisconnect
			db2.pDisconnect = pvt_able
		}
		pvt_able = p_next
	}
	return p_ret
}

@[c:'sqlite3VtabDisconnect']
fn sqlite3_vtab_disconnect(db &Sqlite3, p &Table) {
	pp_vt_ab := &&VTable(0)
	for pp_vt_ab = &p.u.vtab.p; (unsafe { *pp_vt_ab }); pp_vt_ab = &(unsafe { *pp_vt_ab }).pNext {
		if usize((unsafe { *pp_vt_ab }).db) == usize(db) {
			pvt_ab := (unsafe { *pp_vt_ab })
			unsafe { *pp_vt_ab = pvt_ab.pNext }
			sqlite3_vtab_unlock(pvt_ab)
			break
		}
	}
}

@[c:'sqlite3VtabUnlockList']
fn sqlite3_vtab_unlock_list(db &Sqlite3) {
	p := db.pDisconnect
	if p {
		db.pDisconnect = 0
		for {
			p_next := p.pNext
			sqlite3_vtab_unlock(p)
			p = p_next
			if !p {
				break
			}
		}
	}
}

@[c:'sqlite3VtabClear']
fn sqlite3_vtab_clear(db &Sqlite3, p &Table) {
	if usize(db.pnBytesFreed) == usize(0) {
		vtab_disconnect_all(unsafe { nil }, p)
	}
	if p.u.vtab.azArg {
		i := 0
		for i = 0; i < p.u.vtab.nArg; i++ {
			if i != 1 {
				sqlite3_db_free(db, voidptr(p.u.vtab.azArg[i]))
			}
		}
		sqlite3_db_free(db, voidptr(p.u.vtab.azArg))
	}
}

@[c:'addModuleArgument']
fn add_module_argument(p_parse &Parse, p_table &Table, z_arg &i8) {
	n_bytes := Sqlite3_int64(0)
	az_module_arg := &&u8(0)
	db := p_parse.db
	n_bytes = Sqlite3_int64(sizeof(voidptr) * u64((2 + p_table.u.vtab.nArg)))
	if p_table.u.vtab.nArg + 3 >= db.aLimit[2] {
		sqlite3_error_msg(p_parse, c'too many columns on %s', voidptr(p_table.zName))
	}
	az_module_arg = sqlite3_db_realloc(db, voidptr(p_table.u.vtab.azArg), U64(n_bytes))
	if usize(az_module_arg) == usize(0) {
		sqlite3_db_free(db, voidptr(z_arg))
	} else {
		i := p_table.u.vtab.nArg++
		az_module_arg[i] = z_arg
		az_module_arg[i + 1] = 0
		p_table.u.vtab.azArg = az_module_arg
	}
}

@[c:'sqlite3VtabBeginParse']
fn sqlite3_vtab_begin_parse(p_parse &Parse, p_name1 &Token, p_name2 &Token, p_module_name &Token, if_not_exists int) {
	p_table := &Table(0)
	db := &Sqlite3(0)
	sqlite3_start_table(p_parse, p_name1, p_name2, 0, 0, 1, if_not_exists)
	p_table = p_parse.pNewTable
	if usize(p_table) == usize(0) {
		return
	}
	p_table.eTabType = U8(1)
	db = p_parse.db
	add_module_argument(p_parse, p_table, sqlite3_name_from_token(db, p_module_name))
	add_module_argument(p_parse, p_table, unsafe { nil })
	add_module_argument(p_parse, p_table, sqlite3_db_str_dup(db, p_table.zName))
	p_parse.sNameToken.n = u32(int((i64((isize(unsafe { p_module_name.z + p_module_name.n }) - isize(p_parse.sNameToken.z)) / isize(sizeof(i8))))))
	if p_table.u.vtab.azArg {
		i_db := sqlite3_schema_to_index(db, p_table.pSchema)
		sqlite3_auth_check(p_parse, 29, p_table.zName, p_table.u.vtab.azArg[0], p_parse.db.aDb[i_db].zDbSName)
	}
}

@[c:'addArgumentToVtab']
fn add_argument_to_vtab(p_parse &Parse) {
	if !isnil(p_parse.sArg.z) && !isnil(p_parse.pNewTable) {
		z := &i8(p_parse.sArg.z)
		n := int(p_parse.sArg.n)
		db := p_parse.db
		add_module_argument(p_parse, p_parse.pNewTable, sqlite3_db_str_nd_up(db, z, U64(n)))
	}
}

@[c:'sqlite3VtabFinishParse']
fn sqlite3_vtab_finish_parse(p_parse &Parse, p_end &Token) {
	p_tab := p_parse.pNewTable
	db := p_parse.db
	if usize(p_tab) == usize(0) {
		return
	}
	add_argument_to_vtab(p_parse)
	p_parse.sArg.z = 0
	if p_tab.u.vtab.nArg < 1 {
		return
	}
	if !db.init.busy {
		z_stmt := &i8(0)
		z_where := &i8(0)
		i_db := 0
		i_reg := 0
		v := &Vdbe(0)
		sqlite3_may_abort(p_parse)
		if p_end {
			p_parse.sNameToken.n = u32(int((i64((isize(p_end.z) - isize(p_parse.sNameToken.z)) / isize(sizeof(i8)))))) + p_end.n
		}
		z_stmt = sqlite3_mp_rintf(db, c'CREATE VIRTUAL TABLE %T', voidptr(&p_parse.sNameToken))
		i_db = sqlite3_schema_to_index(db, p_tab.pSchema)
		sqlite3_nested_parse(p_parse, c"UPDATE %Q.sqlite_master SET type='table', name=%Q, tbl_name=%Q, rootpage=0, sql=%Q WHERE rowid=#%d", voidptr(db.aDb[i_db].zDbSName), voidptr(p_tab.zName), voidptr(p_tab.zName), voidptr(z_stmt), p_parse.u1.cr.regRowid)
		v = sqlite3_get_vdbe(p_parse)
		sqlite3_change_cookie(p_parse, i_db)
		sqlite3_vdbe_add_op0(v, 168)
		z_where = sqlite3_mp_rintf(db, c'name=%Q AND sql=%Q', voidptr(p_tab.zName), voidptr(z_stmt))
		sqlite3_vdbe_add_parse_schema_op(v, i_db, z_where, U16(0))
		sqlite3_db_free(db, voidptr(z_stmt))
		i_reg = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		sqlite3_vdbe_load_string(v, i_reg, p_tab.zName)
		sqlite3_vdbe_add_op2(v, 173, i_db, i_reg)
	} else {
		p_old := &Table(0)
		p_schema := p_tab.pSchema
		z_name := p_tab.zName
		sqlite3_mark_all_shadow_tables_of(db, p_tab)
		p_old = sqlite3_hash_insert(&p_schema.tblHash, z_name, voidptr(p_tab))
		if p_old {
			sqlite3_oom_fault(db)
			return
		}
		p_parse.pNewTable = 0
	}
}

@[c:'sqlite3VtabArgInit']
fn sqlite3_vtab_arg_init(p_parse &Parse) {
	add_argument_to_vtab(p_parse)
	p_parse.sArg.z = 0
	p_parse.sArg.n = u32(0)
}

@[c:'sqlite3VtabArgExtend']
fn sqlite3_vtab_arg_extend(p_parse &Parse, p &Token) {
	p_arg := &p_parse.sArg
	if usize(p_arg.z) == usize(0) {
		p_arg.z = p.z
		p_arg.n = p.n
	} else {
		p_arg.n = u32(int((i64((isize(unsafe { p.z + p.n }) - isize(p_arg.z)) / isize(sizeof(i8))))))
	}
}

@[c:'vtabCallConstructor']
fn vtab_call_constructor(db &Sqlite3, p_tab &Table, p_mod &Module, x_construct fn (&Sqlite3, voidptr, int, &&u8, &&Sqlite3_vtab, &&u8) int, pz_err &&u8) int {
	s_ctx := VtabCtx{}
	pvt_able := &VTable(0)
	rc := 0
	az_arg := &&u8(0)
	n_arg := p_tab.u.vtab.nArg
	z_err := unsafe { &i8(nil) }
	z_module_name := &i8(0)
	i_db := 0
	p_ctx := &VtabCtx(0)
	az_arg = &&u8(p_tab.u.vtab.azArg)
	for p_ctx = db.pVtabCtx; p_ctx; p_ctx = p_ctx.pPrior {
		if usize(p_ctx.pTab) == usize(p_tab) {
			unsafe { *pz_err = sqlite3_mp_rintf(db, c'vtable constructor called recursively: %s', voidptr(p_tab.zName)) }
			return 6
		}
	}
	z_module_name = sqlite3_db_str_dup(db, p_tab.zName)
	if isnil(z_module_name) {
		return 7
	}
	pvt_able = sqlite3_malloc_zero(U64(sizeof(VTable)))
	if isnil(pvt_able) {
		sqlite3_oom_fault(db)
		sqlite3_db_free(db, voidptr(z_module_name))
		return 7
	}
	pvt_able.db = db
	pvt_able.pMod = p_mod
	pvt_able.eVtabRisk = U8(1)
	i_db = sqlite3_schema_to_index(db, p_tab.pSchema)
	p_tab.u.vtab.azArg[1] = db.aDb[i_db].zDbSName
	s_ctx.pTab = p_tab
	s_ctx.pVTable = pvt_able
	s_ctx.pPrior = db.pVtabCtx
	s_ctx.bDeclared = 0
	db.pVtabCtx = &s_ctx
	p_tab.nTabRef++
	rc = x_construct(db, voidptr(p_mod.pAux), n_arg, az_arg, &&Sqlite3_vtab(&pvt_able.pVtab), &&u8(&&i8(c2v_address_of(&z_err))))
	sqlite3_delete_table(db, p_tab)
	db.pVtabCtx = s_ctx.pPrior
	if rc == 7 {
		sqlite3_oom_fault(db)
	}
	if 0 != rc {
		if usize(z_err) == usize(0) {
			unsafe { *pz_err = sqlite3_mp_rintf(db, c'vtable constructor failed: %s', voidptr(z_module_name)) }
		} else {
			unsafe { *pz_err = sqlite3_mp_rintf(db, c'%s', voidptr(z_err)) }
			sqlite3_free(voidptr(z_err))
		}
		sqlite3_db_free(db, voidptr(pvt_able))
	} else if pvt_able.pVtab {
		C.memset(voidptr(pvt_able.pVtab), 0, sizeof(Sqlite3_vtab))
		pvt_able.pVtab.pModule = p_mod.pModule
		p_mod.nRefModule++
		pvt_able.nRef = 1
		if s_ctx.bDeclared == 0 {
			z_format := c'vtable constructor did not declare schema: %s'
			unsafe { *pz_err = sqlite3_mp_rintf(db, z_format, voidptr(z_module_name)) }
			sqlite3_vtab_unlock(pvt_able)
			rc = 1
		} else {
			i_col := 0
			ooo_hidden := U16(0)
			pvt_able.pNext = p_tab.u.vtab.p
			p_tab.u.vtab.p = pvt_able
			for i_col = 0; i_col < int(p_tab.nCol); i_col++ {
				z_type := sqlite3_column_type_vdup1(unsafe { p_tab.aCol + i_col }, c'')
				n_type := 0
				i := 0
				n_type = sqlite3_strlen30(z_type)
				for i = 0; i < n_type; i++ {
					if 0 == sqlite3_strnicmp(c'hidden', unsafe { z_type + i }, 6) && (i == 0 || int(z_type[i - 1]) == i8(` `)) && (int(z_type[i + 6]) == i8(`\0`) || int(z_type[i + 6]) == i8(` `)) {
						break
					}
				}
				if i < n_type {
					j := 0
					n_del := 6 + (if int(z_type[i + 6]) { 1 } else { 0 })
					for j = i; (j + n_del) <= n_type; j++ {
						z_type[j] = z_type[j + n_del]
					}
					if int(z_type[i]) == i8(`\0`) && i > 0 {
						z_type[i - 1] = i8(`\0`)
					}
					p_tab.aCol[i_col].colFlags |= 2
					p_tab.tabFlags |= u32(2)
					ooo_hidden = U16(1024)
				} else {
					p_tab.tabFlags |= u32(ooo_hidden)
				}
			}
		}
	}
	sqlite3_db_free(db, voidptr(z_module_name))
	return rc
}

@[c:'sqlite3VtabCallConnect']
fn sqlite3_vtab_call_connect(p_parse &Parse, p_tab &Table) int {
	db := p_parse.db
	z_mod := &i8(0)
	p_mod := &Module(0)
	rc := 0
	if sqlite3_get_vt_able(db, p_tab) {
		return 0
	}
	z_mod = p_tab.u.vtab.azArg[0]
	p_mod = &Module(sqlite3_hash_find(&db.aModule, z_mod))
	if isnil(p_mod) {
		z_module := p_tab.u.vtab.azArg[0]
		sqlite3_error_msg(p_parse, c'no such module: %s', voidptr(z_module))
		rc = 1
	} else {
		z_err := unsafe { &i8(nil) }
		rc = vtab_call_constructor(db, p_tab, p_mod, p_mod.pModule.xConnect, &&u8(&&i8(c2v_address_of(&z_err))))
		if rc != 0 {
			sqlite3_error_msg(p_parse, c'%s', voidptr(z_err))
			p_parse.rc = rc
		}
		sqlite3_db_free(db, voidptr(z_err))
	}
	return rc
}

@[c:'growVTrans']
fn grow_vt_rans(db &Sqlite3) int {
	array_incr := 5
	if (db.nVTrans % array_incr) == 0 {
		avt_rans := &&VTable(0)
		n_bytes := Sqlite3_int64(sizeof(voidptr) * u64((Sqlite3_int64(db.nVTrans) + Sqlite3_int64(array_incr))))
		avt_rans = sqlite3_db_realloc(db, voidptr(db.aVTrans), U64(n_bytes))
		if isnil(avt_rans) {
			return 7
		}
		C.memset(voidptr(unsafe { avt_rans + db.nVTrans }), 0, sizeof(voidptr) * u64(array_incr))
		db.aVTrans = avt_rans
	}
	return 0
}

@[c:'addToVTrans']
fn add_to_vt_rans(db &Sqlite3, pvt_ab &VTable) {
	db.aVTrans[db.nVTrans++] = pvt_ab
	sqlite3_vtab_lock(pvt_ab)
}

@[c:'sqlite3VtabCallCreate']
fn sqlite3_vtab_call_create(db &Sqlite3, i_db int, z_tab &i8, pz_err &&u8) int {
	rc := 0
	p_tab := &Table(0)
	p_mod := &Module(0)
	z_mod := &i8(0)
	p_tab = sqlite3_find_table(db, z_tab, db.aDb[i_db].zDbSName)
	z_mod = p_tab.u.vtab.azArg[0]
	p_mod = &Module(sqlite3_hash_find(&db.aModule, z_mod))
	if usize(p_mod) == usize(0) || isnil(p_mod.pModule.xCreate) || isnil(p_mod.pModule.xDestroy) {
		unsafe { *pz_err = sqlite3_mp_rintf(db, c'no such module: %s', voidptr(z_mod)) }
		rc = 1
	} else {
		rc = vtab_call_constructor(db, p_tab, p_mod, p_mod.pModule.xCreate, pz_err)
	}
	if rc == 0 && !isnil(sqlite3_get_vt_able(db, p_tab)) {
		rc = grow_vt_rans(db)
		if rc == 0 {
			add_to_vt_rans(db, sqlite3_get_vt_able(db, p_tab))
		}
	}
	return rc
}

fn sqlite3_declare_vtab(db &Sqlite3, z_create_table &i8) int {
	c2v_gc_register_thread()
	p_ctx := &VtabCtx(0)
	rc := 0
	p_tab := &Table(0)
	s_parse := Parse{}
	init_busy := 0
	i := 0
	z := &u8(0)
	if !sqlite3_declare_vtab_a_keyword_inited {
		c2v_static_init := [U8(17), U8(16), U8(0)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_declare_vtab_a_keyword[c2v_i_0] = c2v_element_0
		}
		sqlite3_declare_vtab_a_keyword_inited = true
	}

	z = &u8(voidptr(z_create_table))
	for i = 0; sqlite3_declare_vtab_a_keyword[i]; i++ {
		token_type := 0
		for {
			c2v_pointer_prefix(voidptr(&z), z, isize(sqlite3_get_token(z, &token_type)))
			if !(token_type == 184 || token_type == 185) {
				break
			}
		}
		if token_type != int(sqlite3_declare_vtab_a_keyword[i]) {
			sqlite3_error_with_msg(db, 1, c'syntax error')
			return 1
		}
	}
	sqlite3_mutex_enter(db.mutex)
	p_ctx = db.pVtabCtx
	if isnil(p_ctx) || p_ctx.bDeclared {
		sqlite3_error(db, sqlite3_misuse_error(848))
		sqlite3_mutex_leave(db.mutex)
		return sqlite3_misuse_error(850)
	}
	p_tab = p_ctx.pTab
	sqlite3_parse_object_init(&s_parse, db)
	s_parse.eParseMode = U8(1)
	s_parse.disableTriggers = Bft(1)
	init_busy = int(db.init.busy)
	db.init.busy = U8(0)
	s_parse.nQueryLoop = LogEst(1)
	if 0 == sqlite3_run_parser(&s_parse, z_create_table) {
		if isnil(p_tab.aCol) {
			p_new := s_parse.pNewTable
			p_idx := &Index(0)
			p_tab.aCol = p_new.aCol
			sqlite3_expr_list_delete(db, p_new.u.tab.pDfltList)
			p_tab.nCol = p_new.nCol
			p_tab.nNVCol = p_tab.nCol
			p_tab.tabFlags |= p_new.tabFlags & u32((128 | 512))
			p_new.nCol = I16(0)
			p_new.aCol = 0
			if !((p_new.tabFlags & u32(128)) == u32(0)) && !isnil(p_ctx.pVTable.pMod.pModule.xUpdate) && int(sqlite3_primary_key_index(p_new).nKeyCol) != 1 {
				rc = 1
			}
			p_idx = p_new.pIndex
			if p_idx {
				p_tab.pIndex = p_idx
				p_new.pIndex = 0
				p_idx.pTable = p_tab
			}
		}
		p_ctx.bDeclared = 1
	} else {
		sqlite3_error_with_msg(db, 1, unsafe { if s_parse.zErrMsg { c'%s' } else { &i8(nil) } }, voidptr(s_parse.zErrMsg))
		sqlite3_db_free(db, voidptr(s_parse.zErrMsg))
		rc = 1
	}
	s_parse.eParseMode = U8(0)
	if s_parse.pVdbe {
		sqlite3_vdbe_finalize(s_parse.pVdbe)
	}
	sqlite3_delete_table(db, s_parse.pNewTable)
	sqlite3_parse_object_reset(&s_parse)
	db.init.busy = U8(init_busy)
	rc = sqlite3_api_exit(db, rc)
	sqlite3_mutex_leave(db.mutex)
	return rc
}

@[c:'sqlite3VtabCallDestroy']
fn sqlite3_vtab_call_destroy(db &Sqlite3, i_db int, z_tab &i8) int {
	rc := 0
	p_tab := &Table(0)
	p_tab = sqlite3_find_table(db, z_tab, db.aDb[i_db].zDbSName)
	if (usize(p_tab) != usize(0)) && (int(p_tab.eTabType) == 1) && (usize(p_tab.u.vtab.p) != usize(0)) {
		p := &VTable(0)
		x_destroy := C2vFn_666e20282653716c697465335f767461622920696e74(voidptr(0))
		for p = p_tab.u.vtab.p; p; p = p.pNext {
			if p.pVtab.nRef > 0 {
				return 6
			}
		}
		p = vtab_disconnect_all(db, p_tab)
		x_destroy = p.pMod.pModule.xDestroy
		if isnil(x_destroy) {
			x_destroy = p.pMod.pModule.xDisconnect
		}
		p_tab.nTabRef++
		rc = x_destroy(p.pVtab)
		if rc == 0 {
			p.pVtab = 0
			p_tab.u.vtab.p = 0
			sqlite3_vtab_unlock(p)
		}
		sqlite3_delete_table(db, p_tab)
	}
	return rc
}

@[c:'callFinaliser']
fn call_finaliser(db &Sqlite3, offset int) {
	i := 0
	if db.aVTrans {
		avt_rans := db.aVTrans
		db.aVTrans = 0
		for i = 0; i < db.nVTrans; i++ {
			pvt_ab := avt_rans[i]
			p := pvt_ab.pVtab
			if p {
				x := C2vFn_666e20282653716c697465335f767461622920696e74(voidptr(0))
				x = unsafe { *&voidptr(voidptr((&i8(voidptr(p.pModule)) + offset))) }
				if x {
					x(p)
				}
			}
			pvt_ab.iSavepoint = 0
			sqlite3_vtab_unlock(pvt_ab)
		}
		sqlite3_db_free(db, voidptr(avt_rans))
		db.nVTrans = 0
	}
}

@[c:'sqlite3VtabSync']
fn sqlite3_vtab_sync(db &Sqlite3, p &Vdbe) int {
	i := 0
	rc := 0
	avt_rans := db.aVTrans
	db.aVTrans = 0
	for i = 0; rc == 0 && i < db.nVTrans; i++ {
		x := C2vFn_666e20282653716c697465335f767461622920696e74(voidptr(0))
		p_vtab := avt_rans[i].pVtab
		if !isnil(p_vtab) && !isnil(C2vFn_666e20282653716c697465335f767461622920696e74(c2v_assign_voidptr(unsafe { &voidptr(&x) }, voidptr(p_vtab.pModule.xSync)))) {
			rc = x(p_vtab)
			sqlite3_vtab_import_errmsg(p, p_vtab)
		}
	}
	db.aVTrans = avt_rans
	return rc
}

@[c:'sqlite3VtabRollback']
fn sqlite3_vtab_rollback(db &Sqlite3) int {
	call_finaliser(db, int((u64(usize(__offsetof(Sqlite3_module, xRollback))))))
	return 0
}

@[c:'sqlite3VtabCommit']
fn sqlite3_vtab_commit(db &Sqlite3) int {
	call_finaliser(db, int((u64(usize(__offsetof(Sqlite3_module, xCommit))))))
	return 0
}

@[c:'sqlite3VtabBegin']
fn sqlite3_vtab_begin(db &Sqlite3, pvt_ab &VTable) int {
	rc := 0
	p_module := &Sqlite3_module(0)
	if (db.nVTrans > 0 && usize(db.aVTrans) == usize(0)) {
		return 6
	}
	if isnil(pvt_ab) {
		return 0
	}
	p_module = pvt_ab.pVtab.pModule
	if p_module.xBegin {
		i := 0
		for i = 0; i < db.nVTrans; i++ {
			if usize(db.aVTrans[i]) == usize(pvt_ab) {
				return 0
			}
		}
		rc = grow_vt_rans(db)
		if rc == 0 {
			rc = p_module.xBegin(pvt_ab.pVtab)
			if rc == 0 {
				i_svpt := db.nStatement + db.nSavepoint
				add_to_vt_rans(db, pvt_ab)
				if i_svpt && !isnil(p_module.xSavepoint) {
					pvt_ab.iSavepoint = i_svpt
					rc = p_module.xSavepoint(pvt_ab.pVtab, i_svpt - 1)
				}
			}
		}
	}
	return rc
}

@[c:'sqlite3VtabSavepoint']
fn sqlite3_vtab_savepoint(db &Sqlite3, op int, i_savepoint int) int {
	rc := 0
	if db.aVTrans {
		i := 0
		for i = 0; rc == 0 && i < db.nVTrans; i++ {
			pvt_ab := db.aVTrans[i]
			p_mod := pvt_ab.pMod.pModule
			if !isnil(pvt_ab.pVtab) && p_mod.iVersion >= 2 {
				x_method := C2vFn_666e20282653716c697465335f767461622c20696e742920696e74(voidptr(0))
				sqlite3_vtab_lock(pvt_ab)
				match op {
					0 {
						x_method = p_mod.xSavepoint
						pvt_ab.iSavepoint = i_savepoint + 1
					}
					2 {
						x_method = p_mod.xRollbackTo
					}
					else {
						x_method = p_mod.xRelease
					}
				}

				if !isnil(x_method) && pvt_ab.iSavepoint > i_savepoint {
					saved_flags := (db.flags & U64(268435456))
					db.flags &= ~U64(268435456)
					rc = x_method(pvt_ab.pVtab, i_savepoint)
					db.flags |= saved_flags
				}
				sqlite3_vtab_unlock(pvt_ab)
			}
		}
	}
	return rc
}

@[c:'sqlite3VtabOverloadFunction']
fn sqlite3_vtab_overload_function(db &Sqlite3, p_def &FuncDef, n_arg int, p_expr &Expr) &FuncDef {
	p_tab := &Table(0)
	p_vtab := &Sqlite3_vtab(0)
	p_mod := &Sqlite3_module(0)
	xsf_unc := C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
	p_arg := voidptr(0)
	p_new := &FuncDef(0)
	rc := 0
	if (usize(p_expr) == usize(0)) {
		return p_def
	}
	if int(p_expr.op) != 168 {
		return p_def
	}
	p_tab = p_expr.y.pTab
	if (usize(p_tab) == usize(0)) {
		return p_def
	}
	if !(int(p_tab.eTabType) == 1) {
		return p_def
	}
	p_vtab = sqlite3_get_vt_able(db, p_tab).pVtab
	p_mod = &Sqlite3_module(p_vtab.pModule)
	if isnil(p_mod.xFindFunction) {
		return p_def
	}
	rc = p_mod.xFindFunction(p_vtab, n_arg, p_def.zName, &xsf_unc, &p_arg)
	if rc == 0 {
		return p_def
	}
	p_new = sqlite3_db_malloc_zero(db, U64(sizeof(FuncDef) + u64(sqlite3_strlen30(p_def.zName)) + u64(1)))
	if usize(p_new) == usize(0) {
		return p_def
	}
	unsafe { *p_new = *p_def }
	p_new.zName = &i8(voidptr(unsafe { p_new + 1 }))
	C.memcpy(voidptr(&i8(voidptr(unsafe { p_new + 1 }))), voidptr(p_def.zName), u64(sqlite3_strlen30(p_def.zName) + 1))
	p_new.xSFunc = xsf_unc
	p_new.pUserData = p_arg
	p_new.funcFlags |= u32(16)
	return p_new
}

@[c:'sqlite3VtabMakeWritable']
fn sqlite3_vtab_make_writable(p_parse &Parse, p_tab &Table) {
	p_toplevel := (if p_parse.pToplevel { p_parse.pToplevel } else { p_parse })
	i := 0
	n := 0

	ap_vtab_lock := &&Table(0)
	for i = 0; i < p_toplevel.nVtabLock; i++ {
		if usize(p_tab) == usize(p_toplevel.apVtabLock[i]) {
			return
		}
	}
	n = int(u64((p_toplevel.nVtabLock + 1)) * sizeof(&Table))
	ap_vtab_lock = sqlite3_realloc_vdup3(voidptr(p_toplevel.apVtabLock), U64(n))
	if ap_vtab_lock {
		p_toplevel.apVtabLock = ap_vtab_lock
		p_toplevel.apVtabLock[p_toplevel.nVtabLock++] = p_tab
	} else {
		sqlite3_oom_fault(p_toplevel.db)
	}
}

@[c:'sqlite3VtabEponymousTableInit']
fn sqlite3_vtab_eponymous_table_init(p_parse &Parse, p_mod &Module) int {
	p_module := p_mod.pModule
	p_tab := &Table(0)
	z_err := unsafe { &i8(nil) }
	rc := 0
	db := p_parse.db
	if p_mod.pEpoTab {
		return 1
	}
	if !isnil(p_module.xCreate) && p_module.xCreate != p_module.xConnect {
		return 0
	}
	p_tab = sqlite3_db_malloc_zero(db, U64(sizeof(Table)))
	if usize(p_tab) == usize(0) {
		return 0
	}
	p_tab.zName = sqlite3_db_str_dup(db, p_mod.zName)
	if usize(p_tab.zName) == usize(0) {
		sqlite3_db_free(db, voidptr(p_tab))
		return 0
	}
	p_mod.pEpoTab = p_tab
	p_tab.nTabRef = u32(1)
	p_tab.eTabType = U8(1)
	p_tab.pSchema = db.aDb[0].pSchema
	p_tab.iPKey = I16(-1)
	p_tab.tabFlags |= u32(32768)
	add_module_argument(p_parse, p_tab, sqlite3_db_str_dup(db, p_tab.zName))
	add_module_argument(p_parse, p_tab, unsafe { nil })
	add_module_argument(p_parse, p_tab, sqlite3_db_str_dup(db, p_tab.zName))
	db.nSchemaLock++
	rc = vtab_call_constructor(db, p_tab, p_mod, p_module.xConnect, &&u8(&&i8(c2v_address_of(&z_err))))
	db.nSchemaLock--
	if rc {
		sqlite3_error_msg(p_parse, c'%s', voidptr(z_err))
		p_parse.rc = rc
		sqlite3_db_free(db, voidptr(z_err))
		sqlite3_vtab_eponymous_table_clear(db, p_mod)
	}
	return 1
}

@[c:'sqlite3VtabEponymousTableClear']
fn sqlite3_vtab_eponymous_table_clear(db &Sqlite3, p_mod &Module) {
	p_tab := p_mod.pEpoTab
	if usize(p_tab) != usize(0) {
		p_tab.tabFlags |= u32(16384)
		sqlite3_delete_table(db, p_tab)
		p_mod.pEpoTab = 0
	}
}

fn sqlite3_vtab_on_conflict(db &Sqlite3) int {
	c2v_gc_register_thread()
	if !sqlite3_vtab_on_conflict_a_map_inited {
		c2v_static_init := [u8(1), u8(4), u8(3), u8(2), u8(5)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_vtab_on_conflict_a_map[c2v_i_0] = c2v_element_0
		}
		sqlite3_vtab_on_conflict_a_map_inited = true
	}

	return int(sqlite3_vtab_on_conflict_a_map[int(db.vtabOnConflict) - 1])
}

@[c2v_variadic]
fn sqlite3_vtab_config(db &Sqlite3, op int, ...) int {
	c2v_gc_register_thread()
	ap := C.va_list{}
	rc := 0
	p := &VtabCtx(0)
	sqlite3_mutex_enter(db.mutex)
	p = db.pVtabCtx
	if isnil(p) {
		rc = sqlite3_misuse_error(1348)
	} else {
		C.va_start(ap, op)
		match op {
			1 {
				p.pVTable.bConstraint = U8(C.va_arg(int, ap))
			}
			2 {
				p.pVTable.eVtabRisk = U8(0)
			}
			3 {
				p.pVTable.eVtabRisk = U8(2)
			}
			4 {
				p.pVTable.bAllSchemas = U8(1)
			}
			else {
				rc = sqlite3_misuse_error(1370)
			}
		}

		C.va_end(ap)
	}
	if rc != 0 {
		sqlite3_error(db, rc)
	}
	sqlite3_mutex_leave(db.mutex)
	return rc
}
