"""Writes tools/facts/: the quest and flight facts the route planner starts from.

Run from the repository root with the sources somewhere outside it:

    python tools/make_quest_facts.py <pfQuest> <mangoszero database> <tables folder>
        [--equipment <Blackthornes_Equipment>]

  github.com/shagu/pfQuest         db/: who gives and takes back each quest,
                                   its objectives, and where every NPC and
                                   object stands, in zone map coordinates
  github.com/mangoszero/database   World/Setup/FullDB/quest_template.sql:
                                   quest level, chains, kill and item counts,
                                   and the money field Classic's XP comes from
  the Forever client's game tables QuestV2, QuestXP, UiMap, UiMapAssignment,
                                   TaxiNodes, TaxiPath and TaxiPathNode as
                                   CSV: which quests Forever has, its XP by
                                   quest level, its maps and flight paths
  Blackthornes_Equipment           Data/ForeverQuests.lua and
                                   Data/ForeverNPCs.lua: quests and spots met
                                   on Forever that Classic lacks;
                                   Data/ClassSpells.lua: the levels each
                                   class has spells to train at, from the
                                   Forever client's tables

Never commit the sources or the tables, and never name where the tables
were downloaded. Rerun after any of them is pulled again.

Writes:
  tools/facts/quests.jsonl   one quest a line, sorted by ID (see Fact below)
  tools/facts/flights.json   flight paths: each node's spot and side, and
                             each path's cost and length in yards
  tools/facts/maps.json      each zone and city map's name and size in yards,
                             for walking times
  tools/facts/training.json  [CLASS] = the levels a trainer has new spells at

Facts the probe read in game (docs/FOREVER_API_FINDINGS.md) that no source
holds are in PROBED below, each with the run that saw it; they are laid
over the rest. Add one only from a probe or a recorded run.

A Classic quest Forever's QuestV2 lacks is left out. A quest only Forever
has comes from Equipment's learned quests, with what they hold (title,
level, giver and spot), marked "forever": "new". Spots are uiMap IDs with
0 to 100 coordinates, the same as a route's `at`. Nothing here guesses a
spot: a place no source gives is left out. XP is Classic's, worked out the
way Classic's server does, and is an estimate until a run records the real
number.
"""

import collections
import csv
import json
import math
import re
import sys
from pathlib import Path

from lupa import lua51

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "tools" / "facts"

# Classic's race bits.
HORDE_RACES = 2 | 16 | 32 | 128      # orc, undead, tauren, troll
ALLIANCE_RACES = 1 | 4 | 8 | 64      # human, dwarf, night elf, gnome

# At most this many spawn spots per mob or object, spread over its spawns,
# so a camp's shape survives without keeping every spawn.
SPOTS_MOST = 24
# Item drops: the mobs and objects with at least this chance (%), at most
# DROPS_MOST of them, best first.
DROP_LEAST = 2
DROPS_MOST = 6

# Seen in game, not in any source: (quest ID, field, value, the run).
PROBED = [
    # Orc mage, level 1, Valley of Trials, 2026-10-19: handed in to Kzan
    # Thornslash, the Weaponsmith in the Den (Classic's NPC 3159, whose
    # Classic spot is in Razor Hill, so no spot is kept), for 6 Abandoned
    # Training Weapons. Where the weapons are is not known yet.
    (97279, "end", [{"npc": 3159, "name": "Kzan Thornslash", "place": "the Den"}], "2026-10-19"),
    (97279, "obj", {"item": [{"name": "Abandoned Training Weapon", "count": 6}]}, "2026-10-19"),
]


def read_csv(folder, name):
    path = folder / (name + ".csv")
    if not path.exists():
        raise SystemExit(f"missing {path}")
    with open(path, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def parse_row(line):
    """One `(a,'b',c)` row as a list of values, or None when it runs on.
    Equipment's tools/make_sources.py, copied."""
    values, cur, in_str, quoted = [], [], False, False
    j, n = 1, len(line)
    while j < n:
        ch = line[j]
        if in_str:
            if ch == "\\":
                cur.append(line[j + 1])
                j += 2
                continue
            if ch == "'":
                in_str = False
            else:
                cur.append(ch)
        elif ch == "'":
            in_str, quoted = True, True
        elif ch in ",)":
            text = "".join(cur)
            if quoted:
                values.append(text)
            else:
                text = text.strip()
                try:
                    values.append(int(text))
                except ValueError:
                    try:
                        values.append(float(text))
                    except ValueError:
                        values.append(text)
            cur, quoted = [], False
            if ch == ")":
                return values
        else:
            cur.append(ch)
        j += 1
    return None


def sql_rows(path, table):
    """Every row of a mysqldump INSERT for `table`, as dicts by column."""
    columns, out, pending = None, [], ""
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            if columns is None:
                m = re.match(r"INSERT INTO `%s` \(([^)]*)\) VALUES" % table, line)
                if m:
                    columns = [c.strip(" `") for c in m.group(1).split(",")]
                continue
            if pending:
                line = pending + line
                pending = ""
            if not line.startswith("("):
                continue
            values = parse_row(line)
            if values is None:
                pending = line
                continue
            if len(values) == len(columns):
                out.append(dict(zip(columns, values)))
    if columns is None:
        raise SystemExit(f"no INSERT for {table} in {path}")
    return out


def load_pfquest(folder):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("pfDB = setmetatable({}, {__index = function(t, k) "
                "local v = {} rawset(t, k, v) return v end})")
    db = folder / "db"
    for name in ["units.lua", "objects.lua", "items.lua", "quests.lua", "zones.lua",
                 "enUS/units.lua", "enUS/objects.lua", "enUS/items.lua",
                 "enUS/quests.lua", "enUS/zones.lua"]:
        lua.execute((db / name).read_text(encoding="utf-8"))
    return lua.eval("pfDB")


def lua_list(t):
    """A Lua list as a Python list, in its order."""
    if t is None:
        return []
    return [t[k] for k in sorted(t)]


def lua_map(t):
    if t is None:
        return {}
    return {k: t[k] for k in t}


def load_equipment(folder):
    """Equipment's Forever quests and NPC spots, read with Lua."""
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("ns = {}")
    out = {"quests": {}, "npcs": {}, "training": {}}
    path = folder / "Data" / "ClassSpells.lua"
    if path.exists():
        lua.compile(path.read_text(encoding="utf-8"))("", lua.eval("ns"))
        spells = lua.eval("ns.CLASS_SPELLS") or {}
        for cls in spells:
            levels = {int(spells[cls][i][2]) for i in spells[cls]}
            out["training"][cls] = sorted(levels)
    for name, key in (("ForeverQuests.lua", "ForeverQuests"), ("ForeverNPCs.lua", "ForeverNPCs")):
        path = folder / "Data" / name
        if not path.exists():
            continue
        lua.compile(path.read_text(encoding="utf-8"))("", lua.eval("ns"))
        table = lua.eval("ns." + key) or {}
        for k in table:
            row = table[k]
            if key == "ForeverQuests":
                out["quests"][int(k)] = {f: row[f] for f in
                                         ("title", "level", "min", "giver", "zone", "x", "y", "side")
                                         if row[f] is not None}
            else:
                out["npcs"][int(k)] = (row[1], row[2], row[3], row[4])
    return out


def classic_xp(row):
    """A quest's full XP the way Classic's server works it out from the
    money it gives at the level cap. 0 when the quest gives none."""
    money, level = row.get("RewMoneyMaxLevel") or 0, row.get("QuestLevel") or 0
    if money <= 0:
        return 0
    if level >= 65:
        div = 6.0
    elif level == 64:
        div = 4.8
    elif level == 63:
        div = 3.6
    elif level == 62:
        div = 2.4
    elif level == 61:
        div = 1.2
    else:
        div = 0.6
    return int(math.ceil(money / div))


def thin(spots, most=SPOTS_MOST):
    """At most `most` spots, picked evenly through the list."""
    if len(spots) <= most:
        return spots
    step = len(spots) / most
    return [spots[int(i * step)] for i in range(most)]


class Maps:
    """pfQuest's zone IDs to uiMap IDs (by name), and world spots to map spots."""

    def __init__(self, tables, zone_names):
        self.uimaps = {int(r["ID"]): r for r in read_csv(tables, "UiMap")}
        by_name = {}
        for mid, r in sorted(self.uimaps.items()):
            # Type 3 is a zone, 4 a city; a continent shares no name with one.
            if r["Type"] in ("3", "4"):
                by_name.setdefault(r["Name_lang"], mid)
        self.by_name = by_name
        self.zone_to_map = {}
        for zid in zone_names:
            name = zone_names[zid]
            if name in by_name:
                self.zone_to_map[int(zid)] = by_name[name]
        self.assign = [r for r in read_csv(tables, "UiMapAssignment")]

    def of_zone(self, zone_id):
        return self.zone_to_map.get(int(zone_id)) if zone_id else None

    def of_name(self, name):
        return self.by_name.get(name)

    def world_to_map(self, continent, wx, wy, names=()):
        """(uiMap, x, y) for a world spot: on the first map in `names` that
        holds it, else the smallest map holding it (maps' areas overlap at
        their edges)."""
        best = None
        for r in self.assign:
            if int(r["MapID"]) != continent:
                continue
            mid = int(r["UiMapID"])
            if self.uimaps.get(mid, {}).get("Type") not in ("3", "4"):
                continue
            min_x, min_y = float(r["Region_0"]), float(r["Region_1"])
            max_x, max_y = float(r["Region_3"]), float(r["Region_4"])
            if not (min_x <= wx <= max_x and min_y <= wy <= max_y):
                continue
            # The map runs west to east as world Y falls, north to south as
            # world X falls.
            u = (max_y - wy) / (max_y - min_y)
            v = (max_x - wx) / (max_x - min_x)
            u0, v0 = float(r["UiMin_0"]), float(r["UiMin_1"])
            u1, v1 = float(r["UiMax_0"]), float(r["UiMax_1"])
            x, y = (u0 + u * (u1 - u0)) * 100, (v0 + v * (v1 - v0)) * 100
            area = (max_x - min_x) * (max_y - min_y)
            name = self.uimaps[mid]["Name_lang"]
            if name in names:
                area = -len(names) + list(names).index(name) - 1
            if best is None or area < best[0]:
                best = (area, (mid, round(x, 1), round(y, 1)))
        return best and best[1]


def map_sizes(maps):
    """{uiMap: {name, yards: [wide, tall]}} for zone and city maps."""
    out = {}
    for r in maps.assign:
        mid = int(r["UiMapID"])
        um = maps.uimaps.get(mid)
        if not um or um["Type"] not in ("3", "4") or str(mid) in out:
            continue
        du = float(r["UiMax_0"]) - float(r["UiMin_0"])
        dv = float(r["UiMax_1"]) - float(r["UiMin_1"])
        if du <= 0 or dv <= 0:
            continue
        wide = (float(r["Region_4"]) - float(r["Region_1"])) / du
        tall = (float(r["Region_3"]) - float(r["Region_0"])) / dv
        out[str(mid)] = {"name": um["Name_lang"], "yards": [round(wide, 1), round(tall, 1)]}
    return dict(sorted(out.items(), key=lambda kv: int(kv[0])))


def flights(tables, maps):
    nodes = {}
    for r in read_csv(tables, "TaxiNodes"):
        nid = int(r["ID"])
        name = r["Name_lang"]
        if not name or name.startswith(("Transport", "zz")) or "Quest" in name:
            continue
        horde, alliance = int(r["MountCreatureID_0"] or 0), int(r["MountCreatureID_1"] or 0)
        side = ("H" if horde else "") + ("A" if alliance else "")
        if not side:
            continue
        continent = int(r["ContinentID"])
        wx, wy, wz = float(r["Pos_0"]), float(r["Pos_1"]), float(r["Pos_2"])
        nodes[nid] = {"name": name, "side": side, "continent": continent,
                      "world": [round(wx, 1), round(wy, 1), round(wz, 1)],
                      "at": maps.world_to_map(continent, wx, wy, tuple(name.split(", ")))}
    points = collections.defaultdict(list)
    for r in read_csv(tables, "TaxiPathNode"):
        points[int(r["PathID"])].append((int(r["NodeIndex"]), float(r["Loc_0"]), float(r["Loc_1"]),
                                         float(r["Loc_2"]), int(r["Delay"] or 0)))
    paths = []
    for r in read_csv(tables, "TaxiPath"):
        a, b = int(r["FromTaxiNode"]), int(r["ToTaxiNode"])
        if a not in nodes or b not in nodes:
            continue
        pts = sorted(points.get(int(r["ID"]), []))
        length = sum(math.dist(p[1:4], q[1:4]) for p, q in zip(pts, pts[1:]))
        paths.append({"from": a, "to": b, "cost": int(r["Cost"] or 0),
                      "yards": round(length), "delay": sum(p[4] for p in pts)})
    return {"nodes": {str(k): v for k, v in sorted(nodes.items())}, "paths": paths}


def main(argv):
    args, opts, rest = [], {}, list(argv)
    while rest:
        a = rest.pop(0)
        if a.startswith("--"):
            opts[a] = rest.pop(0) if rest else ""
        else:
            args.append(a)
    if len(args) < 3:
        raise SystemExit(__doc__)
    pfq_dir, mangos_dir, tables = Path(args[0]), Path(args[1]), Path(args[2])
    equipment = Path(opts.get("--equipment", ROOT.parent / "Blackthornes_Equipment"))

    pfq = load_pfquest(pfq_dir)
    pf_quests, pf_titles = pfq["quests"]["data"], pfq["quests"]["enUS"]
    units, objects, items = pfq["units"]["data"], pfq["objects"]["data"], pfq["items"]["data"]
    unit_names, object_names = pfq["units"]["enUS"], pfq["objects"]["enUS"]
    item_names, zone_names = pfq["items"]["enUS"], pfq["zones"]["enUS"]
    maps = Maps(tables, lua_map(zone_names))

    mangos = {r["entry"]: r for r in sql_rows(mangos_dir / "quest_template.sql", "quest_template")}
    forever_ids = {int(r["ID"]) for r in read_csv(tables, "QuestV2")}
    quest_xp = {int(r["ID"]): [int(r[f"Difficulty_{i}"]) for i in range(10)]
                for r in read_csv(tables, "QuestXP")}
    equip = load_equipment(equipment)

    def spots_of(entry, home_map=None):
        """[(map, x, y), ...] for a pfQuest NPC or object, its home map first."""
        if not entry or not entry["coords"]:
            return []
        out = []
        for i in entry["coords"]:
            c = entry["coords"][i]
            mid = maps.of_zone(c[3])
            if mid:
                out.append((mid, round(float(c[1]), 1), round(float(c[2]), 1)))
        if not out:
            return []
        common = collections.Counter(s[0] for s in out).most_common(1)[0][0]
        keep = home_map if home_map in {s[0] for s in out} else common
        return thin([list(s) for s in out if s[0] == keep])

    def mob_level(uid):
        """A mob's level as pfQuest gives it ("5" or "5-6"), as a number: the middle."""
        entry = units[uid]
        text = str(entry and entry["lvl"] or "")
        parts = [float(p) for p in text.split("-") if p.strip().replace(".", "").isdigit()]
        return round(sum(parts) / len(parts), 1) if parts else None

    def npc(uid, home_map=None):
        name = unit_names[uid]
        spots = spots_of(units[uid], home_map)
        seen = equip["npcs"].get(int(uid))
        if seen and maps.of_name(seen[1]):
            # Where it was met on Forever beats Classic's spot.
            spots = [[maps.of_name(seen[1]), seen[2], seen[3]]]
            name = seen[0] or name
        return {"npc": int(uid), "name": name, "at": spots[:1]} if spots else {"npc": int(uid), "name": name}

    def obj(oid, home_map=None):
        spots = spots_of(objects[oid], home_map)
        return {"object": int(oid), "name": object_names[oid], "at": spots[:1]} if spots else \
            {"object": int(oid), "name": object_names[oid]}

    def ends(part, home_map):
        if not part:
            return []
        out = [npc(u, home_map) for u in lua_list(part["U"])]
        out += [obj(o, home_map) for o in lua_list(part["O"])]
        out += [{"item": int(i), "name": item_names[i]} for i in lua_list(part["I"])]
        return out

    facts, gone, kept = {}, 0, 0
    matched = collections.Counter()
    for qid in pf_quests:
        qid = int(qid)
        pq = pf_quests[qid]
        if qid not in forever_ids:
            gone += 1
            continue
        row = mangos.get(qid, {})
        start = ends(pq["start"], None)
        home = next((s["at"][0][0] for s in start if s.get("at")), None)
        fact = {"id": qid, "title": (pf_titles[qid] or {})["T"] if pf_titles[qid] else row.get("Title"),
                "lvl": int(pq["lvl"] or row.get("QuestLevel") or 0),
                "min": int(pq["min"] or row.get("MinLevel") or 0),
                "races": int(pq["race"] or row.get("RequiredRaces") or 0),
                "classes": int(pq["class"] or row.get("RequiredClasses") or 0),
                "start": start, "end": ends(pq["end"], home), "forever": "kept"}
        if pq["skill"]:
            fact["skill"] = int(pq["skill"])
        if pq["event"]:
            fact["event"] = int(pq["event"])
        pre = [int(p) for p in lua_list(pq["pre"])]
        if pre:
            fact["pre"] = pre
        for key, col in (("prev", "PrevQuestId"), ("next", "NextQuestInChain"),
                         ("exclusive", "ExclusiveGroup"), ("players", "SuggestedPlayers"),
                         ("type", "Type"), ("money", "RewOrReqMoney")):
            if row.get(col):
                fact[key] = row[col]
        spell = row.get("RewSpellCast") or row.get("RewSpell")
        if spell:
            fact["spell"] = spell
        xp = classic_xp(row) if row else 0
        if xp:
            fact["xp"] = xp
            levels = quest_xp.get(fact["lvl"])
            if levels:
                # The Forever row nearest Classic's number, as a second guess.
                fact["xp_forever"] = min((v for v in levels if v), key=lambda v: abs(v - xp), default=0)
                if fact["xp_forever"]:
                    matched[levels.index(fact["xp_forever"])] += 1

        objectives = {}
        kills = []
        for n, uid in enumerate(lua_list((pq["obj"] or {})["U"]) if pq["obj"] else []):
            entry = {"npc": int(uid), "name": unit_names[uid], "lvl": mob_level(uid),
                     "spots": spots_of(units[uid], home)}
            for i in range(1, 5):
                if row.get(f"ReqCreatureOrGOId{i}") == int(uid):
                    entry["count"] = row.get(f"ReqCreatureOrGOCount{i}")
            kills.append(entry)
        if kills:
            objectives["kill"] = kills
        uses = []
        for oid in (lua_list(pq["obj"]["O"]) if pq["obj"] else []):
            uses.append({"object": int(oid), "name": object_names[oid], "spots": spots_of(objects[oid], home)})
        if uses:
            objectives["object"] = uses
        loot = []
        for iid in (lua_list(pq["obj"]["I"]) if pq["obj"] else []):
            entry = {"item": int(iid), "name": item_names[iid]}
            for i in range(1, 5):
                if row.get(f"ReqItemId{i}") == int(iid):
                    entry["count"] = row.get(f"ReqItemCount{i}")
            drops = []
            it = items[iid]
            for key, kind, table, look in (("U", "npc", units, None), ("O", "object", objects, None)):
                part = it and it[key]
                for k in (part or {}):
                    chance = float(part[k] or 0)
                    if chance >= DROP_LEAST:
                        drop = {kind: int(k), "chance": round(chance, 1), "spots": spots_of(table[k], home)}
                        if kind == "npc":
                            drop["lvl"] = mob_level(k)
                        drops.append(drop)
            for vid in (lua_list(it["V"]) if it and it["V"] else []):
                drops.append({"vendor": int(vid), "spots": spots_of(units[vid], home)[:1]})
            drops.sort(key=lambda d: -d.get("chance", 100))
            entry["from"] = [d for d in drops if d["spots"]][:DROPS_MOST]
            loot.append(entry)
        if loot:
            objectives["item"] = loot
        if pq["obj"] and pq["obj"]["A"]:
            objectives["area"] = [int(a) for a in lua_list(pq["obj"]["A"])]
        if objectives:
            fact["obj"] = objectives
        facts[qid] = fact
        kept += 1

    # Which column of Forever's XP table Classic's quests land on most: a
    # Forever quest with no XP known is guessed from that column.
    usual = matched.most_common(1)[0][0] if matched else None
    new = 0
    for qid, q in equip["quests"].items():
        if qid in facts or qid not in forever_ids:
            continue
        fact = {"id": qid, "title": q.get("title"), "lvl": int(q.get("level") or q.get("min") or 0),
                "min": int(q.get("min") or 0), "forever": "new", "side": q.get("side")}
        if usual is not None and quest_xp.get(fact["lvl"]):
            fact["xp_forever"], fact["xp_guess"] = quest_xp[fact["lvl"]][usual], True
        mid = maps.of_name(q.get("zone")) if q.get("zone") else None
        if q.get("giver"):
            giver = {"name": q["giver"]}
            if mid and q.get("x") is not None:
                giver["at"] = [[mid, q["x"], q["y"]]]
            fact["start"] = [giver]
        facts[qid] = fact
        new += 1
    unknown = len(forever_ids - set(facts))
    for qid, field, value, _ in PROBED:
        if qid in facts:
            facts[qid][field] = value
            facts[qid].setdefault("probed", []).append(field)

    OUT.mkdir(parents=True, exist_ok=True)
    with open(OUT / "quests.jsonl", "w", encoding="utf-8", newline="\n") as f:
        for qid in sorted(facts):
            f.write(json.dumps(facts[qid], ensure_ascii=False, separators=(",", ":")) + "\n")
    fl = flights(tables, maps)
    with open(OUT / "flights.json", "w", encoding="utf-8", newline="\n") as f:
        json.dump(fl, f, ensure_ascii=False, indent=1)
        f.write("\n")
    with open(OUT / "maps.json", "w", encoding="utf-8", newline="\n") as f:
        json.dump(map_sizes(maps), f, ensure_ascii=False, indent=1)
        f.write("\n")
    with open(OUT / "training.json", "w", encoding="utf-8", newline="\n") as f:
        json.dump(dict(sorted(equip["training"].items())), f, separators=(",", ":"))
        f.write("\n")
    print(f"XP column most Classic quests match: {usual} ({matched[usual]} of {sum(matched.values())})")
    print(f"quests: {kept} Classic kept, {gone} Classic gone on Forever, {new} Forever-only learned, "
          f"{unknown} Forever-only not met yet")
    print(f"flights: {len(fl['nodes'])} nodes, {len(fl['paths'])} paths")
    unmapped = sorted({zone_names[z] for z in lua_map(zone_names) if maps.of_zone(z) is None} - {None})
    print(f"pfQuest zones with no uiMap: {len(unmapped)}")


if __name__ == "__main__":
    main(sys.argv[1:])
