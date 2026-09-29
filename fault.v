@[translated]
module main

struct BenignMallocHooks {
	xBenignBegin fn ()
	xBenignEnd   fn ()
}

@[c:'sqlite3BenignMallocHooks']
fn sqlite3_benign_malloc_hooks(x_benign_begin fn (), x_benign_end fn ()) {
	sqlite3Hooks.xBenignBegin = x_benign_begin
	sqlite3Hooks.xBenignEnd = x_benign_end
}

@[c:'sqlite3BeginBenignMalloc']
fn sqlite3_begin_benign_malloc() {
	if sqlite3Hooks.xBenignBegin {
		sqlite3Hooks.xBenignBegin()
	}
}

@[c:'sqlite3EndBenignMalloc']
fn sqlite3_end_benign_malloc() {
	if sqlite3Hooks.xBenignEnd {
		sqlite3Hooks.xBenignEnd()
	}
}
