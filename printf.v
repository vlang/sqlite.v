@[translated]
module main

type EtByte = u8

struct Et_info {
	fmttype i8
	base    EtByte
	flags   EtByte
	type_   EtByte
	charset EtByte
	prefix  EtByte
	iNxt    i8
}

@[c:'sqlite3StrAccumSetError']
fn sqlite3_str_accum_set_error(p &StrAccum, e_error U8) {
	p.accError = e_error
	if p.mxAlloc {
		sqlite3_str_reset(unsafe { &Sqlite3_str(p) })
	}
	if int(e_error) == 18 {
		sqlite3_error_to_parser(p.db, int(e_error))
	}
}

@[c:'getIntArg']
fn get_int_arg(p &PrintfArguments) Sqlite3_int64 {
	if p.nArg <= p.nUsed {
		return Sqlite3_int64(0)
	}
	return sqlite3_value_int64(p.apArg[p.nUsed++])
}

@[c:'getDoubleArg']
fn get_double_arg(p &PrintfArguments) f64 {
	if p.nArg <= p.nUsed {
		return 0.0
	}
	return sqlite3_value_double(p.apArg[p.nUsed++])
}

@[c:'getTextArg']
fn get_text_arg(p &PrintfArguments) &i8 {
	if p.nArg <= p.nUsed {
		return unsafe { nil }
	}
	return &i8(voidptr(sqlite3_value_text(p.apArg[p.nUsed++])))
}

@[c:'printfTempBuf']
fn printf_temp_buf(p_accum &Sqlite3_str, n Sqlite3_int64) &i8 {
	z := &i8(0)
	if p_accum.accError {
		return unsafe { nil }
	}
	if n > Sqlite3_int64(p_accum.nAlloc) && n > Sqlite3_int64(p_accum.mxAlloc) {
		sqlite3_str_accum_set_error(unsafe { &StrAccum(p_accum) }, U8(18))
		return unsafe { nil }
	}
	z = &i8(sqlite3_malloc(int(n)))
	if usize(z) == usize(0) {
		sqlite3_str_accum_set_error(unsafe { &StrAccum(p_accum) }, U8(7))
	}
	return z
}

fn sqlite3_str_vappendf(p_accum &Sqlite3_str, fmt &i8, ap C.va_list) {
	c2v_gc_register_thread()
	c := 0
	bufpt := &i8(0)
	precision := 0
	length := 0
	idx := 0
	width := 0
	flag_leftjustify := EtByte(0)
	flag_prefix := EtByte(0)
	flag_alternateform := EtByte(0)
	flag_altform2 := EtByte(0)
	flag_zeropad := EtByte(0)
	flag_long := EtByte(0)
	done := EtByte(0)
	c_thousand := EtByte(0)
	xtype := EtByte(17)
	b_arg_list := U8(0)
	prefix := i8(0)
	longvalue := Sqlite_uint64(0)
	realvalue := 0.0
	infop := &Et_info(0)
	z_out := &i8(0)
	n_out := 0
	z_extra := unsafe { &i8(nil) }
	exp := 0
	e2 := 0

	flag_dp := EtByte(0)
	flag_rtz := EtByte(0)
	p_arg_list := unsafe { &PrintfArguments(nil) }
	buf := [70]i8{}
	bufpt = 0
	if (int(p_accum.printfFlags) & 2) != 0 {
		p_arg_list = C.va_arg(&PrintfArguments, ap)
		b_arg_list = U8(1)
	} else {
		b_arg_list = U8(0)
	}
	for ; true; fmt = unsafe { fmt + 1 } {
		c = unsafe { *fmt }
		if !(c != 0) {
			break
		}
		if c != `%` {
			bufpt = &i8(fmt)
			fmt = C.strchr(fmt, `%`)
			if usize(fmt) == usize(0) {
				fmt = bufpt + C.strlen(bufpt)
			}
			sqlite3_str_append(p_accum, bufpt, int((i64((isize(fmt) - isize(bufpt)) / isize(sizeof(i8))))))
			if int((unsafe { *fmt })) == 0 {
				break
			}
		}
		c = unsafe { *c2v_pointer_prefix(voidptr(&fmt), fmt, isize(1)) }
		if c == 0 {
			sqlite3_str_append(p_accum, c'%', 1)
			break
		}
		flag_zeropad = EtByte(0)
		flag_altform2 = flag_zeropad
		flag_alternateform = flag_altform2
		c_thousand = flag_alternateform
		flag_prefix = c_thousand
		flag_leftjustify = flag_prefix
		done = EtByte(0)
		width = 0
		flag_long = EtByte(0)
		precision = -1
		for {
			match int(c) {
				int(`-`) {
					flag_leftjustify = EtByte(1)
				}
				int(`+`) {
					flag_prefix = EtByte(`+`)
				}
				int(` `) {
					flag_prefix = EtByte(` `)
				}
				int(`#`) {
					flag_alternateform = EtByte(1)
				}
				int(`!`) {
					flag_altform2 = EtByte(1)
				}
				int(`0`) {
					flag_zeropad = EtByte(1)
				}
				int(`,`) {
					c_thousand = EtByte(`,`)
				}
				int(`l`) {
					flag_long = EtByte(1)
					c = unsafe { *c2v_pointer_prefix(voidptr(&fmt), fmt, isize(1)) }
					if c == `l` {
						c = unsafe { *c2v_pointer_prefix(voidptr(&fmt), fmt, isize(1)) }
						flag_long = EtByte(2)
					}
					done = EtByte(1)
				}
				int(`1`), int(`2`), int(`3`), int(`4`), int(`5`), int(`6`), int(`7`), int(`8`), int(`9`) {
					wx := u32(c - int(`0`))
					for {
						c = unsafe { *c2v_pointer_prefix(voidptr(&fmt), fmt, isize(1)) }
						if !(c >= `0` && c <= `9`) {
							break
						}
						wx = wx * u32(10) + u32(c) - u32(`0`)
					}
					width = int(wx & u32(2147483647))
					if c != `.` && c != `l` {
						done = EtByte(1)
					} else {
						c2v_pointer_postfix(voidptr(&fmt), fmt, isize(-1))
					}
				}
				int(`*`) {
					if b_arg_list {
						width = int(get_int_arg(p_arg_list))
					} else {
						width = C.va_arg(int, ap)
					}
					if width < 0 {
						flag_leftjustify = EtByte(1)
						width = if width >= -2147483647 { -width } else { 0 }
					}
					c = int(fmt[1])
					if c != `.` && c != `l` {
						c = unsafe { *c2v_pointer_prefix(voidptr(&fmt), fmt, isize(1)) }
						done = EtByte(1)
					}
				}
				int(`.`) {
					c = unsafe { *c2v_pointer_prefix(voidptr(&fmt), fmt, isize(1)) }
					if c == `*` {
						if b_arg_list {
							precision = int(get_int_arg(p_arg_list))
						} else {
							precision = C.va_arg(int, ap)
						}
						if precision < 0 {
							precision = if precision >= -2147483647 { -precision } else { -1 }
						}
						c = unsafe { *c2v_pointer_prefix(voidptr(&fmt), fmt, isize(1)) }
					} else {
						px := u32(0)
						for c >= `0` && c <= `9` {
							px = px * u32(10) + u32(c) - u32(`0`)
							c = unsafe { *c2v_pointer_prefix(voidptr(&fmt), fmt, isize(1)) }
						}
						precision = int(px & u32(2147483647))
					}
					if c == `l` {
						c2v_pointer_prefix(voidptr(&fmt), fmt, isize(-1))
					} else {
						done = EtByte(1)
					}
				}
				else {
					done = EtByte(1)
				}
			}
			if !(!done && c2v_assign[int](unsafe { &c }, int((unsafe { *c2v_pointer_prefix(voidptr(&fmt), fmt, isize(1)) }))) != 0) {
				break
			}
		}
		idx = int((u32(c)) % u32(23))
		if int(fmtinfo[idx].fmttype) == c || int(fmtinfo[c2v_assign[int](unsafe { &idx }, int(fmtinfo[idx].iNxt))].fmttype) == c {
			infop = unsafe { &fmtinfo[0] + idx }
			xtype = infop.type_
		} else {
			infop = unsafe { &fmtinfo[0] + 0 }
			xtype = EtByte(17)
		}
		match xtype {
			13 {
				flag_long = EtByte(if sizeof(voidptr) == sizeof(I64) {
					2
				} else {
					if sizeof(voidptr) == sizeof(i64) { 1 } else { 0 }
				})

				unsafe { goto c2v_case_6_2
				 }
			}
			15, 0 {
				c2v_case_6_2:
				c_thousand = EtByte(0)

				unsafe { goto c2v_case_6_4
				 }
			}
			16 {
				c2v_case_6_4:
				if int(infop.flags) & 1 {
					v := I64(0)
					if b_arg_list {
						v = get_int_arg(p_arg_list)
					} else if flag_long {
						if int(flag_long) == 2 {
							v = C.va_arg(I64, ap)
						} else {
							v = I64(C.va_arg(i64, ap))
						}
					} else {
						v = I64(C.va_arg(int, ap))
					}
					if v < I64(0) {
						longvalue = Sqlite_uint64(~v)
						longvalue++
						prefix = i8(`-`)
					} else {
						longvalue = Sqlite_uint64(v)
						prefix = i8(flag_prefix)
					}
				} else {
					if b_arg_list {
						longvalue = U64(get_int_arg(p_arg_list))
					} else if flag_long {
						if int(flag_long) == 2 {
							longvalue = C.va_arg(U64, ap)
						} else {
							longvalue = Sqlite_uint64(C.va_arg(u64, ap))
						}
					} else {
						longvalue = Sqlite_uint64(C.va_arg(u32, ap))
					}
					prefix = i8(0)
				}
				if longvalue == Sqlite_uint64(0) {
					flag_alternateform = EtByte(0)
				}
				if int(flag_zeropad) && precision < width - int((int(prefix) != 0)) {
					precision = width - int((int(prefix) != 0))
				}
				if precision < 70 - 10 - 70 / 3 {
					n_out = 70
					z_out = unsafe { &buf[0] }
				} else {
					n := U64(0)
					n = U64(precision) + U64(10)
					if c_thousand {
						n += U64(precision / 3)
					}
					z_extra = printf_temp_buf(p_accum, Sqlite3_int64(n))
					z_out = z_extra
					if usize(z_out) == usize(0) {
						return
					}
					n_out = int(n)
				}
				bufpt = unsafe { z_out + (n_out - 1) }
				if int(xtype) == 15 {
					if !sqlite3_str_vappendf_z_ord_inited {
						c2v_static_init := [i8(116), 104, 115, 116, 110, 100, 114, 100, 0]
						for c2v_i_0, c2v_element_0 in c2v_static_init {
							sqlite3_str_vappendf_z_ord[c2v_i_0] = c2v_element_0
						}
						sqlite3_str_vappendf_z_ord_inited = true
					}

					x := int((longvalue % Sqlite_uint64(10)))
					if x >= 4 || (longvalue / Sqlite_uint64(10)) % Sqlite_uint64(10) == Sqlite_uint64(1) {
						x = 0
					}
					mut __c2v_lhs_tmp_3 := unsafe { c2v_pointer_prefix(voidptr(&bufpt), bufpt, isize(-1)) }
					unsafe { *__c2v_lhs_tmp_3 = sqlite3_str_vappendf_z_ord[x * 2 + 1] }
					mut __c2v_lhs_tmp_4 := unsafe { c2v_pointer_prefix(voidptr(&bufpt), bufpt, isize(-1)) }
					unsafe { *__c2v_lhs_tmp_4 = sqlite3_str_vappendf_z_ord[x * 2] }
				}
				cset := unsafe { &aDigits[0] + infop.charset }
				base := infop.base
				for {
					mut __c2v_lhs_tmp_5 := unsafe { c2v_pointer_prefix(voidptr(&bufpt), bufpt, isize(-1)) }
					unsafe { *__c2v_lhs_tmp_5 = cset[longvalue % Sqlite_uint64(base)] }
					longvalue = longvalue / Sqlite_uint64(base)
					if !(longvalue > Sqlite_uint64(0)) {
						break
					}
				}
				length = int((i64((isize(unsafe { z_out + (n_out - 1) }) - isize(bufpt)) / isize(sizeof(i8)))))
				if precision > length {
					nn := precision - length
					c2v_pointer_prefix(voidptr(&bufpt), bufpt, isize(-nn))
					C.memset(voidptr(bufpt), `0`, u64(nn))
					length = precision
				}
				if c_thousand {
					nn := (length - 1) / 3
					ix := (length - 1) % 3 + 1
					c2v_pointer_prefix(voidptr(&bufpt), bufpt, isize(-nn))
					for idx = 0; nn > 0; idx++ {
						bufpt[idx] = bufpt[idx + nn]
						ix--
						if ix == 0 {
							bufpt[c2v_prefix_add(unsafe { &idx }, 1)] = i8(c_thousand)
							nn--
							ix = 3
						}
					}
				}
				if prefix {
					mut __c2v_lhs_tmp_6 := unsafe { c2v_pointer_prefix(voidptr(&bufpt), bufpt, isize(-1)) }
					unsafe { *__c2v_lhs_tmp_6 = prefix }
				}
				if int(flag_alternateform) && int(infop.prefix) {
					pre := &i8(0)
					x := i8(0)
					pre = unsafe { &aPrefix[0] + infop.prefix }
					for ; true; pre = unsafe { pre + 1 } {
						x = unsafe { *pre }
						if !(int(x) != 0) {
							break
						}
						mut __c2v_lhs_tmp_7 := unsafe { c2v_pointer_prefix(voidptr(&bufpt), bufpt, isize(-1)) }
						unsafe { *__c2v_lhs_tmp_7 = x }
					}
				}
				length = int((i64((isize(unsafe { z_out + (n_out - 1) }) - isize(bufpt)) / isize(sizeof(i8)))))
			}
			1, 2, 3 {
				s := FpDecode{}
				i_round := 0
				mut j := 0
				sz_buf_needed := I64(0)
				if b_arg_list {
					realvalue = get_double_arg(p_arg_list)
				} else {
					realvalue = C.va_arg(f64, ap)
				}
				if precision < 0 {
					precision = 6
				}
				if precision > 100000000 {
					precision = 100000000
				}
				if int(xtype) == 1 {
					i_round = -precision
				} else if int(xtype) == 3 {
					if precision == 0 {
						precision = 1
					}
					i_round = precision
				} else {
					i_round = precision + 1
				}
				sqlite3_fp_decode(&s, realvalue, i_round, if int(flag_altform2) { 20 } else { 16 })
				if s.isSpecial {
					if int(s.isSpecial) == 2 {
						bufpt = if int(flag_zeropad) { c'null' } else { c'NaN' }
						length = sqlite3_strlen30(bufpt)
						unsafe { goto c2v_switch_end_6
						 }
					} else if flag_zeropad {
						s.z[0] = i8(`9`)
						s.iDP = 1000
						s.n = 1
					} else {
						C.memcpy(voidptr(unsafe { &buf[0] }), voidptr(c'-Inf'), u64(5))
						bufpt = unsafe { &buf[0] }
						if int(s.sign) == i8(`-`) {
						} else if flag_prefix {
							buf[0] = i8(flag_prefix)
						} else {
							c2v_pointer_postfix(voidptr(&bufpt), bufpt, isize(1))
						}
						length = sqlite3_strlen30(bufpt)
						unsafe { goto c2v_switch_end_6
						 }
					}
				}
				if int(s.sign) == i8(`-`) {
					if int(flag_alternateform) && !flag_prefix && int(xtype) == 1 && s.iDP <= i_round {
						prefix = i8(0)
					} else {
						prefix = i8(`-`)
					}
				} else {
					prefix = i8(flag_prefix)
				}
				exp = s.iDP - 1
				if int(xtype) == 3 {
					precision--
					flag_rtz = EtByte(!flag_alternateform)
					if exp < -4 || exp > precision {
						xtype = EtByte(2)
					} else {
						precision = precision - exp
						xtype = EtByte(1)
					}
				} else {
					flag_rtz = flag_altform2
				}
				if int(xtype) == 2 {
					e2 = 0
				} else {
					e2 = s.iDP - 1
				}
				sz_buf_needed = I64((if e2 > 0 { e2 } else { 0 })) + I64(precision) + I64(width) + I64(10)
				if int(c_thousand) && e2 > 0 {
					sz_buf_needed += I64((e2 + 2) / 3)
				}
				if sz_buf_needed + I64(p_accum.nChar) >= I64(p_accum.nAlloc) {
					if p_accum.mxAlloc == u32(0) && int(p_accum.accError) == 0 {
						bufpt = &i8(sqlite3_malloc(int(sz_buf_needed)))
						if usize(bufpt) == usize(0) {
							sqlite3_str_accum_set_error(unsafe { &StrAccum(p_accum) }, U8(7))
							return
						}
						z_extra = bufpt
					} else if I64(sqlite3_str_accum_enlarge(unsafe { &StrAccum(p_accum) }, sz_buf_needed)) < sz_buf_needed {
						length = 0
						width = length
						unsafe { goto c2v_switch_end_6
						 }
					} else {
						bufpt = p_accum.zText + p_accum.nChar
					}
				} else {
					bufpt = p_accum.zText + p_accum.nChar
				}
				z_out = bufpt
				flag_dp = EtByte((if precision > 0 { 1 } else { 0 }) | int(flag_alternateform) | int(flag_altform2))
				if prefix {
					mut __c2v_lhs_tmp_8 := unsafe { c2v_pointer_postfix(voidptr(&bufpt), bufpt, isize(1)) }
					unsafe { *__c2v_lhs_tmp_8 = prefix }
				}
				j = 0
				if e2 < 0 {
					mut __c2v_lhs_tmp_9 := unsafe { c2v_pointer_postfix(voidptr(&bufpt), bufpt, isize(1)) }
					unsafe { *__c2v_lhs_tmp_9 = i8(`0`) }
				} else if c_thousand {
					for ; e2 >= 0; e2-- {
						mut __c2v_lhs_tmp_10 := unsafe { c2v_pointer_postfix(voidptr(&bufpt), bufpt, isize(1)) }
						unsafe { *__c2v_lhs_tmp_10 = i8(if j < s.n { int(s.z[j++]) } else { `0` }) }
						if (e2 % 3) == 0 && e2 > 1 {
							mut __c2v_lhs_tmp_11 := unsafe { c2v_pointer_postfix(voidptr(&bufpt), bufpt, isize(1)) }
							unsafe { *__c2v_lhs_tmp_11 = i8(`,`) }
						}
					}
				} else {
					j = e2 + 1
					if j > s.n {
						j = s.n
					}
					C.memcpy(voidptr(bufpt), voidptr(s.z), u64(j))
					c2v_pointer_prefix(voidptr(&bufpt), bufpt, isize(j))
					e2 -= j
					if e2 >= 0 {
						C.memset(voidptr(bufpt), `0`, u64(e2 + 1))
						c2v_pointer_prefix(voidptr(&bufpt), bufpt, isize(e2 + 1))
						e2 = -1
					}
				}
				if flag_dp {
					mut __c2v_lhs_tmp_12 := unsafe { c2v_pointer_postfix(voidptr(&bufpt), bufpt, isize(1)) }
					unsafe { *__c2v_lhs_tmp_12 = i8(`.`) }
				}
				if e2 < (-1) && precision > 0 {
					nn := -1 - e2
					if nn > precision {
						nn = precision
					}
					C.memset(voidptr(bufpt), `0`, u64(nn))
					c2v_pointer_prefix(voidptr(&bufpt), bufpt, isize(nn))
					precision -= nn
				}
				if precision > 0 {
					nn := s.n - j
					if (nn > precision) {
						nn = precision
					}
					if nn > 0 {
						C.memcpy(voidptr(bufpt), voidptr(s.z + j), u64(nn))
						c2v_pointer_prefix(voidptr(&bufpt), bufpt, isize(nn))
						precision -= nn
					}
					if precision > 0 && !flag_rtz {
						C.memset(voidptr(bufpt), `0`, u64(precision))
						c2v_pointer_prefix(voidptr(&bufpt), bufpt, isize(precision))
					}
				}
				if int(flag_rtz) && int(flag_dp) {
					for int(bufpt[-1]) == i8(`0`) {
						mut __c2v_lhs_tmp_13 := unsafe { c2v_pointer_prefix(voidptr(&bufpt), bufpt, isize(-1)) }
						unsafe { *__c2v_lhs_tmp_13 = i8(0) }
					}
					if int(bufpt[-1]) == i8(`.`) {
						if flag_altform2 {
							mut __c2v_lhs_tmp_14 := unsafe { c2v_pointer_postfix(voidptr(&bufpt), bufpt, isize(1)) }
							unsafe { *__c2v_lhs_tmp_14 = i8(`0`) }
						} else {
							mut __c2v_lhs_tmp_15 := unsafe { c2v_pointer_prefix(voidptr(&bufpt), bufpt, isize(-1)) }
							unsafe { *__c2v_lhs_tmp_15 = i8(0) }
						}
					}
				}
				if int(xtype) == 2 {
					exp = s.iDP - 1
					mut __c2v_lhs_tmp_16 := unsafe { c2v_pointer_postfix(voidptr(&bufpt), bufpt, isize(1)) }
					unsafe { *__c2v_lhs_tmp_16 = aDigits[infop.charset] }
					if exp < 0 {
						mut __c2v_lhs_tmp_17 := unsafe { c2v_pointer_postfix(voidptr(&bufpt), bufpt, isize(1)) }
						unsafe { *__c2v_lhs_tmp_17 = i8(`-`) }
						exp = -exp
					} else {
						mut __c2v_lhs_tmp_18 := unsafe { c2v_pointer_postfix(voidptr(&bufpt), bufpt, isize(1)) }
						unsafe { *__c2v_lhs_tmp_18 = i8(`+`) }
					}
					if exp >= 100 {
						mut __c2v_lhs_tmp_19 := unsafe { c2v_pointer_postfix(voidptr(&bufpt), bufpt, isize(1)) }
						unsafe { *__c2v_lhs_tmp_19 = i8(((exp / 100) + int(`0`))) }
						exp %= 100
					}
					mut __c2v_lhs_tmp_20 := unsafe { c2v_pointer_postfix(voidptr(&bufpt), bufpt, isize(1)) }
					unsafe { *__c2v_lhs_tmp_20 = i8((exp / 10 + int(`0`))) }
					mut __c2v_lhs_tmp_21 := unsafe { c2v_pointer_postfix(voidptr(&bufpt), bufpt, isize(1)) }
					unsafe { *__c2v_lhs_tmp_21 = i8((exp % 10 + int(`0`))) }
				}
				length = int((i64((isize(bufpt) - isize(z_out)) / isize(sizeof(i8)))))
				if length < width {
					n_pad := I64(width - length)
					if flag_leftjustify {
						C.memset(voidptr(bufpt), ` `, u64(n_pad))
					} else if !flag_zeropad {
						C.memmove(voidptr(z_out + n_pad), voidptr(z_out), u64(length))
						C.memset(voidptr(z_out), ` `, u64(n_pad))
					} else {
						adj := int(prefix != 0)
						C.memmove(voidptr(z_out + n_pad + adj), voidptr(z_out + adj), u64(length - adj))
						C.memset(voidptr(z_out + adj), `0`, u64(n_pad))
					}
					length = width
				}
				if usize(z_extra) == usize(0) {
					p_accum.nChar += u32(length)
					z_out[length] = i8(0)
					continue
				} else {
					bufpt[0] = i8(0)
					bufpt = z_extra
					unsafe { goto c2v_switch_end_6
					 }
				}
			}
			4 {
				if !b_arg_list {
					mut __c2v_lhs_tmp_22 := unsafe { C.va_arg(&int, ap) }
					unsafe { *__c2v_lhs_tmp_22 = int(p_accum.nChar) }
				}
				width = 0
				length = width
			}
			7 {
				buf[0] = i8(`%`)
				bufpt = unsafe { &buf[0] }
				length = 1
			}
			8 {
				if b_arg_list {
					bufpt = get_text_arg(p_arg_list)
					length = 1
					if bufpt {
						c = unsafe { *(c2v_pointer_postfix(voidptr(&bufpt), bufpt, isize(1))) }
						buf[0] = c
						if (c & 192) == 192 {
							for length < 4 && (int(bufpt[0]) & 192) == 128 {
								buf[length++] = unsafe { *(c2v_pointer_postfix(voidptr(&bufpt), bufpt, isize(1))) }
							}
						}
					} else {
						buf[0] = i8(0)
					}
				} else {
					ch := C.va_arg(u32, ap)
					length = sqlite3_append_one_utf8_character(unsafe { &i8(&buf[0]) }, ch)
				}
				if precision > 1 {
					n_prior := I64(1)
					width -= precision - 1
					if width > 1 && !flag_leftjustify {
						sqlite3_str_appendchar(p_accum, width - 1, i8(` `))
						width = 0
					}
					sqlite3_str_append(p_accum, unsafe { &i8(&buf[0]) }, length)
					precision--
					for precision > 1 {
						n_copy_bytes := I64(0)
						if n_prior > I64(precision - 1) {
							n_prior = I64(precision - 1)
						}
						n_copy_bytes = I64(length) * n_prior
						if sqlite3_str_accum_enlarge_if_needed(unsafe { &StrAccum(p_accum) }, n_copy_bytes) {
							break
						}
						sqlite3_str_append(p_accum, unsafe { p_accum.zText + (I64(p_accum.nChar) - n_copy_bytes) }, int(n_copy_bytes))
						precision -= n_prior
						n_prior *= I64(2)
					}
				}
				bufpt = unsafe { &buf[0] }
				flag_altform2 = EtByte(1)
				unsafe { goto adjust_width_for_utf8
				 }
			}
			5, 6 {
				if b_arg_list {
					bufpt = get_text_arg(p_arg_list)
					xtype = EtByte(5)
				} else {
					bufpt = C.va_arg(&i8, ap)
				}
				if usize(bufpt) == usize(0) {
					bufpt = c''
				} else if int(xtype) == 6 {
					if p_accum.nChar == u32(0) && p_accum.mxAlloc && width == 0 && precision < 0 && int(p_accum.accError) == 0 {
						p_accum.zText = bufpt
						p_accum.nAlloc = u32(sqlite3_db_malloc_size(p_accum.db, voidptr(bufpt)))
						p_accum.nChar = u32(2147483647 & int(C.strlen(bufpt)))
						p_accum.printfFlags |= 4
						length = 0
						unsafe { goto c2v_switch_end_6
						 }
					}
					z_extra = bufpt
				}
				if precision >= 0 {
					if flag_altform2 {
						z := &u8(voidptr(bufpt))
						for precision-- > 0 && int(z[0]) {
							if int((unsafe { *(c2v_pointer_postfix(voidptr(&z), z, isize(1))) })) >= 192 {
								for (int((unsafe { *z })) & 192) == 128 {
									c2v_pointer_postfix(voidptr(&z), z, isize(1))
								}
							}
						}
						length = int((i64((isize(z) - isize(&u8(voidptr(bufpt)))) / isize(sizeof(u8)))))
					} else {
						for length = 0; length < precision && int(bufpt[length]); length++ {
						}
					}
				} else {
					length = 2147483647 & int(C.strlen(bufpt))
				}
				adjust_width_for_utf8:
				if int(flag_altform2) && width > 0 {
					ii := length - 1
					for ii >= 0 {
						if (int(bufpt[ii--]) & 192) == 128 {
							width++
						}
					}
				}
			}
			9, 10, 14 {
				i := I64(0)
				mut j_2 := I64(0)
				k := I64(0)
				n := I64(0)

				need_quote := 0
				ch := i8(0)
				escarg := &i8(0)
				q := i8(0)
				if b_arg_list {
					escarg = get_text_arg(p_arg_list)
				} else {
					escarg = C.va_arg(&i8, ap)
				}
				if usize(escarg) == usize(0) {
					escarg = (if int(xtype) == 10 { c'NULL' } else { c'(NULL)' })
				} else if int(xtype) == 10 {
					need_quote = 1
				}
				if int(xtype) == 14 {
					q = i8(`\"`)
					flag_alternateform = EtByte(0)
				} else {
					q = i8(`\'`)
				}
				k = I64(precision)
				n = I64(0)
				for i = I64(0); k != I64(0) && int(c2v_assign[i8](unsafe { &ch }, i8(escarg[i]))) != 0; i++ {
					if int(ch) == int(q) {
						n++
					}
					if int(flag_altform2) && (int(ch) & 192) == 192 {
						for (int(escarg[i + I64(1)]) & 192) == 128 {
							i++
						}
					}
					k--
				}
				if flag_alternateform {
					n_back := I64(0)
					n_ctrl := I64(0)
					for k = I64(0); k < i; k++ {
						if int(escarg[k]) == i8(`\\`) {
							n_back++
						} else if int((&U8(voidptr(escarg)))[k]) <= 31 {
							n_ctrl++
						}
					}
					if n_ctrl || int(xtype) == 9 {
						n += n_back + I64(5) * n_ctrl
						if int(xtype) == 10 {
							n += I64(10)
							need_quote = 2
						}
					} else {
						flag_alternateform = EtByte(0)
					}
				}
				n += i + I64(3)
				if n > I64(70) {
					z_extra = printf_temp_buf(p_accum, n)
					bufpt = z_extra
					if usize(bufpt) == usize(0) {
						return
					}
				} else {
					bufpt = unsafe { &buf[0] }
				}
				j_2 = I64(0)
				if need_quote {
					if need_quote == 2 {
						C.memcpy(voidptr(unsafe { bufpt + j_2 }), voidptr(c"unistr('"), u64(8))
						j_2 += I64(8)
					} else {
						bufpt[j_2++] = i8(`\'`)
					}
				}
				k = i
				if flag_alternateform {
					for i = I64(0); i < k; i++ {
						ch = escarg[i]
						bufpt[j_2++] = ch
						if int(ch) == int(q) {
							bufpt[j_2++] = ch
						} else if int(ch) == i8(`\\`) {
							bufpt[j_2++] = i8(`\\`)
						} else if int((u8(ch))) <= 31 {
							bufpt[j_2 - I64(1)] = i8(`\\`)
							bufpt[j_2++] = i8(`u`)
							bufpt[j_2++] = i8(`0`)
							bufpt[j_2++] = i8(`0`)
							bufpt[j_2++] = i8(if int(ch) >= 16 { `1` } else { `0` })
							bufpt[j_2++] = c'0123456789abcdef'[int(ch) & 15]
						}
					}
				} else {
					for i = I64(0); i < k; i++ {
						ch = escarg[i]
						bufpt[j_2++] = ch
						if int(ch) == int(q) {
							bufpt[j_2++] = ch
						}
					}
				}
				if need_quote {
					bufpt[j_2++] = i8(`\'`)
					if need_quote == 2 {
						bufpt[j_2++] = i8(`)`)
					}
				}
				bufpt[j_2] = i8(0)
				length = int(j_2)
				unsafe { goto adjust_width_for_utf8
				 }
			}
			11 {
				if (int(p_accum.printfFlags) & 1) == 0 {
					return
				}
				if flag_alternateform {
					p_expr := C.va_arg(&Expr, ap)
					if !isnil(p_expr) && (!((p_expr.flags & u32(2048)) != u32(0))) {
						sqlite3_str_appendall(p_accum, &i8(p_expr.u.zToken))
						sqlite3_record_error_offset_of_expr(p_accum.db, p_expr)
					}
				} else {
					p_token := C.va_arg(&Token, ap)
					if !isnil(p_token) && p_token.n {
						sqlite3_str_append(p_accum, &i8(p_token.z), int(p_token.n))
						sqlite3_record_error_byte_offset(p_accum.db, p_token.z)
					}
				}
				width = 0
				length = width
			}
			12 {
				p_item := &SrcItem(0)
				if (int(p_accum.printfFlags) & 1) == 0 {
					return
				}
				p_item = C.va_arg(&SrcItem, ap)
				if !isnil(p_item.zAlias) && !flag_altform2 {
					sqlite3_str_appendall(p_accum, p_item.zAlias)
				} else if p_item.zName {
					if int(p_item.fg.fixedSchema) == 0 && int(p_item.fg.isSubquery) == 0 && usize(p_item.u4.zDatabase) != usize(0) {
						sqlite3_str_appendall(p_accum, p_item.u4.zDatabase)
						sqlite3_str_append(p_accum, c'.', 1)
					}
					sqlite3_str_appendall(p_accum, p_item.zName)
				} else if p_item.zAlias {
					sqlite3_str_appendall(p_accum, p_item.zAlias)
				} else if p_item.fg.isSubquery {
					p_sel := p_item.u4.pSubq.pSelect
					if p_sel.selFlags & u32(2048) {
						sqlite3_str_appendf(p_accum, c'(join-%u)', p_sel.selId)
					} else if p_sel.selFlags & u32(1024) {
						sqlite3_str_appendf(p_accum, c'%u-ROW VALUES CLAUSE', p_item.u1.nRow)
					} else {
						sqlite3_str_appendf(p_accum, c'(subquery-%u)', p_sel.selId)
					}
				}
				width = 0
				length = width
			}
			else {
				return
			}
		}
		c2v_switch_end_6:

		width -= length
		if width > 0 {
			if !flag_leftjustify {
				sqlite3_str_appendchar(p_accum, width, i8(` `))
			}
			sqlite3_str_append(p_accum, bufpt, length)
			if flag_leftjustify {
				sqlite3_str_appendchar(p_accum, width, i8(` `))
			}
		} else {
			sqlite3_str_append(p_accum, bufpt, length)
		}
		if z_extra {
			sqlite3_db_free(p_accum.db, voidptr(z_extra))
			z_extra = 0
		}
	}
}

@[c:'sqlite3RecordErrorByteOffset']
fn sqlite3_record_error_byte_offset(db &Sqlite3, z &i8) {
	p_parse := &Parse(0)
	z_text := &i8(0)
	z_end := &i8(0)
	if (usize(db) == usize(0)) {
		return
	}
	if db.errByteOffset != (-2) {
		return
	}
	p_parse = db.pParse
	if (usize(p_parse) == usize(0)) {
		return
	}
	z_text = p_parse.zTail
	if (usize(z_text) == usize(0)) {
		return
	}
	z_end = unsafe { z_text + C.strlen(z_text) }
	if ((Uptr(voidptr(z)) >= Uptr(voidptr(z_text))) && (Uptr(voidptr(z)) < Uptr(voidptr(z_end)))) {
		db.errByteOffset = int((i64((isize(z) - isize(z_text)) / isize(sizeof(i8)))))
	}
}

@[c:'sqlite3RecordErrorOffsetOfExpr']
fn sqlite3_record_error_offset_of_expr(db &Sqlite3, p_expr &Expr) {
	for !isnil(p_expr) && (((p_expr.flags & u32((1 | 2))) != u32(0)) || p_expr.w.iOfst <= 0) {
		p_expr = p_expr.pLeft
	}
	if usize(p_expr) == usize(0) {
		return
	}
	if ((p_expr.flags & u32(1073741824)) != u32(0)) {
		return
	}
	db.errByteOffset = p_expr.w.iOfst
}

@[c:'sqlite3StrAccumEnlarge']
fn sqlite3_str_accum_enlarge(p &StrAccum, n I64) int {
	z_new := &i8(0)
	if p.accError {
		return 0
	}
	if p.mxAlloc == u32(0) {
		sqlite3_str_accum_set_error(p, U8(18))
		return int(p.nAlloc - p.nChar - u32(1))
	} else {
		z_old := unsafe { if ((int(p.printfFlags) & 4) != 0) { p.zText } else { &i8(nil) } }
		sz_new := I64(p.nChar) + n + I64(1)
		if sz_new + I64(p.nChar) <= I64(p.mxAlloc) {
			sz_new += I64(p.nChar)
		}
		if sz_new > I64(p.mxAlloc) {
			sqlite3_str_reset(unsafe { &Sqlite3_str(p) })
			sqlite3_str_accum_set_error(p, U8(18))
			return 0
		} else {
			p.nAlloc = u32(int(sz_new))
		}
		if p.db {
			z_new = &i8(sqlite3_db_realloc(p.db, voidptr(z_old), U64(p.nAlloc)))
		} else {
			z_new = &i8(sqlite3_realloc_vdup3(voidptr(z_old), U64(p.nAlloc)))
		}
		if z_new {
			if !((int(p.printfFlags) & 4) != 0) && p.nChar > u32(0) {
				C.memcpy(voidptr(z_new), voidptr(p.zText), u64(p.nChar))
			}
			p.zText = z_new
			p.nAlloc = u32(sqlite3_db_malloc_size(p.db, voidptr(z_new)))
			p.printfFlags |= 4
		} else {
			sqlite3_str_reset(unsafe { &Sqlite3_str(p) })
			sqlite3_str_accum_set_error(p, U8(7))
			return 0
		}
	}
	return int(n)
}

@[c:'sqlite3StrAccumEnlargeIfNeeded']
fn sqlite3_str_accum_enlarge_if_needed(p &StrAccum, n I64) int {
	if n + I64(p.nChar) >= I64(p.nAlloc) {
		sqlite3_str_accum_enlarge(p, n)
	}
	return int(p.accError)
}

fn sqlite3_str_appendchar(p &Sqlite3_str, n int, c i8) {
	c2v_gc_register_thread()
	if I64(p.nChar) + I64(n) >= I64(p.nAlloc) && c2v_assign[int](unsafe { &n }, int(sqlite3_str_accum_enlarge(unsafe { &StrAccum(p) }, I64(n)))) <= 0 {
		return
	}
	for (n--) > 0 {
		p.zText[p.nChar++] = c
	}
}

@[c:'enlargeAndAppend']
fn enlarge_and_append(p &StrAccum, z &i8, n int) {
	n = sqlite3_str_accum_enlarge(p, I64(n))
	if n > 0 {
		C.memcpy(voidptr(unsafe { p.zText + p.nChar }), voidptr(z), u64(n))
		p.nChar += u32(n)
	}
}

fn sqlite3_str_append(p &Sqlite3_str, z &i8, n int) {
	c2v_gc_register_thread()
	if p.nChar + u32(n) >= p.nAlloc {
		enlarge_and_append(unsafe { &StrAccum(p) }, z, n)
	} else if n {
		p.nChar += u32(n)
		C.memcpy(voidptr(unsafe { p.zText + (p.nChar - u32(n)) }), voidptr(z), u64(n))
	}
}

fn sqlite3_str_appendall(p &Sqlite3_str, z &i8) {
	c2v_gc_register_thread()
	sqlite3_str_append(p, z, sqlite3_strlen30(z))
}

@[c:'strAccumFinishRealloc']
fn str_accum_finish_realloc(p &StrAccum) &i8 {
	z_text := &i8(0)
	z_text = &i8(sqlite3_db_malloc_raw(p.db, U64(1) + U64(p.nChar)))
	if z_text {
		C.memcpy(voidptr(z_text), voidptr(p.zText), u64(p.nChar + u32(1)))
		p.printfFlags |= 4
	} else {
		sqlite3_str_accum_set_error(p, U8(7))
	}
	p.zText = z_text
	return z_text
}

@[c:'sqlite3StrAccumFinish']
fn sqlite3_str_accum_finish(p &StrAccum) &i8 {
	if p.zText {
		p.zText[p.nChar] = i8(0)
		if p.mxAlloc > u32(0) && !((int(p.printfFlags) & 4) != 0) {
			return str_accum_finish_realloc(p)
		}
	}
	return p.zText
}

@[c:'sqlite3ResultStrAccum']
fn sqlite3_result_str_accum(p_ctx &Sqlite3_context, p &StrAccum) {
	if p.accError {
		sqlite3_result_error_code(p_ctx, int(p.accError))
		sqlite3_str_reset(unsafe { &Sqlite3_str(p) })
	} else if ((int(p.printfFlags) & 4) != 0) {
		sqlite3_result_text(p_ctx, p.zText, int(p.nChar), (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))))
	} else {
		sqlite3_result_text(p_ctx, c'', 0, (C2vFn_666e2028766f696470747229(voidptr(0))))
		sqlite3_str_reset(unsafe { &Sqlite3_str(p) })
	}
}

fn sqlite3_str_finish(p &Sqlite3_str) &i8 {
	c2v_gc_register_thread()
	z := &i8(0)
	if usize(p) != usize(0) && usize(p) != usize(&sqlite3OomStr) {
		z = sqlite3_str_accum_finish(unsafe { &StrAccum(p) })
		sqlite3_free(voidptr(p))
	} else {
		z = 0
	}
	return z
}

fn sqlite3_str_errcode(p &Sqlite3_str) int {
	c2v_gc_register_thread()
	return if p { int(p.accError) } else { 7 }
}

fn sqlite3_str_length(p &Sqlite3_str) int {
	c2v_gc_register_thread()
	return int(if p { p.nChar } else { u32(0) })
}

fn sqlite3_str_truncate(p &Sqlite3_str, n int) {
	c2v_gc_register_thread()
	if usize(p) != usize(0) && n >= 0 && u32(n) < p.nChar {
		p.nChar = u32(n)
		p.zText[p.nChar] = i8(0)
	}
}

fn sqlite3_str_value(p &Sqlite3_str) &i8 {
	c2v_gc_register_thread()
	if usize(p) == usize(0) || p.nChar == u32(0) {
		return unsafe { nil }
	}
	p.zText[p.nChar] = i8(0)
	return p.zText
}

fn sqlite3_str_reset(p &StrAccum) {
	c2v_gc_register_thread()
	if ((int(p.printfFlags) & 4) != 0) {
		sqlite3_db_free(p.db, voidptr(p.zText))
		p.printfFlags &= ~4
	}
	p.nAlloc = u32(0)
	p.nChar = u32(0)
	p.zText = 0
}

fn sqlite3_str_free(p &Sqlite3_str) {
	c2v_gc_register_thread()
	if usize(p) != usize(0) && usize(p) != usize(&sqlite3OomStr) {
		sqlite3_str_reset(p)
		sqlite3_free(voidptr(p))
	}
}

@[c:'sqlite3StrAccumInit']
fn sqlite3_str_accum_init(p &StrAccum, db &Sqlite3, z_base &i8, n int, mx int) {
	p.zText = z_base
	p.db = db
	p.nAlloc = u32(n)
	p.mxAlloc = u32(mx)
	p.nChar = u32(0)
	p.accError = U8(0)
	p.printfFlags = U8(0)
}

fn sqlite3_str_new(db &Sqlite3) &Sqlite3_str {
	c2v_gc_register_thread()
	p := &Sqlite3_str(sqlite3_malloc64(Sqlite3_uint64(sizeof(Sqlite3_str))))
	if p {
		sqlite3_str_accum_init(unsafe { &StrAccum(p) }, unsafe { nil }, unsafe { nil }, 0, if db {
			db.aLimit[0]
		} else {
			1000000000
		})
	} else {
		p = &sqlite3OomStr
	}
	return p
}

@[c:'sqlite3VMPrintf']
fn sqlite3_vm_printf(db &Sqlite3, z_format &i8, ap C.va_list) &i8 {
	z := &i8(0)
	z_base := [70]i8{}
	acc := StrAccum{}
	sqlite3_str_accum_init(&acc, db, unsafe { &i8(&z_base[0]) }, int(sizeof([70]i8)), db.aLimit[0])
	acc.printfFlags = U8(1)
	sqlite3_str_vappendf(unsafe { &Sqlite3_str(&acc) }, z_format, ap)
	z = sqlite3_str_accum_finish(&acc)
	if int(acc.accError) == 7 {
		sqlite3_oom_fault(db)
	}
	return z
}

@[c:'sqlite3MPrintf']
@[c2v_variadic]
fn sqlite3_mp_rintf(db &Sqlite3, z_format &i8, ...) &i8 {
	ap := C.va_list{}
	z := &i8(0)
	C.va_start(ap, z_format)
	z = sqlite3_vm_printf(db, z_format, ap)
	C.va_end(ap)
	return z
}

fn sqlite3_vmprintf(z_format &i8, ap C.va_list) &i8 {
	c2v_gc_register_thread()
	z := &i8(0)
	z_base := [70]i8{}
	acc := StrAccum{}
	if sqlite3_initialize() {
		return unsafe { nil }
	}
	sqlite3_str_accum_init(&acc, unsafe { nil }, unsafe { &i8(&z_base[0]) }, int(sizeof([70]i8)), 1000000000)
	sqlite3_str_vappendf(unsafe { &Sqlite3_str(&acc) }, z_format, ap)
	z = sqlite3_str_accum_finish(&acc)
	return z
}

@[c2v_variadic]
fn sqlite3_mprintf(z_format &i8, ...) &i8 {
	c2v_gc_register_thread()
	ap := C.va_list{}
	z := &i8(0)
	if sqlite3_initialize() {
		return unsafe { nil }
	}
	C.va_start(ap, z_format)
	z = sqlite3_vmprintf(z_format, ap)
	C.va_end(ap)
	return z
}

fn sqlite3_vsnprintf(n int, z_buf &i8, z_format &i8, ap C.va_list) &i8 {
	c2v_gc_register_thread()
	acc := StrAccum{}
	if n <= 0 {
		return z_buf
	}
	sqlite3_str_accum_init(&acc, unsafe { nil }, z_buf, n, 0)
	sqlite3_str_vappendf(unsafe { &Sqlite3_str(&acc) }, z_format, ap)
	z_buf[acc.nChar] = i8(0)
	return z_buf
}

@[c2v_variadic]
fn sqlite3_snprintf(n int, z_buf &i8, z_format &i8, ...) &i8 {
	c2v_gc_register_thread()
	acc := StrAccum{}
	ap := C.va_list{}
	if n <= 0 {
		return z_buf
	}
	sqlite3_str_accum_init(&acc, unsafe { nil }, z_buf, n, 0)
	C.va_start(ap, z_format)
	sqlite3_str_vappendf(unsafe { &Sqlite3_str(&acc) }, z_format, ap)
	C.va_end(ap)
	z_buf[acc.nChar] = i8(0)
	return z_buf
}

@[c:'renderLogMsg']
fn render_log_msg(i_err_code int, z_format &i8, ap C.va_list) {
	acc := StrAccum{}
	z_msg := [700]i8{}
	sqlite3_str_accum_init(&acc, unsafe { nil }, unsafe { &i8(&z_msg[0]) }, int(sizeof([700]i8)), 0)
	sqlite3_str_vappendf(unsafe { &Sqlite3_str(&acc) }, z_format, ap)
	sqlite3Config.xLog(voidptr(sqlite3Config.pLogArg), i_err_code, sqlite3_str_accum_finish(&acc))
}

@[c2v_variadic]
fn sqlite3_log(i_err_code int, z_format &i8, ...) {
	c2v_gc_register_thread()
	ap := C.va_list{}
	if sqlite3Config.xLog {
		C.va_start(ap, z_format)
		render_log_msg(i_err_code, z_format, ap)
		C.va_end(ap)
	}
}

@[c2v_variadic]
fn sqlite3_str_appendf(p &StrAccum, z_format &i8, ...) {
	c2v_gc_register_thread()
	ap := C.va_list{}
	C.va_start(ap, z_format)
	sqlite3_str_vappendf(unsafe { &Sqlite3_str(p) }, z_format, ap)
	C.va_end(ap)
}

@[c:'sqlite3RCStrRef']
fn sqlite3_rc_str_ref(z &i8) &i8 {
	p := &RCStr(voidptr(z))
	c2v_pointer_postfix(voidptr(&p), p, isize(-1))
	p.nRCRef++
	return z
}

@[c:'sqlite3RCStrUnref']
fn sqlite3_rc_str_unref(z voidptr) {
	c2v_gc_register_thread()
	p := &RCStr(z)
	c2v_pointer_postfix(voidptr(&p), p, isize(-1))
	if p.nRCRef >= U64(2) {
		p.nRCRef--
	} else {
		sqlite3_free(voidptr(p))
	}
}

@[c:'sqlite3RCStrNew']
fn sqlite3_rc_str_new(n U64) &i8 {
	p := &RCStr(sqlite3_malloc64(n + U64(sizeof(RCStr)) + U64(1)))
	if usize(p) == usize(0) {
		return unsafe { nil }
	}
	p.nRCRef = U64(1)
	return &i8(voidptr(unsafe { p + 1 }))
}

@[c:'sqlite3RCStrResize']
fn sqlite3_rc_str_resize(z &i8, n U64) &i8 {
	p := &RCStr(voidptr(z))
	p_new := &RCStr(0)
	c2v_pointer_postfix(voidptr(&p), p, isize(-1))
	p_new = sqlite3_realloc64(voidptr(p), n + U64(sizeof(RCStr)) + U64(1))
	if usize(p_new) == usize(0) {
		sqlite3_free(voidptr(p))
		return unsafe { nil }
	} else {
		return &i8(voidptr(unsafe { p_new + 1 }))
	}
}
