@[translated]
module main

@[c:'allocateCursor']
fn allocate_cursor(p &Vdbe, i_cur int, n_field int, e_cur_type U8) &VdbeCursor {
	p_mem := if i_cur > 0 { p.aMem + (p.nMem - i_cur) } else { p.aMem }
	n_byte := I64(0)
	p_cx := unsafe { &VdbeCursor(nil) }
	n_byte = I64(((((u64(usize(__offsetof(VdbeCursor, aType)))) + u64(7)) & u64(~7)) + u64((n_field + 1)) * sizeof(U64)))
	if int(e_cur_type) == 0 {
		n_byte += I64(sqlite3_btree_cursor_size())
	}
	if p.apCsr[i_cur] {
		sqlite3_vdbe_free_cursor_nn(p, p.apCsr[i_cur])
		p.apCsr[i_cur] = 0
	}
	if I64(p_mem.szMalloc) < n_byte {
		if p_mem.szMalloc > 0 {
			sqlite3_db_free_nn(p_mem.db, voidptr(p_mem.zMalloc))
		}
		p_mem.zMalloc = &i8(sqlite3_db_malloc_raw(p_mem.db, U64(n_byte)))
		p_mem.z = p_mem.zMalloc
		if usize(p_mem.zMalloc) == usize(0) {
			p_mem.szMalloc = 0
			return unsafe { nil }
		}
		p_mem.szMalloc = int(n_byte)
	}
	p_cx = &VdbeCursor(voidptr(p_mem.zMalloc))
	p.apCsr[i_cur] = p_cx
	C.memset(voidptr(p_cx), 0, (u64(usize(__offsetof(VdbeCursor, pAltCursor)))))
	p_cx.eCurType = e_cur_type
	p_cx.nField = I16(n_field)
	p_cx.aOffset = unsafe { &p_cx.aType[0] + n_field }
	if int(e_cur_type) == 0 {
		p_cx.uc.pCursor = &BtCursor(voidptr(unsafe { p_mem.z + ((((u64(usize(__offsetof(VdbeCursor, aType)))) + u64(7)) & u64(~7)) + u64((n_field + 1)) * sizeof(U64)) }))
		sqlite3_btree_cursor_zero(p_cx.uc.pCursor)
	}
	return p_cx
}

@[c:'alsoAnInt']
fn also_an_int(p_rec &Mem, r_value f64, pi_value &I64) int {
	i_value := I64(0)
	i_value = sqlite3_real_to_i64(r_value)
	if sqlite3_real_same_as_int(r_value, i_value) {
		unsafe { *pi_value = i_value }
		return 1
	}
	return int(0 == sqlite3_atoi64(p_rec.z, pi_value, p_rec.n, p_rec.enc))
}

@[c:'applyNumericAffinity']
fn apply_numeric_affinity(p_rec &Mem, b_try_for_int int) {
	r_value := 0.0
	rc := 0
	rc = sqlite3_mem_real_value_rc(p_rec, &r_value)
	if rc <= 0 {
		return
	}
	if (rc & 2) == 0 && also_an_int(p_rec, r_value, &p_rec.u.i) {
		p_rec.flags |= 4
	} else {
		p_rec.u.r = r_value
		p_rec.flags |= 8
		if b_try_for_int {
			sqlite3_vdbe_integer_affinity(p_rec)
		}
	}
	p_rec.flags &= ~2
}

@[c:'applyAffinity']
fn apply_affinity(p_rec &Mem, affinity i8, enc U8) {
	if int(affinity) >= 67 {
		if (int(p_rec.flags) & 4) == 0 {
			if (int(p_rec.flags) & (8 | 32)) == 0 {
				if int(p_rec.flags) & 2 {
					apply_numeric_affinity(p_rec, 1)
				}
			} else if int(affinity) <= 69 {
				sqlite3_vdbe_integer_affinity(p_rec)
			}
		}
	} else if int(affinity) == 66 {
		if 0 == (int(p_rec.flags) & 2) {
			if (int(p_rec.flags) & (8 | 4 | 32)) {
				sqlite3_vdbe_mem_stringify(p_rec, enc, U8(1))
			}
		}
		p_rec.flags &= ~(8 | 4 | 32)
	}
}

fn sqlite3_value_numeric_type(p_val &Sqlite3_value) int {
	c2v_gc_register_thread()
	e_type := sqlite3_value_type(p_val)
	if e_type == 3 {
		p_mem := &Mem(p_val)
		sqlite3_mutex_enter(p_mem.db.mutex)
		apply_numeric_affinity(p_mem, 0)
		sqlite3_mutex_leave(p_mem.db.mutex)
		e_type = sqlite3_value_type(p_val)
	}
	return e_type
}

@[c:'sqlite3ValueApplyAffinity']
fn sqlite3_value_apply_affinity(p_val &Sqlite3_value, affinity U8, enc U8) {
	apply_affinity(&Mem(p_val), i8(affinity), enc)
}

@[c:'computeNumericType']
fn compute_numeric_type(p_mem &Mem) U16 {
	rc := 0
	ix := Sqlite3_int64(0)
	if (if (int(p_mem.flags) & 1024) { sqlite3_vdbe_mem_expand_blob(p_mem) } else { 0 }) {
		p_mem.u.i = I64(0)
		return U16(4)
	}
	rc = sqlite3_mem_real_value_rc(p_mem, &p_mem.u.r)
	if rc <= 0 {
		if (rc & 2) == 0 && sqlite3_atoi64(p_mem.z, unsafe { &I64(&ix) }, p_mem.n, p_mem.enc) <= 1 {
			p_mem.u.i = ix
			return U16(4)
		} else {
			return U16(8)
		}
	} else if (rc & 2) == 0 && sqlite3_atoi64(p_mem.z, unsafe { &I64(&ix) }, p_mem.n, p_mem.enc) == 0 {
		p_mem.u.i = ix
		return U16(4)
	}
	return U16(8)
}

@[c:'numericType']
fn numeric_type(p_mem &Mem) U16 {
	if int(p_mem.flags) & (4 | 8 | 32 | 1) {
		return U16(int(p_mem.flags) & (4 | 8 | 32 | 1))
	}
	return compute_numeric_type(p_mem)
	return U16(0)
}

@[c:'out2PrereleaseWithClear']
fn out2_prerelease_with_clear(p_out &Mem) &Mem {
	sqlite3_vdbe_mem_set_null(p_out)
	p_out.flags = U16(4)
	return p_out
}

@[c:'out2Prerelease']
fn out2_prerelease(p &Vdbe, p_op &VdbeOp) &Mem {
	p_out := &Mem(0)
	p_out = unsafe { p.aMem + p_op.p2 }
	if ((int(p_out.flags) & (32768 | 4096)) != 0) {
		return out2_prerelease_with_clear(p_out)
	} else {
		p_out.flags = U16(4)
		return p_out
	}
}

@[c:'filterHash']
fn filter_hash(a_mem &Mem, p_op &Op) U64 {
	i := 0
	mx := 0

	h := U64(0)
	i = p_op.p3
	for mx = i + p_op.p4.i; i < mx; i++ {
		p := unsafe { a_mem + i }
		if int(p.flags) & (4 | 32) {
			h += U64(p.u.i)
		} else if int(p.flags) & 8 {
			h += U64(sqlite3_vdbe_int_value(p))
		} else if int(p.flags) & (2 | 16) {
			h += U64(4093 + (int(p.flags) & (2 | 16)))
		}
	}
	return h
}

@[c:'vdbeColumnFromOverflow']
fn vdbe_column_from_overflow(pc &VdbeCursor, i_col int, t u32, i_offset I64, cache_status u32, col_cache_ctr u32, p_dest &Mem) int {
	rc := 0
	db := p_dest.db
	encoding := int(p_dest.enc)
	len := int(sqlite3_vdbe_serial_type_len(t))
	if len > db.aLimit[0] {
		return 18
	}
	if len > 4000 && usize(pc.pKeyInfo) == usize(0) {
		p_cache := &VdbeTxtBlbCache(0)
		p_buf := &i8(0)
		if int(pc.colCache) == 0 {
			pc.pCache = sqlite3_db_malloc_zero(db, U64(sizeof(VdbeTxtBlbCache)))
			if usize(pc.pCache) == usize(0) {
				return 7
			}
			pc.colCache = bool(1)
		}
		p_cache = pc.pCache
		mut __c2v_condition_42 := false
		mut __c2v_condition_43 := false
		__c2v_condition_43 = usize(p_cache.pCValue) == usize(0)
		__c2v_condition_42 = __c2v_condition_43
		if !__c2v_condition_42 {
			mut __c2v_condition_44 := false
			__c2v_condition_44 = p_cache.iCol != i_col
			__c2v_condition_42 = __c2v_condition_44
		}
		if !__c2v_condition_42 {
			mut __c2v_condition_45 := false
			__c2v_condition_45 = p_cache.cacheStatus != cache_status
			__c2v_condition_42 = __c2v_condition_45
		}
		if !__c2v_condition_42 {
			mut __c2v_condition_46 := false
			__c2v_condition_46 = p_cache.colCacheCtr != col_cache_ctr
			__c2v_condition_42 = __c2v_condition_46
		}
		if !__c2v_condition_42 {
			mut __c2v_condition_47 := false
			__c2v_condition_47 = p_cache.iOffset != sqlite3_btree_offset(pc.uc.pCursor)
			__c2v_condition_42 = __c2v_condition_47
		}
		if __c2v_condition_42 {
			if p_cache.pCValue {
				sqlite3_rc_str_unref(voidptr(p_cache.pCValue))
			}
			p_cache.pCValue = sqlite3_rc_str_new(U64(len + 3))
			p_buf = p_cache.pCValue
			if usize(p_buf) == usize(0) {
				return 7
			}
			rc = sqlite3_btree_payload(pc.uc.pCursor, u32(i_offset), u32(len), voidptr(p_buf))
			if rc {
				return rc
			}
			p_buf[len] = i8(0)
			p_buf[len + 1] = i8(0)
			p_buf[len + 2] = i8(0)
			p_cache.iCol = i_col
			p_cache.cacheStatus = cache_status
			p_cache.colCacheCtr = col_cache_ctr
			p_cache.iOffset = sqlite3_btree_offset(pc.uc.pCursor)
		} else {
			p_buf = p_cache.pCValue
		}
		sqlite3_rc_str_ref(p_buf)
		if t & u32(1) {
			rc = sqlite3_vdbe_mem_set_str(p_dest, p_buf, I64(len), U8(encoding), sqlite3_rc_str_unref)
			p_dest.flags |= 512
		} else {
			rc = sqlite3_vdbe_mem_set_str(p_dest, p_buf, I64(len), U8(0), sqlite3_rc_str_unref)
		}
	} else {
		rc = sqlite3_vdbe_mem_from_btree(pc.uc.pCursor, u32(i_offset), u32(len), p_dest)
		if rc {
			return rc
		}
		sqlite3_vdbe_serial_get(&U8(voidptr(p_dest.z)), t, p_dest)
		if (t & u32(1)) != u32(0) && encoding == 1 {
			p_dest.z[len] = i8(0)
			p_dest.flags |= 512
		}
	}
	p_dest.flags &= ~16384
	return rc
}

@[c:'sqlite3VdbeLogAbort']
fn sqlite3_vdbe_log_abort(p &Vdbe, rc int, p_op &Op, a_op &Op) {
	z_sql := p.zSql
	z_prefix := c''
	pc := 0
	z_xtra := [100]i8{}
	if p.pFrame {
		if usize(a_op[0].p4.z) != usize(0) {
			sqlite3_snprintf(int(sizeof([100]i8)), unsafe { &i8(&z_xtra[0]) }, c'/* %s */ ', voidptr(a_op[0].p4.z + 3))
			z_prefix = unsafe { &z_xtra[0] }
		} else {
			z_prefix = c'/* unknown trigger */ '
		}
	}
	pc = int((i64((isize(p_op) - isize(a_op)) / isize(sizeof(Op)))))
	sqlite3_log(rc, c'statement aborts at %d: %s; [%s%s]', pc, voidptr(p.zErrMsg), voidptr(z_prefix), voidptr(z_sql))
}

@[c:'vdbeMemTypeName']
fn vdbe_mem_type_name(p_mem &Mem) &i8 {
	if !vdbe_mem_type_name_az_types_inited {
		c2v_static_init := [c'INT', c'REAL', c'TEXT', c'BLOB', c'NULL']
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			vdbe_mem_type_name_az_types[c2v_i_0] = c2v_element_0
		}
		vdbe_mem_type_name_az_types_inited = true
	}

	return vdbe_mem_type_name_az_types[sqlite3_value_type(unsafe { &Sqlite3_value(p_mem) }) - 1]
}

@[c:'sqlite3VdbeExec']
fn sqlite3_vdbe_exec(p &Vdbe) int {
	a_op := p.aOp
	p_op := a_op
	rc := 0
	db := p.db
	reset_schema_on_fault := U8(0)
	encoding := db.enc
	i_compare := 0
	n_vm_step := U64(0)
	n_progress_limit := U64(0)
	mut a_mem := p.aMem
	p_in1 := unsafe { &Mem(nil) }
	p_in2 := unsafe { &Mem(nil) }
	p_in3 := unsafe { &Mem(nil) }
	p_out := unsafe { &Mem(nil) }
	col_cache_ctr := u32(0)
	if (p.lockMask != YDbMask(0)) {
		sqlite3_vdbe_enter(p)
	}
	if db.xProgress {
		i_prior := p.aCounter[4]
		n_progress_limit = U64(db.nProgressOps - (i_prior % db.nProgressOps))
	} else {
		n_progress_limit = (U64(u32(4294967295)) | ((U64(u32(4294967295))) << 32))
	}
	if p.rc == 7 {
		unsafe { goto no_mem
		 }
	}
	p.rc = 0
	p.iCurrentTime = I64(0)
	db.busyHandler.nBusy = 0
	if C.c2v_atomic_load_n__int_int_int((&db.u1.isInterrupted), 0) {
		unsafe { goto abort_due_to_interrupt
		 }
	}
	for p_op = unsafe { a_op + p.pc }; 1; p_op = unsafe { p_op + 1 } {
		n_vm_step++
		n_field := 0
		p_key_info := &KeyInfo(0)
		p2 := u32(0)
		i_db := 0
		wr_flag := 0
		px := &Btree(0)
		p_cur := &VdbeCursor(0)
		p_db := &Db(0)
		pc := &VdbeCursor(0)
		p_crsr := &BtCursor(0)
		res := 0
		i_key := U64(0)
		pc_2 := &VdbeCursor(0)
		match p_op.opcode {
			9 {
				jump_to_p2_and_check_for_interrupt:
				p_op = unsafe { a_op + (p_op.p2 - 1) }
				check_for_interrupt:
				if C.c2v_atomic_load_n__int_int_int((&db.u1.isInterrupted), 0) {
					unsafe { goto abort_due_to_interrupt
					 }
				}
				for n_vm_step >= n_progress_limit && !isnil(db.xProgress) {
					n_progress_limit += U64(db.nProgressOps)
					if db.xProgress(voidptr(db.pProgressArg)) {
						n_progress_limit = (U64(u32(4294967295)) | ((U64(u32(4294967295))) << 32))
						rc = 9
						unsafe { goto abort_due_to_error
						 }
					}
				}
			}
			10 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_in1.flags = U16(4)
				p_in1.u.i = I64(int((i64((isize(p_op) - isize(a_op)) / isize(sizeof(Op))))))
				unsafe { goto jump_to_p2_and_check_for_interrupt
				 }
			}
			69 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				if int(p_in1.flags) & 4 {
					if p_op.p3 {
					}
					p_op = unsafe { a_op + p_in1.u.i }
				} else if p_op.p3 {
				}
			}
			11 {
				p_out = unsafe { a_mem + p_op.p1 }
				p_out.u.i = I64(p_op.p3 - 1)
				p_out.flags = U16(4)
				if p_op.p2 == 0 {
					unsafe { goto c2v_switch_end_23
					 }
				}
				jump_to_p2:
				p_op = unsafe { a_op + (p_op.p2 - 1) }
			}
			70 {
				p_caller := &VdbeOp(0)
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_caller = unsafe { a_op + p_in1.u.i }
				p_in1.u.i = I64(int((i64((isize(p_op) - isize(p.aOp)) / isize(sizeof(Op))))) - 1)
				p_op = unsafe { a_op + (p_caller.p2 - 1) }
			}
			12 {
				pc_dest := 0
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_in1.flags = U16(4)
				pc_dest = int(p_in1.u.i)
				p_in1.u.i = I64(int((i64((isize(p_op) - isize(a_op)) / isize(sizeof(Op))))))
				p_op = unsafe { a_op + pc_dest }
			}
			71 {
				p_in3 = unsafe { a_mem + p_op.p3 }
				if (int(p_in3.flags) & 1) == 0 {
					unsafe { goto c2v_switch_end_23
					 }
				}

				unsafe { goto c2v_case_23_7
				 }
			}
			72 {
				c2v_case_23_7:
				p_frame := &VdbeFrame(0)
				pcx := 0
				if !isnil(p.pFrame) && p_op.p1 == 0 {
					p_frame = p.pFrame
					p.pFrame = p_frame.pParent
					p.nFrame--
					sqlite3_vdbe_set_changes(db, p.nChange)
					pcx = sqlite3_vdbe_frame_restore(p_frame)
					if p_op.p2 == 4 {
						pcx = p.aOp[pcx].p2 - 1
					}
					a_op = p.aOp
					a_mem = p.aMem
					p_op = unsafe { a_op + pcx }
					unsafe { goto c2v_switch_end_23
					 }
				}
				p.rc = p_op.p1
				p.errorAction = U8(p_op.p2)
				if p.rc {
					if p_op.p3 > 0 && int(p_op.p4type) == 0 {
						z_err := &i8(0)
						z_err = &i8(sqlite3_value_text_vdup5(unsafe { &Sqlite3_value(a_mem + p_op.p3) }, U8(1)))
						sqlite3_vdbe_error(p, c'%s', voidptr(z_err))
					} else if p_op.p5 {
						if !sqlite3_vdbe_exec_az_type_inited {
							c2v_static_init := [c'NOT NULL', c'UNIQUE', c'CHECK', c'FOREIGN KEY']
							for c2v_i_0, c2v_element_0 in c2v_static_init {
								sqlite3_vdbe_exec_az_type[c2v_i_0] = c2v_element_0
							}
							sqlite3_vdbe_exec_az_type_inited = true
						}

						sqlite3_vdbe_error(p, c'%s constraint failed', voidptr(sqlite3_vdbe_exec_az_type[int(p_op.p5) - 1]))
						if p_op.p4.z {
							p.zErrMsg = sqlite3_mp_rintf(db, c'%z: %s', voidptr(p.zErrMsg), voidptr(p_op.p4.z))
						}
					} else {
						sqlite3_vdbe_error(p, c'%s', voidptr(p_op.p4.z))
					}
					sqlite3_vdbe_log_abort(p, p_op.p1, p_op, a_op)
				}
				rc = sqlite3_vdbe_halt(p)
				if rc == 5 {
					p.rc = 5
				} else {
					rc = if p.rc { 1 } else { 101 }
				}
				unsafe { goto vdbe_return
				 }
			}
			73 {
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				p_out.u.i = I64(p_op.p1)
			}
			74 {
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				p_out.u.i = unsafe { *p_op.p4.pI64 }
			}
			154 {
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				p_out.flags = U16(8)
				p_out.u.r = unsafe { *p_op.p4.pReal }
			}
			118 {
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				p_op.p1 = sqlite3_strlen30(p_op.p4.z)
				if int(encoding) != 1 {
					rc = sqlite3_vdbe_mem_set_str(p_out, p_op.p4.z, I64(-1), U8(1), (C2vFn_666e2028766f696470747229(voidptr(0))))
					if rc {
						unsafe { goto too_big
						 }
					}
					if 0 != sqlite3_vdbe_change_encoding(p_out, int(encoding)) {
						unsafe { goto no_mem
						 }
					}
					p_out.szMalloc = 0
					p_out.flags |= 8192
					if int(p_op.p4type) == (-7) {
						sqlite3_db_free(db, voidptr(p_op.p4.z))
					}
					p_op.p4type = i8((-7))
					p_op.p4.z = p_out.z
					p_op.p1 = p_out.n
				}
				if p_op.p1 > db.aLimit[0] {
					unsafe { goto too_big
					 }
				}
				p_op.opcode = U8(75)

				unsafe { goto c2v_case_23_12
				 }
			}
			75 {
				c2v_case_23_12:
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				p_out.flags = U16(2 | 8192 | 512)
				p_out.z = p_op.p4.z
				p_out.n = p_op.p1
				p_out.enc = encoding
				if p_op.p3 > 0 {
					p_in3 = unsafe { a_mem + p_op.p3 }
					if p_in3.u.i == I64(p_op.p5) {
						p_out.flags = U16(16 | 8192 | 512)
					}
				}
			}
			76, 77 {
				cnt := 0
				null_flag := U16(0)
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				cnt = p_op.p3 - p_op.p2
				null_flag = U16(if p_op.p1 { (1 | 256) } else { 1 })
				p_out.flags = null_flag
				p_out.n = 0
				for cnt > 0 {
					c2v_pointer_postfix(voidptr(&p_out), p_out, isize(1))
					sqlite3_vdbe_mem_set_null(p_out)
					p_out.flags = null_flag
					p_out.n = 0
					cnt--
				}
			}
			78 {
				p_out = unsafe { a_mem + p_op.p1 }
				p_out.flags = U16((int(p_out.flags) & ~(0 | 63)) | 1)
			}
			79 {
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				if usize(p_op.p4.z) == usize(0) {
					sqlite3_vdbe_mem_set_zero_blob(p_out, p_op.p1)
					if sqlite3_vdbe_mem_expand_blob(p_out) {
						unsafe { goto no_mem
						 }
					}
				} else {
					sqlite3_vdbe_mem_set_str(p_out, p_op.p4.z, I64(p_op.p1), U8(0), unsafe { nil })
				}
				p_out.enc = encoding
			}
			80 {
				p_var := &Mem(0)
				p_var = unsafe { p.aVar + (p_op.p1 - 1) }
				if sqlite3_vdbe_mem_too_big(p_var) {
					unsafe { goto too_big
					 }
				}
				p_out = unsafe { a_mem + p_op.p2 }
				if ((int(p_out.flags) & (32768 | 4096)) != 0) {
					sqlite3_vdbe_mem_set_null(p_out)
				}
				C.memcpy(voidptr(p_out), voidptr(p_var), (u64(usize(__offsetof(Mem, db)))))
				p_out.flags &= ~(4096 | 16384)
				p_out.flags |= 8192 | 64
			}
			81 {
				n := 0
				p1 := 0
				p2_2 := 0
				n = p_op.p3
				p1 = p_op.p1
				p2_2 = p_op.p2
				p_in1 = unsafe { a_mem + p1 }
				p_out = unsafe { a_mem + p2_2 }
				for {
					sqlite3_vdbe_mem_move(p_out, p_in1)
					if (int(p_out.flags) & 16384) != 0 && sqlite3_vdbe_mem_make_writeable(p_out) {
						unsafe { goto no_mem
						 }
					}
					c2v_pointer_postfix(voidptr(&p_in1), p_in1, isize(1))
					c2v_pointer_postfix(voidptr(&p_out), p_out, isize(1))
					n--
					if !n {
						break
					}
				}
			}
			82 {
				n := 0
				n = p_op.p3
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_out = unsafe { a_mem + p_op.p2 }
				for {
					sqlite3_vdbe_mem_shallow_copy(p_out, p_in1, 16384)
					if (int(p_out.flags) & 16384) != 0 && sqlite3_vdbe_mem_make_writeable(p_out) {
						unsafe { goto no_mem
						 }
					}
					if (int(p_out.flags) & 2048) != 0 && (int(p_op.p5) & 2) != 0 {
						p_out.flags &= ~2048
					}
					if (n--) == 0 {
						break
					}
					c2v_pointer_postfix(voidptr(&p_out), p_out, isize(1))
					c2v_pointer_postfix(voidptr(&p_in1), p_in1, isize(1))
				}
			}
			83 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_out = unsafe { a_mem + p_op.p2 }
				sqlite3_vdbe_mem_shallow_copy(p_out, p_in1, 16384)
			}
			84 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_out = unsafe { a_mem + p_op.p2 }
				sqlite3_vdbe_mem_set_int64(p_out, p_in1.u.i)
			}
			85 {
				rc = sqlite3_vdbe_check_fk_immediate(p)
				if rc != 0 {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			86 {
				p.cacheCtr = (p.cacheCtr + u32(2)) | u32(1)
				p.pResultRow = unsafe { a_mem + p_op.p1 }
				if db.mallocFailed {
					unsafe { goto no_mem
					 }
				}
				if int(db.mTrace) & 4 {
					db.trace.xV2(u32(4), voidptr(db.pTraceArg), voidptr(p), unsafe { nil })
				}
				p.pc = int((i64((isize(p_op) - isize(a_op)) / isize(sizeof(Op))))) + 1
				rc = 100
				unsafe { goto vdbe_return
				 }
			}
			112 {
				n_byte := I64(0)
				flags1 := U16(0)
				flags2 := U16(0)
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_in2 = unsafe { a_mem + p_op.p2 }
				p_out = unsafe { a_mem + p_op.p3 }
				flags1 = p_in1.flags
				if (int(flags1) | int(p_in2.flags)) & 1 {
					sqlite3_vdbe_mem_set_null(p_out)
					unsafe { goto c2v_switch_end_23
					 }
				}
				if (int(flags1) & (2 | 16)) == 0 {
					if sqlite3_vdbe_mem_stringify(p_in1, encoding, U8(0)) {
						unsafe { goto no_mem
						 }
					}
					flags1 = U16(int(p_in1.flags) & ~2)
				} else if (int(flags1) & 1024) != 0 {
					if sqlite3_vdbe_mem_expand_blob(p_in1) {
						unsafe { goto no_mem
						 }
					}
					flags1 = U16(int(p_in1.flags) & ~2)
				}
				flags2 = p_in2.flags
				if (int(flags2) & (2 | 16)) == 0 {
					if sqlite3_vdbe_mem_stringify(p_in2, encoding, U8(0)) {
						unsafe { goto no_mem
						 }
					}
					flags2 = U16(int(p_in2.flags) & ~2)
				} else if (int(flags2) & 1024) != 0 {
					if sqlite3_vdbe_mem_expand_blob(p_in2) {
						unsafe { goto no_mem
						 }
					}
					flags2 = U16(int(p_in2.flags) & ~2)
				}
				n_byte = I64(p_in1.n)
				n_byte += I64(p_in2.n)
				if n_byte > I64(db.aLimit[0]) {
					unsafe { goto too_big
					 }
				}
				if sqlite3_vdbe_mem_grow(p_out, int(n_byte) + 2, usize(p_out) == usize(p_in2)) {
					unsafe { goto no_mem
					 }
				}
				p_out.flags = U16((int(p_out.flags) & ~(3519 | 1024)) | 2)
				if usize(p_out) != usize(p_in2) {
					C.memcpy(voidptr(p_out.z), voidptr(p_in2.z), u64(p_in2.n))
					p_in2.flags = flags2
				}
				C.memcpy(voidptr(unsafe { p_out.z + p_in2.n }), voidptr(p_in1.z), u64(p_in1.n))
				p_in1.flags = flags1
				if int(encoding) > 1 {
					n_byte &= I64(~1)
				}
				p_out.z[n_byte] = i8(0)
				p_out.z[n_byte + I64(1)] = i8(0)
				p_out.flags |= 512
				p_out.n = int(n_byte)
				p_out.enc = encoding
			}
			107, 108, 109, 110, 111 {
				type1 := U16(0)
				type2 := U16(0)
				ia := I64(0)
				ib := I64(0)
				ra := 0.0
				rb := 0.0
				p_in1 = unsafe { a_mem + p_op.p1 }
				type1 = p_in1.flags
				p_in2 = unsafe { a_mem + p_op.p2 }
				type2 = p_in2.flags
				p_out = unsafe { a_mem + p_op.p3 }
				if (int(type1) & int(type2) & 4) != 0 {
					int_math:
					ia = p_in1.u.i
					ib = p_in2.u.i
					match p_op.opcode {
						107 {
							if sqlite3_add_int64(&ib, ia) {
								unsafe { goto fp_math
								 }
							}
						}
						108 {
							if sqlite3_sub_int64(&ib, ia) {
								unsafe { goto fp_math
								 }
							}
						}
						109 {
							if sqlite3_mul_int64(&ib, ia) {
								unsafe { goto fp_math
								 }
							}
						}
						110 {
							if ia == I64(0) {
								unsafe { goto arithmetic_result_is_null
								 }
							}
							if ia == I64(-1) && ib == ((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32))) {
								unsafe { goto fp_math
								 }
							}
							ib /= ia
						}
						else {
							if ia == I64(0) {
								unsafe { goto arithmetic_result_is_null
								 }
							}
							if ia == I64(-1) {
								ia = I64(1)
							}
							ib %= ia
						}
					}

					p_out.u.i = ib
					p_out.flags = U16((int(p_out.flags) & ~(3519 | 1024)) | 4)
				} else if ((int(type1) | int(type2)) & 1) != 0 {
					unsafe { goto arithmetic_result_is_null
					 }
				} else {
					type1 = numeric_type(p_in1)
					type2 = numeric_type(p_in2)
					if (int(type1) & int(type2) & 4) != 0 {
						unsafe { goto int_math
						 }
					}
					fp_math:
					ra = sqlite3_vdbe_real_value(p_in1)
					rb = sqlite3_vdbe_real_value(p_in2)
					match p_op.opcode {
						107 {
							rb += ra
						}
						108 {
							rb -= ra
						}
						109 {
							rb *= ra
						}
						110 {
							if ra == f64(0) {
								unsafe { goto arithmetic_result_is_null
								 }
							}
							rb /= ra
						}
						else {
							ia = sqlite3_vdbe_int_value(p_in1)
							ib = sqlite3_vdbe_int_value(p_in2)
							if ia == I64(0) {
								unsafe { goto arithmetic_result_is_null
								 }
							}
							if ia == I64(-1) {
								ia = I64(1)
							}
							rb = f64((ib % ia))
						}
					}

					if sqlite3_is_na_n(rb) {
						unsafe { goto arithmetic_result_is_null
						 }
					}
					p_out.u.r = rb
					p_out.flags = U16((int(p_out.flags) & ~(3519 | 1024)) | 8)
				}
				unsafe { goto c2v_switch_end_23
				 }

				arithmetic_result_is_null:
				sqlite3_vdbe_mem_set_null(p_out)
			}
			87 {
				if p_op.p1 {
					sqlite3_vdbe_mem_set_int64(unsafe { a_mem + p_op.p1 }, I64(0))
				}
			}
			103, 104, 105, 106 {
				ia_2 := I64(0)
				ua := U64(0)
				ib_2 := I64(0)
				op := U8(0)
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_in2 = unsafe { a_mem + p_op.p2 }
				p_out = unsafe { a_mem + p_op.p3 }
				if (int(p_in1.flags) | int(p_in2.flags)) & 1 {
					sqlite3_vdbe_mem_set_null(p_out)
					unsafe { goto c2v_switch_end_23
					 }
				}
				ia_2 = sqlite3_vdbe_int_value(p_in2)
				ib_2 = sqlite3_vdbe_int_value(p_in1)
				op = p_op.opcode
				if int(op) == 103 {
					ia_2 &= ib_2
				} else if int(op) == 104 {
					ia_2 |= ib_2
				} else if ib_2 != I64(0) {
					if ib_2 < I64(0) {
						op = U8(2 * 105 + 1 - int(op))
						ib_2 = if ib_2 > I64((-64)) { -ib_2 } else { I64(64) }
					}
					if ib_2 >= I64(64) {
						ia_2 = I64(if (ia_2 >= I64(0) || int(op) == 105) { 0 } else { -1 })
					} else {
						C.memcpy(voidptr(&ua), voidptr(&ia_2), sizeof(ua))
						if int(op) == 105 {
							ua <<= ib_2
						} else {
							ua >>= ib_2
							if ia_2 < I64(0) {
								ua |= (((U64(u32(4294967295))) << 32) | U64(u32(4294967295))) << i64((I64(64) - ib_2))
							}
						}
						C.memcpy(voidptr(&ia_2), voidptr(&ua), sizeof(ia_2))
					}
				}
				p_out.u.i = ia_2
				p_out.flags = U16((int(p_out.flags) & ~(3519 | 1024)) | 4)
			}
			88 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				sqlite3_vdbe_mem_integerify(p_in1)
				mut __c2v_lhs_tmp_83 := unsafe { &U64(voidptr(&p_in1.u.i)) }
				unsafe { *__c2v_lhs_tmp_83 += U64(p_op.p2) }
			}
			13 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				if (int(p_in1.flags) & 4) == 0 {
					apply_affinity(p_in1, i8(67), encoding)
					if (int(p_in1.flags) & 4) == 0 {
						if p_op.p2 == 0 {
							rc = 20
							unsafe { goto abort_due_to_error
							 }
						} else {
							unsafe { goto jump_to_p2
							 }
						}
					}
				}
				p_in1.flags = U16((int(p_in1.flags) & ~(3519 | 1024)) | 4)
			}
			89 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				if int(p_in1.flags) & (4 | 32) {
					sqlite3_vdbe_mem_realify(p_in1)
				}
			}
			90 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				rc = (if (int(p_in1.flags) & 1024) { sqlite3_vdbe_mem_expand_blob(p_in1) } else { 0 })
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				rc = sqlite3_vdbe_mem_cast(p_in1, U8(p_op.p2), encoding)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			54, 53, 57, 56, 55, 58 {
				res_2 := 0
				res2 := 0

				affinity := i8(0)
				flags1 := U16(0)
				flags3 := U16(0)
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_in3 = unsafe { a_mem + p_op.p3 }
				flags1 = p_in1.flags
				flags3 = p_in3.flags
				if (int(flags1) & int(flags3) & 4) != 0 {
					if p_in3.u.i > p_in1.u.i {
						if sqlite3aGTb[p_op.opcode] {
							unsafe { goto jump_to_p2
							 }
						}
						i_compare = 1
					} else if p_in3.u.i < p_in1.u.i {
						if sqlite3aLTb[p_op.opcode] {
							unsafe { goto jump_to_p2
							 }
						}
						i_compare = -1
					} else {
						if sqlite3aEQb[p_op.opcode] {
							unsafe { goto jump_to_p2
							 }
						}
						i_compare = 0
					}
					unsafe { goto c2v_switch_end_23
					 }
				}
				if (int(flags1) | int(flags3)) & 1 {
					if int(p_op.p5) & 128 {
						if (int(flags1) & int(flags3) & 1) != 0 && (int(flags3) & 256) == 0 {
							res_2 = 0
						} else {
							res_2 = (if (int(flags3) & 1) { -1 } else { 1 })
						}
					} else {
						if int(p_op.p5) & 16 {
							unsafe { goto jump_to_p2
							 }
						}
						i_compare = 1
						unsafe { goto c2v_switch_end_23
						 }
					}
				} else {
					affinity = i8(int(p_op.p5) & 71)
					if int(affinity) >= 67 {
						if (int(flags1) | int(flags3)) & 2 {
							if (int(flags1) & (4 | 32 | 8 | 2)) == 2 {
								apply_numeric_affinity(p_in1, 0)
								flags3 = p_in3.flags
							}
							if (int(flags3) & (4 | 32 | 8 | 2)) == 2 {
								apply_numeric_affinity(p_in3, 0)
							}
						}
					} else if int(affinity) == 66 && ((int(flags1) | int(flags3)) & 2) != 0 {
						if (int(flags1) & 2) != 0 {
							p_in1.flags &= ~(4 | 8 | 32)
						} else if (int(flags1) & (4 | 8 | 32)) != 0 {
							sqlite3_vdbe_mem_stringify(p_in1, encoding, U8(1))
							flags1 = U16((int(p_in1.flags) & ~3519) | (int(flags1) & 3519))
							if (usize(p_in1) == usize(p_in3)) {
								flags3 = U16(int(flags1) | 2)
							}
						}
						if (int(flags3) & 2) != 0 {
							p_in3.flags &= ~(4 | 8 | 32)
						} else if (int(flags3) & (4 | 8 | 32)) != 0 {
							sqlite3_vdbe_mem_stringify(p_in3, encoding, U8(1))
							flags3 = U16((int(p_in3.flags) & ~3519) | (int(flags3) & 3519))
						}
					}
					res_2 = sqlite3_mem_compare(p_in3, p_in1, p_op.p4.pColl)
				}
				if res_2 < 0 {
					res2 = int(sqlite3aLTb[p_op.opcode])
				} else if res_2 == 0 {
					res2 = int(sqlite3aEQb[p_op.opcode])
				} else {
					res2 = int(sqlite3aGTb[p_op.opcode])
				}
				i_compare = res_2
				p_in3.flags = flags3
				p_in1.flags = flags1
				if res2 {
					unsafe { goto jump_to_p2
					 }
				}
			}
			59 {
				if i_compare == 0 {
					unsafe { goto jump_to_p2
					 }
				}
			}
			91 {
			}
			92 {
				n := 0
				i := 0
				p1 := 0
				p2_2 := 0
				p_key_info_2 := &KeyInfo(0)
				idx := u32(0)
				p_coll := &CollSeq(0)
				b_rev := 0
				a_permute := &u32(0)
				if (int(p_op.p5) & 1) == 0 {
					a_permute = 0
				} else {
					a_permute = p_op[-1].p4.ai + 1
				}
				n = p_op.p3
				p_key_info_2 = p_op.p4.pKeyInfo
				p1 = p_op.p1
				p2_2 = p_op.p2
				for i = 0; i < n; i++ {
					idx = if a_permute { a_permute[i] } else { u32(i) }
					p_coll = (&p_key_info_2.aColl[0])[i]
					b_rev = (int(p_key_info_2.aSortFlags[i]) & 1)
					i_compare = sqlite3_mem_compare(unsafe { a_mem + (u32(p1) + idx) }, unsafe { a_mem + (u32(p2_2) + idx) }, p_coll)
					if i_compare {
						if (int(p_key_info_2.aSortFlags[i]) & 2) && ((int(a_mem[u32(p1) + idx].flags) & 1) || (int(a_mem[u32(p2_2) + idx].flags) & 1)) {
							i_compare = -i_compare
						}
						if b_rev {
							i_compare = -i_compare
						}
						break
					}
				}
			}
			14 {
				if i_compare < 0 {
					p_op = unsafe { a_op + (p_op.p1 - 1) }
				} else if i_compare == 0 {
					p_op = unsafe { a_op + (p_op.p2 - 1) }
				} else {
					p_op = unsafe { a_op + (p_op.p3 - 1) }
				}
			}
			44, 43 {
				v1 := 0
				v2 := 0
				v1 = sqlite3_vdbe_boolean_value(unsafe { a_mem + p_op.p1 }, 2)
				v2 = sqlite3_vdbe_boolean_value(unsafe { a_mem + p_op.p2 }, 2)
				if int(p_op.opcode) == 44 {
					if !sqlite3_vdbe_exec_and_logic_inited {
						c2v_static_init := [u8(0), u8(0), u8(0), u8(0), u8(1), u8(2), u8(0), u8(2),
							u8(2)]
						for c2v_i_0, c2v_element_0 in c2v_static_init {
							sqlite3_vdbe_exec_and_logic[c2v_i_0] = c2v_element_0
						}
						sqlite3_vdbe_exec_and_logic_inited = true
					}

					v1 = int(sqlite3_vdbe_exec_and_logic[v1 * 3 + v2])
				} else {
					if !sqlite3_vdbe_exec_or_logic_inited {
						c2v_static_init := [u8(0), u8(1), u8(2), u8(1), u8(1), u8(1), u8(2), u8(1),
							u8(2)]
						for c2v_i_0, c2v_element_0 in c2v_static_init {
							sqlite3_vdbe_exec_or_logic[c2v_i_0] = c2v_element_0
						}
						sqlite3_vdbe_exec_or_logic_inited = true
					}

					v1 = int(sqlite3_vdbe_exec_or_logic[v1 * 3 + v2])
				}
				p_out = unsafe { a_mem + p_op.p3 }
				if v1 == 2 {
					p_out.flags = U16((int(p_out.flags) & ~(3519 | 1024)) | 1)
				} else {
					p_out.u.i = I64(v1)
					p_out.flags = U16((int(p_out.flags) & ~(3519 | 1024)) | 4)
				}
			}
			93 {
				sqlite3_vdbe_mem_set_int64(unsafe { a_mem + p_op.p2 }, I64(sqlite3_vdbe_boolean_value(unsafe { a_mem + p_op.p1 }, p_op.p3) ^ p_op.p4.i))
			}
			19 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_out = unsafe { a_mem + p_op.p2 }
				if (int(p_in1.flags) & 1) == 0 {
					sqlite3_vdbe_mem_set_int64(p_out, I64(!sqlite3_vdbe_boolean_value(p_in1, 0)))
				} else {
					sqlite3_vdbe_mem_set_null(p_out)
				}
			}
			115 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_out = unsafe { a_mem + p_op.p2 }
				sqlite3_vdbe_mem_set_null(p_out)
				if (int(p_in1.flags) & 1) == 0 {
					p_out.flags = U16(4)
					p_out.u.i = ~sqlite3_vdbe_int_value(p_in1)
				}
			}
			15 {
				i_addr := u32(0)
				if p.pFrame {
					i_addr = u32(int((i64((isize(p_op) - isize(p.aOp)) / isize(sizeof(Op))))))
					if (int(p.pFrame.aOnce[i_addr / u32(8)]) & (1 << (i_addr & u32(7)))) != 0 {
						unsafe { goto jump_to_p2
						 }
					}
					p.pFrame.aOnce[i_addr / u32(8)] |= 1 << (i_addr & u32(7))
				} else {
					if p.aOp[0].p1 == p_op.p1 {
						unsafe { goto jump_to_p2
						 }
					}
				}
				p_op.p1 = p.aOp[0].p1
			}
			16 {
				c := 0
				c = sqlite3_vdbe_boolean_value(unsafe { a_mem + p_op.p1 }, p_op.p3)
				if c {
					unsafe { goto jump_to_p2
					 }
				}
			}
			17 {
				c := 0
				c = !sqlite3_vdbe_boolean_value(unsafe { a_mem + p_op.p1 }, !p_op.p3)
				if c {
					unsafe { goto jump_to_p2
					 }
				}
			}
			51 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				if (int(p_in1.flags) & 1) != 0 {
					unsafe { goto jump_to_p2
					 }
				}
			}
			18 {
				pc_3 := &VdbeCursor(0)
				type_mask := U16(0)
				serial_type := u32(0)
				if p_op.p1 >= 0 {
					pc_3 = p.apCsr[p_op.p1]
					if p_op.p3 < int(pc_3.nHdrParsed) {
						serial_type = (&pc_3.aType[0])[p_op.p3]
						if serial_type >= u32(12) {
							if serial_type & u32(1) {
								type_mask = U16(4)
							} else {
								type_mask = U16(8)
							}
						} else {
							if !sqlite3_vdbe_exec_a_mask_inited {
								c2v_static_init := [u8(16), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1),
									u8(2), u8(1), u8(1), u8(16), u8(16)]
								for c2v_i_0, c2v_element_0 in c2v_static_init {
									sqlite3_vdbe_exec_a_mask[c2v_i_0] = c2v_element_0
								}
								sqlite3_vdbe_exec_a_mask_inited = true
							}

							type_mask = U16(sqlite3_vdbe_exec_a_mask[serial_type])
						}
					} else {
						type_mask = U16(1 << (p_op.p4.i - 1))
					}
				} else {
					type_mask = U16(1 << (sqlite3_value_type(&Sqlite3_value(unsafe { a_mem + p_op.p3 })) - 1))
				}
				if int(type_mask) & int(p_op.p5) {
					unsafe { goto jump_to_p2
					 }
				}
			}
			94 {
				if (int(a_mem[p_op.p1].flags) & 1) != 0 || (int(a_mem[p_op.p3].flags) & 1) != 0 {
					sqlite3_vdbe_mem_set_null(a_mem + p_op.p2)
				} else {
					sqlite3_vdbe_mem_set_int64(a_mem + p_op.p2, I64(0))
				}
			}
			52 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				if (int(p_in1.flags) & 1) == 0 {
					unsafe { goto jump_to_p2
					 }
				}
			}
			20 {
				pc_3 := &VdbeCursor(0)
				pc_3 = p.apCsr[p_op.p1]
				if !isnil(pc_3) && int(pc_3.nullRow) {
					sqlite3_vdbe_mem_set_null(a_mem + p_op.p3)
					unsafe { goto jump_to_p2
					 }
				}
			}
			96 {
				p2_2 := u32(0)
				pc_3 := &VdbeCursor(0)
				p_crsr_2 := &BtCursor(0)
				a_offset := &u32(0)
				len := 0
				i := 0
				p_dest := &Mem(0)
				s_mem := Mem{}
				z_data := &U8(0)
				z_hdr := &U8(0)
				z_end_hdr := &U8(0)
				offset64 := U64(0)
				t := u32(0)
				p_reg := &Mem(0)
				pc_3 = p.apCsr[p_op.p1]
				p2_2 = u32(p_op.p2)
				op_column_restart:
				a_offset = pc_3.aOffset
				if pc_3.cacheStatus != p.cacheCtr {
					if pc_3.nullRow {
						if int(pc_3.eCurType) == 3 && pc_3.seekResult > 0 {
							p_reg = unsafe { a_mem + pc_3.seekResult }
							pc_3.szRow = u32(p_reg.n)
							pc_3.payloadSize = pc_3.szRow
							pc_3.aRow = &U8(voidptr(p_reg.z))
						} else {
							p_dest = unsafe { a_mem + p_op.p3 }
							sqlite3_vdbe_mem_set_null(p_dest)
							unsafe { goto op_column_out
							 }
						}
					} else {
						p_crsr_2 = pc_3.uc.pCursor
						if pc_3.deferredMoveto {
							i_map := u32(0)
							if !isnil(pc_3.ub.aAltMap) && c2v_assign[u32](unsafe { &i_map }, u32(pc_3.ub.aAltMap[u32(1) + p2_2])) > u32(0) {
								pc_3 = pc_3.pAltCursor
								p2_2 = i_map - u32(1)
								unsafe { goto op_column_restart
								 }
							}
							rc = sqlite3_vdbe_finish_moveto(pc_3)
							if rc {
								unsafe { goto abort_due_to_error
								 }
							}
						} else if sqlite3_btree_cursor_has_moved(p_crsr_2) {
							rc = sqlite3_vdbe_handle_moved_cursor(pc_3)
							if rc {
								unsafe { goto abort_due_to_error
								 }
							}
							unsafe { goto op_column_restart
							 }
						}
						pc_3.payloadSize = sqlite3_btree_payload_size(p_crsr_2)
						pc_3.aRow = sqlite3_btree_payload_fetch(p_crsr_2, &pc_3.szRow)
					}
					pc_3.cacheStatus = p.cacheCtr
					a_offset[0] = u32(pc_3.aRow[0])
					if a_offset[0] < u32(128) {
						pc_3.iHdrOffset = u32(1)
					} else {
						pc_3.iHdrOffset = u32(sqlite3_get_varint32(pc_3.aRow, a_offset))
					}
					pc_3.nHdrParsed = U16(0)
					if pc_3.szRow < a_offset[0] {
						pc_3.aRow = 0
						pc_3.szRow = u32(0)
						if a_offset[0] > u32(98307) || a_offset[0] > pc_3.payloadSize {
							unsafe { goto op_column_corrupt
							 }
						}
					} else {
						z_data = pc_3.aRow
						unsafe { goto op_column_read_header
						 }
					}
				} else if sqlite3_btree_cursor_has_moved(pc_3.uc.pCursor) {
					rc = sqlite3_vdbe_handle_moved_cursor(pc_3)
					if rc {
						unsafe { goto abort_due_to_error
						 }
					}
					unsafe { goto op_column_restart
					 }
				}
				if u32(pc_3.nHdrParsed) <= p2_2 {
					if pc_3.iHdrOffset < a_offset[0] {
						if usize(pc_3.aRow) == usize(0) {
							C.memset(voidptr(&s_mem), 0, sizeof(s_mem))
							rc = sqlite3_vdbe_mem_from_btree_zero_offset(pc_3.uc.pCursor, a_offset[0], &s_mem)
							if rc != 0 {
								unsafe { goto abort_due_to_error
								 }
							}
							z_data = &U8(voidptr(s_mem.z))
						} else {
							z_data = pc_3.aRow
						}
						op_column_read_header:
						i = int(pc_3.nHdrParsed)
						offset64 = U64(a_offset[i])
						z_hdr = z_data + pc_3.iHdrOffset
						z_end_hdr = z_data + a_offset[0]
						for {
							t = u32(z_hdr[0])
							(&pc_3.aType[0])[i] = t
							if (&pc_3.aType[0])[i] < u32(128) {
								c2v_pointer_postfix(voidptr(&z_hdr), z_hdr, isize(1))
								offset64 += U64(sqlite3_vdbe_one_byte_serial_type_len(U8(t)))
							} else {
								c2v_pointer_prefix(voidptr(&z_hdr), z_hdr, isize(int(sqlite3_get_varint32(z_hdr, &t))))
								(&pc_3.aType[0])[i] = t
								offset64 += U64(sqlite3_vdbe_serial_type_len(t))
							}
							a_offset[c2v_prefix_add(unsafe { &i }, 1)] = u32((offset64 & U64(u32(4294967295))))
							if !(u32(i) <= p2_2 && usize(z_hdr) < usize(z_end_hdr)) {
								break
							}
						}
						if (usize(z_hdr) >= usize(z_end_hdr) && (usize(z_hdr) > usize(z_end_hdr) || offset64 != U64(pc_3.payloadSize))) || (offset64 > U64(pc_3.payloadSize)) {
							if a_offset[0] == u32(0) {
								i = 0
								z_hdr = z_end_hdr
							} else {
								if usize(pc_3.aRow) == usize(0) {
									sqlite3_vdbe_mem_release(&s_mem)
								}
								unsafe { goto op_column_corrupt
								 }
							}
						}
						pc_3.nHdrParsed = U16(i)
						pc_3.iHdrOffset = u32((i64((isize(z_hdr) - isize(z_data)) / isize(sizeof(U8)))))
						if usize(pc_3.aRow) == usize(0) {
							sqlite3_vdbe_mem_release(&s_mem)
						}
					} else {
						t = u32(0)
					}
					if u32(pc_3.nHdrParsed) <= p2_2 {
						p_dest = unsafe { a_mem + p_op.p3 }
						if int(p_op.p4type) == (-11) {
							sqlite3_vdbe_mem_shallow_copy(p_dest, p_op.p4.pMem, 8192)
						} else {
							sqlite3_vdbe_mem_set_null(p_dest)
						}
						unsafe { goto op_column_out
						 }
					}
				} else {
					t = (&pc_3.aType[0])[p2_2]
				}
				p_dest = unsafe { a_mem + p_op.p3 }
				if ((int(p_dest.flags) & (32768 | 4096)) != 0) {
					sqlite3_vdbe_mem_set_null(p_dest)
				}
				if pc_3.szRow >= a_offset[p2_2 + u32(1)] {
					z_data = pc_3.aRow + a_offset[p2_2]
					if t < u32(12) {
						sqlite3_vdbe_serial_get(z_data, t, p_dest)
					} else {
						if !sqlite3_vdbe_exec_a_flag_inited {
							c2v_static_init := [U16(16), U16(2 | 512)]
							for c2v_i_0, c2v_element_0 in c2v_static_init {
								sqlite3_vdbe_exec_a_flag[c2v_i_0] = c2v_element_0
							}
							sqlite3_vdbe_exec_a_flag_inited = true
						}

						len = int((t - u32(12)) / u32(2))
						p_dest.n = len
						p_dest.enc = encoding
						if p_dest.szMalloc < len + 2 {
							if len > db.aLimit[0] {
								unsafe { goto too_big
								 }
							}
							p_dest.flags = U16(1)
							if sqlite3_vdbe_mem_grow(p_dest, len + 2, 0) {
								unsafe { goto no_mem
								 }
							}
						} else {
							p_dest.z = p_dest.zMalloc
						}
						C.memcpy(voidptr(p_dest.z), voidptr(z_data), u64(len))
						p_dest.z[len] = i8(0)
						p_dest.z[len + 1] = i8(0)
						p_dest.flags = sqlite3_vdbe_exec_a_flag[t & u32(1)]
					}
				} else {
					p5 := U8(0)
					p_dest.enc = encoding
					p5 = U8((int(p_op.p5) & 192))
					if (int(p5) != 0 && (int(p5) == 128 || (t >= u32(12) && ((t & u32(1)) == u32(0) || int(p5) == 192)))) || sqlite3_vdbe_serial_type_len(t) == u32(0) {
						sqlite3_vdbe_serial_get(&U8(unsafe { &sqlite3CtypeMap[0] }), t, p_dest)
					} else {
						rc = vdbe_column_from_overflow(pc_3, int(p2_2), t, I64(a_offset[p2_2]), p.cacheCtr, col_cache_ctr, p_dest)
						if rc {
							if rc == 7 {
								unsafe { goto no_mem
								 }
							}
							if rc == 18 {
								unsafe { goto too_big
								 }
							}
							unsafe { goto abort_due_to_error
							 }
						}
					}
				}
				op_column_out:
				unsafe { goto c2v_switch_end_23
				 }

				op_column_corrupt:
				if a_op[0].p3 > 0 {
					p_op = unsafe { a_op + (a_op[0].p3 - 1) }
					unsafe { goto c2v_switch_end_23
					 }
				} else {
					rc = sqlite3_corrupt_error(3355)
					unsafe { goto abort_due_to_error
					 }
				}
			}
			97 {
				p_tab := &Table(0)
				a_col := &Column(0)
				i := 0
				n_col := 0
				p_tab = p_op.p4.pTab
				a_col = p_tab.aCol
				p_in1 = unsafe { a_mem + p_op.p1 }
				if p_op.p3 < 2 {
					i = 0
					n_col = int(p_tab.nCol)
				} else {
					i = p_op.p3 - 2
					n_col = i + 1
				}
				for ; i < n_col; i++ {
					if (int(a_col[i].colFlags) & 96) != 0 && p_op.p3 < 2 {
						if (int(a_col[i].colFlags) & 32) != 0 {
							continue
						}
						if p_op.p3 {
							c2v_pointer_postfix(voidptr(&p_in1), p_in1, isize(1))
							continue
						}
					}
					apply_affinity(p_in1, i8(a_col[i].affinity), encoding)
					if (int(p_in1.flags) & 1) == 0 {
						match int(a_col[i].eCType) {
							2 {
								if (int(p_in1.flags) & 16) == 0 {
									unsafe { goto vdbe_type_error
									 }
								}
							}
							4, 3 {
								if (int(p_in1.flags) & 4) == 0 {
									unsafe { goto vdbe_type_error
									 }
								}
							}
							6 {
								if (int(p_in1.flags) & 2) == 0 {
									unsafe { goto vdbe_type_error
									 }
								}
							}
							5 {
								if int(p_in1.flags) & 4 {
									if p_in1.u.i <= 140737488355327 && p_in1.u.i >= -140737488355328 {
										p_in1.flags |= 32
										p_in1.flags &= ~4
									} else {
										p_in1.u.r = f64(p_in1.u.i)
										p_in1.flags |= 8
										p_in1.flags &= ~4
									}
								} else if (int(p_in1.flags) & (8 | 32)) == 0 {
									unsafe { goto vdbe_type_error
									 }
								}
							}
							else {
							}
						}
					}
					c2v_pointer_postfix(voidptr(&p_in1), p_in1, isize(1))
				}
				unsafe { goto c2v_switch_end_23
				 }

				vdbe_type_error:
				sqlite3_vdbe_error(p, c'cannot store %s value in %s column %s.%s', voidptr(vdbe_mem_type_name(p_in1)), voidptr(sqlite3StdType[int(a_col[i].eCType) - 1]), voidptr(p_tab.zName), voidptr(a_col[i].zCnName))
				rc = (19 | (12 << 8))
				unsafe { goto abort_due_to_error
				 }
			}
			98 {
				z_affinity := &i8(0)
				z_affinity = p_op.p4.z
				p_in1 = unsafe { a_mem + p_op.p1 }
				for {
					apply_affinity(p_in1, i8(z_affinity[0]), encoding)
					if int(z_affinity[0]) == 69 && (int(p_in1.flags) & 4) != 0 {
						if p_in1.u.i <= 140737488355327 && p_in1.u.i >= -140737488355328 {
							p_in1.flags |= 32
							p_in1.flags &= ~4
						} else {
							p_in1.u.r = f64(p_in1.u.i)
							p_in1.flags |= 8
							p_in1.flags &= ~(4 | 2)
						}
					}
					c2v_pointer_postfix(voidptr(&z_affinity), z_affinity, isize(1))
					if int(z_affinity[0]) == 0 {
						break
					}
					c2v_pointer_postfix(voidptr(&p_in1), p_in1, isize(1))
				}
			}
			99 {
				p_rec := &Mem(0)
				n_data := U64(0)
				n_hdr := 0
				n_byte := I64(0)
				n_zero := I64(0)
				n_varint := 0
				serial_type := u32(0)
				p_data0 := &Mem(0)
				p_last := &Mem(0)
				n_field_2 := 0
				z_affinity := &i8(0)
				len := u32(0)
				z_hdr := &U8(0)
				z_payload := &U8(0)
				n_data = U64(0)
				n_hdr = 0
				n_zero = I64(0)
				n_field_2 = p_op.p1
				z_affinity = p_op.p4.z
				p_data0 = unsafe { a_mem + n_field_2 }
				n_field_2 = p_op.p2
				p_last = unsafe { p_data0 + (n_field_2 - 1) }
				p_out = unsafe { a_mem + p_op.p3 }
				if z_affinity {
					p_rec = p_data0
					for {
						apply_affinity(p_rec, i8(z_affinity[0]), encoding)
						if int(z_affinity[0]) == 69 && (int(p_rec.flags) & 4) {
							p_rec.flags |= 32
							p_rec.flags &= ~4
						}
						c2v_pointer_postfix(voidptr(&z_affinity), z_affinity, isize(1))
						c2v_pointer_postfix(voidptr(&p_rec), p_rec, isize(1))
						if !(z_affinity[0]) {
							break
						}
					}
				}
				p_rec = p_last
				for {
					if int(p_rec.flags) & 1 {
						if int(p_rec.flags) & 1024 {
							p_rec.uTemp = u32(10)
						} else {
							p_rec.uTemp = u32(0)
						}
						n_hdr++
					} else if int(p_rec.flags) & (4 | 32) {
						i := p_rec.u.i
						uu := U64(0)
						if i < I64(0) {
							uu = U64(~i)
						} else {
							uu = U64(i)
						}
						n_hdr++
						if uu <= U64(127) {
							if (i & I64(1)) == i && int(p.minWriteFileFormat) >= 4 {
								p_rec.uTemp = u32(8) + u32(uu)
							} else {
								n_data++
								p_rec.uTemp = u32(1)
							}
						} else if uu <= U64(32767) {
							n_data += U64(2)
							p_rec.uTemp = u32(2)
						} else if uu <= U64(8388607) {
							n_data += U64(3)
							p_rec.uTemp = u32(3)
						} else if uu <= U64(2147483647) {
							n_data += U64(4)
							p_rec.uTemp = u32(4)
						} else if uu <= U64(140737488355327) {
							n_data += U64(6)
							p_rec.uTemp = u32(5)
						} else {
							n_data += U64(8)
							if int(p_rec.flags) & 32 {
								p_rec.u.r = f64(p_rec.u.i)
								p_rec.flags &= ~32
								p_rec.flags |= 8
								p_rec.uTemp = u32(7)
							} else {
								p_rec.uTemp = u32(6)
							}
						}
					} else if int(p_rec.flags) & 8 {
						n_hdr++
						n_data += U64(8)
						p_rec.uTemp = u32(7)
					} else {
						len = u32(p_rec.n)
						serial_type = (len * u32(2)) + u32(12) + int(u32(((int(p_rec.flags) & 2) != 0)))
						if int(p_rec.flags) & 1024 {
							serial_type += u32(p_rec.u.nZero) * u32(2)
							if n_data {
								if sqlite3_vdbe_mem_expand_blob(p_rec) {
									unsafe { goto no_mem
									 }
								}
								len += u32(p_rec.u.nZero)
							} else {
								n_zero += I64(p_rec.u.nZero)
							}
						}
						n_data += U64(len)
						n_hdr += sqlite3_varint_len(U64(serial_type))
						p_rec.uTemp = serial_type
					}
					if usize(p_rec) == usize(p_data0) {
						break
					}
					c2v_pointer_postfix(voidptr(&p_rec), p_rec, isize(-1))
				}
				if n_hdr <= 126 {
					n_hdr += 1
				} else {
					n_varint = sqlite3_varint_len(U64(n_hdr))
					n_hdr += n_varint
					if n_varint < sqlite3_varint_len(U64(n_hdr)) {
						n_hdr++
					}
				}
				n_byte = I64(U64(n_hdr) + n_data)
				if n_byte + n_zero <= I64(p_out.szMalloc) {
					p_out.z = p_out.zMalloc
				} else {
					if n_byte + n_zero > I64(db.aLimit[0]) {
						unsafe { goto too_big
						 }
					}
					if sqlite3_vdbe_mem_clear_and_resize(p_out, int(n_byte)) {
						unsafe { goto no_mem
						 }
					}
				}
				p_out.n = int(n_byte)
				p_out.flags = U16(16)
				if n_zero {
					p_out.u.nZero = int(n_zero)
					p_out.flags |= 1024
				}
				z_hdr = &U8(voidptr(p_out.z))
				z_payload = z_hdr + n_hdr
				if n_hdr < 128 {
					mut __c2v_lhs_tmp_84 := unsafe { c2v_pointer_postfix(voidptr(&z_hdr), z_hdr, isize(1)) }
					unsafe { *__c2v_lhs_tmp_84 = U8(n_hdr) }
				} else {
					c2v_pointer_prefix(voidptr(&z_hdr), z_hdr, isize(sqlite3_put_varint(z_hdr, U64(n_hdr))))
				}
				p_rec = p_data0
				for {
					serial_type = p_rec.uTemp
					if serial_type <= u32(7) {
						mut __c2v_lhs_tmp_85 := unsafe { c2v_pointer_postfix(voidptr(&z_hdr), z_hdr, isize(1)) }
						unsafe { *__c2v_lhs_tmp_85 = U8(serial_type) }
						if serial_type == u32(0) {
						} else {
							v := U64(0)
							if serial_type == u32(7) {
								C.memcpy(voidptr(&v), voidptr(&p_rec.u.r), sizeof(v))
							} else {
								v = U64(p_rec.u.i)
							}
							len = u32(sqlite3_small_type_sizes[serial_type])
							match len {
								u32(6) {
									c2v_case_27_5:
									z_payload[5] = U8((v & U64(255)))
									v >>= 8
									z_payload[4] = U8((v & U64(255)))
									v >>= 8

									unsafe { goto c2v_case_27_10
									 }
								}
								u32(4) {
									c2v_case_27_10:
									z_payload[3] = U8((v & U64(255)))
									v >>= 8

									unsafe { goto c2v_case_27_13
									 }
								}
								u32(3) {
									c2v_case_27_13:
									z_payload[2] = U8((v & U64(255)))
									v >>= 8

									unsafe { goto c2v_case_27_16
									 }
								}
								u32(2) {
									c2v_case_27_16:
									z_payload[1] = U8((v & U64(255)))
									v >>= 8

									unsafe { goto c2v_case_27_19
									 }
								}
								u32(1) {
									c2v_case_27_19:
									z_payload[0] = U8((v & U64(255)))
								}
								else {
									z_payload[7] = U8((v & U64(255)))
									v >>= 8
									z_payload[6] = U8((v & U64(255)))
									v >>= 8

									unsafe { goto c2v_case_27_5
									 }
								}
							}

							c2v_pointer_prefix(voidptr(&z_payload), z_payload, isize(len))
						}
					} else if serial_type < u32(128) {
						mut __c2v_lhs_tmp_86 := unsafe { c2v_pointer_postfix(voidptr(&z_hdr), z_hdr, isize(1)) }
						unsafe { *__c2v_lhs_tmp_86 = U8(serial_type) }
						if serial_type >= u32(14) && p_rec.n > 0 {
							C.memcpy(voidptr(z_payload), voidptr(p_rec.z), u64(p_rec.n))
							c2v_pointer_prefix(voidptr(&z_payload), z_payload, isize(p_rec.n))
						}
					} else {
						c2v_pointer_prefix(voidptr(&z_hdr), z_hdr, isize(sqlite3_put_varint(z_hdr, U64(serial_type))))
						if p_rec.n {
							C.memcpy(voidptr(z_payload), voidptr(p_rec.z), u64(p_rec.n))
							c2v_pointer_prefix(voidptr(&z_payload), z_payload, isize(p_rec.n))
						}
					}
					if usize(p_rec) == usize(p_last) {
						break
					}
					c2v_pointer_postfix(voidptr(&p_rec), p_rec, isize(1))
				}
			}
			100 {
				n_entry := I64(0)
				p_crsr_2 := &BtCursor(0)
				p_crsr_2 = p.apCsr[p_op.p1].uc.pCursor
				if p_op.p3 {
					n_entry = sqlite3_btree_row_count_est(p_crsr_2)
				} else {
					n_entry = I64(0)
					rc = sqlite3_btree_count(db, p_crsr_2, &n_entry)
					if rc {
						unsafe { goto abort_due_to_error
						 }
					}
				}
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				p_out.u.i = n_entry
				unsafe { goto check_for_interrupt
				 }
			}
			0 {
				p1 := 0
				z_name := &i8(0)
				n_name := 0
				p_new := &Savepoint(0)
				p_savepoint := &Savepoint(0)
				p_tmp := &Savepoint(0)
				i_savepoint := 0
				ii := 0
				p1 = p_op.p1
				z_name = p_op.p4.z
				if p1 == 0 {
					if db.nVdbeWrite > 0 {
						sqlite3_vdbe_error(p, c'cannot open savepoint - SQL statements in progress')
						rc = 5
					} else {
						n_name = sqlite3_strlen30(z_name)
						rc = sqlite3_vtab_savepoint(db, 0, db.nStatement + db.nSavepoint)
						if rc != 0 {
							unsafe { goto abort_due_to_error
							 }
						}
						p_new = sqlite3_db_malloc_raw_nn(db, U64(sizeof(Savepoint) + u64(n_name) + u64(1)))
						if p_new {
							p_new.zName = &i8(voidptr(unsafe { p_new + 1 }))
							C.memcpy(voidptr(p_new.zName), voidptr(z_name), u64(n_name + 1))
							if db.autoCommit {
								db.autoCommit = U8(0)
								db.isTransactionSavepoint = U8(1)
							} else {
								db.nSavepoint++
							}
							p_new.pNext = db.pSavepoint
							db.pSavepoint = p_new
							p_new.nDeferredCons = db.nDeferredCons
							p_new.nDeferredImmCons = db.nDeferredImmCons
						}
					}
				} else {
					i_savepoint = 0
					for p_savepoint = db.pSavepoint; !isnil(p_savepoint) && sqlite3_str_ic_mp(p_savepoint.zName, z_name); p_savepoint = p_savepoint.pNext {
						i_savepoint++
					}
					if isnil(p_savepoint) {
						sqlite3_vdbe_error(p, c'no such savepoint: %s', voidptr(z_name))
						rc = 1
					} else if db.nVdbeWrite > 0 && p1 == 1 {
						sqlite3_vdbe_error(p, c'cannot release savepoint - SQL statements in progress')
						rc = 5
					} else {
						is_transaction := int(usize(p_savepoint.pNext) == usize(0) && int(db.isTransactionSavepoint))
						if is_transaction && p1 == 1 {
							rc = sqlite3_vdbe_check_fk_deferred(p)
							if rc != 0 {
								unsafe { goto vdbe_return
								 }
							}
							db.autoCommit = U8(1)
							if sqlite3_vdbe_halt(p) == 5 {
								p.pc = int((i64((isize(p_op) - isize(a_op)) / isize(sizeof(Op)))))
								db.autoCommit = U8(0)
								rc = 5
								p.rc = rc
								unsafe { goto vdbe_return
								 }
							}
							rc = p.rc
							if rc {
								db.autoCommit = U8(0)
							} else {
								db.isTransactionSavepoint = U8(0)
							}
						} else {
							is_schema_change := 0
							i_savepoint = db.nSavepoint - i_savepoint - 1
							if p1 == 2 {
								is_schema_change = (db.mDbFlags & u32(1)) != u32(0)
								for ii = 0; ii < db.nDb; ii++ {
									rc = sqlite3_btree_trip_all_cursors(db.aDb[ii].pBt, (4 | (2 << 8)), is_schema_change == 0)
									if rc != 0 {
										unsafe { goto abort_due_to_error
										 }
									}
								}
							} else {
								is_schema_change = 0
							}
							for ii = 0; ii < db.nDb; ii++ {
								rc = sqlite3_btree_savepoint(db.aDb[ii].pBt, p1, i_savepoint)
								if rc != 0 {
									unsafe { goto abort_due_to_error
									 }
								}
							}
							if is_schema_change {
								sqlite3_expire_prepared_statements(db, 0)
								sqlite3_reset_all_schemas_of_connection(db)
								db.mDbFlags |= u32(1)
							}
						}
						if rc {
							unsafe { goto abort_due_to_error
							 }
						}
						for usize(db.pSavepoint) != usize(p_savepoint) {
							p_tmp = db.pSavepoint
							db.pSavepoint = p_tmp.pNext
							sqlite3_db_free(db, voidptr(p_tmp))
							db.nSavepoint--
						}
						if p1 == 1 {
							db.pSavepoint = p_savepoint.pNext
							sqlite3_db_free(db, voidptr(p_savepoint))
							if !is_transaction {
								db.nSavepoint--
							}
						} else {
							db.nDeferredCons = p_savepoint.nDeferredCons
							db.nDeferredImmCons = p_savepoint.nDeferredImmCons
						}
						if !is_transaction || p1 == 2 {
							rc = sqlite3_vtab_savepoint(db, p1, i_savepoint)
							if rc != 0 {
								unsafe { goto abort_due_to_error
								 }
							}
						}
					}
				}
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				if int(p.eVdbeState) == 3 {
					rc = 101
					unsafe { goto vdbe_return
					 }
				}
			}
			1 {
				desired_auto_commit := 0
				i_rollback := 0
				desired_auto_commit = p_op.p1
				i_rollback = p_op.p2
				if desired_auto_commit != int(db.autoCommit) {
					if i_rollback {
						sqlite3_rollback_all(db, (4 | (2 << 8)))
						db.autoCommit = U8(1)
					} else if desired_auto_commit && db.nVdbeWrite > 0 {
						sqlite3_vdbe_error(p, c'cannot commit transaction - SQL statements in progress')
						rc = 5
						unsafe { goto abort_due_to_error
						 }
					} else {
						rc = sqlite3_vdbe_check_fk_deferred(p)
						if rc != 0 {
							unsafe { goto vdbe_return
							 }
						} else {
							db.autoCommit = U8(desired_auto_commit)
						}
					}
					if sqlite3_vdbe_halt(p) == 5 {
						p.pc = int((i64((isize(p_op) - isize(a_op)) / isize(sizeof(Op)))))
						db.autoCommit = U8((1 - desired_auto_commit))
						rc = 5
						p.rc = rc
						unsafe { goto vdbe_return
						 }
					}
					sqlite3_close_savepoints(db)
					if p.rc == 0 {
						rc = 101
					} else {
						rc = 1
					}
					unsafe { goto vdbe_return
					 }
				} else {
					sqlite3_vdbe_error(p, unsafe { if (!desired_auto_commit) {
						c'cannot start a transaction within a transaction'
					} else {
						if i_rollback {
							c'cannot rollback - no transaction is active'
						} else {
							c'cannot commit - no transaction is active'
						}
					} })
					rc = 1
					unsafe { goto abort_due_to_error
					 }
				}
				unsafe { goto c2v_case_23_55
				 }
			}
			2 {
				c2v_case_23_55:
				p_bt := &Btree(0)
				p_db_2 := &Db(0)
				i_meta := 0
				if p_op.p2 && (db.flags & (U64(1048576) | (U64(2) << 32))) != U64(0) {
					if db.flags & U64(1048576) {
						rc = 8
					} else {
						rc = 11
					}
					unsafe { goto abort_due_to_error
					 }
				}
				p_db_2 = unsafe { db.aDb + p_op.p1 }
				p_bt = p_db_2.pBt
				if p_bt {
					rc = sqlite3_btree_begin_trans(p_bt, p_op.p2, &i_meta)
					if rc != 0 {
						if (rc & 255) == 5 {
							p.pc = int((i64((isize(p_op) - isize(a_op)) / isize(sizeof(Op)))))
							p.rc = rc
							unsafe { goto vdbe_return
							 }
						}
						unsafe { goto abort_due_to_error
						 }
					}
					if int(p.usesStmtJournal) && p_op.p2 && (int(db.autoCommit) == 0 || db.nVdbeRead > 1) {
						if p.iStatement == 0 {
							db.nStatement++
							p.iStatement = db.nSavepoint + db.nStatement
						}
						rc = sqlite3_vtab_savepoint(db, 0, p.iStatement - 1)
						if rc == 0 {
							rc = sqlite3_btree_begin_stmt(p_bt, p.iStatement)
						}
						p.nStmtDefCons = db.nDeferredCons
						p.nStmtDefImmCons = db.nDeferredImmCons
					}
				}
				if rc == 0 && int(p_op.p5) && (i_meta != p_op.p3 || p_db_2.pSchema.iGeneration != p_op.p4.i) {
					sqlite3_db_free(db, voidptr(p.zErrMsg))
					p.zErrMsg = sqlite3_db_str_dup(db, c'database schema has changed')
					if db.aDb[p_op.p1].pSchema.schema_cookie != i_meta {
						sqlite3_reset_one_schema(db, p_op.p1)
					}
					p.expired = Bft(1)
					rc = 17
					p.changeCntOn = Bft(0)
				}
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			101 {
				i_meta := 0
				i_db_2 := 0
				i_cookie := 0
				i_db_2 = p_op.p1
				i_cookie = p_op.p3
				sqlite3_btree_get_meta(db.aDb[i_db_2].pBt, i_cookie, &u32(c2v_address_of(&i_meta)))
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				p_out.u.i = I64(i_meta)
			}
			102 {
				p_db_2 := &Db(0)
				p_db_2 = unsafe { db.aDb + p_op.p1 }
				rc = sqlite3_btree_update_meta(p_db_2.pBt, p_op.p2, u32(p_op.p3))
				if p_op.p2 == 1 {
					mut __c2v_lhs_tmp_87 := unsafe { &u32(voidptr(&p_db_2.pSchema.schema_cookie)) }
					unsafe { *__c2v_lhs_tmp_87 = *&u32(voidptr(&p_op.p3)) - u32(p_op.p5) }
					db.mDbFlags |= u32(1)
					sqlite3_fk_clear_trigger_cache(db, p_op.p1)
				} else if p_op.p2 == 2 {
					p_db_2.pSchema.file_format = U8(p_op.p3)
				}
				if p_op.p1 == 1 {
					sqlite3_expire_prepared_statements(db, 0)
					p.expired = Bft(0)
				}
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			113 {
				p_cur = p.apCsr[p_op.p1]
				if !isnil(p_cur) && p_cur.pgnoRoot == u32(p_op.p2) {
					sqlite3_btree_clear_cursor(p_cur.uc.pCursor)
					unsafe { goto open_cursor_set_hints
					 }
				}
				unsafe { goto c2v_case_23_59
				 }
			}
			114, 116 {
				c2v_case_23_59:
				if int(p.expired) == 1 {
					rc = (4 | (2 << 8))
					unsafe { goto abort_due_to_error
					 }
				}
				n_field = 0
				p_key_info = 0
				p2 = u32(p_op.p2)
				i_db = p_op.p3
				p_db = unsafe { db.aDb + i_db }
				px = p_db.pBt
				if int(p_op.opcode) == 116 {
					wr_flag = 4 | (int(p_op.p5) & 8)
					if int(p_db.pSchema.file_format) < int(p.minWriteFileFormat) {
						p.minWriteFileFormat = p_db.pSchema.file_format
					}
					if int(p_op.p5) & 16 {
						p_in2 = unsafe { a_mem + p2 }
						sqlite3_vdbe_mem_integerify(p_in2)
						p2 = u32(int(p_in2.u.i))
					}
				} else {
					wr_flag = 0
				}
				if int(p_op.p4type) == (-9) {
					p_key_info = p_op.p4.pKeyInfo
					n_field = int(p_key_info.nAllField)
				} else if int(p_op.p4type) == (-3) {
					n_field = p_op.p4.i
				}
				p_cur = allocate_cursor(p, p_op.p1, n_field, U8(0))
				if usize(p_cur) == usize(0) {
					unsafe { goto no_mem
					 }
				}
				p_cur.iDb = I8(i_db)
				p_cur.nullRow = U8(1)
				p_cur.isOrdered = bool(1)
				p_cur.pgnoRoot = p2
				rc = sqlite3_btree_cursor(px, p2, wr_flag, p_key_info, p_cur.uc.pCursor)
				p_cur.pKeyInfo = p_key_info
				p_cur.isTable = U8(int(p_op.p4type) != (-9))
				open_cursor_set_hints:
				sqlite3_btree_cursor_hint_flags(p_cur.uc.pCursor, u32((int(p_op.p5) & (1 | 2))))
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			117 {
				p_orig := &VdbeCursor(0)
				p_cx := &VdbeCursor(0)
				p_orig = p.apCsr[p_op.p2]
				p_cx = allocate_cursor(p, p_op.p1, int(p_orig.nField), U8(0))
				if usize(p_cx) == usize(0) {
					unsafe { goto no_mem
					 }
				}
				p_cx.nullRow = U8(1)
				p_cx.isEphemeral = bool(1)
				p_cx.pKeyInfo = p_orig.pKeyInfo
				p_cx.isTable = p_orig.isTable
				p_cx.pgnoRoot = p_orig.pgnoRoot
				p_cx.isOrdered = p_orig.isOrdered
				p_cx.ub.pBtx = p_orig.ub.pBtx
				p_cx.noReuse = bool(1)
				p_orig.noReuse = bool(1)
				rc = sqlite3_btree_cursor(p_cx.ub.pBtx, p_cx.pgnoRoot, 4, p_cx.pKeyInfo, p_cx.uc.pCursor)
			}
			119, 120 {
				p_cx := &VdbeCursor(0)
				p_key_info_2 := &KeyInfo(0)
				static vfs_flags := 2 | 4 | 16 | 8 | 1024
				if p_op.p3 > 0 {
					a_mem[p_op.p3].n = 0
					a_mem[p_op.p3].z = c''
				}
				p_cx = p.apCsr[p_op.p1]
				if !isnil(p_cx) && !p_cx.noReuse && (p_op.p2 <= int(p_cx.nField)) {
					p_cx.seqCount = I64(0)
					p_cx.cacheStatus = u32(0)
					rc = sqlite3_btree_clear_table(p_cx.ub.pBtx, int(p_cx.pgnoRoot), unsafe { nil })
				} else {
					p_cx = allocate_cursor(p, p_op.p1, p_op.p2, U8(0))
					if usize(p_cx) == usize(0) {
						unsafe { goto no_mem
						 }
					}
					p_cx.isEphemeral = bool(1)
					rc = sqlite3_btree_open(db.pVfs, unsafe { nil }, db, &&Btree(&p_cx.ub.pBtx), 1 | 4 | int(p_op.p5), vfs_flags)
					if rc == 0 {
						rc = sqlite3_btree_begin_trans(p_cx.ub.pBtx, 1, unsafe { nil })
						if rc == 0 {
							p_key_info_2 = p_op.p4.pKeyInfo
							p_cx.pKeyInfo = p_key_info_2
							if usize(p_cx.pKeyInfo) != usize(0) {
								rc = sqlite3_btree_create_table(p_cx.ub.pBtx, &p_cx.pgnoRoot, 2 | int(p_op.p5))
								if rc == 0 {
									rc = sqlite3_btree_cursor(p_cx.ub.pBtx, p_cx.pgnoRoot, 4, p_key_info_2, p_cx.uc.pCursor)
								}
								p_cx.isTable = U8(0)
							} else {
								p_cx.pgnoRoot = Pgno(1)
								rc = sqlite3_btree_cursor(p_cx.ub.pBtx, Pgno(1), 4, unsafe { nil }, p_cx.uc.pCursor)
								p_cx.isTable = U8(1)
							}
						}
						p_cx.isOrdered = bool((int(p_op.p5) != 8))
						if rc {
							sqlite3_btree_close(p_cx.ub.pBtx)
							p.apCsr[p_op.p1] = 0
						} else {
						}
					}
				}
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				p_cx.nullRow = U8(1)
			}
			121 {
				p_cx_2 := &VdbeCursor(0)
				p_cx_2 = allocate_cursor(p, p_op.p1, p_op.p2, U8(1))
				if usize(p_cx_2) == usize(0) {
					unsafe { goto no_mem
					 }
				}
				p_cx_2.pKeyInfo = p_op.p4.pKeyInfo
				rc = sqlite3_vdbe_sorter_init(db, p_op.p3, p_cx_2)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			122 {
				pc_3 := &VdbeCursor(0)
				pc_3 = p.apCsr[p_op.p1]
				if (pc_3.seqCount++) == I64(0) {
					unsafe { goto jump_to_p2
					 }
				}
			}
			123 {
				p_cx_2 := &VdbeCursor(0)
				p_cx_2 = allocate_cursor(p, p_op.p1, p_op.p3, U8(3))
				if usize(p_cx_2) == usize(0) {
					unsafe { goto no_mem
					 }
				}
				p_cx_2.nullRow = U8(1)
				p_cx_2.seekResult = p_op.p2
				p_cx_2.isTable = U8(1)
				p_cx_2.uc.pCursor = sqlite3_btree_fake_valid_cursor()
			}
			124 {
				sqlite3_vdbe_free_cursor(p, p.apCsr[p_op.p1])
				p.apCsr[p_op.p1] = 0
			}
			21, 22, 23, 24 {
				res_3 := 0
				oc := 0
				pc_3 := &VdbeCursor(0)
				r := UnpackedRecord{}
				n_field_2 := 0
				i_key_2 := I64(0)
				eq_only := 0
				pc_3 = p.apCsr[p_op.p1]
				oc = int(p_op.opcode)
				eq_only = 0
				pc_3.nullRow = U8(0)
				pc_3.deferredMoveto = U8(0)
				pc_3.cacheStatus = u32(0)
				if pc_3.isTable {
					flags3_2 := U16(0)
					new_type := U16(0)

					p_in3 = unsafe { a_mem + p_op.p3 }
					flags3_2 = p_in3.flags
					if (int(flags3_2) & (4 | 8 | 32 | 2)) == 2 {
						apply_numeric_affinity(p_in3, 0)
					}
					i_key_2 = sqlite3_vdbe_int_value(p_in3)
					new_type = p_in3.flags
					p_in3.flags = flags3_2
					if (int(new_type) & (4 | 32)) == 0 {
						c := 0
						if (int(new_type) & 8) == 0 {
							if (int(new_type) & 1) || oc >= 23 {
								unsafe { goto jump_to_p2
								 }
							} else {
								rc = sqlite3_btree_last(pc_3.uc.pCursor, &res_3)
								if rc != 0 {
									unsafe { goto abort_due_to_error
									 }
								}
								unsafe { goto seek_not_found
								 }
							}
						}
						c = sqlite3_int_float_compare(i_key_2, p_in3.u.r)
						if c > 0 {
							if (oc & 1) == (24 & 1) {
								oc--
							}
						} else if c < 0 {
							if (oc & 1) == (21 & 1) {
								oc++
							}
						}
					}
					rc = sqlite3_btree_table_moveto(pc_3.uc.pCursor, I64(U64(i_key_2)), 0, &res_3)
					pc_3.movetoTarget = i_key_2
					if rc != 0 {
						unsafe { goto abort_due_to_error
						 }
					}
				} else {
					if sqlite3_btree_cursor_has_hint(pc_3.uc.pCursor, u32(2)) {
						eq_only = 1
					}
					n_field_2 = p_op.p4.i
					r.pKeyInfo = pc_3.pKeyInfo
					r.nField = U16(n_field_2)
					r.default_rc = I8((if (1 & (oc - 21)) { -1 } else { 1 }))
					r.aMem = unsafe { a_mem + p_op.p3 }
					r.eqSeen = U8(0)
					rc = sqlite3_btree_index_moveto(pc_3.uc.pCursor, &r, &res_3)
					if rc != 0 {
						unsafe { goto abort_due_to_error
						 }
					}
					if eq_only && int(r.eqSeen) == 0 {
						unsafe { goto seek_not_found
						 }
					}
				}
				if oc >= 23 {
					if res_3 < 0 || (res_3 == 0 && oc == 24) {
						res_3 = 0
						rc = sqlite3_btree_next(pc_3.uc.pCursor, 0)
						if rc != 0 {
							if rc == 101 {
								rc = 0
								res_3 = 1
							} else {
								unsafe { goto abort_due_to_error
								 }
							}
						}
					} else {
						res_3 = 0
					}
				} else {
					if res_3 > 0 || (res_3 == 0 && oc == 21) {
						res_3 = 0
						rc = sqlite3_btree_previous(pc_3.uc.pCursor, 0)
						if rc != 0 {
							if rc == 101 {
								rc = 0
								res_3 = 1
							} else {
								unsafe { goto abort_due_to_error
								 }
							}
						}
					} else {
						res_3 = sqlite3_btree_eof(pc_3.uc.pCursor)
					}
				}
				seek_not_found:
				if res_3 {
					unsafe { goto jump_to_p2
					 }
				} else if eq_only {
					c2v_pointer_postfix(voidptr(&p_op), p_op, isize(1))
				}
			}
			126 {
				pc_4 := &VdbeCursor(0)
				res_4 := 0
				n_step := 0
				r_2 := UnpackedRecord{}
				pc_4 = p.apCsr[p_op[1].p1]
				if !sqlite3_btree_cursor_is_valid_nn(pc_4.uc.pCursor) {
					unsafe { goto c2v_switch_end_23
					 }
				}
				n_step = p_op.p1
				r_2.pKeyInfo = pc_4.pKeyInfo
				r_2.nField = U16(p_op[1].p4.i)
				r_2.default_rc = I8(0)
				r_2.aMem = unsafe { a_mem + p_op[1].p3 }
				res_4 = 0
				for {
					rc = sqlite3_vdbe_idx_key_compare(db, pc_4, &r_2, &res_4)
					if rc {
						unsafe { goto abort_due_to_error
						 }
					}
					if res_4 > 0 && int(p_op.p5) == 0 {
						seekscan_search_fail:
						c2v_pointer_postfix(voidptr(&p_op), p_op, isize(1))
						unsafe { goto jump_to_p2
						 }
					}
					if res_4 >= 0 {
						unsafe { goto jump_to_p2
						 }
						break
					}
					if n_step <= 0 {
						break
					}
					n_step--
					pc_4.cacheStatus = u32(0)
					rc = sqlite3_btree_next(pc_4.uc.pCursor, 0)
					if rc {
						if rc == 101 {
							rc = 0
							unsafe { goto seekscan_search_fail
							 }
						} else {
							unsafe { goto abort_due_to_error
							 }
						}
					}
				}
			}
			127 {
				pc_4 := &VdbeCursor(0)
				pc_4 = p.apCsr[p_op.p1]
				if int(pc_4.seekHit) < p_op.p2 {
					pc_4.seekHit = U16(p_op.p2)
				} else if int(pc_4.seekHit) > p_op.p3 {
					pc_4.seekHit = U16(p_op.p3)
				}
			}
			25 {
				p_cur_2 := &VdbeCursor(0)
				p_cur_2 = p.apCsr[p_op.p1]
				if usize(p_cur_2) == usize(0) || int(p_cur_2.nullRow) {
					unsafe { goto jump_to_p2_and_check_for_interrupt
					 }
				}
			}
			26 {
				pc_4 := &VdbeCursor(0)
				pc_4 = p.apCsr[p_op.p1]
				if int(pc_4.seekHit) >= p_op.p4.i {
					unsafe { goto c2v_switch_end_23
					 }
				}

				unsafe { goto c2v_case_23_104
				 }
			}
			27, 28, 29 {
				c2v_case_23_104:
				already_exists := 0
				ii := 0
				pc_4 := &VdbeCursor(0)
				p_idx_key := &UnpackedRecord(0)
				r_2 := UnpackedRecord{}
				pc_4 = p.apCsr[p_op.p1]
				r_2.aMem = unsafe { a_mem + p_op.p3 }
				r_2.nField = U16(p_op.p4.i)
				if int(r_2.nField) > 0 {
					r_2.pKeyInfo = pc_4.pKeyInfo
					r_2.default_rc = I8(0)
					rc = sqlite3_btree_index_moveto(pc_4.uc.pCursor, &r_2, &pc_4.seekResult)
				} else {
					rc = (if (int(r_2.aMem.flags) & 1024) {
						sqlite3_vdbe_mem_expand_blob(r_2.aMem)
					} else {
						0
					})
					if rc {
						unsafe { goto no_mem
						 }
					}
					p_idx_key = sqlite3_vdbe_alloc_unpacked_record(pc_4.pKeyInfo)
					if usize(p_idx_key) == usize(0) {
						unsafe { goto no_mem
						 }
					}
					sqlite3_vdbe_record_unpack(r_2.aMem.n, voidptr(r_2.aMem.z), p_idx_key)
					p_idx_key.default_rc = I8(0)
					rc = sqlite3_btree_index_moveto(pc_4.uc.pCursor, p_idx_key, &pc_4.seekResult)
					sqlite3_db_free_nn(db, voidptr(p_idx_key))
				}
				if rc != 0 {
					unsafe { goto abort_due_to_error
					 }
				}
				already_exists = (pc_4.seekResult == 0)
				pc_4.nullRow = U8(1 - already_exists)
				pc_4.deferredMoveto = U8(0)
				pc_4.cacheStatus = u32(0)
				if int(p_op.opcode) == 29 {
					if already_exists {
						unsafe { goto jump_to_p2
						 }
					}
				} else {
					if !already_exists {
						unsafe { goto jump_to_p2
						 }
					}
					if int(p_op.opcode) == 27 {
						for ii = 0; ii < int(r_2.nField); ii++ {
							if int(r_2.aMem[ii].flags) & 1 {
								unsafe { goto jump_to_p2
								 }
							}
						}
					}
					if int(p_op.opcode) == 26 {
						pc_4.seekHit = U16(p_op.p4.i)
					}
				}
			}
			30 {
				p_in3 = unsafe { a_mem + p_op.p3 }
				if (int(p_in3.flags) & (4 | 32)) == 0 {
					x := p_in3[0]
					apply_affinity(&x, i8(67), encoding)
					if (int(x.flags) & 4) == 0 {
						unsafe { goto jump_to_p2
						 }
					}
					i_key = U64(x.u.i)
					unsafe { goto notExistsWithKey
					 }
				}

				unsafe { goto c2v_case_23_106
				 }
			}
			31 {
				c2v_case_23_106:
				p_in3 = unsafe { a_mem + p_op.p3 }
				i_key = U64(p_in3.u.i)
				notExistsWithKey:
				pc = p.apCsr[p_op.p1]
				p_crsr = pc.uc.pCursor
				res = 0
				rc = sqlite3_btree_table_moveto(p_crsr, I64(i_key), 0, &res)
				pc.movetoTarget = I64(i_key)
				pc.nullRow = U8(0)
				pc.cacheStatus = u32(0)
				pc.deferredMoveto = U8(0)
				pc.seekResult = res
				if res != 0 {
					if p_op.p2 == 0 {
						rc = sqlite3_corrupt_error(5637)
					} else {
						unsafe { goto jump_to_p2
						 }
					}
				}
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			128 {
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				mut __c2v_postfix_value_3 := p.apCsr[p_op.p1].seqCount
				p.apCsr[p_op.p1].seqCount++
				p_out.u.i = __c2v_postfix_value_3
			}
			129 {
				v := I64(0)
				pc_5 := &VdbeCursor(0)
				res_4 := 0
				cnt_2 := 0
				p_mem := &Mem(0)
				p_frame := &VdbeFrame(0)
				v = I64(0)
				res_4 = 0
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				pc_5 = p.apCsr[p_op.p1]
				if !pc_5.useRandomRowid {
					rc = sqlite3_btree_last(pc_5.uc.pCursor, &res_4)
					if rc != 0 {
						unsafe { goto abort_due_to_error
						 }
					}
					if res_4 {
						v = I64(1)
					} else {
						v = sqlite3_btree_integer_key(pc_5.uc.pCursor)
						if v >= I64((((U64(2147483647)) << 32) | U64(u32(4294967295)))) {
							pc_5.useRandomRowid = bool(1)
						} else {
							v++
						}
					}
				}
				if p_op.p3 {
					if p.pFrame {
						for p_frame = p.pFrame; p_frame.pParent; p_frame = p_frame.pParent {
						}
						p_mem = unsafe { p_frame.aMem + p_op.p3 }
					} else {
						p_mem = unsafe { a_mem + p_op.p3 }
					}
					sqlite3_vdbe_mem_integerify(p_mem)
					if p_mem.u.i == I64((((U64(2147483647)) << 32) | U64(u32(4294967295)))) || int(pc_5.useRandomRowid) {
						rc = 13
						unsafe { goto abort_due_to_error
						 }
					}
					if v < p_mem.u.i + I64(1) {
						v = p_mem.u.i + I64(1)
					}
					p_mem.u.i = v
				}
				if pc_5.useRandomRowid {
					cnt_2 = 0
					for {
						sqlite3_randomness(int(sizeof(v)), voidptr(&v))
						v &= (I64((((U64(2147483647)) << 32) | U64(u32(4294967295)))) >> 1)
						v++
						rc = sqlite3_btree_table_moveto(pc_5.uc.pCursor, I64(U64(v)), 0, &res_4)
						if !((rc == 0) && (res_4 == 0) && (c2v_prefix_add(unsafe { &cnt_2 }, 1) < 100)) {
							break
						}
					}
					if rc {
						unsafe { goto abort_due_to_error
						 }
					}
					if res_4 == 0 {
						rc = 13
						unsafe { goto abort_due_to_error
						 }
					}
				}
				pc_5.deferredMoveto = U8(0)
				pc_5.cacheStatus = u32(0)
				p_out.u.i = v
			}
			130 {
				p_data := &Mem(0)
				p_key := &Mem(0)
				pc_5 := &VdbeCursor(0)
				seek_result := 0
				z_db := &i8(0)
				p_tab := &Table(0)
				x := BtreePayload{}
				p_data = unsafe { a_mem + p_op.p2 }
				pc_5 = p.apCsr[p_op.p1]
				p_key = unsafe { a_mem + p_op.p3 }
				x.nKey = p_key.u.i
				if int(p_op.p4type) == (-5) && !isnil(db.xUpdateCallback) {
					z_db = db.aDb[pc_5.iDb].zDbSName
					p_tab = p_op.p4.pTab
				} else {
					p_tab = 0
					z_db = 0
				}
				if int(p_op.p5) & 1 {
					p.nChange++
					if int(p_op.p5) & 32 {
						db.lastRowid = x.nKey
					}
				}
				x.pData = p_data.z
				x.nData = p_data.n
				seek_result = (if (int(p_op.p5) & 16) { pc_5.seekResult } else { 0 })
				if int(p_data.flags) & 1024 {
					x.nZero = p_data.u.nZero
				} else {
					x.nZero = 0
				}
				x.pKey = 0
				rc = sqlite3_btree_insert(pc_5.uc.pCursor, &x, (int(p_op.p5) & (8 | 2 | 128)), seek_result)
				pc_5.deferredMoveto = U8(0)
				pc_5.cacheStatus = u32(0)
				col_cache_ctr++
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				if p_tab {
					db.xUpdateCallback(voidptr(db.pUpdateArg), if (int(p_op.p5) & 4) {
						23
					} else {
						18
					}, z_db, p_tab.zName, x.nKey)
				}
			}
			131 {
				p_dest := &VdbeCursor(0)
				p_src := &VdbeCursor(0)
				i_key_3 := I64(0)
				p_dest = p.apCsr[p_op.p1]
				p_src = p.apCsr[p_op.p2]
				i_key_3 = if p_op.p3 { a_mem[p_op.p3].u.i } else { I64(0) }
				rc = sqlite3_btree_transfer_row(p_dest.uc.pCursor, p_src.uc.pCursor, i_key_3)
				if rc != 0 {
					unsafe { goto abort_due_to_error
					 }
				}
				unsafe { goto c2v_switch_end_23
				 }

				unsafe { goto c2v_case_23_133
				 }
			}
			132 {
				c2v_case_23_133:
				pc_5 := &VdbeCursor(0)
				z_db := &i8(0)
				p_tab := &Table(0)
				opflags := 0
				opflags = p_op.p2
				pc_5 = p.apCsr[p_op.p1]
				if int(p_op.p4type) == (-5) && !isnil(db.xUpdateCallback) {
					z_db = db.aDb[pc_5.iDb].zDbSName
					p_tab = p_op.p4.pTab
					if (int(p_op.p5) & 2) != 0 && int(pc_5.isTable) {
						pc_5.movetoTarget = sqlite3_btree_integer_key(pc_5.uc.pCursor)
					}
				} else {
					z_db = 0
					p_tab = 0
				}
				rc = sqlite3_btree_delete(pc_5.uc.pCursor, U8(p_op.p5))
				pc_5.cacheStatus = u32(0)
				col_cache_ctr++
				pc_5.seekResult = 0
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				if opflags & 1 {
					p.nChange++
					if !isnil(db.xUpdateCallback) && (usize(p_tab) != usize(0)) && ((p_tab.tabFlags & u32(128)) == u32(0)) {
						db.xUpdateCallback(voidptr(db.pUpdateArg), 9, z_db, p_tab.zName, pc_5.movetoTarget)
					}
				}
			}
			133 {
				sqlite3_vdbe_set_changes(db, p.nChange)
				p.nChange = I64(0)
			}
			134 {
				pc_5 := &VdbeCursor(0)
				res_4 := 0
				n_key_col := 0
				pc_5 = p.apCsr[p_op.p1]
				p_in3 = unsafe { a_mem + p_op.p3 }
				n_key_col = p_op.p4.i
				res_4 = 0
				rc = sqlite3_vdbe_sorter_compare(pc_5, p_in3, n_key_col, &res_4)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				if res_4 {
					unsafe { goto jump_to_p2
					 }
				}
				unsafe { goto c2v_switch_end_23
				 }

				unsafe { goto c2v_case_23_137
				 }
			}
			135 {
				c2v_case_23_137:
				pc_5 := &VdbeCursor(0)
				p_out = unsafe { a_mem + p_op.p2 }
				pc_5 = p.apCsr[p_op.p1]
				rc = sqlite3_vdbe_sorter_rowkey(pc_5, p_out)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				p.apCsr[p_op.p3].cacheStatus = u32(0)
			}
			136 {
				pc_5 := &VdbeCursor(0)
				p_crsr_2 := &BtCursor(0)
				n := u32(0)
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				pc_5 = p.apCsr[p_op.p1]
				p_crsr_2 = pc_5.uc.pCursor
				n = sqlite3_btree_payload_size(p_crsr_2)
				if n > u32(db.aLimit[0]) {
					unsafe { goto too_big
					 }
				}
				rc = sqlite3_vdbe_mem_from_btree_zero_offset(p_crsr_2, n, p_out)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				if !p_op.p3 {
					if (int(p_out.flags) & 16384) != 0 && sqlite3_vdbe_mem_make_writeable(p_out) {
						unsafe { goto no_mem
						 }
					}
				}
			}
			137 {
				pc_5 := &VdbeCursor(0)
				v := I64(0)
				p_vtab := &Sqlite3_vtab(0)
				p_module := &Sqlite3_module(0)
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				pc_5 = p.apCsr[p_op.p1]
				if pc_5.nullRow {
					p_out.flags = U16(1)
					unsafe { goto c2v_switch_end_23
					 }
				} else if pc_5.deferredMoveto {
					v = pc_5.movetoTarget
				} else if int(pc_5.eCurType) == 2 {
					p_vtab = pc_5.uc.pVCur.pVtab
					p_module = p_vtab.pModule
					rc = p_module.xRowid(pc_5.uc.pVCur, unsafe { &Sqlite3_int64(&v) })
					sqlite3_vtab_import_errmsg(p, p_vtab)
					if rc {
						unsafe { goto abort_due_to_error
						 }
					}
				} else {
					rc = sqlite3_vdbe_cursor_restore(pc_5)
					if rc {
						unsafe { goto abort_due_to_error
						 }
					}
					if pc_5.nullRow {
						p_out.flags = U16(1)
						unsafe { goto c2v_switch_end_23
						 }
					}
					v = sqlite3_btree_integer_key(pc_5.uc.pCursor)
				}
				p_out.u.i = v
			}
			138 {
				pc_5 := &VdbeCursor(0)
				pc_5 = p.apCsr[p_op.p1]
				if usize(pc_5) == usize(0) {
					pc_5 = allocate_cursor(p, p_op.p1, 1, U8(3))
					if usize(pc_5) == usize(0) {
						unsafe { goto no_mem
						 }
					}
					pc_5.seekResult = 0
					pc_5.isTable = U8(1)
					pc_5.noReuse = bool(1)
					pc_5.uc.pCursor = sqlite3_btree_fake_valid_cursor()
				}
				pc_5.nullRow = U8(1)
				pc_5.cacheStatus = u32(0)
				if int(pc_5.eCurType) == 0 {
					sqlite3_btree_clear_cursor(pc_5.uc.pCursor)
				}
			}
			139, 32 {
				pc_5 := &VdbeCursor(0)
				p_crsr_2 := &BtCursor(0)
				res_4 := 0
				pc_5 = p.apCsr[p_op.p1]
				p_crsr_2 = pc_5.uc.pCursor
				res_4 = 0
				if int(p_op.opcode) == 139 {
					pc_5.seekResult = -1
					if sqlite3_btree_cursor_is_valid_nn(p_crsr_2) {
						unsafe { goto c2v_switch_end_23
						 }
					}
				}
				rc = sqlite3_btree_last(p_crsr_2, &res_4)
				pc_5.nullRow = U8(res_4)
				pc_5.deferredMoveto = U8(0)
				pc_5.cacheStatus = u32(0)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				if p_op.p2 > 0 {
					if res_4 {
						unsafe { goto jump_to_p2
						 }
					}
				}
			}
			33 {
				pc_6 := &VdbeCursor(0)
				p_crsr_3 := &BtCursor(0)
				res_5 := 0
				sz := I64(0)
				pc_6 = p.apCsr[p_op.p1]
				p_crsr_3 = pc_6.uc.pCursor
				rc = sqlite3_btree_first(p_crsr_3, &res_5)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				if res_5 != 0 {
					sz = I64(-1)
				} else {
					sz = sqlite3_btree_row_count_est(p_crsr_3)
					sz = I64(sqlite3_log_est(U64(sz)))
				}
				res_5 = sz >= I64(p_op.p3) && sz <= I64(p_op.p4.i)
				if res_5 {
					unsafe { goto jump_to_p2
					 }
				}
			}
			34, 35 {
				p.aCounter[2]++

				unsafe { goto c2v_case_23_144
				 }
			}
			36 {
				c2v_case_23_144:
				pc_6 := &VdbeCursor(0)
				p_crsr_3 := &BtCursor(0)
				res_5 := 0
				pc_6 = p.apCsr[p_op.p1]
				res_5 = 1
				if (int(pc_6.eCurType) == 1) {
					rc = sqlite3_vdbe_sorter_rewind(pc_6, &res_5)
				} else {
					p_crsr_3 = pc_6.uc.pCursor
					rc = sqlite3_btree_first(p_crsr_3, &res_5)
					pc_6.deferredMoveto = U8(0)
					pc_6.cacheStatus = u32(0)
				}
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				pc_6.nullRow = U8(res_5)
				if p_op.p2 > 0 {
					if res_5 {
						unsafe { goto jump_to_p2
						 }
					}
				}
			}
			37 {
				pc_6 := &VdbeCursor(0)
				p_crsr_3 := &BtCursor(0)
				res_5 := 0
				pc_6 = p.apCsr[p_op.p1]
				p_crsr_3 = pc_6.uc.pCursor
				rc = sqlite3_btree_is_empty(p_crsr_3, &res_5)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				if res_5 {
					unsafe { goto jump_to_p2
					 }
				}
			}
			38 {
				pc_2 = p.apCsr[p_op.p1]
				rc = sqlite3_vdbe_sorter_next(db, pc_2)
				unsafe { goto next_tail
				 }
			}
			39 {
				pc_2 = p.apCsr[p_op.p1]
				rc = sqlite3_btree_previous(pc_2.uc.pCursor, p_op.p3)
				unsafe { goto next_tail
				 }
			}
			40 {
				pc_2 = p.apCsr[p_op.p1]
				rc = sqlite3_btree_next(pc_2.uc.pCursor, p_op.p3)
				next_tail:
				pc_2.cacheStatus = u32(0)
				if rc == 0 {
					pc_2.nullRow = U8(0)
					p.aCounter[p_op.p5]++
					unsafe { goto jump_to_p2_and_check_for_interrupt
					 }
				}
				if rc != 101 {
					unsafe { goto abort_due_to_error
					 }
				}
				rc = 0
				pc_2.nullRow = U8(1)
				unsafe { goto check_for_interrupt
				 }
			}
			140 {
				pc_6 := &VdbeCursor(0)
				x := BtreePayload{}
				pc_6 = p.apCsr[p_op.p1]
				p_in2 = unsafe { a_mem + p_op.p2 }
				if int(p_op.p5) & 1 {
					p.nChange++
				}
				rc = (if (int(p_in2.flags) & 1024) { sqlite3_vdbe_mem_expand_blob(p_in2) } else { 0 })
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				x.nKey = Sqlite3_int64(p_in2.n)
				x.pKey = p_in2.z
				x.aMem = a_mem + p_op.p3
				x.nMem = U16(p_op.p4.i)
				rc = sqlite3_btree_insert(pc_6.uc.pCursor, &x, (int(p_op.p5) & (8 | 2 | 128)), (if (int(p_op.p5) & 16) {
					pc_6.seekResult
				} else {
					0
				}))
				pc_6.cacheStatus = u32(0)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			141 {
				pc_6 := &VdbeCursor(0)
				pc_6 = p.apCsr[p_op.p1]
				p_in2 = unsafe { a_mem + p_op.p2 }
				rc = (if (int(p_in2.flags) & 1024) { sqlite3_vdbe_mem_expand_blob(p_in2) } else { 0 })
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				rc = sqlite3_vdbe_sorter_write(pc_6, p_in2)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			142 {
				pc_6 := &VdbeCursor(0)
				p_crsr_3 := &BtCursor(0)
				res_5 := 0
				r_3 := UnpackedRecord{}
				pc_6 = p.apCsr[p_op.p1]
				p_crsr_3 = pc_6.uc.pCursor
				r_3.pKeyInfo = pc_6.pKeyInfo
				r_3.nField = U16(p_op.p3)
				r_3.default_rc = I8(0)
				r_3.aMem = unsafe { a_mem + p_op.p2 }
				rc = sqlite3_btree_index_moveto(p_crsr_3, &r_3, &res_5)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				if res_5 != 0 {
					rc = sqlite3_vdbe_find_index_key(p_crsr_3, p_op.p4.pIdx, &r_3, &res_5, 0)
					if rc != 0 {
						unsafe { goto abort_due_to_error
						 }
					}
					if res_5 != 0 {
						if !sqlite3_writable_schema(db) {
							rc = sqlite3_report_error((11 | (3 << 8)), 6754, c'index corruption')
							unsafe { goto abort_due_to_error
							 }
						}
						pc_6.cacheStatus = u32(0)
						pc_6.seekResult = 0
						unsafe { goto c2v_switch_end_23
						 }
					}
				}
				rc = sqlite3_btree_delete(p_crsr_3, U8(4))
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				pc_6.cacheStatus = u32(0)
				pc_6.seekResult = 0
			}
			143, 144 {
				pc_6 := &VdbeCursor(0)
				p_tab_cur := &VdbeCursor(0)
				rowid := I64(0)
				pc_6 = p.apCsr[p_op.p1]
				rc = sqlite3_vdbe_cursor_restore(pc_6)
				if rc != 0 {
					unsafe { goto abort_due_to_error
					 }
				}
				if !pc_6.nullRow {
					rowid = I64(0)
					rc = sqlite3_vdbe_idx_rowid(db, pc_6.uc.pCursor, &rowid)
					if rc != 0 {
						unsafe { goto abort_due_to_error
						 }
					}
					if int(p_op.opcode) == 143 {
						p_tab_cur = p.apCsr[p_op.p3]
						p_tab_cur.nullRow = U8(0)
						p_tab_cur.movetoTarget = rowid
						p_tab_cur.deferredMoveto = U8(1)
						p_tab_cur.cacheStatus = u32(0)
						p_tab_cur.ub.aAltMap = p_op.p4.ai
						p_tab_cur.pAltCursor = pc_6
					} else {
						p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
						p_out.u.i = rowid
					}
				} else {
					sqlite3_vdbe_mem_set_null(unsafe { a_mem + p_op.p2 })
				}
			}
			145 {
				pc_7 := &VdbeCursor(0)
				pc_7 = p.apCsr[p_op.p1]
				if pc_7.deferredMoveto {
					rc = sqlite3_vdbe_finish_moveto(pc_7)
					if rc {
						unsafe { goto abort_due_to_error
						 }
					}
				}
			}
			41, 42, 45, 46 {
				pc_7 := &VdbeCursor(0)
				res_5 := 0
				r_3 := UnpackedRecord{}
				pc_7 = p.apCsr[p_op.p1]
				r_3.pKeyInfo = pc_7.pKeyInfo
				r_3.nField = U16(p_op.p4.i)
				if int(p_op.opcode) < 45 {
					r_3.default_rc = I8(-1)
				} else {
					r_3.default_rc = I8(0)
				}
				r_3.aMem = unsafe { a_mem + p_op.p3 }
				n_cell_key := I64(0)
				p_cur_2 := &BtCursor(0)
				m := Mem{}
				p_cur_2 = pc_7.uc.pCursor
				n_cell_key = I64(sqlite3_btree_payload_size(p_cur_2))
				if n_cell_key <= I64(0) || n_cell_key > I64(2147483647) {
					rc = sqlite3_corrupt_error(6966)
					unsafe { goto abort_due_to_error
					 }
				}
				sqlite3_vdbe_mem_init(&m, db, U16(0))
				rc = sqlite3_vdbe_mem_from_btree_zero_offset(p_cur_2, u32(n_cell_key), &m)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				res_5 = sqlite3_vdbe_record_compare_with_skip(m.n, voidptr(m.z), &r_3, 0)
				sqlite3_vdbe_mem_release_malloc(&m)
				if (int(p_op.opcode) & 1) == (45 & 1) {
					res_5 = -res_5
				} else {
					res_5++
				}
				if res_5 > 0 {
					unsafe { goto jump_to_p2
					 }
				}
			}
			146 {
				i_moved := 0
				i_db_2 := 0
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				p_out.flags = U16(1)
				if db.nVdbeRead > db.nVDestroy + 1 {
					rc = 6
					p.errorAction = U8(2)
					unsafe { goto abort_due_to_error
					 }
				} else {
					i_db_2 = p_op.p3
					i_moved = 0
					rc = sqlite3_btree_drop_table(db.aDb[i_db_2].pBt, p_op.p1, &i_moved)
					p_out.flags = U16(4)
					p_out.u.i = I64(i_moved)
					if rc {
						unsafe { goto abort_due_to_error
						 }
					}
					if i_moved != 0 {
						sqlite3_root_page_moved(db, i_db_2, Pgno(i_moved), Pgno(p_op.p1))
						reset_schema_on_fault = U8(i_db_2 + 1)
					}
				}
			}
			147 {
				n_change := I64(0)
				n_change = I64(0)
				rc = sqlite3_btree_clear_table(db.aDb[p_op.p2].pBt, int(u32(p_op.p1)), &n_change)
				if p_op.p3 {
					p.nChange += n_change
					if p_op.p3 > 0 {
						a_mem[p_op.p3].u.i += n_change
					}
				}
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			148 {
				pc_8 := &VdbeCursor(0)
				pc_8 = p.apCsr[p_op.p1]
				if (int(pc_8.eCurType) == 1) {
					sqlite3_vdbe_sorter_reset(db, pc_8.uc.pSorter)
				} else {
					rc = sqlite3_btree_clear_table_of_cursor(pc_8.uc.pCursor)
					if rc {
						unsafe { goto abort_due_to_error
						 }
					}
				}
			}
			149 {
				pgno := Pgno(0)
				p_db_2 := &Db(0)
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				pgno = Pgno(0)
				p_db_2 = unsafe { db.aDb + p_op.p1 }
				rc = sqlite3_btree_create_table(p_db_2.pBt, &pgno, p_op.p3)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				p_out.u.i = I64(pgno)
			}
			150 {
				z_err := &i8(0)
				x_auth := unsafe { Sqlite3_xauth(nil) }
				m_trace := U8(0)
				saved_analysis_limit := 0
				db.nSqlExec++
				z_err = 0
				x_auth = db.xAuth
				m_trace = db.mTrace
				saved_analysis_limit = db.nAnalysisLimit
				if p_op.p1 & 1 {
					db.xAuth = 0
					db.mTrace = U8(0)
				}
				if p_op.p1 & 2 {
					db.nAnalysisLimit = p_op.p2
				}
				rc = sqlite3_exec(db, p_op.p4.z, unsafe { nil }, unsafe { nil }, &&u8(&&i8(c2v_address_of(&z_err))))
				db.nSqlExec--
				db.xAuth = x_auth
				db.mTrace = m_trace
				db.nAnalysisLimit = saved_analysis_limit
				if !isnil(z_err) || rc {
					sqlite3_vdbe_error(p, c'%s', voidptr(z_err))
					sqlite3_free(voidptr(z_err))
					if rc == 7 {
						unsafe { goto no_mem
						 }
					}
					unsafe { goto abort_due_to_error
					 }
				}
			}
			151 {
				i_db_2 := 0
				z_schema := &i8(0)
				z_sql := &i8(0)
				init_data := InitData{}
				i_db_2 = p_op.p1
				if usize(p_op.p4.z) == usize(0) {
					sqlite3_schema_clear(voidptr(db.aDb[i_db_2].pSchema))
					db.mDbFlags &= u32(~16)
					rc = sqlite3_init_one(db, i_db_2, &&u8(&p.zErrMsg), u32(p_op.p5))
					db.mDbFlags |= u32(1)
					p.expired = Bft(0)
				} else {
					z_schema = c'sqlite_master'
					init_data.db = db
					init_data.iDb = i_db_2
					init_data.pzErrMsg = &p.zErrMsg
					init_data.mInitFlags = u32(0)
					init_data.mxPage = sqlite3_btree_last_page(db.aDb[i_db_2].pBt)
					z_sql = sqlite3_mp_rintf(db, c'SELECT*FROM"%w".%s WHERE %s ORDER BY rowid', voidptr(db.aDb[i_db_2].zDbSName), voidptr(z_schema), voidptr(p_op.p4.z))
					if usize(z_sql) == usize(0) {
						rc = 7
					} else {
						db.init.busy = U8(1)
						init_data.rc = 0
						init_data.nInitRow = u32(0)
						rc = sqlite3_exec(db, z_sql, sqlite3_init_callback, voidptr(&init_data), unsafe { &&u8(nil) })
						if rc == 0 {
							rc = init_data.rc
						}
						if rc == 0 && init_data.nInitRow == u32(0) {
							rc = sqlite3_corrupt_error(7259)
						}
						sqlite3_db_free_nn(db, voidptr(z_sql))
						db.init.busy = U8(0)
					}
				}
				if rc {
					sqlite3_reset_all_schemas_of_connection(db)
					if rc == 7 {
						unsafe { goto no_mem
						 }
					}
					unsafe { goto abort_due_to_error
					 }
				}
			}
			152 {
				rc = sqlite3_analysis_load(db, p_op.p1)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			153 {
				sqlite3_unlink_and_delete_table(db, p_op.p1, p_op.p4.z)
			}
			155 {
				sqlite3_unlink_and_delete_index(db, p_op.p1, p_op.p4.z)
			}
			156 {
				sqlite3_unlink_and_delete_trigger(db, p_op.p1, p_op.p4.z)
			}
			157 {
				n_root := 0
				a_root := &Pgno(0)
				n_err := 0
				z := &i8(0)
				pn_err := &Mem(0)
				n_root = p_op.p2
				a_root = p_op.p4.ai
				pn_err = unsafe { a_mem + p_op.p1 }
				p_in1 = unsafe { a_mem + (p_op.p1 + 1) }
				rc = sqlite3_btree_integrity_check(db, db.aDb[p_op.p5].pBt, unsafe { a_root + 1 }, unsafe { &Sqlite3_value(a_mem + p_op.p3) }, n_root, int(pn_err.u.i) + 1, &n_err, &&u8(&&i8(c2v_address_of(&z))))
				sqlite3_vdbe_mem_set_null(p_in1)
				if n_err == 0 {
				} else if rc {
					sqlite3_free(voidptr(z))
					unsafe { goto abort_due_to_error
					 }
				} else {
					pn_err.u.i -= I64(n_err - 1)
					sqlite3_vdbe_mem_set_str(p_in1, z, I64(-1), U8(1), sqlite3_free)
				}
				sqlite3_vdbe_change_encoding(p_in1, int(encoding))
				unsafe { goto check_for_interrupt
				 }
			}
			47 {
				pc_8 := &VdbeCursor(0)
				res_6 := 0
				r_4 := UnpackedRecord{}
				pc_8 = p.apCsr[p_op.p1]
				C.memset(voidptr(&r_4), 0, sizeof(r_4))
				r_4.aMem = unsafe { a_mem + p_op.p3 }
				r_4.nField = p_op.p4.pIdx.nColumn
				r_4.pKeyInfo = pc_8.pKeyInfo
				rc = sqlite3_vdbe_find_index_key(pc_8.uc.pCursor, p_op.p4.pIdx, &r_4, &res_6, 1)
				if rc || res_6 != 0 {
					rc = 0
					unsafe { goto jump_to_p2
					 }
				}
				pc_8.nullRow = U8(0)
				unsafe { goto c2v_switch_end_23
				 }

				unsafe { goto c2v_case_23_190
				 }
			}
			158 {
				c2v_case_23_190:
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_in2 = unsafe { a_mem + p_op.p2 }
				if (int(p_in1.flags) & 16) == 0 {
					if sqlite3_vdbe_mem_set_row_set(p_in1) {
						unsafe { goto no_mem
						 }
					}
				}
				sqlite3_row_set_insert(&RowSet(voidptr(p_in1.z)), p_in2.u.i)
			}
			48 {
				val := I64(0)
				p_in1 = unsafe { a_mem + p_op.p1 }
				if (int(p_in1.flags) & 16) == 0 || sqlite3_row_set_next(&RowSet(voidptr(p_in1.z)), &val) == 0 {
					sqlite3_vdbe_mem_set_null(p_in1)
					unsafe { goto jump_to_p2_and_check_for_interrupt
					 }
				} else {
					sqlite3_vdbe_mem_set_int64(unsafe { a_mem + p_op.p3 }, val)
				}
				unsafe { goto check_for_interrupt
				 }
			}
			49 {
				i_set := 0
				exists := 0
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_in3 = unsafe { a_mem + p_op.p3 }
				i_set = p_op.p4.i
				if (int(p_in1.flags) & 16) == 0 {
					if sqlite3_vdbe_mem_set_row_set(p_in1) {
						unsafe { goto no_mem
						 }
					}
				}
				if i_set {
					exists = sqlite3_row_set_test(&RowSet(voidptr(p_in1.z)), i_set, p_in3.u.i)
					if exists {
						unsafe { goto jump_to_p2
						 }
					}
				}
				if i_set >= 0 {
					sqlite3_row_set_insert(&RowSet(voidptr(p_in1.z)), p_in3.u.i)
				}
			}
			50 {
				n_mem := 0
				n_byte := I64(0)
				p_rt := &Mem(0)
				p_mem := &Mem(0)
				p_end := &Mem(0)
				p_frame := &VdbeFrame(0)
				p_program := &SubProgram(0)
				t := &voidptr(0)
				p_program = p_op.p4.pProgram
				p_rt = unsafe { a_mem + p_op.p3 }
				if p_op.p5 {
					t = p_program.token
					for p_frame = p.pFrame; !isnil(p_frame) && usize(p_frame.token) != usize(t); p_frame = p_frame.pParent {
					}
					if p_frame {
						unsafe { goto c2v_switch_end_23
						 }
					}
				}
				if p.nFrame >= db.aLimit[10] {
					rc = 1
					sqlite3_vdbe_error(p, c'too many levels of trigger recursion')
					unsafe { goto abort_due_to_error
					 }
				}
				if (int(p_rt.flags) & 16) == 0 {
					n_mem = p_program.nMem + p_program.nCsr
					if p_program.nCsr == 0 {
						n_mem++
					}
					n_byte = I64((((sizeof(VdbeFrame)) + u64(7)) & u64(~7)) + u64(n_mem) * sizeof(Mem) + u64(p_program.nCsr) * sizeof(voidptr) + u64((I64(7) + I64(p_program.nOp)) / I64(8)))
					p_frame = sqlite3_db_malloc_zero(db, U64(n_byte))
					if isnil(p_frame) {
						unsafe { goto no_mem
						 }
					}
					sqlite3_vdbe_mem_release(p_rt)
					p_rt.flags = U16(16 | 4096)
					p_rt.z = &i8(voidptr(p_frame))
					p_rt.n = int(n_byte)
					p_rt.xDel = sqlite3_vdbe_frame_mem_del
					p_frame.v = p
					p_frame.nChildMem = n_mem
					p_frame.nChildCsr = p_program.nCsr
					p_frame.pc = int((i64((isize(p_op) - isize(a_op)) / isize(sizeof(Op)))))
					p_frame.aMem = p.aMem
					p_frame.nMem = p.nMem
					p_frame.apCsr = p.apCsr
					p_frame.nCursor = p.nCursor
					p_frame.aOp = p.aOp
					p_frame.nOp = p.nOp
					p_frame.token = p_program.token
					p_end = unsafe { (&Mem(voidptr((&U8(voidptr(p_frame))) + (((sizeof(VdbeFrame)) + u64(7)) & u64(~7))))) + p_frame.nChildMem }
					for p_mem = (&Mem(voidptr(unsafe { (&U8(voidptr(p_frame))) + (((sizeof(VdbeFrame)) + u64(7)) & u64(~7)) }))); usize(p_mem) != usize(p_end); p_mem = unsafe { p_mem + 1 } {
						p_mem.flags = U16(0)
						p_mem.db = db
					}
				} else {
					p_frame = &VdbeFrame(voidptr(p_rt.z))
				}
				p.nFrame++
				p_frame.pParent = p.pFrame
				p_frame.lastRowid = db.lastRowid
				p_frame.nChange = p.nChange
				p_frame.nDbChange = p.db.nChange
				p_frame.pAuxData = p.pAuxData
				p.pAuxData = 0
				p.nChange = I64(0)
				p.pFrame = p_frame
				a_mem = (&Mem(voidptr(unsafe { (&U8(voidptr(p_frame))) + (((sizeof(VdbeFrame)) + u64(7)) & u64(~7)) })))
				p.aMem = a_mem
				p.nMem = p_frame.nChildMem
				p.nCursor = int(U16(p_frame.nChildCsr))
				p.apCsr = &&VdbeCursor(voidptr(unsafe { a_mem + p.nMem }))
				p_frame.aOnce = &U8(voidptr(unsafe { p.apCsr + p_program.nCsr }))
				C.memset(voidptr(p_frame.aOnce), 0, u64((p_program.nOp + 7) / 8))
				a_op = p_program.aOp
				p.aOp = a_op
				p.nOp = p_program.nOp
				p_op = unsafe { a_op + -1 }
				unsafe { goto check_for_interrupt
				 }
			}
			159 {
				p_frame := &VdbeFrame(0)
				p_in := &Mem(0)
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				p_frame = p.pFrame
				p_in = unsafe { p_frame.aMem + (p_op.p1 + p_frame.aOp[p_frame.pc].p1) }
				sqlite3_vdbe_mem_shallow_copy(p_out, p_in, 16384)
			}
			160 {
				if p_op.p1 {
					db.nDeferredCons += I64(p_op.p2)
				} else {
					if db.flags & U64(524288) {
						db.nDeferredImmCons += I64(p_op.p2)
					} else {
						p.nFkConstraint += I64(p_op.p2)
					}
				}
			}
			60 {
				if p_op.p1 {
					if db.nDeferredCons == I64(0) && db.nDeferredImmCons == I64(0) {
						unsafe { goto jump_to_p2
						 }
					}
				} else {
					if p.nFkConstraint == I64(0) && db.nDeferredImmCons == I64(0) {
						unsafe { goto jump_to_p2
						 }
					}
				}
			}
			161 {
				p_frame := &VdbeFrame(0)
				if p.pFrame {
					for p_frame = p.pFrame; p_frame.pParent; p_frame = p_frame.pParent {
					}
					p_in1 = unsafe { p_frame.aMem + p_op.p1 }
				} else {
					p_in1 = unsafe { a_mem + p_op.p1 }
				}
				sqlite3_vdbe_mem_integerify(p_in1)
				p_in2 = unsafe { a_mem + p_op.p2 }
				sqlite3_vdbe_mem_integerify(p_in2)
				if p_in1.u.i < p_in2.u.i {
					p_in1.u.i = p_in2.u.i
				}
			}
			61 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				if p_in1.u.i > I64(0) {
					p_in1.u.i -= I64(p_op.p3)
					unsafe { goto jump_to_p2
					 }
				}
			}
			162 {
				x := I64(0)
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_in3 = unsafe { a_mem + p_op.p3 }
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				x = p_in1.u.i
				if x <= I64(0) || sqlite3_add_int64(&x, if p_in3.u.i > I64(0) {
					p_in3.u.i
				} else {
					I64(0)
				}) {
					p_out.u.i = I64(-1)
				} else {
					p_out.u.i = x
				}
			}
			62 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				if p_in1.u.i {
					if p_in1.u.i > I64(0) {
						p_in1.u.i--
					}
					unsafe { goto jump_to_p2
					 }
				}
			}
			63 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				if p_in1.u.i > ((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32))) {
					p_in1.u.i--
				}
				if p_in1.u.i == I64(0) {
					unsafe { goto jump_to_p2
					 }
				}
			}
			163, 164 {
				n := 0
				p_ctx := &Sqlite3_context(0)
				n_alloc := U64(0)
				n = int(p_op.p5)
				n_alloc = U64(((u64(usize(__offsetof(Sqlite3_context, argv)))) + u64(n) * sizeof(voidptr)))
				p_ctx = sqlite3_db_malloc_raw_nn(db, n_alloc + U64(sizeof(Mem)))
				if usize(p_ctx) == usize(0) {
					unsafe { goto no_mem
					 }
				}
				p_ctx.pOut = &Mem(voidptr((&U8(voidptr(p_ctx)) + n_alloc)))
				sqlite3_vdbe_mem_init(p_ctx.pOut, db, U16(1))
				p_ctx.pMem = 0
				p_ctx.pFunc = p_op.p4.pFunc
				p_ctx.iOp = int((i64((isize(p_op) - isize(a_op)) / isize(sizeof(Op)))))
				p_ctx.pVdbe = p
				p_ctx.skipFlag = U8(0)
				p_ctx.isError = 0
				p_ctx.enc = encoding
				p_ctx.argc = U16(n)
				p_op.p4type = i8((-16))
				p_op.p4.pCtx = p_ctx
				p_op.opcode = U8(165)

				unsafe { goto c2v_case_23_203
				 }
			}
			165 {
				c2v_case_23_203:
				i := 0
				p_ctx_2 := &Sqlite3_context(0)
				p_mem := &Mem(0)
				p_ctx_2 = p_op.p4.pCtx
				p_mem = unsafe { a_mem + p_op.p3 }
				if usize(p_ctx_2.pMem) != usize(p_mem) {
					p_ctx_2.pMem = p_mem
					for i = int(p_ctx_2.argc) - 1; i >= 0; i-- {
						(&p_ctx_2.argv[0])[i] = unsafe { a_mem + (p_op.p2 + i) }
					}
				}
				p_mem.n++
				if p_op.p1 {
					p_ctx_2.pFunc.xInverse(p_ctx_2, int(p_ctx_2.argc), &&Sqlite3_value(&p_ctx_2.argv[0]))
				} else {
					p_ctx_2.pFunc.xSFunc(p_ctx_2, int(p_ctx_2.argc), &&Sqlite3_value(&p_ctx_2.argv[0]))
				}
				if p_ctx_2.isError {
					if p_ctx_2.isError > 0 {
						sqlite3_vdbe_error(p, c'%s', voidptr(sqlite3_value_text(unsafe { &Sqlite3_value(p_ctx_2.pOut) })))
						rc = p_ctx_2.isError
					}
					if p_ctx_2.skipFlag {
						i = p_op[-1].p1
						if i {
							sqlite3_vdbe_mem_set_int64(unsafe { a_mem + i }, I64(1))
						}
						p_ctx_2.skipFlag = U8(0)
					}
					sqlite3_vdbe_mem_release(p_ctx_2.pOut)
					p_ctx_2.pOut.flags = U16(1)
					p_ctx_2.isError = 0
					if rc {
						unsafe { goto abort_due_to_error
						 }
					}
				}
			}
			166, 167 {
				p_mem := &Mem(0)
				p_mem = unsafe { a_mem + p_op.p1 }
				if p_op.p3 {
					rc = sqlite3_vdbe_mem_agg_value(p_mem, unsafe { a_mem + p_op.p3 }, p_op.p4.pFunc)
					p_mem = unsafe { a_mem + p_op.p3 }
				} else {
					rc = sqlite3_vdbe_mem_finalize(p_mem, p_op.p4.pFunc)
				}
				if rc {
					sqlite3_vdbe_error(p, c'%s', voidptr(sqlite3_value_text(unsafe { &Sqlite3_value(p_mem) })))
					unsafe { goto abort_due_to_error
					 }
				}
				sqlite3_vdbe_change_encoding(p_mem, int(encoding))
			}
			3 {
				i := 0
				a_res := [3]int{}
				p_mem_2 := &Mem(0)
				a_res[0] = 0
				a_res[2] = -1
				a_res[1] = a_res[2]
				rc = sqlite3_checkpoint(db, p_op.p1, p_op.p2, unsafe { &a_res[0] + 1 }, unsafe { &a_res[0] + 2 })
				if rc {
					if rc != 5 {
						unsafe { goto abort_due_to_error
						 }
					}
					rc = 0
					a_res[0] = 1
				}
				i = 0
				for p_mem_2 = unsafe { a_mem + p_op.p3 }; i < 3; i++ {
					sqlite3_vdbe_mem_set_int64(p_mem_2, I64(a_res[i]))
					c2v_pointer_postfix(voidptr(&p_mem_2), p_mem_2, isize(1))
				}
				unsafe { goto c2v_switch_end_23
				 }

				unsafe { goto c2v_case_23_207
				 }
			}
			4 {
				c2v_case_23_207:
				p_bt := &Btree(0)
				p_pager := &Pager(0)
				e_new := 0
				e_old := 0
				z_filename := &i8(0)
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				e_new = p_op.p3
				p_bt = db.aDb[p_op.p1].pBt
				p_pager = sqlite3_btree_pager(p_bt)
				e_old = sqlite3_pager_get_journal_mode(p_pager)
				if e_new == (-1) {
					e_new = e_old
				}
				if !sqlite3_pager_ok_to_change_journal_mode(p_pager) {
					e_new = e_old
				}
				z_filename = sqlite3_pager_filename(p_pager, 1)
				if e_new == 5 && (sqlite3_strlen30(z_filename) == 0 || !sqlite3_pager_wal_supported(p_pager)) {
					e_new = e_old
				}
				if (e_new != e_old) && (e_old == 5 || e_new == 5) {
					if !db.autoCommit || db.nVdbeRead > 1 {
						rc = 1
						sqlite3_vdbe_error(p, c'cannot change %s wal mode from within a transaction', voidptr((if e_new == 5 {
							c'into'
						} else {
							c'out of'
						})))
						unsafe { goto abort_due_to_error
						 }
					} else {
						if e_old == 5 {
							rc = sqlite3_pager_close_wal(p_pager, db)
							if rc == 0 {
								sqlite3_pager_set_journal_mode(p_pager, e_new)
							}
						} else if e_old == 4 {
							sqlite3_pager_set_journal_mode(p_pager, 2)
						}
						if rc == 0 {
							rc = sqlite3_btree_set_version(p_bt, (if e_new == 5 { 2 } else { 1 }))
						}
					}
				}
				if rc {
					e_new = e_old
				}
				e_new = sqlite3_pager_set_journal_mode(p_pager, e_new)
				p_out.flags = U16(2 | 8192 | 512)
				p_out.z = &i8(sqlite3_journal_modename(e_new))
				p_out.n = sqlite3_strlen30(p_out.z)
				p_out.enc = U8(1)
				sqlite3_vdbe_change_encoding(p_out, int(encoding))
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				unsafe { goto c2v_switch_end_23
				 }

				unsafe { goto c2v_case_23_209
				 }
			}
			5 {
				c2v_case_23_209:
				rc = sqlite3_run_vacuum(&&u8(&p.zErrMsg), db, p_op.p1, unsafe { if p_op.p2 {
					&Sqlite3_value(a_mem + p_op.p2)
				} else {
					&Sqlite3_value(nil)
				} })
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			64 {
				p_bt := &Btree(0)
				p_bt = db.aDb[p_op.p1].pBt
				rc = sqlite3_btree_incr_vacuum(p_bt)
				if rc {
					if rc != 101 {
						unsafe { goto abort_due_to_error
						 }
					}
					rc = 0
					unsafe { goto jump_to_p2
					 }
				}
			}
			168 {
				if !p_op.p1 {
					sqlite3_expire_prepared_statements(db, p_op.p2)
				} else {
					p.expired = Bft(p_op.p2 + 1)
				}
			}
			169 {
				pc_8 := &VdbeCursor(0)
				pc_8 = p.apCsr[p_op.p1]
				sqlite3_btree_cursor_pin(pc_8.uc.pCursor)
			}
			170 {
				pc_8 := &VdbeCursor(0)
				pc_8 = p.apCsr[p_op.p1]
				sqlite3_btree_cursor_unpin(pc_8.uc.pCursor)
			}
			171 {
				is_write_lock := U8(p_op.p3)
				if int(is_write_lock) || U64(0) == (db.flags & (U64(4) << 32)) {
					p1 := p_op.p1
					rc = sqlite3_btree_lock_table(db.aDb[p1].pBt, p_op.p2, is_write_lock)
					if rc {
						if (rc & 255) == 6 {
							z := p_op.p4.z
							sqlite3_vdbe_error(p, c'database table is locked: %s', voidptr(z))
						}
						unsafe { goto abort_due_to_error
						 }
					}
				}
			}
			172 {
				pvt_ab := &VTable(0)
				pvt_ab = p_op.p4.pVtab
				rc = sqlite3_vtab_begin(db, pvt_ab)
				if pvt_ab {
					sqlite3_vtab_import_errmsg(p, pvt_ab.pVtab)
				}
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			173 {
				s_mem := Mem{}
				z_tab := &i8(0)
				C.memset(voidptr(&s_mem), 0, sizeof(s_mem))
				s_mem.db = db
				rc = sqlite3_vdbe_mem_copy(&s_mem, unsafe { a_mem + p_op.p2 })
				z_tab = &i8(voidptr(sqlite3_value_text(unsafe { &Sqlite3_value(&s_mem) })))
				if z_tab {
					rc = sqlite3_vtab_call_create(db, p_op.p1, z_tab, &&u8(&p.zErrMsg))
				}
				sqlite3_vdbe_mem_release(&s_mem)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			174 {
				db.nVDestroy++
				rc = sqlite3_vtab_call_destroy(db, p_op.p1, p_op.p4.z)
				db.nVDestroy--
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			175 {
				p_cur_3 := &VdbeCursor(0)
				pvc_ur := &Sqlite3_vtab_cursor(0)
				p_vtab := &Sqlite3_vtab(0)
				p_module := &Sqlite3_module(0)
				p_cur_3 = p.apCsr[p_op.p1]
				if usize(p_cur_3) != usize(0) && (int(p_cur_3.eCurType) == 2) && (usize(p_cur_3.uc.pVCur.pVtab) == usize(p_op.p4.pVtab.pVtab)) {
					unsafe { goto c2v_switch_end_23
					 }
				}
				pvc_ur = 0
				p_vtab = p_op.p4.pVtab.pVtab
				if usize(p_vtab) == usize(0) || (usize(p_vtab.pModule) == usize(0)) {
					rc = 6
					unsafe { goto abort_due_to_error
					 }
				}
				p_module = p_vtab.pModule
				rc = p_module.xOpen(p_vtab, &&Sqlite3_vtab_cursor(&&Sqlite3_vtab_cursor(c2v_address_of(&pvc_ur))))
				sqlite3_vtab_import_errmsg(p, p_vtab)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				pvc_ur.pVtab = p_vtab
				p_cur_3 = allocate_cursor(p, p_op.p1, 0, U8(2))
				if p_cur_3 {
					p_cur_3.uc.pVCur = pvc_ur
					p_vtab.nRef++
				} else {
					p_module.xClose(pvc_ur)
					unsafe { goto no_mem
					 }
				}
			}
			176 {
				p_tab := &Table(0)
				p_vtab := &Sqlite3_vtab(0)
				p_module := &Sqlite3_module(0)
				z_err := unsafe { &i8(nil) }
				p_out = unsafe { a_mem + p_op.p2 }
				sqlite3_vdbe_mem_set_null(p_out)
				p_tab = p_op.p4.pTab
				if usize(p_tab.u.vtab.p) == usize(0) {
					unsafe { goto c2v_switch_end_23
					 }
				}
				p_vtab = p_tab.u.vtab.p.pVtab
				p_module = p_vtab.pModule
				sqlite3_vtab_lock(p_tab.u.vtab.p)
				rc = p_module.xIntegrity(p_vtab, db.aDb[p_op.p1].zDbSName, p_tab.zName, p_op.p3, &&u8(&&i8(c2v_address_of(&z_err))))
				sqlite3_vtab_unlock(p_tab.u.vtab.p)
				if rc {
					sqlite3_free(voidptr(z_err))
					unsafe { goto abort_due_to_error
					 }
				}
				if z_err {
					sqlite3_vdbe_mem_set_str(p_out, z_err, I64(-1), U8(1), sqlite3_free)
				}
			}
			177 {
				pc_8 := &VdbeCursor(0)
				p_rhs := &ValueList(0)
				pc_8 = p.apCsr[p_op.p1]
				p_rhs = sqlite3_malloc64(Sqlite3_uint64(sizeof(ValueList)))
				if usize(p_rhs) == usize(0) {
					unsafe { goto no_mem
					 }
				}
				p_rhs.pCsr = pc_8.uc.pCursor
				p_rhs.pOut = unsafe { a_mem + p_op.p3 }
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				p_out.flags = U16(1)
				sqlite3_vdbe_mem_set_pointer(p_out, voidptr(p_rhs), c'ValueList', sqlite3_vdbe_value_list_free)
			}
			6 {
				n_arg := 0
				i_query := 0
				p_module := &Sqlite3_module(0)
				p_query := &Mem(0)
				p_argc := &Mem(0)
				pvc_ur := &Sqlite3_vtab_cursor(0)
				p_vtab := &Sqlite3_vtab(0)
				p_cur_3 := &VdbeCursor(0)
				res_6 := 0
				i := 0
				ap_arg := &&Mem(0)
				p_query = unsafe { a_mem + p_op.p3 }
				p_argc = unsafe { p_query + 1 }
				p_cur_3 = p.apCsr[p_op.p1]
				pvc_ur = p_cur_3.uc.pVCur
				p_vtab = pvc_ur.pVtab
				p_module = p_vtab.pModule
				n_arg = int(p_argc.u.i)
				i_query = int(p_query.u.i)
				ap_arg = p.apArg
				for i = 0; i < n_arg; i++ {
					ap_arg[i] = unsafe { p_argc + (i + 1) }
				}
				rc = p_module.xFilter(pvc_ur, i_query, p_op.p4.z, n_arg, unsafe { &&Sqlite3_value(ap_arg) })
				sqlite3_vtab_import_errmsg(p, p_vtab)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				res_6 = p_module.xEof(pvc_ur)
				p_cur_3.nullRow = U8(0)
				if res_6 {
					unsafe { goto jump_to_p2
					 }
				}
			}
			178 {
				p_vtab := &Sqlite3_vtab(0)
				p_module := &Sqlite3_module(0)
				p_dest := &Mem(0)
				s_context := Sqlite3_context{}
				null_func := FuncDef{}
				p_cur_3 := p.apCsr[p_op.p1]
				p_dest = unsafe { a_mem + p_op.p3 }
				if p_cur_3.nullRow {
					sqlite3_vdbe_mem_set_null(p_dest)
					unsafe { goto c2v_switch_end_23
					 }
				}
				p_vtab = p_cur_3.uc.pVCur.pVtab
				p_module = p_vtab.pModule
				C.memset(voidptr(&s_context), 0, sizeof(s_context))
				s_context.pOut = p_dest
				s_context.enc = encoding
				null_func.pUserData = 0
				null_func.funcFlags = u32(16777216)
				s_context.pFunc = &null_func
				if int(p_op.p5) & 1 {
					sqlite3_vdbe_mem_set_null(p_dest)
					p_dest.flags = U16(1 | 1024)
					p_dest.u.nZero = 0
				} else {
					p_dest.flags = U16((int(p_dest.flags) & ~(3519 | 1024)) | 1)
				}
				rc = p_module.xColumn(p_cur_3.uc.pVCur, &s_context, p_op.p2)
				sqlite3_vtab_import_errmsg(p, p_vtab)
				if s_context.isError > 0 {
					sqlite3_vdbe_error(p, c'%s', voidptr(sqlite3_value_text(unsafe { &Sqlite3_value(p_dest) })))
					rc = s_context.isError
				}
				sqlite3_vdbe_change_encoding(p_dest, int(encoding))
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			65 {
				p_vtab := &Sqlite3_vtab(0)
				p_module := &Sqlite3_module(0)
				res_6 := 0
				p_cur_3 := &VdbeCursor(0)
				p_cur_3 = p.apCsr[p_op.p1]
				if p_cur_3.nullRow {
					unsafe { goto c2v_switch_end_23
					 }
				}
				p_vtab = p_cur_3.uc.pVCur.pVtab
				p_module = p_vtab.pModule
				rc = p_module.xNext(p_cur_3.uc.pVCur)
				sqlite3_vtab_import_errmsg(p, p_vtab)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				res_6 = p_module.xEof(p_cur_3.uc.pVCur)
				if !res_6 {
					unsafe { goto jump_to_p2_and_check_for_interrupt
					 }
				}
				unsafe { goto check_for_interrupt
				 }
			}
			179 {
				p_vtab := &Sqlite3_vtab(0)
				p_name := &Mem(0)
				is_legacy := 0
				is_legacy = int((db.flags & U64(67108864)))
				db.flags |= U64(67108864)
				p_vtab = p_op.p4.pVtab.pVtab
				p_name = unsafe { a_mem + p_op.p1 }
				rc = sqlite3_vdbe_change_encoding(p_name, 1)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
				rc = p_vtab.pModule.xRename(p_vtab, p_name.z)
				if is_legacy == 0 {
					db.flags &= ~U64(67108864)
				}
				sqlite3_vtab_import_errmsg(p, p_vtab)
				p.expired = Bft(0)
				if rc {
					unsafe { goto abort_due_to_error
					 }
				}
			}
			7 {
				p_vtab := &Sqlite3_vtab(0)
				p_module := &Sqlite3_module(0)
				n_arg := 0
				i := 0
				rowid_2 := Sqlite_int64(0)
				ap_arg := &&Mem(0)
				px_2 := &Mem(0)
				if db.mallocFailed {
					unsafe { goto no_mem
					 }
				}
				p_vtab = p_op.p4.pVtab.pVtab
				if usize(p_vtab) == usize(0) || (usize(p_vtab.pModule) == usize(0)) {
					rc = 6
					unsafe { goto abort_due_to_error
					 }
				}
				p_module = p_vtab.pModule
				n_arg = p_op.p2
				if p_module.xUpdate {
					vtab_on_conflict := db.vtabOnConflict
					ap_arg = p.apArg
					px_2 = unsafe { a_mem + p_op.p3 }
					for i = 0; i < n_arg; i++ {
						ap_arg[i] = px_2
						c2v_pointer_postfix(voidptr(&px_2), px_2, isize(1))
					}
					db.vtabOnConflict = U8(p_op.p5)
					rc = p_module.xUpdate(p_vtab, n_arg, unsafe { &&Sqlite3_value(ap_arg) }, unsafe { &Sqlite3_int64(&rowid_2) })
					db.vtabOnConflict = vtab_on_conflict
					sqlite3_vtab_import_errmsg(p, p_vtab)
					if rc == 0 && p_op.p1 {
						db.lastRowid = rowid_2
					}
					if (rc & 255) == 19 && int(p_op.p4.pVtab.bConstraint) {
						if int(p_op.p5) == 4 {
							rc = 0
						} else {
							p.errorAction = U8((if (int(p_op.p5) == 5) { 2 } else { int(p_op.p5) }))
						}
					} else {
						p.nChange++
					}
					if rc {
						unsafe { goto abort_due_to_error
						 }
					}
				}
			}
			180 {
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				p_out.u.i = I64(sqlite3_btree_last_page(db.aDb[p_op.p1].pBt))
			}
			181 {
				new_max := u32(0)
				p_bt := &Btree(0)
				p_out = out2_prerelease(p, unsafe { &VdbeOp(p_op) })
				p_bt = db.aDb[p_op.p1].pBt
				new_max = u32(0)
				if p_op.p3 {
					new_max = sqlite3_btree_last_page(p_bt)
					if new_max < u32(p_op.p3) {
						new_max = u32(p_op.p3)
					}
				}
				p_out.u.i = I64(sqlite3_btree_max_page_count(p_bt, new_max))
			}
			67, 68 {
				i := 0
				p_ctx_2 := &Sqlite3_context(0)
				p_ctx_2 = p_op.p4.pCtx
				p_out = unsafe { a_mem + p_op.p3 }
				if usize(p_ctx_2.pOut) != usize(p_out) {
					p_ctx_2.pVdbe = p
					p_ctx_2.pOut = p_out
					p_ctx_2.enc = encoding
					for i = int(p_ctx_2.argc) - 1; i >= 0; i-- {
						(&p_ctx_2.argv[0])[i] = unsafe { a_mem + (p_op.p2 + i) }
					}
				}
				p_out.flags = U16((int(p_out.flags) & ~(3519 | 1024)) | 1)
				p_ctx_2.pFunc.xSFunc(p_ctx_2, int(p_ctx_2.argc), &&Sqlite3_value(&p_ctx_2.argv[0]))
				if p_ctx_2.isError {
					if p_ctx_2.isError > 0 {
						sqlite3_vdbe_error(p, c'%s', voidptr(sqlite3_value_text(unsafe { &Sqlite3_value(p_out) })))
						rc = p_ctx_2.isError
					}
					sqlite3_vdbe_delete_aux_data(db, &&AuxData(&p.pAuxData), p_ctx_2.iOp, p_op.p1)
					p_ctx_2.isError = 0
					if rc {
						unsafe { goto abort_due_to_error
						 }
					}
				}
			}
			182 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_in1.flags &= ~2048
			}
			183 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_out = unsafe { a_mem + p_op.p2 }
				if int(p_in1.flags) & 2048 {
					sqlite3_vdbe_mem_set_int64(p_out, I64(p_in1.eSubtype))
				} else {
					sqlite3_vdbe_mem_set_null(p_out)
				}
			}
			184 {
				p_in1 = unsafe { a_mem + p_op.p1 }
				p_out = unsafe { a_mem + p_op.p2 }
				if int(p_in1.flags) & 1 {
					p_out.flags &= ~2048
				} else {
					p_out.flags |= 2048
					p_out.eSubtype = U8((p_in1.u.i & I64(255)))
				}
			}
			185 {
				h := U64(0)
				p_in1 = unsafe { a_mem + p_op.p1 }
				h = filter_hash(a_mem, p_op)
				h %= U64((p_in1.n * 8))
				p_in1.z[h / U64(8)] |= 1 << u64((h & U64(7)))
			}
			66 {
				h := U64(0)
				p_in1 = unsafe { a_mem + p_op.p1 }
				h = filter_hash(a_mem, p_op)
				h %= U64((p_in1.n * 8))
				if (int(p_in1.z[h / U64(8)]) & (1 << u64((h & U64(7))))) == 0 {
					p.aCounter[8]++
					unsafe { goto jump_to_p2
					 }
				} else {
					p.aCounter[7]++
				}
			}
			186, 8 {
				i_2 := 0
				z_trace := &i8(0)
				if (int(db.mTrace) & (1 | 64)) != 0 && int(p.minWriteFileFormat) != 254 && usize(c2v_assign[&i8](unsafe { &z_trace }, (if p_op.p4.z {
					p_op.p4.z
				} else {
					p.zSql
				}))) != usize(0) {
					if int(db.mTrace) & 64 {
						z := sqlite3_vdbe_expand_sql(p, z_trace)
						db.trace.xLegacy(voidptr(db.pTraceArg), z)
						sqlite3_free(voidptr(z))
					} else if db.nVdbeExec > 1 {
						z := sqlite3_mp_rintf(db, c'-- %s', voidptr(z_trace))
						db.trace.xV2(u32(1), voidptr(db.pTraceArg), voidptr(p), voidptr(z))
						sqlite3_db_free(db, voidptr(z))
					} else {
						db.trace.xV2(u32(1), voidptr(db.pTraceArg), voidptr(p), voidptr(z_trace))
					}
				}
				if p_op.p1 >= sqlite3Config.iOnceResetThreshold {
					if int(p_op.opcode) == 186 {
						unsafe { goto c2v_switch_end_23
						 }
					}
					for i_2 = 1; i_2 < p.nOp; i_2++ {
						if int(p.aOp[i_2].opcode) == 15 {
							p.aOp[i_2].p1 = 0
						}
					}
					p_op.p1 = 0
				}
				p_op.p1++
				p.aCounter[6]++
				unsafe { goto jump_to_p2
				 }
			}
			else {
			}
		}
		c2v_switch_end_23:
	}
	abort_due_to_error:
	if db.mallocFailed {
		rc = 7
	} else if rc == (10 | (33 << 8)) {
		rc = sqlite3_corrupt_error(9381)
	}
	if usize(p.zErrMsg) == usize(0) && rc != (10 | (12 << 8)) {
		sqlite3_vdbe_error(p, c'%s', voidptr(sqlite3_err_str(rc)))
	}
	p.rc = rc
	sqlite3_system_error(db, rc)
	sqlite3_vdbe_log_abort(p, rc, p_op, a_op)
	if int(p.eVdbeState) == 2 {
		sqlite3_vdbe_halt(p)
	}
	if rc == (10 | (12 << 8)) {
		sqlite3_oom_fault(db)
	}
	if rc == 11 && int(db.autoCommit) == 0 {
		db.flags |= (U64(2) << 32)
	}
	rc = 1
	if int(reset_schema_on_fault) > 0 {
		sqlite3_reset_one_schema(db, int(reset_schema_on_fault) - 1)
	}
	vdbe_return: for n_vm_step >= n_progress_limit && !isnil(db.xProgress) {
		n_progress_limit += U64(db.nProgressOps)
		if db.xProgress(voidptr(db.pProgressArg)) {
			n_progress_limit = (U64(u32(4294967295)) | ((U64(u32(4294967295))) << 32))
			rc = 9
			unsafe { goto abort_due_to_error
			 }
		}
	}
	p.aCounter[4] += u32(int(n_vm_step))
	if (p.lockMask != YDbMask(0)) {
		sqlite3_vdbe_leave(p)
	}
	return rc
	too_big:
	sqlite3_vdbe_error(p, c'string or blob too big')
	rc = 18
	unsafe { goto abort_due_to_error
	 }
	no_mem:
	sqlite3_oom_fault(db)
	sqlite3_vdbe_error(p, c'out of memory')
	rc = 7
	unsafe { goto abort_due_to_error
	 }
	abort_due_to_interrupt:
	rc = 9
	unsafe { goto abort_due_to_error
	 }
	return 0
}
