@[translated]
module main

struct Incrblob {
	nByte   int
	iOffset int
	iCol    U16
	pCsr    &BtCursor
	pStmt   &Sqlite3_stmt
	db      &Sqlite3
	zDb     &i8
	pTab    &Table
}

@[c:'blobSeekToRow']
fn blob_seek_to_row(p &Incrblob, i_row Sqlite3_int64, pz_err &&u8) int {
	rc := 0
	z_err := unsafe { &i8(nil) }
	v := &Vdbe(voidptr(p.pStmt))
	sqlite3_vdbe_mem_set_int64(unsafe { v.aMem + 1 }, i_row)
	if v.pc > 4 {
		v.pc = 4
		rc = sqlite3_vdbe_exec(v)
	} else {
		rc = sqlite3_step(p.pStmt)
	}
	if rc == 100 {
		pc := v.apCsr[0]
		type_ := u32(0)
		type_ = if int(pc.nHdrParsed) > int(p.iCol) { (&pc.aType[0])[p.iCol] } else { u32(0) }
		if type_ < u32(12) {
			z_err = sqlite3_mp_rintf(p.db, c'cannot open value of type %s', voidptr(if type_ == u32(0) {
				c'null'
			} else {
				if type_ == u32(7) { c'real' } else { c'integer' }
			}))
			rc = 1
			sqlite3_finalize(p.pStmt)
			p.pStmt = 0
		} else {
			p.iOffset = int((&pc.aType[0])[int(p.iCol) + int(pc.nField)])
			p.nByte = int(sqlite3_vdbe_serial_type_len(type_))
			p.pCsr = pc.uc.pCursor
			sqlite3_btree_incrblob_cursor(p.pCsr)
		}
	}
	if rc == 100 {
		rc = 0
	} else if p.pStmt {
		rc = sqlite3_finalize(p.pStmt)
		p.pStmt = 0
		if rc == 0 {
			z_err = sqlite3_mp_rintf(p.db, c'no such rowid: %lld', i_row)
			rc = 1
		} else {
			z_err = sqlite3_mp_rintf(p.db, c'%s', voidptr(sqlite3_errmsg(p.db)))
		}
	}
	unsafe { *pz_err = z_err }
	return rc
}

fn sqlite3_blob_open(db &Sqlite3, z_db &i8, z_table &i8, z_column &i8, i_row Sqlite_int64, wr_flag int, pp_blob &&Sqlite3_blob) int {
	c2v_gc_register_thread()
	n_attempt := 0
	i_col := 0
	rc := 0
	z_err := unsafe { &i8(nil) }
	p_tab := &Table(0)
	p_blob := unsafe { &Incrblob(nil) }
	i_db := 0
	s_parse := Parse{}
	unsafe { *pp_blob = 0 }
	wr_flag = !!wr_flag
	sqlite3_mutex_enter(db.mutex)
	p_blob = &Incrblob(sqlite3_db_malloc_zero(db, U64(sizeof(Incrblob))))
	for {
		sqlite3_parse_object_init(&s_parse, db)
		if isnil(p_blob) {
			unsafe { goto blob_open_out
			 }
		}
		sqlite3_db_free(db, voidptr(z_err))
		z_err = 0
		sqlite3_btree_enter_all(db)
		p_tab = sqlite3_locate_table(&s_parse, u32(0), z_table, z_db)
		if !isnil(p_tab) && (int(p_tab.eTabType) == 1) {
			p_tab = 0
			sqlite3_error_msg(&s_parse, c'cannot open virtual table: %s', voidptr(z_table))
		}
		if !isnil(p_tab) && !((p_tab.tabFlags & u32(128)) == u32(0)) {
			p_tab = 0
			sqlite3_error_msg(&s_parse, c'cannot open table without rowid: %s', voidptr(z_table))
		}
		if !isnil(p_tab) && (p_tab.tabFlags & u32(96)) != u32(0) {
			p_tab = 0
			sqlite3_error_msg(&s_parse, c'cannot open table with generated columns: %s', voidptr(z_table))
		}
		if !isnil(p_tab) && (int(p_tab.eTabType) == 2) {
			p_tab = 0
			sqlite3_error_msg(&s_parse, c'cannot open view: %s', voidptr(z_table))
		}
		if usize(p_tab) == usize(0) || (c2v_assign[int](unsafe { &i_db }, int(sqlite3_schema_to_index(db, p_tab.pSchema))) == 1 && sqlite3_open_temp_database(&s_parse)) {
			if s_parse.zErrMsg {
				sqlite3_db_free(db, voidptr(z_err))
				z_err = s_parse.zErrMsg
				s_parse.zErrMsg = 0
			}
			rc = 1
			sqlite3_btree_leave_all(db)
			unsafe { goto blob_open_out
			 }
		}
		p_blob.pTab = p_tab
		p_blob.zDb = db.aDb[i_db].zDbSName
		i_col = sqlite3_column_index(p_tab, z_column)
		if i_col < 0 {
			sqlite3_db_free(db, voidptr(z_err))
			z_err = sqlite3_mp_rintf(db, c'no such column: "%s"', voidptr(z_column))
			rc = 1
			sqlite3_btree_leave_all(db)
			unsafe { goto blob_open_out
			 }
		}
		if wr_flag {
			z_fault := unsafe { &i8(nil) }
			p_idx := &Index(0)
			if db.flags & U64(16384) {
				pfk_ey := &FKey(0)
				for pfk_ey = p_tab.u.tab.pFKey; pfk_ey; pfk_ey = pfk_ey.pNextFrom {
					j := 0
					for j = 0; j < pfk_ey.nCol; j++ {
						if c2v_at(&pfk_ey.aCol[0], isize(j)).iFrom == i_col {
							z_fault = c'foreign key'
						}
					}
				}
			}
			for p_idx = p_tab.pIndex; p_idx; p_idx = p_idx.pNext {
				j := 0
				for j = 0; j < int(p_idx.nKeyCol); j++ {
					if int(p_idx.aiColumn[j]) == i_col || int(p_idx.aiColumn[j]) == (-2) {
						z_fault = c'indexed'
					}
				}
			}
			if z_fault {
				sqlite3_db_free(db, voidptr(z_err))
				z_err = sqlite3_mp_rintf(db, c'cannot open %s column for writing', voidptr(z_fault))
				rc = 1
				sqlite3_btree_leave_all(db)
				unsafe { goto blob_open_out
				 }
			}
		}
		p_blob.pStmt = &Sqlite3_stmt(voidptr(sqlite3_vdbe_create(&s_parse)))
		if p_blob.pStmt {
			static i_ln := 0
			if !sqlite3_blob_open_open_blob_inited {
				c2v_static_init := [VdbeOpList{
					opcode: U8(171)
					p1: i8(0)
					p2: i8(0)
					p3: i8(0)
				}, VdbeOpList{
					opcode: U8(114)
					p1: i8(0)
					p2: i8(0)
					p3: i8(0)
				}, VdbeOpList{
					opcode: U8(31)
					p1: i8(0)
					p2: i8(5)
					p3: i8(1)
				}, VdbeOpList{
					opcode: U8(96)
					p1: i8(0)
					p2: i8(0)
					p3: i8(1)
				}, VdbeOpList{
					opcode: U8(86)
					p1: i8(1)
					p2: i8(0)
					p3: i8(0)
				}, VdbeOpList{
					opcode: U8(72)
					p1: i8(0)
					p2: i8(0)
					p3: i8(0)
				}]
				for c2v_i_0, c2v_element_0 in c2v_static_init {
					sqlite3_blob_open_open_blob[c2v_i_0] = c2v_element_0
				}
				sqlite3_blob_open_open_blob_inited = true
			}

			v := &Vdbe(voidptr(p_blob.pStmt))
			mut a_op := &VdbeOp(0)
			sqlite3_vdbe_add_op4_int(v, 2, i_db, wr_flag, p_tab.pSchema.schema_cookie, p_tab.pSchema.iGeneration)
			sqlite3_vdbe_change_p5(v, U16(1))
			a_op = sqlite3_vdbe_add_op_list(v, 6, &sqlite3_blob_open_open_blob[0], i_ln)
			sqlite3_vdbe_uses_btree(v, i_db)
			if int(db.mallocFailed) == 0 {
				a_op[0].p1 = i_db
				a_op[0].p2 = int(p_tab.tnum)
				a_op[0].p3 = wr_flag
				sqlite3_vdbe_change_p4(v, 2, p_tab.zName, 0)
			}
			if int(db.mallocFailed) == 0 {
				if wr_flag {
					a_op[1].opcode = U8(116)
				}
				a_op[1].p2 = int(p_tab.tnum)
				a_op[1].p3 = i_db
				a_op[1].p4type = i8((-3))
				a_op[1].p4.i = int(p_tab.nCol) + 1
				a_op[3].p2 = int(p_tab.nCol)
				s_parse.nVar = YnVar(0)
				s_parse.nMem = 1
				s_parse.nTab = 1
				sqlite3_vdbe_make_ready(v, &s_parse)
			}
		}
		p_blob.iCol = U16(i_col)
		p_blob.db = db
		sqlite3_btree_leave_all(db)
		if db.mallocFailed {
			unsafe { goto blob_open_out
			 }
		}
		rc = blob_seek_to_row(p_blob, i_row, &&u8(&&i8(c2v_address_of(&z_err))))
		n_attempt++
		if n_attempt >= 50 || rc != 17 {
			break
		}
		sqlite3_parse_object_reset(&s_parse)
	}
	blob_open_out:
	if rc == 0 && int(db.mallocFailed) == 0 {
		unsafe { *pp_blob = &Sqlite3_blob(voidptr(p_blob)) }
	} else {
		if !isnil(p_blob) && !isnil(p_blob.pStmt) {
			sqlite3_vdbe_finalize(&Vdbe(voidptr(p_blob.pStmt)))
		}
		sqlite3_db_free(db, voidptr(p_blob))
	}
	sqlite3_error_with_msg(db, rc, unsafe { if z_err { c'%s' } else { &i8(nil) } }, voidptr(z_err))
	sqlite3_db_free(db, voidptr(z_err))
	sqlite3_parse_object_reset(&s_parse)
	rc = sqlite3_api_exit(db, rc)
	sqlite3_mutex_leave(db.mutex)
	return rc
}

fn sqlite3_blob_close(p_blob &Sqlite3_blob) int {
	c2v_gc_register_thread()
	p := &Incrblob(voidptr(p_blob))
	rc := 0
	db := &Sqlite3(0)
	if p {
		p_stmt := p.pStmt
		db = p.db
		sqlite3_mutex_enter(db.mutex)
		sqlite3_db_free(db, voidptr(p))
		sqlite3_mutex_leave(db.mutex)
		rc = sqlite3_finalize(p_stmt)
	} else {
		rc = 0
	}
	return rc
}

@[c:'blobReadWrite']
fn blob_read_write(p_blob &Sqlite3_blob, z voidptr, n int, i_offset int, x_call fn (&BtCursor, u32, u32, voidptr) int) int {
	rc := 0
	p := &Incrblob(voidptr(p_blob))
	v := &Vdbe(0)
	db := &Sqlite3(0)
	if usize(p) == usize(0) {
		return sqlite3_misuse_error(393)
	}
	db = p.db
	sqlite3_mutex_enter(db.mutex)
	v = &Vdbe(voidptr(p.pStmt))
	if n < 0 || i_offset < 0 || (Sqlite3_int64(i_offset) + Sqlite3_int64(n)) > Sqlite3_int64(p.nByte) {
		rc = 1
	} else if usize(v) == usize(0) {
		rc = 4
	} else {
		sqlite3_btree_enter_cursor(p.pCsr)
		rc = x_call(p.pCsr, u32(i_offset + p.iOffset), u32(n), voidptr(z))
		sqlite3_btree_leave_cursor(p.pCsr)
		if rc == 4 {
			sqlite3_vdbe_finalize(v)
			p.pStmt = 0
		} else {
			v.rc = rc
		}
	}
	sqlite3_error(db, rc)
	rc = sqlite3_api_exit(db, rc)
	sqlite3_mutex_leave(db.mutex)
	return rc
}

fn sqlite3_blob_read(p_blob &Sqlite3_blob, z voidptr, n int, i_offset int) int {
	c2v_gc_register_thread()
	return blob_read_write(p_blob, voidptr(z), n, i_offset, sqlite3_btree_payload_checked)
}

fn sqlite3_blob_write(p_blob &Sqlite3_blob, z voidptr, n int, i_offset int) int {
	c2v_gc_register_thread()
	return blob_read_write(p_blob, voidptr(z), n, i_offset, sqlite3_btree_put_data)
}

fn sqlite3_blob_bytes(p_blob &Sqlite3_blob) int {
	c2v_gc_register_thread()
	p := &Incrblob(voidptr(p_blob))
	return if (!isnil(p) && !isnil(p.pStmt)) { p.nByte } else { 0 }
}

fn sqlite3_blob_reopen(p_blob &Sqlite3_blob, i_row Sqlite3_int64) int {
	c2v_gc_register_thread()
	rc := 0
	p := &Incrblob(voidptr(p_blob))
	db := &Sqlite3(0)
	if usize(p) == usize(0) {
		return sqlite3_misuse_error(508)
	}
	db = p.db
	sqlite3_mutex_enter(db.mutex)
	if usize(p.pStmt) == usize(0) {
		rc = 4
	} else {
		z_err := &i8(0)
		(&Vdbe(voidptr(p.pStmt))).rc = 0
		rc = blob_seek_to_row(p, i_row, &&u8(&&i8(c2v_address_of(&z_err))))
		if rc != 0 {
			sqlite3_error_with_msg(db, rc, unsafe { if z_err { c'%s' } else { &i8(nil) } }, voidptr(z_err))
			sqlite3_db_free(db, voidptr(z_err))
		}
	}
	rc = sqlite3_api_exit(db, rc)
	sqlite3_mutex_leave(db.mutex)
	return rc
}
