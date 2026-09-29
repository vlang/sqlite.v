@[translated]
module main

@[c:'callCollNeeded']
fn call_coll_needed(db &Sqlite3, enc int, z_name &i8) {
	if db.xCollNeeded {
		z_external := sqlite3_db_str_dup(db, z_name)
		if isnil(z_external) {
			return
		}
		db.xCollNeeded(voidptr(db.pCollNeededArg), db, enc, z_external)
		sqlite3_db_free(db, voidptr(z_external))
	}
	if db.xCollNeeded16 {
		z_external := &i8(0)
		p_tmp := sqlite3_value_new(db)
		sqlite3_value_set_str(p_tmp, -1, voidptr(z_name), U8(1), (C2vFn_666e2028766f696470747229(voidptr(0))))
		z_external = &i8(sqlite3_value_text_vdup5(p_tmp, U8(2)))
		if z_external {
			db.xCollNeeded16(voidptr(db.pCollNeededArg), db, int(db.enc), voidptr(z_external))
		}
		sqlite3_value_free_vdup7(p_tmp)
	}
}

@[c:'synthCollSeq']
fn synth_coll_seq(db &Sqlite3, p_coll &CollSeq) int {
	p_coll2 := &CollSeq(0)
	z := p_coll.zName
	i := 0
	if !synth_coll_seq_a_enc_inited {
		c2v_static_init := [U8(3), U8(2), U8(1)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			synth_coll_seq_a_enc[c2v_i_0] = c2v_element_0
		}
		synth_coll_seq_a_enc_inited = true
	}

	for i = 0; i < 3; i++ {
		p_coll2 = sqlite3_find_coll_seq(db, synth_coll_seq_a_enc[i], z, 0)
		if !isnil(p_coll2.xCmp) {
			C.memcpy(voidptr(p_coll), voidptr(p_coll2), sizeof(CollSeq))
			p_coll.xDel = 0
			return 0
		}
	}
	return 1
}

@[c:'sqlite3CheckCollSeq']
fn sqlite3_check_coll_seq(p_parse &Parse, p_coll &CollSeq) int {
	if !isnil(p_coll) && isnil(p_coll.xCmp) {
		z_name := p_coll.zName
		db := p_parse.db
		p := sqlite3_get_coll_seq(p_parse, db.enc, p_coll, z_name)
		if isnil(p) {
			return 1
		}
	}
	return 0
}

@[c:'findCollSeqEntry']
fn find_coll_seq_entry(db &Sqlite3, z_name &i8, create int) &CollSeq {
	mut p_coll := &CollSeq(0)
	p_coll = sqlite3_hash_find(&db.aCollSeq, z_name)
	if usize(0) == usize(p_coll) && create {
		n_name := sqlite3_strlen30(z_name) + 1
		p_coll = sqlite3_db_malloc_zero(db, U64(u64(3) * sizeof(CollSeq) + u64(n_name)))
		if p_coll {
			p_del := unsafe { &CollSeq(nil) }
			p_coll[0].zName = &i8(voidptr(unsafe { p_coll + 3 }))
			p_coll[0].enc = U8(1)
			p_coll[1].zName = &i8(voidptr(unsafe { p_coll + 3 }))
			p_coll[1].enc = U8(2)
			p_coll[2].zName = &i8(voidptr(unsafe { p_coll + 3 }))
			p_coll[2].enc = U8(3)
			C.memcpy(voidptr(p_coll[0].zName), voidptr(z_name), u64(n_name))
			p_del = sqlite3_hash_insert(&db.aCollSeq, p_coll[0].zName, voidptr(p_coll))
			if usize(p_del) != usize(0) {
				sqlite3_oom_fault(db)
				sqlite3_db_free(db, voidptr(p_del))
				p_coll = 0
			}
		}
	}
	return p_coll
}

@[c:'sqlite3FindCollSeq']
fn sqlite3_find_coll_seq(db &Sqlite3, enc U8, z_name &i8, create int) &CollSeq {
	p_coll := &CollSeq(0)
	if z_name {
		p_coll = find_coll_seq_entry(db, z_name, create)
		if p_coll {
			c2v_pointer_prefix(voidptr(&p_coll), p_coll, isize(int(enc) - 1))
		}
	} else {
		p_coll = db.pDfltColl
	}
	return p_coll
}

@[c:'sqlite3SetTextEncoding']
fn sqlite3_set_text_encoding(db &Sqlite3, enc U8) {
	db.enc = enc
	db.pDfltColl = sqlite3_find_coll_seq(db, enc, unsafe { &i8(&sqlite3StrBINARY[0]) }, 0)
	sqlite3_expire_prepared_statements(db, 1)
}

@[c:'sqlite3GetCollSeq']
fn sqlite3_get_coll_seq(p_parse &Parse, enc U8, p_coll &CollSeq, z_name &i8) &CollSeq {
	p := &CollSeq(0)
	db := p_parse.db
	p = p_coll
	if isnil(p) {
		p = sqlite3_find_coll_seq(db, enc, z_name, 0)
	}
	if isnil(p) || isnil(p.xCmp) {
		call_coll_needed(db, int(enc), z_name)
		p = sqlite3_find_coll_seq(db, enc, z_name, 0)
	}
	if !isnil(p) && isnil(p.xCmp) && synth_coll_seq(db, p) {
		p = 0
	}
	if usize(p) == usize(0) {
		sqlite3_error_msg(p_parse, c'no such collation sequence: %s', voidptr(z_name))
		p_parse.rc = (1 | (1 << 8))
	}
	return p
}

@[c:'sqlite3LocateCollSeq']
fn sqlite3_locate_coll_seq(p_parse &Parse, z_name &i8) &CollSeq {
	db := p_parse.db
	enc := db.enc
	initbusy := db.init.busy
	p_coll := &CollSeq(0)
	p_coll = sqlite3_find_coll_seq(db, enc, z_name, int(initbusy))
	if !initbusy && (isnil(p_coll) || isnil(p_coll.xCmp)) {
		p_coll = sqlite3_get_coll_seq(p_parse, enc, p_coll, z_name)
	}
	return p_coll
}

@[c:'matchQuality']
fn match_quality(p &FuncDef, n_arg int, enc U8) int {
	match_ := 0
	if int(p.nArg) != n_arg {
		if n_arg == (-2) {
			return if isnil(p.xSFunc) { 0 } else { 6 }
		}
		if int(p.nArg) >= 0 {
			return 0
		}
		if int(p.nArg) < (-2) && n_arg < (-2 - int(p.nArg)) {
			return 0
		}
	}
	if int(p.nArg) == n_arg {
		match_ = 4
	} else {
		match_ = 1
	}
	if u32(enc) == (p.funcFlags & u32(3)) {
		match_ += 2
	} else if (u32(enc) & p.funcFlags & u32(2)) != u32(0) {
		match_ += 1
	}
	return match_
}

@[c:'sqlite3FunctionSearch']
fn sqlite3_function_search(h int, z_func &i8) &FuncDef {
	p := &FuncDef(0)
	for p = sqlite3BuiltinFunctions.a[h]; p; p = p.u.pHash {
		if sqlite3_str_ic_mp(p.zName, z_func) == 0 {
			return p
		}
	}
	return unsafe { nil }
}

@[c:'sqlite3InsertBuiltinFuncs']
fn sqlite3_insert_builtin_funcs(a_def &FuncDef, n_def int) {
	i := 0
	for i = 0; i < n_def; i++ {
		p_other := &FuncDef(0)
		z_name := a_def[i].zName
		n_name := sqlite3_strlen30(z_name)
		h := ((int(z_name[0]) + n_name) % 23)
		p_other = sqlite3_function_search(h, z_name)
		if p_other {
			a_def[i].pNext = p_other.pNext
			p_other.pNext = unsafe { a_def + i }
		} else {
			a_def[i].pNext = 0
			a_def[i].u.pHash = sqlite3BuiltinFunctions.a[h]
			sqlite3BuiltinFunctions.a[h] = unsafe { a_def + i }
		}
	}
}

@[c:'sqlite3FindFunction']
fn sqlite3_find_function(db &Sqlite3, z_name &i8, n_arg int, enc U8, create_flag U8) &FuncDef {
	p := &FuncDef(0)
	p_best := unsafe { &FuncDef(nil) }
	best_score := 0
	h := 0
	n_name := 0
	n_name = sqlite3_strlen30(z_name)
	p = &FuncDef(sqlite3_hash_find(&db.aFunc, z_name))
	for p {
		score := match_quality(p, n_arg, enc)
		if score > best_score {
			p_best = p
			best_score = score
		}
		p = p.pNext
	}
	if !create_flag && (usize(p_best) == usize(0) || (db.mDbFlags & u32(2)) != u32(0)) {
		best_score = 0
		h = ((int(sqlite3UpperToLower[U8(z_name[0])]) + n_name) % 23)
		p = sqlite3_function_search(h, z_name)
		for p {
			score := match_quality(p, n_arg, enc)
			if score > best_score {
				p_best = p
				best_score = score
			}
			p = p.pNext
		}
	}
	if int(create_flag) && best_score < 6 && usize(c2v_assign[&FuncDef](unsafe { &p_best }, sqlite3_db_malloc_zero(db, U64(sizeof(FuncDef) + u64(n_name) + u64(1))))) != usize(0) {
		p_other := &FuncDef(0)
		z := &U8(0)
		p_best.zName = &i8(voidptr(unsafe { p_best + 1 }))
		p_best.nArg = I16(U16(n_arg))
		p_best.funcFlags = u32(enc)
		C.memcpy(voidptr(&i8(voidptr(unsafe { p_best + 1 }))), voidptr(z_name), u64(n_name + 1))
		for z = &U8(voidptr(p_best.zName)); (unsafe { *z }); z = unsafe { z + 1 } {
			unsafe { *z = sqlite3UpperToLower[*z] }
		}
		p_other = &FuncDef(sqlite3_hash_insert(&db.aFunc, p_best.zName, voidptr(p_best)))
		if usize(p_other) == usize(p_best) {
			sqlite3_db_free(db, voidptr(p_best))
			sqlite3_oom_fault(db)
			return unsafe { nil }
		} else {
			p_best.pNext = p_other
		}
	}
	if !isnil(p_best) && (!isnil(p_best.xSFunc) || int(create_flag)) {
		return p_best
	}
	return unsafe { nil }
}

@[c:'sqlite3SchemaClear']
fn sqlite3_schema_clear(p voidptr) {
	c2v_gc_register_thread()
	temp1 := Hash{}
	temp2 := Hash{}
	p_elem := &HashElem(0)
	p_schema := &Schema(p)
	xdb := Sqlite3{}
	C.memset(voidptr(&xdb), 0, sizeof(xdb))
	temp1 = p_schema.tblHash
	temp2 = p_schema.trigHash
	sqlite3_hash_init(&p_schema.trigHash)
	sqlite3_hash_clear(&p_schema.idxHash)
	for p_elem = temp2.first; p_elem; p_elem = p_elem.next {
		sqlite3_delete_trigger(&xdb, &Trigger(p_elem.data))
	}
	sqlite3_hash_clear(&temp2)
	sqlite3_hash_init(&p_schema.tblHash)
	for p_elem = temp1.first; p_elem; p_elem = p_elem.next {
		p_tab := &Table(p_elem.data)
		sqlite3_delete_table(&xdb, p_tab)
	}
	sqlite3_hash_clear(&temp1)
	sqlite3_hash_clear(&p_schema.fkeyHash)
	p_schema.pSeqTab = 0
	if int(p_schema.schemaFlags) & 1 {
		p_schema.iGeneration++
	}
	p_schema.schemaFlags &= ~(1 | 8)
}

@[c:'sqlite3SchemaGet']
fn sqlite3_schema_get(db &Sqlite3, p_bt &Btree) &Schema {
	p := &Schema(0)
	if p_bt {
		p = &Schema(sqlite3_btree_schema(p_bt, int(sizeof(Schema)), sqlite3_schema_clear))
	} else {
		p = &Schema(sqlite3_db_malloc_zero(unsafe { nil }, U64(sizeof(Schema))))
	}
	if isnil(p) {
		sqlite3_oom_fault(db)
	} else if 0 == int(p.file_format) {
		sqlite3_hash_init(&p.tblHash)
		sqlite3_hash_init(&p.idxHash)
		sqlite3_hash_init(&p.trigHash)
		sqlite3_hash_init(&p.fkeyHash)
		p.enc = U8(1)
	}
	return p
}
