# Stockfish edit tests

Matches at 15+0 between stock Stockfish and the same version with one small patch from
`patches/` applied.

## Patches

| Patch | What it does | Result |
|---|---|---|
| `ttpv.patch` | Undoes commit `dabffbce` ("Make pruning at ttpv nodes more aggressive"): removes `if (ss->ttPv) r += 929;` before shallow-depth pruning and lowers the matching LMR constant from 3023 to 2094, so only the pruning changes. That commit was -4.98 ± 2.1 Elo at 10+0.1 but kept because it gained at very long time controls. | 11,008 games: +2.9 Elo (95% range -1.7 to +7.6) |

## Running it

On GitHub: Actions → Tournament → Run workflow. Pick the patch and, optionally, a Stockfish
commit (empty means the latest master). The games are split across 20 runners and the combined
score shows up on the run's summary page.

Locally:

```bash
PATCH=patches/ttpv.patch SF_COMMIT=<sha> ./setup.sh   # builds both engines, downloads the book, installs a match runner
./run_tournament.sh                                    # plays 1000 games; progress in results/tournament.log
```

The match uses the UHO_Lichess_4852_v1 opening book, each opening played twice with colors
swapped, 1 thread and 16 MB hash per engine, and one fewer concurrent game than CPU cores.
Results end up in `results/summary.txt`, `results/tournament.log` and `results/tournament.pgn`.

Stockfish is GPLv3; the patches are modifications of it under the same license.
