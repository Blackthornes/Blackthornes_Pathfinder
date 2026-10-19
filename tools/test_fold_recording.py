"""Tests for tools/fold_recording.py. Run: python tools/test_fold_recording.py

A made-up save, shaped the way Logic/Recorder.lua keeps runs, is folded and
checked: the facts it gives, the pace, that no character key or name gets
through, and that a save can run no code.
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fold_recording import fold, load_recorded  # noqa: E402

checks = 0
failures = 0


def expect(what, ok, detail=""):
    global checks, failures
    checks += 1
    if not ok:
        failures += 1
        print(f"FAIL: {what} {detail}")


# A run in the Valley of Trials: the player walks, takes Cutting Teeth from
# Gornek, kills boars, hands it in, and opens a flight map.
walk = "".join('{ %d, "p", 1411, %s, 68 },' % (100 + 5 * i, 40 + 0.7 * i) for i in range(12))
kills = "".join('{ %d, "k", 3098, 1411, %s, 65 },' % (200 + 30 * i, 44 + i * 0.2) for i in range(12))
SAVE = """
BlackthornesPathfinderDB = {
    ["debug"] = false,
    ["recorded"] = {
        ["Player-1-0ABCDEF0"] = { ["runs"] = { {
            ["race"] = "Orc", ["class"] = "WARRIOR", ["side"] = "Horde", ["level"] = 1,
            ["started"] = 100,
            ["events"] = {
                { 100, "z", 1411 },
                %s
                { 160, "o", 788, 3143, "Cutting Teeth", 1411, 42.1, 68.3 },
                { 166, "a", 788, 1411, 42.1, 68.3 },
                { 170, "x", 2, 20, 900 },
                { 190, "j", 788, 1, 1, 10, 1411, 45.1, 65.9 },
                { 195, "j", 788, 1, 2, 10, false, false, false },
                %s
                { 600, "q", 788, "reward", 3143, 1411, 42.1, 68.3 },
                { 605, "t", 788, 150, 35, 1411, 42.1, 68.3 },
                { 610, "n", "taxi", 3310, "Doras", 1454, 45.1, 63.9 },
                { 611, "f", { 23, 0, 25, 1 } },
                { 900, "z", false },
            },
        } } },
    },
}
""" % (walk, kills)

MAPS = {"1411": {"name": "Durotar", "yards": [5287.5, 3525.0]}}

recorded = load_recorded(SAVE)
expect("the save's runs are read", "Player-1-0ABCDEF0" in recorded)
facts, pace = fold(recorded, MAPS)
q = facts["quests"].get("788", {})
expect("who offered it, and where", q.get("start") == {"npc": 3143, "at": [1411, 42.1, 68.3]}, q.get("start"))
expect("who took it back, and where", q.get("end") == {"npc": 3143, "at": [1411, 42.1, 68.3]}, q.get("end"))
expect("its title", q.get("title") == "Cutting Teeth")
expect("the side it was offered to", q.get("side") == "H", q.get("side"))
expect("the XP the game gave", q.get("xp") == [150])
expect("the level it was met at", q.get("level_seen") == 1, q.get("level_seen"))
expect("and the level it was handed in at", q.get("level_done") == 2, q.get("level_done"))
obj = q.get("obj", {}).get("1", {})
expect("where the objective moved on, without the spot the game kept back",
       obj.get("need") == 10 and obj.get("spots") == [[1411, 45.1, 65.9]], obj)
expect("where each mob was killed", len(facts["kills"].get("3098", [])) == 12)
expect("an NPC's name, kind and spot",
       facts["npcs"].get("3310") == {"kinds": ["taxi"], "name": "Doras", "at": [1454, 45.1, 63.9]},
       facts["npcs"].get("3310"))
expect("the flight paths seen", facts["flights_seen"] == [23, 25])
# 0.7 map units on Durotar's 5287.5 yards every 5 seconds is about 7.4 yards a second.
expect("the walking speed", abs(pace.get("run", 0) - 7.4) < 0.1, pace)
expect("the seconds a kill", pace.get("kill") == 30, pace)
expect("how long was recorded", pace.get("minutes_recorded") == 13, pace)

written = json.dumps(facts) + json.dumps(pace)
expect("no character key gets through", "Player-" not in written and "0ABCDEF0" not in written)
expect("no class or race of the player gets through", "WARRIOR" not in written)

# A save can run no code: it sees no os, io or require.
for bad in ('os.execute("echo hi")', 'io.open("x", "w")', 'require("os")'):
    try:
        load_recorded("BlackthornesPathfinderDB = {} " + bad)
        ok = False
    except Exception:
        ok = True
    expect(f"a save that tries {bad.split('(')[0]} is refused", ok)

expect("a save with no recorder runs gives nothing",
       load_recorded("BlackthornesPathfinderDB = { debug = true }") == {})

print(f"  fold_recording: {checks} checks, {failures} failure(s)")
sys.exit(1 if failures else 0)
