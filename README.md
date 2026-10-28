# Stockfish ttPv pruning test

A match at 15+0 (10,000 games by default on GitHub, 1000 locally) between stock Stockfish (commit `ff3a6c5`, 2026-10-25) and the same
version with `ttpv.patch` applied.

## The edit

`ttpv.patch` undoes Stockfish commit `dabffbce` ("Make pruning at ttpv nodes more aggressive"),
which fishtest measured at **-4.98 ± 2.1 Elo at short time control** (10+0.1, 28,584 games) but
kept because it gains at very long time controls. It removes `if (ss->ttPv) r += 929;` before the
shallow-depth pruning step and lowers the matching LMR constant from 3023 to 2094, so LMR is
unchanged and the only behavior change is less shallow pruning at ttPv nodes.

## Running it

On GitHub: Actions → Tournament → Run workflow. It splits the games across 20 runners and
shows the combined score on the run's summary page.

Locally:

```bash
./setup.sh            # builds both engines, downloads the opening book, installs a match runner
./run_tournament.sh   # plays 1000 games; progress in results/tournament.log
```

The match uses the UHO_Lichess_4852_v1 opening book, each opening played twice with colors
swapped, 1 thread and 16 MB hash per engine, and one fewer concurrent game than CPU cores.
Results end up in `results/summary.txt`, `results/tournament.log` and `results/tournament.pgn`.

Stockfish is GPLv3; `ttpv.patch` is a modification of it under the same license.
