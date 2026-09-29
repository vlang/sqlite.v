@[translated]
module main

@[c:'upsertDelete']
fn upsert_delete(db &Sqlite3, p &Upsert) {
	for {
		p_next := p.pNextUpsert
		sqlite3_expr_list_delete(db, p.pUpsertTarget)
		sqlite3_expr_delete(db, p.pUpsertTargetWhere)
		sqlite3_expr_list_delete(db, p.pUpsertSet)
		sqlite3_expr_delete(db, p.pUpsertWhere)
		sqlite3_db_free(db, voidptr(p.pToFree))
		sqlite3_db_free(db, voidptr(p))
		p = p_next
		if !p {
			break
		}
	}
}

@[c:'sqlite3UpsertDelete']
fn sqlite3_upsert_delete(db &Sqlite3, p &Upsert) {
	if p {
		upsert_delete(db, p)
	}
}

@[c:'sqlite3UpsertDup']
fn sqlite3_upsert_dup(db &Sqlite3, p &Upsert) &Upsert {
	if usize(p) == usize(0) {
		return unsafe { nil }
	}
	return sqlite3_upsert_new(db, sqlite3_expr_list_dup(db, p.pUpsertTarget, 0), sqlite3_expr_dup(db, p.pUpsertTargetWhere, 0), sqlite3_expr_list_dup(db, p.pUpsertSet, 0), sqlite3_expr_dup(db, p.pUpsertWhere, 0), sqlite3_upsert_dup(db, p.pNextUpsert))
}

@[c:'sqlite3UpsertNew']
fn sqlite3_upsert_new(db &Sqlite3, p_target &ExprList, p_target_where &Expr, p_set &ExprList, p_where &Expr, p_next &Upsert) &Upsert {
	p_new := &Upsert(0)
	p_new = sqlite3_db_malloc_zero(db, U64(sizeof(Upsert)))
	if usize(p_new) == usize(0) {
		sqlite3_expr_list_delete(db, p_target)
		sqlite3_expr_delete(db, p_target_where)
		sqlite3_expr_list_delete(db, p_set)
		sqlite3_expr_delete(db, p_where)
		sqlite3_upsert_delete(db, p_next)
		return unsafe { nil }
	} else {
		p_new.pUpsertTarget = p_target
		p_new.pUpsertTargetWhere = p_target_where
		p_new.pUpsertSet = p_set
		p_new.pUpsertWhere = p_where
		p_new.isDoUpdate = U8(usize(p_set) != usize(0))
		p_new.pNextUpsert = p_next
	}
	return p_new
}

@[c:'sqlite3UpsertAnalyzeTarget']
fn sqlite3_upsert_analyze_target(p_parse &Parse, p_tab_list &SrcList, p_upsert &Upsert, p_all &Upsert) int {
	p_tab := &Table(0)
	rc := 0
	i_cursor := 0
	p_idx := &Index(0)
	p_target := &ExprList(0)
	p_term := &Expr(0)
	snc := NameContext{}
	s_col := [2]Expr{}
	n_clause := 0
	C.memset(voidptr(&snc), 0, sizeof(snc))
	snc.pParse = p_parse
	snc.pSrcList = p_tab_list
	for ; !isnil(p_upsert) && !isnil(p_upsert.pUpsertTarget);  {
		rc = sqlite3_resolve_expr_list_names(&snc, p_upsert.pUpsertTarget)
		if rc {
			return rc
		}
		rc = sqlite3_resolve_expr_names(&snc, p_upsert.pUpsertTargetWhere)
		if rc {
			return rc
		}
		p_tab = c2v_at(&p_tab_list.a[0], isize(0)).pSTab
		p_target = p_upsert.pUpsertTarget
		i_cursor = c2v_at(&p_tab_list.a[0], isize(0)).iCursor
		if ((p_tab.tabFlags & u32(128)) == u32(0)) && p_target.nExpr == 1 && int(c2v_assign[&Expr](unsafe { &p_term }, c2v_at(&p_target.a[0], isize(0)).pExpr).op) == 168 && int(p_term.iColumn) == (-1) {
			unsafe { goto c2v_for_next_173
			 }
		}
		C.memset(voidptr(unsafe { &s_col[0] }), 0, sizeof([2]Expr))
		s_col[0].op = U8(114)
		s_col[0].pLeft = unsafe { &s_col[0] + 1 }
		s_col[1].op = U8(168)
		s_col[1].iTable = c2v_at(&p_tab_list.a[0], isize(0)).iCursor
		for p_idx = p_tab.pIndex; p_idx; p_idx = p_idx.pNext {
			ii := 0
			jj := 0
			nn := 0

			if !(int(p_idx.onError) != 0) {
				continue
			}
			if p_target.nExpr != int(p_idx.nKeyCol) {
				continue
			}
			if p_idx.pPartIdxWhere {
				if usize(p_upsert.pUpsertTargetWhere) == usize(0) {
					continue
				}
				if sqlite3_expr_compare(p_parse, p_upsert.pUpsertTargetWhere, p_idx.pPartIdxWhere, i_cursor) != 0 {
					continue
				}
			}
			nn = int(p_idx.nKeyCol)
			for ii = 0; ii < nn; ii++ {
				p_expr := &Expr(0)
				s_col[0].u.zToken = &i8(p_idx.azColl[ii])
				if int(p_idx.aiColumn[ii]) == (-2) {
					p_expr = c2v_at(&p_idx.aColExpr.a[0], isize(ii)).pExpr
					if int(p_expr.op) != 114 {
						s_col[0].pLeft = p_expr
						p_expr = unsafe { &s_col[0] + 0 }
					}
				} else {
					s_col[0].pLeft = unsafe { &s_col[0] + 1 }
					s_col[1].iColumn = p_idx.aiColumn[ii]
					p_expr = unsafe { &s_col[0] + 0 }
				}
				for jj = 0; jj < nn; jj++ {
					if sqlite3_expr_compare(unsafe { nil }, c2v_at(&p_target.a[0], isize(jj)).pExpr, p_expr, i_cursor) < 2 {
						break
					}
				}
				if jj >= nn {
					break
				}
			}
			if ii < nn {
				continue
			}
			p_upsert.pUpsertIdx = p_idx
			if usize(sqlite3_upsert_of_index(p_all, p_idx)) != usize(p_upsert) {
				p_upsert.isDup = U8(1)
			}
			break
		}
		if usize(p_upsert.pUpsertIdx) == usize(0) {
			z_which := [16]i8{}
			if n_clause == 0 && usize(p_upsert.pNextUpsert) == usize(0) {
				z_which[0] = i8(0)
			} else {
				sqlite3_snprintf(int(sizeof([16]i8)), unsafe { &i8(&z_which[0]) }, c'%r ', n_clause + 1)
			}
			sqlite3_error_msg(p_parse, c'%sON CONFLICT clause does not match any PRIMARY KEY or UNIQUE constraint', voidptr(&z_which[0]))
			return 1
		}
		c2v_for_next_173:
		p_upsert = p_upsert.pNextUpsert
		n_clause++
	}
	return 0
}

@[c:'sqlite3UpsertNextIsIPK']
fn sqlite3_upsert_next_is_ipk(p_upsert &Upsert) int {
	p_next := &Upsert(0)
	if (usize(p_upsert) == usize(0)) {
		return 0
	}
	p_next = p_upsert.pNextUpsert
	for {
		if usize(p_next) == usize(0) {
			return 1
		}
		if usize(p_next.pUpsertTarget) == usize(0) {
			return 1
		}
		if usize(p_next.pUpsertIdx) == usize(0) {
			return 1
		}
		if !p_next.isDup {
			return 0
		}
		p_next = p_next.pNextUpsert
	}
	return 0
}

@[c:'sqlite3UpsertOfIndex']
fn sqlite3_upsert_of_index(p_upsert &Upsert, p_idx &Index) &Upsert {
	for !isnil(p_upsert) && usize(p_upsert.pUpsertTarget) != usize(0) && usize(p_upsert.pUpsertIdx) != usize(p_idx) {
		p_upsert = p_upsert.pNextUpsert
	}
	return p_upsert
}

@[c:'sqlite3UpsertDoUpdate']
fn sqlite3_upsert_do_update(p_parse &Parse, p_upsert &Upsert, p_tab &Table, p_idx &Index, i_cur int) {
	v := p_parse.pVdbe
	db := p_parse.db
	p_src := &SrcList(0)
	i_data_cur := 0
	i := 0
	p_top := p_upsert
	i_data_cur = p_upsert.iDataCur
	p_upsert = sqlite3_upsert_of_index(p_top, p_idx)
	if !isnil(p_idx) && i_cur != i_data_cur {
		if ((p_tab.tabFlags & u32(128)) == u32(0)) {
			reg_rowid := sqlite3_get_temp_reg(p_parse)
			sqlite3_vdbe_add_op2(v, 144, i_cur, reg_rowid)
			sqlite3_vdbe_add_op3(v, 30, i_data_cur, 0, reg_rowid)
			sqlite3_release_temp_reg(p_parse, reg_rowid)
		} else {
			p_pk := sqlite3_primary_key_index(p_tab)
			n_pk := int(p_pk.nKeyCol)
			i_pk := p_parse.nMem + 1
			p_parse.nMem += n_pk
			for i = 0; i < n_pk; i++ {
				k := 0
				k = sqlite3_table_column_to_index(p_idx, int(p_pk.aiColumn[i]))
				sqlite3_vdbe_add_op3(v, 96, i_cur, k, i_pk + i)
			}
			i = sqlite3_vdbe_add_op4_int(v, 29, i_data_cur, 0, i_pk, n_pk)
			sqlite3_vdbe_add_op4(v, 72, 11, 2, 0, c'corrupt database', (-1))
			sqlite3_may_abort(p_parse)
			sqlite3_vdbe_jump_here(v, i)
		}
	}
	p_src = sqlite3_src_list_dup(db, p_top.pUpsertSrc, 0)
	for i = 0; i < int(p_tab.nCol); i++ {
		if int(p_tab.aCol[i].affinity) == 69 {
			i_storage := p_top.regData + int(sqlite3_table_column_to_storage(p_tab, I16(i)))
			sqlite3_vdbe_add_op1(v, 89, i_storage)
		}
	}
	sqlite3_update(p_parse, p_src, sqlite3_expr_list_dup(db, p_upsert.pUpsertSet, 0), sqlite3_expr_dup(db, p_upsert.pUpsertWhere, 0), 2, unsafe { nil }, unsafe { nil }, p_upsert)
}
