@[translated]
module main

union Bitvec_u {
	aBitmap [496]U8
	aHash   [124]u32
	apSub   [62]voidptr
}

struct Bitvec {
	iSize    u32
	nSet     u32
	iDivisor u32
	u        Bitvec_u
}

@[c:'sqlite3BitvecCreate']
fn sqlite3_bitvec_create(i_size u32) &Bitvec {
	p := &Bitvec(0)
	p = sqlite3_malloc_zero(U64(sizeof(Bitvec)))
	if p {
		p.iSize = i_size
	}
	return p
}

@[c:'sqlite3BitvecTestNotNull']
fn sqlite3_bitvec_test_not_null(p &Bitvec, i u32) int {
	i--
	if i >= p.iSize {
		return 0
	}
	for p.iDivisor {
		bin := i / p.iDivisor
		i = i % p.iDivisor
		p = &Bitvec(p.u.apSub[bin])
		if isnil(p) {
			return 0
		}
	}
	if u64(p.iSize) <= (((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(U8)) * u64(8)) {
		return int((int(p.u.aBitmap[i / u32(8)]) & (1 << (i & u32((8 - 1))))) != 0)
	} else {
		h := u32((u64(((i++) * u32(1))) % ((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(u32))))
		for p.u.aHash[h] {
			if p.u.aHash[h] == i {
				return 1
			}
			h = u32(u64((h + u32(1))) % ((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(u32)))
		}
		return 0
	}
}

@[c:'sqlite3BitvecTest']
fn sqlite3_bitvec_test(p &Bitvec, i u32) int {
	return int(usize(p) != usize(0) && sqlite3_bitvec_test_not_null(p, i))
}

@[c:'sqlite3BitvecSet']
fn sqlite3_bitvec_set(p &Bitvec, i u32) int {
	h := u32(0)
	if usize(p) == usize(0) {
		return 0
	}
	i--
	for (u64(p.iSize) > (((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(U8)) * u64(8))) && p.iDivisor {
		bin := i / p.iDivisor
		i = i % p.iDivisor
		if usize(p.u.apSub[bin]) == usize(0) {
			p.u.apSub[bin] = sqlite3_bitvec_create(p.iDivisor)
			if usize(p.u.apSub[bin]) == usize(0) {
				return 7
			}
		}
		p = &Bitvec(p.u.apSub[bin])
	}
	if u64(p.iSize) <= (((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(U8)) * u64(8)) {
		p.u.aBitmap[i / u32(8)] |= 1 << (i & u32((8 - 1)))
		return 0
	}
	h = u32((u64(((i++) * u32(1))) % ((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(u32))))
	if !p.u.aHash[h] {
		if u64(p.nSet) < (((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(u32)) - u64(1)) {
			unsafe { goto bitvec_set_end
			 }
		} else {
			unsafe { goto bitvec_set_rehash
			 }
		}
	}
	for {
		if p.u.aHash[h] == i {
			return 0
		}
		h++
		if u64(h) >= ((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(u32)) {
			h = u32(0)
		}
		if !(p.u.aHash[h]) {
			break
		}
	}
	bitvec_set_rehash:
	if u64(p.nSet) >= (((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(u32)) / u64(2)) {
		j := u32(0)
		rc := 0
		ai_values := &u32(sqlite3_db_malloc_raw(unsafe { nil }, U64(sizeof([124]u32))))
		if usize(ai_values) == usize(0) {
			return 7
		} else {
			C.memcpy(voidptr(ai_values), p.u.aHash, sizeof([124]u32))
			C.memset(p.u.apSub, 0, sizeof([62]&Bitvec))
			p.iDivisor = p.iSize / (u32(((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(voidptr))))
			if (p.iSize % (u32(((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(voidptr))))) != u32(0) {
				p.iDivisor++
			}
			if u64(p.iDivisor) < (((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(U8)) * u64(8)) {
				p.iDivisor = u32((((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(U8)) * u64(8)))
			}
			rc = sqlite3_bitvec_set(p, i)
			for j = u32(0); u64(j) < ((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(u32)); j++ {
				if ai_values[j] {
					rc |= sqlite3_bitvec_set(p, ai_values[j])
				}
			}
			sqlite3_db_free(unsafe { nil }, voidptr(ai_values))
			return rc
		}
	}
	bitvec_set_end:
	p.nSet++
	p.u.aHash[h] = i
	return 0
}

@[c:'sqlite3BitvecClear']
fn sqlite3_bitvec_clear(p &Bitvec, i u32, p_buf voidptr) {
	if usize(p) == usize(0) {
		return
	}
	i--
	for p.iDivisor {
		bin := i / p.iDivisor
		i = i % p.iDivisor
		p = &Bitvec(p.u.apSub[bin])
		if isnil(p) {
			return
		}
	}
	if u64(p.iSize) <= (((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(U8)) * u64(8)) {
		p.u.aBitmap[i / u32(8)] &= ~int(U8((1 << (i & u32((8 - 1))))))
	} else {
		j := u32(0)
		ai_values := &u32(p_buf)
		C.memcpy(voidptr(ai_values), p.u.aHash, sizeof([124]u32))
		C.memset(p.u.aHash, 0, sizeof([124]u32))
		p.nSet = u32(0)
		for j = u32(0); u64(j) < ((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(u32)); j++ {
			if ai_values[j] && ai_values[j] != (i + u32(1)) {
				h := u32((u64(((ai_values[j] - u32(1)) * u32(1))) % ((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(u32))))
				p.nSet++
				for p.u.aHash[h] {
					h++
					if u64(h) >= ((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(u32)) {
						h = u32(0)
					}
				}
				p.u.aHash[h] = ai_values[j]
			}
		}
	}
}

@[c:'sqlite3BitvecDestroy']
fn sqlite3_bitvec_destroy(p &Bitvec) {
	if usize(p) == usize(0) {
		return
	}
	if p.iDivisor {
		i := u32(0)
		for i = u32(0); i < (u32(((((u64(512) - (u64(3) * sizeof(u32))) / sizeof(voidptr)) * sizeof(voidptr)) / sizeof(voidptr)))); i++ {
			sqlite3_bitvec_destroy(&Bitvec(p.u.apSub[i]))
		}
	}
	sqlite3_free(voidptr(p))
}

@[c:'sqlite3BitvecSize']
fn sqlite3_bitvec_size(p &Bitvec) u32 {
	return p.iSize
}

@[c:'sqlite3BitvecBuiltinTest']
fn sqlite3_bitvec_builtin_test(sz int, a_op &int) int {
	p_bitvec := unsafe { &Bitvec(nil) }
	pv := unsafe { &u8(nil) }
	rc := -1
	i := 0
	nx := 0
	pc := 0
	op := 0

	p_tmp_space := &voidptr(0)
	if sz <= 0 {
		p_bitvec = sqlite3_bitvec_create(u32(2) * u32((-sz)))
		pv = 0
	} else {
		p_bitvec = sqlite3_bitvec_create(u32(sz))
		pv = &u8(sqlite3_malloc_zero(U64((I64(7) + I64(sz)) / I64(8) + I64(1))))
	}
	p_tmp_space = sqlite3_malloc64(Sqlite3_uint64(512))
	if usize(p_bitvec) == usize(0) || usize(p_tmp_space) == usize(0) || (usize(pv) == usize(0) && sz > 0) {
		unsafe { goto bitvec_end
		 }
	}
	sqlite3_bitvec_set(unsafe { nil }, u32(1))
	sqlite3_bitvec_clear(unsafe { nil }, u32(1), voidptr(p_tmp_space))
	i = 0
	pc = i
	for {
		op = a_op[pc]
		if !(op != 0) {
			break
		}
		if op >= 6 {
			pc++
			continue
		}
		match op {
			1, 2, 5 {
				nx = 4
				i = a_op[pc + 2] - 1
				a_op[pc + 2] += a_op[pc + 3]
			}
			else {
				nx = 2
				sqlite3_randomness(int(sizeof(i)), voidptr(&i))
			}
		}

		a_op[pc + 1]--
		if (a_op[pc + 1]) > 0 {
			nx = 0
		}
		pc += nx
		i = (i & 2147483647) % sz
		if (op & 1) != 0 {
			if pv {
				pv[(i + 1) >> 3] |= (1 << ((i + 1) & 7))
			}
			if op != 5 {
				if sqlite3_bitvec_set(p_bitvec, u32(i + 1)) {
					unsafe { goto bitvec_end
					 }
				}
			}
		} else {
			if pv {
				pv[(i + 1) >> 3] &= ~int(U8((1 << ((i + 1) & 7))))
			}
			sqlite3_bitvec_clear(p_bitvec, u32(i + 1), voidptr(p_tmp_space))
		}
	}
	if pv {
		rc = int(u32(sqlite3_bitvec_test(unsafe { nil }, u32(0)) + sqlite3_bitvec_test(p_bitvec, u32(sz + 1)) + sqlite3_bitvec_test(p_bitvec, u32(0))) + (sqlite3_bitvec_size(p_bitvec) - u32(sz)))
		for i = 1; i <= sz; i++ {
			if ((int(pv[i >> 3]) & (1 << (i & 7))) != 0) != sqlite3_bitvec_test(p_bitvec, u32(i)) {
				rc = i
				break
			}
		}
	} else {
		rc = 0
	}
	bitvec_end:
	sqlite3_free(voidptr(p_tmp_space))
	sqlite3_free(voidptr(pv))
	sqlite3_bitvec_destroy(p_bitvec)
	return rc
}
