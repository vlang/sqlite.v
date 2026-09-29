@[translated]
module main

@[c:'sqlite3TestExtInit']
fn sqlite3_test_ext_init(db &Sqlite3) int {
	c2v_gc_register_thread()

	return sqlite3_fault_sim(500)
}

fn sqlite3_libversion() &i8 {
	c2v_gc_register_thread()
	return unsafe { &i8(&sqlite3_version[0]) }
}

fn sqlite3_libversion_number() int {
	c2v_gc_register_thread()
	return 3053004
}

fn sqlite3_threadsafe() int {
	c2v_gc_register_thread()
	return 1
}

fn sqlite3_initialize() int {
	p_main_mtx := &Sqlite3_mutex(0)
	rc := 0
	if sqlite3Config.isInit {
		sqlite3_memory_barrier()
		return 0
	}
	rc = sqlite3_mutex_init()
	if rc {
		return rc
	}
	p_main_mtx = sqlite3_mutex_alloc_vdup4(2)
	sqlite3_mutex_enter(p_main_mtx)
	sqlite3Config.isMutexInit = 1
	if !sqlite3Config.isMallocInit {
		rc = sqlite3_malloc_init()
	}
	if rc == 0 {
		sqlite3Config.isMallocInit = 1
		if isnil(sqlite3Config.pInitMutex) {
			sqlite3Config.pInitMutex = sqlite3_mutex_alloc_vdup4(1)
			if int(sqlite3Config.bCoreMutex) && isnil(sqlite3Config.pInitMutex) {
				rc = 7
			}
		}
	}
	if rc == 0 {
		sqlite3Config.nRefInitMutex++
	}
	sqlite3_mutex_leave(p_main_mtx)
	if rc != 0 {
		return rc
	}
	sqlite3_mutex_enter(sqlite3Config.pInitMutex)
	if sqlite3Config.isInit == 0 && sqlite3Config.inProgress == 0 {
		sqlite3Config.inProgress = 1
		C.memset(voidptr(&sqlite3BuiltinFunctions), 0, sizeof(sqlite3BuiltinFunctions))
		sqlite3_register_builtin_functions()
		if sqlite3Config.isPCacheInit == 0 {
			rc = sqlite3_pcache_initialize()
		}
		if rc == 0 {
			sqlite3Config.isPCacheInit = 1
			rc = sqlite3_os_init_vdup0()
		}
		if rc == 0 {
			rc = sqlite3_memdb_init()
		}
		if rc == 0 {
			sqlite3_pc_ache_buffer_setup(voidptr(sqlite3Config.pPage), sqlite3Config.szPage, sqlite3Config.nPage)
		}
		if rc == 0 {
			sqlite3_memory_barrier()
			sqlite3Config.isInit = 1
		}
		sqlite3Config.inProgress = 0
	}
	sqlite3_mutex_leave(sqlite3Config.pInitMutex)
	sqlite3_mutex_enter(p_main_mtx)
	sqlite3Config.nRefInitMutex--
	if sqlite3Config.nRefInitMutex <= 0 {
		sqlite3_mutex_free(sqlite3Config.pInitMutex)
		sqlite3Config.pInitMutex = 0
	}
	sqlite3_mutex_leave(p_main_mtx)
	return rc
}

fn sqlite3_shutdown() int {
	if sqlite3Config.isInit {
		sqlite3_os_end()
		sqlite3_reset_auto_extension()
		sqlite3Config.isInit = 0
	}
	if sqlite3Config.isPCacheInit {
		sqlite3_pcache_shutdown()
		sqlite3Config.isPCacheInit = 0
	}
	if sqlite3Config.isMallocInit {
		sqlite3_malloc_end()
		sqlite3Config.isMallocInit = 0
		sqlite3_data_directory = 0
		sqlite3_temp_directory = 0
	}
	if sqlite3Config.isMutexInit {
		sqlite3_mutex_end()
		sqlite3Config.isMutexInit = 0
	}
	return 0
}

@[c:'sqlite3_config']
@[c2v_variadic]
fn sqlite3_config_fn(op int, ...) int {
	ap := C.va_list{}
	rc := 0
	if sqlite3Config.isInit {
		static m_anytime_config_option := U64(0) | ((U64(1)) << 16) | ((U64(1)) << 24)
		if op < 0 || op > 63 || (((U64(1)) << op) & m_anytime_config_option) == U64(0) {
			return sqlite3_misuse_error(540)
		}
	}
	C.va_start(ap, op)
	match op {
		1 {
			sqlite3Config.bCoreMutex = U8(0)
			sqlite3Config.bFullMutex = U8(0)
		}
		2 {
			sqlite3Config.bCoreMutex = U8(1)
			sqlite3Config.bFullMutex = U8(0)
		}
		3 {
			sqlite3Config.bCoreMutex = U8(1)
			sqlite3Config.bFullMutex = U8(1)
		}
		10 {
			sqlite3Config.mutex = unsafe { *C.va_arg(&Sqlite3_mutex_methods, ap) }
		}
		11 {
			mut __c2v_lhs_tmp_178 := unsafe { C.va_arg(&Sqlite3_mutex_methods, ap) }
			unsafe { *__c2v_lhs_tmp_178 = sqlite3Config.mutex }
		}
		4 {
			sqlite3Config.m = unsafe { *C.va_arg(&Sqlite3_mem_methods, ap) }
		}
		5 {
			if isnil(sqlite3Config.m.xMalloc) {
				sqlite3_mem_set_default()
			}
			mut __c2v_lhs_tmp_179 := unsafe { C.va_arg(&Sqlite3_mem_methods, ap) }
			unsafe { *__c2v_lhs_tmp_179 = sqlite3Config.m }
		}
		9 {
			sqlite3Config.bMemstat = C.va_arg(int, ap)
		}
		27 {
			sqlite3Config.bSmallMalloc = U8(C.va_arg(int, ap))
		}
		7 {
			sqlite3Config.pPage = C.va_arg(voidptr, ap)
			sqlite3Config.szPage = C.va_arg(int, ap)
			sqlite3Config.nPage = C.va_arg(int, ap)
		}
		24 {
			mut __c2v_lhs_tmp_180 := unsafe { C.va_arg(&int, ap) }
			unsafe { *__c2v_lhs_tmp_180 = sqlite3_header_size_btree() + sqlite3_header_size_pcache() + sqlite3_header_size_pcache1() }
		}
		14 {
		}
		15 {
			rc = 1
		}
		18 {
			sqlite3Config.pcache2 = unsafe { *C.va_arg(&Sqlite3_pcache_methods2, ap) }
		}
		19 {
			if isnil(sqlite3Config.pcache2.xInit) {
				sqlite3_pc_ache_set_default()
			}
			mut __c2v_lhs_tmp_181 := unsafe { C.va_arg(&Sqlite3_pcache_methods2, ap) }
			unsafe { *__c2v_lhs_tmp_181 = sqlite3Config.pcache2 }
		}
		13 {
			sqlite3Config.szLookaside = C.va_arg(int, ap)
			sqlite3Config.nLookaside = C.va_arg(int, ap)
		}
		16 {
			x_log := C.va_arg(LOGFUNC_t, ap)
			p_log_arg := C.va_arg(voidptr, ap)
			C.c2v_atomic_store_n__voidptr_LOGFUNC_t_int_((&sqlite3Config.xLog), x_log, 0)
			C.c2v_atomic_store_n__voidptr_voidptr_int_((&sqlite3Config.pLogArg), p_log_arg, 0)
		}
		17 {
			b_open_uri := C.va_arg(int, ap)
			C.c2v_atomic_store_n__U8_U8_int_((&sqlite3Config.bOpenUri), U8(b_open_uri), 0)
		}
		20 {
			sqlite3Config.bUseCis = U8(C.va_arg(int, ap))
		}
		22 {
			sz_mmap := C.va_arg(Sqlite3_int64, ap)
			mx_mmap := C.va_arg(Sqlite3_int64, ap)
			if mx_mmap < Sqlite3_int64(0) || mx_mmap > Sqlite3_int64(2147418112) {
				mx_mmap = Sqlite3_int64(2147418112)
			}
			if sz_mmap < Sqlite3_int64(0) {
				sz_mmap = Sqlite3_int64(0)
			}
			if sz_mmap > mx_mmap {
				sz_mmap = mx_mmap
			}
			sqlite3Config.mxMmap = mx_mmap
			sqlite3Config.szMmap = sz_mmap
		}
		25 {
			sqlite3Config.szPma = C.va_arg(u32, ap)
		}
		26 {
			sqlite3Config.nStmtSpill = C.va_arg(int, ap)
		}
		29 {
			sqlite3Config.mxMemdbSize = C.va_arg(Sqlite3_int64, ap)
		}
		30 {
			p_val := C.va_arg(&int, ap)
			unsafe { *p_val = 0 }
		}
		else {
			rc = 1
		}
	}

	C.va_end(ap)
	return rc
}

@[c:'setupLookaside']
fn setup_lookaside(db &Sqlite3, p_buf voidptr, sz int, cnt int) int {
	p_start := &voidptr(0)
	sz_alloc := Sqlite3_int64(0)
	n_big := 0
	n_sm := 0
	if sqlite3_lookaside_used(db, unsafe { nil }) > 0 {
		return 5
	}
	if db.lookaside.bMalloced {
		sqlite3_free(voidptr(db.lookaside.pStart))
	}
	sz = (sz & ~7)
	if sz <= int(sizeof(voidptr)) {
		sz = 0
	}
	if sz > 65528 {
		sz = 65528
	}
	if cnt < 1 {
		cnt = 0
	}
	if sz > 0 && cnt > (2147418112 / sz) {
		cnt = 2147418112 / sz
	}
	sz_alloc = I64(sz) * I64(cnt)
	if sz_alloc == Sqlite3_int64(0) {
		sz = 0
		p_start = 0
	} else if usize(p_buf) == usize(0) {
		sqlite3_begin_benign_malloc()
		p_start = sqlite3_malloc_vdup2(U64(sz_alloc))
		sqlite3_end_benign_malloc()
		if p_start {
			sz_alloc = Sqlite3_int64(sqlite3_malloc_size(voidptr(p_start)))
		}
	} else {
		p_start = p_buf
	}
	if sz >= 128 * 3 {
		n_big = int(sz_alloc / Sqlite3_int64((3 * 128 + sz)))
		n_sm = int((sz_alloc - I64(sz) * I64(n_big)) / Sqlite_int64(128))
	} else if sz >= 128 * 2 {
		n_big = int(sz_alloc / Sqlite3_int64((128 + sz)))
		n_sm = int((sz_alloc - I64(sz) * I64(n_big)) / Sqlite_int64(128))
	} else if sz > 0 {
		n_big = int(sz_alloc / Sqlite3_int64(sz))
		n_sm = 0
	} else {
		n_sm = 0
		n_big = n_sm
	}
	db.lookaside.pStart = p_start
	db.lookaside.pInit = 0
	db.lookaside.pFree = 0
	db.lookaside.sz = U16(sz)
	db.lookaside.szTrue = U16(sz)
	if p_start {
		i := 0
		p := &LookasideSlot(0)
		p = &LookasideSlot(p_start)
		for i = 0; i < n_big; i++ {
			p.pNext = db.lookaside.pInit
			db.lookaside.pInit = p
			p = &LookasideSlot(voidptr(unsafe { (&U8(voidptr(p))) + sz }))
		}
		db.lookaside.pSmallInit = 0
		db.lookaside.pSmallFree = 0
		db.lookaside.pMiddle = p
		for i = 0; i < n_sm; i++ {
			p.pNext = db.lookaside.pSmallInit
			db.lookaside.pSmallInit = p
			p = &LookasideSlot(voidptr(unsafe { (&U8(voidptr(p))) + 128 }))
		}
		db.lookaside.pEnd = p
		db.lookaside.bDisable = u32(0)
		db.lookaside.bMalloced = U8(if usize(p_buf) == usize(0) { 1 } else { 0 })
		db.lookaside.nSlot = u32(n_big + n_sm)
	} else {
		db.lookaside.pStart = 0
		db.lookaside.pSmallInit = 0
		db.lookaside.pSmallFree = 0
		db.lookaside.pMiddle = 0
		db.lookaside.pEnd = 0
		db.lookaside.bDisable = u32(1)
		db.lookaside.sz = U16(0)
		db.lookaside.bMalloced = U8(0)
		db.lookaside.nSlot = u32(0)
	}
	db.lookaside.pTrueEnd = db.lookaside.pEnd
	return 0
}

fn sqlite3_db_mutex(db &Sqlite3) &Sqlite3_mutex {
	c2v_gc_register_thread()
	return db.mutex
}

fn sqlite3_db_release_memory(db &Sqlite3) int {
	c2v_gc_register_thread()
	i := 0
	sqlite3_mutex_enter(db.mutex)
	sqlite3_btree_enter_all(db)
	for i = 0; i < db.nDb; i++ {
		p_bt := db.aDb[i].pBt
		if p_bt {
			p_pager := sqlite3_btree_pager(p_bt)
			sqlite3_pager_shrink(p_pager)
		}
	}
	sqlite3_btree_leave_all(db)
	sqlite3_mutex_leave(db.mutex)
	return 0
}

fn sqlite3_db_cacheflush(db &Sqlite3) int {
	c2v_gc_register_thread()
	i := 0
	rc := 0
	b_seen_busy := 0
	sqlite3_mutex_enter(db.mutex)
	sqlite3_btree_enter_all(db)
	for i = 0; rc == 0 && i < db.nDb; i++ {
		p_bt := db.aDb[i].pBt
		if !isnil(p_bt) && sqlite3_btree_txn_state(p_bt) == 2 {
			p_pager := sqlite3_btree_pager(p_bt)
			rc = sqlite3_pager_flush(p_pager)
			if rc == 5 {
				b_seen_busy = 1
				rc = 0
			}
		}
	}
	sqlite3_btree_leave_all(db)
	sqlite3_mutex_leave(db.mutex)
	return if (rc == 0 && b_seen_busy) { 5 } else { rc }
}

@[c2v_variadic]
fn sqlite3_db_config(db &Sqlite3, op int, ...) int {
	c2v_gc_register_thread()
	ap := C.va_list{}
	rc := 0
	sqlite3_mutex_enter(db.mutex)
	C.va_start(ap, op)
	match op {
		1000 {
			db.aDb[0].zDbSName = C.va_arg(&i8, ap)
			rc = 0
		}
		1001 {
			p_buf := C.va_arg(voidptr, ap)
			sz := C.va_arg(int, ap)
			cnt := C.va_arg(int, ap)
			rc = setup_lookaside(db, voidptr(p_buf), sz, cnt)
		}
		1023 {
			n_in := C.va_arg(int, ap)
			p_out := C.va_arg(&int, ap)
			if n_in > 3 && n_in < 24 {
				db.nFpDigit = U8(n_in)
			}
			if p_out {
				unsafe { *p_out = int(db.nFpDigit) }
			}
			rc = 0
		}
		else {
			if !sqlite3_db_config_a_flag_op_inited {
				c2v_static_init := [AnonStruct_189077{
					op: 1002
					mask: U64(16384)
				}, AnonStruct_189077{
					op: 1003
					mask: U64(262144)
				}, AnonStruct_189077{
					op: 1015
					mask: U64(u32(2147483648))
				}, AnonStruct_189077{
					op: 1004
					mask: U64(4194304)
				}, AnonStruct_189077{
					op: 1005
					mask: U64(65536)
				}, AnonStruct_189077{
					op: 1006
					mask: U64(2048)
				}, AnonStruct_189077{
					op: 1007
					mask: U64(8388608)
				}, AnonStruct_189077{
					op: 1008
					mask: U64(16777216)
				}, AnonStruct_189077{
					op: 1009
					mask: U64(33554432)
				}, AnonStruct_189077{
					op: 1010
					mask: U64(268435456)
				}, AnonStruct_189077{
					op: 1011
					mask: U64(1 | 134217728)
				}, AnonStruct_189077{
					op: 1012
					mask: U64(67108864)
				}, AnonStruct_189077{
					op: 1014
					mask: U64(536870912)
				}, AnonStruct_189077{
					op: 1013
					mask: U64(1073741824)
				}, AnonStruct_189077{
					op: 1016
					mask: U64(2)
				}, AnonStruct_189077{
					op: 1017
					mask: U64(128)
				}, AnonStruct_189077{
					op: 1018
					mask: U64(1024)
				}, AnonStruct_189077{
					op: 1019
					mask: U64(4096)
				}, AnonStruct_189077{
					op: 1020
					mask: 68719476736
				}, AnonStruct_189077{
					op: 1021
					mask: 137438953472
				}, AnonStruct_189077{
					op: 1022
					mask: 274877906944
				}]
				for c2v_i_0, c2v_element_0 in c2v_static_init {
					sqlite3_db_config_a_flag_op[c2v_i_0] = c2v_element_0
				}
				sqlite3_db_config_a_flag_op_inited = true
			}

			i := u32(0)
			rc = 1
			for i = u32(0); i < 21; i++ {
				if sqlite3_db_config_a_flag_op[i].op == op {
					onoff := C.va_arg(int, ap)
					p_res := C.va_arg(&int, ap)
					old_flags := db.flags
					if onoff > 0 {
						db.flags |= sqlite3_db_config_a_flag_op[i].mask
					} else if onoff == 0 {
						db.flags &= ~U64(sqlite3_db_config_a_flag_op[i].mask)
					}
					if old_flags != db.flags {
						sqlite3_expire_prepared_statements(db, 0)
					}
					if p_res {
						unsafe { *p_res = (db.flags & sqlite3_db_config_a_flag_op[i].mask) != U64(0) }
					}
					rc = 0
					break
				}
			}
		}
	}

	C.va_end(ap)
	sqlite3_mutex_leave(db.mutex)
	return rc
}

@[c:'binCollFunc']
fn bin_coll_func(not_used voidptr, n_key1 int, p_key1 voidptr, n_key2 int, p_key2 voidptr) int {
	c2v_gc_register_thread()
	rc := 0
	n := 0

	n = if n_key1 < n_key2 { n_key1 } else { n_key2 }
	rc = C.memcmp(voidptr(p_key1), voidptr(p_key2), u64(n))
	if rc == 0 {
		rc = n_key1 - n_key2
	}
	return rc
}

@[c:'rtrimCollFunc']
fn rtrim_coll_func(p_user voidptr, n_key1 int, p_key1 voidptr, n_key2 int, p_key2 voidptr) int {
	c2v_gc_register_thread()
	p_k1 := &U8(p_key1)
	p_k2 := &U8(p_key2)
	for n_key1 && int(p_k1[n_key1 - 1]) == ` ` {
		n_key1--
	}
	for n_key2 && int(p_k2[n_key2 - 1]) == ` ` {
		n_key2--
	}
	return bin_coll_func(voidptr(p_user), n_key1, voidptr(p_key1), n_key2, voidptr(p_key2))
}

@[c:'sqlite3IsBinary']
fn sqlite3_is_binary(p &CollSeq) int {
	return int(usize(p) == usize(0) || p.xCmp == bin_coll_func)
}

@[c:'nocaseCollatingFunc']
fn nocase_collating_func(not_used voidptr, n_key1 int, p_key1 voidptr, n_key2 int, p_key2 voidptr) int {
	c2v_gc_register_thread()
	r := sqlite3_strnicmp(&i8(p_key1), &i8(p_key2), if (n_key1 < n_key2) { n_key1 } else { n_key2 })

	if 0 == r {
		r = n_key1 - n_key2
	}
	return r
}

fn sqlite3_last_insert_rowid(db &Sqlite3) Sqlite3_int64 {
	c2v_gc_register_thread()
	i_ret := I64(0)
	sqlite3_mutex_enter(db.mutex)
	i_ret = db.lastRowid
	sqlite3_mutex_leave(db.mutex)
	return i_ret
}

fn sqlite3_set_last_insert_rowid(db &Sqlite3, i_rowid Sqlite3_int64) {
	c2v_gc_register_thread()
	sqlite3_mutex_enter(db.mutex)
	db.lastRowid = i_rowid
	sqlite3_mutex_leave(db.mutex)
}

fn sqlite3_changes64(db &Sqlite3) Sqlite3_int64 {
	c2v_gc_register_thread()
	i_ret := I64(0)
	sqlite3_mutex_enter(db.mutex)
	i_ret = db.nChange
	sqlite3_mutex_leave(db.mutex)
	return i_ret
}

fn sqlite3_changes(db &Sqlite3) int {
	c2v_gc_register_thread()
	return int(sqlite3_changes64(db))
}

fn sqlite3_total_changes64(db &Sqlite3) Sqlite3_int64 {
	c2v_gc_register_thread()
	i_ret := I64(0)
	sqlite3_mutex_enter(db.mutex)
	i_ret = db.nTotalChange
	sqlite3_mutex_leave(db.mutex)
	return i_ret
}

fn sqlite3_total_changes(db &Sqlite3) int {
	c2v_gc_register_thread()
	return int(sqlite3_total_changes64(db))
}

@[c:'sqlite3CloseSavepoints']
fn sqlite3_close_savepoints(db &Sqlite3) {
	for db.pSavepoint {
		p_tmp := db.pSavepoint
		db.pSavepoint = p_tmp.pNext
		sqlite3_db_free(db, voidptr(p_tmp))
	}
	db.nSavepoint = 0
	db.nStatement = 0
	db.isTransactionSavepoint = U8(0)
}

@[c:'functionDestroy']
fn function_destroy(db &Sqlite3, p &FuncDef) {
	p_destructor := &FuncDestructor(0)
	p_destructor = p.u.pDestructor
	if p_destructor {
		p_destructor.nRef--
		if p_destructor.nRef == 0 {
			p_destructor.xDestroy(voidptr(p_destructor.pUserData))
			sqlite3_db_free(db, voidptr(p_destructor))
		}
	}
}

@[c:'disconnectAllVtab']
fn disconnect_all_vtab(db &Sqlite3) {
	i := 0
	p := &HashElem(0)
	sqlite3_btree_enter_all(db)
	for i = 0; i < db.nDb; i++ {
		p_schema := db.aDb[i].pSchema
		if p_schema {
			for p = p_schema.tblHash.first; p; p = p.next {
				p_tab := &Table(p.data)
				if (int(p_tab.eTabType) == 1) {
					sqlite3_vtab_disconnect(db, p_tab)
				}
			}
		}
	}
	for p = db.aModule.first; p; p = p.next {
		p_mod := &Module(p.data)
		if p_mod.pEpoTab {
			sqlite3_vtab_disconnect(db, p_mod.pEpoTab)
		}
	}
	sqlite3_vtab_unlock_list(db)
	sqlite3_btree_leave_all(db)
}

@[c:'connectionIsBusy']
fn connection_is_busy(db &Sqlite3) int {
	j := 0
	if db.pVdbe {
		return 1
	}
	for j = 0; j < db.nDb; j++ {
		p_bt := db.aDb[j].pBt
		if !isnil(p_bt) && sqlite3_btree_is_in_backup(p_bt) {
			return 1
		}
	}
	return 0
}

@[c:'sqlite3Close']
fn sqlite3_close_vdup14(db &Sqlite3, force_zombie int) int {
	if isnil(db) {
		return 0
	}
	if !sqlite3_safety_check_sick_or_ok(db) {
		return sqlite3_misuse_error(1373)
	}
	sqlite3_mutex_enter(db.mutex)
	if int(db.mTrace) & 8 {
		db.trace.xV2(u32(8), voidptr(db.pTraceArg), voidptr(db), unsafe { nil })
	}
	disconnect_all_vtab(db)
	sqlite3_vtab_rollback(db)
	if !force_zombie && connection_is_busy(db) {
		sqlite3_error_with_msg(db, 5, c'unable to close due to unfinalized statements or unfinished backups')
		sqlite3_mutex_leave(db.mutex)
		return 5
	}
	for db.pDbData {
		p := db.pDbData
		db.pDbData = p.pNext
		if p.xDestructor {
			p.xDestructor(voidptr(p.pData))
		}
		sqlite3_free(voidptr(p))
	}
	db.eOpenState = U8(167)
	sqlite3_leave_mutex_and_close_zombie(db)
	return 0
}

fn sqlite3_txn_state(db &Sqlite3, z_schema &i8) int {
	c2v_gc_register_thread()
	i_db := 0
	n_db := 0

	i_txn := -1
	sqlite3_mutex_enter(db.mutex)
	if z_schema {
		i_db = sqlite3_find_db_name(db, z_schema)
		n_db = i_db
		if i_db < 0 {
			n_db--
		}
	} else {
		i_db = 0
		n_db = db.nDb - 1
	}
	for ; i_db <= n_db; i_db++ {
		p_bt := db.aDb[i_db].pBt
		x := if usize(p_bt) != usize(0) { sqlite3_btree_txn_state(p_bt) } else { 0 }
		if x > i_txn {
			i_txn = x
		}
	}
	sqlite3_mutex_leave(db.mutex)
	return i_txn
}

fn sqlite3_close(db &Sqlite3) int {
	c2v_gc_register_thread()
	return sqlite3_close_vdup14(db, 0)
}

fn sqlite3_close_v2(db &Sqlite3) int {
	c2v_gc_register_thread()
	return sqlite3_close_vdup14(db, 1)
}

@[c:'sqlite3LeaveMutexAndCloseZombie']
fn sqlite3_leave_mutex_and_close_zombie(db &Sqlite3) {
	i := &HashElem(0)
	j := 0
	if int(db.eOpenState) != 167 || connection_is_busy(db) {
		sqlite3_mutex_leave(db.mutex)
		return
	}
	sqlite3_rollback_all(db, 0)
	sqlite3_close_savepoints(db)
	for j = 0; j < db.nDb; j++ {
		p_db := unsafe { db.aDb + j }
		if p_db.pBt {
			sqlite3_btree_close(p_db.pBt)
			p_db.pBt = 0
			if j != 1 {
				p_db.pSchema = 0
			}
		}
	}
	if db.aDb[1].pSchema {
		sqlite3_schema_clear(voidptr(db.aDb[1].pSchema))
	}
	sqlite3_vtab_unlock_list(db)
	sqlite3_collapse_database_array(db)
	for i = db.aFunc.first; i; i = i.next {
		p_next := &FuncDef(0)
		p := &FuncDef(0)

		p = i.data
		for {
			function_destroy(db, p)
			p_next = p.pNext
			sqlite3_db_free(db, voidptr(p))
			p = p_next
			if !p {
				break
			}
		}
	}
	sqlite3_hash_clear(&db.aFunc)
	for i = db.aCollSeq.first; i; i = i.next {
		p_coll := &CollSeq(i.data)
		for j = 0; j < 3; j++ {
			if p_coll[j].xDel {
				p_coll[j].xDel(voidptr(p_coll[j].pUser))
			}
		}
		sqlite3_db_free(db, voidptr(p_coll))
	}
	sqlite3_hash_clear(&db.aCollSeq)
	for i = db.aModule.first; i; i = i.next {
		p_mod := &Module(i.data)
		sqlite3_vtab_eponymous_table_clear(db, p_mod)
		sqlite3_vtab_module_unref(db, p_mod)
	}
	sqlite3_hash_clear(&db.aModule)
	sqlite3_error(db, 0)
	sqlite3_value_free_vdup7(db.pErr)
	sqlite3_close_extensions(db)
	db.eOpenState = U8(213)
	sqlite3_db_free(db, voidptr(db.aDb[1].pSchema))
	if db.xAutovacDestr {
		db.xAutovacDestr(voidptr(db.pAutovacPagesArg))
	}
	sqlite3_mutex_leave(db.mutex)
	db.eOpenState = U8(206)
	sqlite3_mutex_free(db.mutex)
	if db.lookaside.bMalloced {
		sqlite3_free(voidptr(db.lookaside.pStart))
	}
	sqlite3_free(voidptr(db))
}

@[c:'sqlite3RollbackAll']
fn sqlite3_rollback_all(db &Sqlite3, trip_code int) {
	i := 0
	in_trans := 0
	schema_change := 0
	sqlite3_begin_benign_malloc()
	sqlite3_btree_enter_all(db)
	schema_change = (db.mDbFlags & u32(1)) != u32(0) && int(db.init.busy) == 0
	for i = 0; i < db.nDb; i++ {
		p := db.aDb[i].pBt
		if p {
			if sqlite3_btree_txn_state(p) == 2 {
				in_trans = 1
			}
			sqlite3_btree_rollback(p, trip_code, !schema_change)
		}
	}
	sqlite3_vtab_rollback(db)
	sqlite3_end_benign_malloc()
	if schema_change {
		sqlite3_expire_prepared_statements(db, 0)
		sqlite3_reset_all_schemas_of_connection(db)
	}
	sqlite3_btree_leave_all(db)
	db.nDeferredCons = I64(0)
	db.nDeferredImmCons = I64(0)
	db.flags &= ~U64((U64(524288) | (U64(2) << 32)))
	if !isnil(db.xRollbackCallback) && (in_trans || !db.autoCommit) {
		db.xRollbackCallback(voidptr(db.pRollbackArg))
	}
}

@[c:'sqlite3ErrStr']
fn sqlite3_err_str(rc int) &i8 {
	if !sqlite3_err_str_a_msg_inited {
		c2v_static_init := [c'not an error', c'SQL logic error', unsafe { &i8(nil) },
			c'access permission denied', c'query aborted', c'database is locked',
			c'database table is locked', c'out of memory', c'attempt to write a readonly database',
			c'interrupted', c'disk I/O error', c'database disk image is malformed',
			c'unknown operation', c'database or disk is full', c'unable to open database file',
			c'locking protocol', unsafe { &i8(nil) }, c'database schema has changed',
			c'string or blob too big', c'constraint failed', c'datatype mismatch',
			c'bad parameter or other API misuse', unsafe { &i8(nil) }, c'authorization denied',
			unsafe { &i8(nil) }, c'column index out of range', c'file is not a database',
			c'notification message', c'warning message']
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_err_str_a_msg[c2v_i_0] = c2v_element_0
		}
		sqlite3_err_str_a_msg_inited = true
	}

	z_err := c'unknown error'
	match rc {
		(4 | (2 << 8)) {
			z_err = c'abort due to ROLLBACK'
		}
		100 {
			z_err = c'another row available'
		}
		101 {
			z_err = c'no more rows available'
		}
		else {
			rc &= 255
			if (rc >= 0) && rc < 29 && usize(sqlite3_err_str_a_msg[rc]) != usize(0) {
				z_err = sqlite3_err_str_a_msg[rc]
			}
		}
	}

	return z_err
}

@[c:'sqliteDefaultBusyCallback']
fn sqlite_default_busy_callback(ptr voidptr, count int) int {
	c2v_gc_register_thread()
	if !sqlite_default_busy_callback_delays_inited {
		c2v_static_init := [U8(1), U8(2), U8(5), U8(10), U8(15), U8(20), U8(25), U8(25), U8(25),
			U8(50), U8(50), U8(100)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite_default_busy_callback_delays[c2v_i_0] = c2v_element_0
		}
		sqlite_default_busy_callback_delays_inited = true
	}

	if !sqlite_default_busy_callback_totals_inited {
		c2v_static_init := [U8(0), U8(1), U8(3), U8(8), U8(18), U8(33), U8(53), U8(78), U8(103),
			U8(128), U8(178), U8(228)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite_default_busy_callback_totals[c2v_i_0] = c2v_element_0
		}
		sqlite_default_busy_callback_totals_inited = true
	}

	db := &Sqlite3(ptr)
	tmout := db.busyTimeout
	delay := 0
	prior := 0

	if count < 12 {
		delay = int(sqlite_default_busy_callback_delays[count])
		prior = int(sqlite_default_busy_callback_totals[count])
	} else {
		delay = int(sqlite_default_busy_callback_delays[11])
		prior = int(sqlite_default_busy_callback_totals[11]) + delay * (count - 11)
	}
	if prior + delay > tmout {
		delay = tmout - prior
		if delay <= 0 {
			return 0
		}
	}
	sqlite3_os_sleep(db.pVfs, delay * 1000)
	return 1
}

@[c:'sqlite3InvokeBusyHandler']
fn sqlite3_invoke_busy_handler(p &BusyHandler) int {
	rc := 0
	if isnil(p.xBusyHandler) || p.nBusy < 0 {
		return 0
	}
	rc = p.xBusyHandler(voidptr(p.pBusyArg), p.nBusy)
	if rc == 0 {
		p.nBusy = -1
	} else {
		p.nBusy++
	}
	return rc
}

fn sqlite3_busy_handler(db &Sqlite3, x_busy fn (voidptr, int) int, p_arg voidptr) int {
	c2v_gc_register_thread()
	sqlite3_mutex_enter(db.mutex)
	db.busyHandler.xBusyHandler = x_busy
	db.busyHandler.pBusyArg = p_arg
	db.busyHandler.nBusy = 0
	db.busyTimeout = 0
	sqlite3_mutex_leave(db.mutex)
	return 0
}

fn sqlite3_progress_handler(db &Sqlite3, n_ops int, x_progress fn (voidptr) int, p_arg voidptr) {
	c2v_gc_register_thread()
	sqlite3_mutex_enter(db.mutex)
	if n_ops > 0 {
		db.xProgress = x_progress
		db.nProgressOps = u32(n_ops)
		db.pProgressArg = p_arg
	} else {
		db.xProgress = 0
		db.nProgressOps = u32(0)
		db.pProgressArg = 0
	}
	sqlite3_mutex_leave(db.mutex)
}

fn sqlite3_busy_timeout(db &Sqlite3, ms int) int {
	c2v_gc_register_thread()
	sqlite3_mutex_enter(db.mutex)
	if ms > 0 {
		sqlite3_busy_handler(db, C2vFn_666e2028766f69647074722c20696e742920696e74(voidptr(sqlite_default_busy_callback)), voidptr(db))
		db.busyTimeout = ms
	} else {
		sqlite3_busy_handler(db, unsafe { nil }, unsafe { nil })
	}
	sqlite3_mutex_leave(db.mutex)
	return 0
}

fn sqlite3_setlk_timeout(db &Sqlite3, ms int, flags int) int {
	c2v_gc_register_thread()
	if ms < -1 {
		return 25
	}

	return 0
}

fn sqlite3_interrupt(db &Sqlite3) {
	c2v_gc_register_thread()
	C.c2v_atomic_store_n__int_int_int_((&db.u1.isInterrupted), 1, 0)
}

fn sqlite3_is_interrupted(db &Sqlite3) int {
	c2v_gc_register_thread()
	return int(C.c2v_atomic_load_n__int_int_int((&db.u1.isInterrupted), 0) != 0)
}

@[c:'sqlite3CreateFunc']
fn sqlite3_create_func(db &Sqlite3, z_function_name &i8, n_arg int, enc int, p_user_data voidptr, xsf_unc fn (&Sqlite3_context, int, &&Sqlite3_value), x_step fn (&Sqlite3_context, int, &&Sqlite3_value), x_final fn (&Sqlite3_context), x_value fn (&Sqlite3_context), x_inverse fn (&Sqlite3_context, int, &&Sqlite3_value), p_destructor &FuncDestructor) int {
	p := &FuncDef(0)
	extra_flags := 0
	mut __c2v_condition_146 := false
	mut __c2v_condition_147 := false
	__c2v_condition_147 = usize(z_function_name) == usize(0)
	__c2v_condition_146 = __c2v_condition_147
	if !__c2v_condition_146 {
		mut __c2v_condition_148 := false
		__c2v_condition_148 = (!isnil(xsf_unc) && !isnil(x_final))
		__c2v_condition_146 = __c2v_condition_148
	}
	if !__c2v_condition_146 {
		mut __c2v_condition_149 := false
		__c2v_condition_149 = ((isnil(x_final)) != (isnil(x_step)))
		__c2v_condition_146 = __c2v_condition_149
	}
	if !__c2v_condition_146 {
		mut __c2v_condition_150 := false
		__c2v_condition_150 = ((isnil(x_value)) != (isnil(x_inverse)))
		__c2v_condition_146 = __c2v_condition_150
	}
	if !__c2v_condition_146 {
		mut __c2v_condition_151 := false
		__c2v_condition_151 = (n_arg < -1 || n_arg > 1000)
		__c2v_condition_146 = __c2v_condition_151
	}
	if !__c2v_condition_146 {
		mut __c2v_condition_152 := false
		__c2v_condition_152 = (255 < sqlite3_strlen30(z_function_name))
		__c2v_condition_146 = __c2v_condition_152
	}
	if __c2v_condition_146 {
		return sqlite3_misuse_error(2070)
	}
	extra_flags = enc & (2048 | 524288 | 1048576 | 2097152 | 16777216 | 33554432)
	enc &= (3 | 5)
	extra_flags ^= 2097152
	match enc {
		4 {
			enc = 2
		}
		5 {
			rc := 0
			rc = sqlite3_create_func(db, z_function_name, n_arg, (1 | extra_flags) ^ 2097152, voidptr(p_user_data), xsf_unc, x_step, x_final, x_value, x_inverse, p_destructor)
			if rc == 0 {
				rc = sqlite3_create_func(db, z_function_name, n_arg, (2 | extra_flags) ^ 2097152, voidptr(p_user_data), xsf_unc, x_step, x_final, x_value, x_inverse, p_destructor)
			}
			if rc != 0 {
				return rc
			}
			enc = 3
		}
		1, 2, 3 {
		}
		else {
			enc = 1
		}
	}

	p = sqlite3_find_function(db, z_function_name, n_arg, U8(enc), U8(0))
	if !isnil(p) && (p.funcFlags & u32(3)) == u32(enc) && int(p.nArg) == n_arg {
		if db.nVdbeActive {
			sqlite3_error_with_msg(db, 5, c'unable to delete/modify user-function due to active statements')
			return 5
		} else {
			sqlite3_expire_prepared_statements(db, 0)
		}
	} else if isnil(xsf_unc) && isnil(x_final) {
		return 0
	}
	p = sqlite3_find_function(db, z_function_name, n_arg, U8(enc), U8(1))
	if isnil(p) {
		return 7
	}
	function_destroy(db, p)
	if p_destructor {
		p_destructor.nRef++
	}
	p.u.pDestructor = p_destructor
	p.funcFlags = (p.funcFlags & u32(3)) | u32(extra_flags)
	p.xSFunc = if xsf_unc { xsf_unc } else { x_step }
	p.xFinalize = x_final
	p.xValue = x_value
	p.xInverse = x_inverse
	p.pUserData = p_user_data
	p.nArg = I16(U16(n_arg))
	return 0
}

@[c:'createFunctionApi']
fn create_function_api(db &Sqlite3, z_func &i8, n_arg int, enc int, p voidptr, xsf_unc fn (&Sqlite3_context, int, &&Sqlite3_value), x_step fn (&Sqlite3_context, int, &&Sqlite3_value), x_final fn (&Sqlite3_context), x_value fn (&Sqlite3_context), x_inverse fn (&Sqlite3_context, int, &&Sqlite3_value), x_destroy fn (voidptr)) int {
	rc := 1
	p_arg := unsafe { &FuncDestructor(nil) }
	sqlite3_mutex_enter(db.mutex)
	if x_destroy {
		p_arg = &FuncDestructor(sqlite3_malloc_vdup2(U64(sizeof(FuncDestructor))))
		if isnil(p_arg) {
			sqlite3_oom_fault(db)
			x_destroy(voidptr(p))
			unsafe { goto out
			 }
		}
		p_arg.nRef = 0
		p_arg.xDestroy = x_destroy
		p_arg.pUserData = p
	}
	rc = sqlite3_create_func(db, z_func, n_arg, enc, voidptr(p), xsf_unc, x_step, x_final, x_value, x_inverse, p_arg)
	if !isnil(p_arg) && p_arg.nRef == 0 {
		x_destroy(voidptr(p))
		sqlite3_free(voidptr(p_arg))
	}
	out:
	rc = sqlite3_api_exit(db, rc)
	sqlite3_mutex_leave(db.mutex)
	return rc
}

fn sqlite3_create_function(db &Sqlite3, z_func &i8, n_arg int, enc int, p voidptr, xsf_unc fn (&Sqlite3_context, int, &&Sqlite3_value), x_step fn (&Sqlite3_context, int, &&Sqlite3_value), x_final fn (&Sqlite3_context)) int {
	c2v_gc_register_thread()
	return create_function_api(db, z_func, n_arg, enc, voidptr(p), xsf_unc, x_step, x_final, unsafe { nil }, unsafe { nil }, unsafe { nil })
}

fn sqlite3_create_function_v2(db &Sqlite3, z_func &i8, n_arg int, enc int, p voidptr, xsf_unc fn (&Sqlite3_context, int, &&Sqlite3_value), x_step fn (&Sqlite3_context, int, &&Sqlite3_value), x_final fn (&Sqlite3_context), x_destroy fn (voidptr)) int {
	c2v_gc_register_thread()
	return create_function_api(db, z_func, n_arg, enc, voidptr(p), xsf_unc, x_step, x_final, unsafe { nil }, unsafe { nil }, x_destroy)
}

fn sqlite3_create_window_function(db &Sqlite3, z_func &i8, n_arg int, enc int, p voidptr, x_step fn (&Sqlite3_context, int, &&Sqlite3_value), x_final fn (&Sqlite3_context), x_value fn (&Sqlite3_context), x_inverse fn (&Sqlite3_context, int, &&Sqlite3_value), x_destroy fn (voidptr)) int {
	c2v_gc_register_thread()
	return create_function_api(db, z_func, n_arg, enc, voidptr(p), unsafe { nil }, x_step, x_final, x_value, x_inverse, x_destroy)
}

fn sqlite3_create_function16(db &Sqlite3, z_function_name voidptr, n_arg int, e_text_rep int, p voidptr, xsf_unc fn (&Sqlite3_context, int, &&Sqlite3_value), x_step fn (&Sqlite3_context, int, &&Sqlite3_value), x_final fn (&Sqlite3_context)) int {
	c2v_gc_register_thread()
	rc := 0
	z_func8 := &i8(0)
	sqlite3_mutex_enter(db.mutex)
	z_func8 = sqlite3_utf16to8(db, voidptr(z_function_name), -1, U8(2))
	rc = sqlite3_create_func(db, z_func8, n_arg, e_text_rep, voidptr(p), xsf_unc, x_step, x_final, unsafe { nil }, unsafe { nil }, unsafe { nil })
	sqlite3_db_free(db, voidptr(z_func8))
	rc = sqlite3_api_exit(db, rc)
	sqlite3_mutex_leave(db.mutex)
	return rc
}

@[c:'sqlite3InvalidFunction']
fn sqlite3_invalid_function(context &Sqlite3_context, not_used int, not_used2 &&Sqlite3_value) {
	c2v_gc_register_thread()
	z_name := &i8(sqlite3_user_data(context))
	z_err := &i8(0)

	z_err = sqlite3_mprintf(c'unable to use function %s in the requested context', voidptr(z_name))
	sqlite3_result_error(context, z_err, -1)
	sqlite3_free(voidptr(z_err))
}

fn sqlite3_overload_function(db &Sqlite3, z_name &i8, n_arg int) int {
	c2v_gc_register_thread()
	rc := 0
	z_copy := &i8(0)
	sqlite3_mutex_enter(db.mutex)
	rc = usize(sqlite3_find_function(db, z_name, n_arg, U8(1), U8(0))) != usize(0)
	sqlite3_mutex_leave(db.mutex)
	if rc {
		return 0
	}
	z_copy = sqlite3_mprintf(c'%s', voidptr(z_name))
	if usize(z_copy) == usize(0) {
		return 7
	}
	return sqlite3_create_function_v2(db, z_name, n_arg, 1, voidptr(z_copy), sqlite3_invalid_function, unsafe { nil }, unsafe { nil }, sqlite3_free)
}

fn sqlite3_trace(db &Sqlite3, x_trace fn (voidptr, &i8), p_arg voidptr) voidptr {
	c2v_gc_register_thread()
	p_old := &voidptr(0)
	sqlite3_mutex_enter(db.mutex)
	p_old = db.pTraceArg
	db.mTrace = U8(if x_trace { 64 } else { 0 })
	db.trace.xLegacy = x_trace
	db.pTraceArg = p_arg
	sqlite3_mutex_leave(db.mutex)
	return p_old
}

fn sqlite3_trace_v2(db &Sqlite3, m_trace u32, x_trace fn (u32, voidptr, voidptr, voidptr) int, p_arg voidptr) int {
	c2v_gc_register_thread()
	sqlite3_mutex_enter(db.mutex)
	if m_trace == u32(0) {
		x_trace = 0
	}
	if isnil(x_trace) {
		m_trace = u32(0)
	}
	db.mTrace = U8(m_trace)
	db.trace.xV2 = x_trace
	db.pTraceArg = p_arg
	sqlite3_mutex_leave(db.mutex)
	return 0
}

fn sqlite3_profile(db &Sqlite3, x_profile fn (voidptr, &i8, Sqlite_uint64), p_arg voidptr) voidptr {
	c2v_gc_register_thread()
	p_old := &voidptr(0)
	sqlite3_mutex_enter(db.mutex)
	p_old = db.pProfileArg
	db.xProfile = x_profile
	db.pProfileArg = p_arg
	db.mTrace &= 15
	if db.xProfile {
		db.mTrace |= 128
	}
	sqlite3_mutex_leave(db.mutex)
	return p_old
}

fn sqlite3_commit_hook(db &Sqlite3, x_callback fn (voidptr) int, p_arg voidptr) voidptr {
	c2v_gc_register_thread()
	p_old := &voidptr(0)
	sqlite3_mutex_enter(db.mutex)
	p_old = db.pCommitArg
	db.xCommitCallback = x_callback
	db.pCommitArg = p_arg
	sqlite3_mutex_leave(db.mutex)
	return p_old
}

fn sqlite3_update_hook(db &Sqlite3, x_callback fn (voidptr, int, &i8, &i8, Sqlite_int64), p_arg voidptr) voidptr {
	c2v_gc_register_thread()
	p_ret := &voidptr(0)
	sqlite3_mutex_enter(db.mutex)
	p_ret = db.pUpdateArg
	db.xUpdateCallback = x_callback
	db.pUpdateArg = p_arg
	sqlite3_mutex_leave(db.mutex)
	return p_ret
}

fn sqlite3_rollback_hook(db &Sqlite3, x_callback fn (voidptr), p_arg voidptr) voidptr {
	c2v_gc_register_thread()
	p_ret := &voidptr(0)
	sqlite3_mutex_enter(db.mutex)
	p_ret = db.pRollbackArg
	db.xRollbackCallback = x_callback
	db.pRollbackArg = p_arg
	sqlite3_mutex_leave(db.mutex)
	return p_ret
}

fn sqlite3_autovacuum_pages(db &Sqlite3, x_callback fn (voidptr, &i8, u32, u32, u32) u32, p_arg voidptr, x_destructor fn (voidptr)) int {
	c2v_gc_register_thread()
	sqlite3_mutex_enter(db.mutex)
	if db.xAutovacDestr {
		db.xAutovacDestr(voidptr(db.pAutovacPagesArg))
	}
	db.xAutovacPages = x_callback
	db.pAutovacPagesArg = p_arg
	db.xAutovacDestr = x_destructor
	sqlite3_mutex_leave(db.mutex)
	return 0
}

@[c:'sqlite3WalDefaultHook']
fn sqlite3_wal_default_hook(p_client_data voidptr, db &Sqlite3, z_db &i8, n_frame int) int {
	c2v_gc_register_thread()
	if n_frame >= (int(i64(p_client_data))) {
		sqlite3_begin_benign_malloc()
		sqlite3_wal_checkpoint(db, z_db)
		sqlite3_end_benign_malloc()
	}
	return 0
}

fn sqlite3_wal_autocheckpoint(db &Sqlite3, n_frame int) int {
	c2v_gc_register_thread()
	if n_frame > 0 {
		sqlite3_wal_hook(db, sqlite3_wal_default_hook, voidptr((voidptr(i64(n_frame)))))
	} else {
		sqlite3_wal_hook(db, unsafe { nil }, unsafe { nil })
	}
	return 0
}

fn sqlite3_wal_hook(db &Sqlite3, x_callback fn (voidptr, &Sqlite3, &i8, int) int, p_arg voidptr) voidptr {
	c2v_gc_register_thread()
	p_ret := &voidptr(0)
	sqlite3_mutex_enter(db.mutex)
	p_ret = db.pWalArg
	db.xWalCallback = x_callback
	db.pWalArg = p_arg
	sqlite3_mutex_leave(db.mutex)
	return p_ret
}

fn sqlite3_wal_checkpoint_v2(db &Sqlite3, z_db &i8, e_mode int, pn_log &int, pn_ckpt &int) int {
	c2v_gc_register_thread()
	rc := 0
	i_db := 0
	if pn_log {
		unsafe { *pn_log = -1 }
	}
	if pn_ckpt {
		unsafe { *pn_ckpt = -1 }
	}
	if e_mode < -1 || e_mode > 3 {
		return sqlite3_misuse_error(2695)
	}
	sqlite3_mutex_enter(db.mutex)
	if !isnil(z_db) && int(z_db[0]) {
		i_db = sqlite3_find_db_name(db, z_db)
	} else {
		i_db = (10 + 2)
	}
	if i_db < 0 {
		rc = 1
		sqlite3_error_with_msg(db, 1, c'unknown database: %s', voidptr(z_db))
	} else {
		db.busyHandler.nBusy = 0
		rc = sqlite3_checkpoint(db, i_db, e_mode, pn_log, pn_ckpt)
		sqlite3_error(db, rc)
	}
	rc = sqlite3_api_exit(db, rc)
	if db.nVdbeActive == 0 {
		C.c2v_atomic_store_n__int_int_int_((&db.u1.isInterrupted), 0, 0)
	}
	sqlite3_mutex_leave(db.mutex)
	return rc
}

fn sqlite3_wal_checkpoint(db &Sqlite3, z_db &i8) int {
	c2v_gc_register_thread()
	return sqlite3_wal_checkpoint_v2(db, z_db, 0, unsafe { nil }, unsafe { nil })
}

@[c:'sqlite3Checkpoint']
fn sqlite3_checkpoint(db &Sqlite3, i_db int, e_mode int, pn_log &int, pn_ckpt &int) int {
	rc := 0
	i := 0
	b_busy := 0
	for i = 0; i < db.nDb && rc == 0; i++ {
		if i == i_db || i_db == (10 + 2) {
			rc = sqlite3_btree_checkpoint(db.aDb[i].pBt, e_mode, pn_log, pn_ckpt)
			pn_log = 0
			pn_ckpt = 0
			if rc == 5 {
				b_busy = 1
				rc = 0
			}
		}
	}
	return if (rc == 0 && b_busy) { 5 } else { rc }
}

@[c:'sqlite3TempInMemory']
fn sqlite3_temp_in_memory(db &Sqlite3) int {
	return int((int(db.temp_store) == 2))
}

fn sqlite3_errmsg(db &Sqlite3) &i8 {
	c2v_gc_register_thread()
	z := &i8(0)
	if isnil(db) {
		return sqlite3_err_str(7)
	}
	if !sqlite3_safety_check_sick_or_ok(db) {
		return sqlite3_err_str(sqlite3_misuse_error(2831))
	}
	sqlite3_mutex_enter(db.mutex)
	if db.mallocFailed {
		z = sqlite3_err_str(7)
	} else {
		z = unsafe { if db.errCode { &i8(voidptr(sqlite3_value_text(db.pErr))) } else { &i8(nil) } }
		if usize(z) == usize(0) {
			z = sqlite3_err_str(db.errCode)
		}
	}
	sqlite3_mutex_leave(db.mutex)
	return z
}

fn sqlite3_set_errmsg(db &Sqlite3, errcode int, z_msg &i8) int {
	c2v_gc_register_thread()
	rc := 0
	if !sqlite3_safety_check_ok(db) {
		return sqlite3_misuse_error(2858)
	}
	sqlite3_mutex_enter(db.mutex)
	if z_msg {
		sqlite3_error_with_msg(db, errcode, c'%s', voidptr(z_msg))
	} else {
		sqlite3_error(db, errcode)
	}
	rc = sqlite3_api_exit(db, rc)
	sqlite3_mutex_leave(db.mutex)
	return rc
}

fn sqlite3_error_offset(db &Sqlite3) int {
	c2v_gc_register_thread()
	i_offset := -1
	if !isnil(db) && sqlite3_safety_check_sick_or_ok(db) {
		sqlite3_mutex_enter(db.mutex)
		if db.errCode {
			i_offset = db.errByteOffset
		}
		sqlite3_mutex_leave(db.mutex)
	}
	return i_offset
}

fn sqlite3_errmsg16(db &Sqlite3) voidptr {
	c2v_gc_register_thread()
	if !sqlite3_errmsg16_out_of_mem_inited {
		c2v_static_init := [U16(`o`), U16(`u`), U16(`t`), U16(` `), U16(`o`), U16(`f`), U16(` `),
			U16(`m`), U16(`e`), U16(`m`), U16(`o`), U16(`r`), U16(`y`), U16(0)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_errmsg16_out_of_mem[c2v_i_0] = c2v_element_0
		}
		sqlite3_errmsg16_out_of_mem_inited = true
	}

	if !sqlite3_errmsg16_misuse_inited {
		c2v_static_init := [U16(`b`), U16(`a`), U16(`d`), U16(` `), U16(`p`), U16(`a`), U16(`r`),
			U16(`a`), U16(`m`), U16(`e`), U16(`t`), U16(`e`), U16(`r`), U16(` `), U16(`o`), U16(`r`),
			U16(` `), U16(`o`), U16(`t`), U16(`h`), U16(`e`), U16(`r`), U16(` `), U16(`A`), U16(`P`),
			U16(`I`), U16(` `), U16(`m`), U16(`i`), U16(`s`), U16(`u`), U16(`s`), U16(`e`), U16(0)]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_errmsg16_misuse[c2v_i_0] = c2v_element_0
		}
		sqlite3_errmsg16_misuse_inited = true
	}

	z := &voidptr(0)
	if isnil(db) {
		return voidptr(unsafe { &sqlite3_errmsg16_out_of_mem[0] })
	}
	if !sqlite3_safety_check_sick_or_ok(db) {
		return voidptr(unsafe { &sqlite3_errmsg16_misuse[0] })
	}
	sqlite3_mutex_enter(db.mutex)
	if db.mallocFailed {
		z = voidptr(unsafe { &sqlite3_errmsg16_out_of_mem[0] })
	} else {
		z = sqlite3_value_text16(db.pErr)
		if usize(z) == usize(0) {
			sqlite3_error_with_msg(db, db.errCode, sqlite3_err_str(db.errCode))
			z = sqlite3_value_text16(db.pErr)
		}
		sqlite3_oom_clear(db)
	}
	sqlite3_mutex_leave(db.mutex)
	return z
}

fn sqlite3_errcode(db &Sqlite3) int {
	c2v_gc_register_thread()
	i_ret := 0
	if isnil(db) {
		return 7
	}
	if !sqlite3_safety_check_sick_or_ok(db) {
		return sqlite3_misuse_error(2937)
	}
	sqlite3_mutex_enter(db.mutex)
	if db.mallocFailed {
		i_ret = 7
	} else {
		i_ret = db.errCode & db.errMask
	}
	sqlite3_mutex_leave(db.mutex)
	return i_ret
}

fn sqlite3_extended_errcode(db &Sqlite3) int {
	c2v_gc_register_thread()
	i_ret := 0
	if isnil(db) {
		return 7
	}
	if !sqlite3_safety_check_sick_or_ok(db) {
		return sqlite3_misuse_error(2952)
	}
	sqlite3_mutex_enter(db.mutex)
	if db.mallocFailed {
		i_ret = 7
	} else {
		i_ret = db.errCode
	}
	sqlite3_mutex_leave(db.mutex)
	return i_ret
}

fn sqlite3_system_errno(db &Sqlite3) int {
	c2v_gc_register_thread()
	i_ret := 0
	if db {
		sqlite3_mutex_enter(db.mutex)
		i_ret = db.iSysErrno
		sqlite3_mutex_leave(db.mutex)
	}
	return i_ret
}

fn sqlite3_errstr(rc int) &i8 {
	c2v_gc_register_thread()
	return sqlite3_err_str(rc)
}

@[c:'createCollation']
fn create_collation(db &Sqlite3, z_name &i8, enc U8, p_ctx voidptr, x_compare fn (voidptr, int, voidptr, int, voidptr) int, x_del fn (voidptr)) int {
	p_coll := &CollSeq(0)
	enc2 := 0
	enc2 = int(enc)
	if enc2 == 4 || enc2 == 8 {
		enc2 = 2
	}
	if enc2 < 1 || enc2 > 3 {
		return sqlite3_misuse_error(3010)
	}
	p_coll = sqlite3_find_coll_seq(db, U8(enc2), z_name, 0)
	if !isnil(p_coll) && !isnil(p_coll.xCmp) {
		if db.nVdbeActive {
			sqlite3_error_with_msg(db, 5, c'unable to delete/modify collation sequence due to active statements')
			return 5
		}
		sqlite3_expire_prepared_statements(db, 0)
		if (int(p_coll.enc) & ~8) == enc2 {
			a_coll := &CollSeq(sqlite3_hash_find(&db.aCollSeq, z_name))
			j := 0
			for j = 0; j < 3; j++ {
				p := unsafe { a_coll + j }
				if int(p.enc) == int(p_coll.enc) {
					if p.xDel {
						p.xDel(voidptr(p.pUser))
					}
					p.xCmp = 0
				}
			}
		}
	}
	p_coll = sqlite3_find_coll_seq(db, U8(enc2), z_name, 1)
	if usize(p_coll) == usize(0) {
		return 7
	}
	p_coll.xCmp = x_compare
	p_coll.pUser = p_ctx
	p_coll.xDel = x_del
	p_coll.enc = U8((enc2 | (int(enc) & 8)))
	sqlite3_error(db, 0)
	return 0
}

fn sqlite3_limit(db &Sqlite3, limit_id int, new_limit int) int {
	c2v_gc_register_thread()
	old_limit := 0
	if limit_id < 0 || limit_id >= (12 + 1) {
		return -1
	}
	sqlite3_mutex_enter(db.mutex)
	old_limit = db.aLimit[limit_id]
	if new_limit >= 0 {
		if new_limit > aHardLimit[limit_id] {
			new_limit = aHardLimit[limit_id]
		} else if new_limit < 30 && limit_id == 0 {
			new_limit = 30
		}
		db.aLimit[limit_id] = new_limit
	}
	sqlite3_mutex_leave(db.mutex)
	return old_limit
}

@[c:'sqlite3ParseUri']
fn sqlite3_parse_uri(z_default_vfs &i8, z_uri &i8, p_flags &u32, pp_vfs &&Sqlite3_vfs, pz_file &&u8, pz_err_msg &&u8) int {
	rc := 0
	flags := (unsafe { *p_flags })
	z_vfs := z_default_vfs
	z_file := &i8(0)
	c := i8(0)
	n_uri := I64(C.strlen(z_uri))
	if ((flags & u32(64)) || int(C.c2v_atomic_load_n__U8_int_U8((&sqlite3Config.bOpenUri), 0))) && n_uri >= I64(5) && C.memcmp(voidptr(z_uri), voidptr(c'file:'), u64(5)) == 0 {
		z_opt := &i8(0)
		e_state := 0
		i_in := I64(0)
		i_out := I64(0)
		n_byte := U64(n_uri + I64(8))
		flags |= u32(64)
		for i_in = I64(0); i_in < n_uri; i_in++ {
			n_byte += U64((int(z_uri[i_in]) == i8(`&`)))
		}
		z_file = &i8(sqlite3_malloc64(n_byte))
		if isnil(z_file) {
			return 7
		}
		C.memset(voidptr(z_file), 0, u64(4))
		c2v_pointer_prefix(voidptr(&z_file), z_file, isize(4))
		i_in = I64(5)
		if int(z_uri[5]) == i8(`/`) && int(z_uri[6]) == i8(`/`) {
			i_in = I64(7)
			for int(z_uri[i_in]) && int(z_uri[i_in]) != i8(`/`) {
				i_in++
			}
			if i_in != I64(7) && (i_in != I64(16) || C.memcmp(voidptr(c'localhost'), voidptr(unsafe { z_uri + 7 }), u64(9))) {
				unsafe { *pz_err_msg = sqlite3_mprintf(c'invalid uri authority: %.*s', int((i_in - I64(7))), voidptr(z_uri + 7)) }
				rc = 1
				unsafe { goto parse_uri_out
				 }
			}
		}
		e_state = 0
		for {
			c = z_uri[i_in]
			if !(int(c) != 0 && int(c) != i8(`#`)) {
				break
			}
			i_in++
			if int(c) == i8(`%`) && (int(sqlite3CtypeMap[u8(z_uri[i_in])]) & 8) && (int(sqlite3CtypeMap[u8(z_uri[i_in + I64(1)])]) & 8) {
				octet := (int(sqlite3_hex_to_int(z_uri[i_in++])) << 4)
				octet += int(sqlite3_hex_to_int(z_uri[i_in++]))
				if octet == 0 {
					for {
						c = z_uri[i_in]
						if !(int(c) != 0 && int(c) != i8(`#`) && (e_state != 0 || int(c) != i8(`?`)) && (e_state != 1 || (int(c) != i8(`=`) && int(c) != i8(`&`))) && (e_state != 2 || int(c) != i8(`&`))) {
							break
						}
						i_in++
					}
					continue
				}
				c = i8(octet)
			} else if e_state == 1 && (int(c) == i8(`&`) || int(c) == i8(`=`)) {
				if int(z_file[i_out - I64(1)]) == 0 {
					for int(z_uri[i_in]) && int(z_uri[i_in]) != i8(`#`) && int(z_uri[i_in - I64(1)]) != i8(`&`) {
						i_in++
					}
					continue
				}
				if int(c) == i8(`&`) {
					z_file[i_out++] = i8(`\0`)
				} else {
					e_state = 2
				}
				c = i8(0)
			} else if (e_state == 0 && int(c) == i8(`?`)) || (e_state == 2 && int(c) == i8(`&`)) {
				c = i8(0)
				e_state = 1
			}
			z_file[i_out++] = c
		}
		if e_state == 1 {
			z_file[i_out++] = i8(`\0`)
		}
		C.memset(voidptr(z_file + i_out), 0, u64(4))
		z_opt = unsafe { z_file + (C.strlen(z_file) + u64(1)) }
		for z_opt[0] {
			n_opt := I64(C.strlen(z_opt))
			z_val := unsafe { z_opt + (n_opt + I64(1)) }
			n_val := I64(C.strlen(z_val))
			if n_opt == I64(3) && C.memcmp(voidptr(c'vfs'), voidptr(z_opt), u64(3)) == 0 {
				z_vfs = z_val
			} else {
				a_mode := unsafe { &OpenMode(nil) }

				z_mode_type := unsafe { &i8(nil) }
				mask := 0
				limit := 0
				if n_opt == I64(5) && C.memcmp(voidptr(c'cache'), voidptr(z_opt), u64(5)) == 0 {
					if !sqlite3_parse_uri_a_cache_mode_inited {
						c2v_static_init := [OpenMode{
							z: c'shared'
							mode: 131072
						}, OpenMode{
							z: c'private'
							mode: 262144
						}, OpenMode{}]
						for c2v_i_0, c2v_element_0 in c2v_static_init {
							sqlite3_parse_uri_a_cache_mode[c2v_i_0] = c2v_element_0
						}
						sqlite3_parse_uri_a_cache_mode_inited = true
					}

					mask = 131072 | 262144
					a_mode = unsafe { &sqlite3_parse_uri_a_cache_mode[0] }
					limit = mask
					z_mode_type = c'cache'
				}
				if n_opt == I64(4) && C.memcmp(voidptr(c'mode'), voidptr(z_opt), u64(4)) == 0 {
					if !sqlite3_parse_uri_a_open_mode_inited {
						c2v_static_init := [OpenMode{
							z: c'ro'
							mode: 1
						}, OpenMode{
							z: c'rw'
							mode: 2
						}, OpenMode{
							z: c'rwc'
							mode: 2 | 4
						}, OpenMode{
							z: c'memory'
							mode: 128
						}, OpenMode{}]
						for c2v_i_0, c2v_element_0 in c2v_static_init {
							sqlite3_parse_uri_a_open_mode[c2v_i_0] = c2v_element_0
						}
						sqlite3_parse_uri_a_open_mode_inited = true
					}

					mask = 1 | 2 | 4 | 128
					a_mode = unsafe { &sqlite3_parse_uri_a_open_mode[0] }
					limit = int(u32(mask) & flags)
					z_mode_type = c'access'
				}
				if a_mode {
					i := 0
					mode := 0
					for i = 0; a_mode[i].z; i++ {
						z := a_mode[i].z
						if n_val == I64(C.strlen(z)) && 0 == C.memcmp(voidptr(z_val), voidptr(z), u64(n_val)) {
							mode = a_mode[i].mode
							break
						}
					}
					if mode == 0 {
						unsafe { *pz_err_msg = sqlite3_mprintf(c'no such %s mode: %s', voidptr(z_mode_type), voidptr(z_val)) }
						rc = 1
						unsafe { goto parse_uri_out
						 }
					}
					if (mode & ~128) > limit {
						unsafe { *pz_err_msg = sqlite3_mprintf(c'%s mode not allowed: %s', voidptr(z_mode_type), voidptr(z_val)) }
						rc = 3
						unsafe { goto parse_uri_out
						 }
					}
					flags = (flags & u32(~mask)) | u32(mode)
				}
			}
			z_opt = unsafe { z_val + (n_val + I64(1)) }
		}
	} else {
		z_file = &i8(sqlite3_malloc64(Sqlite3_uint64(n_uri + I64(8))))
		if isnil(z_file) {
			return 7
		}
		C.memset(voidptr(z_file), 0, u64(4))
		c2v_pointer_prefix(voidptr(&z_file), z_file, isize(4))
		if n_uri {
			C.memcpy(voidptr(z_file), voidptr(z_uri), u64(n_uri))
		}
		C.memset(voidptr(z_file + n_uri), 0, u64(4))
		flags &= u32(~64)
	}
	unsafe { *pp_vfs = sqlite3_vfs_find(z_vfs) }
	if usize((unsafe { *pp_vfs })) == usize(0) {
		unsafe { *pz_err_msg = sqlite3_mprintf(c'no such vfs: %s', voidptr(z_vfs)) }
		rc = 1
	}
	parse_uri_out:
	if rc != 0 {
		sqlite3_free_filename(z_file)
		z_file = 0
	}
	unsafe { *p_flags = flags }
	unsafe { *pz_file = z_file }
	return rc
}

@[c:'uriParameter']
fn uri_parameter(z_filename &i8, z_param &i8) &i8 {
	c2v_pointer_prefix(voidptr(&z_filename), z_filename, isize(sqlite3_strlen30(z_filename) + 1))
	for (usize(z_filename) != usize(0)) && int(z_filename[0]) {
		x := C.strcmp(z_filename, z_param)
		c2v_pointer_prefix(voidptr(&z_filename), z_filename, isize(sqlite3_strlen30(z_filename) + 1))
		if x == 0 {
			return z_filename
		}
		c2v_pointer_prefix(voidptr(&z_filename), z_filename, isize(sqlite3_strlen30(z_filename) + 1))
	}
	return unsafe { nil }
}

@[c:'openDatabase']
fn open_database(z_filename &i8, pp_db &&Sqlite3, flags u32, z_vfs &i8) int {
	db := &Sqlite3(0)
	rc := 0
	is_threadsafe := 0
	z_open := unsafe { &i8(nil) }
	z_err_msg := unsafe { &i8(nil) }
	i := 0
	unsafe { *pp_db = 0 }
	rc = sqlite3_initialize()
	if rc {
		return rc
	}
	if int(sqlite3Config.bCoreMutex) == 0 {
		is_threadsafe = 0
	} else if flags & u32(32768) {
		is_threadsafe = 0
	} else if flags & u32(65536) {
		is_threadsafe = 1
	} else {
		is_threadsafe = int(sqlite3Config.bFullMutex)
	}
	if flags & u32(262144) {
		flags &= u32(~131072)
	} else if sqlite3Config.sharedCacheEnabled {
		flags |= u32(131072)
	}
	flags &= u32(~(8 | 16 | 256 | 512 | 1024 | 2048 | 4096 | 8192 | 16384 | 32768 | 65536 | 524288))
	db = sqlite3_malloc_zero(U64(sizeof(Sqlite3)))
	if usize(db) == usize(0) {
		unsafe { goto opendb_out
		 }
	}
	if is_threadsafe {
		db.mutex = sqlite3_mutex_alloc_vdup4(1)
		if usize(db.mutex) == usize(0) {
			sqlite3_free(voidptr(db))
			db = 0
			unsafe { goto opendb_out
			 }
		}
		if is_threadsafe == 0 {
		}
	}
	sqlite3_mutex_enter(db.mutex)
	db.errMask = int(if (flags & u32(33554432)) != u32(0) { u32(4294967295) } else { u32(255) })
	db.nDb = 2
	db.eOpenState = U8(109)
	db.aDb = unsafe { &db.aDbStatic[0] }
	db.lookaside.bDisable = u32(1)
	db.lookaside.sz = U16(0)
	db.nFpDigit = U8(17)
	C.memcpy(db.aLimit, voidptr(unsafe { &aHardLimit[0] }), sizeof([13]int))
	db.aLimit[11] = 0
	db.autoCommit = U8(1)
	db.nextAutovac = i8(-1)
	db.szMmap = sqlite3Config.szMmap
	db.nextPagesize = 0
	db.init.azInit = unsafe { &sqlite3StdType[0] }
	db.flags |= U64(u32(64 | 262144) | u32(2147483648) | u32(32)) | (U64(16) << 32) | (U64(32) << 32) | (U64(64) << 32) | U64(128) | U64(1073741824) | U64(536870912) | U64(32768)
	sqlite3_hash_init(&db.aCollSeq)
	sqlite3_hash_init(&db.aModule)
	create_collation(db, unsafe { &i8(&sqlite3StrBINARY[0]) }, U8(1), unsafe { nil }, bin_coll_func, unsafe { nil })
	create_collation(db, unsafe { &i8(&sqlite3StrBINARY[0]) }, U8(3), unsafe { nil }, bin_coll_func, unsafe { nil })
	create_collation(db, unsafe { &i8(&sqlite3StrBINARY[0]) }, U8(2), unsafe { nil }, bin_coll_func, unsafe { nil })
	create_collation(db, c'NOCASE', U8(1), unsafe { nil }, nocase_collating_func, unsafe { nil })
	create_collation(db, c'RTRIM', U8(1), unsafe { nil }, rtrim_coll_func, unsafe { nil })
	if db.mallocFailed {
		unsafe { goto opendb_out
		 }
	}
	db.openFlags = flags
	if ((1 << (flags & u32(7))) & 70) == 0 {
		rc = sqlite3_misuse_error(3693)
	} else {
		if usize(z_filename) == usize(0) {
			z_filename = c':memory:'
		}
		rc = sqlite3_parse_uri(z_vfs, z_filename, &flags, &&Sqlite3_vfs(&db.pVfs), &&u8(&&i8(c2v_address_of(&z_open))), &&u8(&&i8(c2v_address_of(&z_err_msg))))
	}
	if rc != 0 {
		if rc == 7 {
			sqlite3_oom_fault(db)
		}
		sqlite3_error_with_msg(db, rc, unsafe { if z_err_msg { c'%s' } else { &i8(nil) } }, voidptr(z_err_msg))
		sqlite3_free(voidptr(z_err_msg))
		unsafe { goto opendb_out
		 }
	}
	rc = sqlite3_btree_open(db.pVfs, z_open, db, &&Btree(&db.aDb[0].pBt), 0, int(flags | u32(256)))
	if rc != 0 {
		if rc == (10 | (12 << 8)) {
			rc = 7
		}
		sqlite3_error(db, rc)
		unsafe { goto opendb_out
		 }
	}
	sqlite3_btree_enter(db.aDb[0].pBt)
	db.aDb[0].pSchema = sqlite3_schema_get(db, db.aDb[0].pBt)
	if !db.mallocFailed {
		sqlite3_set_text_encoding(db, db.aDb[0].pSchema.enc)
	}
	sqlite3_btree_leave(db.aDb[0].pBt)
	db.aDb[1].pSchema = sqlite3_schema_get(db, unsafe { nil })
	db.aDb[0].zDbSName = c'main'
	db.aDb[0].safety_level = U8(2 + 1)
	db.aDb[1].zDbSName = c'temp'
	db.aDb[1].safety_level = U8(1)
	db.eOpenState = U8(118)
	if db.mallocFailed {
		unsafe { goto opendb_out
		 }
	}
	sqlite3_error(db, 0)
	sqlite3_register_per_connection_builtin_functions(db)
	rc = sqlite3_errcode(db)
	for i = 0; rc == 0 && i < (int((sizeof([1]voidptr) / sizeof(voidptr)))); i++ {
		rc = sqlite3_builtin_extensions[i](db)
	}
	if rc == 0 {
		sqlite3_auto_load_extensions(db)
		rc = sqlite3_errcode(db)
		if rc != 0 {
			unsafe { goto opendb_out
			 }
		}
	}
	if rc {
		sqlite3_error(db, rc)
	}
	setup_lookaside(db, unsafe { nil }, sqlite3Config.szLookaside, sqlite3Config.nLookaside)
	sqlite3_wal_autocheckpoint(db, 1000)
	opendb_out:
	if db {
		sqlite3_mutex_leave(db.mutex)
	}
	rc = sqlite3_errcode(db)
	if (rc & 255) == 7 {
		sqlite3_close(db)
		db = 0
	} else if rc != 0 {
		db.eOpenState = U8(186)
	}
	unsafe { *pp_db = db }
	sqlite3_free_filename(z_open)
	return rc
}

fn sqlite3_open(z_filename &i8, pp_db &&Sqlite3) int {
	c2v_gc_register_thread()
	return open_database(z_filename, pp_db, u32(2 | 4), unsafe { nil })
}

fn sqlite3_open_v2(filename &i8, pp_db &&Sqlite3, flags int, z_vfs &i8) int {
	c2v_gc_register_thread()
	return open_database(filename, pp_db, u32(flags), z_vfs)
}

fn sqlite3_open16(z_filename voidptr, pp_db &&Sqlite3) int {
	c2v_gc_register_thread()
	z_filename8 := &i8(0)
	p_val := &Sqlite3_value(0)
	rc := 0
	unsafe { *pp_db = 0 }
	rc = sqlite3_initialize()
	if rc {
		return rc
	}
	if usize(z_filename) == usize(0) {
		z_filename = c'\000\000'
	}
	p_val = sqlite3_value_new(unsafe { nil })
	sqlite3_value_set_str(p_val, -1, voidptr(z_filename), U8(2), (C2vFn_666e2028766f696470747229(voidptr(0))))
	z_filename8 = &i8(sqlite3_value_text_vdup5(p_val, U8(1)))
	if z_filename8 {
		rc = open_database(z_filename8, pp_db, u32(2 | 4), unsafe { nil })
		if rc == 0 && !((int((unsafe { *pp_db }).aDb[0].pSchema.schemaFlags) & 1) == 1) {
			unsafe { (*pp_db).enc = U8(2) }
			unsafe { (*pp_db).aDb[0].pSchema.enc = (*pp_db).enc }
		}
	} else {
		rc = 7
	}
	sqlite3_value_free_vdup7(p_val)
	return rc & 255
}

fn sqlite3_create_collation(db &Sqlite3, z_name &i8, enc int, p_ctx voidptr, x_compare fn (voidptr, int, voidptr, int, voidptr) int) int {
	c2v_gc_register_thread()
	return sqlite3_create_collation_v2(db, z_name, enc, voidptr(p_ctx), x_compare, unsafe { nil })
}

fn sqlite3_create_collation_v2(db &Sqlite3, z_name &i8, enc int, p_ctx voidptr, x_compare fn (voidptr, int, voidptr, int, voidptr) int, x_del fn (voidptr)) int {
	c2v_gc_register_thread()
	rc := 0
	sqlite3_mutex_enter(db.mutex)
	rc = create_collation(db, z_name, U8(enc), voidptr(p_ctx), x_compare, x_del)
	rc = sqlite3_api_exit(db, rc)
	sqlite3_mutex_leave(db.mutex)
	return rc
}

fn sqlite3_create_collation16(db &Sqlite3, z_name voidptr, enc int, p_ctx voidptr, x_compare fn (voidptr, int, voidptr, int, voidptr) int) int {
	c2v_gc_register_thread()
	rc := 0
	z_name8 := &i8(0)
	sqlite3_mutex_enter(db.mutex)
	z_name8 = sqlite3_utf16to8(db, voidptr(z_name), -1, U8(2))
	if z_name8 {
		rc = create_collation(db, z_name8, U8(enc), voidptr(p_ctx), x_compare, unsafe { nil })
		sqlite3_db_free(db, voidptr(z_name8))
	}
	rc = sqlite3_api_exit(db, rc)
	sqlite3_mutex_leave(db.mutex)
	return rc
}

fn sqlite3_collation_needed(db &Sqlite3, p_coll_needed_arg voidptr, x_coll_needed fn (voidptr, &Sqlite3, int, &i8)) int {
	c2v_gc_register_thread()
	sqlite3_mutex_enter(db.mutex)
	db.xCollNeeded = x_coll_needed
	db.xCollNeeded16 = 0
	db.pCollNeededArg = p_coll_needed_arg
	sqlite3_mutex_leave(db.mutex)
	return 0
}

fn sqlite3_collation_needed16(db &Sqlite3, p_coll_needed_arg voidptr, x_coll_needed16 fn (voidptr, &Sqlite3, int, voidptr)) int {
	c2v_gc_register_thread()
	sqlite3_mutex_enter(db.mutex)
	db.xCollNeeded = 0
	db.xCollNeeded16 = x_coll_needed16
	db.pCollNeededArg = p_coll_needed_arg
	sqlite3_mutex_leave(db.mutex)
	return 0
}

fn sqlite3_get_clientdata(db &Sqlite3, z_name &i8) voidptr {
	c2v_gc_register_thread()
	p := &DbClientData(0)
	sqlite3_mutex_enter(db.mutex)
	for p = db.pDbData; p; p = p.pNext {
		if C.strcmp(unsafe { &i8(&p.zName[0]) }, z_name) == 0 {
			p_result := p.pData
			sqlite3_mutex_leave(db.mutex)
			return p_result
		}
	}
	sqlite3_mutex_leave(db.mutex)
	return unsafe { nil }
}

fn sqlite3_set_clientdata(db &Sqlite3, z_name &i8, p_data voidptr, x_destructor fn (voidptr)) int {
	c2v_gc_register_thread()
	p := &DbClientData(0)
	pp := &&DbClientData(0)

	sqlite3_mutex_enter(db.mutex)
	pp = &db.pDbData
	for p = db.pDbData; !isnil(p) && C.strcmp(unsafe { &i8(&p.zName[0]) }, z_name); p = p.pNext {
		pp = &p.pNext
	}
	if p {
		if p.xDestructor {
			p.xDestructor(voidptr(p.pData))
		}
		if usize(p_data) == usize(0) {
			unsafe { *pp = p.pNext }
			sqlite3_free(voidptr(p))
			sqlite3_mutex_leave(db.mutex)
			return 0
		}
	} else if usize(p_data) == usize(0) {
		sqlite3_mutex_leave(db.mutex)
		return 0
	} else {
		n := C.strlen(z_name)
		p = sqlite3_malloc64(Sqlite3_uint64(((u64(usize(__offsetof(DbClientData, zName)))) + (n + usize(1)))))
		if usize(p) == usize(0) {
			if x_destructor {
				x_destructor(voidptr(p_data))
			}
			sqlite3_mutex_leave(db.mutex)
			return 7
		}
		C.memcpy(p.zName, voidptr(z_name), n + usize(1))
		p.pNext = db.pDbData
		db.pDbData = p
	}
	p.pData = p_data
	p.xDestructor = x_destructor
	sqlite3_mutex_leave(db.mutex)
	return 0
}

fn sqlite3_global_recover() int {
	return 0
}

fn sqlite3_get_autocommit(db &Sqlite3) int {
	c2v_gc_register_thread()
	i_ret := 0
	sqlite3_mutex_enter(db.mutex)
	i_ret = int(db.autoCommit)
	sqlite3_mutex_leave(db.mutex)
	return i_ret
}

@[c:'sqlite3ReportError']
fn sqlite3_report_error(i_err int, lineno int, z_type &i8) int {
	sqlite3_log(i_err, c'%s at line %d of [%.10s]', voidptr(z_type), lineno, voidptr(unsafe { sqlite3_sourceid() + (20) }))
	return i_err
}

@[c:'sqlite3CorruptError']
fn sqlite3_corrupt_error(lineno int) int {
	return sqlite3_report_error(11, lineno, c'database corruption')
}

@[c:'sqlite3MisuseError']
fn sqlite3_misuse_error(lineno int) int {
	return sqlite3_report_error(21, lineno, c'misuse')
}

@[c:'sqlite3CantopenError']
fn sqlite3_cantopen_error(lineno int) int {
	return sqlite3_report_error(14, lineno, c'cannot open file')
}

fn sqlite3_thread_cleanup() {
	c2v_gc_register_thread()
}

fn sqlite3_table_column_metadata(db &Sqlite3, z_db_name &i8, z_table_name &i8, z_column_name &i8, pz_data_type &&u8, pz_coll_seq &&u8, p_not_null &int, p_primary_key &int, p_autoinc &int) int {
	c2v_gc_register_thread()
	rc := 0
	z_err_msg := unsafe { &i8(nil) }
	p_tab := unsafe { &Table(nil) }
	p_col := unsafe { &Column(nil) }
	i_col := 0
	z_data_type := unsafe { &i8(nil) }
	z_coll_seq := unsafe { &i8(nil) }
	notnull := 0
	primarykey := 0
	autoinc := 0
	sqlite3_mutex_enter(db.mutex)
	sqlite3_btree_enter_all(db)
	rc = sqlite3_init(db, &&u8(&&i8(c2v_address_of(&z_err_msg))))
	if 0 != rc {
		unsafe { goto error_out
		 }
	}
	p_tab = sqlite3_find_table(db, z_table_name, z_db_name)
	if isnil(p_tab) || (int(p_tab.eTabType) == 2) {
		p_tab = 0
		unsafe { goto error_out
		 }
	}
	if usize(z_column_name) == usize(0) {
	} else {
		i_col = sqlite3_column_index(p_tab, z_column_name)
		if i_col >= 0 {
			p_col = unsafe { p_tab.aCol + i_col }
		} else {
			if ((p_tab.tabFlags & u32(128)) == u32(0)) && sqlite3_is_rowid(z_column_name) {
				i_col = int(p_tab.iPKey)
				p_col = unsafe { if i_col >= 0 { p_tab.aCol + i_col } else { &Column(nil) } }
			} else {
				p_tab = 0
				unsafe { goto error_out
				 }
			}
		}
	}
	if p_col {
		z_data_type = sqlite3_column_type_vdup1(p_col, unsafe { nil })
		z_coll_seq = sqlite3_column_coll(p_col)
		notnull = int(p_col.notNull) != 0
		primarykey = (int(p_col.colFlags) & 1) != 0
		autoinc = int(p_tab.iPKey) == i_col && (p_tab.tabFlags & u32(8)) != u32(0)
	} else {
		z_data_type = c'INTEGER'
		primarykey = 1
	}
	if isnil(z_coll_seq) {
		z_coll_seq = unsafe { &sqlite3StrBINARY[0] }
	}
	error_out:
	sqlite3_btree_leave_all(db)
	if pz_data_type {
		unsafe { *pz_data_type = z_data_type }
	}
	if pz_coll_seq {
		unsafe { *pz_coll_seq = z_coll_seq }
	}
	if p_not_null {
		unsafe { *p_not_null = notnull }
	}
	if p_primary_key {
		unsafe { *p_primary_key = primarykey }
	}
	if p_autoinc {
		unsafe { *p_autoinc = autoinc }
	}
	if 0 == rc && isnil(p_tab) {
		sqlite3_db_free(db, voidptr(z_err_msg))
		z_err_msg = sqlite3_mp_rintf(db, c'no such table column: %s.%s', voidptr(z_table_name), voidptr(z_column_name))
		rc = 1
	}
	sqlite3_error_with_msg(db, rc, unsafe { if z_err_msg { c'%s' } else { &i8(nil) } }, voidptr(z_err_msg))
	sqlite3_db_free(db, voidptr(z_err_msg))
	rc = sqlite3_api_exit(db, rc)
	sqlite3_mutex_leave(db.mutex)
	return rc
}

fn sqlite3_sleep(ms int) int {
	c2v_gc_register_thread()
	p_vfs := &Sqlite3_vfs(0)
	rc := 0
	p_vfs = sqlite3_vfs_find(unsafe { nil })
	if usize(p_vfs) == usize(0) {
		return 0
	}
	rc = (sqlite3_os_sleep(p_vfs, if ms < 0 { 0 } else { 1000 * ms }) / 1000)
	return rc
}

fn sqlite3_extended_result_codes(db &Sqlite3, onoff int) int {
	c2v_gc_register_thread()
	sqlite3_mutex_enter(db.mutex)
	db.errMask = int(if onoff { u32(4294967295) } else { u32(255) })
	sqlite3_mutex_leave(db.mutex)
	return 0
}

fn sqlite3_file_control(db &Sqlite3, z_db_name &i8, op int, p_arg voidptr) int {
	c2v_gc_register_thread()
	rc := 1
	p_btree := &Btree(0)
	sqlite3_mutex_enter(db.mutex)
	p_btree = sqlite3_db_name_to_btree(db, z_db_name)
	if p_btree {
		p_pager := &Pager(0)
		fd := &Sqlite3_file(0)
		sqlite3_btree_enter(p_btree)
		p_pager = sqlite3_btree_pager(p_btree)
		fd = sqlite3_pager_file(p_pager)
		if op == 7 {
			mut __c2v_lhs_tmp_182 := unsafe { &&Sqlite3_file(p_arg) }
			unsafe { *__c2v_lhs_tmp_182 = fd }
			rc = 0
		} else if op == 27 {
			mut __c2v_lhs_tmp_183 := unsafe { &&Sqlite3_vfs(p_arg) }
			unsafe { *__c2v_lhs_tmp_183 = sqlite3_pager_vfs(p_pager) }
			rc = 0
		} else if op == 28 {
			mut __c2v_lhs_tmp_184 := unsafe { &&Sqlite3_file(p_arg) }
			unsafe { *__c2v_lhs_tmp_184 = sqlite3_pager_jrnl_file(p_pager) }
			rc = 0
		} else if op == 35 {
			mut __c2v_lhs_tmp_185 := unsafe { &u32(p_arg) }
			unsafe { *__c2v_lhs_tmp_185 = sqlite3_pager_data_version(p_pager) }
			rc = 0
		} else if op == 38 {
			i_new := (unsafe { *&int(p_arg) })
			mut __c2v_lhs_tmp_186 := unsafe { &int(p_arg) }
			unsafe { *__c2v_lhs_tmp_186 = sqlite3_btree_get_requested_reserve(p_btree) }
			if i_new >= 0 && i_new <= 255 {
				sqlite3_btree_set_page_size(p_btree, 0, i_new, 0)
			}
			rc = 0
		} else if op == 42 {
			sqlite3_btree_clear_cache(p_btree)
			rc = 0
		} else {
			n_save := db.busyHandler.nBusy
			rc = sqlite3_os_file_control(fd, op, voidptr(p_arg))
			db.busyHandler.nBusy = n_save
		}
		sqlite3_btree_leave(p_btree)
	}
	sqlite3_mutex_leave(db.mutex)
	return rc
}

@[c2v_variadic]
fn sqlite3_test_control(op int, ...) int {
	c2v_gc_register_thread()
	rc := 0
	ap := C.va_list{}
	C.va_start(ap, op)
	match op {
		5 {
			sqlite3_prng_save_state()
		}
		6 {
			sqlite3_prng_restore_state()
		}
		28 {
			x := C.va_arg(int, ap)
			y := 0
			db := C.va_arg(&Sqlite3, ap)
			if !isnil(db) && c2v_assign[int](unsafe { &y }, int(db.aDb[0].pSchema.schema_cookie)) != 0 {
				x = y
			}
			sqlite3Config.iPrngSeed = u32(x)
			sqlite3_randomness(0, unsafe { nil })
		}
		7 {
			db := C.va_arg(&Sqlite3, ap)
			b := C.va_arg(int, ap)
			if b {
				db.flags |= (U64(8) << 32)
			} else {
				db.flags &= ~(U64(8) << 32)
			}
		}
		8 {
			sz := C.va_arg(int, ap)
			a_prog := C.va_arg(&int, ap)
			rc = sqlite3_bitvec_builtin_test(sz, a_prog)
		}
		9 {
			sqlite3Config.xTestCallback = C.va_arg(Sqlite3FaultFuncType, ap)
			rc = sqlite3_fault_sim(0)
		}
		10 {
			x_benign_begin := unsafe { Void_function(nil) }
			x_benign_end := unsafe { Void_function(nil) }
			x_benign_begin = C.va_arg(Void_function, ap)
			x_benign_end = C.va_arg(Void_function, ap)
			sqlite3_benign_malloc_hooks(x_benign_begin, x_benign_end)
		}
		11 {
			rc = sqlite3PendingByte
			new_val := C.va_arg(u32, ap)
			if new_val {
				sqlite3PendingByte = int(new_val)
			}
		}
		12 {
			x := 0
			rc = x
		}
		13 {
			x := C.va_arg(int, ap)
			rc = if x { x } else { 0 }
		}
		22 {
			rc = 1234 * 100 + 1 * 10 + 0
		}
		15 {
			db := C.va_arg(&Sqlite3, ap)
			db.dbOptFlags = C.va_arg(u32, ap)
		}
		16 {
			db := C.va_arg(&Sqlite3, ap)
			pn := C.va_arg(&int, ap)
			unsafe { *pn = int(db.dbOptFlags) }
		}
		18 {
			sqlite3Config.bLocaltimeFault = C.va_arg(int, ap)
			if sqlite3Config.bLocaltimeFault == 2 {
				sqlite3Config.xAltLocaltime = C.va_arg(Sqlite3LocaltimeType, ap)
			} else {
				sqlite3Config.xAltLocaltime = 0
			}
		}
		17 {
			db := C.va_arg(&Sqlite3, ap)
			db.mDbFlags ^= u32(32)
		}
		20 {
			sqlite3Config.neverCorrupt = C.va_arg(int, ap)
		}
		29 {
			sqlite3Config.bExtraSchemaChecks = U8(C.va_arg(int, ap))
		}
		19 {
			sqlite3Config.iOnceResetThreshold = C.va_arg(int, ap)
		}
		21 {
		}
		24 {
			db := C.va_arg(&Sqlite3, ap)
			db.nMaxSorterMmap = C.va_arg(int, ap)
		}
		23 {
			if sqlite3Config.isInit == 0 {
				rc = 1
			}
		}
		25 {
			db := C.va_arg(&Sqlite3, ap)
			i_db := 0
			sqlite3_mutex_enter(db.mutex)
			i_db = sqlite3_find_db_name(db, C.va_arg(&i8, ap))
			if i_db >= 0 {
				db.init.iDb = U8(i_db)
				db.init.imposterTable = u32(C.va_arg(int, ap))
				db.init.busy = db.init.imposterTable
				db.init.newTnum = Pgno(C.va_arg(int, ap))
				if int(db.init.busy) == 0 && db.init.newTnum > Pgno(0) {
					sqlite3_reset_all_schemas_of_connection(db)
				}
			}
			sqlite3_mutex_leave(db.mutex)
		}
		27 {
			p_ctx := C.va_arg(&Sqlite3_context, ap)
			sqlite3_result_int_real(p_ctx)
		}
		30 {
			db := C.va_arg(&Sqlite3, ap)
			pn := C.va_arg(&Sqlite3_uint64, ap)
			unsafe { *pn = U64(0) }
		}
		31 {
			op_trace := C.va_arg(int, ap)
			ptr := C.va_arg(&u32, ap)
			match op_trace {
				0 {
					unsafe { *ptr = sqlite3TreeTrace }
				}
				1 {
					sqlite3TreeTrace = unsafe { *ptr }
				}
				2 {
					unsafe { *ptr = sqlite3WhereTrace }
				}
				3 {
					sqlite3WhereTrace = unsafe { *ptr }
				}
				else {}
			}
		}
		33 {
			r_in := C.va_arg(f64, ap)
			r_log_est := sqlite3_log_est_from_double(r_in)
			p_i1 := C.va_arg(&int, ap)
			p_u64 := C.va_arg(&U64, ap)
			p_i2 := C.va_arg(&int, ap)
			unsafe { *p_i1 = int(r_log_est) }
			unsafe { *p_u64 = sqlite3_log_est_to_int(r_log_est) }
			unsafe { *p_i2 = int(sqlite3_log_est(*p_u64)) }
		}
		34 {
			z := C.va_arg(&i8, ap)
			pr := C.va_arg(&f64, ap)
			rc = sqlite3_ato_f(z, pr)
		}
		14 {
		}
		else {}
	}

	C.va_end(ap)
	return rc
}

@[c:'databaseName']
fn database_name(z_name &i8) &i8 {
	for int(z_name[-1]) != 0 || int(z_name[-2]) != 0 || int(z_name[-3]) != 0 || int(z_name[-4]) != 0 {
		c2v_pointer_postfix(voidptr(&z_name), z_name, isize(-1))
	}
	return z_name
}

@[c:'appendText']
fn append_text(p &i8, z &i8) &i8 {
	n := C.strlen(z)
	C.memcpy(voidptr(p), voidptr(z), n + usize(1))
	return p + n + 1
}

fn sqlite3_create_filename(z_database &i8, z_journal &i8, z_wal &i8, n_param int, az_param &&u8) Sqlite3_filename {
	c2v_gc_register_thread()
	n_byte := Sqlite3_int64(0)
	i := 0
	p_result := &i8(0)
	p := &i8(0)

	n_byte = Sqlite3_int64(C.strlen(z_database) + C.strlen(z_journal) + C.strlen(z_wal) + u64(10))
	for i = 0; i < n_param * 2; i++ {
		n_byte += C.strlen(az_param[i]) + u64(1)
	}
	p = &i8(sqlite3_malloc64(Sqlite3_uint64(n_byte)))
	p_result = p
	if usize(p) == usize(0) {
		return unsafe { nil }
	}
	C.memset(voidptr(p), 0, u64(4))
	c2v_pointer_prefix(voidptr(&p), p, isize(4))
	p = append_text(p, z_database)
	for i = 0; i < n_param * 2; i++ {
		p = append_text(p, az_param[i])
	}
	mut __c2v_lhs_tmp_187 := unsafe { c2v_pointer_postfix(voidptr(&p), p, isize(1)) }
	unsafe { *__c2v_lhs_tmp_187 = i8(0) }
	p = append_text(p, z_journal)
	p = append_text(p, z_wal)
	mut __c2v_lhs_tmp_188 := unsafe { c2v_pointer_postfix(voidptr(&p), p, isize(1)) }
	unsafe { *__c2v_lhs_tmp_188 = i8(0) }
	mut __c2v_lhs_tmp_189 := unsafe { c2v_pointer_postfix(voidptr(&p), p, isize(1)) }
	unsafe { *__c2v_lhs_tmp_189 = i8(0) }
	return p_result + 4
}

fn sqlite3_free_filename(p &i8) {
	c2v_gc_register_thread()
	if usize(p) == usize(0) {
		return
	}
	p = database_name(p)
	sqlite3_free(voidptr(&i8(p) - 4))
}

fn sqlite3_uri_parameter(z_filename &i8, z_param &i8) &i8 {
	c2v_gc_register_thread()
	if usize(z_filename) == usize(0) || usize(z_param) == usize(0) {
		return unsafe { nil }
	}
	z_filename = database_name(z_filename)
	return uri_parameter(z_filename, z_param)
}

fn sqlite3_uri_key(z_filename &i8, n int) &i8 {
	c2v_gc_register_thread()
	if usize(z_filename) == usize(0) || n < 0 {
		return unsafe { nil }
	}
	z_filename = database_name(z_filename)
	c2v_pointer_prefix(voidptr(&z_filename), z_filename, isize(sqlite3_strlen30(z_filename) + 1))
	for !isnil(z_filename) && int(z_filename[0]) && (n--) > 0 {
		c2v_pointer_prefix(voidptr(&z_filename), z_filename, isize(sqlite3_strlen30(z_filename) + 1))
		c2v_pointer_prefix(voidptr(&z_filename), z_filename, isize(sqlite3_strlen30(z_filename) + 1))
	}
	return unsafe { if int(z_filename[0]) { z_filename } else { &i8(nil) } }
}

fn sqlite3_uri_boolean(z_filename &i8, z_param &i8, b_dflt int) int {
	c2v_gc_register_thread()
	z := sqlite3_uri_parameter(z_filename, z_param)
	b_dflt = b_dflt != 0
	return if z { int(sqlite3_get_boolean(z, U8(b_dflt))) } else { b_dflt }
}

fn sqlite3_uri_int64(z_filename &i8, z_param &i8, b_dflt Sqlite3_int64) Sqlite3_int64 {
	c2v_gc_register_thread()
	z := sqlite3_uri_parameter(z_filename, z_param)
	v := Sqlite3_int64(0)
	if !isnil(z) && sqlite3_dec_or_hex_to_i64(z, unsafe { &I64(&v) }) == 0 {
		b_dflt = v
	}
	return b_dflt
}

fn sqlite3_filename_database(z_filename &i8) &i8 {
	c2v_gc_register_thread()
	if usize(z_filename) == usize(0) {
		return unsafe { nil }
	}
	return database_name(z_filename)
}

fn sqlite3_filename_journal(z_filename &i8) &i8 {
	c2v_gc_register_thread()
	if usize(z_filename) == usize(0) {
		return unsafe { nil }
	}
	z_filename = database_name(z_filename)
	c2v_pointer_prefix(voidptr(&z_filename), z_filename, isize(sqlite3_strlen30(z_filename) + 1))
	for !isnil(z_filename) && int(z_filename[0]) {
		c2v_pointer_prefix(voidptr(&z_filename), z_filename, isize(sqlite3_strlen30(z_filename) + 1))
		c2v_pointer_prefix(voidptr(&z_filename), z_filename, isize(sqlite3_strlen30(z_filename) + 1))
	}
	return z_filename + 1
}

fn sqlite3_filename_wal(z_filename &i8) &i8 {
	c2v_gc_register_thread()
	z_filename = sqlite3_filename_journal(z_filename)
	if z_filename {
		c2v_pointer_prefix(voidptr(&z_filename), z_filename, isize(sqlite3_strlen30(z_filename) + 1))
	}
	return z_filename
}

@[c:'sqlite3DbNameToBtree']
fn sqlite3_db_name_to_btree(db &Sqlite3, z_db_name &i8) &Btree {
	i_db := if z_db_name { sqlite3_find_db_name(db, z_db_name) } else { 0 }
	return unsafe { if i_db < 0 { &Btree(nil) } else { db.aDb[i_db].pBt } }
}

fn sqlite3_db_name(db &Sqlite3, n int) &i8 {
	c2v_gc_register_thread()
	z_ret := unsafe { &i8(nil) }
	sqlite3_mutex_enter(db.mutex)
	if n >= 0 && n < db.nDb {
		z_ret = db.aDb[n].zDbSName
	}
	sqlite3_mutex_leave(db.mutex)
	return z_ret
}

fn sqlite3_db_filename(db &Sqlite3, z_db_name &i8) Sqlite3_filename {
	c2v_gc_register_thread()
	p_bt := &Btree(0)
	p_bt = sqlite3_db_name_to_btree(db, z_db_name)
	return unsafe { if p_bt { sqlite3_btree_get_filename(p_bt) } else { &i8(nil) } }
}

fn sqlite3_db_readonly(db &Sqlite3, z_db_name &i8) int {
	c2v_gc_register_thread()
	p_bt := &Btree(0)
	p_bt = sqlite3_db_name_to_btree(db, z_db_name)
	return if p_bt { sqlite3_btree_is_readonly(p_bt) } else { -1 }
}

fn sqlite3_compileoption_used(z_opt_name &i8) int {
	c2v_gc_register_thread()
	i := 0
	n := 0

	n_opt := 0
	az_compile_opt := &&u8(0)
	az_compile_opt = sqlite3_compile_options(&n_opt)
	if sqlite3_strnicmp(z_opt_name, c'SQLITE_', 7) == 0 {
		c2v_pointer_prefix(voidptr(&z_opt_name), z_opt_name, isize(7))
	}
	n = sqlite3_strlen30(z_opt_name)
	for i = 0; i < n_opt; i++ {
		if sqlite3_strnicmp(z_opt_name, az_compile_opt[i], n) == 0 && sqlite3_is_id_char(u8(az_compile_opt[i][n])) == 0 {
			return 1
		}
	}
	return 0
}

fn sqlite3_compileoption_get(n int) &i8 {
	c2v_gc_register_thread()
	n_opt := 0
	az_compile_opt := &&u8(0)
	az_compile_opt = sqlite3_compile_options(&n_opt)
	if n >= 0 && n < n_opt {
		return az_compile_opt[n]
	}
	return unsafe { nil }
}
