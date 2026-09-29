@[translated]
module main

type Sqlite_int64 = i64

type Sqlite_uint64 = u64

type Sqlite3_int64 = i64

type Sqlite3_uint64 = u64

type Sqlite3_callback = fn (voidptr, int, &&u8, &&u8) int

struct Sqlite3_file {
	pMethods &Sqlite3_io_methods
}

struct Sqlite3_io_methods {
	iVersion               int
	xClose                 fn (&Sqlite3_file) int
	xRead                  fn (&Sqlite3_file, voidptr, int, Sqlite3_int64) int
	xWrite                 fn (&Sqlite3_file, voidptr, int, Sqlite3_int64) int
	xTruncate              fn (&Sqlite3_file, Sqlite3_int64) int
	xSync                  fn (&Sqlite3_file, int) int
	xFileSize              fn (&Sqlite3_file, &Sqlite3_int64) int
	xLock                  fn (&Sqlite3_file, int) int
	xUnlock                fn (&Sqlite3_file, int) int
	xCheckReservedLock     fn (&Sqlite3_file, &int) int
	xFileControl           fn (&Sqlite3_file, int, voidptr) int
	xSectorSize            fn (&Sqlite3_file) int
	xDeviceCharacteristics fn (&Sqlite3_file) int
	xShmMap                fn (&Sqlite3_file, int, int, int, &voidptr) int
	xShmLock               fn (&Sqlite3_file, int, int, int) int
	xShmBarrier            fn (&Sqlite3_file)
	xShmUnmap              fn (&Sqlite3_file, int) int
	xFetch                 fn (&Sqlite3_file, Sqlite3_int64, int, &voidptr) int
	xUnfetch               fn (&Sqlite3_file, Sqlite3_int64, voidptr) int
}

type Sqlite3_filename = &i8

type Sqlite3_syscall_ptr = fn ()

struct Sqlite3_vfs {
	iVersion          int
	szOsFile          int
	mxPathname        int
	pNext             &Sqlite3_vfs
	zName             &i8
	pAppData          voidptr
	xOpen             fn (&Sqlite3_vfs, Sqlite3_filename, &Sqlite3_file, int, &int) int
	xDelete           fn (&Sqlite3_vfs, &i8, int) int
	xAccess           fn (&Sqlite3_vfs, &i8, int, &int) int
	xFullPathname     fn (&Sqlite3_vfs, &i8, int, &i8) int
	xDlOpen           fn (&Sqlite3_vfs, &i8) voidptr
	xDlError          fn (&Sqlite3_vfs, int, &i8)
	xDlSym            fn (&Sqlite3_vfs, voidptr, &i8) C2vFn_666e202829
	xDlClose          fn (&Sqlite3_vfs, voidptr)
	xRandomness       fn (&Sqlite3_vfs, int, &i8) int
	xSleep            fn (&Sqlite3_vfs, int) int
	xCurrentTime      fn (&Sqlite3_vfs, &f64) int
	xGetLastError     fn (&Sqlite3_vfs, int, &i8) int
	xCurrentTimeInt64 fn (&Sqlite3_vfs, &Sqlite3_int64) int
	xSetSystemCall    fn (&Sqlite3_vfs, &i8, Sqlite3_syscall_ptr) int
	xGetSystemCall    fn (&Sqlite3_vfs, &i8) Sqlite3_syscall_ptr
	xNextSystemCall   fn (&Sqlite3_vfs, &i8) &i8
}

struct Sqlite3_mem_methods {
	xMalloc   fn (int) voidptr
	xFree     fn (voidptr)
	xRealloc  fn (voidptr, int) voidptr
	xSize     fn (voidptr) int
	xRoundup  fn (int) int
	xInit     fn (voidptr) int
	xShutdown fn (voidptr)
	pAppData  voidptr
}

struct Sqlite3_stmt {}

fn sqlite3_column_database_name(arg &Sqlite3_stmt, arg_2 int) &i8

fn sqlite3_column_database_name16(arg &Sqlite3_stmt, arg_2 int) voidptr

fn sqlite3_column_table_name(arg &Sqlite3_stmt, arg_2 int) &i8

fn sqlite3_column_table_name16(arg &Sqlite3_stmt, arg_2 int) voidptr

fn sqlite3_column_origin_name(arg &Sqlite3_stmt, arg_2 int) &i8

fn sqlite3_column_origin_name16(arg &Sqlite3_stmt, arg_2 int) voidptr

type Sqlite3_destructor_type = fn (voidptr)

@[markused; weak]
__global sqlite3_temp_directory &i8
@[markused; weak]
__global sqlite3_data_directory &i8

fn sqlite3_win32_set_directory(type_ u64, z_value voidptr) int

fn sqlite3_win32_set_directory8(type_ u64, z_value &i8) int

fn sqlite3_win32_set_directory16(type_ u64, z_value voidptr) int

struct Sqlite3_module {
	iVersion      int
	xCreate       fn (&Sqlite3, voidptr, int, &&u8, &&Sqlite3_vtab, &&u8) int
	xConnect      fn (&Sqlite3, voidptr, int, &&u8, &&Sqlite3_vtab, &&u8) int
	xBestIndex    fn (&Sqlite3_vtab, &Sqlite3_index_info) int
	xDisconnect   fn (&Sqlite3_vtab) int
	xDestroy      fn (&Sqlite3_vtab) int
	xOpen         fn (&Sqlite3_vtab, &&Sqlite3_vtab_cursor) int
	xClose        fn (&Sqlite3_vtab_cursor) int
	xFilter       fn (&Sqlite3_vtab_cursor, int, &i8, int, &&Sqlite3_value) int
	xNext         fn (&Sqlite3_vtab_cursor) int
	xEof          fn (&Sqlite3_vtab_cursor) int
	xColumn       fn (&Sqlite3_vtab_cursor, &Sqlite3_context, int) int
	xRowid        fn (&Sqlite3_vtab_cursor, &Sqlite3_int64) int
	xUpdate       fn (&Sqlite3_vtab, int, &&Sqlite3_value, &Sqlite3_int64) int
	xBegin        fn (&Sqlite3_vtab) int
	xSync         fn (&Sqlite3_vtab) int
	xCommit       fn (&Sqlite3_vtab) int
	xRollback     fn (&Sqlite3_vtab) int
	xFindFunction fn (&Sqlite3_vtab, int, &i8, &fn (&Sqlite3_context, int, &&Sqlite3_value), &voidptr) int
	xRename       fn (&Sqlite3_vtab, &i8) int
	xSavepoint    fn (&Sqlite3_vtab, int) int
	xRelease      fn (&Sqlite3_vtab, int) int
	xRollbackTo   fn (&Sqlite3_vtab, int) int
	xShadowName   fn (&i8) int
	xIntegrity    fn (&Sqlite3_vtab, &i8, &i8, int, &&u8) int
}

struct Sqlite3_index_constraint {
	iColumn     int
	op          u8
	usable      u8
	iTermOffset int
}

struct Sqlite3_index_orderby {
	iColumn int
	desc    u8
}

struct Sqlite3_index_constraint_usage {
	argvIndex int
	omit      u8
}

struct Sqlite3_index_info {
	nConstraint      int
	aConstraint      &Sqlite3_index_constraint
	nOrderBy         int
	aOrderBy         &Sqlite3_index_orderby
	aConstraintUsage &Sqlite3_index_constraint_usage
	idxNum           int
	idxStr           &i8
	needToFreeIdxStr int
	orderByConsumed  int
	estimatedCost    f64
	estimatedRows    Sqlite3_int64
	idxFlags         int
	colUsed          Sqlite3_uint64
}

struct Sqlite3_vtab {
	pModule &Sqlite3_module
	nRef    int
	zErrMsg &i8
}

struct Sqlite3_vtab_cursor {
	pVtab &Sqlite3_vtab
}

struct Sqlite3_blob {}

struct Sqlite3_mutex_methods {
	xMutexInit    fn () int
	xMutexEnd     fn () int
	xMutexAlloc   fn (int) &Sqlite3_mutex
	xMutexFree    fn (&Sqlite3_mutex)
	xMutexEnter   fn (&Sqlite3_mutex)
	xMutexTry     fn (&Sqlite3_mutex) int
	xMutexLeave   fn (&Sqlite3_mutex)
	xMutexHeld    fn (&Sqlite3_mutex) int
	xMutexNotheld fn (&Sqlite3_mutex) int
}

fn sqlite3_mutex_held(arg &Sqlite3_mutex) int

fn sqlite3_mutex_notheld(arg &Sqlite3_mutex) int

struct Sqlite3_pcache {}

struct Sqlite3_pcache_page {
	pBuf   voidptr
	pExtra voidptr
}

struct Sqlite3_pcache_methods2 {
	iVersion   int
	pArg       voidptr
	xInit      fn (voidptr) int
	xShutdown  fn (voidptr)
	xCreate    fn (int, int, int) &Sqlite3_pcache
	xCachesize fn (&Sqlite3_pcache, int)
	xPagecount fn (&Sqlite3_pcache) int
	xFetch     fn (&Sqlite3_pcache, u32, int) &Sqlite3_pcache_page
	xUnpin     fn (&Sqlite3_pcache, &Sqlite3_pcache_page, int)
	xRekey     fn (&Sqlite3_pcache, &Sqlite3_pcache_page, u32, u32)
	xTruncate  fn (&Sqlite3_pcache, u32)
	xDestroy   fn (&Sqlite3_pcache)
	xShrink    fn (&Sqlite3_pcache)
}

struct Sqlite3_pcache_methods {
	pArg       voidptr
	xInit      fn (voidptr) int
	xShutdown  fn (voidptr)
	xCreate    fn (int, int) &Sqlite3_pcache
	xCachesize fn (&Sqlite3_pcache, int)
	xPagecount fn (&Sqlite3_pcache) int
	xFetch     fn (&Sqlite3_pcache, u32, int) voidptr
	xUnpin     fn (&Sqlite3_pcache, voidptr, int)
	xRekey     fn (&Sqlite3_pcache, voidptr, u32, u32)
	xTruncate  fn (&Sqlite3_pcache, u32)
	xDestroy   fn (&Sqlite3_pcache)
}

fn sqlite3_unlock_notify(p_blocked &Sqlite3, x_notify fn (&voidptr, int), p_notify_arg voidptr) int

fn sqlite3_stmt_scanstatus(p_stmt &Sqlite3_stmt, idx int, i_scan_status_op int, p_out voidptr) int

fn sqlite3_stmt_scanstatus_v2(p_stmt &Sqlite3_stmt, idx int, i_scan_status_op int, flags int, p_out voidptr) int

fn sqlite3_stmt_scanstatus_reset(arg &Sqlite3_stmt)

struct Sqlite3_snapshot {
	hidden [48]u8
}

fn sqlite3_snapshot_get(db &Sqlite3, z_schema &i8, pp_snapshot &&Sqlite3_snapshot) int

fn sqlite3_snapshot_open(db &Sqlite3, z_schema &i8, p_snapshot &Sqlite3_snapshot) int

fn sqlite3_snapshot_free(arg &Sqlite3_snapshot)

fn sqlite3_snapshot_cmp(p1 &Sqlite3_snapshot, p2 &Sqlite3_snapshot) int

fn sqlite3_snapshot_recover(db &Sqlite3, z_db &i8) int

fn sqlite3_carray_bind_v2(p_stmt &Sqlite3_stmt, i int, a_data voidptr, n_data int, m_flags int, x_del fn (voidptr), p_del voidptr) int

fn sqlite3_carray_bind(p_stmt &Sqlite3_stmt, i int, a_data voidptr, n_data int, m_flags int, x_del fn (voidptr)) int

type Sqlite3_rtree_dbl = f64

fn sqlite3_rtree_geometry_callback(db &Sqlite3, z_geom &i8, x_geom fn (&Sqlite3_rtree_geometry, int, &Sqlite3_rtree_dbl, &int) int, p_context voidptr) int

struct Sqlite3_rtree_geometry {
	pContext voidptr
	nParam   int
	aParam   &Sqlite3_rtree_dbl
	pUser    voidptr
	xDelUser fn (voidptr)
}

fn sqlite3_rtree_query_callback(db &Sqlite3, z_query_func &i8, x_query_func fn (&Sqlite3_rtree_query_info) int, p_context voidptr, x_destructor fn (voidptr)) int

struct Sqlite3_rtree_query_info {
	pContext      voidptr
	nParam        int
	aParam        &Sqlite3_rtree_dbl
	pUser         voidptr
	xDelUser      fn (voidptr)
	aCoord        &Sqlite3_rtree_dbl
	anQueue       &u32
	nCoord        int
	iLevel        int
	mxLevel       int
	iRowid        Sqlite3_int64
	rParentScore  Sqlite3_rtree_dbl
	eParentWithin int
	eWithin       int
	rScore        Sqlite3_rtree_dbl
	apSqlParam    &&Sqlite3_value
}

struct Fts5Context {}

type Fts5_extension_function = fn (&Fts5ExtensionApi, &Fts5Context, &Sqlite3_context, int, &&Sqlite3_value)

struct Fts5PhraseIter {
	a &u8
	b &u8
}

struct Fts5ExtensionApi {
	iVersion           int
	xUserData          fn (&Fts5Context) voidptr
	xColumnCount       fn (&Fts5Context) int
	xRowCount          fn (&Fts5Context, &Sqlite3_int64) int
	xColumnTotalSize   fn (&Fts5Context, int, &Sqlite3_int64) int
	xTokenize          fn (&Fts5Context, &i8, int, voidptr, fn (voidptr, int, &i8, int, int, int) int) int
	xPhraseCount       fn (&Fts5Context) int
	xPhraseSize        fn (&Fts5Context, int) int
	xInstCount         fn (&Fts5Context, &int) int
	xInst              fn (&Fts5Context, int, &int, &int, &int) int
	xRowid             fn (&Fts5Context) Sqlite3_int64
	xColumnText        fn (&Fts5Context, int, &&u8, &int) int
	xColumnSize        fn (&Fts5Context, int, &int) int
	xQueryPhrase       fn (&Fts5Context, int, voidptr, fn (&Fts5ExtensionApi, &Fts5Context, voidptr) int) int
	xSetAuxdata        fn (&Fts5Context, voidptr, fn (voidptr)) int
	xGetAuxdata        fn (&Fts5Context, int) voidptr
	xPhraseFirst       fn (&Fts5Context, int, &Fts5PhraseIter, &int, &int) int
	xPhraseNext        fn (&Fts5Context, &Fts5PhraseIter, &int, &int)
	xPhraseFirstColumn fn (&Fts5Context, int, &Fts5PhraseIter, &int) int
	xPhraseNextColumn  fn (&Fts5Context, &Fts5PhraseIter, &int)
	xQueryToken        fn (&Fts5Context, int, int, &&u8, &int) int
	xInstToken         fn (&Fts5Context, int, int, &&u8, &int) int
	xColumnLocale      fn (&Fts5Context, int, &&u8, &int) int
	xTokenize_v2       fn (&Fts5Context, &i8, int, &i8, int, voidptr, fn (voidptr, int, &i8, int, int, int) int) int
}

struct Fts5Tokenizer {}

struct Fts5_tokenizer_v2 {
	iVersion  int
	xCreate   fn (voidptr, &&u8, int, &&Fts5Tokenizer) int
	xDelete   fn (&Fts5Tokenizer)
	xTokenize fn (&Fts5Tokenizer, voidptr, int, &i8, int, &i8, int, fn (voidptr, int, &i8, int, int, int) int) int
}

struct Fts5_tokenizer {
	xCreate   fn (voidptr, &&u8, int, &&Fts5Tokenizer) int
	xDelete   fn (&Fts5Tokenizer)
	xTokenize fn (&Fts5Tokenizer, voidptr, int, &i8, int, fn (voidptr, int, &i8, int, int, int) int) int
}

struct Fts5_api {
	iVersion            int
	xCreateTokenizer    fn (&Fts5_api, &i8, voidptr, &Fts5_tokenizer, fn (voidptr)) int
	xFindTokenizer      fn (&Fts5_api, &i8, &voidptr, &Fts5_tokenizer) int
	xCreateFunction     fn (&Fts5_api, &i8, voidptr, Fts5_extension_function, fn (voidptr)) int
	xCreateTokenizer_v2 fn (&Fts5_api, &i8, voidptr, &Fts5_tokenizer_v2, fn (voidptr)) int
	xFindTokenizer_v2   fn (&Fts5_api, &i8, &voidptr, &&Fts5_tokenizer_v2) int
}
