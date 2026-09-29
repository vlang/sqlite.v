@[translated]
module main

struct MemPage {
	isInit          U8
	intKey          U8
	intKeyLeaf      U8
	pgno            Pgno
	leaf            U8
	hdrOffset       U8
	childPtrSize    U8
	max1bytePayload U8
	nOverflow       U8
	maxLocal        U16
	minLocal        U16
	cellOffset      U16
	nFree           int
	nCell           U16
	maskPage        U16
	aiOvfl          [4]U16
	apOvfl          [4]&U8
	pBt             &BtShared
	aData           &U8
	aDataEnd        &U8
	aCellIdx        &U8
	aDataOfst       &U8
	pDbPage         &DbPage
	xCellSize       fn (&MemPage, &U8) U16
	xParseCell      fn (&MemPage, &U8, &CellInfo)
}

struct BtLock {
	pBtree &Btree
	iTable Pgno
	eLock  U8
	pNext  &BtLock
}

struct Btree {
	db             &Sqlite3
	pBt            &BtShared
	inTrans        U8
	sharable       U8
	locked         U8
	hasIncrblobCur U8
	wantToLock     int
	nBackup        int
	iBDataVersion  u32
	pNext          &Btree
	pPrev          &Btree
	lock_          BtLock
}

struct BtShared {
	pPager          &Pager
	db              &Sqlite3
	pCursor         &BtCursor
	pPage1          &MemPage
	openFlags       U8
	autoVacuum      U8
	incrVacuum      U8
	bDoTruncate     U8
	inTransaction   U8
	max1bytePayload U8
	nReserveWanted  U8
	btsFlags        U16
	maxLocal        U16
	minLocal        U16
	maxLeaf         U16
	minLeaf         U16
	pageSize        u32
	usableSize      u32
	nTransaction    int
	nPage           u32
	pSchema         voidptr
	xFreeSchema     fn (voidptr)
	mutex           &Sqlite3_mutex
	pHasContent     &Bitvec
	nRef            int
	pNext           &BtShared
	pLock           &BtLock
	pWriter         &Btree
	pTmpSpace       &U8
	nPreformatSize  int
}

struct CellInfo {
	nKey     I64
	pPayload &U8
	nPayload u32
	nLocal   U16
	nSize    U16
}

struct BtCursor {
	eState        U8
	curFlags      U8
	curPagerFlags U8
	hints         U8
	skipNext      int
	pBtree        &Btree
	aOverflow     &Pgno
	pKey          voidptr
	pBt           &BtShared
	pNext         &BtCursor
	info          CellInfo
	nKey          I64
	pgnoRoot      Pgno
	iPage         I8
	curIntKey     U8
	ix            U16
	aiIdx         [19]U16
	pKeyInfo      &KeyInfo
	pPage         &MemPage
	apPage        [19]&MemPage
}

struct IntegrityCk {
	pBt     &BtShared
	pPager  &Pager
	aPgRef  &U8
	nCkPage Pgno
	mxErr   int
	nErr    int
	rc      int
	nStep   u32
	zPfx    &i8
	v0      Pgno
	v1      Pgno
	v2      int
	errMsg  StrAccum
	heap    &u32
	db      &Sqlite3
	nRow    I64
}
