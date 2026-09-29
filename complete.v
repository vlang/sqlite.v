@[translated]
module main

fn sqlite3_complete(z_sql &i8) int {
	c2v_gc_register_thread()
	state := U8(0)
	token := U8(0)
	if !sqlite3_complete_trans_inited {
		c2v_static_init := [[U8(1), U8(0), U8(2), U8(3), U8(4), U8(2), U8(2), U8(2)],
			[U8(1), U8(1), U8(2), U8(3), U8(4), U8(2), U8(2), U8(2)],
			[U8(1), U8(2), U8(2), U8(2), U8(2), U8(2), U8(2), U8(2)],
			[U8(1), U8(3), U8(3), U8(2), U8(4), U8(2), U8(2), U8(2)],
			[U8(1), U8(4), U8(2), U8(2), U8(2), U8(4), U8(5), U8(2)],
			[U8(6), U8(5), U8(5), U8(5), U8(5), U8(5), U8(5), U8(5)],
			[U8(6), U8(6), U8(5), U8(5), U8(5), U8(5), U8(5), U8(7)],
			[U8(1), U8(7), U8(5), U8(5), U8(5), U8(5), U8(5), U8(5)]]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			for c2v_i_1, c2v_element_1 in c2v_element_0 {
				sqlite3_complete_trans[c2v_i_0][c2v_i_1] = c2v_element_1
			}
		}
		sqlite3_complete_trans_inited = true
	}

	for (unsafe { *z_sql }) {
		match int((unsafe { *z_sql })) {
			int(`;`) {
				token = U8(0)
			}
			int(` `), int(`\r`), int(`\t`), int(`\n`), int(`\f`) {
				token = U8(1)
			}
			int(`/`) {
				if int(z_sql[1]) != i8(`*`) {
					token = U8(2)
					unsafe { goto c2v_switch_end_71
					 }
				}
				c2v_pointer_prefix(voidptr(&z_sql), z_sql, isize(2))
				for int(z_sql[0]) && (int(z_sql[0]) != i8(`*`) || int(z_sql[1]) != i8(`/`)) {
					c2v_pointer_postfix(voidptr(&z_sql), z_sql, isize(1))
				}
				if int(z_sql[0]) == 0 {
					return 0
				}
				c2v_pointer_postfix(voidptr(&z_sql), z_sql, isize(1))
				token = U8(1)
			}
			int(`-`) {
				if int(z_sql[1]) != i8(`-`) {
					token = U8(2)
					unsafe { goto c2v_switch_end_71
					 }
				}
				for int((unsafe { *z_sql })) && int((unsafe { *z_sql })) != i8(`\n`) {
					c2v_pointer_postfix(voidptr(&z_sql), z_sql, isize(1))
				}
				if int((unsafe { *z_sql })) == 0 {
					return int(state == 1)
				}
				token = U8(1)
			}
			int(`[`) {
				c2v_pointer_postfix(voidptr(&z_sql), z_sql, isize(1))
				for int((unsafe { *z_sql })) && int((unsafe { *z_sql })) != i8(`]`) {
					c2v_pointer_postfix(voidptr(&z_sql), z_sql, isize(1))
				}
				if int((unsafe { *z_sql })) == 0 {
					return 0
				}
				token = U8(2)
			}
			int(`\``), int(`\"`), int(`\'`) {
				c := int((unsafe { *z_sql }))
				c2v_pointer_postfix(voidptr(&z_sql), z_sql, isize(1))
				for int((unsafe { *z_sql })) && int((unsafe { *z_sql })) != c {
					c2v_pointer_postfix(voidptr(&z_sql), z_sql, isize(1))
				}
				if int((unsafe { *z_sql })) == 0 {
					return 0
				}
				token = U8(2)
			}
			else {
				if ((int(sqlite3CtypeMap[u8(U8((unsafe { *z_sql })))]) & 70) != 0) {
					n_id := 0
					for n_id = 1; ((int(sqlite3CtypeMap[u8(z_sql[n_id])]) & 70) != 0); n_id++ {
					}
					match int((unsafe { *z_sql })) {
						int(`c`), int(`C`) {
							if n_id == 6 && sqlite3_strnicmp(z_sql, c'create', 6) == 0 {
								token = U8(4)
							} else {
								token = U8(2)
							}
						}
						int(`t`), int(`T`) {
							if n_id == 7 && sqlite3_strnicmp(z_sql, c'trigger', 7) == 0 {
								token = U8(6)
							} else if n_id == 4 && sqlite3_strnicmp(z_sql, c'temp', 4) == 0 {
								token = U8(5)
							} else if n_id == 9 && sqlite3_strnicmp(z_sql, c'temporary', 9) == 0 {
								token = U8(5)
							} else {
								token = U8(2)
							}
						}
						int(`e`), int(`E`) {
							if n_id == 3 && sqlite3_strnicmp(z_sql, c'end', 3) == 0 {
								token = U8(7)
							} else if n_id == 7 && sqlite3_strnicmp(z_sql, c'explain', 7) == 0 {
								token = U8(3)
							} else {
								token = U8(2)
							}
						}
						else {
							token = U8(2)
						}
					}

					c2v_pointer_prefix(voidptr(&z_sql), z_sql, isize(n_id - 1))
				} else {
					token = U8(2)
				}
			}
		}
		c2v_switch_end_71:

		state = sqlite3_complete_trans[state][token]
		c2v_pointer_postfix(voidptr(&z_sql), z_sql, isize(1))
	}
	return int(state == 1)
}

fn sqlite3_complete16(z_sql voidptr) int {
	c2v_gc_register_thread()
	p_val := &Sqlite3_value(0)
	z_sql8 := &i8(0)
	rc := 0
	rc = sqlite3_initialize()
	if rc {
		return rc
	}
	p_val = sqlite3_value_new(unsafe { nil })
	sqlite3_value_set_str(p_val, -1, voidptr(z_sql), U8(2), (C2vFn_666e2028766f696470747229(voidptr(0))))
	z_sql8 = &i8(sqlite3_value_text_vdup5(p_val, U8(1)))
	if z_sql8 {
		rc = sqlite3_complete(z_sql8)
	} else {
		rc = 7
	}
	sqlite3_value_free_vdup7(p_val)
	return rc & 255
}
