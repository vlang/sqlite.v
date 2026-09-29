@[translated]
module main

@[c:'sqlite3HashInit']
fn sqlite3_hash_init(p_new &Hash) {
	p_new.first = 0
	p_new.count = u32(0)
	p_new.htsize = u32(0)
	p_new.ht = 0
}

@[c:'sqlite3HashClear']
fn sqlite3_hash_clear(ph &Hash) {
	elem := &HashElem(0)
	elem = ph.first
	ph.first = 0
	sqlite3_free(voidptr(ph.ht))
	ph.ht = 0
	ph.htsize = u32(0)
	for elem {
		next_elem := elem.next
		sqlite3_free(voidptr(elem))
		elem = next_elem
	}
	ph.count = u32(0)
}

@[c:'strHash']
fn str_hash(z &i8) u32 {
	h := u32(0)
	for z[0] {
		h += u32(223 & int(u8((unsafe { *(c2v_pointer_postfix(voidptr(&z), z, isize(1))) }))))
		h *= u32(2654435761)
	}
	return h
}

@[c:'insertElement']
fn insert_element(ph &Hash, p_entry &Ht, p_new &HashElem) {
	p_head := &HashElem(0)
	if p_entry {
		p_head = unsafe { if p_entry.count { p_entry.chain } else { &HashElem(nil) } }
		p_entry.count++
		p_entry.chain = p_new
	} else {
		p_head = 0
	}
	if p_head {
		p_new.next = p_head
		p_new.prev = p_head.prev
		if p_head.prev {
			p_head.prev.next = p_new
		} else {
			ph.first = p_new
		}
		p_head.prev = p_new
	} else {
		p_new.next = ph.first
		if ph.first {
			ph.first.prev = p_new
		}
		p_new.prev = 0
		ph.first = p_new
	}
}

fn rehash(ph &Hash, new_size u32) int {
	new_ht := &Ht(0)
	elem := &HashElem(0)
	next_elem := &HashElem(0)

	if u64(new_size) * sizeof(Ht) > u64(1024) {
		new_size = u32(u64(1024) / sizeof(Ht))
	}
	if new_size == ph.htsize {
		return 0
	}
	sqlite3_begin_benign_malloc()
	new_ht = &Ht(sqlite3_malloc_vdup2(U64(u64(new_size) * sizeof(Ht))))
	sqlite3_end_benign_malloc()
	if usize(new_ht) == usize(0) {
		return 0
	}
	sqlite3_free(voidptr(ph.ht))
	ph.ht = new_ht
	new_size = u32(u64(sqlite3_malloc_size(voidptr(new_ht))) / sizeof(Ht))
	ph.htsize = new_size
	C.memset(voidptr(new_ht), 0, u64(new_size) * sizeof(Ht))
	elem = ph.first
	ph.first = 0
	for elem {
		next_elem = elem.next
		insert_element(ph, unsafe { new_ht + (elem.h % new_size) }, elem)
		elem = next_elem
	}
	return 1
}

@[c:'findElementWithHash']
fn find_element_with_hash(ph &Hash, p_key &i8, p_hash &u32) &HashElem {
	elem := &HashElem(0)
	count := u32(0)
	h := u32(0)
	if !find_element_with_hash_null_element_inited {
		find_element_with_hash_null_element = HashElem{}

		find_element_with_hash_null_element_inited = true
	}

	h = str_hash(p_key)
	if ph.ht {
		p_entry := &Ht(0)
		p_entry = unsafe { ph.ht + (h % ph.htsize) }
		elem = p_entry.chain
		count = p_entry.count
	} else {
		elem = ph.first
		count = ph.count
	}
	if p_hash {
		unsafe { *p_hash = h }
	}
	for count {
		if h == elem.h && sqlite3_str_ic_mp(elem.pKey, p_key) == 0 {
			return elem
		}
		elem = elem.next
		count--
	}
	return &find_element_with_hash_null_element
}

@[c:'removeElement']
fn remove_element(ph &Hash, elem &HashElem) {
	p_entry := &Ht(0)
	if elem.prev {
		elem.prev.next = elem.next
	} else {
		ph.first = elem.next
	}
	if elem.next {
		elem.next.prev = elem.prev
	}
	if ph.ht {
		p_entry = unsafe { ph.ht + (elem.h % ph.htsize) }
		if usize(p_entry.chain) == usize(elem) {
			p_entry.chain = elem.next
		}
		p_entry.count--
	}
	sqlite3_free(voidptr(elem))
	ph.count--
	if ph.count == u32(0) {
		sqlite3_hash_clear(ph)
	}
}

@[c:'sqlite3HashFind']
fn sqlite3_hash_find(ph &Hash, p_key &i8) voidptr {
	return find_element_with_hash(ph, p_key, unsafe { nil }).data
}

@[c:'sqlite3HashInsert']
fn sqlite3_hash_insert(ph &Hash, p_key &i8, data voidptr) voidptr {
	h := u32(0)
	elem := &HashElem(0)
	new_elem := &HashElem(0)
	elem = find_element_with_hash(ph, p_key, &h)
	if elem.data {
		old_data := elem.data
		if usize(data) == usize(0) {
			remove_element(ph, elem)
		} else {
			elem.data = data
			elem.pKey = p_key
		}
		return old_data
	}
	if usize(data) == usize(0) {
		return unsafe { nil }
	}
	new_elem = &HashElem(sqlite3_malloc_vdup2(U64(sizeof(HashElem))))
	if usize(new_elem) == usize(0) {
		return data
	}
	new_elem.pKey = p_key
	new_elem.h = h
	new_elem.data = data
	ph.count++
	if ph.count >= u32(5) && ph.count > u32(2) * ph.htsize {
		rehash(ph, ph.count * u32(3))
	}
	insert_element(ph, unsafe { if ph.ht { ph.ht + (new_elem.h % ph.htsize) } else { &Ht(nil) } }, new_elem)
	return unsafe { nil }
}
