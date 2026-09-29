@[translated]
module main

type Op = VdbeOp

type Bool = u32

union VdbeCursor_ub {
	pBtx    &Btree
	aAltMap &u32
}

union VdbeCursor_uc {
	pCursor &BtCursor
	pVCur   &Sqlite3_vtab_cursor
	pSorter &VdbeSorter
}

struct VdbeCursor {
	eCurType       U8
	iDb            I8
	nullRow        U8
	deferredMoveto U8
	isTable        U8
	isEphemeral    bool
	useRandomRowid bool
	isOrdered      bool
	noReuse        bool
	colCache       bool
	seekHit        U16
	ub             VdbeCursor_ub
	seqCount       I64
	cacheStatus    u32
	seekResult     int
	pAltCursor     &VdbeCursor
	uc             VdbeCursor_uc
	pKeyInfo       &KeyInfo
	iHdrOffset     u32
	pgnoRoot       Pgno
	nField         I16
	nHdrParsed     U16
	movetoTarget   I64
	aOffset        &u32
	aRow           &U8
	payloadSize    u32
	szRow          u32
	pCache         &VdbeTxtBlbCache
	aType          [1]u32
}

struct VdbeTxtBlbCache {
	pCValue     &i8
	iOffset     I64
	iCol        int
	cacheStatus u32
	colCacheCtr u32
}

struct VdbeFrame {
	v         &Vdbe
	pParent   &VdbeFrame
	aOp       &Op
	aMem      &Mem
	apCsr     &&VdbeCursor
	aOnce     &U8
	token     voidptr
	lastRowid I64
	pAuxData  &AuxData
	nCursor   int
	pc        int
	nOp       int
	nMem      int
	nChildMem int
	nChildCsr int
	nChange   I64
	nDbChange I64
}

union MemValue {
	r      f64
	i      I64
	nZero  int
	zPType &i8
	pDef   &FuncDef
}

struct Sqlite3_value {
	u        MemValue
	z        &i8
	n        int
	flags    U16
	enc      U8
	eSubtype U8
	db       &Sqlite3
	szMalloc int
	uTemp    u32
	zMalloc  &i8
	xDel     fn (voidptr)
}

struct AuxData {
	iAuxOp     int
	iAuxArg    int
	pAux       voidptr
	xDeleteAux fn (voidptr)
	pNextAux   &AuxData
}

struct Sqlite3_context {
	pOut     &Mem
	pFunc    &FuncDef
	pMem     &Mem
	pVdbe    &Vdbe
	iOp      int
	isError  int
	enc      U8
	skipFlag U8
	argc     U16
	argv     [1]&Sqlite3_value
}

struct ScanStatus {
	addrExplain int
	aAddrRange  [6]int
	addrLoop    int
	addrVisit   int
	iSelectID   int
	nEst        LogEst
	zName       &i8
}

struct DblquoteStr {
	pNextStr &DblquoteStr
	z        [8]i8
}

struct Vdbe {
	db                 &Sqlite3
	ppVPrev            &&Vdbe
	pVNext             &Vdbe
	pParse             &Parse
	nVar               YnVar
	nMem               int
	nCursor            int
	cacheCtr           u32
	pc                 int
	rc                 int
	nChange            I64
	iStatement         int
	iCurrentTime       I64
	nFkConstraint      I64
	nStmtDefCons       I64
	nStmtDefImmCons    I64
	aMem               &Mem
	apArg              &&Mem
	apCsr              &&VdbeCursor
	aVar               &Mem
	aOp                &Op
	nOp                int
	nOpAlloc           int
	aColName           &Mem
	pResultRow         &Mem
	zErrMsg            &i8
	pVList             &VList
	startTime          I64
	nResColumn         U16
	nResAlloc          U16
	errorAction        U8
	minWriteFileFormat U8
	prepFlags          U8
	eVdbeState         U8
	expired            Bft
	explain            Bft
	changeCntOn        Bft
	usesStmtJournal    Bft
	readOnly           Bft
	bIsReader          Bft
	haveEqpOps         Bft
	btreeMask          YDbMask
	lockMask           YDbMask
	aCounter           [9]u32
	zSql               &i8
	pFree              voidptr
	pFrame             &VdbeFrame
	pDelFrame          &VdbeFrame
	nFrame             int
	expmask            u32
	pProgram           &SubProgram
	pAuxData           &AuxData
}

struct PreUpdate_uKey {
	keyinfoSpace [32]U8
}

struct PreUpdate {
	v            &Vdbe
	pCsr         &VdbeCursor
	op           int
	aRecord      &U8
	pKeyinfo     &KeyInfo
	pUnpacked    &UnpackedRecord
	pNewUnpacked &UnpackedRecord
	iNewReg      int
	iBlobWrite   int
	iKey1        I64
	iKey2        I64
	oldipk       Mem
	aNew         &Mem
	pTab         &Table
	pPk          &Index
	apDflt       &&Sqlite3_value
	uKey         PreUpdate_uKey
}

struct ValueList {
	pCsr &BtCursor
	pOut &Sqlite3_value
}

@[c:'sqliteVdbePopStack']
fn sqlite_vdbe_pop_stack(arg &Vdbe, arg_2 int)

@[c:'sqlite2BtreeKeyCompare']
fn sqlite2_btree_key_compare(arg &BtCursor, arg_2 voidptr, arg_3 int, arg_4 int, arg_5 &int) int
