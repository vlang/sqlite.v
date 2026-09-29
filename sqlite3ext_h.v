@[translated]
module main

struct Sqlite3_api_routines {
	aggregate_context      fn (&Sqlite3_context, int) voidptr
	aggregate_count        fn (&Sqlite3_context) int
	bind_blob              fn (&Sqlite3_stmt, int, voidptr, int, fn (voidptr)) int
	bind_double            fn (&Sqlite3_stmt, int, f64) int
	bind_int               fn (&Sqlite3_stmt, int, int) int
	bind_int64             fn (&Sqlite3_stmt, int, Sqlite_int64) int
	bind_null              fn (&Sqlite3_stmt, int) int
	bind_parameter_count   fn (&Sqlite3_stmt) int
	bind_parameter_index   fn (&Sqlite3_stmt, &i8) int
	bind_parameter_name    fn (&Sqlite3_stmt, int) &i8
	bind_text              fn (&Sqlite3_stmt, int, &i8, int, fn (voidptr)) int
	bind_text16            fn (&Sqlite3_stmt, int, voidptr, int, fn (voidptr)) int
	bind_value             fn (&Sqlite3_stmt, int, &Sqlite3_value) int
	busy_handler           fn (&Sqlite3, fn (voidptr, int) int, voidptr) int
	busy_timeout           fn (&Sqlite3, int) int
	changes                fn (&Sqlite3) int
	close_                 fn (&Sqlite3) int
	collation_needed       fn (&Sqlite3, voidptr, fn (voidptr, &Sqlite3, int, &i8)) int
	collation_needed16     fn (&Sqlite3, voidptr, fn (voidptr, &Sqlite3, int, voidptr)) int
	column_blob            fn (&Sqlite3_stmt, int) voidptr
	column_bytes           fn (&Sqlite3_stmt, int) int
	column_bytes16         fn (&Sqlite3_stmt, int) int
	column_count           fn (&Sqlite3_stmt) int
	column_database_name   fn (&Sqlite3_stmt, int) &i8
	column_database_name16 fn (&Sqlite3_stmt, int) voidptr
	column_decltype        fn (&Sqlite3_stmt, int) &i8
	column_decltype16      fn (&Sqlite3_stmt, int) voidptr
	column_double          fn (&Sqlite3_stmt, int) f64
	column_int             fn (&Sqlite3_stmt, int) int
	column_int64           fn (&Sqlite3_stmt, int) Sqlite_int64
	column_name            fn (&Sqlite3_stmt, int) &i8
	column_name16          fn (&Sqlite3_stmt, int) voidptr
	column_origin_name     fn (&Sqlite3_stmt, int) &i8
	column_origin_name16   fn (&Sqlite3_stmt, int) voidptr
	column_table_name      fn (&Sqlite3_stmt, int) &i8
	column_table_name16    fn (&Sqlite3_stmt, int) voidptr
	column_text            fn (&Sqlite3_stmt, int) &u8
	column_text16          fn (&Sqlite3_stmt, int) voidptr
	column_type            fn (&Sqlite3_stmt, int) int
	column_value           fn (&Sqlite3_stmt, int) &Sqlite3_value
	commit_hook            fn (&Sqlite3, fn (voidptr) int, voidptr) voidptr
	complete               fn (&i8) int
	complete16             fn (voidptr) int
	create_collation       fn (&Sqlite3, &i8, int, voidptr, fn (voidptr, int, voidptr, int, voidptr) int) int
	create_collation16     fn (&Sqlite3, voidptr, int, voidptr, fn (voidptr, int, voidptr, int, voidptr) int) int
	create_function        fn (&Sqlite3, &i8, int, int, voidptr, fn (&Sqlite3_context, int, &&Sqlite3_value), fn (&Sqlite3_context, int, &&Sqlite3_value), fn (&Sqlite3_context)) int
	create_function16      fn (&Sqlite3, voidptr, int, int, voidptr, fn (&Sqlite3_context, int, &&Sqlite3_value), fn (&Sqlite3_context, int, &&Sqlite3_value), fn (&Sqlite3_context)) int
	create_module          fn (&Sqlite3, &i8, &Sqlite3_module, voidptr) int
	data_count             fn (&Sqlite3_stmt) int
	db_handle              fn (&Sqlite3_stmt) &Sqlite3
	declare_vtab           fn (&Sqlite3, &i8) int
	enable_shared_cache    fn (int) int
	errcode                fn (&Sqlite3) int
	errmsg                 fn (&Sqlite3) &i8
	errmsg16               fn (&Sqlite3) voidptr
	exec                   fn (&Sqlite3, &i8, Sqlite3_callback, voidptr, &&u8) int
	expired                fn (&Sqlite3_stmt) int
	finalize               fn (&Sqlite3_stmt) int
	free_                  fn (voidptr)
	free_table             fn (&&u8)
	get_autocommit         fn (&Sqlite3) int
	get_auxdata            fn (&Sqlite3_context, int) voidptr
	get_table              fn (&Sqlite3, &i8, &&&i8, &int, &int, &&u8) int
	global_recover         fn () int
	interruptx             fn (&Sqlite3)
	last_insert_rowid      fn (&Sqlite3) Sqlite_int64
	libversion             fn () &i8
	libversion_number      fn () int
	malloc_                fn (int) voidptr
	mprintf                fn (&i8, ...) &i8
	open_                  fn (&i8, &&Sqlite3) int
	open16                 fn (voidptr, &&Sqlite3) int
	prepare                fn (&Sqlite3, &i8, int, &&Sqlite3_stmt, &&u8) int
	prepare16              fn (&Sqlite3, voidptr, int, &&Sqlite3_stmt, &voidptr) int
	profile                fn (&Sqlite3, fn (voidptr, &i8, Sqlite_uint64), voidptr) voidptr
	progress_handler       fn (&Sqlite3, int, fn (voidptr) int, voidptr)
	realloc                fn (voidptr, int) voidptr
	reset                  fn (&Sqlite3_stmt) int
	result_blob            fn (&Sqlite3_context, voidptr, int, fn (voidptr))
	result_double          fn (&Sqlite3_context, f64)
	result_error           fn (&Sqlite3_context, &i8, int)
	result_error16         fn (&Sqlite3_context, voidptr, int)
	result_int             fn (&Sqlite3_context, int)
	result_int64           fn (&Sqlite3_context, Sqlite_int64)
	result_null            fn (&Sqlite3_context)
	result_text            fn (&Sqlite3_context, &i8, int, fn (voidptr))
	result_text16          fn (&Sqlite3_context, voidptr, int, fn (voidptr))
	result_text16be        fn (&Sqlite3_context, voidptr, int, fn (voidptr))
	result_text16le        fn (&Sqlite3_context, voidptr, int, fn (voidptr))
	result_value           fn (&Sqlite3_context, &Sqlite3_value)
	rollback_hook          fn (&Sqlite3, fn (voidptr), voidptr) voidptr
	set_authorizer         fn (&Sqlite3, fn (voidptr, int, &i8, &i8, &i8, &i8) int, voidptr) int
	set_auxdata            fn (&Sqlite3_context, int, voidptr, fn (voidptr))
	xsnprintf              fn (int, &i8, &i8, ...) &i8
	step                   fn (&Sqlite3_stmt) int
	table_column_metadata  fn (&Sqlite3, &i8, &i8, &i8, &&u8, &&u8, &int, &int, &int) int
	thread_cleanup         fn ()
	total_changes          fn (&Sqlite3) int
	trace                  fn (&Sqlite3, fn (voidptr, &i8), voidptr) voidptr
	transfer_bindings      fn (&Sqlite3_stmt, &Sqlite3_stmt) int
	update_hook            fn (&Sqlite3, fn (voidptr, int, &i8, &i8, Sqlite_int64), voidptr) voidptr
	user_data              fn (&Sqlite3_context) voidptr
	value_blob             fn (&Sqlite3_value) voidptr
	value_bytes            fn (&Sqlite3_value) int
	value_bytes16          fn (&Sqlite3_value) int
	value_double           fn (&Sqlite3_value) f64
	value_int              fn (&Sqlite3_value) int
	value_int64            fn (&Sqlite3_value) Sqlite_int64
	value_numeric_type     fn (&Sqlite3_value) int
	value_text             fn (&Sqlite3_value) &u8
	value_text16           fn (&Sqlite3_value) voidptr
	value_text16be         fn (&Sqlite3_value) voidptr
	value_text16le         fn (&Sqlite3_value) voidptr
	value_type             fn (&Sqlite3_value) int
	vmprintf               fn (&i8, C.va_list) &i8
	overload_function      fn (&Sqlite3, &i8, int) int
	prepare_v2             fn (&Sqlite3, &i8, int, &&Sqlite3_stmt, &&u8) int
	prepare16_v2           fn (&Sqlite3, voidptr, int, &&Sqlite3_stmt, &voidptr) int
	clear_bindings         fn (&Sqlite3_stmt) int
	create_module_v2       fn (&Sqlite3, &i8, &Sqlite3_module, voidptr, fn (voidptr)) int
	bind_zeroblob          fn (&Sqlite3_stmt, int, int) int
	blob_bytes             fn (&Sqlite3_blob) int
	blob_close             fn (&Sqlite3_blob) int
	blob_open              fn (&Sqlite3, &i8, &i8, &i8, Sqlite3_int64, int, &&Sqlite3_blob) int
	blob_read              fn (&Sqlite3_blob, voidptr, int, int) int
	blob_write             fn (&Sqlite3_blob, voidptr, int, int) int
	create_collation_v2    fn (&Sqlite3, &i8, int, voidptr, fn (voidptr, int, voidptr, int, voidptr) int, fn (voidptr)) int
	file_control           fn (&Sqlite3, &i8, int, voidptr) int
	memory_highwater       fn (int) Sqlite3_int64
	memory_used            fn () Sqlite3_int64
	mutex_alloc            fn (int) &Sqlite3_mutex
	mutex_enter            fn (&Sqlite3_mutex)
	mutex_free             fn (&Sqlite3_mutex)
	mutex_leave            fn (&Sqlite3_mutex)
	mutex_try              fn (&Sqlite3_mutex) int
	open_v2                fn (&i8, &&Sqlite3, int, &i8) int
	release_memory         fn (int) int
	result_error_nomem     fn (&Sqlite3_context)
	result_error_toobig    fn (&Sqlite3_context)
	sleep                  fn (int) int
	soft_heap_limit        fn (int)
	vfs_find               fn (&i8) &Sqlite3_vfs
	vfs_register           fn (&Sqlite3_vfs, int) int
	vfs_unregister         fn (&Sqlite3_vfs) int
	xthreadsafe            fn () int
	result_zeroblob        fn (&Sqlite3_context, int)
	result_error_code      fn (&Sqlite3_context, int)
	test_control           fn (int, ...) int
	randomness             fn (int, voidptr)
	context_db_handle      fn (&Sqlite3_context) &Sqlite3
	extended_result_codes  fn (&Sqlite3, int) int
	limit                  fn (&Sqlite3, int, int) int
	next_stmt              fn (&Sqlite3, &Sqlite3_stmt) &Sqlite3_stmt
	sql_                   fn (&Sqlite3_stmt) &i8
	status                 fn (int, &int, &int, int) int
	backup_finish          fn (&Sqlite3_backup) int
	backup_init            fn (&Sqlite3, &i8, &Sqlite3, &i8) &Sqlite3_backup
	backup_pagecount       fn (&Sqlite3_backup) int
	backup_remaining       fn (&Sqlite3_backup) int
	backup_step            fn (&Sqlite3_backup, int) int
	compileoption_get      fn (int) &i8
	compileoption_used     fn (&i8) int
	create_function_v2     fn (&Sqlite3, &i8, int, int, voidptr, fn (&Sqlite3_context, int, &&Sqlite3_value), fn (&Sqlite3_context, int, &&Sqlite3_value), fn (&Sqlite3_context), fn (voidptr)) int
	db_config              fn (&Sqlite3, int, ...) int
	db_mutex               fn (&Sqlite3) &Sqlite3_mutex
	db_status              fn (&Sqlite3, int, &int, &int, int) int
	extended_errcode       fn (&Sqlite3) int
	log                    fn (int, &i8, ...)
	soft_heap_limit64      fn (Sqlite3_int64) Sqlite3_int64
	sourceid               fn () &i8
	stmt_status            fn (&Sqlite3_stmt, int, int) int
	strnicmp               fn (&i8, &i8, int) int
	unlock_notify          fn (&Sqlite3, fn (&voidptr, int), voidptr) int
	wal_autocheckpoint     fn (&Sqlite3, int) int
	wal_checkpoint         fn (&Sqlite3, &i8) int
	wal_hook               fn (&Sqlite3, fn (voidptr, &Sqlite3, &i8, int) int, voidptr) voidptr
	blob_reopen            fn (&Sqlite3_blob, Sqlite3_int64) int
	vtab_config            fn (&Sqlite3, int, ...) int
	vtab_on_conflict       fn (&Sqlite3) int
	close_v2               fn (&Sqlite3) int
	db_filename            fn (&Sqlite3, &i8) &i8
	db_readonly            fn (&Sqlite3, &i8) int
	db_release_memory      fn (&Sqlite3) int
	errstr                 fn (int) &i8
	stmt_busy              fn (&Sqlite3_stmt) int
	stmt_readonly          fn (&Sqlite3_stmt) int
	stricmp                fn (&i8, &i8) int
	uri_boolean            fn (&i8, &i8, int) int
	uri_int64              fn (&i8, &i8, Sqlite3_int64) Sqlite3_int64
	uri_parameter          fn (&i8, &i8) &i8
	xvsnprintf             fn (int, &i8, &i8, C.va_list) &i8
	wal_checkpoint_v2      fn (&Sqlite3, &i8, int, &int, &int) int
	auto_extension         fn (fn ()) int
	bind_blob64            fn (&Sqlite3_stmt, int, voidptr, Sqlite3_uint64, fn (voidptr)) int
	bind_text64            fn (&Sqlite3_stmt, int, &i8, Sqlite3_uint64, fn (voidptr), u8) int
	cancel_auto_extension  fn (fn ()) int
	load_extension         fn (&Sqlite3, &i8, &i8, &&u8) int
	malloc64               fn (Sqlite3_uint64) voidptr
	msize                  fn (voidptr) Sqlite3_uint64
	realloc64              fn (voidptr, Sqlite3_uint64) voidptr
	reset_auto_extension   fn ()
	result_blob64          fn (&Sqlite3_context, voidptr, Sqlite3_uint64, fn (voidptr))
	result_text64          fn (&Sqlite3_context, &i8, Sqlite3_uint64, fn (voidptr), u8)
	strglob                fn (&i8, &i8) int
	value_dup              fn (&Sqlite3_value) &Sqlite3_value
	value_free             fn (&Sqlite3_value)
	result_zeroblob64      fn (&Sqlite3_context, Sqlite3_uint64) int
	bind_zeroblob64        fn (&Sqlite3_stmt, int, Sqlite3_uint64) int
	value_subtype          fn (&Sqlite3_value) u32
	result_subtype         fn (&Sqlite3_context, u32)
	status64               fn (int, &Sqlite3_int64, &Sqlite3_int64, int) int
	strlike                fn (&i8, &i8, u32) int
	db_cacheflush          fn (&Sqlite3) int
	system_errno           fn (&Sqlite3) int
	trace_v2               fn (&Sqlite3, u32, fn (u32, voidptr, voidptr, voidptr) int, voidptr) int
	expanded_sql           fn (&Sqlite3_stmt) &i8
	set_last_insert_rowid  fn (&Sqlite3, Sqlite3_int64)
	prepare_v3             fn (&Sqlite3, &i8, int, u32, &&Sqlite3_stmt, &&u8) int
	prepare16_v3           fn (&Sqlite3, voidptr, int, u32, &&Sqlite3_stmt, &voidptr) int
	bind_pointer           fn (&Sqlite3_stmt, int, voidptr, &i8, fn (voidptr)) int
	result_pointer         fn (&Sqlite3_context, voidptr, &i8, fn (voidptr))
	value_pointer          fn (&Sqlite3_value, &i8) voidptr
	vtab_nochange          fn (&Sqlite3_context) int
	value_nochange         fn (&Sqlite3_value) int
	vtab_collation         fn (&Sqlite3_index_info, int) &i8
	keyword_count          fn () int
	keyword_name           fn (int, &&u8, &int) int
	keyword_check          fn (&i8, int) int
	str_new                fn (&Sqlite3) &Sqlite3_str
	str_finish             fn (&Sqlite3_str) &i8
	str_appendf            fn (&Sqlite3_str, &i8, ...)
	str_vappendf           fn (&Sqlite3_str, &i8, C.va_list)
	str_append             fn (&Sqlite3_str, &i8, int)
	str_appendall          fn (&Sqlite3_str, &i8)
	str_appendchar         fn (&Sqlite3_str, int, i8)
	str_reset              fn (&Sqlite3_str)
	str_errcode            fn (&Sqlite3_str) int
	str_length             fn (&Sqlite3_str) int
	str_value              fn (&Sqlite3_str) &i8
	create_window_function fn (&Sqlite3, &i8, int, int, voidptr, fn (&Sqlite3_context, int, &&Sqlite3_value), fn (&Sqlite3_context), fn (&Sqlite3_context), fn (&Sqlite3_context, int, &&Sqlite3_value), fn (voidptr)) int
	normalized_sql         fn (&Sqlite3_stmt) &i8
	stmt_isexplain         fn (&Sqlite3_stmt) int
	value_frombind         fn (&Sqlite3_value) int
	drop_modules           fn (&Sqlite3, &&u8) int
	hard_heap_limit64      fn (Sqlite3_int64) Sqlite3_int64
	uri_key                fn (&i8, int) &i8
	filename_database      fn (&i8) &i8
	filename_journal       fn (&i8) &i8
	filename_wal           fn (&i8) &i8
	create_filename        fn (&i8, &i8, &i8, int, &&u8) &i8
	free_filename          fn (&i8)
	database_file_object   fn (&i8) &Sqlite3_file
	txn_state              fn (&Sqlite3, &i8) int
	changes64              fn (&Sqlite3) Sqlite3_int64
	total_changes64        fn (&Sqlite3) Sqlite3_int64
	autovacuum_pages       fn (&Sqlite3, fn (voidptr, &i8, u32, u32, u32) u32, voidptr, fn (voidptr)) int
	error_offset           fn (&Sqlite3) int
	vtab_rhs_value         fn (&Sqlite3_index_info, int, &&Sqlite3_value) int
	vtab_distinct          fn (&Sqlite3_index_info) int
	vtab_in                fn (&Sqlite3_index_info, int, int) int
	vtab_in_first          fn (&Sqlite3_value, &&Sqlite3_value) int
	vtab_in_next           fn (&Sqlite3_value, &&Sqlite3_value) int
	deserialize            fn (&Sqlite3, &i8, &u8, Sqlite3_int64, Sqlite3_int64, u32) int
	serialize              fn (&Sqlite3, &i8, &Sqlite3_int64, u32) &u8
	db_name                fn (&Sqlite3, int) &i8
	value_encoding         fn (&Sqlite3_value) int
	is_interrupted         fn (&Sqlite3) int
	stmt_explain           fn (&Sqlite3_stmt, int) int
	get_clientdata         fn (&Sqlite3, &i8) voidptr
	set_clientdata         fn (&Sqlite3, &i8, voidptr, fn (voidptr)) int
	setlk_timeout          fn (&Sqlite3, int, int) int
	set_errmsg             fn (&Sqlite3, int, &i8) int
	db_status64            fn (&Sqlite3, int, &Sqlite3_int64, &Sqlite3_int64, int) int
	str_truncate           fn (&Sqlite3_str, int)
	str_free               fn (&Sqlite3_str)
	carray_bind            fn (&Sqlite3_stmt, int, voidptr, int, int, fn (voidptr)) int
	carray_bind_v2         fn (&Sqlite3_stmt, int, voidptr, int, int, fn (voidptr), voidptr) int
}

type Sqlite3_loadext_entry = fn (&Sqlite3, &&u8, &Sqlite3_api_routines) int
