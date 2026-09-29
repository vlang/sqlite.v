@[translated]
module main

fn sqlite3_release_memory(n int) int {
	c2v_gc_register_thread()

	return 0
}

struct Mem0Global {
	mutex          &Sqlite3_mutex
	alarmThreshold Sqlite3_int64
	hardLimit      Sqlite3_int64
	nearlyFull     int
}

@[c:'sqlite3MallocMutex']
fn sqlite3_malloc_mutex() &Sqlite3_mutex {
	return mem0.mutex
}

fn sqlite3_memory_alarm(x_callback fn (voidptr, Sqlite3_int64, int), p_arg voidptr, i_threshold Sqlite3_int64) int {
	return 0
}

fn sqlite3_soft_heap_limit64(n Sqlite3_int64) Sqlite3_int64 {
	c2v_gc_register_thread()
	prior_limit := Sqlite3_int64(0)
	excess := Sqlite3_int64(0)
	n_used := Sqlite3_int64(0)
	rc := sqlite3_initialize()
	if rc {
		return Sqlite3_int64(-1)
	}
	sqlite3_mutex_enter(mem0.mutex)
	prior_limit = mem0.alarmThreshold
	if n < Sqlite3_int64(0) {
		sqlite3_mutex_leave(mem0.mutex)
		return prior_limit
	}
	if mem0.hardLimit > Sqlite3_int64(0) && (n > mem0.hardLimit || n == Sqlite3_int64(0)) {
		n = mem0.hardLimit
	}
	mem0.alarmThreshold = n
	n_used = sqlite3_status_value(0)
	C.c2v_atomic_store_n__int_int_int_((&mem0.nearlyFull), (n > Sqlite3_int64(0) && n <= n_used), 0)
	sqlite3_mutex_leave(mem0.mutex)
	excess = sqlite3_memory_used() - n
	if excess > Sqlite3_int64(0) {
		sqlite3_release_memory(int((excess & Sqlite3_int64(2147483647))))
	}
	return prior_limit
}

fn sqlite3_soft_heap_limit(n int) {
	c2v_gc_register_thread()
	if n < 0 {
		n = 0
	}
	sqlite3_soft_heap_limit64(Sqlite3_int64(n))
}

fn sqlite3_hard_heap_limit64(n Sqlite3_int64) Sqlite3_int64 {
	c2v_gc_register_thread()
	prior_limit := Sqlite3_int64(0)
	rc := sqlite3_initialize()
	if rc {
		return Sqlite3_int64(-1)
	}
	sqlite3_mutex_enter(mem0.mutex)
	prior_limit = mem0.hardLimit
	if n >= Sqlite3_int64(0) {
		mem0.hardLimit = n
		if n < mem0.alarmThreshold || mem0.alarmThreshold == Sqlite3_int64(0) {
			mem0.alarmThreshold = n
		}
	}
	sqlite3_mutex_leave(mem0.mutex)
	return prior_limit
}

@[c:'sqlite3MallocInit']
fn sqlite3_malloc_init() int {
	rc := 0
	if isnil(sqlite3Config.m.xMalloc) {
		sqlite3_mem_set_default()
	}
	mem0.mutex = sqlite3_mutex_alloc_vdup4(3)
	if usize(sqlite3Config.pPage) == usize(0) || sqlite3Config.szPage < 512 || sqlite3Config.nPage <= 0 {
		sqlite3Config.pPage = 0
		sqlite3Config.szPage = 0
	}
	rc = sqlite3Config.m.xInit(voidptr(sqlite3Config.m.pAppData))
	if rc != 0 {
		C.memset(voidptr(&mem0), 0, sizeof(mem0))
	}
	return rc
}

@[c:'sqlite3HeapNearlyFull']
fn sqlite3_heap_nearly_full() int {
	return C.c2v_atomic_load_n__int_int_int((&mem0.nearlyFull), 0)
}

@[c:'sqlite3MallocEnd']
fn sqlite3_malloc_end() {
	if sqlite3Config.m.xShutdown {
		sqlite3Config.m.xShutdown(voidptr(sqlite3Config.m.pAppData))
	}
	C.memset(voidptr(&mem0), 0, sizeof(mem0))
}

fn sqlite3_memory_used() Sqlite3_int64 {
	c2v_gc_register_thread()
	res := Sqlite3_int64(0)
	mx := Sqlite3_int64(0)

	sqlite3_status64(0, &res, &mx, 0)
	return res
}

fn sqlite3_memory_highwater(reset_flag int) Sqlite3_int64 {
	c2v_gc_register_thread()
	res := Sqlite3_int64(0)
	mx := Sqlite3_int64(0)

	sqlite3_status64(0, &res, &mx, reset_flag)
	return mx
}

@[c:'sqlite3MallocAlarm']
fn sqlite3_malloc_alarm(n_byte int) {
	if mem0.alarmThreshold <= Sqlite3_int64(0) {
		return
	}
	sqlite3_mutex_leave(mem0.mutex)
	sqlite3_release_memory(n_byte)
	sqlite3_mutex_enter(mem0.mutex)
}

@[c:'mallocWithAlarm']
fn malloc_with_alarm(n int, pp &voidptr) {
	p := &voidptr(0)
	n_full := 0
	n_full = sqlite3Config.m.xRoundup(n)
	sqlite3_status_highwater(5, n)
	if mem0.alarmThreshold > Sqlite3_int64(0) {
		n_used := sqlite3_status_value(0)
		if n_used >= mem0.alarmThreshold - Sqlite3_int64(n_full) {
			C.c2v_atomic_store_n__int_int_int_((&mem0.nearlyFull), 1, 0)
			sqlite3_malloc_alarm(n_full)
			if mem0.hardLimit {
				n_used = sqlite3_status_value(0)
				if n_used >= mem0.hardLimit - Sqlite3_int64(n_full) {
					0
					unsafe { *pp = 0 }
					return
				}
			}
		} else {
			C.c2v_atomic_store_n__int_int_int_((&mem0.nearlyFull), 0, 0)
		}
	}
	p = sqlite3Config.m.xMalloc(n_full)
	if p {
		n_full = sqlite3_malloc_size(voidptr(p))
		sqlite3_status_up(0, n_full)
		sqlite3_status_up(9, 1)
	}
	unsafe { *pp = p }
}

@[c:'sqlite3Malloc']
fn sqlite3_malloc_vdup2(n U64) voidptr {
	p := &voidptr(0)
	if n == U64(0) || n > U64(2147483391) {
		p = 0
	} else if sqlite3Config.bMemstat {
		sqlite3_mutex_enter(mem0.mutex)
		malloc_with_alarm(int(n), &p)
		sqlite3_mutex_leave(mem0.mutex)
	} else {
		p = sqlite3Config.m.xMalloc(int(n))
	}
	return p
}

fn sqlite3_malloc(n int) voidptr {
	c2v_gc_register_thread()
	if sqlite3_initialize() {
		return unsafe { nil }
	}
	return voidptr(unsafe { if n <= 0 { &u8(nil) } else { &u8(sqlite3_malloc_vdup2(U64(n))) } })
}

fn sqlite3_malloc64(n Sqlite3_uint64) voidptr {
	c2v_gc_register_thread()
	if sqlite3_initialize() {
		return unsafe { nil }
	}
	return sqlite3_malloc_vdup2(n)
}

@[c:'isLookaside']
fn is_lookaside(db &Sqlite3, p voidptr) int {
	return int(((Uptr(p) >= Uptr(db.lookaside.pStart)) && (Uptr(p) < Uptr(db.lookaside.pTrueEnd))))
}

@[c:'sqlite3MallocSize']
fn sqlite3_malloc_size(p voidptr) int {
	return sqlite3Config.m.xSize(voidptr(p))
}

@[c:'lookasideMallocSize']
fn lookaside_malloc_size(db &Sqlite3, p voidptr) int {
	return if usize(p) < usize(db.lookaside.pMiddle) { int(db.lookaside.szTrue) } else { 128 }
}

@[c:'sqlite3DbMallocSize']
fn sqlite3_db_malloc_size(db &Sqlite3, p voidptr) int {
	if db {
		if (Uptr(p)) < Uptr(db.lookaside.pTrueEnd) {
			if (Uptr(p)) >= Uptr(db.lookaside.pMiddle) {
				return 128
			}
			if (Uptr(p)) >= Uptr(db.lookaside.pStart) {
				return int(db.lookaside.szTrue)
			}
		}
	}
	return sqlite3Config.m.xSize(voidptr(p))
}

fn sqlite3_msize(p voidptr) Sqlite3_uint64 {
	c2v_gc_register_thread()
	return Sqlite3_uint64(if p { sqlite3Config.m.xSize(voidptr(p)) } else { 0 })
}

fn sqlite3_free(p voidptr) {
	c2v_gc_register_thread()
	if usize(p) == usize(0) {
		return
	}
	if sqlite3Config.bMemstat {
		sqlite3_mutex_enter(mem0.mutex)
		sqlite3_status_down(0, sqlite3_malloc_size(voidptr(p)))
		sqlite3_status_down(9, 1)
		sqlite3Config.m.xFree(voidptr(p))
		sqlite3_mutex_leave(mem0.mutex)
	} else {
		sqlite3Config.m.xFree(voidptr(p))
	}
}

@[c:'measureAllocationSize']
fn measure_allocation_size(db &Sqlite3, p voidptr) {
	unsafe { *db.pnBytesFreed += sqlite3_db_malloc_size(db, voidptr(p)) }
}

@[c:'sqlite3DbFreeNN']
fn sqlite3_db_free_nn(db &Sqlite3, p voidptr) {
	if db {
		if (Uptr(p)) < Uptr(db.lookaside.pEnd) {
			if (Uptr(p)) >= Uptr(db.lookaside.pMiddle) {
				p_buf := &LookasideSlot(p)
				p_buf.pNext = db.lookaside.pSmallFree
				db.lookaside.pSmallFree = p_buf
				return
			}
			if (Uptr(p)) >= Uptr(db.lookaside.pStart) {
				p_buf := &LookasideSlot(p)
				p_buf.pNext = db.lookaside.pFree
				db.lookaside.pFree = p_buf
				return
			}
		}
		if db.pnBytesFreed {
			measure_allocation_size(db, voidptr(p))
			return
		}
	}
	0
	sqlite3_free(voidptr(p))
}

@[c:'sqlite3DbNNFreeNN']
fn sqlite3_db_nn_free_nn(db &Sqlite3, p voidptr) {
	if (Uptr(p)) < Uptr(db.lookaside.pEnd) {
		if (Uptr(p)) >= Uptr(db.lookaside.pMiddle) {
			p_buf := &LookasideSlot(p)
			p_buf.pNext = db.lookaside.pSmallFree
			db.lookaside.pSmallFree = p_buf
			return
		}
		if (Uptr(p)) >= Uptr(db.lookaside.pStart) {
			p_buf := &LookasideSlot(p)
			p_buf.pNext = db.lookaside.pFree
			db.lookaside.pFree = p_buf
			return
		}
	}
	if db.pnBytesFreed {
		measure_allocation_size(db, voidptr(p))
		return
	}
	0
	sqlite3_free(voidptr(p))
}

@[c:'sqlite3DbFree']
fn sqlite3_db_free(db &Sqlite3, p voidptr) {
	c2v_gc_register_thread()
	if p {
		sqlite3_db_free_nn(db, voidptr(p))
	}
}

@[c:'sqlite3Realloc']
fn sqlite3_realloc_vdup3(p_old voidptr, n_bytes U64) voidptr {
	n_old := 0
	n_new := 0
	n_diff := 0

	p_new := &voidptr(0)
	if usize(p_old) == usize(0) {
		return sqlite3_malloc_vdup2(n_bytes)
	}
	if n_bytes == U64(0) {
		sqlite3_free(voidptr(p_old))
		return unsafe { nil }
	}
	if n_bytes > U64(2147483391) {
		return unsafe { nil }
	}
	n_old = sqlite3_malloc_size(voidptr(p_old))
	n_new = sqlite3Config.m.xRoundup(int(n_bytes))
	if n_old == n_new {
		p_new = p_old
	} else if sqlite3Config.bMemstat {
		n_used := Sqlite3_int64(0)
		sqlite3_mutex_enter(mem0.mutex)
		sqlite3_status_highwater(5, int(n_bytes))
		n_diff = n_new - n_old
		if n_diff > 0 && c2v_assign[i64](unsafe { &n_used }, i64(sqlite3_status_value(0))) >= mem0.alarmThreshold - Sqlite3_int64(n_diff) {
			sqlite3_malloc_alarm(n_diff)
			if mem0.hardLimit > Sqlite3_int64(0) && n_used >= mem0.hardLimit - Sqlite3_int64(n_diff) {
				sqlite3_mutex_leave(mem0.mutex)
				0
				return unsafe { nil }
			}
		}
		p_new = sqlite3Config.m.xRealloc(voidptr(p_old), n_new)
		if p_new {
			n_new = sqlite3_malloc_size(voidptr(p_new))
			sqlite3_status_up(0, n_new - n_old)
		}
		sqlite3_mutex_leave(mem0.mutex)
	} else {
		p_new = sqlite3Config.m.xRealloc(voidptr(p_old), n_new)
	}
	return p_new
}

fn sqlite3_realloc(p_old voidptr, n int) voidptr {
	c2v_gc_register_thread()
	if sqlite3_initialize() {
		return unsafe { nil }
	}
	if n < 0 {
		n = 0
	}
	return sqlite3_realloc_vdup3(voidptr(p_old), U64(n))
}

fn sqlite3_realloc64(p_old voidptr, n Sqlite3_uint64) voidptr {
	c2v_gc_register_thread()
	if sqlite3_initialize() {
		return unsafe { nil }
	}
	return sqlite3_realloc_vdup3(voidptr(p_old), n)
}

@[c:'sqlite3MallocZero']
fn sqlite3_malloc_zero(n U64) voidptr {
	p := sqlite3_malloc_vdup2(n)
	if p {
		C.memset(voidptr(p), 0, usize(n))
	}
	return p
}

@[c:'sqlite3DbMallocZero']
fn sqlite3_db_malloc_zero(db &Sqlite3, n U64) voidptr {
	p := &voidptr(0)
	0
	p = sqlite3_db_malloc_raw(db, n)
	if p {
		C.memset(voidptr(p), 0, usize(n))
	}
	return p
}

@[c:'dbMallocRawFinish']
fn db_malloc_raw_finish(db &Sqlite3, n U64) voidptr {
	p := &voidptr(0)
	p = sqlite3_malloc_vdup2(n)
	if isnil(p) {
		sqlite3_oom_fault(db)
	}
	0
	return p
}

@[c:'sqlite3DbMallocRaw']
fn sqlite3_db_malloc_raw(db &Sqlite3, n U64) voidptr {
	p := &voidptr(0)
	if db {
		return sqlite3_db_malloc_raw_nn(db, n)
	}
	p = sqlite3_malloc_vdup2(n)
	0
	return p
}

@[c:'sqlite3DbMallocRawNN']
fn sqlite3_db_malloc_raw_nn(db &Sqlite3, n U64) voidptr {
	p_buf := &LookasideSlot(0)
	if n > U64(db.lookaside.sz) {
		if !db.lookaside.bDisable {
			db.lookaside.anStat[1]++
		} else if db.mallocFailed {
			return unsafe { nil }
		}
		return db_malloc_raw_finish(db, n)
	}
	if n <= U64(128) {
		p_buf = db.lookaside.pSmallFree
		if usize(p_buf) != usize(0) {
			db.lookaside.pSmallFree = p_buf.pNext
			db.lookaside.anStat[0]++
			return voidptr(p_buf)
		} else {
			p_buf = db.lookaside.pSmallInit
			if usize(p_buf) != usize(0) {
				db.lookaside.pSmallInit = p_buf.pNext
				db.lookaside.anStat[0]++
				return voidptr(p_buf)
			}
		}
	}
	p_buf = db.lookaside.pFree
	if usize(p_buf) != usize(0) {
		db.lookaside.pFree = p_buf.pNext
		db.lookaside.anStat[0]++
		return voidptr(p_buf)
	} else {
		p_buf = db.lookaside.pInit
		if usize(p_buf) != usize(0) {
			db.lookaside.pInit = p_buf.pNext
			db.lookaside.anStat[0]++
			return voidptr(p_buf)
		} else {
			db.lookaside.anStat[2]++
		}
	}
	return db_malloc_raw_finish(db, n)
}

@[c:'sqlite3DbRealloc']
fn sqlite3_db_realloc(db &Sqlite3, p voidptr, n U64) voidptr {
	if usize(p) == usize(0) {
		return sqlite3_db_malloc_raw_nn(db, n)
	}
	if (Uptr(p)) < Uptr(db.lookaside.pEnd) {
		if (Uptr(p)) >= Uptr(db.lookaside.pMiddle) {
			if n <= U64(128) {
				return p
			}
		} else if (Uptr(p)) >= Uptr(db.lookaside.pStart) {
			if n <= U64(db.lookaside.szTrue) {
				return p
			}
		}
	}
	return db_realloc_finish(db, voidptr(p), n)
}

@[c:'dbReallocFinish']
fn db_realloc_finish(db &Sqlite3, p voidptr, n U64) voidptr {
	p_new := voidptr(0)
	if int(db.mallocFailed) == 0 {
		if is_lookaside(db, voidptr(p)) {
			p_new = sqlite3_db_malloc_raw_nn(db, n)
			if p_new {
				C.memcpy(voidptr(p_new), voidptr(p), u64(lookaside_malloc_size(db, voidptr(p))))
				sqlite3_db_free(db, voidptr(p))
			}
		} else {
			0
			p_new = sqlite3_realloc_vdup3(voidptr(p), n)
			if isnil(p_new) {
				sqlite3_oom_fault(db)
			}
			0
		}
	}
	return p_new
}

@[c:'sqlite3DbReallocOrFree']
fn sqlite3_db_realloc_or_free(db &Sqlite3, p voidptr, n U64) voidptr {
	p_new := &voidptr(0)
	p_new = sqlite3_db_realloc(db, voidptr(p), n)
	if isnil(p_new) {
		sqlite3_db_free(db, voidptr(p))
	}
	return p_new
}

@[c:'sqlite3DbStrDup']
fn sqlite3_db_str_dup(db &Sqlite3, z &i8) &i8 {
	z_new := &i8(0)
	n := usize(0)
	if usize(z) == usize(0) {
		return unsafe { nil }
	}
	n = C.strlen(z) + u64(1)
	z_new = &i8(sqlite3_db_malloc_raw(db, U64(n)))
	if z_new {
		C.memcpy(voidptr(z_new), voidptr(z), n)
	}
	return z_new
}

@[c:'sqlite3DbStrNDup']
fn sqlite3_db_str_nd_up(db &Sqlite3, z &i8, n U64) &i8 {
	z_new := &i8(0)
	z_new = &i8(voidptr(unsafe { if z {
		&u8(sqlite3_db_malloc_raw_nn(db, n + U64(1)))
	} else {
		&u8(nil)
	} }))
	if z_new {
		C.memcpy(voidptr(z_new), voidptr(z), usize(n))
		z_new[n] = i8(0)
	}
	return z_new
}

@[c:'sqlite3DbSpanDup']
fn sqlite3_db_span_dup(db &Sqlite3, z_start &i8, z_end &i8) &i8 {
	n := 0
	for (int(sqlite3CtypeMap[u8(z_start[0])]) & 1) {
		c2v_pointer_postfix(voidptr(&z_start), z_start, isize(1))
	}
	n = int((i64((isize(z_end) - isize(z_start)) / isize(sizeof(i8)))))
	for (int(sqlite3CtypeMap[u8(z_start[n - 1])]) & 1) {
		n--
	}
	return sqlite3_db_str_nd_up(db, z_start, U64(n))
}

@[c:'sqlite3SetString']
fn sqlite3_set_string(pz &&u8, db &Sqlite3, z_new &i8) {
	z := sqlite3_db_str_dup(db, z_new)
	sqlite3_db_free(db, voidptr((unsafe { *pz })))
	unsafe { *pz = z }
}

@[c:'sqlite3OomFault']
fn sqlite3_oom_fault(db &Sqlite3) voidptr {
	if int(db.mallocFailed) == 0 && int(db.bBenignMalloc) == 0 {
		db.mallocFailed = U8(1)
		if db.nVdbeExec > 0 {
			C.c2v_atomic_store_n__int_int_int_((&db.u1.isInterrupted), 1, 0)
		}
		db.lookaside.bDisable++
		db.lookaside.sz = U16(0)
		if db.pParse {
			p_parse := &Parse(0)
			sqlite3_error_msg(db.pParse, c'out of memory')
			db.pParse.rc = 7
			for p_parse = db.pParse.pOuterParse; p_parse; p_parse = p_parse.pOuterParse {
				p_parse.nErr++
				p_parse.rc = 7
			}
		}
	}
	return unsafe { nil }
}

@[c:'sqlite3OomClear']
fn sqlite3_oom_clear(db &Sqlite3) {
	if int(db.mallocFailed) && db.nVdbeExec == 0 {
		db.mallocFailed = U8(0)
		C.c2v_atomic_store_n__int_int_int_((&db.u1.isInterrupted), 0, 0)
		db.lookaside.bDisable--
		db.lookaside.sz = U16(if db.lookaside.bDisable { 0 } else { int(db.lookaside.szTrue) })
	}
}

@[c:'apiHandleError']
fn api_handle_error(db &Sqlite3, rc int) int {
	if int(db.mallocFailed) || rc == (10 | (12 << 8)) {
		sqlite3_oom_clear(db)
		sqlite3_error(db, 7)
		return 7
	}
	return rc & db.errMask
}

@[c:'sqlite3ApiExit']
fn sqlite3_api_exit(db &Sqlite3, rc int) int {
	if int(db.mallocFailed) || rc {
		return api_handle_error(db, rc)
	}
	return 0
}
