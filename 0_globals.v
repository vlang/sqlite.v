@[translated]
module main

@[markused; weak]
__global sqlite3_version = [i8(51), 46, 53, 51, 46, 52, 0]!
@[weak]
__global sqlite3azCompileOpt = [c'ATOMIC_INTRINSICS=1', c'COMPILER=clang-21.0.0',
	c'DEFAULT_AUTOVACUUM', c'DEFAULT_CACHE_SIZE=-2000', c'DEFAULT_FILE_FORMAT=4',
	c'DEFAULT_JOURNAL_SIZE_LIMIT=-1', c'DEFAULT_MMAP_SIZE=0', c'DEFAULT_PAGE_SIZE=4096',
	c'DEFAULT_PCACHE_INITSZ=20', c'DEFAULT_RECURSIVE_TRIGGERS', c'DEFAULT_SECTOR_SIZE=4096',
	c'DEFAULT_SYNCHRONOUS=2', c'DEFAULT_WAL_AUTOCHECKPOINT=1000', c'DEFAULT_WAL_SYNCHRONOUS=2',
	c'DEFAULT_WORKER_THREADS=0', c'DIRECT_OVERFLOW_READ', c'MALLOC_SOFT_LIMIT=1024',
	c'MAX_ATTACHED=10', c'MAX_COLUMN=2000', c'MAX_COMPOUND_SELECT=500', c'MAX_DEFAULT_PAGE_SIZE=8192',
	c'MAX_EXPR_DEPTH=1000', c'MAX_FUNCTION_ARG=1000', c'MAX_LENGTH=1000000000',
	c'MAX_LIKE_PATTERN_LENGTH=50000', c'MAX_MMAP_SIZE=0x7fff0000', c'MAX_PAGE_COUNT=0xfffffffe',
	c'MAX_PAGE_SIZE=65536', c'MAX_SQL_LENGTH=1000000000', c'MAX_TRIGGER_DEPTH=1000',
	c'MAX_VARIABLE_NUMBER=32766', c'MAX_VDBE_OP=250000000', c'MAX_WORKER_THREADS=8',
	c'MUTEX_PTHREADS', c'SYSTEM_MALLOC', c'TEMP_STORE=1', c'THREADSAFE=1']!
@[weak]
__global sqlite3UpperToLower = [u8(0), u8(1), u8(2), u8(3), u8(4), u8(5), u8(6), u8(7), u8(8), u8(9),
	u8(10), u8(11), u8(12), u8(13), u8(14), u8(15), u8(16), u8(17), u8(18), u8(19), u8(20), u8(21),
	u8(22), u8(23), u8(24), u8(25), u8(26), u8(27), u8(28), u8(29), u8(30), u8(31), u8(32), u8(33),
	u8(34), u8(35), u8(36), u8(37), u8(38), u8(39), u8(40), u8(41), u8(42), u8(43), u8(44), u8(45),
	u8(46), u8(47), u8(48), u8(49), u8(50), u8(51), u8(52), u8(53), u8(54), u8(55), u8(56), u8(57),
	u8(58), u8(59), u8(60), u8(61), u8(62), u8(63), u8(64), u8(97), u8(98), u8(99), u8(100), u8(101),
	u8(102), u8(103), u8(104), u8(105), u8(106), u8(107), u8(108), u8(109), u8(110), u8(111),
	u8(112), u8(113), u8(114), u8(115), u8(116), u8(117), u8(118), u8(119), u8(120), u8(121),
	u8(122), u8(91), u8(92), u8(93), u8(94), u8(95), u8(96), u8(97), u8(98), u8(99), u8(100),
	u8(101), u8(102), u8(103), u8(104), u8(105), u8(106), u8(107), u8(108), u8(109), u8(110),
	u8(111), u8(112), u8(113), u8(114), u8(115), u8(116), u8(117), u8(118), u8(119), u8(120),
	u8(121), u8(122), u8(123), u8(124), u8(125), u8(126), u8(127), u8(128), u8(129), u8(130),
	u8(131), u8(132), u8(133), u8(134), u8(135), u8(136), u8(137), u8(138), u8(139), u8(140),
	u8(141), u8(142), u8(143), u8(144), u8(145), u8(146), u8(147), u8(148), u8(149), u8(150),
	u8(151), u8(152), u8(153), u8(154), u8(155), u8(156), u8(157), u8(158), u8(159), u8(160),
	u8(161), u8(162), u8(163), u8(164), u8(165), u8(166), u8(167), u8(168), u8(169), u8(170),
	u8(171), u8(172), u8(173), u8(174), u8(175), u8(176), u8(177), u8(178), u8(179), u8(180),
	u8(181), u8(182), u8(183), u8(184), u8(185), u8(186), u8(187), u8(188), u8(189), u8(190),
	u8(191), u8(192), u8(193), u8(194), u8(195), u8(196), u8(197), u8(198), u8(199), u8(200),
	u8(201), u8(202), u8(203), u8(204), u8(205), u8(206), u8(207), u8(208), u8(209), u8(210),
	u8(211), u8(212), u8(213), u8(214), u8(215), u8(216), u8(217), u8(218), u8(219), u8(220),
	u8(221), u8(222), u8(223), u8(224), u8(225), u8(226), u8(227), u8(228), u8(229), u8(230),
	u8(231), u8(232), u8(233), u8(234), u8(235), u8(236), u8(237), u8(238), u8(239), u8(240),
	u8(241), u8(242), u8(243), u8(244), u8(245), u8(246), u8(247), u8(248), u8(249), u8(250),
	u8(251), u8(252), u8(253), u8(254), u8(255), u8(1), u8(0), u8(0), u8(1), u8(1), u8(0), u8(0),
	u8(1), u8(0), u8(1), u8(0), u8(1), u8(1), u8(0), u8(1), u8(0), u8(0), u8(1)]!
@[weak]
__global sqlite3aLTb = unsafe { &sqlite3UpperToLower[0] + (256 - 53) }
@[weak]
__global sqlite3aEQb = unsafe { &sqlite3UpperToLower[0] + (256 + 6 - 53) }
@[weak]
__global sqlite3aGTb = unsafe { &sqlite3UpperToLower[0] + (256 + 12 - 53) }
@[weak]
__global sqlite3CtypeMap = [u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(1),
	u8(1), u8(1), u8(1), u8(1), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0),
	u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(1), u8(0), u8(128), u8(0), u8(64),
	u8(0), u8(0), u8(128), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(12), u8(12),
	u8(12), u8(12), u8(12), u8(12), u8(12), u8(12), u8(12), u8(12), u8(0), u8(0), u8(0), u8(0),
	u8(0), u8(0), u8(0), u8(10), u8(10), u8(10), u8(10), u8(10), u8(10), u8(2), u8(2), u8(2), u8(2),
	u8(2), u8(2), u8(2), u8(2), u8(2), u8(2), u8(2), u8(2), u8(2), u8(2), u8(2), u8(2), u8(2), u8(2),
	u8(2), u8(2), u8(128), u8(0), u8(0), u8(0), u8(64), u8(128), u8(42), u8(42), u8(42), u8(42),
	u8(42), u8(42), u8(34), u8(34), u8(34), u8(34), u8(34), u8(34), u8(34), u8(34), u8(34), u8(34),
	u8(34), u8(34), u8(34), u8(34), u8(34), u8(34), u8(34), u8(34), u8(34), u8(34), u8(0), u8(0),
	u8(0), u8(0), u8(0), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64),
	u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64),
	u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64),
	u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64),
	u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64),
	u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64),
	u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64),
	u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64),
	u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64),
	u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64),
	u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64), u8(64)]!
@[weak]
__global sqlite3Config = Sqlite3Config{
	bMemstat: 1
	bCoreMutex: U8(1)
	bFullMutex: U8(1 == 1)
	bOpenUri: U8(0)
	bUseCis: U8(1)
	bSmallMalloc: U8(0)
	bExtraSchemaChecks: U8(1)
	mxStrlen: 2147483646
	neverCorrupt: 0
	szLookaside: 1200
	nLookaside: 40
	nStmtSpill: (64 * 1024)
	m: Sqlite3_mem_methods{}
	mutex: Sqlite3_mutex_methods{}
	pcache2: Sqlite3_pcache_methods2{}
	pHeap: voidptr(0)
	nHeap: 0
	mnReq: 0
	mxReq: 0
	szMmap: Sqlite3_int64(0)
	mxMmap: Sqlite3_int64(2147418112)
	pPage: voidptr(0)
	szPage: 0
	nPage: 20
	mxParserStack: 0
	sharedCacheEnabled: 0
	szPma: u32(250)
	isInit: 0
	inProgress: 0
	isMutexInit: 0
	isMallocInit: 0
	isPCacheInit: 0
	nRefInitMutex: 0
	pInitMutex: 0
	xLog: C2vFn_666e2028766f69647074722c20696e742c2026693829(voidptr(0))
	pLogArg: 0
	mxMemdbSize: Sqlite3_int64(1073741824)
	xTestCallback: C2vFn_666e2028696e742920696e74(voidptr(0))
	bLocaltimeFault: 0
	xAltLocaltime: C2vFn_666e2028766f69647074722c20766f69647074722920696e74(voidptr(0))
	iOnceResetThreshold: 2147483646
	szSorterRef: u32(2147483647)
	iPrngSeed: u32(0)
}
@[weak]
__global sqlite3PendingByte = int(1073741824)
@[weak]
__global sqlite3TreeTrace = u32(0)

@[export: 'sqlite3OpcodeProperty']
const sqlite3_opcode_property = [u8(0), u8(0), u8(0), u8(0), u8(16), u8(0), u8(65), u8(0), u8(129),
	u8(1), u8(1), u8(129), u8(131), u8(131), u8(1), u8(1), u8(3), u8(3), u8(1), u8(18), u8(1),
	u8(201), u8(201), u8(201), u8(201), u8(1), u8(73), u8(73), u8(73), u8(73), u8(201), u8(73),
	u8(193), u8(1), u8(65), u8(65), u8(193), u8(1), u8(1), u8(65), u8(65), u8(65), u8(65), u8(38),
	u8(38), u8(65), u8(65), u8(9), u8(35), u8(11), u8(129), u8(3), u8(3), u8(11), u8(11), u8(11),
	u8(11), u8(11), u8(11), u8(1), u8(1), u8(3), u8(3), u8(3), u8(1), u8(65), u8(1), u8(0), u8(0),
	u8(2), u8(2), u8(8), u8(0), u8(16), u8(16), u8(16), u8(0), u8(16), u8(0), u8(16), u8(16), u8(0),
	u8(0), u8(16), u8(16), u8(0), u8(0), u8(0), u8(2), u8(2), u8(2), u8(0), u8(0), u8(18), u8(30),
	u8(32), u8(64), u8(0), u8(0), u8(0), u8(16), u8(16), u8(0), u8(38), u8(38), u8(38), u8(38),
	u8(38), u8(38), u8(38), u8(38), u8(38), u8(38), u8(64), u8(64), u8(18), u8(0), u8(64), u8(16),
	u8(64), u8(64), u8(0), u8(0), u8(0), u8(64), u8(0), u8(64), u8(64), u8(16), u8(16), u8(0), u8(0),
	u8(0), u8(0), u8(0), u8(64), u8(0), u8(80), u8(0), u8(64), u8(4), u8(4), u8(0), u8(64), u8(80),
	u8(64), u8(16), u8(0), u8(0), u8(16), u8(0), u8(0), u8(0), u8(0), u8(16), u8(0), u8(0), u8(0),
	u8(6), u8(16), u8(0), u8(4), u8(26), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0),
	u8(0), u8(0), u8(0), u8(0), u8(64), u8(16), u8(80), u8(64), u8(0), u8(16), u8(16), u8(2), u8(18),
	u8(18), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0)]!

@[weak]
__global sqlite3StrBINARY = [i8(66), 73, 78, 65, 82, 89, 0]!

@[export: 'sqlite3StdTypeLen']
const sqlite3_std_type_len = [u8(3), u8(4), u8(3), u8(7), u8(4), u8(4)]

@[export: 'sqlite3StdTypeAffinity']
const sqlite3_std_type_affinity = [i8(67), i8(65), i8(68), i8(68), i8(69), i8(66)]

@[weak]
__global sqlite3StdType = [c'ANY', c'BLOB', c'INT', c'INTEGER', c'REAL', c'TEXT']!
@[weak]
__global sqlite3Stat = Sqlite3StatType{}

@[export: 'statMutex']
const stat_mutex = [i8(0), i8(1), i8(1), i8(0), i8(0), i8(0), i8(0), i8(1), i8(0), i8(0)]!

@[weak]
__global aXformType = [AnonStruct_26163{
	nName: U8(6)
	zName: [i8(115), 101, 99, 111, 110, 100, 0]!
	rLimit: f32(4.6427e+14)
	rXform: f32(1.0)
}, AnonStruct_26163{
	nName: U8(6)
	zName: [i8(109), 105, 110, 117, 116, 101, 0]!
	rLimit: f32(7.7379e+12)
	rXform: f32(60.0)
}, AnonStruct_26163{
	nName: U8(4)
	zName: [i8(104), 111, 117, 114, 0, 0, 0]!
	rLimit: f32(1.2897e+11)
	rXform: f32(3600.0)
}, AnonStruct_26163{
	nName: U8(3)
	zName: [i8(100), 97, 121, 0, 0, 0, 0]!
	rLimit: f32(5.373485e+06)
	rXform: f32(86400.0)
}, AnonStruct_26163{
	nName: U8(5)
	zName: [i8(109), 111, 110, 116, 104, 0, 0]!
	rLimit: f32(176546.0)
	rXform: f32(2.592e+06)
}, AnonStruct_26163{
	nName: U8(4)
	zName: [i8(121), 101, 97, 114, 0, 0, 0]!
	rLimit: f32(14713.0)
	rXform: f32(3.1536e+07)
}]
@[weak]
__global vfsList = &Sqlite3_vfs(0)
@[weak]
__global sqlite3Hooks = BenignMallocHooks{}
@[weak]
__global mem0 = Mem0Global{}
@[weak]
__global aDigits = [i8(48), 49, 50, 51, 52, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69, 70, 48, 49,
	50, 51, 52, 53, 54, 55, 56, 57, 97, 98, 99, 100, 101, 102, 0]!
@[weak]
__global aPrefix = [i8(45), 120, 48, 0, 88, 48, 0]!
@[weak]
__global fmtinfo = [Et_info{
	fmttype: i8(`s`)
	base: EtByte(0)
	flags: EtByte(4)
	type_: EtByte(5)
	charset: EtByte(0)
	prefix: EtByte(0)
	iNxt: i8(1)
}, Et_info{
	fmttype: i8(`E`)
	base: EtByte(0)
	flags: EtByte(1)
	type_: EtByte(2)
	charset: EtByte(14)
	prefix: EtByte(0)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`u`)
	base: EtByte(10)
	flags: EtByte(0)
	type_: EtByte(16)
	charset: EtByte(0)
	prefix: EtByte(0)
	iNxt: i8(3)
}, Et_info{
	fmttype: i8(`G`)
	base: EtByte(0)
	flags: EtByte(1)
	type_: EtByte(3)
	charset: EtByte(14)
	prefix: EtByte(0)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`w`)
	base: EtByte(0)
	flags: EtByte(4)
	type_: EtByte(14)
	charset: EtByte(0)
	prefix: EtByte(0)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`x`)
	base: EtByte(16)
	flags: EtByte(0)
	type_: EtByte(0)
	charset: EtByte(16)
	prefix: EtByte(1)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`c`)
	base: EtByte(0)
	flags: EtByte(0)
	type_: EtByte(8)
	charset: EtByte(0)
	prefix: EtByte(0)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`z`)
	base: EtByte(0)
	flags: EtByte(4)
	type_: EtByte(6)
	charset: EtByte(0)
	prefix: EtByte(0)
	iNxt: i8(6)
}, Et_info{
	fmttype: i8(`d`)
	base: EtByte(10)
	flags: EtByte(1)
	type_: EtByte(16)
	charset: EtByte(0)
	prefix: EtByte(0)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`e`)
	base: EtByte(0)
	flags: EtByte(1)
	type_: EtByte(2)
	charset: EtByte(30)
	prefix: EtByte(0)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`f`)
	base: EtByte(0)
	flags: EtByte(1)
	type_: EtByte(1)
	charset: EtByte(0)
	prefix: EtByte(0)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`g`)
	base: EtByte(0)
	flags: EtByte(1)
	type_: EtByte(3)
	charset: EtByte(30)
	prefix: EtByte(0)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`Q`)
	base: EtByte(0)
	flags: EtByte(4)
	type_: EtByte(10)
	charset: EtByte(0)
	prefix: EtByte(0)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`i`)
	base: EtByte(10)
	flags: EtByte(1)
	type_: EtByte(16)
	charset: EtByte(0)
	prefix: EtByte(0)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`%`)
	base: EtByte(0)
	flags: EtByte(0)
	type_: EtByte(7)
	charset: EtByte(0)
	prefix: EtByte(0)
	iNxt: i8(16)
}, Et_info{
	fmttype: i8(`T`)
	base: EtByte(0)
	flags: EtByte(0)
	type_: EtByte(11)
	charset: EtByte(0)
	prefix: EtByte(0)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`S`)
	base: EtByte(0)
	flags: EtByte(0)
	type_: EtByte(12)
	charset: EtByte(0)
	prefix: EtByte(0)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`X`)
	base: EtByte(16)
	flags: EtByte(0)
	type_: EtByte(0)
	charset: EtByte(0)
	prefix: EtByte(4)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`n`)
	base: EtByte(0)
	flags: EtByte(0)
	type_: EtByte(4)
	charset: EtByte(0)
	prefix: EtByte(0)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`o`)
	base: EtByte(8)
	flags: EtByte(0)
	type_: EtByte(0)
	charset: EtByte(0)
	prefix: EtByte(2)
	iNxt: i8(17)
}, Et_info{
	fmttype: i8(`p`)
	base: EtByte(16)
	flags: EtByte(0)
	type_: EtByte(13)
	charset: EtByte(0)
	prefix: EtByte(1)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`q`)
	base: EtByte(0)
	flags: EtByte(4)
	type_: EtByte(9)
	charset: EtByte(0)
	prefix: EtByte(0)
	iNxt: i8(0)
}, Et_info{
	fmttype: i8(`r`)
	base: EtByte(10)
	flags: EtByte(1)
	type_: EtByte(15)
	charset: EtByte(0)
	prefix: EtByte(0)
	iNxt: i8(0)
}]!
@[weak]
__global sqlite3OomStr = Sqlite3_str{
	db: 0
	zText: 0
	nAlloc: u32(0)
	mxAlloc: u32(0)
	nChar: u32(0)
	accError: U8(7)
	printfFlags: U8(0)
}

@[export: 'sqlite3Utf8Trans1']
const sqlite3_utf8_trans1 = [u8(0), u8(1), u8(2), u8(3), u8(4), u8(5), u8(6), u8(7), u8(8), u8(9),
	u8(10), u8(11), u8(12), u8(13), u8(14), u8(15), u8(16), u8(17), u8(18), u8(19), u8(20), u8(21),
	u8(22), u8(23), u8(24), u8(25), u8(26), u8(27), u8(28), u8(29), u8(30), u8(31), u8(0), u8(1),
	u8(2), u8(3), u8(4), u8(5), u8(6), u8(7), u8(8), u8(9), u8(10), u8(11), u8(12), u8(13), u8(14),
	u8(15), u8(0), u8(1), u8(2), u8(3), u8(4), u8(5), u8(6), u8(7), u8(0), u8(1), u8(2), u8(3),
	u8(0), u8(1), u8(0), u8(0)]

@[weak]
__global sqlite3DigitPairs = AnonStruct_37437{
	a: [i8(48), 48, 48, 49, 48, 50, 48, 51, 48, 52, 48, 53, 48, 54, 48, 55, 48, 56, 48, 57, 49,
		48, 49, 49, 49, 50, 49, 51, 49, 52, 49, 53, 49, 54, 49, 55, 49, 56, 49, 57, 50, 48, 50,
		49, 50, 50, 50, 51, 50, 52, 50, 53, 50, 54, 50, 55, 50, 56, 50, 57, 51, 48, 51, 49, 51,
		50, 51, 51, 51, 52, 51, 53, 51, 54, 51, 55, 51, 56, 51, 57, 52, 48, 52, 49, 52, 50, 52,
		51, 52, 52, 52, 53, 52, 54, 52, 55, 52, 56, 52, 57, 53, 48, 53, 49, 53, 50, 53, 51, 53,
		52, 53, 53, 53, 54, 53, 55, 53, 56, 53, 57, 54, 48, 54, 49, 54, 50, 54, 51, 54, 52, 54,
		53, 54, 54, 54, 55, 54, 56, 54, 57, 55, 48, 55, 49, 55, 50, 55, 51, 55, 52, 55, 53, 55,
		54, 55, 55, 55, 56, 55, 57, 56, 48, 56, 49, 56, 50, 56, 51, 56, 52, 56, 53, 56, 54, 56,
		55, 56, 56, 56, 57, 57, 48, 57, 49, 57, 50, 57, 51, 57, 52, 57, 53, 57, 54, 57, 55, 57,
		56, 57, 57, 0]!
}
@[weak]
__global randomnessPid = int(0)
@[weak]
__global aSyscall = [Unix_syscall{
	zName: c'open'
	pCurrent: C2vFn_666e202829(voidptr(posix_open))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'close'
	pCurrent: C2vFn_666e202829(voidptr(C.close))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'access'
	pCurrent: C2vFn_666e202829(voidptr(C.access))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'getcwd'
	pCurrent: C2vFn_666e202829(voidptr(C.getcwd))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'stat'
	pCurrent: C2vFn_666e202829(voidptr(c2v_fn_stat))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'fstat'
	pCurrent: C2vFn_666e202829(voidptr(C.fstat))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'ftruncate'
	pCurrent: C2vFn_666e202829(voidptr(C.ftruncate))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'fcntl'
	pCurrent: C2vFn_666e202829(voidptr(C.fcntl))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'read'
	pCurrent: C2vFn_666e202829(voidptr(C.read))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'pread'
	pCurrent: C2vFn_666e202829(voidptr(C.pread))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'pread64'
	pCurrent: unsafe { Sqlite3_syscall_ptr(nil) }
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'write'
	pCurrent: C2vFn_666e202829(voidptr(C.write))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'pwrite'
	pCurrent: C2vFn_666e202829(voidptr(C.pwrite))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'pwrite64'
	pCurrent: unsafe { Sqlite3_syscall_ptr(nil) }
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'fchmod'
	pCurrent: C2vFn_666e202829(voidptr(C.fchmod))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'fallocate'
	pCurrent: unsafe { Sqlite3_syscall_ptr(nil) }
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'unlink'
	pCurrent: C2vFn_666e202829(voidptr(C.unlink))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'openDirectory'
	pCurrent: C2vFn_666e202829(voidptr(open_directory))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'mkdir'
	pCurrent: C2vFn_666e202829(voidptr(C.mkdir))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'rmdir'
	pCurrent: C2vFn_666e202829(voidptr(C.rmdir))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'fchown'
	pCurrent: C2vFn_666e202829(voidptr(C.fchown))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'geteuid'
	pCurrent: C2vFn_666e202829(voidptr(C.geteuid))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'mmap'
	pCurrent: C2vFn_666e202829(voidptr(C.mmap))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'munmap'
	pCurrent: C2vFn_666e202829(voidptr(C.munmap))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'mremap'
	pCurrent: unsafe { Sqlite3_syscall_ptr(nil) }
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'getpagesize'
	pCurrent: C2vFn_666e202829(voidptr(unix_getpagesize))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'readlink'
	pCurrent: C2vFn_666e202829(voidptr(C.readlink))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'lstat'
	pCurrent: C2vFn_666e202829(voidptr(C.lstat))
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}, Unix_syscall{
	zName: c'ioctl'
	pCurrent: unsafe { Sqlite3_syscall_ptr(nil) }
	pDefault: unsafe { Sqlite3_syscall_ptr(nil) }
}]!
@[weak]
__global unixBigLock = &Sqlite3_mutex(0)
@[weak]
__global inodeList = &UnixInodeInfo(0)
@[weak]
__global posixIoMethods = Sqlite3_io_methods{
	iVersion: 3
	xClose: unix_close
	xRead: unix_read
	xWrite: unix_write
	xTruncate: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342920696e74(voidptr(unix_truncate))
	xSync: unix_sync
	xFileSize: C2vFn_666e20282653716c697465335f66696c652c202653716c697465335f696e7436342920696e74(voidptr(unix_file_size))
	xLock: unix_lock
	xUnlock: unix_unlock
	xCheckReservedLock: unix_check_reserved_lock
	xFileControl: unix_file_control
	xSectorSize: unix_sector_size
	xDeviceCharacteristics: unix_device_characteristics
	xShmMap: unix_shm_map
	xShmLock: unix_shm_lock
	xShmBarrier: unix_shm_barrier
	xShmUnmap: unix_shm_unmap
	xFetch: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20696e742c2026766f69647074722920696e74(voidptr(unix_fetch))
	xUnfetch: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20766f69647074722920696e74(voidptr(unix_unfetch))
}
@[weak]
__global posixIoFinder = C2vFn_666e20282669382c2026556e697846696c6529202653716c697465335f696f5f6d6574686f6473(voidptr(posix_io_finder_impl))
@[weak]
__global nolockIoMethods = Sqlite3_io_methods{
	iVersion: 3
	xClose: nolock_close
	xRead: unix_read
	xWrite: unix_write
	xTruncate: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342920696e74(voidptr(unix_truncate))
	xSync: unix_sync
	xFileSize: C2vFn_666e20282653716c697465335f66696c652c202653716c697465335f696e7436342920696e74(voidptr(unix_file_size))
	xLock: nolock_lock
	xUnlock: nolock_unlock
	xCheckReservedLock: nolock_check_reserved_lock
	xFileControl: unix_file_control
	xSectorSize: unix_sector_size
	xDeviceCharacteristics: unix_device_characteristics
	xShmMap: C2vFn_666e20282653716c697465335f66696c652c20696e742c20696e742c20696e742c2026766f69647074722920696e74(voidptr(0))
	xShmLock: unix_shm_lock
	xShmBarrier: unix_shm_barrier
	xShmUnmap: unix_shm_unmap
	xFetch: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20696e742c2026766f69647074722920696e74(voidptr(unix_fetch))
	xUnfetch: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20766f69647074722920696e74(voidptr(unix_unfetch))
}
@[weak]
__global nolockIoFinder = C2vFn_666e20282669382c2026556e697846696c6529202653716c697465335f696f5f6d6574686f6473(voidptr(nolock_io_finder_impl))
@[weak]
__global dotlockIoMethods = Sqlite3_io_methods{
	iVersion: 1
	xClose: dotlock_close
	xRead: unix_read
	xWrite: unix_write
	xTruncate: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342920696e74(voidptr(unix_truncate))
	xSync: unix_sync
	xFileSize: C2vFn_666e20282653716c697465335f66696c652c202653716c697465335f696e7436342920696e74(voidptr(unix_file_size))
	xLock: dotlock_lock
	xUnlock: dotlock_unlock
	xCheckReservedLock: dotlock_check_reserved_lock
	xFileControl: unix_file_control
	xSectorSize: unix_sector_size
	xDeviceCharacteristics: unix_device_characteristics
	xShmMap: C2vFn_666e20282653716c697465335f66696c652c20696e742c20696e742c20696e742c2026766f69647074722920696e74(voidptr(0))
	xShmLock: unix_shm_lock
	xShmBarrier: unix_shm_barrier
	xShmUnmap: unix_shm_unmap
	xFetch: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20696e742c2026766f69647074722920696e74(voidptr(unix_fetch))
	xUnfetch: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20766f69647074722920696e74(voidptr(unix_unfetch))
}
@[weak]
__global dotlockIoFinder = C2vFn_666e20282669382c2026556e697846696c6529202653716c697465335f696f5f6d6574686f6473(voidptr(dotlock_io_finder_impl))
@[weak]
__global flockIoMethods = Sqlite3_io_methods{
	iVersion: 1
	xClose: flock_close
	xRead: unix_read
	xWrite: unix_write
	xTruncate: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342920696e74(voidptr(unix_truncate))
	xSync: unix_sync
	xFileSize: C2vFn_666e20282653716c697465335f66696c652c202653716c697465335f696e7436342920696e74(voidptr(unix_file_size))
	xLock: flock_lock
	xUnlock: flock_unlock
	xCheckReservedLock: flock_check_reserved_lock
	xFileControl: unix_file_control
	xSectorSize: unix_sector_size
	xDeviceCharacteristics: unix_device_characteristics
	xShmMap: C2vFn_666e20282653716c697465335f66696c652c20696e742c20696e742c20696e742c2026766f69647074722920696e74(voidptr(0))
	xShmLock: unix_shm_lock
	xShmBarrier: unix_shm_barrier
	xShmUnmap: unix_shm_unmap
	xFetch: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20696e742c2026766f69647074722920696e74(voidptr(unix_fetch))
	xUnfetch: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20766f69647074722920696e74(voidptr(unix_unfetch))
}
@[weak]
__global flockIoFinder = C2vFn_666e20282669382c2026556e697846696c6529202653716c697465335f696f5f6d6574686f6473(voidptr(flock_io_finder_impl))
@[weak]
__global afpIoMethods = Sqlite3_io_methods{
	iVersion: 1
	xClose: afp_close
	xRead: unix_read
	xWrite: unix_write
	xTruncate: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342920696e74(voidptr(unix_truncate))
	xSync: unix_sync
	xFileSize: C2vFn_666e20282653716c697465335f66696c652c202653716c697465335f696e7436342920696e74(voidptr(unix_file_size))
	xLock: afp_lock
	xUnlock: afp_unlock
	xCheckReservedLock: afp_check_reserved_lock
	xFileControl: unix_file_control
	xSectorSize: unix_sector_size
	xDeviceCharacteristics: unix_device_characteristics
	xShmMap: C2vFn_666e20282653716c697465335f66696c652c20696e742c20696e742c20696e742c2026766f69647074722920696e74(voidptr(0))
	xShmLock: unix_shm_lock
	xShmBarrier: unix_shm_barrier
	xShmUnmap: unix_shm_unmap
	xFetch: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20696e742c2026766f69647074722920696e74(voidptr(unix_fetch))
	xUnfetch: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20766f69647074722920696e74(voidptr(unix_unfetch))
}
@[weak]
__global afpIoFinder = C2vFn_666e20282669382c2026556e697846696c6529202653716c697465335f696f5f6d6574686f6473(voidptr(afp_io_finder_impl))
@[weak]
__global proxyIoMethods = Sqlite3_io_methods{
	iVersion: 1
	xClose: proxy_close
	xRead: unix_read
	xWrite: unix_write
	xTruncate: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342920696e74(voidptr(unix_truncate))
	xSync: unix_sync
	xFileSize: C2vFn_666e20282653716c697465335f66696c652c202653716c697465335f696e7436342920696e74(voidptr(unix_file_size))
	xLock: proxy_lock
	xUnlock: proxy_unlock
	xCheckReservedLock: proxy_check_reserved_lock
	xFileControl: unix_file_control
	xSectorSize: unix_sector_size
	xDeviceCharacteristics: unix_device_characteristics
	xShmMap: C2vFn_666e20282653716c697465335f66696c652c20696e742c20696e742c20696e742c2026766f69647074722920696e74(voidptr(0))
	xShmLock: unix_shm_lock
	xShmBarrier: unix_shm_barrier
	xShmUnmap: unix_shm_unmap
	xFetch: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20696e742c2026766f69647074722920696e74(voidptr(unix_fetch))
	xUnfetch: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20766f69647074722920696e74(voidptr(unix_unfetch))
}
@[weak]
__global proxyIoFinder = C2vFn_666e20282669382c2026556e697846696c6529202653716c697465335f696f5f6d6574686f6473(voidptr(proxy_io_finder_impl))
@[weak]
__global nfsIoMethods = Sqlite3_io_methods{
	iVersion: 1
	xClose: unix_close
	xRead: unix_read
	xWrite: unix_write
	xTruncate: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342920696e74(voidptr(unix_truncate))
	xSync: unix_sync
	xFileSize: C2vFn_666e20282653716c697465335f66696c652c202653716c697465335f696e7436342920696e74(voidptr(unix_file_size))
	xLock: unix_lock
	xUnlock: nfs_unlock
	xCheckReservedLock: unix_check_reserved_lock
	xFileControl: unix_file_control
	xSectorSize: unix_sector_size
	xDeviceCharacteristics: unix_device_characteristics
	xShmMap: C2vFn_666e20282653716c697465335f66696c652c20696e742c20696e742c20696e742c2026766f69647074722920696e74(voidptr(0))
	xShmLock: unix_shm_lock
	xShmBarrier: unix_shm_barrier
	xShmUnmap: unix_shm_unmap
	xFetch: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20696e742c2026766f69647074722920696e74(voidptr(unix_fetch))
	xUnfetch: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20766f69647074722920696e74(voidptr(unix_unfetch))
}
@[weak]
__global nfsIoFinder = C2vFn_666e20282669382c2026556e697846696c6529202653716c697465335f696f5f6d6574686f6473(voidptr(nfs_io_finder_impl))
@[weak]
__global autolockIoFinder = C2vFn_666e20282669382c2026556e697846696c6529202653716c697465335f696f5f6d6574686f6473(voidptr(autolock_io_finder_impl))
@[weak]
__global azTempDirs = [unsafe { &i8(nil) }, unsafe { &i8(nil) }, c'/var/tmp', c'/usr/tmp', c'/tmp',
	c'.']!
@[weak]
__global memdb_vfs = Sqlite3_vfs{
	iVersion: 2
	szOsFile: 0
	mxPathname: 1024
	pNext: 0
	zName: c'memdb'
	pAppData: 0
	xOpen: C2vFn_666e20282653716c697465335f7666732c2053716c697465335f66696c656e616d652c202653716c697465335f66696c652c20696e742c2026696e742920696e74(voidptr(memdb_open))
	xDelete: C2vFn_666e20282653716c697465335f7666732c202669382c20696e742920696e74(voidptr(0))
	xAccess: memdb_access
	xFullPathname: memdb_full_pathname
	xDlOpen: memdb_dl_open
	xDlError: memdb_dl_error
	xDlSym: memdb_dl_sym
	xDlClose: memdb_dl_close
	xRandomness: memdb_randomness
	xSleep: memdb_sleep
	xCurrentTime: C2vFn_666e20282653716c697465335f7666732c20266636342920696e74(voidptr(0))
	xGetLastError: memdb_get_last_error
	xCurrentTimeInt64: memdb_current_time_int64
	xSetSystemCall: C2vFn_666e20282653716c697465335f7666732c202669382c2053716c697465335f73797363616c6c5f7074722920696e74(voidptr(0))
	xGetSystemCall: C2vFn_666e20282653716c697465335f7666732c20266938292053716c697465335f73797363616c6c5f707472(voidptr(0))
	xNextSystemCall: C2vFn_666e20282653716c697465335f7666732c202669382920266938(voidptr(0))
}
@[weak]
__global memdb_io_methods = Sqlite3_io_methods{
	iVersion: 3
	xClose: memdb_close
	xRead: memdb_read
	xWrite: memdb_write
	xTruncate: memdb_truncate
	xSync: memdb_sync
	xFileSize: memdb_file_size
	xLock: memdb_lock
	xUnlock: memdb_unlock
	xCheckReservedLock: C2vFn_666e20282653716c697465335f66696c652c2026696e742920696e74(voidptr(0))
	xFileControl: memdb_file_control
	xSectorSize: C2vFn_666e20282653716c697465335f66696c652920696e74(voidptr(0))
	xDeviceCharacteristics: memdb_device_characteristics
	xShmMap: C2vFn_666e20282653716c697465335f66696c652c20696e742c20696e742c20696e742c2026766f69647074722920696e74(voidptr(0))
	xShmLock: C2vFn_666e20282653716c697465335f66696c652c20696e742c20696e742c20696e742920696e74(voidptr(0))
	xShmBarrier: C2vFn_666e20282653716c697465335f66696c6529(voidptr(0))
	xShmUnmap: C2vFn_666e20282653716c697465335f66696c652c20696e742920696e74(voidptr(0))
	xFetch: memdb_fetch
	xUnfetch: memdb_unfetch
}
@[weak]
__global aJournalMagic = [u8(217), u8(213), u8(5), u8(249), u8(32), u8(161), u8(99), u8(215)]!
@[weak]
__global zMagicHeader = [i8(83), 81, 76, 105, 116, 101, 32, 102, 111, 114, 109, 97, 116, 32, 51,
	0]!
@[weak]
__global sqlite3SharedCacheList = &BtShared(0)

@[export: 'sqlite3SmallTypeSizes']
const sqlite3_small_type_sizes = [U8(0), U8(1), U8(2), U8(3), U8(4), U8(6), U8(8), U8(8), U8(0),
	U8(0), U8(0), U8(0), U8(0), U8(0), U8(1), U8(1), U8(2), U8(2), U8(3), U8(3), U8(4), U8(4), U8(5),
	U8(5), U8(6), U8(6), U8(7), U8(7), U8(8), U8(8), U8(9), U8(9), U8(10), U8(10), U8(11), U8(11),
	U8(12), U8(12), U8(13), U8(13), U8(14), U8(14), U8(15), U8(15), U8(16), U8(16), U8(17), U8(17),
	U8(18), U8(18), U8(19), U8(19), U8(20), U8(20), U8(21), U8(21), U8(22), U8(22), U8(23), U8(23),
	U8(24), U8(24), U8(25), U8(25), U8(26), U8(26), U8(27), U8(27), U8(28), U8(28), U8(29), U8(29),
	U8(30), U8(30), U8(31), U8(31), U8(32), U8(32), U8(33), U8(33), U8(34), U8(34), U8(35), U8(35),
	U8(36), U8(36), U8(37), U8(37), U8(38), U8(38), U8(39), U8(39), U8(40), U8(40), U8(41), U8(41),
	U8(42), U8(42), U8(43), U8(43), U8(44), U8(44), U8(45), U8(45), U8(46), U8(46), U8(47), U8(47),
	U8(48), U8(48), U8(49), U8(49), U8(50), U8(50), U8(51), U8(51), U8(52), U8(52), U8(53), U8(53),
	U8(54), U8(54), U8(55), U8(55), U8(56), U8(56), U8(57), U8(57)]

@[weak]
__global azExplainColNames8 = [c'addr', c'opcode', c'p1', c'p2', c'p3', c'p4', c'p5', c'comment',
	c'id', c'parent', c'notused', c'detail']!
@[weak]
__global azExplainColNames16data = [U16(`a`), U16(`d`), U16(`d`), U16(`r`), U16(0), U16(`o`),
	U16(`p`), U16(`c`), U16(`o`), U16(`d`), U16(`e`), U16(0), U16(`p`), U16(`1`), U16(0), U16(`p`),
	U16(`2`), U16(0), U16(`p`), U16(`3`), U16(0), U16(`p`), U16(`4`), U16(0), U16(`p`), U16(`5`),
	U16(0), U16(`c`), U16(`o`), U16(`m`), U16(`m`), U16(`e`), U16(`n`), U16(`t`), U16(0), U16(`i`),
	U16(`d`), U16(0), U16(`p`), U16(`a`), U16(`r`), U16(`e`), U16(`n`), U16(`t`), U16(0), U16(`n`),
	U16(`o`), U16(`t`), U16(`u`), U16(`s`), U16(`e`), U16(`d`), U16(0), U16(`d`), U16(`e`), U16(`t`),
	U16(`a`), U16(`i`), U16(`l`), U16(0)]!

@[export: 'iExplainColNames16']
const i_explain_col_names16 = [U8(0), U8(5), U8(12), U8(15), U8(18), U8(21), U8(24), U8(27), U8(35),
	U8(38), U8(45), U8(53)]

@[weak]
__global memJournalMethods = Sqlite3_io_methods{
	iVersion: 1
	xClose: memjrnl_close
	xRead: C2vFn_666e20282653716c697465335f66696c652c20766f69647074722c20696e742c2053716c697465335f696e7436342920696e74(voidptr(memjrnl_read))
	xWrite: C2vFn_666e20282653716c697465335f66696c652c20766f69647074722c20696e742c2053716c697465335f696e7436342920696e74(voidptr(memjrnl_write))
	xTruncate: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342920696e74(voidptr(memjrnl_truncate))
	xSync: memjrnl_sync
	xFileSize: C2vFn_666e20282653716c697465335f66696c652c202653716c697465335f696e7436342920696e74(voidptr(memjrnl_file_size))
	xLock: C2vFn_666e20282653716c697465335f66696c652c20696e742920696e74(voidptr(0))
	xUnlock: C2vFn_666e20282653716c697465335f66696c652c20696e742920696e74(voidptr(0))
	xCheckReservedLock: C2vFn_666e20282653716c697465335f66696c652c2026696e742920696e74(voidptr(0))
	xFileControl: C2vFn_666e20282653716c697465335f66696c652c20696e742c20766f69647074722920696e74(voidptr(0))
	xSectorSize: C2vFn_666e20282653716c697465335f66696c652920696e74(voidptr(0))
	xDeviceCharacteristics: C2vFn_666e20282653716c697465335f66696c652920696e74(voidptr(0))
	xShmMap: C2vFn_666e20282653716c697465335f66696c652c20696e742c20696e742c20696e742c2026766f69647074722920696e74(voidptr(0))
	xShmLock: C2vFn_666e20282653716c697465335f66696c652c20696e742c20696e742c20696e742920696e74(voidptr(0))
	xShmBarrier: C2vFn_666e20282653716c697465335f66696c6529(voidptr(0))
	xShmUnmap: C2vFn_666e20282653716c697465335f66696c652c20696e742920696e74(voidptr(0))
	xFetch: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20696e742c2026766f69647074722920696e74(voidptr(0))
	xUnfetch: C2vFn_666e20282653716c697465335f66696c652c2053716c697465335f696e7436342c20766f69647074722920696e74(voidptr(0))
}

@[export: 'zeroItem']
const zero_item = ExprList_item{}

@[weak]
__global statInitFuncdef = FuncDef{
	nArg: I16(4)
	funcFlags: u32(1)
	pUserData: 0
	pNext: 0
	xSFunc: stat_init
	xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
	xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
	xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
	zName: c'stat_init'
	u: FuncDef_u{}
}
@[weak]
__global statPushFuncdef = FuncDef{
	nArg: I16(2 + 0)
	funcFlags: u32(1)
	pUserData: 0
	pNext: 0
	xSFunc: stat_push
	xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
	xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
	xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
	zName: c'stat_push'
	u: FuncDef_u{}
}
@[weak]
__global statGetFuncdef = FuncDef{
	nArg: I16(1 + 0)
	funcFlags: u32(1)
	pUserData: 0
	pNext: 0
	xSFunc: stat_get
	xFinalize: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
	xValue: C2vFn_666e20282653716c697465335f636f6e7465787429(voidptr(0))
	xInverse: C2vFn_666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c756529(voidptr(0))
	zName: c'stat_get'
	u: FuncDef_u{}
}
@[weak]
__global globInfo = CompareInfo{
	matchAll: U8(`*`)
	matchOne: U8(`?`)
	matchSet: U8(`[`)
	noCase: U8(0)
}
@[weak]
__global likeInfoNorm = CompareInfo{
	matchAll: U8(`%`)
	matchOne: U8(`_`)
	matchSet: U8(0)
	noCase: U8(1)
}
@[weak]
__global likeInfoAlt = CompareInfo{
	matchAll: U8(`%`)
	matchOne: U8(`_`)
	matchSet: U8(0)
	noCase: U8(0)
}

@[export: 'hexdigits']
const hexdigits = [i8(`0`), i8(`1`), i8(`2`), i8(`3`), i8(`4`), i8(`5`), i8(`6`), i8(`7`), i8(`8`),
	i8(`9`), i8(`A`), i8(`B`), i8(`C`), i8(`D`), i8(`E`), i8(`F`)]!

@[weak]
__global sqlite3Apis = Sqlite3_api_routines{
	aggregate_context: sqlite3_aggregate_context
	aggregate_count: sqlite3_aggregate_count
	bind_blob: sqlite3_bind_blob
	bind_double: sqlite3_bind_double
	bind_int: sqlite3_bind_int
	bind_int64: C2vFn_666e20282653716c697465335f73746d742c20696e742c2053716c6974655f696e7436342920696e74(voidptr(sqlite3_bind_int64))
	bind_null: sqlite3_bind_null
	bind_parameter_count: sqlite3_bind_parameter_count
	bind_parameter_index: sqlite3_bind_parameter_index
	bind_parameter_name: sqlite3_bind_parameter_name
	bind_text: sqlite3_bind_text
	bind_text16: sqlite3_bind_text16
	bind_value: sqlite3_bind_value
	busy_handler: sqlite3_busy_handler
	busy_timeout: sqlite3_busy_timeout
	changes: sqlite3_changes
	close_: sqlite3_close
	collation_needed: sqlite3_collation_needed
	collation_needed16: sqlite3_collation_needed16
	column_blob: sqlite3_column_blob
	column_bytes: sqlite3_column_bytes
	column_bytes16: sqlite3_column_bytes16
	column_count: sqlite3_column_count
	column_database_name: C2vFn_666e20282653716c697465335f73746d742c20696e742920266938(voidptr(0))
	column_database_name16: C2vFn_666e20282653716c697465335f73746d742c20696e742920766f6964707472(voidptr(0))
	column_decltype: sqlite3_column_decltype
	column_decltype16: sqlite3_column_decltype16
	column_double: sqlite3_column_double
	column_int: sqlite3_column_int
	column_int64: C2vFn_666e20282653716c697465335f73746d742c20696e74292053716c6974655f696e743634(voidptr(sqlite3_column_int64))
	column_name: sqlite3_column_name
	column_name16: sqlite3_column_name16
	column_origin_name: C2vFn_666e20282653716c697465335f73746d742c20696e742920266938(voidptr(0))
	column_origin_name16: C2vFn_666e20282653716c697465335f73746d742c20696e742920766f6964707472(voidptr(0))
	column_table_name: C2vFn_666e20282653716c697465335f73746d742c20696e742920266938(voidptr(0))
	column_table_name16: C2vFn_666e20282653716c697465335f73746d742c20696e742920766f6964707472(voidptr(0))
	column_text: sqlite3_column_text
	column_text16: sqlite3_column_text16
	column_type: sqlite3_column_type
	column_value: sqlite3_column_value
	commit_hook: sqlite3_commit_hook
	complete: sqlite3_complete
	complete16: sqlite3_complete16
	create_collation: sqlite3_create_collation
	create_collation16: sqlite3_create_collation16
	create_function: sqlite3_create_function
	create_function16: sqlite3_create_function16
	create_module: sqlite3_create_module
	data_count: sqlite3_data_count
	db_handle: sqlite3_db_handle
	declare_vtab: sqlite3_declare_vtab
	enable_shared_cache: sqlite3_enable_shared_cache
	errcode: sqlite3_errcode
	errmsg: sqlite3_errmsg
	errmsg16: sqlite3_errmsg16
	exec: C2vFn_666e20282653716c697465332c202669382c2053716c697465335f63616c6c6261636b2c20766f69647074722c20262675382920696e74(voidptr(sqlite3_exec))
	expired: sqlite3_expired
	finalize: sqlite3_finalize
	free_: sqlite3_free
	free_table: sqlite3_free_table
	get_autocommit: sqlite3_get_autocommit
	get_auxdata: sqlite3_get_auxdata
	get_table: sqlite3_get_table
	global_recover: C2vFn_666e20282920696e74(voidptr(0))
	interruptx: sqlite3_interrupt
	last_insert_rowid: C2vFn_666e20282653716c69746533292053716c6974655f696e743634(voidptr(sqlite3_last_insert_rowid))
	libversion: sqlite3_libversion
	libversion_number: sqlite3_libversion_number
	malloc_: sqlite3_malloc
	mprintf: sqlite3_mprintf
	open_: sqlite3_open
	open16: sqlite3_open16
	prepare: sqlite3_prepare
	prepare16: sqlite3_prepare16
	profile: C2vFn_666e20282653716c697465332c20666e2028766f69647074722c202669382c2053716c6974655f75696e743634292c20766f69647074722920766f6964707472(voidptr(sqlite3_profile))
	progress_handler: sqlite3_progress_handler
	realloc: sqlite3_realloc
	reset: sqlite3_reset
	result_blob: sqlite3_result_blob
	result_double: sqlite3_result_double
	result_error: sqlite3_result_error
	result_error16: sqlite3_result_error16
	result_int: sqlite3_result_int
	result_int64: C2vFn_666e20282653716c697465335f636f6e746578742c2053716c6974655f696e74363429(voidptr(sqlite3_result_int64))
	result_null: sqlite3_result_null
	result_text: sqlite3_result_text
	result_text16: sqlite3_result_text16
	result_text16be: sqlite3_result_text16be
	result_text16le: sqlite3_result_text16le
	result_value: sqlite3_result_value
	rollback_hook: sqlite3_rollback_hook
	set_authorizer: sqlite3_set_authorizer
	set_auxdata: sqlite3_set_auxdata
	xsnprintf: sqlite3_snprintf
	step: sqlite3_step
	table_column_metadata: sqlite3_table_column_metadata
	thread_cleanup: sqlite3_thread_cleanup
	total_changes: sqlite3_total_changes
	trace: sqlite3_trace
	transfer_bindings: sqlite3_transfer_bindings
	update_hook: C2vFn_666e20282653716c697465332c20666e2028766f69647074722c20696e742c202669382c202669382c2053716c6974655f696e743634292c20766f69647074722920766f6964707472(voidptr(sqlite3_update_hook))
	user_data: sqlite3_user_data
	value_blob: sqlite3_value_blob
	value_bytes: sqlite3_value_bytes
	value_bytes16: sqlite3_value_bytes16
	value_double: sqlite3_value_double
	value_int: sqlite3_value_int
	value_int64: C2vFn_666e20282653716c697465335f76616c7565292053716c6974655f696e743634(voidptr(sqlite3_value_int64))
	value_numeric_type: sqlite3_value_numeric_type
	value_text: sqlite3_value_text
	value_text16: sqlite3_value_text16
	value_text16be: sqlite3_value_text16be
	value_text16le: sqlite3_value_text16le
	value_type: sqlite3_value_type
	vmprintf: sqlite3_vmprintf
	overload_function: sqlite3_overload_function
	prepare_v2: sqlite3_prepare_v2
	prepare16_v2: sqlite3_prepare16_v2
	clear_bindings: sqlite3_clear_bindings
	create_module_v2: sqlite3_create_module_v2
	bind_zeroblob: sqlite3_bind_zeroblob
	blob_bytes: sqlite3_blob_bytes
	blob_close: sqlite3_blob_close
	blob_open: sqlite3_blob_open
	blob_read: sqlite3_blob_read
	blob_write: sqlite3_blob_write
	create_collation_v2: sqlite3_create_collation_v2
	file_control: sqlite3_file_control
	memory_highwater: sqlite3_memory_highwater
	memory_used: sqlite3_memory_used
	mutex_alloc: sqlite3_mutex_alloc
	mutex_enter: sqlite3_mutex_enter
	mutex_free: sqlite3_mutex_free
	mutex_leave: sqlite3_mutex_leave
	mutex_try: sqlite3_mutex_try
	open_v2: sqlite3_open_v2
	release_memory: sqlite3_release_memory
	result_error_nomem: sqlite3_result_error_nomem
	result_error_toobig: sqlite3_result_error_toobig
	sleep: sqlite3_sleep
	soft_heap_limit: sqlite3_soft_heap_limit
	vfs_find: sqlite3_vfs_find
	vfs_register: sqlite3_vfs_register
	vfs_unregister: sqlite3_vfs_unregister
	xthreadsafe: sqlite3_threadsafe
	result_zeroblob: sqlite3_result_zeroblob
	result_error_code: sqlite3_result_error_code
	test_control: sqlite3_test_control
	randomness: sqlite3_randomness
	context_db_handle: sqlite3_context_db_handle
	extended_result_codes: sqlite3_extended_result_codes
	limit: sqlite3_limit
	next_stmt: sqlite3_next_stmt
	sql_: sqlite3_sql
	status: sqlite3_status
	backup_finish: sqlite3_backup_finish
	backup_init: sqlite3_backup_init
	backup_pagecount: sqlite3_backup_pagecount
	backup_remaining: sqlite3_backup_remaining
	backup_step: sqlite3_backup_step
	compileoption_get: sqlite3_compileoption_get
	compileoption_used: sqlite3_compileoption_used
	create_function_v2: sqlite3_create_function_v2
	db_config: sqlite3_db_config
	db_mutex: sqlite3_db_mutex
	db_status: sqlite3_db_status
	extended_errcode: sqlite3_extended_errcode
	log: sqlite3_log
	soft_heap_limit64: sqlite3_soft_heap_limit64
	sourceid: sqlite3_sourceid
	stmt_status: sqlite3_stmt_status
	strnicmp: sqlite3_strnicmp
	unlock_notify: C2vFn_666e20282653716c697465332c20666e202826766f69647074722c20696e74292c20766f69647074722920696e74(voidptr(0))
	wal_autocheckpoint: sqlite3_wal_autocheckpoint
	wal_checkpoint: sqlite3_wal_checkpoint
	wal_hook: sqlite3_wal_hook
	blob_reopen: sqlite3_blob_reopen
	vtab_config: sqlite3_vtab_config
	vtab_on_conflict: sqlite3_vtab_on_conflict
	close_v2: sqlite3_close_v2
	db_filename: C2vFn_666e20282653716c697465332c202669382920266938(voidptr(sqlite3_db_filename))
	db_readonly: sqlite3_db_readonly
	db_release_memory: sqlite3_db_release_memory
	errstr: sqlite3_errstr
	stmt_busy: sqlite3_stmt_busy
	stmt_readonly: sqlite3_stmt_readonly
	stricmp: sqlite3_stricmp
	uri_boolean: C2vFn_666e20282669382c202669382c20696e742920696e74(voidptr(sqlite3_uri_boolean))
	uri_int64: C2vFn_666e20282669382c202669382c2053716c697465335f696e743634292053716c697465335f696e743634(voidptr(sqlite3_uri_int64))
	uri_parameter: C2vFn_666e20282669382c202669382920266938(voidptr(sqlite3_uri_parameter))
	xvsnprintf: sqlite3_vsnprintf
	wal_checkpoint_v2: sqlite3_wal_checkpoint_v2
	auto_extension: sqlite3_auto_extension
	bind_blob64: sqlite3_bind_blob64
	bind_text64: sqlite3_bind_text64
	cancel_auto_extension: sqlite3_cancel_auto_extension
	load_extension: sqlite3_load_extension
	malloc64: sqlite3_malloc64
	msize: sqlite3_msize
	realloc64: sqlite3_realloc64
	reset_auto_extension: sqlite3_reset_auto_extension
	result_blob64: sqlite3_result_blob64
	result_text64: sqlite3_result_text64
	strglob: sqlite3_strglob
	value_dup: C2vFn_666e20282653716c697465335f76616c756529202653716c697465335f76616c7565(voidptr(sqlite3_value_dup))
	value_free: sqlite3_value_free
	result_zeroblob64: sqlite3_result_zeroblob64
	bind_zeroblob64: sqlite3_bind_zeroblob64
	value_subtype: sqlite3_value_subtype
	result_subtype: sqlite3_result_subtype
	status64: sqlite3_status64
	strlike: sqlite3_strlike
	db_cacheflush: sqlite3_db_cacheflush
	system_errno: sqlite3_system_errno
	trace_v2: sqlite3_trace_v2
	expanded_sql: sqlite3_expanded_sql
	set_last_insert_rowid: sqlite3_set_last_insert_rowid
	prepare_v3: sqlite3_prepare_v3
	prepare16_v3: sqlite3_prepare16_v3
	bind_pointer: sqlite3_bind_pointer
	result_pointer: sqlite3_result_pointer
	value_pointer: sqlite3_value_pointer
	vtab_nochange: sqlite3_vtab_nochange
	value_nochange: sqlite3_value_nochange
	vtab_collation: sqlite3_vtab_collation
	keyword_count: sqlite3_keyword_count
	keyword_name: sqlite3_keyword_name
	keyword_check: sqlite3_keyword_check
	str_new: sqlite3_str_new
	str_finish: sqlite3_str_finish
	str_appendf: sqlite3_str_appendf
	str_vappendf: sqlite3_str_vappendf
	str_append: sqlite3_str_append
	str_appendall: sqlite3_str_appendall
	str_appendchar: sqlite3_str_appendchar
	str_reset: sqlite3_str_reset
	str_errcode: sqlite3_str_errcode
	str_length: sqlite3_str_length
	str_value: sqlite3_str_value
	create_window_function: sqlite3_create_window_function
	normalized_sql: C2vFn_666e20282653716c697465335f73746d742920266938(voidptr(0))
	stmt_isexplain: sqlite3_stmt_isexplain
	value_frombind: sqlite3_value_frombind
	drop_modules: sqlite3_drop_modules
	hard_heap_limit64: sqlite3_hard_heap_limit64
	uri_key: C2vFn_666e20282669382c20696e742920266938(voidptr(sqlite3_uri_key))
	filename_database: C2vFn_666e20282669382920266938(voidptr(sqlite3_filename_database))
	filename_journal: C2vFn_666e20282669382920266938(voidptr(sqlite3_filename_journal))
	filename_wal: C2vFn_666e20282669382920266938(voidptr(sqlite3_filename_wal))
	create_filename: C2vFn_666e20282669382c202669382c202669382c20696e742c20262675382920266938(voidptr(sqlite3_create_filename))
	free_filename: C2vFn_666e202826693829(voidptr(sqlite3_free_filename))
	database_file_object: sqlite3_database_file_object
	txn_state: sqlite3_txn_state
	changes64: sqlite3_changes64
	total_changes64: sqlite3_total_changes64
	autovacuum_pages: sqlite3_autovacuum_pages
	error_offset: sqlite3_error_offset
	vtab_rhs_value: sqlite3_vtab_rhs_value
	vtab_distinct: sqlite3_vtab_distinct
	vtab_in: sqlite3_vtab_in
	vtab_in_first: sqlite3_vtab_in_first
	vtab_in_next: sqlite3_vtab_in_next
	deserialize: sqlite3_deserialize
	serialize: sqlite3_serialize
	db_name: sqlite3_db_name
	value_encoding: sqlite3_value_encoding
	is_interrupted: sqlite3_is_interrupted
	stmt_explain: sqlite3_stmt_explain
	get_clientdata: sqlite3_get_clientdata
	set_clientdata: sqlite3_set_clientdata
	setlk_timeout: sqlite3_setlk_timeout
	set_errmsg: sqlite3_set_errmsg
	db_status64: sqlite3_db_status64
	str_truncate: sqlite3_str_truncate
	str_free: sqlite3_str_free
	carray_bind: C2vFn_666e20282653716c697465335f73746d742c20696e742c20766f69647074722c20696e742c20696e742c20666e2028766f6964707472292920696e74(voidptr(0))
	carray_bind_v2: C2vFn_666e20282653716c697465335f73746d742c20696e742c20766f69647074722c20696e742c20696e742c20666e2028766f6964707472292c20766f69647074722920696e74(voidptr(0))
}
@[weak]
__global sqlite3Autoext = Sqlite3AutoExtList{}
@[weak]
__global pragCName = [c'id', c'seq', c'table', c'from', c'to', c'on_update', c'on_delete', c'match',
	c'cid', c'name', c'type', c'notnull', c'dflt_value', c'pk', c'hidden', c'name', c'builtin',
	c'type', c'enc', c'narg', c'flags', c'schema', c'name', c'type', c'ncol', c'wr', c'strict',
	c'seqno', c'cid', c'name', c'desc', c'coll', c'key', c'seq', c'name', c'unique', c'origin',
	c'partial', c'tbl', c'idx', c'wdth', c'hght', c'flgs', c'table', c'rowid', c'parent', c'fkid',
	c'busy', c'log', c'checkpointed', c'seq', c'name', c'file', c'database', c'status', c'cache_size',
	c'timeout']!
@[weak]
__global aPragmaName = [PragmaName{
	zName: c'analysis_limit'
	ePragTyp: U8(1)
	mPragFlg: U8(16)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'application_id'
	ePragTyp: U8(2)
	mPragFlg: U8(4 | 16)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(8)
}, PragmaName{
	zName: c'auto_vacuum'
	ePragTyp: U8(3)
	mPragFlg: U8(1 | 16 | 128 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'automatic_index'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(32768)
}, PragmaName{
	zName: c'busy_timeout'
	ePragTyp: U8(5)
	mPragFlg: U8(16)
	iPragCName: U8(56)
	nPragCName: U8(1)
	iArg: U64(0)
}, PragmaName{
	zName: c'cache_size'
	ePragTyp: U8(6)
	mPragFlg: U8(1 | 16 | 128 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'cache_spill'
	ePragTyp: U8(7)
	mPragFlg: U8(16 | 128 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'case_sensitive_like'
	ePragTyp: U8(8)
	mPragFlg: U8(2)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'cell_size_check'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(2097152)
}, PragmaName{
	zName: c'checkpoint_fullfsync'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(16)
}, PragmaName{
	zName: c'collation_list'
	ePragTyp: U8(9)
	mPragFlg: U8(16)
	iPragCName: U8(33)
	nPragCName: U8(2)
	iArg: U64(0)
}, PragmaName{
	zName: c'compile_options'
	ePragTyp: U8(10)
	mPragFlg: U8(16)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'count_changes'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: 4294967296
}, PragmaName{
	zName: c'data_version'
	ePragTyp: U8(2)
	mPragFlg: U8(8 | 16)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(15)
}, PragmaName{
	zName: c'database_list'
	ePragTyp: U8(12)
	mPragFlg: U8(16)
	iPragCName: U8(50)
	nPragCName: U8(3)
	iArg: U64(0)
}, PragmaName{
	zName: c'default_cache_size'
	ePragTyp: U8(13)
	mPragFlg: U8(1 | 16 | 128 | 4)
	iPragCName: U8(55)
	nPragCName: U8(1)
	iArg: U64(0)
}, PragmaName{
	zName: c'defer_foreign_keys'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(524288)
}, PragmaName{
	zName: c'empty_result_callbacks'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(256)
}, PragmaName{
	zName: c'encoding'
	ePragTyp: U8(14)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'foreign_key_check'
	ePragTyp: U8(15)
	mPragFlg: U8(1 | 16 | 32 | 64)
	iPragCName: U8(43)
	nPragCName: U8(4)
	iArg: U64(0)
}, PragmaName{
	zName: c'foreign_key_list'
	ePragTyp: U8(16)
	mPragFlg: U8(1 | 32 | 64)
	iPragCName: U8(0)
	nPragCName: U8(8)
	iArg: U64(0)
}, PragmaName{
	zName: c'foreign_keys'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(16384)
}, PragmaName{
	zName: c'freelist_count'
	ePragTyp: U8(2)
	mPragFlg: U8(8 | 16)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'full_column_names'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(4)
}, PragmaName{
	zName: c'fullfsync'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(8)
}, PragmaName{
	zName: c'function_list'
	ePragTyp: U8(17)
	mPragFlg: U8(16)
	iPragCName: U8(15)
	nPragCName: U8(6)
	iArg: U64(0)
}, PragmaName{
	zName: c'hard_heap_limit'
	ePragTyp: U8(18)
	mPragFlg: U8(16)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'ignore_check_constraints'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(512)
}, PragmaName{
	zName: c'incremental_vacuum'
	ePragTyp: U8(19)
	mPragFlg: U8(1 | 2)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'index_info'
	ePragTyp: U8(20)
	mPragFlg: U8(1 | 32 | 64)
	iPragCName: U8(27)
	nPragCName: U8(3)
	iArg: U64(0)
}, PragmaName{
	zName: c'index_list'
	ePragTyp: U8(21)
	mPragFlg: U8(1 | 32 | 64)
	iPragCName: U8(33)
	nPragCName: U8(5)
	iArg: U64(0)
}, PragmaName{
	zName: c'index_xinfo'
	ePragTyp: U8(20)
	mPragFlg: U8(1 | 32 | 64)
	iPragCName: U8(27)
	nPragCName: U8(6)
	iArg: U64(1)
}, PragmaName{
	zName: c'integrity_check'
	ePragTyp: U8(22)
	mPragFlg: U8(1 | 16 | 32 | 64)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'journal_mode'
	ePragTyp: U8(23)
	mPragFlg: U8(1 | 16 | 128)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'journal_size_limit'
	ePragTyp: U8(24)
	mPragFlg: U8(16 | 128)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'legacy_alter_table'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(67108864)
}, PragmaName{
	zName: c'lock_proxy_file'
	ePragTyp: U8(25)
	mPragFlg: U8(4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'locking_mode'
	ePragTyp: U8(26)
	mPragFlg: U8(16 | 128)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'max_page_count'
	ePragTyp: U8(27)
	mPragFlg: U8(1 | 16 | 128)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'mmap_size'
	ePragTyp: U8(28)
	mPragFlg: U8(0)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'module_list'
	ePragTyp: U8(29)
	mPragFlg: U8(16)
	iPragCName: U8(9)
	nPragCName: U8(1)
	iArg: U64(0)
}, PragmaName{
	zName: c'optimize'
	ePragTyp: U8(30)
	mPragFlg: U8(32 | 1)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'page_count'
	ePragTyp: U8(27)
	mPragFlg: U8(1 | 16 | 128)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'page_size'
	ePragTyp: U8(31)
	mPragFlg: U8(16 | 128 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'pragma_list'
	ePragTyp: U8(32)
	mPragFlg: U8(16)
	iPragCName: U8(9)
	nPragCName: U8(1)
	iArg: U64(0)
}, PragmaName{
	zName: c'query_only'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(1048576)
}, PragmaName{
	zName: c'quick_check'
	ePragTyp: U8(22)
	mPragFlg: U8(1 | 16 | 32 | 64)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'read_uncommitted'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: 17179869184
}, PragmaName{
	zName: c'recursive_triggers'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(8192)
}, PragmaName{
	zName: c'reverse_unordered_selects'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(4096)
}, PragmaName{
	zName: c'schema_version'
	ePragTyp: U8(2)
	mPragFlg: U8(4 | 16)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(1)
}, PragmaName{
	zName: c'secure_delete'
	ePragTyp: U8(33)
	mPragFlg: U8(16)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'short_column_names'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(64)
}, PragmaName{
	zName: c'shrink_memory'
	ePragTyp: U8(34)
	mPragFlg: U8(2)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'soft_heap_limit'
	ePragTyp: U8(35)
	mPragFlg: U8(16)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'synchronous'
	ePragTyp: U8(36)
	mPragFlg: U8(1 | 16 | 128 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'table_info'
	ePragTyp: U8(37)
	mPragFlg: U8(1 | 32 | 64)
	iPragCName: U8(8)
	nPragCName: U8(6)
	iArg: U64(0)
}, PragmaName{
	zName: c'table_list'
	ePragTyp: U8(38)
	mPragFlg: U8(1 | 32)
	iPragCName: U8(21)
	nPragCName: U8(6)
	iArg: U64(0)
}, PragmaName{
	zName: c'table_xinfo'
	ePragTyp: U8(37)
	mPragFlg: U8(1 | 32 | 64)
	iPragCName: U8(8)
	nPragCName: U8(7)
	iArg: U64(1)
}, PragmaName{
	zName: c'temp_store'
	ePragTyp: U8(39)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'temp_store_directory'
	ePragTyp: U8(40)
	mPragFlg: U8(4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'threads'
	ePragTyp: U8(41)
	mPragFlg: U8(16)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'trusted_schema'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(128)
}, PragmaName{
	zName: c'user_version'
	ePragTyp: U8(2)
	mPragFlg: U8(4 | 16)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(6)
}, PragmaName{
	zName: c'wal_autocheckpoint'
	ePragTyp: U8(42)
	mPragFlg: U8(0)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(0)
}, PragmaName{
	zName: c'wal_checkpoint'
	ePragTyp: U8(43)
	mPragFlg: U8(1)
	iPragCName: U8(47)
	nPragCName: U8(3)
	iArg: U64(0)
}, PragmaName{
	zName: c'writable_schema'
	ePragTyp: U8(4)
	mPragFlg: U8(16 | 4)
	iPragCName: U8(0)
	nPragCName: U8(0)
	iArg: U64(1 | 134217728)
}]!
@[weak]
__global pragmaVtabModule = Sqlite3_module{
	iVersion: 0
	xCreate: C2vFn_666e20282653716c697465332c20766f69647074722c20696e742c20262675382c20262653716c697465335f767461622c20262675382920696e74(voidptr(0))
	xConnect: pragma_vtab_connect
	xBestIndex: pragma_vtab_best_index
	xDisconnect: pragma_vtab_disconnect
	xDestroy: C2vFn_666e20282653716c697465335f767461622920696e74(voidptr(0))
	xOpen: pragma_vtab_open
	xClose: pragma_vtab_close
	xFilter: pragma_vtab_filter
	xNext: pragma_vtab_next
	xEof: pragma_vtab_eof
	xColumn: pragma_vtab_column
	xRowid: C2vFn_666e20282653716c697465335f767461625f637572736f722c202653716c697465335f696e7436342920696e74(voidptr(pragma_vtab_rowid))
	xUpdate: C2vFn_666e20282653716c697465335f767461622c20696e742c20262653716c697465335f76616c75652c202653716c697465335f696e7436342920696e74(voidptr(0))
	xBegin: C2vFn_666e20282653716c697465335f767461622920696e74(voidptr(0))
	xSync: C2vFn_666e20282653716c697465335f767461622920696e74(voidptr(0))
	xCommit: C2vFn_666e20282653716c697465335f767461622920696e74(voidptr(0))
	xRollback: C2vFn_666e20282653716c697465335f767461622920696e74(voidptr(0))
	xFindFunction: C2vFn_666e20282653716c697465335f767461622c20696e742c202669382c2026666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c7565292c2026766f69647074722920696e74(voidptr(0))
	xRename: C2vFn_666e20282653716c697465335f767461622c202669382920696e74(voidptr(0))
	xSavepoint: C2vFn_666e20282653716c697465335f767461622c20696e742920696e74(voidptr(0))
	xRelease: C2vFn_666e20282653716c697465335f767461622c20696e742920696e74(voidptr(0))
	xRollbackTo: C2vFn_666e20282653716c697465335f767461622c20696e742920696e74(voidptr(0))
	xShadowName: C2vFn_666e20282669382920696e74(voidptr(0))
	xIntegrity: C2vFn_666e20282653716c697465335f767461622c202669382c202669382c20696e742c20262675382920696e74(voidptr(0))
}
@[weak]
__global row_numberName = [i8(114), 111, 119, 95, 110, 117, 109, 98, 101, 114, 0]!
@[weak]
__global dense_rankName = [i8(100), 101, 110, 115, 101, 95, 114, 97, 110, 107, 0]!
@[weak]
__global rankName = [i8(114), 97, 110, 107, 0]!
@[weak]
__global percent_rankName = [i8(112), 101, 114, 99, 101, 110, 116, 95, 114, 97, 110, 107, 0]!
@[weak]
__global cume_distName = [i8(99), 117, 109, 101, 95, 100, 105, 115, 116, 0]!
@[weak]
__global ntileName = [i8(110), 116, 105, 108, 101, 0]!
@[weak]
__global last_valueName = [i8(108), 97, 115, 116, 95, 118, 97, 108, 117, 101, 0]!
@[weak]
__global nth_valueName = [i8(110), 116, 104, 95, 118, 97, 108, 117, 101, 0]!
@[weak]
__global first_valueName = [i8(102), 105, 114, 115, 116, 95, 118, 97, 108, 117, 101, 0]!
@[weak]
__global leadName = [i8(108), 101, 97, 100, 0]!
@[weak]
__global lagName = [i8(108), 97, 103, 0]!

@[export: 'yy_action']
const yy_action = [u16(134), u16(131), u16(238), u16(290), u16(290), u16(1353), u16(593), u16(1332),
	u16(478), u16(1606), u16(593), u16(1315), u16(593), u16(7), u16(593), u16(1353), u16(590),
	u16(593), u16(579), u16(424), u16(1566), u16(134), u16(131), u16(238), u16(1318), u16(541),
	u16(478), u16(477), u16(575), u16(84), u16(84), u16(1005), u16(303), u16(84), u16(84), u16(51),
	u16(51), u16(63), u16(63), u16(1006), u16(84), u16(84), u16(498), u16(141), u16(142), u16(93),
	u16(442), u16(1254), u16(1254), u16(1085), u16(1088), u16(1075), u16(1075), u16(139), u16(139),
	u16(140), u16(140), u16(140), u16(140), u16(424), u16(296), u16(296), u16(498), u16(296),
	u16(296), u16(567), u16(553), u16(296), u16(296), u16(1306), u16(574), u16(1358), u16(1358),
	u16(590), u16(542), u16(579), u16(590), u16(574), u16(579), u16(548), u16(590), u16(1304),
	u16(579), u16(141), u16(142), u16(93), u16(576), u16(1254), u16(1254), u16(1085), u16(1088),
	u16(1075), u16(1075), u16(139), u16(139), u16(140), u16(140), u16(140), u16(140), u16(399),
	u16(478), u16(395), u16(6), u16(138), u16(138), u16(138), u16(138), u16(137), u16(137), u16(136),
	u16(136), u16(136), u16(135), u16(132), u16(463), u16(44), u16(342), u16(593), u16(305),
	u16(1127), u16(1280), u16(1), u16(1), u16(599), u16(2), u16(1284), u16(598), u16(1200),
	u16(1284), u16(1200), u16(330), u16(424), u16(158), u16(330), u16(1613), u16(158), u16(390),
	u16(116), u16(308), u16(1366), u16(51), u16(51), u16(1366), u16(138), u16(138), u16(138),
	u16(138), u16(137), u16(137), u16(136), u16(136), u16(136), u16(135), u16(132), u16(463),
	u16(141), u16(142), u16(93), u16(515), u16(1254), u16(1254), u16(1085), u16(1088), u16(1075),
	u16(1075), u16(139), u16(139), u16(140), u16(140), u16(140), u16(140), u16(1230), u16(329),
	u16(584), u16(296), u16(296), u16(212), u16(296), u16(296), u16(568), u16(568), u16(488),
	u16(143), u16(1072), u16(1072), u16(1086), u16(1089), u16(590), u16(1195), u16(579), u16(590),
	u16(340), u16(579), u16(140), u16(140), u16(140), u16(140), u16(133), u16(392), u16(564),
	u16(536), u16(1195), u16(250), u16(425), u16(1195), u16(250), u16(137), u16(137), u16(136),
	u16(136), u16(136), u16(135), u16(132), u16(463), u16(291), u16(138), u16(138), u16(138),
	u16(138), u16(137), u16(137), u16(136), u16(136), u16(136), u16(135), u16(132), u16(463),
	u16(966), u16(1230), u16(1231), u16(1230), u16(412), u16(965), u16(467), u16(412), u16(424),
	u16(467), u16(489), u16(357), u16(1611), u16(391), u16(138), u16(138), u16(138), u16(138),
	u16(137), u16(137), u16(136), u16(136), u16(136), u16(135), u16(132), u16(463), u16(463),
	u16(134), u16(131), u16(238), u16(555), u16(1076), u16(141), u16(142), u16(93), u16(593),
	u16(1254), u16(1254), u16(1085), u16(1088), u16(1075), u16(1075), u16(139), u16(139), u16(140),
	u16(140), u16(140), u16(140), u16(1317), u16(134), u16(131), u16(238), u16(424), u16(549),
	u16(1597), u16(1531), u16(333), u16(97), u16(83), u16(83), u16(140), u16(140), u16(140),
	u16(140), u16(138), u16(138), u16(138), u16(138), u16(137), u16(137), u16(136), u16(136),
	u16(136), u16(135), u16(132), u16(463), u16(141), u16(142), u16(93), u16(1657), u16(1254),
	u16(1254), u16(1085), u16(1088), u16(1075), u16(1075), u16(139), u16(139), u16(140), u16(140),
	u16(140), u16(140), u16(138), u16(138), u16(138), u16(138), u16(137), u16(137), u16(136),
	u16(136), u16(136), u16(135), u16(132), u16(463), u16(591), u16(1230), u16(958), u16(958),
	u16(138), u16(138), u16(138), u16(138), u16(137), u16(137), u16(136), u16(136), u16(136),
	u16(135), u16(132), u16(463), u16(44), u16(398), u16(547), u16(1306), u16(136), u16(136),
	u16(136), u16(135), u16(132), u16(463), u16(386), u16(593), u16(442), u16(595), u16(145),
	u16(595), u16(138), u16(138), u16(138), u16(138), u16(137), u16(137), u16(136), u16(136),
	u16(136), u16(135), u16(132), u16(463), u16(500), u16(1230), u16(112), u16(550), u16(460),
	u16(459), u16(51), u16(51), u16(424), u16(296), u16(296), u16(479), u16(334), u16(1259),
	u16(1230), u16(1231), u16(1230), u16(1599), u16(1261), u16(388), u16(312), u16(444), u16(590),
	u16(246), u16(579), u16(546), u16(1260), u16(271), u16(235), u16(329), u16(584), u16(551),
	u16(141), u16(142), u16(93), u16(429), u16(1254), u16(1254), u16(1085), u16(1088), u16(1075),
	u16(1075), u16(139), u16(139), u16(140), u16(140), u16(140), u16(140), u16(22), u16(22),
	u16(1230), u16(1262), u16(424), u16(1262), u16(216), u16(296), u16(296), u16(98), u16(1230),
	u16(1231), u16(1230), u16(264), u16(884), u16(45), u16(528), u16(525), u16(524), u16(1041),
	u16(590), u16(1269), u16(579), u16(421), u16(420), u16(393), u16(523), u16(44), u16(141),
	u16(142), u16(93), u16(498), u16(1254), u16(1254), u16(1085), u16(1088), u16(1075), u16(1075),
	u16(139), u16(139), u16(140), u16(140), u16(140), u16(140), u16(138), u16(138), u16(138),
	u16(138), u16(137), u16(137), u16(136), u16(136), u16(136), u16(135), u16(132), u16(463),
	u16(593), u16(1611), u16(561), u16(1230), u16(1231), u16(1230), u16(23), u16(264), u16(515),
	u16(200), u16(528), u16(525), u16(524), u16(127), u16(585), u16(509), u16(4), u16(355), u16(487),
	u16(506), u16(523), u16(593), u16(498), u16(84), u16(84), u16(134), u16(131), u16(238), u16(329),
	u16(584), u16(588), u16(1627), u16(138), u16(138), u16(138), u16(138), u16(137), u16(137),
	u16(136), u16(136), u16(136), u16(135), u16(132), u16(463), u16(19), u16(19), u16(435),
	u16(1230), u16(1460), u16(297), u16(297), u16(311), u16(424), u16(1565), u16(464), u16(1631),
	u16(599), u16(2), u16(1284), u16(437), u16(574), u16(1107), u16(590), u16(330), u16(579),
	u16(158), u16(582), u16(489), u16(357), u16(573), u16(593), u16(592), u16(1366), u16(409),
	u16(1274), u16(1230), u16(141), u16(142), u16(93), u16(1364), u16(1254), u16(1254), u16(1085),
	u16(1088), u16(1075), u16(1075), u16(139), u16(139), u16(140), u16(140), u16(140), u16(140),
	u16(389), u16(84), u16(84), u16(1062), u16(567), u16(1230), u16(313), u16(1523), u16(593),
	u16(125), u16(125), u16(970), u16(1230), u16(1231), u16(1230), u16(296), u16(296), u16(126),
	u16(46), u16(464), u16(594), u16(464), u16(296), u16(296), u16(1050), u16(1230), u16(218),
	u16(439), u16(590), u16(1604), u16(579), u16(84), u16(84), u16(7), u16(403), u16(590), u16(515),
	u16(579), u16(325), u16(417), u16(1230), u16(1231), u16(1230), u16(250), u16(138), u16(138),
	u16(138), u16(138), u16(137), u16(137), u16(136), u16(136), u16(136), u16(135), u16(132),
	u16(463), u16(1050), u16(1050), u16(1052), u16(1053), u16(35), u16(1275), u16(1230), u16(1231),
	u16(1230), u16(424), u16(1370), u16(993), u16(574), u16(371), u16(414), u16(274), u16(412),
	u16(1597), u16(467), u16(1302), u16(552), u16(451), u16(590), u16(543), u16(579), u16(1530),
	u16(1230), u16(1231), u16(1230), u16(1214), u16(201), u16(409), u16(1174), u16(141), u16(142),
	u16(93), u16(223), u16(1254), u16(1254), u16(1085), u16(1088), u16(1075), u16(1075), u16(139),
	u16(139), u16(140), u16(140), u16(140), u16(140), u16(296), u16(296), u16(1250), u16(593),
	u16(424), u16(296), u16(296), u16(236), u16(529), u16(296), u16(296), u16(515), u16(100),
	u16(590), u16(1600), u16(579), u16(48), u16(1605), u16(590), u16(1230), u16(579), u16(7),
	u16(590), u16(577), u16(579), u16(904), u16(84), u16(84), u16(141), u16(142), u16(93), u16(496),
	u16(1254), u16(1254), u16(1085), u16(1088), u16(1075), u16(1075), u16(139), u16(139), u16(140),
	u16(140), u16(140), u16(140), u16(138), u16(138), u16(138), u16(138), u16(137), u16(137),
	u16(136), u16(136), u16(136), u16(135), u16(132), u16(463), u16(1365), u16(1230), u16(296),
	u16(296), u16(1250), u16(115), u16(1275), u16(326), u16(233), u16(539), u16(1062), u16(40),
	u16(282), u16(127), u16(585), u16(590), u16(4), u16(579), u16(329), u16(584), u16(1230),
	u16(1231), u16(1230), u16(1598), u16(593), u16(388), u16(904), u16(1051), u16(1356), u16(1356),
	u16(588), u16(1050), u16(138), u16(138), u16(138), u16(138), u16(137), u16(137), u16(136),
	u16(136), u16(136), u16(135), u16(132), u16(463), u16(185), u16(593), u16(1230), u16(19),
	u16(19), u16(1230), u16(971), u16(1597), u16(424), u16(1651), u16(464), u16(129), u16(908),
	u16(1195), u16(1230), u16(1231), u16(1230), u16(1325), u16(443), u16(1050), u16(1050), u16(1052),
	u16(582), u16(1603), u16(149), u16(149), u16(1195), u16(7), u16(5), u16(1195), u16(1687),
	u16(410), u16(141), u16(142), u16(93), u16(1536), u16(1254), u16(1254), u16(1085), u16(1088),
	u16(1075), u16(1075), u16(139), u16(139), u16(140), u16(140), u16(140), u16(140), u16(1214),
	u16(397), u16(593), u16(1062), u16(424), u16(1536), u16(1538), u16(50), u16(901), u16(125),
	u16(125), u16(1230), u16(1231), u16(1230), u16(1230), u16(1231), u16(1230), u16(126), u16(1230),
	u16(464), u16(594), u16(464), u16(515), u16(1230), u16(1050), u16(84), u16(84), u16(3), u16(141),
	u16(142), u16(93), u16(924), u16(1254), u16(1254), u16(1085), u16(1088), u16(1075), u16(1075),
	u16(139), u16(139), u16(140), u16(140), u16(140), u16(140), u16(138), u16(138), u16(138),
	u16(138), u16(137), u16(137), u16(136), u16(136), u16(136), u16(135), u16(132), u16(463),
	u16(1050), u16(1050), u16(1052), u16(1053), u16(35), u16(442), u16(457), u16(532), u16(433),
	u16(1230), u16(1062), u16(1361), u16(540), u16(540), u16(1598), u16(925), u16(388), u16(7),
	u16(1129), u16(1230), u16(1231), u16(1230), u16(1129), u16(1536), u16(1230), u16(1231),
	u16(1230), u16(1051), u16(570), u16(1214), u16(593), u16(1050), u16(138), u16(138), u16(138),
	u16(138), u16(137), u16(137), u16(136), u16(136), u16(136), u16(135), u16(132), u16(463), u16(6),
	u16(185), u16(1195), u16(1230), u16(231), u16(593), u16(382), u16(992), u16(424), u16(151),
	u16(151), u16(510), u16(1213), u16(557), u16(482), u16(1195), u16(381), u16(160), u16(1195),
	u16(1050), u16(1050), u16(1052), u16(1230), u16(1231), u16(1230), u16(422), u16(593), u16(447),
	u16(84), u16(84), u16(593), u16(217), u16(141), u16(142), u16(93), u16(593), u16(1254),
	u16(1254), u16(1085), u16(1088), u16(1075), u16(1075), u16(139), u16(139), u16(140), u16(140),
	u16(140), u16(140), u16(1214), u16(19), u16(19), u16(593), u16(424), u16(19), u16(19), u16(442),
	u16(1063), u16(442), u16(19), u16(19), u16(1230), u16(1231), u16(1230), u16(515), u16(445),
	u16(458), u16(1597), u16(386), u16(315), u16(1175), u16(1685), u16(556), u16(1685), u16(450),
	u16(84), u16(84), u16(141), u16(142), u16(93), u16(505), u16(1254), u16(1254), u16(1085),
	u16(1088), u16(1075), u16(1075), u16(139), u16(139), u16(140), u16(140), u16(140), u16(140),
	u16(138), u16(138), u16(138), u16(138), u16(137), u16(137), u16(136), u16(136), u16(136),
	u16(135), u16(132), u16(463), u16(442), u16(1147), u16(454), u16(1597), u16(362), u16(1041),
	u16(593), u16(462), u16(1460), u16(1233), u16(47), u16(1393), u16(324), u16(565), u16(565),
	u16(115), u16(1148), u16(449), u16(7), u16(460), u16(459), u16(307), u16(375), u16(354),
	u16(593), u16(113), u16(593), u16(329), u16(584), u16(19), u16(19), u16(1149), u16(138),
	u16(138), u16(138), u16(138), u16(137), u16(137), u16(136), u16(136), u16(136), u16(135),
	u16(132), u16(463), u16(209), u16(1173), u16(563), u16(19), u16(19), u16(19), u16(19), u16(49),
	u16(424), u16(944), u16(1175), u16(1686), u16(1046), u16(1686), u16(218), u16(355), u16(484),
	u16(343), u16(210), u16(945), u16(569), u16(562), u16(1262), u16(1233), u16(1262), u16(490),
	u16(314), u16(423), u16(424), u16(1598), u16(1206), u16(388), u16(141), u16(142), u16(93),
	u16(440), u16(1254), u16(1254), u16(1085), u16(1088), u16(1075), u16(1075), u16(139), u16(139),
	u16(140), u16(140), u16(140), u16(140), u16(352), u16(316), u16(531), u16(316), u16(141),
	u16(142), u16(93), u16(549), u16(1254), u16(1254), u16(1085), u16(1088), u16(1075), u16(1075),
	u16(139), u16(139), u16(140), u16(140), u16(140), u16(140), u16(446), u16(10), u16(1598),
	u16(274), u16(388), u16(915), u16(281), u16(299), u16(383), u16(534), u16(378), u16(533),
	u16(269), u16(593), u16(1206), u16(587), u16(587), u16(587), u16(374), u16(293), u16(1579),
	u16(991), u16(1173), u16(302), u16(138), u16(138), u16(138), u16(138), u16(137), u16(137),
	u16(136), u16(136), u16(136), u16(135), u16(132), u16(463), u16(53), u16(53), u16(520),
	u16(1250), u16(593), u16(1147), u16(1576), u16(431), u16(138), u16(138), u16(138), u16(138),
	u16(137), u16(137), u16(136), u16(136), u16(136), u16(135), u16(132), u16(463), u16(1148),
	u16(301), u16(593), u16(1577), u16(593), u16(1307), u16(431), u16(54), u16(54), u16(593),
	u16(268), u16(593), u16(461), u16(461), u16(461), u16(1149), u16(347), u16(492), u16(424),
	u16(135), u16(132), u16(463), u16(1146), u16(1195), u16(474), u16(68), u16(68), u16(69), u16(69),
	u16(550), u16(332), u16(287), u16(21), u16(21), u16(55), u16(55), u16(1195), u16(581), u16(424),
	u16(1195), u16(309), u16(1250), u16(141), u16(142), u16(93), u16(119), u16(1254), u16(1254),
	u16(1085), u16(1088), u16(1075), u16(1075), u16(139), u16(139), u16(140), u16(140), u16(140),
	u16(140), u16(593), u16(237), u16(480), u16(1476), u16(141), u16(142), u16(93), u16(593),
	u16(1254), u16(1254), u16(1085), u16(1088), u16(1075), u16(1075), u16(139), u16(139), u16(140),
	u16(140), u16(140), u16(140), u16(344), u16(430), u16(346), u16(70), u16(70), u16(494), u16(991),
	u16(1132), u16(1132), u16(512), u16(56), u16(56), u16(1269), u16(593), u16(268), u16(593),
	u16(369), u16(374), u16(593), u16(481), u16(215), u16(384), u16(1624), u16(481), u16(138),
	u16(138), u16(138), u16(138), u16(137), u16(137), u16(136), u16(136), u16(136), u16(135),
	u16(132), u16(463), u16(71), u16(71), u16(72), u16(72), u16(225), u16(73), u16(73), u16(593),
	u16(138), u16(138), u16(138), u16(138), u16(137), u16(137), u16(136), u16(136), u16(136),
	u16(135), u16(132), u16(463), u16(586), u16(431), u16(593), u16(872), u16(873), u16(874),
	u16(593), u16(911), u16(593), u16(1602), u16(74), u16(74), u16(593), u16(7), u16(1460), u16(242),
	u16(593), u16(306), u16(424), u16(1578), u16(472), u16(306), u16(364), u16(219), u16(367),
	u16(75), u16(75), u16(430), u16(345), u16(57), u16(57), u16(58), u16(58), u16(432), u16(187),
	u16(59), u16(59), u16(593), u16(424), u16(61), u16(61), u16(1475), u16(141), u16(142), u16(93),
	u16(123), u16(1254), u16(1254), u16(1085), u16(1088), u16(1075), u16(1075), u16(139), u16(139),
	u16(140), u16(140), u16(140), u16(140), u16(424), u16(570), u16(62), u16(62), u16(141), u16(142),
	u16(93), u16(911), u16(1254), u16(1254), u16(1085), u16(1088), u16(1075), u16(1075), u16(139),
	u16(139), u16(140), u16(140), u16(140), u16(140), u16(161), u16(384), u16(1624), u16(1474),
	u16(141), u16(130), u16(93), u16(441), u16(1254), u16(1254), u16(1085), u16(1088), u16(1075),
	u16(1075), u16(139), u16(139), u16(140), u16(140), u16(140), u16(140), u16(267), u16(266),
	u16(265), u16(1460), u16(138), u16(138), u16(138), u16(138), u16(137), u16(137), u16(136),
	u16(136), u16(136), u16(135), u16(132), u16(463), u16(593), u16(1336), u16(593), u16(1269),
	u16(1460), u16(384), u16(1624), u16(231), u16(138), u16(138), u16(138), u16(138), u16(137),
	u16(137), u16(136), u16(136), u16(136), u16(135), u16(132), u16(463), u16(593), u16(163),
	u16(593), u16(76), u16(76), u16(77), u16(77), u16(593), u16(138), u16(138), u16(138), u16(138),
	u16(137), u16(137), u16(136), u16(136), u16(136), u16(135), u16(132), u16(463), u16(475),
	u16(593), u16(483), u16(78), u16(78), u16(20), u16(20), u16(1249), u16(424), u16(491), u16(79),
	u16(79), u16(495), u16(422), u16(295), u16(235), u16(1574), u16(38), u16(511), u16(896),
	u16(422), u16(335), u16(240), u16(422), u16(147), u16(147), u16(112), u16(593), u16(424),
	u16(593), u16(101), u16(222), u16(991), u16(142), u16(93), u16(455), u16(1254), u16(1254),
	u16(1085), u16(1088), u16(1075), u16(1075), u16(139), u16(139), u16(140), u16(140), u16(140),
	u16(140), u16(593), u16(39), u16(148), u16(148), u16(80), u16(80), u16(93), u16(551), u16(1254),
	u16(1254), u16(1085), u16(1088), u16(1075), u16(1075), u16(139), u16(139), u16(140), u16(140),
	u16(140), u16(140), u16(328), u16(923), u16(922), u16(64), u16(64), u16(502), u16(1656),
	u16(1005), u16(933), u16(896), u16(124), u16(422), u16(121), u16(254), u16(593), u16(1006),
	u16(593), u16(226), u16(593), u16(127), u16(585), u16(164), u16(4), u16(16), u16(138), u16(138),
	u16(138), u16(138), u16(137), u16(137), u16(136), u16(136), u16(136), u16(135), u16(132),
	u16(463), u16(588), u16(81), u16(81), u16(65), u16(65), u16(82), u16(82), u16(593), u16(138),
	u16(138), u16(138), u16(138), u16(137), u16(137), u16(136), u16(136), u16(136), u16(135),
	u16(132), u16(463), u16(593), u16(226), u16(237), u16(966), u16(464), u16(593), u16(298),
	u16(593), u16(965), u16(593), u16(66), u16(66), u16(593), u16(1170), u16(593), u16(411),
	u16(582), u16(353), u16(469), u16(115), u16(593), u16(471), u16(169), u16(173), u16(173),
	u16(593), u16(44), u16(991), u16(174), u16(174), u16(89), u16(89), u16(67), u16(67), u16(593),
	u16(85), u16(85), u16(150), u16(150), u16(1114), u16(1043), u16(593), u16(273), u16(86), u16(86),
	u16(1062), u16(593), u16(503), u16(171), u16(171), u16(593), u16(125), u16(125), u16(497),
	u16(593), u16(273), u16(336), u16(152), u16(152), u16(126), u16(1335), u16(464), u16(594),
	u16(464), u16(146), u16(146), u16(1050), u16(593), u16(545), u16(172), u16(172), u16(593),
	u16(1054), u16(165), u16(165), u16(256), u16(339), u16(156), u16(156), u16(127), u16(585),
	u16(1586), u16(4), u16(329), u16(584), u16(499), u16(358), u16(273), u16(115), u16(348),
	u16(155), u16(155), u16(930), u16(931), u16(153), u16(153), u16(588), u16(1114), u16(1050),
	u16(1050), u16(1052), u16(1053), u16(35), u16(1554), u16(521), u16(593), u16(270), u16(1008),
	u16(1009), u16(9), u16(593), u16(372), u16(593), u16(115), u16(593), u16(168), u16(593),
	u16(115), u16(593), u16(1110), u16(464), u16(270), u16(996), u16(964), u16(273), u16(129),
	u16(1645), u16(1214), u16(154), u16(154), u16(1054), u16(1404), u16(582), u16(88), u16(88),
	u16(90), u16(90), u16(87), u16(87), u16(52), u16(52), u16(60), u16(60), u16(1405), u16(504),
	u16(537), u16(559), u16(1179), u16(961), u16(507), u16(129), u16(558), u16(127), u16(585),
	u16(1126), u16(4), u16(1126), u16(1125), u16(894), u16(1125), u16(162), u16(1062), u16(963),
	u16(359), u16(129), u16(1401), u16(363), u16(125), u16(125), u16(588), u16(366), u16(368),
	u16(370), u16(1349), u16(1334), u16(126), u16(1333), u16(464), u16(594), u16(464), u16(377),
	u16(387), u16(1050), u16(1391), u16(1414), u16(1618), u16(1459), u16(1387), u16(1399), u16(208),
	u16(580), u16(1464), u16(1314), u16(464), u16(243), u16(516), u16(1305), u16(1293), u16(1384),
	u16(1292), u16(1294), u16(1638), u16(288), u16(170), u16(228), u16(582), u16(12), u16(408),
	u16(321), u16(322), u16(241), u16(323), u16(245), u16(1446), u16(1050), u16(1050), u16(1052),
	u16(1053), u16(35), u16(559), u16(304), u16(350), u16(351), u16(501), u16(560), u16(127),
	u16(585), u16(1441), u16(4), u16(1451), u16(1434), u16(310), u16(1450), u16(526), u16(1062),
	u16(1332), u16(415), u16(380), u16(232), u16(1527), u16(125), u16(125), u16(588), u16(1214),
	u16(1396), u16(356), u16(1526), u16(583), u16(126), u16(1397), u16(464), u16(594), u16(464),
	u16(1641), u16(535), u16(1050), u16(1581), u16(1395), u16(1269), u16(1583), u16(1582), u16(213),
	u16(402), u16(277), u16(214), u16(227), u16(464), u16(1573), u16(239), u16(1571), u16(1266),
	u16(1394), u16(434), u16(198), u16(100), u16(224), u16(96), u16(183), u16(582), u16(191),
	u16(485), u16(193), u16(486), u16(194), u16(195), u16(196), u16(519), u16(1050), u16(1050),
	u16(1052), u16(1053), u16(35), u16(559), u16(113), u16(252), u16(413), u16(1447), u16(558),
	u16(493), u16(13), u16(1455), u16(416), u16(1453), u16(1452), u16(14), u16(202), u16(1521),
	u16(1062), u16(1532), u16(508), u16(258), u16(106), u16(514), u16(125), u16(125), u16(99),
	u16(1214), u16(1543), u16(289), u16(260), u16(206), u16(126), u16(365), u16(464), u16(594),
	u16(464), u16(361), u16(517), u16(1050), u16(261), u16(448), u16(1295), u16(262), u16(418),
	u16(1352), u16(1351), u16(108), u16(1350), u16(1655), u16(1654), u16(1343), u16(915), u16(419),
	u16(1322), u16(233), u16(452), u16(319), u16(379), u16(1321), u16(453), u16(1623), u16(320),
	u16(1320), u16(275), u16(1653), u16(544), u16(276), u16(1609), u16(1608), u16(1342), u16(1050),
	u16(1050), u16(1052), u16(1053), u16(35), u16(1630), u16(1218), u16(466), u16(385), u16(456),
	u16(300), u16(1419), u16(144), u16(1418), u16(570), u16(407), u16(407), u16(406), u16(284),
	u16(404), u16(11), u16(1508), u16(881), u16(396), u16(120), u16(127), u16(585), u16(394), u16(4),
	u16(1214), u16(327), u16(114), u16(1375), u16(1374), u16(220), u16(247), u16(400), u16(338),
	u16(401), u16(554), u16(42), u16(1224), u16(588), u16(596), u16(283), u16(337), u16(285),
	u16(286), u16(188), u16(597), u16(1290), u16(1285), u16(175), u16(1558), u16(176), u16(1559),
	u16(1557), u16(1556), u16(159), u16(317), u16(229), u16(177), u16(868), u16(230), u16(91),
	u16(465), u16(464), u16(221), u16(331), u16(468), u16(1165), u16(470), u16(473), u16(94),
	u16(244), u16(95), u16(249), u16(189), u16(582), u16(1124), u16(1122), u16(341), u16(427),
	u16(190), u16(178), u16(1249), u16(179), u16(43), u16(192), u16(947), u16(349), u16(428),
	u16(1138), u16(197), u16(251), u16(180), u16(181), u16(436), u16(102), u16(182), u16(438),
	u16(103), u16(104), u16(199), u16(248), u16(1140), u16(253), u16(1062), u16(105), u16(255),
	u16(1137), u16(166), u16(24), u16(125), u16(125), u16(257), u16(1264), u16(273), u16(360),
	u16(513), u16(259), u16(126), u16(15), u16(464), u16(594), u16(464), u16(204), u16(883),
	u16(1050), u16(518), u16(263), u16(373), u16(381), u16(92), u16(585), u16(1130), u16(4),
	u16(203), u16(205), u16(426), u16(107), u16(522), u16(25), u16(26), u16(329), u16(584), u16(913),
	u16(572), u16(527), u16(376), u16(588), u16(926), u16(530), u16(109), u16(184), u16(318),
	u16(167), u16(110), u16(27), u16(538), u16(1050), u16(1050), u16(1052), u16(1053), u16(35),
	u16(1211), u16(1091), u16(17), u16(476), u16(111), u16(1181), u16(234), u16(292), u16(1180),
	u16(464), u16(294), u16(207), u16(994), u16(129), u16(1201), u16(272), u16(1000), u16(28),
	u16(1197), u16(29), u16(30), u16(582), u16(1199), u16(1205), u16(1214), u16(31), u16(1204),
	u16(32), u16(1186), u16(41), u16(566), u16(33), u16(1105), u16(211), u16(8), u16(115), u16(1092),
	u16(1090), u16(1094), u16(34), u16(278), u16(578), u16(1095), u16(117), u16(122), u16(118),
	u16(1145), u16(36), u16(18), u16(128), u16(1062), u16(1055), u16(895), u16(957), u16(37),
	u16(589), u16(125), u16(125), u16(279), u16(186), u16(280), u16(1646), u16(157), u16(405),
	u16(126), u16(1220), u16(464), u16(594), u16(464), u16(1218), u16(466), u16(1050), u16(1219),
	u16(300), u16(1281), u16(1281), u16(1281), u16(1281), u16(407), u16(407), u16(406), u16(284),
	u16(404), u16(1281), u16(1281), u16(881), u16(1281), u16(300), u16(1281), u16(1281), u16(571),
	u16(1281), u16(407), u16(407), u16(406), u16(284), u16(404), u16(1281), u16(247), u16(881),
	u16(338), u16(1281), u16(1281), u16(1050), u16(1050), u16(1052), u16(1053), u16(35), u16(337),
	u16(1281), u16(1281), u16(1281), u16(247), u16(1281), u16(338), u16(1281), u16(1281), u16(1281),
	u16(1281), u16(1281), u16(1281), u16(1281), u16(337), u16(1281), u16(1281), u16(1281), u16(1281),
	u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1214), u16(1281), u16(1281),
	u16(1281), u16(1281), u16(1281), u16(1281), u16(249), u16(1281), u16(1281), u16(1281), u16(1281),
	u16(1281), u16(1281), u16(1281), u16(178), u16(1281), u16(1281), u16(43), u16(1281), u16(1281),
	u16(249), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(178),
	u16(1281), u16(1281), u16(43), u16(1281), u16(1281), u16(248), u16(1281), u16(1281), u16(1281),
	u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281),
	u16(1281), u16(1281), u16(248), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281),
	u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281),
	u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(426), u16(1281), u16(1281),
	u16(1281), u16(1281), u16(329), u16(584), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281),
	u16(1281), u16(1281), u16(426), u16(1281), u16(1281), u16(1281), u16(1281), u16(329), u16(584),
	u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(476),
	u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(1281),
	u16(1281), u16(1281), u16(1281), u16(1281), u16(1281), u16(476)]

@[export: 'yy_lookahead']
const yy_lookahead = [u16(277), u16(278), u16(279), u16(241), u16(242), u16(225), u16(195), u16(227),
	u16(195), u16(312), u16(195), u16(218), u16(195), u16(316), u16(195), u16(235), u16(254),
	u16(195), u16(256), u16(19), u16(297), u16(277), u16(278), u16(279), u16(218), u16(206),
	u16(213), u16(214), u16(206), u16(218), u16(219), u16(31), u16(206), u16(218), u16(219),
	u16(218), u16(219), u16(218), u16(219), u16(39), u16(218), u16(219), u16(195), u16(43), u16(44),
	u16(45), u16(195), u16(47), u16(48), u16(49), u16(50), u16(51), u16(52), u16(53), u16(54),
	u16(55), u16(56), u16(57), u16(58), u16(19), u16(241), u16(242), u16(195), u16(241), u16(242),
	u16(195), u16(255), u16(241), u16(242), u16(195), u16(255), u16(237), u16(238), u16(254),
	u16(255), u16(256), u16(254), u16(255), u16(256), u16(264), u16(254), u16(207), u16(256),
	u16(43), u16(44), u16(45), u16(264), u16(47), u16(48), u16(49), u16(50), u16(51), u16(52),
	u16(53), u16(54), u16(55), u16(56), u16(57), u16(58), u16(251), u16(287), u16(253), u16(215),
	u16(103), u16(104), u16(105), u16(106), u16(107), u16(108), u16(109), u16(110), u16(111),
	u16(112), u16(113), u16(114), u16(82), u16(265), u16(195), u16(271), u16(11), u16(187), u16(188),
	u16(189), u16(190), u16(191), u16(192), u16(190), u16(87), u16(192), u16(89), u16(197), u16(19),
	u16(199), u16(197), u16(317), u16(199), u16(319), u16(25), u16(271), u16(206), u16(218),
	u16(219), u16(206), u16(103), u16(104), u16(105), u16(106), u16(107), u16(108), u16(109),
	u16(110), u16(111), u16(112), u16(113), u16(114), u16(43), u16(44), u16(45), u16(195), u16(47),
	u16(48), u16(49), u16(50), u16(51), u16(52), u16(53), u16(54), u16(55), u16(56), u16(57),
	u16(58), u16(60), u16(139), u16(140), u16(241), u16(242), u16(289), u16(241), u16(242), u16(309),
	u16(310), u16(294), u16(70), u16(47), u16(48), u16(49), u16(50), u16(254), u16(77), u16(256),
	u16(254), u16(195), u16(256), u16(55), u16(56), u16(57), u16(58), u16(59), u16(221), u16(88),
	u16(109), u16(90), u16(269), u16(240), u16(93), u16(269), u16(107), u16(108), u16(109), u16(110),
	u16(111), u16(112), u16(113), u16(114), u16(215), u16(103), u16(104), u16(105), u16(106),
	u16(107), u16(108), u16(109), u16(110), u16(111), u16(112), u16(113), u16(114), u16(136),
	u16(117), u16(118), u16(119), u16(298), u16(141), u16(300), u16(298), u16(19), u16(300),
	u16(129), u16(130), u16(317), u16(318), u16(103), u16(104), u16(105), u16(106), u16(107),
	u16(108), u16(109), u16(110), u16(111), u16(112), u16(113), u16(114), u16(114), u16(277),
	u16(278), u16(279), u16(146), u16(122), u16(43), u16(44), u16(45), u16(195), u16(47), u16(48),
	u16(49), u16(50), u16(51), u16(52), u16(53), u16(54), u16(55), u16(56), u16(57), u16(58),
	u16(218), u16(277), u16(278), u16(279), u16(19), u16(19), u16(195), u16(286), u16(23), u16(68),
	u16(218), u16(219), u16(55), u16(56), u16(57), u16(58), u16(103), u16(104), u16(105), u16(106),
	u16(107), u16(108), u16(109), u16(110), u16(111), u16(112), u16(113), u16(114), u16(43), u16(44),
	u16(45), u16(232), u16(47), u16(48), u16(49), u16(50), u16(51), u16(52), u16(53), u16(54),
	u16(55), u16(56), u16(57), u16(58), u16(103), u16(104), u16(105), u16(106), u16(107), u16(108),
	u16(109), u16(110), u16(111), u16(112), u16(113), u16(114), u16(135), u16(60), u16(137),
	u16(138), u16(103), u16(104), u16(105), u16(106), u16(107), u16(108), u16(109), u16(110),
	u16(111), u16(112), u16(113), u16(114), u16(82), u16(281), u16(206), u16(195), u16(109),
	u16(110), u16(111), u16(112), u16(113), u16(114), u16(195), u16(195), u16(195), u16(205),
	u16(22), u16(207), u16(103), u16(104), u16(105), u16(106), u16(107), u16(108), u16(109),
	u16(110), u16(111), u16(112), u16(113), u16(114), u16(195), u16(60), u16(116), u16(117),
	u16(107), u16(108), u16(218), u16(219), u16(19), u16(241), u16(242), u16(121), u16(23), u16(116),
	u16(117), u16(118), u16(119), u16(306), u16(121), u16(308), u16(206), u16(234), u16(254),
	u16(15), u16(256), u16(195), u16(129), u16(259), u16(260), u16(139), u16(140), u16(145), u16(43),
	u16(44), u16(45), u16(200), u16(47), u16(48), u16(49), u16(50), u16(51), u16(52), u16(53),
	u16(54), u16(55), u16(56), u16(57), u16(58), u16(218), u16(219), u16(60), u16(154), u16(19),
	u16(156), u16(265), u16(241), u16(242), u16(24), u16(117), u16(118), u16(119), u16(120), u16(21),
	u16(73), u16(123), u16(124), u16(125), u16(74), u16(254), u16(61), u16(256), u16(107), u16(108),
	u16(221), u16(133), u16(82), u16(43), u16(44), u16(45), u16(195), u16(47), u16(48), u16(49),
	u16(50), u16(51), u16(52), u16(53), u16(54), u16(55), u16(56), u16(57), u16(58), u16(103),
	u16(104), u16(105), u16(106), u16(107), u16(108), u16(109), u16(110), u16(111), u16(112),
	u16(113), u16(114), u16(195), u16(317), u16(318), u16(117), u16(118), u16(119), u16(22),
	u16(120), u16(195), u16(22), u16(123), u16(124), u16(125), u16(19), u16(20), u16(284), u16(22),
	u16(128), u16(81), u16(288), u16(133), u16(195), u16(195), u16(218), u16(219), u16(277),
	u16(278), u16(279), u16(139), u16(140), u16(36), u16(195), u16(103), u16(104), u16(105),
	u16(106), u16(107), u16(108), u16(109), u16(110), u16(111), u16(112), u16(113), u16(114),
	u16(218), u16(219), u16(62), u16(60), u16(195), u16(241), u16(242), u16(271), u16(19), u16(240),
	u16(60), u16(189), u16(190), u16(191), u16(192), u16(233), u16(255), u16(124), u16(254),
	u16(197), u16(256), u16(199), u16(72), u16(129), u16(130), u16(264), u16(195), u16(195),
	u16(206), u16(22), u16(23), u16(60), u16(43), u16(44), u16(45), u16(206), u16(47), u16(48),
	u16(49), u16(50), u16(51), u16(52), u16(53), u16(54), u16(55), u16(56), u16(57), u16(58),
	u16(195), u16(218), u16(219), u16(101), u16(195), u16(60), u16(271), u16(162), u16(195),
	u16(107), u16(108), u16(109), u16(117), u16(118), u16(119), u16(241), u16(242), u16(115),
	u16(73), u16(117), u16(118), u16(119), u16(241), u16(242), u16(122), u16(60), u16(195), u16(266),
	u16(254), u16(312), u16(256), u16(218), u16(219), u16(316), u16(203), u16(254), u16(195),
	u16(256), u16(255), u16(208), u16(117), u16(118), u16(119), u16(269), u16(103), u16(104),
	u16(105), u16(106), u16(107), u16(108), u16(109), u16(110), u16(111), u16(112), u16(113),
	u16(114), u16(154), u16(155), u16(156), u16(157), u16(158), u16(102), u16(117), u16(118),
	u16(119), u16(19), u16(242), u16(144), u16(255), u16(23), u16(206), u16(24), u16(298), u16(195),
	u16(300), u16(206), u16(195), u16(264), u16(254), u16(206), u16(256), u16(240), u16(117),
	u16(118), u16(119), u16(183), u16(22), u16(22), u16(23), u16(43), u16(44), u16(45), u16(151),
	u16(47), u16(48), u16(49), u16(50), u16(51), u16(52), u16(53), u16(54), u16(55), u16(56),
	u16(57), u16(58), u16(241), u16(242), u16(60), u16(195), u16(19), u16(241), u16(242), u16(195),
	u16(23), u16(241), u16(242), u16(195), u16(152), u16(254), u16(310), u16(256), u16(243),
	u16(312), u16(254), u16(60), u16(256), u16(316), u16(254), u16(206), u16(256), u16(60), u16(218),
	u16(219), u16(43), u16(44), u16(45), u16(272), u16(47), u16(48), u16(49), u16(50), u16(51),
	u16(52), u16(53), u16(54), u16(55), u16(56), u16(57), u16(58), u16(103), u16(104), u16(105),
	u16(106), u16(107), u16(108), u16(109), u16(110), u16(111), u16(112), u16(113), u16(114),
	u16(240), u16(60), u16(241), u16(242), u16(118), u16(25), u16(102), u16(255), u16(166), u16(167),
	u16(101), u16(22), u16(26), u16(19), u16(20), u16(254), u16(22), u16(256), u16(139), u16(140),
	u16(117), u16(118), u16(119), u16(306), u16(195), u16(308), u16(117), u16(118), u16(237),
	u16(238), u16(36), u16(122), u16(103), u16(104), u16(105), u16(106), u16(107), u16(108),
	u16(109), u16(110), u16(111), u16(112), u16(113), u16(114), u16(195), u16(195), u16(60),
	u16(218), u16(219), u16(60), u16(109), u16(195), u16(19), u16(217), u16(60), u16(25), u16(23),
	u16(77), u16(117), u16(118), u16(119), u16(225), u16(233), u16(154), u16(155), u16(156), u16(72),
	u16(312), u16(218), u16(219), u16(90), u16(316), u16(22), u16(93), u16(303), u16(304), u16(43),
	u16(44), u16(45), u16(195), u16(47), u16(48), u16(49), u16(50), u16(51), u16(52), u16(53),
	u16(54), u16(55), u16(56), u16(57), u16(58), u16(183), u16(195), u16(195), u16(101), u16(19),
	u16(213), u16(214), u16(243), u16(23), u16(107), u16(108), u16(117), u16(118), u16(119),
	u16(117), u16(118), u16(119), u16(115), u16(60), u16(117), u16(118), u16(119), u16(195), u16(60),
	u16(122), u16(218), u16(219), u16(22), u16(43), u16(44), u16(45), u16(35), u16(47), u16(48),
	u16(49), u16(50), u16(51), u16(52), u16(53), u16(54), u16(55), u16(56), u16(57), u16(58),
	u16(103), u16(104), u16(105), u16(106), u16(107), u16(108), u16(109), u16(110), u16(111),
	u16(112), u16(113), u16(114), u16(154), u16(155), u16(156), u16(157), u16(158), u16(195),
	u16(255), u16(67), u16(195), u16(60), u16(101), u16(240), u16(311), u16(312), u16(306), u16(75),
	u16(308), u16(316), u16(29), u16(117), u16(118), u16(119), u16(33), u16(287), u16(117), u16(118),
	u16(119), u16(118), u16(146), u16(183), u16(195), u16(122), u16(103), u16(104), u16(105),
	u16(106), u16(107), u16(108), u16(109), u16(110), u16(111), u16(112), u16(113), u16(114),
	u16(215), u16(195), u16(77), u16(60), u16(25), u16(195), u16(122), u16(144), u16(19), u16(218),
	u16(219), u16(66), u16(23), u16(88), u16(246), u16(90), u16(132), u16(25), u16(93), u16(154),
	u16(155), u16(156), u16(117), u16(118), u16(119), u16(257), u16(195), u16(131), u16(218),
	u16(219), u16(195), u16(265), u16(43), u16(44), u16(45), u16(195), u16(47), u16(48), u16(49),
	u16(50), u16(51), u16(52), u16(53), u16(54), u16(55), u16(56), u16(57), u16(58), u16(183),
	u16(218), u16(219), u16(195), u16(19), u16(218), u16(219), u16(195), u16(23), u16(195), u16(218),
	u16(219), u16(117), u16(118), u16(119), u16(195), u16(233), u16(255), u16(195), u16(195),
	u16(233), u16(22), u16(23), u16(146), u16(25), u16(233), u16(218), u16(219), u16(43), u16(44),
	u16(45), u16(294), u16(47), u16(48), u16(49), u16(50), u16(51), u16(52), u16(53), u16(54),
	u16(55), u16(56), u16(57), u16(58), u16(103), u16(104), u16(105), u16(106), u16(107), u16(108),
	u16(109), u16(110), u16(111), u16(112), u16(113), u16(114), u16(195), u16(12), u16(234),
	u16(195), u16(240), u16(74), u16(195), u16(255), u16(195), u16(60), u16(243), u16(262), u16(263),
	u16(311), u16(312), u16(25), u16(27), u16(19), u16(316), u16(107), u16(108), u16(265), u16(24),
	u16(265), u16(195), u16(150), u16(195), u16(139), u16(140), u16(218), u16(219), u16(42),
	u16(103), u16(104), u16(105), u16(106), u16(107), u16(108), u16(109), u16(110), u16(111),
	u16(112), u16(113), u16(114), u16(233), u16(102), u16(67), u16(218), u16(219), u16(218),
	u16(219), u16(243), u16(19), u16(64), u16(22), u16(23), u16(23), u16(25), u16(195), u16(128),
	u16(129), u16(130), u16(233), u16(74), u16(233), u16(86), u16(154), u16(118), u16(156), u16(130),
	u16(265), u16(208), u16(19), u16(306), u16(95), u16(308), u16(43), u16(44), u16(45), u16(266),
	u16(47), u16(48), u16(49), u16(50), u16(51), u16(52), u16(53), u16(54), u16(55), u16(56),
	u16(57), u16(58), u16(153), u16(230), u16(96), u16(232), u16(43), u16(44), u16(45), u16(19),
	u16(47), u16(48), u16(49), u16(50), u16(51), u16(52), u16(53), u16(54), u16(55), u16(56),
	u16(57), u16(58), u16(114), u16(22), u16(306), u16(24), u16(308), u16(127), u16(120), u16(121),
	u16(122), u16(123), u16(124), u16(125), u16(126), u16(195), u16(147), u16(212), u16(213),
	u16(214), u16(132), u16(23), u16(195), u16(25), u16(102), u16(100), u16(103), u16(104), u16(105),
	u16(106), u16(107), u16(108), u16(109), u16(110), u16(111), u16(112), u16(113), u16(114),
	u16(218), u16(219), u16(19), u16(60), u16(195), u16(12), u16(210), u16(211), u16(103), u16(104),
	u16(105), u16(106), u16(107), u16(108), u16(109), u16(110), u16(111), u16(112), u16(113),
	u16(114), u16(27), u16(134), u16(195), u16(195), u16(195), u16(210), u16(211), u16(218),
	u16(219), u16(195), u16(47), u16(195), u16(212), u16(213), u16(214), u16(42), u16(16), u16(130),
	u16(19), u16(112), u16(113), u16(114), u16(23), u16(77), u16(195), u16(218), u16(219), u16(218),
	u16(219), u16(117), u16(163), u16(164), u16(218), u16(219), u16(218), u16(219), u16(90), u16(64),
	u16(19), u16(93), u16(153), u16(118), u16(43), u16(44), u16(45), u16(160), u16(47), u16(48),
	u16(49), u16(50), u16(51), u16(52), u16(53), u16(54), u16(55), u16(56), u16(57), u16(58),
	u16(195), u16(119), u16(272), u16(276), u16(43), u16(44), u16(45), u16(195), u16(47), u16(48),
	u16(49), u16(50), u16(51), u16(52), u16(53), u16(54), u16(55), u16(56), u16(57), u16(58),
	u16(78), u16(116), u16(80), u16(218), u16(219), u16(116), u16(144), u16(128), u16(129), u16(130),
	u16(218), u16(219), u16(61), u16(195), u16(47), u16(195), u16(16), u16(132), u16(195), u16(263),
	u16(195), u16(314), u16(315), u16(267), u16(103), u16(104), u16(105), u16(106), u16(107),
	u16(108), u16(109), u16(110), u16(111), u16(112), u16(113), u16(114), u16(218), u16(219),
	u16(218), u16(219), u16(151), u16(218), u16(219), u16(195), u16(103), u16(104), u16(105),
	u16(106), u16(107), u16(108), u16(109), u16(110), u16(111), u16(112), u16(113), u16(114),
	u16(210), u16(211), u16(195), u16(7), u16(8), u16(9), u16(195), u16(60), u16(195), u16(312),
	u16(218), u16(219), u16(195), u16(316), u16(195), u16(120), u16(195), u16(263), u16(19),
	u16(195), u16(125), u16(267), u16(78), u16(24), u16(80), u16(218), u16(219), u16(116), u16(162),
	u16(218), u16(219), u16(218), u16(219), u16(301), u16(302), u16(218), u16(219), u16(195),
	u16(19), u16(218), u16(219), u16(276), u16(43), u16(44), u16(45), u16(160), u16(47), u16(48),
	u16(49), u16(50), u16(51), u16(52), u16(53), u16(54), u16(55), u16(56), u16(57), u16(58),
	u16(19), u16(146), u16(218), u16(219), u16(43), u16(44), u16(45), u16(118), u16(47), u16(48),
	u16(49), u16(50), u16(51), u16(52), u16(53), u16(54), u16(55), u16(56), u16(57), u16(58),
	u16(165), u16(314), u16(315), u16(276), u16(43), u16(44), u16(45), u16(266), u16(47), u16(48),
	u16(49), u16(50), u16(51), u16(52), u16(53), u16(54), u16(55), u16(56), u16(57), u16(58),
	u16(128), u16(129), u16(130), u16(195), u16(103), u16(104), u16(105), u16(106), u16(107),
	u16(108), u16(109), u16(110), u16(111), u16(112), u16(113), u16(114), u16(195), u16(228),
	u16(195), u16(61), u16(195), u16(314), u16(315), u16(25), u16(103), u16(104), u16(105), u16(106),
	u16(107), u16(108), u16(109), u16(110), u16(111), u16(112), u16(113), u16(114), u16(195),
	u16(22), u16(195), u16(218), u16(219), u16(218), u16(219), u16(195), u16(103), u16(104),
	u16(105), u16(106), u16(107), u16(108), u16(109), u16(110), u16(111), u16(112), u16(113),
	u16(114), u16(195), u16(195), u16(246), u16(218), u16(219), u16(218), u16(219), u16(25), u16(19),
	u16(246), u16(218), u16(219), u16(246), u16(257), u16(259), u16(260), u16(195), u16(22),
	u16(266), u16(60), u16(257), u16(195), u16(120), u16(257), u16(218), u16(219), u16(116),
	u16(195), u16(19), u16(195), u16(150), u16(151), u16(25), u16(44), u16(45), u16(266), u16(47),
	u16(48), u16(49), u16(50), u16(51), u16(52), u16(53), u16(54), u16(55), u16(56), u16(57),
	u16(58), u16(195), u16(54), u16(218), u16(219), u16(218), u16(219), u16(45), u16(145), u16(47),
	u16(48), u16(49), u16(50), u16(51), u16(52), u16(53), u16(54), u16(55), u16(56), u16(57),
	u16(58), u16(246), u16(121), u16(122), u16(218), u16(219), u16(19), u16(23), u16(31), u16(25),
	u16(118), u16(159), u16(257), u16(161), u16(24), u16(195), u16(39), u16(195), u16(143), u16(195),
	u16(19), u16(20), u16(22), u16(22), u16(24), u16(103), u16(104), u16(105), u16(106), u16(107),
	u16(108), u16(109), u16(110), u16(111), u16(112), u16(113), u16(114), u16(36), u16(218),
	u16(219), u16(218), u16(219), u16(218), u16(219), u16(195), u16(103), u16(104), u16(105),
	u16(106), u16(107), u16(108), u16(109), u16(110), u16(111), u16(112), u16(113), u16(114),
	u16(195), u16(143), u16(119), u16(136), u16(60), u16(195), u16(22), u16(195), u16(141), u16(195),
	u16(218), u16(219), u16(195), u16(23), u16(195), u16(25), u16(72), u16(23), u16(131), u16(25),
	u16(195), u16(134), u16(23), u16(218), u16(219), u16(195), u16(82), u16(144), u16(218), u16(219),
	u16(218), u16(219), u16(218), u16(219), u16(195), u16(218), u16(219), u16(218), u16(219),
	u16(60), u16(23), u16(195), u16(25), u16(218), u16(219), u16(101), u16(195), u16(117), u16(218),
	u16(219), u16(195), u16(107), u16(108), u16(23), u16(195), u16(25), u16(195), u16(218), u16(219),
	u16(115), u16(228), u16(117), u16(118), u16(119), u16(218), u16(219), u16(122), u16(195),
	u16(19), u16(218), u16(219), u16(195), u16(60), u16(218), u16(219), u16(142), u16(195), u16(218),
	u16(219), u16(19), u16(20), u16(195), u16(22), u16(139), u16(140), u16(23), u16(23), u16(25),
	u16(25), u16(195), u16(218), u16(219), u16(7), u16(8), u16(218), u16(219), u16(36), u16(118),
	u16(154), u16(155), u16(156), u16(157), u16(158), u16(195), u16(23), u16(195), u16(25), u16(84),
	u16(85), u16(49), u16(195), u16(23), u16(195), u16(25), u16(195), u16(23), u16(195), u16(25),
	u16(195), u16(23), u16(60), u16(25), u16(23), u16(23), u16(25), u16(25), u16(142), u16(183),
	u16(218), u16(219), u16(118), u16(195), u16(72), u16(218), u16(219), u16(218), u16(219),
	u16(218), u16(219), u16(218), u16(219), u16(218), u16(219), u16(195), u16(195), u16(146),
	u16(86), u16(98), u16(23), u16(195), u16(25), u16(91), u16(19), u16(20), u16(154), u16(22),
	u16(156), u16(154), u16(23), u16(156), u16(25), u16(101), u16(23), u16(195), u16(25), u16(195),
	u16(195), u16(107), u16(108), u16(36), u16(195), u16(195), u16(195), u16(195), u16(228),
	u16(115), u16(195), u16(117), u16(118), u16(119), u16(195), u16(195), u16(122), u16(261),
	u16(195), u16(321), u16(195), u16(195), u16(195), u16(258), u16(238), u16(195), u16(195),
	u16(60), u16(299), u16(291), u16(195), u16(195), u16(258), u16(195), u16(195), u16(195),
	u16(290), u16(244), u16(216), u16(72), u16(245), u16(193), u16(258), u16(258), u16(299),
	u16(258), u16(299), u16(274), u16(154), u16(155), u16(156), u16(157), u16(158), u16(86),
	u16(247), u16(295), u16(248), u16(295), u16(91), u16(19), u16(20), u16(270), u16(22), u16(274),
	u16(270), u16(248), u16(274), u16(222), u16(101), u16(227), u16(274), u16(221), u16(231),
	u16(221), u16(107), u16(108), u16(36), u16(183), u16(262), u16(247), u16(221), u16(283),
	u16(115), u16(262), u16(117), u16(118), u16(119), u16(198), u16(116), u16(122), u16(220),
	u16(262), u16(61), u16(220), u16(220), u16(251), u16(247), u16(142), u16(251), u16(245), u16(60),
	u16(202), u16(299), u16(202), u16(38), u16(262), u16(202), u16(22), u16(152), u16(151), u16(296),
	u16(43), u16(72), u16(236), u16(18), u16(239), u16(202), u16(239), u16(239), u16(239), u16(18),
	u16(154), u16(155), u16(156), u16(157), u16(158), u16(86), u16(150), u16(201), u16(248),
	u16(275), u16(91), u16(248), u16(273), u16(236), u16(248), u16(275), u16(275), u16(273),
	u16(236), u16(248), u16(101), u16(286), u16(202), u16(201), u16(159), u16(63), u16(107),
	u16(108), u16(296), u16(183), u16(293), u16(202), u16(201), u16(22), u16(115), u16(202),
	u16(117), u16(118), u16(119), u16(292), u16(223), u16(122), u16(201), u16(65), u16(202),
	u16(201), u16(223), u16(220), u16(220), u16(22), u16(220), u16(226), u16(226), u16(229),
	u16(127), u16(223), u16(220), u16(166), u16(24), u16(285), u16(220), u16(222), u16(114),
	u16(315), u16(285), u16(220), u16(202), u16(220), u16(307), u16(92), u16(320), u16(320),
	u16(229), u16(154), u16(155), u16(156), u16(157), u16(158), u16(0), u16(1), u16(2), u16(223),
	u16(83), u16(5), u16(268), u16(149), u16(268), u16(146), u16(10), u16(11), u16(12), u16(13),
	u16(14), u16(22), u16(280), u16(17), u16(202), u16(159), u16(19), u16(20), u16(251), u16(22),
	u16(183), u16(282), u16(148), u16(252), u16(252), u16(250), u16(30), u16(249), u16(32), u16(248),
	u16(147), u16(25), u16(13), u16(36), u16(204), u16(196), u16(40), u16(196), u16(6), u16(302),
	u16(194), u16(194), u16(194), u16(209), u16(215), u16(209), u16(215), u16(215), u16(215),
	u16(224), u16(224), u16(216), u16(209), u16(4), u16(216), u16(215), u16(3), u16(60), u16(22),
	u16(122), u16(19), u16(122), u16(19), u16(125), u16(22), u16(15), u16(22), u16(71), u16(16),
	u16(72), u16(23), u16(23), u16(140), u16(305), u16(152), u16(79), u16(25), u16(131), u16(82),
	u16(143), u16(20), u16(16), u16(305), u16(1), u16(143), u16(145), u16(131), u16(131), u16(62),
	u16(54), u16(131), u16(37), u16(54), u16(54), u16(152), u16(99), u16(117), u16(34), u16(101),
	u16(54), u16(24), u16(1), u16(5), u16(22), u16(107), u16(108), u16(116), u16(76), u16(25),
	u16(162), u16(41), u16(142), u16(115), u16(24), u16(117), u16(118), u16(119), u16(116), u16(20),
	u16(122), u16(19), u16(126), u16(23), u16(132), u16(19), u16(20), u16(69), u16(22), u16(69),
	u16(22), u16(134), u16(22), u16(68), u16(22), u16(22), u16(139), u16(140), u16(60), u16(141),
	u16(68), u16(24), u16(36), u16(28), u16(97), u16(22), u16(37), u16(68), u16(23), u16(150),
	u16(34), u16(22), u16(154), u16(155), u16(156), u16(157), u16(158), u16(23), u16(23), u16(22),
	u16(163), u16(25), u16(23), u16(142), u16(23), u16(98), u16(60), u16(23), u16(22), u16(144),
	u16(25), u16(76), u16(34), u16(117), u16(34), u16(89), u16(34), u16(34), u16(72), u16(87),
	u16(76), u16(183), u16(34), u16(94), u16(34), u16(23), u16(22), u16(24), u16(34), u16(23),
	u16(25), u16(44), u16(25), u16(23), u16(23), u16(23), u16(22), u16(22), u16(25), u16(11),
	u16(143), u16(25), u16(143), u16(23), u16(22), u16(22), u16(22), u16(101), u16(23), u16(23),
	u16(136), u16(22), u16(25), u16(107), u16(108), u16(142), u16(25), u16(142), u16(142), u16(23),
	u16(15), u16(115), u16(1), u16(117), u16(118), u16(119), u16(1), u16(2), u16(122), u16(1),
	u16(5), u16(322), u16(322), u16(322), u16(322), u16(10), u16(11), u16(12), u16(13), u16(14),
	u16(322), u16(322), u16(17), u16(322), u16(5), u16(322), u16(322), u16(141), u16(322), u16(10),
	u16(11), u16(12), u16(13), u16(14), u16(322), u16(30), u16(17), u16(32), u16(322), u16(322),
	u16(154), u16(155), u16(156), u16(157), u16(158), u16(40), u16(322), u16(322), u16(322), u16(30),
	u16(322), u16(32), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(40),
	u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322),
	u16(183), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(71), u16(322),
	u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(79), u16(322), u16(322), u16(82),
	u16(322), u16(322), u16(71), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322),
	u16(322), u16(79), u16(322), u16(322), u16(82), u16(322), u16(322), u16(99), u16(322), u16(322),
	u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322),
	u16(322), u16(322), u16(99), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322),
	u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322),
	u16(322), u16(322), u16(322), u16(322), u16(322), u16(134), u16(322), u16(322), u16(322),
	u16(322), u16(139), u16(140), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322),
	u16(322), u16(134), u16(322), u16(322), u16(322), u16(322), u16(139), u16(140), u16(322),
	u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(163), u16(322),
	u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322),
	u16(322), u16(322), u16(322), u16(163), u16(322), u16(322), u16(322), u16(322), u16(322),
	u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322),
	u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(322),
	u16(322), u16(322), u16(322), u16(322), u16(322), u16(322), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187), u16(187),
	u16(187), u16(187)]

@[export: 'yy_shift_ofst']
const yy_shift_ofst = [u16(2201), u16(1973), u16(2215), u16(1552), u16(1552), u16(33), u16(368),
	u16(1668), u16(1741), u16(1814), u16(726), u16(726), u16(726), u16(265), u16(33), u16(33),
	u16(33), u16(33), u16(33), u16(0), u16(0), u16(216), u16(1349), u16(726), u16(726), u16(726),
	u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726),
	u16(726), u16(726), u16(726), u16(272), u16(272), u16(111), u16(111), u16(316), u16(365),
	u16(516), u16(867), u16(867), u16(916), u16(916), u16(916), u16(916), u16(40), u16(112),
	u16(260), u16(364), u16(408), u16(512), u16(617), u16(661), u16(765), u16(809), u16(913),
	u16(957), u16(1061), u16(1081), u16(1195), u16(1215), u16(1329), u16(1349), u16(1349), u16(1349),
	u16(1349), u16(1349), u16(1349), u16(1349), u16(1349), u16(1349), u16(1349), u16(1349),
	u16(1349), u16(1349), u16(1349), u16(1349), u16(1349), u16(1349), u16(1349), u16(1369),
	u16(1349), u16(1473), u16(1493), u16(1493), u16(473), u16(1974), u16(2082), u16(726), u16(726),
	u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726),
	u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726),
	u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726),
	u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726),
	u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726), u16(726),
	u16(726), u16(726), u16(726), u16(726), u16(726), u16(138), u16(232), u16(232), u16(232),
	u16(232), u16(232), u16(232), u16(232), u16(188), u16(99), u16(242), u16(718), u16(416),
	u16(1159), u16(867), u16(867), u16(940), u16(940), u16(867), u16(1103), u16(417), u16(574),
	u16(574), u16(574), u16(611), u16(139), u16(139), u16(2379), u16(2379), u16(1026), u16(1026),
	u16(1026), u16(536), u16(466), u16(466), u16(466), u16(466), u16(1017), u16(1017), u16(849),
	u16(718), u16(971), u16(1060), u16(867), u16(867), u16(867), u16(867), u16(867), u16(867),
	u16(867), u16(867), u16(867), u16(867), u16(867), u16(867), u16(867), u16(867), u16(867),
	u16(867), u16(867), u16(867), u16(867), u16(261), u16(712), u16(712), u16(867), u16(108),
	u16(1142), u16(1142), u16(977), u16(1108), u16(1108), u16(977), u16(977), u16(1243), u16(2379),
	u16(2379), u16(2379), u16(2379), u16(2379), u16(2379), u16(2379), u16(641), u16(789), u16(789),
	u16(635), u16(366), u16(721), u16(673), u16(782), u16(494), u16(787), u16(829), u16(867),
	u16(867), u16(867), u16(867), u16(867), u16(867), u16(867), u16(867), u16(867), u16(867),
	u16(867), u16(959), u16(867), u16(867), u16(867), u16(867), u16(867), u16(867), u16(867),
	u16(867), u16(867), u16(867), u16(867), u16(867), u16(867), u16(867), u16(820), u16(820),
	u16(820), u16(867), u16(867), u16(867), u16(1136), u16(867), u16(867), u16(867), u16(1119),
	u16(1007), u16(867), u16(1169), u16(867), u16(867), u16(867), u16(867), u16(867), u16(867),
	u16(867), u16(867), u16(1225), u16(1153), u16(869), u16(196), u16(618), u16(618), u16(618),
	u16(618), u16(1491), u16(196), u16(196), u16(91), u16(339), u16(1326), u16(1386), u16(383),
	u16(1163), u16(1364), u16(1426), u16(1364), u16(1538), u16(903), u16(1163), u16(1163), u16(903),
	u16(1163), u16(1426), u16(1538), u16(1018), u16(1535), u16(1241), u16(1528), u16(1528),
	u16(1528), u16(1394), u16(1394), u16(1394), u16(1394), u16(762), u16(762), u16(1403), u16(1466),
	u16(1475), u16(1551), u16(1746), u16(1805), u16(1746), u16(1746), u16(1729), u16(1729),
	u16(1840), u16(1840), u16(1729), u16(1730), u16(1732), u16(1859), u16(1842), u16(1870),
	u16(1870), u16(1870), u16(1870), u16(1729), u16(1876), u16(1751), u16(1732), u16(1732),
	u16(1751), u16(1859), u16(1842), u16(1751), u16(1842), u16(1751), u16(1729), u16(1876),
	u16(1760), u16(1857), u16(1729), u16(1876), u16(1906), u16(1729), u16(1876), u16(1729),
	u16(1876), u16(1906), u16(1746), u16(1746), u16(1746), u16(1873), u16(1922), u16(1922),
	u16(1906), u16(1746), u16(1822), u16(1746), u16(1873), u16(1746), u16(1746), u16(1786),
	u16(1929), u16(1843), u16(1843), u16(1906), u16(1729), u16(1872), u16(1872), u16(1894),
	u16(1894), u16(1831), u16(1836), u16(1966), u16(1729), u16(1833), u16(1831), u16(1851),
	u16(1860), u16(1751), u16(1983), u16(1996), u16(1996), u16(2009), u16(2009), u16(2009),
	u16(2379), u16(2379), u16(2379), u16(2379), u16(2379), u16(2379), u16(2379), u16(2379),
	u16(2379), u16(2379), u16(2379), u16(2379), u16(2379), u16(2379), u16(2379), u16(136), u16(1063),
	u16(1196), u16(530), u16(636), u16(1274), u16(1300), u16(1443), u16(1598), u16(1495), u16(1479),
	u16(967), u16(1083), u16(1602), u16(463), u16(1625), u16(1638), u16(1670), u16(1541), u16(1671),
	u16(1689), u16(1696), u16(1277), u16(1432), u16(1693), u16(808), u16(1700), u16(1607), u16(1657),
	u16(1587), u16(1704), u16(1707), u16(1631), u16(1708), u16(1733), u16(1608), u16(1611),
	u16(1743), u16(1747), u16(1620), u16(1592), u16(2026), u16(2030), u16(2013), u16(1914),
	u16(2018), u16(1916), u16(2020), u16(2019), u16(2021), u16(1915), u16(2027), u16(2029),
	u16(2024), u16(2025), u16(1909), u16(1899), u16(1923), u16(2028), u16(2028), u16(1913),
	u16(2037), u16(1917), u16(2042), u16(2059), u16(1918), u16(1932), u16(2028), u16(1933),
	u16(2003), u16(2031), u16(2028), u16(1919), u16(2012), u16(2015), u16(2016), u16(2022),
	u16(1936), u16(1956), u16(2040), u16(2053), u16(2077), u16(2074), u16(2058), u16(1967),
	u16(1924), u16(2034), u16(2060), u16(2036), u16(2008), u16(2046), u16(1946), u16(1978),
	u16(2066), u16(2075), u16(2078), u16(1968), u16(1972), u16(2084), u16(2041), u16(2086),
	u16(2088), u16(2076), u16(2089), u16(2048), u16(2054), u16(2093), u16(2023), u16(2091),
	u16(2099), u16(2055), u16(2085), u16(2101), u16(2092), u16(1975), u16(2105), u16(2110),
	u16(2111), u16(2112), u16(2115), u16(2113), u16(2043), u16(1997), u16(2117), u16(2120),
	u16(2032), u16(2114), u16(2122), u16(2001), u16(2121), u16(2116), u16(2118), u16(2119),
	u16(2124), u16(2062), u16(2071), u16(2068), u16(2123), u16(2080), u16(2065), u16(2126),
	u16(2138), u16(2140), u16(2139), u16(2141), u16(2143), u16(2130), u16(2033), u16(2035),
	u16(2142), u16(2121), u16(2146), u16(2147), u16(2148), u16(2150), u16(2149), u16(2152),
	u16(2156), u16(2151), u16(2164), u16(2158), u16(2159), u16(2161), u16(2162), u16(2160),
	u16(2165), u16(2163), u16(2050), u16(2049), u16(2051), u16(2052), u16(2167), u16(2172),
	u16(2181), u16(2197), u16(2204)]

@[export: 'yy_reduce_ofst']
const yy_reduce_ofst = [i16(-67), i16(345), i16(-64), i16(-178), i16(-181), i16(143), i16(435),
	i16(-78), i16(-183), i16(163), i16(-185), i16(284), i16(384), i16(-174), i16(189), i16(352),
	i16(440), i16(444), i16(493), i16(-23), i16(227), i16(-277), i16(-1), i16(305), i16(561),
	i16(755), i16(759), i16(764), i16(-189), i16(839), i16(857), i16(354), i16(484), i16(859),
	i16(631), i16(67), i16(734), i16(780), i16(-187), i16(616), i16(581), i16(730), i16(891),
	i16(449), i16(588), i16(795), i16(836), i16(-238), i16(287), i16(-238), i16(287), i16(-256),
	i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(-256),
	i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(-256),
	i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(-256),
	i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(-256),
	i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(205), i16(582),
	i16(715), i16(958), i16(985), i16(1003), i16(1005), i16(1010), i16(1012), i16(1059), i16(1066),
	i16(1092), i16(1094), i16(1097), i16(1122), i16(1137), i16(1141), i16(1143), i16(1147),
	i16(1151), i16(1172), i16(1249), i16(1251), i16(1269), i16(1271), i16(1276), i16(1290),
	i16(1316), i16(1318), i16(1337), i16(1371), i16(1373), i16(1375), i16(1400), i16(1413),
	i16(1418), i16(1420), i16(1422), i16(1425), i16(1427), i16(1433), i16(1438), i16(1447),
	i16(1454), i16(1459), i16(1463), i16(1467), i16(1480), i16(1484), i16(1518), i16(1523),
	i16(1525), i16(1527), i16(1529), i16(1531), i16(-256), i16(-256), i16(-256), i16(-256),
	i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(-256), i16(155), i16(210),
	i16(-220), i16(86), i16(-130), i16(943), i16(996), i16(402), i16(-256), i16(-113), i16(981),
	i16(1095), i16(1135), i16(395), i16(-256), i16(-256), i16(-256), i16(-256), i16(568), i16(568),
	i16(568), i16(-4), i16(-153), i16(-133), i16(259), i16(306), i16(-166), i16(523), i16(-303),
	i16(-126), i16(503), i16(503), i16(-37), i16(-149), i16(164), i16(690), i16(292), i16(412),
	i16(492), i16(651), i16(784), i16(332), i16(786), i16(841), i16(1149), i16(833), i16(1236),
	i16(792), i16(162), i16(796), i16(1253), i16(777), i16(288), i16(381), i16(380), i16(709),
	i16(487), i16(1027), i16(972), i16(1030), i16(1084), i16(991), i16(1120), i16(-152), i16(1062),
	i16(692), i16(1240), i16(1247), i16(1250), i16(1239), i16(1306), i16(-207), i16(-194), i16(57),
	i16(180), i16(74), i16(315), i16(355), i16(376), i16(452), i16(488), i16(630), i16(693),
	i16(965), i16(1004), i16(1025), i16(1099), i16(1154), i16(1289), i16(1305), i16(1310), i16(1469),
	i16(1489), i16(984), i16(1494), i16(1502), i16(1516), i16(1544), i16(1556), i16(1557), i16(1562),
	i16(1576), i16(1578), i16(1579), i16(1583), i16(1584), i16(1585), i16(1586), i16(1217),
	i16(1440), i16(1554), i16(1589), i16(1593), i16(1594), i16(1530), i16(1597), i16(1599),
	i16(1600), i16(1539), i16(1472), i16(1601), i16(1560), i16(1604), i16(355), i16(1605), i16(1609),
	i16(1610), i16(1612), i16(1613), i16(1614), i16(1503), i16(1512), i16(1520), i16(1567),
	i16(1548), i16(1558), i16(1559), i16(1561), i16(1530), i16(1567), i16(1567), i16(1569),
	i16(1596), i16(1622), i16(1519), i16(1521), i16(1547), i16(1565), i16(1581), i16(1568),
	i16(1534), i16(1582), i16(1563), i16(1566), i16(1591), i16(1570), i16(1606), i16(1536),
	i16(1619), i16(1615), i16(1616), i16(1624), i16(1626), i16(1633), i16(1590), i16(1595),
	i16(1603), i16(1617), i16(1618), i16(1621), i16(1572), i16(1623), i16(1628), i16(1663),
	i16(1644), i16(1577), i16(1647), i16(1648), i16(1673), i16(1675), i16(1588), i16(1627),
	i16(1678), i16(1630), i16(1629), i16(1634), i16(1651), i16(1650), i16(1652), i16(1653),
	i16(1654), i16(1688), i16(1701), i16(1655), i16(1635), i16(1636), i16(1658), i16(1639),
	i16(1672), i16(1661), i16(1677), i16(1666), i16(1715), i16(1717), i16(1632), i16(1642),
	i16(1724), i16(1726), i16(1712), i16(1728), i16(1736), i16(1737), i16(1739), i16(1718),
	i16(1722), i16(1723), i16(1725), i16(1719), i16(1720), i16(1721), i16(1727), i16(1731),
	i16(1734), i16(1735), i16(1738), i16(1740), i16(1742), i16(1643), i16(1656), i16(1669),
	i16(1674), i16(1753), i16(1759), i16(1645), i16(1646), i16(1711), i16(1713), i16(1748),
	i16(1744), i16(1709), i16(1789), i16(1716), i16(1749), i16(1752), i16(1755), i16(1758),
	i16(1807), i16(1816), i16(1818), i16(1823), i16(1824), i16(1825), i16(1745), i16(1754),
	i16(1714), i16(1811), i16(1806), i16(1808), i16(1809), i16(1810), i16(1813), i16(1802),
	i16(1803), i16(1812), i16(1815), i16(1817), i16(1820)]

@[export: 'yy_default']
const yy_default = [u16(1691), u16(1691), u16(1691), u16(1516), u16(1279), u16(1392), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1516), u16(1516), u16(1516), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1422), u16(1422), u16(1568), u16(1312),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1515), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1607), u16(1607), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1592), u16(1591), u16(1279), u16(1279), u16(1279), u16(1431), u16(1279), u16(1279),
	u16(1279), u16(1438), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1517),
	u16(1518), u16(1279), u16(1279), u16(1279), u16(1279), u16(1567), u16(1569), u16(1533),
	u16(1445), u16(1444), u16(1443), u16(1442), u16(1551), u16(1410), u16(1436), u16(1429),
	u16(1433), u16(1512), u16(1513), u16(1511), u16(1670), u16(1518), u16(1517), u16(1279),
	u16(1432), u16(1480), u16(1496), u16(1479), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1488), u16(1495), u16(1494), u16(1493), u16(1502),
	u16(1492), u16(1489), u16(1482), u16(1481), u16(1483), u16(1484), u16(1303), u16(1300),
	u16(1354), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1485), u16(1312),
	u16(1473), u16(1472), u16(1471), u16(1279), u16(1499), u16(1486), u16(1498), u16(1497),
	u16(1575), u16(1644), u16(1643), u16(1534), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1607), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1412), u16(1607), u16(1607), u16(1279), u16(1312), u16(1607), u16(1607),
	u16(1308), u16(1413), u16(1413), u16(1308), u16(1308), u16(1416), u16(1587), u16(1383),
	u16(1383), u16(1383), u16(1383), u16(1392), u16(1383), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1572), u16(1570), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1388), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1637),
	u16(1683), u16(1279), u16(1546), u16(1368), u16(1388), u16(1388), u16(1388), u16(1388),
	u16(1390), u16(1369), u16(1367), u16(1382), u16(1313), u16(1286), u16(1683), u16(1683),
	u16(1448), u16(1437), u16(1389), u16(1437), u16(1680), u16(1435), u16(1448), u16(1448),
	u16(1435), u16(1448), u16(1389), u16(1680), u16(1329), u16(1659), u16(1324), u16(1422),
	u16(1422), u16(1422), u16(1412), u16(1412), u16(1412), u16(1412), u16(1416), u16(1416),
	u16(1514), u16(1389), u16(1382), u16(1279), u16(1355), u16(1683), u16(1355), u16(1355),
	u16(1398), u16(1398), u16(1682), u16(1682), u16(1398), u16(1534), u16(1667), u16(1457),
	u16(1357), u16(1363), u16(1363), u16(1363), u16(1363), u16(1398), u16(1297), u16(1435),
	u16(1667), u16(1667), u16(1435), u16(1457), u16(1357), u16(1435), u16(1357), u16(1435),
	u16(1398), u16(1297), u16(1550), u16(1678), u16(1398), u16(1297), u16(1524), u16(1398),
	u16(1297), u16(1398), u16(1297), u16(1524), u16(1355), u16(1355), u16(1355), u16(1344),
	u16(1279), u16(1279), u16(1524), u16(1355), u16(1329), u16(1355), u16(1344), u16(1355),
	u16(1355), u16(1625), u16(1279), u16(1528), u16(1528), u16(1524), u16(1398), u16(1617),
	u16(1617), u16(1425), u16(1425), u16(1430), u16(1416), u16(1519), u16(1398), u16(1279),
	u16(1430), u16(1428), u16(1426), u16(1435), u16(1347), u16(1640), u16(1640), u16(1636),
	u16(1636), u16(1636), u16(1688), u16(1688), u16(1587), u16(1652), u16(1312), u16(1312),
	u16(1312), u16(1312), u16(1652), u16(1331), u16(1331), u16(1313), u16(1313), u16(1312),
	u16(1652), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1647), u16(1279), u16(1279), u16(1535), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1402), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1593), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1462), u16(1279), u16(1282), u16(1584), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1439), u16(1440), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1454), u16(1279), u16(1279), u16(1279),
	u16(1449), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1403), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1549), u16(1548), u16(1279), u16(1279), u16(1400), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1327), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1427), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1622), u16(1417), u16(1279), u16(1279), u16(1279), u16(1279), u16(1671),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1377), u16(1279), u16(1279), u16(1279),
	u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1279), u16(1663),
	u16(1371), u16(1463), u16(1279), u16(1466), u16(1301), u16(1279), u16(1291), u16(1279),
	u16(1279)]

@[export: 'yyFallback']
const yy_fallback = [u16(0), u16(0), u16(60), u16(60), u16(60), u16(60), u16(0), u16(60), u16(60),
	u16(60), u16(0), u16(60), u16(60), u16(60), u16(60), u16(0), u16(0), u16(0), u16(60), u16(0),
	u16(0), u16(60), u16(0), u16(0), u16(0), u16(0), u16(60), u16(60), u16(60), u16(60), u16(60),
	u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60),
	u16(60), u16(60), u16(0), u16(0), u16(0), u16(0), u16(60), u16(60), u16(0), u16(0), u16(0),
	u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(60), u16(60),
	u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60),
	u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60),
	u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60),
	u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(60), u16(0), u16(0),
	u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0),
	u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0),
	u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0),
	u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0),
	u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0),
	u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0),
	u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0), u16(0)]

@[export: 'yyRuleInfoLhs']
const yy_rule_info_lhs = [u16(191), u16(191), u16(190), u16(192), u16(193), u16(193), u16(193),
	u16(193), u16(192), u16(192), u16(192), u16(192), u16(192), u16(197), u16(199), u16(201),
	u16(201), u16(200), u16(200), u16(198), u16(198), u16(205), u16(205), u16(207), u16(207),
	u16(208), u16(210), u16(210), u16(210), u16(211), u16(215), u16(216), u16(217), u16(217),
	u16(217), u16(217), u16(217), u16(217), u16(217), u16(217), u16(217), u16(217), u16(217),
	u16(217), u16(217), u16(226), u16(226), u16(222), u16(222), u16(224), u16(224), u16(227),
	u16(227), u16(227), u16(227), u16(228), u16(228), u16(228), u16(228), u16(228), u16(225),
	u16(225), u16(229), u16(229), u16(229), u16(204), u16(231), u16(232), u16(232), u16(232),
	u16(232), u16(232), u16(235), u16(220), u16(220), u16(236), u16(236), u16(237), u16(237),
	u16(192), u16(239), u16(239), u16(192), u16(192), u16(192), u16(206), u16(206), u16(206),
	u16(241), u16(244), u16(244), u16(244), u16(242), u16(242), u16(254), u16(242), u16(256),
	u16(256), u16(245), u16(245), u16(245), u16(257), u16(246), u16(246), u16(246), u16(258),
	u16(258), u16(247), u16(247), u16(260), u16(260), u16(259), u16(259), u16(259), u16(259),
	u16(259), u16(202), u16(202), u16(240), u16(240), u16(265), u16(265), u16(265), u16(265),
	u16(261), u16(261), u16(261), u16(261), u16(262), u16(262), u16(262), u16(267), u16(263),
	u16(263), u16(251), u16(251), u16(233), u16(233), u16(221), u16(221), u16(221), u16(268),
	u16(268), u16(268), u16(249), u16(249), u16(250), u16(250), u16(252), u16(252), u16(252),
	u16(252), u16(192), u16(248), u16(248), u16(270), u16(270), u16(270), u16(270), u16(192),
	u16(271), u16(271), u16(271), u16(271), u16(192), u16(192), u16(274), u16(274), u16(274),
	u16(274), u16(274), u16(274), u16(275), u16(272), u16(272), u16(273), u16(273), u16(266),
	u16(266), u16(219), u16(219), u16(219), u16(219), u16(218), u16(218), u16(218), u16(219),
	u16(219), u16(219), u16(219), u16(219), u16(219), u16(219), u16(219), u16(219), u16(218),
	u16(219), u16(219), u16(219), u16(219), u16(219), u16(219), u16(219), u16(219), u16(219),
	u16(277), u16(219), u16(219), u16(219), u16(219), u16(219), u16(219), u16(219), u16(219),
	u16(219), u16(219), u16(219), u16(219), u16(278), u16(278), u16(219), u16(279), u16(279),
	u16(219), u16(219), u16(219), u16(219), u16(219), u16(219), u16(282), u16(282), u16(283),
	u16(283), u16(281), u16(264), u16(255), u16(255), u16(280), u16(280), u16(192), u16(284),
	u16(284), u16(223), u16(223), u16(234), u16(234), u16(285), u16(285), u16(192), u16(192),
	u16(192), u16(286), u16(286), u16(192), u16(192), u16(192), u16(192), u16(192), u16(213),
	u16(214), u16(192), u16(288), u16(290), u16(290), u16(290), u16(291), u16(291), u16(291),
	u16(293), u16(293), u16(289), u16(289), u16(295), u16(295), u16(294), u16(294), u16(294),
	u16(294), u16(219), u16(219), u16(238), u16(238), u16(238), u16(192), u16(192), u16(192),
	u16(297), u16(297), u16(192), u16(192), u16(192), u16(192), u16(192), u16(192), u16(298),
	u16(192), u16(192), u16(192), u16(192), u16(192), u16(192), u16(192), u16(192), u16(192),
	u16(300), u16(302), u16(303), u16(303), u16(304), u16(269), u16(269), u16(307), u16(307),
	u16(307), u16(306), u16(308), u16(243), u16(243), u16(309), u16(310), u16(311), u16(311),
	u16(311), u16(311), u16(311), u16(312), u16(312), u16(312), u16(316), u16(318), u16(318),
	u16(319), u16(319), u16(317), u16(317), u16(320), u16(320), u16(321), u16(321), u16(321),
	u16(253), u16(276), u16(276), u16(276), u16(315), u16(315), u16(314), u16(218), u16(187),
	u16(188), u16(188), u16(189), u16(189), u16(189), u16(194), u16(194), u16(194), u16(196),
	u16(196), u16(192), u16(205), u16(203), u16(203), u16(195), u16(195), u16(210), u16(211),
	u16(212), u16(212), u16(209), u16(209), u16(217), u16(217), u16(217), u16(204), u16(230),
	u16(230), u16(231), u16(235), u16(237), u16(241), u16(242), u16(257), u16(258), u16(267),
	u16(275), u16(219), u16(277), u16(281), u16(264), u16(287), u16(287), u16(287), u16(287),
	u16(287), u16(213), u16(292), u16(292), u16(295), u16(296), u16(296), u16(299), u16(299),
	u16(301), u16(301), u16(302), u16(305), u16(305), u16(305), u16(269), u16(309), u16(311)]

@[export: 'yyRuleInfoNRhs']
const yy_rule_info_nr_hs = [i8(-1), i8(-3), i8(-1), i8(-3), i8(0), i8(-1), i8(-1), i8(-1), i8(-2),
	i8(-2), i8(-2), i8(-3), i8(-5), i8(-6), i8(-1), i8(0), i8(-3), i8(-1), i8(0), i8(-5), i8(-2),
	i8(0), i8(-3), i8(-2), i8(-1), i8(-2), i8(0), i8(-4), i8(-6), i8(-2), i8(0), i8(0), i8(-2),
	i8(-3), i8(-4), i8(-4), i8(-4), i8(-3), i8(-3), i8(-5), i8(-2), i8(-4), i8(-4), i8(-1), i8(-2),
	i8(-3), i8(-4), i8(0), i8(-1), i8(0), i8(-2), i8(-2), i8(-3), i8(-3), i8(-3), i8(-2), i8(-2),
	i8(-1), i8(-1), i8(-2), i8(-3), i8(-2), i8(0), i8(-2), i8(-2), i8(0), i8(-1), i8(-2), i8(-7),
	i8(-5), i8(-5), i8(-10), i8(0), i8(0), i8(-3), i8(0), i8(-2), i8(-1), i8(-1), i8(-4), i8(-2),
	i8(0), i8(-9), i8(-4), i8(-1), i8(-3), i8(-4), i8(-1), i8(-3), i8(-1), i8(-2), i8(-1), i8(-9),
	i8(-10), i8(-4), i8(-1), i8(-5), i8(-5), i8(-1), i8(-1), i8(0), i8(0), i8(-5), i8(-3), i8(-5),
	i8(-2), i8(0), i8(0), i8(-2), i8(-2), i8(0), i8(-5), i8(-6), i8(-8), i8(-6), i8(-6), i8(0),
	i8(-2), i8(-1), i8(-3), i8(-1), i8(-3), i8(-3), i8(-5), i8(-1), i8(-2), i8(-3), i8(-4), i8(-2),
	i8(-4), i8(0), i8(0), i8(-3), i8(-2), i8(0), i8(-3), i8(-5), i8(-3), i8(-1), i8(-1), i8(0),
	i8(-2), i8(-2), i8(0), i8(0), i8(-3), i8(0), i8(-2), i8(0), i8(-2), i8(-4), i8(-4), i8(-6),
	i8(0), i8(-2), i8(0), i8(-2), i8(-2), i8(-4), i8(-9), i8(-5), i8(-7), i8(-3), i8(-5), i8(-7),
	i8(-8), i8(0), i8(-2), i8(-12), i8(-9), i8(-5), i8(-8), i8(-2), i8(-2), i8(-1), i8(0), i8(-3),
	i8(-3), i8(-1), i8(-3), i8(-1), i8(-3), i8(-5), i8(-1), i8(-1), i8(-1), i8(-1), i8(-3), i8(-6),
	i8(-5), i8(-8), i8(-4), i8(-6), i8(-9), i8(-5), i8(-1), i8(-5), i8(-3), i8(-3), i8(-3), i8(-3),
	i8(-3), i8(-3), i8(-3), i8(-3), i8(-2), i8(-3), i8(-5), i8(-2), i8(-3), i8(-3), i8(-4), i8(-6),
	i8(-5), i8(-2), i8(-2), i8(-2), i8(-3), i8(-1), i8(-2), i8(-5), i8(-1), i8(-2), i8(-5), i8(-3),
	i8(-5), i8(-5), i8(-4), i8(-5), i8(-5), i8(-4), i8(-2), i8(0), i8(0), i8(0), i8(-3), i8(-1),
	i8(0), i8(-3), i8(-12), i8(-1), i8(0), i8(0), i8(-3), i8(-5), i8(-3), i8(0), i8(-2), i8(-4),
	i8(-2), i8(-3), i8(-2), i8(0), i8(-3), i8(-5), i8(-6), i8(-5), i8(-6), i8(-2), i8(-2), i8(-5),
	i8(-11), i8(-1), i8(-2), i8(0), i8(-1), i8(-1), i8(-3), i8(0), i8(-2), i8(-3), i8(-2), i8(-3),
	i8(-2), i8(-9), i8(-8), i8(-6), i8(-3), i8(-4), i8(-6), i8(-1), i8(-1), i8(-1), i8(-4), i8(-6),
	i8(-3), i8(0), i8(-2), i8(-1), i8(-3), i8(-1), i8(-3), i8(-6), i8(-2), i8(-7), i8(-6), i8(-8),
	i8(-6), i8(-9), i8(-10), i8(-11), i8(-9), i8(-1), i8(-4), i8(-8), i8(0), i8(-1), i8(-3), i8(-1),
	i8(-2), i8(-3), i8(-1), i8(-2), i8(-3), i8(-6), i8(-1), i8(-1), i8(-3), i8(-3), i8(-5), i8(-5),
	i8(-6), i8(-4), i8(-5), i8(-2), i8(0), i8(-3), i8(-6), i8(-1), i8(-1), i8(-2), i8(-1), i8(-2),
	i8(-2), i8(-2), i8(0), i8(-2), i8(-2), i8(-2), i8(-1), i8(-2), i8(-2), i8(-1), i8(-1), i8(-4),
	i8(-2), i8(-5), i8(-1), i8(-1), i8(-2), i8(-1), i8(-1), i8(-2), i8(-3), i8(0), i8(-1), i8(-2),
	i8(-1), i8(0), i8(-2), i8(-1), i8(-4), i8(-2), i8(-1), i8(-1), i8(-1), i8(-1), i8(-1), i8(-1),
	i8(-2), i8(0), i8(-2), i8(-4), i8(-2), i8(-2), i8(-3), i8(-1), i8(0), i8(-1), i8(-1), i8(-1),
	i8(-1), i8(-2), i8(-1), i8(-1), i8(0), i8(-1), i8(-1), i8(-1), i8(-1), i8(-1), i8(-1), i8(-1),
	i8(-1), i8(-1), i8(-1), i8(0), i8(-3), i8(0), i8(-1), i8(0), i8(0), i8(-1), i8(-1), i8(-3),
	i8(-2), i8(0), i8(-4), i8(-2), i8(0), i8(-1), i8(-1)]

@[export: 'aiClass']
const ai_class = [u8(29), u8(28), u8(28), u8(28), u8(28), u8(28), u8(28), u8(28), u8(28), u8(7),
	u8(7), u8(28), u8(7), u8(7), u8(28), u8(28), u8(28), u8(28), u8(28), u8(28), u8(28), u8(28),
	u8(28), u8(28), u8(28), u8(28), u8(28), u8(28), u8(28), u8(28), u8(28), u8(28), u8(7), u8(15),
	u8(8), u8(5), u8(4), u8(22), u8(24), u8(8), u8(17), u8(18), u8(21), u8(20), u8(23), u8(11),
	u8(26), u8(16), u8(3), u8(3), u8(3), u8(3), u8(3), u8(3), u8(3), u8(3), u8(3), u8(3), u8(5),
	u8(19), u8(12), u8(14), u8(13), u8(6), u8(5), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1),
	u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1),
	u8(1), u8(1), u8(0), u8(2), u8(2), u8(9), u8(28), u8(28), u8(28), u8(2), u8(8), u8(1), u8(1),
	u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1),
	u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(1), u8(0), u8(2), u8(2), u8(28), u8(10), u8(28),
	u8(25), u8(28), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27),
	u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27),
	u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27),
	u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27),
	u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27),
	u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27),
	u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27),
	u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27),
	u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27),
	u8(27), u8(27), u8(27), u8(27), u8(27), u8(30), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27),
	u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27), u8(27)]

@[weak]
__global zKWText = [i8(`R`), i8(`E`), i8(`I`), i8(`N`), i8(`D`), i8(`E`), i8(`X`), i8(`E`), i8(`D`),
	i8(`E`), i8(`S`), i8(`C`), i8(`A`), i8(`P`), i8(`E`), i8(`A`), i8(`C`), i8(`H`), i8(`E`),
	i8(`C`), i8(`K`), i8(`E`), i8(`Y`), i8(`B`), i8(`E`), i8(`F`), i8(`O`), i8(`R`), i8(`E`),
	i8(`I`), i8(`G`), i8(`N`), i8(`O`), i8(`R`), i8(`E`), i8(`G`), i8(`E`), i8(`X`), i8(`P`),
	i8(`L`), i8(`A`), i8(`I`), i8(`N`), i8(`S`), i8(`T`), i8(`E`), i8(`A`), i8(`D`), i8(`D`),
	i8(`A`), i8(`T`), i8(`A`), i8(`B`), i8(`A`), i8(`S`), i8(`E`), i8(`L`), i8(`E`), i8(`C`),
	i8(`T`), i8(`A`), i8(`B`), i8(`L`), i8(`E`), i8(`F`), i8(`T`), i8(`H`), i8(`E`), i8(`N`),
	i8(`D`), i8(`E`), i8(`F`), i8(`E`), i8(`R`), i8(`R`), i8(`A`), i8(`B`), i8(`L`), i8(`E`),
	i8(`L`), i8(`S`), i8(`E`), i8(`X`), i8(`C`), i8(`L`), i8(`U`), i8(`D`), i8(`E`), i8(`L`),
	i8(`E`), i8(`T`), i8(`E`), i8(`M`), i8(`P`), i8(`O`), i8(`R`), i8(`A`), i8(`R`), i8(`Y`),
	i8(`I`), i8(`S`), i8(`N`), i8(`U`), i8(`L`), i8(`L`), i8(`S`), i8(`A`), i8(`V`), i8(`E`),
	i8(`P`), i8(`O`), i8(`I`), i8(`N`), i8(`T`), i8(`E`), i8(`R`), i8(`S`), i8(`E`), i8(`C`),
	i8(`T`), i8(`I`), i8(`E`), i8(`S`), i8(`N`), i8(`O`), i8(`T`), i8(`N`), i8(`U`), i8(`L`),
	i8(`L`), i8(`I`), i8(`K`), i8(`E`), i8(`X`), i8(`C`), i8(`E`), i8(`P`), i8(`T`), i8(`R`),
	i8(`A`), i8(`N`), i8(`S`), i8(`A`), i8(`C`), i8(`T`), i8(`I`), i8(`O`), i8(`N`), i8(`A`),
	i8(`T`), i8(`U`), i8(`R`), i8(`A`), i8(`L`), i8(`T`), i8(`E`), i8(`R`), i8(`A`), i8(`I`),
	i8(`S`), i8(`E`), i8(`X`), i8(`C`), i8(`L`), i8(`U`), i8(`S`), i8(`I`), i8(`V`), i8(`E`),
	i8(`X`), i8(`I`), i8(`S`), i8(`T`), i8(`S`), i8(`C`), i8(`O`), i8(`N`), i8(`S`), i8(`T`),
	i8(`R`), i8(`A`), i8(`I`), i8(`N`), i8(`T`), i8(`O`), i8(`F`), i8(`F`), i8(`S`), i8(`E`),
	i8(`T`), i8(`R`), i8(`I`), i8(`G`), i8(`G`), i8(`E`), i8(`R`), i8(`A`), i8(`N`), i8(`G`),
	i8(`E`), i8(`N`), i8(`E`), i8(`R`), i8(`A`), i8(`T`), i8(`E`), i8(`D`), i8(`E`), i8(`T`),
	i8(`A`), i8(`C`), i8(`H`), i8(`A`), i8(`V`), i8(`I`), i8(`N`), i8(`G`), i8(`L`), i8(`O`),
	i8(`B`), i8(`E`), i8(`G`), i8(`I`), i8(`N`), i8(`N`), i8(`E`), i8(`R`), i8(`E`), i8(`F`),
	i8(`E`), i8(`R`), i8(`E`), i8(`N`), i8(`C`), i8(`E`), i8(`S`), i8(`U`), i8(`N`), i8(`I`),
	i8(`Q`), i8(`U`), i8(`E`), i8(`R`), i8(`Y`), i8(`W`), i8(`I`), i8(`T`), i8(`H`), i8(`O`),
	i8(`U`), i8(`T`), i8(`E`), i8(`R`), i8(`E`), i8(`L`), i8(`E`), i8(`A`), i8(`S`), i8(`E`),
	i8(`A`), i8(`T`), i8(`T`), i8(`A`), i8(`C`), i8(`H`), i8(`B`), i8(`E`), i8(`T`), i8(`W`),
	i8(`E`), i8(`E`), i8(`N`), i8(`O`), i8(`T`), i8(`H`), i8(`I`), i8(`N`), i8(`G`), i8(`R`),
	i8(`O`), i8(`U`), i8(`P`), i8(`S`), i8(`C`), i8(`A`), i8(`S`), i8(`C`), i8(`A`), i8(`D`),
	i8(`E`), i8(`F`), i8(`A`), i8(`U`), i8(`L`), i8(`T`), i8(`C`), i8(`A`), i8(`S`), i8(`E`),
	i8(`C`), i8(`O`), i8(`L`), i8(`L`), i8(`A`), i8(`T`), i8(`E`), i8(`C`), i8(`R`), i8(`E`),
	i8(`A`), i8(`T`), i8(`E`), i8(`C`), i8(`U`), i8(`R`), i8(`R`), i8(`E`), i8(`N`), i8(`T`),
	i8(`_`), i8(`D`), i8(`A`), i8(`T`), i8(`E`), i8(`I`), i8(`M`), i8(`M`), i8(`E`), i8(`D`),
	i8(`I`), i8(`A`), i8(`T`), i8(`E`), i8(`J`), i8(`O`), i8(`I`), i8(`N`), i8(`S`), i8(`E`),
	i8(`R`), i8(`T`), i8(`M`), i8(`A`), i8(`T`), i8(`C`), i8(`H`), i8(`P`), i8(`L`), i8(`A`),
	i8(`N`), i8(`A`), i8(`L`), i8(`Y`), i8(`Z`), i8(`E`), i8(`P`), i8(`R`), i8(`A`), i8(`G`),
	i8(`M`), i8(`A`), i8(`T`), i8(`E`), i8(`R`), i8(`I`), i8(`A`), i8(`L`), i8(`I`), i8(`Z`),
	i8(`E`), i8(`D`), i8(`E`), i8(`F`), i8(`E`), i8(`R`), i8(`R`), i8(`E`), i8(`D`), i8(`I`),
	i8(`S`), i8(`T`), i8(`I`), i8(`N`), i8(`C`), i8(`T`), i8(`U`), i8(`P`), i8(`D`), i8(`A`),
	i8(`T`), i8(`E`), i8(`V`), i8(`A`), i8(`L`), i8(`U`), i8(`E`), i8(`S`), i8(`V`), i8(`I`),
	i8(`R`), i8(`T`), i8(`U`), i8(`A`), i8(`L`), i8(`W`), i8(`A`), i8(`Y`), i8(`S`), i8(`W`),
	i8(`H`), i8(`E`), i8(`N`), i8(`W`), i8(`H`), i8(`E`), i8(`R`), i8(`E`), i8(`C`), i8(`U`),
	i8(`R`), i8(`S`), i8(`I`), i8(`V`), i8(`E`), i8(`A`), i8(`B`), i8(`O`), i8(`R`), i8(`T`),
	i8(`A`), i8(`F`), i8(`T`), i8(`E`), i8(`R`), i8(`E`), i8(`N`), i8(`A`), i8(`M`), i8(`E`),
	i8(`A`), i8(`N`), i8(`D`), i8(`R`), i8(`O`), i8(`P`), i8(`A`), i8(`R`), i8(`T`), i8(`I`),
	i8(`T`), i8(`I`), i8(`O`), i8(`N`), i8(`A`), i8(`U`), i8(`T`), i8(`O`), i8(`I`), i8(`N`),
	i8(`C`), i8(`R`), i8(`E`), i8(`M`), i8(`E`), i8(`N`), i8(`T`), i8(`C`), i8(`A`), i8(`S`),
	i8(`T`), i8(`C`), i8(`O`), i8(`L`), i8(`U`), i8(`M`), i8(`N`), i8(`C`), i8(`O`), i8(`M`),
	i8(`M`), i8(`I`), i8(`T`), i8(`C`), i8(`O`), i8(`N`), i8(`F`), i8(`L`), i8(`I`), i8(`C`),
	i8(`T`), i8(`C`), i8(`R`), i8(`O`), i8(`S`), i8(`S`), i8(`C`), i8(`U`), i8(`R`), i8(`R`),
	i8(`E`), i8(`N`), i8(`T`), i8(`_`), i8(`T`), i8(`I`), i8(`M`), i8(`E`), i8(`S`), i8(`T`),
	i8(`A`), i8(`M`), i8(`P`), i8(`R`), i8(`E`), i8(`C`), i8(`E`), i8(`D`), i8(`I`), i8(`N`),
	i8(`G`), i8(`F`), i8(`A`), i8(`I`), i8(`L`), i8(`A`), i8(`S`), i8(`T`), i8(`F`), i8(`I`),
	i8(`L`), i8(`T`), i8(`E`), i8(`R`), i8(`E`), i8(`P`), i8(`L`), i8(`A`), i8(`C`), i8(`E`),
	i8(`F`), i8(`I`), i8(`R`), i8(`S`), i8(`T`), i8(`F`), i8(`O`), i8(`L`), i8(`L`), i8(`O`),
	i8(`W`), i8(`I`), i8(`N`), i8(`G`), i8(`F`), i8(`R`), i8(`O`), i8(`M`), i8(`F`), i8(`U`),
	i8(`L`), i8(`L`), i8(`I`), i8(`M`), i8(`I`), i8(`T`), i8(`I`), i8(`F`), i8(`O`), i8(`R`),
	i8(`D`), i8(`E`), i8(`R`), i8(`E`), i8(`S`), i8(`T`), i8(`R`), i8(`I`), i8(`C`), i8(`T`),
	i8(`O`), i8(`T`), i8(`H`), i8(`E`), i8(`R`), i8(`S`), i8(`O`), i8(`V`), i8(`E`), i8(`R`),
	i8(`E`), i8(`T`), i8(`U`), i8(`R`), i8(`N`), i8(`I`), i8(`N`), i8(`G`), i8(`R`), i8(`I`),
	i8(`G`), i8(`H`), i8(`T`), i8(`R`), i8(`O`), i8(`L`), i8(`L`), i8(`B`), i8(`A`), i8(`C`),
	i8(`K`), i8(`R`), i8(`O`), i8(`W`), i8(`S`), i8(`U`), i8(`N`), i8(`B`), i8(`O`), i8(`U`),
	i8(`N`), i8(`D`), i8(`E`), i8(`D`), i8(`U`), i8(`N`), i8(`I`), i8(`O`), i8(`N`), i8(`U`),
	i8(`S`), i8(`I`), i8(`N`), i8(`G`), i8(`V`), i8(`A`), i8(`C`), i8(`U`), i8(`U`), i8(`M`),
	i8(`V`), i8(`I`), i8(`E`), i8(`W`), i8(`I`), i8(`N`), i8(`D`), i8(`O`), i8(`W`), i8(`B`),
	i8(`Y`), i8(`I`), i8(`N`), i8(`I`), i8(`T`), i8(`I`), i8(`A`), i8(`L`), i8(`L`), i8(`Y`),
	i8(`P`), i8(`R`), i8(`I`), i8(`M`), i8(`A`), i8(`R`), i8(`Y`)]!

@[export: 'aKWHash']
const akw_hash = [u8(84), u8(92), u8(134), u8(82), u8(105), u8(29), u8(0), u8(0), u8(94), u8(0),
	u8(85), u8(72), u8(0), u8(53), u8(35), u8(86), u8(15), u8(0), u8(42), u8(97), u8(54), u8(89),
	u8(135), u8(19), u8(0), u8(0), u8(140), u8(0), u8(40), u8(129), u8(0), u8(22), u8(107), u8(0),
	u8(9), u8(0), u8(0), u8(123), u8(80), u8(0), u8(78), u8(6), u8(0), u8(65), u8(103), u8(147),
	u8(0), u8(136), u8(115), u8(0), u8(0), u8(48), u8(0), u8(90), u8(24), u8(0), u8(17), u8(0),
	u8(27), u8(70), u8(23), u8(26), u8(5), u8(60), u8(142), u8(110), u8(122), u8(0), u8(73), u8(91),
	u8(71), u8(145), u8(61), u8(120), u8(74), u8(0), u8(49), u8(0), u8(11), u8(41), u8(0), u8(113),
	u8(0), u8(0), u8(0), u8(109), u8(10), u8(111), u8(116), u8(125), u8(14), u8(50), u8(124), u8(0),
	u8(100), u8(0), u8(18), u8(121), u8(144), u8(56), u8(130), u8(139), u8(88), u8(83), u8(37),
	u8(30), u8(126), u8(0), u8(0), u8(108), u8(51), u8(131), u8(128), u8(0), u8(34), u8(0), u8(0),
	u8(132), u8(0), u8(98), u8(38), u8(39), u8(0), u8(20), u8(45), u8(117), u8(93)]

@[export: 'aKWNext']
const akw_next = [u8(0), u8(0), u8(0), u8(0), u8(0), u8(4), u8(0), u8(43), u8(0), u8(0), u8(106),
	u8(114), u8(0), u8(0), u8(0), u8(2), u8(0), u8(0), u8(143), u8(0), u8(0), u8(0), u8(13), u8(0),
	u8(0), u8(0), u8(0), u8(141), u8(0), u8(0), u8(119), u8(52), u8(0), u8(0), u8(137), u8(12),
	u8(0), u8(0), u8(62), u8(0), u8(138), u8(0), u8(133), u8(0), u8(0), u8(36), u8(0), u8(0), u8(28),
	u8(77), u8(0), u8(0), u8(0), u8(0), u8(59), u8(0), u8(47), u8(0), u8(0), u8(0), u8(0), u8(0),
	u8(0), u8(0), u8(0), u8(0), u8(0), u8(69), u8(0), u8(0), u8(0), u8(0), u8(0), u8(146), u8(3),
	u8(0), u8(58), u8(0), u8(1), u8(75), u8(0), u8(0), u8(0), u8(31), u8(0), u8(0), u8(0), u8(0),
	u8(0), u8(127), u8(0), u8(104), u8(0), u8(64), u8(66), u8(63), u8(0), u8(0), u8(0), u8(0), u8(0),
	u8(46), u8(0), u8(16), u8(8), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0), u8(0),
	u8(0), u8(81), u8(101), u8(0), u8(112), u8(21), u8(7), u8(67), u8(0), u8(79), u8(96), u8(118),
	u8(0), u8(0), u8(68), u8(0), u8(0), u8(99), u8(44), u8(0), u8(55), u8(0), u8(76), u8(0), u8(95),
	u8(32), u8(33), u8(57), u8(25), u8(0), u8(102), u8(0), u8(0), u8(87)]

@[export: 'aKWLen']
const akw_len = [u8(0), u8(7), u8(7), u8(5), u8(4), u8(6), u8(4), u8(5), u8(3), u8(6), u8(7), u8(3),
	u8(6), u8(6), u8(7), u8(7), u8(3), u8(8), u8(2), u8(6), u8(5), u8(4), u8(4), u8(3), u8(10),
	u8(4), u8(7), u8(6), u8(9), u8(4), u8(2), u8(6), u8(5), u8(9), u8(9), u8(4), u8(7), u8(3), u8(2),
	u8(4), u8(4), u8(6), u8(11), u8(6), u8(2), u8(7), u8(5), u8(5), u8(9), u8(6), u8(10), u8(4),
	u8(6), u8(2), u8(3), u8(7), u8(5), u8(9), u8(6), u8(6), u8(4), u8(5), u8(5), u8(10), u8(6),
	u8(5), u8(7), u8(4), u8(5), u8(7), u8(6), u8(7), u8(7), u8(6), u8(5), u8(7), u8(3), u8(7), u8(4),
	u8(7), u8(6), u8(12), u8(9), u8(4), u8(6), u8(5), u8(4), u8(7), u8(6), u8(12), u8(8), u8(8),
	u8(2), u8(6), u8(6), u8(7), u8(6), u8(4), u8(5), u8(9), u8(5), u8(5), u8(6), u8(3), u8(4), u8(9),
	u8(13), u8(2), u8(2), u8(4), u8(6), u8(6), u8(8), u8(5), u8(17), u8(12), u8(7), u8(9), u8(4),
	u8(4), u8(6), u8(7), u8(5), u8(9), u8(4), u8(4), u8(5), u8(2), u8(5), u8(8), u8(6), u8(4), u8(9),
	u8(5), u8(8), u8(4), u8(3), u8(9), u8(5), u8(5), u8(6), u8(4), u8(6), u8(2), u8(2), u8(9), u8(3),
	u8(7)]

@[export: 'aKWOffset']
const akw_offset = [u16(0), u16(0), u16(2), u16(2), u16(8), u16(9), u16(14), u16(16), u16(20),
	u16(23), u16(25), u16(25), u16(29), u16(33), u16(36), u16(41), u16(46), u16(48), u16(53),
	u16(54), u16(59), u16(62), u16(65), u16(67), u16(69), u16(78), u16(81), u16(86), u16(90),
	u16(90), u16(94), u16(99), u16(101), u16(105), u16(111), u16(119), u16(123), u16(123), u16(123),
	u16(126), u16(129), u16(132), u16(137), u16(142), u16(146), u16(147), u16(152), u16(156),
	u16(160), u16(168), u16(174), u16(181), u16(184), u16(184), u16(187), u16(189), u16(195),
	u16(198), u16(206), u16(211), u16(216), u16(219), u16(222), u16(226), u16(236), u16(239),
	u16(244), u16(244), u16(248), u16(252), u16(259), u16(265), u16(271), u16(277), u16(277),
	u16(283), u16(284), u16(288), u16(295), u16(299), u16(306), u16(312), u16(324), u16(333),
	u16(335), u16(341), u16(346), u16(348), u16(355), u16(359), u16(370), u16(377), u16(378),
	u16(385), u16(391), u16(397), u16(402), u16(408), u16(412), u16(415), u16(424), u16(429),
	u16(433), u16(439), u16(441), u16(444), u16(453), u16(455), u16(457), u16(466), u16(470),
	u16(476), u16(482), u16(490), u16(495), u16(495), u16(495), u16(511), u16(520), u16(523),
	u16(527), u16(532), u16(539), u16(544), u16(553), u16(557), u16(560), u16(565), u16(567),
	u16(571), u16(579), u16(585), u16(588), u16(597), u16(602), u16(610), u16(610), u16(614),
	u16(623), u16(628), u16(633), u16(639), u16(642), u16(645), u16(648), u16(650), u16(655),
	u16(659)]

@[export: 'aKWCode']
const akw_code = [u8(0), u8(99), u8(117), u8(162), u8(39), u8(59), u8(41), u8(125), u8(68), u8(33),
	u8(133), u8(63), u8(64), u8(48), u8(2), u8(66), u8(164), u8(38), u8(24), u8(139), u8(16),
	u8(119), u8(160), u8(11), u8(132), u8(161), u8(92), u8(129), u8(21), u8(21), u8(43), u8(51),
	u8(83), u8(13), u8(138), u8(95), u8(52), u8(19), u8(67), u8(122), u8(48), u8(137), u8(6), u8(28),
	u8(116), u8(119), u8(163), u8(72), u8(9), u8(20), u8(120), u8(152), u8(70), u8(69), u8(131),
	u8(78), u8(90), u8(96), u8(40), u8(148), u8(48), u8(5), u8(119), u8(126), u8(124), u8(3), u8(26),
	u8(82), u8(119), u8(14), u8(32), u8(49), u8(153), u8(93), u8(147), u8(35), u8(31), u8(121),
	u8(158), u8(114), u8(17), u8(101), u8(8), u8(144), u8(128), u8(47), u8(4), u8(30), u8(71),
	u8(98), u8(7), u8(141), u8(45), u8(130), u8(140), u8(81), u8(97), u8(159), u8(150), u8(73),
	u8(27), u8(29), u8(100), u8(44), u8(134), u8(88), u8(127), u8(15), u8(50), u8(36), u8(61),
	u8(10), u8(37), u8(119), u8(101), u8(101), u8(86), u8(89), u8(42), u8(85), u8(167), u8(74),
	u8(84), u8(87), u8(143), u8(119), u8(149), u8(18), u8(146), u8(75), u8(94), u8(166), u8(151),
	u8(119), u8(12), u8(77), u8(76), u8(91), u8(135), u8(145), u8(79), u8(80), u8(165), u8(62),
	u8(34), u8(65), u8(136), u8(123)]

@[export: 'sqlite3BuiltinExtensions']
const sqlite3_builtin_extensions = [sqlite3_test_ext_init]

@[weak]
__global aHardLimit = [1000000000, 1000000000, 2000, 1000, 500, 250000000, 1000, 10, 50000, 32766,
	1000, 8, 2500]!
@[weak]
__global jsonbType = [c'null', c'true', c'false', c'integer', c'integer', c'real', c'real', c'text',
	c'text', c'text', c'text', c'array', c'object', c'', c'', c'', c'']!

@[export: 'jsonIsSpace']
const json_is_space = [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(1), i8(1),
	i8(0), i8(0), i8(1), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(1), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0)]

@[weak]
__global jsonSpaces = [i8(9), 10, 13, 32, 0]!

@[export: 'jsonIsOk']
const json_is_ok = [i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0),
	i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(0), i8(1), i8(1), i8(0), i8(1), i8(1), i8(1), i8(1),
	i8(0), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1),
	i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1),
	i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1),
	i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(0), i8(1), i8(1),
	i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1),
	i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1),
	i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1),
	i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1),
	i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1),
	i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1),
	i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1),
	i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1),
	i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1),
	i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1),
	i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1),
	i8(1), i8(1), i8(1), i8(1), i8(1), i8(1), i8(1)]

@[export: 'aNanInfName']
const a_nan_inf_name = [NanInfName{
	c1: i8(`i`)
	c2: i8(`I`)
	n: i8(3)
	eType: i8(5)
	nRepl: i8(7)
	zMatch: c'inf'
	zRepl: c'9.0e999'
}, NanInfName{
	c1: i8(`i`)
	c2: i8(`I`)
	n: i8(8)
	eType: i8(5)
	nRepl: i8(7)
	zMatch: c'infinity'
	zRepl: c'9.0e999'
}, NanInfName{
	c1: i8(`n`)
	c2: i8(`N`)
	n: i8(3)
	eType: i8(0)
	nRepl: i8(4)
	zMatch: c'NaN'
	zRepl: c'null'
}, NanInfName{
	c1: i8(`q`)
	c2: i8(`Q`)
	n: i8(4)
	eType: i8(0)
	nRepl: i8(4)
	zMatch: c'QNaN'
	zRepl: c'null'
}, NanInfName{
	c1: i8(`s`)
	c2: i8(`S`)
	n: i8(4)
	eType: i8(0)
	nRepl: i8(4)
	zMatch: c'SNaN'
	zRepl: c'null'
}]

@[weak]
__global jsonEachModule = Sqlite3_module{
	iVersion: 0
	xCreate: C2vFn_666e20282653716c697465332c20766f69647074722c20696e742c20262675382c20262653716c697465335f767461622c20262675382920696e74(voidptr(0))
	xConnect: json_each_connect
	xBestIndex: json_each_best_index
	xDisconnect: json_each_disconnect
	xDestroy: C2vFn_666e20282653716c697465335f767461622920696e74(voidptr(0))
	xOpen: json_each_open
	xClose: json_each_close
	xFilter: json_each_filter
	xNext: json_each_next
	xEof: json_each_eof
	xColumn: json_each_column
	xRowid: C2vFn_666e20282653716c697465335f767461625f637572736f722c202653716c697465335f696e7436342920696e74(voidptr(json_each_rowid))
	xUpdate: C2vFn_666e20282653716c697465335f767461622c20696e742c20262653716c697465335f76616c75652c202653716c697465335f696e7436342920696e74(voidptr(0))
	xBegin: C2vFn_666e20282653716c697465335f767461622920696e74(voidptr(0))
	xSync: C2vFn_666e20282653716c697465335f767461622920696e74(voidptr(0))
	xCommit: C2vFn_666e20282653716c697465335f767461622920696e74(voidptr(0))
	xRollback: C2vFn_666e20282653716c697465335f767461622920696e74(voidptr(0))
	xFindFunction: C2vFn_666e20282653716c697465335f767461622c20696e742c202669382c2026666e20282653716c697465335f636f6e746578742c20696e742c20262653716c697465335f76616c7565292c2026766f69647074722920696e74(voidptr(0))
	xRename: C2vFn_666e20282653716c697465335f767461622c202669382920696e74(voidptr(0))
	xSavepoint: C2vFn_666e20282653716c697465335f767461622c20696e742920696e74(voidptr(0))
	xRelease: C2vFn_666e20282653716c697465335f767461622c20696e742920696e74(voidptr(0))
	xRollbackTo: C2vFn_666e20282653716c697465335f767461622c20696e742920696e74(voidptr(0))
	xShadowName: C2vFn_666e20282669382920696e74(voidptr(0))
	xIntegrity: C2vFn_666e20282653716c697465335f767461622c202669382c202669382c20696e742c20262675382920696e74(voidptr(0))
}
