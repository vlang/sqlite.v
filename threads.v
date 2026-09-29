@[translated]
module main

struct SQLiteThread {
	tid   voidptr
	done  int
	pOut  voidptr
	xTask fn (voidptr) voidptr
	pIn   voidptr
}

@[c:'sqlite3ThreadCreate']
fn sqlite3_thread_create(pp_thread &&SQLiteThread, x_task fn (voidptr) voidptr, p_in voidptr) int {
	p := &SQLiteThread(0)
	rc := 0
	unsafe { *pp_thread = 0 }
	p = sqlite3_malloc_vdup2(U64(sizeof(SQLiteThread)))
	if usize(p) == usize(0) {
		return 7
	}
	C.memset(voidptr(p), 0, sizeof(SQLiteThread))
	p.xTask = x_task
	p.pIn = p_in
	if sqlite3_fault_sim(200) {
		rc = 1
	} else {
		rc = C.pthread_create(&p.tid, unsafe { nil }, x_task, voidptr(p_in))
	}
	if rc {
		p.done = 1
		p.pOut = x_task(voidptr(p_in))
	}
	unsafe { *pp_thread = p }
	return 0
}

@[c:'sqlite3ThreadJoin']
fn sqlite3_thread_join(p &SQLiteThread, pp_out &voidptr) int {
	rc := 0
	if (usize(p) == usize(0)) {
		return 7
	}
	if p.done {
		unsafe { *pp_out = p.pOut }
		rc = 0
	} else {
		rc = if C.pthread_join(voidptr(p.tid), pp_out) { 1 } else { 0 }
	}
	sqlite3_free(voidptr(p))
	return rc
}
