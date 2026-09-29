@[translated]
module main

struct UnixUnusedFd {
	fd    int
	flags int
	pNext &UnixUnusedFd
}

struct UnixFile {
	pMethod               &Sqlite3_io_methods
	pVfs                  &Sqlite3_vfs
	pInode                &UnixInodeInfo
	h                     int
	eFileLock             u8
	ctrlFlags             u16
	lastErrno             int
	lockingContext        voidptr
	pPreallocatedUnused   &UnixUnusedFd
	zPath                 &i8
	pShm                  &UnixShm
	szChunk               int
	nFetchOut             int
	mmapSize              Sqlite3_int64
	mmapSizeActual        Sqlite3_int64
	mmapSizeMax           Sqlite3_int64
	pMapRegion            voidptr
	sectorSize            int
	deviceCharacteristics int
	openFlags             int
	fsFlags               u32
}

@[c:'posixOpen']
fn posix_open(z_file &i8, flags int, mode int) int {
	c2v_gc_register_thread()
	return C.open(z_file, flags, mode)
}

struct Unix_syscall {
	zName    &i8
	pCurrent Sqlite3_syscall_ptr
	pDefault Sqlite3_syscall_ptr
}

@[c:'robustFchown']
fn robust_fchown(fd int, uid u32, gid u32) int {
	return if c2v_fnptr_666e20282920753332(voidptr(aSyscall[21].pCurrent))() {
		0
	} else {
		c2v_fncall_666e2028696e742c207533322c207533322920696e74(voidptr(aSyscall[20].pCurrent), fd, uid, gid)
	}
}

@[c:'unixSetSystemCall']
fn unix_set_system_call(p_not_used &Sqlite3_vfs, z_name &i8, p_new_func Sqlite3_syscall_ptr) int {
	c2v_gc_register_thread()
	i := u32(0)
	rc := 12

	if usize(z_name) == usize(0) {
		rc = 0
		for i = u32(0); u64(i) < 29; i++ {
			if aSyscall[i].pDefault {
				aSyscall[i].pCurrent = aSyscall[i].pDefault
			}
		}
	} else {
		for i = u32(0); u64(i) < 29; i++ {
			if C.strcmp(z_name, aSyscall[i].zName) == 0 {
				if isnil(aSyscall[i].pDefault) {
					aSyscall[i].pDefault = aSyscall[i].pCurrent
				}
				rc = 0
				if isnil(p_new_func) {
					p_new_func = aSyscall[i].pDefault
				}
				aSyscall[i].pCurrent = p_new_func
				break
			}
		}
	}
	return rc
}

@[c:'unixGetSystemCall']
fn unix_get_system_call(p_not_used &Sqlite3_vfs, z_name &i8) Sqlite3_syscall_ptr {
	c2v_gc_register_thread()
	i := u32(0)

	for i = u32(0); u64(i) < 29; i++ {
		if C.strcmp(z_name, aSyscall[i].zName) == 0 {
			return aSyscall[i].pCurrent
		}
	}
	return unsafe { Sqlite3_syscall_ptr(nil) }
}

@[c:'unixNextSystemCall']
fn unix_next_system_call(p &Sqlite3_vfs, z_name &i8) &i8 {
	c2v_gc_register_thread()
	i := -1

	if z_name {
		for i = 0; i < 28; i++ {
			if C.strcmp(z_name, aSyscall[i].zName) == 0 {
				break
			}
		}
	}
	for i++; i < 29; i++ {
		if !isnil(aSyscall[i].pCurrent) {
			return aSyscall[i].zName
		}
	}
	return unsafe { nil }
}

fn robust_open(z &i8, f int, m u32) int {
	fd := 0
	m2 := u32(if int(m) { int(m) } else { 420 })
	for {
		fd = c2v_fnptr_666e20282669382c20696e742c20696e742920696e74(voidptr(aSyscall[0].pCurrent))(z, f | 16777216, int(m2))
		if fd < 0 {
			if (unsafe { *C.__error() }) == 4 {
				continue
			}
			break
		}
		if fd >= 3 {
			break
		}
		if (f & (2048 | 512)) == (2048 | 512) {
			c2v_fnptr_666e20282669382920696e74(voidptr(aSyscall[16].pCurrent))(z)
		}
		c2v_fnptr_666e2028696e742920696e74(voidptr(aSyscall[1].pCurrent))(fd)
		sqlite3_log(28, c'attempt to open "%s" as file descriptor %d', voidptr(z), fd)
		fd = -1
		if c2v_fnptr_666e20282669382c20696e742c20696e742920696e74(voidptr(aSyscall[0].pCurrent))(c'/dev/null', 0, int(m)) < 0 {
			break
		}
	}
	if fd >= 0 {
		if int(m) != 0 {
			statbuf := C.stat{}
			if c2v_fnptr_666e2028696e742c2026432e737461742920696e74(voidptr(aSyscall[5].pCurrent))(fd, &statbuf) == 0 && statbuf.st_size == i64(0) && (int(statbuf.st_mode) & 511) != int(m) {
				c2v_fnptr_666e2028696e742c207533322920696e74(voidptr(aSyscall[14].pCurrent))(fd, m)
			}
		}
	}
	return fd
}

@[c:'unixEnterMutex']
fn unix_enter_mutex() {
	sqlite3_mutex_enter(unixBigLock)
}

@[c:'unixLeaveMutex']
fn unix_leave_mutex() {
	sqlite3_mutex_leave(unixBigLock)
}

fn robust_ftruncate(h int, sz Sqlite3_int64) int {
	rc := 0
	for {
		rc = c2v_fnptr_666e2028696e742c206936342920696e74(voidptr(aSyscall[6].pCurrent))(h, sz)
		if !(rc < 0 && (unsafe { *C.__error() }) == 4) {
			break
		}
	}
	return rc
}

@[c:'sqliteErrorFromPosixError']
fn sqlite_error_from_posix_error(posix_error int, sqlite_io_err int) int {
	match posix_error {
		13, 35, 60, 16, 4, 77 {
			return 5
		}
		1 {
			return 3
		}
		else {
			return sqlite_io_err
		}
	}
	return 0
}

struct VxworksFileId {
	pNext          &VxworksFileId
	nRef           int
	nName          int
	zCanonicalName &i8
}

struct UnixFileId {
	dev u64
	ino U64
}

struct UnixInodeInfo {
	fileId       UnixFileId
	pLockMutex   &Sqlite3_mutex
	nShared      int
	nLock        int
	eFileLock    u8
	bProcessLock u8
	pUnused      &UnixUnusedFd
	nRef         int
	pShmNode     &UnixShmNode
	pNext        &UnixInodeInfo
	pPrev        &UnixInodeInfo
	sharedByte   u64
}

@[c:'unixLogErrorAtLine']
fn unix_log_error_at_line(errcode int, z_func &i8, z_path &i8, i_line int) int {
	z_err := &i8(0)
	i_errno := (unsafe { *C.__error() })
	z_err = c''
	if usize(z_path) == usize(0) {
		z_path = c''
	}
	sqlite3_log(errcode, c'os_unix.c:%d: (%d) %s(%s) - %s', i_line, i_errno, voidptr(z_func), voidptr(z_path), voidptr(z_err))
	return errcode
}

fn robust_close(p_file &UnixFile, h int, lineno int) {
	if c2v_fnptr_666e2028696e742920696e74(voidptr(aSyscall[1].pCurrent))(h) {
		unix_log_error_at_line((10 | (16 << 8)), c'close', unsafe { if p_file {
			p_file.zPath
		} else {
			&i8(nil)
		} }, lineno)
	}
}

@[c:'storeLastErrno']
fn store_last_errno(p_file &UnixFile, error int) {
	p_file.lastErrno = error
}

@[c:'closePendingFds']
fn close_pending_fds(p_file &UnixFile) {
	p_inode := p_file.pInode
	p := &UnixUnusedFd(0)
	p_next := &UnixUnusedFd(0)
	for p = p_inode.pUnused; p; p = p_next {
		p_next = p.pNext
		robust_close(p_file, p.fd, 1478)
		sqlite3_free(voidptr(p))
	}
	p_inode.pUnused = 0
}

@[c:'releaseInodeInfo']
fn release_inode_info(p_file &UnixFile) {
	p_inode := p_file.pInode
	if p_inode {
		p_inode.nRef--
		if p_inode.nRef == 0 {
			sqlite3_mutex_enter(p_inode.pLockMutex)
			close_pending_fds(p_file)
			sqlite3_mutex_leave(p_inode.pLockMutex)
			if p_inode.pPrev {
				p_inode.pPrev.pNext = p_inode.pNext
			} else {
				inodeList = p_inode.pNext
			}
			if p_inode.pNext {
				p_inode.pNext.pPrev = p_inode.pPrev
			}
			sqlite3_mutex_free(p_inode.pLockMutex)
			sqlite3_free(voidptr(p_inode))
		}
	}
}

@[c:'findInodeInfo']
fn find_inode_info(p_file &UnixFile, pp_inode &&UnixInodeInfo) int {
	rc := 0
	fd := 0
	file_id := UnixFileId{}
	statbuf := C.stat{}
	p_inode := unsafe { &UnixInodeInfo(nil) }
	fd = p_file.h
	rc = c2v_fnptr_666e2028696e742c2026432e737461742920696e74(voidptr(aSyscall[5].pCurrent))(fd, &statbuf)
	if rc != 0 {
		store_last_errno(p_file, (unsafe { *C.__error() }))
		return 10
	}
	if statbuf.st_size == i64(0) && (p_file.fsFlags & u32(1)) != u32(0) {
		for {
			rc = int(c2v_fnptr_666e2028696e742c20766f69647074722c207573697a6529206973697a65(voidptr(aSyscall[11].pCurrent))(fd, voidptr(c'S'), usize(1)))
			if !(rc < 0 && (unsafe { *C.__error() }) == 4) {
				break
			}
		}
		if rc != 1 {
			store_last_errno(p_file, (unsafe { *C.__error() }))
			return 10
		}
		if C.fsync(fd) {
			store_last_errno(p_file, (unsafe { *C.__error() }))
			return 10 | (4 << 8)
		}
		rc = c2v_fnptr_666e2028696e742c2026432e737461742920696e74(voidptr(aSyscall[5].pCurrent))(fd, &statbuf)
		if rc != 0 {
			store_last_errno(p_file, (unsafe { *C.__error() }))
			return 10
		}
	}
	C.memset(voidptr(&file_id), 0, sizeof(file_id))
	file_id.dev = statbuf.st_dev
	file_id.ino = U64(statbuf.st_ino)
	p_inode = inodeList
	for !isnil(p_inode) && C.memcmp(voidptr(&file_id), voidptr(&p_inode.fileId), sizeof(file_id)) {
		p_inode = p_inode.pNext
	}
	if usize(p_inode) == usize(0) {
		p_inode = sqlite3_malloc64(Sqlite3_uint64(sizeof(UnixInodeInfo)))
		if usize(p_inode) == usize(0) {
			return 7
		}
		C.memset(voidptr(p_inode), 0, sizeof(UnixInodeInfo))
		C.memcpy(voidptr(&p_inode.fileId), voidptr(&file_id), sizeof(file_id))
		if sqlite3Config.bCoreMutex {
			p_inode.pLockMutex = sqlite3_mutex_alloc(0)
			if usize(p_inode.pLockMutex) == usize(0) {
				sqlite3_free(voidptr(p_inode))
				return 7
			}
		}
		p_inode.nRef = 1
		p_inode.pNext = inodeList
		p_inode.pPrev = 0
		if inodeList {
			inodeList.pPrev = p_inode
		}
		inodeList = p_inode
	} else {
		p_inode.nRef++
	}
	unsafe { *pp_inode = p_inode }
	return 0
}

@[c:'fileHasMoved']
fn file_has_moved(p_file &UnixFile) int {
	buf := C.stat{}
	return int(usize(p_file.pInode) != usize(0) && (c2v_fncall_666e20282669382c2026432e737461742920696e74(voidptr(aSyscall[4].pCurrent), p_file.zPath, &buf) != 0 || U64(buf.st_ino) != p_file.pInode.fileId.ino))
}

@[c:'verifyDbFile']
fn verify_db_file(p_file &UnixFile) {
	buf := C.stat{}
	rc := 0
	if int(p_file.ctrlFlags) & 128 {
		return
	}
	rc = c2v_fnptr_666e2028696e742c2026432e737461742920696e74(voidptr(aSyscall[5].pCurrent))(p_file.h, &buf)
	if rc != 0 {
		sqlite3_log(28, c'cannot fstat db file %s', voidptr(p_file.zPath))
		return
	}
	if int(buf.st_nlink) == 0 {
		sqlite3_log(28, c'file unlinked while open: %s', voidptr(p_file.zPath))
		return
	}
	if int(buf.st_nlink) > 1 {
		sqlite3_log(28, c'multiple links to file: %s', voidptr(p_file.zPath))
		return
	}
	if file_has_moved(p_file) {
		sqlite3_log(28, c'file renamed while open: %s', voidptr(p_file.zPath))
		return
	}
}

@[c:'unixCheckReservedLock']
fn unix_check_reserved_lock(id &Sqlite3_file, p_res_out &int) int {
	c2v_gc_register_thread()
	rc := 0
	reserved := 0
	p_file := &UnixFile(voidptr(id))
	sqlite3_mutex_enter(p_file.pInode.pLockMutex)
	if int(p_file.pInode.eFileLock) > 1 {
		reserved = 1
	}
	if !reserved && !p_file.pInode.bProcessLock {
		lock_ := C.flock{}
		lock_.l_whence = i16(0)
		lock_.l_start = i64((sqlite3PendingByte + 1))
		lock_.l_len = i64(1)
		lock_.l_type = i16(3)
		if C.C2V_VCALL_696e74282a2928696e742c696e742c2e2e2e29(voidptr((C2vFn_666e2028696e742c20696e742c202e2e2e2920696e74(voidptr(aSyscall[7].pCurrent)))), p_file.h, 7, voidptr(&lock_)) {
			rc = (10 | (14 << 8))
			store_last_errno(p_file, (unsafe { *C.__error() }))
		} else if int(lock_.l_type) != 2 {
			reserved = 1
		}
	}
	sqlite3_mutex_leave(p_file.pInode.pLockMutex)
	unsafe { *p_res_out = reserved }
	return rc
}

@[c:'unixFileLock']
fn unix_file_lock(p_file &UnixFile, p_lock &C.flock) int {
	rc := 0
	p_inode := p_file.pInode
	if (int(p_file.ctrlFlags) & (1 | 2)) == 1 {
		if int(p_inode.bProcessLock) == 0 {
			lock_ := C.flock{}
			lock_.l_whence = i16(0)
			lock_.l_start = i64((sqlite3PendingByte + 2))
			lock_.l_len = i64(510)
			lock_.l_type = i16(3)
			rc = C.C2V_VCALL_696e74282a2928696e742c696e742c2e2e2e29(voidptr((C2vFn_666e2028696e742c20696e742c202e2e2e2920696e74(voidptr(aSyscall[7].pCurrent)))), p_file.h, 8, voidptr(&lock_))
			if rc < 0 {
				return rc
			}
			p_inode.bProcessLock = u8(1)
			p_inode.nLock++
		} else {
			rc = 0
		}
	} else {
		rc = C.C2V_VCALL_696e74282a2928696e742c696e742c2e2e2e29(voidptr((C2vFn_666e2028696e742c20696e742c202e2e2e2920696e74(voidptr(aSyscall[7].pCurrent)))), p_file.h, 8, voidptr(p_lock))
	}
	return rc
}

@[c:'unixLock']
fn unix_lock(id &Sqlite3_file, e_file_lock int) int {
	c2v_gc_register_thread()
	rc := 0
	p_file := &UnixFile(voidptr(id))
	p_inode := &UnixInodeInfo(0)
	lock_ := C.flock{}
	t_errno := 0
	if int(p_file.eFileLock) >= e_file_lock {
		return 0
	}
	p_inode = p_file.pInode
	sqlite3_mutex_enter(p_inode.pLockMutex)
	if (int(p_file.eFileLock) != int(p_inode.eFileLock) && (int(p_inode.eFileLock) >= 3 || e_file_lock > 1)) {
		rc = 5
		unsafe { goto end_lock
		 }
	}
	if e_file_lock == 1 && (int(p_inode.eFileLock) == 1 || int(p_inode.eFileLock) == 2) {
		p_file.eFileLock = u8(1)
		p_inode.nShared++
		p_inode.nLock++
		unsafe { goto end_lock
		 }
	}
	lock_.l_len = 1
	lock_.l_whence = i16(0)
	if e_file_lock == 1 || (e_file_lock == 4 && int(p_file.eFileLock) == 2) {
		lock_.l_type = i16((if e_file_lock == 1 { 1 } else { 3 }))
		lock_.l_start = i64(sqlite3PendingByte)
		if unix_file_lock(p_file, &lock_) {
			t_errno = unsafe { *C.__error() }
			rc = sqlite_error_from_posix_error(t_errno, (10 | (15 << 8)))
			if rc != 5 {
				store_last_errno(p_file, t_errno)
			}
			unsafe { goto end_lock
			 }
		} else if e_file_lock == 4 {
			p_file.eFileLock = u8(3)
			p_inode.eFileLock = u8(3)
		}
	}
	if e_file_lock == 1 {
		lock_.l_start = i64((sqlite3PendingByte + 2))
		lock_.l_len = i64(510)
		if unix_file_lock(p_file, &lock_) {
			t_errno = unsafe { *C.__error() }
			rc = sqlite_error_from_posix_error(t_errno, (10 | (15 << 8)))
		}
		lock_.l_start = i64(sqlite3PendingByte)
		lock_.l_len = 1
		lock_.l_type = i16(2)
		if unix_file_lock(p_file, &lock_) && rc == 0 {
			t_errno = unsafe { *C.__error() }
			rc = (10 | (8 << 8))
		}
		if rc {
			if rc != 5 {
				store_last_errno(p_file, t_errno)
			}
			unsafe { goto end_lock
			 }
		} else {
			p_file.eFileLock = u8(1)
			p_inode.nLock++
			p_inode.nShared = 1
		}
	} else if e_file_lock == 4 && p_inode.nShared > 1 {
		rc = 5
	} else if unix_is_sharing_shm_node(p_file) {
		rc = 5
	} else {
		lock_.l_type = i16(3)
		if e_file_lock == 2 {
			lock_.l_start = i64((sqlite3PendingByte + 1))
			lock_.l_len = 1
		} else {
			lock_.l_start = i64((sqlite3PendingByte + 2))
			lock_.l_len = i64(510)
		}
		if unix_file_lock(p_file, &lock_) {
			t_errno = unsafe { *C.__error() }
			rc = sqlite_error_from_posix_error(t_errno, (10 | (15 << 8)))
			if rc != 5 {
				store_last_errno(p_file, t_errno)
			}
		}
	}
	if rc == 0 {
		p_file.eFileLock = u8(e_file_lock)
		p_inode.eFileLock = u8(e_file_lock)
	}
	end_lock:
	sqlite3_mutex_leave(p_inode.pLockMutex)
	return rc
}

@[c:'setPendingFd']
fn set_pending_fd(p_file &UnixFile) {
	p_inode := p_file.pInode
	p := p_file.pPreallocatedUnused
	p.pNext = p_inode.pUnused
	p_inode.pUnused = p
	p_file.h = -1
	p_file.pPreallocatedUnused = 0
}

@[c:'posixUnlock']
fn posix_unlock(id &Sqlite3_file, e_file_lock int, handle_nfs_unlock int) int {
	p_file := &UnixFile(voidptr(id))
	p_inode := &UnixInodeInfo(0)
	lock_ := C.flock{}
	rc := 0
	if int(p_file.eFileLock) <= e_file_lock {
		return 0
	}
	p_inode = p_file.pInode
	sqlite3_mutex_enter(p_inode.pLockMutex)
	if int(p_file.eFileLock) > 1 {
		if e_file_lock == 1 {
			if handle_nfs_unlock {
				t_errno := 0
				div_size := i64(510 - 1)
				lock_.l_type = i16(2)
				lock_.l_whence = i16(0)
				lock_.l_start = i64((sqlite3PendingByte + 2))
				lock_.l_len = div_size
				if unix_file_lock(p_file, &lock_) == (-1) {
					t_errno = unsafe { *C.__error() }
					rc = (10 | (8 << 8))
					store_last_errno(p_file, t_errno)
					unsafe { goto end_unlock
					 }
				}
				lock_.l_type = i16(1)
				lock_.l_whence = i16(0)
				lock_.l_start = i64((sqlite3PendingByte + 2))
				lock_.l_len = div_size
				if unix_file_lock(p_file, &lock_) == (-1) {
					t_errno = unsafe { *C.__error() }
					rc = sqlite_error_from_posix_error(t_errno, (10 | (9 << 8)))
					if ((rc != 0) && (rc != 5)) {
						store_last_errno(p_file, t_errno)
					}
					unsafe { goto end_unlock
					 }
				}
				lock_.l_type = i16(2)
				lock_.l_whence = i16(0)
				lock_.l_start = i64((sqlite3PendingByte + 2)) + div_size
				lock_.l_len = i64(510) - div_size
				if unix_file_lock(p_file, &lock_) == (-1) {
					t_errno = unsafe { *C.__error() }
					rc = (10 | (8 << 8))
					store_last_errno(p_file, t_errno)
					unsafe { goto end_unlock
					 }
				}
			} else {
				lock_.l_type = i16(1)
				lock_.l_whence = i16(0)
				lock_.l_start = i64((sqlite3PendingByte + 2))
				lock_.l_len = i64(510)
				if unix_file_lock(p_file, &lock_) {
					rc = (10 | (9 << 8))
					store_last_errno(p_file, (unsafe { *C.__error() }))
					unsafe { goto end_unlock
					 }
				}
			}
		}
		lock_.l_type = i16(2)
		lock_.l_whence = i16(0)
		lock_.l_start = i64(sqlite3PendingByte)
		lock_.l_len = 2
		if unix_file_lock(p_file, &lock_) == 0 {
			p_inode.eFileLock = u8(1)
		} else {
			rc = (10 | (8 << 8))
			store_last_errno(p_file, (unsafe { *C.__error() }))
			unsafe { goto end_unlock
			 }
		}
	}
	if e_file_lock == 0 {
		p_inode.nShared--
		if p_inode.nShared == 0 {
			lock_.l_type = i16(2)
			lock_.l_whence = i16(0)
			lock_.l_len = 0
			lock_.l_start = lock_.l_len
			if unix_file_lock(p_file, &lock_) == 0 {
				p_inode.eFileLock = u8(0)
			} else {
				rc = (10 | (8 << 8))
				store_last_errno(p_file, (unsafe { *C.__error() }))
				p_inode.eFileLock = u8(0)
				p_file.eFileLock = u8(0)
			}
		}
		p_inode.nLock--
		if p_inode.nLock == 0 {
			close_pending_fds(p_file)
		}
	}
	end_unlock:
	sqlite3_mutex_leave(p_inode.pLockMutex)
	if rc == 0 {
		p_file.eFileLock = u8(e_file_lock)
	}
	return rc
}

@[c:'unixUnlock']
fn unix_unlock(id &Sqlite3_file, e_file_lock int) int {
	c2v_gc_register_thread()
	return posix_unlock(id, e_file_lock, 0)
}

@[c:'closeUnixFile']
fn close_unix_file(id &Sqlite3_file) int {
	p_file := &UnixFile(voidptr(id))
	unix_unmapfile(p_file)
	if p_file.h >= 0 {
		robust_close(p_file, p_file.h, 2312)
		p_file.h = -1
	}
	sqlite3_free(voidptr(p_file.pPreallocatedUnused))
	C.memset(voidptr(p_file), 0, sizeof(UnixFile))
	return 0
}

@[c:'unixClose']
fn unix_close(id &Sqlite3_file) int {
	c2v_gc_register_thread()
	rc := 0
	p_file := &UnixFile(voidptr(id))
	p_inode := p_file.pInode
	verify_db_file(p_file)
	unix_unlock(id, 0)
	unix_enter_mutex()
	sqlite3_mutex_enter(p_inode.pLockMutex)
	if p_inode.nLock {
		set_pending_fd(p_file)
	}
	sqlite3_mutex_leave(p_inode.pLockMutex)
	release_inode_info(p_file)
	rc = close_unix_file(id)
	unix_leave_mutex()
	return rc
}

@[c:'nolockCheckReservedLock']
fn nolock_check_reserved_lock(not_used &Sqlite3_file, p_res_out &int) int {
	c2v_gc_register_thread()

	unsafe { *p_res_out = 0 }
	return 0
}

@[c:'nolockLock']
fn nolock_lock(not_used &Sqlite3_file, not_used2 int) int {
	c2v_gc_register_thread()

	return 0
}

@[c:'nolockUnlock']
fn nolock_unlock(not_used &Sqlite3_file, not_used2 int) int {
	c2v_gc_register_thread()

	return 0
}

@[c:'nolockClose']
fn nolock_close(id &Sqlite3_file) int {
	c2v_gc_register_thread()
	return close_unix_file(id)
}

@[c:'dotlockCheckReservedLock']
fn dotlock_check_reserved_lock(id &Sqlite3_file, p_res_out &int) int {
	c2v_gc_register_thread()
	p_file := &UnixFile(voidptr(id))
	if int(p_file.eFileLock) >= 1 {
		unsafe { *p_res_out = 0 }
	} else {
		unsafe { *p_res_out = c2v_fnptr_666e20282669382c20696e742920696e74(voidptr(aSyscall[2].pCurrent))(&i8(p_file.lockingContext), 0) == 0 }
	}
	return 0
}

@[c:'dotlockLock']
fn dotlock_lock(id &Sqlite3_file, e_file_lock int) int {
	c2v_gc_register_thread()
	p_file := &UnixFile(voidptr(id))
	z_lock_file := &i8(p_file.lockingContext)
	rc := 0
	if int(p_file.eFileLock) > 0 {
		p_file.eFileLock = u8(e_file_lock)
		C.utimes(z_lock_file, (voidptr(0)))
		return 0
	}
	rc = c2v_fnptr_666e20282669382c207533322920696e74(voidptr(aSyscall[18].pCurrent))(z_lock_file, u32(511))
	if rc < 0 {
		t_errno := (unsafe { *C.__error() })
		if 17 == t_errno {
			rc = 5
		} else {
			rc = sqlite_error_from_posix_error(t_errno, (10 | (15 << 8)))
			if rc != 5 {
				store_last_errno(p_file, t_errno)
			}
		}
		return rc
	}
	p_file.eFileLock = u8(e_file_lock)
	return rc
}

@[c:'dotlockUnlock']
fn dotlock_unlock(id &Sqlite3_file, e_file_lock int) int {
	c2v_gc_register_thread()
	p_file := &UnixFile(voidptr(id))
	z_lock_file := &i8(p_file.lockingContext)
	rc := 0
	if int(p_file.eFileLock) == e_file_lock {
		return 0
	}
	if e_file_lock == 1 {
		p_file.eFileLock = u8(1)
		return 0
	}
	rc = c2v_fnptr_666e20282669382920696e74(voidptr(aSyscall[19].pCurrent))(z_lock_file)
	if rc < 0 {
		t_errno := (unsafe { *C.__error() })
		if t_errno == 2 {
			rc = 0
		} else {
			rc = (10 | (8 << 8))
			store_last_errno(p_file, t_errno)
		}
		return rc
	}
	p_file.eFileLock = u8(0)
	return 0
}

@[c:'dotlockClose']
fn dotlock_close(id &Sqlite3_file) int {
	c2v_gc_register_thread()
	p_file := &UnixFile(voidptr(id))
	dotlock_unlock(id, 0)
	sqlite3_free(voidptr(p_file.lockingContext))
	return close_unix_file(id)
}

fn robust_flock(fd int, op int) int {
	rc := 0
	for {
		rc = c2v_fn_flock(fd, op)
		if !(rc < 0 && (unsafe { *C.__error() }) == 4) {
			break
		}
	}
	return rc
}

@[c:'flockCheckReservedLock']
fn flock_check_reserved_lock(id &Sqlite3_file, p_res_out &int) int {
	c2v_gc_register_thread()

	unsafe { *p_res_out = 0 }
	return 0
}

@[c:'flockLock']
fn flock_lock(id &Sqlite3_file, e_file_lock int) int {
	c2v_gc_register_thread()
	rc := 0
	p_file := &UnixFile(voidptr(id))
	if int(p_file.eFileLock) > 0 {
		p_file.eFileLock = u8(e_file_lock)
		return 0
	}
	if robust_flock(p_file.h, 2 | 4) {
		t_errno := (unsafe { *C.__error() })
		rc = sqlite_error_from_posix_error(t_errno, (10 | (15 << 8)))
		if ((rc != 0) && (rc != 5)) {
			store_last_errno(p_file, t_errno)
		}
	} else {
		p_file.eFileLock = u8(e_file_lock)
	}
	return rc
}

@[c:'flockUnlock']
fn flock_unlock(id &Sqlite3_file, e_file_lock int) int {
	c2v_gc_register_thread()
	p_file := &UnixFile(voidptr(id))
	if int(p_file.eFileLock) == e_file_lock {
		return 0
	}
	if e_file_lock == 1 {
		p_file.eFileLock = u8(e_file_lock)
		return 0
	}
	if robust_flock(p_file.h, 8) {
		return 10 | (8 << 8)
	} else {
		p_file.eFileLock = u8(0)
		return 0
	}
}

@[c:'flockClose']
fn flock_close(id &Sqlite3_file) int {
	c2v_gc_register_thread()
	flock_unlock(id, 0)
	return close_unix_file(id)
}

struct AfpLockingContext {
	reserved int
	dbPath   &i8
}

struct ByteRangeLockPB2 {
	offset        u64
	length        u64
	retRangeStart u64
	unLockFlag    u8
	startEndFlag  u8
	fd            int
}

@[c:'afpSetLock']
fn afp_set_lock(path &i8, p_file &UnixFile, offset u64, length u64, set_lock_flag int) int {
	pb := ByteRangeLockPB2{}
	err := 0
	pb.unLockFlag = u8(if set_lock_flag { 0 } else { 1 })
	pb.startEndFlag = u8(0)
	pb.offset = offset
	pb.length = length
	pb.fd = p_file.h
	err = C.fsctl(path, (u64((u32(u32(2147483648)) | u32(1073741824))) | ((sizeof(ByteRangeLockPB2) & u64(8191)) << 16) | u64((`z` << 8)) | u64(23)), voidptr(&pb), u32(0))
	if err == -1 {
		rc := 0
		t_errno := (unsafe { *C.__error() })
		rc = sqlite_error_from_posix_error(t_errno, if set_lock_flag {
			(10 | (15 << 8))
		} else {
			(10 | (8 << 8))
		})
		if ((rc != 0) && (rc != 5)) {
			store_last_errno(p_file, t_errno)
		}
		return rc
	} else {
		return 0
	}
}

@[c:'afpCheckReservedLock']
fn afp_check_reserved_lock(id &Sqlite3_file, p_res_out &int) int {
	c2v_gc_register_thread()
	rc := 0
	reserved := 0
	p_file := &UnixFile(voidptr(id))
	context := &AfpLockingContext(0)
	context = &AfpLockingContext(p_file.lockingContext)
	if context.reserved {
		unsafe { *p_res_out = 1 }
		return 0
	}
	sqlite3_mutex_enter(p_file.pInode.pLockMutex)
	if int(p_file.pInode.eFileLock) > 1 {
		reserved = 1
	}
	if !reserved {
		lrc := afp_set_lock(context.dbPath, p_file, u64((sqlite3PendingByte + 1)), u64(1), 1)
		if 0 == lrc {
			lrc = afp_set_lock(context.dbPath, p_file, u64((sqlite3PendingByte + 1)), u64(1), 0)
		} else {
			reserved = 1
		}
		if ((lrc != 0) && (lrc != 5)) {
			rc = lrc
		}
	}
	sqlite3_mutex_leave(p_file.pInode.pLockMutex)
	unsafe { *p_res_out = reserved }
	return rc
}

@[c:'afpLock']
fn afp_lock(id &Sqlite3_file, e_file_lock int) int {
	c2v_gc_register_thread()
	rc := 0
	p_file := &UnixFile(voidptr(id))
	p_inode := p_file.pInode
	context := &AfpLockingContext(p_file.lockingContext)
	if int(p_file.eFileLock) >= e_file_lock {
		return 0
	}
	p_inode = p_file.pInode
	sqlite3_mutex_enter(p_inode.pLockMutex)
	if (int(p_file.eFileLock) != int(p_inode.eFileLock) && (int(p_inode.eFileLock) >= 3 || e_file_lock > 1)) {
		rc = 5
		unsafe { goto afp_end_lock
		 }
	}
	if e_file_lock == 1 && (int(p_inode.eFileLock) == 1 || int(p_inode.eFileLock) == 2) {
		p_file.eFileLock = u8(1)
		p_inode.nShared++
		p_inode.nLock++
		unsafe { goto afp_end_lock
		 }
	}
	if e_file_lock == 1 || (e_file_lock == 4 && int(p_file.eFileLock) < 3) {
		failed := 0
		failed = afp_set_lock(context.dbPath, p_file, u64(sqlite3PendingByte), u64(1), 1)
		if failed {
			rc = failed
			unsafe { goto afp_end_lock
			 }
		}
	}
	if e_file_lock == 1 {
		lrc1 := 0
		lrc2 := 0
		lrc1_errno := 0

		lk := i64(0)
		mask := i64(0)

		mask = i64(if (sizeof(i64) == u64(8)) {
			(I64(u32(4294967295)) | ((I64(2147483647)) << 32))
		} else {
			I64(2147483647)
		})
		lk = C.random()
		p_inode.sharedByte = u64((lk & mask) % i64((510 - 1)))
		lrc1 = afp_set_lock(context.dbPath, p_file, u64((sqlite3PendingByte + 2)) + p_inode.sharedByte, u64(1), 1)
		if ((lrc1 != 0) && (lrc1 != 5)) {
			lrc1_errno = p_file.lastErrno
		}
		lrc2 = afp_set_lock(context.dbPath, p_file, u64(sqlite3PendingByte), u64(1), 0)
		if ((lrc1 != 0) && (lrc1 != 5)) {
			store_last_errno(p_file, lrc1_errno)
			rc = lrc1
			unsafe { goto afp_end_lock
			 }
		} else if ((lrc2 != 0) && (lrc2 != 5)) {
			rc = lrc2
			unsafe { goto afp_end_lock
			 }
		} else if lrc1 != 0 {
			rc = lrc1
		} else {
			p_file.eFileLock = u8(1)
			p_inode.nLock++
			p_inode.nShared = 1
		}
	} else if e_file_lock == 4 && p_inode.nShared > 1 {
		rc = 5
	} else {
		failed := 0
		if e_file_lock >= 2 && int(p_file.eFileLock) < 2 {
			failed = afp_set_lock(context.dbPath, p_file, u64((sqlite3PendingByte + 1)), u64(1), 1)
			if !failed {
				context.reserved = 1
			}
		}
		if !failed && e_file_lock == 4 {
			failed = afp_set_lock(context.dbPath, p_file, u64((sqlite3PendingByte + 2)) + p_inode.sharedByte, u64(1), 0)
			if !failed {
				failed2 := 0
				failed = afp_set_lock(context.dbPath, p_file, u64((sqlite3PendingByte + 2)), u64(510), 1)
				if failed && c2v_assign[int](unsafe { &failed2 }, int(afp_set_lock(context.dbPath, p_file, u64((sqlite3PendingByte + 2)) + p_inode.sharedByte, u64(1), 1))) {
					rc = if ((failed & 255) == 10) { failed2 } else { (10 | (15 << 8)) }
					unsafe { goto afp_end_lock
					 }
				}
			} else {
				rc = failed
			}
		}
		if failed {
			rc = failed
		}
	}
	if rc == 0 {
		p_file.eFileLock = u8(e_file_lock)
		p_inode.eFileLock = u8(e_file_lock)
	} else if e_file_lock == 4 {
		p_file.eFileLock = u8(3)
		p_inode.eFileLock = u8(3)
	}
	afp_end_lock:
	sqlite3_mutex_leave(p_inode.pLockMutex)
	return rc
}

@[c:'afpUnlock']
fn afp_unlock(id &Sqlite3_file, e_file_lock int) int {
	c2v_gc_register_thread()
	rc := 0
	p_file := &UnixFile(voidptr(id))
	p_inode := &UnixInodeInfo(0)
	context := &AfpLockingContext(p_file.lockingContext)
	skip_shared := 0
	if int(p_file.eFileLock) <= e_file_lock {
		return 0
	}
	p_inode = p_file.pInode
	sqlite3_mutex_enter(p_inode.pLockMutex)
	if int(p_file.eFileLock) > 1 {
		if int(p_file.eFileLock) == 4 {
			rc = afp_set_lock(context.dbPath, p_file, u64((sqlite3PendingByte + 2)), u64(510), 0)
			if rc == 0 && (e_file_lock == 1 || p_inode.nShared > 1) {
				shared_lock_byte := int(u64((sqlite3PendingByte + 2)) + p_inode.sharedByte)
				rc = afp_set_lock(context.dbPath, p_file, u64(shared_lock_byte), u64(1), 1)
			} else {
				skip_shared = 1
			}
		}
		if rc == 0 && int(p_file.eFileLock) >= 3 {
			rc = afp_set_lock(context.dbPath, p_file, u64(sqlite3PendingByte), u64(1), 0)
		}
		if rc == 0 && int(p_file.eFileLock) >= 2 && context.reserved {
			rc = afp_set_lock(context.dbPath, p_file, u64((sqlite3PendingByte + 1)), u64(1), 0)
			if !rc {
				context.reserved = 0
			}
		}
		if rc == 0 && (e_file_lock == 1 || p_inode.nShared > 1) {
			p_inode.eFileLock = u8(1)
		}
	}
	if rc == 0 && e_file_lock == 0 {
		shared_lock_byte := u64((sqlite3PendingByte + 2)) + p_inode.sharedByte
		p_inode.nShared--
		if p_inode.nShared == 0 {
			if !skip_shared {
				rc = afp_set_lock(context.dbPath, p_file, shared_lock_byte, u64(1), 0)
			}
			if !rc {
				p_inode.eFileLock = u8(0)
				p_file.eFileLock = u8(0)
			}
		}
		if rc == 0 {
			p_inode.nLock--
			if p_inode.nLock == 0 {
				close_pending_fds(p_file)
			}
		}
	}
	sqlite3_mutex_leave(p_inode.pLockMutex)
	if rc == 0 {
		p_file.eFileLock = u8(e_file_lock)
	}
	return rc
}

@[c:'afpClose']
fn afp_close(id &Sqlite3_file) int {
	c2v_gc_register_thread()
	rc := 0
	p_file := &UnixFile(voidptr(id))
	afp_unlock(id, 0)
	unix_enter_mutex()
	if p_file.pInode {
		p_inode := p_file.pInode
		sqlite3_mutex_enter(p_inode.pLockMutex)
		if p_inode.nLock {
			set_pending_fd(p_file)
		}
		sqlite3_mutex_leave(p_inode.pLockMutex)
	}
	release_inode_info(p_file)
	sqlite3_free(voidptr(p_file.lockingContext))
	rc = close_unix_file(id)
	unix_leave_mutex()
	return rc
}

@[c:'nfsUnlock']
fn nfs_unlock(id &Sqlite3_file, e_file_lock int) int {
	c2v_gc_register_thread()
	return posix_unlock(id, e_file_lock, 1)
}

@[c:'seekAndRead']
fn seek_and_read(id &UnixFile, offset Sqlite3_int64, p_buf voidptr, cnt int) int {
	got := 0
	prior := 0
	for {
		got = int(c2v_fnptr_666e2028696e742c20766f69647074722c207573697a652c2069363429206973697a65(voidptr(aSyscall[9].pCurrent))(id.h, voidptr(p_buf), usize(cnt), offset))
		if got == cnt {
			break
		}
		if got < 0 {
			if (unsafe { *C.__error() }) == 4 {
				got = 1
				unsafe { goto c2v_do_next_19
				 }
			}
			prior = 0
			store_last_errno(&UnixFile(id), (unsafe { *C.__error() }))
			break
		} else if got > 0 {
			cnt -= got
			offset += Sqlite3_int64(got)
			prior += got
			p_buf = voidptr((unsafe { &i8(p_buf) + got }))
		}
		c2v_do_next_19:
		if !(got > 0) {
			break
		}
	}
	return got + prior
}

@[c:'unixRead']
fn unix_read(id &Sqlite3_file, p_buf voidptr, amt int, offset Sqlite3_int64) int {
	c2v_gc_register_thread()
	p_file := &UnixFile(voidptr(id))
	got := 0
	if offset < p_file.mmapSize {
		if offset + Sqlite3_int64(amt) <= p_file.mmapSize {
			C.memcpy(voidptr(p_buf), voidptr(unsafe { (&U8(p_file.pMapRegion)) + offset }), u64(amt))
			return 0
		} else {
			n_copy := int(p_file.mmapSize - offset)
			C.memcpy(voidptr(p_buf), voidptr(unsafe { (&U8(p_file.pMapRegion)) + offset }), u64(n_copy))
			p_buf = unsafe { (&U8(p_buf)) + n_copy }
			amt -= n_copy
			offset += Sqlite3_int64(n_copy)
		}
	}
	got = seek_and_read(p_file, offset, voidptr(p_buf), amt)
	if got == amt {
		return 0
	} else if got < 0 {
		match p_file.lastErrno {
			34, 5, 6, 83 {
				return 10 | (33 << 8)
			}
			else {}
		}

		return 10 | (1 << 8)
	} else {
		store_last_errno(p_file, 0)
		C.memset(voidptr(unsafe { (&i8(p_buf)) + got }), 0, u64(amt - got))
		return 10 | (2 << 8)
	}
}

@[c:'seekAndWriteFd']
fn seek_and_write_fd(fd int, i_off I64, p_buf voidptr, n_buf int, pi_errno &int) int {
	rc := 0
	n_buf &= 131071
	for {
		rc = int(c2v_fnptr_666e2028696e742c20766f69647074722c207573697a652c2069363429206973697a65(voidptr(aSyscall[12].pCurrent))(fd, voidptr(p_buf), usize(n_buf), i_off))
		if !(rc < 0 && (unsafe { *C.__error() }) == 4) {
			break
		}
	}
	if rc < 0 {
		unsafe { *pi_errno = *C.__error() }
	}
	return rc
}

@[c:'seekAndWrite']
fn seek_and_write(id &UnixFile, offset I64, p_buf voidptr, cnt int) int {
	return seek_and_write_fd(id.h, offset, voidptr(p_buf), cnt, &id.lastErrno)
}

@[c:'unixWrite']
fn unix_write(id &Sqlite3_file, p_buf voidptr, amt int, offset Sqlite3_int64) int {
	c2v_gc_register_thread()
	p_file := &UnixFile(voidptr(id))
	wrote := 0
	for {
		wrote = seek_and_write(p_file, offset, voidptr(p_buf), amt)
		if !(wrote < amt && wrote > 0) {
			break
		}
		amt -= wrote
		offset += Sqlite3_int64(wrote)
		p_buf = unsafe { (&i8(p_buf)) + wrote }
	}
	if amt > wrote {
		if wrote < 0 && p_file.lastErrno != 28 {
			return 10 | (3 << 8)
		} else {
			store_last_errno(p_file, 0)
			return 13
		}
	}
	return 0
}

fn full_fsync(fd int, full_sync int, data_only int) int {
	rc := 0

	if full_sync {
		rc = C.C2V_VCALL_696e74282a2928696e742c696e742c2e2e2e29(voidptr((C2vFn_666e2028696e742c20696e742c202e2e2e2920696e74(voidptr(aSyscall[7].pCurrent)))), fd, 51, 0)
	} else {
		rc = 1
	}
	if rc {
		rc = C.fsync(fd)
	}
	if 0 && rc != -1 {
		rc = 0
	}
	return rc
}

@[c:'openDirectory']
fn open_directory(z_filename &i8, p_fd &int) int {
	c2v_gc_register_thread()
	ii := 0
	fd := -1
	z_dirname := [513]i8{}
	sqlite3_snprintf(512, unsafe { &i8(&z_dirname[0]) }, c'%s', voidptr(z_filename))
	for ii = int(C.strlen(unsafe { &i8(&z_dirname[0]) })); ii > 0 && int(z_dirname[ii]) != i8(`/`); ii-- {
	}
	if ii > 0 {
		z_dirname[ii] = i8(`\0`)
	} else {
		if int(z_dirname[0]) != i8(`/`) {
			z_dirname[0] = i8(`.`)
		}
		z_dirname[1] = i8(0)
	}
	fd = robust_open(unsafe { &i8(&z_dirname[0]) }, 0 | 0, u32(0))
	if fd >= 0 {
	}
	unsafe { *p_fd = fd }
	if fd >= 0 {
		return 0
	}
	return unix_log_error_at_line(sqlite3_cantopen_error(3893), c'openDirectory', unsafe { &i8(&z_dirname[0]) }, 3893)
}

@[c:'unixSync']
fn unix_sync(id &Sqlite3_file, flags int) int {
	c2v_gc_register_thread()
	rc := 0
	p_file := &UnixFile(voidptr(id))
	is_data_only := (flags & 16)
	is_fullsync := int((flags & 15) == 3)
	rc = full_fsync(p_file.h, is_fullsync, is_data_only)
	if rc {
		store_last_errno(p_file, (unsafe { *C.__error() }))
		return unix_log_error_at_line((10 | (4 << 8)), c'full_fsync', p_file.zPath, 3934)
	}
	if int(p_file.ctrlFlags) & 8 {
		dirfd := 0
		rc = c2v_fnptr_666e20282669382c2026696e742920696e74(voidptr(aSyscall[17].pCurrent))(p_file.zPath, &dirfd)
		if rc == 0 {
			full_fsync(dirfd, 0, 0)
			robust_close(p_file, dirfd, 3948)
		} else {
			rc = 0
		}
		p_file.ctrlFlags &= ~8
	}
	return rc
}

@[c:'unixTruncate']
fn unix_truncate(id &Sqlite3_file, n_byte I64) int {
	c2v_gc_register_thread()
	p_file := &UnixFile(voidptr(id))
	rc := 0
	if p_file.szChunk > 0 {
		n_byte = ((n_byte + I64(p_file.szChunk) - I64(1)) / I64(p_file.szChunk)) * I64(p_file.szChunk)
	}
	rc = robust_ftruncate(p_file.h, n_byte)
	if rc {
		store_last_errno(p_file, (unsafe { *C.__error() }))
		return unix_log_error_at_line((10 | (6 << 8)), c'ftruncate', p_file.zPath, 3979)
	} else {
		if n_byte < p_file.mmapSize {
			p_file.mmapSize = n_byte
		}
		return 0
	}
}

@[c:'unixFileSize']
fn unix_file_size(id &Sqlite3_file, p_size &I64) int {
	c2v_gc_register_thread()
	rc := 0
	buf := C.stat{}
	rc = c2v_fnptr_666e2028696e742c2026432e737461742920696e74(voidptr(aSyscall[5].pCurrent))((&UnixFile(voidptr(id))).h, &buf)
	if rc != 0 {
		store_last_errno(&UnixFile(voidptr(id)), (unsafe { *C.__error() }))
		return 10 | (7 << 8)
	}
	unsafe { *p_size = buf.st_size }
	if (unsafe { *p_size }) == I64(1) {
		unsafe { *p_size = I64(0) }
	}
	return 0
}

@[c:'fcntlSizeHint']
fn fcntl_size_hint(p_file &UnixFile, n_byte I64) int {
	if p_file.szChunk > 0 {
		n_size := I64(0)
		buf := C.stat{}
		if c2v_fnptr_666e2028696e742c2026432e737461742920696e74(voidptr(aSyscall[5].pCurrent))(p_file.h, &buf) {
			return 10 | (7 << 8)
		}
		n_size = ((n_byte + I64(p_file.szChunk) - I64(1)) / I64(p_file.szChunk)) * I64(p_file.szChunk)
		if n_size > I64(buf.st_size) {
			n_blk := buf.st_blksize
			n_write := 0
			i_write := I64(0)
			i_write = (buf.st_size / i64(n_blk)) * i64(n_blk) + i64(n_blk) - i64(1)
			for ; i_write < n_size + I64(n_blk) - I64(1); i_write += I64(n_blk) {
				if i_write >= n_size {
					i_write = n_size - I64(1)
				}
				n_write = seek_and_write(p_file, i_write, voidptr(c''), 1)
				if n_write != 1 {
					return 10 | (3 << 8)
				}
			}
		}
	}
	if p_file.mmapSizeMax > Sqlite3_int64(0) && n_byte > p_file.mmapSize {
		rc := 0
		if p_file.szChunk <= 0 {
			if robust_ftruncate(p_file.h, n_byte) {
				store_last_errno(p_file, (unsafe { *C.__error() }))
				return unix_log_error_at_line((10 | (6 << 8)), c'ftruncate', p_file.zPath, 4100)
			}
		}
		rc = unix_mapfile(p_file, n_byte)
		return rc
	}
	return 0
}

@[c:'unixModeBit']
fn unix_mode_bit(p_file &UnixFile, mask u8, p_arg &int) {
	if (unsafe { *p_arg }) < 0 {
		unsafe { *p_arg = (int(p_file.ctrlFlags) & int(mask)) != 0 }
	} else if (unsafe { *p_arg }) == 0 {
		p_file.ctrlFlags &= ~int(mask)
	} else {
		p_file.ctrlFlags |= int(mask)
	}
}

@[c:'unixFileControl']
fn unix_file_control(id &Sqlite3_file, op int, p_arg voidptr) int {
	c2v_gc_register_thread()
	p_file := &UnixFile(voidptr(id))
	match op {
		43 {
			c2v_fnptr_666e2028696e742920696e74(voidptr(aSyscall[1].pCurrent))(p_file.h)
			p_file.h = -1
			return 0
		}
		1 {
			mut __c2v_lhs_tmp_60 := unsafe { &int(p_arg) }
			unsafe { *__c2v_lhs_tmp_60 = int(p_file.eFileLock) }
			return 0
		}
		4 {
			mut __c2v_lhs_tmp_61 := unsafe { &int(p_arg) }
			unsafe { *__c2v_lhs_tmp_61 = p_file.lastErrno }
			return 0
		}
		6 {
			p_file.szChunk = unsafe { *&int(p_arg) }
			return 0
		}
		5 {
			rc := 0
			rc = fcntl_size_hint(p_file, (unsafe { *&I64(p_arg) }))
			return rc
		}
		10 {
			unix_mode_bit(p_file, u8(4), &int(p_arg))
			return 0
		}
		13 {
			unix_mode_bit(p_file, u8(16), &int(p_arg))
			return 0
		}
		12 {
			mut __c2v_lhs_tmp_62 := unsafe { &&u8(p_arg) }
			unsafe { *__c2v_lhs_tmp_62 = sqlite3_mprintf(c'%s', voidptr(p_file.pVfs.zName)) }
			return 0
		}
		16 {
			ztf_ile := &i8(sqlite3_malloc64(Sqlite3_uint64(p_file.pVfs.mxPathname)))
			if ztf_ile {
				unix_get_tempname(p_file.pVfs.mxPathname, ztf_ile)
				mut __c2v_lhs_tmp_63 := unsafe { &&u8(p_arg) }
				unsafe { *__c2v_lhs_tmp_63 = ztf_ile }
			}
			return 0
		}
		20 {
			mut __c2v_lhs_tmp_64 := unsafe { &int(p_arg) }
			unsafe { *__c2v_lhs_tmp_64 = file_has_moved(p_file) }
			return 0
		}
		18 {
			new_limit := (unsafe { *&I64(p_arg) })
			rc := 0
			if new_limit > sqlite3Config.mxMmap {
				new_limit = sqlite3Config.mxMmap
			}
			if new_limit > I64(0) && sizeof(usize) < u64(8) {
				new_limit = (new_limit & I64(2147483647))
			}
			mut __c2v_lhs_tmp_65 := unsafe { &I64(p_arg) }
			unsafe { *__c2v_lhs_tmp_65 = p_file.mmapSizeMax }
			if new_limit >= I64(0) && new_limit != p_file.mmapSizeMax && p_file.nFetchOut == 0 {
				p_file.mmapSizeMax = new_limit
				if p_file.mmapSize > Sqlite3_int64(0) {
					unix_unmapfile(p_file)
					rc = unix_mapfile(p_file, I64(-1))
				}
			}
			return rc
		}
		3, 2 {
			return proxy_file_control(id, op, voidptr(p_arg))
		}
		40 {
			return unix_fcntl_external_reader(&UnixFile(voidptr(id)), &int(p_arg))
		}
		else {}
	}

	return 12
}

@[c:'setDeviceCharacteristics']
fn set_device_characteristics(p_fd &UnixFile) {
	if p_fd.sectorSize == 0 {
		if int(p_fd.ctrlFlags) & 16 {
			p_fd.deviceCharacteristics |= 4096
		}
		p_fd.deviceCharacteristics |= 32768
		p_fd.sectorSize = 4096
	}
}

@[c:'unixSectorSize']
fn unix_sector_size(id &Sqlite3_file) int {
	c2v_gc_register_thread()
	p_fd := &UnixFile(voidptr(id))
	set_device_characteristics(p_fd)
	return p_fd.sectorSize
}

@[c:'unixDeviceCharacteristics']
fn unix_device_characteristics(id &Sqlite3_file) int {
	c2v_gc_register_thread()
	p_fd := &UnixFile(voidptr(id))
	set_device_characteristics(p_fd)
	return p_fd.deviceCharacteristics
}

@[c:'unixGetpagesize']
fn unix_getpagesize() int {
	c2v_gc_register_thread()
	return int(C.sysconf(29))
}

struct UnixShmNode {
	pInode     &UnixInodeInfo
	pShmMutex  &Sqlite3_mutex
	zFilename  &i8
	hShm       int
	szRegion   int
	nRegion    U16
	isReadonly U8
	isUnlocked U8
	apRegion   &&u8
	nRef       int
	pFirst     &UnixShm
	aLock      [8]int
}

struct UnixShm {
	pShmNode   &UnixShmNode
	pNext      &UnixShm
	hasMutex   U8
	id         U8
	sharedMask U16
	exclMask   U16
}

@[c:'unixFcntlExternalReader']
fn unix_fcntl_external_reader(p_file &UnixFile, pi_out &int) int {
	rc := 0
	unsafe { *pi_out = 0 }
	if p_file.pShm {
		p_shm_node := p_file.pShm.pShmNode
		f := C.flock{}
		C.memset(voidptr(&f), 0, sizeof(f))
		f.l_type = i16(3)
		f.l_whence = i16(0)
		f.l_start = i64(((22 + 8) * 4) + 3)
		f.l_len = i64(8 - 3)
		sqlite3_mutex_enter(p_shm_node.pShmMutex)
		if C.C2V_VCALL_696e74282a2928696e742c696e742c2e2e2e29(voidptr((C2vFn_666e2028696e742c20696e742c202e2e2e2920696e74(voidptr(aSyscall[7].pCurrent)))), p_shm_node.hShm, 7, voidptr(&f)) < 0 {
			rc = (10 | (15 << 8))
		} else {
			unsafe { *pi_out = (int(f.l_type) != 2) }
		}
		sqlite3_mutex_leave(p_shm_node.pShmMutex)
	}
	return rc
}

@[c:'unixIsSharingShmNode']
fn unix_is_sharing_shm_node(p_file &UnixFile) int {
	p_shm_node := &UnixShmNode(0)
	lock_ := C.flock{}
	if usize(p_file.pShm) == usize(0) {
		return 0
	}
	if int(p_file.ctrlFlags) & 1 {
		return 0
	}
	p_shm_node = p_file.pShm.pShmNode
	C.memset(voidptr(&lock_), 0, sizeof(lock_))
	lock_.l_whence = i16(0)
	lock_.l_start = i64((((22 + 8) * 4) + 8))
	lock_.l_len = i64(1)
	lock_.l_type = i16(3)
	C.C2V_VCALL_696e74282a2928696e742c696e742c2e2e2e29(voidptr((C2vFn_666e2028696e742c20696e742c202e2e2e2920696e74(voidptr(aSyscall[7].pCurrent)))), p_shm_node.hShm, 7, voidptr(&lock_))
	return int((int(lock_.l_type) != 2))
}

@[c:'unixShmSystemLock']
fn unix_shm_system_lock(p_file &UnixFile, lock_type int, ofst int, n int) int {
	p_shm_node := &UnixShmNode(0)
	f := C.flock{}
	rc := 0
	p_shm_node = p_file.pInode.pShmNode
	if ofst == (((22 + 8) * 4) + 8) {
	} else {
	}
	if p_shm_node.hShm >= 0 {
		res := 0
		f.l_type = i16(lock_type)
		f.l_whence = i16(0)
		f.l_start = i64(ofst)
		f.l_len = i64(n)
		res = C.C2V_VCALL_696e74282a2928696e742c696e742c2e2e2e29(voidptr((C2vFn_666e2028696e742c20696e742c202e2e2e2920696e74(voidptr(aSyscall[7].pCurrent)))), p_shm_node.hShm, 8, voidptr(&f))
		if res == -1 {
			rc = 5
		}
	}
	return rc
}

@[c:'unixShmRegionPerMap']
fn unix_shm_region_per_map() int {
	shmsz := 32 * 1024
	pgsz := c2v_fnptr_666e20282920696e74(voidptr(aSyscall[25].pCurrent))()
	if pgsz < shmsz {
		return 1
	}
	return pgsz / shmsz
}

@[c:'unixShmPurge']
fn unix_shm_purge(p_fd &UnixFile) {
	p := p_fd.pInode.pShmNode
	if !isnil(p) && (p.nRef == 0) {
		n_shm_per_map := unix_shm_region_per_map()
		i := 0
		sqlite3_mutex_free(p.pShmMutex)
		for i = 0; i < int(p.nRegion); i += n_shm_per_map {
			if p.hShm >= 0 {
				c2v_fnptr_666e2028766f69647074722c207573697a652920696e74(voidptr(aSyscall[23].pCurrent))(voidptr(p.apRegion[i]), usize(p.szRegion))
			} else {
				sqlite3_free(voidptr(p.apRegion[i]))
			}
		}
		sqlite3_free(voidptr(p.apRegion))
		if p.hShm >= 0 {
			robust_close(p_fd, p.hShm, 4833)
			p.hShm = -1
		}
		p.pInode.pShmNode = 0
		sqlite3_free(voidptr(p))
	}
}

@[c:'unixLockSharedMemory']
fn unix_lock_shared_memory(p_db_fd &UnixFile, p_shm_node &UnixShmNode) int {
	lock_ := C.flock{}
	rc := 0
	lock_.l_whence = i16(0)
	lock_.l_start = i64((((22 + 8) * 4) + 8))
	lock_.l_len = i64(1)
	lock_.l_type = i16(3)
	if C.C2V_VCALL_696e74282a2928696e742c696e742c2e2e2e29(voidptr((C2vFn_666e2028696e742c20696e742c202e2e2e2920696e74(voidptr(aSyscall[7].pCurrent)))), p_shm_node.hShm, 7, voidptr(&lock_)) != 0 {
		rc = (10 | (15 << 8))
	} else if int(lock_.l_type) == 2 {
		if p_shm_node.isReadonly {
			p_shm_node.isUnlocked = U8(1)
			rc = (8 | (5 << 8))
		} else {
			rc = unix_shm_system_lock(p_db_fd, 3, (((22 + 8) * 4) + 8), 1)
			if rc == 0 && robust_ftruncate(p_shm_node.hShm, Sqlite3_int64(3)) {
				rc = unix_log_error_at_line((10 | (18 << 8)), c'ftruncate', p_shm_node.zFilename, 4903)
			}
		}
	} else if int(lock_.l_type) == 3 {
		rc = 5
	}
	if rc == 0 {
		rc = unix_shm_system_lock(p_db_fd, 1, (((22 + 8) * 4) + 8), 1)
	}
	return rc
}

@[c:'unixOpenSharedMemory']
fn unix_open_shared_memory(p_db_fd &UnixFile) int {
	p := unsafe { &UnixShm(nil) }
	p_shm_node := &UnixShmNode(0)
	rc := 0
	p_inode := &UnixInodeInfo(0)
	z_shm := &i8(0)
	n_shm_filename := 0
	p = sqlite3_malloc64(Sqlite3_uint64(sizeof(UnixShm)))
	if usize(p) == usize(0) {
		return 7
	}
	C.memset(voidptr(p), 0, sizeof(UnixShm))
	unix_enter_mutex()
	p_inode = p_db_fd.pInode
	p_shm_node = p_inode.pShmNode
	if usize(p_shm_node) == usize(0) {
		s_stat := C.stat{}
		z_base_path := p_db_fd.zPath
		if c2v_fnptr_666e2028696e742c2026432e737461742920696e74(voidptr(aSyscall[5].pCurrent))(p_db_fd.h, &s_stat) {
			rc = (10 | (7 << 8))
			unsafe { goto shm_open_err
			 }
		}
		n_shm_filename = 6 + int(C.strlen(z_base_path))
		p_shm_node = sqlite3_malloc64(Sqlite3_uint64(sizeof(UnixShmNode) + u64(n_shm_filename)))
		if usize(p_shm_node) == usize(0) {
			rc = 7
			unsafe { goto shm_open_err
			 }
		}
		C.memset(voidptr(p_shm_node), 0, sizeof(UnixShmNode) + u64(n_shm_filename))
		p_shm_node.zFilename = &i8(voidptr(unsafe { p_shm_node + 1 }))
		z_shm = p_shm_node.zFilename
		sqlite3_snprintf(n_shm_filename, z_shm, c'%s-shm', voidptr(z_base_path))
		p_shm_node.hShm = -1
		p_db_fd.pInode.pShmNode = p_shm_node
		p_shm_node.pInode = p_db_fd.pInode
		if sqlite3Config.bCoreMutex {
			p_shm_node.pShmMutex = sqlite3_mutex_alloc(0)
			if usize(p_shm_node.pShmMutex) == usize(0) {
				rc = 7
				unsafe { goto shm_open_err
				 }
			}
		}
		if int(p_inode.bProcessLock) == 0 {
			if 0 == sqlite3_uri_boolean(p_db_fd.zPath, c'readonly_shm', 0) {
				p_shm_node.hShm = robust_open(z_shm, 2 | 512 | 256, u32((int(s_stat.st_mode) & 511)))
			}
			if p_shm_node.hShm < 0 {
				p_shm_node.hShm = robust_open(z_shm, 0 | 256, u32((int(s_stat.st_mode) & 511)))
				if p_shm_node.hShm < 0 {
					rc = unix_log_error_at_line(sqlite3_cantopen_error(5040), c'open', z_shm, 5040)
					unsafe { goto shm_open_err
					 }
				}
				p_shm_node.isReadonly = U8(1)
			}
			robust_fchown(p_shm_node.hShm, s_stat.st_uid, s_stat.st_gid)
			rc = unix_lock_shared_memory(p_db_fd, p_shm_node)
			if rc != 0 && rc != (8 | (5 << 8)) {
				unsafe { goto shm_open_err
				 }
			}
		}
	}
	p.pShmNode = p_shm_node
	p_shm_node.nRef++
	p_db_fd.pShm = p
	unix_leave_mutex()
	sqlite3_mutex_enter(p_shm_node.pShmMutex)
	p.pNext = p_shm_node.pFirst
	p_shm_node.pFirst = p
	sqlite3_mutex_leave(p_shm_node.pShmMutex)
	return rc
	shm_open_err:
	unix_shm_purge(p_db_fd)
	sqlite3_free(voidptr(p))
	unix_leave_mutex()
	return rc
}

@[c:'unixShmMap']
fn unix_shm_map(fd &Sqlite3_file, i_region int, sz_region int, b_extend int, pp &voidptr) int {
	c2v_gc_register_thread()
	p_db_fd := &UnixFile(voidptr(fd))
	p := &UnixShm(0)
	p_shm_node := &UnixShmNode(0)
	rc := 0
	n_shm_per_map := unix_shm_region_per_map()
	n_req_region := 0
	if usize(p_db_fd.pShm) == usize(0) {
		rc = unix_open_shared_memory(p_db_fd)
		if rc != 0 {
			return rc
		}
	}
	p = p_db_fd.pShm
	p_shm_node = p.pShmNode
	sqlite3_mutex_enter(p_shm_node.pShmMutex)
	if p_shm_node.isUnlocked {
		rc = unix_lock_shared_memory(p_db_fd, p_shm_node)
		if rc != 0 {
			unsafe { goto shmpage_out
			 }
		}
		p_shm_node.isUnlocked = U8(0)
	}
	n_req_region = ((i_region + n_shm_per_map) / n_shm_per_map) * n_shm_per_map
	if int(p_shm_node.nRegion) < n_req_region {
		ap_new := &&u8(0)
		n_byte := I64(n_req_region) * I64(sz_region)
		s_stat := C.stat{}
		p_shm_node.szRegion = sz_region
		if p_shm_node.hShm >= 0 {
			if c2v_fnptr_666e2028696e742c2026432e737461742920696e74(voidptr(aSyscall[5].pCurrent))(p_shm_node.hShm, &s_stat) {
				rc = (10 | (19 << 8))
				unsafe { goto shmpage_out
				 }
			}
			if s_stat.st_size < n_byte {
				if !b_extend {
					unsafe { goto shmpage_out
					 }
				} else {
					static pgsz := 4096
					i_pg := I64(0)
					for i_pg = (s_stat.st_size / i64(pgsz)); i_pg < (n_byte / I64(pgsz)); i_pg++ {
						x := 0
						if seek_and_write_fd(p_shm_node.hShm, i_pg * I64(pgsz) + I64(pgsz) - I64(1), voidptr(c''), 1, &x) != 1 {
							z_file := p_shm_node.zFilename
							rc = unix_log_error_at_line((10 | (19 << 8)), c'write', z_file, 5184)
							unsafe { goto shmpage_out
							 }
						}
					}
				}
			}
		}
		ap_new = &&u8(sqlite3_realloc64(voidptr(p_shm_node.apRegion), Sqlite3_uint64(u64(n_req_region) * sizeof(voidptr))))
		if isnil(ap_new) {
			rc = (10 | (12 << 8))
			unsafe { goto shmpage_out
			 }
		}
		p_shm_node.apRegion = ap_new
		for int(p_shm_node.nRegion) < n_req_region {
			n_map := I64(sz_region) * I64(n_shm_per_map)
			i := I64(0)
			p_mem := &voidptr(0)
			if p_shm_node.hShm >= 0 {
				p_mem = c2v_fnptr_666e2028766f69647074722c207573697a652c20696e742c20696e742c20696e742c206936342920766f6964707472(voidptr(aSyscall[22].pCurrent))(unsafe { nil }, usize(n_map), if int(p_shm_node.isReadonly) {
					1
				} else {
					1 | 2
				}, 1, p_shm_node.hShm, I64(sz_region) * I64(p_shm_node.nRegion))
				if usize(p_mem) == usize((voidptr(-1))) {
					rc = unix_log_error_at_line((10 | (21 << 8)), c'mmap', p_shm_node.zFilename, 5211)
					unsafe { goto shmpage_out
					 }
				}
			} else {
				p_mem = sqlite3_malloc64(Sqlite3_uint64(n_map))
				if usize(p_mem) == usize(0) {
					rc = 7
					unsafe { goto shmpage_out
					 }
				}
				C.memset(voidptr(p_mem), 0, u64(n_map))
			}
			for i = I64(0); i < I64(n_shm_per_map); i++ {
				p_shm_node.apRegion[I64(p_shm_node.nRegion) + i] = unsafe { (&i8(p_mem)) + (I64(sz_region) * i) }
			}
			p_shm_node.nRegion += n_shm_per_map
		}
	}
	shmpage_out:
	if int(p_shm_node.nRegion) > i_region {
		unsafe { *pp = p_shm_node.apRegion[i_region] }
	} else {
		unsafe { *pp = 0 }
	}
	if int(p_shm_node.isReadonly) && rc == 0 {
		rc = 8
	}
	sqlite3_mutex_leave(p_shm_node.pShmMutex)
	return rc
}

@[c:'unixShmLock']
fn unix_shm_lock(fd &Sqlite3_file, ofst int, n int, flags int) int {
	c2v_gc_register_thread()
	p_db_fd := &UnixFile(voidptr(fd))
	p := &UnixShm(0)
	p_shm_node := &UnixShmNode(0)
	rc := 0
	mask := U16((1 << (ofst + n)) - (1 << ofst))
	a_lock := &int(0)
	p = p_db_fd.pShm
	if usize(p) == usize(0) {
		return 10 | (20 << 8)
	}
	p_shm_node = p.pShmNode
	if (usize(p_shm_node) == usize(0)) {
		return 10 | (20 << 8)
	}
	a_lock = unsafe { &p_shm_node.aLock[0] }
	if ((flags & 1) && ((int(p.exclMask) | int(p.sharedMask)) & int(mask))) || (flags == (4 | 2) && 0 == (int(p.sharedMask) & int(mask))) || (flags == (8 | 2)) {
		sqlite3_mutex_enter(p_shm_node.pShmMutex)
		if (rc == 0) {
			if flags & 1 {
				b_unlock := 1
				if flags & 4 {
					if a_lock[ofst] > 1 {
						b_unlock = 0
						a_lock[ofst]--
						p.sharedMask &= ~int(mask)
					}
				}
				if b_unlock {
					rc = unix_shm_system_lock(p_db_fd, 2, ofst + ((22 + 8) * 4), n)
					if rc == 0 {
						C.memset(voidptr(unsafe { a_lock + ofst }), 0, sizeof(int) * u64(n))
						p.sharedMask &= ~int(mask)
						p.exclMask &= ~int(mask)
					}
				}
			} else if flags & 4 {
				if a_lock[ofst] < 0 {
					rc = 5
				} else if a_lock[ofst] == 0 {
					rc = unix_shm_system_lock(p_db_fd, 1, ofst + ((22 + 8) * 4), n)
				}
				if rc == 0 {
					p.sharedMask |= int(mask)
					a_lock[ofst]++
				}
			} else {
				ii := 0
				for ii = ofst; ii < ofst + n; ii++ {
					if a_lock[ii] {
						rc = 5
						break
					}
				}
				if rc == 0 {
					rc = unix_shm_system_lock(p_db_fd, 3, ofst + ((22 + 8) * 4), n)
					if rc == 0 {
						p.exclMask |= int(mask)
						for ii = ofst; ii < ofst + n; ii++ {
							a_lock[ii] = -1
						}
					}
				}
			}
		}
		sqlite3_mutex_leave(p_shm_node.pShmMutex)
	}
	return rc
}

@[c:'unixShmBarrier']
fn unix_shm_barrier(fd &Sqlite3_file) {
	c2v_gc_register_thread()

	sqlite3_memory_barrier()
	unix_enter_mutex()
	unix_leave_mutex()
}

@[c:'unixShmUnmap']
fn unix_shm_unmap(fd &Sqlite3_file, delete_flag int) int {
	c2v_gc_register_thread()
	p := &UnixShm(0)
	p_shm_node := &UnixShmNode(0)
	pp := &&UnixShm(0)
	p_db_fd := &UnixFile(0)
	p_db_fd = &UnixFile(voidptr(fd))
	p = p_db_fd.pShm
	if usize(p) == usize(0) {
		return 0
	}
	p_shm_node = p.pShmNode
	sqlite3_mutex_enter(p_shm_node.pShmMutex)
	for pp = &p_shm_node.pFirst; usize((unsafe { *pp })) != usize(p); pp = &(unsafe { *pp }).pNext {
	}
	unsafe { *pp = p.pNext }
	sqlite3_free(voidptr(p))
	p_db_fd.pShm = 0
	sqlite3_mutex_leave(p_shm_node.pShmMutex)
	unix_enter_mutex()
	p_shm_node.nRef--
	if p_shm_node.nRef == 0 {
		if delete_flag && p_shm_node.hShm >= 0 {
			c2v_fnptr_666e20282669382920696e74(voidptr(aSyscall[16].pCurrent))(p_shm_node.zFilename)
		}
		unix_shm_purge(p_db_fd)
	}
	unix_leave_mutex()
	return 0
}

@[c:'unixUnmapfile']
fn unix_unmapfile(p_fd &UnixFile) {
	if p_fd.pMapRegion {
		c2v_fnptr_666e2028766f69647074722c207573697a652920696e74(voidptr(aSyscall[23].pCurrent))(voidptr(p_fd.pMapRegion), usize(p_fd.mmapSizeActual))
		p_fd.pMapRegion = 0
		p_fd.mmapSize = Sqlite3_int64(0)
		p_fd.mmapSizeActual = Sqlite3_int64(0)
	}
}

@[c:'unixRemapfile']
fn unix_remapfile(p_fd &UnixFile, n_new I64) {
	z_err := c'mmap'
	h := p_fd.h
	p_orig := &U8(p_fd.pMapRegion)
	n_orig := p_fd.mmapSizeActual
	p_new := unsafe { &U8(nil) }
	flags := 1
	if p_orig {
		sz_syspage := c2v_fnptr_666e20282920696e74(voidptr(aSyscall[25].pCurrent))()
		n_reuse := (p_fd.mmapSize & Sqlite3_int64(~(sz_syspage - 1)))
		p_req := unsafe { p_orig + n_reuse }
		if n_reuse != n_orig {
			c2v_fnptr_666e2028766f69647074722c207573697a652920696e74(voidptr(aSyscall[23].pCurrent))(voidptr(p_req), usize(n_orig - n_reuse))
		}
		p_new = c2v_fnptr_666e2028766f69647074722c207573697a652c20696e742c20696e742c20696e742c206936342920766f6964707472(voidptr(aSyscall[22].pCurrent))(voidptr(p_req), usize(n_new - n_reuse), flags, 1, h, n_reuse)
		if usize(p_new) != usize((voidptr(-1))) {
			if usize(p_new) != usize(p_req) {
				c2v_fnptr_666e2028766f69647074722c207573697a652920696e74(voidptr(aSyscall[23].pCurrent))(voidptr(p_new), usize(n_new - n_reuse))
				p_new = 0
			} else {
				p_new = p_orig
			}
		}
		if usize(p_new) == usize((voidptr(-1))) || usize(p_new) == usize(0) {
			c2v_fnptr_666e2028766f69647074722c207573697a652920696e74(voidptr(aSyscall[23].pCurrent))(voidptr(p_orig), usize(n_reuse))
		}
	}
	if usize(p_new) == usize(0) {
		p_new = c2v_fnptr_666e2028766f69647074722c207573697a652c20696e742c20696e742c20696e742c206936342920766f6964707472(voidptr(aSyscall[22].pCurrent))(unsafe { nil }, usize(n_new), flags, 1, h, i64(0))
	}
	if usize(p_new) == usize((voidptr(-1))) {
		p_new = 0
		n_new = I64(0)
		unix_log_error_at_line(0, z_err, p_fd.zPath, 5650)
		p_fd.mmapSizeMax = Sqlite3_int64(0)
	}
	p_fd.pMapRegion = voidptr(p_new)
	p_fd.mmapSizeActual = n_new
	p_fd.mmapSize = p_fd.mmapSizeActual
}

@[c:'unixMapfile']
fn unix_mapfile(p_fd &UnixFile, n_map I64) int {
	if p_fd.nFetchOut > 0 {
		return 0
	}
	if n_map < I64(0) {
		statbuf := C.stat{}
		if c2v_fnptr_666e2028696e742c2026432e737461742920696e74(voidptr(aSyscall[5].pCurrent))(p_fd.h, &statbuf) {
			return 10 | (7 << 8)
		}
		n_map = statbuf.st_size
	}
	if n_map > p_fd.mmapSizeMax {
		n_map = p_fd.mmapSizeMax
	}
	if n_map != p_fd.mmapSize {
		unix_remapfile(p_fd, n_map)
	}
	return 0
}

@[c:'unixFetch']
fn unix_fetch(fd &Sqlite3_file, i_off I64, n_amt int, pp &voidptr) int {
	c2v_gc_register_thread()
	p_fd := &UnixFile(voidptr(fd))
	unsafe { *pp = 0 }
	if p_fd.mmapSizeMax > Sqlite3_int64(0) {
		n_eof_buffer := 256
		if usize(p_fd.pMapRegion) == usize(0) {
			rc := unix_mapfile(p_fd, I64(-1))
			if rc != 0 {
				return rc
			}
		}
		if p_fd.mmapSize >= (i_off + I64(n_amt) + I64(n_eof_buffer)) {
			unsafe { *pp = (&U8(p_fd.pMapRegion)) + i_off }
			p_fd.nFetchOut++
		}
	}
	return 0
}

@[c:'unixUnfetch']
fn unix_unfetch(fd &Sqlite3_file, i_off I64, p voidptr) int {
	c2v_gc_register_thread()
	p_fd := &UnixFile(voidptr(fd))

	if p {
		p_fd.nFetchOut--
	} else {
		unix_unmapfile(p_fd)
	}
	return 0
}

@[c:'posixIoFinderImpl']
fn posix_io_finder_impl(z &i8, p &UnixFile) &Sqlite3_io_methods {
	c2v_gc_register_thread()

	return &posixIoMethods
}

@[c:'nolockIoFinderImpl']
fn nolock_io_finder_impl(z &i8, p &UnixFile) &Sqlite3_io_methods {
	c2v_gc_register_thread()

	return &nolockIoMethods
}

@[c:'dotlockIoFinderImpl']
fn dotlock_io_finder_impl(z &i8, p &UnixFile) &Sqlite3_io_methods {
	c2v_gc_register_thread()

	return &dotlockIoMethods
}

@[c:'flockIoFinderImpl']
fn flock_io_finder_impl(z &i8, p &UnixFile) &Sqlite3_io_methods {
	c2v_gc_register_thread()

	return &flockIoMethods
}

@[c:'afpIoFinderImpl']
fn afp_io_finder_impl(z &i8, p &UnixFile) &Sqlite3_io_methods {
	c2v_gc_register_thread()

	return &afpIoMethods
}

@[c:'proxyIoFinderImpl']
fn proxy_io_finder_impl(z &i8, p &UnixFile) &Sqlite3_io_methods {
	c2v_gc_register_thread()

	return &proxyIoMethods
}

@[c:'nfsIoFinderImpl']
fn nfs_io_finder_impl(z &i8, p &UnixFile) &Sqlite3_io_methods {
	c2v_gc_register_thread()

	return &nfsIoMethods
}

@[c:'autolockIoFinderImpl']
fn autolock_io_finder_impl(file_path &i8, p_new &UnixFile) &Sqlite3_io_methods {
	c2v_gc_register_thread()
	if !autolock_io_finder_impl_a_map_inited {
		c2v_static_init := [Mapping{
			zFilesystem: c'hfs'
			pMethods: &posixIoMethods
		}, Mapping{
			zFilesystem: c'ufs'
			pMethods: &posixIoMethods
		}, Mapping{
			zFilesystem: c'afpfs'
			pMethods: &afpIoMethods
		}, Mapping{
			zFilesystem: c'smbfs'
			pMethods: &afpIoMethods
		}, Mapping{
			zFilesystem: c'webdav'
			pMethods: &nolockIoMethods
		}, Mapping{}]!
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			autolock_io_finder_impl_a_map[c2v_i_0] = c2v_element_0
		}
		autolock_io_finder_impl_a_map_inited = true
	}

	i := 0
	fs_info := C.statfs{}
	lock_info := C.flock{}
	if isnil(file_path) {
		return &nolockIoMethods
	}
	if c2v_fn_statfs(file_path, &fs_info) != -1 {
		if fs_info.f_flags & u32(1) {
			return &nolockIoMethods
		}
		for i = 0; autolock_io_finder_impl_a_map[i].zFilesystem; i++ {
			if C.strcmp(unsafe { &i8(&fs_info.f_fstypename[0]) }, autolock_io_finder_impl_a_map[i].zFilesystem) == 0 {
				return autolock_io_finder_impl_a_map[i].pMethods
			}
		}
	}
	lock_info.l_len = i64(1)
	lock_info.l_start = i64(0)
	lock_info.l_whence = i16(0)
	lock_info.l_type = i16(1)
	if C.C2V_VCALL_696e74282a2928696e742c696e742c2e2e2e29(voidptr((C2vFn_666e2028696e742c20696e742c202e2e2e2920696e74(voidptr(aSyscall[7].pCurrent)))), p_new.h, 7, voidptr(&lock_info)) != -1 {
		if C.strcmp(unsafe { &i8(&fs_info.f_fstypename[0]) }, c'nfs') == 0 {
			return &nfsIoMethods
		} else {
			return &posixIoMethods
		}
	} else {
		return &dotlockIoMethods
	}
}

type Finder_type = fn (&i8, &UnixFile) &Sqlite3_io_methods

@[c:'fillInUnixFile']
fn fill_in_unix_file(p_vfs &Sqlite3_vfs, h int, p_id &Sqlite3_file, z_filename &i8, ctrl_flags int) int {
	p_locking_style := &Sqlite3_io_methods(0)
	p_new := &UnixFile(voidptr(p_id))
	rc := 0
	p_new.h = h
	p_new.pVfs = p_vfs
	p_new.zPath = z_filename
	p_new.ctrlFlags = u16(U8(ctrl_flags))
	p_new.mmapSizeMax = sqlite3Config.szMmap
	if sqlite3_uri_boolean((unsafe { if (ctrl_flags & 64) { z_filename } else { &i8(nil) } }), c'psow', 1) {
		p_new.ctrlFlags |= 16
	}
	if C.strcmp(p_vfs.zName, c'unix-excl') == 0 {
		p_new.ctrlFlags |= 1
	}
	if ctrl_flags & 128 {
		p_locking_style = &nolockIoMethods
	} else {
		p_locking_style = c2v_fnptr_666e20282669382c2026556e697846696c6529202653716c697465335f696f5f6d6574686f6473(voidptr((unsafe { *&voidptr(p_vfs.pAppData) })))(z_filename, p_new)
		p_new.lockingContext = voidptr(z_filename)
	}
	if usize(p_locking_style) == usize(&posixIoMethods) || usize(p_locking_style) == usize(&nfsIoMethods) {
		unix_enter_mutex()
		rc = find_inode_info(p_new, &&UnixInodeInfo(&p_new.pInode))
		if rc != 0 {
			robust_close(p_new, h, 6158)
			h = -1
		}
		unix_leave_mutex()
	} else if usize(p_locking_style) == usize(&afpIoMethods) {
		p_ctx := &AfpLockingContext(0)
		p_ctx = sqlite3_malloc64(Sqlite3_uint64(sizeof(AfpLockingContext)))
		p_new.lockingContext = p_ctx
		if usize(p_ctx) == usize(0) {
			rc = 7
		} else {
			p_ctx.dbPath = z_filename
			p_ctx.reserved = 0
			C.srandomdev()
			unix_enter_mutex()
			rc = find_inode_info(p_new, &&UnixInodeInfo(&p_new.pInode))
			if rc != 0 {
				sqlite3_free(voidptr(p_new.lockingContext))
				robust_close(p_new, h, 6184)
				h = -1
			}
			unix_leave_mutex()
		}
	} else if usize(p_locking_style) == usize(&dotlockIoMethods) {
		z_lock_file := &i8(0)
		n_filename := 0
		n_filename = int(C.strlen(z_filename)) + 6
		z_lock_file = &i8(sqlite3_malloc64(Sqlite3_uint64(n_filename)))
		if usize(z_lock_file) == usize(0) {
			rc = 7
		} else {
			sqlite3_snprintf(n_filename, z_lock_file, c'%s.lock', voidptr(z_filename))
		}
		p_new.lockingContext = z_lock_file
	}
	store_last_errno(p_new, 0)
	if rc != 0 {
		if h >= 0 {
			robust_close(p_new, h, 6250)
		}
	} else {
		p_id.pMethods = p_locking_style
		verify_db_file(p_new)
	}
	return rc
}

@[c:'unixTempFileInit']
fn unix_temp_file_init() {
	azTempDirs[0] = C.getenv(c'SQLITE_TMPDIR')
	azTempDirs[1] = C.getenv(c'TMPDIR')
}

@[c:'unixTempFileDir']
fn unix_temp_file_dir() &i8 {
	i := u32(0)
	buf := C.stat{}
	z_dir := sqlite3_temp_directory
	for {
		mut __c2v_condition_3 := false
		mut __c2v_condition_4 := false
		__c2v_condition_4 = usize(z_dir) != usize(0)
		if __c2v_condition_4 {
			__c2v_condition_4 = c2v_fncall_666e20282669382c2026432e737461742920696e74(voidptr(aSyscall[4].pCurrent), z_dir, &buf) == 0
		}
		if __c2v_condition_4 {
			__c2v_condition_4 = ((int(buf.st_mode) & 61440) == 16384)
		}
		if __c2v_condition_4 {
			__c2v_condition_4 = c2v_fncall_666e20282669382c20696e742920696e74(voidptr(aSyscall[2].pCurrent), z_dir, 3) == 0
		}
		__c2v_condition_3 = __c2v_condition_4
		if __c2v_condition_3 {
			return z_dir
		}
		if u64(i) >= 6 {
			break
		}
		z_dir = azTempDirs[i++]
	}
	return unsafe { nil }
}

@[c:'unixGetTempname']
fn unix_get_tempname(n_buf int, z_buf &i8) int {
	z_dir := &i8(0)
	i_limit := 0
	rc := 0
	z_buf[0] = i8(0)
	sqlite3_mutex_enter(sqlite3_mutex_alloc_vdup4(11))
	z_dir = unix_temp_file_dir()
	if usize(z_dir) == usize(0) {
		rc = (10 | (25 << 8))
	} else {
		for {
			r := U64(0)
			sqlite3_randomness(int(sizeof(r)), voidptr(&r))
			z_buf[n_buf - 2] = i8(0)
			sqlite3_snprintf(n_buf, z_buf, c'%s/etilqs_%llx%c', voidptr(z_dir), r, 0)
			if int(z_buf[n_buf - 2]) != 0 || (i_limit++) > 10 {
				rc = 1
				break
			}
			if !(c2v_fnptr_666e20282669382c20696e742920696e74(voidptr(aSyscall[2].pCurrent))(z_buf, 0) == 0) {
				break
			}
		}
	}
	sqlite3_mutex_leave(sqlite3_mutex_alloc_vdup4(11))
	return rc
}

@[c:'findReusableFd']
fn find_reusable_fd(z_path &i8, flags int) &UnixUnusedFd {
	p_unused := unsafe { &UnixUnusedFd(nil) }
	s_stat := C.stat{}
	unix_enter_mutex()
	if usize(inodeList) != usize(0) && 0 == c2v_fncall_666e20282669382c2026432e737461742920696e74(voidptr(aSyscall[4].pCurrent), z_path, &s_stat) {
		p_inode := &UnixInodeInfo(0)
		p_inode = inodeList
		for !isnil(p_inode) && (p_inode.fileId.dev != s_stat.st_dev || p_inode.fileId.ino != U64(s_stat.st_ino)) {
			p_inode = p_inode.pNext
		}
		if p_inode {
			pp := &&UnixUnusedFd(0)
			sqlite3_mutex_enter(p_inode.pLockMutex)
			flags &= (1 | 2)
			for pp = &p_inode.pUnused; !isnil((unsafe { *pp })) && (unsafe { *pp }).flags != flags; pp = &(unsafe { *pp }).pNext {
			}
			p_unused = unsafe { *pp }
			if p_unused {
				unsafe { *pp = p_unused.pNext }
			}
			sqlite3_mutex_leave(p_inode.pLockMutex)
		}
	}
	unix_leave_mutex()
	return p_unused
}

@[c:'getFileMode']
fn get_file_mode(z_file &i8, p_mode &u32, p_uid &u32, p_gid &u32) int {
	s_stat := C.stat{}
	rc := 0
	if 0 == c2v_fnptr_666e20282669382c2026432e737461742920696e74(voidptr(aSyscall[4].pCurrent))(z_file, &s_stat) {
		unsafe { *p_mode = u32(int(s_stat.st_mode) & 511) }
		unsafe { *p_uid = s_stat.st_uid }
		unsafe { *p_gid = s_stat.st_gid }
	} else {
		rc = (10 | (7 << 8))
	}
	return rc
}

@[c:'findCreateFileMode']
fn find_create_file_mode(z_path &i8, flags int, p_mode &u32, p_uid &u32, p_gid &u32) int {
	rc := 0
	unsafe { *p_mode = u32(0) }
	unsafe { *p_uid = u32(0) }
	unsafe { *p_gid = u32(0) }
	if flags & (524288 | 2048) {
		z_db := [513]i8{}
		n_db := 0
		n_db = sqlite3_strlen30(z_path) - 1
		for n_db > 0 && int(z_path[n_db]) != i8(`.`) {
			if int(z_path[n_db]) == i8(`-`) {
				C.memcpy(voidptr(unsafe { &z_db[0] }), voidptr(z_path), u64(n_db))
				z_db[n_db] = i8(`\0`)
				rc = get_file_mode(unsafe { &i8(&z_db[0]) }, p_mode, p_uid, p_gid)
				break
			}
			n_db--
		}
	} else if flags & 8 {
		unsafe { *p_mode = u32(384) }
	} else if flags & 64 {
		z := sqlite3_uri_parameter(z_path, c'modeof')
		if z {
			rc = get_file_mode(z, p_mode, p_uid, p_gid)
		}
	}
	return rc
}

@[c:'unixOpen']
fn unix_open(p_vfs &Sqlite3_vfs, z_path &i8, p_file &Sqlite3_file, flags int, p_out_flags &int) int {
	c2v_gc_register_thread()
	p := &UnixFile(voidptr(p_file))
	fd := -1
	open_flags := 0
	e_type := flags & 1048320
	no_lock := 0
	rc := 0
	ctrl_flags := 0
	is_exclusive := (flags & 16)
	is_delete := (flags & 8)
	is_create := (flags & 4)
	is_readonly := (flags & 1)
	is_read_write := (flags & 2)
	is_auto_proxy := (flags & 32)
	fs_info := C.statfs{}
	is_new_jrnl := int((is_create && (e_type == 16384 || e_type == 2048 || e_type == 524288)))
	z_tmpname := [514]i8{}
	z_name := z_path
	if randomnessPid != int(C.getpid()) {
		randomnessPid = int(C.getpid())
		sqlite3_randomness(0, unsafe { nil })
	}
	C.memset(voidptr(p), 0, sizeof(UnixFile))
	if e_type == 256 {
		p_unused := &UnixUnusedFd(0)
		p_unused = find_reusable_fd(z_name, flags)
		if p_unused {
			fd = p_unused.fd
		} else {
			p_unused = sqlite3_malloc64(Sqlite3_uint64(sizeof(UnixUnusedFd)))
			if isnil(p_unused) {
				return 7
			}
		}
		p.pPreallocatedUnused = p_unused
	} else if isnil(z_name) {
		rc = unix_get_tempname(p_vfs.mxPathname, unsafe { &i8(&z_tmpname[0]) })
		if rc != 0 {
			return rc
		}
		z_name = unsafe { &z_tmpname[0] }
	}
	if is_readonly {
		open_flags |= 0
	}
	if is_read_write {
		open_flags |= 2
	}
	if is_create {
		open_flags |= 512
	}
	if is_exclusive {
		open_flags |= (2048 | 256)
	}
	open_flags |= (0 | 0 | 256)
	if fd < 0 {
		open_mode := u32(0)
		uid := u32(0)
		gid := u32(0)
		rc = find_create_file_mode(z_name, flags, &open_mode, &uid, &gid)
		if rc != 0 {
			return rc
		}
		fd = robust_open(z_name, open_flags, open_mode)
		if fd < 0 {
			if is_new_jrnl && (unsafe { *C.__error() }) == 13 && c2v_fncall_666e20282669382c20696e742920696e74(voidptr(aSyscall[2].pCurrent), z_name, 0) {
				rc = (8 | (6 << 8))
			} else if (unsafe { *C.__error() }) != 21 && is_read_write {
				p_readonly := unsafe { &UnixUnusedFd(nil) }
				flags &= ~(2 | 4)
				open_flags &= ~(2 | 512)
				flags |= 1
				open_flags |= 0
				is_readonly = 1
				p_readonly = find_reusable_fd(z_name, flags)
				if p_readonly {
					fd = p_readonly.fd
					sqlite3_free(voidptr(p_readonly))
				} else {
					fd = robust_open(z_name, open_flags, open_mode)
				}
			}
		}
		if fd < 0 {
			rc2 := unix_log_error_at_line(sqlite3_cantopen_error(6707), c'open', z_name, 6707)
			if rc == 0 {
				rc = rc2
			}
			unsafe { goto open_finished
			 }
		}
		if int(open_mode) && (flags & (524288 | 2048)) != 0 {
			robust_fchown(fd, uid, gid)
		}
	}
	if p_out_flags {
		unsafe { *p_out_flags = flags }
	}
	if p.pPreallocatedUnused {
		p.pPreallocatedUnused.fd = fd
		p.pPreallocatedUnused.flags = flags & (1 | 2)
	}
	if is_delete {
		c2v_fnptr_666e20282669382920696e74(voidptr(aSyscall[16].pCurrent))(z_name)
	} else {
		p.openFlags = open_flags
	}
	if C.fstatfs(fd, &fs_info) == -1 {
		store_last_errno(p, (unsafe { *C.__error() }))
		robust_close(p, fd, 6761)
		return 10 | (13 << 8)
	}
	if 0 == C.strncmp(c'msdos', unsafe { &i8(&fs_info.f_fstypename[0]) }, u64(5)) {
		(&UnixFile(voidptr(p_file))).fsFlags |= u32(1)
	}
	if 0 == C.strncmp(c'exfat', unsafe { &i8(&fs_info.f_fstypename[0]) }, u64(5)) {
		(&UnixFile(voidptr(p_file))).fsFlags |= u32(1)
	}
	if is_delete {
		ctrl_flags |= 32
	}
	if is_readonly {
		ctrl_flags |= 2
	}
	no_lock = e_type != 256
	if no_lock {
		ctrl_flags |= 128
	}
	if is_new_jrnl {
		ctrl_flags |= 8
	}
	if flags & 64 {
		ctrl_flags |= 64
	}
	if is_auto_proxy && (usize(z_path) != usize((voidptr(0)))) && (!no_lock) && !isnil(p_vfs.xOpen) {
		envforce := C.getenv(c'SQLITE_FORCE_PROXY_LOCKING')
		use_proxy := 0
		if usize(envforce) != usize((voidptr(0))) {
			use_proxy = C.atoi(envforce) > 0
		} else {
			use_proxy = !(fs_info.f_flags & u32(4096))
		}
		if use_proxy {
			rc = fill_in_unix_file(p_vfs, fd, p_file, z_path, ctrl_flags)
			if rc == 0 {
				rc = proxy_transform_unix_file(&UnixFile(voidptr(p_file)), c':auto:')
				if rc != 0 {
					unix_close(p_file)
					return rc
				}
			}
			unsafe { goto open_finished
			 }
		}
	}
	rc = fill_in_unix_file(p_vfs, fd, p_file, z_path, ctrl_flags)
	open_finished:
	if rc != 0 {
		sqlite3_free(voidptr(p.pPreallocatedUnused))
	}
	return rc
}

@[c:'unixDelete']
fn unix_delete(not_used &Sqlite3_vfs, z_path &i8, dir_sync int) int {
	c2v_gc_register_thread()
	rc := 0

	if c2v_fnptr_666e20282669382920696e74(voidptr(aSyscall[16].pCurrent))(z_path) == (-1) {
		if (unsafe { *C.__error() }) == 2 {
			rc = (10 | (23 << 8))
		} else {
			rc = unix_log_error_at_line((10 | (10 << 8)), c'unlink', z_path, 6849)
		}
		return rc
	}
	if (dir_sync & 1) != 0 {
		fd := 0
		rc = c2v_fnptr_666e20282669382c2026696e742920696e74(voidptr(aSyscall[17].pCurrent))(z_path, &fd)
		if rc == 0 {
			if full_fsync(fd, 0, 0) {
				rc = unix_log_error_at_line((10 | (5 << 8)), c'fsync', z_path, 6859)
			}
			robust_close(unsafe { nil }, fd, 6861)
		} else {
			rc = 0
		}
	}
	return rc
}

@[c:'unixAccess']
fn unix_access(not_used &Sqlite3_vfs, z_path &i8, flags int, p_res_out &int) int {
	c2v_gc_register_thread()

	if flags == 0 {
		buf := C.stat{}
		unsafe { *p_res_out = 0 == c2v_fnptr_666e20282669382c2026432e737461742920696e74(voidptr(aSyscall[4].pCurrent))(z_path, &buf) && (!((int(buf.st_mode) & 61440) == 32768) || buf.st_size > i64(0)) }
	} else {
		unsafe { *p_res_out = c2v_fnptr_666e20282669382c20696e742920696e74(voidptr(aSyscall[2].pCurrent))(z_path, (1 << 1) | (1 << 2)) == 0 }
	}
	return 0
}

struct DbPath {
	rc       int
	nSymlink int
	zOut     &i8
	nOut     int
	nUsed    int
}

@[c:'appendOnePathElement']
fn append_one_path_element(p_path &DbPath, z_name &i8, n_name int) {
	if int(z_name[0]) == i8(`.`) {
		if n_name == 1 {
			return
		}
		if int(z_name[1]) == i8(`.`) && n_name == 2 {
			if p_path.nUsed > 1 {
				for {
					p_path.nUsed--
					if !(int(p_path.zOut[p_path.nUsed]) != i8(`/`)) {
						break
					}
				}
			}
			return
		}
	}
	if p_path.nUsed + n_name + 2 >= p_path.nOut {
		p_path.rc = 1
		return
	}
	p_path.zOut[p_path.nUsed++] = i8(`/`)
	C.memcpy(voidptr(unsafe { p_path.zOut + p_path.nUsed }), voidptr(z_name), u64(n_name))
	p_path.nUsed += n_name
	if p_path.rc == 0 {
		z_in := &i8(0)
		buf := C.stat{}
		p_path.zOut[p_path.nUsed] = i8(0)
		z_in = p_path.zOut
		if c2v_fnptr_666e20282669382c2026432e737461742920696e74(voidptr(aSyscall[27].pCurrent))(z_in, &buf) != 0 {
			if (unsafe { *C.__error() }) != 2 {
				p_path.rc = unix_log_error_at_line(sqlite3_cantopen_error(6955), c'lstat', z_in, 6955)
			}
		} else if ((int(buf.st_mode) & 61440) == 40960) {
			got := isize(0)
			z_lnk := [1026]i8{}
			if p_path.nSymlink++ > 200 {
				p_path.rc = sqlite3_cantopen_error(6961)
				return
			}
			got = c2v_fnptr_666e20282669382c202669382c207573697a6529206973697a65(voidptr(aSyscall[26].pCurrent))(z_in, unsafe { &i8(&z_lnk[0]) }, sizeof([1026]i8) - u64(2))
			if got <= isize(0) || got >= isize(sizeof([1026]i8)) - isize(2) {
				p_path.rc = unix_log_error_at_line(sqlite3_cantopen_error(6966), c'readlink', z_in, 6966)
				return
			}
			z_lnk[got] = i8(0)
			if int(z_lnk[0]) == i8(`/`) {
				p_path.nUsed = 0
			} else {
				p_path.nUsed -= n_name + 1
			}
			append_all_path_elements(p_path, unsafe { &i8(&z_lnk[0]) })
		}
	}
}

@[c:'appendAllPathElements']
fn append_all_path_elements(p_path &DbPath, z_path &i8) {
	i := 0
	j := 0
	for {
		for int(z_path[i]) && int(z_path[i]) != i8(`/`) {
			i++
		}
		if i > j {
			append_one_path_element(p_path, unsafe { z_path + j }, i - j)
		}
		j = i + 1
		if !(z_path[i++]) {
			break
		}
	}
}

@[c:'unixFullPathname']
fn unix_full_pathname(p_vfs &Sqlite3_vfs, z_path &i8, n_out int, z_out &i8) int {
	c2v_gc_register_thread()
	path := DbPath{}

	path.rc = 0
	path.nUsed = 0
	path.nSymlink = 0
	path.nOut = n_out
	path.zOut = z_out
	if int(z_path[0]) != i8(`/`) {
		z_pwd := [1026]i8{}
		if usize(c2v_fnptr_666e20282669382c207573697a652920266938(voidptr(aSyscall[3].pCurrent))(unsafe { &i8(&z_pwd[0]) }, sizeof([1026]i8) - u64(2))) == usize(0) {
			return unix_log_error_at_line(sqlite3_cantopen_error(7024), c'getcwd', z_path, 7024)
		}
		append_all_path_elements(&path, unsafe { &i8(&z_pwd[0]) })
	}
	append_all_path_elements(&path, z_path)
	z_out[path.nUsed] = i8(0)
	if path.rc || path.nUsed < 2 {
		return sqlite3_cantopen_error(7030)
	}
	if path.nSymlink {
		return 0 | (2 << 8)
	}
	return 0
}

@[c:'unixDlOpen']
fn unix_dl_open(not_used &Sqlite3_vfs, z_filename &i8) voidptr {
	c2v_gc_register_thread()

	return C.dlopen(z_filename, 2 | 8)
}

@[c:'unixDlError']
fn unix_dl_error(not_used &Sqlite3_vfs, n_buf int, z_buf_out &i8) {
	c2v_gc_register_thread()
	z_err := &i8(0)

	unix_enter_mutex()
	z_err = C.dlerror()
	if z_err {
		sqlite3_snprintf(n_buf, z_buf_out, c'%s', voidptr(z_err))
	}
	unix_leave_mutex()
}

@[c:'unixDlSym']
fn unix_dl_sym(not_used &Sqlite3_vfs, p voidptr, z_sym &i8) C2vFn_666e202829 {
	c2v_gc_register_thread()
	x := C2vFn_666e2028766f69647074722c202669382920433276466e5f36363665323032383239(voidptr(0))

	x = C2vFn_666e2028766f69647074722c202669382920433276466e5f36363665323032383239(voidptr(C.dlsym))
	return x(p, z_sym)
}

@[c:'unixDlClose']
fn unix_dl_close(not_used &Sqlite3_vfs, p_handle voidptr) {
	c2v_gc_register_thread()

	C.dlclose(voidptr(p_handle))
}

@[c:'unixRandomness']
fn unix_randomness(not_used &Sqlite3_vfs, n_buf int, z_buf &i8) int {
	c2v_gc_register_thread()

	C.memset(voidptr(z_buf), 0, u64(n_buf))
	randomnessPid = int(C.getpid())
	fd := 0
	got := 0

	fd = robust_open(c'/dev/urandom', 0, u32(0))
	if fd < 0 {
		t := i64(0)
		C.time(&t)
		C.memcpy(voidptr(z_buf), voidptr(&t), sizeof(t))
		C.memcpy(voidptr(unsafe { z_buf + sizeof(t) }), voidptr(&randomnessPid), sizeof(randomnessPid))
		n_buf = int(sizeof(t) + sizeof(randomnessPid))
	} else {
		for {
			got = int(c2v_fnptr_666e2028696e742c20766f69647074722c207573697a6529206973697a65(voidptr(aSyscall[8].pCurrent))(fd, voidptr(z_buf), usize(n_buf)))
			if !(got < 0 && (unsafe { *C.__error() }) == 4) {
				break
			}
		}
		robust_close(unsafe { nil }, fd, 7131)
	}
	return n_buf
}

@[c:'unixSleep']
fn unix_sleep(not_used &Sqlite3_vfs, microseconds int) int {
	c2v_gc_register_thread()
	sp := C.timespec{}
	sp.tv_sec = i64(microseconds / 1000000)
	sp.tv_nsec = i64((microseconds % 1000000) * 1000)
	C.nanosleep(&sp, (voidptr(0)))

	return microseconds
}

@[c:'unixCurrentTimeInt64']
fn unix_current_time_int64(not_used &Sqlite3_vfs, pi_now &Sqlite3_int64) int {
	c2v_gc_register_thread()
	static unix_epoch := Sqlite3_int64(24405875) * Sqlite3_int64(8640000)
	rc := 0
	s_now := C.timeval{}
	C.gettimeofday(&s_now, unsafe { nil })
	unsafe { *pi_now = unix_epoch + Sqlite3_int64(1000) * Sqlite3_int64(s_now.tv_sec) + Sqlite3_int64(s_now.tv_usec / 1000) }

	return rc
}

@[c:'unixCurrentTime']
fn unix_current_time(not_used &Sqlite3_vfs, pr_now &f64) int {
	c2v_gc_register_thread()
	i := Sqlite3_int64(0)
	rc := 0

	rc = unix_current_time_int64(unsafe { nil }, &i)
	unsafe { *pr_now = f64(i) / 8.64E+7 }
	return rc
}

@[c:'unixGetLastError']
fn unix_get_last_error(not_used &Sqlite3_vfs, not_used2 int, not_used3 &i8) int {
	c2v_gc_register_thread()

	return unsafe { *C.__error() }
}

struct ProxyLockingContext {
	conchFile         &UnixFile
	conchFilePath     &i8
	lockProxy         &UnixFile
	lockProxyPath     &i8
	dbPath            &i8
	conchHeld         int
	nFails            int
	oldLockingContext voidptr
	pOldMethod        &Sqlite3_io_methods
}

@[c:'proxyGetLockPath']
fn proxy_get_lock_path(db_path &i8, l_path &i8, max_len usize) int {
	len := 0
	db_len := 0
	i := 0
	if !C.confstr(65537, l_path, max_len) {
		return 10 | (15 << 8)
	}
	len = int(C.strlcat(l_path, c'sqliteplocks', max_len))
	if int(l_path[len - 1]) != i8(`/`) {
		len = int(C.strlcat(l_path, c'/', max_len))
	}
	db_len = int(C.strlen(db_path))
	for i = 0; i < db_len && (i + len + 7) < int(max_len); i++ {
		c := db_path[i]
		l_path[i + len] = i8(if (int(c) == i8(`/`)) { `_` } else { int(c) })
	}
	l_path[i + len] = i8(`\0`)
	C.strlcat(l_path, c':auto:', max_len)
	return 0
}

@[c:'proxyCreateLockPath']
fn proxy_create_lock_path(lock_path &i8) int {
	i := 0
	len := 0

	buf := [1024]i8{}
	start := 0
	len = int(C.strlen(lock_path))
	buf[0] = lock_path[0]
	for i = 1; i < len; i++ {
		if int(lock_path[i]) == i8(`/`) && (i - start > 0) {
			if i - start > 2 || (i - start == 1 && int(buf[start]) != i8(`.`) && int(buf[start]) != i8(`/`)) || (i - start == 2 && int(buf[start]) != i8(`.`) && int(buf[start + 1]) != i8(`.`)) {
				buf[i] = i8(`\0`)
				if c2v_fnptr_666e20282669382c207533322920696e74(voidptr(aSyscall[18].pCurrent))(unsafe { &i8(&buf[0]) }, u32(493)) {
					err := (unsafe { *C.__error() })
					if err != 17 {
						return err
					}
				}
			}
			start = i + 1
		}
		buf[i] = lock_path[i]
	}
	return 0
}

@[c:'proxyCreateUnixFile']
fn proxy_create_unix_file(path &i8, pp_file &&UnixFile, islockfile int) int {
	fd := -1
	p_new := &UnixFile(0)
	rc := 0
	open_flags := 2 | 512 | 256
	dummy_vfs := Sqlite3_vfs{}
	terrno := 0
	p_unused := unsafe { &UnixUnusedFd(nil) }
	p_unused = find_reusable_fd(path, open_flags)
	if p_unused {
		fd = p_unused.fd
	} else {
		p_unused = sqlite3_malloc64(Sqlite3_uint64(sizeof(UnixUnusedFd)))
		if isnil(p_unused) {
			return 7
		}
	}
	if fd < 0 {
		fd = robust_open(path, open_flags, u32(0))
		terrno = unsafe { *C.__error() }
		if fd < 0 && (unsafe { *C.__error() }) == 2 && islockfile {
			if proxy_create_lock_path(path) == 0 {
				fd = robust_open(path, open_flags, u32(0))
			}
		}
	}
	if fd < 0 {
		open_flags = 0 | 256
		fd = robust_open(path, open_flags, u32(0))
		terrno = unsafe { *C.__error() }
	}
	if fd < 0 {
		if islockfile {
			return 5
		}
		match terrno {
			13 {
				return 3
			}
			5 {
				return 10 | (15 << 8)
			}
			else {
				return sqlite3_cantopen_error(7565)
			}
		}
	}
	p_new = &UnixFile(sqlite3_malloc64(Sqlite3_uint64(sizeof(UnixFile))))
	if usize(p_new) == usize((voidptr(0))) {
		rc = 7
		unsafe { goto end_create_proxy
		 }
	}
	C.memset(voidptr(p_new), 0, sizeof(UnixFile))
	p_new.openFlags = open_flags
	C.memset(voidptr(&dummy_vfs), 0, sizeof(dummy_vfs))
	dummy_vfs.pAppData = voidptr(&autolockIoFinder)
	dummy_vfs.zName = c'dummy'
	p_unused.fd = fd
	p_unused.flags = open_flags
	p_new.pPreallocatedUnused = p_unused
	rc = fill_in_unix_file(&dummy_vfs, fd, &Sqlite3_file(voidptr(p_new)), path, 0)
	if rc == 0 {
		unsafe { *pp_file = p_new }
		return 0
	}
	end_create_proxy:
	robust_close(p_new, fd, 7589)
	sqlite3_free(voidptr(p_new))
	sqlite3_free(voidptr(p_unused))
	return rc
}

@[c:'proxyGetHostID']
fn proxy_get_host_id(p_host_id &u8, p_error &int) int {
	C.memset(voidptr(p_host_id), 0, u64(16))
	timeout := C.timespec{
		tv_sec: i64(1)
		tv_nsec: i64(0)
	}

	if C.gethostuuid(p_host_id, &timeout) {
		err := (unsafe { *C.__error() })
		if p_error {
			unsafe { *p_error = err }
		}
		return 10
	}
	return 0
}

@[c:'proxyBreakConchLock']
fn proxy_break_conch_lock(p_file &UnixFile, my_host_id &u8) int {
	p_ctx := &ProxyLockingContext(p_file.lockingContext)
	conch_file := p_ctx.conchFile
	t_path := [1024]i8{}
	buf := [1041]i8{}
	c_path := p_ctx.conchFilePath
	read_len := usize(0)
	path_len := usize(0)
	errmsg := [i8(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0]
	fd := -1
	rc := -1

	path_len = C.strlcpy(unsafe { &i8(&t_path[0]) }, c_path, u64(1024))
	if path_len > usize(1024) || path_len < usize(6) || (C.strlcpy(unsafe { &t_path[0] + (path_len - usize(5)) }, c'break', u64(6)) != u64(5)) {
		sqlite3_snprintf(int(sizeof([64]i8)), unsafe { &i8(&errmsg[0]) }, c'path error (len %d)', int(path_len))
		unsafe { goto end_breaklock
		 }
	}
	read_len = usize(c2v_fnptr_666e2028696e742c20766f69647074722c207573697a652c2069363429206973697a65(voidptr(aSyscall[9].pCurrent))(conch_file.h, voidptr(unsafe { &buf[0] }), usize((1 + 16 + 1024)), i64(0)))
	if read_len < usize((1 + 16)) {
		sqlite3_snprintf(int(sizeof([64]i8)), unsafe { &i8(&errmsg[0]) }, c'read error (len %d)', int(read_len))
		unsafe { goto end_breaklock
		 }
	}
	fd = robust_open(unsafe { &i8(&t_path[0]) }, (2 | 512 | 2048 | 256), u32(0))
	if fd < 0 {
		sqlite3_snprintf(int(sizeof([64]i8)), unsafe { &i8(&errmsg[0]) }, c'create failed (%d)', (unsafe { *C.__error() }))
		unsafe { goto end_breaklock
		 }
	}
	if c2v_fnptr_666e2028696e742c20766f69647074722c207573697a652c2069363429206973697a65(voidptr(aSyscall[12].pCurrent))(fd, voidptr(unsafe { &buf[0] }), read_len, i64(0)) != isize(read_len) {
		sqlite3_snprintf(int(sizeof([64]i8)), unsafe { &i8(&errmsg[0]) }, c'write failed (%d)', (unsafe { *C.__error() }))
		unsafe { goto end_breaklock
		 }
	}
	if C.rename(unsafe { &i8(&t_path[0]) }, c_path) {
		sqlite3_snprintf(int(sizeof([64]i8)), unsafe { &i8(&errmsg[0]) }, c'rename failed (%d)', (unsafe { *C.__error() }))
		unsafe { goto end_breaklock
		 }
	}
	rc = 0
	C.fprintf(C.stderr, c'broke stale lock on %s\n', c_path)
	robust_close(p_file, conch_file.h, 7692)
	conch_file.h = fd
	conch_file.openFlags = 2 | 512
	end_breaklock:
	if rc {
		if fd >= 0 {
			c2v_fnptr_666e20282669382920696e74(voidptr(aSyscall[16].pCurrent))(unsafe { &i8(&t_path[0]) })
			robust_close(p_file, fd, 7700)
		}
		C.fprintf(C.stderr, c'failed to break stale lock on %s, %s\n', c_path, &errmsg[0])
	}
	return rc
}

@[c:'proxyConchLock']
fn proxy_conch_lock(p_file &UnixFile, my_host_id &u8, lock_type int) int {
	p_ctx := &ProxyLockingContext(p_file.lockingContext)
	conch_file := p_ctx.conchFile
	rc := 0
	n_tries := 0
	conch_mod_time := C.timespec{}
	C.memset(voidptr(&conch_mod_time), 0, sizeof(conch_mod_time))
	for {
		rc = conch_file.pMethod.xLock(&Sqlite3_file(voidptr(conch_file)), lock_type)
		n_tries++
		if rc == 5 {
			buf := C.stat{}
			if c2v_fnptr_666e2028696e742c2026432e737461742920696e74(voidptr(aSyscall[5].pCurrent))(conch_file.h, &buf) {
				store_last_errno(p_file, (unsafe { *C.__error() }))
				return 10 | (15 << 8)
			}
			if n_tries == 1 {
				conch_mod_time = buf.st_mtimespec
				unix_sleep(unsafe { nil }, 500000)
				unsafe { goto c2v_do_next_24
				 }
			}
			if conch_mod_time.tv_sec != buf.st_mtimespec.tv_sec || conch_mod_time.tv_nsec != buf.st_mtimespec.tv_nsec {
				return 5
			}
			if n_tries == 2 {
				t_buf := [1041]i8{}
				len := int(c2v_fnptr_666e2028696e742c20766f69647074722c207573697a652c2069363429206973697a65(voidptr(aSyscall[9].pCurrent))(conch_file.h, voidptr(unsafe { &t_buf[0] }), usize((1 + 16 + 1024)), i64(0)))
				if len < 0 {
					store_last_errno(p_file, (unsafe { *C.__error() }))
					return 10 | (15 << 8)
				}
				if len > (1 + 16) && int(t_buf[0]) == int(i8(2)) {
					if 0 != C.memcmp(voidptr(unsafe { &t_buf[0] + 1 }), voidptr(my_host_id), u64(16)) {
						return 5
					}
				} else {
					return 5
				}
				unix_sleep(unsafe { nil }, 10000000)
				unsafe { goto c2v_do_next_24
				 }
			}
			if 0 == proxy_break_conch_lock(p_file, my_host_id) {
				rc = 0
				if lock_type == 4 {
					rc = conch_file.pMethod.xLock(&Sqlite3_file(voidptr(conch_file)), 1)
				}
				if !rc {
					rc = conch_file.pMethod.xLock(&Sqlite3_file(voidptr(conch_file)), lock_type)
				}
			}
		}
		c2v_do_next_24:
		if !(rc == 5 && n_tries < 3) {
			break
		}
	}
	return rc
}

@[c:'proxyTakeConch']
fn proxy_take_conch(p_file &UnixFile) int {
	p_ctx := &ProxyLockingContext(p_file.lockingContext)
	if p_ctx.conchHeld != 0 {
		return 0
	} else {
		conch_file := p_ctx.conchFile
		my_host_id := [16]u8{}
		p_error := 0
		read_buf := [1041]i8{}
		lock_path := [1024]i8{}
		temp_lock_path := unsafe { &i8(nil) }
		rc := 0
		create_conch := 0
		host_id_match := 0
		read_len := 0
		try_old_lock_path := 0
		force_new_lock_path := 0
		rc = proxy_get_host_id(&my_host_id[0], &p_error)
		if (rc & 255) == 10 {
			store_last_errno(p_file, p_error)
			unsafe { goto end_takeconch
			 }
		}
		rc = proxy_conch_lock(p_file, &my_host_id[0], 1)
		if rc != 0 {
			unsafe { goto end_takeconch
			 }
		}
		read_len = seek_and_read(&UnixFile(conch_file), Sqlite3_int64(0), voidptr(unsafe { &read_buf[0] }), (1 + 16 + 1024))
		if read_len < 0 {
			store_last_errno(p_file, conch_file.lastErrno)
			rc = (10 | (1 << 8))
			unsafe { goto end_takeconch
			 }
		} else if read_len <= (1 + 16) || int(read_buf[0]) != int(i8(2)) {
			create_conch = 1
		}
		for {
			if !create_conch && !force_new_lock_path {
				host_id_match = !C.memcmp(voidptr(unsafe { &read_buf[0] + 1 }), voidptr(unsafe { &my_host_id[0] }), u64(16))
				if isnil(p_ctx.lockProxyPath) {
					if host_id_match {
						path_len := usize((read_len - (1 + 16)))
						if path_len >= usize(1024) {
							path_len = usize(1024 - 1)
						}
						C.memcpy(voidptr(unsafe { &lock_path[0] }), voidptr(unsafe { &read_buf[0] + (1 + 16) }), path_len)
						lock_path[path_len] = i8(0)
						temp_lock_path = unsafe { &lock_path[0] }
						try_old_lock_path = 1
						unsafe { goto end_takeconch
						 }
					}
				} else if host_id_match && !C.strncmp(p_ctx.lockProxyPath, unsafe { &read_buf[0] + (1 + 16) }, u64(read_len - (1 + 16))) {
					unsafe { goto end_takeconch
					 }
				}
			}
			if (conch_file.openFlags & 2) == 0 {
				rc = 5
				unsafe { goto end_takeconch
				 }
			}
			if isnil(p_ctx.lockProxyPath) {
				proxy_get_lock_path(p_ctx.dbPath, unsafe { &i8(&lock_path[0]) }, usize(1024))
				temp_lock_path = unsafe { &lock_path[0] }
			}
			C.futimes(conch_file.h, (voidptr(0)))
			if host_id_match && !create_conch {
				if !isnil(conch_file.pInode) && conch_file.pInode.nShared > 1 {
					rc = 5
				} else {
					rc = proxy_conch_lock(p_file, &my_host_id[0], 4)
				}
			} else {
				rc = proxy_conch_lock(p_file, &my_host_id[0], 4)
			}
			if rc == 0 {
				write_buffer := [1041]i8{}
				write_size := 0
				write_buffer[0] = i8(2)
				C.memcpy(voidptr(unsafe { &write_buffer[0] + 1 }), voidptr(unsafe { &my_host_id[0] }), u64(16))
				if usize(p_ctx.lockProxyPath) != usize((voidptr(0))) {
					C.strlcpy(unsafe { &write_buffer[0] + (1 + 16) }, p_ctx.lockProxyPath, u64(1024))
				} else {
					C.strlcpy(unsafe { &write_buffer[0] + (1 + 16) }, temp_lock_path, u64(1024))
				}
				write_size = int(u64((1 + 16)) + C.strlen(unsafe { &write_buffer[0] + (1 + 16) }))
				robust_ftruncate(conch_file.h, Sqlite3_int64(write_size))
				rc = unix_write(&Sqlite3_file(voidptr(conch_file)), voidptr(unsafe { &write_buffer[0] }), write_size, Sqlite3_int64(0))
				full_fsync(conch_file.h, 0, 0)
				if rc == 0 && create_conch {
					buf := C.stat{}
					err := c2v_fnptr_666e2028696e742c2026432e737461742920696e74(voidptr(aSyscall[5].pCurrent))(p_file.h, &buf)
					if err == 0 {
						cmode := u32(int(buf.st_mode) & (256 | 128 | 32 | 16 | 4 | 2))
						c2v_fnptr_666e2028696e742c207533322920696e74(voidptr(aSyscall[14].pCurrent))(conch_file.h, cmode)
					}
				}
			}
			conch_file.pMethod.xUnlock(&Sqlite3_file(voidptr(conch_file)), 1)
			end_takeconch:
			if rc == 0 && p_file.openFlags {
				fd := 0
				if p_file.h >= 0 {
					robust_close(p_file, p_file.h, 7953)
				}
				p_file.h = -1
				fd = robust_open(p_ctx.dbPath, p_file.openFlags, u32(0))
				if fd >= 0 {
					p_file.h = fd
				} else {
					rc = sqlite3_cantopen_error(7961)
				}
			}
			if rc == 0 && isnil(p_ctx.lockProxy) {
				path := if temp_lock_path { temp_lock_path } else { p_ctx.lockProxyPath }
				rc = proxy_create_unix_file(path, &&UnixFile(&p_ctx.lockProxy), 1)
				if rc != 0 && rc != 7 && try_old_lock_path {
					force_new_lock_path = 1
					try_old_lock_path = 0
					unsafe { goto c2v_do_next_25
					 }
				}
			}
			if rc == 0 {
				if temp_lock_path {
					p_ctx.lockProxyPath = sqlite3_db_str_dup(unsafe { nil }, temp_lock_path)
					if isnil(p_ctx.lockProxyPath) {
						rc = 7
					}
				}
			}
			if rc == 0 {
				p_ctx.conchHeld = 1
				if usize(p_ctx.lockProxy.pMethod) == usize(&afpIoMethods) {
					afp_ctx := &AfpLockingContext(0)
					afp_ctx = &AfpLockingContext(p_ctx.lockProxy.lockingContext)
					afp_ctx.dbPath = p_ctx.lockProxyPath
				}
			} else {
				conch_file.pMethod.xUnlock(&Sqlite3_file(voidptr(conch_file)), 0)
			}
			return rc
			c2v_do_next_25:
		}
	}
	return 0
}

@[c:'proxyReleaseConch']
fn proxy_release_conch(p_file &UnixFile) int {
	rc := 0
	p_ctx := &ProxyLockingContext(0)
	conch_file := &UnixFile(0)
	p_ctx = &ProxyLockingContext(p_file.lockingContext)
	conch_file = p_ctx.conchFile
	if p_ctx.conchHeld > 0 {
		rc = conch_file.pMethod.xUnlock(&Sqlite3_file(voidptr(conch_file)), 0)
	}
	p_ctx.conchHeld = 0
	return rc
}

@[c:'proxyCreateConchPathname']
fn proxy_create_conch_pathname(db_path &i8, p_conch_path &&u8) int {
	i := 0
	len := int(C.strlen(db_path))
	conch_path := &i8(0)
	conch_path = &i8(sqlite3_malloc64(Sqlite3_uint64(len + 8)))
	unsafe { *p_conch_path = conch_path }
	if usize(conch_path) == usize(0) {
		return 7
	}
	C.memcpy(voidptr(conch_path), voidptr(db_path), u64(len + 1))
	for i = (len - 1); i >= 0; i-- {
		if int(conch_path[i]) == i8(`/`) {
			i++
			break
		}
	}
	conch_path[i] = i8(`.`)
	for i < len {
		conch_path[i + 1] = db_path[i]
		i++
	}
	C.memcpy(voidptr(unsafe { conch_path + (i + 1) }), voidptr(c'-conch'), u64(7))
	return 0
}

@[c:'switchLockProxyPath']
fn switch_lock_proxy_path(p_file &UnixFile, path &i8) int {
	p_ctx := &ProxyLockingContext(p_file.lockingContext)
	old_path := p_ctx.lockProxyPath
	rc := 0
	if int(p_file.eFileLock) != 0 {
		return 5
	}
	if isnil(path) || int(path[0]) == i8(`\0`) || !C.strcmp(path, c':auto:') || (!isnil(old_path) && !C.strncmp(old_path, path, u64(1024))) {
		return 0
	} else {
		lock_proxy := p_ctx.lockProxy
		p_ctx.lockProxy = (voidptr(0))
		p_ctx.conchHeld = 0
		if usize(lock_proxy) != usize((voidptr(0))) {
			rc = lock_proxy.pMethod.xClose(&Sqlite3_file(voidptr(lock_proxy)))
			if rc {
				return rc
			}
			sqlite3_free(voidptr(lock_proxy))
		}
		sqlite3_free(voidptr(old_path))
		p_ctx.lockProxyPath = sqlite3_db_str_dup(unsafe { nil }, path)
	}
	return rc
}

@[c:'proxyGetDbPathForUnixFile']
fn proxy_get_db_path_for_unix_file(p_file &UnixFile, db_path &i8) int {
	if usize(p_file.pMethod) == usize(&afpIoMethods) {
		C.strlcpy(db_path, (&AfpLockingContext(p_file.lockingContext)).dbPath, u64(1024))
	} else if usize(p_file.pMethod) == usize(&dotlockIoMethods) {
		len := int(C.strlen(&i8(p_file.lockingContext)) - C.strlen(c'.lock'))
		C.memcpy(voidptr(db_path), voidptr(&i8(p_file.lockingContext)), u64(len + 1))
	} else {
		C.strlcpy(db_path, &i8(p_file.lockingContext), u64(1024))
	}
	return 0
}

@[c:'proxyTransformUnixFile']
fn proxy_transform_unix_file(p_file &UnixFile, path &i8) int {
	p_ctx := &ProxyLockingContext(0)
	db_path := [1025]i8{}
	lock_path := unsafe { &i8(nil) }
	rc := 0
	if int(p_file.eFileLock) != 0 {
		return 5
	}
	proxy_get_db_path_for_unix_file(p_file, unsafe { &i8(&db_path[0]) })
	if isnil(path) || int(path[0]) == i8(`\0`) || !C.strcmp(path, c':auto:') {
		lock_path = (voidptr(0))
	} else {
		lock_path = &i8(path)
	}
	p_ctx = sqlite3_malloc64(Sqlite3_uint64(sizeof(ProxyLockingContext)))
	if usize(p_ctx) == usize(0) {
		return 7
	}
	C.memset(voidptr(p_ctx), 0, sizeof(ProxyLockingContext))
	rc = proxy_create_conch_pathname(unsafe { &i8(&db_path[0]) }, &&u8(&p_ctx.conchFilePath))
	if rc == 0 {
		rc = proxy_create_unix_file(p_ctx.conchFilePath, &&UnixFile(&p_ctx.conchFile), 0)
		if rc == 14 && ((p_file.openFlags & 2) == 0) {
			fs_info := C.statfs{}
			conch_info := C.stat{}
			go_lockless := 0
			if c2v_fnptr_666e20282669382c2026432e737461742920696e74(voidptr(aSyscall[4].pCurrent))(p_ctx.conchFilePath, &conch_info) == -1 {
				err := (unsafe { *C.__error() })
				if (err == 2) && (c2v_fn_statfs(unsafe { &i8(&db_path[0]) }, &fs_info) != -1) {
					go_lockless = (fs_info.f_flags & u32(1)) == u32(1)
				}
			}
			if go_lockless {
				p_ctx.conchHeld = -1
				rc = 0
			}
		}
	}
	if rc == 0 && !isnil(lock_path) {
		p_ctx.lockProxyPath = sqlite3_db_str_dup(unsafe { nil }, lock_path)
	}
	if rc == 0 {
		p_ctx.dbPath = sqlite3_db_str_dup(unsafe { nil }, unsafe { &i8(&db_path[0]) })
		if usize(p_ctx.dbPath) == usize((voidptr(0))) {
			rc = 7
		}
	}
	if rc == 0 {
		p_ctx.oldLockingContext = p_file.lockingContext
		p_file.lockingContext = p_ctx
		p_ctx.pOldMethod = p_file.pMethod
		p_file.pMethod = &proxyIoMethods
	} else {
		if p_ctx.conchFile {
			p_ctx.conchFile.pMethod.xClose(&Sqlite3_file(voidptr(p_ctx.conchFile)))
			sqlite3_free(voidptr(p_ctx.conchFile))
		}
		sqlite3_db_free(unsafe { nil }, voidptr(p_ctx.lockProxyPath))
		sqlite3_free(voidptr(p_ctx.conchFilePath))
		sqlite3_free(voidptr(p_ctx))
	}
	return rc
}

@[c:'proxyFileControl']
fn proxy_file_control(id &Sqlite3_file, op int, p_arg voidptr) int {
	match op {
		2 {
			p_file := &UnixFile(voidptr(id))
			if usize(p_file.pMethod) == usize(&proxyIoMethods) {
				p_ctx := &ProxyLockingContext(p_file.lockingContext)
				proxy_take_conch(p_file)
				if p_ctx.lockProxyPath {
					mut __c2v_lhs_tmp_66 := unsafe { &&u8(p_arg) }
					unsafe { *__c2v_lhs_tmp_66 = p_ctx.lockProxyPath }
				} else {
					mut __c2v_lhs_tmp_67 := unsafe { &&u8(p_arg) }
					unsafe { *__c2v_lhs_tmp_67 = c':auto: (not held)' }
				}
			} else {
				mut __c2v_lhs_tmp_68 := unsafe { &&u8(p_arg) }
				unsafe { *__c2v_lhs_tmp_68 = (voidptr(0)) }
			}
			return 0
		}
		3 {
			p_file := &UnixFile(voidptr(id))
			rc := 0
			is_proxy_style := int((usize(p_file.pMethod) == usize(&proxyIoMethods)))
			if usize(p_arg) == usize((voidptr(0))) || usize(&i8(p_arg)) == usize(0) {
				if is_proxy_style {
					rc = 1
				} else {
					rc = 0
				}
			} else {
				proxy_path := &i8(p_arg)
				if is_proxy_style {
					p_ctx := &ProxyLockingContext(p_file.lockingContext)
					if !C.strcmp(&i8(p_arg), c':auto:') || (!isnil(p_ctx.lockProxyPath) && !C.strncmp(p_ctx.lockProxyPath, proxy_path, u64(1024))) {
						rc = 0
					} else {
						rc = switch_lock_proxy_path(p_file, proxy_path)
					}
				} else {
					rc = proxy_transform_unix_file(p_file, proxy_path)
				}
			}
			return rc
		}
		else {
		}
	}

	return 1
}

@[c:'proxyCheckReservedLock']
fn proxy_check_reserved_lock(id &Sqlite3_file, p_res_out &int) int {
	c2v_gc_register_thread()
	p_file := &UnixFile(voidptr(id))
	rc := proxy_take_conch(p_file)
	if rc == 0 {
		p_ctx := &ProxyLockingContext(p_file.lockingContext)
		if p_ctx.conchHeld > 0 {
			proxy := p_ctx.lockProxy
			return proxy.pMethod.xCheckReservedLock(&Sqlite3_file(voidptr(proxy)), p_res_out)
		} else {
			p_res_out = 0
		}
	}
	return rc
}

@[c:'proxyLock']
fn proxy_lock(id &Sqlite3_file, e_file_lock int) int {
	c2v_gc_register_thread()
	p_file := &UnixFile(voidptr(id))
	rc := proxy_take_conch(p_file)
	if rc == 0 {
		p_ctx := &ProxyLockingContext(p_file.lockingContext)
		if p_ctx.conchHeld > 0 {
			proxy := p_ctx.lockProxy
			rc = proxy.pMethod.xLock(&Sqlite3_file(voidptr(proxy)), e_file_lock)
			p_file.eFileLock = proxy.eFileLock
		} else {
		}
	}
	return rc
}

@[c:'proxyUnlock']
fn proxy_unlock(id &Sqlite3_file, e_file_lock int) int {
	c2v_gc_register_thread()
	p_file := &UnixFile(voidptr(id))
	rc := proxy_take_conch(p_file)
	if rc == 0 {
		p_ctx := &ProxyLockingContext(p_file.lockingContext)
		if p_ctx.conchHeld > 0 {
			proxy := p_ctx.lockProxy
			rc = proxy.pMethod.xUnlock(&Sqlite3_file(voidptr(proxy)), e_file_lock)
			p_file.eFileLock = proxy.eFileLock
		} else {
		}
	}
	return rc
}

@[c:'proxyClose']
fn proxy_close(id &Sqlite3_file) int {
	c2v_gc_register_thread()
	if id {
		p_file := &UnixFile(voidptr(id))
		p_ctx := &ProxyLockingContext(p_file.lockingContext)
		lock_proxy := p_ctx.lockProxy
		conch_file := p_ctx.conchFile
		rc := 0
		if lock_proxy {
			rc = lock_proxy.pMethod.xUnlock(&Sqlite3_file(voidptr(lock_proxy)), 0)
			if rc {
				return rc
			}
			rc = lock_proxy.pMethod.xClose(&Sqlite3_file(voidptr(lock_proxy)))
			if rc {
				return rc
			}
			sqlite3_free(voidptr(lock_proxy))
			p_ctx.lockProxy = 0
		}
		if conch_file {
			if p_ctx.conchHeld {
				rc = proxy_release_conch(p_file)
				if rc {
					return rc
				}
			}
			rc = conch_file.pMethod.xClose(&Sqlite3_file(voidptr(conch_file)))
			if rc {
				return rc
			}
			sqlite3_free(voidptr(conch_file))
		}
		sqlite3_db_free(unsafe { nil }, voidptr(p_ctx.lockProxyPath))
		sqlite3_free(voidptr(p_ctx.conchFilePath))
		sqlite3_db_free(unsafe { nil }, voidptr(p_ctx.dbPath))
		p_file.lockingContext = p_ctx.oldLockingContext
		p_file.pMethod = p_ctx.pOldMethod
		sqlite3_free(voidptr(p_ctx))
		return p_file.pMethod.xClose(id)
	}
	return 0
}

fn sqlite3_os_init() int {
	if !sqlite3_os_init_a_vfs_inited {
		c2v_static_init := [Sqlite3_vfs{
			iVersion: 3
			szOsFile: int(sizeof(UnixFile))
			mxPathname: 512
			pNext: 0
			zName: c'unix'
			pAppData: voidptr(&autolockIoFinder)
			xOpen: C2vFn_666e20282653716c697465335f7666732c2053716c697465335f66696c656e616d652c202653716c697465335f66696c652c20696e742c2026696e742920696e74(voidptr(unix_open))
			xDelete: unix_delete
			xAccess: unix_access
			xFullPathname: unix_full_pathname
			xDlOpen: unix_dl_open
			xDlError: unix_dl_error
			xDlSym: unix_dl_sym
			xDlClose: unix_dl_close
			xRandomness: unix_randomness
			xSleep: unix_sleep
			xCurrentTime: unix_current_time
			xGetLastError: unix_get_last_error
			xCurrentTimeInt64: unix_current_time_int64
			xSetSystemCall: unix_set_system_call
			xGetSystemCall: unix_get_system_call
			xNextSystemCall: unix_next_system_call
		}, Sqlite3_vfs{
			iVersion: 3
			szOsFile: int(sizeof(UnixFile))
			mxPathname: 512
			pNext: 0
			zName: c'unix-none'
			pAppData: voidptr(&nolockIoFinder)
			xOpen: C2vFn_666e20282653716c697465335f7666732c2053716c697465335f66696c656e616d652c202653716c697465335f66696c652c20696e742c2026696e742920696e74(voidptr(unix_open))
			xDelete: unix_delete
			xAccess: unix_access
			xFullPathname: unix_full_pathname
			xDlOpen: unix_dl_open
			xDlError: unix_dl_error
			xDlSym: unix_dl_sym
			xDlClose: unix_dl_close
			xRandomness: unix_randomness
			xSleep: unix_sleep
			xCurrentTime: unix_current_time
			xGetLastError: unix_get_last_error
			xCurrentTimeInt64: unix_current_time_int64
			xSetSystemCall: unix_set_system_call
			xGetSystemCall: unix_get_system_call
			xNextSystemCall: unix_next_system_call
		}, Sqlite3_vfs{
			iVersion: 3
			szOsFile: int(sizeof(UnixFile))
			mxPathname: 512
			pNext: 0
			zName: c'unix-dotfile'
			pAppData: voidptr(&dotlockIoFinder)
			xOpen: C2vFn_666e20282653716c697465335f7666732c2053716c697465335f66696c656e616d652c202653716c697465335f66696c652c20696e742c2026696e742920696e74(voidptr(unix_open))
			xDelete: unix_delete
			xAccess: unix_access
			xFullPathname: unix_full_pathname
			xDlOpen: unix_dl_open
			xDlError: unix_dl_error
			xDlSym: unix_dl_sym
			xDlClose: unix_dl_close
			xRandomness: unix_randomness
			xSleep: unix_sleep
			xCurrentTime: unix_current_time
			xGetLastError: unix_get_last_error
			xCurrentTimeInt64: unix_current_time_int64
			xSetSystemCall: unix_set_system_call
			xGetSystemCall: unix_get_system_call
			xNextSystemCall: unix_next_system_call
		}, Sqlite3_vfs{
			iVersion: 3
			szOsFile: int(sizeof(UnixFile))
			mxPathname: 512
			pNext: 0
			zName: c'unix-excl'
			pAppData: voidptr(&posixIoFinder)
			xOpen: C2vFn_666e20282653716c697465335f7666732c2053716c697465335f66696c656e616d652c202653716c697465335f66696c652c20696e742c2026696e742920696e74(voidptr(unix_open))
			xDelete: unix_delete
			xAccess: unix_access
			xFullPathname: unix_full_pathname
			xDlOpen: unix_dl_open
			xDlError: unix_dl_error
			xDlSym: unix_dl_sym
			xDlClose: unix_dl_close
			xRandomness: unix_randomness
			xSleep: unix_sleep
			xCurrentTime: unix_current_time
			xGetLastError: unix_get_last_error
			xCurrentTimeInt64: unix_current_time_int64
			xSetSystemCall: unix_set_system_call
			xGetSystemCall: unix_get_system_call
			xNextSystemCall: unix_next_system_call
		}, Sqlite3_vfs{
			iVersion: 3
			szOsFile: int(sizeof(UnixFile))
			mxPathname: 512
			pNext: 0
			zName: c'unix-posix'
			pAppData: voidptr(&posixIoFinder)
			xOpen: C2vFn_666e20282653716c697465335f7666732c2053716c697465335f66696c656e616d652c202653716c697465335f66696c652c20696e742c2026696e742920696e74(voidptr(unix_open))
			xDelete: unix_delete
			xAccess: unix_access
			xFullPathname: unix_full_pathname
			xDlOpen: unix_dl_open
			xDlError: unix_dl_error
			xDlSym: unix_dl_sym
			xDlClose: unix_dl_close
			xRandomness: unix_randomness
			xSleep: unix_sleep
			xCurrentTime: unix_current_time
			xGetLastError: unix_get_last_error
			xCurrentTimeInt64: unix_current_time_int64
			xSetSystemCall: unix_set_system_call
			xGetSystemCall: unix_get_system_call
			xNextSystemCall: unix_next_system_call
		}, Sqlite3_vfs{
			iVersion: 3
			szOsFile: int(sizeof(UnixFile))
			mxPathname: 512
			pNext: 0
			zName: c'unix-flock'
			pAppData: voidptr(&flockIoFinder)
			xOpen: C2vFn_666e20282653716c697465335f7666732c2053716c697465335f66696c656e616d652c202653716c697465335f66696c652c20696e742c2026696e742920696e74(voidptr(unix_open))
			xDelete: unix_delete
			xAccess: unix_access
			xFullPathname: unix_full_pathname
			xDlOpen: unix_dl_open
			xDlError: unix_dl_error
			xDlSym: unix_dl_sym
			xDlClose: unix_dl_close
			xRandomness: unix_randomness
			xSleep: unix_sleep
			xCurrentTime: unix_current_time
			xGetLastError: unix_get_last_error
			xCurrentTimeInt64: unix_current_time_int64
			xSetSystemCall: unix_set_system_call
			xGetSystemCall: unix_get_system_call
			xNextSystemCall: unix_next_system_call
		}, Sqlite3_vfs{
			iVersion: 3
			szOsFile: int(sizeof(UnixFile))
			mxPathname: 512
			pNext: 0
			zName: c'unix-afp'
			pAppData: voidptr(&afpIoFinder)
			xOpen: C2vFn_666e20282653716c697465335f7666732c2053716c697465335f66696c656e616d652c202653716c697465335f66696c652c20696e742c2026696e742920696e74(voidptr(unix_open))
			xDelete: unix_delete
			xAccess: unix_access
			xFullPathname: unix_full_pathname
			xDlOpen: unix_dl_open
			xDlError: unix_dl_error
			xDlSym: unix_dl_sym
			xDlClose: unix_dl_close
			xRandomness: unix_randomness
			xSleep: unix_sleep
			xCurrentTime: unix_current_time
			xGetLastError: unix_get_last_error
			xCurrentTimeInt64: unix_current_time_int64
			xSetSystemCall: unix_set_system_call
			xGetSystemCall: unix_get_system_call
			xNextSystemCall: unix_next_system_call
		}, Sqlite3_vfs{
			iVersion: 3
			szOsFile: int(sizeof(UnixFile))
			mxPathname: 512
			pNext: 0
			zName: c'unix-nfs'
			pAppData: voidptr(&nfsIoFinder)
			xOpen: C2vFn_666e20282653716c697465335f7666732c2053716c697465335f66696c656e616d652c202653716c697465335f66696c652c20696e742c2026696e742920696e74(voidptr(unix_open))
			xDelete: unix_delete
			xAccess: unix_access
			xFullPathname: unix_full_pathname
			xDlOpen: unix_dl_open
			xDlError: unix_dl_error
			xDlSym: unix_dl_sym
			xDlClose: unix_dl_close
			xRandomness: unix_randomness
			xSleep: unix_sleep
			xCurrentTime: unix_current_time
			xGetLastError: unix_get_last_error
			xCurrentTimeInt64: unix_current_time_int64
			xSetSystemCall: unix_set_system_call
			xGetSystemCall: unix_get_system_call
			xNextSystemCall: unix_next_system_call
		}, Sqlite3_vfs{
			iVersion: 3
			szOsFile: int(sizeof(UnixFile))
			mxPathname: 512
			pNext: 0
			zName: c'unix-proxy'
			pAppData: voidptr(&proxyIoFinder)
			xOpen: C2vFn_666e20282653716c697465335f7666732c2053716c697465335f66696c656e616d652c202653716c697465335f66696c652c20696e742c2026696e742920696e74(voidptr(unix_open))
			xDelete: unix_delete
			xAccess: unix_access
			xFullPathname: unix_full_pathname
			xDlOpen: unix_dl_open
			xDlError: unix_dl_error
			xDlSym: unix_dl_sym
			xDlClose: unix_dl_close
			xRandomness: unix_randomness
			xSleep: unix_sleep
			xCurrentTime: unix_current_time
			xGetLastError: unix_get_last_error
			xCurrentTimeInt64: unix_current_time_int64
			xSetSystemCall: unix_set_system_call
			xGetSystemCall: unix_get_system_call
			xNextSystemCall: unix_next_system_call
		}]
		for c2v_i_0, c2v_element_0 in c2v_static_init {
			sqlite3_os_init_a_vfs[c2v_i_0] = c2v_element_0
		}
		sqlite3_os_init_a_vfs_inited = true
	}

	i := u32(0)
	for i = u32(0); u64(i) < 9; i++ {
		sqlite3_vfs_register(unsafe { &sqlite3_os_init_a_vfs[0] + i }, i == u32(0))
	}
	unixBigLock = sqlite3_mutex_alloc_vdup4(11)
	unix_temp_file_init()
	return 0
}

fn sqlite3_os_end() int {
	unixBigLock = 0
	return 0
}
