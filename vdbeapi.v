@[translated]
module main

fn sqlite3_expired(p_stmt &Sqlite3_stmt) int {
	c2v_gc_register_thread()
	i_ret := 1
	if p_stmt {
		p := &Vdbe(voidptr(p_stmt))
		sqlite3_mutex_enter(p.db.mutex)
		i_ret = int(p.expired)
		sqlite3_mutex_leave(p.db.mutex)
	}
	return i_ret
}

@[c:'vdbeSafety']
fn vdbe_safety(p &Vdbe) int {
	if usize(p.db) == usize(0) {
		sqlite3_log(21, c'API called with finalized prepared statement')
		return 1
	} else {
		return 0
	}
}

@[c:'vdbeSafetyNotNull']
fn vdbe_safety_not_null(p &Vdbe) int {
	if usize(p) == usize(0) {
		sqlite3_log(21, c'API called with NULL prepared statement')
		return 1
	} else {
		return vdbe_safety(p)
	}
}

@[c:'invokeProfileCallback']
fn invoke_profile_callback(db &Sqlite3, p &Vdbe) {
	i_now := Sqlite3_int64(0)
	i_elapse := Sqlite3_int64(0)
	sqlite3_os_current_time_int64(db.pVfs, &i_now)
	i_elapse = (i_now - p.startTime) * Sqlite_int64(1000000)
	if db.xProfile {
		db.xProfile(voidptr(db.pProfileArg), p.zSql, U64(i_elapse))
	}
	if int(db.mTrace) & 2 {
		db.trace.xV2(u32(2), voidptr(db.pTraceArg), voidptr(p), voidptr(c2v_address_of(&i_elapse)))
	}
	p.startTime = I64(0)
}

fn sqlite3_finalize(p_stmt &Sqlite3_stmt) int {
	c2v_gc_register_thread()
	rc := 0
	if usize(p_stmt) == usize(0) {
		rc = 0
	} else {
		v := &Vdbe(voidptr(p_stmt))
		db := v.db
		if vdbe_safety(v) {
			return sqlite3_misuse_error(114)
		}
		sqlite3_mutex_enter(db.mutex)
		if v.startTime > I64(0) {
			invoke_profile_callback(db, v)
		}
		0
		rc = sqlite3_vdbe_reset(v)
		sqlite3_vdbe_delete(v)
		rc = sqlite3_api_exit(db, rc)
		sqlite3_leave_mutex_and_close_zombie(db)
	}
	return rc
}

fn sqlite3_reset(p_stmt &Sqlite3_stmt) int {
	c2v_gc_register_thread()
	rc := 0
	if usize(p_stmt) == usize(0) {
		rc = 0
	} else {
		v := &Vdbe(voidptr(p_stmt))
		db := v.db
		sqlite3_mutex_enter(db.mutex)
		if v.startTime > I64(0) {
			invoke_profile_callback(db, v)
		}
		0
		rc = sqlite3_vdbe_reset(v)
		sqlite3_vdbe_rewind(v)
		rc = sqlite3_api_exit(db, rc)
		sqlite3_mutex_leave(db.mutex)
	}
	return rc
}

fn sqlite3_clear_bindings(p_stmt &Sqlite3_stmt) int {
	c2v_gc_register_thread()
	i := 0
	rc := 0
	p := &Vdbe(voidptr(p_stmt))
	mutex := &Sqlite3_mutex(0)
	mutex = p.db.mutex
	sqlite3_mutex_enter(mutex)
	for i = 0; i < int(p.nVar); i++ {
		sqlite3_vdbe_mem_release(unsafe { p.aVar + i })
		p.aVar[i].flags = U16(1)
	}
	if p.expmask {
		p.expired = Bft(1)
	}
	sqlite3_mutex_leave(mutex)
	return rc
}

fn sqlite3_value_blob(p_val &Sqlite3_value) voidptr {
	c2v_gc_register_thread()
	p := &Mem(p_val)
	if int(p.flags) & (16 | 2) {
		if (if (int(p.flags) & 1024) { sqlite3_vdbe_mem_expand_blob(p) } else { 0 }) != 0 {
			return unsafe { nil }
		}
		p.flags |= 16
		return unsafe { if p.n { p.z } else { &i8(nil) } }
	} else {
		return sqlite3_value_text(p_val)
	}
}

fn sqlite3_value_bytes(p_val &Sqlite3_value) int {
	c2v_gc_register_thread()
	return sqlite3_value_bytes_vdup6(p_val, U8(1))
}

fn sqlite3_value_bytes16(p_val &Sqlite3_value) int {
	c2v_gc_register_thread()
	return sqlite3_value_bytes_vdup6(p_val, U8(2))
}

fn sqlite3_value_double(p_val &Sqlite3_value) f64 {
	c2v_gc_register_thread()
	return sqlite3_vdbe_real_value(&Mem(p_val))
}

fn sqlite3_value_int(p_val &Sqlite3_value) int {
	c2v_gc_register_thread()
	return int(sqlite3_vdbe_int_value(&Mem(p_val)))
}

fn sqlite3_value_int64(p_val &Sqlite3_value) Sqlite3_int64 {
	c2v_gc_register_thread()
	return sqlite3_vdbe_int_value(&Mem(p_val))
}

fn sqlite3_value_subtype(p_val &Sqlite3_value) u32 {
	c2v_gc_register_thread()
	p_mem := &Mem(p_val)
	return u32((if (int(p_mem.flags) & 2048) { int(p_mem.eSubtype) } else { 0 }))
}

fn sqlite3_value_pointer(p_val &Sqlite3_value, zpt_ype &i8) voidptr {
	c2v_gc_register_thread()
	p := &Mem(p_val)
	if (int(p.flags) & (3519 | 512 | 2048)) == (1 | 512 | 2048) && usize(zpt_ype) != usize(0) && int(p.eSubtype) == `p` && C.strcmp(p.u.zPType, zpt_ype) == 0 {
		return voidptr(p.z)
	} else {
		return unsafe { nil }
	}
}

fn sqlite3_value_text(p_val &Sqlite3_value) &u8 {
	c2v_gc_register_thread()
	return &u8(sqlite3_value_text_vdup5(p_val, U8(1)))
}

fn sqlite3_value_text16(p_val &Sqlite3_value) voidptr {
	c2v_gc_register_thread()
	return sqlite3_value_text_vdup5(p_val, U8(2))
}

fn sqlite3_value_text16be(p_val &Sqlite3_value) voidptr {
	c2v_gc_register_thread()
	return sqlite3_value_text_vdup5(p_val, U8(3))
}

fn sqlite3_value_text16le(p_val &Sqlite3_value) voidptr {
	c2v_gc_register_thread()
	return sqlite3_value_text_vdup5(p_val, U8(2))
}

fn sqlite3_value_type(p_val &Sqlite3_value) int {
	c2v_gc_register_thread()
	if !sqlite3_value_type_a_type_inited {
		c2v_static_init := [U8(4), U8(5), U8(3), U8(5), U8(1), U8(5), U8(1), U8(5), U8(2), U8(5),
			U8(2), U8(5), U8(1), U8(5), U8(1), U8(5), U8(4), U8(5), U8(3), U8(5), U8(1), U8(5),
			U8(1), U8(5), U8(2), U8(5), U8(2), U8(5), U8(1), U8(5), U8(1), U8(5), U8(2), U8(5),
			U8(2), U8(5), U8(2), U8(5), U8(2), U8(5), U8(2), U8(5), U8(2), U8(5), U8(2), U8(5),
			U8(2), U8(5), U8(4), U8(5), U8(3), U8(5), U8(2), U8(5), U8(2), U8(5), U8(2), U8(5),
			U8(2), U8(5), U8(2), U8(5), U8(2), U8(5)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_value_type_a_type[c2v_i_0] = c2v_element_0
		}
		sqlite3_value_type_a_type_inited = true
	}

	return int(sqlite3_value_type_a_type[int(p_val.flags) & 63])
}

fn sqlite3_value_encoding(p_val &Sqlite3_value) int {
	c2v_gc_register_thread()
	return int(p_val.enc)
}

fn sqlite3_value_nochange(p_val &Sqlite3_value) int {
	c2v_gc_register_thread()
	return int((int(p_val.flags) & (1 | 1024)) == (1 | 1024))
}

fn sqlite3_value_frombind(p_val &Sqlite3_value) int {
	c2v_gc_register_thread()
	return int((int(p_val.flags) & 64) != 0)
}

fn sqlite3_value_dup(p_orig &Sqlite3_value) &Sqlite3_value {
	c2v_gc_register_thread()
	p_new := &Sqlite3_value(0)
	if usize(p_orig) == usize(0) {
		return unsafe { nil }
	}
	p_new = sqlite3_malloc(int(sizeof(Sqlite3_value)))
	if usize(p_new) == usize(0) {
		return unsafe { nil }
	}
	C.memset(voidptr(p_new), 0, sizeof(Sqlite3_value))
	C.memcpy(voidptr(p_new), voidptr(p_orig), (u64(usize(__offsetof(Mem, db)))))
	p_new.flags &= ~4096
	p_new.db = 0
	if int(p_new.flags) & (2 | 16) {
		p_new.flags &= ~(8192 | 4096)
		p_new.flags |= 16384
		if sqlite3_vdbe_mem_make_writeable(unsafe { &Mem(p_new) }) != 0 {
			sqlite3_value_free_vdup7(p_new)
			p_new = 0
		}
	} else if int(p_new.flags) & 1 {
		p_new.flags &= ~(512 | 2048)
	}
	return p_new
}

fn sqlite3_value_free(p_old &Sqlite3_value) {
	c2v_gc_register_thread()
	sqlite3_value_free_vdup7(p_old)
}

@[c:'setResultStrOrError']
fn set_result_str_or_error(p_ctx &Sqlite3_context, z &i8, n int, enc U8, x_del fn (voidptr)) {
	p_out := p_ctx.pOut
	rc := 0
	if int(enc) == 1 {
		rc = sqlite3_vdbe_mem_set_text(p_out, z, I64(n), x_del)
	} else if int(enc) == 16 {
		rc = sqlite3_vdbe_mem_set_text(p_out, z, I64(n), x_del)
		p_out.flags |= 512
	} else {
		rc = sqlite3_vdbe_mem_set_str(p_out, z, I64(n), enc, x_del)
	}
	if rc {
		if rc == 18 {
			sqlite3_result_error_toobig(p_ctx)
		} else {
			sqlite3_result_error_nomem(p_ctx)
		}
		return
	}
	sqlite3_vdbe_change_encoding(p_out, int(p_ctx.enc))
	if sqlite3_vdbe_mem_too_big(p_out) {
		sqlite3_result_error_toobig(p_ctx)
	}
}

@[c:'invokeValueDestructor']
fn invoke_value_destructor(p voidptr, x_del fn (voidptr), p_ctx &Sqlite3_context) int {
	if isnil(x_del) {
	} else if x_del == (C2vFn_666e2028766f696470747229(voidptr(-1))) {
	} else {
		x_del(voidptr(p))
	}
	sqlite3_result_error_toobig(p_ctx)
	return 18
}

fn sqlite3_result_blob(p_ctx &Sqlite3_context, z voidptr, n int, x_del fn (voidptr)) {
	c2v_gc_register_thread()
	set_result_str_or_error(p_ctx, &i8(z), n, U8(0), x_del)
}

fn sqlite3_result_blob64(p_ctx &Sqlite3_context, z voidptr, n Sqlite3_uint64, x_del fn (voidptr)) {
	c2v_gc_register_thread()
	if n > Sqlite3_uint64(2147483647) {
		invoke_value_destructor(voidptr(z), x_del, p_ctx)
	} else {
		set_result_str_or_error(p_ctx, &i8(z), int(n), U8(0), x_del)
	}
}

fn sqlite3_result_double(p_ctx &Sqlite3_context, r_val f64) {
	c2v_gc_register_thread()
	sqlite3_vdbe_mem_set_double(p_ctx.pOut, r_val)
}

fn sqlite3_result_error(p_ctx &Sqlite3_context, z &i8, n int) {
	c2v_gc_register_thread()
	p_ctx.isError = 1
	sqlite3_vdbe_mem_set_str(p_ctx.pOut, z, I64(n), U8(1), (C2vFn_666e2028766f696470747229(voidptr(-1))))
}

fn sqlite3_result_error16(p_ctx &Sqlite3_context, z voidptr, n int) {
	c2v_gc_register_thread()
	p_ctx.isError = 1
	sqlite3_vdbe_mem_set_str(p_ctx.pOut, &i8(z), I64(n), U8(2), (C2vFn_666e2028766f696470747229(voidptr(-1))))
}

fn sqlite3_result_int(p_ctx &Sqlite3_context, i_val int) {
	c2v_gc_register_thread()
	sqlite3_vdbe_mem_set_int64(p_ctx.pOut, I64(i_val))
}

fn sqlite3_result_int64(p_ctx &Sqlite3_context, i_val I64) {
	c2v_gc_register_thread()
	sqlite3_vdbe_mem_set_int64(p_ctx.pOut, i_val)
}

fn sqlite3_result_null(p_ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	sqlite3_vdbe_mem_set_null(p_ctx.pOut)
}

fn sqlite3_result_pointer(p_ctx &Sqlite3_context, p_ptr voidptr, zpt_ype &i8, x_destructor fn (voidptr)) {
	c2v_gc_register_thread()
	p_out := &Mem(0)
	p_out = p_ctx.pOut
	sqlite3_vdbe_mem_release(p_out)
	p_out.flags = U16(1)
	sqlite3_vdbe_mem_set_pointer(p_out, voidptr(p_ptr), zpt_ype, x_destructor)
}

fn sqlite3_result_subtype(p_ctx &Sqlite3_context, e_subtype u32) {
	c2v_gc_register_thread()
	p_out := &Mem(0)
	p_out = p_ctx.pOut
	p_out.eSubtype = U8(e_subtype & u32(255))
	p_out.flags |= 2048
}

fn sqlite3_result_text(p_ctx &Sqlite3_context, z &i8, n int, x_del fn (voidptr)) {
	c2v_gc_register_thread()
	set_result_str_or_error(p_ctx, z, n, U8(1), x_del)
}

fn sqlite3_result_text64(p_ctx &Sqlite3_context, z &i8, n Sqlite3_uint64, x_del fn (voidptr), enc u8) {
	c2v_gc_register_thread()
	if int(enc) != 1 && int(enc) != 16 {
		if int(enc) == 4 {
			enc = u8(2)
		}
		n &= ~U64(1)
	}
	if n > Sqlite3_uint64(2147483647) {
		invoke_value_destructor(voidptr(z), x_del, p_ctx)
	} else {
		set_result_str_or_error(p_ctx, z, int(n), enc, x_del)
		sqlite3_vdbe_mem_zero_terminate_if_able(p_ctx.pOut)
	}
}

fn sqlite3_result_text16(p_ctx &Sqlite3_context, z voidptr, n int, x_del fn (voidptr)) {
	c2v_gc_register_thread()
	set_result_str_or_error(p_ctx, &i8(z), int(U64(n) & ~U64(1)), U8(2), x_del)
}

fn sqlite3_result_text16be(p_ctx &Sqlite3_context, z voidptr, n int, x_del fn (voidptr)) {
	c2v_gc_register_thread()
	set_result_str_or_error(p_ctx, &i8(z), int(U64(n) & ~U64(1)), U8(3), x_del)
}

fn sqlite3_result_text16le(p_ctx &Sqlite3_context, z voidptr, n int, x_del fn (voidptr)) {
	c2v_gc_register_thread()
	set_result_str_or_error(p_ctx, &i8(z), int(U64(n) & ~U64(1)), U8(2), x_del)
}

fn sqlite3_result_value(p_ctx &Sqlite3_context, p_value &Sqlite3_value) {
	c2v_gc_register_thread()
	p_out := &Mem(0)
	p_out = p_ctx.pOut
	sqlite3_vdbe_mem_copy(p_out, p_value)
	sqlite3_vdbe_change_encoding(p_out, int(p_ctx.enc))
	if sqlite3_vdbe_mem_too_big(p_out) {
		sqlite3_result_error_toobig(p_ctx)
	}
}

fn sqlite3_result_zeroblob(p_ctx &Sqlite3_context, n int) {
	c2v_gc_register_thread()
	sqlite3_result_zeroblob64(p_ctx, Sqlite3_uint64(if n > 0 { n } else { 0 }))
}

fn sqlite3_result_zeroblob64(p_ctx &Sqlite3_context, n U64) int {
	c2v_gc_register_thread()
	p_out := &Mem(0)
	p_out = p_ctx.pOut
	if n > U64(p_out.db.aLimit[0]) {
		sqlite3_result_error_toobig(p_ctx)
		return 18
	}
	sqlite3_vdbe_mem_set_zero_blob(p_ctx.pOut, int(n))
	return 0
}

fn sqlite3_result_error_code(p_ctx &Sqlite3_context, err_code int) {
	c2v_gc_register_thread()
	p_ctx.isError = if err_code { err_code } else { -1 }
	if int(p_ctx.pOut.flags) & 1 {
		set_result_str_or_error(p_ctx, sqlite3_err_str(err_code), -1, U8(1), (C2vFn_666e2028766f696470747229(voidptr(0))))
	}
}

fn sqlite3_result_error_toobig(p_ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	p_ctx.isError = 18
	sqlite3_vdbe_mem_set_str(p_ctx.pOut, c'string or blob too big', I64(-1), U8(1), (C2vFn_666e2028766f696470747229(voidptr(0))))
}

fn sqlite3_result_error_nomem(p_ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	sqlite3_vdbe_mem_set_null(p_ctx.pOut)
	p_ctx.isError = 7
	sqlite3_oom_fault(p_ctx.pOut.db)
}

@[c:'sqlite3ResultIntReal']
fn sqlite3_result_int_real(p_ctx &Sqlite3_context) {
	if int(p_ctx.pOut.flags) & 4 {
		p_ctx.pOut.flags &= ~4
		p_ctx.pOut.flags |= 32
	}
}

@[c:'doWalCallbacks']
fn do_wal_callbacks(db &Sqlite3) int {
	rc := 0
	i := 0
	for i = 0; i < db.nDb; i++ {
		p_bt := db.aDb[i].pBt
		if p_bt {
			n_entry := 0
			sqlite3_btree_enter(p_bt)
			n_entry = sqlite3_pager_wal_callback(sqlite3_btree_pager(p_bt))
			sqlite3_btree_leave(p_bt)
			if n_entry > 0 && !isnil(db.xWalCallback) && rc == 0 {
				rc = db.xWalCallback(voidptr(db.pWalArg), db, db.aDb[i].zDbSName, n_entry)
			}
		}
	}
	return rc
}

@[c:'sqlite3Step']
fn sqlite3_step_vdup10(p &Vdbe) int {
	db := &Sqlite3(0)
	rc := 0
	db = p.db
	if int(p.eVdbeState) != 2 {
		restart_step:
		if int(p.eVdbeState) == 1 {
			if p.expired {
				p.rc = 17
				rc = 1
				if (int(p.prepFlags) & 128) != 0 {
					rc = sqlite3_vdbe_transfer_error(p)
				}
				unsafe { goto end_of_step
				 }
			}
			if db.nVdbeActive == 0 {
				C.c2v_atomic_store_n__int_int_int_((&db.u1.isInterrupted), 0, 0)
			}
			if (int(db.mTrace) & (2 | 128)) != 0 && !db.init.busy && !isnil(p.zSql) {
				sqlite3_os_current_time_int64(db.pVfs, unsafe { &Sqlite3_int64(&p.startTime) })
			} else {
			}
			db.nVdbeActive++
			if int(p.readOnly) == 0 {
				db.nVdbeWrite++
			}
			if p.bIsReader {
				db.nVdbeRead++
			}
			p.pc = 0
			p.eVdbeState = U8(2)
		} else if (int(p.eVdbeState) == 3) {
			sqlite3_reset(&Sqlite3_stmt(voidptr(p)))
			unsafe { goto restart_step
			 }
		}
	}
	if p.explain {
		rc = sqlite3_vdbe_list(p)
	} else {
		db.nVdbeExec++
		rc = sqlite3_vdbe_exec(p)
		db.nVdbeExec--
	}
	if rc == 100 {
		db.errCode = 100
		return 100
	} else {
		if p.startTime > I64(0) {
			invoke_profile_callback(db, p)
		}
		0
		p.pResultRow = 0
		if rc == 101 && int(db.autoCommit) {
			p.rc = do_wal_callbacks(db)
			if p.rc != 0 {
				rc = 1
			}
		} else if rc != 101 && (int(p.prepFlags) & 128) != 0 {
			rc = sqlite3_vdbe_transfer_error(p)
		}
	}
	db.errCode = rc
	if 7 == sqlite3_api_exit(p.db, p.rc) {
		p.rc = 7
		if (int(p.prepFlags) & 128) != 0 {
			rc = p.rc
		}
	}
	end_of_step:
	return rc & db.errMask
}

fn sqlite3_step(p_stmt &Sqlite3_stmt) int {
	c2v_gc_register_thread()
	rc := 0
	v := &Vdbe(voidptr(p_stmt))
	cnt := 0
	db := &Sqlite3(0)
	if vdbe_safety_not_null(v) {
		return sqlite3_misuse_error(926)
	}
	db = v.db
	sqlite3_mutex_enter(db.mutex)
	for {
		rc = sqlite3_step_vdup10(v)
		if !(rc == 17 && cnt++ < 50) {
			break
		}
		saved_pc := v.pc
		rc = sqlite3_reprepare(v)
		if rc != 0 {
			z_err := &i8(voidptr(sqlite3_value_text(db.pErr)))
			sqlite3_db_free(db, voidptr(v.zErrMsg))
			if !db.mallocFailed {
				v.zErrMsg = sqlite3_db_str_dup(db, z_err)
				rc = sqlite3_api_exit(db, rc)
				v.rc = rc
			} else {
				v.zErrMsg = 0
				rc = 7
				v.rc = rc
			}
			break
		}
		sqlite3_reset(p_stmt)
		if saved_pc >= 0 {
			v.minWriteFileFormat = U8(254)
		}
	}
	sqlite3_mutex_leave(db.mutex)
	return rc
}

fn sqlite3_user_data(p &Sqlite3_context) voidptr {
	c2v_gc_register_thread()
	return p.pFunc.pUserData
}

fn sqlite3_context_db_handle(p &Sqlite3_context) &Sqlite3 {
	c2v_gc_register_thread()
	return p.pOut.db
}

fn sqlite3_vtab_nochange(p &Sqlite3_context) int {
	c2v_gc_register_thread()
	return sqlite3_value_nochange(unsafe { &Sqlite3_value(p.pOut) })
}

@[c:'sqlite3VdbeValueListFree']
fn sqlite3_vdbe_value_list_free(p_to_delete voidptr) {
	c2v_gc_register_thread()
	sqlite3_free(voidptr(p_to_delete))
}

@[c:'valueFromValueList']
fn value_from_value_list(p_val &Sqlite3_value, pp_out &&Sqlite3_value, b_next int) int {
	rc := 0
	p_rhs := &ValueList(0)
	unsafe { *pp_out = 0 }
	if usize(p_val) == usize(0) {
		return sqlite3_misuse_error(1047)
	}
	if (int(p_val.flags) & 4096) == 0 || p_val.xDel != sqlite3_vdbe_value_list_free {
		return 1
	} else {
		p_rhs = &ValueList(voidptr(p_val.z))
	}
	if b_next {
		rc = sqlite3_btree_next(p_rhs.pCsr, 0)
	} else {
		dummy := 0
		rc = sqlite3_btree_first(p_rhs.pCsr, &dummy)
		if sqlite3_btree_eof(p_rhs.pCsr) {
			rc = 101
		}
	}
	if rc == 0 {
		sz := u32(0)
		s_mem := Mem{}
		C.memset(voidptr(&s_mem), 0, sizeof(s_mem))
		sz = sqlite3_btree_payload_size(p_rhs.pCsr)
		rc = sqlite3_vdbe_mem_from_btree_zero_offset(p_rhs.pCsr, sz, &s_mem)
		if rc == 0 {
			z_buf := &U8(voidptr(s_mem.z))
			mut i_serial := u32(0)
			p_out := p_rhs.pOut
			i_off := 1 + int(U8((if (int((unsafe { *(z_buf + 1) })) < int(U8(128))) {
				(if true {
					i_serial = u32((unsafe { *(z_buf + 1) }))
					1
				} else {
					0
				})
			} else {
				int(sqlite3_get_varint32((unsafe { z_buf + 1 }), &u32(c2v_address_of(&i_serial))))
			})))
			sqlite3_vdbe_serial_get(unsafe { z_buf + i_off }, i_serial, unsafe { &Mem(p_out) })
			p_out.enc = p_out.db.enc
			if (int(p_out.flags) & 16384) != 0 && sqlite3_vdbe_mem_make_writeable(unsafe { &Mem(p_out) }) {
				rc = 7
			} else {
				unsafe { *pp_out = p_out }
			}
		}
		sqlite3_vdbe_mem_release(&s_mem)
	}
	return rc
}

fn sqlite3_vtab_in_first(p_val &Sqlite3_value, pp_out &&Sqlite3_value) int {
	c2v_gc_register_thread()
	return value_from_value_list(p_val, pp_out, 0)
}

fn sqlite3_vtab_in_next(p_val &Sqlite3_value, pp_out &&Sqlite3_value) int {
	c2v_gc_register_thread()
	return value_from_value_list(p_val, pp_out, 1)
}

@[c:'sqlite3StmtCurrentTime']
fn sqlite3_stmt_current_time(p &Sqlite3_context) Sqlite3_int64 {
	rc := 0
	pi_time := &p.pVdbe.iCurrentTime
	if (unsafe { *pi_time }) == Sqlite3_int64(0) {
		rc = sqlite3_os_current_time_int64(p.pOut.db.pVfs, pi_time)
		if rc {
			unsafe { *pi_time = Sqlite3_int64(0) }
		}
	}
	return unsafe { *pi_time }
}

@[c:'createAggContext']
fn create_agg_context(p &Sqlite3_context, n_byte int) voidptr {
	p_mem := p.pMem
	if n_byte <= 0 {
		sqlite3_vdbe_mem_set_null(p_mem)
		p_mem.z = 0
	} else {
		sqlite3_vdbe_mem_clear_and_resize(p_mem, n_byte)
		p_mem.flags = U16(32768)
		p_mem.u.pDef = p.pFunc
		if p_mem.z {
			C.memset(voidptr(p_mem.z), 0, u64(n_byte))
		}
	}
	return voidptr(p_mem.z)
}

fn sqlite3_aggregate_context(p &Sqlite3_context, n_byte int) voidptr {
	c2v_gc_register_thread()
	0
	if (int(p.pMem.flags) & 32768) == 0 {
		return create_agg_context(p, n_byte)
	} else {
		return voidptr(p.pMem.z)
	}
}

fn sqlite3_get_auxdata(p_ctx &Sqlite3_context, i_arg int) voidptr {
	c2v_gc_register_thread()
	p_aux_data := &AuxData(0)
	for p_aux_data = p_ctx.pVdbe.pAuxData; p_aux_data; p_aux_data = p_aux_data.pNextAux {
		if p_aux_data.iAuxArg == i_arg && (p_aux_data.iAuxOp == p_ctx.iOp || i_arg < 0) {
			return p_aux_data.pAux
		}
	}
	return unsafe { nil }
}

fn sqlite3_set_auxdata(p_ctx &Sqlite3_context, i_arg int, p_aux voidptr, x_delete fn (voidptr)) {
	c2v_gc_register_thread()
	p_aux_data := &AuxData(0)
	p_vdbe := &Vdbe(0)
	p_vdbe = p_ctx.pVdbe
	for p_aux_data = p_vdbe.pAuxData; p_aux_data; p_aux_data = p_aux_data.pNextAux {
		if p_aux_data.iAuxArg == i_arg && (p_aux_data.iAuxOp == p_ctx.iOp || i_arg < 0) {
			break
		}
	}
	if usize(p_aux_data) == usize(0) {
		p_aux_data = sqlite3_db_malloc_zero(p_vdbe.db, U64(sizeof(AuxData)))
		if isnil(p_aux_data) {
			unsafe { goto failed
			 }
		}
		p_aux_data.iAuxOp = p_ctx.iOp
		p_aux_data.iAuxArg = i_arg
		p_aux_data.pNextAux = p_vdbe.pAuxData
		p_vdbe.pAuxData = p_aux_data
		if p_ctx.isError == 0 {
			p_ctx.isError = -1
		}
	} else if p_aux_data.xDeleteAux {
		p_aux_data.xDeleteAux(voidptr(p_aux_data.pAux))
	}
	p_aux_data.pAux = p_aux
	p_aux_data.xDeleteAux = x_delete
	return
	failed:
	if x_delete {
		x_delete(voidptr(p_aux))
	}
}

fn sqlite3_aggregate_count(p &Sqlite3_context) int {
	c2v_gc_register_thread()
	return p.pMem.n
}

fn sqlite3_column_count(p_stmt &Sqlite3_stmt) int {
	c2v_gc_register_thread()
	p_vm := &Vdbe(voidptr(p_stmt))
	if usize(p_vm) == usize(0) {
		return 0
	}
	return int(p_vm.nResColumn)
}

fn sqlite3_data_count(p_stmt &Sqlite3_stmt) int {
	c2v_gc_register_thread()
	p_vm := &Vdbe(voidptr(p_stmt))
	if usize(p_vm) == usize(0) || usize(p_vm.pResultRow) == usize(0) {
		return 0
	}
	return int(p_vm.nResColumn)
}

@[c:'columnNullValue']
fn column_null_value() &Mem {
	if !column_null_value_null_mem_inited {
		column_null_value_null_mem = Mem{
			u: MemValue{}
			z: voidptr(0)
			n: int(0)
			flags: U16(1)
			enc: U8(0)
			eSubtype: U8(0)
			db: voidptr(0)
			szMalloc: int(0)
			uTemp: u32(0)
			zMalloc: voidptr(0)
			xDel: C2vFn_666e2028766f696470747229(voidptr(0))
		}

		column_null_value_null_mem_inited = true
	}

	return &column_null_value_null_mem
}

@[c:'columnMem']
fn column_mem(p_stmt &Sqlite3_stmt, i int) &Mem {
	p_vm := &Vdbe(0)
	p_out := &Mem(0)
	p_vm = &Vdbe(voidptr(p_stmt))
	if usize(p_vm) == usize(0) {
		return &Mem(column_null_value())
	}
	sqlite3_mutex_enter(p_vm.db.mutex)
	if usize(p_vm.pResultRow) != usize(0) && i < int(p_vm.nResColumn) && i >= 0 {
		p_out = unsafe { p_vm.pResultRow + i }
	} else {
		sqlite3_error(p_vm.db, 25)
		p_out = &Mem(column_null_value())
	}
	return p_out
}

@[c:'columnMallocFailure']
fn column_malloc_failure(p_stmt &Sqlite3_stmt) {
	p := &Vdbe(voidptr(p_stmt))
	if p {
		p.rc = sqlite3_api_exit(p.db, p.rc)
		sqlite3_mutex_leave(p.db.mutex)
	}
}

fn sqlite3_column_blob(p_stmt &Sqlite3_stmt, i int) voidptr {
	c2v_gc_register_thread()
	val := &voidptr(0)
	val = sqlite3_value_blob(unsafe { &Sqlite3_value(column_mem(p_stmt, i)) })
	column_malloc_failure(p_stmt)
	return val
}

fn sqlite3_column_bytes(p_stmt &Sqlite3_stmt, i int) int {
	c2v_gc_register_thread()
	val := sqlite3_value_bytes(unsafe { &Sqlite3_value(column_mem(p_stmt, i)) })
	column_malloc_failure(p_stmt)
	return val
}

fn sqlite3_column_bytes16(p_stmt &Sqlite3_stmt, i int) int {
	c2v_gc_register_thread()
	val := sqlite3_value_bytes16(unsafe { &Sqlite3_value(column_mem(p_stmt, i)) })
	column_malloc_failure(p_stmt)
	return val
}

fn sqlite3_column_double(p_stmt &Sqlite3_stmt, i int) f64 {
	c2v_gc_register_thread()
	val := sqlite3_value_double(unsafe { &Sqlite3_value(column_mem(p_stmt, i)) })
	column_malloc_failure(p_stmt)
	return val
}

fn sqlite3_column_int(p_stmt &Sqlite3_stmt, i int) int {
	c2v_gc_register_thread()
	val := sqlite3_value_int(unsafe { &Sqlite3_value(column_mem(p_stmt, i)) })
	column_malloc_failure(p_stmt)
	return val
}

fn sqlite3_column_int64(p_stmt &Sqlite3_stmt, i int) Sqlite3_int64 {
	c2v_gc_register_thread()
	val := sqlite3_value_int64(unsafe { &Sqlite3_value(column_mem(p_stmt, i)) })
	column_malloc_failure(p_stmt)
	return val
}

fn sqlite3_column_text(p_stmt &Sqlite3_stmt, i int) &u8 {
	c2v_gc_register_thread()
	val := sqlite3_value_text(unsafe { &Sqlite3_value(column_mem(p_stmt, i)) })
	column_malloc_failure(p_stmt)
	return val
}

fn sqlite3_column_value(p_stmt &Sqlite3_stmt, i int) &Sqlite3_value {
	c2v_gc_register_thread()
	p_out := column_mem(p_stmt, i)
	if int(p_out.flags) & 8192 {
		p_out.flags &= ~8192
		p_out.flags |= 16384
	}
	column_malloc_failure(p_stmt)
	return &Sqlite3_value(p_out)
}

fn sqlite3_column_text16(p_stmt &Sqlite3_stmt, i int) voidptr {
	c2v_gc_register_thread()
	val := sqlite3_value_text16(unsafe { &Sqlite3_value(column_mem(p_stmt, i)) })
	column_malloc_failure(p_stmt)
	return val
}

fn sqlite3_column_type(p_stmt &Sqlite3_stmt, i int) int {
	c2v_gc_register_thread()
	i_type := sqlite3_value_type(unsafe { &Sqlite3_value(column_mem(p_stmt, i)) })
	column_malloc_failure(p_stmt)
	return i_type
}

@[c:'columnName']
fn column_name(p_stmt &Sqlite3_stmt, n int, use_utf16 int, use_type int) voidptr {
	ret := &voidptr(0)
	p := &Vdbe(0)
	n_2 := 0
	db := &Sqlite3(0)
	if n < 0 {
		return unsafe { nil }
	}
	ret = 0
	p = &Vdbe(voidptr(p_stmt))
	db = p.db
	sqlite3_mutex_enter(db.mutex)
	if p.explain {
		if use_type > 0 {
			unsafe { goto columnName_end
			 }
		}
		n_2 = if int(p.explain) == 1 { 8 } else { 4 }
		if n >= n_2 {
			unsafe { goto columnName_end
			 }
		}
		if use_utf16 {
			i := int(i_explain_col_names16[n + 8 * int(p.explain) - 8])
			ret = voidptr(unsafe { &azExplainColNames16data[0] + i })
		} else {
			ret = voidptr(azExplainColNames8[n + 8 * int(p.explain) - 8])
		}
		unsafe { goto columnName_end
		 }
	}
	n_2 = int(p.nResColumn)
	if n < n_2 {
		prior_malloc_failed := db.mallocFailed
		n += use_type * n_2
		if use_utf16 {
			ret = sqlite3_value_text16(&Sqlite3_value(unsafe { p.aColName + n }))
		} else {
			ret = sqlite3_value_text(&Sqlite3_value(unsafe { p.aColName + n }))
		}
		if int(db.mallocFailed) > int(prior_malloc_failed) {
			sqlite3_oom_clear(db)
			ret = 0
		}
	}
	columnName_end:
	sqlite3_mutex_leave(db.mutex)
	return ret
}

fn sqlite3_column_name(p_stmt &Sqlite3_stmt, n int) &i8 {
	c2v_gc_register_thread()
	return &i8(column_name(p_stmt, n, 0, 0))
}

fn sqlite3_column_name16(p_stmt &Sqlite3_stmt, n int) voidptr {
	c2v_gc_register_thread()
	return column_name(p_stmt, n, 1, 0)
}

fn sqlite3_column_decltype(p_stmt &Sqlite3_stmt, n int) &i8 {
	c2v_gc_register_thread()
	return &i8(column_name(p_stmt, n, 0, 1))
}

fn sqlite3_column_decltype16(p_stmt &Sqlite3_stmt, n int) voidptr {
	c2v_gc_register_thread()
	return column_name(p_stmt, n, 1, 1)
}

@[c:'vdbeUnbind']
fn vdbe_unbind(p &Vdbe, i u32) int {
	p_var := &Mem(0)
	if vdbe_safety_not_null(p) {
		return sqlite3_misuse_error(1663)
	}
	sqlite3_mutex_enter(p.db.mutex)
	if int(p.eVdbeState) != 1 {
		sqlite3_error(p.db, sqlite3_misuse_error(1667))
		sqlite3_mutex_leave(p.db.mutex)
		sqlite3_log(21, c'bind on a busy prepared statement: [%s]', voidptr(p.zSql))
		return sqlite3_misuse_error(1671)
	}
	if i >= u32(p.nVar) {
		sqlite3_error(p.db, 25)
		sqlite3_mutex_leave(p.db.mutex)
		return 25
	}
	p_var = unsafe { p.aVar + i }
	sqlite3_vdbe_mem_release(p_var)
	p_var.flags = U16(1)
	p.db.errCode = 0
	if p.expmask != u32(0) && (p.expmask & (if i >= u32(31) { u32(2147483648) } else { u32(1) << i })) != u32(0) {
		p.expired = Bft(1)
	}
	return 0
}

@[c:'bindText']
fn bind_text(p_stmt &Sqlite3_stmt, i int, z_data voidptr, n_data I64, x_del fn (voidptr), encoding U8) int {
	p := &Vdbe(voidptr(p_stmt))
	p_var := &Mem(0)
	rc := 0
	rc = vdbe_unbind(p, u32((i - 1)))
	if rc == 0 {
		if usize(z_data) != usize(0) {
			p_var = unsafe { p.aVar + (i - 1) }
			if int(encoding) == 1 {
				rc = sqlite3_vdbe_mem_set_text(p_var, &i8(z_data), n_data, x_del)
			} else if int(encoding) == 16 {
				rc = sqlite3_vdbe_mem_set_text(p_var, &i8(z_data), n_data, x_del)
				p_var.flags |= 512
			} else {
				rc = sqlite3_vdbe_mem_set_str(p_var, &i8(z_data), n_data, encoding, x_del)
				if int(encoding) == 0 {
					p_var.enc = p.db.enc
				}
			}
			if rc == 0 && int(encoding) != 0 {
				rc = sqlite3_vdbe_change_encoding(p_var, int(p.db.enc))
			}
			if rc {
				sqlite3_error(p.db, rc)
				rc = sqlite3_api_exit(p.db, rc)
			}
		}
		sqlite3_mutex_leave(p.db.mutex)
	} else if x_del != (C2vFn_666e2028766f696470747229(voidptr(0))) && x_del != (C2vFn_666e2028766f696470747229(voidptr(-1))) {
		x_del(voidptr(z_data))
	}
	return rc
}

fn sqlite3_bind_blob(p_stmt &Sqlite3_stmt, i int, z_data voidptr, n_data int, x_del fn (voidptr)) int {
	c2v_gc_register_thread()
	return bind_text(p_stmt, i, voidptr(z_data), I64(n_data), x_del, U8(0))
}

fn sqlite3_bind_blob64(p_stmt &Sqlite3_stmt, i int, z_data voidptr, n_data Sqlite3_uint64, x_del fn (voidptr)) int {
	c2v_gc_register_thread()
	return bind_text(p_stmt, i, voidptr(z_data), I64(n_data), x_del, U8(0))
}

fn sqlite3_bind_double(p_stmt &Sqlite3_stmt, i int, r_value f64) int {
	c2v_gc_register_thread()
	rc := 0
	p := &Vdbe(voidptr(p_stmt))
	rc = vdbe_unbind(p, u32((i - 1)))
	if rc == 0 {
		sqlite3_vdbe_mem_set_double(unsafe { p.aVar + (i - 1) }, r_value)
		sqlite3_mutex_leave(p.db.mutex)
	}
	return rc
}

fn sqlite3_bind_int(p &Sqlite3_stmt, i int, i_value int) int {
	c2v_gc_register_thread()
	return sqlite3_bind_int64(p, i, I64(i_value))
}

fn sqlite3_bind_int64(p_stmt &Sqlite3_stmt, i int, i_value Sqlite_int64) int {
	c2v_gc_register_thread()
	rc := 0
	p := &Vdbe(voidptr(p_stmt))
	rc = vdbe_unbind(p, u32((i - 1)))
	if rc == 0 {
		sqlite3_vdbe_mem_set_int64(unsafe { p.aVar + (i - 1) }, i_value)
		sqlite3_mutex_leave(p.db.mutex)
	}
	return rc
}

fn sqlite3_bind_null(p_stmt &Sqlite3_stmt, i int) int {
	c2v_gc_register_thread()
	rc := 0
	p := &Vdbe(voidptr(p_stmt))
	rc = vdbe_unbind(p, u32((i - 1)))
	if rc == 0 {
		sqlite3_mutex_leave(p.db.mutex)
	}
	return rc
}

fn sqlite3_bind_pointer(p_stmt &Sqlite3_stmt, i int, p_ptr voidptr, zpt_type &i8, x_destructor fn (voidptr)) int {
	c2v_gc_register_thread()
	rc := 0
	p := &Vdbe(voidptr(p_stmt))
	rc = vdbe_unbind(p, u32((i - 1)))
	if rc == 0 {
		sqlite3_vdbe_mem_set_pointer(unsafe { p.aVar + (i - 1) }, voidptr(p_ptr), zpt_type, x_destructor)
		sqlite3_mutex_leave(p.db.mutex)
	} else if x_destructor {
		x_destructor(voidptr(p_ptr))
	}
	return rc
}

fn sqlite3_bind_text(p_stmt &Sqlite3_stmt, i int, z_data &i8, n_data int, x_del fn (voidptr)) int {
	c2v_gc_register_thread()
	return bind_text(p_stmt, i, voidptr(z_data), I64(n_data), x_del, U8(1))
}

fn sqlite3_bind_text64(p_stmt &Sqlite3_stmt, i int, z_data &i8, n_data Sqlite3_uint64, x_del fn (voidptr), enc u8) int {
	c2v_gc_register_thread()
	if int(enc) != 1 && int(enc) != 16 {
		if int(enc) == 4 {
			enc = u8(2)
		}
		n_data &= ~U64(1)
	}
	return bind_text(p_stmt, i, voidptr(z_data), I64(n_data), x_del, enc)
}

fn sqlite3_bind_text16(p_stmt &Sqlite3_stmt, i int, z_data voidptr, n int, x_del fn (voidptr)) int {
	c2v_gc_register_thread()
	return bind_text(p_stmt, i, voidptr(z_data), I64(U64(n) & ~U64(1)), x_del, U8(2))
}

fn sqlite3_bind_value(p_stmt &Sqlite3_stmt, i int, p_value &Sqlite3_value) int {
	c2v_gc_register_thread()
	rc := 0
	match sqlite3_value_type(&Sqlite3_value(p_value)) {
		1 {
			rc = sqlite3_bind_int64(p_stmt, i, p_value.u.i)
		}
		2 {
			rc = sqlite3_bind_double(p_stmt, i, if (int(p_value.flags) & 8) {
				p_value.u.r
			} else {
				f64(p_value.u.i)
			})
		}
		4 {
			if int(p_value.flags) & 1024 {
				rc = sqlite3_bind_zeroblob(p_stmt, i, p_value.u.nZero)
			} else {
				rc = sqlite3_bind_blob(p_stmt, i, voidptr(p_value.z), p_value.n, (C2vFn_666e2028766f696470747229(voidptr(-1))))
			}
		}
		3 {
			rc = bind_text(p_stmt, i, voidptr(p_value.z), I64(p_value.n), (C2vFn_666e2028766f696470747229(voidptr(-1))), p_value.enc)
		}
		else {
			rc = sqlite3_bind_null(p_stmt, i)
		}
	}

	return rc
}

fn sqlite3_bind_zeroblob(p_stmt &Sqlite3_stmt, i int, n int) int {
	c2v_gc_register_thread()
	rc := 0
	p := &Vdbe(voidptr(p_stmt))
	rc = vdbe_unbind(p, u32((i - 1)))
	if rc == 0 {
		sqlite3_vdbe_mem_set_zero_blob(unsafe { p.aVar + (i - 1) }, n)
		sqlite3_mutex_leave(p.db.mutex)
	}
	return rc
}

fn sqlite3_bind_zeroblob64(p_stmt &Sqlite3_stmt, i int, n Sqlite3_uint64) int {
	c2v_gc_register_thread()
	rc := 0
	p := &Vdbe(voidptr(p_stmt))
	sqlite3_mutex_enter(p.db.mutex)
	if n > U64(p.db.aLimit[0]) {
		rc = 18
	} else {
		rc = sqlite3_bind_zeroblob(p_stmt, i, int(n))
	}
	rc = sqlite3_api_exit(p.db, rc)
	sqlite3_mutex_leave(p.db.mutex)
	return rc
}

fn sqlite3_bind_parameter_count(p_stmt &Sqlite3_stmt) int {
	c2v_gc_register_thread()
	p := &Vdbe(voidptr(p_stmt))
	return if p { int(p.nVar) } else { 0 }
}

fn sqlite3_bind_parameter_name(p_stmt &Sqlite3_stmt, i int) &i8 {
	c2v_gc_register_thread()
	p := &Vdbe(voidptr(p_stmt))
	if usize(p) == usize(0) {
		return unsafe { nil }
	}
	return sqlite3_vl_ist_num_to_name(p.pVList, i)
}

@[c:'sqlite3VdbeParameterIndex']
fn sqlite3_vdbe_parameter_index(p &Vdbe, z_name &i8, n_name int) int {
	if usize(p) == usize(0) || usize(z_name) == usize(0) {
		return 0
	}
	return sqlite3_vl_ist_name_to_num(p.pVList, z_name, n_name)
}

fn sqlite3_bind_parameter_index(p_stmt &Sqlite3_stmt, z_name &i8) int {
	c2v_gc_register_thread()
	return sqlite3_vdbe_parameter_index(&Vdbe(voidptr(p_stmt)), z_name, sqlite3_strlen30(z_name))
}

@[c:'sqlite3TransferBindings']
fn sqlite3_transfer_bindings_vdup8(p_from_stmt &Sqlite3_stmt, p_to_stmt &Sqlite3_stmt) int {
	p_from := &Vdbe(voidptr(p_from_stmt))
	p_to := &Vdbe(voidptr(p_to_stmt))
	i := 0
	sqlite3_mutex_enter(p_to.db.mutex)
	for i = 0; i < int(p_from.nVar); i++ {
		sqlite3_vdbe_mem_move(unsafe { p_to.aVar + i }, unsafe { p_from.aVar + i })
	}
	sqlite3_mutex_leave(p_to.db.mutex)
	return 0
}

fn sqlite3_transfer_bindings(p_from_stmt &Sqlite3_stmt, p_to_stmt &Sqlite3_stmt) int {
	c2v_gc_register_thread()
	p_from := &Vdbe(voidptr(p_from_stmt))
	p_to := &Vdbe(voidptr(p_to_stmt))
	if int(p_from.nVar) != int(p_to.nVar) {
		return 1
	}
	if p_to.expmask {
		p_to.expired = Bft(1)
	}
	if p_from.expmask {
		p_from.expired = Bft(1)
	}
	return sqlite3_transfer_bindings_vdup8(p_from_stmt, p_to_stmt)
}

fn sqlite3_db_handle(p_stmt &Sqlite3_stmt) &Sqlite3 {
	c2v_gc_register_thread()
	return unsafe { if p_stmt { (&Vdbe(voidptr(p_stmt))).db } else { &Sqlite3(nil) } }
}

fn sqlite3_stmt_readonly(p_stmt &Sqlite3_stmt) int {
	c2v_gc_register_thread()
	return if p_stmt { int((&Vdbe(voidptr(p_stmt))).readOnly) } else { 1 }
}

fn sqlite3_stmt_isexplain(p_stmt &Sqlite3_stmt) int {
	c2v_gc_register_thread()
	return if p_stmt { int((&Vdbe(voidptr(p_stmt))).explain) } else { 0 }
}

fn sqlite3_stmt_explain(p_stmt &Sqlite3_stmt, e_mode int) int {
	c2v_gc_register_thread()
	v := &Vdbe(voidptr(p_stmt))
	rc := 0
	sqlite3_mutex_enter(v.db.mutex)
	if (int(v.explain)) == e_mode {
		rc = 0
	} else if e_mode < 0 || e_mode > 2 {
		rc = 1
	} else if (int(v.prepFlags) & 128) == 0 {
		rc = 1
	} else if int(v.eVdbeState) != 1 {
		rc = 5
	} else if v.nMem >= 10 && (e_mode != 2 || int(v.haveEqpOps)) {
		v.explain = Bft(e_mode)
		rc = 0
	} else {
		v.explain = Bft(e_mode)
		rc = sqlite3_reprepare(v)
		v.haveEqpOps = Bft(e_mode == 2)
	}
	if v.explain {
		v.nResColumn = U16(12 - 4 * int(v.explain))
	} else {
		v.nResColumn = v.nResAlloc
	}
	sqlite3_mutex_leave(v.db.mutex)
	return rc
}

fn sqlite3_stmt_busy(p_stmt &Sqlite3_stmt) int {
	c2v_gc_register_thread()
	v := &Vdbe(voidptr(p_stmt))
	return int(usize(v) != usize(0) && int(v.eVdbeState) == 2)
}

fn sqlite3_next_stmt(p_db &Sqlite3, p_stmt &Sqlite3_stmt) &Sqlite3_stmt {
	c2v_gc_register_thread()
	p_next := &Sqlite3_stmt(0)
	sqlite3_mutex_enter(p_db.mutex)
	if usize(p_stmt) == usize(0) {
		p_next = &Sqlite3_stmt(voidptr(p_db.pVdbe))
	} else {
		p_next = &Sqlite3_stmt(voidptr((&Vdbe(voidptr(p_stmt))).pVNext))
	}
	sqlite3_mutex_leave(p_db.mutex)
	return p_next
}

fn sqlite3_stmt_status(p_stmt &Sqlite3_stmt, op int, reset_flag int) int {
	c2v_gc_register_thread()
	p_vdbe := &Vdbe(voidptr(p_stmt))
	v := u32(0)
	if op == 99 {
		db := p_vdbe.db
		sqlite3_mutex_enter(db.mutex)
		v = u32(0)
		db.pnBytesFreed = &int(c2v_address_of(&v))
		db.lookaside.pEnd = db.lookaside.pStart
		sqlite3_vdbe_delete(p_vdbe)
		db.pnBytesFreed = 0
		db.lookaside.pEnd = db.lookaside.pTrueEnd
		sqlite3_mutex_leave(db.mutex)
	} else {
		v = p_vdbe.aCounter[op]
		if reset_flag {
			p_vdbe.aCounter[op] = u32(0)
		}
	}
	return int(v)
}

fn sqlite3_sql(p_stmt &Sqlite3_stmt) &i8 {
	c2v_gc_register_thread()
	p := &Vdbe(voidptr(p_stmt))
	return unsafe { if p { p.zSql } else { &i8(nil) } }
}

fn sqlite3_expanded_sql(p_stmt &Sqlite3_stmt) &i8 {
	c2v_gc_register_thread()
	z := unsafe { &i8(nil) }
	z_sql := sqlite3_sql(p_stmt)
	if z_sql {
		p := &Vdbe(voidptr(p_stmt))
		sqlite3_mutex_enter(p.db.mutex)
		z = sqlite3_vdbe_expand_sql(p, z_sql)
		sqlite3_mutex_leave(p.db.mutex)
	}
	return z
}
