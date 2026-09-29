@[translated]
module main

@[c:'findNextHostParameter']
fn find_next_host_parameter(z_sql &i8, pn_token &I64) I64 {
	token_type := 0
	n_total := I64(0)
	n := I64(0)
	unsafe { *pn_token = I64(0) }
	for z_sql[0] {
		n = sqlite3_get_token(&U8(voidptr(z_sql)), &token_type)
		if token_type == 157 {
			unsafe { *pn_token = n }
			break
		}
		n_total += n
		c2v_pointer_prefix(voidptr(&z_sql), z_sql, isize(n))
	}
	return n_total
}

@[c:'sqlite3VdbeExpandSql']
fn sqlite3_vdbe_expand_sql(p &Vdbe, z_raw_sql &i8) &i8 {
	db := &Sqlite3(0)
	idx := 0
	next_index := 1
	n := I64(0)
	n_token := I64(0)
	i := 0
	p_var := &Mem(0)
	out := StrAccum{}
	utf8 := Mem{}
	db = p.db
	sqlite3_str_accum_init(&out, unsafe { nil }, unsafe { nil }, 0, db.aLimit[0])
	if db.nVdbeExec > 1 {
		for (unsafe { *z_raw_sql }) {
			z_start := z_raw_sql
			for int((unsafe { *(c2v_pointer_postfix(voidptr(&z_raw_sql), z_raw_sql, isize(1))) })) != i8(`\n`) && int((unsafe { *z_raw_sql })) {
				0
			}
			sqlite3_str_append(unsafe { &Sqlite3_str(&out) }, c'-- ', 3)
			sqlite3_str_append(unsafe { &Sqlite3_str(&out) }, z_start, int((i64((isize(z_raw_sql) - isize(z_start)) / isize(sizeof(i8))))))
		}
	} else if int(p.nVar) == 0 {
		sqlite3_str_append(unsafe { &Sqlite3_str(&out) }, z_raw_sql, sqlite3_strlen30(z_raw_sql))
	} else {
		for z_raw_sql[0] {
			n = find_next_host_parameter(z_raw_sql, &n_token)
			sqlite3_str_append(unsafe { &Sqlite3_str(&out) }, z_raw_sql, int(n))
			c2v_pointer_prefix(voidptr(&z_raw_sql), z_raw_sql, isize(n))
			if n_token == I64(0) {
				break
			}
			if int(z_raw_sql[0]) == i8(`?`) {
				if n_token > I64(1) {
					sqlite3_get_int32(unsafe { z_raw_sql + 1 }, &idx)
				} else {
					idx = next_index
				}
			} else {
				0
				0
				0
				0
				idx = sqlite3_vdbe_parameter_index(p, z_raw_sql, int(n_token))
			}
			c2v_pointer_prefix(voidptr(&z_raw_sql), z_raw_sql, isize(n_token))
			next_index = (if (idx + 1) > next_index { (idx + 1) } else { next_index })
			p_var = unsafe { p.aVar + (idx - 1) }
			if int(p_var.flags) & 1 {
				sqlite3_str_append(unsafe { &Sqlite3_str(&out) }, c'NULL', 4)
			} else if int(p_var.flags) & (4 | 32) {
				sqlite3_str_appendf(unsafe { &Sqlite3_str(&out) }, c'%lld', p_var.u.i)
			} else if int(p_var.flags) & 8 {
				sqlite3_str_appendf(unsafe { &Sqlite3_str(&out) }, c'%!.15g', p_var.u.r)
			} else if int(p_var.flags) & 2 {
				n_out := 0
				enc := db.enc
				if int(enc) != 1 {
					C.memset(voidptr(&utf8), 0, sizeof(utf8))
					utf8.db = db
					sqlite3_vdbe_mem_set_str(&utf8, p_var.z, I64(p_var.n), enc, (C2vFn_666e2028766f696470747229(voidptr(0))))
					if 7 == sqlite3_vdbe_change_encoding(&utf8, 1) {
						out.accError = U8(7)
						out.nAlloc = u32(0)
					}
					p_var = &utf8
				}
				n_out = p_var.n
				sqlite3_str_appendf(unsafe { &Sqlite3_str(&out) }, c"'%.*q'", n_out, voidptr(p_var.z))
				if int(enc) != 1 {
					sqlite3_vdbe_mem_release(&utf8)
				}
			} else if int(p_var.flags) & 1024 {
				sqlite3_str_appendf(unsafe { &Sqlite3_str(&out) }, c'zeroblob(%d)', p_var.u.nZero)
			} else {
				n_out := 0
				sqlite3_str_append(unsafe { &Sqlite3_str(&out) }, c"x'", 2)
				n_out = p_var.n
				for i = 0; i < n_out; i++ {
					sqlite3_str_appendf(unsafe { &Sqlite3_str(&out) }, c'%02x', int(p_var.z[i]) & 255)
				}
				sqlite3_str_append(unsafe { &Sqlite3_str(&out) }, c"'", 1)
			}
		}
	}
	if out.accError {
		sqlite3_str_reset(unsafe { &Sqlite3_str(&out) })
	}
	return sqlite3_str_accum_finish(&out)
}
