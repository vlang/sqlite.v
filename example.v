// A small program that uses the translated SQLite library in sqlite.v.
//
// Build and run it with:
//
//     v -old-compiler run .
module main

const sqlite_ok = 0
const sqlite_row = 100
const sqlite_done = 101

fn check(db &Sqlite3, rc int, what string) {
	if rc != sqlite_ok {
		msg := unsafe { cstring_to_vstring(&char(sqlite3_errmsg(db))) }
		eprintln('${what} failed: ${msg}')
		exit(1)
	}
}

// print_row is a `sqlite3_exec()` callback: it prints one result row.
fn print_row(_ voidptr, argc int, argv &&u8, col_names &&u8) int {
	mut parts := []string{}
	for i in 0 .. argc {
		name := unsafe { cstring_to_vstring(&char(col_names[i])) }
		value := if isnil(unsafe { argv[i] }) {
			'NULL'
		} else {
			unsafe { cstring_to_vstring(&char(argv[i])) }
		}
		parts << '${name}=${value}'
	}
	println(parts.join(' '))
	return 0
}

fn main() {
	mut db := &Sqlite3(unsafe { nil })
	check(db, sqlite3_open(c':memory:', &db), 'open')
	println('SQLite ${unsafe { cstring_to_vstring(&char(sqlite3_libversion())) }}')

	mut err := &u8(unsafe { nil })
	check(db, sqlite3_exec(db, c'CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT, score REAL)', unsafe { nil }, unsafe { nil }, &err), 'create table')

	// Insert rows with a prepared statement.
	mut stmt := &Sqlite3_stmt(unsafe { nil })
	check(db, sqlite3_prepare_v2(db, c'INSERT INTO users(name, score) VALUES (?, ?)', -1, &stmt, unsafe { nil }), 'prepare insert')
	users := {
		'alice': 9.5
		'bob':   7.25
		'carol': 8.0
	}
	for name, score in users {
		// A null destructor is SQLITE_STATIC: `name` outlives the statement.
		sqlite3_bind_text(stmt, 1, &i8(name.str), name.len, unsafe { nil })
		sqlite3_bind_double(stmt, 2, score)
		if sqlite3_step(stmt) != sqlite_done {
			check(db, 1, 'insert')
		}
		sqlite3_reset(stmt)
	}
	sqlite3_finalize(stmt)
	println('inserted ${users.len} rows, last rowid ${sqlite3_last_insert_rowid(db)}')

	// Read rows back.
	check(db, sqlite3_prepare_v2(db, c'SELECT id, name, score FROM users WHERE score > ? ORDER BY score DESC', -1, &stmt, unsafe { nil }), 'prepare select')
	sqlite3_bind_double(stmt, 1, 7.5)
	for sqlite3_step(stmt) == sqlite_row {
		id := sqlite3_column_int64(stmt, 0)
		name := unsafe { cstring_to_vstring(&char(sqlite3_column_text(stmt, 1))) }
		score := sqlite3_column_double(stmt, 2)
		println('${id}: ${name} ${score}')
	}
	sqlite3_finalize(stmt)

	// Or let sqlite3_exec() call back for every row.
	check(db, sqlite3_exec(db, c"SELECT count(*) AS n, avg(score) AS avg, group_concat(name, ', ') AS names FROM users", print_row, unsafe { nil }, &err), 'aggregate')
	check(db, sqlite3_exec(db, c"WITH RECURSIVE n(x) AS (SELECT 1 UNION ALL SELECT x + 1 FROM n WHERE x < 10) SELECT sum(x) AS sum, printf('%.3f', 22.0 / 7) AS approx FROM n", print_row, unsafe { nil }, &err), 'recursive cte')
	sqlite3_close(db)
}
