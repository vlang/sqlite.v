@[translated]
module main

struct PgHdr {
	pPage      &Sqlite3_pcache_page
	pData      voidptr
	pExtra     voidptr
	pCache     &PCache
	pDirty     &PgHdr
	pPager     &Pager
	pgno       Pgno
	flags      U16
	nRef       I64
	pDirtyNext &PgHdr
	pDirtyPrev &PgHdr
}
