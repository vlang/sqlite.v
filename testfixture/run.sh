#!/usr/bin/env bash
# Translates SQLite's Tcl test harness ("testfixture": sqlite3.c, the Tcl
# interface and SQLite's C test code) with c2v, builds it with V and runs
# SQLite's own test suite with the result.
#
# usage: testfixture/run.sh [veryquick|full|<testrunner arguments>...]
#
# Environment:
#   SQLITE_SRC  SQLite source tree, e.g. sqlite-src-3530400 (required)
#   C2V         c2v executable (default: c2v)
#   V           v executable (default: v)
#   TCL         Tcl 8.6 installation prefix (default: `brew --prefix tcl-tk@8`)
#   WORK        work directory (default: ./work)
#   JOBS        parallel test processes (default: number of CPUs)
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
: "${SQLITE_SRC:?set SQLITE_SRC to the SQLite source tree (sqlite-src-3530400)}"
SQLITE_SRC=$(cd "$SQLITE_SRC" && pwd)
C2V=${C2V:-c2v}
V=${V:-v}
TCL=${TCL:-$(brew --prefix tcl-tk@8 2>/dev/null || true)}
WORK=${WORK:-$PWD/work}
JOBS=${JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || nproc)}
if [ $# -eq 0 ]; then
	set -- veryquick
fi
mkdir -p "$WORK"
WORK=$(cd "$WORK" && pwd)
tcl_include=$(dirname "$(find "$TCL/include" -maxdepth 2 -name tcl.h | head -1)")

# 1. Configure and build SQLite natively. This generates the files the test
#    build compiles (sqlite3.c, tclsqlite-ex.c, sqlite_cfg.h, ...) and gives a
#    native testfixture to compare with.
native=$WORK/native
if [ ! -x "$native/testfixture" ]; then
	mkdir -p "$native"
	(cd "$native" && "$SQLITE_SRC/configure" --with-tcl="$TCL/lib" && make testfixture)
fi

# 2. Assemble the C project: the sources and headers `make testfixture` uses,
#    unmodified, next to each other.
project=$WORK/project
rm -rf "$project"
mkdir -p "$project"
copy() {
	if [ "$1" = build ]; then
		cp "$native/$(basename "$2")" "$project/"
	else
		cp "$SQLITE_SRC/$2" "$project/"
	fi
}
while read -r kind path; do
	copy "$kind" "$path"
	basename "$path" >>"$project/sources.txt"
done <"$here/sources.txt"
while read -r kind path; do
	copy "$kind" "$path"
done <"$here/headers.txt"

link_flags="-L$TCL/lib -ltcl8.6 -lz -lpthread"
if [ "$(uname)" = Darwin ]; then
	link_flags="$link_flags -framework CoreFoundation"
fi
includes="-I$native -I$SQLITE_SRC/src -I$SQLITE_SRC/ext/fts3 -I$SQLITE_SRC/ext/icu"
includes="$includes -I$SQLITE_SRC/ext/misc -I$SQLITE_SRC/ext/rtree -I$SQLITE_SRC/ext/session -I$tcl_include"
# The defines of `make testfixture` (TESTFIXTURE_FLAGS and the configured CFLAGS).
defines="-DBUILD_sqlite -DNDEBUG -DSQLITE_CKSUMVFS_STATIC -DSQLITE_CORE -DSQLITE_CRASH_TEST=1"
defines="$defines -DSQLITE_DEFAULT_PAGE_SIZE=1024 -DSQLITE_ENABLE_BYTECODE_VTAB -DSQLITE_ENABLE_CARRAY"
defines="$defines -DSQLITE_ENABLE_DBPAGE_VTAB -DSQLITE_ENABLE_MATH_FUNCTIONS -DSQLITE_ENABLE_PERCENTILE"
defines="$defines -DSQLITE_ENABLE_STMTVTAB -DSQLITE_HAVE_ZLIB=1 -DSQLITE_NO_SYNC=1 -DSQLITE_PRIVATE="
defines="$defines -DSQLITE_SERIES_CONSTRAINT_VERIFY=1 -DSQLITE_SERVER=1 -DSQLITE_STATIC_RANDOMJSON"
defines="$defines -DSQLITE_STRICT_SUBTYPE=1 -DSQLITE_TEST=1 -DSQLITE_THREADSAFE=1"
defines="$defines -DTCLSH_INIT_PROC=sqlite3TestInit -D_HAVE_SQLITE_CONFIG_H"
cat >"$project/c2v.toml" <<EOF
[project]
output_dirname = "out"
additional_flags = "$includes $defines"
single_module = true
generate_stubs = false
require_no_stubs = true
require_main = true
source_manifest = "sources.txt"
link_flags = "$link_flags"
skip_comments = true
EOF

# 3. Translate to V (the Clang AST of sqlite3.c is ~740 MB: a large initial GC
#    heap makes c2v much faster) and build with V.
(cd "$project" && GC_INITIAL_HEAP_SIZE=16000000000 "$C2V" "$project")
"$V" -old-compiler -w -o "$WORK/testfixture" "$project/out"

# 4. Run SQLite's test suite with the V build.
#    - misc7.test opens files until the descriptor limit is reached: with a
#      high limit it runs for hours (natively too).
#    - vtabH.test walks the whole file system and does not finish either
#      (natively too): it is stopped after a minute and reported as failed.
run=$WORK/run
rm -rf "$run"
mkdir -p "$run"
cd "$run"
ulimit -n 1024
"$WORK/testfixture" "$SQLITE_SRC/test/testrunner.tcl" --jobs "$JOBS" "$@" &
runner=$!
while kill -0 "$runner" 2>/dev/null; do
	sleep 10
	if pgrep -f "$WORK/testfixture .*/vtabH.test" >/dev/null; then
		sleep 60
		pkill -f "$WORK/testfixture .*/vtabH.test" || true
	fi
done
wait "$runner"
