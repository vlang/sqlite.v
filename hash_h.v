@[translated]
module main

struct Ht {
	count u32
	chain &HashElem
}

struct Hash {
	htsize u32
	count  u32
	first  &HashElem
	ht     &Ht
}

struct HashElem {
	next &HashElem
	prev &HashElem
	data voidptr
	pKey &i8
	h    u32
}
