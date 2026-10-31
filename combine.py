"""Combine the PGN files from all shards and print the overall result as Markdown.

Usage: python3 combine.py <folder with *.pgn files, searched recursively> [patch] [stockfish commit] [time control]
"""
import math
import pathlib
import re
import sys

wins = losses = draws = edited_time_losses = stock_time_losses = 0
for pgn in pathlib.Path(sys.argv[1]).rglob("*.pgn"):
    for game in pgn.read_text().split("[Event ")[1:]:
        white = re.search(r'\[White "([^"]+)"\]', game).group(1)
        result = re.search(r'\[Result "([^"]+)"\]', game).group(1)
        if result == "1/2-1/2":
            draws += 1
            continue
        if result not in ("1-0", "0-1"):
            continue
        edited_won = (result == "1-0") == (white == "edited")
        wins += edited_won
        losses += not edited_won
        if "on time" in game:
            if edited_won:
                stock_time_losses += 1
            else:
                edited_time_losses += 1

n = wins + losses + draws
patch, commit, tc = (sys.argv[2:] + ["", "", ""])[:3]
print(f"## {pathlib.Path(patch).stem or 'Edited'} vs stock Stockfish{' ' + commit[:8] if commit else ''}, {tc or '15+0'}\n")
if n == 0:
    print("No finished games found.")
    sys.exit()

score = (wins + draws / 2) / n
var = (wins * (1 - score) ** 2 + losses * score ** 2 + draws * (0.5 - score) ** 2) / n / n


def elo(s):
    s = min(max(s, 1e-6), 1 - 1e-6)
    return -400 * math.log10(1 / s - 1)


lo, hi = elo(score - 1.96 * math.sqrt(var)), elo(score + 1.96 * math.sqrt(var))
print(f"| Games | Wins | Losses | Draws | Score |\n|---|---|---|---|---|")
print(f"| {n} | {wins} | {losses} | {draws} | {100 * score:.1f}% |\n")
print(f"**Elo difference: {elo(score):+.1f}** (95% range {lo:+.1f} to {hi:+.1f})\n")
print(f"Games lost on time: edited {edited_time_losses}, stock {stock_time_losses}\n")
verdict = "better" if lo > 0 else "worse" if hi < 0 else "not distinguishable from stock"
print(f"Verdict: the edited version is **{verdict}** at this sample size.")
