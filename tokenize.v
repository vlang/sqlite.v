@[translated]
module main

@[c:'sqlite3IsIdChar']
fn sqlite3_is_id_char(c U8) int {
	return int(((int(sqlite3CtypeMap[u8(c)]) & 70) != 0))
}

@[c:'getToken']
fn get_token(pz &&u8) int {
	z := (unsafe { *pz })
	t := 0
	for {
		c2v_pointer_prefix(voidptr(&z), z, isize(sqlite3_get_token(z, &t)))
		if !(t == 184 || t == 185) {
			break
		}
	}
	if t == 60 || t == 118 || t == 119 || t == 165 || t == 166 || sqlite3_parser_fallback(t) == 60 {
		t = 60
	}
	unsafe { *pz = z }
	return t
}

@[c:'analyzeWindowKeyword']
fn analyze_window_keyword(z_param &u8) int {
	mut z := z_param
	t := 0
	t = get_token(&&u8(&&u8(c2v_address_of(&z))))
	if t != 60 {
		return 60
	}
	t = get_token(&&u8(&&u8(c2v_address_of(&z))))
	if t != 24 {
		return 60
	}
	return 165
}

@[c:'analyzeOverKeyword']
fn analyze_over_keyword(z_param &u8, last_token int) int {
	mut z := z_param
	if last_token == 23 {
		t := get_token(&&u8(&&u8(c2v_address_of(&z))))
		if t == 22 || t == 60 {
			return 166
		}
	}
	return 60
}

@[c:'analyzeFilterKeyword']
fn analyze_filter_keyword(z_param &u8, last_token int) int {
	mut z := z_param
	if last_token == 23 && get_token(&&u8(&&u8(c2v_address_of(&z)))) == 22 {
		return 167
	}
	return 60
}

@[c:'sqlite3GetToken']
fn sqlite3_get_token(z &u8, token_type &int) I64 {
	i := I64(0)
	c := 0
	match int(ai_class[(unsafe { *z })]) {
		7 {
			0
			0
			0
			0
			0
			for i = I64(1); (int(sqlite3CtypeMap[u8(z[i])]) & 1); i++ {
			}
			unsafe { *token_type = 184 }
			return i
		}
		11 {
			if int(z[1]) == `-` {
				for i = I64(2); true; i++ {
					c = int(z[i])
					if !(c != 0 && c != `\n`) {
						break
					}
				}
				unsafe { *token_type = 185 }
				return i
			} else if int(z[1]) == `>` {
				unsafe { *token_type = 113 }
				return I64(2 + int((int(z[2]) == `>`)))
			}
			unsafe { *token_type = 108 }
			return I64(1)
		}
		17 {
			unsafe { *token_type = 22 }
			return I64(1)
		}
		18 {
			unsafe { *token_type = 23 }
			return I64(1)
		}
		19 {
			unsafe { *token_type = 1 }
			return I64(1)
		}
		20 {
			unsafe { *token_type = 107 }
			return I64(1)
		}
		21 {
			unsafe { *token_type = 109 }
			return I64(1)
		}
		16 {
			if int(z[1]) != `*` || int(z[2]) == 0 {
				unsafe { *token_type = 110 }
				return I64(1)
			}
			i = I64(3)
			for c = int(z[2]); (c != `*` || int(z[i]) != `/`) && c2v_assign[int](unsafe { &c }, int(z[i])) != 0; i++ {
			}
			if c {
				i++
			}
			unsafe { *token_type = 185 }
			return i
		}
		22 {
			unsafe { *token_type = 111 }
			return I64(1)
		}
		14 {
			unsafe { *token_type = 54 }
			return I64(1 + int((int(z[1]) == `=`)))
		}
		12 {
			c = int(z[1])
			if c == `=` {
				unsafe { *token_type = 56 }
				return I64(2)
			} else if c == `>` {
				unsafe { *token_type = 53 }
				return I64(2)
			} else if c == `<` {
				unsafe { *token_type = 105 }
				return I64(2)
			} else {
				unsafe { *token_type = 57 }
				return I64(1)
			}
		}
		13 {
			c = int(z[1])
			if c == `=` {
				unsafe { *token_type = 58 }
				return I64(2)
			} else if c == `>` {
				unsafe { *token_type = 106 }
				return I64(2)
			} else {
				unsafe { *token_type = 55 }
				return I64(1)
			}
		}
		15 {
			if int(z[1]) != `=` {
				unsafe { *token_type = 186 }
				return I64(1)
			} else {
				unsafe { *token_type = 53 }
				return I64(2)
			}
		}
		10 {
			if int(z[1]) != `|` {
				unsafe { *token_type = 104 }
				return I64(1)
			} else {
				unsafe { *token_type = 112 }
				return I64(2)
			}
		}
		23 {
			unsafe { *token_type = 25 }
			return I64(1)
		}
		24 {
			unsafe { *token_type = 103 }
			return I64(1)
		}
		25 {
			unsafe { *token_type = 115 }
			return I64(1)
		}
		8 {
			delim := int(z[0])
			0
			0
			0
			for i = I64(1); true; i++ {
				c = int(z[i])
				if !(c != 0) {
					break
				}
				if c == delim {
					if int(z[i + I64(1)]) == delim {
						i++
					} else {
						break
					}
				}
			}
			if c == `\'` {
				unsafe { *token_type = 118 }
				return i + I64(1)
			} else if c != 0 {
				unsafe { *token_type = 60 }
				return i + I64(1)
			} else {
				unsafe { *token_type = 186 }
				return i
			}
		}
		26 {
			if !(int(sqlite3CtypeMap[u8(z[1])]) & 4) {
				unsafe { *token_type = 142 }
				return I64(1)
			}

			unsafe { goto c2v_case_70_19
			 }
		}
		3 {
			c2v_case_70_19:
			0
			0
			0
			0
			0
			0
			0
			0
			0
			0
			0
			unsafe { *token_type = 156 }
			if int(z[0]) == `0` && (int(z[1]) == `x` || int(z[1]) == `X`) && (int(sqlite3CtypeMap[u8(z[2])]) & 8) {
				for i = I64(3); 1; i++ {
					if (int(sqlite3CtypeMap[u8(z[i])]) & 8) == 0 {
						if int(z[i]) == `_` {
							unsafe { *token_type = 183 }
						} else {
							break
						}
					}
				}
			} else {
				for i = I64(0); 1; i++ {
					if (int(sqlite3CtypeMap[u8(z[i])]) & 4) == 0 {
						if int(z[i]) == `_` {
							unsafe { *token_type = 183 }
						} else {
							break
						}
					}
				}
				if int(z[i]) == `.` {
					if (unsafe { *token_type }) == 156 {
						unsafe { *token_type = 154 }
					}
					for i++; 1; i++ {
						if (int(sqlite3CtypeMap[u8(z[i])]) & 4) == 0 {
							if int(z[i]) == `_` {
								unsafe { *token_type = 183 }
							} else {
								break
							}
						}
					}
				}
				mut __c2v_condition_144 := false
				mut __c2v_condition_145 := false
				__c2v_condition_145 = (int(z[i]) == `e` || int(z[i]) == `E`)
				if __c2v_condition_145 {
					__c2v_condition_145 = ((int(sqlite3CtypeMap[u8(z[i + I64(1)])]) & 4) || ((int(z[i + I64(1)]) == `+` || int(z[i + I64(1)]) == `-`) && (int(sqlite3CtypeMap[u8(z[i + I64(2)])]) & 4)))
				}
				__c2v_condition_144 = __c2v_condition_145
				if __c2v_condition_144 {
					if (unsafe { *token_type }) == 156 {
						unsafe { *token_type = 154 }
					}
					i += I64(2)
					for 1 {
						if (int(sqlite3CtypeMap[u8(z[i])]) & 4) == 0 {
							if int(z[i]) == `_` {
								unsafe { *token_type = 183 }
							} else {
								break
							}
						}
						i++
					}
				}
			}
			for ((int(sqlite3CtypeMap[u8(z[i])]) & 70) != 0) {
				unsafe { *token_type = 186 }
				i++
			}
			return i
		}
		9 {
			i = I64(1)
			for c = int(z[0]); c != `]` && c2v_assign[int](unsafe { &c }, int(z[i])) != 0; i++ {
			}
			unsafe { *token_type = if c == `]` { 60 } else { 186 } }
			return i
		}
		6 {
			unsafe { *token_type = 157 }
			for i = I64(1); (int(sqlite3CtypeMap[u8(z[i])]) & 4); i++ {
			}
			return i
		}
		4, 5 {
			n := I64(0)
			0
			0
			0
			0
			unsafe { *token_type = 157 }
			for i = I64(1); true; i++ {
				c = int(z[i])
				if !(c != 0) {
					break
				}
				if ((int(sqlite3CtypeMap[u8(c)]) & 70) != 0) {
					n++
				} else if c == `(` && n > I64(0) {
					for {
						i++
						c = int(z[i])
						if !(c != 0 && !(int(sqlite3CtypeMap[u8(c)]) & 1) && c != `)`) {
							break
						}
					}
					if c == `)` {
						i++
					} else {
						unsafe { *token_type = 186 }
					}
					break
				} else if c == `:` && int(z[i + I64(1)]) == `:` {
					i++
				} else {
					break
				}
			}
			if n == I64(0) {
				unsafe { *token_type = 186 }
			}
			return i
		}
		1 {
			if int(ai_class[z[1]]) > 2 {
				i = I64(1)
				unsafe { goto c2v_switch_end_70
				 }
			}
			for i = I64(2); int(ai_class[z[i]]) <= 2; i++ {
			}
			if ((int(sqlite3CtypeMap[u8(z[i])]) & 70) != 0) {
				i++
				unsafe { goto c2v_switch_end_70
				 }
			}
			unsafe { *token_type = 60 }
			return keyword_code(&i8(voidptr(z)), i, token_type)
		}
		0 {
			0
			0
			if int(z[1]) == `\'` {
				unsafe { *token_type = 155 }
				for i = I64(2); (int(sqlite3CtypeMap[u8(z[i])]) & 8); i++ {
				}
				if int(z[i]) != `\'` || i % I64(2) {
					unsafe { *token_type = 186 }
					for int(z[i]) && int(z[i]) != `\'` {
						i++
					}
				}
				if z[i] {
					i++
				}
				return i
			}

			unsafe { goto c2v_case_70_25
			 }
		}
		2, 27 {
			c2v_case_70_25:
			i = I64(1)
		}
		30 {
			if int(z[1]) == 187 && int(z[2]) == 191 {
				unsafe { *token_type = 184 }
				return I64(3)
			}
			i = I64(1)
		}
		29 {
			unsafe { *token_type = 186 }
			return I64(0)
		}
		else {
			unsafe { *token_type = 186 }
			return I64(1)
		}
	}
	c2v_switch_end_70: for ((int(sqlite3CtypeMap[u8(z[i])]) & 70) != 0) {
		i++
	}
	unsafe { *token_type = 60 }
	return i
}

@[c:'sqlite3RunParser']
fn sqlite3_run_parser(p_parse &Parse, z_sql &i8) int {
	n_err := 0
	p_engine := &voidptr(0)
	n := I64(0)
	token_type := 0
	last_token_parsed := -1
	db := p_parse.db
	mx_sql_len := I64(0)
	p_parent_parse := unsafe { &Parse(nil) }
	s_engine := YyParser{}
	0
	mx_sql_len = I64(db.aLimit[1])
	if db.nVdbeActive == 0 {
		C.c2v_atomic_store_n__int_int_int_((&db.u1.isInterrupted), 0, 0)
	}
	p_parse.rc = 0
	p_parse.zTail = z_sql
	p_engine = &s_engine
	sqlite3_parser_init(voidptr(p_engine), p_parse)
	p_parent_parse = db.pParse
	db.pParse = p_parse
	for {
		n = sqlite3_get_token(&U8(voidptr(z_sql)), &token_type)
		mx_sql_len -= n
		if mx_sql_len < I64(0) {
			p_parse.rc = 18
			p_parse.nErr++
			break
		}
		if token_type >= 165 {
			if C.c2v_atomic_load_n__int_int_int((&db.u1.isInterrupted), 0) {
				p_parse.rc = 9
				p_parse.nErr++
				break
			}
			if token_type == 184 {
				c2v_pointer_prefix(voidptr(&z_sql), z_sql, isize(n))
				continue
			}
			if int(z_sql[0]) == 0 {
				if last_token_parsed == 1 {
					token_type = 0
				} else if last_token_parsed == 0 {
					break
				} else {
					token_type = 1
				}
				n = I64(0)
			} else if token_type == 165 {
				token_type = analyze_window_keyword(&U8(voidptr(unsafe { z_sql + 6 })))
			} else if token_type == 166 {
				token_type = analyze_over_keyword(&U8(voidptr(unsafe { z_sql + 4 })), last_token_parsed)
			} else if token_type == 167 {
				token_type = analyze_filter_keyword(&U8(voidptr(unsafe { z_sql + 6 })), last_token_parsed)
			} else if token_type == 185 && (int(db.init.busy) || (db.flags & (U64(64) << 32)) != U64(0)) {
				c2v_pointer_prefix(voidptr(&z_sql), z_sql, isize(n))
				continue
			} else if token_type != 183 {
				x := Token{}
				x.z = z_sql
				x.n = u32(n)
				sqlite3_error_msg(p_parse, c'unrecognized token: "%T"', voidptr(&x))
				break
			}
		}
		p_parse.sLastToken.z = z_sql
		p_parse.sLastToken.n = u32(n)
		sqlite3_parser(voidptr(p_engine), token_type, p_parse.sLastToken)
		last_token_parsed = token_type
		c2v_pointer_prefix(voidptr(&z_sql), z_sql, isize(n))
		if p_parse.rc != 0 {
			break
		}
	}
	sqlite3_parser_finalize(voidptr(p_engine))
	if db.mallocFailed {
		p_parse.rc = 7
	}
	if !isnil(p_parse.zErrMsg) || (p_parse.rc != 0 && p_parse.rc != 101) {
		if usize(p_parse.zErrMsg) == usize(0) {
			p_parse.zErrMsg = sqlite3_db_str_dup(db, sqlite3_err_str(p_parse.rc))
		}
		if (int(p_parse.prepFlags) & 16) == 0 {
			sqlite3_log(p_parse.rc, c'%s in "%s"', voidptr(p_parse.zErrMsg), voidptr(p_parse.zTail))
		}
		n_err++
	}
	p_parse.zTail = z_sql
	sqlite3_free(voidptr(p_parse.apVtabLock))
	if !isnil(p_parse.pNewTable) && !(int(p_parse.eParseMode) != 0) {
		sqlite3_delete_table(db, p_parse.pNewTable)
	}
	if !isnil(p_parse.pNewTrigger) && !(int(p_parse.eParseMode) >= 2) {
		sqlite3_delete_trigger(db, p_parse.pNewTrigger)
	}
	if p_parse.pVList {
		sqlite3_db_nn_free_nn(db, voidptr(p_parse.pVList))
	}
	db.pParse = p_parent_parse
	return n_err
}
