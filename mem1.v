@[translated]
module main

@[weak]
__global _sqliteZone_ &C.malloc_zone_t

@[c:'sqlite3MemMalloc']
fn sqlite3_mem_malloc(n_byte int) voidptr {
	c2v_gc_register_thread()
	p := &voidptr(0)
	0
	p = C.malloc_zone_malloc(_sqliteZone_, usize(n_byte))
	if usize(p) == usize(0) {
		0
		sqlite3_log(7, c'failed to allocate %u bytes of memory', n_byte)
	}
	return p
}

@[c:'sqlite3MemFree']
fn sqlite3_mem_free(p_prior voidptr) {
	c2v_gc_register_thread()
	C.malloc_zone_free(_sqliteZone_, voidptr(p_prior))
	0
}

@[c:'sqlite3MemSize']
fn sqlite3_mem_size(p_prior voidptr) int {
	c2v_gc_register_thread()
	return int((if _sqliteZone_ {
		_sqliteZone_.size(_sqliteZone_, voidptr(p_prior))
	} else {
		C.malloc_size(voidptr(p_prior))
	}))
}

@[c:'sqlite3MemRealloc']
fn sqlite3_mem_realloc(p_prior voidptr, n_byte int) voidptr {
	c2v_gc_register_thread()
	p := C.malloc_zone_realloc(_sqliteZone_, voidptr(p_prior), usize(n_byte))
	if usize(p) == usize(0) {
		0
		sqlite3_log(7, c'failed memory resize %u to %u bytes', (if _sqliteZone_ {
			_sqliteZone_.size(_sqliteZone_, voidptr(p_prior))
		} else {
			C.malloc_size(voidptr(p_prior))
		}), n_byte)
	}
	return p
}

@[c:'sqlite3MemRoundup']
fn sqlite3_mem_roundup(n int) int {
	c2v_gc_register_thread()
	return (n + 7) & ~7
}

@[c:'sqlite3MemInit']
fn sqlite3_mem_init(not_used voidptr) int {
	c2v_gc_register_thread()
	cpu_count := 0
	len := usize(0)
	if _sqliteZone_ {
		return 0
	}
	len = sizeof(cpu_count)
	C.sysctlbyname(c'hw.ncpu', voidptr(&cpu_count), &len, voidptr((voidptr(0))), usize(0))
	if cpu_count > 1 {
		_sqliteZone_ = C.malloc_default_zone()
	} else {
		_sqliteZone_ = C.malloc_create_zone(u64(4096), u32(0))
		C.malloc_set_zone_name(_sqliteZone_, c'Sqlite_Heap')
	}

	return 0
}

@[c:'sqlite3MemShutdown']
fn sqlite3_mem_shutdown(not_used voidptr) {
	c2v_gc_register_thread()

	return
}

@[c:'sqlite3MemSetDefault']
fn sqlite3_mem_set_default() {
	if !sqlite3_mem_set_default_default_methods_inited {
		sqlite3_mem_set_default_default_methods = Sqlite3_mem_methods{
			xMalloc: sqlite3_mem_malloc
			xFree: sqlite3_mem_free
			xRealloc: sqlite3_mem_realloc
			xSize: sqlite3_mem_size
			xRoundup: sqlite3_mem_roundup
			xInit: sqlite3_mem_init
			xShutdown: sqlite3_mem_shutdown
			pAppData: 0
		}

		sqlite3_mem_set_default_default_methods_inited = true
	}

	sqlite3_config_fn(4, voidptr(&sqlite3_mem_set_default_default_methods))
}
