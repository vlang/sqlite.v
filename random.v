@[translated]
module main

struct Sqlite3PrngType {
	s   [16]u32
	out [64]U8
	n   U8
}

@[weak]
__global sqlite3Prng Sqlite3PrngType

fn chacha_block(out &u32, in_ &u32) {
	i := 0
	x := [16]u32{}
	C.memcpy(voidptr(unsafe { &x[0] }), voidptr(in_), u64(64))
	for i = 0; i < 10; i++ {
		x[0] += x[4]
		x[12] ^= x[0]
		x[12] = ((x[12] << 16) | (x[12] >> (32 - 16)))
		x[8] += x[12]
		x[4] ^= x[8]
		x[4] = ((x[4] << 12) | (x[4] >> (32 - 12)))
		x[0] += x[4]
		x[12] ^= x[0]
		x[12] = ((x[12] << 8) | (x[12] >> (32 - 8)))
		x[8] += x[12]
		x[4] ^= x[8]
		x[4] = ((x[4] << 7) | (x[4] >> (32 - 7)))
		x[1] += x[5]
		x[13] ^= x[1]
		x[13] = ((x[13] << 16) | (x[13] >> (32 - 16)))
		x[9] += x[13]
		x[5] ^= x[9]
		x[5] = ((x[5] << 12) | (x[5] >> (32 - 12)))
		x[1] += x[5]
		x[13] ^= x[1]
		x[13] = ((x[13] << 8) | (x[13] >> (32 - 8)))
		x[9] += x[13]
		x[5] ^= x[9]
		x[5] = ((x[5] << 7) | (x[5] >> (32 - 7)))
		x[2] += x[6]
		x[14] ^= x[2]
		x[14] = ((x[14] << 16) | (x[14] >> (32 - 16)))
		x[10] += x[14]
		x[6] ^= x[10]
		x[6] = ((x[6] << 12) | (x[6] >> (32 - 12)))
		x[2] += x[6]
		x[14] ^= x[2]
		x[14] = ((x[14] << 8) | (x[14] >> (32 - 8)))
		x[10] += x[14]
		x[6] ^= x[10]
		x[6] = ((x[6] << 7) | (x[6] >> (32 - 7)))
		x[3] += x[7]
		x[15] ^= x[3]
		x[15] = ((x[15] << 16) | (x[15] >> (32 - 16)))
		x[11] += x[15]
		x[7] ^= x[11]
		x[7] = ((x[7] << 12) | (x[7] >> (32 - 12)))
		x[3] += x[7]
		x[15] ^= x[3]
		x[15] = ((x[15] << 8) | (x[15] >> (32 - 8)))
		x[11] += x[15]
		x[7] ^= x[11]
		x[7] = ((x[7] << 7) | (x[7] >> (32 - 7)))
		x[0] += x[5]
		x[15] ^= x[0]
		x[15] = ((x[15] << 16) | (x[15] >> (32 - 16)))
		x[10] += x[15]
		x[5] ^= x[10]
		x[5] = ((x[5] << 12) | (x[5] >> (32 - 12)))
		x[0] += x[5]
		x[15] ^= x[0]
		x[15] = ((x[15] << 8) | (x[15] >> (32 - 8)))
		x[10] += x[15]
		x[5] ^= x[10]
		x[5] = ((x[5] << 7) | (x[5] >> (32 - 7)))
		x[1] += x[6]
		x[12] ^= x[1]
		x[12] = ((x[12] << 16) | (x[12] >> (32 - 16)))
		x[11] += x[12]
		x[6] ^= x[11]
		x[6] = ((x[6] << 12) | (x[6] >> (32 - 12)))
		x[1] += x[6]
		x[12] ^= x[1]
		x[12] = ((x[12] << 8) | (x[12] >> (32 - 8)))
		x[11] += x[12]
		x[6] ^= x[11]
		x[6] = ((x[6] << 7) | (x[6] >> (32 - 7)))
		x[2] += x[7]
		x[13] ^= x[2]
		x[13] = ((x[13] << 16) | (x[13] >> (32 - 16)))
		x[8] += x[13]
		x[7] ^= x[8]
		x[7] = ((x[7] << 12) | (x[7] >> (32 - 12)))
		x[2] += x[7]
		x[13] ^= x[2]
		x[13] = ((x[13] << 8) | (x[13] >> (32 - 8)))
		x[8] += x[13]
		x[7] ^= x[8]
		x[7] = ((x[7] << 7) | (x[7] >> (32 - 7)))
		x[3] += x[4]
		x[14] ^= x[3]
		x[14] = ((x[14] << 16) | (x[14] >> (32 - 16)))
		x[9] += x[14]
		x[4] ^= x[9]
		x[4] = ((x[4] << 12) | (x[4] >> (32 - 12)))
		x[3] += x[4]
		x[14] ^= x[3]
		x[14] = ((x[14] << 8) | (x[14] >> (32 - 8)))
		x[9] += x[14]
		x[4] ^= x[9]
		x[4] = ((x[4] << 7) | (x[4] >> (32 - 7)))
	}
	for i = 0; i < 16; i++ {
		out[i] = x[i] + in_[i]
	}
}

fn sqlite3_randomness(n int, p_buf voidptr) {
	c2v_gc_register_thread()
	z_buf := &u8(p_buf)
	mutex := &Sqlite3_mutex(0)
	if sqlite3_initialize() {
		return
	}
	mutex = sqlite3_mutex_alloc_vdup4(5)
	sqlite3_mutex_enter(mutex)
	if n <= 0 || usize(p_buf) == usize(0) {
		sqlite3Prng.s[0] = u32(0)
		sqlite3_mutex_leave(mutex)
		return
	}
	if sqlite3Prng.s[0] == u32(0) {
		p_vfs := sqlite3_vfs_find(unsafe { nil })
		if !sqlite3_randomness_chacha20_init_inited {
			c2v_static_init := [u32(1634760805), u32(857760878), u32(2036477234), u32(1797285236)]!
			for c2v_i_0, c2v_element_0 in c2v_static_init {
				sqlite3_randomness_chacha20_init[c2v_i_0] = c2v_element_0
			}
			sqlite3_randomness_chacha20_init_inited = true
		}

		C.memcpy(voidptr(unsafe { &sqlite3Prng.s[0] + 0 }), voidptr(unsafe { &sqlite3_randomness_chacha20_init[0] }), u64(16))
		if (usize(p_vfs) == usize(0)) {
			C.memset(voidptr(unsafe { &sqlite3Prng.s[0] + 4 }), 0, u64(44))
		} else {
			sqlite3_os_randomness(p_vfs, 44, &i8(voidptr(unsafe { &sqlite3Prng.s[0] + 4 })))
		}
		sqlite3Prng.s[15] = sqlite3Prng.s[12]
		sqlite3Prng.s[12] = u32(0)
		sqlite3Prng.n = U8(0)
	}
	for {
		if n <= int(sqlite3Prng.n) {
			C.memcpy(voidptr(z_buf), voidptr(unsafe { &sqlite3Prng.out[0] + (int(sqlite3Prng.n) - n) }), u64(n))
			sqlite3Prng.n -= n
			break
		}
		if int(sqlite3Prng.n) > 0 {
			C.memcpy(voidptr(z_buf), sqlite3Prng.out, u64(sqlite3Prng.n))
			n -= int(sqlite3Prng.n)
			c2v_pointer_prefix(voidptr(&z_buf), z_buf, isize(int(sqlite3Prng.n)))
		}
		sqlite3Prng.s[12]++
		chacha_block(&u32(voidptr(unsafe { &sqlite3Prng.out[0] })), unsafe { &sqlite3Prng.s[0] })
		sqlite3Prng.n = U8(64)
	}
	sqlite3_mutex_leave(mutex)
}

@[weak]
__global sqlite3SavedPrng Sqlite3PrngType

@[c:'sqlite3PrngSaveState']
fn sqlite3_prng_save_state() {
	C.memcpy(voidptr(&sqlite3SavedPrng), voidptr(&sqlite3Prng), sizeof(sqlite3Prng))
}

@[c:'sqlite3PrngRestoreState']
fn sqlite3_prng_restore_state() {
	C.memcpy(voidptr(&sqlite3Prng), voidptr(&sqlite3SavedPrng), sizeof(sqlite3Prng))
}
