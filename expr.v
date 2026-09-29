@[translated]
module main

@[c:'sqlite3TableColumnAffinity']
fn sqlite3_table_column_affinity(p_tab &Table, i_col int) i8 {
	if i_col < 0 || (i_col >= int(p_tab.nCol)) {
		return i8(68)
	}
	return p_tab.aCol[i_col].affinity
}

@[c:'sqlite3ExprAffinity']
fn sqlite3_expr_affinity(p_expr &Expr) i8 {
	op := 0
	op = int(p_expr.op)
	for {
		if op == 168 || (op == 170 && usize(p_expr.y.pTab) != usize(0)) {
			return sqlite3_table_column_affinity(p_expr.y.pTab, int(p_expr.iColumn))
		}
		if op == 139 {
			return sqlite3_expr_affinity(c2v_at(&p_expr.x.pSelect.pEList.a[0], isize(0)).pExpr)
		}
		if op == 36 {
			return sqlite3_affinity_type(p_expr.u.zToken, unsafe { nil })
		}
		if op == 178 {
			return sqlite3_expr_affinity(c2v_at(&p_expr.pLeft.x.pSelect.pEList.a[0], isize(p_expr.iColumn)).pExpr)
		}
		if op == 177 || (op == 172 && int(p_expr.affExpr) == 88) {
			return sqlite3_expr_affinity(c2v_at(&p_expr.x.pList.a[0], isize(0)).pExpr)
		}
		if ((p_expr.flags & u32((8192 | 262144))) != u32(0)) {
			p_expr = p_expr.pLeft
			op = int(p_expr.op)
			continue
		}
		if op != 176 {
			break
		}
		op = int(p_expr.op2)
		if (op == 176) {
			break
		}
	}
	return p_expr.affExpr
}

@[c:'sqlite3ExprDataType']
fn sqlite3_expr_data_type(p_expr &Expr) int {
	for p_expr {
		match p_expr.op {
			114, 179, 173 {
				p_expr = p_expr.pLeft
			}
			122 {
				p_expr = 0
			}
			118 {
				return 2
			}
			155 {
				return 4
			}
			112 {
				return 6
			}
			157, 169, 172 {
				return 7
			}
			168, 170, 139, 36, 178, 177 {
				aff := int(sqlite3_expr_affinity(p_expr))
				if aff >= 67 {
					return 5
				}
				if aff == 66 {
					return 6
				}
				return 7
			}
			158 {
				res := 0
				ii := 0
				p_list := p_expr.x.pList
				for ii = 1; ii < p_list.nExpr; ii += 2 {
					res |= sqlite3_expr_data_type(c2v_at(&p_list.a[0], isize(ii)).pExpr)
				}
				if p_list.nExpr % 2 {
					res |= sqlite3_expr_data_type(c2v_at(&p_list.a[0], isize(p_list.nExpr - 1)).pExpr)
				}
				return res
			}
			else {
				return 1
			}
		}
	}
	return 0
}

@[c:'sqlite3ExprAddCollateToken']
fn sqlite3_expr_add_collate_token(p_parse &Parse, p_expr &Expr, p_coll_name &Token, dequote int) &Expr {
	if p_coll_name.n > u32(0) {
		p_new := sqlite3_expr_alloc(p_parse.db, 114, p_coll_name, dequote)
		if p_new {
			p_new.pLeft = p_expr
			p_new.flags |= u32(512 | 8192)
			p_expr = p_new
		}
	}
	return p_expr
}

@[c:'sqlite3ExprAddCollateString']
fn sqlite3_expr_add_collate_string(p_parse &Parse, p_expr &Expr, zc &i8) &Expr {
	s := Token{}
	sqlite3_token_init(&s, &i8(zc))
	return sqlite3_expr_add_collate_token(p_parse, p_expr, &s, 0)
}

@[c:'sqlite3ExprSkipCollate']
fn sqlite3_expr_skip_collate(p_expr &Expr) &Expr {
	for !isnil(p_expr) && ((p_expr.flags & u32(8192)) != u32(0)) {
		p_expr = p_expr.pLeft
	}
	return p_expr
}

@[c:'sqlite3ExprSkipCollateAndLikely']
fn sqlite3_expr_skip_collate_and_likely(p_expr &Expr) &Expr {
	for !isnil(p_expr) && ((p_expr.flags & u32((8192 | 524288))) != u32(0)) {
		if ((p_expr.flags & u32(524288)) != u32(0)) {
			p_expr = c2v_at(&p_expr.x.pList.a[0], isize(0)).pExpr
		} else if int(p_expr.op) == 114 {
			p_expr = p_expr.pLeft
		} else {
			break
		}
	}
	return p_expr
}

@[c:'sqlite3ExprCollSeq']
fn sqlite3_expr_coll_seq(p_parse &Parse, p_expr &Expr) &CollSeq {
	db := p_parse.db
	p_coll := unsafe { &CollSeq(nil) }
	p := p_expr
	for p {
		op := int(p.op)
		if op == 176 {
			op = int(p.op2)
		}
		if (op == 170 && usize(p.y.pTab) != usize(0)) || op == 168 || op == 78 {
			j := 0
			j = int(p.iColumn)
			if j >= 0 {
				z_coll := sqlite3_column_coll(unsafe { p.y.pTab.aCol + j })
				p_coll = sqlite3_find_coll_seq(db, db.enc, z_coll, 0)
			}
			break
		}
		if op == 36 || op == 173 {
			p = p.pLeft
			continue
		}
		if op == 177 || (op == 172 && int(p.affExpr) == 88) {
			p = c2v_at(&p.x.pList.a[0], isize(0)).pExpr
			continue
		}
		if op == 114 {
			p_coll = sqlite3_get_coll_seq(p_parse, db.enc, unsafe { nil }, p.u.zToken)
			break
		}
		if p.flags & u32(512) {
			if !isnil(p.pLeft) && (p.pLeft.flags & u32(512)) != u32(0) {
				p = p.pLeft
			} else {
				p_next := p.pRight
				if ((p.flags & u32(4096)) == u32(0)) && usize(p.x.pList) != usize(0) && !db.mallocFailed {
					i := 0
					for i = 0; i < p.x.pList.nExpr; i++ {
						if ((c2v_at(&p.x.pList.a[0], isize(i)).pExpr.flags & u32(512)) != u32(0)) {
							p_next = c2v_at(&p.x.pList.a[0], isize(i)).pExpr
							break
						}
					}
				}
				p = p_next
			}
		} else {
			break
		}
	}
	if sqlite3_check_coll_seq(p_parse, p_coll) {
		p_coll = 0
	}
	return p_coll
}

@[c:'sqlite3ExprNNCollSeq']
fn sqlite3_expr_nn_coll_seq(p_parse &Parse, p_expr &Expr) &CollSeq {
	p := sqlite3_expr_coll_seq(p_parse, p_expr)
	if usize(p) == usize(0) {
		p = p_parse.db.pDfltColl
	}
	return p
}

@[c:'sqlite3ExprCollSeqMatch']
fn sqlite3_expr_coll_seq_match(p_parse &Parse, p_e1 &Expr, p_e2 &Expr) int {
	p_coll1 := sqlite3_expr_nn_coll_seq(p_parse, p_e1)
	p_coll2 := sqlite3_expr_nn_coll_seq(p_parse, p_e2)
	return int(sqlite3_str_ic_mp(p_coll1.zName, p_coll2.zName) == 0)
}

@[c:'sqlite3CompareAffinity']
fn sqlite3_compare_affinity(p_expr &Expr, aff2 i8) i8 {
	aff1 := sqlite3_expr_affinity(p_expr)
	if int(aff1) > 64 && int(aff2) > 64 {
		if (int(aff1) >= 67) || (int(aff2) >= 67) {
			return i8(67)
		} else {
			return i8(65)
		}
	} else {
		return i8((if int(aff1) <= 64 { int(aff2) } else { int(aff1) }) | 64)
	}
}

@[c:'comparisonAffinity']
fn comparison_affinity(p_expr &Expr) i8 {
	aff := i8(0)
	aff = sqlite3_expr_affinity(p_expr.pLeft)
	if p_expr.pRight {
		aff = sqlite3_compare_affinity(p_expr.pRight, i8(aff))
	} else if ((p_expr.flags & u32(4096)) != u32(0)) {
		aff = sqlite3_compare_affinity(c2v_at(&p_expr.x.pSelect.pEList.a[0], isize(0)).pExpr, i8(aff))
	} else if int(aff) == 0 {
		aff = i8(65)
	}
	return aff
}

@[c:'sqlite3IndexAffinityOk']
fn sqlite3_index_affinity_ok(p_expr &Expr, idx_affinity i8) int {
	aff := comparison_affinity(p_expr)
	if int(aff) < 66 {
		return 1
	}
	if int(aff) == 66 {
		return int(idx_affinity == 66)
	}
	return int((int(idx_affinity) >= 67))
}

@[c:'binaryCompareP5']
fn binary_compare_p5(p_expr1 &Expr, p_expr2 &Expr, jump_if_null int) U8 {
	aff := U8(i8(sqlite3_expr_affinity(p_expr2)))
	aff = U8(int(U8(sqlite3_compare_affinity(p_expr1, i8(aff)))) | int(U8(jump_if_null)))
	return aff
}

@[c:'sqlite3BinaryCompareCollSeq']
fn sqlite3_binary_compare_coll_seq(p_parse &Parse, p_left &Expr, p_right &Expr) &CollSeq {
	p_coll := &CollSeq(0)
	if p_left.flags & u32(512) {
		p_coll = sqlite3_expr_coll_seq(p_parse, p_left)
	} else if !isnil(p_right) && (p_right.flags & u32(512)) != u32(0) {
		p_coll = sqlite3_expr_coll_seq(p_parse, p_right)
	} else {
		p_coll = sqlite3_expr_coll_seq(p_parse, p_left)
		if isnil(p_coll) {
			p_coll = sqlite3_expr_coll_seq(p_parse, p_right)
		}
	}
	return p_coll
}

@[c:'sqlite3ExprCompareCollSeq']
fn sqlite3_expr_compare_coll_seq(p_parse &Parse, p &Expr) &CollSeq {
	if ((p.flags & u32(1024)) != u32(0)) {
		return sqlite3_binary_compare_coll_seq(p_parse, p.pRight, p.pLeft)
	} else {
		return sqlite3_binary_compare_coll_seq(p_parse, p.pLeft, p.pRight)
	}
}

@[c:'codeCompare']
fn code_compare(p_parse &Parse, p_left &Expr, p_right &Expr, opcode int, in1 int, in2 int, dest int, jump_if_null int, is_commuted int) int {
	p5 := 0
	addr := 0
	p4 := &CollSeq(0)
	if p_parse.nErr {
		return 0
	}
	if is_commuted {
		p4 = sqlite3_binary_compare_coll_seq(p_parse, p_right, p_left)
	} else {
		p4 = sqlite3_binary_compare_coll_seq(p_parse, p_left, p_right)
	}
	p5 = int(binary_compare_p5(p_left, p_right, jump_if_null))
	addr = sqlite3_vdbe_add_op4(p_parse.pVdbe, opcode, in2, dest, in1, &i8(voidptr(p4)), (-2))
	sqlite3_vdbe_change_p5(p_parse.pVdbe, U16(p5))
	return addr
}

@[c:'sqlite3ExprIsVector']
fn sqlite3_expr_is_vector(p_expr &Expr) int {
	return int(sqlite3_expr_vector_size(p_expr) > 1)
}

@[c:'sqlite3ExprVectorSize']
fn sqlite3_expr_vector_size(p_expr &Expr) int {
	op := p_expr.op
	if int(op) == 176 {
		op = p_expr.op2
	}
	if int(op) == 177 {
		return p_expr.x.pList.nExpr
	} else if int(op) == 139 {
		return p_expr.x.pSelect.pEList.nExpr
	} else {
		return 1
	}
}

@[c:'sqlite3VectorFieldSubexpr']
fn sqlite3_vector_field_subexpr(p_vector &Expr, i int) &Expr {
	if sqlite3_expr_is_vector(p_vector) {
		if int(p_vector.op) == 139 || int(p_vector.op2) == 139 {
			return c2v_at(&p_vector.x.pSelect.pEList.a[0], isize(i)).pExpr
		} else {
			return c2v_at(&p_vector.x.pList.a[0], isize(i)).pExpr
		}
	}
	return p_vector
}

@[c:'sqlite3ExprForVectorField']
fn sqlite3_expr_for_vector_field(p_parse &Parse, p_vector &Expr, i_field int, n_field int) &Expr {
	p_ret := &Expr(0)
	if int(p_vector.op) == 139 {
		p_ret = sqlite3_pe_xpr(p_parse, 178, unsafe { nil }, unsafe { nil })
		if p_ret {
			p_ret.flags |= u32(131072)
			p_ret.iTable = n_field
			p_ret.iColumn = YnVar(i_field)
			p_ret.pLeft = p_vector
		}
	} else {
		if int(p_vector.op) == 177 {
			pp_vector := &&Expr(0)
			pp_vector = &c2v_at(&p_vector.x.pList.a[0], isize(i_field)).pExpr
			p_vector = unsafe { *pp_vector }
			if (int(p_parse.eParseMode) >= 2) {
				unsafe { *pp_vector = 0 }
				return p_vector
			}
		}
		p_ret = sqlite3_expr_dup(p_parse.db, p_vector, 0)
	}
	return p_ret
}

@[c:'exprCodeSubselect']
fn expr_code_subselect(p_parse &Parse, p_expr &Expr) int {
	reg := 0
	if int(p_expr.op) == 139 {
		reg = sqlite3_code_subselect(p_parse, p_expr)
	}
	return reg
}

@[c:'exprVectorRegister']
fn expr_vector_register(p_parse &Parse, p_vector &Expr, i_field int, reg_select int, pp_expr &&Expr, p_reg_free &int) int {
	op := p_vector.op
	if int(op) == 176 {
		unsafe { *pp_expr = sqlite3_vector_field_subexpr(p_vector, i_field) }
		return p_vector.iTable + i_field
	}
	if int(op) == 139 {
		unsafe { *pp_expr = c2v_at(&p_vector.x.pSelect.pEList.a[0], isize(i_field)).pExpr }
		return reg_select + i_field
	}
	if int(op) == 177 {
		unsafe { *pp_expr = c2v_at(&p_vector.x.pList.a[0], isize(i_field)).pExpr }
		return sqlite3_expr_code_temp(p_parse, (unsafe { *pp_expr }), p_reg_free)
	}
	return 0
}

@[c:'codeVectorCompare']
fn code_vector_compare(p_parse &Parse, p_expr &Expr, dest int, op U8, p5 U8) {
	v := p_parse.pVdbe
	p_left := p_expr.pLeft
	p_right := p_expr.pRight
	n_left := sqlite3_expr_vector_size(p_left)
	i := 0
	reg_left := 0
	reg_right := 0
	opx := op
	addr_cmp := 0
	addr_done := sqlite3_vdbe_make_label(p_parse)
	is_commuted := int(((p_expr.flags & u32(1024)) != u32(0)))
	if p_parse.nErr {
		return
	}
	if n_left != sqlite3_expr_vector_size(p_right) {
		sqlite3_error_msg(p_parse, c'row value misused')
		return
	}
	if int(op) == 56 {
		opx = U8(57)
	}
	if int(op) == 58 {
		opx = U8(55)
	}
	if int(op) == 53 {
		opx = U8(54)
	}
	reg_left = expr_code_subselect(p_parse, p_left)
	reg_right = expr_code_subselect(p_parse, p_right)
	sqlite3_vdbe_add_op2(v, 73, 1, dest)
	for i = 0; 1; i++ {
		reg_free1 := 0
		reg_free2 := 0

		pl := unsafe { &Expr(nil) }
		pr := unsafe { &Expr(nil) }

		r1 := 0
		r2 := 0

		if addr_cmp {
			sqlite3_vdbe_jump_here(v, addr_cmp)
		}
		r1 = expr_vector_register(p_parse, p_left, i, reg_left, &&Expr(&&Expr(c2v_address_of(&pl))), &reg_free1)
		r2 = expr_vector_register(p_parse, p_right, i, reg_right, &&Expr(&&Expr(c2v_address_of(&pr))), &reg_free2)
		addr_cmp = sqlite3_vdbe_current_addr(v)
		code_compare(p_parse, pl, pr, int(opx), r1, r2, addr_done, int(p5), is_commuted)
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
		sqlite3_release_temp_reg(p_parse, reg_free1)
		sqlite3_release_temp_reg(p_parse, reg_free2)
		if (int(opx) == 57 || int(opx) == 55) && i < n_left - 1 {
			addr_cmp = sqlite3_vdbe_add_op0(v, 59)
			0
			0
			0
			0
		}
		if int(p5) == 128 {
			sqlite3_vdbe_add_op2(v, 73, 0, dest)
		} else {
			sqlite3_vdbe_add_op3(v, 94, r1, dest, r2)
		}
		if i == n_left - 1 {
			break
		}
		if int(opx) == 54 {
			sqlite3_vdbe_add_op2(v, 52, dest, addr_done)
			0
		} else {
			sqlite3_vdbe_add_op2(v, 9, 0, addr_done)
			if i == n_left - 2 {
				opx = op
			}
		}
	}
	sqlite3_vdbe_jump_here(v, addr_cmp)
	sqlite3_vdbe_resolve_label(v, addr_done)
	if int(op) == 53 {
		sqlite3_vdbe_add_op2(v, 19, dest, dest)
	}
}

@[c:'sqlite3ExprCheckHeight']
fn sqlite3_expr_check_height(p_parse &Parse, n_height int) int {
	rc := 0
	mx_height := p_parse.db.aLimit[3]
	if n_height > mx_height {
		sqlite3_error_msg(p_parse, c'Expression tree is too large (maximum depth %d)', mx_height)
		rc = 1
	}
	return rc
}

@[c:'heightOfExpr']
fn height_of_expr(p &Expr, pn_height &int) {
	if p {
		if p.nHeight > (unsafe { *pn_height }) {
			unsafe { *pn_height = p.nHeight }
		}
	}
}

@[c:'heightOfExprList']
fn height_of_expr_list(p &ExprList, pn_height &int) {
	if p {
		i := 0
		for i = 0; i < p.nExpr; i++ {
			height_of_expr(c2v_at(&p.a[0], isize(i)).pExpr, pn_height)
		}
	}
}

@[c:'heightOfSelect']
fn height_of_select(p_select &Select, pn_height &int) {
	p := &Select(0)
	for p = p_select; p; p = p.pPrior {
		height_of_expr(p.pWhere, pn_height)
		height_of_expr(p.pHaving, pn_height)
		height_of_expr(p.pLimit, pn_height)
		height_of_expr_list(p.pEList, pn_height)
		height_of_expr_list(p.pGroupBy, pn_height)
		height_of_expr_list(p.pOrderBy, pn_height)
	}
}

@[c:'exprSetHeight']
fn expr_set_height(p &Expr) {
	n_height := if p.pLeft { p.pLeft.nHeight } else { 0 }
	if !isnil(p.pRight) && p.pRight.nHeight > n_height {
		n_height = p.pRight.nHeight
	}
	if ((p.flags & u32(4096)) != u32(0)) {
		height_of_select(p.x.pSelect, &n_height)
	} else if p.x.pList {
		height_of_expr_list(p.x.pList, &n_height)
		p.flags |= u32((512 | 4194304 | 8)) & sqlite3_expr_list_flags(p.x.pList)
	}
	p.nHeight = n_height + 1
}

@[c:'sqlite3ExprSetHeightAndFlags']
fn sqlite3_expr_set_height_and_flags(p_parse &Parse, p &Expr) {
	if p_parse.nErr {
		return
	}
	expr_set_height(p)
	sqlite3_expr_check_height(p_parse, p.nHeight)
}

@[c:'sqlite3SelectExprHeight']
fn sqlite3_select_expr_height(p &Select) int {
	n_height := 0
	height_of_select(p, &n_height)
	return n_height
}

@[c:'sqlite3ExprSetErrorOffset']
fn sqlite3_expr_set_error_offset(p_expr &Expr, i_ofst int) {
	if usize(p_expr) == usize(0) {
		return
	}
	if ((p_expr.flags & u32((2 | 1))) != u32(0)) {
		return
	}
	p_expr.w.iOfst = i_ofst
}

@[c:'sqlite3ExprAlloc']
fn sqlite3_expr_alloc(db &Sqlite3, op int, p_token &Token, dequote int) &Expr {
	p_new := &Expr(0)
	n_extra := int(if p_token { p_token.n + u32(1) } else { u32(0) })
	p_new = sqlite3_db_malloc_raw_nn(db, U64(sizeof(Expr) + u64(n_extra)))
	if p_new {
		C.memset(voidptr(p_new), 0, sizeof(Expr))
		p_new.op = U8(op)
		p_new.iAgg = I16(-1)
		if n_extra {
			p_new.u.zToken = &i8(voidptr(unsafe { p_new + 1 }))
			if p_token.n {
				C.memcpy(voidptr(p_new.u.zToken), voidptr(p_token.z), u64(p_token.n))
			}
			p_new.u.zToken[p_token.n] = i8(0)
			if dequote && (int(sqlite3CtypeMap[u8(p_new.u.zToken[0])]) & 128) {
				sqlite3_dequote_expr(p_new)
			}
		}
		p_new.nHeight = 1
	}
	return p_new
}

@[c:'sqlite3Expr']
fn sqlite3_expr(db &Sqlite3, op int, z_token &i8) &Expr {
	x := Token{}
	x.z = z_token
	x.n = u32(sqlite3_strlen30(z_token))
	return sqlite3_expr_alloc(db, op, &x, 0)
}

@[c:'sqlite3ExprInt32']
fn sqlite3_expr_int32(db &Sqlite3, i_val int) &Expr {
	p_new := &Expr(sqlite3_db_malloc_raw_nn(db, U64(sizeof(Expr))))
	if p_new {
		C.memset(voidptr(p_new), 0, sizeof(Expr))
		p_new.op = U8(156)
		p_new.iAgg = I16(-1)
		p_new.flags = u32(2048 | 8388608 | (if i_val { 268435456 } else { 536870912 }))
		p_new.u.iValue = i_val
		p_new.nHeight = 1
	}
	return p_new
}

@[c:'sqlite3ExprAttachSubtrees']
fn sqlite3_expr_attach_subtrees(db &Sqlite3, p_root &Expr, p_left &Expr, p_right &Expr) {
	if usize(p_root) == usize(0) {
		sqlite3_expr_delete(db, p_left)
		sqlite3_expr_delete(db, p_right)
	} else {
		if p_right {
			p_root.pRight = p_right
			p_root.flags |= u32((512 | 4194304 | 8)) & p_right.flags
			p_root.nHeight = p_right.nHeight + 1
		} else {
			p_root.nHeight = 1
		}
		if p_left {
			p_root.pLeft = p_left
			p_root.flags |= u32((512 | 4194304 | 8)) & p_left.flags
			if p_left.nHeight >= p_root.nHeight {
				p_root.nHeight = p_left.nHeight + 1
			}
		}
	}
}

@[c:'sqlite3PExpr']
fn sqlite3_pe_xpr(p_parse &Parse, op int, p_left &Expr, p_right &Expr) &Expr {
	p := &Expr(0)
	p = sqlite3_db_malloc_raw_nn(p_parse.db, U64(sizeof(Expr)))
	if p {
		C.memset(voidptr(p), 0, sizeof(Expr))
		p.op = U8(op & 255)
		p.iAgg = I16(-1)
		sqlite3_expr_attach_subtrees(p_parse.db, p, p_left, p_right)
		sqlite3_expr_check_height(p_parse, p.nHeight)
	} else {
		sqlite3_expr_delete(p_parse.db, p_left)
		sqlite3_expr_delete(p_parse.db, p_right)
	}
	return p
}

@[c:'sqlite3PExprAddSelect']
fn sqlite3_pe_xpr_add_select(p_parse &Parse, p_expr &Expr, p_select &Select) {
	if p_expr {
		p_expr.x.pSelect = p_select
		p_expr.flags |= u32((4096 | 4194304))
		sqlite3_expr_set_height_and_flags(p_parse, p_expr)
	} else {
		sqlite3_select_delete(p_parse.db, p_select)
	}
}

@[c:'sqlite3ExprListToValues']
fn sqlite3_expr_list_to_values(p_parse &Parse, n_elem int, pel_ist &ExprList) &Select {
	ii := 0
	p_ret := unsafe { &Select(nil) }
	for ii = 0; ii < pel_ist.nExpr; ii++ {
		p_sel := &Select(0)
		p_expr := c2v_at(&pel_ist.a[0], isize(ii)).pExpr
		n_expr_elem := 0
		if int(p_expr.op) == 177 {
			n_expr_elem = p_expr.x.pList.nExpr
		} else {
			n_expr_elem = 1
		}
		if n_expr_elem != n_elem {
			sqlite3_error_msg(p_parse, c'IN(...) element has %d term%s - expected %d', n_expr_elem, voidptr(if n_expr_elem > 1 {
				c's'
			} else {
				c''
			}), n_elem)
			break
		}
		p_sel = sqlite3_select_new(p_parse, p_expr.x.pList, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, u32(512), unsafe { nil })
		p_expr.x.pList = 0
		if p_sel {
			if p_ret {
				p_sel.op = U8(136)
				p_sel.pPrior = p_ret
			}
			p_ret = p_sel
		}
	}
	if !isnil(p_ret) && !isnil(p_ret.pPrior) {
		p_ret.selFlags |= u32(1024)
	}
	sqlite3_expr_list_delete(p_parse.db, pel_ist)
	return p_ret
}

@[c:'sqlite3ExprAnd']
fn sqlite3_expr_and(p_parse &Parse, p_left &Expr, p_right &Expr) &Expr {
	db := p_parse.db
	if usize(p_left) == usize(0) {
		return p_right
	} else if usize(p_right) == usize(0) {
		return p_left
	} else {
		f := p_left.flags | p_right.flags
		if (f & u32((1 | 2 | 536870912 | 8))) == u32(536870912) && !(int(p_parse.eParseMode) >= 2) {
			sqlite3_expr_deferred_delete(p_parse, p_left)
			sqlite3_expr_deferred_delete(p_parse, p_right)
			return sqlite3_expr_int32(db, 0)
		} else {
			return sqlite3_pe_xpr(p_parse, 44, p_left, p_right)
		}
	}
}

@[c:'sqlite3ExprFunction']
fn sqlite3_expr_function(p_parse &Parse, p_list &ExprList, p_token &Token, e_distinct int) &Expr {
	p_new := &Expr(0)
	db := p_parse.db
	p_new = sqlite3_expr_alloc(db, 172, p_token, 1)
	if usize(p_new) == usize(0) {
		sqlite3_expr_list_delete(db, p_list)
		return unsafe { nil }
	}
	p_new.w.iOfst = int((i64((isize(p_token.z) - isize(p_parse.zTail)) / isize(sizeof(i8)))))
	if !isnil(p_list) && p_list.nExpr > p_parse.db.aLimit[6] && !p_parse.nested {
		sqlite3_error_msg(p_parse, c'too many arguments on function %T', voidptr(p_token))
	}
	p_new.x.pList = p_list
	p_new.flags |= u32(8)
	sqlite3_expr_set_height_and_flags(p_parse, p_new)
	if e_distinct == 1 {
		p_new.flags |= u32(4)
	}
	return p_new
}

@[c:'sqlite3ExprOrderByAggregateError']
fn sqlite3_expr_order_by_aggregate_error(p_parse &Parse, p &Expr) {
	sqlite3_error_msg(p_parse, c'ORDER BY may not be used with non-aggregate %#T()', voidptr(p))
}

@[c:'sqlite3ExprAddFunctionOrderBy']
fn sqlite3_expr_add_function_order_by(p_parse &Parse, p_expr &Expr, p_order_by &ExprList) {
	pob := &Expr(0)
	db := p_parse.db
	if (usize(p_order_by) == usize(0)) {
		return
	}
	if usize(p_expr) == usize(0) {
		sqlite3_expr_list_delete(db, p_order_by)
		return
	}
	if usize(p_expr.x.pList) == usize(0) || (p_expr.x.pList.nExpr == 0) {
		sqlite3_parser_add_cleanup(p_parse, sqlite3_expr_list_delete_generic, voidptr(p_order_by))
		return
	}
	if (((p_expr.flags & u32(16777216)) != u32(0)) && int(p_expr.y.pWin.eFrmType) != 167) {
		sqlite3_expr_order_by_aggregate_error(p_parse, p_expr)
		sqlite3_expr_list_delete(db, p_order_by)
		return
	}
	if p_order_by.nExpr > db.aLimit[2] {
		sqlite3_error_msg(p_parse, c'too many terms in ORDER BY clause')
		sqlite3_expr_list_delete(db, p_order_by)
		return
	}
	pob = sqlite3_expr_alloc(db, 146, unsafe { nil }, 0)
	if usize(pob) == usize(0) {
		sqlite3_expr_list_delete(db, p_order_by)
		return
	}
	pob.x.pList = p_order_by
	p_expr.pLeft = pob
	pob.flags |= u32(131072)
}

@[c:'sqlite3ExprFunctionUsable']
fn sqlite3_expr_function_usable(p_parse &Parse, p_expr &Expr, p_def &FuncDef) {
	if ((p_expr.flags & u32(1073741824)) != u32(0)) || int(p_parse.prepFlags) & 32 {
		if (p_def.funcFlags & u32(524288)) != u32(0) || (p_parse.db.flags & U64(128)) == U64(0) {
			sqlite3_error_msg(p_parse, c'unsafe use of %#T()', voidptr(p_expr))
		}
	}
}

@[c:'sqlite3ExprAssignVarNumber']
fn sqlite3_expr_assign_var_number(p_parse &Parse, p_expr &Expr, n u32) {
	db := p_parse.db
	z := &i8(0)
	x := YnVar(0)
	if usize(p_expr) == usize(0) {
		return
	}
	z = p_expr.u.zToken
	if int(z[1]) == 0 {
		x = YnVar((c2v_prefix_add(unsafe { &p_parse.nVar }, i16(1))))
	} else {
		do_add := 0
		if int(z[0]) == i8(`?`) {
			i := I64(0)
			b_ok := 0
			if n == u32(2) {
				i = I64(int(z[1]) - int(`0`))
				b_ok = 1
			} else {
				b_ok = 0 == sqlite3_atoi64(unsafe { z + 1 }, &i, int(n - u32(1)), U8(1))
			}
			0
			0
			0
			0
			if b_ok == 0 || i < I64(1) || i > I64(db.aLimit[9]) {
				sqlite3_error_msg(p_parse, c'variable number must be between ?1 and ?%d', db.aLimit[9])
				sqlite3_record_error_offset_of_expr(p_parse.db, p_expr)
				return
			}
			x = YnVar(i)
			if int(x) > int(p_parse.nVar) {
				p_parse.nVar = YnVar(int(x))
				do_add = 1
			} else if usize(sqlite3_vl_ist_num_to_name(p_parse.pVList, int(x))) == usize(0) {
				do_add = 1
			}
		} else {
			x = YnVar(sqlite3_vl_ist_name_to_num(p_parse.pVList, z, int(n)))
			if int(x) == 0 {
				x = YnVar((c2v_prefix_add(unsafe { &p_parse.nVar }, i16(1))))
				do_add = 1
			}
		}
		if do_add {
			p_parse.pVList = sqlite3_vl_ist_add(db, p_parse.pVList, z, int(n), int(x))
		}
	}
	p_expr.iColumn = x
	if int(x) > db.aLimit[9] {
		sqlite3_error_msg(p_parse, c'too many SQL variables')
		sqlite3_record_error_offset_of_expr(p_parse.db, p_expr)
	}
}

@[c:'sqlite3ExprDeleteNN']
fn sqlite3_expr_delete_nn(db &Sqlite3, p &Expr) {
	exprDeleteRestart:
	if !((p.flags & u32((65536 | 8388608))) != u32(0)) {
		if p.pRight {
			sqlite3_expr_delete_nn(db, p.pRight)
		} else if ((p.flags & u32(4096)) != u32(0)) {
			sqlite3_select_delete(db, p.x.pSelect)
		} else {
			sqlite3_expr_list_delete(db, p.x.pList)
			if ((p.flags & u32(16777216)) != u32(0)) {
				sqlite3_window_delete(db, p.y.pWin)
			}
		}
		if !isnil(p.pLeft) && int(p.op) != 178 {
			p_left := p.pLeft
			if !((p.flags & u32(134217728)) != u32(0)) && !((p_left.flags & u32(134217728)) != u32(0)) {
				sqlite3_db_nn_free_nn(db, voidptr(p))
				p = p_left
				unsafe { goto exprDeleteRestart
				 }
			} else {
				sqlite3_expr_delete_nn(db, p_left)
			}
		}
	}
	if !((p.flags & u32(134217728)) != u32(0)) {
		sqlite3_db_nn_free_nn(db, voidptr(p))
	}
}

@[c:'sqlite3ExprDelete']
fn sqlite3_expr_delete(db &Sqlite3, p &Expr) {
	if p {
		sqlite3_expr_delete_nn(db, p)
	}
}

@[c:'sqlite3ExprDeleteGeneric']
fn sqlite3_expr_delete_generic(db &Sqlite3, p voidptr) {
	c2v_gc_register_thread()
	if p {
		sqlite3_expr_delete_nn(db, &Expr(p))
	}
}

@[c:'sqlite3ClearOnOrUsing']
fn sqlite3_clear_on_or_using(db &Sqlite3, p &OnOrUsing) {
	if usize(p) == usize(0) {
	} else if p.pOn {
		sqlite3_expr_delete_nn(db, p.pOn)
	} else if p.pUsing {
		sqlite3_id_list_delete(db, p.pUsing)
	}
}

@[c:'sqlite3ExprDeferredDelete']
fn sqlite3_expr_deferred_delete(p_parse &Parse, p_expr &Expr) int {
	return int(usize(0) == usize(sqlite3_parser_add_cleanup(p_parse, sqlite3_expr_delete_generic, voidptr(p_expr))))
}

@[c:'sqlite3ExprUnmapAndDelete']
fn sqlite3_expr_unmap_and_delete(p_parse &Parse, p &Expr) {
	if p {
		if (int(p_parse.eParseMode) >= 2) {
			sqlite3_rename_expr_unmap(p_parse, p)
		}
		sqlite3_expr_delete_nn(p_parse.db, p)
	}
}

@[c:'exprStructSize']
fn expr_struct_size(p &Expr) int {
	if ((p.flags & u32(65536)) != u32(0)) {
		return int((u64(usize(__offsetof(Expr, pLeft)))))
	}
	if ((p.flags & u32(16384)) != u32(0)) {
		return int((u64(usize(__offsetof(Expr, iTable)))))
	}
	return int(sizeof(Expr))
}

@[c:'dupedExprStructSize']
fn duped_expr_struct_size(p &Expr, flags int) int {
	n_size := 0
	if 0 == flags || ((p.flags & u32(131072)) != u32(0)) {
		n_size = int(sizeof(Expr))
	} else {
		if !isnil(p.pLeft) || !isnil(p.x.pList) {
			n_size = int((u64(usize(__offsetof(Expr, iTable)))) | u64(16384))
		} else {
			n_size = int((u64(usize(__offsetof(Expr, pLeft)))) | u64(65536))
		}
	}
	return n_size
}

@[c:'dupedExprNodeSize']
fn duped_expr_node_size(p &Expr, flags int) int {
	n_byte := duped_expr_struct_size(p, flags) & 4095
	if !((p.flags & u32(2048)) != u32(0)) && !isnil(p.u.zToken) {
		n_byte += (C.strlen(p.u.zToken) & u64(1073741823)) + u64(1)
	}
	return (n_byte + 7) & ~7
}

@[c:'dupedExprSize']
fn duped_expr_size(p &Expr) int {
	n_byte := 0
	n_byte = duped_expr_node_size(p, 1)
	if p.pLeft {
		n_byte += duped_expr_size(p.pLeft)
	}
	if p.pRight {
		n_byte += duped_expr_size(p.pRight)
	}
	return n_byte
}

struct EdupBuf {
	zAlloc &U8
}

@[c:'exprDup']
fn expr_dup(db &Sqlite3, p &Expr, dup_flags int, p_edup_buf &EdupBuf) &Expr {
	p_new := &Expr(0)
	s_edup_buf := EdupBuf{}
	static_flag := u32(0)
	n_token := -1
	if p_edup_buf {
		s_edup_buf.zAlloc = p_edup_buf.zAlloc
		static_flag = u32(134217728)
	} else {
		n_alloc := 0
		if dup_flags {
			n_alloc = duped_expr_size(p)
		} else if !((p.flags & u32(2048)) != u32(0)) && !isnil(p.u.zToken) {
			n_token = int((C.strlen(p.u.zToken) & u64(1073741823)) + u64(1))
			n_alloc = int((((sizeof(Expr) + u64(n_token)) + u64(7)) & u64(~7)))
		} else {
			n_token = 0
			n_alloc = int((((sizeof(Expr)) + u64(7)) & u64(~7)))
		}
		s_edup_buf.zAlloc = sqlite3_db_malloc_raw_nn(db, U64(n_alloc))
		static_flag = u32(0)
	}
	p_new = &Expr(voidptr(s_edup_buf.zAlloc))
	if p_new {
		n_struct_size := u32(duped_expr_struct_size(p, dup_flags))
		n_new_size := int(n_struct_size & u32(4095))
		if n_token < 0 {
			if !((p.flags & u32(2048)) != u32(0)) && !isnil(p.u.zToken) {
				n_token = sqlite3_strlen30(p.u.zToken) + 1
			} else {
				n_token = 0
			}
		}
		if dup_flags {
			C.memcpy(voidptr(s_edup_buf.zAlloc), voidptr(p), u64(n_new_size))
		} else {
			n_size := u32(expr_struct_size(p))
			C.memcpy(voidptr(s_edup_buf.zAlloc), voidptr(p), u64(n_size))
			if u64(n_size) < sizeof(Expr) {
				C.memset(voidptr(unsafe { s_edup_buf.zAlloc + n_size }), 0, sizeof(Expr) - u64(n_size))
			}
			n_new_size = int(sizeof(Expr))
		}
		p_new.flags &= u32(~(16384 | 65536 | 134217728))
		p_new.flags |= n_struct_size & u32((16384 | 65536))
		p_new.flags |= static_flag
		0
		if dup_flags {
			0
		}
		if n_token > 0 {
			z_token := c2v_assign[&i8](unsafe { &p_new.u.zToken }, &i8(voidptr(unsafe { s_edup_buf.zAlloc + n_new_size })))
			C.memcpy(voidptr(z_token), voidptr(p.u.zToken), u64(n_token))
			n_new_size += n_token
		}
		c2v_pointer_prefix(voidptr(&s_edup_buf.zAlloc), s_edup_buf.zAlloc, isize(((n_new_size + 7) & ~7)))
		if ((p.flags | p_new.flags) & u32((65536 | 8388608))) == u32(0) {
			if ((p.flags & u32(4096)) != u32(0)) {
				p_new.x.pSelect = sqlite3_select_dup(db, p.x.pSelect, dup_flags)
			} else {
				p_new.x.pList = sqlite3_expr_list_dup(db, p.x.pList, if int(p.op) != 146 {
					dup_flags
				} else {
					0
				})
			}
			if ((p.flags & u32(16777216)) != u32(0)) {
				p_new.y.pWin = sqlite3_window_dup(db, p_new, p.y.pWin)
			}
			if dup_flags {
				if int(p.op) == 178 {
					p_new.pLeft = p.pLeft
				} else {
					p_new.pLeft = unsafe { if p.pLeft {
						expr_dup(db, p.pLeft, 1, &s_edup_buf)
					} else {
						&Expr(nil)
					} }
				}
				p_new.pRight = unsafe { if p.pRight {
					expr_dup(db, p.pRight, 1, &s_edup_buf)
				} else {
					&Expr(nil)
				} }
			} else {
				if int(p.op) == 178 {
					p_new.pLeft = p.pLeft
				} else {
					p_new.pLeft = sqlite3_expr_dup(db, p.pLeft, 0)
				}
				p_new.pRight = sqlite3_expr_dup(db, p.pRight, 0)
			}
		}
	}
	if p_edup_buf {
		C.memcpy(voidptr(p_edup_buf), voidptr(&s_edup_buf), sizeof(s_edup_buf))
	}
	return p_new
}

@[c:'sqlite3WithDup']
fn sqlite3_with_dup(db &Sqlite3, p &With) &With {
	p_ret := unsafe { &With(nil) }
	if p {
		n_byte := Sqlite3_int64(((u64(usize(__offsetof(With, a)))) + u64(p.nCte) * sizeof(Cte)))
		p_ret = sqlite3_db_malloc_zero(db, U64(n_byte))
		if p_ret {
			i := 0
			p_ret.nCte = p.nCte
			for i = 0; i < p.nCte; i++ {
				mut __c2v_lhs_tmp_94 := c2v_at(&p_ret.a[0], isize(i))
				__c2v_lhs_tmp_94.pSelect = sqlite3_select_dup(db, c2v_at(&p.a[0], isize(i)).pSelect, 0)
				mut __c2v_lhs_tmp_95 := c2v_at(&p_ret.a[0], isize(i))
				__c2v_lhs_tmp_95.pCols = sqlite3_expr_list_dup(db, c2v_at(&p.a[0], isize(i)).pCols, 0)
				mut __c2v_lhs_tmp_96 := c2v_at(&p_ret.a[0], isize(i))
				__c2v_lhs_tmp_96.zName = sqlite3_db_str_dup(db, c2v_at(&p.a[0], isize(i)).zName)
				mut __c2v_lhs_tmp_97 := c2v_at(&p_ret.a[0], isize(i))
				__c2v_lhs_tmp_97.eM10d = c2v_at(&p.a[0], isize(i)).eM10d
			}
		}
	}
	return p_ret
}

@[c:'gatherSelectWindowsCallback']
fn gather_select_windows_callback(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	if int(p_expr.op) == 172 && ((p_expr.flags & u32(16777216)) != u32(0)) {
		p_select := p_walker.u.pSelect
		p_win := p_expr.y.pWin
		sqlite3_window_link(p_select, p_win)
	}
	return 0
}

@[c:'gatherSelectWindowsSelectCallback']
fn gather_select_windows_select_callback(p_walker &Walker, p &Select) int {
	c2v_gc_register_thread()
	return if usize(p) == usize(p_walker.u.pSelect) { 0 } else { 1 }
}

@[c:'gatherSelectWindows']
fn gather_select_windows(p &Select) {
	w := Walker{}
	w.xExprCallback = gather_select_windows_callback
	w.xSelectCallback = gather_select_windows_select_callback
	w.xSelectCallback2 = 0
	w.pParse = 0
	w.u.pSelect = p
	sqlite3_walk_select(&w, p)
}

@[c:'sqlite3ExprDup']
fn sqlite3_expr_dup(db &Sqlite3, p &Expr, flags int) &Expr {
	return unsafe { if p { expr_dup(db, p, flags, nil) } else { &Expr(nil) } }
}

@[c:'sqlite3ExprListDup']
fn sqlite3_expr_list_dup(db &Sqlite3, p &ExprList, flags int) &ExprList {
	p_new := &ExprList(0)
	p_item := &ExprList_item(0)
	p_old_item := &ExprList_item(0)
	i := 0
	p_prior_select_col_old := unsafe { &Expr(nil) }
	p_prior_select_col_new := unsafe { &Expr(nil) }
	if usize(p) == usize(0) {
		return unsafe { nil }
	}
	p_new = sqlite3_db_malloc_raw_nn(db, U64(sqlite3_db_malloc_size(db, voidptr(p))))
	if usize(p_new) == usize(0) {
		return unsafe { nil }
	}
	p_new.nExpr = p.nExpr
	p_new.nAlloc = p.nAlloc
	p_item = unsafe { &p_new.a[0] }
	p_old_item = unsafe { &p.a[0] }
	for i = 0; i < p.nExpr; i++ {
		p_old_expr := p_old_item.pExpr
		p_new_expr := &Expr(0)
		p_item.pExpr = sqlite3_expr_dup(db, p_old_expr, flags)
		if !isnil(p_old_expr) && int(p_old_expr.op) == 178 && usize(c2v_assign[&Expr](unsafe { &p_new_expr }, p_item.pExpr)) != usize(0) {
			if p_new_expr.pRight {
				p_prior_select_col_old = p_old_expr.pRight
				p_prior_select_col_new = p_new_expr.pRight
				p_new_expr.pLeft = p_new_expr.pRight
			} else {
				if usize(p_old_expr.pLeft) != usize(p_prior_select_col_old) {
					p_prior_select_col_old = p_old_expr.pLeft
					p_prior_select_col_new = sqlite3_expr_dup(db, p_prior_select_col_old, flags)
					p_new_expr.pRight = p_prior_select_col_new
				}
				p_new_expr.pLeft = p_prior_select_col_new
			}
		}
		p_item.zEName = sqlite3_db_str_dup(db, p_old_item.zEName)
		p_item.fg = p_old_item.fg
		p_item.u = p_old_item.u
		c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
		c2v_pointer_postfix(voidptr(&p_old_item), p_old_item, isize(1))
	}
	return p_new
}

@[c:'sqlite3SrcListDup']
fn sqlite3_src_list_dup(db &Sqlite3, p &SrcList, flags int) &SrcList {
	p_new := &SrcList(0)
	i := 0
	if usize(p) == usize(0) {
		return unsafe { nil }
	}
	p_new = sqlite3_db_malloc_raw_nn(db, U64(((u64(usize(__offsetof(SrcList, a)))) + u64(p.nSrc) * sizeof(SrcItem))))
	if usize(p_new) == usize(0) {
		return unsafe { nil }
	}
	p_new.nAlloc = u32(p.nSrc)
	p_new.nSrc = p_new.nAlloc
	for i = 0; i < p.nSrc; i++ {
		p_new_item := unsafe { &p_new.a[0] + i }
		p_old_item := unsafe { &p.a[0] + i }
		p_tab := &Table(0)
		p_new_item.fg = p_old_item.fg
		if p_old_item.fg.isSubquery {
			p_new_subq := &Subquery(sqlite3_db_malloc_raw(db, U64(sizeof(Subquery))))
			if usize(p_new_subq) == usize(0) {
				p_new_item.fg.isSubquery = u32(0)
			} else {
				C.memcpy(voidptr(p_new_subq), voidptr(p_old_item.u4.pSubq), sizeof(Subquery))
				p_new_subq.pSelect = sqlite3_select_dup(db, p_new_subq.pSelect, flags)
				if usize(p_new_subq.pSelect) == usize(0) {
					sqlite3_db_free(db, voidptr(p_new_subq))
					p_new_subq = 0
					p_new_item.fg.isSubquery = u32(0)
				}
			}
			p_new_item.u4.pSubq = p_new_subq
		} else if p_old_item.fg.fixedSchema {
			p_new_item.u4.pSchema = p_old_item.u4.pSchema
		} else {
			p_new_item.u4.zDatabase = sqlite3_db_str_dup(db, p_old_item.u4.zDatabase)
		}
		p_new_item.zName = sqlite3_db_str_dup(db, p_old_item.zName)
		p_new_item.zAlias = sqlite3_db_str_dup(db, p_old_item.zAlias)
		p_new_item.iCursor = p_old_item.iCursor
		if p_new_item.fg.isIndexedBy {
			p_new_item.u1.zIndexedBy = sqlite3_db_str_dup(db, p_old_item.u1.zIndexedBy)
		} else if p_new_item.fg.isTabFunc {
			p_new_item.u1.pFuncArg = sqlite3_expr_list_dup(db, p_old_item.u1.pFuncArg, flags)
		} else {
			p_new_item.u1.nRow = p_old_item.u1.nRow
		}
		p_new_item.u2 = p_old_item.u2
		if p_new_item.fg.isCte {
			p_new_item.u2.pCteUse.nUse++
		}
		p_new_item.pSTab = p_old_item.pSTab
		p_tab = p_new_item.pSTab
		if p_tab {
			p_tab.nTabRef++
		}
		if p_old_item.fg.isUsing {
			p_new_item.u3.pUsing = sqlite3_id_list_dup(db, p_old_item.u3.pUsing)
		} else {
			p_new_item.u3.pOn = sqlite3_expr_dup(db, p_old_item.u3.pOn, flags)
		}
		p_new_item.colUsed = p_old_item.colUsed
	}
	return p_new
}

@[c:'sqlite3IdListDup']
fn sqlite3_id_list_dup(db &Sqlite3, p &IdList) &IdList {
	p_new := &IdList(0)
	i := 0
	if usize(p) == usize(0) {
		return unsafe { nil }
	}
	p_new = sqlite3_db_malloc_raw_nn(db, U64(((u64(usize(__offsetof(IdList, a)))) + u64(p.nId) * sizeof(IdList_item))))
	if usize(p_new) == usize(0) {
		return unsafe { nil }
	}
	p_new.nId = p.nId
	for i = 0; i < p.nId; i++ {
		p_new_item := unsafe { &p_new.a[0] + i }
		p_old_item := unsafe { &p.a[0] + i }
		p_new_item.zName = sqlite3_db_str_dup(db, p_old_item.zName)
	}
	return p_new
}

@[c:'sqlite3SelectDup']
fn sqlite3_select_dup(db &Sqlite3, p_dup &Select, flags int) &Select {
	p_ret := unsafe { &Select(nil) }
	p_next := unsafe { &Select(nil) }
	pp := &&Select(c2v_address_of(&p_ret))
	p := &Select(0)
	for p = p_dup; p; p = p.pPrior {
		p_new := &Select(sqlite3_db_malloc_raw_nn(db, U64(sizeof(Select))))
		if usize(p_new) == usize(0) {
			break
		}
		p_new.pEList = sqlite3_expr_list_dup(db, p.pEList, flags)
		p_new.pSrc = sqlite3_src_list_dup(db, p.pSrc, flags)
		p_new.pWhere = sqlite3_expr_dup(db, p.pWhere, flags)
		p_new.pGroupBy = sqlite3_expr_list_dup(db, p.pGroupBy, flags)
		p_new.pHaving = sqlite3_expr_dup(db, p.pHaving, flags)
		p_new.pOrderBy = sqlite3_expr_list_dup(db, p.pOrderBy, flags)
		p_new.op = p.op
		p_new.pNext = p_next
		p_new.pPrior = 0
		p_new.pLimit = sqlite3_expr_dup(db, p.pLimit, flags)
		p_new.iLimit = 0
		p_new.iOffset = 0
		p_new.selFlags = p.selFlags
		p_new.nSelectRow = p.nSelectRow
		p_new.pWith = sqlite3_with_dup(db, p.pWith)
		p_new.pWin = 0
		p_new.pWinDefn = sqlite3_window_list_dup(db, p.pWinDefn)
		if !isnil(p.pWin) && int(db.mallocFailed) == 0 {
			gather_select_windows(p_new)
		}
		p_new.selId = p.selId
		if db.mallocFailed {
			p_new.pNext = 0
			sqlite3_select_delete(db, p_new)
			break
		}
		unsafe { *pp = p_new }
		pp = &p_new.pPrior
		p_next = p_new
	}
	return p_ret
}

@[c:'sqlite3ExprListAppendNew']
fn sqlite3_expr_list_append_new(db &Sqlite3, p_expr &Expr) &ExprList {
	p_item := &ExprList_item(0)
	p_list := &ExprList(0)
	p_list = sqlite3_db_malloc_raw_nn(db, U64(((u64(usize(__offsetof(ExprList, a)))) + u64(4) * sizeof(ExprList_item))))
	if usize(p_list) == usize(0) {
		sqlite3_expr_delete(db, p_expr)
		return unsafe { nil }
	}
	p_list.nAlloc = 4
	p_list.nExpr = 1
	p_item = unsafe { &p_list.a[0] + 0 }
	unsafe { *p_item = zero_item }
	p_item.pExpr = p_expr
	return p_list
}

@[c:'sqlite3ExprListAppendGrow']
fn sqlite3_expr_list_append_grow(db &Sqlite3, p_list &ExprList, p_expr &Expr) &ExprList {
	p_item := &ExprList_item(0)
	p_new := &ExprList(0)
	p_list.nAlloc *= 2
	p_new = sqlite3_db_realloc(db, voidptr(p_list), U64(((u64(usize(__offsetof(ExprList, a)))) + u64(p_list.nAlloc) * sizeof(ExprList_item))))
	if usize(p_new) == usize(0) {
		sqlite3_expr_list_delete(db, p_list)
		sqlite3_expr_delete(db, p_expr)
		return unsafe { nil }
	} else {
		p_list = p_new
	}
	p_item = unsafe { &p_list.a[0] + p_list.nExpr++ }
	unsafe { *p_item = zero_item }
	p_item.pExpr = p_expr
	return p_list
}

@[c:'sqlite3ExprListAppend']
fn sqlite3_expr_list_append(p_parse &Parse, p_list &ExprList, p_expr &Expr) &ExprList {
	p_item := &ExprList_item(0)
	if usize(p_list) == usize(0) {
		return sqlite3_expr_list_append_new(p_parse.db, p_expr)
	}
	if p_list.nAlloc < p_list.nExpr + 1 {
		return sqlite3_expr_list_append_grow(p_parse.db, p_list, p_expr)
	}
	p_item = unsafe { &p_list.a[0] + p_list.nExpr++ }
	unsafe { *p_item = zero_item }
	p_item.pExpr = p_expr
	return p_list
}

@[c:'sqlite3ExprListAppendVector']
fn sqlite3_expr_list_append_vector(p_parse &Parse, p_list &ExprList, p_columns &IdList, p_expr &Expr) &ExprList {
	db := p_parse.db
	n := 0
	i := 0
	i_first := if p_list { p_list.nExpr } else { 0 }
	if (usize(p_columns) == usize(0)) {
		unsafe { goto vector_append_error
		 }
	}
	if usize(p_expr) == usize(0) {
		unsafe { goto vector_append_error
		 }
	}
	if int(p_expr.op) != 139 && p_columns.nId != c2v_assign[int](unsafe { &n }, int(sqlite3_expr_vector_size(p_expr))) {
		sqlite3_error_msg(p_parse, c'%d columns assigned %d values', p_columns.nId, n)
		unsafe { goto vector_append_error
		 }
	}
	for i = 0; i < p_columns.nId; i++ {
		p_sub_expr := sqlite3_expr_for_vector_field(p_parse, p_expr, i, p_columns.nId)
		if usize(p_sub_expr) == usize(0) {
			continue
		}
		p_list = sqlite3_expr_list_append(p_parse, p_list, p_sub_expr)
		if p_list {
			mut __c2v_lhs_tmp_98 := unsafe { c2v_at(&p_list.a[0], isize(p_list.nExpr - 1)) }
			__c2v_lhs_tmp_98.zEName = c2v_at(&p_columns.a[0], isize(i)).zName
			mut __c2v_lhs_tmp_99 := c2v_at(&p_columns.a[0], isize(i))
			__c2v_lhs_tmp_99.zName = 0
		}
	}
	if !db.mallocFailed && int(p_expr.op) == 139 && (usize(p_list) != usize(0)) {
		p_first := c2v_at(&p_list.a[0], isize(i_first)).pExpr
		p_first.pRight = p_expr
		p_expr = 0
		p_first.iTable = p_columns.nId
	}
	vector_append_error:
	sqlite3_expr_unmap_and_delete(p_parse, p_expr)
	sqlite3_id_list_delete(db, p_columns)
	return p_list
}

@[c:'sqlite3ExprListSetSortOrder']
fn sqlite3_expr_list_set_sort_order(p &ExprList, i_sort_order int, e_nulls int) {
	p_item := &ExprList_item(0)
	if usize(p) == usize(0) {
		return
	}
	p_item = unsafe { &p.a[0] + (p.nExpr - 1) }
	if i_sort_order == -1 {
		i_sort_order = 0
	}
	p_item.fg.sortFlags = U8(i_sort_order)
	if e_nulls != -1 {
		p_item.fg.bNulls = u32(1)
		if i_sort_order != e_nulls {
			p_item.fg.sortFlags |= 2
		}
	}
}

@[c:'sqlite3ExprListSetName']
fn sqlite3_expr_list_set_name(p_parse &Parse, p_list &ExprList, p_name &Token, dequote int) {
	if p_list {
		p_item := &ExprList_item(0)
		p_item = unsafe { &p_list.a[0] + (p_list.nExpr - 1) }
		p_item.zEName = sqlite3_db_str_nd_up(p_parse.db, p_name.z, U64(p_name.n))
		if dequote {
			sqlite3_dequote(p_item.zEName)
			if (int(p_parse.eParseMode) >= 2) {
				sqlite3_rename_token_map(p_parse, voidptr(p_item.zEName), p_name)
			}
		}
	}
}

@[c:'sqlite3ExprListSetSpan']
fn sqlite3_expr_list_set_span(p_parse &Parse, p_list &ExprList, z_start &i8, z_end &i8) {
	db := p_parse.db
	if p_list {
		p_item := unsafe { &p_list.a[0] + (p_list.nExpr - 1) }
		if usize(p_item.zEName) == usize(0) {
			p_item.zEName = sqlite3_db_span_dup(db, z_start, z_end)
			p_item.fg.eEName = u32(1)
		}
	}
}

@[c:'sqlite3ExprListCheckLength']
fn sqlite3_expr_list_check_length(p_parse &Parse, pel_ist &ExprList, z_object &i8) {
	mx := p_parse.db.aLimit[2]
	0
	0
	if !isnil(pel_ist) && pel_ist.nExpr > mx {
		sqlite3_error_msg(p_parse, c'too many columns in %s', voidptr(z_object))
	}
}

@[c:'exprListDeleteNN']
fn expr_list_delete_nn(db &Sqlite3, p_list &ExprList) {
	i := p_list.nExpr
	p_item := unsafe { &ExprList_item(&p_list.a[0]) }
	for {
		sqlite3_expr_delete(db, p_item.pExpr)
		if p_item.zEName {
			sqlite3_db_nn_free_nn(db, voidptr(p_item.zEName))
		}
		c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
		i--
		if !(i > 0) {
			break
		}
	}
	sqlite3_db_nn_free_nn(db, voidptr(p_list))
}

@[c:'sqlite3ExprListDelete']
fn sqlite3_expr_list_delete(db &Sqlite3, p_list &ExprList) {
	if p_list {
		expr_list_delete_nn(db, p_list)
	}
}

@[c:'sqlite3ExprListDeleteGeneric']
fn sqlite3_expr_list_delete_generic(db &Sqlite3, p_list voidptr) {
	c2v_gc_register_thread()
	if p_list {
		expr_list_delete_nn(db, &ExprList(p_list))
	}
}

@[c:'sqlite3ExprListFlags']
fn sqlite3_expr_list_flags(p_list &ExprList) u32 {
	i := 0
	m := u32(0)
	for i = 0; i < p_list.nExpr; i++ {
		p_expr := c2v_at(&p_list.a[0], isize(i)).pExpr
		m |= p_expr.flags
	}
	return m
}

@[c:'sqlite3SelectWalkFail']
fn sqlite3_select_walk_fail(p_walker &Walker, not_used &Select) int {
	c2v_gc_register_thread()

	p_walker.eCode = U16(0)
	return 2
}

@[c:'sqlite3IsTrueOrFalse']
fn sqlite3_is_trueor_false(z_in &i8) u32 {
	if sqlite3_str_ic_mp(z_in, c'true') == 0 {
		return u32(268435456)
	}
	if sqlite3_str_ic_mp(z_in, c'false') == 0 {
		return u32(536870912)
	}
	return u32(0)
}

@[c:'sqlite3ExprIdToTrueFalse']
fn sqlite3_expr_id_to_truefalse(p_expr &Expr) int {
	v := u32(0)
	if !((p_expr.flags & u32((67108864 | 2048))) != u32(0)) && c2v_assign[u32](unsafe { &v }, u32(sqlite3_is_trueor_false(p_expr.u.zToken))) != u32(0) {
		p_expr.op = U8(171)
		p_expr.flags |= u32(v)
		return 1
	}
	return 0
}

@[c:'sqlite3ExprTruthValue']
fn sqlite3_expr_truth_value(p_expr &Expr) int {
	p_expr = sqlite3_expr_skip_collate_and_likely(&Expr(p_expr))
	return int(p_expr.u.zToken[4] == 0)
}

@[c:'sqlite3ExprSimplifiedAndOr']
fn sqlite3_expr_simplified_and_or(p_expr &Expr) &Expr {
	if int(p_expr.op) == 44 || int(p_expr.op) == 43 {
		p_right := sqlite3_expr_simplified_and_or(p_expr.pRight)
		p_left := sqlite3_expr_simplified_and_or(p_expr.pLeft)
		if ((p_left.flags & u32((1 | 268435456))) == u32(268435456)) || ((p_right.flags & u32((1 | 536870912))) == u32(536870912)) {
			p_expr = if int(p_expr.op) == 44 { p_right } else { p_left }
		} else if ((p_right.flags & u32((1 | 268435456))) == u32(268435456)) || ((p_left.flags & u32((1 | 536870912))) == u32(536870912)) {
			p_expr = if int(p_expr.op) == 44 { p_left } else { p_right }
		}
	}
	return p_expr
}

@[c:'exprEvalRhsFirst']
fn expr_eval_rhs_first(p_expr &Expr) int {
	if ((p_expr.pLeft.flags & u32(4194304)) != u32(0)) && !((p_expr.pRight.flags & u32(4194304)) != u32(0)) {
		return 1
	} else {
		return 0
	}
}

@[c:'exprComputeOperands']
fn expr_compute_operands(p_parse &Parse, p_expr &Expr, p_r1 &int, p_r2 &int, p_free1 &int, p_free2 &int) int {
	addr_is_null := 0
	r1 := 0
	r2 := 0

	v := p_parse.pVdbe
	if expr_eval_rhs_first(p_expr) && sqlite3_expr_can_be_null(p_expr.pRight) {
		r2 = sqlite3_expr_code_temp(p_parse, p_expr.pRight, p_free2)
		addr_is_null = sqlite3_vdbe_add_op1(v, 51, r2)
		0
		0
	} else {
		r2 = 0
		addr_is_null = 0
	}
	r1 = sqlite3_expr_code_temp(p_parse, p_expr.pLeft, p_free1)
	if addr_is_null == 0 {
		if ((p_expr.pRight.flags & u32(4194304)) != u32(0)) && sqlite3_expr_can_be_null(p_expr.pLeft) {
			addr_is_null = sqlite3_vdbe_add_op1(v, 51, r1)
			0
			0
		}
		r2 = sqlite3_expr_code_temp(p_parse, p_expr.pRight, p_free2)
	}
	unsafe { *p_r1 = r1 }
	unsafe { *p_r2 = r2 }
	return addr_is_null
}

@[c:'exprNodeIsConstantFunction']
fn expr_node_is_constant_function(p_walker &Walker, p_expr &Expr) int {
	n := 0
	p_list := &ExprList(0)
	p_def := &FuncDef(0)
	db := &Sqlite3(0)
	if ((p_expr.flags & u32(65536)) != u32(0)) || usize(c2v_assign[&ExprList](unsafe { &p_list }, p_expr.x.pList)) == usize(0) {
		0
		n = 0
	} else {
		n = p_list.nExpr
		sqlite3_walk_expr_list(p_walker, p_list)
		if int(p_walker.eCode) == 0 {
			return 2
		}
	}
	db = p_walker.pParse.db
	p_def = sqlite3_find_function(db, p_expr.u.zToken, n, db.enc, U8(0))
	if usize(p_def) == usize(0) || !isnil(p_def.xFinalize) || (p_def.funcFlags & u32((2048 | 8192))) == u32(0) || ((p_expr.flags & u32(16777216)) != u32(0)) {
		p_walker.eCode = U16(0)
		return 2
	}
	return 1
}

@[c:'exprNodeIsConstant']
fn expr_node_is_constant(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	if int(p_walker.eCode) == 2 && ((p_expr.flags & u32(1)) != u32(0)) {
		p_walker.eCode = U16(0)
		return 2
	}
	match p_expr.op {
		172 {
			if (int(p_walker.eCode) >= 4 || ((p_expr.flags & u32(1048576)) != u32(0))) && !((p_expr.flags & u32(16777216)) != u32(0)) {
				if int(p_walker.eCode) == 5 {
					p_expr.flags |= u32(1073741824)
				}
				return 0
			} else if p_walker.pParse {
				return expr_node_is_constant_function(p_walker, p_expr)
			} else {
				p_walker.eCode = U16(0)
				return 2
			}
		}
		60 {
			if sqlite3_expr_id_to_truefalse(p_expr) {
				return 1
			}

			unsafe { goto c2v_case_30_3
			 }
		}
		168, 169, 170 {
			c2v_case_30_3:
			0
			0
			0
			0
			if ((p_expr.flags & u32(32)) != u32(0)) && int(p_walker.eCode) != 2 {
				return 0
			}
			if int(p_walker.eCode) == 3 && p_expr.iTable == p_walker.u.iCur {
				return 0
			}

			unsafe { goto c2v_case_30_10
			 }
		}
		179, 176, 142, 72 {
			c2v_case_30_10:
			0
			0
			0
			0
			p_walker.eCode = U16(0)
			return 2
		}
		157 {
			if int(p_walker.eCode) == 5 {
				p_expr.op = U8(122)
			} else if int(p_walker.eCode) == 4 {
				p_walker.eCode = U16(0)
				return 2
			}

			unsafe { goto c2v_case_30_18
			 }
		}
		else {
			c2v_case_30_18:
			0
			0
			return 0
		}
	}
	return 0
}

@[c:'exprIsConst']
fn expr_is_const(p_parse &Parse, p &Expr, init_flag int) int {
	w := Walker{}
	w.eCode = U16(init_flag)
	w.pParse = p_parse
	w.xExprCallback = expr_node_is_constant
	w.xSelectCallback = sqlite3_select_walk_fail
	sqlite3_walk_expr(&w, p)
	return int(w.eCode)
}

@[c:'sqlite3ExprIsConstant']
fn sqlite3_expr_is_constant(p_parse &Parse, p &Expr) int {
	return expr_is_const(p_parse, p, 1)
}

@[c:'sqlite3ExprIsConstantNotJoin']
fn sqlite3_expr_is_constant_not_join(p_parse &Parse, p &Expr) int {
	return expr_is_const(p_parse, p, 2)
}

@[c:'exprSelectWalkTableConstant']
fn expr_select_walk_table_constant(p_walker &Walker, p_select &Select) int {
	c2v_gc_register_thread()
	if (p_select.selFlags & u32(536870912)) != u32(0) {
		p_walker.eCode = U16(0)
		return 2
	}
	return 1
}

@[c:'sqlite3ExprIsTableConstant']
fn sqlite3_expr_is_table_constant(p &Expr, i_cur int, b_allow_subq int) int {
	w := Walker{}
	w.eCode = U16(3)
	w.pParse = 0
	w.xExprCallback = expr_node_is_constant
	if b_allow_subq {
		w.xSelectCallback = expr_select_walk_table_constant
	} else {
		w.xSelectCallback = sqlite3_select_walk_fail
	}
	w.u.iCur = i_cur
	sqlite3_walk_expr(&w, p)
	return int(w.eCode)
}

@[c:'sqlite3ExprIsSingleTableConstraint']
fn sqlite3_expr_is_single_table_constraint(p_expr &Expr, p_src_list &SrcList, i_src int, b_allow_subq int) int {
	p_src := unsafe { &p_src_list.a[0] + i_src }
	if int(p_src.fg.jointype) & 64 {
		return 0
	}
	if int(p_src.fg.jointype) & 8 {
		if !((p_expr.flags & u32(1)) != u32(0)) {
			return 0
		}
		if p_expr.w.iJoin != p_src.iCursor {
			return 0
		}
	} else {
		if ((p_expr.flags & u32(1)) != u32(0)) {
			return 0
		}
	}
	if ((p_expr.flags & u32((1 | 2))) != u32(0)) && (int(c2v_at(&p_src_list.a[0], isize(0)).fg.jointype) & 64) != 0 {
		jj := 0
		for jj = 0; jj < i_src; jj++ {
			if p_expr.w.iJoin == c2v_at(&p_src_list.a[0], isize(jj)).iCursor {
				if (int(c2v_at(&p_src_list.a[0], isize(jj)).fg.jointype) & 64) != 0 {
					return 0
				}
				break
			}
		}
	}
	return sqlite3_expr_is_table_constant(p_expr, p_src.iCursor, b_allow_subq)
}

@[c:'exprNodeIsConstantOrGroupBy']
fn expr_node_is_constant_or_group_by(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	p_group_by := p_walker.u.pGroupBy
	i := 0
	for i = 0; i < p_group_by.nExpr; i++ {
		p := c2v_at(&p_group_by.a[0], isize(i)).pExpr
		if sqlite3_expr_compare(unsafe { nil }, p_expr, p, -1) < 2 {
			p_coll := sqlite3_expr_nn_coll_seq(p_walker.pParse, p)
			if sqlite3_is_binary(p_coll) {
				return 1
			}
		}
	}
	if ((p_expr.flags & u32(4096)) != u32(0)) {
		p_walker.eCode = U16(0)
		return 2
	}
	return expr_node_is_constant(p_walker, p_expr)
}

@[c:'sqlite3ExprIsConstantOrGroupBy']
fn sqlite3_expr_is_constant_or_group_by(p_parse &Parse, p &Expr, p_group_by &ExprList) int {
	w := Walker{}
	w.eCode = U16(1)
	w.xExprCallback = expr_node_is_constant_or_group_by
	w.xSelectCallback = 0
	w.u.pGroupBy = p_group_by
	w.pParse = p_parse
	sqlite3_walk_expr(&w, p)
	return int(w.eCode)
}

@[c:'sqlite3ExprIsConstantOrFunction']
fn sqlite3_expr_is_constant_or_function(p &Expr, is_init U8) int {
	return expr_is_const(unsafe { nil }, p, 4 + int(is_init))
}

@[c:'sqlite3ExprIsInteger']
fn sqlite3_expr_is_integer(p &Expr, p_value &int, p_parse &Parse) int {
	rc := 0
	if (usize(p) == usize(0)) {
		return 0
	}
	if p.flags & u32(2048) {
		unsafe { *p_value = p.u.iValue }
		return 1
	}
	match p.op {
		173 {
			rc = sqlite3_expr_is_integer(p.pLeft, p_value, unsafe { nil })
		}
		174 {
			v := 0
			if sqlite3_expr_is_integer(p.pLeft, &v, unsafe { nil }) {
				unsafe { *p_value = -v }
				rc = 1
			}
		}
		157 {
			p_val := &Sqlite3_value(0)
			if usize(p_parse) == usize(0) {
				unsafe { goto c2v_switch_end_31
				 }
			}
			if (usize(p_parse.pVdbe) == usize(0)) {
				unsafe { goto c2v_switch_end_31
				 }
			}
			if (p_parse.db.flags & U64(8388608)) != U64(0) {
				unsafe { goto c2v_switch_end_31
				 }
			}
			sqlite3_vdbe_set_varmask(p_parse.pVdbe, int(p.iColumn))
			p_val = sqlite3_vdbe_get_bound_value(p_parse.pReprepare, int(p.iColumn), U8(65))
			if p_val {
				if sqlite3_value_type(p_val) == 1 {
					vv := sqlite3_value_int64(p_val)
					if vv == (vv & Sqlite3_int64(2147483647)) {
						unsafe { *p_value = int(vv) }
						rc = 1
					}
				}
				sqlite3_value_free_vdup7(p_val)
			}
		}
		else {
		}
	}
	c2v_switch_end_31:

	return rc
}

@[c:'sqlite3ExprCanBeNull']
fn sqlite3_expr_can_be_null(p &Expr) int {
	op := U8(0)
	for int(p.op) == 173 || int(p.op) == 174 {
		p = p.pLeft
	}
	op = p.op
	if int(op) == 176 {
		op = p.op2
	}
	match op {
		156, 118, 154, 155 {
			return 0
		}
		168 {
			return int(((p.flags & u32(2097152)) != u32(0)) || (usize(p.y.pTab) == usize(0)) || (int(p.iColumn) >= 0 && usize(p.y.pTab.aCol) != usize(0) && (int(p.iColumn) < int(p.y.pTab.nCol)) && int(p.y.pTab.aCol[p.iColumn].notNull) == 0))
		}
		else {
			return 1
		}
	}
	return 0
}

@[c:'sqlite3ExprNeedsNoAffinityChange']
fn sqlite3_expr_needs_no_affinity_change(p &Expr, aff i8) int {
	op := U8(0)
	unary_minus := 0
	if int(aff) == 65 {
		return 1
	}
	for int(p.op) == 173 || int(p.op) == 174 {
		if int(p.op) == 174 {
			unary_minus = 1
		}
		p = p.pLeft
	}
	op = p.op
	if int(op) == 176 {
		op = p.op2
	}
	match op {
		156 {
			return int(aff >= 67)
		}
		154 {
			return int(aff >= 67)
		}
		118 {
			return int(!unary_minus && int(aff) == 66)
		}
		155 {
			return int(!unary_minus)
		}
		168 {
			return int(aff >= 67 && int(p.iColumn) < 0)
		}
		else {
			return 0
		}
	}
	return 0
}

@[c:'sqlite3IsRowid']
fn sqlite3_is_rowid(z &i8) int {
	if sqlite3_str_ic_mp(z, c'_ROWID_') == 0 {
		return 1
	}
	if sqlite3_str_ic_mp(z, c'ROWID') == 0 {
		return 1
	}
	if sqlite3_str_ic_mp(z, c'OID') == 0 {
		return 1
	}
	return 0
}

@[c:'sqlite3RowidAlias']
fn sqlite3_rowid_alias(p_tab &Table) &i8 {
	az_opt := [c'_ROWID_', c'ROWID', c'OID']!

	ii := 0
	for ii = 0; ii < 3; ii++ {
		if sqlite3_column_index(p_tab, az_opt[ii]) < 0 {
			return az_opt[ii]
		}
	}
	return unsafe { nil }
}

@[c:'isCandidateForInOpt']
fn is_candidate_for_in_opt(px &Expr) &Select {
	p := &Select(0)
	p_src := &SrcList(0)
	pel_ist := &ExprList(0)
	p_tab := &Table(0)
	i := 0
	if !((px.flags & u32(4096)) != u32(0)) {
		return unsafe { nil }
	}
	if ((px.flags & u32(64)) != u32(0)) {
		return unsafe { nil }
	}
	p = px.x.pSelect
	if p.pPrior {
		return unsafe { nil }
	}
	if p.selFlags & u32((1 | 8)) {
		0
		0
		return unsafe { nil }
	}
	if p.pLimit {
		return unsafe { nil }
	}
	if p.pWhere {
		return unsafe { nil }
	}
	p_src = p.pSrc
	if p_src.nSrc != 1 {
		return unsafe { nil }
	}
	if c2v_at(&p_src.a[0], isize(0)).fg.isSubquery {
		return unsafe { nil }
	}
	p_tab = c2v_at(&p_src.a[0], isize(0)).pSTab
	if (int(p_tab.eTabType) == 1) {
		return unsafe { nil }
	}
	pel_ist = p.pEList
	for i = 0; i < pel_ist.nExpr; i++ {
		p_res := c2v_at(&pel_ist.a[0], isize(i)).pExpr
		if int(p_res.op) != 168 {
			return unsafe { nil }
		}
	}
	return p
}

@[c:'sqlite3SetHasNullFlag']
fn sqlite3_set_has_null_flag(v &Vdbe, i_cur int, reg_has_null int) {
	addr1 := 0
	sqlite3_vdbe_add_op2(v, 73, 0, reg_has_null)
	addr1 = sqlite3_vdbe_add_op1(v, 36, i_cur)
	0
	sqlite3_vdbe_add_op3(v, 96, i_cur, 0, reg_has_null)
	sqlite3_vdbe_change_p5(v, U16(128))
	0
	sqlite3_vdbe_jump_here(v, addr1)
}

@[c:'sqlite3InRhsIsConstant']
fn sqlite3_in_rhs_is_constant(p_parse &Parse, p_in &Expr) int {
	plhs := &Expr(0)
	res := 0
	plhs = p_in.pLeft
	p_in.pLeft = 0
	res = sqlite3_expr_is_constant(p_parse, p_in)
	p_in.pLeft = plhs
	return res
}

@[c:'sqlite3FindInIndex']
fn sqlite3_find_in_index(p_parse &Parse, px &Expr, in_flags u32, pr_rhs_has_null &int, ai_map &int, pi_tab &int) int {
	p := &Select(0)
	e_type := 0
	i_tab := 0
	must_be_unique := 0
	v := sqlite3_get_vdbe(p_parse)
	must_be_unique = (in_flags & u32(4)) != u32(0)
	mut __c2v_postfix_value_4 := p_parse.nTab
	p_parse.nTab++
	i_tab = __c2v_postfix_value_4
	if !isnil(pr_rhs_has_null) && ((px.flags & u32(4096)) != u32(0)) {
		i := 0
		pel_ist := px.x.pSelect.pEList
		for i = 0; i < pel_ist.nExpr; i++ {
			if sqlite3_expr_can_be_null(c2v_at(&pel_ist.a[0], isize(i)).pExpr) {
				break
			}
		}
		if i == pel_ist.nExpr {
			pr_rhs_has_null = 0
		}
	}
	if p_parse.nErr == 0 && usize(c2v_assign[&Select](unsafe { &p }, is_candidate_for_in_opt(px))) != usize(0) {
		db := p_parse.db
		p_tab := &Table(0)
		i_db := 0
		pel_ist := p.pEList
		n_expr := pel_ist.nExpr
		p_tab = c2v_at(&p.pSrc.a[0], isize(0)).pSTab
		i_db = sqlite3_schema_to_index(db, p_tab.pSchema)
		sqlite3_code_verify_schema(p_parse, i_db)
		sqlite3_table_lock(p_parse, i_db, p_tab.tnum, U8(0), p_tab.zName)
		if n_expr == 1 && int(c2v_at(&pel_ist.a[0], isize(0)).pExpr.iColumn) < 0 {
			i_addr := sqlite3_vdbe_add_op0(v, 15)
			0
			sqlite3_open_table(p_parse, i_tab, i_db, p_tab, 114)
			e_type = 1
			sqlite3_vdbe_explain(p_parse, U8(0), c'USING ROWID SEARCH ON TABLE %s FOR IN-OPERATOR', voidptr(p_tab.zName))
			sqlite3_vdbe_jump_here(v, i_addr)
		} else {
			p_idx := &Index(0)
			affinity_ok := 1
			i := 0
			for i = 0; i < n_expr && affinity_ok; i++ {
				p_lhs := sqlite3_vector_field_subexpr(px.pLeft, i)
				i_col := int(c2v_at(&pel_ist.a[0], isize(i)).pExpr.iColumn)
				idxaff := sqlite3_table_column_affinity(p_tab, i_col)
				cmpaff := sqlite3_compare_affinity(p_lhs, i8(idxaff))
				0
				0
				match int(cmpaff) {
					65 {
					}
					66 {
					}
					else {
						affinity_ok = (int(idxaff) >= 67)
					}
				}
			}
			if affinity_ok {
				for p_idx = p_tab.pIndex; !isnil(p_idx) && e_type == 0; p_idx = p_idx.pNext {
					col_used := Bitmask(0)
					m_col := Bitmask(0)
					if int(p_idx.nColumn) < n_expr {
						continue
					}
					if usize(p_idx.pPartIdxWhere) != usize(0) {
						continue
					}
					0
					0
					if int(p_idx.nColumn) >= (int((sizeof(Bitmask) * u64(8)))) - 1 {
						continue
					}
					if must_be_unique {
						if int(p_idx.nKeyCol) > n_expr || (int(p_idx.nColumn) > n_expr && !(int(p_idx.onError) != 0)) {
							continue
						}
					}
					col_used = Bitmask(0)
					for i = 0; i < n_expr; i++ {
						p_lhs := sqlite3_vector_field_subexpr(px.pLeft, i)
						p_rhs := c2v_at(&pel_ist.a[0], isize(i)).pExpr
						p_req := sqlite3_binary_compare_coll_seq(p_parse, p_lhs, p_rhs)
						j := 0
						for j = 0; j < n_expr; j++ {
							if int(p_idx.aiColumn[j]) != int(p_rhs.iColumn) {
								continue
							}
							if usize(p_req) != usize(0) && sqlite3_str_ic_mp(p_req.zName, p_idx.azColl[j]) != 0 {
								continue
							}
							break
						}
						if j == n_expr {
							break
						}
						m_col = ((Bitmask(1)) << j)
						if m_col & col_used {
							break
						}
						col_used |= m_col
						if ai_map {
							ai_map[i] = j
						}
					}
					if col_used == (((Bitmask(1)) << n_expr) - Bitmask(1)) {
						i_addr := sqlite3_vdbe_add_op0(v, 15)
						0
						sqlite3_vdbe_explain(p_parse, U8(0), c'USING INDEX %s FOR IN-OPERATOR', voidptr(p_idx.zName))
						sqlite3_vdbe_add_op3(v, 114, i_tab, int(p_idx.tnum), i_db)
						sqlite3_vdbe_set_p4_key_info(p_parse, p_idx)
						0
						e_type = 3 + int(p_idx.aSortOrder[0])
						if pr_rhs_has_null {
							unsafe { *pr_rhs_has_null = c2v_prefix_add(&p_parse.nMem, 1) }
							if n_expr == 1 {
								sqlite3_set_has_null_flag(v, i_tab, (unsafe { *pr_rhs_has_null }))
							}
						}
						sqlite3_vdbe_jump_here(v, i_addr)
					}
				}
			}
		}
	}
	if e_type == 0 && (in_flags & u32(1)) && ((px.flags & u32(4096)) == u32(0)) && (!sqlite3_in_rhs_is_constant(p_parse, px) || px.x.pList.nExpr <= 2) {
		p_parse.nTab--
		i_tab = -1
		e_type = 5
	}
	if e_type == 0 {
		saved_nq_uery_loop := u32(p_parse.nQueryLoop)
		r_may_have_null := 0
		bloom_ok := int((in_flags & u32(2)) != u32(0))
		e_type = 2
		if in_flags & u32(4) {
			p_parse.nQueryLoop = LogEst(0)
		} else if pr_rhs_has_null {
			r_may_have_null = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			unsafe { *pr_rhs_has_null = r_may_have_null }
		}
		if !bloom_ok && ((px.flags & u32(4096)) != u32(0)) && (px.x.pSelect.selFlags & u32(32)) != u32(0) {
			bloom_ok = 1
		}
		sqlite3_code_rhs_of_in(p_parse, px, i_tab, bloom_ok)
		if r_may_have_null {
			sqlite3_set_has_null_flag(v, i_tab, r_may_have_null)
		}
		p_parse.nQueryLoop = LogEst(saved_nq_uery_loop)
	}
	if !isnil(ai_map) && e_type != 3 && e_type != 4 {
		i := 0
		n := 0

		n = sqlite3_expr_vector_size(px.pLeft)
		for i = 0; i < n; i++ {
			ai_map[i] = i
		}
	}
	unsafe { *pi_tab = i_tab }
	return e_type
}

@[c:'exprINAffinity']
fn expr_in_affinity(p_parse &Parse, p_expr &Expr) &i8 {
	p_left := p_expr.pLeft
	n_val := sqlite3_expr_vector_size(p_left)
	p_select := unsafe { if ((p_expr.flags & u32(4096)) != u32(0)) {
		p_expr.x.pSelect
	} else {
		&Select(nil)
	} }
	z_ret := &i8(0)
	z_ret = &i8(sqlite3_db_malloc_raw(p_parse.db, U64(I64(1) + I64(n_val))))
	if z_ret {
		i := 0
		for i = 0; i < n_val; i++ {
			pa := sqlite3_vector_field_subexpr(p_left, i)
			a := sqlite3_expr_affinity(pa)
			if p_select {
				z_ret[i] = sqlite3_compare_affinity(c2v_at(&p_select.pEList.a[0], isize(i)).pExpr, i8(a))
			} else {
				z_ret[i] = a
			}
		}
		z_ret[n_val] = i8(`\0`)
	}
	return z_ret
}

@[c:'sqlite3SubselectError']
fn sqlite3_subselect_error(p_parse &Parse, n_actual int, n_expect int) {
	if p_parse.nErr == 0 {
		z_fmt := c'sub-select returns %d columns - expected %d'
		sqlite3_error_msg(p_parse, z_fmt, n_actual, n_expect)
	}
}

@[c:'sqlite3VectorErrorMsg']
fn sqlite3_vector_error_msg(p_parse &Parse, p_expr &Expr) {
	if ((p_expr.flags & u32(4096)) != u32(0)) {
		sqlite3_subselect_error(p_parse, p_expr.x.pSelect.pEList.nExpr, 1)
	} else {
		sqlite3_error_msg(p_parse, c'row value misused')
	}
}

@[c:'findCompatibleInRhsSubrtn']
fn find_compatible_in_rhs_subrtn(p_parse &Parse, p_expr &Expr, p_new_sig &SubrtnSig) int {
	p_op := &VdbeOp(0)
	p_end := &VdbeOp(0)

	p_sig := &SubrtnSig(0)
	v := &Vdbe(0)
	if usize(p_new_sig) == usize(0) {
		return 0
	}
	if (int(p_parse.mSubrtnSig) & (1 << (p_new_sig.selId & 7))) == 0 {
		return 0
	}
	v = p_parse.pVdbe
	p_op = sqlite3_vdbe_get_op(v, 1)
	p_end = sqlite3_vdbe_get_last_op(v)
	for ; usize(p_op) < usize(p_end); p_op = unsafe { p_op + 1 } {
		if int(p_op.p4type) != (-18) {
			continue
		}
		p_sig = p_op.p4.pSubrtnSig
		if !p_sig.bComplete {
			continue
		}
		if p_new_sig.selId != p_sig.selId {
			continue
		}
		if C.strcmp(p_new_sig.zAff, p_sig.zAff) != 0 {
			continue
		}
		p_expr.y.sub.iAddr = p_sig.iAddr
		p_expr.y.sub.regReturn = p_sig.regReturn
		p_expr.iTable = p_sig.iTable
		p_expr.flags |= u32(33554432)
		return 1
	}
	return 0
}

@[c:'sqlite3CodeRhsOfIN']
fn sqlite3_code_rhs_of_in(p_parse &Parse, p_expr &Expr, i_tab int, allow_bloom int) {
	addr_once := 0
	addr := 0
	p_left := &Expr(0)
	p_key_info := unsafe { &KeyInfo(nil) }
	n_val := 0
	v := &Vdbe(0)
	p_sig := unsafe { &SubrtnSig(nil) }
	v = p_parse.pVdbe
	if !((p_expr.flags & u32(64)) != u32(0)) && p_parse.iSelfTab == 0 {
		if ((p_expr.flags & u32(4096)) != u32(0)) && (p_expr.x.pSelect.selFlags & u32(2)) == u32(0) {
			p_sig = sqlite3_db_malloc_raw_nn(p_parse.db, U64(sizeof(SubrtnSig)))
			if p_sig {
				p_sig.selId = int(p_expr.x.pSelect.selId)
				p_sig.zAff = expr_in_affinity(p_parse, p_expr)
			}
		}
		if ((p_expr.flags & u32(33554432)) != u32(0)) || find_compatible_in_rhs_subrtn(p_parse, p_expr, p_sig) {
			addr_once = sqlite3_vdbe_add_op0(v, 15)
			0
			if ((p_expr.flags & u32(4096)) != u32(0)) {
				sqlite3_vdbe_explain(p_parse, U8(0), c'REUSE LIST SUBQUERY %d', p_expr.x.pSelect.selId)
			}
			sqlite3_vdbe_add_op2(v, 10, p_expr.y.sub.regReturn, p_expr.y.sub.iAddr)
			sqlite3_vdbe_add_op2(v, 117, i_tab, p_expr.iTable)
			sqlite3_vdbe_jump_here(v, addr_once)
			if p_sig {
				sqlite3_db_free(p_parse.db, voidptr(p_sig.zAff))
				sqlite3_db_free(p_parse.db, voidptr(p_sig))
			}
			return
		}
		p_expr.flags |= u32(33554432)
		p_expr.y.sub.regReturn = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		p_expr.y.sub.iAddr = sqlite3_vdbe_add_op2(v, 76, 0, p_expr.y.sub.regReturn) + 1
		if p_sig {
			p_sig.bComplete = U8(0)
			p_sig.iAddr = p_expr.y.sub.iAddr
			p_sig.regReturn = p_expr.y.sub.regReturn
			p_sig.iTable = i_tab
			p_parse.mSubrtnSig = U8(1 << (p_sig.selId & 7))
			sqlite3_vdbe_change_p4(v, -1, &i8(voidptr(p_sig)), (-18))
		}
		addr_once = sqlite3_vdbe_add_op0(v, 15)
		0
	}
	p_left = p_expr.pLeft
	n_val = sqlite3_expr_vector_size(p_left)
	p_expr.iTable = i_tab
	addr = sqlite3_vdbe_add_op2(v, 120, p_expr.iTable, n_val)
	p_key_info = sqlite3_key_info_alloc(p_parse.db, n_val, 1)
	if ((p_expr.flags & u32(4096)) != u32(0)) {
		p_select := p_expr.x.pSelect
		pel_ist := p_select.pEList
		sqlite3_vdbe_explain(p_parse, U8(1), c'%sLIST SUBQUERY %d', voidptr(if addr_once {
			c''
		} else {
			c'CORRELATED '
		}), p_select.selId)
		if (pel_ist.nExpr == n_val) {
			p_copy := &Select(0)
			dest := SelectDest{}
			i := 0
			rc := 0
			addr_bloom := 0
			sqlite3_select_dest_init(&dest, 9, i_tab)
			dest.zAffSdst = expr_in_affinity(p_parse, p_expr)
			p_select.iLimit = 0
			if addr_once && allow_bloom && ((p_parse.db.dbOptFlags & u32(524288)) == u32(0)) {
				reg_bloom := c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
				addr_bloom = sqlite3_vdbe_add_op2(v, 79, 10000, reg_bloom)
				0
				dest.iSDParm2 = reg_bloom
			}
			0
			0
			p_copy = sqlite3_select_dup(p_parse.db, p_select, 0)
			rc = if int(p_parse.db.mallocFailed) { 1 } else { sqlite3_select(p_parse, p_copy, &dest) }
			sqlite3_select_delete(p_parse.db, p_copy)
			sqlite3_db_free(p_parse.db, voidptr(dest.zAffSdst))
			if addr_bloom {
				mut __c2v_lhs_tmp_100 := sqlite3_vdbe_get_op(v, addr_once)
				__c2v_lhs_tmp_100.p3 = dest.iSDParm2
				if dest.iSDParm2 == 0 {
					mut __c2v_lhs_tmp_101 := sqlite3_vdbe_get_op(v, addr_bloom)
					__c2v_lhs_tmp_101.p1 = 10
				}
			}
			if rc {
				sqlite3_key_info_unref(p_key_info)
				return
			}
			for i = 0; i < n_val; i++ {
				p := sqlite3_vector_field_subexpr(p_left, i)
				(&p_key_info.aColl[0])[i] = sqlite3_binary_compare_coll_seq(p_parse, p, c2v_at(&pel_ist.a[0], isize(i)).pExpr)
			}
		}
	} else if (usize(p_expr.x.pList) != usize(0)) {
		affinity := i8(0)
		i := 0
		p_list := p_expr.x.pList
		p_item := &ExprList_item(0)
		r1 := 0
		r2 := 0

		affinity = sqlite3_expr_affinity(p_left)
		if int(affinity) <= 64 {
			affinity = i8(65)
		} else if int(affinity) == 69 {
			affinity = i8(67)
		}
		if p_key_info {
			(&p_key_info.aColl[0])[0] = sqlite3_expr_coll_seq(p_parse, p_expr.pLeft)
		}
		r1 = sqlite3_get_temp_reg(p_parse)
		r2 = sqlite3_get_temp_reg(p_parse)
		i = p_list.nExpr
		for p_item = unsafe { &p_list.a[0] }; i > 0; i-- {
			p_e2 := p_item.pExpr
			if addr_once && !sqlite3_expr_is_constant(p_parse, p_e2) {
				sqlite3_vdbe_change_to_noop(v, addr_once - 1)
				sqlite3_vdbe_change_to_noop(v, addr_once)
				p_expr.flags &= ~u32(33554432)
				addr_once = 0
			}
			sqlite3_expr_code(p_parse, p_e2, r1)
			sqlite3_vdbe_add_op4(v, 99, r1, 1, r2, &affinity, 1)
			sqlite3_vdbe_add_op4_int(v, 140, i_tab, r2, r1, 1)
			c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
		}
		sqlite3_release_temp_reg(p_parse, r1)
		sqlite3_release_temp_reg(p_parse, r2)
	}
	if p_sig {
		p_sig.bComplete = U8(1)
	}
	if p_key_info {
		sqlite3_vdbe_change_p4(v, addr, &i8(voidptr(p_key_info)), (-9))
	}
	if addr_once {
		sqlite3_vdbe_add_op1(v, 138, i_tab)
		sqlite3_vdbe_jump_here(v, addr_once)
		sqlite3_vdbe_add_op3(v, 69, p_expr.y.sub.regReturn, p_expr.y.sub.iAddr, 1)
		0
		sqlite3_clear_temp_reg_cache(p_parse)
	}
}

@[c:'sqlite3CodeSubselect']
fn sqlite3_code_subselect(p_parse &Parse, p_expr &Expr) int {
	addr_once := 0
	r_reg := 0
	p_sel := &Select(0)
	dest := SelectDest{}
	n_reg := 0
	p_limit := &Expr(0)
	v := p_parse.pVdbe
	if p_parse.nErr {
		return 0
	}
	0
	0
	p_sel = p_expr.x.pSelect
	if ((p_expr.flags & u32(33554432)) != u32(0)) {
		sqlite3_vdbe_explain(p_parse, U8(0), c'REUSE SUBQUERY %d', p_sel.selId)
		sqlite3_vdbe_add_op2(v, 10, p_expr.y.sub.regReturn, p_expr.y.sub.iAddr)
		return p_expr.iTable
	}
	p_expr.flags |= u32(33554432)
	p_expr.y.sub.regReturn = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	p_expr.y.sub.iAddr = sqlite3_vdbe_add_op2(v, 76, 0, p_expr.y.sub.regReturn) + 1
	if !((p_expr.flags & u32(64)) != u32(0)) {
		addr_once = sqlite3_vdbe_add_op0(v, 15)
		0
	}
	sqlite3_vdbe_explain(p_parse, U8(1), c'%sSCALAR SUBQUERY %d', voidptr(if addr_once {
		c''
	} else {
		c'CORRELATED '
	}), p_sel.selId)
	0
	n_reg = if int(p_expr.op) == 139 { p_sel.pEList.nExpr } else { 1 }
	sqlite3_select_dest_init(&dest, 0, p_parse.nMem + 1)
	p_parse.nMem += n_reg
	if int(p_expr.op) == 139 {
		dest.eDest = U8(8)
		if (p_sel.selFlags & u32(1)) && !isnil(p_sel.pLimit) && !isnil(p_sel.pLimit.pRight) {
			dest.iSdst = p_parse.nMem + 1
			p_parse.nMem += n_reg
		} else {
			dest.iSdst = dest.iSDParm
		}
		dest.nSdst = n_reg
		sqlite3_vdbe_add_op3(v, 77, 0, dest.iSDParm, p_parse.nMem)
		0
	} else {
		dest.eDest = U8(1)
		sqlite3_vdbe_add_op2(v, 73, 0, dest.iSDParm)
		0
	}
	if p_sel.pLimit {
		p_left := p_sel.pLimit.pLeft
		if ((p_left.flags & u32(2048)) != u32(0)) == 0 || (p_left.u.iValue != 1 && p_left.u.iValue != 0) {
			db := p_parse.db
			p_limit = sqlite3_expr_int32(db, 0)
			if p_limit {
				p_limit.affExpr = i8(67)
				p_limit = sqlite3_pe_xpr(p_parse, 53, sqlite3_expr_dup(db, p_left, 0), p_limit)
			}
			sqlite3_expr_deferred_delete(p_parse, p_left)
			p_sel.pLimit.pLeft = p_limit
		}
	} else {
		p_limit = sqlite3_expr_int32(p_parse.db, 1)
		p_sel.pLimit = sqlite3_pe_xpr(p_parse, 149, p_limit, unsafe { nil })
	}
	p_sel.iLimit = 0
	if sqlite3_select(p_parse, p_sel, &dest) {
		p_expr.op2 = p_expr.op
		p_expr.op = U8(182)
		return 0
	}
	r_reg = dest.iSDParm
	p_expr.iTable = r_reg
	0
	if addr_once {
		sqlite3_vdbe_jump_here(v, addr_once)
	}
	0
	sqlite3_vdbe_add_op3(v, 69, p_expr.y.sub.regReturn, p_expr.y.sub.iAddr, 1)
	0
	sqlite3_clear_temp_reg_cache(p_parse)
	return r_reg
}

@[c:'sqlite3ExprCheckIN']
fn sqlite3_expr_check_in(p_parse &Parse, p_in &Expr) int {
	n_vector := sqlite3_expr_vector_size(p_in.pLeft)
	if ((p_in.flags & u32(4096)) != u32(0)) && !p_parse.db.mallocFailed {
		if n_vector != p_in.x.pSelect.pEList.nExpr {
			sqlite3_subselect_error(p_parse, p_in.x.pSelect.pEList.nExpr, n_vector)
			return 1
		}
	} else if n_vector != 1 {
		sqlite3_vector_error_msg(p_parse, p_in.pLeft)
		return 1
	}
	return 0
}

@[c:'sqlite3ExprCodeIN']
fn sqlite3_expr_code_in(p_parse &Parse, p_expr &Expr, dest_if_false int, dest_if_null int) {
	r_rhs_has_null := 0
	e_type := 0
	r_lhs := 0
	v := &Vdbe(0)
	ai_map := unsafe { &int(nil) }
	z_aff := unsafe { &i8(nil) }
	n_vector := 0
	i_dummy := 0
	p_left := &Expr(0)
	i := 0
	dest_step2 := 0
	dest_step6 := 0
	addr_truth_op := 0
	dest_not_null := 0
	addr_top := 0
	i_tab := 0
	ok_const_factor := U8(p_parse.okConstFactor)
	p_left = p_expr.pLeft
	if sqlite3_expr_check_in(p_parse, p_expr) {
		return
	}
	z_aff = expr_in_affinity(p_parse, p_expr)
	n_vector = sqlite3_expr_vector_size(p_expr.pLeft)
	ai_map = &int(sqlite3_db_malloc_zero(p_parse.db, U64(u64(n_vector) * sizeof(int))))
	if p_parse.db.mallocFailed {
		unsafe { goto sqlite3ExprCodeIN_oom_error
		 }
	}
	v = p_parse.pVdbe
	0
	e_type = sqlite3_find_in_index(p_parse, p_expr, u32(2 | 1), unsafe { if dest_if_false == dest_if_null {
		&int(nil)
	} else {
		&r_rhs_has_null
	} }, ai_map, &i_tab)
	p_parse.okConstFactor = Bft(0)
	r_lhs = expr_code_vector(p_parse, p_left, &i_dummy)
	p_parse.okConstFactor = Bft(ok_const_factor)
	if e_type == 5 {
		p_list := &ExprList(0)
		p_coll := &CollSeq(0)
		label_ok := sqlite3_vdbe_make_label(p_parse)
		r2 := 0
		reg_to_free := 0

		reg_ck_null := 0
		ii := 0
		p_list = p_expr.x.pList
		p_coll = sqlite3_expr_coll_seq(p_parse, p_expr.pLeft)
		if dest_if_null != dest_if_false {
			reg_ck_null = sqlite3_get_temp_reg(p_parse)
			sqlite3_vdbe_add_op3(v, 103, r_lhs, r_lhs, reg_ck_null)
		}
		for ii = 0; ii < p_list.nExpr; ii++ {
			r2 = sqlite3_expr_code_temp(p_parse, c2v_at(&p_list.a[0], isize(ii)).pExpr, &reg_to_free)
			if reg_ck_null && sqlite3_expr_can_be_null(c2v_at(&p_list.a[0], isize(ii)).pExpr) {
				sqlite3_vdbe_add_op3(v, 103, reg_ck_null, r2, reg_ck_null)
			}
			sqlite3_release_temp_reg(p_parse, reg_to_free)
			if ii < p_list.nExpr - 1 || dest_if_null != dest_if_false {
				op := if r_lhs != r2 { 54 } else { 52 }
				sqlite3_vdbe_add_op4(v, op, r_lhs, label_ok, r2, &i8(voidptr(p_coll)), (-2))
				0
				0
				0
				0
				sqlite3_vdbe_change_p5(v, U16(z_aff[0]))
			} else {
				op := if r_lhs != r2 { 53 } else { 51 }
				sqlite3_vdbe_add_op4(v, op, r_lhs, dest_if_false, r2, &i8(voidptr(p_coll)), (-2))
				0
				0
				sqlite3_vdbe_change_p5(v, U16(int(z_aff[0]) | 16))
			}
		}
		if reg_ck_null {
			sqlite3_vdbe_add_op2(v, 51, reg_ck_null, dest_if_null)
			0
			sqlite3_vdbe_goto(v, dest_if_false)
		}
		sqlite3_vdbe_resolve_label(v, label_ok)
		sqlite3_release_temp_reg(p_parse, reg_ck_null)
		unsafe { goto sqlite3ExprCodeIN_finished
		 }
	}
	if e_type != 1 {
		sqlite3_vdbe_add_op4(v, 98, r_lhs, n_vector, 0, z_aff, n_vector)
		for i = 0; i < n_vector && ai_map[i] == i; i++ {
		}
		if i != n_vector {
			r_lhs_orig := r_lhs
			r_lhs = sqlite3_get_temp_range(p_parse, n_vector)
			for i = 0; i < n_vector; i++ {
				sqlite3_vdbe_add_op3(v, 82, r_lhs_orig + i, r_lhs + ai_map[i], 0)
			}
			sqlite3_release_temp_reg(p_parse, r_lhs_orig)
		}
	}
	if dest_if_null == dest_if_false {
		dest_step2 = dest_if_false
	} else {
		dest_step6 = sqlite3_vdbe_make_label(p_parse)
		dest_step2 = dest_step6
	}
	for i = 0; i < n_vector; i++ {
		p := sqlite3_vector_field_subexpr(p_expr.pLeft, i)
		if p_parse.nErr {
			unsafe { goto sqlite3ExprCodeIN_oom_error
			 }
		}
		if sqlite3_expr_can_be_null(p) {
			sqlite3_vdbe_add_op2(v, 51, r_lhs + ai_map[i], dest_step2)
			0
		}
	}
	if e_type == 1 {
		sqlite3_vdbe_add_op3(v, 30, i_tab, dest_if_false, r_lhs)
		0
		addr_truth_op = sqlite3_vdbe_add_op0(v, 9)
	} else {
		if dest_if_false == dest_if_null {
			if ((p_expr.flags & u32(33554432)) != u32(0)) {
				p_op := sqlite3_vdbe_get_op(v, p_expr.y.sub.iAddr)
				if p_op.p3 > 0 {
					sqlite3_vdbe_add_op4_int(v, 66, p_op.p3, dest_if_false, r_lhs, n_vector)
					0
				}
			}
			sqlite3_vdbe_add_op4_int(v, 28, i_tab, dest_if_false, r_lhs, n_vector)
			0
			unsafe { goto sqlite3ExprCodeIN_finished
			 }
		}
		addr_truth_op = sqlite3_vdbe_add_op4_int(v, 29, i_tab, 0, r_lhs, n_vector)
		0
	}
	if r_rhs_has_null && n_vector == 1 {
		sqlite3_vdbe_add_op2(v, 52, r_rhs_has_null, dest_if_false)
		0
	}
	if dest_if_false == dest_if_null {
		sqlite3_vdbe_goto(v, dest_if_false)
	}
	if dest_step6 {
		sqlite3_vdbe_resolve_label(v, dest_step6)
	}
	addr_top = sqlite3_vdbe_add_op2(v, 36, i_tab, dest_if_false)
	0
	if n_vector > 1 {
		dest_not_null = sqlite3_vdbe_make_label(p_parse)
	} else {
		dest_not_null = dest_if_false
	}
	for i = 0; i < n_vector; i++ {
		p := &Expr(0)
		p_coll := &CollSeq(0)
		r3 := sqlite3_get_temp_reg(p_parse)
		p = sqlite3_vector_field_subexpr(p_left, i)
		if ((p_expr.flags & u32(4096)) != u32(0)) {
			p_rhs := c2v_at(&p_expr.x.pSelect.pEList.a[0], isize(i)).pExpr
			p_coll = sqlite3_binary_compare_coll_seq(p_parse, p, p_rhs)
		} else {
			p_coll = sqlite3_expr_coll_seq(p_parse, p)
		}
		sqlite3_vdbe_add_op3(v, 96, i_tab, ai_map[i], r3)
		sqlite3_vdbe_add_op4(v, 53, r_lhs + ai_map[i], dest_not_null, r3, &i8(voidptr(p_coll)), (-2))
		0
		sqlite3_release_temp_reg(p_parse, r3)
	}
	sqlite3_vdbe_add_op2(v, 9, 0, dest_if_null)
	if n_vector > 1 {
		sqlite3_vdbe_resolve_label(v, dest_not_null)
		sqlite3_vdbe_add_op2(v, 40, i_tab, addr_top + 1)
		0
		sqlite3_vdbe_add_op2(v, 9, 0, dest_if_false)
	}
	sqlite3_vdbe_jump_here(v, addr_truth_op)
	sqlite3ExprCodeIN_finished:
	0
	sqlite3ExprCodeIN_oom_error:
	sqlite3_db_free(p_parse.db, voidptr(ai_map))
	sqlite3_db_free(p_parse.db, voidptr(z_aff))
}

@[c:'codeReal']
fn code_real(v &Vdbe, z &i8, negate_flag int, i_mem int) {
	if (usize(z) != usize(0)) {
		value := 0.0
		sqlite3_ato_f(z, &value)
		if negate_flag {
			value = -value
		}
		sqlite3_vdbe_add_op4_dup8(v, 154, 0, i_mem, 0, &U8(c2v_address_of(&value)), (-13))
	}
}

@[c:'codeInteger']
fn code_integer(p_parse &Parse, p_expr &Expr, neg_flag int, i_mem int) {
	v := p_parse.pVdbe
	if p_expr.flags & u32(2048) {
		i := p_expr.u.iValue
		if neg_flag {
			i = -i
		}
		sqlite3_vdbe_add_op2(v, 73, i, i_mem)
	} else {
		c := 0
		value := I64(0)
		z := p_expr.u.zToken
		c = sqlite3_dec_or_hex_to_i64(z, &value)
		if (c == 3 && !neg_flag) || (c == 2) || (neg_flag && value == ((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32)))) {
			if sqlite3_strnicmp(z, c'0x', 2) == 0 {
				sqlite3_error_msg(p_parse, c'hex literal too big: %s%#T', voidptr(if neg_flag {
					c'-'
				} else {
					c''
				}), voidptr(p_expr))
			} else {
				code_real(v, z, neg_flag, i_mem)
			}
		} else {
			if neg_flag {
				value = if c == 3 {
					((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32)))
				} else {
					-value
				}
			}
			sqlite3_vdbe_add_op4_dup8(v, 74, 0, i_mem, 0, &U8(c2v_address_of(&value)), (-14))
		}
	}
}

@[c:'sqlite3ExprCodeLoadIndexColumn']
fn sqlite3_expr_code_load_index_column(p_parse &Parse, p_idx &Index, i_tab_cur int, i_idx_col int, reg_out int) {
	i_tab_col := p_idx.aiColumn[i_idx_col]
	if int(i_tab_col) == (-2) {
		p_parse.iSelfTab = i_tab_cur + 1
		sqlite3_expr_code_copy(p_parse, c2v_at(&p_idx.aColExpr.a[0], isize(i_idx_col)).pExpr, reg_out)
		p_parse.iSelfTab = 0
	} else {
		sqlite3_expr_code_get_column_of_table(p_parse.pVdbe, p_idx.pTable, i_tab_cur, int(i_tab_col), reg_out)
	}
}

@[c:'sqlite3ExprCodeGeneratedColumn']
fn sqlite3_expr_code_generated_column(p_parse &Parse, p_tab &Table, p_col &Column, reg_out int) {
	i_addr := 0
	v := p_parse.pVdbe
	n_err := p_parse.nErr
	if p_parse.iSelfTab > 0 {
		i_addr = sqlite3_vdbe_add_op3(v, 20, p_parse.iSelfTab - 1, 0, reg_out)
	} else {
		i_addr = 0
	}
	sqlite3_expr_code_copy(p_parse, sqlite3_column_expr(p_tab, p_col), reg_out)
	if (int(p_col.colFlags) & 32) != 0 && (p_tab.tabFlags & u32(65536)) != u32(0) {
		p3 := 2 + int((i64((isize(p_col) - isize(p_tab.aCol)) / isize(sizeof(Column)))))
		sqlite3_vdbe_add_op4(v, 97, reg_out, 1, p3, &i8(voidptr(p_tab)), (-5))
	} else if int(p_col.affinity) >= 66 {
		sqlite3_vdbe_add_op4(v, 98, reg_out, 1, 0, &p_col.affinity, 1)
	}
	if i_addr {
		sqlite3_vdbe_jump_here(v, i_addr)
	}
	if p_parse.nErr > n_err {
		p_parse.db.errByteOffset = -1
	}
}

@[c:'sqlite3ExprCodeGetColumnOfTable']
fn sqlite3_expr_code_get_column_of_table(v &Vdbe, p_tab &Table, i_tab_cur int, i_col int, reg_out int) {
	p_col := &Column(0)
	if i_col < 0 || i_col == int(p_tab.iPKey) {
		sqlite3_vdbe_add_op2(v, 137, i_tab_cur, reg_out)
		0
	} else {
		op := 0
		x := 0
		if (int(p_tab.eTabType) == 1) {
			op = 178
			x = i_col
		} else {
			p_col = unsafe { p_tab.aCol + i_col }
			if int(p_col.colFlags) & 32 {
				p_parse := sqlite3_vdbe_parser(v)
				if int(p_col.colFlags) & 256 {
					sqlite3_error_msg(p_parse, c'generated column loop on "%s"', voidptr(p_col.zCnName))
				} else {
					saved_self_tab := p_parse.iSelfTab
					p_col.colFlags |= 256
					p_parse.iSelfTab = i_tab_cur + 1
					sqlite3_expr_code_generated_column(p_parse, p_tab, p_col, reg_out)
					p_parse.iSelfTab = saved_self_tab
					p_col.colFlags &= ~256
				}
				return
			} else if !((p_tab.tabFlags & u32(128)) == u32(0)) {
				0
				x = sqlite3_table_column_to_index(sqlite3_primary_key_index(p_tab), i_col)
				op = 96
			} else {
				x = int(sqlite3_table_column_to_storage(p_tab, I16(i_col)))
				0
				op = 96
			}
		}
		sqlite3_vdbe_add_op3(v, op, i_tab_cur, x, reg_out)
		sqlite3_column_default(v, p_tab, i_col, reg_out)
	}
}

@[c:'sqlite3ExprCodeGetColumn']
fn sqlite3_expr_code_get_column(p_parse &Parse, p_tab &Table, i_column int, i_table int, i_reg int, p5 U8) int {
	sqlite3_expr_code_get_column_of_table(p_parse.pVdbe, p_tab, i_table, i_column, i_reg)
	if p5 {
		p_op := sqlite3_vdbe_get_last_op(p_parse.pVdbe)
		if int(p_op.opcode) == 96 {
			p_op.p5 = U16(p5)
		}
		if int(p_op.opcode) == 178 {
			p_op.p5 = U16((int(p5) & 1))
		}
	}
	return i_reg
}

@[c:'sqlite3ExprCodeMove']
fn sqlite3_expr_code_move(p_parse &Parse, i_from int, i_to int, n_reg int) {
	sqlite3_vdbe_add_op3(p_parse.pVdbe, 81, i_from, i_to, n_reg)
}

@[c:'sqlite3ExprToRegister']
fn sqlite3_expr_to_register(p_expr &Expr, i_reg int) {
	p := sqlite3_expr_skip_collate_and_likely(p_expr)
	if (usize(p) == usize(0)) {
		return
	}
	if int(p.op) == 176 {
	} else {
		p.op2 = p.op
		p.op = U8(176)
		p.iTable = i_reg
		p.flags &= ~u32(8192)
	}
}

@[c:'exprCodeVector']
fn expr_code_vector(p_parse &Parse, p &Expr, pi_freeable &int) int {
	i_result := 0
	n_result := sqlite3_expr_vector_size(p)
	if n_result == 1 {
		i_result = sqlite3_expr_code_temp(p_parse, p, pi_freeable)
	} else {
		unsafe { *pi_freeable = 0 }
		if int(p.op) == 139 {
			i_result = sqlite3_code_subselect(p_parse, p)
		} else {
			i := 0
			i_result = p_parse.nMem + 1
			p_parse.nMem += n_result
			for i = 0; i < n_result; i++ {
				sqlite3_expr_code_factorable(p_parse, c2v_at(&p.x.pList.a[0], isize(i)).pExpr, i + i_result)
			}
		}
	}
	return i_result
}

@[c:'setDoNotMergeFlagOnCopy']
fn set_do_not_merge_flag_on_copy(v &Vdbe) {
	if int(sqlite3_vdbe_get_last_op(v).opcode) == 82 {
		sqlite3_vdbe_change_p5(v, U16(1))
	}
}

@[c:'exprCodeInlineFunction']
fn expr_code_inline_function(p_parse &Parse, p_farg &ExprList, i_func_id int, target int) int {
	n_farg := 0
	v := p_parse.pVdbe
	n_farg = p_farg.nExpr
	match i_func_id {
		0 {
			end_coalesce := sqlite3_vdbe_make_label(p_parse)
			i := 0
			sqlite3_expr_code(p_parse, c2v_at(&p_farg.a[0], isize(0)).pExpr, target)
			for i = 1; i < n_farg; i++ {
				sqlite3_vdbe_add_op2(v, 52, target, end_coalesce)
				0
				sqlite3_expr_code(p_parse, c2v_at(&p_farg.a[0], isize(i)).pExpr, target)
			}
			set_do_not_merge_flag_on_copy(v)
			sqlite3_vdbe_resolve_label(v, end_coalesce)
		}
		5 {
			case_expr := Expr{}
			C.memset(voidptr(&case_expr), 0, sizeof(case_expr))
			case_expr.op = U8(158)
			case_expr.x.pList = p_farg
			return sqlite3_expr_code_target(p_parse, &case_expr, target)
		}
		3 {
			sqlite3_vdbe_add_op2(v, 73, sqlite3_expr_compare(unsafe { nil }, c2v_at(&p_farg.a[0], isize(0)).pExpr, c2v_at(&p_farg.a[0], isize(1)).pExpr, -1), target)
		}
		2 {
			sqlite3_vdbe_add_op2(v, 73, sqlite3_expr_implies_expr(p_parse, c2v_at(&p_farg.a[0], isize(0)).pExpr, c2v_at(&p_farg.a[0], isize(1)).pExpr, -1), target)
		}
		1 {
			p_a1 := &Expr(0)
			p_a1 = c2v_at(&p_farg.a[0], isize(1)).pExpr
			if int(p_a1.op) == 168 {
				sqlite3_vdbe_add_op2(v, 73, sqlite3_expr_implies_non_null_row(c2v_at(&p_farg.a[0], isize(0)).pExpr, p_a1.iTable, 1), target)
			} else {
				sqlite3_vdbe_add_op2(v, 77, 0, target)
			}
		}
		4 {
			az_aff := [c'blob', c'text', c'numeric', c'integer', c'real', c'flexnum']

			aff := i8(0)
			aff = sqlite3_expr_affinity(c2v_at(&p_farg.a[0], isize(0)).pExpr)
			sqlite3_vdbe_load_string(v, target, unsafe { if (int(aff) <= 64) {
				c'none'
			} else {
				az_aff[int(aff) - 65]
			} })
		}
		else {
			target = sqlite3_expr_code_target(p_parse, c2v_at(&p_farg.a[0], isize(0)).pExpr, target)
		}
	}

	return target
}

@[c:'exprNodeCanReturnSubtype']
fn expr_node_can_return_subtype(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	n := 0
	p_def := &FuncDef(0)
	db := &Sqlite3(0)
	if int(p_expr.op) == 158 || int(p_expr.op) == 173 || int(p_expr.op) == 114 || int(p_expr.op) == 36 {
		return 0
	}
	if int(p_expr.op) != 172 {
		return 1
	}
	db = p_walker.pParse.db
	n = if p_expr.x.pList { p_expr.x.pList.nExpr } else { 0 }
	p_def = sqlite3_find_function(db, p_expr.u.zToken, n, db.enc, U8(0))
	if (usize(p_def) == usize(0)) || (p_def.funcFlags & u32(16777216)) != u32(0) {
		p_walker.eCode = U16(1)
		return 2
	}
	return 0
}

@[c:'sqlite3ExprCanReturnSubtype']
fn sqlite3_expr_can_return_subtype(p_parse &Parse, p_expr &Expr) int {
	w := Walker{}
	C.memset(voidptr(&w), 0, sizeof(w))
	w.pParse = p_parse
	w.xExprCallback = expr_node_can_return_subtype
	sqlite3_walk_expr(&w, p_expr)
	return int(w.eCode)
}

@[c:'sqlite3IndexedExprLookup']
fn sqlite3_indexed_expr_lookup(p_parse &Parse, p_expr &Expr, target int) int {
	p := &IndexedExpr(0)
	v := &Vdbe(0)
	for p = p_parse.pIdxEpr; p; p = p.pIENext {
		expr_aff := U8(0)
		i_data_cur := p.iDataCur
		if i_data_cur < 0 {
			continue
		}
		if p_parse.iSelfTab {
			if p.iDataCur != p_parse.iSelfTab - 1 {
				continue
			}
			i_data_cur = -1
		}
		if sqlite3_expr_compare(unsafe { nil }, p_expr, p.pExpr, i_data_cur) != 0 {
			continue
		}
		expr_aff = U8(sqlite3_expr_affinity(p_expr))
		if (int(expr_aff) <= 65 && int(p.aff) != 65) || (int(expr_aff) == 66 && int(p.aff) != 66) || (int(expr_aff) >= 67 && int(p.aff) != 67) {
			continue
		}
		if ((p_expr.flags & u32(u32(2147483648))) != u32(0)) && sqlite3_expr_can_return_subtype(p_parse, p_expr) {
			continue
		}
		v = p_parse.pVdbe
		if p.bMaybeNullRow {
			addr := sqlite3_vdbe_current_addr(v)
			sqlite3_vdbe_add_op3(v, 20, p.iIdxCur, addr + 3, target)
			0
			sqlite3_vdbe_add_op3(v, 96, p.iIdxCur, p.iIdxCol, target)
			0
			sqlite3_vdbe_goto(v, 0)
			p = p_parse.pIdxEpr
			p_parse.pIdxEpr = 0
			sqlite3_expr_code(p_parse, p_expr, target)
			p_parse.pIdxEpr = p
			sqlite3_vdbe_jump_here(v, addr + 2)
		} else {
			sqlite3_vdbe_add_op3(v, 96, p.iIdxCur, p.iIdxCol, target)
			0
		}
		return target
	}
	return -1
}

@[c:'exprPartidxExprLookup']
fn expr_partidx_expr_lookup(p_parse &Parse, p_expr &Expr, i_target int) int {
	p := &IndexedExpr(0)
	for p = p_parse.pIdxPartExpr; p; p = p.pIENext {
		if int(p_expr.iColumn) == p.iIdxCol && p_expr.iTable == p.iDataCur {
			v := p_parse.pVdbe
			addr := 0
			ret := 0
			if p.bMaybeNullRow {
				addr = sqlite3_vdbe_add_op1(v, 20, p.iIdxCur)
			}
			ret = sqlite3_expr_code_target(p_parse, p.pExpr, i_target)
			sqlite3_vdbe_add_op4(p_parse.pVdbe, 98, ret, 1, 0, &i8(voidptr(&p.aff)), 1)
			if addr {
				sqlite3_vdbe_jump_here(v, addr)
				sqlite3_vdbe_change_p3(v, addr, ret)
			}
			return ret
		}
	}
	return 0
}

@[c:'exprCodeTargetAndOr']
fn expr_code_target_and_or(p_parse &Parse, p_expr &Expr, target int, p_tmp_reg &int) int {
	op := 0
	skip_op := 0
	addr_skip := 0
	reg_ss := 0
	r1 := 0
	r2 := 0

	p_alt := &Expr(0)
	v := &Vdbe(0)
	op = int(p_expr.op)
	0
	0
	v = p_parse.pVdbe
	p_alt = sqlite3_expr_simplified_and_or(p_expr)
	if usize(p_alt) != usize(p_expr) {
		r1 = sqlite3_expr_code_target(p_parse, p_alt, target)
		sqlite3_vdbe_add_op3(v, 44, r1, r1, target)
		return target
	}
	skip_op = if op == 44 { 17 } else { 16 }
	if expr_eval_rhs_first(p_expr) {
		reg_ss = sqlite3_expr_code_target(p_parse, p_expr.pRight, target)
		r2 = reg_ss
		addr_skip = sqlite3_vdbe_add_op1(v, skip_op, r2)
		0
		0
		r1 = sqlite3_expr_code_temp(p_parse, p_expr.pLeft, p_tmp_reg)
	} else {
		r1 = sqlite3_expr_code_target(p_parse, p_expr.pLeft, target)
		if ((p_expr.pRight.flags & u32(4194304)) != u32(0)) {
			reg_ss = r1
			addr_skip = sqlite3_vdbe_add_op1(v, skip_op, r1)
			0
			0
		} else {
			reg_ss = 0
			addr_skip = reg_ss
		}
		r2 = sqlite3_expr_code_temp(p_parse, p_expr.pRight, p_tmp_reg)
	}
	sqlite3_vdbe_add_op3(v, op, r2, r1, target)
	0
	if addr_skip {
		sqlite3_vdbe_add_op2(v, 9, 0, sqlite3_vdbe_current_addr(v) + 2)
		sqlite3_vdbe_jump_here(v, addr_skip)
		sqlite3_vdbe_add_op3(v, 43, reg_ss, reg_ss, target)
		0
	}
	return target
}

@[c:'sqlite3ExprCodeTarget']
fn sqlite3_expr_code_target(p_parse &Parse, p_expr &Expr, target int) int {
	v := p_parse.pVdbe
	op := 0
	in_reg := target
	reg_free1 := 0
	reg_free2 := 0
	r1 := 0
	r2 := 0

	temp_x := Expr{}
	p5 := 0
	expr_code_doover:
	if usize(p_expr) == usize(0) {
		op = 122
	} else {
		if usize(p_parse.pIdxEpr) != usize(0) && !((p_expr.flags & u32(8388608)) != u32(0)) && c2v_assign[int](unsafe { &r1 }, int(sqlite3_indexed_expr_lookup(p_parse, p_expr, target))) >= 0 {
			return r1
		} else {
			op = int(p_expr.op)
		}
	}
	match op {
		170 {
			p_agg_info := p_expr.pAggInfo
			p_col := &AggInfo_col(0)
			if int(p_expr.iAgg) >= p_agg_info.nColumn {
				sqlite3_vdbe_add_op2(v, 77, 0, target)
				unsafe { goto c2v_switch_end_36
				 }
			}
			p_col = unsafe { p_agg_info.aCol + p_expr.iAgg }
			if !p_agg_info.directMode {
				return p_agg_info.iFirstReg + int(p_expr.iAgg)
			} else if p_agg_info.useSortingIdx {
				p_tab := p_col.pTab
				sqlite3_vdbe_add_op3(v, 96, p_agg_info.sortingIdxPTab, p_col.iSorterColumn, target)
				if usize(p_tab) == usize(0) {
				} else if p_col.iColumn < 0 {
					0
				} else {
					0
					if int(p_tab.aCol[p_col.iColumn].affinity) == 69 {
						sqlite3_vdbe_add_op1(v, 89, target)
					}
				}
				return target
			} else if usize(p_expr.y.pTab) == usize(0) {
				sqlite3_vdbe_add_op3(v, 96, p_expr.iTable, int(p_expr.iColumn), target)
				return target
			}

			unsafe { goto c2v_case_36_1
			 }
		}
		168 {
			c2v_case_36_1:
			i_tab := p_expr.iTable
			i_reg := 0
			if ((p_expr.flags & u32(32)) != u32(0)) {
				aff := 0
				i_reg = sqlite3_expr_code_target(p_parse, p_expr.pLeft, target)
				aff = int(sqlite3_table_column_affinity(p_expr.y.pTab, int(p_expr.iColumn)))
				if aff > 65 {
					if !sqlite3_expr_code_target_z_aff_inited {
						c2v_static_init := [i8(66), 0, 67, 0, 68, 0, 69, 0, 70, 0]
						for c2v_i_0, c2v_element_0 in c2v_static_init {
							sqlite3_expr_code_target_z_aff[c2v_i_0] = c2v_element_0
						}
						sqlite3_expr_code_target_z_aff_inited = true
					}

					sqlite3_vdbe_add_op4(v, 98, i_reg, 1, 0, unsafe { &sqlite3_expr_code_target_z_aff[0] + ((aff - int(`B`)) * 2) }, (-1))
				}
				return i_reg
			}
			if i_tab < 0 {
				if p_parse.iSelfTab < 0 {
					p_col := &Column(0)
					p_tab := &Table(0)
					i_src := 0
					i_col := int(p_expr.iColumn)
					p_tab = p_expr.y.pTab
					if i_col < 0 {
						return -1 - p_parse.iSelfTab
					}
					p_col = p_tab.aCol + i_col
					0
					i_src = int(sqlite3_table_column_to_storage(p_tab, I16(i_col))) - p_parse.iSelfTab
					if int(p_col.colFlags) & 96 {
						if int(p_col.colFlags) & 256 {
							sqlite3_error_msg(p_parse, c'generated column loop on "%s"', voidptr(p_col.zCnName))
							return 0
						}
						p_col.colFlags |= 256
						if int(p_col.colFlags) & 128 {
							sqlite3_expr_code_generated_column(p_parse, p_tab, p_col, i_src)
						}
						p_col.colFlags &= ~(256 | 128)
						return i_src
					} else if int(p_col.affinity) == 69 {
						sqlite3_vdbe_add_op2(v, 83, i_src, target)
						sqlite3_vdbe_add_op1(v, 89, target)
						return target
					} else {
						return i_src
					}
				} else {
					i_tab = p_parse.iSelfTab - 1
				}
			} else {
				if !isnil(p_parse.pIdxPartExpr) && 0 != c2v_assign[int](unsafe { &r1 }, int(expr_partidx_expr_lookup(p_parse, p_expr, target))) {
					return r1
				}
			}
			i_reg = sqlite3_expr_code_get_column(p_parse, p_expr.y.pTab, int(p_expr.iColumn), i_tab, target, p_expr.op2)
			return i_reg
		}
		156 {
			code_integer(p_parse, p_expr, 0, target)
			return target
		}
		171 {
			sqlite3_vdbe_add_op2(v, 73, sqlite3_expr_truth_value(p_expr), target)
			return target
		}
		154 {
			code_real(v, p_expr.u.zToken, 0, target)
			return target
		}
		118 {
			sqlite3_vdbe_load_string(v, target, p_expr.u.zToken)
			return target
		}
		83 {
			sqlite3_vdbe_add_op3(v, 77, 0, target, target + p_expr.y.nReg - 1)
			return target
		}
		155 {
			n := 0
			z := &i8(0)
			z_blob := &i8(0)
			z = unsafe { p_expr.u.zToken + 2 }
			n = sqlite3_strlen30(z) - 1
			z_blob = &i8(sqlite3_hex_to_blob(sqlite3_vdbe_db(v), z, n))
			sqlite3_vdbe_add_op4(v, 79, n / 2, target, 0, z_blob, (-7))
			return target
		}
		157 {
			sqlite3_vdbe_add_op2(v, 80, int(p_expr.iColumn), target)
			return target
		}
		176 {
			return p_expr.iTable
		}
		36 {
			sqlite3_expr_code(p_parse, p_expr.pLeft, target)
			sqlite3_vdbe_add_op2(v, 90, target, int(sqlite3_affinity_type(p_expr.u.zToken, unsafe { nil })))
			return in_reg
		}
		45, 46 {
			op = if (op == 45) { 54 } else { 53 }
			p5 = 128

			unsafe { goto c2v_case_36_15
			 }
		}
		57, 56, 55, 58, 53, 54 {
			c2v_case_36_15:
			p_left := p_expr.pLeft
			addr_is_null := 0
			if sqlite3_expr_is_vector(p_left) {
				code_vector_compare(p_parse, p_expr, target, U8(op), U8(p5))
			} else {
				if ((p_expr.flags & u32(4194304)) != u32(0)) && p5 != 128 {
					addr_is_null = expr_compute_operands(p_parse, p_expr, &r1, &r2, &reg_free1, &reg_free2)
				} else {
					r1 = sqlite3_expr_code_temp(p_parse, p_expr.pLeft, &reg_free1)
					r2 = sqlite3_expr_code_temp(p_parse, p_expr.pRight, &reg_free2)
				}
				sqlite3_vdbe_add_op2(v, 73, 1, in_reg)
				code_compare(p_parse, p_left, p_expr.pRight, op, r1, r2, sqlite3_vdbe_current_addr(v) + 2, p5, ((p_expr.flags & u32(1024)) != u32(0)))
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
				if p5 == 128 {
					sqlite3_vdbe_add_op2(v, 73, 0, in_reg)
				} else {
					sqlite3_vdbe_add_op3(v, 94, r1, in_reg, r2)
					if addr_is_null {
						sqlite3_vdbe_add_op2(v, 9, 0, sqlite3_vdbe_current_addr(v) + 2)
						sqlite3_vdbe_jump_here(v, addr_is_null)
						sqlite3_vdbe_add_op2(v, 77, 0, in_reg)
					}
				}
				0
				0
			}
		}
		44, 43 {
			in_reg = expr_code_target_and_or(p_parse, p_expr, target, &reg_free1)
		}
		107, 109, 108, 111, 103, 104, 110, 105, 106, 112 {
			addr_is_null_2 := 0
			0
			0
			0
			0
			0
			0
			0
			0
			0
			if ((p_expr.flags & u32(4194304)) != u32(0)) {
				addr_is_null_2 = expr_compute_operands(p_parse, p_expr, &r1, &r2, &reg_free1, &reg_free2)
			} else {
				r1 = sqlite3_expr_code_temp(p_parse, p_expr.pLeft, &reg_free1)
				r2 = sqlite3_expr_code_temp(p_parse, p_expr.pRight, &reg_free2)
				addr_is_null_2 = 0
			}
			sqlite3_vdbe_add_op3(v, op, r2, r1, target)
			0
			0
			if addr_is_null_2 {
				sqlite3_vdbe_add_op2(v, 9, 0, sqlite3_vdbe_current_addr(v) + 2)
				sqlite3_vdbe_jump_here(v, addr_is_null_2)
				sqlite3_vdbe_add_op2(v, 77, 0, target)
				0
			}
		}
		174 {
			p_left_2 := p_expr.pLeft
			if int(p_left_2.op) == 156 {
				code_integer(p_parse, p_left_2, 1, target)
				return target
			} else if int(p_left_2.op) == 154 {
				code_real(v, p_left_2.u.zToken, 1, target)
				return target
			} else {
				temp_x.op = U8(156)
				temp_x.flags = u32(2048 | 65536)
				temp_x.u.iValue = 0
				0
				r1 = sqlite3_expr_code_temp(p_parse, &temp_x, &reg_free1)
				r2 = sqlite3_expr_code_temp(p_parse, p_expr.pLeft, &reg_free2)
				sqlite3_vdbe_add_op3(v, 108, r2, r1, target)
				0
			}
		}
		115, 19 {
			0
			0
			r1 = sqlite3_expr_code_temp(p_parse, p_expr.pLeft, &reg_free1)
			0
			sqlite3_vdbe_add_op2(v, op, r1, in_reg)
		}
		175 {
			is_true := 0
			b_normal := 0
			r1 = sqlite3_expr_code_temp(p_parse, p_expr.pLeft, &reg_free1)
			0
			is_true = sqlite3_expr_truth_value(p_expr.pRight)
			b_normal = int(p_expr.op2) == 45
			0
			0
			sqlite3_vdbe_add_op4_int(v, 93, r1, in_reg, !is_true, is_true ^ b_normal)
		}
		51, 52 {
			addr := 0
			0
			0
			sqlite3_vdbe_add_op2(v, 73, 1, target)
			r1 = sqlite3_expr_code_temp(p_parse, p_expr.pLeft, &reg_free1)
			0
			addr = sqlite3_vdbe_add_op1(v, op, r1)
			0
			0
			sqlite3_vdbe_add_op2(v, 73, 0, target)
			sqlite3_vdbe_jump_here(v, addr)
		}
		169 {
			p_info := p_expr.pAggInfo
			if usize(p_info) == usize(0) || (int(p_expr.iAgg) < 0) || (int(p_expr.iAgg) >= p_info.nFunc) {
				sqlite3_error_msg(p_parse, c'misuse of aggregate: %#T()', voidptr(p_expr))
			} else {
				return p_info.iFirstReg + p_info.nColumn + int(p_expr.iAgg)
			}
		}
		172 {
			p_farg := &ExprList(0)
			n_farg := 0
			p_def := &FuncDef(0)
			z_id := &i8(0)
			const_mask := u32(0)
			i := 0
			db := p_parse.db
			enc := db.enc
			p_coll := unsafe { &CollSeq(nil) }
			if ((p_expr.flags & u32(16777216)) != u32(0)) {
				return p_expr.y.pWin.regResult
			}
			if int(p_parse.okConstFactor) && sqlite3_expr_is_constant_not_join(p_parse, p_expr) {
				return sqlite3_expr_code_run_just_once(p_parse, p_expr, -1)
			}
			p_farg = p_expr.x.pList
			n_farg = if p_farg { p_farg.nExpr } else { 0 }
			z_id = p_expr.u.zToken
			p_def = sqlite3_find_function(db, z_id, n_farg, enc, U8(0))
			if usize(p_def) == usize(0) || !isnil(p_def.xFinalize) {
				sqlite3_error_msg(p_parse, c'unknown function: %#T()', voidptr(p_expr))
				unsafe { goto c2v_switch_end_36
				 }
			}
			if (p_def.funcFlags & u32(4194304)) != u32(0) && (usize(p_farg) != usize(0)) {
				return expr_code_inline_function(p_parse, p_farg, (int(i64(p_def.pUserData))), target)
			} else if p_def.funcFlags & u32((524288 | 2097152)) {
				sqlite3_expr_function_usable(p_parse, p_expr, p_def)
			}
			for i = 0; i < n_farg; i++ {
				if i < 32 && sqlite3_expr_is_constant(p_parse, c2v_at(&p_farg.a[0], isize(i)).pExpr) {
					0
					const_mask |= ((u32(1)) << i)
				}
				if (p_def.funcFlags & u32(32)) != u32(0) && isnil(p_coll) {
					p_coll = sqlite3_expr_coll_seq(p_parse, c2v_at(&p_farg.a[0], isize(i)).pExpr)
				}
			}
			if p_farg {
				if const_mask {
					r1 = p_parse.nMem + 1
					p_parse.nMem += n_farg
				} else {
					r1 = sqlite3_get_temp_range(p_parse, n_farg)
				}
				if (p_def.funcFlags & u32((64 | 128))) != u32(0) {
					expr_op := U8(0)
					expr_op = c2v_at(&p_farg.a[0], isize(0)).pExpr.op
					if int(expr_op) == 168 || int(expr_op) == 170 {
						0
						0
						0
						mut __c2v_lhs_tmp_102 := c2v_at(&p_farg.a[0], isize(0))
						__c2v_lhs_tmp_102.pExpr.op2 = U8(p_def.funcFlags & u32(192))
					}
				}
				sqlite3_expr_code_expr_list(p_parse, p_farg, r1, 0, U8(2))
			} else {
				r1 = 0
			}
			if n_farg >= 2 && ((p_expr.flags & u32(256)) != u32(0)) {
				p_def = sqlite3_vtab_overload_function(db, p_def, n_farg, c2v_at(&p_farg.a[0], isize(1)).pExpr)
			} else if n_farg > 0 {
				p_def = sqlite3_vtab_overload_function(db, p_def, n_farg, c2v_at(&p_farg.a[0], isize(0)).pExpr)
			}
			if p_def.funcFlags & u32(32) {
				if isnil(p_coll) {
					p_coll = db.pDfltColl
				}
				sqlite3_vdbe_add_op4(v, 87, 0, 0, 0, &i8(voidptr(p_coll)), (-2))
			}
			sqlite3_vdbe_add_function_call(p_parse, int(const_mask), r1, target, n_farg, p_def, int(p_expr.op2))
			if n_farg {
				if const_mask == u32(0) {
					sqlite3_release_temp_range(p_parse, r1, n_farg)
				} else {
					0
				}
			}
			return target
		}
		20, 139 {
			n_col := 0
			0
			0
			if p_parse.db.mallocFailed {
				return 0
			} else {
				if op == 139 && ((p_expr.flags & u32(4096)) != u32(0)) && c2v_assign[int](unsafe { &n_col }, int(p_expr.x.pSelect.pEList.nExpr)) != 1 {
					sqlite3_subselect_error(p_parse, n_col, 1)
				} else {
					return sqlite3_code_subselect(p_parse, p_expr)
				}
			}
		}
		178 {
			n := 0
			p_left_2 := p_expr.pLeft
			if p_left_2.iTable == 0 || int(p_parse.withinRJSubrtn) > int(p_left_2.op2) {
				p_left_2.iTable = sqlite3_code_subselect(p_parse, p_left_2)
				p_left_2.op2 = p_parse.withinRJSubrtn
			}
			n = sqlite3_expr_vector_size(p_left_2)
			if p_expr.iTable != n {
				sqlite3_error_msg(p_parse, c'%d columns assigned %d values', p_expr.iTable, n)
			}
			return p_left_2.iTable + int(p_expr.iColumn)
		}
		50 {
			dest_if_false := sqlite3_vdbe_make_label(p_parse)
			dest_if_null := sqlite3_vdbe_make_label(p_parse)
			sqlite3_vdbe_add_op2(v, 77, 0, target)
			sqlite3_expr_code_in(p_parse, p_expr, dest_if_false, dest_if_null)
			sqlite3_vdbe_add_op2(v, 73, 1, target)
			sqlite3_vdbe_resolve_label(v, dest_if_false)
			sqlite3_vdbe_add_op2(v, 88, target, 0)
			sqlite3_vdbe_resolve_label(v, dest_if_null)
			return target
		}
		49 {
			expr_code_between(p_parse, p_expr, target, unsafe { nil }, 0)
			return target
		}
		114 {
			if !((p_expr.flags & u32(512)) != u32(0)) {
				sqlite3_expr_code(p_parse, p_expr.pLeft, target)
				sqlite3_vdbe_add_op1(v, 182, target)
				return target
			} else {
				p_expr = p_expr.pLeft
				unsafe { goto expr_code_doover
				 }
			}
		}
		181, 173 {
			p_expr = p_expr.pLeft
			unsafe { goto expr_code_doover
			 }
		}
		78 {
			p_tab := &Table(0)
			i_col := 0
			p1 := 0
			p_tab = p_expr.y.pTab
			i_col = int(p_expr.iColumn)
			p1 = p_expr.iTable * (int(p_tab.nCol) + 1) + 1 + int(sqlite3_table_column_to_storage(p_tab, I16(i_col)))
			sqlite3_vdbe_add_op2(v, 159, p1, target)
			0
			if i_col >= 0 && int(p_tab.aCol[i_col].affinity) == 69 {
				sqlite3_vdbe_add_op1(v, 89, target)
			}
		}
		177 {
			sqlite3_error_msg(p_parse, c'row value misused')
		}
		179 {
			addr_inr := 0
			ok_const_factor := U8(p_parse.okConstFactor)
			p_agg_info := p_expr.pAggInfo
			if p_agg_info {
				if !p_agg_info.directMode {
					in_reg = (p_agg_info.iFirstReg + int(p_expr.iAgg))
					unsafe { goto c2v_switch_end_36
					 }
				}
				if p_expr.pAggInfo.useSortingIdx {
					sqlite3_vdbe_add_op3(v, 96, p_agg_info.sortingIdxPTab, p_agg_info.aCol[p_expr.iAgg].iSorterColumn, target)
					in_reg = target
					unsafe { goto c2v_switch_end_36
					 }
				}
			}
			addr_inr = sqlite3_vdbe_add_op3(v, 20, p_expr.iTable, 0, target)
			p_parse.okConstFactor = Bft(0)
			sqlite3_expr_code(p_parse, p_expr.pLeft, target)
			p_parse.okConstFactor = Bft(ok_const_factor)
			sqlite3_vdbe_jump_here(v, addr_inr)
		}
		158 {
			end_label := 0
			next_case := 0
			n_expr := 0
			i := 0
			pel_ist := &ExprList(0)
			a_listelem := &ExprList_item(0)
			op_compare := Expr{}
			px := &Expr(0)
			p_test := unsafe { &Expr(nil) }
			p_del := unsafe { &Expr(nil) }
			db := p_parse.db
			pel_ist = p_expr.x.pList
			a_listelem = unsafe { &pel_ist.a[0] }
			n_expr = pel_ist.nExpr
			end_label = sqlite3_vdbe_make_label(p_parse)
			px = p_expr.pLeft
			if usize(px) != usize(0) {
				p_del = sqlite3_expr_dup(db, px, 0)
				if db.mallocFailed {
					sqlite3_expr_delete(db, p_del)
					unsafe { goto c2v_switch_end_36
					 }
				}
				0
				sqlite3_expr_to_register(p_del, expr_code_vector(p_parse, p_del, &reg_free1))
				0
				C.memset(voidptr(&op_compare), 0, sizeof(op_compare))
				op_compare.op = U8(54)
				op_compare.pLeft = p_del
				p_test = &op_compare
				reg_free1 = 0
			}
			for i = 0; i < n_expr - 1; i = i + 2 {
				if px {
					op_compare.pRight = a_listelem[i].pExpr
				} else {
					p_test = a_listelem[i].pExpr
				}
				next_case = sqlite3_vdbe_make_label(p_parse)
				0
				sqlite3_expr_if_false(p_parse, p_test, next_case, 16)
				0
				sqlite3_expr_code(p_parse, a_listelem[i + 1].pExpr, target)
				sqlite3_vdbe_goto(v, end_label)
				sqlite3_vdbe_resolve_label(v, next_case)
			}
			if (n_expr & 1) != 0 {
				sqlite3_expr_code(p_parse, c2v_at(&pel_ist.a[0], isize(n_expr - 1)).pExpr, target)
			} else {
				sqlite3_vdbe_add_op2(v, 77, 0, target)
			}
			sqlite3_expr_delete(db, p_del)
			set_do_not_merge_flag_on_copy(v)
			sqlite3_vdbe_resolve_label(v, end_label)
		}
		72 {
			if isnil(p_parse.pTriggerTab) && !p_parse.nested {
				sqlite3_error_msg(p_parse, c'RAISE() may only be used within a trigger-program')
				return 0
			}
			if int(p_expr.affExpr) == 2 {
				sqlite3_may_abort(p_parse)
			}
			if int(p_expr.affExpr) == 4 {
				sqlite3_vdbe_add_op2(v, 72, 0, 4)
				0
			} else {
				r1 = sqlite3_expr_code_temp(p_parse, p_expr.pLeft, &reg_free1)
				sqlite3_vdbe_add_op3(v, 72, if p_parse.pTriggerTab { (19 | (7 << 8)) } else { 1 }, int(p_expr.affExpr), r1)
			}
		}
		else {
			sqlite3_vdbe_add_op2(v, 77, 0, target)
			return target
		}
	}
	c2v_switch_end_36:

	sqlite3_release_temp_reg(p_parse, reg_free1)
	sqlite3_release_temp_reg(p_parse, reg_free2)
	return in_reg
}

@[c:'sqlite3ExprCodeRunJustOnce']
fn sqlite3_expr_code_run_just_once(p_parse &Parse, p_expr &Expr, reg_dest int) int {
	p := &ExprList(0)
	p = p_parse.pConstExpr
	if reg_dest < 0 && !isnil(p) {
		p_item := &ExprList_item(0)
		i := 0
		p_item = unsafe { &p.a[0] }
		for i = p.nExpr; i > 0; p_item = unsafe { p_item + 1 } {
			if int(p_item.fg.reusable) && sqlite3_expr_compare(unsafe { nil }, p_item.pExpr, p_expr, -1) == 0 {
				return p_item.u.iConstExprReg
			}
			i--
		}
	}
	p_expr = sqlite3_expr_dup(p_parse.db, p_expr, 0)
	if usize(p_expr) != usize(0) && ((p_expr.flags & u32(8)) != u32(0)) {
		v := p_parse.pVdbe
		addr := 0
		addr = sqlite3_vdbe_add_op0(v, 15)
		0
		p_parse.okConstFactor = Bft(0)
		if !p_parse.db.mallocFailed {
			if reg_dest < 0 {
				reg_dest = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			}
			sqlite3_expr_code(p_parse, p_expr, reg_dest)
		}
		p_parse.okConstFactor = Bft(1)
		sqlite3_expr_delete(p_parse.db, p_expr)
		sqlite3_vdbe_jump_here(v, addr)
	} else {
		p = sqlite3_expr_list_append(p_parse, p, p_expr)
		if p {
			p_item := unsafe { &p.a[0] + (p.nExpr - 1) }
			p_item.fg.reusable = u32(reg_dest < 0)
			if reg_dest < 0 {
				reg_dest = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			}
			p_item.u.iConstExprReg = reg_dest
		}
		p_parse.pConstExpr = p
	}
	return reg_dest
}

@[c:'sqlite3ExprNullRegisterRange']
fn sqlite3_expr_null_register_range(p_parse &Parse, i_reg int, n_reg int) {
	ok_const_factor := U8(p_parse.okConstFactor)
	t := Expr{}
	C.memset(voidptr(&t), 0, sizeof(t))
	t.op = U8(83)
	t.y.nReg = n_reg
	p_parse.okConstFactor = Bft(1)
	sqlite3_expr_code_run_just_once(p_parse, &t, i_reg)
	p_parse.okConstFactor = Bft(ok_const_factor)
}

@[c:'sqlite3ExprCodeTemp']
fn sqlite3_expr_code_temp(p_parse &Parse, p_expr &Expr, p_reg &int) int {
	r2 := 0
	p_expr = sqlite3_expr_skip_collate_and_likely(p_expr)
	if int(p_parse.okConstFactor) && (usize(p_expr) != usize(0)) && int(p_expr.op) != 176 && sqlite3_expr_is_constant_not_join(p_parse, p_expr) {
		unsafe { *p_reg = 0 }
		r2 = sqlite3_expr_code_run_just_once(p_parse, p_expr, -1)
	} else {
		r1 := sqlite3_get_temp_reg(p_parse)
		r2 = sqlite3_expr_code_target(p_parse, p_expr, r1)
		if r2 == r1 {
			unsafe { *p_reg = r1 }
		} else {
			sqlite3_release_temp_reg(p_parse, r1)
			unsafe { *p_reg = 0 }
		}
	}
	return r2
}

@[c:'sqlite3ExprCode']
fn sqlite3_expr_code(p_parse &Parse, p_expr &Expr, target int) {
	in_reg := 0
	if usize(p_parse.pVdbe) == usize(0) {
		return
	}
	in_reg = sqlite3_expr_code_target(p_parse, p_expr, target)
	if in_reg != target {
		op := U8(0)
		px := sqlite3_expr_skip_collate_and_likely(p_expr)
		0
		if !isnil(px) && (((px.flags & u32(4194304)) != u32(0)) || int(px.op) == 176) {
			op = U8(82)
		} else {
			op = U8(83)
		}
		sqlite3_vdbe_add_op2(p_parse.pVdbe, int(op), in_reg, target)
	}
}

@[c:'sqlite3ExprCodeCopy']
fn sqlite3_expr_code_copy(p_parse &Parse, p_expr &Expr, target int) {
	db := p_parse.db
	p_expr = sqlite3_expr_dup(db, p_expr, 0)
	if !db.mallocFailed {
		sqlite3_expr_code(p_parse, p_expr, target)
	}
	sqlite3_expr_delete(db, p_expr)
}

@[c:'sqlite3ExprCodeFactorable']
fn sqlite3_expr_code_factorable(p_parse &Parse, p_expr &Expr, target int) {
	if int(p_parse.okConstFactor) && sqlite3_expr_is_constant_not_join(p_parse, p_expr) {
		sqlite3_expr_code_run_just_once(p_parse, p_expr, target)
	} else {
		sqlite3_expr_code_copy(p_parse, p_expr, target)
	}
}

@[c:'sqlite3ExprCodeExprList']
fn sqlite3_expr_code_expr_list(p_parse &Parse, p_list &ExprList, target int, src_reg int, flags U8) int {
	p_item := &ExprList_item(0)
	i := 0
	j := 0
	n := 0

	copy_op := U8(if (int(flags) & 1) { 82 } else { 83 })
	v := p_parse.pVdbe
	n = p_list.nExpr
	if !p_parse.okConstFactor {
		flags &= ~2
	}
	p_item = unsafe { &p_list.a[0] }
	for i = 0; i < n; i++ {
		p_expr := p_item.pExpr
		if (int(flags) & 4) != 0 && c2v_assign[int](unsafe { &j }, int(p_item.u.x.iOrderByCol)) > 0 {
			if int(flags) & 8 {
				i--
				n--
			} else {
				sqlite3_vdbe_add_op2(v, int(copy_op), j + src_reg - 1, target + i)
			}
		} else if (int(flags) & 2) != 0 && sqlite3_expr_is_constant_not_join(p_parse, p_expr) {
			sqlite3_expr_code_run_just_once(p_parse, p_expr, target + i)
		} else {
			in_reg := sqlite3_expr_code_target(p_parse, p_expr, target + i)
			if in_reg != target + i {
				p_op := &VdbeOp(0)
				mut __c2v_condition_52 := false
				mut __c2v_condition_53 := false
				__c2v_condition_53 = int(copy_op) == 82
				if __c2v_condition_53 {
					__c2v_condition_53 = int(c2v_assign[&VdbeOp](unsafe { &p_op }, sqlite3_vdbe_get_last_op(v)).opcode) == 82
				}
				if __c2v_condition_53 {
					__c2v_condition_53 = p_op.p1 + p_op.p3 + 1 == in_reg
				}
				if __c2v_condition_53 {
					__c2v_condition_53 = p_op.p2 + p_op.p3 + 1 == target + i
				}
				if __c2v_condition_53 {
					__c2v_condition_53 = int(p_op.p5) == 0
				}
				__c2v_condition_52 = __c2v_condition_53
				if __c2v_condition_52 {
					p_op.p3++
				} else {
					sqlite3_vdbe_add_op2(v, int(copy_op), in_reg, target + i)
				}
			}
		}
		c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
	}
	return n
}

@[c:'exprCodeBetween']
fn expr_code_between(p_parse &Parse, p_expr &Expr, dest int, x_jump fn (&Parse, &Expr, int, int), jump_if_null int) {
	expr_and := Expr{}
	comp_left := Expr{}
	comp_right := Expr{}
	reg_free1 := 0
	p_del := unsafe { &Expr(nil) }
	db := p_parse.db
	C.memset(voidptr(&comp_left), 0, sizeof(Expr))
	C.memset(voidptr(&comp_right), 0, sizeof(Expr))
	C.memset(voidptr(&expr_and), 0, sizeof(Expr))
	p_del = sqlite3_expr_dup(db, p_expr.pLeft, 0)
	if int(db.mallocFailed) == 0 {
		expr_and.op = U8(44)
		expr_and.pLeft = &comp_left
		expr_and.pRight = &comp_right
		comp_left.op = U8(58)
		comp_left.pLeft = p_del
		comp_left.pRight = c2v_at(&p_expr.x.pList.a[0], isize(0)).pExpr
		comp_right.op = U8(56)
		comp_right.pLeft = p_del
		comp_right.pRight = c2v_at(&p_expr.x.pList.a[0], isize(1)).pExpr
		sqlite3_expr_to_register(p_del, expr_code_vector(p_parse, p_del, &reg_free1))
		if x_jump {
			x_jump(p_parse, &expr_and, dest, jump_if_null)
		} else {
			p_del.flags |= u32(1)
			sqlite3_expr_code_target(p_parse, &expr_and, dest)
		}
		sqlite3_release_temp_reg(p_parse, reg_free1)
	}
	sqlite3_expr_delete(db, p_del)
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

@[c:'sqlite3ExprIfTrue']
fn sqlite3_expr_if_true(p_parse &Parse, p_expr &Expr, dest int, jump_if_null int) {
	c2v_gc_register_thread()
	v := p_parse.pVdbe
	op := 0
	reg_free1 := 0
	reg_free2 := 0
	r1 := 0
	r2 := 0

	if (usize(v) == usize(0)) {
		return
	}
	if (usize(p_expr) == usize(0)) {
		return
	}
	op = int(p_expr.op)
	match op {
		44, 43 {
			p_alt := sqlite3_expr_simplified_and_or(p_expr)
			if usize(p_alt) != usize(p_expr) {
				sqlite3_expr_if_true(p_parse, p_alt, dest, jump_if_null)
			} else {
				p_first := &Expr(0)
				p_second := &Expr(0)

				if expr_eval_rhs_first(p_expr) {
					p_first = p_expr.pRight
					p_second = p_expr.pLeft
				} else {
					p_first = p_expr.pLeft
					p_second = p_expr.pRight
				}
				if op == 44 {
					d2 := sqlite3_vdbe_make_label(p_parse)
					0
					sqlite3_expr_if_false(p_parse, p_first, d2, jump_if_null ^ 16)
					sqlite3_expr_if_true(p_parse, p_second, dest, jump_if_null)
					sqlite3_vdbe_resolve_label(v, d2)
				} else {
					0
					sqlite3_expr_if_true(p_parse, p_first, dest, jump_if_null)
					sqlite3_expr_if_true(p_parse, p_second, dest, jump_if_null)
				}
			}
		}
		19 {
			0
			sqlite3_expr_if_false(p_parse, p_expr.pLeft, dest, jump_if_null)
		}
		175 {
			is_not := 0
			is_true := 0
			0
			is_not = int(p_expr.op2) == 46
			is_true = sqlite3_expr_truth_value(p_expr.pRight)
			0
			0
			if is_true ^ is_not {
				sqlite3_expr_if_true(p_parse, p_expr.pLeft, dest, if is_not { 16 } else { 0 })
			} else {
				sqlite3_expr_if_false(p_parse, p_expr.pLeft, dest, if is_not { 16 } else { 0 })
			}
		}
		45, 46 {
			0
			0
			op = if (op == 45) { 54 } else { 53 }
			jump_if_null = 128

			unsafe { goto c2v_case_37_8
			 }
		}
		57, 56, 55, 58, 53, 54 {
			c2v_case_37_8:
			addr_is_null := 0
			if sqlite3_expr_is_vector(p_expr.pLeft) {
				unsafe { goto default_expr
				 }
			}
			if ((p_expr.flags & u32(4194304)) != u32(0)) && jump_if_null != 128 {
				addr_is_null = expr_compute_operands(p_parse, p_expr, &r1, &r2, &reg_free1, &reg_free2)
			} else {
				r1 = sqlite3_expr_code_temp(p_parse, p_expr.pLeft, &reg_free1)
				r2 = sqlite3_expr_code_temp(p_parse, p_expr.pRight, &reg_free2)
				addr_is_null = 0
			}
			code_compare(p_parse, p_expr.pLeft, p_expr.pRight, op, r1, r2, dest, jump_if_null, ((p_expr.flags & u32(1024)) != u32(0)))
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
			0
			0
			0
			if addr_is_null {
				if jump_if_null {
					sqlite3_vdbe_change_p2(v, addr_is_null, dest)
				} else {
					sqlite3_vdbe_jump_here(v, addr_is_null)
				}
			}
		}
		51, 52 {
			0
			0
			r1 = sqlite3_expr_code_temp(p_parse, p_expr.pLeft, &reg_free1)
			if reg_free1 {
				sqlite3_vdbe_typeof_column(v, r1)
			}
			sqlite3_vdbe_add_op2(v, op, r1, dest)
			0
			0
		}
		49 {
			0
			expr_code_between(p_parse, p_expr, dest, sqlite3_expr_if_true, jump_if_null)
		}
		50 {
			dest_if_false := sqlite3_vdbe_make_label(p_parse)
			dest_if_null := if jump_if_null { dest } else { dest_if_false }
			sqlite3_expr_code_in(p_parse, p_expr, dest_if_false, dest_if_null)
			sqlite3_vdbe_goto(v, dest)
			sqlite3_vdbe_resolve_label(v, dest_if_false)
		}
		else {
			default_expr:
			if ((p_expr.flags & u32((1 | 268435456))) == u32(268435456)) {
				sqlite3_vdbe_goto(v, dest)
			} else if ((p_expr.flags & u32((1 | 536870912))) == u32(536870912)) {
			} else {
				r1 = sqlite3_expr_code_temp(p_parse, p_expr, &reg_free1)
				sqlite3_vdbe_add_op3(v, 16, r1, dest, jump_if_null != 0)
				0
				0
				0
			}
		}
	}

	sqlite3_release_temp_reg(p_parse, reg_free1)
	sqlite3_release_temp_reg(p_parse, reg_free2)
}

@[c:'sqlite3ExprIfFalse']
fn sqlite3_expr_if_false(p_parse &Parse, p_expr &Expr, dest int, jump_if_null int) {
	c2v_gc_register_thread()
	v := p_parse.pVdbe
	op := 0
	reg_free1 := 0
	reg_free2 := 0
	r1 := 0
	r2 := 0

	if (usize(v) == usize(0)) {
		return
	}
	if usize(p_expr) == usize(0) {
		return
	}
	op = ((int(p_expr.op) + (51 & 1)) ^ 1) - (51 & 1)
	match p_expr.op {
		44, 43 {
			p_alt := sqlite3_expr_simplified_and_or(p_expr)
			if usize(p_alt) != usize(p_expr) {
				sqlite3_expr_if_false(p_parse, p_alt, dest, jump_if_null)
			} else {
				p_first := &Expr(0)
				p_second := &Expr(0)

				if expr_eval_rhs_first(p_expr) {
					p_first = p_expr.pRight
					p_second = p_expr.pLeft
				} else {
					p_first = p_expr.pLeft
					p_second = p_expr.pRight
				}
				if int(p_expr.op) == 44 {
					0
					sqlite3_expr_if_false(p_parse, p_first, dest, jump_if_null)
					sqlite3_expr_if_false(p_parse, p_second, dest, jump_if_null)
				} else {
					d2 := sqlite3_vdbe_make_label(p_parse)
					0
					sqlite3_expr_if_true(p_parse, p_first, d2, jump_if_null ^ 16)
					sqlite3_expr_if_false(p_parse, p_second, dest, jump_if_null)
					sqlite3_vdbe_resolve_label(v, d2)
				}
			}
		}
		19 {
			0
			sqlite3_expr_if_true(p_parse, p_expr.pLeft, dest, jump_if_null)
		}
		175 {
			is_not := 0
			is_true := 0
			0
			is_not = int(p_expr.op2) == 46
			is_true = sqlite3_expr_truth_value(p_expr.pRight)
			0
			0
			if is_true ^ is_not {
				sqlite3_expr_if_false(p_parse, p_expr.pLeft, dest, if is_not { 0 } else { 16 })
			} else {
				sqlite3_expr_if_true(p_parse, p_expr.pLeft, dest, if is_not { 0 } else { 16 })
			}
		}
		45, 46 {
			0
			0
			op = if (int(p_expr.op) == 45) { 53 } else { 54 }
			jump_if_null = 128

			unsafe { goto c2v_case_38_8
			 }
		}
		57, 56, 55, 58, 53, 54 {
			c2v_case_38_8:
			addr_is_null := 0
			if sqlite3_expr_is_vector(p_expr.pLeft) {
				unsafe { goto default_expr
				 }
			}
			if ((p_expr.flags & u32(4194304)) != u32(0)) && jump_if_null != 128 {
				addr_is_null = expr_compute_operands(p_parse, p_expr, &r1, &r2, &reg_free1, &reg_free2)
			} else {
				r1 = sqlite3_expr_code_temp(p_parse, p_expr.pLeft, &reg_free1)
				r2 = sqlite3_expr_code_temp(p_parse, p_expr.pRight, &reg_free2)
				addr_is_null = 0
			}
			code_compare(p_parse, p_expr.pLeft, p_expr.pRight, op, r1, r2, dest, jump_if_null, ((p_expr.flags & u32(1024)) != u32(0)))
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
			0
			0
			0
			if addr_is_null {
				if jump_if_null {
					sqlite3_vdbe_change_p2(v, addr_is_null, dest)
				} else {
					sqlite3_vdbe_jump_here(v, addr_is_null)
				}
			}
		}
		51, 52 {
			r1 = sqlite3_expr_code_temp(p_parse, p_expr.pLeft, &reg_free1)
			if reg_free1 {
				sqlite3_vdbe_typeof_column(v, r1)
			}
			sqlite3_vdbe_add_op2(v, op, r1, dest)
			0
			0
			0
			0
		}
		49 {
			0
			expr_code_between(p_parse, p_expr, dest, sqlite3_expr_if_false, jump_if_null)
		}
		50 {
			if jump_if_null {
				sqlite3_expr_code_in(p_parse, p_expr, dest, dest)
			} else {
				dest_if_null := sqlite3_vdbe_make_label(p_parse)
				sqlite3_expr_code_in(p_parse, p_expr, dest, dest_if_null)
				sqlite3_vdbe_resolve_label(v, dest_if_null)
			}
		}
		else {
			default_expr:
			if ((p_expr.flags & u32((1 | 536870912))) == u32(536870912)) {
				sqlite3_vdbe_goto(v, dest)
			} else if ((p_expr.flags & u32((1 | 268435456))) == u32(268435456)) {
			} else {
				r1 = sqlite3_expr_code_temp(p_parse, p_expr, &reg_free1)
				sqlite3_vdbe_add_op3(v, 17, r1, dest, jump_if_null != 0)
				0
				0
				0
			}
		}
	}

	sqlite3_release_temp_reg(p_parse, reg_free1)
	sqlite3_release_temp_reg(p_parse, reg_free2)
}

@[c:'sqlite3ExprIfFalseDup']
fn sqlite3_expr_if_falsedup(p_parse &Parse, p_expr &Expr, dest int, jump_if_null int) {
	db := p_parse.db
	p_copy := sqlite3_expr_dup(db, p_expr, 0)
	if int(db.mallocFailed) == 0 {
		sqlite3_expr_if_false(p_parse, p_copy, dest, jump_if_null)
	}
	sqlite3_expr_delete(db, p_copy)
}

@[c:'exprCompareVariable']
fn expr_compare_variable(p_parse &Parse, p_var &Expr, p_expr &Expr) int {
	res := 2
	i_var := 0
	pl := &Sqlite3_value(0)
	pr := unsafe { &Sqlite3_value(nil) }

	if int(p_expr.op) == 157 && int(p_var.iColumn) == int(p_expr.iColumn) {
		return 0
	}
	if (p_parse.db.flags & U64(8388608)) != U64(0) {
		return 2
	}
	sqlite3_value_from_expr(p_parse.db, p_expr, U8(1), U8(65), &&Sqlite3_value(&&Sqlite3_value(c2v_address_of(&pr))))
	if pr {
		i_var = int(p_var.iColumn)
		sqlite3_vdbe_set_varmask(p_parse.pVdbe, i_var)
		pl = sqlite3_vdbe_get_bound_value(p_parse.pReprepare, i_var, U8(65))
		if pl {
			if sqlite3_value_type(pl) == 3 {
				sqlite3_value_text(pl)
			}
			res = if sqlite3_mem_compare(pl, pr, unsafe { nil }) { 2 } else { 0 }
		}
		sqlite3_value_free_vdup7(pr)
		sqlite3_value_free_vdup7(pl)
	}
	return res
}

@[c:'sqlite3ExprCompare']
fn sqlite3_expr_compare(p_parse &Parse, pa &Expr, pb &Expr, i_tab int) int {
	combined_flags := u32(0)
	if usize(pa) == usize(0) || usize(pb) == usize(0) {
		return if usize(pb) == usize(pa) { 0 } else { 2 }
	}
	if !isnil(p_parse) && int(pa.op) == 157 {
		return expr_compare_variable(p_parse, pa, pb)
	}
	combined_flags = pa.flags | pb.flags
	if combined_flags & u32(2048) {
		if (pa.flags & pb.flags & u32(2048)) != u32(0) && pa.u.iValue == pb.u.iValue {
			return 0
		}
		return 2
	}
	if int(pa.op) != int(pb.op) || int(pa.op) == 72 {
		if int(pa.op) == 114 && sqlite3_expr_compare(p_parse, pa.pLeft, pb, i_tab) < 2 {
			return 1
		}
		if int(pb.op) == 114 && sqlite3_expr_compare(p_parse, pa, pb.pLeft, i_tab) < 2 {
			return 1
		}
		if int(pa.op) == 170 && int(pb.op) == 168 && pb.iTable < 0 && pa.iTable == i_tab {
		} else {
			return 2
		}
	}
	if pa.u.zToken {
		if int(pa.op) == 172 || int(pa.op) == 169 {
			if sqlite3_str_ic_mp(pa.u.zToken, pb.u.zToken) != 0 {
				return 2
			}
			if ((pa.flags & u32(16777216)) != u32(0)) != ((pb.flags & u32(16777216)) != u32(0)) {
				return 2
			}
			if ((pa.flags & u32(16777216)) != u32(0)) {
				if sqlite3_window_compare(p_parse, pa.y.pWin, pb.y.pWin, 1) != 0 {
					return 2
				}
			}
		} else if int(pa.op) == 122 {
			return 0
		} else if int(pa.op) == 114 {
			if sqlite3_stricmp(pa.u.zToken, pb.u.zToken) != 0 {
				return 2
			}
		} else if usize(pb.u.zToken) != usize(0) && int(pa.op) != 168 && int(pa.op) != 170 && C.strcmp(pa.u.zToken, pb.u.zToken) != 0 {
			return 2
		}
	}
	if (pa.flags & u32((4 | 1024))) != (pb.flags & u32((4 | 1024))) {
		return 2
	}
	if ((combined_flags & u32(65536)) == u32(0)) {
		if combined_flags & u32(4096) {
			return 2
		}
		if (combined_flags & u32(32)) == u32(0) && sqlite3_expr_compare(p_parse, pa.pLeft, pb.pLeft, i_tab) {
			return 2
		}
		if sqlite3_expr_compare(p_parse, pa.pRight, pb.pRight, i_tab) {
			return 2
		}
		if sqlite3_expr_list_compare(pa.x.pList, pb.x.pList, i_tab) {
			return 2
		}
		if int(pa.op) != 118 && int(pa.op) != 171 && ((combined_flags & u32(16384)) == u32(0)) {
			if int(pa.iColumn) != int(pb.iColumn) {
				return 2
			}
			if int(pa.op2) != int(pb.op2) && int(pa.op) == 175 {
				return 2
			}
			if int(pa.op) != 50 && pa.iTable != pb.iTable && pa.iTable != i_tab {
				return 2
			}
		}
	}
	return 0
}

@[c:'sqlite3ExprListCompare']
fn sqlite3_expr_list_compare(pa &ExprList, pb &ExprList, i_tab int) int {
	i := 0
	if usize(pa) == usize(0) && usize(pb) == usize(0) {
		return 0
	}
	if usize(pa) == usize(0) || usize(pb) == usize(0) {
		return 1
	}
	if pa.nExpr != pb.nExpr {
		return 1
	}
	for i = 0; i < pa.nExpr; i++ {
		res := 0
		p_expr_a := c2v_at(&pa.a[0], isize(i)).pExpr
		p_expr_b := c2v_at(&pb.a[0], isize(i)).pExpr
		if int(c2v_at(&pa.a[0], isize(i)).fg.sortFlags) != int(c2v_at(&pb.a[0], isize(i)).fg.sortFlags) {
			return 1
		}
		res = sqlite3_expr_compare(unsafe { nil }, p_expr_a, p_expr_b, i_tab)
		if res {
			return res
		}
	}
	return 0
}

@[c:'sqlite3ExprCompareSkip']
fn sqlite3_expr_compare_skip(pa &Expr, pb &Expr, i_tab int) int {
	return sqlite3_expr_compare(unsafe { nil }, sqlite3_expr_skip_collate(pa), sqlite3_expr_skip_collate(pb), i_tab)
}

@[c:'exprImpliesNotNull']
fn expr_implies_not_null(p_parse &Parse, p &Expr, pnn &Expr, i_tab int, seen_not int) int {
	if sqlite3_expr_compare(p_parse, p, pnn, i_tab) == 0 {
		return int(pnn.op != 122)
	}
	match p.op {
		50 {
			if seen_not && ((p.flags & u32(4096)) != u32(0)) {
				return 0
			}
			return expr_implies_not_null(p_parse, p.pLeft, pnn, i_tab, 1)
		}
		49 {
			p_list := &ExprList(0)
			p_list = p.x.pList
			if seen_not {
				return 0
			}
			if expr_implies_not_null(p_parse, c2v_at(&p_list.a[0], isize(0)).pExpr, pnn, i_tab, 1) || expr_implies_not_null(p_parse, c2v_at(&p_list.a[0], isize(1)).pExpr, pnn, i_tab, 1) {
				return 1
			}
			return expr_implies_not_null(p_parse, p.pLeft, pnn, i_tab, 1)
		}
		54, 53, 57, 56, 55, 58, 107, 108, 104, 105, 106, 112 {
			seen_not = 1

			unsafe { goto c2v_case_39_4
			 }
		}
		109, 111, 103, 110 {
			c2v_case_39_4:
			if expr_implies_not_null(p_parse, p.pRight, pnn, i_tab, seen_not) {
				return 1
			}

			unsafe { goto c2v_case_39_5
			 }
		}
		181, 114, 173, 174 {
			c2v_case_39_5:
			return expr_implies_not_null(p_parse, p.pLeft, pnn, i_tab, seen_not)
		}
		175 {
			if seen_not {
				return 0
			}
			if int(p.op2) != 45 {
				return 0
			}
			return expr_implies_not_null(p_parse, p.pLeft, pnn, i_tab, 1)
		}
		115, 19 {
			return expr_implies_not_null(p_parse, p.pLeft, pnn, i_tab, 1)
		}
		else {}
	}

	return 0
}

@[c:'sqlite3ExprIsNotTrue']
fn sqlite3_expr_is_not_true(p_expr &Expr) int {
	v := 0
	if int(p_expr.op) == 122 {
		return 1
	}
	if int(p_expr.op) == 171 && sqlite3_expr_truth_value(p_expr) == 0 {
		return 1
	}
	v = 1
	if sqlite3_expr_is_integer(p_expr, &v, unsafe { nil }) && v == 0 {
		return 1
	}
	return 0
}

@[c:'sqlite3ExprIsIIF']
fn sqlite3_expr_is_iif(db &Sqlite3, p_expr &Expr) int {
	p_list := &ExprList(0)
	if int(p_expr.op) == 172 {
		z := p_expr.u.zToken
		p_def := &FuncDef(0)
		if (int(z[0]) != i8(`i`) && int(z[0]) != i8(`I`)) {
			return 0
		}
		if usize(p_expr.x.pList) == usize(0) {
			return 0
		}
		p_def = sqlite3_find_function(db, z, p_expr.x.pList.nExpr, db.enc, U8(0))
		if (usize(p_def) == usize(0)) {
			return 0
		}
		if (p_def.funcFlags & u32(4194304)) == u32(0) {
			return 0
		}
		if (int(i64(p_def.pUserData))) != 5 {
			return 0
		}
	} else if int(p_expr.op) == 158 {
		if usize(p_expr.pLeft) != usize(0) {
			return 0
		}
	} else {
		return 0
	}
	p_list = p_expr.x.pList
	if p_list.nExpr == 2 {
		return 1
	}
	if p_list.nExpr == 3 && sqlite3_expr_is_not_true(c2v_at(&p_list.a[0], isize(2)).pExpr) {
		return 1
	}
	return 0
}

@[c:'sqlite3ExprImpliesExpr']
fn sqlite3_expr_implies_expr(p_parse &Parse, p_e1 &Expr, p_e2 &Expr, i_tab int) int {
	if sqlite3_expr_compare(p_parse, p_e1, p_e2, i_tab) == 0 {
		return 1
	}
	if int(p_e2.op) == 43 && (sqlite3_expr_implies_expr(p_parse, p_e1, p_e2.pLeft, i_tab) || sqlite3_expr_implies_expr(p_parse, p_e1, p_e2.pRight, i_tab)) {
		return 1
	}
	if int(p_e2.op) == 52 && expr_implies_not_null(p_parse, p_e1, p_e2.pLeft, i_tab, 0) {
		return 1
	}
	if sqlite3_expr_is_iif(p_parse.db, p_e1) {
		return sqlite3_expr_implies_expr(p_parse, c2v_at(&p_e1.x.pList.a[0], isize(0)).pExpr, p_e2, i_tab)
	}
	return 0
}

@[c:'bothImplyNotNullRow']
fn both_imply_not_null_row(p_walker &Walker, p_e1 &Expr, p_e2 &Expr) {
	if int(p_walker.eCode) == 0 {
		sqlite3_walk_expr(p_walker, p_e1)
		if p_walker.eCode {
			p_walker.eCode = U16(0)
			sqlite3_walk_expr(p_walker, p_e2)
		}
	}
}

@[c:'impliesNotNullRow']
fn implies_not_null_row(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	0
	0
	if ((p_expr.flags & u32(1)) != u32(0)) {
		return 1
	}
	if ((p_expr.flags & u32(2)) != u32(0)) && int(p_walker.mWFlags) {
		return 1
	}
	match p_expr.op {
		46, 51, 52, 45, 177, 172, 175, 158 {
			0
			0
			0
			0
			0
			0
			0
			0
			return 1
		}
		168 {
			if p_walker.u.iCur == p_expr.iTable {
				p_walker.eCode = U16(1)
				return 2
			}
			return 1
		}
		43, 44 {
			0
			0
			both_imply_not_null_row(p_walker, p_expr.pLeft, p_expr.pRight)
			return 1
		}
		50 {
			if ((p_expr.flags & u32(4096)) == u32(0)) && (p_expr.x.pList.nExpr > 0) {
				sqlite3_walk_expr(p_walker, p_expr.pLeft)
			}
			return 1
		}
		49 {
			sqlite3_walk_expr(p_walker, p_expr.pLeft)
			both_imply_not_null_row(p_walker, c2v_at(&p_expr.x.pList.a[0], isize(0)).pExpr, c2v_at(&p_expr.x.pList.a[0], isize(1)).pExpr)
			return 1
		}
		54, 53, 57, 56, 55, 58 {
			p_left := p_expr.pLeft
			p_right := p_expr.pRight
			0
			0
			0
			0
			0
			0
			mut __c2v_condition_54 := false
			mut __c2v_condition_55 := false
			__c2v_condition_55 = (int(p_left.op) == 168 && (usize(p_left.y.pTab) != usize(0)) && (int(p_left.y.pTab.eTabType) == 1))
			__c2v_condition_54 = __c2v_condition_55
			if !__c2v_condition_54 {
				mut __c2v_condition_56 := false
				__c2v_condition_56 = (int(p_right.op) == 168 && (usize(p_right.y.pTab) != usize(0)) && (int(p_right.y.pTab.eTabType) == 1))
				__c2v_condition_54 = __c2v_condition_56
			}
			if __c2v_condition_54 {
				return 1
			}

			unsafe { goto c2v_case_40_23
			 }
		}
		else {
			c2v_case_40_23:
			return 0
		}
	}
	return 0
}

@[c:'sqlite3ExprImpliesNonNullRow']
fn sqlite3_expr_implies_non_null_row(p &Expr, i_tab int, is_rj int) int {
	w := Walker{}
	p = sqlite3_expr_skip_collate_and_likely(p)
	if usize(p) == usize(0) {
		return 0
	}
	if int(p.op) == 52 {
		p = p.pLeft
	} else {
		for int(p.op) == 44 {
			if sqlite3_expr_implies_non_null_row(p.pLeft, i_tab, is_rj) {
				return 1
			}
			p = p.pRight
		}
	}
	w.xExprCallback = implies_not_null_row
	w.xSelectCallback = 0
	w.xSelectCallback2 = 0
	w.eCode = U16(0)
	w.mWFlags = U16(is_rj != 0)
	w.u.iCur = i_tab
	sqlite3_walk_expr(&w, p)
	return int(w.eCode)
}

struct IdxCover {
	pIdx &Index
	iCur int
}

@[c:'exprIdxCover']
fn expr_idx_cover(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	if int(p_expr.op) == 168 && p_expr.iTable == p_walker.u.pIdxCover.iCur && sqlite3_table_column_to_index(p_walker.u.pIdxCover.pIdx, int(p_expr.iColumn)) < 0 {
		p_walker.eCode = U16(1)
		return 2
	}
	return 0
}

@[c:'sqlite3ExprCoveredByIndex']
fn sqlite3_expr_covered_by_index(p_expr &Expr, i_cur int, p_idx &Index) int {
	w := Walker{}
	xcov := IdxCover{}
	C.memset(voidptr(&w), 0, sizeof(w))
	xcov.iCur = i_cur
	xcov.pIdx = p_idx
	w.xExprCallback = expr_idx_cover
	w.u.pIdxCover = &xcov
	sqlite3_walk_expr(&w, p_expr)
	return int(!w.eCode)
}

struct RefSrcList {
	db        &Sqlite3
	pRef      &SrcList
	nExclude  I64
	aiExclude &int
}

@[c:'selectRefEnter']
fn select_ref_enter(p_walker &Walker, p_select &Select) int {
	c2v_gc_register_thread()
	p := p_walker.u.pRefSrcList
	p_src := p_select.pSrc
	i := I64(0)
	j := I64(0)

	pi_new := &int(0)
	if p_src.nSrc == 0 {
		return 0
	}
	j = p.nExclude
	p.nExclude += I64(p_src.nSrc)
	pi_new = sqlite3_db_realloc(p.db, voidptr(p.aiExclude), u64(p.nExclude) * sizeof(int))
	if usize(pi_new) == usize(0) {
		p.nExclude = I64(0)
		return 2
	} else {
		p.aiExclude = pi_new
	}
	for i = I64(0); i < I64(p_src.nSrc); i++ {
		p.aiExclude[j] = c2v_at(&p_src.a[0], isize(i)).iCursor
		j++
	}
	return 0
}

@[c:'selectRefLeave']
fn select_ref_leave(p_walker &Walker, p_select &Select) {
	c2v_gc_register_thread()
	p := p_walker.u.pRefSrcList
	p_src := p_select.pSrc
	if p.nExclude {
		p.nExclude -= I64(p_src.nSrc)
	}
}

@[c:'exprRefToSrcList']
fn expr_ref_to_src_list(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	if int(p_expr.op) == 168 || int(p_expr.op) == 170 {
		i := 0
		p := p_walker.u.pRefSrcList
		p_src := p.pRef
		n_src := if p_src { p_src.nSrc } else { 0 }
		for i = 0; i < n_src; i++ {
			if p_expr.iTable == c2v_at(&p_src.a[0], isize(i)).iCursor {
				p_walker.eCode |= 1
				return 0
			}
		}
		for i = 0; I64(i) < p.nExclude && p.aiExclude[i] != p_expr.iTable; i++ {
		}
		if I64(i) >= p.nExclude {
			p_walker.eCode |= 2
		}
	}
	return 0
}

@[c:'sqlite3ReferencesSrcList']
fn sqlite3_references_src_list(p_parse &Parse, p_expr &Expr, p_src_list &SrcList) int {
	w := Walker{}
	x := RefSrcList{}
	C.memset(voidptr(&w), 0, sizeof(w))
	C.memset(voidptr(&x), 0, sizeof(x))
	w.xExprCallback = expr_ref_to_src_list
	w.xSelectCallback = select_ref_enter
	w.xSelectCallback2 = select_ref_leave
	w.u.pRefSrcList = &x
	x.db = p_parse.db
	x.pRef = p_src_list
	sqlite3_walk_expr_list(&w, p_expr.x.pList)
	if p_expr.pLeft {
		sqlite3_walk_expr_list(&w, p_expr.pLeft.x.pList)
	}
	if ((p_expr.flags & u32(16777216)) != u32(0)) {
		sqlite3_walk_expr(&w, p_expr.y.pWin.pFilter)
	}
	if x.aiExclude {
		sqlite3_db_nn_free_nn(p_parse.db, voidptr(x.aiExclude))
	}
	if int(w.eCode) & 1 {
		return 1
	} else if w.eCode {
		return 0
	} else {
		return -1
	}
}

@[c:'agginfoPersistExprCb']
fn agginfo_persist_expr_cb(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	if (!((p_expr.flags & u32((65536 | 16384))) != u32(0))) && usize(p_expr.pAggInfo) != usize(0) {
		p_agg_info := p_expr.pAggInfo
		i_agg := int(p_expr.iAgg)
		p_parse := p_walker.pParse
		db := p_parse.db
		if int(p_expr.op) != 169 {
			if i_agg < p_agg_info.nColumn && usize(p_agg_info.aCol[i_agg].pCExpr) == usize(p_expr) {
				p_expr = sqlite3_expr_dup(db, p_expr, 0)
				if !isnil(p_expr) && !sqlite3_expr_deferred_delete(p_parse, p_expr) {
					p_agg_info.aCol[i_agg].pCExpr = p_expr
				}
			}
		} else {
			if (i_agg < p_agg_info.nFunc) && usize(p_agg_info.aFunc[i_agg].pFExpr) == usize(p_expr) {
				p_expr = sqlite3_expr_dup(db, p_expr, 0)
				if !isnil(p_expr) && !sqlite3_expr_deferred_delete(p_parse, p_expr) {
					p_agg_info.aFunc[i_agg].pFExpr = p_expr
				}
			}
		}
	}
	return 0
}

@[c:'sqlite3AggInfoPersistWalkerInit']
fn sqlite3_agg_info_persist_walker_init(p_walker &Walker, p_parse &Parse) {
	C.memset(voidptr(p_walker), 0, sizeof(Walker))
	p_walker.pParse = p_parse
	p_walker.xExprCallback = agginfo_persist_expr_cb
	p_walker.xSelectCallback = sqlite3_select_walk_noop
}

@[c:'addAggInfoColumn']
fn add_agg_info_column(db &Sqlite3, p_info &AggInfo) int {
	i := 0
	p_info.aCol = sqlite3_array_allocate(db, voidptr(p_info.aCol), int(sizeof(AggInfo_col)), &p_info.nColumn, &i)
	return i
}

@[c:'addAggInfoFunc']
fn add_agg_info_func(db &Sqlite3, p_info &AggInfo) int {
	i := 0
	p_info.aFunc = sqlite3_array_allocate(db, voidptr(p_info.aFunc), int(sizeof(AggInfo_func)), &p_info.nFunc, &i)
	return i
}

@[c:'findOrCreateAggInfoColumn']
fn find_or_create_agg_info_column(p_parse &Parse, p_agg_info &AggInfo, p_expr &Expr) {
	p_col := &AggInfo_col(0)
	k := 0
	mx_term := p_parse.db.aLimit[2]
	p_col = p_agg_info.aCol
	for k = 0; k < p_agg_info.nColumn; k++ {
		if usize(p_col.pCExpr) == usize(p_expr) {
			return
		}
		if p_col.iTable == p_expr.iTable && p_col.iColumn == int(p_expr.iColumn) && int(p_expr.op) != 179 {
			unsafe { goto fix_up_expr
			 }
		}
		c2v_pointer_postfix(voidptr(&p_col), p_col, isize(1))
	}
	k = add_agg_info_column(p_parse.db, p_agg_info)
	if k < 0 {
		return
	}
	if k > mx_term {
		sqlite3_error_msg(p_parse, c'more than %d aggregate terms', mx_term)
		k = mx_term
	}
	p_col = unsafe { p_agg_info.aCol + k }
	p_col.pTab = p_expr.y.pTab
	p_col.iTable = p_expr.iTable
	p_col.iColumn = int(p_expr.iColumn)
	p_col.iSorterColumn = -1
	p_col.pCExpr = p_expr
	if !isnil(p_agg_info.pGroupBy) && int(p_expr.op) != 179 {
		j := 0
		n := 0

		pgb := p_agg_info.pGroupBy
		p_term := unsafe { &ExprList_item(&pgb.a[0]) }
		n = pgb.nExpr
		for j = 0; j < n; j++ {
			pe := p_term.pExpr
			if int(pe.op) == 168 && pe.iTable == p_expr.iTable && int(pe.iColumn) == int(p_expr.iColumn) {
				p_col.iSorterColumn = j
				break
			}
			c2v_pointer_postfix(voidptr(&p_term), p_term, isize(1))
		}
	}
	if p_col.iSorterColumn < 0 {
		mut __c2v_postfix_value_5 := p_agg_info.nSortingColumn
		p_agg_info.nSortingColumn++
		p_col.iSorterColumn = __c2v_postfix_value_5
	}
	fix_up_expr:
	0
	p_expr.pAggInfo = p_agg_info
	if int(p_expr.op) == 168 {
		p_expr.op = U8(170)
	}
	p_expr.iAgg = I16(k)
}

@[c:'analyzeAggregate']
fn analyze_aggregate(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	i := 0
	pnc := p_walker.u.pNC
	p_parse := pnc.pParse
	p_src_list := pnc.pSrcList
	p_agg_info := pnc.uNC.pAggInfo
	match p_expr.op {
		179, 170, 168 {
			0
			0
			0
			if (usize(p_src_list) != usize(0)) {
				p_item := unsafe { &SrcItem(&p_src_list.a[0]) }
				for i = 0; i < p_src_list.nSrc; i++ {
					if p_expr.iTable == p_item.iCursor {
						find_or_create_agg_info_column(p_parse, p_agg_info, p_expr)
						break
					}
					c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
				}
			}
			return 0
		}
		169 {
			if (pnc.ncFlags & 131072) == 0 && p_walker.walkerDepth == int(p_expr.op2) && usize(p_expr.pAggInfo) == usize(0) {
				p_item := p_agg_info.aFunc
				mx_term := p_parse.db.aLimit[2]
				for i = 0; i < p_agg_info.nFunc; i++ {
					if (usize(p_item.pFExpr) == usize(p_expr)) {
						break
					}
					if sqlite3_expr_compare(unsafe { nil }, p_item.pFExpr, p_expr, -1) == 0 {
						break
					}
					c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
				}
				if i > mx_term {
					sqlite3_error_msg(p_parse, c'more than %d aggregate terms', mx_term)
					i = mx_term
				} else if i >= p_agg_info.nFunc {
					enc := p_parse.db.enc
					i = add_agg_info_func(p_parse.db, p_agg_info)
					if i >= 0 {
						n_arg := 0
						p_item = unsafe { p_agg_info.aFunc + i }
						p_item.pFExpr = p_expr
						n_arg = if p_expr.x.pList { p_expr.x.pList.nExpr } else { 0 }
						p_item.pFunc = sqlite3_find_function(p_parse.db, p_expr.u.zToken, n_arg, enc, U8(0))
						if !isnil(p_expr.pLeft) && (p_item.pFunc.funcFlags & u32(32)) == u32(0) {
							pob_list := &ExprList(0)
							mut __c2v_postfix_value_6 := p_parse.nTab
							p_parse.nTab++
							p_item.iOBTab = __c2v_postfix_value_6
							pob_list = p_expr.pLeft.x.pList
							if pob_list.nExpr == 1 && n_arg == 1 && sqlite3_expr_compare(unsafe { nil }, c2v_at(&pob_list.a[0], isize(0)).pExpr, c2v_at(&p_expr.x.pList.a[0], isize(0)).pExpr, 0) == 0 {
								p_item.bOBPayload = U8(0)
								p_item.bOBUnique = U8(((p_expr.flags & u32(4)) != u32(0)))
							} else {
								p_item.bOBPayload = U8(1)
							}
							p_item.bUseSubtype = U8((p_item.pFunc.funcFlags & u32(1048576)) != u32(0))
						} else {
							p_item.iOBTab = -1
						}
						if ((p_expr.flags & u32(4)) != u32(0)) && !p_item.bOBUnique {
							mut __c2v_postfix_value_7 := p_parse.nTab
							p_parse.nTab++
							p_item.iDistinct = __c2v_postfix_value_7
						} else {
							p_item.iDistinct = -1
						}
					}
				}
				0
				p_expr.iAgg = I16(i)
				p_expr.pAggInfo = p_agg_info
				return 1
			} else {
				return 0
			}
		}
		else {
			pie_pr := &IndexedExpr(0)
			tmp := Expr{}
			if (pnc.ncFlags & 131072) == 0 {
				unsafe { goto c2v_switch_end_41
				 }
			}
			if usize(p_parse.pIdxEpr) == usize(0) {
				unsafe { goto c2v_switch_end_41
				 }
			}
			for pie_pr = p_parse.pIdxEpr; pie_pr; pie_pr = pie_pr.pIENext {
				i_data_cur := pie_pr.iDataCur
				if i_data_cur < 0 {
					continue
				}
				if sqlite3_expr_compare(unsafe { nil }, p_expr, pie_pr.pExpr, i_data_cur) == 0 {
					break
				}
			}
			if usize(pie_pr) == usize(0) {
				unsafe { goto c2v_switch_end_41
				 }
			}
			if (!((p_expr.flags & u32((16777216 | 33554432))) == u32(0))) {
				unsafe { goto c2v_switch_end_41
				 }
			}
			for i = 0; i < p_src_list.nSrc; i++ {
				if c2v_at(&p_src_list.a[0], isize(i)).iCursor == pie_pr.iDataCur {
					0
					break
				}
			}
			if i >= p_src_list.nSrc {
				unsafe { goto c2v_switch_end_41
				 }
			}
			if (usize(p_expr.pAggInfo) != usize(0)) {
				unsafe { goto c2v_switch_end_41
				 }
			}
			if p_parse.nErr {
				return 2
			}
			C.memset(voidptr(&tmp), 0, sizeof(tmp))
			tmp.op = U8(170)
			tmp.iTable = pie_pr.iIdxCur
			tmp.iColumn = YnVar(pie_pr.iIdxCol)
			find_or_create_agg_info_column(p_parse, p_agg_info, &tmp)
			if p_parse.nErr {
				return 2
			}
			p_agg_info.aCol[tmp.iAgg].pCExpr = p_expr
			p_expr.pAggInfo = p_agg_info
			p_expr.iAgg = tmp.iAgg
			return 1
		}
	}
	c2v_switch_end_41:

	return 0
}

@[c:'sqlite3ExprAnalyzeAggregates']
fn sqlite3_expr_analyze_aggregates(pnc &NameContext, p_expr &Expr) {
	w := Walker{}
	w.xExprCallback = analyze_aggregate
	w.xSelectCallback = sqlite3_walker_depth_increase
	w.xSelectCallback2 = sqlite3_walker_depth_decrease
	w.walkerDepth = 0
	w.u.pNC = pnc
	w.pParse = 0
	sqlite3_walk_expr(&w, p_expr)
}

@[c:'sqlite3ExprAnalyzeAggList']
fn sqlite3_expr_analyze_agg_list(pnc &NameContext, p_list &ExprList) {
	p_item := &ExprList_item(0)
	i := 0
	if p_list {
		p_item = unsafe { &p_list.a[0] }
		for i = 0; i < p_list.nExpr; i++ {
			sqlite3_expr_analyze_aggregates(pnc, p_item.pExpr)
			c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
		}
	}
}

@[c:'sqlite3GetTempReg']
fn sqlite3_get_temp_reg(p_parse &Parse) int {
	if int(p_parse.nTempReg) == 0 {
		return c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	}
	return p_parse.aTempReg[c2v_prefix_add(unsafe { &p_parse.nTempReg }, u8(-1))]
}

@[c:'sqlite3ReleaseTempReg']
fn sqlite3_release_temp_reg(p_parse &Parse, i_reg int) {
	if i_reg {
		0
		if int(p_parse.nTempReg) < 8 {
			p_parse.aTempReg[p_parse.nTempReg++] = i_reg
		}
	}
}

@[c:'sqlite3GetTempRange']
fn sqlite3_get_temp_range(p_parse &Parse, n_reg int) int {
	i := 0
	n := 0

	if n_reg == 1 {
		return sqlite3_get_temp_reg(p_parse)
	}
	i = p_parse.iRangeReg
	n = p_parse.nRangeReg
	if n_reg <= n {
		p_parse.iRangeReg += n_reg
		p_parse.nRangeReg -= n_reg
	} else {
		i = p_parse.nMem + 1
		p_parse.nMem += n_reg
	}
	return i
}

@[c:'sqlite3ReleaseTempRange']
fn sqlite3_release_temp_range(p_parse &Parse, i_reg int, n_reg int) {
	if n_reg == 1 {
		sqlite3_release_temp_reg(p_parse, i_reg)
		return
	}
	0
	if n_reg > p_parse.nRangeReg {
		p_parse.nRangeReg = n_reg
		p_parse.iRangeReg = i_reg
	}
}

@[c:'sqlite3ClearTempRegCache']
fn sqlite3_clear_temp_reg_cache(p_parse &Parse) {
	p_parse.nTempReg = U8(0)
	p_parse.nRangeReg = 0
}

@[c:'sqlite3TouchRegister']
fn sqlite3_touch_register(p_parse &Parse, i_reg int) {
	if p_parse.nMem < i_reg {
		p_parse.nMem = i_reg
	}
}
