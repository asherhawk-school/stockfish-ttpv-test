#!/bin/bash
# 1000-game match at 15+0: edited Stockfish (ttpv.patch) vs stock.
# Each opening is played twice with colors swapped. Run setup.sh first.
# Usage: ./run_tournament.sh [games]   (default 1000)
set -euo pipefail
cd "$(dirname "$0")"
WORK="$PWD/work"
GAMES=${1:-1000}
CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu)
CONC=$(( CORES > 1 ? CORES - 1 : 1 ))   # leave one core free to avoid time losses
mkdir -p results

if command -v cutechess-cli >/dev/null; then CC=cutechess-cli; else CC="$WORK/cutechess/build/cutechess-cli"; fi

echo "Playing $GAMES games, $CONC at a time, log in results/tournament.log"
if [ -x "$CC" ] || command -v "$CC" >/dev/null; then
    "$CC" \
      -engine cmd="$WORK/ttpv/src/stockfish" name=edited \
      -engine cmd="$WORK/base/src/stockfish" name=stock \
      -each proto=uci tc=15+0 option.Hash=16 option.Threads=1 timemargin=100 \
      -openings file="$WORK/UHO_Lichess_4852_v1.epd" format=epd order=random \
      -rounds $(( GAMES / 2 )) -games 2 -repeat -concurrency "$CONC" -recover \
      -ratinginterval 10 -pgnout results/tournament.pgn \
      > results/tournament.log 2>&1
else
    "$WORK/fastchess/fastchess" \
      -engine cmd="$WORK/ttpv/src/stockfish" name=edited \
      -engine cmd="$WORK/base/src/stockfish" name=stock \
      -each tc=15+0 option.Hash=16 option.Threads=1 proto=uci timemargin=100 \
      -openings file="$WORK/UHO_Lichess_4852_v1.epd" format=epd order=random \
      -rounds $(( GAMES / 2 )) -games 2 -repeat -concurrency "$CONC" -recover \
      -ratinginterval 10 -pgnout file=results/tournament.pgn \
      > results/tournament.log 2>&1
fi

grep -E "^(Score of|Elo|Elo difference|Games|Ptnml|\.\.\.)" results/tournament.log | tail -8 | tee results/summary.txt
