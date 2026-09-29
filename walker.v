@[translated]
module main

@[c:'walkWindowList']
fn walk_window_list(p_walker &Walker, p_list &Window, b_one_only int) int {
	p_win := &Window(0)
	for p_win = p_list; p_win; p_win = p_win.pNextWin {
		rc := 0
		rc = sqlite3_walk_expr_list(p_walker, p_win.pOrderBy)
		if rc {
			return 2
		}
		rc = sqlite3_walk_expr_list(p_walker, p_win.pPartition)
		if rc {
			return 2
		}
		rc = sqlite3_walk_expr(p_walker, p_win.pFilter)
		if rc {
			return 2
		}
		rc = sqlite3_walk_expr(p_walker, p_win.pStart)
		if rc {
			return 2
		}
		rc = sqlite3_walk_expr(p_walker, p_win.pEnd)
		if rc {
			return 2
		}
		if b_one_only {
			break
		}
	}
	return 0
}

@[c:'sqlite3WalkExprNN']
fn sqlite3_walk_expr_nn(p_walker &Walker, p_expr &Expr) int {
	rc := 0
	for {
		rc = p_walker.xExprCallback(p_walker, p_expr)
		if rc {
			return rc & 2
		}
		if !((p_expr.flags & u32((65536 | 8388608))) != u32(0)) {
			if !isnil(p_expr.pLeft) && sqlite3_walk_expr_nn(p_walker, p_expr.pLeft) {
				return 2
			}
			if p_expr.pRight {
				p_expr = p_expr.pRight
				continue
			} else if ((p_expr.flags & u32(4096)) != u32(0)) {
				if sqlite3_walk_select(p_walker, p_expr.x.pSelect) {
					return 2
				}
			} else {
				if p_expr.x.pList {
					if sqlite3_walk_expr_list(p_walker, p_expr.x.pList) {
						return 2
					}
				}
				if ((p_expr.flags & u32(16777216)) != u32(0)) {
					if walk_window_list(p_walker, p_expr.y.pWin, 1) {
						return 2
					}
				}
			}
		}
		break
	}
	return 0
}

@[c:'sqlite3WalkExpr']
fn sqlite3_walk_expr(p_walker &Walker, p_expr &Expr) int {
	return if p_expr { sqlite3_walk_expr_nn(p_walker, p_expr) } else { 0 }
}

@[c:'sqlite3WalkExprList']
fn sqlite3_walk_expr_list(p_walker &Walker, p &ExprList) int {
	i := 0
	p_item := &ExprList_item(0)
	if p {
		i = p.nExpr
		for p_item = unsafe { &p.a[0] }; i > 0; i-- {
			if sqlite3_walk_expr(p_walker, p_item.pExpr) {
				return 2
			}
			c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
		}
	}
	return 0
}

@[c:'sqlite3WalkWinDefnDummyCallback']
fn sqlite3_walk_win_defn_dummy_callback(p_walker &Walker, p &Select) {
	c2v_gc_register_thread()
}

@[c:'sqlite3WalkSelectExpr']
fn sqlite3_walk_select_expr(p_walker &Walker, p &Select) int {
	if sqlite3_walk_expr_list(p_walker, p.pEList) {
		return 2
	}
	if sqlite3_walk_expr(p_walker, p.pWhere) {
		return 2
	}
	if sqlite3_walk_expr_list(p_walker, p.pGroupBy) {
		return 2
	}
	if sqlite3_walk_expr(p_walker, p.pHaving) {
		return 2
	}
	if sqlite3_walk_expr_list(p_walker, p.pOrderBy) {
		return 2
	}
	if sqlite3_walk_expr(p_walker, p.pLimit) {
		return 2
	}
	if p.pWinDefn {
		p_parse := &Parse(0)
		mut __c2v_condition_48 := false
		mut __c2v_condition_49 := false
		__c2v_condition_49 = p_walker.xSelectCallback2 == sqlite3_walk_win_defn_dummy_callback
		__c2v_condition_48 = __c2v_condition_49
		if !__c2v_condition_48 {
			mut __c2v_condition_50 := false
			__c2v_condition_50 = (usize(c2v_assign[&Parse](unsafe { &p_parse }, p_walker.pParse)) != usize(0) && (int(p_parse.eParseMode) >= 2))
			__c2v_condition_48 = __c2v_condition_50
		}
		if !__c2v_condition_48 {
			mut __c2v_condition_51 := false
			__c2v_condition_51 = p_walker.xSelectCallback2 == sqlite3_select_pop_with
			__c2v_condition_48 = __c2v_condition_51
		}
		if __c2v_condition_48 {
			rc := walk_window_list(p_walker, p.pWinDefn, 0)
			return rc
		}
	}
	return 0
}

@[c:'sqlite3WalkSelectFrom']
fn sqlite3_walk_select_from(p_walker &Walker, p &Select) int {
	p_src := &SrcList(0)
	i := 0
	p_item := &SrcItem(0)
	p_src = p.pSrc
	if p_src {
		i = p_src.nSrc
		for p_item = unsafe { &p_src.a[0] }; i > 0; i-- {
			if int(p_item.fg.isSubquery) && sqlite3_walk_select(p_walker, p_item.u4.pSubq.pSelect) {
				return 2
			}
			if int(p_item.fg.isTabFunc) && sqlite3_walk_expr_list(p_walker, p_item.u1.pFuncArg) {
				return 2
			}
			c2v_pointer_postfix(voidptr(&p_item), p_item, isize(1))
		}
	}
	return 0
}

@[c:'sqlite3WalkSelect']
fn sqlite3_walk_select(p_walker &Walker, p &Select) int {
	rc := 0
	if usize(p) == usize(0) {
		return 0
	}
	if isnil(p_walker.xSelectCallback) {
		return 0
	}
	for {
		rc = p_walker.xSelectCallback(p_walker, p)
		if rc {
			return rc & 2
		}
		if sqlite3_walk_select_expr(p_walker, p) || sqlite3_walk_select_from(p_walker, p) {
			return 2
		}
		if p_walker.xSelectCallback2 {
			p_walker.xSelectCallback2(p_walker, p)
		}
		p = p.pPrior
		if !(usize(p) != usize(0)) {
			break
		}
	}
	return 0
}

@[c:'sqlite3WalkerDepthIncrease']
fn sqlite3_walker_depth_increase(p_walker &Walker, p_select &Select) int {
	c2v_gc_register_thread()

	p_walker.walkerDepth++
	return 0
}

@[c:'sqlite3WalkerDepthDecrease']
fn sqlite3_walker_depth_decrease(p_walker &Walker, p_select &Select) {
	c2v_gc_register_thread()

	p_walker.walkerDepth--
}

@[c:'sqlite3ExprWalkNoop']
fn sqlite3_expr_walk_noop(not_used &Walker, not_used2 &Expr) int {
	c2v_gc_register_thread()

	return 0
}

@[c:'sqlite3SelectWalkNoop']
fn sqlite3_select_walk_noop(not_used &Walker, not_used2 &Select) int {
	c2v_gc_register_thread()

	return 0
}
