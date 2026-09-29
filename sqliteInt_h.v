@[translated]
module main

type I64 = i64

type U64 = u64

type U32 = u32

type U16 = u16

type I16 = i16

type U8 = u8

type I8 = i8

type Bft = u32

type TRowcnt = u64

type LogEst = i16

type Uptr = u64

@[weak]
__global sqlite3WhereTrace u32

struct BusyHandler {
	xBusyHandler fn (voidptr, int) int
	pBusyArg     voidptr
	nBusy        int
}

struct KeyClass {}

type StrAccum = Sqlite3_str

struct TreeView {}

type Bitmask = u64

type VList = int

struct Db {
	zDbSName     &i8
	pBt          &Btree
	safety_level U8
	bSyncSet     U8
	pSchema      &Schema
}

struct Schema {
	schema_cookie int
	iGeneration   int
	tblHash       Hash
	idxHash       Hash
	trigHash      Hash
	fkeyHash      Hash
	pSeqTab       &Table
	file_format   U8
	enc           U8
	schemaFlags   U16
	cache_size    int
}

struct Lookaside {
	bDisable   u32
	sz         U16
	szTrue     U16
	bMalloced  U8
	nSlot      u32
	anStat     [3]u32
	pInit      &LookasideSlot
	pFree      &LookasideSlot
	pSmallInit &LookasideSlot
	pSmallFree &LookasideSlot
	pMiddle    voidptr
	pStart     voidptr
	pEnd       voidptr
	pTrueEnd   voidptr
}

struct LookasideSlot {
	pNext &LookasideSlot
}

struct FuncDefHash {
	a [23]&FuncDef
}

type Sqlite3_xauth = fn (voidptr, int, &i8, &i8, &i8, &i8) int

struct Sqlite3InitInfo {
	newTnum       Pgno
	iDb           U8
	busy          U8
	orphanTrigger u32
	imposterTable u32
	reopenMemdb   u32
	azInit        &&u8
}

union Sqlite3_trace {
	xLegacy fn (voidptr, &i8)
	xV2     fn (u32, voidptr, voidptr, voidptr) int
}

union Sqlite3_u1 {
	isInterrupted int
	notUsed1      f64
}

struct Sqlite3 {
	pVfs                   &Sqlite3_vfs
	pVdbe                  &Vdbe
	pDfltColl              &CollSeq
	mutex                  &Sqlite3_mutex
	aDb                    &Db
	nDb                    int
	mDbFlags               u32
	flags                  U64
	lastRowid              I64
	szMmap                 I64
	nSchemaLock            u32
	openFlags              u32
	errCode                int
	errByteOffset          int
	errMask                int
	iSysErrno              int
	dbOptFlags             u32
	enc                    U8
	autoCommit             U8
	temp_store             U8
	mallocFailed           U8
	bBenignMalloc          U8
	dfltLockMode           U8
	nextAutovac            i8
	suppressErr            U8
	vtabOnConflict         U8
	isTransactionSavepoint U8
	mTrace                 U8
	noSharedCache          U8
	nSqlExec               U8
	eOpenState             U8
	nFpDigit               U8
	nextPagesize           int
	nChange                I64
	nTotalChange           I64
	aLimit                 [13]int
	nMaxSorterMmap         int
	init                   Sqlite3InitInfo
	nVdbeActive            int
	nVdbeRead              int
	nVdbeWrite             int
	nVdbeExec              int
	nVDestroy              int
	nExtension             int
	aExtension             &voidptr
	trace                  Sqlite3_trace
	pTraceArg              voidptr
	xProfile               fn (voidptr, &i8, U64)
	pProfileArg            voidptr
	pCommitArg             voidptr
	xCommitCallback        fn (voidptr) int
	pRollbackArg           voidptr
	xRollbackCallback      fn (voidptr)
	pUpdateArg             voidptr
	xUpdateCallback        fn (voidptr, int, &i8, &i8, Sqlite_int64)
	pAutovacPagesArg       voidptr
	xAutovacDestr          fn (voidptr)
	xAutovacPages          fn (voidptr, &i8, u32, u32, u32) u32
	pParse                 &Parse
	xWalCallback           fn (voidptr, &Sqlite3, &i8, int) int
	pWalArg                voidptr
	xCollNeeded            fn (voidptr, &Sqlite3, int, &i8)
	xCollNeeded16          fn (voidptr, &Sqlite3, int, voidptr)
	pCollNeededArg         voidptr
	pErr                   &Sqlite3_value
	u1                     Sqlite3_u1
	lookaside              Lookaside
	xAuth                  Sqlite3_xauth
	pAuthArg               voidptr
	xProgress              fn (voidptr) int
	pProgressArg           voidptr
	nProgressOps           u32
	nVTrans                int
	aModule                Hash
	pVtabCtx               &VtabCtx
	aVTrans                &&VTable
	pDisconnect            &VTable
	aFunc                  Hash
	aCollSeq               Hash
	busyHandler            BusyHandler
	aDbStatic              [2]Db
	pSavepoint             &Savepoint
	nAnalysisLimit         int
	busyTimeout            int
	nSavepoint             int
	nStatement             int
	nDeferredCons          I64
	nDeferredImmCons       I64
	pnBytesFreed           &int
	pDbData                &DbClientData
	nSpill                 U64
}

union FuncDef_u {
	pHash       &FuncDef
	pDestructor &FuncDestructor
}

struct FuncDef {
	nArg      I16
	funcFlags u32
	pUserData voidptr
	pNext     &FuncDef
	xSFunc    fn (&Sqlite3_context, int, &&Sqlite3_value)
	xFinalize fn (&Sqlite3_context)
	xValue    fn (&Sqlite3_context)
	xInverse  fn (&Sqlite3_context, int, &&Sqlite3_value)
	zName     &i8
	u         FuncDef_u
}

struct FuncDestructor {
	nRef      int
	xDestroy  fn (voidptr)
	pUserData voidptr
}

struct Savepoint {
	zName            &i8
	nDeferredCons    I64
	nDeferredImmCons I64
	pNext            &Savepoint
}

struct Module {
	pModule    &Sqlite3_module
	zName      &i8
	nRefModule int
	pAux       voidptr
	xDestroy   fn (voidptr)
	pEpoTab    &Table
}

struct Column {
	zCnName  &i8
	notNull  u32
	eCType   u32
	affinity i8
	szEst    U8
	hName    U8
	iDflt    U16
	colFlags U16
}

struct CollSeq {
	zName &i8
	enc   U8
	pUser voidptr
	xCmp  fn (voidptr, int, voidptr, int, voidptr) int
	xDel  fn (voidptr)
}

struct VTable {
	db          &Sqlite3
	pMod        &Module
	pVtab       &Sqlite3_vtab
	nRef        int
	bConstraint U8
	bAllSchemas U8
	eVtabRisk   U8
	iSavepoint  int
	pNext       &VTable
}

struct Table_u_tab {
	addColOffset int
	pFKey        &FKey
	pDfltList    &ExprList
}

struct Table_u_view {
	pSelect &Select
}

struct Table_u_vtab {
	nArg  int
	azArg &&u8
	p     &VTable
}

union Table_u {
	tab  Table_u_tab
	view Table_u_view
	vtab Table_u_vtab
}

struct Table {
	zName      &i8
	aCol       &Column
	pIndex     &Index
	zColAff    &i8
	pCheck     &ExprList
	tnum       Pgno
	nTabRef    u32
	tabFlags   u32
	iPKey      I16
	nCol       I16
	nNVCol     I16
	nRowLogEst LogEst
	szTabRow   LogEst
	keyConf    U8
	eTabType   U8
	u          Table_u
	pTrigger   &Trigger
	pSchema    &Schema
	aHx        [16]U8
}

struct SColMap {
	iFrom int
	zCol  &i8
}

struct FKey {
	pFrom      &Table
	pNextFrom  &FKey
	zTo        &i8
	pNextTo    &FKey
	pPrevTo    &FKey
	nCol       int
	isDeferred U8
	aAction    [2]U8
	apTrigger  [2]&Trigger
	aCol       [1]SColMap
}

struct KeyInfo {
	nRef       u32
	enc        U8
	nKeyField  U16
	nAllField  U16
	db         &Sqlite3
	aSortFlags &U8
	aColl      [1]&CollSeq
}

union UnpackedRecord_u {
	z &i8
	i I64
}

struct UnpackedRecord {
	pKeyInfo   &KeyInfo
	aMem       &Mem
	u          UnpackedRecord_u
	n          int
	nField     U16
	default_rc I8
	errCode    U8
	r1         I8
	r2         I8
	eqSeen     U8
}

struct Index {
	zName         &i8
	aiColumn      &I16
	aiRowLogEst   &LogEst
	pTable        &Table
	zColAff       &i8
	pNext         &Index
	pSchema       &Schema
	aSortOrder    &U8
	azColl        &&u8
	pPartIdxWhere &Expr
	aColExpr      &ExprList
	tnum          Pgno
	szIdxRow      LogEst
	nKeyCol       U16
	nColumn       U16
	onError       U8
	idxType       u32
	bUnordered    u32
	uniqNotNull   u32
	isResized     u32
	isCovering    u32
	noSkipScan    u32
	hasStat1      u32
	bNoQuery      u32
	bAscKeyBug    u32
	bHasVCol      u32
	bHasExpr      u32
	colNotIdxed   Bitmask
}

struct IndexSample {
	p     voidptr
	n     int
	anEq  &TRowcnt
	anLt  &TRowcnt
	anDLt &TRowcnt
}

struct Token {
	z &i8
	n u32
}

struct AggInfo_col {
	pTab          &Table
	pCExpr        &Expr
	iTable        int
	iColumn       int
	iSorterColumn int
}

struct AggInfo_func {
	pFExpr      &Expr
	pFunc       &FuncDef
	iDistinct   int
	iDistAddr   int
	iOBTab      int
	bOBPayload  U8
	bOBUnique   U8
	bUseSubtype U8
}

struct AggInfo {
	directMode     U8
	useSortingIdx  U8
	nSortingColumn u32
	sortingIdx     int
	sortingIdxPTab int
	iFirstReg      int
	pGroupBy       &ExprList
	aCol           &AggInfo_col
	nColumn        int
	nAccumulator   int
	aFunc          &AggInfo_func
	nFunc          int
	selId          u32
}

type YnVar = i16

union Expr_u {
	zToken &i8
	iValue int
}

union Expr_x {
	pList   &ExprList
	pSelect &Select
}

union Expr_w {
	iJoin int
	iOfst int
}

struct Expr_y_sub {
	iAddr     int
	regReturn int
}

union Expr_y {
	pTab &Table
	pWin &Window
	nReg int
	sub  Expr_y_sub
}

struct Expr {
	op       U8
	affExpr  i8
	op2      U8
	flags    u32
	u        Expr_u
	pLeft    &Expr
	pRight   &Expr
	x        Expr_x
	nHeight  int
	iTable   int
	iColumn  YnVar
	iAgg     I16
	w        Expr_w
	pAggInfo &AggInfo
	y        Expr_y
}

struct ExprList_item_fg {
	sortFlags  U8
	eEName     u32
	done       u32
	reusable   u32
	bSorterRef u32
	bNulls     u32
	bUsed      u32
	bUsingTerm u32
	bNoExpand  u32
}

struct ExprList_item_u_x {
	iOrderByCol U16
	iAlias      U16
}

union ExprList_item_u {
	x             ExprList_item_u_x
	iConstExprReg int
}

struct ExprList_item {
	pExpr  &Expr
	zEName &i8
	fg     ExprList_item_fg
	u      ExprList_item_u
}

struct ExprList {
	nExpr  int
	nAlloc int
	a      [1]ExprList_item
}

struct IdList_item {
	zName &i8
}

struct IdList {
	nId int
	a   [1]IdList_item
}

struct Subquery {
	pSelect     &Select
	addrFillSub int
	regReturn   int
	regResult   int
}

struct SrcItem_fg {
	jointype       U8
	notIndexed     u32
	isIndexedBy    u32
	isSubquery     u32
	isTabFunc      u32
	isCorrelated   u32
	isMaterialized u32
	viaCoroutine   u32
	isRecursive    u32
	fromDDL        u32
	isCte          u32
	notCte         u32
	isUsing        u32
	isOn           u32
	isSynthUsing   u32
	isNestedFrom   u32
	rowidUsed      u32
	fixedSchema    u32
	hadSchema      u32
	fromExists     u32
}

union SrcItem_u1 {
	zIndexedBy &i8
	pFuncArg   &ExprList
	nRow       u32
}

union SrcItem_u2 {
	pIBIndex &Index
	pCteUse  &CteUse
}

union SrcItem_u3 {
	pOn    &Expr
	pUsing &IdList
}

union SrcItem_u4 {
	pSchema   &Schema
	zDatabase &i8
	pSubq     &Subquery
}

struct SrcItem {
	zName   &i8
	zAlias  &i8
	pSTab   &Table
	fg      SrcItem_fg
	iCursor int
	colUsed Bitmask
	u1      SrcItem_u1
	u2      SrcItem_u2
	u3      SrcItem_u3
	u4      SrcItem_u4
}

struct OnOrUsing {
	pOn    &Expr
	pUsing &IdList
}

struct SrcList {
	nSrc   int
	nAlloc u32
	a      [1]SrcItem
}

union NameContext_uNC {
	pEList   &ExprList
	pAggInfo &AggInfo
	pUpsert  &Upsert
	iBaseReg int
}

struct NameContext {
	pParse        &Parse
	pSrcList      &SrcList
	uNC           NameContext_uNC
	pNext         &NameContext
	nRef          int
	nNcErr        int
	ncFlags       int
	nNestedSelect u32
	pWinSelect    &Select
}

struct Upsert {
	pUpsertTarget      &ExprList
	pUpsertTargetWhere &Expr
	pUpsertSet         &ExprList
	pUpsertWhere       &Expr
	pNextUpsert        &Upsert
	isDoUpdate         U8
	isDup              U8
	pToFree            voidptr
	pUpsertIdx         &Index
	pUpsertSrc         &SrcList
	regData            int
	iDataCur           int
	iIdxCur            int
}

struct Select {
	op         U8
	nSelectRow LogEst
	selFlags   u32
	iLimit     int
	iOffset    int
	selId      u32
	pEList     &ExprList
	pSrc       &SrcList
	pWhere     &Expr
	pGroupBy   &ExprList
	pHaving    &Expr
	pOrderBy   &ExprList
	pPrior     &Select
	pNext      &Select
	pLimit     &Expr
	pWith      &With
	pWin       &Window
	pWinDefn   &Window
}

struct SelectDest {
	eDest    U8
	iSDParm  int
	iSDParm2 int
	iSdst    int
	nSdst    int
	zAffSdst &i8
	pOrderBy &ExprList
}

struct AutoincInfo {
	pNext  &AutoincInfo
	pTab   &Table
	iDb    int
	regCtr int
}

struct TriggerPrg {
	pTrigger &Trigger
	pNext    &TriggerPrg
	pProgram &SubProgram
	orconf   int
	aColmask [2]u32
}

type YDbMask = u32

struct IndexedExpr {
	pExpr         &Expr
	iDataCur      int
	iIdxCur       int
	iIdxCol       int
	bMaybeNullRow U8
	aff           U8
	pIENext       &IndexedExpr
}

struct ParseCleanup {
	pNext    &ParseCleanup
	pPtr     voidptr
	xCleanup fn (&Sqlite3, voidptr)
}

struct Parse_u1_cr {
	addrCrTab      int
	regRowid       int
	regRoot        int
	constraintName Token
}

struct Parse_u1_d {
	pReturning &Returning
}

union Parse_u1 {
	cr Parse_u1_cr
	d  Parse_u1_d
}

struct Parse {
	db               &Sqlite3
	zErrMsg          &i8
	pVdbe            &Vdbe
	rc               int
	nQueryLoop       LogEst
	nested           U8
	nTempReg         U8
	isMultiWrite     U8
	disableLookaside U8
	prepFlags        U8
	withinRJSubrtn   U8
	mSubrtnSig       U8
	eTriggerOp       U8
	eOrconf          U8
	disableTriggers  Bft
	mayAbort         Bft
	hasCompound      Bft
	bReturning       Bft
	bHasExists       Bft
	colNamesSet      Bft
	bHasWith         Bft
	okConstFactor    Bft
	checkSchema      Bft
	nRangeReg        int
	iRangeReg        int
	nErr             int
	nTab             int
	nMem             int
	szOpAlloc        int
	iSelfTab         int
	nNestSel         int
	nLabel           int
	nLabelAlloc      int
	aLabel           &int
	pConstExpr       &ExprList
	pIdxEpr          &IndexedExpr
	pIdxPartExpr     &IndexedExpr
	writeMask        YDbMask
	cookieMask       YDbMask
	nMaxArg          int
	nSelect          int
	nProgressSteps   u32
	nTableLock       int
	aTableLock       &TableLock
	pAinc            &AutoincInfo
	pToplevel        &Parse
	pTriggerTab      &Table
	pTriggerPrg      &TriggerPrg
	pCleanup         &ParseCleanup
	aTempReg         [8]int
	pOuterParse      &Parse
	sNameToken       Token
	oldmask          u32
	newmask          u32
	u1               Parse_u1
	sLastToken       Token
	nVar             YnVar
	iPkSortOrder     U8
	explain          U8
	eParseMode       U8
	nVtabLock        int
	nHeight          int
	addrExplain      int
	pVList           &VList
	pReprepare       &Vdbe
	zTail            &i8
	pNewTable        &Table
	pNewIndex        &Index
	pNewTrigger      &Trigger
	zAuthContext     &i8
	sArg             Token
	apVtabLock       &&Table
	pWith            &With
	pRename          &RenameToken
}

struct AuthContext {
	zAuthContext &i8
	pParse       &Parse
}

struct Trigger {
	zName      &i8
	table      &i8
	op         U8
	tr_tm      U8
	bReturning U8
	pWhen      &Expr
	pColumns   &IdList
	pSchema    &Schema
	pTabSchema &Schema
	step_list  &TriggerStep
	pNext      &Trigger
}

struct TriggerStep {
	op        U8
	orconf    U8
	pTrig     &Trigger
	pSelect   &Select
	pSrc      &SrcList
	pWhere    &Expr
	pExprList &ExprList
	pIdList   &IdList
	pUpsert   &Upsert
	zSpan     &i8
	pNext     &TriggerStep
	pLast     &TriggerStep
}

struct Returning {
	pParse    &Parse
	pReturnEL &ExprList
	retTrig   Trigger
	retTStep  TriggerStep
	iRetCur   int
	nRetCol   int
	iRetReg   int
	zName     [40]i8
}

struct Sqlite3_str {
	db          &Sqlite3
	zText       &i8
	nAlloc      u32
	mxAlloc     u32
	nChar       u32
	accError    U8
	printfFlags U8
}

struct RCStr {
	nRCRef U64
}

struct InitData {
	db         &Sqlite3
	pzErrMsg   &&u8
	iDb        int
	rc         int
	mInitFlags u32
	nInitRow   u32
	mxPage     Pgno
}

struct Sqlite3Config {
	bMemstat            int
	bCoreMutex          U8
	bFullMutex          U8
	bOpenUri            U8
	bUseCis             U8
	bSmallMalloc        U8
	bExtraSchemaChecks  U8
	mxStrlen            int
	neverCorrupt        int
	szLookaside         int
	nLookaside          int
	nStmtSpill          int
	m                   Sqlite3_mem_methods
	mutex               Sqlite3_mutex_methods
	pcache2             Sqlite3_pcache_methods2
	pHeap               voidptr
	nHeap               int
	mnReq               int
	mxReq               int
	szMmap              Sqlite3_int64
	mxMmap              Sqlite3_int64
	pPage               voidptr
	szPage              int
	nPage               int
	mxParserStack       int
	sharedCacheEnabled  int
	szPma               u32
	isInit              int
	inProgress          int
	isMutexInit         int
	isMallocInit        int
	isPCacheInit        int
	nRefInitMutex       int
	pInitMutex          &Sqlite3_mutex
	xLog                fn (voidptr, int, &i8)
	pLogArg             voidptr
	mxMemdbSize         Sqlite3_int64
	xTestCallback       fn (int) int
	bLocaltimeFault     int
	xAltLocaltime       fn (voidptr, voidptr) int
	iOnceResetThreshold int
	szSorterRef         u32
	iPrngSeed           u32
}

union Walker_u {
	pNC         &NameContext
	n           int
	iCur        int
	sz          int
	pSrcList    &SrcList
	pCCurHint   &C.CCurHint
	pRefSrcList &RefSrcList
	aiCol       &int
	pIdxCover   &IdxCover
	pGroupBy    &ExprList
	pSelect     &Select
	pRewrite    &WindowRewrite
	pConst      &WhereConst
	pRename     &RenameCtx
	pTab        &Table
	pCovIdxCk   &CoveringIndexCheck
	pSrcItem    &SrcItem
	pFix        &DbFixer
	aMem        &Mem
	pCheckOnCtx &CheckOnCtx
}

struct Walker {
	pParse           &Parse
	xExprCallback    fn (&Walker, &Expr) int
	xSelectCallback  fn (&Walker, &Select) int
	xSelectCallback2 fn (&Walker, &Select)
	walkerDepth      int
	eCode            U16
	mWFlags          U16
	u                Walker_u
}

struct DbFixer {
	pParse  &Parse
	w       Walker
	pSchema &Schema
	bTemp   U8
	zDb     &i8
	zType   &i8
	pName   &Token
}

struct Cte {
	zName   &i8
	pCols   &ExprList
	pSelect &Select
	zCteErr &i8
	pUse    &CteUse
	eM10d   U8
}

struct With {
	nCte   int
	bView  int
	pOuter &With
	a      [1]Cte
}

struct CteUse {
	nUse    int
	addrM9e int
	regRtn  int
	iCur    int
	nRowEst LogEst
	eM10d   U8
}

struct DbClientData {
	pNext       &DbClientData
	pData       voidptr
	xDestructor fn (voidptr)
	zName       [1]i8
}

struct Window {
	zName          &i8
	zBase          &i8
	pPartition     &ExprList
	pOrderBy       &ExprList
	eFrmType       U8
	eStart         U8
	eEnd           U8
	bImplicitFrame U8
	eExclude       U8
	pStart         &Expr
	pEnd           &Expr
	ppThis         &&Window
	pNextWin       &Window
	pFilter        &Expr
	pWFunc         &FuncDef
	iEphCsr        int
	regAccum       int
	regResult      int
	csrApp         int
	regApp         int
	regPart        int
	pOwner         &Expr
	nBufferCol     int
	iArgCol        int
	regOne         int
	regStartRowid  int
	regEndRowid    int
	bExprArgs      U8
}

struct PrintfArguments {
	nArg  int
	nUsed int
	apArg &&Sqlite3_value
}

struct FpDecode {
	n         int
	iDP       int
	z         &i8
	zBuf      [21]i8
	sign      i8
	isSpecial i8
}

@[c:'sqliteViewTriggers']
fn sqlite_view_triggers(arg &Parse, arg_2 &Table, arg_3 &Expr, arg_4 int, arg_5 &ExprList)
