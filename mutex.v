@[translated]
module main

@[c:'sqlite3MutexInit']
fn sqlite3_mutex_init() int {
	rc := 0
	if isnil(sqlite3Config.mutex.xMutexAlloc) {
		p_from := &Sqlite3_mutex_methods(0)
		p_to := &sqlite3Config.mutex
		if sqlite3Config.bCoreMutex {
			p_from = sqlite3_default_mutex()
		} else {
			p_from = sqlite3_noop_mutex()
		}
		p_to.xMutexInit = p_from.xMutexInit
		p_to.xMutexEnd = p_from.xMutexEnd
		p_to.xMutexFree = p_from.xMutexFree
		p_to.xMutexEnter = p_from.xMutexEnter
		p_to.xMutexTry = p_from.xMutexTry
		p_to.xMutexLeave = p_from.xMutexLeave
		p_to.xMutexHeld = p_from.xMutexHeld
		p_to.xMutexNotheld = p_from.xMutexNotheld
		sqlite3_memory_barrier()
		p_to.xMutexAlloc = p_from.xMutexAlloc
	}
	rc = sqlite3Config.mutex.xMutexInit()
	sqlite3_memory_barrier()
	return rc
}

@[c:'sqlite3MutexEnd']
fn sqlite3_mutex_end() int {
	rc := 0
	if sqlite3Config.mutex.xMutexEnd {
		rc = sqlite3Config.mutex.xMutexEnd()
	}
	return rc
}

fn sqlite3_mutex_alloc(id int) &Sqlite3_mutex {
	c2v_gc_register_thread()
	if id <= 1 && sqlite3_initialize() {
		return unsafe { nil }
	}
	if id > 1 && sqlite3_mutex_init() {
		return unsafe { nil }
	}
	return sqlite3Config.mutex.xMutexAlloc(id)
}

@[c:'sqlite3MutexAlloc']
fn sqlite3_mutex_alloc_vdup4(id int) &Sqlite3_mutex {
	if !sqlite3Config.bCoreMutex {
		return unsafe { nil }
	}
	return sqlite3Config.mutex.xMutexAlloc(id)
}

fn sqlite3_mutex_free(p &Sqlite3_mutex) {
	c2v_gc_register_thread()
	if p {
		sqlite3Config.mutex.xMutexFree(p)
	}
}

fn sqlite3_mutex_enter(p &Sqlite3_mutex) {
	c2v_gc_register_thread()
	if p {
		sqlite3Config.mutex.xMutexEnter(p)
	}
}

fn sqlite3_mutex_try(p &Sqlite3_mutex) int {
	c2v_gc_register_thread()
	rc := 0
	if p {
		return sqlite3Config.mutex.xMutexTry(p)
	}
	return rc
}

fn sqlite3_mutex_leave(p &Sqlite3_mutex) {
	c2v_gc_register_thread()
	if p {
		sqlite3Config.mutex.xMutexLeave(p)
	}
}
