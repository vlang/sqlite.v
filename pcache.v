@[translated]
module main

struct PCache {
	pDirty     &PgHdr
	pDirtyTail &PgHdr
	pSynced    &PgHdr
	nRefSum    I64
	szCache    int
	szSpill    int
	szPage     int
	szExtra    int
	bPurgeable U8
	eCreate    U8
	xStress    fn (voidptr, &PgHdr) int
	pStress    voidptr
	pCache     &Sqlite3_pcache
}

@[c:'pcacheManageDirtyList']
fn pcache_manage_dirty_list(p_page &PgHdr, add_remove U8) {
	p := p_page.pCache
	if int(add_remove) & 1 {
		if usize(p.pSynced) == usize(p_page) {
			p.pSynced = p_page.pDirtyPrev
		}
		if p_page.pDirtyNext {
			p_page.pDirtyNext.pDirtyPrev = p_page.pDirtyPrev
		} else {
			p.pDirtyTail = p_page.pDirtyPrev
		}
		if p_page.pDirtyPrev {
			p_page.pDirtyPrev.pDirtyNext = p_page.pDirtyNext
		} else {
			p.pDirty = p_page.pDirtyNext
			if usize(p.pDirty) == usize(0) {
				p.eCreate = U8(2)
			}
		}
	}
	if int(add_remove) & 2 {
		p_page.pDirtyPrev = 0
		p_page.pDirtyNext = p.pDirty
		if p_page.pDirtyNext {
			p_page.pDirtyNext.pDirtyPrev = p_page
		} else {
			p.pDirtyTail = p_page
			if p.bPurgeable {
				p.eCreate = U8(1)
			}
		}
		p.pDirty = p_page
		if isnil(p.pSynced) && 0 == (int(p_page.flags) & 8) {
			p.pSynced = p_page
		}
	}
}

@[c:'pcacheUnpin']
fn pcache_unpin(p &PgHdr) {
	if p.pCache.bPurgeable {
		sqlite3Config.pcache2.xUnpin(p.pCache.pCache, p.pPage, 0)
	}
}

@[c:'numberOfCachePages']
fn number_of_cache_pages(p &PCache) int {
	if p.szCache >= 0 {
		return p.szCache
	} else {
		n := I64(0)
		n = ((I64(-1024) * I64(p.szCache)) / I64((p.szPage + p.szExtra)))
		if n > I64(1000000000) {
			n = I64(1000000000)
		}
		return int(n)
	}
}

@[c:'sqlite3PcacheInitialize']
fn sqlite3_pcache_initialize() int {
	if isnil(sqlite3Config.pcache2.xInit) {
		sqlite3_pc_ache_set_default()
	}
	return sqlite3Config.pcache2.xInit(voidptr(sqlite3Config.pcache2.pArg))
}

@[c:'sqlite3PcacheShutdown']
fn sqlite3_pcache_shutdown() {
	if sqlite3Config.pcache2.xShutdown {
		sqlite3Config.pcache2.xShutdown(voidptr(sqlite3Config.pcache2.pArg))
	}
}

@[c:'sqlite3PcacheSize']
fn sqlite3_pcache_size() int {
	return int(sizeof(PCache))
}

@[c:'sqlite3PcacheOpen']
fn sqlite3_pcache_open(sz_page int, sz_extra int, b_purgeable int, x_stress fn (voidptr, &PgHdr) int, p_stress voidptr, p &PCache) int {
	C.memset(voidptr(p), 0, sizeof(PCache))
	p.szPage = 1
	p.szExtra = sz_extra
	p.bPurgeable = U8(b_purgeable)
	p.eCreate = U8(2)
	p.xStress = x_stress
	p.pStress = p_stress
	p.szCache = 100
	p.szSpill = 1
	return sqlite3_pcache_set_page_size(p, sz_page)
}

@[c:'sqlite3PcacheSetPageSize']
fn sqlite3_pcache_set_page_size(p_cache &PCache, sz_page int) int {
	if p_cache.szPage {
		p_new := &Sqlite3_pcache(0)
		p_new = sqlite3Config.pcache2.xCreate(sz_page, int(u64(p_cache.szExtra) + (((sizeof(PgHdr)) + u64(7)) & u64(~7))), int(p_cache.bPurgeable))
		if usize(p_new) == usize(0) {
			return 7
		}
		sqlite3Config.pcache2.xCachesize(p_new, number_of_cache_pages(p_cache))
		if p_cache.pCache {
			sqlite3Config.pcache2.xDestroy(p_cache.pCache)
		}
		p_cache.pCache = p_new
		p_cache.szPage = sz_page
	}
	return 0
}

@[c:'sqlite3PcacheFetch']
fn sqlite3_pcache_fetch(p_cache &PCache, pgno Pgno, create_flag int) &Sqlite3_pcache_page {
	e_create := 0
	p_res := &Sqlite3_pcache_page(0)
	e_create = create_flag & int(p_cache.eCreate)
	p_res = sqlite3Config.pcache2.xFetch(p_cache.pCache, pgno, e_create)
	return p_res
}

@[c:'sqlite3PcacheFetchStress']
fn sqlite3_pcache_fetch_stress(p_cache &PCache, pgno Pgno, pp_page &&Sqlite3_pcache_page) int {
	p_pg := &PgHdr(0)
	if int(p_cache.eCreate) == 2 {
		return 0
	}
	if sqlite3_pcache_pagecount(p_cache) > p_cache.szSpill {
		for p_pg = p_cache.pSynced; !isnil(p_pg) && (p_pg.nRef || (int(p_pg.flags) & 8)); p_pg = p_pg.pDirtyPrev {
		}
		p_cache.pSynced = p_pg
		if isnil(p_pg) {
			for p_pg = p_cache.pDirtyTail; !isnil(p_pg) && p_pg.nRef; p_pg = p_pg.pDirtyPrev {
			}
		}
		if p_pg {
			rc := 0
			rc = p_cache.xStress(voidptr(p_cache.pStress), p_pg)
			if rc != 0 && rc != 5 {
				return rc
			}
		}
	}
	unsafe { *pp_page = sqlite3Config.pcache2.xFetch(p_cache.pCache, pgno, 2) }
	return if usize((unsafe { *pp_page })) == usize(0) { 7 } else { 0 }
}

@[c:'pcacheFetchFinishWithInit']
fn pcache_fetch_finish_with_init(p_cache &PCache, pgno Pgno, p_page &Sqlite3_pcache_page) &PgHdr {
	p_pg_hdr := &PgHdr(0)
	p_pg_hdr = &PgHdr(p_page.pExtra)
	C.memset(voidptr(&p_pg_hdr.pDirty), 0, sizeof(PgHdr) - (u64(usize(__offsetof(PgHdr, pDirty)))))
	p_pg_hdr.pPage = p_page
	p_pg_hdr.pData = p_page.pBuf
	p_pg_hdr.pExtra = voidptr(unsafe { p_pg_hdr + 1 })
	C.memset(voidptr(p_pg_hdr.pExtra), 0, u64(8))
	p_pg_hdr.pCache = p_cache
	p_pg_hdr.pgno = pgno
	p_pg_hdr.flags = U16(1)
	return sqlite3_pcache_fetch_finish(p_cache, pgno, p_page)
}

@[c:'sqlite3PcacheFetchFinish']
fn sqlite3_pcache_fetch_finish(p_cache &PCache, pgno Pgno, p_page &Sqlite3_pcache_page) &PgHdr {
	p_pg_hdr := &PgHdr(0)
	p_pg_hdr = &PgHdr(p_page.pExtra)
	if isnil(p_pg_hdr.pPage) {
		return pcache_fetch_finish_with_init(p_cache, pgno, p_page)
	}
	p_cache.nRefSum++
	p_pg_hdr.nRef++
	return p_pg_hdr
}

@[c:'sqlite3PcacheRelease']
fn sqlite3_pcache_release(p &PgHdr) {
	p.pCache.nRefSum--
	p.nRef--
	if (p.nRef) == I64(0) {
		if int(p.flags) & 1 {
			pcache_unpin(p)
		} else {
			pcache_manage_dirty_list(p, U8(3))
		}
	}
}

@[c:'sqlite3PcacheRef']
fn sqlite3_pcache_ref(p &PgHdr) {
	p.nRef++
	p.pCache.nRefSum++
}

@[c:'sqlite3PcacheDrop']
fn sqlite3_pcache_drop(p &PgHdr) {
	if int(p.flags) & 2 {
		pcache_manage_dirty_list(p, U8(1))
	}
	p.pCache.nRefSum--
	sqlite3Config.pcache2.xUnpin(p.pCache.pCache, p.pPage, 1)
}

@[c:'sqlite3PcacheMakeDirty']
fn sqlite3_pcache_make_dirty(p &PgHdr) {
	if int(p.flags) & (1 | 16) {
		p.flags &= ~16
		if int(p.flags) & 1 {
			p.flags ^= (2 | 1)
			pcache_manage_dirty_list(p, U8(2))
		}
	}
}

@[c:'sqlite3PcacheMakeClean']
fn sqlite3_pcache_make_clean(p &PgHdr) {
	pcache_manage_dirty_list(p, U8(1))
	p.flags &= ~(2 | 8 | 4)
	p.flags |= 1
	if p.nRef == I64(0) {
		pcache_unpin(p)
	}
}

@[c:'sqlite3PcacheCleanAll']
fn sqlite3_pcache_clean_all(p_cache &PCache) {
	p := &PgHdr(0)
	for {
		p = p_cache.pDirty
		if !(usize(p) != usize(0)) {
			break
		}
		sqlite3_pcache_make_clean(p)
	}
}

@[c:'sqlite3PcacheClearWritable']
fn sqlite3_pcache_clear_writable(p_cache &PCache) {
	p := &PgHdr(0)
	for p = p_cache.pDirty; p; p = p.pDirtyNext {
		p.flags &= ~(8 | 4)
	}
	p_cache.pSynced = p_cache.pDirtyTail
}

@[c:'sqlite3PcacheClearSyncFlags']
fn sqlite3_pcache_clear_sync_flags(p_cache &PCache) {
	p := &PgHdr(0)
	for p = p_cache.pDirty; p; p = p.pDirtyNext {
		p.flags &= ~8
	}
	p_cache.pSynced = p_cache.pDirtyTail
}

@[c:'sqlite3PcacheMove']
fn sqlite3_pcache_move(p &PgHdr, new_pgno Pgno) {
	p_cache := p.pCache
	p_other := &Sqlite3_pcache_page(0)
	p_other = sqlite3Config.pcache2.xFetch(p_cache.pCache, new_pgno, 0)
	if p_other {
		pxp_age := &PgHdr(p_other.pExtra)
		pxp_age.nRef++
		p_cache.nRefSum++
		sqlite3_pcache_drop(pxp_age)
	}
	sqlite3Config.pcache2.xRekey(p_cache.pCache, p.pPage, p.pgno, new_pgno)
	p.pgno = new_pgno
	if (int(p.flags) & 2) && (int(p.flags) & 8) {
		pcache_manage_dirty_list(p, U8(3))
	}
}

@[c:'sqlite3PcacheTruncate']
fn sqlite3_pcache_truncate(p_cache &PCache, pgno Pgno) {
	if p_cache.pCache {
		p := &PgHdr(0)
		p_next := &PgHdr(0)
		for p = p_cache.pDirty; p; p = p_next {
			p_next = p.pDirtyNext
			if p.pgno > pgno {
				sqlite3_pcache_make_clean(p)
			}
		}
		if pgno == Pgno(0) && p_cache.nRefSum {
			p_page1 := &Sqlite3_pcache_page(0)
			p_page1 = sqlite3Config.pcache2.xFetch(p_cache.pCache, u32(1), 0)
			if p_page1 {
				C.memset(voidptr(p_page1.pBuf), 0, u64(p_cache.szPage))
				pgno = Pgno(1)
			}
		}
		sqlite3Config.pcache2.xTruncate(p_cache.pCache, pgno + Pgno(1))
	}
}

@[c:'sqlite3PcacheClose']
fn sqlite3_pcache_close(p_cache &PCache) {
	sqlite3Config.pcache2.xDestroy(p_cache.pCache)
}

@[c:'sqlite3PcacheClear']
fn sqlite3_pcache_clear(p_cache &PCache) {
	sqlite3_pcache_truncate(p_cache, Pgno(0))
}

@[c:'pcacheMergeDirtyList']
fn pcache_merge_dirty_list(pa &PgHdr, pb &PgHdr) &PgHdr {
	result := PgHdr{}
	p_tail := &PgHdr(0)

	p_tail = &result
	for {
		if pa.pgno < pb.pgno {
			p_tail.pDirty = pa
			p_tail = pa
			pa = pa.pDirty
			if usize(pa) == usize(0) {
				p_tail.pDirty = pb
				break
			}
		} else {
			p_tail.pDirty = pb
			p_tail = pb
			pb = pb.pDirty
			if usize(pb) == usize(0) {
				p_tail.pDirty = pa
				break
			}
		}
	}
	return result.pDirty
}

@[c:'pcacheSortDirtyList']
fn pcache_sort_dirty_list(p_in &PgHdr) &PgHdr {
	a := [32]&PgHdr{}
	p := &PgHdr(0)

	i := 0
	C.memset(voidptr(unsafe { &a[0] }), 0, sizeof([32]&PgHdr))
	for p_in {
		p = p_in
		p_in = p.pDirty
		p.pDirty = 0
		for i = 0; (i < 32 - 1); i++ {
			if usize(a[i]) == usize(0) {
				a[i] = p
				break
			} else {
				p = pcache_merge_dirty_list(a[i], p)
				a[i] = 0
			}
		}
		if (i == 32 - 1) {
			a[i] = pcache_merge_dirty_list(a[i], p)
		}
	}
	p = a[0]
	for i = 1; i < 32; i++ {
		if usize(a[i]) == usize(0) {
			continue
		}
		p = if p { pcache_merge_dirty_list(p, a[i]) } else { a[i] }
	}
	return p
}

@[c:'sqlite3PcacheDirtyList']
fn sqlite3_pcache_dirty_list(p_cache &PCache) &PgHdr {
	p := &PgHdr(0)
	for p = p_cache.pDirty; p; p = p.pDirtyNext {
		p.pDirty = p.pDirtyNext
	}
	return pcache_sort_dirty_list(p_cache.pDirty)
}

@[c:'sqlite3PcacheRefCount']
fn sqlite3_pcache_ref_count(p_cache &PCache) I64 {
	return p_cache.nRefSum
}

@[c:'sqlite3PcachePageRefcount']
fn sqlite3_pcache_page_refcount(p &PgHdr) I64 {
	return p.nRef
}

@[c:'sqlite3PcachePagecount']
fn sqlite3_pcache_pagecount(p_cache &PCache) int {
	return sqlite3Config.pcache2.xPagecount(p_cache.pCache)
}

@[c:'sqlite3PcacheSetCachesize']
fn sqlite3_pcache_set_cachesize(p_cache &PCache, mx_page int) {
	p_cache.szCache = mx_page
	sqlite3Config.pcache2.xCachesize(p_cache.pCache, number_of_cache_pages(p_cache))
}

@[c:'sqlite3PcacheSetSpillsize']
fn sqlite3_pcache_set_spillsize(p &PCache, mx_page int) int {
	res := 0
	if mx_page {
		if mx_page < 0 {
			mx_page = int(((I64(-1024) * I64(mx_page)) / I64((p.szPage + p.szExtra))))
		}
		p.szSpill = mx_page
	}
	res = number_of_cache_pages(p)
	if res < p.szSpill {
		res = p.szSpill
	}
	return res
}

@[c:'sqlite3PcacheShrink']
fn sqlite3_pcache_shrink(p_cache &PCache) {
	sqlite3Config.pcache2.xShrink(p_cache.pCache)
}

@[c:'sqlite3HeaderSizePcache']
fn sqlite3_header_size_pcache() int {
	return int((((sizeof(PgHdr)) + u64(7)) & u64(~7)))
}

@[c:'sqlite3PCachePercentDirty']
fn sqlite3_pc_ache_percent_dirty(p_cache &PCache) int {
	p_dirty := &PgHdr(0)
	n_dirty := 0
	n_cache := number_of_cache_pages(p_cache)
	for p_dirty = p_cache.pDirty; p_dirty; p_dirty = p_dirty.pDirtyNext {
		n_dirty++
	}
	return if n_cache { int(((I64(n_dirty) * I64(100)) / I64(n_cache))) } else { 0 }
}

@[c:'sqlite3PCacheIsDirty']
fn sqlite3_pc_ache_is_dirty(p_cache &PCache) int {
	return int((usize(p_cache.pDirty) != usize(0)))
}
