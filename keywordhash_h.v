@[translated]
module main

@[c:'keywordCode']
fn keyword_code(z &i8, n I64, p_type &int) I64 {
	i := I64(0)
	j := I64(0)

	zkw := &i8(0)
	i = (I64((int(sqlite3UpperToLower[u8(z[0])]) * 4) ^ (int(sqlite3UpperToLower[u8(z[n - I64(1)])]) * 3)) ^ n * I64(1)) % I64(127)
	for i = I64(int(akw_hash[i])); i > I64(0); i = I64(akw_next[i]) {
		if I64(akw_len[i]) != n {
			continue
		}
		zkw = unsafe { &zKWText[0] + akw_offset[i] }
		if (int(z[0]) & ~32) != int(zkw[0]) {
			continue
		}
		if (int(z[1]) & ~32) != int(zkw[1]) {
			continue
		}
		j = I64(2)
		for j < n && (int(z[j]) & ~32) == int(zkw[j]) {
			j++
		}
		if j < n {
			continue
		}
		unsafe { *p_type = int(akw_code[i]) }
		break
	}
	return n
}

@[c:'sqlite3KeywordCode']
fn sqlite3_keyword_code(z &u8, n int) int {
	id := 60
	if n >= 2 {
		keyword_code(&i8(voidptr(z)), I64(n), &id)
	}
	return id
}

fn sqlite3_keyword_name(i int, pz_name &&u8, pn_name &int) int {
	c2v_gc_register_thread()
	if i < 0 || i >= 147 {
		return 1
	}
	i++
	unsafe { *pz_name = &zKWText[0] + int(akw_offset[i]) }
	unsafe { *pn_name = int(akw_len[i]) }
	return 0
}

fn sqlite3_keyword_count() int {
	c2v_gc_register_thread()
	return 147
}

fn sqlite3_keyword_check(z_name &i8, n_name int) int {
	c2v_gc_register_thread()
	return int(60 != sqlite3_keyword_code(&U8(voidptr(z_name)), n_name))
}
