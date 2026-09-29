@[translated]
module main

@[c:'openStatTable']
fn open_stat_table(p_parse &Parse, i_db int, i_stat_cur int, z_where &i8, z_where_type &i8) {
	if !open_stat_table_a_table_inited {
		c2v_static_init := [AnonStruct_123894{
			zName: c'sqlite_stat1'
			zCols: c'tbl,idx,stat'
		}, AnonStruct_123894{
			zName: c'sqlite_stat4'
			zCols: 0
		}, AnonStruct_123894{
			zName: c'sqlite_stat3'
			zCols: 0
		}]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			open_stat_table_a_table[c2v_i_0] = c2v_element_0
		}
		open_stat_table_a_table_inited = true
	}

	i := 0
	db := p_parse.db
	p_db := &Db(0)
	v := sqlite3_get_vdbe(p_parse)
	a_root := [3]u32{}
	a_create_tbl := [3]U8{}
	n_to_open := 1
	if usize(v) == usize(0) {
		return
	}
	p_db = unsafe { db.aDb + i_db }
	for i = 0; i < 3; i++ {
		z_tab := open_stat_table_a_table[i].zName
		p_stat := &Table(0)
		a_create_tbl[i] = U8(0)
		p_stat = sqlite3_find_table(db, z_tab, p_db.zDbSName)
		if usize(p_stat) == usize(0) {
			if i < n_to_open {
				sqlite3_nested_parse(p_parse, c'CREATE TABLE %Q.%s(%s)', voidptr(p_db.zDbSName), voidptr(z_tab), voidptr(open_stat_table_a_table[i].zCols))
				a_root[i] = u32(p_parse.u1.cr.regRoot)
				a_create_tbl[i] = U8(16)
			}
		} else {
			a_root[i] = p_stat.tnum
			sqlite3_table_lock(p_parse, i_db, a_root[i], U8(1), z_tab)
			if z_where {
				sqlite3_nested_parse(p_parse, c'DELETE FROM %Q.%s WHERE %s=%Q', voidptr(p_db.zDbSName), voidptr(z_tab), voidptr(z_where_type), voidptr(z_where))
			} else {
				sqlite3_vdbe_add_op2(v, 147, int(a_root[i]), i_db)
			}
		}
	}
	for i = 0; i < n_to_open; i++ {
		sqlite3_vdbe_add_op4_int(v, 116, i_stat_cur + i, int(a_root[i]), i_db, 3)
		sqlite3_vdbe_change_p5(v, U16(a_create_tbl[i]))
		0
	}
}

struct StatSample {
	anDLt &TRowcnt
}

struct StatAccum {
	db         &Sqlite3
	nEst       TRowcnt
	nRow       TRowcnt
	nLimit     int
	nCol       int
	nKeyCol    int
	nSkipAhead U8
	current    StatSample
}

@[c:'statAccumDestructor']
fn stat_accum_destructor(p_old voidptr) {
	c2v_gc_register_thread()
	p := &StatAccum(p_old)
	sqlite3_db_free(p.db, voidptr(p))
}

@[c:'statInit']
fn stat_init(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &StatAccum(0)
	n_col := 0
	n_key_col := 0
	n_col_up := 0
	n := I64(0)
	db := sqlite3_context_db_handle(context)

	n_col = sqlite3_value_int(argv[0])
	n_col_up = if sizeof(TRowcnt) < u64(8) { (n_col + 1) & ~1 } else { n_col }
	n_key_col = sqlite3_value_int(argv[1])
	n = I64(sizeof(StatAccum) + sizeof(TRowcnt) * u64(n_col_up))
	p = sqlite3_db_malloc_zero(db, U64(n))
	if usize(p) == usize(0) {
		sqlite3_result_error_nomem(context)
		return
	}
	p.db = db
	p.nEst = TRowcnt(sqlite3_value_int64(argv[2]))
	p.nRow = TRowcnt(0)
	p.nLimit = sqlite3_value_int(argv[3])
	p.nCol = n_col
	p.nKeyCol = n_key_col
	p.nSkipAhead = U8(0)
	p.current.anDLt = &TRowcnt(voidptr(unsafe { p + 1 }))
	sqlite3_result_blob(context, voidptr(p), int(sizeof(StatAccum)), stat_accum_destructor)
}

@[c:'statPush']
fn stat_push(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	i := 0
	p := &StatAccum(sqlite3_value_blob(argv[0]))
	i_chng := sqlite3_value_int(argv[1])

	if p.nRow == TRowcnt(0) {
	} else {
		for i = i_chng; i < p.nCol; i++ {
			p.current.anDLt[i]++
		}
	}
	p.nRow++
	if p.nLimit && p.nRow > TRowcnt(p.nLimit) * TRowcnt((int(p.nSkipAhead) + 1)) {
		p.nSkipAhead++
		sqlite3_result_int(context, p.current.anDLt[0] > TRowcnt(0))
	}
}

@[c:'statGet']
fn stat_get(context &Sqlite3_context, argc int, argv &&Sqlite3_value) {
	c2v_gc_register_thread()
	p := &StatAccum(sqlite3_value_blob(argv[0]))
	s_stat := Sqlite3_str{}
	i := 0
	sqlite3_str_accum_init(unsafe { &StrAccum(&s_stat) }, unsafe { nil }, unsafe { nil }, 0, (p.nKeyCol + 1) * 100)
	sqlite3_str_appendf(&s_stat, c'%llu', if int(p.nSkipAhead) { U64(p.nEst) } else { U64(p.nRow) })
	for i = 0; i < p.nKeyCol; i++ {
		n_distinct := p.current.anDLt[i] + TRowcnt(1)
		i_val := (p.nRow + n_distinct - U64(1)) / n_distinct
		if i_val == U64(2) && p.nRow * TRowcnt(10) <= n_distinct * U64(11) {
			i_val = U64(1)
		}
		sqlite3_str_appendf(&s_stat, c' %llu', i_val)
	}
	sqlite3_result_str_accum(context, unsafe { &StrAccum(&s_stat) })
}

@[c:'callStatGet']
fn call_stat_get(p_parse &Parse, reg_stat int, i_param int, reg_out int) {
	sqlite3_vdbe_add_function_call(p_parse, 0, reg_stat, reg_out, 1 + 0, &statGetFuncdef, 0)
}

@[c:'analyzeOneTable']
fn analyze_one_table(p_parse &Parse, p_tab &Table, p_only_idx &Index, i_stat_cur int, i_mem int, i_tab int) {
	db := p_parse.db
	p_idx := &Index(0)
	i_idx_cur := 0
	i_tab_cur := 0
	v := &Vdbe(0)
	i := 0
	j_zero_rows := -1
	i_db := 0
	need_table_cnt := U8(1)
	reg_new_rowid := i_mem++
	reg_stat := i_mem++
	reg_chng := i_mem++
	reg_rowid := i_mem++
	reg_temp := i_mem++
	reg_temp2 := i_mem++
	reg_tabname := i_mem++
	reg_idxname := i_mem++
	reg_stat1 := i_mem++
	reg_prev := i_mem
	sqlite3_touch_register(p_parse, i_mem)
	v = sqlite3_get_vdbe(p_parse)
	if usize(v) == usize(0) || (usize(p_tab) == usize(0)) {
		return
	}
	if !(int(p_tab.eTabType) == 0) {
		return
	}
	if sqlite3_strlike(c'sqlite\\_%', p_tab.zName, u32(`\\`)) == 0 {
		return
	}
	i_db = sqlite3_schema_to_index(db, p_tab.pSchema)
	if sqlite3_auth_check(p_parse, 28, p_tab.zName, unsafe { nil }, db.aDb[i_db].zDbSName) {
		return
	}
	sqlite3_table_lock(p_parse, i_db, p_tab.tnum, U8(0), p_tab.zName)
	mut __c2v_postfix_value_9 := i_tab
	i_tab++
	i_tab_cur = __c2v_postfix_value_9
	mut __c2v_postfix_value_10 := i_tab
	i_tab++
	i_idx_cur = __c2v_postfix_value_10
	p_parse.nTab = (if p_parse.nTab > i_tab { p_parse.nTab } else { i_tab })
	sqlite3_open_table(p_parse, i_tab_cur, i_db, p_tab, 114)
	sqlite3_vdbe_load_string(v, reg_tabname, p_tab.zName)
	for p_idx = p_tab.pIndex; p_idx; p_idx = p_idx.pNext {
		n_col := 0
		addr_goto_end := 0
		addr_next_row := 0
		z_idx_name := &i8(0)
		n_col_test := 0
		if !isnil(p_only_idx) && usize(p_only_idx) != usize(p_idx) {
			continue
		}
		if usize(p_idx.pPartIdxWhere) == usize(0) {
			need_table_cnt = U8(0)
		}
		if !((p_tab.tabFlags & u32(128)) == u32(0)) && (int(p_idx.idxType) == 2) {
			n_col = int(p_idx.nKeyCol)
			z_idx_name = p_tab.zName
			n_col_test = n_col - 1
		} else {
			n_col = int(p_idx.nColumn)
			z_idx_name = p_idx.zName
			n_col_test = if int(p_idx.uniqNotNull) { int(p_idx.nKeyCol) - 1 } else { n_col - 1 }
		}
		sqlite3_vdbe_load_string(v, reg_idxname, z_idx_name)
		0
		sqlite3_touch_register(p_parse, reg_prev + n_col_test)
		sqlite3_vdbe_add_op3(v, 114, i_idx_cur, int(p_idx.tnum), i_db)
		sqlite3_vdbe_set_p4_key_info(p_parse, p_idx)
		0
		sqlite3_vdbe_add_op2(v, 73, db.nAnalysisLimit, reg_temp2)
		sqlite3_vdbe_add_op2(v, 73, n_col, reg_stat + 1)
		sqlite3_vdbe_add_op2(v, 73, int(p_idx.nKeyCol), reg_rowid)
		sqlite3_vdbe_add_op3(v, 100, i_idx_cur, reg_temp, ((db.dbOptFlags & u32(2048)) != u32(0)))
		sqlite3_vdbe_add_function_call(p_parse, 0, reg_stat + 1, reg_stat, 4, &statInitFuncdef, 0)
		addr_goto_end = sqlite3_vdbe_add_op1(v, 36, i_idx_cur)
		0
		sqlite3_vdbe_add_op2(v, 73, 0, reg_chng)
		addr_next_row = sqlite3_vdbe_current_addr(v)
		if n_col_test > 0 {
			end_distinct_test := sqlite3_vdbe_make_label(p_parse)
			a_goto_chng := &int(0)
			a_goto_chng = sqlite3_db_malloc_raw_nn(db, U64(sizeof(int) * u64(n_col_test)))
			if usize(a_goto_chng) == usize(0) {
				continue
			}
			sqlite3_vdbe_add_op0(v, 9)
			addr_next_row = sqlite3_vdbe_current_addr(v)
			if n_col_test == 1 && int(p_idx.nKeyCol) == 1 && (int(p_idx.onError) != 0) {
				sqlite3_vdbe_add_op2(v, 52, reg_prev, end_distinct_test)
				0
			}
			for i = 0; i < n_col_test; i++ {
				p_coll := &i8(voidptr(sqlite3_locate_coll_seq(p_parse, p_idx.azColl[i])))
				sqlite3_vdbe_add_op2(v, 73, i, reg_chng)
				sqlite3_vdbe_add_op3(v, 96, i_idx_cur, i, reg_temp)
				0
				a_goto_chng[i] = sqlite3_vdbe_add_op4(v, 53, reg_temp, 0, reg_prev + i, p_coll, (-2))
				sqlite3_vdbe_change_p5(v, U16(128))
				0
			}
			sqlite3_vdbe_add_op2(v, 73, n_col_test, reg_chng)
			sqlite3_vdbe_goto(v, end_distinct_test)
			sqlite3_vdbe_jump_here(v, addr_next_row - 1)
			for i = 0; i < n_col_test; i++ {
				sqlite3_vdbe_jump_here(v, a_goto_chng[i])
				sqlite3_vdbe_add_op3(v, 96, i_idx_cur, i, reg_prev + i)
				0
			}
			sqlite3_vdbe_resolve_label(v, end_distinct_test)
			sqlite3_db_free(db, voidptr(a_goto_chng))
		}
		sqlite3_vdbe_add_function_call(p_parse, 1, reg_stat, reg_temp, 2 + 0, &statPushFuncdef, 0)
		if db.nAnalysisLimit {
			j1 := 0
			j2 := 0
			j3 := 0

			j1 = sqlite3_vdbe_add_op1(v, 51, reg_temp)
			0
			j2 = sqlite3_vdbe_add_op1(v, 16, reg_temp)
			0
			j3 = sqlite3_vdbe_add_op4_int(v, 24, i_idx_cur, 0, reg_prev, 1)
			0
			sqlite3_vdbe_jump_here(v, j1)
			sqlite3_vdbe_add_op2(v, 40, i_idx_cur, addr_next_row)
			0
			sqlite3_vdbe_jump_here(v, j2)
			sqlite3_vdbe_jump_here(v, j3)
		} else {
			sqlite3_vdbe_add_op2(v, 40, i_idx_cur, addr_next_row)
			0
		}
		if p_idx.pPartIdxWhere {
			sqlite3_vdbe_jump_here(v, addr_goto_end)
			addr_goto_end = 0
		}
		call_stat_get(p_parse, reg_stat, 0, reg_stat1)
		sqlite3_vdbe_add_op4(v, 99, reg_tabname, 3, reg_temp, c'BBB', 0)
		sqlite3_vdbe_add_op2(v, 129, i_stat_cur, reg_new_rowid)
		sqlite3_vdbe_add_op3(v, 130, i_stat_cur, reg_temp, reg_new_rowid)
		sqlite3_vdbe_change_p5(v, U16(8))
		if addr_goto_end {
			sqlite3_vdbe_jump_here(v, addr_goto_end)
		}
	}
	if usize(p_only_idx) == usize(0) && int(need_table_cnt) {
		0
		sqlite3_vdbe_add_op2(v, 100, i_tab_cur, reg_stat1)
		j_zero_rows = sqlite3_vdbe_add_op1(v, 17, reg_stat1)
		0
		sqlite3_vdbe_add_op2(v, 77, 0, reg_idxname)
		sqlite3_vdbe_add_op4(v, 99, reg_tabname, 3, reg_temp, c'BBB', 0)
		sqlite3_vdbe_add_op2(v, 129, i_stat_cur, reg_new_rowid)
		sqlite3_vdbe_add_op3(v, 130, i_stat_cur, reg_temp, reg_new_rowid)
		sqlite3_vdbe_change_p5(v, U16(8))
		sqlite3_vdbe_jump_here(v, j_zero_rows)
	}
}

@[c:'loadAnalysis']
fn load_analysis(p_parse &Parse, i_db int) {
	v := sqlite3_get_vdbe(p_parse)
	if v {
		sqlite3_vdbe_add_op1(v, 152, i_db)
	}
}

@[c:'analyzeDatabase']
fn analyze_database(p_parse &Parse, i_db int) {
	db := p_parse.db
	p_schema := db.aDb[i_db].pSchema
	k := &HashElem(0)
	i_stat_cur := 0
	i_mem := 0
	i_tab := 0
	sqlite3_begin_write_operation(p_parse, 0, i_db)
	i_stat_cur = p_parse.nTab
	p_parse.nTab += 3
	open_stat_table(p_parse, i_db, i_stat_cur, unsafe { nil }, unsafe { nil })
	i_mem = p_parse.nMem + 1
	i_tab = p_parse.nTab
	for k = p_schema.tblHash.first; k; k = k.next {
		p_tab := &Table(k.data)
		analyze_one_table(p_parse, p_tab, unsafe { nil }, i_stat_cur, i_mem, i_tab)
	}
	load_analysis(p_parse, i_db)
}

@[c:'analyzeTable']
fn analyze_table(p_parse &Parse, p_tab &Table, p_only_idx &Index) {
	i_db := 0
	i_stat_cur := 0
	i_db = sqlite3_schema_to_index(p_parse.db, p_tab.pSchema)
	sqlite3_begin_write_operation(p_parse, 0, i_db)
	i_stat_cur = p_parse.nTab
	p_parse.nTab += 3
	if p_only_idx {
		open_stat_table(p_parse, i_db, i_stat_cur, p_only_idx.zName, c'idx')
	} else {
		open_stat_table(p_parse, i_db, i_stat_cur, p_tab.zName, c'tbl')
	}
	analyze_one_table(p_parse, p_tab, p_only_idx, i_stat_cur, p_parse.nMem + 1, p_parse.nTab)
	load_analysis(p_parse, i_db)
}

@[c:'sqlite3Analyze']
fn sqlite3_analyze(p_parse &Parse, p_name1 &Token, p_name2 &Token) {
	db := p_parse.db
	i_db := 0
	i := 0
	z := &i8(0)
	z_db := &i8(0)

	p_tab := &Table(0)
	p_idx := &Index(0)
	p_table_name := &Token(0)
	v := &Vdbe(0)
	if 0 != sqlite3_read_schema(p_parse) {
		return
	}
	if usize(p_name1) == usize(0) {
		for i = 0; i < db.nDb; i++ {
			if i == 1 {
				continue
			}
			analyze_database(p_parse, i)
		}
	} else {
		if p_name2.n == u32(0) && c2v_assign[int](unsafe { &i_db }, int(sqlite3_find_db(db, p_name1))) >= 0 {
			analyze_database(p_parse, i_db)
		} else {
			i_db = sqlite3_two_part_name(p_parse, p_name1, p_name2, &&Token(&&Token(c2v_address_of(&p_table_name))))
			if i_db >= 0 {
				z_db = unsafe { if p_name2.n { db.aDb[i_db].zDbSName } else { &i8(nil) } }
				z = sqlite3_name_from_token(db, p_table_name)
				if z {
					p_idx = sqlite3_find_index(db, z, z_db)
					if usize(p_idx) != usize(0) {
						analyze_table(p_parse, p_idx.pTable, p_idx)
					} else {
						p_tab = sqlite3_locate_table(p_parse, u32(0), z, z_db)
						if usize(p_tab) != usize(0) {
							analyze_table(p_parse, p_tab, unsafe { nil })
						}
					}
					sqlite3_db_free(db, voidptr(z))
				}
			}
		}
	}
	if int(db.nSqlExec) == 0 && usize(c2v_assign[&Vdbe](unsafe { &v }, sqlite3_get_vdbe(p_parse))) != usize(0) {
		sqlite3_vdbe_add_op0(v, 168)
	}
}

struct AnalysisInfo {
	db        &Sqlite3
	zDatabase &i8
}

@[c:'decodeIntArray']
fn decode_int_array(z_int_array &i8, n_out int, a_out &TRowcnt, a_log &LogEst, p_index &Index) {
	z := z_int_array
	c := 0
	i := 0
	v := TRowcnt(0)
	for i = 0; int((unsafe { *z })) && i < n_out; i++ {
		v = TRowcnt(0)
		for {
			c = int(z[0])
			if !(c >= `0` && c <= `9`) {
				break
			}
			v = v * TRowcnt(10) + TRowcnt(c) - TRowcnt(`0`)
			c2v_pointer_postfix(voidptr(&z), z, isize(1))
		}

		a_log[i] = sqlite3_log_est(v)
		if int((unsafe { *z })) == i8(` `) {
			c2v_pointer_postfix(voidptr(&z), z, isize(1))
		}
	}
	p_index.bUnordered = u32(0)
	p_index.noSkipScan = u32(0)
	for z[0] {
		if sqlite3_strglob(c'unordered*', z) == 0 {
			p_index.bUnordered = u32(1)
		} else if sqlite3_strglob(c'sz=[0-9]*', z) == 0 {
			sz := sqlite3_atoi(z + 3)
			if sz < 2 {
				sz = 2
			}
			p_index.szIdxRow = sqlite3_log_est(U64(sz))
		} else if sqlite3_strglob(c'noskipscan*', z) == 0 {
			p_index.noSkipScan = u32(1)
		}
		for int(z[0]) != 0 && int(z[0]) != i8(` `) {
			c2v_pointer_postfix(voidptr(&z), z, isize(1))
		}
		for int(z[0]) == i8(` `) {
			c2v_pointer_postfix(voidptr(&z), z, isize(1))
		}
	}
}

@[c:'analysisLoader']
fn analysis_loader(p_data voidptr, argc int, argv &&u8, not_used &&u8) int {
	c2v_gc_register_thread()
	p_info := &AnalysisInfo(p_data)
	p_index := &Index(0)
	p_table := &Table(0)
	z := &i8(0)

	if usize(argv) == usize(0) || usize(argv[0]) == usize(0) || usize(argv[2]) == usize(0) {
		return 0
	}
	p_table = sqlite3_find_table(p_info.db, argv[0], p_info.zDatabase)
	if usize(p_table) == usize(0) {
		return 0
	}
	if usize(argv[1]) == usize(0) {
		p_index = 0
	} else if sqlite3_stricmp(argv[0], argv[1]) == 0 {
		p_index = sqlite3_primary_key_index(p_table)
	} else {
		p_index = sqlite3_find_index(p_info.db, argv[1], p_info.zDatabase)
	}
	z = argv[2]
	if p_index {
		ai_row_est := unsafe { &TRowcnt(nil) }
		n_col := int(p_index.nKeyCol) + 1
		p_index.bUnordered = u32(0)
		decode_int_array(&i8(z), n_col, ai_row_est, p_index.aiRowLogEst, p_index)
		p_index.hasStat1 = u32(1)
		if usize(p_index.pPartIdxWhere) == usize(0) {
			p_table.nRowLogEst = p_index.aiRowLogEst[0]
			p_table.tabFlags |= u32(16)
		}
	} else {
		fake_idx := Index{}
		fake_idx.szIdxRow = p_table.szTabRow
		decode_int_array(&i8(z), 1, unsafe { nil }, &p_table.nRowLogEst, &fake_idx)
		p_table.szTabRow = fake_idx.szIdxRow
		p_table.tabFlags |= u32(16)
	}
	return 0
}

@[c:'sqlite3DeleteIndexSamples']
fn sqlite3_delete_index_samples(db &Sqlite3, p_idx &Index) {
}

@[c:'sqlite3AnalysisLoad']
fn sqlite3_analysis_load(db &Sqlite3, i_db int) int {
	s_info := AnalysisInfo{}
	i := &HashElem(0)
	z_sql := &i8(0)
	rc := 0
	p_schema := db.aDb[i_db].pSchema
	p_stat1 := &Table(0)
	for i = p_schema.tblHash.first; i; i = i.next {
		p_tab := &Table(i.data)
		p_tab.tabFlags &= u32(~16)
	}
	for i = p_schema.idxHash.first; i; i = i.next {
		p_idx := &Index(i.data)
		p_idx.hasStat1 = u32(0)
	}
	s_info.db = db
	s_info.zDatabase = db.aDb[i_db].zDbSName
	p_stat1 = sqlite3_find_table(db, c'sqlite_stat1', s_info.zDatabase)
	if !isnil(p_stat1) && (int(p_stat1.eTabType) == 0) {
		z_sql = sqlite3_mp_rintf(db, c'SELECT tbl,idx,stat FROM %Q.sqlite_stat1', voidptr(s_info.zDatabase))
		if usize(z_sql) == usize(0) {
			rc = 7
		} else {
			rc = sqlite3_exec(db, z_sql, analysis_loader, voidptr(&s_info), unsafe { &&u8(nil) })
			sqlite3_db_free(db, voidptr(z_sql))
		}
	}
	for i = p_schema.idxHash.first; i; i = i.next {
		p_idx := &Index(i.data)
		if !p_idx.hasStat1 {
			sqlite3_default_row_est(p_idx)
		}
	}
	if rc == 7 {
		sqlite3_oom_fault(db)
	}
	return rc
}
