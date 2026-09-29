@[translated]
module main

@[c:'whereOrInfoDelete']
fn where_or_info_delete(db &Sqlite3, p &WhereOrInfo) {
	sqlite3_where_clause_clear(&p.wc)
	sqlite3_db_free(db, voidptr(p))
}

@[c:'whereAndInfoDelete']
fn where_and_info_delete(db &Sqlite3, p &WhereAndInfo) {
	sqlite3_where_clause_clear(&p.wc)
	sqlite3_db_free(db, voidptr(p))
}

@[c:'whereClauseInsert']
fn where_clause_insert(pwc &WhereClause, p &Expr, wt_flags U16) int {
	p_term := &WhereTerm(0)
	idx := 0
	0
	if pwc.nTerm >= pwc.nSlot {
		p_old := pwc.a
		db := pwc.pWInfo.pParse.db
		pwc.a = sqlite3_where_malloc(pwc.pWInfo, U64(sizeof(WhereTerm) * u64(pwc.nSlot) * u64(2)))
		if usize(pwc.a) == usize(0) {
			if int(wt_flags) & 1 {
				sqlite3_expr_delete(db, p)
			}
			pwc.a = p_old
			return 0
		}
		C.memcpy(voidptr(pwc.a), voidptr(p_old), sizeof(WhereTerm) * u64(pwc.nTerm))
		pwc.nSlot = pwc.nSlot * 2
	}
	p_term = unsafe { pwc.a + (c2v_assign[int](&idx, int(pwc.nTerm++))) }
	if (int(wt_flags) & 2) == 0 {
		pwc.nBase = pwc.nTerm
	}
	if !isnil(p) && ((p.flags & u32(524288)) != u32(0)) {
		p_term.truthProb = LogEst(int(sqlite3_log_est(U64(p.iTable))) - 270)
	} else {
		p_term.truthProb = LogEst(1)
	}
	p_term.pExpr = sqlite3_expr_skip_collate_and_likely(p)
	p_term.wtFlags = wt_flags
	p_term.pWC = pwc
	p_term.iParent = -1
	C.memset(voidptr(&p_term.eOperator), 0, sizeof(WhereTerm) - (u64(usize(__offsetof(WhereTerm, eOperator)))))
	return idx
}

@[c:'allowedOp']
fn allowed_op(op int) int {
	if op > 58 {
		return 0
	}
	if op >= 54 {
		return 1
	}
	return int(op == 50 || op == 51 || op == 45)
}

@[c:'exprCommute']
fn expr_commute(p_parse &Parse, p_expr &Expr) U16 {
	mut __c2v_condition_99 := false
	mut __c2v_condition_100 := false
	__c2v_condition_100 = int(p_expr.pLeft.op) == 177
	__c2v_condition_99 = __c2v_condition_100
	if !__c2v_condition_99 {
		mut __c2v_condition_101 := false
		__c2v_condition_101 = int(p_expr.pRight.op) == 177
		__c2v_condition_99 = __c2v_condition_101
	}
	if !__c2v_condition_99 {
		mut __c2v_condition_102 := false
		__c2v_condition_102 = usize(sqlite3_binary_compare_coll_seq(p_parse, p_expr.pLeft, p_expr.pRight)) != usize(sqlite3_binary_compare_coll_seq(p_parse, p_expr.pRight, p_expr.pLeft))
		__c2v_condition_99 = __c2v_condition_102
	}
	if __c2v_condition_99 {
		p_expr.flags ^= u32(1024)
	}
	t := p_expr.pRight
	p_expr.pRight = p_expr.pLeft
	p_expr.pLeft = t
	0
	if int(p_expr.op) >= 55 {
		p_expr.op = U8(((int(p_expr.op) - 55) ^ 2) + 55)
	}
	return U16(0)
}

@[c:'operatorMask']
fn operator_mask(op int) U16 {
	c := U16(0)
	if op >= 54 {
		c = U16((2 << (op - 54)))
	} else if op == 50 {
		c = U16(1)
	} else if op == 51 {
		c = U16(256)
	} else {
		c = U16(128)
	}
	return c
}

@[c:'isLikeOrGlob']
fn is_like_or_glob(p_parse &Parse, p_expr &Expr, pp_prefix &&Expr, pis_complete &int, pno_case &int) int {
	z := unsafe { &U8(nil) }
	p_right := &Expr(0)
	p_left := &Expr(0)

	p_list := &ExprList(0)
	c := U8(0)
	cnt := 0
	wc := [4]U8{}
	db := p_parse.db
	p_val := unsafe { &Sqlite3_value(nil) }
	op := 0
	rc := 0
	if !sqlite3_is_like_function(db, p_expr, pno_case, unsafe { &i8(&wc[0]) }) {
		return 0
	}
	p_list = p_expr.x.pList
	p_left = c2v_at(&p_list.a[0], isize(1)).pExpr
	p_right = sqlite3_expr_skip_collate(c2v_at(&p_list.a[0], isize(0)).pExpr)
	op = int(p_right.op)
	if op == 157 && (db.flags & U64(8388608)) == U64(0) {
		p_reprepare := p_parse.pReprepare
		i_col := int(p_right.iColumn)
		p_val = sqlite3_vdbe_get_bound_value(p_reprepare, i_col, U8(65))
		if !isnil(p_val) && sqlite3_value_type(p_val) == 3 {
			z = sqlite3_value_text(p_val)
		}
		sqlite3_vdbe_set_varmask(p_parse.pVdbe, i_col)
	} else if op == 118 {
		z = &U8(voidptr(p_right.u.zToken))
	}
	if z {
		cnt = 0
		for {
			c = z[cnt]
			if !(int(c) != 0 && int(c) != int(wc[0]) && int(c) != int(wc[1]) && int(c) != int(wc[2])) {
				break
			}
			cnt++
			if int(c) == int(wc[3]) && int(z[cnt]) > 0 && int(z[cnt]) < 128 {
				cnt++
			} else if int(c) >= 128 {
				z2 := z + cnt - 1
				if int(c) == 255 || sqlite3_utf8_read(&&U8(&&U8(c2v_address_of(&z2)))) == u32(65533) || int(db.enc) == 2 {
					cnt--
					break
				} else {
					cnt = int((i64((isize(z2) - isize(z)) / isize(sizeof(U8)))))
				}
			}
		}
		if (cnt > 1 || (cnt > 0 && int(z[0]) != int(wc[3]))) && (255 != int(U8(z[cnt - 1]))) {
			p_prefix := &Expr(0)
			unsafe { *pis_complete = int(c) == int(wc[0]) && int(z[cnt + 1]) == 0 && int(db.enc) != 2 }
			p_prefix = sqlite3_expr(db, 118, &i8(voidptr(z)))
			if p_prefix {
				i_from := 0
				i_to := 0

				z_new := &i8(0)
				z_new = p_prefix.u.zToken
				z_new[cnt] = i8(0)
				i_to = 0
				for i_from = 0; i_from < cnt; i_from++ {
					if int(z_new[i_from]) == int(wc[3]) {
						i_from++
					}
					z_new[i_to++] = z_new[i_from]
				}
				z_new[i_to] = i8(0)
				if int(p_left.op) != 168 || int(sqlite3_expr_affinity(p_left)) != 66 || (((p_left.flags & u32((16777216 | 33554432))) == u32(0)) && !isnil(p_left.y.pTab) && (int(p_left.y.pTab.eTabType) == 1)) {
					is_num := 0
					r_dummy := 0.0
					is_num = sqlite3_ato_f(z_new, &r_dummy)
					if is_num <= 0 {
						if i_to == 1 && int(z_new[0]) == i8(`-`) {
							is_num = 1
						} else {
							z_new[i_to - 1]++
							is_num = sqlite3_ato_f(z_new, &r_dummy)
							z_new[i_to - 1]--
						}
					}
					if is_num > 0 {
						sqlite3_expr_delete(db, p_prefix)
						sqlite3_value_free_vdup7(p_val)
						return 0
					}
				}
			}
			unsafe { *pp_prefix = p_prefix }
			if op == 157 {
				v := p_parse.pVdbe
				sqlite3_vdbe_set_varmask(v, int(p_right.iColumn))
				if (unsafe { *pis_complete }) && int(p_right.u.zToken[1]) {
					r1 := sqlite3_get_temp_reg(p_parse)
					sqlite3_expr_code_target(p_parse, p_right, r1)
					sqlite3_vdbe_change_p3(v, sqlite3_vdbe_current_addr(v) - 1, 0)
					sqlite3_release_temp_reg(p_parse, r1)
				}
			}
		} else {
			z = 0
		}
	}
	rc = (usize(z) != usize(0))
	sqlite3_value_free_vdup7(p_val)
	return rc
}

@[c:'sqlite3ExprIsLikeOperator']
fn sqlite3_expr_is_like_operator(p_expr &Expr) int {
	if !sqlite3_expr_is_like_operator_a_op_inited {
		c2v_static_init := [AnonStruct_167375{
			zOp: c'match'
			eOp: u8(64)
		}, AnonStruct_167375{
			zOp: c'glob'
			eOp: u8(66)
		}, AnonStruct_167375{
			zOp: c'like'
			eOp: u8(65)
		}, AnonStruct_167375{
			zOp: c'regexp'
			eOp: u8(67)
		}]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_expr_is_like_operator_a_op[c2v_i_0] = c2v_element_0
		}
		sqlite3_expr_is_like_operator_a_op_inited = true
	}

	i := 0
	for i = 0; i < 4; i++ {
		if sqlite3_str_ic_mp(p_expr.u.zToken, sqlite3_expr_is_like_operator_a_op[i].zOp) == 0 {
			return int(sqlite3_expr_is_like_operator_a_op[i].eOp)
		}
	}
	return 0
}

@[c:'isAuxiliaryVtabOperator']
fn is_auxiliary_vtab_operator(db &Sqlite3, p_expr &Expr, pe_op2 &u8, pp_left &&Expr, pp_right &&Expr) int {
	if int(p_expr.op) == 172 {
		p_list := &ExprList(0)
		p_col := &Expr(0)
		i := 0
		p_list = p_expr.x.pList
		if usize(p_list) == usize(0) || p_list.nExpr != 2 {
			return 0
		}
		p_col = c2v_at(&p_list.a[0], isize(1)).pExpr
		if (int(p_col.op) == 168 && int(p_col.y.pTab.eTabType) == 1) && c2v_assign[int](unsafe { &i }, int(sqlite3_expr_is_like_operator(p_expr))) != 0 {
			unsafe { *pe_op2 = u8(i) }
			unsafe { *pp_right = c2v_at(&p_list.a[0], isize(0)).pExpr }
			unsafe { *pp_left = p_col }
			return 1
		}
		p_col = c2v_at(&p_list.a[0], isize(0)).pExpr
		if (int(p_col.op) == 168 && int(p_col.y.pTab.eTabType) == 1) {
			p_vtab := &Sqlite3_vtab(0)
			p_mod := &Sqlite3_module(0)
			x_not_used := C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			p_not_used := &voidptr(0)
			p_vtab = sqlite3_get_vt_able(db, p_col.y.pTab).pVtab
			p_mod = &Sqlite3_module(p_vtab.pModule)
			if !isnil(p_mod.xFindFunction) {
				i = p_mod.xFindFunction(p_vtab, 2, p_expr.u.zToken, &x_not_used, &p_not_used)
				if i >= 150 {
					unsafe { *pe_op2 = u8(i) }
					unsafe { *pp_right = c2v_at(&p_list.a[0], isize(1)).pExpr }
					unsafe { *pp_left = p_col }
					return 1
				}
			}
		}
	} else if int(p_expr.op) >= 54 {
		return 0
	} else if int(p_expr.op) == 53 || int(p_expr.op) == 46 || int(p_expr.op) == 52 {
		res := 0
		p_left := p_expr.pLeft
		p_right := p_expr.pRight
		if (int(p_left.op) == 168 && int(p_left.y.pTab.eTabType) == 1) {
			res++
		}
		if !isnil(p_right) && (int(p_right.op) == 168 && int(p_right.y.pTab.eTabType) == 1) {
			res++
			t := p_left
			p_left = p_right
			p_right = t
			0
		}
		unsafe { *pp_left = p_left }
		unsafe { *pp_right = p_right }
		if int(p_expr.op) == 53 {
			unsafe { *pe_op2 = u8(68) }
		}
		if int(p_expr.op) == 46 {
			unsafe { *pe_op2 = u8(69) }
		}
		if int(p_expr.op) == 52 {
			unsafe { *pe_op2 = u8(70) }
		}
		return res
	}
	return 0
}

@[c:'transferJoinMarkings']
fn transfer_join_markings(p_derived &Expr, p_base &Expr) {
	if !isnil(p_derived) && ((p_base.flags & u32((1 | 2))) != u32(0)) {
		p_derived.flags |= p_base.flags & u32((1 | 2))
		p_derived.w.iJoin = p_base.w.iJoin
	}
}

@[c:'markTermAsChild']
fn mark_term_as_child(pwc &WhereClause, i_child int, i_parent int) {
	pwc.a[i_child].iParent = i_parent
	pwc.a[i_child].truthProb = pwc.a[i_parent].truthProb
	unsafe { pwc.a[i_parent].nChild++ }
	0
}

@[c:'whereNthSubterm']
fn where_nth_subterm(p_term &WhereTerm, n int) &WhereTerm {
	if int(p_term.eOperator) != 1024 {
		return unsafe { if n == 0 { p_term } else { &WhereTerm(nil) } }
	}
	if n < p_term.u.pAndInfo.wc.nTerm {
		return unsafe { p_term.u.pAndInfo.wc.a + n }
	}
	return unsafe { nil }
}

@[c:'whereCombineDisjuncts']
fn where_combine_disjuncts(p_src &SrcList, pwc &WhereClause, p_one &WhereTerm, p_two &WhereTerm) {
	e_op := U16(int(p_one.eOperator) | int(p_two.eOperator))
	db := &Sqlite3(0)
	p_new := &Expr(0)
	op := 0
	idx_new := 0
	pa := &Expr(0)
	pb := &Expr(0)

	if (int(p_one.wtFlags) | int(p_two.wtFlags)) & 128 {
		return
	}
	if (int(p_one.eOperator) & (2 | (2 << (57 - 54)) | (2 << (56 - 54)) | (2 << (55 - 54)) | (2 << (58 - 54)))) == 0 {
		return
	}
	if (int(p_two.eOperator) & (2 | (2 << (57 - 54)) | (2 << (56 - 54)) | (2 << (55 - 54)) | (2 << (58 - 54)))) == 0 {
		return
	}
	if (int(e_op) & (2 | (2 << (57 - 54)) | (2 << (56 - 54)))) != int(e_op) && (int(e_op) & (2 | (2 << (55 - 54)) | (2 << (58 - 54)))) != int(e_op) {
		return
	}
	pa = p_one.pExpr
	pb = p_two.pExpr
	if sqlite3_expr_compare(unsafe { nil }, pa.pLeft, pb.pLeft, -1) {
		return
	}
	if sqlite3_expr_compare(unsafe { nil }, pa.pRight, pb.pRight, -1) {
		return
	}
	if ((pa.flags & u32(1024)) != u32(0)) != ((pb.flags & u32(1024)) != u32(0)) {
		return
	}
	if (int(e_op) & (int(e_op) - 1)) != 0 {
		if int(e_op) & ((2 << (57 - 54)) | (2 << (56 - 54))) {
			e_op = U16((2 << (56 - 54)))
		} else {
			e_op = U16((2 << (58 - 54)))
		}
	}
	db = pwc.pWInfo.pParse.db
	p_new = sqlite3_expr_dup(db, pa, 0)
	if usize(p_new) == usize(0) {
		return
	}
	for op = 54; int(e_op) != (2 << (op - 54)); op++ {
	}
	p_new.op = U8(op)
	idx_new = where_clause_insert(pwc, p_new, U16(2 | 1))
	expr_analyze(p_src, pwc, idx_new)
}

@[c:'exprAnalyzeOrTerm']
fn expr_analyze_or_term(p_src &SrcList, pwc &WhereClause, idx_term int) {
	pwi_nfo := pwc.pWInfo
	p_parse := pwi_nfo.pParse
	db := p_parse.db
	p_term := unsafe { pwc.a + idx_term }
	p_expr := p_term.pExpr
	i := 0
	p_or_wc := &WhereClause(0)
	p_or_term := &WhereTerm(0)
	p_or_info := &WhereOrInfo(0)
	chng_to_in := Bitmask(0)
	indexable := Bitmask(0)
	p_or_info = sqlite3_db_malloc_zero(db, U64(sizeof(WhereOrInfo)))
	p_term.u.pOrInfo = p_or_info
	if usize(p_or_info) == usize(0) {
		return
	}
	p_term.wtFlags |= 16
	p_or_wc = &p_or_info.wc
	C.memset(p_or_wc.aStatic, 0, sizeof([8]WhereTerm))
	sqlite3_where_clause_init(p_or_wc, pwi_nfo)
	sqlite3_where_split(p_or_wc, p_expr, U8(43))
	sqlite3_where_expr_analyze(p_src, p_or_wc)
	if db.mallocFailed {
		return
	}
	indexable = ~Bitmask(0)
	chng_to_in = ~Bitmask(0)
	i = p_or_wc.nTerm - 1
	for p_or_term = p_or_wc.a; i >= 0 && indexable; i-- {
		if (int(p_or_term.eOperator) & 511) == 0 {
			p_and_info := &WhereAndInfo(0)
			chng_to_in = Bitmask(0)
			p_and_info = sqlite3_db_malloc_raw_nn(db, U64(sizeof(WhereAndInfo)))
			if p_and_info {
				p_and_wc := &WhereClause(0)
				p_and_term := &WhereTerm(0)
				j := 0
				b := Bitmask(0)
				p_or_term.u.pAndInfo = p_and_info
				p_or_term.wtFlags |= 32
				p_or_term.eOperator = U16(1024)
				p_or_term.leftCursor = -1
				p_and_wc = &p_and_info.wc
				C.memset(p_and_wc.aStatic, 0, sizeof([8]WhereTerm))
				sqlite3_where_clause_init(p_and_wc, pwc.pWInfo)
				sqlite3_where_split(p_and_wc, p_or_term.pExpr, U8(44))
				sqlite3_where_expr_analyze(p_src, p_and_wc)
				p_and_wc.pOuter = pwc
				if !db.mallocFailed {
					j = 0
					for p_and_term = p_and_wc.a; j < p_and_wc.nTerm; j++ {
						if allowed_op(int(p_and_term.pExpr.op)) || int(p_and_term.eOperator) == 64 {
							b |= sqlite3_where_get_mask(&pwi_nfo.sMaskSet, p_and_term.leftCursor)
						}
						c2v_pointer_postfix(voidptr(&p_and_term), p_and_term, isize(1))
					}
				}
				indexable &= b
			}
		} else if int(p_or_term.wtFlags) & 8 {
		} else {
			b := Bitmask(0)
			b = sqlite3_where_get_mask(&pwi_nfo.sMaskSet, p_or_term.leftCursor)
			if int(p_or_term.wtFlags) & 2 {
				p_other := unsafe { p_or_wc.a + p_or_term.iParent }
				b |= sqlite3_where_get_mask(&pwi_nfo.sMaskSet, p_other.leftCursor)
			}
			indexable &= b
			if (int(p_or_term.eOperator) & 2) == 0 {
				chng_to_in = Bitmask(0)
			} else {
				chng_to_in &= b
			}
		}
		c2v_pointer_postfix(voidptr(&p_or_term), p_or_term, isize(1))
	}
	p_or_info.indexable = indexable
	p_term.eOperator = U16(512)
	p_term.leftCursor = -1
	if indexable {
		pwc.hasOr = U8(1)
	}
	if indexable && p_or_wc.nTerm == 2 {
		i_one := 0
		p_one := &WhereTerm(0)
		for {
			p_one = where_nth_subterm(unsafe { p_or_wc.a + 0 }, i_one++)
			if !(usize(p_one) != usize(0)) {
				break
			}
			i_two := 0
			p_two := &WhereTerm(0)
			for {
				p_two = where_nth_subterm(unsafe { p_or_wc.a + 1 }, i_two++)
				if !(usize(p_two) != usize(0)) {
					break
				}
				where_combine_disjuncts(p_src, pwc, p_one, p_two)
			}
		}
	}
	if chng_to_in {
		ok_to_chng_to_in := 0
		i_column := -1
		i_cursor := -1
		j := 0
		for j = 0; j < 2 && !ok_to_chng_to_in; j++ {
			p_left := unsafe { &Expr(nil) }
			p_or_term = p_or_wc.a
			for i = p_or_wc.nTerm - 1; i >= 0; i-- {
				p_or_term.wtFlags &= ~64
				if p_or_term.leftCursor == i_cursor {
					unsafe { goto c2v_for_next_183
					 }
				}
				if (chng_to_in & sqlite3_where_get_mask(&pwi_nfo.sMaskSet, p_or_term.leftCursor)) == Bitmask(0) {
					0
					0
					unsafe { goto c2v_for_next_183
					 }
				}
				i_column = p_or_term.u.x.leftColumn
				i_cursor = p_or_term.leftCursor
				p_left = p_or_term.pExpr.pLeft
				break

				c2v_for_next_183:
				c2v_pointer_postfix(voidptr(&p_or_term), p_or_term, isize(1))
			}
			if i < 0 {
				break
			}
			0
			ok_to_chng_to_in = 1
			for ; i >= 0 && ok_to_chng_to_in; i-- {
				if p_or_term.leftCursor != i_cursor {
					p_or_term.wtFlags &= ~64
				} else if p_or_term.u.x.leftColumn != i_column || (i_column == (-2) && sqlite3_expr_compare(p_parse, p_or_term.pExpr.pLeft, p_left, -1)) {
					ok_to_chng_to_in = 0
				} else {
					aff_left := 0
					aff_right := 0

					aff_right = int(sqlite3_expr_affinity(p_or_term.pExpr.pRight))
					aff_left = int(sqlite3_expr_affinity(p_or_term.pExpr.pLeft))
					if aff_right != 0 && aff_right != aff_left {
						ok_to_chng_to_in = 0
					} else {
						p_or_term.wtFlags |= 64
					}
				}
				c2v_pointer_postfix(voidptr(&p_or_term), p_or_term, isize(1))
			}
		}
		if ok_to_chng_to_in {
			p_dup := &Expr(0)
			p_list := unsafe { &ExprList(nil) }
			p_left := unsafe { &Expr(nil) }
			p_new := &Expr(0)
			i = p_or_wc.nTerm - 1
			for p_or_term = p_or_wc.a; i >= 0; i-- {
				if (int(p_or_term.wtFlags) & 64) == 0 {
					unsafe { goto c2v_for_next_185
					 }
				}
				p_dup = sqlite3_expr_dup(db, p_or_term.pExpr.pRight, 0)
				p_list = sqlite3_expr_list_append(pwi_nfo.pParse, p_list, p_dup)
				p_left = p_or_term.pExpr.pLeft
				c2v_for_next_185:
				c2v_pointer_postfix(voidptr(&p_or_term), p_or_term, isize(1))
			}
			p_dup = sqlite3_expr_dup(db, p_left, 0)
			p_new = sqlite3_pe_xpr(p_parse, 50, p_dup, unsafe { nil })
			if p_new {
				idx_new := 0
				transfer_join_markings(p_new, p_expr)
				p_new.x.pList = p_list
				idx_new = where_clause_insert(pwc, p_new, U16(2 | 1))
				0
				expr_analyze(p_src, pwc, idx_new)
				mark_term_as_child(pwc, idx_new, idx_term)
			} else {
				sqlite3_expr_list_delete(db, p_list)
			}
		}
	}
}

@[c:'termIsEquivalence']
fn term_is_equivalence(p_parse &Parse, p_expr &Expr, p_src &SrcList) int {
	aff1 := i8(0)
	aff2 := i8(0)

	if !((p_parse.db.dbOptFlags & u32(128)) == u32(0)) {
		return 0
	}
	if int(p_expr.op) != 54 && int(p_expr.op) != 45 {
		return 0
	}
	if ((p_expr.flags & u32((1 | 512))) != u32(0)) {
		return 0
	}
	if int(p_expr.op) == 45 && p_src.nSrc >= 2 && (int(c2v_at(&p_src.a[0], isize(0)).fg.jointype) & 64) != 0 {
		return 0
	}
	aff1 = sqlite3_expr_affinity(p_expr.pLeft)
	aff2 = sqlite3_expr_affinity(p_expr.pRight)
	if int(aff1) != int(aff2) && (!(int(aff1) >= 67) || !(int(aff2) >= 67)) {
		return 0
	}
	if !sqlite3_expr_coll_seq_match(p_parse, p_expr.pLeft, p_expr.pRight) {
		return 0
	}
	return 1
}

@[c:'exprSelectUsage']
fn expr_select_usage(p_mask_set &WhereMaskSet, ps &Select) Bitmask {
	mask := Bitmask(0)
	for ps {
		p_src := ps.pSrc
		mask |= sqlite3_where_expr_list_usage(p_mask_set, ps.pEList)
		mask |= sqlite3_where_expr_list_usage(p_mask_set, ps.pGroupBy)
		mask |= sqlite3_where_expr_list_usage(p_mask_set, ps.pOrderBy)
		mask |= sqlite3_where_expr_usage(p_mask_set, ps.pWhere)
		mask |= sqlite3_where_expr_usage(p_mask_set, ps.pHaving)
		if (usize(p_src) != usize(0)) {
			i := 0
			for i = 0; i < p_src.nSrc; i++ {
				if c2v_at(&p_src.a[0], isize(i)).fg.isSubquery {
					mask |= expr_select_usage(p_mask_set, c2v_at(&p_src.a[0], isize(i)).u4.pSubq.pSelect)
				}
				if int(c2v_at(&p_src.a[0], isize(i)).fg.isUsing) == 0 {
					mask |= sqlite3_where_expr_usage(p_mask_set, c2v_at(&p_src.a[0], isize(i)).u3.pOn)
				}
				if c2v_at(&p_src.a[0], isize(i)).fg.isTabFunc {
					mask |= sqlite3_where_expr_list_usage(p_mask_set, c2v_at(&p_src.a[0], isize(i)).u1.pFuncArg)
				}
			}
		}
		ps = ps.pPrior
	}
	return mask
}

@[c:'exprMightBeIndexed2']
fn expr_might_be_indexed2(p_from &SrcList, ai_cur_col &int, p_expr &Expr, j int) int {
	p_idx := &Index(0)
	i := 0
	i_cur := 0
	for {
		i_cur = c2v_at(&p_from.a[0], isize(j)).iCursor
		for p_idx = c2v_at(&p_from.a[0], isize(j)).pSTab.pIndex; p_idx; p_idx = p_idx.pNext {
			if usize(p_idx.aColExpr) == usize(0) {
				continue
			}
			for i = 0; i < int(p_idx.nKeyCol); i++ {
				if int(p_idx.aiColumn[i]) != (-2) {
					continue
				}
				if sqlite3_expr_compare_skip(p_expr, c2v_at(&p_idx.aColExpr.a[0], isize(i)).pExpr, i_cur) == 0 && !sqlite3_expr_is_constant(unsafe { nil }, c2v_at(&p_idx.aColExpr.a[0], isize(i)).pExpr) {
					ai_cur_col[0] = i_cur
					ai_cur_col[1] = (-2)
					return 1
				}
			}
		}
		j++
		if !(j < p_from.nSrc) {
			break
		}
	}
	return 0
}

@[c:'exprMightBeIndexed']
fn expr_might_be_indexed(p_from &SrcList, ai_cur_col &int, p_expr &Expr, op int) int {
	i := 0
	if int(p_expr.op) == 177 && (op >= 55 && (op <= 58)) {
		p_expr = c2v_at(&p_expr.x.pList.a[0], isize(0)).pExpr
	}
	if int(p_expr.op) == 168 {
		ai_cur_col[0] = p_expr.iTable
		ai_cur_col[1] = int(p_expr.iColumn)
		return 1
	}
	for i = 0; i < p_from.nSrc; i++ {
		p_idx := &Index(0)
		for p_idx = c2v_at(&p_from.a[0], isize(i)).pSTab.pIndex; p_idx; p_idx = p_idx.pNext {
			if p_idx.aColExpr {
				return expr_might_be_indexed2(p_from, ai_cur_col, p_expr, i)
			}
		}
	}
	return 0
}

@[c:'exprAnalyze']
fn expr_analyze(p_src &SrcList, pwc &WhereClause, idx_term int) {
	pwi_nfo := pwc.pWInfo
	p_term := &WhereTerm(0)
	p_mask_set := &WhereMaskSet(0)
	p_expr := &Expr(0)
	prereq_left := Bitmask(0)
	prereq_all := Bitmask(0)
	extra_right := Bitmask(0)
	p_str1 := unsafe { &Expr(nil) }
	is_complete := 0
	no_case := 0
	op := 0
	p_parse := pwi_nfo.pParse
	db := p_parse.db
	e_op2 := u8(0)
	n_left := 0
	if db.mallocFailed {
		return
	}
	p_term = unsafe { pwc.a + idx_term }
	p_mask_set = &pwi_nfo.sMaskSet
	p_expr = p_term.pExpr
	p_mask_set.bVarSelect = 0
	prereq_left = sqlite3_where_expr_usage(p_mask_set, p_expr.pLeft)
	op = int(p_expr.op)
	if op == 50 {
		if sqlite3_expr_check_in(p_parse, p_expr) {
			return
		}
		if ((p_expr.flags & u32(4096)) != u32(0)) {
			p_term.prereqRight = expr_select_usage(p_mask_set, p_expr.x.pSelect)
		} else {
			p_term.prereqRight = sqlite3_where_expr_list_usage(p_mask_set, p_expr.x.pList)
		}
		prereq_all = prereq_left | p_term.prereqRight
	} else {
		p_term.prereqRight = sqlite3_where_expr_usage(p_mask_set, p_expr.pRight)
		if usize(p_expr.pLeft) == usize(0) || ((p_expr.flags & u32((4096 | 262144))) != u32(0)) || usize(p_expr.x.pList) != usize(0) {
			prereq_all = sqlite3_where_expr_usage_nn(p_mask_set, p_expr)
		} else {
			prereq_all = prereq_left | p_term.prereqRight
		}
	}
	if p_mask_set.bVarSelect {
		p_term.wtFlags |= 4096
	}
	if ((p_expr.flags & u32((1 | 2))) != u32(0)) {
		x := sqlite3_where_get_mask(p_mask_set, p_expr.w.iJoin)
		if ((p_expr.flags & u32(1)) != u32(0)) {
			prereq_all |= x
			extra_right = x - Bitmask(1)
		} else if (prereq_all >> 1) >= x {
			p_expr.flags &= ~u32(2)
		}
	}
	p_term.prereqAll = prereq_all
	p_term.leftCursor = -1
	p_term.iParent = -1
	p_term.eOperator = U16(0)
	if allowed_op(op) {
		ai_cur_col := [2]int{}
		p_left := sqlite3_expr_skip_collate(p_expr.pLeft)
		p_right := sqlite3_expr_skip_collate(p_expr.pRight)
		op_mask := U16(if (p_term.prereqRight & prereq_left) == Bitmask(0) { 16383 } else { 2048 })
		if p_term.u.x.iField > 0 {
			p_left = c2v_at(&p_left.x.pList.a[0], isize(p_term.u.x.iField - 1)).pExpr
		}
		if expr_might_be_indexed(p_src, &ai_cur_col[0], p_left, op) {
			p_term.leftCursor = ai_cur_col[0]
			p_term.u.x.leftColumn = ai_cur_col[1]
			p_term.eOperator = U16(int(operator_mask(op)) & int(op_mask))
		}
		if op == 45 {
			p_term.wtFlags |= 2048
		}
		if !isnil(p_right) && expr_might_be_indexed(p_src, &ai_cur_col[0], p_right, op) && !((p_right.flags & u32(32)) != u32(0)) {
			p_new := &WhereTerm(0)
			p_dup := &Expr(0)
			e_extra_op := U16(0)
			if p_term.leftCursor >= 0 {
				idx_new := 0
				p_dup = sqlite3_expr_dup(db, p_expr, 0)
				if db.mallocFailed {
					sqlite3_expr_delete(db, p_dup)
					return
				}
				idx_new = where_clause_insert(pwc, p_dup, U16(2 | 1))
				if idx_new == 0 {
					return
				}
				p_new = unsafe { pwc.a + idx_new }
				mark_term_as_child(pwc, idx_new, idx_term)
				if op == 45 {
					p_new.wtFlags |= 2048
				}
				p_term = unsafe { pwc.a + idx_term }
				p_term.wtFlags |= 8
				if term_is_equivalence(p_parse, p_dup, pwi_nfo.pTabList) {
					p_term.eOperator |= 2048
					e_extra_op = U16(2048)
				}
			} else {
				p_dup = p_expr
				p_new = p_term
			}
			p_new.wtFlags |= int(expr_commute(p_parse, p_dup))
			p_new.leftCursor = ai_cur_col[0]
			p_new.u.x.leftColumn = ai_cur_col[1]
			0
			p_new.prereqRight = prereq_left | extra_right
			p_new.prereqAll = prereq_all
			p_new.eOperator = U16((int(operator_mask(int(p_dup.op))) + int(e_extra_op)) & int(op_mask))
		} else if op == 51 && !((p_expr.flags & u32(1)) != u32(0)) && 0 == sqlite3_expr_can_be_null(p_left) {
			p_expr.op = U8(171)
			p_expr.u.zToken = c'false'
			p_expr.flags |= u32(536870912)
			p_term.prereqAll = Bitmask(0)
			p_term.eOperator = U16(0)
		}
	} else if int(p_expr.op) == 49 && int(pwc.op) == 44 {
		p_list := &ExprList(0)
		i := 0
		if !expr_analyze_ops_inited {
			c2v_static_init := [U8(58), U8(56)]
			for c2v_i_0, c2v_element_0 in c2v_static_init {
				expr_analyze_ops[c2v_i_0] = c2v_element_0
			}
			expr_analyze_ops_inited = true
		}

		p_list = p_expr.x.pList
		for i = 0; i < 2; i++ {
			p_new_expr := &Expr(0)
			idx_new := 0
			p_new_expr = sqlite3_pe_xpr(p_parse, int(expr_analyze_ops[i]), sqlite3_expr_dup(db, p_expr.pLeft, 0), sqlite3_expr_dup(db, c2v_at(&p_list.a[0], isize(i)).pExpr, 0))
			transfer_join_markings(p_new_expr, p_expr)
			idx_new = where_clause_insert(pwc, p_new_expr, U16(2 | 1))
			0
			expr_analyze(p_src, pwc, idx_new)
			p_term = unsafe { pwc.a + idx_term }
			mark_term_as_child(pwc, idx_new, idx_term)
		}
	} else if int(p_expr.op) == 43 && !((p_expr.flags & u32(512)) != u32(0)) {
		expr_analyze_or_term(p_src, pwc, idx_term)
		p_term = unsafe { pwc.a + idx_term }
	} else if int(p_expr.op) == 52 {
		if int(p_expr.pLeft.op) == 168 && int(p_expr.pLeft.iColumn) >= 0 && !((p_expr.flags & u32(1)) != u32(0)) {
			p_new_expr := &Expr(0)
			p_left := p_expr.pLeft
			idx_new := 0
			p_new_term := &WhereTerm(0)
			p_new_expr = sqlite3_pe_xpr(p_parse, 55, sqlite3_expr_dup(db, p_left, 0), sqlite3_expr_alloc(db, 122, unsafe { nil }, 0))
			idx_new = where_clause_insert(pwc, p_new_expr, U16(2 | 1 | 128))
			if idx_new {
				p_new_term = unsafe { pwc.a + idx_new }
				p_new_term.prereqRight = Bitmask(0)
				p_new_term.leftCursor = p_left.iTable
				p_new_term.u.x.leftColumn = int(p_left.iColumn)
				p_new_term.eOperator = U16((2 << (55 - 54)))
				mark_term_as_child(pwc, idx_new, idx_term)
				p_term = unsafe { pwc.a + idx_term }
				p_term.wtFlags |= 8
				p_new_term.prereqAll = p_term.prereqAll
			}
		}
	} else if int(p_expr.op) == 172 && int(pwc.op) == 44 && is_like_or_glob(p_parse, p_expr, &&Expr(&&Expr(c2v_address_of(&p_str1))), &is_complete, &no_case) {
		p_left := &Expr(0)
		p_str2 := &Expr(0)
		p_new_expr1 := &Expr(0)
		p_new_expr2 := &Expr(0)
		idx_new1 := 0
		idx_new2 := 0
		z_coll_seq_name := &i8(0)
		wt_flags := U16(256 | 2 | 1)
		p_left = c2v_at(&p_expr.x.pList.a[0], isize(1)).pExpr
		p_str2 = sqlite3_expr_dup(db, p_str1, 0)
		if no_case && !p_parse.db.mallocFailed {
			i := 0
			c := i8(0)
			p_term.wtFlags |= 1024
			for i = 0; true; i++ {
				c = p_str1.u.zToken[i]
				if !(int(c) != 0) {
					break
				}
				p_str1.u.zToken[i] = i8((int(c) & ~(int(sqlite3CtypeMap[u8(c)]) & 32)))
				p_str2.u.zToken[i] = i8(sqlite3UpperToLower[u8(c)])
			}
		}
		if !db.mallocFailed {
			pc := &U8(0)
			pc = &U8(voidptr(unsafe { p_str2.u.zToken + (sqlite3_strlen30(p_str2.u.zToken) - 1) }))
			if no_case {
				if int((unsafe { *pc })) == int(`A`) - 1 {
					is_complete = 0
				}
				unsafe { *pc = sqlite3UpperToLower[*pc] }
			}
			for int((unsafe { *pc })) == 191 && usize(pc) > usize(&U8(voidptr(p_str2.u.zToken))) {
				unsafe { *pc = U8(128) }
				c2v_pointer_postfix(voidptr(&pc), pc, isize(-1))
			}
			unsafe { (*pc)++ }
		}
		z_coll_seq_name = if no_case { c'NOCASE' } else { &sqlite3StrBINARY[0] }
		p_new_expr1 = sqlite3_expr_dup(db, p_left, 0)
		p_new_expr1 = sqlite3_pe_xpr(p_parse, 58, sqlite3_expr_add_collate_string(p_parse, p_new_expr1, z_coll_seq_name), p_str1)
		transfer_join_markings(p_new_expr1, p_expr)
		idx_new1 = where_clause_insert(pwc, p_new_expr1, wt_flags)
		0
		p_new_expr2 = sqlite3_expr_dup(db, p_left, 0)
		p_new_expr2 = sqlite3_pe_xpr(p_parse, 57, sqlite3_expr_add_collate_string(p_parse, p_new_expr2, z_coll_seq_name), p_str2)
		transfer_join_markings(p_new_expr2, p_expr)
		idx_new2 = where_clause_insert(pwc, p_new_expr2, wt_flags)
		0
		expr_analyze(p_src, pwc, idx_new1)
		expr_analyze(p_src, pwc, idx_new2)
		p_term = unsafe { pwc.a + idx_term }
		if is_complete {
			mark_term_as_child(pwc, idx_new1, idx_term)
			mark_term_as_child(pwc, idx_new2, idx_term)
		}
	}
	mut __c2v_condition_103 := false
	mut __c2v_condition_104 := false
	__c2v_condition_104 = (int(p_expr.op) == 54 || int(p_expr.op) == 45)
	if __c2v_condition_104 {
		__c2v_condition_104 = c2v_assign[int](unsafe { &n_left }, int(sqlite3_expr_vector_size(p_expr.pLeft))) > 1
	}
	if __c2v_condition_104 {
		__c2v_condition_104 = sqlite3_expr_vector_size(p_expr.pRight) == n_left
	}
	if __c2v_condition_104 {
		__c2v_condition_104 = ((p_expr.pLeft.flags & u32(4096)) == u32(0) || (p_expr.pRight.flags & u32(4096)) == u32(0))
	}
	if __c2v_condition_104 {
		__c2v_condition_104 = int(pwc.op) == 44
	}
	__c2v_condition_103 = __c2v_condition_104
	if __c2v_condition_103 {
		i := 0
		for i = 0; i < n_left; i++ {
			idx_new := 0
			p_new := &Expr(0)
			p_left := sqlite3_expr_for_vector_field(p_parse, p_expr.pLeft, i, n_left)
			p_right := sqlite3_expr_for_vector_field(p_parse, p_expr.pRight, i, n_left)
			p_new = sqlite3_pe_xpr(p_parse, int(p_expr.op), p_left, p_right)
			transfer_join_markings(p_new, p_expr)
			idx_new = where_clause_insert(pwc, p_new, U16(1 | 32768))
			expr_analyze(p_src, pwc, idx_new)
		}
		p_term = unsafe { pwc.a + idx_term }
		p_term.wtFlags |= 4 | 2
		p_term.eOperator = U16(8192)
	} else if int(p_expr.op) == 50 && p_term.u.x.iField == 0 && int(p_expr.pLeft.op) == 177 && ((p_expr.flags & u32(4096)) != u32(0)) && (usize(p_expr.x.pSelect.pPrior) == usize(0) || (p_expr.x.pSelect.selFlags & u32(512))) && usize(p_expr.x.pSelect.pWin) == usize(0) && int(pwc.op) == 44 && I64(p_expr.x.pSelect.pEList.nExpr) <= (((I64(1)) << (sizeof(U8) * u64(8))) - I64(1)) {
		i := 0
		for i = 0; i < sqlite3_expr_vector_size(p_expr.pLeft); i++ {
			idx_new := 0
			idx_new = where_clause_insert(pwc, p_expr, U16(2 | 32768))
			pwc.a[idx_new].u.x.iField = i + 1
			expr_analyze(p_src, pwc, idx_new)
			mark_term_as_child(pwc, idx_new, idx_term)
		}
	} else if int(pwc.op) == 44 {
		p_right := unsafe { &Expr(nil) }
		p_left := unsafe { &Expr(nil) }

		res := is_auxiliary_vtab_operator(db, p_expr, &e_op2, &&Expr(&&Expr(c2v_address_of(&p_left))), &&Expr(&&Expr(c2v_address_of(&p_right))))
		for res-- > 0 {
			idx_new := 0
			p_new_term := &WhereTerm(0)
			prereq_column := Bitmask(0)
			prereq_expr := Bitmask(0)

			prereq_expr = sqlite3_where_expr_usage(p_mask_set, p_right)
			prereq_column = sqlite3_where_expr_usage(p_mask_set, p_left)
			if (prereq_expr & prereq_column) == Bitmask(0) {
				p_new_expr := &Expr(0)
				p_new_expr = sqlite3_pe_xpr(p_parse, 47, unsafe { nil }, sqlite3_expr_dup(db, p_right, 0))
				if ((p_expr.flags & u32(1)) != u32(0)) && !isnil(p_new_expr) {
					p_new_expr.flags |= u32(1)
					p_new_expr.w.iJoin = p_expr.w.iJoin
				}
				idx_new = where_clause_insert(pwc, p_new_expr, U16(2 | 1))
				0
				p_new_term = unsafe { pwc.a + idx_new }
				p_new_term.prereqRight = prereq_expr | extra_right
				p_new_term.leftCursor = p_left.iTable
				p_new_term.u.x.leftColumn = int(p_left.iColumn)
				p_new_term.eOperator = U16(64)
				p_new_term.eMatchOp = e_op2
				mark_term_as_child(pwc, idx_new, idx_term)
				p_term = unsafe { pwc.a + idx_term }
				p_term.wtFlags |= 8
				p_new_term.prereqAll = p_term.prereqAll
			}
			t := p_left
			p_left = p_right
			p_right = t
			0
		}
	}
	0
	p_term = unsafe { pwc.a + idx_term }
	p_term.prereqRight |= extra_right
}

@[c:'sqlite3WhereSplit']
fn sqlite3_where_split(pwc &WhereClause, p_expr &Expr, op U8) {
	p_e2 := sqlite3_expr_skip_collate_and_likely(p_expr)
	pwc.op = op
	if usize(p_e2) == usize(0) {
		return
	}
	if int(p_e2.op) != int(op) {
		where_clause_insert(pwc, p_expr, U16(0))
	} else {
		sqlite3_where_split(pwc, p_e2.pLeft, op)
		sqlite3_where_split(pwc, p_e2.pRight, op)
	}
}

@[c:'whereAddLimitExpr']
fn where_add_limit_expr(pwc &WhereClause, i_reg int, p_expr &Expr, i_csr int, e_match_op int) {
	p_parse := pwc.pWInfo.pParse
	db := p_parse.db
	p_new := &Expr(0)
	i_val := 0
	if sqlite3_expr_is_integer(p_expr, &i_val, p_parse) && i_val >= 0 {
		p_val := sqlite3_expr_int32(db, i_val)
		if usize(p_val) == usize(0) {
			return
		}
		p_new = sqlite3_pe_xpr(p_parse, 47, unsafe { nil }, p_val)
	} else {
		p_val := sqlite3_expr_alloc(db, 176, unsafe { nil }, 0)
		if usize(p_val) == usize(0) {
			return
		}
		p_val.iTable = i_reg
		p_new = sqlite3_pe_xpr(p_parse, 47, unsafe { nil }, p_val)
	}
	if p_new {
		p_term := &WhereTerm(0)
		idx := 0
		idx = where_clause_insert(pwc, p_new, U16(1 | 2))
		p_term = unsafe { pwc.a + idx }
		p_term.leftCursor = i_csr
		p_term.eOperator = U16(64)
		p_term.eMatchOp = U8(e_match_op)
	}
}

@[c:'sqlite3WhereAddLimit']
fn sqlite3_where_add_limit(pwc &WhereClause, p &Select) {
	if usize(p.pGroupBy) == usize(0) && (p.selFlags & u32((1 | 8))) == u32(0) && (p.pSrc.nSrc == 1 && (int(c2v_at(&p.pSrc.a[0], isize(0)).pSTab.eTabType) == 1)) {
		p_order_by := p.pOrderBy
		i_csr := c2v_at(&p.pSrc.a[0], isize(0)).iCursor
		ii := 0
		for ii = 0; ii < pwc.nTerm; ii++ {
			if int(pwc.a[ii].wtFlags) & 4 {
				continue
			}
			if pwc.a[ii].nChild {
				continue
			}
			if pwc.a[ii].leftCursor == i_csr && pwc.a[ii].prereqRight == Bitmask(0) {
				continue
			}
			if pwc.a[ii].iParent >= 0 {
				p_parent := unsafe { pwc.a + pwc.a[ii].iParent }
				if p_parent.leftCursor == i_csr && p_parent.prereqRight == Bitmask(0) && int(p_parent.nChild) == 1 {
					continue
				}
			}
			return
		}
		if p_order_by {
			for ii = 0; ii < p_order_by.nExpr; ii++ {
				p_expr := c2v_at(&p_order_by.a[0], isize(ii)).pExpr
				if int(p_expr.op) != 168 {
					return
				}
				if p_expr.iTable != i_csr {
					return
				}
				if int(c2v_at(&p_order_by.a[0], isize(ii)).fg.sortFlags) & 2 {
					return
				}
			}
		}
		if p.iOffset != 0 && (p.selFlags & u32(256)) == u32(0) {
			where_add_limit_expr(pwc, p.iOffset, p.pLimit.pRight, i_csr, 74)
		}
		if p.iOffset == 0 || (p.selFlags & u32(256)) == u32(0) {
			where_add_limit_expr(pwc, p.iLimit, p.pLimit.pLeft, i_csr, 73)
		}
	}
}

@[c:'sqlite3WhereClauseInit']
fn sqlite3_where_clause_init(pwc &WhereClause, pwi_nfo &WhereInfo) {
	pwc.pWInfo = pwi_nfo
	pwc.hasOr = U8(0)
	pwc.pOuter = 0
	pwc.nTerm = 0
	pwc.nBase = 0
	pwc.nSlot = 8
	pwc.a = unsafe { &pwc.aStatic[0] }
}

@[c:'sqlite3WhereClauseClear']
fn sqlite3_where_clause_clear(pwc &WhereClause) {
	db := pwc.pWInfo.pParse.db
	if pwc.nTerm > 0 {
		a := pwc.a
		a_last := unsafe { pwc.a + (pwc.nTerm - 1) }
		for {
			if int(a.wtFlags) & 1 {
				sqlite3_expr_delete(db, a.pExpr)
			}
			if int(a.wtFlags) & (16 | 32) {
				if int(a.wtFlags) & 16 {
					where_or_info_delete(db, a.u.pOrInfo)
				} else {
					where_and_info_delete(db, a.u.pAndInfo)
				}
			}
			if usize(a) == usize(a_last) {
				break
			}
			c2v_pointer_postfix(voidptr(&a), a, isize(1))
		}
	}
}

@[c:'sqlite3WhereExprUsageFull']
fn sqlite3_where_expr_usage_full(p_mask_set &WhereMaskSet, p &Expr) Bitmask {
	mask := Bitmask(0)
	mask = if (int(p.op) == 179) { sqlite3_where_get_mask(p_mask_set, p.iTable) } else { Bitmask(0) }
	if p.pLeft {
		mask |= sqlite3_where_expr_usage_nn(p_mask_set, p.pLeft)
	}
	if p.pRight {
		mask |= sqlite3_where_expr_usage_nn(p_mask_set, p.pRight)
	} else if ((p.flags & u32(4096)) != u32(0)) {
		if ((p.flags & u32(64)) != u32(0)) {
			p_mask_set.bVarSelect = 1
		}
		mask |= expr_select_usage(p_mask_set, p.x.pSelect)
	} else if p.x.pList {
		mask |= sqlite3_where_expr_list_usage(p_mask_set, p.x.pList)
	}
	if (int(p.op) == 172 || int(p.op) == 169) && ((p.flags & u32(16777216)) != u32(0)) {
		mask |= sqlite3_where_expr_list_usage(p_mask_set, p.y.pWin.pPartition)
		mask |= sqlite3_where_expr_list_usage(p_mask_set, p.y.pWin.pOrderBy)
		mask |= sqlite3_where_expr_usage(p_mask_set, p.y.pWin.pFilter)
	}
	return mask
}

@[c:'sqlite3WhereExprUsageNN']
fn sqlite3_where_expr_usage_nn(p_mask_set &WhereMaskSet, p &Expr) Bitmask {
	if int(p.op) == 168 && !((p.flags & u32(32)) != u32(0)) {
		return sqlite3_where_get_mask(p_mask_set, p.iTable)
	} else if ((p.flags & u32((65536 | 8388608))) != u32(0)) {
		return Bitmask(0)
	}
	return sqlite3_where_expr_usage_full(p_mask_set, p)
}

@[c:'sqlite3WhereExprUsage']
fn sqlite3_where_expr_usage(p_mask_set &WhereMaskSet, p &Expr) Bitmask {
	return if p { sqlite3_where_expr_usage_nn(p_mask_set, p) } else { Bitmask(0) }
}

@[c:'sqlite3WhereExprListUsage']
fn sqlite3_where_expr_list_usage(p_mask_set &WhereMaskSet, p_list &ExprList) Bitmask {
	i := 0
	mask := Bitmask(0)
	if p_list {
		for i = 0; i < p_list.nExpr; i++ {
			mask |= sqlite3_where_expr_usage(p_mask_set, c2v_at(&p_list.a[0], isize(i)).pExpr)
		}
	}
	return mask
}

@[c:'sqlite3WhereExprAnalyze']
fn sqlite3_where_expr_analyze(p_tab_list &SrcList, pwc &WhereClause) {
	i := 0
	for i = pwc.nTerm - 1; i >= 0; i-- {
		expr_analyze(p_tab_list, pwc, i)
	}
}

@[c:'sqlite3WhereTabFuncArgs']
fn sqlite3_where_tab_func_args(p_parse &Parse, p_item &SrcItem, pwc &WhereClause) {
	p_tab := &Table(0)
	j := 0
	k := 0

	p_args := &ExprList(0)
	p_col_ref := &Expr(0)
	p_term := &Expr(0)
	if int(p_item.fg.isTabFunc) == 0 {
		return
	}
	p_tab = p_item.pSTab
	p_args = p_item.u1.pFuncArg
	if usize(p_args) == usize(0) {
		return
	}
	k = 0
	for j = 0; j < p_args.nExpr; j++ {
		p_rhs := &Expr(0)
		join_type := u32(0)
		for k < int(p_tab.nCol) && (int(p_tab.aCol[k].colFlags) & 2) == 0 {
			k++
		}
		if k >= int(p_tab.nCol) {
			sqlite3_error_msg(p_parse, c'too many arguments on %s() - max %d', voidptr(p_tab.zName), j)
			return
		}
		p_col_ref = sqlite3_expr_alloc(p_parse.db, 168, unsafe { nil }, 0)
		if usize(p_col_ref) == usize(0) {
			return
		}
		p_col_ref.iTable = p_item.iCursor
		mut __c2v_postfix_value_40 := k
		k++
		p_col_ref.iColumn = __c2v_postfix_value_40
		p_col_ref.y.pTab = p_tab
		p_item.colUsed |= sqlite3_expr_col_used(p_col_ref)
		p_rhs = sqlite3_pe_xpr(p_parse, 173, sqlite3_expr_dup(p_parse.db, c2v_at(&p_args.a[0], isize(j)).pExpr, 0), unsafe { nil })
		p_term = sqlite3_pe_xpr(p_parse, 54, p_col_ref, p_rhs)
		if int(p_item.fg.jointype) & (8 | 16) {
			0
			0
			join_type = u32(1)
		} else {
			0
			join_type = u32(2)
		}
		sqlite3_set_join_expr(p_term, p_item.iCursor, join_type)
		where_clause_insert(pwc, p_term, U16(1))
	}
}
