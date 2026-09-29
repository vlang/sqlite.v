@[translated]
module main

struct TabResult {
	azResult &&u8
	zErrMsg  &i8
	nAlloc   u32
	nRow     u32
	nColumn  u32
	nData    u32
	rc       int
}

fn sqlite3_get_table_cb(p_arg voidptr, n_col int, argv &&u8, colv &&u8) int {
	c2v_gc_register_thread()
	p := &TabResult(p_arg)
	need := 0
	i := 0
	z := &i8(0)
	if p.nRow == u32(0) && usize(argv) != usize(0) {
		need = n_col * 2
	} else {
		need = n_col
	}
	if p.nData + u32(need) > p.nAlloc {
		az_new := &&u8(0)
		p.nAlloc = p.nAlloc * u32(2) + u32(need)
		az_new = sqlite3_realloc_vdup3(voidptr(p.azResult), U64(sizeof(voidptr) * u64(p.nAlloc)))
		if usize(az_new) == usize(0) {
			unsafe { goto malloc_failed
			 }
		}
		p.azResult = az_new
	}
	if p.nRow == u32(0) {
		p.nColumn = u32(n_col)
		for i = 0; i < n_col; i++ {
			z = sqlite3_mprintf(c'%s', voidptr(colv[i]))
			if usize(z) == usize(0) {
				unsafe { goto malloc_failed
				 }
			}
			p.azResult[p.nData++] = z
		}
	} else if int(p.nColumn) != n_col {
		sqlite3_free(voidptr(p.zErrMsg))
		p.zErrMsg = sqlite3_mprintf(c'sqlite3_get_table() called with two or more incompatible queries')
		p.rc = 1
		return 1
	}
	if usize(argv) != usize(0) {
		for i = 0; i < n_col; i++ {
			if usize(argv[i]) == usize(0) {
				z = 0
			} else {
				n := sqlite3_strlen30(argv[i]) + 1
				z = &i8(sqlite3_malloc64(Sqlite3_uint64(n)))
				if usize(z) == usize(0) {
					unsafe { goto malloc_failed
					 }
				}
				C.memcpy(voidptr(z), voidptr(argv[i]), u64(n))
			}
			p.azResult[p.nData++] = z
		}
		p.nRow++
	}
	return 0
	malloc_failed:
	p.rc = 7
	return 1
}

fn sqlite3_get_table(db &Sqlite3, z_sql &i8, paz_result &&&i8, pn_row &int, pn_column &int, pz_err_msg &&u8) int {
	c2v_gc_register_thread()
	rc := 0
	res := TabResult{}
	unsafe { *paz_result = 0 }
	if pn_column {
		unsafe { *pn_column = 0 }
	}
	if pn_row {
		unsafe { *pn_row = 0 }
	}
	if pz_err_msg {
		unsafe { *pz_err_msg = 0 }
	}
	res.zErrMsg = 0
	res.nRow = u32(0)
	res.nColumn = u32(0)
	res.nData = u32(1)
	res.nAlloc = u32(20)
	res.rc = 0
	res.azResult = sqlite3_malloc64(Sqlite3_uint64(sizeof(voidptr) * u64(res.nAlloc)))
	if usize(res.azResult) == usize(0) {
		db.errCode = 7
		return 7
	}
	res.azResult[0] = 0
	rc = sqlite3_exec(db, z_sql, sqlite3_get_table_cb, voidptr(&res), pz_err_msg)
	res.azResult[0] = &i8((voidptr(i64(res.nData))))
	if (rc & 255) == 4 {
		sqlite3_free_table(&&u8(unsafe { res.azResult + 1 }))
		if res.zErrMsg {
			if pz_err_msg {
				sqlite3_free(voidptr((unsafe { *pz_err_msg })))
				unsafe { *pz_err_msg = sqlite3_mprintf(c'%s', voidptr(res.zErrMsg)) }
			}
			sqlite3_free(voidptr(res.zErrMsg))
		}
		db.errCode = res.rc
		return res.rc
	}
	sqlite3_free(voidptr(res.zErrMsg))
	if rc != 0 {
		sqlite3_free_table(&&u8(unsafe { res.azResult + 1 }))
		return rc
	}
	if res.nAlloc > res.nData {
		az_new := &&u8(0)
		az_new = sqlite3_realloc_vdup3(voidptr(res.azResult), U64(sizeof(voidptr) * u64(res.nData)))
		if usize(az_new) == usize(0) {
			sqlite3_free_table(&&u8(unsafe { res.azResult + 1 }))
			db.errCode = 7
			return 7
		}
		res.azResult = az_new
	}
	unsafe { *paz_result = res.azResult + 1 }
	if pn_column {
		unsafe { *pn_column = int(res.nColumn) }
	}
	if pn_row {
		unsafe { *pn_row = int(res.nRow) }
	}
	return rc
}

fn sqlite3_free_table(az_result &&u8) {
	c2v_gc_register_thread()
	if az_result {
		i := 0
		n := 0

		c2v_pointer_postfix(voidptr(&az_result), az_result, isize(-1))
		n = (int(i64(voidptr(az_result[0]))))
		for i = 1; i < n; i++ {
			if az_result[i] {
				sqlite3_free(voidptr(az_result[i]))
			}
		}
		sqlite3_free(voidptr(az_result))
	}
}
