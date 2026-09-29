@[translated]
module main

struct JsonCache {
	db    &Sqlite3
	nUsed int
	a     [4]&JsonParse
}

struct JsonString {
	pCtx    &Sqlite3_context
	zBuf    &i8
	nAlloc  U64
	nUsed   U64
	bStatic U8
	eErr    U8
	zSpace  [100]i8
}

struct JsonParse {
	aBlob        &U8
	nBlob        u32
	nBlobAlloc   u32
	zJson        &i8
	db           &Sqlite3
	nJson        int
	nJPRef       u32
	iErr         u32
	iDepth       U16
	nErr         U8
	oom          U8
	bJsonIsRCStr U8
	hasNonstd    U8
	bReadOnly    U8
	eEdit        U8
	delta        int
	nIns         u32
	iLabel       u32
	aIns         &U8
}

@[c:'jsonCacheDelete']
fn json_cache_delete(p &JsonCache) {
	i := 0
	for i = 0; i < p.nUsed; i++ {
		json_parse_free(p.a[i])
	}
	sqlite3_db_free(p.db, voidptr(p))
}

@[c:'jsonCacheDeleteGeneric']
fn json_cache_delete_generic(p voidptr) {
	c2v_gc_register_thread()
	json_cache_delete(&JsonCache(p))
}

@[c:'jsonCacheInsert']
fn json_cache_insert(ctx &Sqlite3_context, p_parse &JsonParse) int {
	p := &JsonCache(0)
	p = sqlite3_get_auxdata(ctx, (-429938))
	if usize(p) == usize(0) {
		db := sqlite3_context_db_handle(ctx)
		p = sqlite3_db_malloc_zero(db, U64(sizeof(JsonCache)))
		if usize(p) == usize(0) {
			return 7
		}
		p.db = db
		sqlite3_set_auxdata(ctx, (-429938), voidptr(p), json_cache_delete_generic)
		p = sqlite3_get_auxdata(ctx, (-429938))
		if usize(p) == usize(0) {
			return 7
		}
	}
	if p.nUsed >= 4 {
		json_parse_free(p.a[0])
		C.memmove(p.a, voidptr(unsafe { &p.a[0] + 1 }), u64((4 - 1)) * sizeof(&JsonParse))
		p.nUsed = 4 - 1
	}
	p_parse.eEdit = U8(0)
	p_parse.nJPRef++
	p_parse.bReadOnly = U8(1)
	p.a[p.nUsed] = p_parse
	p.nUsed++
	return 0
}

@[c:'jsonCacheSearch']
fn json_cache_search(ctx &Sqlite3_context, p_arg &Sqlite3_value) &JsonParse {
	p := &JsonCache(0)
	i := 0
	z_json := &i8(0)
	n_json := 0
	if sqlite3_value_type(p_arg) != 3 {
		return unsafe { nil }
	}
	z_json = &i8(voidptr(sqlite3_value_text(p_arg)))
	if usize(z_json) == usize(0) {
		return unsafe { nil }
	}
	n_json = sqlite3_value_bytes(p_arg)
	p = sqlite3_get_auxdata(ctx, (-429938))
	if usize(p) == usize(0) {
		return unsafe { nil }
	}
	for i = 0; i < p.nUsed; i++ {
		if usize(p.a[i].zJson) == usize(z_json) {
			break
		}
	}
	if i >= p.nUsed {
		for i = 0; i < p.nUsed; i++ {
			if p.a[i].nJson != n_json {
				continue
			}
			if C.memcmp(voidptr(p.a[i].zJson), voidptr(z_json), u64(n_json)) == 0 {
				break
			}
		}
	}
	if i < p.nUsed {
		if i < p.nUsed - 1 {
			tmp := p.a[i]
			C.memmove(voidptr(unsafe { &p.a[0] + i }), voidptr(unsafe { &p.a[0] + (i + 1) }), u64((p.nUsed - i - 1)) * sizeof(tmp))
			p.a[p.nUsed - 1] = tmp
			i = p.nUsed - 1
		}
		return p.a[i]
	} else {
		return unsafe { nil }
	}
}

@[c:'jsonStringZero']
fn json_string_zero(p &JsonString) {
	p.zBuf = unsafe { &p.zSpace[0] }
	p.nAlloc = U64(sizeof([100]i8))
	p.nUsed = U64(0)
	p.bStatic = U8(1)
}

@[c:'jsonStringInit']
fn json_string_init(p &JsonString, p_ctx &Sqlite3_context) {
	p.pCtx = p_ctx
	p.eErr = U8(0)
	json_string_zero(p)
}

@[c:'jsonStringReset']
fn json_string_reset(p &JsonString) {
	if !p.bStatic {
		sqlite3_rc_str_unref(voidptr(p.zBuf))
	}
	json_string_zero(p)
}

@[c:'jsonStringOom']
fn json_string_oom(p &JsonString) {
	p.eErr |= 1
	if p.pCtx {
		sqlite3_result_error_nomem(p.pCtx)
	}
	json_string_reset(p)
}

@[c:'jsonStringTooDeep']
fn json_string_too_deep(p &JsonString) {
	p.eErr |= 4
	sqlite3_result_error(p.pCtx, c'JSON nested too deep', -1)
	json_string_reset(p)
}

@[c:'jsonStringGrow']
fn json_string_grow(p &JsonString, n u32) int {
	n_total := if U64(n) < p.nAlloc { p.nAlloc * U64(2) } else { p.nAlloc + U64(n) + U64(10) }
	z_new := &i8(0)
	if p.bStatic {
		if p.eErr {
			return 1
		}
		z_new = sqlite3_rc_str_new(n_total)
		if usize(z_new) == usize(0) {
			json_string_oom(p)
			return 7
		}
		C.memcpy(voidptr(z_new), voidptr(p.zBuf), usize(p.nUsed))
		p.zBuf = z_new
		p.bStatic = U8(0)
	} else {
		p.zBuf = sqlite3_rc_str_resize(p.zBuf, n_total)
		if usize(p.zBuf) == usize(0) {
			p.eErr |= 1
			json_string_zero(p)
			return 7
		}
	}
	p.nAlloc = n_total
	return 0
}

@[c:'jsonStringExpandAndAppend']
fn json_string_expand_and_append(p &JsonString, z_in &i8, n u32) {
	if json_string_grow(p, n) {
		return
	}
	C.memcpy(voidptr(p.zBuf + p.nUsed), voidptr(z_in), u64(n))
	p.nUsed += U64(n)
}

@[c:'jsonAppendRaw']
fn json_append_raw(p &JsonString, z_in &i8, n u32) {
	if n == u32(0) {
		return
	}
	if U64(n) + p.nUsed >= p.nAlloc {
		json_string_expand_and_append(p, z_in, n)
	} else {
		C.memcpy(voidptr(p.zBuf + p.nUsed), voidptr(z_in), u64(n))
		p.nUsed += U64(n)
	}
}

@[c:'jsonAppendRawNZ']
fn json_append_raw_nz(p &JsonString, z_in &i8, n u32) {
	if U64(n) + p.nUsed >= p.nAlloc {
		json_string_expand_and_append(p, z_in, n)
	} else {
		C.memcpy(voidptr(p.zBuf + p.nUsed), voidptr(z_in), u64(n))
		p.nUsed += U64(n)
	}
}

@[c:'jsonPrintf']
@[c2v_variadic]
fn json_printf(n int, p &JsonString, z_format &i8, ...) {
	ap := C.va_list{}
	if (p.nUsed + U64(n) >= p.nAlloc) && json_string_grow(p, u32(n)) {
		return
	}
	C.va_start(ap, z_format)
	sqlite3_vsnprintf(n, p.zBuf + p.nUsed, z_format, ap)
	C.va_end(ap)
	p.nUsed += U64(int(C.strlen(p.zBuf + p.nUsed)))
}

@[c:'jsonAppendCharExpand']
fn json_append_char_expand(p &JsonString, c i8) {
	if json_string_grow(p, u32(1)) {
		return
	}
	p.zBuf[p.nUsed++] = c
}

@[c:'jsonAppendChar']
fn json_append_char(p &JsonString, c i8) {
	if p.nUsed >= p.nAlloc {
		json_append_char_expand(p, i8(c))
	} else {
		p.zBuf[p.nUsed++] = c
	}
}

@[c:'jsonStringTrimOneChar']
fn json_string_trim_one_char(p &JsonString) {
	if int(p.eErr) == 0 {
		p.nUsed--
	}
}

@[c:'jsonStringTerminate']
fn json_string_terminate(p &JsonString) int {
	json_append_char(p, i8(0))
	json_string_trim_one_char(p)
	return int(p.eErr == 0)
}

@[c:'jsonAppendSeparator']
fn json_append_separator(p &JsonString) {
	c := i8(0)
	if p.nUsed == U64(0) {
		return
	}
	c = p.zBuf[p.nUsed - U64(1)]
	if int(c) == i8(`[`) || int(c) == i8(`{`) {
		return
	}
	json_append_char(p, i8(`,`))
}

@[c:'jsonAppendControlChar']
fn json_append_control_char(p &JsonString, c U8) {
	if !json_append_control_char_a_special_inited {
		c2v_static_init := [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(`b`), i8(`t`),
			i8(`n`), i8(0), i8(`f`), i8(`r`), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
			i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			json_append_control_char_a_special[c2v_i_0] = c2v_element_0
		}
		json_append_control_char_a_special_inited = true
	}

	if json_append_control_char_a_special[c] {
		p.zBuf[p.nUsed] = i8(`\\`)
		p.zBuf[p.nUsed + U64(1)] = json_append_control_char_a_special[c]
		p.nUsed += U64(2)
	} else {
		p.zBuf[p.nUsed] = i8(`\\`)
		p.zBuf[p.nUsed + U64(1)] = i8(`u`)
		p.zBuf[p.nUsed + U64(2)] = i8(`0`)
		p.zBuf[p.nUsed + U64(3)] = i8(`0`)
		p.zBuf[p.nUsed + U64(4)] = c'0123456789abcdef'[int(c) >> 4]
		p.zBuf[p.nUsed + U64(5)] = c'0123456789abcdef'[int(c) & 15]
		p.nUsed += U64(6)
	}
}

@[c:'jsonAppendString']
fn json_append_string(p &JsonString, z_in &i8, n u32) {
	k := u32(0)
	c := U8(0)
	z := &U8(voidptr(z_in))
	if usize(z) == usize(0) {
		return
	}
	if (U64(n) + p.nUsed + U64(2) >= p.nAlloc) && json_string_grow(p, n + u32(2)) != 0 {
		return
	}
	p.zBuf[p.nUsed++] = i8(`\"`)
	for {
		k = u32(0)
		for {
			if k + u32(3) >= n {
				for k < n && int(json_is_ok[z[k]]) {
					k++
				}
				break
			}
			if !json_is_ok[z[k]] {
				break
			}
			if !json_is_ok[z[k + u32(1)]] {
				k += u32(1)
				break
			}
			if !json_is_ok[z[k + u32(2)]] {
				k += u32(2)
				break
			}
			if !json_is_ok[z[k + u32(3)]] {
				k += u32(3)
				break
			} else {
				k += u32(4)
			}
		}
		if k >= n {
			if k > u32(0) {
				C.memcpy(voidptr(unsafe { p.zBuf + p.nUsed }), voidptr(z), u64(k))
				p.nUsed += U64(k)
			}
			break
		}
		if k > u32(0) {
			C.memcpy(voidptr(unsafe { p.zBuf + p.nUsed }), voidptr(z), u64(k))
			p.nUsed += U64(k)
			c2v_pointer_prefix(voidptr(&z), z, isize(k))
			n -= k
		}
		c = z[0]
		if int(c) == `\"` || int(c) == `\\` {
			if (p.nUsed + U64(n) + U64(3) > p.nAlloc) && json_string_grow(p, n + u32(3)) != 0 {
				return
			}
			p.zBuf[p.nUsed++] = i8(`\\`)
			p.zBuf[p.nUsed++] = i8(c)
		} else if int(c) == `\'` {
			p.zBuf[p.nUsed++] = i8(c)
		} else {
			if (p.nUsed + U64(n) + U64(7) > p.nAlloc) && json_string_grow(p, n + u32(7)) != 0 {
				return
			}
			json_append_control_char(p, c)
		}
		c2v_pointer_postfix(voidptr(&z), z, isize(1))
		n--
	}
	p.zBuf[p.nUsed++] = i8(`\"`)
}

@[c:'jsonAppendSqlValue']
fn json_append_sql_value(p &JsonString, p_value &Sqlite3_value) {
	match sqlite3_value_type(p_value) {
		5 {
			json_append_raw_nz(p, c'null', u32(4))
		}
		2 {
			json_printf(100, p, c'%!0.17g', sqlite3_value_double(p_value))
		}
		1 {
			z := &i8(voidptr(sqlite3_value_text(p_value)))
			n := u32(sqlite3_value_bytes(p_value))
			json_append_raw(p, z, n)
		}
		3 {
			z := &i8(voidptr(sqlite3_value_text(p_value)))
			n := u32(sqlite3_value_bytes(p_value))
			if sqlite3_value_subtype(p_value) == u32(74) {
				json_append_raw(p, z, n)
			} else {
				json_append_string(p, z, n)
			}
		}
		else {
			px := JsonParse{}
			C.memset(voidptr(&px), 0, sizeof(px))
			if json_arg_is_jsonb(p_value, &px) {
				json_translate_blob_to_text(&px, u32(0), p)
			} else if int(p.eErr) == 0 {
				sqlite3_result_error(p.pCtx, c'JSON cannot hold BLOB values', -1)
				p.eErr = U8(8)
				json_string_reset(p)
			}
		}
	}
}

@[c:'jsonReturnString']
fn json_return_string(p &JsonString, p_parse &JsonParse, ctx &Sqlite3_context) {
	json_string_terminate(p)
	if int(p.eErr) == 0 {
		flags := (int(i64(sqlite3_user_data(p.pCtx))))
		if flags & 16 {
			json_return_string_as_blob(p)
		} else if p.bStatic {
			sqlite3_result_text64(p.pCtx, p.zBuf, p.nUsed, (C2vFn_666e2028766f696470747229(voidptr(-1))), u8(1))
		} else {
			if !isnil(p_parse) && int(p_parse.bJsonIsRCStr) == 0 && p_parse.nBlobAlloc > u32(0) {
				rc := 0
				p_parse.zJson = sqlite3_rc_str_ref(p.zBuf)
				p_parse.nJson = int(p.nUsed)
				p_parse.bJsonIsRCStr = U8(1)
				rc = json_cache_insert(ctx, p_parse)
				if rc == 7 {
					sqlite3_result_error_nomem(ctx)
					json_string_reset(p)
					return
				}
			}
			sqlite3_result_text64(p.pCtx, sqlite3_rc_str_ref(p.zBuf), p.nUsed, sqlite3_rc_str_unref, u8(1))
		}
	} else if int(p.eErr) & 1 {
		sqlite3_result_error_nomem(p.pCtx)
	} else if int(p.eErr) & 4 {
	} else if int(p.eErr) & 2 {
		sqlite3_result_error(p.pCtx, c'malformed JSON', -1)
	}
	json_string_reset(p)
}

@[c:'jsonParseReset']
fn json_parse_reset(p_parse &JsonParse) {
	if p_parse.bJsonIsRCStr {
		sqlite3_rc_str_unref(voidptr(p_parse.zJson))
		p_parse.zJson = 0
		p_parse.nJson = 0
		p_parse.bJsonIsRCStr = U8(0)
	}
	if p_parse.nBlobAlloc {
		sqlite3_db_free(p_parse.db, voidptr(p_parse.aBlob))
		p_parse.aBlob = 0
		p_parse.nBlob = u32(0)
		p_parse.nBlobAlloc = u32(0)
	}
}

@[c:'jsonParseFree']
fn json_parse_free(p_parse &JsonParse) {
	if p_parse {
		if p_parse.nJPRef > u32(1) {
			p_parse.nJPRef--
		} else {
			json_parse_reset(p_parse)
			sqlite3_db_free(p_parse.db, voidptr(p_parse))
		}
	}
}

@[c:'jsonHexToInt']
fn json_hex_to_int(h int) U8 {
	h += 9 * (1 & (h >> 6))
	return U8((h & 15))
}

@[c:'jsonHexToInt4']
fn json_hex_to_int4(z &i8) u32 {
	v := u32(0)
	v = u32((int(json_hex_to_int(z[0])) << 12) + (int(json_hex_to_int(z[1])) << 8) + (int(json_hex_to_int(z[2])) << 4) + int(json_hex_to_int(z[3])))
	return v
}

@[c:'jsonIs2Hex']
fn json_is2_hex(z &i8) int {
	return int((int(sqlite3CtypeMap[u8(z[0])]) & 8) && (int(sqlite3CtypeMap[u8(z[1])]) & 8))
}

@[c:'jsonIs4Hex']
fn json_is4_hex(z &i8) int {
	return int(json_is2_hex(z) && json_is2_hex(unsafe { z + 2 }))
}

@[c:'json5Whitespace']
fn json5_whitespace(z_in &i8) int {
	n := 0
	z := &U8(voidptr(z_in))
	for {
		match z[n] {
			9, 10, 11, 12, 13, 32 {
				n++
			}
			`/` {
				if int(z[n + 1]) == `*` && int(z[n + 2]) != 0 {
					j := 0
					for j = n + 3; int(z[j]) != `/` || int(z[j - 1]) != `*`; j++ {
						if int(z[j]) == 0 {
							unsafe { goto whitespace_done
							 }
						}
					}
					n = j + 1
					unsafe { goto c2v_switch_end_80
					 }
				} else if int(z[n + 1]) == `/` {
					j := 0
					c := i8(0)
					for j = n + 2; true; j++ {
						c = i8(z[j])
						if !(int(c) != 0) {
							break
						}
						if int(c) == i8(`\n`) || int(c) == i8(`\r`) {
							break
						}
						if 226 == int(U8(c)) && 128 == int(U8(z[j + 1])) && (168 == int(U8(z[j + 2])) || 169 == int(U8(z[j + 2]))) {
							j += 2
							break
						}
					}
					n = j
					if z[n] {
						n++
					}
					unsafe { goto c2v_switch_end_80
					 }
				}
				unsafe { goto whitespace_done
				 }
			}
			194 {
				if int(z[n + 1]) == 160 {
					n += 2
					unsafe { goto c2v_switch_end_80
					 }
				}
				unsafe { goto whitespace_done
				 }
			}
			225 {
				if int(z[n + 1]) == 154 && int(z[n + 2]) == 128 {
					n += 3
					unsafe { goto c2v_switch_end_80
					 }
				}
				unsafe { goto whitespace_done
				 }
			}
			226 {
				if int(z[n + 1]) == 128 {
					c := z[n + 2]
					if int(c) < 128 {
						unsafe { goto whitespace_done
						 }
					}
					if int(c) <= 138 || int(c) == 168 || int(c) == 169 || int(c) == 175 {
						n += 3
						unsafe { goto c2v_switch_end_80
						 }
					}
				} else if int(z[n + 1]) == 129 && int(z[n + 2]) == 159 {
					n += 3
					unsafe { goto c2v_switch_end_80
					 }
				}
				unsafe { goto whitespace_done
				 }
			}
			227 {
				if int(z[n + 1]) == 128 && int(z[n + 2]) == 128 {
					n += 3
					unsafe { goto c2v_switch_end_80
					 }
				}
				unsafe { goto whitespace_done
				 }
			}
			239 {
				if int(z[n + 1]) == 187 && int(z[n + 2]) == 191 {
					n += 3
					unsafe { goto c2v_switch_end_80
					 }
				}
				unsafe { goto whitespace_done
				 }
			}
			else {
				unsafe { goto whitespace_done
				 }
			}
		}
		c2v_switch_end_80:
	}
	whitespace_done:
	return n
}

struct NanInfName {
	c1     i8
	c2     i8
	n      i8
	eType  i8
	nRepl  i8
	zMatch &i8
	zRepl  &i8
}

@[c:'jsonWrongNumArgs']
fn json_wrong_num_args(p_ctx &Sqlite3_context, z_func_name &i8) {
	z_msg := sqlite3_mprintf(c'json_%s() needs an odd number of arguments', voidptr(z_func_name))
	sqlite3_result_error(p_ctx, z_msg, -1)
	sqlite3_free(voidptr(z_msg))
}

@[c:'jsonBlobExpand']
fn json_blob_expand(p_parse &JsonParse, n u32) int {
	a_new := &U8(0)
	t := U64(0)
	if p_parse.nBlobAlloc == u32(0) {
		t = U64(100)
	} else {
		t = U64(p_parse.nBlobAlloc * u32(2))
	}
	if t < U64(n) {
		t = U64(n + u32(100))
	}
	a_new = sqlite3_db_realloc(p_parse.db, voidptr(p_parse.aBlob), t)
	if usize(a_new) == usize(0) {
		p_parse.oom = U8(1)
		return 1
	}
	p_parse.aBlob = a_new
	p_parse.nBlobAlloc = u32(t)
	return 0
}

@[c:'jsonBlobMakeEditable']
fn json_blob_make_editable(p_parse &JsonParse, n_extra u32) int {
	a_old := &U8(0)
	n_size := u32(0)
	if p_parse.oom {
		return 0
	}
	if p_parse.nBlobAlloc > u32(0) {
		return 1
	}
	a_old = p_parse.aBlob
	n_size = p_parse.nBlob + n_extra
	p_parse.aBlob = 0
	if json_blob_expand(p_parse, n_size) {
		return 0
	}
	C.memcpy(voidptr(p_parse.aBlob), voidptr(a_old), u64(p_parse.nBlob))
	return 1
}

@[c:'jsonBlobExpandAndAppendOneByte']
fn json_blob_expand_and_append_one_byte(p_parse &JsonParse, c U8) {
	json_blob_expand(p_parse, p_parse.nBlob + u32(1))
	if int(p_parse.oom) == 0 {
		p_parse.aBlob[p_parse.nBlob++] = c
	}
}

@[c:'jsonBlobAppendOneByte']
fn json_blob_append_one_byte(p_parse &JsonParse, c U8) {
	if p_parse.nBlob >= p_parse.nBlobAlloc {
		json_blob_expand_and_append_one_byte(p_parse, c)
	} else {
		p_parse.aBlob[p_parse.nBlob++] = c
	}
}

@[c:'jsonBlobExpandAndAppendNode']
fn json_blob_expand_and_append_node(p_parse &JsonParse, e_type U8, sz_payload U64, a_payload voidptr) {
	if json_blob_expand(p_parse, u32(U64(p_parse.nBlob) + sz_payload + U64(9))) {
		return
	}
	json_blob_append_node(p_parse, e_type, sz_payload, voidptr(a_payload))
}

@[c:'jsonBlobAppendNode']
fn json_blob_append_node(p_parse &JsonParse, e_type U8, sz_payload U64, a_payload voidptr) {
	a := &U8(0)
	if U64(p_parse.nBlob) + sz_payload + U64(9) > U64(p_parse.nBlobAlloc) {
		json_blob_expand_and_append_node(p_parse, e_type, sz_payload, voidptr(a_payload))
		return
	}
	a = unsafe { p_parse.aBlob + p_parse.nBlob }
	if sz_payload <= U64(11) {
		a[0] = U8(U64(e_type) | (sz_payload << 4))
		p_parse.nBlob += u32(1)
	} else if sz_payload <= U64(255) {
		a[0] = U8(int(e_type) | 192)
		a[1] = U8(sz_payload & U64(255))
		p_parse.nBlob += u32(2)
	} else if sz_payload <= U64(65535) {
		a[0] = U8(int(e_type) | 208)
		a[1] = U8((sz_payload >> 8) & U64(255))
		a[2] = U8(sz_payload & U64(255))
		p_parse.nBlob += u32(3)
	} else {
		a[0] = U8(int(e_type) | 224)
		a[1] = U8((sz_payload >> 24) & U64(255))
		a[2] = U8((sz_payload >> 16) & U64(255))
		a[3] = U8((sz_payload >> 8) & U64(255))
		a[4] = U8(sz_payload & U64(255))
		p_parse.nBlob += u32(5)
	}
	if a_payload {
		p_parse.nBlob += sz_payload
		C.memcpy(voidptr(unsafe { p_parse.aBlob + (U64(p_parse.nBlob) - sz_payload) }), voidptr(a_payload), u64(sz_payload))
	}
}

@[c:'jsonBlobChangePayloadSize']
fn json_blob_change_payload_size(p_parse &JsonParse, i u32, sz_payload u32) int {
	a := &U8(0)
	sz_type := U8(0)
	n_extra := U8(0)
	n_needed := U8(0)
	delta := 0
	if p_parse.oom {
		return 0
	}
	a = unsafe { p_parse.aBlob + i }
	sz_type = U8(int(a[0]) >> 4)
	if int(sz_type) <= 11 {
		n_extra = U8(0)
	} else if int(sz_type) == 12 {
		n_extra = U8(1)
	} else if int(sz_type) == 13 {
		n_extra = U8(2)
	} else if int(sz_type) == 14 {
		n_extra = U8(4)
	} else {
		n_extra = U8(8)
	}
	if sz_payload <= u32(11) {
		n_needed = U8(0)
	} else if sz_payload <= u32(255) {
		n_needed = U8(1)
	} else if sz_payload <= u32(65535) {
		n_needed = U8(2)
	} else {
		n_needed = U8(4)
	}
	delta = int(n_needed) - int(n_extra)
	if delta {
		new_size := p_parse.nBlob + u32(delta)
		if delta > 0 {
			if new_size > p_parse.nBlobAlloc && json_blob_expand(p_parse, new_size) {
				return 0
			}
			a = unsafe { p_parse.aBlob + i }
			C.memmove(voidptr(unsafe { a + (1 + delta) }), voidptr(unsafe { a + 1 }), u64(p_parse.nBlob - (i + u32(1))))
		} else {
			C.memmove(voidptr(unsafe { a + 1 }), voidptr(unsafe { a + (1 - delta) }), u64(p_parse.nBlob - (i + u32(1) - u32(delta))))
		}
		p_parse.nBlob = new_size
	}
	if int(n_needed) == 0 {
		a[0] = U8(u32((int(a[0]) & 15)) | (sz_payload << 4))
	} else if int(n_needed) == 1 {
		a[0] = U8((int(a[0]) & 15) | 192)
		a[1] = U8(sz_payload & u32(255))
	} else if int(n_needed) == 2 {
		a[0] = U8((int(a[0]) & 15) | 208)
		a[1] = U8((sz_payload >> 8) & u32(255))
		a[2] = U8(sz_payload & u32(255))
	} else {
		a[0] = U8((int(a[0]) & 15) | 224)
		a[1] = U8((sz_payload >> 24) & u32(255))
		a[2] = U8((sz_payload >> 16) & u32(255))
		a[3] = U8((sz_payload >> 8) & u32(255))
		a[4] = U8(sz_payload & u32(255))
	}
	return delta
}

@[c:'jsonIs4HexB']
fn json_is4_hex_b(z &i8, p_op &int) int {
	if int(z[0]) != i8(`u`) {
		return 0
	}
	if !json_is4_hex(unsafe { z + 1 }) {
		return 0
	}
	unsafe { *p_op = 8 }
	return 1
}

@[c:'jsonbValidityCheck']
fn jsonb_validity_check(p_parse &JsonParse, i u32, i_end u32, i_depth u32) u32 {
	n := u32(0)
	sz := u32(0)
	j := u32(0)
	k := u32(0)

	z := &U8(0)
	x := U8(0)
	if i_depth > u32(1000) {
		return i + u32(1)
	}
	sz = u32(0)
	n = jsonb_payload_size(p_parse, i, &sz)
	if (n == u32(0)) {
		return i + u32(1)
	}
	if (i + n + sz != i_end) {
		return i + u32(1)
	}
	z = p_parse.aBlob
	x = U8(int(z[i]) & 15)
	match x {
		0, 1, 2 {
			return if n + sz == u32(1) { u32(0) } else { i + u32(1) }
		}
		3 {
			if sz < u32(1) {
				return i + u32(1)
			}
			j = i + n
			if int(z[j]) == `-` {
				j++
				if sz < u32(2) {
					return i + u32(1)
				}
			}
			k = i + n + sz
			for j < k {
				if (int(sqlite3CtypeMap[u8(z[j])]) & 4) {
					j++
				} else {
					return j + u32(1)
				}
			}
			return u32(0)
		}
		4 {
			if sz < u32(3) {
				return i + u32(1)
			}
			j = i + n
			if int(z[j]) == `-` {
				if sz < u32(4) {
					return i + u32(1)
				}
				j++
			}
			if int(z[j]) != `0` {
				return i + u32(1)
			}
			if int(z[j + u32(1)]) != `x` && int(z[j + u32(1)]) != `X` {
				return j + u32(2)
			}
			j += u32(2)
			k = i + n + sz
			for j < k {
				if (int(sqlite3CtypeMap[u8(z[j])]) & 8) {
					j++
				} else {
					return j + u32(1)
				}
			}
			return u32(0)
		}
		5, 6 {
			seen := U8(0)
			if sz < u32(2) {
				return i + u32(1)
			}
			j = i + n
			k = j + sz
			if int(z[j]) == `-` {
				j++
				if sz < u32(3) {
					return i + u32(1)
				}
			}
			if int(z[j]) == `.` {
				if int(x) == 5 {
					return j + u32(1)
				}
				if !(int(sqlite3CtypeMap[u8(z[j + u32(1)])]) & 4) {
					return j + u32(1)
				}
				j += u32(2)
				seen = U8(1)
			} else if int(z[j]) == `0` && int(x) == 5 {
				if j + u32(3) > k {
					return j + u32(1)
				}
				if int(z[j + u32(1)]) != `.` && int(z[j + u32(1)]) != `e` && int(z[j + u32(1)]) != `E` {
					return j + u32(1)
				}
				j++
			}
			for ; j < k; j++ {
				if (int(sqlite3CtypeMap[u8(z[j])]) & 4) {
					continue
				}
				if int(z[j]) == `.` {
					if int(seen) > 0 {
						return j + u32(1)
					}
					if int(x) == 5 && (j == k - u32(1) || !(int(sqlite3CtypeMap[u8(z[j + u32(1)])]) & 4)) {
						return j + u32(1)
					}
					seen = U8(1)
					continue
				}
				if int(z[j]) == `e` || int(z[j]) == `E` {
					if int(seen) == 2 {
						return j + u32(1)
					}
					if j == k - u32(1) {
						return j + u32(1)
					}
					if int(z[j + u32(1)]) == `+` || int(z[j + u32(1)]) == `-` {
						j++
						if j == k - u32(1) {
							return j + u32(1)
						}
					}
					seen = U8(2)
					continue
				}
				return j + u32(1)
			}
			if int(seen) == 0 {
				return i + u32(1)
			}
			return u32(0)
		}
		7 {
			j = i + n
			k = j + sz
			for j < k {
				if !json_is_ok[z[j]] && int(z[j]) != `\'` {
					return j + u32(1)
				}
				j++
			}
			return u32(0)
		}
		8, 9 {
			j = i + n
			k = j + sz
			for j < k {
				if !json_is_ok[z[j]] && int(z[j]) != `\'` {
					if int(z[j]) == `\"` {
						if int(x) == 8 {
							return j + u32(1)
						}
					} else if int(z[j]) <= 31 {
						if int(x) == 8 {
							return j + u32(1)
						}
					} else if (int(z[j]) != `\\`) || j + u32(1) >= k {
						return j + u32(1)
					} else if usize(C.strchr(c'"\\/bfnrt', int(z[j + u32(1)]))) != usize(0) {
						j++
					} else if int(z[j + u32(1)]) == `u` {
						if j + u32(5) >= k {
							return j + u32(1)
						}
						if !json_is4_hex(&i8(voidptr(unsafe { z + (j + u32(2)) }))) {
							return j + u32(1)
						}
						j++
					} else if int(x) != 9 {
						return j + u32(1)
					} else {
						c := u32(0)
						sz_c := json_unescape_one_char(&i8(voidptr(unsafe { z + j })), k - j, &c)
						if c == u32(629145) {
							return j + u32(1)
						}
						j += sz_c - u32(1)
					}
				}
				j++
			}
			return u32(0)
		}
		10 {
			return u32(0)
		}
		11 {
			sub := u32(0)
			j = i + n
			k = j + sz
			for j < k {
				sz = u32(0)
				n = jsonb_payload_size(p_parse, j, &sz)
				if n == u32(0) {
					return j + u32(1)
				}
				if j + n + sz > k {
					return j + u32(1)
				}
				sub = jsonb_validity_check(p_parse, j, j + n + sz, i_depth + u32(1))
				if sub {
					return sub
				}
				j += n + sz
			}
			return u32(0)
		}
		12 {
			cnt := u32(0)
			sub := u32(0)
			j = i + n
			k = j + sz
			for j < k {
				sz = u32(0)
				n = jsonb_payload_size(p_parse, j, &sz)
				if n == u32(0) {
					return j + u32(1)
				}
				if j + n + sz > k {
					return j + u32(1)
				}
				if (cnt & u32(1)) == u32(0) {
					x = U8(int(z[j]) & 15)
					if int(x) < 7 || int(x) > 10 {
						return j + u32(1)
					}
				}
				sub = jsonb_validity_check(p_parse, j, j + n + sz, i_depth + u32(1))
				if sub {
					return sub
				}
				cnt++
				j += n + sz
			}
			if (cnt & u32(1)) != u32(0) {
				return j + u32(1)
			}
			return u32(0)
		}
		else {
			return i + u32(1)
		}
	}
	return u32(0)
}

@[c:'jsonTranslateTextToBlob']
fn json_translate_text_to_blob(p_parse &JsonParse, i u32) int {
	c := i8(0)
	j := u32(0)
	i_this := u32(0)
	i_start := u32(0)

	x := 0
	t := U8(0)
	z := p_parse.zJson
	json_parse_restart:
	opcode := U8(0)
	c_delim := i8(0)
	seen_e := U8(0)
	match U8(z[i]) {
		`{` {
			i_this = p_parse.nBlob
			json_blob_append_node(p_parse, U8(12), U64(u32(p_parse.nJson) - i), unsafe { nil })
			p_parse.iDepth++
			if int(p_parse.iDepth) > 1000 {
				p_parse.iErr = i
				return -1
			}
			i_start = p_parse.nBlob
			for j = i + u32(1); ; j++ {
				i_blob := p_parse.nBlob
				x = json_translate_text_to_blob(p_parse, j)
				if x <= 0 {
					op := 0
					if x == (-2) {
						j = p_parse.iErr
						if p_parse.nBlob != u32(i_start) {
							p_parse.hasNonstd = U8(1)
						}
						break
					}
					j += u32(json5_whitespace(unsafe { z + j }))
					op = 7
					if (int(sqlite3CtypeMap[u8(z[j])]) & 66) || (int(z[j]) == i8(`\\`) && json_is4_hex_b(unsafe { z + (j + u32(1)) }, &op)) {
						k := int(j + u32(1))
						for ((int(sqlite3CtypeMap[u8(z[k])]) & 70) && json5_whitespace(unsafe { z + k }) == 0) || (int(z[k]) == i8(`\\`) && json_is4_hex_b(unsafe { z + (k + 1) }, &op)) {
							k++
						}
						json_blob_append_node(p_parse, U8(op), U64(u32(k) - j), voidptr(unsafe { z + j }))
						p_parse.hasNonstd = U8(1)
						x = k
					} else {
						if x != -1 {
							p_parse.iErr = j
						}
						return -1
					}
				}
				if p_parse.oom {
					return -1
				}
				t = U8(int(p_parse.aBlob[i_blob]) & 15)
				if int(t) < 7 || int(t) > 10 {
					p_parse.iErr = j
					return -1
				}
				j = u32(x)
				if int(z[j]) == i8(`:`) {
					j++
				} else {
					if json_is_space[u8(z[j])] {
						for {
							j++
							if !(json_is_space[u8(z[j])]) {
								break
							}
						}
						if int(z[j]) == i8(`:`) {
							j++
							unsafe { goto parse_object_value
							 }
						}
					}
					x = json_translate_text_to_blob(p_parse, j)
					if x != (-5) {
						if x != (-1) {
							p_parse.iErr = j
						}
						return -1
					}
					j = p_parse.iErr + u32(1)
				}
				parse_object_value:
				x = json_translate_text_to_blob(p_parse, j)
				if x <= 0 {
					if x != (-1) {
						p_parse.iErr = j
					}
					return -1
				}
				j = u32(x)
				if int(z[j]) == i8(`,`) {
					continue
				} else if int(z[j]) == i8(`}`) {
					break
				} else {
					if json_is_space[u8(z[j])] {
						j += u32(1) + u32(C.strspn(unsafe { z + (j + u32(1)) }, unsafe { &i8(&jsonSpaces[0]) }))
						if int(z[j]) == i8(`,`) {
							continue
						} else if int(z[j]) == i8(`}`) {
							break
						}
					}
					x = json_translate_text_to_blob(p_parse, j)
					if x == (-4) {
						j = p_parse.iErr
						continue
					}
					if x == (-2) {
						j = p_parse.iErr
						break
					}
				}
				p_parse.iErr = j
				return -1
			}
			json_blob_change_payload_size(p_parse, i_this, p_parse.nBlob - i_start)
			p_parse.iDepth--
			return int(j + u32(1))
		}
		`[` {
			i_this = p_parse.nBlob
			json_blob_append_node(p_parse, U8(11), U64(u32(p_parse.nJson) - i), unsafe { nil })
			i_start = p_parse.nBlob
			if p_parse.oom {
				return -1
			}
			p_parse.iDepth++
			if int(p_parse.iDepth) > 1000 {
				p_parse.iErr = i
				return -1
			}
			for j = i + u32(1); ; j++ {
				x = json_translate_text_to_blob(p_parse, j)
				if x <= 0 {
					if x == (-3) {
						j = p_parse.iErr
						if p_parse.nBlob != i_start {
							p_parse.hasNonstd = U8(1)
						}
						break
					}
					if x != (-1) {
						p_parse.iErr = j
					}
					return -1
				}
				j = u32(x)
				if int(z[j]) == i8(`,`) {
					continue
				} else if int(z[j]) == i8(`]`) {
					break
				} else {
					if json_is_space[u8(z[j])] {
						j += u32(1) + u32(C.strspn(unsafe { z + (j + u32(1)) }, unsafe { &i8(&jsonSpaces[0]) }))
						if int(z[j]) == i8(`,`) {
							continue
						} else if int(z[j]) == i8(`]`) {
							break
						}
					}
					x = json_translate_text_to_blob(p_parse, j)
					if x == (-4) {
						j = p_parse.iErr
						continue
					}
					if x == (-3) {
						j = p_parse.iErr
						break
					}
				}
				p_parse.iErr = j
				return -1
			}
			json_blob_change_payload_size(p_parse, i_this, p_parse.nBlob - i_start)
			p_parse.iDepth--
			return int(j + u32(1))
		}
		`\'` {
			p_parse.hasNonstd = U8(1)
			opcode = U8(7)
			unsafe { goto parse_string
			 }
		}
		`\"` {
			opcode = U8(7)
			parse_string:
			c_delim = z[i]
			j = i + u32(1)
			for {
				if json_is_ok[U8(z[j])] {
					if !json_is_ok[U8(z[j + u32(1)])] {
						j += u32(1)
					} else if !json_is_ok[U8(z[j + u32(2)])] {
						j += u32(2)
					} else {
						j += u32(3)
						continue
					}
				}
				c = z[j]
				if int(c) == int(c_delim) {
					break
				} else if int(c) == i8(`\\`) {
					c = z[c2v_prefix_add(unsafe { &j }, u32(1))]
					mut __c2v_condition_153 := false
					mut __c2v_condition_154 := false
					__c2v_condition_154 = int(c) == i8(`\"`)
					__c2v_condition_153 = __c2v_condition_154
					if !__c2v_condition_153 {
						mut __c2v_condition_155 := false
						__c2v_condition_155 = int(c) == i8(`\\`)
						__c2v_condition_153 = __c2v_condition_155
					}
					if !__c2v_condition_153 {
						mut __c2v_condition_156 := false
						__c2v_condition_156 = int(c) == i8(`/`)
						__c2v_condition_153 = __c2v_condition_156
					}
					if !__c2v_condition_153 {
						mut __c2v_condition_157 := false
						__c2v_condition_157 = int(c) == i8(`b`)
						__c2v_condition_153 = __c2v_condition_157
					}
					if !__c2v_condition_153 {
						mut __c2v_condition_158 := false
						__c2v_condition_158 = int(c) == i8(`f`)
						__c2v_condition_153 = __c2v_condition_158
					}
					if !__c2v_condition_153 {
						mut __c2v_condition_159 := false
						__c2v_condition_159 = int(c) == i8(`n`)
						__c2v_condition_153 = __c2v_condition_159
					}
					if !__c2v_condition_153 {
						mut __c2v_condition_160 := false
						__c2v_condition_160 = int(c) == i8(`r`)
						__c2v_condition_153 = __c2v_condition_160
					}
					if !__c2v_condition_153 {
						mut __c2v_condition_161 := false
						__c2v_condition_161 = int(c) == i8(`t`)
						__c2v_condition_153 = __c2v_condition_161
					}
					if !__c2v_condition_153 {
						mut __c2v_condition_162 := false
						__c2v_condition_162 = (int(c) == i8(`u`) && json_is4_hex(unsafe { z + (j + u32(1)) }))
						__c2v_condition_153 = __c2v_condition_162
					}
					if __c2v_condition_153 {
						if int(opcode) == 7 {
							opcode = U8(8)
						}
					} else if int(c) == i8(`\'`) || int(c) == i8(`v`) || int(c) == i8(`\n`) || (int(c) == i8(`0`) && !(int(sqlite3CtypeMap[u8(z[j + u32(1)])]) & 4)) || (226 == int(U8(c)) && 128 == int(U8(z[j + u32(1)])) && (168 == int(U8(z[j + u32(2)])) || 169 == int(U8(z[j + u32(2)])))) || (int(c) == i8(`x`) && json_is2_hex(unsafe { z + (j + u32(1)) })) {
						opcode = U8(9)
						p_parse.hasNonstd = U8(1)
					} else if int(c) == i8(`\r`) {
						if int(z[j + u32(1)]) == i8(`\n`) {
							j++
						}
						opcode = U8(9)
						p_parse.hasNonstd = U8(1)
					} else {
						p_parse.iErr = j
						return -1
					}
				} else if int(c) <= 31 {
					if int(c) == 0 {
						p_parse.iErr = j
						return -1
					}
					opcode = U8(9)
					p_parse.hasNonstd = U8(1)
				} else if int(c) == i8(`\"`) {
					opcode = U8(9)
				}
				j++
			}
			json_blob_append_node(p_parse, opcode, U64(j - u32(1) - i), voidptr(unsafe { z + (i + u32(1)) }))
			return int(j + u32(1))
		}
		`t` {
			if C.strncmp(z + i, c'true', u64(4)) == 0 && !(int(sqlite3CtypeMap[u8(z[i + u32(4)])]) & 6) {
				json_blob_append_one_byte(p_parse, U8(1))
				return int(i + u32(4))
			}
			p_parse.iErr = i
			return -1
		}
		`f` {
			if C.strncmp(z + i, c'false', u64(5)) == 0 && !(int(sqlite3CtypeMap[u8(z[i + u32(5)])]) & 6) {
				json_blob_append_one_byte(p_parse, U8(2))
				return int(i + u32(5))
			}
			p_parse.iErr = i
			return -1
		}
		`+` {
			p_parse.hasNonstd = U8(1)
			t = U8(0)
			unsafe { goto parse_number
			 }
		}
		`.` {
			if (int(sqlite3CtypeMap[u8(z[i + u32(1)])]) & 4) {
				p_parse.hasNonstd = U8(1)
				t = U8(3)
				seen_e = U8(0)
				unsafe { goto parse_number_2
				 }
			}
			p_parse.iErr = i
			return -1
		}
		`-`, `0`, `1`, `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9` {
			t = U8(0)
			parse_number:
			seen_e = U8(0)
			c = z[i]
			if int(c) <= i8(`0`) {
				if int(c) == i8(`0`) {
					if (int(z[i + u32(1)]) == i8(`x`) || int(z[i + u32(1)]) == i8(`X`)) && (int(sqlite3CtypeMap[u8(z[i + u32(2)])]) & 8) {
						p_parse.hasNonstd = U8(1)
						t = U8(1)
						for j = i + u32(3); (int(sqlite3CtypeMap[u8(z[j])]) & 8); j++ {
						}
						unsafe { goto parse_number_finish
						 }
					} else if (int(sqlite3CtypeMap[u8(z[i + u32(1)])]) & 4) {
						p_parse.iErr = i + u32(1)
						return -1
					}
				} else {
					if !(int(sqlite3CtypeMap[u8(z[i + u32(1)])]) & 4) {
						if (int(z[i + u32(1)]) == i8(`I`) || int(z[i + u32(1)]) == i8(`i`)) && sqlite3_strnicmp(unsafe { z + (i + u32(1)) }, c'inf', 3) == 0 {
							p_parse.hasNonstd = U8(1)
							if int(z[i]) == i8(`-`) {
								json_blob_append_node(p_parse, U8(5), U64(6), voidptr(c'-9e999'))
							} else {
								json_blob_append_node(p_parse, U8(5), U64(5), voidptr(c'9e999'))
							}
							return int(i + u32((if sqlite3_strnicmp(unsafe { z + (i + u32(4)) }, c'inity', 5) == 0 {
								9
							} else {
								4
							})))
						}
						if int(z[i + u32(1)]) == i8(`.`) {
							p_parse.hasNonstd = U8(1)
							t |= 1
							unsafe { goto parse_number_2
							 }
						}
						p_parse.iErr = i
						return -1
					}
					if int(z[i + u32(1)]) == i8(`0`) {
						if (int(sqlite3CtypeMap[u8(z[i + u32(2)])]) & 4) {
							p_parse.iErr = i + u32(1)
							return -1
						} else if (int(z[i + u32(2)]) == i8(`x`) || int(z[i + u32(2)]) == i8(`X`)) && (int(sqlite3CtypeMap[u8(z[i + u32(3)])]) & 8) {
							p_parse.hasNonstd = U8(1)
							t |= 1
							for j = i + u32(4); (int(sqlite3CtypeMap[u8(z[j])]) & 8); j++ {
							}
							unsafe { goto parse_number_finish
							 }
						}
					}
				}
			}
			parse_number_2: for j = i + u32(1); ; j++ {
				c = z[j]
				if (int(sqlite3CtypeMap[u8(c)]) & 4) {
					continue
				}
				if int(c) == i8(`.`) {
					if (int(t) & 2) != 0 {
						p_parse.iErr = j
						return -1
					}
					t |= 2
					continue
				}
				if int(c) == i8(`e`) || int(c) == i8(`E`) {
					if int(z[j - u32(1)]) < i8(`0`) {
						if (int(z[j - u32(1)]) == i8(`.`)) && (j - u32(2) >= i) && (int(sqlite3CtypeMap[u8(z[j - u32(2)])]) & 4) {
							p_parse.hasNonstd = U8(1)
							t |= 1
						} else {
							p_parse.iErr = j
							return -1
						}
					}
					if seen_e {
						p_parse.iErr = j
						return -1
					}
					t |= 2
					seen_e = U8(1)
					c = z[j + u32(1)]
					if int(c) == i8(`+`) || int(c) == i8(`-`) {
						j++
						c = z[j + u32(1)]
					}
					if int(c) < i8(`0`) || int(c) > i8(`9`) {
						p_parse.iErr = j
						return -1
					}
					continue
				}
				break
			}
			if int(z[j - u32(1)]) < i8(`0`) {
				if (int(z[j - u32(1)]) == i8(`.`)) && (j - u32(2) >= i) && (int(sqlite3CtypeMap[u8(z[j - u32(2)])]) & 4) {
					p_parse.hasNonstd = U8(1)
					t |= 1
				} else {
					p_parse.iErr = j
					return -1
				}
			}
			parse_number_finish:
			if int(z[i]) == i8(`+`) {
				i++
			}
			json_blob_append_node(p_parse, U8(3 + int(t)), U64(j - i), voidptr(unsafe { z + i }))
			return int(j)
		}
		`}` {
			p_parse.iErr = i
			return -2
		}
		`]` {
			p_parse.iErr = i
			return -3
		}
		`,` {
			p_parse.iErr = i
			return -4
		}
		`:` {
			p_parse.iErr = i
			return -5
		}
		0 {
			return 0
		}
		9, 10, 13, 32 {
			i += u32(1) + u32(C.strspn(unsafe { z + (i + u32(1)) }, unsafe { &i8(&jsonSpaces[0]) }))
			unsafe { goto json_parse_restart
			 }
		}
		11, 12, `/`, 194, 225, 226, 227, 239 {
			j = u32(json5_whitespace(unsafe { z + i }))
			if j > u32(0) {
				i += j
				p_parse.hasNonstd = U8(1)
				unsafe { goto json_parse_restart
				 }
			}
			p_parse.iErr = i
			return -1
		}
		`n` {
			if C.strncmp(z + i, c'null', u64(4)) == 0 && !(int(sqlite3CtypeMap[u8(z[i + u32(4)])]) & 6) {
				json_blob_append_one_byte(p_parse, U8(0))
				return int(i + u32(4))
			}

			unsafe { goto c2v_case_82_38
			 }
		}
		else {
			c2v_case_82_38:
			k := u32(0)
			nn := 0
			c = z[i]
			for k = u32(0); u64(k) < 5; k++ {
				if int(c) != int(a_nan_inf_name[k].c1) && int(c) != int(a_nan_inf_name[k].c2) {
					continue
				}
				nn = int(a_nan_inf_name[k].n)
				if sqlite3_strnicmp(unsafe { z + i }, a_nan_inf_name[k].zMatch, nn) != 0 {
					continue
				}
				if (int(sqlite3CtypeMap[u8(z[i + u32(nn)])]) & 6) {
					continue
				}
				if int(a_nan_inf_name[k].eType) == 5 {
					json_blob_append_node(p_parse, U8(5), U64(5), voidptr(c'9e999'))
				} else {
					json_blob_append_one_byte(p_parse, U8(0))
				}
				p_parse.hasNonstd = U8(1)
				return int(i + u32(nn))
			}
			p_parse.iErr = i
			return -1
		}
	}
	return 0
}

@[c:'jsonConvertTextToBlob']
fn json_convert_text_to_blob(p_parse &JsonParse, p_ctx &Sqlite3_context) int {
	i := 0
	z_json := p_parse.zJson
	i = json_translate_text_to_blob(p_parse, u32(0))
	if p_parse.oom {
		i = -1
	}
	if i > 0 {
		for json_is_space[u8(z_json[i])] {
			i++
		}
		if z_json[i] {
			i += json5_whitespace(unsafe { z_json + i })
			if z_json[i] {
				if p_ctx {
					sqlite3_result_error(p_ctx, c'malformed JSON', -1)
				}
				json_parse_reset(p_parse)
				return 1
			}
			p_parse.hasNonstd = U8(1)
		}
	}
	if i <= 0 {
		if usize(p_ctx) != usize(0) {
			if p_parse.oom {
				sqlite3_result_error_nomem(p_ctx)
			} else {
				sqlite3_result_error(p_ctx, c'malformed JSON', -1)
			}
		}
		json_parse_reset(p_parse)
		return 1
	}
	return 0
}

@[c:'jsonReturnStringAsBlob']
fn json_return_string_as_blob(p_str &JsonString) {
	px := JsonParse{}
	C.memset(voidptr(&px), 0, sizeof(px))
	px.zJson = p_str.zBuf
	px.nJson = int(p_str.nUsed)
	px.db = sqlite3_context_db_handle(p_str.pCtx)
	json_translate_text_to_blob(&px, u32(0))
	if px.oom {
		sqlite3_db_free(px.db, voidptr(px.aBlob))
		sqlite3_result_error_nomem(p_str.pCtx)
	} else {
		sqlite3_result_blob(p_str.pCtx, voidptr(px.aBlob), int(px.nBlob), (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))))
	}
}

@[c:'jsonbPayloadSize']
fn jsonb_payload_size(p_parse &JsonParse, i u32, p_sz &u32) u32 {
	x := U8(0)
	sz := u32(0)
	n := u32(0)
	if i >= p_parse.nBlob {
		unsafe { *p_sz = u32(0) }
		return u32(0)
	} else {
		x = U8(int(p_parse.aBlob[i]) >> 4)
		if int(x) <= 11 {
			sz = u32(x)
			n = u32(1)
		} else if int(x) == 12 {
			if i + u32(1) >= p_parse.nBlob {
				unsafe { *p_sz = u32(0) }
				return u32(0)
			}
			sz = u32(p_parse.aBlob[i + u32(1)])
			n = u32(2)
		} else if int(x) == 13 {
			if i + u32(2) >= p_parse.nBlob {
				unsafe { *p_sz = u32(0) }
				return u32(0)
			}
			sz = u32((int(p_parse.aBlob[i + u32(1)]) << 8) + int(p_parse.aBlob[i + u32(2)]))
			n = u32(3)
		} else if int(x) == 14 {
			if i + u32(4) >= p_parse.nBlob {
				unsafe { *p_sz = u32(0) }
				return u32(0)
			}
			sz = (u32(p_parse.aBlob[i + u32(1)]) << 24) + u32((int(p_parse.aBlob[i + u32(2)]) << 16)) + u32((int(p_parse.aBlob[i + u32(3)]) << 8)) + u32(p_parse.aBlob[i + u32(4)])
			n = u32(5)
		} else {
			if i + u32(8) >= p_parse.nBlob || int(p_parse.aBlob[i + u32(1)]) != 0 || int(p_parse.aBlob[i + u32(2)]) != 0 || int(p_parse.aBlob[i + u32(3)]) != 0 || int(p_parse.aBlob[i + u32(4)]) != 0 {
				unsafe { *p_sz = u32(0) }
				return u32(0)
			}
			sz = (u32(p_parse.aBlob[i + u32(5)]) << 24) + u32((int(p_parse.aBlob[i + u32(6)]) << 16)) + u32((int(p_parse.aBlob[i + u32(7)]) << 8)) + u32(p_parse.aBlob[i + u32(8)])
			n = u32(9)
		}
	}
	if I64(i) + I64(sz) + I64(n) > I64(p_parse.nBlob) && I64(i) + I64(sz) + I64(n) > I64(p_parse.nBlob - u32(p_parse.delta)) {
		unsafe { *p_sz = u32(0) }
		return u32(0)
	}
	unsafe { *p_sz = sz }
	return n
}

@[c:'jsonTranslateBlobToText']
fn json_translate_blob_to_text(p_parse &JsonParse, i u32, p_out &JsonString) u32 {
	sz := u32(0)
	n := u32(0)
	j := u32(0)
	i_end := u32(0)

	n = jsonb_payload_size(p_parse, i, &sz)
	if n == u32(0) {
		p_out.eErr |= 2
		return p_parse.nBlob + u32(1)
	}
	match (int(p_parse.aBlob[i] & 15)) {
		0 {
			json_append_raw_nz(p_out, c'null', u32(4))
			return i + u32(1)
		}
		1 {
			json_append_raw_nz(p_out, c'true', u32(4))
			return i + u32(1)
		}
		2 {
			json_append_raw_nz(p_out, c'false', u32(5))
			return i + u32(1)
		}
		3, 5 {
			if sz == u32(0) {
				unsafe { goto malformed_jsonb
				 }
			}
			json_append_raw(p_out, &i8(voidptr(unsafe { p_parse.aBlob + (i + n) })), sz)
		}
		4 {
			k := u32(2)
			u := Sqlite3_uint64(0)
			z_in := &i8(voidptr(unsafe { p_parse.aBlob + (i + n) }))
			b_overflow := 0
			if sz == u32(0) {
				unsafe { goto malformed_jsonb
				 }
			}
			if int(z_in[0]) == i8(`-`) {
				json_append_char(p_out, i8(`-`))
				k++
			} else if int(z_in[0]) == i8(`+`) {
				k++
			}
			for ; k < sz; k++ {
				if !(int(sqlite3CtypeMap[u8(z_in[k])]) & 8) {
					p_out.eErr |= 2
					break
				} else if (u >> 60) != Sqlite3_uint64(0) {
					b_overflow = 1
				} else {
					u = u * Sqlite3_uint64(16) + Sqlite3_uint64(sqlite3_hex_to_int(z_in[k]))
				}
			}
			json_printf(100, p_out, unsafe { if b_overflow { c'9.0e999' } else { c'%llu' } }, u)
		}
		6 {
			k := u32(0)
			z_in := &i8(voidptr(unsafe { p_parse.aBlob + (i + n) }))
			if sz == u32(0) {
				unsafe { goto malformed_jsonb
				 }
			}
			if int(z_in[0]) == i8(`-`) {
				json_append_char(p_out, i8(`-`))
				if sz <= u32(1) {
					unsafe { goto malformed_jsonb
					 }
				}
				k = u32(1)
			}
			if int(z_in[k]) == i8(`.`) {
				json_append_char(p_out, i8(`0`))
			}
			for ; k < sz; k++ {
				json_append_char(p_out, i8(z_in[k]))
				if int(z_in[k]) == i8(`.`) && (k + u32(1) == sz || !(int(sqlite3CtypeMap[u8(z_in[k + u32(1)])]) & 4)) {
					json_append_char(p_out, i8(`0`))
				}
			}
		}
		7, 8 {
			if p_out.nUsed + U64(sz) + U64(2) <= p_out.nAlloc || json_string_grow(p_out, sz + u32(2)) == 0 {
				p_out.zBuf[p_out.nUsed] = i8(`\"`)
				C.memcpy(voidptr(p_out.zBuf + p_out.nUsed + 1), voidptr(&i8(voidptr(unsafe { p_parse.aBlob + (i + n) }))), u64(sz))
				p_out.zBuf[p_out.nUsed + U64(sz) + U64(1)] = i8(`\"`)
				p_out.nUsed += U64(sz + u32(2))
			}
		}
		9 {
			z_in := &i8(0)
			k := u32(0)
			sz2 := sz
			z_in = &i8(voidptr(unsafe { p_parse.aBlob + (i + n) }))
			json_append_char(p_out, i8(`\"`))
			for sz2 > u32(0) {
				for k = u32(0); k < sz2 && (int(json_is_ok[U8(z_in[k])]) || int(z_in[k]) == i8(`\'`)); k++ {
				}
				if k > u32(0) {
					json_append_raw_nz(p_out, z_in, k)
					if k >= sz2 {
						break
					}
					c2v_pointer_prefix(voidptr(&z_in), z_in, isize(k))
					sz2 -= k
				}
				if int(z_in[0]) == i8(`\"`) {
					json_append_raw_nz(p_out, c'\\"', u32(2))
					c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1))
					sz2--
					continue
				}
				if int(z_in[0]) <= 31 {
					if p_out.nUsed + U64(7) > p_out.nAlloc && json_string_grow(p_out, u32(7)) {
						break
					}
					json_append_control_char(p_out, U8(z_in[0]))
					c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1))
					sz2--
					continue
				}
				if sz2 < u32(2) {
					p_out.eErr |= 2
					break
				}
				match U8(z_in[1]) {
					`\'` {
						json_append_char(p_out, i8(`\'`))
					}
					`v` {
						json_append_raw_nz(p_out, c'\\u000b', u32(6))
					}
					`x` {
						if sz2 < u32(4) {
							p_out.eErr |= 2
							sz2 = u32(2)
							unsafe { goto c2v_switch_end_84
							 }
						}
						json_append_raw_nz(p_out, c'\\u00', u32(4))
						json_append_raw_nz(p_out, unsafe { z_in + 2 }, u32(2))
						c2v_pointer_prefix(voidptr(&z_in), z_in, isize(2))
						sz2 -= u32(2)
					}
					`0` {
						json_append_raw_nz(p_out, c'\\u0000', u32(6))
					}
					`\r` {
						if sz2 > u32(2) && int(z_in[2]) == i8(`\n`) {
							c2v_pointer_postfix(voidptr(&z_in), z_in, isize(1))
							sz2--
						}
					}
					`\n` {
					}
					226 {
						if sz2 < u32(4) || 128 != int(U8(z_in[2])) || (168 != int(U8(z_in[3])) && 169 != int(U8(z_in[3]))) {
							p_out.eErr |= 2
							sz2 = u32(2)
							unsafe { goto c2v_switch_end_84
							 }
						}
						c2v_pointer_prefix(voidptr(&z_in), z_in, isize(2))
						sz2 -= u32(2)
					}
					else {
						json_append_raw_nz(p_out, z_in, u32(2))
					}
				}
				c2v_switch_end_84:

				c2v_pointer_prefix(voidptr(&z_in), z_in, isize(2))
				sz2 -= u32(2)
			}
			json_append_char(p_out, i8(`\"`))
		}
		10 {
			json_append_string(p_out, &i8(voidptr(unsafe { p_parse.aBlob + (i + n) })), sz)
		}
		11 {
			json_append_char(p_out, i8(`[`))
			j = i + n
			i_end = j + sz
			p_parse.iDepth++
			if int(p_parse.iDepth) > 1000 {
				json_string_too_deep(p_out)
			}
			for j < i_end && int(p_out.eErr) == 0 {
				j = json_translate_blob_to_text(p_parse, j, p_out)
				json_append_char(p_out, i8(`,`))
			}
			p_parse.iDepth--
			if j > i_end {
				p_out.eErr |= 2
			}
			if sz > u32(0) {
				json_string_trim_one_char(p_out)
			}
			json_append_char(p_out, i8(`]`))
		}
		12 {
			mut x := 0
			json_append_char(p_out, i8(`{`))
			j = i + n
			i_end = j + sz
			p_parse.iDepth++
			if int(p_parse.iDepth) > 1000 {
				json_string_too_deep(p_out)
			}
			for j < i_end && int(p_out.eErr) == 0 {
				j = json_translate_blob_to_text(p_parse, j, p_out)
				json_append_char(p_out, i8(if (x++ & 1) { `,` } else { `:` }))
			}
			p_parse.iDepth--
			if (x & 1) != 0 || j > i_end {
				p_out.eErr |= 2
			}
			if sz > u32(0) {
				json_string_trim_one_char(p_out)
			}
			json_append_char(p_out, i8(`}`))
		}
		else {
			malformed_jsonb:
			p_out.eErr |= 2
		}
	}

	return i + n + sz
}

struct JsonPretty {
	pParse   &JsonParse
	pOut     &JsonString
	zIndent  &i8
	szIndent u32
	nIndent  u32
}

@[c:'jsonPrettyIndent']
fn json_pretty_indent(p_pretty &JsonPretty) {
	jj := u32(0)
	for jj = u32(0); jj < p_pretty.nIndent; jj++ {
		json_append_raw(p_pretty.pOut, p_pretty.zIndent, p_pretty.szIndent)
	}
}

@[c:'jsonTranslateBlobToPrettyText']
fn json_translate_blob_to_pretty_text(p_pretty &JsonPretty, i u32) u32 {
	sz := u32(0)
	n := u32(0)
	j := u32(0)
	i_end := u32(0)

	p_parse := p_pretty.pParse
	p_out := p_pretty.pOut
	n = jsonb_payload_size(p_parse, i, &sz)
	if n == u32(0) {
		p_out.eErr |= 2
		return p_parse.nBlob + u32(1)
	}
	match (int(p_parse.aBlob[i]) & 15) {
		11 {
			j = i + n
			i_end = j + sz
			json_append_char(p_out, i8(`[`))
			if j < i_end {
				json_append_char(p_out, i8(`\n`))
				p_pretty.nIndent++
				if p_pretty.nIndent >= u32(1000) {
					json_string_too_deep(p_out)
				}
				for int(p_out.eErr) == 0 {
					json_pretty_indent(p_pretty)
					j = json_translate_blob_to_pretty_text(p_pretty, j)
					if j >= i_end {
						break
					}
					json_append_raw_nz(p_out, c',\n', u32(2))
				}
				json_append_char(p_out, i8(`\n`))
				p_pretty.nIndent--
				json_pretty_indent(p_pretty)
			}
			json_append_char(p_out, i8(`]`))
			i = i_end
		}
		12 {
			j = i + n
			i_end = j + sz
			json_append_char(p_out, i8(`{`))
			if j < i_end {
				json_append_char(p_out, i8(`\n`))
				p_pretty.nIndent++
				if p_pretty.nIndent >= u32(1000) {
					json_string_too_deep(p_out)
				}
				p_parse.iDepth = U16(p_pretty.nIndent)
				for int(p_out.eErr) == 0 {
					json_pretty_indent(p_pretty)
					j = json_translate_blob_to_text(p_parse, j, p_out)
					if j > i_end {
						p_out.eErr |= 2
						break
					}
					json_append_raw_nz(p_out, c': ', u32(2))
					j = json_translate_blob_to_pretty_text(p_pretty, j)
					if j >= i_end {
						break
					}
					json_append_raw_nz(p_out, c',\n', u32(2))
				}
				json_append_char(p_out, i8(`\n`))
				p_pretty.nIndent--
				json_pretty_indent(p_pretty)
			}
			json_append_char(p_out, i8(`}`))
			i = i_end
		}
		else {
			i = json_translate_blob_to_text(p_parse, i, p_out)
		}
	}

	return i
}

@[c:'jsonbArrayCount']
fn jsonb_array_count(p_parse &JsonParse, i_root u32) u32 {
	n := u32(0)
	sz := u32(0)
	i := u32(0)
	i_end := u32(0)

	k := u32(0)
	n = jsonb_payload_size(p_parse, i_root, &sz)
	i_end = i_root + n + sz
	for i = i_root + n; n > u32(0) && i < i_end; i += sz + n {
		n = jsonb_payload_size(p_parse, i, &sz)
		k++
	}
	return k
}

@[c:'jsonAfterEditSizeAdjust']
fn json_after_edit_size_adjust(p_parse &JsonParse, i_root u32) {
	sz := u32(0)
	n_blob := u32(0)
	n_blob = p_parse.nBlob
	p_parse.nBlob = p_parse.nBlobAlloc
	jsonb_payload_size(p_parse, i_root, &sz)
	p_parse.nBlob = n_blob
	sz += u32(p_parse.delta)
	p_parse.delta += json_blob_change_payload_size(p_parse, i_root, sz)
}

@[c:'jsonBlobOverwrite']
fn json_blob_overwrite(a_out &U8, a_ins &U8, n_ins u32, d u32) int {
	sz_payload := u32(0)
	i := u32(0)
	sz_hdr := U8(0)
	if !json_blob_overwrite_a_type_inited {
		c2v_static_init := [U8(192), U8(208), U8(0), U8(224), U8(0), U8(0), U8(0), U8(240)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			json_blob_overwrite_a_type[c2v_i_0] = c2v_element_0
		}
		json_blob_overwrite_a_type_inited = true
	}

	if (int(a_ins[0]) & 15) <= 2 {
		return 0
	}
	match (int(a_ins[0]) >> 4) {
		12 {
			if ((1 << d) & 138) == 0 {
				return 0
			}
			i = d + u32(2)
			sz_hdr = U8(2)
		}
		13 {
			if d != u32(2) && d != u32(6) {
				return 0
			}
			i = d + u32(3)
			sz_hdr = U8(3)
		}
		14 {
			if d != u32(4) {
				return 0
			}
			i = u32(9)
			sz_hdr = U8(5)
		}
		15 {
			return 0
		}
		else {
			if ((1 << d) & 278) == 0 {
				return 0
			}
			i = d + u32(1)
			sz_hdr = U8(1)
		}
	}

	a_out[0] = U8((int(a_ins[0]) & 15) | int(json_blob_overwrite_a_type[i - u32(2)]))
	C.memcpy(voidptr(unsafe { a_out + i }), voidptr(unsafe { a_ins + sz_hdr }), u64(n_ins - u32(sz_hdr)))
	sz_payload = n_ins - u32(sz_hdr)
	for {
		i--
		a_out[i] = U8(sz_payload & u32(255))
		if i == u32(1) {
			break
		}
		sz_payload >>= 8
	}
	return 1
}

@[c:'jsonBlobEdit']
fn json_blob_edit(p_parse &JsonParse, i_del u32, n_del u32, a_ins &U8, n_ins u32) {
	d := I64(n_ins) - I64(n_del)
	if d < I64(0) && d >= I64((-8)) && usize(a_ins) != usize(0) && json_blob_overwrite(unsafe { p_parse.aBlob + i_del }, a_ins, n_ins, u32(int(-d))) {
		return
	}
	if d != I64(0) {
		if I64(p_parse.nBlob) + d > I64(p_parse.nBlobAlloc) {
			json_blob_expand(p_parse, u32(I64(p_parse.nBlob) + d))
			if p_parse.oom {
				return
			}
		}
		C.memmove(voidptr(unsafe { p_parse.aBlob + (i_del + n_ins) }), voidptr(unsafe { p_parse.aBlob + (i_del + n_del) }), u64(p_parse.nBlob - (i_del + n_del)))
		p_parse.nBlob += d
		p_parse.delta += d
	}
	if n_ins && !isnil(a_ins) {
		C.memcpy(voidptr(unsafe { p_parse.aBlob + i_del }), voidptr(a_ins), u64(n_ins))
	}
}

@[c:'jsonBytesToBypass']
fn json_bytes_to_bypass(z &i8, n u32) u32 {
	i := u32(0)
	for i + u32(1) < n {
		if int(z[i]) != i8(`\\`) {
			return i
		}
		if int(z[i + u32(1)]) == i8(`\n`) {
			i += u32(2)
			continue
		}
		if int(z[i + u32(1)]) == i8(`\r`) {
			if i + u32(2) < n && int(z[i + u32(2)]) == i8(`\n`) {
				i += u32(3)
			} else {
				i += u32(2)
			}
			continue
		}
		if 226 == int(U8(z[i + u32(1)])) && i + u32(3) < n && 128 == int(U8(z[i + u32(2)])) && (168 == int(U8(z[i + u32(3)])) || 169 == int(U8(z[i + u32(3)]))) {
			i += u32(4)
			continue
		}
		break
	}
	return i
}

@[c:'jsonUnescapeOneChar']
fn json_unescape_one_char(z &i8, n u32, pi_out &u32) u32 {
	if n < u32(2) {
		unsafe { *pi_out = u32(629145) }
		return n
	}
	match U8(z[1]) {
		`u` {
			v := u32(0)
			vlo := u32(0)

			if n < u32(6) {
				unsafe { *pi_out = u32(629145) }
				return n
			}
			v = json_hex_to_int4(unsafe { z + 2 })
			mut __c2v_condition_163 := false
			mut __c2v_condition_164 := false
			__c2v_condition_164 = (v & u32(64512)) == u32(55296)
			if __c2v_condition_164 {
				__c2v_condition_164 = n >= u32(12)
			}
			if __c2v_condition_164 {
				__c2v_condition_164 = int(z[6]) == i8(`\\`)
			}
			if __c2v_condition_164 {
				__c2v_condition_164 = int(z[7]) == i8(`u`)
			}
			if __c2v_condition_164 {
				__c2v_condition_164 = (c2v_assign[u32](unsafe { &vlo }, u32(json_hex_to_int4(unsafe { z + 8 }))) & u32(64512)) == u32(56320)
			}
			__c2v_condition_163 = __c2v_condition_164
			if __c2v_condition_163 {
				unsafe { *pi_out = ((v & u32(1023)) << 10) + (vlo & u32(1023)) + u32(65536) }
				return u32(12)
			} else {
				unsafe { *pi_out = v }
				return u32(6)
			}
		}
		`b` {
			unsafe { *pi_out = u32(`\b`) }
			return u32(2)
		}
		`f` {
			unsafe { *pi_out = u32(`\f`) }
			return u32(2)
		}
		`n` {
			unsafe { *pi_out = u32(`\n`) }
			return u32(2)
		}
		`r` {
			unsafe { *pi_out = u32(`\r`) }
			return u32(2)
		}
		`t` {
			unsafe { *pi_out = u32(`\t`) }
			return u32(2)
		}
		`v` {
			unsafe { *pi_out = u32(`\v`) }
			return u32(2)
		}
		`0` {
			unsafe { *pi_out = u32(if (n > u32(2) && (int(sqlite3CtypeMap[u8(z[2])]) & 4)) {
				629145
			} else {
				0
			}) }
			return u32(2)
		}
		`\'`, `\"`, `/`, `\\` {
			unsafe { *pi_out = u32(z[1]) }
			return u32(2)
		}
		`x` {
			if n < u32(4) {
				unsafe { *pi_out = u32(629145) }
				return n
			}
			unsafe { *pi_out = u32((int(json_hex_to_int(z[2])) << 4) | int(json_hex_to_int(z[3]))) }
			return u32(4)
		}
		226, `\r`, `\n` {
			n_skip := json_bytes_to_bypass(z, n)
			if n_skip == u32(0) {
				unsafe { *pi_out = u32(629145) }
				return n
			} else if n_skip == n {
				unsafe { *pi_out = u32(0) }
				return n
			} else if int(z[n_skip]) == i8(`\\`) {
				return n_skip + json_unescape_one_char(unsafe { z + n_skip }, n - n_skip, pi_out)
			} else {
				sz := sqlite3_utf8_read_limited(&U8(voidptr(unsafe { z + n_skip })), int(n - n_skip), pi_out)
				return n_skip + u32(sz)
			}
		}
		else {
			unsafe { *pi_out = u32(629145) }
			return u32(2)
		}
	}
	return u32(0)
}

@[c:'jsonLabelCompareEscaped']
fn json_label_compare_escaped(z_left &i8, n_left u32, raw_left int, z_right &i8, n_right u32, raw_right int) int {
	c_left := u32(0)
	c_right := u32(0)

	for {
		if n_left == u32(0) {
			c_left = u32(0)
		} else if raw_left || int(z_left[0]) != i8(`\\`) {
			c_left = u32((&U8(voidptr(z_left)))[0])
			if c_left >= u32(192) {
				sz := sqlite3_utf8_read_limited(&U8(voidptr(z_left)), int(n_left), &c_left)
				c2v_pointer_prefix(voidptr(&z_left), z_left, isize(sz))
				n_left -= u32(sz)
			} else {
				c2v_pointer_postfix(voidptr(&z_left), z_left, isize(1))
				n_left--
			}
		} else {
			n := json_unescape_one_char(z_left, n_left, &c_left)
			c2v_pointer_prefix(voidptr(&z_left), z_left, isize(n))
			n_left -= n
		}
		if n_right == u32(0) {
			c_right = u32(0)
		} else if raw_right || int(z_right[0]) != i8(`\\`) {
			c_right = u32((&U8(voidptr(z_right)))[0])
			if c_right >= u32(192) {
				sz := sqlite3_utf8_read_limited(&U8(voidptr(z_right)), int(n_right), &c_right)
				c2v_pointer_prefix(voidptr(&z_right), z_right, isize(sz))
				n_right -= u32(sz)
			} else {
				c2v_pointer_postfix(voidptr(&z_right), z_right, isize(1))
				n_right--
			}
		} else {
			n := json_unescape_one_char(z_right, n_right, &c_right)
			c2v_pointer_prefix(voidptr(&z_right), z_right, isize(n))
			n_right -= n
		}
		if c_left != c_right {
			return 0
		}
		if c_left == u32(0) {
			return 1
		}
	}
	panic('unreachable after C for (;;)')
}

@[c:'jsonLabelCompare']
fn json_label_compare(z_left &i8, n_left u32, raw_left int, z_right &i8, n_right u32, raw_right int) int {
	if raw_left && raw_right {
		if n_left != n_right {
			return 0
		}
		return int(C.memcmp(voidptr(z_left), voidptr(z_right), u64(n_left)) == 0)
	} else {
		return json_label_compare_escaped(z_left, n_left, raw_left, z_right, n_right, raw_right)
	}
}

@[c:'jsonCreateEditSubstructure']
fn json_create_edit_substructure(p_parse &JsonParse, p_ins &JsonParse, z_tail &i8) u32 {
	if !json_create_edit_substructure_empty_object_inited {
		c2v_static_init := [U8(11), U8(12)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			json_create_edit_substructure_empty_object[c2v_i_0] = c2v_element_0
		}
		json_create_edit_substructure_empty_object_inited = true
	}

	rc := 0
	C.memset(voidptr(p_ins), 0, sizeof(JsonParse))
	p_ins.db = p_parse.db
	if int(z_tail[0]) == 0 {
		p_ins.aBlob = p_parse.aIns
		p_ins.nBlob = p_parse.nIns
		rc = 0
	} else {
		p_ins.nBlob = u32(1)
		p_ins.aBlob = &U8(unsafe { &json_create_edit_substructure_empty_object[0] + (int(z_tail[0]) == i8(`.`)) })
		p_ins.eEdit = p_parse.eEdit
		p_ins.nIns = p_parse.nIns
		p_ins.aIns = p_parse.aIns
		p_ins.iDepth = U16(int(p_parse.iDepth) + 1)
		if int(p_ins.iDepth) >= 1000 {
			return u32(4294967292)
		}
		rc = int(json_lookup_step(p_ins, u32(0), z_tail, u32(0)))
		p_parse.iDepth--
		p_parse.oom |= int(p_ins.oom)
	}
	return u32(rc)
}

@[c:'jsonLookupStep']
fn json_lookup_step(p_parse &JsonParse, i_root u32, z_path &i8, i_label u32) u32 {
	i := u32(0)
	j := u32(0)
	k := u32(0)
	n_key := u32(0)
	sz := u32(0)
	n := u32(0)
	i_end := u32(0)
	rc := u32(0)

	z_key := &i8(0)
	x := U8(0)
	if int(z_path[0]) == 0 {
		if int(p_parse.eEdit) && json_blob_make_editable(p_parse, p_parse.nIns) {
			n = jsonb_payload_size(p_parse, i_root, &sz)
			sz += n
			if int(p_parse.eEdit) == 1 {
				if i_label > u32(0) {
					sz += i_root - i_label
					i_root = i_label
				}
				json_blob_edit(p_parse, i_root, sz, unsafe { nil }, u32(0))
			} else if int(p_parse.eEdit) == 3 {
			} else if int(p_parse.eEdit) == 5 {
				if int(z_path[-1]) != i8(`]`) {
					return u32(4294967293)
				} else {
					json_blob_edit(p_parse, i_root, u32(0), p_parse.aIns, p_parse.nIns)
				}
			} else {
				json_blob_edit(p_parse, i_root, sz, p_parse.aIns, p_parse.nIns)
			}
		}
		p_parse.iLabel = i_label
		return i_root
	}
	if int(z_path[0]) == i8(`.`) {
		raw_key := 1
		x = p_parse.aBlob[i_root]
		c2v_pointer_postfix(voidptr(&z_path), z_path, isize(1))
		if int(z_path[0]) == i8(`\"`) {
			z_key = z_path + 1
			for i = u32(1); int(z_path[i]) && int(z_path[i]) != i8(`\"`); i++ {
				if int(z_path[i]) == i8(`\\`) && int(z_path[i + u32(1)]) != 0 {
					i++
				}
			}
			n_key = i - u32(1)
			if z_path[i] {
				i++
			} else {
				return u32(4294967291)
			}
			0
			raw_key = usize(C.memchr(voidptr(z_key), `\\`, u64(n_key))) == usize(0)
		} else {
			z_key = z_path
			for i = u32(0); int(z_path[i]) && int(z_path[i]) != i8(`.`) && int(z_path[i]) != i8(`[`); i++ {
			}
			n_key = i
			if n_key == u32(0) {
				return u32(4294967291)
			}
		}
		if (int(x) & 15) != 12 {
			return u32(4294967294)
		}
		n = jsonb_payload_size(p_parse, i_root, &sz)
		j = i_root + n
		i_end = j + sz
		for j < i_end {
			raw_label := 0
			z_label := &i8(0)
			x = U8(int(p_parse.aBlob[j]) & 15)
			if int(x) < 7 || int(x) > 10 {
				return u32(4294967295)
			}
			n = jsonb_payload_size(p_parse, j, &sz)
			if n == u32(0) {
				return u32(4294967295)
			}
			k = j + n
			if k + sz >= i_end {
				return u32(4294967295)
			}
			z_label = &i8(voidptr(unsafe { p_parse.aBlob + k }))
			raw_label = int(x) == 7 || int(x) == 10
			if json_label_compare(z_key, n_key, raw_key, z_label, sz, raw_label) {
				v := k + sz
				if (int(p_parse.aBlob[v]) & 15) > 12 {
					return u32(4294967295)
				}
				n = jsonb_payload_size(p_parse, v, &sz)
				if n == u32(0) || v + n + sz > i_end {
					return u32(4294967295)
				}
				p_parse.iDepth++
				if int(p_parse.iDepth) >= 1000 {
					return u32(4294967292)
				}
				rc = json_lookup_step(p_parse, v, unsafe { z_path + i }, j)
				p_parse.iDepth--
				if p_parse.delta {
					json_after_edit_size_adjust(p_parse, i_root)
				}
				return rc
			}
			j = k + sz
			if (int(p_parse.aBlob[j]) & 15) > 12 {
				return u32(4294967295)
			}
			n = jsonb_payload_size(p_parse, j, &sz)
			if n == u32(0) {
				return u32(4294967295)
			}
			j += n + sz
		}
		if j > i_end {
			return u32(4294967295)
		}
		if int(p_parse.eEdit) >= 3 {
			n_ins := u32(0)
			v := JsonParse{}
			ix := JsonParse{}
			0
			0
			0
			if int(p_parse.eEdit) == 5 && sqlite3_strglob(c'*]', unsafe { z_path + i }) != 0 {
				return u32(4294967293)
			}
			C.memset(voidptr(&ix), 0, sizeof(ix))
			ix.db = p_parse.db
			json_blob_append_node(&ix, U8(if raw_key { 10 } else { 9 }), U64(n_key), unsafe { nil })
			p_parse.oom |= int(ix.oom)
			rc = json_create_edit_substructure(p_parse, &v, unsafe { z_path + i })
			if !(rc >= u32(4294967291)) && json_blob_make_editable(p_parse, ix.nBlob + n_key + v.nBlob) {
				n_ins = ix.nBlob + n_key + v.nBlob
				json_blob_edit(p_parse, j, u32(0), unsafe { nil }, n_ins)
				if !p_parse.oom {
					C.memcpy(voidptr(unsafe { p_parse.aBlob + j }), voidptr(ix.aBlob), u64(ix.nBlob))
					k = j + ix.nBlob
					C.memcpy(voidptr(unsafe { p_parse.aBlob + k }), voidptr(z_key), u64(n_key))
					k += n_key
					C.memcpy(voidptr(unsafe { p_parse.aBlob + k }), voidptr(v.aBlob), u64(v.nBlob))
					if p_parse.delta {
						json_after_edit_size_adjust(p_parse, i_root)
					}
				}
			}
			json_parse_reset(&v)
			json_parse_reset(&ix)
			return rc
		}
	} else if int(z_path[0]) == i8(`[`) {
		kk := U64(0)
		x = U8(int(p_parse.aBlob[i_root]) & 15)
		if int(x) != 11 {
			return u32(4294967294)
		}
		n = jsonb_payload_size(p_parse, i_root, &sz)
		i = u32(1)
		for (int(sqlite3CtypeMap[u8(z_path[i])]) & 4) {
			if kk < U64(u32(4294967295)) {
				kk = kk * U64(10) + U64(z_path[i]) - U64(`0`)
			}
			i++
		}
		if i < u32(2) || int(z_path[i]) != i8(`]`) {
			if int(z_path[1]) == i8(`#`) {
				kk = U64(jsonb_array_count(p_parse, i_root))
				i = u32(2)
				if int(z_path[2]) == i8(`-`) && (int(sqlite3CtypeMap[u8(z_path[3])]) & 4) {
					nn := U64(0)
					i = u32(3)
					for {
						if nn < U64(u32(4294967295)) {
							nn = nn * U64(10) + U64(z_path[i]) - U64(`0`)
						}
						i++
						if !(int(sqlite3CtypeMap[u8(z_path[i])]) & 4) {
							break
						}
					}
					if nn > kk {
						return u32(4294967294)
					}
					kk -= nn
				}
				if int(z_path[i]) != i8(`]`) {
					return u32(4294967291)
				}
			} else {
				return u32(4294967291)
			}
		}
		j = i_root + n
		i_end = j + sz
		for j < i_end {
			if kk == U64(0) {
				p_parse.iDepth++
				if int(p_parse.iDepth) >= 1000 {
					return u32(4294967292)
				}
				rc = json_lookup_step(p_parse, j, unsafe { z_path + (i + u32(1)) }, u32(0))
				p_parse.iDepth--
				if p_parse.delta {
					json_after_edit_size_adjust(p_parse, i_root)
				}
				return rc
			}
			kk--
			n = jsonb_payload_size(p_parse, j, &sz)
			if n == u32(0) {
				return u32(4294967295)
			}
			j += n + sz
		}
		if j > i_end {
			return u32(4294967295)
		}
		if kk > U64(0) {
			return u32(4294967294)
		}
		if int(p_parse.eEdit) >= 3 {
			v := JsonParse{}
			0
			0
			0
			rc = json_create_edit_substructure(p_parse, &v, unsafe { z_path + (i + u32(1)) })
			if !(rc >= u32(4294967291)) && json_blob_make_editable(p_parse, v.nBlob) {
				json_blob_edit(p_parse, j, u32(0), v.aBlob, v.nBlob)
			}
			json_parse_reset(&v)
			if p_parse.delta {
				json_after_edit_size_adjust(p_parse, i_root)
			}
			return rc
		}
	} else {
		return u32(4294967291)
	}
	return u32(4294967294)
}

@[c:'jsonReturnTextJsonFromBlob']
fn json_return_text_json_from_blob(ctx &Sqlite3_context, a_blob &U8, n_blob u32) {
	x := JsonParse{}
	s := JsonString{}
	if (usize(a_blob) == usize(0)) {
		return
	}
	C.memset(voidptr(&x), 0, sizeof(x))
	x.aBlob = &U8(a_blob)
	x.nBlob = n_blob
	json_string_init(&s, ctx)
	json_translate_blob_to_text(&x, u32(0), &s)
	json_return_string(&s, unsafe { nil }, unsafe { nil })
}

@[c:'jsonReturnFromBlob']
fn json_return_from_blob(p_parse &JsonParse, i u32, p_ctx &Sqlite3_context, e_mode int) {
	n := u32(0)
	sz := u32(0)

	rc := 0
	db := sqlite3_context_db_handle(p_ctx)
	n = jsonb_payload_size(p_parse, i, &sz)
	if n == u32(0) {
		sqlite3_result_error(p_ctx, c'malformed JSON', -1)
		return
	}
	match (int(p_parse.aBlob[i]) & 15) {
		0 {
			if sz {
				unsafe { goto returnfromblob_malformed
				 }
			}
			sqlite3_result_null(p_ctx)
		}
		1 {
			if sz {
				unsafe { goto returnfromblob_malformed
				 }
			}
			sqlite3_result_int(p_ctx, 1)
		}
		2 {
			if sz {
				unsafe { goto returnfromblob_malformed
				 }
			}
			sqlite3_result_int(p_ctx, 0)
		}
		4, 3 {
			i_res := Sqlite3_int64(0)
			z := &i8(0)
			b_neg := 0
			x := i8(0)
			if sz == u32(0) {
				unsafe { goto returnfromblob_malformed
				 }
			}
			x = i8(p_parse.aBlob[i + n])
			if int(x) == i8(`-`) {
				if sz < u32(2) {
					unsafe { goto returnfromblob_malformed
					 }
				}
				n++
				sz--
				b_neg = 1
			}
			z = sqlite3_db_str_nd_up(db, &i8(voidptr(unsafe { p_parse.aBlob + (i + n) })), U64(int(sz)))
			if usize(z) == usize(0) {
				unsafe { goto returnfromblob_oom
				 }
			}
			rc = sqlite3_dec_or_hex_to_i64(z, unsafe { &I64(&i_res) })
			sqlite3_db_free(db, voidptr(z))
			if rc == 0 {
				if i_res < Sqlite3_int64(0) {
					r := 0.0
					r = f64((unsafe { *&Sqlite3_uint64(c2v_address_of(&i_res)) }))
					sqlite3_result_double(p_ctx, if b_neg { -r } else { r })
				} else {
					sqlite3_result_int64(p_ctx, if b_neg { -i_res } else { i_res })
				}
			} else if rc == 3 && b_neg {
				sqlite3_result_int64(p_ctx, ((I64(-1)) - (I64(u32(4294967295)) | ((I64(2147483647)) << 32))))
			} else if rc == 1 {
				unsafe { goto returnfromblob_malformed
				 }
			} else {
				if b_neg {
					n--
					sz++
				}
				unsafe { goto to_double
				 }
			}
		}
		6, 5 {
			r := 0.0
			z_2 := &i8(0)
			if sz == u32(0) {
				unsafe { goto returnfromblob_malformed
				 }
			}
			to_double:
			z_2 = sqlite3_db_str_nd_up(db, &i8(voidptr(unsafe { p_parse.aBlob + (i + n) })), U64(int(sz)))
			if usize(z_2) == usize(0) {
				unsafe { goto returnfromblob_oom
				 }
			}
			rc = sqlite3_ato_f(z_2, &r)
			sqlite3_db_free(db, voidptr(z_2))
			if rc <= 0 {
				unsafe { goto returnfromblob_malformed
				 }
			}
			sqlite3_result_double(p_ctx, r)
		}
		10, 7 {
			sqlite3_result_text(p_ctx, &i8(voidptr(unsafe { p_parse.aBlob + (i + n) })), int(sz), (C2vFn_666e2028766f696470747229(voidptr(-1))))
		}
		9, 8 {
			i_in := u32(0)
			i_out := u32(0)

			z_3 := &i8(0)
			z_out := &i8(0)
			n_out := sz
			z_3 = &i8(voidptr(unsafe { p_parse.aBlob + (i + n) }))
			z_out = &i8(sqlite3_db_malloc_raw(db, (U64(n_out)) + U64(1)))
			if usize(z_out) == usize(0) {
				unsafe { goto returnfromblob_oom
				 }
			}
			i_out = u32(0)
			for i_in = u32(0); i_in < sz; i_in++ {
				c := z_3[i_in]
				if int(c) == i8(`\\`) {
					v := u32(0)
					sz_escape := json_unescape_one_char(unsafe { z_3 + i_in }, sz - i_in, &v)
					if v <= u32(127) {
						z_out[i_out++] = i8(v)
					} else if v <= u32(2047) {
						z_out[i_out++] = i8((u32(192) | (v >> 6)))
						z_out[i_out++] = i8(u32(128) | (v & u32(63)))
					} else if v < u32(65536) {
						z_out[i_out++] = i8(u32(224) | (v >> 12))
						z_out[i_out++] = i8(u32(128) | ((v >> 6) & u32(63)))
						z_out[i_out++] = i8(u32(128) | (v & u32(63)))
					} else if v == u32(629145) {
					} else {
						z_out[i_out++] = i8(u32(240) | (v >> 18))
						z_out[i_out++] = i8(u32(128) | ((v >> 12) & u32(63)))
						z_out[i_out++] = i8(u32(128) | ((v >> 6) & u32(63)))
						z_out[i_out++] = i8(u32(128) | (v & u32(63)))
					}
					i_in += sz_escape - u32(1)
				} else {
					z_out[i_out++] = c
				}
			}
			z_out[i_out] = i8(0)
			sqlite3_result_text(p_ctx, z_out, int(i_out), (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))))
		}
		11, 12 {
			if e_mode == 0 {
				if ((int(i64(sqlite3_user_data(p_ctx)))) & 16) != 0 {
					e_mode = 2
				} else {
					e_mode = 1
				}
			}
			if e_mode == 2 {
				sqlite3_result_blob(p_ctx, voidptr(unsafe { p_parse.aBlob + i }), int(sz + n), (C2vFn_666e2028766f696470747229(voidptr(-1))))
			} else {
				json_return_text_json_from_blob(p_ctx, unsafe { p_parse.aBlob + i }, sz + n)
			}
		}
		else {
			unsafe { goto returnfromblob_malformed
			 }
		}
	}

	return
	returnfromblob_oom:
	sqlite3_result_error_nomem(p_ctx)
	return
	returnfromblob_malformed:
	sqlite3_result_error(p_ctx, c'malformed JSON', -1)
	return
}

@[c:'jsonFunctionArgToBlob']
fn json_function_arg_to_blob(ctx &Sqlite3_context, p_arg &Sqlite3_value, p_parse &JsonParse) int {
	e_type := sqlite3_value_type(p_arg)
	if !json_function_arg_to_blob_a_null_inited {
		c2v_static_init := [U8(0)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			json_function_arg_to_blob_a_null[c2v_i_0] = c2v_element_0
		}
		json_function_arg_to_blob_a_null_inited = true
	}

	C.memset(voidptr(p_parse), 0, sizeof(JsonParse))
	p_parse.db = sqlite3_context_db_handle(ctx)
	match e_type {
		4 {
			if !json_arg_is_jsonb(p_arg, p_parse) {
				sqlite3_result_error(ctx, c'JSON cannot hold BLOB values', -1)
				return 1
			}
		}
		3 {
			z_json := &i8(voidptr(sqlite3_value_text(p_arg)))
			n_json := sqlite3_value_bytes(p_arg)
			if usize(z_json) == usize(0) {
				return 1
			}
			if sqlite3_value_subtype(p_arg) == u32(74) {
				p_parse.zJson = &i8(z_json)
				p_parse.nJson = n_json
				if json_convert_text_to_blob(p_parse, ctx) {
					sqlite3_result_error(ctx, c'malformed JSON', -1)
					sqlite3_db_free(p_parse.db, voidptr(p_parse.aBlob))
					C.memset(voidptr(p_parse), 0, sizeof(JsonParse))
					return 1
				}
			} else {
				json_blob_append_node(p_parse, U8(10), U64(n_json), voidptr(z_json))
			}
		}
		2 {
			r := sqlite3_value_double(p_arg)
			if sqlite3_is_na_n(r) {
				json_blob_append_node(p_parse, U8(0), U64(0), unsafe { nil })
			} else {
				n := sqlite3_value_bytes(p_arg)
				z := &i8(voidptr(sqlite3_value_text(p_arg)))
				if usize(z) == usize(0) {
					return 1
				}
				if int(z[0]) == i8(`I`) {
					json_blob_append_node(p_parse, U8(5), U64(5), voidptr(c'9e999'))
				} else if int(z[0]) == i8(`-`) && int(z[1]) == i8(`I`) {
					json_blob_append_node(p_parse, U8(5), U64(6), voidptr(c'-9e999'))
				} else {
					json_blob_append_node(p_parse, U8(5), U64(n), voidptr(z))
				}
			}
		}
		1 {
			n := sqlite3_value_bytes(p_arg)
			z := &i8(voidptr(sqlite3_value_text(p_arg)))
			if usize(z) == usize(0) {
				return 1
			}
			json_blob_append_node(p_parse, U8(3), U64(n), voidptr(z))
		}
		else {
			p_parse.aBlob = unsafe { &json_function_arg_to_blob_a_null[0] }
			p_parse.nBlob = u32(1)
			return 0
		}
	}

	if p_parse.oom {
		sqlite3_result_error_nomem(ctx)
		return 1
	} else {
		return 0
	}
}

@[c:'jsonBadPathError']
fn json_bad_path_error(ctx &Sqlite3_context, z_path &i8, rc int) &i8 {
	z_msg := &i8(0)
	if rc == int(u32(4294967293)) {
		z_msg = sqlite3_mprintf(c'not an array element: %Q', voidptr(z_path))
	} else if rc == int(u32(4294967295)) {
		z_msg = sqlite3_mprintf(c'malformed JSON')
	} else if rc == int(u32(4294967292)) {
		z_msg = sqlite3_mprintf(c'JSON path too deep')
	} else {
		z_msg = sqlite3_mprintf(c'bad JSON path: %Q', voidptr(z_path))
	}
	if usize(ctx) == usize(0) {
		return z_msg
	}
	if z_msg {
		sqlite3_result_error(ctx, z_msg, -1)
		sqlite3_free(voidptr(z_msg))
	} else {
		sqlite3_result_error_nomem(ctx)
	}
	return unsafe { nil }
}

@[c:'jsonInsertIntoBlob']
fn json_insert_into_blob(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value, e_edit int) {
	i := 0
	rc := u32(0)
	z_path := unsafe { &i8(nil) }
	flgs := 0
	p := &JsonParse(0)
	ax := JsonParse{}
	flgs = if argc == 1 { 0 } else { 1 }
	p = json_parse_func_arg(ctx, argv[0], u32(flgs))
	if usize(p) == usize(0) {
		return
	}
	for i = 1; i < argc - 1; i += 2 {
		if sqlite3_value_type(argv[i]) == 5 {
			continue
		}
		z_path = &i8(voidptr(sqlite3_value_text(argv[i])))
		if usize(z_path) == usize(0) {
			sqlite3_result_error_nomem(ctx)
			json_parse_free(p)
			return
		}
		if int(z_path[0]) != i8(`$`) {
			unsafe { goto jsonInsertIntoBlob_patherror
			 }
		}
		if json_function_arg_to_blob(ctx, argv[i + 1], &ax) {
			json_parse_reset(&ax)
			json_parse_free(p)
			return
		}
		if int(z_path[1]) == 0 {
			if e_edit == 2 || e_edit == 4 {
				json_blob_edit(p, u32(0), p.nBlob, ax.aBlob, ax.nBlob)
			}
			rc = u32(0)
		} else {
			p.eEdit = U8(e_edit)
			p.nIns = ax.nBlob
			p.aIns = ax.aBlob
			p.delta = 0
			p.iDepth = U16(0)
			rc = json_lookup_step(p, u32(0), z_path + 1, u32(0))
		}
		json_parse_reset(&ax)
		if rc == u32(4294967294) {
			continue
		}
		if (rc >= u32(4294967291)) {
			unsafe { goto jsonInsertIntoBlob_patherror
			 }
		}
	}
	json_return_parse(ctx, p)
	json_parse_free(p)
	return
	jsonInsertIntoBlob_patherror:
	json_parse_free(p)
	json_bad_path_error(ctx, z_path, int(rc))
	return
}

@[c:'jsonArgIsJsonb']
fn json_arg_is_jsonb(p_arg &Sqlite3_value, p &JsonParse) int {
	n := u32(0)
	sz := u32(0)

	c := U8(0)
	if sqlite3_value_type(p_arg) != 4 {
		return 0
	}
	p.aBlob = &U8(sqlite3_value_blob(p_arg))
	p.nBlob = u32(sqlite3_value_bytes(p_arg))
	mut __c2v_condition_165 := false
	mut __c2v_condition_166 := false
	__c2v_condition_166 = p.nBlob > u32(0)
	if __c2v_condition_166 {
		__c2v_condition_166 = (usize(p.aBlob) != usize(0))
	}
	if __c2v_condition_166 {
		__c2v_condition_166 = (int(c2v_assign[u8](unsafe { &c }, u8(p.aBlob[0]))) & 15) <= 12
	}
	if __c2v_condition_166 {
		__c2v_condition_166 = c2v_assign[u32](unsafe { &n }, u32(jsonb_payload_size(p, u32(0), &sz))) > u32(0)
	}
	if __c2v_condition_166 {
		__c2v_condition_166 = sz + n == p.nBlob
	}
	if __c2v_condition_166 {
		__c2v_condition_166 = ((int(c) & 15) > 2 || sz == u32(0))
	}
	if __c2v_condition_166 {
		__c2v_condition_166 = (sz > u32(7) || (int(c) != 123 && int(c) != 91 && !(int(sqlite3CtypeMap[u8(c)]) & 4)) || jsonb_validity_check(p, u32(0), p.nBlob, u32(1)) == u32(0))
	}
	__c2v_condition_165 = __c2v_condition_166
	if __c2v_condition_165 {
		return 1
	}
	p.aBlob = 0
	p.nBlob = u32(0)
	return 0
}

@[c:'jsonParseFuncArg']
fn json_parse_func_arg(ctx &Sqlite3_context, p_arg &Sqlite3_value, flgs u32) &JsonParse {
	e_type := 0
	p := unsafe { &JsonParse(nil) }
	p_from_cache := unsafe { &JsonParse(nil) }
	db := &Sqlite3(0)
	e_type = sqlite3_value_type(p_arg)
	if e_type == 5 {
		return unsafe { nil }
	}
	p_from_cache = json_cache_search(ctx, p_arg)
	if p_from_cache {
		p_from_cache.nJPRef++
		if (flgs & u32(1)) == u32(0) {
			return p_from_cache
		}
	}
	db = sqlite3_context_db_handle(ctx)
	rebuild_from_cache:
	p = sqlite3_db_malloc_zero(db, U64(sizeof(JsonParse)))
	if usize(p) == usize(0) {
		unsafe { goto json_pfa_oom
		 }
	}
	C.memset(voidptr(p), 0, sizeof(JsonParse))
	p.db = db
	p.nJPRef = u32(1)
	if usize(p_from_cache) != usize(0) {
		n_blob := p_from_cache.nBlob
		p.aBlob = sqlite3_db_malloc_raw(db, U64(n_blob))
		if usize(p.aBlob) == usize(0) {
			unsafe { goto json_pfa_oom
			 }
		}
		C.memcpy(voidptr(p.aBlob), voidptr(p_from_cache.aBlob), u64(n_blob))
		p.nBlob = n_blob
		p.nBlobAlloc = p.nBlob
		p.hasNonstd = p_from_cache.hasNonstd
		json_parse_free(p_from_cache)
		return p
	}
	if e_type == 4 {
		if json_arg_is_jsonb(p_arg, p) {
			if (flgs & u32(1)) != u32(0) && json_blob_make_editable(p, u32(0)) == 0 {
				unsafe { goto json_pfa_oom
				 }
			}
			return p
		}
	}
	p.zJson = &i8(voidptr(sqlite3_value_text(p_arg)))
	p.nJson = sqlite3_value_bytes(p_arg)
	if db.mallocFailed {
		unsafe { goto json_pfa_oom
		 }
	}
	if p.nJson == 0 {
		unsafe { goto json_pfa_malformed
		 }
	}
	if json_convert_text_to_blob(p, unsafe { if (flgs & u32(2)) {
		&Sqlite3_context(nil)
	} else {
		ctx
	} }) {
		if flgs & u32(2) {
			p.nErr = U8(1)
			return p
		} else {
			json_parse_free(p)
			return unsafe { nil }
		}
	} else {
		is_rc_str := sqlite3_value_is_of_class(p_arg, sqlite3_rc_str_unref)
		rc := 0
		if !is_rc_str {
			z_new := sqlite3_rc_str_new(U64(p.nJson))
			if usize(z_new) == usize(0) {
				unsafe { goto json_pfa_oom
				 }
			}
			C.memcpy(voidptr(z_new), voidptr(p.zJson), u64(p.nJson))
			p.zJson = z_new
			p.zJson[p.nJson] = i8(0)
		} else {
			sqlite3_rc_str_ref(p.zJson)
		}
		p.bJsonIsRCStr = U8(1)
		rc = json_cache_insert(ctx, p)
		if rc == 7 {
			unsafe { goto json_pfa_oom
			 }
		}
		if flgs & u32(1) {
			p_from_cache = p
			p = 0
			unsafe { goto rebuild_from_cache
			 }
		}
	}
	return p
	json_pfa_malformed:
	if flgs & u32(2) {
		p.nErr = U8(1)
		return p
	} else {
		json_parse_free(p)
		sqlite3_result_error(ctx, c'malformed JSON', -1)
		return unsafe { nil }
	}
	json_pfa_oom:
	json_parse_free(p_from_cache)
	json_parse_free(p)
	sqlite3_result_error_nomem(ctx)
	return unsafe { nil }
}

@[c:'jsonReturnParse']
fn json_return_parse(ctx &Sqlite3_context, p &JsonParse) {
	flgs := 0
	if p.oom {
		sqlite3_result_error_nomem(ctx)
		return
	}
	flgs = (int(i64(sqlite3_user_data(ctx))))
	if flgs & 16 {
		if p.nBlobAlloc > u32(0) && !p.bReadOnly {
			sqlite3_result_blob(ctx, voidptr(p.aBlob), int(p.nBlob), (C2vFn_666e2028766f696470747229(voidptr(sqlite3_row_set_clear))))
			p.nBlobAlloc = u32(0)
		} else {
			sqlite3_result_blob(ctx, voidptr(p.aBlob), int(p.nBlob), (C2vFn_666e2028766f696470747229(voidptr(-1))))
		}
	} else {
		s := JsonString{}
		json_string_init(&s, ctx)
		p.delta = 0
		json_translate_blob_to_text(p, u32(0), &s)
		json_return_string(&s, p, ctx)
		sqlite3_result_subtype(ctx, u32(74))
	}
}

@[c:'jsonQuoteFunc']
fn json_quote_func(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	jx := JsonString{}

	json_string_init(&jx, ctx)
	json_append_sql_value(&jx, argv[0])
	json_return_string(&jx, unsafe { nil }, unsafe { nil })
	sqlite3_result_subtype(ctx, u32(74))
}

@[c:'jsonArrayFunc']
fn json_array_func(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	i := 0
	jx := JsonString{}
	json_string_init(&jx, ctx)
	json_append_char(&jx, i8(`[`))
	for i = 0; i < argc; i++ {
		json_append_separator(&jx)
		json_append_sql_value(&jx, argv[i])
	}
	json_append_char(&jx, i8(`]`))
	json_return_string(&jx, unsafe { nil }, unsafe { nil })
	sqlite3_result_subtype(ctx, u32(74))
}

@[c:'jsonArrayLengthFunc']
fn json_array_length_func(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &JsonParse(0)
	cnt := Sqlite3_int64(0)
	i := u32(0)
	e_err := U8(0)
	p = json_parse_func_arg(ctx, argv[0], u32(0))
	if usize(p) == usize(0) {
		return
	}
	if argc == 2 {
		z_path := &i8(voidptr(sqlite3_value_text(argv[1])))
		if usize(z_path) == usize(0) {
			json_parse_free(p)
			return
		}
		i = json_lookup_step(p, u32(0), unsafe { if int(z_path[0]) == i8(`$`) {
			z_path + 1
		} else {
			c'@'
		} }, u32(0))
		if (i >= u32(4294967291)) {
			if i == u32(4294967294) {
			} else {
				json_bad_path_error(ctx, z_path, int(i))
			}
			e_err = U8(1)
			i = u32(0)
		}
	} else {
		i = u32(0)
	}
	if (int(p.aBlob[i]) & 15) == 11 {
		cnt = Sqlite3_int64(jsonb_array_count(p, i))
	}
	if !e_err {
		sqlite3_result_int64(ctx, cnt)
	}
	json_parse_free(p)
}

@[c:'jsonAllAlphanum']
fn json_all_alphanum(z &i8, n int) int {
	i := 0
	for i = 0; i < n && ((int(sqlite3CtypeMap[u8(z[i])]) & 6) || int(z[i]) == i8(`_`)); i++ {
	}
	return int(i == n)
}

@[c:'jsonExtractFunc']
fn json_extract_func(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := unsafe { &JsonParse(nil) }
	flags := 0
	i := 0
	jx := JsonString{}
	if argc < 2 {
		return
	}
	p = json_parse_func_arg(ctx, argv[0], u32(0))
	if usize(p) == usize(0) {
		return
	}
	flags = (int(i64(sqlite3_user_data(ctx))))
	json_string_init(&jx, ctx)
	if argc > 2 {
		json_append_char(&jx, i8(`[`))
	}
	for i = 1; i < argc; i++ {
		z_path := &i8(voidptr(sqlite3_value_text(argv[i])))
		n_path := 0
		j := u32(0)
		if usize(z_path) == usize(0) {
			unsafe { goto json_extract_error
			 }
		}
		n_path = sqlite3_strlen30(z_path)
		if int(z_path[0]) == i8(`$`) {
			j = json_lookup_step(p, u32(0), z_path + 1, u32(0))
		} else if (flags & 3) {
			json_string_init(&jx, ctx)
			if sqlite3_value_type(argv[i]) == 1 {
				json_append_raw_nz(&jx, c'[', u32(1))
				if int(z_path[0]) == i8(`-`) {
					json_append_raw_nz(&jx, c'#', u32(1))
				}
				json_append_raw(&jx, z_path, u32(n_path))
				json_append_raw_nz(&jx, c']', u32(2))
			} else if json_all_alphanum(z_path, n_path) {
				json_append_raw_nz(&jx, c'.', u32(1))
				json_append_raw(&jx, z_path, u32(n_path))
			} else if int(z_path[0]) == i8(`[`) && n_path >= 3 && int(z_path[n_path - 1]) == i8(`]`) {
				json_append_raw(&jx, z_path, u32(n_path))
			} else {
				json_append_raw_nz(&jx, c'."', u32(2))
				json_append_raw(&jx, z_path, u32(n_path))
				json_append_raw_nz(&jx, c'"', u32(1))
			}
			json_string_terminate(&jx)
			j = json_lookup_step(p, u32(0), jx.zBuf, u32(0))
			json_string_reset(&jx)
		} else {
			json_bad_path_error(ctx, z_path, 0)
			unsafe { goto json_extract_error
			 }
		}
		if j < p.nBlob {
			if argc == 2 {
				if flags & 1 {
					json_string_init(&jx, ctx)
					json_translate_blob_to_text(p, j, &jx)
					json_return_string(&jx, unsafe { nil }, unsafe { nil })
					json_string_reset(&jx)
					sqlite3_result_subtype(ctx, u32(74))
				} else {
					json_return_from_blob(p, j, ctx, 0)
					if (flags & (2 | 16)) == 0 && (int(p.aBlob[j]) & 15) >= 11 {
						sqlite3_result_subtype(ctx, u32(74))
					}
				}
			} else {
				json_append_separator(&jx)
				json_translate_blob_to_text(p, j, &jx)
			}
		} else if j == u32(4294967294) {
			if argc == 2 {
				unsafe { goto json_extract_error
				 }
			} else {
				json_append_separator(&jx)
				json_append_raw_nz(&jx, c'null', u32(4))
			}
		} else {
			json_bad_path_error(ctx, z_path, int(j))
			unsafe { goto json_extract_error
			 }
		}
	}
	if argc > 2 {
		json_append_char(&jx, i8(`]`))
		json_return_string(&jx, unsafe { nil }, unsafe { nil })
		if (flags & 16) == 0 {
			sqlite3_result_subtype(ctx, u32(74))
		}
	}
	json_extract_error:
	json_string_reset(&jx)
	json_parse_free(p)
	return
}

@[c:'jsonMergePatch']
fn json_merge_patch(p_target &JsonParse, i_target u32, p_patch &JsonParse, i_patch u32, i_depth u32) int {
	x := U8(0)
	n := u32(0)
	sz := u32(0)

	itc_ursor := u32(0)
	its_tart := u32(0)
	ite_nd_be := u32(0)
	ite_nd := u32(0)
	etl_abel := U8(0)
	itl_abel := u32(0)
	ntl_abel := u32(0)
	sz_tl_abel := u32(0)
	itv_alue := u32(0)
	ntv_alue := u32(0)
	sz_tv_alue := u32(0)
	ipc_ursor := u32(0)
	ipe_nd := u32(0)
	epl_abel := U8(0)
	ipl_abel := u32(0)
	npl_abel := u32(0)
	sz_pl_abel := u32(0)
	ipv_alue := u32(0)
	npv_alue := u32(0)
	sz_pv_alue := u32(0)
	x = U8(int(p_patch.aBlob[i_patch]) & 15)
	if int(x) != 12 {
		sz_patch := u32(0)
		sz_target := u32(0)
		n = jsonb_payload_size(p_patch, i_patch, &sz)
		sz_patch = n + sz
		sz = u32(0)
		n = jsonb_payload_size(p_target, i_target, &sz)
		sz_target = n + sz
		json_blob_edit(p_target, i_target, sz_target, p_patch.aBlob + i_patch, sz_patch)
		return if int(p_target.oom) { 3 } else { 0 }
	}
	x = U8(int(p_target.aBlob[i_target]) & 15)
	if int(x) != 12 {
		n = jsonb_payload_size(p_target, i_target, &sz)
		json_blob_edit(p_target, i_target + n, sz, unsafe { nil }, u32(0))
		x = p_target.aBlob[i_target]
		p_target.aBlob[i_target] = U8((int(x) & 240) | 12)
	}
	n = jsonb_payload_size(p_patch, i_patch, &sz)
	if (n == u32(0)) {
		return 2
	}
	ipc_ursor = i_patch + n
	ipe_nd = ipc_ursor + sz
	n = jsonb_payload_size(p_target, i_target, &sz)
	if (n == u32(0)) {
		return 1
	}
	its_tart = i_target + n
	ite_nd_be = its_tart + sz
	for ipc_ursor < ipe_nd {
		ipl_abel = ipc_ursor
		epl_abel = U8(int(p_patch.aBlob[ipc_ursor]) & 15)
		if int(epl_abel) < 7 || int(epl_abel) > 10 {
			return 2
		}
		npl_abel = jsonb_payload_size(p_patch, ipc_ursor, &sz_pl_abel)
		if npl_abel == u32(0) {
			return 2
		}
		ipv_alue = ipc_ursor + npl_abel + sz_pl_abel
		if ipv_alue >= ipe_nd {
			return 2
		}
		npv_alue = jsonb_payload_size(p_patch, ipv_alue, &sz_pv_alue)
		if npv_alue == u32(0) {
			return 2
		}
		ipc_ursor = ipv_alue + npv_alue + sz_pv_alue
		if ipc_ursor > ipe_nd {
			return 2
		}
		itc_ursor = its_tart
		ite_nd = ite_nd_be + u32(p_target.delta)
		for itc_ursor < ite_nd {
			is_equal := 0
			itl_abel = itc_ursor
			etl_abel = U8(int(p_target.aBlob[itc_ursor]) & 15)
			if int(etl_abel) < 7 || int(etl_abel) > 10 {
				return 1
			}
			ntl_abel = jsonb_payload_size(p_target, itc_ursor, &sz_tl_abel)
			if ntl_abel == u32(0) {
				return 1
			}
			itv_alue = itl_abel + ntl_abel + sz_tl_abel
			if itv_alue >= ite_nd {
				return 1
			}
			ntv_alue = jsonb_payload_size(p_target, itv_alue, &sz_tv_alue)
			if ntv_alue == u32(0) {
				return 1
			}
			if itv_alue + ntv_alue + sz_tv_alue > ite_nd {
				return 1
			}
			is_equal = json_label_compare(&i8(voidptr(unsafe { p_patch.aBlob + (ipl_abel + npl_abel) })), sz_pl_abel, (int(epl_abel) == 7 || int(epl_abel) == 10), &i8(voidptr(unsafe { p_target.aBlob + (itl_abel + ntl_abel) })), sz_tl_abel, (int(etl_abel) == 7 || int(etl_abel) == 10))
			if is_equal {
				break
			}
			itc_ursor = itv_alue + ntv_alue + sz_tv_alue
		}
		x = U8(int(p_patch.aBlob[ipv_alue]) & 15)
		if itc_ursor < ite_nd {
			if int(x) == 0 {
				json_blob_edit(p_target, itl_abel, ntl_abel + sz_tl_abel + ntv_alue + sz_tv_alue, unsafe { nil }, u32(0))
				if p_target.oom {
					return 3
				}
			} else {
				rc := 0
				saved_delta := p_target.delta

				p_target.delta = 0
				if i_depth >= u32(1000) {
					return 4
				}
				rc = json_merge_patch(p_target, itv_alue, p_patch, ipv_alue, i_depth + u32(1))
				if rc {
					return rc
				}
				p_target.delta += saved_delta
			}
		} else if int(x) > 0 {
			sz_new := sz_pl_abel + npl_abel
			if (int(p_patch.aBlob[ipv_alue]) & 15) != 12 {
				json_blob_edit(p_target, ite_nd, u32(0), unsafe { nil }, sz_pv_alue + npv_alue + sz_new)
				if p_target.oom {
					return 3
				}
				C.memcpy(voidptr(unsafe { p_target.aBlob + ite_nd }), voidptr(unsafe { p_patch.aBlob + ipl_abel }), u64(sz_new))
				C.memcpy(voidptr(unsafe { p_target.aBlob + (ite_nd + sz_new) }), voidptr(unsafe { p_patch.aBlob + ipv_alue }), u64(sz_pv_alue + npv_alue))
			} else {
				rc := 0
				saved_delta := 0

				json_blob_edit(p_target, ite_nd, u32(0), unsafe { nil }, sz_new + u32(1))
				if p_target.oom {
					return 3
				}
				C.memcpy(voidptr(unsafe { p_target.aBlob + ite_nd }), voidptr(unsafe { p_patch.aBlob + ipl_abel }), u64(sz_new))
				p_target.aBlob[ite_nd + sz_new] = U8(0)
				saved_delta = p_target.delta
				p_target.delta = 0
				if i_depth >= u32(1000) {
					return 4
				}
				rc = json_merge_patch(p_target, ite_nd + sz_new, p_patch, ipv_alue, i_depth + u32(1))
				if rc {
					return rc
				}
				p_target.delta += saved_delta
			}
		}
	}
	if p_target.delta {
		json_after_edit_size_adjust(p_target, i_target)
	}
	return if int(p_target.oom) { 3 } else { 0 }
}

@[c:'jsonPatchFunc']
fn json_patch_func(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	p_target := &JsonParse(0)
	p_patch := &JsonParse(0)
	rc := 0

	p_target = json_parse_func_arg(ctx, argv[0], u32(1))
	if usize(p_target) == usize(0) {
		return
	}
	p_patch = json_parse_func_arg(ctx, argv[1], u32(0))
	if p_patch {
		rc = json_merge_patch(p_target, u32(0), p_patch, u32(0), u32(0))
		if rc == 0 {
			json_return_parse(ctx, p_target)
		} else if rc == 3 {
			sqlite3_result_error_nomem(ctx)
		} else if rc == 4 {
			sqlite3_result_error(ctx, c'JSON nested too deep', -1)
		} else {
			sqlite3_result_error(ctx, c'malformed JSON', -1)
		}
		json_parse_free(p_patch)
	}
	json_parse_free(p_target)
}

@[c:'jsonObjectFunc']
fn json_object_func(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	i := 0
	jx := JsonString{}
	z := &i8(0)
	n := u32(0)
	if argc & 1 {
		sqlite3_result_error(ctx, c'json_object() requires an even number of arguments', -1)
		return
	}
	json_string_init(&jx, ctx)
	json_append_char(&jx, i8(`{`))
	for i = 0; i < argc; i += 2 {
		if sqlite3_value_type(argv[i]) != 3 {
			sqlite3_result_error(ctx, c'json_object() labels must be TEXT', -1)
			json_string_reset(&jx)
			return
		}
		json_append_separator(&jx)
		z = &i8(voidptr(sqlite3_value_text(argv[i])))
		n = u32(sqlite3_value_bytes(argv[i]))
		json_append_string(&jx, z, n)
		json_append_char(&jx, i8(`:`))
		json_append_sql_value(&jx, argv[i + 1])
	}
	json_append_char(&jx, i8(`}`))
	json_return_string(&jx, unsafe { nil }, unsafe { nil })
	sqlite3_result_subtype(ctx, u32(74))
}

@[c:'jsonRemoveFunc']
fn json_remove_func(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &JsonParse(0)
	z_path := unsafe { &i8(nil) }
	i := 0
	rc := u32(0)
	if argc < 1 {
		return
	}
	p = json_parse_func_arg(ctx, argv[0], u32(if argc > 1 { 1 } else { 0 }))
	if usize(p) == usize(0) {
		return
	}
	for i = 1; i < argc; i++ {
		z_path = &i8(voidptr(sqlite3_value_text(argv[i])))
		if usize(z_path) == usize(0) {
			unsafe { goto json_remove_done
			 }
		}
		if int(z_path[0]) != i8(`$`) {
			unsafe { goto json_remove_patherror
			 }
		}
		if int(z_path[1]) == 0 {
			unsafe { goto json_remove_done
			 }
		}
		p.eEdit = U8(1)
		p.delta = 0
		rc = json_lookup_step(p, u32(0), z_path + 1, u32(0))
		if (rc >= u32(4294967291)) {
			if rc == u32(4294967294) {
				continue
			} else {
				json_bad_path_error(ctx, z_path, int(rc))
			}
			unsafe { goto json_remove_done
			 }
		}
	}
	json_return_parse(ctx, p)
	json_parse_free(p)
	return
	json_remove_patherror:
	json_bad_path_error(ctx, z_path, 0)
	json_remove_done:
	json_parse_free(p)
	return
}

@[c:'jsonReplaceFunc']
fn json_replace_func(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	if argc < 1 {
		return
	}
	if (argc & 1) == 0 {
		json_wrong_num_args(ctx, c'replace')
		return
	}
	json_insert_into_blob(ctx, argc, argv, 2)
}

@[c:'jsonSetFunc']
fn json_set_func(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	flags := (int(i64(sqlite3_user_data(ctx))))
	e_ins_type := ((flags & 12) >> 2)
	if !json_set_func_az_ins_type_inited {
		c2v_static_init := [c'insert', c'set', c'array_insert']
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			json_set_func_az_ins_type[c2v_i_0] = c2v_element_0
		}
		json_set_func_az_ins_type_inited = true
	}

	if !json_set_func_a_edit_type_inited {
		c2v_static_init := [U8(3), U8(4), U8(5)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			json_set_func_a_edit_type[c2v_i_0] = c2v_element_0
		}
		json_set_func_a_edit_type_inited = true
	}

	if argc < 1 {
		return
	}
	if (argc & 1) == 0 {
		json_wrong_num_args(ctx, json_set_func_az_ins_type[e_ins_type])
		return
	}
	json_insert_into_blob(ctx, argc, argv, int(json_set_func_a_edit_type[e_ins_type]))
}

@[c:'jsonTypeFunc']
fn json_type_func(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &JsonParse(0)
	z_path := unsafe { &i8(nil) }
	i := u32(0)
	p = json_parse_func_arg(ctx, argv[0], u32(0))
	if usize(p) == usize(0) {
		return
	}
	if argc == 2 {
		z_path = &i8(voidptr(sqlite3_value_text(argv[1])))
		if usize(z_path) == usize(0) {
			unsafe { goto json_type_done
			 }
		}
		if int(z_path[0]) != i8(`$`) {
			json_bad_path_error(ctx, z_path, 0)
			unsafe { goto json_type_done
			 }
		}
		i = json_lookup_step(p, u32(0), z_path + 1, u32(0))
		if (i >= u32(4294967291)) {
			if i == u32(4294967294) {
			} else {
				json_bad_path_error(ctx, z_path, int(i))
			}
			unsafe { goto json_type_done
			 }
		}
	} else {
		i = u32(0)
	}
	sqlite3_result_text(ctx, jsonbType[int(p.aBlob[i]) & 15], -1, (C2vFn_666e2028766f696470747229(voidptr(0))))
	json_type_done:
	json_parse_free(p)
}

@[c:'jsonPrettyFunc']
fn json_pretty_func(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	s := JsonString{}
	x := JsonPretty{}
	C.memset(voidptr(&x), 0, sizeof(x))
	x.pParse = json_parse_func_arg(ctx, argv[0], u32(0))
	if usize(x.pParse) == usize(0) {
		return
	}
	x.pOut = &s
	json_string_init(&s, ctx)
	if argc == 1 || usize(c2v_assign[&i8](unsafe { &x.zIndent }, &i8(voidptr(sqlite3_value_text(argv[1]))))) == usize(0) {
		x.zIndent = c'    '
		x.szIndent = u32(4)
	} else {
		x.szIndent = u32(C.strlen(x.zIndent))
	}
	json_translate_blob_to_pretty_text(&x, u32(0))
	json_return_string(&s, unsafe { nil }, unsafe { nil })
	json_parse_free(x.pParse)
}

@[c:'jsonValidFunc']
fn json_valid_func(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &JsonParse(0)
	flags := U8(1)
	res := U8(0)
	if argc == 2 {
		f := sqlite3_value_int64(argv[1])
		if f < I64(1) || f > I64(15) {
			sqlite3_result_error(ctx, c'FLAGS parameter to json_valid() must be between 1 and 15', -1)
			return
		}
		flags = U8(f & I64(15))
	}
	match sqlite3_value_type(argv[0]) {
		5 {
			return
		}
		4 {
			py := JsonParse{}
			C.memset(voidptr(&py), 0, sizeof(py))
			if json_arg_is_jsonb(argv[0], &py) {
				if int(flags) & 4 {
					res = U8(1)
				} else if int(flags) & 8 {
					res = U8(u32(0) == jsonb_validity_check(&py, u32(0), py.nBlob, u32(1)))
				}
				unsafe { goto c2v_switch_end_90
				 }
			}

			unsafe { goto c2v_case_90_2
			 }
		}
		else {
			c2v_case_90_2:
			px := JsonParse{}
			if (int(flags) & 3) == 0 {
				unsafe { goto c2v_switch_end_90
				 }
			}
			C.memset(voidptr(&px), 0, sizeof(px))
			p = json_parse_func_arg(ctx, argv[0], u32(2))
			if p {
				if p.oom {
					sqlite3_result_error_nomem(ctx)
				} else if p.nErr {
				} else if (int(flags) & 2) != 0 || int(p.hasNonstd) == 0 {
					res = U8(1)
				}
				json_parse_free(p)
			} else {
				sqlite3_result_error_nomem(ctx)
			}
		}
	}
	c2v_switch_end_90:

	sqlite3_result_int(ctx, int(res))
}

@[c:'jsonErrorFunc']
fn json_error_func(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	i_err_pos := I64(0)
	s := JsonParse{}

	C.memset(voidptr(&s), 0, sizeof(s))
	s.db = sqlite3_context_db_handle(ctx)
	if json_arg_is_jsonb(argv[0], &s) {
		i_err_pos = I64(jsonb_validity_check(&s, u32(0), s.nBlob, u32(1)))
	} else {
		s.zJson = &i8(voidptr(sqlite3_value_text(argv[0])))
		if usize(s.zJson) == usize(0) {
			return
		}
		s.nJson = sqlite3_value_bytes(argv[0])
		if json_convert_text_to_blob(&s, unsafe { nil }) {
			if s.oom {
				i_err_pos = I64(-1)
			} else {
				k := u32(0)
				for k = u32(0); k < s.iErr && int(s.zJson[k]); k++ {
					if (int(s.zJson[k]) & 192) != 128 {
						i_err_pos++
					}
				}
				i_err_pos++
			}
		}
	}
	json_parse_reset(&s)
	if i_err_pos < I64(0) {
		sqlite3_result_error_nomem(ctx)
	} else {
		sqlite3_result_int64(ctx, i_err_pos)
	}
}

@[c:'jsonArrayStep']
fn json_array_step(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	p_str := &JsonString(0)

	p_str = &JsonString(sqlite3_aggregate_context(ctx, int(sizeof(JsonString))))
	if p_str {
		if usize(p_str.zBuf) == usize(0) {
			json_string_init(p_str, ctx)
			json_append_char(p_str, i8(`[`))
		} else if p_str.nUsed > U64(1) {
			json_append_char(p_str, i8(`,`))
		}
		p_str.pCtx = ctx
		json_append_sql_value(p_str, argv[0])
	}
}

@[c:'jsonArrayCompute']
fn json_array_compute(ctx &Sqlite3_context, is_final int) {
	p_str := &JsonString(0)
	flags := (int(i64(sqlite3_user_data(ctx))))
	p_str = &JsonString(sqlite3_aggregate_context(ctx, 0))
	if p_str {
		p_str.pCtx = ctx
		json_append_raw_nz(p_str, c']', u32(2))
		json_string_trim_one_char(p_str)
		if p_str.eErr {
			json_return_string(p_str, unsafe { nil }, unsafe { nil })
			return
		} else if flags & 16 {
			json_return_string_as_blob(p_str)
			if is_final {
				if !p_str.bStatic {
					sqlite3_rc_str_unref(voidptr(p_str.zBuf))
				}
			} else {
				json_string_trim_one_char(p_str)
			}
			return
		} else if is_final {
			sqlite3_result_text(ctx, p_str.zBuf, int(p_str.nUsed), if int(p_str.bStatic) {
				(C2vFn_666e2028766f696470747229(voidptr(-1)))
			} else {
				sqlite3_rc_str_unref
			})
			p_str.bStatic = U8(1)
		} else {
			sqlite3_result_text(ctx, p_str.zBuf, int(p_str.nUsed), (C2vFn_666e2028766f696470747229(voidptr(-1))))
			json_string_trim_one_char(p_str)
		}
	} else if flags & 16 {
		if !json_array_compute_empty_array_inited {
			json_array_compute_empty_array = U8(11)
			json_array_compute_empty_array_inited = true
		}

		sqlite3_result_blob(ctx, voidptr(&json_array_compute_empty_array), 1, (C2vFn_666e2028766f696470747229(voidptr(0))))
	} else {
		sqlite3_result_text(ctx, c'[]', 2, (C2vFn_666e2028766f696470747229(voidptr(0))))
	}
	sqlite3_result_subtype(ctx, u32(74))
}

@[c:'jsonArrayValue']
fn json_array_value(ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	json_array_compute(ctx, 0)
}

@[c:'jsonArrayFinal']
fn json_array_final(ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	json_array_compute(ctx, 1)
}

@[c:'jsonGroupInverse']
fn json_group_inverse(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	i := u32(0)
	in_str := 0
	n_nest := 0
	z := &i8(0)
	c := i8(0)
	p_str := &JsonString(0)

	p_str = &JsonString(sqlite3_aggregate_context(ctx, 0))
	if (isnil(p_str)) {
		return
	}
	z = p_str.zBuf
	for i = u32(1); U64(i) < p_str.nUsed && (int(c2v_assign[i8](unsafe { &c }, i8(z[i]))) != i8(`,`) || in_str || n_nest); i++ {
		if int(c) == i8(`\"`) {
			in_str = !in_str
		} else if int(c) == i8(`\\`) {
			i++
		} else if !in_str {
			if int(c) == i8(`{`) || int(c) == i8(`[`) {
				n_nest++
			}
			if int(c) == i8(`}`) || int(c) == i8(`]`) {
				n_nest--
			}
		}
	}
	if U64(i) < p_str.nUsed {
		p_str.nUsed -= U64(i)
		C.memmove(voidptr(unsafe { z + 1 }), voidptr(unsafe { z + (i + u32(1)) }), usize(p_str.nUsed) - usize(1))
		z[p_str.nUsed] = i8(0)
	} else {
		p_str.nUsed = U64(1)
	}
}

@[c:'jsonObjectStep']
fn json_object_step(ctx &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	p_str := &JsonString(0)
	z := &i8(0)
	n := u32(0)

	p_str = &JsonString(sqlite3_aggregate_context(ctx, int(sizeof(JsonString))))
	if p_str {
		z = &i8(voidptr(sqlite3_value_text(argv[0])))
		n = u32(sqlite3_strlen30(z))
		if usize(p_str.zBuf) == usize(0) {
			json_string_init(p_str, ctx)
			json_append_char(p_str, i8(`{`))
		} else if p_str.nUsed > U64(1) {
			json_append_char(p_str, i8(`,`))
		}
		p_str.pCtx = ctx
		if usize(z) != usize(0) {
			json_append_string(p_str, z, n)
			json_append_char(p_str, i8(`:`))
			json_append_sql_value(p_str, argv[1])
		} else {
			p_str.zBuf[0] = i8(`@`)
			json_append_raw_nz(p_str, c'@', u32(1))
		}
	}
}

@[c:'jsonObjectCompute']
fn json_object_compute(ctx &Sqlite3_context, is_final int) {
	p_str := &JsonString(0)
	flags := (int(i64(sqlite3_user_data(ctx))))
	p_str = &JsonString(sqlite3_aggregate_context(ctx, 0))
	if p_str {
		p_og_str := p_str
		tmp_str := JsonString{}
		json_append_raw_nz(p_og_str, c'}', u32(2))
		json_string_trim_one_char(p_og_str)
		p_str.pCtx = ctx
		if p_str.eErr {
			json_return_string(p_str, unsafe { nil }, unsafe { nil })
			return
		}
		if int(p_str.zBuf[0]) != i8(`{`) {
			i := U64(0)
			j := U64(0)

			in_str := 0
			if !is_final {
				json_string_init(&tmp_str, ctx)
				json_append_raw_nz(&tmp_str, p_str.zBuf, u32(p_str.nUsed + U64(1)))
				p_str = &tmp_str
				if p_str.eErr {
					json_return_string(p_str, unsafe { nil }, unsafe { nil })
					return
				}
				json_string_trim_one_char(p_str)
			}
			p_str.zBuf[0] = i8(`{`)
			j = U64(1)
			for i = U64(1); i < p_str.nUsed; i++ {
				c := p_str.zBuf[i]
				if int(c) == i8(`\"`) {
					in_str = !in_str
					p_str.zBuf[j++] = i8(`\"`)
				} else if int(c) == i8(`\\`) {
					p_str.zBuf[j++] = i8(`\\`)
					p_str.zBuf[j++] = p_str.zBuf[c2v_prefix_add(unsafe { &i }, u64(1))]
				} else if int(c) == i8(`@`) && !in_str {
					if int(p_str.zBuf[i + U64(1)]) == i8(`,`) {
						i++
					} else if int(p_str.zBuf[j - U64(1)]) == i8(`,`) {
						j--
					}
				} else {
					p_str.zBuf[j++] = c
				}
			}
			p_str.zBuf[j] = i8(0)
			p_str.nUsed = j
		}
		if flags & 16 {
			json_return_string_as_blob(p_str)
			if is_final {
				if !p_str.bStatic {
					sqlite3_rc_str_unref(voidptr(p_str.zBuf))
				}
			} else {
				json_string_trim_one_char(p_og_str)
			}
		} else if is_final {
			sqlite3_result_text(ctx, p_str.zBuf, int(p_str.nUsed), if int(p_str.bStatic) {
				(C2vFn_666e2028766f696470747229(voidptr(-1)))
			} else {
				sqlite3_rc_str_unref
			})
			p_str.bStatic = U8(1)
		} else {
			sqlite3_result_text(ctx, p_str.zBuf, int(p_str.nUsed), (C2vFn_666e2028766f696470747229(voidptr(-1))))
			json_string_trim_one_char(p_og_str)
		}
		if usize(p_str) != usize(p_og_str) {
			json_string_reset(p_str)
		}
	} else if flags & 16 {
		if !json_object_compute_empty_object_inited {
			json_object_compute_empty_object = u8(12)
			json_object_compute_empty_object_inited = true
		}

		sqlite3_result_blob(ctx, voidptr(&json_object_compute_empty_object), 1, (C2vFn_666e2028766f696470747229(voidptr(0))))
	} else {
		sqlite3_result_text(ctx, c'{}', 2, (C2vFn_666e2028766f696470747229(voidptr(0))))
	}
	sqlite3_result_subtype(ctx, u32(74))
}

@[c:'jsonObjectValue']
fn json_object_value(ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	json_object_compute(ctx, 0)
}

@[c:'jsonObjectFinal']
fn json_object_final(ctx &Sqlite3_context) {
	c2v_gc_register_thread()
	json_object_compute(ctx, 1)
}

struct JsonParent {
	iHead  u32
	iValue u32
	iEnd   u32
	nPath  u32
	iKey   I64
}

struct JsonEachCursor {
	base         Sqlite3_vtab_cursor
	iRowid       u32
	i            u32
	iEnd         u32
	nRoot        u32
	eType        U8
	bRecursive   U8
	eMode        U8
	nParent      u32
	nParentAlloc u32
	aParent      &JsonParent
	db           &Sqlite3
	path         JsonString
	sParse       JsonParse
}

struct JsonEachConnection {
	base       Sqlite3_vtab
	db         &Sqlite3
	eMode      U8
	bRecursive U8
}

@[c:'jsonEachConnect']
fn json_each_connect(db &Sqlite3, p_aux voidptr, argc int, argv &&u8, pp_vtab &&Sqlite3_vtab, pz_err &&u8) int {
	c2v_gc_register_thread()
	p_new := &JsonEachConnection(0)
	rc := 0

	rc = sqlite3_declare_vtab(db, c'CREATE TABLE x(key,value,type,atom,id,parent,fullkey,path,json HIDDEN,root HIDDEN)')
	if rc == 0 {
		p_new = &JsonEachConnection(sqlite3_db_malloc_zero(db, U64(sizeof(JsonEachConnection))))
		unsafe { *pp_vtab = &Sqlite3_vtab(voidptr(p_new)) }
		if usize(p_new) == usize(0) {
			return 7
		}
		sqlite3_vtab_config(db, 2)
		p_new.db = db
		p_new.eMode = U8(if int(argv[0][4]) == i8(`b`) { 2 } else { 1 })
		p_new.bRecursive = U8(int(argv[0][4 + int(p_new.eMode)]) == i8(`t`))
	}
	return rc
}

@[c:'jsonEachDisconnect']
fn json_each_disconnect(p_vtab &Sqlite3_vtab) int {
	c2v_gc_register_thread()
	p := &JsonEachConnection(voidptr(p_vtab))
	sqlite3_db_free(p.db, voidptr(p_vtab))
	return 0
}

@[c:'jsonEachOpen']
fn json_each_open(p &Sqlite3_vtab, pp_cursor &&Sqlite3_vtab_cursor) int {
	c2v_gc_register_thread()
	p_vtab := &JsonEachConnection(voidptr(p))
	p_cur := &JsonEachCursor(0)

	p_cur = sqlite3_db_malloc_zero(p_vtab.db, U64(sizeof(JsonEachCursor)))
	if usize(p_cur) == usize(0) {
		return 7
	}
	p_cur.db = p_vtab.db
	p_cur.eMode = p_vtab.eMode
	p_cur.bRecursive = p_vtab.bRecursive
	json_string_zero(&p_cur.path)
	unsafe { *pp_cursor = &p_cur.base }
	return 0
}

@[c:'jsonEachCursorReset']
fn json_each_cursor_reset(p &JsonEachCursor) {
	json_parse_reset(&p.sParse)
	json_string_reset(&p.path)
	sqlite3_db_free(p.db, voidptr(p.aParent))
	p.iRowid = u32(0)
	p.i = u32(0)
	p.aParent = 0
	p.nParent = u32(0)
	p.nParentAlloc = u32(0)
	p.iEnd = u32(0)
	p.eType = U8(0)
}

@[c:'jsonEachClose']
fn json_each_close(cur &Sqlite3_vtab_cursor) int {
	c2v_gc_register_thread()
	p := &JsonEachCursor(voidptr(cur))
	json_each_cursor_reset(p)
	sqlite3_db_free(p.db, voidptr(cur))
	return 0
}

@[c:'jsonEachEof']
fn json_each_eof(cur &Sqlite3_vtab_cursor) int {
	c2v_gc_register_thread()
	p := &JsonEachCursor(voidptr(cur))
	return int(p.i >= p.iEnd)
}

@[c:'jsonSkipLabel']
fn json_skip_label(p &JsonEachCursor) int {
	if int(p.eType) == 12 {
		sz := u32(0)
		n := jsonb_payload_size(&p.sParse, p.i, &sz)
		sz += p.i + n
		if sz >= p.sParse.nBlob {
			sz = p.i
		}
		return int(sz)
	} else {
		return int(p.i)
	}
}

@[c:'jsonAppendPathName']
fn json_append_path_name(p &JsonEachCursor) {
	if int(p.eType) == 11 {
		json_printf(30, &p.path, c'[%lld]', p.aParent[p.nParent - u32(1)].iKey)
	} else {
		n := u32(0)
		sz := u32(0)
		k := u32(0)
		i := u32(0)

		z := &i8(0)
		need_quote := 0
		n = jsonb_payload_size(&p.sParse, p.i, &sz)
		k = p.i + n
		z = &i8(voidptr(unsafe { p.sParse.aBlob + k }))
		if sz == u32(0) || !(int(sqlite3CtypeMap[u8(z[0])]) & 2) {
			need_quote = 1
		} else {
			for i = u32(0); i < sz; i++ {
				if !(int(sqlite3CtypeMap[u8(z[i])]) & 6) {
					need_quote = 1
					break
				}
			}
		}
		if need_quote {
			json_printf(int(sz + u32(4)), &p.path, c'."%.*s"', sz, voidptr(z))
		} else {
			json_printf(int(sz + u32(2)), &p.path, c'.%.*s', sz, voidptr(z))
		}
	}
}

@[c:'jsonEachNext']
fn json_each_next(cur &Sqlite3_vtab_cursor) int {
	c2v_gc_register_thread()
	p := &JsonEachCursor(voidptr(cur))
	rc := 0
	if p.bRecursive {
		x := U8(0)
		level_change := U8(0)
		n := u32(0)
		sz := u32(0)

		i := u32(json_skip_label(p))
		x = U8(int(p.sParse.aBlob[i]) & 15)
		n = jsonb_payload_size(&p.sParse, i, &sz)
		if int(x) == 12 || int(x) == 11 {
			p_parent := &JsonParent(0)
			if p.nParent >= p.nParentAlloc {
				p_new := &JsonParent(0)
				n_new := U64(0)
				n_new = U64(p.nParentAlloc * u32(2) + u32(3))
				p_new = sqlite3_db_realloc(p.db, voidptr(p.aParent), U64(sizeof(JsonParent)) * n_new)
				if usize(p_new) == usize(0) {
					return 7
				}
				p.nParentAlloc = u32(n_new)
				p.aParent = p_new
			}
			level_change = U8(1)
			p_parent = unsafe { p.aParent + p.nParent }
			p_parent.iHead = p.i
			p_parent.iValue = i
			p_parent.iEnd = i + n + sz
			p_parent.iKey = I64(-1)
			p_parent.nPath = u32(p.path.nUsed)
			if int(p.eType) && p.nParent {
				json_append_path_name(p)
				if p.path.eErr {
					rc = 7
				}
			}
			p.nParent++
			p.i = i + n
		} else {
			p.i = i + n + sz
		}
		for p.nParent > u32(0) && p.i >= p.aParent[p.nParent - u32(1)].iEnd {
			p.nParent--
			p.path.nUsed = U64(p.aParent[p.nParent].nPath)
			level_change = U8(1)
		}
		if level_change {
			if p.nParent > u32(0) {
				p_parent := unsafe { p.aParent + (p.nParent - u32(1)) }
				i_val := p_parent.iValue
				p.eType = U8(int(p.sParse.aBlob[i_val]) & 15)
			} else {
				p.eType = U8(0)
			}
		}
	} else {
		n := u32(0)
		sz := u32(0)

		i := u32(json_skip_label(p))
		n = jsonb_payload_size(&p.sParse, i, &sz)
		p.i = i + n + sz
	}
	if int(p.eType) == 11 && p.nParent {
		unsafe { p.aParent[p.nParent - u32(1)].iKey++ }
	}
	p.iRowid++
	return rc
}

@[c:'jsonEachPathLength']
fn json_each_path_length(p &JsonEachCursor) int {
	n := u32(p.path.nUsed)
	z := p.path.zBuf
	if p.iRowid == u32(0) && int(p.bRecursive) && n >= u32(2) {
		for n > u32(1) {
			n--
			if int(z[n]) == i8(`[`) || int(z[n]) == i8(`.`) {
				x := u32(0)
				sz := u32(0)

				c_saved := z[n]
				z[n] = i8(0)
				x = json_lookup_step(&p.sParse, u32(0), z + 1, u32(0))
				z[n] = c_saved
				if (x >= u32(4294967291)) {
					continue
				}
				if x + jsonb_payload_size(&p.sParse, x, &sz) == p.i {
					break
				}
			}
		}
	}
	return int(n)
}

@[c:'jsonEachColumn']
fn json_each_column(cur &Sqlite3_vtab_cursor, ctx &Sqlite3_context, i_column int) int {
	c2v_gc_register_thread()
	p := &JsonEachCursor(voidptr(cur))
	match i_column {
		0 {
			if p.nParent == u32(0) {
				n := u32(0)
				j := u32(0)

				if p.nRoot == u32(1) {
					unsafe { goto c2v_switch_end_91
					 }
				}
				j = u32(json_each_path_length(p))
				n = p.nRoot - j
				if n == u32(0) {
					unsafe { goto c2v_switch_end_91
					 }
				} else if int(p.path.zBuf[j]) == i8(`[`) {
					x := I64(0)
					sqlite3_atoi64(unsafe { p.path.zBuf + (j + u32(1)) }, &x, int(n - u32(1)), U8(1))
					sqlite3_result_int64(ctx, x)
				} else if int(p.path.zBuf[j + u32(1)]) == i8(`\"`) {
					sqlite3_result_text(ctx, unsafe { p.path.zBuf + (j + u32(2)) }, int(n - u32(3)), (C2vFn_666e2028766f696470747229(voidptr(-1))))
				} else {
					sqlite3_result_text(ctx, unsafe { p.path.zBuf + (j + u32(1)) }, int(n - u32(1)), (C2vFn_666e2028766f696470747229(voidptr(-1))))
				}
				unsafe { goto c2v_switch_end_91
				 }
			}
			if int(p.eType) == 12 {
				json_return_from_blob(&p.sParse, p.i, ctx, 1)
			} else {
				sqlite3_result_int64(ctx, p.aParent[p.nParent - u32(1)].iKey)
			}
		}
		1 {
			i := u32(json_skip_label(p))
			json_return_from_blob(&p.sParse, i, ctx, int(p.eMode))
			if (int(p.sParse.aBlob[i]) & 15) >= 11 {
				sqlite3_result_subtype(ctx, u32(74))
			}
		}
		2 {
			i := u32(json_skip_label(p))
			e_type := U8(int(p.sParse.aBlob[i]) & 15)
			sqlite3_result_text(ctx, jsonbType[e_type], -1, (C2vFn_666e2028766f696470747229(voidptr(0))))
		}
		3 {
			i := u32(json_skip_label(p))
			if (int(p.sParse.aBlob[i]) & 15) < 11 {
				json_return_from_blob(&p.sParse, i, ctx, 1)
			}
		}
		4 {
			sqlite3_result_int64(ctx, Sqlite3_int64(p.i))
		}
		5 {
			if p.nParent > u32(0) && int(p.bRecursive) {
				sqlite3_result_int64(ctx, Sqlite3_int64(p.aParent[p.nParent - u32(1)].iHead))
			}
		}
		6 {
			n_base := p.path.nUsed
			if p.nParent {
				json_append_path_name(p)
			}
			sqlite3_result_text64(ctx, p.path.zBuf, p.path.nUsed, (C2vFn_666e2028766f696470747229(voidptr(-1))), u8(1))
			p.path.nUsed = n_base
		}
		7 {
			n := u32(json_each_path_length(p))
			sqlite3_result_text64(ctx, p.path.zBuf, Sqlite3_uint64(n), (C2vFn_666e2028766f696470747229(voidptr(-1))), u8(1))
		}
		8 {
			if usize(p.sParse.zJson) == usize(0) {
				sqlite3_result_blob(ctx, voidptr(p.sParse.aBlob), int(p.sParse.nBlob), (C2vFn_666e2028766f696470747229(voidptr(-1))))
			} else {
				sqlite3_result_text(ctx, p.sParse.zJson, -1, (C2vFn_666e2028766f696470747229(voidptr(-1))))
			}
		}
		else {
			sqlite3_result_text(ctx, p.path.zBuf, int(p.nRoot), (C2vFn_666e2028766f696470747229(voidptr(0))))
		}
	}
	c2v_switch_end_91:

	return 0
}

@[c:'jsonEachRowid']
fn json_each_rowid(cur &Sqlite3_vtab_cursor, p_rowid &Sqlite_int64) int {
	c2v_gc_register_thread()
	p := &JsonEachCursor(voidptr(cur))
	unsafe { *p_rowid = Sqlite_int64(p.iRowid) }
	return 0
}

@[c:'jsonEachBestIndex']
fn json_each_best_index(tab &Sqlite3_vtab, p_idx_info &Sqlite3_index_info) int {
	c2v_gc_register_thread()
	i := 0
	a_idx := [2]int{}
	unusable_mask := 0
	idx_mask := 0
	p_constraint := &Sqlite3_index_constraint(0)

	a_idx[1] = -1
	a_idx[0] = a_idx[1]
	p_constraint = p_idx_info.aConstraint
	for i = 0; i < p_idx_info.nConstraint; i++ {
		i_col := 0
		i_mask := 0
		if p_constraint.iColumn < 8 {
			unsafe { goto c2v_for_next_223
			 }
		}
		i_col = p_constraint.iColumn - 8
		0
		i_mask = 1 << i_col
		if int(p_constraint.usable) == 0 {
			unusable_mask |= i_mask
		} else if int(p_constraint.op) == 2 {
			a_idx[i_col] = i
			idx_mask |= i_mask
		}
		c2v_for_next_223:
		c2v_pointer_postfix(voidptr(&p_constraint), p_constraint, isize(1))
	}
	if p_idx_info.nOrderBy > 0 && p_idx_info.aOrderBy[0].iColumn < 0 && int(p_idx_info.aOrderBy[0].desc) == 0 {
		p_idx_info.orderByConsumed = 1
	}
	if (unusable_mask & ~idx_mask) != 0 {
		return 19
	}
	if a_idx[0] < 0 {
		p_idx_info.idxNum = 0
	} else {
		p_idx_info.estimatedCost = 1.0
		i = a_idx[0]
		p_idx_info.aConstraintUsage[i].argvIndex = 1
		p_idx_info.aConstraintUsage[i].omit = u8(1)
		if a_idx[1] < 0 {
			p_idx_info.idxNum = 1
		} else {
			i = a_idx[1]
			p_idx_info.aConstraintUsage[i].argvIndex = 2
			p_idx_info.aConstraintUsage[i].omit = u8(1)
			p_idx_info.idxNum = 3
		}
	}
	return 0
}

@[c:'jsonEachFilter']
fn json_each_filter(cur &Sqlite3_vtab_cursor, idx_num int, idx_str &i8, argc int, argv &&Sqlite3_value) int {
	c2v_gc_register_thread()
	p := &JsonEachCursor(voidptr(cur))
	z_root := unsafe { &i8(nil) }
	i := u32(0)
	n := u32(0)
	sz := u32(0)

	json_each_cursor_reset(p)
	if idx_num == 0 {
		return 0
	}
	C.memset(voidptr(&p.sParse), 0, sizeof(JsonParse))
	p.sParse.nJPRef = u32(1)
	p.sParse.db = p.db
	if json_arg_is_jsonb(argv[0], &p.sParse) {
	} else {
		p.sParse.zJson = &i8(voidptr(sqlite3_value_text(argv[0])))
		p.sParse.nJson = sqlite3_value_bytes(argv[0])
		if usize(p.sParse.zJson) == usize(0) {
			p.iEnd = u32(0)
			p.i = p.iEnd
			return 0
		}
		if json_convert_text_to_blob(&p.sParse, unsafe { nil }) {
			if p.sParse.oom {
				return 7
			}
			unsafe { goto json_each_malformed_input
			 }
		}
	}
	if idx_num == 3 {
		z_root = &i8(voidptr(sqlite3_value_text(argv[1])))
		if usize(z_root) == usize(0) {
			return 0
		}
		if int(z_root[0]) != i8(`$`) {
			sqlite3_free(voidptr(cur.pVtab.zErrMsg))
			cur.pVtab.zErrMsg = json_bad_path_error(unsafe { nil }, z_root, 0)
			json_each_cursor_reset(p)
			return if cur.pVtab.zErrMsg { 1 } else { 7 }
		}
		p.nRoot = u32(sqlite3_strlen30(z_root))
		if int(z_root[1]) == 0 {
			p.i = u32(0)
			i = p.i
			p.eType = U8(0)
		} else {
			i = json_lookup_step(&p.sParse, u32(0), z_root + 1, u32(0))
			if (i >= u32(4294967291)) {
				if i == u32(4294967294) {
					p.i = u32(0)
					p.eType = U8(0)
					p.iEnd = u32(0)
					return 0
				}
				sqlite3_free(voidptr(cur.pVtab.zErrMsg))
				cur.pVtab.zErrMsg = json_bad_path_error(unsafe { nil }, z_root, 0)
				json_each_cursor_reset(p)
				return if cur.pVtab.zErrMsg { 1 } else { 7 }
			}
			if p.sParse.iLabel {
				p.i = p.sParse.iLabel
				p.eType = U8(12)
			} else {
				p.i = i
				p.eType = U8(11)
			}
		}
		json_append_raw(&p.path, z_root, p.nRoot)
	} else {
		p.i = u32(0)
		i = p.i
		p.eType = U8(0)
		p.nRoot = u32(1)
		json_append_raw(&p.path, c'$', u32(1))
	}
	p.nParent = u32(0)
	n = jsonb_payload_size(&p.sParse, i, &sz)
	p.iEnd = i + n + sz
	if (int(p.sParse.aBlob[i]) & 15) >= 11 && !p.bRecursive {
		p.i = i + n
		p.eType = U8(int(p.sParse.aBlob[i]) & 15)
		p.aParent = sqlite3_db_malloc_zero(p.db, U64(sizeof(JsonParent)))
		if usize(p.aParent) == usize(0) {
			return 7
		}
		p.nParent = u32(1)
		p.nParentAlloc = u32(1)
		p.aParent[0].iKey = I64(0)
		p.aParent[0].iEnd = p.iEnd
		p.aParent[0].iHead = p.i
		p.aParent[0].iValue = i
	}
	return 0
	json_each_malformed_input:
	sqlite3_free(voidptr(cur.pVtab.zErrMsg))
	cur.pVtab.zErrMsg = sqlite3_mprintf(c'malformed JSON')
	json_each_cursor_reset(p)
	return if cur.pVtab.zErrMsg { 1 } else { 7 }
}

@[c:'sqlite3RegisterJsonFunctions']
fn sqlite3_register_json_functions() {
	if !sqlite3_register_json_functions_a_json_func_inited {
		c2v_static_init := [FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (1 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_remove_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((0 | (1 * 16)))))
			pNext: 0
			xSFunc: json_remove_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'jsonb'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (0 * 32768) | (1 * 1048576) | (1 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_array_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_array'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (0 * 32768) | (1 * 1048576) | (1 * 16777216))
			pUserData: (voidptr(i64((0 | (1 * 16)))))
			pNext: 0
			xSFunc: json_array_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'jsonb_array'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (1 * 1048576) | (1 * 16777216))
			pUserData: (voidptr(i64((8 | (0 * 16)))))
			pNext: 0
			xSFunc: json_set_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_array_insert'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (1 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((8 | (1 * 16)))))
			pNext: 0
			xSFunc: json_set_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'jsonb_array_insert'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_array_length_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_array_length'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_array_length_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_array_length'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_error_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_error_position'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (1 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_extract_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_extract'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((0 | (1 * 16)))))
			pNext: 0
			xSFunc: json_extract_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'jsonb_extract'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (1 * 16777216))
			pUserData: (voidptr(i64((1 | (0 * 16)))))
			pNext: 0
			xSFunc: json_extract_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'->'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((2 | (0 * 16)))))
			pNext: 0
			xSFunc: json_extract_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'->>'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (1 * 1048576) | (1 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_set_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_insert'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (1 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((0 | (1 * 16)))))
			pNext: 0
			xSFunc: json_set_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'jsonb_insert'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (0 * 32768) | (1 * 1048576) | (1 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_object_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_object'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (0 * 32768) | (1 * 1048576) | (1 * 16777216))
			pUserData: (voidptr(i64((0 | (1 * 16)))))
			pNext: 0
			xSFunc: json_object_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'jsonb_object'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (1 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_patch_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_patch'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((0 | (1 * 16)))))
			pNext: 0
			xSFunc: json_patch_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'jsonb_patch'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_pretty_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_pretty'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_pretty_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_pretty'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (0 * 32768) | (1 * 1048576) | (1 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_quote_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_quote'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (1 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_remove_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_remove'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((0 | (1 * 16)))))
			pNext: 0
			xSFunc: json_remove_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'jsonb_remove'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (1 * 1048576) | (1 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_replace_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_replace'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (1 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((0 | (1 * 16)))))
			pNext: 0
			xSFunc: json_replace_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'jsonb_replace'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (1 * 1048576) | (1 * 16777216))
			pUserData: (voidptr(i64((4 | (0 * 16)))))
			pNext: 0
			xSFunc: json_set_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_set'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(-1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (1 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((4 | (1 * 16)))))
			pNext: 0
			xSFunc: json_set_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'jsonb_set'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_type_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_type'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_type_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_type'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_valid_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_valid'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 2048 | 2048 | 1 | (1 * 32768) | (0 * 1048576) | (0 * 16777216))
			pUserData: (voidptr(i64((0 | (0 * 16)))))
			pNext: 0
			xSFunc: json_valid_func
			xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
			xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
			zName: c'json_valid'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 1 | (0 * 32) | 1048576 | 16777216 | 1 | 2048)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: json_array_step
			xFinalize: json_array_final
			xValue: json_array_value
			xInverse: json_group_inverse
			zName: c'json_group_array'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(1)
			funcFlags: u32(8388608 | 1 | (0 * 32) | 1048576 | 16777216 | 1 | 2048)
			pUserData: (voidptr(i64(16)))
			pNext: 0
			xSFunc: json_array_step
			xFinalize: json_array_final
			xValue: json_array_value
			xInverse: json_group_inverse
			zName: c'jsonb_group_array'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 1 | (0 * 32) | 1048576 | 16777216 | 1 | 2048)
			pUserData: (voidptr(i64(0)))
			pNext: 0
			xSFunc: json_object_step
			xFinalize: json_object_final
			xValue: json_object_value
			xInverse: json_group_inverse
			zName: c'json_group_object'
			u: FuncDef_u{}
		}, FuncDef{
			nArg: I16(2)
			funcFlags: u32(8388608 | 1 | (0 * 32) | 1048576 | 16777216 | 1 | 2048)
			pUserData: (voidptr(i64(16)))
			pNext: 0
			xSFunc: json_object_step
			xFinalize: json_object_final
			xValue: json_object_value
			xInverse: json_group_inverse
			zName: c'jsonb_group_object'
			u: FuncDef_u{}
		}]!
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_register_json_functions_a_json_func[c2v_i_0] = c2v_element_0
		}
		sqlite3_register_json_functions_a_json_func_inited = true
	}

	sqlite3_insert_builtin_funcs(&sqlite3_register_json_functions_a_json_func[0], 36)
}

@[c:'sqlite3JsonVtabRegister']
fn sqlite3_json_vtab_register(db &Sqlite3, z_name &i8) &Module {
	i := u32(0)
	if !sqlite3_json_vtab_register_az_module_inited {
		c2v_static_init := [c'json_each', c'json_tree', c'jsonb_each', c'jsonb_tree']
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_json_vtab_register_az_module[c2v_i_0] = c2v_element_0
		}
		sqlite3_json_vtab_register_az_module_inited = true
	}

	for i = u32(0); u64(i) < 4; i++ {
		if sqlite3_str_ic_mp(sqlite3_json_vtab_register_az_module[i], z_name) == 0 {
			return sqlite3_vtab_create_module(db, sqlite3_json_vtab_register_az_module[i], &jsonEachModule, unsafe { nil }, unsafe { nil })
		}
	}
	return unsafe { nil }
}
