@[translated]
module main

type Sqlite3StatValueType = i64

struct Sqlite3StatType {
	nowValue [10]Sqlite3StatValueType
	mxValue  [10]Sqlite3StatValueType
}

@[c:'sqlite3StatusValue']
fn sqlite3_status_value(op int) Sqlite3_int64 {
	return sqlite3Stat.nowValue[op]
}

@[c:'sqlite3StatusUp']
fn sqlite3_status_up(op int, n int) {
	sqlite3Stat.nowValue[op] += Sqlite3StatValueType(n)
	if sqlite3Stat.nowValue[op] > sqlite3Stat.mxValue[op] {
		sqlite3Stat.mxValue[op] = sqlite3Stat.nowValue[op]
	}
}

@[c:'sqlite3StatusDown']
fn sqlite3_status_down(op int, n int) {
	sqlite3Stat.nowValue[op] -= Sqlite3StatValueType(n)
}

@[c:'sqlite3StatusHighwater']
fn sqlite3_status_highwater(op int, x int) {
	new_value := Sqlite3StatValueType(0)
	new_value = Sqlite3StatValueType(x)
	if new_value > sqlite3Stat.mxValue[op] {
		sqlite3Stat.mxValue[op] = new_value
	}
}

fn sqlite3_status64(op int, p_current &Sqlite3_int64, p_highwater &Sqlite3_int64, reset_flag int) int {
	c2v_gc_register_thread()
	p_mutex := &Sqlite3_mutex(0)
	if op < 0 || op >= 10 {
		return sqlite3_misuse_error(143)
	}
	p_mutex = if int(stat_mutex[op]) { sqlite3_pcache1_mutex() } else { sqlite3_malloc_mutex() }
	sqlite3_mutex_enter(p_mutex)
	unsafe { *p_current = sqlite3Stat.nowValue[op] }
	unsafe { *p_highwater = sqlite3Stat.mxValue[op] }
	if reset_flag {
		sqlite3Stat.mxValue[op] = sqlite3Stat.nowValue[op]
	}
	sqlite3_mutex_leave(p_mutex)

	return 0
}

fn sqlite3_status(op int, p_current &int, p_highwater &int, reset_flag int) int {
	c2v_gc_register_thread()
	i_cur := Sqlite3_int64(0)
	i_hwtr := Sqlite3_int64(0)

	rc := 0
	rc = sqlite3_status64(op, &i_cur, &i_hwtr, reset_flag)
	if rc == 0 {
		unsafe { *p_current = int(i_cur) }
		unsafe { *p_highwater = int(i_hwtr) }
	}
	return rc
}

@[c:'countLookasideSlots']
fn count_lookaside_slots(p &LookasideSlot) u32 {
	cnt := u32(0)
	for p {
		p = p.pNext
		cnt++
	}
	return cnt
}

@[c:'sqlite3LookasideUsed']
fn sqlite3_lookaside_used(db &Sqlite3, p_highwater &int) int {
	n_init := count_lookaside_slots(db.lookaside.pInit)
	n_free := count_lookaside_slots(db.lookaside.pFree)
	n_init += count_lookaside_slots(db.lookaside.pSmallInit)
	n_free += count_lookaside_slots(db.lookaside.pSmallFree)
	if p_highwater {
		unsafe { *p_highwater = int((db.lookaside.nSlot - n_init)) }
	}
	return int((db.lookaside.nSlot - (n_init + n_free)))
}

fn sqlite3_db_status64(db &Sqlite3, op int, p_current &Sqlite3_int64, p_highwtr &Sqlite3_int64, reset_flag int) int {
	c2v_gc_register_thread()
	rc := 0
	sqlite3_mutex_enter(db.mutex)
	match op {
		0 {
			h := 0
			unsafe { *p_current = Sqlite3_int64(sqlite3_lookaside_used(db, &h)) }
			unsafe { *p_highwtr = Sqlite3_int64(h) }
			if reset_flag {
				p := db.lookaside.pFree
				if p {
					for p.pNext {
						p = p.pNext
					}
					p.pNext = db.lookaside.pInit
					db.lookaside.pInit = db.lookaside.pFree
					db.lookaside.pFree = 0
				}
				p = db.lookaside.pSmallFree
				if p {
					for p.pNext {
						p = p.pNext
					}
					p.pNext = db.lookaside.pSmallInit
					db.lookaside.pSmallInit = db.lookaside.pSmallFree
					db.lookaside.pSmallFree = 0
				}
			}
		}
		4, 5, 6 {
			unsafe { *p_current = Sqlite3_int64(0) }
			unsafe { *p_highwtr = Sqlite3_int64(db.lookaside.anStat[op - 4]) }
			if reset_flag {
				db.lookaside.anStat[op - 4] = u32(0)
			}
		}
		11, 1 {
			total_used := Sqlite3_int64(0)
			i := 0
			sqlite3_btree_enter_all(db)
			for i = 0; i < db.nDb; i++ {
				p_bt := db.aDb[i].pBt
				if p_bt {
					p_pager := sqlite3_btree_pager(p_bt)
					n_byte := sqlite3_pager_mem_used(p_pager)
					if op == 11 {
						n_byte = n_byte / sqlite3_btree_connection_count(p_bt)
					}
					total_used += Sqlite3_int64(n_byte)
				}
			}
			sqlite3_btree_leave_all(db)
			unsafe { *p_current = total_used }
			unsafe { *p_highwtr = Sqlite3_int64(0) }
		}
		2 {
			i_2 := 0
			n_byte := 0
			sqlite3_btree_enter_all(db)
			db.pnBytesFreed = &n_byte
			db.lookaside.pEnd = db.lookaside.pStart
			for i_2 = 0; i_2 < db.nDb; i_2++ {
				p_schema := db.aDb[i_2].pSchema
				if (usize(p_schema) != usize(0)) {
					p := &HashElem(0)
					n_byte += u32(sqlite3Config.m.xRoundup(int(sizeof(HashElem)))) * (p_schema.tblHash.count + p_schema.trigHash.count + p_schema.idxHash.count + p_schema.fkeyHash.count)
					n_byte += sqlite3_msize(voidptr(p_schema.tblHash.ht))
					n_byte += sqlite3_msize(voidptr(p_schema.trigHash.ht))
					n_byte += sqlite3_msize(voidptr(p_schema.idxHash.ht))
					n_byte += sqlite3_msize(voidptr(p_schema.fkeyHash.ht))
					for p = p_schema.trigHash.first; p; p = p.next {
						sqlite3_delete_trigger(db, &Trigger(p.data))
					}
					for p = p_schema.tblHash.first; p; p = p.next {
						sqlite3_delete_table(db, &Table(p.data))
					}
				}
			}
			db.pnBytesFreed = 0
			db.lookaside.pEnd = db.lookaside.pTrueEnd
			sqlite3_btree_leave_all(db)
			unsafe { *p_highwtr = Sqlite3_int64(0) }
			unsafe { *p_current = Sqlite3_int64(n_byte) }
		}
		3 {
			p_vdbe := &Vdbe(0)
			n_byte := 0
			db.pnBytesFreed = &n_byte
			db.lookaside.pEnd = db.lookaside.pStart
			for p_vdbe = db.pVdbe; p_vdbe; p_vdbe = p_vdbe.pVNext {
				sqlite3_vdbe_delete(p_vdbe)
			}
			db.lookaside.pEnd = db.lookaside.pTrueEnd
			db.pnBytesFreed = 0
			unsafe { *p_highwtr = Sqlite3_int64(0) }
			unsafe { *p_current = Sqlite3_int64(n_byte) }
		}
		12 {
			op = 9 + 1

			unsafe { goto c2v_case_0_7
			 }
		}
		7, 8, 9 {
			c2v_case_0_7:
			i_2 := 0
			n_ret := U64(0)
			for i_2 = 0; i_2 < db.nDb; i_2++ {
				if db.aDb[i_2].pBt {
					p_pager := sqlite3_btree_pager(db.aDb[i_2].pBt)
					sqlite3_pager_cache_stat(p_pager, op, reset_flag, &n_ret)
				}
			}
			unsafe { *p_highwtr = Sqlite3_int64(0) }
			unsafe { *p_current = Sqlite3_int64(n_ret) }
		}
		13 {
			n_ret_2 := U64(0)
			if db.aDb[1].pBt {
				p_pager := sqlite3_btree_pager(db.aDb[1].pBt)
				sqlite3_pager_cache_stat(p_pager, 9, reset_flag, &n_ret_2)
				n_ret_2 *= U64(sqlite3_btree_get_page_size(db.aDb[1].pBt))
			}
			n_ret_2 += db.nSpill
			if reset_flag {
				db.nSpill = U64(0)
			}
			unsafe { *p_highwtr = Sqlite3_int64(0) }
			unsafe { *p_current = Sqlite3_int64(n_ret_2) }
		}
		10 {
			unsafe { *p_highwtr = Sqlite3_int64(0) }
			unsafe { *p_current = Sqlite3_int64(db.nDeferredImmCons > I64(0) || db.nDeferredCons > I64(0)) }
		}
		else {
			rc = 1
		}
	}

	sqlite3_mutex_leave(db.mutex)
	return rc
}

fn sqlite3_db_status(db &Sqlite3, op int, p_current &int, p_highwtr &int, reset_flag int) int {
	c2v_gc_register_thread()
	c := Sqlite3_int64(0)
	h := Sqlite3_int64(0)

	rc := 0
	rc = sqlite3_db_status64(db, op, &c, &h, reset_flag)
	if rc == 0 {
		unsafe { *p_current = int(c & Sqlite3_int64(2147483647)) }
		unsafe { *p_highwtr = int(h & Sqlite3_int64(2147483647)) }
	}
	return rc
}
