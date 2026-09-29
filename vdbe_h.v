@[translated]
module main

type Mem = Sqlite3_value

struct SubrtnSig {
	selId     int
	bComplete U8
	zAff      &i8
	iTable    int
	iAddr     int
	regReturn int
}

union P4union {
	i          int
	p          voidptr
	z          &i8
	pI64       &I64
	pReal      &f64
	pFunc      &FuncDef
	pCtx       &Sqlite3_context
	pColl      &CollSeq
	pMem       &Mem
	pVtab      &VTable
	pKeyInfo   &KeyInfo
	ai         &u32
	pProgram   &SubProgram
	pTab       &Table
	pSubrtnSig &SubrtnSig
	pIdx       &Index
}

struct VdbeOp {
	opcode U8
	p4type i8
	p5     U16
	p1     int
	p2     int
	p3     int
	p4     P4union
}

struct SubProgram {
	aOp   &VdbeOp
	nOp   int
	nMem  int
	nCsr  int
	aOnce &U8
	token voidptr
	pNext &SubProgram
}

struct VdbeOpList {
	opcode U8
	p1     i8
	p2     i8
	p3     i8
}

type RecordCompare = fn (int, voidptr, &UnpackedRecord) int
