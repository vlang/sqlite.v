@[translated]
module main

@[c:'row_numberStepFunc']
fn row_number_step_func(p_ctx &Sqlite3_context, n_arg int, ap_arg &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &I64(sqlite3_aggregate_context(p_ctx, int(sizeof(I64))))
	if p {
		unsafe { (*p)++ }
	}
}

@[c:'row_numberValueFunc']
fn row_number_value_func(p_ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	p := &I64(sqlite3_aggregate_context(p_ctx, int(sizeof(I64))))
	sqlite3_result_int64(p_ctx, (if p { (unsafe { *p }) } else { I64(0) }))
}

struct CallCount {
	nValue I64
	nStep  I64
	nTotal I64
}

@[c:'dense_rankStepFunc']
fn dense_rank_step_func(p_ctx &Sqlite3_context, n_arg int, ap_arg &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &CallCount(0)
	p = &CallCount(sqlite3_aggregate_context(p_ctx, int(sizeof(CallCount))))
	if p {
		p.nStep = I64(1)
	}
}

@[c:'dense_rankValueFunc']
fn dense_rank_value_func(p_ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	p := &CallCount(0)
	p = &CallCount(sqlite3_aggregate_context(p_ctx, int(sizeof(CallCount))))
	if p {
		if p.nStep {
			p.nValue++
			p.nStep = I64(0)
		}
		sqlite3_result_int64(p_ctx, p.nValue)
	}
}

struct NthValueCtx {
	nStep  I64
	pValue &Sqlite3_value
}

@[c:'nth_valueStepFunc']
fn nth_value_step_func(p_ctx &Sqlite3_context, n_arg int, ap_arg &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &NthValueCtx(0)
	p = &NthValueCtx(sqlite3_aggregate_context(p_ctx, int(sizeof(NthValueCtx))))
	if p {
		i_val := I64(0)
		match sqlite3_value_numeric_type(ap_arg[1]) {
			1 {
				i_val = sqlite3_value_int64(ap_arg[1])
			}
			2 {
				f_val := sqlite3_value_double(ap_arg[1])
				if f64(sqlite3_real_to_i64(f_val)) != f_val {
					unsafe { goto error_out
					 }
				}
				i_val = I64(f_val)
			}
			else {
				unsafe { goto error_out
				 }
			}
		}

		if i_val <= I64(0) {
			unsafe { goto error_out
			 }
		}
		p.nStep++
		if i_val == p.nStep {
			p.pValue = sqlite3_value_dup(ap_arg[0])
			if isnil(p.pValue) {
				sqlite3_result_error_nomem(p_ctx)
			}
		}
	}

	return
	error_out:
	sqlite3_result_error(p_ctx, c'second argument to nth_value must be a positive integer', -1)
}

@[c:'nth_valueFinalizeFunc']
fn nth_value_finalize_func(p_ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	p := &NthValueCtx(0)
	p = &NthValueCtx(sqlite3_aggregate_context(p_ctx, 0))
	if !isnil(p) && !isnil(p.pValue) {
		sqlite3_result_value(p_ctx, p.pValue)
		sqlite3_value_free(p.pValue)
		p.pValue = 0
	}
}

@[c:'first_valueStepFunc']
fn first_value_step_func(p_ctx &Sqlite3_context, n_arg int, ap_arg &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &NthValueCtx(0)
	p = &NthValueCtx(sqlite3_aggregate_context(p_ctx, int(sizeof(NthValueCtx))))
	if !isnil(p) && usize(p.pValue) == usize(0) {
		p.pValue = sqlite3_value_dup(ap_arg[0])
		if isnil(p.pValue) {
			sqlite3_result_error_nomem(p_ctx)
		}
	}
}

@[c:'first_valueFinalizeFunc']
fn first_value_finalize_func(p_ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	p := &NthValueCtx(0)
	p = &NthValueCtx(sqlite3_aggregate_context(p_ctx, int(sizeof(NthValueCtx))))
	if !isnil(p) && !isnil(p.pValue) {
		sqlite3_result_value(p_ctx, p.pValue)
		sqlite3_value_free(p.pValue)
		p.pValue = 0
	}
}

@[c:'rankStepFunc']
fn rank_step_func(p_ctx &Sqlite3_context, n_arg int, ap_arg &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &CallCount(0)
	p = &CallCount(sqlite3_aggregate_context(p_ctx, int(sizeof(CallCount))))
	if p {
		p.nStep++
		if p.nValue == I64(0) {
			p.nValue = p.nStep
		}
	}
}

@[c:'rankValueFunc']
fn rank_value_func(p_ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	p := &CallCount(0)
	p = &CallCount(sqlite3_aggregate_context(p_ctx, int(sizeof(CallCount))))
	if p {
		sqlite3_result_int64(p_ctx, p.nValue)
		p.nValue = I64(0)
	}
}

@[c:'percent_rankStepFunc']
fn percent_rank_step_func(p_ctx &Sqlite3_context, n_arg int, ap_arg &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &CallCount(0)

	p = &CallCount(sqlite3_aggregate_context(p_ctx, int(sizeof(CallCount))))
	if p {
		p.nTotal++
	}
}

@[c:'percent_rankInvFunc']
fn percent_rank_inv_func(p_ctx &Sqlite3_context, n_arg int, ap_arg &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &CallCount(0)

	p = &CallCount(sqlite3_aggregate_context(p_ctx, int(sizeof(CallCount))))
	p.nStep++
}

@[c:'percent_rankValueFunc']
fn percent_rank_value_func(p_ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	p := &CallCount(0)
	p = &CallCount(sqlite3_aggregate_context(p_ctx, int(sizeof(CallCount))))
	if p {
		p.nValue = p.nStep
		if p.nTotal > I64(1) {
			r := f64(p.nValue) / f64((p.nTotal - I64(1)))
			sqlite3_result_double(p_ctx, r)
		} else {
			sqlite3_result_double(p_ctx, 0.0)
		}
	}
}

@[c:'cume_distStepFunc']
fn cume_dist_step_func(p_ctx &Sqlite3_context, n_arg int, ap_arg &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &CallCount(0)

	p = &CallCount(sqlite3_aggregate_context(p_ctx, int(sizeof(CallCount))))
	if p {
		p.nTotal++
	}
}

@[c:'cume_distInvFunc']
fn cume_dist_inv_func(p_ctx &Sqlite3_context, n_arg int, ap_arg &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &CallCount(0)

	p = &CallCount(sqlite3_aggregate_context(p_ctx, int(sizeof(CallCount))))
	p.nStep++
}

@[c:'cume_distValueFunc']
fn cume_dist_value_func(p_ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	p := &CallCount(0)
	p = &CallCount(sqlite3_aggregate_context(p_ctx, 0))
	if p {
		r := f64(p.nStep) / f64(p.nTotal)
		sqlite3_result_double(p_ctx, r)
	}
}

struct NtileCtx {
	nTotal I64
	nParam I64
	iRow   I64
}

@[c:'ntileStepFunc']
fn ntile_step_func(p_ctx &Sqlite3_context, n_arg int, ap_arg &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &NtileCtx(0)

	p = &NtileCtx(sqlite3_aggregate_context(p_ctx, int(sizeof(NtileCtx))))
	if p {
		if p.nTotal == I64(0) {
			p.nParam = sqlite3_value_int64(ap_arg[0])
			if p.nParam <= I64(0) {
				sqlite3_result_error(p_ctx, c'argument of ntile must be a positive integer', -1)
			}
		}
		p.nTotal++
	}
}

@[c:'ntileInvFunc']
fn ntile_inv_func(p_ctx &Sqlite3_context, n_arg int, ap_arg &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &NtileCtx(0)

	p = &NtileCtx(sqlite3_aggregate_context(p_ctx, int(sizeof(NtileCtx))))
	p.iRow++
}

@[c:'ntileValueFunc']
fn ntile_value_func(p_ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	p := &NtileCtx(0)
	p = &NtileCtx(sqlite3_aggregate_context(p_ctx, int(sizeof(NtileCtx))))
	if !isnil(p) && p.nParam > I64(0) {
		n_size := int((p.nTotal / p.nParam))
		if n_size == 0 {
			sqlite3_result_int64(p_ctx, p.iRow + I64(1))
		} else {
			n_large := p.nTotal - p.nParam * I64(n_size)
			i_small := n_large * I64((n_size + 1))
			i_row := p.iRow
			if i_row < i_small {
				sqlite3_result_int64(p_ctx, I64(1) + i_row / I64((n_size + 1)))
			} else {
				sqlite3_result_int64(p_ctx, I64(1) + n_large + (i_row - i_small) / I64(n_size))
			}
		}
	}
}

struct LastValueCtx {
	pVal &Sqlite3_value
	nVal int
}

@[c:'last_valueStepFunc']
fn last_value_step_func(p_ctx &Sqlite3_context, n_arg int, ap_arg &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &LastValueCtx(0)

	p = &LastValueCtx(sqlite3_aggregate_context(p_ctx, int(sizeof(LastValueCtx))))
	if p {
		sqlite3_value_free(p.pVal)
		p.pVal = sqlite3_value_dup(ap_arg[0])
		if usize(p.pVal) == usize(0) {
			sqlite3_result_error_nomem(p_ctx)
		} else {
			p.nVal++
		}
	}
}

@[c:'last_valueInvFunc']
fn last_value_inv_func(p_ctx &Sqlite3_context, n_arg int, ap_arg &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &LastValueCtx(0)

	p = &LastValueCtx(sqlite3_aggregate_context(p_ctx, int(sizeof(LastValueCtx))))
	if p {
		p.nVal--
		if p.nVal == 0 {
			sqlite3_value_free(p.pVal)
			p.pVal = 0
		}
	}
}

@[c:'last_valueValueFunc']
fn last_value_value_func(p_ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	p := &LastValueCtx(0)
	p = &LastValueCtx(sqlite3_aggregate_context(p_ctx, 0))
	if !isnil(p) && !isnil(p.pVal) {
		sqlite3_result_value(p_ctx, p.pVal)
	}
}

@[c:'last_valueFinalizeFunc']
fn last_value_finalize_func(p_ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	p := &LastValueCtx(0)
	p = &LastValueCtx(sqlite3_aggregate_context(p_ctx, int(sizeof(LastValueCtx))))
	if !isnil(p) && !isnil(p.pVal) {
		sqlite3_result_value(p_ctx, p.pVal)
		sqlite3_value_free(p.pVal)
		p.pVal = 0
	}
}

@[c:'noopStepFunc']
fn noop_step_func(p &Sqlite3_context, n int, a &&Sqlite3_value) {
	c2v_gc_register_thread()
}

@[c:'noopValueFunc']
fn noop_value_func(p &Sqlite3_context) {
	c2v_gc_register_thread()
}

@[c:'sqlite3WindowFunctions']
fn sqlite3_window_functions() {
	if !sqlite3_window_functions_a_window_funcs_inited {
		c2v_static_init := [FuncDef{
			nArg: I16(0)
			funcFlags: u32((8388608 | 1 | 65536 | 0))
			pUserData: 0
			pNext: 0
			xSFunc: row_number_step_func
			xFinalize: row_number_value_func
			xValue: row_number_value_func
			xInverse: noop_step_func
			zName: unsafe { &row_numberName[0] }
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(0)
			funcFlags: u32((8388608 | 1 | 65536 | 0))
			pUserData: 0
			pNext: 0
			xSFunc: dense_rank_step_func
			xFinalize: dense_rank_value_func
			xValue: dense_rank_value_func
			xInverse: noop_step_func
			zName: unsafe { &dense_rankName[0] }
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(0)
			funcFlags: u32((8388608 | 1 | 65536 | 0))
			pUserData: 0
			pNext: 0
			xSFunc: rank_step_func
			xFinalize: rank_value_func
			xValue: rank_value_func
			xInverse: noop_step_func
			zName: unsafe { &rankName[0] }
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(0)
			funcFlags: u32((8388608 | 1 | 65536 | 0))
			pUserData: 0
			pNext: 0
			xSFunc: percent_rank_step_func
			xFinalize: percent_rank_value_func
			xValue: percent_rank_value_func
			xInverse: percent_rank_inv_func
			zName: unsafe { &percent_rankName[0] }
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(0)
			funcFlags: u32((8388608 | 1 | 65536 | 0))
			pUserData: 0
			pNext: 0
			xSFunc: cume_dist_step_func
			xFinalize: cume_dist_value_func
			xValue: cume_dist_value_func
			xInverse: cume_dist_inv_func
			zName: unsafe { &cume_distName[0] }
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32((8388608 | 1 | 65536 | 0))
			pUserData: 0
			pNext: 0
			xSFunc: ntile_step_func
			xFinalize: ntile_value_func
			xValue: ntile_value_func
			xInverse: ntile_inv_func
			zName: unsafe { &ntileName[0] }
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32((8388608 | 1 | 65536 | 0))
			pUserData: 0
			pNext: 0
			xSFunc: last_value_step_func
			xFinalize: last_value_finalize_func
			xValue: last_value_value_func
			xInverse: last_value_inv_func
			zName: unsafe { &last_valueName[0] }
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32((8388608 | 1 | 65536 | 0))
			pUserData: 0
			pNext: 0
			xSFunc: nth_value_step_func
			xFinalize: nth_value_finalize_func
			xValue: noop_value_func
			xInverse: noop_step_func
			zName: unsafe { &nth_valueName[0] }
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32((8388608 | 1 | 65536 | 0))
			pUserData: 0
			pNext: 0
			xSFunc: first_value_step_func
			xFinalize: first_value_finalize_func
			xValue: noop_value_func
			xInverse: noop_step_func
			zName: unsafe { &first_valueName[0] }
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32((8388608 | 1 | 65536 | 0))
			pUserData: 0
			pNext: 0
			xSFunc: noop_step_func
			xFinalize: noop_value_func
			xValue: noop_value_func
			xInverse: noop_step_func
			zName: unsafe { &leadName[0] }
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32((8388608 | 1 | 65536 | 0))
			pUserData: 0
			pNext: 0
			xSFunc: noop_step_func
			xFinalize: noop_value_func
			xValue: noop_value_func
			xInverse: noop_step_func
			zName: unsafe { &leadName[0] }
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(3)
			funcFlags: u32((8388608 | 1 | 65536 | 0))
			pUserData: 0
			pNext: 0
			xSFunc: noop_step_func
			xFinalize: noop_value_func
			xValue: noop_value_func
			xInverse: noop_step_func
			zName: unsafe { &leadName[0] }
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32((8388608 | 1 | 65536 | 0))
			pUserData: 0
			pNext: 0
			xSFunc: noop_step_func
			xFinalize: noop_value_func
			xValue: noop_value_func
			xInverse: noop_step_func
			zName: unsafe { &lagName[0] }
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32((8388608 | 1 | 65536 | 0))
			pUserData: 0
			pNext: 0
			xSFunc: noop_step_func
			xFinalize: noop_value_func
			xValue: noop_value_func
			xInverse: noop_step_func
			zName: unsafe { &lagName[0] }
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(3)
			funcFlags: u32((8388608 | 1 | 65536 | 0))
			pUserData: 0
			pNext: 0
			xSFunc: noop_step_func
			xFinalize: noop_value_func
			xValue: noop_value_func
			xInverse: noop_step_func
			zName: unsafe { &lagName[0] }
			u: FuncDef_u{}
		}]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_window_functions_a_window_funcs[c2v_i_0] = c2v_element_0
		}
		sqlite3_window_functions_a_window_funcs_inited = true
	}

	sqlite3_insert_builtin_funcs(&sqlite3_window_functions_a_window_funcs[0], 15)
}

@[c:'windowFind']
fn window_find(p_parse &Parse, p_list &Window, z_name &i8) &Window {
	p := &Window(0)
	for p = p_list; p; p = p.pNextWin {
		if sqlite3_str_ic_mp(p.zName, z_name) == 0 {
			break
		}
	}
	if usize(p) == usize(0) {
		sqlite3_error_msg(p_parse, c'no such window: %s', voidptr(z_name))
	}
	return p
}

@[c:'sqlite3WindowUpdate']
fn sqlite3_window_update(p_parse &Parse, p_list &Window, p_win &Window, p_func &FuncDef) {
	if !isnil(p_win.zName) && int(p_win.eFrmType) == 0 {
		p := window_find(p_parse, p_list, p_win.zName)
		if usize(p) == usize(0) {
			return
		}
		p_win.pPartition = sqlite3_expr_list_dup(p_parse.db, p.pPartition, 0)
		p_win.pOrderBy = sqlite3_expr_list_dup(p_parse.db, p.pOrderBy, 0)
		p_win.pStart = sqlite3_expr_dup(p_parse.db, p.pStart, 0)
		p_win.pEnd = sqlite3_expr_dup(p_parse.db, p.pEnd, 0)
		p_win.eStart = p.eStart
		p_win.eEnd = p.eEnd
		p_win.eFrmType = p.eFrmType
		p_win.eExclude = p.eExclude
	} else {
		sqlite3_window_chain(p_parse, p_win, p_list)
	}
	if (int(p_win.eFrmType) == 90) && (!isnil(p_win.pStart) || !isnil(p_win.pEnd)) && (usize(p_win.pOrderBy) == usize(0) || p_win.pOrderBy.nExpr != 1) {
		sqlite3_error_msg(p_parse, c'RANGE with offset PRECEDING/FOLLOWING requires one ORDER BY expression')
	} else if p_func.funcFlags & u32(65536) {
		db := p_parse.db
		if p_win.pFilter {
			sqlite3_error_msg(p_parse, c'FILTER clause may only be used with aggregate window functions')
		} else {
			a_up := [WindowUpdate{
				zFunc: unsafe { &row_numberName[0] }
				eFrmType: 77
				eStart: 91
				eEnd: 86
			}, WindowUpdate{
				zFunc: unsafe { &dense_rankName[0] }
				eFrmType: 90
				eStart: 91
				eEnd: 86
			}, WindowUpdate{
				zFunc: unsafe { &rankName[0] }
				eFrmType: 90
				eStart: 91
				eEnd: 86
			}, WindowUpdate{
				zFunc: unsafe { &percent_rankName[0] }
				eFrmType: 93
				eStart: 86
				eEnd: 91
			}, WindowUpdate{
				zFunc: unsafe { &cume_distName[0] }
				eFrmType: 93
				eStart: 87
				eEnd: 91
			}, WindowUpdate{
				zFunc: unsafe { &ntileName[0] }
				eFrmType: 77
				eStart: 86
				eEnd: 91
			}, WindowUpdate{
				zFunc: unsafe { &leadName[0] }
				eFrmType: 77
				eStart: 91
				eEnd: 91
			}, WindowUpdate{
				zFunc: unsafe { &lagName[0] }
				eFrmType: 77
				eStart: 91
				eEnd: 86
			}]

			i := 0
			for i = 0; i < 8; i++ {
				if usize(p_func.zName) == usize(a_up[i].zFunc) {
					sqlite3_expr_delete(db, p_win.pStart)
					sqlite3_expr_delete(db, p_win.pEnd)
					p_win.pStart = 0
					p_win.pEnd = p_win.pStart
					p_win.eFrmType = U8(a_up[i].eFrmType)
					p_win.eStart = U8(a_up[i].eStart)
					p_win.eEnd = U8(a_up[i].eEnd)
					p_win.eExclude = U8(0)
					if int(p_win.eStart) == 87 {
						p_win.pStart = sqlite3_expr_int32(db, 1)
					}
					break
				}
			}
		}
	}
	p_win.pWFunc = p_func
}

struct WindowRewrite {
	pWin       &Window
	pSrc       &SrcList
	pSub       &ExprList
	pTab       &Table
	pSubSelect &Select
}

@[c:'selectWindowRewriteExprCb']
fn select_window_rewrite_expr_cb(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	p := p_walker.u.pRewrite
	p_parse := p_walker.pParse
	if p.pSubSelect {
		if int(p_expr.op) != 168 {
			return 0
		} else {
			n_src := p.pSrc.nSrc
			i := 0
			for i = 0; i < n_src; i++ {
				if p_expr.iTable == c2v_at(&p.pSrc.a[0], isize(i)).iCursor {
					break
				}
			}
			if i == n_src {
				return 0
			}
		}
	}
	match p_expr.op {
		172 {
			if !((p_expr.flags & u32(16777216)) != u32(0)) {
				unsafe { goto c2v_switch_end_62
				 }
			} else {
				p_win := &Window(0)
				for p_win = p.pWin; p_win; p_win = p_win.pNextWin {
					if usize(p_expr.y.pWin) == usize(p_win) {
						return 1
					}
				}
			}

			unsafe { goto c2v_case_62_2
			 }
		}
		179, 169, 168 {
			c2v_case_62_2:
			i_col := -1
			if p_parse.db.mallocFailed {
				return 2
			}
			if p.pSub {
				i := 0
				for i = 0; i < p.pSub.nExpr; i++ {
					if 0 == sqlite3_expr_compare(unsafe { nil }, c2v_at(&p.pSub.a[0], isize(i)).pExpr, p_expr, -1) {
						i_col = i
						break
					}
				}
			}
			if i_col < 0 {
				p_dup := sqlite3_expr_dup(p_parse.db, p_expr, 0)
				if !isnil(p_dup) && int(p_dup.op) == 169 {
					p_dup.op = U8(172)
				}
				p.pSub = sqlite3_expr_list_append(p_parse, p.pSub, p_dup)
			}
			if p.pSub {
				f := int(p_expr.flags & u32(512))
				p_expr.flags |= u32(134217728)
				sqlite3_expr_delete(p_parse.db, p_expr)
				p_expr.flags &= ~u32(134217728)
				C.memset(voidptr(p_expr), 0, sizeof(Expr))
				p_expr.op = U8(168)
				p_expr.iColumn = YnVar((if i_col < 0 { p.pSub.nExpr - 1 } else { i_col }))
				p_expr.iTable = p.pWin.iEphCsr
				p_expr.y.pTab = p.pTab
				p_expr.flags = u32(f)
			}
			if p_parse.db.mallocFailed {
				return 2
			}
		}
		else {
		}
	}
	c2v_switch_end_62:

	return 0
}

@[c:'selectWindowRewriteSelectCb']
fn select_window_rewrite_select_cb(p_walker &Walker, p_select &Select) int {
	c2v_gc_register_thread()
	p := p_walker.u.pRewrite
	p_save := p.pSubSelect
	if usize(p_save) == usize(p_select) {
		return 0
	} else {
		p.pSubSelect = p_select
		sqlite3_walk_select(p_walker, p_select)
		p.pSubSelect = p_save
	}
	return 1
}

@[c:'selectWindowRewriteEList']
fn select_window_rewrite_el_ist(p_parse &Parse, p_win &Window, p_src &SrcList, pel_ist &ExprList, p_tab &Table, pp_sub &&ExprList) {
	s_walker := Walker{}
	s_rewrite := WindowRewrite{}
	C.memset(voidptr(&s_walker), 0, sizeof(Walker))
	C.memset(voidptr(&s_rewrite), 0, sizeof(WindowRewrite))
	s_rewrite.pSub = unsafe { *pp_sub }
	s_rewrite.pWin = p_win
	s_rewrite.pSrc = p_src
	s_rewrite.pTab = p_tab
	s_walker.pParse = p_parse
	s_walker.xExprCallback = select_window_rewrite_expr_cb
	s_walker.xSelectCallback = select_window_rewrite_select_cb
	s_walker.u.pRewrite = &s_rewrite
	sqlite3_walk_expr_list(&s_walker, pel_ist)
	unsafe { *pp_sub = s_rewrite.pSub }
}

@[c:'exprListAppendList']
fn expr_list_append_list(p_parse &Parse, p_list &ExprList, p_append &ExprList, b_int_to_null int) &ExprList {
	if p_append {
		i := 0
		n_init := if p_list { p_list.nExpr } else { 0 }
		for i = 0; i < p_append.nExpr; i++ {
			db := p_parse.db
			p_dup := sqlite3_expr_dup(db, c2v_at(&p_append.a[0], isize(i)).pExpr, 0)
			if db.mallocFailed {
				sqlite3_expr_delete(db, p_dup)
				break
			}
			if b_int_to_null {
				i_dummy := 0
				p_sub := &Expr(0)
				p_sub = sqlite3_expr_skip_collate_and_likely(p_dup)
				if sqlite3_expr_is_integer(p_sub, &i_dummy, unsafe { nil }) {
					p_sub.op = U8(122)
					p_sub.flags &= u32(~(2048 | 268435456 | 536870912))
					p_sub.u.zToken = 0
				}
			}
			p_list = sqlite3_expr_list_append(p_parse, p_list, p_dup)
			if p_list {
				mut __c2v_lhs_tmp_171 := unsafe { c2v_at(&p_list.a[0], isize(n_init + i)) }
				__c2v_lhs_tmp_171.fg.sortFlags = c2v_at(&p_append.a[0], isize(i)).fg.sortFlags
			}
		}
	}
	return p_list
}

@[c:'sqlite3WindowExtraAggFuncDepth']
fn sqlite3_window_extra_agg_func_depth(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	if int(p_expr.op) == 169 && int(p_expr.op2) >= p_walker.walkerDepth {
		p_expr.op2++
	}
	return 0
}

@[c:'disallowAggregatesInOrderByCb']
fn disallow_aggregates_in_order_by_cb(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	if int(p_expr.op) == 169 && usize(p_expr.pAggInfo) == usize(0) {
		sqlite3_error_msg(p_walker.pParse, c'misuse of aggregate: %s()', voidptr(p_expr.u.zToken))
	}
	return 0
}

@[c:'sqlite3WindowRewrite']
fn sqlite3_window_rewrite(p_parse &Parse, p &Select) int {
	rc := 0
	if !isnil(p.pWin) && usize(p.pPrior) == usize(0) && ((p.selFlags & u32(1048576)) == u32(0)) && (!(int(p_parse.eParseMode) >= 2)) {
		v := sqlite3_get_vdbe(p_parse)
		db := p_parse.db
		p_sub := unsafe { &Select(nil) }
		p_src := p.pSrc
		p_where := p.pWhere
		p_group_by := p.pGroupBy
		p_having := p.pHaving
		p_sort := unsafe { &ExprList(nil) }
		p_sublist := unsafe { &ExprList(nil) }
		pmw_in := p.pWin
		p_win := &Window(0)
		p_tab := &Table(0)
		w := Walker{}
		sel_flags := p.selFlags
		p_tab = sqlite3_db_malloc_zero(db, U64(sizeof(Table)))
		if usize(p_tab) == usize(0) {
			return sqlite3_error_to_parser(db, 7)
		}
		sqlite3_agg_info_persist_walker_init(&w, p_parse)
		sqlite3_walk_select(&w, p)
		if (p.selFlags & u32(8)) == u32(0) {
			w.xExprCallback = disallow_aggregates_in_order_by_cb
			w.xSelectCallback = 0
			sqlite3_walk_expr_list(&w, p.pOrderBy)
		}
		p.pSrc = 0
		p.pWhere = 0
		p.pGroupBy = 0
		p.pHaving = 0
		p.selFlags &= ~u32(8)
		p.selFlags |= u32(1048576)
		p_sort = expr_list_append_list(p_parse, unsafe { nil }, pmw_in.pPartition, 1)
		p_sort = expr_list_append_list(p_parse, p_sort, pmw_in.pOrderBy, 1)
		if !isnil(p_sort) && !isnil(p.pOrderBy) && p.pOrderBy.nExpr <= p_sort.nExpr {
			n_save := p_sort.nExpr
			p_sort.nExpr = p.pOrderBy.nExpr
			if sqlite3_expr_list_compare(p_sort, p.pOrderBy, -1) == 0 {
				sqlite3_expr_list_delete(db, p.pOrderBy)
				p.pOrderBy = 0
			}
			p_sort.nExpr = n_save
		}
		mut __c2v_postfix_value_45 := p_parse.nTab
		p_parse.nTab++
		pmw_in.iEphCsr = __c2v_postfix_value_45
		p_parse.nTab += 3
		select_window_rewrite_el_ist(p_parse, pmw_in, p_src, p.pEList, p_tab, &&ExprList(&&ExprList(c2v_address_of(&p_sublist))))
		select_window_rewrite_el_ist(p_parse, pmw_in, p_src, p.pOrderBy, p_tab, &&ExprList(&&ExprList(c2v_address_of(&p_sublist))))
		pmw_in.nBufferCol = (if p_sublist { p_sublist.nExpr } else { 0 })
		p_sublist = expr_list_append_list(p_parse, p_sublist, pmw_in.pPartition, 0)
		p_sublist = expr_list_append_list(p_parse, p_sublist, pmw_in.pOrderBy, 0)
		for p_win = pmw_in; p_win; p_win = p_win.pNextWin {
			p_args := &ExprList(0)
			p_args = p_win.pOwner.x.pList
			if p_win.pWFunc.funcFlags & u32(1048576) {
				select_window_rewrite_el_ist(p_parse, pmw_in, p_src, p_args, p_tab, &&ExprList(&&ExprList(c2v_address_of(&p_sublist))))
				p_win.iArgCol = (if p_sublist { p_sublist.nExpr } else { 0 })
				p_win.bExprArgs = U8(1)
			} else {
				p_win.iArgCol = (if p_sublist { p_sublist.nExpr } else { 0 })
				p_sublist = expr_list_append_list(p_parse, p_sublist, p_args, 0)
			}
			if p_win.pFilter {
				p_filter := sqlite3_expr_dup(db, p_win.pFilter, 0)
				p_sublist = sqlite3_expr_list_append(p_parse, p_sublist, p_filter)
			}
			p_win.regAccum = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			p_win.regResult = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			sqlite3_vdbe_add_op2(v, 77, 0, p_win.regAccum)
		}
		if usize(p_sublist) == usize(0) {
			p_sublist = sqlite3_expr_list_append(p_parse, unsafe { nil }, sqlite3_expr_int32(db, 0))
		}
		p_sub = sqlite3_select_new(p_parse, p_sublist, p_src, p_where, p_group_by, p_having, p_sort, u32(0), unsafe { nil })
		0
		p.pSrc = sqlite3_src_list_append(p_parse, unsafe { nil }, unsafe { nil }, unsafe { nil })
		if usize(p.pSrc) == usize(0) {
			sqlite3_select_delete(db, p_sub)
		} else if sqlite3_src_item_attach_subquery(p_parse, unsafe { &p.pSrc.a[0] + 0 }, p_sub, 0) {
			p_tab2 := &Table(0)
			mut __c2v_lhs_tmp_172 := c2v_at(&p.pSrc.a[0], isize(0))
			__c2v_lhs_tmp_172.fg.isCorrelated = u32(1)
			sqlite3_src_list_assign_cursors(p_parse, p.pSrc)
			p_sub.selFlags |= u32(64 | 134217728)
			p_tab2 = sqlite3_result_set_of_select(p_parse, p_sub, i8(64))
			p_sub.selFlags |= (sel_flags & u32(8))
			if usize(p_tab2) == usize(0) {
				rc = 7
			} else {
				C.memcpy(voidptr(p_tab), voidptr(p_tab2), sizeof(Table))
				p_tab.tabFlags |= u32(16384)
				mut __c2v_lhs_tmp_173 := c2v_at(&p.pSrc.a[0], isize(0))
				__c2v_lhs_tmp_173.pSTab = p_tab
				p_tab = p_tab2
				C.memset(voidptr(&w), 0, sizeof(w))
				w.xExprCallback = sqlite3_window_extra_agg_func_depth
				w.xSelectCallback = sqlite3_walker_depth_increase
				w.xSelectCallback2 = sqlite3_walker_depth_decrease
				sqlite3_walk_select(&w, p_sub)
			}
		}
		if db.mallocFailed {
			rc = 7
		}
		sqlite3_parser_add_cleanup(p_parse, sqlite3_db_free, voidptr(p_tab))
	}
	return rc
}

@[c:'sqlite3WindowUnlinkFromSelect']
fn sqlite3_window_unlink_from_select(p &Window) {
	if p.ppThis {
		unsafe { *p.ppThis = p.pNextWin }
		if p.pNextWin {
			p.pNextWin.ppThis = p.ppThis
		}
		p.ppThis = 0
	}
}

@[c:'sqlite3WindowDelete']
fn sqlite3_window_delete(db &Sqlite3, p &Window) {
	if p {
		sqlite3_window_unlink_from_select(p)
		sqlite3_expr_delete(db, p.pFilter)
		sqlite3_expr_list_delete(db, p.pPartition)
		sqlite3_expr_list_delete(db, p.pOrderBy)
		sqlite3_expr_delete(db, p.pEnd)
		sqlite3_expr_delete(db, p.pStart)
		sqlite3_db_free(db, voidptr(p.zName))
		sqlite3_db_free(db, voidptr(p.zBase))
		sqlite3_db_free(db, voidptr(p))
	}
}

@[c:'sqlite3WindowListDelete']
fn sqlite3_window_list_delete(db &Sqlite3, p &Window) {
	for p {
		p_next := p.pNextWin
		sqlite3_window_delete(db, p)
		p = p_next
	}
}

@[c:'sqlite3WindowOffsetExpr']
fn sqlite3_window_offset_expr(p_parse &Parse, p_expr &Expr) &Expr {
	if 0 == sqlite3_expr_is_constant(unsafe { nil }, p_expr) {
		if (int(p_parse.eParseMode) >= 2) {
			sqlite3_rename_expr_unmap(p_parse, p_expr)
		}
		sqlite3_expr_delete(p_parse.db, p_expr)
		p_expr = sqlite3_expr_alloc(p_parse.db, 122, unsafe { nil }, 0)
	}
	return p_expr
}

@[c:'sqlite3WindowAlloc']
fn sqlite3_window_alloc(p_parse &Parse, e_type int, e_start int, p_start &Expr, e_end int, p_end &Expr, e_exclude U8) &Window {
	p_win := unsafe { &Window(nil) }
	b_implicit_frame := 0
	if e_type == 0 {
		b_implicit_frame = 1
		e_type = 90
	}
	if (e_start == 86 && e_end == 89) || (e_start == 87 && (e_end == 89 || e_end == 86)) {
		sqlite3_error_msg(p_parse, c'unsupported frame specification')
		unsafe { goto windowAllocErr
		 }
	}
	p_win = &Window(sqlite3_db_malloc_zero(p_parse.db, U64(sizeof(Window))))
	if usize(p_win) == usize(0) {
		unsafe { goto windowAllocErr
		 }
	}
	p_win.eFrmType = U8(e_type)
	p_win.eStart = U8(e_start)
	p_win.eEnd = U8(e_end)
	if int(e_exclude) == 0 && ((p_parse.db.dbOptFlags & u32(2)) != u32(0)) {
		e_exclude = U8(67)
	}
	p_win.eExclude = e_exclude
	p_win.bImplicitFrame = U8(b_implicit_frame)
	p_win.pEnd = sqlite3_window_offset_expr(p_parse, p_end)
	p_win.pStart = sqlite3_window_offset_expr(p_parse, p_start)
	return p_win
	windowAllocErr:
	sqlite3_expr_delete(p_parse.db, p_end)
	sqlite3_expr_delete(p_parse.db, p_start)
	return unsafe { nil }
}

@[c:'sqlite3WindowAssemble']
fn sqlite3_window_assemble(p_parse &Parse, p_win &Window, p_partition &ExprList, p_order_by &ExprList, p_base &Token) &Window {
	if p_win {
		p_win.pPartition = p_partition
		p_win.pOrderBy = p_order_by
		if p_base {
			p_win.zBase = sqlite3_db_str_nd_up(p_parse.db, p_base.z, U64(p_base.n))
		}
	} else {
		sqlite3_expr_list_delete(p_parse.db, p_partition)
		sqlite3_expr_list_delete(p_parse.db, p_order_by)
	}
	return p_win
}

@[c:'sqlite3WindowChain']
fn sqlite3_window_chain(p_parse &Parse, p_win &Window, p_list &Window) {
	if p_win.zBase {
		db := p_parse.db
		p_exist := window_find(p_parse, p_list, p_win.zBase)
		if p_exist {
			z_err := unsafe { &i8(nil) }
			if p_win.pPartition {
				z_err = c'PARTITION clause'
			} else if !isnil(p_exist.pOrderBy) && !isnil(p_win.pOrderBy) {
				z_err = c'ORDER BY clause'
			} else if int(p_exist.bImplicitFrame) == 0 {
				z_err = c'frame specification'
			}
			if z_err {
				sqlite3_error_msg(p_parse, c'cannot override %s of window: %s', voidptr(z_err), voidptr(p_win.zBase))
			} else {
				p_win.pPartition = sqlite3_expr_list_dup(db, p_exist.pPartition, 0)
				if p_exist.pOrderBy {
					p_win.pOrderBy = sqlite3_expr_list_dup(db, p_exist.pOrderBy, 0)
				}
				sqlite3_db_free(db, voidptr(p_win.zBase))
				p_win.zBase = 0
			}
		}
	}
}

@[c:'sqlite3WindowAttach']
fn sqlite3_window_attach(p_parse &Parse, p &Expr, p_win &Window) {
	if p {
		p.y.pWin = p_win
		p.flags |= u32((16777216 | 131072))
		p_win.pOwner = p
		if (p.flags & u32(4)) && int(p_win.eFrmType) != 167 {
			sqlite3_error_msg(p_parse, c'DISTINCT is not supported for window functions')
		}
	} else {
		sqlite3_window_delete(p_parse.db, p_win)
	}
}

@[c:'sqlite3WindowLink']
fn sqlite3_window_link(p_sel &Select, p_win &Window) {
	if p_sel {
		if usize(0) == usize(p_sel.pWin) || 0 == sqlite3_window_compare(unsafe { nil }, p_sel.pWin, p_win, 0) {
			p_win.pNextWin = p_sel.pWin
			if p_sel.pWin {
				p_sel.pWin.ppThis = &p_win.pNextWin
			}
			p_sel.pWin = p_win
			p_win.ppThis = &p_sel.pWin
		} else {
			if sqlite3_expr_list_compare(p_win.pPartition, p_sel.pWin.pPartition, -1) {
				p_sel.selFlags |= u32(33554432)
			}
		}
	}
}

@[c:'sqlite3WindowCompare']
fn sqlite3_window_compare(p_parse &Parse, p1 &Window, p2 &Window, b_filter int) int {
	res := 0
	if (usize(p1) == usize(0)) || (usize(p2) == usize(0)) {
		return 1
	}
	if int(p1.eFrmType) != int(p2.eFrmType) {
		return 1
	}
	if int(p1.eStart) != int(p2.eStart) {
		return 1
	}
	if int(p1.eEnd) != int(p2.eEnd) {
		return 1
	}
	if int(p1.eExclude) != int(p2.eExclude) {
		return 1
	}
	if sqlite3_expr_compare(p_parse, p1.pStart, p2.pStart, -1) {
		return 1
	}
	if sqlite3_expr_compare(p_parse, p1.pEnd, p2.pEnd, -1) {
		return 1
	}
	res = sqlite3_expr_list_compare(p1.pPartition, p2.pPartition, -1)
	if res {
		return res
	}
	res = sqlite3_expr_list_compare(p1.pOrderBy, p2.pOrderBy, -1)
	if res {
		return res
	}
	if b_filter {
		res = sqlite3_expr_compare(p_parse, p1.pFilter, p2.pFilter, -1)
		if res {
			return res
		}
	}
	return 0
}

@[c:'sqlite3WindowCodeInit']
fn sqlite3_window_code_init(p_parse &Parse, p_select &Select) {
	p_win := &Window(0)
	n_eph_expr := 0
	pmw_in := &Window(0)
	v := &Vdbe(0)
	n_eph_expr = c2v_at(&p_select.pSrc.a[0], isize(0)).u4.pSubq.pSelect.pEList.nExpr
	pmw_in = p_select.pWin
	v = sqlite3_get_vdbe(p_parse)
	sqlite3_vdbe_add_op2(v, 120, pmw_in.iEphCsr, n_eph_expr)
	sqlite3_vdbe_add_op2(v, 117, pmw_in.iEphCsr + 1, pmw_in.iEphCsr)
	sqlite3_vdbe_add_op2(v, 117, pmw_in.iEphCsr + 2, pmw_in.iEphCsr)
	sqlite3_vdbe_add_op2(v, 117, pmw_in.iEphCsr + 3, pmw_in.iEphCsr)
	if pmw_in.pPartition {
		n_expr := pmw_in.pPartition.nExpr
		pmw_in.regPart = p_parse.nMem + 1
		p_parse.nMem += n_expr
		sqlite3_vdbe_add_op3(v, 77, 0, pmw_in.regPart, pmw_in.regPart + n_expr - 1)
	}
	pmw_in.regOne = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	sqlite3_vdbe_add_op2(v, 73, 1, pmw_in.regOne)
	if pmw_in.eExclude {
		pmw_in.regStartRowid = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		pmw_in.regEndRowid = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		mut __c2v_postfix_value_46 := p_parse.nTab
		p_parse.nTab++
		pmw_in.csrApp = __c2v_postfix_value_46
		sqlite3_vdbe_add_op2(v, 73, 1, pmw_in.regStartRowid)
		sqlite3_vdbe_add_op2(v, 73, 0, pmw_in.regEndRowid)
		sqlite3_vdbe_add_op2(v, 117, pmw_in.csrApp, pmw_in.iEphCsr)
		return
	}
	for p_win = pmw_in; p_win; p_win = p_win.pNextWin {
		p := p_win.pWFunc
		if (p.funcFlags & u32(4096)) && int(p_win.eStart) != 91 {
			p_list := &ExprList(0)
			p_key_info := &KeyInfo(0)
			p_list = p_win.pOwner.x.pList
			p_key_info = sqlite3_key_info_from_expr_list(p_parse, p_list, 0, 0)
			mut __c2v_postfix_value_47 := p_parse.nTab
			p_parse.nTab++
			p_win.csrApp = __c2v_postfix_value_47
			p_win.regApp = p_parse.nMem + 1
			p_parse.nMem += 3
			if !isnil(p_key_info) && int(p_win.pWFunc.zName[1]) == i8(`i`) {
				p_key_info.aSortFlags[0] = U8(1)
			}
			sqlite3_vdbe_add_op2(v, 120, p_win.csrApp, 2)
			sqlite3_vdbe_append_p4(v, voidptr(p_key_info), (-9))
			sqlite3_vdbe_add_op2(v, 73, 0, p_win.regApp + 1)
		} else if usize(p.zName) == usize(unsafe { &nth_valueName[0] }) || usize(p.zName) == usize(unsafe { &first_valueName[0] }) {
			p_win.regApp = p_parse.nMem + 1
			mut __c2v_postfix_value_48 := p_parse.nTab
			p_parse.nTab++
			p_win.csrApp = __c2v_postfix_value_48
			p_parse.nMem += 2
			sqlite3_vdbe_add_op2(v, 117, p_win.csrApp, pmw_in.iEphCsr)
		} else if usize(p.zName) == usize(unsafe { &leadName[0] }) || usize(p.zName) == usize(unsafe { &lagName[0] }) {
			mut __c2v_postfix_value_49 := p_parse.nTab
			p_parse.nTab++
			p_win.csrApp = __c2v_postfix_value_49
			sqlite3_vdbe_add_op2(v, 117, p_win.csrApp, pmw_in.iEphCsr)
		}
	}
}

@[c:'windowCheckValue']
fn window_check_value(p_parse &Parse, reg int, e_cond int) {
	if !window_check_value_az_err_inited {
		c2v_static_init := [c'frame starting offset must be a non-negative integer',
			c'frame ending offset must be a non-negative integer',
			c'second argument to nth_value must be a positive integer',
			c'frame starting offset must be a non-negative number',
			c'frame ending offset must be a non-negative number']
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			window_check_value_az_err[c2v_i_0] = c2v_element_0
		}
		window_check_value_az_err_inited = true
	}

	if !window_check_value_a_op_inited {
		c2v_static_init := [58, 58, 55, 58, 58]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			window_check_value_a_op[c2v_i_0] = c2v_element_0
		}
		window_check_value_a_op_inited = true
	}

	v := sqlite3_get_vdbe(p_parse)
	reg_zero := sqlite3_get_temp_reg(p_parse)
	sqlite3_vdbe_add_op2(v, 73, 0, reg_zero)
	if e_cond >= 3 {
		reg_string := sqlite3_get_temp_reg(p_parse)
		sqlite3_vdbe_add_op4(v, 118, 0, reg_string, 0, c'', (-1))
		sqlite3_vdbe_add_op3(v, 58, reg_string, sqlite3_vdbe_current_addr(v) + 2, reg)
		sqlite3_vdbe_change_p5(v, U16(67 | 16))
		0
		0
		0
	} else {
		sqlite3_vdbe_add_op2(v, 13, reg, sqlite3_vdbe_current_addr(v) + 2)
		0
		0
		0
		0
	}
	sqlite3_vdbe_add_op3(v, window_check_value_a_op[e_cond], reg_zero, sqlite3_vdbe_current_addr(v) + 2, reg)
	sqlite3_vdbe_change_p5(v, U16(67))
	0
	0
	0
	0
	0
	sqlite3_may_abort(p_parse)
	sqlite3_vdbe_add_op2(v, 72, 1, 2)
	sqlite3_vdbe_append_p4(v, voidptr(window_check_value_az_err[e_cond]), (-1))
	sqlite3_release_temp_reg(p_parse, reg_zero)
}

@[c:'windowArgCount']
fn window_arg_count(p_win &Window) int {
	p_list := &ExprList(0)
	p_list = p_win.pOwner.x.pList
	return if p_list { p_list.nExpr } else { 0 }
}

struct WindowCsrAndReg {
	csr int
	reg int
}

struct WindowCodeArg {
	pParse    &Parse
	pMWin     &Window
	pVdbe     &Vdbe
	addrGosub int
	regGosub  int
	regArg    int
	eDelete   int
	regRowid  int
	start     WindowCsrAndReg
	current   WindowCsrAndReg
	end       WindowCsrAndReg
}

@[c:'windowReadPeerValues']
fn window_read_peer_values(p &WindowCodeArg, csr int, reg int) {
	pmw_in := p.pMWin
	p_order_by := pmw_in.pOrderBy
	if p_order_by {
		v := sqlite3_get_vdbe(p.pParse)
		p_part := pmw_in.pPartition
		i_col_off := pmw_in.nBufferCol + (if p_part { p_part.nExpr } else { 0 })
		i := 0
		for i = 0; i < p_order_by.nExpr; i++ {
			sqlite3_vdbe_add_op3(v, 96, csr, i_col_off + i, reg + i)
		}
	}
}

@[c:'windowAggStep']
fn window_agg_step(p &WindowCodeArg, pmw_in &Window, csr int, b_inverse int, reg int) {
	p_parse := p.pParse
	v := sqlite3_get_vdbe(p_parse)
	p_win := &Window(0)
	for p_win = pmw_in; p_win; p_win = p_win.pNextWin {
		p_func := p_win.pWFunc
		reg_arg := 0
		n_arg := if int(p_win.bExprArgs) { 0 } else { window_arg_count(p_win) }
		i := 0
		addr_if := 0
		for i = 0; i < n_arg; i++ {
			if i != 1 || usize(p_func.zName) != usize(unsafe { &nth_valueName[0] }) {
				sqlite3_vdbe_add_op3(v, 96, csr, p_win.iArgCol + i, reg + i)
			} else {
				sqlite3_vdbe_add_op3(v, 96, pmw_in.iEphCsr, p_win.iArgCol + i, reg + i)
			}
		}
		reg_arg = reg
		if p_win.pFilter {
			reg_tmp := 0
			reg_tmp = sqlite3_get_temp_reg(p_parse)
			sqlite3_vdbe_add_op3(v, 96, csr, p_win.iArgCol + n_arg, reg_tmp)
			addr_if = sqlite3_vdbe_add_op3(v, 17, reg_tmp, 0, 1)
			0
			sqlite3_release_temp_reg(p_parse, reg_tmp)
		}
		if pmw_in.regStartRowid == 0 && (p_func.funcFlags & u32(4096)) && (int(p_win.eStart) != 91) {
			addr_is_null := sqlite3_vdbe_add_op1(v, 51, reg_arg)
			0
			if b_inverse == 0 {
				sqlite3_vdbe_add_op2(v, 88, p_win.regApp + 1, 1)
				sqlite3_vdbe_add_op2(v, 83, reg_arg, p_win.regApp)
				sqlite3_vdbe_add_op3(v, 99, p_win.regApp, 2, p_win.regApp + 2)
				sqlite3_vdbe_add_op2(v, 140, p_win.csrApp, p_win.regApp + 2)
			} else {
				sqlite3_vdbe_add_op4_int(v, 23, p_win.csrApp, 0, reg_arg, 1)
				0
				sqlite3_vdbe_add_op1(v, 132, p_win.csrApp)
				sqlite3_vdbe_jump_here(v, sqlite3_vdbe_current_addr(v) - 2)
			}
			sqlite3_vdbe_jump_here(v, addr_is_null)
		} else if p_win.regApp {
			sqlite3_vdbe_add_op2(v, 88, p_win.regApp + 1 - b_inverse, 1)
		} else if p_func.xSFunc != noop_step_func {
			if p_win.bExprArgs {
				i_op := sqlite3_vdbe_current_addr(v)
				i_end := 0
				n_arg = p_win.pOwner.x.pList.nExpr
				reg_arg = sqlite3_get_temp_range(p_parse, n_arg)
				sqlite3_expr_code_expr_list(p_parse, p_win.pOwner.x.pList, reg_arg, 0, U8(0))
				for i_end = sqlite3_vdbe_current_addr(v); i_op < i_end; i_op++ {
					p_op := sqlite3_vdbe_get_op(v, i_op)
					if int(p_op.opcode) == 96 && p_op.p1 == pmw_in.iEphCsr {
						p_op.p1 = csr
					}
				}
			}
			if p_func.funcFlags & u32(32) {
				p_coll := &CollSeq(0)
				p_coll = sqlite3_expr_nn_coll_seq(p_parse, c2v_at(&p_win.pOwner.x.pList.a[0], isize(0)).pExpr)
				sqlite3_vdbe_add_op4(v, 87, 0, 0, 0, &i8(voidptr(p_coll)), (-2))
			}
			sqlite3_vdbe_add_op3(v, if b_inverse { 163 } else { 164 }, b_inverse, reg_arg, p_win.regAccum)
			sqlite3_vdbe_append_p4(v, voidptr(p_func), (-8))
			sqlite3_vdbe_change_p5(v, U16(n_arg))
			if p_win.bExprArgs {
				sqlite3_release_temp_range(p_parse, reg_arg, n_arg)
			}
		}
		if addr_if {
			sqlite3_vdbe_jump_here(v, addr_if)
		}
	}
}

@[c:'windowAggFinal']
fn window_agg_final(p &WindowCodeArg, b_fin int) {
	p_parse := p.pParse
	pmw_in := p.pMWin
	v := sqlite3_get_vdbe(p_parse)
	p_win := &Window(0)
	for p_win = pmw_in; p_win; p_win = p_win.pNextWin {
		if pmw_in.regStartRowid == 0 && (p_win.pWFunc.funcFlags & u32(4096)) && (int(p_win.eStart) != 91) {
			sqlite3_vdbe_add_op2(v, 77, 0, p_win.regResult)
			sqlite3_vdbe_add_op1(v, 32, p_win.csrApp)
			0
			sqlite3_vdbe_add_op3(v, 96, p_win.csrApp, 0, p_win.regResult)
			sqlite3_vdbe_jump_here(v, sqlite3_vdbe_current_addr(v) - 2)
		} else if p_win.regApp {
		} else {
			n_arg := window_arg_count(p_win)
			if b_fin {
				sqlite3_vdbe_add_op2(v, 167, p_win.regAccum, n_arg)
				sqlite3_vdbe_append_p4(v, voidptr(p_win.pWFunc), (-8))
				sqlite3_vdbe_add_op2(v, 82, p_win.regAccum, p_win.regResult)
				sqlite3_vdbe_add_op2(v, 77, 0, p_win.regAccum)
			} else {
				sqlite3_vdbe_add_op3(v, 166, p_win.regAccum, n_arg, p_win.regResult)
				sqlite3_vdbe_append_p4(v, voidptr(p_win.pWFunc), (-8))
			}
		}
	}
}

@[c:'windowFullScan']
fn window_full_scan(p &WindowCodeArg) {
	p_win := &Window(0)
	p_parse := p.pParse
	pmw_in := p.pMWin
	v := p.pVdbe
	reg_cr_owid := 0
	reg_cp_eer := 0
	reg_rowid := 0
	reg_peer := 0
	n_peer := 0
	lbl_next := 0
	lbl_brk := 0
	addr_next := 0
	csr := 0
	0
	csr = pmw_in.csrApp
	n_peer = (if pmw_in.pOrderBy { pmw_in.pOrderBy.nExpr } else { 0 })
	lbl_next = sqlite3_vdbe_make_label(p_parse)
	lbl_brk = sqlite3_vdbe_make_label(p_parse)
	reg_cr_owid = sqlite3_get_temp_reg(p_parse)
	reg_rowid = sqlite3_get_temp_reg(p_parse)
	if n_peer {
		reg_cp_eer = sqlite3_get_temp_range(p_parse, n_peer)
		reg_peer = sqlite3_get_temp_range(p_parse, n_peer)
	}
	sqlite3_vdbe_add_op2(v, 137, pmw_in.iEphCsr, reg_cr_owid)
	window_read_peer_values(p, pmw_in.iEphCsr, reg_cp_eer)
	for p_win = pmw_in; p_win; p_win = p_win.pNextWin {
		sqlite3_vdbe_add_op2(v, 77, 0, p_win.regAccum)
	}
	sqlite3_vdbe_add_op3(v, 23, csr, lbl_brk, pmw_in.regStartRowid)
	0
	addr_next = sqlite3_vdbe_current_addr(v)
	sqlite3_vdbe_add_op2(v, 137, csr, reg_rowid)
	sqlite3_vdbe_add_op3(v, 55, pmw_in.regEndRowid, lbl_brk, reg_rowid)
	0
	if int(pmw_in.eExclude) == 86 {
		sqlite3_vdbe_add_op3(v, 54, reg_cr_owid, lbl_next, reg_rowid)
		0
	} else if int(pmw_in.eExclude) != 67 {
		addr := 0
		addr_eq := 0
		p_key_info := unsafe { &KeyInfo(nil) }
		if pmw_in.pOrderBy {
			p_key_info = sqlite3_key_info_from_expr_list(p_parse, pmw_in.pOrderBy, 0, 0)
		}
		if int(pmw_in.eExclude) == 95 {
			addr_eq = sqlite3_vdbe_add_op3(v, 54, reg_cr_owid, 0, reg_rowid)
			0
		}
		if p_key_info {
			window_read_peer_values(p, csr, reg_peer)
			sqlite3_vdbe_add_op3(v, 92, reg_peer, reg_cp_eer, n_peer)
			sqlite3_vdbe_append_p4(v, voidptr(p_key_info), (-9))
			addr = sqlite3_vdbe_current_addr(v) + 1
			sqlite3_vdbe_add_op3(v, 14, addr, lbl_next, addr)
			0
		} else {
			sqlite3_vdbe_add_op2(v, 9, 0, lbl_next)
		}
		if addr_eq {
			sqlite3_vdbe_jump_here(v, addr_eq)
		}
	}
	window_agg_step(p, pmw_in, csr, 0, p.regArg)
	sqlite3_vdbe_resolve_label(v, lbl_next)
	sqlite3_vdbe_add_op2(v, 40, csr, addr_next)
	0
	sqlite3_vdbe_jump_here(v, addr_next - 1)
	sqlite3_vdbe_jump_here(v, addr_next + 1)
	sqlite3_release_temp_reg(p_parse, reg_rowid)
	sqlite3_release_temp_reg(p_parse, reg_cr_owid)
	if n_peer {
		sqlite3_release_temp_range(p_parse, reg_peer, n_peer)
		sqlite3_release_temp_range(p_parse, reg_cp_eer, n_peer)
	}
	window_agg_final(p, 1)
	0
}

@[c:'windowReturnOneRow']
fn window_return_one_row(p &WindowCodeArg) {
	pmw_in := p.pMWin
	v := p.pVdbe
	if pmw_in.regStartRowid {
		window_full_scan(p)
	} else {
		p_parse := p.pParse
		p_win := &Window(0)
		for p_win = pmw_in; p_win; p_win = p_win.pNextWin {
			p_func := p_win.pWFunc
			if usize(p_func.zName) == usize(unsafe { &nth_valueName[0] }) || usize(p_func.zName) == usize(unsafe { &first_valueName[0] }) {
				csr := p_win.csrApp
				lbl := sqlite3_vdbe_make_label(p_parse)
				tmp_reg := sqlite3_get_temp_reg(p_parse)
				sqlite3_vdbe_add_op2(v, 77, 0, p_win.regResult)
				if usize(p_func.zName) == usize(unsafe { &nth_valueName[0] }) {
					sqlite3_vdbe_add_op3(v, 96, pmw_in.iEphCsr, p_win.iArgCol + 1, tmp_reg)
					window_check_value(p_parse, tmp_reg, 2)
				} else {
					sqlite3_vdbe_add_op2(v, 73, 1, tmp_reg)
				}
				sqlite3_vdbe_add_op3(v, 107, tmp_reg, p_win.regApp, tmp_reg)
				sqlite3_vdbe_add_op3(v, 55, p_win.regApp + 1, lbl, tmp_reg)
				0
				sqlite3_vdbe_add_op3(v, 30, csr, 0, tmp_reg)
				0
				sqlite3_vdbe_add_op3(v, 96, csr, p_win.iArgCol, p_win.regResult)
				sqlite3_vdbe_resolve_label(v, lbl)
				sqlite3_release_temp_reg(p_parse, tmp_reg)
			} else if usize(p_func.zName) == usize(unsafe { &leadName[0] }) || usize(p_func.zName) == usize(unsafe { &lagName[0] }) {
				n_arg := p_win.pOwner.x.pList.nExpr
				csr := p_win.csrApp
				lbl := sqlite3_vdbe_make_label(p_parse)
				tmp_reg := sqlite3_get_temp_reg(p_parse)
				i_eph := pmw_in.iEphCsr
				if n_arg < 3 {
					sqlite3_vdbe_add_op2(v, 77, 0, p_win.regResult)
				} else {
					sqlite3_vdbe_add_op3(v, 96, i_eph, p_win.iArgCol + 2, p_win.regResult)
				}
				sqlite3_vdbe_add_op2(v, 137, i_eph, tmp_reg)
				if n_arg < 2 {
					val := (if usize(p_func.zName) == usize(unsafe { &leadName[0] }) { 1 } else { -1 })
					sqlite3_vdbe_add_op2(v, 88, tmp_reg, val)
				} else {
					op := (if usize(p_func.zName) == usize(unsafe { &leadName[0] }) {
						107
					} else {
						108
					})
					tmp_reg2 := sqlite3_get_temp_reg(p_parse)
					sqlite3_vdbe_add_op3(v, 96, i_eph, p_win.iArgCol + 1, tmp_reg2)
					sqlite3_vdbe_add_op3(v, op, tmp_reg2, tmp_reg, tmp_reg)
					sqlite3_release_temp_reg(p_parse, tmp_reg2)
				}
				sqlite3_vdbe_add_op3(v, 30, csr, lbl, tmp_reg)
				0
				sqlite3_vdbe_add_op3(v, 96, csr, p_win.iArgCol, p_win.regResult)
				sqlite3_vdbe_resolve_label(v, lbl)
				sqlite3_release_temp_reg(p_parse, tmp_reg)
			}
		}
	}
	sqlite3_vdbe_add_op2(v, 10, p.regGosub, p.addrGosub)
}

@[c:'windowInitAccum']
fn window_init_accum(p_parse &Parse, pmw_in &Window) int {
	v := sqlite3_get_vdbe(p_parse)
	reg_arg := 0
	n_arg := 0
	p_win := &Window(0)
	for p_win = pmw_in; p_win; p_win = p_win.pNextWin {
		p_func := p_win.pWFunc
		sqlite3_vdbe_add_op2(v, 77, 0, p_win.regAccum)
		n_arg = (if n_arg > window_arg_count(p_win) { n_arg } else { window_arg_count(p_win) })
		if pmw_in.regStartRowid == 0 {
			if usize(p_func.zName) == usize(unsafe { &nth_valueName[0] }) || usize(p_func.zName) == usize(unsafe { &first_valueName[0] }) {
				sqlite3_vdbe_add_op2(v, 73, 0, p_win.regApp)
				sqlite3_vdbe_add_op2(v, 73, 0, p_win.regApp + 1)
			}
			if (p_func.funcFlags & u32(4096)) && p_win.csrApp {
				sqlite3_vdbe_add_op1(v, 148, p_win.csrApp)
				sqlite3_vdbe_add_op2(v, 73, 0, p_win.regApp + 1)
			}
		}
	}
	reg_arg = p_parse.nMem + 1
	p_parse.nMem += n_arg
	return reg_arg
}

@[c:'windowCacheFrame']
fn window_cache_frame(pmw_in &Window) int {
	p_win := &Window(0)
	if pmw_in.regStartRowid {
		return 1
	}
	for p_win = pmw_in; p_win; p_win = p_win.pNextWin {
		p_func := p_win.pWFunc
		mut __c2v_condition_139 := false
		mut __c2v_condition_140 := false
		__c2v_condition_140 = (usize(p_func.zName) == usize(unsafe { &nth_valueName[0] }))
		__c2v_condition_139 = __c2v_condition_140
		if !__c2v_condition_139 {
			mut __c2v_condition_141 := false
			__c2v_condition_141 = (usize(p_func.zName) == usize(unsafe { &first_valueName[0] }))
			__c2v_condition_139 = __c2v_condition_141
		}
		if !__c2v_condition_139 {
			mut __c2v_condition_142 := false
			__c2v_condition_142 = (usize(p_func.zName) == usize(unsafe { &leadName[0] }))
			__c2v_condition_139 = __c2v_condition_142
		}
		if !__c2v_condition_139 {
			mut __c2v_condition_143 := false
			__c2v_condition_143 = (usize(p_func.zName) == usize(unsafe { &lagName[0] }))
			__c2v_condition_139 = __c2v_condition_143
		}
		if __c2v_condition_139 {
			return 1
		}
	}
	return 0
}

@[c:'windowIfNewPeer']
fn window_if_new_peer(p_parse &Parse, p_order_by &ExprList, reg_new int, reg_old int, addr int) {
	v := sqlite3_get_vdbe(p_parse)
	if p_order_by {
		n_val := p_order_by.nExpr
		p_key_info := sqlite3_key_info_from_expr_list(p_parse, p_order_by, 0, 0)
		sqlite3_vdbe_add_op3(v, 92, reg_old, reg_new, n_val)
		sqlite3_vdbe_append_p4(v, voidptr(p_key_info), (-9))
		sqlite3_vdbe_add_op3(v, 14, sqlite3_vdbe_current_addr(v) + 1, addr, sqlite3_vdbe_current_addr(v) + 1)
		0
		sqlite3_vdbe_add_op3(v, 82, reg_new, reg_old, n_val - 1)
	} else {
		sqlite3_vdbe_add_op2(v, 9, 0, addr)
	}
}

@[c:'windowCodeRangeTest']
fn window_code_range_test(p &WindowCodeArg, op int, csr1 int, reg_val int, csr2 int, lbl int) {
	p_parse := p.pParse
	v := sqlite3_get_vdbe(p_parse)
	p_order_by := p.pMWin.pOrderBy
	reg1 := sqlite3_get_temp_reg(p_parse)
	reg2 := sqlite3_get_temp_reg(p_parse)
	reg_string := c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	arith := 107
	addr_ge := 0
	addr_done := sqlite3_vdbe_make_label(p_parse)
	p_coll := &CollSeq(0)
	window_read_peer_values(p, csr1, reg1)
	window_read_peer_values(p, csr2, reg2)
	if int(c2v_at(&p_order_by.a[0], isize(0)).fg.sortFlags) & 1 {
		match op {
			58 {
				op = 56
			}
			55 {
				op = 57
			}
			else {
				op = 58
			}
		}

		arith = 108
	}
	0
	if int(c2v_at(&p_order_by.a[0], isize(0)).fg.sortFlags) & 2 {
		addr := sqlite3_vdbe_add_op1(v, 52, reg1)
		0
		match op {
			58 {
				sqlite3_vdbe_add_op2(v, 9, 0, lbl)
			}
			55 {
				sqlite3_vdbe_add_op2(v, 52, reg2, lbl)
				0
			}
			56 {
				sqlite3_vdbe_add_op2(v, 51, reg2, lbl)
				0
			}
			else {
			}
		}

		sqlite3_vdbe_add_op2(v, 9, 0, addr_done)
		sqlite3_vdbe_jump_here(v, addr)
		sqlite3_vdbe_add_op2(v, 51, reg2, if (op == 55 || op == 58) { addr_done } else { lbl })
		0
	}
	sqlite3_vdbe_add_op4(v, 118, 0, reg_string, 0, c'', (-1))
	addr_ge = sqlite3_vdbe_add_op3(v, 58, reg_string, 0, reg1)
	0
	if (op == 58 && arith == 107) || (op == 56 && arith == 108) {
		sqlite3_vdbe_add_op3(v, op, reg2, lbl, reg1)
		0
	}
	sqlite3_vdbe_add_op3(v, arith, reg_val, reg1, reg1)
	sqlite3_vdbe_jump_here(v, addr_ge)
	sqlite3_vdbe_add_op3(v, op, reg2, lbl, reg1)
	0
	p_coll = sqlite3_expr_nn_coll_seq(p_parse, c2v_at(&p_order_by.a[0], isize(0)).pExpr)
	sqlite3_vdbe_append_p4(v, voidptr(p_coll), (-2))
	sqlite3_vdbe_change_p5(v, U16(128))
	sqlite3_vdbe_resolve_label(v, addr_done)
	0
	0
	0
	0
	0
	0
	0
	0
	sqlite3_release_temp_reg(p_parse, reg1)
	sqlite3_release_temp_reg(p_parse, reg2)
	0
}

@[c:'windowCodeOp']
fn window_code_op(p &WindowCodeArg, op int, reg_countdown int, jump_on_eof int) int {
	csr := 0
	reg := 0

	p_parse := p.pParse
	pmw_in := p.pMWin
	ret := 0
	v := p.pVdbe
	addr_continue := 0
	b_peer := int((int(pmw_in.eFrmType) != 77))
	lbl_done := sqlite3_vdbe_make_label(p_parse)
	addr_next_range := 0
	if op == 2 && int(pmw_in.eStart) == 91 {
		return 0
	}
	if reg_countdown > 0 {
		if int(pmw_in.eFrmType) == 90 {
			addr_next_range = sqlite3_vdbe_current_addr(v)
			if op == 2 {
				if int(pmw_in.eStart) == 87 {
					window_code_range_test(p, 56, p.current.csr, reg_countdown, p.start.csr, lbl_done)
				} else {
					window_code_range_test(p, 58, p.start.csr, reg_countdown, p.current.csr, lbl_done)
				}
			} else {
				window_code_range_test(p, 55, p.end.csr, reg_countdown, p.current.csr, lbl_done)
			}
		} else {
			sqlite3_vdbe_add_op3(v, 61, reg_countdown, lbl_done, 1)
			0
		}
	}
	if op == 1 && pmw_in.regStartRowid == 0 {
		window_agg_final(p, 0)
	}
	addr_continue = sqlite3_vdbe_current_addr(v)
	if int(pmw_in.eStart) == int(pmw_in.eEnd) && reg_countdown && int(pmw_in.eFrmType) == 90 {
		reg_rowid1 := sqlite3_get_temp_reg(p_parse)
		reg_rowid2 := sqlite3_get_temp_reg(p_parse)
		if op == 2 {
			sqlite3_vdbe_add_op2(v, 137, p.start.csr, reg_rowid1)
			sqlite3_vdbe_add_op2(v, 137, p.end.csr, reg_rowid2)
			sqlite3_vdbe_add_op3(v, 58, reg_rowid2, lbl_done, reg_rowid1)
			0
		} else if p.regRowid {
			sqlite3_vdbe_add_op2(v, 137, p.end.csr, reg_rowid1)
			sqlite3_vdbe_add_op3(v, 58, p.regRowid, lbl_done, reg_rowid1)
			0
		}
		sqlite3_release_temp_reg(p_parse, reg_rowid1)
		sqlite3_release_temp_reg(p_parse, reg_rowid2)
	}
	match op {
		1 {
			csr = p.current.csr
			reg = p.current.reg
			window_return_one_row(p)
		}
		2 {
			csr = p.start.csr
			reg = p.start.reg
			if pmw_in.regStartRowid {
				sqlite3_vdbe_add_op2(v, 88, pmw_in.regStartRowid, 1)
			} else {
				window_agg_step(p, pmw_in, csr, 1, p.regArg)
			}
		}
		else {
			csr = p.end.csr
			reg = p.end.reg
			if pmw_in.regStartRowid {
				sqlite3_vdbe_add_op2(v, 88, pmw_in.regEndRowid, 1)
			} else {
				window_agg_step(p, pmw_in, csr, 0, p.regArg)
			}
		}
	}

	if op == p.eDelete {
		sqlite3_vdbe_add_op1(v, 132, csr)
		sqlite3_vdbe_change_p5(v, U16(2))
	}
	if jump_on_eof {
		sqlite3_vdbe_add_op2(v, 40, csr, sqlite3_vdbe_current_addr(v) + 2)
		0
		ret = sqlite3_vdbe_add_op0(v, 9)
	} else {
		sqlite3_vdbe_add_op2(v, 40, csr, sqlite3_vdbe_current_addr(v) + 1 + b_peer)
		0
		if b_peer {
			sqlite3_vdbe_add_op2(v, 9, 0, lbl_done)
		}
	}
	if b_peer {
		n_reg := (if pmw_in.pOrderBy { pmw_in.pOrderBy.nExpr } else { 0 })
		reg_tmp := (if n_reg { sqlite3_get_temp_range(p_parse, n_reg) } else { 0 })
		window_read_peer_values(p, csr, reg_tmp)
		window_if_new_peer(p_parse, pmw_in.pOrderBy, reg_tmp, reg, addr_continue)
		sqlite3_release_temp_range(p_parse, reg_tmp, n_reg)
	}
	if addr_next_range {
		sqlite3_vdbe_add_op2(v, 9, 0, addr_next_range)
	}
	sqlite3_vdbe_resolve_label(v, lbl_done)
	return ret
}

@[c:'sqlite3WindowDup']
fn sqlite3_window_dup(db &Sqlite3, p_owner &Expr, p &Window) &Window {
	p_new := unsafe { &Window(nil) }
	if p {
		p_new = sqlite3_db_malloc_zero(db, U64(sizeof(Window)))
		if p_new {
			p_new.zName = sqlite3_db_str_dup(db, p.zName)
			p_new.zBase = sqlite3_db_str_dup(db, p.zBase)
			p_new.pFilter = sqlite3_expr_dup(db, p.pFilter, 0)
			p_new.pWFunc = p.pWFunc
			p_new.pPartition = sqlite3_expr_list_dup(db, p.pPartition, 0)
			p_new.pOrderBy = sqlite3_expr_list_dup(db, p.pOrderBy, 0)
			p_new.eFrmType = p.eFrmType
			p_new.eEnd = p.eEnd
			p_new.eStart = p.eStart
			p_new.eExclude = p.eExclude
			p_new.regResult = p.regResult
			p_new.regAccum = p.regAccum
			p_new.iArgCol = p.iArgCol
			p_new.iEphCsr = p.iEphCsr
			p_new.bExprArgs = p.bExprArgs
			p_new.pStart = sqlite3_expr_dup(db, p.pStart, 0)
			p_new.pEnd = sqlite3_expr_dup(db, p.pEnd, 0)
			p_new.pOwner = p_owner
			p_new.bImplicitFrame = p.bImplicitFrame
		}
	}
	return p_new
}

@[c:'sqlite3WindowListDup']
fn sqlite3_window_list_dup(db &Sqlite3, p &Window) &Window {
	p_win := &Window(0)
	p_ret := unsafe { &Window(nil) }
	pp := &&Window(c2v_address_of(&p_ret))
	for p_win = p; p_win; p_win = p_win.pNextWin {
		unsafe { *pp = sqlite3_window_dup(db, nil, p_win) }
		if usize((unsafe { *pp })) == usize(0) {
			break
		}
		pp = &(unsafe { *pp }).pNextWin
	}
	return p_ret
}

@[c:'windowExprGtZero']
fn window_expr_gt_zero(p_parse &Parse, p_expr &Expr) int {
	ret := 0
	db := p_parse.db
	p_val := unsafe { &Sqlite3_value(nil) }
	sqlite3_value_from_expr(db, p_expr, db.enc, U8(67), &&Sqlite3_value(&&Sqlite3_value(c2v_address_of(&p_val))))
	if !isnil(p_val) && sqlite3_value_int(p_val) > 0 {
		ret = 1
	}
	sqlite3_value_free_vdup7(p_val)
	return ret
}

@[c:'sqlite3WindowCodeStep']
fn sqlite3_window_code_step(p_parse &Parse, p &Select, pwi_nfo &WhereInfo, reg_gosub int, addr_gosub int) {
	pmw_in := p.pWin
	p_order_by := pmw_in.pOrderBy
	v := sqlite3_get_vdbe(p_parse)
	csr_write := 0
	csr_input := c2v_at(&p.pSrc.a[0], isize(0)).iCursor
	n_input := int(c2v_at(&p.pSrc.a[0], isize(0)).pSTab.nCol)
	i_input := 0
	addr_ne := 0
	addr_gosub_flush := 0
	addr_integer := 0
	addr_empty := 0
	reg_new := 0
	reg_record := 0
	reg_new_peer := 0
	reg_peer := 0
	reg_flush_part := 0
	s := WindowCodeArg{}
	lbl_where_end := 0
	reg_start := 0
	reg_end := 0
	lbl_where_end = sqlite3_vdbe_make_label(p_parse)
	C.memset(voidptr(&s), 0, sizeof(WindowCodeArg))
	s.pParse = p_parse
	s.pMWin = pmw_in
	s.pVdbe = v
	s.regGosub = reg_gosub
	s.addrGosub = addr_gosub
	s.current.csr = pmw_in.iEphCsr
	csr_write = s.current.csr + 1
	s.start.csr = s.current.csr + 2
	s.end.csr = s.current.csr + 3
	match pmw_in.eStart {
		87 {
			if int(pmw_in.eFrmType) != 90 && window_expr_gt_zero(p_parse, pmw_in.pStart) {
				s.eDelete = 1
			}
		}
		91 {
			if window_cache_frame(pmw_in) == 0 {
				if int(pmw_in.eEnd) == 89 {
					if int(pmw_in.eFrmType) != 90 && window_expr_gt_zero(p_parse, pmw_in.pEnd) {
						s.eDelete = 3
					}
				} else {
					s.eDelete = 1
				}
			}
		}
		else {
			s.eDelete = 2
		}
	}

	reg_new = p_parse.nMem + 1
	p_parse.nMem += n_input
	reg_record = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	s.regRowid = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	if int(pmw_in.eStart) == 89 || int(pmw_in.eStart) == 87 {
		reg_start = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	}
	if int(pmw_in.eEnd) == 89 || int(pmw_in.eEnd) == 87 {
		reg_end = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	}
	if int(pmw_in.eFrmType) != 77 {
		n_peer := (if p_order_by { p_order_by.nExpr } else { 0 })
		reg_new_peer = reg_new + pmw_in.nBufferCol
		if pmw_in.pPartition {
			reg_new_peer += pmw_in.pPartition.nExpr
		}
		reg_peer = p_parse.nMem + 1
		p_parse.nMem += n_peer
		s.start.reg = p_parse.nMem + 1
		p_parse.nMem += n_peer
		s.current.reg = p_parse.nMem + 1
		p_parse.nMem += n_peer
		s.end.reg = p_parse.nMem + 1
		p_parse.nMem += n_peer
	}
	for i_input = 0; i_input < n_input; i_input++ {
		sqlite3_vdbe_add_op3(v, 96, csr_input, i_input, reg_new + i_input)
	}
	sqlite3_vdbe_add_op3(v, 99, reg_new, n_input, reg_record)
	if pmw_in.pPartition {
		addr := 0
		p_part := pmw_in.pPartition
		n_part := p_part.nExpr
		reg_new_part := reg_new + pmw_in.nBufferCol
		p_key_info := sqlite3_key_info_from_expr_list(p_parse, p_part, 0, 0)
		reg_flush_part = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		addr = sqlite3_vdbe_add_op3(v, 92, reg_new_part, pmw_in.regPart, n_part)
		sqlite3_vdbe_append_p4(v, voidptr(p_key_info), (-9))
		sqlite3_vdbe_add_op3(v, 14, addr + 2, addr + 4, addr + 2)
		0
		addr_gosub_flush = sqlite3_vdbe_add_op1(v, 10, reg_flush_part)
		0
		sqlite3_vdbe_add_op3(v, 82, reg_new_part, pmw_in.regPart, n_part - 1)
	}
	sqlite3_vdbe_add_op2(v, 129, csr_write, s.regRowid)
	sqlite3_vdbe_add_op3(v, 130, csr_write, reg_record, s.regRowid)
	addr_ne = sqlite3_vdbe_add_op3(v, 53, pmw_in.regOne, 0, s.regRowid)
	0
	s.regArg = window_init_accum(p_parse, pmw_in)
	if reg_start {
		sqlite3_expr_code(p_parse, pmw_in.pStart, reg_start)
		window_check_value(p_parse, reg_start, 0 + (if int(pmw_in.eFrmType) == 90 { 3 } else { 0 }))
	}
	if reg_end {
		sqlite3_expr_code(p_parse, pmw_in.pEnd, reg_end)
		window_check_value(p_parse, reg_end, 1 + (if int(pmw_in.eFrmType) == 90 { 3 } else { 0 }))
	}
	if int(pmw_in.eFrmType) != 90 && int(pmw_in.eStart) == int(pmw_in.eEnd) && reg_start {
		op := (if (int(pmw_in.eStart) == 87) { 58 } else { 56 })
		addr_ge := sqlite3_vdbe_add_op3(v, op, reg_start, 0, reg_end)
		0
		0
		window_agg_final(&s, 0)
		sqlite3_vdbe_add_op1(v, 36, s.current.csr)
		window_return_one_row(&s)
		sqlite3_vdbe_add_op1(v, 148, s.current.csr)
		sqlite3_vdbe_add_op2(v, 9, 0, lbl_where_end)
		sqlite3_vdbe_jump_here(v, addr_ge)
	}
	if int(pmw_in.eStart) == 87 && int(pmw_in.eFrmType) != 90 && reg_end {
		sqlite3_vdbe_add_op3(v, 108, reg_start, reg_end, reg_start)
	}
	if int(pmw_in.eStart) != 91 {
		sqlite3_vdbe_add_op1(v, 36, s.start.csr)
	}
	sqlite3_vdbe_add_op1(v, 36, s.current.csr)
	sqlite3_vdbe_add_op1(v, 36, s.end.csr)
	if reg_peer && !isnil(p_order_by) {
		sqlite3_vdbe_add_op3(v, 82, reg_new_peer, reg_peer, p_order_by.nExpr - 1)
		sqlite3_vdbe_add_op3(v, 82, reg_peer, s.start.reg, p_order_by.nExpr - 1)
		sqlite3_vdbe_add_op3(v, 82, reg_peer, s.current.reg, p_order_by.nExpr - 1)
		sqlite3_vdbe_add_op3(v, 82, reg_peer, s.end.reg, p_order_by.nExpr - 1)
	}
	sqlite3_vdbe_add_op2(v, 9, 0, lbl_where_end)
	sqlite3_vdbe_jump_here(v, addr_ne)
	if reg_peer {
		window_if_new_peer(p_parse, p_order_by, reg_new_peer, reg_peer, lbl_where_end)
	}
	if int(pmw_in.eStart) == 87 {
		window_code_op(&s, 3, 0, 0)
		if int(pmw_in.eEnd) != 91 {
			if int(pmw_in.eFrmType) == 90 {
				lbl := sqlite3_vdbe_make_label(p_parse)
				addr_next := sqlite3_vdbe_current_addr(v)
				window_code_range_test(&s, 58, s.current.csr, reg_end, s.end.csr, lbl)
				window_code_op(&s, 2, reg_start, 0)
				window_code_op(&s, 1, 0, 0)
				sqlite3_vdbe_add_op2(v, 9, 0, addr_next)
				sqlite3_vdbe_resolve_label(v, lbl)
			} else {
				window_code_op(&s, 1, reg_end, 0)
				window_code_op(&s, 2, reg_start, 0)
			}
		}
	} else if int(pmw_in.eEnd) == 89 {
		brps := int((int(pmw_in.eStart) == 89 && int(pmw_in.eFrmType) == 90))
		window_code_op(&s, 3, reg_end, 0)
		if brps {
			window_code_op(&s, 2, reg_start, 0)
		}
		window_code_op(&s, 1, 0, 0)
		if !brps {
			window_code_op(&s, 2, reg_start, 0)
		}
	} else {
		addr := 0
		window_code_op(&s, 3, 0, 0)
		if int(pmw_in.eEnd) != 91 {
			if int(pmw_in.eFrmType) == 90 {
				lbl := 0
				addr = sqlite3_vdbe_current_addr(v)
				if reg_end {
					lbl = sqlite3_vdbe_make_label(p_parse)
					window_code_range_test(&s, 58, s.current.csr, reg_end, s.end.csr, lbl)
				}
				window_code_op(&s, 1, 0, 0)
				window_code_op(&s, 2, reg_start, 0)
				if reg_end {
					sqlite3_vdbe_add_op2(v, 9, 0, addr)
					sqlite3_vdbe_resolve_label(v, lbl)
				}
			} else {
				if reg_end {
					addr = sqlite3_vdbe_add_op3(v, 61, reg_end, 0, 1)
					0
				}
				window_code_op(&s, 1, 0, 0)
				window_code_op(&s, 2, reg_start, 0)
				if reg_end {
					sqlite3_vdbe_jump_here(v, addr)
				}
			}
		}
	}
	sqlite3_vdbe_resolve_label(v, lbl_where_end)
	sqlite3_where_end(pwi_nfo)
	if pmw_in.pPartition {
		addr_integer = sqlite3_vdbe_add_op2(v, 73, 0, reg_flush_part)
		sqlite3_vdbe_jump_here(v, addr_gosub_flush)
	}
	s.regRowid = 0
	addr_empty = sqlite3_vdbe_add_op1(v, 36, csr_write)
	0
	if int(pmw_in.eEnd) == 89 {
		brps := int((int(pmw_in.eStart) == 89 && int(pmw_in.eFrmType) == 90))
		window_code_op(&s, 3, reg_end, 0)
		if brps {
			window_code_op(&s, 2, reg_start, 0)
		}
		window_code_op(&s, 1, 0, 0)
	} else if int(pmw_in.eStart) == 87 {
		addr_start := 0
		addr_break1 := 0
		addr_break2 := 0
		addr_break3 := 0
		window_code_op(&s, 3, 0, 0)
		if int(pmw_in.eFrmType) == 90 {
			addr_start = sqlite3_vdbe_current_addr(v)
			addr_break2 = window_code_op(&s, 2, reg_start, 1)
			addr_break1 = window_code_op(&s, 1, 0, 1)
		} else if int(pmw_in.eEnd) == 91 {
			addr_start = sqlite3_vdbe_current_addr(v)
			addr_break1 = window_code_op(&s, 1, reg_start, 1)
			addr_break2 = window_code_op(&s, 2, 0, 1)
		} else {
			sqlite3_vdbe_add_op3(v, 108, reg_start, reg_end, reg_end)
			sqlite3_vdbe_add_op2(v, 73, 0, reg_start)
			addr_start = sqlite3_vdbe_current_addr(v)
			addr_break1 = window_code_op(&s, 1, reg_end, 1)
			addr_break2 = window_code_op(&s, 2, reg_start, 1)
		}
		sqlite3_vdbe_add_op2(v, 9, 0, addr_start)
		sqlite3_vdbe_jump_here(v, addr_break2)
		addr_start = sqlite3_vdbe_current_addr(v)
		addr_break3 = window_code_op(&s, 1, 0, 1)
		sqlite3_vdbe_add_op2(v, 9, 0, addr_start)
		sqlite3_vdbe_jump_here(v, addr_break1)
		sqlite3_vdbe_jump_here(v, addr_break3)
	} else {
		addr_break := 0
		addr_start := 0
		window_code_op(&s, 3, 0, 0)
		addr_start = sqlite3_vdbe_current_addr(v)
		addr_break = window_code_op(&s, 1, 0, 1)
		window_code_op(&s, 2, reg_start, 0)
		sqlite3_vdbe_add_op2(v, 9, 0, addr_start)
		sqlite3_vdbe_jump_here(v, addr_break)
	}
	sqlite3_vdbe_jump_here(v, addr_empty)
	sqlite3_vdbe_add_op1(v, 148, s.current.csr)
	if pmw_in.pPartition {
		if pmw_in.regStartRowid {
			sqlite3_vdbe_add_op2(v, 73, 1, pmw_in.regStartRowid)
			sqlite3_vdbe_add_op2(v, 73, 0, pmw_in.regEndRowid)
		}
		sqlite3_vdbe_change_p1(v, addr_integer, sqlite3_vdbe_current_addr(v))
		sqlite3_vdbe_add_op1(v, 69, reg_flush_part)
	}
}
