@[translated]
module main

@[c:'sqlite3AppendOneUtf8Character']
fn sqlite3_append_one_utf8_character(z_out &i8, v u32) int {
	if v < u32(128) {
		z_out[0] = i8(U8((v & u32(255))))
		return 1
	}
	if v < u32(2048) {
		z_out[0] = i8(192 + int(U8(((v >> 6) & u32(31)))))
		z_out[1] = i8(128 + int(U8((v & u32(63)))))
		return 2
	}
	if v < u32(65536) {
		z_out[0] = i8(224 + int(U8(((v >> 12) & u32(15)))))
		z_out[1] = i8(128 + int(U8(((v >> 6) & u32(63)))))
		z_out[2] = i8(128 + int(U8((v & u32(63)))))
		return 3
	}
	z_out[0] = i8(240 + int(U8(((v >> 18) & u32(7)))))
	z_out[1] = i8(128 + int(U8(((v >> 12) & u32(63)))))
	z_out[2] = i8(128 + int(U8(((v >> 6) & u32(63)))))
	z_out[3] = i8(128 + int(U8((v & u32(63)))))
	return 4
}

@[c:'sqlite3Utf8Read']
fn sqlite3_utf8_read(pz &&u8) u32 {
	c := u32(0)
	c = unsafe { *(c2v_pointer_postfix(voidptr(&(*pz)), (*pz), isize(1))) }
	if c >= u32(192) {
		c = u32(sqlite3_utf8_trans1[c - u32(192)])
		for (int((unsafe { *(*pz) })) & 192) == 128 {
			c = (c << 6) + u32((63 & int((unsafe { *(c2v_pointer_postfix(voidptr(&(*pz)), (*pz), isize(1))) }))))
		}
		if c < u32(128) || (c & u32(4294965248)) == u32(55296) || (c & u32(4294967294)) == u32(65534) {
			c = u32(65533)
		}
	}
	return c
}

@[c:'sqlite3Utf8ReadLimited']
fn sqlite3_utf8_read_limited(z &U8, n int, pi_out &u32) int {
	c := u32(0)
	i := 1
	c = u32(z[0])
	if c >= u32(192) {
		c = u32(sqlite3_utf8_trans1[c - u32(192)])
		if n > 4 {
			n = 4
		}
		for i < n && (int(z[i]) & 192) == 128 {
			c = (c << 6) + u32((63 & int(z[i])))
			i++
		}
	}
	unsafe { *pi_out = c }
	return i
}

@[c:'sqlite3VdbeMemTranslate']
fn sqlite3_vdbe_mem_translate(p_mem &Mem, desired_enc U8) int {
	len := Sqlite3_int64(0)
	z_out := &u8(0)
	z_in := &u8(0)
	z_term := &u8(0)
	z := &u8(0)
	c := u32(0)
	if int(p_mem.enc) != 1 && int(desired_enc) != 1 {
		temp := U8(0)
		rc := 0
		rc = sqlite3_vdbe_mem_make_writeable(p_mem)
		if rc != 0 {
			return 7
		}
		z_in = &U8(voidptr(p_mem.z))
		z_term = unsafe { z_in + (p_mem.n & ~1) }
		for usize(z_in) < usize(z_term) {
			temp = unsafe { *z_in }
			unsafe { *z_in = *(z_in + 1) }
			c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1))
			mut __c2v_lhs_tmp_23 := unsafe { c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1)) }
			unsafe { *__c2v_lhs_tmp_23 = temp }
		}
		p_mem.enc = desired_enc
		unsafe { goto translate_out
		 }
	}
	if int(desired_enc) == 1 {
		p_mem.n &= ~1
		len = Sqlite3_int64(2) * Sqlite3_int64(p_mem.n) + Sqlite3_int64(1)
	} else {
		len = Sqlite3_int64(2) * Sqlite3_int64(p_mem.n) + Sqlite3_int64(2)
	}
	z_in = &U8(voidptr(p_mem.z))
	z_term = unsafe { z_in + p_mem.n }
	z_out = &u8(sqlite3_db_malloc_raw(p_mem.db, U64(len)))
	if isnil(z_out) {
		return 7
	}
	z = z_out
	if int(p_mem.enc) == 1 {
		if int(desired_enc) == 2 {
			for usize(z_in) < usize(z_term) {
				c = unsafe { *(c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1))) }
				if c >= u32(192) {
					c = u32(sqlite3_utf8_trans1[c - u32(192)])
					for usize(z_in) < usize(z_term) && (int((unsafe { *z_in })) & 192) == 128 {
						c = (c << 6) + u32((63 & int((unsafe { *(c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1))) }))))
					}
					if c < u32(128) || (c & u32(4294965248)) == u32(55296) || (c & u32(4294967294)) == u32(65534) {
						c = u32(65533)
					}
				}
				if c <= u32(65535) {
					mut __c2v_lhs_tmp_24 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_24 = U8((c & u32(255))) }
					mut __c2v_lhs_tmp_25 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_25 = U8(((c >> 8) & u32(255))) }
				} else {
					mut __c2v_lhs_tmp_26 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_26 = U8((((c >> 10) & u32(63)) + (((c - u32(65536)) >> 10) & u32(192)))) }
					mut __c2v_lhs_tmp_27 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_27 = U8((u32(216) + (((c - u32(65536)) >> 18) & u32(3)))) }
					mut __c2v_lhs_tmp_28 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_28 = U8((c & u32(255))) }
					mut __c2v_lhs_tmp_29 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_29 = U8((u32(220) + ((c >> 8) & u32(3)))) }
				}
			}
		} else {
			for usize(z_in) < usize(z_term) {
				c = unsafe { *(c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1))) }
				if c >= u32(192) {
					c = u32(sqlite3_utf8_trans1[c - u32(192)])
					for usize(z_in) < usize(z_term) && (int((unsafe { *z_in })) & 192) == 128 {
						c = (c << 6) + u32((63 & int((unsafe { *(c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1))) }))))
					}
					if c < u32(128) || (c & u32(4294965248)) == u32(55296) || (c & u32(4294967294)) == u32(65534) {
						c = u32(65533)
					}
				}
				if c <= u32(65535) {
					mut __c2v_lhs_tmp_30 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_30 = U8(((c >> 8) & u32(255))) }
					mut __c2v_lhs_tmp_31 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_31 = U8((c & u32(255))) }
				} else {
					mut __c2v_lhs_tmp_32 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_32 = U8((u32(216) + (((c - u32(65536)) >> 18) & u32(3)))) }
					mut __c2v_lhs_tmp_33 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_33 = U8((((c >> 10) & u32(63)) + (((c - u32(65536)) >> 10) & u32(192)))) }
					mut __c2v_lhs_tmp_34 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_34 = U8((u32(220) + ((c >> 8) & u32(3)))) }
					mut __c2v_lhs_tmp_35 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_35 = U8((c & u32(255))) }
				}
			}
		}
		p_mem.n = int((i64((isize(z) - isize(z_out)) / isize(sizeof(u8)))))
		mut __c2v_lhs_tmp_36 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
		unsafe { *__c2v_lhs_tmp_36 = u8(0) }
	} else {
		if int(p_mem.enc) == 2 {
			for usize(z_in) < usize(z_term) {
				c = unsafe { *(c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1))) }
				c += u32(int((unsafe { *(c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1))) })) << 8)
				if c >= u32(55296) && c < u32(57344) {
					if usize(z_in) < usize(z_term) {
						c2 := int((unsafe { *c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1)) }))
						c2 += (int((unsafe { *c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1)) })) << 8)
						c = u32((c2 & 1023)) + ((c & u32(63)) << 10) + (((c & u32(960)) + u32(64)) << 10)
					}
				}
				if c < u32(128) {
					mut __c2v_lhs_tmp_37 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_37 = U8((c & u32(255))) }
				} else if c < u32(2048) {
					mut __c2v_lhs_tmp_38 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_38 = u8(192 + int(U8(((c >> 6) & u32(31))))) }
					mut __c2v_lhs_tmp_39 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_39 = u8(128 + int(U8((c & u32(63))))) }
				} else if c < u32(65536) {
					mut __c2v_lhs_tmp_40 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_40 = u8(224 + int(U8(((c >> 12) & u32(15))))) }
					mut __c2v_lhs_tmp_41 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_41 = u8(128 + int(U8(((c >> 6) & u32(63))))) }
					mut __c2v_lhs_tmp_42 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_42 = u8(128 + int(U8((c & u32(63))))) }
				} else {
					mut __c2v_lhs_tmp_43 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_43 = u8(240 + int(U8(((c >> 18) & u32(7))))) }
					mut __c2v_lhs_tmp_44 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_44 = u8(128 + int(U8(((c >> 12) & u32(63))))) }
					mut __c2v_lhs_tmp_45 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_45 = u8(128 + int(U8(((c >> 6) & u32(63))))) }
					mut __c2v_lhs_tmp_46 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_46 = u8(128 + int(U8((c & u32(63))))) }
				}
			}
		} else {
			for usize(z_in) < usize(z_term) {
				c = u32(int((unsafe { *(c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1))) })) << 8)
				c += u32((unsafe { *(c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1))) }))
				if c >= u32(55296) && c < u32(57344) {
					if usize(z_in) < usize(z_term) {
						c2 := (int((unsafe { *c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1)) })) << 8)
						c2 += int((unsafe { *c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1)) }))
						c = u32((c2 & 1023)) + ((c & u32(63)) << 10) + (((c & u32(960)) + u32(64)) << 10)
					}
				}
				if c < u32(128) {
					mut __c2v_lhs_tmp_47 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_47 = U8((c & u32(255))) }
				} else if c < u32(2048) {
					mut __c2v_lhs_tmp_48 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_48 = u8(192 + int(U8(((c >> 6) & u32(31))))) }
					mut __c2v_lhs_tmp_49 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_49 = u8(128 + int(U8((c & u32(63))))) }
				} else if c < u32(65536) {
					mut __c2v_lhs_tmp_50 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_50 = u8(224 + int(U8(((c >> 12) & u32(15))))) }
					mut __c2v_lhs_tmp_51 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_51 = u8(128 + int(U8(((c >> 6) & u32(63))))) }
					mut __c2v_lhs_tmp_52 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_52 = u8(128 + int(U8((c & u32(63))))) }
				} else {
					mut __c2v_lhs_tmp_53 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_53 = u8(240 + int(U8(((c >> 18) & u32(7))))) }
					mut __c2v_lhs_tmp_54 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_54 = u8(128 + int(U8(((c >> 12) & u32(63))))) }
					mut __c2v_lhs_tmp_55 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_55 = u8(128 + int(U8(((c >> 6) & u32(63))))) }
					mut __c2v_lhs_tmp_56 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
					unsafe { *__c2v_lhs_tmp_56 = u8(128 + int(U8((c & u32(63))))) }
				}
			}
		}
		p_mem.n = int((i64((isize(z) - isize(z_out)) / isize(sizeof(u8)))))
	}
	unsafe { *z = u8(0) }
	c = u32(2 | 512 | (int(p_mem.flags) & (63 | 2048)))
	sqlite3_vdbe_mem_release(p_mem)
	p_mem.flags = U16(c)
	p_mem.enc = desired_enc
	p_mem.z = &i8(voidptr(z_out))
	p_mem.zMalloc = p_mem.z
	p_mem.szMalloc = sqlite3_db_malloc_size(p_mem.db, voidptr(p_mem.z))
	translate_out:
	return 0
}

@[c:'sqlite3VdbeMemHandleBom']
fn sqlite3_vdbe_mem_handle_bom(p_mem &Mem) int {
	rc := 0
	bom := U8(0)
	if p_mem.n > 1 {
		b1 := (unsafe { *&U8(voidptr(p_mem.z)) })
		b2 := (unsafe { *((&U8(voidptr(p_mem.z))) + 1) })
		if int(b1) == 254 && int(b2) == 255 {
			bom = U8(3)
		}
		if int(b1) == 255 && int(b2) == 254 {
			bom = U8(2)
		}
	}
	if bom {
		rc = sqlite3_vdbe_mem_make_writeable(p_mem)
		if rc == 0 {
			p_mem.n -= 2
			C.memmove(voidptr(p_mem.z), voidptr(unsafe { p_mem.z + 2 }), u64(p_mem.n))
			p_mem.z[p_mem.n] = i8(`\0`)
			p_mem.z[p_mem.n + 1] = i8(`\0`)
			p_mem.flags |= 512
			p_mem.enc = bom
		}
	}
	return rc
}

@[c:'sqlite3Utf8CharLen']
fn sqlite3_utf8_char_len(z_in &i8, n_byte int) int {
	r := 0
	z := &U8(voidptr(z_in))
	z_term := &U8(0)
	if n_byte >= 0 {
		z_term = unsafe { z + n_byte }
	} else {
		z_term = &U8((-1))
	}
	for int((unsafe { *z })) != 0 && usize(z) < usize(z_term) {
		if int((unsafe { *(c2v_pointer_postfix(voidptr(&z), z, isize(1))) })) >= 192 {
			for (int((unsafe { *z })) & 192) == 128 {
				c2v_pointer_postfix(voidptr(&z), z, isize(1))
			}
		}
		r++
	}
	return r
}

@[c:'sqlite3Utf16to8']
fn sqlite3_utf16to8(db &Sqlite3, z voidptr, n_byte int, enc U8) &i8 {
	m := Mem{}
	C.memset(voidptr(&m), 0, sizeof(m))
	m.db = db
	sqlite3_vdbe_mem_set_str(&m, &i8(z), I64(n_byte), enc, (C2vFn_666e2028766f696470747229(voidptr(0))))
	sqlite3_vdbe_change_encoding(&m, 1)
	if db.mallocFailed {
		sqlite3_vdbe_mem_release(&m)
		m.z = 0
	}
	return m.z
}

@[c:'sqlite3Utf16ByteLen']
fn sqlite3_utf16_byte_len(z_in voidptr, n_byte int, n_char int) int {
	c := 0
	z := &u8(z_in)
	z_end := unsafe { z + (n_byte - 1) }
	n := 0
	if 2 == 2 {
		c2v_pointer_postfix(voidptr(&z), z, isize(1))
	}
	for n < n_char && usize(z) <= usize(z_end) {
		c = int(z[0])
		c2v_pointer_prefix(voidptr(&z), z, isize(2))
		if c >= 216 && c < 220 && usize(z) <= usize(z_end) && int(z[0]) >= 220 && int(z[0]) < 224 {
			c2v_pointer_prefix(voidptr(&z), z, isize(2))
		}
		n++
	}
	return int((i64((isize(z) - isize(&u8(z_in))) / isize(sizeof(u8))))) - int((2 == 2))
}
