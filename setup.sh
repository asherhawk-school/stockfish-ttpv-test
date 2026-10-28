#!/bin/bash
# Builds stock and edited Stockfish, downloads the opening book, and installs a
# match runner (cutechess-cli if possible, fastchess as a fallback).
# Everything goes into ./work next to this script.
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"
WORK="$ROOT/work"
SF_COMMIT=ff3a6c508ed731f0dcf253f4ddf646df19a62f84   # Stockfish master, 2026-10-25
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu)
mkdir -p "$WORK"

as_root() { if [ "$(id -u)" = 0 ]; then "$@"; elif sudo -n true 2>/dev/null; then sudo "$@"; else return 1; fi; }

build_stockfish() {  # $1 = folder name, $2 = optional patch
    local dir="$WORK/$1"
    if [ ! -d "$dir" ]; then
        git init -q "$dir"
        git -C "$dir" remote add origin https://github.com/official-stockfish/Stockfish.git
        git -C "$dir" fetch -q --depth 1 origin "$SF_COMMIT"
        git -C "$dir" checkout -q FETCH_HEAD
        if [ -n "${2:-}" ]; then git -C "$dir" apply "$2"; fi
    fi
    (cd "$dir/src" && { make -j"$JOBS" profile-build ARCH=native >"$WORK/build-$1.log" 2>&1 \
        || make -j"$JOBS" build ARCH=native >>"$WORK/build-$1.log" 2>&1; })
    echo "$1: $("$dir/src/stockfish" bench 2>&1 | grep 'Nodes searched')"
}

echo "== Building Stockfish ($JOBS cores)"
build_stockfish base
build_stockfish ttpv "$ROOT/ttpv.patch"

echo "== Downloading opening book"
if [ ! -f "$WORK/UHO_Lichess_4852_v1.epd" ]; then
    curl -sSL -o "$WORK/book.zip" https://github.com/official-stockfish/books/raw/master/UHO_Lichess_4852_v1.epd.zip
    (cd "$WORK" && unzip -o -q book.zip && rm book.zip)
fi

echo "== Installing match runner"
if command -v cutechess-cli >/dev/null || [ -x "$WORK/cutechess/build/cutechess-cli" ]; then
    echo "cutechess-cli already available"
else
    # cutechess needs Qt and CMake; install them if we have root, then build.
    if ! command -v cmake >/dev/null || ! { command -v qmake6 >/dev/null || [ -d /usr/lib/x86_64-linux-gnu/cmake/Qt6 ] || [ -d /usr/lib/aarch64-linux-gnu/cmake/Qt6 ]; }; then
        as_root apt-get update -qq >/dev/null 2>&1 && as_root apt-get install -y -qq cmake qt6-base-dev qt6-svg-dev >/dev/null 2>&1 || true
    fi
    if git clone -q --depth 1 https://github.com/cutechess/cutechess.git "$WORK/cutechess" 2>/dev/null \
        && cmake -S "$WORK/cutechess" -B "$WORK/cutechess/build" -DCMAKE_BUILD_TYPE=Release -DWITH_TESTS=OFF >"$WORK/build-cutechess.log" 2>&1 \
        && cmake --build "$WORK/cutechess/build" --target cli -j"$JOBS" >>"$WORK/build-cutechess.log" 2>&1; then
        echo "built cutechess-cli"
    else
        echo "cutechess-cli could not be built (see work/build-cutechess.log); falling back to fastchess"
        [ -d "$WORK/fastchess" ] || git clone -q --depth 1 https://github.com/Disservin/fastchess.git "$WORK/fastchess"
        (cd "$WORK/fastchess" && make -j"$JOBS" >"$WORK/build-fastchess.log" 2>&1)
        echo "built fastchess"
    fi
fi
echo "== Setup done"
