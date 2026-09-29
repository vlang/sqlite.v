@[translated]
module main

fn C.getenv(&char) &char

fn C.__error() &int

fn C.fabs(f64) f64

fn C.strlen(&i8) usize

fn C.__error() &int

fn C.access(&i8, int) int

fn C.atoi(&i8) int

fn C.close(int) int

fn C.confstr(int, &i8, usize) usize

fn C.dlclose(voidptr) int

fn C.dlerror() &i8

fn C.dlopen(&i8, int) voidptr

fn C.dlsym(voidptr, &i8) voidptr

fn C.fabs(f64) f64

fn C.fchmod(int, u32) int

fn C.fchown(int, u32, u32) int

fn C.fcntl(int, int, ...voidptr) int

fn C.flock(int, int) int

fn C.fprintf(&C.FILE, &i8, ...voidptr) int

fn C.fsctl(&i8, u64, voidptr, u32) int

fn C.fstat(int, &C.stat) int

fn C.fstatfs(int, &C.statfs) int

fn C.fsync(int) int

fn C.ftruncate(int, i64) int

fn C.futimes(int, &C.timeval) int

fn C.getcwd(&i8, usize) &i8

fn C.getenv(&i8) &i8

fn C.geteuid() u32

fn C.gethostuuid(&u8, &C.timespec) int

fn C.getpid() int

fn C.gettimeofday(&C.timeval, voidptr) int

fn C.localtime(&i64) &C.tm

fn C.lstat(&i8, &C.stat) int

fn C.malloc_create_zone(u64, u32) &C.malloc_zone_t

fn C.malloc_default_zone() &C.malloc_zone_t

fn C.malloc_set_zone_name(&C.malloc_zone_t, &i8)

fn C.malloc_size(voidptr) usize

fn C.malloc_zone_free(&C.malloc_zone_t, voidptr)

fn C.malloc_zone_malloc(&C.malloc_zone_t, usize) voidptr

fn C.malloc_zone_realloc(&C.malloc_zone_t, voidptr, usize) voidptr

fn C.memchr(voidptr, int, usize) voidptr

fn C.memcmp(voidptr, voidptr, usize) int

fn C.memcpy(voidptr, voidptr, usize) voidptr

fn C.memmove(voidptr, voidptr, usize) voidptr

fn C.memset(voidptr, int, usize) voidptr

fn C.mkdir(&i8, u32) int

fn C.mmap(voidptr, usize, int, int, int, i64) voidptr

fn C.munmap(voidptr, usize) int

fn C.nanosleep(&C.timespec, &C.timespec) int

fn C.open(&i8, int, ...voidptr) int

fn C.pread(int, voidptr, usize, i64) isize

fn C.pthread_create(&voidptr, &C.pthread_attr_t, fn (voidptr) voidptr, voidptr) int

fn C.pthread_join(voidptr, &voidptr) int

fn C.pthread_mutex_destroy(&C.pthread_mutex_t) int

fn C.pthread_mutex_init(&C.pthread_mutex_t, &C.pthread_mutexattr_t) int

fn C.pthread_mutex_lock(&C.pthread_mutex_t) int

fn C.pthread_mutex_trylock(&C.pthread_mutex_t) int

fn C.pthread_mutex_unlock(&C.pthread_mutex_t) int

fn C.pthread_mutexattr_destroy(&C.pthread_mutexattr_t) int

fn C.pthread_mutexattr_init(&C.pthread_mutexattr_t) int

fn C.pthread_mutexattr_settype(&C.pthread_mutexattr_t, int) int

fn C.pwrite(int, voidptr, usize, i64) isize

fn C.random() i64

fn C.read(int, voidptr, usize) isize

fn C.readlink(&i8, &i8, usize) isize

fn C.rename(&i8, &i8) int

fn C.rmdir(&i8) int

fn C.srandomdev()

fn C.stat(&i8, &C.stat) int

fn C.statfs(&i8, &C.statfs) int

fn C.strchr(&i8, int) &i8

fn C.strcmp(&i8, &i8) int

fn C.strcspn(&i8, &i8) u64

fn C.strlcat(&i8, &i8, usize) u64

fn C.strlcpy(&i8, &i8, usize) u64

fn C.strlen(&i8) u64

fn C.strncmp(&i8, &i8, usize) int

fn C.strrchr(&i8, int) &i8

fn C.strspn(&i8, &i8) u64

fn C.sysconf(int) i64

fn C.sysctlbyname(&i8, voidptr, &usize, voidptr, usize) int

fn C.time(&i64) i64

fn C.unlink(&i8) int

fn C.utimes(&i8, &C.timeval) int

fn C.write(int, voidptr, usize) isize

#include <dlfcn.h>

#include <errno.h>

#include <fcntl.h>

#include <malloc/malloc.h>

#include <math.h>

#include <pthread/pthread.h>

#include <stdio.h>

#include <stdlib.h>

#include <string.h>

#include <sys/mman.h>

#include <sys/mount.h>

#include <sys/param.h>

#include <sys/stat.h>

#include <sys/sysctl.h>

#include <time.h>

#include <unistd.h>

struct C.tm {
pub mut:
	tm_sec    int
	tm_min    int
	tm_hour   int
	tm_mday   int
	tm_mon    int
	tm_year   int
	tm_wday   int
	tm_yday   int
	tm_isdst  int
	tm_gmtoff i64
	tm_zone   &i8
}

struct C.timeval {
pub mut:
	tv_sec  i64
	tv_usec int
}

struct C.timespec {
pub mut:
	tv_sec  i64
	tv_nsec i64
}

struct C.statfs {
pub mut:
	f_bsize       u32
	f_iosize      int
	f_blocks      u64
	f_bfree       u64
	f_bavail      u64
	f_files       u64
	f_ffree       u64
	f_fsid        C.fsid_t
	f_owner       u32
	f_type        u32
	f_flags       u32
	f_fssubtype   u32
	f_fstypename  [16]i8
	f_mntonname   [1024]i8
	f_mntfromname [1024]i8
	f_flags_ext   u32
	f_reserved    [7]u32
}

@[typedef]
struct C.fsid_t {
pub mut:
	val [2]int
}

struct C.stat {
pub mut:
	st_dev           u64
	st_mode          u32
	st_nlink         u16
	st_ino           u64
	st_uid           u32
	st_gid           u32
	st_rdev          u64
	st_atimespec     C.timespec
	st_mtimespec     C.timespec
	st_ctimespec     C.timespec
	st_birthtimespec C.timespec
	st_size          i64
	st_blocks        i64
	st_blksize       int
	st_flags         u32
	st_gen           u32
	st_lspare        int
	st_qspare        [2]i64
}

@[typedef]
struct C.pthread_mutexattr_t {
pub mut:
	__sig    i64
	__opaque [8]i8
}

@[typedef]
struct C.pthread_mutex_t {
pub mut:
	__sig    i64
	__opaque [56]i8
}

@[typedef]
struct C.pthread_attr_t {
pub mut:
	__sig    i64
	__opaque [56]i8
}

@[typedef]
struct C.malloc_zone_t {
pub mut:
	reserved1                       voidptr
	reserved2                       voidptr
	size                            fn (&C.malloc_zone_t, voidptr) usize
	malloc                          fn (&C.malloc_zone_t, usize) voidptr
	calloc                          fn (&C.malloc_zone_t, usize, usize) voidptr
	valloc                          fn (&C.malloc_zone_t, usize) voidptr
	free                            fn (&C.malloc_zone_t, voidptr)
	realloc                         fn (&C.malloc_zone_t, voidptr, usize) voidptr
	destroy                         fn (&C.malloc_zone_t)
	zone_name                       &i8
	batch_malloc                    fn (&C.malloc_zone_t, usize, &voidptr, u32) u32
	batch_free                      fn (&C.malloc_zone_t, &voidptr, u32)
	introspect                      &C.malloc_introspection_t
	version                         u32
	memalign                        fn (&C.malloc_zone_t, usize, usize) voidptr
	free_definite_size              fn (&C.malloc_zone_t, voidptr, usize)
	pressure_relief                 fn (&C.malloc_zone_t, usize) usize
	claimed_address                 fn (&C.malloc_zone_t, voidptr) int
	try_free_default                fn (&C.malloc_zone_t, voidptr)
	malloc_with_options             fn (&C.malloc_zone_t, usize, usize, u64) voidptr
	malloc_type_malloc              fn (&C.malloc_zone_t, usize, u64) voidptr
	malloc_type_calloc              fn (&C.malloc_zone_t, usize, usize, u64) voidptr
	malloc_type_realloc             fn (&C.malloc_zone_t, voidptr, usize, u64) voidptr
	malloc_type_memalign            fn (&C.malloc_zone_t, usize, usize, u64) voidptr
	malloc_type_malloc_with_options fn (&C.malloc_zone_t, usize, usize, u64, u64) voidptr
}

@[typedef]
struct C.malloc_introspection_t {
pub mut:
	enumerator                 fn (u32, voidptr, u32, u64, fn (u32, u64, u64, &voidptr) int, fn (u32, voidptr, u32, &C.vm_range_t, u32)) int
	good_size                  fn (&C.malloc_zone_t, usize) usize
	check                      fn (&C.malloc_zone_t) int
	print                      fn (&C.malloc_zone_t, int)
	log                        fn (&C.malloc_zone_t, voidptr)
	force_lock                 fn (&C.malloc_zone_t)
	force_unlock               fn (&C.malloc_zone_t)
	statistics                 fn (&C.malloc_zone_t, &C.malloc_statistics_t)
	zone_locked                fn (&C.malloc_zone_t) int
	enable_discharge_checking  fn (&C.malloc_zone_t) int
	disable_discharge_checking fn (&C.malloc_zone_t)
	discharge                  fn (&C.malloc_zone_t, voidptr)
	reinit_lock                fn (&C.malloc_zone_t)
	task_statistics            fn (u32, u64, fn (u32, u64, u64, &voidptr) int, &C.malloc_statistics_t)
	zone_type                  u32
}

@[typedef]
struct C.malloc_statistics_t {
pub mut:
	blocks_in_use   u32
	size_in_use     usize
	max_size_in_use usize
	size_allocated  usize
}

@[typedef]
struct C.vm_range_t {
pub mut:
	address u64
	size    u64
}

struct C.flock {
pub mut:
	l_start  i64
	l_len    i64
	l_pid    int
	l_type   i16
	l_whence i16
}

fn C.GC_thread_is_registered() int

fn C.GC_allow_register_threads()

fn C.pthread_key_create(voidptr, voidptr) int

fn C.pthread_setspecific(usize, voidptr) int

__global c2v_gc_thread_key = u64(0)

fn c2v_gc_thread_exit(value voidptr) {
	$if gcboehm ? {
		C.GC_unregister_my_thread()
	}
}

fn c2v_gc_register_thread() {
	$if gcboehm ? {
		if C.GC_thread_is_registered() != 0 {
			return
		}
		mut base := [4]voidptr{}
		if C.GC_get_stack_base(voidptr(&base[0])) != 0 {
			return
		}
		C.GC_register_my_thread(voidptr(&base[0]))
		$if !windows {
			if c2v_gc_thread_key == 0 {
				C.pthread_key_create(voidptr(&c2v_gc_thread_key), voidptr(c2v_gc_thread_exit))
			}
			C.pthread_setspecific(usize(c2v_gc_thread_key), voidptr(1))
		}
	}
}

fn c2v_gc_allow_threads() {
	$if gcboehm ? {
		C.GC_allow_register_threads()
	}
}

@[typedef]
struct C.va_list {}

fn c2v_pointer_postfix[T](storage voidptr, pointer &T, delta isize) &T {
	mut __c2v_lhs_tmp_0 := unsafe { &&T(storage) }
	unsafe { *__c2v_lhs_tmp_0 = pointer + delta }
	old := pointer
	return old
}

fn c2v_pointer_prefix[T](storage voidptr, pointer &T, delta isize) &T {
	updated := unsafe { pointer + delta }
	mut __c2v_lhs_tmp_1 := unsafe { &&T(storage) }
	unsafe { *__c2v_lhs_tmp_1 = updated }
	return updated
}

@[weak]
__global get_digits_a_mx [6]U16
@[weak]
__global get_digits_a_mx_inited bool

fn C.va_start(C.va_list, ...)

fn C.va_end(C.va_list)

fn C.va_copy(C.va_list, C.va_list)

fn C.va_arg(voidptr, voidptr) voidptr

fn c2v_assign[T](target &T, value T) T {
	unsafe {
		*target = value
	}
	return value
}

@[weak]
__global sqlite3_register_date_time_functions_a_date_time_funcs [10]FuncDef
@[weak]
__global sqlite3_register_date_time_functions_a_date_time_funcs_inited bool
@[weak]
__global sqlite3_mem_set_default_default_methods Sqlite3_mem_methods
@[weak]
__global sqlite3_mem_set_default_default_methods_inited bool
@[weak]
__global sqlite3_noop_mutex_s_mutex Sqlite3_mutex_methods
@[weak]
__global sqlite3_noop_mutex_s_mutex_inited bool

fn C.__sync_synchronize()

@[weak]
__global pthread_mutex_alloc_static_mutexes [12]Sqlite3_mutex
@[weak]
__global pthread_mutex_alloc_static_mutexes_inited bool
@[weak]
__global sqlite3_default_mutex_s_mutex Sqlite3_mutex_methods
@[weak]
__global sqlite3_default_mutex_s_mutex_inited bool

@[c: '__atomic_store_n']
fn C.c2v_atomic_store_n__int_int_int_(&int, int, int)

@[c: '__atomic_load_n']
fn C.c2v_atomic_load_n__int_int_int(&int, int) int

@[weak]
__global sqlite3_str_vappendf_z_ord [9]i8
@[weak]
__global sqlite3_str_vappendf_z_ord_inited bool

fn c2v_prefix_add[T](target &T, delta T) T {
	unsafe {
		*target += delta
		return *target
	}
}

@[weak]
__global sqlite3_randomness_chacha20_init [4]u32
@[weak]
__global sqlite3_randomness_chacha20_init_inited bool

struct C2vU128 {
mut:
	lo u64
	hi u64
}

fn c2v_u128(v u64) C2vU128 {
	return C2vU128{
		lo: v
	}
}

fn c2v_i128(v i64) C2vU128 {
	return C2vU128{
		lo: u64(v)
		hi: if v < 0 { max_u64 } else { 0 }
	}
}

fn c2v_u128_add(a C2vU128, b C2vU128) C2vU128 {
	lo := a.lo + b.lo
	return C2vU128{
		lo: lo
		hi: a.hi + b.hi + (if lo < a.lo { u64(1) } else { u64(0) })
	}
}

fn c2v_u128_sub(a C2vU128, b C2vU128) C2vU128 {
	return C2vU128{
		lo: a.lo - b.lo
		hi: a.hi - b.hi - (if a.lo < b.lo { u64(1) } else { u64(0) })
	}
}

fn c2v_mul_64(x u64, y u64) C2vU128 {
	x0 := x & 0xffffffff
	x1 := x >> 32
	y0 := y & 0xffffffff
	y1 := y >> 32
	w0 := x0 * y0
	t := x1 * y0 + (w0 >> 32)
	w1 := (t & 0xffffffff) + x0 * y1
	return C2vU128{
		lo: x * y
		hi: x1 * y1 + (t >> 32) + (w1 >> 32)
	}
}

fn c2v_u128_mul(a C2vU128, b C2vU128) C2vU128 {
	p := c2v_mul_64(a.lo, b.lo)
	return C2vU128{
		lo: p.lo
		hi: p.hi + a.lo * b.hi + a.hi * b.lo
	}
}

fn c2v_u128_and(a C2vU128, b C2vU128) C2vU128 {
	return C2vU128{
		lo: a.lo & b.lo
		hi: a.hi & b.hi
	}
}

fn c2v_u128_or(a C2vU128, b C2vU128) C2vU128 {
	return C2vU128{
		lo: a.lo | b.lo
		hi: a.hi | b.hi
	}
}

fn c2v_u128_xor(a C2vU128, b C2vU128) C2vU128 {
	return C2vU128{
		lo: a.lo ^ b.lo
		hi: a.hi ^ b.hi
	}
}

fn c2v_u128_not(a C2vU128) C2vU128 {
	return C2vU128{
		lo: ~a.lo
		hi: ~a.hi
	}
}

fn c2v_u128_neg(a C2vU128) C2vU128 {
	return c2v_u128_add(c2v_u128_not(a), c2v_u128(1))
}

fn c2v_u128_shl(a C2vU128, n int) C2vU128 {
	s := n & 127
	if s == 0 {
		return a
	}
	if s >= 64 {
		return C2vU128{
			hi: a.lo << (s - 64)
		}
	}
	return C2vU128{
		lo: a.lo << s
		hi: (a.hi << s) | (a.lo >> (64 - s))
	}
}

fn c2v_u128_shr(a C2vU128, n int) C2vU128 {
	s := n & 127
	if s == 0 {
		return a
	}
	if s >= 64 {
		return C2vU128{
			lo: a.hi >> (s - 64)
		}
	}
	return C2vU128{
		lo: (a.lo >> s) | (a.hi << (64 - s))
		hi: a.hi >> s
	}
}

fn c2v_i128_shr(a C2vU128, n int) C2vU128 {
	s := n & 127
	if s == 0 {
		return a
	}
	fill := if i64(a.hi) < 0 { max_u64 } else { u64(0) }
	if s >= 64 {
		return C2vU128{
			lo: u64(i64(a.hi) >> (s - 64))
			hi: fill
		}
	}
	return C2vU128{
		lo: (a.lo >> s) | (a.hi << (64 - s))
		hi: u64(i64(a.hi) >> s)
	}
}

fn c2v_u128_cmp(a C2vU128, b C2vU128) int {
	if a.hi != b.hi {
		return if a.hi < b.hi { -1 } else { 1 }
	}
	if a.lo != b.lo {
		return if a.lo < b.lo { -1 } else { 1 }
	}
	return 0
}

fn c2v_i128_cmp(a C2vU128, b C2vU128) int {
	if a.hi != b.hi {
		return if i64(a.hi) < i64(b.hi) { -1 } else { 1 }
	}
	if a.lo != b.lo {
		return if a.lo < b.lo { -1 } else { 1 }
	}
	return 0
}

fn c2v_u128_is_zero(a C2vU128) bool {
	return a.lo == 0 && a.hi == 0
}

fn c2v_u128_to_f64(a C2vU128) f64 {
	return f64(a.hi) * 18446744073709551616.0 + f64(a.lo)
}

fn c2v_i128_to_f64(a C2vU128) f64 {
	if i64(a.hi) < 0 {
		return -c2v_u128_to_f64(c2v_u128_neg(a))
	}
	return c2v_u128_to_f64(a)
}

@[weak]
__global power_of_ten_a_base [27]U64
@[weak]
__global power_of_ten_a_base_inited bool
@[weak]
__global power_of_ten_a_scale [26]U64
@[weak]
__global power_of_ten_a_scale_inited bool
@[weak]
__global power_of_ten_a_scale_lo [26]u32
@[weak]
__global power_of_ten_a_scale_lo_inited bool

fn C.__builtin_clzll(u64) int

fn C.__builtin_huge_valf() f32

union AnonStruct_37528 {
	a              [21]i8
	forceAlignment U16
}

@[weak]
__global sqlite3_log_est_add_x [32]u8
@[weak]
__global sqlite3_log_est_add_x_inited bool
@[weak]
__global sqlite3_log_est_a [8]LogEst
@[weak]
__global sqlite3_log_est_a_inited bool
@[weak]
__global find_element_with_hash_null_element HashElem
@[weak]
__global find_element_with_hash_null_element_inited bool
@[weak]
__global sqlite3_opcode_name_az_name [192]&i8
@[weak]
__global sqlite3_opcode_name_az_name_inited bool

fn c2v_fn_stat(a0 &i8, a1 &C.stat) int {
	return C.stat(a0, a1)
}

fn c2v_fnptr_666e20282920753332(p voidptr) C2vFn_666e20282920753332 {
	return C2vFn_666e20282920753332(p)
}

fn c2v_fnptr_666e2028696e742c207533322c207533322920696e74(p voidptr) C2vFn_666e2028696e742c207533322c207533322920696e74 {
	return C2vFn_666e2028696e742c207533322c207533322920696e74(p)
}

fn c2v_fncall_666e2028696e742c207533322c207533322920696e74(p voidptr, a0 int, a1 u32, a2 u32) int {
	f := C2vFn_666e2028696e742c207533322c207533322920696e74(p)
	return f(a0, a1, a2)
}

fn c2v_fnptr_666e20282669382c20696e742c20696e742920696e74(p voidptr) C2vFn_666e20282669382c20696e742c20696e742920696e74 {
	return C2vFn_666e20282669382c20696e742c20696e742920696e74(p)
}

fn c2v_fnptr_666e20282669382920696e74(p voidptr) C2vFn_666e20282669382920696e74 {
	return C2vFn_666e20282669382920696e74(p)
}

fn c2v_fnptr_666e2028696e742920696e74(p voidptr) C2vFn_666e2028696e742920696e74 {
	return C2vFn_666e2028696e742920696e74(p)
}

fn c2v_fnptr_666e2028696e742c2026432e737461742920696e74(p voidptr) C2vFn_666e2028696e742c2026432e737461742920696e74 {
	return C2vFn_666e2028696e742c2026432e737461742920696e74(p)
}

fn c2v_fnptr_666e2028696e742c207533322920696e74(p voidptr) C2vFn_666e2028696e742c207533322920696e74 {
	return C2vFn_666e2028696e742c207533322920696e74(p)
}

fn c2v_fnptr_666e2028696e742c206936342920696e74(p voidptr) C2vFn_666e2028696e742c206936342920696e74 {
	return C2vFn_666e2028696e742c206936342920696e74(p)
}

fn c2v_fnptr_666e2028696e742c20766f69647074722c207573697a6529206973697a65(p voidptr) C2vFn_666e2028696e742c20766f69647074722c207573697a6529206973697a65 {
	return C2vFn_666e2028696e742c20766f69647074722c207573697a6529206973697a65(p)
}

fn c2v_fnptr_666e20282669382c2026432e737461742920696e74(p voidptr) C2vFn_666e20282669382c2026432e737461742920696e74 {
	return C2vFn_666e20282669382c2026432e737461742920696e74(p)
}

fn c2v_fncall_666e20282669382c2026432e737461742920696e74(p voidptr, a0 &i8, a1 &C.stat) int {
	f := C2vFn_666e20282669382c2026432e737461742920696e74(p)
	return f(a0, a1)
}

#flag '-DC2V_VCALL_696e74282a2928696e742c696e742c2e2e2e29(p,...)=((int(*)(int,int,...))(p))(__VA_ARGS__)'

fn C.C2V_VCALL_696e74282a2928696e742c696e742c2e2e2e29(voidptr, ...) int

fn c2v_fnptr_666e20282669382c20696e742920696e74(p voidptr) C2vFn_666e20282669382c20696e742920696e74 {
	return C2vFn_666e20282669382c20696e742920696e74(p)
}

fn c2v_fnptr_666e20282669382c207533322920696e74(p voidptr) C2vFn_666e20282669382c207533322920696e74 {
	return C2vFn_666e20282669382c207533322920696e74(p)
}

fn c2v_fn_flock(a0 int, a1 int) int {
	return C.flock(a0, a1)
}

fn c2v_fnptr_666e2028696e742c20766f69647074722c207573697a652c2069363429206973697a65(p voidptr) C2vFn_666e2028696e742c20766f69647074722c207573697a652c2069363429206973697a65 {
	return C2vFn_666e2028696e742c20766f69647074722c207573697a652c2069363429206973697a65(p)
}

fn c2v_fnptr_666e20282669382c2026696e742920696e74(p voidptr) C2vFn_666e20282669382c2026696e742920696e74 {
	return C2vFn_666e20282669382c2026696e742920696e74(p)
}

fn c2v_fnptr_666e20282920696e74(p voidptr) C2vFn_666e20282920696e74 {
	return C2vFn_666e20282920696e74(p)
}

fn c2v_fnptr_666e2028766f69647074722c207573697a652920696e74(p voidptr) C2vFn_666e2028766f69647074722c207573697a652920696e74 {
	return C2vFn_666e2028766f69647074722c207573697a652920696e74(p)
}

fn c2v_fnptr_666e2028766f69647074722c207573697a652c20696e742c20696e742c20696e742c206936342920766f6964707472(p voidptr) C2vFn_666e2028766f69647074722c207573697a652c20696e742c20696e742c20696e742c206936342920766f6964707472 {
	return C2vFn_666e2028766f69647074722c207573697a652c20696e742c20696e742c20696e742c206936342920766f6964707472(p)
}

struct Mapping {
	zFilesystem &i8
	pMethods    &Sqlite3_io_methods
}

@[weak]
__global autolock_io_finder_impl_a_map [6]Mapping
@[weak]
__global autolock_io_finder_impl_a_map_inited bool

fn c2v_fn_statfs(a0 &i8, a1 &C.statfs) int {
	return C.statfs(a0, a1)
}

fn c2v_fnptr_666e20282669382c2026556e697846696c6529202653716c697465335f696f5f6d6574686f6473(p voidptr) C2vFn_666e20282669382c2026556e697846696c6529202653716c697465335f696f5f6d6574686f6473 {
	return C2vFn_666e20282669382c2026556e697846696c6529202653716c697465335f696f5f6d6574686f6473(p)
}

fn c2v_fncall_666e20282669382c20696e742920696e74(p voidptr, a0 &i8, a1 int) int {
	f := C2vFn_666e20282669382c20696e742920696e74(p)
	return f(a0, a1)
}

fn c2v_fnptr_666e20282669382c202669382c207573697a6529206973697a65(p voidptr) C2vFn_666e20282669382c202669382c207573697a6529206973697a65 {
	return C2vFn_666e20282669382c202669382c207573697a6529206973697a65(p)
}

fn c2v_fnptr_666e20282669382c207573697a652920266938(p voidptr) C2vFn_666e20282669382c207573697a652920266938 {
	return C2vFn_666e20282669382c207573697a652920266938(p)
}

@[weak]
__global sqlite3_os_init_a_vfs [9]Sqlite3_vfs
@[weak]
__global sqlite3_os_init_a_vfs_inited bool

fn c2v_address_of(address voidptr) voidptr {
	return address
}

@[weak]
__global sqlite3_pc_ache_set_default_default_methods Sqlite3_pcache_methods2
@[weak]
__global sqlite3_pc_ache_set_default_default_methods_inited bool
@[weak]
__global zero_journal_hdr_zero_hdr [28]i8
@[weak]
__global zero_journal_hdr_zero_hdr_inited bool
@[weak]
__global sync_journal_zerobyte U8
@[weak]
__global sync_journal_zerobyte_inited bool
@[weak]
__global sqlite3_pager_filename_z_fake [8]i8
@[weak]
__global sqlite3_pager_filename_z_fake_inited bool

@[c: '__atomic_store_n']
fn C.c2v_atomic_store_n__Ht_slot_Ht_slot_int_(&Ht_slot, Ht_slot, int)

struct Sublist {
	nList int
	aList &Ht_slot
}

@[inline]
fn c2v_at[T](base &T, index isize) &T {
	return unsafe { base + index }
}

@[c: '__atomic_store_n']
fn C.c2v_atomic_store_n__u32_u32_int_(&u32, u32, int)

@[c: '__atomic_load_n']
fn C.c2v_atomic_load_n__u32_int_u32(&u32, int) u32

@[c: '__atomic_load_n']
fn C.c2v_atomic_load_n__Ht_slot_int_Ht_slot(&Ht_slot, int) Ht_slot

@[weak]
__global sqlite3_btree_fake_valid_cursor_fake_cursor U8
@[weak]
__global sqlite3_btree_fake_valid_cursor_fake_cursor_inited bool
@[weak]
__global sqlite3_vdbe_get_op_dummy VdbeOp
@[weak]
__global sqlite3_vdbe_display_p4_encnames [4]&i8
@[weak]
__global sqlite3_vdbe_display_p4_encnames_inited bool
@[weak]
__global vdbe_commit_amj_needed [6]U8
@[weak]
__global vdbe_commit_amj_needed_inited bool
@[weak]
__global sqlite3_vdbe_serial_get_a_flag [2]U16
@[weak]
__global sqlite3_vdbe_serial_get_a_flag_inited bool
@[weak]
__global sqlite3_value_type_a_type [64]U8
@[weak]
__global sqlite3_value_type_a_type_inited bool
@[weak]
__global column_null_value_null_mem Mem
@[weak]
__global column_null_value_null_mem_inited bool
@[weak]
__global vdbe_mem_type_name_az_types [5]&i8
@[weak]
__global vdbe_mem_type_name_az_types_inited bool
@[weak]
__global sqlite3_vdbe_exec_az_type [4]&i8
@[weak]
__global sqlite3_vdbe_exec_az_type_inited bool
@[weak]
__global sqlite3_vdbe_exec_and_logic [9]u8
@[weak]
__global sqlite3_vdbe_exec_and_logic_inited bool
@[weak]
__global sqlite3_vdbe_exec_or_logic [9]u8
@[weak]
__global sqlite3_vdbe_exec_or_logic_inited bool
@[weak]
__global sqlite3_vdbe_exec_a_mask [12]u8
@[weak]
__global sqlite3_vdbe_exec_a_mask_inited bool
@[weak]
__global sqlite3_vdbe_exec_a_flag [2]U16
@[weak]
__global sqlite3_vdbe_exec_a_flag_inited bool
@[weak]
__global sqlite3_blob_open_open_blob [6]VdbeOpList
@[weak]
__global sqlite3_blob_open_open_blob_inited bool
@[weak]
__global vdbe_sorter_compare_int_a_len [10]U8
@[weak]
__global vdbe_sorter_compare_int_a_len_inited bool

union AnonStruct_112889 {
	sSrc     SrcList
	srcSpace [80]U8
}

@[weak]
__global sqlite3_expr_code_target_z_aff [10]i8
@[weak]
__global sqlite3_expr_code_target_z_aff_inited bool
@[weak]
__global sqlite3_alter_functions_a_alter_table_funcs [9]FuncDef
@[weak]
__global sqlite3_alter_functions_a_alter_table_funcs_inited bool

struct AnonStruct_123894 {
	zName &i8
	zCols &i8
}

@[weak]
__global open_stat_table_a_table [3]AnonStruct_123894
@[weak]
__global open_stat_table_a_table_inited bool
@[weak]
__global sqlite3_detach_detach_func_2 FuncDef
@[weak]
__global sqlite3_detach_detach_func_2_inited bool
@[weak]
__global sqlite3_attach_attach_func_2 FuncDef
@[weak]
__global sqlite3_attach_attach_func_2_inited bool
@[weak]
__global sqlite3_start_table_a_code [4]U8
@[weak]
__global sqlite3_start_table_a_code_inited bool
@[weak]
__global sqlite3_start_table_null_row [6]i8
@[weak]
__global sqlite3_start_table_null_row_inited bool
@[weak]
__global create_table_stmt_az_type [6]&i8
@[weak]
__global create_table_stmt_az_type_inited bool
@[weak]
__global sqlite3_default_row_est_a_val [5]LogEst
@[weak]
__global sqlite3_default_row_est_a_val_inited bool
@[weak]
__global sqlite3_savepoint_az [3]&i8
@[weak]
__global sqlite3_savepoint_az_inited bool
@[weak]
__global synth_coll_seq_a_enc [3]U8
@[weak]
__global synth_coll_seq_a_enc_inited bool
@[weak]
__global typeof_func_az_type [5]&i8
@[weak]
__global typeof_func_az_type_inited bool
@[weak]
__global trim_func_len_one [1]u32
@[weak]
__global trim_func_len_one_inited bool
@[weak]
__global trim_func_az_one [1]&u8
@[weak]
__global trim_func_az_one_inited bool
@[weak]
__global sqlite3_register_builtin_functions_a_builtin_func [74]FuncDef
@[weak]
__global sqlite3_register_builtin_functions_a_builtin_func_inited bool
@[weak]
__global sqlite3_autoincrement_begin_auto_inc [12]VdbeOpList
@[weak]
__global sqlite3_autoincrement_begin_auto_inc_inited bool
@[weak]
__global auto_increment_end_auto_inc_end [5]VdbeOpList
@[weak]
__global auto_increment_end_auto_inc_end_inited bool
@[weak]
__global sqlite3_load_extension_vdup11_az_endings [1]&i8
@[weak]
__global sqlite3_load_extension_vdup11_az_endings_inited bool
@[weak]
__global get_safety_level_z_text [25]i8
@[weak]
__global get_safety_level_z_text_inited bool
@[weak]
__global get_safety_level_i_offset [8]U8
@[weak]
__global get_safety_level_i_offset_inited bool
@[weak]
__global get_safety_level_i_length [8]U8
@[weak]
__global get_safety_level_i_length_inited bool
@[weak]
__global get_safety_level_i_value [8]U8
@[weak]
__global get_safety_level_i_value_inited bool
@[weak]
__global sqlite3_journal_modename_az_mode_name [6]&i8
@[weak]
__global sqlite3_journal_modename_az_mode_name_inited bool
@[weak]
__global pragma_funclist_line_az_enc [4]&i8
@[weak]
__global pragma_funclist_line_az_enc_inited bool
@[weak]
__global sqlite3_pragma_get_cache_size [9]VdbeOpList
@[weak]
__global sqlite3_pragma_get_cache_size_inited bool
@[weak]
__global sqlite3_pragma_set_meta6 [5]VdbeOpList
@[weak]
__global sqlite3_pragma_set_meta6_inited bool
@[weak]
__global sqlite3_pragma_a_std_type_mask [6]u8
@[weak]
__global sqlite3_pragma_a_std_type_mask_inited bool
@[weak]
__global sqlite3_pragma_end_code [7]VdbeOpList
@[weak]
__global sqlite3_pragma_end_code_inited bool

struct EncName {
	zName &i8
	enc   U8
}

@[weak]
__global sqlite3_pragma_encnames [9]EncName
@[weak]
__global sqlite3_pragma_encnames_inited bool
@[weak]
__global sqlite3_pragma_set_cookie [2]VdbeOpList
@[weak]
__global sqlite3_pragma_set_cookie_inited bool
@[weak]
__global sqlite3_pragma_read_cookie [3]VdbeOpList
@[weak]
__global sqlite3_pragma_read_cookie_inited bool
@[weak]
__global corrupt_schema_az_alter_type [4]&i8
@[weak]
__global corrupt_schema_az_alter_type_inited bool
@[weak]
__global sqlite3_join_type_z_key_text [34]i8
@[weak]
__global sqlite3_join_type_z_key_text_inited bool

struct AnonStruct_149376 {
	i     U8
	nChar U8
	code  U8
}

@[weak]
__global sqlite3_join_type_a_keyword [7]AnonStruct_149376
@[weak]
__global sqlite3_join_type_a_keyword_inited bool
@[weak]
__global sqlite3_process_join_tk_coalesce Token
@[weak]
__global sqlite3_process_join_tk_coalesce_inited bool

union AnonStruct_159324 {
	sSrc      SrcList
	fromSpace [80]U8
}

@[weak]
__global sqlite3_run_vacuum_a_copy [10]u8
@[weak]
__global sqlite3_run_vacuum_a_copy_inited bool
@[weak]
__global sqlite3_declare_vtab_a_keyword [3]U8
@[weak]
__global sqlite3_declare_vtab_a_keyword_inited bool

fn c2v_assign_voidptr(target &voidptr, value voidptr) voidptr {
	unsafe {
		*target = value
	}
	return value
}

@[weak]
__global sqlite3_vtab_on_conflict_a_map [5]u8
@[weak]
__global sqlite3_vtab_on_conflict_a_map_inited bool
@[weak]
__global sqlite3_where_code_one_loop_start_a_start_op [8]U8
@[weak]
__global sqlite3_where_code_one_loop_start_a_start_op_inited bool
@[weak]
__global sqlite3_where_code_one_loop_start_a_end_op [4]U8
@[weak]
__global sqlite3_where_code_one_loop_start_a_end_op_inited bool
@[weak]
__global sqlite3_where_code_one_loop_start_a_step [2]U8
@[weak]
__global sqlite3_where_code_one_loop_start_a_step_inited bool
@[weak]
__global sqlite3_where_code_one_loop_start_a_start [2]U8
@[weak]
__global sqlite3_where_code_one_loop_start_a_start_inited bool

union AnonStruct_166920 {
	sSrc      SrcList
	fromSpace [80]U8
}

struct AnonStruct_167375 {
	zOp &i8
	eOp u8
}

@[weak]
__global sqlite3_expr_is_like_operator_a_op [4]AnonStruct_167375
@[weak]
__global sqlite3_expr_is_like_operator_a_op_inited bool
@[weak]
__global expr_analyze_ops [2]U8
@[weak]
__global expr_analyze_ops_inited bool
@[weak]
__global sqlite3_window_functions_a_window_funcs [15]FuncDef
@[weak]
__global sqlite3_window_functions_a_window_funcs_inited bool

struct WindowUpdate {
	zFunc    &i8
	eFrmType int
	eStart   int
	eEnd     int
}

@[weak]
__global window_check_value_az_err [5]&i8
@[weak]
__global window_check_value_az_err_inited bool
@[weak]
__global window_check_value_a_op [5]int
@[weak]
__global window_check_value_a_op_inited bool
@[weak]
__global sqlite3_complete_trans [8][8]U8
@[weak]
__global sqlite3_complete_trans_inited bool

type LOGFUNC_t = fn (voidptr, int, &i8)

@[c: '__atomic_store_n']
fn C.c2v_atomic_store_n__voidptr_LOGFUNC_t_int_(&voidptr, LOGFUNC_t, int)

@[c: '__atomic_store_n']
fn C.c2v_atomic_store_n__voidptr_voidptr_int_(&voidptr, voidptr, int)

@[c: '__atomic_store_n']
fn C.c2v_atomic_store_n__U8_U8_int_(&U8, U8, int)

struct AnonStruct_189077 {
	op   int
	mask U64
}

@[weak]
__global sqlite3_db_config_a_flag_op [21]AnonStruct_189077
@[weak]
__global sqlite3_db_config_a_flag_op_inited bool
@[weak]
__global sqlite3_err_str_a_msg [29]&i8
@[weak]
__global sqlite3_err_str_a_msg_inited bool
@[weak]
__global sqlite_default_busy_callback_delays [12]U8
@[weak]
__global sqlite_default_busy_callback_delays_inited bool
@[weak]
__global sqlite_default_busy_callback_totals [12]U8
@[weak]
__global sqlite_default_busy_callback_totals_inited bool
@[weak]
__global sqlite3_errmsg16_out_of_mem [14]U16
@[weak]
__global sqlite3_errmsg16_out_of_mem_inited bool
@[weak]
__global sqlite3_errmsg16_misuse [34]U16
@[weak]
__global sqlite3_errmsg16_misuse_inited bool

@[c: '__atomic_load_n']
fn C.c2v_atomic_load_n__U8_int_U8(&U8, int) U8

struct OpenMode {
	z    &i8
	mode int
}

@[weak]
__global sqlite3_parse_uri_a_cache_mode [3]OpenMode
@[weak]
__global sqlite3_parse_uri_a_cache_mode_inited bool
@[weak]
__global sqlite3_parse_uri_a_open_mode [5]OpenMode
@[weak]
__global sqlite3_parse_uri_a_open_mode_inited bool

type Sqlite3FaultFuncType = fn (int) int

type Void_function = fn ()

type Sqlite3LocaltimeType = fn (voidptr, voidptr) int

@[weak]
__global json_append_control_char_a_special [32]i8
@[weak]
__global json_append_control_char_a_special_inited bool
@[weak]
__global json_blob_overwrite_a_type [8]U8
@[weak]
__global json_blob_overwrite_a_type_inited bool
@[weak]
__global json_create_edit_substructure_empty_object [2]U8
@[weak]
__global json_create_edit_substructure_empty_object_inited bool
@[weak]
__global json_function_arg_to_blob_a_null [1]U8
@[weak]
__global json_function_arg_to_blob_a_null_inited bool
@[weak]
__global json_set_func_az_ins_type [3]&i8
@[weak]
__global json_set_func_az_ins_type_inited bool
@[weak]
__global json_set_func_a_edit_type [3]U8
@[weak]
__global json_set_func_a_edit_type_inited bool
@[weak]
__global json_array_compute_empty_array U8
@[weak]
__global json_array_compute_empty_array_inited bool
@[weak]
__global json_object_compute_empty_object u8
@[weak]
__global json_object_compute_empty_object_inited bool
@[weak]
__global sqlite3_register_json_functions_a_json_func [36]FuncDef
@[weak]
__global sqlite3_register_json_functions_a_json_func_inited bool
@[weak]
__global sqlite3_json_vtab_register_az_module [4]&i8
@[weak]
__global sqlite3_json_vtab_register_az_module_inited bool

type C2vFn_666e20282920753332 = fn () u32

type C2vFn_666e2028696e742c207533322c207533322920696e74 = fn (int, u32, u32) int

type C2vFn_666e20282669382c20696e742c20696e742920696e74 = fn (&i8, int, int) int

type C2vFn_666e20282669382920696e74 = fn (&i8) int

type C2vFn_666e2028696e742920696e74 = fn (int) int

type C2vFn_666e2028696e742c2026432e737461742920696e74 = fn (int, &C.stat) int

type C2vFn_666e2028696e742c207533322920696e74 = fn (int, u32) int

type C2vFn_666e2028696e742c206936342920696e74 = fn (int, i64) int

type C2vFn_666e2028696e742c20766f69647074722c207573697a6529206973697a65 = fn (int, voidptr, usize) isize

type C2vFn_666e20282669382c2026432e737461742920696e74 = fn (&i8, &C.stat) int

type C2vFn_666e20282669382c20696e742920696e74 = fn (&i8, int) int

type C2vFn_666e20282669382c207533322920696e74 = fn (&i8, u32) int

type C2vFn_666e2028696e742c20766f69647074722c207573697a652c2069363429206973697a65 = fn (int, voidptr, usize, i64) isize

type C2vFn_666e20282669382c2026696e742920696e74 = fn (&i8, &int) int

type C2vFn_666e20282920696e74 = fn () int

type C2vFn_666e2028766f69647074722c207573697a652920696e74 = fn (voidptr, usize) int

type C2vFn_666e2028766f69647074722c207573697a652c20696e742c20696e742c20696e742c206936342920766f6964707472 = fn (voidptr, usize, int, int, int, i64) voidptr

type C2vFn_666e20282669382c2026556e697846696c6529202653716c697465335f696f5f6d6574686f6473 = fn (&i8, &UnixFile) &Sqlite3_io_methods

type C2vFn_666e20282669382c202669382c207573697a6529206973697a65 = fn (&i8, &i8, usize) isize

type C2vFn_666e20282669382c207573697a652920266938 = fn (&i8, usize) &i8

type C2vFn_666e202829 = fn ()

type C2vFn_666e2028766f69647074722c20696e742c2026693829 = fn (voidptr, int, &i8)

type C2vFn_666e2028766f69647074722c20766f69647074722920696e74 = fn (voidptr, voidptr) int

type C2vFn_666e2028766f696470747229 = fn (voidptr)

type C2vFn_666e20282653716c697465335f636f6e7465787429 = fn (&Sqlite3_context)

type C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529 = fn (&Sqlite3_context, int, &&Sqlite3_value)

type C2vFn_666e20282653716c697465335f6d757465782920696e74 = fn (&Sqlite3_mutex) int

type C2vFn_666e2028696e742c20696e742c202e2e2e2920696e74 = fn (int, int, ...) int

type C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342920696e74 = fn (&Sqlite3_file, Sqlite3_int64) int

type C2vFn_666e20282653716c697465335f66696c652c202653716c697465335f696e7436342920696e74 = fn (&Sqlite3_file, &Sqlite3_int64) int

type C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20696e742c2026766f69647074722920696e74 = fn (&Sqlite3_file, Sqlite3_int64, int, &voidptr) int

type C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20766f69647074722920696e74 = fn (&Sqlite3_file, Sqlite3_int64, voidptr) int

type C2vFn_666e20282653716c697465335f66696c652c20696e742c20696e742c20696e742c2026766f69647074722920696e74 = fn (&Sqlite3_file, int, int, int, &voidptr) int

type C2vFn_666e2028766f69647074722c202669382920433276466e5f36363665323032383239 = fn (voidptr, &i8) C2vFn_666e202829

type C2vFn_666e20282653716c697465335f7666732c2053716c697465335f66696c656e616d652c202653716c697465335f66696c652c20696e742c2026696e742920696e74 = fn (&Sqlite3_vfs, Sqlite3_filename, &Sqlite3_file, int, &int) int

type C2vFn_666e20282653716c697465335f7666732c202669382c20696e742920696e74 = fn (&Sqlite3_vfs, &i8, int) int

type C2vFn_666e20282653716c697465335f7666732c20266636342920696e74 = fn (&Sqlite3_vfs, &f64) int

type C2vFn_666e20282653716c697465335f7666732c202669382c2053716c697465335f73797363616c6c5f7074722920696e74 = fn (&Sqlite3_vfs, &i8, Sqlite3_syscall_ptr) int

type C2vFn_666e20282653716c697465335f7666732c20266938292053716c697465335f73797363616c6c5f707472 = fn (&Sqlite3_vfs, &i8) Sqlite3_syscall_ptr

type C2vFn_666e20282653716c697465335f7666732c202669382920266938 = fn (&Sqlite3_vfs, &i8) &i8

type C2vFn_666e20282653716c697465335f66696c652c2026696e742920696e74 = fn (&Sqlite3_file, &int) int

type C2vFn_666e20282653716c697465335f66696c652920696e74 = fn (&Sqlite3_file) int

type C2vFn_666e20282653716c697465335f66696c652c20696e742c20696e742c20696e742920696e74 = fn (&Sqlite3_file, int, int, int) int

type C2vFn_666e20282653716c697465335f66696c6529 = fn (&Sqlite3_file)

type C2vFn_666e20282653716c697465335f66696c652c20696e742920696e74 = fn (&Sqlite3_file, int) int

type C2vFn_666e2028766f69647074722c202650674864722920696e74 = fn (voidptr, &PgHdr) int

type C2vFn_666e2028766f69647074722920696e74 = fn (voidptr) int

type C2vFn_666e20282653716c697465335f66696c652c20766f69647074722c20696e742c2053716c697465335f696e7436342920696e74 = fn (&Sqlite3_file, voidptr, int, Sqlite3_int64) int

type C2vFn_666e20282653716c697465335f66696c652c20696e742c20766f69647074722920696e74 = fn (&Sqlite3_file, int, voidptr) int

type C2vFn_666e20282657616c6b65722c202653656c6563742920696e74 = fn (&Walker, &Select) int

type C2vFn_666e2028766f69647074722c20696e742c202669382c202669382c202669382c202669382920696e74 = fn (voidptr, int, &i8, &i8, &i8, &i8) int

type C2vFn_666e20282653716c697465335f73746d742c20696e742c2053716c6974655f696e7436342920696e74 = fn (&Sqlite3_stmt, int, Sqlite_int64) int

type C2vFn_666e20282653716c697465335f73746d742c20696e742920266938 = fn (&Sqlite3_stmt, int) &i8

type C2vFn_666e20282653716c697465335f73746d742c20696e742920766f6964707472 = fn (&Sqlite3_stmt, int) voidptr

type C2vFn_666e20282653716c697465335f73746d742c20696e74292053716c6974655f696e743634 = fn (&Sqlite3_stmt, int) Sqlite_int64

type C2vFn_666e20282653716c697465332c202669382c2053716c697465335f63616c6c6261636b2c20766f69647074722c20262675382920696e74 = fn (&Sqlite3, &i8, Sqlite3_callback, voidptr, &&u8) int

type C2vFn_666e20282653716c69746533292053716c6974655f696e743634 = fn (&Sqlite3) Sqlite_int64

type C2vFn_666e20282653716c697465332c20666e2028766f69647074722c202669382c2053716c6974655f75696e743634292c20766f69647074722920766f6964707472 = fn (&Sqlite3, fn (voidptr, &i8, Sqlite_uint64), voidptr) voidptr

type C2vFn_666e20282653716c697465335f636f6e746578742c2053716c6974655f696e74363429 = fn (&Sqlite3_context, Sqlite_int64)

type C2vFn_666e20282653716c697465332c20666e2028766f69647074722c20696e742c202669382c202669382c2053716c6974655f696e743634292c20766f69647074722920766f6964707472 = fn (&Sqlite3, fn (voidptr, int, &i8, &i8, Sqlite_int64), voidptr) voidptr

type C2vFn_666e20282653716c697465335f76616c7565292053716c6974655f696e743634 = fn (&Sqlite3_value) Sqlite_int64

type C2vFn_666e20282653716c697465332c20666e202826766f69647074722c20696e74292c20766f69647074722920696e74 = fn (&Sqlite3, fn (&voidptr, int), voidptr) int

type C2vFn_666e20282653716c697465332c202669382920266938 = fn (&Sqlite3, &i8) &i8

type C2vFn_666e20282669382c202669382c20696e742920696e74 = fn (&i8, &i8, int) int

type C2vFn_666e20282669382c202669382c2053716c697465335f696e743634292053716c697465335f696e743634 = fn (&i8, &i8, Sqlite3_int64) Sqlite3_int64

type C2vFn_666e20282669382c202669382920266938 = fn (&i8, &i8) &i8

type C2vFn_666e20282653716c697465335f76616c756529202653716c697465335f76616c7565 = fn (&Sqlite3_value) &Sqlite3_value

type C2vFn_666e20282653716c697465335f73746d742920266938 = fn (&Sqlite3_stmt) &i8

type C2vFn_666e20282669382c20696e742920266938 = fn (&i8, int) &i8

type C2vFn_666e20282669382920266938 = fn (&i8) &i8

type C2vFn_666e20282669382c202669382c202669382c20696e742c20262675382920266938 = fn (&i8, &i8, &i8, int, &&u8) &i8

type C2vFn_666e202826693829 = fn (&i8)

type C2vFn_666e20282653716c697465335f73746d742c20696e742c20766f69647074722c20696e742c20696e742c20666e2028766f6964707472292920696e74 = fn (&Sqlite3_stmt, int, voidptr, int, int, fn (voidptr)) int

type C2vFn_666e20282653716c697465335f73746d742c20696e742c20766f69647074722c20696e742c20696e742c20666e2028766f6964707472292c20766f69647074722920696e74 = fn (&Sqlite3_stmt, int, voidptr, int, int, fn (voidptr), voidptr) int

type C2vFn_666e20282653716c697465332c20262675382c202653716c697465335f6170695f726f7574696e65732920696e74 = fn (&Sqlite3, &&u8, &Sqlite3_api_routines) int

type C2vFn_666e20282653716c697465332c20766f69647074722c20696e742c20262675382c20262653716c697465335f767461622c20262675382920696e74 = fn (&Sqlite3, voidptr, int, &&u8, &&Sqlite3_vtab, &&u8) int

type C2vFn_666e20282653716c697465335f767461622920696e74 = fn (&Sqlite3_vtab) int

type C2vFn_666e20282653716c697465335f767461625f637572736f722c202653716c697465335f696e7436342920696e74 = fn (&Sqlite3_vtab_cursor, &Sqlite3_int64) int

type C2vFn_666e20282653716c697465335f767461622c20696e742c20262653716c697465335f76616c75652c202653716c697465335f696e7436342920696e74 = fn (&Sqlite3_vtab, int, &&Sqlite3_value, &Sqlite3_int64) int

type C2vFn_666e20282653716c697465335f767461622c20696e742c202669382c2026666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c7565292c2026766f69647074722920696e74 = fn (&Sqlite3_vtab, int, &i8, &fn (&Sqlite3_context, int, &&Sqlite3_value), &voidptr) int

type C2vFn_666e20282653716c697465335f767461622c202669382920696e74 = fn (&Sqlite3_vtab, &i8) int

type C2vFn_666e20282653716c697465335f767461622c20696e742920696e74 = fn (&Sqlite3_vtab, int) int

type C2vFn_666e20282653716c697465335f767461622c202669382c202669382c20696e742c20262675382920696e74 = fn (&Sqlite3_vtab, &i8, &i8, int, &&u8) int

type C2vFn_666e2028766f69647074722c20696e742920696e74 = fn (voidptr, int) int

struct C.CCurHint {}

fn init() {
	c2v_gc_allow_threads()
}
