@[translated]
module main

@[c:'sqlite3DeleteTriggerStep']
fn sqlite3_delete_trigger_step(db &Sqlite3, p_trigger_step &TriggerStep) {
	for p_trigger_step {
		p_tmp := p_trigger_step
		p_trigger_step = p_trigger_step.pNext
		sqlite3_expr_delete(db, p_tmp.pWhere)
		sqlite3_expr_list_delete(db, p_tmp.pExprList)
		sqlite3_select_delete(db, p_tmp.pSelect)
		sqlite3_id_list_delete(db, p_tmp.pIdList)
		sqlite3_upsert_delete(db, p_tmp.pUpsert)
		sqlite3_src_list_delete(db, p_tmp.pSrc)
		sqlite3_db_free(db, voidptr(p_tmp.zSpan))
		sqlite3_db_free(db, voidptr(p_tmp))
	}
}

@[c:'sqlite3TriggerList']
fn sqlite3_trigger_list(p_parse &Parse, p_tab &Table) &Trigger {
	p_tmp_schema := &Schema(0)
	p_list := &Trigger(0)
	p := &HashElem(0)
	p_tmp_schema = p_parse.db.aDb[1].pSchema
	p = p_tmp_schema.trigHash.first
	p_list = p_tab.pTrigger
	for p {
		p_trig := &Trigger(p.data)
		mut __c2v_condition_95 := false
		mut __c2v_condition_96 := false
		__c2v_condition_96 = usize(p_trig.pTabSchema) == usize(p_tab.pSchema)
		if __c2v_condition_96 {
			__c2v_condition_96 = !isnil(p_trig.table)
		}
		if __c2v_condition_96 {
			__c2v_condition_96 = 0 == sqlite3_str_ic_mp(p_trig.table, p_tab.zName)
		}
		if __c2v_condition_96 {
			__c2v_condition_96 = (usize(p_trig.pTabSchema) != usize(p_tmp_schema) || int(p_trig.bReturning))
		}
		__c2v_condition_95 = __c2v_condition_96
		if __c2v_condition_95 {
			p_trig.pNext = p_list
			p_list = p_trig
		} else if int(p_trig.op) == 151 {
			p_trig.table = p_tab.zName
			p_trig.pTabSchema = p_tab.pSchema
			p_trig.pNext = p_list
			p_list = p_trig
		}
		p = p.next
	}
	return p_list
}

@[c:'sqlite3BeginTrigger']
fn sqlite3_begin_trigger(p_parse &Parse, p_name1 &Token, p_name2 &Token, tr_tm int, op int, p_columns &IdList, p_table_name &SrcList, p_when &Expr, is_temp int, no_err int) {
	p_trigger := unsafe { &Trigger(nil) }
	p_tab := &Table(0)
	z_name := unsafe { &i8(nil) }
	db := p_parse.db
	i_db := 0
	p_name := &Token(0)
	s_fix := DbFixer{}
	if is_temp {
		if p_name2.n > u32(0) {
			sqlite3_error_msg(p_parse, c'temporary trigger may not have qualified name')
			unsafe { goto trigger_cleanup
			 }
		}
		i_db = 1
		p_name = p_name1
	} else {
		i_db = sqlite3_two_part_name(p_parse, p_name1, p_name2, &&Token(&&Token(c2v_address_of(&p_name))))
		if i_db < 0 {
			unsafe { goto trigger_cleanup
			 }
		}
	}
	if isnil(p_table_name) || int(db.mallocFailed) {
		unsafe { goto trigger_cleanup
		 }
	}
	if int(db.init.busy) && i_db != 1 {
		sqlite3_db_free(db, voidptr(c2v_at(&p_table_name.a[0], isize(0)).u4.zDatabase))
		mut __c2v_lhs_tmp_150 := c2v_at(&p_table_name.a[0], isize(0))
		__c2v_lhs_tmp_150.u4.zDatabase = 0
	}
	p_tab = sqlite3_src_list_lookup(p_parse, p_table_name)
	if int(db.init.busy) == 0 && p_name2.n == u32(0) && !isnil(p_tab) && usize(p_tab.pSchema) == usize(db.aDb[1].pSchema) {
		i_db = 1
	}
	if db.mallocFailed {
		unsafe { goto trigger_cleanup
		 }
	}
	sqlite3_fix_init(&s_fix, p_parse, i_db, c'trigger', p_name)
	if sqlite3_fix_src_list(&s_fix, p_table_name) {
		unsafe { goto trigger_cleanup
		 }
	}
	p_tab = sqlite3_src_list_lookup(p_parse, p_table_name)
	if isnil(p_tab) {
		unsafe { goto trigger_orphan_error
		 }
	}
	if (int(p_tab.eTabType) == 1) {
		sqlite3_error_msg(p_parse, c'cannot create triggers on virtual tables')
		unsafe { goto trigger_orphan_error
		 }
	}
	if (p_tab.tabFlags & u32(4096)) != u32(0) && sqlite3_read_only_shadow_tables(db) {
		sqlite3_error_msg(p_parse, c'cannot create triggers on shadow tables')
		unsafe { goto trigger_orphan_error
		 }
	}
	z_name = sqlite3_name_from_token(db, p_name)
	if usize(z_name) == usize(0) {
		unsafe { goto trigger_cleanup
		 }
	}
	if sqlite3_check_object_name(p_parse, z_name, c'trigger', p_tab.zName) {
		unsafe { goto trigger_cleanup
		 }
	}
	if !(int(p_parse.eParseMode) >= 2) {
		if sqlite3_hash_find(&db.aDb[i_db].pSchema.trigHash, z_name) {
			if !no_err {
				sqlite3_error_msg(p_parse, c'trigger %T already exists', voidptr(p_name))
			} else {
				sqlite3_code_verify_schema(p_parse, i_db)
			}
			unsafe { goto trigger_cleanup
			 }
		}
	}
	if sqlite3_strnicmp(p_tab.zName, c'sqlite_', 7) == 0 {
		sqlite3_error_msg(p_parse, c'cannot create trigger on system table')
		unsafe { goto trigger_cleanup
		 }
	}
	if (int(p_tab.eTabType) == 2) && tr_tm != 66 {
		sqlite3_error_msg(p_parse, c'cannot create %s trigger on view: %S', voidptr(if (tr_tm == 33) {
			c'BEFORE'
		} else {
			c'AFTER'
		}), voidptr(&p_table_name.a[0]))
		unsafe { goto trigger_orphan_error
		 }
	}
	if !(int(p_tab.eTabType) == 2) && tr_tm == 66 {
		sqlite3_error_msg(p_parse, c'cannot create INSTEAD OF trigger on table: %S', voidptr(&p_table_name.a[0]))
		unsafe { goto trigger_orphan_error
		 }
	}
	if !(int(p_parse.eParseMode) >= 2) {
		i_tab_db := sqlite3_schema_to_index(db, p_tab.pSchema)
		code := 7
		z_db := db.aDb[i_tab_db].zDbSName
		z_db_trig := if is_temp { db.aDb[1].zDbSName } else { z_db }
		if i_tab_db == 1 || is_temp {
			code = 5
		}
		if sqlite3_auth_check(p_parse, code, z_name, p_tab.zName, z_db_trig) {
			unsafe { goto trigger_cleanup
			 }
		}
		if sqlite3_auth_check(p_parse, 18, unsafe { if (!0) && (i_tab_db == 1) {
			c'sqlite_temp_master'
		} else {
			c'sqlite_master'
		} }, unsafe { nil }, z_db) {
			unsafe { goto trigger_cleanup
			 }
		}
	}
	if tr_tm == 66 {
		tr_tm = 33
	}
	p_trigger = &Trigger(sqlite3_db_malloc_zero(db, U64(sizeof(Trigger))))
	if usize(p_trigger) == usize(0) {
		unsafe { goto trigger_cleanup
		 }
	}
	p_trigger.zName = z_name
	z_name = 0
	p_trigger.table = sqlite3_db_str_dup(db, c2v_at(&p_table_name.a[0], isize(0)).zName)
	p_trigger.pSchema = db.aDb[i_db].pSchema
	p_trigger.pTabSchema = p_tab.pSchema
	p_trigger.op = U8(op)
	p_trigger.tr_tm = U8(if tr_tm == 33 { 1 } else { 2 })
	if (int(p_parse.eParseMode) >= 2) {
		sqlite3_rename_token_remap(p_parse, voidptr(p_trigger.table), voidptr(c2v_at(&p_table_name.a[0], isize(0)).zName))
		p_trigger.pWhen = p_when
		p_when = 0
	} else {
		p_trigger.pWhen = sqlite3_expr_dup(db, p_when, 1)
	}
	p_trigger.pColumns = p_columns
	p_columns = 0
	p_parse.pNewTrigger = p_trigger
	trigger_cleanup:
	sqlite3_db_free(db, voidptr(z_name))
	sqlite3_src_list_delete(db, p_table_name)
	sqlite3_id_list_delete(db, p_columns)
	sqlite3_expr_delete(db, p_when)
	if isnil(p_parse.pNewTrigger) {
		sqlite3_delete_trigger(db, p_trigger)
	} else {
	}
	return
	trigger_orphan_error:
	if int(db.init.iDb) == 1 {
		db.init.orphanTrigger = u32(1)
	}
	unsafe { goto trigger_cleanup
	 }
}

@[c:'sqlite3FinishTrigger']
fn sqlite3_finish_trigger(p_parse &Parse, p_step_list &TriggerStep, p_all &Token) {
	p_trig := p_parse.pNewTrigger
	z_name := &i8(0)
	db := p_parse.db
	s_fix := DbFixer{}
	i_db := 0
	name_token := Token{}
	p_parse.pNewTrigger = 0
	if p_parse.nErr || isnil(p_trig) {
		unsafe { goto triggerfinish_cleanup
		 }
	}
	z_name = p_trig.zName
	i_db = sqlite3_schema_to_index(p_parse.db, p_trig.pSchema)
	p_trig.step_list = p_step_list
	for p_step_list {
		p_step_list.pTrig = p_trig
		p_step_list = p_step_list.pNext
	}
	sqlite3_token_init(&name_token, p_trig.zName)
	sqlite3_fix_init(&s_fix, p_parse, i_db, c'trigger', &name_token)
	if sqlite3_fix_trigger_step(&s_fix, p_trig.step_list) || sqlite3_fix_expr(&s_fix, p_trig.pWhen) {
		unsafe { goto triggerfinish_cleanup
		 }
	}
	if (int(p_parse.eParseMode) >= 2) {
		p_parse.pNewTrigger = p_trig
		p_trig = 0
	} else if !db.init.busy {
		v := &Vdbe(0)
		z := &i8(0)
		if sqlite3_read_only_shadow_tables(db) {
			p_step := &TriggerStep(0)
			for p_step = p_trig.step_list; p_step; p_step = p_step.pNext {
				if usize(p_step.pSrc) != usize(0) && sqlite3_shadow_table_name(db, c2v_at(&p_step.pSrc.a[0], isize(0)).zName) {
					sqlite3_error_msg(p_parse, c'trigger "%s" may not write to shadow table "%s"', voidptr(p_trig.zName), voidptr(c2v_at(&p_step.pSrc.a[0], isize(0)).zName))
					unsafe { goto triggerfinish_cleanup
					 }
				}
			}
		}
		v = sqlite3_get_vdbe(p_parse)
		if usize(v) == usize(0) {
			unsafe { goto triggerfinish_cleanup
			 }
		}
		sqlite3_begin_write_operation(p_parse, 0, i_db)
		z = sqlite3_db_str_nd_up(db, &i8(p_all.z), U64(p_all.n))
		sqlite3_nested_parse(p_parse, c"INSERT INTO %Q.sqlite_master VALUES('trigger',%Q,%Q,0,'CREATE TRIGGER %q')", voidptr(db.aDb[i_db].zDbSName), voidptr(z_name), voidptr(p_trig.table), voidptr(z))
		sqlite3_db_free(db, voidptr(z))
		sqlite3_change_cookie(p_parse, i_db)
		sqlite3_vdbe_add_parse_schema_op(v, i_db, sqlite3_mp_rintf(db, c"type='trigger' AND name='%q'", voidptr(z_name)), U16(0))
	}
	if db.init.busy {
		p_link := p_trig
		p_hash := &db.aDb[i_db].pSchema.trigHash
		p_trig = sqlite3_hash_insert(p_hash, z_name, voidptr(p_trig))
		if p_trig {
			sqlite3_oom_fault(db)
		} else if usize(p_link.pSchema) == usize(p_link.pTabSchema) {
			p_tab := &Table(0)
			p_tab = sqlite3_hash_find(&p_link.pTabSchema.tblHash, p_link.table)
			p_link.pNext = p_tab.pTrigger
			p_tab.pTrigger = p_link
		}
	}
	triggerfinish_cleanup:
	sqlite3_delete_trigger(db, p_trig)
	sqlite3_delete_trigger_step(db, p_step_list)
}

@[c:'triggerSpanDup']
fn trigger_span_dup(db &Sqlite3, z_start &i8, z_end &i8) &i8 {
	z := sqlite3_db_span_dup(db, z_start, z_end)
	i := 0
	if z {
		for i = 0; z[i]; i++ {
			if (int(sqlite3CtypeMap[u8(z[i])]) & 1) {
				z[i] = i8(` `)
			}
		}
	}
	return z
}

@[c:'sqlite3TriggerSelectStep']
fn sqlite3_trigger_select_step(db &Sqlite3, p_select &Select, z_start &i8, z_end &i8) &TriggerStep {
	p_trigger_step := &TriggerStep(sqlite3_db_malloc_zero(db, U64(sizeof(TriggerStep))))
	if usize(p_trigger_step) == usize(0) {
		sqlite3_select_delete(db, p_select)
		return unsafe { nil }
	}
	p_trigger_step.op = U8(139)
	p_trigger_step.pSelect = p_select
	p_trigger_step.orconf = U8(11)
	p_trigger_step.zSpan = trigger_span_dup(db, z_start, z_end)
	return p_trigger_step
}

@[c:'triggerStepAllocate']
fn trigger_step_allocate(p_parse &Parse, op U8, p_tab_list &SrcList, z_start &i8, z_end &i8) &TriggerStep {
	p_new := p_parse.pNewTrigger
	db := p_parse.db
	p_trigger_step := unsafe { &TriggerStep(nil) }
	if p_parse.nErr == 0 {
		if !isnil(p_new) && usize(p_new.pSchema) != usize(db.aDb[1].pSchema) && !isnil(c2v_at(&p_tab_list.a[0], isize(0)).u4.zDatabase) {
			sqlite3_error_msg(p_parse, c'qualified table names are not allowed on INSERT, UPDATE, and DELETE statements within triggers')
		} else {
			p_trigger_step = sqlite3_db_malloc_zero(db, U64(sizeof(TriggerStep)))
			if p_trigger_step {
				p_trigger_step.pSrc = sqlite3_src_list_dup(db, p_tab_list, 1)
				p_trigger_step.op = op
				p_trigger_step.zSpan = trigger_span_dup(db, z_start, z_end)
				if !isnil(p_trigger_step.pSrc) && (int(p_parse.eParseMode) >= 2) {
					sqlite3_rename_token_remap(p_parse, voidptr(c2v_at(&p_trigger_step.pSrc.a[0], isize(0)).zName), voidptr(c2v_at(&p_tab_list.a[0], isize(0)).zName))
				}
			}
		}
	}
	sqlite3_src_list_delete(db, p_tab_list)
	return p_trigger_step
}

@[c:'sqlite3TriggerInsertStep']
fn sqlite3_trigger_insert_step(p_parse &Parse, p_tab_list &SrcList, p_column &IdList, p_select &Select, orconf U8, p_upsert &Upsert, z_start &i8, z_end &i8) &TriggerStep {
	db := p_parse.db
	p_trigger_step := &TriggerStep(0)
	p_trigger_step = trigger_step_allocate(p_parse, U8(128), p_tab_list, z_start, z_end)
	if p_trigger_step {
		if (int(p_parse.eParseMode) >= 2) {
			p_trigger_step.pSelect = p_select
			p_select = 0
		} else {
			p_trigger_step.pSelect = sqlite3_select_dup(db, p_select, 1)
		}
		p_trigger_step.pIdList = p_column
		p_trigger_step.pUpsert = p_upsert
		p_trigger_step.orconf = orconf
		if p_upsert {
			sqlite3_has_explicit_nulls(p_parse, p_upsert.pUpsertTarget)
		}
	} else {
		sqlite3_id_list_delete(db, p_column)
		sqlite3_upsert_delete(db, p_upsert)
	}
	sqlite3_select_delete(db, p_select)
	return p_trigger_step
}

@[c:'sqlite3TriggerUpdateStep']
fn sqlite3_trigger_update_step(p_parse &Parse, p_tab_list &SrcList, p_from &SrcList, pel_ist &ExprList, p_where &Expr, orconf U8, z_start &i8, z_end &i8) &TriggerStep {
	db := p_parse.db
	p_trigger_step := &TriggerStep(0)
	p_trigger_step = trigger_step_allocate(p_parse, U8(130), p_tab_list, z_start, z_end)
	if p_trigger_step {
		p_from_dup := unsafe { &SrcList(nil) }
		if (int(p_parse.eParseMode) >= 2) {
			p_trigger_step.pExprList = pel_ist
			p_trigger_step.pWhere = p_where
			p_from_dup = p_from
			pel_ist = 0
			p_where = 0
			p_from = 0
		} else {
			p_trigger_step.pExprList = sqlite3_expr_list_dup(db, pel_ist, 1)
			p_trigger_step.pWhere = sqlite3_expr_dup(db, p_where, 1)
			p_from_dup = sqlite3_src_list_dup(db, p_from, 1)
		}
		p_trigger_step.orconf = orconf
		if !isnil(p_from_dup) && !(int(p_parse.eParseMode) >= 2) {
			p_sub := &Select(0)
			as_ := Token{}

			p_sub = sqlite3_select_new(p_parse, unsafe { nil }, p_from_dup, unsafe { nil }, unsafe { nil }, unsafe { nil }, unsafe { nil }, u32(2048), unsafe { nil })
			p_from_dup = sqlite3_src_list_append_from_term(p_parse, unsafe { nil }, unsafe { nil }, unsafe { nil }, &as_, p_sub, unsafe { nil })
		}
		if !isnil(p_from_dup) && !isnil(p_trigger_step.pSrc) {
			p_trigger_step.pSrc = sqlite3_src_list_append_list(p_parse, p_trigger_step.pSrc, p_from_dup)
		} else {
			sqlite3_src_list_delete(db, p_from_dup)
		}
	}
	sqlite3_expr_list_delete(db, pel_ist)
	sqlite3_expr_delete(db, p_where)
	sqlite3_src_list_delete(db, p_from)
	return p_trigger_step
}

@[c:'sqlite3TriggerDeleteStep']
fn sqlite3_trigger_delete_step(p_parse &Parse, p_tab_list &SrcList, p_where &Expr, z_start &i8, z_end &i8) &TriggerStep {
	db := p_parse.db
	p_trigger_step := &TriggerStep(0)
	p_trigger_step = trigger_step_allocate(p_parse, U8(129), p_tab_list, z_start, z_end)
	if p_trigger_step {
		if (int(p_parse.eParseMode) >= 2) {
			p_trigger_step.pWhere = p_where
			p_where = 0
		} else {
			p_trigger_step.pWhere = sqlite3_expr_dup(db, p_where, 1)
		}
		p_trigger_step.orconf = U8(11)
	}
	sqlite3_expr_delete(db, p_where)
	return p_trigger_step
}

@[c:'sqlite3DeleteTrigger']
fn sqlite3_delete_trigger(db &Sqlite3, p_trigger &Trigger) {
	if usize(p_trigger) == usize(0) || int(p_trigger.bReturning) {
		return
	}
	sqlite3_delete_trigger_step(db, p_trigger.step_list)
	sqlite3_db_free(db, voidptr(p_trigger.zName))
	sqlite3_db_free(db, voidptr(p_trigger.table))
	sqlite3_expr_delete(db, p_trigger.pWhen)
	sqlite3_id_list_delete(db, p_trigger.pColumns)
	sqlite3_db_free(db, voidptr(p_trigger))
}

@[c:'sqlite3DropTrigger']
fn sqlite3_drop_trigger(p_parse &Parse, p_name &SrcList, no_err int) {
	p_trigger := unsafe { &Trigger(nil) }
	i := 0
	z_db := &i8(0)
	z_name := &i8(0)
	db := p_parse.db
	if db.mallocFailed {
		unsafe { goto drop_trigger_cleanup
		 }
	}
	if 0 != sqlite3_read_schema(p_parse) {
		unsafe { goto drop_trigger_cleanup
		 }
	}
	z_db = c2v_at(&p_name.a[0], isize(0)).u4.zDatabase
	z_name = c2v_at(&p_name.a[0], isize(0)).zName
	for i = 0; i < db.nDb; i++ {
		j := if (i < 2) { i ^ 1 } else { i }
		if !isnil(z_db) && sqlite3_db_is_named(db, j, z_db) == 0 {
			continue
		}
		p_trigger = sqlite3_hash_find(&db.aDb[j].pSchema.trigHash, z_name)
		if p_trigger {
			break
		}
	}
	if isnil(p_trigger) {
		if !no_err {
			sqlite3_error_msg(p_parse, c'no such trigger: %S', voidptr(&p_name.a[0]))
		} else {
			sqlite3_code_verify_named_schema(p_parse, z_db)
		}
		p_parse.checkSchema = Bft(1)
		unsafe { goto drop_trigger_cleanup
		 }
	}
	sqlite3_drop_trigger_ptr(p_parse, p_trigger)
	drop_trigger_cleanup:
	sqlite3_src_list_delete(db, p_name)
}

@[c:'tableOfTrigger']
fn table_of_trigger(p_trigger &Trigger) &Table {
	return sqlite3_hash_find(&p_trigger.pTabSchema.tblHash, p_trigger.table)
}

@[c:'sqlite3DropTriggerPtr']
fn sqlite3_drop_trigger_ptr(p_parse &Parse, p_trigger &Trigger) {
	p_table := &Table(0)
	v := &Vdbe(0)
	db := p_parse.db
	i_db := 0
	i_db = sqlite3_schema_to_index(p_parse.db, p_trigger.pSchema)
	p_table = table_of_trigger(p_trigger)
	if p_table {
		code := 16
		z_db := db.aDb[i_db].zDbSName
		z_tab := (if (!0) && (i_db == 1) { c'sqlite_temp_master' } else { c'sqlite_master' })
		if i_db == 1 {
			code = 14
		}
		if sqlite3_auth_check(p_parse, code, p_trigger.zName, p_table.zName, z_db) || sqlite3_auth_check(p_parse, 9, z_tab, unsafe { nil }, z_db) {
			return
		}
	}
	v = sqlite3_get_vdbe(p_parse)
	if usize(v) != usize(0) {
		sqlite3_nested_parse(p_parse, c"DELETE FROM %Q.sqlite_master WHERE name=%Q AND type='trigger'", voidptr(db.aDb[i_db].zDbSName), voidptr(p_trigger.zName))
		sqlite3_change_cookie(p_parse, i_db)
		sqlite3_vdbe_add_op4(v, 156, i_db, 0, 0, p_trigger.zName, 0)
	}
}

@[c:'sqlite3UnlinkAndDeleteTrigger']
fn sqlite3_unlink_and_delete_trigger(db &Sqlite3, i_db int, z_name &i8) {
	p_trigger := &Trigger(0)
	p_hash := &Hash(0)
	p_hash = &db.aDb[i_db].pSchema.trigHash
	p_trigger = sqlite3_hash_insert(p_hash, z_name, unsafe { nil })
	if p_trigger {
		if usize(p_trigger.pSchema) == usize(p_trigger.pTabSchema) {
			p_tab := table_of_trigger(p_trigger)
			if p_tab {
				pp := &&Trigger(0)
				for pp = &p_tab.pTrigger; (unsafe { *pp }); pp = &(unsafe { *pp }).pNext {
					if usize((unsafe { *pp })) == usize(p_trigger) {
						unsafe { *pp = (*pp).pNext }
						break
					}
				}
			}
		}
		sqlite3_delete_trigger(db, p_trigger)
		db.mDbFlags |= u32(1)
	}
}

@[c:'checkColumnOverlap']
fn check_column_overlap(p_id_list &IdList, pel_ist &ExprList) int {
	e := 0
	if usize(p_id_list) == usize(0) || (usize(pel_ist) == usize(0)) {
		return 1
	}
	for e = 0; e < pel_ist.nExpr; e++ {
		if sqlite3_id_list_index(p_id_list, c2v_at(&pel_ist.a[0], isize(e)).zEName) >= 0 {
			return 1
		}
	}
	return 0
}

@[c:'tempTriggersExist']
fn temp_triggers_exist(db &Sqlite3) int {
	if (usize(db.aDb[1].pSchema) == usize(0)) {
		return 0
	}
	if usize((db.aDb[1].pSchema.trigHash.first)) == usize(0) {
		return 0
	}
	return 1
}

@[c:'triggersReallyExist']
fn triggers_really_exist(p_parse &Parse, p_tab &Table, op int, p_changes &ExprList, p_mask &int) &Trigger {
	mask := 0
	p_list := unsafe { &Trigger(nil) }
	p := &Trigger(0)
	p_list = sqlite3_trigger_list(p_parse, p_tab)
	if usize(p_list) != usize(0) {
		p = p_list
		if (p_parse.db.flags & U64(262144)) == U64(0) && usize(p_tab.pTrigger) != usize(0) && sqlite3_schema_to_index(p_parse.db, p_tab.pTrigger.pSchema) != 1 {
			if usize(p_list) == usize(p_tab.pTrigger) {
				p_list = 0
				unsafe { goto exit_triggers_exist
				 }
			}
			for !isnil(p.pNext) && usize(p.pNext) != usize(p_tab.pTrigger) {
				p = p.pNext
			}
			p.pNext = 0
			p = p_list
		}
		for {
			if int(p.op) == op && check_column_overlap(p.pColumns, p_changes) {
				mask |= int(p.tr_tm)
			} else if int(p.op) == 151 {
				p.op = U8(op)
				if (int(p_tab.eTabType) == 1) {
					if op != 128 {
						sqlite3_error_msg(p_parse, c'%s RETURNING is not available on virtual tables', voidptr(if op == 129 {
							c'DELETE'
						} else {
							c'UPDATE'
						}))
					}
					p.tr_tm = U8(1)
				} else {
					p.tr_tm = U8(2)
				}
				mask |= int(p.tr_tm)
			} else if int(p.bReturning) && int(p.op) == 128 && op == 130 && (usize(p_parse.pToplevel) == usize(0)) {
				mask |= int(p.tr_tm)
			}
			p = p.pNext
			if !p {
				break
			}
		}
	}
	exit_triggers_exist:
	if p_mask {
		unsafe { *p_mask = mask }
	}
	return unsafe { if mask { p_list } else { &Trigger(nil) } }
}

@[c:'sqlite3TriggersExist']
fn sqlite3_triggers_exist(p_parse &Parse, p_tab &Table, op int, p_changes &ExprList, p_mask &int) &Trigger {
	if (usize(p_tab.pTrigger) == usize(0) && !temp_triggers_exist(p_parse.db)) || int(p_parse.disableTriggers) {
		if p_mask {
			unsafe { *p_mask = 0 }
		}
		return unsafe { nil }
	}
	return triggers_really_exist(p_parse, p_tab, op, p_changes, p_mask)
}

@[c:'isAsteriskTerm']
fn is_asterisk_term(p_parse &Parse, p_term &Expr) int {
	if int(p_term.op) == 180 {
		return 1
	}
	if int(p_term.op) != 142 {
		return 0
	}
	if int(p_term.pRight.op) != 180 {
		return 0
	}
	sqlite3_error_msg(p_parse, c'RETURNING may not use "TABLE.*" wildcards')
	return 1
}

@[c:'sqlite3ExpandReturning']
fn sqlite3_expand_returning(p_parse &Parse, p_list &ExprList, p_tab &Table) &ExprList {
	p_new := unsafe { &ExprList(nil) }
	db := p_parse.db
	i := 0
	for i = 0; i < p_list.nExpr; i++ {
		p_old_expr := c2v_at(&p_list.a[0], isize(i)).pExpr
		if (usize(p_old_expr) == usize(0)) {
			continue
		}
		if is_asterisk_term(p_parse, p_old_expr) {
			jj := 0
			for jj = 0; jj < int(p_tab.nCol); jj++ {
				p_new_expr := &Expr(0)
				if ((int((p_tab.aCol + jj).colFlags) & 2) != 0) {
					continue
				}
				p_new_expr = sqlite3_expr(db, 60, p_tab.aCol[jj].zCnName)
				p_new = sqlite3_expr_list_append(p_parse, p_new, p_new_expr)
				if !db.mallocFailed {
					p_item := unsafe { &p_new.a[0] + (p_new.nExpr - 1) }
					p_item.zEName = sqlite3_db_str_dup(db, p_tab.aCol[jj].zCnName)
					p_item.fg.eEName = u32(0)
				}
			}
		} else {
			p_new_expr := sqlite3_expr_dup(db, p_old_expr, 0)
			p_new = sqlite3_expr_list_append(p_parse, p_new, p_new_expr)
			if !db.mallocFailed && (usize(c2v_at(&p_list.a[0], isize(i)).zEName) != usize(0)) {
				p_item := unsafe { &p_new.a[0] + (p_new.nExpr - 1) }
				p_item.zEName = sqlite3_db_str_dup(db, c2v_at(&p_list.a[0], isize(i)).zEName)
				p_item.fg.eEName = c2v_at(&p_list.a[0], isize(i)).fg.eEName
			}
		}
	}
	return p_new
}

@[c:'sqlite3ReturningSubqueryVarSelect']
fn sqlite3_returning_subquery_var_select(not_used &Walker, p_expr &Expr) int {
	c2v_gc_register_thread()

	if ((p_expr.flags & u32(4096)) != u32(0)) && (p_expr.x.pSelect.selFlags & u32(536870912)) != u32(0) {
		p_expr.flags |= u32(64)
	}
	return 0
}

@[c:'sqlite3ReturningSubqueryCorrelated']
fn sqlite3_returning_subquery_correlated(p_walker &Walker, p_select &Select) int {
	c2v_gc_register_thread()
	i := 0
	p_src := &SrcList(0)
	p_src = p_select.pSrc
	for i = 0; i < p_src.nSrc; i++ {
		if usize(c2v_at(&p_src.a[0], isize(i)).pSTab) == usize(p_walker.u.pTab) {
			p_select.selFlags |= u32(536870912)
			p_walker.eCode = U16(1)
			break
		}
	}
	return 0
}

@[c:'sqlite3ProcessReturningSubqueries']
fn sqlite3_process_returning_subqueries(pel_ist &ExprList, p_tab &Table) {
	w := Walker{}
	C.memset(voidptr(&w), 0, sizeof(w))
	w.xExprCallback = sqlite3_expr_walk_noop
	w.xSelectCallback = sqlite3_returning_subquery_correlated
	w.u.pTab = p_tab
	sqlite3_walk_expr_list(&w, pel_ist)
	if w.eCode {
		w.xExprCallback = sqlite3_returning_subquery_var_select
		w.xSelectCallback = sqlite3_select_walk_noop
		sqlite3_walk_expr_list(&w, pel_ist)
	}
}

@[c:'codeReturningTrigger']
fn code_returning_trigger(p_parse &Parse, p_trigger &Trigger, p_tab &Table, reg_in int) {
	v := p_parse.pVdbe
	db := p_parse.db
	p_new := &ExprList(0)
	p_returning := &Returning(0)
	s_select := Select{}
	p_from := &SrcList(0)
	u_src := AnonStruct_159324{}

	if !p_parse.bReturning {
		return
	}
	p_returning = p_parse.u1.d.pReturning
	if usize(p_trigger) != usize(&p_returning.retTrig) {
		return
	}
	C.memset(voidptr(&s_select), 0, sizeof(s_select))
	C.memset(voidptr(&u_src), 0, sizeof(u_src))
	p_from = &u_src.sSrc
	s_select.pEList = sqlite3_expr_list_dup(db, p_returning.pReturnEL, 0)
	s_select.pSrc = p_from
	p_from.nSrc = 1
	mut __c2v_lhs_tmp_151 := c2v_at(&p_from.a[0], isize(0))
	__c2v_lhs_tmp_151.pSTab = p_tab
	mut __c2v_lhs_tmp_152 := c2v_at(&p_from.a[0], isize(0))
	__c2v_lhs_tmp_152.zName = p_tab.zName
	mut __c2v_lhs_tmp_153 := c2v_at(&p_from.a[0], isize(0))
	__c2v_lhs_tmp_153.iCursor = -1
	sqlite3_select_prep(p_parse, &s_select, unsafe { nil })
	if p_parse.nErr == 0 {
		sqlite3_generate_column_names(p_parse, &s_select)
	}
	sqlite3_expr_list_delete(db, s_select.pEList)
	p_new = sqlite3_expand_returning(p_parse, p_returning.pReturnEL, p_tab)
	if p_parse.nErr == 0 {
		snc := NameContext{}
		C.memset(voidptr(&snc), 0, sizeof(snc))
		if p_returning.nRetCol == 0 {
			p_returning.nRetCol = p_new.nExpr
			mut __c2v_postfix_value_34 := p_parse.nTab
			p_parse.nTab++
			p_returning.iRetCur = __c2v_postfix_value_34
		}
		snc.pParse = p_parse
		snc.uNC.iBaseReg = reg_in
		snc.ncFlags = 1024
		p_parse.eTriggerOp = p_trigger.op
		p_parse.pTriggerTab = p_tab
		if sqlite3_resolve_expr_list_names(&snc, p_new) == 0 && (!db.mallocFailed) {
			i := 0
			n_col := p_new.nExpr
			reg := p_parse.nMem + 1
			sqlite3_process_returning_subqueries(p_new, p_tab)
			p_parse.nMem += n_col + 2
			p_returning.iRetReg = reg
			for i = 0; i < n_col; i++ {
				p_col := c2v_at(&p_new.a[0], isize(i)).pExpr
				sqlite3_expr_code_factorable(p_parse, p_col, reg + i)
				if int(sqlite3_expr_affinity(p_col)) == 69 {
					sqlite3_vdbe_add_op1(v, 89, reg + i)
				}
			}
			sqlite3_vdbe_add_op3(v, 99, reg, i, reg + i)
			sqlite3_vdbe_add_op2(v, 129, p_returning.iRetCur, reg + i + 1)
			sqlite3_vdbe_add_op3(v, 130, p_returning.iRetCur, reg + i, reg + i + 1)
		}
	}
	sqlite3_expr_list_delete(db, p_new)
	p_parse.eTriggerOp = U8(0)
	p_parse.pTriggerTab = 0
}

@[c:'codeTriggerProgram']
fn code_trigger_program(p_parse &Parse, p_step_list &TriggerStep, orconf int) int {
	p_step := &TriggerStep(0)
	v := p_parse.pVdbe
	db := p_parse.db
	for p_step = p_step_list; p_step; p_step = p_step.pNext {
		p_parse.eOrconf = U8(if (orconf == 11) { int(p_step.orconf) } else { int(U8(orconf)) })
		if p_step.zSpan {
			sqlite3_vdbe_add_op4(v, 186, 2147483647, 1, 0, sqlite3_mp_rintf(db, c'-- %s', voidptr(p_step.zSpan)), (-7))
		}
		match p_step.op {
			130 {
				sqlite3_update(p_parse, sqlite3_src_list_dup(db, p_step.pSrc, 0), sqlite3_expr_list_dup(db, p_step.pExprList, 0), sqlite3_expr_dup(db, p_step.pWhere, 0), int(p_parse.eOrconf), unsafe { nil }, unsafe { nil }, unsafe { nil })
				sqlite3_vdbe_add_op0(v, 133)
			}
			128 {
				sqlite3_insert(p_parse, sqlite3_src_list_dup(db, p_step.pSrc, 0), sqlite3_select_dup(db, p_step.pSelect, 0), sqlite3_id_list_dup(db, p_step.pIdList), int(p_parse.eOrconf), sqlite3_upsert_dup(db, p_step.pUpsert))
				sqlite3_vdbe_add_op0(v, 133)
			}
			129 {
				sqlite3_delete_from(p_parse, sqlite3_src_list_dup(db, p_step.pSrc, 0), sqlite3_expr_dup(db, p_step.pWhere, 0), unsafe { nil }, unsafe { nil })
				sqlite3_vdbe_add_op0(v, 133)
			}
			else {
				s_dest := SelectDest{}
				p_select := sqlite3_select_dup(db, p_step.pSelect, 0)
				sqlite3_select_dest_init(&s_dest, 2, 0)
				sqlite3_select(p_parse, p_select, &s_dest)
				sqlite3_select_delete(db, p_select)
			}
		}
	}
	return 0
}

@[c:'transferParseError']
fn transfer_parse_error(p_to &Parse, p_from &Parse) {
	if p_to.nErr == 0 {
		p_to.zErrMsg = p_from.zErrMsg
		p_to.nErr = p_from.nErr
		p_to.rc = p_from.rc
	} else {
		sqlite3_db_free(p_from.db, voidptr(p_from.zErrMsg))
	}
}

@[c:'codeRowTrigger']
fn code_row_trigger(p_parse &Parse, p_trigger &Trigger, p_tab &Table, orconf int) &TriggerPrg {
	p_top := &Parse(0)
	db := p_parse.db
	p_prg := &TriggerPrg(0)
	p_when := unsafe { &Expr(nil) }
	v := &Vdbe(0)
	snc := NameContext{}
	p_program := unsafe { &SubProgram(nil) }
	i_end_trigger := 0
	s_sub_parse := Parse{}
	n_depth := 0
	p_top = p_parse
	for n_depth = 0; p_top.pOuterParse;  {
		p_top = p_top.pOuterParse
		n_depth++
	}
	if n_depth >= db.aLimit[10] {
		sqlite3_error_msg(p_parse, c'triggers nested too deep')
		return unsafe { nil }
	}
	p_top = (if p_parse.pToplevel { p_parse.pToplevel } else { p_parse })
	p_prg = sqlite3_db_malloc_zero(db, U64(sizeof(TriggerPrg)))
	if isnil(p_prg) {
		return unsafe { nil }
	}
	p_prg.pNext = p_top.pTriggerPrg
	p_top.pTriggerPrg = p_prg
	p_program = sqlite3_db_malloc_zero(db, U64(sizeof(SubProgram)))
	p_prg.pProgram = p_program
	if isnil(p_program) {
		return unsafe { nil }
	}
	sqlite3_vdbe_link_sub_program(p_top.pVdbe, p_program)
	p_prg.pTrigger = p_trigger
	p_prg.orconf = orconf
	p_prg.aColmask[0] = u32(4294967295)
	p_prg.aColmask[1] = u32(4294967295)
	sqlite3_parse_object_init(&s_sub_parse, db)
	C.memset(voidptr(&snc), 0, sizeof(snc))
	snc.pParse = &s_sub_parse
	s_sub_parse.pTriggerTab = p_tab
	s_sub_parse.pToplevel = p_top
	s_sub_parse.zAuthContext = p_trigger.zName
	s_sub_parse.eTriggerOp = p_trigger.op
	s_sub_parse.nQueryLoop = p_parse.nQueryLoop
	s_sub_parse.prepFlags = p_parse.prepFlags
	s_sub_parse.oldmask = u32(0)
	s_sub_parse.newmask = u32(0)
	v = sqlite3_get_vdbe(&s_sub_parse)
	if v {
		if p_trigger.zName {
			sqlite3_vdbe_change_p4(v, -1, sqlite3_mp_rintf(db, c'-- TRIGGER %s', voidptr(p_trigger.zName)), (-7))
		}
		if p_trigger.pWhen {
			p_when = sqlite3_expr_dup(db, p_trigger.pWhen, 0)
			if int(db.mallocFailed) == 0 && 0 == sqlite3_resolve_expr_names(&snc, p_when) {
				i_end_trigger = sqlite3_vdbe_make_label(&s_sub_parse)
				sqlite3_expr_if_false(&s_sub_parse, p_when, i_end_trigger, 16)
			}
			sqlite3_expr_delete(db, p_when)
		}
		code_trigger_program(&s_sub_parse, p_trigger.step_list, orconf)
		if i_end_trigger {
			sqlite3_vdbe_resolve_label(v, i_end_trigger)
		}
		sqlite3_vdbe_add_op0(v, 72)
		transfer_parse_error(p_parse, &s_sub_parse)
		if p_parse.nErr == 0 {
			p_program.aOp = sqlite3_vdbe_take_op_array(v, &p_program.nOp, &p_top.nMaxArg)
		}
		p_program.nMem = s_sub_parse.nMem
		p_program.nCsr = s_sub_parse.nTab
		p_program.token = voidptr(p_trigger)
		p_prg.aColmask[0] = s_sub_parse.oldmask
		p_prg.aColmask[1] = s_sub_parse.newmask
		sqlite3_vdbe_delete(v)
	} else {
		transfer_parse_error(p_parse, &s_sub_parse)
	}
	sqlite3_parse_object_reset(&s_sub_parse)
	return p_prg
}

@[c:'getRowTrigger']
fn get_row_trigger(p_parse &Parse, p_trigger &Trigger, p_tab &Table, orconf int) &TriggerPrg {
	p_root := (if p_parse.pToplevel { p_parse.pToplevel } else { p_parse })
	p_prg := &TriggerPrg(0)
	for p_prg = p_root.pTriggerPrg; !isnil(p_prg) && (usize(p_prg.pTrigger) != usize(p_trigger) || p_prg.orconf != orconf); p_prg = p_prg.pNext {
	}
	if isnil(p_prg) {
		p_prg = code_row_trigger(p_parse, p_trigger, p_tab, orconf)
		p_parse.db.errByteOffset = -1
	}
	return p_prg
}

@[c:'sqlite3CodeRowTriggerDirect']
fn sqlite3_code_row_trigger_direct(p_parse &Parse, p &Trigger, p_tab &Table, reg int, orconf int, ignore_jump int) {
	v := sqlite3_get_vdbe(p_parse)
	p_prg := &TriggerPrg(0)
	p_prg = get_row_trigger(p_parse, p, p_tab, orconf)
	if p_prg {
		b_recursive := int((!isnil(p.zName) && U64(0) == (p_parse.db.flags & U64(8192))))
		sqlite3_vdbe_add_op4(v, 50, reg, ignore_jump, c2v_prefix_add(unsafe { &p_parse.nMem }, 1), &i8(voidptr(p_prg.pProgram)), (-4))
		sqlite3_vdbe_change_p5(v, U16(b_recursive))
	}
}

@[c:'sqlite3CodeRowTrigger']
fn sqlite3_code_row_trigger(p_parse &Parse, p_trigger &Trigger, op int, p_changes &ExprList, tr_tm int, p_tab &Table, reg int, orconf int, ignore_jump int) {
	p := &Trigger(0)
	for p = p_trigger; p; p = p.pNext {
		if (int(p.op) == op || (int(p.bReturning) && int(p.op) == 128 && op == 130)) && int(p.tr_tm) == tr_tm && check_column_overlap(p.pColumns, p_changes) {
			if !p.bReturning {
				sqlite3_code_row_trigger_direct(p_parse, p, p_tab, reg, orconf, ignore_jump)
			} else if (usize(p_parse.pToplevel) == usize(0)) {
				code_returning_trigger(p_parse, p, p_tab, reg)
			}
		}
	}
}

@[c:'sqlite3TriggerColmask']
fn sqlite3_trigger_colmask(p_parse &Parse, p_trigger &Trigger, p_changes &ExprList, is_new int, tr_tm int, p_tab &Table, orconf int) u32 {
	op := if p_changes { 130 } else { 129 }
	mask := u32(0)
	p := &Trigger(0)
	if (int(p_tab.eTabType) == 2) {
		return u32(4294967295)
	}
	for p = p_trigger; p; p = p.pNext {
		if int(p.op) == op && (tr_tm & int(p.tr_tm)) && check_column_overlap(p.pColumns, p_changes) {
			if p.bReturning {
				mask = u32(4294967295)
			} else {
				p_prg := &TriggerPrg(0)
				p_prg = get_row_trigger(p_parse, p, p_tab, orconf)
				if p_prg {
					mask |= p_prg.aColmask[is_new]
				}
			}
		}
	}
	return mask
}
