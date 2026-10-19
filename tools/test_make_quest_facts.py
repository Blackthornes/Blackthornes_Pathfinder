"""Tests for tools/make_quest_facts.py. Run: python tools/test_make_quest_facts.py

The sources are too big to ship with the tests, so the pure parts are
checked with small made-up rows, and the facts written in tools/facts/ are
checked for shape: one quest a line, sorted, every spot on a map with 0 to
100 coordinates.
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_quest_facts import Maps, classic_xp, parse_row, thin  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
checks = 0
failures = 0


def expect(what, got, want):
    global checks, failures
    checks += 1
    if got != want:
        failures += 1
        print(f"FAIL: {what}: got {got!r}, want {want!r}")


# Classic's XP from the money at the level cap.
expect("no money gives no XP", classic_xp({"RewMoneyMaxLevel": 0, "QuestLevel": 5}), 0)
expect("a level 2 quest", classic_xp({"RewMoneyMaxLevel": 90, "QuestLevel": 2}), 150)
expect("a quest at 65 divides by 6", classic_xp({"RewMoneyMaxLevel": 600, "QuestLevel": 65}), 100)

# Spots are thinned evenly and never past the limit.
expect("a short list is kept whole", thin([1, 2, 3], 5), [1, 2, 3])
expect("a long list keeps the limit", len(thin(list(range(100)), 24)), 24)
expect("thinning keeps the first", thin(list(range(100)), 10)[0], 0)

# The SQL row parser, copied from Equipment's.
expect("a row with a quoted comma", parse_row("(1,'a, b',2.5,'it\\'s'),"), [1, "a, b", 2.5, "it's"])
expect("a row that runs on", parse_row("(1,'unfinished"), None)


# World spots to map spots, on a made-up continent with two maps that overlap.
class FakeMaps(Maps):
    def __init__(self):
        self.uimaps = {10: {"Name_lang": "Big", "Type": "3"}, 11: {"Name_lang": "Small", "Type": "4"}}
        self.assign = [
            {"MapID": "1", "UiMapID": "10", "Region_0": "0", "Region_1": "0", "Region_3": "100",
             "Region_4": "100", "UiMin_0": "0", "UiMin_1": "0", "UiMax_0": "1", "UiMax_1": "1"},
            {"MapID": "1", "UiMapID": "11", "Region_0": "40", "Region_1": "40", "Region_3": "60",
             "Region_4": "60", "UiMin_0": "0", "UiMin_1": "0", "UiMax_0": "1", "UiMax_1": "1"},
        ]


fake = FakeMaps()
expect("the north-west corner is the map's top left", fake.world_to_map(1, 100, 100), (10, 0.0, 0.0))
expect("the smaller map wins where both hold it", fake.world_to_map(1, 50, 50)[0], 11)
expect("a named map wins over a smaller one", fake.world_to_map(1, 50, 50, ("Big",))[0], 10)
expect("a spot on no map has none", fake.world_to_map(2, 50, 50), None)

# The facts written, when they are there.
path = os.path.join(HERE, "facts", "quests.jsonl")
if os.path.exists(path):
    ids, bad = [], []
    with open(path, encoding="utf-8") as f:
        for line in f:
            q = json.loads(line)
            ids.append(q["id"])

            def walk(value):
                if isinstance(value, dict):
                    for k, v in value.items():
                        if k in ("at", "spots"):
                            for s in v:
                                if not (isinstance(s[0], int) and 0 <= s[1] <= 100 and 0 <= s[2] <= 100):
                                    bad.append((q["id"], s))
                        else:
                            walk(v)
                elif isinstance(value, list):
                    for v in value:
                        walk(v)
            walk(q)
    expect("quests are sorted by ID, each once", ids, sorted(set(ids)))
    expect("every spot is a map and 0 to 100", bad[:3], [])

print(f"  make_quest_facts: {checks} checks, {failures} failure(s)")
sys.exit(1 if failures else 0)
