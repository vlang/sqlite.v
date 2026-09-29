@[translated]
module main

@[c:'sqlite3OpenTable']
fn sqlite3_open_table(p_parse &Parse, i_cur int, i_db int, p_tab &Table, opcode int) {
	v := &Vdbe(0)
	v = p_parse.pVdbe
	if !p_parse.db.noSharedCache {
		sqlite3_table_lock(p_parse, i_db, p_tab.tnum, U8(if (opcode == 116) { 1 } else { 0 }), p_tab.zName)
	}
	if ((p_tab.tabFlags & u32(128)) == u32(0)) {
		sqlite3_vdbe_add_op4_int(v, opcode, i_cur, int(p_tab.tnum), i_db, int(p_tab.nNVCol))
		0
	} else {
		p_pk := sqlite3_primary_key_index(p_tab)
		sqlite3_vdbe_add_op3(v, opcode, i_cur, int(p_pk.tnum), i_db)
		sqlite3_vdbe_set_p4_key_info(p_parse, p_pk)
		0
	}
}

@[c:'computeIndexAffStr']
fn compute_index_aff_str(db &Sqlite3, p_idx &Index) &i8 {
	n := 0
	p_tab := p_idx.pTable
	p_idx.zColAff = &i8(sqlite3_db_malloc_raw(unsafe { nil }, U64(int(p_idx.nColumn) + 1)))
	if isnil(p_idx.zColAff) {
		sqlite3_oom_fault(db)
		return unsafe { nil }
	}
	for n = 0; n < int(p_idx.nColumn); n++ {
		x := p_idx.aiColumn[n]
		aff := i8(0)
		if int(x) >= 0 {
			aff = p_tab.aCol[x].affinity
		} else if int(x) == (-1) {
			aff = i8(68)
		} else {
			aff = sqlite3_expr_affinity(c2v_at(&p_idx.aColExpr.a[0], isize(n)).pExpr)
		}
		if int(aff) < 65 {
			aff = i8(65)
		}
		if int(aff) > 67 {
			aff = i8(67)
		}
		p_idx.zColAff[n] = aff
	}
	p_idx.zColAff[n] = i8(0)
	return p_idx.zColAff
}

@[c:'sqlite3IndexAffinityStr']
fn sqlite3_index_affinity_str(db &Sqlite3, p_idx &Index) &i8 {
	if isnil(p_idx.zColAff) {
		return compute_index_aff_str(db, p_idx)
	}
	return p_idx.zColAff
}

@[c:'sqlite3TableAffinityStr']
fn sqlite3_table_affinity_str(db &Sqlite3, p_tab &Table) &i8 {
	z_col_aff := &i8(0)
	z_col_aff = &i8(sqlite3_db_malloc_raw(db, U64(int(p_tab.nCol) + 1)))
	if z_col_aff {
		i := 0
		j := 0

		j = 0
		for i = 0; i < int(p_tab.nCol); i++ {
			if (int(p_tab.aCol[i].colFlags) & 32) == 0 {
				z_col_aff[j++] = p_tab.aCol[i].affinity
			}
		}
		for {
			z_col_aff[j--] = i8(0)
			if !(j >= 0 && int(z_col_aff[j]) <= 65) {
				break
			}
		}
	}
	return z_col_aff
}

@[c:'sqlite3TableAffinity']
fn sqlite3_table_affinity(v &Vdbe, p_tab &Table, i_reg int) {
	i := 0
	z_col_aff := &i8(0)
	if p_tab.tabFlags & u32(65536) {
		if i_reg == 0 {
			p_prev := &VdbeOp(0)
			p3 := 0
			sqlite3_vdbe_append_p4(v, voidptr(p_tab), (-5))
			p_prev = sqlite3_vdbe_get_last_op(v)
			p_prev.opcode = U8(97)
			p3 = p_prev.p3
			p_prev.p3 = 0
			sqlite3_vdbe_add_op3(v, 99, p_prev.p1, p_prev.p2, p3)
		} else {
			sqlite3_vdbe_add_op2(v, 97, i_reg, int(p_tab.nNVCol))
			sqlite3_vdbe_append_p4(v, voidptr(p_tab), (-5))
		}
		return
	}
	z_col_aff = p_tab.zColAff
	if usize(z_col_aff) == usize(0) {
		z_col_aff = sqlite3_table_affinity_str(unsafe { nil }, p_tab)
		if isnil(z_col_aff) {
			sqlite3_oom_fault(sqlite3_vdbe_db(v))
			return
		}
		p_tab.zColAff = z_col_aff
	}
	i = int((C.strlen(z_col_aff) & u64(1073741823)))
	if i {
		if i_reg {
			sqlite3_vdbe_add_op4(v, 98, i_reg, i, 0, z_col_aff, i)
		} else {
			sqlite3_vdbe_change_p4(v, -1, z_col_aff, i)
		}
	}
}

@[c:'readsTable']
fn reads_table(p &Parse, i_db int, p_tab &Table) int {
	v := sqlite3_get_vdbe(p)
	i := 0
	i_end := sqlite3_vdbe_current_addr(v)
	pvt_ab := unsafe { if (int(p_tab.eTabType) == 1) {
		sqlite3_get_vt_able(p.db, p_tab)
	} else {
		&VTable(nil)
	} }
	for i = 1; i < i_end; i++ {
		p_op := sqlite3_vdbe_get_op(v, i)
		if int(p_op.opcode) == 114 && p_op.p3 == i_db {
			p_index := &Index(0)
			tnum := Pgno(p_op.p2)
			if tnum == p_tab.tnum {
				return 1
			}
			for p_index = p_tab.pIndex; p_index; p_index = p_index.pNext {
				if tnum == p_index.tnum {
					return 1
				}
			}
		}
		if int(p_op.opcode) == 175 && usize(p_op.p4.pVtab) == usize(pvt_ab) {
			return 1
		}
	}
	return 0
}

@[c:'exprColumnFlagUnion']
fn expr_column_flag_union(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	if int(p_expr.op) == 168 && int(p_expr.iColumn) >= 0 {
		p_walker.eCode |= int(p_walker.u.pTab.aCol[p_expr.iColumn].colFlags)
	}
	return 0
}

@[c:'sqlite3ComputeGeneratedColumns']
fn sqlite3_compute_generated_columns(p_parse &Parse, i_reg_store int, p_tab &Table) {
	i := 0
	w := Walker{}
	p_redo := &Column(0)
	e_progress := 0
	p_op := &VdbeOp(0)
	0
	0
	sqlite3_table_affinity(p_parse.pVdbe, p_tab, i_reg_store)
	if (p_tab.tabFlags & u32(64)) != u32(0) {
		p_op = sqlite3_vdbe_get_last_op(p_parse.pVdbe)
		if int(p_op.opcode) == 98 {
			ii := 0
			jj := 0

			z_p4 := p_op.p4.z
			jj = 0
			for ii = 0; z_p4[jj]; ii++ {
				if int(p_tab.aCol[ii].colFlags) & 32 {
					continue
				}
				if int(p_tab.aCol[ii].colFlags) & 64 {
					z_p4[jj] = i8(64)
				}
				jj++
			}
		} else if int(p_op.opcode) == 97 {
			p_op.p3 = 1
		}
	}
	for i = 0; i < int(p_tab.nCol); i++ {
		if int(p_tab.aCol[i].colFlags) & 96 {
			0
			0
			p_tab.aCol[i].colFlags |= 128
		}
	}
	w.u.pTab = p_tab
	w.xExprCallback = expr_column_flag_union
	w.xSelectCallback = 0
	w.xSelectCallback2 = 0
	p_parse.iSelfTab = -i_reg_store
	for {
		e_progress = 0
		p_redo = 0
		for i = 0; i < int(p_tab.nCol); i++ {
			p_col := p_tab.aCol + i
			if (int(p_col.colFlags) & 128) != 0 {
				x := 0
				p_col.colFlags |= 256
				w.eCode = U16(0)
				sqlite3_walk_expr(&w, sqlite3_column_expr(p_tab, p_col))
				p_col.colFlags &= ~256
				if int(w.eCode) & 128 {
					p_redo = p_col
					continue
				}
				e_progress = 1
				x = int(sqlite3_table_column_to_storage(p_tab, I16(i))) + i_reg_store
				sqlite3_expr_code_generated_column(p_parse, p_tab, p_col, x)
				p_col.colFlags &= ~128
			}
		}
		if !(!isnil(p_redo) && e_progress) {
			break
		}
	}
	if p_redo {
		sqlite3_error_msg(p_parse, c'generated column loop on "%s"', voidptr(p_redo.zCnName))
	}
	p_parse.iSelfTab = 0
}

@[c:'autoIncBegin']
fn auto_inc_begin(p_parse &Parse, i_db int, p_tab &Table) int {
	mem_id := 0
	if (p_tab.tabFlags & u32(8)) != u32(0) && (p_parse.db.mDbFlags & u32(4)) == u32(0) {
		p_toplevel := (if p_parse.pToplevel { p_parse.pToplevel } else { p_parse })
		p_info := &AutoincInfo(0)
		p_seq_tab := p_parse.db.aDb[i_db].pSchema.pSeqTab
		if usize(p_seq_tab) == usize(0) || !((p_seq_tab.tabFlags & u32(128)) == u32(0)) || (int(p_seq_tab.eTabType) == 1) || int(p_seq_tab.nCol) != 2 {
			p_parse.nErr++
			p_parse.rc = (11 | (2 << 8))
			return 0
		}
		p_info = p_toplevel.pAinc
		for !isnil(p_info) && usize(p_info.pTab) != usize(p_tab) {
			p_info = p_info.pNext
		}
		if usize(p_info) == usize(0) {
			p_info = sqlite3_db_malloc_raw_nn(p_parse.db, U64(sizeof(AutoincInfo)))
			sqlite3_parser_add_cleanup(p_toplevel, sqlite3_db_free, voidptr(p_info))
			0
			if p_parse.db.mallocFailed {
				return 0
			}
			p_info.pNext = p_toplevel.pAinc
			p_toplevel.pAinc = p_info
			p_info.pTab = p_tab
			p_info.iDb = i_db
			p_toplevel.nMem++
			p_info.regCtr = c2v_prefix_add(unsafe { &p_toplevel.nMem }, 1)
			p_toplevel.nMem += 2
		}
		mem_id = p_info.regCtr
	}
	return mem_id
}

@[c:'sqlite3AutoincrementBegin']
fn sqlite3_autoincrement_begin(p_parse &Parse) {
	p := &AutoincInfo(0)
	db := p_parse.db
	p_db := &Db(0)
	mem_id := 0
	v := p_parse.pVdbe
	for p = p_parse.pAinc; p; p = p.pNext {
		static i_ln := 0
		if !sqlite3_autoincrement_begin_auto_inc_inited {
			c2v_static_init := [VdbeOpList{
				opcode: U8(77)
				p1: i8(0)
				p2: i8(0)
				p3: i8(0)
			}, VdbeOpList{
				opcode: U8(36)
				p1: i8(0)
				p2: i8(10)
				p3: i8(0)
			}, VdbeOpList{
				opcode: U8(96)
				p1: i8(0)
				p2: i8(0)
				p3: i8(0)
			}, VdbeOpList{
				opcode: U8(53)
				p1: i8(0)
				p2: i8(9)
				p3: i8(0)
			}, VdbeOpList{
				opcode: U8(137)
				p1: i8(0)
				p2: i8(0)
				p3: i8(0)
			}, VdbeOpList{
				opcode: U8(96)
				p1: i8(0)
				p2: i8(1)
				p3: i8(0)
			}, VdbeOpList{
				opcode: U8(88)
				p1: i8(0)
				p2: i8(0)
				p3: i8(0)
			}, VdbeOpList{
				opcode: U8(82)
				p1: i8(0)
				p2: i8(0)
				p3: i8(0)
			}, VdbeOpList{
				opcode: U8(9)
				p1: i8(0)
				p2: i8(11)
				p3: i8(0)
			}, VdbeOpList{
				opcode: U8(40)
				p1: i8(0)
				p2: i8(2)
				p3: i8(0)
			}, VdbeOpList{
				opcode: U8(73)
				p1: i8(0)
				p2: i8(0)
				p3: i8(0)
			}, VdbeOpList{
				opcode: U8(124)
				p1: i8(0)
				p2: i8(0)
				p3: i8(0)
			}]
			for c2v_i_0, c2v_element_0 in c2v_static_init {
				sqlite3_autoincrement_begin_auto_inc[c2v_i_0] = c2v_element_0
			}
			sqlite3_autoincrement_begin_auto_inc_inited = true
		}

		mut a_op := &VdbeOp(0)
		p_db = unsafe { db.aDb + p.iDb }
		mem_id = p.regCtr
		sqlite3_open_table(p_parse, 0, p.iDb, p_db.pSchema.pSeqTab, 114)
		sqlite3_vdbe_load_string(v, mem_id - 1, p.pTab.zName)
		a_op = sqlite3_vdbe_add_op_list(v, 12, &sqlite3_autoincrement_begin_auto_inc[0], i_ln)
		if usize(a_op) == usize(0) {
			break
		}
		a_op[0].p2 = mem_id
		a_op[0].p3 = mem_id + 2
		a_op[2].p3 = mem_id
		a_op[3].p1 = mem_id - 1
		a_op[3].p3 = mem_id
		a_op[3].p5 = U16(16)
		a_op[4].p2 = mem_id + 1
		a_op[5].p3 = mem_id
		a_op[6].p1 = mem_id
		a_op[7].p2 = mem_id + 2
		a_op[7].p1 = mem_id
		a_op[10].p2 = mem_id
		if p_parse.nTab == 0 {
			p_parse.nTab = 1
		}
	}
}

@[c:'autoIncStep']
fn auto_inc_step(p_parse &Parse, mem_id int, reg_rowid int) {
	if mem_id > 0 {
		sqlite3_vdbe_add_op2(p_parse.pVdbe, 161, mem_id, reg_rowid)
	}
}

@[c:'autoIncrementEnd']
fn auto_increment_end(p_parse &Parse) {
	p := &AutoincInfo(0)
	v := p_parse.pVdbe
	db := p_parse.db
	for p = p_parse.pAinc; p; p = p.pNext {
		static i_ln := 0
		if !auto_increment_end_auto_inc_end_inited {
			c2v_static_init := [VdbeOpList{
				opcode: U8(52)
				p1: i8(0)
				p2: i8(2)
				p3: i8(0)
			}, VdbeOpList{
				opcode: U8(129)
				p1: i8(0)
				p2: i8(0)
				p3: i8(0)
			}, VdbeOpList{
				opcode: U8(99)
				p1: i8(0)
				p2: i8(2)
				p3: i8(0)
			}, VdbeOpList{
				opcode: U8(130)
				p1: i8(0)
				p2: i8(0)
				p3: i8(0)
			}, VdbeOpList{
				opcode: U8(124)
				p1: i8(0)
				p2: i8(0)
				p3: i8(0)
			}]
			for c2v_i_0, c2v_element_0 in c2v_static_init {
				auto_increment_end_auto_inc_end[c2v_i_0] = c2v_element_0
			}
			auto_increment_end_auto_inc_end_inited = true
		}

		mut a_op := &VdbeOp(0)
		p_db := unsafe { db.aDb + p.iDb }
		i_rec := 0
		mem_id := p.regCtr
		i_rec = sqlite3_get_temp_reg(p_parse)
		sqlite3_vdbe_add_op3(v, 56, mem_id + 2, sqlite3_vdbe_current_addr(v) + 7, mem_id)
		0
		sqlite3_open_table(p_parse, 0, p.iDb, p_db.pSchema.pSeqTab, 116)
		a_op = sqlite3_vdbe_add_op_list(v, 5, &auto_increment_end_auto_inc_end[0], i_ln)
		if usize(a_op) == usize(0) {
			break
		}
		a_op[0].p1 = mem_id + 1
		a_op[1].p2 = mem_id + 1
		a_op[2].p1 = mem_id - 1
		a_op[2].p3 = i_rec
		a_op[3].p2 = i_rec
		a_op[3].p3 = mem_id + 1
		a_op[3].p5 = U16(8)
		sqlite3_release_temp_reg(p_parse, i_rec)
	}
}

@[c:'sqlite3AutoincrementEnd']
fn sqlite3_autoincrement_end(p_parse &Parse) {
	if p_parse.pAinc {
		auto_increment_end(p_parse)
	}
}

@[c:'sqlite3MultiValuesEnd']
fn sqlite3_multi_values_end(p_parse &Parse, p_val &Select) {
	if !isnil(p_val) && p_val.pSrc.nSrc > 0 {
		p_item := unsafe { &p_val.pSrc.a[0] + 0 }
		if p_item.fg.isSubquery {
			sqlite3_vdbe_end_coroutine(p_parse.pVdbe, p_item.u4.pSubq.regReturn)
			sqlite3_vdbe_jump_here(p_parse.pVdbe, p_item.u4.pSubq.addrFillSub - 1)
		}
	}
}

@[c:'exprListIsConstant']
fn expr_list_is_constant(p_parse &Parse, p_row &ExprList) int {
	ii := 0
	for ii = 0; ii < p_row.nExpr; ii++ {
		if 0 == sqlite3_expr_is_constant(p_parse, c2v_at(&p_row.a[0], isize(ii)).pExpr) {
			return 0
		}
	}
	return 1
}

@[c:'exprListIsNoAffinity']
fn expr_list_is_no_affinity(p_parse &Parse, p_row &ExprList) int {
	ii := 0
	if expr_list_is_constant(p_parse, p_row) == 0 {
		return 0
	}
	for ii = 0; ii < p_row.nExpr; ii++ {
		p_expr := c2v_at(&p_row.a[0], isize(ii)).pExpr
		if 0 != int(sqlite3_expr_affinity(p_expr)) {
			return 0
		}
	}
	return 1
}

@[c:'sqlite3MultiValues']
fn sqlite3_multi_values(p_parse &Parse, p_left &Select, p_row &ExprList) &Select {
	mut __c2v_condition_66 := false
	mut __c2v_condition_67 := false
	__c2v_condition_67 = int(p_parse.bHasWith)
	__c2v_condition_66 = __c2v_condition_67
	if !__c2v_condition_66 {
		mut __c2v_condition_68 := false
		__c2v_condition_68 = int(p_parse.db.init.busy)
		__c2v_condition_66 = __c2v_condition_68
	}
	if !__c2v_condition_66 {
		mut __c2v_condition_69 := false
		__c2v_condition_69 = expr_list_is_constant(p_parse, p_row) == 0
		__c2v_condition_66 = __c2v_condition_69
	}
	if !__c2v_condition_66 {
		mut __c2v_condition_70 := false
		__c2v_condition_70 = (p_left.pSrc.nSrc == 0 && expr_list_is_no_affinity(p_parse, p_left.pEList) == 0)
		__c2v_condition_66 = __c2v_condition_70
	}
	if !__c2v_condition_66 {
		mut __c2v_condition_71 := false
		__c2v_condition_71 = (int(p_parse.eParseMode) != 0)
		__c2v_condition_66 = __c2v_condition_71
	}
	if __c2v_condition_66 {
		p_select := unsafe { &Select(nil) }
		f := 512 | 1024
		if p_left.pSrc.nSrc {
			sqlite3_multi_values_end(p_parse, p_left)
			f = 512
		} else if p_left.pPrior {
			f = int((u32(f) & p_left.selFlags))
		}
		p_select = sqlite3_select_new(p_parse, p_row, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, u32(f), unsafe { nil })
		p_left.selFlags &= ~u32(1024)
		if p_select {
			p_select.op = U8(136)
			p_select.pPrior = p_left
			p_left = p_select
		}
	} else {
		p := unsafe { &SrcItem(nil) }
		if p_left.pSrc.nSrc == 0 {
			v := sqlite3_get_vdbe(p_parse)
			p_ret := sqlite3_select_new(p_parse, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, u32(0), unsafe { nil })
			if (p_parse.db.mDbFlags & u32(16)) == u32(0) {
				sqlite3_read_schema(p_parse)
			}
			if p_ret {
				dest := SelectDest{}
				p_subq := &Subquery(0)
				p_ret.pSrc.nSrc = 1
				p_ret.pPrior = p_left.pPrior
				p_ret.op = p_left.op
				if p_ret.pPrior {
					p_ret.selFlags |= u32(512)
				}
				p_left.pPrior = 0
				p_left.op = U8(139)
				p = unsafe { &p_ret.pSrc.a[0] + 0 }
				p.fg.viaCoroutine = u32(1)
				p.iCursor = -1
				p.u1.nRow = u32(2)
				if sqlite3_src_item_attach_subquery(p_parse, p, p_left, 0) {
					p_subq = p.u4.pSubq
					p_subq.addrFillSub = sqlite3_vdbe_current_addr(v) + 1
					p_subq.regReturn = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
					sqlite3_vdbe_add_op3(v, 11, p_subq.regReturn, 0, p_subq.addrFillSub)
					sqlite3_select_dest_init(&dest, 11, p_subq.regReturn)
					dest.iSdst = p_parse.nMem + 3
					dest.nSdst = p_left.pEList.nExpr
					p_parse.nMem += 2 + dest.nSdst
					p_left.selFlags |= u32(1024)
					sqlite3_select(p_parse, p_left, &dest)
					p_subq.regResult = dest.iSdst
				}
				p_left = p_ret
			}
		} else {
			p = unsafe { &p_left.pSrc.a[0] + 0 }
			p.u1.nRow++
		}
		if p_parse.nErr == 0 {
			p_subq := &Subquery(0)
			p_subq = p.u4.pSubq
			if p_subq.pSelect.pEList.nExpr != p_row.nExpr {
				sqlite3_select_wrong_num_terms_error(p_parse, p_subq.pSelect)
			} else {
				sqlite3_expr_code_expr_list(p_parse, p_row, p_subq.regResult, 0, U8(0))
				sqlite3_vdbe_add_op1(p_parse.pVdbe, 12, p_subq.regReturn)
			}
		}
		sqlite3_expr_list_delete(p_parse.db, p_row)
	}
	return p_left
}

@[c:'sqlite3Insert']
fn sqlite3_insert(p_parse &Parse, p_tab_list &SrcList, p_select &Select, p_column &IdList, on_error int, p_upsert &Upsert) {
	db := &Sqlite3(0)
	p_tab := &Table(0)
	i := 0
	j := 0

	v := &Vdbe(0)
	p_idx := &Index(0)
	n_column := 0
	n_hidden := 0
	i_data_cur := 0
	i_idx_cur := 0
	ipk_column := -1
	end_of_loop := 0
	src_tab := 0
	addr_ins_top := 0
	addr_cont := 0
	dest := SelectDest{}
	i_db := 0
	use_temp_table := U8(0)
	append_flag := U8(0)
	without_rowid := U8(0)
	b_id_list_in_order := U8(0)
	p_list := unsafe { &ExprList(nil) }
	i_reg_store := 0
	reg_from_select := 0
	reg_autoinc := 0
	reg_row_count := 0
	reg_ins := 0
	reg_rowid := 0
	reg_data := 0
	a_reg_idx := unsafe { &int(nil) }
	a_tab_col_map := unsafe { &int(nil) }
	is_view := 0
	p_trigger := &Trigger(0)
	tmask := 0
	db = p_parse.db
	if p_parse.nErr {
		unsafe { goto insert_cleanup
		 }
	}
	dest.iSDParm = 0
	if !isnil(p_select) && (p_select.selFlags & u32(512)) != u32(0) && usize(p_select.pPrior) == usize(0) {
		p_list = p_select.pEList
		p_select.pEList = 0
		sqlite3_select_delete(db, p_select)
		p_select = 0
	}
	p_tab = sqlite3_src_list_lookup(p_parse, p_tab_list)
	if usize(p_tab) == usize(0) {
		unsafe { goto insert_cleanup
		 }
	}
	i_db = sqlite3_schema_to_index(db, p_tab.pSchema)
	if sqlite3_auth_check(p_parse, 18, p_tab.zName, unsafe { nil }, db.aDb[i_db].zDbSName) {
		unsafe { goto insert_cleanup
		 }
	}
	without_rowid = U8(!((p_tab.tabFlags & u32(128)) == u32(0)))
	p_trigger = sqlite3_triggers_exist(p_parse, p_tab, 128, unsafe { nil }, &tmask)
	is_view = (int(p_tab.eTabType) == 2)
	if sqlite3_view_get_column_names(p_parse, p_tab) {
		unsafe { goto insert_cleanup
		 }
	}
	if sqlite3_is_read_only(p_parse, p_tab, p_trigger) {
		unsafe { goto insert_cleanup
		 }
	}
	v = sqlite3_get_vdbe(p_parse)
	if usize(v) == usize(0) {
		unsafe { goto insert_cleanup
		 }
	}
	if int(p_parse.nested) == 0 {
		sqlite3_vdbe_count_changes(v)
	}
	sqlite3_begin_write_operation(p_parse, !isnil(p_select) || !isnil(p_trigger), i_db)
	if usize(p_column) == usize(0) && usize(p_select) != usize(0) && usize(p_trigger) == usize(0) && xfer_optimization(p_parse, p_tab, p_select, on_error, i_db) {
		unsafe { goto insert_end
		 }
	}
	reg_autoinc = auto_inc_begin(p_parse, i_db, p_tab)
	reg_ins = p_parse.nMem + 1
	reg_rowid = reg_ins
	p_parse.nMem += int(p_tab.nCol) + 1
	if (int(p_tab.eTabType) == 1) {
		reg_rowid++
		p_parse.nMem++
	}
	reg_data = reg_rowid + 1
	b_id_list_in_order = U8((p_tab.tabFlags & u32((1024 | 64))) == u32(0))
	if p_column {
		a_tab_col_map = sqlite3_db_malloc_zero(db, U64(u64(p_tab.nCol) * sizeof(int)))
		if usize(a_tab_col_map) == usize(0) {
			unsafe { goto insert_cleanup
			 }
		}
		for i = 0; i < p_column.nId; i++ {
			j = sqlite3_column_index(p_tab, c2v_at(&p_column.a[0], isize(i)).zName)
			if j >= 0 {
				if a_tab_col_map[j] == 0 {
					a_tab_col_map[j] = i + 1
				}
				if i != j {
					b_id_list_in_order = U8(0)
				}
				if j == int(p_tab.iPKey) {
					ipk_column = i
				}
				if int(p_tab.aCol[j].colFlags) & (64 | 32) {
					sqlite3_error_msg(p_parse, c'cannot INSERT into generated column "%s"', voidptr(p_tab.aCol[j].zCnName))
					unsafe { goto insert_cleanup
					 }
				}
			} else {
				if sqlite3_is_rowid(c2v_at(&p_column.a[0], isize(i)).zName) && !without_rowid {
					ipk_column = i
					b_id_list_in_order = U8(0)
				} else {
					sqlite3_error_msg(p_parse, c'table %S has no column named %s', voidptr(&p_tab_list.a[0]), voidptr(c2v_at(&p_column.a[0], isize(i)).zName))
					p_parse.checkSchema = Bft(1)
					unsafe { goto insert_cleanup
					 }
				}
			}
		}
	}
	if p_select {
		rc := 0
		if p_select.pSrc.nSrc == 1 && int(c2v_at(&p_select.pSrc.a[0], isize(0)).fg.viaCoroutine) && usize(p_select.pPrior) == usize(0) {
			p_item := unsafe { &p_select.pSrc.a[0] + 0 }
			p_subq := &Subquery(0)
			p_subq = p_item.u4.pSubq
			dest.iSDParm = p_subq.regReturn
			reg_from_select = p_subq.regResult
			n_column = p_subq.pSelect.pEList.nExpr
			sqlite3_vdbe_explain(p_parse, U8(0), c'SCAN %S', voidptr(p_item))
			if int(b_id_list_in_order) && n_column == int(p_tab.nCol) {
				reg_data = reg_from_select
				reg_rowid = reg_data - 1
				reg_ins = reg_rowid - (if (int(p_tab.eTabType) == 1) { 1 } else { 0 })
			}
		} else {
			addr_top := 0
			reg_yield := c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			addr_top = sqlite3_vdbe_current_addr(v) + 1
			sqlite3_vdbe_add_op3(v, 11, reg_yield, 0, addr_top)
			sqlite3_select_dest_init(&dest, 11, reg_yield)
			dest.iSdst = if int(b_id_list_in_order) { reg_data } else { 0 }
			dest.nSdst = int(p_tab.nCol)
			rc = sqlite3_select(p_parse, p_select, &dest)
			reg_from_select = dest.iSdst
			if rc || p_parse.nErr {
				unsafe { goto insert_cleanup
				 }
			}
			sqlite3_vdbe_end_coroutine(v, reg_yield)
			sqlite3_vdbe_jump_here(v, addr_top - 1)
			n_column = p_select.pEList.nExpr
		}
		if !isnil(p_trigger) || reads_table(p_parse, i_db, p_tab) {
			use_temp_table = U8(1)
		}
		if use_temp_table {
			reg_rec := 0
			reg_temp_rowid := 0
			addr_l := 0
			mut __c2v_postfix_value_18 := p_parse.nTab
			p_parse.nTab++
			src_tab = __c2v_postfix_value_18
			reg_rec = sqlite3_get_temp_reg(p_parse)
			reg_temp_rowid = sqlite3_get_temp_reg(p_parse)
			sqlite3_vdbe_add_op2(v, 120, src_tab, n_column)
			addr_l = sqlite3_vdbe_add_op1(v, 12, dest.iSDParm)
			0
			sqlite3_vdbe_add_op3(v, 99, reg_from_select, n_column, reg_rec)
			sqlite3_vdbe_add_op2(v, 129, src_tab, reg_temp_rowid)
			sqlite3_vdbe_add_op3(v, 130, src_tab, reg_rec, reg_temp_rowid)
			sqlite3_vdbe_goto(v, addr_l)
			sqlite3_vdbe_jump_here(v, addr_l)
			sqlite3_release_temp_reg(p_parse, reg_rec)
			sqlite3_release_temp_reg(p_parse, reg_temp_rowid)
		}
	} else {
		snc := NameContext{}
		C.memset(voidptr(&snc), 0, sizeof(snc))
		snc.pParse = p_parse
		src_tab = -1
		if p_list {
			n_column = p_list.nExpr
			if sqlite3_resolve_expr_list_names(&snc, p_list) {
				unsafe { goto insert_cleanup
				 }
			}
		} else {
			n_column = 0
		}
	}
	if usize(p_column) == usize(0) && n_column > 0 {
		ipk_column = int(p_tab.iPKey)
		if ipk_column >= 0 && (p_tab.tabFlags & u32(96)) != u32(0) {
			0
			0
			for i = ipk_column - 1; i >= 0; i-- {
				if int(p_tab.aCol[i].colFlags) & 96 {
					0
					0
					ipk_column--
				}
			}
		}
		if (p_tab.tabFlags & u32((96 | 2))) != u32(0) {
			for i = 0; i < int(p_tab.nCol); i++ {
				if int(p_tab.aCol[i].colFlags) & 98 {
					n_hidden++
				}
			}
		}
		if n_column != (int(p_tab.nCol) - n_hidden) {
			sqlite3_error_msg(p_parse, c'table %S has %d columns but %d values were supplied', voidptr(&p_tab_list.a[0]), int(p_tab.nCol) - n_hidden, n_column)
			unsafe { goto insert_cleanup
			 }
		}
	}
	if usize(p_column) != usize(0) && n_column != p_column.nId {
		sqlite3_error_msg(p_parse, c'%d values for %d columns', n_column, p_column.nId)
		unsafe { goto insert_cleanup
		 }
	}
	if (db.flags & (U64(1) << 32)) != U64(0) && !p_parse.nested && isnil(p_parse.pTriggerTab) && !p_parse.bReturning {
		reg_row_count = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
		sqlite3_vdbe_add_op2(v, 73, 0, reg_row_count)
	}
	if !is_view {
		n_idx := 0
		n_idx = sqlite3_open_table_and_indices(p_parse, p_tab, 116, U8(0), -1, unsafe { nil }, &i_data_cur, &i_idx_cur)
		a_reg_idx = sqlite3_db_malloc_raw_nn(db, U64(sizeof(int) * u64((n_idx + 2))))
		if usize(a_reg_idx) == usize(0) {
			unsafe { goto insert_cleanup
			 }
		}
		i = 0
		for p_idx = p_tab.pIndex; i < n_idx;  {
			a_reg_idx[i] = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			p_parse.nMem += int(p_idx.nColumn)
			p_idx = p_idx.pNext
			i++
		}
		a_reg_idx[i] = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
	}
	if p_upsert {
		p_nx := &Upsert(0)
		if (int(p_tab.eTabType) == 1) {
			sqlite3_error_msg(p_parse, c'UPSERT not implemented for virtual table "%s"', voidptr(p_tab.zName))
			unsafe { goto insert_cleanup
			 }
		}
		if (int(p_tab.eTabType) == 2) {
			sqlite3_error_msg(p_parse, c'cannot UPSERT a view')
			unsafe { goto insert_cleanup
			 }
		}
		if sqlite3_has_explicit_nulls(p_parse, p_upsert.pUpsertTarget) {
			unsafe { goto insert_cleanup
			 }
		}
		mut __c2v_lhs_tmp_132 := c2v_at(&p_tab_list.a[0], isize(0))
		__c2v_lhs_tmp_132.iCursor = i_data_cur
		p_nx = p_upsert
		for {
			p_nx.pUpsertSrc = p_tab_list
			p_nx.regData = reg_data
			p_nx.iDataCur = i_data_cur
			p_nx.iIdxCur = i_idx_cur
			if p_nx.pUpsertTarget {
				if sqlite3_upsert_analyze_target(p_parse, p_tab_list, p_nx, p_upsert) {
					unsafe { goto insert_cleanup
					 }
				}
			}
			p_nx = p_nx.pNextUpsert
			if !(usize(p_nx) != usize(0)) {
				break
			}
		}
	}
	if use_temp_table {
		addr_ins_top = sqlite3_vdbe_add_op1(v, 36, src_tab)
		0
		addr_cont = sqlite3_vdbe_current_addr(v)
	} else if p_select {
		0
		addr_cont = sqlite3_vdbe_add_op1(v, 12, dest.iSDParm)
		addr_ins_top = addr_cont
		0
		if ipk_column >= 0 {
			sqlite3_vdbe_add_op2(v, 82, reg_from_select + ipk_column, reg_rowid)
		}
	}
	n_hidden = 0
	i_reg_store = reg_data
	for i = 0; i < int(p_tab.nCol); i++ {
		k := 0
		col_flags := u32(0)
		if i == int(p_tab.iPKey) {
			sqlite3_vdbe_add_op1(v, 78, i_reg_store)
			unsafe { goto c2v_for_next_120
			 }
		}
		col_flags = u32(p_tab.aCol[i].colFlags)
		if (col_flags & u32(98)) != u32(0) {
			n_hidden++
			if (col_flags & u32(32)) != u32(0) {
				i_reg_store--
				unsafe { goto c2v_for_next_120
				 }
			} else if (col_flags & u32(64)) != u32(0) {
				if tmask & 1 {
					sqlite3_vdbe_add_op1(v, 78, i_reg_store)
				}
				unsafe { goto c2v_for_next_120
				 }
			} else if usize(p_column) == usize(0) {
				sqlite3_expr_code_factorable(p_parse, sqlite3_column_expr(p_tab, unsafe { p_tab.aCol + i }), i_reg_store)
				unsafe { goto c2v_for_next_120
				 }
			}
		}
		if p_column {
			j = a_tab_col_map[i]
			if j == 0 {
				sqlite3_expr_code_factorable(p_parse, sqlite3_column_expr(p_tab, unsafe { p_tab.aCol + i }), i_reg_store)
				unsafe { goto c2v_for_next_120
				 }
			}
			k = j - 1
		} else if n_column == 0 {
			sqlite3_expr_code_factorable(p_parse, sqlite3_column_expr(p_tab, unsafe { p_tab.aCol + i }), i_reg_store)
			unsafe { goto c2v_for_next_120
			 }
		} else {
			k = i - n_hidden
		}
		if use_temp_table {
			sqlite3_vdbe_add_op3(v, 96, src_tab, k, i_reg_store)
		} else if p_select {
			if reg_from_select != reg_data {
				sqlite3_vdbe_add_op2(v, 83, reg_from_select + k, i_reg_store)
			}
		} else {
			px := c2v_at(&p_list.a[0], isize(k)).pExpr
			y := sqlite3_expr_code_target(p_parse, px, i_reg_store)
			if y != i_reg_store {
				sqlite3_vdbe_add_op2(v, if ((px.flags & u32(4194304)) != u32(0)) { 82 } else { 83 }, y, i_reg_store)
			}
		}
		c2v_for_next_120:
		i_reg_store++
	}
	end_of_loop = sqlite3_vdbe_make_label(p_parse)
	if tmask & 1 {
		reg_cols := sqlite3_get_temp_range(p_parse, int(p_tab.nCol) + 1)
		if ipk_column < 0 {
			sqlite3_vdbe_add_op2(v, 73, -1, reg_cols)
		} else {
			addr1 := 0
			if use_temp_table {
				sqlite3_vdbe_add_op3(v, 96, src_tab, ipk_column, reg_cols)
			} else {
				sqlite3_expr_code(p_parse, c2v_at(&p_list.a[0], isize(ipk_column)).pExpr, reg_cols)
			}
			addr1 = sqlite3_vdbe_add_op1(v, 52, reg_cols)
			0
			sqlite3_vdbe_add_op2(v, 73, -1, reg_cols)
			sqlite3_vdbe_jump_here(v, addr1)
			sqlite3_vdbe_add_op1(v, 13, reg_cols)
			0
		}
		sqlite3_vdbe_add_op3(v, 82, reg_rowid + 1, reg_cols + 1, int(p_tab.nNVCol) - 1)
		if p_tab.tabFlags & u32(96) {
			0
			0
			sqlite3_compute_generated_columns(p_parse, reg_cols + 1, p_tab)
		}
		if !is_view {
			sqlite3_table_affinity(v, p_tab, reg_cols + 1)
		}
		sqlite3_code_row_trigger(p_parse, p_trigger, 128, unsafe { nil }, 1, p_tab, reg_cols - int(p_tab.nCol) - 1, on_error, end_of_loop)
		sqlite3_release_temp_range(p_parse, reg_cols, int(p_tab.nCol) + 1)
	}
	if !is_view {
		if (int(p_tab.eTabType) == 1) {
			sqlite3_vdbe_add_op2(v, 77, 0, reg_ins)
		}
		if ipk_column >= 0 {
			if use_temp_table {
				sqlite3_vdbe_add_op3(v, 96, src_tab, ipk_column, reg_rowid)
			} else if p_select {
			} else {
				p_ipk := c2v_at(&p_list.a[0], isize(ipk_column)).pExpr
				if int(p_ipk.op) == 122 && !(int(p_tab.eTabType) == 1) {
					sqlite3_vdbe_add_op3(v, 129, i_data_cur, reg_rowid, reg_autoinc)
					append_flag = U8(1)
				} else {
					sqlite3_expr_code(p_parse, c2v_at(&p_list.a[0], isize(ipk_column)).pExpr, reg_rowid)
				}
			}
			if !append_flag {
				addr1 := 0
				if !(int(p_tab.eTabType) == 1) {
					addr1 = sqlite3_vdbe_add_op1(v, 52, reg_rowid)
					0
					sqlite3_vdbe_add_op3(v, 129, i_data_cur, reg_rowid, reg_autoinc)
					sqlite3_vdbe_jump_here(v, addr1)
				} else {
					addr1 = sqlite3_vdbe_current_addr(v)
					sqlite3_vdbe_add_op2(v, 51, reg_rowid, addr1 + 2)
					0
				}
				sqlite3_vdbe_add_op1(v, 13, reg_rowid)
				0
			}
		} else if (int(p_tab.eTabType) == 1) || int(without_rowid) {
			sqlite3_vdbe_add_op2(v, 77, 0, reg_rowid)
		} else {
			sqlite3_vdbe_add_op3(v, 129, i_data_cur, reg_rowid, reg_autoinc)
			append_flag = U8(1)
		}
		auto_inc_step(p_parse, reg_autoinc, reg_rowid)
		if p_tab.tabFlags & u32(96) {
			sqlite3_compute_generated_columns(p_parse, reg_rowid + 1, p_tab)
		}
		if (int(p_tab.eTabType) == 1) {
			pvt_ab := &i8(voidptr(sqlite3_get_vt_able(db, p_tab)))
			sqlite3_vtab_make_writable(p_parse, p_tab)
			sqlite3_vdbe_add_op4(v, 7, 1, int(p_tab.nCol) + 2, reg_ins, pvt_ab, (-12))
			sqlite3_vdbe_change_p5(v, U16(if on_error == 11 { 2 } else { on_error }))
			sqlite3_may_abort(p_parse)
		} else {
			is_replace := 0
			b_use_seek := 0
			sqlite3_generate_constraint_checks(p_parse, p_tab, a_reg_idx, i_data_cur, i_idx_cur, reg_ins, 0, U8(ipk_column >= 0), U8(on_error), end_of_loop, &is_replace, unsafe { nil }, p_upsert)
			if db.flags & U64(16384) {
				sqlite3_fk_check(p_parse, p_tab, 0, reg_ins, unsafe { nil }, 0)
			}
			b_use_seek = (is_replace == 0 || !sqlite3_vdbe_has_sub_program(v))
			sqlite3_complete_insertion(p_parse, p_tab, i_data_cur, i_idx_cur, reg_ins, a_reg_idx, 0, int(append_flag), b_use_seek)
		}
	}
	if reg_row_count {
		sqlite3_vdbe_add_op2(v, 88, reg_row_count, 1)
	}
	if p_trigger {
		sqlite3_code_row_trigger(p_parse, p_trigger, 128, unsafe { nil }, 2, p_tab, reg_data - 2 - int(p_tab.nCol), on_error, end_of_loop)
	}
	sqlite3_vdbe_resolve_label(v, end_of_loop)
	if use_temp_table {
		sqlite3_vdbe_add_op2(v, 40, src_tab, addr_cont)
		0
		sqlite3_vdbe_jump_here(v, addr_ins_top)
		sqlite3_vdbe_add_op1(v, 124, src_tab)
	} else if p_select {
		sqlite3_vdbe_goto(v, addr_cont)
		sqlite3_vdbe_jump_here(v, addr_ins_top)
	}
	insert_end:
	if int(p_parse.nested) == 0 && usize(p_parse.pTriggerTab) == usize(0) {
		sqlite3_autoincrement_end(p_parse)
	}
	if reg_row_count {
		sqlite3_code_change_count(v, reg_row_count, c'rows inserted')
	}
	insert_cleanup:
	sqlite3_src_list_delete(db, p_tab_list)
	sqlite3_expr_list_delete(db, p_list)
	sqlite3_upsert_delete(db, p_upsert)
	sqlite3_select_delete(db, p_select)
	if p_column {
		sqlite3_id_list_delete(db, p_column)
		sqlite3_db_free(db, voidptr(a_tab_col_map))
	}
	if a_reg_idx {
		sqlite3_db_nn_free_nn(db, voidptr(a_reg_idx))
	}
}

@[c:'checkConstraintExprNode']
fn check_constraint_expr_node(p_walker &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()
	if int(p_expr.op) == 168 {
		if int(p_expr.iColumn) >= 0 {
			if p_walker.u.aiCol[p_expr.iColumn] >= 0 {
				p_walker.eCode |= 1
			}
		} else {
			p_walker.eCode |= 2
		}
	}
	return 0
}

@[c:'sqlite3ExprReferencesUpdatedColumn']
fn sqlite3_expr_references_updated_column(p_expr &Expr, ai_chng &int, chng_rowid int) int {
	w := Walker{}
	C.memset(voidptr(&w), 0, sizeof(w))
	w.eCode = U16(0)
	w.xExprCallback = check_constraint_expr_node
	w.u.aiCol = ai_chng
	sqlite3_walk_expr(&w, p_expr)
	if !chng_rowid {
		0
		w.eCode &= ~2
	}
	0
	0
	0
	0
	return int(w.eCode != 0)
}

struct IndexIterator_u_lx {
	pIdx &Index
}

struct IndexIterator_u_ax {
	nIdx int
	aIdx &IndexListTerm
}

union IndexIterator_u {
	lx IndexIterator_u_lx
	ax IndexIterator_u_ax
}

struct IndexIterator {
	eType int
	i     int
	u     IndexIterator_u
}

struct IndexListTerm {
	p  &Index
	ix int
}

@[c:'indexIteratorFirst']
fn index_iterator_first(p_iter &IndexIterator, p_ix &int) &Index {
	if p_iter.eType {
		unsafe { *p_ix = p_iter.u.ax.aIdx[0].ix }
		return p_iter.u.ax.aIdx[0].p
	} else {
		unsafe { *p_ix = 0 }
		return p_iter.u.lx.pIdx
	}
}

@[c:'indexIteratorNext']
fn index_iterator_next(p_iter &IndexIterator, p_ix &int) &Index {
	if p_iter.eType {
		i := c2v_prefix_add(unsafe { &p_iter.i }, 1)
		if i >= p_iter.u.ax.nIdx {
			unsafe { *p_ix = i }
			return unsafe { nil }
		}
		unsafe { *p_ix = p_iter.u.ax.aIdx[i].ix }
		return p_iter.u.ax.aIdx[i].p
	} else {
		unsafe { (*p_ix)++ }
		p_iter.u.lx.pIdx = p_iter.u.lx.pIdx.pNext
		return p_iter.u.lx.pIdx
	}
}

@[c:'sqlite3GenerateConstraintChecks']
fn sqlite3_generate_constraint_checks(p_parse &Parse, p_tab &Table, a_reg_idx &int, i_data_cur int, i_idx_cur int, reg_new_data int, reg_old_data int, pk_chng U8, override_error U8, ignore_dest int, pb_may_replace &int, ai_chng &int, p_upsert &Upsert) {
	v := &Vdbe(0)
	p_idx := &Index(0)
	p_pk := unsafe { &Index(nil) }
	db := &Sqlite3(0)
	i := 0
	ix := 0
	n_col := 0
	on_error := 0
	seen_replace := 0
	n_pk_field := 0
	p_upsert_clause := unsafe { &Upsert(nil) }
	is_update := U8(0)
	b_affinity_done := U8(0)
	upsert_ipk_return := 0
	upsert_ipk_delay := 0
	ipk_top := 0
	ipk_bottom := 0
	reg_trig_cnt := 0
	addr_recheck := 0
	lbl_recheck_ok := 0
	p_trigger := &Trigger(0)
	n_replace_trig := 0
	s_idx_iter := IndexIterator{}
	is_update = U8(reg_old_data != 0)
	db = p_parse.db
	v = p_parse.pVdbe
	n_col = int(p_tab.nCol)
	if ((p_tab.tabFlags & u32(128)) == u32(0)) {
		p_pk = 0
		n_pk_field = 1
	} else {
		p_pk = sqlite3_primary_key_index(p_tab)
		n_pk_field = int(p_pk.nKeyCol)
	}
	0
	if p_tab.tabFlags & u32(2048) {
		b2nd_pass := 0
		n_seen_replace := 0
		n_generated := 0
		for {
			for i = 0; i < n_col; i++ {
				i_reg := 0
				p_col := unsafe { p_tab.aCol + i }
				is_generated := 0
				on_error = int(p_col.notNull)
				if on_error == 0 {
					continue
				}
				if i == int(p_tab.iPKey) {
					continue
				}
				is_generated = int(p_col.colFlags) & 96
				if is_generated && !b2nd_pass {
					n_generated++
					continue
				}
				if !isnil(ai_chng) && ai_chng[i] < 0 && !is_generated {
					continue
				}
				if int(override_error) != 11 {
					on_error = int(override_error)
				} else if on_error == 11 {
					on_error = 2
				}
				if on_error == 5 {
					if b2nd_pass || int(p_col.iDflt) == 0 {
						0
						0
						0
						on_error = 2
					} else {
					}
				} else if b2nd_pass && !is_generated {
					continue
				}
				0
				i_reg = int(sqlite3_table_column_to_storage(p_tab, I16(i))) + reg_new_data + 1
				match on_error {
					5 {
						addr1 := sqlite3_vdbe_add_op1(v, 52, i_reg)
						0
						n_seen_replace++
						sqlite3_expr_code_copy(p_parse, sqlite3_column_expr(p_tab, p_col), i_reg)
						sqlite3_vdbe_jump_here(v, addr1)
					}
					2 {
						sqlite3_may_abort(p_parse)

						unsafe { goto c2v_case_47_3
						 }
					}
					1, 3 {
						c2v_case_47_3:
						z_msg := sqlite3_mp_rintf(db, c'%s.%s', voidptr(p_tab.zName), voidptr(p_col.zCnName))
						0
						sqlite3_vdbe_add_op3(v, 71, (19 | (5 << 8)), on_error, i_reg)
						sqlite3_vdbe_append_p4(v, voidptr(z_msg), (-7))
						sqlite3_vdbe_change_p5(v, U16(1))
						0
					}
					else {
						sqlite3_vdbe_add_op2(v, 51, i_reg, ignore_dest)
						0
					}
				}
			}
			if n_generated == 0 && n_seen_replace == 0 {
				break
			}
			if b2nd_pass {
				break
			}
			b2nd_pass = 1
			if n_seen_replace > 0 && (p_tab.tabFlags & u32(96)) != u32(0) {
				sqlite3_compute_generated_columns(p_parse, reg_new_data + 1, p_tab)
			}
		}
	}
	if !isnil(p_tab.pCheck) && (db.flags & U64(512)) == U64(0) {
		p_check := p_tab.pCheck
		p_parse.iSelfTab = -(reg_new_data + 1)
		on_error = if int(override_error) != 11 { int(override_error) } else { 2 }
		for i = 0; i < p_check.nExpr; i++ {
			all_ok := 0
			p_copy := &Expr(0)
			p_expr := c2v_at(&p_check.a[0], isize(i)).pExpr
			if !isnil(ai_chng) && !sqlite3_expr_references_updated_column(p_expr, ai_chng, int(pk_chng)) {
				continue
			}
			if int(b_affinity_done) == 0 {
				sqlite3_table_affinity(v, p_tab, reg_new_data + 1)
				b_affinity_done = U8(1)
			}
			all_ok = sqlite3_vdbe_make_label(p_parse)
			0
			p_copy = sqlite3_expr_dup(db, p_expr, 0)
			if !db.mallocFailed {
				sqlite3_expr_if_true(p_parse, p_copy, all_ok, 16)
			}
			sqlite3_expr_delete(db, p_copy)
			if on_error == 4 {
				sqlite3_vdbe_goto(v, ignore_dest)
			} else {
				z_name := c2v_at(&p_check.a[0], isize(i)).zEName
				if on_error == 5 {
					on_error = 2
				}
				sqlite3_halt_constraint(p_parse, (19 | (1 << 8)), on_error, z_name, I8(0), U8(3))
			}
			sqlite3_vdbe_resolve_label(v, all_ok)
		}
		p_parse.iSelfTab = 0
	}
	s_idx_iter.eType = 0
	s_idx_iter.i = 0
	s_idx_iter.u.ax.aIdx = 0
	s_idx_iter.u.lx.pIdx = p_tab.pIndex
	if p_upsert {
		if usize(p_upsert.pUpsertTarget) == usize(0) {
			if int(p_upsert.isDoUpdate) == 0 {
				override_error = U8(4)
				p_upsert = 0
			} else {
				override_error = U8(6)
			}
		} else if usize(p_tab.pIndex) != usize(0) {
			n_idx := 0
			jj := 0

			n_byte := U64(0)
			p_term := &Upsert(0)
			b_used := &U8(0)
			n_idx = 0
			for p_idx = p_tab.pIndex; p_idx;  {
				p_idx = p_idx.pNext
				n_idx++
			}
			s_idx_iter.eType = 1
			s_idx_iter.u.ax.nIdx = n_idx
			n_byte = U64((sizeof(IndexListTerm) + u64(1)) * u64(n_idx) + u64(n_idx))
			s_idx_iter.u.ax.aIdx = sqlite3_db_malloc_zero(db, n_byte)
			if usize(s_idx_iter.u.ax.aIdx) == usize(0) {
				return
			}
			b_used = &U8(voidptr(unsafe { s_idx_iter.u.ax.aIdx + n_idx }))
			p_upsert.pToFree = s_idx_iter.u.ax.aIdx
			i = 0
			for p_term = p_upsert; p_term; p_term = p_term.pNextUpsert {
				if usize(p_term.pUpsertTarget) == usize(0) {
					break
				}
				if usize(p_term.pUpsertIdx) == usize(0) {
					continue
				}
				jj = 0
				p_idx = p_tab.pIndex
				for (usize(p_idx) != usize(0)) && usize(p_idx) != usize(p_term.pUpsertIdx) {
					p_idx = p_idx.pNext
					jj++
				}
				if b_used[jj] {
					continue
				}
				b_used[jj] = U8(1)
				s_idx_iter.u.ax.aIdx[i].p = p_idx
				s_idx_iter.u.ax.aIdx[i].ix = jj
				i++
			}
			jj = 0
			for p_idx = p_tab.pIndex; p_idx;  {
				if b_used[jj] {
					unsafe { goto c2v_for_next_122
					 }
				}
				s_idx_iter.u.ax.aIdx[i].p = p_idx
				s_idx_iter.u.ax.aIdx[i].ix = jj
				i++
				c2v_for_next_122:
				p_idx = p_idx.pNext
				jj++
			}
		}
	}
	if (db.flags & U64((8192 | 16384))) == U64(0) {
		p_trigger = 0
		reg_trig_cnt = 0
	} else {
		if db.flags & U64(8192) {
			p_trigger = sqlite3_triggers_exist(p_parse, p_tab, 129, unsafe { nil }, unsafe { nil })
			reg_trig_cnt = usize(p_trigger) != usize(0) || sqlite3_fk_required(p_parse, p_tab, unsafe { nil }, 0)
		} else {
			p_trigger = 0
			reg_trig_cnt = sqlite3_fk_required(p_parse, p_tab, unsafe { nil }, 0)
		}
		if reg_trig_cnt {
			reg_trig_cnt = c2v_prefix_add(unsafe { &p_parse.nMem }, 1)
			sqlite3_vdbe_add_op2(v, 73, 0, reg_trig_cnt)
			0
			lbl_recheck_ok = sqlite3_vdbe_make_label(p_parse)
			addr_recheck = lbl_recheck_ok
		}
	}
	if int(pk_chng) && usize(p_pk) == usize(0) {
		addr_rowid_ok := sqlite3_vdbe_make_label(p_parse)
		on_error = int(p_tab.keyConf)
		if int(override_error) != 11 {
			on_error = int(override_error)
		} else if on_error == 11 {
			on_error = 2
		}
		if p_upsert {
			p_upsert_clause = sqlite3_upsert_of_index(p_upsert, unsafe { nil })
			if usize(p_upsert_clause) != usize(0) {
				if int(p_upsert_clause.isDoUpdate) == 0 {
					on_error = 4
				} else {
					on_error = 6
				}
			}
			if usize(p_upsert_clause) != usize(p_upsert) {
				upsert_ipk_delay = sqlite3_vdbe_add_op0(v, 9)
			}
		}
		if on_error == 5 && on_error != int(override_error) && !isnil(p_tab.pIndex) && !upsert_ipk_delay {
			ipk_top = sqlite3_vdbe_add_op0(v, 9) + 1
			0
		}
		if is_update {
			sqlite3_vdbe_add_op3(v, 54, reg_new_data, addr_rowid_ok, reg_old_data)
			sqlite3_vdbe_change_p5(v, U16(144))
			0
		}
		0
		0
		sqlite3_vdbe_add_op3(v, 31, i_data_cur, addr_rowid_ok, reg_new_data)
		0
		match on_error {
			1, 2, 3 {
				c2v_case_48_1:
				0
				0
				0
				sqlite3_rowid_constraint(p_parse, on_error, p_tab)
			}
			5 {
				if reg_trig_cnt {
					sqlite3_multi_write(p_parse)
					sqlite3_generate_row_delete(p_parse, p_tab, p_trigger, i_data_cur, i_idx_cur, reg_new_data, I16(1), U8(0), U8(5), U8(1), -1)
					sqlite3_vdbe_add_op2(v, 88, reg_trig_cnt, 1)
					n_replace_trig++
				} else {
					if p_tab.pIndex {
						sqlite3_multi_write(p_parse)
						sqlite3_generate_row_index_delete(p_parse, p_tab, i_data_cur, i_idx_cur, unsafe { nil }, -1)
					}
				}
				seen_replace = 1
			}
			6 {
				sqlite3_upsert_do_update(p_parse, p_upsert, p_tab, unsafe { nil }, i_data_cur)

				unsafe { goto c2v_case_48_4
				 }
			}
			4 {
				c2v_case_48_4:
				0
				sqlite3_vdbe_goto(v, ignore_dest)
			}
			else {
				on_error = 2

				unsafe { goto c2v_case_48_1
				 }
			}
		}

		sqlite3_vdbe_resolve_label(v, addr_rowid_ok)
		if !isnil(p_upsert) && usize(p_upsert_clause) != usize(p_upsert) {
			upsert_ipk_return = sqlite3_vdbe_add_op0(v, 9)
		} else if ipk_top {
			ipk_bottom = sqlite3_vdbe_add_op0(v, 9)
			sqlite3_vdbe_jump_here(v, ipk_top - 1)
		}
	}
	for p_idx = index_iterator_first(&s_idx_iter, &ix); p_idx; p_idx = index_iterator_next(&s_idx_iter, &ix) {
		reg_idx := 0
		reg_r := 0
		i_this_cur := 0
		addr_unique_ok := 0
		addr_conflict_ck := 0
		if a_reg_idx[ix] == 0 {
			continue
		}
		if p_upsert {
			p_upsert_clause = sqlite3_upsert_of_index(p_upsert, p_idx)
			if upsert_ipk_delay && usize(p_upsert_clause) == usize(p_upsert) {
				sqlite3_vdbe_jump_here(v, upsert_ipk_delay)
			}
		}
		addr_unique_ok = sqlite3_vdbe_make_label(p_parse)
		if int(b_affinity_done) == 0 {
			sqlite3_table_affinity(v, p_tab, reg_new_data + 1)
			b_affinity_done = U8(1)
		}
		0
		i_this_cur = i_idx_cur + ix
		if p_idx.pPartIdxWhere {
			sqlite3_vdbe_add_op2(v, 77, 0, a_reg_idx[ix])
			p_parse.iSelfTab = -(reg_new_data + 1)
			sqlite3_expr_if_falsedup(p_parse, p_idx.pPartIdxWhere, addr_unique_ok, 16)
			p_parse.iSelfTab = 0
		}
		reg_idx = a_reg_idx[ix] + 1
		for i = 0; i < int(p_idx.nColumn); i++ {
			i_field := int(p_idx.aiColumn[i])
			x := 0
			if i_field == (-2) {
				p_parse.iSelfTab = -(reg_new_data + 1)
				sqlite3_expr_code_copy(p_parse, c2v_at(&p_idx.aColExpr.a[0], isize(i)).pExpr, reg_idx + i)
				p_parse.iSelfTab = 0
				0
			} else if i_field == (-1) || i_field == int(p_tab.iPKey) {
				x = reg_new_data
				sqlite3_vdbe_add_op2(v, 84, x, reg_idx + i)
				0
			} else {
				0
				x = int(sqlite3_table_column_to_storage(p_tab, I16(i_field))) + reg_new_data + 1
				sqlite3_vdbe_add_op2(v, 83, x, reg_idx + i)
				0
			}
		}
		sqlite3_vdbe_add_op3(v, 99, reg_idx, int(p_idx.nColumn), a_reg_idx[ix])
		0
		0
		if int(is_update) && usize(p_pk) == usize(p_idx) && int(pk_chng) == 0 {
			sqlite3_vdbe_resolve_label(v, addr_unique_ok)
			continue
		}
		on_error = int(p_idx.onError)
		if on_error == 0 {
			sqlite3_vdbe_resolve_label(v, addr_unique_ok)
			continue
		}
		if int(override_error) != 11 {
			on_error = int(override_error)
		} else if on_error == 11 {
			on_error = 2
		}
		if p_upsert_clause {
			if int(p_upsert_clause.isDoUpdate) == 0 {
				on_error = 4
			} else {
				on_error = 6
			}
		}
		mut __c2v_condition_72 := false
		mut __c2v_condition_73 := false
		__c2v_condition_73 = (ix == 0 && usize(p_idx.pNext) == usize(0))
		if __c2v_condition_73 {
			__c2v_condition_73 = usize(p_pk) == usize(p_idx)
		}
		if __c2v_condition_73 {
			__c2v_condition_73 = on_error == 5
		}
		if __c2v_condition_73 {
			__c2v_condition_73 = (U64(0) == (db.flags & U64(8192)) || usize(0) == usize(sqlite3_triggers_exist(p_parse, p_tab, 129, unsafe { nil }, unsafe { nil })))
		}
		if __c2v_condition_73 {
			__c2v_condition_73 = (U64(0) == (db.flags & U64(16384)) || (usize(0) == usize(p_tab.u.tab.pFKey) && usize(0) == usize(sqlite3_fk_references(p_tab))))
		}
		__c2v_condition_72 = __c2v_condition_73
		if __c2v_condition_72 {
			sqlite3_vdbe_resolve_label(v, addr_unique_ok)
			continue
		}
		0
		addr_conflict_ck = sqlite3_vdbe_add_op4_int(v, 27, i_this_cur, addr_unique_ok, reg_idx, int(p_idx.nKeyCol))
		0
		reg_r = if usize(p_idx) == usize(p_pk) {
			reg_idx
		} else {
			sqlite3_get_temp_range(p_parse, n_pk_field)
		}
		if int(is_update) || on_error == 5 {
			if ((p_tab.tabFlags & u32(128)) == u32(0)) {
				sqlite3_vdbe_add_op2(v, 144, i_this_cur, reg_r)
				if is_update {
					sqlite3_vdbe_add_op3(v, 54, reg_r, addr_unique_ok, reg_old_data)
					sqlite3_vdbe_change_p5(v, U16(144))
					0
				}
			} else {
				x := 0
				if usize(p_idx) != usize(p_pk) {
					for i = 0; i < int(p_pk.nKeyCol); i++ {
						x = sqlite3_table_column_to_index(p_idx, int(p_pk.aiColumn[i]))
						sqlite3_vdbe_add_op3(v, 96, i_this_cur, x, reg_r + i)
						0
					}
				}
				if is_update {
					addr_jump := sqlite3_vdbe_current_addr(v) + int(p_pk.nKeyCol)
					op := 53
					reg_cmp := (if (int(p_idx.idxType) == 2) { reg_idx } else { reg_r })
					for i = 0; i < int(p_pk.nKeyCol); i++ {
						p4 := &i8(voidptr(sqlite3_locate_coll_seq(p_parse, p_pk.azColl[i])))
						x = int(p_pk.aiColumn[i])
						if i == (int(p_pk.nKeyCol) - 1) {
							addr_jump = addr_unique_ok
							op = 54
						}
						x = int(sqlite3_table_column_to_storage(p_tab, I16(x)))
						sqlite3_vdbe_add_op4(v, op, reg_old_data + 1 + x, addr_jump, reg_cmp + i, p4, (-2))
						sqlite3_vdbe_change_p5(v, U16(144))
						0
						0
					}
				}
			}
		}
		match on_error {
			1, 2, 3 {
				0
				0
				0
				sqlite3_unique_constraint(p_parse, on_error, p_idx)
			}
			6 {
				sqlite3_upsert_do_update(p_parse, p_upsert, p_tab, p_idx, i_idx_cur + ix)

				unsafe { goto c2v_case_49_2
				 }
			}
			4 {
				c2v_case_49_2:
				0
				sqlite3_vdbe_goto(v, ignore_dest)
			}
			else {
				n_conflict_ck := 0
				n_conflict_ck = sqlite3_vdbe_current_addr(v) - addr_conflict_ck
				0
				0
				if reg_trig_cnt {
					sqlite3_multi_write(p_parse)
					n_replace_trig++
				}
				if !isnil(p_trigger) && int(is_update) {
					sqlite3_vdbe_add_op1(v, 169, i_data_cur)
				}
				sqlite3_generate_row_delete(p_parse, p_tab, p_trigger, i_data_cur, i_idx_cur, reg_r, I16(n_pk_field), U8(0), U8(5), U8((if usize(p_idx) == usize(p_pk) {
					1
				} else {
					0
				})), i_this_cur)
				if !isnil(p_trigger) && int(is_update) {
					sqlite3_vdbe_add_op1(v, 170, i_data_cur)
				}
				if reg_trig_cnt {
					addr_bypass := 0
					sqlite3_vdbe_add_op2(v, 88, reg_trig_cnt, 1)
					addr_bypass = sqlite3_vdbe_add_op0(v, 9)
					0
					sqlite3_vdbe_resolve_label(v, lbl_recheck_ok)
					lbl_recheck_ok = sqlite3_vdbe_make_label(p_parse)
					if p_idx.pPartIdxWhere {
						sqlite3_vdbe_add_op2(v, 51, reg_idx - 1, lbl_recheck_ok)
						0
					}
					for n_conflict_ck > 0 {
						x := VdbeOp{}
						x = unsafe { *sqlite3_vdbe_get_op(v, addr_conflict_ck) }
						if int(x.opcode) != 144 {
							p2 := 0
							z_p4 := &i8(0)
							if int(sqlite3_opcode_property[x.opcode]) & 1 {
								p2 = lbl_recheck_ok
							} else {
								p2 = x.p2
							}
							z_p4 = &i8(voidptr(unsafe { if int(x.p4type) == (-3) {
								&u8((voidptr(i64(x.p4.i))))
							} else {
								&u8(x.p4.z)
							} }))
							sqlite3_vdbe_add_op4(v, int(x.opcode), x.p1, p2, x.p3, z_p4, int(x.p4type))
							sqlite3_vdbe_change_p5(v, x.p5)
							0
						}
						n_conflict_ck--
						addr_conflict_ck++
					}
					sqlite3_unique_constraint(p_parse, 2, p_idx)
					sqlite3_vdbe_jump_here(v, addr_bypass)
				}
				seen_replace = 1
			}
		}

		sqlite3_vdbe_resolve_label(v, addr_unique_ok)
		if reg_r != reg_idx {
			sqlite3_release_temp_range(p_parse, reg_r, n_pk_field)
		}
		if !isnil(p_upsert_clause) && upsert_ipk_return && sqlite3_upsert_next_is_ipk(p_upsert_clause) {
			sqlite3_vdbe_goto(v, upsert_ipk_delay + 1)
			sqlite3_vdbe_jump_here(v, upsert_ipk_return)
			upsert_ipk_return = 0
		}
	}
	if ipk_top {
		sqlite3_vdbe_goto(v, ipk_top)
		0
		sqlite3_vdbe_jump_here(v, ipk_bottom)
	}
	0
	if n_replace_trig {
		sqlite3_vdbe_add_op2(v, 17, reg_trig_cnt, lbl_recheck_ok)
		0
		if isnil(p_pk) {
			if is_update {
				sqlite3_vdbe_add_op3(v, 54, reg_new_data, addr_recheck, reg_old_data)
				sqlite3_vdbe_change_p5(v, U16(144))
				0
			}
			sqlite3_vdbe_add_op3(v, 31, i_data_cur, addr_recheck, reg_new_data)
			0
			sqlite3_rowid_constraint(p_parse, 2, p_tab)
		} else {
			sqlite3_vdbe_goto(v, addr_recheck)
		}
		sqlite3_vdbe_resolve_label(v, lbl_recheck_ok)
	}
	if ((p_tab.tabFlags & u32(128)) == u32(0)) {
		reg_rec := a_reg_idx[ix]
		sqlite3_vdbe_add_op3(v, 99, reg_new_data + 1, int(p_tab.nNVCol), reg_rec)
		0
		if !b_affinity_done {
			sqlite3_table_affinity(v, p_tab, 0)
		}
	}
	unsafe { *pb_may_replace = seen_replace }
	0
}

@[c:'sqlite3CompleteInsertion']
fn sqlite3_complete_insertion(p_parse &Parse, p_tab &Table, i_data_cur int, i_idx_cur int, reg_new_data int, a_reg_idx &int, update_flags int, append_bias int, use_seek_result int) {
	v := &Vdbe(0)
	p_idx := &Index(0)
	pik_flags := U8(0)
	i := 0
	v = p_parse.pVdbe
	i = 0
	for p_idx = p_tab.pIndex; p_idx;  {
		if a_reg_idx[i] == 0 {
			unsafe { goto c2v_for_next_123
			 }
		}
		if p_idx.pPartIdxWhere {
			sqlite3_vdbe_add_op2(v, 51, a_reg_idx[i], sqlite3_vdbe_current_addr(v) + 2)
			0
		}
		pik_flags = U8((if use_seek_result { 16 } else { 0 }))
		if (int(p_idx.idxType) == 2) && !((p_tab.tabFlags & u32(128)) == u32(0)) {
			pik_flags |= 1
			pik_flags |= (update_flags & 2)
			if update_flags == 0 {
				0
			}
		}
		sqlite3_vdbe_add_op4_int(v, 140, i_idx_cur + i, a_reg_idx[i], a_reg_idx[i] + 1, if int(p_idx.uniqNotNull) {
			int(p_idx.nKeyCol)
		} else {
			int(p_idx.nColumn)
		})
		sqlite3_vdbe_change_p5(v, U16(pik_flags))
		c2v_for_next_123:
		p_idx = p_idx.pNext
		i++
	}
	if !((p_tab.tabFlags & u32(128)) == u32(0)) {
		return
	}
	if p_parse.nested {
		pik_flags = U8(0)
	} else {
		pik_flags = U8(1)
		pik_flags |= (if update_flags { update_flags } else { 32 })
	}
	if append_bias {
		pik_flags |= 8
	}
	if use_seek_result {
		pik_flags |= 16
	}
	sqlite3_vdbe_add_op3(v, 130, i_data_cur, a_reg_idx[i], reg_new_data)
	if !p_parse.nested {
		sqlite3_vdbe_append_p4(v, voidptr(p_tab), (-5))
	}
	sqlite3_vdbe_change_p5(v, U16(pik_flags))
}

@[c:'sqlite3OpenTableAndIndices']
fn sqlite3_open_table_and_indices(p_parse &Parse, p_tab &Table, op int, p5 U8, i_base int, a_to_open &U8, pi_data_cur &int, pi_idx_cur &int) int {
	i := 0
	i_db := 0
	i_data_cur := 0
	p_idx := &Index(0)
	v := &Vdbe(0)
	if (int(p_tab.eTabType) == 1) {
		unsafe { *pi_idx_cur = -999 }
		unsafe { *pi_data_cur = *pi_idx_cur }
		return 0
	}
	i_db = sqlite3_schema_to_index(p_parse.db, p_tab.pSchema)
	v = p_parse.pVdbe
	if i_base < 0 {
		i_base = p_parse.nTab
	}
	mut __c2v_postfix_value_19 := i_base
	i_base++
	i_data_cur = __c2v_postfix_value_19
	unsafe { *pi_data_cur = i_data_cur }
	if ((p_tab.tabFlags & u32(128)) == u32(0)) && (usize(a_to_open) == usize(0) || int(a_to_open[0])) {
		sqlite3_open_table(p_parse, i_data_cur, i_db, p_tab, op)
	} else if int(p_parse.db.noSharedCache) == 0 {
		sqlite3_table_lock(p_parse, i_db, p_tab.tnum, U8(op == 116), p_tab.zName)
	}
	unsafe { *pi_idx_cur = i_base }
	i = 0
	for p_idx = p_tab.pIndex; p_idx;  {
		i_idx_cur := i_base++
		if (int(p_idx.idxType) == 2) && !((p_tab.tabFlags & u32(128)) == u32(0)) {
			unsafe { *pi_data_cur = i_idx_cur }
			p5 = U8(0)
		}
		if usize(a_to_open) == usize(0) || int(a_to_open[i + 1]) {
			sqlite3_vdbe_add_op3(v, op, i_idx_cur, int(p_idx.tnum), i_db)
			sqlite3_vdbe_set_p4_key_info(p_parse, p_idx)
			sqlite3_vdbe_change_p5(v, U16(p5))
			0
		}
		p_idx = p_idx.pNext
		i++
	}
	if i_base > p_parse.nTab {
		p_parse.nTab = i_base
	}
	return i
}

@[c:'xferCompatibleIndex']
fn xfer_compatible_index(p_dest &Index, p_src &Index) int {
	i := 0
	if int(p_dest.nKeyCol) != int(p_src.nKeyCol) || int(p_dest.nColumn) != int(p_src.nColumn) {
		return 0
	}
	if int(p_dest.onError) != int(p_src.onError) {
		return 0
	}
	for i = 0; i < int(p_src.nKeyCol); i++ {
		if int(p_src.aiColumn[i]) != int(p_dest.aiColumn[i]) {
			return 0
		}
		if int(p_src.aiColumn[i]) == (-2) {
			if sqlite3_expr_compare(unsafe { nil }, c2v_at(&p_src.aColExpr.a[0], isize(i)).pExpr, c2v_at(&p_dest.aColExpr.a[0], isize(i)).pExpr, -1) != 0 {
				return 0
			}
		}
		if int(p_src.aSortOrder[i]) != int(p_dest.aSortOrder[i]) {
			return 0
		}
		if sqlite3_stricmp(p_src.azColl[i], p_dest.azColl[i]) != 0 {
			return 0
		}
	}
	if sqlite3_expr_compare(unsafe { nil }, p_src.pPartIdxWhere, p_dest.pPartIdxWhere, -1) {
		return 0
	}
	return 1
}

@[c:'xferOptimization']
fn xfer_optimization(p_parse &Parse, p_dest &Table, p_select &Select, on_error int, i_db_dest int) int {
	db := p_parse.db
	pel_ist := &ExprList(0)
	p_src := &Table(0)
	p_src_idx := &Index(0)
	p_dest_idx := &Index(0)

	p_item := &SrcItem(0)
	i := 0
	i_db_src := 0
	i_src := 0
	i_dest := 0

	addr1 := 0
	addr2 := 0

	empty_dest_test := 0
	empty_src_test := 0
	v := &Vdbe(0)
	reg_autoinc := 0
	dest_has_unique_idx := 0
	reg_data := 0
	reg_rowid := 0

	if !isnil(p_parse.pWith) || !isnil(p_select.pWith) {
		return 0
	}
	if (int(p_dest.eTabType) == 1) {
		return 0
	}
	if on_error == 11 {
		if int(p_dest.iPKey) >= 0 {
			on_error = int(p_dest.keyConf)
		}
		if on_error == 11 {
			on_error = 2
		}
	}
	if p_select.pSrc.nSrc != 1 {
		return 0
	}
	if c2v_at(&p_select.pSrc.a[0], isize(0)).fg.isSubquery {
		return 0
	}
	if p_select.pWhere {
		return 0
	}
	if p_select.pOrderBy {
		return 0
	}
	if p_select.pGroupBy {
		return 0
	}
	if p_select.pLimit {
		return 0
	}
	if p_select.pPrior {
		return 0
	}
	if p_select.selFlags & u32(1) {
		return 0
	}
	pel_ist = p_select.pEList
	if pel_ist.nExpr != 1 {
		return 0
	}
	if int(c2v_at(&pel_ist.a[0], isize(0)).pExpr.op) != 180 {
		return 0
	}
	p_item = unsafe { &p_select.pSrc.a[0] }
	p_src = sqlite3_locate_table_item(p_parse, u32(0), p_item)
	if usize(p_src) == usize(0) {
		return 0
	}
	if p_src.tnum == p_dest.tnum && usize(p_src.pSchema) == usize(p_dest.pSchema) {
		0
		return 0
	}
	if ((p_dest.tabFlags & u32(128)) == u32(0)) != ((p_src.tabFlags & u32(128)) == u32(0)) {
		return 0
	}
	if !(int(p_src.eTabType) == 0) {
		return 0
	}
	if int(p_dest.nCol) != int(p_src.nCol) {
		return 0
	}
	if int(p_dest.iPKey) != int(p_src.iPKey) {
		return 0
	}
	if (p_dest.tabFlags & u32(65536)) != u32(0) && (p_src.tabFlags & u32(65536)) == u32(0) {
		return 0
	}
	for i = 0; i < int(p_dest.nCol); i++ {
		p_dest_col := unsafe { p_dest.aCol + i }
		p_src_col := unsafe { p_src.aCol + i }
		if (int(p_dest_col.colFlags) & 96) != (int(p_src_col.colFlags) & 96) {
			return 0
		}
		if (int(p_dest_col.colFlags) & 96) != 0 {
			if sqlite3_expr_compare(unsafe { nil }, sqlite3_column_expr(p_src, p_src_col), sqlite3_column_expr(p_dest, p_dest_col), -1) != 0 {
				0
				0
				return 0
			}
		}
		if int(p_dest_col.affinity) != int(p_src_col.affinity) {
			return 0
		}
		if sqlite3_stricmp(sqlite3_column_coll(p_dest_col), sqlite3_column_coll(p_src_col)) != 0 {
			return 0
		}
		if int(p_dest_col.notNull) && !p_src_col.notNull {
			return 0
		}
		if (int(p_dest_col.colFlags) & 96) == 0 && i > 0 {
			p_dest_expr := sqlite3_column_expr(p_dest, p_dest_col)
			p_src_expr := sqlite3_column_expr(p_src, p_src_col)
			if (usize(p_dest_expr) == usize(0)) != (usize(p_src_expr) == usize(0)) || (usize(p_dest_expr) != usize(0) && C.strcmp(p_dest_expr.u.zToken, p_src_expr.u.zToken) != 0) {
				return 0
			}
		}
	}
	for p_dest_idx = p_dest.pIndex; p_dest_idx; p_dest_idx = p_dest_idx.pNext {
		if (int(p_dest_idx.onError) != 0) {
			dest_has_unique_idx = 1
		}
		for p_src_idx = p_src.pIndex; p_src_idx; p_src_idx = p_src_idx.pNext {
			if xfer_compatible_index(p_dest_idx, p_src_idx) {
				break
			}
		}
		if usize(p_src_idx) == usize(0) {
			return 0
		}
		if p_src_idx.tnum == p_dest_idx.tnum && usize(p_src.pSchema) == usize(p_dest.pSchema) && sqlite3_fault_sim(411) == 0 {
			return 0
		}
	}
	if !isnil(p_dest.pCheck) && (db.mDbFlags & u32(4)) == u32(0) && sqlite3_expr_list_compare(p_src.pCheck, p_dest.pCheck, -1) {
		return 0
	}
	if (db.flags & U64(16384)) != U64(0) && usize(p_dest.u.tab.pFKey) != usize(0) {
		return 0
	}
	if (db.flags & (U64(1) << 32)) != U64(0) {
		return 0
	}
	i_db_src = sqlite3_schema_to_index(db, p_src.pSchema)
	v = sqlite3_get_vdbe(p_parse)
	sqlite3_code_verify_schema(p_parse, i_db_src)
	mut __c2v_postfix_value_20 := p_parse.nTab
	p_parse.nTab++
	i_src = __c2v_postfix_value_20
	mut __c2v_postfix_value_21 := p_parse.nTab
	p_parse.nTab++
	i_dest = __c2v_postfix_value_21
	reg_autoinc = auto_inc_begin(p_parse, i_db_dest, p_dest)
	reg_data = sqlite3_get_temp_reg(p_parse)
	sqlite3_vdbe_add_op2(v, 77, 0, reg_data)
	reg_rowid = sqlite3_get_temp_reg(p_parse)
	sqlite3_open_table(p_parse, i_dest, i_db_dest, p_dest, 116)
	if (db.mDbFlags & u32(4)) == u32(0) && ((int(p_dest.iPKey) < 0 && usize(p_dest.pIndex) != usize(0)) || dest_has_unique_idx || (on_error != 2 && on_error != 1)) {
		addr1 = sqlite3_vdbe_add_op2(v, 36, i_dest, 0)
		0
		empty_dest_test = sqlite3_vdbe_add_op0(v, 9)
		sqlite3_vdbe_jump_here(v, addr1)
	}
	if ((p_src.tabFlags & u32(128)) == u32(0)) {
		ins_flags := U8(0)
		sqlite3_open_table(p_parse, i_src, i_db_src, p_src, 114)
		empty_src_test = sqlite3_vdbe_add_op2(v, 36, i_src, 0)
		0
		if int(p_dest.iPKey) >= 0 {
			addr1 = sqlite3_vdbe_add_op2(v, 137, i_src, reg_rowid)
			if (db.mDbFlags & u32(4)) == u32(0) {
				0
				addr2 = sqlite3_vdbe_add_op3(v, 31, i_dest, 0, reg_rowid)
				0
				sqlite3_rowid_constraint(p_parse, on_error, p_dest)
				sqlite3_vdbe_jump_here(v, addr2)
			}
			auto_inc_step(p_parse, reg_autoinc, reg_rowid)
		} else if usize(p_dest.pIndex) == usize(0) && !(db.mDbFlags & u32(8)) {
			addr1 = sqlite3_vdbe_add_op2(v, 129, i_dest, reg_rowid)
		} else {
			addr1 = sqlite3_vdbe_add_op2(v, 137, i_src, reg_rowid)
		}
		if db.mDbFlags & u32(4) {
			sqlite3_vdbe_add_op1(v, 139, i_dest)
			ins_flags = U8(8 | 16 | 128)
		} else {
			ins_flags = U8(1 | 32 | 8 | 128)
		}
		sqlite3_vdbe_add_op3(v, 131, i_dest, i_src, reg_rowid)
		sqlite3_vdbe_add_op3(v, 130, i_dest, reg_data, reg_rowid)
		if (db.mDbFlags & u32(4)) == u32(0) {
			sqlite3_vdbe_change_p4(v, -1, &i8(voidptr(p_dest)), (-5))
		}
		sqlite3_vdbe_change_p5(v, U16(ins_flags))
		sqlite3_vdbe_add_op2(v, 40, i_src, addr1)
		0
		sqlite3_vdbe_add_op2(v, 124, i_src, 0)
		sqlite3_vdbe_add_op2(v, 124, i_dest, 0)
	} else {
		sqlite3_table_lock(p_parse, i_db_dest, p_dest.tnum, U8(1), p_dest.zName)
		sqlite3_table_lock(p_parse, i_db_src, p_src.tnum, U8(0), p_src.zName)
	}
	for p_dest_idx = p_dest.pIndex; p_dest_idx; p_dest_idx = p_dest_idx.pNext {
		idx_ins_flags := U8(0)
		for p_src_idx = p_src.pIndex; p_src_idx; p_src_idx = p_src_idx.pNext {
			if xfer_compatible_index(p_dest_idx, p_src_idx) {
				break
			}
		}
		sqlite3_vdbe_add_op3(v, 114, i_src, int(p_src_idx.tnum), i_db_src)
		sqlite3_vdbe_set_p4_key_info(p_parse, p_src_idx)
		0
		sqlite3_vdbe_add_op3(v, 116, i_dest, int(p_dest_idx.tnum), i_db_dest)
		sqlite3_vdbe_set_p4_key_info(p_parse, p_dest_idx)
		sqlite3_vdbe_change_p5(v, U16(1))
		0
		addr1 = sqlite3_vdbe_add_op2(v, 36, i_src, 0)
		0
		if db.mDbFlags & u32(4) {
			for i = 0; i < int(p_src_idx.nColumn); i++ {
				z_coll := p_src_idx.azColl[i]
				if sqlite3_stricmp(unsafe { &i8(&sqlite3StrBINARY[0]) }, z_coll) {
					break
				}
			}
			if i == int(p_src_idx.nColumn) {
				idx_ins_flags = U8(16 | 128)
				sqlite3_vdbe_add_op1(v, 139, i_dest)
				sqlite3_vdbe_add_op2(v, 131, i_dest, i_src)
			}
		} else if !((p_src.tabFlags & u32(128)) == u32(0)) && int(p_dest_idx.idxType) == 2 {
			idx_ins_flags |= 1
		}
		if int(idx_ins_flags) != (16 | 128) {
			sqlite3_vdbe_add_op3(v, 136, i_src, reg_data, 1)
			if (db.mDbFlags & u32(4)) == u32(0) && !((p_dest.tabFlags & u32(128)) == u32(0)) && (int(p_dest_idx.idxType) == 2) {
				0
			}
		}
		sqlite3_vdbe_add_op2(v, 140, i_dest, reg_data)
		sqlite3_vdbe_change_p5(v, U16(int(idx_ins_flags) | 8))
		sqlite3_vdbe_add_op2(v, 40, i_src, addr1 + 1)
		0
		sqlite3_vdbe_jump_here(v, addr1)
		sqlite3_vdbe_add_op2(v, 124, i_src, 0)
		sqlite3_vdbe_add_op2(v, 124, i_dest, 0)
	}
	if empty_src_test {
		sqlite3_vdbe_jump_here(v, empty_src_test)
	}
	sqlite3_release_temp_reg(p_parse, reg_rowid)
	sqlite3_release_temp_reg(p_parse, reg_data)
	if empty_dest_test {
		sqlite3_autoincrement_end(p_parse)
		sqlite3_vdbe_add_op2(v, 72, 0, 0)
		sqlite3_vdbe_jump_here(v, empty_dest_test)
		sqlite3_vdbe_add_op2(v, 124, i_dest, 0)
		return 0
	} else {
		return 1
	}
}
