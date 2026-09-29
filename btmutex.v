@[translated]
module main

@[c:'lockBtreeMutex']
fn lock_btree_mutex(p &Btree) {
	sqlite3_mutex_enter(p.pBt.mutex)
	p.pBt.db = p.db
	p.locked = U8(1)
}

@[c:'unlockBtreeMutex']
fn unlock_btree_mutex(p &Btree) {
	p_bt := p.pBt
	sqlite3_mutex_leave(p_bt.mutex)
	p.locked = U8(0)
}

@[c:'sqlite3BtreeEnter']
fn sqlite3_btree_enter(p &Btree) {
	if !p.sharable {
		return
	}
	p.wantToLock++
	if p.locked {
		return
	}
	btree_lock_carefully(p)
}

@[c:'btreeLockCarefully']
fn btree_lock_carefully(p &Btree) {
	p_later := &Btree(0)
	if sqlite3_mutex_try(p.pBt.mutex) == 0 {
		p.pBt.db = p.db
		p.locked = U8(1)
		return
	}
	for p_later = p.pNext; p_later; p_later = p_later.pNext {
		if p_later.locked {
			unlock_btree_mutex(p_later)
		}
	}
	lock_btree_mutex(p)
	for p_later = p.pNext; p_later; p_later = p_later.pNext {
		if p_later.wantToLock {
			lock_btree_mutex(p_later)
		}
	}
}

@[c:'sqlite3BtreeLeave']
fn sqlite3_btree_leave(p &Btree) {
	if p.sharable {
		p.wantToLock--
		if p.wantToLock == 0 {
			unlock_btree_mutex(p)
		}
	}
}

@[c:'btreeEnterAll']
fn btree_enter_all(db &Sqlite3) {
	i := 0
	skip_ok := U8(1)
	p := &Btree(0)
	for i = 0; i < db.nDb; i++ {
		p = db.aDb[i].pBt
		if !isnil(p) && int(p.sharable) {
			sqlite3_btree_enter(p)
			skip_ok = U8(0)
		}
	}
	db.noSharedCache = skip_ok
}

@[c:'sqlite3BtreeEnterAll']
fn sqlite3_btree_enter_all(db &Sqlite3) {
	if int(db.noSharedCache) == 0 {
		btree_enter_all(db)
	}
}

@[c:'btreeLeaveAll']
fn btree_leave_all(db &Sqlite3) {
	i := 0
	p := &Btree(0)
	for i = 0; i < db.nDb; i++ {
		p = db.aDb[i].pBt
		if p {
			sqlite3_btree_leave(p)
		}
	}
}

@[c:'sqlite3BtreeLeaveAll']
fn sqlite3_btree_leave_all(db &Sqlite3) {
	if int(db.noSharedCache) == 0 {
		btree_leave_all(db)
	}
}

@[c:'sqlite3BtreeEnterCursor']
fn sqlite3_btree_enter_cursor(p_cur &BtCursor) {
	sqlite3_btree_enter(p_cur.pBtree)
}

@[c:'sqlite3BtreeLeaveCursor']
fn sqlite3_btree_leave_cursor(p_cur &BtCursor) {
	sqlite3_btree_leave(p_cur.pBtree)
}
