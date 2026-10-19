"""Checks every route in Data/Routes/ (docs/STEP_FORMAT.md, "Checking a route").
Run: python tools/test_routes.py

Each route file is loaded the way the game would load it, then refused when
a step has no action or two, a field nobody reads (a typo would do nothing),
a quest finished or handed in before the route picks it up, two steps with
one key, a spot off its map, an ID that is not a whole number, a race or
class the game does not have, or a `next` route that does not exist. A few
made-up routes check that each rule catches what it should.
"""

import os
import sys
from pathlib import Path

from lupa import lua51

ROOT = Path(__file__).resolve().parent.parent
ACTIONS = ("accept", "finish", "turnin", "go", "getfp", "fly", "home", "hearth",
           "buy", "train", "level", "use", "note")
FIELDS = set(ACTIONS) | {"at", "near", "npc", "obj", "for", "reward", "class", "race", "prof",
                         "optional", "key", "xp", "secs", "count"}
ROUTE_FIELDS = {"title", "side", "races", "levels", "next", "plan", "steps"}
RACES = {"Orc", "Troll", "Tauren", "Scourge", "Human", "Dwarf", "NightElf", "Gnome"}
CLASSES = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID"}
QUESTS = ("accept", "finish", "turnin")


def load(text):
    """The routes a file adds to ns.Routes, as plain Python."""
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    ns = lua.eval("{}")
    lua.compile(text)("Blackthornes_Pathfinder", ns)
    return plain(ns["Routes"]) or {}


def plain(value):
    if hasattr(value, "items"):
        keys = list(value.keys())
        if keys and all(isinstance(k, int) for k in keys) and sorted(keys) == list(range(1, len(keys) + 1)):
            return [plain(value[k]) for k in sorted(keys)]
        return {k: plain(v) for k, v in value.items()}
    return value


def whole(v):
    return isinstance(v, int) and not isinstance(v, bool) or isinstance(v, float) and v == int(v)


def listed(v):
    return v if isinstance(v, list) else [v]


def key_of(step):
    if "key" in step:
        return step["key"]
    for action in ACTIONS:
        if action in step:
            key = f"{action}:{step[action]}"
            return key + (f":{step['obj']}" if action == "finish" and "obj" in step else "")
    return "?"


def problems(routes, every_route):
    out = []
    for name, route in routes.items():
        for field in route:
            if field not in ROUTE_FIELDS:
                out.append(f"{name}: unknown route field {field}")
        if route.get("next") and route["next"] not in every_route:
            out.append(f"{name}: next route {route['next']} does not exist")
        seen, keys = set(), set()
        for n, step in enumerate(route.get("steps") or [], 1):
            where = f"{name} step {n}"
            actions = [a for a in ACTIONS if a in step]
            if len(actions) != 1:
                out.append(f"{where}: {len(actions)} actions ({', '.join(actions) or 'none'})")
            for field in step:
                if field not in FIELDS:
                    out.append(f"{where}: unknown field {field}")
            for field in ("accept", "turnin", "npc", "getfp", "fly", "buy", "use", "for", "reward"):
                if field in step and not whole(step[field]):
                    out.append(f"{where}: {field} is not a whole number")
            if "finish" in step and not all(whole(q) for q in listed(step["finish"])):
                out.append(f"{where}: finish is not a quest ID")
            at = step.get("at")
            if at is not None:
                if not (isinstance(at, list) and len(at) == 3 and whole(at[0])
                        and all(isinstance(c, (int, float)) and 0 <= c <= 100 for c in at[1:])):
                    out.append(f"{where}: at is not {{ map, x, y }} with x and y 0 to 100")
            for field, allowed in (("race", RACES), ("class", CLASSES)):
                for v in listed(step.get(field, [])):
                    if v not in allowed:
                        out.append(f"{where}: no such {field} {v}")
            for action in ("finish", "turnin"):
                for q in listed(step.get(action, [])):
                    if q not in seen:
                        out.append(f"{where}: {action} {q} before the route picks it up")
            if "accept" in step:
                seen.add(step["accept"])
            key = key_of(step)
            if key in keys:
                out.append(f"{where}: a second step named {key}")
            keys.add(key)
    return out


checks = 0
failures = 0


def expect(what, ok):
    global checks, failures
    checks += 1
    if not ok:
        failures += 1
        print(f"FAIL: {what}")


# The routes that ship.
every = {}
files = sorted((ROOT / "Data" / "Routes").glob("*.lua"))
for path in files:
    every.update(load(path.read_text(encoding="utf-8")))
found = problems(every, every)
for p in found[:10]:
    print("  " + p)
expect(f"the {len(files)} route file(s) pass every rule", not found)


# Each rule catches what it should.
def made_up(steps, extra=""):
    return load('local _, ns = ...\nns.Routes = {}\nns.Routes["t"] = { title = "T", %s steps = { %s } }\n'
                % (extra, steps))


GOOD = '{ accept = 1, at = { 1411, 40, 60 } }, { finish = 1 }, { turnin = 1 }, { train = 4 }'
expect("a good route passes", not problems(made_up(GOOD), {"t"}))
cases = [
    ("a step with two actions", '{ accept = 1, turnin = 1 }'),
    ("a step with no action", '{ at = { 1411, 40, 60 } }'),
    ("a field nobody reads", '{ accept = 1, nps = 3 }'),
    ("a hand-in before the pick-up", '{ turnin = 2 }'),
    ("two steps of one name", '{ accept = 1 }, { accept = 1 }'),
    ("a spot off the map", '{ accept = 1, at = { 1411, 140, 60 } }'),
    ("a quest ID that is not whole", '{ accept = 1.5 }'),
    ("a class that does not exist", '{ accept = 1, class = { "BARD" } }'),
]
for what, steps in cases:
    expect(f"{what} is refused", bool(problems(made_up(steps), {"t"})))
expect("a next route that does not exist is refused",
       bool(problems(made_up(GOOD, 'next = "nowhere",'), {"t"})))

print(f"  routes: {checks} checks, {failures} failure(s)")
sys.exit(1 if failures else 0)
