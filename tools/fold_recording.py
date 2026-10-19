"""Folds the recorder's runs into tools/facts/: what really happened while
leveling, for the planner.

    python tools/fold_recording.py <Blackthornes_Pathfinder.lua>

The argument is the account save from the owner's game
(WTF\\Account\\<account>\\SavedVariables\\Blackthornes_Pathfinder.lua). Only
`recorded` is read, inside a Lua sandbox with nothing in it, so the save can
run no code. Nothing names or keys a character in what is written: no GUID,
no character name, no date, only durations and what the game showed.

Writes:
  tools/facts/recorded.json  per quest: who offered it and where, who took
                             it back and where, where each objective moved
                             on, the XP the game gave and the level it was
                             met at; per mob: where it was killed; per NPC:
                             its name, kind and spot; flight paths seen
  tools/facts/pace.json      how fast the owner really plays: walking
                             speed and seconds a kill, the medians of every
                             run, which the planner uses over its guesses

tools/make_quest_facts.py lays recorded.json over the other facts, and
tools/plan_route.py reads pace.json. Rerun all three after each fold.
"""

import json
import math
import statistics
import sys
from collections import defaultdict
from pathlib import Path

from lupa import lua51

ROOT = Path(__file__).resolve().parent.parent
FACTS = ROOT / "tools" / "facts"

# A walk between two readings counts toward the walking speed only when the
# readings are this close in time, and the speed is a plausible run.
WALK_GAP = 12
WALK_FASTEST, WALK_SLOWEST = 15.0, 2.0
# Kills this close together count as one stretch of fighting.
KILL_GAP = 90
# At most this many spots per objective or mob.
SPOTS_MOST = 40


def load_recorded(text):
    """The save's `recorded` table, as plain Python, loaded in a sandbox."""
    lua = lua51.LuaRuntime(unpack_returned_tuples=True, register_eval=False)
    sandbox = lua.eval("""function(code)
        local env = {}
        local fn, err = loadstring(code, "save")
        if not fn then error(err) end
        setfenv(fn, env)
        fn()
        return env.BlackthornesPathfinderDB and env.BlackthornesPathfinderDB.recorded
    end""")
    return plain(sandbox(text)) or {}


def plain(value):
    if value is None or isinstance(value, (bool, int, float, str)):
        return value
    keys = list(value.keys())
    if keys and all(isinstance(k, int) for k in keys):
        return [plain(value[k]) for k in sorted(keys)]
    return {k: plain(v) for k, v in value.items()}


def spot(event, start):
    """The (map, x, y) an event ends with, or None."""
    m, x, y = event[start:start + 3] if len(event) >= start + 3 else (None, None, None)
    if isinstance(m, (int, float)) and m is not False and isinstance(x, (int, float)) and isinstance(y, (int, float)):
        if not isinstance(m, bool) and not isinstance(x, bool):
            return [int(m), round(float(x), 1), round(float(y), 1)]
    return None


def thin(spots):
    if len(spots) <= SPOTS_MOST:
        return spots
    step = len(spots) / SPOTS_MOST
    return [spots[int(i * step)] for i in range(SPOTS_MOST)]


def fold(recorded, maps):
    quests = defaultdict(dict)
    kills = defaultdict(list)
    npcs = {}
    flights = set()
    walks, gaps, minutes = [], [], 0.0

    def yards(a, b):
        if a[0] != b[0] or str(a[0]) not in maps:
            return None
        wide, tall = maps[str(a[0])]["yards"]
        return math.hypot((a[1] - b[1]) / 100 * wide, (a[2] - b[2]) / 100 * tall)

    for record in recorded.values():
        for run in (record or {}).get("runs") or []:
            events = run.get("events") or []
            level = run.get("level") or 0
            side = {"Horde": "H", "Alliance": "A"}.get(run.get("side"), "")
            last_spot, last_kill, flying = None, None, False
            if events:
                minutes += (events[-1][0] - events[0][0]) / 60
            for e in events:
                if not isinstance(e, list) or len(e) < 2:
                    continue
                t, kind = e[0], e[1]
                if kind == "x" and isinstance(e[2], int):
                    level = e[2]
                elif kind == "l" and isinstance(e[2], int):
                    level = e[2]
                elif kind == "p":
                    here = spot(e, 2)
                    if here and last_spot and not flying and t - last_spot[0] <= WALK_GAP and t > last_spot[0]:
                        d = yards(last_spot[1], here)
                        if d is not None:
                            speed = d / (t - last_spot[0])
                            if WALK_SLOWEST <= speed <= WALK_FASTEST:
                                walks.append(speed)
                    if here:
                        last_spot = (t, here)
                elif kind == "y":
                    flying = True
                elif kind == "d":
                    flying = False
                    last_spot = None
                elif kind == "z":
                    last_spot = None
                elif kind == "o" and isinstance(e[2], int):
                    q = quests[e[2]]
                    start = {"npc": e[3]} if isinstance(e[3], int) and not isinstance(e[3], bool) else {}
                    at = spot(e, 5)
                    if at:
                        start["at"] = at
                    if start:
                        q["start"] = start
                    if isinstance(e[4], str):
                        q["title"] = e[4]
                    q.setdefault("level_seen", level)
                    if side and side not in q.get("side", ""):
                        q["side"] = "".join(sorted(q.get("side", "") + side))
                elif kind == "j" and isinstance(e[2], int):
                    q = quests[e[2]]
                    objs = q.setdefault("obj", {})
                    n = str(e[3])
                    o = objs.setdefault(n, {"need": e[5], "spots": []})
                    at = spot(e, 6)
                    if at:
                        o["spots"].append(at)
                elif kind == "q" and isinstance(e[2], int):
                    end = {"npc": e[4]} if isinstance(e[4], int) and not isinstance(e[4], bool) else {}
                    at = spot(e, 5)
                    if at:
                        end["at"] = at
                    if end:
                        quests[e[2]]["end"] = end
                elif kind == "t" and isinstance(e[2], int):
                    q = quests[e[2]]
                    if isinstance(e[3], int) and not isinstance(e[3], bool):
                        q.setdefault("xp", []).append(e[3])
                    q.setdefault("level_done", level)
                elif kind == "k" and isinstance(e[2], int):
                    at = spot(e, 3)
                    if at:
                        kills[e[2]].append(at)
                    if last_kill is not None and 0 < t - last_kill <= KILL_GAP:
                        gaps.append(t - last_kill)
                    last_kill = t
                elif kind == "n" and isinstance(e[3], int) and not isinstance(e[3], bool):
                    entry = npcs.setdefault(str(e[3]), {"kinds": []})
                    if e[2] not in entry["kinds"]:
                        entry["kinds"].append(e[2])
                    if isinstance(e[4], str):
                        entry["name"] = e[4]
                    at = spot(e, 5)
                    if at:
                        entry["at"] = at
                elif kind == "f" and isinstance(e[2], list):
                    pairs = e[2]
                    for i in range(0, len(pairs) - 1, 2):
                        flights.add(pairs[i])

    for q in quests.values():
        for o in (q.get("obj") or {}).values():
            o["spots"] = thin(o["spots"])
    facts = {
        "quests": {str(k): v for k, v in sorted(quests.items())},
        "kills": {str(k): thin(v) for k, v in sorted(kills.items())},
        "npcs": dict(sorted(npcs.items(), key=lambda kv: int(kv[0]))),
        "flights_seen": sorted(flights),
    }
    pace = {"minutes_recorded": round(minutes)}
    if len(walks) >= 10:
        pace["run"] = round(statistics.median(walks), 2)
    if len(gaps) >= 10:
        pace["kill"] = round(statistics.median(gaps), 1)
    return facts, pace


def main(argv):
    if not argv:
        raise SystemExit(__doc__)
    text = Path(argv[0]).read_text(encoding="utf-8", errors="replace")
    recorded = load_recorded(text)
    maps = json.load(open(FACTS / "maps.json", encoding="utf-8"))
    facts, pace = fold(recorded, maps)
    with open(FACTS / "recorded.json", "w", encoding="utf-8", newline="\n") as f:
        json.dump(facts, f, ensure_ascii=False, indent=1)
        f.write("\n")
    with open(FACTS / "pace.json", "w", encoding="utf-8", newline="\n") as f:
        json.dump(pace, f, indent=1)
        f.write("\n")
    print(f"{len(facts['quests'])} quests, {len(facts['kills'])} mobs, {len(facts['npcs'])} NPCs, "
          f"{pace['minutes_recorded']} minutes; pace {pace}")


if __name__ == "__main__":
    main(sys.argv[1:])
