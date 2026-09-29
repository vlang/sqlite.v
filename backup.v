@[translated]
module main

struct Sqlite3_backup {
	pDestDb     &Sqlite3
	zDestDb     &i8
	pDest       &Btree
	iDestSchema u32
	bDestLocked int
	iNext       Pgno
	pSrcDb      &Sqlite3
	pSrc        &Btree
	rc          int
	nRemaining  Pgno
	nPagecount  Pgno
	isAttached  int
	pNext       &Sqlite3_backup
}

@[c:'findBtree']
fn find_btree(p_error_db &Sqlite3, p_db &Sqlite3, z_db &i8) &Btree {
	i := sqlite3_find_db_name(p_db, z_db)
	if i == 1 {
		s_parse := Parse{}
		rc := 0
		sqlite3_parse_object_init(&s_parse, p_db)
		if sqlite3_open_temp_database(&s_parse) {
			sqlite3_error_with_msg(p_error_db, s_parse.rc, c'%s', voidptr(s_parse.zErrMsg))
			rc = 1
		}
		sqlite3_db_free(p_error_db, voidptr(s_parse.zErrMsg))
		sqlite3_parse_object_reset(&s_parse)
		if rc {
			return unsafe { nil }
		}
	}
	if i < 0 {
		sqlite3_error_with_msg(p_error_db, 1, c'unknown database %s', voidptr(z_db))
		return unsafe { nil }
	}
	return p_db.aDb[i].pBt
}

@[c:'setDestPgsz']
fn set_dest_pgsz(p_dest &Btree, p_src &Btree) int {
	return sqlite3_btree_set_page_size(p_dest, sqlite3_btree_get_page_size(p_src), 0, 0)
}

@[c:'checkReadTransaction']
fn check_read_transaction(db &Sqlite3, p &Btree) int {
	if sqlite3_btree_txn_state(p) != 0 {
		sqlite3_error_with_msg(db, 1, c'destination database is in use')
		return 1
	}
	return 0
}

fn sqlite3_backup_init(p_dest_db &Sqlite3, z_dest_db &i8, p_src_db &Sqlite3, z_src_db &i8) &Sqlite3_backup {
	c2v_gc_register_thread()
	p := &Sqlite3_backup(0)
	sqlite3_mutex_enter(p_src_db.mutex)
	sqlite3_mutex_enter(p_dest_db.mutex)
	if usize(p_src_db) == usize(p_dest_db) {
		sqlite3_error_with_msg(p_dest_db, 1, c'source and destination must be distinct')
		p = 0
	} else {
		n_dest := sqlite3_strlen30(z_dest_db)
		p = &Sqlite3_backup(sqlite3_malloc_zero(U64(sizeof(Sqlite3_backup) + u64(n_dest) + u64(1))))
		if isnil(p) {
			sqlite3_error(p_dest_db, 7)
		} else {
			p.zDestDb = &i8(voidptr(unsafe { p + 1 }))
			C.memcpy(voidptr(p.zDestDb), voidptr(z_dest_db), u64(n_dest))
		}
	}
	if p {
		p_dest := find_btree(p_dest_db, p_dest_db, z_dest_db)
		p.pSrc = find_btree(p_dest_db, p_src_db, z_src_db)
		p.pDestDb = p_dest_db
		p.pSrcDb = p_src_db
		p.iNext = Pgno(1)
		p.isAttached = 0
		if usize(0) == usize(p.pSrc) || usize(0) == usize(p_dest) || check_read_transaction(p_dest_db, p_dest) != 0 {
			sqlite3_free(voidptr(p))
			p = 0
		}
	}
	if p {
		p.pSrc.nBackup++
	}
	sqlite3_mutex_leave(p_dest_db.mutex)
	sqlite3_mutex_leave(p_src_db.mutex)
	return p
}

@[c:'isFatalError']
fn is_fatal_error(rc int) int {
	return int((rc != 0 && rc != 5 && (rc != 6)))
}

@[c:'backupOnePage']
fn backup_one_page(p &Sqlite3_backup, i_src_pg Pgno, z_src_data &U8, b_update int) int {
	p_dest_pager := sqlite3_btree_pager(p.pDest)
	n_src_pgsz := sqlite3_btree_get_page_size(p.pSrc)
	n_dest_pgsz := sqlite3_btree_get_page_size(p.pDest)
	n_copy := (if n_src_pgsz < n_dest_pgsz { n_src_pgsz } else { n_dest_pgsz })
	i_end := I64(i_src_pg) * I64(n_src_pgsz)
	rc := 0
	i_off := I64(0)
	for i_off = i_end - I64(n_src_pgsz); rc == 0 && i_off < i_end; i_off += I64(n_dest_pgsz) {
		p_dest_pg := unsafe { &DbPage(nil) }
		i_dest := Pgno((i_off / I64(n_dest_pgsz))) + Pgno(1)
		if i_dest == (Pgno(((u32(sqlite3PendingByte) / p.pDest.pBt.pageSize) + u32(1)))) {
			continue
		}
		rc = sqlite3_pager_get(p_dest_pager, i_dest, &&DbPage(&&DbPage(c2v_address_of(&p_dest_pg))), 0)
		if 0 == rc && 0 == c2v_assign[int](unsafe { &rc }, int(sqlite3_pager_write(p_dest_pg))) {
			z_in := unsafe { z_src_data + (i_off % I64(n_src_pgsz)) }
			z_dest_data := &U8(sqlite3_pager_get_data(p_dest_pg))
			z_out := unsafe { z_dest_data + (i_off % I64(n_dest_pgsz)) }
			C.memcpy(voidptr(z_out), voidptr(z_in), u64(n_copy))
			(&U8(sqlite3_pager_get_extra(p_dest_pg)))[0] = U8(0)
			if i_off == I64(0) && b_update == 0 {
				sqlite3_put4byte(unsafe { z_out + 28 }, sqlite3_btree_last_page(p.pSrc))
			}
		}
		sqlite3_pager_unref(p_dest_pg)
	}
	return rc
}

@[c:'backupTruncateFile']
fn backup_truncate_file(p_file &Sqlite3_file, i_size I64) int {
	i_current := I64(0)
	rc := sqlite3_os_file_size(p_file, &i_current)
	if rc == 0 && i_current > i_size {
		rc = sqlite3_os_truncate(p_file, i_size)
	}
	return rc
}

@[c:'attachBackupObject']
fn attach_backup_object(p &Sqlite3_backup) {
	pp := &&Sqlite3_backup(0)
	pp = sqlite3_pager_backup_ptr(sqlite3_btree_pager(p.pSrc))
	p.pNext = unsafe { *pp }
	unsafe { *pp = p }
	p.isAttached = 1
}

fn sqlite3_backup_step(p &Sqlite3_backup, n_page int) int {
	c2v_gc_register_thread()
	rc := 0
	dest_mode := 0
	pgsz_src := 0
	pgsz_dest := 0
	sqlite3_mutex_enter(p.pSrcDb.mutex)
	sqlite3_btree_enter(p.pSrc)
	if p.pDestDb {
		sqlite3_mutex_enter(p.pDestDb.mutex)
	}
	rc = p.rc
	if !is_fatal_error(rc) {
		p_src_pager := sqlite3_btree_pager(p.pSrc)
		p_dest := unsafe { &Btree(nil) }
		p_dest_pager := unsafe { &Pager(nil) }
		ii := 0
		n_src_page := -1
		b_close_trans := 0
		if !isnil(p.pDestDb) && int(p.pSrc.pBt.inTransaction) == 2 {
			rc = 5
		} else {
			rc = 0
		}
		if rc == 0 && 0 == sqlite3_btree_txn_state(p.pSrc) {
			rc = sqlite3_btree_begin_trans(p.pSrc, 0, unsafe { nil })
			b_close_trans = 1
		}
		p_dest = p.pDest
		if usize(p_dest) == usize(0) {
			p_dest = find_btree(p.pDestDb, p.pDestDb, p.zDestDb)
		}
		if usize(p_dest) == usize(0) {
			rc = 1
		} else {
			p_dest_pager = sqlite3_btree_pager(p_dest)
		}
		if p.bDestLocked == 0 && rc == 0 && set_dest_pgsz(p_dest, p.pSrc) == 7 {
			rc = 7
		}
		if 0 == rc && p.bDestLocked == 0 && 0 == c2v_assign[int](unsafe { &rc }, int(sqlite3_btree_begin_trans(p_dest, 2, &int(voidptr(&p.iDestSchema))))) {
			p.bDestLocked = 1
			p.pDest = p_dest
		}
		if rc == 0 {
			pgsz_src = sqlite3_btree_get_page_size(p.pSrc)
			pgsz_dest = sqlite3_btree_get_page_size(p.pDest)
			dest_mode = sqlite3_pager_get_journal_mode(sqlite3_btree_pager(p.pDest))
			if (dest_mode == 5 || sqlite3_pager_is_memdb(p_dest_pager)) && pgsz_src != pgsz_dest {
				rc = 8
			}
		}
		n_src_page = int(sqlite3_btree_last_page(p.pSrc))
		for ii = 0; (n_page < 0 || ii < n_page) && p.iNext <= Pgno(n_src_page) && !rc; ii++ {
			i_src_pg := p.iNext
			if i_src_pg != (Pgno(((u32(sqlite3PendingByte) / p.pSrc.pBt.pageSize) + u32(1)))) {
				p_src_pg := &DbPage(0)
				rc = sqlite3_pager_get(p_src_pager, i_src_pg, &&DbPage(&&DbPage(c2v_address_of(&p_src_pg))), 2)
				if rc == 0 {
					rc = backup_one_page(p, i_src_pg, sqlite3_pager_get_data(p_src_pg), 0)
					sqlite3_pager_unref(p_src_pg)
				}
			}
			p.iNext++
		}
		if rc == 0 {
			p.nPagecount = Pgno(n_src_page)
			p.nRemaining = Pgno(n_src_page + 1) - p.iNext
			if p.iNext > Pgno(n_src_page) {
				rc = 101
			} else if !p.isAttached {
				attach_backup_object(p)
			}
		}
		if rc == 101 {
			if n_src_page == 0 {
				rc = sqlite3_btree_new_db(p.pDest)
				n_src_page = 1
			}
			if rc == 0 || rc == 101 {
				rc = sqlite3_btree_update_meta(p.pDest, 1, p.iDestSchema + u32(1))
			}
			if rc == 0 {
				if p.pDestDb {
					sqlite3_reset_all_schemas_of_connection(p.pDestDb)
				}
				if dest_mode == 5 {
					rc = sqlite3_btree_set_version(p.pDest, 2)
				}
			}
			if rc == 0 {
				n_dest_truncate := 0
				if pgsz_src < pgsz_dest {
					ratio := pgsz_dest / pgsz_src
					n_dest_truncate = (n_src_page + ratio - 1) / ratio
					if n_dest_truncate == int((Pgno(((u32(sqlite3PendingByte) / p.pDest.pBt.pageSize) + u32(1))))) {
						n_dest_truncate--
					}
				} else {
					n_dest_truncate = n_src_page * (pgsz_src / pgsz_dest)
				}
				if pgsz_src < pgsz_dest {
					i_size := I64(pgsz_src) * I64(n_src_page)
					p_file := sqlite3_pager_file(p_dest_pager)
					i_pg := Pgno(0)
					n_dst_page := 0
					i_off := I64(0)
					i_end := I64(0)
					sqlite3_pager_pagecount(p_dest_pager, &n_dst_page)
					for i_pg = Pgno(n_dest_truncate); rc == 0 && i_pg <= Pgno(n_dst_page); i_pg++ {
						if i_pg != (Pgno(((u32(sqlite3PendingByte) / p.pDest.pBt.pageSize) + u32(1)))) {
							p_pg := &DbPage(0)
							rc = sqlite3_pager_get(p_dest_pager, i_pg, &&DbPage(&&DbPage(c2v_address_of(&p_pg))), 0)
							if rc == 0 {
								rc = sqlite3_pager_write(p_pg)
								sqlite3_pager_unref(p_pg)
							}
						}
					}
					if rc == 0 {
						rc = sqlite3_pager_commit_phase_one(p_dest_pager, unsafe { nil }, 1)
					}
					i_end = (if I64((sqlite3PendingByte + pgsz_dest)) < i_size {
						I64((sqlite3PendingByte + pgsz_dest))
					} else {
						i_size
					})
					for i_off = I64(sqlite3PendingByte + pgsz_src); rc == 0 && i_off < i_end; i_off += I64(pgsz_src) {
						p_src_pg := unsafe { &PgHdr(nil) }
						i_src_pg := Pgno(((i_off / I64(pgsz_src)) + I64(1)))
						rc = sqlite3_pager_get(p_src_pager, i_src_pg, unsafe { &&DbPage(&&PgHdr(c2v_address_of(&p_src_pg))) }, 0)
						if rc == 0 {
							z_data := &U8(sqlite3_pager_get_data(unsafe { &DbPage(p_src_pg) }))
							rc = sqlite3_os_write(p_file, voidptr(z_data), pgsz_src, i_off)
						}
						sqlite3_pager_unref(unsafe { &DbPage(p_src_pg) })
					}
					if rc == 0 {
						rc = backup_truncate_file(p_file, i_size)
					}
					if rc == 0 {
						rc = sqlite3_pager_sync(p_dest_pager, unsafe { nil })
					}
				} else {
					sqlite3_pager_truncate_image(p_dest_pager, Pgno(n_dest_truncate))
					rc = sqlite3_pager_commit_phase_one(p_dest_pager, unsafe { nil }, 0)
				}
				if 0 == rc && 0 == c2v_assign[int](unsafe { &rc }, int(sqlite3_btree_commit_phase_two(p.pDest, 0))) {
					rc = 101
				}
			}
		}
		if b_close_trans {
			sqlite3_btree_commit_phase_one(p.pSrc, unsafe { nil })
			sqlite3_btree_commit_phase_two(p.pSrc, 0)
		}
		if rc == (10 | (12 << 8)) {
			rc = 7
		}
		p.rc = rc
	}
	if p.pDestDb {
		sqlite3_mutex_leave(p.pDestDb.mutex)
	}
	sqlite3_btree_leave(p.pSrc)
	sqlite3_mutex_leave(p.pSrcDb.mutex)
	return rc
}

fn sqlite3_backup_finish(p &Sqlite3_backup) int {
	c2v_gc_register_thread()
	pp := &&Sqlite3_backup(0)
	p_src_db := &Sqlite3(0)
	rc := 0
	if usize(p) == usize(0) {
		return 0
	}
	p_src_db = p.pSrcDb
	sqlite3_mutex_enter(p_src_db.mutex)
	sqlite3_btree_enter(p.pSrc)
	if p.pDestDb {
		sqlite3_mutex_enter(p.pDestDb.mutex)
	}
	if p.pDestDb {
		p.pSrc.nBackup--
	}
	if p.isAttached {
		pp = sqlite3_pager_backup_ptr(sqlite3_btree_pager(p.pSrc))
		for usize((unsafe { *pp })) != usize(p) {
			pp = &(unsafe { *pp }).pNext
		}
		unsafe { *pp = p.pNext }
	}
	if p.pDest {
		sqlite3_btree_rollback(p.pDest, 0, 0)
	}
	rc = if (p.rc == 101) { 0 } else { p.rc }
	if p.pDestDb {
		sqlite3_error(p.pDestDb, rc)
		sqlite3_leave_mutex_and_close_zombie(p.pDestDb)
	}
	sqlite3_btree_leave(p.pSrc)
	if p.pDestDb {
		sqlite3_free(voidptr(p))
	}
	sqlite3_leave_mutex_and_close_zombie(p_src_db)
	return rc
}

fn sqlite3_backup_remaining(p &Sqlite3_backup) int {
	c2v_gc_register_thread()
	return int(p.nRemaining)
}

fn sqlite3_backup_pagecount(p &Sqlite3_backup) int {
	c2v_gc_register_thread()
	return int(p.nPagecount)
}

@[c:'backupUpdate']
fn backup_update(p &Sqlite3_backup, i_page Pgno, a_data &U8) {
	for {
		if !is_fatal_error(p.rc) && i_page < p.iNext {
			rc := 0
			sqlite3_mutex_enter(p.pDestDb.mutex)
			rc = backup_one_page(p, i_page, a_data, 1)
			sqlite3_mutex_leave(p.pDestDb.mutex)
			if rc != 0 {
				p.rc = rc
			}
		}
		p = p.pNext
		if !(usize(p) != usize(0)) {
			break
		}
	}
}

@[c:'sqlite3BackupUpdate']
fn sqlite3_backup_update(p_backup &Sqlite3_backup, i_page Pgno, a_data &U8) {
	if p_backup {
		backup_update(p_backup, i_page, a_data)
	}
}

@[c:'sqlite3BackupRestart']
fn sqlite3_backup_restart(p_backup &Sqlite3_backup) {
	p := &Sqlite3_backup(0)
	for p = p_backup; p; p = p.pNext {
		p.iNext = Pgno(1)
	}
}

@[c:'sqlite3BtreeCopyFile']
fn sqlite3_btree_copy_file(p_to &Btree, p_from &Btree) int {
	rc := 0
	p_fd := &Sqlite3_file(0)
	b := Sqlite3_backup{}
	sqlite3_btree_enter(p_to)
	sqlite3_btree_enter(p_from)
	p_fd = sqlite3_pager_file(sqlite3_btree_pager(p_to))
	if p_fd.pMethods {
		n_byte := I64(sqlite3_btree_get_page_size(p_from)) * I64(sqlite3_btree_last_page(p_from))
		rc = sqlite3_os_file_control(p_fd, 11, voidptr(&n_byte))
		if rc == 12 {
			rc = 0
		}
		if rc {
			unsafe { goto copy_finished
			 }
		}
	}
	C.memset(voidptr(&b), 0, sizeof(b))
	b.pSrcDb = p_from.db
	b.pSrc = p_from
	b.pDest = p_to
	b.iNext = Pgno(1)
	sqlite3_backup_step(&b, 2147483647)
	rc = sqlite3_backup_finish(&b)
	if rc == 0 {
		p_to.pBt.btsFlags &= ~2
	} else {
		sqlite3_pager_clear_cache(sqlite3_btree_pager(b.pDest))
	}
	copy_finished:
	sqlite3_btree_leave(p_from)
	sqlite3_btree_leave(p_to)
	return rc
}
