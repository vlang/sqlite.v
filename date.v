@[translated]
module main

struct DateTime {
	iJD       Sqlite3_int64
	y         int
	m_        int
	d         int
	h         int
	m         int
	tz        int
	s         f64
	validJD   i8
	validYMD  i8
	validHMS  i8
	nFloor    i8
	rawS      u32
	isError   u32
	useSubsec u32
	isUtc     u32
	isLocal   u32
}

@[c:'getDigits']
@[c2v_variadic]
fn get_digits(z_date &i8, z_format &i8, ...) int {
	if !get_digits_a_mx_inited {
		c2v_static_init := [U16(12), U16(14), U16(24), U16(31), U16(59), U16(14712)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			get_digits_a_mx[c2v_i_0] = c2v_element_0
		}
		get_digits_a_mx_inited = true
	}

	ap := C.va_list{}
	cnt := 0
	next_c := i8(0)
	C.va_start(ap, z_format)
	for {
		n := i8(int(z_format[0]) - int(`0`))
		min := i8(int(z_format[1]) - int(`0`))
		val := 0
		max := U16(0)
		max = get_digits_a_mx[int(z_format[2]) - int(`a`)]
		next_c = z_format[3]
		val = 0
		for n-- {
			if !(int(sqlite3CtypeMap[u8((unsafe { *z_date }))]) & 4) {
				unsafe { goto end_getDigits
				 }
			}
			val = val * 10 + int((unsafe { *z_date })) - int(`0`)
			c2v_pointer_postfix(voidptr(&z_date), z_date, isize(1))
		}
		if val < int(min) || val > int(max) || (int(next_c) != 0 && int(next_c) != int((unsafe { *z_date }))) {
			unsafe { goto end_getDigits
			 }
		}
		mut __c2v_lhs_tmp_2 := unsafe { C.va_arg(&int, ap) }
		unsafe { *__c2v_lhs_tmp_2 = val }
		c2v_pointer_postfix(voidptr(&z_date), z_date, isize(1))
		cnt++
		c2v_pointer_prefix(voidptr(&z_format), z_format, isize(4))
		if !next_c {
			break
		}
	}
	end_getDigits:
	C.va_end(ap)
	return cnt
}

@[c:'parseTimezone']
fn parse_timezone(z_date &i8, p &DateTime) int {
	sgn := 0
	n_hr := 0
	n_mn := 0

	c := 0
	for (int(sqlite3CtypeMap[u8((unsafe { *z_date }))]) & 1) {
		c2v_pointer_postfix(voidptr(&z_date), z_date, isize(1))
	}
	p.tz = 0
	c = unsafe { *z_date }
	if c == `-` {
		sgn = -1
	} else if c == `+` {
		sgn = 1
	} else if c == `Z` || c == `z` {
		c2v_pointer_postfix(voidptr(&z_date), z_date, isize(1))
		p.isLocal = u32(0)
		p.isUtc = u32(1)
		unsafe { goto zulu_time
		 }
	} else {
		return int(c != 0)
	}
	c2v_pointer_postfix(voidptr(&z_date), z_date, isize(1))
	if get_digits(z_date, c'20b:20e', voidptr(&n_hr), voidptr(&n_mn)) != 2 {
		return 1
	}
	c2v_pointer_prefix(voidptr(&z_date), z_date, isize(5))
	p.tz = sgn * (n_mn + n_hr * 60)
	if p.tz == 0 {
		p.isLocal = u32(0)
		p.isUtc = u32(1)
	}
	zulu_time: for (int(sqlite3CtypeMap[u8((unsafe { *z_date }))]) & 1) {
		c2v_pointer_postfix(voidptr(&z_date), z_date, isize(1))
	}
	return int((unsafe { *z_date }) != 0)
}

@[c:'parseHhMmSs']
fn parse_hh_mm_ss(z_date &i8, p &DateTime) int {
	h := 0
	m := 0
	s := 0

	ms := 0.0
	if get_digits(z_date, c'20c:20e', voidptr(&h), voidptr(&m)) != 2 {
		return 1
	}
	c2v_pointer_prefix(voidptr(&z_date), z_date, isize(5))
	if int((unsafe { *z_date })) == i8(`:`) {
		c2v_pointer_postfix(voidptr(&z_date), z_date, isize(1))
		if get_digits(z_date, c'20e', voidptr(&s)) != 1 {
			return 1
		}
		c2v_pointer_prefix(voidptr(&z_date), z_date, isize(2))
		if int((unsafe { *z_date })) == i8(`.`) && (int(sqlite3CtypeMap[u8(z_date[1])]) & 4) {
			r_scale := 1.0
			c2v_pointer_postfix(voidptr(&z_date), z_date, isize(1))
			for (int(sqlite3CtypeMap[u8((unsafe { *z_date }))]) & 4) {
				ms = ms * 10.0 + f64(int((unsafe { *z_date }))) - f64(`0`)
				r_scale *= 10.0
				c2v_pointer_postfix(voidptr(&z_date), z_date, isize(1))
			}
			ms /= r_scale
			if ms > 0.99899999999999999 {
				ms = 0.99899999999999999
			}
		}
	} else {
		s = 0
	}
	p.validJD = i8(0)
	p.rawS = u32(0)
	p.validHMS = i8(1)
	p.h = h
	p.m = m
	p.s = f64(s) + ms
	if parse_timezone(z_date, p) {
		return 1
	}
	return 0
}

@[c:'datetimeError']
fn datetime_error(p &DateTime) {
	C.memset(voidptr(p), 0, sizeof(DateTime))
	p.isError = u32(1)
}

@[c:'computeJD']
fn compute_jd(p &DateTime) {
	y := 0
	m := 0
	d := 0
	a := 0
	b := 0
	x1 := 0
	x2 := 0

	if p.validJD {
		return
	}
	if p.validYMD {
		y = p.y
		m = p.m_
		d = p.d
	} else {
		y = 2000
		m = 1
		d = 1
	}
	if y < -4713 || y > 9999 || int(p.rawS) {
		datetime_error(p)
		return
	}
	if m <= 2 {
		y--
		m += 12
	}
	a = (y + 4800) / 100
	b = 38 - a + (a / 4)
	x1 = 36525 * (y + 4716) / 100
	x2 = 306001 * (m + 1) / 10000
	p.iJD = Sqlite3_int64(((f64(x1 + x2 + d + b) - 1524.5) * f64(86400000)))
	p.validJD = i8(1)
	if p.validHMS {
		p.iJD += Sqlite3_int64(p.h * 3600000 + p.m * 60000) + Sqlite3_int64((p.s * f64(1000) + 0.5))
		if p.tz {
			p.iJD -= Sqlite3_int64(p.tz * 60000)
			p.validYMD = i8(0)
			p.validHMS = i8(0)
			p.tz = 0
			p.isUtc = u32(1)
			p.isLocal = u32(0)
		}
	}
}

@[c:'computeFloor']
fn compute_floor(p &DateTime) {
	if p.d <= 28 {
		p.nFloor = i8(0)
	} else if (1 << p.m_) & 5546 {
		p.nFloor = i8(0)
	} else if p.m_ != 2 {
		p.nFloor = i8((p.d == 31))
	} else if p.y % 4 != 0 || (p.y % 100 == 0 && p.y % 400 != 0) {
		p.nFloor = i8(p.d - 28)
	} else {
		p.nFloor = i8(p.d - 29)
	}
}

@[c:'parseYyyyMmDd']
fn parse_yyyy_mm_dd(z_date &i8, p &DateTime) int {
	y := 0
	m := 0
	d := 0
	neg := 0

	if int(z_date[0]) == i8(`-`) {
		c2v_pointer_postfix(voidptr(&z_date), z_date, isize(1))
		neg = 1
	} else {
		neg = 0
	}
	if get_digits(z_date, c'40f-21a-21d', voidptr(&y), voidptr(&m), voidptr(&d)) != 3 {
		return 1
	}
	c2v_pointer_prefix(voidptr(&z_date), z_date, isize(10))
	for (int(sqlite3CtypeMap[u8((unsafe { *z_date }))]) & 1) || `T` == int((unsafe { *&U8(voidptr(z_date)) })) {
		c2v_pointer_postfix(voidptr(&z_date), z_date, isize(1))
	}
	if parse_hh_mm_ss(z_date, p) == 0 {
	} else if int((unsafe { *z_date })) == 0 {
		p.validHMS = i8(0)
	} else {
		return 1
	}
	p.validJD = i8(0)
	p.validYMD = i8(1)
	p.y = if neg { -y } else { y }
	p.m_ = m
	p.d = d
	compute_floor(p)
	if p.tz {
		compute_jd(p)
	}
	return 0
}

@[c:'setDateTimeToCurrent']
fn set_date_time_to_current(context &Sqlite3_context, p &DateTime) int {
	p.iJD = sqlite3_stmt_current_time(context)
	if p.iJD > Sqlite3_int64(0) {
		p.validJD = i8(1)
		p.isUtc = u32(1)
		p.isLocal = u32(0)
		clear_ymd_hms_tz(p)
		return 0
	} else {
		return 1
	}
}

@[c:'setRawDateNumber']
fn set_raw_date_number(p &DateTime, r f64) {
	p.s = r
	p.rawS = u32(1)
	if r >= 0.0 && r < 5373484.5 {
		p.iJD = Sqlite3_int64((r * 8.64E+7 + 0.5))
		p.validJD = i8(1)
	}
}

@[c:'parseDateOrTime']
fn parse_date_or_time(context &Sqlite3_context, z_date &i8, p &DateTime) int {
	r := 0.0
	if parse_yyyy_mm_dd(z_date, p) == 0 {
		return 0
	} else if parse_hh_mm_ss(z_date, p) == 0 {
		return 0
	} else if sqlite3_str_ic_mp(z_date, c'now') == 0 && sqlite3_not_pure_func(context) {
		return set_date_time_to_current(context, p)
	} else if sqlite3_ato_f(z_date, &r) > 0 {
		set_raw_date_number(p, r)
		return 0
	} else if (sqlite3_str_ic_mp(z_date, c'subsec') == 0 || sqlite3_str_ic_mp(z_date, c'subsecond') == 0) && sqlite3_not_pure_func(context) {
		p.useSubsec = u32(1)
		return set_date_time_to_current(context, p)
	}
	return 1
}

@[c:'validJulianDay']
fn valid_julian_day(ijd Sqlite3_int64) int {
	return int(ijd >= Sqlite3_int64(0) && ijd <= (((I64(108096)) << 32) | I64(275971583)))
}

@[c:'computeYMD']
fn compute_ymd(p &DateTime) {
	z := 0
	alpha := 0
	a := 0
	b := 0
	c := 0
	d := 0
	e := 0
	x1 := 0

	if p.validYMD {
		return
	}
	if !p.validJD {
		p.y = 2000
		p.m_ = 1
		p.d = 1
	} else if !valid_julian_day(p.iJD) {
		datetime_error(p)
		return
	} else {
		z = int(((p.iJD + Sqlite3_int64(43200000)) / Sqlite3_int64(86400000)))
		alpha = int(((f64(z) + 32044.75) / 36524.25)) - 52
		a = z + 1 + alpha - ((alpha + 100) / 4) + 25
		b = a + 1524
		c = int(((f64(b) - 122.09999999999999) / 365.25))
		d = (36525 * (c & 32767)) / 100
		e = int((f64((b - d)) / 30.600100000000001))
		x1 = int((30.600100000000001 * f64(e)))
		p.d = b - d - x1
		p.m_ = if e < 14 { e - 1 } else { e - 13 }
		p.y = if p.m_ > 2 { c - 4716 } else { c - 4715 }
	}
	p.validYMD = i8(1)
}

@[c:'computeHMS']
fn compute_hms(p &DateTime) {
	day_ms := 0
	day_min := 0

	if p.validHMS {
		return
	}
	compute_jd(p)
	day_ms = int(((p.iJD + Sqlite3_int64(43200000)) % Sqlite3_int64(86400000)))
	p.s = f64((day_ms % 60000)) / 1000.0
	day_min = day_ms / 60000
	p.m = day_min % 60
	p.h = day_min / 60
	p.rawS = u32(0)
	p.validHMS = i8(1)
}

@[c:'computeYMD_HMS']
fn compute_ymd_hms(p &DateTime) {
	compute_ymd(p)
	compute_hms(p)
}

@[c:'clearYMD_HMS_TZ']
fn clear_ymd_hms_tz(p &DateTime) {
	p.validYMD = i8(0)
	p.validHMS = i8(0)
	p.tz = 0
}

@[c:'osLocaltime']
fn os_localtime(t &i64, p_tm &C.tm) int {
	rc := 0
	px := &C.tm(0)
	mutex := sqlite3_mutex_alloc_vdup4(2)
	sqlite3_mutex_enter(mutex)
	px = C.localtime(t)
	if sqlite3Config.bLocaltimeFault {
		if !isnil(sqlite3Config.xAltLocaltime) && 0 == sqlite3Config.xAltLocaltime(voidptr(t), voidptr(p_tm)) {
			px = p_tm
		} else {
			px = 0
		}
	}
	if px {
		unsafe { *p_tm = *px }
	}
	sqlite3_mutex_leave(mutex)
	rc = usize(px) == usize(0)
	return rc
}

@[c:'toLocaltime']
fn to_localtime(p &DateTime, p_ctx &Sqlite3_context) int {
	t := i64(0)
	s_local := C.tm{}
	i_year_diff := 0
	C.memset(voidptr(&s_local), 0, sizeof(s_local))
	compute_jd(p)
	if p.iJD < I64(2108667600) * I64(100000) || p.iJD > I64(2130141456) * I64(100000) {
		x := (unsafe { *p })
		compute_ymd_hms(&x)
		i_year_diff = (2000 + x.y % 4) - x.y
		x.y += i_year_diff
		x.validJD = i8(0)
		compute_jd(&x)
		t = i64((x.iJD / Sqlite3_int64(1000) - I64(21086676) * I64(10000)))
	} else {
		i_year_diff = 0
		t = i64((p.iJD / Sqlite3_int64(1000) - I64(21086676) * I64(10000)))
	}
	if os_localtime(&t, &s_local) {
		sqlite3_result_error(p_ctx, c'local time unavailable', -1)
		return 1
	}
	p.y = s_local.tm_year + 1900 - i_year_diff
	p.m_ = s_local.tm_mon + 1
	p.d = s_local.tm_mday
	p.h = s_local.tm_hour
	p.m = s_local.tm_min
	p.s = f64(s_local.tm_sec) + f64((p.iJD % Sqlite3_int64(1000))) * 0.001
	p.validYMD = i8(1)
	p.validHMS = i8(1)
	p.validJD = i8(0)
	p.rawS = u32(0)
	p.tz = 0
	p.isError = u32(0)
	return 0
}

struct AnonStruct_26163 {
	nName  U8
	zName  [7]i8
	rLimit f32
	rXform f32
}

@[c:'autoAdjustDate']
fn auto_adjust_date(p &DateTime) {
	if !p.rawS || int(p.validJD) {
		p.rawS = u32(0)
	} else if p.s >= f64(I64(-21086676) * I64(10000)) && p.s <= f64((I64(25340230) * I64(10000)) + I64(799)) {
		r := p.s * 1000.0 + 2.1086676E+14
		clear_ymd_hms_tz(p)
		p.iJD = Sqlite3_int64((r + 0.5))
		p.validJD = i8(1)
		p.rawS = u32(0)
	}
}

@[c:'parseModifier']
fn parse_modifier(p_ctx &Sqlite3_context, z &i8, n int, p &DateTime, idx int) int {
	rc := 1
	r := 0.0
	match int(sqlite3UpperToLower[U8(z[0])]) {
		int(`a`) {
			if sqlite3_stricmp(z, c'auto') == 0 {
				if idx > 1 {
					return 1
				}
				auto_adjust_date(p)
				rc = 0
			}
		}
		int(`c`) {
			if sqlite3_stricmp(z, c'ceiling') == 0 {
				compute_jd(p)
				clear_ymd_hms_tz(p)
				rc = 0
				p.nFloor = i8(0)
			}
		}
		int(`f`) {
			if sqlite3_stricmp(z, c'floor') == 0 {
				compute_jd(p)
				p.iJD -= Sqlite3_int64(int(p.nFloor) * 86400000)
				clear_ymd_hms_tz(p)
				rc = 0
			}
		}
		int(`j`) {
			if sqlite3_stricmp(z, c'julianday') == 0 {
				if idx > 1 {
					return 1
				}
				if int(p.validJD) && int(p.rawS) {
					rc = 0
					p.rawS = u32(0)
				}
			}
		}
		int(`l`) {
			if sqlite3_stricmp(z, c'localtime') == 0 && sqlite3_not_pure_func(p_ctx) {
				rc = if int(p.isLocal) { 0 } else { to_localtime(p, p_ctx) }
				p.isUtc = u32(0)
				p.isLocal = u32(1)
			}
		}
		int(`u`) {
			if sqlite3_stricmp(z, c'unixepoch') == 0 && int(p.rawS) {
				if idx > 1 {
					return 1
				}
				r = p.s * 1000.0 + 2.1086676E+14
				if r >= 0.0 && r < 4.642690608E+14 {
					clear_ymd_hms_tz(p)
					p.iJD = Sqlite3_int64((r + 0.5))
					p.validJD = i8(1)
					p.rawS = u32(0)
					rc = 0
				}
			} else if sqlite3_stricmp(z, c'utc') == 0 && sqlite3_not_pure_func(p_ctx) {
				if int(p.isUtc) == 0 {
					i_orig_jd := I64(0)
					i_guess := I64(0)
					cnt := 0
					i_err := I64(0)
					compute_jd(p)
					i_orig_jd = p.iJD
					i_guess = i_orig_jd
					i_err = I64(0)
					for {
						new := DateTime{}
						C.memset(voidptr(&new), 0, sizeof(new))
						i_guess -= i_err
						new.iJD = i_guess
						new.validJD = i8(1)
						rc = to_localtime(&new, p_ctx)
						if rc {
							return rc
						}
						compute_jd(&new)
						i_err = new.iJD - i_orig_jd
						if !(i_err && cnt++ < 3) {
							break
						}
					}
					C.memset(voidptr(p), 0, sizeof(DateTime))
					p.iJD = i_guess
					p.validJD = i8(1)
					p.isUtc = u32(1)
					p.isLocal = u32(0)
				}
				rc = 0
			}
		}
		int(`w`) {
			if sqlite3_strnicmp(z, c'weekday ', 8) == 0 && sqlite3_ato_f(unsafe { z + 8 }, &r) > 0 && r >= 0.0 && r < 7.0 && f64(c2v_assign[int](unsafe { &n }, int(int(r)))) == r {
				z_2 := Sqlite3_int64(0)
				compute_ymd_hms(p)
				p.tz = 0
				p.validJD = i8(0)
				compute_jd(p)
				z_2 = ((p.iJD + Sqlite3_int64(129600000)) / Sqlite3_int64(86400000)) % Sqlite3_int64(7)
				if z_2 > Sqlite3_int64(n) {
					z_2 -= Sqlite3_int64(7)
				}
				p.iJD += (Sqlite3_int64(n) - z_2) * Sqlite3_int64(86400000)
				clear_ymd_hms_tz(p)
				rc = 0
			}
		}
		int(`s`) {
			if sqlite3_strnicmp(z, c'start of ', 9) != 0 {
				if sqlite3_stricmp(z, c'subsec') == 0 || sqlite3_stricmp(z, c'subsecond') == 0 {
					p.useSubsec = u32(1)
					rc = 0
				}
				unsafe { goto c2v_switch_end_1
				 }
			}
			if !p.validJD && !p.validYMD && !p.validHMS {
				unsafe { goto c2v_switch_end_1
				 }
			}
			c2v_pointer_prefix(voidptr(&z), z, isize(9))
			compute_ymd(p)
			p.validHMS = i8(1)
			p.m = 0
			p.h = p.m
			p.s = 0.0
			p.rawS = u32(0)
			p.tz = 0
			p.validJD = i8(0)
			if sqlite3_stricmp(z, c'month') == 0 {
				p.d = 1
				rc = 0
			} else if sqlite3_stricmp(z, c'year') == 0 {
				p.m_ = 1
				p.d = 1
				rc = 0
			} else if sqlite3_stricmp(z, c'day') == 0 {
				rc = 0
			}
		}
		int(`+`), int(`-`), int(`0`), int(`1`), int(`2`), int(`3`), int(`4`), int(`5`), int(`6`), int(`7`), int(`8`), int(`9`) {
			r_rounder := 0.0
			i := 0
			rx := 0

			y := 0
			m := 0
			d := 0
			h := 0
			m_2 := 0
			x := 0

			z2 := z
			z_copy := &i8(0)
			db := sqlite3_context_db_handle(p_ctx)
			z0 := z[0]
			for n = 1; z[n]; n++ {
				if int(z[n]) == i8(`:`) {
					break
				}
				if (int(sqlite3CtypeMap[u8(z[n])]) & 1) {
					break
				}
				if int(z[n]) == i8(`-`) {
					if n == 5 && get_digits(unsafe { z + 1 }, c'40f', voidptr(&y)) == 1 {
						break
					}
					if n == 6 && get_digits(unsafe { z + 1 }, c'50f', voidptr(&y)) == 1 {
						break
					}
				}
			}
			z_copy = sqlite3_db_str_nd_up(db, z, U64(n))
			if usize(z_copy) == usize(0) {
				unsafe { goto c2v_switch_end_1
				 }
			}
			rx = sqlite3_ato_f(z_copy, &r) <= 0
			sqlite3_db_free(db, voidptr(z_copy))
			if rx {
				unsafe { goto c2v_switch_end_1
				 }
			}
			if int(z[n]) == i8(`-`) {
				if int(z0) != i8(`+`) && int(z0) != i8(`-`) {
					unsafe { goto c2v_switch_end_1
					 }
				}
				if n == 5 {
					if get_digits(unsafe { z + 1 }, c'40f-20a-20d', voidptr(&y), voidptr(&m), voidptr(&d)) != 3 {
						unsafe { goto c2v_switch_end_1
						 }
					}
				} else {
					if get_digits(unsafe { z + 1 }, c'50f-20a-20d', voidptr(&y), voidptr(&m), voidptr(&d)) != 3 {
						unsafe { goto c2v_switch_end_1
						 }
					}
					c2v_pointer_postfix(voidptr(&z), z, isize(1))
				}
				if m >= 12 {
					unsafe { goto c2v_switch_end_1
					 }
				}
				if d >= 31 {
					unsafe { goto c2v_switch_end_1
					 }
				}
				compute_ymd_hms(p)
				p.validJD = i8(0)
				if int(z0) == i8(`-`) {
					p.y -= y
					p.m_ -= m
					d = -d
				} else {
					p.y += y
					p.m_ += m
				}
				x = if p.m_ > 0 { (p.m_ - 1) / 12 } else { (p.m_ - 12) / 12 }
				p.y += x
				p.m_ -= x * 12
				compute_floor(p)
				compute_jd(p)
				p.validHMS = i8(0)
				p.validYMD = i8(0)
				p.iJD += I64(d) * I64(86400000)
				if int(z[11]) == 0 {
					rc = 0
					unsafe { goto c2v_switch_end_1
					 }
				}
				if (int(sqlite3CtypeMap[u8(z[11])]) & 1) && get_digits(unsafe { z + 12 }, c'20c:20e', voidptr(&h), voidptr(&m_2)) == 2 {
					z2 = unsafe { z + 12 }
					n = 2
				} else {
					unsafe { goto c2v_switch_end_1
					 }
				}
			}
			if int(z2[n]) == i8(`:`) {
				tx := DateTime{}
				day := Sqlite3_int64(0)
				if !(int(sqlite3CtypeMap[u8((unsafe { *z2 }))]) & 4) {
					c2v_pointer_postfix(voidptr(&z2), z2, isize(1))
				}
				C.memset(voidptr(&tx), 0, sizeof(tx))
				if parse_hh_mm_ss(z2, &tx) {
					unsafe { goto c2v_switch_end_1
					 }
				}
				compute_jd(&tx)
				tx.iJD -= Sqlite3_int64(43200000)
				day = tx.iJD / Sqlite3_int64(86400000)
				tx.iJD -= day * Sqlite3_int64(86400000)
				if int(z0) == i8(`-`) {
					tx.iJD = -tx.iJD
				}
				compute_jd(p)
				clear_ymd_hms_tz(p)
				p.iJD += tx.iJD
				rc = 0
				unsafe { goto c2v_switch_end_1
				 }
			}
			c2v_pointer_prefix(voidptr(&z), z, isize(n))
			for (int(sqlite3CtypeMap[u8((unsafe { *z }))]) & 1) {
				c2v_pointer_postfix(voidptr(&z), z, isize(1))
			}
			n = sqlite3_strlen30(z)
			if n < 3 || n > 10 {
				unsafe { goto c2v_switch_end_1
				 }
			}
			if int(sqlite3UpperToLower[U8(z[n - 1])]) == `s` {
				n--
			}
			compute_jd(p)
			r_rounder = if r < f64(0) { -0.5 } else { 0.5 }
			p.nFloor = i8(0)
			for i = 0; i < 6; i++ {
				if int(aXformType[i].nName) == n && sqlite3_strnicmp(unsafe { &i8(&aXformType[i].zName[0]) }, z, n) == 0 && r > f64(-aXformType[i].rLimit) && r < f64(aXformType[i].rLimit) {
					match i {
						4 {
							compute_ymd_hms(p)
							p.m_ += int(r)
							x = if p.m_ > 0 { (p.m_ - 1) / 12 } else { (p.m_ - 12) / 12 }
							p.y += x
							p.m_ -= x * 12
							compute_floor(p)
							p.validJD = i8(0)
							r -= f64(int(r))
						}
						5 {
							y_2 := int(r)
							compute_ymd_hms(p)
							p.y += y_2
							compute_floor(p)
							p.validJD = i8(0)
							r -= f64(int(r))
						}
						else {}
					}

					compute_jd(p)
					p.iJD += Sqlite3_int64((r * 1000.0 * f64(aXformType[i].rXform) + r_rounder))
					rc = 0
					break
				}
			}
			clear_ymd_hms_tz(p)
		}
		else {
		}
	}
	c2v_switch_end_1:

	return rc
}

@[c:'isDate']
fn is_date(context &Sqlite3_context, argc int, argv &&Sqlite3_value, p &DateTime) int {
	i := 0
	n := 0

	z := &u8(0)
	e_type := 0
	C.memset(voidptr(p), 0, sizeof(DateTime))
	if argc == 0 {
		if !sqlite3_not_pure_func(context) {
			return 1
		}
		return set_date_time_to_current(context, p)
	}
	e_type = sqlite3_value_type(argv[0])
	if e_type == 2 || e_type == 1 {
		set_raw_date_number(p, sqlite3_value_double(argv[0]))
	} else {
		z = sqlite3_value_text(argv[0])
		if isnil(z) || parse_date_or_time(context, &i8(voidptr(z)), p) {
			return 1
		}
	}
	for i = 1; i < argc; i++ {
		z = sqlite3_value_text(argv[i])
		n = sqlite3_value_bytes(argv[i])
		if usize(z) == usize(0) || parse_modifier(context, &i8(voidptr(z)), n, p, i) {
			return 1
		}
	}
	compute_jd(p)
	if int(p.isError) || !valid_julian_day(p.iJD) {
		return 1
	}
	if argc == 1 && int(p.validYMD) && p.d > 28 {
		p.validYMD = i8(0)
	}
	return 0
}

@[c:'juliandayFunc']
fn julianday_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	x := DateTime{}
	if is_date(context, argc, argv, &x) == 0 {
		compute_jd(&x)
		sqlite3_result_double(context, f64(x.iJD) / 8.64E+7)
	}
}

@[c:'unixepochFunc']
fn unixepoch_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	x := DateTime{}
	if is_date(context, argc, argv, &x) == 0 {
		compute_jd(&x)
		if x.useSubsec {
			sqlite3_result_double(context, f64((x.iJD - I64(21086676) * I64(10000000))) / 1000.0)
		} else {
			sqlite3_result_int64(context, x.iJD / Sqlite3_int64(1000) - I64(21086676) * I64(10000))
		}
	}
}

@[c:'datetimeFunc']
fn datetime_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	x := DateTime{}
	if is_date(context, argc, argv, &x) == 0 {
		y := 0
		s := 0
		n := 0

		z_buf := [32]i8{}
		compute_ymd_hms(&x)
		y = x.y
		if y < 0 {
			y = -y
		}
		z_buf[1] = i8(int(`0`) + (y / 1000) % 10)
		z_buf[2] = i8(int(`0`) + (y / 100) % 10)
		z_buf[3] = i8(int(`0`) + (y / 10) % 10)
		z_buf[4] = i8(int(`0`) + y % 10)
		z_buf[5] = i8(`-`)
		z_buf[6] = i8(int(`0`) + (x.m_ / 10) % 10)
		z_buf[7] = i8(int(`0`) + x.m_ % 10)
		z_buf[8] = i8(`-`)
		z_buf[9] = i8(int(`0`) + (x.d / 10) % 10)
		z_buf[10] = i8(int(`0`) + x.d % 10)
		z_buf[11] = i8(` `)
		z_buf[12] = i8(int(`0`) + (x.h / 10) % 10)
		z_buf[13] = i8(int(`0`) + x.h % 10)
		z_buf[14] = i8(`:`)
		z_buf[15] = i8(int(`0`) + (x.m / 10) % 10)
		z_buf[16] = i8(int(`0`) + x.m % 10)
		z_buf[17] = i8(`:`)
		if x.useSubsec {
			s = int((1000.0 * x.s + 0.5))
			z_buf[18] = i8(int(`0`) + (s / 10000) % 10)
			z_buf[19] = i8(int(`0`) + (s / 1000) % 10)
			z_buf[20] = i8(`.`)
			z_buf[21] = i8(int(`0`) + (s / 100) % 10)
			z_buf[22] = i8(int(`0`) + (s / 10) % 10)
			z_buf[23] = i8(int(`0`) + s % 10)
			z_buf[24] = i8(0)
			n = 24
		} else {
			s = int(x.s)
			z_buf[18] = i8(int(`0`) + (s / 10) % 10)
			z_buf[19] = i8(int(`0`) + s % 10)
			z_buf[20] = i8(0)
			n = 20
		}
		if x.y < 0 {
			z_buf[0] = i8(`-`)
			sqlite3_result_text(context, unsafe { &i8(&z_buf[0]) }, n, (C2vFn_666e2028766f696470747229(voidptr(-1))))
		} else {
			sqlite3_result_text(context, unsafe { &z_buf[0] + 1 }, n - 1, (C2vFn_666e2028766f696470747229(voidptr(-1))))
		}
	}
}

@[c:'timeFunc']
fn time_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	x := DateTime{}
	if is_date(context, argc, argv, &x) == 0 {
		s := 0
		n := 0

		z_buf := [16]i8{}
		compute_hms(&x)
		z_buf[0] = i8(int(`0`) + (x.h / 10) % 10)
		z_buf[1] = i8(int(`0`) + x.h % 10)
		z_buf[2] = i8(`:`)
		z_buf[3] = i8(int(`0`) + (x.m / 10) % 10)
		z_buf[4] = i8(int(`0`) + x.m % 10)
		z_buf[5] = i8(`:`)
		if x.useSubsec {
			s = int((1000.0 * x.s + 0.5))
			z_buf[6] = i8(int(`0`) + (s / 10000) % 10)
			z_buf[7] = i8(int(`0`) + (s / 1000) % 10)
			z_buf[8] = i8(`.`)
			z_buf[9] = i8(int(`0`) + (s / 100) % 10)
			z_buf[10] = i8(int(`0`) + (s / 10) % 10)
			z_buf[11] = i8(int(`0`) + s % 10)
			z_buf[12] = i8(0)
			n = 12
		} else {
			s = int(x.s)
			z_buf[6] = i8(int(`0`) + (s / 10) % 10)
			z_buf[7] = i8(int(`0`) + s % 10)
			z_buf[8] = i8(0)
			n = 8
		}
		sqlite3_result_text(context, unsafe { &i8(&z_buf[0]) }, n, (C2vFn_666e2028766f696470747229(voidptr(-1))))
	}
}

@[c:'dateFunc']
fn date_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	x := DateTime{}
	if is_date(context, argc, argv, &x) == 0 {
		y := 0
		z_buf := [16]i8{}
		compute_ymd(&x)
		y = x.y
		if y < 0 {
			y = -y
		}
		z_buf[1] = i8(int(`0`) + (y / 1000) % 10)
		z_buf[2] = i8(int(`0`) + (y / 100) % 10)
		z_buf[3] = i8(int(`0`) + (y / 10) % 10)
		z_buf[4] = i8(int(`0`) + y % 10)
		z_buf[5] = i8(`-`)
		z_buf[6] = i8(int(`0`) + (x.m_ / 10) % 10)
		z_buf[7] = i8(int(`0`) + x.m_ % 10)
		z_buf[8] = i8(`-`)
		z_buf[9] = i8(int(`0`) + (x.d / 10) % 10)
		z_buf[10] = i8(int(`0`) + x.d % 10)
		z_buf[11] = i8(0)
		if x.y < 0 {
			z_buf[0] = i8(`-`)
			sqlite3_result_text(context, unsafe { &i8(&z_buf[0]) }, 11, (C2vFn_666e2028766f696470747229(voidptr(-1))))
		} else {
			sqlite3_result_text(context, unsafe { &z_buf[0] + 1 }, 10, (C2vFn_666e2028766f696470747229(voidptr(-1))))
		}
	}
}

@[c:'daysAfterJan01']
fn days_after_jan01(p_date &DateTime) int {
	jan01 := (unsafe { *p_date })
	jan01.validJD = i8(0)
	jan01.m_ = 1
	jan01.d = 1
	compute_jd(&jan01)
	return int(((p_date.iJD - jan01.iJD + Sqlite3_int64(43200000)) / Sqlite3_int64(86400000)))
}

@[c:'daysAfterMonday']
fn days_after_monday(p_date &DateTime) int {
	return int(((p_date.iJD + Sqlite3_int64(43200000)) / Sqlite3_int64(86400000))) % 7
}

@[c:'daysAfterSunday']
fn days_after_sunday(p_date &DateTime) int {
	return int(((p_date.iJD + Sqlite3_int64(129600000)) / Sqlite3_int64(86400000))) % 7
}

@[c:'strftimeFunc']
fn strftime_func(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	x := DateTime{}
	i := usize(0)
	j := usize(0)

	db := &Sqlite3(0)
	z_fmt := &i8(0)
	s_res := Sqlite3_str{}
	if argc == 0 {
		return
	}
	z_fmt = &i8(voidptr(sqlite3_value_text(argv[0])))
	if usize(z_fmt) == usize(0) || is_date(context, argc - 1, argv + 1, &x) {
		return
	}
	db = sqlite3_context_db_handle(context)
	sqlite3_str_accum_init(unsafe { &StrAccum(&s_res) }, unsafe { nil }, unsafe { nil }, 0, db.aLimit[0])
	compute_jd(&x)
	compute_ymd_hms(&x)
	j = usize(0)
	for i = usize(0); z_fmt[i]; i++ {
		cf := i8(0)
		if int(z_fmt[i]) != i8(`%`) {
			continue
		}
		if j < i {
			sqlite3_str_append(&s_res, z_fmt + j, int((i - j)))
		}
		i++
		j = i + usize(1)
		cf = z_fmt[i]
		match int(cf) {
			int(`d`), int(`e`) {
				sqlite3_str_appendf(&s_res, unsafe { if int(cf) == i8(`d`) {
					c'%02d'
				} else {
					c'%2d'
				} }, x.d)
			}
			int(`f`) {
				s := x.s
				if (s > 59.999000000000002) {
					s = 59.999000000000002
				}
				sqlite3_str_appendf(&s_res, c'%06.3f', s)
			}
			int(`F`) {
				sqlite3_str_appendf(&s_res, c'%04d-%02d-%02d', x.y, x.m_, x.d)
			}
			int(`G`), int(`g`) {
				y := x
				y.iJD += Sqlite3_int64((3 - days_after_monday(&x)) * 86400000)
				y.validYMD = i8(0)
				compute_ymd(&y)
				if int(cf) == i8(`g`) {
					sqlite3_str_appendf(&s_res, c'%02d', y.y % 100)
				} else {
					sqlite3_str_appendf(&s_res, c'%04d', y.y)
				}
			}
			int(`H`), int(`k`) {
				sqlite3_str_appendf(&s_res, unsafe { if int(cf) == i8(`H`) {
					c'%02d'
				} else {
					c'%2d'
				} }, x.h)
			}
			int(`I`), int(`l`) {
				h := x.h
				if h > 12 {
					h -= 12
				}
				if h == 0 {
					h = 12
				}
				sqlite3_str_appendf(&s_res, unsafe { if int(cf) == i8(`I`) {
					c'%02d'
				} else {
					c'%2d'
				} }, h)
			}
			int(`j`) {
				sqlite3_str_appendf(&s_res, c'%03d', days_after_jan01(&x) + 1)
			}
			int(`J`) {
				sqlite3_str_appendf(&s_res, c'%.16g', f64(x.iJD) / 8.64E+7)
			}
			int(`m`) {
				sqlite3_str_appendf(&s_res, c'%02d', x.m_)
			}
			int(`M`) {
				sqlite3_str_appendf(&s_res, c'%02d', x.m)
			}
			int(`p`), int(`P`) {
				if x.h >= 12 {
					sqlite3_str_append(&s_res, unsafe { if int(cf) == i8(`p`) {
						c'PM'
					} else {
						c'pm'
					} }, 2)
				} else {
					sqlite3_str_append(&s_res, unsafe { if int(cf) == i8(`p`) {
						c'AM'
					} else {
						c'am'
					} }, 2)
				}
			}
			int(`R`) {
				sqlite3_str_appendf(&s_res, c'%02d:%02d', x.h, x.m)
			}
			int(`s`) {
				if x.useSubsec {
					sqlite3_str_appendf(&s_res, c'%.3f', f64((x.iJD - I64(21086676) * I64(10000000))) / 1000.0)
				} else {
					is_ := I64((x.iJD / Sqlite3_int64(1000) - I64(21086676) * I64(10000)))
					sqlite3_str_appendf(&s_res, c'%lld', is_)
				}
			}
			int(`S`) {
				sqlite3_str_appendf(&s_res, c'%02d', int(x.s))
			}
			int(`T`) {
				sqlite3_str_appendf(&s_res, c'%02d:%02d:%02d', x.h, x.m, int(x.s))
			}
			int(`u`), int(`w`) {
				c := i8(int(i8(days_after_sunday(&x))) + int(`0`))
				if int(c) == i8(`0`) && int(cf) == i8(`u`) {
					c = i8(`7`)
				}
				sqlite3_str_appendchar(&s_res, 1, i8(c))
			}
			int(`U`) {
				sqlite3_str_appendf(&s_res, c'%02d', (days_after_jan01(&x) - days_after_sunday(&x) + 7) / 7)
			}
			int(`V`) {
				y_2 := x
				y_2.iJD += Sqlite3_int64((3 - days_after_monday(&x)) * 86400000)
				y_2.validYMD = i8(0)
				compute_ymd(&y_2)
				sqlite3_str_appendf(&s_res, c'%02d', days_after_jan01(&y_2) / 7 + 1)
			}
			int(`W`) {
				sqlite3_str_appendf(&s_res, c'%02d', (days_after_jan01(&x) - days_after_monday(&x) + 7) / 7)
			}
			int(`Y`) {
				sqlite3_str_appendf(&s_res, c'%04d', x.y)
			}
			int(`%`) {
				sqlite3_str_appendchar(&s_res, 1, i8(`%`))
			}
			else {
				sqlite3_str_reset(&s_res)
				return
			}
		}
	}
	if j < i {
		sqlite3_str_append(&s_res, z_fmt + j, int((i - j)))
	}
	sqlite3_result_str_accum(context, unsafe { &StrAccum(&s_res) })
}

@[c:'ctimeFunc']
fn ctime_func(context &Sqlite3_context, not_used int, not_used2 &&Sqlite3_value) {
	c2v_gc_register_thread()

	time_func(context, 0, unsafe { &&Sqlite3_value(nil) })
}

@[c:'cdateFunc']
fn cdate_func(context &Sqlite3_context, not_used int, not_used2 &&Sqlite3_value) {
	c2v_gc_register_thread()

	date_func(context, 0, unsafe { &&Sqlite3_value(nil) })
}

@[c:'timediffFunc']
fn timediff_func(context &Sqlite3_context, not_used1 int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	sign := i8(0)
	y := 0
	m := 0

	d1 := DateTime{}
	d2 := DateTime{}

	s_res := Sqlite3_str{}

	if is_date(context, 1, &&Sqlite3_value(unsafe { argv + 0 }), &d1) {
		return
	}
	if is_date(context, 1, &&Sqlite3_value(unsafe { argv + 1 }), &d2) {
		return
	}
	compute_ymd_hms(&d1)
	compute_ymd_hms(&d2)
	if d1.iJD >= d2.iJD {
		sign = i8(`+`)
		y = d1.y - d2.y
		if y {
			d2.y = d1.y
			d2.validJD = i8(0)
			compute_jd(&d2)
		}
		m = d1.m_ - d2.m_
		if m < 0 {
			y--
			m += 12
		}
		if m != 0 {
			d2.m_ = d1.m_
			d2.validJD = i8(0)
			compute_jd(&d2)
		}
		for d1.iJD < d2.iJD {
			m--
			if m < 0 {
				m = 11
				y--
			}
			d2.m_--
			if d2.m_ < 1 {
				d2.m_ = 12
				d2.y--
			}
			d2.validJD = i8(0)
			compute_jd(&d2)
		}
		d1.iJD -= d2.iJD
		d1.iJD += U64(1486995408) * U64(100000)
	} else {
		sign = i8(`-`)
		y = d2.y - d1.y
		if y {
			d2.y = d1.y
			d2.validJD = i8(0)
			compute_jd(&d2)
		}
		m = d2.m_ - d1.m_
		if m < 0 {
			y--
			m += 12
		}
		if m != 0 {
			d2.m_ = d1.m_
			d2.validJD = i8(0)
			compute_jd(&d2)
		}
		for d1.iJD > d2.iJD {
			m--
			if m < 0 {
				m = 11
				y--
			}
			d2.m_++
			if d2.m_ > 12 {
				d2.m_ = 1
				d2.y++
			}
			d2.validJD = i8(0)
			compute_jd(&d2)
		}
		d1.iJD = d2.iJD - d1.iJD
		d1.iJD += U64(1486995408) * U64(100000)
	}
	clear_ymd_hms_tz(&d1)
	compute_ymd_hms(&d1)
	sqlite3_str_accum_init(unsafe { &StrAccum(&s_res) }, unsafe { nil }, unsafe { nil }, 0, 100)
	sqlite3_str_appendf(&s_res, c'%c%04d-%02d-%02d %02d:%02d:%06.3f', int(sign), y, m, d1.d - 1, d1.h, d1.m, d1.s)
	sqlite3_result_str_accum(context, unsafe { &StrAccum(&s_res) })
}

@[c:'ctimestampFunc']
fn ctimestamp_func(context &Sqlite3_context, not_used int, not_used2 &&Sqlite3_value) {
	c2v_gc_register_thread()

	datetime_func(context, 0, unsafe { &&Sqlite3_value(nil) })
}

@[c:'sqlite3RegisterDateTimeFunctions']
fn sqlite3_register_date_time_functions() {
	if !sqlite3_register_date_time_functions_a_date_time_funcs_inited {
		c2v_static_init := [FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 8192 | 1 | 2048)
			pUserData: voidptr(&sqlite3Config)
			pNext: 0
			xSFunc: julianday_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'julianday'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 8192 | 1 | 2048)
			pUserData: voidptr(&sqlite3Config)
			pNext: 0
			xSFunc: unixepoch_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'unixepoch'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 8192 | 1 | 2048)
			pUserData: voidptr(&sqlite3Config)
			pNext: 0
			xSFunc: date_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'date'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 8192 | 1 | 2048)
			pUserData: voidptr(&sqlite3Config)
			pNext: 0
			xSFunc: time_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'time'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 8192 | 1 | 2048)
			pUserData: voidptr(&sqlite3Config)
			pNext: 0
			xSFunc: datetime_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'datetime'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 8192 | 1 | 2048)
			pUserData: voidptr(&sqlite3Config)
			pNext: 0
			xSFunc: strftime_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'strftime'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 8192 | 1 | 2048)
			pUserData: voidptr(&sqlite3Config)
			pNext: 0
			xSFunc: timediff_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'timediff'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(0)
			funcFlags: u32(8388608 | 8192 | 1)
			pUserData: 0
			pNext: 0
			xSFunc: ctime_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'current_time'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(0)
			funcFlags: u32(8388608 | 8192 | 1)
			pUserData: 0
			pNext: 0
			xSFunc: ctimestamp_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'current_timestamp'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(0)
			funcFlags: u32(8388608 | 8192 | 1)
			pUserData: 0
			pNext: 0
			xSFunc: cdate_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'current_date'
			u: FuncDef_u{}
		}]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_register_date_time_functions_a_date_time_funcs[c2v_i_0] = c2v_element_0
		}
		sqlite3_register_date_time_functions_a_date_time_funcs_inited = true
	}

	sqlite3_insert_builtin_funcs(&sqlite3_register_date_time_functions_a_date_time_funcs[0], 10)
}
