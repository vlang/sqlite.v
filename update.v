@[translated]
module main

@[c:'sqlite3ColumnDefault']
fn sqlite3_column_default(v &Vdbe, p_tab &Table, i int, i_reg int) {
	p_col := &Column(0)
	p_col = unsafe { p_tab.aCol + i }
	if p_col.iDflt {
		p_value := unsafe { &Sqlite3_value(nil) }
		enc := sqlite3_vdbe_db(v).enc
		0
		sqlite3_value_from_expr(sqlite3_vdbe_db(v), sqlite3_column_expr(p_tab, p_col), enc, U8(p_col.affinity), &&Sqlite3_value(&&Sqlite3_value(c2v_address_of(&p_value))))
		if p_value {
			sqlite3_vdbe_append_p4(v, voidptr(p_value), (-11))
		}
	}
	if int(p_col.affinity) == 69 && !(int(p_tab.eTabType) == 1) {
		sqlite3_vdbe_add_op1(v, 89, i_reg)
	}
}

@[c:'indexColumnIsBeingUpdated']
fn index_column_is_being_updated(p_idx &Index, i_col int, axr_ef &int, chng_rowid int) int {
	i_idx_col := p_idx.aiColumn[i_col]
	if int(i_idx_col) >= 0 {
		return int(axr_ef[i_idx_col] >= 0)
	}
	return sqlite3_expr_references_updated_column(c2v_at(&p_idx.aColExpr.a[0], isize(i_col)).pExpr, axr_ef, chng_rowid)
}

@[c:'indexWhereClauseMightChange']
fn index_where_clause_might_change(p_idx &Index, axr_ef &int, chng_rowid int) int {
	if usize(p_idx.pPartIdxWhere) == usize(0) {
		return 0
	}
	return sqlite3_expr_references_updated_column(p_idx.pPartIdxWhere, axr_ef, chng_rowid)
}

@[c:'exprRowColumn']
fn expr_row_column(p_parse &Parse, i_col int) &Expr {
	p_ret := sqlite3_pe_xpr(p_parse, 76, unsafe { nil }, unsafe { nil })
	if p_ret {
		p_ret.iColumn = YnVar(i_col + 1)
	}
	return p_ret
}

@[c:'updateFromSelect']
fn update_from_select(p_parse &Parse, i_eph int, p_pk &Index, p_changes &ExprList, p_tab_list &SrcList, p_where &Expr, p_order_by &ExprList, p_limit &Expr) {
	i := 0
	dest := SelectDest{}
	p_select := unsafe { &Select(nil) }
	p_list := unsafe { &ExprList(nil) }
	p_grp := unsafe { &ExprList(nil) }
	p_limit2 := unsafe { &Expr(nil) }
	p_order_by2 := unsafe { &ExprList(nil) }
	db := p_parse.db
	p_tab := c2v_at(&p_tab_list.a[0], isize(0)).pSTab
	p_src := &SrcList(0)
	p_where2 := &Expr(0)
	e_dest := 0

	p_src = sqlite3_src_list_dup(db, p_tab_list, 0)
	p_where2 = sqlite3_expr_dup(db, p_where, 0)
	if p_src {
		mut __c2v_lhs_tmp_154 := c2v_at(&p_src.a[0], isize(0))
		__c2v_lhs_tmp_154.iCursor = -1
		mut __c2v_lhs_tmp_155 := c2v_at(&p_src.a[0], isize(0))
		__c2v_lhs_tmp_155.pSTab.nTabRef--
		mut __c2v_lhs_tmp_156 := c2v_at(&p_src.a[0], isize(0))
		__c2v_lhs_tmp_156.pSTab = 0
	}
	if p_pk {
		for i = 0; i < int(p_pk.nKeyCol); i++ {
			p_new := expr_row_column(p_parse, int(p_pk.aiColumn[i]))
			p_list = sqlite3_expr_list_append(p_parse, p_list, p_new)
		}
		e_dest = if (int(p_tab.eTabType) == 1) { 12 } else { 13 }
	} else if (int(p_tab.eTabType) == 2) {
		for i = 0; i < int(p_tab.nCol); i++ {
			p_list = sqlite3_expr_list_append(p_parse, p_list, expr_row_column(p_parse, i))
		}
		e_dest = 12
	} else {
		e_dest = if (int(p_tab.eTabType) == 1) { 12 } else { 13 }
		p_list = sqlite3_expr_list_append(p_parse, unsafe { nil }, sqlite3_pe_xpr(p_parse, 76, unsafe { nil }, unsafe { nil }))
	}
	if p_changes {
		for i = 0; i < p_changes.nExpr; i++ {
			p_list = sqlite3_expr_list_append(p_parse, p_list, sqlite3_expr_dup(db, c2v_at(&p_changes.a[0], isize(i)).pExpr, 0))
		}
	}
	p_select = sqlite3_select_new(p_parse, p_list, p_src, p_where2, p_grp, unsafe { nil }, p_order_by2, u32(8388608 | 131072 | 268435456), p_limit2)
	if p_select {
		p_select.selFlags |= u32(134217728)
	}
	sqlite3_select_dest_init(&dest, e_dest, i_eph)
	dest.iSDParm2 = (if p_pk { int(p_pk.nKeyCol) } else { -1 })
	sqlite3_select(p_parse, p_select, &dest)
	sqlite3_select_delete(db, p_select)
}

@[c:'sqlite3Update']
fn sqlite3_update(p_parse &Parse, p_tab_list &SrcList, p_changes &ExprList, p_where &Expr, on_error int, p_order_by &ExprList, p_limit &Expr, p_upsert &Upsert) {
	i := 0
	j := 0
	k := 0

	p_tab := &Table(0)
	addr_top := 0
	pwi_nfo := unsafe { &WhereInfo(nil) }
	v := &Vdbe(0)
	p_idx := &Index(0)
	p_pk := &Index(0)
	n_idx := 0
	n_all_idx := 0
	i_base_cur := 0
	i_data_cur := 0
	i_idx_cur := 0
	db := &Sqlite3(0)
	a_reg_idx := unsafe { &int(nil) }
	axr_ef := unsafe { &int(nil) }
	a_to_open := &U8(0)
	chng_pk := U8(0)
	chng_rowid := U8(0)
	chng_key := U8(0)
	p_rowid_expr := unsafe { &Expr(nil) }
	i_rowid_expr := -1
	s_context := AuthContext{}
	snc := NameContext{}
	i_db := 0
	e_one_pass := 0
	has_fk := 0
	label_break := 0
	label_continue := 0
	flags := 0
	is_view := 0
	p_trigger := &Trigger(0)
	tmask := 0
	newmask := 0
	i_eph := 0
	n_key := 0
	ai_cur_one_pass := [2]int{}
	addr_open := 0
	i_pk := 0
	n_pk := I16(0)
	b_replace := 0
	b_finish_seek := 1
	n_change_from := 0
	reg_row_count := 0
	reg_old_rowid := 0
	reg_new_rowid := 0
	reg_new := 0
	reg_old := 0
	reg_row_set := 0
	reg_key := 0
	C.memset(voidptr(&s_context), 0, sizeof(s_context))
	db = p_parse.db
	if p_parse.nErr {
		unsafe { goto update_cleanup
		 }
	}
	p_tab = sqlite3_src_list_lookup(p_parse, p_tab_list)
	if usize(p_tab) == usize(0) {
		unsafe { goto update_cleanup
		 }
	}
	i_db = sqlite3_schema_to_index(p_parse.db, p_tab.pSchema)
	p_trigger = sqlite3_triggers_exist(p_parse, p_tab, 130, p_changes, &tmask)
	is_view = (int(p_tab.eTabType) == 2)
	n_change_from = if (p_tab_list.nSrc > 1) { p_changes.nExpr } else { 0 }
	if sqlite3_view_get_column_names(p_parse, p_tab) {
		unsafe { goto update_cleanup
		 }
	}
	if sqlite3_is_read_only(p_parse, p_tab, p_trigger) {
		unsafe { goto update_cleanup
		 }
	}
	mut __c2v_postfix_value_35 := p_parse.nTab
	p_parse.nTab++
	i_data_cur = __c2v_postfix_value_35
	i_base_cur = i_data_cur
	i_idx_cur = i_data_cur + 1
	p_pk = unsafe { if ((p_tab.tabFlags & u32(128)) == u32(0)) {
		&Index(nil)
	} else {
		sqlite3_primary_key_index(p_tab)
	} }
	0
	n_idx = 0
	for p_idx = p_tab.pIndex; p_idx;  {
		if usize(p_pk) == usize(p_idx) {
			i_data_cur = p_parse.nTab
		}
		p_parse.nTab++
		p_idx = p_idx.pNext
		n_idx++
	}
	if p_upsert {
		i_data_cur = p_upsert.iDataCur
		i_idx_cur = p_upsert.iIdxCur
		p_parse.nTab = i_base_cur
	}
	mut __c2v_lhs_tmp_157 := c2v_at(&p_tab_list.a[0], isize(0))
	__c2v_lhs_tmp_157.iCursor = i_data_cur
	axr_ef = sqlite3_db_malloc_raw_nn(db, U64(sizeof(int) * u64((int(p_tab.nCol) + n_idx + 1)) + u64(n_idx) + u64(2)))
	if usize(axr_ef) == usize(0) {
		unsafe { goto update_cleanup
		 }
	}
	a_reg_idx = axr_ef + int(p_tab.nCol)
	a_to_open = &U8(voidptr((a_reg_idx + n_idx + 1)))
	C.memset(voidptr(a_to_open), 1, u64(n_idx + 1))
	a_to_open[n_idx + 1] = U8(0)
	for i = 0; i < int(p_tab.nCol); i++ {
		axr_ef[i] = -1
	}
	C.memset(voidptr(&snc), 0, sizeof(snc))
	snc.pParse = p_parse
	snc.pSrcList = p_tab_list
	snc.uNC.pUpsert = p_upsert
	snc.ncFlags = 512
	v = sqlite3_get_vdbe(p_parse)
	if usize(v) == usize(0) {
		unsafe { goto update_cleanup
		 }
	}
	chng_pk = U8(0)
	chng_rowid = chng_pk
	for i = 0; i < p_changes.nExpr; i++ {
		if n_change_from == 0 && sqlite3_resolve_expr_names(&snc, c2v_at(&p_changes.a[0], isize(i)).pExpr) {
			unsafe { goto update_cleanup
			 }
		}
		j = sqlite3_column_index(p_tab, c2v_at(&p_changes.a[0], isize(i)).zEName)
		if j >= 0 {
			if j == int(p_tab.iPKey) {
				chng_rowid = U8(1)
				p_rowid_expr = c2v_at(&p_changes.a[0], isize(i)).pExpr
				i_rowid_expr = i
			} else if !isnil(p_pk) && (int(p_tab.aCol[j].colFlags) & 1) != 0 {
				chng_pk = U8(1)
			} else if int(p_tab.aCol[j].colFlags) & 96 {
				0
				0
				sqlite3_error_msg(p_parse, c'cannot UPDATE generated column "%s"', voidptr(p_tab.aCol[j].zCnName))
				unsafe { goto update_cleanup
				 }
			}
			axr_ef[j] = i
		} else {
			if usize(p_pk) == usize(0) && sqlite3_is_rowid(c2v_at(&p_changes.a[0], isize(i)).zEName) {
				j = -1
				chng_rowid = U8(1)
				p_rowid_expr = c2v_at(&p_changes.a[0], isize(i)).pExpr
				i_rowid_expr = i
			} else {
				sqlite3_error_msg(p_parse, c'no such column: %s', voidptr(c2v_at(&p_changes.a[0], isize(i)).zEName))
				p_parse.checkSchema = Bft(1)
				unsafe { goto update_cleanup
				 }
			}
		}
		rc := 0
		rc = sqlite3_auth_check(p_parse, 23, p_tab.zName, unsafe { if j < 0 {
			c'ROWID'
		} else {
			p_tab.aCol[j].zCnName
		} }, db.aDb[i_db].zDbSName)
		if rc == 1 {
			unsafe { goto update_cleanup
			 }
		} else if rc == 2 {
			axr_ef[j] = -1
		}
	}
	chng_key = U8(int(chng_rowid) + int(chng_pk))
	if p_tab.tabFlags & u32(96) {
		b_progress := 0
		0
		0
		for {
			b_progress = 0
			for i = 0; i < int(p_tab.nCol); i++ {
				if axr_ef[i] >= 0 {
					continue
				}
				if (int(p_tab.aCol[i].colFlags) & 96) == 0 {
					continue
				}
				if sqlite3_expr_references_updated_column(sqlite3_column_expr(p_tab, unsafe { p_tab.aCol + i }), axr_ef, int(chng_rowid)) {
					axr_ef[i] = 99999
					b_progress = 1
				}
			}
			if !b_progress {
				break
			}
		}
	}
	mut __c2v_lhs_tmp_158 := c2v_at(&p_tab_list.a[0], isize(0))
	__c2v_lhs_tmp_158.colUsed = if (int(p_tab.eTabType) == 1) { (Bitmask(-1)) } else { Bitmask(0) }
	has_fk = sqlite3_fk_required(p_parse, p_tab, axr_ef, int(chng_key))
	if on_error == 5 {
		b_replace = 1
	}
	n_all_idx = 0
	for p_idx = p_tab.pIndex; p_idx;  {
		reg := 0
		if int(chng_key) || has_fk > 1 || usize(p_idx) == usize(p_pk) || index_where_clause_might_change(p_idx, axr_ef, int(chng_rowid)) {
			reg = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			p_parse.nMem += int(p_idx.nColumn)
		} else {
			reg = 0
			for i = 0; i < int(p_idx.nKeyCol); i++ {
				if index_column_is_being_updated(p_idx, i, axr_ef, int(chng_rowid)) {
					reg = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
					p_parse.nMem += int(p_idx.nColumn)
					if on_error == 11 && int(p_idx.onError) == 5 {
						b_replace = 1
					}
					break
				}
			}
		}
		if reg == 0 {
			a_to_open[n_all_idx + 1] = U8(0)
		}
		a_reg_idx[n_all_idx] = reg
		p_idx = p_idx.pNext
		n_all_idx++
	}
	a_reg_idx[n_all_idx] = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	if b_replace {
		C.memset(voidptr(a_to_open), 1, u64(n_idx + 1))
	}
	if int(p_parse.nested) == 0 {
		sqlite3_vdbe_count_changes(v)
	}
	sqlite3_begin_write_operation(p_parse, !isnil(p_trigger) || has_fk, i_db)
	if !(int(p_tab.eTabType) == 1) {
		reg_row_set = a_reg_idx[n_all_idx]
		reg_new_rowid = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		reg_old_rowid = reg_new_rowid
		if int(chng_pk) || !isnil(p_trigger) || has_fk {
			reg_old = p_parse.nMem + 1
			p_parse.nMem += int(p_tab.nCol)
		}
		if int(chng_key) || !isnil(p_trigger) || has_fk {
			reg_new_rowid = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		}
		reg_new = p_parse.nMem + 1
		p_parse.nMem += int(p_tab.nCol)
	}
	if is_view {
		sqlite3_auth_context_push(p_parse, &s_context, p_tab.zName)
	}
	if n_change_from == 0 && is_view {
		sqlite3_materialize_view(p_parse, p_tab, p_where, p_order_by, p_limit, i_data_cur)
		p_order_by = 0
		p_limit = 0
	}
	if n_change_from == 0 && sqlite3_resolve_expr_names(&snc, p_where) {
		unsafe { goto update_cleanup
		 }
	}
	if (int(p_tab.eTabType) == 1) {
		update_virtual_table(p_parse, p_tab_list, p_tab, p_changes, p_rowid_expr, axr_ef, p_where, on_error)
		unsafe { goto update_cleanup
		 }
	}
	label_break = sqlite3_vdbe_make_label(p_parse)
	label_continue = label_break
	if (db.flags & (U64(1) << 32)) != U64(0) && isnil(p_parse.pTriggerTab) && !p_parse.nested && !p_parse.bReturning && usize(p_upsert) == usize(0) {
		reg_row_count = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		sqlite3_vdbe_add_op2(v, 73, 0, reg_row_count)
	}
	if n_change_from == 0 && ((p_tab.tabFlags & u32(128)) == u32(0)) {
		sqlite3_vdbe_add_op3(v, 77, 0, reg_row_set, reg_old_rowid)
		mut __c2v_postfix_value_36 := p_parse.nTab
		p_parse.nTab++
		i_eph = __c2v_postfix_value_36
		addr_open = sqlite3_vdbe_add_op3(v, 120, i_eph, 0, reg_row_set)
	} else {
		n_pk = I16(if p_pk { int(p_pk.nKeyCol) } else { 0 })
		i_pk = p_parse.nMem + 1
		p_parse.nMem += int(n_pk)
		p_parse.nMem += n_change_from
		reg_key = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		if usize(p_upsert) == usize(0) {
			n_eph_col := int(n_pk) + n_change_from + (if is_view { int(p_tab.nCol) } else { 0 })
			mut __c2v_postfix_value_37 := p_parse.nTab
			p_parse.nTab++
			i_eph = __c2v_postfix_value_37
			if p_pk {
				sqlite3_vdbe_add_op3(v, 77, 0, i_pk, i_pk + int(n_pk) - 1)
			}
			addr_open = sqlite3_vdbe_add_op2(v, 120, i_eph, n_eph_col)
			if p_pk {
				p_key_info := sqlite3_key_info_of_index(p_parse, p_pk)
				if p_key_info {
					p_key_info.nAllField = U16(n_eph_col)
					sqlite3_vdbe_append_p4(v, voidptr(p_key_info), (-9))
				}
			}
			if n_change_from {
				update_from_select(p_parse, i_eph, p_pk, p_changes, p_tab_list, p_where, p_order_by, p_limit)
				if is_view {
					i_data_cur = i_eph
				}
			}
		}
	}
	if n_change_from {
		sqlite3_multi_write(p_parse)
		e_one_pass = 0
		n_key = int(n_pk)
		reg_key = i_pk
	} else {
		if p_upsert {
			pwi_nfo = 0
			e_one_pass = 1
			sqlite3_expr_if_false(p_parse, p_where, label_break, 16)
			b_finish_seek = 0
		} else {
			flags = 4
			if !p_parse.nested && isnil(p_trigger) && !has_fk && !chng_key && !b_replace && (usize(p_where) == usize(0) || !((p_where.flags & u32(4194304)) != u32(0))) {
				flags |= 8
			}
			pwi_nfo = sqlite3_where_begin(p_parse, p_tab_list, p_where, unsafe { nil }, unsafe { nil }, unsafe { nil }, U16(flags), i_idx_cur)
			if usize(pwi_nfo) == usize(0) {
				unsafe { goto update_cleanup
				 }
			}
			e_one_pass = sqlite3_where_ok_one_pass(pwi_nfo, &ai_cur_one_pass[0])
			b_finish_seek = sqlite3_where_uses_deferred_seek(pwi_nfo)
			if e_one_pass != 1 {
				sqlite3_multi_write(p_parse)
				if e_one_pass == 2 {
					i_cur := ai_cur_one_pass[1]
					if i_cur >= 0 && i_cur != i_data_cur && int(a_to_open[i_cur - i_base_cur]) {
						e_one_pass = 0
					}
				}
			}
		}
		if ((p_tab.tabFlags & u32(128)) == u32(0)) {
			sqlite3_vdbe_add_op2(v, 137, i_data_cur, reg_old_rowid)
			if e_one_pass == 0 {
				a_reg_idx[n_all_idx] = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
				sqlite3_vdbe_add_op3(v, 130, i_eph, reg_row_set, reg_old_rowid)
			} else {
				if addr_open {
					sqlite3_vdbe_change_to_noop(v, addr_open)
				}
			}
		} else {
			for i = 0; i < int(n_pk); i++ {
				sqlite3_expr_code_get_column_of_table(v, p_tab, i_data_cur, int(p_pk.aiColumn[i]), i_pk + i)
			}
			if e_one_pass {
				if addr_open {
					sqlite3_vdbe_change_to_noop(v, addr_open)
				}
				n_key = int(n_pk)
				reg_key = i_pk
			} else {
				sqlite3_vdbe_add_op4(v, 99, i_pk, int(n_pk), reg_key, sqlite3_index_affinity_str(db, p_pk), int(n_pk))
				sqlite3_vdbe_add_op4_int(v, 140, i_eph, reg_key, i_pk, int(n_pk))
			}
		}
	}
	if usize(p_upsert) == usize(0) {
		if n_change_from == 0 && e_one_pass != 2 {
			sqlite3_where_end(pwi_nfo)
		}
		if !is_view {
			addr_once := 0
			i_not_used1 := 0
			i_not_used2 := 0
			if e_one_pass != 0 {
				if ai_cur_one_pass[0] >= 0 {
					a_to_open[ai_cur_one_pass[0] - i_base_cur] = U8(0)
				}
				if ai_cur_one_pass[1] >= 0 {
					a_to_open[ai_cur_one_pass[1] - i_base_cur] = U8(0)
				}
			}
			if e_one_pass == 2 && (n_idx - int((ai_cur_one_pass[1] >= 0))) > 0 {
				addr_once = sqlite3_vdbe_add_op0(v, 15)
				0
			}
			sqlite3_open_table_and_indices(p_parse, p_tab, 116, U8(0), i_base_cur, a_to_open, &i_not_used1, &i_not_used2)
			if addr_once {
				sqlite3_vdbe_jump_here_or_pop_inst(v, addr_once)
			}
		}
		if e_one_pass != 0 {
			if ai_cur_one_pass[0] != i_data_cur && ai_cur_one_pass[1] != i_data_cur {
				sqlite3_vdbe_add_op4_int(v, 28, i_data_cur, label_break, reg_key, n_key)
				0
			}
			if e_one_pass != 1 {
				label_continue = sqlite3_vdbe_make_label(p_parse)
			}
			sqlite3_vdbe_add_op2(v, 51, if p_pk { reg_key } else { reg_old_rowid }, label_break)
			0
			0
		} else if !isnil(p_pk) || n_change_from {
			label_continue = sqlite3_vdbe_make_label(p_parse)
			sqlite3_vdbe_add_op2(v, 36, i_eph, label_break)
			0
			addr_top = sqlite3_vdbe_current_addr(v)
			if n_change_from {
				if !is_view {
					if p_pk {
						for i = 0; i < int(n_pk); i++ {
							sqlite3_vdbe_add_op3(v, 96, i_eph, i, i_pk + i)
						}
						sqlite3_vdbe_add_op4_int(v, 28, i_data_cur, label_continue, i_pk, int(n_pk))
						0
					} else {
						sqlite3_vdbe_add_op2(v, 137, i_eph, reg_old_rowid)
						sqlite3_vdbe_add_op3(v, 31, i_data_cur, label_continue, reg_old_rowid)
						0
					}
				}
			} else {
				sqlite3_vdbe_add_op2(v, 136, i_eph, reg_key)
				sqlite3_vdbe_add_op4_int(v, 28, i_data_cur, label_continue, reg_key, 0)
				0
			}
		} else {
			sqlite3_vdbe_add_op2(v, 36, i_eph, label_break)
			0
			label_continue = sqlite3_vdbe_make_label(p_parse)
			addr_top = sqlite3_vdbe_add_op2(v, 137, i_eph, reg_old_rowid)
			0
			sqlite3_vdbe_add_op3(v, 31, i_data_cur, label_continue, reg_old_rowid)
			0
		}
	}
	if chng_rowid {
		if n_change_from == 0 {
			sqlite3_expr_code(p_parse, p_rowid_expr, reg_new_rowid)
		} else {
			sqlite3_vdbe_add_op3(v, 96, i_eph, i_rowid_expr, reg_new_rowid)
		}
		sqlite3_vdbe_add_op1(v, 13, reg_new_rowid)
		0
	}
	if int(chng_pk) || has_fk || !isnil(p_trigger) {
		oldmask := (if has_fk { sqlite3_fk_oldmask(p_parse, p_tab) } else { u32(0) })
		oldmask |= sqlite3_trigger_colmask(p_parse, p_trigger, p_changes, 0, 1 | 2, p_tab, on_error)
		for i = 0; i < int(p_tab.nCol); i++ {
			col_flags := u32(p_tab.aCol[i].colFlags)
			k = int(sqlite3_table_column_to_storage(p_tab, I16(i))) + reg_old
			if oldmask == u32(4294967295) || (i < 32 && (oldmask & ((u32(1)) << i)) != u32(0)) || (col_flags & u32(1)) != u32(0) {
				0
				sqlite3_expr_code_get_column_of_table(v, p_tab, i_data_cur, i, k)
			} else {
				sqlite3_vdbe_add_op2(v, 77, 0, k)
			}
		}
		if int(chng_rowid) == 0 && usize(p_pk) == usize(0) {
			sqlite3_vdbe_add_op2(v, 82, reg_old_rowid, reg_new_rowid)
		}
	}
	newmask = int(sqlite3_trigger_colmask(p_parse, p_trigger, p_changes, 1, 1, p_tab, on_error))
	i = 0
	for k = reg_new; i < int(p_tab.nCol); i++ {
		if i == int(p_tab.iPKey) {
			sqlite3_vdbe_add_op2(v, 77, 0, k)
		} else if (int(p_tab.aCol[i].colFlags) & 96) != 0 {
			if int(p_tab.aCol[i].colFlags) & 32 {
				k--
			}
		} else {
			j = axr_ef[i]
			if j >= 0 {
				if n_change_from {
					n_off := (if is_view { int(p_tab.nCol) } else { int(n_pk) })
					sqlite3_vdbe_add_op3(v, 96, i_eph, n_off + j, k)
				} else {
					sqlite3_expr_code(p_parse, c2v_at(&p_changes.a[0], isize(j)).pExpr, k)
				}
			} else if 0 == (tmask & 1) || i > 31 || (u32(newmask) & ((u32(1)) << i)) {
				0
				0
				sqlite3_expr_code_get_column_of_table(v, p_tab, i_data_cur, i, k)
				b_finish_seek = 0
			} else {
				sqlite3_vdbe_add_op2(v, 77, 0, k)
			}
		}
		k++
	}
	if p_tab.tabFlags & u32(96) {
		0
		0
		sqlite3_compute_generated_columns(p_parse, reg_new, p_tab)
	}
	if tmask & 1 {
		sqlite3_table_affinity(v, p_tab, reg_new)
		sqlite3_code_row_trigger(p_parse, p_trigger, 130, p_changes, 1, p_tab, reg_old_rowid, on_error, label_continue)
		if !is_view {
			if p_pk {
				sqlite3_vdbe_add_op4_int(v, 28, i_data_cur, label_continue, reg_key, n_key)
				0
			} else {
				sqlite3_vdbe_add_op3(v, 31, i_data_cur, label_continue, reg_old_rowid)
				0
			}
			i = 0
			for k = reg_new; i < int(p_tab.nCol); i++ {
				if int(p_tab.aCol[i].colFlags) & 96 {
					if int(p_tab.aCol[i].colFlags) & 32 {
						k--
					}
				} else if axr_ef[i] < 0 && i != int(p_tab.iPKey) {
					sqlite3_expr_code_get_column_of_table(v, p_tab, i_data_cur, i, k)
				}
				k++
			}
			if p_tab.tabFlags & u32(96) {
				0
				0
				sqlite3_compute_generated_columns(p_parse, reg_new, p_tab)
			}
		}
	}
	if !is_view {
		sqlite3_generate_constraint_checks(p_parse, p_tab, a_reg_idx, i_data_cur, i_idx_cur, reg_new_rowid, reg_old_rowid, chng_key, U8(on_error), label_continue, &b_replace, axr_ef, unsafe { nil })
		if b_replace || int(chng_key) {
			if p_pk {
				sqlite3_vdbe_add_op4_int(v, 28, i_data_cur, label_continue, reg_key, n_key)
			} else {
				sqlite3_vdbe_add_op3(v, 31, i_data_cur, label_continue, reg_old_rowid)
			}
			0
		}
		if has_fk {
			sqlite3_fk_check(p_parse, p_tab, reg_old_rowid, 0, axr_ef, int(chng_key))
		}
		sqlite3_generate_row_index_delete(p_parse, p_tab, i_data_cur, i_idx_cur, a_reg_idx, -1)
		if b_finish_seek {
			sqlite3_vdbe_add_op1(v, 145, i_data_cur)
		}
		if has_fk > 1 || int(chng_key) {
			sqlite3_vdbe_add_op2(v, 132, i_data_cur, 0)
		}
		if has_fk {
			sqlite3_fk_check(p_parse, p_tab, 0, reg_new_rowid, axr_ef, int(chng_key))
		}
		sqlite3_complete_insertion(p_parse, p_tab, i_data_cur, i_idx_cur, reg_new_rowid, a_reg_idx, 4 | (if e_one_pass == 2 {
			2
		} else {
			0
		}), 0, 0)
		if has_fk {
			sqlite3_fk_actions(p_parse, p_tab, p_changes, reg_old_rowid, axr_ef, int(chng_key))
		}
	}
	if reg_row_count {
		sqlite3_vdbe_add_op2(v, 88, reg_row_count, 1)
	}
	if p_trigger {
		sqlite3_code_row_trigger(p_parse, p_trigger, 130, p_changes, 2, p_tab, reg_old_rowid, on_error, label_continue)
	}
	if e_one_pass == 1 {
	} else if e_one_pass == 2 {
		sqlite3_vdbe_resolve_label(v, label_continue)
		sqlite3_where_end(pwi_nfo)
	} else {
		sqlite3_vdbe_resolve_label(v, label_continue)
		sqlite3_vdbe_add_op2(v, 40, i_eph, addr_top)
		0
	}
	sqlite3_vdbe_resolve_label(v, label_break)
	if int(p_parse.nested) == 0 && usize(p_parse.pTriggerTab) == usize(0) && usize(p_upsert) == usize(0) {
		sqlite3_autoincrement_end(p_parse)
	}
	if reg_row_count {
		sqlite3_code_change_count(v, reg_row_count, c'rows updated')
	}
	update_cleanup:
	sqlite3_auth_context_pop(&s_context)
	sqlite3_db_free(db, voidptr(axr_ef))
	sqlite3_src_list_delete(db, p_tab_list)
	sqlite3_expr_list_delete(db, p_changes)
	sqlite3_expr_delete(db, p_where)
	return
}

@[c:'updateVirtualTable']
fn update_virtual_table(p_parse &Parse, p_src &SrcList, p_tab &Table, p_changes &ExprList, p_rowid &Expr, axr_ef &int, p_where &Expr, on_error int) {
	v := p_parse.pVdbe
	ephem_tab := 0
	i := 0
	db := p_parse.db
	pvt_ab := &i8(voidptr(sqlite3_get_vt_able(db, p_tab)))
	pwi_nfo := unsafe { &WhereInfo(nil) }
	n_arg := 2 + int(p_tab.nCol)
	reg_arg := 0
	reg_rec := 0
	reg_rowid := 0
	i_csr := c2v_at(&p_src.a[0], isize(0)).iCursor
	a_dummy := [2]int{}
	e_one_pass := 0
	addr := 0
	mut __c2v_postfix_value_38 := p_parse.nTab
	p_parse.nTab++
	ephem_tab = __c2v_postfix_value_38
	addr = sqlite3_vdbe_add_op2(v, 120, ephem_tab, n_arg)
	reg_arg = p_parse.nMem + 1
	p_parse.nMem += n_arg
	if p_src.nSrc > 1 {
		p_pk := unsafe { &Index(nil) }
		p_row := &Expr(0)
		p_list := &ExprList(0)
		if ((p_tab.tabFlags & u32(128)) == u32(0)) {
			if p_rowid {
				p_row = sqlite3_expr_dup(db, p_rowid, 0)
			} else {
				p_row = sqlite3_pe_xpr(p_parse, 76, unsafe { nil }, unsafe { nil })
			}
		} else {
			i_pk := I16(0)
			p_pk = sqlite3_primary_key_index(p_tab)
			i_pk = p_pk.aiColumn[0]
			if axr_ef[i_pk] >= 0 {
				p_row = sqlite3_expr_dup(db, c2v_at(&p_changes.a[0], isize(axr_ef[i_pk])).pExpr, 0)
			} else {
				p_row = expr_row_column(p_parse, int(i_pk))
			}
		}
		p_list = sqlite3_expr_list_append(p_parse, unsafe { nil }, p_row)
		for i = 0; i < int(p_tab.nCol); i++ {
			if axr_ef[i] >= 0 {
				p_list = sqlite3_expr_list_append(p_parse, p_list, sqlite3_expr_dup(db, c2v_at(&p_changes.a[0], isize(axr_ef[i])).pExpr, 0))
			} else {
				p_row_expr := expr_row_column(p_parse, i)
				if p_row_expr {
					p_row_expr.op2 = U8(1)
				}
				p_list = sqlite3_expr_list_append(p_parse, p_list, p_row_expr)
			}
		}
		update_from_select(p_parse, ephem_tab, p_pk, p_list, p_src, p_where, unsafe { nil }, unsafe { nil })
		sqlite3_expr_list_delete(db, p_list)
		e_one_pass = 0
	} else {
		reg_rec = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		reg_rowid = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		pwi_nfo = sqlite3_where_begin(p_parse, p_src, p_where, unsafe { nil }, unsafe { nil }, unsafe { nil }, U16(4), 0)
		if usize(pwi_nfo) == usize(0) {
			return
		}
		for i = 0; i < int(p_tab.nCol); i++ {
			if axr_ef[i] >= 0 {
				sqlite3_expr_code(p_parse, c2v_at(&p_changes.a[0], isize(axr_ef[i])).pExpr, reg_arg + 2 + i)
			} else {
				sqlite3_vdbe_add_op3(v, 178, i_csr, i, reg_arg + 2 + i)
				sqlite3_vdbe_change_p5(v, U16(1))
			}
		}
		if ((p_tab.tabFlags & u32(128)) == u32(0)) {
			sqlite3_vdbe_add_op2(v, 137, i_csr, reg_arg)
			if p_rowid {
				sqlite3_expr_code(p_parse, p_rowid, reg_arg + 1)
			} else {
				sqlite3_vdbe_add_op2(v, 137, i_csr, reg_arg + 1)
			}
		} else {
			p_pk := &Index(0)
			i_pk := I16(0)
			p_pk = sqlite3_primary_key_index(p_tab)
			i_pk = p_pk.aiColumn[0]
			sqlite3_vdbe_add_op3(v, 178, i_csr, int(i_pk), reg_arg)
			sqlite3_vdbe_add_op2(v, 83, reg_arg + 2 + int(i_pk), reg_arg + 1)
		}
		e_one_pass = sqlite3_where_ok_one_pass(pwi_nfo, &a_dummy[0])
		if e_one_pass {
			sqlite3_vdbe_change_to_noop(v, addr)
			sqlite3_vdbe_add_op1(v, 124, i_csr)
		} else {
			sqlite3_multi_write(p_parse)
			sqlite3_vdbe_add_op3(v, 99, reg_arg, n_arg, reg_rec)
			sqlite3_vdbe_add_op2(v, 129, ephem_tab, reg_rowid)
			sqlite3_vdbe_add_op3(v, 130, ephem_tab, reg_rec, reg_rowid)
		}
	}
	if e_one_pass == 0 {
		if p_src.nSrc == 1 {
			sqlite3_where_end(pwi_nfo)
		}
		addr = sqlite3_vdbe_add_op1(v, 36, ephem_tab)
		0
		for i = 0; i < n_arg; i++ {
			sqlite3_vdbe_add_op3(v, 96, ephem_tab, i, reg_arg + i)
		}
	}
	sqlite3_vtab_make_writable(p_parse, p_tab)
	sqlite3_vdbe_add_op4(v, 7, 0, n_arg, reg_arg, pvt_ab, (-12))
	sqlite3_vdbe_change_p5(v, U16(if on_error == 11 { 2 } else { on_error }))
	sqlite3_may_abort(p_parse)
	if e_one_pass == 0 {
		sqlite3_vdbe_add_op2(v, 40, ephem_tab, addr + 1)
		0
		sqlite3_vdbe_jump_here(v, addr)
		sqlite3_vdbe_add_op2(v, 124, ephem_tab, 0)
	} else {
		sqlite3_where_end(pwi_nfo)
	}
}
