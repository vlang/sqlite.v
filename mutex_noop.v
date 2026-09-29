@[translated]
module main

@[c:'noopMutexInit']
fn noop_mutex_init() int {
	c2v_gc_register_thread()
	return 0
}

@[c:'noopMutexEnd']
fn noop_mutex_end() int {
	c2v_gc_register_thread()
	return 0
}

@[c:'noopMutexAlloc']
fn noop_mutex_alloc(id int) &Sqlite3_mutex {
	c2v_gc_register_thread()

	return &Sqlite3_mutex(8)
}

@[c:'noopMutexFree']
fn noop_mutex_free(p &Sqlite3_mutex) {
	c2v_gc_register_thread()

	return
}

@[c:'noopMutexEnter']
fn noop_mutex_enter(p &Sqlite3_mutex) {
	c2v_gc_register_thread()

	return
}

@[c:'noopMutexTry']
fn noop_mutex_try(p &Sqlite3_mutex) int {
	c2v_gc_register_thread()

	return 0
}

@[c:'noopMutexLeave']
fn noop_mutex_leave(p &Sqlite3_mutex) {
	c2v_gc_register_thread()

	return
}

@[c:'sqlite3NoopMutex']
fn sqlite3_noop_mutex() &Sqlite3_mutex_methods {
	if !sqlite3_noop_mutex_s_mutex_inited {
		sqlite3_noop_mutex_s_mutex = Sqlite3_mutex_methods{
			xMutexInit: noop_mutex_init
			xMutexEnd: noop_mutex_end
			xMutexAlloc: noop_mutex_alloc
			xMutexFree: noop_mutex_free
			xMutexEnter: noop_mutex_enter
			xMutexTry: noop_mutex_try
			xMutexLeave: noop_mutex_leave
			xMutexHeld: C2vFn_666e20282653716c697465335f6d757465782920696e74(voidptr(0))
			xMutexNotheld: C2vFn_666e20282653716c697465335f6d757465782920696e74(voidptr(0))
		}

		sqlite3_noop_mutex_s_mutex_inited = true
	}

	return &sqlite3_noop_mutex_s_mutex
}
