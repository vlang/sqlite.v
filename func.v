@[translated]
module main

@[c:'sqlite3GetFuncCollSeq']
fn sqlite3_get_func_coll_seq(context &Sqlite3_context) &CollSeq {
	p_op := &VdbeOp(0)
	p_op = unsafe { context.pVdbe.aOp + (context.iOp - 1) }
	return p_op.p4.pColl
}

@[c:'sqlite3SkipAccumulatorLoad']
fn sqlite3_skip_accumulator_load(context &Sqlite3_context) {
	context.isError = -1
	context.skipFlag = U8(1)
}

@[c:'minmaxFunc']
fn minmax_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	i := 0
	mask := 0
	i_best := 0
	p_coll := &CollSeq(0)
	mask = if usize(sqlite3_user_data(context)) == usize(0) { 0 } else { -1 }
	p_coll = sqlite3_get_func_coll_seq(context)
	i_best = 0
	if sqlite3_value_type(argv[0]) == 5 {
		return
	}
	for i = 1; i < argc; i++ {
		if sqlite3_value_type(argv[i]) == 5 {
			return
		}
		if (sqlite3_mem_compare(argv[i_best], argv[i], p_coll) ^ mask) >= 0 {
			i_best = i
		}
	}
	sqlite3_result_value(context, argv[i_best])
}

@[c:'typeofFunc']
fn typeof_func(context &Sqlite3_context, not_used int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	if !typeof_func_az_type_inited {
		c2v_static_init := [c'integer', c'real', c'text', c'blob', c'null']
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			typeof_func_az_type[c2v_i_0] = c2v_element_0
		}
		typeof_func_az_type_inited = true
	}

	i := sqlite3_value_type(argv[0]) - 1

	sqlite3_result_text(context, typeof_func_az_type[i], -1, (C2vFn_666e2028766f696470747229(voidptr(0))))
}

@[c:'subtypeFunc']
fn subtype_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()

	sqlite3_result_int(context, int(sqlite3_value_subtype(argv[0])))
}

@[c:'lengthFunc']
fn length_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()

	match sqlite3_value_type(argv[0]) {
		4, 1, 2 {
			sqlite3_result_int(context, sqlite3_value_bytes(argv[0]))
		}
		3 {
			z := sqlite3_value_text(argv[0])
			z0 := &u8(0)
			c := u8(0)
			if usize(z) == usize(0) {
				return
			}
			z0 = z
			for {
				c = unsafe { *z }
				if !(int(c) != 0) {
					break
				}
				c2v_pointer_postfix(voidptr(&z), z, isize(1))
				if int(c) >= 192 {
					for (int((unsafe { *z })) & 192) == 128 {
						c2v_pointer_postfix(voidptr(&z), z, isize(1))
						c2v_pointer_postfix(voidptr(&z0), z0, isize(1))
					}
				}
			}
			sqlite3_result_int(context, int((i64((isize(z) - isize(z0)) / isize(sizeof(u8))))))
		}
		else {
			sqlite3_result_null(context)
		}
	}
}

@[c:'bytelengthFunc']
fn bytelength_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()

	match sqlite3_value_type(argv[0]) {
		4 {
			sqlite3_result_int(context, sqlite3_value_bytes(argv[0]))
		}
		1, 2 {
			m := I64(if int(sqlite3_context_db_handle(context).enc) <= 1 { 1 } else { 2 })
			sqlite3_result_int64(context, I64(sqlite3_value_bytes(argv[0])) * m)
		}
		3 {
			if sqlite3_value_encoding(argv[0]) <= 1 {
				sqlite3_result_int(context, sqlite3_value_bytes(argv[0]))
			} else {
				sqlite3_result_int(context, sqlite3_value_bytes16(argv[0]))
			}
		}
		else {
			sqlite3_result_null(context)
		}
	}
}

@[c:'absFunc']
fn abs_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()

	match sqlite3_value_type(argv[0]) {
		1 {
			i_val := sqlite3_value_int64(argv[0])
			if i_val < I64(0) {
				if i_val == ((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32))) {
					sqlite3_result_error(context, c'integer overflow', -1)
					return
				}
				i_val = -i_val
			}
			sqlite3_result_int64(context, i_val)
		}
		5 {
			sqlite3_result_null(context)
		}
		else {
			r_val := sqlite3_value_double(argv[0])
			if r_val < f64(0) {
				r_val = -r_val
			}
			sqlite3_result_double(context, r_val)
		}
	}
}

@[c:'instrFunc']
fn instr_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z_haystack := &u8(0)
	z_needle := &u8(0)
	n_haystack := 0
	n_needle := 0
	type_haystack := 0
	type_needle := 0

	n := 1
	is_text := 0
	first_char := u8(0)
	p_c1 := unsafe { &Sqlite3_value(nil) }
	p_c2 := unsafe { &Sqlite3_value(nil) }

	type_haystack = sqlite3_value_type(argv[0])
	type_needle = sqlite3_value_type(argv[1])
	if type_haystack == 5 || type_needle == 5 {
		return
	}
	n_haystack = sqlite3_value_bytes(argv[0])
	n_needle = sqlite3_value_bytes(argv[1])
	if n_needle > 0 {
		if type_haystack == 4 && type_needle == 4 {
			z_haystack = &u8(sqlite3_value_blob(argv[0]))
			z_needle = &u8(sqlite3_value_blob(argv[1]))
			is_text = 0
		} else if type_haystack != 4 && type_needle != 4 {
			z_haystack = sqlite3_value_text(argv[0])
			z_needle = sqlite3_value_text(argv[1])
			is_text = 1
		} else {
			p_c1 = sqlite3_value_dup(argv[0])
			z_haystack = sqlite3_value_text(p_c1)
			if usize(z_haystack) == usize(0) {
				unsafe { goto endInstrOOM
				 }
			}
			n_haystack = sqlite3_value_bytes(p_c1)
			p_c2 = sqlite3_value_dup(argv[1])
			z_needle = sqlite3_value_text(p_c2)
			if usize(z_needle) == usize(0) {
				unsafe { goto endInstrOOM
				 }
			}
			n_needle = sqlite3_value_bytes(p_c2)
			is_text = 1
		}
		if usize(z_needle) == usize(0) || (n_haystack && usize(z_haystack) == usize(0)) {
			unsafe { goto endInstrOOM
			 }
		}
		first_char = z_needle[0]
		for n_needle <= n_haystack && (int(z_haystack[0]) != int(first_char) || C.memcmp(voidptr(z_haystack), voidptr(z_needle), u64(n_needle)) != 0) {
			n++
			for {
				n_haystack--
				c2v_pointer_postfix(voidptr(&z_haystack), z_haystack, isize(1))
				if !(is_text && (int(z_haystack[0]) & 192) == 128) {
					break
				}
			}
		}
		if n_needle > n_haystack {
			n = 0
		}
	}
	sqlite3_result_int(context, n)
	endInstr:
	sqlite3_value_free(p_c1)
	sqlite3_value_free(p_c2)
	return
	endInstrOOM:
	sqlite3_result_error_nomem(context)
	unsafe { goto endInstr
	 }
}

@[c:'printfFunc']
fn printf_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	x := PrintfArguments{}
	str := StrAccum{}
	z_format := &i8(0)
	n := 0
	db := sqlite3_context_db_handle(context)
	if argc >= 1 && usize(c2v_assign[&i8](unsafe { &z_format }, &i8(voidptr(sqlite3_value_text(argv[0]))))) != usize(0) {
		x.nArg = argc - 1
		x.nUsed = 0
		x.apArg = argv + 1
		sqlite3_str_accum_init(&str, db, unsafe { nil }, 0, db.aLimit[0])
		str.printfFlags = U8(2)
		sqlite3_str_appendf(unsafe { &Sqlite3_str(&str) }, z_format, voidptr(&x))
		if int(str.accError) == 0 {
			n = int(str.nChar)
			sqlite3_result_text(context, sqlite3_str_accum_finish(&str), n, (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))))
		} else {
			if int(str.accError) == 7 {
				sqlite3_result_error_nomem(context)
			} else {
				sqlite3_result_error_toobig(context)
			}
			sqlite3_str_reset(unsafe { &Sqlite3_str(&str) })
		}
	}
}

@[c:'substrFunc']
fn substr_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z := &u8(0)
	z2 := &u8(0)
	len := 0
	p0type := 0
	p1 := I64(0)
	p2 := I64(0)

	p0type = sqlite3_value_type(argv[0])
	p1 = sqlite3_value_int64(argv[1])
	if p0type == 4 {
		len = sqlite3_value_bytes(argv[0])
		z = &u8(sqlite3_value_blob(argv[0]))
		if usize(z) == usize(0) {
			return
		}
	} else {
		z = sqlite3_value_text(argv[0])
		if usize(z) == usize(0) {
			return
		}
		len = 0
		if p1 < I64(0) {
			for z2 = z; (unsafe { *z2 }); len++ {
				if int((unsafe { *(c2v_pointer_postfix(voidptr(&z2), z2, isize(1))) })) >= 192 {
					for (int((unsafe { *z2 })) & 192) == 128 {
						c2v_pointer_postfix(voidptr(&z2), z2, isize(1))
					}
				}
			}
		}
	}
	if argc == 3 {
		p2 = sqlite3_value_int64(argv[2])
		if p2 == I64(0) && sqlite3_value_type(argv[2]) == 5 {
			return
		}
	} else {
		p2 = I64(sqlite3_context_db_handle(context).aLimit[0])
	}
	if p1 == I64(0) {
		if sqlite3_value_type(argv[1]) == 5 {
			return
		}
	}
	if p1 < I64(0) {
		p1 += I64(len)
		if p1 < I64(0) {
			if p2 < I64(0) {
				p2 = I64(0)
			} else {
				p2 += p1
			}
			p1 = I64(0)
		}
	} else if p1 > I64(0) {
		p1--
	} else if p2 > I64(0) {
		p2--
	}
	if p2 < I64(0) {
		if p2 < -p1 {
			p2 = p1
		} else {
			p2 = -p2
		}
		p1 -= p2
	}
	if p0type != 4 {
		for int((unsafe { *z })) && p1 {
			if int((unsafe { *(c2v_pointer_postfix(voidptr(&z), z, isize(1))) })) >= 192 {
				for (int((unsafe { *z })) & 192) == 128 {
					c2v_pointer_postfix(voidptr(&z), z, isize(1))
				}
			}
			p1--
		}
		for z2 = z; int((unsafe { *z2 })) && p2; p2-- {
			if int((unsafe { *(c2v_pointer_postfix(voidptr(&z2), z2, isize(1))) })) >= 192 {
				for (int((unsafe { *z2 })) & 192) == 128 {
					c2v_pointer_postfix(voidptr(&z2), z2, isize(1))
				}
			}
		}
		sqlite3_result_text64(context, &i8(voidptr(z)), Sqlite3_uint64(i64((isize(z2) - isize(z)) / isize(sizeof(u8)))), (C2vFn_666e2028766f696470747229(voidptr(-1))), u8(1))
	} else {
		if p1 >= I64(len) {
			p2 = I64(0)
			p1 = p2
		} else if p2 > I64(len) - p1 {
			p2 = I64(len) - p1
		}
		sqlite3_result_blob64(context, voidptr(&i8(voidptr(unsafe { z + p1 }))), U64(p2), (C2vFn_666e2028766f696470747229(voidptr(-1))))
	}
}

@[c:'roundFunc']
fn round_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	n := I64(0)
	r := 0.0
	z_buf := &i8(0)
	if argc == 2 {
		if 5 == sqlite3_value_type(argv[1]) {
			return
		}
		n = sqlite3_value_int64(argv[1])
		if n > I64(30) {
			n = I64(30)
		}
		if n < I64(0) {
			n = I64(0)
		}
	}
	if sqlite3_value_type(argv[0]) == 5 {
		return
	}
	r = sqlite3_value_double(argv[0])
	if r < -4503599627370496.0 || r > 4503599627370496.0 {
	} else if n == I64(0) {
		r = f64((Sqlite_int64((r + (if r < f64(0) { -0.5 } else { 0.5 })))))
	} else {
		z_buf = sqlite3_mprintf(c'%!.*f', int(n), r)
		if usize(z_buf) == usize(0) {
			sqlite3_result_error_nomem(context)
			return
		}
		sqlite3_ato_f(z_buf, &r)
		sqlite3_free(voidptr(z_buf))
	}
	sqlite3_result_double(context, r)
}

@[c:'contextMalloc']
fn context_malloc(context &Sqlite3_context, n_byte I64) voidptr {
	z := &i8(0)
	db := sqlite3_context_db_handle(context)
	if n_byte > I64(db.aLimit[0]) {
		sqlite3_result_error_toobig(context)
		z = 0
	} else {
		z = &i8(sqlite3_malloc_vdup2(U64(n_byte)))
		if isnil(z) {
			sqlite3_result_error_nomem(context)
		}
	}
	return z
}

@[c:'upperFunc']
fn upper_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z1 := &i8(0)
	z2 := &i8(0)
	i := 0
	n := 0

	z2 = &i8(voidptr(sqlite3_value_text(argv[0])))
	n = sqlite3_value_bytes(argv[0])
	if z2 {
		z1 = &i8(context_malloc(context, (I64(n)) + I64(1)))
		if z1 {
			for i = 0; i < n; i++ {
				z1[i] = i8((int(z2[i]) & ~(int(sqlite3CtypeMap[u8(z2[i])]) & 32)))
			}
			sqlite3_result_text(context, z1, n, sqlite3_free)
		}
	}
}

@[c:'lowerFunc']
fn lower_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z1 := &i8(0)
	z2 := &i8(0)
	i := 0
	n := 0

	z2 = &i8(voidptr(sqlite3_value_text(argv[0])))
	n = sqlite3_value_bytes(argv[0])
	if z2 {
		z1 = &i8(context_malloc(context, (I64(n)) + I64(1)))
		if z1 {
			for i = 0; i < n; i++ {
				z1[i] = i8(sqlite3UpperToLower[u8(z2[i])])
			}
			sqlite3_result_text(context, z1, n, sqlite3_free)
		}
	}
}

@[c:'randomFunc']
fn random_func(context &Sqlite3_context, not_used int, not_used2 &&Sqlite3_value) {
	c2v_gc_register_thread()
	r := Sqlite_int64(0)

	sqlite3_randomness(int(sizeof(r)), voidptr(&r))
	if r < Sqlite_int64(0) {
		r = -(r & (I64(u32(4294967295)) | ((I64(2147483647)) << 32)))
	}
	sqlite3_result_int64(context, r)
}

@[c:'randomBlob']
fn random_blob(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	n := Sqlite3_int64(0)
	p := &u8(0)

	n = sqlite3_value_int64(argv[0])
	if n < Sqlite3_int64(1) {
		n = Sqlite3_int64(1)
	}
	p = &u8(context_malloc(context, n))
	if p {
		sqlite3_randomness(int(n), voidptr(p))
		sqlite3_result_blob(context, voidptr(&i8(voidptr(p))), int(n), sqlite3_free)
	}
}

fn last_insert_rowid(context &Sqlite3_context, not_used int, not_used2 &&Sqlite3_value) {
	c2v_gc_register_thread()
	db := sqlite3_context_db_handle(context)

	sqlite3_result_int64(context, sqlite3_last_insert_rowid(db))
}

fn changes(context &Sqlite3_context, not_used int, not_used2 &&Sqlite3_value) {
	c2v_gc_register_thread()
	db := sqlite3_context_db_handle(context)

	sqlite3_result_int64(context, sqlite3_changes64(db))
}

fn total_changes(context &Sqlite3_context, not_used int, not_used2 &&Sqlite3_value) {
	c2v_gc_register_thread()
	db := sqlite3_context_db_handle(context)

	sqlite3_result_int64(context, sqlite3_total_changes64(db))
}

struct CompareInfo {
	matchAll U8
	matchOne U8
	matchSet U8
	noCase   U8
}

@[c:'patternCompare']
fn pattern_compare(z_pattern_param &U8, z_string_param &U8, p_info &CompareInfo, match_other u32) int {
	mut z_pattern := z_pattern_param
	mut z_string := z_string_param
	c := u32(0)
	c2 := u32(0)

	match_one := u32(p_info.matchOne)
	match_all := u32(p_info.matchAll)
	no_case := p_info.noCase
	z_escaped := unsafe { &U8(nil) }
	for {
		c = (if int(z_pattern[0]) < 128 {
			u32((unsafe { *(c2v_pointer_postfix(voidptr(&z_pattern), z_pattern, isize(1))) }))
		} else {
			sqlite3_utf8_read(&&U8(&&U8(c2v_address_of(&z_pattern))))
		})
		if !(c != u32(0)) {
			break
		}
		if c == match_all {
			for {
				c = (if int(z_pattern[0]) < 128 {
					u32((unsafe { *(c2v_pointer_postfix(voidptr(&z_pattern), z_pattern, isize(1))) }))
				} else {
					sqlite3_utf8_read(&&U8(&&U8(c2v_address_of(&z_pattern))))
				})
				if !(c == match_all || (c == match_one && match_one != u32(0))) {
					break
				}
				if c == match_one && sqlite3_utf8_read(&&U8(&&U8(c2v_address_of(&z_string)))) == u32(0) {
					return 2
				}
			}
			if c == u32(0) {
				return 0
			} else if c == match_other {
				if int(p_info.matchSet) == 0 {
					c = sqlite3_utf8_read(&&U8(&&U8(c2v_address_of(&z_pattern))))
					if c == u32(0) {
						return 2
					}
				} else {
					for (unsafe { *z_string }) {
						b_match := pattern_compare(unsafe { z_pattern + -1 }, z_string, p_info, match_other)
						if b_match != 1 {
							return b_match
						}
						if int((unsafe { *(c2v_pointer_postfix(voidptr(&z_string), z_string, isize(1))) })) >= 192 {
							for (int((unsafe { *z_string })) & 192) == 128 {
								c2v_pointer_postfix(voidptr(&z_string), z_string, isize(1))
							}
						}
					}
					return 2
				}
			}
			if c < u32(128) {
				z_stop := [3]i8{}
				b_match := 0
				if no_case {
					z_stop[0] = i8((c & u32(~(int(sqlite3CtypeMap[u8(c)]) & 32))))
					z_stop[1] = i8(sqlite3UpperToLower[u8(c)])
					z_stop[2] = i8(0)
				} else {
					z_stop[0] = i8(c)
					z_stop[1] = i8(0)
				}
				for {
					c2v_pointer_prefix(voidptr(&z_string), z_string, isize(C.strcspn(&i8(voidptr(z_string)), unsafe { &i8(&z_stop[0]) })))
					if int(z_string[0]) == 0 {
						break
					}
					c2v_pointer_postfix(voidptr(&z_string), z_string, isize(1))
					b_match = pattern_compare(z_pattern, z_string, p_info, match_other)
					if b_match != 1 {
						return b_match
					}
				}
			} else {
				b_match := 0
				for {
					c2 = (if int(z_string[0]) < 128 {
						u32((unsafe { *(c2v_pointer_postfix(voidptr(&z_string), z_string, isize(1))) }))
					} else {
						sqlite3_utf8_read(&&U8(&&U8(c2v_address_of(&z_string))))
					})
					if !(c2 != u32(0)) {
						break
					}
					if c2 != c {
						continue
					}
					b_match = pattern_compare(z_pattern, z_string, p_info, match_other)
					if b_match != 1 {
						return b_match
					}
				}
			}
			return 2
		}
		if c == match_other {
			if int(p_info.matchSet) == 0 {
				c = sqlite3_utf8_read(&&U8(&&U8(c2v_address_of(&z_pattern))))
				if c == u32(0) {
					return 1
				}
				z_escaped = z_pattern
			} else {
				prior_c := u32(0)
				seen := 0
				invert := 0
				c = sqlite3_utf8_read(&&U8(&&U8(c2v_address_of(&z_string))))
				if c == u32(0) {
					return 1
				}
				c2 = sqlite3_utf8_read(&&U8(&&U8(c2v_address_of(&z_pattern))))
				if c2 == u32(`^`) {
					invert = 1
					c2 = sqlite3_utf8_read(&&U8(&&U8(c2v_address_of(&z_pattern))))
				}
				if c2 == u32(`]`) {
					if c == u32(`]`) {
						seen = 1
					}
					c2 = sqlite3_utf8_read(&&U8(&&U8(c2v_address_of(&z_pattern))))
				}
				for c2 && c2 != u32(`]`) {
					if c2 == u32(`-`) && int(z_pattern[0]) != `]` && int(z_pattern[0]) != 0 && prior_c > u32(0) {
						c2 = sqlite3_utf8_read(&&U8(&&U8(c2v_address_of(&z_pattern))))
						if c >= prior_c && c <= c2 {
							seen = 1
						}
						prior_c = u32(0)
					} else {
						if c == c2 {
							seen = 1
						}
						prior_c = c2
					}
					c2 = sqlite3_utf8_read(&&U8(&&U8(c2v_address_of(&z_pattern))))
				}
				if c2 == u32(0) || (seen ^ invert) == 0 {
					return 1
				}
				continue
			}
		}
		c2 = (if int(z_string[0]) < 128 {
			u32((unsafe { *(c2v_pointer_postfix(voidptr(&z_string), z_string, isize(1))) }))
		} else {
			sqlite3_utf8_read(&&U8(&&U8(c2v_address_of(&z_string))))
		})
		if c == c2 {
			continue
		}
		if int(no_case) && int(sqlite3UpperToLower[u8(c)]) == int(sqlite3UpperToLower[u8(c2)]) && c < u32(128) && c2 < u32(128) {
			continue
		}
		if c == match_one && usize(z_pattern) != usize(z_escaped) && c2 != u32(0) {
			continue
		}
		return 1
	}
	return if int((unsafe { *z_string })) == 0 { 0 } else { 1 }
}

fn sqlite3_strglob(z_glob_pattern &i8, z_string &i8) int {
	c2v_gc_register_thread()
	if usize(z_string) == usize(0) {
		return int(usize(z_glob_pattern) != usize(0))
	} else if usize(z_glob_pattern) == usize(0) {
		return 1
	} else {
		return pattern_compare(&U8(voidptr(z_glob_pattern)), &U8(voidptr(z_string)), &globInfo, u32(`[`))
	}
}

fn sqlite3_strlike(z_pattern &i8, z_str &i8, esc u32) int {
	c2v_gc_register_thread()
	if usize(z_str) == usize(0) {
		return int(usize(z_pattern) != usize(0))
	} else if usize(z_pattern) == usize(0) {
		return 1
	} else {
		return pattern_compare(&U8(voidptr(z_pattern)), &U8(voidptr(z_str)), &likeInfoNorm, esc)
	}
}

@[c:'likeFunc']
fn like_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	za := &u8(0)
	zb := &u8(0)

	escape := u32(0)
	n_pat := 0
	db := sqlite3_context_db_handle(context)
	p_info := &CompareInfo(sqlite3_user_data(context))
	backup_info := CompareInfo{}
	n_pat = sqlite3_value_bytes(argv[0])
	if n_pat > db.aLimit[8] {
		sqlite3_result_error(context, c'LIKE or GLOB pattern too complex', -1)
		return
	}
	if argc == 3 {
		z_esc := sqlite3_value_text(argv[2])
		if usize(z_esc) == usize(0) {
			return
		}
		if sqlite3_utf8_char_len(&i8(voidptr(z_esc)), -1) != 1 {
			sqlite3_result_error(context, c'ESCAPE expression must be a single character', -1)
			return
		}
		escape = sqlite3_utf8_read(unsafe { &&U8(&&u8(c2v_address_of(&z_esc))) })
		if escape == u32(p_info.matchAll) || escape == u32(p_info.matchOne) {
			C.memcpy(voidptr(&backup_info), voidptr(p_info), sizeof(backup_info))
			p_info = &backup_info
			if escape == u32(p_info.matchAll) {
				p_info.matchAll = U8(0)
			}
			if escape == u32(p_info.matchOne) {
				p_info.matchOne = U8(0)
			}
		}
	} else {
		escape = u32(p_info.matchSet)
	}
	zb = sqlite3_value_text(argv[0])
	za = sqlite3_value_text(argv[1])
	if !isnil(za) && !isnil(zb) {
		sqlite3_result_int(context, pattern_compare(unsafe { &U8(zb) }, unsafe { &U8(za) }, p_info, escape) == 0)
	}
}

@[c:'nullifFunc']
fn nullif_func(context &Sqlite3_context, not_used int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	p_coll := sqlite3_get_func_coll_seq(context)

	if sqlite3_mem_compare(argv[0], argv[1], p_coll) != 0 {
		sqlite3_result_value(context, argv[0])
	}
}

@[c:'versionFunc']
fn version_func(context &Sqlite3_context, not_used int, not_used2 &&Sqlite3_value) {
	c2v_gc_register_thread()

	sqlite3_result_text(context, sqlite3_libversion(), -1, (C2vFn_666e2028766f696470747229(voidptr(0))))
}

@[c:'sourceidFunc']
fn sourceid_func(context &Sqlite3_context, not_used int, not_used2 &&Sqlite3_value) {
	c2v_gc_register_thread()

	sqlite3_result_text(context, sqlite3_sourceid(), -1, (C2vFn_666e2028766f696470747229(voidptr(0))))
}

@[c:'errlogFunc']
fn errlog_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()

	sqlite3_log(sqlite3_value_int(argv[0]), c'%s', voidptr(sqlite3_value_text(argv[1])))
}

@[c:'compileoptionusedFunc']
fn compileoptionused_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z_opt_name := &i8(0)

	z_opt_name = &i8(voidptr(sqlite3_value_text(argv[0])))
	if usize(z_opt_name) != usize(0) {
		sqlite3_result_int(context, sqlite3_compileoption_used(z_opt_name))
	}
}

@[c:'compileoptiongetFunc']
fn compileoptionget_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	n := 0

	n = sqlite3_value_int(argv[0])
	sqlite3_result_text(context, sqlite3_compileoption_get(n), -1, (C2vFn_666e2028766f696470747229(voidptr(0))))
}

@[c:'sqlite3QuoteValue']
fn sqlite3_quote_value(p_str &StrAccum, p_value &Sqlite3_value, b_escape int) {
	match sqlite3_value_type(p_value) {
		2 {
			sqlite3_str_appendf(unsafe { &Sqlite3_str(p_str) }, c'%!0.17g', sqlite3_value_double(p_value))
		}
		1 {
			sqlite3_str_appendf(unsafe { &Sqlite3_str(p_str) }, c'%lld', sqlite3_value_int64(p_value))
		}
		4 {
			z_blob := &i8(sqlite3_value_blob(p_value))
			n_blob := I64(sqlite3_value_bytes(p_value))
			sqlite3_str_accum_enlarge(p_str, n_blob * I64(2) + I64(4))
			if int(p_str.accError) == 0 {
				z_text := p_str.zText
				i := 0
				for i = 0; I64(i) < n_blob; i++ {
					z_text[(i * 2) + 2] = hexdigits[(int(z_blob[i]) >> 4) & 15]
					z_text[(i * 2) + 3] = hexdigits[int(z_blob[i]) & 15]
				}
				z_text[(n_blob * I64(2)) + I64(2)] = i8(`\'`)
				z_text[(n_blob * I64(2)) + I64(3)] = i8(`\0`)
				z_text[0] = i8(`X`)
				z_text[1] = i8(`\'`)
				p_str.nChar = u32(n_blob * I64(2) + I64(3))
			}
		}
		3 {
			z_arg := sqlite3_value_text(p_value)
			sqlite3_str_appendf(unsafe { &Sqlite3_str(p_str) }, unsafe { if b_escape {
				c'%#Q'
			} else {
				c'%Q'
			} }, voidptr(z_arg))
		}
		else {
			sqlite3_str_append(unsafe { &Sqlite3_str(p_str) }, c'NULL', 4)
		}
	}
}

@[c:'isNHex']
fn is_nh_ex(z &i8, n int, p_val &u32) int {
	i := 0
	v := u32(0)
	for i = 0; i < n; i++ {
		if !(int(sqlite3CtypeMap[u8(z[i])]) & 8) {
			return 0
		}
		v = (v << 4) + u32(sqlite3_hex_to_int(z[i]))
	}
	unsafe { *p_val = v }
	return 1
}

@[c:'unistrFunc']
fn unistr_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z_out := &i8(0)
	z_in := &i8(0)
	n_in := 0
	i := 0
	j := 0
	n := 0

	v := u32(0)

	z_in = &i8(voidptr(sqlite3_value_text(argv[0])))
	if usize(z_in) == usize(0) {
		return
	}
	n_in = sqlite3_value_bytes(argv[0])
	z_out = &i8(sqlite3_malloc64(Sqlite3_uint64(n_in + 1)))
	if usize(z_out) == usize(0) {
		sqlite3_result_error_nomem(context)
		return
	}
	j = 0
	i = j
	for i < n_in {
		z := C.strchr(unsafe { z_in + i }, `\\`)
		if usize(z) == usize(0) {
			n = n_in - i
			C.memmove(voidptr(unsafe { z_out + j }), voidptr(unsafe { z_in + i }), u64(n))
			j += n
			break
		}
		n = int(i64((isize(z) - isize(unsafe { z_in + i })) / isize(sizeof(i8))))
		if n > 0 {
			C.memmove(voidptr(unsafe { z_out + j }), voidptr(unsafe { z_in + i }), u64(n))
			j += n
			i += n
		}
		if int(z_in[i + 1]) == i8(`\\`) {
			i += 2
			z_out[j++] = i8(`\\`)
		} else if (int(sqlite3CtypeMap[u8(z_in[i + 1])]) & 8) {
			if !is_nh_ex(unsafe { z_in + (i + 1) }, 4, &v) {
				unsafe { goto unistr_error
				 }
			}
			i += 5
			j += sqlite3_append_one_utf8_character(unsafe { z_out + j }, v)
		} else if int(z_in[i + 1]) == i8(`+`) {
			if !is_nh_ex(unsafe { z_in + (i + 2) }, 6, &v) {
				unsafe { goto unistr_error
				 }
			}
			i += 8
			j += sqlite3_append_one_utf8_character(unsafe { z_out + j }, v)
		} else if int(z_in[i + 1]) == i8(`u`) {
			if !is_nh_ex(unsafe { z_in + (i + 2) }, 4, &v) {
				unsafe { goto unistr_error
				 }
			}
			i += 6
			j += sqlite3_append_one_utf8_character(unsafe { z_out + j }, v)
		} else if int(z_in[i + 1]) == i8(`U`) {
			if !is_nh_ex(unsafe { z_in + (i + 2) }, 8, &v) {
				unsafe { goto unistr_error
				 }
			}
			i += 10
			j += sqlite3_append_one_utf8_character(unsafe { z_out + j }, v)
		} else {
			unsafe { goto unistr_error
			 }
		}
	}
	z_out[j] = i8(0)
	sqlite3_result_text64(context, z_out, Sqlite3_uint64(j), sqlite3_free, u8(16))
	return
	unistr_error:
	sqlite3_free(voidptr(z_out))
	sqlite3_result_error(context, c'invalid Unicode escape', -1)
	return
}

@[c:'quoteFunc']
fn quote_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	str := Sqlite3_str{}
	db := sqlite3_context_db_handle(context)

	sqlite3_str_accum_init(unsafe { &StrAccum(&str) }, db, unsafe { nil }, 0, db.aLimit[0])
	sqlite3_quote_value(unsafe { &StrAccum(&str) }, argv[0], (int(i64(sqlite3_user_data(context)))))
	sqlite3_result_text(context, sqlite3_str_accum_finish(unsafe { &StrAccum(&str) }), int(str.nChar), (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))))
	if int(str.accError) != 0 {
		sqlite3_result_null(context)
		sqlite3_result_error_code(context, int(str.accError))
	}
}

@[c:'unicodeFunc']
fn unicode_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z := sqlite3_value_text(argv[0])

	if !isnil(z) && int(z[0]) {
		sqlite3_result_int(context, int(sqlite3_utf8_read(unsafe { &&U8(&&u8(c2v_address_of(&z))) })))
	}
}

@[c:'charFunc']
fn char_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z := &u8(0)
	z_out := &u8(0)

	i := 0
	z = &u8(sqlite3_malloc64(Sqlite3_uint64(argc * 4 + 1)))
	z_out = z
	if usize(z) == usize(0) {
		sqlite3_result_error_nomem(context)
		return
	}
	for i = 0; i < argc; i++ {
		x := Sqlite3_int64(0)
		c := u32(0)
		x = sqlite3_value_int64(argv[i])
		if x < Sqlite3_int64(0) || x > Sqlite3_int64(1114111) {
			x = Sqlite3_int64(65533)
		}
		c = u32((x & Sqlite3_int64(2097151)))
		if c < u32(128) {
			mut __c2v_lhs_tmp_119 := unsafe { c2v_pointer_postfix(voidptr(&z_out), z_out, isize(1)) }
			unsafe { *__c2v_lhs_tmp_119 = U8((c & u32(255))) }
		} else if c < u32(2048) {
			mut __c2v_lhs_tmp_120 := unsafe { c2v_pointer_postfix(voidptr(&z_out), z_out, isize(1)) }
			unsafe { *__c2v_lhs_tmp_120 = u8(192 + int(U8(((c >> 6) & u32(31))))) }
			mut __c2v_lhs_tmp_121 := unsafe { c2v_pointer_postfix(voidptr(&z_out), z_out, isize(1)) }
			unsafe { *__c2v_lhs_tmp_121 = u8(128 + int(U8((c & u32(63))))) }
		} else if c < u32(65536) {
			mut __c2v_lhs_tmp_122 := unsafe { c2v_pointer_postfix(voidptr(&z_out), z_out, isize(1)) }
			unsafe { *__c2v_lhs_tmp_122 = u8(224 + int(U8(((c >> 12) & u32(15))))) }
			mut __c2v_lhs_tmp_123 := unsafe { c2v_pointer_postfix(voidptr(&z_out), z_out, isize(1)) }
			unsafe { *__c2v_lhs_tmp_123 = u8(128 + int(U8(((c >> 6) & u32(63))))) }
			mut __c2v_lhs_tmp_124 := unsafe { c2v_pointer_postfix(voidptr(&z_out), z_out, isize(1)) }
			unsafe { *__c2v_lhs_tmp_124 = u8(128 + int(U8((c & u32(63))))) }
		} else {
			mut __c2v_lhs_tmp_125 := unsafe { c2v_pointer_postfix(voidptr(&z_out), z_out, isize(1)) }
			unsafe { *__c2v_lhs_tmp_125 = u8(240 + int(U8(((c >> 18) & u32(7))))) }
			mut __c2v_lhs_tmp_126 := unsafe { c2v_pointer_postfix(voidptr(&z_out), z_out, isize(1)) }
			unsafe { *__c2v_lhs_tmp_126 = u8(128 + int(U8(((c >> 12) & u32(63))))) }
			mut __c2v_lhs_tmp_127 := unsafe { c2v_pointer_postfix(voidptr(&z_out), z_out, isize(1)) }
			unsafe { *__c2v_lhs_tmp_127 = u8(128 + int(U8(((c >> 6) & u32(63))))) }
			mut __c2v_lhs_tmp_128 := unsafe { c2v_pointer_postfix(voidptr(&z_out), z_out, isize(1)) }
			unsafe { *__c2v_lhs_tmp_128 = u8(128 + int(U8((c & u32(63))))) }
		}
	}
	unsafe { *z_out = u8(0) }
	sqlite3_result_text64(context, &i8(voidptr(z)), Sqlite3_uint64(i64((isize(z_out) - isize(z)) / isize(sizeof(u8)))), sqlite3_free, u8(16))
}

@[c:'hexFunc']
fn hex_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	i := 0
	n := 0

	p_blob := &u8(0)
	z_hex := &i8(0)
	z := &i8(0)

	p_blob = &u8(sqlite3_value_blob(argv[0]))
	n = sqlite3_value_bytes(argv[0])
	z_hex = &i8(context_malloc(context, (I64(n)) * I64(2) + I64(1)))
	z = z_hex
	if z_hex {
		for i = 0; i < n; i++ {
			c := (unsafe { *p_blob })
			mut __c2v_lhs_tmp_129 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
			unsafe { *__c2v_lhs_tmp_129 = hexdigits[(int(c) >> 4) & 15] }
			mut __c2v_lhs_tmp_130 := unsafe { c2v_pointer_postfix(voidptr(&z), z, isize(1)) }
			unsafe { *__c2v_lhs_tmp_130 = hexdigits[int(c) & 15] }
			c2v_pointer_postfix(voidptr(&p_blob), p_blob, isize(1))
		}
		unsafe { *z = i8(0) }
		sqlite3_result_text64(context, z_hex, U64((i64((isize(z) - isize(z_hex)) / isize(sizeof(i8))))), sqlite3_free, u8(16))
	}
}

@[c:'strContainsChar']
fn str_contains_char(z_str &U8, n_str int, ch u32) int {
	z_end := unsafe { z_str + n_str }
	mut z := z_str
	for usize(z) < usize(z_end) {
		tst := (if int(z[0]) < 128 {
			u32((unsafe { *(c2v_pointer_postfix(voidptr(&z), z, isize(1))) }))
		} else {
			sqlite3_utf8_read(&&U8(&&U8(c2v_address_of(&z))))
		})
		if tst == ch {
			return 1
		}
	}
	return 0
}

@[c:'unhexFunc']
fn unhex_func(p_ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z_pass := &U8(voidptr(c''))
	n_pass := 0
	mut z_hex := sqlite3_value_text(argv[0])
	n_hex := sqlite3_value_bytes(argv[0])
	p_blob := unsafe { &U8(nil) }
	p := unsafe { &U8(nil) }
	if argc == 2 {
		z_pass = sqlite3_value_text(argv[1])
		n_pass = sqlite3_value_bytes(argv[1])
	}
	if isnil(z_hex) || isnil(z_pass) {
		return
	}
	p_blob = context_malloc(p_ctx, I64((n_hex / 2) + 1))
	p = p_blob
	if p_blob {
		c := U8(0)
		d := U8(0)
		for {
			c = unsafe { *z_hex }
			if !(int(c) != 0) {
				break
			}
			for !(int(sqlite3CtypeMap[u8(c)]) & 8) {
				ch := (if int(z_hex[0]) < 128 {
					u32((unsafe { *(c2v_pointer_postfix(voidptr(&z_hex), z_hex, isize(1))) }))
				} else {
					sqlite3_utf8_read(&&U8(&&U8(c2v_address_of(&z_hex))))
				})
				if !str_contains_char(z_pass, n_pass, ch) {
					unsafe { goto unhex_null
					 }
				}
				c = unsafe { *z_hex }
				if int(c) == 0 {
					unsafe { goto unhex_done
					 }
				}
			}
			c2v_pointer_postfix(voidptr(&z_hex), z_hex, isize(1))
			d = unsafe { *(c2v_pointer_postfix(voidptr(&z_hex), z_hex, isize(1))) }
			if !(int(sqlite3CtypeMap[u8(d)]) & 8) {
				unsafe { goto unhex_null
				 }
			}
			mut __c2v_lhs_tmp_131 := unsafe { c2v_pointer_postfix(voidptr(&p), p, isize(1)) }
			unsafe { *__c2v_lhs_tmp_131 = U8((int(sqlite3_hex_to_int(c)) << 4) | int(sqlite3_hex_to_int(d))) }
		}
	}
	unhex_done:
	sqlite3_result_blob(p_ctx, voidptr(p_blob), int((i64((isize(p) - isize(p_blob)) / isize(sizeof(U8))))), sqlite3_free)
	return
	unhex_null:
	sqlite3_free(voidptr(p_blob))
	return
}

@[c:'zeroblobFunc']
fn zeroblob_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	n := I64(0)
	rc := 0

	n = sqlite3_value_int64(argv[0])
	if n < I64(0) {
		n = I64(0)
	}
	rc = sqlite3_result_zeroblob64(context, Sqlite3_uint64(n))
	if rc {
		sqlite3_result_error_code(context, rc)
	}
}

@[c:'replaceFunc']
fn replace_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z_str := &u8(0)
	z_pattern := &u8(0)
	z_rep := &u8(0)
	z_out := &u8(0)
	n_str := 0
	n_pattern := 0
	n_rep := 0
	n_out := I64(0)
	loop_limit := 0
	i := 0
	j := 0

	cnt_expand := u32(0)
	db := sqlite3_context_db_handle(context)

	z_str = sqlite3_value_text(argv[0])
	if usize(z_str) == usize(0) {
		return
	}
	n_str = sqlite3_value_bytes(argv[0])
	z_pattern = sqlite3_value_text(argv[1])
	if usize(z_pattern) == usize(0) {
		return
	}
	if int(z_pattern[0]) == 0 {
		sqlite3_result_text(context, &i8(voidptr(z_str)), n_str, (C2vFn_666e2028766f696470747229(voidptr(-1))))
		return
	}
	n_pattern = sqlite3_value_bytes(argv[1])
	z_rep = sqlite3_value_text(argv[2])
	if usize(z_rep) == usize(0) {
		return
	}
	n_rep = sqlite3_value_bytes(argv[2])
	n_out = I64(n_str + 1)
	z_out = &u8(context_malloc(context, n_out))
	if usize(z_out) == usize(0) {
		return
	}
	loop_limit = n_str - n_pattern
	cnt_expand = u32(0)
	j = 0
	for i = 0; i <= loop_limit; i++ {
		if int(z_str[i]) != int(z_pattern[0]) || C.memcmp(voidptr(unsafe { z_str + i }), voidptr(z_pattern), u64(n_pattern)) {
			z_out[j++] = z_str[i]
		} else {
			if n_rep > n_pattern {
				n_out += I64(n_rep - n_pattern)
				if n_out - I64(1) > I64(db.aLimit[0]) {
					sqlite3_result_error_toobig(context)
					sqlite3_free(voidptr(z_out))
					return
				}
				cnt_expand++
				if (cnt_expand & (cnt_expand - u32(1))) == u32(0) {
					z_old := &U8(0)
					z_old = z_out
					z_out = &u8(sqlite3_realloc_vdup3(voidptr(z_out), U64(I64(int(n_out)) + (n_out - I64(n_str) - I64(1)))))
					if usize(z_out) == usize(0) {
						sqlite3_result_error_nomem(context)
						sqlite3_free(voidptr(z_old))
						return
					}
				}
			}
			C.memcpy(voidptr(unsafe { z_out + j }), voidptr(z_rep), u64(n_rep))
			j += n_rep
			i += n_pattern - 1
		}
	}
	C.memcpy(voidptr(unsafe { z_out + j }), voidptr(unsafe { z_str + i }), u64(n_str - i))
	j += n_str - i
	z_out[j] = u8(0)
	sqlite3_result_text(context, &i8(voidptr(z_out)), j, sqlite3_free)
}

@[c:'trimFunc']
fn trim_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z_in := &u8(0)
	z_char_set := &u8(0)
	n_in := u32(0)
	flags := 0
	i := 0
	a_len := unsafe { &u32(nil) }
	az_char := unsafe { &&u8(nil) }
	n_char := 0
	if sqlite3_value_type(argv[0]) == 5 {
		return
	}
	z_in = sqlite3_value_text(argv[0])
	if usize(z_in) == usize(0) {
		return
	}
	n_in = u32(sqlite3_value_bytes(argv[0]))
	if argc == 1 {
		if !trim_func_len_one_inited {
			c2v_static_init := [u32(1)]
			for c2v_i_0, c2v_element_0 in c2v_static_init {
				trim_func_len_one[c2v_i_0] = c2v_element_0
			}
			trim_func_len_one_inited = true
		}

		if !trim_func_az_one_inited {
			c2v_static_init := [&U8(voidptr(c' '))]
			for c2v_i_0, c2v_element_0 in c2v_static_init {
				trim_func_az_one[c2v_i_0] = c2v_element_0
			}
			trim_func_az_one_inited = true
		}

		n_char = 1
		a_len = &u32(unsafe { &trim_func_len_one[0] })
		az_char = &&u8(unsafe { &trim_func_az_one[0] })
		z_char_set = 0
	} else {
		z_char_set = sqlite3_value_text(argv[1])
		if usize(z_char_set) == usize(0) {
			return
		} else {
			z := &u8(0)
			z = z_char_set
			for n_char = 0; (unsafe { *z }); n_char++ {
				if int((unsafe { *(c2v_pointer_postfix(voidptr(&z), z, isize(1))) })) >= 192 {
					for (int((unsafe { *z })) & 192) == 128 {
						c2v_pointer_postfix(voidptr(&z), z, isize(1))
					}
				}
			}
			if n_char > 0 {
				az_char = context_malloc(context, I64(u64((I64(n_char))) * (sizeof(voidptr) + sizeof(u32))))
				if usize(az_char) == usize(0) {
					return
				}
				a_len = &u32(voidptr(unsafe { az_char + n_char }))
				z = z_char_set
				for n_char = 0; (unsafe { *z }); n_char++ {
					az_char[n_char] = &u8(z)
					if int((unsafe { *(c2v_pointer_postfix(voidptr(&z), z, isize(1))) })) >= 192 {
						for (int((unsafe { *z })) & 192) == 128 {
							c2v_pointer_postfix(voidptr(&z), z, isize(1))
						}
					}
					a_len[n_char] = u32((i64((isize(z) - isize(az_char[n_char])) / isize(sizeof(u8)))))
				}
			}
		}
	}
	if n_char > 0 {
		flags = (int(i64(sqlite3_user_data(context))))
		if flags & 1 {
			for n_in > u32(0) {
				len := u32(0)
				for i = 0; i < n_char; i++ {
					len = a_len[i]
					if len <= n_in && C.memcmp(voidptr(z_in), voidptr(az_char[i]), u64(len)) == 0 {
						break
					}
				}
				if i >= n_char {
					break
				}
				c2v_pointer_prefix(voidptr(&z_in), z_in, isize(len))
				n_in -= len
			}
		}
		if flags & 2 {
			for n_in > u32(0) {
				len := u32(0)
				for i = 0; i < n_char; i++ {
					len = a_len[i]
					if len <= n_in && C.memcmp(voidptr(unsafe { z_in + (n_in - len) }), voidptr(az_char[i]), u64(len)) == 0 {
						break
					}
				}
				if i >= n_char {
					break
				}
				n_in -= len
			}
		}
		if z_char_set {
			sqlite3_free(voidptr(az_char))
		}
	}
	sqlite3_result_text(context, &i8(voidptr(z_in)), int(n_in), (C2vFn_666e2028766f696470747229(voidptr(-1))))
}

@[c:'concatFuncCore']
fn concat_func_core(context &Sqlite3_context, argc int, argv &&Sqlite3_value, n_sep int, z_sep &i8) {
	j := I64(0)
	n := I64(0)

	i := 0
	b_not_null := 0
	z := &i8(0)
	for i = 0; i < argc; i++ {
		n += I64(sqlite3_value_bytes(argv[i]))
	}
	n += I64((argc - 1)) * I64(n_sep)
	z = &i8(sqlite3_malloc64(Sqlite3_uint64(n + I64(1))))
	if usize(z) == usize(0) {
		sqlite3_result_error_nomem(context)
		return
	}
	j = I64(0)
	for i = 0; i < argc; i++ {
		if sqlite3_value_type(argv[i]) != 5 {
			k := sqlite3_value_bytes(argv[i])
			v := &i8(voidptr(sqlite3_value_text(argv[i])))
			if usize(v) != usize(0) {
				if b_not_null && n_sep > 0 {
					C.memcpy(voidptr(unsafe { z + j }), voidptr(z_sep), u64(n_sep))
					j += I64(n_sep)
				}
				C.memcpy(voidptr(unsafe { z + j }), voidptr(v), u64(k))
				j += I64(k)
				b_not_null = 1
			}
		}
	}
	z[j] = i8(0)
	sqlite3_result_text64(context, z, Sqlite3_uint64(j), sqlite3_free, u8(16))
}

@[c:'concatFunc']
fn concat_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	concat_func_core(context, argc, argv, 0, c'')
}

@[c:'concatwsFunc']
fn concatws_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	n_sep := sqlite3_value_bytes(argv[0])
	z_sep := &i8(voidptr(sqlite3_value_text(argv[0])))
	if usize(z_sep) == usize(0) {
		return
	}
	concat_func_core(context, argc - 1, argv + 1, n_sep, z_sep)
}

@[c:'loadExt']
fn load_ext(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z_file := &i8(voidptr(sqlite3_value_text(argv[0])))
	z_proc := &i8(0)
	db := sqlite3_context_db_handle(context)
	z_err_msg := unsafe { &i8(nil) }
	if (db.flags & U64(131072)) == U64(0) {
		sqlite3_result_error(context, c'not authorized', -1)
		return
	}
	if argc == 2 {
		z_proc = &i8(voidptr(sqlite3_value_text(argv[1])))
	} else {
		z_proc = 0
	}
	if !isnil(z_file) && sqlite3_load_extension(db, z_file, z_proc, &&u8(&&i8(c2v_address_of(&z_err_msg)))) {
		sqlite3_result_error(context, z_err_msg, -1)
		sqlite3_free(voidptr(z_err_msg))
	}
}

struct SumCtx {
	rSum   f64
	rErr   f64
	iSum   I64
	cnt    I64
	approx U8
	ovrfl  U8
}

@[c:'kahanBabuskaNeumaierStep']
fn kahan_babuska_neumaier_step(p_sum &SumCtx, r f64) {
	s := p_sum.rSum
	t := s + r
	if C.fabs(s) > C.fabs(r) {
		p_sum.rErr += (s - t) + r
	} else {
		p_sum.rErr += (r - t) + s
	}
	p_sum.rSum = t
}

@[c:'kahanBabuskaNeumaierStepInt64']
fn kahan_babuska_neumaier_step_int64(p_sum &SumCtx, i_val I64) {
	if i_val <= -4503599627370496 || i_val >= 4503599627370496 {
		i_big := I64(0)
		i_sm := I64(0)

		i_sm = i_val % I64(16384)
		i_big = i_val - i_sm
		kahan_babuska_neumaier_step(p_sum, f64(i_big))
		kahan_babuska_neumaier_step(p_sum, f64(i_sm))
	} else {
		kahan_babuska_neumaier_step(p_sum, f64(i_val))
	}
}

@[c:'kahanBabuskaNeumaierInit']
fn kahan_babuska_neumaier_init(p &SumCtx, i_val I64) {
	if i_val <= -4503599627370496 || i_val >= 4503599627370496 {
		i_sm := i_val % I64(16384)
		p.rSum = f64((i_val - i_sm))
		p.rErr = f64(i_sm)
	} else {
		p.rSum = f64(i_val)
		p.rErr = 0.0
	}
}

@[c:'sumStep']
fn sum_step(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &SumCtx(0)
	type_ := 0

	p = sqlite3_aggregate_context(context, int(sizeof(SumCtx)))
	type_ = sqlite3_value_numeric_type(argv[0])
	if !isnil(p) && type_ != 5 {
		p.cnt++
		if int(p.approx) == 0 {
			if type_ != 1 {
				kahan_babuska_neumaier_init(p, p.iSum)
				p.approx = U8(1)
				kahan_babuska_neumaier_step(p, sqlite3_value_double(argv[0]))
			} else {
				x := p.iSum
				if sqlite3_add_int64(&x, sqlite3_value_int64(argv[0])) == 0 {
					p.iSum = x
				} else {
					p.ovrfl = U8(1)
					kahan_babuska_neumaier_init(p, p.iSum)
					p.approx = U8(1)
					kahan_babuska_neumaier_step_int64(p, sqlite3_value_int64(argv[0]))
				}
			}
		} else {
			if type_ == 1 {
				kahan_babuska_neumaier_step_int64(p, sqlite3_value_int64(argv[0]))
			} else {
				p.ovrfl = U8(0)
				kahan_babuska_neumaier_step(p, sqlite3_value_double(argv[0]))
			}
		}
	}
}

@[c:'sumInverse']
fn sum_inverse(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &SumCtx(0)
	type_ := 0

	p = sqlite3_aggregate_context(context, int(sizeof(SumCtx)))
	type_ = sqlite3_value_numeric_type(argv[0])
	if !isnil(p) && type_ != 5 {
		p.cnt--
		if !p.approx {
			x := p.iSum
			if sqlite3_sub_int64(&x, sqlite3_value_int64(argv[0])) == 0 {
				p.iSum = x
				return
			}
			p.ovrfl = U8(1)
			p.approx = U8(1)
			kahan_babuska_neumaier_init(p, p.iSum)
		}
		if type_ == 1 {
			i_val := sqlite3_value_int64(argv[0])
			if i_val != ((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32))) {
				kahan_babuska_neumaier_step_int64(p, -i_val)
			} else {
				kahan_babuska_neumaier_step_int64(p, (I64(u32(4294967295)) | ((I64(2147483647)) << 32)))
				kahan_babuska_neumaier_step_int64(p, I64(1))
			}
		} else {
			kahan_babuska_neumaier_step(p, -sqlite3_value_double(argv[0]))
		}
	}
}

@[c:'sumFinalize']
fn sum_finalize(context &Sqlite3_context) {
	c2v_gc_register_thread()
	p := &SumCtx(0)
	p = sqlite3_aggregate_context(context, 0)
	if !isnil(p) && p.cnt > I64(0) {
		if p.approx {
			if p.ovrfl {
				sqlite3_result_error(context, c'integer overflow', -1)
			} else if !sqlite3_is_overflow(p.rErr) {
				sqlite3_result_double(context, p.rSum + p.rErr)
			} else {
				sqlite3_result_double(context, p.rSum)
			}
		} else {
			sqlite3_result_int64(context, p.iSum)
		}
	}
}

@[c:'avgFinalize']
fn avg_finalize(context &Sqlite3_context) {
	c2v_gc_register_thread()
	p := &SumCtx(0)
	p = sqlite3_aggregate_context(context, 0)
	if !isnil(p) && p.cnt > I64(0) {
		r := 0.0
		if p.approx {
			r = p.rSum
			if !sqlite3_is_overflow(p.rErr) {
				r += p.rErr
			}
		} else {
			r = f64(p.iSum)
		}
		sqlite3_result_double(context, r / f64(p.cnt))
	}
}

@[c:'totalFinalize']
fn total_finalize(context &Sqlite3_context) {
	c2v_gc_register_thread()
	p := &SumCtx(0)
	r := 0.0
	p = sqlite3_aggregate_context(context, 0)
	if p {
		if p.approx {
			r = p.rSum
			if !sqlite3_is_overflow(p.rErr) {
				r += p.rErr
			}
		} else {
			r = f64(p.iSum)
		}
	}
	sqlite3_result_double(context, r)
}

struct CountCtx {
	n I64
}

@[c:'countStep']
fn count_step(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &CountCtx(0)
	p = sqlite3_aggregate_context(context, int(sizeof(CountCtx)))
	if (argc == 0 || 5 != sqlite3_value_type(argv[0])) && !isnil(p) {
		p.n++
	}
}

@[c:'countFinalize']
fn count_finalize(context &Sqlite3_context) {
	c2v_gc_register_thread()
	p := &CountCtx(0)
	p = sqlite3_aggregate_context(context, 0)
	sqlite3_result_int64(context, if p { p.n } else { I64(0) })
}

@[c:'countInverse']
fn count_inverse(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &CountCtx(0)
	p = sqlite3_aggregate_context(ctx, int(sizeof(CountCtx)))
	if (argc == 0 || 5 != sqlite3_value_type(argv[0])) && !isnil(p) {
		p.n--
	}
}

@[c:'minmaxStep']
fn minmax_step(context &Sqlite3_context, not_used int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	p_arg := &Mem(argv[0])
	p_best := &Mem(0)

	p_best = &Mem(sqlite3_aggregate_context(context, int(sizeof(Mem))))
	if isnil(p_best) {
		return
	}
	if sqlite3_value_type(unsafe { &Sqlite3_value(p_arg) }) == 5 {
		if p_best.flags {
			sqlite3_skip_accumulator_load(context)
		}
	} else if p_best.flags {
		max := 0
		cmp := 0
		p_coll := sqlite3_get_func_coll_seq(context)
		max = usize(sqlite3_user_data(context)) != usize(0)
		cmp = sqlite3_mem_compare(p_best, p_arg, p_coll)
		if (max && cmp < 0) || (!max && cmp > 0) {
			sqlite3_vdbe_mem_copy(p_best, p_arg)
		} else {
			sqlite3_skip_accumulator_load(context)
		}
	} else {
		p_best.db = sqlite3_context_db_handle(context)
		sqlite3_vdbe_mem_copy(p_best, p_arg)
	}
}

@[c:'minMaxValueFinalize']
fn min_max_value_finalize(context &Sqlite3_context, b_value int) {
	p_res := &Sqlite3_value(0)
	p_res = &Sqlite3_value(sqlite3_aggregate_context(context, 0))
	if p_res {
		if p_res.flags {
			sqlite3_result_value(context, p_res)
		}
		if b_value == 0 {
			sqlite3_vdbe_mem_release(unsafe { &Mem(p_res) })
		}
	}
}

@[c:'minMaxValue']
fn min_max_value(context &Sqlite3_context) {
	c2v_gc_register_thread()
	min_max_value_finalize(context, 1)
}

@[c:'minMaxFinalize']
fn min_max_finalize(context &Sqlite3_context) {
	c2v_gc_register_thread()
	min_max_value_finalize(context, 0)
}

struct GroupConcatCtx {
	str             StrAccum
	nAccum          int
	nFirstSepLength int
	pnSepLengths    &int
}

@[c:'groupConcatStep']
fn group_concat_step(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	z_val := &i8(0)
	pgcc := &GroupConcatCtx(0)
	z_sep := &i8(0)
	n_val := 0
	n_sep := 0

	if sqlite3_value_type(argv[0]) == 5 {
		return
	}
	pgcc = &GroupConcatCtx(sqlite3_aggregate_context(context, int(sizeof(GroupConcatCtx))))
	if pgcc {
		db := sqlite3_context_db_handle(context)
		first_term := int(pgcc.str.mxAlloc == u32(0))
		pgcc.str.mxAlloc = u32(db.aLimit[0])
		if argc == 1 {
			if !first_term {
				sqlite3_str_appendchar(unsafe { &Sqlite3_str(&pgcc.str) }, 1, i8(`,`))
			} else {
				pgcc.nFirstSepLength = 1
			}
		} else if !first_term {
			z_sep = &i8(voidptr(sqlite3_value_text(argv[1])))
			n_sep = sqlite3_value_bytes(argv[1])
			if z_sep {
				sqlite3_str_append(unsafe { &Sqlite3_str(&pgcc.str) }, z_sep, n_sep)
			} else {
				n_sep = 0
			}
			if n_sep != pgcc.nFirstSepLength || usize(pgcc.pnSepLengths) != usize(0) {
				pnsl := pgcc.pnSepLengths
				if usize(pnsl) == usize(0) {
					pnsl = &int(sqlite3_malloc64(Sqlite3_uint64(u64((pgcc.nAccum + 1)) * sizeof(int))))
					if usize(pnsl) != usize(0) {
						i := 0
						na := pgcc.nAccum - 1

						for i < na {
							pnsl[i++] = pgcc.nFirstSepLength
						}
					}
				} else {
					pnsl = &int(sqlite3_realloc64(voidptr(pnsl), Sqlite3_uint64(u64(pgcc.nAccum) * sizeof(int))))
				}
				if usize(pnsl) != usize(0) {
					if (pgcc.nAccum > 0) {
						pnsl[pgcc.nAccum - 1] = n_sep
					}
					pgcc.pnSepLengths = pnsl
				} else {
					sqlite3_str_accum_set_error(&pgcc.str, U8(7))
				}
			}
		} else {
			pgcc.nFirstSepLength = sqlite3_value_bytes(argv[1])
		}
		pgcc.nAccum += 1
		z_val = &i8(voidptr(sqlite3_value_text(argv[0])))
		n_val = sqlite3_value_bytes(argv[0])
		if z_val {
			sqlite3_str_append(unsafe { &Sqlite3_str(&pgcc.str) }, z_val, n_val)
		}
	}
}

@[c:'groupConcatInverse']
fn group_concat_inverse(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	pgcc := &GroupConcatCtx(0)

	if sqlite3_value_type(argv[0]) == 5 {
		return
	}
	pgcc = &GroupConcatCtx(sqlite3_aggregate_context(context, int(sizeof(GroupConcatCtx))))
	if pgcc {
		nvs := 0
		sqlite3_value_text(argv[0])
		nvs = sqlite3_value_bytes(argv[0])
		pgcc.nAccum -= 1
		if usize(pgcc.pnSepLengths) != usize(0) {
			if pgcc.nAccum > 0 {
				nvs += (unsafe { *pgcc.pnSepLengths })
				C.memmove(voidptr(pgcc.pnSepLengths), voidptr(pgcc.pnSepLengths + 1), u64((pgcc.nAccum - 1)) * sizeof(int))
			}
		} else {
			nvs += pgcc.nFirstSepLength
		}
		if nvs >= int(pgcc.str.nChar) {
			pgcc.str.nChar = u32(0)
		} else {
			pgcc.str.nChar -= u32(nvs)
			C.memmove(voidptr(pgcc.str.zText), voidptr(unsafe { pgcc.str.zText + nvs }), u64(pgcc.str.nChar))
		}
		if pgcc.str.nChar == u32(0) {
			pgcc.str.mxAlloc = u32(0)
			sqlite3_free(voidptr(pgcc.pnSepLengths))
			pgcc.pnSepLengths = 0
		}
	}
}

@[c:'groupConcatFinalize']
fn group_concat_finalize(context &Sqlite3_context) {
	c2v_gc_register_thread()
	pgcc := &GroupConcatCtx(sqlite3_aggregate_context(context, 0))
	if pgcc {
		sqlite3_result_str_accum(context, &pgcc.str)
		sqlite3_free(voidptr(pgcc.pnSepLengths))
	}
}

@[c:'groupConcatValue']
fn group_concat_value(context &Sqlite3_context) {
	c2v_gc_register_thread()
	pgcc := &GroupConcatCtx(sqlite3_aggregate_context(context, 0))
	if pgcc {
		p_accum := &pgcc.str
		if int(p_accum.accError) == 18 {
			sqlite3_result_error_toobig(context)
		} else if int(p_accum.accError) == 7 {
			sqlite3_result_error_nomem(context)
		} else if pgcc.nAccum > 0 && p_accum.nChar == u32(0) {
			sqlite3_result_text(context, c'', 1, (C2vFn_666e2028766f696470747229(voidptr(0))))
		} else {
			z_text := sqlite3_str_value(unsafe { &Sqlite3_str(p_accum) })
			sqlite3_result_text(context, z_text, int(p_accum.nChar), (C2vFn_666e2028766f696470747229(voidptr(-1))))
		}
	}
}

@[c:'sqlite3RegisterPerConnectionBuiltinFunctions']
fn sqlite3_register_per_connection_builtin_functions(db &Sqlite3) {
	rc := sqlite3_overload_function(db, c'MATCH', 2)
	if rc == 7 {
		sqlite3_oom_fault(db)
	}
}

@[c:'sqlite3RegisterLikeFunctions']
fn sqlite3_register_like_functions(db &Sqlite3, case_sensitive int) {
	p_def := &FuncDef(0)
	p_info := &CompareInfo(0)
	flags := 0
	n_arg := 0
	if case_sensitive {
		p_info = &CompareInfo(&likeInfoAlt)
		flags = 4 | 8
	} else {
		p_info = &CompareInfo(&likeInfoNorm)
		flags = 4
	}
	for n_arg = 2; n_arg <= 3; n_arg++ {
		sqlite3_create_func(db, c'like', n_arg, 1, voidptr(p_info), like_func, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil })
		p_def = sqlite3_find_function(db, c'like', n_arg, U8(1), U8(0))
		p_def.funcFlags |= u32(flags)
		p_def.funcFlags &= u32(~2097152)
	}
}

@[c:'sqlite3IsLikeFunction']
fn sqlite3_is_like_function(db &Sqlite3, p_expr &Expr, p_is_nocase &int, a_wc &i8) int {
	p_def := &FuncDef(0)
	n_expr := 0
	if isnil(p_expr.x.pList) {
		return 0
	}
	n_expr = p_expr.x.pList.nExpr
	p_def = sqlite3_find_function(db, p_expr.u.zToken, n_expr, U8(1), U8(0))
	if (usize(p_def) == usize(0)) || (p_def.funcFlags & u32(4)) == u32(0) {
		return 0
	}
	C.memcpy(voidptr(a_wc), voidptr(p_def.pUserData), u64(3))
	if n_expr < 3 {
		a_wc[3] = i8(0)
	} else {
		p_escape := c2v_at(&p_expr.x.pList.a[0], isize(2)).pExpr
		z_escape := &i8(0)
		if int(p_escape.op) != 118 {
			return 0
		}
		z_escape = p_escape.u.zToken
		if int(z_escape[0]) == 0 || int(z_escape[1]) != 0 {
			return 0
		}
		if int(z_escape[0]) == int(a_wc[0]) {
			return 0
		}
		if int(z_escape[0]) == int(a_wc[1]) {
			return 0
		}
		a_wc[3] = z_escape[0]
	}
	unsafe { *p_is_nocase = (p_def.funcFlags & u32(8)) == u32(0) }
	return 1
}

@[c:'signFunc']
fn sign_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	type0 := 0
	x := 0.0

	type0 = sqlite3_value_numeric_type(argv[0])
	if type0 != 1 && type0 != 2 {
		return
	}
	x = sqlite3_value_double(argv[0])
	sqlite3_result_int(context, if x < 0.0 {
		-1
	} else {
		if x > 0.0 { 1 } else { 0 }
	})
}

@[c:'sqlite3RegisterBuiltinFunctions']
fn sqlite3_register_builtin_functions() {
	if !sqlite3_register_builtin_functions_a_builtin_func_inited {
		c2v_static_init := [FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 1 | 262144 | 16384 | 4194304 | 2048 | 0)
			pUserData: (voidptr(i64(1)))
			pNext: 0
			xSFunc: version_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'implies_nonnull_row'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 1 | 262144 | 16384 | 4194304 | 2048 | 0)
			pUserData: (voidptr(i64(3)))
			pNext: 0
			xSFunc: version_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'expr_compare'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 1 | 262144 | 16384 | 4194304 | 2048 | 0)
			pUserData: (voidptr(i64(2)))
			pNext: 0
			xSFunc: version_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'expr_implies_expr'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 1 | 262144 | 16384 | 4194304 | 2048 | 0)
			pUserData: (voidptr(i64(4)))
			pNext: 0
			xSFunc: version_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'affinity'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 1 | 524288 | 2097152)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: load_ext
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'load_extension'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 1 | 524288 | 2097152)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: load_ext
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'load_extension'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 8192 | 1)
			pUserData: 0
			pNext: 0
			xSFunc: compileoptionused_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sqlite_compileoption_used'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 8192 | 1)
			pUserData: 0
			pNext: 0
			xSFunc: compileoptionget_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sqlite_compileoption_get'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 1 | 4194304 | 2048 | 1024)
			pUserData: (voidptr(i64(99)))
			pNext: 0
			xSFunc: version_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'unlikely'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 1 | 4194304 | 2048 | 1024)
			pUserData: (voidptr(i64(99)))
			pNext: 0
			xSFunc: version_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'likelihood'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 1 | 4194304 | 2048 | 1024)
			pUserData: (voidptr(i64(99)))
			pNext: 0
			xSFunc: version_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'likely'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(1)))
			pNext: 0
			xSFunc: trim_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'ltrim'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(1)))
			pNext: 0
			xSFunc: trim_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'ltrim'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(2)))
			pNext: 0
			xSFunc: trim_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'rtrim'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(2)))
			pNext: 0
			xSFunc: trim_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'rtrim'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(3)))
			pNext: 0
			xSFunc: trim_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'trim'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(3)))
			pNext: 0
			xSFunc: trim_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'trim'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-3)
			funcFlags: u32(8388608 | 2048 | 1 | (1 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: minmax_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'min'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 1 | (1 * 32) | 4096 | 134217728)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: minmax_step
			xFinalize: min_max_finalize
			xValue: min_max_value
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'min'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-3)
			funcFlags: u32(8388608 | 2048 | 1 | (1 * 32))
			pUserData: (voidptr(i64(1)))
			pNext: 0
			xSFunc: minmax_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'max'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 1 | (1 * 32) | 4096 | 134217728)
			pUserData: (voidptr(i64(1)))
			pNext: 0
			xSFunc: minmax_step
			xFinalize: min_max_finalize
			xValue: min_max_value
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'max'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32) | 128)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: typeof_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'typeof'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32) | 128 | 1048576)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: subtype_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'subtype'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32) | 64)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: length_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'length'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32) | 192)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: bytelength_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'octet_length'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: instr_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'instr'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: printf_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'printf'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: printf_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'format'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: unicode_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'unicode'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: char_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'char'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: abs_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'abs'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: round_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'round'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: round_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'round'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: upper_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'upper'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: lower_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'lower'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: hex_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'hex'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: unhex_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'unhex'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: unhex_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'unhex'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-3)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: concat_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'concat'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-4)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: concatws_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'concat_ws'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 1 | 4194304 | 2048 | 0)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: version_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'ifnull'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(0)
			funcFlags: u32(8388608 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: random_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'random'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: random_blob
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'randomblob'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 1 | (1 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: nullif_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'nullif'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(0)
			funcFlags: u32(8388608 | 8192 | 1)
			pUserData: 0
			pNext: 0
			xSFunc: version_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sqlite_version'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(0)
			funcFlags: u32(8388608 | 8192 | 1)
			pUserData: 0
			pNext: 0
			xSFunc: sourceid_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sqlite_source_id'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: errlog_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sqlite_log'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: unistr_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'unistr'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: quote_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'quote'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(1)))
			pNext: 0
			xSFunc: quote_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'unistr_quote'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(0)
			funcFlags: u32(8388608 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: last_insert_rowid
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'last_insert_rowid'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(0)
			funcFlags: u32(8388608 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: changes
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'changes'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(0)
			funcFlags: u32(8388608 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: total_changes
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'total_changes'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(3)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: replace_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'replace'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: zeroblob_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'zeroblob'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: substr_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'substr'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(3)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: substr_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'substr'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: substr_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'substring'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(3)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: substr_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'substring'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 1 | (0 * 32) | 0)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: sum_step
			xFinalize: sum_finalize
			xValue: sum_finalize
			xInverse: sum_inverse
			zName: c'sum'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 1 | (0 * 32) | 0)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: sum_step
			xFinalize: total_finalize
			xValue: total_finalize
			xInverse: sum_inverse
			zName: c'total'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 1 | (0 * 32) | 0)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: sum_step
			xFinalize: avg_finalize
			xValue: avg_finalize
			xInverse: sum_inverse
			zName: c'avg'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(0)
			funcFlags: u32(8388608 | 1 | (0 * 32) | 256 | 134217728)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: count_step
			xFinalize: count_finalize
			xValue: count_finalize
			xInverse: count_inverse
			zName: c'count'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 1 | (0 * 32) | 134217728)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: count_step
			xFinalize: count_finalize
			xValue: count_finalize
			xInverse: count_inverse
			zName: c'count'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 1 | (0 * 32) | 0)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: group_concat_step
			xFinalize: group_concat_finalize
			xValue: group_concat_value
			xInverse: group_concat_inverse
			zName: c'group_concat'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 1 | (0 * 32) | 0)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: group_concat_step
			xFinalize: group_concat_finalize
			xValue: group_concat_value
			xInverse: group_concat_inverse
			zName: c'group_concat'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 1 | (0 * 32) | 0)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: group_concat_step
			xFinalize: group_concat_finalize
			xValue: group_concat_value
			xInverse: group_concat_inverse
			zName: c'string_agg'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 1 | 4 | 8)
			pUserData: voidptr(&globInfo)
			pNext: 0
			xSFunc: like_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'glob'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 1 | 4)
			pUserData: voidptr(&likeInfoNorm)
			pNext: 0
			xSFunc: like_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'like'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(3)
			funcFlags: u32(8388608 | 2048 | 1 | 4)
			pUserData: voidptr(&likeInfoNorm)
			pNext: 0
			xSFunc: like_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'like'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 1 | (0 * 32))
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: sign_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'sign'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-4)
			funcFlags: u32(8388608 | 1 | 4194304 | 2048 | 0)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: version_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'coalesce'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-4)
			funcFlags: u32(8388608 | 1 | 4194304 | 2048 | 0)
			pUserData: (voidptr(i64(5)))
			pNext: 0
			xSFunc: version_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'iif'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-4)
			funcFlags: u32(8388608 | 1 | 4194304 | 2048 | 0)
			pUserData: (voidptr(i64(5)))
			pNext: 0
			xSFunc: version_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'if'
			u: FuncDef_u{}
		}]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_register_builtin_functions_a_builtin_func[c2v_i_0] = c2v_element_0
		}
		sqlite3_register_builtin_functions_a_builtin_func_inited = true
	}

	sqlite3_alter_functions()
	sqlite3_window_functions()
	sqlite3_register_date_time_functions()
	sqlite3_register_json_functions()
	sqlite3_insert_builtin_funcs(&sqlite3_register_builtin_functions_a_builtin_func[0], 74)
}
