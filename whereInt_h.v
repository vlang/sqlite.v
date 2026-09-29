@[translated]
module main

struct WhereMemBlock {
	pNext &WhereMemBlock
	sz    U64
}

struct WhereRightJoin {
	iMatch     int
	regBloom   int
	regReturn  int
	addrSubrtn int
	endSubrtn  int
}

struct InLoop {
	iCur       int
	addrInTop  int
	iBase      int
	nPrefix    int
	eEndLoopOp U8
}

struct WhereLevel_u_in_ {
	nIn     int
	aInLoop &InLoop
}

union WhereLevel_u {
	in_          WhereLevel_u_in_
	pCoveringIdx &Index
}

struct WhereLevel {
	iLeftJoin    int
	iTabCur      int
	iIdxCur      int
	addrBrk      int
	addrHalt     int
	addrNxt      int
	addrSkip     int
	addrCont     int
	addrFirst    int
	addrBody     int
	regBignull   int
	addrBignull  int
	iLikeRepCntr u32
	addrLikeRep  int
	regFilter    int
	pRJ          &WhereRightJoin
	iFrom        U8
	op           U8
	p3           U8
	p5           U8
	p1           int
	p2           int
	u            WhereLevel_u
	pWLoop       &WhereLoop
	notReady     Bitmask
}

struct WhereLoop_u_btree {
	nEq          U16
	nBtm         U16
	nTop         U16
	nDistinctCol U16
	pIndex       &Index
	pOrderBy     &ExprList
}

struct WhereLoop_u_vtab {
	idxNum      int
	needFree    u32
	bOmitOffset u32
	bIdxNumHex  u32
	isOrdered   I8
	omitMask    U16
	idxStr      &i8
	mHandleIn   u32
}

union WhereLoop_u {
	btree WhereLoop_u_btree
	vtab  WhereLoop_u_vtab
}

struct WhereLoop {
	prereq      Bitmask
	maskSelf    Bitmask
	iTab        U8
	iSortIdx    U8
	rSetup      LogEst
	rRun        LogEst
	nOut        LogEst
	u           WhereLoop_u
	wsFlags     u32
	nLTerm      U16
	nSkip       U16
	nLSlot      U16
	aLTerm      &&WhereTerm
	pNextLoop   &WhereLoop
	aLTermSpace [3]&WhereTerm
}

struct WhereOrCost {
	prereq Bitmask
	rRun   LogEst
	nOut   LogEst
}

struct WhereOrSet {
	n U16
	a [3]WhereOrCost
}

struct WherePath {
	maskLoop  Bitmask
	revLoop   Bitmask
	nRow      LogEst
	rCost     LogEst
	rUnsort   LogEst
	isOrdered I8
	aLoop     &&WhereLoop
}

struct WhereTerm_u_x {
	leftColumn int
	iField     int
}

union WhereTerm_u {
	x        WhereTerm_u_x
	pOrInfo  &WhereOrInfo
	pAndInfo &WhereAndInfo
}

struct WhereTerm {
	pExpr       &Expr
	pWC         &WhereClause
	truthProb   LogEst
	wtFlags     U16
	eOperator   U16
	nChild      U8
	eMatchOp    U8
	iParent     int
	leftCursor  int
	u           WhereTerm_u
	prereqRight Bitmask
	prereqAll   Bitmask
}

struct WhereScan {
	pOrigWC   &WhereClause
	pWC       &WhereClause
	zCollName &i8
	pIdxExpr  &Expr
	k         int
	opMask    u32
	idxaff    i8
	iEquiv    u8
	nEquiv    u8
	aiCur     [11]int
	aiColumn  [11]I16
}

struct WhereClause {
	pWInfo  &WhereInfo
	pOuter  &WhereClause
	op      U8
	hasOr   U8
	nTerm   int
	nSlot   int
	nBase   int
	a       &WhereTerm
	aStatic [8]WhereTerm
}

struct WhereOrInfo {
	wc        WhereClause
	indexable Bitmask
}

struct WhereAndInfo {
	wc WhereClause
}

struct WhereMaskSet {
	bVarSelect int
	n          int
	ix         [64]int
}

struct WhereLoopBuilder {
	pWInfo     &WhereInfo
	pWC        &WhereClause
	pNew       &WhereLoop
	pOrSet     &WhereOrSet
	bldFlags1  u8
	bldFlags2  u8
	iPlanLimit u32
}

struct WhereInfo {
	pParse            &Parse
	pTabList          &SrcList
	pOrderBy          &ExprList
	pResultSet        &ExprList
	pSelect           &Select
	aiCurOnePass      [2]int
	iContinue         int
	iBreak            int
	savedNQueryLoop   int
	wctrlFlags        U16
	iLimit            LogEst
	nLevel            U8
	nOBSat            I8
	eOnePass          U8
	eDistinct         U8
	bDeferredSeek     u32
	untestedTerms     u32
	bOrderedInnerLoop u32
	sorted            u32
	bStarDone         u32
	bStarUsed         u32
	nRowOut           LogEst
	iTop              int
	iEndWhere         int
	pLoops            &WhereLoop
	pMemToFree        &WhereMemBlock
	revMask           Bitmask
	sWC               WhereClause
	sMaskSet          WhereMaskSet
	a                 [1]WhereLevel
}
