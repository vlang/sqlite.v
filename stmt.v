@[translated]
module main

fn sqlite3_sourceid() &i8 {
	c2v_gc_register_thread()
	return unsafe { &i8(&c'2026-07-24 19:02:57 bf7c7f30031888f4e796e429ab3978879485813aaca6f641c7b33e4e09459bcc'[0]) }
}
