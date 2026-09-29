@[translated]
module main

fn sqlite3_enable_shared_cache(enable int) int {
	c2v_gc_register_thread()
	sqlite3Config.sharedCacheEnabled = enable
	return 0
}

@[c:'querySharedCacheTableLock']
fn query_shared_cache_table_lock(p &Btree, i_tab Pgno, e_lock U8) int {
	p_bt := p.pBt
	p_iter := &BtLock(0)
	if !p.sharable {
		return 0
	}
	if usize(p_bt.pWriter) != usize(p) && (int(p_bt.btsFlags) & 64) != 0 {
		0
		return 6 | (1 << 8)
	}
	for p_iter = p_bt.pLock; p_iter; p_iter = p_iter.pNext {
		if usize(p_iter.pBtree) != usize(p) && p_iter.iTable == i_tab && int(p_iter.eLock) != int(e_lock) {
			0
			if int(e_lock) == 2 {
				p_bt.btsFlags |= 128
			}
			return 6 | (1 << 8)
		}
	}
	return 0
}

@[c:'setSharedCacheTableLock']
fn set_shared_cache_table_lock(p &Btree, i_table Pgno, e_lock U8) int {
	p_bt := p.pBt
	p_lock := unsafe { &BtLock(nil) }
	p_iter := &BtLock(0)
	0
	for p_iter = p_bt.pLock; p_iter; p_iter = p_iter.pNext {
		if p_iter.iTable == i_table && usize(p_iter.pBtree) == usize(p) {
			p_lock = p_iter
			break
		}
	}
	if isnil(p_lock) {
		p_lock = &BtLock(sqlite3_malloc_zero(U64(sizeof(BtLock))))
		if isnil(p_lock) {
			return 7
		}
		p_lock.iTable = i_table
		p_lock.pBtree = p
		p_lock.pNext = p_bt.pLock
		p_bt.pLock = p_lock
	}
	if int(e_lock) > int(p_lock.eLock) {
		p_lock.eLock = e_lock
	}
	return 0
}

@[c:'clearAllSharedCacheTableLocks']
fn clear_all_shared_cache_table_locks(p &Btree) {
	p_bt := p.pBt
	pp_iter := &p_bt.pLock
	0
	for unsafe { *pp_iter != nil } {
		p_lock := (unsafe { *pp_iter })
		if usize(p_lock.pBtree) == usize(p) {
			unsafe { *pp_iter = p_lock.pNext }
			if p_lock.iTable != Pgno(1) {
				sqlite3_free(voidptr(p_lock))
			}
		} else {
			pp_iter = &p_lock.pNext
		}
	}
	if usize(p_bt.pWriter) == usize(p) {
		p_bt.pWriter = 0
		p_bt.btsFlags &= ~(64 | 128)
	} else if p_bt.nTransaction == 2 {
		p_bt.btsFlags &= ~128
	}
}

@[c:'downgradeAllSharedCacheTableLocks']
fn downgrade_all_shared_cache_table_locks(p &Btree) {
	p_bt := p.pBt
	0
	if usize(p_bt.pWriter) == usize(p) {
		p_lock := &BtLock(0)
		p_bt.pWriter = 0
		p_bt.btsFlags &= ~(64 | 128)
		for p_lock = p_bt.pLock; p_lock; p_lock = p_lock.pNext {
			p_lock.eLock = U8(1)
		}
	}
}

@[c:'invalidateAllOverflowCache']
fn invalidate_all_overflow_cache(p_bt &BtShared) {
	p := &BtCursor(0)
	for p = p_bt.pCursor; p; p = p.pNext {
		p.curFlags &= ~4
	}
}

@[c:'invalidateIncrblobCursors']
fn invalidate_incrblob_cursors(p_btree &Btree, pgno_root Pgno, i_row I64, is_clear_table int) {
	p := &BtCursor(0)
	p_btree.hasIncrblobCur = U8(0)
	for p = p_btree.pBt.pCursor; p; p = p.pNext {
		if (int(p.curFlags) & 16) != 0 {
			p_btree.hasIncrblobCur = U8(1)
			if p.pgnoRoot == pgno_root && (is_clear_table || p.info.nKey == i_row) {
				p.eState = U8(1)
			}
		}
	}
}

@[c:'btreeSetHasContent']
fn btree_set_has_content(p_bt &BtShared, pgno Pgno) int {
	rc := 0
	if isnil(p_bt.pHasContent) {
		p_bt.pHasContent = sqlite3_bitvec_create(p_bt.nPage)
		if isnil(p_bt.pHasContent) {
			rc = 7
		}
	}
	if rc == 0 && pgno <= sqlite3_bitvec_size(p_bt.pHasContent) {
		rc = sqlite3_bitvec_set(p_bt.pHasContent, pgno)
	}
	return rc
}

@[c:'btreeGetHasContent']
fn btree_get_has_content(p_bt &BtShared, pgno Pgno) int {
	p := p_bt.pHasContent
	return int(!isnil(p) && (pgno > sqlite3_bitvec_size(p) || sqlite3_bitvec_test_not_null(p, pgno)))
}

@[c:'btreeClearHasContent']
fn btree_clear_has_content(p_bt &BtShared) {
	sqlite3_bitvec_destroy(p_bt.pHasContent)
	p_bt.pHasContent = 0
}

@[c:'btreeReleaseAllCursorPages']
fn btree_release_all_cursor_pages(p_cur &BtCursor) {
	i := 0
	if int(p_cur.iPage) >= 0 {
		for i = 0; i < int(p_cur.iPage); i++ {
			release_page_not_null(p_cur.apPage[i])
		}
		release_page_not_null(p_cur.pPage)
		p_cur.iPage = I8(-1)
	}
}

@[c:'saveCursorKey']
fn save_cursor_key(p_cur &BtCursor) int {
	rc := 0
	if p_cur.curIntKey {
		p_cur.nKey = sqlite3_btree_integer_key(p_cur)
	} else {
		p_key := &voidptr(0)
		p_cur.nKey = I64(sqlite3_btree_payload_size(p_cur))
		p_key = sqlite3_malloc_vdup2(U64((I64(p_cur.nKey)) + I64(9) + I64(8)))
		if p_key {
			rc = sqlite3_btree_payload(p_cur, u32(0), u32(int(p_cur.nKey)), voidptr(p_key))
			if rc == 0 {
				C.memset(voidptr((&U8(p_key)) + p_cur.nKey), 0, u64(9 + 8))
				p_cur.pKey = p_key
			} else {
				sqlite3_free(voidptr(p_key))
			}
		} else {
			rc = 7
		}
	}
	return rc
}

@[c:'saveCursorPosition']
fn save_cursor_position(p_cur &BtCursor) int {
	rc := 0
	if int(p_cur.curFlags) & 64 {
		return 19 | (11 << 8)
	}
	if int(p_cur.eState) == 2 {
		p_cur.eState = U8(0)
	} else {
		p_cur.skipNext = 0
	}
	rc = save_cursor_key(p_cur)
	if rc == 0 {
		btree_release_all_cursor_pages(p_cur)
		p_cur.eState = U8(3)
	}
	p_cur.curFlags &= ~(2 | 4 | 8)
	return rc
}

@[c:'saveAllCursors']
fn save_all_cursors(p_bt &BtShared, i_root Pgno, p_except &BtCursor) int {
	p := &BtCursor(0)
	for p = p_bt.pCursor; p; p = p.pNext {
		if usize(p) != usize(p_except) && (Pgno(0) == i_root || p.pgnoRoot == i_root) {
			break
		}
	}
	if p {
		return save_cursors_on_list(p, i_root, p_except)
	}
	if p_except {
		p_except.curFlags &= ~32
	}
	return 0
}

@[c:'saveCursorsOnList']
fn save_cursors_on_list(p &BtCursor, i_root Pgno, p_except &BtCursor) int {
	for {
		if usize(p) != usize(p_except) && (Pgno(0) == i_root || p.pgnoRoot == i_root) {
			if int(p.eState) == 0 || int(p.eState) == 2 {
				rc := save_cursor_position(p)
				if 0 != rc {
					return rc
				}
			} else {
				0
				btree_release_all_cursor_pages(p)
			}
		}
		p = p.pNext
		if !p {
			break
		}
	}
	return 0
}

@[c:'sqlite3BtreeClearCursor']
fn sqlite3_btree_clear_cursor(p_cur &BtCursor) {
	sqlite3_free(voidptr(p_cur.pKey))
	p_cur.pKey = 0
	p_cur.eState = U8(1)
}

@[c:'btreeMoveto']
fn btree_moveto(p_cur &BtCursor, p_key voidptr, n_key I64, bias int, p_res &int) int {
	rc := 0
	p_idx_key := &UnpackedRecord(0)
	if p_key {
		p_key_info := p_cur.pKeyInfo
		p_idx_key = sqlite3_vdbe_alloc_unpacked_record(p_key_info)
		if usize(p_idx_key) == usize(0) {
			return 7
		}
		sqlite3_vdbe_record_unpack(int(n_key), voidptr(p_key), p_idx_key)
		if int(p_idx_key.nField) == 0 || int(p_idx_key.nField) > int(p_key_info.nAllField) {
			rc = sqlite3_corrupt_error(877)
		} else {
			rc = sqlite3_btree_index_moveto(p_cur, p_idx_key, p_res)
		}
		sqlite3_db_free(p_cur.pKeyInfo.db, voidptr(p_idx_key))
	} else {
		p_idx_key = 0
		rc = sqlite3_btree_table_moveto(p_cur, n_key, bias, p_res)
	}
	return rc
}

@[c:'btreeRestoreCursorPosition']
fn btree_restore_cursor_position(p_cur &BtCursor) int {
	rc := 0
	skip_next := 0
	if int(p_cur.eState) == 4 {
		return p_cur.skipNext
	}
	p_cur.eState = U8(1)
	if sqlite3_fault_sim(410) {
		rc = 10
	} else {
		rc = btree_moveto(p_cur, voidptr(p_cur.pKey), p_cur.nKey, 0, &skip_next)
	}
	if rc == 0 {
		sqlite3_free(voidptr(p_cur.pKey))
		p_cur.pKey = 0
		if skip_next {
			p_cur.skipNext = skip_next
		}
		if p_cur.skipNext && int(p_cur.eState) == 0 {
			p_cur.eState = U8(2)
		}
	}
	return rc
}

@[c:'sqlite3BtreeCursorHasMoved']
fn sqlite3_btree_cursor_has_moved(p_cur &BtCursor) int {
	return int(0 != int((unsafe { *&U8(voidptr(p_cur)) })))
}

@[c:'sqlite3BtreeFakeValidCursor']
fn sqlite3_btree_fake_valid_cursor() &BtCursor {
	if !sqlite3_btree_fake_valid_cursor_fake_cursor_inited {
		sqlite3_btree_fake_valid_cursor_fake_cursor = U8(0)
		sqlite3_btree_fake_valid_cursor_fake_cursor_inited = true
	}

	return &BtCursor(c2v_address_of(&sqlite3_btree_fake_valid_cursor_fake_cursor))
}

@[c:'sqlite3BtreeCursorRestore']
fn sqlite3_btree_cursor_restore(p_cur &BtCursor, p_different_row &int) int {
	rc := 0
	rc = (if int(p_cur.eState) >= 3 { btree_restore_cursor_position(p_cur) } else { 0 })
	if rc {
		unsafe { *p_different_row = 1 }
		return rc
	}
	if int(p_cur.eState) != 0 {
		unsafe { *p_different_row = 1 }
	} else {
		unsafe { *p_different_row = 0 }
	}
	return 0
}

@[c:'sqlite3BtreeCursorHintFlags']
fn sqlite3_btree_cursor_hint_flags(p_cur &BtCursor, x u32) {
	p_cur.hints = U8(x)
}

@[c:'ptrmapPageno']
fn ptrmap_pageno(p_bt &BtShared, pgno Pgno) Pgno {
	n_pages_per_map_page := 0
	i_ptr_map := Pgno(0)
	ret := Pgno(0)

	if pgno < Pgno(2) {
		return Pgno(0)
	}
	n_pages_per_map_page = int((p_bt.usableSize / u32(5)) + u32(1))
	i_ptr_map = (pgno - Pgno(2)) / Pgno(n_pages_per_map_page)
	ret = (i_ptr_map * Pgno(n_pages_per_map_page)) + Pgno(2)
	if ret == (Pgno(((u32(sqlite3PendingByte) / p_bt.pageSize) + u32(1)))) {
		ret++
	}
	return ret
}

@[c:'ptrmapPut']
fn ptrmap_put(p_bt &BtShared, key Pgno, e_type U8, parent Pgno, prc &int) {
	p_db_page := &DbPage(0)
	p_ptrmap := &U8(0)
	i_ptrmap := Pgno(0)
	offset := 0
	rc := 0
	if (unsafe { *prc }) {
		return
	}
	if key == Pgno(0) {
		unsafe { *prc = sqlite3_corrupt_error(1075) }
		return
	}
	i_ptrmap = ptrmap_pageno(p_bt, key)
	rc = sqlite3_pager_get(p_bt.pPager, i_ptrmap, &&DbPage(&&DbPage(c2v_address_of(&p_db_page))), 0)
	if rc != 0 {
		unsafe { *prc = rc }
		return
	}
	if int((&i8(sqlite3_pager_get_extra(p_db_page)))[0]) != 0 {
		unsafe { *prc = sqlite3_corrupt_error(1088) }
		unsafe { goto ptrmap_exit
		 }
	}
	offset = int((Pgno(5) * (key - i_ptrmap - Pgno(1))))
	if offset < 0 {
		unsafe { *prc = sqlite3_corrupt_error(1093) }
		unsafe { goto ptrmap_exit
		 }
	}
	p_ptrmap = &U8(sqlite3_pager_get_data(p_db_page))
	if int(e_type) != int(p_ptrmap[offset]) || sqlite3_get4byte(unsafe { p_ptrmap + (offset + 1) }) != parent {
		0
		rc = sqlite3_pager_write(p_db_page)
		unsafe { *prc = rc }
		if rc == 0 {
			p_ptrmap[offset] = e_type
			sqlite3_put4byte(unsafe { p_ptrmap + (offset + 1) }, parent)
		}
	}
	ptrmap_exit:
	sqlite3_pager_unref(p_db_page)
}

@[c:'ptrmapGet']
fn ptrmap_get(p_bt &BtShared, key Pgno, pet_ype &U8, p_pgno &Pgno) int {
	p_db_page := &DbPage(0)
	i_ptrmap := 0
	p_ptrmap := &U8(0)
	offset := 0
	rc := 0
	i_ptrmap = int(ptrmap_pageno(p_bt, key))
	rc = sqlite3_pager_get(p_bt.pPager, Pgno(i_ptrmap), &&DbPage(&&DbPage(c2v_address_of(&p_db_page))), 0)
	if rc != 0 {
		return rc
	}
	p_ptrmap = &U8(sqlite3_pager_get_data(p_db_page))
	offset = int((Pgno(5) * (key - Pgno(i_ptrmap) - Pgno(1))))
	if offset < 0 {
		sqlite3_pager_unref(p_db_page)
		return sqlite3_corrupt_error(1138)
	}
	unsafe { *pet_ype = p_ptrmap[offset] }
	if p_pgno {
		unsafe { *p_pgno = sqlite3_get4byte(p_ptrmap + (offset + 1)) }
	}
	sqlite3_pager_unref(p_db_page)
	if int((unsafe { *pet_ype })) < 1 || int((unsafe { *pet_ype })) > 5 {
		return sqlite3_corrupt_error(1146)
	}
	return 0
}

@[c:'btreeParseCellAdjustSizeForOverflow']
fn btree_parse_cell_adjust_size_for_overflow(p_page &MemPage, p_cell &U8, p_info &CellInfo) {
	min_local := 0
	max_local := 0
	surplus := 0
	min_local = int(p_page.minLocal)
	max_local = int(p_page.maxLocal)
	surplus = int(u32(min_local) + (p_info.nPayload - u32(min_local)) % (p_page.pBt.usableSize - u32(4)))
	0
	0
	if surplus <= max_local {
		p_info.nLocal = U16(surplus)
	} else {
		p_info.nLocal = U16(min_local)
	}
	p_info.nSize = U16(int(U16((i64((isize(unsafe { p_info.pPayload + p_info.nLocal }) - isize(p_cell)) / isize(sizeof(U8)))))) + 4)
}

@[c:'btreePayloadToLocal']
fn btree_payload_to_local(p_page &MemPage, n_payload I64) int {
	max_local := 0
	max_local = int(p_page.maxLocal)
	if n_payload <= I64(max_local) {
		return int(n_payload)
	} else {
		min_local := 0
		surplus := 0
		min_local = int(p_page.minLocal)
		surplus = int((I64(min_local) + (n_payload - I64(min_local)) % I64((p_page.pBt.usableSize - u32(4)))))
		return if (surplus <= max_local) { surplus } else { min_local }
	}
}

@[c:'btreeParseCellPtrNoPayload']
fn btree_parse_cell_ptr_no_payload(p_page &MemPage, p_cell &U8, p_info &CellInfo) {
	c2v_gc_register_thread()

	p_info.nSize = U16(4 + int(sqlite3_get_varint(unsafe { p_cell + 4 }, &U64(voidptr(&p_info.nKey)))))
	p_info.nPayload = u32(0)
	p_info.nLocal = U16(0)
	p_info.pPayload = 0
	return
}

@[c:'btreeParseCellPtr']
fn btree_parse_cell_ptr(p_page &MemPage, p_cell &U8, p_info &CellInfo) {
	c2v_gc_register_thread()
	p_iter := &U8(0)
	n_payload := U64(0)
	i_key := U64(0)
	p_iter = p_cell
	n_payload = unsafe { *p_iter }
	if n_payload >= U64(128) {
		p_end := unsafe { p_iter + 8 }
		n_payload &= U64(127)
		for {
			n_payload = (n_payload << 7) | U64((int((unsafe { *c2v_pointer_prefix(voidptr(&p_iter), p_iter, isize(1)) })) & 127))
			if !(int((unsafe { *p_iter })) >= 128 && usize(p_iter) < usize(p_end)) {
				break
			}
		}
		n_payload &= U64(u32(4294967295))
	}
	c2v_pointer_postfix(voidptr(&p_iter), p_iter, isize(1))
	i_key = unsafe { *p_iter }
	if i_key >= U64(128) {
		x := U8(0)
		i_key = (i_key << 7) ^ U64(c2v_assign[u8](unsafe { &x }, u8((unsafe { *c2v_pointer_prefix(voidptr(&p_iter), p_iter, isize(1)) }))))
		if int(x) >= 128 {
			i_key = (i_key << 7) ^ U64(c2v_assign[u8](unsafe { &x }, u8((unsafe { *c2v_pointer_prefix(voidptr(&p_iter), p_iter, isize(1)) }))))
			if int(x) >= 128 {
				i_key = (i_key << 7) ^ U64(270548992) ^ U64(c2v_assign[u8](unsafe { &x }, u8((unsafe { *c2v_pointer_prefix(voidptr(&p_iter), p_iter, isize(1)) }))))
				if int(x) >= 128 {
					i_key = (i_key << 7) ^ U64(16384) ^ U64(c2v_assign[u8](unsafe { &x }, u8((unsafe { *c2v_pointer_prefix(voidptr(&p_iter), p_iter, isize(1)) }))))
					if int(x) >= 128 {
						i_key = (i_key << 7) ^ U64(16384) ^ U64(c2v_assign[u8](unsafe { &x }, u8((unsafe { *c2v_pointer_prefix(voidptr(&p_iter), p_iter, isize(1)) }))))
						if int(x) >= 128 {
							i_key = (i_key << 7) ^ U64(16384) ^ U64(c2v_assign[u8](unsafe { &x }, u8((unsafe { *c2v_pointer_prefix(voidptr(&p_iter), p_iter, isize(1)) }))))
							if int(x) >= 128 {
								i_key = (i_key << 7) ^ U64(16384) ^ U64(c2v_assign[u8](unsafe { &x }, u8((unsafe { *c2v_pointer_prefix(voidptr(&p_iter), p_iter, isize(1)) }))))
								if int(x) >= 128 {
									i_key = (i_key << 8) ^ U64(32768) ^ U64((unsafe { *c2v_pointer_prefix(voidptr(&p_iter), p_iter, isize(1)) }))
								}
							}
						}
					}
				}
			} else {
				i_key ^= U64(2113536)
			}
		} else {
			i_key ^= U64(16384)
		}
	}
	c2v_pointer_postfix(voidptr(&p_iter), p_iter, isize(1))
	p_info.nKey = unsafe { *&I64(c2v_address_of(&i_key)) }
	p_info.nPayload = u32(n_payload)
	p_info.pPayload = p_iter
	0
	0
	if n_payload <= U64(p_page.maxLocal) {
		p_info.nSize = U16(int(U16(n_payload)) + int(U16((i64((isize(p_iter) - isize(p_cell)) / isize(sizeof(U8)))))))
		if int(p_info.nSize) < 4 {
			p_info.nSize = U16(4)
		}
		p_info.nLocal = U16(n_payload)
	} else {
		btree_parse_cell_adjust_size_for_overflow(p_page, p_cell, p_info)
	}
}

@[c:'btreeParseCellPtrIndex']
fn btree_parse_cell_ptr_index(p_page &MemPage, p_cell &U8, p_info &CellInfo) {
	c2v_gc_register_thread()
	p_iter := &U8(0)
	n_payload := u32(0)
	p_iter = p_cell + int(p_page.childPtrSize)
	n_payload = unsafe { *p_iter }
	if n_payload >= u32(128) {
		p_end := unsafe { p_iter + 8 }
		n_payload &= u32(127)
		for {
			n_payload = (n_payload << 7) | u32((int((unsafe { *c2v_pointer_prefix(voidptr(&p_iter), p_iter, isize(1)) })) & 127))
			if !(int((unsafe { *p_iter })) >= 128 && usize(p_iter) < usize(p_end)) {
				break
			}
		}
	}
	c2v_pointer_postfix(voidptr(&p_iter), p_iter, isize(1))
	p_info.nKey = I64(n_payload)
	p_info.nPayload = n_payload
	p_info.pPayload = p_iter
	0
	0
	if n_payload <= u32(p_page.maxLocal) {
		p_info.nSize = U16(int(U16(n_payload)) + int(U16((i64((isize(p_iter) - isize(p_cell)) / isize(sizeof(U8)))))))
		if int(p_info.nSize) < 4 {
			p_info.nSize = U16(4)
		}
		p_info.nLocal = U16(n_payload)
	} else {
		btree_parse_cell_adjust_size_for_overflow(p_page, p_cell, p_info)
	}
}

@[c:'btreeParseCell']
fn btree_parse_cell(p_page &MemPage, i_cell int, p_info &CellInfo) {
	p_page.xParseCell(p_page, (p_page.aData + (int(p_page.maskPage) & (int((unsafe { p_page.aCellIdx + (2 * i_cell) })[0]) << 8 | int((unsafe { p_page.aCellIdx + (2 * i_cell) })[1])))), p_info)
}

@[c:'cellSizePtr']
fn cell_size_ptr(p_page &MemPage, p_cell &U8) U16 {
	c2v_gc_register_thread()
	p_iter := p_cell + 4
	p_end := &U8(0)
	n_size := u32(0)
	n_size = unsafe { *p_iter }
	if n_size >= u32(128) {
		p_end = unsafe { p_iter + 8 }
		n_size &= u32(127)
		for {
			n_size = (n_size << 7) | u32((int((unsafe { *c2v_pointer_prefix(voidptr(&p_iter), p_iter, isize(1)) })) & 127))
			if !(int((unsafe { *p_iter })) >= 128 && usize(p_iter) < usize(p_end)) {
				break
			}
		}
	}
	c2v_pointer_postfix(voidptr(&p_iter), p_iter, isize(1))
	0
	0
	if n_size <= u32(p_page.maxLocal) {
		n_size += u32((i64((isize(p_iter) - isize(p_cell)) / isize(sizeof(U8)))))
	} else {
		min_local := int(p_page.minLocal)
		n_size = u32(min_local) + (n_size - u32(min_local)) % (p_page.pBt.usableSize - u32(4))
		0
		0
		if n_size > u32(p_page.maxLocal) {
			n_size = u32(min_local)
		}
		n_size += u32(4 + int(U16((i64((isize(p_iter) - isize(p_cell)) / isize(sizeof(U8)))))))
	}
	return U16(n_size)
}

@[c:'cellSizePtrIdxLeaf']
fn cell_size_ptr_idx_leaf(p_page &MemPage, p_cell &U8) U16 {
	c2v_gc_register_thread()
	p_iter := p_cell
	p_end := &U8(0)
	n_size := u32(0)
	n_size = unsafe { *p_iter }
	if n_size >= u32(128) {
		p_end = unsafe { p_iter + 8 }
		n_size &= u32(127)
		for {
			n_size = (n_size << 7) | u32((int((unsafe { *c2v_pointer_prefix(voidptr(&p_iter), p_iter, isize(1)) })) & 127))
			if !(int((unsafe { *p_iter })) >= 128 && usize(p_iter) < usize(p_end)) {
				break
			}
		}
	}
	c2v_pointer_postfix(voidptr(&p_iter), p_iter, isize(1))
	0
	0
	if n_size <= u32(p_page.maxLocal) {
		n_size += u32((i64((isize(p_iter) - isize(p_cell)) / isize(sizeof(U8)))))
		if n_size < u32(4) {
			n_size = u32(4)
		}
	} else {
		min_local := int(p_page.minLocal)
		n_size = u32(min_local) + (n_size - u32(min_local)) % (p_page.pBt.usableSize - u32(4))
		0
		0
		if n_size > u32(p_page.maxLocal) {
			n_size = u32(min_local)
		}
		n_size += u32(4 + int(U16((i64((isize(p_iter) - isize(p_cell)) / isize(sizeof(U8)))))))
	}
	return U16(n_size)
}

@[c:'cellSizePtrNoPayload']
fn cell_size_ptr_no_payload(p_page &MemPage, p_cell &U8) U16 {
	c2v_gc_register_thread()
	p_iter := p_cell + 4
	p_end := &U8(0)

	p_end = p_iter + 9
	for int((unsafe { *c2v_pointer_postfix(voidptr(&p_iter), p_iter, isize(1)) })) & 128 && usize(p_iter) < usize(p_end) {
		0
	}
	return U16((i64((isize(p_iter) - isize(p_cell)) / isize(sizeof(U8)))))
}

@[c:'cellSizePtrTableLeaf']
fn cell_size_ptr_table_leaf(p_page &MemPage, p_cell &U8) U16 {
	c2v_gc_register_thread()
	p_iter := p_cell
	p_end := &U8(0)
	n_size := u32(0)
	n_size = unsafe { *p_iter }
	if n_size >= u32(128) {
		p_end = unsafe { p_iter + 8 }
		n_size &= u32(127)
		for {
			n_size = (n_size << 7) | u32((int((unsafe { *c2v_pointer_prefix(voidptr(&p_iter), p_iter, isize(1)) })) & 127))
			if !(int((unsafe { *p_iter })) >= 128 && usize(p_iter) < usize(p_end)) {
				break
			}
		}
	}
	c2v_pointer_postfix(voidptr(&p_iter), p_iter, isize(1))
	mut __c2v_condition_32 := false
	mut __c2v_condition_33 := false
	__c2v_condition_33 = int((unsafe { *c2v_pointer_postfix(voidptr(&p_iter), p_iter, isize(1)) })) & 128
	if __c2v_condition_33 {
		__c2v_condition_33 = int((unsafe { *c2v_pointer_postfix(voidptr(&p_iter), p_iter, isize(1)) })) & 128
	}
	if __c2v_condition_33 {
		__c2v_condition_33 = int((unsafe { *c2v_pointer_postfix(voidptr(&p_iter), p_iter, isize(1)) })) & 128
	}
	if __c2v_condition_33 {
		__c2v_condition_33 = int((unsafe { *c2v_pointer_postfix(voidptr(&p_iter), p_iter, isize(1)) })) & 128
	}
	if __c2v_condition_33 {
		__c2v_condition_33 = int((unsafe { *c2v_pointer_postfix(voidptr(&p_iter), p_iter, isize(1)) })) & 128
	}
	if __c2v_condition_33 {
		__c2v_condition_33 = int((unsafe { *c2v_pointer_postfix(voidptr(&p_iter), p_iter, isize(1)) })) & 128
	}
	if __c2v_condition_33 {
		__c2v_condition_33 = int((unsafe { *c2v_pointer_postfix(voidptr(&p_iter), p_iter, isize(1)) })) & 128
	}
	if __c2v_condition_33 {
		__c2v_condition_33 = int((unsafe { *c2v_pointer_postfix(voidptr(&p_iter), p_iter, isize(1)) })) & 128
	}
	__c2v_condition_32 = __c2v_condition_33
	if __c2v_condition_32 {
		c2v_pointer_postfix(voidptr(&p_iter), p_iter, isize(1))
	}
	0
	0
	if n_size <= u32(p_page.maxLocal) {
		n_size += u32((i64((isize(p_iter) - isize(p_cell)) / isize(sizeof(U8)))))
		if n_size < u32(4) {
			n_size = u32(4)
		}
	} else {
		min_local := int(p_page.minLocal)
		n_size = u32(min_local) + (n_size - u32(min_local)) % (p_page.pBt.usableSize - u32(4))
		0
		0
		if n_size > u32(p_page.maxLocal) {
			n_size = u32(min_local)
		}
		n_size += u32(4 + int(U16((i64((isize(p_iter) - isize(p_cell)) / isize(sizeof(U8)))))))
	}
	return U16(n_size)
}

@[c:'ptrmapPutOvflPtr']
fn ptrmap_put_ovfl_ptr(p_page &MemPage, p_src &MemPage, p_cell &U8, prc &int) {
	info := CellInfo{}
	if (unsafe { *prc }) {
		return
	}
	p_page.xParseCell(p_page, p_cell, &info)
	if u32(info.nLocal) < info.nPayload {
		ovfl := Pgno(0)
		if ((Uptr(voidptr(p_cell)) < Uptr(voidptr(p_src.aDataEnd))) && (Uptr(voidptr((p_cell + int(info.nLocal)))) > Uptr(voidptr(p_src.aDataEnd)))) {
			0
			unsafe { *prc = sqlite3_corrupt_error(1591) }
			return
		}
		ovfl = sqlite3_get4byte(unsafe { p_cell + (int(info.nSize) - 4) })
		ptrmap_put(p_page.pBt, ovfl, U8(3), p_page.pgno, prc)
	}
}

@[c:'defragmentPage']
fn defragment_page(p_page &MemPage, n_max_frag int) int {
	i := 0
	pc := 0
	hdr := 0
	size := 0
	usable_size := 0
	cell_offset := 0
	cbrk := 0
	n_cell := 0
	data := &u8(0)
	temp := &u8(0)
	src := &u8(0)
	i_cell_first := 0
	i_cell_last := 0
	i_cell_start := 0
	data = p_page.aData
	hdr = int(p_page.hdrOffset)
	cell_offset = int(p_page.cellOffset)
	n_cell = int(p_page.nCell)
	i_cell_first = cell_offset + 2 * n_cell
	usable_size = int(p_page.pBt.usableSize)
	if int(data[hdr + 7]) <= n_max_frag {
		i_free := (int((unsafe { data + (hdr + 1) })[0]) << 8 | int((unsafe { data + (hdr + 1) })[1]))
		if i_free > usable_size - 4 {
			return sqlite3_corrupt_error(1649)
		}
		if i_free {
			i_free2 := (int((unsafe { data + i_free })[0]) << 8 | int((unsafe { data + i_free })[1]))
			if i_free2 > usable_size - 4 {
				return sqlite3_corrupt_error(1652)
			}
			if 0 == i_free2 || (int(data[i_free2]) == 0 && int(data[i_free2 + 1]) == 0) {
				p_end := unsafe { data + (cell_offset + n_cell * 2) }
				p_addr := &U8(0)
				sz2 := 0
				sz := (int((unsafe { data + (i_free + 2) })[0]) << 8 | int((unsafe { data + (i_free + 2) })[1]))
				top := (int((unsafe { data + (hdr + 5) })[0]) << 8 | int((unsafe { data + (hdr + 5) })[1]))
				if top >= i_free {
					return sqlite3_corrupt_error(1660)
				}
				if i_free2 {
					if i_free + sz > i_free2 {
						return sqlite3_corrupt_error(1663)
					}
					sz2 = (int((unsafe { data + (i_free2 + 2) })[0]) << 8 | int((unsafe { data + (i_free2 + 2) })[1]))
					if i_free2 + sz2 > usable_size {
						return sqlite3_corrupt_error(1665)
					}
					C.memmove(voidptr(unsafe { data + (i_free + sz + sz2) }), voidptr(unsafe { data + (i_free + sz) }), u64(i_free2 - (i_free + sz)))
					sz += sz2
				} else if i_free + sz > usable_size {
					return sqlite3_corrupt_error(1669)
				}
				cbrk = top + sz
				C.memmove(voidptr(unsafe { data + cbrk }), voidptr(unsafe { data + top }), u64(i_free - top))
				for p_addr = unsafe { data + cell_offset }; usize(p_addr) < usize(p_end); p_addr = unsafe { p_addr + 2 } {
					pc = (int(p_addr[0]) << 8 | int(p_addr[1]))
					if pc < i_free {
						p_addr[0] = U8(((pc + sz) >> 8))
						p_addr[1] = U8((pc + sz))
					} else if pc < i_free2 {
						p_addr[0] = U8(((pc + sz2) >> 8))
						p_addr[1] = U8((pc + sz2))
					}
				}
				unsafe { goto defragment_out
				 }
			}
		}
	}
	cbrk = usable_size
	i_cell_last = usable_size - 4
	i_cell_start = (int((unsafe { data + (hdr + 5) })[0]) << 8 | int((unsafe { data + (hdr + 5) })[1]))
	if n_cell > 0 {
		temp = &u8(sqlite3_pager_temp_space(p_page.pBt.pPager))
		C.memcpy(voidptr(temp), voidptr(data), u64(usable_size))
		src = temp
		for i = 0; i < n_cell; i++ {
			p_addr := &U8(0)
			p_addr = unsafe { data + (cell_offset + i * 2) }
			pc = (int(p_addr[0]) << 8 | int(p_addr[1]))
			0
			0
			if pc > i_cell_last {
				return sqlite3_corrupt_error(1702)
			}
			size = int(p_page.xCellSize(p_page, unsafe { &U8(src + pc) }))
			cbrk -= size
			if cbrk < i_cell_start || pc + size > usable_size {
				return sqlite3_corrupt_error(1708)
			}
			0
			0
			p_addr[0] = U8((cbrk >> 8))
			p_addr[1] = U8(cbrk)
			C.memcpy(voidptr(unsafe { data + cbrk }), voidptr(unsafe { src + pc }), u64(size))
		}
	}
	data[hdr + 7] = u8(0)
	defragment_out:
	if int(data[hdr + 7]) + cbrk - i_cell_first != p_page.nFree {
		return sqlite3_corrupt_error(1722)
	}
	(unsafe { data + (hdr + 5) })[0] = U8((cbrk >> 8))
	(unsafe { data + (hdr + 5) })[1] = U8(cbrk)
	data[hdr + 1] = u8(0)
	data[hdr + 2] = u8(0)
	C.memset(voidptr(unsafe { data + i_cell_first }), 0, u64(cbrk - i_cell_first))
	return 0
}

@[c:'pageFindSlot']
fn page_find_slot(p_pg &MemPage, n_byte int, p_rc &int) &U8 {
	hdr := int(p_pg.hdrOffset)
	a_data := p_pg.aData
	i_addr := hdr + 1
	p_tmp := unsafe { a_data + i_addr }
	pc := (int(p_tmp[0]) << 8 | int(p_tmp[1]))
	x := 0
	max_pc := int(p_pg.pBt.usableSize - u32(n_byte))
	size := 0
	for pc <= max_pc {
		p_tmp = unsafe { a_data + (pc + 2) }
		size = (int(p_tmp[0]) << 8 | int(p_tmp[1]))
		x = size - n_byte
		if x >= 0 {
			0
			0
			if x < 4 {
				if int(a_data[hdr + 7]) > 57 {
					return unsafe { nil }
				}
				C.memcpy(voidptr(unsafe { a_data + i_addr }), voidptr(unsafe { a_data + pc }), u64(2))
				a_data[hdr + 7] += int(U8(x))
				return unsafe { a_data + pc }
			} else if x + pc > max_pc {
				unsafe { *p_rc = sqlite3_corrupt_error(1779) }
				return unsafe { nil }
			} else {
				(unsafe { a_data + (pc + 2) })[0] = U8((x >> 8))
				(unsafe { a_data + (pc + 2) })[1] = U8(x)
			}
			return unsafe { a_data + (pc + x) }
		}
		i_addr = pc
		p_tmp = unsafe { a_data + pc }
		pc = (int(p_tmp[0]) << 8 | int(p_tmp[1]))
		if pc <= i_addr {
			if pc {
				unsafe { *p_rc = sqlite3_corrupt_error(1794) }
			}
			return unsafe { nil }
		}
	}
	if pc > max_pc + n_byte - 4 {
		unsafe { *p_rc = sqlite3_corrupt_error(1801) }
	}
	return unsafe { nil }
}

@[c:'allocateSpace']
fn allocate_space(p_page &MemPage, n_byte int, p_idx &int) int {
	hdr := int(p_page.hdrOffset)
	data := p_page.aData
	top := 0
	rc := 0
	p_tmp := &U8(0)
	gap := 0
	gap = int(p_page.cellOffset) + 2 * int(p_page.nCell)
	p_tmp = unsafe { data + (hdr + 5) }
	top = (int(p_tmp[0]) << 8 | int(p_tmp[1]))
	if gap > top {
		if top == 0 && p_page.pBt.usableSize == u32(65536) {
			top = 65536
		} else {
			return sqlite3_corrupt_error(1849)
		}
	} else if top > int(p_page.pBt.usableSize) {
		return sqlite3_corrupt_error(1852)
	}
	0
	0
	0
	if (int(data[hdr + 2]) || int(data[hdr + 1])) && gap + 2 <= top {
		p_space := page_find_slot(p_page, n_byte, &rc)
		if p_space {
			g2 := 0
			g2 = int((i64((isize(p_space) - isize(data)) / isize(sizeof(U8)))))
			unsafe { *p_idx = g2 }
			if g2 <= gap {
				return sqlite3_corrupt_error(1869)
			} else {
				return 0
			}
		} else if rc {
			return rc
		}
	}
	0
	if gap + 2 + n_byte > top {
		rc = defragment_page(p_page, (if 4 < (p_page.nFree - (2 + n_byte)) {
			4
		} else {
			(p_page.nFree - (2 + n_byte))
		}))
		if rc {
			return rc
		}
		top = ((((int((int((unsafe { data + (hdr + 5) })[0]) << 8 | int((unsafe { data + (hdr + 5) })[1])))) - 1) & 65535) + 1)
	}
	top -= n_byte
	(unsafe { data + (hdr + 5) })[0] = U8((top >> 8))
	(unsafe { data + (hdr + 5) })[1] = U8(top)
	unsafe { *p_idx = top }
	return 0
}

@[c:'freeSpace']
fn free_space(p_page &MemPage, i_start int, i_size int) int {
	i_ptr := 0
	i_free_blk := 0
	hdr := U8(0)
	n_frag := 0
	i_orig_size := i_size
	x := 0
	i_end := i_start + i_size
	data := p_page.aData
	p_tmp := &U8(0)
	hdr = p_page.hdrOffset
	i_ptr = int(hdr) + 1
	if int(data[i_ptr + 1]) == 0 && int(data[i_ptr]) == 0 {
		i_free_blk = 0
	} else {
		for {
			i_free_blk = (int((unsafe { data + i_ptr })[0]) << 8 | int((unsafe { data + i_ptr })[1]))
			if !(i_free_blk < i_start) {
				break
			}
			if i_free_blk <= i_ptr {
				if i_free_blk == 0 {
					break
				}
				return sqlite3_corrupt_error(1948)
			}
			i_ptr = i_free_blk
		}
		if i_free_blk > int(p_page.pBt.usableSize) - 4 {
			return sqlite3_corrupt_error(1953)
		}
		if i_free_blk && i_end + 3 >= i_free_blk {
			n_frag = i_free_blk - i_end
			if i_end > i_free_blk {
				return sqlite3_corrupt_error(1965)
			}
			i_end = i_free_blk + (int((unsafe { data + (i_free_blk + 2) })[0]) << 8 | int((unsafe { data + (i_free_blk + 2) })[1]))
			if i_end > int(p_page.pBt.usableSize) {
				return sqlite3_corrupt_error(1968)
			}
			i_size = i_end - i_start
			i_free_blk = (int((unsafe { data + i_free_blk })[0]) << 8 | int((unsafe { data + i_free_blk })[1]))
		}
		if i_ptr > int(hdr) + 1 {
			i_ptr_end := i_ptr + (int((unsafe { data + (i_ptr + 2) })[0]) << 8 | int((unsafe { data + (i_ptr + 2) })[1]))
			if i_ptr_end + 3 >= i_start {
				if i_ptr_end > i_start {
					return sqlite3_corrupt_error(1981)
				}
				n_frag += i_start - i_ptr_end
				i_size = i_end - i_ptr
				i_start = i_ptr
			}
		}
		if n_frag > int(data[int(hdr) + 7]) {
			return sqlite3_corrupt_error(1987)
		}
		data[int(hdr) + 7] -= int(U8(n_frag))
	}
	p_tmp = unsafe { data + (int(hdr) + 5) }
	x = (int(p_tmp[0]) << 8 | int(p_tmp[1]))
	if int(p_page.pBt.btsFlags) & 12 {
		C.memset(voidptr(unsafe { data + i_start }), 0, u64(i_size))
	}
	if i_start <= x {
		if i_start < x {
			return sqlite3_corrupt_error(2001)
		}
		if i_ptr != int(hdr) + 1 {
			return sqlite3_corrupt_error(2002)
		}
		(unsafe { data + (int(hdr) + 1) })[0] = U8((i_free_blk >> 8))
		(unsafe { data + (int(hdr) + 1) })[1] = U8(i_free_blk)
		(unsafe { data + (int(hdr) + 5) })[0] = U8((i_end >> 8))
		(unsafe { data + (int(hdr) + 5) })[1] = U8(i_end)
	} else {
		(unsafe { data + i_ptr })[0] = U8((i_start >> 8))
		(unsafe { data + i_ptr })[1] = U8(i_start)
		(unsafe { data + i_start })[0] = U8((i_free_blk >> 8))
		(unsafe { data + i_start })[1] = U8(i_free_blk)
		(unsafe { data + (i_start + 2) })[0] = U8((int((U16(i_size))) >> 8))
		(unsafe { data + (i_start + 2) })[1] = U8((U16(i_size)))
	}
	p_page.nFree += i_orig_size
	return 0
}

@[c:'decodeFlags']
fn decode_flags(p_page &MemPage, flag_byte int) int {
	p_bt := &BtShared(0)
	p_bt = p_page.pBt
	p_page.max1bytePayload = p_bt.max1bytePayload
	if flag_byte >= (2 | 8) {
		p_page.childPtrSize = U8(0)
		p_page.leaf = U8(1)
		if flag_byte == (4 | 1 | 8) {
			p_page.intKeyLeaf = U8(1)
			p_page.xCellSize = cell_size_ptr_table_leaf
			p_page.xParseCell = btree_parse_cell_ptr
			p_page.intKey = U8(1)
			p_page.maxLocal = p_bt.maxLeaf
			p_page.minLocal = p_bt.minLeaf
		} else if flag_byte == (2 | 8) {
			p_page.intKey = U8(0)
			p_page.intKeyLeaf = U8(0)
			p_page.xCellSize = cell_size_ptr_idx_leaf
			p_page.xParseCell = btree_parse_cell_ptr_index
			p_page.maxLocal = p_bt.maxLocal
			p_page.minLocal = p_bt.minLocal
		} else {
			p_page.intKey = U8(0)
			p_page.intKeyLeaf = U8(0)
			p_page.xCellSize = cell_size_ptr_idx_leaf
			p_page.xParseCell = btree_parse_cell_ptr_index
			return sqlite3_corrupt_error(2057)
		}
	} else {
		p_page.childPtrSize = U8(4)
		p_page.leaf = U8(0)
		if flag_byte == 2 {
			p_page.intKey = U8(0)
			p_page.intKeyLeaf = U8(0)
			p_page.xCellSize = cell_size_ptr
			p_page.xParseCell = btree_parse_cell_ptr_index
			p_page.maxLocal = p_bt.maxLocal
			p_page.minLocal = p_bt.minLocal
		} else if flag_byte == (4 | 1) {
			p_page.intKeyLeaf = U8(0)
			p_page.xCellSize = cell_size_ptr_no_payload
			p_page.xParseCell = btree_parse_cell_ptr_no_payload
			p_page.intKey = U8(1)
			p_page.maxLocal = p_bt.maxLeaf
			p_page.minLocal = p_bt.minLeaf
		} else {
			p_page.intKey = U8(0)
			p_page.intKeyLeaf = U8(0)
			p_page.xCellSize = cell_size_ptr
			p_page.xParseCell = btree_parse_cell_ptr_index
			return sqlite3_corrupt_error(2081)
		}
	}
	return 0
}

@[c:'btreeComputeFreeSpace']
fn btree_compute_free_space(p_page &MemPage) int {
	pc := 0
	hdr := U8(0)
	data := &U8(0)
	usable_size := 0
	n_free := 0
	top := 0
	i_cell_first := 0
	i_cell_last := 0
	usable_size = int(p_page.pBt.usableSize)
	hdr = p_page.hdrOffset
	data = p_page.aData
	top = ((((int((int((unsafe { data + (int(hdr) + 5) })[0]) << 8 | int((unsafe { data + (int(hdr) + 5) })[1])))) - 1) & 65535) + 1)
	i_cell_first = int(hdr) + 8 + int(p_page.childPtrSize) + 2 * int(p_page.nCell)
	i_cell_last = usable_size - 4
	pc = (int((unsafe { data + (int(hdr) + 1) })[0]) << 8 | int((unsafe { data + (int(hdr) + 1) })[1]))
	n_free = int(data[int(hdr) + 7]) + top
	if pc > 0 {
		next := u32(0)
		size := u32(0)

		if pc < top {
			return sqlite3_corrupt_error(2132)
		}
		for {
			if pc > i_cell_last {
				return sqlite3_corrupt_error(2137)
			}
			next = u32((int((unsafe { data + pc })[0]) << 8 | int((unsafe { data + pc })[1])))
			size = u32((int((unsafe { data + (pc + 2) })[0]) << 8 | int((unsafe { data + (pc + 2) })[1])))
			if size < u32(4) {
				return sqlite3_corrupt_error(2143)
			}
			n_free = int(u32(n_free) + size)
			if next < u32(pc) + size + u32(4) {
				break
			}
			pc = int(next)
		}
		if next > u32(0) {
			return sqlite3_corrupt_error(2151)
		}
		if u32(pc) + size > u32(usable_size) {
			return sqlite3_corrupt_error(2155)
		}
	}
	if n_free > usable_size || n_free < i_cell_first {
		return sqlite3_corrupt_error(2167)
	}
	p_page.nFree = int(U16((n_free - i_cell_first)))
	return 0
}

@[c:'btreeCellSizeCheck']
fn btree_cell_size_check(p_page &MemPage) int {
	i_cell_first := 0
	i_cell_last := 0
	i := 0
	sz := 0
	pc := 0
	data := &U8(0)
	usable_size := 0
	cell_offset := 0
	i_cell_first = int(p_page.cellOffset) + 2 * int(p_page.nCell)
	usable_size = int(p_page.pBt.usableSize)
	i_cell_last = usable_size - 4
	data = p_page.aData
	cell_offset = int(p_page.cellOffset)
	if !p_page.leaf {
		i_cell_last--
	}
	for i = 0; i < int(p_page.nCell); i++ {
		pc = (int((unsafe { data + (cell_offset + i * 2) })[0]) << 8 | int((unsafe { data + (cell_offset + i * 2) })[1]))
		0
		0
		if pc < i_cell_first || pc > i_cell_last {
			return sqlite3_corrupt_error(2198)
		}
		sz = int(p_page.xCellSize(p_page, unsafe { data + pc }))
		0
		if pc + sz > usable_size {
			return sqlite3_corrupt_error(2203)
		}
	}
	return 0
}

@[c:'btreeInitPage']
fn btree_init_page(p_page &MemPage) int {
	data := &U8(0)
	p_bt := &BtShared(0)
	p_bt = p_page.pBt
	data = p_page.aData + int(p_page.hdrOffset)
	if decode_flags(p_page, int(data[0])) {
		return sqlite3_corrupt_error(2235)
	}
	p_page.maskPage = U16((p_bt.pageSize - u32(1)))
	p_page.nOverflow = U8(0)
	p_page.cellOffset = U16((int(p_page.hdrOffset) + 8 + int(p_page.childPtrSize)))
	p_page.aCellIdx = data + int(p_page.childPtrSize) + 8
	p_page.aDataEnd = p_page.aData + p_bt.pageSize
	p_page.aDataOfst = p_page.aData + int(p_page.childPtrSize)
	p_page.nCell = U16((int((unsafe { data + 3 })[0]) << 8 | int((unsafe { data + 3 })[1])))
	if u32(p_page.nCell) > ((p_bt.pageSize - u32(8)) / u32(6)) {
		return sqlite3_corrupt_error(2249)
	}
	0
	p_page.nFree = -1
	p_page.isInit = U8(1)
	if p_bt.db.flags & U64(2097152) {
		return btree_cell_size_check(p_page)
	}
	return 0
}

@[c:'zeroPage']
fn zero_page(p_page &MemPage, flags int) {
	data := p_page.aData
	p_bt := p_page.pBt
	hdr := int(p_page.hdrOffset)
	first := 0
	if int(p_bt.btsFlags) & 12 {
		C.memset(voidptr(unsafe { data + hdr }), 0, u64(p_bt.usableSize - u32(hdr)))
	}
	data[hdr] = u8(i8(flags))
	first = hdr + (if (flags & 8) == 0 { 12 } else { 8 })
	C.memset(voidptr(unsafe { data + (hdr + 1) }), 0, u64(4))
	data[hdr + 7] = u8(0)
	(unsafe { data + (hdr + 5) })[0] = U8((p_bt.usableSize >> 8))
	(unsafe { data + (hdr + 5) })[1] = U8(p_bt.usableSize)
	p_page.nFree = int(U16((p_bt.usableSize - u32(first))))
	decode_flags(p_page, flags)
	p_page.cellOffset = U16(first)
	p_page.aDataEnd = unsafe { data + p_bt.pageSize }
	p_page.aCellIdx = unsafe { data + first }
	p_page.aDataOfst = unsafe { data + p_page.childPtrSize }
	p_page.nOverflow = U8(0)
	p_page.maskPage = U16((p_bt.pageSize - u32(1)))
	p_page.nCell = U16(0)
	p_page.isInit = U8(1)
}

@[c:'btreePageFromDbPage']
fn btree_page_from_db_page(p_db_page &DbPage, pgno Pgno, p_bt &BtShared) &MemPage {
	p_page := &MemPage(sqlite3_pager_get_extra(p_db_page))
	if pgno != p_page.pgno {
		p_page.aData = sqlite3_pager_get_data(p_db_page)
		p_page.pDbPage = p_db_page
		p_page.pBt = p_bt
		p_page.pgno = pgno
		p_page.hdrOffset = U8(if pgno == Pgno(1) { 100 } else { 0 })
	}
	return p_page
}

@[c:'btreeGetPage']
fn btree_get_page(p_bt &BtShared, pgno Pgno, pp_page &&MemPage, flags int) int {
	rc := 0
	p_db_page := &DbPage(0)
	rc = sqlite3_pager_get(p_bt.pPager, pgno, &&DbPage(c2v_address_of(&p_db_page)), flags)
	if rc {
		return rc
	}
	unsafe { *pp_page = btree_page_from_db_page(p_db_page, pgno, p_bt) }
	return 0
}

@[c:'btreePageLookup']
fn btree_page_lookup(p_bt &BtShared, pgno Pgno) &MemPage {
	p_db_page := &DbPage(0)
	p_db_page = sqlite3_pager_lookup(p_bt.pPager, pgno)
	if p_db_page {
		return btree_page_from_db_page(p_db_page, pgno, p_bt)
	}
	return unsafe { nil }
}

@[c:'btreePagecount']
fn btree_pagecount(p_bt &BtShared) Pgno {
	return p_bt.nPage
}

@[c:'sqlite3BtreeLastPage']
fn sqlite3_btree_last_page(p &Btree) Pgno {
	return btree_pagecount(p.pBt)
}

@[c:'getAndInitPage']
fn get_and_init_page(p_bt &BtShared, pgno Pgno, pp_page &&MemPage, b_read_only int) int {
	rc := 0
	p_db_page := &DbPage(0)
	p_page := &MemPage(0)
	if pgno > btree_pagecount(p_bt) {
		unsafe { *pp_page = 0 }
		return sqlite3_corrupt_error(2392)
	}
	rc = sqlite3_pager_get(p_bt.pPager, pgno, &&DbPage(c2v_address_of(&p_db_page)), b_read_only)
	if rc {
		unsafe { *pp_page = 0 }
		return rc
	}
	p_page = &MemPage(sqlite3_pager_get_extra(p_db_page))
	if int(p_page.isInit) == 0 {
		btree_page_from_db_page(p_db_page, pgno, p_bt)
		rc = btree_init_page(p_page)
		if rc != 0 {
			release_page(p_page)
			unsafe { *pp_page = 0 }
			return rc
		}
	}
	unsafe { *pp_page = p_page }
	return 0
}

@[c:'releasePageNotNull']
fn release_page_not_null(p_page &MemPage) {
	sqlite3_pager_unref_not_null(p_page.pDbPage)
}

@[c:'releasePage']
fn release_page(p_page &MemPage) {
	if p_page {
		release_page_not_null(p_page)
	}
}

@[c:'releasePageOne']
fn release_page_one(p_page &MemPage) {
	sqlite3_pager_unref_page_one(p_page.pDbPage)
}

@[c:'btreeGetUnusedPage']
fn btree_get_unused_page(p_bt &BtShared, pgno Pgno, pp_page &&MemPage, flags int) int {
	rc := btree_get_page(p_bt, pgno, pp_page, flags)
	if rc == 0 {
		if sqlite3_pager_page_refcount((unsafe { *pp_page }).pDbPage) > 1 {
			release_page((unsafe { *pp_page }))
			unsafe { *pp_page = 0 }
			return sqlite3_corrupt_error(2464)
		}
		unsafe { (*pp_page).isInit = U8(0) }
	} else {
		unsafe { *pp_page = 0 }
	}
	return rc
}

@[c:'pageReinit']
fn page_reinit(p_data &DbPage) {
	c2v_gc_register_thread()
	p_page := &MemPage(0)
	p_page = &MemPage(sqlite3_pager_get_extra(p_data))
	if p_page.isInit {
		p_page.isInit = U8(0)
		if sqlite3_pager_page_refcount(p_data) > 1 {
			btree_init_page(p_page)
		}
	}
}

@[c:'btreeInvokeBusyHandler']
fn btree_invoke_busy_handler(p_arg voidptr) int {
	c2v_gc_register_thread()
	p_bt := &BtShared(p_arg)
	return sqlite3_invoke_busy_handler(&p_bt.db.busyHandler)
}

@[c:'sqlite3BtreeOpen']
fn sqlite3_btree_open(p_vfs &Sqlite3_vfs, z_filename &i8, db &Sqlite3, pp_btree &&Btree, flags int, vfs_flags int) int {
	p_bt := unsafe { &BtShared(nil) }
	p := &Btree(0)
	mutex_open := unsafe { &Sqlite3_mutex(nil) }
	rc := 0
	n_reserve := U8(0)
	z_db_header := [100]u8{}
	is_temp_db := int(usize(z_filename) == usize(0) || int(z_filename[0]) == 0)
	is_memdb := int((!isnil(z_filename) && C.strcmp(z_filename, c':memory:') == 0) || (is_temp_db && sqlite3_temp_in_memory(db)) || (vfs_flags & 128) != 0)
	if is_memdb {
		flags |= 2
	}
	if (vfs_flags & 256) != 0 && (is_memdb || is_temp_db) {
		vfs_flags = (vfs_flags & ~256) | 512
	}
	p = sqlite3_malloc_zero(U64(sizeof(Btree)))
	if isnil(p) {
		return 7
	}
	p.inTrans = U8(0)
	p.db = db
	p.lock_.pBtree = p
	p.lock_.iTable = Pgno(1)
	if is_temp_db == 0 && (is_memdb == 0 || (vfs_flags & 64) != 0) {
		if vfs_flags & 131072 {
			n_filename := sqlite3_strlen30(z_filename) + 1
			n_full_pathname := p_vfs.mxPathname + 1
			z_full_pathname := &i8(sqlite3_malloc_vdup2(U64((if n_full_pathname > n_filename {
				n_full_pathname
			} else {
				n_filename
			}))))
			mutex_shared := &Sqlite3_mutex(0)
			p.sharable = U8(1)
			if isnil(z_full_pathname) {
				sqlite3_free(voidptr(p))
				return 7
			}
			if is_memdb {
				C.memcpy(voidptr(z_full_pathname), voidptr(z_filename), u64(n_filename))
			} else {
				rc = sqlite3_os_full_pathname(p_vfs, z_filename, n_full_pathname, z_full_pathname)
				if rc {
					if rc == (0 | (2 << 8)) {
						rc = 0
					} else {
						sqlite3_free(voidptr(z_full_pathname))
						sqlite3_free(voidptr(p))
						return rc
					}
				}
			}
			mutex_open = sqlite3_mutex_alloc_vdup4(4)
			sqlite3_mutex_enter(mutex_open)
			mutex_shared = sqlite3_mutex_alloc_vdup4(2)
			sqlite3_mutex_enter(mutex_shared)
			for p_bt = sqlite3SharedCacheList; p_bt; p_bt = p_bt.pNext {
				if 0 == C.strcmp(z_full_pathname, sqlite3_pager_filename(p_bt.pPager, 0)) && usize(sqlite3_pager_vfs(p_bt.pPager)) == usize(p_vfs) {
					i_db := 0
					for i_db = db.nDb - 1; i_db >= 0; i_db-- {
						p_existing := db.aDb[i_db].pBt
						if !isnil(p_existing) && usize(p_existing.pBt) == usize(p_bt) {
							sqlite3_mutex_leave(mutex_shared)
							sqlite3_mutex_leave(mutex_open)
							sqlite3_free(voidptr(z_full_pathname))
							sqlite3_free(voidptr(p))
							return 19
						}
					}
					p.pBt = p_bt
					p_bt.nRef++
					break
				}
			}
			sqlite3_mutex_leave(mutex_shared)
			sqlite3_free(voidptr(z_full_pathname))
		}
	}
	if usize(p_bt) == usize(0) {
		C.memset(voidptr(unsafe { &z_db_header[0] + 16 }), 0, u64(8))
		p_bt = sqlite3_malloc_zero(U64(sizeof(BtShared)))
		if usize(p_bt) == usize(0) {
			rc = 7
			unsafe { goto btree_open_out
			 }
		}
		rc = sqlite3_pager_open(p_vfs, &&Pager(&p_bt.pPager), z_filename, int(sizeof(MemPage)), flags, vfs_flags, page_reinit)
		if rc == 0 {
			sqlite3_pager_set_mmap_limit(p_bt.pPager, db.szMmap)
			rc = sqlite3_pager_read_fileheader(p_bt.pPager, int(sizeof([100]u8)), &z_db_header[0])
		}
		if rc != 0 {
			unsafe { goto btree_open_out
			 }
		}
		p_bt.openFlags = U8(flags)
		p_bt.db = db
		sqlite3_pager_set_busy_handler(p_bt.pPager, btree_invoke_busy_handler, voidptr(p_bt))
		p.pBt = p_bt
		p_bt.pCursor = 0
		p_bt.pPage1 = 0
		if sqlite3_pager_isreadonly(p_bt.pPager) {
			p_bt.btsFlags |= 1
		}
		p_bt.pageSize = u32((int(z_db_header[16]) << 8) | (int(z_db_header[17]) << 16))
		if p_bt.pageSize < u32(512) || p_bt.pageSize > u32(65536) || ((p_bt.pageSize - u32(1)) & p_bt.pageSize) != u32(0) {
			p_bt.pageSize = u32(0)
			if !isnil(z_filename) && !is_memdb {
				p_bt.autoVacuum = U8((if 0 { 1 } else { 0 }))
				p_bt.incrVacuum = U8((if 0 == 2 { 1 } else { 0 }))
			}
			n_reserve = U8(0)
		} else {
			n_reserve = z_db_header[20]
			p_bt.btsFlags |= 2
			p_bt.autoVacuum = U8((if sqlite3_get4byte(unsafe { &z_db_header[0] + (36 + 4 * 4) }) {
				1
			} else {
				0
			}))
			p_bt.incrVacuum = U8((if sqlite3_get4byte(unsafe { &z_db_header[0] + (36 + 7 * 4) }) {
				1
			} else {
				0
			}))
		}
		rc = sqlite3_pager_set_pagesize(p_bt.pPager, &p_bt.pageSize, int(n_reserve))
		if rc {
			unsafe { goto btree_open_out
			 }
		}
		p_bt.usableSize = p_bt.pageSize - u32(n_reserve)
		p_bt.nRef = 1
		if p.sharable {
			mutex_shared := &Sqlite3_mutex(0)
			mutex_shared = sqlite3_mutex_alloc_vdup4(2)
			if 1 && int(sqlite3Config.bCoreMutex) {
				p_bt.mutex = sqlite3_mutex_alloc_vdup4(0)
				if usize(p_bt.mutex) == usize(0) {
					rc = 7
					unsafe { goto btree_open_out
					 }
				}
			}
			sqlite3_mutex_enter(mutex_shared)
			p_bt.pNext = sqlite3SharedCacheList
			sqlite3SharedCacheList = p_bt
			sqlite3_mutex_leave(mutex_shared)
		}
	}
	if p.sharable {
		i := 0
		p_sib := &Btree(0)
		for i = 0; i < db.nDb; i++ {
			p_sib = db.aDb[i].pBt
			if usize(p_sib) != usize(0) && int(p_sib.sharable) {
				for p_sib.pPrev {
					p_sib = p_sib.pPrev
				}
				if Uptr(voidptr(p.pBt)) < Uptr(voidptr(p_sib.pBt)) {
					p.pNext = p_sib
					p.pPrev = 0
					p_sib.pPrev = p
				} else {
					for !isnil(p_sib.pNext) && Uptr(voidptr(p_sib.pNext.pBt)) < Uptr(voidptr(p.pBt)) {
						p_sib = p_sib.pNext
					}
					p.pNext = p_sib.pNext
					p.pPrev = p_sib
					if p.pNext {
						p.pNext.pPrev = p
					}
					p_sib.pNext = p
				}
				break
			}
		}
	}
	unsafe { *pp_btree = p }
	btree_open_out:
	if rc != 0 {
		if !isnil(p_bt) && !isnil(p_bt.pPager) {
			sqlite3_pager_close(p_bt.pPager, unsafe { nil })
		}
		sqlite3_free(voidptr(p_bt))
		sqlite3_free(voidptr(p))
		unsafe { *pp_btree = 0 }
	} else {
		p_file := &Sqlite3_file(0)
		if usize(sqlite3_btree_schema(p, 0, unsafe { nil })) == usize(0) {
			sqlite3_btree_set_cache_size(p, -2000)
		}
		p_file = sqlite3_pager_file(p_bt.pPager)
		if p_file.pMethods {
			sqlite3_os_file_control_hint(p_file, 30, voidptr(&p_bt.db))
		}
	}
	if mutex_open {
		sqlite3_mutex_leave(mutex_open)
	}
	return rc
}

@[c:'removeFromSharingList']
fn remove_from_sharing_list(p_bt &BtShared) int {
	p_main_mtx := &Sqlite3_mutex(0)
	p_list := &BtShared(0)
	removed := 0
	p_main_mtx = sqlite3_mutex_alloc_vdup4(2)
	sqlite3_mutex_enter(p_main_mtx)
	p_bt.nRef--
	if p_bt.nRef <= 0 {
		if usize(sqlite3SharedCacheList) == usize(p_bt) {
			sqlite3SharedCacheList = p_bt.pNext
		} else {
			p_list = sqlite3SharedCacheList
			for !isnil(p_list) && usize(p_list.pNext) != usize(p_bt) {
				p_list = p_list.pNext
			}
			if p_list {
				p_list.pNext = p_bt.pNext
			}
		}
		if 1 {
			sqlite3_mutex_free(p_bt.mutex)
		}
		removed = 1
	}
	sqlite3_mutex_leave(p_main_mtx)
	return removed
}

@[c:'allocateTempSpace']
fn allocate_temp_space(p_bt &BtShared) int {
	p_bt.pTmpSpace = sqlite3_page_malloc(int(p_bt.pageSize))
	if usize(p_bt.pTmpSpace) == usize(0) {
		p_cur := p_bt.pCursor
		p_bt.pCursor = p_cur.pNext
		C.memset(voidptr(p_cur), 0, sizeof(BtCursor))
		return 7
	}
	C.memset(voidptr(p_bt.pTmpSpace), 0, u64(8))
	c2v_pointer_prefix(voidptr(&p_bt.pTmpSpace), p_bt.pTmpSpace, isize(4))
	return 0
}

@[c:'freeTempSpace']
fn free_temp_space(p_bt &BtShared) {
	if p_bt.pTmpSpace {
		c2v_pointer_prefix(voidptr(&p_bt.pTmpSpace), p_bt.pTmpSpace, isize(-(4)))
		sqlite3_page_free(voidptr(p_bt.pTmpSpace))
		p_bt.pTmpSpace = 0
	}
}

@[c:'sqlite3BtreeClose']
fn sqlite3_btree_close(p &Btree) int {
	p_bt := p.pBt
	sqlite3_btree_enter(p)
	sqlite3_btree_rollback(p, 0, 0)
	sqlite3_btree_leave(p)
	if !p.sharable || remove_from_sharing_list(p_bt) {
		sqlite3_pager_close(p_bt.pPager, p.db)
		if !isnil(p_bt.xFreeSchema) && !isnil(p_bt.pSchema) {
			p_bt.xFreeSchema(voidptr(p_bt.pSchema))
		}
		sqlite3_db_free(unsafe { nil }, voidptr(p_bt.pSchema))
		free_temp_space(p_bt)
		sqlite3_free(voidptr(p_bt))
	}
	if p.pPrev {
		p.pPrev.pNext = p.pNext
	}
	if p.pNext {
		p.pNext.pPrev = p.pPrev
	}
	sqlite3_free(voidptr(p))
	return 0
}

@[c:'sqlite3BtreeSetCacheSize']
fn sqlite3_btree_set_cache_size(p &Btree, mx_page int) int {
	p_bt := p.pBt
	sqlite3_btree_enter(p)
	sqlite3_pager_set_cachesize(p_bt.pPager, mx_page)
	sqlite3_btree_leave(p)
	return 0
}

@[c:'sqlite3BtreeSetSpillSize']
fn sqlite3_btree_set_spill_size(p &Btree, mx_page int) int {
	p_bt := p.pBt
	res := 0
	sqlite3_btree_enter(p)
	res = sqlite3_pager_set_spillsize(p_bt.pPager, mx_page)
	sqlite3_btree_leave(p)
	return res
}

@[c:'sqlite3BtreeSetMmapLimit']
fn sqlite3_btree_set_mmap_limit(p &Btree, sz_mmap Sqlite3_int64) int {
	p_bt := p.pBt
	sqlite3_btree_enter(p)
	sqlite3_pager_set_mmap_limit(p_bt.pPager, sz_mmap)
	sqlite3_btree_leave(p)
	return 0
}

@[c:'sqlite3BtreeSetPagerFlags']
fn sqlite3_btree_set_pager_flags(p &Btree, pg_flags u32) int {
	p_bt := p.pBt
	sqlite3_btree_enter(p)
	sqlite3_pager_set_flags(p_bt.pPager, pg_flags)
	sqlite3_btree_leave(p)
	return 0
}

@[c:'sqlite3BtreeSetPageSize']
fn sqlite3_btree_set_page_size(p &Btree, page_size int, n_reserve int, i_fix int) int {
	rc := 0
	x := 0
	p_bt := p.pBt
	sqlite3_btree_enter(p)
	p_bt.nReserveWanted = U8(n_reserve)
	x = int(p_bt.pageSize - p_bt.usableSize)
	if x == n_reserve && (page_size == 0 || u32(page_size) == p_bt.pageSize) {
		sqlite3_btree_leave(p)
		return 0
	}
	if n_reserve < x {
		n_reserve = x
	}
	if int(p_bt.btsFlags) & 2 {
		sqlite3_btree_leave(p)
		return 8
	}
	if page_size >= 512 && page_size <= 65536 && ((page_size - 1) & page_size) == 0 {
		if n_reserve > 32 && page_size == 512 {
			page_size = 1024
		}
		p_bt.pageSize = u32(page_size)
		free_temp_space(p_bt)
	}
	rc = sqlite3_pager_set_pagesize(p_bt.pPager, &p_bt.pageSize, n_reserve)
	p_bt.usableSize = p_bt.pageSize - u32(U16(n_reserve))
	if i_fix {
		p_bt.btsFlags |= 2
	}
	sqlite3_btree_leave(p)
	return rc
}

@[c:'sqlite3BtreeGetPageSize']
fn sqlite3_btree_get_page_size(p &Btree) int {
	return int(p.pBt.pageSize)
}

@[c:'sqlite3BtreeGetReserveNoMutex']
fn sqlite3_btree_get_reserve_no_mutex(p &Btree) int {
	n := 0
	n = int(p.pBt.pageSize - p.pBt.usableSize)
	return n
}

@[c:'sqlite3BtreeGetRequestedReserve']
fn sqlite3_btree_get_requested_reserve(p &Btree) int {
	n1 := 0
	n2 := 0

	sqlite3_btree_enter(p)
	n1 = int(p.pBt.nReserveWanted)
	n2 = sqlite3_btree_get_reserve_no_mutex(p)
	sqlite3_btree_leave(p)
	return if n1 > n2 { n1 } else { n2 }
}

@[c:'sqlite3BtreeMaxPageCount']
fn sqlite3_btree_max_page_count(p &Btree, mx_page Pgno) Pgno {
	n := Pgno(0)
	sqlite3_btree_enter(p)
	n = sqlite3_pager_max_page_count(p.pBt.pPager, mx_page)
	sqlite3_btree_leave(p)
	return n
}

@[c:'sqlite3BtreeSecureDelete']
fn sqlite3_btree_secure_delete(p &Btree, new_flag int) int {
	b := 0
	if usize(p) == usize(0) {
		return 0
	}
	sqlite3_btree_enter(p)
	if new_flag >= 0 {
		p.pBt.btsFlags &= ~12
		p.pBt.btsFlags |= int(U16((4 * new_flag)))
	}
	b = (int(p.pBt.btsFlags) & 12) / 4
	sqlite3_btree_leave(p)
	return b
}

@[c:'sqlite3BtreeSetAutoVacuum']
fn sqlite3_btree_set_auto_vacuum(p &Btree, auto_vacuum int) int {
	p_bt := p.pBt
	rc := 0
	av := U8(auto_vacuum)
	sqlite3_btree_enter(p)
	if (int(p_bt.btsFlags) & 2) != 0 && (if int(av) { 1 } else { 0 }) != int(p_bt.autoVacuum) {
		rc = 8
	} else {
		p_bt.autoVacuum = U8(if int(av) { 1 } else { 0 })
		p_bt.incrVacuum = U8(if int(av) == 2 { 1 } else { 0 })
	}
	sqlite3_btree_leave(p)
	return rc
}

@[c:'sqlite3BtreeGetAutoVacuum']
fn sqlite3_btree_get_auto_vacuum(p &Btree) int {
	rc := 0
	sqlite3_btree_enter(p)
	rc = (if (!p.pBt.autoVacuum) {
		0
	} else {
		if (!p.pBt.incrVacuum) { 1 } else { 2 }
	})
	sqlite3_btree_leave(p)
	return rc
}

@[c:'lockBtree']
fn lock_btree(p_bt &BtShared) int {
	rc := 0
	p_page1 := &MemPage(0)
	n_page := u32(0)
	n_page_file := u32(0)
	rc = sqlite3_pager_shared_lock(p_bt.pPager)
	if rc != 0 {
		return rc
	}
	rc = btree_get_page(p_bt, Pgno(1), &&MemPage(&&MemPage(c2v_address_of(&p_page1))), 0)
	if rc != 0 {
		return rc
	}
	n_page = sqlite3_get4byte(unsafe { &U8(p_page1.aData) + (28) })
	sqlite3_pager_pagecount(p_bt.pPager, &int(c2v_address_of(&n_page_file)))
	if n_page == u32(0) || C.memcmp(voidptr(unsafe { &U8(p_page1.aData) + (24) }), voidptr(unsafe { &U8(p_page1.aData) + (92) }), u64(4)) != 0 {
		n_page = n_page_file
	}
	if (p_bt.db.flags & U64(33554432)) != U64(0) {
		n_page = u32(0)
	}
	if n_page > u32(0) {
		page_size := u32(0)
		usable_size := u32(0)
		page1 := p_page1.aData
		rc = 26
		if C.memcmp(voidptr(page1), voidptr(unsafe { &zMagicHeader[0] }), u64(16)) != 0 {
			unsafe { goto page1_init_failed
			 }
		}
		if int(page1[18]) > 2 {
			p_bt.btsFlags |= 1
		}
		if int(page1[19]) > 2 {
			unsafe { goto page1_init_failed
			 }
		}
		if int(page1[19]) == 2 && (int(p_bt.btsFlags) & 32) == 0 {
			is_open := 0
			rc = sqlite3_pager_open_wal(p_bt.pPager, &is_open)
			if rc != 0 {
				unsafe { goto page1_init_failed
				 }
			} else {
				0
				if is_open == 0 {
					release_page_one(p_page1)
					return 0
				}
			}
			rc = 26
		} else {
			0
		}
		if C.memcmp(voidptr(unsafe { page1 + 21 }), voidptr(c'@  '), u64(3)) != 0 {
			unsafe { goto page1_init_failed
			 }
		}
		page_size = u32((int(page1[16]) << 8) | (int(page1[17]) << 16))
		if ((page_size - u32(1)) & page_size) != u32(0) || page_size > u32(65536) || page_size <= u32(256) {
			unsafe { goto page1_init_failed
			 }
		}
		usable_size = page_size - u32(page1[20])
		if u32(page_size) != p_bt.pageSize {
			release_page_one(p_page1)
			p_bt.usableSize = usable_size
			p_bt.pageSize = page_size
			p_bt.btsFlags |= 2
			free_temp_space(p_bt)
			rc = sqlite3_pager_set_pagesize(p_bt.pPager, &p_bt.pageSize, int(page_size - usable_size))
			return rc
		}
		if n_page > n_page_file {
			if sqlite3_writable_schema(p_bt.db) == 0 {
				rc = sqlite3_corrupt_error(3407)
				unsafe { goto page1_init_failed
				 }
			} else {
				n_page = n_page_file
			}
		}
		if usable_size < u32(480) {
			unsafe { goto page1_init_failed
			 }
		}
		p_bt.btsFlags |= 2
		p_bt.pageSize = page_size
		p_bt.usableSize = usable_size
		p_bt.autoVacuum = U8((if sqlite3_get4byte(unsafe { page1 + (36 + 4 * 4) }) { 1 } else { 0 }))
		p_bt.incrVacuum = U8((if sqlite3_get4byte(unsafe { page1 + (36 + 7 * 4) }) { 1 } else { 0 }))
	}
	p_bt.maxLocal = U16(((p_bt.usableSize - u32(12)) * u32(64) / u32(255) - u32(23)))
	p_bt.minLocal = U16(((p_bt.usableSize - u32(12)) * u32(32) / u32(255) - u32(23)))
	p_bt.maxLeaf = U16((p_bt.usableSize - u32(35)))
	p_bt.minLeaf = U16(((p_bt.usableSize - u32(12)) * u32(32) / u32(255) - u32(23)))
	if int(p_bt.maxLocal) > 127 {
		p_bt.max1bytePayload = U8(127)
	} else {
		p_bt.max1bytePayload = U8(p_bt.maxLocal)
	}
	p_bt.pPage1 = p_page1
	p_bt.nPage = n_page
	return 0
	page1_init_failed:
	release_page_one(p_page1)
	p_bt.pPage1 = 0
	return rc
}

@[c:'unlockBtreeIfUnused']
fn unlock_btree_if_unused(p_bt &BtShared) {
	if int(p_bt.inTransaction) == 0 && usize(p_bt.pPage1) != usize(0) {
		p_page1 := p_bt.pPage1
		p_bt.pPage1 = 0
		release_page_one(p_page1)
	}
}

@[c:'newDatabase']
fn new_database(p_bt &BtShared) int {
	p_p1 := &MemPage(0)
	data := &u8(0)
	rc := 0
	if p_bt.nPage > u32(0) {
		return 0
	}
	p_p1 = p_bt.pPage1
	data = p_p1.aData
	rc = sqlite3_pager_write(p_p1.pDbPage)
	if rc {
		return rc
	}
	C.memcpy(voidptr(data), voidptr(unsafe { &zMagicHeader[0] }), sizeof([16]i8))
	data[16] = U8(((p_bt.pageSize >> 8) & u32(255)))
	data[17] = U8(((p_bt.pageSize >> 16) & u32(255)))
	data[18] = u8(1)
	data[19] = u8(1)
	data[20] = U8((p_bt.pageSize - p_bt.usableSize))
	data[21] = u8(64)
	data[22] = u8(32)
	data[23] = u8(32)
	C.memset(voidptr(unsafe { data + 24 }), 0, u64(100 - 24))
	zero_page(p_p1, 1 | 8 | 4)
	p_bt.btsFlags |= 2
	sqlite3_put4byte(unsafe { &U8(data + (36 + 4 * 4)) }, u32(p_bt.autoVacuum))
	sqlite3_put4byte(unsafe { &U8(data + (36 + 7 * 4)) }, u32(p_bt.incrVacuum))
	p_bt.nPage = u32(1)
	data[31] = u8(1)
	return 0
}

@[c:'sqlite3BtreeNewDb']
fn sqlite3_btree_new_db(p &Btree) int {
	rc := 0
	sqlite3_btree_enter(p)
	p.pBt.nPage = u32(0)
	rc = new_database(p.pBt)
	sqlite3_btree_leave(p)
	return rc
}

@[c:'btreeBeginTrans']
fn btree_begin_trans(p &Btree, wrflag int, p_schema_version &int) int {
	p_bt := p.pBt
	p_pager := p_bt.pPager
	rc := 0
	sqlite3_btree_enter(p)
	0
	if int(p.inTrans) == 2 || (int(p.inTrans) == 1 && !wrflag) {
		unsafe { goto trans_begun
		 }
	}
	if (p.db.flags & U64(33554432)) && int(sqlite3_pager_isreadonly(p_pager)) == 0 {
		p_bt.btsFlags &= ~1
	}
	if (int(p_bt.btsFlags) & 1) != 0 && wrflag {
		rc = 8
		unsafe { goto trans_begun
		 }
	}
	p_block := unsafe { &Sqlite3(nil) }
	if (wrflag && int(p_bt.inTransaction) == 2) || (int(p_bt.btsFlags) & 128) != 0 {
		p_block = p_bt.pWriter.db
	} else if wrflag > 1 {
		p_iter := &BtLock(0)
		for p_iter = p_bt.pLock; p_iter; p_iter = p_iter.pNext {
			if usize(p_iter.pBtree) != usize(p) {
				p_block = p_iter.pBtree.db
				break
			}
		}
	}
	if p_block {
		0
		rc = (6 | (1 << 8))
		unsafe { goto trans_begun
		 }
	}
	rc = query_shared_cache_table_lock(p, Pgno(1), U8(1))
	if 0 != rc {
		unsafe { goto trans_begun
		 }
	}
	p_bt.btsFlags &= ~16
	if p_bt.nPage == u32(0) {
		p_bt.btsFlags |= 16
	}
	for {
		0
		for {
			if !(usize(p_bt.pPage1) == usize(0) && 0 == c2v_assign[int](unsafe { &rc }, int(lock_btree(p_bt)))) {
				break
			}
			0
		}
		if rc == 0 && wrflag {
			if (int(p_bt.btsFlags) & 1) != 0 {
				rc = 8
			} else {
				rc = sqlite3_pager_begin(p_pager, wrflag > 1, sqlite3_temp_in_memory(p.db))
				if rc == 0 {
					rc = new_database(p_bt)
				} else if rc == (5 | (2 << 8)) && int(p_bt.inTransaction) == 0 {
					rc = 5
				}
			}
		}
		if rc != 0 {
			unlock_btree_if_unused(p_bt)
		}
		if !((rc & 255) == 5 && int(p_bt.inTransaction) == 0 && btree_invoke_busy_handler(voidptr(p_bt))) {
			break
		}
	}
	0
	if rc == 0 {
		if int(p.inTrans) == 0 {
			p_bt.nTransaction++
			if p.sharable {
				p.lock_.eLock = U8(1)
				p.lock_.pNext = p_bt.pLock
				p_bt.pLock = &p.lock_
			}
		}
		p.inTrans = U8((if wrflag { 2 } else { 1 }))
		if int(p.inTrans) > int(p_bt.inTransaction) {
			p_bt.inTransaction = p.inTrans
		}
		if wrflag {
			p_page1 := p_bt.pPage1
			p_bt.pWriter = p
			p_bt.btsFlags &= ~64
			if wrflag > 1 {
				p_bt.btsFlags |= 64
			}
			if p_bt.nPage != sqlite3_get4byte(unsafe { p_page1.aData + 28 }) {
				rc = sqlite3_pager_write(p_page1.pDbPage)
				if rc == 0 {
					sqlite3_put4byte(unsafe { p_page1.aData + 28 }, p_bt.nPage)
				}
			}
		}
	}
	trans_begun:
	if rc == 0 {
		if p_schema_version {
			unsafe { *p_schema_version = int(sqlite3_get4byte(p_bt.pPage1.aData + 40)) }
		}
		if wrflag {
			rc = sqlite3_pager_open_savepoint(p_pager, p.db.nSavepoint)
		}
	}
	0
	sqlite3_btree_leave(p)
	return rc
}

@[c:'sqlite3BtreeBeginTrans']
fn sqlite3_btree_begin_trans(p &Btree, wrflag int, p_schema_version &int) int {
	p_bt := &BtShared(0)
	if int(p.sharable) || int(p.inTrans) == 0 || (int(p.inTrans) == 1 && wrflag != 0) {
		return btree_begin_trans(p, wrflag, p_schema_version)
	}
	p_bt = p.pBt
	if p_schema_version {
		unsafe { *p_schema_version = int(sqlite3_get4byte(p_bt.pPage1.aData + 40)) }
	}
	if wrflag {
		return sqlite3_pager_open_savepoint(p_bt.pPager, p.db.nSavepoint)
	} else {
		return 0
	}
}

@[c:'setChildPtrmaps']
fn set_child_ptrmaps(p_page &MemPage) int {
	i := 0
	n_cell := 0
	rc := 0
	p_bt := p_page.pBt
	pgno := p_page.pgno
	rc = if int(p_page.isInit) { 0 } else { btree_init_page(p_page) }
	if rc != 0 {
		return rc
	}
	n_cell = int(p_page.nCell)
	for i = 0; i < n_cell; i++ {
		p_cell := (p_page.aData + (int(p_page.maskPage) & (int((unsafe { p_page.aCellIdx + (2 * i) })[0]) << 8 | int((unsafe { p_page.aCellIdx + (2 * i) })[1]))))
		ptrmap_put_ovfl_ptr(p_page, p_page, p_cell, &rc)
		if !p_page.leaf {
			child_pgno := sqlite3_get4byte(p_cell)
			ptrmap_put(p_bt, child_pgno, U8(5), pgno, &rc)
		}
	}
	if !p_page.leaf {
		child_pgno := sqlite3_get4byte(unsafe { p_page.aData + (int(p_page.hdrOffset) + 8) })
		ptrmap_put(p_bt, child_pgno, U8(5), pgno, &rc)
	}
	return rc
}

@[c:'modifyPagePointer']
fn modify_page_pointer(p_page &MemPage, i_from Pgno, i_to Pgno, e_type U8) int {
	if int(e_type) == 4 {
		if sqlite3_get4byte(p_page.aData) != i_from {
			return sqlite3_corrupt_error(3886)
		}
		sqlite3_put4byte(p_page.aData, i_to)
	} else {
		i := 0
		n_cell := 0
		rc := 0
		rc = if int(p_page.isInit) { 0 } else { btree_init_page(p_page) }
		if rc {
			return rc
		}
		n_cell = int(p_page.nCell)
		for i = 0; i < n_cell; i++ {
			p_cell := (p_page.aData + (int(p_page.maskPage) & (int((unsafe { p_page.aCellIdx + (2 * i) })[0]) << 8 | int((unsafe { p_page.aCellIdx + (2 * i) })[1]))))
			if int(e_type) == 3 {
				info := CellInfo{}
				p_page.xParseCell(p_page, p_cell, &info)
				if u32(info.nLocal) < info.nPayload {
					if usize(p_cell + info.nSize) > usize(p_page.aData + p_page.pBt.usableSize) {
						return sqlite3_corrupt_error(3905)
					}
					if i_from == sqlite3_get4byte(p_cell + int(info.nSize) - 4) {
						sqlite3_put4byte(p_cell + int(info.nSize) - 4, i_to)
						break
					}
				}
			} else {
				if usize(p_cell + 4) > usize(p_page.aData + p_page.pBt.usableSize) {
					return sqlite3_corrupt_error(3914)
				}
				if sqlite3_get4byte(p_cell) == i_from {
					sqlite3_put4byte(p_cell, i_to)
					break
				}
			}
		}
		if i == n_cell {
			if int(e_type) != 5 || sqlite3_get4byte(unsafe { p_page.aData + (int(p_page.hdrOffset) + 8) }) != i_from {
				return sqlite3_corrupt_error(3926)
			}
			sqlite3_put4byte(unsafe { p_page.aData + (int(p_page.hdrOffset) + 8) }, i_to)
		}
	}
	return 0
}

@[c:'relocatePage']
fn relocate_page(p_bt &BtShared, p_db_page &MemPage, e_type U8, i_ptr_page Pgno, i_free_page Pgno, is_commit int) int {
	p_ptr_page := &MemPage(0)
	i_db_page := p_db_page.pgno
	p_pager := p_bt.pPager
	rc := 0
	if i_db_page < Pgno(3) {
		return sqlite3_corrupt_error(3961)
	}
	0
	rc = sqlite3_pager_movepage(p_pager, p_db_page.pDbPage, i_free_page, is_commit)
	if rc != 0 {
		return rc
	}
	p_db_page.pgno = i_free_page
	if int(e_type) == 5 || int(e_type) == 1 {
		rc = set_child_ptrmaps(p_db_page)
		if rc != 0 {
			return rc
		}
	} else {
		next_ovfl := sqlite3_get4byte(p_db_page.aData)
		if next_ovfl != Pgno(0) {
			ptrmap_put(p_bt, next_ovfl, U8(4), i_free_page, &rc)
			if rc != 0 {
				return rc
			}
		}
	}
	if int(e_type) != 1 {
		rc = btree_get_page(p_bt, i_ptr_page, &&MemPage(&&MemPage(c2v_address_of(&p_ptr_page))), 0)
		if rc != 0 {
			return rc
		}
		rc = sqlite3_pager_write(p_ptr_page.pDbPage)
		if rc != 0 {
			release_page(p_ptr_page)
			return rc
		}
		rc = modify_page_pointer(p_ptr_page, i_db_page, i_free_page, e_type)
		release_page(p_ptr_page)
		if rc == 0 {
			ptrmap_put(p_bt, i_free_page, e_type, i_ptr_page, &rc)
		}
	}
	return rc
}

@[c:'incrVacuumStep']
fn incr_vacuum_step(p_bt &BtShared, n_fin Pgno, i_last_pg Pgno, b_commit int) int {
	n_free_list := Pgno(0)
	rc := 0
	if !(ptrmap_pageno(p_bt, i_last_pg) == i_last_pg) && i_last_pg != (Pgno(((u32(sqlite3PendingByte) / p_bt.pageSize) + u32(1)))) {
		e_type := U8(0)
		i_ptr_page := Pgno(0)
		n_free_list = sqlite3_get4byte(unsafe { p_bt.pPage1.aData + 36 })
		if n_free_list == Pgno(0) {
			return 101
		}
		rc = ptrmap_get(p_bt, i_last_pg, &e_type, &i_ptr_page)
		if rc != 0 {
			return rc
		}
		if int(e_type) == 1 {
			return sqlite3_corrupt_error(4059)
		}
		if int(e_type) == 2 {
			if b_commit == 0 {
				i_free_pg := Pgno(0)
				p_free_pg := &MemPage(0)
				rc = allocate_btree_page(p_bt, &&MemPage(&&MemPage(c2v_address_of(&p_free_pg))), &i_free_pg, i_last_pg, U8(1))
				if rc != 0 {
					return rc
				}
				release_page(p_free_pg)
			}
		} else {
			i_free_pg := Pgno(0)
			p_last_pg := &MemPage(0)
			e_mode := U8(0)
			i_near := Pgno(0)
			rc = btree_get_page(p_bt, i_last_pg, &&MemPage(&&MemPage(c2v_address_of(&p_last_pg))), 0)
			if rc != 0 {
				return rc
			}
			if b_commit == 0 {
				e_mode = U8(2)
				i_near = n_fin
			}
			for {
				p_free_pg := &MemPage(0)
				db_size := btree_pagecount(p_bt)
				rc = allocate_btree_page(p_bt, &&MemPage(&&MemPage(c2v_address_of(&p_free_pg))), &i_free_pg, i_near, e_mode)
				if rc != 0 {
					release_page(p_last_pg)
					return rc
				}
				release_page(p_free_pg)
				if i_free_pg > db_size {
					release_page(p_last_pg)
					return sqlite3_corrupt_error(4111)
				}
				if !(b_commit && i_free_pg > n_fin) {
					break
				}
			}
			rc = relocate_page(p_bt, p_last_pg, e_type, i_ptr_page, i_free_pg, b_commit)
			release_page(p_last_pg)
			if rc != 0 {
				return rc
			}
		}
	}
	if b_commit == 0 {
		for {
			i_last_pg--
			if !(i_last_pg == (Pgno(((u32(sqlite3PendingByte) / p_bt.pageSize) + u32(1)))) || (ptrmap_pageno(p_bt, i_last_pg) == i_last_pg)) {
				break
			}
		}
		p_bt.bDoTruncate = U8(1)
		p_bt.nPage = i_last_pg
	}
	return 0
}

@[c:'finalDbSize']
fn final_db_size(p_bt &BtShared, n_orig Pgno, n_free Pgno) Pgno {
	n_entry := 0
	n_ptrmap := Pgno(0)
	n_fin := Pgno(0)
	n_entry = int(p_bt.usableSize / u32(5))
	n_ptrmap = (n_free - n_orig + ptrmap_pageno(p_bt, n_orig) + Pgno(n_entry)) / Pgno(n_entry)
	n_fin = n_orig - n_free - n_ptrmap
	if n_orig > (Pgno(((u32(sqlite3PendingByte) / p_bt.pageSize) + u32(1)))) && n_fin < (Pgno(((u32(sqlite3PendingByte) / p_bt.pageSize) + u32(1)))) {
		n_fin--
	}
	for (ptrmap_pageno(p_bt, n_fin) == n_fin) || n_fin == (Pgno(((u32(sqlite3PendingByte) / p_bt.pageSize) + u32(1)))) {
		n_fin--
	}
	return n_fin
}

@[c:'sqlite3BtreeIncrVacuum']
fn sqlite3_btree_incr_vacuum(p &Btree) int {
	rc := 0
	p_bt := p.pBt
	sqlite3_btree_enter(p)
	if !p_bt.autoVacuum {
		rc = 101
	} else {
		n_orig := btree_pagecount(p_bt)
		n_free := sqlite3_get4byte(unsafe { p_bt.pPage1.aData + 36 })
		n_fin := final_db_size(p_bt, n_orig, n_free)
		if n_orig < n_fin || n_free >= n_orig {
			rc = sqlite3_corrupt_error(4179)
		} else if n_free > Pgno(0) {
			rc = save_all_cursors(p_bt, Pgno(0), unsafe { nil })
			if rc == 0 {
				invalidate_all_overflow_cache(p_bt)
				rc = incr_vacuum_step(p_bt, n_fin, n_orig, 0)
			}
			if rc == 0 {
				rc = sqlite3_pager_write(p_bt.pPage1.pDbPage)
				sqlite3_put4byte(unsafe { p_bt.pPage1.aData + 28 }, p_bt.nPage)
			}
		} else {
			rc = 101
		}
	}
	sqlite3_btree_leave(p)
	return rc
}

@[c:'autoVacuumCommit']
fn auto_vacuum_commit(p &Btree) int {
	rc := 0
	p_pager := &Pager(0)
	p_bt := &BtShared(0)
	db := &Sqlite3(0)
	0
	p_bt = p.pBt
	p_pager = p_bt.pPager
	invalidate_all_overflow_cache(p_bt)
	if !p_bt.incrVacuum {
		n_fin := Pgno(0)
		n_free := Pgno(0)
		n_vac := Pgno(0)
		i_free := Pgno(0)
		n_orig := Pgno(0)
		n_orig = btree_pagecount(p_bt)
		if (ptrmap_pageno(p_bt, n_orig) == n_orig) || n_orig == (Pgno(((u32(sqlite3PendingByte) / p_bt.pageSize) + u32(1)))) {
			return sqlite3_corrupt_error(4230)
		}
		n_free = sqlite3_get4byte(unsafe { p_bt.pPage1.aData + 36 })
		db = p.db
		if db.xAutovacPages {
			i_db := 0
			for i_db = 0; (i_db < db.nDb); i_db++ {
				if usize(db.aDb[i_db].pBt) == usize(p) {
					break
				}
			}
			n_vac = db.xAutovacPages(voidptr(db.pAutovacPagesArg), db.aDb[i_db].zDbSName, n_orig, n_free, p_bt.pageSize)
			if n_vac > n_free {
				n_vac = n_free
			}
			if n_vac == Pgno(0) {
				return 0
			}
		} else {
			n_vac = n_free
		}
		n_fin = final_db_size(p_bt, n_orig, n_vac)
		if n_fin > n_orig {
			return sqlite3_corrupt_error(4257)
		}
		if n_fin < n_orig {
			rc = save_all_cursors(p_bt, Pgno(0), unsafe { nil })
		}
		for i_free = n_orig; i_free > n_fin && rc == 0; i_free-- {
			rc = incr_vacuum_step(p_bt, n_fin, i_free, n_vac == n_free)
		}
		if (rc == 101 || rc == 0) && n_free > Pgno(0) {
			rc = sqlite3_pager_write(p_bt.pPage1.pDbPage)
			if n_vac == n_free {
				sqlite3_put4byte(unsafe { p_bt.pPage1.aData + 32 }, u32(0))
				sqlite3_put4byte(unsafe { p_bt.pPage1.aData + 36 }, u32(0))
			}
			sqlite3_put4byte(unsafe { p_bt.pPage1.aData + 28 }, n_fin)
			p_bt.bDoTruncate = U8(1)
			p_bt.nPage = n_fin
		}
		if rc != 0 {
			sqlite3_pager_rollback(p_pager)
		}
	}
	return rc
}

@[c:'sqlite3BtreeCommitPhaseOne']
fn sqlite3_btree_commit_phase_one(p &Btree, z_super_jrnl &i8) int {
	rc := 0
	if int(p.inTrans) == 2 {
		p_bt := p.pBt
		sqlite3_btree_enter(p)
		if p_bt.autoVacuum {
			rc = auto_vacuum_commit(p)
			if rc != 0 {
				sqlite3_btree_leave(p)
				return rc
			}
		}
		if p_bt.bDoTruncate {
			sqlite3_pager_truncate_image(p_bt.pPager, p_bt.nPage)
		}
		rc = sqlite3_pager_commit_phase_one(p_bt.pPager, z_super_jrnl, 0)
		sqlite3_btree_leave(p)
	}
	return rc
}

@[c:'btreeEndTransaction']
fn btree_end_transaction(p &Btree) {
	p_bt := p.pBt
	db := p.db
	p_bt.bDoTruncate = U8(0)
	if int(p.inTrans) > 0 && db.nVdbeRead > 1 {
		downgrade_all_shared_cache_table_locks(p)
		p.inTrans = U8(1)
	} else {
		if int(p.inTrans) != 0 {
			clear_all_shared_cache_table_locks(p)
			p_bt.nTransaction--
			if 0 == p_bt.nTransaction {
				p_bt.inTransaction = U8(0)
			}
		}
		p.inTrans = U8(0)
		unlock_btree_if_unused(p_bt)
	}
	0
}

@[c:'sqlite3BtreeCommitPhaseTwo']
fn sqlite3_btree_commit_phase_two(p &Btree, b_cleanup int) int {
	if int(p.inTrans) == 0 {
		return 0
	}
	sqlite3_btree_enter(p)
	0
	if int(p.inTrans) == 2 {
		rc := 0
		p_bt := p.pBt
		rc = sqlite3_pager_commit_phase_two(p_bt.pPager)
		if rc != 0 && b_cleanup == 0 {
			sqlite3_btree_leave(p)
			return rc
		}
		p.iBDataVersion--
		p_bt.inTransaction = U8(1)
		btree_clear_has_content(p_bt)
	}
	btree_end_transaction(p)
	sqlite3_btree_leave(p)
	return 0
}

@[c:'sqlite3BtreeCommit']
fn sqlite3_btree_commit(p &Btree) int {
	rc := 0
	sqlite3_btree_enter(p)
	rc = sqlite3_btree_commit_phase_one(p, unsafe { nil })
	if rc == 0 {
		rc = sqlite3_btree_commit_phase_two(p, 0)
	}
	sqlite3_btree_leave(p)
	return rc
}

@[c:'sqlite3BtreeTripAllCursors']
fn sqlite3_btree_trip_all_cursors(p_btree &Btree, err_code int, write_only int) int {
	p := &BtCursor(0)
	rc := 0
	if p_btree {
		sqlite3_btree_enter(p_btree)
		for p = p_btree.pBt.pCursor; p; p = p.pNext {
			if write_only && (int(p.curFlags) & 1) == 0 {
				if int(p.eState) == 0 || int(p.eState) == 2 {
					rc = save_cursor_position(p)
					if rc != 0 {
						sqlite3_btree_trip_all_cursors(p_btree, rc, 0)
						break
					}
				}
			} else {
				sqlite3_btree_clear_cursor(p)
				p.eState = U8(4)
				p.skipNext = err_code
			}
			btree_release_all_cursor_pages(p)
		}
		sqlite3_btree_leave(p_btree)
	}
	return rc
}

@[c:'btreeSetNPage']
fn btree_set_np_age(p_bt &BtShared, p_page1 &MemPage) {
	n_page := int(sqlite3_get4byte(unsafe { p_page1.aData + 28 }))
	0
	if n_page == 0 {
		sqlite3_pager_pagecount(p_bt.pPager, &n_page)
	}
	0
	p_bt.nPage = u32(n_page)
}

@[c:'sqlite3BtreeRollback']
fn sqlite3_btree_rollback(p &Btree, trip_code int, write_only int) int {
	rc := 0
	p_bt := p.pBt
	p_page1 := &MemPage(0)
	sqlite3_btree_enter(p)
	if trip_code == 0 {
		trip_code = save_all_cursors(p_bt, Pgno(0), unsafe { nil })
		rc = trip_code
		if rc {
			write_only = 0
		}
	} else {
		rc = 0
	}
	if trip_code {
		rc2 := sqlite3_btree_trip_all_cursors(p, trip_code, write_only)
		if rc2 != 0 {
			rc = rc2
		}
	}
	0
	if int(p.inTrans) == 2 {
		rc2 := 0
		rc2 = sqlite3_pager_rollback(p_bt.pPager)
		if rc2 != 0 {
			rc = rc2
		}
		if btree_get_page(p_bt, Pgno(1), &&MemPage(&&MemPage(c2v_address_of(&p_page1))), 0) == 0 {
			btree_set_np_age(p_bt, p_page1)
			release_page_one(p_page1)
		}
		p_bt.inTransaction = U8(1)
		btree_clear_has_content(p_bt)
	}
	btree_end_transaction(p)
	sqlite3_btree_leave(p)
	return rc
}

@[c:'sqlite3BtreeBeginStmt']
fn sqlite3_btree_begin_stmt(p &Btree, i_statement int) int {
	rc := 0
	p_bt := p.pBt
	sqlite3_btree_enter(p)
	rc = sqlite3_pager_open_savepoint(p_bt.pPager, i_statement)
	sqlite3_btree_leave(p)
	return rc
}

@[c:'sqlite3BtreeSavepoint']
fn sqlite3_btree_savepoint(p &Btree, op int, i_savepoint int) int {
	rc := 0
	if !isnil(p) && int(p.inTrans) == 2 {
		p_bt := p.pBt
		sqlite3_btree_enter(p)
		if op == 2 {
			rc = save_all_cursors(p_bt, Pgno(0), unsafe { nil })
		}
		if rc == 0 {
			rc = sqlite3_pager_savepoint(p_bt.pPager, op, i_savepoint)
		}
		if rc == 0 {
			if i_savepoint < 0 && (int(p_bt.btsFlags) & 16) != 0 {
				p_bt.nPage = u32(0)
			}
			rc = new_database(p_bt)
			btree_set_np_age(p_bt, p_bt.pPage1)
		}
		sqlite3_btree_leave(p)
	}
	return rc
}

@[c:'btreeCursor']
fn btree_cursor(p &Btree, i_table Pgno, wr_flag int, p_key_info &KeyInfo, p_cur &BtCursor) int {
	p_bt := p.pBt
	px := &BtCursor(0)
	if i_table <= Pgno(1) {
		if i_table < Pgno(1) {
			return sqlite3_corrupt_error(4721)
		} else if btree_pagecount(p_bt) == Pgno(0) {
			i_table = Pgno(0)
		}
	}
	p_cur.pgnoRoot = i_table
	p_cur.iPage = I8(-1)
	p_cur.pKeyInfo = p_key_info
	p_cur.pBtree = p
	p_cur.pBt = p_bt
	p_cur.curFlags = U8(0)
	for px = p_bt.pCursor; px; px = px.pNext {
		if px.pgnoRoot == i_table {
			px.curFlags |= 32
			p_cur.curFlags = U8(32)
		}
	}
	p_cur.eState = U8(1)
	p_cur.pNext = p_bt.pCursor
	p_bt.pCursor = p_cur
	if wr_flag {
		p_cur.curFlags |= 1
		p_cur.curPagerFlags = U8(0)
		if usize(p_bt.pTmpSpace) == usize(0) {
			return allocate_temp_space(p_bt)
		}
	} else {
		p_cur.curPagerFlags = U8(2)
	}
	return 0
}

@[c:'btreeCursorWithLock']
fn btree_cursor_with_lock(p &Btree, i_table Pgno, wr_flag int, p_key_info &KeyInfo, p_cur &BtCursor) int {
	rc := 0
	sqlite3_btree_enter(p)
	rc = btree_cursor(p, i_table, wr_flag, p_key_info, p_cur)
	sqlite3_btree_leave(p)
	return rc
}

@[c:'sqlite3BtreeCursor']
fn sqlite3_btree_cursor(p &Btree, i_table Pgno, wr_flag int, p_key_info &KeyInfo, p_cur &BtCursor) int {
	if p.sharable {
		return btree_cursor_with_lock(p, i_table, wr_flag, p_key_info, p_cur)
	} else {
		return btree_cursor(p, i_table, wr_flag, p_key_info, p_cur)
	}
}

@[c:'sqlite3BtreeCursorSize']
fn sqlite3_btree_cursor_size() int {
	return int((((sizeof(BtCursor)) + u64(7)) & u64(~7)))
}

@[c:'sqlite3BtreeCursorZero']
fn sqlite3_btree_cursor_zero(p &BtCursor) {
	C.memset(voidptr(p), 0, (u64(usize(__offsetof(BtCursor, pBt)))))
}

@[c:'sqlite3BtreeCloseCursor']
fn sqlite3_btree_close_cursor(p_cur &BtCursor) int {
	p_btree := p_cur.pBtree
	if p_btree {
		p_bt := p_cur.pBt
		sqlite3_btree_enter(p_btree)
		if usize(p_bt.pCursor) == usize(p_cur) {
			p_bt.pCursor = p_cur.pNext
		} else {
			p_prev := p_bt.pCursor
			for {
				if usize(p_prev.pNext) == usize(p_cur) {
					p_prev.pNext = p_cur.pNext
					break
				}
				p_prev = p_prev.pNext
				if !p_prev {
					break
				}
			}
		}
		btree_release_all_cursor_pages(p_cur)
		unlock_btree_if_unused(p_bt)
		sqlite3_free(voidptr(p_cur.aOverflow))
		sqlite3_free(voidptr(p_cur.pKey))
		if (int(p_bt.openFlags) & 4) && usize(p_bt.pCursor) == usize(0) {
			sqlite3_btree_close(p_btree)
		} else {
			sqlite3_btree_leave(p_btree)
		}
		p_cur.pBtree = 0
	}
	return 0
}

@[c:'getCellInfo']
fn get_cell_info(p_cur &BtCursor) {
	if int(p_cur.info.nSize) == 0 {
		p_cur.curFlags |= 2
		btree_parse_cell(p_cur.pPage, int(p_cur.ix), &p_cur.info)
	} else {
		0
	}
}

@[c:'sqlite3BtreeCursorIsValidNN']
fn sqlite3_btree_cursor_is_valid_nn(p_cur &BtCursor) int {
	return int(p_cur.eState == 0)
}

@[c:'sqlite3BtreeIntegerKey']
fn sqlite3_btree_integer_key(p_cur &BtCursor) I64 {
	get_cell_info(p_cur)
	return p_cur.info.nKey
}

@[c:'sqlite3BtreeCursorPin']
fn sqlite3_btree_cursor_pin(p_cur &BtCursor) {
	p_cur.curFlags |= 64
}

@[c:'sqlite3BtreeCursorUnpin']
fn sqlite3_btree_cursor_unpin(p_cur &BtCursor) {
	p_cur.curFlags &= ~64
}

@[c:'sqlite3BtreeOffset']
fn sqlite3_btree_offset(p_cur &BtCursor) I64 {
	get_cell_info(p_cur)
	return I64(p_cur.pBt.pageSize) * (I64(p_cur.pPage.pgno) - I64(1)) + I64((i64((isize(p_cur.info.pPayload) - isize(p_cur.pPage.aData)) / isize(sizeof(U8)))))
}

@[c:'sqlite3BtreePayloadSize']
fn sqlite3_btree_payload_size(p_cur &BtCursor) u32 {
	get_cell_info(p_cur)
	return p_cur.info.nPayload
}

@[c:'sqlite3BtreeMaxRecordSize']
fn sqlite3_btree_max_record_size(p_cur &BtCursor) Sqlite3_int64 {
	return Sqlite3_int64(p_cur.pBt.pageSize) * Sqlite3_int64(p_cur.pBt.nPage)
}

@[c:'getOverflowPage']
fn get_overflow_page(p_bt &BtShared, ovfl Pgno, pp_page &&MemPage, p_pgno_next &Pgno) int {
	next := Pgno(0)
	p_page := unsafe { &MemPage(nil) }
	rc := 0
	if p_bt.autoVacuum {
		pgno := Pgno(0)
		i_guess := ovfl + Pgno(1)
		e_type := U8(0)
		for (ptrmap_pageno(p_bt, i_guess) == i_guess) || i_guess == (Pgno(((u32(sqlite3PendingByte) / p_bt.pageSize) + u32(1)))) {
			i_guess++
		}
		if i_guess <= btree_pagecount(p_bt) {
			rc = ptrmap_get(p_bt, i_guess, &e_type, &pgno)
			if rc == 0 && int(e_type) == 4 && pgno == ovfl {
				next = i_guess
				rc = 101
			}
		}
	}
	if rc == 0 {
		rc = btree_get_page(p_bt, ovfl, &&MemPage(&&MemPage(c2v_address_of(&p_page))), if (usize(pp_page) == usize(0)) {
			2
		} else {
			0
		})
		if rc == 0 {
			next = sqlite3_get4byte(p_page.aData)
		}
	}
	unsafe { *p_pgno_next = next }
	if pp_page {
		unsafe { *pp_page = p_page }
	} else {
		release_page(p_page)
	}
	return if rc == 101 { 0 } else { rc }
}

@[c:'copyPayload']
fn copy_payload(p_payload voidptr, p_buf voidptr, n_byte int, e_op int, p_db_page &DbPage) int {
	if e_op {
		rc := sqlite3_pager_write(p_db_page)
		if rc != 0 {
			return rc
		}
		C.memcpy(voidptr(p_payload), voidptr(p_buf), u64(n_byte))
	} else {
		C.memcpy(voidptr(p_buf), voidptr(p_payload), u64(n_byte))
	}
	return 0
}

@[c:'accessPayload']
fn access_payload(p_cur &BtCursor, offset u32, amt u32, p_buf &u8, e_op int) int {
	a_payload := &u8(0)
	rc := 0
	i_idx := 0
	p_page := p_cur.pPage
	p_bt := p_cur.pBt
	p_buf_start := p_buf
	if int(p_cur.ix) >= int(p_page.nCell) {
		return sqlite3_corrupt_error(5145)
	}
	get_cell_info(p_cur)
	a_payload = p_cur.info.pPayload
	if Uptr((i64((isize(a_payload) - isize(p_page.aData)) / isize(sizeof(u8))))) > Uptr((p_bt.usableSize - u32(p_cur.info.nLocal))) {
		return sqlite3_corrupt_error(5160)
	}
	if offset < u32(p_cur.info.nLocal) {
		a := int(amt)
		if u32(a) + offset > u32(p_cur.info.nLocal) {
			a = int(u32(p_cur.info.nLocal) - offset)
		}
		rc = copy_payload(voidptr(unsafe { a_payload + offset }), voidptr(p_buf), a, e_op, p_page.pDbPage)
		offset = u32(0)
		c2v_pointer_prefix(voidptr(&p_buf), p_buf, isize(a))
		amt -= u32(a)
	} else {
		offset -= u32(p_cur.info.nLocal)
	}
	if rc == 0 && amt > u32(0) {
		ovfl_size := p_bt.usableSize - u32(4)
		next_page := Pgno(0)
		next_page = sqlite3_get4byte(unsafe { a_payload + p_cur.info.nLocal })
		if (int(p_cur.curFlags) & 4) == 0 {
			n_ovfl := I64(p_cur.info.nPayload)
			0
			n_ovfl = (n_ovfl - I64(p_cur.info.nLocal) + I64(ovfl_size) - I64(1)) / I64(ovfl_size)
			if usize(p_cur.aOverflow) == usize(0) || n_ovfl * I64(int(sizeof(Pgno))) > I64(sqlite3_malloc_size(voidptr(p_cur.aOverflow))) {
				a_new := &Pgno(0)
				if sqlite3_fault_sim(413) {
					a_new = 0
				} else {
					a_new = &Pgno(sqlite3_realloc_vdup3(voidptr(p_cur.aOverflow), u64(n_ovfl * I64(2)) * sizeof(Pgno)))
				}
				if usize(a_new) == usize(0) {
					return 7
				} else {
					p_cur.aOverflow = a_new
				}
			}
			C.memset(voidptr(p_cur.aOverflow), 0, u64(n_ovfl) * sizeof(Pgno))
			p_cur.curFlags |= 4
		} else {
			if p_cur.aOverflow[offset / ovfl_size] {
				i_idx = int((offset / ovfl_size))
				next_page = p_cur.aOverflow[i_idx]
				offset = (offset % ovfl_size)
			}
		}
		for next_page {
			if next_page > p_bt.nPage {
				return sqlite3_corrupt_error(5233)
			}
			p_cur.aOverflow[i_idx] = next_page
			if offset >= ovfl_size {
				if p_cur.aOverflow[i_idx + 1] {
					next_page = p_cur.aOverflow[i_idx + 1]
				} else {
					rc = get_overflow_page(p_bt, next_page, unsafe { &&MemPage(nil) }, &next_page)
				}
				offset -= ovfl_size
			} else {
				a := int(amt)
				if u32(a) + offset > ovfl_size {
					a = int(ovfl_size - offset)
				}
				if e_op == 0 && offset == u32(0) && sqlite3_pager_direct_read_ok(p_bt.pPager, next_page) && usize(unsafe { p_buf + -4 }) >= usize(p_buf_start) {
					fd := sqlite3_pager_file(p_bt.pPager)
					a_save := [4]U8{}
					a_write := unsafe { p_buf + -4 }
					C.memcpy(voidptr(unsafe { &a_save[0] }), voidptr(a_write), u64(4))
					rc = sqlite3_os_read(fd, voidptr(a_write), a + 4, I64(p_bt.pageSize) * I64((next_page - Pgno(1))))
					next_page = sqlite3_get4byte(a_write)
					C.memcpy(voidptr(a_write), voidptr(unsafe { &a_save[0] }), u64(4))
				} else {
					p_db_page := &DbPage(0)
					rc = sqlite3_pager_get(p_bt.pPager, next_page, &&DbPage(&&DbPage(c2v_address_of(&p_db_page))), (if e_op == 0 {
						2
					} else {
						0
					}))
					if rc == 0 {
						if e_op != 0 && (sqlite3_pager_page_refcount(p_db_page) != 1 || int((&MemPage(sqlite3_pager_get_extra(p_db_page))).isInit)) {
							sqlite3_pager_unref(p_db_page)
							return sqlite3_corrupt_error(5303)
						}
						a_payload = &u8(sqlite3_pager_get_data(p_db_page))
						next_page = sqlite3_get4byte(a_payload)
						rc = copy_payload(voidptr(unsafe { a_payload + (offset + u32(4)) }), voidptr(p_buf), a, e_op, p_db_page)
						sqlite3_pager_unref(p_db_page)
						offset = u32(0)
					}
				}
				amt -= u32(a)
				if amt == u32(0) {
					return rc
				}
				c2v_pointer_prefix(voidptr(&p_buf), p_buf, isize(a))
			}
			if rc {
				break
			}
			i_idx++
		}
	}
	if rc == 0 && amt > u32(0) {
		return sqlite3_corrupt_error(5323)
	}
	return rc
}

@[c:'sqlite3BtreePayload']
fn sqlite3_btree_payload(p_cur &BtCursor, offset u32, amt u32, p_buf voidptr) int {
	return access_payload(p_cur, offset, amt, &u8(p_buf), 0)
}

@[c:'accessPayloadChecked']
fn access_payload_checked(p_cur &BtCursor, offset u32, amt u32, p_buf voidptr) int {
	rc := 0
	if int(p_cur.eState) == 1 {
		return 4
	}
	rc = btree_restore_cursor_position(p_cur)
	return if rc { rc } else { access_payload(p_cur, offset, amt, &u8(p_buf), 0) }
}

@[c:'sqlite3BtreePayloadChecked']
fn sqlite3_btree_payload_checked(p_cur &BtCursor, offset u32, amt u32, p_buf voidptr) int {
	c2v_gc_register_thread()
	if int(p_cur.eState) == 0 {
		return access_payload(p_cur, offset, amt, &u8(p_buf), 0)
	} else {
		return access_payload_checked(p_cur, offset, amt, voidptr(p_buf))
	}
}

@[c:'fetchPayload']
fn fetch_payload(p_cur &BtCursor, p_amt &u32) voidptr {
	amt := 0
	amt = int(p_cur.info.nLocal)
	if amt > int((i64((isize(p_cur.pPage.aDataEnd) - isize(p_cur.info.pPayload)) / isize(sizeof(U8))))) {
		amt = (if 0 > (int((i64((isize(p_cur.pPage.aDataEnd) - isize(p_cur.info.pPayload)) / isize(sizeof(U8)))))) {
			0
		} else {
			(int((i64((isize(p_cur.pPage.aDataEnd) - isize(p_cur.info.pPayload)) / isize(sizeof(U8))))))
		})
	}
	unsafe { *p_amt = u32(amt) }
	return voidptr(p_cur.info.pPayload)
}

@[c:'sqlite3BtreePayloadFetch']
fn sqlite3_btree_payload_fetch(p_cur &BtCursor, p_amt &u32) voidptr {
	return fetch_payload(p_cur, p_amt)
}

@[c:'moveToChild']
fn move_to_child(p_cur &BtCursor, new_pgno u32) int {
	rc := 0
	if int(p_cur.iPage) >= (20 - 1) {
		return sqlite3_corrupt_error(5461)
	}
	p_cur.info.nSize = U16(0)
	p_cur.curFlags &= ~(2 | 4)
	p_cur.aiIdx[p_cur.iPage] = p_cur.ix
	p_cur.apPage[p_cur.iPage] = p_cur.pPage
	p_cur.ix = U16(0)
	p_cur.iPage++
	rc = get_and_init_page(p_cur.pBt, new_pgno, &&MemPage(&p_cur.pPage), int(p_cur.curPagerFlags))
	if rc == 0 && (int(p_cur.pPage.nCell) < 1 || int(p_cur.pPage.intKey) != int(p_cur.curIntKey)) {
		release_page(p_cur.pPage)
		rc = sqlite3_corrupt_error(5475)
	}
	if rc {
		p_cur.pPage = p_cur.apPage[c2v_prefix_add(unsafe { &p_cur.iPage }, i8(-1))]
	}
	return rc
}

@[c:'moveToParent']
fn move_to_parent(p_cur &BtCursor) {
	p_leaf := &MemPage(0)
	0
	0
	p_cur.info.nSize = U16(0)
	p_cur.curFlags &= ~(2 | 4)
	p_cur.ix = p_cur.aiIdx[int(p_cur.iPage) - 1]
	p_leaf = p_cur.pPage
	p_cur.pPage = p_cur.apPage[c2v_prefix_add(unsafe { &p_cur.iPage }, i8(-1))]
	release_page_not_null(p_leaf)
}

@[c:'moveToRoot']
fn move_to_root(p_cur &BtCursor) int {
	p_root := &MemPage(0)
	rc := 0
	if int(p_cur.iPage) >= 0 {
		if p_cur.iPage {
			release_page_not_null(p_cur.pPage)
			for {
				p_cur.iPage--
				if !(p_cur.iPage) {
					break
				}
				release_page_not_null(p_cur.apPage[p_cur.iPage])
			}
			p_cur.pPage = p_cur.apPage[0]
			p_root = p_cur.pPage
			unsafe { goto skip_init
			 }
		}
	} else if p_cur.pgnoRoot == Pgno(0) {
		p_cur.eState = U8(1)
		return 16
	} else {
		if int(p_cur.eState) >= 3 {
			if int(p_cur.eState) == 4 {
				return p_cur.skipNext
			}
			sqlite3_btree_clear_cursor(p_cur)
		}
		rc = get_and_init_page(p_cur.pBt, p_cur.pgnoRoot, &&MemPage(&p_cur.pPage), int(p_cur.curPagerFlags))
		if rc != 0 {
			p_cur.eState = U8(1)
			return rc
		}
		p_cur.iPage = I8(0)
		p_cur.curIntKey = p_cur.pPage.intKey
	}
	p_root = p_cur.pPage
	if int(p_root.isInit) == 0 || (usize(p_cur.pKeyInfo) == usize(0)) != int(p_root.intKey) {
		return sqlite3_corrupt_error(5610)
	}
	skip_init:
	p_cur.ix = U16(0)
	p_cur.info.nSize = U16(0)
	p_cur.curFlags &= ~(8 | 2 | 4)
	if int(p_root.nCell) > 0 {
		p_cur.eState = U8(0)
	} else if !p_root.leaf {
		subpage := Pgno(0)
		if p_root.pgno != Pgno(1) {
			return sqlite3_corrupt_error(5622)
		}
		subpage = sqlite3_get4byte(unsafe { p_root.aData + (int(p_root.hdrOffset) + 8) })
		p_cur.eState = U8(0)
		rc = move_to_child(p_cur, subpage)
	} else {
		p_cur.eState = U8(1)
		rc = 16
	}
	return rc
}

@[c:'moveToLeftmost']
fn move_to_leftmost(p_cur &BtCursor) int {
	pgno := Pgno(0)
	rc := 0
	p_page := &MemPage(0)
	for {
		if !(rc == 0 && !c2v_assign[&MemPage](unsafe { &p_page }, p_cur.pPage).leaf) {
			break
		}
		pgno = sqlite3_get4byte((p_page.aData + (int(p_page.maskPage) & (int((unsafe { p_page.aCellIdx + (2 * int(p_cur.ix)) })[0]) << 8 | int((unsafe { p_page.aCellIdx + (2 * int(p_cur.ix)) })[1])))))
		rc = move_to_child(p_cur, pgno)
	}
	return rc
}

@[c:'moveToRightmost']
fn move_to_rightmost(p_cur &BtCursor) int {
	pgno := Pgno(0)
	rc := 0
	p_page := unsafe { &MemPage(nil) }
	for {
		p_page = p_cur.pPage
		if !(!p_page.leaf) {
			break
		}
		pgno = sqlite3_get4byte(unsafe { p_page.aData + (int(p_page.hdrOffset) + 8) })
		p_cur.ix = p_page.nCell
		rc = move_to_child(p_cur, pgno)
		if rc {
			return rc
		}
	}
	p_cur.ix = U16(int(p_page.nCell) - 1)
	return 0
}

@[c:'sqlite3BtreeFirst']
fn sqlite3_btree_first(p_cur &BtCursor, p_res &int) int {
	rc := 0
	rc = move_to_root(p_cur)
	if rc == 0 {
		unsafe { *p_res = 0 }
		rc = move_to_leftmost(p_cur)
	} else if rc == 16 {
		unsafe { *p_res = 1 }
		rc = 0
	}
	return rc
}

@[c:'sqlite3BtreeIsEmpty']
fn sqlite3_btree_is_empty(p_cur &BtCursor, p_res &int) int {
	rc := 0
	if (int(p_cur.eState) == 0) {
		unsafe { *p_res = 0 }
		return 0
	}
	rc = move_to_root(p_cur)
	if rc == 16 {
		unsafe { *p_res = 1 }
		rc = 0
	} else {
		unsafe { *p_res = 0 }
	}
	return rc
}

@[c:'btreeLast']
fn btree_last(p_cur &BtCursor, p_res &int) int {
	rc := move_to_root(p_cur)
	if rc == 0 {
		unsafe { *p_res = 0 }
		rc = move_to_rightmost(p_cur)
		if rc == 0 {
			p_cur.curFlags |= 8
		} else {
			p_cur.curFlags &= ~8
		}
	} else if rc == 16 {
		unsafe { *p_res = 1 }
		rc = 0
	}
	return rc
}

@[c:'sqlite3BtreeLast']
fn sqlite3_btree_last(p_cur &BtCursor, p_res &int) int {
	if 0 == int(p_cur.eState) && (int(p_cur.curFlags) & 8) != 0 {
		unsafe { *p_res = 0 }
		return 0
	}
	return btree_last(p_cur, p_res)
}

@[c:'sqlite3BtreeTableMoveto']
fn sqlite3_btree_table_moveto(p_cur &BtCursor, int_key I64, bias_right int, p_res &int) int {
	rc := 0
	if int(p_cur.eState) == 0 && (int(p_cur.curFlags) & 2) != 0 {
		if p_cur.info.nKey == int_key {
			unsafe { *p_res = 0 }
			return 0
		}
		if p_cur.info.nKey < int_key {
			if (int(p_cur.curFlags) & 8) != 0 {
				unsafe { *p_res = -1 }
				return 0
			}
			if p_cur.info.nKey + I64(1) == int_key {
				unsafe { *p_res = 0 }
				rc = sqlite3_btree_next(p_cur, 0)
				if rc == 0 {
					get_cell_info(p_cur)
					if p_cur.info.nKey == int_key {
						return 0
					}
				} else if rc != 101 {
					return rc
				}
			}
		}
	}
	rc = move_to_root(p_cur)
	if rc {
		if rc == 16 {
			unsafe { *p_res = -1 }
			return 0
		}
		return rc
	}
	for {
		lwr := 0
		upr := 0
		idx := 0
		c := 0

		chld_pg := Pgno(0)
		p_page := p_cur.pPage
		p_cell := &U8(0)
		lwr = 0
		upr = int(p_page.nCell) - 1
		idx = upr >> (1 - bias_right)
		for {
			n_cell_key := I64(0)
			p_cell = (p_page.aDataOfst + (int(p_page.maskPage) & (int((unsafe { p_page.aCellIdx + (2 * idx) })[0]) << 8 | int((unsafe { p_page.aCellIdx + (2 * idx) })[1]))))
			if p_page.intKeyLeaf {
				for 128 <= int((unsafe { *(c2v_pointer_postfix(voidptr(&p_cell), p_cell, isize(1))) })) {
					if usize(p_cell) >= usize(p_page.aDataEnd) {
						return sqlite3_corrupt_error(5895)
					}
				}
			}
			sqlite3_get_varint(p_cell, &U64(c2v_address_of(&n_cell_key)))
			if n_cell_key < int_key {
				lwr = idx + 1
				if lwr > upr {
					c = -1
					break
				}
			} else if n_cell_key > int_key {
				upr = idx - 1
				if lwr > upr {
					c = 1
					break
				}
			} else {
				p_cur.ix = U16(idx)
				if !p_page.leaf {
					lwr = idx
					unsafe { goto moveto_table_next_layer
					 }
				} else {
					p_cur.curFlags |= 2
					p_cur.info.nKey = n_cell_key
					p_cur.info.nSize = U16(0)
					unsafe { *p_res = 0 }
					return 0
				}
			}
			idx = (lwr + upr) >> 1
		}
		if p_page.leaf {
			p_cur.ix = U16(idx)
			unsafe { *p_res = c }
			rc = 0
			unsafe { goto moveto_table_finish
			 }
		}
		moveto_table_next_layer:
		if lwr >= int(p_page.nCell) {
			chld_pg = sqlite3_get4byte(unsafe { p_page.aData + (int(p_page.hdrOffset) + 8) })
		} else {
			chld_pg = sqlite3_get4byte((p_page.aData + (int(p_page.maskPage) & (int((unsafe { p_page.aCellIdx + (2 * lwr) })[0]) << 8 | int((unsafe { p_page.aCellIdx + (2 * lwr) })[1])))))
		}
		p_cur.ix = U16(lwr)
		rc = move_to_child(p_cur, chld_pg)
		if rc {
			break
		}
	}
	moveto_table_finish:
	p_cur.info.nSize = U16(0)
	return rc
}

@[c:'indexCellCompare']
fn index_cell_compare(p_page &MemPage, idx int, p_idx_key &UnpackedRecord, x_record_compare RecordCompare) int {
	c := 0
	n_cell := 0
	p_cell := (p_page.aDataOfst + (int(p_page.maskPage) & (int((unsafe { p_page.aCellIdx + (2 * idx) })[0]) << 8 | int((unsafe { p_page.aCellIdx + (2 * idx) })[1]))))
	n_cell = int(p_cell[0])
	if n_cell <= int(p_page.max1bytePayload) {
		if usize(p_cell + n_cell) >= usize(p_page.aDataEnd) {
			return 99
		}
		c = x_record_compare(n_cell, voidptr(unsafe { p_cell + 1 }), p_idx_key)
	} else {
		if !(int(p_cell[1]) & 128) && c2v_assign[int](unsafe { &n_cell }, int(((n_cell & 127) << 7) + int(p_cell[1]))) <= int(p_page.maxLocal) {
			if usize(p_cell + n_cell) >= usize(p_page.aDataEnd) {
				return 99
			}
			c = x_record_compare(n_cell, voidptr(unsafe { p_cell + 2 }), p_idx_key)
		} else {
			c = 99
		}
	}
	return c
}

@[c:'cursorOnLastPage']
fn cursor_on_last_page(p_cur &BtCursor) int {
	i := 0
	for i = 0; i < int(p_cur.iPage); i++ {
		p_page := p_cur.apPage[i]
		if int(p_cur.aiIdx[i]) < int(p_page.nCell) {
			return 0
		}
	}
	return 1
}

@[c:'sqlite3BtreeIndexMoveto']
fn sqlite3_btree_index_moveto(p_cur &BtCursor, p_idx_key &UnpackedRecord, p_res &int) int {
	rc := 0
	x_record_compare := unsafe { RecordCompare(nil) }
	x_record_compare = sqlite3_vdbe_find_compare(p_idx_key)
	p_idx_key.errCode = U8(0)
	if int(p_cur.eState) == 0 && int(p_cur.pPage.leaf) && cursor_on_last_page(p_cur) {
		c := 0
		mut __c2v_condition_34 := false
		mut __c2v_condition_35 := false
		__c2v_condition_35 = int(p_cur.ix) == int(p_cur.pPage.nCell) - 1
		if __c2v_condition_35 {
			__c2v_condition_35 = c2v_assign[int](unsafe { &c }, int(index_cell_compare(p_cur.pPage, int(p_cur.ix), p_idx_key, x_record_compare))) <= 0
		}
		if __c2v_condition_35 {
			__c2v_condition_35 = int(p_idx_key.errCode) == 0
		}
		__c2v_condition_34 = __c2v_condition_35
		if __c2v_condition_34 {
			unsafe { *p_res = c }
			return 0
		}
		if int(p_cur.iPage) > 0 && index_cell_compare(p_cur.pPage, 0, p_idx_key, x_record_compare) <= 0 && int(p_idx_key.errCode) == 0 {
			p_cur.curFlags &= ~(4 | 8)
			if !p_cur.pPage.isInit {
				return sqlite3_corrupt_error(6090)
			}
			unsafe { goto bypass_moveto_root
			 }
		}
		p_idx_key.errCode = U8(0)
	}
	rc = move_to_root(p_cur)
	if rc {
		if rc == 16 {
			unsafe { *p_res = -1 }
			return 0
		}
		return rc
	}
	bypass_moveto_root: for {
		lwr := 0
		upr := 0
		idx := 0
		c := 0

		chld_pg := Pgno(0)
		p_page := p_cur.pPage
		p_cell := &U8(0)
		lwr = 0
		upr = int(p_page.nCell) - 1
		idx = upr >> 1
		for {
			n_cell := 0
			p_cell = (p_page.aDataOfst + (int(p_page.maskPage) & (int((unsafe { p_page.aCellIdx + (2 * idx) })[0]) << 8 | int((unsafe { p_page.aCellIdx + (2 * idx) })[1]))))
			n_cell = int(p_cell[0])
			if n_cell <= int(p_page.max1bytePayload) {
				if usize(p_cell + n_cell) >= usize(p_page.aDataEnd) {
					rc = sqlite3_corrupt_error(6149)
					unsafe { goto moveto_index_finish
					 }
				}
				c = x_record_compare(n_cell, voidptr(unsafe { p_cell + 1 }), p_idx_key)
			} else {
				if !(int(p_cell[1]) & 128) && c2v_assign[int](unsafe { &n_cell }, int(((n_cell & 127) << 7) + int(p_cell[1]))) <= int(p_page.maxLocal) && usize(p_cell + n_cell) < usize(p_page.aDataEnd) {
					c = x_record_compare(n_cell, voidptr(unsafe { p_cell + 2 }), p_idx_key)
				} else {
					p_cell_key := &voidptr(0)
					p_cell_body := p_cell - int(p_page.childPtrSize)
					n_overrun := 18
					p_page.xParseCell(p_page, p_cell_body, &p_cur.info)
					n_cell = int(p_cur.info.nKey)
					0
					0
					0
					0
					if n_cell < 2 || u32(n_cell) / p_cur.pBt.usableSize > p_cur.pBt.nPage {
						rc = sqlite3_corrupt_error(6180)
						unsafe { goto moveto_index_finish
						 }
					}
					p_cell_key = sqlite3_malloc_vdup2(U64(n_cell) + U64(n_overrun))
					if usize(p_cell_key) == usize(0) {
						rc = 7
						unsafe { goto moveto_index_finish
						 }
					}
					p_cur.ix = U16(idx)
					rc = access_payload(p_cur, u32(0), u32(n_cell), &u8(p_cell_key), 0)
					C.memset(voidptr((&U8(p_cell_key)) + n_cell), 0, u64(n_overrun))
					p_cur.curFlags &= ~4
					if rc {
						sqlite3_free(voidptr(p_cell_key))
						unsafe { goto moveto_index_finish
						 }
					}
					c = sqlite3_vdbe_record_compare(n_cell, voidptr(p_cell_key), p_idx_key)
					sqlite3_free(voidptr(p_cell_key))
				}
			}
			if c < 0 {
				lwr = idx + 1
			} else if c > 0 {
				upr = idx - 1
			} else {
				unsafe { *p_res = 0 }
				rc = 0
				p_cur.ix = U16(idx)
				if p_idx_key.errCode {
					rc = sqlite3_corrupt_error(6212)
				}
				unsafe { goto moveto_index_finish
				 }
			}
			if lwr > upr {
				break
			}
			idx = (lwr + upr) >> 1
		}
		if p_page.leaf {
			p_cur.ix = U16(idx)
			unsafe { *p_res = c }
			rc = 0
			unsafe { goto moveto_index_finish
			 }
		}
		if lwr >= int(p_page.nCell) {
			chld_pg = sqlite3_get4byte(unsafe { p_page.aData + (int(p_page.hdrOffset) + 8) })
		} else {
			chld_pg = sqlite3_get4byte((p_page.aData + (int(p_page.maskPage) & (int((unsafe { p_page.aCellIdx + (2 * lwr) })[0]) << 8 | int((unsafe { p_page.aCellIdx + (2 * lwr) })[1])))))
		}
		p_cur.info.nSize = U16(0)
		p_cur.curFlags &= ~(2 | 4)
		if int(p_cur.iPage) >= (20 - 1) {
			return sqlite3_corrupt_error(6243)
		}
		p_cur.aiIdx[p_cur.iPage] = U16(lwr)
		p_cur.apPage[p_cur.iPage] = p_cur.pPage
		p_cur.ix = U16(0)
		p_cur.iPage++
		rc = get_and_init_page(p_cur.pBt, chld_pg, &&MemPage(&p_cur.pPage), int(p_cur.curPagerFlags))
		if rc == 0 && (int(p_cur.pPage.nCell) < 1 || int(p_cur.pPage.intKey) != int(p_cur.curIntKey)) {
			release_page(p_cur.pPage)
			rc = sqlite3_corrupt_error(6254)
		}
		if rc {
			p_cur.pPage = p_cur.apPage[c2v_prefix_add(unsafe { &p_cur.iPage }, i8(-1))]
			break
		}
	}
	moveto_index_finish:
	p_cur.info.nSize = U16(0)
	return rc
}

@[c:'sqlite3BtreeEof']
fn sqlite3_btree_eof(p_cur &BtCursor) int {
	return int((0 != int(p_cur.eState)))
}

@[c:'sqlite3BtreeRowCountEst']
fn sqlite3_btree_row_count_est(p_cur &BtCursor) I64 {
	n := I64(0)
	i := U8(0)
	if int(p_cur.eState) != 0 {
		return I64(0)
	}
	if (int(p_cur.pPage.leaf) == 0) {
		return I64(-1)
	}
	n = I64(p_cur.pPage.nCell)
	for i = U8(0); int(i) < int(p_cur.iPage); i++ {
		n *= I64(int(p_cur.apPage[i].nCell) + 1)
	}
	return n
}

@[c:'btreeNext']
fn btree_next(p_cur &BtCursor) int {
	rc := 0
	idx := 0
	p_page := &MemPage(0)
	if int(p_cur.eState) != 0 {
		rc = (if int(p_cur.eState) >= 3 { btree_restore_cursor_position(p_cur) } else { 0 })
		if rc != 0 {
			return rc
		}
		if 1 == int(p_cur.eState) {
			return 101
		}
		if int(p_cur.eState) == 2 {
			p_cur.eState = U8(0)
			if p_cur.skipNext > 0 {
				return 0
			}
		}
	}
	p_page = p_cur.pPage
	idx = int(c2v_prefix_add(unsafe { &p_cur.ix }, u16(1)))
	if sqlite3_fault_sim(412) {
		p_page.isInit = U8(0)
	}
	if !p_page.isInit {
		return sqlite3_corrupt_error(6355)
	}
	if idx >= int(p_page.nCell) {
		if !p_page.leaf {
			rc = move_to_child(p_cur, sqlite3_get4byte(unsafe { p_page.aData + (int(p_page.hdrOffset) + 8) }))
			if rc {
				return rc
			}
			return move_to_leftmost(p_cur)
		}
		for {
			if int(p_cur.iPage) == 0 {
				p_cur.eState = U8(1)
				return 101
			}
			move_to_parent(p_cur)
			p_page = p_cur.pPage
			if !(int(p_cur.ix) >= int(p_page.nCell)) {
				break
			}
		}
		if p_page.intKey {
			return sqlite3_btree_next(p_cur, 0)
		} else {
			return 0
		}
	}
	if p_page.leaf {
		return 0
	} else {
		return move_to_leftmost(p_cur)
	}
}

@[c:'sqlite3BtreeNext']
fn sqlite3_btree_next(p_cur &BtCursor, flags int) int {
	p_page := &MemPage(0)

	p_cur.info.nSize = U16(0)
	p_cur.curFlags &= ~(2 | 4)
	if int(p_cur.eState) != 0 {
		return btree_next(p_cur)
	}
	p_page = p_cur.pPage
	p_cur.ix++
	if int((p_cur.ix)) >= int(p_page.nCell) {
		p_cur.ix--
		return btree_next(p_cur)
	}
	if p_page.leaf {
		return 0
	} else {
		return move_to_leftmost(p_cur)
	}
}

@[c:'btreePrevious']
fn btree_previous(p_cur &BtCursor) int {
	rc := 0
	p_page := &MemPage(0)
	if int(p_cur.eState) != 0 {
		rc = (if int(p_cur.eState) >= 3 { btree_restore_cursor_position(p_cur) } else { 0 })
		if rc != 0 {
			return rc
		}
		if 1 == int(p_cur.eState) {
			return 101
		}
		if 2 == int(p_cur.eState) {
			p_cur.eState = U8(0)
			if p_cur.skipNext < 0 {
				return 0
			}
		}
	}
	p_page = p_cur.pPage
	if sqlite3_fault_sim(412) {
		p_page.isInit = U8(0)
	}
	if !p_page.isInit {
		return sqlite3_corrupt_error(6448)
	}
	if !p_page.leaf {
		idx := int(p_cur.ix)
		rc = move_to_child(p_cur, sqlite3_get4byte((p_page.aData + (int(p_page.maskPage) & (int((unsafe { p_page.aCellIdx + (2 * idx) })[0]) << 8 | int((unsafe { p_page.aCellIdx + (2 * idx) })[1]))))))
		if rc {
			return rc
		}
		rc = move_to_rightmost(p_cur)
	} else {
		for int(p_cur.ix) == 0 {
			if int(p_cur.iPage) == 0 {
				p_cur.eState = U8(1)
				return 101
			}
			move_to_parent(p_cur)
		}
		p_cur.ix--
		p_page = p_cur.pPage
		if int(p_page.intKey) && !p_page.leaf {
			rc = sqlite3_btree_previous(p_cur, 0)
		} else {
			rc = 0
		}
	}
	return rc
}

@[c:'sqlite3BtreePrevious']
fn sqlite3_btree_previous(p_cur &BtCursor, flags int) int {
	p_cur.curFlags &= ~(8 | 4 | 2)
	p_cur.info.nSize = U16(0)
	if int(p_cur.eState) != 0 || int(p_cur.ix) == 0 || int(p_cur.pPage.leaf) == 0 {
		return btree_previous(p_cur)
	}
	p_cur.ix--
	return 0
}

@[c:'allocateBtreePage']
fn allocate_btree_page(p_bt &BtShared, pp_page &&MemPage, p_pgno &Pgno, nearby Pgno, e_mode U8) int {
	p_page1 := &MemPage(0)
	rc := 0
	n := u32(0)
	k := u32(0)
	p_trunk := unsafe { &MemPage(nil) }
	p_prev_trunk := unsafe { &MemPage(nil) }
	mx_page := Pgno(0)
	p_page1 = p_bt.pPage1
	mx_page = btree_pagecount(p_bt)
	n = sqlite3_get4byte(unsafe { p_page1.aData + 36 })
	0
	if n >= mx_page {
		return sqlite3_corrupt_error(6538)
	}
	if n > u32(0) {
		i_trunk := Pgno(0)
		search_list := U8(0)
		n_search := u32(0)
		if int(e_mode) == 1 {
			if nearby <= mx_page {
				e_type := U8(0)
				rc = ptrmap_get(p_bt, nearby, &e_type, unsafe { nil })
				if rc {
					return rc
				}
				if int(e_type) == 2 {
					search_list = U8(1)
				}
			}
		} else if int(e_mode) == 2 {
			search_list = U8(1)
		}
		rc = sqlite3_pager_write(p_page1.pDbPage)
		if rc {
			return rc
		}
		sqlite3_put4byte(unsafe { p_page1.aData + 36 }, n - u32(1))
		for {
			p_prev_trunk = p_trunk
			if p_prev_trunk {
				i_trunk = sqlite3_get4byte(unsafe { p_prev_trunk.aData + 0 })
			} else {
				i_trunk = sqlite3_get4byte(unsafe { p_page1.aData + 32 })
			}
			0
			if i_trunk > mx_page || n_search++ > n {
				rc = sqlite3_corrupt_error(6594)
			} else {
				rc = btree_get_unused_page(p_bt, i_trunk, &&MemPage(&&MemPage(c2v_address_of(&p_trunk))), 0)
			}
			if rc {
				p_trunk = 0
				unsafe { goto end_allocate_page
				 }
			}
			k = sqlite3_get4byte(unsafe { p_trunk.aData + 4 })
			if k == u32(0) && !search_list {
				rc = sqlite3_pager_write(p_trunk.pDbPage)
				if rc {
					unsafe { goto end_allocate_page
					 }
				}
				unsafe { *p_pgno = i_trunk }
				C.memcpy(voidptr(unsafe { p_page1.aData + 32 }), voidptr(unsafe { p_trunk.aData + 0 }), u64(4))
				unsafe { *pp_page = p_trunk }
				p_trunk = 0
				0
			} else if k > u32((p_bt.usableSize / u32(4) - u32(2))) {
				rc = sqlite3_corrupt_error(6623)
				unsafe { goto end_allocate_page
				 }
			} else if int(search_list) && (nearby == i_trunk || (i_trunk < nearby && int(e_mode) == 2)) {
				unsafe { *p_pgno = i_trunk }
				unsafe { *pp_page = p_trunk }
				search_list = U8(0)
				rc = sqlite3_pager_write(p_trunk.pDbPage)
				if rc {
					unsafe { goto end_allocate_page
					 }
				}
				if k == u32(0) {
					if isnil(p_prev_trunk) {
						C.memcpy(voidptr(unsafe { p_page1.aData + 32 }), voidptr(unsafe { p_trunk.aData + 0 }), u64(4))
					} else {
						rc = sqlite3_pager_write(p_prev_trunk.pDbPage)
						if rc != 0 {
							unsafe { goto end_allocate_page
							 }
						}
						C.memcpy(voidptr(unsafe { p_prev_trunk.aData + 0 }), voidptr(unsafe { p_trunk.aData + 0 }), u64(4))
					}
				} else {
					p_new_trunk := &MemPage(0)
					i_new_trunk := sqlite3_get4byte(unsafe { p_trunk.aData + 8 })
					if i_new_trunk > mx_page {
						rc = sqlite3_corrupt_error(6657)
						unsafe { goto end_allocate_page
						 }
					}
					0
					rc = btree_get_unused_page(p_bt, i_new_trunk, &&MemPage(&&MemPage(c2v_address_of(&p_new_trunk))), 0)
					if rc != 0 {
						unsafe { goto end_allocate_page
						 }
					}
					rc = sqlite3_pager_write(p_new_trunk.pDbPage)
					if rc != 0 {
						release_page(p_new_trunk)
						unsafe { goto end_allocate_page
						 }
					}
					C.memcpy(voidptr(unsafe { p_new_trunk.aData + 0 }), voidptr(unsafe { p_trunk.aData + 0 }), u64(4))
					sqlite3_put4byte(unsafe { p_new_trunk.aData + 4 }, k - u32(1))
					C.memcpy(voidptr(unsafe { p_new_trunk.aData + 8 }), voidptr(unsafe { p_trunk.aData + 12 }), u64((k - u32(1)) * u32(4)))
					release_page(p_new_trunk)
					if isnil(p_prev_trunk) {
						sqlite3_put4byte(unsafe { p_page1.aData + 32 }, i_new_trunk)
					} else {
						rc = sqlite3_pager_write(p_prev_trunk.pDbPage)
						if rc {
							unsafe { goto end_allocate_page
							 }
						}
						sqlite3_put4byte(unsafe { p_prev_trunk.aData + 0 }, i_new_trunk)
					}
				}
				p_trunk = 0
				0
			} else if k > u32(0) {
				closest := u32(0)
				i_page := Pgno(0)
				a_data := p_trunk.aData
				if nearby > Pgno(0) {
					i := u32(0)
					closest = u32(0)
					if int(e_mode) == 2 {
						for i = u32(0); i < k; i++ {
							i_page = sqlite3_get4byte(unsafe { a_data + (u32(8) + i * u32(4)) })
							if i_page <= nearby {
								closest = i
								break
							}
						}
					} else {
						dist := 0
						dist = sqlite3_abs_int32(int(sqlite3_get4byte(unsafe { a_data + 8 }) - nearby))
						for i = u32(1); i < k; i++ {
							d2 := sqlite3_abs_int32(int(sqlite3_get4byte(unsafe { a_data + (u32(8) + i * u32(4)) }) - nearby))
							if d2 < dist {
								closest = i
								dist = d2
							}
						}
					}
				} else {
					closest = u32(0)
				}
				i_page = sqlite3_get4byte(unsafe { a_data + (u32(8) + closest * u32(4)) })
				0
				if i_page > mx_page || i_page < Pgno(2) {
					rc = sqlite3_corrupt_error(6722)
					unsafe { goto end_allocate_page
					 }
				}
				0
				if !search_list || (i_page == nearby || (i_page < nearby && int(e_mode) == 2)) {
					no_content := 0
					unsafe { *p_pgno = i_page }
					0
					rc = sqlite3_pager_write(p_trunk.pDbPage)
					if rc {
						unsafe { goto end_allocate_page
						 }
					}
					if closest < k - u32(1) {
						C.memcpy(voidptr(unsafe { a_data + (u32(8) + closest * u32(4)) }), voidptr(unsafe { a_data + (u32(4) + k * u32(4)) }), u64(4))
					}
					sqlite3_put4byte(unsafe { &U8(a_data + 4) }, k - u32(1))
					no_content = if !btree_get_has_content(p_bt, (unsafe { *p_pgno })) {
						1
					} else {
						0
					}
					rc = btree_get_unused_page(p_bt, (unsafe { *p_pgno }), pp_page, no_content)
					if rc == 0 {
						rc = sqlite3_pager_write((unsafe { *pp_page }).pDbPage)
						if rc != 0 {
							release_page((unsafe { *pp_page }))
							unsafe { *pp_page = 0 }
						}
					}
					search_list = U8(0)
				}
			}
			release_page(p_prev_trunk)
			p_prev_trunk = 0
			if !search_list {
				break
			}
		}
	} else {
		b_no_content := if (0 == int(p_bt.bDoTruncate)) { 1 } else { 0 }
		rc = sqlite3_pager_write(p_bt.pPage1.pDbPage)
		if rc {
			return rc
		}
		p_bt.nPage++
		if p_bt.nPage == (Pgno(((u32(sqlite3PendingByte) / p_bt.pageSize) + u32(1)))) {
			p_bt.nPage++
		}
		if int(p_bt.autoVacuum) && (ptrmap_pageno(p_bt, p_bt.nPage) == p_bt.nPage) {
			p_pg := unsafe { &MemPage(nil) }
			0
			rc = btree_get_unused_page(p_bt, p_bt.nPage, &&MemPage(&&MemPage(c2v_address_of(&p_pg))), b_no_content)
			if rc == 0 {
				rc = sqlite3_pager_write(p_pg.pDbPage)
				release_page(p_pg)
			}
			if rc {
				return rc
			}
			p_bt.nPage++
			if p_bt.nPage == (Pgno(((u32(sqlite3PendingByte) / p_bt.pageSize) + u32(1)))) {
				p_bt.nPage++
			}
		}
		sqlite3_put4byte(unsafe { &U8(p_bt.pPage1.aData) + (28) }, p_bt.nPage)
		unsafe { *p_pgno = p_bt.nPage }
		rc = btree_get_unused_page(p_bt, (unsafe { *p_pgno }), pp_page, b_no_content)
		if rc {
			return rc
		}
		rc = sqlite3_pager_write((unsafe { *pp_page }).pDbPage)
		if rc != 0 {
			release_page((unsafe { *pp_page }))
			unsafe { *pp_page = 0 }
		}
		0
	}
	end_allocate_page:
	release_page(p_trunk)
	release_page(p_prev_trunk)
	return rc
}

@[c:'freePage2']
fn free_page2(p_bt &BtShared, p_mem_page &MemPage, i_page Pgno) int {
	p_trunk := unsafe { &MemPage(nil) }
	i_trunk := Pgno(0)
	p_page1 := p_bt.pPage1
	p_page := &MemPage(0)
	rc := 0
	n_free := u32(0)
	if i_page < Pgno(2) || i_page > p_bt.nPage {
		return sqlite3_corrupt_error(6849)
	}
	if p_mem_page {
		p_page = p_mem_page
		sqlite3_pager_ref(p_page.pDbPage)
	} else {
		p_page = btree_page_lookup(p_bt, i_page)
	}
	rc = sqlite3_pager_write(p_page1.pDbPage)
	if rc {
		unsafe { goto freepage_out
		 }
	}
	n_free = sqlite3_get4byte(unsafe { p_page1.aData + 36 })
	sqlite3_put4byte(unsafe { p_page1.aData + 36 }, n_free + u32(1))
	if int(p_bt.btsFlags) & 4 {
		mut __c2v_condition_36 := false
		mut __c2v_condition_37 := false
		__c2v_condition_37 = (isnil(p_page) && (c2v_assign[int](unsafe { &rc }, int(btree_get_page(p_bt, i_page, &&MemPage(&&MemPage(c2v_address_of(&p_page))), 0))) != 0))
		__c2v_condition_36 = __c2v_condition_37
		if !__c2v_condition_36 {
			mut __c2v_condition_38 := false
			__c2v_condition_38 = (c2v_assign[int](unsafe { &rc }, int(sqlite3_pager_write(p_page.pDbPage))) != 0)
			__c2v_condition_36 = __c2v_condition_38
		}
		if __c2v_condition_36 {
			unsafe { goto freepage_out
			 }
		}
		C.memset(voidptr(p_page.aData), 0, u64(p_page.pBt.pageSize))
	}
	if p_bt.autoVacuum {
		ptrmap_put(p_bt, i_page, U8(2), Pgno(0), &rc)
		if rc {
			unsafe { goto freepage_out
			 }
		}
	}
	if n_free != u32(0) {
		n_leaf := u32(0)
		i_trunk = sqlite3_get4byte(unsafe { p_page1.aData + 32 })
		if i_trunk > btree_pagecount(p_bt) {
			rc = sqlite3_corrupt_error(6896)
			unsafe { goto freepage_out
			 }
		}
		rc = btree_get_page(p_bt, i_trunk, &&MemPage(&&MemPage(c2v_address_of(&p_trunk))), 0)
		if rc != 0 {
			unsafe { goto freepage_out
			 }
		}
		n_leaf = sqlite3_get4byte(unsafe { p_trunk.aData + 4 })
		if n_leaf > u32(p_bt.usableSize) / u32(4) - u32(2) {
			rc = sqlite3_corrupt_error(6907)
			unsafe { goto freepage_out
			 }
		}
		if n_leaf < u32(p_bt.usableSize) / u32(4) - u32(8) {
			rc = sqlite3_pager_write(p_trunk.pDbPage)
			if rc == 0 {
				sqlite3_put4byte(unsafe { p_trunk.aData + 4 }, n_leaf + u32(1))
				sqlite3_put4byte(unsafe { p_trunk.aData + (u32(8) + n_leaf * u32(4)) }, i_page)
				if !isnil(p_page) && (int(p_bt.btsFlags) & 4) == 0 {
					sqlite3_pager_dont_write(p_page.pDbPage)
				}
				rc = btree_set_has_content(p_bt, i_page)
			}
			0
			unsafe { goto freepage_out
			 }
		}
	}
	if usize(p_page) == usize(0) && 0 != c2v_assign[int](unsafe { &rc }, int(btree_get_page(p_bt, i_page, &&MemPage(&&MemPage(c2v_address_of(&p_page))), 0))) {
		unsafe { goto freepage_out
		 }
	}
	rc = sqlite3_pager_write(p_page.pDbPage)
	if rc != 0 {
		unsafe { goto freepage_out
		 }
	}
	sqlite3_put4byte(p_page.aData, i_trunk)
	sqlite3_put4byte(unsafe { p_page.aData + 4 }, u32(0))
	sqlite3_put4byte(unsafe { p_page1.aData + 32 }, i_page)
	0
	freepage_out:
	if p_page {
		p_page.isInit = U8(0)
	}
	release_page(p_page)
	release_page(p_trunk)
	return rc
}

@[c:'freePage']
fn free_page(p_page &MemPage, prc &int) {
	if (unsafe { *prc }) == 0 {
		unsafe { *prc = free_page2(p_page.pBt, p_page, p_page.pgno) }
	}
}

@[c:'clearCellOverflow']
fn clear_cell_overflow(p_page &MemPage, p_cell &u8, p_info &CellInfo) int {
	p_bt := &BtShared(0)
	ovfl_pgno := Pgno(0)
	rc := 0
	n_ovfl := 0
	ovfl_page_size := u32(0)
	0
	0
	if usize(p_cell + p_info.nSize) > usize(p_page.aDataEnd) {
		return sqlite3_corrupt_error(6996)
	}
	ovfl_pgno = sqlite3_get4byte(p_cell + int(p_info.nSize) - 4)
	p_bt = p_page.pBt
	ovfl_page_size = p_bt.usableSize - u32(4)
	n_ovfl = int((p_info.nPayload - u32(p_info.nLocal) + ovfl_page_size - u32(1)) / ovfl_page_size)
	for n_ovfl-- {
		i_next := Pgno(0)
		p_ovfl := unsafe { &MemPage(nil) }
		if ovfl_pgno < Pgno(2) || ovfl_pgno > btree_pagecount(p_bt) {
			return sqlite3_corrupt_error(7013)
		}
		if n_ovfl {
			rc = get_overflow_page(p_bt, ovfl_pgno, &&MemPage(&&MemPage(c2v_address_of(&p_ovfl))), &i_next)
			if rc {
				return rc
			}
		}
		if (!isnil(p_ovfl) || (usize(c2v_assign[&MemPage](unsafe { &p_ovfl }, btree_page_lookup(p_bt, ovfl_pgno))) != usize(0))) && sqlite3_pager_page_refcount(p_ovfl.pDbPage) != 1 {
			rc = sqlite3_corrupt_error(7033)
		} else {
			rc = free_page2(p_bt, p_ovfl, ovfl_pgno)
		}
		if p_ovfl {
			sqlite3_pager_unref(p_ovfl.pDbPage)
		}
		if rc {
			return rc
		}
		ovfl_pgno = i_next
	}
	return 0
}

@[c:'fillInCell']
fn fill_in_cell(p_page &MemPage, p_cell &u8, px &BtreePayload, pn_size &int) int {
	n_payload := 0
	p_src := &U8(0)
	n_src := 0
	n := 0
	rc := 0
	mn := 0

	space_left := 0
	p_to_release := &MemPage(0)
	p_prior := &u8(0)
	p_payload := &u8(0)
	p_bt := &BtShared(0)
	pgno_ovfl := Pgno(0)
	n_header := 0
	n_header = int(p_page.childPtrSize)
	if p_page.intKey {
		n_payload = px.nData + px.nZero
		p_src = px.pData
		n_src = px.nData
		n_header += int(U8((if (u32(n_payload) < u32(128)) {
			(if true {
				mut __c2v_lhs_tmp_76 := unsafe { p_cell + n_header }
				unsafe { *__c2v_lhs_tmp_76 = u8(n_payload) }
				1
			} else {
				0
			})
		} else {
			sqlite3_put_varint((unsafe { p_cell + n_header }), U64(n_payload))
		})))
		n_header += sqlite3_put_varint(unsafe { p_cell + n_header }, (unsafe { *&U64(voidptr(&px.nKey)) }))
	} else {
		n_payload = int(px.nKey)
		n_src = n_payload
		p_src = px.pKey
		n_header += int(U8((if (u32(n_payload) < u32(128)) {
			(if true {
				mut __c2v_lhs_tmp_77 := unsafe { p_cell + n_header }
				unsafe { *__c2v_lhs_tmp_77 = u8(n_payload) }
				1
			} else {
				0
			})
		} else {
			sqlite3_put_varint((unsafe { p_cell + n_header }), U64(n_payload))
		})))
	}
	p_payload = unsafe { p_cell + n_header }
	if n_payload <= int(p_page.maxLocal) {
		n = n_header + n_payload
		0
		0
		if n < 4 {
			n = 4
			p_payload[n_payload] = u8(0)
		}
		unsafe { *pn_size = n }
		0
		C.memcpy(voidptr(p_payload), voidptr(p_src), u64(n_src))
		C.memset(voidptr(p_payload + n_src), 0, u64(n_payload - n_src))
		return 0
	}
	mn = int(p_page.minLocal)
	n = int(u32(mn) + u32((n_payload - mn)) % (p_page.pBt.usableSize - u32(4)))
	0
	0
	if n > int(p_page.maxLocal) {
		n = mn
	}
	space_left = n
	unsafe { *pn_size = n + n_header + 4 }
	p_prior = unsafe { p_cell + (n_header + n) }
	p_to_release = 0
	pgno_ovfl = Pgno(0)
	p_bt = p_page.pBt
	for {
		n = n_payload
		if n > space_left {
			n = space_left
		}
		if n_src >= n {
			C.memcpy(voidptr(p_payload), voidptr(p_src), u64(n))
		} else if n_src > 0 {
			n = n_src
			C.memcpy(voidptr(p_payload), voidptr(p_src), u64(n))
		} else {
			C.memset(voidptr(p_payload), 0, u64(n))
		}
		n_payload -= n
		if n_payload <= 0 {
			break
		}
		c2v_pointer_prefix(voidptr(&p_payload), p_payload, isize(n))
		c2v_pointer_prefix(voidptr(&p_src), p_src, isize(n))
		n_src -= n
		space_left -= n
		if space_left == 0 {
			p_ovfl := unsafe { &MemPage(nil) }
			pgno_ptrmap := pgno_ovfl
			if p_bt.autoVacuum {
				for {
					pgno_ovfl++
					if !((ptrmap_pageno(p_bt, pgno_ovfl) == pgno_ovfl) || pgno_ovfl == (Pgno(((u32(sqlite3PendingByte) / p_bt.pageSize) + u32(1))))) {
						break
					}
				}
			}
			rc = allocate_btree_page(p_bt, &&MemPage(&&MemPage(c2v_address_of(&p_ovfl))), &pgno_ovfl, pgno_ovfl, U8(0))
			if int(p_bt.autoVacuum) && rc == 0 {
				e_type := U8((if pgno_ptrmap { 4 } else { 3 }))
				ptrmap_put(p_bt, pgno_ovfl, e_type, pgno_ptrmap, &rc)
				if rc {
					release_page(p_ovfl)
				}
			}
			if rc {
				release_page(p_to_release)
				return rc
			}
			sqlite3_put4byte(unsafe { &U8(p_prior) }, pgno_ovfl)
			release_page(p_to_release)
			p_to_release = p_ovfl
			p_prior = p_ovfl.aData
			sqlite3_put4byte(unsafe { &U8(p_prior) }, u32(0))
			p_payload = unsafe { p_ovfl.aData + 4 }
			space_left = int(p_bt.usableSize - u32(4))
		}
	}
	release_page(p_to_release)
	return 0
}

@[c:'dropCell']
fn drop_cell(p_page &MemPage, idx int, sz int, prc &int) {
	pc := u32(0)
	data := &U8(0)
	ptr := &U8(0)
	rc := 0
	hdr := 0
	if (unsafe { *prc }) {
		return
	}
	data = p_page.aData
	ptr = unsafe { p_page.aCellIdx + (2 * idx) }
	pc = u32((int(ptr[0]) << 8 | int(ptr[1])))
	hdr = int(p_page.hdrOffset)
	0
	0
	if pc + u32(sz) > p_page.pBt.usableSize {
		unsafe { *prc = sqlite3_corrupt_error(7289) }
		return
	}
	rc = free_space(p_page, int(pc), sz)
	if rc {
		unsafe { *prc = rc }
		return
	}
	p_page.nCell--
	if int(p_page.nCell) == 0 {
		C.memset(voidptr(unsafe { data + (hdr + 1) }), 0, u64(4))
		data[hdr + 7] = U8(0)
		(unsafe { data + (hdr + 5) })[0] = U8((p_page.pBt.usableSize >> 8))
		(unsafe { data + (hdr + 5) })[1] = U8(p_page.pBt.usableSize)
		p_page.nFree = int(p_page.pBt.usableSize - u32(p_page.hdrOffset) - u32(p_page.childPtrSize) - u32(8))
	} else {
		C.memmove(voidptr(ptr), voidptr(ptr + 2), u64(2 * (int(p_page.nCell) - idx)))
		(unsafe { data + (hdr + 3) })[0] = U8((int(p_page.nCell) >> 8))
		(unsafe { data + (hdr + 3) })[1] = U8(p_page.nCell)
		p_page.nFree += 2
	}
}

@[c:'insertCell']
fn insert_cell(p_page &MemPage, i int, p_cell &U8, sz int, p_temp &U8, i_child Pgno) int {
	idx := 0
	j := 0
	data := &U8(0)
	p_ins := &U8(0)
	if int(p_page.nOverflow) || sz + 2 > p_page.nFree {
		if p_temp {
			C.memcpy(voidptr(p_temp), voidptr(p_cell), u64(sz))
			p_cell = p_temp
		}
		sqlite3_put4byte(p_cell, i_child)
		mut __c2v_postfix_value_0 := p_page.nOverflow
		p_page.nOverflow++
		j = __c2v_postfix_value_0
		p_page.apOvfl[j] = p_cell
		p_page.aiOvfl[j] = U16(i)
	} else {
		rc := sqlite3_pager_write(p_page.pDbPage)
		if (rc != 0) {
			return rc
		}
		data = p_page.aData
		rc = allocate_space(p_page, sz, &idx)
		if rc {
			return rc
		}
		p_page.nFree -= int(U16((2 + sz)))
		C.memcpy(voidptr(unsafe { data + (idx + 4) }), voidptr(p_cell + 4), u64(sz - 4))
		sqlite3_put4byte(unsafe { data + idx }, i_child)
		p_ins = p_page.aCellIdx + (i * 2)
		C.memmove(voidptr(p_ins + 2), voidptr(p_ins), u64(2 * (int(p_page.nCell) - i)))
		p_ins[0] = U8((idx >> 8))
		p_ins[1] = U8(idx)
		p_page.nCell++
		data[int(p_page.hdrOffset) + 4]++
		if int((data[int(p_page.hdrOffset) + 4])) == 0 {
			data[int(p_page.hdrOffset) + 3]++
		}
		if p_page.pBt.autoVacuum {
			rc2 := 0
			ptrmap_put_ovfl_ptr(p_page, p_page, p_cell, &rc2)
			if rc2 {
				return rc2
			}
		}
	}
	return 0
}

@[c:'insertCellFast']
fn insert_cell_fast(p_page &MemPage, i int, p_cell &U8, sz int) int {
	idx := 0
	j := 0
	data := &U8(0)
	p_ins := &U8(0)
	if sz + 2 > p_page.nFree {
		mut __c2v_postfix_value_1 := p_page.nOverflow
		p_page.nOverflow++
		j = __c2v_postfix_value_1
		p_page.apOvfl[j] = p_cell
		p_page.aiOvfl[j] = U16(i)
	} else {
		rc := sqlite3_pager_write(p_page.pDbPage)
		if rc != 0 {
			return rc
		}
		data = p_page.aData
		rc = allocate_space(p_page, sz, &idx)
		if rc {
			return rc
		}
		p_page.nFree -= int(U16((2 + sz)))
		C.memcpy(voidptr(unsafe { data + idx }), voidptr(p_cell), u64(sz))
		p_ins = p_page.aCellIdx + (i * 2)
		C.memmove(voidptr(p_ins + 2), voidptr(p_ins), u64(2 * (int(p_page.nCell) - i)))
		p_ins[0] = U8((idx >> 8))
		p_ins[1] = U8(idx)
		p_page.nCell++
		data[int(p_page.hdrOffset) + 4]++
		if int((data[int(p_page.hdrOffset) + 4])) == 0 {
			data[int(p_page.hdrOffset) + 3]++
		}
		if p_page.pBt.autoVacuum {
			rc2 := 0
			ptrmap_put_ovfl_ptr(p_page, p_page, p_cell, &rc2)
			if rc2 {
				return rc2
			}
		}
	}
	return 0
}

struct CellArray {
	nCell  int
	pRef   &MemPage
	apCell &&U8
	szCell &U16
	apEnd  [6]&U8
	ixNx   [6]int
}

@[c:'populateCellCache']
fn populate_cell_cache(p &CellArray, idx int, n int) {
	p_ref := p.pRef
	sz_cell := p.szCell
	for n > 0 {
		if int(sz_cell[idx]) == 0 {
			sz_cell[idx] = p_ref.xCellSize(p_ref, p.apCell[idx])
		} else {
		}
		idx++
		n--
	}
}

@[c:'computeCellSize']
fn compute_cell_size(p &CellArray, n int) U16 {
	p.szCell[n] = p.pRef.xCellSize(p.pRef, p.apCell[n])
	return p.szCell[n]
}

@[c:'cachedCellSize']
fn cached_cell_size(p &CellArray, n int) U16 {
	if p.szCell[n] {
		return p.szCell[n]
	}
	return compute_cell_size(p, n)
}

@[c:'rebuildPage']
fn rebuild_page(pca_rray &CellArray, i_first int, n_cell int, p_pg &MemPage) int {
	hdr := int(p_pg.hdrOffset)
	a_data := p_pg.aData
	usable_size := int(p_pg.pBt.usableSize)
	p_end := unsafe { a_data + usable_size }
	i := i_first
	j := u32(0)
	i_end := i + n_cell
	p_cellptr := p_pg.aCellIdx
	p_tmp := &U8(sqlite3_pager_temp_space(p_pg.pBt.pPager))
	p_data := &U8(0)
	k := 0
	p_src_end := &U8(0)
	j = u32((int((unsafe { a_data + (hdr + 5) })[0]) << 8 | int((unsafe { a_data + (hdr + 5) })[1])))
	if j > u32(usable_size) {
		j = u32(0)
	}
	C.memcpy(voidptr(unsafe { p_tmp + j }), voidptr(unsafe { a_data + j }), u64(u32(usable_size) - j))
	for k = 0; pca_rray.ixNx[k] <= i; k++ {
	}
	p_src_end = pca_rray.apEnd[k]
	p_data = p_end
	for {
		p_cell := pca_rray.apCell[i]
		sz := pca_rray.szCell[i]
		if ((Uptr(voidptr(p_cell)) >= Uptr(voidptr((a_data + j)))) && (Uptr(voidptr(p_cell)) < Uptr(voidptr(p_end)))) {
			if (Uptr(voidptr((p_cell + int(sz))))) > Uptr(voidptr(p_end)) {
				return sqlite3_corrupt_error(7679)
			}
			p_cell = unsafe { p_tmp + (i64((isize(p_cell) - isize(a_data)) / isize(sizeof(U8)))) }
		} else if Uptr(voidptr((p_cell + int(sz)))) > Uptr(voidptr(p_src_end)) && Uptr(voidptr(p_cell)) < Uptr(voidptr(p_src_end)) {
			return sqlite3_corrupt_error(7684)
		}
		c2v_pointer_prefix(voidptr(&p_data), p_data, isize(-(int(sz))))
		p_cellptr[0] = U8(((i64((isize(p_data) - isize(a_data)) / isize(sizeof(U8)))) >> 8))
		p_cellptr[1] = U8((i64((isize(p_data) - isize(a_data)) / isize(sizeof(U8)))))
		c2v_pointer_prefix(voidptr(&p_cellptr), p_cellptr, isize(2))
		if usize(p_data) < usize(p_cellptr) {
			return sqlite3_corrupt_error(7690)
		}
		C.memmove(voidptr(p_data), voidptr(p_cell), u64(sz))
		i++
		if i >= i_end {
			break
		}
		if pca_rray.ixNx[k] <= i {
			k++
			p_src_end = pca_rray.apEnd[k]
		}
	}
	p_pg.nCell = U16(n_cell)
	p_pg.nOverflow = U8(0)
	(unsafe { a_data + (hdr + 1) })[0] = U8((0 >> 8))
	(unsafe { a_data + (hdr + 1) })[1] = U8(0)
	(unsafe { a_data + (hdr + 3) })[0] = U8((int(p_pg.nCell) >> 8))
	(unsafe { a_data + (hdr + 3) })[1] = U8(p_pg.nCell)
	(unsafe { a_data + (hdr + 5) })[0] = U8(((i64((isize(p_data) - isize(a_data)) / isize(sizeof(U8)))) >> 8))
	(unsafe { a_data + (hdr + 5) })[1] = U8((i64((isize(p_data) - isize(a_data)) / isize(sizeof(U8)))))
	a_data[hdr + 7] = U8(0)
	return 0
}

@[c:'pageInsertArray']
fn page_insert_array(p_pg &MemPage, p_begin &U8, pp_data &&U8, p_cellptr &U8, i_first int, n_cell int, pca_rray &CellArray) int {
	i := i_first
	a_data := p_pg.aData
	p_data := (unsafe { *pp_data })
	i_end := i_first + n_cell
	k := 0
	p_end := &U8(0)
	if i_end <= i_first {
		return 0
	}
	for k = 0; pca_rray.ixNx[k] <= i; k++ {
	}
	p_end = pca_rray.apEnd[k]
	for {
		sz := 0
		rc := 0

		p_slot := &U8(0)
		sz = int(pca_rray.szCell[i])
		if (int(a_data[1]) == 0 && int(a_data[2]) == 0) || usize(c2v_assign[&U8](unsafe { &p_slot }, page_find_slot(p_pg, sz, &rc))) == usize(0) {
			if (i64((isize(p_data) - isize(p_begin)) / isize(sizeof(U8)))) < i64(sz) {
				return 1
			}
			c2v_pointer_prefix(voidptr(&p_data), p_data, isize(-sz))
			p_slot = p_data
		}
		if Uptr(voidptr((pca_rray.apCell[i] + sz))) > Uptr(voidptr(p_end)) && Uptr(voidptr(pca_rray.apCell[i])) < Uptr(voidptr(p_end)) {
			sqlite3_corrupt_error(7777)
			return 1
		}
		C.memmove(voidptr(p_slot), voidptr(pca_rray.apCell[i]), u64(sz))
		p_cellptr[0] = U8(((i64((isize(p_slot) - isize(a_data)) / isize(sizeof(U8)))) >> 8))
		p_cellptr[1] = U8((i64((isize(p_slot) - isize(a_data)) / isize(sizeof(U8)))))
		c2v_pointer_prefix(voidptr(&p_cellptr), p_cellptr, isize(2))
		i++
		if i >= i_end {
			break
		}
		if pca_rray.ixNx[k] <= i {
			k++
			p_end = pca_rray.apEnd[k]
		}
	}
	unsafe { *pp_data = p_data }
	return 0
}

@[c:'pageFreeArray']
fn page_free_array(p_pg &MemPage, i_first int, n_cell int, pca_rray &CellArray) int {
	a_data := p_pg.aData
	p_end := unsafe { a_data + p_pg.pBt.usableSize }
	p_start := unsafe { a_data + (int(p_pg.hdrOffset) + 8 + int(p_pg.childPtrSize)) }
	n_ret := 0
	i := 0
	j := 0

	i_end := i_first + n_cell
	n_free := 0
	a_ofst := [10]int{}
	a_after := [10]int{}
	for i = i_first; i < i_end; i++ {
		p_cell := pca_rray.apCell[i]
		if ((Uptr(voidptr(p_cell)) >= Uptr(voidptr(p_start))) && (Uptr(voidptr(p_cell)) < Uptr(voidptr(p_end)))) {
			sz := 0
			i_after := 0
			i_ofst := 0
			sz = int(pca_rray.szCell[i])
			i_ofst = int(U16((i64((isize(p_cell) - isize(a_data)) / isize(sizeof(U8))))))
			i_after = i_ofst + sz
			for j = 0; j < n_free; j++ {
				if a_ofst[j] == i_after {
					a_ofst[j] = i_ofst
					break
				} else if a_after[j] == i_ofst {
					a_after[j] = i_after
					break
				}
			}
			if j >= n_free {
				if n_free >= 10 {
					for j = 0; j < n_free; j++ {
						free_space(p_pg, a_ofst[j], a_after[j] - a_ofst[j])
					}
					n_free = 0
				}
				a_ofst[n_free] = i_ofst
				a_after[n_free] = i_after
				if usize(unsafe { a_data + i_after }) > usize(p_end) {
					return 0
				}
				n_free++
			}
			n_ret++
		}
	}
	for j = 0; j < n_free; j++ {
		free_space(p_pg, a_ofst[j], a_after[j] - a_ofst[j])
	}
	return n_ret
}

@[c:'editPage']
fn edit_page(p_pg &MemPage, i_old int, i_new int, n_new int, pca_rray &CellArray) int {
	a_data := p_pg.aData
	hdr := int(p_pg.hdrOffset)
	p_begin := unsafe { p_pg.aCellIdx + (n_new * 2) }
	n_cell := int(p_pg.nCell)
	p_data := &U8(0)
	p_cellptr := &U8(0)
	i := 0
	i_old_end := i_old + int(p_pg.nCell) + int(p_pg.nOverflow)
	i_new_end := i_new + n_new
	if i_old < i_new {
		n_shift := page_free_array(p_pg, i_old, i_new - i_old, pca_rray)
		if (n_shift > n_cell) {
			return sqlite3_corrupt_error(7899)
		}
		C.memmove(voidptr(p_pg.aCellIdx), voidptr(unsafe { p_pg.aCellIdx + (n_shift * 2) }), u64(n_cell * 2))
		n_cell -= n_shift
	}
	if i_new_end < i_old_end {
		n_tail := page_free_array(p_pg, i_new_end, i_old_end - i_new_end, pca_rray)
		n_cell -= n_tail
	}
	p_data = unsafe { a_data + (int((a_data + (hdr + 5))[0]) << 8 | int((a_data + (hdr + 5))[1])) }
	if usize(p_data) < usize(p_begin) {
		unsafe { goto editpage_fail
		 }
	}
	if (usize(p_data) > usize(p_pg.aDataEnd)) {
		unsafe { goto editpage_fail
		 }
	}
	if i_new < i_old {
		n_add := (if n_new < (i_old - i_new) { n_new } else { (i_old - i_new) })
		p_cellptr = p_pg.aCellIdx
		C.memmove(voidptr(unsafe { p_cellptr + (n_add * 2) }), voidptr(p_cellptr), u64(n_cell * 2))
		if page_insert_array(p_pg, p_begin, &&U8(&&U8(c2v_address_of(&p_data))), p_cellptr, i_new, n_add, pca_rray) {
			unsafe { goto editpage_fail
			 }
		}
		n_cell += n_add
	}
	for i = 0; i < int(p_pg.nOverflow); i++ {
		i_cell := (i_old + int(p_pg.aiOvfl[i])) - i_new
		if i_cell >= 0 && i_cell < n_new {
			p_cellptr = unsafe { p_pg.aCellIdx + (i_cell * 2) }
			if n_cell > i_cell {
				C.memmove(voidptr(unsafe { p_cellptr + 2 }), voidptr(p_cellptr), u64((n_cell - i_cell) * 2))
			}
			n_cell++
			cached_cell_size(pca_rray, i_cell + i_new)
			if page_insert_array(p_pg, p_begin, &&U8(&&U8(c2v_address_of(&p_data))), p_cellptr, i_cell + i_new, 1, pca_rray) {
				unsafe { goto editpage_fail
				 }
			}
		}
	}
	p_cellptr = unsafe { p_pg.aCellIdx + (n_cell * 2) }
	if page_insert_array(p_pg, p_begin, &&U8(&&U8(c2v_address_of(&p_data))), p_cellptr, i_new + n_cell, n_new - n_cell, pca_rray) {
		unsafe { goto editpage_fail
		 }
	}
	p_pg.nCell = U16(n_new)
	p_pg.nOverflow = U8(0)
	(unsafe { a_data + (hdr + 3) })[0] = U8((int(p_pg.nCell) >> 8))
	(unsafe { a_data + (hdr + 3) })[1] = U8(p_pg.nCell)
	(unsafe { a_data + (hdr + 5) })[0] = U8(((i64((isize(p_data) - isize(a_data)) / isize(sizeof(U8)))) >> 8))
	(unsafe { a_data + (hdr + 5) })[1] = U8((i64((isize(p_data) - isize(a_data)) / isize(sizeof(U8)))))
	return 0
	editpage_fail:
	if n_new < 1 {
		return sqlite3_corrupt_error(7977)
	}
	populate_cell_cache(pca_rray, i_new, n_new)
	return rebuild_page(pca_rray, i_new, n_new, p_pg)
}

fn balance_quick(p_parent &MemPage, p_page &MemPage, p_space &U8) int {
	p_bt := p_page.pBt
	p_new := &MemPage(0)
	rc := 0
	pgno_new := Pgno(0)
	if int(p_page.nCell) == 0 {
		return sqlite3_corrupt_error(8017)
	}
	rc = allocate_btree_page(p_bt, &&MemPage(&&MemPage(c2v_address_of(&p_new))), &pgno_new, Pgno(0), U8(0))
	if rc == 0 {
		p_out := unsafe { p_space + 4 }
		p_cell := p_page.apOvfl[0]
		sz_cell := p_page.xCellSize(p_page, p_cell)
		p_stop := &U8(0)
		b := CellArray{}
		zero_page(p_new, 1 | 4 | 8)
		b.nCell = 1
		b.pRef = p_page
		b.apCell = &&U8(c2v_address_of(&p_cell))
		b.szCell = &sz_cell
		b.apEnd[0] = p_page.aDataEnd
		b.ixNx[0] = 2
		b.ixNx[3 * 2 - 1] = 2147483647
		rc = rebuild_page(&b, 0, 1, p_new)
		if rc {
			release_page(p_new)
			return rc
		}
		p_new.nFree = int(p_bt.usableSize - u32(p_new.cellOffset) - u32(2) - u32(sz_cell))
		if p_bt.autoVacuum {
			ptrmap_put(p_bt, pgno_new, U8(5), p_parent.pgno, &rc)
			if int(sz_cell) > int(p_new.minLocal) {
				ptrmap_put_ovfl_ptr(p_new, p_new, p_cell, &rc)
			}
		}
		p_cell = (p_page.aData + (int(p_page.maskPage) & (int((unsafe { p_page.aCellIdx + (2 * (int(p_page.nCell) - 1)) })[0]) << 8 | int((unsafe { p_page.aCellIdx + (2 * (int(p_page.nCell) - 1)) })[1]))))
		p_stop = unsafe { p_cell + 9 }
		for (int((unsafe { *(c2v_pointer_postfix(voidptr(&p_cell), p_cell, isize(1))) })) & 128) && usize(p_cell) < usize(p_stop) {
			0
		}
		p_stop = unsafe { p_cell + 9 }
		for {
			if !((int(c2v_assign[u8]((c2v_pointer_postfix(voidptr(&p_out), p_out, isize(1))), u8((unsafe { *(c2v_pointer_postfix(voidptr(&p_cell), p_cell, isize(1))) })))) & 128) && usize(p_cell) < usize(p_stop)) {
				break
			}
			0
		}
		if rc == 0 {
			rc = insert_cell(p_parent, int(p_parent.nCell), p_space, int((i64((isize(p_out) - isize(p_space)) / isize(sizeof(U8))))), unsafe { nil }, p_page.pgno)
		}
		sqlite3_put4byte(unsafe { p_parent.aData + (int(p_parent.hdrOffset) + 8) }, pgno_new)
		release_page(p_new)
	}
	return rc
}

@[c:'copyNodeContent']
fn copy_node_content(p_from &MemPage, p_to &MemPage, prc &int) {
	if (unsafe { *prc }) == 0 {
		p_bt := p_from.pBt
		a_from := p_from.aData
		a_to := p_to.aData
		i_from_hdr := int(p_from.hdrOffset)
		i_to_hdr := (if (p_to.pgno == Pgno(1)) { 100 } else { 0 })
		rc := 0
		i_data := 0
		i_data = (int((unsafe { a_from + (i_from_hdr + 5) })[0]) << 8 | int((unsafe { a_from + (i_from_hdr + 5) })[1]))
		C.memcpy(voidptr(unsafe { a_to + i_data }), voidptr(unsafe { a_from + i_data }), u64(p_bt.usableSize - u32(i_data)))
		C.memcpy(voidptr(unsafe { a_to + i_to_hdr }), voidptr(unsafe { a_from + i_from_hdr }), u64(int(p_from.cellOffset) + 2 * int(p_from.nCell)))
		p_to.isInit = U8(0)
		rc = btree_init_page(p_to)
		if rc == 0 {
			rc = btree_compute_free_space(p_to)
		}
		if rc != 0 {
			unsafe { *prc = rc }
			return
		}
		if p_bt.autoVacuum {
			unsafe { *prc = set_child_ptrmaps(p_to) }
		}
	}
}

fn balance_nonroot(p_parent &MemPage, i_parent_idx int, a_ovfl_space &U8, is_root int, b_bulk int) int {
	p_bt := &BtShared(0)
	n_max_cells := 0
	n_new := 0
	n_old := 0
	i := 0
	j := 0
	k := 0

	nx_div := 0
	rc := 0
	leaf_correction := U16(0)
	leaf_data := 0
	usable_space := 0
	page_flags := 0
	i_space1 := 0
	i_ovfl_space := 0
	sz_scratch := U64(0)
	ap_old := [3]&MemPage{}
	ap_new := [5]&MemPage{}
	p_right := &U8(0)
	ap_div := [2]&U8{}
	cnt_new := [5]int{}
	cnt_old := [5]int{}
	sz_new := [5]int{}
	a_space1 := &U8(0)
	pgno := Pgno(0)
	ab_done := [5]U8{}
	a_pgno := [5]Pgno{}
	b := CellArray{}
	C.memset(voidptr(unsafe { &ab_done[0] }), 0, sizeof([5]U8))
	C.memset(voidptr(&b), 0, sizeof(b) - sizeof(int))
	b.ixNx[3 * 2 - 1] = 2147483647
	p_bt = p_parent.pBt
	if isnil(a_ovfl_space) {
		return 7
	}
	i = int(p_parent.nOverflow) + int(p_parent.nCell)
	if i < 2 {
		nx_div = 0
	} else {
		if i_parent_idx == 0 {
			nx_div = 0
		} else if i_parent_idx == i {
			nx_div = i - 2 + b_bulk
		} else {
			nx_div = i_parent_idx - 1
		}
		i = 2 - b_bulk
	}
	n_old = i + 1
	if (i + nx_div - int(p_parent.nOverflow)) == int(p_parent.nCell) {
		p_right = unsafe { p_parent.aData + (int(p_parent.hdrOffset) + 8) }
	} else {
		p_right = (p_parent.aData + (int(p_parent.maskPage) & (int((unsafe { p_parent.aCellIdx + (2 * (i + nx_div - int(p_parent.nOverflow))) })[0]) << 8 | int((unsafe { p_parent.aCellIdx + (2 * (i + nx_div - int(p_parent.nOverflow))) })[1]))))
	}
	pgno = sqlite3_get4byte(p_right)
	for {
		if rc == 0 {
			rc = get_and_init_page(p_bt, pgno, &&MemPage(unsafe { &ap_old[0] + i }), 0)
		}
		if rc {
			C.memset(voidptr(unsafe { &ap_old[0] }), 0, u64((i + 1)) * sizeof(voidptr))
			unsafe { goto balance_cleanup
			 }
		}
		if ap_old[i].nFree < 0 {
			rc = btree_compute_free_space(ap_old[i])
			if rc {
				C.memset(voidptr(unsafe { &ap_old[0] }), 0, u64(i) * sizeof(voidptr))
				unsafe { goto balance_cleanup
				 }
			}
		}
		n_max_cells += int(ap_old[i].nCell) + 4
		if (i--) == 0 {
			break
		}
		if int(p_parent.nOverflow) && i + nx_div == int(p_parent.aiOvfl[0]) {
			ap_div[i] = p_parent.apOvfl[0]
			pgno = sqlite3_get4byte(ap_div[i])
			sz_new[i] = int(p_parent.xCellSize(p_parent, ap_div[i]))
			p_parent.nOverflow = U8(0)
		} else {
			ap_div[i] = (p_parent.aData + (int(p_parent.maskPage) & (int((unsafe { p_parent.aCellIdx + (2 * (i + nx_div - int(p_parent.nOverflow))) })[0]) << 8 | int((unsafe { p_parent.aCellIdx + (2 * (i + nx_div - int(p_parent.nOverflow))) })[1]))))
			pgno = sqlite3_get4byte(ap_div[i])
			sz_new[i] = int(p_parent.xCellSize(p_parent, ap_div[i]))
			if int(p_bt.btsFlags) & 12 {
				i_off := 0
				i_off = (int(i64(voidptr(ap_div[i])))) - (int(i64(voidptr(p_parent.aData))))
				if (i_off + sz_new[i]) <= int(p_bt.usableSize) {
					C.memcpy(voidptr(unsafe { a_ovfl_space + i_off }), voidptr(ap_div[i]), u64(sz_new[i]))
					ap_div[i] = unsafe { a_ovfl_space + (i64((isize(ap_div[i]) - isize(p_parent.aData)) / isize(sizeof(U8)))) }
				}
			}
			drop_cell(p_parent, i + nx_div - int(p_parent.nOverflow), sz_new[i], &rc)
		}
	}
	n_max_cells = (n_max_cells + 3) & ~3
	sz_scratch = U64(u64(n_max_cells) * sizeof(voidptr) + u64(n_max_cells) * sizeof(U16) + u64(p_bt.pageSize))
	b.apCell = sqlite3_db_malloc_raw(unsafe { nil }, sz_scratch)
	if usize(b.apCell) == usize(0) {
		rc = 7
		unsafe { goto balance_cleanup
		 }
	}
	b.szCell = &U16(voidptr(unsafe { b.apCell + n_max_cells }))
	a_space1 = &U8(voidptr(unsafe { b.szCell + n_max_cells }))
	b.pRef = ap_old[0]
	leaf_correction = U16(int(b.pRef.leaf) * 4)
	leaf_data = int(b.pRef.intKeyLeaf)
	for i = 0; i < n_old; i++ {
		p_old := ap_old[i]
		limit := int(p_old.nCell)
		a_data := p_old.aData
		mask_page := p_old.maskPage
		pi_cell := a_data + int(p_old.cellOffset)
		pi_end := &U8(0)
		if int(p_old.aData[0]) != int(ap_old[0].aData[0]) {
			rc = sqlite3_corrupt_error(8441)
			unsafe { goto balance_cleanup
			 }
		}
		C.memset(voidptr(unsafe { b.szCell + b.nCell }), 0, sizeof(U16) * u64((limit + int(p_old.nOverflow))))
		if int(p_old.nOverflow) > 0 {
			if (limit < int(p_old.aiOvfl[0])) {
				rc = sqlite3_corrupt_error(8465)
				unsafe { goto balance_cleanup
				 }
			}
			limit = int(p_old.aiOvfl[0])
			for j = 0; j < limit; j++ {
				b.apCell[b.nCell] = a_data + (int(mask_page) & (int(pi_cell[0]) << 8 | int(pi_cell[1])))
				c2v_pointer_prefix(voidptr(&pi_cell), pi_cell, isize(2))
				b.nCell++
			}
			for k = 0; k < int(p_old.nOverflow); k++ {
				b.apCell[b.nCell] = p_old.apOvfl[k]
				b.nCell++
			}
		}
		pi_end = a_data + int(p_old.cellOffset) + (2 * int(p_old.nCell))
		for usize(pi_cell) < usize(pi_end) {
			b.apCell[b.nCell] = a_data + (int(mask_page) & (int(pi_cell[0]) << 8 | int(pi_cell[1])))
			c2v_pointer_prefix(voidptr(&pi_cell), pi_cell, isize(2))
			b.nCell++
		}
		cnt_old[i] = b.nCell
		if i < n_old - 1 && !leaf_data {
			sz := U16(sz_new[i])
			p_temp := &U8(0)
			b.szCell[b.nCell] = sz
			p_temp = unsafe { a_space1 + i_space1 }
			i_space1 += int(sz)
			C.memcpy(voidptr(p_temp), voidptr(ap_div[i]), u64(sz))
			b.apCell[b.nCell] = p_temp + int(leaf_correction)
			b.szCell[b.nCell] = U16(int(b.szCell[b.nCell]) - int(leaf_correction))
			if !p_old.leaf {
				C.memcpy(voidptr(b.apCell[b.nCell]), voidptr(unsafe { p_old.aData + 8 }), u64(4))
			} else {
				for int(b.szCell[b.nCell]) < 4 {
					a_space1[i_space1++] = U8(0)
					b.szCell[b.nCell]++
				}
			}
			b.nCell++
		}
	}
	usable_space = int(p_bt.usableSize - u32(12) + u32(leaf_correction))
	k = 0
	for i = 0; i < n_old; i++ {
		p := ap_old[i]
		b.apEnd[k] = p.aDataEnd
		b.ixNx[k] = cnt_old[i]
		if k && b.ixNx[k] == b.ixNx[k - 1] {
			k--
		}
		if !leaf_data {
			k++
			b.apEnd[k] = p_parent.aDataEnd
			b.ixNx[k] = cnt_old[i] + 1
		}
		sz_new[i] = usable_space - p.nFree
		for j = 0; j < int(p.nOverflow); j++ {
			sz_new[i] += 2 + int(p.xCellSize(p, p.apOvfl[j]))
		}
		cnt_new[i] = cnt_old[i]
		k++
	}
	k = n_old
	for i = 0; i < k; i++ {
		sz := 0
		for sz_new[i] > usable_space {
			if i + 1 >= k {
				k = i + 2
				if k > 3 + 2 {
					rc = sqlite3_corrupt_error(8566)
					unsafe { goto balance_cleanup
					 }
				}
				sz_new[k - 1] = 0
				cnt_new[k - 1] = b.nCell
			}
			sz = 2 + int(cached_cell_size(&b, cnt_new[i] - 1))
			sz_new[i] -= sz
			if !leaf_data {
				if cnt_new[i] < b.nCell {
					sz = 2 + int(cached_cell_size(&b, cnt_new[i]))
				} else {
					sz = 0
				}
			}
			sz_new[i + 1] += sz
			cnt_new[i]--
		}
		for cnt_new[i] < b.nCell {
			sz = 2 + int(cached_cell_size(&b, cnt_new[i]))
			if sz_new[i] + sz > usable_space {
				break
			}
			sz_new[i] += sz
			cnt_new[i]++
			if !leaf_data {
				if cnt_new[i] < b.nCell {
					sz = 2 + int(cached_cell_size(&b, cnt_new[i]))
				} else {
					sz = 0
				}
			}
			sz_new[i + 1] -= sz
		}
		if cnt_new[i] >= b.nCell {
			k = i + 1
		} else if cnt_new[i] <= (if i > 0 { cnt_new[i - 1] } else { 0 }) {
			rc = sqlite3_corrupt_error(8599)
			unsafe { goto balance_cleanup
			 }
		}
	}
	for i = k - 1; i > 0; i-- {
		sz_right := sz_new[i]
		sz_left := sz_new[i - 1]
		r := 0
		d := 0
		r = cnt_new[i - 1] - 1
		d = r + 1 - leaf_data
		cached_cell_size(&b, d)
		for {
			sz_r := 0
			sz_d := 0

			sz_r = int(cached_cell_size(&b, r))
			sz_d = int(b.szCell[d])
			if sz_right != 0 && (b_bulk || sz_right + sz_d + 2 > sz_left - (sz_r + (if i == k - 1 {
				0
			} else {
				2
			}))) {
				break
			}
			sz_right += sz_d + 2
			sz_left -= sz_r + 2
			cnt_new[i - 1] = r
			r--
			d--
			if !(r >= 0) {
				break
			}
		}
		sz_new[i] = sz_right
		sz_new[i - 1] = sz_left
		if cnt_new[i - 1] <= (if i > 1 { cnt_new[i - 2] } else { 0 }) {
			rc = sqlite3_corrupt_error(8643)
			unsafe { goto balance_cleanup
			 }
		}
	}
	0
	page_flags = int(ap_old[0].aData[0])
	for i = 0; i < k; i++ {
		p_new := &MemPage(0)
		if i < n_old {
			ap_new[i] = ap_old[i]
			p_new = ap_new[i]
			ap_old[i] = 0
			rc = sqlite3_pager_write(p_new.pDbPage)
			n_new++
			if sqlite3_pager_page_refcount(p_new.pDbPage) != 1 + int((i == (i_parent_idx - nx_div))) && rc == 0 {
				rc = sqlite3_corrupt_error(8676)
			}
			if rc {
				unsafe { goto balance_cleanup
				 }
			}
		} else {
			rc = allocate_btree_page(p_bt, &&MemPage(&&MemPage(c2v_address_of(&p_new))), &pgno, (if b_bulk {
				Pgno(1)
			} else {
				pgno
			}), U8(0))
			if rc {
				unsafe { goto balance_cleanup
				 }
			}
			zero_page(p_new, page_flags)
			ap_new[i] = p_new
			n_new++
			cnt_old[i] = b.nCell
			if p_bt.autoVacuum {
				ptrmap_put(p_bt, p_new.pgno, U8(5), p_parent.pgno, &rc)
				if rc != 0 {
					unsafe { goto balance_cleanup
					 }
				}
			}
		}
	}
	for i = 0; i < n_new; i++ {
		a_pgno[i] = ap_new[i].pgno
	}
	for i = 0; i < n_new - 1; i++ {
		ib := i
		for j = i + 1; j < n_new; j++ {
			if ap_new[j].pgno < ap_new[ib].pgno {
				ib = j
			}
		}
		if ib != i {
			pgno_a := ap_new[i].pgno
			pgno_b := ap_new[ib].pgno
			pgno_temp := (u32(sqlite3PendingByte) / p_bt.pageSize) + u32(1)
			fg_a := ap_new[i].pDbPage.flags
			fg_b := ap_new[ib].pDbPage.flags
			sqlite3_pager_rekey(ap_new[i].pDbPage, pgno_temp, fg_b)
			sqlite3_pager_rekey(ap_new[ib].pDbPage, pgno_a, fg_a)
			sqlite3_pager_rekey(ap_new[i].pDbPage, pgno_b, fg_b)
			ap_new[i].pgno = pgno_b
			ap_new[ib].pgno = pgno_a
		}
	}
	0
	sqlite3_put4byte(p_right, ap_new[n_new - 1].pgno)
	if (page_flags & 8) == 0 && n_old != n_new {
		p_old := &MemPage(0)
		if n_new > n_old {
			p_old = ap_new[n_old - 1]
		} else {
			p_old = ap_old[n_old - 1]
		}
		C.memcpy(voidptr(unsafe { ap_new[n_new - 1].aData + 8 }), voidptr(unsafe { p_old.aData + 8 }), u64(4))
	}
	if p_bt.autoVacuum {
		p_old := &MemPage(0)
		p_new := c2v_assign[&MemPage](unsafe { &p_old }, ap_new[0])
		cnt_old_next := int(p_new.nCell) + int(p_new.nOverflow)
		i_new := 0
		i_old := 0
		for i = 0; i < b.nCell; i++ {
			p_cell := b.apCell[i]
			for i == cnt_old_next {
				i_old++
				p_old = if i_old < n_new { ap_new[i_old] } else { ap_old[i_old] }
				cnt_old_next += int(p_old.nCell) + int(p_old.nOverflow) + int(!leaf_data)
			}
			if i == cnt_new[i_new] {
				p_new = ap_new[c2v_prefix_add(unsafe { &i_new }, 1)]
				if !leaf_data {
					continue
				}
			}
			if i_old >= n_new || p_new.pgno != a_pgno[i_old] || !((Uptr(voidptr(p_cell)) >= Uptr(voidptr(p_old.aData))) && (Uptr(voidptr(p_cell)) < Uptr(voidptr(p_old.aDataEnd)))) {
				if !leaf_correction {
					ptrmap_put(p_bt, sqlite3_get4byte(p_cell), U8(5), p_new.pgno, &rc)
				}
				if int(cached_cell_size(&b, i)) > int(p_new.minLocal) {
					ptrmap_put_ovfl_ptr(p_new, p_old, p_cell, &rc)
				}
				if rc {
					unsafe { goto balance_cleanup
					 }
				}
			}
		}
	}
	for i = 0; i < n_new - 1; i++ {
		p_cell := &U8(0)
		p_temp := &U8(0)
		sz := 0
		p_src_end := &U8(0)
		p_new := ap_new[i]
		j = cnt_new[i]
		p_cell = b.apCell[j]
		sz = int(b.szCell[j]) + int(leaf_correction)
		p_temp = unsafe { a_ovfl_space + i_ovfl_space }
		if !p_new.leaf {
			C.memcpy(voidptr(unsafe { p_new.aData + 8 }), voidptr(p_cell), u64(4))
		} else if leaf_data {
			info := CellInfo{}
			j--
			p_new.xParseCell(p_new, b.apCell[j], &info)
			p_cell = p_temp
			sz = 4 + sqlite3_put_varint(unsafe { p_cell + 4 }, U64(info.nKey))
			p_temp = 0
		} else {
			c2v_pointer_prefix(voidptr(&p_cell), p_cell, isize(-(4)))
			if int(b.szCell[j]) == 4 {
				sz = int(p_parent.xCellSize(p_parent, p_cell))
			}
		}
		i_ovfl_space += sz
		for k = 0; b.ixNx[k] <= j; k++ {
		}
		p_src_end = b.apEnd[k]
		if ((Uptr(voidptr(p_cell)) < Uptr(voidptr(p_src_end))) && (Uptr(voidptr((p_cell + sz))) > Uptr(voidptr(p_src_end)))) {
			rc = sqlite3_corrupt_error(8882)
			unsafe { goto balance_cleanup
			 }
		}
		rc = insert_cell(p_parent, nx_div + i, p_cell, sz, p_temp, p_new.pgno)
		if rc != 0 {
			unsafe { goto balance_cleanup
			 }
		}
	}
	for i = 1 - n_new; i < n_new; i++ {
		i_pg := if i < 0 { -i } else { i }
		if ab_done[i_pg] {
			continue
		}
		if i >= 0 || cnt_old[i_pg - 1] >= cnt_new[i_pg - 1] {
			i_new := 0
			i_old := 0
			n_new_cell := 0
			if i_pg == 0 {
				i_old = 0
				i_new = i_old
				n_new_cell = cnt_new[0]
			} else {
				i_old = if i_pg < n_old { (cnt_old[i_pg - 1] + int(!leaf_data)) } else { b.nCell }
				i_new = cnt_new[i_pg - 1] + int(!leaf_data)
				n_new_cell = cnt_new[i_pg] - i_new
			}
			rc = edit_page(ap_new[i_pg], i_old, i_new, n_new_cell, &b)
			if rc {
				unsafe { goto balance_cleanup
				 }
			}
			ab_done[i_pg]++
			ap_new[i_pg].nFree = usable_space - sz_new[i_pg]
		}
	}
	if is_root && int(p_parent.nCell) == 0 && int(p_parent.hdrOffset) <= ap_new[0].nFree {
		rc = defragment_page(ap_new[0], -1)
		0
		copy_node_content(ap_new[0], p_parent, &rc)
		free_page(ap_new[0], &rc)
	} else if int(p_bt.autoVacuum) && !leaf_correction {
		for i = 0; i < n_new; i++ {
			key := sqlite3_get4byte(unsafe { ap_new[i].aData + 8 })
			ptrmap_put(p_bt, key, U8(5), ap_new[i].pgno, &rc)
		}
	}
	0
	for i = n_new; i < n_old; i++ {
		free_page(ap_old[i], &rc)
	}
	balance_cleanup:
	sqlite3_db_free(unsafe { nil }, voidptr(b.apCell))
	for i = 0; i < n_old; i++ {
		release_page(ap_old[i])
	}
	for i = 0; i < n_new; i++ {
		release_page(ap_new[i])
	}
	return rc
}

fn balance_deeper(p_root &MemPage, pp_child &&MemPage) int {
	rc := 0
	p_child := unsafe { &MemPage(nil) }
	pgno_child := Pgno(0)
	p_bt := p_root.pBt
	rc = sqlite3_pager_write(p_root.pDbPage)
	if rc == 0 {
		rc = allocate_btree_page(p_bt, &&MemPage(&&MemPage(c2v_address_of(&p_child))), &pgno_child, p_root.pgno, U8(0))
		copy_node_content(p_root, p_child, &rc)
		if p_bt.autoVacuum {
			ptrmap_put(p_bt, pgno_child, U8(5), p_root.pgno, &rc)
		}
	}
	if rc {
		unsafe { *pp_child = 0 }
		release_page(p_child)
		return rc
	}
	0
	C.memcpy(p_child.aiOvfl, p_root.aiOvfl, u64(p_root.nOverflow) * sizeof(U16))
	C.memcpy(p_child.apOvfl, p_root.apOvfl, u64(p_root.nOverflow) * sizeof(&U8))
	p_child.nOverflow = p_root.nOverflow
	zero_page(p_root, int(p_child.aData[0]) & ~8)
	sqlite3_put4byte(unsafe { p_root.aData + (int(p_root.hdrOffset) + 8) }, pgno_child)
	unsafe { *pp_child = p_child }
	return 0
}

@[c:'anotherValidCursor']
fn another_valid_cursor(p_cur &BtCursor) int {
	p_other := &BtCursor(0)
	for p_other = p_cur.pBt.pCursor; p_other; p_other = p_other.pNext {
		if usize(p_other) != usize(p_cur) && int(p_other.eState) == 0 && usize(p_other.pPage) == usize(p_cur.pPage) {
			return sqlite3_corrupt_error(9114)
		}
	}
	return 0
}

fn balance(p_cur &BtCursor) int {
	rc := 0
	a_balance_quick_space := [13]U8{}
	p_free := unsafe { &U8(nil) }
	0
	0
	for {
		i_page := 0
		p_page := p_cur.pPage
		if (p_page.nFree < 0) && btree_compute_free_space(p_page) {
			break
		}
		if int(p_page.nOverflow) == 0 && p_page.nFree * 3 <= int(p_cur.pBt.usableSize) * 2 {
			break
		} else {
			i_page = int(p_cur.iPage)
			if i_page == 0 {
				if int(p_page.nOverflow) && c2v_assign[int](unsafe { &rc }, int(another_valid_cursor(p_cur))) == 0 {
					0
					rc = balance_deeper(p_page, &&MemPage(unsafe { &p_cur.apPage[0] + 1 }))
					if rc == 0 {
						p_cur.iPage = I8(1)
						p_cur.ix = U16(0)
						p_cur.aiIdx[0] = U16(0)
						p_cur.apPage[0] = p_page
						p_cur.pPage = p_cur.apPage[1]
					}
				} else {
					break
				}
			} else if sqlite3_pager_page_refcount(p_page.pDbPage) > 1 {
				rc = sqlite3_corrupt_error(9174)
			} else {
				p_parent := p_cur.apPage[i_page - 1]
				i_idx := int(p_cur.aiIdx[i_page - 1])
				rc = sqlite3_pager_write(p_parent.pDbPage)
				if rc == 0 && p_parent.nFree < 0 {
					rc = btree_compute_free_space(p_parent)
				}
				if rc == 0 {
					if int(p_page.intKeyLeaf) && int(p_page.nOverflow) == 1 && int(p_page.aiOvfl[0]) == int(p_page.nCell) && p_parent.pgno != Pgno(1) && int(p_parent.nCell) == i_idx {
						0
						rc = balance_quick(p_parent, p_page, &a_balance_quick_space[0])
					} else {
						p_space := &U8(sqlite3_page_malloc(int(p_cur.pBt.pageSize)))
						rc = balance_nonroot(p_parent, i_idx, p_space, i_page == 1, int(p_cur.hints) & 1)
						if p_free {
							sqlite3_page_free(voidptr(p_free))
						}
						p_free = p_space
					}
				}
				p_page.nOverflow = U8(0)
				release_page(p_page)
				p_cur.iPage--
				p_cur.pPage = p_cur.apPage[p_cur.iPage]
			}
		}
		if !(rc == 0) {
			break
		}
	}
	if p_free {
		sqlite3_page_free(voidptr(p_free))
	}
	return rc
}

@[c:'btreeOverwriteContent']
fn btree_overwrite_content(p_page &MemPage, p_dest &U8, px &BtreePayload, i_offset int, i_amt int) int {
	n_data := px.nData - i_offset
	if n_data <= 0 {
		i := 0
		for i = 0; i < i_amt && int(p_dest[i]) == 0; i++ {
		}
		if i < i_amt {
			rc := sqlite3_pager_write(p_page.pDbPage)
			if rc {
				return rc
			}
			C.memset(voidptr(p_dest + i), 0, u64(i_amt - i))
		}
	} else {
		if n_data < i_amt {
			rc := btree_overwrite_content(p_page, p_dest + n_data, px, i_offset + n_data, i_amt - n_data)
			if rc {
				return rc
			}
			i_amt = n_data
		}
		if C.memcmp(voidptr(p_dest), voidptr((&U8(px.pData)) + i_offset), u64(i_amt)) != 0 {
			rc := sqlite3_pager_write(p_page.pDbPage)
			if rc {
				return rc
			}
			C.memmove(voidptr(p_dest), voidptr((&U8(px.pData)) + i_offset), u64(i_amt))
		}
	}
	return 0
}

@[c:'btreeOverwriteOverflowCell']
fn btree_overwrite_overflow_cell(p_cur &BtCursor, px &BtreePayload) int {
	i_offset := 0
	n_total := px.nData + px.nZero
	rc := 0
	p_page := p_cur.pPage
	p_bt := &BtShared(0)
	ovfl_pgno := Pgno(0)
	ovfl_page_size := u32(0)
	rc = btree_overwrite_content(p_page, p_cur.info.pPayload, px, 0, int(p_cur.info.nLocal))
	if rc {
		return rc
	}
	i_offset = int(p_cur.info.nLocal)
	ovfl_pgno = sqlite3_get4byte(p_cur.info.pPayload + i_offset)
	p_bt = p_page.pBt
	ovfl_page_size = p_bt.usableSize - u32(4)
	for {
		rc = btree_get_page(p_bt, ovfl_pgno, &&MemPage(&&MemPage(c2v_address_of(&p_page))), 0)
		if rc {
			return rc
		}
		if sqlite3_pager_page_refcount(p_page.pDbPage) != 1 || int(p_page.isInit) {
			rc = sqlite3_corrupt_error(9338)
		} else {
			if u32(i_offset) + ovfl_page_size < u32(n_total) {
				ovfl_pgno = sqlite3_get4byte(p_page.aData)
			} else {
				ovfl_page_size = u32(n_total - i_offset)
			}
			rc = btree_overwrite_content(p_page, p_page.aData + 4, px, i_offset, int(ovfl_page_size))
		}
		sqlite3_pager_unref(p_page.pDbPage)
		if rc {
			return rc
		}
		i_offset += ovfl_page_size
		if !(i_offset < n_total) {
			break
		}
	}
	return 0
}

@[c:'btreeOverwriteCell']
fn btree_overwrite_cell(p_cur &BtCursor, px &BtreePayload) int {
	n_total := px.nData + px.nZero
	p_page := p_cur.pPage
	if usize(p_cur.info.pPayload + p_cur.info.nLocal) > usize(p_page.aDataEnd) || usize(p_cur.info.pPayload) < usize(p_page.aData + p_page.cellOffset) {
		return sqlite3_corrupt_error(9366)
	}
	if int(p_cur.info.nLocal) == n_total {
		return btree_overwrite_content(p_page, p_cur.info.pPayload, px, 0, int(p_cur.info.nLocal))
	} else {
		return btree_overwrite_overflow_cell(p_cur, px)
	}
}

@[c:'sqlite3BtreeInsert']
fn sqlite3_btree_insert(p_cur &BtCursor, px &BtreePayload, flags int, seek_result int) int {
	rc := 0
	loc := seek_result
	sz_new := 0
	idx := 0
	p_page := &MemPage(0)
	p := p_cur.pBtree
	old_cell := &u8(0)
	new_cell := unsafe { &u8(nil) }
	if int(p_cur.curFlags) & 32 {
		rc = save_all_cursors(p.pBt, p_cur.pgnoRoot, p_cur)
		if rc {
			return rc
		}
		if loc && int(p_cur.iPage) < 0 {
			return sqlite3_corrupt_error(9447)
		}
	}
	if int(p_cur.eState) >= 3 {
		0
		0
		rc = move_to_root(p_cur)
		if rc && rc != 16 {
			return rc
		}
	}
	if usize(p_cur.pKeyInfo) == usize(0) {
		if p.hasIncrblobCur {
			invalidate_incrblob_cursors(p, p_cur.pgnoRoot, px.nKey, 0)
		}
		if (int(p_cur.curFlags) & 2) != 0 && px.nKey == p_cur.info.nKey {
			if int(p_cur.info.nSize) != 0 && p_cur.info.nPayload == u32(px.nData) + u32(px.nZero) {
				return btree_overwrite_cell(p_cur, px)
			}
		} else if loc == 0 {
			rc = sqlite3_btree_table_moveto(p_cur, px.nKey, (flags & 8) != 0, &loc)
			if rc {
				return rc
			}
		}
	} else {
		if loc == 0 && (flags & 2) == 0 {
			if px.nMem {
				r := UnpackedRecord{}
				r.pKeyInfo = p_cur.pKeyInfo
				r.aMem = px.aMem
				r.nField = px.nMem
				r.default_rc = I8(0)
				r.eqSeen = U8(0)
				rc = sqlite3_btree_index_moveto(p_cur, &r, &loc)
			} else {
				rc = btree_moveto(p_cur, voidptr(px.pKey), px.nKey, (flags & 8) != 0, &loc)
			}
			if rc {
				return rc
			}
		}
		if loc == 0 {
			get_cell_info(p_cur)
			if p_cur.info.nKey == px.nKey {
				x2 := BtreePayload{}
				x2.pData = px.pKey
				x2.nData = int(px.nKey)
				x2.nZero = 0
				return btree_overwrite_cell(p_cur, &x2)
			}
		}
	}
	p_page = p_cur.pPage
	if p_page.nFree < 0 {
		if (int(p_cur.eState) > 1) {
			rc = sqlite3_corrupt_error(9570)
		} else {
			rc = btree_compute_free_space(p_page)
		}
		if rc {
			return rc
		}
	}
	0
	new_cell = p.pBt.pTmpSpace
	if flags & 128 {
		rc = 0
		sz_new = p.pBt.nPreformatSize
		if sz_new < 4 {
			sz_new = 4
			new_cell[3] = u8(0)
		}
		if int(p.pBt.autoVacuum) && sz_new > int(p_page.maxLocal) {
			info := CellInfo{}
			p_page.xParseCell(p_page, unsafe { &U8(new_cell) }, &info)
			if info.nPayload != u32(info.nLocal) {
				ovfl := sqlite3_get4byte(unsafe { new_cell + (sz_new - 4) })
				ptrmap_put(p.pBt, ovfl, U8(3), p_page.pgno, &rc)
				if rc {
					unsafe { goto end_insert
					 }
				}
			}
		}
	} else {
		rc = fill_in_cell(p_page, new_cell, px, &sz_new)
		if rc {
			unsafe { goto end_insert
			 }
		}
	}
	idx = int(p_cur.ix)
	p_cur.info.nSize = U16(0)
	if loc == 0 {
		info := CellInfo{}
		if idx >= int(p_page.nCell) {
			return sqlite3_corrupt_error(9612)
		}
		rc = sqlite3_pager_write(p_page.pDbPage)
		if rc {
			unsafe { goto end_insert
			 }
		}
		old_cell = (p_page.aData + (int(p_page.maskPage) & (int((unsafe { p_page.aCellIdx + (2 * idx) })[0]) << 8 | int((unsafe { p_page.aCellIdx + (2 * idx) })[1]))))
		if !p_page.leaf {
			C.memcpy(voidptr(new_cell), voidptr(old_cell), u64(4))
		}
		p_page.xParseCell(p_page, unsafe { &U8(old_cell) }, &info)
		if u32(info.nLocal) != info.nPayload {
			rc = clear_cell_overflow(p_page, old_cell, &info)
		} else {
			rc = 0
		}
		0
		0
		p_cur.curFlags &= ~4
		if int(info.nSize) == sz_new && u32(info.nLocal) == info.nPayload && (!p.pBt.autoVacuum || sz_new < int(p_page.minLocal)) {
			if usize(old_cell) < usize(p_page.aData + p_page.hdrOffset + 10) {
				return sqlite3_corrupt_error(9639)
			}
			if usize(old_cell + sz_new) > usize(p_page.aDataEnd) {
				return sqlite3_corrupt_error(9642)
			}
			C.memcpy(voidptr(old_cell), voidptr(new_cell), u64(sz_new))
			return 0
		}
		drop_cell(p_page, idx, int(info.nSize), &rc)
		if rc {
			unsafe { goto end_insert
			 }
		}
	} else if loc < 0 && int(p_page.nCell) > 0 {
		idx = int(c2v_prefix_add(unsafe { &p_cur.ix }, u16(1)))
		p_cur.curFlags &= ~(2 | 4)
	} else {
	}
	rc = insert_cell_fast(p_page, idx, unsafe { &U8(new_cell) }, sz_new)
	if p_page.nOverflow {
		p_cur.curFlags &= ~(2 | 4)
		rc = balance(p_cur)
		p_cur.pPage.nOverflow = U8(0)
		p_cur.eState = U8(1)
		if (flags & 2) && rc == 0 {
			btree_release_all_cursor_pages(p_cur)
			if p_cur.pKeyInfo {
				p_cur.pKey = sqlite3_malloc_vdup2(U64(px.nKey))
				if usize(p_cur.pKey) == usize(0) {
					rc = 7
				} else {
					C.memcpy(voidptr(p_cur.pKey), voidptr(px.pKey), u64(px.nKey))
				}
			}
			p_cur.eState = U8(3)
			p_cur.nKey = px.nKey
		}
	}
	end_insert:
	return rc
}

@[c:'sqlite3BtreeTransferRow']
fn sqlite3_btree_transfer_row(p_dest &BtCursor, p_src &BtCursor, i_key I64) int {
	p_bt := p_dest.pBt
	a_out := p_bt.pTmpSpace
	a_in := &U8(0)
	n_in := u32(0)
	n_rem := u32(0)
	get_cell_info(p_src)
	if p_src.info.nPayload < u32(128) {
		mut __c2v_lhs_tmp_78 := unsafe { c2v_pointer_postfix(voidptr(&a_out), a_out, isize(1)) }
		unsafe { *__c2v_lhs_tmp_78 = U8(p_src.info.nPayload) }
	} else {
		c2v_pointer_prefix(voidptr(&a_out), a_out, isize(sqlite3_put_varint(a_out, U64(p_src.info.nPayload))))
	}
	if usize(p_dest.pKeyInfo) == usize(0) {
		c2v_pointer_prefix(voidptr(&a_out), a_out, isize(sqlite3_put_varint(a_out, U64(i_key))))
	}
	n_in = u32(p_src.info.nLocal)
	a_in = p_src.info.pPayload
	if usize(a_in + n_in) > usize(p_src.pPage.aDataEnd) {
		return sqlite3_corrupt_error(9744)
	}
	n_rem = p_src.info.nPayload
	if n_in == n_rem && n_in < u32(p_dest.pPage.maxLocal) {
		C.memcpy(voidptr(a_out), voidptr(a_in), u64(n_in))
		p_bt.nPreformatSize = int(n_in + u32(int((i64((isize(a_out) - isize(p_bt.pTmpSpace)) / isize(sizeof(U8)))))))
		return 0
	} else {
		rc := 0
		p_src_pager := p_src.pBt.pPager
		p_pgno_out := unsafe { &U8(nil) }
		ovfl_in := Pgno(0)
		p_page_in := unsafe { &DbPage(nil) }
		p_page_out := unsafe { &MemPage(nil) }
		n_out := u32(0)
		n_out = u32(btree_payload_to_local(p_dest.pPage, I64(p_src.info.nPayload)))
		p_bt.nPreformatSize = int(n_out) + int((i64((isize(a_out) - isize(p_bt.pTmpSpace)) / isize(sizeof(U8)))))
		if n_out < p_src.info.nPayload {
			p_pgno_out = unsafe { a_out + n_out }
			p_bt.nPreformatSize += 4
		}
		if n_rem > n_in {
			if usize(a_in + n_in + 4) > usize(p_src.pPage.aDataEnd) {
				return sqlite3_corrupt_error(9769)
			}
			ovfl_in = sqlite3_get4byte(unsafe { p_src.info.pPayload + n_in })
		}
		for {
			n_rem -= n_out
			for {
				if n_in > u32(0) {
					n_copy := int((if n_out < n_in { n_out } else { n_in }))
					C.memcpy(voidptr(a_out), voidptr(a_in), u64(n_copy))
					n_out -= u32(n_copy)
					n_in -= u32(n_copy)
					c2v_pointer_prefix(voidptr(&a_out), a_out, isize(n_copy))
					c2v_pointer_prefix(voidptr(&a_in), a_in, isize(n_copy))
				}
				if n_out > u32(0) {
					sqlite3_pager_unref(p_page_in)
					p_page_in = 0
					rc = sqlite3_pager_get(p_src_pager, ovfl_in, &&DbPage(&&DbPage(c2v_address_of(&p_page_in))), 2)
					if rc == 0 {
						a_in = &U8(sqlite3_pager_get_data(p_page_in))
						ovfl_in = sqlite3_get4byte(a_in)
						c2v_pointer_prefix(voidptr(&a_in), a_in, isize(4))
						n_in = p_src.pBt.usableSize - u32(4)
					}
				}
				if !(rc == 0 && n_out > u32(0)) {
					break
				}
			}
			if rc == 0 && n_rem > u32(0) && !isnil(p_pgno_out) {
				pgno_new := Pgno(0)
				p_new := unsafe { &MemPage(nil) }
				rc = allocate_btree_page(p_bt, &&MemPage(&&MemPage(c2v_address_of(&p_new))), &pgno_new, Pgno(0), U8(0))
				sqlite3_put4byte(p_pgno_out, pgno_new)
				if int(p_bt.autoVacuum) && !isnil(p_page_out) {
					ptrmap_put(p_bt, pgno_new, U8(4), p_page_out.pgno, &rc)
				}
				release_page(p_page_out)
				p_page_out = p_new
				if p_page_out {
					p_pgno_out = p_page_out.aData
					sqlite3_put4byte(p_pgno_out, u32(0))
					a_out = unsafe { p_pgno_out + 4 }
					n_out = (if (p_bt.usableSize - u32(4)) < n_rem {
						(p_bt.usableSize - u32(4))
					} else {
						n_rem
					})
				}
			}
			if !(n_rem > u32(0) && rc == 0) {
				break
			}
		}
		release_page(p_page_out)
		sqlite3_pager_unref(p_page_in)
		return rc
	}
}

@[c:'sqlite3BtreeDelete']
fn sqlite3_btree_delete(p_cur &BtCursor, flags U8) int {
	p := p_cur.pBtree
	p_bt := p.pBt
	rc := 0
	p_page := &MemPage(0)
	p_cell := &u8(0)
	i_cell_idx := 0
	i_cell_depth := 0
	info := CellInfo{}
	b_preserve := U8(0)
	if int(p_cur.eState) != 0 {
		if int(p_cur.eState) >= 3 {
			rc = btree_restore_cursor_position(p_cur)
			if rc || int(p_cur.eState) != 0 {
				return rc
			}
		} else {
			return sqlite3_corrupt_error(9865)
		}
	}
	i_cell_depth = int(p_cur.iPage)
	i_cell_idx = int(p_cur.ix)
	p_page = p_cur.pPage
	if int(p_page.nCell) <= i_cell_idx {
		return sqlite3_corrupt_error(9874)
	}
	p_cell = (p_page.aData + (int(p_page.maskPage) & (int((unsafe { p_page.aCellIdx + (2 * i_cell_idx) })[0]) << 8 | int((unsafe { p_page.aCellIdx + (2 * i_cell_idx) })[1]))))
	if p_page.nFree < 0 && btree_compute_free_space(p_page) {
		return sqlite3_corrupt_error(9878)
	}
	if usize(p_cell) < usize(unsafe { p_page.aCellIdx + p_page.nCell }) {
		return sqlite3_corrupt_error(9881)
	}
	b_preserve = U8((int(flags) & 2) != 0)
	if b_preserve {
		if !p_page.leaf || (p_page.nFree + int(p_page.xCellSize(p_page, unsafe { &U8(p_cell) })) + 2) > int((p_bt.usableSize * u32(2) / u32(3))) || int(p_page.nCell) == 1 {
			rc = save_cursor_key(p_cur)
			if rc {
				return rc
			}
		} else {
			b_preserve = U8(2)
		}
	}
	if !p_page.leaf {
		rc = sqlite3_btree_previous(p_cur, 0)
		if rc {
			return rc
		}
	}
	if int(p_cur.curFlags) & 32 {
		rc = save_all_cursors(p_bt, p_cur.pgnoRoot, p_cur)
		if rc {
			return rc
		}
	}
	if usize(p_cur.pKeyInfo) == usize(0) && int(p.hasIncrblobCur) {
		invalidate_incrblob_cursors(p, p_cur.pgnoRoot, p_cur.info.nKey, 0)
	}
	rc = sqlite3_pager_write(p_page.pDbPage)
	if rc {
		return rc
	}
	p_page.xParseCell(p_page, unsafe { &U8(p_cell) }, &info)
	if u32(info.nLocal) != info.nPayload {
		rc = clear_cell_overflow(p_page, p_cell, &info)
	} else {
		rc = 0
	}
	0
	drop_cell(p_page, i_cell_idx, int(info.nSize), &rc)
	if rc {
		return rc
	}
	if !p_page.leaf {
		p_leaf := p_cur.pPage
		n_cell := 0
		n := Pgno(0)
		p_tmp := &u8(0)
		if p_leaf.nFree < 0 {
			rc = btree_compute_free_space(p_leaf)
			if rc {
				return rc
			}
		}
		if i_cell_depth < int(p_cur.iPage) - 1 {
			n = p_cur.apPage[i_cell_depth + 1].pgno
		} else {
			n = p_cur.pPage.pgno
		}
		p_cell = (p_leaf.aData + (int(p_leaf.maskPage) & (int((unsafe { p_leaf.aCellIdx + (2 * (int(p_leaf.nCell) - 1)) })[0]) << 8 | int((unsafe { p_leaf.aCellIdx + (2 * (int(p_leaf.nCell) - 1)) })[1]))))
		if usize(p_cell) < usize(unsafe { p_leaf.aData + 4 }) {
			return sqlite3_corrupt_error(9972)
		}
		n_cell = int(p_leaf.xCellSize(p_leaf, unsafe { &U8(p_cell) }))
		p_tmp = p_bt.pTmpSpace
		rc = sqlite3_pager_write(p_leaf.pDbPage)
		if rc == 0 {
			rc = insert_cell(p_page, i_cell_idx, unsafe { &U8(p_cell - 4) }, n_cell + 4, unsafe { &U8(p_tmp) }, n)
		}
		drop_cell(p_leaf, int(p_leaf.nCell) - 1, n_cell, &rc)
		if rc {
			return rc
		}
	}
	if p_cur.pPage.nFree * 3 <= int(p_cur.pBt.usableSize) * 2 {
		rc = 0
	} else {
		rc = balance(p_cur)
	}
	if rc == 0 && int(p_cur.iPage) > i_cell_depth {
		release_page_not_null(p_cur.pPage)
		p_cur.iPage--
		for int(p_cur.iPage) > i_cell_depth {
			release_page(p_cur.apPage[p_cur.iPage--])
		}
		p_cur.pPage = p_cur.apPage[p_cur.iPage]
		rc = balance(p_cur)
	}
	if rc == 0 {
		if int(b_preserve) > 1 {
			p_cur.eState = U8(2)
			if i_cell_idx >= int(p_page.nCell) {
				p_cur.skipNext = -1
				p_cur.ix = U16(int(p_page.nCell) - 1)
			} else {
				p_cur.skipNext = 1
			}
		} else {
			rc = move_to_root(p_cur)
			if b_preserve {
				btree_release_all_cursor_pages(p_cur)
				p_cur.eState = U8(3)
			}
			if rc == 16 {
				rc = 0
			}
		}
	}
	return rc
}

@[c:'btreeCreateTable']
fn btree_create_table(p &Btree, pi_table &Pgno, create_tab_flags int) int {
	p_bt := p.pBt
	p_root := &MemPage(0)
	pgno_root := Pgno(0)
	rc := 0
	ptf_flags := 0
	if p_bt.autoVacuum {
		pgno_move := Pgno(0)
		p_page_move := &MemPage(0)
		invalidate_all_overflow_cache(p_bt)
		sqlite3_btree_get_meta(p, 4, &pgno_root)
		if pgno_root > btree_pagecount(p_bt) {
			return sqlite3_corrupt_error(10088)
		}
		pgno_root++
		for pgno_root == ptrmap_pageno(p_bt, pgno_root) || pgno_root == (Pgno(((u32(sqlite3PendingByte) / p_bt.pageSize) + u32(1)))) {
			pgno_root++
		}
		rc = allocate_btree_page(p_bt, &&MemPage(&&MemPage(c2v_address_of(&p_page_move))), &pgno_move, pgno_root, U8(1))
		if rc != 0 {
			return rc
		}
		if pgno_move != pgno_root {
			e_type := U8(0)
			i_ptr_page := Pgno(0)
			rc = save_all_cursors(p_bt, Pgno(0), unsafe { nil })
			release_page(p_page_move)
			if rc != 0 {
				return rc
			}
			rc = btree_get_page(p_bt, pgno_root, &&MemPage(&&MemPage(c2v_address_of(&p_root))), 0)
			if rc != 0 {
				return rc
			}
			rc = ptrmap_get(p_bt, pgno_root, &e_type, &i_ptr_page)
			if int(e_type) == 1 || int(e_type) == 2 {
				rc = sqlite3_corrupt_error(10136)
			}
			if rc != 0 {
				release_page(p_root)
				return rc
			}
			rc = relocate_page(p_bt, p_root, e_type, i_ptr_page, pgno_move, 0)
			release_page(p_root)
			if rc != 0 {
				return rc
			}
			rc = btree_get_page(p_bt, pgno_root, &&MemPage(&&MemPage(c2v_address_of(&p_root))), 0)
			if rc != 0 {
				return rc
			}
			rc = sqlite3_pager_write(p_root.pDbPage)
			if rc != 0 {
				release_page(p_root)
				return rc
			}
		} else {
			p_root = p_page_move
		}
		ptrmap_put(p_bt, pgno_root, U8(1), Pgno(0), &rc)
		if rc {
			release_page(p_root)
			return rc
		}
		rc = sqlite3_btree_update_meta(p, 4, pgno_root)
		if rc {
			release_page(p_root)
			return rc
		}
	} else {
		rc = allocate_btree_page(p_bt, &&MemPage(&&MemPage(c2v_address_of(&p_root))), &pgno_root, Pgno(1), U8(0))
		if rc {
			return rc
		}
	}
	if create_tab_flags & 1 {
		ptf_flags = 1 | 4 | 8
	} else {
		ptf_flags = 2 | 8
	}
	zero_page(p_root, ptf_flags)
	sqlite3_pager_unref(p_root.pDbPage)
	unsafe { *pi_table = pgno_root }
	return 0
}

@[c:'sqlite3BtreeCreateTable']
fn sqlite3_btree_create_table(p &Btree, pi_table &Pgno, flags int) int {
	rc := 0
	sqlite3_btree_enter(p)
	rc = btree_create_table(p, pi_table, flags)
	sqlite3_btree_leave(p)
	return rc
}

@[c:'clearDatabasePage']
fn clear_database_page(p_bt &BtShared, pgno Pgno, free_page_flag int, pn_change &I64) int {
	p_page := &MemPage(0)
	rc := 0
	p_cell := &u8(0)
	i := 0
	hdr := 0
	info := CellInfo{}
	if pgno > btree_pagecount(p_bt) {
		return sqlite3_corrupt_error(10226)
	}
	rc = get_and_init_page(p_bt, pgno, &&MemPage(&&MemPage(c2v_address_of(&p_page))), 0)
	if rc {
		return rc
	}
	if (int(p_bt.openFlags) & 4) == 0 && sqlite3_pager_page_refcount(p_page.pDbPage) != (1 + int((pgno == Pgno(1)))) {
		rc = sqlite3_corrupt_error(10233)
		unsafe { goto cleardatabasepage_out
		 }
	}
	hdr = int(p_page.hdrOffset)
	for i = 0; i < int(p_page.nCell); i++ {
		p_cell = (p_page.aData + (int(p_page.maskPage) & (int((unsafe { p_page.aCellIdx + (2 * i) })[0]) << 8 | int((unsafe { p_page.aCellIdx + (2 * i) })[1]))))
		if !p_page.leaf {
			rc = clear_database_page(p_bt, sqlite3_get4byte(p_cell), 1, pn_change)
			if rc {
				unsafe { goto cleardatabasepage_out
				 }
			}
		}
		p_page.xParseCell(p_page, unsafe { &U8(p_cell) }, &info)
		if u32(info.nLocal) != info.nPayload {
			rc = clear_cell_overflow(p_page, p_cell, &info)
		} else {
			rc = 0
		}
		0
		if rc {
			unsafe { goto cleardatabasepage_out
			 }
		}
	}
	if !p_page.leaf {
		rc = clear_database_page(p_bt, sqlite3_get4byte(unsafe { p_page.aData + (hdr + 8) }), 1, pn_change)
		if rc {
			unsafe { goto cleardatabasepage_out
			 }
		}
		if p_page.intKey {
			pn_change = 0
		}
	}
	if pn_change {
		0
		unsafe { *pn_change += I64(p_page.nCell) }
	}
	if free_page_flag {
		free_page(p_page, &rc)
	} else {
		rc = sqlite3_pager_write(p_page.pDbPage)
		if rc == 0 {
			zero_page(p_page, int(p_page.aData[hdr]) | 8)
		}
	}
	cleardatabasepage_out:
	release_page(p_page)
	return rc
}

@[c:'sqlite3BtreeClearTable']
fn sqlite3_btree_clear_table(p &Btree, i_table int, pn_change &I64) int {
	rc := 0
	p_bt := p.pBt
	sqlite3_btree_enter(p)
	rc = save_all_cursors(p_bt, Pgno(i_table), unsafe { nil })
	if 0 == rc {
		if p.hasIncrblobCur {
			invalidate_incrblob_cursors(p, Pgno(i_table), I64(0), 1)
		}
		rc = clear_database_page(p_bt, Pgno(i_table), 0, pn_change)
	}
	sqlite3_btree_leave(p)
	return rc
}

@[c:'sqlite3BtreeClearTableOfCursor']
fn sqlite3_btree_clear_table_of_cursor(p_cur &BtCursor) int {
	return sqlite3_btree_clear_table(p_cur.pBtree, int(p_cur.pgnoRoot), unsafe { nil })
}

@[c:'btreeDropTable']
fn btree_drop_table(p &Btree, i_table Pgno, pi_moved &int) int {
	rc := 0
	p_page := unsafe { &MemPage(nil) }
	p_bt := p.pBt
	if i_table > btree_pagecount(p_bt) {
		return sqlite3_corrupt_error(10337)
	}
	rc = sqlite3_btree_clear_table(p, int(i_table), unsafe { nil })
	if rc {
		return rc
	}
	rc = btree_get_page(p_bt, Pgno(i_table), &&MemPage(&&MemPage(c2v_address_of(&p_page))), 0)
	if rc {
		release_page(p_page)
		return rc
	}
	unsafe { *pi_moved = 0 }
	if p_bt.autoVacuum {
		max_root_pgno := Pgno(0)
		sqlite3_btree_get_meta(p, 4, &max_root_pgno)
		if i_table == max_root_pgno {
			free_page(p_page, &rc)
			release_page(p_page)
			if rc != 0 {
				return rc
			}
		} else {
			p_move := &MemPage(0)
			release_page(p_page)
			rc = btree_get_page(p_bt, max_root_pgno, &&MemPage(&&MemPage(c2v_address_of(&p_move))), 0)
			if rc != 0 {
				return rc
			}
			rc = relocate_page(p_bt, p_move, U8(1), Pgno(0), i_table, 0)
			release_page(p_move)
			if rc != 0 {
				return rc
			}
			p_move = 0
			rc = btree_get_page(p_bt, max_root_pgno, &&MemPage(&&MemPage(c2v_address_of(&p_move))), 0)
			free_page(p_move, &rc)
			release_page(p_move)
			if rc != 0 {
				return rc
			}
			unsafe { *pi_moved = int(max_root_pgno) }
		}
		max_root_pgno--
		for max_root_pgno == (Pgno(((u32(sqlite3PendingByte) / p_bt.pageSize) + u32(1)))) || (ptrmap_pageno(p_bt, max_root_pgno) == max_root_pgno) {
			max_root_pgno--
		}
		rc = sqlite3_btree_update_meta(p, 4, max_root_pgno)
	} else {
		free_page(p_page, &rc)
		release_page(p_page)
	}
	return rc
}

@[c:'sqlite3BtreeDropTable']
fn sqlite3_btree_drop_table(p &Btree, i_table int, pi_moved &int) int {
	rc := 0
	sqlite3_btree_enter(p)
	rc = btree_drop_table(p, Pgno(i_table), pi_moved)
	sqlite3_btree_leave(p)
	return rc
}

@[c:'sqlite3BtreeGetMeta']
fn sqlite3_btree_get_meta(p &Btree, idx int, p_meta &u32) {
	p_bt := p.pBt
	sqlite3_btree_enter(p)
	if idx == 15 {
		unsafe { *p_meta = sqlite3_pager_data_version(p_bt.pPager) + p.iBDataVersion }
	} else {
		unsafe { *p_meta = sqlite3_get4byte(p_bt.pPage1.aData + (36 + idx * 4)) }
	}
	sqlite3_btree_leave(p)
}

@[c:'sqlite3BtreeUpdateMeta']
fn sqlite3_btree_update_meta(p &Btree, idx int, i_meta u32) int {
	p_bt := p.pBt
	p_p1 := &u8(0)
	rc := 0
	sqlite3_btree_enter(p)
	p_p1 = p_bt.pPage1.aData
	rc = sqlite3_pager_write(p_bt.pPage1.pDbPage)
	if rc == 0 {
		sqlite3_put4byte(unsafe { &U8(p_p1 + (36 + idx * 4)) }, i_meta)
		if idx == 7 {
			p_bt.incrVacuum = U8(i_meta)
		}
	}
	sqlite3_btree_leave(p)
	return rc
}

@[c:'sqlite3BtreeCount']
fn sqlite3_btree_count(db &Sqlite3, p_cur &BtCursor, pn_entry &I64) int {
	n_entry := I64(0)
	rc := 0
	rc = move_to_root(p_cur)
	if rc == 16 {
		unsafe { *pn_entry = I64(0) }
		return 0
	}
	for rc == 0 && !C.c2v_atomic_load_n__int_int_int((&db.u1.isInterrupted), 0) {
		i_idx := 0
		p_page := &MemPage(0)
		p_page = p_cur.pPage
		if int(p_page.leaf) || !p_page.intKey {
			n_entry += I64(p_page.nCell)
		}
		if p_page.leaf {
			for {
				if int(p_cur.iPage) == 0 {
					unsafe { *pn_entry = n_entry }
					return move_to_root(p_cur)
				}
				move_to_parent(p_cur)
				if !(int(p_cur.ix) >= int(p_cur.pPage.nCell)) {
					break
				}
			}
			p_cur.ix++
			p_page = p_cur.pPage
		}
		i_idx = int(p_cur.ix)
		if i_idx == int(p_page.nCell) {
			rc = move_to_child(p_cur, sqlite3_get4byte(unsafe { p_page.aData + (int(p_page.hdrOffset) + 8) }))
		} else {
			rc = move_to_child(p_cur, sqlite3_get4byte((p_page.aData + (int(p_page.maskPage) & (int((unsafe { p_page.aCellIdx + (2 * i_idx) })[0]) << 8 | int((unsafe { p_page.aCellIdx + (2 * i_idx) })[1]))))))
		}
	}
	return rc
}

@[c:'sqlite3BtreePager']
fn sqlite3_btree_pager(p &Btree) &Pager {
	return p.pBt.pPager
}

@[c:'checkOom']
fn check_oom(p_check &IntegrityCk) {
	p_check.rc = 7
	p_check.mxErr = 0
	if p_check.nErr == 0 {
		p_check.nErr++
	}
}

@[c:'checkProgress']
fn check_progress(p_check &IntegrityCk) {
	db := p_check.db
	if C.c2v_atomic_load_n__int_int_int((&db.u1.isInterrupted), 0) {
		p_check.rc = 9
		p_check.nErr++
		p_check.mxErr = 0
	}
	if db.xProgress {
		p_check.nStep++
		if (p_check.nStep % db.nProgressOps) == u32(0) && db.xProgress(voidptr(db.pProgressArg)) {
			p_check.rc = 9
			p_check.nErr++
			p_check.mxErr = 0
		}
	}
}

@[c:'checkAppendMsg']
@[c2v_variadic]
fn check_append_msg(p_check &IntegrityCk, z_format &i8, ...) {
	ap := C.va_list{}
	check_progress(p_check)
	if !p_check.mxErr {
		return
	}
	p_check.mxErr--
	p_check.nErr++
	C.va_start(ap, z_format)
	if p_check.errMsg.nChar {
		sqlite3_str_append(unsafe { &Sqlite3_str(&p_check.errMsg) }, c'\n', 1)
	}
	if p_check.zPfx {
		sqlite3_str_appendf(unsafe { &Sqlite3_str(&p_check.errMsg) }, p_check.zPfx, p_check.v0, p_check.v1, p_check.v2)
	}
	sqlite3_str_vappendf(unsafe { &Sqlite3_str(&p_check.errMsg) }, z_format, ap)
	C.va_end(ap)
	if int(p_check.errMsg.accError) == 7 {
		check_oom(p_check)
	}
}

@[c:'getPageReferenced']
fn get_page_referenced(p_check &IntegrityCk, i_pg Pgno) int {
	return int(p_check.aPgRef[i_pg / Pgno(8)]) & (1 << u32((i_pg & Pgno(7))))
}

@[c:'setPageReferenced']
fn set_page_referenced(p_check &IntegrityCk, i_pg Pgno) {
	p_check.aPgRef[i_pg / Pgno(8)] |= (1 << u32((i_pg & Pgno(7))))
}

@[c:'checkRef']
fn check_ref(p_check &IntegrityCk, i_page Pgno) int {
	if i_page > p_check.nCkPage || i_page == Pgno(0) {
		check_append_msg(p_check, c'invalid page number %u', i_page)
		return 1
	}
	if get_page_referenced(p_check, i_page) {
		check_append_msg(p_check, c'2nd reference to page %u', i_page)
		return 1
	}
	set_page_referenced(p_check, i_page)
	return 0
}

@[c:'checkPtrmap']
fn check_ptrmap(p_check &IntegrityCk, i_child Pgno, e_type U8, i_parent Pgno) {
	rc := 0
	e_ptrmap_type := U8(0)
	i_ptrmap_parent := Pgno(0)
	rc = ptrmap_get(p_check.pBt, i_child, &e_ptrmap_type, &i_ptrmap_parent)
	if rc != 0 {
		if rc == 7 || rc == (10 | (12 << 8)) {
			check_oom(p_check)
		}
		check_append_msg(p_check, c'Failed to read ptrmap key=%u', i_child)
		return
	}
	if int(e_ptrmap_type) != int(e_type) || i_ptrmap_parent != i_parent {
		check_append_msg(p_check, c'Bad ptr map entry key=%u expected=(%u,%u) got=(%u,%u)', i_child, int(e_type), i_parent, int(e_ptrmap_type), i_ptrmap_parent)
	}
}

@[c:'checkList']
fn check_list(p_check &IntegrityCk, is_free_list int, i_page Pgno, n u32) {
	i := 0
	expected := n
	n_err_at_start := p_check.nErr
	for i_page != Pgno(0) && p_check.mxErr {
		p_ovfl_page := &DbPage(0)
		p_ovfl_data := &u8(0)
		if check_ref(p_check, i_page) {
			break
		}
		n--
		if sqlite3_pager_get(p_check.pPager, Pgno(i_page), &&DbPage(&&DbPage(c2v_address_of(&p_ovfl_page))), 0) {
			check_append_msg(p_check, c'failed to get page %u', i_page)
			break
		}
		p_ovfl_data = &u8(sqlite3_pager_get_data(p_ovfl_page))
		if is_free_list {
			n_2 := u32(sqlite3_get4byte(unsafe { p_ovfl_data + 4 }))
			if p_check.pBt.autoVacuum {
				check_ptrmap(p_check, i_page, U8(2), Pgno(0))
			}
			if n_2 > p_check.pBt.usableSize / u32(4) - u32(2) {
				check_append_msg(p_check, c'freelist leaf count too big on page %u', i_page)
				n--
			} else {
				for i = 0; i < int(n_2); i++ {
					i_free_page := sqlite3_get4byte(unsafe { p_ovfl_data + (8 + i * 4) })
					if p_check.pBt.autoVacuum {
						check_ptrmap(p_check, i_free_page, U8(2), Pgno(0))
					}
					check_ref(p_check, i_free_page)
				}
				n -= n_2
			}
		} else {
			if int(p_check.pBt.autoVacuum) && n > u32(0) {
				i = int(sqlite3_get4byte(p_ovfl_data))
				check_ptrmap(p_check, Pgno(i), U8(4), i_page)
			}
		}
		i_page = sqlite3_get4byte(p_ovfl_data)
		sqlite3_pager_unref(p_ovfl_page)
	}
	if n && n_err_at_start == p_check.nErr {
		check_append_msg(p_check, c'%s is %u but should be %u', voidptr(if is_free_list {
			c'size'
		} else {
			c'overflow list length'
		}), expected - n, expected)
	}
}

@[c:'btreeHeapInsert']
fn btree_heap_insert(a_heap &u32, x u32) {
	j := u32(0)
	i := u32(0)

	i = c2v_prefix_add(unsafe { &a_heap[0] }, u32(1))
	a_heap[i] = x
	for {
		j = i / u32(2)
		if !(j > u32(0) && a_heap[j] > a_heap[i]) {
			break
		}
		x = a_heap[j]
		a_heap[j] = a_heap[i]
		a_heap[i] = x
		i = j
	}
}

@[c:'btreeHeapPull']
fn btree_heap_pull(a_heap &u32, p_out &u32) int {
	j := u32(0)
	i := u32(0)
	x := u32(0)

	x = a_heap[0]
	if x == u32(0) {
		return 0
	}
	unsafe { *p_out = a_heap[1] }
	a_heap[1] = a_heap[x]
	a_heap[x] = u32(4294967295)
	a_heap[0]--
	i = u32(1)
	for {
		j = i * u32(2)
		if !(j <= a_heap[0]) {
			break
		}
		if a_heap[j] > a_heap[j + u32(1)] {
			j++
		}
		if a_heap[i] < a_heap[j] {
			break
		}
		x = a_heap[i]
		a_heap[i] = a_heap[j]
		a_heap[j] = x
		i = j
	}
	return 1
}

@[c:'checkTreePage']
fn check_tree_page(p_check &IntegrityCk, i_page Pgno, pi_min_key &I64, max_key I64) int {
	p_page := unsafe { &MemPage(nil) }
	i := 0
	rc := 0
	depth := -1
	d2 := 0

	pgno := 0
	n_frag := 0
	hdr := 0
	cell_start := 0
	n_cell := 0
	do_coverage_check := 1
	key_can_be_equal := 1
	data := &U8(0)
	p_cell := &U8(0)
	p_cell_idx := &U8(0)
	p_bt := &BtShared(0)
	pc := u32(0)
	usable_size := u32(0)
	content_offset := u32(0)
	heap := unsafe { &u32(nil) }
	x := u32(0)
	prev := u32(0)

	saved_z_pfx := p_check.zPfx
	saved_v1 := int(p_check.v1)
	saved_v2 := p_check.v2
	saved_is_init := U8(0)
	check_progress(p_check)
	if p_check.mxErr == 0 {
		unsafe { goto end_of_check
		 }
	}
	p_bt = p_check.pBt
	usable_size = p_bt.usableSize
	if i_page == Pgno(0) {
		return 0
	}
	if check_ref(p_check, i_page) {
		return 0
	}
	p_check.zPfx = c'Tree %u page %u: '
	p_check.v1 = i_page
	rc = btree_get_page(p_bt, i_page, &&MemPage(&&MemPage(c2v_address_of(&p_page))), 0)
	if rc != 0 {
		check_append_msg(p_check, c'unable to get the page. error code=%d', rc)
		if rc == (10 | (12 << 8)) {
			p_check.rc = 7
		}
		unsafe { goto end_of_check
		 }
	}
	saved_is_init = p_page.isInit
	p_page.isInit = U8(0)
	rc = btree_init_page(p_page)
	if rc != 0 {
		check_append_msg(p_check, c'btreeInitPage() returns error code %d', rc)
		unsafe { goto end_of_check
		 }
	}
	rc = btree_compute_free_space(p_page)
	if rc != 0 {
		check_append_msg(p_check, c'free space corruption', rc)
		unsafe { goto end_of_check
		 }
	}
	data = p_page.aData
	hdr = int(p_page.hdrOffset)
	p_check.zPfx = c'Tree %u page %u cell %u: '
	content_offset = u32(((((int((int((unsafe { data + (hdr + 5) })[0]) << 8 | int((unsafe { data + (hdr + 5) })[1])))) - 1) & 65535) + 1))
	n_cell = (int((unsafe { data + (hdr + 3) })[0]) << 8 | int((unsafe { data + (hdr + 3) })[1]))
	if int(p_page.leaf) || int(p_page.intKey) == 0 {
		p_check.nRow += I64(n_cell)
	}
	cell_start = hdr + 12 - 4 * int(p_page.leaf)
	p_cell_idx = unsafe { data + (cell_start + 2 * (n_cell - 1)) }
	if !p_page.leaf {
		pgno = int(sqlite3_get4byte(unsafe { data + (hdr + 8) }))
		if p_bt.autoVacuum {
			p_check.zPfx = c'Tree %u page %u right child: '
			check_ptrmap(p_check, Pgno(pgno), U8(5), i_page)
		}
		depth = check_tree_page(p_check, Pgno(pgno), &max_key, max_key)
		key_can_be_equal = 0
	} else {
		heap = p_check.heap
		heap[0] = u32(0)
	}
	for i = n_cell - 1; i >= 0 && p_check.mxErr; i-- {
		info := CellInfo{}
		p_check.v2 = i
		pc = u32((int(p_cell_idx[0]) << 8 | int(p_cell_idx[1])))
		c2v_pointer_prefix(voidptr(&p_cell_idx), p_cell_idx, isize(-(2)))
		if pc < content_offset || pc > usable_size - u32(4) {
			check_append_msg(p_check, c'Offset %u out of range %u..%u', pc, content_offset, usable_size - u32(4))
			do_coverage_check = 0
			continue
		}
		p_cell = unsafe { data + pc }
		p_page.xParseCell(p_page, p_cell, &info)
		if pc + u32(info.nSize) > usable_size {
			check_append_msg(p_check, c'Extends off end of page')
			do_coverage_check = 0
			continue
		}
		if p_page.intKey {
			if if key_can_be_equal { (info.nKey > max_key) } else { (info.nKey >= max_key) } {
				check_append_msg(p_check, c'Rowid %lld out of order', info.nKey)
			}
			max_key = info.nKey
			key_can_be_equal = 0
		}
		if info.nPayload > u32(info.nLocal) {
			n_page := u32(0)
			pgno_ovfl := Pgno(0)
			n_page = (info.nPayload - u32(info.nLocal) + usable_size - u32(5)) / (usable_size - u32(4))
			pgno_ovfl = sqlite3_get4byte(unsafe { p_cell + (int(info.nSize) - 4) })
			if p_bt.autoVacuum {
				check_ptrmap(p_check, pgno_ovfl, U8(3), i_page)
			}
			check_list(p_check, 0, pgno_ovfl, n_page)
		}
		if !p_page.leaf {
			pgno = int(sqlite3_get4byte(p_cell))
			if p_bt.autoVacuum {
				check_ptrmap(p_check, Pgno(pgno), U8(5), i_page)
			}
			d2 = check_tree_page(p_check, Pgno(pgno), &max_key, max_key)
			key_can_be_equal = 0
			if d2 != depth {
				check_append_msg(p_check, c'Child page depth differs')
				depth = d2
			}
		} else {
			btree_heap_insert(heap, (pc << 16) | (pc + u32(info.nSize) - u32(1)))
		}
	}
	unsafe { *pi_min_key = max_key }
	p_check.zPfx = 0
	if do_coverage_check && p_check.mxErr > 0 {
		if !p_page.leaf {
			heap = p_check.heap
			heap[0] = u32(0)
			for i = n_cell - 1; i >= 0; i-- {
				size := u32(0)
				pc = u32((int((unsafe { data + (cell_start + i * 2) })[0]) << 8 | int((unsafe { data + (cell_start + i * 2) })[1])))
				size = u32(p_page.xCellSize(p_page, unsafe { data + pc }))
				btree_heap_insert(heap, (pc << 16) | (pc + size - u32(1)))
			}
		}
		i = (int((unsafe { data + (hdr + 1) })[0]) << 8 | int((unsafe { data + (hdr + 1) })[1]))
		for i > 0 {
			size := 0
			j := 0

			size = (int((unsafe { data + (i + 2) })[0]) << 8 | int((unsafe { data + (i + 2) })[1]))
			btree_heap_insert(heap, ((u32(i)) << 16) | u32((i + size - 1)))
			j = (int((unsafe { data + i })[0]) << 8 | int((unsafe { data + i })[1]))
			i = j
		}
		n_frag = 0
		prev = content_offset - u32(1)
		for btree_heap_pull(heap, &x) {
			if (prev & u32(65535)) >= (x >> 16) {
				check_append_msg(p_check, c'Multiple uses for byte %u of page %u', x >> 16, i_page)
				break
			} else {
				n_frag += (x >> 16) - (prev & u32(65535)) - u32(1)
				prev = x
			}
		}
		n_frag += usable_size - (prev & u32(65535)) - u32(1)
		if heap[0] == u32(0) && n_frag != int(data[hdr + 7]) {
			check_append_msg(p_check, c'Fragmentation of %u bytes reported as %u on page %u', n_frag, int(data[hdr + 7]), i_page)
		}
	}
	end_of_check:
	if !do_coverage_check {
		p_page.isInit = saved_is_init
	}
	release_page(p_page)
	p_check.zPfx = saved_z_pfx
	p_check.v1 = Pgno(saved_v1)
	p_check.v2 = saved_v2
	return depth + 1
}

@[c:'sqlite3BtreeIntegrityCheck']
fn sqlite3_btree_integrity_check(db &Sqlite3, p &Btree, a_root &Pgno, a_cnt &Mem, n_root int, mx_err int, pn_err &int, pz_out &&u8) int {
	i := Pgno(0)
	s_check := IntegrityCk{}
	p_bt := p.pBt
	saved_db_flags := p_bt.db.flags
	z_err := [100]i8{}
	b_partial := 0
	b_ck_freelist := 1
	0
	if a_root[0] == Pgno(0) {
		b_partial = 1
		if a_root[1] != Pgno(1) {
			b_ck_freelist = 0
		}
	}
	sqlite3_btree_enter(p)
	0
	C.memset(voidptr(&s_check), 0, sizeof(s_check))
	s_check.db = db
	s_check.pBt = p_bt
	s_check.pPager = p_bt.pPager
	s_check.nCkPage = btree_pagecount(s_check.pBt)
	s_check.mxErr = mx_err
	sqlite3_str_accum_init(&s_check.errMsg, unsafe { nil }, unsafe { &i8(&z_err[0]) }, int(sizeof([100]i8)), 1000000000)
	s_check.errMsg.printfFlags = U8(1)
	if s_check.nCkPage == Pgno(0) {
		unsafe { goto integrity_ck_cleanup
		 }
	}
	s_check.aPgRef = sqlite3_malloc_zero(U64((s_check.nCkPage / Pgno(8)) + Pgno(1)))
	if isnil(s_check.aPgRef) {
		check_oom(&s_check)
		unsafe { goto integrity_ck_cleanup
		 }
	}
	s_check.heap = &u32(sqlite3_page_malloc(int(p_bt.pageSize)))
	if usize(s_check.heap) == usize(0) {
		check_oom(&s_check)
		unsafe { goto integrity_ck_cleanup
		 }
	}
	i = (Pgno(((u32(sqlite3PendingByte) / p_bt.pageSize) + u32(1))))
	if i <= s_check.nCkPage {
		set_page_referenced(&s_check, i)
	}
	if b_ck_freelist {
		s_check.zPfx = c'Freelist: '
		check_list(&s_check, 1, sqlite3_get4byte(unsafe { p_bt.pPage1.aData + 32 }), sqlite3_get4byte(unsafe { p_bt.pPage1.aData + 36 }))
		s_check.zPfx = 0
	}
	if !b_partial {
		if p_bt.autoVacuum {
			mx := Pgno(0)
			mx_in_hdr := Pgno(0)
			for i = Pgno(0); int(i) < n_root; i++ {
				if mx < a_root[i] {
					mx = a_root[i]
				}
			}
			mx_in_hdr = sqlite3_get4byte(unsafe { p_bt.pPage1.aData + 52 })
			if mx != mx_in_hdr {
				check_append_msg(&s_check, c'max rootpage (%u) disagrees with header (%u)', mx, mx_in_hdr)
			}
		} else if sqlite3_get4byte(unsafe { p_bt.pPage1.aData + 64 }) != u32(0) {
			check_append_msg(&s_check, c'incremental_vacuum enabled with a max rootpage of zero')
		}
	}
	0
	p_bt.db.flags &= ~U64(2097152)
	for i = Pgno(0); int(i) < n_root && s_check.mxErr; i++ {
		s_check.nRow = I64(0)
		if a_root[i] {
			not_used := I64(0)
			if int(p_bt.autoVacuum) && a_root[i] > Pgno(1) && !b_partial {
				check_ptrmap(&s_check, a_root[i], U8(1), Pgno(0))
			}
			s_check.v0 = a_root[i]
			check_tree_page(&s_check, a_root[i], &not_used, (I64(u32(4294967295)) | ((I64(2147483647)) << 32)))
		}
		sqlite3_mem_set_array_int64(unsafe { &Sqlite3_value(a_cnt) }, int(i), s_check.nRow)
	}
	p_bt.db.flags = saved_db_flags
	if !b_partial {
		for i = Pgno(1); i <= s_check.nCkPage && s_check.mxErr; i++ {
			if get_page_referenced(&s_check, i) == 0 && (ptrmap_pageno(p_bt, i) != i || !p_bt.autoVacuum) {
				check_append_msg(&s_check, c'Page %u: never used', i)
			}
			if get_page_referenced(&s_check, i) != 0 && (ptrmap_pageno(p_bt, i) == i && int(p_bt.autoVacuum)) {
				check_append_msg(&s_check, c'Page %u: pointer map referenced', i)
			}
		}
	}
	integrity_ck_cleanup:
	sqlite3_page_free(voidptr(s_check.heap))
	sqlite3_free(voidptr(s_check.aPgRef))
	unsafe { *pn_err = s_check.nErr }
	if s_check.nErr == 0 {
		sqlite3_str_reset(unsafe { &Sqlite3_str(&s_check.errMsg) })
		unsafe { *pz_out = 0 }
	} else {
		unsafe { *pz_out = sqlite3_str_accum_finish(&s_check.errMsg) }
	}
	sqlite3_btree_leave(p)
	return s_check.rc
}

@[c:'sqlite3BtreeGetFilename']
fn sqlite3_btree_get_filename(p &Btree) &i8 {
	return sqlite3_pager_filename(p.pBt.pPager, 1)
}

@[c:'sqlite3BtreeGetJournalname']
fn sqlite3_btree_get_journalname(p &Btree) &i8 {
	return sqlite3_pager_journalname(p.pBt.pPager)
}

@[c:'sqlite3BtreeTxnState']
fn sqlite3_btree_txn_state(p &Btree) int {
	return if p { int(p.inTrans) } else { 0 }
}

@[c:'sqlite3BtreeCheckpoint']
fn sqlite3_btree_checkpoint(p &Btree, e_mode int, pn_log &int, pn_ckpt &int) int {
	rc := 0
	if p {
		p_bt := p.pBt
		sqlite3_btree_enter(p)
		if int(p_bt.inTransaction) != 0 {
			rc = 6
		} else {
			rc = sqlite3_pager_checkpoint(p_bt.pPager, p.db, e_mode, pn_log, pn_ckpt)
		}
		sqlite3_btree_leave(p)
	}
	return rc
}

@[c:'sqlite3BtreeIsInBackup']
fn sqlite3_btree_is_in_backup(p &Btree) int {
	return int(p.nBackup != 0)
}

@[c:'sqlite3BtreeSchema']
fn sqlite3_btree_schema(p &Btree, n_bytes int, x_free fn (voidptr)) voidptr {
	p_bt := p.pBt
	sqlite3_btree_enter(p)
	if isnil(p_bt.pSchema) && n_bytes {
		p_bt.pSchema = sqlite3_db_malloc_zero(unsafe { nil }, U64(n_bytes))
		p_bt.xFreeSchema = x_free
	}
	sqlite3_btree_leave(p)
	return p_bt.pSchema
}

@[c:'sqlite3BtreeSchemaLocked']
fn sqlite3_btree_schema_locked(p &Btree) int {
	rc := 0

	sqlite3_btree_enter(p)
	rc = query_shared_cache_table_lock(p, Pgno(1), U8(1))
	sqlite3_btree_leave(p)
	return rc
}

@[c:'sqlite3BtreeLockTable']
fn sqlite3_btree_lock_table(p &Btree, i_tab int, is_write_lock U8) int {
	rc := 0
	if p.sharable {
		lock_type := U8(1 + int(is_write_lock))
		sqlite3_btree_enter(p)
		rc = query_shared_cache_table_lock(p, Pgno(i_tab), lock_type)
		if rc == 0 {
			rc = set_shared_cache_table_lock(p, Pgno(i_tab), lock_type)
		}
		sqlite3_btree_leave(p)
	}
	return rc
}

@[c:'sqlite3BtreePutData']
fn sqlite3_btree_put_data(p_csr &BtCursor, offset u32, amt u32, z voidptr) int {
	c2v_gc_register_thread()
	rc := 0
	rc = (if int(p_csr.eState) >= 3 { btree_restore_cursor_position(p_csr) } else { 0 })
	if rc != 0 {
		return rc
	}
	if int(p_csr.eState) != 0 {
		return 4
	}
	save_all_cursors(p_csr.pBt, p_csr.pgnoRoot, p_csr)
	if (int(p_csr.curFlags) & 1) == 0 {
		return 8
	}
	return access_payload(p_csr, offset, amt, &u8(z), 1)
}

@[c:'sqlite3BtreeIncrblobCursor']
fn sqlite3_btree_incrblob_cursor(p_cur &BtCursor) {
	p_cur.curFlags |= 16
	p_cur.pBtree.hasIncrblobCur = U8(1)
}

@[c:'sqlite3BtreeSetVersion']
fn sqlite3_btree_set_version(p_btree &Btree, i_version int) int {
	p_bt := p_btree.pBt
	rc := 0
	p_bt.btsFlags &= ~32
	if i_version == 1 {
		p_bt.btsFlags |= 32
	}
	rc = sqlite3_btree_begin_trans(p_btree, 0, unsafe { nil })
	if rc == 0 {
		a_data := p_bt.pPage1.aData
		if int(a_data[18]) != int(U8(i_version)) || int(a_data[19]) != int(U8(i_version)) {
			rc = sqlite3_btree_begin_trans(p_btree, 2, unsafe { nil })
			if rc == 0 {
				rc = sqlite3_pager_write(p_bt.pPage1.pDbPage)
				if rc == 0 {
					a_data[18] = U8(i_version)
					a_data[19] = U8(i_version)
				}
			}
		}
	}
	p_bt.btsFlags &= ~32
	return rc
}

@[c:'sqlite3BtreeCursorHasHint']
fn sqlite3_btree_cursor_has_hint(p_csr &BtCursor, mask u32) int {
	return int((u32(p_csr.hints) & mask) != u32(0))
}

@[c:'sqlite3BtreeIsReadonly']
fn sqlite3_btree_is_readonly(p &Btree) int {
	return int((int(p.pBt.btsFlags) & 1) != 0)
}

@[c:'sqlite3HeaderSizeBtree']
fn sqlite3_header_size_btree() int {
	return int((((sizeof(MemPage)) + u64(7)) & u64(~7)))
}

@[c:'sqlite3BtreeClearCache']
fn sqlite3_btree_clear_cache(p &Btree) {
	p_bt := p.pBt
	if int(p_bt.inTransaction) == 0 {
		sqlite3_pager_clear_cache(p_bt.pPager)
	}
}

@[c:'sqlite3BtreeSharable']
fn sqlite3_btree_sharable(p &Btree) int {
	return int(p.sharable)
}

@[c:'sqlite3BtreeConnectionCount']
fn sqlite3_btree_connection_count(p &Btree) int {
	0
	return p.pBt.nRef
}
