@[translated]
module main

struct BtreePayload {
	pKey  voidptr
	nKey  Sqlite3_int64
	pData voidptr
	aMem  &Sqlite3_value
	nMem  U16
	nData int
	nZero int
}
