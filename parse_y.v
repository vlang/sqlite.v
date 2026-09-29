@[translated]
module main

struct TrigEvent {
	a int
	b &IdList
}

struct FrameBound {
	eType int
	pExpr &Expr
}

@[c:'parserSyntaxError']
fn parser_syntax_error(p_parse &Parse, p &Token) {
	sqlite3_error_msg(p_parse, c'near "%T": syntax error', voidptr(p))
}

@[c:'disableLookaside']
fn disable_lookaside(p_parse &Parse) {
	db := p_parse.db
	p_parse.disableLookaside++
	C.memset(voidptr(&p_parse.u1.cr), 0, sizeof(Parse_u1_cr))
	db.lookaside.bDisable++
	db.lookaside.sz = U16(0)
}

@[c:'parserDoubleLinkSelect']
fn parser_double_link_select(p_parse &Parse, p &Select) {
	if p.pPrior {
		p_next := unsafe { &Select(nil) }
		p_loop := p

		mx_select := 0
		cnt := 1

		for {
			p_loop.pNext = p_next
			p_loop.selFlags |= u32(256)
			p_next = p_loop
			p_loop = p_loop.pPrior
			if usize(p_loop) == usize(0) {
				break
			}
			cnt++
			if !isnil(p_loop.pOrderBy) || !isnil(p_loop.pLimit) {
				sqlite3_error_msg(p_parse, c'%s clause should come after %s not before', voidptr(if usize(p_loop.pOrderBy) != usize(0) {
					c'ORDER BY'
				} else {
					c'LIMIT'
				}), voidptr(sqlite3_select_op_name(int(p_next.op))))
				break
			}
		}
		if (p.selFlags & u32((1024 | 512))) == u32(0) && c2v_assign[int](unsafe { &mx_select }, int(p_parse.db.aLimit[4])) > 0 && cnt > mx_select {
			sqlite3_error_msg(p_parse, c'too many terms in compound SELECT')
		}
	}
}

@[c:'attachWithToSelect']
fn attach_with_to_select(p_parse &Parse, p_select &Select, p_with &With) &Select {
	if p_select {
		p_select.pWith = p_with
		parser_double_link_select(p_parse, p_select)
	} else {
		sqlite3_with_delete(p_parse.db, p_with)
	}
	return p_select
}

@[c:'parserStackRealloc']
fn parser_stack_realloc(p_old voidptr, new_size Sqlite3_uint64, p_parse &Parse) voidptr {
	p := voidptr(unsafe { if sqlite3_fault_sim(700) {
		&u8(nil)
	} else {
		&u8(sqlite3_realloc(voidptr(p_old), int(new_size)))
	} })
	if usize(p) == usize(0) {
		sqlite3_oom_fault(p_parse.db)
	}
	return p
}

@[c:'parserStackFree']
fn parser_stack_free(p_old voidptr, p_parse &Parse) {
	sqlite3_free(voidptr(p_old))
}

@[c:'parserStackSizeLimit']
fn parser_stack_size_limit(p_parse &Parse) int {
	return p_parse.db.aLimit[12]
}

@[c:'tokenExpr']
fn token_expr(p_parse &Parse, op int, t Token) &Expr {
	p := &Expr(sqlite3_db_malloc_raw_nn(p_parse.db, U64(sizeof(Expr) + u64(t.n) + u64(1))))
	if p {
		p.op = U8(op)
		p.affExpr = i8(0)
		p.flags = u32(8388608)
		p.pRight = 0
		p.pLeft = p.pRight
		p.pAggInfo = 0
		C.memset(voidptr(&p.x), 0, sizeof(Expr_x))
		C.memset(voidptr(&p.y), 0, sizeof(Expr_y))
		p.op2 = U8(0)
		p.iTable = 0
		p.iColumn = YnVar(0)
		p.u.zToken = &i8(voidptr(unsafe { p + 1 }))
		C.memcpy(voidptr(p.u.zToken), voidptr(t.z), u64(t.n))
		p.u.zToken[t.n] = i8(0)
		p.w.iOfst = int((i64((isize(t.z) - isize(p_parse.zTail)) / isize(sizeof(i8)))))
		if (int(sqlite3CtypeMap[u8(p.u.zToken[0])]) & 128) {
			sqlite3_dequote_expr(p)
		}
		p.nHeight = 1
		if (int(p_parse.eParseMode) >= 2) {
			return &Expr(sqlite3_rename_token_map(p_parse, voidptr(p), &t))
		}
	}
	return p
}

@[c:'sqlite3PExprIsNull']
fn sqlite3_pe_xpr_is_null(p_parse &Parse, op int, p_left &Expr) &Expr {
	p := p_left
	for int(p.op) == 173 || int(p.op) == 174 {
		p = p.pLeft
	}
	match p.op {
		156, 118, 154, 155 {
			sqlite3_expr_deferred_delete(p_parse, p_left)
			return sqlite3_expr_int32(p_parse.db, op == 52)
		}
		else {
		}
	}

	return sqlite3_pe_xpr(p_parse, op, p_left, unsafe { nil })
}

@[c:'sqlite3PExprIs']
fn sqlite3_pe_xpr_is(p_parse &Parse, op int, p_left &Expr, p_right &Expr) &Expr {
	if !isnil(p_right) && int(p_right.op) == 122 {
		sqlite3_expr_deferred_delete(p_parse, p_right)
		return sqlite3_pe_xpr_is_null(p_parse, if op == 45 { 51 } else { 52 }, p_left)
	}
	return sqlite3_pe_xpr(p_parse, op, p_left, p_right)
}

@[c:'parserAddExprIdListTerm']
fn parser_add_expr_id_list_term(p_parse &Parse, p_prior &ExprList, p_id_token &Token, has_collate int, sort_order int) &ExprList {
	p := sqlite3_expr_list_append(p_parse, p_prior, unsafe { nil })
	if (has_collate || sort_order != -1) && int(p_parse.db.init.busy) == 0 {
		sqlite3_error_msg(p_parse, c'syntax error after column name "%.*s"', p_id_token.n, voidptr(p_id_token.z))
	}
	sqlite3_expr_list_set_name(p_parse, p, p_id_token, 1)
	return p
}
