@[translated]
module main

@[c:'sqlite3SrcListLookup']
fn sqlite3_src_list_lookup(p_parse &Parse, p_src &SrcList) &Table {
	p_item := unsafe { &SrcItem(&p_src.a[0]) }
	p_tab := &Table(0)
	p_tab = sqlite3_locate_table_item(p_parse, u32(0), p_item)
	if p_item.pSTab {
		sqlite3_delete_table(p_parse.db, p_item.pSTab)
	}
	p_item.pSTab = p_tab
	p_item.fg.notCte = u32(1)
	if p_tab {
		p_tab.nTabRef++
		if int(p_item.fg.isIndexedBy) && sqlite3_indexed_by_lookup(p_parse, p_item) {
			p_tab = 0
		}
	}
	return p_tab
}

@[c:'sqlite3CodeChangeCount']
fn sqlite3_code_change_count(v &Vdbe, reg_counter int, z_col_name &i8) {
	sqlite3_vdbe_add_op0(v, 85)
	sqlite3_vdbe_add_op2(v, 86, reg_counter, 1)
	sqlite3_vdbe_set_num_cols(v, 1)
	sqlite3_vdbe_set_col_name(v, 0, 0, z_col_name, (C2vFn_666e2028766f696470747229(voidptr(0))))
}

@[c:'vtabIsReadOnly']
fn vtab_is_read_only(p_parse &Parse, p_tab &Table) int {
	if isnil(sqlite3_get_vt_able(p_parse.db, p_tab).pMod.pModule.xUpdate) {
		return 1
	}
	if (usize(p_parse.pToplevel) != usize(0) || (int(p_parse.prepFlags) & 32)) && int(p_tab.u.vtab.p.eVtabRisk) > ((p_parse.db.flags & U64(128)) != U64(0)) {
		sqlite3_error_msg(p_parse, c'unsafe use of virtual table "%s"', voidptr(p_tab.zName))
	}
	return 0
}

@[c:'tabIsReadOnly']
fn tab_is_read_only(p_parse &Parse, p_tab &Table) int {
	db := &Sqlite3(0)
	if (int(p_tab.eTabType) == 1) {
		return vtab_is_read_only(p_parse, p_tab)
	}
	if (p_tab.tabFlags & u32((1 | 4096))) == u32(0) {
		return 0
	}
	db = p_parse.db
	if (p_tab.tabFlags & u32(1)) != u32(0) {
		return int(sqlite3_writable_schema(db) == 0 && int(p_parse.nested) == 0)
	}
	return sqlite3_read_only_shadow_tables(db)
}

@[c:'sqlite3IsReadOnly']
fn sqlite3_is_read_only(p_parse &Parse, p_tab &Table, p_trigger &Trigger) int {
	if tab_is_read_only(p_parse, p_tab) {
		sqlite3_error_msg(p_parse, c'table %s may not be modified', voidptr(p_tab.zName))
		return 1
	}
	if (int(p_tab.eTabType) == 2) && (usize(p_trigger) == usize(0) || (int(p_trigger.bReturning) && usize(p_trigger.pNext) == usize(0))) {
		sqlite3_error_msg(p_parse, c'cannot modify %s because it is a view', voidptr(p_tab.zName))
		return 1
	}
	return 0
}

@[c:'sqlite3MaterializeView']
fn sqlite3_materialize_view(p_parse &Parse, p_view &Table, p_where &Expr, p_order_by &ExprList, p_limit &Expr, i_cur int) {
	dest := SelectDest{}
	p_sel := &Select(0)
	p_from := &SrcList(0)
	db := p_parse.db
	i_db := sqlite3_schema_to_index(db, p_view.pSchema)
	p_where = sqlite3_expr_dup(db, p_where, 0)
	p_from = sqlite3_src_list_append(p_parse, unsafe { nil }, unsafe { nil }, unsafe { nil })
	if p_from {
		mut __c2v_lhs_tmp_116 := c2v_at(&p_from.a[0], isize(0))
		__c2v_lhs_tmp_116.zName = sqlite3_db_str_dup(db, p_view.zName)
		mut __c2v_lhs_tmp_117 := c2v_at(&p_from.a[0], isize(0))
		__c2v_lhs_tmp_117.u4.zDatabase = sqlite3_db_str_dup(db, db.aDb[i_db].zDbSName)
	}
	p_sel = sqlite3_select_new(p_parse, unsafe { nil }, p_from, p_where, unsafe { nil }, unsafe { nil }, p_order_by, u32(131072), p_limit)
	sqlite3_select_dest_init(&dest, 10, i_cur)
	sqlite3_select(p_parse, p_sel, &dest)
	sqlite3_select_delete(db, p_sel)
}

@[c:'sqlite3DeleteFrom']
fn sqlite3_delete_from(p_parse &Parse, p_tab_list &SrcList, p_where &Expr, p_order_by &ExprList, p_limit &Expr) {
	v := &Vdbe(0)
	p_tab := &Table(0)
	i := 0
	pwi_nfo := &WhereInfo(0)
	p_idx := &Index(0)
	i_tab_cur := 0
	i_data_cur := 0
	i_idx_cur := 0
	n_idx := 0
	db := &Sqlite3(0)
	s_context := AuthContext{}
	snc := NameContext{}
	i_db := 0
	mem_cnt := 0
	rcauth := 0
	e_one_pass := 0
	ai_cur_one_pass := [2]int{}
	a_to_open := unsafe { &U8(nil) }
	p_pk := &Index(0)
	i_pk := 0
	n_pk := I16(1)
	i_key := 0
	n_key := I16(0)
	i_eph_cur := 0
	i_row_set := 0
	addr_bypass := 0
	addr_loop := 0
	addr_eph_open := 0
	b_complex := 0
	is_view := 0
	p_trigger := &Trigger(0)
	C.memset(voidptr(&s_context), 0, sizeof(s_context))
	db = p_parse.db
	if p_parse.nErr {
		unsafe { goto delete_from_cleanup
		 }
	}
	p_tab = sqlite3_src_list_lookup(p_parse, p_tab_list)
	if usize(p_tab) == usize(0) {
		unsafe { goto delete_from_cleanup
		 }
	}
	p_trigger = sqlite3_triggers_exist(p_parse, p_tab, 129, unsafe { nil }, unsafe { nil })
	is_view = (int(p_tab.eTabType) == 2)
	b_complex = !isnil(p_trigger) || sqlite3_fk_required(p_parse, p_tab, unsafe { nil }, 0)
	if sqlite3_view_get_column_names(p_parse, p_tab) {
		unsafe { goto delete_from_cleanup
		 }
	}
	if sqlite3_is_read_only(p_parse, p_tab, p_trigger) {
		unsafe { goto delete_from_cleanup
		 }
	}
	i_db = sqlite3_schema_to_index(db, p_tab.pSchema)
	rcauth = sqlite3_auth_check(p_parse, 9, p_tab.zName, unsafe { nil }, db.aDb[i_db].zDbSName)
	if rcauth == 1 {
		unsafe { goto delete_from_cleanup
		 }
	}
	mut __c2v_postfix_value_15 := p_parse.nTab
	p_parse.nTab++
	mut __c2v_lhs_tmp_118 := c2v_at(&p_tab_list.a[0], isize(0))
	__c2v_lhs_tmp_118.iCursor = __c2v_postfix_value_15
	i_tab_cur = c2v_at(&p_tab_list.a[0], isize(0)).iCursor
	n_idx = 0
	for p_idx = p_tab.pIndex; p_idx;  {
		p_parse.nTab++
		p_idx = p_idx.pNext
		n_idx++
	}
	if is_view {
		sqlite3_auth_context_push(p_parse, &s_context, p_tab.zName)
	}
	v = sqlite3_get_vdbe(p_parse)
	if usize(v) == usize(0) {
		unsafe { goto delete_from_cleanup
		 }
	}
	if int(p_parse.nested) == 0 {
		sqlite3_vdbe_count_changes(v)
	}
	sqlite3_begin_write_operation(p_parse, b_complex, i_db)
	if is_view {
		sqlite3_materialize_view(p_parse, p_tab, p_where, p_order_by, p_limit, i_tab_cur)
		i_idx_cur = i_tab_cur
		i_data_cur = i_idx_cur
		p_order_by = 0
		p_limit = 0
	}
	C.memset(voidptr(&snc), 0, sizeof(snc))
	snc.pParse = p_parse
	snc.pSrcList = p_tab_list
	if sqlite3_resolve_expr_names(&snc, p_where) {
		unsafe { goto delete_from_cleanup
		 }
	}
	if (db.flags & (U64(1) << 32)) != U64(0) && !p_parse.nested && isnil(p_parse.pTriggerTab) && !p_parse.bReturning {
		mem_cnt = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		sqlite3_vdbe_add_op2(v, 73, 0, mem_cnt)
	}
	if rcauth == 0 && usize(p_where) == usize(0) && !b_complex && !(int(p_tab.eTabType) == 1) {
		sqlite3_table_lock(p_parse, i_db, p_tab.tnum, U8(1), p_tab.zName)
		if ((p_tab.tabFlags & u32(128)) == u32(0)) {
			sqlite3_vdbe_add_op4(v, 147, int(p_tab.tnum), i_db, if mem_cnt { mem_cnt } else { -1 }, p_tab.zName, (-1))
		}
		for p_idx = p_tab.pIndex; p_idx; p_idx = p_idx.pNext {
			if (int(p_idx.idxType) == 2) && !((p_tab.tabFlags & u32(128)) == u32(0)) {
				sqlite3_vdbe_add_op3(v, 147, int(p_idx.tnum), i_db, if mem_cnt { mem_cnt } else { -1 })
			} else {
				sqlite3_vdbe_add_op2(v, 147, int(p_idx.tnum), i_db)
			}
		}
	} else {
		wcf := U16(4 | 16)
		if snc.ncFlags & 64 {
			b_complex = 1
		}
		wcf |= (if b_complex { 0 } else { 8 })
		if ((p_tab.tabFlags & u32(128)) == u32(0)) {
			p_pk = 0
			i_row_set = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			sqlite3_vdbe_add_op2(v, 77, 0, i_row_set)
		} else {
			p_pk = sqlite3_primary_key_index(p_tab)
			n_pk = I16(p_pk.nKeyCol)
			i_pk = p_parse.nMem + 1
			p_parse.nMem += int(n_pk)
			mut __c2v_postfix_value_16 := p_parse.nTab
			p_parse.nTab++
			i_eph_cur = __c2v_postfix_value_16
			addr_eph_open = sqlite3_vdbe_add_op2(v, 120, i_eph_cur, int(n_pk))
			sqlite3_vdbe_set_p4_key_info(p_parse, p_pk)
		}
		pwi_nfo = sqlite3_where_begin(p_parse, p_tab_list, p_where, unsafe { nil }, unsafe { nil }, unsafe { nil }, wcf, i_tab_cur + 1)
		if usize(pwi_nfo) == usize(0) {
			unsafe { goto delete_from_cleanup
			 }
		}
		e_one_pass = sqlite3_where_ok_one_pass(pwi_nfo, &ai_cur_one_pass[0])
		if e_one_pass != 1 {
			sqlite3_multi_write(p_parse)
		}
		if sqlite3_where_uses_deferred_seek(pwi_nfo) {
			sqlite3_vdbe_add_op1(v, 145, i_tab_cur)
		}
		if mem_cnt {
			sqlite3_vdbe_add_op2(v, 88, mem_cnt, 1)
		}
		if p_pk {
			for i = 0; i < int(n_pk); i++ {
				sqlite3_expr_code_get_column_of_table(v, p_tab, i_tab_cur, int(p_pk.aiColumn[i]), i_pk + i)
			}
			i_key = i_pk
		} else {
			i_key = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			sqlite3_expr_code_get_column_of_table(v, p_tab, i_tab_cur, -1, i_key)
		}
		if e_one_pass != 0 {
			n_key = n_pk
			a_to_open = sqlite3_db_malloc_raw_nn(db, U64(n_idx + 2))
			if usize(a_to_open) == usize(0) {
				sqlite3_where_end(pwi_nfo)
				unsafe { goto delete_from_cleanup
				 }
			}
			C.memset(voidptr(a_to_open), 1, u64(n_idx + 1))
			a_to_open[n_idx + 1] = U8(0)
			if ai_cur_one_pass[0] >= 0 {
				a_to_open[ai_cur_one_pass[0] - i_tab_cur] = U8(0)
			}
			if ai_cur_one_pass[1] >= 0 {
				a_to_open[ai_cur_one_pass[1] - i_tab_cur] = U8(0)
			}
			if addr_eph_open {
				sqlite3_vdbe_change_to_noop(v, addr_eph_open)
			}
			addr_bypass = sqlite3_vdbe_make_label(p_parse)
		} else {
			if p_pk {
				i_key = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
				n_key = I16(0)
				sqlite3_vdbe_add_op4(v, 99, i_pk, int(n_pk), i_key, sqlite3_index_affinity_str(p_parse.db, p_pk), int(n_pk))
				sqlite3_vdbe_add_op4_int(v, 140, i_eph_cur, i_key, i_pk, int(n_pk))
			} else {
				n_key = I16(1)
				sqlite3_vdbe_add_op2(v, 158, i_row_set, i_key)
			}
			sqlite3_where_end(pwi_nfo)
		}
		if !is_view {
			i_addr_once := 0
			if e_one_pass == 2 {
				i_addr_once = sqlite3_vdbe_add_op0(v, 15)
			}
			sqlite3_open_table_and_indices(p_parse, p_tab, 116, U8(8), i_tab_cur, a_to_open, &i_data_cur, &i_idx_cur)
			if e_one_pass == 2 {
				sqlite3_vdbe_jump_here_or_pop_inst(v, i_addr_once)
			}
		}
		if e_one_pass != 0 {
			if !(int(p_tab.eTabType) == 1) && int(a_to_open[i_data_cur - i_tab_cur]) {
				sqlite3_vdbe_add_op4_int(v, 28, i_data_cur, addr_bypass, i_key, int(n_key))
			}
		} else if p_pk {
			addr_loop = sqlite3_vdbe_add_op1(v, 36, i_eph_cur)
			if (int(p_tab.eTabType) == 1) {
				sqlite3_vdbe_add_op3(v, 96, i_eph_cur, 0, i_key)
			} else {
				sqlite3_vdbe_add_op2(v, 136, i_eph_cur, i_key)
			}
		} else {
			addr_loop = sqlite3_vdbe_add_op3(v, 48, i_row_set, 0, i_key)
		}
		if (int(p_tab.eTabType) == 1) {
			pvt_ab := &i8(voidptr(sqlite3_get_vt_able(db, p_tab)))
			sqlite3_vtab_make_writable(p_parse, p_tab)
			sqlite3_may_abort(p_parse)
			if e_one_pass == 1 {
				sqlite3_vdbe_add_op1(v, 124, i_tab_cur)
				if (usize(p_parse.pToplevel) == usize(0)) {
					p_parse.isMultiWrite = U8(0)
				}
			}
			sqlite3_vdbe_add_op4(v, 7, 0, 1, i_key, pvt_ab, (-12))
			sqlite3_vdbe_change_p5(v, U16(2))
		} else {
			count := int((int(p_parse.nested) == 0))
			sqlite3_generate_row_delete(p_parse, p_tab, p_trigger, i_data_cur, i_idx_cur, i_key, n_key, U8(count), U8(11), U8(e_one_pass), ai_cur_one_pass[1])
		}
		if e_one_pass != 0 {
			sqlite3_vdbe_resolve_label(v, addr_bypass)
			sqlite3_where_end(pwi_nfo)
		} else if p_pk {
			sqlite3_vdbe_add_op2(v, 40, i_eph_cur, addr_loop + 1)
			sqlite3_vdbe_jump_here(v, addr_loop)
		} else {
			sqlite3_vdbe_goto(v, addr_loop)
			sqlite3_vdbe_jump_here(v, addr_loop)
		}
	}
	if int(p_parse.nested) == 0 && usize(p_parse.pTriggerTab) == usize(0) {
		sqlite3_autoincrement_end(p_parse)
	}
	if mem_cnt {
		sqlite3_code_change_count(v, mem_cnt, c'rows deleted')
	}
	delete_from_cleanup:
	sqlite3_auth_context_pop(&s_context)
	sqlite3_src_list_delete(db, p_tab_list)
	sqlite3_expr_delete(db, p_where)
	if a_to_open {
		sqlite3_db_nn_free_nn(db, voidptr(a_to_open))
	}
	return
}

@[c:'sqlite3GenerateRowDelete']
fn sqlite3_generate_row_delete(p_parse &Parse, p_tab &Table, p_trigger &Trigger, i_data_cur int, i_idx_cur int, i_pk int, n_pk I16, count U8, onconf U8, e_mode U8, i_idx_no_seek int) {
	v := p_parse.pVdbe
	i_old := 0
	i_label := 0
	op_seek := U8(0)
	i_label = sqlite3_vdbe_make_label(p_parse)
	op_seek = U8(if ((p_tab.tabFlags & u32(128)) == u32(0)) { 31 } else { 28 })
	if int(e_mode) == 0 {
		sqlite3_vdbe_add_op4_int(v, int(op_seek), i_data_cur, i_label, i_pk, int(n_pk))
	}
	if sqlite3_fk_required(p_parse, p_tab, unsafe { nil }, 0) || !isnil(p_trigger) {
		mask := u32(0)
		i_col := 0
		addr_start := 0
		mask = sqlite3_trigger_colmask(p_parse, p_trigger, unsafe { nil }, 0, 1 | 2, p_tab, int(onconf))
		mask |= sqlite3_fk_oldmask(p_parse, p_tab)
		i_old = p_parse.nMem + 1
		p_parse.nMem += (1 + int(p_tab.nCol))
		sqlite3_vdbe_add_op2(v, 82, i_pk, i_old)
		for i_col = 0; i_col < int(p_tab.nCol); i_col++ {
			if mask == u32(4294967295) || (i_col <= 31 && (mask & ((u32(1)) << i_col)) != u32(0)) {
				kk := int(sqlite3_table_column_to_storage(p_tab, I16(i_col)))
				sqlite3_expr_code_get_column_of_table(v, p_tab, i_data_cur, i_col, i_old + kk + 1)
			}
		}
		addr_start = sqlite3_vdbe_current_addr(v)
		sqlite3_code_row_trigger(p_parse, p_trigger, 129, unsafe { nil }, 1, p_tab, i_old, int(onconf), i_label)
		if addr_start < sqlite3_vdbe_current_addr(v) {
			sqlite3_vdbe_add_op4_int(v, int(op_seek), i_data_cur, i_label, i_pk, int(n_pk))
			i_idx_no_seek = -1
		}
		sqlite3_fk_check(p_parse, p_tab, i_old, 0, unsafe { nil }, 0)
	}
	if !(int(p_tab.eTabType) == 2) {
		p5 := U8(0)
		sqlite3_generate_row_index_delete(p_parse, p_tab, i_data_cur, i_idx_cur, unsafe { nil }, i_idx_no_seek)
		sqlite3_vdbe_add_op2(v, 132, i_data_cur, (if int(count) { 1 } else { 0 }))
		if int(p_parse.nested) == 0 || 0 == sqlite3_stricmp(p_tab.zName, c'sqlite_stat1') {
			sqlite3_vdbe_append_p4(v, voidptr(&i8(voidptr(p_tab))), (-5))
		}
		if int(e_mode) != 0 {
			sqlite3_vdbe_change_p5(v, U16(4))
		}
		if i_idx_no_seek >= 0 && i_idx_no_seek != i_data_cur {
			sqlite3_vdbe_add_op1(v, 132, i_idx_no_seek)
		}
		if int(e_mode) == 2 {
			p5 |= 2
		}
		sqlite3_vdbe_change_p5(v, U16(p5))
	}
	sqlite3_fk_actions(p_parse, p_tab, unsafe { nil }, i_old, unsafe { nil }, 0)
	if p_trigger {
		sqlite3_code_row_trigger(p_parse, p_trigger, 129, unsafe { nil }, 2, p_tab, i_old, int(onconf), i_label)
	}
	sqlite3_vdbe_resolve_label(v, i_label)
}

@[c:'sqlite3GenerateRowIndexDelete']
fn sqlite3_generate_row_index_delete(p_parse &Parse, p_tab &Table, i_data_cur int, i_idx_cur int, a_reg_idx &int, i_idx_no_seek int) {
	i := 0
	r1 := -1
	i_part_idx_label := 0
	p_idx := &Index(0)
	p_prior := unsafe { &Index(nil) }
	v := &Vdbe(0)
	p_pk := &Index(0)
	v = p_parse.pVdbe
	p_pk = unsafe { if ((p_tab.tabFlags & u32(128)) == u32(0)) {
		&Index(nil)
	} else {
		sqlite3_primary_key_index(p_tab)
	} }
	i = 0
	for p_idx = p_tab.pIndex; p_idx;  {
		if usize(a_reg_idx) != usize(0) && a_reg_idx[i] == 0 {
			unsafe { goto c2v_for_next_113
			 }
		}
		if usize(p_idx) == usize(p_pk) {
			unsafe { goto c2v_for_next_113
			 }
		}
		if i_idx_cur + i == i_idx_no_seek {
			unsafe { goto c2v_for_next_113
			 }
		}
		r1 = sqlite3_generate_index_key(p_parse, p_idx, i_data_cur, 0, 1, &i_part_idx_label, p_prior, r1)
		sqlite3_vdbe_add_op3(v, 142, i_idx_cur + i, r1, if int(p_idx.uniqNotNull) {
			int(p_idx.nKeyCol)
		} else {
			int(p_idx.nColumn)
		})
		sqlite3_vdbe_change_p4(v, -1, &i8(voidptr(p_idx)), (-6))
		sqlite3_resolve_part_idx_label(p_parse, i_part_idx_label)
		p_prior = p_idx
		c2v_for_next_113:
		i++
		p_idx = p_idx.pNext
	}
}

@[c:'sqlite3GenerateIndexKey']
fn sqlite3_generate_index_key(p_parse &Parse, p_idx &Index, i_data_cur int, reg_out int, prefix_only int, pi_part_idx_label &int, p_prior &Index, reg_prior int) int {
	v := p_parse.pVdbe
	j := 0
	reg_base := 0
	n_col := 0
	if pi_part_idx_label {
		if p_idx.pPartIdxWhere {
			unsafe { *pi_part_idx_label = sqlite3_vdbe_make_label(p_parse) }
			p_parse.iSelfTab = i_data_cur + 1
			sqlite3_expr_if_falsedup(p_parse, p_idx.pPartIdxWhere, (unsafe { *pi_part_idx_label }), 16)
			p_parse.iSelfTab = 0
			p_prior = 0
		} else {
			unsafe { *pi_part_idx_label = 0 }
		}
	}
	n_col = if (prefix_only && int(p_idx.uniqNotNull)) {
		int(p_idx.nKeyCol)
	} else {
		int(p_idx.nColumn)
	}
	reg_base = sqlite3_get_temp_range(p_parse, n_col)
	if !isnil(p_prior) && (reg_base != reg_prior || !isnil(p_prior.pPartIdxWhere)) {
		p_prior = 0
	}
	for j = 0; j < n_col; j++ {
		if !isnil(p_prior) && int(p_prior.aiColumn[j]) == int(p_idx.aiColumn[j]) && int(p_prior.aiColumn[j]) != (-2) {
			continue
		}
		sqlite3_expr_code_load_index_column(p_parse, p_idx, i_data_cur, j, reg_base + j)
		if int(p_idx.aiColumn[j]) >= 0 {
			sqlite3_vdbe_delete_prior_opcode(v, U8(89))
		}
	}
	if reg_out {
		sqlite3_vdbe_add_op3(v, 99, reg_base, n_col, reg_out)
	}
	sqlite3_release_temp_range(p_parse, reg_base, n_col)
	return reg_base
}

@[c:'sqlite3ResolvePartIdxLabel']
fn sqlite3_resolve_part_idx_label(p_parse &Parse, i_label int) {
	if i_label {
		sqlite3_vdbe_resolve_label(p_parse.pVdbe, i_label)
	}
}
