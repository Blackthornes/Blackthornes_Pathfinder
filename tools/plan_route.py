"""Plans a route: the fastest order of quests from tools/facts/, written as
a Data/Routes/ file the guide follows.

    python tools/plan_route.py <route>      e.g. valley-of-trials
    python tools/plan_route.py --list

How it plans (docs/STEP_FORMAT.md, "The fastest route"):

  * A character is walked through the route in a simulation: where it
    stands, its level and XP, the quests in its log and what each still
    needs, and the time. Picking up and handing in a quest is a walk and a
    talk; an objective is a walk to where its mobs or objects are, then
    the kills or loot it takes (an item that drops 80% of the time takes
    1.25 kills a item). Every kill counts for every quest in the log that
    wants that mob or its drop, and gives XP by Classic's formula.
  * A beam search tries the orders: at each step it keeps the BEAM states
    closest to done (time spent plus the least time the XP still needed
    could take). A route is done once it reaches its level with its
    hand-off quests in the log, but may go on: XP past that level counts
    at the rate the next route is expected to give (`rate_next`), so a
    quest here is kept only while it beats moving on. The best route is
    the one with the least time once that XP is counted.
  * Grinding comes in only when no quest is left and the level is not
    reached, on the mob that gives the most XP a minute.
  * The first race and class is planned freely. Every other race and class
    then keeps that order and only adds its own quests where they cost
    least, and drops the ones it can't take, so one step list serves all
    of them, each step marked with who it is for.
  * A quest that teaches a spell the class needs (the shaman's totems) is
    always done. A quest picked up and never handed in is dropped.
  * Training is added, for each class, at the first stop by the trainers
    after a level its trainer has new spells at (tools/facts/training.json).

Every time and speed below is a guess until the recorder times real runs;
they are named in one place so a run can replace them. The route file is
generated: fix a step in the facts (or PROBED in tools/make_quest_facts.py)
or here, then run this again. Never edit a route by hand.
"""

import datetime
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FACTS = ROOT / "tools" / "facts"
ROUTES_DIR = ROOT / "Data" / "Routes"

# --- Guesses, until runs are recorded -----------------------------------
RUN = 7.0            # yards a second, on foot
DETOUR = 1.3         # paths are longer than a straight line
TALK = 6.0           # seconds to pick up or hand in a quest
KILL = 14.0          # seconds a fight takes at these levels
REST = 4.0           # seconds of eating and drinking a kill
LOOT = 6.0           # seconds to loot an object
UNPLACED = 90.0      # seconds for an objective no source places
TRAIN = 20.0         # seconds at a trainer
GRIND_KILLS = 5      # kills in one grind step
BEAM = 300

# Classic's XP to the next level, from level 1. Forever's is not in its
# client tables; the recorder will show whether it differs.
XP_TO_LEVEL = [400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600, 8800, 10100,
               11400, 12900, 14400, 16000, 17700, 19400, 21300, 23200, 25200, 27300,
               29400, 31700, 34000, 36400, 38900, 41400, 44300, 47400, 50800]

RACE_BITS = {"Orc": 2, "Undead": 16, "Tauren": 32, "Troll": 128,
             "Human": 1, "Dwarf": 4, "NightElf": 8, "Gnome": 64}
CLASS_BITS = {"WARRIOR": 1, "PALADIN": 2, "HUNTER": 4, "ROGUE": 8, "PRIEST": 16,
              "SHAMAN": 64, "MAGE": 128, "WARLOCK": 256, "DRUID": 1024}

ROUTES = {
    "valley-of-trials": {
        "title": "Valley of Trials",
        "side": "H",
        "map": 1411,
        "box": (36, 52, 48, 80),           # x from, x to, y from, y to on the map
        "start": (1411, 43.3, 68.5),       # Kaltunk, the first quest giver
        "places": {"the Den": (1411, 42.1, 68.3)},   # Gornek stands in the Den
        "trainers": (1411, 42.1, 68.3),
        "levels": (1, 5),                  # starts at 1, done at 5 at the soonest
        "rate_next": 2.0,                  # XP a second the next route gives, a guess
        "handoff": [805],                  # Report to Sen'jin Village, taken to the next route
        "next": None,
        "who": {
            "Orc": ["WARRIOR", "HUNTER", "ROGUE", "SHAMAN", "WARLOCK"],
            "Troll": ["WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE"],
        },
        "first": ("Orc", "WARRIOR"),
    },
}


# --- Classic's XP -------------------------------------------------------

def zero_difference(level):
    for top, zd in ((7, 5), (9, 6), (11, 7), (15, 8), (19, 9), (29, 11), (39, 12),
                    (44, 13), (49, 14), (54, 15)):
        if level <= top:
            return zd
    return 16


def gray_level(level):
    if level <= 5:
        return 0
    if level <= 39:
        return level - level // 10 - 5
    return level - level // 5 - 1


def kill_xp(level, mob):
    """XP for a kill, by Classic's formula."""
    if mob is None:
        mob = level
    base = level * 5 + 45
    if mob >= level:
        return base * (1 + 0.05 * min(mob - level, 4))
    if mob <= gray_level(level):
        return 0
    return base * (1 - (level - mob) / zero_difference(level))


def quest_xp(level, quest_level, xp):
    """A quest's XP for a character of `level`: less once it is 6 or more below."""
    over = level - quest_level
    if over <= 5:
        return xp
    return xp * {6: 0.8, 7: 0.6, 8: 0.4, 9: 0.2}.get(over, 0.1)


# --- Facts --------------------------------------------------------------

def load_facts():
    quests = {}
    with open(FACTS / "quests.jsonl", encoding="utf-8") as f:
        for line in f:
            q = json.loads(line)
            quests[q["id"]] = q
    maps = json.load(open(FACTS / "maps.json", encoding="utf-8"))
    training = json.load(open(FACTS / "training.json", encoding="utf-8"))
    return quests, maps, training


class Need:
    """One thing a quest still wants: kills of a mob, or loot from a mob or object."""

    def __init__(self, source, kind, count, chance, spots, level, label):
        self.source, self.kind = source, kind          # ("npc", id) or ("object", id) or None
        self.count, self.chance = count, chance / 100.0
        self.spots, self.level, self.label = spots, level, label

    def area(self):
        """The real spawn nearest the middle of the spawns."""
        if not self.spots:
            return None
        mx = sum(s[1] for s in self.spots) / len(self.spots)
        my = sum(s[2] for s in self.spots) / len(self.spots)
        best = min(self.spots, key=lambda s: (s[1] - mx) ** 2 + (s[2] - my) ** 2)
        return tuple(best)


class Planner:
    def __init__(self, name):
        if name not in ROUTES:
            raise SystemExit(f"no route {name}; known: {', '.join(ROUTES)}")
        self.name, self.route = name, ROUTES[name]
        self.facts, self.maps, self.training = load_facts()
        self.pool = self.quests_here()

    # Places and walking.

    def yards(self, a, b):
        if a is None or b is None:
            return 0.0
        if a[0] != b[0]:
            return 9999.0
        wide, tall = self.maps[str(a[0])]["yards"]
        return math.hypot((a[1] - b[1]) / 100 * wide, (a[2] - b[2]) / 100 * tall)

    def walk(self, a, b):
        return self.yards(a, b) * DETOUR / RUN

    def inside(self, at):
        x0, x1, y0, y1 = self.route["box"]
        return at and at[0] == self.route["map"] and x0 <= at[1] <= x1 and y0 <= at[2] <= y1

    def spot_of(self, ends):
        for e in ends or []:
            if e.get("at"):
                return tuple(e["at"][0])
            if e.get("place") in self.route["places"]:
                return self.route["places"][e["place"]]
        return None

    # Which quests the route can use.

    def quests_here(self):
        lo, hi = self.route["levels"]
        bits = sum(RACE_BITS[r] for r in self.route["who"])
        pool = {}
        for q in self.facts.values():
            start = self.spot_of(q.get("start"))
            if not self.inside(start) or q["lvl"] > hi + 2 or q.get("event") or q.get("skill"):
                continue
            if q.get("races") and not q["races"] & bits:
                continue
            if q["forever"] == "new" and self.route["side"] not in (q.get("side") or ""):
                continue
            end = self.spot_of(q.get("end"))
            if q["id"] not in self.route["handoff"] and not self.inside(end):
                continue
            pool[q["id"]] = q
        return pool

    def for_who(self, q, race, cls):
        if q.get("races") and not q["races"] & RACE_BITS[race]:
            return False
        if q.get("classes") and not q["classes"] & CLASS_BITS[cls]:
            return False
        return True

    def needs(self, q):
        """What a quest wants before it can be handed in, as Needs."""
        if q["id"] in self.route["handoff"]:
            return []
        out = []
        obj = q.get("obj") or {}
        for k in obj.get("kill", []):
            out.append(Need(("npc", k["npc"]), "kill", k.get("count") or 1, 100,
                            [tuple(s) for s in k.get("spots", [])], k.get("lvl"), k["name"]))
        for o in obj.get("object", []):
            out.append(Need(("object", o["object"]), "loot", 1, 100,
                            [tuple(s) for s in o.get("spots", [])], None, o["name"]))
        for it in obj.get("item", []):
            sources = [d for d in it.get("from", []) if d.get("spots")]
            if not sources:
                out.append(Need(None, "unplaced", it.get("count") or 1, 100, [], None, it["name"]))
                continue
            best = sources[0]
            kind = "npc" if "npc" in best else ("object" if "object" in best else "vendor")
            sid = best.get("npc") or best.get("object") or best.get("vendor")
            out.append(Need((kind, sid), "loot", it.get("count") or 1, best.get("chance", 100),
                            [tuple(s) for s in best["spots"]], best.get("lvl"), it["name"]))
        return out

    # The simulation.

    def start_state(self):
        return {"at": self.route["start"], "t": 0.0, "level": self.route["levels"][0], "xp": 0.0,
                "log": {}, "done": frozenset(), "taken": frozenset(), "path": ()}

    def gain(self, s, xp):
        s["xp"] += xp
        while s["level"] - 1 < len(XP_TO_LEVEL) and s["xp"] >= XP_TO_LEVEL[s["level"] - 1]:
            s["xp"] -= XP_TO_LEVEL[s["level"] - 1]
            s["level"] += 1

    def total_xp(self, s):
        return sum(XP_TO_LEVEL[:s["level"] - 1]) + s["xp"]

    def available(self, s, q, race, cls):
        qid = q["id"]
        if qid in s["taken"] or not self.for_who(q, race, cls):
            return False
        if q.get("min", 0) > s["level"]:
            return False
        pre = [p for p in q.get("pre", []) if p in self.facts]
        if pre and not any(p in s["done"] for p in pre):
            # "pre" lists other ways in; any one of them done will do, and
            # one this character can never take counts as not needed.
            if any(self.for_who(self.facts[p], race, cls) for p in pre):
                return False
        return len(s["log"]) < 20

    def actions(self, s, race, cls, only=None):
        """Every legal next action, or only those whose quest is in `only`."""
        out = []
        for qid, q in self.pool.items():
            if only is not None and qid not in only:
                continue
            if qid not in s["log"] and self.available(s, q, race, cls):
                out.append(("accept", qid, None))
            elif qid in s["log"]:
                left = s["log"][qid]
                for i, n in enumerate(left):
                    if n > 1e-6:
                        out.append(("work", qid, i))
                if all(n <= 1e-6 for n in left) and qid not in self.route["handoff"]:
                    out.append(("turnin", qid, None))
        return out

    def apply(self, s, action):
        kind, qid, i = action
        q = self.pool[qid]
        s = dict(s, log=dict(s["log"]))
        before = s["t"]
        if kind == "accept":
            at = self.spot_of(q.get("start"))
            s["t"] += self.walk(s["at"], at) + TALK
            s["at"] = at or s["at"]
            s["log"][qid] = tuple(n.count for n in self.needs(q))
            s["taken"] = s["taken"] | {qid}
            xp = 0
        elif kind == "turnin":
            at = self.spot_of(q.get("end"))
            s["t"] += self.walk(s["at"], at) + TALK
            s["at"] = at or s["at"]
            xp = quest_xp(s["level"], q["lvl"], q.get("xp") or q.get("xp_forever") or 0)
            self.gain(s, xp)
            del s["log"][qid]
            s["done"] = s["done"] | {qid}
        else:
            need = self.needs(q)[i]
            left = s["log"][qid][i]
            xp = 0
            if need.kind == "unplaced":
                s["t"] += UNPLACED
                self.settle(s, qid, i, left)
            else:
                at = need.area()
                s["t"] += self.walk(s["at"], at)
                s["at"] = at or s["at"]
                tries = math.ceil(left / need.chance - 1e-9)
                between = self.between(need)
                for _ in range(tries):
                    if need.source[0] == "npc":
                        s["t"] += KILL + REST + between
                        got = kill_xp(s["level"], need.level)
                        xp += got
                        self.gain(s, got)
                    else:
                        s["t"] += LOOT + between
                # Every quest in the log that wants this mob or its loot
                # moves on too.
                for other, rest in list(s["log"].items()):
                    wanted = list(rest)
                    for j, n in enumerate(self.needs(self.pool[other])):
                        if n.source == need.source and wanted[j] > 0:
                            got = tries if n.kind == "kill" else tries * n.chance
                            wanted[j] = max(0.0, wanted[j] - got)
                    s["log"][other] = tuple(wanted)
                self.settle(s, qid, i, left)
        s["path"] = s["path"] + ((action, round(s["t"] - before, 1), round(xp), s["level"], s["at"]),)
        return s

    def settle(self, s, qid, i, left):
        wanted = list(s["log"][qid])
        wanted[i] = 0.0
        s["log"][qid] = tuple(wanted)

    def between(self, need):
        """Seconds walking from one spawn to the next: half the mean gap to the nearest."""
        spots = need.spots
        if len(spots) < 2:
            return 20.0
        gaps = []
        for a in spots:
            gaps.append(min(self.yards(a, b) for b in spots if b is not a))
        return min(12.0, sum(gaps) / len(gaps) * DETOUR / RUN / 2)

    def finished(self, s):
        hi = self.route["levels"][1]
        return (s["level"] >= hi and all(h in s["taken"] for h in self.route["handoff"] if h in self.pool)
                and all(q in s["done"] for q in s.get("must", ())))

    def musts(self, race, cls):
        """Quests that teach this class a spell: never left out."""
        return frozenset(q for q, f in self.pool.items()
                         if f.get("spell") and f.get("classes") and self.for_who(f, race, cls))

    def score(self, s):
        """Time, less the time XP past the route's level saves the next route."""
        hi = self.route["levels"][1]
        past = self.total_xp(s) - sum(XP_TO_LEVEL[:hi - 1])
        return s["t"] - max(0.0, past) / self.route["rate_next"]

    def estimate(self, s):
        """Time spent, plus the least the XP still needed could take."""
        if self.finished(s):
            return self.score(s)
        hi = self.route["levels"][1]
        still = max(0.0, sum(XP_TO_LEVEL[:hi - 1]) - self.total_xp(s))
        best_rate = kill_xp(s["level"], s["level"]) / (KILL + REST) * 3
        return s["t"] + still / best_rate

    def key(self, s):
        return (s["done"], tuple(sorted((k, tuple(round(n, 1) for n in v)) for k, v in s["log"].items())),
                s["at"], s["level"])

    # The search.

    def search(self, race, cls, base=None):
        """The quickest path for one race and class. With `base`, the base's
        order is kept and only quests the base lacks are added."""
        start = self.start_state()
        start["base"] = 0
        start["must"] = self.musts(race, cls)
        extra = None
        if base is not None:
            base_quests = {a[1] for a, *_ in base}
            extra = {qid for qid in self.pool if qid not in base_quests}
        beam, best = [start], None
        for _ in range(400):
            nxt = {}
            for s in beam:
                for a in self.moves(s, race, cls, base, extra):
                    n = self.apply(s, a)
                    n["base"] = s["base"]
                    if base is not None:
                        n["base"] = self.advance(n, race, cls, base, s["base"], a)
                    if self.finished(n) and (best is None or self.score(n) < self.score(best)):
                        best = n
                    k = self.key(n) + ((n["base"],) if base is not None else ())
                    if k not in nxt or nxt[k]["t"] > n["t"]:
                        nxt[k] = n
            if not nxt:
                break
            beam = sorted(nxt.values(), key=self.estimate)[:BEAM]
        if best is None:
            raise SystemExit(f"no way through {self.name} for {race} {cls}")
        return self.tidy(best, race, cls)

    def tidy(self, best, race, cls):
        """The path again without quests picked up and never handed in."""
        kept = {a[1] for a, *_ in best["path"] if a[0] == "turnin"} | set(self.route["handoff"])
        actions = [a for a, *_ in best["path"] if a[0] == "grind" or a[1] in kept]
        s = self.start_state()
        for a in actions:
            s = self.apply(s, a)
        s["path"] = self.with_training(s["path"], cls)
        return s

    def with_training(self, path, cls):
        """Train steps at the first stop by the trainers after each level
        this class has new spells at."""
        levels = [lv for lv in self.training.get(cls, []) if lv > self.route["levels"][0]]
        out, trained = [], set()
        for entry in path:
            out.append(entry)
            level, at = entry[3], entry[4]
            due = [lv for lv in levels if lv <= level and lv not in trained]
            if due and at and self.yards(tuple(at), self.route["trainers"]) < 40:
                trained.update(due)
                out.append((("train", max(due), None), TRAIN, 0, level, at))
        return tuple(out)

    def moves(self, s, race, cls, base, extra):
        legal = self.actions(s, race, cls)
        if base is None:
            moves = legal
        else:
            # The character's own quests, anything the base never did, and
            # the base's next step.
            done_by_base = {b[0] for b in base}
            moves = [a for a in legal if a[1] in extra or a not in done_by_base]
            p = s["base"]
            while p < len(base) and self.passed(s, base[p][0], race, cls):
                p += 1
            if p < len(base) and base[p][0] in legal:
                moves.append(base[p][0])
        if not legal and s["level"] < self.route["levels"][1]:
            moves = moves + self.grinds(s)
        return moves

    def passed(self, s, action, race, cls):
        """A base step this character never needs to wait for: not for it,
        or already done another way."""
        kind, qid, i = action
        if kind == "grind":
            return False
        if not self.for_who(self.pool[qid], race, cls):
            return True
        if kind == "accept":
            return qid in s["taken"]
        if kind == "turnin":
            return qid in s["done"]
        return qid in s["done"] or (qid in s["log"] and s["log"][qid][i] <= 1e-6)

    def advance(self, s, race, cls, base, p, action):
        """The base pointer after `action`: past it if it was the base's
        next step, then past every base step already passed."""
        while p < len(base) and self.passed(s, base[p][0], race, cls) and base[p][0] != action:
            p += 1
        if p < len(base) and base[p][0] == action:
            p += 1
        while p < len(base) and self.passed(s, base[p][0], race, cls):
            p += 1
        return p

    def grinds(self, s):
        """Grinding the mob that gives the most XP a minute, walk included."""
        best = None
        for qid, q in self.pool.items():
            for i, n in enumerate(self.needs(q)):
                if not (n.source and n.source[0] == "npc" and n.spots):
                    continue
                secs = self.walk(s["at"], n.area()) + GRIND_KILLS * (KILL + REST + self.between(n))
                rate = GRIND_KILLS * kill_xp(s["level"], n.level) / secs
                if best is None or rate > best[0]:
                    best = (rate, ("grind", qid, i))
        return [best[1]] if best else []


def apply_grind(planner):
    """Grinding is a kind of work that never settles a need."""
    plain = planner.apply

    def apply(s, action):
        if action[0] != "grind":
            return plain(s, action)
        q = planner.pool[action[1]]
        need = planner.needs(q)[action[2]]
        s = dict(s, log=dict(s["log"]))
        before, xp = s["t"], 0
        at = need.area()
        s["t"] += planner.walk(s["at"], at)
        s["at"] = at
        for _ in range(GRIND_KILLS):
            s["t"] += KILL + REST + planner.between(need)
            got = kill_xp(s["level"], need.level)
            xp += got
            planner.gain(s, got)
        s["path"] = s["path"] + ((action, round(s["t"] - before, 1), round(xp), s["level"], s["at"]),)
        return s
    planner.apply = apply


# --- Writing the route --------------------------------------------------

def plan(name):
    planner = Planner(name)
    apply_grind(planner)
    route = planner.route
    first_race, first_cls = route["first"]
    base = planner.search(first_race, first_cls)["path"]
    spine = [b for b in base if b[0][0] != "train"]
    who = [(r, c) for r, classes in route["who"].items() for c in classes]
    paths = {}
    for race, cls in who:
        if (race, cls) == (first_race, first_cls):
            paths[(race, cls)] = base
        else:
            paths[(race, cls)] = planner.search(race, cls, base=spine)["path"]

    # One list for everyone: the base's steps in order, each other path's
    # own steps placed after the base step they followed.
    # Quest steps are matched to the first plan's; train steps never are,
    # since each class trains at its own stops.
    master, users = [], {}
    slots = {i: [] for i in range(len(spine) + 1)}
    spine_keys = [b[0] for b in spine]
    for combo, path in paths.items():
        p = 0
        for step in path:
            a = step[0]
            if a[0] != "train" and a in spine_keys[p:]:
                p = spine_keys.index(a, p) + 1
                users.setdefault(p - 1, set()).add(combo)
                continue
            for entry in slots[p]:
                if entry[0] == a:
                    entry[1].add(combo)
                    break
            else:
                slots[p].append([a, {combo}, step])
    for i in range(len(spine) + 1):
        for a, combos, step in slots[i]:
            master.append((a, combos, step))
        if i < len(spine):
            master.append((spine[i][0], users.get(i, set()), spine[i]))
    master = [m for m in master if m[1]]

    steps = []
    for a, combos, step in master:
        steps.extend(step_lines(planner, a, combos, step, set(who)))
    name_twins(steps)
    total = sum(b[1] for b in base)
    write(planner, steps, total, base[-1][3])
    report(planner, paths)


def who_fields(combos, everyone):
    """The race and class fields for a step used by `combos`."""
    if combos == everyone:
        return [{}]
    races = sorted({r for r, _ in combos})
    classes = sorted({c for _, c in combos})
    every_class = {c for r, c in everyone if r in races}
    product = {(r, c) for r in races for c in classes} & everyone
    if product == combos:
        out = {}
        if set(races) != {r for r, _ in everyone}:
            out["race"] = races
        if set(classes) != every_class:
            out["class"] = classes
        return [out]
    # Not one race and class list: one step per race.
    return [dict(race=[r], **{"class": sorted(c for rr, c in combos if rr == r)}) for r in races]


def step_lines(planner, action, combos, step, everyone):
    kind, qid, i = action
    _, secs, xp, level, _ = step
    rows = []
    if kind == "train":
        for fields in who_fields(combos, everyone):
            row = {"train": qid}
            row.update(fields)
            row["xp"], row["secs"] = 0, int(TRAIN)
            rows.append((row, f"train at level {qid}", action))
        return rows
    q = planner.pool[qid]
    for fields in who_fields(combos, everyone):
        row = {}
        if kind == "accept":
            row["accept"] = qid
            start = (q.get("start") or [{}])[0]
            if start.get("npc"):
                row["npc"] = start["npc"]
            if start.get("at"):
                row["at"] = tuple(start["at"][0])
            note = f"{q['title']}, from {start.get('name', '?')}"
        elif kind == "turnin":
            row["turnin"] = qid
            end = (q.get("end") or [{}])[0]
            if end.get("npc"):
                row["npc"] = end["npc"]
            if end.get("at"):
                row["at"] = tuple(end["at"][0])
            note = f"{q['title']}, to {end.get('name', '?')}" + (f" in {end['place']}" if end.get("place") else "")
        elif kind == "work":
            need = planner.needs(q)[i]
            row["finish"] = qid
            if len(planner.needs(q)) > 1:
                row["obj"] = i + 1
            if need.area():
                row["at"] = need.area()
            note = f"{q['title']}: {need.label}" + (" (no spot known yet)" if not need.area() else "")
        else:
            need = planner.needs(q)[i]
            row["level"] = level
            row["at"] = need.area()
            note = f"grind {need.label}"
        row.update({k: v for k, v in fields.items()})
        row["xp"], row["secs"] = int(xp), int(round(secs))
        rows.append((row, note, action))
    if len(rows) > 1:
        # One step per race: each needs its own key.
        for row, _, _ in rows:
            row["key"] = step_key(row) + ":" + row["race"][0]
    return rows


def name_twins(steps):
    """Steps that would share a name (a class training at its own stop) get
    a key naming who they are for, which stays the same from plan to plan."""
    counts = {}
    for row, _, _ in steps:
        counts[row.get("key") or step_key(row)] = counts.get(row.get("key") or step_key(row), 0) + 1
    for row, _, _ in steps:
        key = row.get("key") or step_key(row)
        if counts[key] > 1:
            who = "/".join(",".join(row[f]) for f in ("race", "class") if f in row) or "all"
            row["key"] = f"{key}:{who}"


def step_key(row):
    """A step's name, from what it does (docs/STEP_FORMAT.md, "Step keys")."""
    for action in ("accept", "finish", "turnin", "train", "level"):
        if action in row:
            key = f"{action}:{row[action]}"
            return key + (f":{row['obj']}" if action == "finish" and "obj" in row else "")
    raise ValueError(row)


def lua_value(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (list, tuple)):
        return "{ " + ", ".join(lua_value(x) for x in v) + " }"
    if isinstance(v, str):
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(v, float) and v == int(v):
        return str(int(v))
    return str(v)


ORDER = ["accept", "finish", "turnin", "train", "level", "obj", "npc", "at", "race", "class", "key", "xp", "secs"]


def write(planner, steps, total, end_level):
    route, name = planner.route, planner.name
    today = datetime.date.today().isoformat()
    lines = [
        f"-- Blackthornes Pathfinder -- Data/Routes/{name}.lua",
        f"-- {route['title']}, from level {route['levels'][0]}.",
        "--",
        "-- Generated by tools/plan_route.py from tools/facts/, never typed by",
        "-- hand: fix the facts or the planner and run it again. xp and secs are",
        "-- what the planner expects for the first race and class, from guessed",
        "-- speeds until runs are recorded. The comments are for reading only.",
        "",
        "local _, ns = ...",
        "",
        "ns.Routes = ns.Routes or {}",
        "",
        f'ns.Routes["{name}"] = {{',
        f"    title = {lua_value(route['title'])},",
        f"    side = {lua_value(route['side'])},",
        f"    races = {lua_value(sorted(route['who']))},",
        f"    levels = {{ {route['levels'][0]}, {end_level} }},",
    ]
    if route["next"]:
        lines.append(f"    next = {lua_value(route['next'])},")
    lines += [
        f'    plan = {{ at = "{today}", minutes = {round(total / 60)} }},',
        "    steps = {",
    ]
    for row, note, _ in steps:
        parts = [f"{k} = {lua_value(row[k])}" for k in ORDER if k in row]
        lines.append("        { " + ", ".join(parts) + " },  -- " + note)
    lines += ["    },", "}", ""]
    ROUTES_DIR.mkdir(parents=True, exist_ok=True)
    (ROUTES_DIR / f"{name}.lua").write_text("\n".join(lines), encoding="utf-8", newline="\n")


def report(planner, paths):
    paths_time = {}
    print(f"{planner.name}: {len(planner.pool)} quests in the area")
    for combo, path in paths.items():
        t = sum(p[1] for p in path)
        paths_time[combo] = t
        grinds = sum(1 for p in path if p[0][0] == "grind")
        print(f"  {combo[0]:5} {combo[1]:8} {t / 60:5.1f} min, level {path[-1][3]}, "
              f"{len(path)} actions{f', {grinds} grind steps' if grinds else ''}")
    first = paths[planner.route["first"]]
    used = {p[0][1] for p in first}
    skipped = [q for q in planner.pool if q not in used and planner.for_who(planner.pool[q], *planner.route["first"])]
    if skipped:
        print("  left out for", " ".join(planner.route["first"]) + ":",
              ", ".join(f"{q} {planner.pool[q]['title']}" for q in skipped))
    unplaced = [f"{q['id']} {q['title']}: {n.label}" for q in planner.pool.values()
                for n in planner.needs(q) if n.kind == "unplaced"]
    if unplaced:
        print("  no spot known yet:", "; ".join(unplaced))


def main(argv):
    if not argv or argv[0] == "--list":
        print("routes:", ", ".join(ROUTES))
        return
    plan(argv[0])


if __name__ == "__main__":
    main(sys.argv[1:])
