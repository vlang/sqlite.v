@[translated]
module main

@[c:'sqlite3FaultSim']
fn sqlite3_fault_sim(i_test int) int {
	x_callback := sqlite3Config.xTestCallback
	return if x_callback { x_callback(i_test) } else { 0 }
}

@[c:'sqlite3IsNaN']
fn sqlite3_is_na_n(x f64) int {
	rc := 0
	y := U64(0)
	C.memcpy(voidptr(&y), voidptr(&x), sizeof(y))
	rc = ((y & ((U64(2047)) << 52)) == ((U64(2047)) << 52) && (y & (((U64(1)) << 52) - U64(1))) != U64(0))
	return rc
}

@[c:'sqlite3IsOverflow']
fn sqlite3_is_overflow(x f64) int {
	rc := 0
	y := U64(0)
	C.memcpy(voidptr(&y), voidptr(&x), sizeof(y))
	rc = ((y & ((U64(2047)) << 52)) == ((U64(2047)) << 52))
	return rc
}

@[c:'sqlite3Strlen30']
fn sqlite3_strlen30(z &i8) int {
	if usize(z) == usize(0) {
		return 0
	}
	return 1073741823 & int(C.strlen(z))
}

@[c:'sqlite3ColumnType']
fn sqlite3_column_type_vdup1(p_col &Column, z_dflt &i8) &i8 {
	if int(p_col.colFlags) & 4 {
		return p_col.zCnName + C.strlen(p_col.zCnName) + 1
	} else if p_col.eCType {
		return &i8(sqlite3StdType[int(p_col.eCType) - 1])
	} else {
		return z_dflt
	}
}

@[c:'sqlite3ErrorFinish']
fn sqlite3_error_finish(db &Sqlite3, err_code int) {
	if db.pErr {
		sqlite3_value_set_null(db.pErr)
	}
	sqlite3_system_error(db, err_code)
}

@[c:'sqlite3Error']
fn sqlite3_error(db &Sqlite3, err_code int) {
	db.errCode = err_code
	if err_code || !isnil(db.pErr) {
		sqlite3_error_finish(db, err_code)
	} else {
		db.errByteOffset = -1
	}
}

@[c:'sqlite3ErrorClear']
fn sqlite3_error_clear(db &Sqlite3) {
	db.errCode = 0
	db.errByteOffset = -1
	if db.pErr {
		sqlite3_value_set_null(db.pErr)
	}
}

@[c:'sqlite3SystemError']
fn sqlite3_system_error(db &Sqlite3, rc int) {
	if rc == (10 | (12 << 8)) {
		return
	}
	rc &= 255
	if rc == 14 || rc == 10 {
		db.iSysErrno = sqlite3_os_get_last_error(db.pVfs)
	}
}

@[c:'sqlite3ErrorWithMsg']
@[c2v_variadic]
fn sqlite3_error_with_msg(db &Sqlite3, err_code int, z_format &i8, ...) {
	db.errCode = err_code
	sqlite3_system_error(db, err_code)
	if usize(z_format) == usize(0) {
		sqlite3_error(db, err_code)
	} else {
		if !isnil(db.pErr) || usize(c2v_assign[&Sqlite3_value](unsafe { &db.pErr }, sqlite3_value_new(db))) != usize(0) {
			z := &i8(0)
			ap := C.va_list{}
			C.va_start(ap, z_format)
			z = sqlite3_vm_printf(db, z_format, ap)
			C.va_end(ap)
			sqlite3_value_set_str(db.pErr, -1, voidptr(z), U8(1), (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))))
		}
	}
}

@[c:'sqlite3ProgressCheck']
fn sqlite3_progress_check(p &Parse) {
	db := p.db
	if C.c2v_atomic_load_n__int_int_int((&db.u1.isInterrupted), 0) {
		p.nErr++
		p.rc = 9
	}
	if db.xProgress {
		if p.rc == 9 {
			p.nProgressSteps = u32(0)
		} else {
			p.nProgressSteps++
			if (p.nProgressSteps) >= db.nProgressOps {
				if db.xProgress(voidptr(db.pProgressArg)) {
					p.nErr++
					p.rc = 9
				}
				p.nProgressSteps = u32(0)
			}
		}
	}
}

@[c:'sqlite3ErrorMsg']
@[c2v_variadic]
fn sqlite3_error_msg(p_parse &Parse, z_format &i8, ...) {
	z_msg := &i8(0)
	ap := C.va_list{}
	db := p_parse.db
	db.errByteOffset = -2
	C.va_start(ap, z_format)
	z_msg = sqlite3_vm_printf(db, z_format, ap)
	C.va_end(ap)
	if db.errByteOffset < -1 {
		db.errByteOffset = -1
	}
	if db.suppressErr {
		sqlite3_db_free(db, voidptr(z_msg))
		if db.mallocFailed {
			p_parse.nErr++
			p_parse.rc = 7
		}
	} else {
		p_parse.nErr++
		sqlite3_db_free(db, voidptr(p_parse.zErrMsg))
		p_parse.zErrMsg = z_msg
		p_parse.rc = 1
		p_parse.pWith = 0
	}
}

@[c:'sqlite3ErrorToParser']
fn sqlite3_error_to_parser(db &Sqlite3, err_code int) int {
	p_parse := &Parse(0)
	if usize(db) == usize(0) || usize(c2v_assign[&Parse](unsafe { &p_parse }, db.pParse)) == usize(0) {
		return err_code
	}
	p_parse.rc = err_code
	p_parse.nErr++
	return err_code
}

@[c:'sqlite3Dequote']
fn sqlite3_dequote(z &i8) {
	quote := i8(0)
	i := 0
	j := 0

	if usize(z) == usize(0) {
		return
	}
	quote = z[0]
	if !(int(sqlite3CtypeMap[u8(quote)]) & 128) {
		return
	}
	if int(quote) == i8(`[`) {
		quote = i8(`]`)
	}
	i = 1
	for j = 0; ; i++ {
		if int(z[i]) == int(quote) {
			if int(z[i + 1]) == int(quote) {
				z[j++] = quote
				i++
			} else {
				break
			}
		} else {
			z[j++] = z[i]
		}
	}
	z[j] = i8(0)
}

@[c:'sqlite3DequoteExpr']
fn sqlite3_dequote_expr(p &Expr) {
	p.flags |= u32(if int(p.u.zToken[0]) == i8(`\"`) { 67108864 | 128 } else { 67108864 })
	sqlite3_dequote(p.u.zToken)
}

@[c:'sqlite3DequoteNumber']
fn sqlite3_dequote_number(p_parse &Parse, p &Expr) {
	if p {
		p_in := p.u.zToken
		p_out := p.u.zToken
		b_hex := int((int(p_in[0]) == i8(`0`) && (int(p_in[1]) == i8(`x`) || int(p_in[1]) == i8(`X`))))
		i_value := 0
		p.op = U8(156)
		for {
			if int((unsafe { *p_in })) != i8(`_`) {
				mut __c2v_lhs_tmp_57 := unsafe { c2v_pointer_postfix(voidptr(&p_out), p_out, isize(1)) }
				unsafe { *__c2v_lhs_tmp_57 = *p_in }
				if int((unsafe { *p_in })) == i8(`e`) || int((unsafe { *p_in })) == i8(`E`) || int((unsafe { *p_in })) == i8(`.`) {
					p.op = U8(154)
				}
			} else {
				mut __c2v_condition_0 := false
				mut __c2v_condition_1 := false
				__c2v_condition_1 = (b_hex == 0 && (!(int(sqlite3CtypeMap[u8(p_in[-1])]) & 4) || !(int(sqlite3CtypeMap[u8(p_in[1])]) & 4)))
				__c2v_condition_0 = __c2v_condition_1
				if !__c2v_condition_0 {
					mut __c2v_condition_2 := false
					__c2v_condition_2 = (b_hex == 1 && (!(int(sqlite3CtypeMap[u8(p_in[-1])]) & 8) || !(int(sqlite3CtypeMap[u8(p_in[1])]) & 8)))
					__c2v_condition_0 = __c2v_condition_2
				}
				if __c2v_condition_0 {
					sqlite3_error_msg(p_parse, c'unrecognized token: "%s"', voidptr(p.u.zToken))
				}
			}
			if !(unsafe { *c2v_pointer_postfix(voidptr(&p_in), p_in, isize(1)) }) {
				break
			}
		}
		if b_hex {
			p.op = U8(156)
		}
		if int(p.op) == 156 && sqlite3_get_int32(p.u.zToken, &i_value) {
			p.u.iValue = i_value
			p.flags |= u32(2048)
		}
	}
}

@[c:'sqlite3DequoteToken']
fn sqlite3_dequote_token(p &Token) {
	i := u32(0)
	if p.n < u32(2) {
		return
	}
	if !(int(sqlite3CtypeMap[u8(p.z[0])]) & 128) {
		return
	}
	for i = u32(1); i < p.n - u32(1); i++ {
		if (int(sqlite3CtypeMap[u8(p.z[i])]) & 128) {
			return
		}
	}
	p.n -= u32(2)
	c2v_pointer_postfix(voidptr(&p.z), p.z, isize(1))
}

@[c:'sqlite3TokenInit']
fn sqlite3_token_init(p &Token, z &i8) {
	p.z = z
	p.n = u32(sqlite3_strlen30(z))
}

fn sqlite3_stricmp(z_left &i8, z_right &i8) int {
	c2v_gc_register_thread()
	if usize(z_left) == usize(0) {
		return if z_right { -1 } else { 0 }
	} else if usize(z_right) == usize(0) {
		return 1
	}
	return sqlite3_str_ic_mp(z_left, z_right)
}

@[c:'sqlite3StrICmp']
fn sqlite3_str_ic_mp(z_left &i8, z_right &i8) int {
	a := &u8(0)
	b := &u8(0)

	c := 0
	x := 0

	a = &u8(voidptr(z_left))
	b = &u8(voidptr(z_right))
	for {
		c = unsafe { *a }
		x = unsafe { *b }
		if c == x {
			if c == 0 {
				break
			}
		} else {
			c = int(sqlite3UpperToLower[c]) - int(sqlite3UpperToLower[x])
			if c {
				break
			}
		}
		c2v_pointer_postfix(voidptr(&a), a, isize(1))
		c2v_pointer_postfix(voidptr(&b), b, isize(1))
	}
	return c
}

fn sqlite3_strnicmp(z_left &i8, z_right &i8, n int) int {
	c2v_gc_register_thread()
	a := &u8(0)
	b := &u8(0)

	if usize(z_left) == usize(0) {
		return if z_right { -1 } else { 0 }
	} else if usize(z_right) == usize(0) {
		return 1
	}
	a = &u8(voidptr(z_left))
	b = &u8(voidptr(z_right))
	for n-- > 0 && int((unsafe { *a })) != 0 && int(sqlite3UpperToLower[(unsafe { *a })]) == int(sqlite3UpperToLower[(unsafe { *b })]) {
		c2v_pointer_postfix(voidptr(&a), a, isize(1))
		c2v_pointer_postfix(voidptr(&b), b, isize(1))
	}
	return if n < 0 {
		0
	} else {
		int(sqlite3UpperToLower[(unsafe { *a })]) - int(sqlite3UpperToLower[(unsafe { *b })])
	}
}

@[c:'sqlite3StrIHash']
fn sqlite3_str_ih_ash(z &i8) U8 {
	h := U8(0)
	if usize(z) == usize(0) {
		return U8(0)
	}
	for z[0] {
		h += int(sqlite3UpperToLower[u8(z[0])])
		c2v_pointer_postfix(voidptr(&z), z, isize(1))
	}
	return h
}

@[c:'sqlite3Multiply128']
fn sqlite3_multiply128(a U64, b U64, p_lo &U64) U64 {
	r := c2v_u128_mul(c2v_u128(u64(a)), c2v_u128(u64(b)))
	unsafe { *p_lo = U64(r.lo) }
	return U64((c2v_u128_shr(r, int(64))).lo)
}

@[c:'sqlite3Multiply160']
fn sqlite3_multiply160(a U64, a_lo u32, b U64, p_lo &u32) U64 {
	r := c2v_u128_mul(c2v_u128(u64(a)), c2v_u128(u64(b)))
	r = c2v_u128_add(r, c2v_u128_shr((c2v_u128_mul(c2v_u128(u64(a_lo)), c2v_u128(u64(b)))), int(32)))
	unsafe { *p_lo = u32((c2v_u128_and((c2v_u128_shr(r, int(32))), c2v_u128(u64(u32(4294967295))))).lo) }
	return U64((c2v_u128_shr(r, int(64))).lo)
}

@[c:'powerOfTen']
fn power_of_ten(p int, p_lo &u32) U64 {
	if !power_of_ten_a_base_inited {
		c2v_static_init := [U64(u64(9223372036854775808)), U64(u64(11529215046068469760)),
			U64(u64(14411518807585587200)), U64(u64(18014398509481984000)),
			U64(u64(11258999068426240000)), U64(u64(14073748835532800000)),
			U64(u64(17592186044416000000)), U64(u64(10995116277760000000)),
			U64(u64(13743895347200000000)), U64(u64(17179869184000000000)),
			U64(u64(10737418240000000000)), U64(u64(13421772800000000000)),
			U64(u64(16777216000000000000)), U64(u64(10485760000000000000)),
			U64(u64(13107200000000000000)), U64(u64(16384000000000000000)),
			U64(u64(10240000000000000000)), U64(u64(12800000000000000000)),
			U64(u64(16000000000000000000)), U64(u64(10000000000000000000)),
			U64(u64(12500000000000000000)), U64(u64(15625000000000000000)),
			U64(u64(9765625000000000000)), U64(u64(12207031250000000000)),
			U64(u64(15258789062500000000)), U64(u64(9536743164062500000)),
			U64(u64(11920928955078125000))]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			power_of_ten_a_base[c2v_i_0] = c2v_element_0
		}
		power_of_ten_a_base_inited = true
	}

	if !power_of_ten_a_scale_inited {
		c2v_static_init := [U64(u64(9244100769003082158)), U64(u64(14934650266808366570)),
			U64(u64(12064114410120881697)), U64(u64(9745314011399999080)),
			U64(u64(15744403932561434696)), U64(u64(12718228212127407596)),
			U64(u64(10273702932711667006)), U64(u64(16598062275523971834)),
			U64(u64(13407807929942597099)), U64(u64(10830740992659433045)),
			U64(u64(17498005798264095394)), U64(u64(14134776518227074636)),
			U64(u64(11417981541647679048)), U64(u64(14757395258967641292)),
			U64(u64(14901161193847656250)), U64(u64(12037062152420224081)),
			U64(u64(9723461371658033917)), U64(u64(15709099088952724969)),
			U64(u64(12689709186578246116)), U64(u64(10250665447337476733)),
			U64(u64(16560843210556190337)), U64(u64(13377742608693866209)),
			U64(u64(10806454419566533849)), U64(u64(17458768723248864463)),
			U64(u64(14103081061443981063)), U64(u64(11392378155556871081))]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			power_of_ten_a_scale[c2v_i_0] = c2v_element_0
		}
		power_of_ten_a_scale_inited = true
	}

	if !power_of_ten_a_scale_lo_inited {
		c2v_static_init := [u32(542869869), u32(1376144557), u32(u32(2938827448)), u32(1517765799),
			u32(u32(2939790453)), u32(u32(3180165454)), u32(1417589883), u32(213165475),
			u32(u32(2465418594)), u32(980027385), u32(u32(4209144473)), u32(u32(2862080332)),
			u32(2002690661), u32(u32(3435973836)), u32(0), u32(u32(2576388278)), u32(1772103867),
			u32(u32(3893260104)), u32(1589665232), u32(341348116), u32(u32(2400610505)),
			u32(1838497324), u32(1253945104), u32(u32(3160619833)), u32(176566145), u32(1812439746)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			power_of_ten_a_scale_lo[c2v_i_0] = c2v_element_0
		}
		power_of_ten_a_scale_lo_inited = true
	}

	g := 0
	n := 0

	s := U64(0)
	x := U64(0)

	lo := u32(0)
	if p < 0 {
		if p == (-1) {
			unsafe { *p_lo = power_of_ten_a_scale_lo[13] }
			return power_of_ten_a_scale[13]
		}
		g = p / 27
		n = p % 27
		if n {
			g--
			n += 27
		}
	} else if p < 27 {
		unsafe { *p_lo = u32(0) }
		return power_of_ten_a_base[p]
	} else {
		g = p / 27
		n = p % 27
	}
	s = power_of_ten_a_scale[g + 13]
	if n == 0 {
		unsafe { *p_lo = power_of_ten_a_scale_lo[g + 13] }
		return s
	}
	x = sqlite3_multiply160(s, power_of_ten_a_scale_lo[g + 13], power_of_ten_a_base[n], &lo)
	if (((U64(1)) << 63) & x) == U64(0) {
		x = x << 1 | U64(((lo >> 31) & u32(1)))
		lo = (lo << 1) | u32(1)
	}
	unsafe { *p_lo = lo }
	return x
}

fn pwr10to2(p int) int {
	return (p * 108853) >> 15
}

fn pwr2to10(p int) int {
	return (p * 78913) >> 18
}

@[c:'countLeadingZeros']
fn count_leading_zeros(m U64) int {
	return C.__builtin_clzll(m)
}

@[c:'sqlite3Fp2Convert10']
fn sqlite3_fp2_convert10(m U64, e int, n int, pd &U64, pp &int) {
	p := 0
	h := U64(0)
	d1 := U64(0)

	d2 := u32(0)
	p = n - 1 - pwr2to10(e + 63)
	h = sqlite3_multiply128(m, power_of_ten(p, &d2), &d1)
	if n == 18 {
		h >>= -(e + pwr10to2(p) + 2)
		unsafe { *pd = (h + ((h << 1) & U64(2))) >> 1 }
	} else {
		unsafe { *pd = h >> -(e + pwr10to2(p) + 1) }
	}
	unsafe { *pp = -p }
}

@[c:'sqlite3Fp10Convert2']
fn sqlite3_fp10_convert2(d U64, p int) f64 {
	b := 0
	lp := 0
	e := 0
	adj := 0
	s := 0

	pwr10l := u32(0)
	mid1 := u32(0)

	pwr10h := U64(0)
	x := U64(0)
	hi := U64(0)
	lo := U64(0)
	sticky := U64(0)
	u := U64(0)
	m := U64(0)

	r := 0.0
	if p < (-348) {
		return 0.0
	}
	if p > (347) {
		return f64(C.__builtin_huge_valf())
	}
	b = 64 - count_leading_zeros(d)
	lp = pwr10to2(p)
	e = 53 - b - lp
	if e > 1074 {
		if e >= 1130 {
			return 0.0
		}
		e = 1074
	}
	s = -(e - (64 - b) + lp + 3)
	pwr10h = power_of_ten(p, &pwr10l)
	if pwr10l != u32(0) {
		pwr10h++
		pwr10l = ~pwr10l
	}
	x = d << (64 - b)
	hi = sqlite3_multiply128(x, pwr10h, &lo)
	mid1 = u32(lo >> 32)
	sticky = U64(1)
	if (hi & (((U64(1)) << s) - U64(1))) == U64(0) {
		mid2 := u32(sqlite3_multiply128(x, (U64(pwr10l)) << 32, &lo) >> 32)
		sticky = U64((mid1 - mid2 > u32(1)))
		hi -= U64(mid1 < mid2)
	}
	u = (hi >> s) | sticky
	adj = (u >= ((U64(1)) << 55) - U64(2))
	if adj {
		u = (u >> adj) | (u & U64(1))
		e -= adj
	}
	m = (u + U64(1) + ((u >> 2) & U64(1))) >> 2
	if e <= (-972) {
		return f64(C.__builtin_huge_valf())
	}
	if (m & ((U64(1)) << 52)) != U64(0) {
		m = (m & ~((U64(1)) << 52)) | (U64((1075 - e)) << 52)
	}
	C.memcpy(voidptr(&r), voidptr(&m), u64(8))
	return r
}

@[c:'sqlite3AtoF']
fn sqlite3_ato_f(z_in &i8, p_result &f64) int {
	z := &u8(voidptr(z_in))
	neg := 0
	s := U64(0)
	d := 0
	m_state := 0
	v := u32(0)
	start_of_text:
	v = u32(z[0]) - u32(`0`)
	if v < u32(10) {
		parse_integer_part:
		m_state = 1
		s = U64(v)
		c2v_pointer_postfix(voidptr(&z), z, isize(1))
		for {
			v = u32(z[0]) - u32(`0`)
			if !(v < u32(10)) {
				break
			}
			s = s * U64(10) + U64(v)
			c2v_pointer_postfix(voidptr(&z), z, isize(1))
			if s >= ((U64(u32(4294967295)) | ((U64(u32(4294967295))) << 32)) - U64(9)) / U64(10) {
				m_state = 9
				for (int(sqlite3CtypeMap[u8(z[0])]) & 4) {
					c2v_pointer_postfix(voidptr(&z), z, isize(1))
					d++
				}
				break
			}
		}
	} else if int(z[0]) == `-` {
		neg = 1
		c2v_pointer_postfix(voidptr(&z), z, isize(1))
		v = u32(z[0]) - u32(`0`)
		if v < u32(10) {
			unsafe { goto parse_integer_part
			 }
		}
	} else if int(z[0]) == `+` {
		c2v_pointer_postfix(voidptr(&z), z, isize(1))
		v = u32(z[0]) - u32(`0`)
		if v < u32(10) {
			unsafe { goto parse_integer_part
			 }
		}
	} else if (int(sqlite3CtypeMap[u8(z[0])]) & 1) {
		for {
			c2v_pointer_postfix(voidptr(&z), z, isize(1))
			if !(int(sqlite3CtypeMap[u8(z[0])]) & 1) {
				break
			}
		}
		unsafe { goto start_of_text
		 }
	} else {
		s = U64(0)
	}
	if int((unsafe { *z })) == `.` {
		c2v_pointer_postfix(voidptr(&z), z, isize(1))
		if (int(sqlite3CtypeMap[u8(z[0])]) & 4) {
			m_state |= 1
			for {
				if s < ((U64(u32(4294967295)) | ((U64(u32(4294967295))) << 32)) - U64(9)) / U64(10) {
					s = s * U64(10) + U64(z[0]) - U64(`0`)
					d--
				} else {
					m_state = 11
				}
				if !(int(sqlite3CtypeMap[u8((unsafe { *c2v_pointer_prefix(voidptr(&z), z, isize(1)) }))]) & 4) {
					break
				}
			}
		} else if m_state == 0 {
			unsafe { *p_result = 0.0 }
			return 0
		}
		m_state |= 2
	} else if m_state == 0 {
		unsafe { *p_result = 0.0 }
		return 0
	}
	if int((unsafe { *z })) == `e` || int((unsafe { *z })) == `E` {
		esign := 0
		c2v_pointer_postfix(voidptr(&z), z, isize(1))
		if int((unsafe { *z })) == `-` {
			esign = -1
			c2v_pointer_postfix(voidptr(&z), z, isize(1))
		} else {
			esign = 1
			if int((unsafe { *z })) == `+` {
				c2v_pointer_postfix(voidptr(&z), z, isize(1))
			}
		}
		v = u32(z[0]) - u32(`0`)
		if v < u32(10) {
			exp := int(v)
			c2v_pointer_postfix(voidptr(&z), z, isize(1))
			m_state |= 2
			for {
				v = u32(z[0]) - u32(`0`)
				if !(v < u32(10)) {
					break
				}
				exp = int(if exp < 10000 { (u32(exp * 10) + v) } else { u32(10000) })
				c2v_pointer_postfix(voidptr(&z), z, isize(1))
			}
			d += esign * exp
		} else {
			c2v_pointer_postfix(voidptr(&z), z, isize(-1))
		}
	}
	if s == U64(0) {
		unsafe { *p_result = 0.0 }
		m_state |= 4
	} else {
		unsafe { *p_result = sqlite3_fp10_convert2(s, d) }
	}
	if neg {
		unsafe { *p_result = -*p_result }
	}
	if int(z[0]) == 0 {
		return m_state
	}
	if (int(sqlite3CtypeMap[u8(z[0])]) & 1) {
		for {
			c2v_pointer_postfix(voidptr(&z), z, isize(1))
			if !(int(sqlite3CtypeMap[u8((unsafe { *z }))]) & 1) {
				break
			}
		}
		if int(z[0]) == 0 {
			return m_state
		}
	}
	return int(u32(4294967280) | u32(m_state))
}

union AnonStruct_37437 {
	a              [201]i8
	forceAlignment i16
}

@[c:'sqlite3Int64ToText']
fn sqlite3_int64_to_text(v I64, z_out &i8) int {
	i := 0
	x := U64(0)
	u := AnonStruct_37528{}

	if v > I64(0) {
		x = U64(v)
	} else if v == I64(0) {
		z_out[0] = i8(`0`)
		z_out[1] = i8(0)
		return 1
	} else {
		x = if (v == ((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32)))) {
			(U64(1)) << 63
		} else {
			U64(-v)
		}
	}
	i = int(sizeof([21]i8) - u64(1))
	u.a[i] = i8(0)
	for x >= U64(10) {
		kk := int((x % U64(100)) * U64(2))
		mut __c2v_lhs_tmp_58 := unsafe { &U16(voidptr((&u.a[0] + (i - 2)))) }
		unsafe { *__c2v_lhs_tmp_58 = *&U16(voidptr(&sqlite3DigitPairs.a[0] + kk)) }
		i -= 2
		x /= U64(100)
	}
	if x {
		u.a[c2v_prefix_add(unsafe { &i }, -1)] = i8(x + U64(`0`))
	}
	if v < I64(0) {
		u.a[c2v_prefix_add(unsafe { &i }, -1)] = i8(`-`)
	}
	C.memcpy(voidptr(z_out), voidptr(unsafe { &u.a[0] + i }), sizeof([21]i8) - u64(i))
	return int(sizeof([21]i8) - u64(1) - u64(i))
}

fn compare2pow63(z_num &i8, incr int) int {
	c := 0
	i := 0
	pow63 := c'922337203685477580'
	for i = 0; c == 0 && i < 18; i++ {
		c = (int(z_num[i * incr]) - int(pow63[i])) * 10
	}
	if c == 0 {
		c = int(z_num[18 * incr]) - int(`8`)
	}
	return c
}

@[c:'sqlite3Atoi64']
fn sqlite3_atoi64(z_num &i8, p_num &I64, length int, enc U8) int {
	incr := 0
	u := U64(0)
	neg := 0
	i := 0
	j := 0

	c := u32(0)
	non_num := 0
	rc := 0
	z_start := &i8(0)
	z_end := z_num + length
	if int(enc) == 1 {
		incr = 1
	} else {
		incr = 2
		length &= ~1
		for i = 3 - int(enc); i < length && int(z_num[i]) == 0; i += 2 {
		}
		non_num = i < length
		z_end = unsafe { z_num + (i ^ 1) }
		c2v_pointer_prefix(voidptr(&z_num), z_num, isize((int(enc) & 1)))
	}
	for usize(z_num) < usize(z_end) && (int(sqlite3CtypeMap[u8((unsafe { *z_num }))]) & 1) {
		c2v_pointer_prefix(voidptr(&z_num), z_num, isize(incr))
	}
	if usize(z_num) < usize(z_end) {
		if int((unsafe { *z_num })) == i8(`-`) {
			neg = 1
			c2v_pointer_prefix(voidptr(&z_num), z_num, isize(incr))
		} else if int((unsafe { *z_num })) == i8(`+`) {
			c2v_pointer_prefix(voidptr(&z_num), z_num, isize(incr))
		}
	}
	z_start = z_num
	for usize(z_num) < usize(z_end) && int(z_num[0]) == i8(`0`) {
		c2v_pointer_prefix(voidptr(&z_num), z_num, isize(incr))
	}
	for i = 0; usize(unsafe { z_num + i }) < usize(z_end) && c2v_assign[u32](unsafe { &c }, u32(u32(z_num[i]) - u32(`0`))) <= u32(9); i += incr {
		u = u * U64(10) + U64(c)
	}
	if u > U64((I64(u32(4294967295)) | ((I64(2147483647)) << 32))) {
		unsafe { *p_num = if neg {
			((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32)))
		} else {
			(I64(u32(4294967295)) | ((I64(2147483647)) << 32))
		} }
	} else if neg {
		unsafe { *p_num = -I64(u) }
	} else {
		unsafe { *p_num = I64(u) }
	}
	rc = 0
	if i == 0 && usize(z_start) == usize(z_num) {
		rc = -1
	} else if non_num {
		rc = 1
	} else if usize(unsafe { z_num + i }) < usize(z_end) {
		jj := i
		for {
			if !(int(sqlite3CtypeMap[u8(z_num[jj])]) & 1) {
				rc = 1
				break
			}
			jj += incr
			if !(usize(unsafe { z_num + jj }) < usize(z_end)) {
				break
			}
		}
	}
	if i < 19 * incr {
		return rc
	} else {
		j = if i > 19 * incr { 1 } else { compare2pow63(z_num, incr) }
		if j < 0 {
			return rc
		} else {
			unsafe { *p_num = if neg {
				((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32)))
			} else {
				(I64(u32(4294967295)) | ((I64(2147483647)) << 32))
			} }
			if j > 0 {
				return 2
			} else {
				return if neg { rc } else { 3 }
			}
		}
	}
}

@[c:'sqlite3DecOrHexToI64']
fn sqlite3_dec_or_hex_to_i64(z &i8, p_out &I64) int {
	if int(z[0]) == i8(`0`) && (int(z[1]) == i8(`x`) || int(z[1]) == i8(`X`)) {
		u := U64(0)
		i := 0
		k := 0

		for i = 2; int(z[i]) == i8(`0`); i++ {
		}
		for k = i; (int(sqlite3CtypeMap[u8(z[k])]) & 8); k++ {
			u = u * U64(16) + U64(sqlite3_hex_to_int(z[k]))
		}
		C.memcpy(voidptr(p_out), voidptr(&u), u64(8))
		if k - i > 16 {
			return 2
		}
		if int(z[k]) != 0 {
			return 1
		}
		return 0
	} else {
		n := int((u64(1073741823) & (C.strspn(z, c'+- \n\t0123456789'))))
		if z[n] {
			n++
		}
		return sqlite3_atoi64(z, p_out, n, U8(1))
	}
}

@[c:'sqlite3GetInt32']
fn sqlite3_get_int32(z_num &i8, p_value &int) int {
	v := Sqlite_int64(0)
	i := 0
	c := 0

	neg := 0
	if int(z_num[0]) == i8(`-`) {
		neg = 1
		c2v_pointer_postfix(voidptr(&z_num), z_num, isize(1))
	} else if int(z_num[0]) == i8(`+`) {
		c2v_pointer_postfix(voidptr(&z_num), z_num, isize(1))
	} else if int(z_num[0]) == i8(`0`) && (int(z_num[1]) == i8(`x`) || int(z_num[1]) == i8(`X`)) && (int(sqlite3CtypeMap[u8(z_num[2])]) & 8) {
		u := u32(0)
		c2v_pointer_prefix(voidptr(&z_num), z_num, isize(2))
		for int(z_num[0]) == i8(`0`) {
			c2v_pointer_postfix(voidptr(&z_num), z_num, isize(1))
		}
		for i = 0; i < 8 && (int(sqlite3CtypeMap[u8(z_num[i])]) & 8); i++ {
			u = u * u32(16) + u32(sqlite3_hex_to_int(z_num[i]))
		}
		if (u & u32(2147483648)) == u32(0) && (int(sqlite3CtypeMap[u8(z_num[i])]) & 8) == 0 {
			C.memcpy(voidptr(p_value), voidptr(&u), u64(4))
			return 1
		} else {
			return 0
		}
	}
	if !(int(sqlite3CtypeMap[u8(z_num[0])]) & 4) {
		return 0
	}
	for int(z_num[0]) == i8(`0`) {
		c2v_pointer_postfix(voidptr(&z_num), z_num, isize(1))
	}
	for i = 0; i < 11 && c2v_assign[int](unsafe { &c }, int(z_num[i] - int(`0`))) >= 0 && c <= 9; i++ {
		v = v * Sqlite_int64(10) + Sqlite_int64(c)
	}
	if i > 10 {
		return 0
	}
	if v - Sqlite_int64(neg) > Sqlite_int64(2147483647) {
		return 0
	}
	if neg {
		v = -v
	}
	unsafe { *p_value = int(v) }
	return 1
}

@[c:'sqlite3Atoi']
fn sqlite3_atoi(z &i8) int {
	x := 0
	sqlite3_get_int32(z, &x)
	return x
}

@[c:'sqlite3FpDecode']
fn sqlite3_fp_decode(p &FpDecode, r f64, i_round int, mx_round int) {
	i := 0
	n := 0
	v := U64(0)
	e := 0
	exp := 0

	z_buf := &i8(0)
	z := &i8(0)
	p.isSpecial = i8(0)
	if r < 0.0 {
		p.sign = i8(`-`)
		r = -r
	} else if r == 0.0 {
		p.sign = i8(`+`)
		p.n = 1
		p.iDP = 1
		p.z = c'0'
		return
	} else {
		p.sign = i8(`+`)
	}
	C.memcpy(voidptr(&v), voidptr(&r), u64(8))
	e = int((v >> 52) & U64(2047))
	if e == 2047 {
		p.isSpecial = i8(1 + int((v != U64(9218868437227405312))))
		p.n = 0
		p.iDP = 0
		p.z = unsafe { &p.zBuf[0] }
		return
	}
	v &= u64(4503599627370495)
	if e == 0 {
		nn := count_leading_zeros(v)
		v <<= nn
		e = -1074 - nn
	} else {
		v = (v << 11) | ((U64(1)) << 63)
		e -= 1086
	}
	sqlite3_fp2_convert10(v, e, if (i_round <= 0 || i_round >= 18) { 18 } else { i_round + 1 }, &v, &exp)
	z_buf = unsafe { &p.zBuf[0] }
	i = 20
	for v >= U64(10) {
		kk := int((v % U64(100)) * U64(2))
		mut __c2v_lhs_tmp_59 := unsafe { &U16(voidptr((z_buf + (i - 2)))) }
		unsafe { *__c2v_lhs_tmp_59 = *&U16(voidptr(&sqlite3DigitPairs.a[0] + kk)) }
		i -= 2
		v /= U64(100)
	}
	if v {
		z_buf[c2v_prefix_add(unsafe { &i }, -1)] = i8(v + U64(`0`))
	}
	n = 20 - i
	p.iDP = n + exp
	if i_round <= 0 {
		i_round = p.iDP - i_round
		if i_round == 0 && int(z_buf[i]) >= i8(`5`) {
			i_round = 1
			z_buf[c2v_prefix_add(unsafe { &i }, -1)] = i8(`0`)
			n++
			p.iDP++
		}
	}
	z = unsafe { z_buf + i }
	if i_round > 0 && (i_round < n || n > mx_round) {
		if i_round > mx_round {
			i_round = mx_round
		}
		if i_round == 17 {
			if int(z[15]) == i8(`9`) && int(z[14]) == i8(`9`) {
				jj := 0
				kk := 0

				v2 := U64(0)
				for jj = 14; jj > 0 && int(z[jj - 1]) == i8(`9`); jj-- {
				}
				if jj == 0 {
					v2 = U64(1)
				} else {
					v2 = U64(int(z[0]) - int(`0`))
					for kk = 1; kk < jj; kk++ {
						v2 = (v2 * U64(10)) + U64(z[kk]) - U64(`0`)
					}
					v2++
				}
				if r == sqlite3_fp10_convert2(v2, exp + n - jj) {
					i_round = jj + 1
				}
			} else if p.iDP >= n || (int(z[15]) == i8(`0`) && int(z[14]) == i8(`0`) && int(z[13]) == i8(`0`)) {
				jj := 0
				kk := 0

				v2 := U64(0)
				for jj = 13; int(z[jj - 1]) == i8(`0`); jj-- {
				}
				v2 = U64(int(z[0]) - int(`0`))
				for kk = 1; kk < jj; kk++ {
					v2 = (v2 * U64(10)) + U64(z[kk]) - U64(`0`)
				}
				if r == sqlite3_fp10_convert2(v2, exp + n - jj) {
					i_round = jj + 1
				}
			}
		}
		n = i_round
		if int(z[i_round]) >= i8(`5`) {
			j := i_round - 1
			for {
				z[j]++
				if int(z[j]) <= i8(`9`) {
					break
				}
				z[j] = i8(`0`)
				if j == 0 {
					c2v_pointer_postfix(voidptr(&z), z, isize(-1))
					z[0] = i8(`1`)
					n++
					p.iDP++
					break
				} else {
					j--
				}
			}
		}
	}
	for int(z[n - 1]) == i8(`0`) {
		n--
	}
	p.n = n
	p.z = z
}

@[c:'sqlite3GetUInt32']
fn sqlite3_get_ui_nt32(z &i8, pi &u32) int {
	v := U64(0)
	i := 0
	for i = 0; (int(sqlite3CtypeMap[u8(z[i])]) & 4); i++ {
		v = v * U64(10) + U64(z[i]) - U64(`0`)
		if v > U64(4294967296) {
			unsafe { *pi = u32(0) }
			return 0
		}
	}
	if i == 0 || int(z[i]) != 0 {
		unsafe { *pi = u32(0) }
		return 0
	}
	unsafe { *pi = u32(v) }
	return 1
}

@[c:'putVarint64']
fn put_varint64(p &u8, v U64) int {
	i := 0
	j := 0
	n := 0

	buf := [10]U8{}
	if v & ((U64(u32(4278190080))) << 32) {
		p[8] = U8(v)
		v >>= 8
		for i = 7; i >= 0; i-- {
			p[i] = U8(((v & U64(127)) | U64(128)))
			v >>= 7
		}
		return 9
	}
	n = 0
	for {
		buf[n++] = U8(((v & U64(127)) | U64(128)))
		v >>= 7
		if !(v != U64(0)) {
			break
		}
	}
	buf[0] &= 127
	i = 0
	for j = n - 1; j >= 0; j-- {
		p[i] = buf[j]
		i++
	}
	return n
}

@[c:'sqlite3PutVarint']
fn sqlite3_put_varint(p &u8, v U64) int {
	if v <= U64(127) {
		p[0] = u8(v & U64(127))
		return 1
	}
	if v <= U64(16383) {
		p[0] = u8(((v >> 7) & U64(127)) | U64(128))
		p[1] = u8(v & U64(127))
		return 2
	}
	return put_varint64(p, v)
}

@[c:'sqlite3GetVarint']
fn sqlite3_get_varint(p &u8, v &U64) U8 {
	a := u32(0)
	b := u32(0)
	s := u32(0)

	if int((&i8(voidptr(p)))[0]) >= 0 {
		unsafe { *v = *p }
		return U8(1)
	}
	if int((&i8(voidptr(p)))[1]) >= 0 {
		unsafe { *v = U64((u32((int(p[0]) & 127)) << 7) | u32(p[1])) }
		return U8(2)
	}
	a = (u32(p[0])) << 14
	b = u32(p[1])
	c2v_pointer_prefix(voidptr(&p), p, isize(2))
	a |= u32((unsafe { *p }))
	if !(a & u32(128)) {
		a &= u32(2080895)
		b &= u32(127)
		b = b << 7
		a |= b
		unsafe { *v = U64(a) }
		return U8(3)
	}
	a &= u32(2080895)
	c2v_pointer_postfix(voidptr(&p), p, isize(1))
	b = b << 14
	b |= u32((unsafe { *p }))
	if !(b & u32(128)) {
		b &= u32(2080895)
		a = a << 7
		a |= b
		unsafe { *v = U64(a) }
		return U8(4)
	}
	b &= u32(2080895)
	s = a
	c2v_pointer_postfix(voidptr(&p), p, isize(1))
	a = a << 14
	a |= u32((unsafe { *p }))
	if !(a & u32(128)) {
		b = b << 7
		a |= b
		s = s >> 18
		unsafe { *v = (U64(s)) << 32 | U64(a) }
		return U8(5)
	}
	s = s << 7
	s |= b
	c2v_pointer_postfix(voidptr(&p), p, isize(1))
	b = b << 14
	b |= u32((unsafe { *p }))
	if !(b & u32(128)) {
		a &= u32(2080895)
		a = a << 7
		a |= b
		s = s >> 18
		unsafe { *v = (U64(s)) << 32 | U64(a) }
		return U8(6)
	}
	c2v_pointer_postfix(voidptr(&p), p, isize(1))
	a = a << 14
	a |= u32((unsafe { *p }))
	if !(a & u32(128)) {
		a &= u32(4028612735)
		b &= u32(2080895)
		b = b << 7
		a |= b
		s = s >> 11
		unsafe { *v = (U64(s)) << 32 | U64(a) }
		return U8(7)
	}
	a &= u32(2080895)
	c2v_pointer_postfix(voidptr(&p), p, isize(1))
	b = b << 14
	b |= u32((unsafe { *p }))
	if !(b & u32(128)) {
		b &= u32(4028612735)
		a = a << 7
		a |= b
		s = s >> 4
		unsafe { *v = (U64(s)) << 32 | U64(a) }
		return U8(8)
	}
	c2v_pointer_postfix(voidptr(&p), p, isize(1))
	a = a << 15
	a |= u32((unsafe { *p }))
	b &= u32(2080895)
	b = b << 8
	a |= b
	s = s << 4
	b = u32(p[-4])
	b &= u32(127)
	b = b >> 3
	s |= b
	unsafe { *v = (U64(s)) << 32 | U64(a) }
	return U8(9)
}

@[c:'sqlite3GetVarint32']
fn sqlite3_get_varint32(p &u8, v &u32) U8 {
	v64 := U64(0)
	n := U8(0)
	if (int(p[1]) & 128) == 0 {
		unsafe { *v = u32(((int(p[0]) & 127) << 7) | int(p[1])) }
		return U8(2)
	}
	if (int(p[2]) & 128) == 0 {
		unsafe { *v = u32(((int(p[0]) & 127) << 14) | ((int(p[1]) & 127) << 7) | int(p[2])) }
		return U8(3)
	}
	n = sqlite3_get_varint(p, &v64)
	if (v64 & (((U64(1)) << 32) - U64(1))) != v64 {
		unsafe { *v = u32(4294967295) }
	} else {
		unsafe { *v = u32(v64) }
	}
	return n
}

@[c:'sqlite3VarintLen']
fn sqlite3_varint_len(v U64) int {
	i := 0
	for i = 1; true; i++ {
		v >>= 7
		if !(v != U64(0)) {
			break
		}
	}
	return i
}

@[c:'sqlite3Get4byte']
fn sqlite3_get4byte(p &U8) u32 {
	return (u32(p[0]) << 24) | u32((int(p[1]) << 16)) | u32((int(p[2]) << 8)) | u32(p[3])
}

@[c:'sqlite3Put4byte']
fn sqlite3_put4byte(p &u8, v u32) {
	p[0] = U8((v >> 24))
	p[1] = U8((v >> 16))
	p[2] = U8((v >> 8))
	p[3] = U8(v)
}

@[c:'sqlite3HexToInt']
fn sqlite3_hex_to_int(h int) U8 {
	h += 9 * (1 & (h >> 6))
	return U8((h & 15))
}

@[c:'sqlite3HexToBlob']
fn sqlite3_hex_to_blob(db &Sqlite3, z &i8, n int) voidptr {
	z_blob := &i8(0)
	i := 0
	z_blob = &i8(sqlite3_db_malloc_raw_nn(db, U64(n / 2 + 1)))
	n--
	if z_blob {
		for i = 0; i < n; i += 2 {
			z_blob[i / 2] = i8((int(sqlite3_hex_to_int(z[i])) << 4) | int(sqlite3_hex_to_int(z[i + 1])))
		}
		z_blob[i / 2] = i8(0)
	}
	return z_blob
}

@[c:'logBadConnection']
fn log_bad_connection(z_type &i8) {
	sqlite3_log(21, c'API call with %s database connection pointer', voidptr(z_type))
}

@[c:'sqlite3SafetyCheckOk']
fn sqlite3_safety_check_ok(db &Sqlite3) int {
	e_open_state := U8(0)
	if usize(db) == usize(0) {
		log_bad_connection(c'NULL')
		return 0
	}
	e_open_state = db.eOpenState
	if int(e_open_state) != 118 {
		if sqlite3_safety_check_sick_or_ok(db) {
			log_bad_connection(c'unopened')
		}
		return 0
	} else {
		return 1
	}
}

@[c:'sqlite3SafetyCheckSickOrOk']
fn sqlite3_safety_check_sick_or_ok(db &Sqlite3) int {
	e_open_state := U8(0)
	e_open_state = db.eOpenState
	if int(e_open_state) != 186 && int(e_open_state) != 118 && int(e_open_state) != 109 {
		log_bad_connection(c'invalid')
		return 0
	} else {
		return 1
	}
}

@[c:'sqlite3AddInt64']
fn sqlite3_add_int64(pa &I64, ib I64) int {
	ia := (unsafe { *pa })
	if ib >= I64(0) {
		if ia > I64(0) && (I64(u32(4294967295)) | ((I64(2147483647)) << 32)) - ia < ib {
			return 1
		}
	} else {
		if ia < I64(0) && -(ia + (I64(u32(4294967295)) | ((I64(2147483647)) << 32))) > ib + I64(1) {
			return 1
		}
	}
	unsafe { *pa += ib }
	return 0
}

@[c:'sqlite3SubInt64']
fn sqlite3_sub_int64(pa &I64, ib I64) int {
	if ib == ((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32))) {
		if (unsafe { *pa }) >= I64(0) {
			return 1
		}
		unsafe { *pa -= ib }
		return 0
	} else {
		return sqlite3_add_int64(pa, -ib)
	}
}

@[c:'sqlite3MulInt64']
fn sqlite3_mul_int64(pa &I64, ib I64) int {
	ia := (unsafe { *pa })
	if ib > I64(0) {
		if ia > (I64(u32(4294967295)) | ((I64(2147483647)) << 32)) / ib {
			return 1
		}
		if ia < ((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32))) / ib {
			return 1
		}
	} else if ib < I64(0) {
		if ia > I64(0) {
			if ib < ((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32))) / ia {
				return 1
			}
		} else if ia < I64(0) {
			if ib == ((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32))) {
				return 1
			}
			if ia == ((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32))) {
				return 1
			}
			if -ia > (I64(u32(4294967295)) | ((I64(2147483647)) << 32)) / -ib {
				return 1
			}
		}
	}
	unsafe { *pa = ia * ib }
	return 0
}

@[c:'sqlite3AbsInt32']
fn sqlite3_abs_int32(x int) int {
	if x >= 0 {
		return x
	}
	if x == int(u32(2147483648)) {
		return 2147483647
	}
	return -x
}

@[c:'sqlite3LogEstAdd']
fn sqlite3_log_est_add(a LogEst, b LogEst) LogEst {
	if !sqlite3_log_est_add_x_inited {
		c2v_static_init := [u8(10), u8(10), u8(9), u8(9), u8(8), u8(8), u8(7), u8(7), u8(7), u8(6),
			u8(6), u8(6), u8(5), u8(5), u8(5), u8(4), u8(4), u8(4), u8(4), u8(3), u8(3), u8(3),
			u8(3), u8(3), u8(3), u8(2), u8(2), u8(2), u8(2), u8(2), u8(2), u8(2)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_log_est_add_x[c2v_i_0] = c2v_element_0
		}
		sqlite3_log_est_add_x_inited = true
	}

	if int(a) >= int(b) {
		if int(a) > int(b) + 49 {
			return a
		}
		if int(a) > int(b) + 31 {
			return LogEst(int(a) + 1)
		}
		return LogEst(int(a) + int(sqlite3_log_est_add_x[int(a) - int(b)]))
	} else {
		if int(b) > int(a) + 49 {
			return b
		}
		if int(b) > int(a) + 31 {
			return LogEst(int(b) + 1)
		}
		return LogEst(int(b) + int(sqlite3_log_est_add_x[int(b) - int(a)]))
	}
}

@[c:'sqlite3LogEst']
fn sqlite3_log_est(x U64) LogEst {
	if !sqlite3_log_est_a_inited {
		c2v_static_init := [LogEst(0), LogEst(2), LogEst(3), LogEst(5), LogEst(6), LogEst(7),
			LogEst(8), LogEst(9)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_log_est_a[c2v_i_0] = c2v_element_0
		}
		sqlite3_log_est_a_inited = true
	}

	y := LogEst(40)
	if x < U64(8) {
		if x < U64(2) {
			return LogEst(0)
		}
		for x < U64(8) {
			y -= 10
			x <<= 1
		}
	} else {
		for x > U64(255) {
			y += 40
			x >>= 4
		}
		for x > U64(15) {
			y += 10
			x >>= 1
		}
	}
	return LogEst(int(sqlite3_log_est_a[x & U64(7)]) + int(y) - 10)
}

@[c:'sqlite3LogEstFromDouble']
fn sqlite3_log_est_from_double(x f64) LogEst {
	a := U64(0)
	e := LogEst(0)
	if x <= f64(1) {
		return LogEst(0)
	}
	if x <= f64(2000000000) {
		return sqlite3_log_est(U64(x))
	}
	C.memcpy(voidptr(&a), voidptr(&x), u64(8))
	e = LogEst((a >> 52) - U64(1022))
	return LogEst(int(e) * 10)
}

@[c:'sqlite3LogEstToInt']
fn sqlite3_log_est_to_int(x LogEst) U64 {
	n := U64(0)
	n = U64(int(x) % 10)
	x /= 10
	if n >= U64(5) {
		n -= U64(2)
	} else if n >= U64(1) {
		n -= U64(1)
	}
	if int(x) > 60 {
		return U64((I64(u32(4294967295)) | ((I64(2147483647)) << 32)))
	}
	return if int(x) >= 3 { (n + U64(8)) << (int(x) - 3) } else { (n + U64(8)) >> (3 - int(x)) }
}

@[c:'sqlite3VListAdd']
fn sqlite3_vl_ist_add(db &Sqlite3, p_in &VList, z_name &i8, n_name int, i_val int) &VList {
	n_int := 0
	z := &i8(0)
	i := 0
	n_int = n_name / 4 + 3
	if usize(p_in) == usize(0) || p_in[1] + n_int > p_in[0] {
		n_alloc := (if p_in { Sqlite3_int64(2) * Sqlite3_int64(p_in[0]) } else { Sqlite3_int64(10) }) + Sqlite3_int64(n_int)
		p_out := &VList(sqlite3_db_realloc(db, voidptr(p_in), u64(n_alloc) * sizeof(int)))
		if usize(p_out) == usize(0) {
			return p_in
		}
		if usize(p_in) == usize(0) {
			p_out[1] = 2
		}
		p_in = p_out
		p_in[0] = VList(n_alloc)
	}
	i = p_in[1]
	p_in[i] = i_val
	p_in[i + 1] = n_int
	z = &i8(voidptr(unsafe { p_in + (i + 2) }))
	p_in[1] = i + n_int
	C.memcpy(voidptr(z), voidptr(z_name), u64(n_name))
	z[n_name] = i8(0)
	return p_in
}

@[c:'sqlite3VListNumToName']
fn sqlite3_vl_ist_num_to_name(p_in &VList, i_val int) &i8 {
	i := 0
	mx := 0

	if usize(p_in) == usize(0) {
		return unsafe { nil }
	}
	mx = p_in[1]
	i = 2
	for {
		if p_in[i] == i_val {
			return &i8(voidptr(unsafe { p_in + (i + 2) }))
		}
		i += p_in[i + 1]
		if !(i < mx) {
			break
		}
	}
	return unsafe { nil }
}

@[c:'sqlite3VListNameToNum']
fn sqlite3_vl_ist_name_to_num(p_in &VList, z_name &i8, n_name int) int {
	i := 0
	mx := 0

	if usize(p_in) == usize(0) {
		return 0
	}
	mx = p_in[1]
	i = 2
	for {
		z := &i8(voidptr(unsafe { p_in + (i + 2) }))
		if C.strncmp(z, z_name, u64(n_name)) == 0 && int(z[n_name]) == 0 {
			return p_in[i]
		}
		i += p_in[i + 1]
		if !(i < mx) {
			break
		}
	}
	return 0
}
