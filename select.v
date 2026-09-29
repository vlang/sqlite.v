@[translated]
module main

struct DistinctCtx {
	isTnct    U8
	eTnctType U8
	tabTnct   int
	addrTnct  int
}

struct SortCtx {
	pOrderBy         &ExprList
	nOBSat           int
	iECursor         int
	regReturn        int
	labelBkOut       int
	addrSortIndex    int
	labelDone        int
	labelOBLopt      int
	sortFlags        U8
	pDeferredRowLoad &RowLoadInfo
}

@[c:'clearSelect']
fn clear_select(db &Sqlite3, p &Select, b_free int) {
	for p {
		p_prior := p.pPrior
		sqlite3_expr_list_delete(db, p.pEList)
		sqlite3_src_list_delete(db, p.pSrc)
		sqlite3_expr_delete(db, p.pWhere)
		sqlite3_expr_list_delete(db, p.pGroupBy)
		sqlite3_expr_delete(db, p.pHaving)
		sqlite3_expr_list_delete(db, p.pOrderBy)
		sqlite3_expr_delete(db, p.pLimit)
		if p.pWith {
			sqlite3_with_delete(db, p.pWith)
		}
		if p.pWinDefn {
			sqlite3_window_list_delete(db, p.pWinDefn)
		}
		for p.pWin {
			sqlite3_window_unlink_from_select(p.pWin)
		}
		if b_free {
			sqlite3_db_nn_free_nn(db, voidptr(p))
		}
		p = p_prior
		b_free = 1
	}
}

@[c:'sqlite3SelectDestInit']
fn sqlite3_select_dest_init(p_dest &SelectDest, e_dest int, i_parm int) {
	p_dest.eDest = U8(e_dest)
	p_dest.iSDParm = i_parm
	p_dest.iSDParm2 = 0
	p_dest.zAffSdst = 0
	p_dest.iSdst = 0
	p_dest.nSdst = 0
}

@[c:'sqlite3SelectNew']
fn sqlite3_select_new(p_parse &Parse, pel_ist &ExprList, p_src &SrcList, p_where &Expr, p_group_by &ExprList, p_having &Expr, p_order_by &ExprList, sel_flags u32, p_limit &Expr) &Select {
	p_new := &Select(0)
	p_allocated := &Select(0)

	standin := Select{}
	p_new = sqlite3_db_malloc_raw_nn(p_parse.db, U64(sizeof(Select)))
	p_allocated = p_new
	if usize(p_new) == usize(0) {
		p_new = &standin
	}
	if usize(pel_ist) == usize(0) {
		pel_ist = sqlite3_expr_list_append(p_parse, unsafe { nil }, sqlite3_expr(p_parse.db, 180, unsafe { nil }))
	}
	p_new.pEList = pel_ist
	p_new.op = U8(139)
	p_new.selFlags = sel_flags
	p_new.iLimit = 0
	p_new.iOffset = 0
	p_new.selId = u32(c2v_prefix_add(unsafe { &p_parse.nSelect }, 1))
	p_new.nSelectRow = LogEst(0)
	if usize(p_src) == usize(0) {
		p_src = sqlite3_db_malloc_zero(p_parse.db, U64(((u64(usize(__offsetof(SrcList, a)))) + sizeof(SrcItem))))
	}
	p_new.pSrc = p_src
	p_new.pWhere = p_where
	p_new.pGroupBy = p_group_by
	p_new.pHaving = p_having
	p_new.pOrderBy = p_order_by
	p_new.pPrior = 0
	p_new.pNext = 0
	p_new.pLimit = p_limit
	p_new.pWith = 0
	p_new.pWin = 0
	p_new.pWinDefn = 0
	if p_parse.db.mallocFailed {
		clear_select(p_parse.db, p_new, usize(p_new) != usize(&standin))
		p_allocated = 0
	} else {
	}
	return p_allocated
}

@[c:'sqlite3SelectDelete']
fn sqlite3_select_delete(db &Sqlite3, p &Select) {
	if p {
		clear_select(db, p, 1)
	}
}

@[c:'sqlite3SelectDeleteGeneric']
fn sqlite3_select_delete_generic(db &Sqlite3, p voidptr) {
	c2v_gc_register_thread()
	if p {
		clear_select(db, &Select(p), 1)
	}
}

@[c:'findRightmost']
fn find_rightmost(p &Select) &Select {
	for p.pNext {
		p = p.pNext
	}
	return p
}

@[c:'sqlite3JoinType']
fn sqlite3_join_type(p_parse &Parse, pa &Token, pb &Token, pc &Token) int {
	jointype := 0
	ap_all := [3]&Token{}
	p := &Token(0)
	if !sqlite3_join_type_z_key_text_inited {
		c2v_static_init := [i8(110), 97, 116, 117, 114, 97, 108, 101, 102, 116, 111, 117, 116, 101,
			114, 105, 103, 104, 116, 102, 117, 108, 108, 105, 110, 110, 101, 114, 99, 114, 111,
			115, 115, 0]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_join_type_z_key_text[c2v_i_0] = c2v_element_0
		}
		sqlite3_join_type_z_key_text_inited = true
	}

	if !sqlite3_join_type_a_keyword_inited {
		c2v_static_init := [AnonStruct_149376{
			i: U8(0)
			nChar: U8(7)
			code: U8(4)
		}, AnonStruct_149376{
			i: U8(6)
			nChar: U8(4)
			code: U8(8 | 32)
		}, AnonStruct_149376{
			i: U8(10)
			nChar: U8(5)
			code: U8(32)
		}, AnonStruct_149376{
			i: U8(14)
			nChar: U8(5)
			code: U8(16 | 32)
		}, AnonStruct_149376{
			i: U8(19)
			nChar: U8(4)
			code: U8(8 | 16 | 32)
		}, AnonStruct_149376{
			i: U8(23)
			nChar: U8(5)
			code: U8(1)
		}, AnonStruct_149376{
			i: U8(28)
			nChar: U8(5)
			code: U8(1 | 2)
		}]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_join_type_a_keyword[c2v_i_0] = c2v_element_0
		}
		sqlite3_join_type_a_keyword_inited = true
	}

	i := 0
	j := 0

	ap_all[0] = pa
	ap_all[1] = pb
	ap_all[2] = pc
	for i = 0; i < 3 && !isnil(ap_all[i]); i++ {
		p = ap_all[i]
		for j = 0; j < 7; j++ {
			if p.n == u32(sqlite3_join_type_a_keyword[j].nChar) && sqlite3_strnicmp(&i8(p.z), unsafe { &sqlite3_join_type_z_key_text[0] + sqlite3_join_type_a_keyword[j].i }, int(p.n)) == 0 {
				jointype |= int(sqlite3_join_type_a_keyword[j].code)
				break
			}
		}
		if j >= 7 {
			jointype |= 128
			break
		}
	}
	if (jointype & (1 | 32)) == (1 | 32) || (jointype & 128) != 0 || (jointype & (32 | 8 | 16)) == 32 {
		z_sp1 := c' '
		z_sp2 := c' '
		if usize(pb) == usize(0) {
			c2v_pointer_postfix(voidptr(&z_sp1), z_sp1, isize(1))
		}
		if usize(pc) == usize(0) {
			c2v_pointer_postfix(voidptr(&z_sp2), z_sp2, isize(1))
		}
		sqlite3_error_msg(p_parse, c'unknown join type: %T%s%T%s%T', voidptr(pa), voidptr(z_sp1), voidptr(pb), voidptr(z_sp2), voidptr(pc))
		jointype = 1
	}
	return jointype
}

@[c:'sqlite3ColumnIndex']
fn sqlite3_column_index(p_tab &Table, z_col &i8) int {
	i := 0
	h := U8(0)
	a_col := &Column(0)
	n_col := 0
	h = sqlite3_str_ih_ash(z_col)
	a_col = p_tab.aCol
	n_col = int(p_tab.nCol)
	i = int(p_tab.aHx[u64(h) % sizeof([16]U8)])
	if int(a_col[i].hName) == int(h) && sqlite3_str_ic_mp(a_col[i].zCnName, z_col) == 0 {
		return i
	}
	i = 0
	for {
		if int(a_col[i].hName) == int(h) && sqlite3_str_ic_mp(a_col[i].zCnName, z_col) == 0 {
			return i
		}
		i++
		if i >= n_col {
			break
		}
	}
	return -1
}

@[c:'sqlite3SrcItemColumnUsed']
fn sqlite3_src_item_column_used(p_item &SrcItem, i_col int) {
	if p_item.fg.isNestedFrom {
		p_results := &ExprList(0)
		p_results = p_item.u4.pSubq.pSelect.pEList
		mut __c2v_lhs_tmp_133 := c2v_at(&p_results.a[0], isize(i_col))
		__c2v_lhs_tmp_133.fg.bUsed = u32(1)
	}
}

@[c:'tableAndColumnIndex']
fn table_and_column_index(p_src &SrcList, i_start int, i_end int, z_col &i8, pi_tab &int, pi_col &int, b_ignore_hidden int) int {
	i := 0
	i_col := 0
	for i = i_start; i <= i_end; i++ {
		i_col = sqlite3_column_index(c2v_at(&p_src.a[0], isize(i)).pSTab, z_col)
		if i_col >= 0 && (b_ignore_hidden == 0 || ((int(c2v_at(&p_src.a[0], isize(i)).pSTab.aCol[i_col].colFlags) & 2) != 0) == 0) {
			if pi_tab {
				sqlite3_src_item_column_used(unsafe { &p_src.a[0] + i }, i_col)
				unsafe { *pi_tab = i }
				unsafe { *pi_col = i_col }
			}
			return 1
		}
	}
	return 0
}

@[c:'sqlite3SetJoinExpr']
fn sqlite3_set_join_expr(p &Expr, i_table int, join_flag u32) {
	for p {
		p.flags |= u32(join_flag)
		p.w.iJoin = i_table
		if ((p.flags & u32(4096)) == u32(0)) {
			if p.x.pList {
				i := 0
				for i = 0; i < p.x.pList.nExpr; i++ {
					sqlite3_set_join_expr(c2v_at(&p.x.pList.a[0], isize(i)).pExpr, i_table, join_flag)
				}
			}
		}
		sqlite3_set_join_expr(p.pLeft, i_table, join_flag)
		p = p.pRight
	}
}

@[c:'unsetJoinExpr']
fn unset_join_expr(p &Expr, i_table int, nullable int) {
	for p {
		if i_table < 0 || (((p.flags & u32(1)) != u32(0)) && p.w.iJoin == i_table) {
			p.flags &= ~u32((1 | 2))
			if i_table >= 0 {
				p.flags |= u32(2)
			}
		}
		if int(p.op) == 168 && p.iTable == i_table && !nullable {
			p.flags &= ~u32(2097152)
		}
		if int(p.op) == 172 {
			if p.x.pList {
				i := 0
				for i = 0; i < p.x.pList.nExpr; i++ {
					unset_join_expr(c2v_at(&p.x.pList.a[0], isize(i)).pExpr, i_table, nullable)
				}
			}
		}
		unset_join_expr(p.pLeft, i_table, nullable)
		p = p.pRight
	}
}

@[c:'sqlite3ProcessJoin']
fn sqlite3_process_join(p_parse &Parse, p &Select) int {
	p_src := &SrcList(0)
	i := 0
	j := 0

	p_left := &SrcItem(0)
	p_right := &SrcItem(0)
	p_src = p.pSrc
	p_left = unsafe { &p_src.a[0] + 0 }
	p_right = unsafe { p_left + 1 }
	for i = 0; i < p_src.nSrc - 1; i++ {
		p_right_tab := p_right.pSTab
		join_type := u32(0)
		if (usize(p_left.pSTab) == usize(0) || usize(p_right_tab) == usize(0)) {
			unsafe { goto c2v_for_next_139
			 }
		}
		join_type = u32(if (int(p_right.fg.jointype) & 32) != 0 { 1 } else { 2 })
		if int(p_right.fg.jointype) & 4 {
			p_using := unsafe { &IdList(nil) }
			if int(p_right.fg.isUsing) || !isnil(p_right.u3.pOn) {
				sqlite3_error_msg(p_parse, c'a NATURAL join may not have an ON or USING clause', 0)
				return 1
			}
			for j = 0; j < int(p_right_tab.nCol); j++ {
				z_name := &i8(0)
				if ((int(p_right_tab.aCol[j].colFlags) & 2) != 0) {
					continue
				}
				z_name = p_right_tab.aCol[j].zCnName
				if table_and_column_index(p_src, 0, i, z_name, unsafe { nil }, unsafe { nil }, 1) {
					p_using = sqlite3_id_list_append(p_parse, p_using, unsafe { nil })
					if p_using {
						mut __c2v_lhs_tmp_134 := unsafe { c2v_at(&p_using.a[0], isize(p_using.nId - 1)) }
						__c2v_lhs_tmp_134.zName = sqlite3_db_str_dup(p_parse.db, z_name)
					}
				}
			}
			if p_using {
				p_right.fg.isUsing = u32(1)
				p_right.fg.isSynthUsing = u32(1)
				p_right.u3.pUsing = p_using
			}
			if p_parse.nErr {
				return 1
			}
		}
		if p_right.fg.isUsing {
			p_list := p_right.u3.pUsing
			db := p_parse.db
			for j = 0; j < p_list.nId; j++ {
				z_name := &i8(0)
				i_left := 0
				i_left_col := 0
				i_right_col := 0
				p_e1 := &Expr(0)
				p_e2 := &Expr(0)
				p_eq := &Expr(0)
				z_name = c2v_at(&p_list.a[0], isize(j)).zName
				i_right_col = sqlite3_column_index(p_right_tab, z_name)
				if i_right_col < 0 || table_and_column_index(p_src, 0, i, z_name, &i_left, &i_left_col, int(p_right.fg.isSynthUsing)) == 0 {
					sqlite3_error_msg(p_parse, c'cannot join using column %s - column not present in both tables', voidptr(z_name))
					return 1
				}
				p_e1 = sqlite3_create_column_expr(db, p_src, i_left, i_left_col)
				sqlite3_src_item_column_used(unsafe { &p_src.a[0] + i_left }, i_left_col)
				if (int(c2v_at(&p_src.a[0], isize(0)).fg.jointype) & 64) != 0 && p_parse.nErr == 0 {
					p_func_args := unsafe { &ExprList(nil) }
					if !sqlite3_process_join_tk_coalesce_inited {
						sqlite3_process_join_tk_coalesce = Token{
							z: c'coalesce'
							n: u32(8)
						}

						sqlite3_process_join_tk_coalesce_inited = true
					}

					p_e1.flags |= u32(2097152)
					for table_and_column_index(p_src, i_left + 1, i, z_name, &i_left, &i_left_col, int(p_right.fg.isSynthUsing)) != 0 {
						if int(c2v_at(&p_src.a[0], isize(i_left)).fg.isUsing) == 0 || sqlite3_id_list_index(c2v_at(&p_src.a[0], isize(i_left)).u3.pUsing, z_name) < 0 {
							sqlite3_error_msg(p_parse, c'ambiguous reference to %s in USING()', voidptr(z_name))
							break
						}
						p_func_args = sqlite3_expr_list_append(p_parse, p_func_args, p_e1)
						p_e1 = sqlite3_create_column_expr(db, p_src, i_left, i_left_col)
						sqlite3_src_item_column_used(unsafe { &p_src.a[0] + i_left }, i_left_col)
					}
					if p_func_args {
						p_func_args = sqlite3_expr_list_append(p_parse, p_func_args, p_e1)
						p_e1 = sqlite3_expr_function(p_parse, p_func_args, &sqlite3_process_join_tk_coalesce, 0)
						if p_e1 {
							p_e1.affExpr = i8(88)
						}
					}
				} else if (int(c2v_at(&p_src.a[0], isize(i + 1)).fg.jointype) & 8) != 0 && p_parse.nErr == 0 {
					p_e1.flags |= u32(2097152)
				}
				p_e2 = sqlite3_create_column_expr(db, p_src, i + 1, i_right_col)
				sqlite3_src_item_column_used(p_right, i_right_col)
				p_eq = sqlite3_pe_xpr(p_parse, 54, p_e1, p_e2)
				if p_eq {
					p_eq.flags |= u32(join_type)
					p_eq.w.iJoin = p_e2.iTable
				}
				p.pWhere = sqlite3_expr_and(p_parse, p.pWhere, p_eq)
			}
		} else if p_right.u3.pOn {
			sqlite3_set_join_expr(p_right.u3.pOn, p_right.iCursor, join_type)
			p.pWhere = sqlite3_expr_and(p_parse, p.pWhere, p_right.u3.pOn)
			p_right.u3.pOn = 0
			p_right.fg.isOn = u32(1)
			p.selFlags |= u32(1073741824)
		}
		if (int(p_right_tab.eTabType) == 1) && join_type == u32(1) && !isnil(p_right.u1.pFuncArg) {
			p.selFlags |= u32(1073741824)
		}
		c2v_for_next_139:
		c2v_pointer_postfix(voidptr(&p_right), p_right, isize(1))
		c2v_pointer_postfix(voidptr(&p_left), p_left, isize(1))
	}
	return 0
}

struct RowLoadInfo {
	regResult int
	ecelFlags U8
}

@[c:'innerLoopLoadRow']
fn inner_loop_load_row(p_parse &Parse, p_select &Select, p_info &RowLoadInfo) {
	sqlite3_expr_code_expr_list(p_parse, p_select.pEList, p_info.regResult, 0, p_info.ecelFlags)
}

@[c:'makeSorterRecord']
fn make_sorter_record(p_parse &Parse, p_sort &SortCtx, p_select &Select, reg_base int, n_base int) int {
	nob_sat := p_sort.nOBSat
	v := p_parse.pVdbe
	reg_out := c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	if p_sort.pDeferredRowLoad {
		inner_loop_load_row(p_parse, p_select, p_sort.pDeferredRowLoad)
	}
	sqlite3_vdbe_add_op3(v, 99, reg_base + nob_sat, n_base - nob_sat, reg_out)
	return reg_out
}

@[c:'pushOntoSorter']
fn push_onto_sorter(p_parse &Parse, p_sort &SortCtx, p_select &Select, reg_data int, reg_orig_data int, n_data int, n_prefix_reg int) {
	v := p_parse.pVdbe
	b_seq := int(((int(p_sort.sortFlags) & 1) == 0))
	n_expr := p_sort.pOrderBy.nExpr
	n_base := n_expr + b_seq + n_data
	reg_base := 0
	reg_record := 0
	nob_sat := p_sort.nOBSat
	op := 0
	i_limit := 0
	i_skip := 0
	if n_prefix_reg {
		reg_base = reg_data - n_prefix_reg
	} else {
		reg_base = p_parse.nMem + 1
		p_parse.nMem += n_base
	}
	i_limit = if p_select.iOffset { p_select.iOffset + 1 } else { p_select.iLimit }
	p_sort.labelDone = sqlite3_vdbe_make_label(p_parse)
	sqlite3_expr_code_expr_list(p_parse, p_sort.pOrderBy, reg_base, reg_orig_data, U8(1 | (if reg_orig_data {
		4
	} else {
		0
	})))
	if b_seq {
		sqlite3_vdbe_add_op2(v, 128, p_sort.iECursor, reg_base + n_expr)
	}
	if n_prefix_reg == 0 && n_data > 0 {
		sqlite3_expr_code_move(p_parse, reg_data, reg_base + n_expr + b_seq, n_data)
	}
	if nob_sat > 0 {
		reg_prev_key := 0
		addr_first := 0
		addr_jmp := 0
		p_op := &VdbeOp(0)
		n_key := 0
		pki := &KeyInfo(0)
		reg_record = make_sorter_record(p_parse, p_sort, p_select, reg_base, n_base)
		reg_prev_key = p_parse.nMem + 1
		p_parse.nMem += p_sort.nOBSat
		n_key = n_expr - p_sort.nOBSat + b_seq
		if b_seq {
			addr_first = sqlite3_vdbe_add_op1(v, 17, reg_base + n_expr)
		} else {
			addr_first = sqlite3_vdbe_add_op1(v, 122, p_sort.iECursor)
		}
		sqlite3_vdbe_add_op3(v, 92, reg_prev_key, reg_base, p_sort.nOBSat)
		p_op = sqlite3_vdbe_get_op(v, p_sort.addrSortIndex)
		if p_parse.db.mallocFailed {
			return
		}
		p_op.p2 = n_key + n_data
		pki = p_op.p4.pKeyInfo
		C.memset(voidptr(pki.aSortFlags), 0, u64(pki.nKeyField))
		sqlite3_vdbe_change_p4(v, -1, &i8(voidptr(pki)), (-9))
		p_op.p4.pKeyInfo = sqlite3_key_info_from_expr_list(p_parse, p_sort.pOrderBy, nob_sat, int(pki.nAllField) - int(pki.nKeyField) - 1)
		p_op = 0
		addr_jmp = sqlite3_vdbe_current_addr(v)
		sqlite3_vdbe_add_op3(v, 14, addr_jmp + 1, 0, addr_jmp + 1)
		p_sort.labelBkOut = sqlite3_vdbe_make_label(p_parse)
		p_sort.regReturn = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		sqlite3_vdbe_add_op2(v, 10, p_sort.regReturn, p_sort.labelBkOut)
		sqlite3_vdbe_add_op1(v, 148, p_sort.iECursor)
		if i_limit {
			sqlite3_vdbe_add_op2(v, 17, i_limit, p_sort.labelDone)
		}
		sqlite3_vdbe_jump_here(v, addr_first)
		sqlite3_expr_code_move(p_parse, reg_base, reg_prev_key, p_sort.nOBSat)
		sqlite3_vdbe_jump_here(v, addr_jmp)
	}
	if i_limit {
		i_csr := p_sort.iECursor
		sqlite3_vdbe_add_op2(v, 62, i_limit, sqlite3_vdbe_current_addr(v) + 4)
		sqlite3_vdbe_add_op2(v, 32, i_csr, 0)
		i_skip = sqlite3_vdbe_add_op4_int(v, 41, i_csr, 0, reg_base + nob_sat, n_expr - nob_sat)
		sqlite3_vdbe_add_op1(v, 132, i_csr)
	}
	if reg_record == 0 {
		reg_record = make_sorter_record(p_parse, p_sort, p_select, reg_base, n_base)
	}
	if int(p_sort.sortFlags) & 1 {
		op = 141
	} else {
		op = 140
	}
	sqlite3_vdbe_add_op4_int(v, op, p_sort.iECursor, reg_record, reg_base + nob_sat, n_base - nob_sat)
	if i_skip {
		sqlite3_vdbe_change_p2(v, i_skip, if p_sort.labelOBLopt {
			p_sort.labelOBLopt
		} else {
			sqlite3_vdbe_current_addr(v)
		})
	}
}

@[c:'codeOffset']
fn code_offset(v &Vdbe, i_offset int, i_continue int) {
	if i_offset > 0 {
		sqlite3_vdbe_add_op3(v, 61, i_offset, i_continue, 1)
	}
}

@[c:'codeDistinct']
fn code_distinct(p_parse &Parse, e_tnct_type int, i_tab int, addr_repeat int, pel_ist &ExprList, reg_elem int) int {
	i_ret := 0
	n_result_col := pel_ist.nExpr
	v := p_parse.pVdbe
	match e_tnct_type {
		2 {
			i := 0
			i_jump := 0
			reg_prev := 0
			reg_prev = p_parse.nMem + 1
			i_ret = reg_prev
			p_parse.nMem += n_result_col
			i_jump = sqlite3_vdbe_current_addr(v) + n_result_col
			for i = 0; i < n_result_col; i++ {
				p_coll := sqlite3_expr_coll_seq(p_parse, c2v_at(&pel_ist.a[0], isize(i)).pExpr)
				if i < n_result_col - 1 {
					sqlite3_vdbe_add_op3(v, 53, reg_elem + i, i_jump, reg_prev + i)
				} else {
					sqlite3_vdbe_add_op3(v, 54, reg_elem + i, addr_repeat, reg_prev + i)
				}
				sqlite3_vdbe_change_p4(v, -1, &i8(voidptr(p_coll)), (-2))
				sqlite3_vdbe_change_p5(v, U16(128))
			}
			sqlite3_vdbe_add_op3(v, 82, reg_elem, reg_prev, n_result_col - 1)
		}
		1 {
		}
		else {
			r1 := sqlite3_get_temp_reg(p_parse)
			sqlite3_vdbe_add_op4_int(v, 29, i_tab, addr_repeat, reg_elem, n_result_col)
			sqlite3_vdbe_add_op3(v, 99, reg_elem, n_result_col, r1)
			sqlite3_vdbe_add_op4_int(v, 140, i_tab, r1, reg_elem, n_result_col)
			sqlite3_vdbe_change_p5(v, U16(16))
			sqlite3_release_temp_reg(p_parse, r1)
			i_ret = i_tab
		}
	}

	return i_ret
}

@[c:'fixDistinctOpenEph']
fn fix_distinct_open_eph(p_parse &Parse, e_tnct_type int, i_val int, i_open_eph_addr int) {
	if p_parse.nErr == 0 && (e_tnct_type == 1 || e_tnct_type == 2) {
		v := p_parse.pVdbe
		sqlite3_vdbe_change_to_noop(v, i_open_eph_addr)
		if int(sqlite3_vdbe_get_op(v, i_open_eph_addr + 1).opcode) == 190 {
			sqlite3_vdbe_change_to_noop(v, i_open_eph_addr + 1)
		}
		if e_tnct_type == 2 {
			p_op := sqlite3_vdbe_get_op(v, i_open_eph_addr)
			p_op.opcode = U8(77)
			p_op.p1 = 1
			p_op.p2 = i_val
		}
	}
}

@[c:'selectInnerLoop']
fn select_inner_loop(p_parse &Parse, p &Select, src_tab int, p_sort &SortCtx, p_distinct &DistinctCtx, p_dest &SelectDest, i_continue int, i_break int) {
	v := p_parse.pVdbe
	i := 0
	has_distinct := 0
	e_dest := int(p_dest.eDest)
	i_parm := p_dest.iSDParm
	n_result_col := 0
	n_prefix_reg := 0
	s_row_load_info := RowLoadInfo{}
	reg_result := 0
	reg_orig := 0
	has_distinct = if p_distinct { int(p_distinct.eTnctType) } else { 0 }
	if !isnil(p_sort) && usize(p_sort.pOrderBy) == usize(0) {
		p_sort = 0
	}
	if usize(p_sort) == usize(0) && !has_distinct {
		code_offset(v, p.iOffset, i_continue)
	}
	n_result_col = p.pEList.nExpr
	if p_dest.iSdst == 0 {
		if p_sort {
			n_prefix_reg = p_sort.pOrderBy.nExpr
			if !(int(p_sort.sortFlags) & 1) {
				n_prefix_reg++
			}
			p_parse.nMem += n_prefix_reg
		}
		p_dest.iSdst = p_parse.nMem + 1
		p_parse.nMem += n_result_col
	} else if p_dest.iSdst + n_result_col > p_parse.nMem {
		p_parse.nMem += n_result_col
	}
	p_dest.nSdst = n_result_col
	reg_result = p_dest.iSdst
	reg_orig = reg_result
	if src_tab >= 0 {
		for i = 0; i < n_result_col; i++ {
			sqlite3_vdbe_add_op3(v, 96, src_tab, i, reg_result + i)
		}
	} else if e_dest != 1 {
		ecel_flags := U8(0)
		pel_ist := &ExprList(0)
		if e_dest == 8 || e_dest == 7 || e_dest == 11 {
			ecel_flags = U8(1)
		} else {
			ecel_flags = U8(0)
		}
		if !isnil(p_sort) && has_distinct == 0 && e_dest != 10 && e_dest != 12 {
			ecel_flags |= (8 | 4)
			for i = p_sort.nOBSat; i < p_sort.pOrderBy.nExpr; i++ {
				j := 0
				j = int(c2v_at(&p_sort.pOrderBy.a[0], isize(i)).u.x.iOrderByCol)
				if j > 0 {
					mut __c2v_lhs_tmp_135 := unsafe { c2v_at(&p.pEList.a[0], isize(j - 1)) }
					__c2v_lhs_tmp_135.u.x.iOrderByCol = U16(i + 1 - p_sort.nOBSat)
				}
			}
			pel_ist = p.pEList
			for i = 0; i < pel_ist.nExpr; i++ {
				if int(c2v_at(&pel_ist.a[0], isize(i)).u.x.iOrderByCol) > 0 {
					n_result_col--
					reg_orig = 0
				}
			}
		}
		s_row_load_info.regResult = reg_result
		s_row_load_info.ecelFlags = ecel_flags
		if p.iLimit && (int(ecel_flags) & 8) != 0 && n_prefix_reg > 0 {
			p_sort.pDeferredRowLoad = &s_row_load_info
			reg_orig = 0
		} else {
			inner_loop_load_row(p_parse, p, &s_row_load_info)
		}
	}
	if has_distinct {
		e_type := int(p_distinct.eTnctType)
		i_tab := p_distinct.tabTnct
		i_tab = code_distinct(p_parse, e_type, i_tab, i_continue, p.pEList, reg_result)
		fix_distinct_open_eph(p_parse, e_type, i_tab, p_distinct.addrTnct)
		if usize(p_sort) == usize(0) {
			code_offset(v, p.iOffset, i_continue)
		}
	}
	match e_dest {
		6, 3, 12, 10 {
			r1 := sqlite3_get_temp_range(p_parse, n_prefix_reg + 1)
			sqlite3_vdbe_add_op3(v, 99, reg_result, n_result_col, r1 + n_prefix_reg)
			if e_dest == 3 {
				addr := sqlite3_vdbe_current_addr(v) + 4
				sqlite3_vdbe_add_op4_int(v, 29, i_parm + 1, addr, r1, 0)
				sqlite3_vdbe_add_op4_int(v, 140, i_parm + 1, r1, reg_result, n_result_col)
			}
			if p_sort {
				push_onto_sorter(p_parse, p_sort, p, r1 + n_prefix_reg, reg_orig, 1, n_prefix_reg)
			} else {
				r2 := sqlite3_get_temp_reg(p_parse)
				sqlite3_vdbe_add_op2(v, 129, i_parm, r2)
				sqlite3_vdbe_add_op3(v, 130, i_parm, r1, r2)
				sqlite3_vdbe_change_p5(v, U16(8))
				sqlite3_release_temp_reg(p_parse, r2)
			}
			sqlite3_release_temp_range(p_parse, r1, n_prefix_reg + 1)
		}
		13 {
			if p_sort {
				push_onto_sorter(p_parse, p_sort, p, reg_result, reg_orig, n_result_col, n_prefix_reg)
			} else {
				i2 := p_dest.iSDParm2
				r1_2 := sqlite3_get_temp_reg(p_parse)
				sqlite3_vdbe_add_op2(v, 51, reg_result, i_break)
				sqlite3_vdbe_add_op3(v, 99, reg_result + int((i2 < 0)), n_result_col - int((i2 < 0)), r1_2)
				if i2 < 0 {
					sqlite3_vdbe_add_op3(v, 130, i_parm, r1_2, reg_result)
				} else {
					sqlite3_vdbe_add_op4_int(v, 140, i_parm, r1_2, reg_result, i2)
				}
			}
		}
		9 {
			if p_sort {
				push_onto_sorter(p_parse, p_sort, p, reg_result, reg_orig, n_result_col, n_prefix_reg)
				p_dest.iSDParm2 = 0
			} else {
				r1_2 := sqlite3_get_temp_reg(p_parse)
				sqlite3_vdbe_add_op4(v, 99, reg_result, n_result_col, r1_2, p_dest.zAffSdst, n_result_col)
				sqlite3_vdbe_add_op4_int(v, 140, i_parm, r1_2, reg_result, n_result_col)
				if p_dest.iSDParm2 {
					sqlite3_vdbe_add_op4_int(v, 185, p_dest.iSDParm2, 0, reg_result, n_result_col)
					sqlite3_vdbe_explain(p_parse, U8(0), c'CREATE BLOOM FILTER')
				}
				sqlite3_release_temp_reg(p_parse, r1_2)
			}
		}
		1 {
			sqlite3_vdbe_add_op2(v, 73, 1, i_parm)
		}
		8 {
			if p_sort {
				push_onto_sorter(p_parse, p_sort, p, reg_result, reg_orig, n_result_col, n_prefix_reg)
				p_dest.iSDParm = reg_result
			} else {
				if reg_result != i_parm {
					sqlite3_vdbe_add_op3(v, 82, reg_result, i_parm, n_result_col - 1)
				}
			}
		}
		11, 7 {
			if p_sort {
				push_onto_sorter(p_parse, p_sort, p, reg_result, reg_orig, n_result_col, n_prefix_reg)
			} else if e_dest == 11 {
				sqlite3_vdbe_add_op1(v, 12, p_dest.iSDParm)
			} else {
				sqlite3_vdbe_add_op2(v, 86, reg_result, n_result_col)
			}
		}
		4, 5 {
			n_key := 0
			r1_2 := 0
			r2 := 0
			r3 := 0

			addr_test := 0
			pso := &ExprList(0)
			pso = p_dest.pOrderBy
			n_key = pso.nExpr
			r1_2 = sqlite3_get_temp_reg(p_parse)
			r2 = sqlite3_get_temp_range(p_parse, n_key + 2)
			r3 = r2 + n_key + 1
			if e_dest == 4 {
				addr_test = sqlite3_vdbe_add_op4_int(v, 29, i_parm + 1, 0, reg_result, n_result_col)
			}
			sqlite3_vdbe_add_op3(v, 99, reg_result, n_result_col, r3)
			if e_dest == 4 {
				sqlite3_vdbe_add_op2(v, 140, i_parm + 1, r3)
				sqlite3_vdbe_change_p5(v, U16(16))
			}
			for i = 0; i < n_key; i++ {
				sqlite3_vdbe_add_op2(v, 83, reg_result + int(c2v_at(&pso.a[0], isize(i)).u.x.iOrderByCol) - 1, r2 + i)
			}
			sqlite3_vdbe_add_op2(v, 128, i_parm, r2 + n_key)
			sqlite3_vdbe_add_op3(v, 99, r2, n_key + 2, r1_2)
			sqlite3_vdbe_add_op4_int(v, 140, i_parm, r1_2, r2, n_key + 2)
			if addr_test {
				sqlite3_vdbe_jump_here(v, addr_test)
			}
			sqlite3_release_temp_reg(p_parse, r1_2)
			sqlite3_release_temp_range(p_parse, r2, n_key + 2)
		}
		else {
		}
	}

	if usize(p_sort) == usize(0) && p.iLimit {
		sqlite3_vdbe_add_op2(v, 63, p.iLimit, i_break)
	}
}

@[c:'sqlite3KeyInfoAlloc']
fn sqlite3_key_info_alloc(db &Sqlite3, n int, x int) &KeyInfo {
	n_extra := int(u64((n + x)) * (sizeof(voidptr) + u64(1)))
	p := &KeyInfo(0)
	if (n + x > 65535) {
		return &KeyInfo(sqlite3_oom_fault(db))
	}
	p = sqlite3_db_malloc_raw_nn(db, U64(((u64(usize(__offsetof(KeyInfo, aColl)))) + u64(0) * sizeof(voidptr)) + u64(n_extra)))
	if p {
		p.aSortFlags = &U8(voidptr(unsafe { &p.aColl[0] + (n + x) }))
		p.nKeyField = U16(n)
		p.nAllField = U16((n + x))
		p.enc = db.enc
		p.db = db
		p.nRef = u32(1)
		C.memset(p.aColl, 0, u64(n_extra))
	} else {
		return &KeyInfo(sqlite3_oom_fault(db))
	}
	return p
}

@[c:'sqlite3KeyInfoUnref']
fn sqlite3_key_info_unref(p &KeyInfo) {
	if p {
		p.nRef--
		if p.nRef == u32(0) {
			sqlite3_db_nn_free_nn(p.db, voidptr(p))
		}
	}
}

@[c:'sqlite3KeyInfoRef']
fn sqlite3_key_info_ref(p &KeyInfo) &KeyInfo {
	if p {
		p.nRef++
	}
	return p
}

@[c:'sqlite3KeyInfoFromExprList']
fn sqlite3_key_info_from_expr_list(p_parse &Parse, p_list &ExprList, i_start int, n_extra int) &KeyInfo {
	n_expr := 0
	p_info := &KeyInfo(0)
	p_item := &ExprList_item(0)
	db := p_parse.db
	i := 0
	n_expr = p_list.nExpr
	p_info = sqlite3_key_info_alloc(db, n_expr - i_start, n_extra + 1)
	if p_info {
		i = i_start
		for p_item = unsafe { &p_list.a[0] } + i_start; i < n_expr; i++ {
			(&p_info.aColl[0])[i - i_start] = sqlite3_expr_nn_coll_seq(p_parse, p_item.pExpr)
			p_info.aSortFlags[i - i_start] = p_item.fg.sortFlags
			c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
		}
	}
	return p_info
}

@[c:'sqlite3SelectOpName']
fn sqlite3_select_op_name(id int) &i8 {
	z := &i8(0)
	match id {
		136 {
			z = c'UNION ALL'
		}
		138 {
			z = c'INTERSECT'
		}
		137 {
			z = c'EXCEPT'
		}
		else {
			z = c'UNION'
		}
	}

	return z
}

@[c:'explainTempTable']
fn explain_temp_table(p_parse &Parse, z_usage &i8) {
	sqlite3_vdbe_explain(p_parse, U8(0), c'USE TEMP B-TREE FOR %s', voidptr(z_usage))
}

@[c:'generateSortTail']
fn generate_sort_tail(p_parse &Parse, p &Select, p_sort &SortCtx, n_column int, p_dest &SelectDest) {
	v := p_parse.pVdbe
	addr_break := p_sort.labelDone
	addr_continue := sqlite3_vdbe_make_label(p_parse)
	addr := 0
	addr_once := 0
	i_tab := 0
	p_order_by := p_sort.pOrderBy
	e_dest := int(p_dest.eDest)
	i_parm := p_dest.iSDParm
	reg_row := 0
	reg_rowid := 0
	i_col := 0
	n_key := 0
	i_sort_tab := 0
	i := 0
	b_seq := 0
	n_ref_key := 0
	a_out_ex := unsafe { &ExprList_item(&p.pEList.a[0]) }
	n_key = p_order_by.nExpr - p_sort.nOBSat
	if p_sort.nOBSat == 0 || n_key == 1 {
		sqlite3_vdbe_explain(p_parse, U8(0), c'USE TEMP B-TREE FOR %sORDER BY', voidptr(if p_sort.nOBSat {
			c'LAST TERM OF '
		} else {
			c''
		}))
	} else {
		sqlite3_vdbe_explain(p_parse, U8(0), c'USE TEMP B-TREE FOR LAST %d TERMS OF ORDER BY', n_key)
	}
	if p_sort.labelBkOut {
		sqlite3_vdbe_add_op2(v, 10, p_sort.regReturn, p_sort.labelBkOut)
		sqlite3_vdbe_goto(v, addr_break)
		sqlite3_vdbe_resolve_label(v, p_sort.labelBkOut)
	}
	i_tab = p_sort.iECursor
	if e_dest == 7 || e_dest == 11 || e_dest == 8 {
		if e_dest == 8 && p.iOffset {
			sqlite3_vdbe_add_op2(v, 77, 0, p_dest.iSdst)
		}
		reg_rowid = 0
		reg_row = p_dest.iSdst
	} else {
		reg_rowid = sqlite3_get_temp_reg(p_parse)
		if e_dest == 10 || e_dest == 12 {
			reg_row = sqlite3_get_temp_reg(p_parse)
			n_column = 0
		} else {
			reg_row = sqlite3_get_temp_range(p_parse, n_column)
		}
	}
	if int(p_sort.sortFlags) & 1 {
		reg_sort_out := c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		mut __c2v_postfix_value_24 := p_parse.nTab
		p_parse.nTab++
		i_sort_tab = __c2v_postfix_value_24
		if p_sort.labelBkOut {
			addr_once = sqlite3_vdbe_add_op0(v, 15)
		}
		sqlite3_vdbe_add_op3(v, 123, i_sort_tab, reg_sort_out, n_key + 1 + n_column + n_ref_key)
		if addr_once {
			sqlite3_vdbe_jump_here(v, addr_once)
		}
		addr = 1 + sqlite3_vdbe_add_op2(v, 34, i_tab, addr_break)
		sqlite3_vdbe_add_op3(v, 135, i_tab, reg_sort_out, i_sort_tab)
		b_seq = 0
	} else {
		addr = 1 + sqlite3_vdbe_add_op2(v, 35, i_tab, addr_break)
		code_offset(v, p.iOffset, addr_continue)
		i_sort_tab = i_tab
		b_seq = 1
		if p.iOffset > 0 {
			sqlite3_vdbe_add_op2(v, 88, p.iLimit, -1)
		}
	}
	i = 0
	for i_col = n_key + b_seq - 1; i < n_column; i++ {
		if int(a_out_ex[i].u.x.iOrderByCol) == 0 {
			i_col++
		}
	}
	for i = n_column - 1; i >= 0; i-- {
		i_read := 0
		if a_out_ex[i].u.x.iOrderByCol {
			i_read = int(a_out_ex[i].u.x.iOrderByCol) - 1
		} else {
			mut __c2v_postfix_value_25 := i_col
			i_col--
			i_read = __c2v_postfix_value_25
		}
		sqlite3_vdbe_add_op3(v, 96, i_sort_tab, i_read, reg_row + i)
	}
	match e_dest {
		12, 10 {
			sqlite3_vdbe_add_op3(v, 96, i_sort_tab, n_key + b_seq, reg_row)
			sqlite3_vdbe_add_op2(v, 129, i_parm, reg_rowid)
			sqlite3_vdbe_add_op3(v, 130, i_parm, reg_row, reg_rowid)
			sqlite3_vdbe_change_p5(v, U16(8))
		}
		9 {
			sqlite3_vdbe_add_op4(v, 99, reg_row, n_column, reg_rowid, p_dest.zAffSdst, n_column)
			sqlite3_vdbe_add_op4_int(v, 140, i_parm, reg_rowid, reg_row, n_column)
		}
		8 {
		}
		13 {
			i2 := p_dest.iSDParm2
			r1 := sqlite3_get_temp_reg(p_parse)
			sqlite3_vdbe_add_op3(v, 99, reg_row + int((i2 < 0)), n_column - int((i2 < 0)), r1)
			if i2 < 0 {
				sqlite3_vdbe_add_op3(v, 130, i_parm, r1, reg_row)
			} else {
				sqlite3_vdbe_add_op4_int(v, 140, i_parm, r1, reg_row, i2)
			}
		}
		else {
			if e_dest == 7 {
				sqlite3_vdbe_add_op2(v, 86, p_dest.iSdst, n_column)
			} else {
				sqlite3_vdbe_add_op1(v, 12, p_dest.iSDParm)
			}
		}
	}

	if reg_rowid {
		if e_dest == 9 {
			sqlite3_release_temp_range(p_parse, reg_row, n_column)
		} else {
			sqlite3_release_temp_reg(p_parse, reg_row)
		}
		sqlite3_release_temp_reg(p_parse, reg_rowid)
	}
	sqlite3_vdbe_resolve_label(v, addr_continue)
	if int(p_sort.sortFlags) & 1 {
		sqlite3_vdbe_add_op2(v, 38, i_tab, addr)
	} else {
		sqlite3_vdbe_add_op2(v, 40, i_tab, addr)
	}
	if p_sort.regReturn {
		sqlite3_vdbe_add_op1(v, 69, p_sort.regReturn)
	}
	sqlite3_vdbe_resolve_label(v, addr_break)
}

@[c:'columnTypeImpl']
fn column_type_impl(pnc &NameContext, p_expr &Expr) &i8 {
	z_type := unsafe { &i8(nil) }
	j := 0
	match p_expr.op {
		168 {
			p_tab := unsafe { &Table(nil) }
			ps := unsafe { &Select(nil) }
			i_col := int(p_expr.iColumn)
			for !isnil(pnc) && isnil(p_tab) {
				p_tab_list := pnc.pSrcList
				for j = 0; j < p_tab_list.nSrc && c2v_at(&p_tab_list.a[0], isize(j)).iCursor != p_expr.iTable; j++ {
				}
				if j < p_tab_list.nSrc {
					p_tab = c2v_at(&p_tab_list.a[0], isize(j)).pSTab
					if c2v_at(&p_tab_list.a[0], isize(j)).fg.isSubquery {
						ps = c2v_at(&p_tab_list.a[0], isize(j)).u4.pSubq.pSelect
					} else {
						ps = 0
					}
				} else {
					pnc = pnc.pNext
				}
			}
			if usize(p_tab) == usize(0) {
				unsafe { goto c2v_switch_end_56
				 }
			}
			if ps {
				if i_col < ps.pEList.nExpr && (!0 || i_col >= 0) {
					snc := NameContext{}
					p := c2v_at(&ps.pEList.a[0], isize(i_col)).pExpr
					snc.pSrcList = ps.pSrc
					snc.pNext = pnc
					snc.pParse = pnc.pParse
					z_type = column_type_impl(&snc, p)
				}
			} else {
				if i_col < 0 {
					z_type = c'INTEGER'
				} else {
					z_type = sqlite3_column_type_vdup1(unsafe { p_tab.aCol + i_col }, unsafe { nil })
				}
			}
		}
		139 {
			snc := NameContext{}
			ps := &Select(0)
			p := &Expr(0)
			ps = p_expr.x.pSelect
			p = c2v_at(&ps.pEList.a[0], isize(0)).pExpr
			snc.pSrcList = ps.pSrc
			snc.pNext = pnc
			snc.pParse = pnc.pParse
			z_type = column_type_impl(&snc, p)
		}
		else {}
	}
	c2v_switch_end_56:

	return z_type
}

@[c:'generateColumnTypes']
fn generate_column_types(p_parse &Parse, p_tab_list &SrcList, pel_ist &ExprList) {
	v := p_parse.pVdbe
	i := 0
	snc := NameContext{}
	snc.pSrcList = p_tab_list
	snc.pParse = p_parse
	snc.pNext = 0
	for i = 0; i < pel_ist.nExpr; i++ {
		p := c2v_at(&pel_ist.a[0], isize(i)).pExpr
		z_type := &i8(0)
		z_type = column_type_impl(&snc, p)
		sqlite3_vdbe_set_col_name(v, i, 1, z_type, (C2vFn_666e2028766f696470747229(voidptr(-1))))
	}
}

@[c:'sqlite3GenerateColumnNames']
fn sqlite3_generate_column_names(p_parse &Parse, p_select &Select) {
	v := p_parse.pVdbe
	i := 0
	p_tab := &Table(0)
	p_tab_list := &SrcList(0)
	pel_ist := &ExprList(0)
	db := p_parse.db
	full_name := 0
	src_name := 0
	if p_parse.colNamesSet {
		return
	}
	for p_select.pPrior {
		p_select = p_select.pPrior
	}
	p_tab_list = p_select.pSrc
	pel_ist = p_select.pEList
	p_parse.colNamesSet = Bft(1)
	full_name = (db.flags & U64(4)) != U64(0)
	src_name = (db.flags & U64(64)) != U64(0) || full_name
	sqlite3_vdbe_set_num_cols(v, pel_ist.nExpr)
	for i = 0; i < pel_ist.nExpr; i++ {
		p := c2v_at(&pel_ist.a[0], isize(i)).pExpr
		if !isnil(c2v_at(&pel_ist.a[0], isize(i)).zEName) && int(c2v_at(&pel_ist.a[0], isize(i)).fg.eEName) == 0 {
			z_name := c2v_at(&pel_ist.a[0], isize(i)).zEName
			sqlite3_vdbe_set_col_name(v, i, 0, z_name, (C2vFn_666e2028766f696470747229(voidptr(-1))))
		} else if src_name && int(p.op) == 168 {
			z_col := &i8(0)
			i_col := int(p.iColumn)
			p_tab = p.y.pTab
			if i_col < 0 {
				i_col = int(p_tab.iPKey)
			}
			if i_col < 0 {
				z_col = c'rowid'
			} else {
				z_col = p_tab.aCol[i_col].zCnName
			}
			if full_name {
				z_name := unsafe { &i8(nil) }
				z_name = sqlite3_mp_rintf(db, c'%s.%s', voidptr(p_tab.zName), voidptr(z_col))
				sqlite3_vdbe_set_col_name(v, i, 0, z_name, (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))))
			} else {
				sqlite3_vdbe_set_col_name(v, i, 0, z_col, (C2vFn_666e2028766f696470747229(voidptr(-1))))
			}
		} else {
			z := c2v_at(&pel_ist.a[0], isize(i)).zEName
			z = if usize(z) == usize(0) {
				sqlite3_mp_rintf(db, c'column%d', i + 1)
			} else {
				sqlite3_db_str_dup(db, z)
			}
			sqlite3_vdbe_set_col_name(v, i, 0, z, (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))))
		}
	}
	generate_column_types(p_parse, p_tab_list, pel_ist)
}

@[c:'sqlite3ColumnsFromExprList']
fn sqlite3_columns_from_expr_list(p_parse &Parse, pel_ist &ExprList, pn_col &I16, pa_col &&Column) int {
	db := p_parse.db
	i := 0
	j := 0

	cnt := u32(0)
	a_col := &Column(0)
	p_col := &Column(0)

	n_col := 0
	z_name := &i8(0)
	n_name := 0
	ht := Hash{}
	p_tab := &Table(0)
	sqlite3_hash_init(&ht)
	if pel_ist {
		n_col = pel_ist.nExpr
		a_col = sqlite3_db_malloc_zero(db, U64(sizeof(Column) * u64(n_col)))
		if (n_col > 32767) {
			n_col = 32767
		}
	} else {
		n_col = 0
		a_col = 0
	}
	unsafe { *pn_col = I16(n_col) }
	unsafe { *pa_col = a_col }
	i = 0
	for p_col = a_col; i < n_col && !p_parse.nErr; i++ {
		px := unsafe { &pel_ist.a[0] + i }
		p_collide := &ExprList_item(0)
		z_name = px.zEName
		if usize(z_name) != usize(0) && int(px.fg.eEName) == 0 {
		} else {
			p_col_expr := sqlite3_expr_skip_collate_and_likely(px.pExpr)
			for (usize(p_col_expr) != usize(0)) && int(p_col_expr.op) == 142 {
				p_col_expr = p_col_expr.pRight
			}
			if int(p_col_expr.op) == 168 && ((p_col_expr.flags & u32((16777216 | 33554432))) == u32(0)) && (usize(p_col_expr.y.pTab) != usize(0)) {
				i_col := int(p_col_expr.iColumn)
				p_tab = p_col_expr.y.pTab
				if i_col < 0 {
					i_col = int(p_tab.iPKey)
				}
				z_name = if i_col >= 0 { p_tab.aCol[i_col].zCnName } else { c'rowid' }
			} else if int(p_col_expr.op) == 60 {
				z_name = p_col_expr.u.zToken
			} else {
			}
		}
		if !isnil(z_name) && !sqlite3_is_trueor_false(z_name) {
			z_name = sqlite3_db_str_dup(db, z_name)
		} else {
			z_name = sqlite3_mp_rintf(db, c'column%d', i + 1)
		}
		cnt = u32(0)
		for {
			if !(!isnil(z_name) && usize(c2v_assign[&ExprList_item](unsafe { &p_collide }, sqlite3_hash_find(&ht, z_name))) != usize(0)) {
				break
			}
			if p_collide.fg.bUsingTerm {
				p_col.colFlags |= 1024
			}
			n_name = sqlite3_strlen30(z_name)
			if n_name > 0 {
				for j = n_name - 1; j > 0 && (int(sqlite3CtypeMap[u8(z_name[j])]) & 4); j-- {
				}
				if int(z_name[j]) == i8(`:`) {
					n_name = j
				}
			}
			z_name = sqlite3_mp_rintf(db, c'%.*z:%u', n_name, voidptr(z_name), c2v_prefix_add(unsafe { &cnt }, u32(1)))
			sqlite3_progress_check(p_parse)
			if cnt > u32(3) {
				sqlite3_randomness(int(sizeof(cnt)), voidptr(&cnt))
			}
		}
		p_col.zCnName = z_name
		p_col.hName = sqlite3_str_ih_ash(z_name)
		if px.fg.bNoExpand {
			p_col.colFlags |= 1024
		}
		if !isnil(z_name) && usize(sqlite3_hash_insert(&ht, z_name, voidptr(px))) == usize(px) {
			sqlite3_oom_fault(db)
		}
		c2v_pointer_postfix(voidptr(&p_col), p_col, isize(1))
	}
	sqlite3_hash_clear(&ht)
	if p_parse.nErr {
		for j = 0; j < i; j++ {
			sqlite3_db_free(db, voidptr(a_col[j].zCnName))
		}
		sqlite3_db_free(db, voidptr(a_col))
		unsafe { *pa_col = 0 }
		unsafe { *pn_col = I16(0) }
		return p_parse.rc
	}
	return 0
}

@[c:'sqlite3SubqueryColumnTypes']
fn sqlite3_subquery_column_types(p_parse &Parse, p_tab &Table, p_select &Select, aff i8) {
	db := p_parse.db
	p_col := &Column(0)
	p_coll := &CollSeq(0)
	i := 0
	j := 0

	p := &Expr(0)
	a := &ExprList_item(0)
	snc := NameContext{}
	if int(db.mallocFailed) || (int(p_parse.eParseMode) >= 2) {
		return
	}
	for p_select.pPrior {
		p_select = p_select.pPrior
	}
	a = unsafe { &p_select.pEList.a[0] }
	C.memset(voidptr(&snc), 0, sizeof(snc))
	snc.pSrcList = p_select.pSrc
	i = 0
	for p_col = p_tab.aCol; i < int(p_tab.nCol); i++ {
		z_type := &i8(0)
		n := I64(0)
		m := 0
		p_s2 := p_select
		p_tab.tabFlags |= u32((int(p_col.colFlags) & 98))
		p = a[i].pExpr
		p_col.affinity = sqlite3_expr_affinity(p)
		for int(p_col.affinity) <= 64 && usize(p_s2.pNext) != usize(0) {
			m |= sqlite3_expr_data_type(c2v_at(&p_s2.pEList.a[0], isize(i)).pExpr)
			p_s2 = p_s2.pNext
			p_col.affinity = sqlite3_expr_affinity(c2v_at(&p_s2.pEList.a[0], isize(i)).pExpr)
		}
		if int(p_col.affinity) <= 64 {
			p_col.affinity = aff
		}
		if int(p_col.affinity) >= 66 && (!isnil(p_s2.pNext) || usize(p_s2) != usize(p_select)) {
			for p_s2 = p_s2.pNext; p_s2; p_s2 = p_s2.pNext {
				m |= sqlite3_expr_data_type(c2v_at(&p_s2.pEList.a[0], isize(i)).pExpr)
			}
			if int(p_col.affinity) == 66 && (m & 1) != 0 {
				p_col.affinity = i8(65)
			} else if int(p_col.affinity) >= 67 && (m & 2) != 0 {
				p_col.affinity = i8(65)
			}
			if int(p_col.affinity) >= 67 && int(p.op) == 36 {
				p_col.affinity = i8(70)
			}
		}
		z_type = column_type_impl(&snc, p)
		if usize(z_type) == usize(0) || int(p_col.affinity) != int(sqlite3_affinity_type(z_type, unsafe { nil })) {
			if int(p_col.affinity) == 67 || int(p_col.affinity) == 70 {
				z_type = c'NUM'
			} else {
				z_type = 0
				for j = 1; j < 6; j++ {
					if int(sqlite3_std_type_affinity[j]) == int(p_col.affinity) {
						z_type = sqlite3StdType[j]
						break
					}
				}
			}
		}
		if z_type {
			k := I64(C.strlen(z_type))
			n = I64(C.strlen(p_col.zCnName))
			p_col.zCnName = &i8(sqlite3_db_realloc_or_free(db, voidptr(p_col.zCnName), U64(n + k + I64(2))))
			p_col.colFlags &= ~(4 | 512)
			if p_col.zCnName {
				C.memcpy(voidptr(unsafe { p_col.zCnName + (n + I64(1)) }), voidptr(z_type), u64(k + I64(1)))
				p_col.colFlags |= 4
			}
		}
		p_coll = sqlite3_expr_coll_seq(p_parse, p)
		if p_coll {
			sqlite3_column_set_coll(db, p_col, p_coll.zName)
		}
		c2v_pointer_postfix(voidptr(&p_col), p_col, isize(1))
	}
	p_tab.szTabRow = LogEst(1)
}

@[c:'sqlite3ResultSetOfSelect']
fn sqlite3_result_set_of_select(p_parse &Parse, p_select &Select, aff i8) &Table {
	p_tab := &Table(0)
	db := p_parse.db
	saved_flags := U64(0)
	p_parse.nNestSel++
	if p_parse.nNestSel >= db.aLimit[3] {
		sqlite3_error_msg(p_parse, c'VIEWs and/or subqueries nested too deep')
		return unsafe { nil }
	}
	saved_flags = db.flags
	db.flags &= ~U64(4)
	db.flags |= U64(64)
	sqlite3_select_prep(p_parse, p_select, unsafe { nil })
	db.flags = saved_flags
	if p_parse.nErr {
		return unsafe { nil }
	}
	for p_select.pPrior {
		p_select = p_select.pPrior
	}
	p_tab = sqlite3_db_malloc_zero(db, U64(sizeof(Table)))
	if usize(p_tab) == usize(0) {
		return unsafe { nil }
	}
	p_tab.nTabRef = u32(1)
	p_tab.zName = 0
	p_tab.nRowLogEst = LogEst(200)
	sqlite3_columns_from_expr_list(p_parse, p_select.pEList, &p_tab.nCol, &&Column(&p_tab.aCol))
	sqlite3_subquery_column_types(p_parse, p_tab, p_select, i8(aff))
	p_tab.iPKey = I16(-1)
	if db.mallocFailed {
		sqlite3_delete_table(db, p_tab)
		return unsafe { nil }
	}
	p_parse.nNestSel--
	return p_tab
}

@[c:'sqlite3GetVdbe']
fn sqlite3_get_vdbe(p_parse &Parse) &Vdbe {
	if p_parse.pVdbe {
		return p_parse.pVdbe
	}
	if usize(p_parse.pToplevel) == usize(0) && ((p_parse.db.dbOptFlags & u32(8)) == u32(0)) {
		p_parse.okConstFactor = Bft(1)
	}
	return sqlite3_vdbe_create(p_parse)
}

@[c:'computeLimitRegisters']
fn compute_limit_registers(p_parse &Parse, p &Select, i_break int) {
	v := unsafe { &Vdbe(nil) }
	i_limit := 0
	i_offset := 0
	n := 0
	p_limit := p.pLimit
	if p.iLimit {
		return
	}
	if p_limit {
		i_limit = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		p.iLimit = i_limit
		v = sqlite3_get_vdbe(p_parse)
		if sqlite3_expr_is_integer(p_limit.pLeft, &n, p_parse) {
			sqlite3_vdbe_add_op2(v, 73, n, i_limit)
			if n == 0 {
				sqlite3_vdbe_goto(v, i_break)
			} else if n >= 0 && int(p.nSelectRow) > int(sqlite3_log_est(U64(n))) {
				p.nSelectRow = sqlite3_log_est(U64(n))
				p.selFlags |= u32(16384)
			}
		} else {
			sqlite3_expr_code(p_parse, p_limit.pLeft, i_limit)
			sqlite3_vdbe_add_op1(v, 13, i_limit)
			sqlite3_vdbe_add_op2(v, 17, i_limit, i_break)
		}
		if p_limit.pRight {
			i_offset = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			p.iOffset = i_offset
			p_parse.nMem++
			sqlite3_expr_code(p_parse, p_limit.pRight, i_offset)
			sqlite3_vdbe_add_op1(v, 13, i_offset)
			sqlite3_vdbe_add_op3(v, 162, i_limit, i_offset + 1, i_offset)
		}
	}
}

@[c:'multiSelectCollSeq']
fn multi_select_coll_seq(p_parse &Parse, p &Select, i_col int) &CollSeq {
	p_ret := &CollSeq(0)
	if p.pPrior {
		p_ret = multi_select_coll_seq(p_parse, p.pPrior, i_col)
	} else {
		p_ret = 0
	}
	if usize(p_ret) == usize(0) && (i_col < p.pEList.nExpr) {
		p_ret = sqlite3_expr_coll_seq(p_parse, c2v_at(&p.pEList.a[0], isize(i_col)).pExpr)
	}
	return p_ret
}

@[c:'multiSelectByMergeKeyInfo']
fn multi_select_by_merge_key_info(p_parse &Parse, p &Select, n_extra int) &KeyInfo {
	p_order_by := p.pOrderBy
	n_order_by := if (usize(p_order_by) != usize(0)) { p_order_by.nExpr } else { 0 }
	db := p_parse.db
	p_ret := sqlite3_key_info_alloc(db, n_order_by + n_extra, 1)
	if p_ret {
		i := 0
		for i = 0; i < n_order_by; i++ {
			p_item := unsafe { &p_order_by.a[0] + i }
			p_term := p_item.pExpr
			p_coll := &CollSeq(0)
			if p_term.flags & u32(512) {
				p_coll = sqlite3_expr_coll_seq(p_parse, p_term)
			} else {
				p_coll = multi_select_coll_seq(p_parse, p, int(p_item.u.x.iOrderByCol) - 1)
				if usize(p_coll) == usize(0) {
					p_coll = db.pDfltColl
				}
				mut __c2v_lhs_tmp_136 := c2v_at(&p_order_by.a[0], isize(i))
				__c2v_lhs_tmp_136.pExpr = sqlite3_expr_add_collate_string(p_parse, p_term, p_coll.zName)
			}
			(&p_ret.aColl[0])[i] = p_coll
			p_ret.aSortFlags[i] = c2v_at(&p_order_by.a[0], isize(i)).fg.sortFlags
		}
	}
	return p_ret
}

@[c:'generateWithRecursiveQuery']
fn generate_with_recursive_query(p_parse &Parse, p &Select, p_dest &SelectDest) {
	p_src := p.pSrc
	n_col := p.pEList.nExpr
	v := p_parse.pVdbe
	p_setup := &Select(0)
	p_first_rec := &Select(0)
	addr_top := 0
	addr_cont := 0
	addr_break := 0

	i_current := 0
	reg_current := 0
	i_queue := 0
	i_distinct := 0
	e_dest := 6
	dest_queue := SelectDest{}
	i := 0
	rc := 0
	p_order_by := &ExprList(0)
	p_limit := &Expr(0)
	reg_limit := 0
	reg_offset := 0

	if p.pWin {
		sqlite3_error_msg(p_parse, c'cannot use window functions in recursive queries')
		return
	}
	if sqlite3_auth_check(p_parse, 33, unsafe { nil }, unsafe { nil }, unsafe { nil }) {
		return
	}
	addr_break = sqlite3_vdbe_make_label(p_parse)
	p.nSelectRow = LogEst(320)
	compute_limit_registers(p_parse, p, addr_break)
	p_limit = p.pLimit
	reg_limit = p.iLimit
	reg_offset = p.iOffset
	p.pLimit = 0
	p.iOffset = 0
	p.iLimit = p.iOffset
	p_order_by = p.pOrderBy
	for i = 0; (i < p_src.nSrc); i++ {
		if c2v_at(&p_src.a[0], isize(i)).fg.isRecursive {
			i_current = c2v_at(&p_src.a[0], isize(i)).iCursor
			break
		}
	}
	mut __c2v_postfix_value_26 := p_parse.nTab
	p_parse.nTab++
	i_queue = __c2v_postfix_value_26
	if int(p.op) == 135 {
		e_dest = if p_order_by { 4 } else { 3 }
		mut __c2v_postfix_value_27 := p_parse.nTab
		p_parse.nTab++
		i_distinct = __c2v_postfix_value_27
	} else {
		e_dest = if p_order_by { 5 } else { 6 }
	}
	sqlite3_select_dest_init(&dest_queue, e_dest, i_queue)
	reg_current = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	sqlite3_vdbe_add_op3(v, 123, i_current, reg_current, n_col)
	if p_order_by {
		p_key_info := multi_select_by_merge_key_info(p_parse, p, 1)
		sqlite3_vdbe_add_op4(v, 120, i_queue, p_order_by.nExpr + 2, 0, &i8(voidptr(p_key_info)), (-9))
		dest_queue.pOrderBy = p_order_by
	} else {
		sqlite3_vdbe_add_op2(v, 120, i_queue, n_col)
	}
	if i_distinct {
		p_key_info := &KeyInfo(0)
		ap_coll := &&CollSeq(0)
		n_col = p.pEList.nExpr
		p_key_info = sqlite3_key_info_alloc(p_parse.db, n_col, 1)
		if p_key_info {
			i = 0
			for ap_coll = unsafe { &p_key_info.aColl[0] }; i < n_col; i++ {
				unsafe { *ap_coll = multi_select_coll_seq(p_parse, p, i) }
				if usize(0) == usize((unsafe { *ap_coll })) {
					unsafe { *ap_coll = p_parse.db.pDfltColl }
				}
				c2v_pointer_postfix(voidptr(&ap_coll), ap_coll, isize(1))
			}
			sqlite3_vdbe_add_op4(v, 120, i_distinct, n_col, 0, &i8(voidptr(p_key_info)), (-9))
		} else {
		}
	}
	p.pOrderBy = 0
	for p_first_rec = p; (usize(p_first_rec) != usize(0)); p_first_rec = p_first_rec.pPrior {
		if p_first_rec.selFlags & u32(8) {
			sqlite3_error_msg(p_parse, c'recursive aggregate queries not supported')
			unsafe { goto end_of_recursive_query
			 }
		}
		p_first_rec.op = U8(136)
		if (p_first_rec.pPrior.selFlags & u32(8192)) == u32(0) {
			break
		}
	}
	p_setup = p_first_rec.pPrior
	p_setup.pNext = 0
	sqlite3_vdbe_explain(p_parse, U8(1), c'SETUP')
	rc = sqlite3_select(p_parse, p_setup, &dest_queue)
	p_setup.pNext = p
	if rc {
		unsafe { goto end_of_recursive_query
		 }
	}
	addr_top = sqlite3_vdbe_add_op2(v, 36, i_queue, addr_break)
	sqlite3_vdbe_add_op1(v, 138, i_current)
	if p_order_by {
		sqlite3_vdbe_add_op3(v, 96, i_queue, p_order_by.nExpr + 1, reg_current)
	} else {
		sqlite3_vdbe_add_op2(v, 136, i_queue, reg_current)
	}
	sqlite3_vdbe_add_op1(v, 132, i_queue)
	addr_cont = sqlite3_vdbe_make_label(p_parse)
	code_offset(v, reg_offset, addr_cont)
	select_inner_loop(p_parse, p, i_current, unsafe { nil }, unsafe { nil }, p_dest, addr_cont, addr_break)
	if reg_limit {
		sqlite3_vdbe_add_op2(v, 63, reg_limit, addr_break)
	}
	sqlite3_vdbe_resolve_label(v, addr_cont)
	p_first_rec.pPrior = 0
	sqlite3_vdbe_explain(p_parse, U8(1), c'RECURSIVE STEP')
	sqlite3_select(p_parse, p, &dest_queue)
	p_first_rec.pPrior = p_setup
	sqlite3_vdbe_goto(v, addr_top)
	sqlite3_vdbe_resolve_label(v, addr_break)
	end_of_recursive_query:
	sqlite3_expr_list_delete(p_parse.db, p.pOrderBy)
	p.pOrderBy = p_order_by
	p.pLimit = p_limit
	return
}

@[c:'multiSelectValues']
fn multi_select_values(p_parse &Parse, p &Select, p_dest &SelectDest) int {
	n_row := 1
	rc := 0
	b_show_all := int(usize(p.pLimit) == usize(0))
	for {
		if p.pWin {
			return -1
		}
		if usize(p.pPrior) == usize(0) {
			break
		}
		p = p.pPrior
		n_row += b_show_all
	}
	sqlite3_vdbe_explain(p_parse, U8(0), c'SCAN %d CONSTANT ROW%s', n_row, voidptr(if n_row == 1 {
		c''
	} else {
		c'S'
	}))
	for p {
		select_inner_loop(p_parse, p, -1, unsafe { nil }, unsafe { nil }, p_dest, 1, 1)
		if !b_show_all {
			break
		}
		p.nSelectRow = LogEst(n_row)
		p = p.pNext
	}
	return rc
}

@[c:'hasAnchor']
fn has_anchor(p &Select) int {
	for !isnil(p) && (p.selFlags & u32(8192)) != u32(0) {
		p = p.pPrior
	}
	return int(usize(p) != usize(0))
}

@[c:'multiSelect']
fn multi_select(p_parse &Parse, p &Select, p_dest &SelectDest) int {
	rc := 0
	p_prior := &Select(0)
	v := &Vdbe(0)
	dest := SelectDest{}
	p_delete := unsafe { &Select(nil) }
	db := &Sqlite3(0)
	db = p_parse.db
	p_prior = p.pPrior
	dest = unsafe { *p_dest }
	v = sqlite3_get_vdbe(p_parse)
	if int(dest.eDest) == 10 {
		sqlite3_vdbe_add_op2(v, 120, dest.iSDParm, p.pEList.nExpr)
		dest.eDest = U8(12)
	}
	if p.selFlags & u32(1024) {
		rc = multi_select_values(p_parse, p, &dest)
		if rc >= 0 {
			unsafe { goto multi_select_end
			 }
		}
		rc = 0
	}
	if (p.selFlags & u32(8192)) != u32(0) && has_anchor(p) {
		generate_with_recursive_query(p_parse, p, &dest)
	} else if p.pOrderBy {
		return multi_select_by_merge(p_parse, p, p_dest)
	} else if int(p.op) != 136 {
		p_one := sqlite3_expr_int32(db, 1)
		p.pOrderBy = sqlite3_expr_list_append(p_parse, unsafe { nil }, p_one)
		if p_parse.nErr {
			unsafe { goto multi_select_end
			 }
		}
		mut __c2v_lhs_tmp_137 := c2v_at(&p.pOrderBy.a[0], isize(0))
		__c2v_lhs_tmp_137.u.x.iOrderByCol = U16(1)
		return multi_select_by_merge(p_parse, p, p_dest)
	} else {
		addr := 0
		n_limit := 0
		if usize(p_prior.pPrior) == usize(0) {
			sqlite3_vdbe_explain(p_parse, U8(1), c'COMPOUND QUERY')
			sqlite3_vdbe_explain(p_parse, U8(1), c'LEFT-MOST SUBQUERY')
		}
		p_prior.iLimit = p.iLimit
		p_prior.iOffset = p.iOffset
		p_prior.pLimit = sqlite3_expr_dup(db, p.pLimit, 0)
		rc = sqlite3_select(p_parse, p_prior, &dest)
		sqlite3_expr_delete(db, p_prior.pLimit)
		p_prior.pLimit = 0
		if rc {
			unsafe { goto multi_select_end
			 }
		}
		p.pPrior = 0
		p.iLimit = p_prior.iLimit
		p.iOffset = p_prior.iOffset
		if p.iLimit {
			addr = sqlite3_vdbe_add_op1(v, 17, p.iLimit)
			if p.iOffset {
				sqlite3_vdbe_add_op3(v, 162, p.iLimit, p.iOffset + 1, p.iOffset)
			}
		}
		sqlite3_vdbe_explain(p_parse, U8(1), c'UNION ALL')
		rc = sqlite3_select(p_parse, p, &dest)
		p_delete = p.pPrior
		p.pPrior = p_prior
		p.nSelectRow = sqlite3_log_est_add(p.nSelectRow, p_prior.nSelectRow)
		if !isnil(p.pLimit) && sqlite3_expr_is_integer(p.pLimit.pLeft, &n_limit, p_parse) && n_limit > 0 && int(p.nSelectRow) > int(sqlite3_log_est(U64(n_limit))) {
			p.nSelectRow = sqlite3_log_est(U64(n_limit))
		}
		if addr {
			sqlite3_vdbe_jump_here(v, addr)
		}
		if usize(p.pNext) == usize(0) {
			sqlite3_vdbe_explain_pop(p_parse)
		}
	}
	multi_select_end:
	p_dest.iSdst = dest.iSdst
	p_dest.nSdst = dest.nSdst
	p_dest.iSDParm2 = dest.iSDParm2
	if p_delete {
		sqlite3_parser_add_cleanup(p_parse, sqlite3_select_delete_generic, voidptr(p_delete))
	}
	return rc
}

@[c:'sqlite3SelectWrongNumTermsError']
fn sqlite3_select_wrong_num_terms_error(p_parse &Parse, p &Select) {
	if p.selFlags & u32(512) {
		sqlite3_error_msg(p_parse, c'all VALUES must have the same number of terms')
	} else {
		sqlite3_error_msg(p_parse, c'SELECTs to the left and right of %s do not have the same number of result columns', voidptr(sqlite3_select_op_name(int(p.op))))
	}
}

@[c:'generateOutputSubroutine']
fn generate_output_subroutine(p_parse &Parse, p &Select, p_in &SelectDest, p_dest &SelectDest, reg_return int, reg_prev int, p_key_info &KeyInfo, i_break int) int {
	v := p_parse.pVdbe
	i_continue := 0
	addr := 0
	addr = sqlite3_vdbe_current_addr(v)
	i_continue = sqlite3_vdbe_make_label(p_parse)
	if reg_prev {
		addr1 := 0
		addr2 := 0

		addr1 = sqlite3_vdbe_add_op1(v, 17, reg_prev)
		addr2 = sqlite3_vdbe_add_op4(v, 92, p_in.iSdst, reg_prev + 1, p_in.nSdst, &i8(voidptr(sqlite3_key_info_ref(p_key_info))), (-9))
		sqlite3_vdbe_add_op3(v, 14, addr2 + 2, i_continue, addr2 + 2)
		sqlite3_vdbe_jump_here(v, addr1)
		sqlite3_vdbe_add_op3(v, 82, p_in.iSdst, reg_prev + 1, p_in.nSdst - 1)
		sqlite3_vdbe_add_op2(v, 73, 1, reg_prev)
	}
	if p_parse.db.mallocFailed {
		return 0
	}
	code_offset(v, p.iOffset, i_continue)
	match p_dest.eDest {
		6, 3, 12, 10 {
			r1 := sqlite3_get_temp_reg(p_parse)
			r2 := sqlite3_get_temp_reg(p_parse)
			i_parm := p_dest.iSDParm
			sqlite3_vdbe_add_op3(v, 99, p_in.iSdst, p_in.nSdst, r1)
			if int(p_dest.eDest) == 3 {
				sqlite3_vdbe_add_op4_int(v, 140, i_parm + 1, r1, p_in.iSdst, p_in.nSdst)
			}
			sqlite3_vdbe_add_op2(v, 129, i_parm, r2)
			sqlite3_vdbe_add_op3(v, 130, i_parm, r1, r2)
			sqlite3_vdbe_change_p5(v, U16(8))
			sqlite3_release_temp_reg(p_parse, r2)
			sqlite3_release_temp_reg(p_parse, r1)
		}
		1 {
			sqlite3_vdbe_add_op2(v, 73, 1, p_dest.iSDParm)
		}
		9 {
			r1_2 := 0
			r1_2 = sqlite3_get_temp_reg(p_parse)
			sqlite3_vdbe_add_op4(v, 99, p_in.iSdst, p_in.nSdst, r1_2, p_dest.zAffSdst, p_in.nSdst)
			sqlite3_vdbe_add_op4_int(v, 140, p_dest.iSDParm, r1_2, p_in.iSdst, p_in.nSdst)
			if p_dest.iSDParm2 > 0 {
				sqlite3_vdbe_add_op4_int(v, 185, p_dest.iSDParm2, 0, p_in.iSdst, p_in.nSdst)
				sqlite3_vdbe_explain(p_parse, U8(0), c'CREATE BLOOM FILTER')
			}
			sqlite3_release_temp_reg(p_parse, r1_2)
		}
		8 {
			sqlite3_expr_code_move(p_parse, p_in.iSdst, p_dest.iSDParm, p_in.nSdst)
		}
		11 {
			if p_dest.iSdst == 0 {
				p_dest.iSdst = sqlite3_get_temp_range(p_parse, p_in.nSdst)
				p_dest.nSdst = p_in.nSdst
			}
			sqlite3_expr_code_move(p_parse, p_in.iSdst, p_dest.iSdst, p_in.nSdst)
			sqlite3_vdbe_add_op1(v, 12, p_dest.iSDParm)
		}
		4, 5 {
			n_key := 0
			r1_2 := 0
			r2_2 := 0
			r3 := 0
			ii := 0

			pso := &ExprList(0)
			i_parm_2 := p_dest.iSDParm
			pso = p_dest.pOrderBy
			n_key = pso.nExpr
			r1_2 = sqlite3_get_temp_reg(p_parse)
			r2_2 = sqlite3_get_temp_range(p_parse, n_key + 2)
			r3 = r2_2 + n_key + 1
			sqlite3_vdbe_add_op3(v, 99, p_in.iSdst, p_in.nSdst, r3)
			if int(p_dest.eDest) == 4 {
				sqlite3_vdbe_add_op2(v, 140, i_parm_2 + 1, r3)
			}
			for ii = 0; ii < n_key; ii++ {
				sqlite3_vdbe_add_op2(v, 83, p_in.iSdst + int(c2v_at(&pso.a[0], isize(ii)).u.x.iOrderByCol) - 1, r2_2 + ii)
			}
			sqlite3_vdbe_add_op2(v, 128, i_parm_2, r2_2 + n_key)
			sqlite3_vdbe_add_op3(v, 99, r2_2, n_key + 2, r1_2)
			sqlite3_vdbe_add_op4_int(v, 140, i_parm_2, r1_2, r2_2, n_key + 2)
			sqlite3_release_temp_reg(p_parse, r1_2)
			sqlite3_release_temp_range(p_parse, r2_2, n_key + 2)
		}
		2 {
		}
		else {
			sqlite3_vdbe_add_op2(v, 86, p_in.iSdst, p_in.nSdst)
		}
	}

	if p.iLimit {
		sqlite3_vdbe_add_op2(v, 63, p.iLimit, i_break)
	}
	sqlite3_vdbe_resolve_label(v, i_continue)
	sqlite3_vdbe_add_op1(v, 69, reg_return)
	return addr
}

@[c:'multiSelectByMerge']
fn multi_select_by_merge(p_parse &Parse, p &Select, p_dest &SelectDest) int {
	i := 0
	j := 0

	p_prior := &Select(0)
	p_split := &Select(0)
	n_select := 0
	v := &Vdbe(0)
	dest_a := SelectDest{}
	dest_b := SelectDest{}
	reg_addr_a := 0
	reg_addr_b := 0
	addr_select_a := 0
	addr_select_b := 0
	reg_out_a := 0
	reg_out_b := 0
	addr_out_a := 0
	addr_out_b := 0
	addr_eof_a := 0
	addr_eof_a_no_b := 0
	addr_eof_b := 0
	addr_alt_b := 0
	addr_aeq_b := 0
	addr_agt_b := 0
	reg_limit_a := 0
	reg_limit_b := 0
	reg_prev := 0
	saved_limit := 0
	saved_offset := 0
	label_cmpr := 0
	label_end := 0
	addr1 := 0
	op := 0
	p_key_dup := unsafe { &KeyInfo(nil) }
	p_key_merge := &KeyInfo(0)
	db := &Sqlite3(0)
	p_order_by := &ExprList(0)
	n_order_by := 0
	a_permute := &u32(0)
	db = p_parse.db
	v = p_parse.pVdbe
	label_end = sqlite3_vdbe_make_label(p_parse)
	label_cmpr = sqlite3_vdbe_make_label(p_parse)
	op = int(p.op)
	p_order_by = p.pOrderBy
	n_order_by = p_order_by.nExpr
	if op != 136 {
		for i = 1; int(db.mallocFailed) == 0 && i <= p.pEList.nExpr; i++ {
			p_item := &ExprList_item(0)
			j = 0
			for p_item = unsafe { &p_order_by.a[0] }; j < n_order_by; j++ {
				if int(p_item.u.x.iOrderByCol) == i {
					break
				}
				c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
			}
			if j == n_order_by {
				p_new := sqlite3_expr_int32(db, i)
				if usize(p_new) == usize(0) {
					return 7
				}
				p_order_by = sqlite3_expr_list_append(p_parse, p_order_by, p_new)
				p.pOrderBy = p_order_by
				if p_order_by {
					mut __c2v_lhs_tmp_138 := c2v_at(&p_order_by.a[0], isize(n_order_by++))
					__c2v_lhs_tmp_138.u.x.iOrderByCol = U16(i)
				}
			}
		}
	}
	a_permute = sqlite3_db_malloc_raw_nn(db, U64(sizeof(u32) * u64((n_order_by + 1))))
	if a_permute {
		p_item := &ExprList_item(0)
		b_keep := 0
		a_permute[0] = u32(n_order_by)
		i = 1
		for p_item = unsafe { &p_order_by.a[0] }; i <= n_order_by; i++ {
			a_permute[i] = u32(int(p_item.u.x.iOrderByCol) - 1)
			if a_permute[i] != u32(i) - u32(1) {
				b_keep = 1
			}
			c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
		}
		if b_keep == 0 {
			sqlite3_db_free_nn(db, voidptr(a_permute))
			a_permute = 0
		}
	}
	p_key_merge = multi_select_by_merge_key_info(p_parse, p, 1)
	if op == 136 {
		reg_prev = 0
	} else {
		n_expr := p.pEList.nExpr
		reg_prev = p_parse.nMem + 1
		p_parse.nMem += n_expr + 1
		sqlite3_vdbe_add_op2(v, 73, 0, reg_prev)
		p_key_dup = sqlite3_key_info_alloc(db, n_expr, 1)
		if p_key_dup {
			for i = 0; i < n_expr; i++ {
				(&p_key_dup.aColl[0])[i] = multi_select_coll_seq(p_parse, p, i)
				p_key_dup.aSortFlags[i] = U8(0)
			}
		}
	}
	n_select = 1
	if (op == 136 || op == 135) && ((db.dbOptFlags & u32(2097152)) == u32(0)) {
		for p_split = p; usize(p_split.pPrior) != usize(0) && int(p_split.op) == op; p_split = p_split.pPrior {
			n_select++
		}
	}
	if n_select <= 3 {
		p_split = p
	} else {
		p_split = p
		for i = 2; i < n_select; i += 2 {
			p_split = p_split.pPrior
		}
	}
	p_prior = p_split.pPrior
	p_split.pPrior = 0
	p_prior.pNext = 0
	p_prior.pOrderBy = sqlite3_expr_list_dup(p_parse.db, p_order_by, 0)
	sqlite3_resolve_order_group_by(p_parse, p, p.pOrderBy, c'ORDER')
	sqlite3_resolve_order_group_by(p_parse, p_prior, p_prior.pOrderBy, c'ORDER')
	compute_limit_registers(p_parse, p, label_end)
	if p.iLimit && op == 136 {
		reg_limit_a = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		reg_limit_b = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		sqlite3_vdbe_add_op2(v, 82, if p.iOffset { p.iOffset + 1 } else { p.iLimit }, reg_limit_a)
		sqlite3_vdbe_add_op2(v, 82, reg_limit_a, reg_limit_b)
	} else {
		reg_limit_b = 0
		reg_limit_a = reg_limit_b
	}
	sqlite3_expr_delete(db, p.pLimit)
	p.pLimit = 0
	reg_addr_a = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	reg_addr_b = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	reg_out_a = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	reg_out_b = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	sqlite3_select_dest_init(&dest_a, 11, reg_addr_a)
	sqlite3_select_dest_init(&dest_b, 11, reg_addr_b)
	sqlite3_vdbe_explain(p_parse, U8(1), c'MERGE (%s)', voidptr(sqlite3_select_op_name(int(p.op))))
	addr_select_a = sqlite3_vdbe_current_addr(v) + 1
	addr1 = sqlite3_vdbe_add_op3(v, 11, reg_addr_a, 0, addr_select_a)
	p_prior.iLimit = reg_limit_a
	sqlite3_vdbe_explain(p_parse, U8(1), c'LEFT')
	sqlite3_select(p_parse, p_prior, &dest_a)
	sqlite3_vdbe_end_coroutine(v, reg_addr_a)
	sqlite3_vdbe_jump_here(v, addr1)
	addr_select_b = sqlite3_vdbe_current_addr(v) + 1
	addr1 = sqlite3_vdbe_add_op3(v, 11, reg_addr_b, 0, addr_select_b)
	saved_limit = p.iLimit
	saved_offset = p.iOffset
	p.iLimit = reg_limit_b
	p.iOffset = 0
	sqlite3_vdbe_explain(p_parse, U8(1), c'RIGHT')
	sqlite3_select(p_parse, p, &dest_b)
	p.iLimit = saved_limit
	p.iOffset = saved_offset
	sqlite3_vdbe_end_coroutine(v, reg_addr_b)
	addr_out_a = generate_output_subroutine(p_parse, p, &dest_a, p_dest, reg_out_a, reg_prev, p_key_dup, label_end)
	if op == 136 || op == 135 {
		addr_out_b = generate_output_subroutine(p_parse, p, &dest_b, p_dest, reg_out_b, reg_prev, p_key_dup, label_end)
	}
	sqlite3_key_info_unref(p_key_dup)
	if op == 137 || op == 138 {
		addr_eof_a = label_end
		addr_eof_a_no_b = addr_eof_a
	} else {
		addr_eof_a = sqlite3_vdbe_add_op2(v, 10, reg_out_b, addr_out_b)
		addr_eof_a_no_b = sqlite3_vdbe_add_op2(v, 12, reg_addr_b, label_end)
		sqlite3_vdbe_goto(v, addr_eof_a)
		p.nSelectRow = sqlite3_log_est_add(p.nSelectRow, p_prior.nSelectRow)
	}
	if op == 138 {
		addr_eof_b = addr_eof_a
		if int(p.nSelectRow) > int(p_prior.nSelectRow) {
			p.nSelectRow = p_prior.nSelectRow
		}
	} else {
		addr_eof_b = sqlite3_vdbe_add_op2(v, 10, reg_out_a, addr_out_a)
		sqlite3_vdbe_add_op2(v, 12, reg_addr_a, label_end)
		sqlite3_vdbe_goto(v, addr_eof_b)
	}
	addr_alt_b = sqlite3_vdbe_add_op2(v, 10, reg_out_a, addr_out_a)
	sqlite3_vdbe_add_op2(v, 12, reg_addr_a, addr_eof_a)
	sqlite3_vdbe_goto(v, label_cmpr)
	if op == 136 {
		addr_aeq_b = addr_alt_b
	} else if op == 138 {
		addr_aeq_b = addr_alt_b
		addr_alt_b++
	} else {
		addr_aeq_b = addr_alt_b + 1
	}
	addr_agt_b = sqlite3_vdbe_current_addr(v)
	if op == 136 || op == 135 {
		sqlite3_vdbe_add_op2(v, 10, reg_out_b, addr_out_b)
		sqlite3_vdbe_add_op2(v, 12, reg_addr_b, addr_eof_b)
		sqlite3_vdbe_goto(v, label_cmpr)
	} else {
		addr_agt_b++
	}
	sqlite3_vdbe_jump_here(v, addr1)
	sqlite3_vdbe_add_op2(v, 12, reg_addr_a, addr_eof_a_no_b)
	sqlite3_vdbe_add_op2(v, 12, reg_addr_b, addr_eof_b)
	if usize(a_permute) != usize(0) {
		sqlite3_vdbe_add_op4(v, 91, 0, 0, 0, &i8(voidptr(a_permute)), (-15))
	}
	sqlite3_vdbe_resolve_label(v, label_cmpr)
	sqlite3_vdbe_add_op4(v, 92, dest_a.iSdst, dest_b.iSdst, n_order_by, &i8(voidptr(p_key_merge)), (-9))
	if usize(a_permute) != usize(0) {
		sqlite3_vdbe_change_p5(v, U16(1))
	}
	sqlite3_vdbe_add_op3(v, 14, addr_alt_b, addr_aeq_b, addr_agt_b)
	sqlite3_vdbe_resolve_label(v, label_end)
	if p_split.pPrior {
		sqlite3_parser_add_cleanup(p_parse, sqlite3_select_delete_generic, voidptr(p_split.pPrior))
	}
	p_split.pPrior = p_prior
	p_prior.pNext = p_split
	sqlite3_expr_list_delete(db, p_prior.pOrderBy)
	p_prior.pOrderBy = 0
	sqlite3_vdbe_explain_pop(p_parse)
	return int(p_parse.nErr != 0)
}

struct SubstContext {
	pParse      &Parse
	iTable      int
	iNewTable   int
	isOuterJoin int
	nSelDepth   int
	pEList      &ExprList
	pCList      &ExprList
}

@[c:'substExpr']
fn subst_expr(p_subst &SubstContext, p_expr &Expr) &Expr {
	if usize(p_expr) == usize(0) {
		return unsafe { nil }
	}
	if ((p_expr.flags & u32((1 | 2))) != u32(0)) && p_expr.w.iJoin == p_subst.iTable {
		p_expr.w.iJoin = p_subst.iNewTable
	}
	if int(p_expr.op) == 168 && p_expr.iTable == p_subst.iTable && !((p_expr.flags & u32(32)) != u32(0)) {
		p_new := &Expr(0)
		i_column := 0
		p_copy := &Expr(0)
		if_null_row := Expr{}
		i_column = int(p_expr.iColumn)
		p_copy = c2v_at(&p_subst.pEList.a[0], isize(i_column)).pExpr
		if sqlite3_expr_is_vector(p_copy) {
			sqlite3_vector_error_msg(p_subst.pParse, p_copy)
		} else {
			db := p_subst.pParse.db
			if p_subst.isOuterJoin && (int(p_copy.op) != 168 || p_copy.iTable != p_subst.iNewTable) {
				C.memset(voidptr(&if_null_row), 0, sizeof(if_null_row))
				if_null_row.op = U8(179)
				if_null_row.pLeft = p_copy
				if_null_row.iTable = p_subst.iNewTable
				if_null_row.iColumn = YnVar(-99)
				if_null_row.flags = u32(262144)
				p_copy = &if_null_row
			}
			p_new = sqlite3_expr_dup(db, p_copy, 0)
			if db.mallocFailed {
				sqlite3_expr_delete(db, p_new)
				return p_expr
			}
			if p_subst.isOuterJoin {
				p_new.flags |= u32(2097152)
			}
			if int(p_new.op) == 171 {
				p_new.u.iValue = sqlite3_expr_truth_value(p_new)
				p_new.op = U8(156)
				p_new.flags |= u32(2048)
			}
			p_nat := sqlite3_expr_coll_seq(p_subst.pParse, p_new)
			p_coll := sqlite3_expr_coll_seq(p_subst.pParse, c2v_at(&p_subst.pCList.a[0], isize(i_column)).pExpr)
			if usize(p_nat) != usize(p_coll) || (int(p_new.op) != 168 && int(p_new.op) != 114) {
				p_new = sqlite3_expr_add_collate_string(p_subst.pParse, p_new, unsafe { if p_coll {
					p_coll.zName
				} else {
					c'BINARY'
				} })
			}
			p_new.flags &= ~u32(512)
			if ((p_expr.flags & u32((1 | 2))) != u32(0)) {
				sqlite3_set_join_expr(p_new, p_expr.w.iJoin, p_expr.flags & u32((1 | 2)))
			}
			sqlite3_expr_delete(db, p_expr)
			p_expr = p_new
		}
	} else {
		if int(p_expr.op) == 179 && p_expr.iTable == p_subst.iTable {
			p_expr.iTable = p_subst.iNewTable
		}
		if int(p_expr.op) == 169 && int(p_expr.op2) >= p_subst.nSelDepth {
			p_expr.op2--
		}
		p_expr.pLeft = subst_expr(p_subst, p_expr.pLeft)
		p_expr.pRight = subst_expr(p_subst, p_expr.pRight)
		if ((p_expr.flags & u32(4096)) != u32(0)) {
			subst_select(p_subst, p_expr.x.pSelect, 1)
		} else {
			subst_expr_list(p_subst, p_expr.x.pList)
		}
		if ((p_expr.flags & u32(16777216)) != u32(0)) {
			p_win := p_expr.y.pWin
			p_win.pFilter = subst_expr(p_subst, p_win.pFilter)
			subst_expr_list(p_subst, p_win.pPartition)
			subst_expr_list(p_subst, p_win.pOrderBy)
		}
	}
	return p_expr
}

@[c:'substExprList']
fn subst_expr_list(p_subst &SubstContext, p_list &ExprList) {
	i := 0
	if usize(p_list) == usize(0) {
		return
	}
	for i = 0; i < p_list.nExpr; i++ {
		mut __c2v_lhs_tmp_139 := c2v_at(&p_list.a[0], isize(i))
		__c2v_lhs_tmp_139.pExpr = subst_expr(p_subst, c2v_at(&p_list.a[0], isize(i)).pExpr)
	}
}

@[c:'substSelect']
fn subst_select(p_subst &SubstContext, p &Select, do_prior int) {
	p_src := &SrcList(0)
	p_item := &SrcItem(0)
	i := 0
	if isnil(p) {
		return
	}
	p_subst.nSelDepth++
	for {
		subst_expr_list(p_subst, p.pEList)
		subst_expr_list(p_subst, p.pGroupBy)
		subst_expr_list(p_subst, p.pOrderBy)
		p.pHaving = subst_expr(p_subst, p.pHaving)
		p.pWhere = subst_expr(p_subst, p.pWhere)
		p_src = p.pSrc
		i = p_src.nSrc
		for p_item = unsafe { &p_src.a[0] }; i > 0; i-- {
			if p_item.fg.isSubquery {
				subst_select(p_subst, p_item.u4.pSubq.pSelect, 1)
			}
			if p_item.fg.isTabFunc {
				subst_expr_list(p_subst, p_item.u1.pFuncArg)
			}
			c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
		}
		if !(do_prior && usize(c2v_assign[&Select](unsafe { &p }, p.pPrior)) != usize(0)) {
			break
		}
	}
	p_subst.nSelDepth--
}

@[c:'recomputeColumnsUsedExpr']
fn recompute_columns_used_expr(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	p_item := &SrcItem(0)
	if int(p_expr.op) != 168 {
		return 0
	}
	p_item = p_walker.u.pSrcItem
	if p_item.iCursor != p_expr.iTable {
		return 0
	}
	if int(p_expr.iColumn) < 0 {
		return 0
	}
	p_item.colUsed |= sqlite3_expr_col_used(p_expr)
	return 0
}

@[c:'recomputeColumnsUsed']
fn recompute_columns_used(p_select &Select, p_src_item &SrcItem) {
	w := Walker{}
	if (usize(p_src_item.pSTab) == usize(0)) {
		return
	}
	C.memset(voidptr(&w), 0, sizeof(w))
	w.xExprCallback = recompute_columns_used_expr
	w.xSelectCallback = sqlite3_select_walk_noop
	w.u.pSrcItem = p_src_item
	p_src_item.colUsed = Bitmask(0)
	sqlite3_walk_select(&w, p_select)
}

@[c:'srclistRenumberCursors']
fn srclist_renumber_cursors(p_parse &Parse, a_csr_map &int, p_src &SrcList, i_except int) {
	i := 0
	p_item := &SrcItem(0)
	i = 0
	for p_item = unsafe { &p_src.a[0] }; i < p_src.nSrc; i++ {
		if i != i_except {
			p := &Select(0)
			if !p_item.fg.isRecursive || a_csr_map[p_item.iCursor + 1] == 0 {
				mut __c2v_postfix_value_28 := p_parse.nTab
				p_parse.nTab++
				a_csr_map[p_item.iCursor + 1] = __c2v_postfix_value_28
			}
			p_item.iCursor = a_csr_map[p_item.iCursor + 1]
			if p_item.fg.isSubquery {
				for p = p_item.u4.pSubq.pSelect; p; p = p.pPrior {
					srclist_renumber_cursors(p_parse, a_csr_map, p.pSrc, -1)
				}
			}
		}
		c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
	}
}

@[c:'renumberCursorDoMapping']
fn renumber_cursor_do_mapping(p_walker &Walker, pi_cursor &int) {
	a_csr_map := p_walker.u.aiCol
	i_csr := (unsafe { *pi_cursor })
	if i_csr < a_csr_map[0] && a_csr_map[i_csr + 1] > 0 {
		unsafe { *pi_cursor = a_csr_map[i_csr + 1] }
	}
}

@[c:'renumberCursorsCb']
fn renumber_cursors_cb(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	op := int(p_expr.op)
	if op == 168 || op == 179 {
		renumber_cursor_do_mapping(p_walker, &p_expr.iTable)
	}
	if ((p_expr.flags & u32(1)) != u32(0)) {
		renumber_cursor_do_mapping(p_walker, &p_expr.w.iJoin)
	}
	return 0
}

@[c:'renumberCursors']
fn renumber_cursors(p_parse &Parse, p &Select, i_except int, a_csr_map &int) {
	w := Walker{}
	srclist_renumber_cursors(p_parse, a_csr_map, p.pSrc, i_except)
	C.memset(voidptr(&w), 0, sizeof(w))
	w.u.aiCol = a_csr_map
	w.xExprCallback = renumber_cursors_cb
	w.xSelectCallback = sqlite3_select_walk_noop
	sqlite3_walk_select(&w, p)
}

@[c:'findLeftmostExprlist']
fn find_leftmost_exprlist(p_sel &Select) &ExprList {
	for p_sel.pPrior {
		p_sel = p_sel.pPrior
	}
	return p_sel.pEList
}

@[c:'compoundHasDifferentAffinities']
fn compound_has_different_affinities(p &Select) int {
	ii := 0
	p_list := &ExprList(0)
	p_list = p.pEList
	for ii = 0; ii < p_list.nExpr; ii++ {
		aff := i8(0)
		p_sub1 := &Select(0)
		aff = sqlite3_expr_affinity(c2v_at(&p_list.a[0], isize(ii)).pExpr)
		for p_sub1 = p.pPrior; p_sub1; p_sub1 = p_sub1.pPrior {
			if int(sqlite3_expr_affinity(c2v_at(&p_sub1.pEList.a[0], isize(ii)).pExpr)) != int(aff) {
				return 1
			}
		}
	}
	return 0
}

@[c:'flattenSubquery']
fn flatten_subquery(p_parse &Parse, p &Select, i_from int, is_agg int) int {
	z_saved_auth_context := p_parse.zAuthContext
	p_parent := &Select(0)
	p_sub := &Select(0)
	p_sub1 := &Select(0)
	p_src := &SrcList(0)
	p_sub_src := &SrcList(0)
	i_parent := 0
	i_new_parent := -1
	is_outer_join := 0
	i := 0
	p_where := &Expr(0)
	p_subitem := &SrcItem(0)
	db := p_parse.db
	w := Walker{}
	a_csr_map := unsafe { &int(nil) }
	if ((db.dbOptFlags & u32(1)) != u32(0)) {
		return 0
	}
	p_src = p.pSrc
	p_subitem = unsafe { &p_src.a[0] + i_from }
	i_parent = p_subitem.iCursor
	p_sub = p_subitem.u4.pSubq.pSelect
	if !isnil(p.pWin) || !isnil(p_sub.pWin) {
		return 0
	}
	p_sub_src = p_sub.pSrc
	if !isnil(p_sub.pLimit) && !isnil(p.pLimit) {
		return 0
	}
	if !isnil(p_sub.pLimit) && !isnil(p_sub.pLimit.pRight) {
		return 0
	}
	if (p.selFlags & u32(256)) != u32(0) && !isnil(p_sub.pLimit) {
		return 0
	}
	if p_sub_src.nSrc == 0 {
		return 0
	}
	if p_sub.selFlags & u32(1) {
		return 0
	}
	if !isnil(p_sub.pLimit) && (p_src.nSrc > 1 || is_agg) {
		return 0
	}
	if !isnil(p.pOrderBy) && !isnil(p_sub.pOrderBy) {
		return 0
	}
	if is_agg && !isnil(p_sub.pOrderBy) {
		return 0
	}
	if !isnil(p_sub.pLimit) && !isnil(p.pWhere) {
		return 0
	}
	if !isnil(p_sub.pLimit) && (p.selFlags & u32(1)) != u32(0) {
		return 0
	}
	if p_sub.selFlags & u32(8192) {
		return 0
	}
	if (int(p_subitem.fg.jointype) & (32 | 64)) != 0 {
		if p_sub_src.nSrc > 1 || (p.selFlags & u32(1)) != u32(0) || (int(p_subitem.fg.jointype) & 16) != 0 {
			return 0
		}
		is_outer_join = 1
	}
	if i_from > 0 && (int(c2v_at(&p_sub_src.a[0], isize(0)).fg.jointype) & 64) != 0 {
		return 0
	}
	if p_sub.pPrior {
		ii := 0
		if p_sub.pOrderBy {
			return 0
		}
		if is_agg || (p.selFlags & u32(1)) != u32(0) || is_outer_join > 0 {
			return 0
		}
		for p_sub1 = p_sub; p_sub1; p_sub1 = p_sub1.pPrior {
			if (p_sub1.selFlags & u32((1 | 8))) != u32(0) || (!isnil(p_sub1.pPrior) && int(p_sub1.op) != 136) || p_sub1.pSrc.nSrc < 1 || !isnil(p_sub1.pWin) {
				return 0
			}
			if i_from > 0 && (int(c2v_at(&p_sub1.pSrc.a[0], isize(0)).fg.jointype) & 64) != 0 {
				return 0
			}
		}
		if p.pOrderBy {
			for ii = 0; ii < p.pOrderBy.nExpr; ii++ {
				if int(c2v_at(&p.pOrderBy.a[0], isize(ii)).u.x.iOrderByCol) == 0 {
					return 0
				}
			}
		}
		if (p.selFlags & u32(8192)) {
			return 0
		}
		if compound_has_different_affinities(p_sub) {
			return 0
		}
		if p_src.nSrc > 1 {
			if p_parse.nSelect > 500 {
				return 0
			}
			if ((db.dbOptFlags & u32(8388608)) != u32(0)) {
				return 0
			}
			a_csr_map = sqlite3_db_malloc_zero(db, u64((I64(p_parse.nTab) + I64(1))) * sizeof(int))
			if a_csr_map {
				a_csr_map[0] = p_parse.nTab
			}
		}
	}
	p_parse.zAuthContext = p_subitem.zName
	sqlite3_auth_check(p_parse, 21, unsafe { nil }, unsafe { nil }, unsafe { nil })
	p_parse.zAuthContext = z_saved_auth_context
	if p_subitem.fg.isSubquery {
		p_sub1 = sqlite3_subquery_detach(db, p_subitem)
	} else {
		p_sub1 = 0
	}
	sqlite3_db_free(db, voidptr(p_subitem.zName))
	sqlite3_db_free(db, voidptr(p_subitem.zAlias))
	p_subitem.zName = 0
	p_subitem.zAlias = 0
	for p_sub = p_sub.pPrior; p_sub; p_sub = p_sub.pPrior {
		p_new := &Select(0)
		p_order_by := p.pOrderBy
		p_limit := p.pLimit
		p_prior := p.pPrior
		p_item_tab := p_subitem.pSTab
		p_subitem.pSTab = 0
		p.pOrderBy = 0
		p.pPrior = 0
		p.pLimit = 0
		p_new = sqlite3_select_dup(db, p, 0)
		p.pLimit = p_limit
		p.pOrderBy = p_order_by
		p.op = U8(136)
		p_subitem.pSTab = p_item_tab
		if usize(p_new) == usize(0) {
			p.pPrior = p_prior
		} else {
			p_new.selId = u32(c2v_prefix_add(unsafe { &p_parse.nSelect }, 1))
			if !isnil(a_csr_map) && (int(db.mallocFailed) == 0) {
				renumber_cursors(p_parse, p_new, i_from, a_csr_map)
			}
			p_new.pPrior = p_prior
			if p_prior {
				p_prior.pNext = p_new
			}
			p_new.pNext = p
			p.pPrior = p_new
		}
	}
	sqlite3_db_free(db, voidptr(a_csr_map))
	if db.mallocFailed {
		sqlite3_src_item_attach_subquery(p_parse, p_subitem, p_sub1, 0)
		return 1
	}
	if (usize(p_subitem.pSTab) != usize(0)) {
		p_tab_to_del := p_subitem.pSTab
		if p_tab_to_del.nTabRef == u32(1) {
			p_toplevel := (if p_parse.pToplevel { p_parse.pToplevel } else { p_parse })
			sqlite3_parser_add_cleanup(p_toplevel, sqlite3_delete_table_generic, voidptr(p_tab_to_del))
		} else {
			p_tab_to_del.nTabRef--
		}
		p_subitem.pSTab = 0
	}
	p_sub = p_sub1
	for p_parent = p; p_parent;  {
		n_sub_src := 0
		jointype := p_subitem.fg.jointype
		p_sub_src = p_sub.pSrc
		n_sub_src = p_sub_src.nSrc
		p_src = p_parent.pSrc
		if n_sub_src > 1 {
			p_src = sqlite3_src_list_enlarge(p_parse, p_src, n_sub_src - 1, i_from + 1)
			if usize(p_src) == usize(0) {
				break
			}
			p_parent.pSrc = p_src
			p_subitem = unsafe { &p_src.a[0] + i_from }
		}
		i_new_parent = c2v_at(&p_sub_src.a[0], isize(0)).iCursor
		for i = 0; i < n_sub_src; i++ {
			p_item := unsafe { &p_src.a[0] + (i + i_from) }
			if p_item.fg.isUsing {
				sqlite3_id_list_delete(db, p_item.u3.pUsing)
			}
			unsafe { *p_item = (&p_sub_src.a[0])[i] }
			p_item.fg.jointype |= (int(jointype) & 64)
			C.memset(voidptr(unsafe { &p_sub_src.a[0] + i }), 0, sizeof(SrcItem))
		}
		p_subitem.fg.jointype |= int(jointype)
		if p_sub.pOrderBy {
			p_order_by := p_sub.pOrderBy
			for i = 0; i < p_order_by.nExpr; i++ {
				mut __c2v_lhs_tmp_140 := c2v_at(&p_order_by.a[0], isize(i))
				__c2v_lhs_tmp_140.u.x.iOrderByCol = U16(0)
			}
			p_parent.pOrderBy = p_order_by
			p_sub.pOrderBy = 0
		}
		p_where = p_sub.pWhere
		p_sub.pWhere = 0
		if is_outer_join > 0 {
			sqlite3_set_join_expr(p_where, i_new_parent, u32(1))
		}
		if p_where {
			if p_parent.pWhere {
				p_parent.pWhere = sqlite3_pe_xpr(p_parse, 44, p_where, p_parent.pWhere)
			} else {
				p_parent.pWhere = p_where
			}
		}
		if int(db.mallocFailed) == 0 {
			x := SubstContext{}
			x.pParse = p_parse
			x.iTable = i_parent
			x.iNewTable = i_new_parent
			x.isOuterJoin = is_outer_join
			x.nSelDepth = 0
			x.pEList = p_sub.pEList
			x.pCList = find_leftmost_exprlist(p_sub)
			subst_select(&x, p_parent, 0)
		}
		p_parent.selFlags |= p_sub.selFlags & u32(256)
		if p_sub.pLimit {
			p_parent.pLimit = p_sub.pLimit
			p_sub.pLimit = 0
		}
		for i = 0; i < n_sub_src; i++ {
			recompute_columns_used(p_parent, unsafe { &p_src.a[0] + (i + i_from) })
		}
		p_parent = p_parent.pPrior
		p_sub = p_sub.pPrior
	}
	sqlite3_agg_info_persist_walker_init(&w, p_parse)
	sqlite3_walk_select(&w, p_sub1)
	sqlite3_select_delete(db, p_sub1)
	return 1
}

struct WhereConst {
	pParse      &Parse
	pOomFault   &U8
	nConst      int
	nChng       int
	bHasAffBlob int
	mExcludeOn  u32
	apExpr      &&Expr
}

@[c:'constInsert']
fn const_insert(p_const &WhereConst, p_column &Expr, p_value &Expr, p_expr &Expr) {
	i := 0
	if ((p_column.flags & u32(32)) != u32(0)) {
		return
	}
	if int(sqlite3_expr_affinity(p_value)) != 0 {
		return
	}
	if !sqlite3_is_binary(sqlite3_expr_compare_coll_seq(p_const.pParse, p_expr)) {
		return
	}
	for i = 0; i < p_const.nConst; i++ {
		p_e2 := p_const.apExpr[i * 2]
		if p_e2.iTable == p_column.iTable && int(p_e2.iColumn) == int(p_column.iColumn) {
			return
		}
	}
	if int(sqlite3_expr_affinity(p_column)) <= 65 {
		p_const.bHasAffBlob = 1
	}
	p_const.nConst++
	p_const.apExpr = sqlite3_db_realloc_or_free(p_const.pParse.db, voidptr(p_const.apExpr), U64(u64(p_const.nConst * 2) * sizeof(voidptr)))
	if usize(p_const.apExpr) == usize(0) {
		p_const.nConst = 0
	} else {
		p_const.apExpr[p_const.nConst * 2 - 2] = p_column
		p_const.apExpr[p_const.nConst * 2 - 1] = p_value
	}
}

@[c:'findConstInWhere']
fn find_const_in_where(p_const &WhereConst, p_expr &Expr) {
	p_right := &Expr(0)
	p_left := &Expr(0)

	if (usize(p_expr) == usize(0)) {
		return
	}
	if ((p_expr.flags & u32(p_const.mExcludeOn)) != u32(0)) {
		return
	}
	if int(p_expr.op) == 44 {
		find_const_in_where(p_const, p_expr.pRight)
		find_const_in_where(p_const, p_expr.pLeft)
		return
	}
	if int(p_expr.op) != 54 {
		return
	}
	p_right = p_expr.pRight
	p_left = p_expr.pLeft
	if int(p_right.op) == 168 && sqlite3_expr_is_constant(p_const.pParse, p_left) {
		const_insert(p_const, p_right, p_left, p_expr)
	}
	if int(p_left.op) == 168 && sqlite3_expr_is_constant(p_const.pParse, p_right) {
		const_insert(p_const, p_left, p_right, p_expr)
	}
}

@[c:'propagateConstantExprRewriteOne']
fn propagate_constant_expr_rewrite_one(p_const &WhereConst, p_expr &Expr, b_ignore_aff_blob int) int {
	i := 0
	if p_const.pOomFault[0] {
		return 1
	}
	if int(p_expr.op) != 168 {
		return 0
	}
	if ((p_expr.flags & u32((u32(32) | p_const.mExcludeOn))) != u32(0)) {
		return 0
	}
	for i = 0; i < p_const.nConst; i++ {
		p_column := p_const.apExpr[i * 2]
		if usize(p_column) == usize(p_expr) {
			continue
		}
		if p_column.iTable != p_expr.iTable {
			continue
		}
		if int(p_column.iColumn) != int(p_expr.iColumn) {
			continue
		}
		if b_ignore_aff_blob && int(sqlite3_expr_affinity(p_column)) <= 65 {
			break
		}
		p_const.nChng++
		p_expr.flags &= ~u32(8388608)
		p_expr.flags |= u32(32)
		p_expr.pLeft = sqlite3_expr_dup(p_const.pParse.db, p_const.apExpr[i * 2 + 1], 0)
		if p_const.pParse.db.mallocFailed {
			return 1
		}
		break
	}
	return 1
}

@[c:'propagateConstantExprRewrite']
fn propagate_constant_expr_rewrite(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	p_const := p_walker.u.pConst
	if p_const.bHasAffBlob {
		if (int(p_expr.op) >= 54 && int(p_expr.op) <= 58) || int(p_expr.op) == 45 {
			propagate_constant_expr_rewrite_one(p_const, p_expr.pLeft, 0)
			if p_const.pOomFault[0] {
				return 1
			}
			if int(sqlite3_expr_affinity(p_expr.pLeft)) != 66 {
				propagate_constant_expr_rewrite_one(p_const, p_expr.pRight, 0)
			}
		}
	}
	return propagate_constant_expr_rewrite_one(p_const, p_expr, p_const.bHasAffBlob)
}

@[c:'propagateConstants']
fn propagate_constants(p_parse &Parse, p &Select) int {
	x := WhereConst{}
	w := Walker{}
	n_chng := 0
	x.pParse = p_parse
	x.pOomFault = &p_parse.db.mallocFailed
	for {
		x.nConst = 0
		x.nChng = 0
		x.apExpr = 0
		x.bHasAffBlob = 0
		if (usize(p.pSrc) != usize(0)) && p.pSrc.nSrc > 0 && (int(c2v_at(&p.pSrc.a[0], isize(0)).fg.jointype) & 64) != 0 {
			x.mExcludeOn = u32(2 | 1)
		} else {
			x.mExcludeOn = u32(1)
		}
		find_const_in_where(&x, p.pWhere)
		if x.nConst {
			C.memset(voidptr(&w), 0, sizeof(w))
			w.pParse = p_parse
			w.xExprCallback = propagate_constant_expr_rewrite
			w.xSelectCallback = sqlite3_select_walk_noop
			w.xSelectCallback2 = 0
			w.walkerDepth = 0
			w.u.pConst = &x
			sqlite3_walk_expr(&w, p.pWhere)
			sqlite3_db_free(x.pParse.db, voidptr(x.apExpr))
			n_chng += x.nChng
		}
		if !(x.nChng) {
			break
		}
	}
	return n_chng
}

@[c:'pushDownWindowCheck']
fn push_down_window_check(p_parse &Parse, p_subq &Select, p_expr &Expr) int {
	return sqlite3_expr_is_constant_or_group_by(p_parse, p_expr, p_subq.pWin.pPartition)
}

@[c:'pushDownWhereTerms']
fn push_down_where_terms(p_parse &Parse, p_subq &Select, p_where &Expr, p_src_list &SrcList, i_src int) int {
	p_new := &Expr(0)
	p_src := &SrcItem(0)
	n_chng := 0
	p_src = unsafe { &p_src_list.a[0] + i_src }
	if usize(p_where) == usize(0) {
		return 0
	}
	if p_subq.selFlags & u32((8192 | 33554432)) {
		return 0
	}
	if int(p_src.fg.jointype) & (64 | 16) {
		return 0
	}
	if p_subq.pPrior {
		p_sel := &Select(0)
		not_union_all := 0
		for p_sel = p_subq; p_sel; p_sel = p_sel.pPrior {
			op := p_sel.op
			if int(op) != 136 && int(op) != 139 {
				not_union_all = 1
			}
			if p_sel.pWin {
				return 0
			}
		}
		if not_union_all {
			for p_sel = p_subq; p_sel; p_sel = p_sel.pPrior {
				ii := 0
				p_list := p_sel.pEList
				for ii = 0; ii < p_list.nExpr; ii++ {
					p_coll := sqlite3_expr_coll_seq(p_parse, c2v_at(&p_list.a[0], isize(ii)).pExpr)
					if !sqlite3_is_binary(p_coll) {
						return 0
					}
				}
			}
		}
	} else {
		if !isnil(p_subq.pWin) && usize(p_subq.pWin.pPartition) == usize(0) {
			return 0
		}
	}
	if usize(p_subq.pLimit) != usize(0) {
		return 0
	}
	for int(p_where.op) == 44 {
		n_chng += push_down_where_terms(p_parse, p_subq, p_where.pRight, p_src_list, i_src)
		p_where = p_where.pLeft
	}
	if sqlite3_expr_is_single_table_constraint(p_where, p_src_list, i_src, 1) {
		n_chng++
		p_subq.selFlags |= u32(16777216)
		for p_subq {
			x := SubstContext{}
			p_new = sqlite3_expr_dup(p_parse.db, p_where, 0)
			unset_join_expr(p_new, -1, 1)
			x.pParse = p_parse
			x.iTable = p_src.iCursor
			x.iNewTable = p_src.iCursor
			x.isOuterJoin = 0
			x.nSelDepth = 0
			x.pEList = p_subq.pEList
			x.pCList = find_leftmost_exprlist(p_subq)
			p_new = subst_expr(&x, p_new)
			if p_parse.nErr == 0 && int(p_new.op) == 50 && ((p_new.flags & u32(4096)) != u32(0)) {
				p_new.x.pSelect.selFlags |= u32(32)
				p_where.x.pSelect.selFlags |= u32(32)
			}
			if !isnil(p_subq.pWin) && 0 == push_down_window_check(p_parse, p_subq, p_new) {
				sqlite3_expr_delete(p_parse.db, p_new)
				n_chng--
				break
			}
			if p_subq.selFlags & u32(8) {
				p_subq.pHaving = sqlite3_expr_and(p_parse, p_subq.pHaving, p_new)
			} else {
				p_subq.pWhere = sqlite3_expr_and(p_parse, p_subq.pWhere, p_new)
			}
			p_subq = p_subq.pPrior
		}
	}
	return n_chng
}

@[c:'disableUnusedSubqueryResultColumns']
fn disable_unused_subquery_result_columns(p_item &SrcItem) int {
	n_col := 0
	p_sub := &Select(0)
	px := &Select(0)
	p_tab := &Table(0)
	j := 0
	n_chng := 0
	col_used := Bitmask(0)
	if int(p_item.fg.isCorrelated) || int(p_item.fg.isCte) {
		return 0
	}
	p_tab = p_item.pSTab
	p_sub = p_item.u4.pSubq.pSelect
	for px = p_sub; px; px = px.pPrior {
		if (px.selFlags & u32((1 | 8))) != u32(0) {
			return 0
		}
		if !isnil(px.pPrior) && int(px.op) != 136 {
			return 0
		}
		if px.pWin {
			return 0
		}
	}
	col_used = p_item.colUsed
	if p_sub.pOrderBy {
		p_list := p_sub.pOrderBy
		for j = 0; j < p_list.nExpr; j++ {
			i_col := c2v_at(&p_list.a[0], isize(j)).u.x.iOrderByCol
			if int(i_col) > 0 {
				i_col--
				col_used |= (Bitmask(1)) << (if int(i_col) >= (int((sizeof(Bitmask) * u64(8)))) {
					(int((sizeof(Bitmask) * u64(8)))) - 1
				} else {
					int(i_col)
				})
			}
		}
	}
	n_col = int(p_tab.nCol)
	for j = 0; j < n_col; j++ {
		m := if j < (int((sizeof(Bitmask) * u64(8)))) - 1 {
			((Bitmask(1)) << j)
		} else {
			((Bitmask(1)) << ((int((sizeof(Bitmask) * u64(8)))) - 1))
		}
		if (m & col_used) != Bitmask(0) {
			continue
		}
		for px = p_sub; px; px = px.pPrior {
			py := c2v_at(&px.pEList.a[0], isize(j)).pExpr
			if int(py.op) == 122 {
				continue
			}
			py.op = U8(122)
			py.flags &= ~u32((8192 | 524288))
			px.selFlags |= u32(16777216)
			n_chng++
		}
	}
	return n_chng
}

@[c:'minMaxQuery']
fn min_max_query(db &Sqlite3, p_func &Expr, pp_min_max &&ExprList) U8 {
	e_ret := 0
	pel_ist := &ExprList(0)
	z_func := &i8(0)
	p_order_by := &ExprList(0)
	sort_flags := U8(0)
	pel_ist = p_func.x.pList
	if usize(pel_ist) == usize(0) || pel_ist.nExpr != 1 || ((p_func.flags & u32(16777216)) != u32(0)) || ((db.dbOptFlags & u32(65536)) != u32(0)) {
		return U8(e_ret)
	}
	z_func = p_func.u.zToken
	if sqlite3_str_ic_mp(z_func, c'min') == 0 {
		e_ret = 1
		if sqlite3_expr_can_be_null(c2v_at(&pel_ist.a[0], isize(0)).pExpr) {
			sort_flags = U8(2)
		}
	} else if sqlite3_str_ic_mp(z_func, c'max') == 0 {
		e_ret = 2
		sort_flags = U8(1)
	} else {
		return U8(e_ret)
	}
	p_order_by = sqlite3_expr_list_dup(db, pel_ist, 0)
	unsafe { *pp_min_max = p_order_by }
	if p_order_by {
		mut __c2v_lhs_tmp_141 := c2v_at(&p_order_by.a[0], isize(0))
		__c2v_lhs_tmp_141.fg.sortFlags = sort_flags
	}
	return U8(e_ret)
}

@[c:'isSimpleCount']
fn is_simple_count(p &Select, p_agg_info &AggInfo) &Table {
	p_tab := &Table(0)
	p_expr := &Expr(0)
	if !isnil(p.pWhere) || p.pEList.nExpr != 1 || p.pSrc.nSrc != 1 || int(c2v_at(&p.pSrc.a[0], isize(0)).fg.isSubquery) || p_agg_info.nFunc != 1 || !isnil(p.pHaving) {
		return unsafe { nil }
	}
	p_tab = c2v_at(&p.pSrc.a[0], isize(0)).pSTab
	if !(int(p_tab.eTabType) == 0) {
		return unsafe { nil }
	}
	p_expr = c2v_at(&p.pEList.a[0], isize(0)).pExpr
	if int(p_expr.op) != 169 {
		return unsafe { nil }
	}
	if usize(p_expr.pAggInfo) != usize(p_agg_info) {
		return unsafe { nil }
	}
	if (p_agg_info.aFunc[0].pFunc.funcFlags & u32(256)) == u32(0) {
		return unsafe { nil }
	}
	if ((p_expr.flags & u32((4 | 16777216))) != u32(0)) {
		return unsafe { nil }
	}
	return p_tab
}

@[c:'sqlite3IndexedByLookup']
fn sqlite3_indexed_by_lookup(p_parse &Parse, p_from &SrcItem) int {
	p_tab := p_from.pSTab
	z_indexed_by := p_from.u1.zIndexedBy
	p_idx := &Index(0)
	for p_idx = p_tab.pIndex; !isnil(p_idx) && sqlite3_str_ic_mp(p_idx.zName, z_indexed_by); p_idx = p_idx.pNext {
	}
	if isnil(p_idx) {
		sqlite3_error_msg(p_parse, c'no such index: %s', voidptr(z_indexed_by), 0)
		p_parse.checkSchema = Bft(1)
		return 1
	}
	p_from.u2.pIBIndex = p_idx
	return 0
}

@[c:'convertCompoundSelectToSubquery']
fn convert_compound_select_to_subquery(p_walker &Walker, p &Select) int {
	c2v_gc_register_thread()
	i := 0
	p_new := &Select(0)
	px := &Select(0)
	db := &Sqlite3(0)
	a := &ExprList_item(0)
	p_new_src := &SrcList(0)
	p_parse := &Parse(0)
	dummy := Token{}
	if usize(p.pPrior) == usize(0) {
		return 0
	}
	if usize(p.pOrderBy) == usize(0) {
		return 0
	}
	for px = p; !isnil(px) && (int(px.op) == 136 || int(px.op) == 139); px = px.pPrior {
	}
	if usize(px) == usize(0) {
		return 0
	}
	a = unsafe { &p.pOrderBy.a[0] }
	if a[0].u.x.iOrderByCol {
		return 0
	}
	for i = p.pOrderBy.nExpr - 1; i >= 0; i-- {
		if a[i].pExpr.flags & u32(512) {
			break
		}
	}
	if i < 0 {
		return 0
	}
	p_parse = p_walker.pParse
	db = p_parse.db
	p_new = sqlite3_db_malloc_zero(db, U64(sizeof(Select)))
	if usize(p_new) == usize(0) {
		return 2
	}
	C.memset(voidptr(&dummy), 0, sizeof(dummy))
	p_new_src = sqlite3_src_list_append_from_term(p_parse, unsafe { nil }, unsafe { nil }, unsafe { nil }, &dummy, p_new, unsafe { nil })
	if p_parse.nErr {
		sqlite3_src_list_delete(db, p_new_src)
		return 2
	}
	unsafe { *p_new = *p }
	p.pSrc = p_new_src
	p.pEList = sqlite3_expr_list_append(p_parse, unsafe { nil }, sqlite3_expr(db, 180, unsafe { nil }))
	p.op = U8(139)
	p.pWhere = 0
	p_new.pGroupBy = 0
	p_new.pHaving = 0
	p_new.pOrderBy = 0
	p.pPrior = 0
	p.pNext = 0
	p.pWith = 0
	p.pWinDefn = 0
	p.selFlags &= ~u32(256)
	p.selFlags |= u32(65536)
	p_new.pPrior.pNext = p_new
	p_new.pLimit = 0
	return 0
}

@[c:'cannotBeFunction']
fn cannot_be_function(p_parse &Parse, p_from &SrcItem) int {
	if p_from.fg.isTabFunc {
		sqlite3_error_msg(p_parse, c"'%s' is not a function", voidptr(p_from.zName))
		return 1
	}
	return 0
}

@[c:'searchWith']
fn search_with(p_with &With, p_item &SrcItem, pp_context &&With) &Cte {
	z_name := p_item.zName
	p := &With(0)
	for p = p_with; p; p = p.pOuter {
		i := 0
		for i = 0; i < p.nCte; i++ {
			if sqlite3_str_ic_mp(z_name, c2v_at(&p.a[0], isize(i)).zName) == 0 {
				unsafe { *pp_context = p }
				return unsafe { &p.a[0] + i }
			}
		}
		if p.bView {
			break
		}
	}
	return unsafe { nil }
}

@[c:'sqlite3WithPush']
fn sqlite3_with_push(p_parse &Parse, p_with &With, b_free U8) &With {
	if p_with {
		if b_free {
			p_with = &With(sqlite3_parser_add_cleanup(p_parse, sqlite3_with_delete_generic, voidptr(p_with)))
			if usize(p_with) == usize(0) {
				return unsafe { nil }
			}
		}
		if p_parse.nErr == 0 {
			p_with.pOuter = p_parse.pWith
			p_parse.pWith = p_with
		}
	}
	return p_with
}

@[c:'resolveFromTermToCte']
fn resolve_from_term_to_cte(p_parse &Parse, p_walker &Walker, p_from &SrcItem) int {
	p_cte := &Cte(0)
	p_with := &With(0)
	if usize(p_parse.pWith) == usize(0) {
		return 0
	}
	if p_parse.nErr {
		return 0
	}
	if int(p_from.fg.fixedSchema) == 0 && usize(p_from.u4.zDatabase) != usize(0) {
		return 0
	}
	if p_from.fg.notCte {
		return 0
	}
	p_cte = search_with(p_parse.pWith, p_from, &&With(&&With(c2v_address_of(&p_with))))
	if p_cte {
		db := p_parse.db
		p_tab := &Table(0)
		pel_ist := &ExprList(0)
		p_sel := &Select(0)
		p_left := &Select(0)
		p_rec_term := &Select(0)
		b_may_recursive := 0
		p_saved_with := &With(0)
		i_rec_tab := -1
		p_cte_use := &CteUse(0)
		if p_cte.zCteErr {
			sqlite3_error_msg(p_parse, p_cte.zCteErr, voidptr(p_cte.zName))
			return 2
		}
		if cannot_be_function(p_parse, p_from) {
			return 2
		}
		p_tab = sqlite3_db_malloc_zero(db, U64(sizeof(Table)))
		if usize(p_tab) == usize(0) {
			return 2
		}
		p_cte_use = p_cte.pUse
		if usize(p_cte_use) == usize(0) {
			p_cte_use = sqlite3_db_malloc_zero(db, U64(sizeof(CteUse)))
			p_cte.pUse = p_cte_use
			if usize(p_cte_use) == usize(0) || usize(sqlite3_parser_add_cleanup(p_parse, sqlite3_db_free, voidptr(p_cte_use))) == usize(0) {
				sqlite3_db_free(db, voidptr(p_tab))
				return 2
			}
			p_cte_use.eM10d = p_cte.eM10d
		}
		p_from.pSTab = p_tab
		p_tab.nTabRef = u32(1)
		p_tab.zName = sqlite3_db_str_dup(db, p_cte.zName)
		p_tab.iPKey = I16(-1)
		p_tab.nRowLogEst = LogEst(200)
		p_tab.tabFlags |= u32(16384 | 512)
		sqlite3_src_item_attach_subquery(p_parse, p_from, p_cte.pSelect, 1)
		if db.mallocFailed {
			return 2
		}
		p_sel = p_from.u4.pSubq.pSelect
		p_sel.selFlags |= u32(67108864)
		if p_from.fg.isIndexedBy {
			sqlite3_error_msg(p_parse, c'no such index: "%s"', voidptr(p_from.u1.zIndexedBy))
			return 2
		}
		p_from.fg.isCte = u32(1)
		p_from.u2.pCteUse = p_cte_use
		p_cte_use.nUse++
		p_rec_term = p_sel
		b_may_recursive = (int(p_sel.op) == 136 || int(p_sel.op) == 135)
		for b_may_recursive && int(p_rec_term.op) == int(p_sel.op) {
			i := 0
			p_src := p_rec_term.pSrc
			for i = 0; i < p_src.nSrc; i++ {
				p_item := unsafe { &p_src.a[0] + i }
				mut __c2v_condition_76 := false
				mut __c2v_condition_77 := false
				__c2v_condition_77 = usize(p_item.zName) != usize(0)
				if __c2v_condition_77 {
					__c2v_condition_77 = !p_item.fg.hadSchema
				}
				if __c2v_condition_77 {
					__c2v_condition_77 = (!p_item.fg.isSubquery)
				}
				if __c2v_condition_77 {
					__c2v_condition_77 = (int(p_item.fg.fixedSchema) || usize(p_item.u4.zDatabase) == usize(0))
				}
				if __c2v_condition_77 {
					__c2v_condition_77 = 0 == sqlite3_str_ic_mp(p_item.zName, p_cte.zName)
				}
				__c2v_condition_76 = __c2v_condition_77
				if __c2v_condition_76 {
					p_item.pSTab = p_tab
					p_tab.nTabRef++
					p_item.fg.isRecursive = u32(1)
					if p_rec_term.selFlags & u32(8192) {
						sqlite3_error_msg(p_parse, c'multiple references to recursive table: %s', voidptr(p_cte.zName))
						return 2
					}
					p_rec_term.selFlags |= u32(8192)
					if i_rec_tab < 0 {
						mut __c2v_postfix_value_29 := p_parse.nTab
						p_parse.nTab++
						i_rec_tab = __c2v_postfix_value_29
					}
					p_item.iCursor = i_rec_tab
				}
			}
			if (p_rec_term.selFlags & u32(8192)) == u32(0) {
				break
			}
			p_rec_term = p_rec_term.pPrior
		}
		p_cte.zCteErr = c'circular reference: %s'
		p_saved_with = p_parse.pWith
		p_parse.pWith = p_with
		if p_sel.selFlags & u32(8192) {
			rc := 0
			p_rec_term.pWith = p_sel.pWith
			rc = sqlite3_walk_select(p_walker, p_rec_term)
			p_rec_term.pWith = 0
			if rc {
				p_parse.pWith = p_saved_with
				return 2
			}
		} else {
			if sqlite3_walk_select(p_walker, p_sel) {
				p_parse.pWith = p_saved_with
				return 2
			}
		}
		p_parse.pWith = p_with
		for p_left = p_sel; p_left.pPrior; p_left = p_left.pPrior {
		}
		pel_ist = p_left.pEList
		if p_cte.pCols {
			if !isnil(pel_ist) && pel_ist.nExpr != p_cte.pCols.nExpr {
				sqlite3_error_msg(p_parse, c'table %s has %d values for %d columns', voidptr(p_cte.zName), pel_ist.nExpr, p_cte.pCols.nExpr)
				p_parse.pWith = p_saved_with
				return 2
			}
			pel_ist = p_cte.pCols
		}
		sqlite3_columns_from_expr_list(p_parse, pel_ist, &p_tab.nCol, &&Column(&p_tab.aCol))
		if b_may_recursive {
			if p_sel.selFlags & u32(8192) {
				p_cte.zCteErr = c'multiple recursive references: %s'
			} else {
				p_cte.zCteErr = c'recursive reference in a subquery: %s'
			}
			sqlite3_walk_select(p_walker, p_sel)
		}
		p_cte.zCteErr = 0
		p_parse.pWith = p_saved_with
		return 1
	}
	return 0
}

@[c:'sqlite3SelectPopWith']
fn sqlite3_select_pop_with(p_walker &Walker, p &Select) {
	c2v_gc_register_thread()
	p_parse := p_walker.pParse
	if !isnil(p_parse.pWith) && usize(p.pPrior) == usize(0) {
		p_with := find_rightmost(p).pWith
		if usize(p_with) != usize(0) {
			p_parse.pWith = p_with.pOuter
		}
	}
}

@[c:'sqlite3ExpandSubquery']
fn sqlite3_expand_subquery(p_parse &Parse, p_from &SrcItem) int {
	p_sel := &Select(0)
	p_tab := &Table(0)
	p_sel = p_from.u4.pSubq.pSelect
	p_tab = sqlite3_db_malloc_zero(p_parse.db, U64(sizeof(Table)))
	p_from.pSTab = p_tab
	if usize(p_tab) == usize(0) {
		return 7
	}
	p_tab.nTabRef = u32(1)
	if p_from.zAlias {
		p_tab.zName = sqlite3_db_str_dup(p_parse.db, p_from.zAlias)
	} else {
		p_tab.zName = sqlite3_mp_rintf(p_parse.db, c'%!S', voidptr(p_from))
	}
	for p_sel.pPrior {
		p_sel = p_sel.pPrior
	}
	sqlite3_columns_from_expr_list(p_parse, p_sel.pEList, &p_tab.nCol, &&Column(&p_tab.aCol))
	p_tab.iPKey = I16(-1)
	p_tab.eTabType = U8(2)
	p_tab.nRowLogEst = LogEst(200)
	p_tab.tabFlags |= u32(16384 | 512)
	return if p_parse.nErr { 1 } else { 0 }
}

@[c:'inAnyUsingClause']
fn in_any_using_clause(z_name &i8, p_base &SrcItem, n int) int {
	for n > 0 {
		n--
		c2v_pointer_postfix(voidptr(&p_base), p_base, isize(1))
		if int(p_base.fg.isUsing) == 0 {
			continue
		}
		if (usize(p_base.u3.pUsing) == usize(0)) {
			continue
		}
		if sqlite3_id_list_index(p_base.u3.pUsing, z_name) >= 0 {
			return 1
		}
	}
	return 0
}

@[c:'selectExpander']
fn select_expander(p_walker &Walker, p &Select) int {
	c2v_gc_register_thread()
	p_parse := p_walker.pParse
	i := 0
	j := 0
	k := 0
	rc := 0

	p_tab_list := &SrcList(0)
	pel_ist := &ExprList(0)
	p_from := &SrcItem(0)
	db := p_parse.db
	pe := &Expr(0)
	p_right := &Expr(0)
	p_expr := &Expr(0)

	sel_flags := U16(p.selFlags)
	elist_flags := u32(0)
	p.selFlags |= u32(64)
	if db.mallocFailed {
		return 2
	}
	if (int(sel_flags) & 64) != 0 {
		return 1
	}
	if p_walker.eCode {
		p.selId = u32(c2v_prefix_add(unsafe { &p_parse.nSelect }, 1))
	}
	p_tab_list = p.pSrc
	pel_ist = p.pEList
	if !isnil(p_parse.pWith) && (p.selFlags & u32(2097152)) {
		if usize(p.pWith) == usize(0) {
			p.pWith = &With(sqlite3_db_malloc_zero(db, U64(((u64(usize(__offsetof(With, a)))) + u64(1) * sizeof(Cte)))))
			if usize(p.pWith) == usize(0) {
				return 2
			}
		}
		p.pWith.bView = 1
	}
	sqlite3_with_push(p_parse, p.pWith, U8(0))
	sqlite3_src_list_assign_cursors(p_parse, p_tab_list)
	i = 0
	for p_from = unsafe { &p_tab_list.a[0] }; i < p_tab_list.nSrc; i++ {
		p_tab := &Table(0)
		if p_from.pSTab {
			unsafe { goto c2v_for_next_152
			 }
		}
		if usize(p_from.zName) == usize(0) {
			p_sel := &Select(0)
			p_sel = p_from.u4.pSubq.pSelect
			if sqlite3_walk_select(p_walker, p_sel) {
				return 2
			}
			if sqlite3_expand_subquery(p_parse, p_from) {
				return 2
			}
		} else {
			rc = resolve_from_term_to_cte(p_parse, p_walker, p_from)
			if rc != 0 {
				if rc > 1 {
					return 2
				}
				p_tab = p_from.pSTab
			} else {
				p_tab = sqlite3_locate_table_item(p_parse, u32(0), p_from)
				p_from.pSTab = p_tab
				if usize(p_tab) == usize(0) {
					return 2
				}
				if p_tab.nTabRef >= u32(65535) {
					sqlite3_error_msg(p_parse, c'too many references to "%s": max 65535', voidptr(p_tab.zName))
					p_from.pSTab = 0
					return 2
				}
				p_tab.nTabRef++
				if !(int(p_tab.eTabType) == 1) && cannot_be_function(p_parse, p_from) {
					return 2
				}
				if !(int(p_tab.eTabType) == 0) {
					n_col := I16(0)
					e_code_orig := U8(p_walker.eCode)
					if sqlite3_view_get_column_names(p_parse, p_tab) {
						return 2
					}
					if (int(p_tab.eTabType) == 2) {
						if (db.flags & U64(u32(2147483648))) == U64(0) && usize(p_tab.pSchema) != usize(db.aDb[1].pSchema) {
							sqlite3_error_msg(p_parse, c'access to view "%s" prohibited', voidptr(p_tab.zName))
						}
						sqlite3_src_item_attach_subquery(p_parse, p_from, p_tab.u.view.pSelect, 1)
					} else if (int(p_tab.eTabType) == 1) && (int(p_from.fg.fromDDL) || (int(p_parse.prepFlags) & 32)) && (usize(p_tab.u.vtab.p) != usize(0)) && int(p_tab.u.vtab.p.eVtabRisk) > ((db.flags & U64(128)) != U64(0)) {
						sqlite3_error_msg(p_parse, c'unsafe use of virtual table "%s"', voidptr(p_tab.zName))
					}
					n_col = p_tab.nCol
					p_tab.nCol = I16(-1)
					p_walker.eCode = U16(1)
					if p_from.fg.isSubquery {
						sqlite3_walk_select(p_walker, p_from.u4.pSubq.pSelect)
					}
					p_walker.eCode = U16(e_code_orig)
					p_tab.nCol = n_col
				}
			}
		}
		if int(p_from.fg.isIndexedBy) && sqlite3_indexed_by_lookup(p_parse, p_from) {
			return 2
		}
		c2v_for_next_152:
		c2v_pointer_postfix(voidptr(&p_from), p_from, isize(1))
	}
	if p_parse.nErr || sqlite3_process_join(p_parse, p) {
		return 2
	}
	for k = 0; k < pel_ist.nExpr; k++ {
		pe = c2v_at(&pel_ist.a[0], isize(k)).pExpr
		if int(pe.op) == 180 {
			break
		}
		if int(pe.op) == 142 && int(pe.pRight.op) == 180 {
			break
		}
		elist_flags |= pe.flags
	}
	if k < pel_ist.nExpr {
		mut a := unsafe { &ExprList_item(&pel_ist.a[0]) }
		p_new := unsafe { &ExprList(nil) }
		flags := int(p_parse.db.flags)
		long_names := int((flags & 4) != 0 && (flags & 64) == 0)
		for k = 0; k < pel_ist.nExpr; k++ {
			pe = a[k].pExpr
			elist_flags |= pe.flags
			p_right = pe.pRight
			if int(pe.op) != 180 && (int(pe.op) != 142 || int(p_right.op) != 180) {
				p_new = sqlite3_expr_list_append(p_parse, p_new, a[k].pExpr)
				if p_new {
					mut __c2v_lhs_tmp_142 := unsafe { c2v_at(&p_new.a[0], isize(p_new.nExpr - 1)) }
					__c2v_lhs_tmp_142.zEName = a[k].zEName
					mut __c2v_lhs_tmp_143 := unsafe { c2v_at(&p_new.a[0], isize(p_new.nExpr - 1)) }
					__c2v_lhs_tmp_143.fg.eEName = a[k].fg.eEName
					a[k].zEName = 0
				}
				a[k].pExpr = 0
			} else {
				table_seen := 0
				ztn_ame := unsafe { &i8(nil) }
				i_err_ofst := 0
				if int(pe.op) == 142 {
					ztn_ame = pe.pLeft.u.zToken
					i_err_ofst = pe.pRight.w.iOfst
				} else {
					i_err_ofst = pe.w.iOfst
				}
				i = 0
				for p_from = unsafe { &p_tab_list.a[0] }; i < p_tab_list.nSrc; i++ {
					n_add := 0
					p_tab := p_from.pSTab
					p_nested_from := &ExprList(0)
					z_tab_name := &i8(0)
					z_schema_name := unsafe { &i8(nil) }
					i_db := 0
					p_using := &IdList(0)
					z_tab_name = p_from.zAlias
					if usize(z_tab_name) == usize(0) {
						z_tab_name = p_tab.zName
					}
					if db.mallocFailed {
						break
					}
					if p_from.fg.isNestedFrom {
						p_nested_from = p_from.u4.pSubq.pSelect.pEList
					} else {
						if !isnil(ztn_ame) && sqlite3_str_ic_mp(ztn_ame, z_tab_name) != 0 {
							unsafe { goto c2v_for_next_153
							 }
						}
						p_nested_from = 0
						i_db = sqlite3_schema_to_index(db, p_tab.pSchema)
						z_schema_name = if i_db >= 0 { db.aDb[i_db].zDbSName } else { c'*' }
					}
					if i + 1 < p_tab_list.nSrc && int(p_from[1].fg.isUsing) && (int(sel_flags) & 2048) != 0 {
						ii := 0
						p_using = p_from[1].u3.pUsing
						for ii = 0; ii < p_using.nId; ii++ {
							zun_ame := c2v_at(&p_using.a[0], isize(ii)).zName
							p_right = sqlite3_expr(db, 60, zun_ame)
							sqlite3_expr_set_error_offset(p_right, i_err_ofst)
							p_new = sqlite3_expr_list_append(p_parse, p_new, p_right)
							if p_new {
								px := unsafe { &p_new.a[0] + (p_new.nExpr - 1) }
								px.zEName = sqlite3_mp_rintf(db, c'..%s', voidptr(zun_ame))
								px.fg.eEName = u32(2)
								px.fg.bUsingTerm = u32(1)
							}
						}
					} else {
						p_using = 0
					}
					n_add = int(p_tab.nCol)
					if ((p_tab.tabFlags & u32(512)) == u32(0)) && (int(sel_flags) & 2048) != 0 {
						n_add++
					}
					for j = 0; j < n_add; j++ {
						z_name := &i8(0)
						px := &ExprList_item(0)
						if j == int(p_tab.nCol) {
							z_name = sqlite3_rowid_alias(p_tab)
							if usize(z_name) == usize(0) {
								continue
							}
						} else {
							z_name = p_tab.aCol[j].zCnName
							if !isnil(p_nested_from) && int(c2v_at(&p_nested_from.a[0], isize(j)).fg.eEName) == 3 {
								continue
							}
							if !isnil(ztn_ame) && !isnil(p_nested_from) && sqlite3_match_en_ame(unsafe { &p_nested_from.a[0] + j }, unsafe { nil }, ztn_ame, unsafe { nil }, unsafe { nil }) == 0 {
								continue
							}
							if (p.selFlags & u32(131072)) == u32(0) && ((int(p_tab.aCol[j].colFlags) & 2) != 0) {
								continue
							}
							if (int(p_tab.aCol[j].colFlags) & 1024) != 0 && usize(ztn_ame) == usize(0) && (int(sel_flags) & 2048) == 0 {
								continue
							}
						}
						table_seen = 1
						if i > 0 && usize(ztn_ame) == usize(0) && (int(sel_flags) & 2048) == 0 {
							if int(p_from.fg.isUsing) && sqlite3_id_list_index(p_from.u3.pUsing, z_name) >= 0 {
								continue
							}
						}
						p_right = sqlite3_expr(db, 60, z_name)
						mut __c2v_condition_78 := false
						mut __c2v_condition_79 := false
						__c2v_condition_79 = (p_tab_list.nSrc > 1 && ((int(p_from.fg.jointype) & 64) == 0 || (int(sel_flags) & 2048) != 0 || !in_any_using_clause(z_name, p_from, p_tab_list.nSrc - i - 1)))
						__c2v_condition_78 = __c2v_condition_79
						if !__c2v_condition_78 {
							mut __c2v_condition_80 := false
							__c2v_condition_80 = (int(p_parse.eParseMode) >= 2)
							__c2v_condition_78 = __c2v_condition_80
						}
						if __c2v_condition_78 {
							p_left := &Expr(0)
							p_left = sqlite3_expr(db, 60, z_tab_name)
							p_expr = sqlite3_pe_xpr(p_parse, 142, p_left, p_right)
							if (int(p_parse.eParseMode) >= 2) && !isnil(pe.pLeft) {
								sqlite3_rename_token_remap(p_parse, voidptr(p_left), voidptr(pe.pLeft))
							}
							if z_schema_name {
								p_left = sqlite3_expr(db, 60, z_schema_name)
								p_expr = sqlite3_pe_xpr(p_parse, 142, p_left, p_expr)
							}
						} else {
							p_expr = p_right
						}
						sqlite3_expr_set_error_offset(p_expr, i_err_ofst)
						p_new = sqlite3_expr_list_append(p_parse, p_new, p_expr)
						if usize(p_new) == usize(0) {
							break
						}
						px = unsafe { &p_new.a[0] + (p_new.nExpr - 1) }
						if (int(sel_flags) & 2048) != 0 && !(int(p_parse.eParseMode) >= 2) {
							if !isnil(p_nested_from) && (!0 || j < p_nested_from.nExpr) {
								px.zEName = sqlite3_db_str_dup(db, c2v_at(&p_nested_from.a[0], isize(j)).zEName)
							} else {
								px.zEName = sqlite3_mp_rintf(db, c'%s.%s.%s', voidptr(z_schema_name), voidptr(z_tab_name), voidptr(z_name))
							}
							px.fg.eEName = u32((if j == int(p_tab.nCol) { 3 } else { 2 }))
							mut __c2v_condition_81 := false
							mut __c2v_condition_82 := false
							__c2v_condition_82 = (int(p_from.fg.isUsing) && sqlite3_id_list_index(p_from.u3.pUsing, z_name) >= 0)
							__c2v_condition_81 = __c2v_condition_82
							if !__c2v_condition_81 {
								mut __c2v_condition_83 := false
								__c2v_condition_83 = (!isnil(p_using) && sqlite3_id_list_index(p_using, z_name) >= 0)
								__c2v_condition_81 = __c2v_condition_83
							}
							if !__c2v_condition_81 {
								mut __c2v_condition_84 := false
								__c2v_condition_84 = (j < int(p_tab.nCol) && (int(p_tab.aCol[j].colFlags) & 1024))
								__c2v_condition_81 = __c2v_condition_84
							}
							if __c2v_condition_81 {
								px.fg.bNoExpand = u32(1)
							}
						} else if long_names {
							px.zEName = sqlite3_mp_rintf(db, c'%s.%s', voidptr(z_tab_name), voidptr(z_name))
							px.fg.eEName = u32(0)
						} else {
							px.zEName = sqlite3_db_str_dup(db, z_name)
							px.fg.eEName = u32(0)
						}
					}
					c2v_for_next_153:
					c2v_pointer_postfix(voidptr(&p_from), p_from, isize(1))
				}
				if !table_seen {
					if ztn_ame {
						sqlite3_error_msg(p_parse, c'no such table: %s', voidptr(ztn_ame))
					} else {
						sqlite3_error_msg(p_parse, c'no tables specified')
					}
				}
			}
		}
		sqlite3_expr_list_delete(db, pel_ist)
		p.pEList = p_new
	}
	if p.pEList {
		if p.pEList.nExpr > db.aLimit[2] {
			sqlite3_error_msg(p_parse, c'too many columns in result set')
			return 2
		}
		if (elist_flags & u32((8 | 4194304))) != u32(0) {
			p.selFlags |= u32(262144)
		}
	}
	return 0
}

@[c:'sqlite3SelectExpand']
fn sqlite3_select_expand(p_parse &Parse, p_select &Select) {
	w := Walker{}
	w.xExprCallback = sqlite3_expr_walk_noop
	w.pParse = p_parse
	if p_parse.hasCompound {
		w.xSelectCallback = convert_compound_select_to_subquery
		w.xSelectCallback2 = 0
		sqlite3_walk_select(&w, p_select)
	}
	w.xSelectCallback = select_expander
	w.xSelectCallback2 = sqlite3_select_pop_with
	w.eCode = U16(0)
	sqlite3_walk_select(&w, p_select)
}

@[c:'selectAddSubqueryTypeInfo']
fn select_add_subquery_type_info(p_walker &Walker, p &Select) {
	c2v_gc_register_thread()
	p_parse := &Parse(0)
	i := 0
	p_tab_list := &SrcList(0)
	p_from := &SrcItem(0)
	if p.selFlags & u32(128) {
		return
	}
	p.selFlags |= u32(128)
	p_parse = p_walker.pParse
	p_tab_list = p.pSrc
	i = 0
	for p_from = unsafe { &p_tab_list.a[0] }; i < p_tab_list.nSrc; i++ {
		p_tab := p_from.pSTab
		if (p_tab.tabFlags & u32(16384)) != u32(0) && int(p_from.fg.isSubquery) {
			p_sel := p_from.u4.pSubq.pSelect
			sqlite3_subquery_column_types(p_parse, p_tab, p_sel, i8(64))
		}
		c2v_pointer_postfix(voidptr(&p_from), p_from, isize(1))
	}
}

@[c:'sqlite3SelectAddTypeInfo']
fn sqlite3_select_add_type_info(p_parse &Parse, p_select &Select) {
	w := Walker{}
	w.xSelectCallback = sqlite3_select_walk_noop
	w.xSelectCallback2 = select_add_subquery_type_info
	w.xExprCallback = sqlite3_expr_walk_noop
	w.pParse = p_parse
	sqlite3_walk_select(&w, p_select)
}

@[c:'sqlite3SelectPrep']
fn sqlite3_select_prep(p_parse &Parse, p &Select, p_outer_nc &NameContext) {
	if p_parse.db.mallocFailed {
		return
	}
	if p.selFlags & u32(128) {
		return
	}
	sqlite3_select_expand(p_parse, p)
	if p_parse.nErr {
		return
	}
	sqlite3_resolve_select_names(p_parse, p, p_outer_nc)
	if p_parse.nErr {
		return
	}
	sqlite3_select_add_type_info(p_parse, p)
}

@[c:'analyzeAggFuncArgs']
fn analyze_agg_func_args(p_agg_info &AggInfo, pnc &NameContext) {
	i := 0
	pnc.ncFlags |= 131072
	for i = 0; i < p_agg_info.nFunc; i++ {
		p_expr := p_agg_info.aFunc[i].pFExpr
		sqlite3_expr_analyze_agg_list(pnc, p_expr.x.pList)
		if p_expr.pLeft {
			sqlite3_expr_analyze_agg_list(pnc, p_expr.pLeft.x.pList)
		}
		if ((p_expr.flags & u32(16777216)) != u32(0)) {
			sqlite3_expr_analyze_aggregates(pnc, p_expr.y.pWin.pFilter)
		}
	}
	pnc.ncFlags &= ~131072
}

@[c:'optimizeAggregateUseOfIndexedExpr']
fn optimize_aggregate_use_of_indexed_expr(p_parse &Parse, p_select &Select, p_agg_info &AggInfo, pnc &NameContext) {
	p_agg_info.nColumn = p_agg_info.nAccumulator
	if (p_agg_info.nSortingColumn > u32(0)) {
		mx := p_select.pGroupBy.nExpr - 1
		j := 0
		k := 0

		for j = 0; j < p_agg_info.nColumn; j++ {
			k = p_agg_info.aCol[j].iSorterColumn
			if k > mx {
				mx = k
			}
		}
		p_agg_info.nSortingColumn = u32(mx + 1)
	}
	analyze_agg_func_args(p_agg_info, pnc)
}

@[c:'aggregateIdxEprRefToColCallback']
fn aggregate_idx_epr_ref_to_col_callback(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	p_agg_info := &AggInfo(0)
	p_col := &AggInfo_col(0)

	if usize(p_expr.pAggInfo) == usize(0) {
		return 0
	}
	if int(p_expr.op) == 170 {
		return 0
	}
	if int(p_expr.op) == 169 {
		return 0
	}
	if int(p_expr.op) == 179 {
		return 0
	}
	p_agg_info = p_expr.pAggInfo
	if (int(p_expr.iAgg) >= p_agg_info.nColumn) {
		return 0
	}
	p_col = unsafe { p_agg_info.aCol + p_expr.iAgg }
	p_expr.op = U8(170)
	p_expr.iTable = p_col.iTable
	p_expr.iColumn = YnVar(p_col.iColumn)
	p_expr.flags &= ~u32((8192 | 512 | 524288))
	return 1
}

@[c:'aggregateConvertIndexedExprRefToColumn']
fn aggregate_convert_indexed_expr_ref_to_column(p_agg_info &AggInfo) {
	i := 0
	w := Walker{}
	C.memset(voidptr(&w), 0, sizeof(w))
	w.xExprCallback = aggregate_idx_epr_ref_to_col_callback
	for i = 0; i < p_agg_info.nFunc; i++ {
		sqlite3_walk_expr(&w, p_agg_info.aFunc[i].pFExpr)
	}
}

@[c:'assignAggregateRegisters']
fn assign_aggregate_registers(p_parse &Parse, p_agg_info &AggInfo) {
	p_agg_info.iFirstReg = p_parse.nMem + 1
	p_parse.nMem += p_agg_info.nColumn + p_agg_info.nFunc
}

@[c:'resetAccumulator']
fn reset_accumulator(p_parse &Parse, p_agg_info &AggInfo) {
	v := p_parse.pVdbe
	i := 0
	p_func := &AggInfo_func(0)
	n_reg := p_agg_info.nFunc + p_agg_info.nColumn
	if n_reg == 0 {
		return
	}
	if p_parse.nErr {
		return
	}
	sqlite3_vdbe_add_op3(v, 77, 0, p_agg_info.iFirstReg, p_agg_info.iFirstReg + n_reg - 1)
	p_func = p_agg_info.aFunc
	for i = 0; i < p_agg_info.nFunc; i++ {
		if p_func.iDistinct >= 0 {
			pe := p_func.pFExpr
			if usize(pe.x.pList) == usize(0) || pe.x.pList.nExpr != 1 {
				sqlite3_error_msg(p_parse, c'DISTINCT aggregates must have exactly one argument')
				p_func.iDistinct = -1
			} else {
				p_key_info := sqlite3_key_info_from_expr_list(p_parse, pe.x.pList, 0, 0)
				p_func.iDistAddr = sqlite3_vdbe_add_op4(v, 120, p_func.iDistinct, 0, 0, &i8(voidptr(p_key_info)), (-9))
				sqlite3_vdbe_explain(p_parse, U8(0), c'USE TEMP B-TREE FOR %s(DISTINCT)', voidptr(p_func.pFunc.zName))
			}
		}
		if p_func.iOBTab >= 0 {
			pob_list := &ExprList(0)
			p_key_info := &KeyInfo(0)
			n_extra := 0
			pob_list = p_func.pFExpr.pLeft.x.pList
			if !p_func.bOBUnique {
				n_extra++
			}
			if p_func.bOBPayload {
				n_extra += p_func.pFExpr.x.pList.nExpr
			}
			if p_func.bUseSubtype {
				n_extra += p_func.pFExpr.x.pList.nExpr
			}
			p_key_info = sqlite3_key_info_from_expr_list(p_parse, pob_list, 0, n_extra)
			if !p_func.bOBUnique && p_parse.nErr == 0 {
				p_key_info.nKeyField++
			}
			sqlite3_vdbe_add_op4(v, 120, p_func.iOBTab, pob_list.nExpr + n_extra, 0, &i8(voidptr(p_key_info)), (-9))
			sqlite3_vdbe_explain(p_parse, U8(0), c'USE TEMP B-TREE FOR %s(ORDER BY)', voidptr(p_func.pFunc.zName))
		}
		c2v_pointer_postfix(voidptr(&p_func), p_func, isize(1))
	}
}

@[c:'finalizeAggFunctions']
fn finalize_agg_functions(p_parse &Parse, p_agg_info &AggInfo) {
	v := p_parse.pVdbe
	i := 0
	pf := &AggInfo_func(0)
	i = 0
	for pf = p_agg_info.aFunc; i < p_agg_info.nFunc; i++ {
		p_list := &ExprList(0)
		if p_parse.nErr {
			return
		}
		p_list = pf.pFExpr.x.pList
		if pf.iOBTab >= 0 {
			i_top := 0
			n_arg := 0
			n_key := 0
			reg_agg := 0
			j := 0
			n_arg = p_list.nExpr
			reg_agg = sqlite3_get_temp_range(p_parse, n_arg)
			if int(pf.bOBPayload) == 0 {
				n_key = 0
			} else {
				n_key = pf.pFExpr.pLeft.x.pList.nExpr
				if (!pf.bOBUnique) {
					n_key++
				}
			}
			i_top = sqlite3_vdbe_add_op1(v, 36, pf.iOBTab)
			for j = n_arg - 1; j >= 0; j-- {
				sqlite3_vdbe_add_op3(v, 96, pf.iOBTab, n_key + j, reg_agg + j)
			}
			if pf.bUseSubtype {
				reg_subtype := sqlite3_get_temp_reg(p_parse)
				i_base_col := n_key + n_arg + int((int(pf.bOBPayload) == 0 && int(pf.bOBUnique) == 0))
				for j = n_arg - 1; j >= 0; j-- {
					sqlite3_vdbe_add_op3(v, 96, pf.iOBTab, i_base_col + j, reg_subtype)
					sqlite3_vdbe_add_op2(v, 184, reg_subtype, reg_agg + j)
				}
				sqlite3_release_temp_reg(p_parse, reg_subtype)
			}
			sqlite3_vdbe_add_op3(v, 164, 0, reg_agg, (p_agg_info.iFirstReg + p_agg_info.nColumn + i))
			sqlite3_vdbe_append_p4(v, voidptr(pf.pFunc), (-8))
			sqlite3_vdbe_change_p5(v, U16(n_arg))
			sqlite3_vdbe_add_op2(v, 40, pf.iOBTab, i_top + 1)
			sqlite3_vdbe_jump_here(v, i_top)
			sqlite3_release_temp_range(p_parse, reg_agg, n_arg)
		}
		sqlite3_vdbe_add_op2(v, 167, (p_agg_info.iFirstReg + p_agg_info.nColumn + i), if p_list {
			p_list.nExpr
		} else {
			0
		})
		sqlite3_vdbe_append_p4(v, voidptr(pf.pFunc), (-8))
		c2v_pointer_postfix(voidptr(&pf), pf, isize(1))
	}
}

@[c:'updateAccumulator']
fn update_accumulator(p_parse &Parse, reg_acc int, p_agg_info &AggInfo, e_distinct_type int) {
	v := p_parse.pVdbe
	i := 0
	reg_hit := 0
	addr_hit_test := 0
	pf := &AggInfo_func(0)
	pc := &AggInfo_col(0)
	if p_parse.nErr {
		return
	}
	p_agg_info.directMode = U8(1)
	i = 0
	for pf = p_agg_info.aFunc; i < p_agg_info.nFunc; i++ {
		n_arg := 0
		addr_next := 0
		reg_agg := 0
		reg_agg_sz := 0
		reg_distinct := 0
		p_list := &ExprList(0)
		p_list = pf.pFExpr.x.pList
		if ((pf.pFExpr.flags & u32(16777216)) != u32(0)) {
			p_filter := pf.pFExpr.y.pWin.pFilter
			if p_agg_info.nAccumulator && (pf.pFunc.funcFlags & u32(32)) && reg_acc {
				if reg_hit == 0 {
					reg_hit = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
				}
				sqlite3_vdbe_add_op2(v, 82, reg_acc, reg_hit)
			}
			addr_next = sqlite3_vdbe_make_label(p_parse)
			sqlite3_expr_if_false(p_parse, p_filter, addr_next, 16)
		}
		if pf.iOBTab >= 0 {
			jj := 0
			pob_list := &ExprList(0)
			n_arg = p_list.nExpr
			pob_list = pf.pFExpr.pLeft.x.pList
			reg_agg_sz = pob_list.nExpr
			if !pf.bOBUnique {
				reg_agg_sz++
			}
			if pf.bOBPayload {
				reg_agg_sz += n_arg
			}
			if pf.bUseSubtype {
				reg_agg_sz += n_arg
			}
			reg_agg_sz++
			reg_agg = sqlite3_get_temp_range(p_parse, reg_agg_sz)
			reg_distinct = reg_agg
			sqlite3_expr_code_expr_list(p_parse, pob_list, reg_agg, 0, U8(1))
			jj = pob_list.nExpr
			if !pf.bOBUnique {
				sqlite3_vdbe_add_op2(v, 128, pf.iOBTab, reg_agg + jj)
				jj++
			}
			if pf.bOBPayload {
				reg_distinct = reg_agg + jj
				sqlite3_expr_code_expr_list(p_parse, p_list, reg_distinct, 0, U8(1))
				jj += n_arg
			}
			if pf.bUseSubtype {
				kk := 0
				reg_base := if int(pf.bOBPayload) { reg_distinct } else { reg_agg }
				for kk = 0; kk < n_arg; kk++ {
					sqlite3_vdbe_add_op2(v, 183, reg_base + kk, reg_agg + jj)
					jj++
				}
			}
		} else if p_list {
			n_arg = p_list.nExpr
			reg_agg = sqlite3_get_temp_range(p_parse, n_arg)
			reg_distinct = reg_agg
			sqlite3_expr_code_expr_list(p_parse, p_list, reg_agg, 0, U8(1))
		} else {
			n_arg = 0
			reg_agg = 0
		}
		if pf.iDistinct >= 0 && !isnil(p_list) {
			if addr_next == 0 {
				addr_next = sqlite3_vdbe_make_label(p_parse)
			}
			pf.iDistinct = code_distinct(p_parse, e_distinct_type, pf.iDistinct, addr_next, p_list, reg_distinct)
		}
		if pf.iOBTab >= 0 {
			sqlite3_vdbe_add_op3(v, 99, reg_agg, reg_agg_sz - 1, reg_agg + reg_agg_sz - 1)
			sqlite3_vdbe_add_op4_int(v, 140, pf.iOBTab, reg_agg + reg_agg_sz - 1, reg_agg, reg_agg_sz - 1)
			sqlite3_release_temp_range(p_parse, reg_agg, reg_agg_sz)
		} else {
			if pf.pFunc.funcFlags & u32(32) {
				p_coll := unsafe { &CollSeq(nil) }
				p_item := &ExprList_item(0)
				j := 0
				j = 0
				for p_item = unsafe { &p_list.a[0] }; isnil(p_coll) && j < n_arg; j++ {
					p_coll = sqlite3_expr_coll_seq(p_parse, p_item.pExpr)
					c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
				}
				if isnil(p_coll) {
					p_coll = p_parse.db.pDfltColl
				}
				if reg_hit == 0 && p_agg_info.nAccumulator {
					reg_hit = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
				}
				sqlite3_vdbe_add_op4(v, 87, reg_hit, 0, 0, &i8(voidptr(p_coll)), (-2))
			}
			sqlite3_vdbe_add_op3(v, 164, 0, reg_agg, (p_agg_info.iFirstReg + p_agg_info.nColumn + i))
			sqlite3_vdbe_append_p4(v, voidptr(pf.pFunc), (-8))
			sqlite3_vdbe_change_p5(v, U16(n_arg))
			sqlite3_release_temp_range(p_parse, reg_agg, n_arg)
		}
		if addr_next {
			sqlite3_vdbe_resolve_label(v, addr_next)
		}
		if p_parse.nErr {
			return
		}
		c2v_pointer_postfix(voidptr(&pf), pf, isize(1))
	}
	if reg_hit == 0 && p_agg_info.nAccumulator {
		reg_hit = reg_acc
	}
	if reg_hit {
		addr_hit_test = sqlite3_vdbe_add_op1(v, 16, reg_hit)
	}
	i = 0
	for pc = p_agg_info.aCol; i < p_agg_info.nAccumulator; i++ {
		sqlite3_expr_code(p_parse, pc.pCExpr, (p_agg_info.iFirstReg + i))
		if p_parse.nErr {
			return
		}
		c2v_pointer_postfix(voidptr(&pc), pc, isize(1))
	}
	p_agg_info.directMode = U8(0)
	if addr_hit_test {
		sqlite3_vdbe_jump_here_or_pop_inst(v, addr_hit_test)
	}
}

@[c:'explainSimpleCount']
fn explain_simple_count(p_parse &Parse, p_tab &Table, p_idx &Index) {
	if int(p_parse.explain) == 2 {
		b_cover := int((usize(p_idx) != usize(0) && (((p_tab.tabFlags & u32(128)) == u32(0)) || !(int(p_idx.idxType) == 2))))
		sqlite3_vdbe_explain(p_parse, U8(0), c'SCAN %s%s%s', voidptr(p_tab.zName), voidptr(if b_cover {
			c' USING COVERING INDEX '
		} else {
			c''
		}), voidptr(if b_cover { p_idx.zName } else { c'' }))
	}
}

@[c:'havingToWhereExprCb']
fn having_to_where_expr_cb(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	if int(p_expr.op) != 44 {
		ps := p_walker.u.pSelect
		if sqlite3_expr_is_constant_or_group_by(p_walker.pParse, p_expr, ps.pGroupBy) && ((p_expr.flags & u32((1 | 536870912))) == u32(536870912)) == 0 && usize(p_expr.pAggInfo) == usize(0) {
			db := p_walker.pParse.db
			p_new := sqlite3_expr_int32(db, 1)
			if p_new {
				p_where := ps.pWhere
				t := (unsafe { *p_new })
				unsafe { *p_new = *p_expr }
				unsafe { *p_expr = t }
				p_new = sqlite3_expr_and(p_walker.pParse, p_where, p_new)
				ps.pWhere = p_new
				p_walker.eCode = U16(1)
			}
		}
		return 1
	}
	return 0
}

@[c:'havingToWhere']
fn having_to_where(p_parse &Parse, p &Select) {
	s_walker := Walker{}
	C.memset(voidptr(&s_walker), 0, sizeof(s_walker))
	s_walker.pParse = p_parse
	s_walker.xExprCallback = having_to_where_expr_cb
	s_walker.u.pSelect = p
	sqlite3_walk_expr(&s_walker, p.pHaving)
}

@[c:'isSelfJoinView']
fn is_self_join_view(p_tab_list &SrcList, p_this &SrcItem, i_first int, i_end int) &SrcItem {
	p_item := &SrcItem(0)
	p_sel := &Select(0)
	p_sel = p_this.u4.pSubq.pSelect
	if p_sel.selFlags & u32(16777216) {
		return unsafe { nil }
	}
	for i_first < i_end {
		p_s1 := &Select(0)
		p_item = unsafe { &p_tab_list.a[0] + i_first++ }
		if !p_item.fg.isSubquery {
			continue
		}
		if p_item.fg.viaCoroutine {
			continue
		}
		if usize(p_item.zName) == usize(0) {
			continue
		}
		if usize(p_item.pSTab.pSchema) != usize(p_this.pSTab.pSchema) {
			continue
		}
		if sqlite3_stricmp(p_item.zName, p_this.zName) != 0 {
			continue
		}
		p_s1 = p_item.u4.pSubq.pSelect
		if usize(p_item.pSTab.pSchema) == usize(0) && p_sel.selId != p_s1.selId {
			continue
		}
		if p_s1.selFlags & u32(16777216) {
			continue
		}
		return p_item
	}
	return unsafe { nil }
}

@[c:'agginfoFree']
fn agginfo_free(db &Sqlite3, p_arg voidptr) {
	c2v_gc_register_thread()
	p := &AggInfo(p_arg)
	sqlite3_db_free(db, voidptr(p.aCol))
	sqlite3_db_free(db, voidptr(p.aFunc))
	sqlite3_db_free_nn(db, voidptr(p))
}

@[c:'countOfViewOptimization']
fn count_of_view_optimization(p_parse &Parse, p &Select) int {
	p_sub := &Select(0)
	p_prior := &Select(0)

	p_expr := &Expr(0)
	p_count := &Expr(0)
	db := &Sqlite3(0)
	p_from := &SrcItem(0)
	if (p.selFlags & u32(8)) == u32(0) {
		return 0
	}
	if p.pEList.nExpr != 1 {
		return 0
	}
	if p.pWhere {
		return 0
	}
	if p.pHaving {
		return 0
	}
	if p.pGroupBy {
		return 0
	}
	if p.pOrderBy {
		return 0
	}
	p_expr = c2v_at(&p.pEList.a[0], isize(0)).pExpr
	if int(p_expr.op) != 169 {
		return 0
	}
	if sqlite3_stricmp(p_expr.u.zToken, c'count') {
		return 0
	}
	if usize(p_expr.x.pList) != usize(0) {
		return 0
	}
	if p.pSrc.nSrc != 1 {
		return 0
	}
	if ((p_expr.flags & u32(16777216)) != u32(0)) {
		return 0
	}
	p_from = unsafe { &p.pSrc.a[0] }
	if int(p_from.fg.isSubquery) == 0 {
		return 0
	}
	p_sub = p_from.u4.pSubq.pSelect
	if usize(p_sub.pPrior) == usize(0) {
		return 0
	}
	if p_sub.selFlags & u32(67108864) {
		return 0
	}
	for {
		if int(p_sub.op) != 136 && !isnil(p_sub.pPrior) {
			return 0
		}
		if p_sub.pWhere {
			return 0
		}
		if p_sub.pLimit {
			return 0
		}
		if p_sub.selFlags & u32((8 | 1)) {
			return 0
		}
		p_sub = p_sub.pPrior
		if !p_sub {
			break
		}
	}
	db = p_parse.db
	p_count = p_expr
	p_expr = 0
	p_sub = sqlite3_subquery_detach(db, p_from)
	sqlite3_src_list_delete(db, p.pSrc)
	p.pSrc = sqlite3_db_malloc_zero(p_parse.db, U64(((u64(usize(__offsetof(SrcList, a)))) + sizeof(SrcItem))))
	for p_sub {
		p_term := &Expr(0)
		p_prior = p_sub.pPrior
		p_sub.pPrior = 0
		p_sub.pNext = 0
		p_sub.selFlags |= u32(8)
		p_sub.selFlags &= ~u32(256)
		p_sub.nSelectRow = LogEst(0)
		sqlite3_parser_add_cleanup(p_parse, sqlite3_expr_list_delete_generic, voidptr(p_sub.pEList))
		p_term = if p_prior { sqlite3_expr_dup(db, p_count, 0) } else { p_count }
		p_sub.pEList = sqlite3_expr_list_append(p_parse, unsafe { nil }, p_term)
		p_term = sqlite3_pe_xpr(p_parse, 139, unsafe { nil }, unsafe { nil })
		sqlite3_pe_xpr_add_select(p_parse, p_term, p_sub)
		if usize(p_expr) == usize(0) {
			p_expr = p_term
		} else {
			p_expr = sqlite3_pe_xpr(p_parse, 107, p_term, p_expr)
		}
		p_sub = p_prior
	}
	mut __c2v_lhs_tmp_144 := c2v_at(&p.pEList.a[0], isize(0))
	__c2v_lhs_tmp_144.pExpr = p_expr
	p.selFlags &= ~u32(8)
	return 1
}

@[c:'sameSrcAlias']
fn same_src_alias(p0 &SrcItem, p_src &SrcList) int {
	i := 0
	for i = 0; i < p_src.nSrc; i++ {
		p1 := unsafe { &p_src.a[0] + i }
		if usize(p1) == usize(p0) {
			continue
		}
		if usize(p0.pSTab) == usize(p1.pSTab) && 0 == sqlite3_stricmp(p0.zAlias, p1.zAlias) {
			return 1
		}
		if int(p1.fg.isSubquery) && (p1.u4.pSubq.pSelect.selFlags & u32(2048)) != u32(0) && same_src_alias(p0, p1.u4.pSubq.pSelect.pSrc) {
			return 1
		}
	}
	return 0
}

@[c:'fromClauseTermCanBeCoroutine']
fn from_clause_term_can_be_coroutine(p_parse &Parse, p_tab_list &SrcList, i int, sel_flags int) int {
	p_item := unsafe { &p_tab_list.a[0] + i }
	if p_item.fg.isCte {
		p_cte_use := p_item.u2.pCteUse
		if int(p_cte_use.eM10d) == 0 {
			return 0
		}
		if p_cte_use.nUse >= 2 && int(p_cte_use.eM10d) != 2 {
			return 0
		}
	}
	if int(c2v_at(&p_tab_list.a[0], isize(0)).fg.jointype) & 64 {
		return 0
	}
	if ((p_parse.db.dbOptFlags & u32(33554432)) != u32(0)) {
		return 0
	}
	if usize(is_self_join_view(p_tab_list, p_item, i + 1, p_tab_list.nSrc)) != usize(0) {
		return 0
	}
	if i == 0 {
		if p_tab_list.nSrc == 1 {
			return 1
		}
		if int(c2v_at(&p_tab_list.a[0], isize(1)).fg.jointype) & 2 {
			return 1
		}
		if sel_flags & 268435456 {
			return 0
		}
		return 1
	}
	if sel_flags & 268435456 {
		return 0
	}
	for {
		if int(p_item.fg.jointype) & (32 | 2) {
			return 0
		}
		if i == 0 {
			break
		}
		i--
		c2v_pointer_postfix(voidptr(&p_item), p_item, isize(-1))
		if p_item.fg.isSubquery {
			return 0
		}
	}
	return 1
}

@[c:'existsToJoin']
fn exists_to_join(p_parse &Parse, p &Select, p_where &Expr) {
	mut __c2v_condition_85 := false
	mut __c2v_condition_86 := false
	__c2v_condition_86 = p_parse.nErr == 0
	if __c2v_condition_86 {
		__c2v_condition_86 = usize(p_where) != usize(0)
	}
	if __c2v_condition_86 {
		__c2v_condition_86 = !((p_where.flags & u32((1 | 2))) != u32(0))
	}
	if __c2v_condition_86 {
		__c2v_condition_86 = (usize(p.pSrc) != usize(0))
	}
	if __c2v_condition_86 {
		__c2v_condition_86 = p.pSrc.nSrc < (int((sizeof(Bitmask) * u64(8))))
	}
	if __c2v_condition_86 {
		__c2v_condition_86 = (usize(p.pLimit) == usize(0) || usize(p.pLimit.pRight) == usize(0))
	}
	__c2v_condition_85 = __c2v_condition_86
	if __c2v_condition_85 {
		if int(p_where.op) == 44 {
			p_right := p_where.pRight
			exists_to_join(p_parse, p, p_where.pLeft)
			exists_to_join(p_parse, p, p_right)
		} else if int(p_where.op) == 20 {
			p_sub := p_where.x.pSelect
			p_sub_where := p_sub.pWhere
			if p_sub.pSrc.nSrc == 1 && (p_sub.selFlags & u32(8)) == u32(0) && !c2v_at(&p_sub.pSrc.a[0], isize(0)).fg.isSubquery && usize(p_sub.pLimit) == usize(0) && usize(p_sub.pPrior) == usize(0) {
				db := p_parse.db
				a_csr_map := &int(sqlite3_db_malloc_zero(db, U64(u64((p_parse.nTab + 2)) * sizeof(int))))
				if usize(a_csr_map) == usize(0) {
					return
				}
				a_csr_map[0] = (p_parse.nTab + 1)
				renumber_cursors(p_parse, p_sub, -1, a_csr_map)
				sqlite3_db_free(db, voidptr(a_csr_map))
				C.memset(voidptr(p_where), 0, sizeof(Expr))
				p_where.op = U8(156)
				p_where.u.iValue = 1
				p_where.flags |= u32(2048)
				mut __c2v_lhs_tmp_145 := c2v_at(&p_sub.pSrc.a[0], isize(0))
				__c2v_lhs_tmp_145.fg.fromExists = u32(1)
				p.pSrc = sqlite3_src_list_append_list(p_parse, p.pSrc, p_sub.pSrc)
				if p_sub_where {
					p.pWhere = sqlite3_pe_xpr(p_parse, 44, p.pWhere, p_sub_where)
					p_sub.pWhere = 0
				}
				p_sub.pSrc = 0
				sqlite3_parser_add_cleanup(p_parse, sqlite3_select_delete_generic, voidptr(p_sub))
			}
		}
	}
}

struct CheckOnCtx {
	pSrc     &SrcList
	iJoin    int
	bFuncArg int
	pParent  &CheckOnCtx
}

@[c:'selectCheckOnClausesExpr']
fn select_check_on_clauses_expr(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	p_ctx := p_walker.u.pCheckOnCtx
	if ((p_expr.flags & u32(1)) != u32(0)) || (((p_expr.flags & u32(2)) != u32(0)) && ((int(c2v_at(&p_ctx.pSrc.a[0], isize(0)).fg.jointype) & 64) != 0)) {
		if p_ctx.iJoin == 0 {
			p_ctx.iJoin = p_expr.w.iJoin
			sqlite3_walk_expr_nn(p_walker, p_expr)
			p_ctx.iJoin = 0
			return 1
		}
	}
	if int(p_expr.op) == 168 {
		for {
			p_src := p_ctx.pSrc
			n_src := p_src.nSrc
			i_tab := p_expr.iTable
			ii := 0
			for ii = 0; ii < n_src && c2v_at(&p_src.a[0], isize(ii)).iCursor != i_tab; ii++ {
			}
			if ii < n_src {
				if p_ctx.iJoin && i_tab > p_ctx.iJoin {
					sqlite3_error_msg(p_walker.pParse, c'%s references tables to its right', voidptr((if p_ctx.bFuncArg {
						c'table-function argument'
					} else {
						c'ON clause'
					})))
					return 2
				}
				break
			}
			p_ctx = p_ctx.pParent
			if !p_ctx {
				break
			}
		}
	}
	return 0
}

@[c:'selectCheckOnClausesSelect']
fn select_check_on_clauses_select(p_walker &Walker, p_select &Select) int {
	c2v_gc_register_thread()
	p_ctx := p_walker.u.pCheckOnCtx
	if usize(p_select.pSrc) == usize(p_ctx.pSrc) || p_select.pSrc.nSrc == 0 {
		return 0
	} else {
		s_ctx := CheckOnCtx{}
		C.memset(voidptr(&s_ctx), 0, sizeof(s_ctx))
		s_ctx.pSrc = p_select.pSrc
		s_ctx.pParent = p_ctx
		p_walker.u.pCheckOnCtx = &s_ctx
		sqlite3_walk_select(p_walker, p_select)
		p_walker.u.pCheckOnCtx = p_ctx
		p_select.selFlags &= u32(~1073741824)
		return 1
	}
}

@[c:'sqlite3SelectCheckOnClauses']
fn sqlite3_select_check_on_clauses(p_parse &Parse, p_select &Select) {
	w := Walker{}
	s_ctx := CheckOnCtx{}
	ii := 0
	C.memset(voidptr(&w), 0, sizeof(w))
	w.pParse = p_parse
	w.xExprCallback = select_check_on_clauses_expr
	w.xSelectCallback = select_check_on_clauses_select
	w.u.pCheckOnCtx = &s_ctx
	C.memset(voidptr(&s_ctx), 0, sizeof(s_ctx))
	s_ctx.pSrc = p_select.pSrc
	sqlite3_walk_expr(&w, p_select.pWhere)
	p_select.selFlags &= u32(~1073741824)
	s_ctx.bFuncArg = 1
	for ii = 0; ii < p_select.pSrc.nSrc; ii++ {
		p_item := unsafe { &p_select.pSrc.a[0] + ii }
		if int(p_item.fg.isTabFunc) && (int(p_item.fg.jointype) & 32) {
			s_ctx.iJoin = p_item.iCursor
			sqlite3_walk_expr_list(&w, p_item.u1.pFuncArg)
		}
	}
}

@[c:'sqlite3CopySortOrder']
fn sqlite3_copy_sort_order(p1 &ExprList, p2 &ExprList) int {
	if !isnil(p2) && p1.nExpr == p2.nExpr {
		ii := 0
		for ii = 0; ii < p1.nExpr; ii++ {
			sort_flags := U8(0)
			sort_flags = U8(int(c2v_at(&p2.a[0], isize(ii)).fg.sortFlags) & 1)
			mut __c2v_lhs_tmp_146 := c2v_at(&p1.a[0], isize(ii))
			__c2v_lhs_tmp_146.fg.sortFlags = sort_flags
		}
		return 1
	} else {
		return 0
	}
}

@[c:'sqlite3Select']
fn sqlite3_select(p_parse &Parse, p &Select, p_dest &SelectDest) int {
	i := 0
	j := 0

	pwi_nfo := &WhereInfo(0)
	v := &Vdbe(0)
	is_agg := 0
	pel_ist := unsafe { &ExprList(nil) }
	p_tab_list := &SrcList(0)
	p_where := &Expr(0)
	p_group_by := &ExprList(0)
	p_having := &Expr(0)
	p_agg_info := unsafe { &AggInfo(nil) }
	rc := 1
	s_distinct := DistinctCtx{}
	s_sort := SortCtx{}
	i_end := 0
	db := &Sqlite3(0)
	p_min_max_order_by := unsafe { &ExprList(nil) }
	min_max_flag := U8(0)
	db = p_parse.db
	v = sqlite3_get_vdbe(p_parse)
	if usize(p) == usize(0) || p_parse.nErr {
		return 1
	}
	if sqlite3_auth_check(p_parse, 21, unsafe { nil }, unsafe { nil }, unsafe { nil }) {
		return 1
	}
	if (int(p_dest.eDest) <= 4) {
		if p.pOrderBy {
			sqlite3_parser_add_cleanup(p_parse, sqlite3_expr_list_delete_generic, voidptr(p.pOrderBy))
			p.pOrderBy = 0
		}
		p.selFlags &= ~u32(1)
	}
	sqlite3_select_prep(p_parse, p, unsafe { nil })
	if p_parse.nErr {
		unsafe { goto select_end
		 }
	}
	if p.selFlags & u32(8388608) {
		p0 := unsafe { &p.pSrc.a[0] + 0 }
		if same_src_alias(p0, p.pSrc) {
			sqlite3_error_msg(p_parse, c'target object/alias may not appear in FROM clause: %s', voidptr(if p0.zAlias {
				p0.zAlias
			} else {
				p0.pSTab.zName
			}))
			unsafe { goto select_end
			 }
		}
		p.selFlags &= ~u32(8388608)
	}
	if int(p_dest.eDest) == 7 {
		sqlite3_generate_column_names(p_parse, p)
	}
	if sqlite3_window_rewrite(p_parse, p) {
		unsafe { goto select_end
		 }
	}
	p_tab_list = p.pSrc
	is_agg = (p.selFlags & u32(8)) != u32(0)
	C.memset(voidptr(&s_sort), 0, sizeof(s_sort))
	s_sort.pOrderBy = p.pOrderBy
	for i = 0; isnil(p.pPrior) && i < p_tab_list.nSrc; i++ {
		p_item := unsafe { &p_tab_list.a[0] + i }
		p_sub := unsafe { if int(p_item.fg.isSubquery) {
			p_item.u4.pSubq.pSelect
		} else {
			&Select(nil)
		} }
		p_tab := p_item.pSTab
		if (int(p_item.fg.jointype) & (8 | 64)) != 0 && sqlite3_expr_implies_non_null_row(p.pWhere, p_item.iCursor, int(p_item.fg.jointype) & 64) && ((db.dbOptFlags & u32(8192)) == u32(0)) {
			if int(p_item.fg.jointype) & 8 {
				if int(p_item.fg.jointype) & 16 {
					p_item.fg.jointype &= ~8
				} else {
					p_item.fg.jointype &= ~(8 | 32)
					unset_join_expr(p.pWhere, p_item.iCursor, 0)
				}
			}
			if int(p_item.fg.jointype) & 64 {
				for j = i + 1; j < p_tab_list.nSrc; j++ {
					p_i2 := unsafe { &p_tab_list.a[0] + j }
					if int(p_i2.fg.jointype) & 16 {
						if int(p_i2.fg.jointype) & 8 {
							p_i2.fg.jointype &= ~16
						} else {
							p_i2.fg.jointype &= ~(16 | 32)
							unset_join_expr(p.pWhere, p_i2.iCursor, 1)
						}
					}
				}
				for j = p_tab_list.nSrc - 1; j >= 0; j-- {
					mut __c2v_lhs_tmp_147 := c2v_at(&p_tab_list.a[0], isize(j))
					__c2v_lhs_tmp_147.fg.jointype &= ~64
					if int(c2v_at(&p_tab_list.a[0], isize(j)).fg.jointype) & 16 {
						break
					}
				}
			}
		}
		if usize(p_sub) == usize(0) {
			continue
		}
		if int(p_tab.nCol) != p_sub.pEList.nExpr {
			sqlite3_error_msg(p_parse, c"expected %d columns for '%s' but got %d", int(p_tab.nCol), voidptr(p_tab.zName), p_sub.pEList.nExpr)
			unsafe { goto select_end
			 }
		}
		if int(p_item.fg.isCte) && int(p_item.u2.pCteUse.eM10d) == 0 {
			continue
		}
		if (p_sub.selFlags & u32(8)) != u32(0) {
			continue
		}
		mut __c2v_condition_87 := false
		mut __c2v_condition_88 := false
		__c2v_condition_88 = usize(p_sub.pOrderBy) != usize(0)
		if __c2v_condition_88 {
			__c2v_condition_88 = (usize(p.pOrderBy) != usize(0) || p_tab_list.nSrc > 1)
		}
		if __c2v_condition_88 {
			__c2v_condition_88 = usize(p_sub.pLimit) == usize(0)
		}
		if __c2v_condition_88 {
			__c2v_condition_88 = (p_sub.selFlags & u32((134217728 | 8192))) == u32(0)
		}
		if __c2v_condition_88 {
			__c2v_condition_88 = (p.selFlags & u32(134217728)) == u32(0)
		}
		if __c2v_condition_88 {
			__c2v_condition_88 = ((db.dbOptFlags & u32(262144)) == u32(0))
		}
		__c2v_condition_87 = __c2v_condition_88
		if __c2v_condition_87 {
			sqlite3_parser_add_cleanup(p_parse, sqlite3_expr_list_delete_generic, voidptr(p_sub.pOrderBy))
			p_sub.pOrderBy = 0
		}
		if usize(p_sub.pOrderBy) != usize(0) && i == 0 && (p.selFlags & u32(262144)) != u32(0) && (p_tab_list.nSrc == 1 || (int(c2v_at(&p_tab_list.a[0], isize(1)).fg.jointype) & (32 | 2)) != 0) {
			continue
		}
		if flatten_subquery(p_parse, p, i, is_agg) {
			if p_parse.nErr {
				unsafe { goto select_end
				 }
			}
			i = -1
		}
		p_tab_list = p.pSrc
		if db.mallocFailed {
			unsafe { goto select_end
			 }
		}
		if !(int(p_dest.eDest) <= 6) {
			s_sort.pOrderBy = p.pOrderBy
		}
	}
	if p.pPrior {
		rc = multi_select(p_parse, p, p_dest)
		if usize(p.pNext) == usize(0) {
			sqlite3_vdbe_explain_pop(p_parse)
		}
		return rc
	}
	if int(p_parse.bHasExists) && ((db.dbOptFlags & u32(1073741824)) == u32(0)) {
		exists_to_join(p_parse, p, p.pWhere)
		p_tab_list = p.pSrc
	}
	if usize(p.pWhere) != usize(0) && int(p.pWhere.op) == 44 && ((db.dbOptFlags & u32(32768)) == u32(0)) && propagate_constants(p_parse, p) {
	} else {
	}
	if ((db.dbOptFlags & u32((1 | 512))) == u32(0)) && count_of_view_optimization(p_parse, p) {
		if db.mallocFailed {
			unsafe { goto select_end
			 }
		}
		p_tab_list = p.pSrc
	}
	for i = 0; i < p_tab_list.nSrc; i++ {
		p_item := unsafe { &p_tab_list.a[0] + i }
		p_prior := &SrcItem(0)
		dest := SelectDest{}
		p_subq := &Subquery(0)
		p_sub := &Select(0)
		z_saved_auth_context := &i8(0)
		if p_item.colUsed == Bitmask(0) && usize(p_item.zName) != usize(0) {
			z_db := &i8(0)
			if p_item.fg.fixedSchema {
				i_db := sqlite3_schema_to_index(p_parse.db, p_item.u4.pSchema)
				z_db = db.aDb[i_db].zDbSName
			} else if p_item.fg.isSubquery {
				z_db = 0
			} else {
				z_db = p_item.u4.zDatabase
			}
			sqlite3_auth_check(p_parse, 20, p_item.zName, c'', z_db)
		}
		if int(p_item.fg.isSubquery) == 0 {
			continue
		}
		p_subq = p_item.u4.pSubq
		p_sub = p_subq.pSelect
		if p_subq.addrFillSub != 0 {
			continue
		}
		p_parse.nHeight += sqlite3_select_expr_height(p)
		mut __c2v_condition_89 := false
		mut __c2v_condition_90 := false
		__c2v_condition_90 = ((db.dbOptFlags & u32(4096)) == u32(0))
		if __c2v_condition_90 {
			__c2v_condition_90 = (int(p_item.fg.isCte) == 0 || (int(p_item.u2.pCteUse.eM10d) != 0 && p_item.u2.pCteUse.nUse < 2))
		}
		if __c2v_condition_90 {
			__c2v_condition_90 = push_down_where_terms(p_parse, p_sub, p.pWhere, p_tab_list, i)
		}
		__c2v_condition_89 = __c2v_condition_90
		if __c2v_condition_89 {
		} else {
		}
		if ((db.dbOptFlags & u32(67108864)) == u32(0)) && disable_unused_subquery_result_columns(p_item) {
		}
		z_saved_auth_context = p_parse.zAuthContext
		p_parse.zAuthContext = p_item.zName
		if from_clause_term_can_be_coroutine(p_parse, p_tab_list, i, int(p.selFlags)) {
			addr_top := sqlite3_vdbe_current_addr(v) + 1
			p_subq.regReturn = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			sqlite3_vdbe_add_op3(v, 11, p_subq.regReturn, 0, addr_top)
			p_subq.addrFillSub = addr_top
			sqlite3_select_dest_init(&dest, 11, p_subq.regReturn)
			sqlite3_vdbe_explain(p_parse, U8(1), c'CO-ROUTINE %!S', voidptr(p_item))
			sqlite3_select(p_parse, p_sub, &dest)
			p_item.pSTab.nRowLogEst = p_sub.nSelectRow
			p_item.fg.viaCoroutine = u32(1)
			p_subq.regResult = dest.iSdst
			sqlite3_vdbe_end_coroutine(v, p_subq.regReturn)
			sqlite3_vdbe_jump_here(v, addr_top - 1)
			sqlite3_clear_temp_reg_cache(p_parse)
		} else if int(p_item.fg.isCte) && p_item.u2.pCteUse.addrM9e > 0 {
			p_cte_use := p_item.u2.pCteUse
			sqlite3_vdbe_add_op2(v, 10, p_cte_use.regRtn, p_cte_use.addrM9e)
			if p_item.iCursor != p_cte_use.iCur {
				sqlite3_vdbe_add_op2(v, 117, p_item.iCursor, p_cte_use.iCur)
			}
			p_sub.nSelectRow = p_cte_use.nRowEst
		} else {
			p_prior = is_self_join_view(p_tab_list, p_item, 0, i)
			if usize(p_prior) != usize(0) {
				p_prior_subq := &Subquery(0)
				p_prior_subq = p_prior.u4.pSubq
				if p_prior_subq.addrFillSub {
					sqlite3_vdbe_add_op2(v, 10, p_prior_subq.regReturn, p_prior_subq.addrFillSub)
				}
				sqlite3_vdbe_add_op2(v, 117, p_item.iCursor, p_prior.iCursor)
				p_sub.nSelectRow = p_prior_subq.pSelect.nSelectRow
			} else {
				top_addr := 0
				once_addr := 0
				p_subq.regReturn = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
				top_addr = sqlite3_vdbe_add_op0(v, 9)
				p_subq.addrFillSub = top_addr + 1
				p_item.fg.isMaterialized = u32(1)
				if int(p_item.fg.isCorrelated) == 0 {
					once_addr = sqlite3_vdbe_add_op0(v, 15)
				} else {
				}
				sqlite3_select_dest_init(&dest, 10, p_item.iCursor)
				sqlite3_vdbe_explain(p_parse, U8(1), c'MATERIALIZE %!S', voidptr(p_item))
				sqlite3_select(p_parse, p_sub, &dest)
				p_item.pSTab.nRowLogEst = p_sub.nSelectRow
				if once_addr {
					sqlite3_vdbe_jump_here(v, once_addr)
				}
				sqlite3_vdbe_add_op2(v, 69, p_subq.regReturn, top_addr + 1)
				sqlite3_vdbe_jump_here(v, top_addr)
				sqlite3_clear_temp_reg_cache(p_parse)
				if int(p_item.fg.isCte) && int(p_item.fg.isCorrelated) == 0 {
					p_cte_use := p_item.u2.pCteUse
					p_cte_use.addrM9e = p_subq.addrFillSub
					p_cte_use.regRtn = p_subq.regReturn
					p_cte_use.iCur = p_item.iCursor
					p_cte_use.nRowEst = p_sub.nSelectRow
				}
			}
		}
		if db.mallocFailed {
			unsafe { goto select_end
			 }
		}
		p_parse.nHeight -= sqlite3_select_expr_height(p)
		p_parse.zAuthContext = z_saved_auth_context
	}
	pel_ist = p.pEList
	p_where = p.pWhere
	p_group_by = p.pGroupBy
	p_having = p.pHaving
	s_distinct.isTnct = U8((p.selFlags & u32(1)) != u32(0))
	mut __c2v_condition_91 := false
	mut __c2v_condition_92 := false
	__c2v_condition_92 = (p.selFlags & u32((1 | 8))) == u32(1)
	if __c2v_condition_92 {
		__c2v_condition_92 = sqlite3_copy_sort_order(pel_ist, s_sort.pOrderBy)
	}
	if __c2v_condition_92 {
		__c2v_condition_92 = sqlite3_expr_list_compare(pel_ist, s_sort.pOrderBy, -1) == 0
	}
	if __c2v_condition_92 {
		__c2v_condition_92 = ((db.dbOptFlags & u32(4)) == u32(0))
	}
	if __c2v_condition_92 {
		__c2v_condition_92 = usize(p.pWin) == usize(0)
	}
	__c2v_condition_91 = __c2v_condition_92
	if __c2v_condition_91 {
		p.selFlags &= ~u32(1)
		p.pGroupBy = sqlite3_expr_list_dup(db, pel_ist, 0)
		p_group_by = p.pGroupBy
		if p_group_by {
			for i = 0; i < p_group_by.nExpr; i++ {
				mut __c2v_lhs_tmp_148 := c2v_at(&p_group_by.a[0], isize(i))
				__c2v_lhs_tmp_148.u.x.iOrderByCol = U16(i + 1)
			}
		}
		p.selFlags |= u32(8)
		s_distinct.isTnct = U8(2)
	}
	if s_sort.pOrderBy {
		p_key_info := &KeyInfo(0)
		p_key_info = sqlite3_key_info_from_expr_list(p_parse, s_sort.pOrderBy, 0, pel_ist.nExpr)
		mut __c2v_postfix_value_30 := p_parse.nTab
		p_parse.nTab++
		s_sort.iECursor = __c2v_postfix_value_30
		s_sort.addrSortIndex = sqlite3_vdbe_add_op4(v, 120, s_sort.iECursor, s_sort.pOrderBy.nExpr + 1 + pel_ist.nExpr, 0, &i8(voidptr(p_key_info)), (-9))
	} else {
		s_sort.addrSortIndex = -1
	}
	if int(p_dest.eDest) == 10 {
		sqlite3_vdbe_add_op2(v, 120, p_dest.iSDParm, pel_ist.nExpr)
		if p.selFlags & u32(2048) {
			ii := 0
			for ii = pel_ist.nExpr - 1; ii > 0 && int(c2v_at(&pel_ist.a[0], isize(ii)).fg.bUsed) == 0; ii-- {
				sqlite3_expr_delete(db, c2v_at(&pel_ist.a[0], isize(ii)).pExpr)
				sqlite3_db_free(db, voidptr(c2v_at(&pel_ist.a[0], isize(ii)).zEName))
				pel_ist.nExpr--
			}
			for ii = 0; ii < pel_ist.nExpr; ii++ {
				if int(c2v_at(&pel_ist.a[0], isize(ii)).fg.bUsed) == 0 {
					mut __c2v_lhs_tmp_149 := c2v_at(&pel_ist.a[0], isize(ii))
					__c2v_lhs_tmp_149.pExpr.op = U8(122)
				}
			}
		}
	}
	i_end = sqlite3_vdbe_make_label(p_parse)
	if (p.selFlags & u32(16384)) == u32(0) {
		p.nSelectRow = LogEst(320)
	}
	if p.pLimit {
		compute_limit_registers(p_parse, p, i_end)
	}
	if p.iLimit == 0 && s_sort.addrSortIndex >= 0 {
		sqlite3_vdbe_change_opcode(v, s_sort.addrSortIndex, U8(121))
		s_sort.sortFlags |= 1
	}
	if p.selFlags & u32(1) {
		mut __c2v_postfix_value_31 := p_parse.nTab
		p_parse.nTab++
		s_distinct.tabTnct = __c2v_postfix_value_31
		s_distinct.addrTnct = sqlite3_vdbe_add_op4(v, 120, s_distinct.tabTnct, 0, 0, &i8(voidptr(sqlite3_key_info_from_expr_list(p_parse, p.pEList, 0, 0))), (-9))
		sqlite3_vdbe_change_p5(v, U16(8))
		s_distinct.eTnctType = U8(3)
	} else {
		s_distinct.eTnctType = U8(0)
	}
	if !is_agg && usize(p_group_by) == usize(0) {
		wctrl_flags := U16(u32((if int(s_distinct.isTnct) { 256 } else { 0 })) | (p.selFlags & u32(16384)))
		p_win := p.pWin
		if p_win {
			sqlite3_window_code_init(p_parse, p)
		}
		pwi_nfo = sqlite3_where_begin(p_parse, p_tab_list, p_where, s_sort.pOrderBy, p.pEList, p, wctrl_flags, int(p.nSelectRow))
		if usize(pwi_nfo) == usize(0) {
			unsafe { goto select_end
			 }
		}
		if int(sqlite3_where_output_row_count(pwi_nfo)) < int(p.nSelectRow) {
			p.nSelectRow = sqlite3_where_output_row_count(pwi_nfo)
			if int(p_dest.eDest) <= 4 && int(p_dest.eDest) >= 3 {
				p.nSelectRow -= 30
			}
		}
		if int(s_distinct.isTnct) && sqlite3_where_is_distinct(pwi_nfo) {
			s_distinct.eTnctType = U8(sqlite3_where_is_distinct(pwi_nfo))
		}
		if s_sort.pOrderBy {
			s_sort.nOBSat = sqlite3_where_is_ordered(pwi_nfo)
			s_sort.labelOBLopt = sqlite3_where_order_by_limit_opt_label(pwi_nfo)
			if s_sort.nOBSat == s_sort.pOrderBy.nExpr {
				s_sort.pOrderBy = 0
			}
		}
		if s_sort.addrSortIndex >= 0 && usize(s_sort.pOrderBy) == usize(0) {
			sqlite3_vdbe_change_to_noop(v, s_sort.addrSortIndex)
		}
		if p_win {
			addr_gosub := sqlite3_vdbe_make_label(p_parse)
			i_cont := sqlite3_vdbe_make_label(p_parse)
			i_break := sqlite3_vdbe_make_label(p_parse)
			reg_gosub := c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			sqlite3_window_code_step(p_parse, p, pwi_nfo, reg_gosub, addr_gosub)
			sqlite3_vdbe_add_op2(v, 9, 0, i_break)
			sqlite3_vdbe_resolve_label(v, addr_gosub)
			s_sort.labelOBLopt = 0
			select_inner_loop(p_parse, p, -1, &s_sort, &s_distinct, p_dest, i_cont, i_break)
			sqlite3_vdbe_resolve_label(v, i_cont)
			sqlite3_vdbe_add_op1(v, 69, reg_gosub)
			sqlite3_vdbe_resolve_label(v, i_break)
		} else {
			select_inner_loop(p_parse, p, -1, &s_sort, &s_distinct, p_dest, sqlite3_where_continue_label(pwi_nfo), sqlite3_where_break_label(pwi_nfo))
			sqlite3_where_end(pwi_nfo)
		}
	} else {
		snc := NameContext{}
		iam_em := 0
		ibm_em := 0
		i_use_flag := 0
		i_abort_flag := 0
		group_by_sort := 0
		addr_end := 0
		sort_pt_ab := 0
		sort_out := 0
		order_by_grp := 0
		if p_group_by {
			k := 0
			p_item := &ExprList_item(0)
			k = p.pEList.nExpr
			for p_item = unsafe { &p.pEList.a[0] }; k > 0; k-- {
				p_item.u.x.iAlias = U16(0)
				c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
			}
			k = p_group_by.nExpr
			for p_item = unsafe { &p_group_by.a[0] }; k > 0; k-- {
				p_item.u.x.iAlias = U16(0)
				c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
			}
			if int(p.nSelectRow) > 66 {
				p.nSelectRow = LogEst(66)
			}
			if sqlite3_copy_sort_order(p_group_by, s_sort.pOrderBy) && sqlite3_expr_list_compare(p_group_by, s_sort.pOrderBy, -1) == 0 {
				order_by_grp = 1
			}
		} else {
			p.nSelectRow = LogEst(0)
		}
		addr_end = sqlite3_vdbe_make_label(p_parse)
		p_agg_info = sqlite3_db_malloc_zero(db, U64(sizeof(AggInfo)))
		if p_agg_info {
			sqlite3_parser_add_cleanup(p_parse, agginfo_free, voidptr(p_agg_info))
		}
		if db.mallocFailed {
			unsafe { goto select_end
			 }
		}
		p_agg_info.selId = p.selId
		C.memset(voidptr(&snc), 0, sizeof(snc))
		snc.pParse = p_parse
		snc.pSrcList = p_tab_list
		snc.uNC.pAggInfo = p_agg_info
		p_agg_info.nSortingColumn = u32(if p_group_by { p_group_by.nExpr } else { 0 })
		p_agg_info.pGroupBy = p_group_by
		sqlite3_expr_analyze_agg_list(&snc, pel_ist)
		sqlite3_expr_analyze_agg_list(&snc, s_sort.pOrderBy)
		if p_having {
			if p_group_by {
				having_to_where(p_parse, p)
				p_where = p.pWhere
			}
			sqlite3_expr_analyze_aggregates(&snc, p_having)
		}
		p_agg_info.nAccumulator = p_agg_info.nColumn
		if usize(p.pGroupBy) == usize(0) && usize(p.pHaving) == usize(0) && p_agg_info.nFunc == 1 {
			min_max_flag = min_max_query(db, p_agg_info.aFunc[0].pFExpr, &&ExprList(&&ExprList(c2v_address_of(&p_min_max_order_by))))
		} else {
			min_max_flag = U8(0)
		}
		analyze_agg_func_args(p_agg_info, &snc)
		if db.mallocFailed {
			unsafe { goto select_end
			 }
		}
		if p_group_by {
			p_key_info := &KeyInfo(0)
			addr1 := 0
			addr_output_row := 0
			reg_output_row := 0
			addr_set_abort := 0
			addr_top_of_loop := 0
			addr_sorting_idx := 0
			addr_reset := 0
			reg_reset := 0
			p_distinct := unsafe { &ExprList(nil) }
			dist_flag := U16(0)
			e_dist := 0
			mut __c2v_condition_93 := false
			mut __c2v_condition_94 := false
			__c2v_condition_94 = p_agg_info.nFunc == 1
			if __c2v_condition_94 {
				__c2v_condition_94 = p_agg_info.aFunc[0].iDistinct >= 0
			}
			if __c2v_condition_94 {
				__c2v_condition_94 = (usize(p_agg_info.aFunc[0].pFExpr) != usize(0))
			}
			if __c2v_condition_94 {
				__c2v_condition_94 = ((p_agg_info.aFunc[0].pFExpr.flags & u32(4096)) == u32(0))
			}
			if __c2v_condition_94 {
				__c2v_condition_94 = usize(p_agg_info.aFunc[0].pFExpr.x.pList) != usize(0)
			}
			__c2v_condition_93 = __c2v_condition_94
			if __c2v_condition_93 {
				p_expr := c2v_at(&p_agg_info.aFunc[0].pFExpr.x.pList.a[0], isize(0)).pExpr
				p_expr = sqlite3_expr_dup(db, p_expr, 0)
				p_distinct = sqlite3_expr_list_dup(db, p_group_by, 0)
				p_distinct = sqlite3_expr_list_append(p_parse, p_distinct, p_expr)
				dist_flag = U16(if p_distinct { (256 | 1024) } else { 0 })
			}
			mut __c2v_postfix_value_32 := p_parse.nTab
			p_parse.nTab++
			p_agg_info.sortingIdx = __c2v_postfix_value_32
			p_key_info = sqlite3_key_info_from_expr_list(p_parse, p_group_by, 0, p_agg_info.nColumn)
			addr_sorting_idx = sqlite3_vdbe_add_op4(v, 121, p_agg_info.sortingIdx, int(p_agg_info.nSortingColumn), 0, &i8(voidptr(p_key_info)), (-9))
			i_use_flag = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			i_abort_flag = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			reg_output_row = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			addr_output_row = sqlite3_vdbe_make_label(p_parse)
			reg_reset = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			addr_reset = sqlite3_vdbe_make_label(p_parse)
			iam_em = p_parse.nMem + 1
			p_parse.nMem += p_group_by.nExpr
			ibm_em = p_parse.nMem + 1
			p_parse.nMem += p_group_by.nExpr
			sqlite3_vdbe_add_op2(v, 73, 0, i_abort_flag)
			sqlite3_vdbe_add_op3(v, 77, 0, iam_em, iam_em + p_group_by.nExpr - 1)
			sqlite3_expr_null_register_range(p_parse, iam_em, p_group_by.nExpr)
			sqlite3_vdbe_add_op2(v, 10, reg_reset, addr_reset)
			pwi_nfo = sqlite3_where_begin(p_parse, p_tab_list, p_where, p_group_by, p_distinct, p, U16((if int(s_distinct.isTnct) == 2 {
				128
			} else {
				64
			}) | (if order_by_grp { 512 } else { 0 }) | int(dist_flag)), 0)
			if usize(pwi_nfo) == usize(0) {
				sqlite3_expr_list_delete(db, p_distinct)
				unsafe { goto select_end
				 }
			}
			if p_parse.pIdxEpr {
				optimize_aggregate_use_of_indexed_expr(p_parse, p, p_agg_info, &snc)
			}
			assign_aggregate_registers(p_parse, p_agg_info)
			e_dist = sqlite3_where_is_distinct(pwi_nfo)
			if sqlite3_where_is_ordered(pwi_nfo) == p_group_by.nExpr {
				group_by_sort = 0
			} else {
				reg_base := 0
				reg_record := 0
				n_col := 0
				n_group_by := 0
				sqlite3_vdbe_explain(p_parse, U8(0), c'USE TEMP B-TREE FOR %s', voidptr(if (int(s_distinct.isTnct) && (p.selFlags & u32(1)) == u32(0)) {
					c'DISTINCT'
				} else {
					c'GROUP BY'
				}))
				group_by_sort = 1
				n_group_by = p_group_by.nExpr
				n_col = n_group_by
				j = n_group_by
				for i = 0; i < p_agg_info.nColumn; i++ {
					if p_agg_info.aCol[i].iSorterColumn >= j {
						n_col++
						j++
					}
				}
				reg_base = sqlite3_get_temp_range(p_parse, n_col)
				sqlite3_expr_code_expr_list(p_parse, p_group_by, reg_base, 0, U8(0))
				j = n_group_by
				p_agg_info.directMode = U8(1)
				for i = 0; i < p_agg_info.nColumn; i++ {
					p_col := unsafe { p_agg_info.aCol + i }
					if p_col.iSorterColumn >= j {
						sqlite3_expr_code(p_parse, p_col.pCExpr, j + reg_base)
						j++
					}
				}
				p_agg_info.directMode = U8(0)
				reg_record = sqlite3_get_temp_reg(p_parse)
				sqlite3_vdbe_add_op3(v, 99, reg_base, n_col, reg_record)
				sqlite3_vdbe_add_op2(v, 141, p_agg_info.sortingIdx, reg_record)
				sqlite3_release_temp_reg(p_parse, reg_record)
				sqlite3_release_temp_range(p_parse, reg_base, n_col)
				sqlite3_where_end(pwi_nfo)
				mut __c2v_postfix_value_33 := p_parse.nTab
				p_parse.nTab++
				sort_pt_ab = __c2v_postfix_value_33
				p_agg_info.sortingIdxPTab = sort_pt_ab
				sort_out = sqlite3_get_temp_reg(p_parse)
				sqlite3_vdbe_add_op3(v, 123, sort_pt_ab, sort_out, n_col)
				sqlite3_vdbe_add_op2(v, 34, p_agg_info.sortingIdx, addr_end)
				p_agg_info.useSortingIdx = U8(1)
			}
			if p_parse.pIdxEpr {
				aggregate_convert_indexed_expr_ref_to_column(p_agg_info)
			}
			if order_by_grp && ((db.dbOptFlags & u32(4)) == u32(0)) && (group_by_sort || sqlite3_where_is_sorted(pwi_nfo)) {
				s_sort.pOrderBy = 0
				sqlite3_vdbe_change_to_noop(v, s_sort.addrSortIndex)
			}
			addr_top_of_loop = sqlite3_vdbe_current_addr(v)
			if group_by_sort {
				sqlite3_vdbe_add_op3(v, 135, p_agg_info.sortingIdx, sort_out, sort_pt_ab)
			}
			for j = 0; j < p_group_by.nExpr; j++ {
				i_order_by_col := int(c2v_at(&p_group_by.a[0], isize(j)).u.x.iOrderByCol)
				if group_by_sort {
					sqlite3_vdbe_add_op3(v, 96, sort_pt_ab, j, ibm_em + j)
				} else {
					p_agg_info.directMode = U8(1)
					sqlite3_expr_code(p_parse, c2v_at(&p_group_by.a[0], isize(j)).pExpr, ibm_em + j)
				}
				if i_order_by_col {
					px := c2v_at(&p.pEList.a[0], isize(i_order_by_col - 1)).pExpr
					p_base := sqlite3_expr_skip_collate_and_likely(px)
					for (usize(p_base) != usize(0)) && int(p_base.op) == 179 {
						px = p_base.pLeft
						p_base = sqlite3_expr_skip_collate_and_likely(px)
					}
					if (usize(p_base) != usize(0)) && int(p_base.op) != 170 && int(p_base.op) != 176 {
						sqlite3_expr_to_register(px, iam_em + j)
					}
				}
			}
			sqlite3_vdbe_add_op4(v, 92, iam_em, ibm_em, p_group_by.nExpr, &i8(voidptr(sqlite3_key_info_ref(p_key_info))), (-9))
			addr1 = sqlite3_vdbe_current_addr(v)
			sqlite3_vdbe_add_op3(v, 14, addr1 + 1, 0, addr1 + 1)
			sqlite3_vdbe_add_op2(v, 10, reg_output_row, addr_output_row)
			sqlite3_expr_code_move(p_parse, ibm_em, iam_em, p_group_by.nExpr)
			sqlite3_vdbe_add_op2(v, 61, i_abort_flag, addr_end)
			sqlite3_vdbe_add_op2(v, 10, reg_reset, addr_reset)
			sqlite3_vdbe_jump_here(v, addr1)
			update_accumulator(p_parse, i_use_flag, p_agg_info, e_dist)
			sqlite3_vdbe_add_op2(v, 73, 1, i_use_flag)
			if group_by_sort {
				sqlite3_vdbe_add_op2(v, 38, p_agg_info.sortingIdx, addr_top_of_loop)
			} else {
				sqlite3_where_end(pwi_nfo)
				sqlite3_vdbe_change_to_noop(v, addr_sorting_idx)
			}
			sqlite3_expr_list_delete(db, p_distinct)
			sqlite3_vdbe_add_op2(v, 10, reg_output_row, addr_output_row)
			sqlite3_vdbe_goto(v, addr_end)
			addr_set_abort = sqlite3_vdbe_current_addr(v)
			sqlite3_vdbe_add_op2(v, 73, 1, i_abort_flag)
			sqlite3_vdbe_add_op1(v, 69, reg_output_row)
			sqlite3_vdbe_resolve_label(v, addr_output_row)
			addr_output_row = sqlite3_vdbe_current_addr(v)
			sqlite3_vdbe_add_op2(v, 61, i_use_flag, addr_output_row + 2)
			sqlite3_vdbe_add_op1(v, 69, reg_output_row)
			finalize_agg_functions(p_parse, p_agg_info)
			sqlite3_expr_if_false(p_parse, p_having, addr_output_row + 1, 16)
			select_inner_loop(p_parse, p, -1, &s_sort, &s_distinct, p_dest, addr_output_row + 1, addr_set_abort)
			sqlite3_vdbe_add_op1(v, 69, reg_output_row)
			sqlite3_vdbe_resolve_label(v, addr_reset)
			reset_accumulator(p_parse, p_agg_info)
			sqlite3_vdbe_add_op2(v, 73, 0, i_use_flag)
			sqlite3_vdbe_add_op1(v, 69, reg_reset)
			if int(dist_flag) != 0 && e_dist != 0 {
				pf := unsafe { p_agg_info.aFunc + 0 }
				fix_distinct_open_eph(p_parse, e_dist, pf.iDistinct, pf.iDistAddr)
			}
		} else {
			p_tab := &Table(0)
			p_tab = is_simple_count(p, p_agg_info)
			if usize(p_tab) != usize(0) {
				i_db := sqlite3_schema_to_index(p_parse.db, p_tab.pSchema)
				i_csr := p_parse.nTab++
				p_idx := &Index(0)
				p_key_info := unsafe { &KeyInfo(nil) }
				p_best := unsafe { &Index(nil) }
				i_root := p_tab.tnum
				sqlite3_code_verify_schema(p_parse, i_db)
				sqlite3_table_lock(p_parse, i_db, p_tab.tnum, U8(0), p_tab.zName)
				if !((p_tab.tabFlags & u32(128)) == u32(0)) {
					p_best = sqlite3_primary_key_index(p_tab)
				}
				if !c2v_at(&p.pSrc.a[0], isize(0)).fg.notIndexed {
					for p_idx = p_tab.pIndex; p_idx; p_idx = p_idx.pNext {
						if int(p_idx.bUnordered) == 0 && int(p_idx.szIdxRow) < int(p_tab.szTabRow) && usize(p_idx.pPartIdxWhere) == usize(0) && (isnil(p_best) || int(p_idx.szIdxRow) < int(p_best.szIdxRow)) {
							p_best = p_idx
						}
					}
				}
				if p_best {
					i_root = p_best.tnum
					p_key_info = sqlite3_key_info_of_index(p_parse, p_best)
				}
				sqlite3_vdbe_add_op4_int(v, 114, i_csr, int(i_root), i_db, 1)
				if p_key_info {
					sqlite3_vdbe_change_p4(v, -1, &i8(voidptr(p_key_info)), (-9))
				}
				assign_aggregate_registers(p_parse, p_agg_info)
				sqlite3_vdbe_add_op2(v, 100, i_csr, (p_agg_info.iFirstReg + p_agg_info.nColumn + 0))
				sqlite3_vdbe_add_op1(v, 124, i_csr)
				explain_simple_count(p_parse, p_tab, p_best)
			} else {
				reg_acc := 0
				p_distinct := unsafe { &ExprList(nil) }
				dist_flag := U16(0)
				e_dist := 0
				if p_agg_info.nAccumulator {
					for i = 0; i < p_agg_info.nFunc; i++ {
						if ((p_agg_info.aFunc[i].pFExpr.flags & u32(16777216)) != u32(0)) {
							continue
						}
						if p_agg_info.aFunc[i].pFunc.funcFlags & u32(32) {
							break
						}
					}
					if i == p_agg_info.nFunc {
						reg_acc = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
						sqlite3_vdbe_add_op2(v, 73, 0, reg_acc)
					}
				} else if p_agg_info.nFunc == 1 && p_agg_info.aFunc[0].iDistinct >= 0 {
					p_distinct = p_agg_info.aFunc[0].pFExpr.x.pList
					dist_flag = U16(if p_distinct { (256 | 1024) } else { 0 })
				}
				assign_aggregate_registers(p_parse, p_agg_info)
				reset_accumulator(p_parse, p_agg_info)
				pwi_nfo = sqlite3_where_begin(p_parse, p_tab_list, p_where, p_min_max_order_by, p_distinct, p, U16(int(min_max_flag) | int(dist_flag)), 0)
				if usize(pwi_nfo) == usize(0) {
					unsafe { goto select_end
					 }
				}
				e_dist = sqlite3_where_is_distinct(pwi_nfo)
				update_accumulator(p_parse, reg_acc, p_agg_info, e_dist)
				if e_dist != 0 {
					pf := p_agg_info.aFunc
					if pf {
						fix_distinct_open_eph(p_parse, e_dist, pf.iDistinct, pf.iDistAddr)
					}
				}
				if reg_acc {
					sqlite3_vdbe_add_op2(v, 73, 1, reg_acc)
				}
				if min_max_flag {
					sqlite3_where_min_max_opt_early_out(v, pwi_nfo)
				}
				sqlite3_where_end(pwi_nfo)
				finalize_agg_functions(p_parse, p_agg_info)
			}
			s_sort.pOrderBy = 0
			sqlite3_expr_if_false(p_parse, p_having, addr_end, 16)
			select_inner_loop(p_parse, p, -1, unsafe { nil }, unsafe { nil }, p_dest, addr_end, addr_end)
		}
		sqlite3_vdbe_resolve_label(v, addr_end)
	}
	if int(s_distinct.eTnctType) == 3 {
		explain_temp_table(p_parse, c'DISTINCT')
	}
	if s_sort.pOrderBy {
		generate_sort_tail(p_parse, p, &s_sort, pel_ist.nExpr, p_dest)
	}
	sqlite3_vdbe_resolve_label(v, i_end)
	rc = (p_parse.nErr > 0)
	select_end:
	sqlite3_expr_list_delete(db, p_min_max_order_by)
	sqlite3_vdbe_explain_pop(p_parse)
	return rc
}
