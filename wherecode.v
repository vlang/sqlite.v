@[translated]
module main

@[c:'explainIndexColumnName']
fn explain_index_column_name(p_idx &Index, i int) &i8 {
	i = int(p_idx.aiColumn[i])
	if i == (-2) {
		return unsafe { &i8(&c'<expr>'[0]) }
	}
	if i == (-1) {
		return unsafe { &i8(&c'rowid'[0]) }
	}
	return p_idx.pTable.aCol[i].zCnName
}

@[c:'explainAppendTerm']
fn explain_append_term(p_str &StrAccum, p_idx &Index, n_term int, i_term int, b_and int, z_op &i8) {
	i := 0
	if b_and {
		sqlite3_str_append(unsafe { &Sqlite3_str(p_str) }, c' AND ', 5)
	}
	if n_term > 1 {
		sqlite3_str_append(unsafe { &Sqlite3_str(p_str) }, c'(', 1)
	}
	for i = 0; i < n_term; i++ {
		if i {
			sqlite3_str_append(unsafe { &Sqlite3_str(p_str) }, c',', 1)
		}
		sqlite3_str_appendall(unsafe { &Sqlite3_str(p_str) }, explain_index_column_name(p_idx, i_term + i))
	}
	if n_term > 1 {
		sqlite3_str_append(unsafe { &Sqlite3_str(p_str) }, c')', 1)
	}
	sqlite3_str_append(unsafe { &Sqlite3_str(p_str) }, z_op, 1)
	if n_term > 1 {
		sqlite3_str_append(unsafe { &Sqlite3_str(p_str) }, c'(', 1)
	}
	for i = 0; i < n_term; i++ {
		if i {
			sqlite3_str_append(unsafe { &Sqlite3_str(p_str) }, c',', 1)
		}
		sqlite3_str_append(unsafe { &Sqlite3_str(p_str) }, c'?', 1)
	}
	if n_term > 1 {
		sqlite3_str_append(unsafe { &Sqlite3_str(p_str) }, c')', 1)
	}
}

@[c:'explainIndexRange']
fn explain_index_range(p_str &StrAccum, p_loop &WhereLoop) {
	p_index := p_loop.u.btree.pIndex
	n_eq := p_loop.u.btree.nEq
	n_skip := p_loop.nSkip
	i := 0
	j := 0

	if int(n_eq) == 0 && (p_loop.wsFlags & u32((32 | 16))) == u32(0) {
		return
	}
	sqlite3_str_append(unsafe { &Sqlite3_str(p_str) }, c' (', 2)
	for i = 0; i < int(n_eq); i++ {
		z := explain_index_column_name(p_index, i)
		if i {
			sqlite3_str_append(unsafe { &Sqlite3_str(p_str) }, c' AND ', 5)
		}
		sqlite3_str_appendf(unsafe { &Sqlite3_str(p_str) }, unsafe { if i >= int(n_skip) {
			c'%s=?'
		} else {
			c'ANY(%s)'
		} }, voidptr(z))
	}
	j = i
	if p_loop.wsFlags & u32(32) {
		explain_append_term(p_str, p_index, int(p_loop.u.btree.nBtm), j, i, c'>')
		i = 1
	}
	if p_loop.wsFlags & u32(16) {
		explain_append_term(p_str, p_index, int(p_loop.u.btree.nTop), j, i, c'<')
	}
	sqlite3_str_append(unsafe { &Sqlite3_str(p_str) }, c')', 1)
}

@[c:'sqlite3WhereAddExplainText']
fn sqlite3_where_add_explain_text(p_parse &Parse, addr int, p_tab_list &SrcList, p_level &WhereLevel, wctrl_flags U16) {
	if int((if p_parse.pToplevel { p_parse.pToplevel } else { p_parse }).explain) == 2 || 0 {
		p_op := sqlite3_vdbe_get_op(p_parse.pVdbe, addr)
		p_item := unsafe { &p_tab_list.a[0] + p_level.iFrom }
		db := p_parse.db
		is_search := 0
		p_loop := &WhereLoop(0)
		flags := u32(0)
		str := StrAccum{}
		z_buf := [100]i8{}
		if db.mallocFailed {
			return
		}
		p_loop = p_level.pWLoop
		flags = p_loop.wsFlags
		is_search = (flags & u32((32 | 16))) != u32(0) || ((flags & u32(1024)) == u32(0) && (int(p_loop.u.btree.nEq) > 0)) || (int(wctrl_flags) & (1 | 2))
		sqlite3_str_accum_init(&str, db, unsafe { &i8(&z_buf[0]) }, int(sizeof([100]i8)), 1000000000)
		str.printfFlags = U8(1)
		sqlite3_str_appendf(unsafe { &Sqlite3_str(&str) }, c'%s %S%s', voidptr(if is_search {
			c'SEARCH'
		} else {
			c'SCAN'
		}), voidptr(p_item), voidptr(if int(p_item.fg.fromExists) { c' EXISTS' } else { c'' }))
		if (flags & u32((256 | 1024))) == u32(0) {
			z_fmt := unsafe { &i8(nil) }
			p_idx := &Index(0)
			p_idx = p_loop.u.btree.pIndex
			if !((p_item.pSTab.tabFlags & u32(128)) == u32(0)) && (int(p_idx.idxType) == 2) {
				if is_search {
					z_fmt = c'PRIMARY KEY'
				}
			} else if flags & u32(131072) {
				z_fmt = c'AUTOMATIC PARTIAL COVERING INDEX'
			} else if flags & u32(16384) {
				z_fmt = c'AUTOMATIC COVERING INDEX'
			} else if flags & u32((64 | 67108864)) {
				z_fmt = c'COVERING INDEX %s'
			} else {
				z_fmt = c'INDEX %s'
			}
			if z_fmt {
				sqlite3_str_append(unsafe { &Sqlite3_str(&str) }, c' USING ', 7)
				sqlite3_str_appendf(unsafe { &Sqlite3_str(&str) }, z_fmt, voidptr(p_idx.zName))
				explain_index_range(&str, p_loop)
			}
		} else if (flags & u32(256)) != u32(0) && (flags & u32(15)) != u32(0) {
			c_range_op := i8(0)
			z_rowid := c'rowid'
			sqlite3_str_appendf(unsafe { &Sqlite3_str(&str) }, c' USING INTEGER PRIMARY KEY (%s', voidptr(z_rowid))
			if flags & u32((1 | 4)) {
				c_range_op = i8(`=`)
			} else if (flags & u32(48)) == u32(48) {
				sqlite3_str_appendf(unsafe { &Sqlite3_str(&str) }, c'>? AND %s', voidptr(z_rowid))
				c_range_op = i8(`<`)
			} else if flags & u32(32) {
				c_range_op = i8(`>`)
			} else {
				c_range_op = i8(`<`)
			}
			sqlite3_str_appendf(unsafe { &Sqlite3_str(&str) }, c'%c?)', int(c_range_op))
		} else if (flags & u32(1024)) != u32(0) {
			sqlite3_str_appendall(unsafe { &Sqlite3_str(&str) }, c' VIRTUAL TABLE INDEX ')
			sqlite3_str_appendf(unsafe { &Sqlite3_str(&str) }, unsafe { if int(p_loop.u.vtab.bIdxNumHex) {
				c'0x%x:%s'
			} else {
				c'%d:%s'
			} }, p_loop.u.vtab.idxNum, voidptr(p_loop.u.vtab.idxStr))
		}
		if int(p_item.fg.jointype) & 8 {
			sqlite3_str_appendf(unsafe { &Sqlite3_str(&str) }, c' LEFT-JOIN')
		}
		sqlite3_db_free(db, voidptr(p_op.p4.z))
		p_op.p4type = i8((-7))
		p_op.p4.z = sqlite3_str_accum_finish(&str)
	}
}

@[c:'sqlite3WhereExplainOneScan']
fn sqlite3_where_explain_one_scan(p_parse &Parse, p_tab_list &SrcList, p_level &WhereLevel, wctrl_flags U16) int {
	ret := 0
	if int((if p_parse.pToplevel { p_parse.pToplevel } else { p_parse }).explain) == 2 || 0 {
		if (p_level.pWLoop.wsFlags & u32(8192)) == u32(0) && (int(wctrl_flags) & 32) == 0 {
			v := p_parse.pVdbe
			addr := sqlite3_vdbe_current_addr(v)
			ret = sqlite3_vdbe_add_op3(v, 190, addr, p_parse.addrExplain, int(p_level.pWLoop.rRun))
			sqlite3_where_add_explain_text(p_parse, addr, p_tab_list, p_level, wctrl_flags)
		}
	}
	return ret
}

@[c:'sqlite3WhereExplainBloomFilter']
fn sqlite3_where_explain_bloom_filter(p_parse &Parse, pwi_nfo &WhereInfo, p_level &WhereLevel) int {
	ret := 0
	p_item := unsafe { &pwi_nfo.pTabList.a[0] + p_level.iFrom }
	v := p_parse.pVdbe
	db := p_parse.db
	z_msg := &i8(0)
	i := 0
	p_loop := &WhereLoop(0)
	str := StrAccum{}
	z_buf := [100]i8{}
	sqlite3_str_accum_init(&str, db, unsafe { &i8(&z_buf[0]) }, int(sizeof([100]i8)), 1000000000)
	str.printfFlags = U8(1)
	sqlite3_str_appendf(unsafe { &Sqlite3_str(&str) }, c'BLOOM FILTER ON %S (', voidptr(p_item))
	p_loop = p_level.pWLoop
	if p_loop.wsFlags & u32(256) {
		p_tab := p_item.pSTab
		if int(p_tab.iPKey) >= 0 {
			sqlite3_str_appendf(unsafe { &Sqlite3_str(&str) }, c'%s=?', voidptr(p_tab.aCol[p_tab.iPKey].zCnName))
		} else {
			sqlite3_str_appendf(unsafe { &Sqlite3_str(&str) }, c'rowid=?')
		}
	} else {
		for i = int(p_loop.nSkip); i < int(p_loop.u.btree.nEq); i++ {
			z := explain_index_column_name(p_loop.u.btree.pIndex, i)
			if i > int(p_loop.nSkip) {
				sqlite3_str_append(unsafe { &Sqlite3_str(&str) }, c' AND ', 5)
			}
			sqlite3_str_appendf(unsafe { &Sqlite3_str(&str) }, c'%s=?', voidptr(z))
		}
	}
	sqlite3_str_append(unsafe { &Sqlite3_str(&str) }, c')', 1)
	z_msg = sqlite3_str_accum_finish(&str)
	ret = sqlite3_vdbe_add_op4(v, 190, sqlite3_vdbe_current_addr(v), p_parse.addrExplain, 0, z_msg, (-7))
	0
	return ret
}

@[c:'disableTerm']
fn disable_term(p_level &WhereLevel, p_term &WhereTerm) {
	n_loop := 0
	for (int(p_term.wtFlags) & 4) == 0 && (p_level.iLeftJoin == 0 || ((p_term.pExpr.flags & u32(1)) != u32(0))) && (p_level.notReady & p_term.prereqAll) == Bitmask(0) {
		if n_loop && (int(p_term.wtFlags) & 1024) != 0 {
			p_term.wtFlags |= 512
		} else {
			p_term.wtFlags |= 4
		}
		if p_term.iParent < 0 {
			break
		}
		p_term = unsafe { p_term.pWC.a + p_term.iParent }
		p_term.nChild--
		if int(p_term.nChild) != 0 {
			break
		}
		n_loop++
	}
}

@[c:'codeApplyAffinity']
fn code_apply_affinity(p_parse &Parse, base int, n int, z_aff &i8) {
	v := p_parse.pVdbe
	if usize(z_aff) == usize(0) {
		return
	}
	for n > 0 && int(z_aff[0]) <= 65 {
		n--
		base++
		c2v_pointer_postfix(voidptr(&z_aff), z_aff, isize(1))
	}
	for n > 1 && int(z_aff[n - 1]) <= 65 {
		n--
	}
	if n > 0 {
		sqlite3_vdbe_add_op4(v, 98, base, n, 0, z_aff, n)
	}
}

@[c:'updateRangeAffinityStr']
fn update_range_affinity_str(p_right &Expr, n int, z_aff &i8) {
	i := 0
	for i = 0; i < n; i++ {
		p := sqlite3_vector_field_subexpr(p_right, i)
		if int(sqlite3_compare_affinity(p, i8(z_aff[i]))) == 65 || sqlite3_expr_needs_no_affinity_change(p, i8(z_aff[i])) {
			z_aff[i] = i8(65)
		}
	}
}

@[c:'adjustOrderByCol']
fn adjust_order_by_col(p_order_by &ExprList, pel_ist &ExprList) {
	i := 0
	j := 0

	if usize(p_order_by) == usize(0) {
		return
	}
	for i = 0; i < p_order_by.nExpr; i++ {
		t := int(c2v_at(&p_order_by.a[0], isize(i)).u.x.iOrderByCol)
		if t == 0 {
			continue
		}
		for j = 0; j < pel_ist.nExpr; j++ {
			if int(c2v_at(&pel_ist.a[0], isize(j)).u.x.iOrderByCol) == t {
				mut __c2v_lhs_tmp_159 := c2v_at(&p_order_by.a[0], isize(i))
				__c2v_lhs_tmp_159.u.x.iOrderByCol = U16(j + 1)
				break
			}
		}
		if j >= pel_ist.nExpr {
			mut __c2v_lhs_tmp_160 := c2v_at(&p_order_by.a[0], isize(i))
			__c2v_lhs_tmp_160.u.x.iOrderByCol = U16(0)
		}
	}
}

@[c:'removeUnindexableInClauseTerms']
fn remove_unindexable_in_clause_terms(p_parse &Parse, i_eq int, p_loop &WhereLoop, px &Expr) &Expr {
	db := p_parse.db
	p_select := &Select(0)
	p_new := &Expr(0)
	p_new = sqlite3_expr_dup(db, px, 0)
	if int(db.mallocFailed) == 0 {
		for p_select = p_new.x.pSelect; p_select; p_select = p_select.pPrior {
			p_orig_rhs := &ExprList(0)
			p_orig_lhs := unsafe { &ExprList(nil) }
			p_rhs := unsafe { &ExprList(nil) }
			p_lhs := unsafe { &ExprList(nil) }
			i := 0
			p_orig_rhs = p_select.pEList
			if usize(p_select) == usize(p_new.x.pSelect) {
				p_orig_lhs = p_new.pLeft.x.pList
			}
			for i = i_eq; i < int(p_loop.nLTerm); i++ {
				if usize(p_loop.aLTerm[i].pExpr) == usize(px) {
					i_field := 0
					i_field = p_loop.aLTerm[i].u.x.iField - 1
					if (usize(c2v_at(&p_orig_rhs.a[0], isize(i_field)).pExpr) == usize(0)) {
						continue
					}
					p_rhs = sqlite3_expr_list_append(p_parse, p_rhs, c2v_at(&p_orig_rhs.a[0], isize(i_field)).pExpr)
					mut __c2v_lhs_tmp_161 := c2v_at(&p_orig_rhs.a[0], isize(i_field))
					__c2v_lhs_tmp_161.pExpr = 0
					if p_rhs {
						mut __c2v_lhs_tmp_162 := unsafe { c2v_at(&p_rhs.a[0], isize(p_rhs.nExpr - 1)) }
						__c2v_lhs_tmp_162.u.x.iOrderByCol = U16(i_field + 1)
					}
					if p_orig_lhs {
						p_lhs = sqlite3_expr_list_append(p_parse, p_lhs, c2v_at(&p_orig_lhs.a[0], isize(i_field)).pExpr)
						mut __c2v_lhs_tmp_163 := c2v_at(&p_orig_lhs.a[0], isize(i_field))
						__c2v_lhs_tmp_163.pExpr = 0
					}
				}
			}
			sqlite3_expr_list_delete(db, p_orig_rhs)
			if p_orig_lhs {
				sqlite3_expr_list_delete(db, p_orig_lhs)
				p_new.pLeft.x.pList = p_lhs
			}
			p_select.pEList = p_rhs
			p_select.selId = u32(c2v_prefix_add(unsafe { &p_parse.nSelect }, 1))
			if !isnil(p_lhs) && p_lhs.nExpr == 1 {
				p := c2v_at(&p_lhs.a[0], isize(0)).pExpr
				mut __c2v_lhs_tmp_164 := c2v_at(&p_lhs.a[0], isize(0))
				__c2v_lhs_tmp_164.pExpr = 0
				sqlite3_expr_delete(db, p_new.pLeft)
				p_new.pLeft = p
			}
			if p_rhs {
				adjust_order_by_col(p_select.pOrderBy, p_rhs)
				adjust_order_by_col(p_select.pGroupBy, p_rhs)
				for i = 0; i < p_rhs.nExpr; i++ {
					mut __c2v_lhs_tmp_165 := c2v_at(&p_rhs.a[0], isize(i))
					__c2v_lhs_tmp_165.u.x.iOrderByCol = U16(0)
				}
			}
		}
	}
	return p_new
}

@[c:'codeINTerm']
fn code_in_term(p_parse &Parse, p_term &WhereTerm, p_level &WhereLevel, i_eq int, b_rev int, i_target int) {
	px := p_term.pExpr
	e_type := 5
	i_tab := 0
	p_in := &InLoop(0)
	p_loop := p_level.pWLoop
	v := p_parse.pVdbe
	i := 0
	n_eq := 0
	ai_map := unsafe { &int(nil) }
	if (p_loop.wsFlags & u32(1024)) == u32(0) && usize(p_loop.u.btree.pIndex) != usize(0) && int(p_loop.u.btree.pIndex.aSortOrder[i_eq]) {
		0
		0
		b_rev = !b_rev
	}
	for i = 0; i < i_eq; i++ {
		if !isnil(p_loop.aLTerm[i]) && usize(p_loop.aLTerm[i].pExpr) == usize(px) {
			disable_term(p_level, p_term)
			return
		}
	}
	for i = i_eq; i < int(p_loop.nLTerm); i++ {
		if usize(p_loop.aLTerm[i].pExpr) == usize(px) {
			n_eq++
		}
	}
	i_tab = 0
	if !((px.flags & u32(4096)) != u32(0)) || px.x.pSelect.pEList.nExpr == 1 {
		e_type = sqlite3_find_in_index(p_parse, px, u32(4), unsafe { nil }, unsafe { nil }, &i_tab)
	} else {
		db := p_parse.db
		pxm_od := remove_unindexable_in_clause_terms(p_parse, i_eq, p_loop, px)
		if !db.mallocFailed {
			ai_map = &int(sqlite3_db_malloc_zero(db, U64(sizeof(int) * u64(n_eq))))
			e_type = sqlite3_find_in_index(p_parse, pxm_od, u32(4), unsafe { nil }, ai_map, &i_tab)
		}
		sqlite3_expr_delete(db, pxm_od)
	}
	if e_type == 4 {
		0
		b_rev = !b_rev
	}
	sqlite3_vdbe_add_op2(v, if b_rev { 32 } else { 36 }, i_tab, 0)
	0
	0
	p_loop.wsFlags |= u32(2048)
	if p_level.u.in_.nIn == 0 {
		p_level.addrNxt = sqlite3_vdbe_make_label(p_parse)
	}
	if i_eq > 0 && (p_loop.wsFlags & u32(1048576)) == u32(0) {
		p_loop.wsFlags |= u32(262144)
	}
	i = p_level.u.in_.nIn
	p_level.u.in_.nIn += n_eq
	p_level.u.in_.aInLoop = sqlite3_where_realloc(p_term.pWC.pWInfo, voidptr(p_level.u.in_.aInLoop), U64(sizeof(InLoop) * u64(p_level.u.in_.nIn)))
	p_in = p_level.u.in_.aInLoop
	if p_in {
		mut i_map := 0
		c2v_pointer_prefix(voidptr(&p_in), p_in, isize(i))
		for i = i_eq; i < int(p_loop.nLTerm); i++ {
			if usize(p_loop.aLTerm[i].pExpr) == usize(px) {
				i_out := i_target + i - i_eq
				if e_type == 1 {
					p_in.addrInTop = sqlite3_vdbe_add_op2(v, 137, i_tab, i_out)
				} else {
					i_col := if ai_map { ai_map[i_map++] } else { 0 }
					p_in.addrInTop = sqlite3_vdbe_add_op3(v, 96, i_tab, i_col, i_out)
				}
				sqlite3_vdbe_add_op1(v, 51, i_out)
				0
				if i == i_eq {
					p_in.iCur = i_tab
					p_in.eEndLoopOp = U8(if b_rev { 39 } else { 40 })
					if i_eq > 0 {
						p_in.iBase = i_target - i
						p_in.nPrefix = i
					} else {
						p_in.nPrefix = 0
					}
				} else {
					p_in.eEndLoopOp = U8(189)
				}
				c2v_pointer_postfix(voidptr(&p_in), p_in, isize(1))
			}
		}
		0
		if i_eq > 0 && (p_loop.wsFlags & u32((1048576 | 1024))) == u32(0) {
			sqlite3_vdbe_add_op3(v, 127, p_level.iIdxCur, 0, i_eq)
		}
	} else {
		p_level.u.in_.nIn = 0
	}
	sqlite3_db_free(p_parse.db, voidptr(ai_map))
}

@[c:'codeEqualityTerm']
fn code_equality_term(p_parse &Parse, p_term &WhereTerm, p_level &WhereLevel, i_eq int, b_rev int, i_target int) int {
	px := p_term.pExpr
	i_reg := 0
	if int(px.op) == 54 || int(px.op) == 45 {
		i_reg = sqlite3_expr_code_target(p_parse, px.pRight, i_target)
	} else if int(px.op) == 51 {
		i_reg = i_target
		sqlite3_vdbe_add_op2(p_parse.pVdbe, 77, 0, i_reg)
	} else {
		i_reg = i_target
		code_in_term(p_parse, p_term, p_level, i_eq, b_rev, i_target)
	}
	if (p_level.pWLoop.wsFlags & u32(2097152)) == u32(0) || (int(p_term.eOperator) & 2048) == 0 {
		disable_term(p_level, p_term)
	}
	return i_reg
}

@[c:'codeAllEqualityTerms']
fn code_all_equality_terms(p_parse &Parse, p_level &WhereLevel, b_rev int, n_extra_reg int, pz_aff &&u8) int {
	n_eq := U16(0)
	n_skip := U16(0)
	v := p_parse.pVdbe
	p_idx := &Index(0)
	p_term := &WhereTerm(0)
	p_loop := &WhereLoop(0)
	j := 0
	reg_base := 0
	n_reg := 0
	z_aff := &i8(0)
	p_loop = p_level.pWLoop
	n_eq = p_loop.u.btree.nEq
	n_skip = p_loop.nSkip
	p_idx = p_loop.u.btree.pIndex
	reg_base = p_parse.nMem + 1
	n_reg = int(n_eq) + n_extra_reg
	p_parse.nMem += n_reg
	z_aff = sqlite3_db_str_dup(p_parse.db, sqlite3_index_affinity_str(p_parse.db, p_idx))
	if n_skip {
		i_idx_cur := p_level.iIdxCur
		sqlite3_vdbe_add_op3(v, 77, 0, reg_base, reg_base + int(n_skip) - 1)
		sqlite3_vdbe_add_op1(v, (if b_rev { 32 } else { 36 }), i_idx_cur)
		0
		0
		0
		j = sqlite3_vdbe_add_op0(v, 9)
		p_level.addrSkip = sqlite3_vdbe_add_op4_int(v, (if b_rev { 21 } else { 24 }), i_idx_cur, 0, reg_base, int(n_skip))
		0
		0
		sqlite3_vdbe_jump_here(v, j)
		for j = 0; j < int(n_skip); j++ {
			sqlite3_vdbe_add_op3(v, 96, i_idx_cur, j, reg_base + j)
			0
			0
		}
	}
	for j = int(n_skip); j < int(n_eq); j++ {
		r1 := 0
		p_term = p_loop.aLTerm[j]
		0
		0
		r1 = code_equality_term(p_parse, p_term, p_level, j, b_rev, reg_base + j)
		if r1 != reg_base + j {
			if n_reg == 1 {
				sqlite3_release_temp_reg(p_parse, reg_base)
				reg_base = r1
			} else {
				sqlite3_vdbe_add_op2(v, 82, r1, reg_base + j)
			}
		}
		if int(p_term.eOperator) & 1 {
			if p_term.pExpr.flags & u32(4096) {
				if z_aff {
					z_aff[j] = i8(65)
				}
			}
		} else if (int(p_term.eOperator) & 256) == 0 {
			p_right := p_term.pExpr.pRight
			if (int(p_term.wtFlags) & 2048) == 0 && sqlite3_expr_can_be_null(p_right) {
				sqlite3_vdbe_add_op2(v, 51, reg_base + j, p_level.addrBrk)
				0
			}
			if p_parse.nErr == 0 {
				if int(sqlite3_compare_affinity(p_right, i8(z_aff[j]))) == 65 {
					z_aff[j] = i8(65)
				}
				if sqlite3_expr_needs_no_affinity_change(p_right, i8(z_aff[j])) {
					z_aff[j] = i8(65)
				}
			}
		}
	}
	unsafe { *pz_aff = z_aff }
	return reg_base
}

@[c:'whereLikeOptimizationStringFixup']
fn where_like_optimization_string_fixup(v &Vdbe, p_level &WhereLevel, p_term &WhereTerm) {
	if int(p_term.wtFlags) & 256 {
		p_op := &VdbeOp(0)
		p_op = sqlite3_vdbe_get_last_op(v)
		p_op.p3 = int((p_level.iLikeRepCntr >> 1))
		p_op.p5 = U16(U8((p_level.iLikeRepCntr & u32(1))))
	}
}

@[c:'codeDeferredSeek']
fn code_deferred_seek(pwi_nfo &WhereInfo, p_idx &Index, i_cur int, i_idx_cur int) {
	p_parse := pwi_nfo.pParse
	v := p_parse.pVdbe
	pwi_nfo.bDeferredSeek = u32(1)
	sqlite3_vdbe_add_op3(v, 143, i_idx_cur, 0, i_cur)
	if (int(pwi_nfo.wctrlFlags) & (32 | 4096)) && ((if p_parse.pToplevel {
		p_parse.pToplevel
	} else {
		p_parse
	}).writeMask == YDbMask(0)) {
		i := 0
		p_tab := p_idx.pTable
		ai := &u32(sqlite3_db_malloc_zero(p_parse.db, U64(sizeof(u32) * u64((int(p_tab.nCol) + 1)))))
		if ai {
			ai[0] = u32(p_tab.nCol)
			for i = 0; i < int(p_idx.nColumn) - 1; i++ {
				x1 := 0
				x2 := 0

				x1 = int(p_idx.aiColumn[i])
				x2 = int(sqlite3_table_column_to_storage(p_tab, I16(x1)))
				0
				if x1 >= 0 {
					ai[x2 + 1] = u32(i + 1)
				}
			}
			sqlite3_vdbe_change_p4(v, -1, &i8(voidptr(ai)), (-15))
		}
	}
}

@[c:'codeExprOrVector']
fn code_expr_or_vector(p_parse &Parse, p &Expr, i_reg int, n_reg int) {
	if !isnil(p) && sqlite3_expr_is_vector(p) {
		if ((p.flags & u32(4096)) != u32(0)) {
			v := p_parse.pVdbe
			i_select := 0
			i_select = sqlite3_code_subselect(p_parse, p)
			sqlite3_vdbe_add_op3(v, 82, i_select, i_reg, n_reg - 1)
		} else {
			i := 0
			p_list := &ExprList(0)
			p_list = p.x.pList
			for i = 0; i < n_reg; i++ {
				sqlite3_expr_code(p_parse, c2v_at(&p_list.a[0], isize(i)).pExpr, i_reg + i)
			}
		}
	} else {
		sqlite3_expr_code(p_parse, p, i_reg)
	}
}

@[c:'whereApplyPartialIndexConstraints']
fn where_apply_partial_index_constraints(p_truth &Expr, i_tab_cur int, pwc &WhereClause) {
	i := 0
	p_term := &WhereTerm(0)
	for int(p_truth.op) == 44 {
		where_apply_partial_index_constraints(p_truth.pLeft, i_tab_cur, pwc)
		p_truth = p_truth.pRight
	}
	i = 0
	for p_term = pwc.a; i < pwc.nTerm; i++ {
		p_expr := &Expr(0)
		if int(p_term.wtFlags) & 4 {
			unsafe { goto c2v_for_next_176
			 }
		}
		p_expr = p_term.pExpr
		if sqlite3_expr_compare(unsafe { nil }, p_expr, p_truth, i_tab_cur) == 0 {
			p_term.wtFlags |= 4
		}
		c2v_for_next_176:
		c2v_pointer_postfix(voidptr(&p_term), p_term, isize(1))
	}
}

@[c:'filterPullDown']
fn filter_pull_down(p_parse &Parse, pwi_nfo &WhereInfo, i_level int, addr_nxt int, not_ready Bitmask) {
	saved_addr_brk := 0
	for {
		i_level++
		if !(i_level < int(pwi_nfo.nLevel)) {
			break
		}
		p_level := unsafe { &pwi_nfo.a[0] + i_level }
		p_loop := p_level.pWLoop
		if p_level.regFilter == 0 {
			continue
		}
		if p_level.pWLoop.nSkip {
			continue
		}
		if (p_loop.prereq & not_ready) {
			continue
		}
		saved_addr_brk = p_level.addrBrk
		p_level.addrBrk = addr_nxt
		if p_loop.wsFlags & u32(256) {
			p_term := p_loop.aLTerm[0]
			reg_rowid := 0
			0
			reg_rowid = sqlite3_get_temp_reg(p_parse)
			reg_rowid = code_equality_term(p_parse, p_term, p_level, 0, 0, reg_rowid)
			sqlite3_vdbe_add_op2(p_parse.pVdbe, 13, reg_rowid, addr_nxt)
			0
			sqlite3_vdbe_add_op4_int(p_parse.pVdbe, 66, p_level.regFilter, addr_nxt, reg_rowid, 1)
			0
		} else {
			n_eq := p_loop.u.btree.nEq
			r1 := 0
			z_start_aff := &i8(0)
			r1 = code_all_equality_terms(p_parse, p_level, 0, 0, &&u8(&&i8(c2v_address_of(&z_start_aff))))
			code_apply_affinity(p_parse, r1, int(n_eq), z_start_aff)
			sqlite3_db_free(p_parse.db, voidptr(z_start_aff))
			sqlite3_vdbe_add_op4_int(p_parse.pVdbe, 66, p_level.regFilter, addr_nxt, r1, int(n_eq))
			0
		}
		p_level.regFilter = 0
		p_level.addrBrk = saved_addr_brk
	}
}

@[c:'whereLoopIsOneRow']
fn where_loop_is_one_row(p_loop &WhereLoop) int {
	if int(p_loop.u.btree.pIndex.onError) && int(p_loop.nSkip) == 0 && int(p_loop.u.btree.nEq) == int(p_loop.u.btree.pIndex.nKeyCol) {
		ii := 0
		for ii = 0; ii < int(p_loop.u.btree.nEq); ii++ {
			if int(p_loop.aLTerm[ii].eOperator) & (128 | 256) {
				return 0
			}
		}
		return 1
	}
	return 0
}

@[c:'sqlite3WhereCodeOneLoopStart']
fn sqlite3_where_code_one_loop_start(p_parse &Parse, v &Vdbe, pwi_nfo &WhereInfo, i_level int, p_level &WhereLevel, not_ready Bitmask) Bitmask {
	j := 0
	k := 0

	i_cur := 0
	addr_nxt := 0
	b_rev := 0
	p_loop := &WhereLoop(0)
	pwc := &WhereClause(0)
	p_term := &WhereTerm(0)
	db := &Sqlite3(0)
	p_tab_item := &SrcItem(0)
	addr_brk := 0
	addr_cont := 0
	i_rowid_reg := 0
	i_release_reg := 0
	p_idx := unsafe { &Index(nil) }
	i_loop := 0
	pwc = &pwi_nfo.sWC
	db = p_parse.db
	p_loop = p_level.pWLoop
	p_tab_item = unsafe { &pwi_nfo.pTabList.a[0] + p_level.iFrom }
	i_cur = p_tab_item.iCursor
	p_level.notReady = not_ready & ~sqlite3_where_get_mask(&pwi_nfo.sMaskSet, i_cur)
	b_rev = int((pwi_nfo.revMask >> i_level) & Bitmask(1))
	0
	p_level.addrNxt = p_level.addrBrk
	addr_brk = p_level.addrNxt
	p_level.addrCont = sqlite3_vdbe_make_label(p_parse)
	addr_cont = p_level.addrCont
	if int(p_level.iFrom) > 0 && (int(p_tab_item[0].fg.jointype) & 8) != 0 {
		p_level.iLeftJoin = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		sqlite3_vdbe_add_op2(v, 73, 0, p_level.iLeftJoin)
		0
	}
	if p_tab_item.fg.viaCoroutine {
		reg_yield := 0
		p_subq := &Subquery(0)
		p_subq = p_tab_item.u4.pSubq
		reg_yield = p_subq.regReturn
		sqlite3_vdbe_add_op3(v, 11, reg_yield, 0, p_subq.addrFillSub)
		p_level.p2 = sqlite3_vdbe_add_op2(v, 12, reg_yield, addr_brk)
		0
		0
		p_level.op = U8(9)
	} else if (p_loop.wsFlags & u32(1024)) != u32(0) {
		i_reg := 0
		addr_not_found := 0
		n_constraint := int(p_loop.nLTerm)
		i_reg = sqlite3_get_temp_range(p_parse, n_constraint + 2)
		addr_not_found = p_level.addrBrk
		for j = 0; j < n_constraint; j++ {
			i_target := i_reg + j + 2
			p_term = p_loop.aLTerm[j]
			if (usize(p_term) == usize(0)) {
				continue
			}
			if int(p_term.eOperator) & 1 {
				if (if j <= 31 { (u32(1)) << j } else { u32(0) }) & p_loop.u.vtab.mHandleIn {
					i_tab := p_parse.nTab++
					i_cache := c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
					sqlite3_code_rhs_of_in(p_parse, p_term.pExpr, i_tab, 0)
					sqlite3_vdbe_add_op3(v, 177, i_tab, i_target, i_cache)
				} else {
					code_equality_term(p_parse, p_term, p_level, j, b_rev, i_target)
					addr_not_found = p_level.addrNxt
				}
			} else {
				p_right := p_term.pExpr.pRight
				code_expr_or_vector(p_parse, p_right, i_target, 1)
				if int(p_term.eMatchOp) == 74 && int(p_loop.u.vtab.bOmitOffset) {
					sqlite3_vdbe_add_op2(v, 73, 0, pwi_nfo.pSelect.iOffset)
					0
				}
			}
		}
		sqlite3_vdbe_add_op2(v, 73, p_loop.u.vtab.idxNum, i_reg)
		sqlite3_vdbe_add_op2(v, 73, n_constraint, i_reg + 1)
		sqlite3_vdbe_add_op4(v, 6, i_cur, addr_not_found, i_reg, p_loop.u.vtab.idxStr, if int(p_loop.u.vtab.needFree) {
			(-7)
		} else {
			(-1)
		})
		0
		p_loop.u.vtab.needFree = u32(0)
		if db.mallocFailed {
			p_loop.u.vtab.idxStr = 0
		}
		p_level.p1 = i_cur
		p_level.op = U8(if int(pwi_nfo.eOnePass) { 189 } else { 65 })
		p_level.p2 = sqlite3_vdbe_current_addr(v)
		for j = 0; j < n_constraint; j++ {
			p_term = p_loop.aLTerm[j]
			if j < 16 && (int(p_loop.u.vtab.omitMask) >> j) & 1 {
				disable_term(p_level, p_term)
				continue
			}
			if (int(p_term.eOperator) & 1) != 0 && ((if j <= 31 { (u32(1)) << j } else { u32(0) }) & p_loop.u.vtab.mHandleIn) == u32(0) && !db.mallocFailed {
				p_compare := &Expr(0)
				p_right := &Expr(0)
				p_op := &VdbeOp(0)
				i_in := 0
				for i_in = 0; (i_in < p_level.u.in_.nIn); i_in++ {
					p_op = sqlite3_vdbe_get_op(v, p_level.u.in_.aInLoop[i_in].addrInTop)
					if (int(p_op.opcode) == 96 && p_op.p3 == i_reg + j + 2) || (int(p_op.opcode) == 137 && p_op.p2 == i_reg + j + 2) {
						0
						sqlite3_vdbe_add_op3(v, int(p_op.opcode), p_op.p1, p_op.p2, p_op.p3)
						break
					}
				}
				p_compare = sqlite3_pe_xpr(p_parse, 54, unsafe { nil }, unsafe { nil })
				if !db.mallocFailed {
					i_fld := p_term.u.x.iField
					p_left := p_term.pExpr.pLeft
					if i_fld > 0 {
						p_compare.pLeft = c2v_at(&p_left.x.pList.a[0], isize(i_fld - 1)).pExpr
					} else {
						p_compare.pLeft = p_left
					}
					p_right = sqlite3_expr(db, 176, unsafe { nil })
					p_compare.pRight = p_right
					if p_right {
						p_right.iTable = i_reg + j + 2
						sqlite3_expr_if_false(p_parse, p_compare, p_level.addrCont, 16)
					}
					p_compare.pLeft = 0
				}
				sqlite3_expr_delete(db, p_compare)
			}
		}
	} else if (p_loop.wsFlags & u32(256)) != u32(0) && (p_loop.wsFlags & u32((4 | 1))) != u32(0) {
		p_term = p_loop.aLTerm[0]
		0
		i_release_reg = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		i_rowid_reg = code_equality_term(p_parse, p_term, p_level, 0, b_rev, i_release_reg)
		if i_rowid_reg != i_release_reg {
			sqlite3_release_temp_reg(p_parse, i_release_reg)
		}
		addr_nxt = p_level.addrNxt
		if p_level.regFilter {
			sqlite3_vdbe_add_op2(v, 13, i_rowid_reg, addr_nxt)
			0
			sqlite3_vdbe_add_op4_int(v, 66, p_level.regFilter, addr_nxt, i_rowid_reg, 1)
			0
			filter_pull_down(p_parse, pwi_nfo, i_level, addr_nxt, not_ready)
		}
		sqlite3_vdbe_add_op3(v, 30, i_cur, addr_nxt, i_rowid_reg)
		0
		p_level.op = U8(189)
	} else if (p_loop.wsFlags & u32(256)) != u32(0) && (p_loop.wsFlags & u32(2)) != u32(0) {
		test_op := 189
		start := 0
		mem_end_value := 0
		p_start := &WhereTerm(0)
		p_end := &WhereTerm(0)

		j = 0
		p_end = 0
		p_start = p_end
		if p_loop.wsFlags & u32(32) {
			p_start = p_loop.aLTerm[j++]
		}
		if p_loop.wsFlags & u32(16) {
			p_end = p_loop.aLTerm[j++]
		}
		if b_rev {
			p_term = p_start
			p_start = p_end
			p_end = p_term
		}
		0
		if p_start {
			px := &Expr(0)
			r1 := 0
			r_temp := 0

			op := 0
			a_move_op := [U8(24), U8(22), U8(21), U8(23)]

			0
			px = p_start.pExpr
			0
			if sqlite3_expr_is_vector(px.pRight) {
				r_temp = sqlite3_get_temp_reg(p_parse)
				r1 = r_temp
				code_expr_or_vector(p_parse, px.pRight, r1, 1)
				0
				0
				0
				0
				op = int(a_move_op[((int(px.op) - 55 - 1) & 3) | 1])
			} else {
				r1 = sqlite3_expr_code_temp(p_parse, px.pRight, &r_temp)
				disable_term(p_level, p_start)
				op = int(a_move_op[(int(px.op) - 55)])
			}
			sqlite3_vdbe_add_op3(v, op, i_cur, addr_brk, r1)
			0
			0
			0
			0
			0
			sqlite3_release_temp_reg(p_parse, r_temp)
		} else {
			sqlite3_vdbe_add_op2(v, if b_rev { 32 } else { 36 }, i_cur, p_level.addrHalt)
			0
			0
		}
		if p_end {
			px := &Expr(0)
			px = p_end.pExpr
			0
			0
			mem_end_value = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			code_expr_or_vector(p_parse, px.pRight, mem_end_value, 1)
			if 0 == sqlite3_expr_is_vector(px.pRight) && (int(px.op) == 57 || int(px.op) == 55) {
				test_op = if b_rev { 56 } else { 58 }
			} else {
				test_op = if b_rev { 57 } else { 55 }
			}
			if 0 == sqlite3_expr_is_vector(px.pRight) {
				disable_term(p_level, p_end)
			}
		}
		start = sqlite3_vdbe_current_addr(v)
		p_level.op = U8(if b_rev { 39 } else { 40 })
		p_level.p1 = i_cur
		p_level.p2 = start
		if test_op != 189 {
			i_rowid_reg = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			sqlite3_vdbe_add_op2(v, 137, i_cur, i_rowid_reg)
			sqlite3_vdbe_add_op3(v, test_op, mem_end_value, addr_brk, i_rowid_reg)
			0
			0
			0
			0
			sqlite3_vdbe_change_p5(v, U16(67 | 16))
		}
	} else if p_loop.wsFlags & u32(512) {
		if !sqlite3_where_code_one_loop_start_a_start_op_inited {
			c2v_static_init := [U8(0), U8(0), U8(36), U8(32), U8(24), U8(21), U8(23), U8(22)]
			for c2v_i_0, c2v_element_0 in c2v_static_init {
				sqlite3_where_code_one_loop_start_a_start_op[c2v_i_0] = c2v_element_0
			}
			sqlite3_where_code_one_loop_start_a_start_op_inited = true
		}

		if !sqlite3_where_code_one_loop_start_a_end_op_inited {
			c2v_static_init := [U8(46), U8(42), U8(41), U8(45)]
			for c2v_i_0, c2v_element_0 in c2v_static_init {
				sqlite3_where_code_one_loop_start_a_end_op[c2v_i_0] = c2v_element_0
			}
			sqlite3_where_code_one_loop_start_a_end_op_inited = true
		}

		n_eq := p_loop.u.btree.nEq
		n_btm := p_loop.u.btree.nBtm
		n_top := p_loop.u.btree.nTop
		reg_base := 0
		p_range_start := unsafe { &WhereTerm(nil) }
		p_range_end := unsafe { &WhereTerm(nil) }
		start_eq := 0
		end_eq := 0
		start_constraints := 0
		n_constraint := 0
		i_idx_cur := 0
		n_extra_reg := 0
		op := 0
		z_start_aff := &i8(0)
		z_end_aff := unsafe { &i8(nil) }
		b_seek_past_null := U8(0)
		b_stop_at_null := U8(0)
		omit_table := 0
		reg_bignull := 0
		addr_seek_scan := 0
		p_idx = p_loop.u.btree.pIndex
		i_idx_cur = p_level.iIdxCur
		j = int(n_eq)
		if p_loop.wsFlags & u32(32) {
			p_range_start = p_loop.aLTerm[j++]
			n_extra_reg = (if n_extra_reg > int(p_loop.u.btree.nBtm) {
				n_extra_reg
			} else {
				int(p_loop.u.btree.nBtm)
			})
		}
		if p_loop.wsFlags & u32(16) {
			p_range_end = p_loop.aLTerm[j++]
			n_extra_reg = (if n_extra_reg > int(p_loop.u.btree.nTop) {
				n_extra_reg
			} else {
				int(p_loop.u.btree.nTop)
			})
			if (int(p_range_end.wtFlags) & 256) != 0 {
				p_level.iLikeRepCntr = u32(c2v_prefix_add(unsafe { &p_parse.nMem }, 1))
				sqlite3_vdbe_add_op2(v, 73, 1, int(p_level.iLikeRepCntr))
				0
				p_level.addrLikeRep = sqlite3_vdbe_current_addr(v)
				0
				0
				p_level.iLikeRepCntr <<= 1
				p_level.iLikeRepCntr |= u32(b_rev ^ int((int(p_idx.aSortOrder[n_eq]) == 1)))
			}
			if usize(p_range_start) == usize(0) {
				j = int(p_idx.aiColumn[n_eq])
				if (j >= 0 && int(p_idx.pTable.aCol[j].notNull) == 0) || j == (-2) {
					b_seek_past_null = U8(1)
				}
			}
		}
		if (p_loop.wsFlags & u32((16 | 32))) == u32(0) && (p_loop.wsFlags & u32(524288)) != u32(0) {
			0
			n_extra_reg = 1
			b_seek_past_null = U8(1)
			reg_bignull = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			p_level.regBignull = reg_bignull
			if p_level.iLeftJoin {
				sqlite3_vdbe_add_op2(v, 73, 0, reg_bignull)
			}
			p_level.addrBignull = sqlite3_vdbe_make_label(p_parse)
		}
		if (int(n_eq) < int(p_idx.nColumn) && b_rev == (int(p_idx.aSortOrder[n_eq]) == 0)) {
			t := p_range_end
			p_range_end = p_range_start
			p_range_start = t
			0
			t_2 := b_seek_past_null
			b_seek_past_null = b_stop_at_null
			b_stop_at_null = t_2
			0
			t_3 := U8(n_btm)
			n_btm = n_top
			n_top = U16(t_3)
			0
		}
		if i_level > 0 && (p_loop.wsFlags & u32(1048576)) != u32(0) {
			sqlite3_vdbe_add_op1(v, 138, i_idx_cur)
		}
		0
		reg_base = code_all_equality_terms(p_parse, p_level, b_rev, n_extra_reg, &&u8(&&i8(c2v_address_of(&z_start_aff))))
		if !isnil(z_start_aff) && int(n_top) {
			z_end_aff = sqlite3_db_str_dup(db, unsafe { z_start_aff + n_eq })
		}
		addr_nxt = (if reg_bignull { p_level.addrBignull } else { p_level.addrNxt })
		0
		0
		0
		0
		start_eq = isnil(p_range_start) || int(p_range_start.eOperator) & ((2 << (56 - 54)) | (2 << (58 - 54)))
		end_eq = isnil(p_range_end) || int(p_range_end.eOperator) & ((2 << (56 - 54)) | (2 << (58 - 54)))
		start_constraints = !isnil(p_range_start) || int(n_eq) > 0
		n_constraint = int(n_eq)
		if p_range_start {
			p_right := p_range_start.pExpr.pRight
			code_expr_or_vector(p_parse, p_right, reg_base + int(n_eq), int(n_btm))
			where_like_optimization_string_fixup(v, p_level, p_range_start)
			if (int(p_range_start.wtFlags) & 128) == 0 && sqlite3_expr_can_be_null(p_right) {
				sqlite3_vdbe_add_op2(v, 51, reg_base + int(n_eq), addr_nxt)
				0
			}
			if z_start_aff {
				update_range_affinity_str(p_right, int(n_btm), unsafe { z_start_aff + n_eq })
			}
			n_constraint += int(n_btm)
			0
			if sqlite3_expr_is_vector(p_right) == 0 {
				disable_term(p_level, p_range_start)
			} else {
				start_eq = 1
			}
			b_seek_past_null = U8(0)
		} else if b_seek_past_null {
			start_eq = 0
			sqlite3_vdbe_add_op2(v, 77, 0, reg_base + int(n_eq))
			start_constraints = 1
			n_constraint++
		} else if reg_bignull {
			sqlite3_vdbe_add_op2(v, 77, 0, reg_base + int(n_eq))
			start_constraints = 1
			n_constraint++
		}
		code_apply_affinity(p_parse, reg_base, n_constraint - int(b_seek_past_null), z_start_aff)
		if int(p_loop.nSkip) > 0 && n_constraint == int(p_loop.nSkip) {
		} else {
			if reg_bignull {
				sqlite3_vdbe_add_op2(v, 73, 1, reg_bignull)
				0
			}
			if p_level.regFilter {
				sqlite3_vdbe_add_op4_int(v, 66, p_level.regFilter, addr_nxt, reg_base, int(n_eq))
				0
				filter_pull_down(p_parse, pwi_nfo, i_level, addr_nxt, not_ready)
			}
			op = int(sqlite3_where_code_one_loop_start_a_start_op[(start_constraints << 2) + (start_eq << 1) + b_rev])
			if (p_loop.wsFlags & u32(1048576)) != u32(0) && op == 23 {
				addr_seek_scan = sqlite3_vdbe_add_op1(v, 126, (int(p_idx.aiRowLogEst[0]) + 9) / 10)
				if !isnil(p_range_start) || !isnil(p_range_end) {
					sqlite3_vdbe_change_p5(v, U16(1))
					sqlite3_vdbe_change_p2(v, addr_seek_scan, sqlite3_vdbe_current_addr(v) + 1)
					addr_seek_scan = 0
				}
				0
			}
			sqlite3_vdbe_add_op4_int(v, op, i_idx_cur, addr_nxt, reg_base, n_constraint)
			0
			0
			0
			0
			0
			0
			0
			0
			0
			0
			0
			0
			0
			if reg_bignull {
				sqlite3_vdbe_add_op2(v, 9, 0, sqlite3_vdbe_current_addr(v) + 2)
				op = int(sqlite3_where_code_one_loop_start_a_start_op[int((n_constraint > 1)) * 4 + 2 + b_rev])
				sqlite3_vdbe_add_op4_int(v, op, i_idx_cur, addr_nxt, reg_base, n_constraint - start_eq)
				0
				0
				0
				0
				0
				0
				0
				0
				0
			}
		}
		n_constraint = int(n_eq)
		if p_range_end {
			p_right := p_range_end.pExpr.pRight
			code_expr_or_vector(p_parse, p_right, reg_base + int(n_eq), int(n_top))
			where_like_optimization_string_fixup(v, p_level, p_range_end)
			if (int(p_range_end.wtFlags) & 128) == 0 && sqlite3_expr_can_be_null(p_right) {
				sqlite3_vdbe_add_op2(v, 51, reg_base + int(n_eq), addr_nxt)
				0
			}
			if z_end_aff {
				update_range_affinity_str(p_right, int(n_top), z_end_aff)
				code_apply_affinity(p_parse, reg_base + int(n_eq), int(n_top), z_end_aff)
			} else {
			}
			n_constraint += int(n_top)
			0
			if sqlite3_expr_is_vector(p_right) == 0 {
				disable_term(p_level, p_range_end)
			} else {
				end_eq = 1
			}
		} else if b_stop_at_null {
			if reg_bignull == 0 {
				sqlite3_vdbe_add_op2(v, 77, 0, reg_base + int(n_eq))
				end_eq = 0
			}
			n_constraint++
		}
		if z_start_aff {
			sqlite3_db_nn_free_nn(db, voidptr(z_start_aff))
		}
		if z_end_aff {
			sqlite3_db_nn_free_nn(db, voidptr(z_end_aff))
		}
		p_level.p2 = sqlite3_vdbe_current_addr(v)
		if n_constraint {
			if reg_bignull {
				sqlite3_vdbe_add_op2(v, 17, reg_bignull, sqlite3_vdbe_current_addr(v) + 3)
				0
				0
			}
			op = int(sqlite3_where_code_one_loop_start_a_end_op[b_rev * 2 + end_eq])
			sqlite3_vdbe_add_op4_int(v, op, i_idx_cur, addr_nxt, reg_base, n_constraint)
			0
			0
			0
			0
			0
			0
			0
			0
			if addr_seek_scan {
				sqlite3_vdbe_jump_here(v, addr_seek_scan)
			}
		}
		if reg_bignull {
			sqlite3_vdbe_add_op2(v, 16, reg_bignull, sqlite3_vdbe_current_addr(v) + 2)
			0
			0
			op = int(sqlite3_where_code_one_loop_start_a_end_op[b_rev * 2 + int(b_seek_past_null)])
			sqlite3_vdbe_add_op4_int(v, op, i_idx_cur, addr_nxt, reg_base, n_constraint + int(b_seek_past_null))
			0
			0
			0
			0
			0
			0
			0
			0
		}
		if (p_loop.wsFlags & u32(262144)) != u32(0) {
			sqlite3_vdbe_add_op3(v, 127, i_idx_cur, int(n_eq), int(n_eq))
		}
		omit_table = (p_loop.wsFlags & u32(64)) != u32(0) && (int(pwi_nfo.wctrlFlags) & (32 | 4096)) == 0
		if omit_table {
		} else if ((p_idx.pTable.tabFlags & u32(128)) == u32(0)) {
			code_deferred_seek(pwi_nfo, p_idx, i_cur, i_idx_cur)
		} else if i_cur != i_idx_cur {
			p_pk := sqlite3_primary_key_index(p_idx.pTable)
			i_rowid_reg = sqlite3_get_temp_range(p_parse, int(p_pk.nKeyCol))
			for j = 0; j < int(p_pk.nKeyCol); j++ {
				k = sqlite3_table_column_to_index(p_idx, int(p_pk.aiColumn[j]))
				sqlite3_vdbe_add_op3(v, 96, i_idx_cur, k, i_rowid_reg + j)
			}
			sqlite3_vdbe_add_op4_int(v, 28, i_cur, addr_cont, i_rowid_reg, int(p_pk.nKeyCol))
			0
		}
		if p_level.iLeftJoin == 0 {
			if !isnil(p_idx.pPartIdxWhere) && usize(p_level.pRJ) == usize(0) {
				where_apply_partial_index_constraints(p_idx.pPartIdxWhere, i_cur, pwc)
			}
		} else {
			0
		}
		if (p_loop.wsFlags & u32(4096)) || (p_level.u.in_.nIn && reg_bignull == 0 && where_loop_is_one_row(p_loop)) {
			p_level.op = U8(189)
		} else if b_rev {
			p_level.op = U8(39)
		} else {
			p_level.op = U8(40)
		}
		p_level.p1 = i_idx_cur
		p_level.p3 = U8(if (p_loop.wsFlags & u32(65536)) != u32(0) { 1 } else { 0 })
		if (p_loop.wsFlags & u32(15)) == u32(0) {
			p_level.p5 = U8(1)
		} else {
		}
		if omit_table {
			p_idx = 0
		}
	} else if p_loop.wsFlags & u32(8192) {
		p_or_wc := &WhereClause(0)
		p_or_tab := &SrcList(0)
		p_cov := unsafe { &Index(nil) }
		i_cov_cur := p_parse.nTab++
		reg_return := c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		reg_rowset := 0
		reg_rowid := 0
		i_loop_body := sqlite3_vdbe_make_label(p_parse)
		i_ret_init := 0
		untested_terms := 0
		ii := 0
		p_and_expr := unsafe { &Expr(nil) }
		p_tab := p_tab_item.pSTab
		p_term = p_loop.aLTerm[0]
		p_or_wc = &p_term.u.pOrInfo.wc
		p_level.op = U8(69)
		p_level.p1 = reg_return
		if int(pwi_nfo.nLevel) > 1 || int(p_tab_item.fg.fromExists) {
			n_not_ready := 0
			orig_src := &SrcItem(0)
			n_not_ready = int(pwi_nfo.nLevel) - i_level - 1
			p_or_tab = sqlite3_db_malloc_raw_nn(db, U64(((u64(usize(__offsetof(SrcList, a)))) + u64((n_not_ready + 1)) * sizeof(SrcItem))))
			if usize(p_or_tab) == usize(0) {
				return not_ready
			}
			p_or_tab.nAlloc = u32(U8((n_not_ready + 1)))
			p_or_tab.nSrc = int(p_or_tab.nAlloc)
			C.memcpy(p_or_tab.a, voidptr(p_tab_item), sizeof(SrcItem))
			orig_src = unsafe { &pwi_nfo.pTabList.a[0] }
			for k = 1; k <= n_not_ready; k++ {
				C.memcpy(voidptr(unsafe { &p_or_tab.a[0] + k }), voidptr(unsafe { orig_src + p_level[k].iFrom }), sizeof(SrcItem))
			}
			mut __c2v_lhs_tmp_166 := c2v_at(&p_or_tab.a[0], isize(0))
			__c2v_lhs_tmp_166.fg.fromExists = u32(0)
		} else {
			p_or_tab = pwi_nfo.pTabList
		}
		if (int(pwi_nfo.wctrlFlags) & 16) == 0 {
			if ((p_tab.tabFlags & u32(128)) == u32(0)) {
				reg_rowset = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
				sqlite3_vdbe_add_op2(v, 77, 0, reg_rowset)
			} else {
				p_pk := sqlite3_primary_key_index(p_tab)
				mut __c2v_postfix_value_39 := p_parse.nTab
				p_parse.nTab++
				reg_rowset = __c2v_postfix_value_39
				sqlite3_vdbe_add_op2(v, 120, reg_rowset, int(p_pk.nKeyCol))
				sqlite3_vdbe_set_p4_key_info(p_parse, p_pk)
			}
			reg_rowid = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		}
		i_ret_init = sqlite3_vdbe_add_op2(v, 73, 0, reg_return)
		if pwc.nTerm > 1 {
			i_term := 0
			for i_term = 0; i_term < pwc.nTerm; i_term++ {
				p_expr := pwc.a[i_term].pExpr
				if usize(unsafe { pwc.a + i_term }) == usize(p_term) {
					continue
				}
				0
				0
				0
				if (int(pwc.a[i_term].wtFlags) & (2 | 4 | 32768)) != 0 {
					continue
				}
				if (int(pwc.a[i_term].eOperator) & 16383) == 0 {
					continue
				}
				if ((p_expr.flags & u32(4194304)) != u32(0)) {
					continue
				}
				p_expr = sqlite3_expr_dup(db, p_expr, 0)
				p_and_expr = sqlite3_expr_and(p_parse, p_and_expr, p_expr)
			}
			if p_and_expr {
				p_and_expr = sqlite3_pe_xpr(p_parse, 44 | 65536, unsafe { nil }, p_and_expr)
			}
		}
		sqlite3_vdbe_explain(p_parse, U8(1), c'MULTI-INDEX OR')
		for ii = 0; ii < p_or_wc.nTerm; ii++ {
			p_or_term := unsafe { p_or_wc.a + ii }
			if p_or_term.leftCursor == i_cur || (int(p_or_term.eOperator) & 1024) != 0 {
				p_sub_wi_nfo := &WhereInfo(0)
				p_or_expr := p_or_term.pExpr
				p_delete := &Expr(0)
				jmp1 := 0
				0
				p_or_expr = sqlite3_expr_dup(db, p_or_expr, 0)
				p_delete = p_or_expr
				if db.mallocFailed {
					sqlite3_expr_delete(db, p_delete)
					continue
				}
				if p_and_expr {
					p_and_expr.pLeft = p_or_expr
					p_or_expr = p_and_expr
				}
				sqlite3_vdbe_explain(p_parse, U8(1), c'INDEX %d', ii + 1)
				0
				p_sub_wi_nfo = sqlite3_where_begin(p_parse, p_or_tab, p_or_expr, unsafe { nil }, unsafe { nil }, unsafe { nil }, U16(32), i_cov_cur)
				if p_sub_wi_nfo {
					p_sub_loop := &WhereLoop(0)
					addr_explain := sqlite3_where_explain_one_scan(p_parse, p_or_tab, unsafe { &p_sub_wi_nfo.a[0] + 0 }, U16(0))

					if (int(pwi_nfo.wctrlFlags) & 16) == 0 {
						i_set := (if (ii == p_or_wc.nTerm - 1) { -1 } else { ii })
						if ((p_tab.tabFlags & u32(128)) == u32(0)) {
							sqlite3_expr_code_get_column_of_table(v, p_tab, i_cur, -1, reg_rowid)
							jmp1 = sqlite3_vdbe_add_op4_int(v, 49, reg_rowset, 0, reg_rowid, i_set)
							0
						} else {
							p_pk := sqlite3_primary_key_index(p_tab)
							n_pk := int(p_pk.nKeyCol)
							i_pk := 0
							r := 0
							r = sqlite3_get_temp_range(p_parse, n_pk)
							for i_pk = 0; i_pk < n_pk; i_pk++ {
								i_col := int(p_pk.aiColumn[i_pk])
								sqlite3_expr_code_get_column_of_table(v, p_tab, i_cur, i_col, r + i_pk)
							}
							if i_set {
								jmp1 = sqlite3_vdbe_add_op4_int(v, 29, reg_rowset, 0, r, n_pk)
								0
							}
							if i_set >= 0 {
								sqlite3_vdbe_add_op3(v, 99, r, n_pk, reg_rowid)
								sqlite3_vdbe_add_op4_int(v, 140, reg_rowset, reg_rowid, r, n_pk)
								if i_set {
									sqlite3_vdbe_change_p5(v, U16(16))
								}
							}
							sqlite3_release_temp_range(p_parse, r, n_pk)
						}
					}
					sqlite3_vdbe_add_op2(v, 10, reg_return, i_loop_body)
					if jmp1 {
						sqlite3_vdbe_jump_here(v, jmp1)
					}
					if p_sub_wi_nfo.untestedTerms {
						untested_terms = 1
					}
					p_sub_loop = c2v_at(&p_sub_wi_nfo.a[0], isize(0)).pWLoop
					mut __c2v_condition_97 := false
					mut __c2v_condition_98 := false
					__c2v_condition_98 = (p_sub_loop.wsFlags & u32(512)) != u32(0)
					if __c2v_condition_98 {
						__c2v_condition_98 = (ii == 0 || usize(p_sub_loop.u.btree.pIndex) == usize(p_cov))
					}
					if __c2v_condition_98 {
						__c2v_condition_98 = (((p_tab.tabFlags & u32(128)) == u32(0)) || !(int(p_sub_loop.u.btree.pIndex.idxType) == 2))
					}
					__c2v_condition_97 = __c2v_condition_98
					if __c2v_condition_97 {
						p_cov = p_sub_loop.u.btree.pIndex
					} else {
						p_cov = 0
					}
					if sqlite3_where_uses_deferred_seek(p_sub_wi_nfo) {
						pwi_nfo.bDeferredSeek = u32(1)
					}
					sqlite3_where_end(p_sub_wi_nfo)
					sqlite3_vdbe_explain_pop(p_parse)
				}
				sqlite3_expr_delete(db, p_delete)
			}
		}
		sqlite3_vdbe_explain_pop(p_parse)
		p_level.u.pCoveringIdx = p_cov
		if p_cov {
			p_level.iIdxCur = i_cov_cur
		}
		if p_and_expr {
			p_and_expr.pLeft = 0
			sqlite3_expr_delete(db, p_and_expr)
		}
		sqlite3_vdbe_change_p1(v, i_ret_init, sqlite3_vdbe_current_addr(v))
		sqlite3_vdbe_goto(v, p_level.addrBrk)
		sqlite3_vdbe_resolve_label(v, i_loop_body)
		p_level.p2 = sqlite3_vdbe_current_addr(v)
		if usize(pwi_nfo.pTabList) != usize(p_or_tab) {
			sqlite3_db_free_nn(db, voidptr(p_or_tab))
		}
		if !untested_terms {
			disable_term(p_level, p_term)
		}
	} else {
		if !sqlite3_where_code_one_loop_start_a_step_inited {
			c2v_static_init := [U8(40), U8(39)]
			for c2v_i_0, c2v_element_0 in c2v_static_init {
				sqlite3_where_code_one_loop_start_a_step[c2v_i_0] = c2v_element_0
			}
			sqlite3_where_code_one_loop_start_a_step_inited = true
		}

		if !sqlite3_where_code_one_loop_start_a_start_inited {
			c2v_static_init := [U8(36), U8(32)]
			for c2v_i_0, c2v_element_0 in c2v_static_init {
				sqlite3_where_code_one_loop_start_a_start[c2v_i_0] = c2v_element_0
			}
			sqlite3_where_code_one_loop_start_a_start_inited = true
		}

		if p_tab_item.fg.isRecursive {
			p_level.op = U8(189)
		} else {
			0
			p_level.op = sqlite3_where_code_one_loop_start_a_step[b_rev]
			p_level.p1 = i_cur
			p_level.p2 = 1 + sqlite3_vdbe_add_op2(v, int(sqlite3_where_code_one_loop_start_a_start[b_rev]), i_cur, p_level.addrHalt)
			0
			0
			p_level.p5 = U8(1)
		}
	}
	i_loop = (if p_idx { 1 } else { 2 })
	for {
		i_next := 0
		p_term = pwc.a
		for j = pwc.nTerm; j > 0; j-- {
			pe := &Expr(0)
			skip_like_addr := 0
			0
			0
			if int(p_term.wtFlags) & (2 | 4) {
				unsafe { goto c2v_for_next_178
				 }
			}
			if (p_term.prereqAll & p_level.notReady) != Bitmask(0) {
				0
				pwi_nfo.untestedTerms = u32(1)
				unsafe { goto c2v_for_next_178
				 }
			}
			pe = p_term.pExpr
			if int(p_tab_item.fg.jointype) & (8 | 64 | 16) {
				if !((pe.flags & u32((1 | 2))) != u32(0)) {
					unsafe { goto c2v_for_next_178
					 }
				} else if (int(p_tab_item.fg.jointype) & 8) == 8 && !((pe.flags & u32(1)) != u32(0)) {
					unsafe { goto c2v_for_next_178
					 }
				} else {
					m := sqlite3_where_get_mask(&pwi_nfo.sMaskSet, pe.w.iJoin)
					if m & p_level.notReady {
						unsafe { goto c2v_for_next_178
						 }
					}
				}
			}
			if i_loop == 1 && !sqlite3_expr_covered_by_index(pe, p_level.iTabCur, p_idx) {
				i_next = 2
				unsafe { goto c2v_for_next_178
				 }
			}
			if i_loop < 3 && (int(p_term.wtFlags) & 4096) {
				if i_next == 0 {
					i_next = 3
				}
				unsafe { goto c2v_for_next_178
				 }
			}
			if (int(p_term.wtFlags) & 512) != 0 {
				x := p_level.iLikeRepCntr
				if x > u32(0) {
					skip_like_addr = sqlite3_vdbe_add_op1(v, if (x & u32(1)) { 17 } else { 16 }, int((x >> 1)))
					0
					0
				}
			}
			sqlite3_expr_if_false(p_parse, pe, addr_cont, 16)
			if skip_like_addr {
				sqlite3_vdbe_jump_here(v, skip_like_addr)
			}
			p_term.wtFlags |= 4
			c2v_for_next_178:
			c2v_pointer_postfix(voidptr(&p_term), p_term, isize(1))
		}
		i_loop = i_next
		if !(i_loop > 0) {
			break
		}
	}
	p_term = pwc.a
	for j = pwc.nBase; j > 0; j-- {
		pe := &Expr(0)
		sea_lt := Expr{}

		p_alt := &WhereTerm(0)
		if int(p_term.wtFlags) & (2 | 4) {
			unsafe { goto c2v_for_next_179
			 }
		}
		if (int(p_term.eOperator) & (2 | 128)) == 0 {
			unsafe { goto c2v_for_next_179
			 }
		}
		if (int(p_term.eOperator) & 2048) == 0 {
			unsafe { goto c2v_for_next_179
			 }
		}
		if p_term.leftCursor != i_cur {
			unsafe { goto c2v_for_next_179
			 }
		}
		if int(p_tab_item.fg.jointype) & (8 | 64 | 16) {
			unsafe { goto c2v_for_next_179
			 }
		}
		pe = p_term.pExpr
		p_alt = sqlite3_where_find_term(pwc, i_cur, p_term.u.x.leftColumn, not_ready, u32(2 | 1 | 128), unsafe { nil })
		if usize(p_alt) == usize(0) {
			unsafe { goto c2v_for_next_179
			 }
		}
		if int(p_alt.wtFlags) & 4 {
			unsafe { goto c2v_for_next_179
			 }
		}
		if ((p_alt.pExpr.flags & u32(512)) != u32(0)) {
			unsafe { goto c2v_for_next_179
			 }
		}
		if (int(p_alt.eOperator) & 1) && ((p_alt.pExpr.flags & u32(4096)) != u32(0)) && (p_alt.pExpr.x.pSelect.pEList.nExpr > 1) {
			unsafe { goto c2v_for_next_179
			 }
		}
		0
		0
		0
		0
		sea_lt = unsafe { *p_alt.pExpr }
		sea_lt.pLeft = pe.pLeft
		sqlite3_expr_if_false(p_parse, &sea_lt, addr_cont, 16)
		p_alt.wtFlags |= 4
		c2v_for_next_179:
		c2v_pointer_postfix(voidptr(&p_term), p_term, isize(1))
	}
	if p_level.pRJ {
		p_tab := &Table(0)
		n_pk := 0
		r := 0
		jmp1 := 0
		prj := p_level.pRJ
		p_tab = c2v_at(&pwi_nfo.pTabList.a[0], isize(p_level.iFrom)).pSTab
		if ((p_tab.tabFlags & u32(128)) == u32(0)) {
			r = sqlite3_get_temp_range(p_parse, 2)
			sqlite3_expr_code_get_column_of_table(v, p_tab, p_level.iTabCur, -1, r + 1)
			n_pk = 1
		} else {
			i_pk := 0
			p_pk := sqlite3_primary_key_index(p_tab)
			n_pk = int(p_pk.nKeyCol)
			r = sqlite3_get_temp_range(p_parse, n_pk + 1)
			for i_pk = 0; i_pk < n_pk; i_pk++ {
				i_col := int(p_pk.aiColumn[i_pk])
				sqlite3_expr_code_get_column_of_table(v, p_tab, i_cur, i_col, r + 1 + i_pk)
			}
		}
		jmp1 = sqlite3_vdbe_add_op4_int(v, 29, prj.iMatch, 0, r + 1, n_pk)
		0
		0
		sqlite3_vdbe_add_op3(v, 99, r + 1, n_pk, r)
		sqlite3_vdbe_add_op4_int(v, 140, prj.iMatch, r, r + 1, n_pk)
		sqlite3_vdbe_add_op4_int(v, 185, prj.regBloom, 0, r + 1, n_pk)
		sqlite3_vdbe_change_p5(v, U16(16))
		sqlite3_vdbe_jump_here(v, jmp1)
		sqlite3_release_temp_range(p_parse, r, n_pk + 1)
	}
	if p_level.iLeftJoin {
		p_level.addrFirst = sqlite3_vdbe_current_addr(v)
		sqlite3_vdbe_add_op2(v, 73, 1, p_level.iLeftJoin)
		0
		if usize(p_level.pRJ) == usize(0) {
			unsafe { goto code_outer_join_constraints
			 }
		}
	}
	if p_level.pRJ {
		prj := p_level.pRJ
		sqlite3_vdbe_add_op2(v, 76, 0, prj.regReturn)
		prj.addrSubrtn = sqlite3_vdbe_current_addr(v)
		p_parse.withinRJSubrtn++
		code_outer_join_constraints:
		p_term = pwc.a
		for j = 0; j < pwc.nBase; j++ {
			0
			0
			if int(p_term.wtFlags) & (2 | 4) {
				unsafe { goto c2v_for_next_180
				 }
			}
			if (p_term.prereqAll & p_level.notReady) != Bitmask(0) {
				unsafe { goto c2v_for_next_180
				 }
			}
			if int(p_tab_item.fg.jointype) & 64 {
				unsafe { goto c2v_for_next_180
				 }
			}
			sqlite3_expr_if_false(p_parse, p_term.pExpr, addr_cont, 16)
			p_term.wtFlags |= 4
			c2v_for_next_180:
			c2v_pointer_postfix(voidptr(&p_term), p_term, isize(1))
		}
	}
	return p_level.notReady
}

@[c:'sqlite3WhereRightJoinLoop']
fn sqlite3_where_right_join_loop(pwi_nfo &WhereInfo, i_level int, p_level &WhereLevel) {
	p_parse := pwi_nfo.pParse
	v := p_parse.pVdbe
	prj := p_level.pRJ
	p_sub_where := unsafe { &Expr(nil) }
	pwc := &pwi_nfo.sWC
	p_sub_wi_nfo := &WhereInfo(0)
	p_loop := p_level.pWLoop
	p_tab_item := unsafe { &pwi_nfo.pTabList.a[0] + p_level.iFrom }
	p_from := &SrcList(0)
	u_src := AnonStruct_166920{}

	m_all := Bitmask(0)
	k := 0
	sqlite3_vdbe_explain(p_parse, U8(1), c'RIGHT-JOIN %s', voidptr(p_tab_item.pSTab.zName))
	0
	for k = 0; k < i_level; k++ {
		i_idx_cur := 0
		p_right := &SrcItem(0)
		p_right = unsafe { &pwi_nfo.pTabList.a[0] + c2v_at(&pwi_nfo.a[0], isize(k)).iFrom }
		m_all |= c2v_at(&pwi_nfo.a[0], isize(k)).pWLoop.maskSelf
		if p_right.fg.viaCoroutine {
			p_subq := &Subquery(0)
			p_subq = p_right.u4.pSubq
			sqlite3_vdbe_add_op3(v, 77, 0, p_subq.regResult, p_subq.regResult + p_subq.pSelect.pEList.nExpr - 1)
		}
		sqlite3_vdbe_add_op1(v, 138, c2v_at(&pwi_nfo.a[0], isize(k)).iTabCur)
		i_idx_cur = c2v_at(&pwi_nfo.a[0], isize(k)).iIdxCur
		if i_idx_cur {
			sqlite3_vdbe_add_op1(v, 138, i_idx_cur)
		}
	}
	if (int(p_tab_item.fg.jointype) & 64) == 0 {
		m_all |= p_loop.maskSelf
		for k = 0; k < pwc.nTerm; k++ {
			p_term := unsafe { pwc.a + k }
			if (int(p_term.wtFlags) & (2 | 32768)) != 0 && int(p_term.eOperator) != 8192 {
				break
			}
			if p_term.prereqAll & ~m_all {
				continue
			}
			if ((p_term.pExpr.flags & u32((1 | 2))) != u32(0)) {
				continue
			}
			p_sub_where = sqlite3_expr_and(p_parse, p_sub_where, sqlite3_expr_dup(p_parse.db, p_term.pExpr, 0))
		}
	}
	if p_level.iIdxCur {
		sqlite3_vdbe_add_op1(v, 138, p_level.iIdxCur)
	}
	p_from = &u_src.sSrc
	p_from.nSrc = 1
	p_from.nAlloc = u32(1)
	C.memcpy(voidptr(unsafe { &p_from.a[0] + 0 }), voidptr(p_tab_item), sizeof(SrcItem))
	mut __c2v_lhs_tmp_167 := c2v_at(&p_from.a[0], isize(0))
	__c2v_lhs_tmp_167.fg.jointype = U8(0)
	p_parse.withinRJSubrtn++
	p_sub_wi_nfo = sqlite3_where_begin(p_parse, p_from, p_sub_where, unsafe { nil }, unsafe { nil }, unsafe { nil }, U16(4096), 0)
	if p_sub_wi_nfo {
		i_cur := p_level.iTabCur
		r := c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		n_pk := 0
		jmp := 0
		addr_cont := sqlite3_where_continue_label(p_sub_wi_nfo)
		p_tab := p_tab_item.pSTab
		if ((p_tab.tabFlags & u32(128)) == u32(0)) {
			sqlite3_expr_code_get_column_of_table(v, p_tab, i_cur, -1, r)
			n_pk = 1
		} else {
			i_pk := 0
			p_pk := sqlite3_primary_key_index(p_tab)
			n_pk = int(p_pk.nKeyCol)
			p_parse.nMem += n_pk - 1
			for i_pk = 0; i_pk < n_pk; i_pk++ {
				i_col := int(p_pk.aiColumn[i_pk])
				sqlite3_expr_code_get_column_of_table(v, p_tab, i_cur, i_col, r + i_pk)
			}
		}
		jmp = sqlite3_vdbe_add_op4_int(v, 66, prj.regBloom, 0, r, n_pk)
		0
		sqlite3_vdbe_add_op4_int(v, 29, prj.iMatch, addr_cont, r, n_pk)
		0
		sqlite3_vdbe_jump_here(v, jmp)
		sqlite3_vdbe_add_op2(v, 10, prj.regReturn, prj.addrSubrtn)
		sqlite3_where_end(p_sub_wi_nfo)
	}
	sqlite3_expr_delete(p_parse.db, p_sub_where)
	sqlite3_vdbe_explain_pop(p_parse)
	p_parse.withinRJSubrtn--
}
