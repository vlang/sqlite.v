@[translated]
module main

struct Sqlite3_mutex {
	mutex C.pthread_mutex_t
}

@[c:'sqlite3MemoryBarrier']
fn sqlite3_memory_barrier() {
	C.__sync_synchronize()
}

@[c:'pthreadMutexInit']
fn pthread_mutex_init() int {
	c2v_gc_register_thread()
	return 0
}

@[c:'pthreadMutexEnd']
fn pthread_mutex_end() int {
	c2v_gc_register_thread()
	return 0
}

@[c:'pthreadMutexAlloc']
fn pthread_mutex_alloc(i_type int) &Sqlite3_mutex {
	c2v_gc_register_thread()
	if !pthread_mutex_alloc_static_mutexes_inited {
		c2v_static_init := [Sqlite3_mutex{
			mutex: C.pthread_mutex_t{
				__sig: i64(850045863)
				__opaque: [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0)]!
			}
		}, Sqlite3_mutex{
			mutex: C.pthread_mutex_t{
				__sig: i64(850045863)
				__opaque: [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0)]!
			}
		}, Sqlite3_mutex{
			mutex: C.pthread_mutex_t{
				__sig: i64(850045863)
				__opaque: [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0)]!
			}
		}, Sqlite3_mutex{
			mutex: C.pthread_mutex_t{
				__sig: i64(850045863)
				__opaque: [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0)]!
			}
		}, Sqlite3_mutex{
			mutex: C.pthread_mutex_t{
				__sig: i64(850045863)
				__opaque: [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0)]!
			}
		}, Sqlite3_mutex{
			mutex: C.pthread_mutex_t{
				__sig: i64(850045863)
				__opaque: [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0)]!
			}
		}, Sqlite3_mutex{
			mutex: C.pthread_mutex_t{
				__sig: i64(850045863)
				__opaque: [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0)]!
			}
		}, Sqlite3_mutex{
			mutex: C.pthread_mutex_t{
				__sig: i64(850045863)
				__opaque: [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0)]!
			}
		}, Sqlite3_mutex{
			mutex: C.pthread_mutex_t{
				__sig: i64(850045863)
				__opaque: [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0)]!
			}
		}, Sqlite3_mutex{
			mutex: C.pthread_mutex_t{
				__sig: i64(850045863)
				__opaque: [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0)]!
			}
		}, Sqlite3_mutex{
			mutex: C.pthread_mutex_t{
				__sig: i64(850045863)
				__opaque: [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0)]!
			}
		}, Sqlite3_mutex{
			mutex: C.pthread_mutex_t{
				__sig: i64(850045863)
				__opaque: [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
					i8(0), i8(0)]!
			}
		}]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			pthread_mutex_alloc_static_mutexes[c2v_i_0] = c2v_element_0
		}
		pthread_mutex_alloc_static_mutexes_inited = true
	}

	p := &Sqlite3_mutex(0)
	match i_type {
		1 {
			p = sqlite3_malloc_zero(U64(sizeof(Sqlite3_mutex)))
			if p {
				recursive_attr := C.pthread_mutexattr_t{}
				C.pthread_mutexattr_init(&recursive_attr)
				C.pthread_mutexattr_settype(&recursive_attr, 2)
				C.pthread_mutex_init(&p.mutex, &recursive_attr)
				C.pthread_mutexattr_destroy(&recursive_attr)
			}
		}
		0 {
			p = sqlite3_malloc_zero(U64(sizeof(Sqlite3_mutex)))
			if p {
				C.pthread_mutex_init(&p.mutex, unsafe { nil })
			}
		}
		else {
			p = unsafe { &pthread_mutex_alloc_static_mutexes[0] + (i_type - 2) }
		}
	}

	return p
}

@[c:'pthreadMutexFree']
fn pthread_mutex_free(p &Sqlite3_mutex) {
	c2v_gc_register_thread()
	C.pthread_mutex_destroy(&p.mutex)
	sqlite3_free(voidptr(p))
}

@[c:'pthreadMutexEnter']
fn pthread_mutex_enter(p &Sqlite3_mutex) {
	c2v_gc_register_thread()
	C.pthread_mutex_lock(&p.mutex)
}

@[c:'pthreadMutexTry']
fn pthread_mutex_try(p &Sqlite3_mutex) int {
	c2v_gc_register_thread()
	rc := 0
	if C.pthread_mutex_trylock(&p.mutex) == 0 {
		rc = 0
	} else {
		rc = 5
	}
	return rc
}

@[c:'pthreadMutexLeave']
fn pthread_mutex_leave(p &Sqlite3_mutex) {
	c2v_gc_register_thread()
	C.pthread_mutex_unlock(&p.mutex)
}

@[c:'sqlite3DefaultMutex']
fn sqlite3_default_mutex() &Sqlite3_mutex_methods {
	if !sqlite3_default_mutex_s_mutex_inited {
		sqlite3_default_mutex_s_mutex = Sqlite3_mutex_methods{
			xMutexInit: pthread_mutex_init
			xMutexEnd: pthread_mutex_end
			xMutexAlloc: pthread_mutex_alloc
			xMutexFree: pthread_mutex_free
			xMutexEnter: pthread_mutex_enter
			xMutexTry: pthread_mutex_try
			xMutexLeave: pthread_mutex_leave
			xMutexHeld: C2vFn_666e20282653716c697465335f6d757465782920696e74(voidptr(0))
			xMutexNotheld: C2vFn_666e20282653716c697465335f6d757465782920696e74(voidptr(0))
		}

		sqlite3_default_mutex_s_mutex_inited = true
	}

	return &sqlite3_default_mutex_s_mutex
}
