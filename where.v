@[translated]
module main

struct HiddenIndexInfo {
	pWC       &WhereClause
	pParse    &Parse
	eDistinct int
	mIn       u32
	mHandleIn u32
	aRhs      [1]&Sqlite3_value
}

@[c:'sqlite3WhereOutputRowCount']
fn sqlite3_where_output_row_count(pwi_nfo &WhereInfo) LogEst {
	return pwi_nfo.nRowOut
}

@[c:'sqlite3WhereIsDistinct']
fn sqlite3_where_is_distinct(pwi_nfo &WhereInfo) int {
	return int(pwi_nfo.eDistinct)
}

@[c:'sqlite3WhereIsOrdered']
fn sqlite3_where_is_ordered(pwi_nfo &WhereInfo) int {
	return if int(pwi_nfo.nOBSat) < 0 { 0 } else { int(pwi_nfo.nOBSat) }
}

@[c:'sqlite3WhereOrderByLimitOptLabel']
fn sqlite3_where_order_by_limit_opt_label(pwi_nfo &WhereInfo) int {
	p_inner := &WhereLevel(0)
	if !pwi_nfo.bOrderedInnerLoop {
		return pwi_nfo.iContinue
	}
	p_inner = unsafe { &pwi_nfo.a[0] + (int(pwi_nfo.nLevel) - 1) }
	return if p_inner.pRJ { pwi_nfo.iContinue } else { p_inner.addrNxt }
}

@[c:'sqlite3WhereMinMaxOptEarlyOut']
fn sqlite3_where_min_max_opt_early_out(v &Vdbe, pwi_nfo &WhereInfo) {
	p_inner := &WhereLevel(0)
	i := 0
	if !pwi_nfo.bOrderedInnerLoop {
		return
	}
	if int(pwi_nfo.nOBSat) == 0 {
		return
	}
	for i = int(pwi_nfo.nLevel) - 1; i >= 0; i-- {
		p_inner = unsafe { &pwi_nfo.a[0] + i }
		if (p_inner.pWLoop.wsFlags & u32(4)) != u32(0) {
			sqlite3_vdbe_goto(v, p_inner.addrNxt)
			return
		}
	}
	sqlite3_vdbe_goto(v, pwi_nfo.iBreak)
}

@[c:'sqlite3WhereContinueLabel']
fn sqlite3_where_continue_label(pwi_nfo &WhereInfo) int {
	return pwi_nfo.iContinue
}

@[c:'sqlite3WhereBreakLabel']
fn sqlite3_where_break_label(pwi_nfo &WhereInfo) int {
	return pwi_nfo.iBreak
}

@[c:'sqlite3WhereOkOnePass']
fn sqlite3_where_ok_one_pass(pwi_nfo &WhereInfo, ai_cur &int) int {
	C.memcpy(voidptr(ai_cur), pwi_nfo.aiCurOnePass, sizeof(int) * u64(2))
	return int(pwi_nfo.eOnePass)
}

@[c:'sqlite3WhereUsesDeferredSeek']
fn sqlite3_where_uses_deferred_seek(pwi_nfo &WhereInfo) int {
	return int(pwi_nfo.bDeferredSeek)
}

@[c:'whereOrMove']
fn where_or_move(p_dest &WhereOrSet, p_src &WhereOrSet) {
	p_dest.n = p_src.n
	C.memcpy(p_dest.a, p_src.a, u64(p_dest.n) * sizeof(WhereOrCost))
}

@[c:'whereOrInsert']
fn where_or_insert(p_set &WhereOrSet, prereq Bitmask, r_run LogEst, n_out LogEst) int {
	i := U16(0)
	p := &WhereOrCost(0)
	i = p_set.n
	for p = unsafe { &p_set.a[0] }; int(i) > 0; i-- {
		if int(r_run) <= int(p.rRun) && (prereq & p.prereq) == prereq {
			unsafe { goto whereOrInsert_done
			 }
		}
		if int(p.rRun) <= int(r_run) && (p.prereq & prereq) == p.prereq {
			return 0
		}
		c2v_pointer_postfix(voidptr(&p), p, isize(1))
	}
	if int(p_set.n) < 3 {
		p = unsafe { &p_set.a[0] + p_set.n++ }
		p.nOut = n_out
	} else {
		p = unsafe { &p_set.a[0] }
		for i = U16(1); int(i) < int(p_set.n); i++ {
			if int(p.rRun) > int(p_set.a[i].rRun) {
				p = unsafe { &p_set.a[0] } + int(i)
			}
		}
		if int(p.rRun) <= int(r_run) {
			return 0
		}
	}
	whereOrInsert_done:
	p.prereq = prereq
	p.rRun = r_run
	if int(p.nOut) > int(n_out) {
		p.nOut = n_out
	}
	return 1
}

@[c:'sqlite3WhereGetMask']
fn sqlite3_where_get_mask(p_mask_set &WhereMaskSet, i_cursor int) Bitmask {
	i := 0
	if p_mask_set.ix[0] == i_cursor {
		return Bitmask(1)
	}
	for i = 1; i < p_mask_set.n; i++ {
		if p_mask_set.ix[i] == i_cursor {
			return (Bitmask(1)) << i
		}
	}
	return Bitmask(0)
}

@[c:'sqlite3WhereMalloc']
fn sqlite3_where_malloc(pwi_nfo &WhereInfo, n_byte U64) voidptr {
	p_block := &WhereMemBlock(0)
	p_block = sqlite3_db_malloc_raw_nn(pwi_nfo.pParse.db, n_byte + U64(sizeof(WhereMemBlock)))
	if p_block {
		p_block.pNext = pwi_nfo.pMemToFree
		p_block.sz = n_byte
		pwi_nfo.pMemToFree = p_block
		c2v_pointer_postfix(voidptr(&p_block), p_block, isize(1))
	}
	return voidptr(p_block)
}

@[c:'sqlite3WhereRealloc']
fn sqlite3_where_realloc(pwi_nfo &WhereInfo, p_old voidptr, n_byte U64) voidptr {
	p_new := sqlite3_where_malloc(pwi_nfo, n_byte)
	if !isnil(p_new) && !isnil(p_old) {
		p_old_blk := &WhereMemBlock(p_old)
		c2v_pointer_postfix(voidptr(&p_old_blk), p_old_blk, isize(-1))
		C.memcpy(voidptr(p_new), voidptr(p_old), u64(p_old_blk.sz))
	}
	return p_new
}

@[c:'createMask']
fn create_mask(p_mask_set &WhereMaskSet, i_cursor int) {
	p_mask_set.ix[p_mask_set.n++] = i_cursor
}

@[c:'whereRightSubexprIsColumn']
fn where_right_subexpr_is_column(p &Expr) &Expr {
	p = sqlite3_expr_skip_collate_and_likely(p.pRight)
	if (usize(p) != usize(0)) && int(p.op) == 168 && !((p.flags & u32(32)) != u32(0)) {
		return p
	}
	return unsafe { nil }
}

@[c:'indexInAffinityOk']
fn index_in_affinity_ok(p_parse &Parse, p_term &WhereTerm, idxaff U8) &i8 {
	px := p_term.pExpr
	inexpr := Expr{}
	if sqlite3_expr_is_vector(px.pLeft) {
		i_field := p_term.u.x.iField - 1
		inexpr.flags = u32(0)
		inexpr.op = U8(54)
		inexpr.pLeft = c2v_at(&px.pLeft.x.pList.a[0], isize(i_field)).pExpr
		inexpr.pRight = c2v_at(&px.x.pSelect.pEList.a[0], isize(i_field)).pExpr
		px = &inexpr
	}
	if sqlite3_index_affinity_ok(px, i8(idxaff)) {
		p_ret := sqlite3_expr_compare_coll_seq(p_parse, px)
		return if p_ret { p_ret.zName } else { &sqlite3StrBINARY[0] }
	}
	return unsafe { nil }
}

@[c:'whereScanNext']
fn where_scan_next(p_scan &WhereScan) &WhereTerm {
	i_cur := 0
	i_column := I16(0)
	px := &Expr(0)
	pwc := &WhereClause(0)
	p_term := &WhereTerm(0)
	k := p_scan.k
	pwc = p_scan.pWC
	for {
		i_column = p_scan.aiColumn[int(p_scan.iEquiv) - 1]
		i_cur = p_scan.aiCur[int(p_scan.iEquiv) - 1]
		for {
			for p_term = pwc.a + k; k < pwc.nTerm; k++ {
				mut __c2v_condition_105 := false
				mut __c2v_condition_106 := false
				__c2v_condition_106 = p_term.leftCursor == i_cur
				if __c2v_condition_106 {
					__c2v_condition_106 = p_term.u.x.leftColumn == int(i_column)
				}
				if __c2v_condition_106 {
					__c2v_condition_106 = (int(i_column) != (-2) || sqlite3_expr_compare_skip(p_term.pExpr.pLeft, p_scan.pIdxExpr, i_cur) == 0)
				}
				if __c2v_condition_106 {
					__c2v_condition_106 = (int(p_scan.iEquiv) <= 1 || !((p_term.pExpr.flags & u32(1)) != u32(0)))
				}
				__c2v_condition_105 = __c2v_condition_106
				if __c2v_condition_105 {
					if (int(p_term.eOperator) & 2048) != 0 && int(p_scan.nEquiv) < 11 && usize(c2v_assign[&Expr](unsafe { &px }, where_right_subexpr_is_column(p_term.pExpr))) != usize(0) {
						j := 0
						for j = 0; j < int(p_scan.nEquiv); j++ {
							if p_scan.aiCur[j] == px.iTable && int(p_scan.aiColumn[j]) == int(px.iColumn) {
								break
							}
						}
						if j == int(p_scan.nEquiv) {
							p_scan.aiCur[j] = px.iTable
							p_scan.aiColumn[j] = px.iColumn
							p_scan.nEquiv++
						}
					}
					if (u32(p_term.eOperator) & p_scan.opMask) != u32(0) {
						if !isnil(p_scan.zCollName) && (int(p_term.eOperator) & 256) == 0 {
							z_coll_name := &i8(0)
							p_parse := pwc.pWInfo.pParse
							px = p_term.pExpr
							if (int(p_term.eOperator) & 1) {
								z_coll_name = index_in_affinity_ok(p_parse, p_term, U8(p_scan.idxaff))
								if isnil(z_coll_name) {
									unsafe { goto c2v_for_next_189
									 }
								}
							} else {
								p_coll := &CollSeq(0)
								if !sqlite3_index_affinity_ok(px, i8(p_scan.idxaff)) {
									unsafe { goto c2v_for_next_189
									 }
								}
								p_coll = sqlite3_expr_compare_coll_seq(p_parse, px)
								z_coll_name = if p_coll {
									p_coll.zName
								} else {
									unsafe { &sqlite3StrBINARY[0] }
								}
							}
							if sqlite3_str_ic_mp(z_coll_name, p_scan.zCollName) {
								unsafe { goto c2v_for_next_189
								 }
							}
						}
						if (int(p_term.eOperator) & (2 | 128)) != 0 && (if true {
							px = p_term.pExpr.pRight
							usize(px) != usize(0)
						} else {
							0
						}) && int(px.op) == 168 && px.iTable == p_scan.aiCur[0] && int(px.iColumn) == int(p_scan.aiColumn[0]) {
							unsafe { goto c2v_for_next_189
							 }
						}
						p_scan.pWC = pwc
						p_scan.k = k + 1
						return p_term
					}
				}
				c2v_for_next_189:
				c2v_pointer_postfix(voidptr(&p_term), p_term, isize(1))
			}
			pwc = pwc.pOuter
			k = 0
			if !(usize(pwc) != usize(0)) {
				break
			}
		}
		if int(p_scan.iEquiv) >= int(p_scan.nEquiv) {
			break
		}
		pwc = p_scan.pOrigWC
		k = 0
		p_scan.iEquiv++
	}
	return unsafe { nil }
}

@[c:'whereScanInitIndexExpr']
fn where_scan_init_index_expr(p_scan &WhereScan) &WhereTerm {
	p_scan.idxaff = sqlite3_expr_affinity(p_scan.pIdxExpr)
	return where_scan_next(p_scan)
}

@[c:'whereScanInit']
fn where_scan_init(p_scan &WhereScan, pwc &WhereClause, i_cur int, i_column int, op_mask u32, p_idx &Index) &WhereTerm {
	p_scan.pOrigWC = pwc
	p_scan.pWC = pwc
	p_scan.pIdxExpr = 0
	p_scan.idxaff = i8(0)
	p_scan.zCollName = 0
	p_scan.opMask = op_mask
	p_scan.k = 0
	p_scan.aiCur[0] = i_cur
	p_scan.nEquiv = u8(1)
	p_scan.iEquiv = u8(1)
	if p_idx {
		j := i_column
		i_column = int(p_idx.aiColumn[j])
		if i_column == int(p_idx.pTable.iPKey) {
			i_column = (-1)
		} else if i_column >= 0 {
			p_scan.idxaff = p_idx.pTable.aCol[i_column].affinity
			p_scan.zCollName = p_idx.azColl[j]
		} else if i_column == (-2) {
			p_scan.pIdxExpr = c2v_at(&p_idx.aColExpr.a[0], isize(j)).pExpr
			p_scan.zCollName = p_idx.azColl[j]
			p_scan.aiColumn[0] = I16((-2))
			return where_scan_init_index_expr(p_scan)
		}
	} else if i_column == (-2) {
		return unsafe { nil }
	}
	p_scan.aiColumn[0] = I16(i_column)
	return where_scan_next(p_scan)
}

@[c:'sqlite3WhereFindTerm']
fn sqlite3_where_find_term(pwc &WhereClause, i_cur int, i_column int, not_ready Bitmask, op u32, p_idx &Index) &WhereTerm {
	p_result := unsafe { &WhereTerm(nil) }
	p := &WhereTerm(0)
	scan := WhereScan{}
	p = where_scan_init(&scan, pwc, i_cur, i_column, op, p_idx)
	op &= u32(2 | 128)
	for p {
		if (p.prereqRight & not_ready) == Bitmask(0) {
			if p.prereqRight == Bitmask(0) && (u32(p.eOperator) & op) != u32(0) {
				return p
			}
			if usize(p_result) == usize(0) {
				p_result = p
			}
		}
		p = where_scan_next(&scan)
	}
	return p_result
}

@[c:'findIndexCol']
fn find_index_col(p_parse &Parse, p_list &ExprList, i_base int, p_idx &Index, i_col int) int {
	i := 0
	z_coll := p_idx.azColl[i_col]
	for i = 0; i < p_list.nExpr; i++ {
		p := sqlite3_expr_skip_collate_and_likely(c2v_at(&p_list.a[0], isize(i)).pExpr)
		if (usize(p) != usize(0)) && (int(p.op) == 168 || int(p.op) == 170) && int(p.iColumn) == int(p_idx.aiColumn[i_col]) && p.iTable == i_base {
			p_coll := sqlite3_expr_nn_coll_seq(p_parse, c2v_at(&p_list.a[0], isize(i)).pExpr)
			if 0 == sqlite3_str_ic_mp(p_coll.zName, z_coll) {
				return i
			}
		}
	}
	return -1
}

@[c:'indexColumnNotNull']
fn index_column_not_null(p_idx &Index, i_col int) int {
	j := 0
	j = int(p_idx.aiColumn[i_col])
	if j >= 0 {
		return int(p_idx.pTable.aCol[j].notNull)
	} else if j == (-1) {
		return 1
	} else {
		return 0
	}
}

@[c:'isDistinctRedundant']
fn is_distinct_redundant(p_parse &Parse, p_tab_list &SrcList, pwc &WhereClause, p_distinct &ExprList) int {
	p_tab := &Table(0)
	p_idx := &Index(0)
	i := 0
	i_base := 0
	if p_tab_list.nSrc != 1 {
		return 0
	}
	i_base = c2v_at(&p_tab_list.a[0], isize(0)).iCursor
	p_tab = c2v_at(&p_tab_list.a[0], isize(0)).pSTab
	for i = 0; i < p_distinct.nExpr; i++ {
		p := sqlite3_expr_skip_collate_and_likely(c2v_at(&p_distinct.a[0], isize(i)).pExpr)
		if (usize(p) == usize(0)) {
			continue
		}
		if int(p.op) != 168 && int(p.op) != 170 {
			continue
		}
		if p.iTable == i_base && int(p.iColumn) < 0 {
			return 1
		}
	}
	for p_idx = p_tab.pIndex; p_idx; p_idx = p_idx.pNext {
		if !(int(p_idx.onError) != 0) {
			continue
		}
		if p_idx.pPartIdxWhere {
			continue
		}
		for i = 0; i < int(p_idx.nKeyCol); i++ {
			if usize(0) == usize(sqlite3_where_find_term(pwc, i_base, i, ~Bitmask(0), u32(2), p_idx)) {
				if find_index_col(p_parse, p_distinct, i_base, p_idx, i) < 0 {
					break
				}
				if index_column_not_null(p_idx, i) == 0 {
					break
				}
			}
		}
		if i == int(p_idx.nKeyCol) {
			return 1
		}
	}
	return 0
}

@[c:'estLog']
fn est_log(n LogEst) LogEst {
	return LogEst(if int(n) <= 10 { 0 } else { int(sqlite3_log_est(U64(n))) - 33 })
}

@[c:'translateColumnToCopy']
fn translate_column_to_copy(p_parse &Parse, i_start int, i_tab_cur int, i_register int, i_autoidx_cur int) {
	v := p_parse.pVdbe
	p_op := sqlite3_vdbe_get_op(v, i_start)
	i_end := sqlite3_vdbe_current_addr(v)
	if p_parse.db.mallocFailed {
		return
	}
	for ; i_start < i_end; i_start++ {
		if p_op.p1 != i_tab_cur {
			unsafe { goto c2v_for_next_190
			 }
		}
		if int(p_op.opcode) == 96 {
			p_op.opcode = U8(82)
			p_op.p1 = p_op.p2 + i_register
			p_op.p2 = p_op.p3
			p_op.p3 = 0
			p_op.p5 = U16(2)
		} else if int(p_op.opcode) == 137 {
			p_op.opcode = U8(128)
			p_op.p1 = i_autoidx_cur
		}
		c2v_for_next_190:
		c2v_pointer_postfix(voidptr(&p_op), p_op, isize(1))
	}
}

@[c:'constraintCompatibleWithOuterJoin']
fn constraint_compatible_with_outer_join(p_term &WhereTerm, p_src &SrcItem) int {
	if !((p_term.pExpr.flags & u32((1 | 2))) != u32(0)) || p_term.pExpr.w.iJoin != p_src.iCursor {
		return 0
	}
	if (int(p_src.fg.jointype) & (8 | 16)) != 0 && ((p_term.pExpr.flags & u32(2)) != u32(0)) {
		return 0
	}
	return 1
}

@[c:'columnIsGoodIndexCandidate']
fn column_is_good_index_candidate(p_tab &Table, i_col int) int {
	p_idx := &Index(0)
	for p_idx = p_tab.pIndex; usize(p_idx) != usize(0); p_idx = p_idx.pNext {
		j := 0
		for j = 0; j < int(p_idx.nKeyCol); j++ {
			if int(p_idx.aiColumn[j]) == i_col {
				if j == 0 {
					return 0
				}
				if int(p_idx.hasStat1) && int(p_idx.aiRowLogEst[j + 1]) > 20 {
					return 0
				}
				break
			}
		}
	}
	return 1
}

@[c:'termCanDriveIndex']
fn term_can_drive_index(p_term &WhereTerm, p_src &SrcItem, not_ready Bitmask) int {
	aff := i8(0)
	left_col := 0
	if p_term.leftCursor != p_src.iCursor {
		return 0
	}
	if (int(p_term.eOperator) & (2 | 128)) == 0 {
		return 0
	}
	if (int(p_src.fg.jointype) & (8 | 64 | 16)) != 0 && !constraint_compatible_with_outer_join(p_term, p_src) {
		return 0
	}
	if (p_term.prereqRight & not_ready) != Bitmask(0) {
		return 0
	}
	left_col = p_term.u.x.leftColumn
	if left_col < 0 {
		return 0
	}
	aff = p_src.pSTab.aCol[left_col].affinity
	if !sqlite3_index_affinity_ok(p_term.pExpr, i8(aff)) {
		return 0
	}
	return column_is_good_index_candidate(p_src.pSTab, left_col)
}

@[c:'constructAutomaticIndex']
fn construct_automatic_index(p_parse &Parse, pwc &WhereClause, not_ready Bitmask, p_level &WhereLevel) {
	n_key_col := 0
	p_term := &WhereTerm(0)
	pwc_end := &WhereTerm(0)
	p_idx := &Index(0)
	v := &Vdbe(0)
	addr_init := 0
	p_table := &Table(0)
	addr_top := 0
	reg_record := 0
	n := 0
	i := 0
	mx_bit_col := 0
	p_coll := &CollSeq(0)
	p_loop := &WhereLoop(0)
	z_not_used := &i8(0)
	idx_cols := Bitmask(0)
	extra_cols := Bitmask(0)
	sent_warning := U8(0)
	use_bloom_filter := U8(0)
	p_partial := unsafe { &Expr(nil) }
	i_continue := 0
	p_tab_list := &SrcList(0)
	p_src := &SrcItem(0)
	addr_counter := 0
	reg_base := 0
	v = p_parse.pVdbe
	addr_init = sqlite3_vdbe_add_op0(v, 15)
	n_key_col = 0
	p_tab_list = pwc.pWInfo.pTabList
	p_src = unsafe { &p_tab_list.a[0] + p_level.iFrom }
	p_table = p_src.pSTab
	pwc_end = unsafe { pwc.a + pwc.nTerm }
	p_loop = p_level.pWLoop
	idx_cols = Bitmask(0)
	for p_term = pwc.a; usize(p_term) < usize(pwc_end); p_term = unsafe { p_term + 1 } {
		p_expr := p_term.pExpr
		if (int(p_term.wtFlags) & 2) == 0 && sqlite3_expr_is_single_table_constraint(p_expr, p_tab_list, int(p_level.iFrom), 0) {
			p_partial = sqlite3_expr_and(p_parse, p_partial, sqlite3_expr_dup(p_parse.db, p_expr, 0))
		}
		if term_can_drive_index(p_term, p_src, not_ready) {
			i_col := 0
			c_mask := Bitmask(0)
			i_col = p_term.u.x.leftColumn
			c_mask = if i_col >= (int((sizeof(Bitmask) * u64(8)))) {
				((Bitmask(1)) << ((int((sizeof(Bitmask) * u64(8)))) - 1))
			} else {
				((Bitmask(1)) << i_col)
			}
			if !sent_warning {
				sqlite3_log((28 | (1 << 8)), c'automatic index on %s(%s)', voidptr(p_table.zName), voidptr(p_table.aCol[i_col].zCnName))
				sent_warning = U8(1)
			}
			if (idx_cols & c_mask) == Bitmask(0) {
				if where_loop_resize(p_parse.db, p_loop, n_key_col + 1) {
					unsafe { goto end_auto_index_create
					 }
				}
				p_loop.aLTerm[n_key_col++] = p_term
				idx_cols |= c_mask
			}
		}
	}
	p_loop.nLTerm = U16(n_key_col)
	p_loop.u.btree.nEq = p_loop.nLTerm
	p_loop.wsFlags = u32(1 | 64 | 512 | 16384)
	if (int(p_table.eTabType) == 2) {
		extra_cols = (Bitmask(-1)) & ~idx_cols
	} else {
		extra_cols = p_src.colUsed & (~idx_cols | ((Bitmask(1)) << ((int((sizeof(Bitmask) * u64(8)))) - 1)))
	}
	if !((p_table.tabFlags & u32(128)) == u32(0)) {
		for i = 0; i < int(p_table.nCol); i++ {
			if (int(p_table.aCol[i].colFlags) & 1) == 0 {
				continue
			}
			if i >= (int((sizeof(Bitmask) * u64(8)))) - 1 {
				extra_cols |= ((Bitmask(1)) << ((int((sizeof(Bitmask) * u64(8)))) - 1))
				break
			}
			if idx_cols & ((Bitmask(1)) << i) {
				continue
			}
			extra_cols |= ((Bitmask(1)) << i)
		}
	}
	mx_bit_col = (if ((int((sizeof(Bitmask) * u64(8)))) - 1) < int(p_table.nCol) {
		((int((sizeof(Bitmask) * u64(8)))) - 1)
	} else {
		int(p_table.nCol)
	})
	for i = 0; i < mx_bit_col; i++ {
		if extra_cols & ((Bitmask(1)) << i) {
			n_key_col++
		}
	}
	if p_src.colUsed & ((Bitmask(1)) << ((int((sizeof(Bitmask) * u64(8)))) - 1)) {
		n_key_col += int(p_table.nCol) - (int((sizeof(Bitmask) * u64(8)))) + 1
	}
	p_idx = sqlite3_allocate_index_object(p_parse.db, n_key_col + int(((p_table.tabFlags & u32(128)) == u32(0))), 0, &&u8(&&i8(c2v_address_of(&z_not_used))))
	if usize(p_idx) == usize(0) {
		unsafe { goto end_auto_index_create
		 }
	}
	p_loop.u.btree.pIndex = p_idx
	p_idx.zName = c'auto-index'
	p_idx.pTable = p_table
	n = 0
	idx_cols = Bitmask(0)
	for p_term = pwc.a; usize(p_term) < usize(pwc_end); p_term = unsafe { p_term + 1 } {
		if term_can_drive_index(p_term, p_src, not_ready) {
			i_col := 0
			c_mask := Bitmask(0)
			i_col = p_term.u.x.leftColumn
			c_mask = if i_col >= (int((sizeof(Bitmask) * u64(8)))) {
				((Bitmask(1)) << ((int((sizeof(Bitmask) * u64(8)))) - 1))
			} else {
				((Bitmask(1)) << i_col)
			}
			if (idx_cols & c_mask) == Bitmask(0) {
				px := p_term.pExpr
				idx_cols |= c_mask
				p_idx.aiColumn[n] = I16(p_term.u.x.leftColumn)
				p_coll = sqlite3_expr_compare_coll_seq(p_parse, px)
				p_idx.azColl[n] = if p_coll { p_coll.zName } else { &sqlite3StrBINARY[0] }
				n++
				if (usize(px.pLeft) != usize(0)) && int(sqlite3_expr_affinity(px.pLeft)) != 66 {
					use_bloom_filter = U8(1)
				}
			}
		}
	}
	for i = 0; i < mx_bit_col; i++ {
		if extra_cols & ((Bitmask(1)) << i) {
			p_idx.aiColumn[n] = I16(i)
			p_idx.azColl[n] = unsafe { &sqlite3StrBINARY[0] }
			n++
		}
	}
	if p_src.colUsed & ((Bitmask(1)) << ((int((sizeof(Bitmask) * u64(8)))) - 1)) {
		for i = (int((sizeof(Bitmask) * u64(8)))) - 1; i < int(p_table.nCol); i++ {
			p_idx.aiColumn[n] = I16(i)
			p_idx.azColl[n] = unsafe { &sqlite3StrBINARY[0] }
			n++
		}
	}
	if ((p_table.tabFlags & u32(128)) == u32(0)) {
		p_idx.aiColumn[n] = I16((-1))
		p_idx.azColl[n] = unsafe { &sqlite3StrBINARY[0] }
	}
	mut __c2v_postfix_value_41 := p_parse.nTab
	p_parse.nTab++
	p_level.iIdxCur = __c2v_postfix_value_41
	sqlite3_vdbe_add_op2(v, 119, p_level.iIdxCur, n_key_col + 1)
	sqlite3_vdbe_set_p4_key_info(p_parse, p_idx)
	if ((p_parse.db.dbOptFlags & u32(524288)) == u32(0)) && int(use_bloom_filter) {
		sqlite3_where_explain_bloom_filter(p_parse, pwc.pWInfo, p_level)
		p_level.regFilter = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		sqlite3_vdbe_add_op2(v, 79, 10000, p_level.regFilter)
	}
	if p_src.fg.viaCoroutine {
		reg_yield := 0
		p_subq := &Subquery(0)
		p_subq = p_src.u4.pSubq
		reg_yield = p_subq.regReturn
		addr_counter = sqlite3_vdbe_add_op2(v, 73, 0, 0)
		sqlite3_vdbe_add_op3(v, 11, reg_yield, 0, p_subq.addrFillSub)
		addr_top = sqlite3_vdbe_add_op1(v, 12, reg_yield)
	} else {
		addr_top = sqlite3_vdbe_add_op2(v, 36, p_level.iTabCur, p_level.addrHalt)
	}
	if p_partial {
		i_continue = sqlite3_vdbe_make_label(p_parse)
		sqlite3_expr_if_false(p_parse, p_partial, i_continue, 16)
		p_loop.wsFlags |= u32(131072)
	}
	reg_record = sqlite3_get_temp_reg(p_parse)
	reg_base = sqlite3_generate_index_key(p_parse, p_idx, p_level.iTabCur, reg_record, 0, unsafe { nil }, unsafe { nil }, 0)
	if p_level.regFilter {
		sqlite3_vdbe_add_op4_int(v, 185, p_level.regFilter, 0, reg_base, int(p_loop.u.btree.nEq))
	}
	sqlite3_vdbe_add_op2(v, 140, p_level.iIdxCur, reg_record)
	sqlite3_vdbe_change_p5(v, U16(16))
	if p_partial {
		sqlite3_vdbe_resolve_label(v, i_continue)
	}
	if p_src.fg.viaCoroutine {
		sqlite3_vdbe_change_p2(v, addr_counter, reg_base + n)
		translate_column_to_copy(p_parse, addr_top, p_level.iTabCur, p_src.u4.pSubq.regResult, p_level.iIdxCur)
		sqlite3_vdbe_goto(v, addr_top)
		p_src.fg.viaCoroutine = u32(0)
		sqlite3_vdbe_jump_here(v, addr_top)
	} else {
		sqlite3_vdbe_add_op2(v, 40, p_level.iTabCur, addr_top + 1)
		sqlite3_vdbe_change_p5(v, U16(3))
		if (int(p_src.fg.jointype) & 8) != 0 {
			sqlite3_vdbe_jump_here(v, addr_top)
		}
	}
	sqlite3_release_temp_reg(p_parse, reg_record)
	sqlite3_vdbe_jump_here(v, addr_init)
	end_auto_index_create:
	sqlite3_expr_delete(p_parse.db, p_partial)
}

@[c:'sqlite3ConstructBloomFilter']
fn sqlite3_construct_bloom_filter(pwi_nfo &WhereInfo, i_level int, p_level &WhereLevel, not_ready Bitmask) {
	addr_once := 0
	addr_top := 0
	addr_cont := 0
	p_term := &WhereTerm(0)
	pwc_end := &WhereTerm(0)
	p_parse := pwi_nfo.pParse
	v := p_parse.pVdbe
	p_loop := p_level.pWLoop
	i_cur := 0
	saved_p_idx_epr := &IndexedExpr(0)
	saved_p_idx_part_expr := &IndexedExpr(0)
	saved_p_idx_epr = p_parse.pIdxEpr
	saved_p_idx_part_expr = p_parse.pIdxPartExpr
	p_parse.pIdxEpr = 0
	p_parse.pIdxPartExpr = 0
	addr_once = sqlite3_vdbe_add_op0(v, 15)
	for {
		p_tab_list := &SrcList(0)
		p_item := &SrcItem(0)
		p_tab := &Table(0)
		sz := U64(0)
		i_src := 0
		sqlite3_where_explain_bloom_filter(p_parse, pwi_nfo, p_level)
		addr_cont = sqlite3_vdbe_make_label(p_parse)
		i_cur = p_level.iTabCur
		p_level.regFilter = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		p_tab_list = pwi_nfo.pTabList
		i_src = int(p_level.iFrom)
		p_item = unsafe { &p_tab_list.a[0] + i_src }
		p_tab = p_item.pSTab
		sz = sqlite3_log_est_to_int(p_tab.nRowLogEst)
		if sz < U64(10000) {
			sz = U64(10000)
		} else if sz > U64(10000000) {
			sz = U64(10000000)
		}
		sqlite3_vdbe_add_op2(v, 79, int(sz), p_level.regFilter)
		addr_top = sqlite3_vdbe_add_op1(v, 36, i_cur)
		pwc_end = unsafe { pwi_nfo.sWC.a + pwi_nfo.sWC.nTerm }
		for p_term = pwi_nfo.sWC.a; usize(p_term) < usize(pwc_end); p_term = unsafe { p_term + 1 } {
			p_expr := p_term.pExpr
			if (int(p_term.wtFlags) & 2) == 0 && sqlite3_expr_is_single_table_constraint(p_expr, p_tab_list, i_src, 0) {
				sqlite3_expr_if_false(p_parse, p_term.pExpr, addr_cont, 16)
			}
		}
		if p_loop.wsFlags & u32(256) {
			r1 := sqlite3_get_temp_reg(p_parse)
			sqlite3_vdbe_add_op2(v, 137, i_cur, r1)
			sqlite3_vdbe_add_op4_int(v, 185, p_level.regFilter, 0, r1, 1)
			sqlite3_release_temp_reg(p_parse, r1)
		} else {
			p_idx := p_loop.u.btree.pIndex
			n := int(p_loop.u.btree.nEq)
			r1 := sqlite3_get_temp_range(p_parse, n)
			jj := 0
			for jj = 0; jj < n; jj++ {
				sqlite3_expr_code_load_index_column(p_parse, p_idx, i_cur, jj, r1 + jj)
			}
			sqlite3_vdbe_add_op4_int(v, 185, p_level.regFilter, 0, r1, n)
			sqlite3_release_temp_range(p_parse, r1, n)
		}
		sqlite3_vdbe_resolve_label(v, addr_cont)
		sqlite3_vdbe_add_op2(v, 40, p_level.iTabCur, addr_top + 1)
		sqlite3_vdbe_jump_here(v, addr_top)
		p_loop.wsFlags &= u32(~4194304)
		if ((p_parse.db.dbOptFlags & u32(1048576)) != u32(0)) {
			break
		}
		for {
			i_level++
			if !(i_level < int(pwi_nfo.nLevel)) {
				break
			}
			p_tab_item := &SrcItem(0)
			p_level = unsafe { &pwi_nfo.a[0] + i_level }
			p_tab_item = unsafe { &pwi_nfo.pTabList.a[0] + p_level.iFrom }
			if int(p_tab_item.fg.jointype) & (8 | 64) {
				continue
			}
			p_loop = p_level.pWLoop
			if (usize(p_loop) == usize(0)) {
				continue
			}
			if p_loop.prereq & not_ready {
				continue
			}
			if (p_loop.wsFlags & u32((4194304 | 4))) == u32(4194304) {
				break
			}
		}
		if !(i_level < int(pwi_nfo.nLevel)) {
			break
		}
	}
	sqlite3_vdbe_jump_here(v, addr_once)
	p_parse.pIdxEpr = saved_p_idx_epr
	p_parse.pIdxPartExpr = saved_p_idx_part_expr
}

@[c:'termFromWhereClause']
fn term_from_where_clause(pwc &WhereClause, i_term int) &WhereTerm {
	p := &WhereClause(0)
	for p = pwc; p; p = p.pOuter {
		if i_term < p.nTerm {
			return unsafe { p.a + i_term }
		}
		i_term -= p.nTerm
	}
	return unsafe { nil }
}

@[c:'allocateIndexInfo']
fn allocate_index_info(pwi_nfo &WhereInfo, pwc &WhereClause, m_unusable Bitmask, p_src &SrcItem, pm_no_omit &U16) &Sqlite3_index_info {
	i := 0
	j := 0

	n_term := 0
	p_parse := pwi_nfo.pParse
	mut p_idx_cons := &Sqlite3_index_constraint(0)
	mut p_idx_order_by := &Sqlite3_index_orderby(0)
	p_usage := &Sqlite3_index_constraint_usage(0)
	p_hidden := &HiddenIndexInfo(0)
	p_term := &WhereTerm(0)
	n_order_by := 0
	p_idx_info := &Sqlite3_index_info(0)
	m_no_omit := U16(0)
	p_tab := &Table(0)
	e_distinct := 0
	p_order_by := pwi_nfo.pOrderBy
	p := &WhereClause(0)
	p_tab = p_src.pSTab
	p = pwc
	for n_term = 0; p; p = p.pOuter {
		i = 0
		for p_term = p.a; i < p.nTerm; i++ {
			p_term.wtFlags &= ~64
			if p_term.leftCursor != p_src.iCursor {
				unsafe { goto c2v_for_next_192
				 }
			}
			if p_term.prereqRight & m_unusable {
				unsafe { goto c2v_for_next_192
				 }
			}
			if (int(p_term.eOperator) & ~2048) == 0 {
				unsafe { goto c2v_for_next_192
				 }
			}
			if int(p_term.wtFlags) & 128 {
				unsafe { goto c2v_for_next_192
				 }
			}
			if (int(p_src.fg.jointype) & (8 | 64 | 16)) != 0 && !constraint_compatible_with_outer_join(p_term, p_src) {
				unsafe { goto c2v_for_next_192
				 }
			}
			n_term++
			p_term.wtFlags |= 64
			c2v_for_next_192:
			c2v_pointer_postfix(voidptr(&p_term), p_term, isize(1))
		}
	}
	n_order_by = 0
	if p_order_by {
		n := p_order_by.nExpr
		for i = 0; i < n; i++ {
			p_expr := c2v_at(&p_order_by.a[0], isize(i)).pExpr
			p_e2 := &Expr(0)
			if sqlite3_expr_is_constant(unsafe { nil }, p_expr) {
				continue
			}
			if int(c2v_at(&p_order_by.a[0], isize(i)).fg.sortFlags) & 2 {
				break
			}
			if int(p_expr.op) == 168 && p_expr.iTable == p_src.iCursor {
				continue
			}
			if int(p_expr.op) == 114 && int(c2v_assign[&Expr](unsafe { &p_e2 }, p_expr.pLeft).op) == 168 && p_e2.iTable == p_src.iCursor {
				z_coll := &i8(0)
				p_expr.iColumn = p_e2.iColumn
				if int(p_e2.iColumn) < 0 {
					continue
				}
				z_coll = sqlite3_column_coll(unsafe { p_tab.aCol + p_e2.iColumn })
				if usize(z_coll) == usize(0) {
					z_coll = unsafe { &sqlite3StrBINARY[0] }
				}
				if sqlite3_stricmp(p_expr.u.zToken, z_coll) == 0 {
					continue
				}
			}
			break
		}
		if i == n {
			b_sort_by_group := int((int(pwi_nfo.wctrlFlags) & 512) != 0)
			n_order_by = n
			if (int(pwi_nfo.wctrlFlags) & 128) && !p_src.fg.rowidUsed {
				e_distinct = 2 + b_sort_by_group
			} else if int(pwi_nfo.wctrlFlags) & 64 {
				e_distinct = 1 - b_sort_by_group
			} else if int(pwi_nfo.wctrlFlags) & 256 {
				e_distinct = 3
			}
		}
	}
	p_idx_info = sqlite3_db_malloc_zero(p_parse.db, U64(sizeof(Sqlite3_index_info) + (sizeof(Sqlite3_index_constraint) + sizeof(Sqlite3_index_constraint_usage)) * u64(n_term) + sizeof(Sqlite3_index_orderby) * u64(n_order_by) + ((u64(usize(__offsetof(HiddenIndexInfo, aRhs)))) + u64(n_term) * sizeof(voidptr))))
	if usize(p_idx_info) == usize(0) {
		sqlite3_error_msg(p_parse, c'out of memory')
		return unsafe { nil }
	}
	p_hidden = &HiddenIndexInfo(voidptr(unsafe { p_idx_info + 1 }))
	p_idx_cons = &Sqlite3_index_constraint(voidptr(unsafe { &p_hidden.aRhs[0] + n_term }))
	p_idx_order_by = &Sqlite3_index_orderby(voidptr(unsafe { p_idx_cons + n_term }))
	p_usage = &Sqlite3_index_constraint_usage(voidptr(unsafe { p_idx_order_by + n_order_by }))
	p_idx_info.aConstraint = p_idx_cons
	p_idx_info.aOrderBy = p_idx_order_by
	p_idx_info.aConstraintUsage = p_usage
	p_idx_info.colUsed = Sqlite3_uint64(Sqlite3_int64(p_src.colUsed))
	if ((p_tab.tabFlags & u32(128)) == u32(0)) == 0 {
		p_pk := sqlite3_primary_key_index(&Table(p_tab))
		for i = 0; i < int(p_pk.nKeyCol); i++ {
			i_col := int(p_pk.aiColumn[i])
			if i_col >= (int((sizeof(Bitmask) * u64(8)))) - 1 {
				i_col = (int((sizeof(Bitmask) * u64(8)))) - 1
			}
			p_idx_info.colUsed |= ((Bitmask(1)) << i_col)
		}
	}
	p_hidden.pWC = pwc
	p_hidden.pParse = p_parse
	p_hidden.eDistinct = e_distinct
	p_hidden.mIn = u32(0)
	p = pwc
	j = 0
	i = j
	for p {
		n_last := i + p.nTerm
		for p_term = p.a; i < n_last; i++ {
			op := U16(0)
			if (int(p_term.wtFlags) & 64) == 0 {
				unsafe { goto c2v_for_next_194
				 }
			}
			p_idx_cons[j].iColumn = p_term.u.x.leftColumn
			p_idx_cons[j].iTermOffset = i
			op = U16(int(p_term.eOperator) & 16383)
			if int(op) == 1 {
				if (int(p_term.wtFlags) & 32768) == 0 {
					p_hidden.mIn |= (if j <= 31 { (u32(1)) << j } else { u32(0) })
				}
				op = U16(2)
			}
			if int(op) == 64 {
				p_idx_cons[j].op = p_term.eMatchOp
			} else if int(op) & (256 | 128) {
				if int(op) == 256 {
					p_idx_cons[j].op = u8(71)
				} else {
					p_idx_cons[j].op = u8(72)
				}
			} else {
				p_idx_cons[j].op = U8(op)
				if int(op) & ((2 << (57 - 54)) | (2 << (56 - 54)) | (2 << (55 - 54)) | (2 << (58 - 54))) && sqlite3_expr_is_vector(p_term.pExpr.pRight) {
					if j < 16 {
						m_no_omit |= (1 << j)
					}
					if int(op) == (2 << (57 - 54)) {
						p_idx_cons[j].op = u8((2 << (56 - 54)))
					}
					if int(op) == (2 << (55 - 54)) {
						p_idx_cons[j].op = u8((2 << (58 - 54)))
					}
				}
			}
			j++
			c2v_for_next_194:
			c2v_pointer_postfix(voidptr(&p_term), p_term, isize(1))
		}
		p = p.pOuter
	}
	p_idx_info.nConstraint = j
	j = 0
	for i = 0; i < n_order_by; i++ {
		p_expr := c2v_at(&p_order_by.a[0], isize(i)).pExpr
		if sqlite3_expr_is_constant(unsafe { nil }, p_expr) {
			continue
		}
		p_idx_order_by[j].iColumn = int(p_expr.iColumn)
		p_idx_order_by[j].desc = u8(int(c2v_at(&p_order_by.a[0], isize(i)).fg.sortFlags) & 1)
		j++
	}
	p_idx_info.nOrderBy = j
	unsafe { *pm_no_omit = m_no_omit }
	return p_idx_info
}

@[c:'freeIdxStr']
fn free_idx_str(p_idx_info &Sqlite3_index_info) {
	if p_idx_info.needToFreeIdxStr {
		sqlite3_free(voidptr(p_idx_info.idxStr))
		p_idx_info.idxStr = 0
		p_idx_info.needToFreeIdxStr = 0
	}
}

@[c:'freeIndexInfo']
fn free_index_info(db &Sqlite3, p_idx_info &Sqlite3_index_info) {
	p_hidden := &HiddenIndexInfo(0)
	i := 0
	p_hidden = &HiddenIndexInfo(voidptr(unsafe { p_idx_info + 1 }))
	for i = 0; i < p_idx_info.nConstraint; i++ {
		sqlite3_value_free_vdup7((&p_hidden.aRhs[0])[i])
		(&p_hidden.aRhs[0])[i] = 0
	}
	free_idx_str(p_idx_info)
	sqlite3_db_free(db, voidptr(p_idx_info))
}

@[c:'vtabBestIndex']
fn vtab_best_index(p_parse &Parse, p_tab &Table, p &Sqlite3_index_info) int {
	rc := 0
	p_vtab := &Sqlite3_vtab(0)
	p_vtab = sqlite3_get_vt_able(p_parse.db, p_tab).pVtab
	p_parse.db.nSchemaLock++
	rc = p_vtab.pModule.xBestIndex(p_vtab, p)
	p_parse.db.nSchemaLock--
	if rc != 0 && rc != 19 {
		if rc == 7 {
			sqlite3_oom_fault(p_parse.db)
		} else if isnil(p_vtab.zErrMsg) {
			sqlite3_error_msg(p_parse, c'%s', voidptr(sqlite3_err_str(rc)))
		} else {
			sqlite3_error_msg(p_parse, c'%s', voidptr(p_vtab.zErrMsg))
		}
	}
	if p_tab.u.vtab.p.bAllSchemas {
		sqlite3_vtab_uses_all_schemas(p_parse)
	}
	sqlite3_free(voidptr(p_vtab.zErrMsg))
	p_vtab.zErrMsg = 0
	return rc
}

@[c:'whereRangeAdjust']
fn where_range_adjust(p_term &WhereTerm, n_new LogEst) LogEst {
	n_ret := n_new
	if p_term {
		if int(p_term.truthProb) <= 0 {
			n_ret += int(p_term.truthProb)
		} else if (int(p_term.wtFlags) & 128) == 0 {
			n_ret -= 20
		}
	}
	return n_ret
}

@[c:'whereRangeScanEst']
fn where_range_scan_est(p_parse &Parse, p_builder &WhereLoopBuilder, p_lower &WhereTerm, p_upper &WhereTerm, p_loop &WhereLoop) int {
	rc := 0
	n_out := int(p_loop.nOut)
	n_new := LogEst(0)

	n_new = where_range_adjust(p_lower, LogEst(n_out))
	n_new = where_range_adjust(p_upper, n_new)
	if !isnil(p_lower) && int(p_lower.truthProb) > 0 && !isnil(p_upper) && int(p_upper.truthProb) > 0 {
		n_new -= 20
	}
	n_out -= int((usize(p_lower) != usize(0))) + int((usize(p_upper) != usize(0)))
	if int(n_new) < 10 {
		n_new = LogEst(10)
	}
	if int(n_new) < n_out {
		n_out = int(n_new)
	}
	p_loop.nOut = LogEst(n_out)
	return rc
}

@[c:'whereLoopInit']
fn where_loop_init(p &WhereLoop) {
	p.aLTerm = unsafe { &p.aLTermSpace[0] }
	p.nLTerm = U16(0)
	p.nLSlot = 3
	p.wsFlags = u32(0)
}

@[c:'whereLoopClearUnion']
fn where_loop_clear_union(db &Sqlite3, p &WhereLoop) {
	if p.wsFlags & u32((1024 | 16384)) {
		if (p.wsFlags & u32(1024)) != u32(0) && int(p.u.vtab.needFree) {
			sqlite3_free(voidptr(p.u.vtab.idxStr))
			p.u.vtab.needFree = u32(0)
			p.u.vtab.idxStr = 0
		} else if (p.wsFlags & u32(16384)) != u32(0) && usize(p.u.btree.pIndex) != usize(0) {
			sqlite3_db_free(db, voidptr(p.u.btree.pIndex.zColAff))
			sqlite3_db_free_nn(db, voidptr(p.u.btree.pIndex))
			p.u.btree.pIndex = 0
		}
	}
}

@[c:'whereLoopClear']
fn where_loop_clear(db &Sqlite3, p &WhereLoop) {
	if usize(p.aLTerm) != usize(unsafe { &p.aLTermSpace[0] }) {
		sqlite3_db_free_nn(db, voidptr(p.aLTerm))
		p.aLTerm = unsafe { &p.aLTermSpace[0] }
		p.nLSlot = 3
	}
	where_loop_clear_union(db, p)
	p.nLTerm = U16(0)
	p.wsFlags = u32(0)
}

@[c:'whereLoopResize']
fn where_loop_resize(db &Sqlite3, p &WhereLoop, n int) int {
	pa_new := &&WhereTerm(0)
	if int(p.nLSlot) >= n {
		return 0
	}
	n = (n + 7) & ~7
	pa_new = sqlite3_db_malloc_raw_nn(db, U64(sizeof(&WhereTerm) * u64(n)))
	if usize(pa_new) == usize(0) {
		return 7
	}
	C.memcpy(voidptr(pa_new), voidptr(p.aLTerm), sizeof(&WhereTerm) * u64(p.nLSlot))
	if usize(p.aLTerm) != usize(unsafe { &p.aLTermSpace[0] }) {
		sqlite3_db_free_nn(db, voidptr(p.aLTerm))
	}
	p.aLTerm = pa_new
	p.nLSlot = U16(n)
	return 0
}

@[c:'whereLoopXfer']
fn where_loop_xfer(db &Sqlite3, p_to &WhereLoop, p_from &WhereLoop) int {
	where_loop_clear_union(db, p_to)
	if int(p_from.nLTerm) > int(p_to.nLSlot) && where_loop_resize(db, p_to, int(p_from.nLTerm)) {
		C.memset(voidptr(p_to), 0, (u64(usize(__offsetof(WhereLoop, nLSlot)))))
		return 7
	}
	C.memcpy(voidptr(p_to), voidptr(p_from), (u64(usize(__offsetof(WhereLoop, nLSlot)))))
	C.memcpy(voidptr(p_to.aLTerm), voidptr(p_from.aLTerm), u64(p_to.nLTerm) * sizeof(&WhereTerm))
	if p_from.wsFlags & u32(1024) {
		p_from.u.vtab.needFree = u32(0)
	} else if (p_from.wsFlags & u32(16384)) != u32(0) {
		p_from.u.btree.pIndex = 0
	}
	return 0
}

@[c:'whereLoopDelete']
fn where_loop_delete(db &Sqlite3, p &WhereLoop) {
	where_loop_clear(db, p)
	sqlite3_db_nn_free_nn(db, voidptr(p))
}

@[c:'whereInfoFree']
fn where_info_free(db &Sqlite3, pwi_nfo &WhereInfo) {
	sqlite3_where_clause_clear(&pwi_nfo.sWC)
	for pwi_nfo.pLoops {
		p := pwi_nfo.pLoops
		pwi_nfo.pLoops = p.pNextLoop
		where_loop_delete(db, p)
	}
	for pwi_nfo.pMemToFree {
		p_next := pwi_nfo.pMemToFree.pNext
		sqlite3_db_nn_free_nn(db, voidptr(pwi_nfo.pMemToFree))
		pwi_nfo.pMemToFree = p_next
	}
	sqlite3_db_nn_free_nn(db, voidptr(pwi_nfo))
}

@[c:'whereLoopCheaperProperSubset']
fn where_loop_cheaper_proper_subset(px &WhereLoop, py &WhereLoop) int {
	i := 0
	j := 0

	if int(px.rRun) > int(py.rRun) && int(px.nOut) > int(py.nOut) {
		return 0
	}
	if int(px.u.btree.nEq) < int(py.u.btree.nEq) && usize(px.u.btree.pIndex) == usize(py.u.btree.pIndex) && int(px.nSkip) == 0 && int(py.nSkip) == 0 {
		return 1
	}
	if int(px.nLTerm) - int(px.nSkip) >= int(py.nLTerm) - int(py.nSkip) {
		return 0
	}
	if int(py.nSkip) > int(px.nSkip) {
		return 0
	}
	for i = int(px.nLTerm) - 1; i >= 0; i-- {
		if usize(px.aLTerm[i]) == usize(0) {
			continue
		}
		for j = int(py.nLTerm) - 1; j >= 0; j-- {
			if usize(py.aLTerm[j]) == usize(px.aLTerm[i]) {
				break
			}
		}
		if j < 0 {
			return 0
		}
	}
	if (px.wsFlags & u32(64)) != u32(0) && (py.wsFlags & u32(64)) == u32(0) {
		return 0
	}
	return 1
}

@[c:'whereLoopAdjustCost']
fn where_loop_adjust_cost(p &WhereLoop, p_template &WhereLoop) {
	if (p_template.wsFlags & u32(512)) == u32(0) {
		return
	}
	for ; p; p = p.pNextLoop {
		if int(p.iTab) != int(p_template.iTab) {
			continue
		}
		if (p.wsFlags & u32(512)) == u32(0) {
			continue
		}
		if where_loop_cheaper_proper_subset(p, p_template) {
			p_template.rRun = LogEst((if int(p.rRun) < int(p_template.rRun) {
				int(p.rRun)
			} else {
				int(p_template.rRun)
			}))
			p_template.nOut = LogEst((if (int(p.nOut) - 1) < int(p_template.nOut) {
				(int(p.nOut) - 1)
			} else {
				int(p_template.nOut)
			}))
		} else if where_loop_cheaper_proper_subset(p_template, p) {
			p_template.rRun = LogEst((if int(p.rRun) > int(p_template.rRun) {
				int(p.rRun)
			} else {
				int(p_template.rRun)
			}))
			p_template.nOut = LogEst((if (int(p.nOut) + 1) > int(p_template.nOut) {
				(int(p.nOut) + 1)
			} else {
				int(p_template.nOut)
			}))
		}
	}
}

@[c:'whereLoopFindLesser']
fn where_loop_find_lesser(pp_prev &&WhereLoop, p_template &WhereLoop) &&WhereLoop {
	p := &WhereLoop(0)
	for p = unsafe { *pp_prev }; p;  {
		if int(p.iTab) != int(p_template.iTab) || int(p.iSortIdx) != int(p_template.iSortIdx) {
			unsafe { goto c2v_for_next_195
			 }
		}
		mut __c2v_condition_107 := false
		mut __c2v_condition_108 := false
		__c2v_condition_108 = (p.wsFlags & u32(16384)) != u32(0)
		if __c2v_condition_108 {
			__c2v_condition_108 = int(p_template.nSkip) == 0
		}
		if __c2v_condition_108 {
			__c2v_condition_108 = (p_template.wsFlags & u32(512)) != u32(0)
		}
		if __c2v_condition_108 {
			__c2v_condition_108 = (p_template.wsFlags & u32(1)) != u32(0)
		}
		if __c2v_condition_108 {
			__c2v_condition_108 = (p.prereq & p_template.prereq) == p_template.prereq
		}
		__c2v_condition_107 = __c2v_condition_108
		if __c2v_condition_107 {
			break
		}
		if (p.prereq & p_template.prereq) == p.prereq && int(p.rSetup) <= int(p_template.rSetup) && int(p.rRun) <= int(p_template.rRun) && int(p.nOut) <= int(p_template.nOut) {
			return unsafe { nil }
		}
		if (p.prereq & p_template.prereq) == p_template.prereq && int(p.rRun) >= int(p_template.rRun) && int(p.nOut) >= int(p_template.nOut) {
			break
		}
		c2v_for_next_195:
		pp_prev = &p.pNextLoop
		p = unsafe { *pp_prev }
	}
	return pp_prev
}

@[c:'whereLoopInsert']
fn where_loop_insert(p_builder &WhereLoopBuilder, p_template &WhereLoop) int {
	pp_prev := &&WhereLoop(0)
	p := &WhereLoop(0)

	pwi_nfo := p_builder.pWInfo
	db := pwi_nfo.pParse.db
	rc := 0
	if p_builder.iPlanLimit == u32(0) {
		if p_builder.pOrSet {
			p_builder.pOrSet.n = U16(0)
		}
		return 101
	}
	p_builder.iPlanLimit--
	where_loop_adjust_cost(pwi_nfo.pLoops, p_template)
	if usize(p_builder.pOrSet) != usize(0) {
		if p_template.nLTerm {
			where_or_insert(p_builder.pOrSet, p_template.prereq, p_template.rRun, p_template.nOut)
		}
		return 0
	}
	pp_prev = where_loop_find_lesser(&&WhereLoop(&pwi_nfo.pLoops), p_template)
	if usize(pp_prev) == usize(0) {
		return 0
	} else {
		p = unsafe { *pp_prev }
	}
	if usize(p) == usize(0) {
		p = sqlite3_db_malloc_raw_nn(db, U64(sizeof(WhereLoop)))
		unsafe { *pp_prev = p }
		if usize(p) == usize(0) {
			return 7
		}
		where_loop_init(p)
		p.pNextLoop = 0
	} else {
		pp_tail := &p.pNextLoop
		p_to_del := &WhereLoop(0)
		for unsafe { *pp_tail != nil } {
			pp_tail = where_loop_find_lesser(pp_tail, p_template)
			if usize(pp_tail) == usize(0) {
				break
			}
			p_to_del = unsafe { *pp_tail }
			if usize(p_to_del) == usize(0) {
				break
			}
			unsafe { *pp_tail = p_to_del.pNextLoop }
			where_loop_delete(db, p_to_del)
		}
	}
	rc = where_loop_xfer(db, p, p_template)
	if (p.wsFlags & u32(1024)) == u32(0) {
		p_index := p.u.btree.pIndex
		if !isnil(p_index) && int(p_index.idxType) == 3 {
			p.u.btree.pIndex = 0
		}
	}
	return rc
}

@[c:'exprNodePatternLengthEst']
fn expr_node_pattern_length_est(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	if int(p_expr.op) == 118 {
		sz := 0
		z := &U8(voidptr(p_expr.u.zToken))
		c := U8(0)
		c1 := U8(0)
		c2 := U8(0)
		c3 := U8(0)

		if p_walker.eCode {
			c1 = U8(`%`)
			c2 = U8(`_`)
			c3 = U8(0)
		} else {
			c1 = U8(`*`)
			c2 = U8(`?`)
			c3 = U8(`[`)
		}
		for {
			c = unsafe { *(c2v_pointer_postfix(voidptr(&z), z, isize(1))) }
			if !(int(c) != 0) {
				break
			}
			if int(c) == int(c3) {
				if (unsafe { *z }) {
					c2v_pointer_postfix(voidptr(&z), z, isize(1))
				}
				for int((unsafe { *z })) && int((unsafe { *z })) != `]` {
					c2v_pointer_postfix(voidptr(&z), z, isize(1))
				}
			} else if int(c) != int(c1) && int(c) != int(c2) {
				sz++
			}
		}
		if sz > p_walker.u.sz {
			p_walker.u.sz = sz
		}
	}
	return 0
}

@[c:'estLikePatternLength']
fn est_like_pattern_length(p &Expr, e_code U16) int {
	w := Walker{}
	w.u.sz = 0
	w.eCode = e_code
	w.xExprCallback = expr_node_pattern_length_est
	w.xSelectCallback = sqlite3_select_walk_fail
	sqlite3_walk_expr(&w, p)
	return w.u.sz
}

@[c:'whereLoopOutputAdjust']
fn where_loop_output_adjust(pwc &WhereClause, p_loop &WhereLoop, n_row LogEst) {
	p_term := &WhereTerm(0)
	px := &WhereTerm(0)

	not_allowed := ~(p_loop.prereq | p_loop.maskSelf)
	i := 0
	j := 0

	i_reduce := LogEst(0)
	i = pwc.nBase
	for p_term = pwc.a; i > 0; i-- {
		if (p_term.prereqAll & not_allowed) != Bitmask(0) {
			unsafe { goto c2v_for_next_196
			 }
		}
		if (p_term.prereqAll & p_loop.maskSelf) == Bitmask(0) {
			unsafe { goto c2v_for_next_196
			 }
		}
		if (int(p_term.wtFlags) & 2) != 0 {
			unsafe { goto c2v_for_next_196
			 }
		}
		for j = int(p_loop.nLTerm) - 1; j >= 0; j-- {
			px = p_loop.aLTerm[j]
			if usize(px) == usize(0) {
				continue
			}
			if usize(px) == usize(p_term) {
				break
			}
			if px.iParent >= 0 && usize((unsafe { pwc.a + px.iParent })) == usize(p_term) {
				break
			}
		}
		if j < 0 {
			sqlite3_progress_check(pwc.pWInfo.pParse)
			if p_loop.maskSelf == p_term.prereqAll {
				if (int(p_term.eOperator) & 63) != 0 || (int(c2v_at(&pwc.pWInfo.pTabList.a[0], isize(p_loop.iTab)).fg.jointype) & (8 | 64)) == 0 {
					p_loop.wsFlags |= u32(8388608)
				}
			}
			if int(p_term.truthProb) <= 0 {
				p_loop.nOut += int(p_term.truthProb)
			} else {
				p_op_expr := p_term.pExpr
				p_loop.nOut--
				if (int(p_term.eOperator) & (2 | 128)) != 0 && (int(p_term.wtFlags) & 0) == 0 {
					p_right := p_op_expr.pRight
					k := 0
					if sqlite3_expr_is_integer(p_right, &k, unsafe { nil }) && k >= (-1) && k <= 1 {
						k = 10
					} else {
						k = 20
					}
					if int(i_reduce) < k {
						p_term.wtFlags |= 8192
						i_reduce = LogEst(k)
					}
				} else if ((p_op_expr.flags & u32(256)) != u32(0)) && int(p_op_expr.op) == 172 {
					e_op := 0
					e_op = sqlite3_expr_is_like_operator(p_op_expr)
					if (e_op > 0) {
						sz_pattern := 0
						prhs := c2v_at(&p_op_expr.x.pList.a[0], isize(0)).pExpr
						e_op = e_op == 65
						sz_pattern = est_like_pattern_length(prhs, U16(e_op))
						if sz_pattern > 0 {
							p_loop.nOut -= sz_pattern * 2
						}
					}
				}
			}
		}
		c2v_for_next_196:
		c2v_pointer_postfix(voidptr(&p_term), p_term, isize(1))
	}
	if int(p_loop.nOut) > int(n_row) - int(i_reduce) {
		p_loop.nOut = LogEst(int(n_row) - int(i_reduce))
	}
}

@[c:'whereRangeVectorLen']
fn where_range_vector_len(p_parse &Parse, i_cur int, p_idx &Index, n_eq int, p_term &WhereTerm) int {
	n_cmp := sqlite3_expr_vector_size(p_term.pExpr.pLeft)
	i := 0
	n_cmp = (if n_cmp < (int(p_idx.nColumn) - n_eq) { n_cmp } else { (int(p_idx.nColumn) - n_eq) })
	for i = 1; i < n_cmp; i++ {
		aff := i8(0)
		idxaff := i8(0)
		p_coll := &CollSeq(0)
		p_lhs := &Expr(0)
		p_rhs := &Expr(0)

		p_lhs = c2v_at(&p_term.pExpr.pLeft.x.pList.a[0], isize(i)).pExpr
		p_rhs = p_term.pExpr.pRight
		if ((p_rhs.flags & u32(4096)) != u32(0)) {
			p_rhs = c2v_at(&p_rhs.x.pSelect.pEList.a[0], isize(i)).pExpr
		} else {
			p_rhs = c2v_at(&p_rhs.x.pList.a[0], isize(i)).pExpr
		}
		if int(p_lhs.op) != 168 || p_lhs.iTable != i_cur || int(p_lhs.iColumn) != int(p_idx.aiColumn[i + n_eq]) || int(p_idx.aSortOrder[i + n_eq]) != int(p_idx.aSortOrder[n_eq]) {
			break
		}
		aff = sqlite3_compare_affinity(p_rhs, i8(sqlite3_expr_affinity(p_lhs)))
		idxaff = sqlite3_table_column_affinity(p_idx.pTable, int(p_lhs.iColumn))
		if int(aff) != int(idxaff) {
			break
		}
		if ((p_term.pExpr.flags & u32(1024)) != u32(0)) {
			t := p_rhs
			p_rhs = p_lhs
			p_lhs = t
		}
		p_coll = sqlite3_binary_compare_coll_seq(p_parse, p_lhs, p_rhs)
		if usize(p_coll) == usize(0) {
			break
		}
		if sqlite3_str_ic_mp(p_coll.zName, p_idx.azColl[i + n_eq]) {
			break
		}
	}
	return i
}

@[c:'whereLoopAddBtreeIndex']
fn where_loop_add_btree_index(p_builder &WhereLoopBuilder, p_src &SrcItem, p_probe &Index, n_in_mul LogEst) int {
	pwi_nfo := p_builder.pWInfo
	p_parse := pwi_nfo.pParse
	db := p_parse.db
	p_new := &WhereLoop(0)
	p_term := &WhereTerm(0)
	op_mask := 0
	scan := WhereScan{}
	saved_prereq := Bitmask(0)
	saved_n_lt_erm := U16(0)
	saved_n_eq := U16(0)
	saved_n_btm := U16(0)
	saved_n_top := U16(0)
	saved_n_skip := U16(0)
	saved_ws_flags := u32(0)
	saved_n_out := LogEst(0)
	rc := 0
	r_size := LogEst(0)
	r_log_size := LogEst(0)
	p_top := unsafe { &WhereTerm(nil) }
	p_btm := unsafe { &WhereTerm(nil) }

	p_new = p_builder.pNew
	if p_parse.nErr {
		return p_parse.rc
	}
	if p_new.wsFlags & u32(32) {
		op_mask = (2 << (57 - 54)) | (2 << (56 - 54))
	} else {
		op_mask = 2 | 1 | (2 << (55 - 54)) | (2 << (58 - 54)) | (2 << (57 - 54)) | (2 << (56 - 54)) | 256 | 128
	}
	if p_probe.bUnordered {
		op_mask &= ~((2 << (55 - 54)) | (2 << (58 - 54)) | (2 << (57 - 54)) | (2 << (56 - 54)))
	}
	saved_n_eq = p_new.u.btree.nEq
	saved_n_btm = p_new.u.btree.nBtm
	saved_n_top = p_new.u.btree.nTop
	saved_n_skip = p_new.nSkip
	saved_n_lt_erm = p_new.nLTerm
	saved_ws_flags = p_new.wsFlags
	saved_prereq = p_new.prereq
	saved_n_out = p_new.nOut
	p_term = where_scan_init(&scan, p_builder.pWC, p_src.iCursor, int(saved_n_eq), u32(op_mask), p_probe)
	p_new.rSetup = LogEst(0)
	r_size = p_probe.aiRowLogEst[0]
	r_log_size = est_log(r_size)
	for ; rc == 0 && usize(p_term) != usize(0); p_term = where_scan_next(&scan) {
		e_op := p_term.eOperator
		r_cost_idx := LogEst(0)
		n_out_unadjusted := LogEst(0)
		n_in := 0
		if (int(e_op) == 256 || (int(p_term.wtFlags) & 128) != 0) && index_column_not_null(p_probe, int(saved_n_eq)) {
			continue
		}
		if p_term.prereqRight & p_new.maskSelf {
			continue
		}
		if int(p_term.wtFlags) & 256 && int(p_term.eOperator) == (2 << (57 - 54)) {
			continue
		}
		if (int(p_src.fg.jointype) & (8 | 64 | 16)) != 0 && !constraint_compatible_with_outer_join(p_term, p_src) {
			continue
		}
		if (int(p_probe.onError) != 0) && int(saved_n_eq) == int(p_probe.nKeyCol) - 1 {
			p_builder.bldFlags1 |= 2
		} else {
			p_builder.bldFlags1 |= 1
		}
		p_new.wsFlags = saved_ws_flags
		p_new.u.btree.nEq = saved_n_eq
		p_new.u.btree.nBtm = saved_n_btm
		p_new.u.btree.nTop = saved_n_top
		p_new.nLTerm = saved_n_lt_erm
		if int(p_new.nLTerm) >= int(p_new.nLSlot) && where_loop_resize(db, p_new, int(p_new.nLTerm) + 1) {
			break
		}
		p_new.aLTerm[p_new.nLTerm++] = p_term
		p_new.prereq = (saved_prereq | p_term.prereqRight) & ~p_new.maskSelf
		if int(e_op) & 1 {
			p_expr := p_term.pExpr
			if ((p_expr.flags & u32(4096)) != u32(0)) {
				i := 0
				b_redundant := 0
				n_in = 46
				for i = 0; i < int(p_new.nLTerm) - 1; i++ {
					if !isnil(p_new.aLTerm[i]) && usize(p_new.aLTerm[i].pExpr) == usize(p_expr) {
						n_in = 0
						if p_new.aLTerm[i].u.x.iField == p_term.u.x.iField {
							b_redundant = 1
						}
					}
				}
				if b_redundant {
					p_new.nLTerm--
					continue
				}
			} else if (!isnil(p_expr.x.pList) && p_expr.x.pList.nExpr) {
				n_in = int(sqlite3_log_est(U64(p_expr.x.pList.nExpr)))
			}
			if int(p_probe.hasStat1) && int(r_log_size) >= 10 {
				m := LogEst(0)
				log_k := LogEst(0)
				x := LogEst(0)

				m = p_probe.aiRowLogEst[saved_n_eq]
				log_k = est_log(LogEst(n_in))
				x = LogEst(int(m) + int(log_k) + 10 - (n_in + int(r_log_size)))
				if int(x) >= 0 {
				} else if int(n_in_mul) < 2 && ((db.dbOptFlags & u32(131072)) == u32(0)) {
					p_new.wsFlags |= u32(1048576)
				} else {
					continue
				}
			}
			p_new.wsFlags |= u32(4)
		} else if int(e_op) & (2 | 128) {
			i_col := int(p_probe.aiColumn[saved_n_eq])
			p_new.wsFlags |= u32(1)
			if i_col == (-1) || (i_col >= 0 && int(n_in_mul) == 0 && int(saved_n_eq) == int(p_probe.nKeyCol) - 1) {
				if i_col == (-1) || int(p_probe.uniqNotNull) || (int(p_probe.nKeyCol) == 1 && int(p_probe.onError) && (int(e_op) & 2)) {
					p_new.wsFlags |= u32(4096)
				} else {
					p_new.wsFlags |= u32(65536)
				}
			}
			if int(scan.iEquiv) > 1 {
				p_new.wsFlags |= u32(2097152)
			}
		} else if int(e_op) & 256 {
			p_new.wsFlags |= u32(8)
		} else {
			n_vec_len := where_range_vector_len(p_parse, p_src.iCursor, p_probe, int(saved_n_eq), p_term)
			if int(e_op) & ((2 << (55 - 54)) | (2 << (58 - 54))) {
				p_new.wsFlags |= u32(2 | 32)
				p_new.u.btree.nBtm = U16(n_vec_len)
				p_btm = p_term
				p_top = 0
				if int(p_term.wtFlags) & 256 {
					p_top = unsafe { p_term + 1 }
					if where_loop_resize(db, p_new, int(p_new.nLTerm) + 1) {
						break
					}
					p_new.aLTerm[p_new.nLTerm++] = p_top
					p_new.wsFlags |= u32(16)
					p_new.u.btree.nTop = U16(1)
				}
			} else {
				p_new.wsFlags |= u32(2 | 16)
				p_new.u.btree.nTop = U16(n_vec_len)
				p_top = p_term
				p_btm = unsafe { if (p_new.wsFlags & u32(32)) != u32(0) {
					p_new.aLTerm[int(p_new.nLTerm) - 2]
				} else {
					&WhereTerm(nil)
				} }
			}
		}
		if p_new.wsFlags & u32(2) {
			where_range_scan_est(p_parse, p_builder, p_btm, p_top, p_new)
		} else {
			n_eq := int(c2v_prefix_add(unsafe { &p_new.u.btree.nEq }, u16(1)))
			if int(p_term.truthProb) <= 0 && int(p_probe.aiColumn[saved_n_eq]) >= 0 {
				p_new.nOut += int(p_term.truthProb)
				p_new.nOut -= n_in
			} else {
				p_new.nOut += (int(p_probe.aiRowLogEst[n_eq]) - int(p_probe.aiRowLogEst[n_eq - 1]))
				if int(e_op) & 256 {
					p_new.nOut += 10
				}
			}
		}
		if int(p_probe.idxType) == 3 {
			r_cost_idx = LogEst(int(p_new.nOut) + 16)
		} else {
			r_cost_idx = LogEst(int(p_new.nOut) + 1 + (15 * int(p_probe.szIdxRow)) / int(p_src.pSTab.szTabRow))
		}
		r_cost_idx = sqlite3_log_est_add(r_log_size, r_cost_idx)
		p_new.rRun = r_cost_idx
		if (p_new.wsFlags & u32((64 | 256 | 67108864))) == u32(0) {
			p_new.rRun = sqlite3_log_est_add(p_new.rRun, LogEst(int(p_new.nOut) + 16))
		}
		n_out_unadjusted = p_new.nOut
		p_new.rRun += int(n_in_mul) + n_in
		p_new.nOut += int(n_in_mul) + n_in
		where_loop_output_adjust(p_builder.pWC, p_new, r_size)
		if p_src.fg.fromExists {
			p_new.nOut = LogEst(0)
		}
		rc = where_loop_insert(p_builder, p_new)
		if p_new.wsFlags & u32(2) {
			p_new.nOut = saved_n_out
		} else {
			p_new.nOut = n_out_unadjusted
		}
		if (p_new.wsFlags & u32(16)) == u32(0) && int(p_new.u.btree.nEq) < int(p_probe.nColumn) && (int(p_new.u.btree.nEq) < int(p_probe.nKeyCol) || int(p_probe.idxType) != 2) {
			if int(p_new.u.btree.nEq) > 3 {
				sqlite3_progress_check(p_parse)
			}
			where_loop_add_btree_index(p_builder, p_src, p_probe, LogEst(int(n_in_mul) + n_in))
		}
		p_new.nOut = saved_n_out
	}
	p_new.prereq = saved_prereq
	p_new.u.btree.nEq = saved_n_eq
	p_new.u.btree.nBtm = saved_n_btm
	p_new.u.btree.nTop = saved_n_top
	p_new.nSkip = saved_n_skip
	p_new.wsFlags = saved_ws_flags
	p_new.nOut = saved_n_out
	p_new.nLTerm = saved_n_lt_erm
	mut __c2v_condition_109 := false
	mut __c2v_condition_110 := false
	__c2v_condition_110 = int(saved_n_eq) == int(saved_n_skip)
	if __c2v_condition_110 {
		__c2v_condition_110 = int(saved_n_eq) + 1 < int(p_probe.nKeyCol)
	}
	if __c2v_condition_110 {
		__c2v_condition_110 = int(saved_n_eq) == int(p_new.nLTerm)
	}
	if __c2v_condition_110 {
		__c2v_condition_110 = int(p_probe.noSkipScan) == 0
	}
	if __c2v_condition_110 {
		__c2v_condition_110 = int(p_probe.hasStat1) != 0
	}
	if __c2v_condition_110 {
		__c2v_condition_110 = ((db.dbOptFlags & u32(16384)) == u32(0))
	}
	if __c2v_condition_110 {
		__c2v_condition_110 = int(p_probe.aiRowLogEst[int(saved_n_eq) + 1]) >= 42
	}
	if __c2v_condition_110 {
		__c2v_condition_110 = int(p_src.fg.fromExists) == 0
	}
	if __c2v_condition_110 {
		__c2v_condition_110 = c2v_assign[int](unsafe { &rc }, int(where_loop_resize(db, p_new, int(p_new.nLTerm) + 1))) == 0
	}
	__c2v_condition_109 = __c2v_condition_110
	if __c2v_condition_109 {
		n_iter := LogEst(0)
		p_new.u.btree.nEq++
		p_new.nSkip++
		p_new.aLTerm[p_new.nLTerm++] = 0
		p_new.wsFlags |= u32(32768)
		n_iter = LogEst(int(p_probe.aiRowLogEst[saved_n_eq]) - int(p_probe.aiRowLogEst[int(saved_n_eq) + 1]))
		p_new.nOut -= int(n_iter)
		n_iter += 5
		where_loop_add_btree_index(p_builder, p_src, p_probe, LogEst(int(n_iter) + int(n_in_mul)))
		p_new.nOut = saved_n_out
		p_new.u.btree.nEq = saved_n_eq
		p_new.nSkip = saved_n_skip
		p_new.wsFlags = saved_ws_flags
	}
	return rc
}

@[c:'indexMightHelpWithOrderBy']
fn index_might_help_with_order_by(p_builder &WhereLoopBuilder, p_index &Index, i_cursor int) int {
	pob := &ExprList(0)
	a_col_expr := &ExprList(0)
	ii := 0
	jj := 0

	if p_index.bUnordered {
		return 0
	}
	pob = p_builder.pWInfo.pOrderBy
	if usize(pob) == usize(0) {
		return 0
	}
	for ii = 0; ii < pob.nExpr; ii++ {
		p_expr := sqlite3_expr_skip_collate_and_likely(c2v_at(&pob.a[0], isize(ii)).pExpr)
		if (usize(p_expr) == usize(0)) {
			continue
		}
		if (int(p_expr.op) == 168 || int(p_expr.op) == 170) && p_expr.iTable == i_cursor {
			if int(p_expr.iColumn) < 0 {
				return 1
			}
			for jj = 0; jj < int(p_index.nKeyCol); jj++ {
				if int(p_expr.iColumn) == int(p_index.aiColumn[jj]) {
					return 1
				}
			}
		} else {
			a_col_expr = p_index.aColExpr
			if usize(a_col_expr) != usize(0) {
				for jj = 0; jj < int(p_index.nKeyCol); jj++ {
					if int(p_index.aiColumn[jj]) != (-2) {
						continue
					}
					if sqlite3_expr_compare_skip(p_expr, c2v_at(&a_col_expr.a[0], isize(jj)).pExpr, i_cursor) == 0 {
						return 1
					}
				}
			}
		}
	}
	return 0
}

@[c:'whereUsablePartialIndex']
fn where_usable_partial_index(i_tab int, jointype U8, pwc &WhereClause, p_where &Expr) int {
	i := 0
	p_term := &WhereTerm(0)
	p_parse := &Parse(0)
	if int(jointype) & 64 {
		return 0
	}
	p_parse = pwc.pWInfo.pParse
	for int(p_where.op) == 44 {
		if !where_usable_partial_index(i_tab, jointype, pwc, p_where.pLeft) {
			return 0
		}
		p_where = p_where.pRight
	}
	i = 0
	for p_term = pwc.a; i < pwc.nTerm; i++ {
		p_expr := &Expr(0)
		p_expr = p_term.pExpr
		mut __c2v_condition_111 := false
		mut __c2v_condition_112 := false
		__c2v_condition_112 = (!((p_expr.flags & u32(1)) != u32(0)) || p_expr.w.iJoin == i_tab)
		if __c2v_condition_112 {
			__c2v_condition_112 = ((int(jointype) & 32) == 0 || ((p_expr.flags & u32(1)) != u32(0)))
		}
		if __c2v_condition_112 {
			__c2v_condition_112 = sqlite3_expr_implies_expr(p_parse, p_expr, p_where, i_tab)
		}
		if __c2v_condition_112 {
			__c2v_condition_112 = !sqlite3_expr_implies_expr(p_parse, p_expr, p_where, -1)
		}
		if __c2v_condition_112 {
			__c2v_condition_112 = (int(p_term.wtFlags) & 128) == 0
		}
		__c2v_condition_111 = __c2v_condition_112
		if __c2v_condition_111 {
			return 1
		}
		c2v_pointer_postfix(voidptr(&p_term), p_term, isize(1))
	}
	return 0
}

@[c:'exprIsCoveredByIndex']
fn expr_is_covered_by_index(p_expr &Expr, p_idx &Index, i_tab_cur int) int {
	i := 0
	for i = 0; i < int(p_idx.nColumn); i++ {
		if int(p_idx.aiColumn[i]) == (-2) && sqlite3_expr_compare(unsafe { nil }, p_expr, c2v_at(&p_idx.aColExpr.a[0], isize(i)).pExpr, i_tab_cur) == 0 {
			return 1
		}
	}
	return 0
}

struct CoveringIndexCheck {
	pIdx    &Index
	iTabCur int
	bExpr   U8
	bUnidx  U8
}

@[c:'whereIsCoveringIndexWalkCallback']
fn where_is_covering_index_walk_callback(p_walk &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	i := 0
	p_idx := &Index(0)
	ai_column := &I16(0)
	n_column := U16(0)
	p_ck := &CoveringIndexCheck(0)
	p_ck = p_walk.u.pCovIdxCk
	p_idx = p_ck.pIdx
	if (int(p_expr.op) == 168 || int(p_expr.op) == 170) {
		if p_expr.iTable != p_ck.iTabCur {
			return 0
		}
		p_idx = p_walk.u.pCovIdxCk.pIdx
		ai_column = p_idx.aiColumn
		n_column = p_idx.nColumn
		for i = 0; i < int(n_column); i++ {
			if int(ai_column[i]) == int(p_expr.iColumn) {
				return 0
			}
		}
		p_ck.bUnidx = U8(1)
		return 2
	} else if int(p_idx.bHasExpr) && expr_is_covered_by_index(p_expr, p_idx, p_walk.u.pCovIdxCk.iTabCur) {
		p_ck.bExpr = U8(1)
		return 1
	}
	return 0
}

@[c:'whereIsCoveringIndex']
fn where_is_covering_index(pwi_nfo &WhereInfo, p_idx &Index, i_tab_cur int) u32 {
	i := 0
	rc := 0

	ck := CoveringIndexCheck{}
	w := Walker{}
	if usize(pwi_nfo.pSelect) == usize(0) {
		return u32(0)
	}
	if int(p_idx.bHasExpr) == 0 {
		for i = 0; i < int(p_idx.nColumn); i++ {
			if int(p_idx.aiColumn[i]) >= (int((sizeof(Bitmask) * u64(8)))) - 1 {
				break
			}
		}
		if i >= int(p_idx.nColumn) {
			return u32(0)
		}
	}
	ck.pIdx = p_idx
	ck.iTabCur = i_tab_cur
	ck.bExpr = U8(0)
	ck.bUnidx = U8(0)
	C.memset(voidptr(&w), 0, sizeof(w))
	w.xExprCallback = where_is_covering_index_walk_callback
	w.xSelectCallback = sqlite3_select_walk_noop
	w.u.pCovIdxCk = &ck
	sqlite3_walk_select(&w, pwi_nfo.pSelect)
	if ck.bUnidx {
		rc = 0
	} else if ck.bExpr {
		rc = 67108864
	} else {
		rc = 64
	}
	return u32(rc)
}

@[c:'whereIndexedExprCleanup']
fn where_indexed_expr_cleanup(db &Sqlite3, p_object voidptr) {
	c2v_gc_register_thread()
	pp := &&IndexedExpr(p_object)
	for usize((unsafe { *pp })) != usize(0) {
		p := (unsafe { *pp })
		unsafe { *pp = p.pIENext }
		sqlite3_expr_delete(db, p.pExpr)
		sqlite3_db_free_nn(db, voidptr(p))
	}
}

@[c:'wherePartIdxExpr']
fn where_part_idx_expr(p_parse &Parse, p_idx &Index, p_part &Expr, p_mask &Bitmask, i_idx_cur int, p_item &SrcItem) {
	if int(p_part.op) == 44 {
		where_part_idx_expr(p_parse, p_idx, p_part.pRight, p_mask, i_idx_cur, p_item)
		p_part = p_part.pLeft
	}
	if (int(p_part.op) == 54 || int(p_part.op) == 45) {
		p_left := p_part.pLeft
		p_right := p_part.pRight
		aff := U8(0)
		if int(p_left.op) != 168 {
			return
		}
		if !sqlite3_expr_is_constant(unsafe { nil }, p_right) {
			return
		}
		if !sqlite3_is_binary(sqlite3_expr_compare_coll_seq(p_parse, p_part)) {
			return
		}
		if int(p_left.iColumn) < 0 {
			return
		}
		aff = U8(p_idx.pTable.aCol[p_left.iColumn].affinity)
		if int(aff) >= 66 {
			if p_item {
				db := p_parse.db
				p := &IndexedExpr(sqlite3_db_malloc_raw(db, U64(sizeof(IndexedExpr))))
				if p {
					b_null_row := int((int(p_item.fg.jointype) & (8 | 64)) != 0)
					p.pExpr = sqlite3_expr_dup(db, p_right, 0)
					p.iDataCur = p_item.iCursor
					p.iIdxCur = i_idx_cur
					p.iIdxCol = int(p_left.iColumn)
					p.bMaybeNullRow = U8(b_null_row)
					p.pIENext = p_parse.pIdxPartExpr
					p.aff = aff
					p_parse.pIdxPartExpr = p
					if usize(p.pIENext) == usize(0) {
						p_arg := voidptr(&p_parse.pIdxPartExpr)
						sqlite3_parser_add_cleanup(p_parse, where_indexed_expr_cleanup, voidptr(p_arg))
					}
				}
			} else if int(p_left.iColumn) < ((int((sizeof(Bitmask) * u64(8)))) - 1) {
				unsafe { *p_mask &= ~(Bitmask(1) << int(p_left.iColumn)) }
			}
		}
	}
}

@[c:'whereLoopAddBtree']
fn where_loop_add_btree(p_builder &WhereLoopBuilder, m_prereq Bitmask) int {
	pwi_nfo := &WhereInfo(0)
	p_probe := &Index(0)
	s_pk := Index{}
	ai_row_est_pk := [2]LogEst{}
	ai_column_pk := I16(-1)
	p_tab_list := &SrcList(0)
	p_src := &SrcItem(0)
	p_new := &WhereLoop(0)
	rc := 0
	i_sort_idx := 1
	b := 0
	r_size := LogEst(0)
	pwc := &WhereClause(0)
	p_tab := &Table(0)
	p_new = p_builder.pNew
	pwi_nfo = p_builder.pWInfo
	p_tab_list = pwi_nfo.pTabList
	p_src = unsafe { &p_tab_list.a[0] } + int(p_new.iTab)
	p_tab = p_src.pSTab
	pwc = p_builder.pWC
	if p_src.fg.isIndexedBy {
		p_probe = p_src.u2.pIBIndex
	} else if !((p_tab.tabFlags & u32(128)) == u32(0)) {
		p_probe = p_tab.pIndex
	} else {
		p_first := &Index(0)
		C.memset(voidptr(&s_pk), 0, sizeof(Index))
		s_pk.nKeyCol = U16(1)
		s_pk.nColumn = U16(1)
		s_pk.aiColumn = &ai_column_pk
		s_pk.aiRowLogEst = unsafe { &ai_row_est_pk[0] }
		s_pk.onError = U8(5)
		s_pk.pTable = p_tab
		s_pk.szIdxRow = LogEst(3)
		s_pk.idxType = u32(3)
		ai_row_est_pk[0] = p_tab.nRowLogEst
		ai_row_est_pk[1] = LogEst(0)
		p_first = p_src.pSTab.pIndex
		if int(p_src.fg.notIndexed) == 0 {
			s_pk.pNext = p_first
		}
		p_probe = &s_pk
	}
	r_size = p_tab.nRowLogEst
	mut __c2v_condition_113 := false
	mut __c2v_condition_114 := false
	__c2v_condition_114 = isnil(p_builder.pOrSet)
	if __c2v_condition_114 {
		__c2v_condition_114 = (int(pwi_nfo.wctrlFlags) & (4096 | 32)) == 0
	}
	if __c2v_condition_114 {
		__c2v_condition_114 = (pwi_nfo.pParse.db.flags & U64(32768)) != U64(0)
	}
	if __c2v_condition_114 {
		__c2v_condition_114 = !p_src.fg.isIndexedBy
	}
	if __c2v_condition_114 {
		__c2v_condition_114 = !p_src.fg.notIndexed
	}
	if __c2v_condition_114 {
		__c2v_condition_114 = !p_src.fg.isCorrelated
	}
	if __c2v_condition_114 {
		__c2v_condition_114 = !p_src.fg.isRecursive
	}
	if __c2v_condition_114 {
		__c2v_condition_114 = (int(p_src.fg.jointype) & 16) == 0
	}
	__c2v_condition_113 = __c2v_condition_114
	if __c2v_condition_113 {
		r_log_size := LogEst(0)
		p_term := &WhereTerm(0)
		pwc_end := pwc.a + pwc.nTerm
		r_log_size = est_log(r_size)
		for p_term = pwc.a; rc == 0 && usize(p_term) < usize(pwc_end); p_term = unsafe { p_term + 1 } {
			if p_term.prereqRight & p_new.maskSelf {
				continue
			}
			if term_can_drive_index(p_term, p_src, Bitmask(0)) {
				p_new.u.btree.nEq = U16(1)
				p_new.nSkip = U16(0)
				p_new.u.btree.pIndex = 0
				p_new.nLTerm = U16(1)
				p_new.aLTerm[0] = p_term
				p_new.rSetup = LogEst(int(r_log_size) + int(r_size))
				if !(int(p_tab.eTabType) == 2) && (p_tab.tabFlags & u32(16384)) == u32(0) {
					p_new.rSetup += 28
				} else {
					p_new.rSetup -= 25
				}
				if int(p_new.rSetup) < 0 {
					p_new.rSetup = LogEst(0)
				}
				p_new.nOut = LogEst(43)
				p_new.rRun = sqlite3_log_est_add(r_log_size, p_new.nOut)
				p_new.wsFlags = u32(16384)
				p_new.prereq = m_prereq | p_term.prereqRight
				rc = where_loop_insert(p_builder, p_new)
			}
		}
	}

	for rc == 0 && !isnil(p_probe) {
		if usize(p_probe.pPartIdxWhere) != usize(0) && !where_usable_partial_index(p_src.iCursor, p_src.fg.jointype, pwc, p_probe.pPartIdxWhere) {
			unsafe { goto c2v_for_next_198
			 }
		}
		if p_probe.bNoQuery {
			unsafe { goto c2v_for_next_198
			 }
		}
		r_size = p_probe.aiRowLogEst[0]
		p_new.u.btree.nEq = U16(0)
		p_new.u.btree.nBtm = U16(0)
		p_new.u.btree.nTop = U16(0)
		p_new.u.btree.nDistinctCol = U16(0)
		p_new.nSkip = U16(0)
		p_new.nLTerm = U16(0)
		p_new.iSortIdx = U8(0)
		p_new.rSetup = LogEst(0)
		p_new.prereq = m_prereq
		p_new.nOut = r_size
		p_new.u.btree.pIndex = p_probe
		p_new.u.btree.pOrderBy = 0
		b = index_might_help_with_order_by(p_builder, p_probe, p_src.iCursor)
		if int(p_probe.idxType) == 3 {
			p_new.wsFlags = u32(256)
			p_new.iSortIdx = U8(if b { i_sort_idx } else { 0 })
			p_new.rRun = LogEst(int(r_size) + 16)
			where_loop_output_adjust(pwc, p_new, r_size)
			if p_src.fg.isSubquery {
				if p_src.fg.viaCoroutine {
					p_new.wsFlags |= u32(33554432)
				}
				if (p_src.u4.pSubq.pSelect.selFlags & u32(8192)) == u32(0) {
					p_new.u.btree.pOrderBy = p_src.u4.pSubq.pSelect.pOrderBy
				}
			} else if p_src.fg.fromExists {
				p_new.nOut = LogEst(0)
			}
			rc = where_loop_insert(p_builder, p_new)
			p_new.nOut = r_size
			if rc {
				break
			}
		} else {
			m := Bitmask(0)
			if p_probe.isCovering {
				m = Bitmask(0)
				p_new.wsFlags = u32(64 | 512)
			} else {
				m = p_src.colUsed & p_probe.colNotIdxed
				if p_probe.pPartIdxWhere {
					where_part_idx_expr(pwi_nfo.pParse, p_probe, p_probe.pPartIdxWhere, &m, 0, unsafe { nil })
				}
				p_new.wsFlags = u32(512)
				if m == ((Bitmask(1)) << ((int((sizeof(Bitmask) * u64(8)))) - 1)) || (int(p_probe.bHasExpr) && !p_probe.bHasVCol && m != Bitmask(0)) {
					is_cov := where_is_covering_index(pwi_nfo, p_probe, p_src.iCursor)
					if is_cov == u32(0) {
					} else {
						m = Bitmask(0)
						p_new.wsFlags |= is_cov
						if is_cov & u32(64) {
						} else {
						}
					}
				} else if m == Bitmask(0) && (((p_tab.tabFlags & u32(128)) == u32(0)) || usize(pwi_nfo.pSelect) != usize(0) || sqlite3_fault_sim(700)) {
					p_new.wsFlags = u32(64 | 512)
				}
			}
			mut __c2v_condition_115 := false
			mut __c2v_condition_116 := false
			__c2v_condition_116 = b
			__c2v_condition_115 = __c2v_condition_116
			if !__c2v_condition_115 {
				mut __c2v_condition_117 := false
				__c2v_condition_117 = !((p_tab.tabFlags & u32(128)) == u32(0))
				__c2v_condition_115 = __c2v_condition_117
			}
			if !__c2v_condition_115 {
				mut __c2v_condition_118 := false
				__c2v_condition_118 = usize(p_probe.pPartIdxWhere) != usize(0)
				__c2v_condition_115 = __c2v_condition_118
			}
			if !__c2v_condition_115 {
				mut __c2v_condition_119 := false
				__c2v_condition_119 = int(p_src.fg.isIndexedBy)
				__c2v_condition_115 = __c2v_condition_119
			}
			if !__c2v_condition_115 {
				mut __c2v_condition_120 := false
				__c2v_condition_120 = (m == Bitmask(0) && int(p_probe.bUnordered) == 0 && (int(p_probe.szIdxRow) < int(p_tab.szTabRow)) && (int(pwi_nfo.wctrlFlags) & 4) == 0 && int(sqlite3Config.bUseCis) && ((pwi_nfo.pParse.db.dbOptFlags & u32(32)) == u32(0)))
				__c2v_condition_115 = __c2v_condition_120
			}
			if __c2v_condition_115 {
				p_new.iSortIdx = U8(if b { i_sort_idx } else { 0 })
				p_new.rRun = LogEst(int(r_size) + 1 + (15 * int(p_probe.szIdxRow)) / int(p_tab.szTabRow))
				if m != Bitmask(0) {
					n_lookup := LogEst(int(r_size) + 16)
					ii := 0
					i_cur := p_src.iCursor
					pwc_2 := &pwi_nfo.sWC
					for ii = 0; ii < pwc_2.nTerm; ii++ {
						p_term := unsafe { pwc_2.a + ii }
						if !sqlite3_expr_covered_by_index(p_term.pExpr, i_cur, p_probe) {
							break
						}
						if int(p_term.truthProb) <= 0 {
							n_lookup += int(p_term.truthProb)
						} else {
							n_lookup--
							if int(p_term.eOperator) & (2 | 128) {
								n_lookup -= 19
							}
						}
					}
					p_new.rRun = sqlite3_log_est_add(p_new.rRun, n_lookup)
				}
				where_loop_output_adjust(pwc, p_new, r_size)
				if (int(p_src.fg.jointype) & 16) != 0 && !isnil(p_probe.aColExpr) {
				} else {
					if p_src.fg.fromExists {
						p_new.nOut = LogEst(0)
					}
					rc = where_loop_insert(p_builder, p_new)
				}
				p_new.nOut = r_size
				if rc {
					break
				}
			}
		}
		p_builder.bldFlags1 = u8(0)
		rc = where_loop_add_btree_index(p_builder, p_src, p_probe, LogEst(0))
		if int(p_builder.bldFlags1) == 1 {
			p_tab.tabFlags |= u32(256)
		}
		c2v_for_next_198:
		p_probe = (unsafe { if int(p_src.fg.isIndexedBy) { &Index(nil) } else { p_probe.pNext } })
		i_sort_idx++
	}
	return rc
}

@[c:'isLimitTerm']
fn is_limit_term(p_term &WhereTerm) int {
	return int(p_term.eMatchOp >= 73 && int(p_term.eMatchOp) <= 74)
}

@[c:'allConstraintsUsed']
fn all_constraints_used(a_usage &Sqlite3_index_constraint_usage, n_cons int) int {
	ii := 0
	for ii = 0; ii < n_cons; ii++ {
		if a_usage[ii].argvIndex <= 0 {
			return 0
		}
	}
	return 1
}

@[c:'whereLoopAddVirtualOne']
fn where_loop_add_virtual_one(p_builder &WhereLoopBuilder, m_prereq Bitmask, m_usable Bitmask, m_exclude U16, p_idx_info &Sqlite3_index_info, m_no_omit U16, pb_in &int, pb_retry_limit &int) int {
	pwc := p_builder.pWC
	p_hidden := &HiddenIndexInfo(voidptr(unsafe { p_idx_info + 1 }))
	p_idx_cons := &Sqlite3_index_constraint(0)
	p_usage := p_idx_info.aConstraintUsage
	i := 0
	mx_term := 0
	rc := 0
	p_new := p_builder.pNew
	p_parse := p_builder.pWInfo.pParse
	p_src := unsafe { &p_builder.pWInfo.pTabList.a[0] + p_new.iTab }
	n_constraint := p_idx_info.nConstraint
	unsafe { *pb_in = 0 }
	p_new.prereq = m_prereq
	p_idx_cons = unsafe { *&&Sqlite3_index_constraint(&p_idx_info.aConstraint) }
	for i = 0; i < n_constraint; i++ {
		p_term := term_from_where_clause(pwc, p_idx_cons.iTermOffset)
		p_idx_cons.usable = u8(0)
		if (p_term.prereqRight & m_usable) == p_term.prereqRight && (int(p_term.eOperator) & int(m_exclude)) == 0 && (!isnil(pb_retry_limit) || !is_limit_term(p_term)) {
			p_idx_cons.usable = u8(1)
		}
		c2v_pointer_postfix(voidptr(&p_idx_cons), p_idx_cons, isize(1))
	}
	C.memset(voidptr(p_usage), 0, sizeof(Sqlite3_index_constraint_usage) * u64(n_constraint))
	p_idx_info.idxStr = 0
	p_idx_info.idxNum = 0
	p_idx_info.orderByConsumed = 0
	p_idx_info.estimatedCost = 9.9999999999999997E+98 / f64(2)
	p_idx_info.estimatedRows = Sqlite3_int64(25)
	p_idx_info.idxFlags = 0
	p_hidden.mHandleIn = u32(0)
	rc = vtab_best_index(p_parse, p_src.pSTab, p_idx_info)
	if rc {
		if rc == 19 {
			free_idx_str(p_idx_info)
			return 0
		}
		return rc
	}
	mx_term = -1
	C.memset(voidptr(p_new.aLTerm), 0, sizeof(&WhereTerm) * u64(n_constraint))
	C.memset(voidptr(&p_new.u.vtab), 0, sizeof(WhereLoop_u_vtab))
	p_idx_cons = unsafe { *&&Sqlite3_index_constraint(&p_idx_info.aConstraint) }
	for i = 0; i < n_constraint; i++ {
		i_term := 0
		i_term = p_usage[i].argvIndex - 1
		if i_term >= 0 {
			p_term := &WhereTerm(0)
			j := p_idx_cons.iTermOffset
			mut __c2v_condition_121 := false
			mut __c2v_condition_122 := false
			__c2v_condition_122 = i_term >= n_constraint
			__c2v_condition_121 = __c2v_condition_122
			if !__c2v_condition_121 {
				mut __c2v_condition_123 := false
				__c2v_condition_123 = j < 0
				__c2v_condition_121 = __c2v_condition_123
			}
			if !__c2v_condition_121 {
				mut __c2v_condition_124 := false
				__c2v_condition_124 = usize(c2v_assign[&WhereTerm](unsafe { &p_term }, term_from_where_clause(pwc, j))) == usize(0)
				__c2v_condition_121 = __c2v_condition_124
			}
			if !__c2v_condition_121 {
				mut __c2v_condition_125 := false
				__c2v_condition_125 = usize(p_new.aLTerm[i_term]) != usize(0)
				__c2v_condition_121 = __c2v_condition_125
			}
			if !__c2v_condition_121 {
				mut __c2v_condition_126 := false
				__c2v_condition_126 = int(p_idx_cons.usable) == 0
				__c2v_condition_121 = __c2v_condition_126
			}
			if __c2v_condition_121 {
				sqlite3_error_msg(p_parse, c'%s.xBestIndex malfunction', voidptr(p_src.pSTab.zName))
				free_idx_str(p_idx_info)
				return 1
			}
			p_new.prereq |= p_term.prereqRight
			p_new.aLTerm[i_term] = p_term
			if i_term > mx_term {
				mx_term = i_term
			}
			if p_usage[i].omit {
				if i < 16 && ((1 << i) & int(m_no_omit)) == 0 {
					p_new.u.vtab.omitMask |= 1 << i_term
				} else {
				}
				if int(p_term.eMatchOp) == 74 {
					p_new.u.vtab.bOmitOffset = u32(1)
				}
			}
			if (if i <= 31 { (u32(1)) << i } else { u32(0) }) & p_hidden.mHandleIn {
				p_new.u.vtab.mHandleIn |= ((u32(1)) << i_term)
			} else if (int(p_term.eOperator) & 1) != 0 {
				p_idx_info.orderByConsumed = 0
				p_idx_info.idxFlags &= ~1
				unsafe { *pb_in = 1 }
			}
			if is_limit_term(p_term) && ((unsafe { *pb_in }) || !all_constraints_used(p_usage, i)) {
				free_idx_str(p_idx_info)
				unsafe { *pb_retry_limit = 1 }
				return 0
			}
		}
		c2v_pointer_postfix(voidptr(&p_idx_cons), p_idx_cons, isize(1))
	}
	p_new.nLTerm = U16(mx_term + 1)
	for i = 0; i <= mx_term; i++ {
		if usize(p_new.aLTerm[i]) == usize(0) {
			sqlite3_error_msg(p_parse, c'%s.xBestIndex malfunction', voidptr(p_src.pSTab.zName))
			free_idx_str(p_idx_info)
			return 1
		}
	}
	p_new.u.vtab.idxNum = p_idx_info.idxNum
	p_new.u.vtab.needFree = u32(p_idx_info.needToFreeIdxStr)
	p_idx_info.needToFreeIdxStr = 0
	p_new.u.vtab.idxStr = p_idx_info.idxStr
	p_new.u.vtab.isOrdered = I8((if p_idx_info.orderByConsumed { p_idx_info.nOrderBy } else { 0 }))
	p_new.u.vtab.bIdxNumHex = u32((p_idx_info.idxFlags & 2) != 0)
	p_new.rSetup = LogEst(0)
	p_new.rRun = sqlite3_log_est_from_double(p_idx_info.estimatedCost)
	p_new.nOut = sqlite3_log_est(U64(p_idx_info.estimatedRows))
	if p_idx_info.idxFlags & 1 {
		p_new.wsFlags |= u32(4096)
	} else {
		p_new.wsFlags &= u32(~4096)
	}
	rc = where_loop_insert(p_builder, p_new)
	if p_new.u.vtab.needFree {
		sqlite3_free(voidptr(p_new.u.vtab.idxStr))
		p_new.u.vtab.needFree = u32(0)
	}
	return rc
}

fn sqlite3_vtab_collation(p_idx_info &Sqlite3_index_info, i_cons int) &i8 {
	c2v_gc_register_thread()
	p_hidden := &HiddenIndexInfo(voidptr(unsafe { p_idx_info + 1 }))
	z_ret := unsafe { &i8(nil) }
	if i_cons >= 0 && i_cons < p_idx_info.nConstraint {
		pc := unsafe { &CollSeq(nil) }
		i_term := p_idx_info.aConstraint[i_cons].iTermOffset
		px := term_from_where_clause(p_hidden.pWC, i_term).pExpr
		if px.pLeft {
			pc = sqlite3_expr_compare_coll_seq(p_hidden.pParse, px)
		}
		z_ret = (if pc { pc.zName } else { &sqlite3StrBINARY[0] })
	}
	return z_ret
}

fn sqlite3_vtab_in(p_idx_info &Sqlite3_index_info, i_cons int, b_handle int) int {
	c2v_gc_register_thread()
	p_hidden := &HiddenIndexInfo(voidptr(unsafe { p_idx_info + 1 }))
	m := (if i_cons <= 31 { (u32(1)) << i_cons } else { u32(0) })
	if m & p_hidden.mIn {
		if b_handle == 0 {
			p_hidden.mHandleIn &= ~m
		} else if b_handle > 0 {
			p_hidden.mHandleIn |= m
		}
		return 1
	}
	return 0
}

fn sqlite3_vtab_rhs_value(p_idx_info &Sqlite3_index_info, i_cons int, pp_val &&Sqlite3_value) int {
	c2v_gc_register_thread()
	ph := &HiddenIndexInfo(voidptr(unsafe { p_idx_info + 1 }))
	p_val := unsafe { &Sqlite3_value(nil) }
	rc := 0
	if i_cons < 0 || i_cons >= p_idx_info.nConstraint {
		rc = sqlite3_misuse_error(4603)
	} else {
		if usize((&ph.aRhs[0])[i_cons]) == usize(0) {
			p_term := term_from_where_clause(ph.pWC, p_idx_info.aConstraint[i_cons].iTermOffset)
			rc = sqlite3_value_from_expr(ph.pParse.db, p_term.pExpr.pRight, ph.pParse.db.enc, U8(65), &&Sqlite3_value(unsafe { &ph.aRhs[0] + i_cons }))
		}
		p_val = (&ph.aRhs[0])[i_cons]
	}
	unsafe { *pp_val = p_val }
	if rc == 0 && usize(p_val) == usize(0) {
		rc = 12
	}
	return rc
}

fn sqlite3_vtab_distinct(p_idx_info &Sqlite3_index_info) int {
	c2v_gc_register_thread()
	p_hidden := &HiddenIndexInfo(voidptr(unsafe { p_idx_info + 1 }))
	return p_hidden.eDistinct
}

@[c:'sqlite3VtabUsesAllSchemas']
fn sqlite3_vtab_uses_all_schemas(p_parse &Parse) {
	n_db := p_parse.db.nDb
	i := 0
	for i = 0; i < n_db; i++ {
		sqlite3_code_verify_schema(p_parse, i)
	}
	if (p_parse.writeMask != YDbMask(0)) {
		for i = 0; i < n_db; i++ {
			sqlite3_begin_write_operation(p_parse, 0, i)
		}
	}
}

@[c:'whereLoopAddVirtual']
fn where_loop_add_virtual(p_builder &WhereLoopBuilder, m_prereq Bitmask, m_unusable Bitmask) int {
	rc := 0
	pwi_nfo := &WhereInfo(0)
	p_parse := &Parse(0)
	pwc := &WhereClause(0)
	p_src := &SrcItem(0)
	p := &Sqlite3_index_info(0)
	n_constraint := 0
	b_in := 0
	p_new := &WhereLoop(0)
	m_best := Bitmask(0)
	m_no_omit := U16(0)
	b_retry := 0
	pwi_nfo = p_builder.pWInfo
	p_parse = pwi_nfo.pParse
	pwc = p_builder.pWC
	p_new = p_builder.pNew
	p_src = unsafe { &pwi_nfo.pTabList.a[0] + p_new.iTab }
	p = allocate_index_info(pwi_nfo, pwc, m_unusable, p_src, &m_no_omit)
	if usize(p) == usize(0) {
		return 7
	}
	p_new.rSetup = LogEst(0)
	p_new.wsFlags = u32(1024)
	p_new.nLTerm = U16(0)
	p_new.u.vtab.needFree = u32(0)
	n_constraint = p.nConstraint
	if where_loop_resize(p_parse.db, p_new, n_constraint) {
		free_index_info(p_parse.db, p)
		return 7
	}
	rc = where_loop_add_virtual_one(p_builder, m_prereq, (Bitmask(-1)), U16(0), p, m_no_omit, &b_in, &b_retry)
	if b_retry {
		rc = where_loop_add_virtual_one(p_builder, m_prereq, (Bitmask(-1)), U16(0), p, m_no_omit, &b_in, unsafe { nil })
	}
	if rc == 0 && (c2v_assign[u64](unsafe { &m_best }, u64((p_new.prereq & ~m_prereq))) != Bitmask(0) || b_in) {
		seen_zero := 0
		seen_zero_no_in := 0
		m_prev := Bitmask(0)
		m_best_no_in := Bitmask(0)
		if b_in {
			rc = where_loop_add_virtual_one(p_builder, m_prereq, (Bitmask(-1)), U16(1), p, m_no_omit, &b_in, unsafe { nil })
			m_best_no_in = p_new.prereq & ~m_prereq
			if m_best_no_in == Bitmask(0) {
				seen_zero = 1
				seen_zero_no_in = 1
			}
		}
		for rc == 0 {
			i := 0
			m_next := (Bitmask(-1))
			for i = 0; i < n_constraint; i++ {
				i_term := p.aConstraint[i].iTermOffset
				m_this := term_from_where_clause(pwc, i_term).prereqRight & ~m_prereq
				if m_this > m_prev && m_this < m_next {
					m_next = m_this
				}
			}
			m_prev = m_next
			if m_next == (Bitmask(-1)) {
				break
			}
			if m_next == m_best || m_next == m_best_no_in {
				continue
			}
			rc = where_loop_add_virtual_one(p_builder, m_prereq, m_next | m_prereq, U16(0), p, m_no_omit, &b_in, unsafe { nil })
			if p_new.prereq == m_prereq {
				seen_zero = 1
				if b_in == 0 {
					seen_zero_no_in = 1
				}
			}
		}
		if rc == 0 && seen_zero == 0 {
			rc = where_loop_add_virtual_one(p_builder, m_prereq, m_prereq, U16(0), p, m_no_omit, &b_in, unsafe { nil })
			if b_in == 0 {
				seen_zero_no_in = 1
			}
		}
		if rc == 0 && seen_zero_no_in == 0 {
			rc = where_loop_add_virtual_one(p_builder, m_prereq, m_prereq, U16(1), p, m_no_omit, &b_in, unsafe { nil })
		}
	}
	free_index_info(p_parse.db, p)
	return rc
}

@[c:'whereLoopAddOr']
fn where_loop_add_or(p_builder &WhereLoopBuilder, m_prereq Bitmask, m_unusable Bitmask) int {
	pwi_nfo := p_builder.pWInfo
	pwc := &WhereClause(0)
	p_new := &WhereLoop(0)
	p_term := &WhereTerm(0)
	pwc_end := &WhereTerm(0)

	rc := 0
	i_cur := 0
	temp_wc := WhereClause{}
	s_sub_build := WhereLoopBuilder{}
	s_sum := WhereOrSet{}
	s_cur := WhereOrSet{}

	p_item := &SrcItem(0)
	pwc = p_builder.pWC
	pwc_end = pwc.a + pwc.nTerm
	p_new = p_builder.pNew
	C.memset(voidptr(&s_sum), 0, sizeof(s_sum))
	p_item = unsafe { &pwi_nfo.pTabList.a[0] } + int(p_new.iTab)
	i_cur = p_item.iCursor
	if int(p_item.fg.jointype) & 16 {
		return 0
	}
	for p_term = pwc.a; usize(p_term) < usize(pwc_end) && rc == 0; p_term = unsafe { p_term + 1 } {
		if (int(p_term.eOperator) & 512) != 0 && (p_term.u.pOrInfo.indexable & p_new.maskSelf) != Bitmask(0) {
			p_or_wc := &p_term.u.pOrInfo.wc
			p_or_wc_end := unsafe { p_or_wc.a + p_or_wc.nTerm }
			p_or_term := &WhereTerm(0)
			once := 1
			i := 0
			j := 0

			s_sub_build = unsafe { *p_builder }
			s_sub_build.pOrSet = &s_cur
			for p_or_term = p_or_wc.a; usize(p_or_term) < usize(p_or_wc_end); p_or_term = unsafe { p_or_term + 1 } {
				if (int(p_or_term.eOperator) & 1024) != 0 {
					s_sub_build.pWC = &p_or_term.u.pAndInfo.wc
				} else if p_or_term.leftCursor == i_cur {
					temp_wc.pWInfo = pwc.pWInfo
					temp_wc.pOuter = pwc
					temp_wc.op = U8(44)
					temp_wc.nTerm = 1
					temp_wc.nBase = 1
					temp_wc.a = p_or_term
					s_sub_build.pWC = &temp_wc
				} else {
					continue
				}
				s_cur.n = U16(0)
				if (int(p_item.pSTab.eTabType) == 1) {
					rc = where_loop_add_virtual(&s_sub_build, m_prereq, m_unusable)
				} else {
					rc = where_loop_add_btree(&s_sub_build, m_prereq)
				}
				if rc == 0 {
					rc = where_loop_add_or(&s_sub_build, m_prereq, m_unusable)
				}
				if int(s_cur.n) == 0 {
					s_sum.n = U16(0)
					break
				} else if once {
					where_or_move(&s_sum, &s_cur)
					once = 0
				} else {
					s_prev := WhereOrSet{}
					where_or_move(&s_prev, &s_sum)
					s_sum.n = U16(0)
					for i = 0; i < int(s_prev.n); i++ {
						for j = 0; j < int(s_cur.n); j++ {
							where_or_insert(&s_sum, s_prev.a[i].prereq | s_cur.a[j].prereq, sqlite3_log_est_add(s_prev.a[i].rRun, s_cur.a[j].rRun), sqlite3_log_est_add(s_prev.a[i].nOut, s_cur.a[j].nOut))
						}
					}
				}
			}
			p_new.nLTerm = U16(1)
			p_new.aLTerm[0] = p_term
			p_new.wsFlags = u32(8192)
			p_new.rSetup = LogEst(0)
			p_new.iSortIdx = U8(0)
			C.memset(voidptr(&p_new.u), 0, sizeof(WhereLoop_u))
			for i = 0; rc == 0 && i < int(s_sum.n); i++ {
				p_new.rRun = LogEst(int(s_sum.a[i].rRun) + 1)
				p_new.nOut = s_sum.a[i].nOut
				p_new.prereq = s_sum.a[i].prereq
				rc = where_loop_insert(p_builder, p_new)
			}
		}
	}
	return rc
}

@[c:'whereLoopAddAll']
fn where_loop_add_all(p_builder &WhereLoopBuilder) int {
	pwi_nfo := p_builder.pWInfo
	m_prereq := Bitmask(0)
	m_prior := Bitmask(0)
	i_tab := 0
	p_tab_list := pwi_nfo.pTabList
	p_item := &SrcItem(0)
	p_end := unsafe { &p_tab_list.a[0] + pwi_nfo.nLevel }
	db := pwi_nfo.pParse.db
	rc := 0
	b_first_past_rj := 0
	has_right_cross_join := 0
	p_new := &WhereLoop(0)
	p_new = p_builder.pNew
	p_builder.iPlanLimit = u32(20000)
	i_tab = 0
	for p_item = unsafe { &p_tab_list.a[0] }; usize(p_item) < usize(p_end); i_tab++ {
		m_unusable := Bitmask(0)
		p_new.iTab = U8(i_tab)
		p_builder.iPlanLimit += u32(1000)
		p_new.maskSelf = sqlite3_where_get_mask(&pwi_nfo.sMaskSet, p_item.iCursor)
		if b_first_past_rj || (int(p_item.fg.jointype) & (32 | 2 | 64)) != 0 {
			if int(p_item.fg.jointype) & (64 | 2) {
				has_right_cross_join = 1
			}
			m_prereq |= m_prior
			b_first_past_rj = (int(p_item.fg.jointype) & 16) != 0
		} else if p_item.fg.fromExists {
			pwc := &pwi_nfo.sWC
			p_term := &WhereTerm(0)
			i := 0
			i = pwc.nBase
			for p_term = pwc.a; i > 0; i-- {
				if (p_new.maskSelf & p_term.prereqAll) != Bitmask(0) {
					m_prereq |= (p_term.prereqAll & (p_new.maskSelf - Bitmask(1)))
				}
				c2v_pointer_postfix(voidptr(&p_term), p_term, isize(1))
			}
		} else if !has_right_cross_join {
			m_prereq = Bitmask(0)
		}
		if (int(p_item.pSTab.eTabType) == 1) {
			p := &SrcItem(0)
			for p = unsafe { p_item + 1 }; usize(p) < usize(p_end); p = unsafe { p + 1 } {
				if m_unusable || (int(p.fg.jointype) & (32 | 2)) {
					m_unusable |= sqlite3_where_get_mask(&pwi_nfo.sMaskSet, p.iCursor)
				}
			}
			rc = where_loop_add_virtual(p_builder, m_prereq, m_unusable)
		} else {
			rc = where_loop_add_btree(p_builder, m_prereq)
		}
		if rc == 0 && int(p_builder.pWC.hasOr) {
			rc = where_loop_add_or(p_builder, m_prereq, m_unusable)
		}
		m_prior |= p_new.maskSelf
		if rc || int(db.mallocFailed) {
			if rc == 101 {
				sqlite3_log(28, c'abbreviated query algorithm search')
				rc = 0
			} else {
				break
			}
		}
		c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
	}
	where_loop_clear(db, p_new)
	return rc
}

@[c:'wherePathMatchSubqueryOB']
fn where_path_match_subquery_ob(pwi_nfo &WhereInfo, p_loop &WhereLoop, i_loop int, i_cur int, p_order_by &ExprList, p_rev_mask &Bitmask, pob_sat &Bitmask) int {
	iob := 0
	j_sub := 0
	rev := U8(0)
	rev_idx := U8(0)
	pob_expr := &Expr(0)
	p_sub_ob := &ExprList(0)
	p_sub_ob = p_loop.u.btree.pOrderBy
	for iob = 0; (((Bitmask(1)) << iob) & (unsafe { *pob_sat })) != Bitmask(0); iob++ {
	}
	for j_sub = 0; j_sub < p_sub_ob.nExpr && iob < p_order_by.nExpr; j_sub++ {
		if int(c2v_at(&p_sub_ob.a[0], isize(j_sub)).u.x.iOrderByCol) == 0 {
			break
		}
		pob_expr = c2v_at(&p_order_by.a[0], isize(iob)).pExpr
		if int(pob_expr.op) != 168 && int(pob_expr.op) != 170 {
			break
		}
		if pob_expr.iTable != i_cur {
			break
		}
		if int(pob_expr.iColumn) != int(c2v_at(&p_sub_ob.a[0], isize(j_sub)).u.x.iOrderByCol) - 1 {
			break
		}
		if (int(pwi_nfo.wctrlFlags) & 64) == 0 {
			sf_ob := c2v_at(&p_order_by.a[0], isize(iob)).fg.sortFlags
			sf_sub := c2v_at(&p_sub_ob.a[0], isize(j_sub)).fg.sortFlags
			if (int(sf_sub) & 2) != (int(sf_ob) & 2) {
				break
			}
			rev_idx = U8(int(sf_sub) & 1)
			if j_sub > 0 {
				if (int(rev) ^ int(rev_idx)) != (int(sf_ob) & 1) {
					break
				}
			} else {
				rev = U8(int(rev_idx) ^ (int(sf_ob) & 1))
				if rev {
					if (p_loop.wsFlags & u32(33554432)) != u32(0) {
						break
					}
					unsafe { *p_rev_mask |= ((Bitmask(1)) << i_loop) }
				}
			}
		}
		unsafe { *pob_sat |= ((Bitmask(1)) << iob) }
		iob++
	}
	return int(j_sub > 0)
}

@[c:'wherePathSatisfiesOrderBy']
fn where_path_satisfies_order_by(pwi_nfo &WhereInfo, p_order_by &ExprList, p_path &WherePath, wctrl_flags U16, n_loop U16, p_last &WhereLoop, p_rev_mask &Bitmask) I8 {
	rev_set := U8(0)
	rev := U8(0)
	rev_idx := U8(0)
	is_order_distinct := U8(0)
	distinct_columns := U8(0)
	is_match := U8(0)
	eq_op_mask := U16(0)
	n_key_col := U16(0)
	n_column := U16(0)
	n_order_by := U16(0)
	i_loop := 0
	i := 0
	j := 0

	i_cur := 0
	i_column := 0
	p_loop := unsafe { &WhereLoop(nil) }
	p_term := &WhereTerm(0)
	pob_expr := &Expr(0)
	p_coll := &CollSeq(0)
	p_index := &Index(0)
	db := pwi_nfo.pParse.db
	ob_sat := Bitmask(0)
	ob_done := Bitmask(0)
	order_distinct_mask := Bitmask(0)
	ready := Bitmask(0)
	if int(n_loop) && ((db.dbOptFlags & u32(64)) != u32(0)) {
		return I8(0)
	}
	n_order_by = U16(p_order_by.nExpr)
	if int(n_order_by) > (int((sizeof(Bitmask) * u64(8)))) - 1 {
		return I8(0)
	}
	is_order_distinct = U8(1)
	ob_done = ((Bitmask(1)) << int(n_order_by)) - Bitmask(1)
	order_distinct_mask = Bitmask(0)
	ready = Bitmask(0)
	eq_op_mask = U16(2 | 128 | 256)
	if int(wctrl_flags) & (2048 | 2 | 1) {
		eq_op_mask |= 1
	}
	for i_loop = 0; int(is_order_distinct) && ob_sat < ob_done && i_loop <= int(n_loop); i_loop++ {
		if i_loop > 0 {
			ready |= p_loop.maskSelf
		}
		if i_loop < int(n_loop) {
			p_loop = p_path.aLoop[i_loop]
			if int(wctrl_flags) & 2048 {
				continue
			}
		} else {
			p_loop = p_last
		}
		if p_loop.wsFlags & u32(1024) {
			if int(p_loop.u.vtab.isOrdered) && usize(pwi_nfo.pOrderBy) == usize(p_order_by) {
				ob_sat = ob_done
			} else {
				is_order_distinct = U8(0)
			}
			break
		}
		i_cur = c2v_at(&pwi_nfo.pTabList.a[0], isize(p_loop.iTab)).iCursor
		for i = 0; i < int(n_order_by); i++ {
			if ((Bitmask(1)) << i) & ob_sat {
				continue
			}
			pob_expr = sqlite3_expr_skip_collate_and_likely(c2v_at(&p_order_by.a[0], isize(i)).pExpr)
			if (usize(pob_expr) == usize(0)) {
				continue
			}
			if int(pob_expr.op) != 168 && int(pob_expr.op) != 170 {
				continue
			}
			if pob_expr.iTable != i_cur {
				continue
			}
			p_term = sqlite3_where_find_term(&pwi_nfo.sWC, i_cur, int(pob_expr.iColumn), ~ready, u32(eq_op_mask), unsafe { nil })
			if usize(p_term) == usize(0) {
				continue
			}
			if int(p_term.eOperator) == 1 {
				for j = 0; j < int(p_loop.nLTerm) && usize(p_term) != usize(p_loop.aLTerm[j]); j++ {
				}
				if j >= int(p_loop.nLTerm) {
					continue
				}
			}
			if (int(p_term.eOperator) & (2 | 128)) != 0 && int(pob_expr.iColumn) >= 0 {
				p_parse := pwi_nfo.pParse
				p_coll1 := sqlite3_expr_nn_coll_seq(p_parse, c2v_at(&p_order_by.a[0], isize(i)).pExpr)
				p_coll2 := sqlite3_expr_compare_coll_seq(p_parse, p_term.pExpr)
				if usize(p_coll2) == usize(0) || sqlite3_str_ic_mp(p_coll1.zName, p_coll2.zName) {
					continue
				}
			}
			ob_sat |= ((Bitmask(1)) << i)
		}
		if (p_loop.wsFlags & u32(4096)) == u32(0) {
			if p_loop.wsFlags & u32(256) {
				if !isnil(p_loop.u.btree.pOrderBy) && ((db.dbOptFlags & u32(268435456)) == u32(0)) && where_path_match_subquery_ob(pwi_nfo, p_loop, i_loop, i_cur, p_order_by, p_rev_mask, &ob_sat) {
					n_column = U16(0)
					is_order_distinct = U8(0)
				} else {
					n_column = U16(1)
				}
				p_index = 0
				n_key_col = U16(0)
			} else {
				p_index = p_loop.u.btree.pIndex
				if usize(p_index) == usize(0) || int(p_index.bUnordered) {
					return I8(0)
				} else {
					n_key_col = p_index.nKeyCol
					n_column = p_index.nColumn
					is_order_distinct = U8((int(p_index.onError) != 0) && (p_loop.wsFlags & u32(32768)) == u32(0))
				}
			}
			rev_set = U8(0)
			rev = rev_set
			distinct_columns = U8(0)
			for j = 0; j < int(n_column); j++ {
				b_once := U8(1)
				if j < int(p_loop.u.btree.nEq) && j >= int(p_loop.nSkip) {
					e_op := p_loop.aLTerm[j].eOperator
					if (int(e_op) & int(eq_op_mask)) != 0 {
						if int(e_op) & (256 | 128) {
							is_order_distinct = U8(0)
						}
						continue
					} else if (int(e_op) & 1) {
						px := p_loop.aLTerm[j].pExpr
						for i = j + 1; i < int(p_loop.u.btree.nEq); i++ {
							if usize(p_loop.aLTerm[i].pExpr) == usize(px) {
								b_once = U8(0)
								break
							}
						}
					}
				}
				if p_index {
					i_column = int(p_index.aiColumn[j])
					rev_idx = U8(int(p_index.aSortOrder[j]) & 1)
					if i_column == int(p_index.pTable.iPKey) {
						i_column = (-1)
					}
				} else {
					i_column = (-1)
					rev_idx = U8(0)
				}
				if is_order_distinct {
					if i_column >= 0 && j >= int(p_loop.u.btree.nEq) && int(p_index.pTable.aCol[i_column].notNull) == 0 {
						is_order_distinct = U8(0)
					}
					if i_column == (-2) {
						is_order_distinct = U8(0)
					}
				}
				is_match = U8(0)
				for i = 0; int(b_once) && i < int(n_order_by); i++ {
					if ((Bitmask(1)) << i) & ob_sat {
						continue
					}
					pob_expr = sqlite3_expr_skip_collate_and_likely(c2v_at(&p_order_by.a[0], isize(i)).pExpr)
					if (usize(pob_expr) == usize(0)) {
						continue
					}
					if (int(wctrl_flags) & (64 | 128)) == 0 {
						b_once = U8(0)
					}
					if i_column >= (-1) {
						if int(pob_expr.op) != 168 && int(pob_expr.op) != 170 {
							continue
						}
						if pob_expr.iTable != i_cur {
							continue
						}
						if int(pob_expr.iColumn) != i_column {
							continue
						}
					} else {
						p_ix_expr := c2v_at(&p_index.aColExpr.a[0], isize(j)).pExpr
						if sqlite3_expr_compare_skip(pob_expr, p_ix_expr, i_cur) {
							continue
						}
					}
					if i_column != (-1) {
						p_coll = sqlite3_expr_nn_coll_seq(pwi_nfo.pParse, c2v_at(&p_order_by.a[0], isize(i)).pExpr)
						if sqlite3_str_ic_mp(p_coll.zName, p_index.azColl[j]) != 0 {
							continue
						}
					}
					if int(wctrl_flags) & 128 {
						p_loop.u.btree.nDistinctCol = U16(j + 1)
					}
					is_match = U8(1)
					break
				}
				if int(is_match) && (int(wctrl_flags) & 64) == 0 {
					if rev_set {
						if (int(rev) ^ int(rev_idx)) != (int(c2v_at(&p_order_by.a[0], isize(i)).fg.sortFlags) & 1) {
							is_match = U8(0)
						}
					} else {
						rev = U8(int(rev_idx) ^ (int(c2v_at(&p_order_by.a[0], isize(i)).fg.sortFlags) & 1))
						if rev {
							unsafe { *p_rev_mask |= ((Bitmask(1)) << i_loop) }
						}
						rev_set = U8(1)
					}
				}
				if int(is_match) && (int(c2v_at(&p_order_by.a[0], isize(i)).fg.sortFlags) & 2) {
					if j == int(p_loop.u.btree.nEq) {
						p_loop.wsFlags |= u32(524288)
					} else {
						is_match = U8(0)
					}
				}
				if is_match {
					if i_column == (-1) {
						distinct_columns = U8(1)
					}
					ob_sat |= ((Bitmask(1)) << i)
				} else {
					if j == 0 || j < int(n_key_col) {
						is_order_distinct = U8(0)
					}
					break
				}
			}
			if distinct_columns {
				is_order_distinct = U8(1)
			}
		}
		if is_order_distinct {
			order_distinct_mask |= p_loop.maskSelf
			for i = 0; i < int(n_order_by); i++ {
				p := &Expr(0)
				m_term := Bitmask(0)
				if ((Bitmask(1)) << i) & ob_sat {
					continue
				}
				p = c2v_at(&p_order_by.a[0], isize(i)).pExpr
				m_term = sqlite3_where_expr_usage(&pwi_nfo.sMaskSet, p)
				if m_term == Bitmask(0) && !sqlite3_expr_is_constant(unsafe { nil }, p) {
					continue
				}
				if (m_term & ~order_distinct_mask) == Bitmask(0) {
					ob_sat |= ((Bitmask(1)) << i)
				}
			}
		}
	}
	if ob_sat == ob_done {
		return I8(n_order_by)
	}
	if !is_order_distinct {
		for i = int(n_order_by) - 1; i > 0; i-- {
			m := if (i < (int((sizeof(Bitmask) * u64(8))))) {
				((Bitmask(1)) << i) - Bitmask(1)
			} else {
				Bitmask(0)
			}
			if (ob_sat & m) == m {
				return I8(i)
			}
		}
		return I8(0)
	}
	return I8(-1)
}

@[c:'sqlite3WhereIsSorted']
fn sqlite3_where_is_sorted(pwi_nfo &WhereInfo) int {
	return int(pwi_nfo.sorted)
}

@[c:'whereSortingCost']
fn where_sorting_cost(pwi_nfo &WhereInfo, n_row LogEst, n_order_by int, n_sorted int) LogEst {
	r_sort_cost := LogEst(0)
	n_col := LogEst(0)

	n_col = sqlite3_log_est(U64((pwi_nfo.pSelect.pEList.nExpr + 59) / 30))
	r_sort_cost = LogEst(int(n_row) + int(n_col))
	if n_sorted > 0 {
		r_sort_cost += int(sqlite3_log_est(U64((n_order_by - n_sorted) * 100 / n_order_by))) - 66
	}
	if (int(pwi_nfo.wctrlFlags) & 16384) != 0 {
		r_sort_cost += 10
		if n_sorted != 0 {
			r_sort_cost += 6
		}
		if int(pwi_nfo.iLimit) < int(n_row) {
			n_row = pwi_nfo.iLimit
		}
	} else if (int(pwi_nfo.wctrlFlags) & 256) {
		if int(n_row) > 10 {
			n_row -= 10
		}
	}
	r_sort_cost += int(est_log(n_row))
	return r_sort_cost
}

@[c:'computeMxChoice']
fn compute_mx_choice(pwi_nfo &WhereInfo) int {
	n_loop := int(pwi_nfo.nLevel)
	pwl_oop := &WhereLoop(0)
	if n_loop >= 4 && !pwi_nfo.bStarDone && ((pwi_nfo.pParse.db.dbOptFlags & u32(536870912)) == u32(0)) {
		a_from_tabs := &SrcItem(0)
		i_from_idx := 0
		m := Bitmask(0)
		m_self_join := Bitmask(0)
		p_start := &WhereLoop(0)
		pwi_nfo.bStarDone = u32(1)
		a_from_tabs = unsafe { &pwi_nfo.pTabList.a[0] }
		p_start = pwi_nfo.pLoops
		i_from_idx = 0
		for m = Bitmask(1); i_from_idx < n_loop; i_from_idx++ {
			n_dep := 0
			mx_run := LogEst(0)
			m_seen := Bitmask(0)
			p_fact_tab := &SrcItem(0)
			p_fact_tab = a_from_tabs + i_from_idx
			if (int(p_fact_tab.fg.jointype) & (32 | 2)) != 0 {
				if i_from_idx + 3 > n_loop {
					break
				}
				for !isnil(p_start) && int(p_start.iTab) <= i_from_idx {
					p_start = p_start.pNextLoop
				}
			}
			for pwl_oop = p_start; pwl_oop; pwl_oop = pwl_oop.pNextLoop {
				if (int(a_from_tabs[pwl_oop.iTab].fg.jointype) & (32 | 2)) != 0 {
					break
				}
				if (pwl_oop.prereq & m) != Bitmask(0) && (pwl_oop.maskSelf & m_seen) == Bitmask(0) && (pwl_oop.maskSelf & m_self_join) == Bitmask(0) {
					if usize(a_from_tabs[pwl_oop.iTab].pSTab) == usize(p_fact_tab.pSTab) {
						m_self_join |= m
					} else {
						n_dep++
						m_seen |= pwl_oop.maskSelf
					}
				}
			}
			if n_dep <= 2 {
				unsafe { goto c2v_for_next_204
				 }
			}
			pwi_nfo.bStarUsed = u32(1)
			mx_run = LogEst((-32768))
			for pwl_oop = p_start; pwl_oop; pwl_oop = pwl_oop.pNextLoop {
				if int(pwl_oop.iTab) < i_from_idx {
					continue
				}
				if int(pwl_oop.iTab) > i_from_idx {
					break
				}
				if int(pwl_oop.rRun) > int(mx_run) {
					mx_run = pwl_oop.rRun
				}
			}
			if (int(mx_run) < 32767) {
				mx_run++
			}
			for pwl_oop = p_start; pwl_oop; pwl_oop = pwl_oop.pNextLoop {
				if (pwl_oop.maskSelf & m_seen) == Bitmask(0) {
					continue
				}
				if pwl_oop.nLTerm {
					continue
				}
				if int(pwl_oop.rRun) < int(mx_run) {
					pwl_oop.rRun = mx_run
				}
			}
			c2v_for_next_204:
			m <<= 1
		}
	}
	return if int(pwi_nfo.bStarUsed) { 18 } else { 12 }
}

@[c:'whereLoopIsNoBetter']
fn where_loop_is_no_better(p_candidate &WhereLoop, p_baseline &WhereLoop) int {
	if (p_candidate.wsFlags & u32(512)) == u32(0) {
		return 1
	}
	if (p_baseline.wsFlags & u32(512)) == u32(0) {
		return 1
	}
	if int(p_candidate.u.btree.pIndex.szIdxRow) < int(p_baseline.u.btree.pIndex.szIdxRow) {
		return 0
	}
	return 1
}

@[c:'wherePathSolver']
fn where_path_solver(pwi_nfo &WhereInfo, n_row_est LogEst) int {
	mx_choice := 0
	n_loop := 0
	p_parse := &Parse(0)
	i_loop := 0
	ii := 0
	jj := 0

	mx_i := 0
	n_order_by := 0
	mx_cost := LogEst(0)
	mx_unsort := LogEst(0)
	n_to := 0
	n_from := 0

	mut a_from := &WherePath(0)
	a_to := &WherePath(0)
	p_from := &WherePath(0)
	p_to := &WherePath(0)
	pwl_oop := &WhereLoop(0)
	px := &&WhereLoop(0)
	a_sort_cost := unsafe { &LogEst(nil) }
	p_space := &i8(0)
	n_space := 0
	p_parse = pwi_nfo.pParse
	n_loop = int(pwi_nfo.nLevel)
	if n_loop <= 1 {
		mx_choice = 1
	} else if n_loop == 2 {
		mx_choice = 5
	} else if p_parse.nErr {
		mx_choice = 1
	} else {
		mx_choice = compute_mx_choice(pwi_nfo)
	}
	if usize(pwi_nfo.pOrderBy) == usize(0) || int(n_row_est) == 0 {
		n_order_by = 0
	} else {
		n_order_by = pwi_nfo.pOrderBy.nExpr
	}
	n_space = int((sizeof(WherePath) + sizeof(voidptr) * u64(n_loop)) * u64(mx_choice) * u64(2))
	n_space += sizeof(LogEst) * u64(n_order_by)
	p_space = &i8(sqlite3_db_malloc_raw_nn(p_parse.db, U64(n_space)))
	if usize(p_space) == usize(0) {
		return 7
	}
	a_to = &WherePath(voidptr(p_space))
	a_from = a_to + mx_choice
	C.memset(voidptr(a_from), 0, sizeof(WherePath))
	px = &&WhereLoop(voidptr((a_from + mx_choice)))
	ii = mx_choice * 2
	for p_from = a_to; ii > 0; ii-- {
		p_from.aLoop = px
		c2v_pointer_postfix(voidptr(&p_from), p_from, isize(1))
		c2v_pointer_prefix(voidptr(&px), px, isize(n_loop))
	}
	if n_order_by {
		a_sort_cost = &LogEst(voidptr(px))
		C.memset(voidptr(a_sort_cost), 0, sizeof(LogEst) * u64(n_order_by))
	}
	a_from[0].nRow = LogEst((if int(p_parse.nQueryLoop) < 48 { int(p_parse.nQueryLoop) } else { 48 }))
	n_from = 1
	if n_order_by {
		a_from[0].isOrdered = I8(if n_loop > 0 { -1 } else { n_order_by })
	}
	for i_loop = 0; i_loop < n_loop; i_loop++ {
		n_to = 0
		ii = 0
		for p_from = a_from; ii < n_from; ii++ {
			for pwl_oop = pwi_nfo.pLoops; pwl_oop; pwl_oop = pwl_oop.pNextLoop {
				n_out := LogEst(0)
				r_cost := LogEst(0)
				r_unsort := LogEst(0)
				is_ordered := I8(0)
				mask_new := Bitmask(0)
				rev_mask := Bitmask(0)
				if (pwl_oop.prereq & ~p_from.maskLoop) != Bitmask(0) {
					continue
				}
				if (pwl_oop.maskSelf & p_from.maskLoop) != Bitmask(0) {
					continue
				}
				if (pwl_oop.wsFlags & u32(16384)) != u32(0) && int(p_from.nRow) < 3 {
					continue
				}
				r_unsort = LogEst(int(pwl_oop.rRun) + int(p_from.nRow))
				if pwl_oop.rSetup {
					r_unsort = sqlite3_log_est_add(pwl_oop.rSetup, r_unsort)
				}
				r_unsort = sqlite3_log_est_add(r_unsort, p_from.rUnsort)
				n_out = LogEst(int(p_from.nRow) + int(pwl_oop.nOut))
				mask_new = p_from.maskLoop | pwl_oop.maskSelf
				is_ordered = p_from.isOrdered
				if int(is_ordered) < 0 {
					rev_mask = Bitmask(0)
					is_ordered = where_path_satisfies_order_by(pwi_nfo, pwi_nfo.pOrderBy, p_from, pwi_nfo.wctrlFlags, U16(i_loop), pwl_oop, &rev_mask)
				} else {
					rev_mask = p_from.revLoop
				}
				if int(is_ordered) >= 0 && int(is_ordered) < n_order_by {
					if int(a_sort_cost[is_ordered]) == 0 {
						a_sort_cost[is_ordered] = where_sorting_cost(pwi_nfo, n_row_est, n_order_by, int(is_ordered))
					}
					r_cost = LogEst(int(sqlite3_log_est_add(r_unsort, a_sort_cost[is_ordered])) + 3)
				} else {
					r_cost = r_unsort
					r_unsort -= 2
				}
				jj = 0
				for p_to = a_to; jj < n_to; jj++ {
					if p_to.maskLoop == mask_new && (((int(p_to.isOrdered) ^ int(is_ordered)) & 128) == 0 || i_loop == n_loop - 1) {
						break
					}
					c2v_pointer_postfix(voidptr(&p_to), p_to, isize(1))
				}
				if jj >= n_to {
					if n_to >= mx_choice && (int(r_cost) > int(mx_cost) || (int(r_cost) == int(mx_cost) && int(r_unsort) >= int(mx_unsort))) {
						continue
					}
					if n_to < mx_choice {
						mut __c2v_postfix_value_42 := n_to
						n_to++
						jj = __c2v_postfix_value_42
					} else {
						jj = mx_i
					}
					p_to = unsafe { a_to + jj }
				} else {
					mut __c2v_condition_127 := false
					mut __c2v_condition_128 := false
					__c2v_condition_128 = (int(p_to.rCost) < int(r_cost))
					__c2v_condition_127 = __c2v_condition_128
					if !__c2v_condition_127 {
						mut __c2v_condition_129 := false
						__c2v_condition_129 = (int(p_to.rCost) == int(r_cost) && int(p_to.nRow) < int(n_out))
						__c2v_condition_127 = __c2v_condition_129
					}
					if !__c2v_condition_127 {
						mut __c2v_condition_130 := false
						__c2v_condition_130 = (int(p_to.rCost) == int(r_cost) && int(p_to.nRow) == int(n_out) && int(p_to.rUnsort) < int(r_unsort))
						__c2v_condition_127 = __c2v_condition_130
					}
					if !__c2v_condition_127 {
						mut __c2v_condition_131 := false
						__c2v_condition_131 = (int(p_to.rCost) == int(r_cost) && int(p_to.nRow) == int(n_out) && int(p_to.rUnsort) == int(r_unsort) && where_loop_is_no_better(pwl_oop, p_to.aLoop[i_loop]))
						__c2v_condition_127 = __c2v_condition_131
					}
					if __c2v_condition_127 {
						continue
					}
				}
				p_to.maskLoop = p_from.maskLoop | pwl_oop.maskSelf
				p_to.revLoop = rev_mask
				p_to.nRow = n_out
				p_to.rCost = r_cost
				p_to.rUnsort = r_unsort
				p_to.isOrdered = is_ordered
				C.memcpy(voidptr(p_to.aLoop), voidptr(p_from.aLoop), sizeof(voidptr) * u64(i_loop))
				p_to.aLoop[i_loop] = pwl_oop
				if n_to >= mx_choice {
					mx_i = 0
					mx_cost = a_to[0].rCost
					mx_unsort = a_to[0].nRow
					jj = 1
					for p_to = unsafe { a_to + 1 }; jj < mx_choice; jj++ {
						if int(p_to.rCost) > int(mx_cost) || (int(p_to.rCost) == int(mx_cost) && int(p_to.rUnsort) > int(mx_unsort)) {
							mx_cost = p_to.rCost
							mx_unsort = p_to.rUnsort
							mx_i = jj
						}
						c2v_pointer_postfix(voidptr(&p_to), p_to, isize(1))
					}
				}
			}
			c2v_pointer_postfix(voidptr(&p_from), p_from, isize(1))
		}
		p_from = a_to
		a_to = a_from
		a_from = p_from
		n_from = n_to
	}
	if n_from == 0 {
		sqlite3_error_msg(p_parse, c'no query solution')
		sqlite3_db_free_nn(p_parse.db, voidptr(p_space))
		return 1
	}
	p_from = a_from
	for i_loop = 0; i_loop < n_loop; i_loop++ {
		p_level := unsafe { &pwi_nfo.a[0] } + i_loop
		pwl_oop = p_from.aLoop[i_loop]
		p_level.pWLoop = pwl_oop
		p_level.iFrom = pwl_oop.iTab
		p_level.iTabCur = c2v_at(&pwi_nfo.pTabList.a[0], isize(p_level.iFrom)).iCursor
	}
	if (int(pwi_nfo.wctrlFlags) & 256) != 0 && (int(pwi_nfo.wctrlFlags) & 128) == 0 && int(pwi_nfo.eDistinct) == 0 && int(n_row_est) {
		not_used := Bitmask(0)
		rc := int(where_path_satisfies_order_by(pwi_nfo, pwi_nfo.pResultSet, p_from, U16(128), U16(n_loop - 1), p_from.aLoop[n_loop - 1], &not_used))
		if rc == pwi_nfo.pResultSet.nExpr {
			pwi_nfo.eDistinct = U8(2)
		}
	}
	pwi_nfo.bOrderedInnerLoop = u32(0)
	if pwi_nfo.pOrderBy {
		pwi_nfo.nOBSat = p_from.isOrdered
		if int(pwi_nfo.wctrlFlags) & 128 {
			if int(p_from.isOrdered) == pwi_nfo.pOrderBy.nExpr {
				pwi_nfo.eDistinct = U8(2)
			}
		} else {
			pwi_nfo.revMask = p_from.revLoop
			if int(pwi_nfo.nOBSat) <= 0 {
				pwi_nfo.nOBSat = I8(0)
				if n_loop > 0 {
					ws_flags := p_from.aLoop[n_loop - 1].wsFlags
					if (ws_flags & u32(4096)) == u32(0) && (ws_flags & u32((256 | 4))) != u32((256 | 4)) {
						m := Bitmask(0)
						rc := int(where_path_satisfies_order_by(pwi_nfo, pwi_nfo.pOrderBy, p_from, U16(2048), U16(n_loop - 1), p_from.aLoop[n_loop - 1], &m))
						if rc == pwi_nfo.pOrderBy.nExpr {
							pwi_nfo.bOrderedInnerLoop = u32(1)
							pwi_nfo.revMask = m
						}
					}
				}
			} else if n_loop && int(pwi_nfo.nOBSat) == 1 && (int(pwi_nfo.wctrlFlags) & (1 | 2)) != 0 {
				pwi_nfo.bOrderedInnerLoop = u32(1)
			}
		}
		if (int(pwi_nfo.wctrlFlags) & 512) && int(pwi_nfo.nOBSat) == pwi_nfo.pOrderBy.nExpr && n_loop > 0 {
			rev_mask := Bitmask(0)
			n_order := int(where_path_satisfies_order_by(pwi_nfo, pwi_nfo.pOrderBy, p_from, U16(0), U16(n_loop - 1), p_from.aLoop[n_loop - 1], &rev_mask))
			if n_order == pwi_nfo.pOrderBy.nExpr {
				pwi_nfo.sorted = u32(1)
				pwi_nfo.revMask = rev_mask
			}
		}
	}
	pwi_nfo.nRowOut = p_from.nRow
	sqlite3_db_free_nn(p_parse.db, voidptr(p_space))
	return 0
}

@[c:'whereInterstageHeuristic']
fn where_interstage_heuristic(pwi_nfo &WhereInfo) {
	i := 0
	for i = 0; i < int(pwi_nfo.nLevel); i++ {
		p := c2v_at(&pwi_nfo.a[0], isize(i)).pWLoop
		if usize(p) == usize(0) {
			break
		}
		if (p.wsFlags & u32(1024)) != u32(0) {
			break
		}
		if (p.wsFlags & u32((1 | 8 | 4))) != u32(0) {
			i_tab := p.iTab
			p_loop := &WhereLoop(0)
			for p_loop = pwi_nfo.pLoops; p_loop; p_loop = p_loop.pNextLoop {
				if int(p_loop.iTab) != int(i_tab) {
					continue
				}
				if (p_loop.wsFlags & u32((15 | 16384))) != u32(0) {
					continue
				}
				p_loop.prereq = (Bitmask(-1))
			}
		} else {
			break
		}
	}
}

@[c:'whereShortCut']
fn where_short_cut(p_builder &WhereLoopBuilder) int {
	pwi_nfo := &WhereInfo(0)
	p_item := &SrcItem(0)
	pwc := &WhereClause(0)
	p_term := &WhereTerm(0)
	p_loop := &WhereLoop(0)
	i_cur := 0
	j := 0
	p_tab := &Table(0)
	p_idx := &Index(0)
	scan := WhereScan{}
	pwi_nfo = p_builder.pWInfo
	if int(pwi_nfo.wctrlFlags) & 32 {
		return 0
	}
	p_item = unsafe { &pwi_nfo.pTabList.a[0] }
	p_tab = p_item.pSTab
	if (int(p_tab.eTabType) == 1) {
		return 0
	}
	if int(p_item.fg.isIndexedBy) || int(p_item.fg.notIndexed) {
		return 0
	}
	i_cur = p_item.iCursor
	pwc = &pwi_nfo.sWC
	p_loop = p_builder.pNew
	p_loop.wsFlags = u32(0)
	p_loop.nSkip = U16(0)
	p_term = where_scan_init(&scan, pwc, i_cur, -1, u32(2 | 128), unsafe { nil })
	for !isnil(p_term) && p_term.prereqRight {
		p_term = where_scan_next(&scan)
	}
	if p_term {
		p_loop.wsFlags = u32(1 | 256 | 4096)
		p_loop.aLTerm[0] = p_term
		p_loop.nLTerm = U16(1)
		p_loop.u.btree.nEq = U16(1)
		p_loop.rRun = LogEst(33)
	} else {
		for p_idx = p_tab.pIndex; p_idx; p_idx = p_idx.pNext {
			op_mask := 0
			if !(int(p_idx.onError) != 0) || usize(p_idx.pPartIdxWhere) != usize(0) || int(p_idx.nKeyCol) > 3 {
				continue
			}
			op_mask = if int(p_idx.uniqNotNull) { (2 | 128) } else { 2 }
			for j = 0; j < int(p_idx.nKeyCol); j++ {
				p_term = where_scan_init(&scan, pwc, i_cur, j, u32(op_mask), p_idx)
				for !isnil(p_term) && p_term.prereqRight {
					p_term = where_scan_next(&scan)
				}
				if usize(p_term) == usize(0) {
					break
				}
				p_loop.aLTerm[j] = p_term
			}
			if j != int(p_idx.nKeyCol) {
				continue
			}
			p_loop.wsFlags = u32(1 | 4096 | 512)
			if int(p_idx.isCovering) || (p_item.colUsed & p_idx.colNotIdxed) == Bitmask(0) {
				p_loop.wsFlags |= u32(64)
			}
			p_loop.nLTerm = U16(j)
			p_loop.u.btree.nEq = U16(j)
			p_loop.u.btree.pIndex = p_idx
			p_loop.rRun = LogEst(39)
			break
		}
	}
	if p_loop.wsFlags {
		p_loop.nOut = LogEst(1)
		mut __c2v_lhs_tmp_168 := c2v_at(&pwi_nfo.a[0], isize(0))
		__c2v_lhs_tmp_168.pWLoop = p_loop
		p_loop.maskSelf = Bitmask(1)
		mut __c2v_lhs_tmp_169 := c2v_at(&pwi_nfo.a[0], isize(0))
		__c2v_lhs_tmp_169.iTabCur = i_cur
		pwi_nfo.nRowOut = LogEst(1)
		if pwi_nfo.pOrderBy {
			pwi_nfo.nOBSat = I8(pwi_nfo.pOrderBy.nExpr)
		}
		if int(pwi_nfo.wctrlFlags) & 256 {
			pwi_nfo.eDistinct = U8(1)
		}
		if int(scan.iEquiv) > 1 {
			p_loop.wsFlags |= u32(2097152)
		}
		return 1
	}
	return 0
}

@[c:'exprNodeIsDeterministic']
fn expr_node_is_deterministic(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	if int(p_expr.op) == 172 && ((p_expr.flags & u32(1048576)) != u32(0)) == 0 {
		p_walker.eCode = U16(0)
		return 2
	}
	return 0
}

@[c:'exprIsDeterministic']
fn expr_is_deterministic(p &Expr) int {
	w := Walker{}
	C.memset(voidptr(&w), 0, sizeof(w))
	w.eCode = U16(1)
	w.xExprCallback = expr_node_is_deterministic
	w.xSelectCallback = sqlite3_select_walk_fail
	sqlite3_walk_expr(&w, p)
	return int(w.eCode)
}

@[c:'whereOmitNoopJoin']
fn where_omit_noop_join(pwi_nfo &WhereInfo, not_ready Bitmask) Bitmask {
	i := 0
	tab_used := Bitmask(0)
	has_right_join := 0
	tab_used = sqlite3_where_expr_list_usage(&pwi_nfo.sMaskSet, pwi_nfo.pResultSet)
	if pwi_nfo.pOrderBy {
		tab_used |= sqlite3_where_expr_list_usage(&pwi_nfo.sMaskSet, pwi_nfo.pOrderBy)
	}
	has_right_join = (int(c2v_at(&pwi_nfo.pTabList.a[0], isize(0)).fg.jointype) & 64) != 0
	for i = int(pwi_nfo.nLevel) - 1; i >= 1; i-- {
		p_term := &WhereTerm(0)
		p_end := &WhereTerm(0)

		p_item := &SrcItem(0)
		p_loop := &WhereLoop(0)
		m1 := Bitmask(0)
		p_loop = c2v_at(&pwi_nfo.a[0], isize(i)).pWLoop
		p_item = unsafe { &pwi_nfo.pTabList.a[0] + p_loop.iTab }
		if (int(p_item.fg.jointype) & (8 | 16)) != 8 {
			continue
		}
		if (int(pwi_nfo.wctrlFlags) & 256) == 0 && (p_loop.wsFlags & u32(4096)) == u32(0) {
			continue
		}
		if (tab_used & p_loop.maskSelf) != Bitmask(0) {
			continue
		}
		p_end = pwi_nfo.sWC.a + pwi_nfo.sWC.nTerm
		for p_term = pwi_nfo.sWC.a; usize(p_term) < usize(p_end); p_term = unsafe { p_term + 1 } {
			if (p_term.prereqAll & p_loop.maskSelf) != Bitmask(0) {
				if !((p_term.pExpr.flags & u32(1)) != u32(0)) || p_term.pExpr.w.iJoin != p_item.iCursor {
					break
				}
			}
			if has_right_join && ((p_term.pExpr.flags & u32(2)) != u32(0)) && (p_term.pExpr.w.iJoin == p_item.iCursor) {
				break
			}
		}
		if usize(p_term) < usize(p_end) {
			continue
		}
		m1 = ((Bitmask(1)) << i) - Bitmask(1)
		pwi_nfo.revMask = (m1 & pwi_nfo.revMask) | ((pwi_nfo.revMask >> 1) & ~m1)
		not_ready &= ~p_loop.maskSelf
		for p_term = pwi_nfo.sWC.a; usize(p_term) < usize(p_end); p_term = unsafe { p_term + 1 } {
			if (p_term.prereqAll & p_loop.maskSelf) != Bitmask(0) {
				p_term.wtFlags |= 4
				p_term.prereqAll = Bitmask(0)
			}
		}
		if i != int(pwi_nfo.nLevel) - 1 {
			n_byte := int(u64((int(pwi_nfo.nLevel) - 1 - i)) * sizeof(WhereLevel))
			C.memmove(voidptr(unsafe { &pwi_nfo.a[0] + i }), voidptr(unsafe { &pwi_nfo.a[0] + (i + 1) }), u64(n_byte))
		}
		pwi_nfo.nLevel--
	}
	return not_ready
}

@[c:'whereCheckIfBloomFilterIsUseful']
fn where_check_if_bloom_filter_is_useful(pwi_nfo &WhereInfo) {
	i := 0
	n_search := LogEst(0)
	for i = 0; i < int(pwi_nfo.nLevel); i++ {
		p_loop := c2v_at(&pwi_nfo.a[0], isize(i)).pWLoop
		req_flags := u32((8388608 | 1))
		p_item := unsafe { &pwi_nfo.pTabList.a[0] + p_loop.iTab }
		p_tab := p_item.pSTab
		if (p_tab.tabFlags & u32(16)) == u32(0) {
			break
		}
		p_tab.tabFlags |= u32(256)
		if i >= 1 && (p_loop.wsFlags & req_flags) == req_flags && ((p_loop.wsFlags & u32((256 | 512))) != u32(0)) {
			if int(n_search) > int(p_tab.nRowLogEst) {
				p_loop.wsFlags |= u32(4194304)
				p_loop.wsFlags &= u32(~64)
			}
		}
		n_search += int(p_loop.nOut)
	}
}

@[c:'whereAddIndexedExpr']
fn where_add_indexed_expr(p_parse &Parse, p_idx &Index, i_idx_cur int, p_tab_item &SrcItem) {
	i := 0
	p := &IndexedExpr(0)
	p_tab := &Table(0)
	p_tab = p_idx.pTable
	for i = 0; i < int(p_idx.nColumn); i++ {
		p_expr := &Expr(0)
		j := int(p_idx.aiColumn[i])
		if j == (-2) {
			p_expr = c2v_at(&p_idx.aColExpr.a[0], isize(i)).pExpr
		} else if j >= 0 && (int(p_tab.aCol[j].colFlags) & 32) != 0 {
			p_expr = sqlite3_column_expr(p_tab, unsafe { p_tab.aCol + j })
		} else {
			continue
		}
		if sqlite3_expr_is_constant(unsafe { nil }, p_expr) {
			continue
		}
		p = sqlite3_db_malloc_raw(p_parse.db, U64(sizeof(IndexedExpr)))
		if usize(p) == usize(0) {
			break
		}
		p.pIENext = p_parse.pIdxEpr
		p.pExpr = sqlite3_expr_dup(p_parse.db, p_expr, 0)
		p.iDataCur = p_tab_item.iCursor
		p.iIdxCur = i_idx_cur
		p.iIdxCol = i
		p.bMaybeNullRow = U8((int(p_tab_item.fg.jointype) & (8 | 64 | 16)) != 0)
		if sqlite3_index_affinity_str(p_parse.db, p_idx) {
			p.aff = U8(p_idx.zColAff[i])
		}
		p_parse.pIdxEpr = p
		if usize(p.pIENext) == usize(0) {
			p_arg := voidptr(&p_parse.pIdxEpr)
			sqlite3_parser_add_cleanup(p_parse, where_indexed_expr_cleanup, voidptr(p_arg))
		}
	}
}

@[c:'whereReverseScanOrder']
fn where_reverse_scan_order(pwi_nfo &WhereInfo) {
	ii := 0
	for ii = 0; ii < pwi_nfo.pTabList.nSrc; ii++ {
		p_item := unsafe { &pwi_nfo.pTabList.a[0] + ii }
		if !p_item.fg.isCte || int(p_item.u2.pCteUse.eM10d) != 0 || (int(p_item.fg.isSubquery) == 0) || usize(p_item.u4.pSubq.pSelect.pOrderBy) == usize(0) {
			pwi_nfo.revMask |= ((Bitmask(1)) << ii)
		}
	}
}

@[c:'sqlite3WhereBegin']
fn sqlite3_where_begin(p_parse &Parse, p_tab_list &SrcList, p_where &Expr, p_order_by &ExprList, p_result_set &ExprList, p_select &Select, wctrl_flags U16, i_aux_arg int) &WhereInfo {
	n_byte_wi_nfo := 0
	n_tab_list := 0
	pwi_nfo := &WhereInfo(0)
	v := p_parse.pVdbe
	not_ready := Bitmask(0)
	swlb := WhereLoopBuilder{}
	p_mask_set := &WhereMaskSet(0)
	p_level := &WhereLevel(0)
	p_loop := &WhereLoop(0)
	ii := 0
	db := &Sqlite3(0)
	rc := 0
	b_fordelete := U8(0)
	db = p_parse.db
	C.memset(voidptr(&swlb), 0, sizeof(swlb))
	if !isnil(p_order_by) && p_order_by.nExpr >= (int((sizeof(Bitmask) * u64(8)))) {
		p_order_by = 0
		wctrl_flags &= ~256
		wctrl_flags |= 8192
	}
	if p_tab_list.nSrc > (int((sizeof(Bitmask) * u64(8)))) {
		sqlite3_error_msg(p_parse, c'at most %d tables in a join', (int((sizeof(Bitmask) * u64(8)))))
		return unsafe { nil }
	}
	n_tab_list = if (int(wctrl_flags) & 32) { 1 } else { p_tab_list.nSrc }
	n_byte_wi_nfo = int(((((u64(usize(__offsetof(WhereInfo, a)))) + u64(n_tab_list) * sizeof(WhereLevel)) + u64(7)) & u64(~7)))
	pwi_nfo = sqlite3_db_malloc_raw_nn(db, U64(u64(n_byte_wi_nfo) + sizeof(WhereLoop)))
	if db.mallocFailed {
		sqlite3_db_free(db, voidptr(pwi_nfo))
		pwi_nfo = 0
		unsafe { goto whereBeginError
		 }
	}
	pwi_nfo.pParse = p_parse
	pwi_nfo.pTabList = p_tab_list
	pwi_nfo.pOrderBy = p_order_by
	pwi_nfo.pResultSet = p_result_set
	pwi_nfo.aiCurOnePass[1] = -1
	pwi_nfo.aiCurOnePass[0] = pwi_nfo.aiCurOnePass[1]
	pwi_nfo.nLevel = U8(n_tab_list)
	pwi_nfo.iContinue = sqlite3_vdbe_make_label(p_parse)
	pwi_nfo.iBreak = pwi_nfo.iContinue
	pwi_nfo.wctrlFlags = wctrl_flags
	pwi_nfo.iLimit = LogEst(i_aux_arg)
	pwi_nfo.savedNQueryLoop = int(p_parse.nQueryLoop)
	pwi_nfo.pSelect = p_select
	C.memset(voidptr(&pwi_nfo.nOBSat), 0, (u64(usize(__offsetof(WhereInfo, sWC)))) - (u64(usize(__offsetof(WhereInfo, nOBSat)))))
	C.memset(voidptr(unsafe { &pwi_nfo.a[0] + 0 }), 0, sizeof(WhereLoop) + u64(n_tab_list) * sizeof(WhereLevel))
	p_mask_set = &pwi_nfo.sMaskSet
	p_mask_set.n = 0
	p_mask_set.ix[0] = -99
	swlb.pWInfo = pwi_nfo
	swlb.pWC = &pwi_nfo.sWC
	swlb.pNew = &WhereLoop(voidptr(((&i8(voidptr(pwi_nfo))) + n_byte_wi_nfo)))
	where_loop_init(swlb.pNew)
	sqlite3_where_clause_init(&pwi_nfo.sWC, pwi_nfo)
	sqlite3_where_split(&pwi_nfo.sWC, p_where, U8(44))
	if n_tab_list == 0 {
		if p_order_by {
			pwi_nfo.nOBSat = I8(p_order_by.nExpr)
		}
		if (int(wctrl_flags) & 256) != 0 && ((db.dbOptFlags & u32(16)) == u32(0)) {
			pwi_nfo.eDistinct = U8(1)
		}
		if !isnil(pwi_nfo.pSelect) && (pwi_nfo.pSelect.selFlags & u32(1024)) == u32(0) {
			sqlite3_vdbe_explain(p_parse, U8(0), c'SCAN CONSTANT ROW')
		}
	} else {
		ii = 0
		for {
			create_mask(p_mask_set, c2v_at(&p_tab_list.a[0], isize(ii)).iCursor)
			sqlite3_where_tab_func_args(p_parse, unsafe { &p_tab_list.a[0] + ii }, &pwi_nfo.sWC)
			ii++
			if !(ii < p_tab_list.nSrc) {
				break
			}
		}
	}
	sqlite3_where_expr_analyze(p_tab_list, &pwi_nfo.sWC)
	if !isnil(p_select) && !isnil(p_select.pLimit) {
		sqlite3_where_add_limit(&pwi_nfo.sWC, p_select)
	}
	if p_parse.nErr {
		unsafe { goto whereBeginError
		 }
	}
	for ii = 0; ii < swlb.pWC.nBase; ii++ {
		pt := unsafe { swlb.pWC.a + ii }
		px := &Expr(0)
		if int(pt.wtFlags) & 2 {
			continue
		}
		px = pt.pExpr
		if pt.prereqAll == Bitmask(0) && (n_tab_list == 0 || expr_is_deterministic(px)) && !(((px.flags & u32(2)) != u32(0)) && (int(c2v_at(&p_tab_list.a[0], isize(0)).fg.jointype) & 64) != 0) {
			sqlite3_expr_if_false(p_parse, px, pwi_nfo.iBreak, 16)
			pt.wtFlags |= 4
		}
	}
	if int(wctrl_flags) & 256 {
		if ((db.dbOptFlags & u32(16)) != u32(0)) {
			wctrl_flags &= ~256
			pwi_nfo.wctrlFlags &= ~256
		} else if is_distinct_redundant(p_parse, p_tab_list, &pwi_nfo.sWC, p_result_set) {
			pwi_nfo.eDistinct = U8(1)
		} else if usize(p_order_by) == usize(0) {
			pwi_nfo.wctrlFlags |= 128
			pwi_nfo.pOrderBy = p_result_set
		}
	}
	if n_tab_list != 1 || where_short_cut(&swlb) == 0 {
		rc = where_loop_add_all(&swlb)
		if rc {
			unsafe { goto whereBeginError
			 }
		}
		where_path_solver(pwi_nfo, LogEst(0))
		if db.mallocFailed {
			unsafe { goto whereBeginError
			 }
		}
		if pwi_nfo.pOrderBy {
			where_interstage_heuristic(pwi_nfo)
			where_path_solver(pwi_nfo, LogEst(if int(pwi_nfo.nRowOut) < 0 {
				1
			} else {
				int(pwi_nfo.nRowOut) + 1
			}))
			if db.mallocFailed {
				unsafe { goto whereBeginError
				 }
			}
		}
		if (int(pwi_nfo.wctrlFlags) & 256) != 0 {
			pwi_nfo.nRowOut -= 30
		}
	}
	if usize(pwi_nfo.pOrderBy) == usize(0) && (db.flags & U64(4096)) != U64(0) {
		where_reverse_scan_order(pwi_nfo)
	}
	if p_parse.nErr {
		unsafe { goto whereBeginError
		 }
	}
	not_ready = ~Bitmask(0)
	if int(pwi_nfo.nLevel) >= 2 && usize(p_result_set) != usize(0) && 0 == (int(wctrl_flags) & (1024 | 8192)) && ((db.dbOptFlags & u32(256)) == u32(0)) {
		not_ready = where_omit_noop_join(pwi_nfo, not_ready)
		n_tab_list = int(pwi_nfo.nLevel)
	}
	if int(pwi_nfo.nLevel) >= 2 && ((db.dbOptFlags & u32(524288)) == u32(0)) {
		where_check_if_bloom_filter_is_useful(pwi_nfo)
	}
	pwi_nfo.pParse.nQueryLoop += int(pwi_nfo.nRowOut)
	if (int(wctrl_flags) & 4) != 0 {
		ws_flags := int(c2v_at(&pwi_nfo.a[0], isize(0)).pWLoop.wsFlags)
		b_onerow := int((ws_flags & 4096) != 0)
		mut __c2v_condition_132 := false
		mut __c2v_condition_133 := false
		__c2v_condition_133 = b_onerow
		__c2v_condition_132 = __c2v_condition_133
		if !__c2v_condition_132 {
			mut __c2v_condition_134 := false
			__c2v_condition_134 = (0 != (int(wctrl_flags) & 8) && !(int(c2v_at(&p_tab_list.a[0], isize(0)).pSTab.eTabType) == 1) && (0 == (ws_flags & 8192) || (int(wctrl_flags) & 16)) && ((db.dbOptFlags & u32(134217728)) == u32(0)))
			__c2v_condition_132 = __c2v_condition_134
		}
		if __c2v_condition_132 {
			pwi_nfo.eOnePass = U8(if b_onerow { 1 } else { 2 })
			if ((c2v_at(&p_tab_list.a[0], isize(0)).pSTab.tabFlags & u32(128)) == u32(0)) && (ws_flags & 64) {
				if int(wctrl_flags) & 8 {
					b_fordelete = U8(8)
				}
				mut __c2v_lhs_tmp_170 := c2v_at(&pwi_nfo.a[0], isize(0))
				__c2v_lhs_tmp_170.pWLoop.wsFlags = u32((ws_flags & ~64))
			}
		}
	}
	ii = 0
	for p_level = unsafe { &pwi_nfo.a[0] }; ii < n_tab_list; ii++ {
		p_tab := &Table(0)
		i_db := 0
		p_tab_item := &SrcItem(0)
		p_tab_item = unsafe { &p_tab_list.a[0] + p_level.iFrom }
		p_tab = p_tab_item.pSTab
		i_db = sqlite3_schema_to_index(db, p_tab.pSchema)
		p_loop = p_level.pWLoop
		p_level.addrBrk = sqlite3_vdbe_make_label(p_parse)
		if ii == 0 || (int(p_tab_item[0].fg.jointype) & 8) != 0 {
			p_level.addrHalt = p_level.addrBrk
		} else if c2v_at(&pwi_nfo.a[0], isize(ii - 1)).pRJ {
			p_level.addrHalt = c2v_at(&pwi_nfo.a[0], isize(ii - 1)).addrBrk
		} else {
			p_level.addrHalt = c2v_at(&pwi_nfo.a[0], isize(ii - 1)).addrHalt
		}
		if (p_tab.tabFlags & u32(16384)) != u32(0) || (int(p_tab.eTabType) == 2) {
		} else if (p_loop.wsFlags & u32(1024)) != u32(0) {
			pvt_ab := &i8(voidptr(sqlite3_get_vt_able(db, p_tab)))
			i_cur := p_tab_item.iCursor
			sqlite3_vdbe_add_op4(v, 175, i_cur, 0, 0, pvt_ab, (-12))
		} else if (int(p_tab.eTabType) == 1) {
		} else if ((p_loop.wsFlags & u32(64)) == u32(0) && (int(wctrl_flags) & 32) == 0) || (int(p_tab_item.fg.jointype) & (64 | 16)) != 0 {
			op := 114
			if int(pwi_nfo.eOnePass) != 0 {
				op = 116
				pwi_nfo.aiCurOnePass[0] = p_tab_item.iCursor
			}
			sqlite3_open_table(p_parse, p_tab_item.iCursor, i_db, p_tab, op)
			if int(pwi_nfo.eOnePass) == 0 && int(p_tab.nCol) < (int((sizeof(Bitmask) * u64(8)))) && (p_tab.tabFlags & u32((96 | 128))) == u32(0) && (p_loop.wsFlags & u32((16384 | 4194304))) == u32(0) {
				b := p_tab_item.colUsed
				n := 0
				for ; b; b = b >> 1 {
					n++
				}
				sqlite3_vdbe_change_p4(v, -1, &i8((voidptr(i64(n)))), (-3))
			}
			sqlite3_vdbe_change_p5(v, U16(b_fordelete))
			if ii >= 2 && (int(p_tab_item[0].fg.jointype) & (64 | 8)) == 0 && p_level.addrHalt == c2v_at(&pwi_nfo.a[0], isize(0)).addrHalt {
				sqlite3_vdbe_add_op2(v, 37, p_tab_item.iCursor, pwi_nfo.iBreak)
			}
		} else {
			sqlite3_table_lock(p_parse, i_db, p_tab.tnum, U8(0), p_tab.zName)
		}
		if p_loop.wsFlags & u32(512) {
			p_ix := p_loop.u.btree.pIndex
			i_index_cur := 0
			op := 114
			if !((p_tab.tabFlags & u32(128)) == u32(0)) && (int(p_ix.idxType) == 2) && (int(wctrl_flags) & 32) != 0 {
				i_index_cur = p_level.iTabCur
				op = 0
			} else if int(pwi_nfo.eOnePass) != 0 {
				pj := p_tab_item.pSTab.pIndex
				i_index_cur = i_aux_arg
				for !isnil(pj) && usize(pj) != usize(p_ix) {
					i_index_cur++
					pj = pj.pNext
				}
				op = 116
				pwi_nfo.aiCurOnePass[1] = i_index_cur
			} else if i_aux_arg && (int(wctrl_flags) & 32) != 0 {
				i_index_cur = i_aux_arg
				op = 113
			} else {
				mut __c2v_postfix_value_43 := p_parse.nTab
				p_parse.nTab++
				i_index_cur = __c2v_postfix_value_43
				if int(p_ix.bHasExpr) && ((db.dbOptFlags & u32(16777216)) == u32(0)) {
					where_add_indexed_expr(p_parse, p_ix, i_index_cur, p_tab_item)
				}
				if !isnil(p_ix.pPartIdxWhere) && (int(p_tab_item.fg.jointype) & 16) == 0 {
					where_part_idx_expr(p_parse, p_ix, p_ix.pPartIdxWhere, unsafe { nil }, i_index_cur, p_tab_item)
				}
			}
			p_level.iIdxCur = i_index_cur
			if op {
				sqlite3_vdbe_add_op3(v, op, i_index_cur, int(p_ix.tnum), i_db)
				sqlite3_vdbe_set_p4_key_info(p_parse, p_ix)
				mut __c2v_condition_135 := false
				mut __c2v_condition_136 := false
				__c2v_condition_136 = (p_loop.wsFlags & u32(15)) != u32(0)
				if __c2v_condition_136 {
					__c2v_condition_136 = (p_loop.wsFlags & u32((2 | 32768))) == u32(0)
				}
				if __c2v_condition_136 {
					__c2v_condition_136 = (p_loop.wsFlags & u32(524288)) == u32(0)
				}
				if __c2v_condition_136 {
					__c2v_condition_136 = (p_loop.wsFlags & u32(1048576)) == u32(0)
				}
				if __c2v_condition_136 {
					__c2v_condition_136 = (int(pwi_nfo.wctrlFlags) & 1) == 0
				}
				if __c2v_condition_136 {
					__c2v_condition_136 = int(pwi_nfo.eDistinct) != 2
				}
				__c2v_condition_135 = __c2v_condition_136
				if __c2v_condition_135 {
					sqlite3_vdbe_change_p5(v, U16(2))
				}
			}
		}
		if i_db >= 0 {
			sqlite3_code_verify_schema(p_parse, i_db)
		}
		if (int(p_tab_item.fg.jointype) & 16) != 0 && usize(c2v_assign[&WhereRightJoin](unsafe { &p_level.pRJ }, sqlite3_where_malloc(pwi_nfo, U64(sizeof(WhereRightJoin))))) != usize(0) {
			prj := p_level.pRJ
			mut __c2v_postfix_value_44 := p_parse.nTab
			p_parse.nTab++
			prj.iMatch = __c2v_postfix_value_44
			prj.regBloom = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			sqlite3_vdbe_add_op2(v, 79, 65536, prj.regBloom)
			prj.regReturn = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			sqlite3_vdbe_add_op2(v, 77, 0, prj.regReturn)
			if ((p_tab.tabFlags & u32(128)) == u32(0)) {
				p_info := &KeyInfo(0)
				sqlite3_vdbe_add_op2(v, 120, prj.iMatch, 1)
				p_info = sqlite3_key_info_alloc(p_parse.db, 1, 0)
				if p_info {
					(&p_info.aColl[0])[0] = 0
					p_info.aSortFlags[0] = U8(0)
					sqlite3_vdbe_append_p4(v, voidptr(p_info), (-9))
				}
			} else {
				p_pk := sqlite3_primary_key_index(p_tab)
				sqlite3_vdbe_add_op2(v, 120, prj.iMatch, int(p_pk.nKeyCol))
				sqlite3_vdbe_set_p4_key_info(p_parse, p_pk)
			}
			p_loop.wsFlags &= u32(~64)
			pwi_nfo.nOBSat = I8(0)
			pwi_nfo.eDistinct = U8(3)
		}
		c2v_pointer_postfix(voidptr(&p_level), p_level, isize(1))
	}
	pwi_nfo.iTop = sqlite3_vdbe_current_addr(v)
	if db.mallocFailed {
		unsafe { goto whereBeginError
		 }
	}
	for ii = 0; ii < n_tab_list; ii++ {
		addr_explain := 0
		ws_flags := 0
		p_src := &SrcItem(0)
		if p_parse.nErr {
			unsafe { goto whereBeginError
			 }
		}
		p_level = unsafe { &pwi_nfo.a[0] + ii }
		ws_flags = int(p_level.pWLoop.wsFlags)
		p_src = unsafe { &p_tab_list.a[0] + p_level.iFrom }
		if p_src.fg.isMaterialized {
			p_subq := &Subquery(0)
			i_once := 0
			p_subq = p_src.u4.pSubq
			if int(p_src.fg.isCorrelated) == 0 {
				i_once = sqlite3_vdbe_add_op0(v, 15)
			} else {
				i_once = 0
			}
			sqlite3_vdbe_add_op2(v, 10, p_subq.regReturn, p_subq.addrFillSub)
			if i_once {
				sqlite3_vdbe_jump_here(v, i_once)
			}
		}
		if (ws_flags & (16384 | 4194304)) != 0 {
			if (ws_flags & 16384) != 0 {
				construct_automatic_index(p_parse, &pwi_nfo.sWC, not_ready, p_level)
			} else {
				sqlite3_construct_bloom_filter(pwi_nfo, ii, p_level, not_ready)
			}
			if db.mallocFailed {
				unsafe { goto whereBeginError
				 }
			}
		}
		addr_explain = sqlite3_where_explain_one_scan(p_parse, p_tab_list, p_level, wctrl_flags)
		p_level.addrBody = sqlite3_vdbe_current_addr(v)
		not_ready = sqlite3_where_code_one_loop_start(p_parse, v, pwi_nfo, ii, p_level, not_ready)
		pwi_nfo.iContinue = p_level.addrCont
		if (ws_flags & 8192) == 0 && (int(wctrl_flags) & 32) == 0 {
		}
	}
	pwi_nfo.iEndWhere = sqlite3_vdbe_current_addr(v)
	return pwi_nfo
	whereBeginError:
	if pwi_nfo {
		p_parse.nQueryLoop = LogEst(pwi_nfo.savedNQueryLoop)
		where_info_free(db, pwi_nfo)
	}
	return unsafe { nil }
}

@[c:'sqlite3WhereEnd']
fn sqlite3_where_end(pwi_nfo &WhereInfo) {
	p_parse := pwi_nfo.pParse
	v := p_parse.pVdbe
	i := 0
	p_level := &WhereLevel(0)
	p_loop := &WhereLoop(0)
	p_tab_list := pwi_nfo.pTabList
	db := p_parse.db
	i_end := sqlite3_vdbe_current_addr(v)
	nrj := 0
	addr_seek := 0
	for i = int(pwi_nfo.nLevel) - 1; i >= 0; i-- {
		addr := 0
		p_level = unsafe { &pwi_nfo.a[0] + i }
		if p_level.pRJ {
			prj := p_level.pRJ
			sqlite3_vdbe_resolve_label(v, p_level.addrCont)
			p_level.addrCont = sqlite3_vdbe_make_label(p_parse)
			prj.endSubrtn = sqlite3_vdbe_current_addr(v)
			sqlite3_vdbe_add_op3(v, 69, prj.regReturn, prj.addrSubrtn, 1)
			nrj++
		}
		p_loop = p_level.pWLoop
		if int(p_level.op) != 189 {
			p_idx := &Index(0)
			n := 0
			mut __c2v_condition_137 := false
			mut __c2v_condition_138 := false
			__c2v_condition_138 = int(pwi_nfo.eDistinct) == 2
			if __c2v_condition_138 {
				__c2v_condition_138 = i == int(pwi_nfo.nLevel) - 1
			}
			if __c2v_condition_138 {
				__c2v_condition_138 = (p_loop.wsFlags & u32(512)) != u32(0)
			}
			if __c2v_condition_138 {
				__c2v_condition_138 = int(c2v_assign[&Index](unsafe { &p_idx }, p_loop.u.btree.pIndex).hasStat1)
			}
			if __c2v_condition_138 {
				__c2v_condition_138 = c2v_assign[int](unsafe { &n }, int(p_loop.u.btree.nDistinctCol)) > 0
			}
			if __c2v_condition_138 {
				__c2v_condition_138 = int(p_idx.aiRowLogEst[n]) >= 36
			}
			__c2v_condition_137 = __c2v_condition_138
			if __c2v_condition_137 {
				r1 := p_parse.nMem + 1
				j := 0
				op := 0

				addr_if_null := 0
				if p_level.iLeftJoin {
					addr_if_null = sqlite3_vdbe_add_op2(v, 20, p_level.iIdxCur, r1)
				}
				for j = 0; j < n; j++ {
					sqlite3_vdbe_add_op3(v, 96, p_level.iIdxCur, j, r1 + j)
				}
				p_parse.nMem += n + 1
				op = if int(p_level.op) == 39 { 21 } else { 24 }
				addr_seek = sqlite3_vdbe_add_op4_int(v, op, p_level.iIdxCur, 0, r1, n)
				sqlite3_vdbe_add_op2(v, 9, 1, p_level.p2)
				if p_level.iLeftJoin {
					sqlite3_vdbe_jump_here(v, addr_if_null)
				}
			}
		}
		if c2v_at(&p_tab_list.a[0], isize(p_level.iFrom)).fg.fromExists {
			sqlite3_vdbe_add_op2(v, 9, 0, p_level.addrBrk)
		}
		sqlite3_vdbe_resolve_label(v, p_level.addrCont)
		if int(p_level.op) != 189 {
			sqlite3_vdbe_add_op3(v, int(p_level.op), p_level.p1, p_level.p2, int(p_level.p3))
			sqlite3_vdbe_change_p5(v, U16(p_level.p5))
			if p_level.regBignull {
				sqlite3_vdbe_resolve_label(v, p_level.addrBignull)
				sqlite3_vdbe_add_op2(v, 63, p_level.regBignull, p_level.p2 - 1)
			}
			if addr_seek {
				sqlite3_vdbe_jump_here(v, addr_seek)
				addr_seek = 0
			}
		}
		if (p_loop.wsFlags & u32(2048)) != u32(0) && p_level.u.in_.nIn > 0 {
			p_in := &InLoop(0)
			j := 0
			sqlite3_vdbe_resolve_label(v, p_level.addrNxt)
			j = p_level.u.in_.nIn
			for p_in = unsafe { p_level.u.in_.aInLoop + (j - 1) }; j > 0; j-- {
				sqlite3_vdbe_jump_here(v, p_in.addrInTop + 1)
				if int(p_in.eEndLoopOp) != 189 {
					if p_in.nPrefix {
						b_early_out := int((p_loop.wsFlags & u32(1024)) == u32(0) && (p_loop.wsFlags & u32(262144)) != u32(0))
						if p_level.iLeftJoin {
							sqlite3_vdbe_add_op2(v, 25, p_in.iCur, sqlite3_vdbe_current_addr(v) + 2 + b_early_out)
						}
						if b_early_out {
							sqlite3_vdbe_add_op4_int(v, 26, p_level.iIdxCur, sqlite3_vdbe_current_addr(v) + 2, p_in.iBase, p_in.nPrefix)
							sqlite3_vdbe_jump_here(v, p_in.addrInTop + 1)
						}
					}
					sqlite3_vdbe_add_op2(v, int(p_in.eEndLoopOp), p_in.iCur, p_in.addrInTop)
				}
				sqlite3_vdbe_jump_here(v, p_in.addrInTop - 1)
				c2v_pointer_postfix(voidptr(&p_in), p_in, isize(-1))
			}
		}
		sqlite3_vdbe_resolve_label(v, p_level.addrBrk)
		if p_level.pRJ {
			sqlite3_vdbe_add_op3(v, 69, p_level.pRJ.regReturn, 0, 1)
		}
		if p_level.addrSkip {
			sqlite3_vdbe_goto(v, p_level.addrSkip)
			sqlite3_vdbe_jump_here(v, p_level.addrSkip)
			sqlite3_vdbe_jump_here(v, p_level.addrSkip - 2)
		}
		if p_level.addrLikeRep {
			sqlite3_vdbe_add_op2(v, 63, int((p_level.iLikeRepCntr >> 1)), p_level.addrLikeRep)
		}
		if p_level.iLeftJoin {
			ws := int(p_loop.wsFlags)
			addr = sqlite3_vdbe_add_op1(v, 61, p_level.iLeftJoin)
			if (ws & 64) == 0 {
				p_src := unsafe { &p_tab_list.a[0] + p_level.iFrom }
				if p_src.fg.viaCoroutine {
					m := 0
					n := 0

					n = p_src.u4.pSubq.regResult
					m = int(p_src.pSTab.nCol)
					sqlite3_vdbe_add_op3(v, 77, 0, n, n + m - 1)
				}
				sqlite3_vdbe_add_op1(v, 138, p_level.iTabCur)
			}
			if (ws & 512) || ((ws & 8192) && !isnil(p_level.u.pCoveringIdx)) {
				if ws & 8192 {
					p_ix := p_level.u.pCoveringIdx
					i_db := sqlite3_schema_to_index(db, p_ix.pSchema)
					sqlite3_vdbe_add_op3(v, 113, p_level.iIdxCur, int(p_ix.tnum), i_db)
					sqlite3_vdbe_set_p4_key_info(p_parse, p_ix)
				}
				sqlite3_vdbe_add_op1(v, 138, p_level.iIdxCur)
			}
			if int(p_level.op) == 69 {
				sqlite3_vdbe_add_op2(v, 10, p_level.p1, p_level.addrFirst)
			} else {
				sqlite3_vdbe_goto(v, p_level.addrFirst)
			}
			sqlite3_vdbe_jump_here(v, addr)
		}
	}
	i = 0
	for p_level = unsafe { &pwi_nfo.a[0] }; i < int(pwi_nfo.nLevel); i++ {
		k := 0
		last := 0

		p_op := &VdbeOp(0)
		p_last_op := &VdbeOp(0)

		p_idx := unsafe { &Index(nil) }
		p_tab_item := unsafe { &p_tab_list.a[0] + p_level.iFrom }
		p_tab := p_tab_item.pSTab
		p_loop = p_level.pWLoop
		if p_level.pRJ {
			sqlite3_where_right_join_loop(pwi_nfo, i, p_level)
			unsafe { goto c2v_for_next_213
			 }
		}
		if p_tab_item.fg.viaCoroutine {
			translate_column_to_copy(p_parse, p_level.addrBody, p_level.iTabCur, p_tab_item.u4.pSubq.regResult, 0)
			unsafe { goto c2v_for_next_213
			 }
		}
		if p_loop.wsFlags & u32((512 | 64)) {
			p_idx = p_loop.u.btree.pIndex
		} else if p_loop.wsFlags & u32(8192) {
			p_idx = p_level.u.pCoveringIdx
		}
		if !isnil(p_idx) && !db.mallocFailed {
			if int(pwi_nfo.eOnePass) == 0 || !((p_idx.pTable.tabFlags & u32(128)) == u32(0)) {
				last = i_end
			} else {
				last = pwi_nfo.iEndWhere
			}
			if p_idx.bHasExpr {
				p := p_parse.pIdxEpr
				for p {
					if p.iIdxCur == p_level.iIdxCur {
						p.iDataCur = -1
						p.iIdxCur = -1
					}
					p = p.pIENext
				}
			}
			k = p_level.addrBody + 1
			p_op = sqlite3_vdbe_get_op(v, k)
			p_last_op = p_op + (last - k)
			for {
				if p_op.p1 != p_level.iTabCur {
				} else if int(p_op.opcode) == 96 {
					x := p_op.p2
					if !((p_tab.tabFlags & u32(128)) == u32(0)) {
						p_pk := sqlite3_primary_key_index(p_tab)
						x = int(p_pk.aiColumn[x])
					} else {
						x = int(sqlite3_storage_column_to_table(p_tab, I16(x)))
					}
					x = sqlite3_table_column_to_index(p_idx, x)
					if x >= 0 {
						p_op.p2 = x
						p_op.p1 = p_level.iIdxCur
					} else if p_loop.wsFlags & u32((64 | 67108864)) {
						if p_loop.wsFlags & u32(64) {
							sqlite3_error_msg(p_parse, c'internal query planner error')
							p_parse.rc = 2
						} else {
							p_loop.wsFlags &= u32(~67108864)
							sqlite3_where_add_explain_text(p_parse, p_level.addrBody - 1, p_tab_list, p_level, pwi_nfo.wctrlFlags)
						}
					}
				} else if int(p_op.opcode) == 137 {
					p_op.p1 = p_level.iIdxCur
					p_op.opcode = U8(144)
				} else if int(p_op.opcode) == 20 {
					p_op.p1 = p_level.iIdxCur
				}
				if !(usize((c2v_pointer_prefix(voidptr(&p_op), p_op, isize(1)))) < usize(p_last_op)) {
					break
				}
			}
		}
		c2v_for_next_213:
		c2v_pointer_postfix(voidptr(&p_level), p_level, isize(1))
	}
	sqlite3_vdbe_resolve_label(v, pwi_nfo.iBreak)
	p_parse.nQueryLoop = LogEst(pwi_nfo.savedNQueryLoop)
	where_info_free(db, pwi_nfo)
	p_parse.withinRJSubrtn -= nrj
	return
}
