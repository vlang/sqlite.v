@[translated]
module main

@[c:'sqlite3FkLocateIndex']
fn sqlite3_fk_locate_index(p_parse &Parse, p_parent &Table, pfk_ey &FKey, pp_idx &&Index, pai_col &&int) int {
	p_idx := unsafe { &Index(nil) }
	ai_col := unsafe { &int(nil) }
	n_col := pfk_ey.nCol
	z_key := c2v_at(&pfk_ey.aCol[0], isize(0)).zCol
	if n_col == 1 {
		if int(p_parent.iPKey) >= 0 {
			if isnil(z_key) {
				return 0
			}
			if !sqlite3_str_ic_mp(p_parent.aCol[p_parent.iPKey].zCnName, z_key) {
				return 0
			}
		}
	} else if pai_col {
		ai_col = &int(sqlite3_db_malloc_raw_nn(p_parse.db, U64(u64(n_col) * sizeof(int))))
		if isnil(ai_col) {
			return 1
		}
		unsafe { *pai_col = ai_col }
	}
	for p_idx = p_parent.pIndex; p_idx; p_idx = p_idx.pNext {
		if int(p_idx.nKeyCol) == n_col && (int(p_idx.onError) != 0) && usize(p_idx.pPartIdxWhere) == usize(0) {
			if usize(z_key) == usize(0) {
				if (int(p_idx.idxType) == 2) {
					if ai_col {
						i := 0
						for i = 0; i < n_col; i++ {
							ai_col[i] = c2v_at(&pfk_ey.aCol[0], isize(i)).iFrom
						}
					}
					break
				}
			} else {
				i := 0
				j := 0

				for i = 0; i < n_col; i++ {
					i_col := p_idx.aiColumn[i]
					z_dflt_coll := &i8(0)
					z_idx_col := &i8(0)
					if int(i_col) < 0 {
						break
					}
					z_dflt_coll = sqlite3_column_coll(unsafe { p_parent.aCol + i_col })
					if isnil(z_dflt_coll) {
						z_dflt_coll = unsafe { &sqlite3StrBINARY[0] }
					}
					if sqlite3_str_ic_mp(p_idx.azColl[i], z_dflt_coll) {
						break
					}
					z_idx_col = p_parent.aCol[i_col].zCnName
					for j = 0; j < n_col; j++ {
						if sqlite3_str_ic_mp(c2v_at(&pfk_ey.aCol[0], isize(j)).zCol, z_idx_col) == 0 {
							if ai_col {
								ai_col[i] = c2v_at(&pfk_ey.aCol[0], isize(j)).iFrom
							}
							break
						}
					}
					if j == n_col {
						break
					}
				}
				if i == n_col {
					break
				}
			}
		}
	}
	if isnil(p_idx) {
		if !p_parse.disableTriggers {
			sqlite3_error_msg(p_parse, c'foreign key mismatch - "%w" referencing "%w"', voidptr(pfk_ey.pFrom.zName), voidptr(pfk_ey.zTo))
		}
		sqlite3_db_free(p_parse.db, voidptr(ai_col))
		return 1
	}
	unsafe { *pp_idx = p_idx }
	return 0
}

@[c:'fkLookupParent']
fn fk_lookup_parent(p_parse &Parse, i_db int, p_tab &Table, p_idx &Index, pfk_ey &FKey, ai_col &int, reg_data int, n_incr int, is_ignore int) {
	i := 0
	v := sqlite3_get_vdbe(p_parse)
	i_cur := p_parse.nTab - 1
	i_ok := sqlite3_vdbe_make_label(p_parse)
	0
	if n_incr < 0 {
		sqlite3_vdbe_add_op2(v, 60, int(pfk_ey.isDeferred), i_ok)
		0
	}
	for i = 0; i < pfk_ey.nCol; i++ {
		i_reg := int(sqlite3_table_column_to_storage(pfk_ey.pFrom, I16(ai_col[i]))) + reg_data + 1
		sqlite3_vdbe_add_op2(v, 51, i_reg, i_ok)
		0
	}
	if is_ignore == 0 {
		if usize(p_idx) == usize(0) {
			i_must_be_int := 0
			reg_temp := sqlite3_get_temp_reg(p_parse)
			sqlite3_vdbe_add_op2(v, 83, int(sqlite3_table_column_to_storage(pfk_ey.pFrom, I16(ai_col[0]))) + 1 + reg_data, reg_temp)
			i_must_be_int = sqlite3_vdbe_add_op2(v, 13, reg_temp, 0)
			0
			if usize(p_tab) == usize(pfk_ey.pFrom) && n_incr == 1 {
				sqlite3_vdbe_add_op3(v, 54, reg_data, i_ok, reg_temp)
				0
				sqlite3_vdbe_change_p5(v, U16(144))
			}
			sqlite3_open_table(p_parse, i_cur, i_db, p_tab, 114)
			sqlite3_vdbe_add_op3(v, 31, i_cur, 0, reg_temp)
			0
			sqlite3_vdbe_goto(v, i_ok)
			sqlite3_vdbe_jump_here(v, sqlite3_vdbe_current_addr(v) - 2)
			sqlite3_vdbe_jump_here(v, i_must_be_int)
			sqlite3_release_temp_reg(p_parse, reg_temp)
		} else {
			n_col := pfk_ey.nCol
			reg_temp := sqlite3_get_temp_range(p_parse, n_col)
			sqlite3_vdbe_add_op3(v, 114, i_cur, int(p_idx.tnum), i_db)
			sqlite3_vdbe_set_p4_key_info(p_parse, p_idx)
			for i = 0; i < n_col; i++ {
				sqlite3_vdbe_add_op2(v, 82, int(sqlite3_table_column_to_storage(pfk_ey.pFrom, I16(ai_col[i]))) + 1 + reg_data, reg_temp + i)
			}
			if usize(p_tab) == usize(pfk_ey.pFrom) && n_incr == 1 {
				i_jump := sqlite3_vdbe_current_addr(v) + n_col + 1
				for i = 0; i < n_col; i++ {
					i_child := int(sqlite3_table_column_to_storage(pfk_ey.pFrom, I16(ai_col[i]))) + 1 + reg_data
					i_parent := 1 + reg_data
					i_parent += int(sqlite3_table_column_to_storage(p_idx.pTable, p_idx.aiColumn[i]))
					if int(p_idx.aiColumn[i]) == int(p_tab.iPKey) {
						i_parent = reg_data
					}
					sqlite3_vdbe_add_op3(v, 53, i_child, i_jump, i_parent)
					0
					sqlite3_vdbe_change_p5(v, U16(16))
				}
				sqlite3_vdbe_goto(v, i_ok)
			}
			sqlite3_vdbe_add_op4(v, 98, reg_temp, n_col, 0, sqlite3_index_affinity_str(p_parse.db, p_idx), n_col)
			sqlite3_vdbe_add_op4_int(v, 29, i_cur, i_ok, reg_temp, n_col)
			0
			sqlite3_release_temp_range(p_parse, reg_temp, n_col)
		}
	}
	if !pfk_ey.isDeferred && !(p_parse.db.flags & U64(524288)) && isnil(p_parse.pToplevel) && !p_parse.isMultiWrite {
		sqlite3_halt_constraint(p_parse, (19 | (3 << 8)), 2, unsafe { nil }, I8((-1)), U8(4))
	} else {
		if n_incr > 0 && int(pfk_ey.isDeferred) == 0 {
			sqlite3_may_abort(p_parse)
		}
		sqlite3_vdbe_add_op2(v, 160, int(pfk_ey.isDeferred), n_incr)
	}
	sqlite3_vdbe_resolve_label(v, i_ok)
	sqlite3_vdbe_add_op1(v, 124, i_cur)
}

@[c:'exprTableRegister']
fn expr_table_register(p_parse &Parse, p_tab &Table, reg_base int, i_col I16) &Expr {
	p_expr := &Expr(0)
	p_col := &Column(0)
	z_coll := &i8(0)
	db := p_parse.db
	p_expr = sqlite3_expr(db, 176, unsafe { nil })
	if p_expr {
		if int(i_col) >= 0 && int(i_col) != int(p_tab.iPKey) {
			p_col = unsafe { p_tab.aCol + i_col }
			p_expr.iTable = reg_base + int(sqlite3_table_column_to_storage(p_tab, i_col)) + 1
			p_expr.affExpr = p_col.affinity
			z_coll = sqlite3_column_coll(p_col)
			if usize(z_coll) == usize(0) {
				z_coll = db.pDfltColl.zName
			}
			p_expr = sqlite3_expr_add_collate_string(p_parse, p_expr, z_coll)
		} else {
			p_expr.iTable = reg_base
			p_expr.affExpr = i8(68)
		}
	}
	return p_expr
}

@[c:'exprTableColumn']
fn expr_table_column(db &Sqlite3, p_tab &Table, i_cursor int, i_col I16) &Expr {
	p_expr := sqlite3_expr(db, 168, unsafe { nil })
	if p_expr {
		p_expr.y.pTab = p_tab
		p_expr.iTable = i_cursor
		p_expr.iColumn = i_col
	}
	return p_expr
}

@[c:'fkScanChildren']
fn fk_scan_children(p_parse &Parse, p_src &SrcList, p_tab &Table, p_idx &Index, pfk_ey &FKey, ai_col &int, reg_data int, n_incr int) {
	db := p_parse.db
	i := 0
	p_where := unsafe { &Expr(nil) }
	s_name_context := NameContext{}
	pwi_nfo := &WhereInfo(0)
	i_fk_if_zero := 0
	v := sqlite3_get_vdbe(p_parse)
	if n_incr < 0 {
		i_fk_if_zero = sqlite3_vdbe_add_op2(v, 60, int(pfk_ey.isDeferred), 0)
		0
	}
	for i = 0; i < pfk_ey.nCol; i++ {
		p_left := &Expr(0)
		p_right := &Expr(0)
		p_eq := &Expr(0)
		i_col := I16(0)
		z_col := &i8(0)
		i_col = I16(if p_idx { int(p_idx.aiColumn[i]) } else { -1 })
		p_left = expr_table_register(p_parse, p_tab, reg_data, i_col)
		i_col = I16(if ai_col { ai_col[i] } else { c2v_at(&pfk_ey.aCol[0], isize(0)).iFrom })
		z_col = pfk_ey.pFrom.aCol[i_col].zCnName
		p_right = sqlite3_expr(db, 60, z_col)
		p_eq = sqlite3_pe_xpr(p_parse, 54, p_left, p_right)
		p_where = sqlite3_expr_and(p_parse, p_where, p_eq)
	}
	if usize(p_tab) == usize(pfk_ey.pFrom) && n_incr > 0 {
		p_ne := &Expr(0)
		p_left := &Expr(0)
		p_right := &Expr(0)
		if ((p_tab.tabFlags & u32(128)) == u32(0)) {
			p_left = expr_table_register(p_parse, p_tab, reg_data, I16(-1))
			p_right = expr_table_column(db, p_tab, c2v_at(&p_src.a[0], isize(0)).iCursor, I16(-1))
			p_ne = sqlite3_pe_xpr(p_parse, 53, p_left, p_right)
		} else {
			p_eq := &Expr(0)
			p_all := unsafe { &Expr(nil) }

			for i = 0; i < int(p_idx.nKeyCol); i++ {
				i_col := p_idx.aiColumn[i]
				p_left = expr_table_register(p_parse, p_tab, reg_data, i_col)
				p_right = sqlite3_expr(db, 60, p_tab.aCol[i_col].zCnName)
				p_eq = sqlite3_pe_xpr(p_parse, 45, p_left, p_right)
				p_all = sqlite3_expr_and(p_parse, p_all, p_eq)
			}
			p_ne = sqlite3_pe_xpr(p_parse, 19, p_all, unsafe { nil })
		}
		p_where = sqlite3_expr_and(p_parse, p_where, p_ne)
	}
	C.memset(voidptr(&s_name_context), 0, sizeof(NameContext))
	s_name_context.pSrcList = p_src
	s_name_context.pParse = p_parse
	sqlite3_resolve_expr_names(&s_name_context, p_where)
	if p_parse.nErr == 0 {
		pwi_nfo = sqlite3_where_begin(p_parse, p_src, p_where, unsafe { nil }, unsafe { nil }, unsafe { nil }, U16(0), 0)
		sqlite3_vdbe_add_op2(v, 160, int(pfk_ey.isDeferred), n_incr)
		if pwi_nfo {
			sqlite3_where_end(pwi_nfo)
		}
	}
	sqlite3_expr_delete(db, p_where)
	if i_fk_if_zero {
		sqlite3_vdbe_jump_here_or_pop_inst(v, i_fk_if_zero)
	}
}

@[c:'sqlite3FkReferences']
fn sqlite3_fk_references(p_tab &Table) &FKey {
	return &FKey(sqlite3_hash_find(&p_tab.pSchema.fkeyHash, p_tab.zName))
}

@[c:'fkTriggerDelete']
fn fk_trigger_delete(db_mem &Sqlite3, p &Trigger) {
	if p {
		p_step := p.step_list
		sqlite3_src_list_delete(db_mem, p_step.pSrc)
		sqlite3_expr_delete(db_mem, p_step.pWhere)
		sqlite3_expr_list_delete(db_mem, p_step.pExprList)
		sqlite3_select_delete(db_mem, p_step.pSelect)
		sqlite3_expr_delete(db_mem, p.pWhen)
		sqlite3_db_free(db_mem, voidptr(p))
	}
}

@[c:'sqlite3FkClearTriggerCache']
fn sqlite3_fk_clear_trigger_cache(db &Sqlite3, i_db int) {
	k := &HashElem(0)
	p_hash := &db.aDb[i_db].pSchema.tblHash
	for k = p_hash.first; k; k = k.next {
		p_tab := &Table(k.data)
		pfk_ey := &FKey(0)
		if !(int(p_tab.eTabType) == 0) {
			continue
		}
		for pfk_ey = p_tab.u.tab.pFKey; pfk_ey; pfk_ey = pfk_ey.pNextFrom {
			fk_trigger_delete(db, pfk_ey.apTrigger[0])
			pfk_ey.apTrigger[0] = 0
			fk_trigger_delete(db, pfk_ey.apTrigger[1])
			pfk_ey.apTrigger[1] = 0
		}
	}
}

@[c:'sqlite3FkDropTable']
fn sqlite3_fk_drop_table(p_parse &Parse, p_name &SrcList, p_tab &Table) {
	db := p_parse.db
	if (db.flags & U64(16384)) && (int(p_tab.eTabType) == 0) {
		i_skip := 0
		v := sqlite3_get_vdbe(p_parse)
		if usize(sqlite3_fk_references(p_tab)) == usize(0) {
			p := &FKey(0)
			for p = p_tab.u.tab.pFKey; p; p = p.pNextFrom {
				if int(p.isDeferred) || (db.flags & U64(524288)) {
					break
				}
			}
			if isnil(p) {
				return
			}
			i_skip = sqlite3_vdbe_make_label(p_parse)
			sqlite3_vdbe_add_op2(v, 60, 1, i_skip)
			0
		}
		p_parse.disableTriggers = Bft(1)
		sqlite3_delete_from(p_parse, sqlite3_src_list_dup(db, p_name, 0), unsafe { nil }, unsafe { nil }, unsafe { nil })
		p_parse.disableTriggers = Bft(0)
		if (db.flags & U64(524288)) == U64(0) {
			0
			sqlite3_vdbe_add_op2(v, 60, 0, sqlite3_vdbe_current_addr(v) + 2)
			0
			sqlite3_halt_constraint(p_parse, (19 | (3 << 8)), 2, unsafe { nil }, I8((-1)), U8(4))
		}
		if i_skip {
			sqlite3_vdbe_resolve_label(v, i_skip)
		}
	}
}

@[c:'fkChildIsModified']
fn fk_child_is_modified(p_tab &Table, p &FKey, a_change &int, b_chng_rowid int) int {
	i := 0
	for i = 0; i < p.nCol; i++ {
		i_child_key := c2v_at(&p.aCol[0], isize(i)).iFrom
		if a_change[i_child_key] >= 0 {
			return 1
		}
		if i_child_key == int(p_tab.iPKey) && b_chng_rowid {
			return 1
		}
	}
	return 0
}

@[c:'fkParentIsModified']
fn fk_parent_is_modified(p_tab &Table, p &FKey, a_change &int, b_chng_rowid int) int {
	i := 0
	for i = 0; i < p.nCol; i++ {
		z_key := c2v_at(&p.aCol[0], isize(i)).zCol
		i_key := 0
		for i_key = 0; i_key < int(p_tab.nCol); i_key++ {
			if a_change[i_key] >= 0 || (i_key == int(p_tab.iPKey) && b_chng_rowid) {
				p_col := unsafe { p_tab.aCol + i_key }
				if z_key {
					if 0 == sqlite3_str_ic_mp(p_col.zCnName, z_key) {
						return 1
					}
				} else if int(p_col.colFlags) & 1 {
					return 1
				}
			}
		}
	}
	return 0
}

@[c:'isSetNullAction']
fn is_set_null_action(p_parse &Parse, pfk_ey &FKey) int {
	p_top := (if p_parse.pToplevel { p_parse.pToplevel } else { p_parse })
	if p_top.pTriggerPrg {
		p := p_top.pTriggerPrg.pTrigger
		if (usize(p) == usize(pfk_ey.apTrigger[0]) && int(pfk_ey.aAction[0]) == 8) || (usize(p) == usize(pfk_ey.apTrigger[1]) && int(pfk_ey.aAction[1]) == 8) {
			return 1
		}
	}
	return 0
}

@[c:'sqlite3FkCheck']
fn sqlite3_fk_check(p_parse &Parse, p_tab &Table, reg_old int, reg_new int, a_change &int, b_chng_rowid int) {
	db := p_parse.db
	pfk_ey := &FKey(0)
	i_db := 0
	z_db := &i8(0)
	is_ignore_errors := int(p_parse.disableTriggers)
	if (db.flags & U64(16384)) == U64(0) {
		return
	}
	if !(int(p_tab.eTabType) == 0) {
		return
	}
	i_db = sqlite3_schema_to_index(db, p_tab.pSchema)
	z_db = db.aDb[i_db].zDbSName
	for pfk_ey = p_tab.u.tab.pFKey; pfk_ey; pfk_ey = pfk_ey.pNextFrom {
		p_to := &Table(0)
		p_idx := unsafe { &Index(nil) }
		ai_free := unsafe { &int(nil) }
		ai_col := &int(0)
		i_col := 0
		i := 0
		b_ignore := 0
		if !isnil(a_change) && sqlite3_stricmp(p_tab.zName, pfk_ey.zTo) != 0 && fk_child_is_modified(p_tab, pfk_ey, a_change, b_chng_rowid) == 0 {
			continue
		}
		if p_parse.disableTriggers {
			p_to = sqlite3_find_table(db, pfk_ey.zTo, z_db)
		} else {
			p_to = sqlite3_locate_table(p_parse, u32(0), pfk_ey.zTo, z_db)
		}
		if isnil(p_to) || sqlite3_fk_locate_index(p_parse, p_to, pfk_ey, &&Index(&&Index(c2v_address_of(&p_idx))), &&int(&&int(c2v_address_of(&ai_free)))) {
			if !is_ignore_errors || int(db.mallocFailed) {
				return
			}
			if usize(p_to) == usize(0) {
				v := sqlite3_get_vdbe(p_parse)
				i_jump := sqlite3_vdbe_current_addr(v) + pfk_ey.nCol + 1
				for i = 0; i < pfk_ey.nCol; i++ {
					i_from_col := 0
					i_reg := 0

					i_from_col = c2v_at(&pfk_ey.aCol[0], isize(i)).iFrom
					i_reg = int(sqlite3_table_column_to_storage(pfk_ey.pFrom, I16(i_from_col))) + reg_old + 1
					sqlite3_vdbe_add_op2(v, 51, i_reg, i_jump)
					0
				}
				sqlite3_vdbe_add_op2(v, 160, int(pfk_ey.isDeferred), -1)
			}
			continue
		}
		if ai_free {
			ai_col = ai_free
		} else {
			i_col = c2v_at(&pfk_ey.aCol[0], isize(0)).iFrom
			ai_col = &i_col
		}
		for i = 0; i < pfk_ey.nCol; i++ {
			if ai_col[i] == int(p_tab.iPKey) {
				ai_col[i] = -1
			}
			if db.xAuth {
				rcauth := 0
				z_col := p_to.aCol[if p_idx { int(p_idx.aiColumn[i]) } else { int(p_to.iPKey) }].zCnName
				rcauth = sqlite3_auth_read_col(p_parse, p_to.zName, z_col, i_db)
				b_ignore = (rcauth == 2)
			}
		}
		sqlite3_table_lock(p_parse, i_db, p_to.tnum, U8(0), p_to.zName)
		p_parse.nTab++
		if reg_old != 0 {
			fk_lookup_parent(p_parse, i_db, p_to, p_idx, pfk_ey, ai_col, reg_old, -1, b_ignore)
		}
		if reg_new != 0 && !is_set_null_action(p_parse, pfk_ey) {
			fk_lookup_parent(p_parse, i_db, p_to, p_idx, pfk_ey, ai_col, reg_new, 1, b_ignore)
		}
		sqlite3_db_free(db, voidptr(ai_free))
	}
	for pfk_ey = sqlite3_fk_references(p_tab); pfk_ey; pfk_ey = pfk_ey.pNextTo {
		p_idx := unsafe { &Index(nil) }
		p_src := &SrcList(0)
		ai_col := unsafe { &int(nil) }
		if !isnil(a_change) && fk_parent_is_modified(p_tab, pfk_ey, a_change, b_chng_rowid) == 0 {
			continue
		}
		if !pfk_ey.isDeferred && !(db.flags & U64(524288)) && isnil(p_parse.pToplevel) && !p_parse.isMultiWrite {
			continue
		}
		if sqlite3_fk_locate_index(p_parse, p_tab, pfk_ey, &&Index(&&Index(c2v_address_of(&p_idx))), &&int(&&int(c2v_address_of(&ai_col)))) {
			if !is_ignore_errors || int(db.mallocFailed) {
				return
			}
			continue
		}
		p_src = sqlite3_src_list_append(p_parse, unsafe { nil }, unsafe { nil }, unsafe { nil })
		if p_src {
			p_item := unsafe { &SrcItem(&p_src.a[0]) }
			p_item.pSTab = pfk_ey.pFrom
			p_item.zName = pfk_ey.pFrom.zName
			p_item.pSTab.nTabRef++
			mut __c2v_postfix_value_17 := p_parse.nTab
			p_parse.nTab++
			p_item.iCursor = __c2v_postfix_value_17
			if reg_new != 0 {
				fk_scan_children(p_parse, p_src, p_tab, p_idx, pfk_ey, ai_col, reg_new, -1)
			}
			if reg_old != 0 {
				e_action := int(pfk_ey.aAction[int(usize(a_change) != usize(0))])
				if (db.flags & (U64(8) << 32)) {
					e_action = 0
				}
				fk_scan_children(p_parse, p_src, p_tab, p_idx, pfk_ey, ai_col, reg_old, 1)
				if !pfk_ey.isDeferred && e_action != 10 && e_action != 8 {
					sqlite3_may_abort(p_parse)
				}
			}
			p_item.zName = 0
			sqlite3_src_list_delete(db, p_src)
		}
		sqlite3_db_free(db, voidptr(ai_col))
	}
}

@[c:'sqlite3FkOldmask']
fn sqlite3_fk_oldmask(p_parse &Parse, p_tab &Table) u32 {
	mask := u32(0)
	if p_parse.db.flags & U64(16384) && (int(p_tab.eTabType) == 0) {
		p := &FKey(0)
		i := 0
		for p = p_tab.u.tab.pFKey; p; p = p.pNextFrom {
			for i = 0; i < p.nCol; i++ {
				mask |= (if (c2v_at(&p.aCol[0], isize(i)).iFrom > 31) {
					u32(4294967295)
				} else {
					(u32(1) << c2v_at(&p.aCol[0], isize(i)).iFrom)
				})
			}
		}
		for p = sqlite3_fk_references(p_tab); p; p = p.pNextTo {
			p_idx := unsafe { &Index(nil) }
			sqlite3_fk_locate_index(p_parse, p_tab, p, &&Index(&&Index(c2v_address_of(&p_idx))), unsafe { &&int(nil) })
			if p_idx {
				for i = 0; i < int(p_idx.nKeyCol); i++ {
					mask |= (if (int(p_idx.aiColumn[i]) > 31) {
						u32(4294967295)
					} else {
						(u32(1) << int(p_idx.aiColumn[i]))
					})
				}
			}
		}
	}
	return mask
}

@[c:'sqlite3FkRequired']
fn sqlite3_fk_required(p_parse &Parse, p_tab &Table, a_change &int, chng_rowid int) int {
	e_ret := 1
	b_have_fk := 0
	if p_parse.db.flags & U64(16384) && (int(p_tab.eTabType) == 0) {
		if isnil(a_change) {
			b_have_fk = (!isnil(sqlite3_fk_references(p_tab)) || !isnil(p_tab.u.tab.pFKey))
		} else {
			p := &FKey(0)
			for p = p_tab.u.tab.pFKey; p; p = p.pNextFrom {
				if fk_child_is_modified(p_tab, p, a_change, chng_rowid) {
					if 0 == sqlite3_stricmp(p_tab.zName, p.zTo) {
						e_ret = 2
					}
					b_have_fk = 1
				}
			}
			for p = sqlite3_fk_references(p_tab); p; p = p.pNextTo {
				if fk_parent_is_modified(p_tab, p, a_change, chng_rowid) {
					if (p_parse.db.flags & (U64(8) << 32)) == U64(0) && int(p.aAction[1]) != 0 {
						return 2
					}
					b_have_fk = 1
				}
			}
		}
	}
	return if b_have_fk { e_ret } else { 0 }
}

@[c:'fkActionTrigger']
fn fk_action_trigger(p_parse &Parse, p_tab &Table, pfk_ey &FKey, p_changes &ExprList) &Trigger {
	db := p_parse.db
	action := 0
	p_trigger := &Trigger(0)
	i_action := int((usize(p_changes) != usize(0)))
	action = int(pfk_ey.aAction[i_action])
	if (db.flags & (U64(8) << 32)) {
		action = 0
	}
	if action == 7 && (db.flags & U64(524288)) {
		return unsafe { nil }
	}
	p_trigger = pfk_ey.apTrigger[i_action]
	if action != 0 && isnil(p_trigger) {
		z_from := &i8(0)
		n_from := 0
		p_idx := unsafe { &Index(nil) }
		ai_col := unsafe { &int(nil) }
		p_step := unsafe { &TriggerStep(nil) }
		p_where := unsafe { &Expr(nil) }
		p_list := unsafe { &ExprList(nil) }
		p_select := unsafe { &Select(nil) }
		i := 0
		p_when := unsafe { &Expr(nil) }
		if sqlite3_fk_locate_index(p_parse, p_tab, pfk_ey, &&Index(&&Index(c2v_address_of(&p_idx))), &&int(&&int(c2v_address_of(&ai_col)))) {
			return unsafe { nil }
		}
		for i = 0; i < pfk_ey.nCol; i++ {
			t_old := Token{
				z: c'old'
				n: u32(3)
			}

			t_new := Token{
				z: c'new'
				n: u32(3)
			}

			t_from_col := Token{}
			t_to_col := Token{}
			i_from_col := 0
			p_eq := &Expr(0)
			i_from_col = if ai_col { ai_col[i] } else { c2v_at(&pfk_ey.aCol[0], isize(0)).iFrom }
			sqlite3_token_init(&t_to_col, p_tab.aCol[if p_idx {
				int(p_idx.aiColumn[i])
			} else {
				int(p_tab.iPKey)
			}].zCnName)
			sqlite3_token_init(&t_from_col, pfk_ey.pFrom.aCol[i_from_col].zCnName)
			p_eq = sqlite3_pe_xpr(p_parse, 54, sqlite3_pe_xpr(p_parse, 142, sqlite3_expr_alloc(db, 60, &t_old, 0), sqlite3_expr_alloc(db, 60, &t_to_col, 0)), sqlite3_expr_alloc(db, 60, &t_from_col, 0))
			p_where = sqlite3_expr_and(p_parse, p_where, p_eq)
			if p_changes {
				p_eq = sqlite3_pe_xpr(p_parse, 45, sqlite3_pe_xpr(p_parse, 142, sqlite3_expr_alloc(db, 60, &t_old, 0), sqlite3_expr_alloc(db, 60, &t_to_col, 0)), sqlite3_pe_xpr(p_parse, 142, sqlite3_expr_alloc(db, 60, &t_new, 0), sqlite3_expr_alloc(db, 60, &t_to_col, 0)))
				p_when = sqlite3_expr_and(p_parse, p_when, p_eq)
			}
			if action != 7 && (action != 10 || !isnil(p_changes)) {
				p_new := &Expr(0)
				if action == 10 {
					p_new = sqlite3_pe_xpr(p_parse, 142, sqlite3_expr_alloc(db, 60, &t_new, 0), sqlite3_expr_alloc(db, 60, &t_to_col, 0))
				} else if action == 9 {
					p_col := pfk_ey.pFrom.aCol + i_from_col
					p_dflt := &Expr(0)
					if int(p_col.colFlags) & 96 {
						0
						0
						p_dflt = 0
					} else {
						p_dflt = sqlite3_column_expr(pfk_ey.pFrom, p_col)
					}
					if p_dflt {
						p_new = sqlite3_expr_dup(db, p_dflt, 0)
					} else {
						p_new = sqlite3_expr_alloc(db, 122, unsafe { nil }, 0)
					}
				} else {
					p_new = sqlite3_expr_alloc(db, 122, unsafe { nil }, 0)
				}
				p_list = sqlite3_expr_list_append(p_parse, p_list, p_new)
				sqlite3_expr_list_set_name(p_parse, p_list, &t_from_col, 0)
			}
		}
		sqlite3_db_free(db, voidptr(ai_col))
		z_from = pfk_ey.pFrom.zName
		n_from = sqlite3_strlen30(z_from)
		if action == 7 {
			p_src := &SrcList(0)
			p_raise := &Expr(0)
			p_raise = sqlite3_expr(db, 118, c'FOREIGN KEY constraint failed')
			p_raise = sqlite3_pe_xpr(p_parse, 72, p_raise, unsafe { nil })
			if p_raise {
				p_raise.affExpr = i8(2)
			}
			p_src = sqlite3_src_list_append(p_parse, unsafe { nil }, unsafe { nil }, unsafe { nil })
			if p_src {
				p_item := unsafe { &p_src.a[0] + 0 }
				p_item.zName = sqlite3_db_str_dup(db, z_from)
				p_item.fg.fixedSchema = u32(1)
				p_item.u4.pSchema = p_tab.pSchema
			}
			p_select = sqlite3_select_new(p_parse, sqlite3_expr_list_append(p_parse, unsafe { nil }, p_raise), p_src, p_where, unsafe { nil }, unsafe { nil }, unsafe { nil }, u32(0), unsafe { nil })
			p_where = 0
		}
		db.lookaside.bDisable++
		db.lookaside.sz = U16(0)
		p_trigger = &Trigger(sqlite3_db_malloc_zero(db, U64(sizeof(Trigger) + sizeof(TriggerStep))))
		if p_trigger {
			p_trigger.step_list = &TriggerStep(voidptr(unsafe { p_trigger + 1 }))
			p_step = p_trigger.step_list
			p_step.pSrc = sqlite3_src_list_append(p_parse, unsafe { nil }, unsafe { nil }, unsafe { nil })
			if p_step.pSrc {
				p_item := unsafe { &p_step.pSrc.a[0] + 0 }
				p_item.zName = sqlite3_db_str_nd_up(db, z_from, U64(n_from))
				p_item.u4.pSchema = p_tab.pSchema
				p_item.fg.fixedSchema = u32(1)
			}
			p_step.pWhere = sqlite3_expr_dup(db, p_where, 1)
			p_step.pExprList = sqlite3_expr_list_dup(db, p_list, 1)
			p_step.pSelect = sqlite3_select_dup(db, p_select, 1)
			if p_when {
				p_when = sqlite3_pe_xpr(p_parse, 19, p_when, unsafe { nil })
				p_trigger.pWhen = sqlite3_expr_dup(db, p_when, 1)
			}
		}
		db.lookaside.bDisable--
		db.lookaside.sz = U16(if db.lookaside.bDisable { 0 } else { int(db.lookaside.szTrue) })
		sqlite3_expr_delete(db, p_where)
		sqlite3_expr_delete(db, p_when)
		sqlite3_expr_list_delete(db, p_list)
		sqlite3_select_delete(db, p_select)
		if int(db.mallocFailed) == 1 {
			fk_trigger_delete(db, p_trigger)
			return unsafe { nil }
		}
		match action {
			7 {
				p_step.op = U8(139)
			}
			10 {
				if isnil(p_changes) {
					p_step.op = U8(129)
					unsafe { goto c2v_switch_end_46
					 }
				}

				unsafe { goto c2v_case_46_4
				 }
			}
			else {
				c2v_case_46_4:
				p_step.op = U8(130)
			}
		}
		c2v_switch_end_46:

		p_step.pTrig = p_trigger
		p_trigger.pSchema = p_tab.pSchema
		p_trigger.pTabSchema = p_tab.pSchema
		pfk_ey.apTrigger[i_action] = p_trigger
		p_trigger.op = U8((if p_changes { 130 } else { 129 }))
	}
	return p_trigger
}

@[c:'sqlite3FkActions']
fn sqlite3_fk_actions(p_parse &Parse, p_tab &Table, p_changes &ExprList, reg_old int, a_change &int, b_chng_rowid int) {
	if p_parse.db.flags & U64(16384) {
		pfk_ey := &FKey(0)
		for pfk_ey = sqlite3_fk_references(p_tab); pfk_ey; pfk_ey = pfk_ey.pNextTo {
			if usize(a_change) == usize(0) || fk_parent_is_modified(p_tab, pfk_ey, a_change, b_chng_rowid) {
				p_act := fk_action_trigger(p_parse, p_tab, pfk_ey, p_changes)
				if p_act {
					sqlite3_code_row_trigger_direct(p_parse, p_act, p_tab, reg_old, 2, 0)
				}
			}
		}
	}
}

@[c:'sqlite3FkDelete']
fn sqlite3_fk_delete(db &Sqlite3, p_tab &Table) {
	pfk_ey := &FKey(0)
	p_next := &FKey(0)
	for pfk_ey = p_tab.u.tab.pFKey; pfk_ey; pfk_ey = p_next {
		if usize(db.pnBytesFreed) == usize(0) {
			if pfk_ey.pPrevTo {
				pfk_ey.pPrevTo.pNextTo = pfk_ey.pNextTo
			} else {
				z := (if pfk_ey.pNextTo { pfk_ey.pNextTo.zTo } else { pfk_ey.zTo })
				sqlite3_hash_insert(&p_tab.pSchema.fkeyHash, z, voidptr(pfk_ey.pNextTo))
			}
			if pfk_ey.pNextTo {
				pfk_ey.pNextTo.pPrevTo = pfk_ey.pPrevTo
			}
		}
		fk_trigger_delete(db, pfk_ey.apTrigger[0])
		fk_trigger_delete(db, pfk_ey.apTrigger[1])
		p_next = pfk_ey.pNextFrom
		sqlite3_db_free(db, voidptr(pfk_ey))
	}
}
