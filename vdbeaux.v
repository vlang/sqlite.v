@[translated]
module main

@[c:'sqlite3VdbeCreate']
fn sqlite3_vdbe_create(p_parse &Parse) &Vdbe {
	db := p_parse.db
	p := &Vdbe(0)
	p = sqlite3_db_malloc_raw_nn(db, U64(sizeof(Vdbe)))
	if usize(p) == usize(0) {
		return unsafe { nil }
	}
	C.memset(voidptr(&p.aOp), 0, sizeof(Vdbe) - (u64(usize(__offsetof(Vdbe, aOp)))))
	p.db = db
	if db.pVdbe {
		db.pVdbe.ppVPrev = &p.pVNext
	}
	p.pVNext = db.pVdbe
	p.ppVPrev = &db.pVdbe
	db.pVdbe = p
	p.pParse = p_parse
	p_parse.pVdbe = p
	sqlite3_vdbe_add_op2(p, 8, 0, 1)
	return p
}

@[c:'sqlite3VdbeParser']
fn sqlite3_vdbe_parser(p &Vdbe) &Parse {
	return p.pParse
}

@[c:'sqlite3VdbeError']
@[c2v_variadic]
fn sqlite3_vdbe_error(p &Vdbe, z_format &i8, ...) {
	ap := C.va_list{}
	sqlite3_db_free(p.db, voidptr(p.zErrMsg))
	C.va_start(ap, z_format)
	p.zErrMsg = sqlite3_vm_printf(p.db, z_format, ap)
	C.va_end(ap)
}

@[c:'sqlite3VdbeSetSql']
fn sqlite3_vdbe_set_sql(p &Vdbe, z &i8, n int, prep_flags U8) {
	if usize(p) == usize(0) {
		return
	}
	p.prepFlags = prep_flags
	if (int(prep_flags) & 128) == 0 {
		p.expmask = u32(0)
	}
	p.zSql = sqlite3_db_str_nd_up(p.db, z, U64(n))
}

@[c:'sqlite3VdbeSwap']
fn sqlite3_vdbe_swap(pa &Vdbe, pb &Vdbe) {
	tmp := Vdbe{}
	p_tmp := &Vdbe(0)
	pp_tmp := &&Vdbe(0)

	z_tmp := &i8(0)
	tmp = unsafe { *pa }
	unsafe { *pa = *pb }
	unsafe { *pb = tmp }
	p_tmp = pa.pVNext
	pa.pVNext = pb.pVNext
	pb.pVNext = p_tmp
	pp_tmp = pa.ppVPrev
	pa.ppVPrev = pb.ppVPrev
	pb.ppVPrev = pp_tmp
	z_tmp = pa.zSql
	pa.zSql = pb.zSql
	pb.zSql = z_tmp
	pb.expmask = pa.expmask
	pb.prepFlags = pa.prepFlags
	C.memcpy(pb.aCounter, pa.aCounter, sizeof([9]u32))
	pb.aCounter[5]++
}

@[c:'growOpArray']
fn grow_op_array(v &Vdbe, n_op int) int {
	p_new := &VdbeOp(0)
	p := v.pParse
	n_new := (if v.nOpAlloc {
		Sqlite3_int64(2) * Sqlite3_int64(v.nOpAlloc)
	} else {
		Sqlite3_int64((u64(1024) / sizeof(Op)))
	})

	if n_new > Sqlite3_int64(p.db.aLimit[5]) {
		sqlite3_oom_fault(p.db)
		return 7
	}
	p_new = sqlite3_db_realloc(p.db, voidptr(v.aOp), u64(n_new) * sizeof(Op))
	if p_new {
		p.szOpAlloc = sqlite3_db_malloc_size(p.db, voidptr(p_new))
		v.nOpAlloc = int(u64(p.szOpAlloc) / sizeof(Op))
		v.aOp = p_new
	}
	return if p_new { 0 } else { 7 }
}

@[c:'growOp3']
fn grow_op3(p &Vdbe, op int, p1 int, p2 int, p3 int) int {
	if grow_op_array(p, 1) {
		return 1
	}
	return sqlite3_vdbe_add_op3(p, op, p1, p2, p3)
}

@[c:'addOp4IntSlow']
fn add_op4_int_slow(p &Vdbe, op int, p1 int, p2 int, p3 int, p4 int) int {
	addr := sqlite3_vdbe_add_op3(p, op, p1, p2, p3)
	if int(p.db.mallocFailed) == 0 {
		p_op := unsafe { p.aOp + addr }
		p_op.p4type = i8((-3))
		p_op.p4.i = p4
	}
	return addr
}

@[c:'sqlite3VdbeAddOp0']
fn sqlite3_vdbe_add_op0(p &Vdbe, op int) int {
	return sqlite3_vdbe_add_op3(p, op, 0, 0, 0)
}

@[c:'sqlite3VdbeAddOp1']
fn sqlite3_vdbe_add_op1(p &Vdbe, op int, p1 int) int {
	return sqlite3_vdbe_add_op3(p, op, p1, 0, 0)
}

@[c:'sqlite3VdbeAddOp2']
fn sqlite3_vdbe_add_op2(p &Vdbe, op int, p1 int, p2 int) int {
	return sqlite3_vdbe_add_op3(p, op, p1, p2, 0)
}

@[c:'sqlite3VdbeAddOp3']
fn sqlite3_vdbe_add_op3(p &Vdbe, op int, p1 int, p2 int, p3 int) int {
	i := 0
	p_op := &VdbeOp(0)
	i = p.nOp
	if p.nOpAlloc <= i {
		return grow_op3(p, op, p1, p2, p3)
	}
	p.nOp++
	p_op = unsafe { p.aOp + i }
	p_op.opcode = U8(op)
	p_op.p5 = U16(0)
	p_op.p1 = p1
	p_op.p2 = p2
	p_op.p3 = p3
	p_op.p4.p = 0
	p_op.p4type = i8(0)
	return i
}

@[c:'sqlite3VdbeAddOp4Int']
fn sqlite3_vdbe_add_op4_int(p &Vdbe, op int, p1 int, p2 int, p3 int, p4 int) int {
	i := 0
	p_op := &VdbeOp(0)
	i = p.nOp
	if p.nOpAlloc <= i {
		return add_op4_int_slow(p, op, p1, p2, p3, p4)
	}
	p.nOp++
	p_op = unsafe { p.aOp + i }
	p_op.opcode = U8(op)
	p_op.p5 = U16(0)
	p_op.p1 = p1
	p_op.p2 = p2
	p_op.p3 = p3
	p_op.p4.i = p4
	p_op.p4type = i8((-3))
	return i
}

@[c:'sqlite3VdbeGoto']
fn sqlite3_vdbe_goto(p &Vdbe, i_dest int) int {
	return sqlite3_vdbe_add_op3(p, 9, 0, i_dest, 0)
}

@[c:'sqlite3VdbeLoadString']
fn sqlite3_vdbe_load_string(p &Vdbe, i_dest int, z_str &i8) int {
	return sqlite3_vdbe_add_op4(p, 118, 0, i_dest, 0, z_str, 0)
}

@[c:'sqlite3VdbeMultiLoad']
@[c2v_variadic]
fn sqlite3_vdbe_multi_load(p &Vdbe, i_dest int, z_types &i8, ...) {
	ap := C.va_list{}
	i := 0
	c := i8(0)
	C.va_start(ap, z_types)
	for i = 0; true; i++ {
		c = z_types[i]
		if !(int(c) != 0) {
			break
		}
		if int(c) == i8(`s`) {
			z := C.va_arg(&i8, ap)
			sqlite3_vdbe_add_op4(p, if usize(z) == usize(0) { 77 } else { 118 }, 0, i_dest + i, 0, z, 0)
		} else if int(c) == i8(`i`) {
			sqlite3_vdbe_add_op2(p, 73, C.va_arg(int, ap), i_dest + i)
		} else {
			unsafe { goto skip_op_resultrow
			 }
		}
	}
	sqlite3_vdbe_add_op2(p, 86, i_dest, i)
	skip_op_resultrow:
	C.va_end(ap)
}

@[c:'sqlite3VdbeAddOp4']
fn sqlite3_vdbe_add_op4(p &Vdbe, op int, p1 int, p2 int, p3 int, z_p4 &i8, p4type int) int {
	addr := sqlite3_vdbe_add_op3(p, op, p1, p2, p3)
	sqlite3_vdbe_change_p4(p, addr, z_p4, p4type)
	return addr
}

@[c:'sqlite3VdbeAddFunctionCall']
fn sqlite3_vdbe_add_function_call(p_parse &Parse, p1 int, p2 int, p3 int, n_arg int, p_func &FuncDef, e_call_ctx int) int {
	v := p_parse.pVdbe
	addr := 0
	p_ctx := &Sqlite3_context(0)
	p_ctx = sqlite3_db_malloc_raw_nn(p_parse.db, U64(((u64(usize(__offsetof(Sqlite3_context, argv)))) + u64(n_arg) * sizeof(voidptr))))
	if usize(p_ctx) == usize(0) {
		free_ephemeral_function(p_parse.db, &FuncDef(p_func))
		return 0
	}
	p_ctx.pOut = 0
	p_ctx.pFunc = &FuncDef(p_func)
	p_ctx.pVdbe = 0
	p_ctx.isError = 0
	p_ctx.argc = U16(n_arg)
	p_ctx.iOp = sqlite3_vdbe_current_addr(v)
	addr = sqlite3_vdbe_add_op4(v, if e_call_ctx { 67 } else { 68 }, p1, p2, p3, &i8(voidptr(p_ctx)), (-16))
	sqlite3_vdbe_change_p5(v, U16(e_call_ctx & 46))
	sqlite3_may_abort(p_parse)
	return addr
}

@[c:'sqlite3VdbeAddOp4Dup8']
fn sqlite3_vdbe_add_op4_dup8(p &Vdbe, op int, p1 int, p2 int, p3 int, z_p4 &U8, p4type int) int {
	p4copy := &i8(sqlite3_db_malloc_raw_nn(sqlite3_vdbe_db(p), U64(8)))
	if p4copy {
		C.memcpy(voidptr(p4copy), voidptr(z_p4), u64(8))
	}
	return sqlite3_vdbe_add_op4(p, op, p1, p2, p3, p4copy, p4type)
}

@[c:'sqlite3VdbeExplainParent']
fn sqlite3_vdbe_explain_parent(p_parse &Parse) int {
	p_op := &VdbeOp(0)
	if p_parse.addrExplain == 0 {
		return 0
	}
	p_op = sqlite3_vdbe_get_op(p_parse.pVdbe, p_parse.addrExplain)
	return p_op.p2
}

@[c:'sqlite3VdbeExplain']
@[c2v_variadic]
fn sqlite3_vdbe_explain(p_parse &Parse, b_push U8, z_fmt &i8, ...) int {
	addr := 0
	if int(p_parse.explain) == 2 || 0 {
		z_msg := &i8(0)
		v := &Vdbe(0)
		ap := C.va_list{}
		i_this := 0
		C.va_start(ap, z_fmt)
		z_msg = sqlite3_vm_printf(p_parse.db, z_fmt, ap)
		C.va_end(ap)
		v = p_parse.pVdbe
		i_this = v.nOp
		addr = sqlite3_vdbe_add_op4(v, 190, i_this, p_parse.addrExplain, 0, z_msg, (-7))
		0
		if b_push {
			p_parse.addrExplain = i_this
		}
		0
	}
	return addr
}

@[c:'sqlite3VdbeExplainPop']
fn sqlite3_vdbe_explain_pop(p_parse &Parse) {
	0
	p_parse.addrExplain = sqlite3_vdbe_explain_parent(p_parse)
}

@[c:'sqlite3VdbeAddParseSchemaOp']
fn sqlite3_vdbe_add_parse_schema_op(p &Vdbe, i_db int, z_where &i8, p5 U16) {
	j := 0
	sqlite3_vdbe_add_op4(p, 151, i_db, 0, 0, z_where, (-7))
	sqlite3_vdbe_change_p5(p, p5)
	for j = 0; j < p.db.nDb; j++ {
		sqlite3_vdbe_uses_btree(p, j)
	}
	sqlite3_may_abort(p.pParse)
}

@[c:'sqlite3VdbeEndCoroutine']
fn sqlite3_vdbe_end_coroutine(v &Vdbe, reg_yield int) {
	sqlite3_vdbe_add_op1(v, 70, reg_yield)
	v.pParse.nTempReg = U8(0)
	v.pParse.nRangeReg = 0
}

@[c:'sqlite3VdbeMakeLabel']
fn sqlite3_vdbe_make_label(p_parse &Parse) int {
	return c2v_prefix_add(unsafe { &p_parse.nLabel }, -1)
}

@[c:'resizeResolveLabel']
fn resize_resolve_label(p &Parse, v &Vdbe, j int) {
	n_new_size := 10 - p.nLabel
	p.aLabel = sqlite3_db_realloc_or_free(p.db, voidptr(p.aLabel), U64(u64(n_new_size) * sizeof(int)))
	if usize(p.aLabel) == usize(0) {
		p.nLabelAlloc = 0
	} else {
		if n_new_size >= 100 && (n_new_size / 100) > (p.nLabelAlloc / 100) {
			sqlite3_progress_check(p)
		}
		p.nLabelAlloc = n_new_size
		p.aLabel[j] = v.nOp
	}
}

@[c:'sqlite3VdbeResolveLabel']
fn sqlite3_vdbe_resolve_label(v &Vdbe, x int) {
	p := v.pParse
	j := (~x)
	if p.nLabelAlloc + p.nLabel < 0 {
		resize_resolve_label(p, v, j)
	} else {
		p.aLabel[j] = v.nOp
	}
}

@[c:'sqlite3VdbeRunOnlyOnce']
fn sqlite3_vdbe_run_only_once(p &Vdbe) {
	sqlite3_vdbe_add_op2(p, 168, 1, 1)
}

@[c:'sqlite3VdbeReusable']
fn sqlite3_vdbe_reusable(p &Vdbe) {
	i := 0
	for i = 1; (i < p.nOp); i++ {
		if (int(p.aOp[i].opcode) == 168) {
			p.aOp[1].opcode = U8(189)
			break
		}
	}
}

@[c:'resolveP2Values']
fn resolve_p2_values(p &Vdbe, p_max_vtab_args &int) {
	n_max_vtab_args := (unsafe { *p_max_vtab_args })
	p_op := &Op(0)
	p_parse := p.pParse
	a_label := p_parse.aLabel
	p.readOnly = Bft(1)
	p.bIsReader = Bft(0)
	p_op = unsafe { p.aOp + (p.nOp - 1) }
	for {
		if int(p_op.opcode) <= 66 {
			match p_op.opcode {
				2 {
					if p_op.p2 != 0 {
						p.readOnly = Bft(0)
					}

					unsafe { goto c2v_case_15_1
					 }
				}
				1, 0 {
					c2v_case_15_1:
					p.bIsReader = Bft(1)
				}
				3, 5, 4 {
					p.readOnly = Bft(0)
					p.bIsReader = Bft(1)
				}
				8 {
					unsafe { goto resolve_p2_values_loop_exit
					 }
				}
				7 {
					if p_op.p2 > n_max_vtab_args {
						n_max_vtab_args = p_op.p2
					}
				}
				6 {
					n := 0
					n = p_op[-1].p1
					if n > n_max_vtab_args {
						n_max_vtab_args = n
					}

					unsafe { goto c2v_case_15_6
					 }
				}
				else {
					c2v_case_15_6:
					if p_op.p2 < 0 {
						p_op.p2 = a_label[(~p_op.p2)]
					}
				}
			}
		}
		c2v_pointer_postfix(voidptr(&p_op), p_op, isize(-1))
	}
	resolve_p2_values_loop_exit:
	if a_label {
		sqlite3_db_nn_free_nn(p.db, voidptr(p_parse.aLabel))
		p_parse.aLabel = 0
	}
	p_parse.nLabel = 0
	unsafe { *p_max_vtab_args = n_max_vtab_args }
}

@[c:'sqlite3VdbeCurrentAddr']
fn sqlite3_vdbe_current_addr(p &Vdbe) int {
	return p.nOp
}

@[c:'sqlite3VdbeTakeOpArray']
fn sqlite3_vdbe_take_op_array(p &Vdbe, pn_op &int, pn_max_arg &int) &VdbeOp {
	a_op := p.aOp
	resolve_p2_values(p, pn_max_arg)
	unsafe { *pn_op = p.nOp }
	p.aOp = 0
	return a_op
}

@[c:'sqlite3VdbeAddOpList']
fn sqlite3_vdbe_add_op_list(p &Vdbe, n_op int, a_op &VdbeOpList, i_lineno int) &VdbeOp {
	i := 0
	p_out := &VdbeOp(0)
	p_first := &VdbeOp(0)

	if p.nOp + n_op > p.nOpAlloc && grow_op_array(p, n_op) {
		return unsafe { nil }
	}
	p_out = unsafe { p.aOp + p.nOp }
	p_first = p_out
	for i = 0; i < n_op; i++ {
		p_out.opcode = a_op.opcode
		p_out.p1 = int(a_op.p1)
		p_out.p2 = int(a_op.p2)
		if (int(sqlite3_opcode_property[a_op.opcode]) & 1) != 0 && int(a_op.p2) > 0 {
			p_out.p2 += p.nOp
		}
		p_out.p3 = int(a_op.p3)
		p_out.p4type = i8(0)
		p_out.p4.p = 0
		p_out.p5 = U16(0)

		c2v_pointer_postfix(voidptr(&a_op), a_op, isize(1))
		c2v_pointer_postfix(voidptr(&p_out), p_out, isize(1))
	}
	p.nOp += n_op
	return p_first
}

@[c:'sqlite3VdbeChangeOpcode']
fn sqlite3_vdbe_change_opcode(p &Vdbe, addr int, i_new_opcode U8) {
	mut __c2v_lhs_tmp_79 := sqlite3_vdbe_get_op(p, addr)
	__c2v_lhs_tmp_79.opcode = i_new_opcode
}

@[c:'sqlite3VdbeChangeP1']
fn sqlite3_vdbe_change_p1(p &Vdbe, addr int, val int) {
	mut __c2v_lhs_tmp_80 := sqlite3_vdbe_get_op(p, addr)
	__c2v_lhs_tmp_80.p1 = val
}

@[c:'sqlite3VdbeChangeP2']
fn sqlite3_vdbe_change_p2(p &Vdbe, addr int, val int) {
	mut __c2v_lhs_tmp_81 := sqlite3_vdbe_get_op(p, addr)
	__c2v_lhs_tmp_81.p2 = val
}

@[c:'sqlite3VdbeChangeP3']
fn sqlite3_vdbe_change_p3(p &Vdbe, addr int, val int) {
	mut __c2v_lhs_tmp_82 := sqlite3_vdbe_get_op(p, addr)
	__c2v_lhs_tmp_82.p3 = val
}

@[c:'sqlite3VdbeChangeP5']
fn sqlite3_vdbe_change_p5(p &Vdbe, p5 U16) {
	if p.nOp > 0 {
		p.aOp[p.nOp - 1].p5 = p5
	}
}

@[c:'sqlite3VdbeTypeofColumn']
fn sqlite3_vdbe_typeof_column(p &Vdbe, i_dest int) {
	p_op := sqlite3_vdbe_get_last_op(p)
	if p_op.p3 == i_dest && int(p_op.opcode) == 96 {
		p_op.p5 |= 128
	}
}

@[c:'sqlite3VdbeJumpHere']
fn sqlite3_vdbe_jump_here(p &Vdbe, addr int) {
	sqlite3_vdbe_change_p2(p, addr, p.nOp)
}

@[c:'sqlite3VdbeJumpHereOrPopInst']
fn sqlite3_vdbe_jump_here_or_pop_inst(p &Vdbe, addr int) {
	if addr == p.nOp - 1 {
		p.nOp--
	} else {
		sqlite3_vdbe_change_p2(p, addr, p.nOp)
	}
}

@[c:'freeEphemeralFunction']
fn free_ephemeral_function(db &Sqlite3, p_def &FuncDef) {
	if (p_def.funcFlags & u32(16)) != u32(0) {
		sqlite3_db_nn_free_nn(db, voidptr(p_def))
	}
}

@[c:'freeP4Mem']
fn free_p4_mem(db &Sqlite3, p &Mem) {
	if p.szMalloc {
		sqlite3_db_free(db, voidptr(p.zMalloc))
	}
	sqlite3_db_nn_free_nn(db, voidptr(p))
}

@[c:'freeP4FuncCtx']
fn free_p4_func_ctx(db &Sqlite3, p &Sqlite3_context) {
	free_ephemeral_function(db, p.pFunc)
	sqlite3_db_nn_free_nn(db, voidptr(p))
}

@[c:'freeP4']
fn free_p4(db &Sqlite3, p4type int, p4 voidptr) {
	match p4type {
		(-16) {
			free_p4_func_ctx(db, &Sqlite3_context(p4))
		}
		(-13), (-14), (-7), (-15) {
			if p4 {
				sqlite3_db_nn_free_nn(db, voidptr(p4))
			}
		}
		(-9) {
			if usize(db.pnBytesFreed) == usize(0) {
				sqlite3_key_info_unref(&KeyInfo(p4))
			}
		}
		(-8) {
			free_ephemeral_function(db, &FuncDef(p4))
		}
		(-11) {
			if usize(db.pnBytesFreed) == usize(0) {
				sqlite3_value_free_vdup7(&Sqlite3_value(p4))
			} else {
				free_p4_mem(db, &Mem(p4))
			}
		}
		(-12) {
			if usize(db.pnBytesFreed) == usize(0) {
				sqlite3_vtab_unlock(&VTable(p4))
			}
		}
		(-17) {
			if usize(db.pnBytesFreed) == usize(0) {
				sqlite3_delete_table(db, &Table(p4))
			}
		}
		(-18) {
			p_sig := &SubrtnSig(p4)
			sqlite3_db_free(db, voidptr(p_sig.zAff))
			sqlite3_db_free(db, voidptr(p_sig))
		}
		else {}
	}
}

@[c:'vdbeFreeOpArray']
fn vdbe_free_op_array(db &Sqlite3, a_op &Op, n_op int) {
	if a_op {
		p_op := unsafe { a_op + (n_op - 1) }
		for {
			if int(p_op.p4type) <= (-7) {
				free_p4(db, int(p_op.p4type), voidptr(p_op.p4.p))
			}
			if usize(p_op) == usize(a_op) {
				break
			}
			c2v_pointer_postfix(voidptr(&p_op), p_op, isize(-1))
		}
		sqlite3_db_nn_free_nn(db, voidptr(a_op))
	}
}

@[c:'sqlite3VdbeLinkSubProgram']
fn sqlite3_vdbe_link_sub_program(p_vdbe &Vdbe, p &SubProgram) {
	p.pNext = p_vdbe.pProgram
	p_vdbe.pProgram = p
}

@[c:'sqlite3VdbeHasSubProgram']
fn sqlite3_vdbe_has_sub_program(p_vdbe &Vdbe) int {
	return int(usize(p_vdbe.pProgram) != usize(0))
}

@[c:'sqlite3VdbeChangeToNoop']
fn sqlite3_vdbe_change_to_noop(p &Vdbe, addr int) int {
	p_op := &VdbeOp(0)
	if p.db.mallocFailed {
		return 0
	}
	p_op = unsafe { p.aOp + addr }
	free_p4(p.db, int(p_op.p4type), voidptr(p_op.p4.p))
	p_op.p4type = i8(0)
	p_op.p4.z = 0
	p_op.opcode = U8(189)
	return 1
}

@[c:'sqlite3VdbeDeletePriorOpcode']
fn sqlite3_vdbe_delete_prior_opcode(p &Vdbe, op U8) int {
	if p.nOp > 0 && int(p.aOp[p.nOp - 1].opcode) == int(op) {
		return sqlite3_vdbe_change_to_noop(p, p.nOp - 1)
	} else {
		return 0
	}
}

@[c:'vdbeChangeP4Full']
fn vdbe_change_p4_full(p &Vdbe, p_op &Op, z_p4 &i8, n int) {
	if p_op.p4type {
		p_op.p4type = i8(0)
		p_op.p4.p = 0
	}
	if n < 0 {
		sqlite3_vdbe_change_p4(p, int((i64((isize(p_op) - isize(p.aOp)) / isize(sizeof(Op))))), z_p4, n)
	} else {
		if n == 0 {
			n = sqlite3_strlen30(z_p4)
		}
		p_op.p4.z = sqlite3_db_str_nd_up(p.db, z_p4, U64(n))
		p_op.p4type = i8((-7))
	}
}

@[c:'sqlite3VdbeChangeP4']
fn sqlite3_vdbe_change_p4(p &Vdbe, addr int, z_p4_param &i8, n int) {
	mut z_p4 := z_p4_param
	p_op := &Op(0)
	db := &Sqlite3(0)
	db = p.db
	if db.mallocFailed {
		if n != (-12) {
			free_p4(db, n, voidptr((unsafe { *&&u8(c2v_address_of(&z_p4)) })))
		}
		return
	}
	if addr < 0 {
		addr = p.nOp - 1
	}
	p_op = unsafe { p.aOp + addr }
	if n >= 0 || int(p_op.p4type) {
		vdbe_change_p4_full(p, p_op, z_p4, n)
		return
	}
	if n == (-3) {
		p_op.p4.i = (int(i64(voidptr(z_p4))))
		p_op.p4type = i8((-3))
	} else if usize(z_p4) != usize(0) {
		p_op.p4.p = voidptr(z_p4)
		p_op.p4type = i8(n)
		if n == (-12) {
			sqlite3_vtab_lock(&VTable(voidptr(z_p4)))
		}
	}
}

@[c:'sqlite3VdbeAppendP4']
fn sqlite3_vdbe_append_p4(p &Vdbe, p_p4 voidptr, n int) {
	p_op := &VdbeOp(0)
	if p.db.mallocFailed {
		free_p4(p.db, n, voidptr(p_p4))
	} else {
		p_op = unsafe { p.aOp + (p.nOp - 1) }
		p_op.p4type = i8(n)
		p_op.p4.p = p_p4
	}
}

@[c:'sqlite3VdbeSetP4KeyInfo']
fn sqlite3_vdbe_set_p4_key_info(p_parse &Parse, p_idx &Index) {
	v := p_parse.pVdbe
	p_key_info := &KeyInfo(0)
	p_key_info = sqlite3_key_info_of_index(p_parse, p_idx)
	if p_key_info {
		sqlite3_vdbe_append_p4(v, voidptr(p_key_info), (-9))
	}
}

@[c:'sqlite3VdbeGetOp']
fn sqlite3_vdbe_get_op(p &Vdbe, addr int) &VdbeOp {
	if p.db.mallocFailed {
		return &VdbeOp(c2v_address_of(&sqlite3_vdbe_get_op_dummy))
	} else {
		return unsafe { p.aOp + addr }
	}
}

@[c:'sqlite3VdbeGetLastOp']
fn sqlite3_vdbe_get_last_op(p &Vdbe) &VdbeOp {
	return sqlite3_vdbe_get_op(p, p.nOp - 1)
}

@[c:'sqlite3VdbeDisplayP4']
fn sqlite3_vdbe_display_p4(db &Sqlite3, p_op &Op) &i8 {
	z_p4 := unsafe { &i8(nil) }
	x := StrAccum{}
	sqlite3_str_accum_init(&x, unsafe { nil }, unsafe { nil }, 0, 1000000000)
	match int(p_op.p4type) {
		(-9) {
			j := 0
			p_key_info := p_op.p4.pKeyInfo
			sqlite3_str_appendf(unsafe { &Sqlite3_str(&x) }, c'k(%d', int(p_key_info.nKeyField))
			for j = 0; j < int(p_key_info.nKeyField); j++ {
				p_coll := (&p_key_info.aColl[0])[j]
				z_coll := if p_coll { p_coll.zName } else { c'' }
				if C.strcmp(z_coll, c'BINARY') == 0 {
					z_coll = c'B'
				}
				sqlite3_str_appendf(unsafe { &Sqlite3_str(&x) }, c',%s%s%s', voidptr(if (int(p_key_info.aSortFlags[j]) & 1) {
					c'-'
				} else {
					c''
				}), voidptr(if (int(p_key_info.aSortFlags[j]) & 2) { c'N.' } else { c'' }), voidptr(z_coll))
			}
			sqlite3_str_append(unsafe { &Sqlite3_str(&x) }, c')', 1)
		}
		(-2) {
			if !sqlite3_vdbe_display_p4_encnames_inited {
				c2v_static_init := [c'?', c'8', c'16LE', c'16BE']!
				for c2v_i_0, c2v_element_0 in c2v_static_init {
					sqlite3_vdbe_display_p4_encnames[c2v_i_0] = c2v_element_0
				}
				sqlite3_vdbe_display_p4_encnames_inited = true
			}

			p_coll := p_op.p4.pColl
			sqlite3_str_appendf(unsafe { &Sqlite3_str(&x) }, c'%.18s-%s', voidptr(p_coll.zName), voidptr(sqlite3_vdbe_display_p4_encnames[p_coll.enc]))
		}
		(-8) {
			p_def := p_op.p4.pFunc
			sqlite3_str_appendf(unsafe { &Sqlite3_str(&x) }, c'%s(%d)', voidptr(p_def.zName), int(p_def.nArg))
		}
		(-16) {
			p_def := p_op.p4.pCtx.pFunc
			sqlite3_str_appendf(unsafe { &Sqlite3_str(&x) }, c'%s(%d)', voidptr(p_def.zName), int(p_def.nArg))
		}
		(-14) {
			sqlite3_str_appendf(unsafe { &Sqlite3_str(&x) }, c'%lld', (unsafe { *p_op.p4.pI64 }))
		}
		(-3) {
			sqlite3_str_appendf(unsafe { &Sqlite3_str(&x) }, c'%d', p_op.p4.i)
		}
		(-13) {
			sqlite3_str_appendf(unsafe { &Sqlite3_str(&x) }, c'%.16g', (unsafe { *p_op.p4.pReal }))
		}
		(-11) {
			p_mem := p_op.p4.pMem
			if int(p_mem.flags) & 2 {
				z_p4 = p_mem.z
			} else if int(p_mem.flags) & (4 | 32) {
				sqlite3_str_appendf(unsafe { &Sqlite3_str(&x) }, c'%lld', p_mem.u.i)
			} else if int(p_mem.flags) & 8 {
				sqlite3_str_appendf(unsafe { &Sqlite3_str(&x) }, c'%.16g', p_mem.u.r)
			} else if int(p_mem.flags) & 1 {
				z_p4 = c'NULL'
			} else {
				z_p4 = c'(blob)'
			}
		}
		(-12) {
			p_vtab := p_op.p4.pVtab.pVtab
			sqlite3_str_appendf(unsafe { &Sqlite3_str(&x) }, c'vtab:%p', voidptr(p_vtab))
		}
		(-15) {
			i := u32(0)
			ai := p_op.p4.ai
			n := ai[0]
			for i = u32(1); i <= n; i++ {
				sqlite3_str_appendf(unsafe { &Sqlite3_str(&x) }, c'%c%u', (if i == u32(1) {
					`[`
				} else {
					`,`
				}), ai[i])
			}
			sqlite3_str_append(unsafe { &Sqlite3_str(&x) }, c']', 1)
		}
		(-4) {
			z_p4 = c'program'
		}
		(-5) {
			z_p4 = p_op.p4.pTab.zName
		}
		(-6) {
			z_p4 = p_op.p4.pIdx.zName
		}
		(-18) {
			p_sig := p_op.p4.pSubrtnSig
			sqlite3_str_appendf(unsafe { &Sqlite3_str(&x) }, c'subrtnsig:%d,%s', p_sig.selId, voidptr(p_sig.zAff))
		}
		else {
			z_p4 = p_op.p4.z
		}
	}

	if z_p4 {
		sqlite3_str_appendall(unsafe { &Sqlite3_str(&x) }, z_p4)
	}
	if (int(x.accError) & 7) != 0 {
		sqlite3_oom_fault(db)
	}
	return sqlite3_str_accum_finish(&x)
}

@[c:'sqlite3VdbeUsesBtree']
fn sqlite3_vdbe_uses_btree(p &Vdbe, i int) {
	p.btreeMask |= ((YDbMask(1)) << i)
	if i != 1 && sqlite3_btree_sharable(p.db.aDb[i].pBt) {
		p.lockMask |= ((YDbMask(1)) << i)
	}
}

@[c:'sqlite3VdbeEnter']
fn sqlite3_vdbe_enter(p &Vdbe) {
	i := 0
	db := &Sqlite3(0)
	a_db := &Db(0)
	n_db := 0
	if (p.lockMask == YDbMask(0)) {
		return
	}
	db = p.db
	a_db = db.aDb
	n_db = db.nDb
	for i = 0; i < n_db; i++ {
		if i != 1 && ((p.lockMask & ((YDbMask(1)) << i)) != YDbMask(0)) && (usize(a_db[i].pBt) != usize(0)) {
			sqlite3_btree_enter(a_db[i].pBt)
		}
	}
}

@[c:'vdbeLeave']
fn vdbe_leave(p &Vdbe) {
	i := 0
	db := &Sqlite3(0)
	a_db := &Db(0)
	n_db := 0
	db = p.db
	a_db = db.aDb
	n_db = db.nDb
	for i = 0; i < n_db; i++ {
		if i != 1 && ((p.lockMask & ((YDbMask(1)) << i)) != YDbMask(0)) && (usize(a_db[i].pBt) != usize(0)) {
			sqlite3_btree_leave(a_db[i].pBt)
		}
	}
}

@[c:'sqlite3VdbeLeave']
fn sqlite3_vdbe_leave(p &Vdbe) {
	if (p.lockMask == YDbMask(0)) {
		return
	}
	vdbe_leave(p)
}

@[c:'initMemArray']
fn init_mem_array(p &Mem, n int, db &Sqlite3, flags U16) {
	if n > 0 {
		for {
			p.flags = flags
			p.db = db
			p.szMalloc = 0
			c2v_pointer_postfix(voidptr(&p), p, isize(1))
			n--
			if !(n > 0) {
				break
			}
		}
	}
}

@[c:'releaseMemArray']
fn release_mem_array(p &Mem, n int) {
	if !isnil(p) && n {
		p_end := unsafe { p + n }
		db := p.db
		if db.pnBytesFreed {
			for {
				if p.szMalloc {
					sqlite3_db_free(db, voidptr(p.zMalloc))
				}
				if !(usize((c2v_pointer_prefix(voidptr(&p), p, isize(1)))) < usize(p_end)) {
					break
				}
			}
			return
		}
		for {
			0
			0
			if int(p.flags) & (32768 | 4096) {
				0
				sqlite3_vdbe_mem_release(p)
				p.flags = U16(0)
			} else if p.szMalloc {
				sqlite3_db_nn_free_nn(db, voidptr(p.zMalloc))
				p.szMalloc = 0
				p.flags = U16(0)
			}
			if !(usize((c2v_pointer_prefix(voidptr(&p), p, isize(1)))) < usize(p_end)) {
				break
			}
		}
	}
}

@[c:'sqlite3VdbeFrameMemDel']
fn sqlite3_vdbe_frame_mem_del(p_arg voidptr) {
	c2v_gc_register_thread()
	p_frame := &VdbeFrame(p_arg)
	p_frame.pParent = p_frame.v.pDelFrame
	p_frame.v.pDelFrame = p_frame
}

@[c:'sqlite3VdbeNextOpcode']
fn sqlite3_vdbe_next_opcode(p &Vdbe, p_sub &Mem, e_mode int, pi_pc &int, pi_addr &int, pa_op &&Op) int {
	n_row := 0
	n_sub := 0
	ap_sub := unsafe { &&SubProgram(nil) }
	i := 0
	rc := 0
	a_op := unsafe { &Op(nil) }
	i_pc := 0
	n_row = p.nOp
	if usize(p_sub) != usize(0) {
		if int(p_sub.flags) & 16 {
			n_sub = int(u64(p_sub.n) / sizeof(voidptr))
			ap_sub = &&SubProgram(voidptr(p_sub.z))
		}
		for i = 0; i < n_sub; i++ {
			n_row += ap_sub[i].nOp
		}
	}
	i_pc = unsafe { *pi_pc }
	for {
		mut __c2v_postfix_value_2 := i_pc
		i_pc++
		i = __c2v_postfix_value_2
		if i >= n_row {
			p.rc = 0
			rc = 101
			break
		}
		if i < p.nOp {
			a_op = p.aOp
		} else {
			j := 0
			i -= p.nOp
			for j = 0; i >= ap_sub[j].nOp; j++ {
				i -= ap_sub[j].nOp
			}
			a_op = ap_sub[j].aOp
		}
		if usize(p_sub) != usize(0) && int(a_op[i].p4type) == (-4) {
			n_byte := int(u64((n_sub + 1)) * sizeof(voidptr))
			j := 0
			for j = 0; j < n_sub; j++ {
				if usize(ap_sub[j]) == usize(a_op[i].p4.pProgram) {
					break
				}
			}
			if j == n_sub {
				p.rc = sqlite3_vdbe_mem_grow(p_sub, n_byte, n_sub != 0)
				if p.rc != 0 {
					rc = 1
					break
				}
				ap_sub = &&SubProgram(voidptr(p_sub.z))
				ap_sub[n_sub++] = a_op[i].p4.pProgram
				p_sub.flags = U16((int(p_sub.flags) & ~(3519 | 1024)) | 16)
				p_sub.n = int(u64(n_sub) * sizeof(voidptr))
				n_row += a_op[i].p4.pProgram.nOp
			}
		}
		if e_mode == 0 {
			break
		}
		if int(a_op[i].opcode) == 190 {
			break
		}
		if int(a_op[i].opcode) == 8 && i_pc > 1 {
			break
		}
	}
	unsafe { *pi_pc = i_pc }
	unsafe { *pi_addr = i }
	unsafe { *pa_op = a_op }
	return rc
}

@[c:'sqlite3VdbeFrameDelete']
fn sqlite3_vdbe_frame_delete(p &VdbeFrame) {
	i := 0
	a_mem := (&Mem(voidptr(unsafe { (&U8(voidptr(p))) + (((sizeof(VdbeFrame)) + u64(7)) & u64(~7)) })))
	ap_csr := &&VdbeCursor(voidptr(unsafe { a_mem + p.nChildMem }))
	for i = 0; i < p.nChildCsr; i++ {
		if ap_csr[i] {
			sqlite3_vdbe_free_cursor_nn(p.v, ap_csr[i])
		}
	}
	release_mem_array(a_mem, p.nChildMem)
	sqlite3_vdbe_delete_aux_data(p.v.db, &&AuxData(&p.pAuxData), -1, 0)
	sqlite3_db_free(p.v.db, voidptr(p))
}

@[c:'sqlite3VdbeList']
fn sqlite3_vdbe_list(p &Vdbe) int {
	p_sub := unsafe { &Mem(nil) }
	db := p.db
	i := 0
	rc := 0
	p_mem := unsafe { p.aMem + 1 }
	b_list_subprogs := int((int(p.explain) == 1 || (db.flags & U64(16777216)) != U64(0)))
	a_op := &Op(0)
	p_op := &Op(0)
	release_mem_array(p_mem, 8)
	if p.rc == 7 {
		sqlite3_oom_fault(db)
		return 1
	}
	if b_list_subprogs {
		p_sub = unsafe { p.aMem + 9 }
	} else {
		p_sub = 0
	}
	rc = sqlite3_vdbe_next_opcode(p, p_sub, int(p.explain) == 2, &p.pc, &i, &&Op(&&Op(c2v_address_of(&a_op))))
	if rc == 0 {
		p_op = a_op + i
		if C.c2v_atomic_load_n__int_int_int((&db.u1.isInterrupted), 0) {
			p.rc = 9
			rc = 1
			sqlite3_vdbe_error(p, sqlite3_err_str(p.rc))
		} else {
			z_p4 := sqlite3_vdbe_display_p4(db, p_op)
			if int(p.explain) == 2 {
				sqlite3_vdbe_mem_set_int64(p_mem, I64(p_op.p1))
				sqlite3_vdbe_mem_set_int64(p_mem + 1, I64(p_op.p2))
				sqlite3_vdbe_mem_set_int64(p_mem + 2, I64(p_op.p3))
				sqlite3_vdbe_mem_set_str(p_mem + 3, z_p4, I64(-1), U8(1), sqlite3_free)
			} else {
				sqlite3_vdbe_mem_set_int64(p_mem + 0, I64(i))
				sqlite3_vdbe_mem_set_str(p_mem + 1, &i8(sqlite3_opcode_name(int(p_op.opcode))), I64(-1), U8(1), (C2vFn_666e2028766f696470747229(voidptr(0))))
				sqlite3_vdbe_mem_set_int64(p_mem + 2, I64(p_op.p1))
				sqlite3_vdbe_mem_set_int64(p_mem + 3, I64(p_op.p2))
				sqlite3_vdbe_mem_set_int64(p_mem + 4, I64(p_op.p3))
				sqlite3_vdbe_mem_set_int64(p_mem + 6, I64(p_op.p5))
				sqlite3_vdbe_mem_set_null(p_mem + 7)
				sqlite3_vdbe_mem_set_str(p_mem + 5, z_p4, I64(-1), U8(1), sqlite3_free)
			}
			p.pResultRow = p_mem
			if db.mallocFailed {
				p.rc = 7
				rc = 1
			} else {
				p.rc = 0
				rc = 100
			}
		}
	}
	return rc
}

struct ReusableSpace {
	pSpace  &U8
	nFree   Sqlite3_int64
	nNeeded Sqlite3_int64
}

@[c:'allocSpace']
fn alloc_space(p &ReusableSpace, p_buf voidptr, n_byte Sqlite3_int64) voidptr {
	if usize(p_buf) == usize(0) {
		n_byte = n_byte
		if n_byte <= p.nFree {
			p.nFree -= n_byte
			p_buf = unsafe { p.pSpace + p.nFree }
		} else {
			p.nNeeded += n_byte
		}
	}
	return p_buf
}

@[c:'sqlite3VdbeRewind']
fn sqlite3_vdbe_rewind(p &Vdbe) {
	p.eVdbeState = U8(1)
	p.pc = -1
	p.rc = 0
	p.errorAction = U8(2)
	p.nChange = I64(0)
	p.cacheCtr = u32(1)
	p.minWriteFileFormat = U8(255)
	p.iStatement = 0
	p.nFkConstraint = I64(0)
}

@[c:'sqlite3VdbeMakeReady']
fn sqlite3_vdbe_make_ready(p &Vdbe, p_parse &Parse) {
	db := &Sqlite3(0)
	n_var := 0
	n_mem := 0
	n_cursor := 0
	n_arg := 0
	n := 0
	x := ReusableSpace{}
	p.pVList = p_parse.pVList
	p_parse.pVList = 0
	db = p.db
	n_var = int(p_parse.nVar)
	n_mem = p_parse.nMem
	n_cursor = p_parse.nTab
	n_arg = p_parse.nMaxArg
	n_mem += n_cursor
	if n_cursor == 0 && n_mem > 0 {
		n_mem++
	}
	n = int((sizeof(Op) * u64(p.nOp)))
	x.pSpace = unsafe { (&U8(voidptr(p.aOp))) + n }
	x.nFree = Sqlite3_int64(((p_parse.szOpAlloc - n) & ~7))
	resolve_p2_values(p, &n_arg)
	p.usesStmtJournal = Bft(U8((int(p_parse.isMultiWrite) && int(p_parse.mayAbort))))
	if p_parse.explain {
		if n_mem < 10 {
			n_mem = 10
		}
		p.explain = Bft(p_parse.explain)
		p.nResColumn = U16(12 - 4 * int(p.explain))
	}
	p.expired = Bft(0)
	x.nNeeded = Sqlite3_int64(0)
	p.aMem = alloc_space(&x, unsafe { nil }, Sqlite3_int64(u64(n_mem) * sizeof(Mem)))
	p.aVar = alloc_space(&x, unsafe { nil }, Sqlite3_int64(u64(n_var) * sizeof(Mem)))
	p.apArg = alloc_space(&x, unsafe { nil }, Sqlite3_int64(u64(n_arg) * sizeof(voidptr)))
	p.apCsr = alloc_space(&x, unsafe { nil }, Sqlite3_int64(u64(n_cursor) * sizeof(voidptr)))
	if x.nNeeded {
		p.pFree = sqlite3_db_malloc_raw_nn(db, U64(x.nNeeded))
		x.pSpace = p.pFree
		x.nFree = x.nNeeded
		if !db.mallocFailed {
			p.aMem = alloc_space(&x, voidptr(p.aMem), Sqlite3_int64(u64(n_mem) * sizeof(Mem)))
			p.aVar = alloc_space(&x, voidptr(p.aVar), Sqlite3_int64(u64(n_var) * sizeof(Mem)))
			p.apArg = alloc_space(&x, voidptr(p.apArg), Sqlite3_int64(u64(n_arg) * sizeof(voidptr)))
			p.apCsr = alloc_space(&x, voidptr(p.apCsr), Sqlite3_int64(u64(n_cursor) * sizeof(voidptr)))
		}
	}
	if db.mallocFailed {
		p.nVar = YnVar(0)
		p.nCursor = 0
		p.nMem = 0
	} else {
		p.nCursor = n_cursor
		p.nVar = YnVar(n_var)
		init_mem_array(p.aVar, n_var, db, U16(1))
		p.nMem = n_mem
		init_mem_array(p.aMem, n_mem, db, U16(0))
		C.memset(voidptr(p.apCsr), 0, u64(n_cursor) * sizeof(voidptr))
	}
	sqlite3_vdbe_rewind(p)
}

@[c:'sqlite3VdbeFreeCursor']
fn sqlite3_vdbe_free_cursor(p &Vdbe, p_cx &VdbeCursor) {
	if p_cx {
		sqlite3_vdbe_free_cursor_nn(p, p_cx)
	}
}

@[c:'freeCursorWithCache']
fn free_cursor_with_cache(p &Vdbe, p_cx &VdbeCursor) {
	p_cache := p_cx.pCache
	p_cx.colCache = bool(0)
	p_cx.pCache = 0
	if p_cache.pCValue {
		sqlite3_rc_str_unref(voidptr(p_cache.pCValue))
		p_cache.pCValue = 0
	}
	sqlite3_db_free(p.db, voidptr(p_cache))
	sqlite3_vdbe_free_cursor_nn(p, p_cx)
}

@[c:'sqlite3VdbeFreeCursorNN']
fn sqlite3_vdbe_free_cursor_nn(p &Vdbe, p_cx &VdbeCursor) {
	if p_cx.colCache {
		free_cursor_with_cache(p, p_cx)
		return
	}
	match p_cx.eCurType {
		1 {
			sqlite3_vdbe_sorter_close(p.db, p_cx)
		}
		0 {
			sqlite3_btree_close_cursor(p_cx.uc.pCursor)
		}
		2 {
			pvc_ur := p_cx.uc.pVCur
			p_module := pvc_ur.pVtab.pModule
			pvc_ur.pVtab.nRef--
			p_module.xClose(pvc_ur)
		}
		else {}
	}
}

@[c:'closeCursorsInFrame']
fn close_cursors_in_frame(p &Vdbe) {
	i := 0
	for i = 0; i < p.nCursor; i++ {
		pc := p.apCsr[i]
		if pc {
			sqlite3_vdbe_free_cursor_nn(p, pc)
			p.apCsr[i] = 0
		}
	}
}

@[c:'sqlite3VdbeFrameRestore']
fn sqlite3_vdbe_frame_restore(p_frame &VdbeFrame) int {
	v := p_frame.v
	close_cursors_in_frame(v)
	v.aOp = p_frame.aOp
	v.nOp = p_frame.nOp
	v.aMem = p_frame.aMem
	v.nMem = p_frame.nMem
	v.apCsr = p_frame.apCsr
	v.nCursor = p_frame.nCursor
	v.db.lastRowid = p_frame.lastRowid
	v.nChange = p_frame.nChange
	v.db.nChange = p_frame.nDbChange
	sqlite3_vdbe_delete_aux_data(v.db, &&AuxData(&v.pAuxData), -1, 0)
	v.pAuxData = p_frame.pAuxData
	p_frame.pAuxData = 0
	return p_frame.pc
}

@[c:'closeAllCursors']
fn close_all_cursors(p &Vdbe) {
	if p.pFrame {
		p_frame := &VdbeFrame(0)
		for p_frame = p.pFrame; p_frame.pParent; p_frame = p_frame.pParent {
			0
		}
		sqlite3_vdbe_frame_restore(p_frame)
		p.pFrame = 0
		p.nFrame = 0
	}
	close_cursors_in_frame(p)
	release_mem_array(p.aMem, p.nMem)
	for p.pDelFrame {
		p_del := p.pDelFrame
		p.pDelFrame = p_del.pParent
		sqlite3_vdbe_frame_delete(p_del)
	}
	if p.pAuxData {
		sqlite3_vdbe_delete_aux_data(p.db, &&AuxData(&p.pAuxData), -1, 0)
	}
}

@[c:'sqlite3VdbeSetNumCols']
fn sqlite3_vdbe_set_num_cols(p &Vdbe, n_res_column int) {
	n := 0
	db := p.db
	if p.nResAlloc {
		release_mem_array(p.aColName, int(p.nResAlloc) * 2)
		sqlite3_db_free(db, voidptr(p.aColName))
	}
	n = n_res_column * 2
	p.nResAlloc = U16(n_res_column)
	p.nResColumn = p.nResAlloc
	p.aColName = &Mem(sqlite3_db_malloc_raw_nn(db, U64(sizeof(Mem) * u64(n))))
	if usize(p.aColName) == usize(0) {
		return
	}
	init_mem_array(p.aColName, n, db, U16(1))
}

@[c:'sqlite3VdbeSetColName']
fn sqlite3_vdbe_set_col_name(p &Vdbe, idx int, var int, z_name &i8, x_del fn (voidptr)) int {
	rc := 0
	p_col_name := &Mem(0)
	if p.db.mallocFailed {
		return 7
	}
	p_col_name = unsafe { p.aColName + (idx + var * int(p.nResAlloc)) }
	rc = sqlite3_vdbe_mem_set_text(p_col_name, z_name, I64(-1), x_del)
	return rc
}

@[c:'vdbeCommit']
fn vdbe_commit(db &Sqlite3, p &Vdbe) int {
	i := 0
	n_trans := 0
	rc := 0
	need_xcommit := 0
	rc = sqlite3_vtab_sync(db, p)
	for i = 0; rc == 0 && i < db.nDb; i++ {
		p_bt := db.aDb[i].pBt
		if sqlite3_btree_txn_state(p_bt) == 2 {
			if !vdbe_commit_amj_needed_inited {
				c2v_static_init := [U8(1), U8(1), U8(0), U8(1), U8(0), U8(0)]
				for c2v_i_0, c2v_element_0 in c2v_static_init {
					vdbe_commit_amj_needed[c2v_i_0] = c2v_element_0
				}
				vdbe_commit_amj_needed_inited = true
			}

			p_pager := &Pager(0)
			need_xcommit = 1
			sqlite3_btree_enter(p_bt)
			p_pager = sqlite3_btree_pager(p_bt)
			if int(db.aDb[i].safety_level) != 1 && int(vdbe_commit_amj_needed[sqlite3_pager_get_journal_mode(p_pager)]) && sqlite3_pager_is_memdb(p_pager) == 0 {
				n_trans++
			}
			rc = sqlite3_pager_exclusive_lock(p_pager)
			sqlite3_btree_leave(p_bt)
		}
	}
	if rc != 0 {
		return rc
	}
	if need_xcommit && !isnil(db.xCommitCallback) {
		rc = db.xCommitCallback(voidptr(db.pCommitArg))
		if rc {
			return 19 | (2 << 8)
		}
	}
	if 0 == sqlite3_strlen30(sqlite3_btree_get_filename(db.aDb[0].pBt)) || n_trans <= 1 {
		if need_xcommit {
			for i = 0; rc == 0 && i < db.nDb; i++ {
				p_bt := db.aDb[i].pBt
				if sqlite3_btree_txn_state(p_bt) >= 2 {
					rc = sqlite3_btree_commit_phase_one(p_bt, unsafe { nil })
				}
			}
		}
		for i = 0; rc == 0 && i < db.nDb; i++ {
			p_bt := db.aDb[i].pBt
			txn := sqlite3_btree_txn_state(p_bt)
			if txn != 0 {
				rc = sqlite3_btree_commit_phase_two(p_bt, 0)
			}
		}
		if rc == 0 {
			sqlite3_vtab_commit(db)
		}
	} else {
		p_vfs := db.pVfs
		z_super := unsafe { &i8(nil) }
		z_main_file := sqlite3_btree_get_filename(db.aDb[0].pBt)
		p_super_jrnl := unsafe { &Sqlite3_file(nil) }
		offset := I64(0)
		res := 0
		retry_count := 0
		n_main_file := 0
		n_main_file = sqlite3_strlen30(z_main_file)
		z_super = sqlite3_mp_rintf(db, c'%.4c%s%.16c', 0, voidptr(z_main_file), 0)
		if usize(z_super) == usize(0) {
			return 7
		}
		c2v_pointer_prefix(voidptr(&z_super), z_super, isize(4))
		for {
			i_random := u32(0)
			if retry_count {
				if retry_count > 100 {
					sqlite3_log(13, c'MJ delete: %s', voidptr(z_super))
					sqlite3_os_delete(p_vfs, z_super, 0)
					break
				} else if retry_count == 1 {
					sqlite3_log(13, c'MJ collide: %s', voidptr(z_super))
				}
			}
			retry_count++
			sqlite3_randomness(int(sizeof(i_random)), voidptr(&i_random))
			sqlite3_snprintf(13, unsafe { z_super + n_main_file }, c'-mj%06X9%02X', (i_random >> 8) & u32(16777215), i_random & u32(255))
			0
			rc = sqlite3_os_access(p_vfs, z_super, 0, &res)
			if !(rc == 0 && res) {
				break
			}
		}
		if rc == 0 {
			rc = sqlite3_os_open_malloc(p_vfs, z_super, &&Sqlite3_file(&&Sqlite3_file(c2v_address_of(&p_super_jrnl))), 2 | 4 | 16 | 16384, unsafe { nil })
		}
		if rc != 0 {
			sqlite3_db_free(db, voidptr(z_super - 4))
			return rc
		}
		for i = 0; i < db.nDb; i++ {
			p_bt := db.aDb[i].pBt
			if sqlite3_btree_txn_state(p_bt) == 2 {
				z_file := sqlite3_btree_get_journalname(p_bt)
				if usize(z_file) == usize(0) {
					continue
				}
				rc = sqlite3_os_write(p_super_jrnl, voidptr(z_file), sqlite3_strlen30(z_file) + 1, offset)
				offset += I64(sqlite3_strlen30(z_file) + 1)
				if rc != 0 {
					sqlite3_os_close_free(p_super_jrnl)
					sqlite3_os_delete(p_vfs, z_super, 0)
					sqlite3_db_free(db, voidptr(z_super - 4))
					return rc
				}
			}
		}
		if 0 == (sqlite3_os_device_characteristics(p_super_jrnl) & 1024) && 0 != c2v_assign[int](unsafe { &rc }, int(sqlite3_os_sync(p_super_jrnl, 2))) {
			sqlite3_os_close_free(p_super_jrnl)
			sqlite3_os_delete(p_vfs, z_super, 0)
			sqlite3_db_free(db, voidptr(z_super - 4))
			return rc
		}
		for i = 0; rc == 0 && i < db.nDb; i++ {
			p_bt := db.aDb[i].pBt
			if p_bt {
				rc = sqlite3_btree_commit_phase_one(p_bt, z_super)
			}
		}
		sqlite3_os_close_free(p_super_jrnl)
		if rc != 0 {
			sqlite3_db_free(db, voidptr(z_super - 4))
			return rc
		}
		rc = sqlite3_os_delete(p_vfs, z_super, 1)
		sqlite3_db_free(db, voidptr(z_super - 4))
		z_super = 0
		if rc {
			return rc
		}
		0
		sqlite3_begin_benign_malloc()
		for i = 0; i < db.nDb; i++ {
			p_bt := db.aDb[i].pBt
			if p_bt {
				sqlite3_btree_commit_phase_two(p_bt, 1)
			}
		}
		sqlite3_end_benign_malloc()
		0
		sqlite3_vtab_commit(db)
	}
	return rc
}

@[c:'vdbeCloseStatement']
fn vdbe_close_statement(p &Vdbe, e_op int) int {
	db := p.db
	rc := 0
	i := 0
	i_savepoint := p.iStatement - 1
	for i = 0; i < db.nDb; i++ {
		rc2 := 0
		p_bt := db.aDb[i].pBt
		if p_bt {
			if e_op == 2 {
				rc2 = sqlite3_btree_savepoint(p_bt, 2, i_savepoint)
			}
			if rc2 == 0 {
				rc2 = sqlite3_btree_savepoint(p_bt, 1, i_savepoint)
			}
			if rc == 0 {
				rc = rc2
			}
		}
	}
	db.nStatement--
	p.iStatement = 0
	if rc == 0 {
		if e_op == 2 {
			rc = sqlite3_vtab_savepoint(db, 2, i_savepoint)
		}
		if rc == 0 {
			rc = sqlite3_vtab_savepoint(db, 1, i_savepoint)
		}
	}
	if e_op == 2 {
		db.nDeferredCons = p.nStmtDefCons
		db.nDeferredImmCons = p.nStmtDefImmCons
	}
	return rc
}

@[c:'sqlite3VdbeCloseStatement']
fn sqlite3_vdbe_close_statement(p &Vdbe, e_op int) int {
	if p.db.nStatement && p.iStatement {
		return vdbe_close_statement(p, e_op)
	}
	return 0
}

@[c:'vdbeFkError']
fn vdbe_fk_error(p &Vdbe) int {
	p.rc = (19 | (3 << 8))
	p.errorAction = U8(2)
	sqlite3_vdbe_error(p, c'FOREIGN KEY constraint failed')
	if (int(p.prepFlags) & 128) == 0 {
		return 1
	}
	return 19 | (3 << 8)
}

@[c:'sqlite3VdbeCheckFkImmediate']
fn sqlite3_vdbe_check_fk_immediate(p &Vdbe) int {
	if p.nFkConstraint == I64(0) {
		return 0
	}
	return vdbe_fk_error(p)
}

@[c:'sqlite3VdbeCheckFkDeferred']
fn sqlite3_vdbe_check_fk_deferred(p &Vdbe) int {
	db := p.db
	if (db.nDeferredCons + db.nDeferredImmCons) == I64(0) {
		return 0
	}
	return vdbe_fk_error(p)
}

@[c:'sqlite3VdbeHalt']
fn sqlite3_vdbe_halt(p &Vdbe) int {
	rc := 0
	db := p.db
	if db.mallocFailed {
		p.rc = 7
	}
	close_all_cursors(p)
	0
	if p.bIsReader {
		mrc := 0
		e_statement_op := 0
		is_special_error := 0
		sqlite3_vdbe_enter(p)
		if p.rc {
			mrc = p.rc & 255
			is_special_error = mrc == 7 || mrc == 10 || mrc == 9 || mrc == 13
		} else {
			is_special_error = 0
			mrc = is_special_error
		}
		if is_special_error {
			if !p.readOnly || mrc != 9 {
				if (mrc == 7 || mrc == 13) && int(p.usesStmtJournal) {
					e_statement_op = 2
				} else {
					sqlite3_rollback_all(db, (4 | (2 << 8)))
					sqlite3_close_savepoints(db)
					db.autoCommit = U8(1)
					p.nChange = I64(0)
				}
			}
		}
		if p.rc == 0 || (int(p.errorAction) == 3 && !is_special_error) {
			sqlite3_vdbe_check_fk_immediate(p)
		}
		if !(db.nVTrans > 0 && usize(db.aVTrans) == usize(0)) && int(db.autoCommit) && db.nVdbeWrite == (int(p.readOnly) == 0) {
			if p.rc == 0 || (int(p.errorAction) == 3 && !is_special_error) {
				rc = sqlite3_vdbe_check_fk_deferred(p)
				if rc != 0 {
					if p.readOnly {
						sqlite3_vdbe_leave(p)
						return 1
					}
					rc = (19 | (3 << 8))
				} else if db.flags & (U64(2) << 32) {
					rc = 11
					db.flags &= ~(U64(2) << 32)
				} else {
					rc = vdbe_commit(db, p)
				}
				if rc == 5 && int(p.readOnly) {
					sqlite3_vdbe_leave(p)
					return 5
				} else if rc != 0 {
					sqlite3_system_error(db, rc)
					p.rc = rc
					sqlite3_rollback_all(db, 0)
					p.nChange = I64(0)
				} else {
					db.nDeferredCons = I64(0)
					db.nDeferredImmCons = I64(0)
					db.flags &= ~U64(524288)
					sqlite3_commit_internal_changes(db)
				}
			} else if p.rc == 17 && db.nVdbeActive > 1 {
				p.nChange = I64(0)
			} else {
				sqlite3_rollback_all(db, 0)
				p.nChange = I64(0)
			}
			db.nStatement = 0
		} else if e_statement_op == 0 {
			if p.rc == 0 || int(p.errorAction) == 3 {
				e_statement_op = 1
			} else if int(p.errorAction) == 2 {
				e_statement_op = 2
			} else {
				sqlite3_rollback_all(db, (4 | (2 << 8)))
				sqlite3_close_savepoints(db)
				db.autoCommit = U8(1)
				p.nChange = I64(0)
			}
		}
		if e_statement_op {
			rc = sqlite3_vdbe_close_statement(p, e_statement_op)
			if rc {
				if p.rc == 0 || (p.rc & 255) == 19 {
					p.rc = rc
					sqlite3_db_free(db, voidptr(p.zErrMsg))
					p.zErrMsg = 0
				}
				sqlite3_rollback_all(db, (4 | (2 << 8)))
				sqlite3_close_savepoints(db)
				db.autoCommit = U8(1)
				p.nChange = I64(0)
			}
		}
		if p.changeCntOn {
			if e_statement_op != 2 {
				sqlite3_vdbe_set_changes(db, p.nChange)
			} else {
				sqlite3_vdbe_set_changes(db, I64(0))
			}
			p.nChange = I64(0)
		}
		sqlite3_vdbe_leave(p)
	}
	db.nVdbeActive--
	if !p.readOnly {
		db.nVdbeWrite--
	}
	if p.bIsReader {
		db.nVdbeRead--
	}
	p.eVdbeState = U8(3)
	0
	if db.mallocFailed {
		p.rc = 7
	}
	if db.autoCommit {
		0
	}
	return if p.rc == 5 { 5 } else { 0 }
}

@[c:'sqlite3VdbeResetStepResult']
fn sqlite3_vdbe_reset_step_result(p &Vdbe) {
	p.rc = 0
}

@[c:'sqlite3VdbeTransferError']
fn sqlite3_vdbe_transfer_error(p &Vdbe) int {
	db := p.db
	rc := p.rc
	if p.zErrMsg {
		db.bBenignMalloc++
		sqlite3_begin_benign_malloc()
		if usize(db.pErr) == usize(0) {
			db.pErr = sqlite3_value_new(db)
		}
		sqlite3_value_set_str(db.pErr, -1, voidptr(p.zErrMsg), U8(1), (C2vFn_666e2028766f696470747229(voidptr(-1))))
		sqlite3_end_benign_malloc()
		db.bBenignMalloc--
	} else if db.pErr {
		sqlite3_value_set_null(db.pErr)
	}
	db.errCode = rc
	db.errByteOffset = -1
	return rc
}

@[c:'sqlite3VdbeReset']
fn sqlite3_vdbe_reset(p &Vdbe) int {
	db := &Sqlite3(0)
	db = p.db
	if int(p.eVdbeState) == 2 {
		sqlite3_vdbe_halt(p)
	}
	if p.pc >= 0 {
		0
		if !isnil(db.pErr) || !isnil(p.zErrMsg) {
			sqlite3_vdbe_transfer_error(p)
		} else {
			db.errCode = p.rc
		}
	}
	if p.zErrMsg {
		sqlite3_db_free(db, voidptr(p.zErrMsg))
		p.zErrMsg = 0
	}
	p.pResultRow = 0
	return p.rc & db.errMask
}

@[c:'sqlite3VdbeFinalize']
fn sqlite3_vdbe_finalize(p &Vdbe) int {
	rc := 0
	if int(p.eVdbeState) >= 1 {
		rc = sqlite3_vdbe_reset(p)
	}
	sqlite3_vdbe_delete(p)
	return rc
}

@[c:'sqlite3VdbeDeleteAuxData']
fn sqlite3_vdbe_delete_aux_data(db &Sqlite3, pp &&AuxData, i_op int, mask int) {
	for unsafe { *pp != nil } {
		p_aux := (unsafe { *pp })
		if (i_op < 0) || (p_aux.iAuxOp == i_op && p_aux.iAuxArg >= 0 && (p_aux.iAuxArg > 31 || !(u32(mask) & ((u32(1)) << p_aux.iAuxArg)))) {
			0
			if p_aux.xDeleteAux {
				p_aux.xDeleteAux(voidptr(p_aux.pAux))
			}
			unsafe { *pp = p_aux.pNextAux }
			sqlite3_db_free(db, voidptr(p_aux))
		} else {
			pp = &p_aux.pNextAux
		}
	}
}

@[c:'sqlite3VdbeClearObject']
fn sqlite3_vdbe_clear_object(db &Sqlite3, p &Vdbe) {
	p_sub := &SubProgram(0)
	p_next := &SubProgram(0)

	if p.aColName {
		release_mem_array(p.aColName, int(p.nResAlloc) * 2)
		sqlite3_db_nn_free_nn(db, voidptr(p.aColName))
	}
	for p_sub = p.pProgram; p_sub; p_sub = p_next {
		p_next = p_sub.pNext
		vdbe_free_op_array(db, unsafe { &Op(p_sub.aOp) }, p_sub.nOp)
		sqlite3_db_free(db, voidptr(p_sub))
	}
	if int(p.eVdbeState) != 0 {
		release_mem_array(p.aVar, int(p.nVar))
		if p.pVList {
			sqlite3_db_nn_free_nn(db, voidptr(p.pVList))
		}
		if p.pFree {
			sqlite3_db_nn_free_nn(db, voidptr(p.pFree))
		}
	}
	vdbe_free_op_array(db, p.aOp, p.nOp)
	if p.zSql {
		sqlite3_db_nn_free_nn(db, voidptr(p.zSql))
	}
}

@[c:'sqlite3VdbeDelete']
fn sqlite3_vdbe_delete(p &Vdbe) {
	db := &Sqlite3(0)
	db = p.db
	sqlite3_vdbe_clear_object(db, p)
	if usize(db.pnBytesFreed) == usize(0) {
		unsafe { *p.ppVPrev = p.pVNext }
		if p.pVNext {
			p.pVNext.ppVPrev = p.ppVPrev
		}
	}
	sqlite3_db_nn_free_nn(db, voidptr(p))
}

@[c:'sqlite3VdbeFinishMoveto']
fn sqlite3_vdbe_finish_moveto(p &VdbeCursor) int {
	res := 0
	rc := 0

	rc = sqlite3_btree_table_moveto(p.uc.pCursor, p.movetoTarget, 0, &res)
	if rc {
		return rc
	}
	if res != 0 {
		return sqlite3_corrupt_error(3811)
	}
	p.deferredMoveto = U8(0)
	p.cacheStatus = u32(0)
	return 0
}

@[c:'sqlite3VdbeHandleMovedCursor']
fn sqlite3_vdbe_handle_moved_cursor(p &VdbeCursor) int {
	is_different_row := 0
	rc := 0

	rc = sqlite3_btree_cursor_restore(p.uc.pCursor, &is_different_row)
	p.cacheStatus = u32(0)
	if is_different_row {
		p.nullRow = U8(1)
	}
	return rc
}

@[c:'sqlite3VdbeCursorRestore']
fn sqlite3_vdbe_cursor_restore(p &VdbeCursor) int {
	if sqlite3_btree_cursor_has_moved(p.uc.pCursor) {
		return sqlite3_vdbe_handle_moved_cursor(p)
	}
	return 0
}

@[c:'sqlite3VdbeSerialTypeLen']
fn sqlite3_vdbe_serial_type_len(serial_type u32) u32 {
	if serial_type >= u32(128) {
		return (serial_type - u32(12)) / u32(2)
	} else {
		return u32(sqlite3_small_type_sizes[serial_type])
	}
}

@[c:'sqlite3VdbeOneByteSerialTypeLen']
fn sqlite3_vdbe_one_byte_serial_type_len(serial_type U8) U8 {
	return sqlite3_small_type_sizes[serial_type]
}

@[c:'serialGet']
fn serial_get(buf &u8, serial_type u32, p_mem &Mem) {
	x := U64(((u32(buf[0]) << 24) | u32((int(buf[1]) << 16)) | u32((int(buf[2]) << 8)) | u32(buf[3])))
	y := ((u32((buf + 4)[0]) << 24) | u32((int((buf + 4)[1]) << 16)) | u32((int((buf + 4)[2]) << 8)) | u32((buf + 4)[3]))
	x = (x << 32) + U64(y)
	if serial_type == u32(6) {
		p_mem.u.i = unsafe { *&I64(c2v_address_of(&x)) }
		p_mem.flags = U16(4)
		0
	} else {
		0
		C.memcpy(voidptr(&p_mem.u.r), voidptr(&x), sizeof(x))
		p_mem.flags = U16(if ((x & ((U64(2047)) << 52)) == ((U64(2047)) << 52) && (x & (((U64(1)) << 52) - U64(1))) != U64(0)) {
			1
		} else {
			8
		})
	}
}

@[c:'serialGet7']
fn serial_get7(buf &u8, p_mem &Mem) int {
	x := U64(((u32(buf[0]) << 24) | u32((int(buf[1]) << 16)) | u32((int(buf[2]) << 8)) | u32(buf[3])))
	y := ((u32((buf + 4)[0]) << 24) | u32((int((buf + 4)[1]) << 16)) | u32((int((buf + 4)[2]) << 8)) | u32((buf + 4)[3]))
	x = (x << 32) + U64(y)
	0
	C.memcpy(voidptr(&p_mem.u.r), voidptr(&x), sizeof(x))
	if ((x & ((U64(2047)) << 52)) == ((U64(2047)) << 52) && (x & (((U64(1)) << 52) - U64(1))) != U64(0)) {
		p_mem.flags = U16(1)
		return 1
	}
	p_mem.flags = U16(8)
	return 0
}

@[c:'sqlite3VdbeSerialGet']
fn sqlite3_vdbe_serial_get(buf &u8, serial_type u32, p_mem &Mem) {
	match serial_type {
		u32(10) {
			p_mem.flags = U16(1 | 1024)
			p_mem.n = 0
			p_mem.u.nZero = 0
			return
		}
		u32(11), u32(0) {
			p_mem.flags = U16(1)
			return
		}
		u32(1) {
			p_mem.u.i = I64((I8(buf[0])))
			p_mem.flags = U16(4)
			0
			return
		}
		u32(2) {
			p_mem.u.i = I64((256 * int(I8(buf[0])) | int(buf[1])))
			p_mem.flags = U16(4)
			0
			return
		}
		u32(3) {
			p_mem.u.i = I64((65536 * int(I8(buf[0])) | (int(buf[1]) << 8) | int(buf[2])))
			p_mem.flags = U16(4)
			0
			return
		}
		u32(4) {
			p_mem.u.i = I64((16777216 * int(I8(buf[0])) | (int(buf[1]) << 16) | (int(buf[2]) << 8) | int(buf[3])))
			p_mem.flags = U16(4)
			0
			return
		}
		u32(5) {
			p_mem.u.i = I64(((u32((buf + 2)[0]) << 24) | u32((int((buf + 2)[1]) << 16)) | u32((int((buf + 2)[2]) << 8)) | u32((buf + 2)[3]))) + ((I64(1)) << 32) * I64((256 * int(I8(buf[0])) | int(buf[1])))
			p_mem.flags = U16(4)
			0
			return
		}
		u32(6), u32(7) {
			serial_get(buf, serial_type, p_mem)
			return
		}
		u32(8), u32(9) {
			p_mem.u.i = I64(serial_type - u32(8))
			p_mem.flags = U16(4)
			return
		}
		else {
			if !sqlite3_vdbe_serial_get_a_flag_inited {
				c2v_static_init := [U16(16 | 16384), U16(2 | 16384)]
				for c2v_i_0, c2v_element_0 in c2v_static_init {
					sqlite3_vdbe_serial_get_a_flag[c2v_i_0] = c2v_element_0
				}
				sqlite3_vdbe_serial_get_a_flag_inited = true
			}

			p_mem.z = &i8(voidptr(buf))
			p_mem.n = int((serial_type - u32(12)) / u32(2))
			p_mem.flags = sqlite3_vdbe_serial_get_a_flag[serial_type & u32(1)]
			return
		}
	}

	return
}

@[c:'sqlite3VdbeAllocUnpackedRecord']
fn sqlite3_vdbe_alloc_unpacked_record(p_key_info &KeyInfo) &UnpackedRecord {
	p := &UnpackedRecord(0)
	n_byte := U64(0)
	n_byte = U64((sizeof(UnpackedRecord)) + sizeof(Mem) * u64((int(p_key_info.nKeyField) + 1)))
	p = &UnpackedRecord(sqlite3_db_malloc_raw(p_key_info.db, n_byte))
	if isnil(p) {
		return unsafe { nil }
	}
	p.aMem = &Mem(voidptr(unsafe { (&i8(voidptr(p))) + (sizeof(UnpackedRecord)) }))
	p.pKeyInfo = p_key_info
	p.nField = U16(int(p_key_info.nKeyField) + 1)
	return p
}

@[c:'sqlite3VdbeRecordUnpack']
fn sqlite3_vdbe_record_unpack(n_key int, p_key voidptr, p &UnpackedRecord) {
	a_key := &u8(p_key)
	d := u32(0)
	idx := u32(0)
	u := U16(0)
	mut sz_hdr := u32(0)
	p_mem := p.aMem
	p_key_info := p.pKeyInfo
	p.default_rc = I8(0)
	idx = u32(U8((if (int((unsafe { *a_key })) < int(U8(128))) {
		(if true {
			sz_hdr = u32((unsafe { *a_key }))
			1
		} else {
			0
		})
	} else {
		int(sqlite3_get_varint32(a_key, &u32(c2v_address_of(&sz_hdr))))
	})))
	d = sz_hdr
	u = U16(0)
	for idx < sz_hdr && d <= u32(n_key) {
		mut serial_type := u32(0)
		idx += u32(U8((if (int((unsafe { *(a_key + idx) })) < int(U8(128))) {
			(if true {
				serial_type = u32((unsafe { *(a_key + idx) }))
				1
			} else {
				0
			})
		} else {
			int(sqlite3_get_varint32((unsafe { a_key + idx }), &u32(c2v_address_of(&serial_type))))
		})))
		p_mem.enc = p_key_info.enc
		p_mem.db = p_key_info.db
		p_mem.szMalloc = 0
		p_mem.z = 0
		sqlite3_vdbe_serial_get(unsafe { a_key + d }, serial_type, p_mem)
		d += sqlite3_vdbe_serial_type_len(serial_type)
		u++
		if int(u) >= int(p.nField) {
			break
		}
		c2v_pointer_postfix(voidptr(&p_mem), p_mem, isize(1))
	}
	if d > u32(n_key) && int(u) {
		sqlite3_vdbe_mem_set_null(p_mem - (int(u) < int(p.nField)))
	}
	0
	0
	p.nField = u
}

@[c:'vdbeCompareMemStringWithEncodingChange']
fn vdbe_compare_mem_string_with_encoding_change(p_mem1 &Mem, p_mem2 &Mem, p_coll &CollSeq, prc_err &U8) int {
	rc := 0
	v1 := &voidptr(0)
	v2 := &voidptr(0)

	c1 := Mem{}
	c2 := Mem{}
	sqlite3_vdbe_mem_init(&c1, p_mem1.db, U16(1))
	sqlite3_vdbe_mem_init(&c2, p_mem1.db, U16(1))
	sqlite3_vdbe_mem_shallow_copy(&c1, p_mem1, 16384)
	sqlite3_vdbe_mem_shallow_copy(&c2, p_mem2, 16384)
	v1 = sqlite3_value_text_vdup5(&Sqlite3_value(c2v_address_of(&c1)), p_coll.enc)
	v2 = sqlite3_value_text_vdup5(&Sqlite3_value(c2v_address_of(&c2)), p_coll.enc)
	if (usize(v1) == usize(0) || usize(v2) == usize(0)) {
		if prc_err {
			unsafe { *prc_err = U8(7) }
		}
		rc = 0
	} else {
		rc = p_coll.xCmp(voidptr(p_coll.pUser), c1.n, voidptr(v1), c2.n, voidptr(v2))
	}
	sqlite3_vdbe_mem_release_malloc(&c1)
	sqlite3_vdbe_mem_release_malloc(&c2)
	return rc
}

@[c:'vdbeCompareMemString']
fn vdbe_compare_mem_string(p_mem1 &Mem, p_mem2 &Mem, p_coll &CollSeq, prc_err &U8) int {
	if int(p_mem1.enc) == int(p_coll.enc) {
		return p_coll.xCmp(voidptr(p_coll.pUser), p_mem1.n, voidptr(p_mem1.z), p_mem2.n, voidptr(p_mem2.z))
	} else {
		return vdbe_compare_mem_string_with_encoding_change(p_mem1, p_mem2, p_coll, prc_err)
	}
}

@[c:'isAllZero']
fn is_all_zero(z &i8, n int) int {
	i := 0
	for i = 0; i < n; i++ {
		if z[i] {
			return 0
		}
	}
	return 1
}

@[c:'sqlite3BlobCompare']
fn sqlite3_blob_compare(p_b1 &Mem, p_b2 &Mem) int {
	c := 0
	n1 := p_b1.n
	n2 := p_b2.n
	if (int(p_b1.flags) | int(p_b2.flags)) & 1024 {
		if int(p_b1.flags) & int(p_b2.flags) & 1024 {
			return p_b1.u.nZero - p_b2.u.nZero
		} else if int(p_b1.flags) & 1024 {
			if !is_all_zero(p_b2.z, p_b2.n) {
				return -1
			}
			return p_b1.u.nZero - n2
		} else {
			if !is_all_zero(p_b1.z, p_b1.n) {
				return 1
			}
			return n1 - p_b2.u.nZero
		}
	}
	c = C.memcmp(voidptr(p_b1.z), voidptr(p_b2.z), u64(if n1 > n2 { n2 } else { n1 }))
	if c {
		return c
	}
	return n1 - n2
}

@[c:'sqlite3IntFloatCompare']
fn sqlite3_int_float_compare(i I64, r f64) int {
	if sqlite3_is_na_n(r) {
		return 1
	} else {
		y := I64(0)
		if r < -9.2233720368547758E+18 {
			return 1
		}
		if r >= 9.2233720368547758E+18 {
			return -1
		}
		y = I64(r)
		if i < y {
			return -1
		}
		if i > y {
			return 1
		}
		0
		0
		0
		return if ((f64(i)) < r) { -1 } else { ((f64(i)) > r) }
	}
}

@[c:'sqlite3MemCompare']
fn sqlite3_mem_compare(p_mem1 &Mem, p_mem2 &Mem, p_coll &CollSeq) int {
	f1 := 0
	f2 := 0

	combined_flags := 0
	f1 = int(p_mem1.flags)
	f2 = int(p_mem2.flags)
	combined_flags = f1 | f2
	if combined_flags & 1 {
		return (f2 & 1) - (f1 & 1)
	}
	if combined_flags & (4 | 8 | 32) {
		0
		0
		0
		if (f1 & f2 & (4 | 32)) != 0 {
			0
			0
			if p_mem1.u.i < p_mem2.u.i {
				return -1
			}
			if p_mem1.u.i > p_mem2.u.i {
				return 1
			}
			return 0
		}
		if (f1 & f2 & 8) != 0 {
			if p_mem1.u.r < p_mem2.u.r {
				return -1
			}
			if p_mem1.u.r > p_mem2.u.r {
				return 1
			}
			return 0
		}
		if (f1 & (4 | 32)) != 0 {
			0
			0
			if (f2 & 8) != 0 {
				return sqlite3_int_float_compare(p_mem1.u.i, p_mem2.u.r)
			} else if (f2 & (4 | 32)) != 0 {
				if p_mem1.u.i < p_mem2.u.i {
					return -1
				}
				if p_mem1.u.i > p_mem2.u.i {
					return 1
				}
				return 0
			} else {
				return -1
			}
		}
		if (f1 & 8) != 0 {
			if (f2 & (4 | 32)) != 0 {
				0
				0
				return -sqlite3_int_float_compare(p_mem2.u.i, p_mem1.u.r)
			} else {
				return -1
			}
		}
		return 1
	}
	if combined_flags & 2 {
		if (f1 & 2) == 0 {
			return 1
		}
		if (f2 & 2) == 0 {
			return -1
		}
		if p_coll {
			return vdbe_compare_mem_string(p_mem1, p_mem2, p_coll, unsafe { nil })
		}
	}
	return sqlite3_blob_compare(p_mem1, p_mem2)
}

@[c:'vdbeRecordDecodeInt']
fn vdbe_record_decode_int(serial_type u32, a_key &U8) I64 {
	y := u32(0)
	match serial_type {
		u32(0), u32(1) {
			0
			return I64((I8(a_key[0])))
		}
		u32(2) {
			0
			return I64((256 * int(I8(a_key[0])) | int(a_key[1])))
		}
		u32(3) {
			0
			return I64((65536 * int(I8(a_key[0])) | (int(a_key[1]) << 8) | int(a_key[2])))
		}
		u32(4) {
			0
			y = ((u32(a_key[0]) << 24) | u32((int(a_key[1]) << 16)) | u32((int(a_key[2]) << 8)) | u32(a_key[3]))
			return I64((unsafe { *&int(c2v_address_of(&y)) }))
		}
		u32(5) {
			0
			return I64(((u32((a_key + 2)[0]) << 24) | u32((int((a_key + 2)[1]) << 16)) | u32((int((a_key + 2)[2]) << 8)) | u32((a_key + 2)[3]))) + ((I64(1)) << 32) * I64((256 * int(I8(a_key[0])) | int(a_key[1])))
		}
		u32(6) {
			x := U64(((u32(a_key[0]) << 24) | u32((int(a_key[1]) << 16)) | u32((int(a_key[2]) << 8)) | u32(a_key[3])))
			0
			x = (x << 32) | U64(((u32((a_key + 4)[0]) << 24) | u32((int((a_key + 4)[1]) << 16)) | u32((int((a_key + 4)[2]) << 8)) | u32((a_key + 4)[3])))
			return I64((unsafe { *&I64(c2v_address_of(&x)) }))
		}
		else {}
	}

	return I64((serial_type - u32(8)))
}

@[c:'sqlite3VdbeRecordCompareWithSkip']
fn sqlite3_vdbe_record_compare_with_skip(n_key1 int, p_key1 voidptr, ppk_ey2 &UnpackedRecord, b_skip int) int {
	d1 := u32(0)
	i := 0
	sz_hdr1 := u32(0)
	idx1 := u32(0)
	rc := 0
	p_rhs := ppk_ey2.aMem
	p_key_info := &KeyInfo(0)
	a_key1 := &u8(p_key1)
	mem1 := Mem{}
	if b_skip {
		s1 := u32(a_key1[1])
		if s1 < u32(128) {
			idx1 = u32(2)
		} else {
			idx1 = u32(1 + int(sqlite3_get_varint32(unsafe { a_key1 + 1 }, &s1)))
		}
		sz_hdr1 = u32(a_key1[0])
		d1 = sz_hdr1 + sqlite3_vdbe_serial_type_len(s1)
		i = 1
		c2v_pointer_postfix(voidptr(&p_rhs), p_rhs, isize(1))
	} else {
		sz_hdr1 = u32(a_key1[0])
		if sz_hdr1 < u32(128) {
			idx1 = u32(1)
		} else {
			idx1 = u32(sqlite3_get_varint32(a_key1, &sz_hdr1))
		}
		d1 = sz_hdr1
		i = 0
	}
	if d1 > u32(n_key1) {
		ppk_ey2.errCode = U8(sqlite3_corrupt_error(4772))
		return 0
	}
	for {
		serial_type := u32(0)
		if int(p_rhs.flags) & (4 | 32) {
			0
			0
			serial_type = u32(a_key1[idx1])
			0
			if serial_type >= u32(10) {
				rc = if serial_type == u32(10) { -1 } else { 1 }
			} else if serial_type == u32(0) {
				rc = -1
			} else if serial_type == u32(7) {
				serial_get7(unsafe { a_key1 + d1 }, &mem1)
				rc = -sqlite3_int_float_compare(p_rhs.u.i, mem1.u.r)
			} else {
				lhs := vdbe_record_decode_int(serial_type, unsafe { &U8(a_key1 + d1) })
				rhs := p_rhs.u.i
				if lhs < rhs {
					rc = -1
				} else if lhs > rhs {
					rc = 1
				}
			}
		} else if int(p_rhs.flags) & 8 {
			serial_type = u32(a_key1[idx1])
			if serial_type >= u32(10) {
				rc = if serial_type == u32(10) { -1 } else { 1 }
			} else if serial_type == u32(0) {
				rc = -1
			} else {
				if serial_type == u32(7) {
					if serial_get7(unsafe { a_key1 + d1 }, &mem1) {
						rc = -1
					} else if mem1.u.r < p_rhs.u.r {
						rc = -1
					} else if mem1.u.r > p_rhs.u.r {
						rc = 1
					} else {
					}
				} else {
					sqlite3_vdbe_serial_get(unsafe { a_key1 + d1 }, serial_type, &mem1)
					rc = sqlite3_int_float_compare(mem1.u.i, p_rhs.u.r)
				}
			}
		} else if int(p_rhs.flags) & 2 {
			serial_type = u32((unsafe { *(a_key1 + idx1) }))
			if serial_type >= u32(128) {
				sqlite3_get_varint32((unsafe { a_key1 + idx1 }), &u32(c2v_address_of(&serial_type)))
			}
			0
			if serial_type < u32(12) {
				rc = -1
			} else if !(serial_type & u32(1)) {
				rc = 1
			} else {
				mem1.n = int((serial_type - u32(12)) / u32(2))
				0
				0
				if (d1 + u32(mem1.n)) > u32(n_key1) || int(c2v_assign[&KeyInfo](unsafe { &p_key_info }, ppk_ey2.pKeyInfo).nAllField) <= i {
					ppk_ey2.errCode = U8(sqlite3_corrupt_error(4853))
					return 0
				} else if (&p_key_info.aColl[0])[i] {
					mem1.enc = p_key_info.enc
					mem1.db = p_key_info.db
					mem1.flags = U16(2)
					mem1.z = &i8(voidptr(unsafe { a_key1 + d1 }))
					rc = vdbe_compare_mem_string(&mem1, p_rhs, (&p_key_info.aColl[0])[i], &ppk_ey2.errCode)
				} else {
					n_cmp := (if mem1.n < p_rhs.n { mem1.n } else { p_rhs.n })
					rc = C.memcmp(voidptr(unsafe { a_key1 + d1 }), voidptr(p_rhs.z), u64(n_cmp))
					if rc == 0 {
						rc = mem1.n - p_rhs.n
					}
				}
			}
		} else if int(p_rhs.flags) & 16 {
			serial_type = u32((unsafe { *(a_key1 + idx1) }))
			if serial_type >= u32(128) {
				sqlite3_get_varint32((unsafe { a_key1 + idx1 }), &u32(c2v_address_of(&serial_type)))
			}
			0
			if serial_type < u32(12) || (serial_type & u32(1)) {
				rc = -1
			} else {
				n_str := int((serial_type - u32(12)) / u32(2))
				0
				0
				if (d1 + u32(n_str)) > u32(n_key1) {
					ppk_ey2.errCode = U8(sqlite3_corrupt_error(4883))
					return 0
				} else if int(p_rhs.flags) & 1024 {
					if !is_all_zero(&i8(voidptr(unsafe { a_key1 + d1 })), n_str) {
						rc = 1
					} else {
						rc = n_str - p_rhs.u.nZero
					}
				} else {
					n_cmp := (if n_str < p_rhs.n { n_str } else { p_rhs.n })
					rc = C.memcmp(voidptr(unsafe { a_key1 + d1 }), voidptr(p_rhs.z), u64(n_cmp))
					if rc == 0 {
						rc = n_str - p_rhs.n
					}
				}
			}
		} else {
			serial_type = u32(a_key1[idx1])
			if serial_type == u32(0) || serial_type == u32(10) || (serial_type == u32(7) && serial_get7(unsafe { a_key1 + d1 }, &mem1) != 0) {
			} else {
				rc = 1
			}
		}
		if rc != 0 {
			sort_flags := int(ppk_ey2.pKeyInfo.aSortFlags[i])
			if sort_flags {
				if (sort_flags & 2) == 0 || ((sort_flags & 1) != (serial_type == u32(0) || (int(p_rhs.flags) & 1))) {
					rc = -rc
				}
			}
			return rc
		}
		i++
		if i == int(ppk_ey2.nField) {
			break
		}
		c2v_pointer_postfix(voidptr(&p_rhs), p_rhs, isize(1))
		d1 += sqlite3_vdbe_serial_type_len(serial_type)
		if d1 > u32(n_key1) {
			break
		}
		idx1 += u32(sqlite3_varint_len(U64(serial_type)))
		if idx1 >= u32(sz_hdr1) {
			ppk_ey2.errCode = U8(sqlite3_corrupt_error(4934))
			return 0
		}
	}
	ppk_ey2.eqSeen = U8(1)
	return int(ppk_ey2.default_rc)
}

@[c:'sqlite3VdbeRecordCompare']
fn sqlite3_vdbe_record_compare(n_key1 int, p_key1 voidptr, ppk_ey2 &UnpackedRecord) int {
	c2v_gc_register_thread()
	return sqlite3_vdbe_record_compare_with_skip(n_key1, voidptr(p_key1), ppk_ey2, 0)
}

@[c:'vdbeRecordCompareInt']
fn vdbe_record_compare_int(n_key1 int, p_key1 voidptr, ppk_ey2 &UnpackedRecord) int {
	c2v_gc_register_thread()
	a_key := unsafe { (&U8(p_key1)) + (int(*&U8(p_key1)) & 63) }
	serial_type := int((&U8(p_key1))[1])
	res := 0
	y := u32(0)
	x := U64(0)
	v := I64(0)
	lhs := I64(0)
	0
	match serial_type {
		1 {
			lhs = I64((I8(a_key[0])))
			0
		}
		2 {
			lhs = I64((256 * int(I8(a_key[0])) | int(a_key[1])))
			0
		}
		3 {
			lhs = I64((65536 * int(I8(a_key[0])) | (int(a_key[1]) << 8) | int(a_key[2])))
			0
		}
		4 {
			y = ((u32(a_key[0]) << 24) | u32((int(a_key[1]) << 16)) | u32((int(a_key[2]) << 8)) | u32(a_key[3]))
			lhs = I64((unsafe { *&int(c2v_address_of(&y)) }))
			0
		}
		5 {
			lhs = I64(((u32((a_key + 2)[0]) << 24) | u32((int((a_key + 2)[1]) << 16)) | u32((int((a_key + 2)[2]) << 8)) | u32((a_key + 2)[3]))) + ((I64(1)) << 32) * I64((256 * int(I8(a_key[0])) | int(a_key[1])))
			0
		}
		6 {
			x = U64(((u32(a_key[0]) << 24) | u32((int(a_key[1]) << 16)) | u32((int(a_key[2]) << 8)) | u32(a_key[3])))
			x = (x << 32) | U64(((u32((a_key + 4)[0]) << 24) | u32((int((a_key + 4)[1]) << 16)) | u32((int((a_key + 4)[2]) << 8)) | u32((a_key + 4)[3])))
			lhs = unsafe { *&I64(c2v_address_of(&x)) }
			0
		}
		8 {
			lhs = I64(0)
		}
		9 {
			lhs = I64(1)
		}
		0, 7 {
			return sqlite3_vdbe_record_compare(n_key1, voidptr(p_key1), ppk_ey2)
		}
		else {
			return sqlite3_vdbe_record_compare(n_key1, voidptr(p_key1), ppk_ey2)
		}
	}

	v = ppk_ey2.u.i
	if v > lhs {
		res = int(ppk_ey2.r1)
	} else if v < lhs {
		res = int(ppk_ey2.r2)
	} else if int(ppk_ey2.nField) > 1 {
		res = sqlite3_vdbe_record_compare_with_skip(n_key1, voidptr(p_key1), ppk_ey2, 1)
	} else {
		res = int(ppk_ey2.default_rc)
		ppk_ey2.eqSeen = U8(1)
	}
	return res
}

@[c:'vdbeRecordCompareString']
fn vdbe_record_compare_string(n_key1 int, p_key1 voidptr, ppk_ey2 &UnpackedRecord) int {
	c2v_gc_register_thread()
	a_key1 := &U8(p_key1)
	serial_type := 0
	res := 0
	0
	serial_type = int(i8(a_key1[1]))
	vrcs_restart:
	if serial_type < 12 {
		if serial_type < 0 {
			sqlite3_get_varint32(unsafe { a_key1 + 1 }, &u32(c2v_address_of(&serial_type)))
			if serial_type >= 12 {
				unsafe { goto vrcs_restart
				 }
			}
		}
		res = int(ppk_ey2.r1)
	} else if !(serial_type & 1) {
		res = int(ppk_ey2.r2)
	} else {
		n_cmp := 0
		n_str := 0
		sz_hdr := int(a_key1[0])
		n_str = (serial_type - 12) / 2
		if (sz_hdr + n_str) > n_key1 {
			ppk_ey2.errCode = U8(sqlite3_corrupt_error(5097))
			return 0
		}
		n_cmp = (if ppk_ey2.n < n_str { ppk_ey2.n } else { n_str })
		res = C.memcmp(voidptr(unsafe { a_key1 + sz_hdr }), voidptr(ppk_ey2.u.z), u64(n_cmp))
		if res > 0 {
			res = int(ppk_ey2.r2)
		} else if res < 0 {
			res = int(ppk_ey2.r1)
		} else {
			res = n_str - ppk_ey2.n
			if res == 0 {
				if int(ppk_ey2.nField) > 1 {
					res = sqlite3_vdbe_record_compare_with_skip(n_key1, voidptr(p_key1), ppk_ey2, 1)
				} else {
					res = int(ppk_ey2.default_rc)
					ppk_ey2.eqSeen = U8(1)
				}
			} else if res > 0 {
				res = int(ppk_ey2.r2)
			} else {
				res = int(ppk_ey2.r1)
			}
		}
	}
	return res
}

@[c:'sqlite3VdbeFindCompare']
fn sqlite3_vdbe_find_compare(p &UnpackedRecord) RecordCompare {
	if int(p.pKeyInfo.nAllField) <= 13 {
		flags := int(p.aMem[0].flags)
		if p.pKeyInfo.aSortFlags[0] {
			if int(p.pKeyInfo.aSortFlags[0]) & 2 {
				return sqlite3_vdbe_record_compare
			}
			p.r1 = I8(1)
			p.r2 = I8(-1)
		} else {
			p.r1 = I8(-1)
			p.r2 = I8(1)
		}
		if (flags & 4) {
			p.u.i = p.aMem[0].u.i
			return vdbe_record_compare_int
		}
		0
		0
		0
		if (flags & (8 | 32 | 1 | 16)) == 0 && usize((&p.pKeyInfo.aColl[0])[0]) == usize(0) {
			p.u.z = p.aMem[0].z
			p.n = p.aMem[0].n
			return vdbe_record_compare_string
		}
	}
	return sqlite3_vdbe_record_compare
}

@[c:'sqlite3VdbeIdxRowid']
fn sqlite3_vdbe_idx_rowid(db &Sqlite3, p_cur &BtCursor, rowid &I64) int {
	n_cell_key := I64(0)
	rc := 0
	sz_hdr := u32(0)
	type_rowid := u32(0)
	len_rowid := u32(0)
	m := Mem{}
	v := Mem{}

	n_cell_key = I64(sqlite3_btree_payload_size(p_cur))
	sqlite3_vdbe_mem_init(&m, db, U16(0))
	rc = sqlite3_vdbe_mem_from_btree_zero_offset(p_cur, u32(n_cell_key), &m)
	if rc {
		return rc
	}
	sz_hdr = u32((unsafe { *(&U8(voidptr(m.z))) }))
	if sz_hdr >= u32(128) {
		sqlite3_get_varint32((&U8(voidptr(m.z))), &u32(c2v_address_of(&sz_hdr)))
	}
	0
	0
	0
	if (sz_hdr < u32(3) || sz_hdr > u32(m.n)) {
		unsafe { goto idx_rowid_corruption
		 }
	}
	type_rowid = u32((unsafe { *(&U8(voidptr(m.z + (sz_hdr - u32(1))))) }))
	if type_rowid >= u32(128) {
		sqlite3_get_varint32((&U8(voidptr(unsafe { m.z + (sz_hdr - u32(1)) }))), &u32(c2v_address_of(&type_rowid)))
	}
	0
	0
	0
	0
	0
	0
	0
	0
	if (type_rowid < u32(1) || type_rowid > u32(9) || type_rowid == u32(7)) {
		unsafe { goto idx_rowid_corruption
		 }
	}
	len_rowid = u32(sqlite3_small_type_sizes[type_rowid])
	0
	if (u32(m.n) < sz_hdr + len_rowid) {
		unsafe { goto idx_rowid_corruption
		 }
	}
	sqlite3_vdbe_serial_get(&U8(voidptr(unsafe { m.z + (u32(m.n) - len_rowid) })), type_rowid, &v)
	unsafe { *rowid = v.u.i }
	sqlite3_vdbe_mem_release_malloc(&m)
	return 0
	idx_rowid_corruption:
	0
	sqlite3_vdbe_mem_release_malloc(&m)
	return sqlite3_corrupt_error(5256)
}

@[c:'sqlite3VdbeIdxKeyCompare']
fn sqlite3_vdbe_idx_key_compare(db &Sqlite3, pc &VdbeCursor, p_unpacked &UnpackedRecord, res &int) int {
	n_cell_key := I64(0)
	rc := 0
	p_cur := &BtCursor(0)
	m := Mem{}
	p_cur = pc.uc.pCursor
	n_cell_key = I64(sqlite3_btree_payload_size(p_cur))
	if n_cell_key <= I64(0) || n_cell_key > I64(2147483647) {
		unsafe { *res = 0 }
		return sqlite3_corrupt_error(5289)
	}
	sqlite3_vdbe_mem_init(&m, db, U16(0))
	rc = sqlite3_vdbe_mem_from_btree_zero_offset(p_cur, u32(n_cell_key), &m)
	if rc {
		return rc
	}
	unsafe { *res = sqlite3_vdbe_record_compare_with_skip(m.n, voidptr(m.z), p_unpacked, 0) }
	sqlite3_vdbe_mem_release_malloc(&m)
	return 0
}

@[c:'sqlite3VdbeSetChanges']
fn sqlite3_vdbe_set_changes(db &Sqlite3, n_change I64) {
	db.nChange = n_change
	db.nTotalChange += n_change
}

@[c:'sqlite3VdbeCountChanges']
fn sqlite3_vdbe_count_changes(v &Vdbe) {
	v.changeCntOn = Bft(1)
}

@[c:'sqlite3ExpirePreparedStatements']
fn sqlite3_expire_prepared_statements(db &Sqlite3, i_code int) {
	p := &Vdbe(0)
	for p = db.pVdbe; p; p = p.pVNext {
		p.expired = Bft(i_code + 1)
	}
}

@[c:'sqlite3VdbeDb']
fn sqlite3_vdbe_db(v &Vdbe) &Sqlite3 {
	return v.db
}

@[c:'sqlite3VdbePrepareFlags']
fn sqlite3_vdbe_prepare_flags(v &Vdbe) U8 {
	return v.prepFlags
}

@[c:'sqlite3VdbeGetBoundValue']
fn sqlite3_vdbe_get_bound_value(v &Vdbe, i_var int, aff U8) &Sqlite3_value {
	if v {
		p_mem := unsafe { v.aVar + (i_var - 1) }
		if 0 == (int(p_mem.flags) & 1) {
			p_ret := sqlite3_value_new(v.db)
			if p_ret {
				sqlite3_vdbe_mem_copy(&Mem(p_ret), p_mem)
				sqlite3_value_apply_affinity(p_ret, aff, U8(1))
			}
			return p_ret
		}
	}
	return unsafe { nil }
}

@[c:'sqlite3VdbeSetVarmask']
fn sqlite3_vdbe_set_varmask(v &Vdbe, i_var int) {
	if i_var >= 32 {
		v.expmask |= u32(2147483648)
	} else {
		v.expmask |= (u32(1) << (i_var - 1))
	}
}

@[c:'vdbeSkipField']
fn vdbe_skip_field(mask Bitmask, i_col int, p_mem1 &Mem, p_mem2 &Mem, b_integrity int) int {
	if i_col >= (int((sizeof(Bitmask) * u64(8)))) || (mask & ((Bitmask(1)) << i_col)) == Bitmask(0) {
		return 0
	}
	if b_integrity == 0 {
		return 1
	}
	if (int(p_mem1.flags) & 8) && (int(p_mem2.flags) & 8) {
		m1 := U64(0)
		m2 := U64(0)

		C.memcpy(voidptr(&m1), voidptr(&p_mem1.u.r), u64(8))
		C.memcpy(voidptr(&m2), voidptr(&p_mem2.u.r), u64(8))
		if (if m1 < m2 { m2 - m1 } else { m1 - m2 }) <= U64(2) {
			return 1
		}
	}
	return 0
}

@[c:'vdbeIsMatchingIndexKey']
fn vdbe_is_matching_index_key(p_cur &BtCursor, b_int int, mask Bitmask, p &UnpackedRecord, pi_res &int) int {
	a_rec := unsafe { &U8(nil) }
	n_rec := u32(0)
	mem := Mem{}
	rc := 0
	C.memset(voidptr(&mem), 0, sizeof(mem))
	mem.enc = p.pKeyInfo.enc
	mem.db = p.pKeyInfo.db
	n_rec = sqlite3_btree_payload_size(p_cur)
	if n_rec > u32(2147483647) {
		return sqlite3_corrupt_error(5461)
	}
	a_rec = sqlite3_malloc_zero(U64(n_rec + u32(5)))
	if usize(a_rec) == usize(0) {
		rc = 7
	} else {
		rc = sqlite3_btree_payload(p_cur, u32(0), n_rec, voidptr(a_rec))
	}
	if rc == 0 {
		mut sz_hdr := u32(0)
		idx_hdr := u32(0)
		idx_hdr = u32(U8((if (int((unsafe { *a_rec })) < int(U8(128))) {
			(if true {
				sz_hdr = u32((unsafe { *a_rec }))
				1
			} else {
				0
			})
		} else {
			int(sqlite3_get_varint32(a_rec, &u32(c2v_address_of(&sz_hdr))))
		})))
		if sz_hdr > u32(98307) {
			rc = 11
		} else {
			res := 0
			idx_rec := sz_hdr
			ii := 0
			n_col := int(p.pKeyInfo.nAllField)
			for ii = 0; ii < n_col && rc == 0; ii++ {
				mut i_serial := u32(0)
				n_serial := 0
				if idx_hdr >= sz_hdr {
					rc = sqlite3_corrupt_error(5492)
					break
				}
				idx_hdr += u32(U8((if (int((unsafe { *(a_rec + idx_hdr) })) < int(U8(128))) {
					(if true {
						i_serial = u32((unsafe { *(a_rec + idx_hdr) }))
						1
					} else {
						0
					})
				} else {
					int(sqlite3_get_varint32((unsafe { a_rec + idx_hdr }), &u32(c2v_address_of(&i_serial))))
				})))
				n_serial = int(sqlite3_vdbe_serial_type_len(i_serial))
				if (idx_rec + u32(n_serial)) > n_rec {
					rc = sqlite3_corrupt_error(5498)
				} else {
					sqlite3_vdbe_serial_get(unsafe { a_rec + idx_rec }, i_serial, &mem)
					if vdbe_skip_field(mask, ii, unsafe { p.aMem + ii }, &mem, b_int) == 0 {
						res = sqlite3_mem_compare(&mem, unsafe { p.aMem + ii }, (&p.pKeyInfo.aColl[0])[ii])
						if res != 0 {
							break
						}
					}
				}
				idx_rec += sqlite3_vdbe_serial_type_len(i_serial)
			}
			unsafe { *pi_res = res }
		}
	}
	sqlite3_free(voidptr(a_rec))
	return rc
}

@[c:'sqlite3VdbeFindIndexKey']
fn sqlite3_vdbe_find_index_key(p_cur &BtCursor, p_idx &Index, p &UnpackedRecord, p_res &int, b_integrity int) int {
	n_step := 0
	res := 1
	rc := 0
	ii := 0
	mask := Bitmask(0)
	for ii = 0; ii < (if int(p_idx.nColumn) < (int((sizeof(Bitmask) * u64(8)))) {
		int(p_idx.nColumn)
	} else {
		(int((sizeof(Bitmask) * u64(8))))
	}); ii++ {
		i_col := int(p_idx.aiColumn[ii])
		if (i_col == (-2)) || (i_col >= 0 && (int(p_idx.pTable.aCol[i_col].colFlags) & 32)) {
			mask |= ((Bitmask(1)) << ii)
		}
	}
	if mask != Bitmask(0) {
		for ii = 0; sqlite3_btree_eof(p_cur) == 0 && ii < 10; ii++ {
			rc = sqlite3_btree_previous(p_cur, 0)
		}
		if rc == 101 {
			rc = sqlite3_btree_first(p_cur, &res)
			n_step = -1
		} else {
			n_step = 10 * 2
		}
		for sqlite3_btree_cursor_is_valid_nn(p_cur) {
			for ii = 0; rc == 0 && (ii < n_step || n_step < 0); ii++ {
				rc = vdbe_is_matching_index_key(p_cur, b_integrity, mask, p, &res)
				if res == 0 || rc != 0 {
					break
				}
				rc = sqlite3_btree_next(p_cur, 0)
			}
			if rc == 101 {
				rc = 0
			}
			if n_step < 0 || rc != 0 || res == 0 || b_integrity {
				break
			}
			n_step = -1
			rc = sqlite3_btree_first(p_cur, &res)
		}
	}
	unsafe { *p_res = res }
	return rc
}

@[c:'sqlite3NotPureFunc']
fn sqlite3_not_pure_func(p_ctx &Sqlite3_context) int {
	p_op := &VdbeOp(0)
	p_op = p_ctx.pVdbe.aOp + p_ctx.iOp
	if int(p_op.opcode) == 67 {
		z_context := &i8(0)
		z_msg := &i8(0)
		if int(p_op.p5) & 4 {
			z_context = c'a CHECK constraint'
		} else if int(p_op.p5) & 8 {
			z_context = c'a generated column'
		} else {
			z_context = c'an index'
		}
		z_msg = sqlite3_mprintf(c'non-deterministic use of %s() in %s', voidptr(p_ctx.pFunc.zName), voidptr(z_context))
		sqlite3_result_error(p_ctx, z_msg, -1)
		sqlite3_free(voidptr(z_msg))
		return 0
	}
	return 1
}

@[c:'sqlite3VtabImportErrmsg']
fn sqlite3_vtab_import_errmsg(p &Vdbe, p_vtab &Sqlite3_vtab) {
	if p_vtab.zErrMsg {
		db := p.db
		sqlite3_db_free(db, voidptr(p.zErrMsg))
		p.zErrMsg = sqlite3_db_str_dup(db, p_vtab.zErrMsg)
		sqlite3_free(voidptr(p_vtab.zErrMsg))
		p_vtab.zErrMsg = 0
	}
}
