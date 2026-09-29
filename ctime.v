@[translated]
module main

@[c:'sqlite3CompileOptions']
fn sqlite3_compile_options(pn_opt &int) &&u8 {
	unsafe { *pn_opt = 37 }
	return unsafe { &sqlite3azCompileOpt[0] }
}
