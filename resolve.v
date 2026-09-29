@[translated]
module main

@[c:'incrAggDepth']
fn incr_agg_depth(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	if int(p_expr.op) == 169 {
		p_expr.op2 += p_walker.u.n
	}
	return 0
}

@[c:'incrAggFunctionDepth']
fn incr_agg_function_depth(p_expr &Expr, n int) {
	if n > 0 {
		w := Walker{}
		C.memset(voidptr(&w), 0, sizeof(w))
		w.xExprCallback = incr_agg_depth
		w.u.n = n
		sqlite3_walk_expr(&w, p_expr)
	}
}

@[c:'resolveAlias']
fn resolve_alias(p_parse &Parse, pel_ist &ExprList, i_col int, p_expr &Expr, n_subquery int) {
	p_orig := &Expr(0)
	p_dup := &Expr(0)
	db := &Sqlite3(0)
	p_orig = c2v_at(&pel_ist.a[0], isize(i_col)).pExpr
	if p_expr.pAggInfo {
		return
	}
	db = p_parse.db
	p_dup = sqlite3_expr_dup(db, p_orig, 0)
	if db.mallocFailed {
		sqlite3_expr_delete(db, p_dup)
		p_dup = 0
	} else {
		temp := Expr{}
		incr_agg_function_depth(p_dup, n_subquery)
		if int(p_expr.op) == 114 {
			p_dup = sqlite3_expr_add_collate_string(p_parse, p_dup, p_expr.u.zToken)
		}
		C.memcpy(voidptr(&temp), voidptr(p_dup), sizeof(Expr))
		C.memcpy(voidptr(p_dup), voidptr(p_expr), sizeof(Expr))
		C.memcpy(voidptr(p_expr), voidptr(&temp), sizeof(Expr))
		if ((p_expr.flags & u32(16777216)) != u32(0)) {
			if (usize(p_expr.y.pWin) != usize(0)) {
				p_expr.y.pWin.pOwner = p_expr
			}
		}
		sqlite3_expr_deferred_delete(p_parse, p_dup)
	}
}

@[c:'sqlite3MatchEName']
fn sqlite3_match_en_ame(p_item &ExprList_item, z_col &i8, z_tab &i8, z_db &i8, pb_rowid &int) int {
	n := 0
	z_span := &i8(0)
	een_ame := int(p_item.fg.eEName)
	if een_ame != 2 && (een_ame != 3 || (usize(pb_rowid) == usize(0))) {
		return 0
	}
	z_span = p_item.zEName
	for n = 0; int(z_span[n]) && int(z_span[n]) != i8(`.`); n++ {
	}
	if !isnil(z_db) && (sqlite3_strnicmp(z_span, z_db, n) != 0 || int(z_db[n]) != 0) {
		return 0
	}
	c2v_pointer_prefix(voidptr(&z_span), z_span, isize(n + 1))
	for n = 0; int(z_span[n]) && int(z_span[n]) != i8(`.`); n++ {
	}
	if !isnil(z_tab) && (sqlite3_strnicmp(z_span, z_tab, n) != 0 || int(z_tab[n]) != 0) {
		return 0
	}
	c2v_pointer_prefix(voidptr(&z_span), z_span, isize(n + 1))
	if z_col {
		if een_ame == 2 && sqlite3_str_ic_mp(z_span, z_col) != 0 {
			return 0
		}
		if een_ame == 3 && sqlite3_is_rowid(z_col) == 0 {
			return 0
		}
	}
	if een_ame == 3 {
		unsafe { *pb_rowid = 1 }
	}
	return 1
}

@[c:'areDoubleQuotedStringsEnabled']
fn are_double_quoted_strings_enabled(db &Sqlite3, p_top_nc &NameContext) int {
	if db.init.busy {
		return 1
	}
	if p_top_nc.ncFlags & 65536 {
		if sqlite3_writable_schema(db) && (db.flags & U64(1073741824)) != U64(0) {
			return 1
		}
		return int((db.flags & U64(536870912)) != U64(0))
	} else {
		return int((db.flags & U64(1073741824)) != U64(0))
	}
}

@[c:'sqlite3ExprColUsed']
fn sqlite3_expr_col_used(p_expr &Expr) Bitmask {
	n := 0
	p_ex_tab := &Table(0)
	n = int(p_expr.iColumn)
	p_ex_tab = p_expr.y.pTab
	if (p_ex_tab.tabFlags & u32(96)) != u32(0) && (int(p_ex_tab.aCol[n].colFlags) & 96) != 0 {
		return if int(p_ex_tab.nCol) >= (int((sizeof(Bitmask) * u64(8)))) {
			(Bitmask(-1))
		} else {
			((Bitmask(1)) << int(p_ex_tab.nCol)) - Bitmask(1)
		}
	} else {
		if n >= (int((sizeof(Bitmask) * u64(8)))) {
			n = (int((sizeof(Bitmask) * u64(8)))) - 1
		}
		return (Bitmask(1)) << n
	}
}

@[c:'extendFJMatch']
fn extend_fj_match(p_parse &Parse, pp_list &&ExprList, p_match &SrcItem, i_column I16) {
	p_new := sqlite3_expr_alloc(p_parse.db, 168, unsafe { nil }, 0)
	if p_new {
		p_new.iTable = p_match.iCursor
		p_new.iColumn = i_column
		p_new.y.pTab = p_match.pSTab
		p_new.flags |= u32(2097152)
		unsafe { *pp_list = sqlite3_expr_list_append(p_parse, *pp_list, p_new) }
	}
}

@[c:'isValidSchemaTableName']
fn is_valid_schema_table_name(z_tab &i8, p_tab &Table, z_db &i8) int {
	z_legacy := &i8(0)
	if sqlite3_strnicmp(z_tab, c'sqlite_', 7) != 0 {
		return 0
	}
	z_legacy = p_tab.zName
	if C.strcmp(z_legacy + 7, unsafe { c'sqlite_temp_master' + 7 }) == 0 {
		if sqlite3_str_ic_mp(z_tab + 7, unsafe { c'sqlite_temp_schema' + 7 }) == 0 {
			return 1
		}
		if usize(z_db) == usize(0) {
			return 0
		}
		if sqlite3_str_ic_mp(z_tab + 7, unsafe { c'sqlite_master' + 7 }) == 0 {
			return 1
		}
		if sqlite3_str_ic_mp(z_tab + 7, unsafe { c'sqlite_schema' + 7 }) == 0 {
			return 1
		}
	} else {
		if sqlite3_str_ic_mp(z_tab + 7, unsafe { c'sqlite_schema' + 7 }) == 0 {
			return 1
		}
	}
	return 0
}

@[c:'lookupName']
fn lookup_name(p_parse &Parse, z_db &i8, z_tab &i8, p_right &Expr, pnc &NameContext, p_expr &Expr) int {
	i := 0
	j := 0

	cnt := 0
	cnt_tab := 0
	n_subquery := 0
	db := p_parse.db
	p_item := &SrcItem(0)
	p_match := unsafe { &SrcItem(nil) }
	p_top_nc := pnc
	p_schema := unsafe { &Schema(nil) }
	e_new_expr_op := 168
	p_tab := unsafe { &Table(nil) }
	pfj_match := unsafe { &ExprList(nil) }
	z_col := p_right.u.zToken
	p_expr.iTable = -1
	if z_db {
		if (pnc.ncFlags & (2 | 4)) != 0 {
			z_db = 0
		} else {
			for i = 0; i < db.nDb; i++ {
				if sqlite3_str_ic_mp(db.aDb[i].zDbSName, z_db) == 0 {
					p_schema = db.aDb[i].pSchema
					break
				}
			}
			if i == db.nDb && sqlite3_str_ic_mp(c'main', z_db) == 0 {
				p_schema = db.aDb[0].pSchema
				z_db = db.aDb[0].zDbSName
			}
		}
	}
	for {
		pel_ist := &ExprList(0)
		p_src_list := pnc.pSrcList
		if p_src_list {
			i = 0
			for p_item = unsafe { &p_src_list.a[0] }; i < p_src_list.nSrc; i++ {
				p_tab = p_item.pSTab
				if p_item.fg.isNestedFrom {
					hit := 0
					p_sel := &Select(0)
					p_sel = p_item.u4.pSubq.pSelect
					pel_ist = p_sel.pEList
					for j = 0; j < pel_ist.nExpr; j++ {
						b_rowid := 0
						if !sqlite3_match_en_ame(unsafe { &pel_ist.a[0] + j }, z_col, z_tab, z_db, &b_rowid) {
							continue
						}
						if b_rowid == 0 {
							if cnt > 0 {
								if int(p_item.fg.isUsing) == 0 || sqlite3_id_list_index(p_item.u3.pUsing, z_col) < 0 || usize(p_match) == usize(p_item) {
									sqlite3_expr_list_delete(db, pfj_match)
									pfj_match = 0
								} else if (int(p_item.fg.jointype) & 16) == 0 {
									continue
								} else if (int(p_item.fg.jointype) & 8) == 0 {
									cnt = 0
									sqlite3_expr_list_delete(db, pfj_match)
									pfj_match = 0
								} else {
									extend_fj_match(p_parse, &&ExprList(&&ExprList(c2v_address_of(&pfj_match))), p_match, p_expr.iColumn)
								}
							}
							cnt++
							hit = 1
						} else if cnt > 0 {
							continue
						}
						cnt_tab++
						p_match = p_item
						p_expr.iColumn = YnVar(j)
						mut __c2v_lhs_tmp_89 := c2v_at(&pel_ist.a[0], isize(j))
						__c2v_lhs_tmp_89.fg.bUsed = u32(1)
						if c2v_at(&pel_ist.a[0], isize(j)).fg.bUsingTerm {
							break
						}
					}
					if hit || usize(z_tab) == usize(0) {
						unsafe { goto c2v_for_next_75
						 }
					}
				}
				if z_tab {
					if z_db {
						if usize(p_tab.pSchema) != usize(p_schema) {
							unsafe { goto c2v_for_next_75
							 }
						}
						if usize(p_schema) == usize(0) && C.strcmp(z_db, c'*') != 0 {
							unsafe { goto c2v_for_next_75
							 }
						}
					}
					if usize(p_item.zAlias) != usize(0) {
						if sqlite3_str_ic_mp(z_tab, p_item.zAlias) != 0 {
							unsafe { goto c2v_for_next_75
							 }
						}
					} else if sqlite3_str_ic_mp(z_tab, p_tab.zName) != 0 {
						if p_tab.tnum != Pgno(1) {
							unsafe { goto c2v_for_next_75
							 }
						}
						if !is_valid_schema_table_name(z_tab, p_tab, z_db) {
							unsafe { goto c2v_for_next_75
							 }
						}
					}
					if (int(p_parse.eParseMode) >= 2) && !isnil(p_item.zAlias) {
						sqlite3_rename_token_remap(p_parse, unsafe { nil }, voidptr(&p_expr.y.pTab))
					}
				}
				j = sqlite3_column_index(p_tab, z_col)
				if j >= 0 {
					if cnt > 0 {
						if int(p_item.fg.isUsing) == 0 || sqlite3_id_list_index(p_item.u3.pUsing, z_col) < 0 {
							sqlite3_expr_list_delete(db, pfj_match)
							pfj_match = 0
						} else if (int(p_item.fg.jointype) & 16) == 0 {
							unsafe { goto c2v_for_next_75
							 }
						} else if (int(p_item.fg.jointype) & 8) == 0 {
							cnt = 0
							sqlite3_expr_list_delete(db, pfj_match)
							pfj_match = 0
						} else {
							extend_fj_match(p_parse, &&ExprList(&&ExprList(c2v_address_of(&pfj_match))), p_match, p_expr.iColumn)
						}
					}
					cnt++
					p_match = p_item
					p_expr.iColumn = YnVar(if j == int(p_tab.iPKey) { -1 } else { int(I16(j)) })
					if p_item.fg.isNestedFrom {
						sqlite3_src_item_column_used(p_item, j)
					}
				}
				if 0 == cnt && ((p_tab.tabFlags & u32(512)) == u32(0)) {
					cnt_tab++
					p_match = p_item
				}
				c2v_for_next_75:
				c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
			}
			if p_match {
				p_expr.iTable = p_match.iCursor
				p_expr.y.pTab = p_match.pSTab
				if (int(p_match.fg.jointype) & (8 | 64)) != 0 {
					p_expr.flags |= u32(2097152)
				}
				p_schema = p_expr.y.pTab.pSchema
			}
		}
		if cnt == 0 && usize(z_db) == usize(0) {
			p_tab = 0
			if usize(p_parse.pTriggerTab) != usize(0) {
				op := int(p_parse.eTriggerOp)
				if p_parse.bReturning {
					if (pnc.ncFlags & 1024) != 0 && (usize(z_tab) == usize(0) || sqlite3_str_ic_mp(z_tab, p_parse.pTriggerTab.zName) == 0 || is_valid_schema_table_name(z_tab, p_parse.pTriggerTab, unsafe { nil })) {
						p_expr.iTable = op != 129
						p_tab = p_parse.pTriggerTab
					}
				} else if op != 129 && !isnil(z_tab) && sqlite3_str_ic_mp(c'new', z_tab) == 0 {
					p_expr.iTable = 1
					p_tab = p_parse.pTriggerTab
				} else if op != 128 && !isnil(z_tab) && sqlite3_str_ic_mp(c'old', z_tab) == 0 {
					p_expr.iTable = 0
					p_tab = p_parse.pTriggerTab
				}
			}
			if (pnc.ncFlags & 512) != 0 && usize(z_tab) != usize(0) {
				p_upsert := pnc.uNC.pUpsert
				if !isnil(p_upsert) && sqlite3_str_ic_mp(c'excluded', z_tab) == 0 {
					p_tab = c2v_at(&p_upsert.pUpsertSrc.a[0], isize(0)).pSTab
					p_expr.iTable = 2
				}
			}
			if p_tab {
				i_col := 0
				p_schema = p_tab.pSchema
				cnt_tab++
				i_col = sqlite3_column_index(p_tab, z_col)
				if i_col >= 0 {
					if int(p_tab.iPKey) == i_col {
						i_col = -1
					}
				} else {
					if sqlite3_is_rowid(z_col) && ((p_tab.tabFlags & u32(512)) == u32(0)) {
						i_col = -1
					} else {
						i_col = int(p_tab.nCol)
					}
				}
				if i_col < int(p_tab.nCol) {
					cnt++
					p_match = 0
					if p_expr.iTable == 2 {
						if (int(p_parse.eParseMode) >= 2) {
							p_expr.iColumn = YnVar(i_col)
							p_expr.y.pTab = p_tab
							e_new_expr_op = 168
						} else {
							p_expr.iTable = pnc.uNC.pUpsert.regData + int(sqlite3_table_column_to_storage(p_tab, I16(i_col)))
							e_new_expr_op = 176
						}
					} else {
						p_expr.y.pTab = p_tab
						if p_parse.bReturning {
							e_new_expr_op = 176
							p_expr.op2 = U8(168)
							p_expr.iColumn = YnVar(i_col)
							p_expr.iTable = pnc.uNC.iBaseReg + (int(p_tab.nCol) + 1) * p_expr.iTable + int(sqlite3_table_column_to_storage(p_tab, I16(i_col))) + 1
						} else {
							p_expr.iColumn = I16(i_col)
							e_new_expr_op = 78
							if i_col < 0 {
								p_expr.affExpr = i8(68)
							} else if p_expr.iTable == 0 {
								p_parse.oldmask |= (if i_col >= 32 {
									u32(4294967295)
								} else {
									((u32(1)) << i_col)
								})
							} else {
								p_parse.newmask |= (if i_col >= 32 {
									u32(4294967295)
								} else {
									((u32(1)) << i_col)
								})
							}
						}
					}
				}
			}
		}
		if cnt == 0 && cnt_tab >= 1 && !isnil(p_match) && (pnc.ncFlags & (32 | 8)) == 0 && sqlite3_is_rowid(z_col) && (((p_match.pSTab.tabFlags & u32(512)) == u32(0)) || int(p_match.fg.isNestedFrom)) {
			cnt = cnt_tab
			if int(p_match.fg.isNestedFrom) == 0 {
				p_expr.iColumn = YnVar(-1)
			}
			p_expr.affExpr = i8(68)
		}
		if cnt == 0 && (pnc.ncFlags & 128) != 0 && usize(z_tab) == usize(0) {
			pel_ist = pnc.uNC.pEList
			for j = 0; j < pel_ist.nExpr; j++ {
				z_as := c2v_at(&pel_ist.a[0], isize(j)).zEName
				if int(c2v_at(&pel_ist.a[0], isize(j)).fg.eEName) == 0 && sqlite3_stricmp(z_as, z_col) == 0 {
					p_orig := &Expr(0)
					p_orig = c2v_at(&pel_ist.a[0], isize(j)).pExpr
					if (pnc.ncFlags & 1) == 0 && ((p_orig.flags & u32(16)) != u32(0)) {
						sqlite3_error_msg(p_parse, c'misuse of aliased aggregate %s', voidptr(z_as))
						return 2
					}
					if ((p_orig.flags & u32(32768)) != u32(0)) && ((pnc.ncFlags & 16384) == 0 || usize(pnc) != usize(p_top_nc)) {
						sqlite3_error_msg(p_parse, c'misuse of aliased window function %s', voidptr(z_as))
						return 2
					}
					if sqlite3_expr_vector_size(p_orig) != 1 {
						sqlite3_error_msg(p_parse, c'row value misused')
						return 2
					}
					resolve_alias(p_parse, pel_ist, j, p_expr, n_subquery)
					cnt = 1
					p_match = 0
					if (int(p_parse.eParseMode) >= 2) {
						sqlite3_rename_token_remap(p_parse, unsafe { nil }, voidptr(p_expr))
					}
					unsafe { goto lookupname_end
					 }
				}
			}
		}
		if cnt {
			break
		}
		pnc = pnc.pNext
		n_subquery++
		if !pnc {
			break
		}
	}
	if cnt == 0 && usize(z_tab) == usize(0) {
		if ((p_expr.flags & u32(128)) != u32(0)) && are_double_quoted_strings_enabled(db, p_top_nc) {
			sqlite3_log(28, c'double-quoted string literal: "%w"', voidptr(z_col))
			p_expr.op = U8(118)
			C.memset(voidptr(&p_expr.y), 0, sizeof(Expr_y))
			return 1
		}
		if sqlite3_expr_id_to_truefalse(p_expr) {
			return 1
		}
	}
	if cnt != 1 {
		z_err := &i8(0)
		if pfj_match {
			if pfj_match.nExpr == cnt - 1 {
				if ((p_expr.flags & u32(8388608)) != u32(0)) {
					p_expr.flags &= ~u32(8388608)
				} else {
					sqlite3_expr_delete(db, p_expr.pLeft)
					p_expr.pLeft = 0
					sqlite3_expr_delete(db, p_expr.pRight)
					p_expr.pRight = 0
				}
				extend_fj_match(p_parse, &&ExprList(&&ExprList(c2v_address_of(&pfj_match))), p_match, p_expr.iColumn)
				p_expr.op = U8(172)
				p_expr.u.zToken = c'coalesce'
				p_expr.x.pList = pfj_match
				p_expr.affExpr = i8(88)
				cnt = 1
				unsafe { goto lookupname_end
				 }
			} else {
				sqlite3_expr_list_delete(db, pfj_match)
				pfj_match = 0
			}
		}
		z_err = if cnt == 0 { c'no such column' } else { c'ambiguous column name' }
		if z_db {
			sqlite3_error_msg(p_parse, c'%s: %s.%s.%s', voidptr(z_err), voidptr(z_db), voidptr(z_tab), voidptr(z_col))
		} else if z_tab {
			sqlite3_error_msg(p_parse, c'%s: %s.%s', voidptr(z_err), voidptr(z_tab), voidptr(z_col))
		} else if cnt == 0 && ((p_right.flags & u32(128)) != u32(0)) {
			sqlite3_error_msg(p_parse, c'%s: "%s" - should this be a string literal in single-quotes?', voidptr(z_err), voidptr(z_col))
		} else {
			sqlite3_error_msg(p_parse, c'%s: %s', voidptr(z_err), voidptr(z_col))
		}
		sqlite3_record_error_offset_of_expr(p_parse.db, p_expr)
		p_parse.checkSchema = Bft(1)
		p_top_nc.nNcErr++
		e_new_expr_op = 122
	}
	if !((p_expr.flags & u32((65536 | 8388608))) != u32(0)) {
		sqlite3_expr_delete(db, p_expr.pLeft)
		p_expr.pLeft = 0
		sqlite3_expr_delete(db, p_expr.pRight)
		p_expr.pRight = 0
		p_expr.flags |= u32(8388608)
	}
	if p_match {
		if int(p_expr.iColumn) >= 0 {
			p_match.colUsed |= sqlite3_expr_col_used(p_expr)
		} else {
			p_match.fg.rowidUsed = u32(1)
		}
	}
	p_expr.op = U8(e_new_expr_op)
	lookupname_end:
	if cnt == 1 {
		if !isnil(p_parse.db.xAuth) && (int(p_expr.op) == 168 || int(p_expr.op) == 78) {
			sqlite3_auth_read(p_parse, p_expr, p_schema, pnc.pSrcList)
		}
		for {
			p_top_nc.nRef++
			if usize(p_top_nc) == usize(pnc) {
				break
			}
			p_top_nc = p_top_nc.pNext
		}
		return 1
	} else {
		return 2
	}
}

@[c:'sqlite3CreateColumnExpr']
fn sqlite3_create_column_expr(db &Sqlite3, p_src &SrcList, i_src int, i_col int) &Expr {
	p := sqlite3_expr_alloc(db, 168, unsafe { nil }, 0)
	if p {
		p_item := unsafe { &p_src.a[0] + i_src }
		p_tab := &Table(0)
		p.y.pTab = p_item.pSTab
		p_tab = p.y.pTab
		p.iTable = p_item.iCursor
		if int(p.y.pTab.iPKey) == i_col {
			p.iColumn = YnVar(-1)
		} else {
			p.iColumn = YnVar(i_col)
			if (p_tab.tabFlags & u32(96)) != u32(0) && (int(p_tab.aCol[i_col].colFlags) & 96) != 0 {
				p_item.colUsed = if int(p_tab.nCol) >= 64 {
					(Bitmask(-1))
				} else {
					((Bitmask(1)) << int(p_tab.nCol)) - Bitmask(1)
				}
			} else {
				p_item.colUsed |= (Bitmask(1)) << (if i_col >= (int((sizeof(Bitmask) * u64(8)))) {
					(int((sizeof(Bitmask) * u64(8)))) - 1
				} else {
					i_col
				})
			}
		}
	}
	return p
}

@[c:'notValidImpl']
fn not_valid_impl(p_parse &Parse, pnc &NameContext, z_msg &i8, p_expr &Expr, p_error &Expr) {
	z_in := c'partial index WHERE clauses'
	if pnc.ncFlags & 32 {
		z_in = c'index expressions'
	} else if pnc.ncFlags & 4 {
		z_in = c'CHECK constraints'
	} else if pnc.ncFlags & 8 {
		z_in = c'generated columns'
	}
	sqlite3_error_msg(p_parse, c'%s prohibited in %s', voidptr(z_msg), voidptr(z_in))
	if p_expr {
		p_expr.op = U8(122)
	}
	sqlite3_record_error_offset_of_expr(p_parse.db, p_error)
}

@[c:'exprProbability']
fn expr_probability(p &Expr) int {
	r := -1.0
	if int(p.op) != 154 {
		return -1
	}
	sqlite3_ato_f(p.u.zToken, &r)
	if r > 1.0 {
		return -1
	}
	return int((r * 134217728.0))
}

@[c:'resolveSetExprSubtypeArg']
fn resolve_set_expr_subtype_arg(p_list &ExprList) {
	nn := 0
	ii := 0

	nn = if p_list { p_list.nExpr } else { 0 }
	for ii = 0; ii < nn; ii++ {
		p_expr := c2v_at(&p_list.a[0], isize(ii)).pExpr
		for {
			p_expr.flags |= u32(u32(2147483648))
			if int(p_expr.op) == 139 {
				resolve_set_expr_subtype_arg(p_expr.x.pSelect.pEList)
				break
			}
			if int(p_expr.op) == 173 {
				p_expr = p_expr.pLeft
			} else {
				break
			}
		}
	}
}

@[c:'resolveExprStep']
fn resolve_expr_step(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	pnc := &NameContext(0)
	p_parse := &Parse(0)
	pnc = p_walker.u.pNC
	p_parse = pnc.pParse
	match p_expr.op {
		76 {
			p_src_list := pnc.pSrcList
			p_item := &SrcItem(0)
			p_item = unsafe { &p_src_list.a[0] }
			p_expr.op = U8(168)
			p_expr.y.pTab = p_item.pSTab
			p_expr.iTable = p_item.iCursor
			p_expr.iColumn--
			p_expr.affExpr = i8(68)
		}
		52, 51 {
			an_ref := [8]int{}
			p := &NameContext(0)
			i := 0
			i = 0
			for p = pnc; !isnil(p) && i < 8;  {
				an_ref[i] = p.nRef
				p = p.pNext
				i++
			}
			sqlite3_walk_expr(p_walker, p_expr.pLeft)
			if (int(p_parse.eParseMode) >= 2) {
				return 1
			}
			if sqlite3_expr_can_be_null(p_expr.pLeft) {
				return 1
			}
			i = 0
			for p = pnc; p;  {
				if (p.ncFlags & 1048576) == 0 {
					return 1
				}
				p = p.pNext
				i++
			}
			p_expr.u.iValue = (int(p_expr.op) == 52)
			p_expr.flags |= u32(2048)
			p_expr.op = U8(156)
			i = 0
			for p = pnc; !isnil(p) && i < 8;  {
				p.nRef = an_ref[i]
				p = p.pNext
				i++
			}
			sqlite3_expr_delete(p_parse.db, p_expr.pLeft)
			p_expr.pLeft = 0
			return 1
		}
		60, 142 {
			z_table := &i8(0)
			z_db := &i8(0)
			p_right := &Expr(0)
			if int(p_expr.op) == 60 {
				z_db = 0
				z_table = 0
				p_right = p_expr
			} else {
				p_left := p_expr.pLeft
				if (pnc.ncFlags & (32 | 8)) != 0 {
					not_valid_impl(p_parse, pnc, c'the "." operator', unsafe { nil }, p_expr)
				}
				p_right = p_expr.pRight
				if int(p_right.op) == 60 {
					z_db = 0
				} else {
					z_db = p_left.u.zToken
					p_left = p_right.pLeft
					p_right = p_right.pRight
				}
				z_table = p_left.u.zToken
				if (int(p_parse.eParseMode) >= 2) {
					sqlite3_rename_token_remap(p_parse, voidptr(p_expr), voidptr(p_right))
					sqlite3_rename_token_remap(p_parse, voidptr(&p_expr.y.pTab), voidptr(p_left))
				}
			}
			return lookup_name(p_parse, z_db, z_table, p_right, pnc, p_expr)
		}
		172 {
			p_list := &ExprList(0)
			n := 0
			no_such_func := 0
			wrong_num_args := 0
			is_agg := 0
			z_id := &i8(0)
			p_def := &FuncDef(0)
			enc := p_parse.db.enc
			saved_allow_flags := (pnc.ncFlags & (1 | 16384))
			p_win := (unsafe { if (((p_expr.flags & u32(16777216)) != u32(0)) && int(p_expr.y.pWin.eFrmType) != 167) {
				p_expr.y.pWin
			} else {
				&Window(nil)
			} })
			p_list = p_expr.x.pList
			n = if p_list { p_list.nExpr } else { 0 }
			z_id = p_expr.u.zToken
			p_def = sqlite3_find_function(p_parse.db, z_id, n, enc, U8(0))
			if usize(p_def) == usize(0) {
				p_def = sqlite3_find_function(p_parse.db, z_id, -2, enc, U8(0))
				if usize(p_def) == usize(0) {
					no_such_func = 1
				} else {
					wrong_num_args = 1
				}
			} else {
				is_agg = !isnil(p_def.xFinalize)
				if p_def.funcFlags & u32(1024) {
					p_expr.flags |= u32(524288)
					if n == 2 {
						p_expr.iTable = expr_probability(c2v_at(&p_list.a[0], isize(1)).pExpr)
						if p_expr.iTable < 0 {
							sqlite3_error_msg(p_parse, c'second argument to %#T() must be a constant between 0.0 and 1.0', voidptr(p_expr))
							pnc.nNcErr++
						}
					} else {
						p_expr.iTable = if int(p_def.zName[0]) == i8(`u`) {
							8388608
						} else {
							125829120
						}
					}
				}
				auth := sqlite3_auth_check(p_parse, 31, unsafe { nil }, p_def.zName, unsafe { nil })
				if auth != 0 {
					if auth == 1 {
						sqlite3_error_msg(p_parse, c'not authorized to use function: %#T', voidptr(p_expr))
						pnc.nNcErr++
					}
					p_expr.op = U8(122)
					return 1
				}
				if (p_def.funcFlags & u32(1048576)) || ((p_expr.flags & u32(u32(2147483648))) != u32(0)) {
					resolve_set_expr_subtype_arg(p_list)
				}
				if p_def.funcFlags & u32((2048 | 8192)) {
					p_expr.flags |= u32(1048576)
				}
				if (p_def.funcFlags & u32(2048)) == u32(0) {
					if (pnc.ncFlags & (32 | 2 | 8)) != 0 {
						not_valid_impl(p_parse, pnc, c'non-deterministic functions', unsafe { nil }, p_expr)
					}
				} else {
					p_expr.op2 = U8(pnc.ncFlags & 46)
				}
				if (p_def.funcFlags & u32(262144)) != u32(0) && int(p_parse.nested) == 0 && (p_parse.db.mDbFlags & u32(32)) == u32(0) {
					no_such_func = 1
					p_def = 0
				} else if (p_def.funcFlags & u32((524288 | 2097152))) != u32(0) && !(int(p_parse.eParseMode) >= 2) {
					if pnc.ncFlags & 262144 {
						p_expr.flags |= u32(1073741824)
					}
					sqlite3_expr_function_usable(p_parse, p_expr, p_def)
				}
			}
			if 0 == (int(p_parse.eParseMode) >= 2) {
				if !isnil(p_def) && isnil(p_def.xValue) && !isnil(p_win) {
					sqlite3_error_msg(p_parse, c'%#T() may not be used as a window function', voidptr(p_expr))
					pnc.nNcErr++
				} else if (is_agg && (pnc.ncFlags & 1) == 0) || (is_agg && (p_def.funcFlags & u32(65536)) && isnil(p_win)) || (is_agg && !isnil(p_win) && (pnc.ncFlags & 16384) == 0) {
					z_type := &i8(0)
					if (p_def.funcFlags & u32(65536)) || !isnil(p_win) {
						z_type = c'window'
					} else {
						z_type = c'aggregate'
					}
					sqlite3_error_msg(p_parse, c'misuse of %s function %#T()', voidptr(z_type), voidptr(p_expr))
					pnc.nNcErr++
					is_agg = 0
				} else if no_such_func && int(p_parse.db.init.busy) == 0 {
					sqlite3_error_msg(p_parse, c'no such function: %#T', voidptr(p_expr))
					pnc.nNcErr++
				} else if wrong_num_args {
					sqlite3_error_msg(p_parse, c'wrong number of arguments to function %#T()', voidptr(p_expr))
					pnc.nNcErr++
				} else if is_agg == 0 && ((p_expr.flags & u32(16777216)) != u32(0)) {
					sqlite3_error_msg(p_parse, c'FILTER may not be used with non-aggregate %#T()', voidptr(p_expr))
					pnc.nNcErr++
				} else if is_agg == 0 && !isnil(p_expr.pLeft) {
					sqlite3_expr_order_by_aggregate_error(p_parse, p_expr)
					pnc.nNcErr++
				}
				if is_agg {
					pnc.ncFlags &= ~(16384 | (if isnil(p_win) { 1 } else { 0 }))
				}
			} else if ((p_expr.flags & u32(16777216)) != u32(0)) || !isnil(p_expr.pLeft) {
				is_agg = 1
			}
			sqlite3_walk_expr_list(p_walker, p_list)
			if is_agg {
				if p_expr.pLeft {
					sqlite3_walk_expr_list(p_walker, p_expr.pLeft.x.pList)
				}
				if !isnil(p_win) && p_parse.nErr == 0 {
					p_sel := pnc.pWinSelect
					if (int(p_parse.eParseMode) >= 2) == 0 {
						sqlite3_window_update(p_parse, unsafe { if p_sel {
							p_sel.pWinDefn
						} else {
							&Window(nil)
						} }, p_win, p_def)
						if p_parse.db.mallocFailed {
							unsafe { goto c2v_switch_end_28
							 }
						}
					}
					sqlite3_walk_expr_list(p_walker, p_win.pPartition)
					sqlite3_walk_expr_list(p_walker, p_win.pOrderBy)
					sqlite3_walk_expr(p_walker, p_win.pFilter)
					sqlite3_window_link(p_sel, p_win)
					pnc.ncFlags |= 32768
				} else {
					pnc_2 := &NameContext(0)
					p_expr.op = U8(169)
					p_expr.op2 = U8(0)
					if ((p_expr.flags & u32(16777216)) != u32(0)) {
						sqlite3_walk_expr(p_walker, p_expr.y.pWin.pFilter)
					}
					pnc_2 = pnc
					for !isnil(pnc_2) && sqlite3_references_src_list(p_parse, p_expr, pnc_2.pSrcList) == 0 {
						p_expr.op2 += (u32(1) + pnc_2.nNestedSelect)
						pnc_2 = pnc_2.pNext
					}
					if !isnil(pnc_2) && !isnil(p_def) {
						p_expr.op2 += pnc_2.nNestedSelect
						pnc_2.ncFlags |= u32(16) | ((p_def.funcFlags ^ u32(134217728)) & u32((4096 | 134217728)))
					}
				}
				pnc.ncFlags |= saved_allow_flags
			}
			return 1
		}
		20, 139, 50 {
			if ((p_expr.flags & u32(4096)) != u32(0)) {
				n_ref := pnc.nRef
				if int(p_expr.op) == 20 {
					p_parse.bHasExists = Bft(1)
				}
				if pnc.ncFlags & 46 {
					not_valid_impl(p_parse, pnc, c'subqueries', p_expr, p_expr)
				} else {
					sqlite3_walk_select(p_walker, p_expr.x.pSelect)
				}
				if n_ref != pnc.nRef {
					p_expr.flags |= u32(64)
					p_expr.x.pSelect.selFlags |= u32(536870912)
				}
				pnc.ncFlags |= 64
			}
		}
		157 {
			if (pnc.ncFlags & (4 | 2 | 32 | 8)) != 0 {
				not_valid_impl(p_parse, pnc, c'parameters', p_expr, p_expr)
			}
		}
		45, 46 {
			p_right_2 := sqlite3_expr_skip_collate_and_likely(p_expr.pRight)
			if !isnil(p_right_2) && (int(p_right_2.op) == 60 || int(p_right_2.op) == 171) {
				rc := resolve_expr_step(p_walker, p_right_2)
				if rc == 2 {
					return 2
				}
				if int(p_right_2.op) == 171 {
					p_expr.op2 = p_expr.op
					p_expr.op = U8(175)
					return 0
				}
			}

			unsafe { goto c2v_case_28_7
			 }
		}
		49, 54, 53, 57, 56, 55, 58 {
			c2v_case_28_7:
			n_left := 0
			n_right := 0

			if p_parse.db.mallocFailed {
				unsafe { goto c2v_switch_end_28
				 }
			}
			n_left = sqlite3_expr_vector_size(p_expr.pLeft)
			if int(p_expr.op) == 49 {
				n_right = sqlite3_expr_vector_size(c2v_at(&p_expr.x.pList.a[0], isize(0)).pExpr)
				if n_right == n_left {
					n_right = sqlite3_expr_vector_size(c2v_at(&p_expr.x.pList.a[0], isize(1)).pExpr)
				}
			} else {
				n_right = sqlite3_expr_vector_size(p_expr.pRight)
			}
			if n_left != n_right {
				sqlite3_error_msg(p_parse, c'row value misused')
				sqlite3_record_error_offset_of_expr(p_parse.db, p_expr)
			}
		}
		else {}
	}
	c2v_switch_end_28:

	return if p_parse.nErr { 2 } else { 0 }
}

@[c:'resolveAsName']
fn resolve_as_name(p_parse &Parse, pel_ist &ExprList, pe &Expr) int {
	i := 0

	if int(pe.op) == 60 {
		z_col := &i8(0)
		z_col = pe.u.zToken
		for i = 0; i < pel_ist.nExpr; i++ {
			if int(c2v_at(&pel_ist.a[0], isize(i)).fg.eEName) == 0 && sqlite3_stricmp(c2v_at(&pel_ist.a[0], isize(i)).zEName, z_col) == 0 {
				return i + 1
			}
		}
	}
	return 0
}

@[c:'resolveOrderByTermToExprList']
fn resolve_order_by_term_to_expr_list(p_parse &Parse, p_select &Select, pe &Expr) int {
	i := 0
	pel_ist := &ExprList(0)
	nc := NameContext{}
	db := &Sqlite3(0)
	rc := 0
	saved_supp_err := U8(0)
	pel_ist = p_select.pEList
	C.memset(voidptr(&nc), 0, sizeof(nc))
	nc.pParse = p_parse
	nc.pSrcList = p_select.pSrc
	nc.uNC.pEList = pel_ist
	nc.ncFlags = 1 | 128 | 524288
	nc.nNcErr = 0
	db = p_parse.db
	saved_supp_err = db.suppressErr
	db.suppressErr = U8(1)
	rc = sqlite3_resolve_expr_names(&nc, pe)
	db.suppressErr = saved_supp_err
	if rc {
		return 0
	}
	for i = 0; i < pel_ist.nExpr; i++ {
		if sqlite3_expr_compare(unsafe { nil }, c2v_at(&pel_ist.a[0], isize(i)).pExpr, pe, -1) < 2 {
			return i + 1
		}
	}
	return 0
}

@[c:'resolveOutOfRangeError']
fn resolve_out_of_range_error(p_parse &Parse, z_type &i8, i int, mx int, p_error &Expr) {
	sqlite3_error_msg(p_parse, c'%r %s BY term out of range - should be between 1 and %d', i, voidptr(z_type), mx)
	sqlite3_record_error_offset_of_expr(p_parse.db, p_error)
}

@[c:'resolveCompoundOrderBy']
fn resolve_compound_order_by(p_parse &Parse, p_select &Select) int {
	i := 0
	p_order_by := &ExprList(0)
	pel_ist := &ExprList(0)
	db := &Sqlite3(0)
	more_to_do := 1
	p_order_by = p_select.pOrderBy
	if usize(p_order_by) == usize(0) {
		return 0
	}
	db = p_parse.db
	if p_order_by.nExpr > db.aLimit[2] {
		sqlite3_error_msg(p_parse, c'too many terms in ORDER BY clause')
		return 1
	}
	for i = 0; i < p_order_by.nExpr; i++ {
		mut __c2v_lhs_tmp_90 := c2v_at(&p_order_by.a[0], isize(i))
		__c2v_lhs_tmp_90.fg.done = u32(0)
	}
	p_select.pNext = 0
	for p_select.pPrior {
		p_select.pPrior.pNext = p_select
		p_select = p_select.pPrior
	}
	for !isnil(p_select) && more_to_do {
		p_item := &ExprList_item(0)
		more_to_do = 0
		pel_ist = p_select.pEList
		i = 0
		for p_item = unsafe { &p_order_by.a[0] }; i < p_order_by.nExpr; i++ {
			i_col := -1
			pe := &Expr(0)
			p_dup := &Expr(0)

			if p_item.fg.done {
				unsafe { goto c2v_for_next_79
				 }
			}
			pe = sqlite3_expr_skip_collate_and_likely(p_item.pExpr)
			if (usize(pe) == usize(0)) {
				unsafe { goto c2v_for_next_79
				 }
			}
			if sqlite3_expr_is_integer(pe, &i_col, unsafe { nil }) {
				if i_col <= 0 || i_col > pel_ist.nExpr {
					resolve_out_of_range_error(p_parse, c'ORDER', i + 1, pel_ist.nExpr, pe)
					return 1
				}
			} else {
				i_col = resolve_as_name(p_parse, pel_ist, pe)
				if i_col == 0 {
					p_dup = sqlite3_expr_dup(db, pe, 0)
					if !db.mallocFailed {
						i_col = resolve_order_by_term_to_expr_list(p_parse, p_select, p_dup)
						if (int(p_parse.eParseMode) >= 2) && i_col > 0 {
							resolve_order_by_term_to_expr_list(p_parse, p_select, pe)
						}
					}
					sqlite3_expr_delete(db, p_dup)
				}
			}
			if i_col > 0 {
				if !(int(p_parse.eParseMode) >= 2) {
					p_new := sqlite3_expr_int32(db, i_col)
					if usize(p_new) == usize(0) {
						return 1
					}
					if usize(p_item.pExpr) == usize(pe) {
						p_item.pExpr = p_new
					} else {
						p_parent := p_item.pExpr
						for int(p_parent.pLeft.op) == 114 {
							p_parent = p_parent.pLeft
						}
						p_parent.pLeft = p_new
					}
					sqlite3_expr_delete(db, pe)
					p_item.u.x.iOrderByCol = U16(i_col)
				}
				p_item.fg.done = u32(1)
			} else {
				more_to_do = 1
			}
			c2v_for_next_79:
			c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
		}
		p_select = p_select.pNext
	}
	for i = 0; i < p_order_by.nExpr; i++ {
		if int(c2v_at(&p_order_by.a[0], isize(i)).fg.done) == 0 {
			sqlite3_error_msg(p_parse, c'%r ORDER BY term does not match any column in the result set', i + 1)
			return 1
		}
	}
	return 0
}

@[c:'sqlite3ResolveOrderGroupBy']
fn sqlite3_resolve_order_group_by(p_parse &Parse, p_select &Select, p_order_by &ExprList, z_type &i8) int {
	i := 0
	db := p_parse.db
	pel_ist := &ExprList(0)
	p_item := &ExprList_item(0)
	if usize(p_order_by) == usize(0) || int(p_parse.db.mallocFailed) || (int(p_parse.eParseMode) >= 2) {
		return 0
	}
	if p_order_by.nExpr > db.aLimit[2] {
		sqlite3_error_msg(p_parse, c'too many terms in %s BY clause', voidptr(z_type))
		return 1
	}
	pel_ist = p_select.pEList
	i = 0
	for p_item = unsafe { &p_order_by.a[0] }; i < p_order_by.nExpr; i++ {
		if p_item.u.x.iOrderByCol {
			if int(p_item.u.x.iOrderByCol) > pel_ist.nExpr {
				resolve_out_of_range_error(p_parse, z_type, i + 1, pel_ist.nExpr, unsafe { nil })
				return 1
			}
			resolve_alias(p_parse, pel_ist, int(p_item.u.x.iOrderByCol) - 1, p_item.pExpr, 0)
		}
		c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
	}
	return 0
}

@[c:'resolveRemoveWindowsCb']
fn resolve_remove_windows_cb(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()

	if ((p_expr.flags & u32(16777216)) != u32(0)) {
		p_win := p_expr.y.pWin
		sqlite3_window_unlink_from_select(p_win)
	}
	return 0
}

@[c:'windowRemoveExprFromSelect']
fn window_remove_expr_from_select(p_select &Select, p_expr &Expr) {
	if p_select.pWin {
		s_walker := Walker{}
		C.memset(voidptr(&s_walker), 0, sizeof(Walker))
		s_walker.xExprCallback = resolve_remove_windows_cb
		s_walker.u.pSelect = p_select
		sqlite3_walk_expr(&s_walker, p_expr)
	}
}

@[c:'resolveOrderGroupBy']
fn resolve_order_group_by(pnc &NameContext, p_select &Select, p_order_by &ExprList, z_type &i8) int {
	i := 0
	j := 0

	i_col := 0
	p_item := &ExprList_item(0)
	p_parse := &Parse(0)
	n_result := 0
	n_result = p_select.pEList.nExpr
	p_parse = pnc.pParse
	i = 0
	for p_item = unsafe { &p_order_by.a[0] }; i < p_order_by.nExpr; i++ {
		pe := p_item.pExpr
		p_e2 := sqlite3_expr_skip_collate_and_likely(pe)
		if (usize(p_e2) == usize(0)) {
			unsafe { goto c2v_for_next_81
			 }
		}
		if int(z_type[0]) != i8(`G`) {
			i_col = resolve_as_name(p_parse, p_select.pEList, p_e2)
			if i_col > 0 {
				p_item.u.x.iOrderByCol = U16(i_col)
				unsafe { goto c2v_for_next_81
				 }
			}
		}
		if sqlite3_expr_is_integer(p_e2, &i_col, unsafe { nil }) {
			if i_col < 1 || i_col > 65535 {
				resolve_out_of_range_error(p_parse, z_type, i + 1, n_result, p_e2)
				return 1
			}
			p_item.u.x.iOrderByCol = U16(i_col)
			unsafe { goto c2v_for_next_81
			 }
		}
		p_item.u.x.iOrderByCol = U16(0)
		if sqlite3_resolve_expr_names(pnc, pe) {
			return 1
		}
		for j = 0; j < p_select.pEList.nExpr; j++ {
			if sqlite3_expr_compare(unsafe { nil }, pe, c2v_at(&p_select.pEList.a[0], isize(j)).pExpr, -1) == 0 {
				window_remove_expr_from_select(p_select, pe)
				p_item.u.x.iOrderByCol = U16(j + 1)
			}
		}
		c2v_for_next_81:
		c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
	}
	return sqlite3_resolve_order_group_by(p_parse, p_select, p_order_by, z_type)
}

@[c:'resolveSelectStep']
fn resolve_select_step(p_walker &Walker, p &Select) int {
	c2v_gc_register_thread()
	p_outer_nc := &NameContext(0)
	snc := NameContext{}
	is_compound := 0
	n_compound := 0
	p_parse := &Parse(0)
	i := 0
	p_group_by := &ExprList(0)
	p_leftmost := &Select(0)
	db := &Sqlite3(0)
	if p.selFlags & u32(4) {
		return 1
	}
	p_outer_nc = p_walker.u.pNC
	p_parse = p_walker.pParse
	db = p_parse.db
	if (p.selFlags & u32(64)) == u32(0) {
		sqlite3_select_prep(p_parse, p, p_outer_nc)
		return if p_parse.nErr { 2 } else { 1 }
	}
	is_compound = usize(p.pPrior) != usize(0)
	n_compound = 0
	p_leftmost = p
	for p {
		p.selFlags |= u32(4)
		C.memset(voidptr(&snc), 0, sizeof(snc))
		snc.pParse = p_parse
		snc.pWinSelect = p
		if sqlite3_resolve_expr_names(&snc, p.pLimit) {
			return 2
		}
		if p.selFlags & u32(65536) {
			p_sub := &Select(0)
			p_sub = c2v_at(&p.pSrc.a[0], isize(0)).u4.pSubq.pSelect
			p_sub.pOrderBy = p.pOrderBy
			p.pOrderBy = 0
		}
		if p_outer_nc {
			p_outer_nc.nNestedSelect++
		}
		for i = 0; i < p.pSrc.nSrc; i++ {
			p_item := unsafe { &p.pSrc.a[0] + i }
			if int(p_item.fg.isSubquery) && (p_item.u4.pSubq.pSelect.selFlags & u32(4)) == u32(0) {
				n_ref := if p_outer_nc { p_outer_nc.nRef } else { 0 }
				z_saved_context := p_parse.zAuthContext
				if p_item.zName {
					p_parse.zAuthContext = p_item.zName
				}
				sqlite3_resolve_select_names(p_parse, p_item.u4.pSubq.pSelect, p_outer_nc)
				p_parse.zAuthContext = z_saved_context
				if p_parse.nErr {
					return 2
				}
				if p_outer_nc {
					p_item.fg.isCorrelated = u32((p_outer_nc.nRef > n_ref))
				}
			}
		}
		if !isnil(p_outer_nc) && (p_outer_nc.nNestedSelect > u32(0)) {
			p_outer_nc.nNestedSelect--
		}
		snc.ncFlags = 1 | 16384
		snc.pSrcList = p.pSrc
		snc.pNext = p_outer_nc
		if sqlite3_resolve_expr_list_names(&snc, p.pEList) {
			return 2
		}
		snc.ncFlags &= ~16384
		p_group_by = p.pGroupBy
		if !isnil(p_group_by) || (snc.ncFlags & 16) != 0 {
			p.selFlags |= u32(8 | (snc.ncFlags & (4096 | 134217728)))
		} else {
			snc.ncFlags &= ~1
		}
		snc.uNC.pEList = p.pEList
		snc.ncFlags |= 128
		if p.pHaving {
			if (p.selFlags & u32(8)) == u32(0) {
				sqlite3_error_msg(p_parse, c'HAVING clause on a non-aggregate query')
				return 2
			}
			if sqlite3_resolve_expr_names(&snc, p.pHaving) {
				return 2
			}
		}
		snc.ncFlags |= 1048576
		if sqlite3_resolve_expr_names(&snc, p.pWhere) {
			return 2
		}
		snc.ncFlags &= ~1048576
		for i = 0; i < p.pSrc.nSrc; i++ {
			p_item := unsafe { &p.pSrc.a[0] + i }
			if int(p_item.fg.isTabFunc) && sqlite3_resolve_expr_list_names(&snc, p_item.u1.pFuncArg) {
				return 2
			}
		}
		if (int(p_parse.eParseMode) >= 2) {
			p_win := &Window(0)
			for p_win = p.pWinDefn; p_win; p_win = p_win.pNextWin {
				if sqlite3_resolve_expr_list_names(&snc, p_win.pOrderBy) || sqlite3_resolve_expr_list_names(&snc, p_win.pPartition) {
					return 2
				}
			}
		}
		snc.ncFlags |= 1 | 16384
		if p.selFlags & u32(65536) {
			p_sub := &Select(0)
			p_sub = c2v_at(&p.pSrc.a[0], isize(0)).u4.pSubq.pSelect
			p.pOrderBy = p_sub.pOrderBy
			p_sub.pOrderBy = 0
		}
		if usize(p.pOrderBy) != usize(0) && is_compound <= n_compound && resolve_order_group_by(&snc, p, p.pOrderBy, c'ORDER') {
			return 2
		}
		if db.mallocFailed {
			return 2
		}
		snc.ncFlags &= ~16384
		if p_group_by {
			p_item := &ExprList_item(0)
			if resolve_order_group_by(&snc, p, p_group_by, c'GROUP') || int(db.mallocFailed) {
				return 2
			}
			i = 0
			for p_item = unsafe { &p_group_by.a[0] }; i < p_group_by.nExpr; i++ {
				if ((p_item.pExpr.flags & u32(16)) != u32(0)) {
					sqlite3_error_msg(p_parse, c'aggregate functions are not allowed in the GROUP BY clause')
					return 2
				}
				c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
			}
		}
		if !isnil(p.pNext) && p.pEList.nExpr != p.pNext.pEList.nExpr {
			sqlite3_select_wrong_num_terms_error(p_parse, p.pNext)
			return 2
		}
		if (p.selFlags & u32(1073741824)) {
			sqlite3_select_check_on_clauses(p_parse, p)
			if p_parse.nErr {
				return 2
			}
		}
		p = p.pPrior
		n_compound++
	}
	if is_compound && resolve_compound_order_by(p_parse, p_leftmost) {
		return 2
	}
	return 1
}

@[c:'sqlite3ResolveExprNames']
fn sqlite3_resolve_expr_names(pnc &NameContext, p_expr &Expr) int {
	saved_has_agg := 0
	w := Walker{}
	if usize(p_expr) == usize(0) {
		return 0
	}
	saved_has_agg = pnc.ncFlags & (16 | 4096 | 32768 | 134217728)
	pnc.ncFlags &= ~(16 | 4096 | 32768 | 134217728)
	w.pParse = pnc.pParse
	w.xExprCallback = resolve_expr_step
	w.xSelectCallback = unsafe { if (pnc.ncFlags & 524288) {
		C2vFn_666e20282657616c6b65722c202653656c6563742920696e74(voidptr(0))
	} else {
		resolve_select_step
	} }
	w.xSelectCallback2 = 0
	w.u.pNC = pnc
	w.pParse.nHeight += p_expr.nHeight
	if sqlite3_expr_check_height(w.pParse, w.pParse.nHeight) {
		return 1
	}
	sqlite3_walk_expr_nn(&w, p_expr)
	w.pParse.nHeight -= p_expr.nHeight
	p_expr.flags |= u32((pnc.ncFlags & (16 | 32768)))
	pnc.ncFlags |= saved_has_agg
	return int(pnc.nNcErr > 0 || w.pParse.nErr > 0)
}

@[c:'sqlite3ResolveExprListNames']
fn sqlite3_resolve_expr_list_names(pnc &NameContext, p_list &ExprList) int {
	i := 0
	saved_has_agg := 0
	w := Walker{}
	if usize(p_list) == usize(0) {
		return 0
	}
	w.pParse = pnc.pParse
	w.xExprCallback = resolve_expr_step
	w.xSelectCallback = resolve_select_step
	w.xSelectCallback2 = 0
	w.u.pNC = pnc
	saved_has_agg = pnc.ncFlags & (16 | 4096 | 32768 | 134217728)
	pnc.ncFlags &= ~(16 | 4096 | 32768 | 134217728)
	for i = 0; i < p_list.nExpr; i++ {
		p_expr := c2v_at(&p_list.a[0], isize(i)).pExpr
		if usize(p_expr) == usize(0) {
			continue
		}
		w.pParse.nHeight += p_expr.nHeight
		if sqlite3_expr_check_height(w.pParse, w.pParse.nHeight) {
			return 1
		}
		sqlite3_walk_expr_nn(&w, p_expr)
		w.pParse.nHeight -= p_expr.nHeight
		if pnc.ncFlags & (16 | 4096 | 32768 | 134217728) {
			p_expr.flags |= u32((pnc.ncFlags & (16 | 32768)))
			saved_has_agg |= pnc.ncFlags & (16 | 4096 | 32768 | 134217728)
			pnc.ncFlags &= ~(16 | 4096 | 32768 | 134217728)
		}
		if w.pParse.nErr > 0 {
			return 1
		}
	}
	pnc.ncFlags |= saved_has_agg
	return 0
}

@[c:'sqlite3ResolveSelectNames']
fn sqlite3_resolve_select_names(p_parse &Parse, p &Select, p_outer_nc &NameContext) {
	w := Walker{}
	w.xExprCallback = resolve_expr_step
	w.xSelectCallback = resolve_select_step
	w.xSelectCallback2 = 0
	w.pParse = p_parse
	w.u.pNC = p_outer_nc
	sqlite3_walk_select(&w, p)
}

@[c:'sqlite3ResolveSelfReference']
fn sqlite3_resolve_self_reference(p_parse &Parse, p_tab &Table, type_ int, p_expr &Expr, p_list &ExprList) int {
	p_src := &SrcList(0)
	snc := NameContext{}
	rc := 0
	u_src := AnonStruct_112889{}

	C.memset(voidptr(&snc), 0, sizeof(snc))
	C.memset(voidptr(&u_src), 0, sizeof(u_src))
	p_src = &u_src.sSrc
	if p_tab {
		p_src.nSrc = 1
		mut __c2v_lhs_tmp_91 := c2v_at(&p_src.a[0], isize(0))
		__c2v_lhs_tmp_91.zName = p_tab.zName
		mut __c2v_lhs_tmp_92 := c2v_at(&p_src.a[0], isize(0))
		__c2v_lhs_tmp_92.pSTab = p_tab
		mut __c2v_lhs_tmp_93 := c2v_at(&p_src.a[0], isize(0))
		__c2v_lhs_tmp_93.iCursor = -1
		if usize(p_tab.pSchema) != usize(p_parse.db.aDb[1].pSchema) {
			type_ |= 262144
		}
	}
	snc.pParse = p_parse
	snc.pSrcList = p_src
	snc.ncFlags = type_ | 65536
	rc = sqlite3_resolve_expr_names(&snc, p_expr)
	if rc != 0 {
		return rc
	}
	if p_list {
		rc = sqlite3_resolve_expr_list_names(&snc, p_list)
	}
	return rc
}
