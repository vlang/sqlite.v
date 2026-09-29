@[translated]
module main

struct YYMINORTYPE_yy383 {
	value int
	mask  int
}

union YYMINORTYPE {
	yyinit int
	yy0    Token
	yy14   &ExprList
	yy59   &With
	yy67   &Cte
	yy122  &Upsert
	yy132  &IdList
	yy144  int
	yy168  &i8
	yy203  &SrcList
	yy211  &Window
	yy269  OnOrUsing
	yy286  TrigEvent
	yy383  YYMINORTYPE_yy383
	yy391  u32
	yy427  &TriggerStep
	yy454  &Expr
	yy462  U8
	yy509  FrameBound
	yy555  &Select
}

struct YyStackEntry {
	stateno u16
	major   u16
	minor   YYMINORTYPE
}

struct YyParser {
	yytos      &YyStackEntry
	pParse     &Parse
	yystackEnd &YyStackEntry
	yystack    &YyStackEntry
	yystk0     [50]YyStackEntry
}

@[c:'yyGrowStack']
fn yy_grow_stack(p &YyParser) int {
	old_size := 1 + int((i64((isize(p.yystackEnd) - isize(p.yystack)) / isize(sizeof(YyStackEntry)))))
	new_size := 0
	idx := 0
	p_new := &YyStackEntry(0)
	n_limit := parser_stack_size_limit(p.pParse)
	new_size = old_size * 2 + 100
	if new_size > n_limit {
		new_size = n_limit
		if new_size <= old_size {
			return 1
		}
	}
	idx = int((i64((isize(p.yytos) - isize(p.yystack)) / isize(sizeof(YyStackEntry)))))
	if usize(p.yystack) == usize(unsafe { &p.yystk0[0] }) {
		p_new = parser_stack_realloc(unsafe { nil }, Sqlite3_uint64(u64(new_size) * sizeof(YyStackEntry)), p.pParse)
		if usize(p_new) == usize(0) {
			return 1
		}
		C.memcpy(voidptr(p_new), voidptr(p.yystack), u64(old_size) * sizeof(YyStackEntry))
	} else {
		p_new = parser_stack_realloc(voidptr(p.yystack), Sqlite3_uint64(u64(new_size) * sizeof(YyStackEntry)), p.pParse)
		if usize(p_new) == usize(0) {
			return 1
		}
	}
	p.yystack = p_new
	p.yytos = unsafe { p.yystack + idx }
	p.yystackEnd = unsafe { p.yystack + (new_size - 1) }
	return 0
}

@[c:'sqlite3ParserInit']
fn sqlite3_parser_init(yyp_raw_parser voidptr, p_parse &Parse) {
	yyp_parser := &YyParser(yyp_raw_parser)
	yyp_parser.pParse = p_parse
	yyp_parser.yystack = unsafe { &yyp_parser.yystk0[0] }
	yyp_parser.yystackEnd = unsafe { yyp_parser.yystack + (50 - 1) }
	yyp_parser.yytos = yyp_parser.yystack
	yyp_parser.yystack[0].stateno = u16(0)
	yyp_parser.yystack[0].major = u16(0)
}

fn yy_destructor(yyp_parser &YyParser, yymajor u16, yypminor &YYMINORTYPE) {
	p_parse := yyp_parser.pParse
	match int(yymajor) {
		206, 241, 242, 254, 256 {
			sqlite3_select_delete(p_parse.db, yypminor.yy555)
		}
		218, 219, 248, 250, 270, 281, 283, 286, 293, 297, 314 {
			sqlite3_expr_delete(p_parse.db, yypminor.yy454)
		}
		223, 233, 234, 246, 249, 251, 255, 257, 264, 271, 280, 282, 313 {
			sqlite3_expr_list_delete(p_parse.db, yypminor.yy14)
		}
		240, 247, 259, 260, 265 {
			sqlite3_src_list_delete(p_parse.db, yypminor.yy203)
		}
		243 {
			sqlite3_with_delete(p_parse.db, yypminor.yy59)
		}
		253, 309 {
			sqlite3_window_list_delete(p_parse.db, yypminor.yy211)
		}
		266, 273 {
			sqlite3_id_list_delete(p_parse.db, yypminor.yy132)
		}
		276, 310, 311, 312, 315 {
			sqlite3_window_delete(p_parse.db, yypminor.yy211)
		}
		289, 294 {
			sqlite3_delete_trigger_step(p_parse.db, yypminor.yy427)
		}
		291 {
			sqlite3_id_list_delete(p_parse.db, yypminor.yy286.b)
		}
		317, 318, 319 {
			sqlite3_expr_delete(p_parse.db, yypminor.yy509.pExpr)
		}
		else {
		}
	}
}

fn yy_pop_parser_stack(p_parser &YyParser) {
	yytos := &YyStackEntry(0)
	mut __c2v_postfix_value_50 := p_parser.yytos
	c2v_pointer_postfix(voidptr(&p_parser.yytos), p_parser.yytos, isize(-1))
	yytos = __c2v_postfix_value_50
	yy_destructor(p_parser, yytos.major, &yytos.minor)
}

@[c:'sqlite3ParserFinalize']
fn sqlite3_parser_finalize(p voidptr) {
	p_parser := &YyParser(p)
	yytos := p_parser.yytos
	for usize(yytos) > usize(p_parser.yystack) {
		if int(yytos.major) >= 206 {
			yy_destructor(p_parser, yytos.major, &yytos.minor)
		}
		c2v_pointer_postfix(voidptr(&yytos), yytos, isize(-1))
	}
	if usize(p_parser.yystack) != usize(unsafe { &p_parser.yystk0[0] }) {
		parser_stack_free(voidptr(p_parser.yystack), p_parser.pParse)
	}
}

fn yy_find_shift_action(i_look_ahead u16, stateno u16) u16 {
	i := 0
	if int(stateno) > 599 {
		return stateno
	}
	for {
		i = int(yy_shift_ofst[stateno])
		i += int(i_look_ahead)
		if int(yy_lookahead[i]) != int(i_look_ahead) {
			i_fallback := u16(0)
			i_fallback = yy_fallback[i_look_ahead]
			if int(i_fallback) != 0 {
				i_look_ahead = i_fallback
				unsafe { goto c2v_do_next_215
				 }
			}
			j := i - int(i_look_ahead) + 102
			if int(yy_lookahead[j]) == 102 && int(i_look_ahead) > 0 {
				return yy_action[j]
			}
			return yy_default[stateno]
		} else {
			return yy_action[i]
		}
		c2v_do_next_215:
	}
	return u16(0)
}

fn yy_find_reduce_action(stateno u16, i_look_ahead u16) u16 {
	i := 0
	i = int(yy_reduce_ofst[stateno])
	i += int(i_look_ahead)
	return yy_action[i]
}

@[c:'yyStackOverflow']
fn yy_stack_overflow(yyp_parser &YyParser) {
	p_parse := yyp_parser.pParse
	for usize(yyp_parser.yytos) > usize(yyp_parser.yystack) {
		yy_pop_parser_stack(yyp_parser)
	}
	if p_parse.nErr == 0 {
		sqlite3_error_msg(p_parse, c'Recursion limit')
	}
	yyp_parser.pParse = p_parse
}

fn yy_shift(yyp_parser &YyParser, yy_new_state u16, yy_major u16, yy_minor Token) {
	yytos := &YyStackEntry(0)
	c2v_pointer_postfix(voidptr(&yyp_parser.yytos), yyp_parser.yytos, isize(1))
	yytos = yyp_parser.yytos
	if usize(yytos) > usize(yyp_parser.yystackEnd) {
		if yy_grow_stack(yyp_parser) {
			c2v_pointer_postfix(voidptr(&yyp_parser.yytos), yyp_parser.yytos, isize(-1))
			yy_stack_overflow(yyp_parser)
			return
		}
		yytos = yyp_parser.yytos
	}
	if int(yy_new_state) > 599 {
		yy_new_state += 1282 - 867
	}
	yytos.stateno = yy_new_state
	yytos.major = yy_major
	yytos.minor.yy0 = yy_minor
	0
}

fn yy_reduce(yyp_parser &YyParser, yyruleno u32, yy_lookahead_2 int, yy_lookahead_token Token, p_parse &Parse) u16 {
	yygoto := 0
	yyact := u16(0)
	mut yymsp := &YyStackEntry(0)
	yysize := 0

	yymsp = yyp_parser.yytos
	yylhsminor := YYMINORTYPE{}
	match yyruleno {
		u32(0) {
			if usize(p_parse.pReprepare) == usize(0) {
				p_parse.explain = U8(1)
			}
		}
		u32(1) {
			if usize(p_parse.pReprepare) == usize(0) {
				p_parse.explain = U8(2)
			}
		}
		u32(2) {
			sqlite3_finish_coding(p_parse)
		}
		u32(3) {
			sqlite3_begin_transaction(p_parse, yymsp[-1].minor.yy144)
		}
		u32(4) {
			yymsp[1].minor.yy144 = 7
		}
		u32(5), u32(6) {
			0
			unsafe { goto c2v_case_69_12
			 }
		}
		u32(7) {
			c2v_case_69_12:
			0
			unsafe { goto c2v_case_69_13
			 }
		}
		u32(328) {
			c2v_case_69_13:
			0
			yymsp[0].minor.yy144 = int(yymsp[0].major)
		}
		u32(8), u32(9) {
			0
			sqlite3_end_transaction(p_parse, int(yymsp[-1].major))
		}
		u32(10) {
			sqlite3_savepoint(p_parse, 0, &yymsp[0].minor.yy0)
		}
		u32(11) {
			sqlite3_savepoint(p_parse, 1, &yymsp[0].minor.yy0)
		}
		u32(12) {
			sqlite3_savepoint(p_parse, 2, &yymsp[0].minor.yy0)
		}
		u32(13) {
			sqlite3_start_table(p_parse, &yymsp[-1].minor.yy0, &yymsp[0].minor.yy0, yymsp[-4].minor.yy144, 0, 0, yymsp[-2].minor.yy144)
		}
		u32(14) {
			disable_lookaside(p_parse)
		}
		u32(15), u32(18) {
			0
			unsafe { goto c2v_case_69_30
			 }
		}
		u32(47) {
			c2v_case_69_30:
			0
			unsafe { goto c2v_case_69_31
			 }
		}
		u32(62) {
			c2v_case_69_31:
			0
			unsafe { goto c2v_case_69_32
			 }
		}
		u32(72) {
			c2v_case_69_32:
			0
			unsafe { goto c2v_case_69_33
			 }
		}
		u32(81) {
			c2v_case_69_33:
			0
			unsafe { goto c2v_case_69_34
			 }
		}
		u32(100) {
			c2v_case_69_34:
			0
			unsafe { goto c2v_case_69_35
			 }
		}
		u32(246) {
			c2v_case_69_35:
			0
			yymsp[1].minor.yy144 = 0
		}
		u32(16) {
			yymsp[-2].minor.yy144 = 1
		}
		u32(17) {
			yymsp[0].minor.yy144 = int(p_parse.db.init.busy) == 0
		}
		u32(19) {
			sqlite3_end_table(p_parse, &yymsp[-2].minor.yy0, &yymsp[-1].minor.yy0, yymsp[0].minor.yy391, unsafe { nil })
		}
		u32(20) {
			sqlite3_end_table(p_parse, unsafe { nil }, unsafe { nil }, u32(0), yymsp[0].minor.yy555)
			sqlite3_select_delete(p_parse.db, yymsp[0].minor.yy555)
		}
		u32(21) {
			yymsp[1].minor.yy391 = u32(0)
		}
		u32(22) {
			yylhsminor.yy391 = yymsp[-2].minor.yy391 | yymsp[0].minor.yy391
			yymsp[-2].minor.yy391 = yylhsminor.yy391
		}
		u32(23) {
			if yymsp[0].minor.yy0.n == u32(5) && sqlite3_strnicmp(yymsp[0].minor.yy0.z, c'rowid', 5) == 0 {
				yymsp[-1].minor.yy391 = u32(128 | 512)
			} else {
				yymsp[-1].minor.yy391 = u32(0)
				sqlite3_error_msg(p_parse, c'unknown table option: %.*s', yymsp[0].minor.yy0.n, voidptr(yymsp[0].minor.yy0.z))
			}
		}
		u32(24) {
			if yymsp[0].minor.yy0.n == u32(6) && sqlite3_strnicmp(yymsp[0].minor.yy0.z, c'strict', 6) == 0 {
				yylhsminor.yy391 = u32(65536)
			} else {
				yylhsminor.yy391 = u32(0)
				sqlite3_error_msg(p_parse, c'unknown table option: %.*s', yymsp[0].minor.yy0.n, voidptr(yymsp[0].minor.yy0.z))
			}
			yymsp[0].minor.yy391 = yylhsminor.yy391
		}
		u32(25) {
			sqlite3_add_column(p_parse, yymsp[-1].minor.yy0, yymsp[0].minor.yy0)
		}
		u32(26), u32(65) {
			0
			unsafe { goto c2v_case_69_59
			 }
		}
		u32(106) {
			c2v_case_69_59:
			0
			yymsp[1].minor.yy0.n = u32(0)
			yymsp[1].minor.yy0.z = 0
		}
		u32(27) {
			yymsp[-3].minor.yy0.n = u32(int((i64((isize(unsafe { yymsp[0].minor.yy0.z + yymsp[0].minor.yy0.n }) - isize(yymsp[-3].minor.yy0.z)) / isize(sizeof(i8))))))
		}
		u32(28) {
			yymsp[-5].minor.yy0.n = u32(int((i64((isize(unsafe { yymsp[0].minor.yy0.z + yymsp[0].minor.yy0.n }) - isize(yymsp[-5].minor.yy0.z)) / isize(sizeof(i8))))))
		}
		u32(29) {
			yymsp[-1].minor.yy0.n = yymsp[0].minor.yy0.n + u32(int((i64((isize(yymsp[0].minor.yy0.z) - isize(yymsp[-1].minor.yy0.z)) / isize(sizeof(i8))))))
		}
		u32(30) {
			yymsp[1].minor.yy168 = yy_lookahead_token.z
		}
		u32(31) {
			yymsp[1].minor.yy0 = yy_lookahead_token
		}
		u32(32), u32(67) {
			0
			p_parse.u1.cr.constraintName = yymsp[0].minor.yy0
		}
		u32(33) {
			sqlite3_add_default_value(p_parse, yymsp[0].minor.yy454, yymsp[-1].minor.yy0.z, unsafe { yymsp[-1].minor.yy0.z + yymsp[-1].minor.yy0.n })
		}
		u32(34) {
			sqlite3_add_default_value(p_parse, yymsp[-1].minor.yy454, yymsp[-2].minor.yy0.z + 1, yymsp[0].minor.yy0.z)
		}
		u32(35) {
			sqlite3_add_default_value(p_parse, yymsp[0].minor.yy454, yymsp[-2].minor.yy0.z, unsafe { yymsp[-1].minor.yy0.z + yymsp[-1].minor.yy0.n })
		}
		u32(36) {
			p := sqlite3_pe_xpr(p_parse, 174, yymsp[0].minor.yy454, unsafe { nil })
			sqlite3_add_default_value(p_parse, p, yymsp[-2].minor.yy0.z, unsafe { yymsp[-1].minor.yy0.z + yymsp[-1].minor.yy0.n })
		}
		u32(37) {
			p := token_expr(p_parse, 118, yymsp[0].minor.yy0)
			if p {
				sqlite3_expr_id_to_truefalse(p)
				0
			}
			sqlite3_add_default_value(p_parse, p, yymsp[0].minor.yy0.z, yymsp[0].minor.yy0.z + yymsp[0].minor.yy0.n)
		}
		u32(38) {
			sqlite3_add_not_null(p_parse, yymsp[0].minor.yy144)
		}
		u32(39) {
			sqlite3_add_primary_key(p_parse, unsafe { nil }, yymsp[-1].minor.yy144, yymsp[0].minor.yy144, yymsp[-2].minor.yy144)
		}
		u32(40) {
			sqlite3_create_index(p_parse, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, yymsp[0].minor.yy144, unsafe { nil }, unsafe { nil }, 0, 0, U8(1))
		}
		u32(41) {
			sqlite3_add_check_constraint(p_parse, yymsp[-1].minor.yy454, yymsp[-2].minor.yy0.z, yymsp[0].minor.yy0.z)
		}
		u32(42) {
			sqlite3_create_foreign_key(p_parse, unsafe { nil }, &yymsp[-2].minor.yy0, yymsp[-1].minor.yy14, yymsp[0].minor.yy144)
		}
		u32(43) {
			sqlite3_defer_foreign_key(p_parse, yymsp[0].minor.yy144)
		}
		u32(44) {
			sqlite3_add_collate_type(p_parse, &yymsp[0].minor.yy0)
		}
		u32(45) {
			sqlite3_add_generated(p_parse, yymsp[-1].minor.yy454, unsafe { nil })
		}
		u32(46) {
			sqlite3_add_generated(p_parse, yymsp[-2].minor.yy454, &yymsp[0].minor.yy0)
		}
		u32(48) {
			yymsp[0].minor.yy144 = 1
		}
		u32(49) {
			yymsp[1].minor.yy144 = 0 * 257
		}
		u32(50) {
			yymsp[-1].minor.yy144 = (yymsp[-1].minor.yy144 & ~yymsp[0].minor.yy383.mask) | yymsp[0].minor.yy383.value
		}
		u32(51) {
			yymsp[-1].minor.yy383.value = 0
			yymsp[-1].minor.yy383.mask = 0
		}
		u32(52) {
			yymsp[-2].minor.yy383.value = 0
			yymsp[-2].minor.yy383.mask = 0
		}
		u32(53) {
			yymsp[-2].minor.yy383.value = yymsp[0].minor.yy144
			yymsp[-2].minor.yy383.mask = 255
		}
		u32(54) {
			yymsp[-2].minor.yy383.value = yymsp[0].minor.yy144 << 8
			yymsp[-2].minor.yy383.mask = 65280
		}
		u32(55) {
			yymsp[-1].minor.yy144 = 8
		}
		u32(56) {
			yymsp[-1].minor.yy144 = 9
		}
		u32(57) {
			yymsp[0].minor.yy144 = 10
		}
		u32(58) {
			yymsp[0].minor.yy144 = 7
		}
		u32(59) {
			yymsp[-1].minor.yy144 = 0
		}
		u32(60) {
			yymsp[-2].minor.yy144 = 0
		}
		u32(61), u32(76) {
			0
			unsafe { goto c2v_case_69_130
			 }
		}
		u32(173) {
			c2v_case_69_130:
			0
			yymsp[-1].minor.yy144 = yymsp[0].minor.yy144
		}
		u32(63), u32(80) {
			0
			unsafe { goto c2v_case_69_134
			 }
		}
		u32(219) {
			c2v_case_69_134:
			0
			unsafe { goto c2v_case_69_135
			 }
		}
		u32(222) {
			c2v_case_69_135:
			0
			unsafe { goto c2v_case_69_136
			 }
		}
		u32(247) {
			c2v_case_69_136:
			0
			yymsp[-1].minor.yy144 = 1
		}
		u32(64) {
			yymsp[-1].minor.yy144 = 0
		}
		u32(66) {
			p_parse.u1.cr.constraintName.n = u32(0)
		}
		u32(68) {
			sqlite3_add_primary_key(p_parse, yymsp[-3].minor.yy14, yymsp[0].minor.yy144, yymsp[-2].minor.yy144, 0)
		}
		u32(69) {
			sqlite3_create_index(p_parse, unsafe { nil }, unsafe { nil }, unsafe { nil }, yymsp[-2].minor.yy14, yymsp[0].minor.yy144, unsafe { nil }, unsafe { nil }, 0, 0, U8(1))
		}
		u32(70) {
			sqlite3_add_check_constraint(p_parse, yymsp[-2].minor.yy454, yymsp[-3].minor.yy0.z, yymsp[-1].minor.yy0.z)
		}
		u32(71) {
			sqlite3_create_foreign_key(p_parse, yymsp[-6].minor.yy14, &yymsp[-3].minor.yy0, yymsp[-2].minor.yy14, yymsp[-1].minor.yy144)
			sqlite3_defer_foreign_key(p_parse, yymsp[0].minor.yy144)
		}
		u32(73), u32(75) {
			0
			yymsp[1].minor.yy144 = 11
		}
		u32(74) {
			yymsp[-2].minor.yy144 = yymsp[0].minor.yy144
		}
		u32(77) {
			yymsp[0].minor.yy144 = 4
		}
		u32(78), u32(174) {
			0
			yymsp[0].minor.yy144 = 5
		}
		u32(79) {
			sqlite3_drop_table(p_parse, yymsp[0].minor.yy203, 0, yymsp[-1].minor.yy144)
		}
		u32(82) {
			sqlite3_create_view(p_parse, &yymsp[-8].minor.yy0, &yymsp[-4].minor.yy0, &yymsp[-3].minor.yy0, yymsp[-2].minor.yy14, yymsp[0].minor.yy555, yymsp[-7].minor.yy144, yymsp[-5].minor.yy144)
		}
		u32(83) {
			sqlite3_drop_table(p_parse, yymsp[0].minor.yy203, 1, yymsp[-1].minor.yy144)
		}
		u32(84) {
			dest := SelectDest{
				eDest: U8(7)
				iSDParm: 0
				iSDParm2: 0
				iSdst: 0
				nSdst: 0
				zAffSdst: 0
				pOrderBy: 0
			}

			if (p_parse.db.mDbFlags & u32(64)) != u32(0) || sqlite3_read_schema(p_parse) == 0 {
				sqlite3_select(p_parse, yymsp[0].minor.yy555, &dest)
			}
			sqlite3_select_delete(p_parse.db, yymsp[0].minor.yy555)
		}
		u32(85) {
			yymsp[-2].minor.yy555 = attach_with_to_select(p_parse, yymsp[0].minor.yy555, yymsp[-1].minor.yy59)
		}
		u32(86) {
			yymsp[-3].minor.yy555 = attach_with_to_select(p_parse, yymsp[0].minor.yy555, yymsp[-1].minor.yy59)
		}
		u32(87) {
			p := yymsp[0].minor.yy555
			if p {
				parser_double_link_select(p_parse, p)
			}
		}
		u32(88) {
			p_rhs := yymsp[0].minor.yy555
			p_lhs := yymsp[-2].minor.yy555
			if !isnil(p_rhs) && !isnil(p_rhs.pPrior) {
				p_from := &SrcList(0)
				x := Token{}
				x.n = u32(0)
				parser_double_link_select(p_parse, p_rhs)
				p_from = sqlite3_src_list_append_from_term(p_parse, unsafe { nil }, unsafe { nil }, unsafe { nil }, &x, p_rhs, unsafe { nil })
				p_rhs = sqlite3_select_new(p_parse, unsafe { nil }, p_from, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, u32(0), unsafe { nil })
			}
			if p_rhs {
				p_rhs.op = U8(yymsp[-1].minor.yy144)
				p_rhs.pPrior = p_lhs
				if p_lhs {
					p_lhs.selFlags &= ~u32(1024)
				}
				p_rhs.selFlags &= ~u32(1024)
				if yymsp[-1].minor.yy144 != 136 {
					p_parse.hasCompound = Bft(1)
				}
			} else {
				sqlite3_select_delete(p_parse.db, p_lhs)
			}
			yymsp[-2].minor.yy555 = p_rhs
		}
		u32(89), u32(91) {
			0
			yymsp[0].minor.yy144 = int(yymsp[0].major)
		}
		u32(90) {
			yymsp[-1].minor.yy144 = 136
		}
		u32(92) {
			yymsp[-8].minor.yy555 = sqlite3_select_new(p_parse, yymsp[-6].minor.yy14, yymsp[-5].minor.yy203, yymsp[-4].minor.yy454, yymsp[-3].minor.yy14, yymsp[-2].minor.yy454, yymsp[-1].minor.yy14, u32(yymsp[-7].minor.yy144), yymsp[0].minor.yy454)
		}
		u32(93) {
			yymsp[-9].minor.yy555 = sqlite3_select_new(p_parse, yymsp[-7].minor.yy14, yymsp[-6].minor.yy203, yymsp[-5].minor.yy454, yymsp[-4].minor.yy14, yymsp[-3].minor.yy454, yymsp[-1].minor.yy14, u32(yymsp[-8].minor.yy144), yymsp[0].minor.yy454)
			if yymsp[-9].minor.yy555 {
				yymsp[-9].minor.yy555.pWinDefn = yymsp[-2].minor.yy211
			} else {
				sqlite3_window_list_delete(p_parse.db, yymsp[-2].minor.yy211)
			}
		}
		u32(94) {
			yymsp[-3].minor.yy555 = sqlite3_select_new(p_parse, yymsp[-1].minor.yy14, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, u32(512), unsafe { nil })
		}
		u32(95) {
			sqlite3_multi_values_end(p_parse, yymsp[0].minor.yy555)
		}
		u32(96), u32(97) {
			0
			yymsp[-4].minor.yy555 = sqlite3_multi_values(p_parse, yymsp[-4].minor.yy555, yymsp[-1].minor.yy14)
		}
		u32(98) {
			yymsp[0].minor.yy144 = 1
		}
		u32(99) {
			yymsp[0].minor.yy144 = 2
		}
		u32(101), u32(134) {
			0
			unsafe { goto c2v_case_69_198
			 }
		}
		u32(144) {
			c2v_case_69_198:
			0
			unsafe { goto c2v_case_69_199
			 }
		}
		u32(234) {
			c2v_case_69_199:
			0
			unsafe { goto c2v_case_69_200
			 }
		}
		u32(237) {
			c2v_case_69_200:
			0
			unsafe { goto c2v_case_69_201
			 }
		}
		u32(242) {
			c2v_case_69_201:
			0
			yymsp[1].minor.yy14 = 0
		}
		u32(102) {
			yymsp[-4].minor.yy14 = sqlite3_expr_list_append(p_parse, yymsp[-4].minor.yy14, yymsp[-2].minor.yy454)
			if yymsp[0].minor.yy0.n > u32(0) {
				sqlite3_expr_list_set_name(p_parse, yymsp[-4].minor.yy14, &yymsp[0].minor.yy0, 1)
			}
			sqlite3_expr_list_set_span(p_parse, yymsp[-4].minor.yy14, yymsp[-3].minor.yy168, yymsp[-1].minor.yy168)
		}
		u32(103) {
			p := sqlite3_expr(p_parse.db, 180, unsafe { nil })
			sqlite3_expr_set_error_offset(p, int((i64((isize(yymsp[0].minor.yy0.z) - isize(p_parse.zTail)) / isize(sizeof(i8))))))
			yymsp[-2].minor.yy14 = sqlite3_expr_list_append(p_parse, yymsp[-2].minor.yy14, p)
		}
		u32(104) {
			p_right := &Expr(0)
			p_left := &Expr(0)
			p_dot := &Expr(0)

			p_right = sqlite3_pe_xpr(p_parse, 180, unsafe { nil }, unsafe { nil })
			sqlite3_expr_set_error_offset(p_right, int((i64((isize(yymsp[0].minor.yy0.z) - isize(p_parse.zTail)) / isize(sizeof(i8))))))
			p_left = token_expr(p_parse, 60, yymsp[-2].minor.yy0)
			p_dot = sqlite3_pe_xpr(p_parse, 142, p_left, p_right)
			yymsp[-4].minor.yy14 = sqlite3_expr_list_append(p_parse, yymsp[-4].minor.yy14, p_dot)
		}
		u32(105), u32(117) {
			0
			unsafe { goto c2v_case_69_211
			 }
		}
		u32(258) {
			c2v_case_69_211:
			0
			unsafe { goto c2v_case_69_212
			 }
		}
		u32(259) {
			c2v_case_69_212:
			0
			yymsp[-1].minor.yy0 = yymsp[0].minor.yy0
		}
		u32(107), u32(110) {
			0
			yymsp[1].minor.yy203 = 0
		}
		u32(108) {
			yymsp[-1].minor.yy203 = yymsp[0].minor.yy203
			sqlite3_src_list_shift_join_type(p_parse, yymsp[-1].minor.yy203)
		}
		u32(109) {
			if (!isnil(yymsp[-1].minor.yy203) && yymsp[-1].minor.yy203.nSrc > 0) {
				mut __c2v_lhs_tmp_174 := unsafe { c2v_at(&yymsp[-1].minor.yy203.a[0], isize(yymsp[-1].minor.yy203.nSrc - 1)) }
				__c2v_lhs_tmp_174.fg.jointype = U8(yymsp[0].minor.yy144)
			}
		}
		u32(111) {
			yymsp[-4].minor.yy203 = sqlite3_src_list_append_from_term(p_parse, yymsp[-4].minor.yy203, &yymsp[-3].minor.yy0, &yymsp[-2].minor.yy0, &yymsp[-1].minor.yy0, unsafe { nil }, &yymsp[0].minor.yy269)
		}
		u32(112) {
			yymsp[-5].minor.yy203 = sqlite3_src_list_append_from_term(p_parse, yymsp[-5].minor.yy203, &yymsp[-4].minor.yy0, &yymsp[-3].minor.yy0, &yymsp[-2].minor.yy0, unsafe { nil }, &yymsp[0].minor.yy269)
			sqlite3_src_list_indexed_by(p_parse, yymsp[-5].minor.yy203, &yymsp[-1].minor.yy0)
		}
		u32(113) {
			yymsp[-7].minor.yy203 = sqlite3_src_list_append_from_term(p_parse, yymsp[-7].minor.yy203, &yymsp[-6].minor.yy0, &yymsp[-5].minor.yy0, &yymsp[-1].minor.yy0, unsafe { nil }, &yymsp[0].minor.yy269)
			sqlite3_src_list_func_args(p_parse, yymsp[-7].minor.yy203, yymsp[-3].minor.yy14)
		}
		u32(114) {
			yymsp[-5].minor.yy203 = sqlite3_src_list_append_from_term(p_parse, yymsp[-5].minor.yy203, unsafe { nil }, unsafe { nil }, &yymsp[-1].minor.yy0, yymsp[-3].minor.yy555, &yymsp[0].minor.yy269)
		}
		u32(115) {
			if usize(yymsp[-5].minor.yy203) == usize(0) && yymsp[-1].minor.yy0.n == u32(0) && usize(yymsp[0].minor.yy269.pOn) == usize(0) && usize(yymsp[0].minor.yy269.pUsing) == usize(0) {
				yymsp[-5].minor.yy203 = yymsp[-3].minor.yy203
			} else if (usize(yymsp[-3].minor.yy203) != usize(0)) && yymsp[-3].minor.yy203.nSrc == 1 {
				yymsp[-5].minor.yy203 = sqlite3_src_list_append_from_term(p_parse, yymsp[-5].minor.yy203, unsafe { nil }, unsafe { nil }, &yymsp[-1].minor.yy0, unsafe { nil }, &yymsp[0].minor.yy269)
				if yymsp[-5].minor.yy203 {
					p_new := unsafe { &yymsp[-5].minor.yy203.a[0] + (yymsp[-5].minor.yy203.nSrc - 1) }
					p_old := unsafe { &SrcItem(&yymsp[-3].minor.yy203.a[0]) }
					p_new.zName = p_old.zName
					if p_old.fg.isSubquery {
						p_new.fg.isSubquery = u32(1)
						p_new.u4.pSubq = p_old.u4.pSubq
						p_old.u4.pSubq = 0
						p_old.fg.isSubquery = u32(0)
						if (p_new.u4.pSubq.pSelect.selFlags & u32(2048)) != u32(0) {
							p_new.fg.isNestedFrom = u32(1)
						}
					} else {
						p_new.u4.zDatabase = p_old.u4.zDatabase
						p_old.u4.zDatabase = 0
					}
					if p_old.fg.isTabFunc {
						p_new.u1.pFuncArg = p_old.u1.pFuncArg
						p_old.u1.pFuncArg = 0
						p_old.fg.isTabFunc = u32(0)
						p_new.fg.isTabFunc = u32(1)
					}
					p_old.zName = 0
				}
				sqlite3_src_list_delete(p_parse.db, yymsp[-3].minor.yy203)
			} else {
				p_subquery := &Select(0)
				sqlite3_src_list_shift_join_type(p_parse, yymsp[-3].minor.yy203)
				p_subquery = sqlite3_select_new(p_parse, unsafe { nil }, yymsp[-3].minor.yy203, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, u32(2048), unsafe { nil })
				yymsp[-5].minor.yy203 = sqlite3_src_list_append_from_term(p_parse, yymsp[-5].minor.yy203, unsafe { nil }, unsafe { nil }, &yymsp[-1].minor.yy0, p_subquery, &yymsp[0].minor.yy269)
			}
		}
		u32(116), u32(131) {
			0
			yymsp[1].minor.yy0.z = 0
			yymsp[1].minor.yy0.n = u32(0)
		}
		u32(118), u32(120) {
			0
			yylhsminor.yy203 = sqlite3_src_list_append(p_parse, unsafe { nil }, &yymsp[0].minor.yy0, unsafe { nil })
			if (int(p_parse.eParseMode) >= 2) && !isnil(yylhsminor.yy203) {
				sqlite3_rename_token_map(p_parse, voidptr(c2v_at(&yylhsminor.yy203.a[0], isize(0)).zName), &yymsp[0].minor.yy0)
			}
			yymsp[0].minor.yy203 = yylhsminor.yy203
		}
		u32(119), u32(121) {
			0
			yylhsminor.yy203 = sqlite3_src_list_append(p_parse, unsafe { nil }, &yymsp[-2].minor.yy0, &yymsp[0].minor.yy0)
			if (int(p_parse.eParseMode) >= 2) && !isnil(yylhsminor.yy203) {
				sqlite3_rename_token_map(p_parse, voidptr(c2v_at(&yylhsminor.yy203.a[0], isize(0)).zName), &yymsp[0].minor.yy0)
			}
			yymsp[-2].minor.yy203 = yylhsminor.yy203
		}
		u32(122) {
			yylhsminor.yy203 = sqlite3_src_list_append(p_parse, unsafe { nil }, &yymsp[-2].minor.yy0, unsafe { nil })
			if yylhsminor.yy203 {
				if (int(p_parse.eParseMode) >= 2) {
					sqlite3_rename_token_map(p_parse, voidptr(c2v_at(&yylhsminor.yy203.a[0], isize(0)).zName), &yymsp[-2].minor.yy0)
				} else {
					mut __c2v_lhs_tmp_175 := c2v_at(&yylhsminor.yy203.a[0], isize(0))
					__c2v_lhs_tmp_175.zAlias = sqlite3_name_from_token(p_parse.db, &yymsp[0].minor.yy0)
				}
			}
			yymsp[-2].minor.yy203 = yylhsminor.yy203
		}
		u32(123) {
			yylhsminor.yy203 = sqlite3_src_list_append(p_parse, unsafe { nil }, &yymsp[-4].minor.yy0, &yymsp[-2].minor.yy0)
			if yylhsminor.yy203 {
				if (int(p_parse.eParseMode) >= 2) {
					sqlite3_rename_token_map(p_parse, voidptr(c2v_at(&yylhsminor.yy203.a[0], isize(0)).zName), &yymsp[-2].minor.yy0)
				} else {
					mut __c2v_lhs_tmp_176 := c2v_at(&yylhsminor.yy203.a[0], isize(0))
					__c2v_lhs_tmp_176.zAlias = sqlite3_name_from_token(p_parse.db, &yymsp[0].minor.yy0)
				}
			}
			yymsp[-4].minor.yy203 = yylhsminor.yy203
		}
		u32(124) {
			yymsp[0].minor.yy144 = 1
		}
		u32(125) {
			yymsp[-1].minor.yy144 = sqlite3_join_type(p_parse, &yymsp[-1].minor.yy0, unsafe { nil }, unsafe { nil })
		}
		u32(126) {
			yymsp[-2].minor.yy144 = sqlite3_join_type(p_parse, &yymsp[-2].minor.yy0, &yymsp[-1].minor.yy0, unsafe { nil })
		}
		u32(127) {
			yymsp[-3].minor.yy144 = sqlite3_join_type(p_parse, &yymsp[-3].minor.yy0, &yymsp[-2].minor.yy0, &yymsp[-1].minor.yy0)
		}
		u32(128) {
			yymsp[-1].minor.yy269.pOn = yymsp[0].minor.yy454
			yymsp[-1].minor.yy269.pUsing = 0
		}
		u32(129) {
			yymsp[-3].minor.yy269.pOn = 0
			yymsp[-3].minor.yy269.pUsing = yymsp[-1].minor.yy132
		}
		u32(130) {
			yymsp[1].minor.yy269.pOn = 0
			yymsp[1].minor.yy269.pUsing = 0
		}
		u32(132) {
			yymsp[-2].minor.yy0 = yymsp[0].minor.yy0
		}
		u32(133) {
			yymsp[-1].minor.yy0.z = 0
			yymsp[-1].minor.yy0.n = u32(1)
		}
		u32(135), u32(145) {
			0
			yymsp[-2].minor.yy14 = yymsp[0].minor.yy14
		}
		u32(136) {
			yymsp[-4].minor.yy14 = sqlite3_expr_list_append(p_parse, yymsp[-4].minor.yy14, yymsp[-2].minor.yy454)
			sqlite3_expr_list_set_sort_order(yymsp[-4].minor.yy14, yymsp[-1].minor.yy144, yymsp[0].minor.yy144)
		}
		u32(137) {
			yymsp[-2].minor.yy14 = sqlite3_expr_list_append(p_parse, unsafe { nil }, yymsp[-2].minor.yy454)
			sqlite3_expr_list_set_sort_order(yymsp[-2].minor.yy14, yymsp[-1].minor.yy144, yymsp[0].minor.yy144)
		}
		u32(138) {
			yymsp[0].minor.yy144 = 0
		}
		u32(139) {
			yymsp[0].minor.yy144 = 1
		}
		u32(140), u32(143) {
			0
			yymsp[1].minor.yy144 = -1
		}
		u32(141) {
			yymsp[-1].minor.yy144 = 0
		}
		u32(142) {
			yymsp[-1].minor.yy144 = 1
		}
		u32(146), u32(148) {
			0
			unsafe { goto c2v_case_69_286
			 }
		}
		u32(153) {
			c2v_case_69_286:
			0
			unsafe { goto c2v_case_69_287
			 }
		}
		u32(155) {
			c2v_case_69_287:
			0
			unsafe { goto c2v_case_69_288
			 }
		}
		u32(232) {
			c2v_case_69_288:
			0
			unsafe { goto c2v_case_69_289
			 }
		}
		u32(233) {
			c2v_case_69_289:
			0
			unsafe { goto c2v_case_69_290
			 }
		}
		u32(252) {
			c2v_case_69_290:
			0
			yymsp[1].minor.yy454 = 0
		}
		u32(147), u32(154) {
			0
			unsafe { goto c2v_case_69_294
			 }
		}
		u32(156) {
			c2v_case_69_294:
			0
			unsafe { goto c2v_case_69_295
			 }
		}
		u32(231) {
			c2v_case_69_295:
			0
			unsafe { goto c2v_case_69_296
			 }
		}
		u32(251) {
			c2v_case_69_296:
			0
			yymsp[-1].minor.yy454 = yymsp[0].minor.yy454
		}
		u32(149) {
			yymsp[-1].minor.yy454 = sqlite3_pe_xpr(p_parse, 149, yymsp[0].minor.yy454, unsafe { nil })
		}
		u32(150) {
			yymsp[-3].minor.yy454 = sqlite3_pe_xpr(p_parse, 149, yymsp[-2].minor.yy454, yymsp[0].minor.yy454)
		}
		u32(151) {
			yymsp[-3].minor.yy454 = sqlite3_pe_xpr(p_parse, 149, yymsp[0].minor.yy454, yymsp[-2].minor.yy454)
		}
		u32(152) {
			sqlite3_src_list_indexed_by(p_parse, yymsp[-2].minor.yy203, &yymsp[-1].minor.yy0)
			sqlite3_delete_from(p_parse, yymsp[-2].minor.yy203, yymsp[0].minor.yy454, unsafe { nil }, unsafe { nil })
		}
		u32(157) {
			sqlite3_add_returning(p_parse, yymsp[0].minor.yy14)
			yymsp[-1].minor.yy454 = 0
		}
		u32(158) {
			sqlite3_add_returning(p_parse, yymsp[0].minor.yy14)
			yymsp[-3].minor.yy454 = yymsp[-2].minor.yy454
		}
		u32(159) {
			sqlite3_src_list_indexed_by(p_parse, yymsp[-5].minor.yy203, &yymsp[-4].minor.yy0)
			sqlite3_expr_list_check_length(p_parse, yymsp[-2].minor.yy14, c'set list')
			if yymsp[-1].minor.yy203 {
				p_from_clause := yymsp[-1].minor.yy203
				if p_from_clause.nSrc > 1 {
					p_subquery := &Select(0)
					as_ := Token{}
					p_subquery = sqlite3_select_new(p_parse, unsafe { nil }, p_from_clause, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, u32(2048), unsafe { nil })
					as_.n = u32(0)
					as_.z = 0
					p_from_clause = sqlite3_src_list_append_from_term(p_parse, unsafe { nil }, unsafe { nil }, unsafe { nil }, &as_, p_subquery, unsafe { nil })
				}
				yymsp[-5].minor.yy203 = sqlite3_src_list_append_list(p_parse, yymsp[-5].minor.yy203, p_from_clause)
			}
			sqlite3_update(p_parse, yymsp[-5].minor.yy203, yymsp[-2].minor.yy14, yymsp[0].minor.yy454, yymsp[-6].minor.yy144, unsafe { nil }, unsafe { nil }, unsafe { nil })
		}
		u32(160) {
			yymsp[-4].minor.yy14 = sqlite3_expr_list_append(p_parse, yymsp[-4].minor.yy14, yymsp[0].minor.yy454)
			sqlite3_expr_list_set_name(p_parse, yymsp[-4].minor.yy14, &yymsp[-2].minor.yy0, 1)
		}
		u32(161) {
			yymsp[-6].minor.yy14 = sqlite3_expr_list_append_vector(p_parse, yymsp[-6].minor.yy14, yymsp[-3].minor.yy132, yymsp[0].minor.yy454)
		}
		u32(162) {
			yylhsminor.yy14 = sqlite3_expr_list_append(p_parse, unsafe { nil }, yymsp[0].minor.yy454)
			sqlite3_expr_list_set_name(p_parse, yylhsminor.yy14, &yymsp[-2].minor.yy0, 1)
			yymsp[-2].minor.yy14 = yylhsminor.yy14
		}
		u32(163) {
			yymsp[-4].minor.yy14 = sqlite3_expr_list_append_vector(p_parse, unsafe { nil }, yymsp[-3].minor.yy132, yymsp[0].minor.yy454)
		}
		u32(164) {
			sqlite3_insert(p_parse, yymsp[-3].minor.yy203, yymsp[-1].minor.yy555, yymsp[-2].minor.yy132, yymsp[-5].minor.yy144, yymsp[0].minor.yy122)
		}
		u32(165) {
			sqlite3_insert(p_parse, yymsp[-4].minor.yy203, unsafe { nil }, yymsp[-3].minor.yy132, yymsp[-6].minor.yy144, unsafe { nil })
		}
		u32(166) {
			yymsp[1].minor.yy122 = 0
		}
		u32(167) {
			yymsp[-1].minor.yy122 = 0
			sqlite3_add_returning(p_parse, yymsp[0].minor.yy14)
		}
		u32(168) {
			yymsp[-11].minor.yy122 = sqlite3_upsert_new(p_parse.db, yymsp[-8].minor.yy14, yymsp[-6].minor.yy454, yymsp[-2].minor.yy14, yymsp[-1].minor.yy454, yymsp[0].minor.yy122)
		}
		u32(169) {
			yymsp[-8].minor.yy122 = sqlite3_upsert_new(p_parse.db, yymsp[-5].minor.yy14, yymsp[-3].minor.yy454, unsafe { nil }, unsafe { nil }, yymsp[0].minor.yy122)
		}
		u32(170) {
			yymsp[-4].minor.yy122 = sqlite3_upsert_new(p_parse.db, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil })
		}
		u32(171) {
			yymsp[-7].minor.yy122 = sqlite3_upsert_new(p_parse.db, unsafe { nil }, unsafe { nil }, yymsp[-2].minor.yy14, yymsp[-1].minor.yy454, unsafe { nil })
		}
		u32(172) {
			sqlite3_add_returning(p_parse, yymsp[0].minor.yy14)
		}
		u32(175) {
			yymsp[1].minor.yy132 = 0
		}
		u32(176) {
			yymsp[-2].minor.yy132 = yymsp[-1].minor.yy132
		}
		u32(177) {
			yymsp[-2].minor.yy132 = sqlite3_id_list_append(p_parse, yymsp[-2].minor.yy132, &yymsp[0].minor.yy0)
		}
		u32(178) {
			yymsp[0].minor.yy132 = sqlite3_id_list_append(p_parse, unsafe { nil }, &yymsp[0].minor.yy0)
		}
		u32(179) {
			yymsp[-2].minor.yy454 = yymsp[-1].minor.yy454
		}
		u32(180) {
			yymsp[0].minor.yy454 = token_expr(p_parse, 60, yymsp[0].minor.yy0)
		}
		u32(181) {
			temp1 := token_expr(p_parse, 60, yymsp[-2].minor.yy0)
			temp2 := token_expr(p_parse, 60, yymsp[0].minor.yy0)
			yylhsminor.yy454 = sqlite3_pe_xpr(p_parse, 142, temp1, temp2)
			yymsp[-2].minor.yy454 = yylhsminor.yy454
		}
		u32(182) {
			temp1 := token_expr(p_parse, 60, yymsp[-4].minor.yy0)
			temp2 := token_expr(p_parse, 60, yymsp[-2].minor.yy0)
			temp3 := token_expr(p_parse, 60, yymsp[0].minor.yy0)
			temp4 := sqlite3_pe_xpr(p_parse, 142, temp2, temp3)
			if (int(p_parse.eParseMode) >= 2) {
				sqlite3_rename_token_remap(p_parse, unsafe { nil }, voidptr(temp1))
			}
			yylhsminor.yy454 = sqlite3_pe_xpr(p_parse, 142, temp1, temp4)
			yymsp[-4].minor.yy454 = yylhsminor.yy454
		}
		u32(183), u32(184) {
			0
			yymsp[0].minor.yy454 = token_expr(p_parse, int(yymsp[0].major), yymsp[0].minor.yy0)
		}
		u32(185) {
			i_value := 0
			if sqlite3_get_int32(yymsp[0].minor.yy0.z, &i_value) == 0 {
				yylhsminor.yy454 = sqlite3_expr_alloc(p_parse.db, 156, &yymsp[0].minor.yy0, 0)
			} else {
				yylhsminor.yy454 = sqlite3_expr_int32(p_parse.db, i_value)
			}
			if yylhsminor.yy454 {
				yylhsminor.yy454.w.iOfst = int((i64((isize(yymsp[0].minor.yy0.z) - isize(p_parse.zTail)) / isize(sizeof(i8)))))
			}
			yymsp[0].minor.yy454 = yylhsminor.yy454
		}
		u32(186) {
			if !(int(yymsp[0].minor.yy0.z[0]) == i8(`#`) && (int(sqlite3CtypeMap[u8(yymsp[0].minor.yy0.z[1])]) & 4)) {
				n := yymsp[0].minor.yy0.n
				yymsp[0].minor.yy454 = token_expr(p_parse, 157, yymsp[0].minor.yy0)
				sqlite3_expr_assign_var_number(p_parse, yymsp[0].minor.yy454, n)
			} else {
				t := yymsp[0].minor.yy0
				if int(p_parse.nested) == 0 {
					parser_syntax_error(p_parse, &t)
					yymsp[0].minor.yy454 = 0
				} else {
					yymsp[0].minor.yy454 = sqlite3_pe_xpr(p_parse, 176, unsafe { nil }, unsafe { nil })
					if yymsp[0].minor.yy454 {
						sqlite3_get_int32(unsafe { t.z + 1 }, &yymsp[0].minor.yy454.iTable)
					}
				}
			}
		}
		u32(187) {
			yymsp[-2].minor.yy454 = sqlite3_expr_add_collate_token(p_parse, yymsp[-2].minor.yy454, &yymsp[0].minor.yy0, 1)
		}
		u32(188) {
			yymsp[-5].minor.yy454 = sqlite3_expr_alloc(p_parse.db, 36, &yymsp[-1].minor.yy0, 1)
			sqlite3_expr_attach_subtrees(p_parse.db, yymsp[-5].minor.yy454, yymsp[-3].minor.yy454, unsafe { nil })
		}
		u32(189) {
			yylhsminor.yy454 = sqlite3_expr_function(p_parse, yymsp[-1].minor.yy14, &yymsp[-4].minor.yy0, yymsp[-2].minor.yy144)
			yymsp[-4].minor.yy454 = yylhsminor.yy454
		}
		u32(190) {
			yylhsminor.yy454 = sqlite3_expr_function(p_parse, yymsp[-4].minor.yy14, &yymsp[-7].minor.yy0, yymsp[-5].minor.yy144)
			sqlite3_expr_add_function_order_by(p_parse, yylhsminor.yy454, yymsp[-1].minor.yy14)
			yymsp[-7].minor.yy454 = yylhsminor.yy454
		}
		u32(191) {
			yylhsminor.yy454 = sqlite3_expr_function(p_parse, unsafe { nil }, &yymsp[-3].minor.yy0, 0)
			yymsp[-3].minor.yy454 = yylhsminor.yy454
		}
		u32(192) {
			yylhsminor.yy454 = sqlite3_expr_function(p_parse, yymsp[-2].minor.yy14, &yymsp[-5].minor.yy0, yymsp[-3].minor.yy144)
			sqlite3_window_attach(p_parse, yylhsminor.yy454, yymsp[0].minor.yy211)
			yymsp[-5].minor.yy454 = yylhsminor.yy454
		}
		u32(193) {
			yylhsminor.yy454 = sqlite3_expr_function(p_parse, yymsp[-5].minor.yy14, &yymsp[-8].minor.yy0, yymsp[-6].minor.yy144)
			sqlite3_window_attach(p_parse, yylhsminor.yy454, yymsp[0].minor.yy211)
			sqlite3_expr_add_function_order_by(p_parse, yylhsminor.yy454, yymsp[-2].minor.yy14)
			yymsp[-8].minor.yy454 = yylhsminor.yy454
		}
		u32(194) {
			yylhsminor.yy454 = sqlite3_expr_function(p_parse, unsafe { nil }, &yymsp[-4].minor.yy0, 0)
			sqlite3_window_attach(p_parse, yylhsminor.yy454, yymsp[0].minor.yy211)
			yymsp[-4].minor.yy454 = yylhsminor.yy454
		}
		u32(195) {
			yylhsminor.yy454 = sqlite3_expr_function(p_parse, unsafe { nil }, &yymsp[0].minor.yy0, 0)
			yymsp[0].minor.yy454 = yylhsminor.yy454
		}
		u32(196) {
			p_list := sqlite3_expr_list_append(p_parse, yymsp[-3].minor.yy14, yymsp[-1].minor.yy454)
			yymsp[-4].minor.yy454 = sqlite3_pe_xpr(p_parse, 177, unsafe { nil }, unsafe { nil })
			if yymsp[-4].minor.yy454 {
				i := 0
				yymsp[-4].minor.yy454.x.pList = p_list
				for i = 0; i < p_list.nExpr; i++ {
					yymsp[-4].minor.yy454.flags |= c2v_at(&p_list.a[0], isize(i)).pExpr.flags & u32((512 | 4194304 | 8))
				}
			} else {
				sqlite3_expr_list_delete(p_parse.db, p_list)
			}
		}
		u32(197) {
			yymsp[-2].minor.yy454 = sqlite3_expr_and(p_parse, yymsp[-2].minor.yy454, yymsp[0].minor.yy454)
		}
		u32(198), u32(199) {
			0
			unsafe { goto c2v_case_69_396
			 }
		}
		u32(200) {
			c2v_case_69_396:
			0
			unsafe { goto c2v_case_69_397
			 }
		}
		u32(201) {
			c2v_case_69_397:
			0
			unsafe { goto c2v_case_69_398
			 }
		}
		u32(202) {
			c2v_case_69_398:
			0
			unsafe { goto c2v_case_69_399
			 }
		}
		u32(203) {
			c2v_case_69_399:
			0
			unsafe { goto c2v_case_69_400
			 }
		}
		u32(204) {
			c2v_case_69_400:
			0
			yymsp[-2].minor.yy454 = sqlite3_pe_xpr(p_parse, int(yymsp[-1].major), yymsp[-2].minor.yy454, yymsp[0].minor.yy454)
		}
		u32(205) {
			yymsp[-1].minor.yy0 = yymsp[0].minor.yy0
			yymsp[-1].minor.yy0.n |= u32(2147483648)
		}
		u32(206) {
			p_list := &ExprList(0)
			b_not := int(yymsp[-1].minor.yy0.n & u32(2147483648))
			yymsp[-1].minor.yy0.n &= u32(2147483647)
			p_list = sqlite3_expr_list_append(p_parse, unsafe { nil }, yymsp[0].minor.yy454)
			p_list = sqlite3_expr_list_append(p_parse, p_list, yymsp[-2].minor.yy454)
			yymsp[-2].minor.yy454 = sqlite3_expr_function(p_parse, p_list, &yymsp[-1].minor.yy0, 0)
			if b_not {
				yymsp[-2].minor.yy454 = sqlite3_pe_xpr(p_parse, 19, yymsp[-2].minor.yy454, unsafe { nil })
			}
			if yymsp[-2].minor.yy454 {
				yymsp[-2].minor.yy454.flags |= u32(256)
			}
		}
		u32(207) {
			p_list := &ExprList(0)
			b_not := int(yymsp[-3].minor.yy0.n & u32(2147483648))
			yymsp[-3].minor.yy0.n &= u32(2147483647)
			p_list = sqlite3_expr_list_append(p_parse, unsafe { nil }, yymsp[-2].minor.yy454)
			p_list = sqlite3_expr_list_append(p_parse, p_list, yymsp[-4].minor.yy454)
			p_list = sqlite3_expr_list_append(p_parse, p_list, yymsp[0].minor.yy454)
			yymsp[-4].minor.yy454 = sqlite3_expr_function(p_parse, p_list, &yymsp[-3].minor.yy0, 0)
			if b_not {
				yymsp[-4].minor.yy454 = sqlite3_pe_xpr(p_parse, 19, yymsp[-4].minor.yy454, unsafe { nil })
			}
			if yymsp[-4].minor.yy454 {
				yymsp[-4].minor.yy454.flags |= u32(256)
			}
		}
		u32(208) {
			yymsp[-1].minor.yy454 = sqlite3_pe_xpr_is_null(p_parse, int(yymsp[0].major), yymsp[-1].minor.yy454)
		}
		u32(209) {
			yymsp[-2].minor.yy454 = sqlite3_pe_xpr_is_null(p_parse, 52, yymsp[-2].minor.yy454)
		}
		u32(210) {
			yymsp[-2].minor.yy454 = sqlite3_pe_xpr_is(p_parse, 45, yymsp[-2].minor.yy454, yymsp[0].minor.yy454)
		}
		u32(211) {
			yymsp[-3].minor.yy454 = sqlite3_pe_xpr_is(p_parse, 46, yymsp[-3].minor.yy454, yymsp[0].minor.yy454)
		}
		u32(212) {
			yymsp[-5].minor.yy454 = sqlite3_pe_xpr_is(p_parse, 45, yymsp[-5].minor.yy454, yymsp[0].minor.yy454)
		}
		u32(213) {
			yymsp[-4].minor.yy454 = sqlite3_pe_xpr_is(p_parse, 46, yymsp[-4].minor.yy454, yymsp[0].minor.yy454)
		}
		u32(214), u32(215) {
			0
			yymsp[-1].minor.yy454 = sqlite3_pe_xpr(p_parse, int(yymsp[-1].major), yymsp[0].minor.yy454, unsafe { nil })
		}
		u32(216) {
			p := yymsp[0].minor.yy454
			op := U8(int(yymsp[-1].major) + (173 - 107))
			if !isnil(p) && int(p.op) == 173 {
				p.op = op
				yymsp[-1].minor.yy454 = p
			} else {
				yymsp[-1].minor.yy454 = sqlite3_pe_xpr(p_parse, int(op), p, unsafe { nil })
			}
		}
		u32(217) {
			p_list := sqlite3_expr_list_append(p_parse, unsafe { nil }, yymsp[-2].minor.yy454)
			p_list = sqlite3_expr_list_append(p_parse, p_list, yymsp[0].minor.yy454)
			yylhsminor.yy454 = sqlite3_expr_function(p_parse, p_list, &yymsp[-1].minor.yy0, 0)
			yymsp[-2].minor.yy454 = yylhsminor.yy454
		}
		u32(218), u32(221) {
			0
			yymsp[0].minor.yy144 = 0
		}
		u32(220) {
			p_list := sqlite3_expr_list_append(p_parse, unsafe { nil }, yymsp[-2].minor.yy454)
			p_list = sqlite3_expr_list_append(p_parse, p_list, yymsp[0].minor.yy454)
			yymsp[-4].minor.yy454 = sqlite3_pe_xpr(p_parse, 49, yymsp[-4].minor.yy454, unsafe { nil })
			if yymsp[-4].minor.yy454 {
				yymsp[-4].minor.yy454.x.pList = p_list
				sqlite3_expr_set_height_and_flags(p_parse, yymsp[-4].minor.yy454)
			} else {
				sqlite3_expr_list_delete(p_parse.db, p_list)
			}
			if yymsp[-3].minor.yy144 {
				yymsp[-4].minor.yy454 = sqlite3_pe_xpr(p_parse, 19, yymsp[-4].minor.yy454, unsafe { nil })
			}
		}
		u32(223) {
			if usize(yymsp[-1].minor.yy14) == usize(0) {
				pb := sqlite3_expr(p_parse.db, 118, unsafe { if yymsp[-3].minor.yy144 {
					c'true'
				} else {
					c'false'
				} })
				if pb {
					sqlite3_expr_id_to_truefalse(pb)
				}
				if !((yymsp[-4].minor.yy454.flags & u32(8)) != u32(0)) {
					sqlite3_expr_unmap_and_delete(p_parse, yymsp[-4].minor.yy454)
					yymsp[-4].minor.yy454 = pb
				} else {
					yymsp[-4].minor.yy454 = sqlite3_pe_xpr(p_parse, if yymsp[-3].minor.yy144 {
						43
					} else {
						44
					}, pb, yymsp[-4].minor.yy454)
				}
			} else {
				prhs := c2v_at(&yymsp[-1].minor.yy14.a[0], isize(0)).pExpr
				if yymsp[-1].minor.yy14.nExpr == 1 && sqlite3_expr_is_constant(p_parse, prhs) && int(yymsp[-4].minor.yy454.op) != 177 {
					mut __c2v_lhs_tmp_177 := c2v_at(&yymsp[-1].minor.yy14.a[0], isize(0))
					__c2v_lhs_tmp_177.pExpr = 0
					sqlite3_expr_list_delete(p_parse.db, yymsp[-1].minor.yy14)
					prhs = sqlite3_pe_xpr(p_parse, 173, prhs, unsafe { nil })
					yymsp[-4].minor.yy454 = sqlite3_pe_xpr(p_parse, 54, yymsp[-4].minor.yy454, prhs)
				} else if yymsp[-1].minor.yy14.nExpr == 1 && int(prhs.op) == 139 {
					yymsp[-4].minor.yy454 = sqlite3_pe_xpr(p_parse, 50, yymsp[-4].minor.yy454, unsafe { nil })
					sqlite3_pe_xpr_add_select(p_parse, yymsp[-4].minor.yy454, prhs.x.pSelect)
					prhs.x.pSelect = 0
					sqlite3_expr_list_delete(p_parse.db, yymsp[-1].minor.yy14)
				} else {
					yymsp[-4].minor.yy454 = sqlite3_pe_xpr(p_parse, 50, yymsp[-4].minor.yy454, unsafe { nil })
					if usize(yymsp[-4].minor.yy454) == usize(0) {
						sqlite3_expr_list_delete(p_parse.db, yymsp[-1].minor.yy14)
					} else if int(yymsp[-4].minor.yy454.pLeft.op) == 177 {
						n_expr := yymsp[-4].minor.yy454.pLeft.x.pList.nExpr
						p_select_rhs := sqlite3_expr_list_to_values(p_parse, n_expr, yymsp[-1].minor.yy14)
						if p_select_rhs {
							parser_double_link_select(p_parse, p_select_rhs)
							sqlite3_pe_xpr_add_select(p_parse, yymsp[-4].minor.yy454, p_select_rhs)
						}
					} else {
						yymsp[-4].minor.yy454.x.pList = yymsp[-1].minor.yy14
						sqlite3_expr_set_height_and_flags(p_parse, yymsp[-4].minor.yy454)
					}
				}
				if yymsp[-3].minor.yy144 {
					yymsp[-4].minor.yy454 = sqlite3_pe_xpr(p_parse, 19, yymsp[-4].minor.yy454, unsafe { nil })
				}
			}
		}
		u32(224) {
			yymsp[-2].minor.yy454 = sqlite3_pe_xpr(p_parse, 139, unsafe { nil }, unsafe { nil })
			sqlite3_pe_xpr_add_select(p_parse, yymsp[-2].minor.yy454, yymsp[-1].minor.yy555)
		}
		u32(225) {
			yymsp[-4].minor.yy454 = sqlite3_pe_xpr(p_parse, 50, yymsp[-4].minor.yy454, unsafe { nil })
			sqlite3_pe_xpr_add_select(p_parse, yymsp[-4].minor.yy454, yymsp[-1].minor.yy555)
			if yymsp[-3].minor.yy144 {
				yymsp[-4].minor.yy454 = sqlite3_pe_xpr(p_parse, 19, yymsp[-4].minor.yy454, unsafe { nil })
			}
		}
		u32(226) {
			p_src := sqlite3_src_list_append(p_parse, unsafe { nil }, &yymsp[-2].minor.yy0, &yymsp[-1].minor.yy0)
			p_select := sqlite3_select_new(p_parse, unsafe { nil }, p_src, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, u32(0), unsafe { nil })
			if yymsp[0].minor.yy14 {
				sqlite3_src_list_func_args(p_parse, unsafe { if p_select {
					p_src
				} else {
					&SrcList(nil)
				} }, yymsp[0].minor.yy14)
			}
			yymsp[-4].minor.yy454 = sqlite3_pe_xpr(p_parse, 50, yymsp[-4].minor.yy454, unsafe { nil })
			sqlite3_pe_xpr_add_select(p_parse, yymsp[-4].minor.yy454, p_select)
			if yymsp[-3].minor.yy144 {
				yymsp[-4].minor.yy454 = sqlite3_pe_xpr(p_parse, 19, yymsp[-4].minor.yy454, unsafe { nil })
			}
		}
		u32(227) {
			p := &Expr(0)
			yymsp[-3].minor.yy454 = sqlite3_pe_xpr(p_parse, 20, unsafe { nil }, unsafe { nil })
			p = yymsp[-3].minor.yy454
			sqlite3_pe_xpr_add_select(p_parse, p, yymsp[-1].minor.yy555)
		}
		u32(228) {
			yymsp[-4].minor.yy454 = sqlite3_pe_xpr(p_parse, 158, yymsp[-3].minor.yy454, unsafe { nil })
			if yymsp[-4].minor.yy454 {
				yymsp[-4].minor.yy454.x.pList = if yymsp[-1].minor.yy454 {
					sqlite3_expr_list_append(p_parse, yymsp[-2].minor.yy14, yymsp[-1].minor.yy454)
				} else {
					yymsp[-2].minor.yy14
				}
				sqlite3_expr_set_height_and_flags(p_parse, yymsp[-4].minor.yy454)
			} else {
				sqlite3_expr_list_delete(p_parse.db, yymsp[-2].minor.yy14)
				sqlite3_expr_delete(p_parse.db, yymsp[-1].minor.yy454)
			}
		}
		u32(229) {
			yymsp[-4].minor.yy14 = sqlite3_expr_list_append(p_parse, yymsp[-4].minor.yy14, yymsp[-2].minor.yy454)
			yymsp[-4].minor.yy14 = sqlite3_expr_list_append(p_parse, yymsp[-4].minor.yy14, yymsp[0].minor.yy454)
		}
		u32(230) {
			yymsp[-3].minor.yy14 = sqlite3_expr_list_append(p_parse, unsafe { nil }, yymsp[-2].minor.yy454)
			yymsp[-3].minor.yy14 = sqlite3_expr_list_append(p_parse, yymsp[-3].minor.yy14, yymsp[0].minor.yy454)
		}
		u32(235) {
			yymsp[-2].minor.yy14 = sqlite3_expr_list_append(p_parse, yymsp[-2].minor.yy14, yymsp[0].minor.yy454)
		}
		u32(236) {
			yymsp[0].minor.yy14 = sqlite3_expr_list_append(p_parse, unsafe { nil }, yymsp[0].minor.yy454)
		}
		u32(238), u32(243) {
			0
			yymsp[-2].minor.yy14 = yymsp[-1].minor.yy14
		}
		u32(239) {
			sqlite3_create_index(p_parse, &yymsp[-7].minor.yy0, &yymsp[-6].minor.yy0, sqlite3_src_list_append(p_parse, unsafe { nil }, &yymsp[-4].minor.yy0, unsafe { nil }), yymsp[-2].minor.yy14, yymsp[-10].minor.yy144, &yymsp[-11].minor.yy0, yymsp[0].minor.yy454, 0, yymsp[-8].minor.yy144, U8(0))
			if (int(p_parse.eParseMode) >= 2) && !isnil(p_parse.pNewIndex) {
				sqlite3_rename_token_map(p_parse, voidptr(p_parse.pNewIndex.zName), &yymsp[-4].minor.yy0)
			}
		}
		u32(240), u32(281) {
			0
			yymsp[0].minor.yy144 = 2
		}
		u32(241) {
			yymsp[1].minor.yy144 = 0
		}
		u32(244) {
			yymsp[-4].minor.yy14 = parser_add_expr_id_list_term(p_parse, yymsp[-4].minor.yy14, &yymsp[-2].minor.yy0, yymsp[-1].minor.yy144, yymsp[0].minor.yy144)
		}
		u32(245) {
			yymsp[-2].minor.yy14 = parser_add_expr_id_list_term(p_parse, unsafe { nil }, &yymsp[-2].minor.yy0, yymsp[-1].minor.yy144, yymsp[0].minor.yy144)
		}
		u32(248) {
			sqlite3_drop_index(p_parse, yymsp[0].minor.yy203, yymsp[-1].minor.yy144)
		}
		u32(249) {
			sqlite3_vacuum(p_parse, unsafe { nil }, yymsp[0].minor.yy454)
		}
		u32(250) {
			sqlite3_vacuum(p_parse, &yymsp[-1].minor.yy0, yymsp[0].minor.yy454)
		}
		u32(253) {
			sqlite3_pragma(p_parse, &yymsp[-1].minor.yy0, &yymsp[0].minor.yy0, unsafe { nil }, 0)
		}
		u32(254) {
			sqlite3_pragma(p_parse, &yymsp[-3].minor.yy0, &yymsp[-2].minor.yy0, &yymsp[0].minor.yy0, 0)
		}
		u32(255) {
			sqlite3_pragma(p_parse, &yymsp[-4].minor.yy0, &yymsp[-3].minor.yy0, &yymsp[-1].minor.yy0, 0)
		}
		u32(256) {
			sqlite3_pragma(p_parse, &yymsp[-3].minor.yy0, &yymsp[-2].minor.yy0, &yymsp[0].minor.yy0, 1)
		}
		u32(257) {
			sqlite3_pragma(p_parse, &yymsp[-4].minor.yy0, &yymsp[-3].minor.yy0, &yymsp[-1].minor.yy0, 1)
		}
		u32(260) {
			all := Token{}
			all.z = yymsp[-3].minor.yy0.z
			all.n = u32(int((i64((isize(yymsp[0].minor.yy0.z) - isize(yymsp[-3].minor.yy0.z)) / isize(sizeof(i8)))))) + yymsp[0].minor.yy0.n
			sqlite3_finish_trigger(p_parse, yymsp[-1].minor.yy427, &all)
		}
		u32(261) {
			sqlite3_begin_trigger(p_parse, &yymsp[-7].minor.yy0, &yymsp[-6].minor.yy0, yymsp[-5].minor.yy144, yymsp[-4].minor.yy286.a, yymsp[-4].minor.yy286.b, yymsp[-2].minor.yy203, yymsp[0].minor.yy454, yymsp[-10].minor.yy144, yymsp[-8].minor.yy144)
			yymsp[-10].minor.yy0 = (if yymsp[-6].minor.yy0.n == u32(0) {
				yymsp[-7].minor.yy0
			} else {
				yymsp[-6].minor.yy0
			})
		}
		u32(262) {
			yymsp[0].minor.yy144 = int(yymsp[0].major)
		}
		u32(263) {
			yymsp[-1].minor.yy144 = 66
		}
		u32(264) {
			yymsp[1].minor.yy144 = 33
		}
		u32(265), u32(266) {
			0
			yymsp[0].minor.yy286.a = int(yymsp[0].major)
			yymsp[0].minor.yy286.b = 0
		}
		u32(267) {
			yymsp[-2].minor.yy286.a = 130
			yymsp[-2].minor.yy286.b = yymsp[0].minor.yy132
		}
		u32(268), u32(286) {
			0
			yymsp[1].minor.yy454 = 0
		}
		u32(269), u32(287) {
			0
			yymsp[-1].minor.yy454 = yymsp[0].minor.yy454
		}
		u32(270) {
			yymsp[-2].minor.yy427.pLast.pNext = yymsp[-1].minor.yy427
			yymsp[-2].minor.yy427.pLast = yymsp[-1].minor.yy427
		}
		u32(271) {
			yymsp[-1].minor.yy427.pLast = yymsp[-1].minor.yy427
		}
		u32(272) {
			sqlite3_error_msg(p_parse, c'the INDEXED BY clause is not allowed on UPDATE or DELETE statements within triggers')
		}
		u32(273) {
			sqlite3_error_msg(p_parse, c'the NOT INDEXED clause is not allowed on UPDATE or DELETE statements within triggers')
		}
		u32(274) {
			yylhsminor.yy427 = sqlite3_trigger_update_step(p_parse, yymsp[-6].minor.yy203, yymsp[-2].minor.yy203, yymsp[-3].minor.yy14, yymsp[-1].minor.yy454, U8(yymsp[-7].minor.yy144), yymsp[-8].minor.yy0.z, yymsp[0].minor.yy168)
			yymsp[-8].minor.yy427 = yylhsminor.yy427
		}
		u32(275) {
			yylhsminor.yy427 = sqlite3_trigger_insert_step(p_parse, yymsp[-4].minor.yy203, yymsp[-3].minor.yy132, yymsp[-2].minor.yy555, U8(yymsp[-6].minor.yy144), yymsp[-1].minor.yy122, yymsp[-7].minor.yy168, yymsp[0].minor.yy168)
			yymsp[-7].minor.yy427 = yylhsminor.yy427
		}
		u32(276) {
			yylhsminor.yy427 = sqlite3_trigger_delete_step(p_parse, yymsp[-3].minor.yy203, yymsp[-1].minor.yy454, yymsp[-5].minor.yy0.z, yymsp[0].minor.yy168)
			yymsp[-5].minor.yy427 = yylhsminor.yy427
		}
		u32(277) {
			yylhsminor.yy427 = sqlite3_trigger_select_step(p_parse.db, yymsp[-1].minor.yy555, yymsp[-2].minor.yy168, yymsp[0].minor.yy168)
			yymsp[-2].minor.yy427 = yylhsminor.yy427
		}
		u32(278) {
			yymsp[-3].minor.yy454 = sqlite3_pe_xpr(p_parse, 72, unsafe { nil }, unsafe { nil })
			if yymsp[-3].minor.yy454 {
				yymsp[-3].minor.yy454.affExpr = i8(4)
			}
		}
		u32(279) {
			yymsp[-5].minor.yy454 = sqlite3_pe_xpr(p_parse, 72, yymsp[-1].minor.yy454, unsafe { nil })
			if yymsp[-5].minor.yy454 {
				yymsp[-5].minor.yy454.affExpr = i8(yymsp[-3].minor.yy144)
			}
		}
		u32(280) {
			yymsp[0].minor.yy144 = 1
		}
		u32(282) {
			yymsp[0].minor.yy144 = 3
		}
		u32(283) {
			sqlite3_drop_trigger(p_parse, yymsp[0].minor.yy203, yymsp[-1].minor.yy144)
		}
		u32(284) {
			sqlite3_attach(p_parse, yymsp[-3].minor.yy454, yymsp[-1].minor.yy454, yymsp[0].minor.yy454)
		}
		u32(285) {
			sqlite3_detach(p_parse, yymsp[0].minor.yy454)
		}
		u32(288) {
			sqlite3_reindex(p_parse, unsafe { nil }, unsafe { nil })
		}
		u32(289) {
			sqlite3_reindex(p_parse, &yymsp[-1].minor.yy0, &yymsp[0].minor.yy0)
		}
		u32(290) {
			sqlite3_analyze(p_parse, unsafe { nil }, unsafe { nil })
		}
		u32(291) {
			sqlite3_analyze(p_parse, &yymsp[-1].minor.yy0, &yymsp[0].minor.yy0)
		}
		u32(292) {
			sqlite3_alter_rename_table(p_parse, yymsp[-3].minor.yy203, &yymsp[0].minor.yy0)
		}
		u32(293) {
			yymsp[-1].minor.yy0.n = u32(int((i64((isize(p_parse.sLastToken.z) - isize(yymsp[-1].minor.yy0.z)) / isize(sizeof(i8)))))) + p_parse.sLastToken.n
			sqlite3_alter_finish_add_column(p_parse, &yymsp[-1].minor.yy0)
		}
		u32(294) {
			disable_lookaside(p_parse)
			sqlite3_alter_begin_add_column(p_parse, yymsp[-4].minor.yy203)
			sqlite3_add_column(p_parse, yymsp[-1].minor.yy0, yymsp[0].minor.yy0)
			yymsp[-6].minor.yy0 = yymsp[-1].minor.yy0
		}
		u32(295) {
			sqlite3_alter_drop_column(p_parse, yymsp[-3].minor.yy203, &yymsp[0].minor.yy0)
		}
		u32(296) {
			sqlite3_alter_rename_column(p_parse, yymsp[-5].minor.yy203, &yymsp[-2].minor.yy0, &yymsp[0].minor.yy0)
		}
		u32(297) {
			sqlite3_alter_drop_constraint(p_parse, yymsp[-3].minor.yy203, &yymsp[0].minor.yy0, unsafe { nil })
		}
		u32(298) {
			sqlite3_alter_drop_constraint(p_parse, yymsp[-6].minor.yy203, unsafe { nil }, &yymsp[-3].minor.yy0)
		}
		u32(299) {
			sqlite3_alter_set_not_null(p_parse, yymsp[-7].minor.yy203, &yymsp[-4].minor.yy0, &yymsp[-2].minor.yy0)
		}
		u32(300) {
			sqlite3_alter_add_constraint(p_parse, yymsp[-8].minor.yy203, &yymsp[-6].minor.yy0, &yymsp[-5].minor.yy0, yymsp[-3].minor.yy0.z + 1, int((i64((isize(yymsp[-1].minor.yy0.z) - isize(yymsp[-3].minor.yy0.z)) / isize(sizeof(i8))) - i64(1))), yymsp[-2].minor.yy454)
		}
		u32(301) {
			sqlite3_alter_add_constraint(p_parse, yymsp[-6].minor.yy203, &yymsp[-4].minor.yy0, unsafe { nil }, yymsp[-3].minor.yy0.z + 1, int((i64((isize(yymsp[-1].minor.yy0.z) - isize(yymsp[-3].minor.yy0.z)) / isize(sizeof(i8))) - i64(1))), yymsp[-2].minor.yy454)
		}
		u32(302) {
			sqlite3_vtab_finish_parse(p_parse, unsafe { nil })
		}
		u32(303) {
			sqlite3_vtab_finish_parse(p_parse, &yymsp[0].minor.yy0)
		}
		u32(304) {
			sqlite3_vtab_begin_parse(p_parse, &yymsp[-3].minor.yy0, &yymsp[-2].minor.yy0, &yymsp[0].minor.yy0, yymsp[-4].minor.yy144)
		}
		u32(305) {
			sqlite3_vtab_arg_init(p_parse)
		}
		u32(306), u32(307) {
			0
			unsafe { goto c2v_case_69_576
			 }
		}
		u32(308) {
			c2v_case_69_576:
			0
			sqlite3_vtab_arg_extend(p_parse, &yymsp[0].minor.yy0)
		}
		u32(309), u32(310) {
			0
			sqlite3_with_push(p_parse, yymsp[0].minor.yy59, U8(1))
		}
		u32(311) {
			yymsp[0].minor.yy462 = U8(1)
		}
		u32(312) {
			yymsp[-1].minor.yy462 = U8(0)
		}
		u32(313) {
			yymsp[-2].minor.yy462 = U8(2)
		}
		u32(314) {
			yymsp[-5].minor.yy67 = sqlite3_cte_new(p_parse, &yymsp[-5].minor.yy0, yymsp[-4].minor.yy14, yymsp[-1].minor.yy555, yymsp[-3].minor.yy462)
		}
		u32(315) {
			p_parse.bHasWith = Bft(1)
		}
		u32(316) {
			yymsp[0].minor.yy59 = sqlite3_with_add(p_parse, unsafe { nil }, yymsp[0].minor.yy67)
		}
		u32(317) {
			yymsp[-2].minor.yy59 = sqlite3_with_add(p_parse, yymsp[-2].minor.yy59, yymsp[0].minor.yy67)
		}
		u32(318) {
			sqlite3_window_chain(p_parse, yymsp[0].minor.yy211, yymsp[-2].minor.yy211)
			yymsp[0].minor.yy211.pNextWin = yymsp[-2].minor.yy211
			yylhsminor.yy211 = yymsp[0].minor.yy211
			yymsp[-2].minor.yy211 = yylhsminor.yy211
		}
		u32(319) {
			if yymsp[-1].minor.yy211 {
				yymsp[-1].minor.yy211.zName = sqlite3_db_str_nd_up(p_parse.db, yymsp[-4].minor.yy0.z, U64(yymsp[-4].minor.yy0.n))
			}
			yylhsminor.yy211 = yymsp[-1].minor.yy211
			yymsp[-4].minor.yy211 = yylhsminor.yy211
		}
		u32(320) {
			yymsp[-4].minor.yy211 = sqlite3_window_assemble(p_parse, yymsp[0].minor.yy211, yymsp[-2].minor.yy14, yymsp[-1].minor.yy14, unsafe { nil })
		}
		u32(321) {
			yylhsminor.yy211 = sqlite3_window_assemble(p_parse, yymsp[0].minor.yy211, yymsp[-2].minor.yy14, yymsp[-1].minor.yy14, &yymsp[-5].minor.yy0)
			yymsp[-5].minor.yy211 = yylhsminor.yy211
		}
		u32(322) {
			yymsp[-3].minor.yy211 = sqlite3_window_assemble(p_parse, yymsp[0].minor.yy211, unsafe { nil }, yymsp[-1].minor.yy14, unsafe { nil })
		}
		u32(323) {
			yylhsminor.yy211 = sqlite3_window_assemble(p_parse, yymsp[0].minor.yy211, unsafe { nil }, yymsp[-1].minor.yy14, &yymsp[-4].minor.yy0)
			yymsp[-4].minor.yy211 = yylhsminor.yy211
		}
		u32(324) {
			yylhsminor.yy211 = sqlite3_window_assemble(p_parse, yymsp[0].minor.yy211, unsafe { nil }, unsafe { nil }, &yymsp[-1].minor.yy0)
			yymsp[-1].minor.yy211 = yylhsminor.yy211
		}
		u32(325) {
			yymsp[1].minor.yy211 = sqlite3_window_alloc(p_parse, 0, 91, unsafe { nil }, 86, unsafe { nil }, U8(0))
		}
		u32(326) {
			yylhsminor.yy211 = sqlite3_window_alloc(p_parse, yymsp[-2].minor.yy144, yymsp[-1].minor.yy509.eType, yymsp[-1].minor.yy509.pExpr, 86, unsafe { nil }, yymsp[0].minor.yy462)
			yymsp[-2].minor.yy211 = yylhsminor.yy211
		}
		u32(327) {
			yylhsminor.yy211 = sqlite3_window_alloc(p_parse, yymsp[-5].minor.yy144, yymsp[-3].minor.yy509.eType, yymsp[-3].minor.yy509.pExpr, yymsp[-1].minor.yy509.eType, yymsp[-1].minor.yy509.pExpr, yymsp[0].minor.yy462)
			yymsp[-5].minor.yy211 = yylhsminor.yy211
		}
		u32(329), u32(331) {
			0
			yylhsminor.yy509 = yymsp[0].minor.yy509
			yymsp[0].minor.yy509 = yylhsminor.yy509
		}
		u32(330), u32(332) {
			0
			unsafe { goto c2v_case_69_628
			 }
		}
		u32(334) {
			c2v_case_69_628:
			0
			yylhsminor.yy509.eType = int(yymsp[-1].major)
			yylhsminor.yy509.pExpr = 0
			yymsp[-1].minor.yy509 = yylhsminor.yy509
		}
		u32(333) {
			yylhsminor.yy509.eType = int(yymsp[0].major)
			yylhsminor.yy509.pExpr = yymsp[-1].minor.yy454
			yymsp[-1].minor.yy509 = yylhsminor.yy509
		}
		u32(335) {
			yymsp[1].minor.yy462 = U8(0)
		}
		u32(336) {
			yymsp[-1].minor.yy462 = yymsp[0].minor.yy462
		}
		u32(337), u32(338) {
			0
			yymsp[-1].minor.yy462 = U8(yymsp[-1].major)
		}
		u32(339) {
			yymsp[0].minor.yy462 = U8(yymsp[0].major)
		}
		u32(340) {
			yymsp[-1].minor.yy211 = yymsp[0].minor.yy211
		}
		u32(341) {
			if yymsp[0].minor.yy211 {
				yymsp[0].minor.yy211.pFilter = yymsp[-1].minor.yy454
			} else {
				sqlite3_expr_delete(p_parse.db, yymsp[-1].minor.yy454)
			}
			yylhsminor.yy211 = yymsp[0].minor.yy211
			yymsp[-1].minor.yy211 = yylhsminor.yy211
		}
		u32(342) {
			yylhsminor.yy211 = yymsp[0].minor.yy211
			yymsp[0].minor.yy211 = yylhsminor.yy211
		}
		u32(343) {
			yylhsminor.yy211 = &Window(sqlite3_db_malloc_zero(p_parse.db, U64(sizeof(Window))))
			if yylhsminor.yy211 {
				yylhsminor.yy211.eFrmType = U8(167)
				yylhsminor.yy211.pFilter = yymsp[0].minor.yy454
			} else {
				sqlite3_expr_delete(p_parse.db, yymsp[0].minor.yy454)
			}
			yymsp[0].minor.yy211 = yylhsminor.yy211
		}
		u32(344) {
			yymsp[-3].minor.yy211 = yymsp[-1].minor.yy211
		}
		u32(345) {
			yymsp[-1].minor.yy211 = &Window(sqlite3_db_malloc_zero(p_parse.db, U64(sizeof(Window))))
			if yymsp[-1].minor.yy211 {
				yymsp[-1].minor.yy211.zName = sqlite3_db_str_nd_up(p_parse.db, yymsp[0].minor.yy0.z, U64(yymsp[0].minor.yy0.n))
			}
		}
		u32(346) {
			yymsp[-4].minor.yy454 = yymsp[-1].minor.yy454
		}
		u32(347) {
			yylhsminor.yy454 = token_expr(p_parse, int(yymsp[0].major), yymsp[0].minor.yy0)
			sqlite3_dequote_number(p_parse, yylhsminor.yy454)
			yymsp[0].minor.yy454 = yylhsminor.yy454
		}
		else {
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
			0
		}
	}

	0
	yygoto = int(yy_rule_info_lhs[yyruleno])
	yysize = int(yy_rule_info_nr_hs[yyruleno])
	yyact = yy_find_reduce_action(yymsp[yysize].stateno, u16(yygoto))
	c2v_pointer_prefix(voidptr(&yymsp), yymsp, isize(yysize + 1))
	yyp_parser.yytos = yymsp
	yymsp.stateno = u16(yyact)
	yymsp.major = u16(yygoto)
	0
	return yyact
}

fn yy_syntax_error(yyp_parser &YyParser, yymajor int, yyminor Token) {
	p_parse := yyp_parser.pParse

	if yyminor.z[0] {
		parser_syntax_error(p_parse, &yyminor)
	} else {
		sqlite3_error_msg(p_parse, c'incomplete input')
	}
	yyp_parser.pParse = p_parse
}

fn yy_accept(yyp_parser &YyParser) {
	p_parse := yyp_parser.pParse
	yyp_parser.pParse = p_parse
}

@[c:'sqlite3Parser']
fn sqlite3_parser(yyp voidptr, yymajor int, yyminor Token) {
	yyminorunion := YYMINORTYPE{}
	yyact := u16(0)
	yyp_parser := &YyParser(yyp)
	p_parse := yyp_parser.pParse
	yyact = yyp_parser.yytos.stateno
	for {
		yyact = yy_find_shift_action(u16(yymajor), yyact)
		if int(yyact) >= 1282 {
			yyruleno := u32(int(yyact) - 1282)
			if int(yy_rule_info_nr_hs[yyruleno]) == 0 {
				if usize(yyp_parser.yytos) >= usize(yyp_parser.yystackEnd) {
					if yy_grow_stack(yyp_parser) {
						yy_stack_overflow(yyp_parser)
						break
					}
				}
			}
			yyact = yy_reduce(yyp_parser, yyruleno, yymajor, yyminor, p_parse)
		} else if int(yyact) <= 1278 {
			yy_shift(yyp_parser, yyact, u16(yymajor), yyminor)
			break
		} else if int(yyact) == 1280 {
			c2v_pointer_postfix(voidptr(&yyp_parser.yytos), yyp_parser.yytos, isize(-1))
			yy_accept(yyp_parser)
			return
		} else {
			yyminorunion.yy0 = yyminor
			yy_syntax_error(yyp_parser, yymajor, yyminor)
			yy_destructor(yyp_parser, u16(yymajor), &yyminorunion)
			break
		}
	}
	return
}

@[c:'sqlite3ParserFallback']
fn sqlite3_parser_fallback(i_token int) int {
	return int(yy_fallback[i_token])
}
