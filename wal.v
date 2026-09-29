@[translated]
module main

struct WalIndexHdr {
	iVersion    u32
	unused      u32
	iChange     u32
	isInit      U8
	bigEndCksum U8
	szPage      U16
	mxFrame     u32
	nPage       u32
	aFrameCksum [2]u32
	aSalt       [2]u32
	aCksum      [2]u32
}

struct WalCkptInfo {
	nBackfill          u32
	aReadMark          [5]u32
	aLock              [8]U8
	nBackfillAttempted u32
	notUsed0           u32
}

struct Wal {
	pVfs                &Sqlite3_vfs
	pDbFd               &Sqlite3_file
	pWalFd              &Sqlite3_file
	iCallback           u32
	mxWalSize           I64
	nWiData             int
	szFirstBlock        int
	apWiData            &&u32
	szPage              u32
	readLock            I16
	syncFlags           U8
	exclusiveMode       U8
	writeLock           U8
	ckptLock            U8
	readOnly            U8
	truncateOnCommit    U8
	syncHeader          U8
	padToSectorBoundary U8
	bShmUnreliable      U8
	hdr                 WalIndexHdr
	minFrame            u32
	iReCksum            u32
	zWalName            &i8
	nCkpt               u32
}

type Ht_slot = u16

struct WalSegment {
	iNext  int
	aIndex &Ht_slot
	aPgno  &u32
	nEntry int
	iZero  int
}

struct WalIterator {
	iPrior   u32
	nSegment int
	aSegment [1]WalSegment
}

@[c:'walIndexPageRealloc']
fn wal_index_page_realloc(p_wal &Wal, i_page int, pp_page &&u32) int {
	rc := 0
	if p_wal.nWiData <= i_page {
		n_byte := Sqlite3_int64(sizeof(voidptr) * u64((I64(1) + I64(i_page))))
		ap_new := &&u32(0)
		ap_new = &&u32(sqlite3_realloc_vdup3(voidptr(p_wal.apWiData), U64(n_byte)))
		if isnil(ap_new) {
			unsafe { *pp_page = 0 }
			return 7
		}
		C.memset(voidptr(unsafe { ap_new + p_wal.nWiData }), 0, sizeof(voidptr) * u64((i_page + 1 - p_wal.nWiData)))
		p_wal.apWiData = ap_new
		p_wal.nWiData = i_page + 1
	}
	if int(p_wal.exclusiveMode) == 2 {
		p_wal.apWiData[i_page] = &u32(sqlite3_malloc_zero(U64((sizeof(Ht_slot) * u64((4096 * 2)) + u64(4096) * sizeof(u32)))))
		if isnil(p_wal.apWiData[i_page]) {
			rc = 7
		}
	} else {
		rc = sqlite3_os_shm_map(p_wal.pDbFd, i_page, int((sizeof(Ht_slot) * u64((4096 * 2)) + u64(4096) * sizeof(u32))), int(p_wal.writeLock), &voidptr(voidptr(unsafe { p_wal.apWiData + i_page })))
		if rc == 0 {
			if i_page > 0 && sqlite3_fault_sim(600) {
				rc = 7
			}
		} else if (rc & 255) == 8 {
			p_wal.readOnly |= 2
			if rc == 8 {
				rc = 0
			}
		}
	}
	unsafe { *pp_page = p_wal.apWiData[i_page] }
	return rc
}

@[c:'walIndexPage']
fn wal_index_page(p_wal &Wal, i_page int, pp_page &&u32) int {
	if p_wal.nWiData <= i_page || usize(c2v_assign[&u32](pp_page, p_wal.apWiData[i_page])) == usize(0) {
		return wal_index_page_realloc(p_wal, i_page, pp_page)
	}
	return 0
}

@[c:'walCkptInfo']
fn wal_ckpt_info(p_wal &Wal) &WalCkptInfo {
	return &WalCkptInfo(voidptr(unsafe { p_wal.apWiData[0] + (sizeof(WalIndexHdr) / u64(2)) }))
}

@[c:'walIndexHdr']
fn wal_index_hdr(p_wal &Wal) &WalIndexHdr {
	return &WalIndexHdr(voidptr(p_wal.apWiData[0]))
}

@[c:'walChecksumBytes']
fn wal_checksum_bytes(native_cksum int, a &U8, n_byte int, a_in &u32, a_out &u32) {
	s1 := u32(0)
	s2 := u32(0)

	a_data := &u32(voidptr(a))
	a_end := &u32(voidptr(unsafe { a + n_byte }))
	if a_in {
		s1 = a_in[0]
		s2 = a_in[1]
	} else {
		s2 = u32(0)
		s1 = s2
	}
	if !native_cksum {
		for {
			s1 += (((a_data[0] & u32(255)) << 24) + ((a_data[0] & u32(65280)) << 8) + ((a_data[0] & u32(16711680)) >> 8) + ((a_data[0] & u32(4278190080)) >> 24)) + s2
			s2 += (((a_data[1] & u32(255)) << 24) + ((a_data[1] & u32(65280)) << 8) + ((a_data[1] & u32(16711680)) >> 8) + ((a_data[1] & u32(4278190080)) >> 24)) + s1
			c2v_pointer_prefix(voidptr(&a_data), a_data, isize(2))
			if !(usize(a_data) < usize(a_end)) {
				break
			}
		}
	} else if n_byte % 64 == 0 {
		for {
			s1 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s2
			s2 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s1
			s1 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s2
			s2 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s1
			s1 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s2
			s2 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s1
			s1 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s2
			s2 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s1
			s1 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s2
			s2 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s1
			s1 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s2
			s2 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s1
			s1 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s2
			s2 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s1
			s1 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s2
			s2 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s1
			if !(usize(a_data) < usize(a_end)) {
				break
			}
		}
	} else {
		for {
			s1 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s2
			s2 += (unsafe { *c2v_pointer_postfix(voidptr(&a_data), a_data, isize(1)) }) + s1
			if !(usize(a_data) < usize(a_end)) {
				break
			}
		}
	}
	a_out[0] = s1
	a_out[1] = s2
}

@[c:'walShmBarrier']
fn wal_shm_barrier(p_wal &Wal) {
	if int(p_wal.exclusiveMode) != 2 {
		sqlite3_os_shm_barrier(p_wal.pDbFd)
	}
}

@[c:'walIndexWriteHdr']
fn wal_index_write_hdr(p_wal &Wal) {
	a_hdr := wal_index_hdr(p_wal)
	n_cksum := int((u64(usize(__offsetof(WalIndexHdr, aCksum)))))
	p_wal.hdr.isInit = U8(1)
	p_wal.hdr.iVersion = u32(3007000)
	wal_checksum_bytes(1, &U8(voidptr(&p_wal.hdr)), n_cksum, unsafe { nil }, &p_wal.hdr.aCksum[0])
	C.memcpy(voidptr(unsafe { a_hdr + 1 }), voidptr(&p_wal.hdr), sizeof(WalIndexHdr))
	wal_shm_barrier(p_wal)
	C.memcpy(voidptr(unsafe { a_hdr + 0 }), voidptr(&p_wal.hdr), sizeof(WalIndexHdr))
}

@[c:'walEncodeFrame']
fn wal_encode_frame(p_wal &Wal, i_page u32, n_truncate u32, a_data &U8, a_frame &U8) {
	native_cksum := 0
	a_cksum := unsafe { &u32(&p_wal.hdr.aFrameCksum[0]) }
	sqlite3_put4byte(unsafe { a_frame + 0 }, i_page)
	sqlite3_put4byte(unsafe { a_frame + 4 }, n_truncate)
	if p_wal.iReCksum == u32(0) {
		C.memcpy(voidptr(unsafe { a_frame + 8 }), p_wal.hdr.aSalt, u64(8))
		native_cksum = (int(p_wal.hdr.bigEndCksum) == 0)
		wal_checksum_bytes(native_cksum, a_frame, 8, a_cksum, a_cksum)
		wal_checksum_bytes(native_cksum, a_data, int(p_wal.szPage), a_cksum, a_cksum)
		sqlite3_put4byte(unsafe { a_frame + 16 }, a_cksum[0])
		sqlite3_put4byte(unsafe { a_frame + 20 }, a_cksum[1])
	} else {
		C.memset(voidptr(unsafe { a_frame + 8 }), 0, u64(16))
	}
}

@[c:'walDecodeFrame']
fn wal_decode_frame(p_wal &Wal, pi_page &u32, pn_truncate &u32, a_data &U8, a_frame &U8) int {
	native_cksum := 0
	a_cksum := unsafe { &u32(&p_wal.hdr.aFrameCksum[0]) }
	pgno := u32(0)
	if C.memcmp(voidptr(&p_wal.hdr.aSalt), voidptr(unsafe { a_frame + 8 }), u64(8)) != 0 {
		return 0
	}
	pgno = sqlite3_get4byte(unsafe { a_frame + 0 })
	if pgno == u32(0) {
		return 0
	}
	if !p_wal.szPage {
		return 0
	}
	native_cksum = (int(p_wal.hdr.bigEndCksum) == 0)
	wal_checksum_bytes(native_cksum, a_frame, 8, a_cksum, a_cksum)
	wal_checksum_bytes(native_cksum, a_data, int(p_wal.szPage), a_cksum, a_cksum)
	if a_cksum[0] != sqlite3_get4byte(unsafe { a_frame + 16 }) || a_cksum[1] != sqlite3_get4byte(unsafe { a_frame + 20 }) {
		return 0
	}
	unsafe { *pi_page = pgno }
	unsafe { *pn_truncate = sqlite3_get4byte(a_frame + 4) }
	return 1
}

@[c:'walLockShared']
fn wal_lock_shared(p_wal &Wal, lock_idx int) int {
	rc := 0
	if p_wal.exclusiveMode {
		return 0
	}
	rc = sqlite3_os_shm_lock(p_wal.pDbFd, lock_idx, 1, 2 | 4)
	return rc
}

@[c:'walUnlockShared']
fn wal_unlock_shared(p_wal &Wal, lock_idx int) {
	if p_wal.exclusiveMode {
		return
	}
	sqlite3_os_shm_lock(p_wal.pDbFd, lock_idx, 1, 1 | 4)
}

@[c:'walLockExclusive']
fn wal_lock_exclusive(p_wal &Wal, lock_idx int, n int) int {
	rc := 0
	if p_wal.exclusiveMode {
		return 0
	}
	rc = sqlite3_os_shm_lock(p_wal.pDbFd, lock_idx, n, 2 | 8)
	return rc
}

@[c:'walUnlockExclusive']
fn wal_unlock_exclusive(p_wal &Wal, lock_idx int, n int) {
	if p_wal.exclusiveMode {
		return
	}
	sqlite3_os_shm_lock(p_wal.pDbFd, lock_idx, n, 1 | 8)
}

@[c:'walHash']
fn wal_hash(i_page u32) int {
	return int((i_page * u32(383)) & u32(((4096 * 2) - 1)))
}

@[c:'walNextHash']
fn wal_next_hash(i_prior_hash int) int {
	return (i_prior_hash + 1) & ((4096 * 2) - 1)
}

struct WalHashLoc {
	aHash &Ht_slot
	aPgno &u32
	iZero u32
}

@[c:'walHashGet']
fn wal_hash_get(p_wal &Wal, i_hash int, p_loc &WalHashLoc) int {
	rc := 0
	rc = wal_index_page(p_wal, i_hash, &&u32(&p_loc.aPgno))
	if p_loc.aPgno {
		p_loc.aHash = &Ht_slot(voidptr(unsafe { p_loc.aPgno + 4096 }))
		if i_hash == 0 {
			p_loc.aPgno = unsafe { p_loc.aPgno + ((sizeof(WalIndexHdr) * u64(2) + sizeof(WalCkptInfo)) / sizeof(u32)) }
			p_loc.iZero = u32(0)
		} else {
			p_loc.iZero = u32((u64(4096) - ((sizeof(WalIndexHdr) * u64(2) + sizeof(WalCkptInfo)) / sizeof(u32))) + u64((i_hash - 1) * 4096))
		}
	} else if (rc == 0) {
		rc = 1
	}
	return rc
}

@[c:'walFramePage']
fn wal_frame_page(i_frame u32) int {
	i_hash := int((u64(i_frame + u32(4096)) - (u64(4096) - ((sizeof(WalIndexHdr) * u64(2) + sizeof(WalCkptInfo)) / sizeof(u32))) - u64(1)) / u64(4096))
	return i_hash
}

@[c:'walFramePgno']
fn wal_frame_pgno(p_wal &Wal, i_frame u32) u32 {
	i_hash := wal_frame_page(i_frame)
	if i_hash == 0 {
		return p_wal.apWiData[0][(sizeof(WalIndexHdr) * u64(2) + sizeof(WalCkptInfo)) / sizeof(u32) + u64(i_frame) - u64(1)]
	}
	return p_wal.apWiData[i_hash][(u64(i_frame - u32(1)) - (u64(4096) - ((sizeof(WalIndexHdr) * u64(2) + sizeof(WalCkptInfo)) / sizeof(u32)))) % u64(4096)]
}

@[c:'walCleanupHash']
fn wal_cleanup_hash(p_wal &Wal) {
	s_loc := WalHashLoc{}
	i_limit := 0
	n_byte := 0
	i := 0
	if p_wal.hdr.mxFrame == u32(0) {
		return
	}
	i = wal_hash_get(p_wal, wal_frame_page(p_wal.hdr.mxFrame), &s_loc)
	if i {
		return
	}
	i_limit = int(p_wal.hdr.mxFrame - s_loc.iZero)
	for i = 0; i < (4096 * 2); i++ {
		if int(s_loc.aHash[i]) > i_limit {
			s_loc.aHash[i] = Ht_slot(0)
		}
	}
	n_byte = int((i64((isize(&i8(voidptr(s_loc.aHash))) - isize(&i8(voidptr(unsafe { s_loc.aPgno + i_limit })))) / isize(sizeof(i8)))))
	C.memset(voidptr(unsafe { s_loc.aPgno + i_limit }), 0, u64(n_byte))
}

@[c:'walIndexAppend']
fn wal_index_append(p_wal &Wal, i_frame u32, i_page u32) int {
	rc := 0
	s_loc := WalHashLoc{}
	rc = wal_hash_get(p_wal, wal_frame_page(i_frame), &s_loc)
	if rc == 0 {
		i_key := 0
		idx := 0
		n_collide := 0
		idx = int(i_frame - s_loc.iZero)
		if idx == 1 {
			n_byte := int((i64((isize(&U8(voidptr(unsafe { s_loc.aHash + (4096 * 2) }))) - isize(&U8(voidptr(s_loc.aPgno)))) / isize(sizeof(U8)))))
			C.memset(voidptr(s_loc.aPgno), 0, u64(n_byte))
		}
		if s_loc.aPgno[idx - 1] {
			wal_cleanup_hash(p_wal)
		}
		n_collide = idx
		for i_key = wal_hash(i_page); s_loc.aHash[i_key]; i_key = wal_next_hash(i_key) {
			if (n_collide--) == 0 {
				return sqlite3_corrupt_error(1341)
			}
		}
		s_loc.aPgno[(idx - 1) & (4096 - 1)] = i_page
		C.c2v_atomic_store_n__Ht_slot_Ht_slot_int_((unsafe { s_loc.aHash + i_key }), (Ht_slot(idx)), 0)
	}
	return rc
}

@[c:'walIndexRecover']
fn wal_index_recover(p_wal &Wal) int {
	rc := 0
	n_size := I64(0)
	a_frame_cksum := [2]u32{}
	i_lock := 0
	i_lock = 1 + int(p_wal.ckptLock)
	rc = wal_lock_exclusive(p_wal, i_lock, (3 + 0) - i_lock)
	if rc {
		return rc
	}
	C.memset(voidptr(&p_wal.hdr), 0, sizeof(WalIndexHdr))
	rc = sqlite3_os_file_size(p_wal.pWalFd, &n_size)
	if rc != 0 {
		unsafe { goto recovery_error
		 }
	}
	if n_size > I64(32) {
		a_buf := [32]U8{}
		a_private := unsafe { &u32(nil) }
		a_frame := unsafe { &U8(nil) }
		sz_frame := 0
		a_data := &U8(0)
		sz_page := 0
		magic := u32(0)
		version := u32(0)
		is_valid := 0
		i_pg := u32(0)
		i_last_frame := u32(0)
		rc = sqlite3_os_read(p_wal.pWalFd, voidptr(unsafe { &a_buf[0] }), 32, I64(0))
		if rc != 0 {
			unsafe { goto recovery_error
			 }
		}
		magic = sqlite3_get4byte(unsafe { &a_buf[0] + 0 })
		sz_page = int(sqlite3_get4byte(unsafe { &a_buf[0] + 8 }))
		if (magic & u32(4294967294)) != u32(931071618) || sz_page & (sz_page - 1) || sz_page > 65536 || sz_page < 512 {
			unsafe { goto finished
			 }
		}
		p_wal.hdr.bigEndCksum = U8((magic & u32(1)))
		p_wal.szPage = u32(sz_page)
		p_wal.nCkpt = sqlite3_get4byte(unsafe { &a_buf[0] + 12 })
		C.memcpy(voidptr(&p_wal.hdr.aSalt), voidptr(unsafe { &a_buf[0] + 16 }), u64(8))
		wal_checksum_bytes(int(p_wal.hdr.bigEndCksum) == 0, &a_buf[0], 32 - 2 * 4, unsafe { nil }, &p_wal.hdr.aFrameCksum[0])
		if p_wal.hdr.aFrameCksum[0] != sqlite3_get4byte(unsafe { &a_buf[0] + 24 }) || p_wal.hdr.aFrameCksum[1] != sqlite3_get4byte(unsafe { &a_buf[0] + 28 }) {
			unsafe { goto finished
			 }
		}
		version = sqlite3_get4byte(unsafe { &a_buf[0] + 4 })
		if version != u32(3007000) {
			rc = sqlite3_cantopen_error(1473)
			unsafe { goto finished
			 }
		}
		sz_frame = sz_page + 24
		a_frame = &U8(sqlite3_malloc64(Sqlite3_uint64(u64(sz_frame) + (sizeof(Ht_slot) * u64((4096 * 2)) + u64(4096) * sizeof(u32)))))
		if isnil(a_frame) {
			rc = 7
			unsafe { goto recovery_error
			 }
		}
		a_data = unsafe { a_frame + 24 }
		a_private = &u32(voidptr(unsafe { a_data + sz_page }))
		i_last_frame = u32((n_size - I64(32)) / I64(sz_frame))
		for i_pg = u32(0); i_pg <= u32(wal_frame_page(i_last_frame)); i_pg++ {
			a_share := &u32(0)
			i_frame := u32(0)
			i_last := u32((if u64(i_last_frame) < ((u64(4096) - ((sizeof(WalIndexHdr) * u64(2) + sizeof(WalCkptInfo)) / sizeof(u32))) + u64(i_pg * u32(4096))) {
				u64(i_last_frame)
			} else {
				((u64(4096) - ((sizeof(WalIndexHdr) * u64(2) + sizeof(WalCkptInfo)) / sizeof(u32))) + u64(i_pg * u32(4096)))
			}))
			i_first := u32(u64(1) + (if i_pg == u32(0) {
				u64(0)
			} else {
				(u64(4096) - ((sizeof(WalIndexHdr) * u64(2) + sizeof(WalCkptInfo)) / sizeof(u32))) + u64((i_pg - u32(1)) * u32(4096))
			}))
			n_hdr := u32(0)
			n_hdr32 := u32(0)

			rc = wal_index_page(p_wal, int(i_pg), &&u32(c2v_address_of(&a_share)))
			if usize(a_share) == usize(0) {
				break
			}
			p_wal.apWiData[i_pg] = a_private
			for i_frame = i_first; i_frame <= i_last; i_frame++ {
				i_offset := (I64(32) + I64((i_frame - u32(1))) * I64((sz_page + 24)))
				pgno := u32(0)
				n_truncate := u32(0)
				rc = sqlite3_os_read(p_wal.pWalFd, voidptr(a_frame), sz_frame, i_offset)
				if rc != 0 {
					break
				}
				is_valid = wal_decode_frame(p_wal, &pgno, &n_truncate, a_data, a_frame)
				if !is_valid {
					break
				}
				rc = wal_index_append(p_wal, i_frame, pgno)
				if (rc != 0) {
					break
				}
				if n_truncate {
					p_wal.hdr.mxFrame = i_frame
					p_wal.hdr.nPage = n_truncate
					p_wal.hdr.szPage = U16(((sz_page & 65280) | (sz_page >> 16)))
					a_frame_cksum[0] = p_wal.hdr.aFrameCksum[0]
					a_frame_cksum[1] = p_wal.hdr.aFrameCksum[1]
				}
			}
			p_wal.apWiData[i_pg] = a_share
			n_hdr = u32((if i_pg == u32(0) {
				(sizeof(WalIndexHdr) * u64(2) + sizeof(WalCkptInfo))
			} else {
				u64(0)
			}))
			n_hdr32 = u32(u64(n_hdr) / sizeof(u32))
			C.memcpy(voidptr(unsafe { a_share + n_hdr32 }), voidptr(unsafe { a_private + n_hdr32 }), (sizeof(Ht_slot) * u64((4096 * 2)) + u64(4096) * sizeof(u32)) - u64(n_hdr))
			if i_frame <= i_last {
				break
			}
		}
		sqlite3_free(voidptr(a_frame))
	}
	finished:
	if rc == 0 {
		p_info := &WalCkptInfo(0)
		i := 0
		p_wal.hdr.aFrameCksum[0] = a_frame_cksum[0]
		p_wal.hdr.aFrameCksum[1] = a_frame_cksum[1]
		wal_index_write_hdr(p_wal)
		p_info = wal_ckpt_info(p_wal)
		p_info.nBackfill = u32(0)
		p_info.nBackfillAttempted = p_wal.hdr.mxFrame
		p_info.aReadMark[0] = u32(0)
		for i = 1; i < (8 - 3); i++ {
			rc = wal_lock_exclusive(p_wal, (3 + i), 1)
			if rc == 0 {
				if i == 1 && p_wal.hdr.mxFrame {
					p_info.aReadMark[i] = p_wal.hdr.mxFrame
				} else {
					p_info.aReadMark[i] = u32(4294967295)
				}
				wal_unlock_exclusive(p_wal, (3 + i), 1)
			} else if rc != 5 {
				unsafe { goto recovery_error
				 }
			}
		}
		if p_wal.hdr.nPage {
			sqlite3_log((27 | (1 << 8)), c'recovered %d frames from WAL file %s', p_wal.hdr.mxFrame, voidptr(p_wal.zWalName))
		}
	}
	recovery_error:
	wal_unlock_exclusive(p_wal, i_lock, (3 + 0) - i_lock)
	return rc
}

@[c:'walIndexClose']
fn wal_index_close(p_wal &Wal, is_delete int) {
	if int(p_wal.exclusiveMode) == 2 || int(p_wal.bShmUnreliable) {
		i := 0
		for i = 0; i < p_wal.nWiData; i++ {
			sqlite3_free(voidptr(p_wal.apWiData[i]))
			p_wal.apWiData[i] = 0
		}
	}
	if int(p_wal.exclusiveMode) != 2 {
		sqlite3_os_shm_unmap(p_wal.pDbFd, is_delete)
	}
}

@[c:'sqlite3WalOpen']
fn sqlite3_wal_open(p_vfs &Sqlite3_vfs, p_db_fd &Sqlite3_file, z_wal_name &i8, b_no_shm int, mx_wal_size I64, pp_wal &&Wal) int {
	rc := 0
	p_ret := &Wal(0)
	flags := 0
	unsafe { *pp_wal = 0 }
	p_ret = &Wal(sqlite3_malloc_zero(U64(sizeof(Wal) + u64(p_vfs.szOsFile))))
	if isnil(p_ret) {
		return 7
	}
	p_ret.pVfs = p_vfs
	p_ret.pWalFd = &Sqlite3_file(voidptr(unsafe { p_ret + 1 }))
	p_ret.pDbFd = p_db_fd
	p_ret.readLock = I16(-1)
	p_ret.mxWalSize = mx_wal_size
	p_ret.zWalName = z_wal_name
	p_ret.syncHeader = U8(1)
	p_ret.padToSectorBoundary = U8(1)
	p_ret.exclusiveMode = U8((if b_no_shm { 2 } else { 0 }))
	flags = (2 | 4 | 524288)
	rc = sqlite3_os_open(p_vfs, z_wal_name, p_ret.pWalFd, flags, &flags)
	if rc == 0 && flags & 1 {
		p_ret.readOnly = U8(1)
	}
	if rc != 0 {
		wal_index_close(p_ret, 0)
		sqlite3_os_close(p_ret.pWalFd)
		sqlite3_free(voidptr(p_ret))
	} else {
		idc := sqlite3_os_device_characteristics(p_db_fd)
		if idc & 1024 {
			p_ret.syncHeader = U8(0)
		}
		if idc & 4096 {
			p_ret.padToSectorBoundary = U8(0)
		}
		unsafe { *pp_wal = p_ret }
	}
	return rc
}

@[c:'sqlite3WalLimit']
fn sqlite3_wal_limit(p_wal &Wal, i_limit I64) {
	if p_wal {
		p_wal.mxWalSize = i_limit
	}
}

@[c:'walIteratorNext']
fn wal_iterator_next(p &WalIterator, pi_page &u32, pi_frame &u32) int {
	i_min := u32(0)
	i_ret := u32(4294967295)
	i := 0
	i_min = p.iPrior
	for i = p.nSegment - 1; i >= 0; i-- {
		p_segment := unsafe { &p.aSegment[0] + i }
		for p_segment.iNext < p_segment.nEntry {
			i_pg := p_segment.aPgno[p_segment.aIndex[p_segment.iNext]]
			if i_pg > i_min {
				if i_pg < i_ret {
					i_ret = i_pg
					unsafe { *pi_frame = u32(p_segment.iZero + int(p_segment.aIndex[p_segment.iNext])) }
				}
				break
			}
			p_segment.iNext++
		}
	}
	p.iPrior = i_ret
	unsafe { *pi_page = p.iPrior }
	return int((i_ret == u32(4294967295)))
}

@[c:'walMerge']
fn wal_merge(a_content &u32, a_left &Ht_slot, n_left int, pa_right &&Ht_slot, pn_right &int, a_tmp &Ht_slot) {
	i_left := 0
	i_right := 0
	i_out := 0
	n_right := (unsafe { *pn_right })
	a_right := (unsafe { *pa_right })
	for i_right < n_right || i_left < n_left {
		logpage := Ht_slot(0)
		dbpage := Pgno(0)
		if (i_left < n_left) && (i_right >= n_right || a_content[a_left[i_left]] < a_content[a_right[i_right]]) {
			logpage = a_left[i_left++]
		} else {
			logpage = a_right[i_right++]
		}
		dbpage = a_content[logpage]
		a_tmp[i_out++] = logpage
		if i_left < n_left && a_content[a_left[i_left]] == dbpage {
			i_left++
		}
	}
	unsafe { *pa_right = a_left }
	unsafe { *pn_right = i_out }
	C.memcpy(voidptr(a_left), voidptr(a_tmp), sizeof(Ht_slot) * u64(i_out))
}

@[c:'walMergesort']
fn wal_mergesort(a_content &u32, a_buffer &Ht_slot, a_list &Ht_slot, pn_list &int) {
	n_list := (unsafe { *pn_list })
	n_merge := 0
	a_merge := unsafe { &Ht_slot(nil) }
	i_list := 0
	i_sub := u32(0)
	a_sub := [13]Sublist{}
	C.memset(voidptr(unsafe { &a_sub[0] }), 0, sizeof([13]Sublist))
	for i_list = 0; i_list < n_list; i_list++ {
		n_merge = 1
		a_merge = unsafe { a_list + i_list }
		for i_sub = u32(0); i_list & (1 << i_sub); i_sub++ {
			p := &Sublist(0)
			p = unsafe { &a_sub[0] + i_sub }
			wal_merge(a_content, p.aList, p.nList, &&Ht_slot(&&Ht_slot(c2v_address_of(&a_merge))), &n_merge, a_buffer)
		}
		a_sub[i_sub].aList = a_merge
		a_sub[i_sub].nList = n_merge
	}
	for i_sub++; i_sub < 13; i_sub++ {
		if n_list & (1 << i_sub) {
			p := &Sublist(0)
			p = unsafe { &a_sub[0] + i_sub }
			wal_merge(a_content, p.aList, p.nList, &&Ht_slot(&&Ht_slot(c2v_address_of(&a_merge))), &n_merge, a_buffer)
		}
	}
	unsafe { *pn_list = n_merge }
}

@[c:'walIteratorFree']
fn wal_iterator_free(p &WalIterator) {
	sqlite3_free(voidptr(p))
}

@[c:'walIteratorInit']
fn wal_iterator_init(p_wal &Wal, n_backfill u32, pp &&WalIterator) int {
	p := &WalIterator(0)
	n_segment := 0
	i_last := u32(0)
	n_byte := Sqlite3_int64(0)
	i := 0
	a_tmp := &Ht_slot(0)
	rc := 0
	i_last = p_wal.hdr.mxFrame
	n_segment = wal_frame_page(i_last) + 1
	n_byte = Sqlite3_int64(((u64(usize(__offsetof(WalIterator, aSegment)))) + u64(n_segment) * sizeof(WalSegment)) + u64(i_last) * sizeof(Ht_slot))
	p = &WalIterator(sqlite3_malloc64(u64(n_byte) + sizeof(Ht_slot) * u64((if i_last > u32(4096) {
		u32(4096)
	} else {
		i_last
	}))))
	if isnil(p) {
		return 7
	}
	C.memset(voidptr(p), 0, u64(n_byte))
	p.nSegment = n_segment
	a_tmp = &Ht_slot(voidptr(unsafe { (&U8(voidptr(p))) + n_byte }))
	for i = wal_frame_page(n_backfill + u32(1)); rc == 0 && i < n_segment; i++ {
		s_loc := WalHashLoc{}
		rc = wal_hash_get(p_wal, i, &s_loc)
		if rc == 0 {
			j := 0
			n_entry := 0
			a_index := &Ht_slot(0)
			if (i + 1) == n_segment {
				n_entry = int((i_last - s_loc.iZero))
			} else {
				n_entry = int((i64((isize(&u32(voidptr(s_loc.aHash))) - isize(&u32(s_loc.aPgno))) / isize(sizeof(u32)))))
			}
			a_index = unsafe { (&Ht_slot(voidptr(&p.aSegment[0] + p.nSegment))) + s_loc.iZero }
			s_loc.iZero++
			for j = 0; j < n_entry; j++ {
				a_index[j] = Ht_slot(j)
			}
			wal_mergesort(&u32(s_loc.aPgno), a_tmp, a_index, &n_entry)
			mut __c2v_lhs_tmp_72 := c2v_at(&p.aSegment[0], isize(i))
			__c2v_lhs_tmp_72.iZero = int(s_loc.iZero)
			mut __c2v_lhs_tmp_73 := c2v_at(&p.aSegment[0], isize(i))
			__c2v_lhs_tmp_73.nEntry = n_entry
			mut __c2v_lhs_tmp_74 := c2v_at(&p.aSegment[0], isize(i))
			__c2v_lhs_tmp_74.aIndex = a_index
			mut __c2v_lhs_tmp_75 := c2v_at(&p.aSegment[0], isize(i))
			__c2v_lhs_tmp_75.aPgno = &u32(s_loc.aPgno)
		}
	}
	if rc != 0 {
		wal_iterator_free(p)
		p = 0
	}
	unsafe { *pp = p }
	return rc
}

@[c:'walBusyLock']
fn wal_busy_lock(p_wal &Wal, x_busy fn (voidptr) int, p_busy_arg voidptr, lock_idx int, n int) int {
	rc := 0
	for {
		rc = wal_lock_exclusive(p_wal, lock_idx, n)
		if !(!isnil(x_busy) && rc == 5 && x_busy(voidptr(p_busy_arg))) {
			break
		}
	}
	return rc
}

@[c:'walPagesize']
fn wal_pagesize(p_wal &Wal) int {
	return (int(p_wal.hdr.szPage) & 65024) + ((int(p_wal.hdr.szPage) & 1) << 16)
}

@[c:'walRestartHdr']
fn wal_restart_hdr(p_wal &Wal, salt1 u32) {
	p_info := wal_ckpt_info(p_wal)
	i := 0
	a_salt := unsafe { &u32(&p_wal.hdr.aSalt[0]) }
	p_wal.nCkpt++
	p_wal.hdr.mxFrame = u32(0)
	sqlite3_put4byte(&U8(voidptr(unsafe { a_salt + 0 })), u32(1) + sqlite3_get4byte(&U8(voidptr(unsafe { a_salt + 0 }))))
	C.memcpy(voidptr(unsafe { &p_wal.hdr.aSalt[0] + 1 }), voidptr(&salt1), u64(4))
	wal_index_write_hdr(p_wal)
	C.c2v_atomic_store_n__u32_u32_int_((&p_info.nBackfill), u32(0), 0)
	p_info.nBackfillAttempted = u32(0)
	p_info.aReadMark[1] = u32(0)
	for i = 2; i < (8 - 3); i++ {
		p_info.aReadMark[i] = u32(4294967295)
	}
}

@[c:'walCheckpoint']
fn wal_checkpoint(p_wal &Wal, db &Sqlite3, e_mode int, x_busy fn (voidptr) int, p_busy_arg voidptr, sync_flags int, z_buf &U8) int {
	rc := 0
	sz_page := 0
	p_iter := unsafe { &WalIterator(nil) }
	i_dbpage := u32(0)
	i_frame := u32(0)
	mx_safe_frame := u32(0)
	mx_page := u32(0)
	i := 0
	p_info := &WalCkptInfo(0)
	sz_page = wal_pagesize(p_wal)
	p_info = wal_ckpt_info(p_wal)
	if p_info.nBackfill < p_wal.hdr.mxFrame {
		mx_safe_frame = p_wal.hdr.mxFrame
		mx_page = p_wal.hdr.nPage
		for i = 1; i < (8 - 3); i++ {
			y := C.c2v_atomic_load_n__u32_int_u32((unsafe { &p_info.aReadMark[0] } + i), 0)
			if mx_safe_frame > y {
				rc = wal_busy_lock(p_wal, x_busy, voidptr(p_busy_arg), (3 + i), 1)
				if rc == 0 {
					i_mark := (if i == 1 { mx_safe_frame } else { u32(4294967295) })
					C.c2v_atomic_store_n__u32_u32_int_((unsafe { &p_info.aReadMark[0] } + i), i_mark, 0)
					wal_unlock_exclusive(p_wal, (3 + i), 1)
				} else if rc == 5 {
					mx_safe_frame = y
					x_busy = 0
				} else {
					unsafe { goto walcheckpoint_out
					 }
				}
			}
		}
		if p_info.nBackfill < mx_safe_frame {
			rc = wal_iterator_init(p_wal, p_info.nBackfill, &&WalIterator(&&WalIterator(c2v_address_of(&p_iter))))
		}
		if !isnil(p_iter) && c2v_assign[int](unsafe { &rc }, int(wal_busy_lock(p_wal, x_busy, voidptr(p_busy_arg), (3 + 0), 1))) == 0 {
			n_backfill := p_info.nBackfill
			p_live := &WalIndexHdr(wal_index_hdr(p_wal))
			b_chg := C.memcmp(p_live.aSalt, p_wal.hdr.aSalt, sizeof([2]u32))
			if 0 == b_chg {
				p_info.nBackfillAttempted = mx_safe_frame
				rc = sqlite3_os_sync(p_wal.pWalFd, ((sync_flags >> 2) & 3))
				if rc == 0 {
					n_req := (I64(mx_page) * I64(sz_page))
					n_size := I64(0)
					sqlite3_os_file_control(p_wal.pDbFd, 39, unsafe { nil })
					rc = sqlite3_os_file_size(p_wal.pDbFd, &n_size)
					if rc == 0 && n_size < n_req {
						if (n_size + I64(65536) + I64(p_wal.hdr.mxFrame) * I64(sz_page)) < n_req {
							rc = sqlite3_corrupt_error(2293)
						} else {
							sqlite3_os_file_control_hint(p_wal.pDbFd, 5, voidptr(&n_req))
						}
					}
				}
				for rc == 0 && 0 == wal_iterator_next(p_iter, &i_dbpage, &i_frame) {
					i_offset := I64(0)
					if C.c2v_atomic_load_n__int_int_int((&db.u1.isInterrupted), 0) {
						rc = if int(db.mallocFailed) { 7 } else { 9 }
						break
					}
					if i_frame <= n_backfill || i_frame > mx_safe_frame || i_dbpage > mx_page {
						continue
					}
					i_offset = (I64(32) + I64((i_frame - u32(1))) * I64((sz_page + 24))) + I64(24)
					rc = sqlite3_os_read(p_wal.pWalFd, voidptr(z_buf), sz_page, i_offset)
					if rc != 0 {
						break
					}
					i_offset = I64((i_dbpage - u32(1))) * I64(sz_page)
					rc = sqlite3_os_write(p_wal.pDbFd, voidptr(z_buf), sz_page, i_offset)
					if rc != 0 {
						break
					}
				}
				sqlite3_os_file_control(p_wal.pDbFd, 37, unsafe { nil })
				if rc == 0 {
					if mx_safe_frame == wal_index_hdr(p_wal).mxFrame {
						sz_db := I64(p_wal.hdr.nPage) * I64(sz_page)
						rc = sqlite3_os_truncate(p_wal.pDbFd, sz_db)
						if rc == 0 {
							rc = sqlite3_os_sync(p_wal.pDbFd, ((sync_flags >> 2) & 3))
						}
					}
					if rc == 0 {
						C.c2v_atomic_store_n__u32_u32_int_((&p_info.nBackfill), mx_safe_frame, 0)
					}
				}
			}
			wal_unlock_exclusive(p_wal, (3 + 0), 1)
		}
		if rc == 5 {
			rc = 0
		}
	}
	if rc == 0 && e_mode != 0 {
		if p_info.nBackfill < p_wal.hdr.mxFrame {
			rc = 5
		} else if e_mode >= 2 {
			salt1 := u32(0)
			sqlite3_randomness(4, voidptr(&salt1))
			rc = wal_busy_lock(p_wal, x_busy, voidptr(p_busy_arg), (3 + 1), (8 - 3) - 1)
			if rc == 0 {
				if e_mode == 3 {
					wal_restart_hdr(p_wal, salt1)
					rc = sqlite3_os_truncate(p_wal.pWalFd, I64(0))
				}
				wal_unlock_exclusive(p_wal, (3 + 1), (8 - 3) - 1)
			}
		}
	}
	walcheckpoint_out:
	wal_iterator_free(p_iter)
	return rc
}

@[c:'walLimitSize']
fn wal_limit_size(p_wal &Wal, n_max I64) {
	sz := I64(0)
	rx := 0
	sqlite3_begin_benign_malloc()
	rx = sqlite3_os_file_size(p_wal.pWalFd, &sz)
	if rx == 0 && (sz > n_max) {
		rx = sqlite3_os_truncate(p_wal.pWalFd, n_max)
	}
	sqlite3_end_benign_malloc()
	if rx {
		sqlite3_log(rx, c'cannot limit WAL size: %s', voidptr(p_wal.zWalName))
	}
}

@[c:'sqlite3WalClose']
fn sqlite3_wal_close(p_wal &Wal, db &Sqlite3, sync_flags int, n_buf int, z_buf &U8) int {
	rc := 0
	if p_wal {
		is_delete := 0
		if usize(z_buf) != usize(0) && 0 == c2v_assign[int](unsafe { &rc }, int(sqlite3_os_lock(p_wal.pDbFd, 4))) {
			if int(p_wal.exclusiveMode) == 0 {
				p_wal.exclusiveMode = U8(1)
			}
			rc = sqlite3_wal_checkpoint_vdup9(p_wal, db, 0, unsafe { nil }, unsafe { nil }, sync_flags, n_buf, z_buf, unsafe { nil }, unsafe { nil })
			if rc == 0 {
				b_persist := -1
				sqlite3_os_file_control_hint(p_wal.pDbFd, 10, voidptr(&b_persist))
				if b_persist != 1 {
					is_delete = 1
				} else if p_wal.mxWalSize >= I64(0) {
					wal_limit_size(p_wal, I64(0))
				}
			}
		}
		wal_index_close(p_wal, is_delete)
		sqlite3_os_close(p_wal.pWalFd)
		if is_delete {
			sqlite3_begin_benign_malloc()
			sqlite3_os_delete(p_wal.pVfs, p_wal.zWalName, 0)
			sqlite3_end_benign_malloc()
		}
		sqlite3_free(voidptr(p_wal.apWiData))
		sqlite3_free(voidptr(p_wal))
	}
	return rc
}

@[c:'walIndexTryHdr']
fn wal_index_try_hdr(p_wal &Wal, p_changed &int) int {
	a_cksum := [2]u32{}
	h1 := WalIndexHdr{}
	h2 := WalIndexHdr{}

	a_hdr := &WalIndexHdr(0)
	a_hdr = wal_index_hdr(p_wal)
	C.memcpy(voidptr(&h1), voidptr(unsafe { a_hdr + 0 }), sizeof(h1))
	wal_shm_barrier(p_wal)
	C.memcpy(voidptr(&h2), voidptr(unsafe { a_hdr + 1 }), sizeof(h2))
	if C.memcmp(voidptr(&h1), voidptr(&h2), sizeof(h1)) != 0 {
		return 1
	}
	if int(h1.isInit) == 0 {
		return 1
	}
	wal_checksum_bytes(1, &U8(c2v_address_of(&h1)), int(sizeof(h1) - sizeof([2]u32)), unsafe { nil }, &a_cksum[0])
	if a_cksum[0] != h1.aCksum[0] || a_cksum[1] != h1.aCksum[1] {
		return 1
	}
	if C.memcmp(voidptr(&p_wal.hdr), voidptr(&h1), sizeof(WalIndexHdr)) {
		unsafe { *p_changed = 1 }
		C.memcpy(voidptr(&p_wal.hdr), voidptr(&h1), sizeof(WalIndexHdr))
		p_wal.szPage = u32((int(p_wal.hdr.szPage) & 65024) + ((int(p_wal.hdr.szPage) & 1) << 16))
	}
	return 0
}

@[c:'walIndexReadHdr']
fn wal_index_read_hdr(p_wal &Wal, p_changed &int) int {
	rc := 0
	bad_hdr := 0
	page0 := &u32(0)
	rc = wal_index_page(p_wal, 0, &&u32(&&u32(c2v_address_of(&page0))))
	if rc != 0 {
		if rc == (8 | (5 << 8)) {
			p_wal.bShmUnreliable = U8(1)
			p_wal.exclusiveMode = U8(2)
			unsafe { *p_changed = 1 }
		} else {
			return rc
		}
	} else {
	}
	bad_hdr = (if page0 { wal_index_try_hdr(p_wal, p_changed) } else { 1 })
	if bad_hdr {
		if int(p_wal.bShmUnreliable) == 0 && (int(p_wal.readOnly) & 2) {
			rc = wal_lock_shared(p_wal, 0)
			if 0 == rc {
				wal_unlock_shared(p_wal, 0)
				rc = (8 | (1 << 8))
			}
		} else {
			b_write_lock := int(p_wal.writeLock)
			if b_write_lock || 0 == c2v_assign[int](unsafe { &rc }, int(wal_lock_exclusive(p_wal, 0, 1))) {
				if !b_write_lock {
					p_wal.writeLock = U8(2)
				}
				rc = wal_index_page(p_wal, 0, &&u32(&&u32(c2v_address_of(&page0))))
				if 0 == rc {
					bad_hdr = wal_index_try_hdr(p_wal, p_changed)
					if bad_hdr {
						rc = wal_index_recover(p_wal)
						unsafe { *p_changed = 1 }
					}
				}
				if b_write_lock == 0 {
					p_wal.writeLock = U8(0)
					wal_unlock_exclusive(p_wal, 0, 1)
				}
			}
		}
	}
	if bad_hdr == 0 && p_wal.hdr.iVersion != u32(3007000) {
		rc = sqlite3_cantopen_error(2747)
	}
	if p_wal.bShmUnreliable {
		if rc != 0 {
			wal_index_close(p_wal, 0)
			p_wal.bShmUnreliable = U8(0)
			if rc == (10 | (2 << 8)) {
				rc = (-1)
			}
		}
		p_wal.exclusiveMode = U8(0)
	}
	return rc
}

@[c:'walBeginShmUnreliable']
fn wal_begin_shm_unreliable(p_wal &Wal, p_changed &int) int {
	sz_wal := I64(0)
	i_offset := I64(0)
	a_buf := [32]U8{}
	a_frame := unsafe { &U8(nil) }
	sz_frame := 0
	a_data := &U8(0)
	p_dummy := &voidptr(0)
	rc := 0
	a_save_cksum := [2]u32{}
	rc = wal_lock_shared(p_wal, (3 + 0))
	if rc != 0 {
		if rc == 5 {
			rc = (-1)
		}
		unsafe { goto begin_unreliable_shm_out
		 }
	}
	p_wal.readLock = I16(0)
	rc = sqlite3_os_shm_map(p_wal.pDbFd, 0, int((sizeof(Ht_slot) * u64((4096 * 2)) + u64(4096) * sizeof(u32))), 0, &p_dummy)
	if rc != (8 | (5 << 8)) {
		rc = (if rc == 8 { (-1) } else { rc })
		unsafe { goto begin_unreliable_shm_out
		 }
	}
	C.memcpy(voidptr(&p_wal.hdr), voidptr(wal_index_hdr(p_wal)), sizeof(WalIndexHdr))
	rc = sqlite3_os_file_size(p_wal.pWalFd, &sz_wal)
	if rc != 0 {
		unsafe { goto begin_unreliable_shm_out
		 }
	}
	if sz_wal < I64(32) {
		unsafe { *p_changed = 1 }
		rc = (if p_wal.hdr.mxFrame == u32(0) { 0 } else { (-1) })
		unsafe { goto begin_unreliable_shm_out
		 }
	}
	rc = sqlite3_os_read(p_wal.pWalFd, voidptr(unsafe { &a_buf[0] }), 32, I64(0))
	if rc != 0 {
		unsafe { goto begin_unreliable_shm_out
		 }
	}
	if C.memcmp(voidptr(&p_wal.hdr.aSalt), voidptr(unsafe { &a_buf[0] + 16 }), u64(8)) {
		rc = (-1)
		unsafe { goto begin_unreliable_shm_out
		 }
	}
	sz_frame = int(p_wal.szPage + u32(24))
	a_frame = &U8(sqlite3_malloc64(Sqlite3_uint64(sz_frame)))
	if usize(a_frame) == usize(0) {
		rc = 7
		unsafe { goto begin_unreliable_shm_out
		 }
	}
	a_data = unsafe { a_frame + 24 }
	a_save_cksum[0] = p_wal.hdr.aFrameCksum[0]
	a_save_cksum[1] = p_wal.hdr.aFrameCksum[1]
	for i_offset = (I64(32) + I64(((p_wal.hdr.mxFrame + u32(1)) - u32(1))) * I64((p_wal.szPage + u32(24)))); i_offset + I64(sz_frame) <= sz_wal; i_offset += I64(sz_frame) {
		pgno := u32(0)
		n_truncate := u32(0)
		rc = sqlite3_os_read(p_wal.pWalFd, voidptr(a_frame), sz_frame, i_offset)
		if rc != 0 {
			break
		}
		if !wal_decode_frame(p_wal, &pgno, &n_truncate, a_data, a_frame) {
			break
		}
		if n_truncate {
			rc = (-1)
			break
		}
	}
	p_wal.hdr.aFrameCksum[0] = a_save_cksum[0]
	p_wal.hdr.aFrameCksum[1] = a_save_cksum[1]
	begin_unreliable_shm_out:
	sqlite3_free(voidptr(a_frame))
	if rc != 0 {
		i := 0
		for i = 0; i < p_wal.nWiData; i++ {
			sqlite3_free(voidptr(p_wal.apWiData[i]))
			p_wal.apWiData[i] = 0
		}
		p_wal.bShmUnreliable = U8(0)
		sqlite3_wal_end_read_transaction(p_wal)
		unsafe { *p_changed = 1 }
	}
	return rc
}

@[c:'walTryBeginRead']
fn wal_try_begin_read(p_wal &Wal, p_changed &int, use_wal int, p_cnt &int) int {
	p_info := &WalCkptInfo(0)
	rc := 0
	unsafe { (*p_cnt)++ }
	if (unsafe { *p_cnt }) > 5 {
		n_delay := 1
		cnt := ((unsafe { *p_cnt }) & ~0)
		if cnt > 100 {
			return 15
		}
		if (unsafe { *p_cnt }) >= 10 {
			n_delay = (cnt - 9) * (cnt - 9) * 39
		}
		sqlite3_os_sleep(p_wal.pVfs, n_delay)
		unsafe { *p_cnt &= ~0 }
	}
	if !use_wal {
		if int(p_wal.bShmUnreliable) == 0 {
			rc = wal_index_read_hdr(p_wal, p_changed)
		}
		if rc == 5 {
			if usize(p_wal.apWiData[0]) == usize(0) {
				rc = (-1)
			} else {
				rc = wal_lock_shared(p_wal, 2)
				if 0 == rc {
					wal_unlock_shared(p_wal, 2)
					rc = (-1)
				} else if rc == 5 {
					rc = (5 | (1 << 8))
				}
			}
		}
		if rc != 0 {
			return rc
		} else if p_wal.bShmUnreliable {
			return wal_begin_shm_unreliable(p_wal, p_changed)
		}
	}
	p_info = wal_ckpt_info(p_wal)
	mx_read_mark := u32(0)
	mx_i := 0
	i := 0
	mx_frame := u32(0)
	if !use_wal && C.c2v_atomic_load_n__u32_int_u32((&p_info.nBackfill), 0) == p_wal.hdr.mxFrame {
		rc = wal_lock_shared(p_wal, (3 + 0))
		wal_shm_barrier(p_wal)
		if rc == 0 {
			if C.memcmp(voidptr(wal_index_hdr(p_wal)), voidptr(&p_wal.hdr), sizeof(WalIndexHdr)) {
				wal_unlock_shared(p_wal, (3 + 0))
				return -1
			}
			p_wal.readLock = I16(0)
			return 0
		} else if rc != 5 {
			return rc
		}
	}
	mx_read_mark = u32(0)
	mx_i = 0
	mx_frame = p_wal.hdr.mxFrame
	for i = 1; i < (8 - 3); i++ {
		this_mark := C.c2v_atomic_load_n__u32_int_u32((unsafe { &p_info.aReadMark[0] } + i), 0)
		if mx_read_mark <= this_mark && this_mark <= mx_frame {
			mx_read_mark = this_mark
			mx_i = i
		}
	}
	if (int(p_wal.readOnly) & 2) == 0 && (mx_read_mark < mx_frame || mx_i == 0) {
		for i = 1; i < (8 - 3); i++ {
			rc = wal_lock_exclusive(p_wal, (3 + i), 1)
			if rc == 0 {
				C.c2v_atomic_store_n__u32_u32_int_((unsafe { &p_info.aReadMark[0] } + i), mx_frame, 0)
				mx_read_mark = mx_frame
				mx_i = i
				wal_unlock_exclusive(p_wal, (3 + i), 1)
				break
			} else if rc != 5 {
				return rc
			}
		}
	}
	if mx_i == 0 {
		return if rc == 5 { (-1) } else { (8 | (5 << 8)) }
	}
	rc = wal_lock_shared(p_wal, (3 + mx_i))
	if rc {
		return if (rc & 255) == 5 { (-1) } else { rc }
	}
	p_wal.minFrame = C.c2v_atomic_load_n__u32_int_u32((&p_info.nBackfill), 0) + u32(1)
	wal_shm_barrier(p_wal)
	if C.c2v_atomic_load_n__u32_int_u32((unsafe { &p_info.aReadMark[0] } + mx_i), 0) != mx_read_mark || C.memcmp(voidptr(wal_index_hdr(p_wal)), voidptr(&p_wal.hdr), sizeof(WalIndexHdr)) {
		wal_unlock_shared(p_wal, (3 + mx_i))
		return -1
	} else {
		p_wal.readLock = I16(mx_i)
	}
	return rc
}

@[c:'walBeginReadTransaction']
fn wal_begin_read_transaction(p_wal &Wal, p_changed &int) int {
	rc := 0
	cnt := 0
	for {
		rc = wal_try_begin_read(p_wal, p_changed, 0, &cnt)
		if !(rc == (-1)) {
			break
		}
	}
	return rc
}

@[c:'sqlite3WalBeginReadTransaction']
fn sqlite3_wal_begin_read_transaction(p_wal &Wal, p_changed &int) int {
	rc := 0
	rc = wal_begin_read_transaction(p_wal, p_changed)
	return rc
}

@[c:'sqlite3WalEndReadTransaction']
fn sqlite3_wal_end_read_transaction(p_wal &Wal) {
	if int(p_wal.readLock) >= 0 {
		sqlite3_wal_end_write_transaction(p_wal)
		wal_unlock_shared(p_wal, (3 + int(p_wal.readLock)))
		p_wal.readLock = I16(-1)
	}
}

@[c:'walFindFrame']
fn wal_find_frame(p_wal &Wal, pgno Pgno, pi_read &u32) int {
	i_read := u32(0)
	i_last := p_wal.hdr.mxFrame
	i_hash := 0
	i_min_hash := 0
	if i_last == u32(0) || (int(p_wal.readLock) == 0 && int(p_wal.bShmUnreliable) == 0) {
		unsafe { *pi_read = u32(0) }
		return 0
	}
	i_min_hash = wal_frame_page(p_wal.minFrame)
	for i_hash = wal_frame_page(i_last); i_hash >= i_min_hash; i_hash-- {
		s_loc := WalHashLoc{}
		i_key := 0
		n_collide := 0
		rc := 0
		ih := u32(0)
		rc = wal_hash_get(p_wal, i_hash, &s_loc)
		if rc != 0 {
			return rc
		}
		n_collide = (4096 * 2)
		i_key = wal_hash(pgno)
		for {
			ih = u32(C.c2v_atomic_load_n__Ht_slot_int_Ht_slot((unsafe { s_loc.aHash + i_key }), 0))
			if !(ih != u32(0)) {
				break
			}
			i_frame := ih + s_loc.iZero
			if i_frame <= i_last && i_frame >= p_wal.minFrame && s_loc.aPgno[(ih - u32(1)) & u32((4096 - 1))] == pgno {
				i_read = i_frame
			}
			if (n_collide--) == 0 {
				unsafe { *pi_read = u32(0) }
				return sqlite3_corrupt_error(3600)
			}
			i_key = wal_next_hash(i_key)
		}
		if i_read {
			break
		}
	}
	unsafe { *pi_read = i_read }
	return 0
}

@[c:'sqlite3WalFindFrame']
fn sqlite3_wal_find_frame(p_wal &Wal, pgno Pgno, pi_read &u32) int {
	rc := 0
	rc = wal_find_frame(p_wal, pgno, pi_read)
	return rc
}

@[c:'sqlite3WalReadFrame']
fn sqlite3_wal_read_frame(p_wal &Wal, i_read u32, n_out int, p_out &U8) int {
	sz := 0
	i_offset := I64(0)
	sz = int(p_wal.hdr.szPage)
	sz = (sz & 65024) + ((sz & 1) << 16)
	i_offset = (I64(32) + I64((i_read - u32(1))) * I64((sz + 24))) + I64(24)
	return sqlite3_os_read(p_wal.pWalFd, voidptr(p_out), (if n_out > sz { sz } else { n_out }), i_offset)
}

@[c:'sqlite3WalDbsize']
fn sqlite3_wal_dbsize(p_wal &Wal) Pgno {
	if !isnil(p_wal) && (int(p_wal.readLock) >= 0) {
		return p_wal.hdr.nPage
	}
	return Pgno(0)
}

@[c:'sqlite3WalBeginWriteTransaction']
fn sqlite3_wal_begin_write_transaction(p_wal &Wal) int {
	rc := 0
	if p_wal.readOnly {
		return 8
	}
	rc = wal_lock_exclusive(p_wal, 0, 1)
	if rc {
		return rc
	}
	p_wal.writeLock = U8(1)
	if C.memcmp(voidptr(&p_wal.hdr), voidptr(wal_index_hdr(p_wal)), sizeof(WalIndexHdr)) != 0 {
		rc = (5 | (2 << 8))
	}
	if rc != 0 {
		wal_unlock_exclusive(p_wal, 0, 1)
		p_wal.writeLock = U8(0)
	}
	return rc
}

@[c:'sqlite3WalEndWriteTransaction']
fn sqlite3_wal_end_write_transaction(p_wal &Wal) int {
	if p_wal.writeLock {
		wal_unlock_exclusive(p_wal, 0, 1)
		p_wal.writeLock = U8(0)
		p_wal.iReCksum = u32(0)
		p_wal.truncateOnCommit = U8(0)
	}
	return 0
}

@[c:'sqlite3WalUndo']
fn sqlite3_wal_undo(p_wal &Wal, x_undo fn (voidptr, Pgno) int, p_undo_ctx voidptr) int {
	rc := 0
	if p_wal.writeLock {
		i_max := p_wal.hdr.mxFrame
		i_frame := Pgno(0)
		C.memcpy(voidptr(&p_wal.hdr), voidptr(wal_index_hdr(p_wal)), sizeof(WalIndexHdr))
		for i_frame = p_wal.hdr.mxFrame + u32(1); (rc == 0) && i_frame <= i_max; i_frame++ {
			rc = x_undo(voidptr(p_undo_ctx), wal_frame_pgno(p_wal, i_frame))
		}
		if i_max != p_wal.hdr.mxFrame {
			wal_cleanup_hash(p_wal)
		}
		p_wal.iReCksum = u32(0)
	}
	return rc
}

@[c:'sqlite3WalSavepoint']
fn sqlite3_wal_savepoint(p_wal &Wal, a_wal_data &u32) {
	a_wal_data[0] = p_wal.hdr.mxFrame
	a_wal_data[1] = p_wal.hdr.aFrameCksum[0]
	a_wal_data[2] = p_wal.hdr.aFrameCksum[1]
	a_wal_data[3] = p_wal.nCkpt
}

@[c:'sqlite3WalSavepointUndo']
fn sqlite3_wal_savepoint_undo(p_wal &Wal, a_wal_data &u32) int {
	rc := 0
	if a_wal_data[3] != p_wal.nCkpt {
		a_wal_data[0] = u32(0)
		a_wal_data[3] = p_wal.nCkpt
	}
	if a_wal_data[0] < p_wal.hdr.mxFrame {
		p_wal.hdr.mxFrame = a_wal_data[0]
		p_wal.hdr.aFrameCksum[0] = a_wal_data[1]
		p_wal.hdr.aFrameCksum[1] = a_wal_data[2]
		wal_cleanup_hash(p_wal)
		if p_wal.iReCksum > p_wal.hdr.mxFrame {
			p_wal.iReCksum = u32(0)
		}
	}
	return rc
}

@[c:'walRestartLog']
fn wal_restart_log(p_wal &Wal) int {
	rc := 0
	cnt := 0
	if int(p_wal.readLock) == 0 {
		p_info := wal_ckpt_info(p_wal)
		if p_info.nBackfill > u32(0) {
			salt1 := u32(0)
			sqlite3_randomness(4, voidptr(&salt1))
			rc = wal_lock_exclusive(p_wal, (3 + 1), (8 - 3) - 1)
			if rc == 0 {
				wal_restart_hdr(p_wal, salt1)
				wal_unlock_exclusive(p_wal, (3 + 1), (8 - 3) - 1)
			} else if rc != 5 {
				return rc
			}
		}
		wal_unlock_shared(p_wal, (3 + 0))
		p_wal.readLock = I16(-1)
		cnt = 0
		for {
			not_used := 0
			rc = wal_try_begin_read(p_wal, &not_used, 1, &cnt)
			if !(rc == (-1)) {
				break
			}
		}
	}
	return rc
}

struct WalWriter {
	pWal       &Wal
	pFd        &Sqlite3_file
	iSyncPoint Sqlite3_int64
	syncFlags  int
	szPage     int
}

@[c:'walWriteToLog']
fn wal_write_to_log(p &WalWriter, p_content voidptr, i_amt int, i_offset Sqlite3_int64) int {
	rc := 0
	if i_offset < p.iSyncPoint && i_offset + Sqlite3_int64(i_amt) >= p.iSyncPoint {
		i_first_amt := int((p.iSyncPoint - i_offset))
		rc = sqlite3_os_write(p.pFd, voidptr(p_content), i_first_amt, i_offset)
		if rc {
			return rc
		}
		i_offset += Sqlite3_int64(i_first_amt)
		i_amt -= i_first_amt
		p_content = voidptr((unsafe { &i8(p_content) + i_first_amt }))
		rc = sqlite3_os_sync(p.pFd, (p.syncFlags & 3))
		if i_amt == 0 || rc {
			return rc
		}
	}
	rc = sqlite3_os_write(p.pFd, voidptr(p_content), i_amt, i_offset)
	return rc
}

@[c:'walWriteOneFrame']
fn wal_write_one_frame(p &WalWriter, p_page &PgHdr, n_truncate int, i_offset Sqlite3_int64) int {
	rc := 0
	p_data := &voidptr(0)
	a_frame := [24]U8{}
	p_data = p_page.pData
	wal_encode_frame(p.pWal, p_page.pgno, u32(n_truncate), p_data, &a_frame[0])
	rc = wal_write_to_log(p, voidptr(unsafe { &a_frame[0] }), int(sizeof([24]U8)), i_offset)
	if rc {
		return rc
	}
	rc = wal_write_to_log(p, voidptr(p_data), p.szPage, Sqlite3_int64(u64(i_offset) + sizeof([24]U8)))
	return rc
}

@[c:'walRewriteChecksums']
fn wal_rewrite_checksums(p_wal &Wal, i_last u32) int {
	sz_page := int(p_wal.szPage)
	rc := 0
	a_buf := &U8(0)
	a_frame := [24]U8{}
	i_read := u32(0)
	i_cksum_off := I64(0)
	a_buf = sqlite3_malloc(sz_page + 24)
	if usize(a_buf) == usize(0) {
		return 7
	}
	if p_wal.iReCksum == u32(1) {
		i_cksum_off = I64(24)
	} else {
		i_cksum_off = (I64(32) + I64(((p_wal.iReCksum - u32(1)) - u32(1))) * I64((sz_page + 24))) + I64(16)
	}
	rc = sqlite3_os_read(p_wal.pWalFd, voidptr(a_buf), int(sizeof(u32) * u64(2)), i_cksum_off)
	p_wal.hdr.aFrameCksum[0] = sqlite3_get4byte(a_buf)
	p_wal.hdr.aFrameCksum[1] = sqlite3_get4byte(unsafe { a_buf + sizeof(u32) })
	i_read = p_wal.iReCksum
	p_wal.iReCksum = u32(0)
	for ; rc == 0 && i_read <= i_last; i_read++ {
		i_off := (I64(32) + I64((i_read - u32(1))) * I64((sz_page + 24)))
		rc = sqlite3_os_read(p_wal.pWalFd, voidptr(a_buf), sz_page + 24, i_off)
		if rc == 0 {
			i_pgno := u32(0)
			n_db_size := u32(0)

			i_pgno = sqlite3_get4byte(a_buf)
			n_db_size = sqlite3_get4byte(unsafe { a_buf + 4 })
			wal_encode_frame(p_wal, i_pgno, n_db_size, unsafe { a_buf + 24 }, &a_frame[0])
			rc = sqlite3_os_write(p_wal.pWalFd, voidptr(unsafe { &a_frame[0] }), int(sizeof([24]U8)), i_off)
		}
	}
	sqlite3_free(voidptr(a_buf))
	return rc
}

@[c:'walFrames']
fn wal_frames(p_wal &Wal, sz_page int, p_list &PgHdr, n_truncate Pgno, is_commit int, sync_flags int) int {
	rc := 0
	i_frame := u32(0)
	p := &PgHdr(0)
	p_last := unsafe { &PgHdr(nil) }
	n_extra := 0
	sz_frame := 0
	i_offset := I64(0)
	w := WalWriter{}
	i_first := u32(0)
	p_live := &WalIndexHdr(0)
	p_live = &WalIndexHdr(wal_index_hdr(p_wal))
	if C.memcmp(voidptr(&p_wal.hdr), voidptr(p_live), sizeof(WalIndexHdr)) != 0 {
		i_first = p_live.mxFrame + u32(1)
	}
	rc = wal_restart_log(p_wal)
	if 0 != rc {
		return rc
	}
	i_frame = p_wal.hdr.mxFrame
	if i_frame == u32(0) {
		a_wal_hdr := [32]U8{}
		a_cksum := [2]u32{}
		sqlite3_put4byte(unsafe { &a_wal_hdr[0] + 0 }, u32((931071618 | 0)))
		sqlite3_put4byte(unsafe { &a_wal_hdr[0] + 4 }, u32(3007000))
		sqlite3_put4byte(unsafe { &a_wal_hdr[0] + 8 }, u32(sz_page))
		sqlite3_put4byte(unsafe { &a_wal_hdr[0] + 12 }, p_wal.nCkpt)
		if p_wal.nCkpt == u32(0) {
			sqlite3_randomness(8, p_wal.hdr.aSalt)
		}
		C.memcpy(voidptr(unsafe { &a_wal_hdr[0] + 16 }), p_wal.hdr.aSalt, u64(8))
		wal_checksum_bytes(1, &a_wal_hdr[0], 32 - 2 * 4, unsafe { nil }, &a_cksum[0])
		sqlite3_put4byte(unsafe { &a_wal_hdr[0] + 24 }, a_cksum[0])
		sqlite3_put4byte(unsafe { &a_wal_hdr[0] + 28 }, a_cksum[1])
		p_wal.szPage = u32(sz_page)
		p_wal.hdr.bigEndCksum = U8(0)
		p_wal.hdr.aFrameCksum[0] = a_cksum[0]
		p_wal.hdr.aFrameCksum[1] = a_cksum[1]
		p_wal.truncateOnCommit = U8(1)
		rc = sqlite3_os_write(p_wal.pWalFd, voidptr(unsafe { &a_wal_hdr[0] }), int(sizeof([32]U8)), I64(0))
		if rc != 0 {
			return rc
		}
		if p_wal.syncHeader {
			rc = sqlite3_os_sync(p_wal.pWalFd, ((sync_flags >> 2) & 3))
			if rc {
				return rc
			}
		}
	}
	if int(p_wal.szPage) != sz_page {
		return sqlite3_corrupt_error(4127)
	}
	w.pWal = p_wal
	w.pFd = p_wal.pWalFd
	w.iSyncPoint = Sqlite3_int64(0)
	w.syncFlags = sync_flags
	w.szPage = sz_page
	i_offset = (I64(32) + I64(((i_frame + u32(1)) - u32(1))) * I64((sz_page + 24)))
	sz_frame = sz_page + 24
	for p = p_list; p; p = p.pDirty {
		n_db_size := 0
		if i_first && (!isnil(p.pDirty) || is_commit == 0) {
			i_write := u32(0)
			wal_find_frame(p_wal, p.pgno, &i_write)
			if i_write >= i_first {
				i_off := (I64(32) + I64((i_write - u32(1))) * I64((sz_page + 24))) + I64(24)
				p_data := &voidptr(0)
				if p_wal.iReCksum == u32(0) || i_write < p_wal.iReCksum {
					p_wal.iReCksum = i_write
				}
				p_data = p.pData
				rc = sqlite3_os_write(p_wal.pWalFd, voidptr(p_data), sz_page, i_off)
				if rc {
					return rc
				}
				p.flags &= ~64
				continue
			}
		}
		i_frame++
		n_db_size = int(if (is_commit && usize(p.pDirty) == usize(0)) { n_truncate } else { Pgno(0) })
		rc = wal_write_one_frame(&w, p, n_db_size, i_offset)
		if rc {
			return rc
		}
		p_last = p
		i_offset += I64(sz_frame)
		p.flags |= 64
	}
	if is_commit && p_wal.iReCksum {
		rc = wal_rewrite_checksums(p_wal, i_frame)
		if rc {
			return rc
		}
	}
	if is_commit && (sync_flags & 3) != 0 {
		b_sync := 1
		if p_wal.padToSectorBoundary {
			sector_size := sqlite3_sector_size(p_wal.pWalFd)
			w.iSyncPoint = ((i_offset + I64(sector_size) - I64(1)) / I64(sector_size)) * I64(sector_size)
			b_sync = (w.iSyncPoint == i_offset)
			for i_offset < w.iSyncPoint {
				rc = wal_write_one_frame(&w, p_last, int(n_truncate), i_offset)
				if rc {
					return rc
				}
				i_offset += I64(sz_frame)
				n_extra++
			}
		}
		if b_sync {
			rc = sqlite3_os_sync(w.pFd, (sync_flags & 3))
		}
	}
	if is_commit && int(p_wal.truncateOnCommit) && p_wal.mxWalSize >= I64(0) {
		sz := p_wal.mxWalSize
		if (I64(32) + I64(((i_frame + u32(n_extra) + u32(1)) - u32(1))) * I64((sz_page + 24))) > p_wal.mxWalSize {
			sz = (I64(32) + I64(((i_frame + u32(n_extra) + u32(1)) - u32(1))) * I64((sz_page + 24)))
		}
		wal_limit_size(p_wal, sz)
		p_wal.truncateOnCommit = U8(0)
	}
	i_frame = p_wal.hdr.mxFrame
	for p = p_list; !isnil(p) && rc == 0; p = p.pDirty {
		if (int(p.flags) & 64) == 0 {
			continue
		}
		i_frame++
		rc = wal_index_append(p_wal, i_frame, p.pgno)
	}
	for rc == 0 && n_extra > 0 {
		i_frame++
		n_extra--
		rc = wal_index_append(p_wal, i_frame, p_last.pgno)
	}
	if rc == 0 {
		p_wal.hdr.szPage = U16(((sz_page & 65280) | (sz_page >> 16)))
		p_wal.hdr.mxFrame = i_frame
		if is_commit {
			p_wal.hdr.iChange++
			p_wal.hdr.nPage = n_truncate
		}
		if is_commit {
			wal_index_write_hdr(p_wal)
			p_wal.iCallback = i_frame
		}
	}
	return rc
}

@[c:'sqlite3WalFrames']
fn sqlite3_wal_frames(p_wal &Wal, sz_page int, p_list &PgHdr, n_truncate Pgno, is_commit int, sync_flags int) int {
	rc := 0
	rc = wal_frames(p_wal, sz_page, p_list, n_truncate, is_commit, sync_flags)
	return rc
}

@[c:'sqlite3WalCheckpoint']
fn sqlite3_wal_checkpoint_vdup9(p_wal &Wal, db &Sqlite3, e_mode int, x_busy fn (voidptr) int, p_busy_arg voidptr, sync_flags int, n_buf int, z_buf &U8, pn_log &int, pn_ckpt &int) int {
	rc := 0
	is_changed := 0
	e_mode2 := e_mode
	x_busy2 := x_busy
	if p_wal.readOnly {
		return 8
	}
	if x_busy2 {
	}
	if e_mode != -1 {
		rc = wal_lock_exclusive(p_wal, 1, 1)
		if rc == 0 {
			p_wal.ckptLock = U8(1)
			if e_mode != 0 {
				rc = wal_busy_lock(p_wal, x_busy2, voidptr(p_busy_arg), 0, 1)
				if rc == 0 {
					p_wal.writeLock = U8(1)
				} else if rc == 5 {
					e_mode2 = 0
					x_busy2 = 0
					rc = 0
				}
			}
		}
	} else {
		rc = 0
	}
	if rc == 0 {
		rc = wal_index_read_hdr(p_wal, &is_changed)
		if e_mode2 > 0 {
		}
		if is_changed && p_wal.pDbFd.pMethods.iVersion >= 3 {
			sqlite3_os_unfetch(p_wal.pDbFd, I64(0), unsafe { nil })
		}
	}
	if rc == 0 {
		sqlite3_fault_sim(660)
		if p_wal.hdr.mxFrame && wal_pagesize(p_wal) != n_buf {
			rc = sqlite3_corrupt_error(4393)
		} else if e_mode2 != -1 {
			rc = wal_checkpoint(p_wal, db, e_mode2, x_busy2, voidptr(p_busy_arg), sync_flags, z_buf)
		}
		if rc == 0 || rc == 5 {
			if pn_log {
				unsafe { *pn_log = int(p_wal.hdr.mxFrame) }
			}
			if pn_ckpt {
				unsafe { *pn_ckpt = int(wal_ckpt_info(p_wal).nBackfill) }
			}
		}
	}
	if is_changed {
		C.memset(voidptr(&p_wal.hdr), 0, sizeof(WalIndexHdr))
	}
	sqlite3_wal_end_write_transaction(p_wal)
	if p_wal.ckptLock {
		wal_unlock_exclusive(p_wal, 1, 1)
		p_wal.ckptLock = U8(0)
	}
	return if rc == 0 && e_mode != e_mode2 { 5 } else { rc }
}

@[c:'sqlite3WalCallback']
fn sqlite3_wal_callback(p_wal &Wal) int {
	ret := u32(0)
	if p_wal {
		ret = p_wal.iCallback
		p_wal.iCallback = u32(0)
	}
	return int(ret)
}

@[c:'sqlite3WalExclusiveMode']
fn sqlite3_wal_exclusive_mode(p_wal &Wal, op int) int {
	rc := 0
	if op == 0 {
		if int(p_wal.exclusiveMode) != 0 {
			p_wal.exclusiveMode = U8(0)
			if wal_lock_shared(p_wal, (3 + int(p_wal.readLock))) != 0 {
				p_wal.exclusiveMode = U8(1)
			}
			rc = int(p_wal.exclusiveMode) == 0
		} else {
			rc = 0
		}
	} else if op > 0 {
		wal_unlock_shared(p_wal, (3 + int(p_wal.readLock)))
		p_wal.exclusiveMode = U8(1)
		rc = 1
	} else {
		rc = int(p_wal.exclusiveMode) == 0
	}
	return rc
}

@[c:'sqlite3WalHeapMemory']
fn sqlite3_wal_heap_memory(p_wal &Wal) int {
	return int((!isnil(p_wal) && int(p_wal.exclusiveMode) == 2))
}

@[c:'sqlite3WalFile']
fn sqlite3_wal_file(p_wal &Wal) &Sqlite3_file {
	return p_wal.pWalFd
}
