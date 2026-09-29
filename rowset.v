@[translated]
module main

struct RowSetEntry {
	v      I64
	pRight &RowSetEntry
	pLeft  &RowSetEntry
}

struct RowSetChunk {
	pNextChunk &RowSetChunk
	aEntry     [42]RowSetEntry
}

struct RowSet {
	pChunk  &RowSetChunk
	db      &Sqlite3
	pEntry  &RowSetEntry
	pLast   &RowSetEntry
	pFresh  &RowSetEntry
	pForest &RowSetEntry
	nFresh  U16
	rsFlags U16
	iBatch  int
}

@[c:'sqlite3RowSetInit']
fn sqlite3_row_set_init(db &Sqlite3) &RowSet {
	p := &RowSet(sqlite3_db_malloc_raw_nn(db, U64(sizeof(RowSet))))
	if p {
		n := sqlite3_db_malloc_size(db, voidptr(p))
		p.pChunk = 0
		p.db = db
		p.pEntry = 0
		p.pLast = 0
		p.pForest = 0
		p.pFresh = &RowSetEntry(voidptr((unsafe { &i8(voidptr(p)) + (((sizeof(RowSet)) + u64(7)) & u64(~7)) })))
		p.nFresh = U16(((u64(n) - (((sizeof(RowSet)) + u64(7)) & u64(~7))) / sizeof(RowSetEntry)))
		p.rsFlags = U16(1)
		p.iBatch = 0
	}
	return p
}

@[c:'sqlite3RowSetClear']
fn sqlite3_row_set_clear(p_arg voidptr) {
	c2v_gc_register_thread()
	p := &RowSet(p_arg)
	p_chunk := &RowSetChunk(0)
	p_next_chunk := &RowSetChunk(0)

	for p_chunk = p.pChunk; p_chunk; p_chunk = p_next_chunk {
		p_next_chunk = p_chunk.pNextChunk
		sqlite3_db_free(p.db, voidptr(p_chunk))
	}
	p.pChunk = 0
	p.nFresh = U16(0)
	p.pEntry = 0
	p.pLast = 0
	p.pForest = 0
	p.rsFlags = U16(1)
}

@[c:'sqlite3RowSetDelete']
fn sqlite3_row_set_delete(p_arg voidptr) {
	c2v_gc_register_thread()
	sqlite3_row_set_clear(voidptr(p_arg))
	sqlite3_db_free((&RowSet(p_arg)).db, voidptr(p_arg))
}

@[c:'rowSetEntryAlloc']
fn row_set_entry_alloc(p &RowSet) &RowSetEntry {
	if int(p.nFresh) == 0 {
		p_new := &RowSetChunk(0)
		p_new = sqlite3_db_malloc_raw_nn(p.db, U64(sizeof(RowSetChunk)))
		if usize(p_new) == usize(0) {
			return unsafe { nil }
		}
		p_new.pNextChunk = p.pChunk
		p.pChunk = p_new
		p.pFresh = unsafe { &p_new.aEntry[0] }
		p.nFresh = U16((u64((1024 - 8)) / sizeof(RowSetEntry)))
	}
	p.nFresh--
	return c2v_pointer_postfix(voidptr(&p.pFresh), p.pFresh, isize(1))
}

@[c:'sqlite3RowSetInsert']
fn sqlite3_row_set_insert(p &RowSet, rowid I64) {
	p_entry := &RowSetEntry(0)
	p_last := &RowSetEntry(0)
	p_entry = row_set_entry_alloc(p)
	if usize(p_entry) == usize(0) {
		return
	}
	p_entry.v = rowid
	p_entry.pRight = 0
	p_last = p.pLast
	if p_last {
		if rowid <= p_last.v {
			p.rsFlags &= ~1
		}
		p_last.pRight = p_entry
	} else {
		p.pEntry = p_entry
	}
	p.pLast = p_entry
}

@[c:'rowSetEntryMerge']
fn row_set_entry_merge(pa &RowSetEntry, pb &RowSetEntry) &RowSetEntry {
	head := RowSetEntry{}
	p_tail := &RowSetEntry(0)
	p_tail = &head
	for {
		if pa.v <= pb.v {
			if pa.v < pb.v {
				p_tail.pRight = pa
				p_tail = p_tail.pRight
			}
			pa = pa.pRight
			if usize(pa) == usize(0) {
				p_tail.pRight = pb
				break
			}
		} else {
			p_tail.pRight = pb
			p_tail = p_tail.pRight
			pb = pb.pRight
			if usize(pb) == usize(0) {
				p_tail.pRight = pa
				break
			}
		}
	}
	return head.pRight
}

@[c:'rowSetEntrySort']
fn row_set_entry_sort(p_in &RowSetEntry) &RowSetEntry {
	i := u32(0)
	p_next := &RowSetEntry(0)
	a_bucket := [40]&RowSetEntry{}

	C.memset(voidptr(unsafe { &a_bucket[0] }), 0, sizeof([40]&RowSetEntry))
	for p_in {
		p_next = p_in.pRight
		p_in.pRight = 0
		for i = u32(0); a_bucket[i]; i++ {
			p_in = row_set_entry_merge(a_bucket[i], p_in)
			a_bucket[i] = 0
		}
		a_bucket[i] = p_in
		p_in = p_next
	}
	p_in = a_bucket[0]
	for i = u32(1); u64(i) < 40; i++ {
		if usize(a_bucket[i]) == usize(0) {
			continue
		}
		p_in = if p_in { row_set_entry_merge(p_in, a_bucket[i]) } else { a_bucket[i] }
	}
	return p_in
}

@[c:'rowSetTreeToList']
fn row_set_tree_to_list(p_in &RowSetEntry, pp_first &&RowSetEntry, pp_last &&RowSetEntry) {
	if p_in.pLeft {
		p := &RowSetEntry(0)
		row_set_tree_to_list(p_in.pLeft, pp_first, &&RowSetEntry(&&RowSetEntry(c2v_address_of(&p))))
		p.pRight = p_in
	} else {
		unsafe { *pp_first = p_in }
	}
	if p_in.pRight {
		row_set_tree_to_list(p_in.pRight, &&RowSetEntry(&p_in.pRight), pp_last)
	} else {
		unsafe { *pp_last = p_in }
	}
}

@[c:'rowSetNDeepTree']
fn row_set_nd_eep_tree(pp_list &&RowSetEntry, i_depth int) &RowSetEntry {
	p := &RowSetEntry(0)
	p_left := &RowSetEntry(0)
	if usize((unsafe { *pp_list })) == usize(0) {
		return unsafe { nil }
	}
	if i_depth > 1 {
		p_left = row_set_nd_eep_tree(pp_list, i_depth - 1)
		p = unsafe { *pp_list }
		if usize(p) == usize(0) {
			return p_left
		}
		p.pLeft = p_left
		unsafe { *pp_list = p.pRight }
		p.pRight = row_set_nd_eep_tree(pp_list, i_depth - 1)
	} else {
		p = unsafe { *pp_list }
		unsafe { *pp_list = p.pRight }
		p.pRight = 0
		p.pLeft = p.pRight
	}
	return p
}

@[c:'rowSetListToTree']
fn row_set_list_to_tree(p_list_param &RowSetEntry) &RowSetEntry {
	mut p_list := p_list_param
	i_depth := 0
	p := &RowSetEntry(0)
	p_left := &RowSetEntry(0)
	p = p_list
	p_list = p.pRight
	p.pRight = 0
	p.pLeft = p.pRight
	for i_depth = 1; p_list; i_depth++ {
		p_left = p
		p = p_list
		p_list = p.pRight
		p.pLeft = p_left
		p.pRight = row_set_nd_eep_tree(&&RowSetEntry(&&RowSetEntry(c2v_address_of(&p_list))), i_depth)
	}
	return p
}

@[c:'sqlite3RowSetNext']
fn sqlite3_row_set_next(p &RowSet, p_rowid &I64) int {
	if (int(p.rsFlags) & 2) == 0 {
		if (int(p.rsFlags) & 1) == 0 {
			p.pEntry = row_set_entry_sort(p.pEntry)
		}
		p.rsFlags |= 1 | 2
	}
	if p.pEntry {
		unsafe { *p_rowid = p.pEntry.v }
		p.pEntry = p.pEntry.pRight
		if usize(p.pEntry) == usize(0) {
			sqlite3_row_set_clear(voidptr(p))
		}
		return 1
	} else {
		return 0
	}
}

@[c:'sqlite3RowSetTest']
fn sqlite3_row_set_test(p_row_set &RowSet, i_batch int, i_rowid Sqlite3_int64) int {
	p := &RowSetEntry(0)
	p_tree := &RowSetEntry(0)

	if i_batch != p_row_set.iBatch {
		p = p_row_set.pEntry
		if p {
			pp_prev_tree := &p_row_set.pForest
			if (int(p_row_set.rsFlags) & 1) == 0 {
				p = row_set_entry_sort(p)
			}
			for p_tree = p_row_set.pForest; p_tree; p_tree = p_tree.pRight {
				pp_prev_tree = &p_tree.pRight
				if usize(p_tree.pLeft) == usize(0) {
					p_tree.pLeft = row_set_list_to_tree(p)
					break
				} else {
					p_aux := &RowSetEntry(0)
					p_tail := &RowSetEntry(0)

					row_set_tree_to_list(p_tree.pLeft, &&RowSetEntry(&&RowSetEntry(c2v_address_of(&p_aux))), &&RowSetEntry(&&RowSetEntry(c2v_address_of(&p_tail))))
					p_tree.pLeft = 0
					p = row_set_entry_merge(p_aux, p)
				}
			}
			if usize(p_tree) == usize(0) {
				p_tree = row_set_entry_alloc(p_row_set)
				unsafe { *pp_prev_tree = p_tree }
				if p_tree {
					p_tree.v = I64(0)
					p_tree.pRight = 0
					p_tree.pLeft = row_set_list_to_tree(p)
				}
			}
			p_row_set.pEntry = 0
			p_row_set.pLast = 0
			p_row_set.rsFlags |= 1
		}
		p_row_set.iBatch = i_batch
	}
	for p_tree = p_row_set.pForest; p_tree; p_tree = p_tree.pRight {
		p = p_tree.pLeft
		for p {
			if p.v < i_rowid {
				p = p.pRight
			} else if p.v > i_rowid {
				p = p.pLeft
			} else {
				return 1
			}
		}
	}
	return 0
}
