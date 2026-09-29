@[translated]
module main

@[c:'vdbeMemRenderNum']
fn vdbe_mem_render_num(sz int, z_buf &i8, p &Mem) {
	acc := StrAccum{}
	if int(p.flags) & (4 | 32) {
		p.n = sqlite3_int64_to_text(p.u.i, z_buf)
		if int(p.flags) & 32 {
			C.memcpy(voidptr(z_buf + p.n), voidptr(c'.0'), u64(3))
			p.n += 2
		}
	} else {
		sqlite3_str_accum_init(&acc, unsafe { nil }, z_buf, sz, 0)
		sqlite3_str_appendf(unsafe { &Sqlite3_str(&acc) }, c'%!.*g', (if p.db {
			int(p.db.nFpDigit)
		} else {
			17
		}), p.u.r)
		z_buf[acc.nChar] = i8(0)
		p.n = int(acc.nChar)
	}
}

@[c:'sqlite3VdbeChangeEncoding']
fn sqlite3_vdbe_change_encoding(p_mem &Mem, desired_enc int) int {
	rc := 0
	if !(int(p_mem.flags) & 2) {
		p_mem.enc = U8(desired_enc)
		return 0
	}
	if int(p_mem.enc) == desired_enc {
		return 0
	}
	rc = sqlite3_vdbe_mem_translate(p_mem, U8(desired_enc))
	return rc
}

@[c:'sqlite3VdbeMemGrow']
fn sqlite3_vdbe_mem_grow(p_mem &Mem, n int, b_preserve int) int {
	if p_mem.szMalloc > 0 && b_preserve && usize(p_mem.z) == usize(p_mem.zMalloc) {
		if p_mem.db {
			p_mem.zMalloc = &i8(sqlite3_db_realloc_or_free(p_mem.db, voidptr(p_mem.z), U64(n)))
			p_mem.z = p_mem.zMalloc
		} else {
			p_mem.zMalloc = &i8(sqlite3_realloc_vdup3(voidptr(p_mem.z), U64(n)))
			if usize(p_mem.zMalloc) == usize(0) {
				sqlite3_free(voidptr(p_mem.z))
			}
			p_mem.z = p_mem.zMalloc
		}
		b_preserve = 0
	} else {
		if p_mem.szMalloc > 0 {
			sqlite3_db_free_nn(p_mem.db, voidptr(p_mem.zMalloc))
		}
		p_mem.zMalloc = &i8(sqlite3_db_malloc_raw(p_mem.db, U64(n)))
	}
	if usize(p_mem.zMalloc) == usize(0) {
		sqlite3_vdbe_mem_set_null(p_mem)
		p_mem.z = 0
		p_mem.szMalloc = 0
		return 7
	} else {
		p_mem.szMalloc = sqlite3_db_malloc_size(p_mem.db, voidptr(p_mem.zMalloc))
	}
	if b_preserve && !isnil(p_mem.z) {
		C.memcpy(voidptr(p_mem.zMalloc), voidptr(p_mem.z), u64(p_mem.n))
	}
	if (int(p_mem.flags) & 4096) != 0 {
		p_mem.xDel(voidptr(p_mem.z))
	}
	p_mem.z = p_mem.zMalloc
	p_mem.flags &= ~(4096 | 16384 | 8192)
	return 0
}

@[c:'sqlite3VdbeMemClearAndResize']
fn sqlite3_vdbe_mem_clear_and_resize(p_mem &Mem, sz_new int) int {
	if p_mem.szMalloc < sz_new {
		return sqlite3_vdbe_mem_grow(p_mem, sz_new, 0)
	}
	p_mem.z = p_mem.zMalloc
	p_mem.flags &= (1 | 4 | 8 | 32)
	return 0
}

@[c:'sqlite3VdbeMemZeroTerminateIfAble']
fn sqlite3_vdbe_mem_zero_terminate_if_able(p_mem &Mem) int {
	if (int(p_mem.flags) & (2 | 512 | 16384 | 8192)) != 2 {
		return 0
	}
	if int(p_mem.enc) != 1 {
		return 0
	}
	if int(p_mem.flags) & 4096 {
		if p_mem.xDel == sqlite3_free && sqlite3_msize(voidptr(p_mem.z)) >= U64((p_mem.n + 1)) {
			p_mem.z[p_mem.n] = i8(0)
			p_mem.flags |= 512
			return 1
		}
		if p_mem.xDel == sqlite3_rc_str_unref {
			p_mem.flags |= 512
			return 1
		}
	} else if p_mem.szMalloc >= p_mem.n + 1 {
		p_mem.z[p_mem.n] = i8(0)
		p_mem.flags |= 512
		return 1
	}
	return 0
}

@[c:'vdbeMemAddTerminator']
fn vdbe_mem_add_terminator(p_mem &Mem) int {
	if sqlite3_vdbe_mem_grow(p_mem, p_mem.n + 3, 1) {
		return 7
	}
	p_mem.z[p_mem.n] = i8(0)
	p_mem.z[p_mem.n + 1] = i8(0)
	p_mem.z[p_mem.n + 2] = i8(0)
	p_mem.flags |= 512
	return 0
}

@[c:'sqlite3VdbeMemMakeWriteable']
fn sqlite3_vdbe_mem_make_writeable(p_mem &Mem) int {
	if (int(p_mem.flags) & (2 | 16)) != 0 {
		if (if (int(p_mem.flags) & 1024) { sqlite3_vdbe_mem_expand_blob(p_mem) } else { 0 }) {
			return 7
		}
		if p_mem.szMalloc == 0 || usize(p_mem.z) != usize(p_mem.zMalloc) {
			rc := vdbe_mem_add_terminator(p_mem)
			if rc {
				return rc
			}
		}
	}
	p_mem.flags &= ~16384
	return 0
}

@[c:'sqlite3VdbeMemExpandBlob']
fn sqlite3_vdbe_mem_expand_blob(p_mem &Mem) int {
	n_byte := 0
	n_byte = p_mem.n + p_mem.u.nZero
	if n_byte <= 0 {
		if (int(p_mem.flags) & 16) == 0 {
			return 0
		}
		n_byte = 1
	}
	if sqlite3_vdbe_mem_grow(p_mem, n_byte, 1) {
		return 7
	}
	C.memset(voidptr(unsafe { p_mem.z + p_mem.n }), 0, u64(p_mem.u.nZero))
	p_mem.n += p_mem.u.nZero
	p_mem.flags &= ~(1024 | 512)
	return 0
}

@[c:'sqlite3VdbeMemNulTerminate']
fn sqlite3_vdbe_mem_nul_terminate(p_mem &Mem) int {
	if (int(p_mem.flags) & (512 | 2)) != 2 {
		return 0
	} else {
		return vdbe_mem_add_terminator(p_mem)
	}
}

@[c:'sqlite3VdbeMemStringify']
fn sqlite3_vdbe_mem_stringify(p_mem &Mem, enc U8, b_force U8) int {
	n_byte := 32
	if sqlite3_vdbe_mem_clear_and_resize(p_mem, n_byte) {
		p_mem.enc = U8(0)
		return 7
	}
	vdbe_mem_render_num(n_byte, p_mem.z, p_mem)
	p_mem.enc = U8(1)
	p_mem.flags |= 2 | 512
	if b_force {
		p_mem.flags &= ~(4 | 8 | 32)
	}
	sqlite3_vdbe_change_encoding(p_mem, int(enc))
	return 0
}

@[c:'sqlite3VdbeMemFinalize']
fn sqlite3_vdbe_mem_finalize(p_mem &Mem, p_func &FuncDef) int {
	ctx := Sqlite3_context{}
	t := Mem{}
	C.memset(voidptr(&ctx), 0, sizeof(ctx))
	C.memset(voidptr(&t), 0, sizeof(t))
	t.flags = U16(1)
	t.db = p_mem.db
	ctx.pOut = &t
	ctx.pMem = p_mem
	ctx.pFunc = p_func
	ctx.enc = t.db.enc
	p_func.xFinalize(&ctx)
	if p_mem.szMalloc > 0 {
		sqlite3_db_free_nn(p_mem.db, voidptr(p_mem.zMalloc))
	}
	C.memcpy(voidptr(p_mem), voidptr(&t), sizeof(t))
	return ctx.isError
}

@[c:'sqlite3VdbeMemAggValue']
fn sqlite3_vdbe_mem_agg_value(p_accum &Mem, p_out &Mem, p_func &FuncDef) int {
	ctx := Sqlite3_context{}
	C.memset(voidptr(&ctx), 0, sizeof(ctx))
	sqlite3_vdbe_mem_set_null(p_out)
	ctx.pOut = p_out
	ctx.pMem = p_accum
	ctx.pFunc = p_func
	ctx.enc = p_accum.db.enc
	p_func.xValue(&ctx)
	return ctx.isError
}

@[c:'vdbeMemClearExternAndSetNull']
fn vdbe_mem_clear_extern_and_set_null(p &Mem) {
	if int(p.flags) & 32768 {
		sqlite3_vdbe_mem_finalize(p, p.u.pDef)
	}
	if int(p.flags) & 4096 {
		p.xDel(voidptr(p.z))
	}
	p.flags = U16(1)
}

@[c:'vdbeMemClear']
fn vdbe_mem_clear(p &Mem) {
	if ((int(p.flags) & (32768 | 4096)) != 0) {
		vdbe_mem_clear_extern_and_set_null(p)
	}
	if p.szMalloc {
		sqlite3_db_free_nn(p.db, voidptr(p.zMalloc))
		p.szMalloc = 0
	}
	p.z = 0
}

@[c:'sqlite3VdbeMemRelease']
fn sqlite3_vdbe_mem_release(p &Mem) {
	if ((int(p.flags) & (32768 | 4096)) != 0) || p.szMalloc {
		vdbe_mem_clear(p)
	}
}

@[c:'sqlite3VdbeMemReleaseMalloc']
fn sqlite3_vdbe_mem_release_malloc(p &Mem) {
	if p.szMalloc {
		vdbe_mem_clear(p)
	}
}

@[c:'memIntValue']
fn mem_int_value(p_mem &Mem) I64 {
	value := I64(0)
	sqlite3_atoi64(p_mem.z, &value, p_mem.n, p_mem.enc)
	return value
}

@[c:'sqlite3VdbeIntValue']
fn sqlite3_vdbe_int_value(p_mem &Mem) I64 {
	flags := 0
	flags = int(p_mem.flags)
	if flags & (4 | 32) {
		return p_mem.u.i
	} else if flags & 8 {
		return sqlite3_real_to_i64(p_mem.u.r)
	} else if (flags & (2 | 16)) != 0 && usize(p_mem.z) != usize(0) {
		return mem_int_value(p_mem)
	} else {
		return I64(0)
	}
}

@[c:'sqlite3MemRealValueRCSlowPath']
fn sqlite3_mem_real_value_rc_slow_path(p_mem &Mem, p_value &f64) int {
	rc := 0
	unsafe { *p_value = 0.0 }
	if int(p_mem.enc) == 1 {
		z_copy := sqlite3_db_str_nd_up(p_mem.db, p_mem.z, U64(p_mem.n))
		if z_copy {
			rc = sqlite3_ato_f(z_copy, p_value)
			sqlite3_db_free(p_mem.db, voidptr(z_copy))
		}
		return rc
	} else {
		n := 0
		i := 0
		j := 0

		z_copy := &i8(0)
		z := &i8(0)
		n = p_mem.n & ~1
		z_copy = &i8(sqlite3_db_malloc_raw(p_mem.db, U64(n / 2 + 2)))
		if z_copy {
			z = p_mem.z
			if int(p_mem.enc) == 2 {
				j = 0
				for i = 0; i < n - 1; i += 2 {
					z_copy[j] = z[i]
					if int(z[i + 1]) != 0 {
						break
					}
					j++
				}
			} else {
				j = 0
				for i = 0; i < n - 1; i += 2 {
					if int(z[i]) != 0 {
						break
					}
					z_copy[j] = z[i + 1]
					j++
				}
			}
			z_copy[j] = i8(0)
			rc = sqlite3_ato_f(z_copy, p_value)
			if i < n {
				rc = -100
			}
			sqlite3_db_free(p_mem.db, voidptr(z_copy))
		}
		return rc
	}
}

@[c:'sqlite3MemRealValueRC']
fn sqlite3_mem_real_value_rc(p_mem &Mem, p_value &f64) int {
	if usize(p_mem.z) == usize(0) {
		unsafe { *p_value = 0.0 }
		return 0
	} else if int(p_mem.enc) == 1 && ((int(p_mem.flags) & 512) != 0 || sqlite3_vdbe_mem_zero_terminate_if_able(p_mem)) {
		return sqlite3_ato_f(p_mem.z, p_value)
	} else if p_mem.n == 0 {
		unsafe { *p_value = 0.0 }
		return 0
	} else {
		return sqlite3_mem_real_value_rc_slow_path(p_mem, p_value)
	}
}

@[c:'sqlite3MemRealValueNoRC']
fn sqlite3_mem_real_value_no_rc(p_mem &Mem) f64 {
	r := 0.0
	sqlite3_mem_real_value_rc(p_mem, &r)
	return r
}

@[c:'sqlite3VdbeRealValue']
fn sqlite3_vdbe_real_value(p_mem &Mem) f64 {
	if int(p_mem.flags) & 8 {
		return p_mem.u.r
	} else if int(p_mem.flags) & (4 | 32) {
		return f64(p_mem.u.i)
	} else if int(p_mem.flags) & (2 | 16) {
		return sqlite3_mem_real_value_no_rc(p_mem)
	} else {
		return f64(0)
	}
}

@[c:'sqlite3VdbeBooleanValue']
fn sqlite3_vdbe_boolean_value(p_mem &Mem, if_null int) int {
	if int(p_mem.flags) & (4 | 32) {
		return int(p_mem.u.i != I64(0))
	}
	if int(p_mem.flags) & 1 {
		return if_null
	}
	return int(sqlite3_vdbe_real_value(p_mem) != 0.0)
}

@[c:'sqlite3VdbeIntegerAffinity']
fn sqlite3_vdbe_integer_affinity(p_mem &Mem) {
	if int(p_mem.flags) & 32 {
		p_mem.flags = U16((int(p_mem.flags) & ~(3519 | 1024)) | 4)
	} else {
		ix := sqlite3_real_to_i64(p_mem.u.r)
		if p_mem.u.r == f64(ix) && ix > ((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32))) && ix < (I64(u32(4294967295)) | ((I64(2147483647)) << 32)) {
			p_mem.u.i = ix
			p_mem.flags = U16((int(p_mem.flags) & ~(3519 | 1024)) | 4)
		}
	}
}

@[c:'sqlite3VdbeMemIntegerify']
fn sqlite3_vdbe_mem_integerify(p_mem &Mem) int {
	p_mem.u.i = sqlite3_vdbe_int_value(p_mem)
	p_mem.flags = U16((int(p_mem.flags) & ~(3519 | 1024)) | 4)
	return 0
}

@[c:'sqlite3VdbeMemRealify']
fn sqlite3_vdbe_mem_realify(p_mem &Mem) int {
	p_mem.u.r = sqlite3_vdbe_real_value(p_mem)
	p_mem.flags = U16((int(p_mem.flags) & ~(3519 | 1024)) | 8)
	return 0
}

@[c:'sqlite3RealSameAsInt']
fn sqlite3_real_same_as_int(r1 f64, i Sqlite3_int64) int {
	r2 := f64(i)
	return int(r1 == 0.0 || (C.memcmp(voidptr(&r1), voidptr(&r2), sizeof(r1)) == 0 && i >= -2251799813685248 && i < 2251799813685248))
}

@[c:'sqlite3RealToI64']
fn sqlite3_real_to_i64(r f64) I64 {
	if r < -9.2233720368547748E+18 {
		return (I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32))
	}
	if r > 9.2233720368547748E+18 {
		return I64(u32(4294967295)) | ((I64(2147483647)) << 32)
	}
	return I64(r)
}

@[c:'sqlite3VdbeMemNumerify']
fn sqlite3_vdbe_mem_numerify(p_mem &Mem) int {
	if (int(p_mem.flags) & (4 | 8 | 32 | 1)) == 0 {
		rc := 0
		ix := Sqlite3_int64(0)
		rc = sqlite3_mem_real_value_rc(p_mem, &p_mem.u.r)
		mut __c2v_condition_39 := false
		mut __c2v_condition_40 := false
		__c2v_condition_40 = ((rc & 2) == 0 && sqlite3_atoi64(p_mem.z, unsafe { &I64(&ix) }, p_mem.n, p_mem.enc) < 2)
		__c2v_condition_39 = __c2v_condition_40
		if !__c2v_condition_39 {
			mut __c2v_condition_41 := false
			__c2v_condition_41 = sqlite3_real_same_as_int(p_mem.u.r, c2v_assign[i64](unsafe { &ix }, i64(sqlite3_real_to_i64(p_mem.u.r))))
			__c2v_condition_39 = __c2v_condition_41
		}
		if __c2v_condition_39 {
			p_mem.u.i = ix
			p_mem.flags = U16((int(p_mem.flags) & ~(3519 | 1024)) | 4)
		} else {
			p_mem.flags = U16((int(p_mem.flags) & ~(3519 | 1024)) | 8)
		}
	}
	p_mem.flags &= ~(2 | 16 | 1024)
	return 0
}

@[c:'sqlite3VdbeMemCast']
fn sqlite3_vdbe_mem_cast(p_mem &Mem, aff U8, encoding U8) int {
	if int(p_mem.flags) & 1 {
		return 0
	}
	match aff {
		65 {
			if (int(p_mem.flags) & 16) == 0 {
				sqlite3_value_apply_affinity(unsafe { &Sqlite3_value(p_mem) }, U8(66), encoding)
				if int(p_mem.flags) & 2 {
					p_mem.flags = U16((int(p_mem.flags) & ~(3519 | 1024)) | 16)
				}
			} else {
				p_mem.flags &= ~(3519 & ~16)
			}
		}
		67 {
			sqlite3_vdbe_mem_numerify(p_mem)
		}
		68 {
			sqlite3_vdbe_mem_integerify(p_mem)
		}
		69 {
			sqlite3_vdbe_mem_realify(p_mem)
		}
		else {
			rc := 0
			p_mem.flags |= (int(p_mem.flags) & 16) >> 3
			sqlite3_value_apply_affinity(unsafe { &Sqlite3_value(p_mem) }, U8(66), encoding)
			p_mem.flags &= ~(4 | 8 | 32 | 16 | 1024)
			if int(encoding) != 1 {
				p_mem.n &= ~1
			}
			rc = sqlite3_vdbe_change_encoding(p_mem, int(encoding))
			if rc {
				return rc
			}
			sqlite3_vdbe_mem_zero_terminate_if_able(p_mem)
		}
	}

	return 0
}

@[c:'sqlite3VdbeMemInit']
fn sqlite3_vdbe_mem_init(p_mem &Mem, db &Sqlite3, flags U16) {
	p_mem.flags = flags
	p_mem.db = db
	p_mem.szMalloc = 0
}

@[c:'sqlite3VdbeMemSetNull']
fn sqlite3_vdbe_mem_set_null(p_mem &Mem) {
	if ((int(p_mem.flags) & (32768 | 4096)) != 0) {
		vdbe_mem_clear_extern_and_set_null(p_mem)
	} else {
		p_mem.flags = U16(1)
	}
}

@[c:'sqlite3ValueSetNull']
fn sqlite3_value_set_null(p &Sqlite3_value) {
	sqlite3_vdbe_mem_set_null(&Mem(p))
}

@[c:'sqlite3VdbeMemSetZeroBlob']
fn sqlite3_vdbe_mem_set_zero_blob(p_mem &Mem, n int) {
	sqlite3_vdbe_mem_release(p_mem)
	p_mem.flags = U16(16 | 1024)
	p_mem.n = 0
	if n < 0 {
		n = 0
	}
	p_mem.u.nZero = n
	p_mem.enc = U8(1)
	p_mem.z = 0
}

@[c:'vdbeReleaseAndSetInt64']
fn vdbe_release_and_set_int64(p_mem &Mem, val I64) {
	sqlite3_vdbe_mem_set_null(p_mem)
	p_mem.u.i = val
	p_mem.flags = U16(4)
}

@[c:'sqlite3VdbeMemSetInt64']
fn sqlite3_vdbe_mem_set_int64(p_mem &Mem, val I64) {
	if ((int(p_mem.flags) & (32768 | 4096)) != 0) {
		vdbe_release_and_set_int64(p_mem, val)
	} else {
		p_mem.u.i = val
		p_mem.flags = U16(4)
	}
}

@[c:'sqlite3MemSetArrayInt64']
fn sqlite3_mem_set_array_int64(a_mem &Sqlite3_value, i_idx int, val I64) {
	sqlite3_vdbe_mem_set_int64(unsafe { &Mem(a_mem + i_idx) }, val)
}

@[c:'sqlite3NoopDestructor']
fn sqlite3_noop_destructor(p voidptr) {
	c2v_gc_register_thread()
}

@[c:'sqlite3VdbeMemSetPointer']
fn sqlite3_vdbe_mem_set_pointer(p_mem &Mem, p_ptr voidptr, zpt_ype &i8, x_destructor fn (voidptr)) {
	vdbe_mem_clear(p_mem)
	p_mem.u.zPType = if zpt_ype { zpt_ype } else { c'' }
	p_mem.z = &i8(p_ptr)
	p_mem.flags = U16(1 | 4096 | 2048 | 512)
	p_mem.eSubtype = U8(`p`)
	p_mem.xDel = if x_destructor { x_destructor } else { sqlite3_noop_destructor }
}

@[c:'sqlite3VdbeMemSetDouble']
fn sqlite3_vdbe_mem_set_double(p_mem &Mem, val f64) {
	sqlite3_vdbe_mem_set_null(p_mem)
	if !sqlite3_is_na_n(val) {
		p_mem.u.r = val
		p_mem.flags = U16(8)
	}
}

@[c:'sqlite3VdbeMemSetRowSet']
fn sqlite3_vdbe_mem_set_row_set(p_mem &Mem) int {
	db := p_mem.db
	p := &RowSet(0)
	sqlite3_vdbe_mem_release(p_mem)
	p = sqlite3_row_set_init(db)
	if usize(p) == usize(0) {
		return 7
	}
	p_mem.z = &i8(voidptr(p))
	p_mem.flags = U16(16 | 4096)
	p_mem.xDel = sqlite3_row_set_delete
	return 0
}

@[c:'sqlite3VdbeMemTooBig']
fn sqlite3_vdbe_mem_too_big(p &Mem) int {
	if int(p.flags) & (2 | 16) {
		n := p.n
		if int(p.flags) & 1024 {
			n += p.u.nZero
		}
		return int(n > p.db.aLimit[0])
	}
	return 0
}

@[c:'vdbeClrCopy']
fn vdbe_clr_copy(p_to &Mem, p_from &Mem, e_type int) {
	vdbe_mem_clear_extern_and_set_null(p_to)
	sqlite3_vdbe_mem_shallow_copy(p_to, p_from, e_type)
}

@[c:'sqlite3VdbeMemShallowCopy']
fn sqlite3_vdbe_mem_shallow_copy(p_to &Mem, p_from &Mem, src_type int) {
	if ((int(p_to.flags) & (32768 | 4096)) != 0) {
		vdbe_clr_copy(p_to, p_from, src_type)
		return
	}
	C.memcpy(voidptr(p_to), voidptr(p_from), (u64(usize(__offsetof(Mem, db)))))
	if (int(p_from.flags) & 8192) == 0 {
		p_to.flags &= ~(4096 | 8192 | 16384)
		p_to.flags |= src_type
	}
}

@[c:'sqlite3VdbeMemCopy']
fn sqlite3_vdbe_mem_copy(p_to &Mem, p_from &Mem) int {
	rc := 0
	if ((int(p_to.flags) & (32768 | 4096)) != 0) {
		vdbe_mem_clear_extern_and_set_null(p_to)
	}
	C.memcpy(voidptr(p_to), voidptr(p_from), (u64(usize(__offsetof(Mem, db)))))
	p_to.flags &= ~4096
	if int(p_to.flags) & (2 | 16) {
		if 0 == (int(p_from.flags) & 8192) {
			p_to.flags |= 16384
			rc = sqlite3_vdbe_mem_make_writeable(p_to)
		}
	}
	return rc
}

@[c:'sqlite3VdbeMemMove']
fn sqlite3_vdbe_mem_move(p_to &Mem, p_from &Mem) {
	sqlite3_vdbe_mem_release(p_to)
	C.memcpy(voidptr(p_to), voidptr(p_from), sizeof(Mem))
	p_from.flags = U16(1)
	p_from.szMalloc = 0
}

@[c:'sqlite3VdbeMemSetStr']
fn sqlite3_vdbe_mem_set_str(p_mem &Mem, z &i8, n I64, enc U8, x_del fn (voidptr)) int {
	n_byte := n
	i_limit := 0
	flags := U16(0)
	if isnil(z) {
		sqlite3_vdbe_mem_set_null(p_mem)
		return 0
	}
	if p_mem.db {
		i_limit = p_mem.db.aLimit[0]
	} else {
		i_limit = 1000000000
	}
	if n_byte < I64(0) {
		if int(enc) == 1 {
			n_byte = I64(C.strlen(z))
		} else {
			for n_byte = I64(0); n_byte <= I64(i_limit) && (int(z[n_byte]) | int(z[n_byte + I64(1)])); n_byte += I64(2) {
			}
		}
		flags = U16(2 | 512)
	} else if int(enc) == 0 {
		flags = U16(16)
		enc = U8(1)
	} else {
		flags = U16(2)
	}
	if n_byte > I64(i_limit) {
		if !isnil(x_del) && x_del != (C2vFn_666e2028766f696470747229(voidptr(-1))) {
			if x_del == (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))) {
				sqlite3_db_free(p_mem.db, voidptr(z))
			} else {
				x_del(voidptr(z))
			}
		}
		sqlite3_vdbe_mem_set_null(p_mem)
		return sqlite3_error_to_parser(p_mem.db, 18)
	}
	if x_del == (C2vFn_666e2028766f696470747229(voidptr(-1))) {
		n_alloc := n_byte
		if int(flags) & 512 {
			n_alloc += I64((if int(enc) == 1 { 1 } else { 2 }))
		}
		if sqlite3_vdbe_mem_clear_and_resize(p_mem, int((if n_alloc > I64(32) {
			n_alloc
		} else {
			I64(32)
		}))) {
			return 7
		}
		C.memcpy(voidptr(p_mem.z), voidptr(z), u64(n_alloc))
	} else {
		sqlite3_vdbe_mem_release(p_mem)
		p_mem.z = &i8(z)
		if x_del == (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))) {
			p_mem.zMalloc = p_mem.z
			p_mem.szMalloc = sqlite3_db_malloc_size(p_mem.db, voidptr(p_mem.zMalloc))
		} else {
			p_mem.xDel = x_del
			flags |= (if (x_del == (C2vFn_666e2028766f696470747229(voidptr(0)))) {
				8192
			} else {
				4096
			})
		}
	}
	p_mem.n = int((n_byte & I64(2147483647)))
	p_mem.flags = flags
	p_mem.enc = enc
	if int(enc) > 1 && sqlite3_vdbe_mem_handle_bom(p_mem) {
		return 7
	}
	return 0
}

@[c:'sqlite3VdbeMemSetText']
fn sqlite3_vdbe_mem_set_text(p_mem &Mem, z &i8, n I64, x_del fn (voidptr)) int {
	n_byte := n
	flags := U16(0)
	if isnil(z) {
		sqlite3_vdbe_mem_set_null(p_mem)
		return 0
	}
	if n_byte < I64(0) {
		n_byte = I64(C.strlen(z))
		flags = U16(2 | 512)
	} else {
		flags = U16(2)
	}
	if n_byte > I64(p_mem.db.aLimit[0]) {
		if !isnil(x_del) && x_del != (C2vFn_666e2028766f696470747229(voidptr(-1))) {
			if x_del == (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))) {
				sqlite3_db_free(p_mem.db, voidptr(z))
			} else {
				x_del(voidptr(z))
			}
		}
		sqlite3_vdbe_mem_set_null(p_mem)
		return sqlite3_error_to_parser(p_mem.db, 18)
	}
	if x_del == (C2vFn_666e2028766f696470747229(voidptr(-1))) {
		n_alloc := n_byte + I64(1)
		if sqlite3_vdbe_mem_clear_and_resize(p_mem, int((if n_alloc > I64(32) {
			n_alloc
		} else {
			I64(32)
		}))) {
			return 7
		}
		C.memcpy(voidptr(p_mem.z), voidptr(z), u64(n_byte))
		p_mem.z[n_byte] = i8(0)
	} else {
		sqlite3_vdbe_mem_release(p_mem)
		p_mem.z = &i8(z)
		if x_del == (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))) {
			p_mem.zMalloc = p_mem.z
			p_mem.szMalloc = sqlite3_db_malloc_size(p_mem.db, voidptr(p_mem.zMalloc))
			p_mem.xDel = 0
		} else if x_del == (C2vFn_666e2028766f696470747229(voidptr(0))) {
			p_mem.xDel = x_del
			flags |= 8192
		} else {
			p_mem.xDel = x_del
			flags |= 4096
		}
	}
	p_mem.flags = flags
	p_mem.n = int((n_byte & I64(2147483647)))
	p_mem.enc = U8(1)
	return 0
}

@[c:'sqlite3VdbeMemFromBtree']
fn sqlite3_vdbe_mem_from_btree(p_cur &BtCursor, offset u32, amt u32, p_mem &Mem) int {
	rc := 0
	p_mem.flags = U16(1)
	if amt >= u32(2147483391) {
		return 7
	}
	if U64(amt) + U64(offset) > U64(sqlite3_btree_max_record_size(p_cur)) {
		return sqlite3_corrupt_error(1476)
	}
	rc = sqlite3_vdbe_mem_clear_and_resize(p_mem, int(amt + u32(1)))
	if 0 == rc {
		rc = sqlite3_btree_payload(p_cur, offset, amt, voidptr(p_mem.z))
		if rc == 0 {
			p_mem.z[amt] = i8(0)
			p_mem.flags = U16(16)
			p_mem.n = int(amt)
		} else {
			sqlite3_vdbe_mem_release(p_mem)
		}
	}
	return rc
}

@[c:'sqlite3VdbeMemFromBtreeZeroOffset']
fn sqlite3_vdbe_mem_from_btree_zero_offset(p_cur &BtCursor, amt u32, p_mem &Mem) int {
	available := u32(0)
	rc := 0
	p_mem.z = &i8(sqlite3_btree_payload_fetch(p_cur, &available))
	if amt <= available {
		p_mem.flags = U16(16 | 16384)
		p_mem.n = int(amt)
	} else {
		rc = sqlite3_vdbe_mem_from_btree(p_cur, u32(0), amt, p_mem)
	}
	return rc
}

@[c:'valueToText']
fn value_to_text(p_val &Sqlite3_value, enc U8) voidptr {
	if int(p_val.flags) & (16 | 2) {
		if (if (int(p_val.flags) & 1024) {
			sqlite3_vdbe_mem_expand_blob(unsafe { &Mem(p_val) })
		} else {
			0
		}) {
			return unsafe { nil }
		}
		p_val.flags |= 2
		if int(p_val.enc) != (int(enc) & ~8) {
			sqlite3_vdbe_change_encoding(unsafe { &Mem(p_val) }, int(enc) & ~8)
		}
		if (int(enc) & 8) != 0 && 1 == (1 & (int(i64(voidptr(p_val.z))))) {
			if sqlite3_vdbe_mem_make_writeable(unsafe { &Mem(p_val) }) != 0 {
				return unsafe { nil }
			}
		}
		sqlite3_vdbe_mem_nul_terminate(unsafe { &Mem(p_val) })
	} else {
		sqlite3_vdbe_mem_stringify(unsafe { &Mem(p_val) }, enc, U8(0))
	}
	if int(p_val.enc) == (int(enc) & ~8) {
		return p_val.z
	} else {
		return unsafe { nil }
	}
}

@[c:'sqlite3ValueText']
fn sqlite3_value_text_vdup5(p_val &Sqlite3_value, enc U8) voidptr {
	if isnil(p_val) {
		return unsafe { nil }
	}
	if (int(p_val.flags) & (2 | 512)) == (2 | 512) && int(p_val.enc) == int(enc) {
		return p_val.z
	}
	if int(p_val.flags) & 1 {
		return unsafe { nil }
	}
	return value_to_text(p_val, enc)
}

@[c:'sqlite3ValueIsOfClass']
fn sqlite3_value_is_of_class(p_val &Sqlite3_value, x_free fn (voidptr)) int {
	if (usize(p_val) != usize(0)) && ((int(p_val.flags) & (2 | 16)) != 0) && (int(p_val.flags) & 4096) != 0 && p_val.xDel == x_free {
		return 1
	} else {
		return 0
	}
}

@[c:'sqlite3ValueNew']
fn sqlite3_value_new(db &Sqlite3) &Sqlite3_value {
	p := &Mem(sqlite3_db_malloc_zero(db, U64(sizeof(Mem))))
	if p {
		p.flags = U16(1)
		p.db = db
	}
	return p
}

struct ValueNewStat4Ctx {
	pParse &Parse
	pIdx   &Index
	ppRec  &&UnpackedRecord
	iVal   int
}

@[c:'valueNew']
fn value_new(db &Sqlite3, p &ValueNewStat4Ctx) &Sqlite3_value {
	return sqlite3_value_new(db)
}

@[c:'valueFromExpr']
fn value_from_expr(db &Sqlite3, p_expr &Expr, enc U8, affinity U8, pp_val &&Sqlite3_value, p_ctx &ValueNewStat4Ctx) int {
	op := 0
	z_val := unsafe { &i8(nil) }
	p_val := unsafe { &Sqlite3_value(nil) }
	neg_int := 1
	z_neg := c''
	rc := 0
	for {
		op = int(p_expr.op)
		if !(op == 173 || op == 181) {
			break
		}
		p_expr = p_expr.pLeft
	}
	if op == 176 {
		op = int(p_expr.op2)
	}
	if op == 36 {
		aff := U8(0)
		aff = U8(sqlite3_affinity_type(p_expr.u.zToken, unsafe { nil }))
		rc = value_from_expr(db, p_expr.pLeft, enc, aff, pp_val, p_ctx)
		if unsafe { *pp_val != nil } {
			sqlite3_vdbe_mem_cast(unsafe { &Mem(pp_val) }, aff, enc)
			sqlite3_value_apply_affinity((unsafe { *pp_val }), affinity, enc)
		}
		return rc
	}
	if op == 174 {
		p_left := p_expr.pLeft
		if (int(p_left.op) == 156 || int(p_left.op) == 154) {
			if ((p_left.flags & u32(2048)) != u32(0)) || int(p_left.u.zToken[0]) != i8(`0`) || (int(p_left.u.zToken[1]) & ~32) != `X` {
				p_expr = p_left
				op = int(p_expr.op)
				neg_int = -1
				z_neg = c'-'
			}
		}
	}
	if op == 118 || op == 154 || op == 156 {
		p_val = value_new(db, p_ctx)
		if usize(p_val) == usize(0) {
			unsafe { goto no_mem
			 }
		}
		if ((p_expr.flags & u32(2048)) != u32(0)) {
			sqlite3_vdbe_mem_set_int64(unsafe { &Mem(p_val) }, I64(p_expr.u.iValue) * I64(neg_int))
		} else {
			i_val := I64(0)
			if op == 156 && 0 == sqlite3_dec_or_hex_to_i64(p_expr.u.zToken, &i_val) {
				sqlite3_vdbe_mem_set_int64(unsafe { &Mem(p_val) }, i_val * I64(neg_int))
			} else {
				z_val = sqlite3_mp_rintf(db, c'%s%s', voidptr(z_neg), voidptr(p_expr.u.zToken))
				if usize(z_val) == usize(0) {
					unsafe { goto no_mem
					 }
				}
				sqlite3_value_set_str(p_val, -1, voidptr(z_val), U8(1), (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))))
			}
		}
		if int(affinity) == 65 {
			if op == 154 {
				sqlite3_ato_f(p_val.z, &p_val.u.r)
				p_val.flags = U16(8)
			} else if op == 156 {
				sqlite3_value_apply_affinity(p_val, U8(67), U8(1))
			}
		} else {
			sqlite3_value_apply_affinity(p_val, affinity, U8(1))
		}
		if int(p_val.flags) & (4 | 32 | 8) {
			p_val.flags &= ~2
		}
		if int(enc) != 1 {
			rc = sqlite3_vdbe_change_encoding(unsafe { &Mem(p_val) }, int(enc))
		}
	} else if op == 174 {
		if 0 == value_from_expr(db, p_expr.pLeft, enc, affinity, &&Sqlite3_value(&&Sqlite3_value(c2v_address_of(&p_val))), p_ctx) && usize(p_val) != usize(0) {
			sqlite3_vdbe_mem_numerify(unsafe { &Mem(p_val) })
			if int(p_val.flags) & 8 {
				p_val.u.r = -p_val.u.r
			} else if p_val.u.i == ((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32))) {
				p_val.u.r = -f64(((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32))))
				p_val.flags = U16((int(p_val.flags) & ~(3519 | 1024)) | 8)
			} else {
				p_val.u.i = -p_val.u.i
			}
			sqlite3_value_apply_affinity(p_val, affinity, enc)
		}
	} else if op == 122 {
		p_val = value_new(db, p_ctx)
		if usize(p_val) == usize(0) {
			unsafe { goto no_mem
			 }
		}
		sqlite3_vdbe_mem_set_null(unsafe { &Mem(p_val) })
	} else if op == 155 {
		n_val := 0
		p_val = value_new(db, p_ctx)
		if isnil(p_val) {
			unsafe { goto no_mem
			 }
		}
		z_val = unsafe { p_expr.u.zToken + 2 }
		n_val = sqlite3_strlen30(z_val) - 1
		sqlite3_vdbe_mem_set_str(unsafe { &Mem(p_val) }, &i8(sqlite3_hex_to_blob(db, z_val, n_val)), I64(n_val / 2), U8(0), (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))))
	} else if op == 171 {
		p_val = value_new(db, p_ctx)
		if p_val {
			p_val.flags = U16(4)
			p_val.u.i = I64(int(p_expr.u.zToken[4]) == 0)
			sqlite3_value_apply_affinity(p_val, affinity, enc)
		}
	}
	unsafe { *pp_val = p_val }
	return rc
	no_mem:
	sqlite3_oom_fault(db)
	sqlite3_db_free(db, voidptr(z_val))
	sqlite3_value_free_vdup7(p_val)
	return 7
}

@[c:'sqlite3ValueFromExpr']
fn sqlite3_value_from_expr(db &Sqlite3, p_expr &Expr, enc U8, affinity U8, pp_val &&Sqlite3_value) int {
	return if p_expr { value_from_expr(db, p_expr, enc, affinity, pp_val, unsafe { nil }) } else { 0 }
}

@[c:'sqlite3ValueSetStr']
fn sqlite3_value_set_str(v &Sqlite3_value, n int, z voidptr, enc U8, x_del fn (voidptr)) {
	if v {
		sqlite3_vdbe_mem_set_str(&Mem(v), &i8(z), I64(n), enc, x_del)
	}
}

@[c:'sqlite3ValueFree']
fn sqlite3_value_free_vdup7(v &Sqlite3_value) {
	if isnil(v) {
		return
	}
	sqlite3_vdbe_mem_release(&Mem(v))
	sqlite3_db_free_nn((&Mem(v)).db, voidptr(v))
}

@[c:'valueBytes']
fn value_bytes(p_val &Sqlite3_value, enc U8) int {
	return if usize(value_to_text(p_val, enc)) != usize(0) { p_val.n } else { 0 }
}

@[c:'sqlite3ValueBytes']
fn sqlite3_value_bytes_vdup6(p_val &Sqlite3_value, enc U8) int {
	p := &Mem(p_val)
	if (int(p.flags) & 2) != 0 && int(p_val.enc) == int(enc) {
		return p.n
	}
	if (int(p.flags) & 2) != 0 && int(enc) != 1 && int(p_val.enc) != 1 {
		return p.n
	}
	if (int(p.flags) & 16) != 0 {
		if int(p.flags) & 1024 {
			return p.n + p.u.nZero
		} else {
			return p.n
		}
	}
	if int(p.flags) & 1 {
		return 0
	}
	return value_bytes(p_val, enc)
}
