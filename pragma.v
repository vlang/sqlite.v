@[translated]
module main

@[c:'getSafetyLevel']
fn get_safety_level(z &i8, omit_full int, dflt U8) U8 {
	if !get_safety_level_z_text_inited {
		c2v_static_init := [i8(111), 110, 111, 102, 102, 97, 108, 115, 101, 121, 101, 115, 116,
			114, 117, 101, 120, 116, 114, 97, 102, 117, 108, 108, 0]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			get_safety_level_z_text[c2v_i_0] = c2v_element_0
		}
		get_safety_level_z_text_inited = true
	}

	if !get_safety_level_i_offset_inited {
		c2v_static_init := [U8(0), U8(1), U8(2), U8(4), U8(9), U8(12), U8(15), U8(20)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			get_safety_level_i_offset[c2v_i_0] = c2v_element_0
		}
		get_safety_level_i_offset_inited = true
	}

	if !get_safety_level_i_length_inited {
		c2v_static_init := [U8(2), U8(2), U8(3), U8(5), U8(3), U8(4), U8(5), U8(4)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			get_safety_level_i_length[c2v_i_0] = c2v_element_0
		}
		get_safety_level_i_length_inited = true
	}

	if !get_safety_level_i_value_inited {
		c2v_static_init := [U8(1), U8(0), U8(0), U8(0), U8(1), U8(1), U8(3), U8(2)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			get_safety_level_i_value[c2v_i_0] = c2v_element_0
		}
		get_safety_level_i_value_inited = true
	}

	i := 0
	n := 0

	if (int(sqlite3CtypeMap[u8((unsafe { *z }))]) & 4) {
		return U8(sqlite3_atoi(z))
	}
	n = sqlite3_strlen30(z)
	for i = 0; i < 8; i++ {
		mut __c2v_condition_74 := false
		mut __c2v_condition_75 := false
		__c2v_condition_75 = int(get_safety_level_i_length[i]) == n
		if __c2v_condition_75 {
			__c2v_condition_75 = sqlite3_strnicmp(unsafe { &get_safety_level_z_text[0] + get_safety_level_i_offset[i] }, z, n) == 0
		}
		if __c2v_condition_75 {
			__c2v_condition_75 = (!omit_full || int(get_safety_level_i_value[i]) <= 1)
		}
		__c2v_condition_74 = __c2v_condition_75
		if __c2v_condition_74 {
			return get_safety_level_i_value[i]
		}
	}
	return dflt
}

@[c:'sqlite3GetBoolean']
fn sqlite3_get_boolean(z &i8, dflt U8) U8 {
	return U8(int(get_safety_level(z, 1, dflt)) != 0)
}

@[c:'getLockingMode']
fn get_locking_mode(z &i8) int {
	if z {
		if 0 == sqlite3_str_ic_mp(z, c'exclusive') {
			return 1
		}
		if 0 == sqlite3_str_ic_mp(z, c'normal') {
			return 0
		}
	}
	return -1
}

@[c:'getAutoVacuum']
fn get_auto_vacuum(z &i8) int {
	i := 0
	if 0 == sqlite3_str_ic_mp(z, c'none') {
		return 0
	}
	if 0 == sqlite3_str_ic_mp(z, c'full') {
		return 1
	}
	if 0 == sqlite3_str_ic_mp(z, c'incremental') {
		return 2
	}
	i = sqlite3_atoi(z)
	return int(U8((if (i >= 0 && i <= 2) { i } else { 0 })))
}

@[c:'getTempStore']
fn get_temp_store(z &i8) int {
	if int(z[0]) >= i8(`0`) && int(z[0]) <= i8(`2`) {
		return int(z[0]) - int(`0`)
	} else if sqlite3_str_ic_mp(z, c'file') == 0 {
		return 1
	} else if sqlite3_str_ic_mp(z, c'memory') == 0 {
		return 2
	} else {
		return 0
	}
}

@[c:'invalidateTempStorage']
fn invalidate_temp_storage(p_parse &Parse) int {
	db := p_parse.db
	if usize(db.aDb[1].pBt) != usize(0) {
		if !db.autoCommit || sqlite3_btree_txn_state(db.aDb[1].pBt) != 0 {
			sqlite3_error_msg(p_parse, c'temporary storage cannot be changed from within a transaction')
			return 1
		}
		sqlite3_btree_close(db.aDb[1].pBt)
		db.aDb[1].pBt = 0
		sqlite3_reset_all_schemas_of_connection(db)
	}
	return 0
}

@[c:'changeTempStorage']
fn change_temp_storage(p_parse &Parse, z_storage_type &i8) int {
	ts := get_temp_store(z_storage_type)
	db := p_parse.db
	if int(db.temp_store) == ts {
		return 0
	}
	if invalidate_temp_storage(p_parse) != 0 {
		return 1
	}
	db.temp_store = U8(ts)
	return 0
}

@[c:'setPragmaResultColumnNames']
fn set_pragma_result_column_names(v &Vdbe, p_pragma &PragmaName) {
	n := p_pragma.nPragCName
	sqlite3_vdbe_set_num_cols(v, if int(n) == 0 { 1 } else { int(n) })
	if int(n) == 0 {
		sqlite3_vdbe_set_col_name(v, 0, 0, p_pragma.zName, (C2vFn_666e2028766f696470747229(voidptr(0))))
	} else {
		i := 0
		j := 0

		i = 0
		for j = int(p_pragma.iPragCName); i < int(n); i++ {
			sqlite3_vdbe_set_col_name(v, i, 0, pragCName[j], (C2vFn_666e2028766f696470747229(voidptr(0))))
			j++
		}
	}
}

@[c:'returnSingleInt']
fn return_single_int(v &Vdbe, value I64) {
	sqlite3_vdbe_add_op4_dup8(v, 74, 0, 1, 0, &U8(c2v_address_of(&value)), (-14))
	sqlite3_vdbe_add_op2(v, 86, 1, 1)
}

@[c:'returnSingleText']
fn return_single_text(v &Vdbe, z_value &i8) {
	if z_value {
		sqlite3_vdbe_load_string(v, 1, &i8(z_value))
		sqlite3_vdbe_add_op2(v, 86, 1, 1)
	}
}

@[c:'setAllPagerFlags']
fn set_all_pager_flags(db &Sqlite3) {
	if db.autoCommit {
		p_db := db.aDb
		n := db.nDb
		for (n--) > 0 {
			if p_db.pBt {
				sqlite3_btree_set_pager_flags(p_db.pBt, u32(U64(p_db.safety_level) | (db.flags & U64(56))))
			}
			c2v_pointer_postfix(voidptr(&p_db), p_db, isize(1))
		}
	}
}

@[c:'actionName']
fn action_name(action U8) &i8 {
	z_name := &i8(0)
	match action {
		8 {
			z_name = c'SET NULL'
		}
		9 {
			z_name = c'SET DEFAULT'
		}
		10 {
			z_name = c'CASCADE'
		}
		7 {
			z_name = c'RESTRICT'
		}
		else {
			z_name = c'NO ACTION'
		}
	}

	return z_name
}

@[c:'sqlite3JournalModename']
fn sqlite3_journal_modename(e_mode int) &i8 {
	if !sqlite3_journal_modename_az_mode_name_inited {
		c2v_static_init := [c'delete', c'persist', c'off', c'truncate', c'memory', c'wal']
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_journal_modename_az_mode_name[c2v_i_0] = c2v_element_0
		}
		sqlite3_journal_modename_az_mode_name_inited = true
	}

	if e_mode == 6 {
		return unsafe { nil }
	}
	return sqlite3_journal_modename_az_mode_name[e_mode]
}

@[c:'pragmaLocate']
fn pragma_locate(z_name &i8) &PragmaName {
	upr := 0
	lwr := 0
	mid := 0
	rc := 0

	lwr = 0
	upr = 66
	for lwr <= upr {
		mid = (lwr + upr) / 2
		rc = sqlite3_stricmp(z_name, aPragmaName[mid].zName)
		if rc == 0 {
			break
		}
		if rc < 0 {
			upr = mid - 1
		} else {
			lwr = mid + 1
		}
	}
	return unsafe { if lwr > upr { &PragmaName(nil) } else { &aPragmaName[0] + mid } }
}

@[c:'pragmaFunclistLine']
fn pragma_funclist_line(v &Vdbe, p &FuncDef, is_builtin int, show_intern_funcs int) {
	mask := u32(2048 | 524288 | 1048576 | 2097152 | 262144)
	if show_intern_funcs {
		mask = u32(4294967295)
	}
	for ; p; p = p.pNext {
		z_type := &i8(0)
		if !pragma_funclist_line_az_enc_inited {
			c2v_static_init := [unsafe { &i8(nil) }, c'utf8', c'utf16le', c'utf16be']
			for c2v_i_0, c2v_element_0 in c2v_static_init {
				pragma_funclist_line_az_enc[c2v_i_0] = c2v_element_0
			}
			pragma_funclist_line_az_enc_inited = true
		}

		if isnil(p.xSFunc) {
			continue
		}
		if (p.funcFlags & u32(262144)) != u32(0) && show_intern_funcs == 0 {
			continue
		}
		if !isnil(p.xValue) {
			z_type = c'w'
		} else if !isnil(p.xFinalize) {
			z_type = c'a'
		} else {
			z_type = c's'
		}
		sqlite3_vdbe_multi_load(v, 1, c'sissii', voidptr(p.zName), is_builtin, voidptr(z_type), voidptr(pragma_funclist_line_az_enc[p.funcFlags & u32(3)]), int(p.nArg), (p.funcFlags & mask) ^ u32(2097152))
	}
}

@[c:'integrityCheckResultRow']
fn integrity_check_result_row(v &Vdbe) int {
	addr := 0
	sqlite3_vdbe_add_op2(v, 86, 3, 1)
	addr = sqlite3_vdbe_add_op3(v, 61, 1, sqlite3_vdbe_current_addr(v) + 2, 1)
	0
	sqlite3_vdbe_add_op0(v, 72)
	return addr
}

@[c:'tableSkipIntegrityCheck']
fn table_skip_integrity_check(p_tab &Table, p_obj_tab &Table) int {
	if p_obj_tab {
		return int(usize(p_tab) != usize(p_obj_tab))
	} else {
		return int((p_tab.tabFlags & u32(131072)) != u32(0))
	}
}

@[c:'sqlite3Pragma']
fn sqlite3_pragma(p_parse &Parse, p_id1 &Token, p_id2 &Token, p_value &Token, minus_flag int) {
	z_left := unsafe { &i8(nil) }
	z_right := unsafe { &i8(nil) }
	z_db := unsafe { &i8(nil) }
	p_id := &Token(0)
	a_fcntl := [4]&i8{}
	i_db := 0
	rc := 0
	db := p_parse.db
	p_db := &Db(0)
	v := sqlite3_get_vdbe(p_parse)
	p_pragma := &PragmaName(0)
	if usize(v) == usize(0) {
		return
	}
	sqlite3_vdbe_run_only_once(v)
	p_parse.nMem = 2
	i_db = sqlite3_two_part_name(p_parse, p_id1, p_id2, &&Token(&&Token(c2v_address_of(&p_id))))
	if i_db < 0 {
		return
	}
	p_db = unsafe { db.aDb + i_db }
	if i_db == 1 && sqlite3_open_temp_database(p_parse) {
		return
	}
	z_left = sqlite3_name_from_token(db, p_id)
	if isnil(z_left) {
		return
	}
	if minus_flag {
		z_right = sqlite3_mp_rintf(db, c'-%T', voidptr(p_value))
	} else {
		z_right = sqlite3_name_from_token(db, p_value)
	}
	z_db = unsafe { if p_id2.n > u32(0) { p_db.zDbSName } else { &i8(nil) } }
	if sqlite3_auth_check(p_parse, 19, z_left, z_right, z_db) {
		unsafe { goto pragma_out
		 }
	}
	a_fcntl[0] = 0
	a_fcntl[1] = z_left
	a_fcntl[2] = z_right
	a_fcntl[3] = 0
	db.busyHandler.nBusy = 0
	rc = sqlite3_file_control(db, z_db, 14, voidptr(unsafe { &a_fcntl[0] }))
	if rc == 0 {
		sqlite3_vdbe_set_num_cols(v, 1)
		sqlite3_vdbe_set_col_name(v, 0, 0, a_fcntl[0], (C2vFn_666e2028766f696470747229(voidptr(-1))))
		return_single_text(v, a_fcntl[0])
		sqlite3_free(voidptr(a_fcntl[0]))
		unsafe { goto pragma_out
		 }
	}
	if rc != 12 {
		if a_fcntl[0] {
			sqlite3_error_msg(p_parse, c'%s', voidptr(a_fcntl[0]))
			sqlite3_free(voidptr(a_fcntl[0]))
		}
		p_parse.nErr++
		p_parse.rc = rc
		unsafe { goto pragma_out
		 }
	}
	p_pragma = pragma_locate(z_left)
	if usize(p_pragma) == usize(0) {
		unsafe { goto pragma_out
		 }
	}
	if (int(p_pragma.mPragFlg) & 1) != 0 {
		if sqlite3_read_schema(p_parse) {
			unsafe { goto pragma_out
			 }
		}
	}
	if (int(p_pragma.mPragFlg) & 2) == 0 && ((int(p_pragma.mPragFlg) & 4) == 0 || usize(z_right) == usize(0)) {
		set_pragma_result_column_names(v, p_pragma)
	}
	match p_pragma.ePragTyp {
		13 {
			static i_ln := 0
			if !sqlite3_pragma_get_cache_size_inited {
				c2v_static_init := [VdbeOpList{
					opcode: U8(2)
					p1: i8(0)
					p2: i8(0)
					p3: i8(0)
				}, VdbeOpList{
					opcode: U8(101)
					p1: i8(0)
					p2: i8(1)
					p3: i8(3)
				}, VdbeOpList{
					opcode: U8(61)
					p1: i8(1)
					p2: i8(8)
					p3: i8(0)
				}, VdbeOpList{
					opcode: U8(73)
					p1: i8(0)
					p2: i8(2)
					p3: i8(0)
				}, VdbeOpList{
					opcode: U8(108)
					p1: i8(1)
					p2: i8(2)
					p3: i8(1)
				}, VdbeOpList{
					opcode: U8(61)
					p1: i8(1)
					p2: i8(8)
					p3: i8(0)
				}, VdbeOpList{
					opcode: U8(73)
					p1: i8(0)
					p2: i8(1)
					p3: i8(0)
				}, VdbeOpList{
					opcode: U8(189)
					p1: i8(0)
					p2: i8(0)
					p3: i8(0)
				}, VdbeOpList{
					opcode: U8(86)
					p1: i8(1)
					p2: i8(1)
					p3: i8(0)
				}]
				for c2v_i_0, c2v_element_0 in c2v_static_init {
					sqlite3_pragma_get_cache_size[c2v_i_0] = c2v_element_0
				}
				sqlite3_pragma_get_cache_size_inited = true
			}

			mut a_op := &VdbeOp(0)
			sqlite3_vdbe_uses_btree(v, i_db)
			if isnil(z_right) {
				p_parse.nMem += 2
				0
				a_op = sqlite3_vdbe_add_op_list(v, 9, &sqlite3_pragma_get_cache_size[0], i_ln)
				if 0 {
					unsafe { goto c2v_switch_end_51
					 }
				}
				a_op[0].p1 = i_db
				a_op[1].p1 = i_db
				a_op[6].p1 = -2000
			} else {
				size := sqlite3_abs_int32(sqlite3_atoi(z_right))
				sqlite3_begin_write_operation(p_parse, 0, i_db)
				sqlite3_vdbe_add_op3(v, 102, i_db, 3, size)
				p_db.pSchema.cache_size = size
				sqlite3_btree_set_cache_size(p_db.pBt, p_db.pSchema.cache_size)
			}
		}
		31 {
			p_bt := p_db.pBt
			if isnil(z_right) {
				size := if p_bt { sqlite3_btree_get_page_size(p_bt) } else { 0 }
				return_single_int(v, I64(size))
			} else {
				db.nextPagesize = sqlite3_atoi(z_right)
				if 7 == sqlite3_btree_set_page_size(p_bt, db.nextPagesize, 0, 0) {
					sqlite3_oom_fault(db)
				}
			}
		}
		33 {
			p_bt := p_db.pBt
			b := -1
			if z_right {
				if sqlite3_stricmp(z_right, c'fast') == 0 {
					b = 2
				} else {
					b = int(sqlite3_get_boolean(z_right, U8(0)))
				}
			}
			if p_id2.n == u32(0) && b >= 0 {
				ii := 0
				for ii = 0; ii < db.nDb; ii++ {
					sqlite3_btree_secure_delete(db.aDb[ii].pBt, b)
				}
			}
			b = sqlite3_btree_secure_delete(p_bt, b)
			return_single_int(v, I64(b))
		}
		27 {
			i_reg := 0
			x := I64(0)
			sqlite3_code_verify_schema(p_parse, i_db)
			i_reg = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			if int(sqlite3UpperToLower[u8(z_left[0])]) == `p` {
				sqlite3_vdbe_add_op2(v, 180, i_db, i_reg)
			} else {
				if !isnil(z_right) && sqlite3_dec_or_hex_to_i64(z_right, &x) == 0 {
					if x < I64(0) {
						x = I64(0)
					} else if x > I64(u32(4294967294)) {
						x = I64(u32(4294967294))
					}
				} else {
					x = I64(0)
				}
				sqlite3_vdbe_add_op3(v, 181, i_db, i_reg, int(x))
			}
			sqlite3_vdbe_add_op2(v, 86, i_reg, 1)
		}
		26 {
			z_ret := c'normal'
			e_mode := get_locking_mode(z_right)
			if p_id2.n == u32(0) && e_mode == -1 {
				e_mode = int(db.dfltLockMode)
			} else {
				p_pager := &Pager(0)
				if p_id2.n == u32(0) {
					ii := 0
					for ii = 2; ii < db.nDb; ii++ {
						p_pager = sqlite3_btree_pager(db.aDb[ii].pBt)
						sqlite3_pager_locking_mode(p_pager, e_mode)
					}
					db.dfltLockMode = U8(e_mode)
				}
				p_pager = sqlite3_btree_pager(p_db.pBt)
				e_mode = sqlite3_pager_locking_mode(p_pager, e_mode)
			}
			if e_mode == 1 {
				z_ret = c'exclusive'
			}
			return_single_text(v, z_ret)
		}
		23 {
			e_mode := 0
			ii := 0
			if usize(z_right) == usize(0) {
				e_mode = (-1)
			} else {
				z_mode := &i8(0)
				n := sqlite3_strlen30(z_right)
				for e_mode = 0; true; e_mode++ {
					z_mode = sqlite3_journal_modename(e_mode)
					if !(usize(z_mode) != usize(0)) {
						break
					}
					if sqlite3_strnicmp(z_right, z_mode, n) == 0 {
						break
					}
				}
				if isnil(z_mode) {
					e_mode = (-1)
				}
				if e_mode == 2 && (db.flags & U64(268435456)) != U64(0) {
					e_mode = (-1)
				}
			}
			if e_mode == (-1) && p_id2.n == u32(0) {
				i_db = 0
				p_id2.n = u32(1)
			}
			for ii = db.nDb - 1; ii >= 0; ii-- {
				if !isnil(db.aDb[ii].pBt) && (ii == i_db || p_id2.n == u32(0)) {
					sqlite3_vdbe_uses_btree(v, ii)
					sqlite3_vdbe_add_op3(v, 4, ii, 1, e_mode)
				}
			}
			sqlite3_vdbe_add_op2(v, 86, 1, 1)
		}
		24 {
			p_pager := sqlite3_btree_pager(p_db.pBt)
			i_limit := I64(-2)
			if z_right {
				sqlite3_dec_or_hex_to_i64(z_right, &i_limit)
				if i_limit < I64(-1) {
					i_limit = I64(-1)
				}
			}
			i_limit = sqlite3_pager_journal_size_limit(p_pager, i_limit)
			return_single_int(v, i_limit)
		}
		3 {
			p_bt := p_db.pBt
			if isnil(z_right) {
				return_single_int(v, I64(sqlite3_btree_get_auto_vacuum(p_bt)))
			} else {
				e_auto := get_auto_vacuum(z_right)
				db.nextAutovac = i8(U8(e_auto))
				rc = sqlite3_btree_set_auto_vacuum(p_bt, e_auto)
				if rc == 0 && (e_auto == 1 || e_auto == 2) {
					static i_ln := 0
					if !sqlite3_pragma_set_meta6_inited {
						c2v_static_init := [VdbeOpList{
							opcode: U8(2)
							p1: i8(0)
							p2: i8(1)
							p3: i8(0)
						}, VdbeOpList{
							opcode: U8(101)
							p1: i8(0)
							p2: i8(1)
							p3: i8(4)
						}, VdbeOpList{
							opcode: U8(16)
							p1: i8(1)
							p2: i8(0)
							p3: i8(0)
						}, VdbeOpList{
							opcode: U8(72)
							p1: i8(0)
							p2: i8(2)
							p3: i8(0)
						}, VdbeOpList{
							opcode: U8(102)
							p1: i8(0)
							p2: i8(7)
							p3: i8(0)
						}]
						for c2v_i_0, c2v_element_0 in c2v_static_init {
							sqlite3_pragma_set_meta6[c2v_i_0] = c2v_element_0
						}
						sqlite3_pragma_set_meta6_inited = true
					}

					mut a_op := &VdbeOp(0)
					i_addr := sqlite3_vdbe_current_addr(v)
					0
					a_op = sqlite3_vdbe_add_op_list(v, 5, &sqlite3_pragma_set_meta6[0], i_ln)
					if 0 {
						unsafe { goto c2v_switch_end_51
						 }
					}
					a_op[0].p1 = i_db
					a_op[1].p1 = i_db
					a_op[2].p2 = i_addr + 4
					a_op[4].p1 = i_db
					a_op[4].p3 = e_auto - 1
					sqlite3_vdbe_uses_btree(v, i_db)
				}
			}
		}
		19 {
			i_limit := 0
			addr := 0

			if usize(z_right) == usize(0) || !sqlite3_get_int32(z_right, &i_limit) || i_limit <= 0 {
				i_limit = 2147483647
			}
			sqlite3_begin_write_operation(p_parse, 0, i_db)
			sqlite3_vdbe_add_op2(v, 73, i_limit, 1)
			addr = sqlite3_vdbe_add_op1(v, 64, i_db)
			0
			sqlite3_vdbe_add_op1(v, 86, 1)
			sqlite3_vdbe_add_op2(v, 88, 1, -1)
			sqlite3_vdbe_add_op2(v, 61, 1, addr)
			0
			sqlite3_vdbe_jump_here(v, addr)
		}
		6 {
			if isnil(z_right) {
				return_single_int(v, I64(p_db.pSchema.cache_size))
			} else {
				size := sqlite3_atoi(z_right)
				p_db.pSchema.cache_size = size
				sqlite3_btree_set_cache_size(p_db.pBt, p_db.pSchema.cache_size)
			}
		}
		7 {
			if isnil(z_right) {
				return_single_int(v, I64(if (db.flags & U64(32)) == U64(0) {
					0
				} else {
					sqlite3_btree_set_spill_size(p_db.pBt, 0)
				}))
			} else {
				size := 1
				if sqlite3_get_int32(z_right, &size) {
					sqlite3_btree_set_spill_size(p_db.pBt, size)
				}
				if sqlite3_get_boolean(z_right, U8(size != 0)) {
					db.flags |= U64(32)
				} else {
					db.flags &= ~U64(32)
				}
				set_all_pager_flags(db)
			}
		}
		28 {
			sz := Sqlite3_int64(0)
			if z_right {
				ii := 0
				sqlite3_dec_or_hex_to_i64(z_right, unsafe { &I64(&sz) })
				if sz < Sqlite3_int64(0) {
					sz = sqlite3Config.szMmap
				}
				if p_id2.n == u32(0) {
					db.szMmap = sz
				}
				for ii = db.nDb - 1; ii >= 0; ii-- {
					if !isnil(db.aDb[ii].pBt) && (ii == i_db || p_id2.n == u32(0)) {
						sqlite3_btree_set_mmap_limit(db.aDb[ii].pBt, sz)
					}
				}
			}
			sz = Sqlite3_int64(-1)
			rc = sqlite3_file_control(db, z_db, 18, voidptr(&sz))
			if rc == 0 {
				return_single_int(v, sz)
			} else if rc != 12 {
				p_parse.nErr++
				p_parse.rc = rc
			}
		}
		39 {
			if isnil(z_right) {
				return_single_int(v, I64(db.temp_store))
			} else {
				change_temp_storage(p_parse, z_right)
			}
		}
		40 {
			sqlite3_mutex_enter(sqlite3_mutex_alloc_vdup4(11))
			if isnil(z_right) {
				return_single_text(v, sqlite3_temp_directory)
			} else {
				if z_right[0] {
					res := 0
					rc = sqlite3_os_access(db.pVfs, z_right, 1, &res)
					if rc != 0 || res == 0 {
						sqlite3_error_msg(p_parse, c'not a writable directory')
						sqlite3_mutex_leave(sqlite3_mutex_alloc_vdup4(11))
						unsafe { goto pragma_out
						 }
					}
				}
				if 1 == 0 || (1 == 1 && int(db.temp_store) <= 1) || (1 == 2 && int(db.temp_store) == 1) {
					invalidate_temp_storage(p_parse)
				}
				sqlite3_free(voidptr(sqlite3_temp_directory))
				if z_right[0] {
					sqlite3_temp_directory = sqlite3_mprintf(c'%s', voidptr(z_right))
				} else {
					sqlite3_temp_directory = 0
				}
			}
			sqlite3_mutex_leave(sqlite3_mutex_alloc_vdup4(11))
		}
		25 {
			if isnil(z_right) {
				p_pager := sqlite3_btree_pager(p_db.pBt)
				proxy_file_path := unsafe { &i8(nil) }
				p_file := sqlite3_pager_file(p_pager)
				sqlite3_os_file_control_hint(p_file, 2, voidptr(&&i8(c2v_address_of(&proxy_file_path))))
				return_single_text(v, proxy_file_path)
			} else {
				p_pager := sqlite3_btree_pager(p_db.pBt)
				p_file := sqlite3_pager_file(p_pager)
				res := 0
				if z_right[0] {
					res = sqlite3_os_file_control(p_file, 3, voidptr(z_right))
				} else {
					res = sqlite3_os_file_control(p_file, 3, voidptr((voidptr(0))))
				}
				if res != 0 {
					sqlite3_error_msg(p_parse, c'failed to set lock proxy file')
					unsafe { goto pragma_out
					 }
				}
			}
		}
		36 {
			if isnil(z_right) {
				return_single_int(v, I64(int(p_db.safety_level) - 1))
			} else {
				if !db.autoCommit {
					sqlite3_error_msg(p_parse, c'Safety level may not be changed inside a transaction')
				} else if i_db != 1 {
					i_level := (int(get_safety_level(z_right, 0, U8(1))) + 1) & 7
					if i_level == 0 {
						i_level = 1
					}
					p_db.safety_level = U8(i_level)
					p_db.bSyncSet = U8(1)
					set_all_pager_flags(db)
				}
			}
		}
		4 {
			if usize(z_right) == usize(0) {
				set_pragma_result_column_names(v, p_pragma)
				return_single_int(v, I64((db.flags & p_pragma.iArg) != U64(0)))
			} else {
				mask := p_pragma.iArg
				if int(db.autoCommit) == 0 {
					mask &= U64(~16384)
				}
				if sqlite3_get_boolean(z_right, U8(0)) {
					if (mask & U64(1)) == U64(0) || (db.flags & U64(268435456)) == U64(0) {
						db.flags |= mask
					}
				} else {
					db.flags &= ~mask
					if mask == U64(524288) {
						db.nDeferredImmCons = I64(0)
						db.nDeferredCons = I64(0)
					}
					if (mask & U64(1)) != U64(0) && sqlite3_stricmp(z_right, c'reset') == 0 {
						sqlite3_reset_all_schemas_of_connection(db)
					}
				}
				sqlite3_vdbe_add_op0(v, 168)
				set_all_pager_flags(db)
			}
		}
		37 {
			if z_right {
				p_tab := &Table(0)
				sqlite3_code_verify_named_schema(p_parse, z_db)
				p_tab = sqlite3_locate_table(p_parse, u32(2), z_right, z_db)
				if p_tab {
					i := 0
					k := 0

					n_hidden := 0
					p_col := &Column(0)
					p_pk := sqlite3_primary_key_index(p_tab)
					p_parse.nMem = 7
					sqlite3_view_get_column_names(p_parse, p_tab)
					i = 0
					for p_col = p_tab.aCol; i < int(p_tab.nCol); i++ {
						is_hidden := 0
						p_col_expr := &Expr(0)
						if int(p_col.colFlags) & 98 {
							if p_pragma.iArg == U64(0) {
								n_hidden++
								unsafe { goto c2v_for_next_127
								 }
							}
							if int(p_col.colFlags) & 32 {
								is_hidden = 2
							} else if int(p_col.colFlags) & 64 {
								is_hidden = 3
							} else {
								is_hidden = 1
							}
						}
						if (int(p_col.colFlags) & 1) == 0 {
							k = 0
						} else if usize(p_pk) == usize(0) {
							k = 1
						} else {
							for k = 1; k <= int(p_tab.nCol) && int(p_pk.aiColumn[k - 1]) != i; k++ {
							}
						}
						p_col_expr = sqlite3_column_expr(p_tab, p_col)
						sqlite3_vdbe_multi_load(v, 1, unsafe { if p_pragma.iArg {
							c'issisii'
						} else {
							c'issisi'
						} }, i - n_hidden, voidptr(p_col.zCnName), voidptr(sqlite3_column_type_vdup1(p_col, c'')), if int(p_col.notNull) {
							1
						} else {
							0
						}, voidptr(unsafe { if (is_hidden >= 2 || usize(p_col_expr) == usize(0)) {
							&i8(nil)
						} else {
							p_col_expr.u.zToken
						} }), k, is_hidden)
						c2v_for_next_127:
						c2v_pointer_postfix(voidptr(&p_col), p_col, isize(1))
					}
				}
			}
		}
		38 {
			ii := 0
			p_parse.nMem = 6
			sqlite3_code_verify_named_schema(p_parse, z_db)
			for ii = 0; ii < db.nDb; ii++ {
				k := &HashElem(0)
				p_hash := &Hash(0)
				init_nc_ol := 0
				if !isnil(z_db) && sqlite3_stricmp(z_db, db.aDb[ii].zDbSName) != 0 {
					continue
				}
				p_hash = &db.aDb[ii].pSchema.tblHash
				init_nc_ol = int(p_hash.count)
				for init_nc_ol-- {
					for k = p_hash.first; 1; k = k.next {
						p_tab := &Table(0)
						if usize(k) == usize(0) {
							init_nc_ol = 0
							break
						}
						p_tab = k.data
						if int(p_tab.nCol) == 0 {
							z_sql := sqlite3_mp_rintf(db, c'SELECT*FROM"%w"', voidptr(p_tab.zName))
							if z_sql {
								p_dummy := unsafe { &Sqlite3_stmt(nil) }
								sqlite3_prepare_v3(db, z_sql, -1, u32(16), &&Sqlite3_stmt(&&Sqlite3_stmt(c2v_address_of(&p_dummy))), unsafe { &&u8(nil) })
								sqlite3_finalize(p_dummy)
								sqlite3_db_free(db, voidptr(z_sql))
							}
							if db.mallocFailed {
								sqlite3_error_msg(db.pParse, c'out of memory')
								db.pParse.rc = 7
							}
							p_hash = &db.aDb[ii].pSchema.tblHash
							break
						}
					}
				}
				for k = p_hash.first; k; k = k.next {
					p_tab := &Table(k.data)
					z_type := &i8(0)
					if !isnil(z_right) && sqlite3_stricmp(z_right, p_tab.zName) != 0 {
						continue
					}
					if (int(p_tab.eTabType) == 2) {
						z_type = c'view'
					} else if (int(p_tab.eTabType) == 1) {
						z_type = c'virtual'
					} else if p_tab.tabFlags & u32(4096) {
						z_type = c'shadow'
					} else {
						z_type = c'table'
					}
					sqlite3_vdbe_multi_load(v, 1, c'sssiii', voidptr(db.aDb[ii].zDbSName), voidptr(sqlite3_preferred_table_name(p_tab.zName)), voidptr(z_type), int(p_tab.nCol), (p_tab.tabFlags & u32(128)) != u32(0), (p_tab.tabFlags & u32(65536)) != u32(0))
				}
			}
		}
		20 {
			if z_right {
				p_idx := &Index(0)
				p_tab := &Table(0)
				p_idx = sqlite3_find_index(db, z_right, z_db)
				if usize(p_idx) == usize(0) {
					p_tab = sqlite3_locate_table(p_parse, u32(2), z_right, z_db)
					if !isnil(p_tab) && !((p_tab.tabFlags & u32(128)) == u32(0)) {
						p_idx = sqlite3_primary_key_index(p_tab)
					}
				}
				if p_idx {
					i_idx_db := sqlite3_schema_to_index(db, p_idx.pSchema)
					i := 0
					mx := 0
					if p_pragma.iArg {
						mx = int(p_idx.nColumn)
						p_parse.nMem = 6
					} else {
						mx = int(p_idx.nKeyCol)
						p_parse.nMem = 3
					}
					p_tab = p_idx.pTable
					sqlite3_code_verify_schema(p_parse, i_idx_db)
					for i = 0; i < mx; i++ {
						cnum := p_idx.aiColumn[i]
						sqlite3_vdbe_multi_load(v, 1, c'iisX', i, int(cnum), voidptr(unsafe { if int(cnum) < 0 {
							&i8(nil)
						} else {
							p_tab.aCol[cnum].zCnName
						} }))
						if p_pragma.iArg {
							sqlite3_vdbe_multi_load(v, 4, c'isiX', int(p_idx.aSortOrder[i]), voidptr(p_idx.azColl[i]), i < int(p_idx.nKeyCol))
						}
						sqlite3_vdbe_add_op2(v, 86, 1, p_parse.nMem)
					}
				}
			}
		}
		21 {
			if z_right {
				p_idx := &Index(0)
				p_tab := &Table(0)
				i := 0
				p_tab = sqlite3_find_table(db, z_right, z_db)
				if p_tab {
					i_tab_db := sqlite3_schema_to_index(db, p_tab.pSchema)
					p_parse.nMem = 5
					sqlite3_code_verify_schema(p_parse, i_tab_db)
					p_idx = p_tab.pIndex
					for i = 0; p_idx;  {
						az_origin := [c'c', c'u', c'pk']

						sqlite3_vdbe_multi_load(v, 1, c'isisi', i, voidptr(p_idx.zName), (int(p_idx.onError) != 0), voidptr(az_origin[p_idx.idxType]), usize(p_idx.pPartIdxWhere) != usize(0))
						p_idx = p_idx.pNext
						i++
					}
				}
			}
		}
		12 {
			i := 0
			p_parse.nMem = 3
			for i = 0; i < db.nDb; i++ {
				if usize(db.aDb[i].pBt) == usize(0) {
					continue
				}
				sqlite3_vdbe_multi_load(v, 1, c'iss', i, voidptr(db.aDb[i].zDbSName), voidptr(sqlite3_btree_get_filename(db.aDb[i].pBt)))
			}
		}
		9 {
			i := 0
			p := &HashElem(0)
			p_parse.nMem = 2
			for p = db.aCollSeq.first; p; p = p.next {
				p_coll := &CollSeq(p.data)
				sqlite3_vdbe_multi_load(v, 1, c'is', i++, voidptr(p_coll.zName))
			}
		}
		17 {
			i := 0
			j := &HashElem(0)
			p := &FuncDef(0)
			show_intern_func := int((db.mDbFlags & u32(32)) != u32(0))
			p_parse.nMem = 6
			for i = 0; i < 23; i++ {
				for p = sqlite3BuiltinFunctions.a[i]; p; p = p.u.pHash {
					pragma_funclist_line(v, p, 1, show_intern_func)
				}
			}
			for j = db.aFunc.first; j; j = j.next {
				p = &FuncDef(j.data)
				pragma_funclist_line(v, p, 0, show_intern_func)
			}
		}
		29 {
			j := &HashElem(0)
			p_parse.nMem = 1
			for j = db.aModule.first; j; j = j.next {
				p_mod := &Module(j.data)
				sqlite3_vdbe_multi_load(v, 1, c's', voidptr(p_mod.zName))
			}
		}
		32 {
			i := 0
			for i = 0; i < 67; i++ {
				sqlite3_vdbe_multi_load(v, 1, c's', voidptr(aPragmaName[i].zName))
			}
		}
		16 {
			if z_right {
				pfk := &FKey(0)
				p_tab := &Table(0)
				p_tab = sqlite3_find_table(db, z_right, z_db)
				if !isnil(p_tab) && (int(p_tab.eTabType) == 0) {
					pfk = p_tab.u.tab.pFKey
					if pfk {
						i_tab_db := sqlite3_schema_to_index(db, p_tab.pSchema)
						i := 0
						p_parse.nMem = 8
						sqlite3_code_verify_schema(p_parse, i_tab_db)
						for pfk {
							j := 0
							for j = 0; j < pfk.nCol; j++ {
								sqlite3_vdbe_multi_load(v, 1, c'iissssss', i, j, voidptr(pfk.zTo), voidptr(p_tab.aCol[c2v_at(&pfk.aCol[0], isize(j)).iFrom].zCnName), voidptr(c2v_at(&pfk.aCol[0], isize(j)).zCol), voidptr(action_name(pfk.aAction[1])), voidptr(action_name(pfk.aAction[0])), voidptr(c'NONE'))
							}
							i++
							pfk = pfk.pNextFrom
						}
					}
				}
			}
		}
		15 {
			pfk := &FKey(0)
			p_tab := &Table(0)
			p_parent := &Table(0)
			p_idx := &Index(0)
			i := 0
			j := 0
			k := &HashElem(0)
			x := 0
			reg_result := 0
			reg_row := 0
			addr_top := 0
			addr_ok := 0
			ai_cols := &int(0)
			reg_result = p_parse.nMem + 1
			p_parse.nMem += 4
			reg_row = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			k = db.aDb[i_db].pSchema.tblHash.first
			for k {
				if z_right {
					p_tab = sqlite3_locate_table(p_parse, u32(0), z_right, z_db)
					k = 0
				} else {
					p_tab = &Table(k.data)
					k = k.next
				}
				if usize(p_tab) == usize(0) || !(int(p_tab.eTabType) == 0) || usize(p_tab.u.tab.pFKey) == usize(0) {
					continue
				}
				i_db = sqlite3_schema_to_index(db, p_tab.pSchema)
				z_db = db.aDb[i_db].zDbSName
				sqlite3_code_verify_schema(p_parse, i_db)
				sqlite3_table_lock(p_parse, i_db, p_tab.tnum, U8(0), p_tab.zName)
				sqlite3_touch_register(p_parse, int(p_tab.nCol) + reg_row)
				sqlite3_open_table(p_parse, 0, i_db, p_tab, 114)
				sqlite3_vdbe_load_string(v, reg_result, p_tab.zName)
				i = 1
				for pfk = p_tab.u.tab.pFKey; pfk;  {
					p_parent = sqlite3_find_table(db, pfk.zTo, z_db)
					if usize(p_parent) == usize(0) {
						unsafe { goto c2v_for_next_129
						 }
					}
					p_idx = 0
					sqlite3_table_lock(p_parse, i_db, p_parent.tnum, U8(0), p_parent.zName)
					x = sqlite3_fk_locate_index(p_parse, p_parent, pfk, &&Index(&&Index(c2v_address_of(&p_idx))), unsafe { &&int(nil) })
					if x == 0 {
						if usize(p_idx) == usize(0) {
							sqlite3_open_table(p_parse, i, i_db, p_parent, 114)
						} else {
							sqlite3_vdbe_add_op3(v, 114, i, int(p_idx.tnum), i_db)
							sqlite3_vdbe_set_p4_key_info(p_parse, p_idx)
						}
					} else {
						k = 0
						break
					}
					c2v_for_next_129:
					i++
					pfk = pfk.pNextFrom
				}
				if pfk {
					break
				}
				if p_parse.nTab < i {
					p_parse.nTab = i
				}
				addr_top = sqlite3_vdbe_add_op1(v, 36, 0)
				0
				i = 1
				for pfk = p_tab.u.tab.pFKey; pfk;  {
					p_parent = sqlite3_find_table(db, pfk.zTo, z_db)
					p_idx = 0
					ai_cols = 0
					if p_parent {
						x = sqlite3_fk_locate_index(p_parse, p_parent, pfk, &&Index(&&Index(c2v_address_of(&p_idx))), &&int(&&int(c2v_address_of(&ai_cols))))
					}
					addr_ok = sqlite3_vdbe_make_label(p_parse)
					sqlite3_touch_register(p_parse, reg_row + pfk.nCol)
					for j = 0; j < pfk.nCol; j++ {
						i_col := if ai_cols {
							ai_cols[j]
						} else {
							c2v_at(&pfk.aCol[0], isize(j)).iFrom
						}
						sqlite3_expr_code_get_column_of_table(v, p_tab, 0, i_col, reg_row + j)
						sqlite3_vdbe_add_op2(v, 51, reg_row + j, addr_ok)
						0
					}
					if p_idx {
						sqlite3_vdbe_add_op4(v, 98, reg_row, pfk.nCol, 0, sqlite3_index_affinity_str(db, p_idx), pfk.nCol)
						sqlite3_vdbe_add_op4_int(v, 29, i, addr_ok, reg_row, pfk.nCol)
						0
					} else if p_parent {
						jmp := sqlite3_vdbe_current_addr(v) + 2
						sqlite3_vdbe_add_op3(v, 30, i, jmp, reg_row)
						0
						sqlite3_vdbe_goto(v, addr_ok)
					}
					if ((p_tab.tabFlags & u32(128)) == u32(0)) {
						sqlite3_vdbe_add_op2(v, 137, 0, reg_result + 1)
					} else {
						sqlite3_vdbe_add_op2(v, 77, 0, reg_result + 1)
					}
					sqlite3_vdbe_multi_load(v, reg_result + 2, c'siX', voidptr(pfk.zTo), i - 1)
					sqlite3_vdbe_add_op2(v, 86, reg_result, 4)
					sqlite3_vdbe_resolve_label(v, addr_ok)
					sqlite3_db_free(db, voidptr(ai_cols))
					i++
					pfk = pfk.pNextFrom
				}
				sqlite3_vdbe_add_op2(v, 40, 0, addr_top + 1)
				0
				sqlite3_vdbe_jump_here(v, addr_top)
			}
		}
		8 {
			if z_right {
				sqlite3_register_like_functions(db, int(sqlite3_get_boolean(z_right, U8(0))))
			}
		}
		22 {
			i := 0
			j := 0
			addr := 0
			mx_err := 0

			p_obj_tab := unsafe { &Table(nil) }
			is_quick := int((int(sqlite3UpperToLower[u8(z_left[0])]) == `q`))
			if usize(p_id2.z) == usize(0) {
				i_db = -1
			}
			p_parse.nMem = 6
			mx_err = 100
			if z_right {
				if sqlite3_get_int32(p_value.z, &mx_err) {
					if mx_err <= 0 {
						mx_err = 100
					}
				} else {
					p_obj_tab = sqlite3_locate_table(p_parse, u32(0), z_right, unsafe { if i_db >= 0 {
						db.aDb[i_db].zDbSName
					} else {
						&i8(nil)
					} })
				}
			}
			sqlite3_vdbe_add_op2(v, 73, mx_err - 1, 1)
			for i = 0; i < db.nDb; i++ {
				x := &HashElem(0)
				p_tbls := &Hash(0)
				a_root := &int(0)
				cnt := 0
				if 0 && i == 1 {
					continue
				}
				if i_db >= 0 && i != i_db {
					continue
				}
				sqlite3_code_verify_schema(p_parse, i)
				p_parse.okConstFactor = Bft(0)
				p_tbls = &db.aDb[i].pSchema.tblHash
				cnt = 0
				for x = p_tbls.first; x; x = x.next {
					p_tab := &Table(x.data)
					p_idx := &Index(0)
					n_idx := 0
					if table_skip_integrity_check(p_tab, p_obj_tab) {
						continue
					}
					if ((p_tab.tabFlags & u32(128)) == u32(0)) {
						cnt++
					}
					n_idx = 0
					for p_idx = p_tab.pIndex; p_idx;  {
						cnt++
						p_idx = p_idx.pNext
						n_idx++
					}
				}
				if cnt == 0 {
					continue
				}
				if p_obj_tab {
					cnt++
				}
				a_root = sqlite3_db_malloc_raw_nn(db, U64(sizeof(int) * u64((cnt + 1))))
				if usize(a_root) == usize(0) {
					break
				}
				cnt = 0
				if p_obj_tab {
					a_root[c2v_prefix_add(unsafe { &cnt }, 1)] = 0
				}
				for x = p_tbls.first; x; x = x.next {
					p_tab := &Table(x.data)
					p_idx := &Index(0)
					if table_skip_integrity_check(p_tab, p_obj_tab) {
						continue
					}
					if ((p_tab.tabFlags & u32(128)) == u32(0)) {
						a_root[c2v_prefix_add(unsafe { &cnt }, 1)] = int(p_tab.tnum)
					}
					for p_idx = p_tab.pIndex; p_idx; p_idx = p_idx.pNext {
						a_root[c2v_prefix_add(unsafe { &cnt }, 1)] = int(p_idx.tnum)
					}
				}
				a_root[0] = cnt
				sqlite3_touch_register(p_parse, 8 + cnt)
				sqlite3_vdbe_add_op3(v, 77, 0, 8, 8 + cnt)
				sqlite3_clear_temp_reg_cache(p_parse)
				sqlite3_vdbe_add_op4(v, 157, 1, cnt, 8, &i8(voidptr(a_root)), (-15))
				sqlite3_vdbe_change_p5(v, U16(i))
				addr = sqlite3_vdbe_add_op1(v, 51, 2)
				0
				sqlite3_vdbe_add_op4(v, 118, 0, 3, 0, sqlite3_mp_rintf(db, c'*** in database %s ***\n', voidptr(db.aDb[i].zDbSName)), (-7))
				sqlite3_vdbe_add_op3(v, 112, 2, 3, 3)
				integrity_check_result_row(v)
				sqlite3_vdbe_jump_here(v, addr)
				cnt = if p_obj_tab { 1 } else { 0 }
				sqlite3_vdbe_load_string(v, 2, c'wrong # of entries in index ')
				for x = p_tbls.first; x; x = x.next {
					i_tab := 0
					p_tab := &Table(x.data)
					p_idx := &Index(0)
					if table_skip_integrity_check(p_tab, p_obj_tab) {
						continue
					}
					if ((p_tab.tabFlags & u32(128)) == u32(0)) {
						mut __c2v_postfix_value_22 := cnt
						cnt++
						i_tab = __c2v_postfix_value_22
					} else {
						i_tab = cnt
						for p_idx = p_tab.pIndex; p_idx; p_idx = p_idx.pNext {
							if (int(p_idx.idxType) == 2) {
								break
							}
							i_tab++
						}
					}
					for p_idx = p_tab.pIndex; p_idx; p_idx = p_idx.pNext {
						if usize(p_idx.pPartIdxWhere) == usize(0) {
							addr = sqlite3_vdbe_add_op3(v, 54, 8 + cnt, 0, 8 + i_tab)
							0
							sqlite3_vdbe_load_string(v, 4, p_idx.zName)
							sqlite3_vdbe_add_op3(v, 112, 4, 2, 3)
							integrity_check_result_row(v)
							sqlite3_vdbe_jump_here(v, addr)
						}
						cnt++
					}
				}
				for x = p_tbls.first; x; x = x.next {
					p_tab := &Table(x.data)
					p_idx := &Index(0)
					p_pk := &Index(0)

					p_prior := unsafe { &Index(nil) }
					loop_top := 0
					i_data_cur := 0
					i_idx_cur := 0

					r1 := -1
					b_strict := 0
					r2 := 0
					mx_col := 0
					if table_skip_integrity_check(p_tab, p_obj_tab) {
						continue
					}
					if !(int(p_tab.eTabType) == 0) {
						continue
					}
					if is_quick || ((p_tab.tabFlags & u32(128)) == u32(0)) {
						p_pk = 0
						r2 = 0
					} else {
						p_pk = sqlite3_primary_key_index(p_tab)
						r2 = sqlite3_get_temp_range(p_parse, int(p_pk.nKeyCol))
						sqlite3_vdbe_add_op3(v, 77, 1, r2, r2 + int(p_pk.nKeyCol) - 1)
					}
					sqlite3_open_table_and_indices(p_parse, p_tab, 114, U8(0), 1, unsafe { nil }, &i_data_cur, &i_idx_cur)
					sqlite3_vdbe_add_op2(v, 73, 0, 7)
					j = 0
					for p_idx = p_tab.pIndex; p_idx;  {
						sqlite3_vdbe_add_op2(v, 73, 0, 8 + j)
						p_idx = p_idx.pNext
						j++
					}
					sqlite3_vdbe_add_op2(v, 36, i_data_cur, 0)
					0
					loop_top = sqlite3_vdbe_add_op2(v, 88, 7, 1)
					if ((p_tab.tabFlags & u32(128)) == u32(0)) {
						mx_col = -1
						for j = 0; j < int(p_tab.nCol); j++ {
							if (int(p_tab.aCol[j].colFlags) & 32) == 0 {
								mx_col++
							}
						}
						if mx_col == int(p_tab.iPKey) {
							mx_col--
						}
					} else {
						mx_col = int(sqlite3_primary_key_index(p_tab).nColumn) - 1
					}
					if mx_col >= 0 {
						sqlite3_vdbe_add_op3(v, 96, i_data_cur, mx_col, 3)
						sqlite3_vdbe_typeof_column(v, 3)
					}
					if !is_quick {
						if p_pk {
							a1 := 0
							z_err := &i8(0)
							a1 = sqlite3_vdbe_add_op4_int(v, 42, i_data_cur, 0, r2, int(p_pk.nKeyCol))
							0
							sqlite3_vdbe_add_op1(v, 51, r2)
							0
							z_err = sqlite3_mp_rintf(db, c'row not in PRIMARY KEY order for %s', voidptr(p_tab.zName))
							sqlite3_vdbe_add_op4(v, 118, 0, 3, 0, z_err, (-7))
							integrity_check_result_row(v)
							sqlite3_vdbe_jump_here(v, a1)
							sqlite3_vdbe_jump_here(v, a1 + 1)
							for j = 0; j < int(p_pk.nKeyCol); j++ {
								sqlite3_expr_code_load_index_column(p_parse, p_pk, i_data_cur, j, r2 + j)
							}
						}
					}
					b_strict = (p_tab.tabFlags & u32(65536)) != u32(0)
					for j = 0; j < int(p_tab.nCol); j++ {
						z_err := &i8(0)
						p_col := p_tab.aCol + j
						label_error := 0
						label_ok := 0
						p1 := 0
						p3 := 0
						p4 := 0

						do_type_check := 0
						if j == int(p_tab.iPKey) {
							continue
						}
						if b_strict {
							do_type_check = int(p_col.eCType) > 1
						} else {
							do_type_check = int(p_col.affinity) > 65
						}
						if int(p_col.notNull) == 0 && !do_type_check {
							continue
						}
						p4 = 5
						if int(p_col.colFlags) & 32 {
							sqlite3_expr_code_get_column_of_table(v, p_tab, i_data_cur, j, 3)
							p1 = -1
							p3 = 3
						} else {
							if p_col.iDflt {
								p_dflt_value := unsafe { &Sqlite3_value(nil) }
								sqlite3_value_from_expr(db, sqlite3_column_expr(p_tab, p_col), db.enc, U8(p_col.affinity), &&Sqlite3_value(&&Sqlite3_value(c2v_address_of(&p_dflt_value))))
								if p_dflt_value {
									p4 = sqlite3_value_type(p_dflt_value)
									sqlite3_value_free_vdup7(p_dflt_value)
								}
							}
							p1 = i_data_cur
							if !((p_tab.tabFlags & u32(128)) == u32(0)) {
								0
								p3 = sqlite3_table_column_to_index(sqlite3_primary_key_index(p_tab), j)
							} else {
								p3 = int(sqlite3_table_column_to_storage(p_tab, I16(j)))
								0
							}
						}
						label_error = sqlite3_vdbe_make_label(p_parse)
						label_ok = sqlite3_vdbe_make_label(p_parse)
						if p_col.notNull {
							jmp3 := 0
							jmp2 := sqlite3_vdbe_add_op4_int(v, 18, p1, label_ok, p3, p4)
							0
							if p1 < 0 {
								sqlite3_vdbe_change_p5(v, U16(15))
								jmp3 = jmp2
							} else {
								sqlite3_vdbe_change_p5(v, U16(13))
								sqlite3_vdbe_add_op3(v, 96, p1, p3, 3)
								sqlite3_column_default(v, p_tab, j, 3)
								jmp3 = sqlite3_vdbe_add_op2(v, 52, 3, label_ok)
								0
							}
							z_err = sqlite3_mp_rintf(db, c'NULL value in %s.%s', voidptr(p_tab.zName), voidptr(p_col.zCnName))
							sqlite3_vdbe_add_op4(v, 118, 0, 3, 0, z_err, (-7))
							if do_type_check {
								sqlite3_vdbe_goto(v, label_error)
								sqlite3_vdbe_jump_here(v, jmp2)
								sqlite3_vdbe_jump_here(v, jmp3)
							} else {
							}
						}
						if b_strict && do_type_check {
							if !sqlite3_pragma_a_std_type_mask_inited {
								c2v_static_init := [u8(31), u8(24), u8(17), u8(17), u8(19), u8(20)]
								for c2v_i_0, c2v_element_0 in c2v_static_init {
									sqlite3_pragma_a_std_type_mask[c2v_i_0] = c2v_element_0
								}
								sqlite3_pragma_a_std_type_mask_inited = true
							}

							sqlite3_vdbe_add_op4_int(v, 18, p1, label_ok, p3, p4)
							sqlite3_vdbe_change_p5(v, U16(sqlite3_pragma_a_std_type_mask[int(p_col.eCType) - 1]))
							0
							z_err = sqlite3_mp_rintf(db, c'non-%s value in %s.%s', voidptr(sqlite3StdType[int(p_col.eCType) - 1]), voidptr(p_tab.zName), voidptr(p_tab.aCol[j].zCnName))
							sqlite3_vdbe_add_op4(v, 118, 0, 3, 0, z_err, (-7))
						} else if !b_strict && int(p_col.affinity) == 66 {
							sqlite3_vdbe_add_op4_int(v, 18, p1, label_ok, p3, p4)
							sqlite3_vdbe_change_p5(v, U16(28))
							0
							z_err = sqlite3_mp_rintf(db, c'NUMERIC value in %s.%s', voidptr(p_tab.zName), voidptr(p_tab.aCol[j].zCnName))
							sqlite3_vdbe_add_op4(v, 118, 0, 3, 0, z_err, (-7))
						} else if !b_strict && int(p_col.affinity) >= 67 {
							sqlite3_vdbe_add_op4_int(v, 18, p1, label_ok, p3, p4)
							sqlite3_vdbe_change_p5(v, U16(27))
							0
							if p1 >= 0 {
								sqlite3_expr_code_get_column_of_table(v, p_tab, i_data_cur, j, 3)
							}
							sqlite3_vdbe_add_op4(v, 98, 3, 1, 0, c'C', (-1))
							sqlite3_vdbe_add_op4_int(v, 18, -1, label_ok, 3, p4)
							sqlite3_vdbe_change_p5(v, U16(28))
							0
							z_err = sqlite3_mp_rintf(db, c'TEXT value in %s.%s', voidptr(p_tab.zName), voidptr(p_tab.aCol[j].zCnName))
							sqlite3_vdbe_add_op4(v, 118, 0, 3, 0, z_err, (-7))
						}
						sqlite3_vdbe_resolve_label(v, label_error)
						integrity_check_result_row(v)
						sqlite3_vdbe_resolve_label(v, label_ok)
					}
					if !isnil(p_tab.pCheck) && (db.flags & U64(512)) == U64(0) {
						p_check := sqlite3_expr_list_dup(db, p_tab.pCheck, 0)
						if int(db.mallocFailed) == 0 {
							addr_ck_fault := sqlite3_vdbe_make_label(p_parse)
							addr_ck_ok := sqlite3_vdbe_make_label(p_parse)
							z_err := &i8(0)
							k := 0
							p_parse.iSelfTab = i_data_cur + 1
							for k = p_check.nExpr - 1; k > 0; k-- {
								sqlite3_expr_if_false(p_parse, c2v_at(&p_check.a[0], isize(k)).pExpr, addr_ck_fault, 0)
							}
							sqlite3_expr_if_true(p_parse, c2v_at(&p_check.a[0], isize(0)).pExpr, addr_ck_ok, 16)
							sqlite3_vdbe_resolve_label(v, addr_ck_fault)
							p_parse.iSelfTab = 0
							z_err = sqlite3_mp_rintf(db, c'CHECK constraint failed in %s', voidptr(p_tab.zName))
							sqlite3_vdbe_add_op4(v, 118, 0, 3, 0, z_err, (-7))
							integrity_check_result_row(v)
							sqlite3_vdbe_resolve_label(v, addr_ck_ok)
						}
						sqlite3_expr_list_delete(db, p_check)
					}
					if !is_quick {
						j = 0
						for p_idx = p_tab.pIndex; p_idx;  {
							jmp2 := 0
							jmp3 := 0
							jmp4 := 0
							jmp5 := 0
							label6 := 0

							kk := 0
							ck_uniq := sqlite3_vdbe_make_label(p_parse)
							if usize(p_pk) == usize(p_idx) {
								unsafe { goto c2v_for_next_133
								 }
							}
							r1 = sqlite3_generate_index_key(p_parse, p_idx, i_data_cur, 0, 0, &jmp3, p_prior, r1)
							p_prior = p_idx
							sqlite3_vdbe_add_op2(v, 88, 8 + j, 1)
							sqlite3_vdbe_add_op4_int(v, 29, i_idx_cur + j, ck_uniq, r1, int(p_idx.nColumn))
							0
							jmp2 = sqlite3_vdbe_add_op3(v, 47, i_idx_cur + j, ck_uniq, r1)
							0
							sqlite3_vdbe_change_p4(v, -1, &i8(voidptr(p_idx)), (-6))
							sqlite3_vdbe_add_op4(v, 118, 0, 3, 0, sqlite3_mp_rintf(db, c'index %s stores an imprecise floating-point value for row ', voidptr(p_idx.zName)), (-7))
							sqlite3_vdbe_add_op3(v, 112, 7, 3, 3)
							integrity_check_result_row(v)
							sqlite3_vdbe_add_op2(v, 9, 0, ck_uniq)
							sqlite3_vdbe_jump_here(v, jmp2)
							sqlite3_vdbe_load_string(v, 3, c'row ')
							sqlite3_vdbe_add_op3(v, 112, 7, 3, 3)
							sqlite3_vdbe_load_string(v, 4, c' missing from index ')
							sqlite3_vdbe_add_op3(v, 112, 4, 3, 3)
							jmp5 = sqlite3_vdbe_load_string(v, 4, p_idx.zName)
							sqlite3_vdbe_add_op3(v, 112, 4, 3, 3)
							jmp4 = integrity_check_result_row(v)
							sqlite3_vdbe_resolve_label(v, ck_uniq)
							if ((p_tab.tabFlags & u32(128)) == u32(0)) {
								jmp7 := 0
								sqlite3_vdbe_add_op2(v, 144, i_idx_cur + j, 3)
								jmp7 = sqlite3_vdbe_add_op3(v, 54, 3, 0, r1 + int(p_idx.nColumn) - 1)
								0
								sqlite3_vdbe_load_string(v, 3, c'rowid not at end-of-record for row ')
								sqlite3_vdbe_add_op3(v, 112, 7, 3, 3)
								sqlite3_vdbe_load_string(v, 4, c' of index ')
								sqlite3_vdbe_goto(v, jmp5 - 1)
								sqlite3_vdbe_jump_here(v, jmp7)
							}
							label6 = 0
							for kk = 0; kk < int(p_idx.nKeyCol); kk++ {
								if usize(p_idx.azColl[kk]) == usize(unsafe { &sqlite3StrBINARY[0] }) {
									continue
								}
								if label6 == 0 {
									label6 = sqlite3_vdbe_make_label(p_parse)
								}
								sqlite3_vdbe_add_op3(v, 96, i_idx_cur + j, kk, 3)
								sqlite3_vdbe_add_op3(v, 53, 3, label6, r1 + kk)
								0
							}
							if label6 {
								jmp6 := sqlite3_vdbe_add_op0(v, 9)
								sqlite3_vdbe_resolve_label(v, label6)
								sqlite3_vdbe_load_string(v, 3, c'row ')
								sqlite3_vdbe_add_op3(v, 112, 7, 3, 3)
								sqlite3_vdbe_load_string(v, 4, c' values differ from index ')
								sqlite3_vdbe_goto(v, jmp5 - 1)
								sqlite3_vdbe_jump_here(v, jmp6)
							}
							if (int(p_idx.onError) != 0) {
								uniq_ok := sqlite3_vdbe_make_label(p_parse)
								jmp6 := 0
								for kk = 0; kk < int(p_idx.nKeyCol); kk++ {
									i_col := int(p_idx.aiColumn[kk])
									if i_col >= 0 && int(p_tab.aCol[i_col].notNull) {
										continue
									}
									sqlite3_vdbe_add_op2(v, 51, r1 + kk, uniq_ok)
									0
								}
								jmp6 = sqlite3_vdbe_add_op1(v, 40, i_idx_cur + j)
								0
								sqlite3_vdbe_goto(v, uniq_ok)
								sqlite3_vdbe_jump_here(v, jmp6)
								sqlite3_vdbe_add_op4_int(v, 42, i_idx_cur + j, uniq_ok, r1, int(p_idx.nKeyCol))
								0
								sqlite3_vdbe_load_string(v, 3, c'non-unique entry in index ')
								sqlite3_vdbe_goto(v, jmp5)
								sqlite3_vdbe_resolve_label(v, uniq_ok)
							}
							sqlite3_vdbe_jump_here(v, jmp4)
							sqlite3_resolve_part_idx_label(p_parse, jmp3)
							c2v_for_next_133:
							p_idx = p_idx.pNext
							j++
						}
					}
					sqlite3_vdbe_add_op2(v, 40, i_data_cur, loop_top)
					0
					sqlite3_vdbe_jump_here(v, loop_top - 1)
					if p_pk {
						sqlite3_release_temp_range(p_parse, r2, int(p_pk.nKeyCol))
					}
				}
				for x = p_tbls.first; x; x = x.next {
					p_tab := &Table(x.data)
					pvt_ab := &Sqlite3_vtab(0)
					a1 := 0
					if table_skip_integrity_check(p_tab, p_obj_tab) {
						continue
					}
					if (int(p_tab.eTabType) == 0) {
						continue
					}
					if !(int(p_tab.eTabType) == 1) {
						continue
					}
					if int(p_tab.nCol) <= 0 {
						z_mod := p_tab.u.vtab.azArg[0]
						if usize(sqlite3_hash_find(&db.aModule, z_mod)) == usize(0) {
							continue
						}
					}
					sqlite3_view_get_column_names(p_parse, p_tab)
					if usize(p_tab.u.vtab.p) == usize(0) {
						continue
					}
					pvt_ab = p_tab.u.vtab.p.pVtab
					if (usize(pvt_ab) == usize(0)) {
						continue
					}
					if (usize(pvt_ab.pModule) == usize(0)) {
						continue
					}
					if pvt_ab.pModule.iVersion < 4 {
						continue
					}
					if isnil(pvt_ab.pModule.xIntegrity) {
						continue
					}
					sqlite3_vdbe_add_op3(v, 176, i, 3, is_quick)
					p_tab.nTabRef++
					sqlite3_vdbe_append_p4(v, voidptr(p_tab), (-17))
					a1 = sqlite3_vdbe_add_op1(v, 51, 3)
					0
					integrity_check_result_row(v)
					sqlite3_vdbe_jump_here(v, a1)
					continue
				}
			}
			static i_ln := 0
			if !sqlite3_pragma_end_code_inited {
				c2v_static_init := [VdbeOpList{
					opcode: U8(88)
					p1: i8(1)
					p2: i8(0)
					p3: i8(0)
				}, VdbeOpList{
					opcode: U8(62)
					p1: i8(1)
					p2: i8(4)
					p3: i8(0)
				}, VdbeOpList{
					opcode: U8(118)
					p1: i8(0)
					p2: i8(3)
					p3: i8(0)
				}, VdbeOpList{
					opcode: U8(86)
					p1: i8(3)
					p2: i8(1)
					p3: i8(0)
				}, VdbeOpList{
					opcode: U8(72)
					p1: i8(0)
					p2: i8(0)
					p3: i8(0)
				}, VdbeOpList{
					opcode: U8(118)
					p1: i8(0)
					p2: i8(3)
					p3: i8(0)
				}, VdbeOpList{
					opcode: U8(9)
					p1: i8(0)
					p2: i8(3)
					p3: i8(0)
				}]
				for c2v_i_0, c2v_element_0 in c2v_static_init {
					sqlite3_pragma_end_code[c2v_i_0] = c2v_element_0
				}
				sqlite3_pragma_end_code_inited = true
			}

			mut a_op := &VdbeOp(0)
			a_op = sqlite3_vdbe_add_op_list(v, 7, &sqlite3_pragma_end_code[0], i_ln)
			if a_op {
				a_op[0].p2 = 1 - mx_err
				a_op[2].p4type = i8((-1))
				a_op[2].p4.z = c'ok'
				a_op[5].p4type = i8((-1))
				a_op[5].p4.z = &i8(sqlite3_err_str(11))
			}
			sqlite3_vdbe_change_p3(v, 0, sqlite3_vdbe_current_addr(v) - 2)
		}
		14 {
			if !sqlite3_pragma_encnames_inited {
				c2v_static_init := [EncName{
					zName: c'UTF8'
					enc: U8(1)
				}, EncName{
					zName: c'UTF-8'
					enc: U8(1)
				}, EncName{
					zName: c'UTF-16le'
					enc: U8(2)
				}, EncName{
					zName: c'UTF-16be'
					enc: U8(3)
				}, EncName{
					zName: c'UTF16le'
					enc: U8(2)
				}, EncName{
					zName: c'UTF16be'
					enc: U8(3)
				}, EncName{
					zName: c'UTF-16'
					enc: U8(0)
				}, EncName{
					zName: c'UTF16'
					enc: U8(0)
				}, EncName{}]
				for c2v_i_0, c2v_element_0 in c2v_static_init {
					sqlite3_pragma_encnames[c2v_i_0] = c2v_element_0
				}
				sqlite3_pragma_encnames_inited = true
			}

			p_enc := &EncName(0)
			if isnil(z_right) {
				if sqlite3_read_schema(p_parse) {
					unsafe { goto pragma_out
					 }
				}
				return_single_text(v, sqlite3_pragma_encnames[p_parse.db.enc].zName)
			} else {
				if (db.mDbFlags & u32(64)) == u32(0) {
					for p_enc = unsafe { &sqlite3_pragma_encnames[0] + 0 }; p_enc.zName; p_enc = unsafe { p_enc + 1 } {
						if 0 == sqlite3_str_ic_mp(z_right, p_enc.zName) {
							enc := U8(if int(p_enc.enc) { int(p_enc.enc) } else { 2 })
							db.aDb[0].pSchema.enc = enc
							sqlite3_set_text_encoding(db, enc)
							break
						}
					}
					if isnil(p_enc.zName) {
						sqlite3_error_msg(p_parse, c'unsupported encoding: %s', voidptr(z_right))
					}
				}
			}
		}
		2 {
			i_cookie := int(p_pragma.iArg)
			sqlite3_vdbe_uses_btree(v, i_db)
			if !isnil(z_right) && (int(p_pragma.mPragFlg) & 8) == 0 {
				if !sqlite3_pragma_set_cookie_inited {
					c2v_static_init := [VdbeOpList{
						opcode: U8(2)
						p1: i8(0)
						p2: i8(1)
						p3: i8(0)
					}, VdbeOpList{
						opcode: U8(102)
						p1: i8(0)
						p2: i8(0)
						p3: i8(0)
					}]
					for c2v_i_0, c2v_element_0 in c2v_static_init {
						sqlite3_pragma_set_cookie[c2v_i_0] = c2v_element_0
					}
					sqlite3_pragma_set_cookie_inited = true
				}

				mut a_op := &VdbeOp(0)
				0
				a_op = sqlite3_vdbe_add_op_list(v, 2, &sqlite3_pragma_set_cookie[0], 0)
				if 0 {
					unsafe { goto c2v_switch_end_51
					 }
				}
				a_op[0].p1 = i_db
				a_op[1].p1 = i_db
				a_op[1].p2 = i_cookie
				a_op[1].p3 = sqlite3_atoi(z_right)
				a_op[1].p5 = U16(1)
				if i_cookie == 1 && (db.flags & U64(268435456)) != U64(0) {
					a_op[1].opcode = U8(189)
				}
			} else {
				if !sqlite3_pragma_read_cookie_inited {
					c2v_static_init := [VdbeOpList{
						opcode: U8(2)
						p1: i8(0)
						p2: i8(0)
						p3: i8(0)
					}, VdbeOpList{
						opcode: U8(101)
						p1: i8(0)
						p2: i8(1)
						p3: i8(0)
					}, VdbeOpList{
						opcode: U8(86)
						p1: i8(1)
						p2: i8(1)
						p3: i8(0)
					}]
					for c2v_i_0, c2v_element_0 in c2v_static_init {
						sqlite3_pragma_read_cookie[c2v_i_0] = c2v_element_0
					}
					sqlite3_pragma_read_cookie_inited = true
				}

				mut a_op := &VdbeOp(0)
				0
				a_op = sqlite3_vdbe_add_op_list(v, 3, &sqlite3_pragma_read_cookie[0], 0)
				if 0 {
					unsafe { goto c2v_switch_end_51
					 }
				}
				a_op[0].p1 = i_db
				a_op[1].p1 = i_db
				a_op[1].p3 = i_cookie
				sqlite3_vdbe_reusable(v)
			}
		}
		10 {
			i := 0
			z_opt := &i8(0)
			p_parse.nMem = 1
			for {
				z_opt = sqlite3_compileoption_get(i++)
				if !(usize(z_opt) != usize(0)) {
					break
				}
				sqlite3_vdbe_load_string(v, 1, z_opt)
				sqlite3_vdbe_add_op2(v, 86, 1, 1)
			}
			sqlite3_vdbe_reusable(v)
		}
		43 {
			i_bt := (if p_id2.z { i_db } else { (10 + 2) })
			e_mode := 0
			if z_right {
				if sqlite3_str_ic_mp(z_right, c'full') == 0 {
					e_mode = 1
				} else if sqlite3_str_ic_mp(z_right, c'restart') == 0 {
					e_mode = 2
				} else if sqlite3_str_ic_mp(z_right, c'truncate') == 0 {
					e_mode = 3
				} else if sqlite3_str_ic_mp(z_right, c'noop') == 0 {
					e_mode = -1
				}
			}
			p_parse.nMem = 3
			sqlite3_vdbe_add_op3(v, 3, i_bt, e_mode, 1)
			sqlite3_vdbe_add_op2(v, 86, 1, 3)
		}
		42 {
			if z_right {
				sqlite3_wal_autocheckpoint(db, sqlite3_atoi(z_right))
			}
			return_single_int(v, I64(if db.xWalCallback == sqlite3_wal_default_hook {
				(int(i64(db.pWalArg)))
			} else {
				0
			}))
		}
		34 {
			sqlite3_db_release_memory(db)
		}
		30 {
			i_db_last := 0
			i_tab_cur := 0
			k := &HashElem(0)
			p_schema := &Schema(0)
			p_tab := &Table(0)
			p_idx := &Index(0)
			sz_threshold := LogEst(0)
			z_sub_sql := &i8(0)
			op_mask := u32(0)
			n_limit := 0
			n_check := 0
			n_btree := 0
			n_index := 0
			if z_right {
				op_mask = u32(sqlite3_atoi(z_right))
				if (op_mask & u32(2)) == u32(0) {
					unsafe { goto c2v_switch_end_51
					 }
				}
			} else {
				op_mask = u32(65534)
			}
			if (op_mask & u32(16)) == u32(0) {
				n_limit = 0
			} else if db.nAnalysisLimit > 0 && db.nAnalysisLimit < 2000 {
				n_limit = 0
			} else {
				n_limit = 2000
			}
			mut __c2v_postfix_value_23 := p_parse.nTab
			p_parse.nTab++
			i_tab_cur = __c2v_postfix_value_23
			i_db_last = if z_db { i_db } else { db.nDb - 1 }
			for i_db <= i_db_last {
				if i_db == 1 {
					unsafe { goto c2v_for_next_134
					 }
				}
				sqlite3_code_verify_schema(p_parse, i_db)
				p_schema = db.aDb[i_db].pSchema
				for k = p_schema.tblHash.first; k; k = k.next {
					p_tab = &Table(k.data)
					if !(int(p_tab.eTabType) == 0) {
						continue
					}
					if 0 == sqlite3_strnicmp(p_tab.zName, c'sqlite_', 7) {
						continue
					}
					sz_threshold = p_tab.nRowLogEst
					n_index = 0
					for p_idx = p_tab.pIndex; p_idx; p_idx = p_idx.pNext {
						n_index++
						if !p_idx.hasStat1 {
							sz_threshold = LogEst(-1)
						}
					}
					if (p_tab.tabFlags & u32(256)) != u32(0) {
					} else if op_mask & u32(65536) {
					} else if usize(p_tab.pIndex) != usize(0) && int(sz_threshold) < 0 {
					} else {
						continue
					}
					n_check++
					if n_check == 2 {
						sqlite3_begin_write_operation(p_parse, 0, i_db)
					}
					n_btree += n_index + 1
					sqlite3_open_table(p_parse, i_tab_cur, i_db, p_tab, 114)
					if int(sz_threshold) >= 0 {
						i_range := LogEst(33)
						sqlite3_vdbe_add_op4_int(v, 33, i_tab_cur, int(u32(sqlite3_vdbe_current_addr(v) + 2) + (op_mask & u32(1))), if int(sz_threshold) >= int(i_range) {
							int(sz_threshold) - int(i_range)
						} else {
							-1
						}, int(sz_threshold) + int(i_range))
						0
					} else {
						sqlite3_vdbe_add_op2(v, 36, i_tab_cur, int(u32(sqlite3_vdbe_current_addr(v) + 2) + (op_mask & u32(1))))
						0
					}
					z_sub_sql = sqlite3_mp_rintf(db, c'ANALYZE "%w"."%w"', voidptr(db.aDb[i_db].zDbSName), voidptr(p_tab.zName))
					if op_mask & u32(1) {
						r1 := sqlite3_get_temp_reg(p_parse)
						sqlite3_vdbe_add_op4(v, 118, 0, r1, 0, z_sub_sql, (-7))
						sqlite3_vdbe_add_op2(v, 86, r1, 1)
					} else {
						sqlite3_vdbe_add_op4(v, 150, if n_limit { 2 } else { 0 }, n_limit, 0, z_sub_sql, (-7))
					}
				}
				c2v_for_next_134:
				i_db++
			}
			sqlite3_vdbe_add_op0(v, 168)
			if !db.mallocFailed && n_limit > 0 && n_btree > 100 {
				i_addr := 0
				i_end := 0

				mut a_op := &VdbeOp(0)
				n_limit = 100 * n_limit / n_btree
				if n_limit < 100 {
					n_limit = 100
				}
				a_op = sqlite3_vdbe_get_op(v, 0)
				i_end = sqlite3_vdbe_current_addr(v)
				for i_addr = 0; i_addr < i_end; i_addr++ {
					if int(a_op[i_addr].opcode) == 150 {
						a_op[i_addr].p2 = n_limit
					}
				}
			}
		}
		35 {
			n := Sqlite3_int64(0)
			if !isnil(z_right) && sqlite3_dec_or_hex_to_i64(z_right, unsafe { &I64(&n) }) == 0 {
				sqlite3_soft_heap_limit64(n)
			}
			return_single_int(v, sqlite3_soft_heap_limit64(Sqlite3_int64(-1)))
		}
		18 {
			n := Sqlite3_int64(0)
			if !isnil(z_right) && sqlite3_dec_or_hex_to_i64(z_right, unsafe { &I64(&n) }) == 0 {
				i_prior := sqlite3_hard_heap_limit64(Sqlite3_int64(-1))
				if n > Sqlite3_int64(0) && (i_prior == Sqlite3_int64(0) || i_prior > n) {
					sqlite3_hard_heap_limit64(n)
				}
			}
			return_single_int(v, sqlite3_hard_heap_limit64(Sqlite3_int64(-1)))
		}
		41 {
			n := Sqlite3_int64(0)
			if !isnil(z_right) && sqlite3_dec_or_hex_to_i64(z_right, unsafe { &I64(&n) }) == 0 && n >= Sqlite3_int64(0) {
				sqlite3_limit(db, 11, int((n & Sqlite3_int64(2147483647))))
			}
			return_single_int(v, I64(sqlite3_limit(db, 11, -1)))
		}
		1 {
			n := Sqlite3_int64(0)
			if !isnil(z_right) && sqlite3_dec_or_hex_to_i64(z_right, unsafe { &I64(&n) }) == 0 && n >= Sqlite3_int64(0) {
				db.nAnalysisLimit = int((n & Sqlite3_int64(2147483647)))
			}
			return_single_int(v, I64(db.nAnalysisLimit))
		}
		else {
			if z_right {
				sqlite3_busy_timeout(db, sqlite3_atoi(z_right))
			}
			return_single_int(v, I64(db.busyTimeout))
		}
	}
	c2v_switch_end_51:

	if (int(p_pragma.mPragFlg) & 4) && !isnil(z_right) {
		0
	}
	pragma_out:
	sqlite3_db_free(db, voidptr(z_left))
	sqlite3_db_free(db, voidptr(z_right))
}

struct PragmaVtab {
	base    Sqlite3_vtab
	db      &Sqlite3
	pName   &PragmaName
	nHidden U8
	iHidden U8
}

struct PragmaVtabCursor {
	base    Sqlite3_vtab_cursor
	pPragma &Sqlite3_stmt
	iRowid  Sqlite_int64
	azArg   [2]&i8
}

@[c:'pragmaVtabConnect']
fn pragma_vtab_connect(db &Sqlite3, p_aux voidptr, argc int, argv &&u8, pp_vtab &&Sqlite3_vtab, pz_err &&u8) int {
	c2v_gc_register_thread()
	p_pragma := &PragmaName(p_aux)
	p_tab := unsafe { &PragmaVtab(nil) }
	rc := 0
	i := 0
	j := 0

	c_sep := i8(`(`)
	acc := StrAccum{}
	z_buf := [200]i8{}

	sqlite3_str_accum_init(&acc, unsafe { nil }, unsafe { &i8(&z_buf[0]) }, int(sizeof([200]i8)), 0)
	sqlite3_str_appendall(unsafe { &Sqlite3_str(&acc) }, c'CREATE TABLE x')
	i = 0
	for j = int(p_pragma.iPragCName); i < int(p_pragma.nPragCName); i++ {
		sqlite3_str_appendf(unsafe { &Sqlite3_str(&acc) }, c'%c"%s"', int(c_sep), voidptr(pragCName[j]))
		c_sep = i8(`,`)
		j++
	}
	if i == 0 {
		sqlite3_str_appendf(unsafe { &Sqlite3_str(&acc) }, c'("%s"', voidptr(p_pragma.zName))
		i++
	}
	j = 0
	if int(p_pragma.mPragFlg) & 32 {
		sqlite3_str_appendall(unsafe { &Sqlite3_str(&acc) }, c',arg HIDDEN')
		j++
	}
	if int(p_pragma.mPragFlg) & (64 | 128) {
		sqlite3_str_appendall(unsafe { &Sqlite3_str(&acc) }, c',schema HIDDEN')
		j++
	}
	sqlite3_str_append(unsafe { &Sqlite3_str(&acc) }, c')', 1)
	sqlite3_str_accum_finish(&acc)
	rc = sqlite3_declare_vtab(db, unsafe { &i8(&z_buf[0]) })
	if rc == 0 {
		p_tab = &PragmaVtab(sqlite3_malloc(int(sizeof(PragmaVtab))))
		if usize(p_tab) == usize(0) {
			rc = 7
		} else {
			C.memset(voidptr(p_tab), 0, sizeof(PragmaVtab))
			p_tab.pName = p_pragma
			p_tab.db = db
			p_tab.iHidden = U8(i)
			p_tab.nHidden = U8(j)
		}
	} else {
		unsafe { *pz_err = sqlite3_mprintf(c'%s', voidptr(sqlite3_errmsg(db))) }
	}
	unsafe { *pp_vtab = &Sqlite3_vtab(voidptr(p_tab)) }
	return rc
}

@[c:'pragmaVtabDisconnect']
fn pragma_vtab_disconnect(p_vtab &Sqlite3_vtab) int {
	c2v_gc_register_thread()
	p_tab := &PragmaVtab(voidptr(p_vtab))
	sqlite3_free(voidptr(p_tab))
	return 0
}

@[c:'pragmaVtabBestIndex']
fn pragma_vtab_best_index(tab &Sqlite3_vtab, p_idx_info &Sqlite3_index_info) int {
	c2v_gc_register_thread()
	p_tab := &PragmaVtab(voidptr(tab))
	p_constraint := &Sqlite3_index_constraint(0)
	i := 0
	j := 0

	seen := [2]int{}
	p_idx_info.estimatedCost = f64(1)
	if int(p_tab.nHidden) == 0 {
		return 0
	}
	p_constraint = p_idx_info.aConstraint
	seen[0] = 0
	seen[1] = 0
	for i = 0; i < p_idx_info.nConstraint; i++ {
		if p_constraint.iColumn < int(p_tab.iHidden) {
			unsafe { goto c2v_for_next_136
			 }
		}
		if int(p_constraint.op) != 2 {
			unsafe { goto c2v_for_next_136
			 }
		}
		if int(p_constraint.usable) == 0 {
			return 19
		}
		j = p_constraint.iColumn - int(p_tab.iHidden)
		seen[j] = i + 1
		c2v_for_next_136:
		c2v_pointer_postfix(voidptr(&p_constraint), p_constraint, isize(1))
	}
	if seen[0] == 0 {
		p_idx_info.estimatedCost = f64(2147483647)
		p_idx_info.estimatedRows = Sqlite3_int64(2147483647)
		return 0
	}
	j = seen[0] - 1
	p_idx_info.aConstraintUsage[j].argvIndex = 1
	p_idx_info.aConstraintUsage[j].omit = u8(1)
	p_idx_info.estimatedCost = f64(20)
	p_idx_info.estimatedRows = Sqlite3_int64(20)
	if seen[1] {
		j = seen[1] - 1
		p_idx_info.aConstraintUsage[j].argvIndex = 2
		p_idx_info.aConstraintUsage[j].omit = u8(1)
	}
	return 0
}

@[c:'pragmaVtabOpen']
fn pragma_vtab_open(p_vtab &Sqlite3_vtab, pp_cursor &&Sqlite3_vtab_cursor) int {
	c2v_gc_register_thread()
	p_csr := &PragmaVtabCursor(0)
	p_csr = &PragmaVtabCursor(sqlite3_malloc(int(sizeof(PragmaVtabCursor))))
	if usize(p_csr) == usize(0) {
		return 7
	}
	C.memset(voidptr(p_csr), 0, sizeof(PragmaVtabCursor))
	p_csr.base.pVtab = p_vtab
	unsafe { *pp_cursor = &p_csr.base }
	return 0
}

@[c:'pragmaVtabCursorClear']
fn pragma_vtab_cursor_clear(p_csr &PragmaVtabCursor) {
	i := 0
	sqlite3_finalize(p_csr.pPragma)
	p_csr.pPragma = 0
	p_csr.iRowid = Sqlite_int64(0)
	for i = 0; i < 2; i++ {
		sqlite3_free(voidptr(p_csr.azArg[i]))
		p_csr.azArg[i] = 0
	}
}

@[c:'pragmaVtabClose']
fn pragma_vtab_close(cur &Sqlite3_vtab_cursor) int {
	c2v_gc_register_thread()
	p_csr := &PragmaVtabCursor(voidptr(cur))
	pragma_vtab_cursor_clear(p_csr)
	sqlite3_free(voidptr(p_csr))
	return 0
}

@[c:'pragmaVtabNext']
fn pragma_vtab_next(p_vtab_cursor &Sqlite3_vtab_cursor) int {
	c2v_gc_register_thread()
	p_csr := &PragmaVtabCursor(voidptr(p_vtab_cursor))
	rc := 0
	p_csr.iRowid++
	if 100 != sqlite3_step(p_csr.pPragma) {
		rc = sqlite3_finalize(p_csr.pPragma)
		p_csr.pPragma = 0
		pragma_vtab_cursor_clear(p_csr)
	}
	return rc
}

@[c:'pragmaVtabFilter']
fn pragma_vtab_filter(p_vtab_cursor &Sqlite3_vtab_cursor, idx_num int, idx_str &i8, argc int, argv &&Sqlite3_value) int {
	c2v_gc_register_thread()
	p_csr := &PragmaVtabCursor(voidptr(p_vtab_cursor))
	p_tab := &PragmaVtab(voidptr(p_vtab_cursor.pVtab))
	rc := 0
	i := 0
	j := 0

	acc := StrAccum{}
	z_sql := &i8(0)

	pragma_vtab_cursor_clear(p_csr)
	j = if (int(p_tab.pName.mPragFlg) & 32) != 0 { 0 } else { 1 }
	for i = 0; i < argc; i++ {
		z_text := &i8(voidptr(sqlite3_value_text(argv[i])))
		if z_text {
			p_csr.azArg[j] = sqlite3_mprintf(c'%s', voidptr(z_text))
			if usize(p_csr.azArg[j]) == usize(0) {
				return 7
			}
		}
		j++
	}
	sqlite3_str_accum_init(&acc, unsafe { nil }, unsafe { nil }, 0, p_tab.db.aLimit[1])
	sqlite3_str_appendall(unsafe { &Sqlite3_str(&acc) }, c'PRAGMA ')
	if p_csr.azArg[1] {
		sqlite3_str_appendf(unsafe { &Sqlite3_str(&acc) }, c'%Q.', voidptr(p_csr.azArg[1]))
	}
	sqlite3_str_appendall(unsafe { &Sqlite3_str(&acc) }, p_tab.pName.zName)
	if p_csr.azArg[0] {
		sqlite3_str_appendf(unsafe { &Sqlite3_str(&acc) }, c'=%Q', voidptr(p_csr.azArg[0]))
	}
	z_sql = sqlite3_str_accum_finish(&acc)
	if usize(z_sql) == usize(0) {
		return 7
	}
	rc = sqlite3_prepare_v2(p_tab.db, z_sql, -1, &&Sqlite3_stmt(&p_csr.pPragma), unsafe { &&u8(nil) })
	sqlite3_free(voidptr(z_sql))
	if rc != 0 {
		p_tab.base.zErrMsg = sqlite3_mprintf(c'%s', voidptr(sqlite3_errmsg(p_tab.db)))
		return rc
	}
	return pragma_vtab_next(p_vtab_cursor)
}

@[c:'pragmaVtabEof']
fn pragma_vtab_eof(p_vtab_cursor &Sqlite3_vtab_cursor) int {
	c2v_gc_register_thread()
	p_csr := &PragmaVtabCursor(voidptr(p_vtab_cursor))
	return int((usize(p_csr.pPragma) == usize(0)))
}

@[c:'pragmaVtabColumn']
fn pragma_vtab_column(p_vtab_cursor &Sqlite3_vtab_cursor, ctx &Sqlite3_context, i int) int {
	c2v_gc_register_thread()
	p_csr := &PragmaVtabCursor(voidptr(p_vtab_cursor))
	p_tab := &PragmaVtab(voidptr(p_vtab_cursor.pVtab))
	if i < int(p_tab.iHidden) {
		sqlite3_result_value(ctx, sqlite3_column_value(p_csr.pPragma, i))
	} else {
		sqlite3_result_text(ctx, p_csr.azArg[i - int(p_tab.iHidden)], -1, (C2vFn_666e2028766f696470747229(voidptr(-1))))
	}
	return 0
}

@[c:'pragmaVtabRowid']
fn pragma_vtab_rowid(p_vtab_cursor &Sqlite3_vtab_cursor, p &Sqlite_int64) int {
	c2v_gc_register_thread()
	p_csr := &PragmaVtabCursor(voidptr(p_vtab_cursor))
	unsafe { *p = p_csr.iRowid }
	return 0
}

@[c:'sqlite3PragmaVtabRegister']
fn sqlite3_pragma_vtab_register(db &Sqlite3, z_name &i8) &Module {
	p_name := &PragmaName(0)
	p_name = pragma_locate(z_name + 7)
	if usize(p_name) == usize(0) {
		return unsafe { nil }
	}
	if (int(p_name.mPragFlg) & (16 | 32)) == 0 {
		return unsafe { nil }
	}
	return sqlite3_vtab_create_module(db, z_name, &pragmaVtabModule, voidptr(p_name), unsafe { nil })
}
