@[translated]
module main

struct PgHdr1 {
	page        Sqlite3_pcache_page
	iKey        u32
	isBulkLocal U16
	isAnchor    U16
	pNext       &PgHdr1
	pCache      &PCache1
	pLruNext    &PgHdr1
	pLruPrev    &PgHdr1
}

struct PGroup {
	mutex      &Sqlite3_mutex
	nMaxPage   u32
	nMinPage   u32
	mxPinned   u32
	nPurgeable u32
	lru        PgHdr1
}

struct PCache1 {
	pGroup          &PGroup
	pnPurgeable     &u32
	szPage          int
	szExtra         int
	szAlloc         int
	bPurgeable      int
	nMin            u32
	nMax            u32
	n90pct          u32
	iMaxKey         u32
	nPurgeableDummy u32
	nRecyclable     u32
	nPage           u32
	nHash           u32
	apHash          &&PgHdr1
	pFree           &PgHdr1
	pBulk           voidptr
}

struct PgFreeslot {
	pNext &PgFreeslot
}

struct PCacheGlobal {
	grp            PGroup
	isInit         int
	separateCache  int
	nInitPage      int
	szSlot         int
	nSlot          int
	nReserve       int
	pStart         voidptr
	pEnd           voidptr
	mutex          &Sqlite3_mutex
	pFree          &PgFreeslot
	nFreeSlot      int
	bUnderPressure int
}

@[weak]
__global pcache1_g PCacheGlobal

@[c:'sqlite3PCacheBufferSetup']
fn sqlite3_pc_ache_buffer_setup(p_buf voidptr, sz int, n int) {
	if pcache1_g.isInit {
		p := &PgFreeslot(0)
		if usize(p_buf) == usize(0) {
			n = 0
			sz = n
		}
		if n == 0 {
			sz = 0
		}
		sz = (sz & ~7)
		pcache1_g.szSlot = sz
		pcache1_g.nFreeSlot = n
		pcache1_g.nSlot = pcache1_g.nFreeSlot
		pcache1_g.nReserve = if n > 90 { 10 } else { (n / 10 + 1) }
		pcache1_g.pStart = p_buf
		pcache1_g.pFree = 0
		C.c2v_atomic_store_n__int_int_int_((&pcache1_g.bUnderPressure), 0, 0)
		for n-- {
			p = &PgFreeslot(p_buf)
			p.pNext = pcache1_g.pFree
			pcache1_g.pFree = p
			p_buf = voidptr(unsafe { (&i8(p_buf)) + sz })
		}
		pcache1_g.pEnd = p_buf
	}
}

@[c:'pcache1InitBulk']
fn pcache1_init_bulk(p_cache &PCache1) int {
	sz_bulk := I64(0)
	z_bulk := &i8(0)
	if pcache1_g.nInitPage == 0 {
		return 0
	}
	if p_cache.nMax < u32(3) {
		return 0
	}
	sqlite3_begin_benign_malloc()
	if pcache1_g.nInitPage > 0 {
		sz_bulk = I64(p_cache.szAlloc) * I64(pcache1_g.nInitPage)
	} else {
		sz_bulk = I64(-1024) * I64(pcache1_g.nInitPage)
	}
	if sz_bulk > I64(p_cache.szAlloc) * I64(p_cache.nMax) {
		sz_bulk = I64(p_cache.szAlloc) * I64(p_cache.nMax)
	}
	if sz_bulk >= I64(p_cache.szAlloc) {
		p_cache.pBulk = sqlite3_malloc_vdup2(U64(sz_bulk))
		z_bulk = p_cache.pBulk
		sqlite3_end_benign_malloc()
		if z_bulk {
			n_bulk := sqlite3_malloc_size(voidptr(z_bulk)) / p_cache.szAlloc
			for {
				px := &PgHdr1(voidptr(unsafe { z_bulk + p_cache.szPage }))
				px.page.pBuf = z_bulk
				px.page.pExtra = &U8(voidptr(px)) + (((sizeof(PgHdr1)) + u64(7)) & u64(~7))
				px.isBulkLocal = U16(1)
				px.isAnchor = U16(0)
				px.pNext = p_cache.pFree
				px.pLruPrev = 0
				p_cache.pFree = px
				c2v_pointer_prefix(voidptr(&z_bulk), z_bulk, isize(p_cache.szAlloc))
				n_bulk--
				if !n_bulk {
					break
				}
			}
		}
	}
	return int(usize(p_cache.pFree) != usize(0))
}

@[c:'pcache1Alloc']
fn pcache1_alloc(n_byte int) voidptr {
	p := voidptr(0)
	if n_byte <= pcache1_g.szSlot {
		sqlite3_mutex_enter(pcache1_g.mutex)
		p = &PgHdr1(voidptr(pcache1_g.pFree))
		if p {
			pcache1_g.pFree = pcache1_g.pFree.pNext
			pcache1_g.nFreeSlot--
			C.c2v_atomic_store_n__int_int_int_((&pcache1_g.bUnderPressure), (pcache1_g.nFreeSlot < pcache1_g.nReserve), 0)
			sqlite3_status_highwater(7, n_byte)
			sqlite3_status_up(1, 1)
		}
		sqlite3_mutex_leave(pcache1_g.mutex)
	}
	if usize(p) == usize(0) {
		p = sqlite3_malloc_vdup2(U64(n_byte))
		if p {
			sz := sqlite3_malloc_size(voidptr(p))
			sqlite3_mutex_enter(pcache1_g.mutex)
			sqlite3_status_highwater(7, n_byte)
			sqlite3_status_up(2, sz)
			sqlite3_mutex_leave(pcache1_g.mutex)
		}
	}
	return p
}

@[c:'pcache1Free']
fn pcache1_free(p voidptr) {
	if usize(p) == usize(0) {
		return
	}
	if ((Uptr(p) >= Uptr(pcache1_g.pStart)) && (Uptr(p) < Uptr(pcache1_g.pEnd))) {
		p_slot := &PgFreeslot(0)
		sqlite3_mutex_enter(pcache1_g.mutex)
		sqlite3_status_down(1, 1)
		p_slot = &PgFreeslot(p)
		p_slot.pNext = pcache1_g.pFree
		pcache1_g.pFree = p_slot
		pcache1_g.nFreeSlot++
		C.c2v_atomic_store_n__int_int_int_((&pcache1_g.bUnderPressure), (pcache1_g.nFreeSlot < pcache1_g.nReserve), 0)
		sqlite3_mutex_leave(pcache1_g.mutex)
	} else {
		n_freed := 0
		n_freed = sqlite3_malloc_size(voidptr(p))
		sqlite3_mutex_enter(pcache1_g.mutex)
		sqlite3_status_down(2, n_freed)
		sqlite3_mutex_leave(pcache1_g.mutex)
		sqlite3_free(voidptr(p))
	}
}

@[c:'pcache1AllocPage']
fn pcache1_alloc_page(p_cache &PCache1, benign_malloc int) &PgHdr1 {
	p := unsafe { &PgHdr1(nil) }
	p_pg := &voidptr(0)
	if !isnil(p_cache.pFree) || (p_cache.nPage == u32(0) && pcache1_init_bulk(p_cache)) {
		p = p_cache.pFree
		p_cache.pFree = p.pNext
		p.pNext = 0
	} else {
		if benign_malloc {
			sqlite3_begin_benign_malloc()
		}
		p_pg = pcache1_alloc(p_cache.szAlloc)
		if benign_malloc {
			sqlite3_end_benign_malloc()
		}
		if usize(p_pg) == usize(0) {
			return unsafe { nil }
		}
		p = &PgHdr1(voidptr(unsafe { (&U8(p_pg)) + p_cache.szPage }))
		p.page.pBuf = p_pg
		p.page.pExtra = &U8(voidptr(p)) + (((sizeof(PgHdr1)) + u64(7)) & u64(~7))
		p.isBulkLocal = U16(0)
		p.isAnchor = U16(0)
		p.pLruPrev = 0
	}
	unsafe { (*p_cache.pnPurgeable)++ }
	return p
}

@[c:'pcache1FreePage']
fn pcache1_free_page(p &PgHdr1) {
	p_cache := &PCache1(0)
	p_cache = p.pCache
	if p.isBulkLocal {
		p.pNext = p_cache.pFree
		p_cache.pFree = p
	} else {
		pcache1_free(voidptr(p.page.pBuf))
	}
	unsafe { (*p_cache.pnPurgeable)-- }
}

@[c:'sqlite3PageMalloc']
fn sqlite3_page_malloc(sz int) voidptr {
	return pcache1_alloc(sz)
}

@[c:'sqlite3PageFree']
fn sqlite3_page_free(p voidptr) {
	pcache1_free(voidptr(p))
}

@[c:'pcache1UnderMemoryPressure']
fn pcache1_under_memory_pressure(p_cache &PCache1) int {
	if pcache1_g.nSlot && (p_cache.szPage + p_cache.szExtra) <= pcache1_g.szSlot {
		return C.c2v_atomic_load_n__int_int_int((&pcache1_g.bUnderPressure), 0)
	} else {
		return sqlite3_heap_nearly_full()
	}
}

@[c:'pcache1ResizeHash']
fn pcache1_resize_hash(p &PCache1) {
	ap_new := &&PgHdr1(0)
	n_new := U64(0)
	i := u32(0)
	n_new = U64(2) * U64(p.nHash)
	if n_new < U64(256) {
		n_new = U64(256)
	}
	if p.nHash {
		sqlite3_begin_benign_malloc()
	}
	ap_new = &&PgHdr1(sqlite3_malloc_zero(U64(sizeof(voidptr)) * n_new))
	if p.nHash {
		sqlite3_end_benign_malloc()
	}
	if ap_new {
		for i = u32(0); i < p.nHash; i++ {
			p_page := &PgHdr1(0)
			p_next := p.apHash[i]
			for {
				p_page = p_next
				if !(usize(p_page) != usize(0)) {
					break
				}
				h := u32(U64(p_page.iKey) % n_new)
				p_next = p_page.pNext
				p_page.pNext = ap_new[h]
				ap_new[h] = p_page
			}
		}
		sqlite3_free(voidptr(p.apHash))
		p.apHash = ap_new
		p.nHash = u32(n_new)
	}
}

@[c:'pcache1PinPage']
fn pcache1_pin_page(p_page &PgHdr1) &PgHdr1 {
	p_page.pLruPrev.pLruNext = p_page.pLruNext
	p_page.pLruNext.pLruPrev = p_page.pLruPrev
	p_page.pLruNext = 0
	p_page.pCache.nRecyclable--
	return p_page
}

@[c:'pcache1RemoveFromHash']
fn pcache1_remove_from_hash(p_page &PgHdr1, free_flag int) {
	h := u32(0)
	p_cache := p_page.pCache
	pp := &&PgHdr1(0)
	h = p_page.iKey % p_cache.nHash
	for pp = unsafe { p_cache.apHash + h }; usize((unsafe { *pp })) != usize(p_page); pp = &(unsafe { *pp }).pNext {
	}
	unsafe { *pp = (*pp).pNext }
	p_cache.nPage--
	if free_flag {
		pcache1_free_page(p_page)
	}
}

@[c:'pcache1EnforceMaxPage']
fn pcache1_enforce_max_page(p_cache &PCache1) {
	p_group := p_cache.pGroup
	p := &PgHdr1(0)
	for {
		if !(p_group.nPurgeable > p_group.nMaxPage && int(c2v_assign[&PgHdr1](unsafe { &p }, p_group.lru.pLruPrev).isAnchor) == 0) {
			break
		}
		pcache1_pin_page(p)
		pcache1_remove_from_hash(p, 1)
	}
	if p_cache.nPage == u32(0) && !isnil(p_cache.pBulk) {
		sqlite3_free(voidptr(p_cache.pBulk))
		p_cache.pFree = 0
		p_cache.pBulk = p_cache.pFree
	}
}

@[c:'pcache1TruncateUnsafe']
fn pcache1_truncate_unsafe(p_cache &PCache1, i_limit u32) {
	h := u32(0)
	i_stop := u32(0)

	if p_cache.iMaxKey - i_limit < p_cache.nHash {
		h = i_limit % p_cache.nHash
		i_stop = p_cache.iMaxKey % p_cache.nHash
	} else {
		h = p_cache.nHash / u32(2)
		i_stop = h - u32(1)
	}
	for {
		pp := &&PgHdr1(0)
		p_page := &PgHdr1(0)
		pp = unsafe { p_cache.apHash + h }
		for {
			p_page = unsafe { *pp }
			if !(usize(p_page) != usize(0)) {
				break
			}
			if p_page.iKey >= i_limit {
				p_cache.nPage--
				unsafe { *pp = p_page.pNext }
				if (usize(p_page.pLruNext) != usize(0)) {
					pcache1_pin_page(p_page)
				}
				pcache1_free_page(p_page)
			} else {
				pp = &p_page.pNext
			}
		}
		if h == i_stop {
			break
		}
		h = (h + u32(1)) % p_cache.nHash
	}
}

@[c:'pcache1Init']
fn pcache1_init(not_used voidptr) int {
	c2v_gc_register_thread()

	C.memset(voidptr(&pcache1_g), 0, sizeof(pcache1_g))
	pcache1_g.separateCache = usize(sqlite3Config.pPage) == usize(0) || int(sqlite3Config.bCoreMutex) > 0
	if sqlite3Config.bCoreMutex {
		pcache1_g.grp.mutex = sqlite3_mutex_alloc_vdup4(6)
		pcache1_g.mutex = sqlite3_mutex_alloc_vdup4(7)
	}
	if pcache1_g.separateCache && sqlite3Config.nPage != 0 && usize(sqlite3Config.pPage) == usize(0) {
		pcache1_g.nInitPage = sqlite3Config.nPage
	} else {
		pcache1_g.nInitPage = 0
	}
	pcache1_g.grp.mxPinned = u32(10)
	pcache1_g.isInit = 1
	return 0
}

@[c:'pcache1Shutdown']
fn pcache1_shutdown(not_used voidptr) {
	c2v_gc_register_thread()

	C.memset(voidptr(&pcache1_g), 0, sizeof(pcache1_g))
}

@[c:'pcache1Create']
fn pcache1_create(sz_page int, sz_extra int, b_purgeable int) &Sqlite3_pcache {
	c2v_gc_register_thread()
	p_cache := &PCache1(0)
	p_group := &PGroup(0)
	sz := I64(0)
	sz = I64(sizeof(PCache1) + sizeof(PGroup) * u64(pcache1_g.separateCache))
	p_cache = &PCache1(sqlite3_malloc_zero(U64(sz)))
	if p_cache {
		if pcache1_g.separateCache {
			p_group = &PGroup(voidptr(unsafe { p_cache + 1 }))
			p_group.mxPinned = u32(10)
		} else {
			p_group = &pcache1_g.grp
		}
		if int(p_group.lru.isAnchor) == 0 {
			p_group.lru.isAnchor = U16(1)
			p_group.lru.pLruNext = &p_group.lru
			p_group.lru.pLruPrev = p_group.lru.pLruNext
		}
		p_cache.pGroup = p_group
		p_cache.szPage = sz_page
		p_cache.szExtra = sz_extra
		p_cache.szAlloc = int(u64(sz_page + sz_extra) + (((sizeof(PgHdr1)) + u64(7)) & u64(~7)))
		p_cache.bPurgeable = (if b_purgeable { 1 } else { 0 })
		pcache1_resize_hash(p_cache)
		if b_purgeable {
			p_cache.nMin = u32(10)
			p_group.nMinPage += p_cache.nMin
			p_group.mxPinned = p_group.nMaxPage + u32(10) - p_group.nMinPage
			p_cache.pnPurgeable = &p_group.nPurgeable
		} else {
			p_cache.pnPurgeable = &p_cache.nPurgeableDummy
		}
		if p_cache.nHash == u32(0) {
			pcache1_destroy(&Sqlite3_pcache(voidptr(p_cache)))
			p_cache = 0
		}
	}
	return &Sqlite3_pcache(voidptr(p_cache))
}

@[c:'pcache1Cachesize']
fn pcache1_cachesize(p &Sqlite3_pcache, n_max int) {
	c2v_gc_register_thread()
	p_cache := &PCache1(voidptr(p))
	n := u32(0)
	if p_cache.bPurgeable {
		p_group := p_cache.pGroup
		n = u32(n_max)
		if n > u32(2147418112) - p_group.nMaxPage + p_cache.nMax {
			n = u32(2147418112) - p_group.nMaxPage + p_cache.nMax
		}
		p_group.nMaxPage += (n - p_cache.nMax)
		p_group.mxPinned = p_group.nMaxPage + u32(10) - p_group.nMinPage
		p_cache.nMax = n
		p_cache.n90pct = p_cache.nMax * u32(9) / u32(10)
		pcache1_enforce_max_page(p_cache)
	}
}

@[c:'pcache1Shrink']
fn pcache1_shrink(p &Sqlite3_pcache) {
	c2v_gc_register_thread()
	p_cache := &PCache1(voidptr(p))
	if p_cache.bPurgeable {
		p_group := p_cache.pGroup
		saved_max_page := u32(0)
		saved_max_page = p_group.nMaxPage
		p_group.nMaxPage = u32(0)
		pcache1_enforce_max_page(p_cache)
		p_group.nMaxPage = saved_max_page
	}
}

@[c:'pcache1Pagecount']
fn pcache1_pagecount(p &Sqlite3_pcache) int {
	c2v_gc_register_thread()
	n := 0
	p_cache := &PCache1(voidptr(p))
	n = int(p_cache.nPage)
	return n
}

@[c:'pcache1FetchStage2']
fn pcache1_fetch_stage2(p_cache &PCache1, i_key u32, create_flag int) &PgHdr1 {
	n_pinned := u32(0)
	p_group := p_cache.pGroup
	p_page := unsafe { &PgHdr1(nil) }
	n_pinned = p_cache.nPage - p_cache.nRecyclable
	if create_flag == 1 && (n_pinned >= p_group.mxPinned || n_pinned >= p_cache.n90pct || (pcache1_under_memory_pressure(p_cache) && p_cache.nRecyclable < n_pinned)) {
		return unsafe { nil }
	}
	if p_cache.nPage >= p_cache.nHash {
		pcache1_resize_hash(p_cache)
	}
	if p_cache.bPurgeable && !p_group.lru.pLruPrev.isAnchor && ((p_cache.nPage + u32(1) >= p_cache.nMax) || pcache1_under_memory_pressure(p_cache)) {
		p_other := &PCache1(0)
		p_page = p_group.lru.pLruPrev
		pcache1_remove_from_hash(p_page, 0)
		pcache1_pin_page(p_page)
		p_other = p_page.pCache
		if p_other.szAlloc != p_cache.szAlloc {
			pcache1_free_page(p_page)
			p_page = 0
		} else {
			p_group.nPurgeable -= u32((p_other.bPurgeable - p_cache.bPurgeable))
		}
	}
	if isnil(p_page) {
		p_page = pcache1_alloc_page(p_cache, create_flag == 1)
	}
	if p_page {
		h := i_key % p_cache.nHash
		p_cache.nPage++
		p_page.iKey = i_key
		p_page.pNext = p_cache.apHash[h]
		p_page.pCache = p_cache
		p_page.pLruNext = 0
		mut __c2v_lhs_tmp_71 := unsafe { &voidptr(p_page.page.pExtra) }
		unsafe { *__c2v_lhs_tmp_71 = 0 }
		p_cache.apHash[h] = p_page
		if i_key > p_cache.iMaxKey {
			p_cache.iMaxKey = i_key
		}
	}
	return p_page
}

@[c:'pcache1FetchNoMutex']
fn pcache1_fetch_no_mutex(p &Sqlite3_pcache, i_key u32, create_flag int) &PgHdr1 {
	p_cache := &PCache1(voidptr(p))
	p_page := unsafe { &PgHdr1(nil) }
	p_page = p_cache.apHash[i_key % p_cache.nHash]
	for !isnil(p_page) && p_page.iKey != i_key {
		p_page = p_page.pNext
	}
	if p_page {
		if (usize(p_page.pLruNext) != usize(0)) {
			return pcache1_pin_page(p_page)
		} else {
			return p_page
		}
	} else if create_flag {
		return pcache1_fetch_stage2(p_cache, i_key, create_flag)
	} else {
		return unsafe { nil }
	}
}

@[c:'pcache1Fetch']
fn pcache1_fetch(p &Sqlite3_pcache, i_key u32, create_flag int) &Sqlite3_pcache_page {
	c2v_gc_register_thread()
	return &Sqlite3_pcache_page(voidptr(pcache1_fetch_no_mutex(p, i_key, create_flag)))
}

@[c:'pcache1Unpin']
fn pcache1_unpin(p &Sqlite3_pcache, p_pg &Sqlite3_pcache_page, reuse_unlikely int) {
	c2v_gc_register_thread()
	p_cache := &PCache1(voidptr(p))
	p_page := &PgHdr1(voidptr(p_pg))
	p_group := p_cache.pGroup
	if reuse_unlikely || p_group.nPurgeable > p_group.nMaxPage {
		pcache1_remove_from_hash(p_page, 1)
	} else {
		pp_first := &p_group.lru.pLruNext
		p_page.pLruPrev = &p_group.lru
		unsafe { c2v_assign[&PgHdr1](&p_page.pLruNext, *pp_first).pLruPrev = p_page }
		unsafe { *pp_first = p_page }
		p_cache.nRecyclable++
	}
}

@[c:'pcache1Rekey']
fn pcache1_rekey(p &Sqlite3_pcache, p_pg &Sqlite3_pcache_page, i_old u32, i_new u32) {
	c2v_gc_register_thread()
	p_cache := &PCache1(voidptr(p))
	p_page := &PgHdr1(voidptr(p_pg))
	pp := &&PgHdr1(0)
	h_old := u32(0)
	h_new := u32(0)

	h_old = i_old % p_cache.nHash
	pp = unsafe { p_cache.apHash + h_old }
	for usize((unsafe { *pp })) != usize(p_page) {
		pp = &(unsafe { *pp }).pNext
	}
	unsafe { *pp = p_page.pNext }
	h_new = i_new % p_cache.nHash
	p_page.iKey = i_new
	p_page.pNext = p_cache.apHash[h_new]
	p_cache.apHash[h_new] = p_page
	if i_new > p_cache.iMaxKey {
		p_cache.iMaxKey = i_new
	}
}

@[c:'pcache1Truncate']
fn pcache1_truncate(p &Sqlite3_pcache, i_limit u32) {
	c2v_gc_register_thread()
	p_cache := &PCache1(voidptr(p))
	if i_limit <= p_cache.iMaxKey {
		pcache1_truncate_unsafe(p_cache, i_limit)
		p_cache.iMaxKey = i_limit - u32(1)
	}
}

@[c:'pcache1Destroy']
fn pcache1_destroy(p &Sqlite3_pcache) {
	c2v_gc_register_thread()
	p_cache := &PCache1(voidptr(p))
	p_group := p_cache.pGroup
	if p_cache.nPage {
		pcache1_truncate_unsafe(p_cache, u32(0))
	}
	p_group.nMaxPage -= p_cache.nMax
	p_group.nMinPage -= p_cache.nMin
	p_group.mxPinned = p_group.nMaxPage + u32(10) - p_group.nMinPage
	pcache1_enforce_max_page(p_cache)
	sqlite3_free(voidptr(p_cache.pBulk))
	sqlite3_free(voidptr(p_cache.apHash))
	sqlite3_free(voidptr(p_cache))
}

@[c:'sqlite3PCacheSetDefault']
fn sqlite3_pc_ache_set_default() {
	if !sqlite3_pc_ache_set_default_default_methods_inited {
		sqlite3_pc_ache_set_default_default_methods = Sqlite3_pcache_methods2{
			iVersion: 1
			pArg: 0
			xInit: pcache1_init
			xShutdown: pcache1_shutdown
			xCreate: pcache1_create
			xCachesize: pcache1_cachesize
			xPagecount: pcache1_pagecount
			xFetch: pcache1_fetch
			xUnpin: pcache1_unpin
			xRekey: pcache1_rekey
			xTruncate: pcache1_truncate
			xDestroy: pcache1_destroy
			xShrink: pcache1_shrink
		}

		sqlite3_pc_ache_set_default_default_methods_inited = true
	}

	sqlite3_config_fn(18, voidptr(&sqlite3_pc_ache_set_default_default_methods))
}

@[c:'sqlite3HeaderSizePcache1']
fn sqlite3_header_size_pcache1() int {
	return int((((sizeof(PgHdr1)) + u64(7)) & u64(~7)))
}

@[c:'sqlite3Pcache1Mutex']
fn sqlite3_pcache1_mutex() &Sqlite3_mutex {
	return pcache1_g.mutex
}
