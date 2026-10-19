# The step format (draft)

**A draft for the owner to look over (2026-10-19). Nothing in the game is
built yet**, and every name in it can still change; the owner's answers to
its questions are under "Decided". Built so far: the quest facts tool
(see "Where the facts come from"), the planner and the first route (see
"The first route"), and the route check. It says how a route is
written down, how the guide knows each step is done, and how routes get
made: worked out by a planner to be the fastest way to level, then made
faster with times from real runs.

What the client can do is in `docs/FOREVER_API_FINDINGS.md`. This file
leans on those runs and says where something is still untested.

## The big picture

Four parts, each feeding the next:

1. **Quest facts:** for each quest, its ID, level, who gives it and where,
   where its objectives are, who takes it back, the quests that must come
   first, and the XP it gives. They come from the client and from play (see
   "Where the facts come from"), never from another guide.
2. **The planner** (`tools/plan_route.py`, run by Claude, never shipped):
   reads the facts and works out the order of quests, travel, flights,
   hearthstones and training that gets from level A to level B in the
   least time. It writes a route.
3. **Routes** (`Data/Routes/*.lua`, shipped): the step lists the guide
   follows. A route is plain data that reads easily, but it is written by
   the planner: a step it got wrong is fixed in the facts or the planner,
   and the route planned again, so the next plan keeps the fix.
4. **The guide in game** (`Logic/Guide.lua` and the window): follows a
   route, ticks steps off as the game shows them done, points the arrow,
   and does the clicks it is allowed to.

A fifth part closes the loop: **the recorder** keeps, per step, how long
it really took and the XP it gave. Folded back into the facts after a run,
those times replace the planner's guesses, and the next plan is faster.
"Fastest" is always measured, not claimed.

## A route

One file per route under `Data/Routes/`, each adding itself to
`ns.Routes`, named for its place (`valley-of-trials`), never its levels:
the planner decides where a route ends, and the name is kept in saves. A Lua table, like every other `Data/` file in the house: no
parser to write, the syntax check already reads it, and it can be edited by
hand.

```lua
ns.Routes["valley-of-trials"] = {
    title = "Valley of Trials",   -- shown name; a zone name from the client where it can be
    side = "H",
    races = { "Orc", "Troll" },   -- who starts here; nil for anyone of the side
    levels = { 1, 6 },            -- the level it starts at, the level it ends at
    next = "durotar",             -- the route that follows, or nil
    plan = { at = "2026-10-19", minutes = 34 },  -- what the planner expected, filled by the tool
    steps = {
        -- one table per step, below
    },
}
```

A route covers one stretch (a starting area, a zone, a level band) so a
route can be planned, measured and fixed on its own. Routes chain with
`next`, and where races or classes split (a starting zone each), each split
has its own route that joins the shared one later.

## A step

Every step has **exactly one action key**, which says what to do and what
it is done to. The rest are optional fields shared by every kind.

| Action | Value | Done when |
| --- | --- | --- |
| `accept` | quest ID | the quest is in the log, or already turned in |
| `finish` | quest ID, or a list of them | each quest's objectives are complete (or it is turned in) |
| `turnin` | quest ID | the quest is turned in (`QUEST_TURNED_IN`, or flagged completed) |
| `go` | true (the place is `at`) | the character is within `near` yards of `at` (soft, see below) |
| `getfp` | flight path node ID | the flight map shows that node as known |
| `fly` | flight path node ID | the character lands after flying there (soft) |
| `home` | true (the innkeeper is `npc`/`at`) | the hearthstone's place changes while at this step's innkeeper, or already reads this place |
| `hearth` | true | a hearthstone cast finishes and the character lands (soft) |
| `buy` | item ID (with `count`) | the bags hold at least `count` |
| `train` | the level whose spells to train | a class trainer's list was opened at that level or above (soft) |
| `level` | a level | the character is at that level (grind along the way) |
| `use` | item ID | the quest objective it serves moves on (needs `for`), or ticked by hand |
| `note` | a translated line | ticked by hand |

Fields any step can carry:

- `at = { map, x, y }`: the spot, as a uiMap ID and the map's 0 to 100
  coordinates (Durotar is map 1411 on Forever, per the findings). Map IDs
  do not change with the client's language, unlike zone names.
- `near`: how close counts as there, in yards (default 15, like
  Equipment's arrow).
- `npc`: the NPC ID, read from `UnitGUID("npc")`, so the guide can tell it
  is talking to the right person and can learn where they really stand.
- `obj`: for `finish`, only this objective of the quest (1, 2...).
- `for`: the quest a `use`, `buy` or `level` step serves.
- `reward`: for `turnin`, the reward to take (an item ID). Without it the
  guide picks the best for the character, as Equipment's Take button does.
- `note`: a short tip shown under the step, written as `L["..."]` so it is
  translated like every other string.
- `class`, `race`, `prof`: show the step only to that class, race or
  profession (a list for more than one).
- `optional = true`: shown, but never holds the route up.
- `key`: a name for the step, only when two steps would get the same one
  (see "Step keys").
- `xp`, `secs`: what the planner expects the step to give and take. Filled
  by the tool, never by hand; the guide uses them for pace, not to decide
  anything.

What the player reads is made from the action and the client's own names:
"Accept Vile Familiars", "Buy 5 Tough Hunk of Bread", "Fly to Ratchet". The
quest title, item name and flight path name all come from the client in
its language, so a route has no English to translate except its `note`s.

An example with IDs the probes saw (the spots are made up for the example
and the NPC IDs are left out until they are read in game):

```lua
steps = {
    { accept = 4641, at = { 1411, 0, 0 } },                       -- from Kaltunk
    { turnin = 4641, at = { 1411, 0, 0 } },                       -- to Gornek
    { accept = 788,  at = { 1411, 0, 0 } },                       -- Gornek's kill quest
    { accept = 97279, at = { 1411, 0, 0 } },                      -- Wayward Weapons, Kzan Thornslash
    { accept = 792,  at = { 1411, 0, 0 } },                       -- Vile Familiars, Zureetha Fargaze
    { finish = { 788, 97279 }, at = { 1411, 0, 0 },
      note = L["Grab the training weapons as you clear the camp."] },
    { finish = 792,  at = { 1411, 0, 0 } },
    { turnin = 97279, at = { 1411, 0, 0 } },
    { turnin = 788,  at = { 1411, 0, 0 } },
    { turnin = 792,  at = { 1411, 0, 0 } },
    { buy = 4540, count = 5, optional = true },                   -- Tough Hunk of Bread
    { train = 4, class = "MAGE" },
}
```

`finish = { 788, 97279 }` is one step for quests done in the same place at
the same time, which is most of what makes a fast route: the planner merges
quests whose objectives overlap into one step.

## Which step is now

The guide reads the game and works out the step to do now; it never just
counts clicks. Each time something it watches changes (the quest log, a
turn-in, the bags, the level, a landing, a zone), it walks the route:

- A step is **done** when its check says so, or when the player skipped
  it. Checks read the game first (quest log, completed quests, bags, level)
  and the character's own record second (flight paths learned, home set,
  steps ticked), so a quest done out of order, on an earlier try, or before
  the addon was installed still counts.
- A **soft** step (`go`, `fly`, `hearth`, `train`) can't be checked once
  it's past: being in a zone says nothing about whether you walked there
  for this step. So a soft step counts as done once any later step that is
  not soft is done, Equipment's rule for the upgrade quest's steps.
- A step for another class, race or profession, or an `optional` one,
  never holds up the ones after it.
- The step to do now is the first one not done. The window shows it big,
  with the next few under it, and the arrow points at its `at` (or at its
  quest's objective area where the client gives one).

Several steps can be open at once without anything special: when the
player accepts three quests in a row, the three `accept` steps tick off
one after another, wherever they stand.

## Step keys and the character's record

Steps are named by what they do, not where they stand in the list:
`accept:792`, `turnin:97279`, `getfp:22`, `buy:4540`. A route can then be
re-planned in an update (steps moved, added, taken out) without a
character's ticks pointing at the wrong step. Two steps that would share a
name (two `go` steps, or a quest handed in at two points of a chain) get a
`key`. The route check refuses a route with two steps of one name.

Kept per character in `BlackthornesPathfinderCharDB` (each character is at
its own point in the guide), names not final:

- `route`: the route being followed.
- `skipped[route][key] = true`: steps the player skipped.
- `ticked[route][key] = true`: steps ticked by hand, and the done checks
  the game can't answer later (a `home` or `getfp` seen done).
- `flightPaths[node] = true`: paths seen known on any flight map.

Like every saved name in the house, once shipped these are never renamed.

## Doing it for the player

"It must seem like magic" means the guide does the routine clicks itself,
for **the step to do now only**: never a quest the route did not ask for.
They are on by default while the guide is following a route (the owner,
2026-10-19), and do nothing when it isn't. Each is its own setting, Shift
held pauses them all, and each action reads the window first, as the
findings say it can:

- **Accept:** the quest page shows "offer" and `GetQuestID` is the step's
  quest: `AcceptQuest()`. From a gossip list, pick it by ID first
  (`C_GossipInfo.SelectAvailableQuest`).
- **Turn in:** on the gossip list, `C_GossipInfo.GetActiveQuests` finds
  the quest by ID with `isComplete`, then `SelectActiveQuest`; on the
  progress page with `IsQuestCompletable` true, `CompleteQuest()`; on the
  reward page, `GetQuestReward(choice)` with the step's `reward` or the
  best pick. With more than one choice and no `reward`, the guide waits
  for the player unless "Pick rewards for me" is on.
- **Set home:** the innkeeper's option is found by its icon (132052), not
  its words or ID, then the confirm.
- **Flights:** at a flight master, the option with icon 132057 opens the
  map; the step's node is found by `nodeID` in `C_TaxiMap.GetAllTaxiNodes`,
  checked reachable, and taken with `TakeTaxiNode(slotIndex)`.
- **Buy:** the vendor's list is searched by `GetMerchantItemID` and the
  count bought.

**Still untested:** whether the client lets addon code call `AcceptQuest`,
`CompleteQuest`, `GetQuestReward`, `SelectActiveQuest`, `TakeTaxiNode` and
`ConfirmationInteraction` without the player's click. Each one that is
refused becomes a glowing button over the window instead (the player's
click, like Equipment's Take button), so the format doesn't change either
way. The first real route will show which.

## The fastest route

The planner's job is the least time from a route's first level to its
last. That is a scheduling problem: an order for every pick-up, objective
and hand-in, where some must come before others and walking between them
costs time. How it works it out:

**What it weighs, per quest:**
- The XP it gives at the level the character will be when turning it in
  (lower-level quests give less, so a quest left too late can stop being
  worth doing).
- The time it takes: walking to the giver, to the objectives and back,
  plus the time spent on the objectives themselves (kills, items to
  collect and how often they drop).
- What it must come after (`p`, the quest before in a chain) and what it
  opens.
- The XP from mobs killed on the way, which counts toward the level too.

**What it decides:**
- Which quests are worth doing at all. A quest that gives too little for
  the walk is left out, and a slow one that opens a fast chain is kept.
- Which quests to carry together, so each trip to an area clears every
  objective there (the merged `finish` steps).
- When to hearth and when to fly, against the hearthstone's hour cooldown
  and the flight paths the character has.
- Where a short grind (`level` step) beats walking to the next quest
  giver, and when to train.

**How it gets better:** the first plan works from estimates (walking
speed over the map distance, a guess per kill). The recorder then keeps
real times and XP per step, and once a route has been run the planner
plans again from what really happened. Runs by different classes are kept
apart where they differ (a mage clears a camp at another pace than a
warrior). Each re-plan shows the expected time beside the last measured
run, so a change is kept only when it is faster.

Later, the same planner logic can run in game in a small form: when the
player is ahead, behind or has skipped quests, the guide can pick the
next-best order from where they really are instead of sending them back.
That comes after the routes work.

## Where the facts come from

Every fact must come from the client, from play, or from data the project
has cleared. Never from another guide (their routes are theirs; see
`CLAUDE.md`). The owner's rule (2026-10-19): **whatever can be gathered
without playing comes first**, so a route can be planned before anyone
walks it, and play only fills the gaps and the timings.

**Before play: `tools/make_quest_facts.py`** (built). It reads Classic's
quest data (pfQuest, MIT, and the mangoszero database; the owner cleared
Classic data for routes, 2026-10-19), the Forever client's game tables and
what Equipment has already learned on Forever, and writes
`tools/facts/quests.jsonl` and `tools/facts/flights.json`. Run against
Forever build 1.60.1.70245 on 2026-10-19:

- **3,662 Classic quests Forever still has**, each with who gives it and
  takes it back (NPC IDs and spots), its level and the level it opens at,
  the race and class it is for, the quests before it, its objectives (mobs
  to kill with up to 24 spawn spots each, objects, items with the mobs that
  drop them and how often), and its XP.
- **771 Classic quests Forever does not have** (not in its QuestV2 table),
  left out, so no route sends anyone to a quest that is gone.
- **XP:** Classic's number, worked out the way Classic's server does, and
  the nearest row of Forever's own XP table beside it. The two agree within
  a few percent (Cutting Teeth 150 and 130, Vile Familiars 450 and 445,
  level 8 quests 700 and 700), so Forever gives about Classic's XP.
- **Flight paths:** every node with its side and its spot on the map, and
  every path with its cost and length in yards, for planning flights
  before any are learned. The costs match the probe (Orgrimmar to Thunder
  Bluff 50 copper in the table, 45 in game: the 10% discount; Crossroads
  110 and 99).
- **2,947 quests only Forever has.** Equipment had met 46 of them (most on
  Zephras Isle, one in the Valley of Trials: Wayward Weapons). The other
  2,901 are IDs with nothing known yet. Many are likely unused, but some are
  new leveling quests, and only play finds those.

In Durotar alone that gives 73 Horde quests up to level 14 to plan from,
with only one of Forever's own known so far.

**During play: the recorder** (`/bpath record`, a draft name). The owner
will level with it on (2026-10-19); it is not offered to players for now.
It keeps every quest offered, accepted, completed and turned in, with the
quest ID, the NPC ID, the map and spot, the time and the character's XP,
plus each flight path, innkeeper, vendor and trainer, and each mob killed
with its spot. A tool folds the save into the facts (as Equipment's
`tools/forever_quests.py` reads `learnedQuests`): Forever's new quests get
their givers and objectives, and every step gets a real time.

## The first route

`python tools/plan_route.py valley-of-trials` plans the Valley of Trials
for every orc and troll class from the facts and writes
`Data/Routes/valley-of-trials.lua` (2026-10-19). With the guessed speeds it
expects about 32 minutes to level 5 for most classes, 31 for warlocks, and
36 for shamans, whose Call of Earth chain teaches their Earth totem and is
always done. It ends when the valley stops paying better than moving on
would (`rate_next`, a guess of 2 XP a second): 805, Report to Sen'jin
Village, is the hand-off to the next route.

What the plan does on its own: picks up everything at the camp before
heading out, clears boars, peons and cactus apples on the way, makes one
trip north for the Vile Familiars, Thazz'ril's Pick, the Burning Blade
Medallion and (for shamans) the Felstalker Hooves, and trains at level 4
where each class next stands by its trainer. Forever's Wayward Weapons is
left out: nobody knows yet where its weapons are, and at a guessed 170 XP
it pays about what moving on does. The recorder settles both.

The route file is not in the TOC yet; it joins when the guide that follows
it is built.

## Checking a route

A test (`tools/test_routes.py`, with the others) reads every route and
refuses one where:

- a step has no action key, or two;
- a field is one it doesn't know (a typo would otherwise do nothing);
- a quest is finished or turned in before the route accepts it, unless
  it is marked as picked up in an earlier route;
- two steps share a key;
- a spot is outside 0 to 100, or a map, quest, item or node ID isn't a
  whole number;
- `next` names a route that doesn't exist.

## What to probe next

- **XP:** whether `GetRewardXP` and `GetQuestLogRewardXP` answer on
  Forever, and `UnitXP`/`UnitXPMax`, for the recorder and the planner.
- **Quest titles by ID:** `C_QuestLog.GetTitleForQuestID` for a quest not
  in the log, so steps can name quests the character hasn't seen.
- **Objective areas:** whether the client gives a quest's objective spot
  (retail's `C_QuestLog.GetNextWaypoint` and the quest POI calls), for the
  arrow on a `finish` step without an `at`.
- **The clicks:** the untested calls under "Doing it for the player".
- **The hearthstone cast:** which spell ID the client reports when it
  finishes, for the `hearth` step.
- **Flight costs:** the four reachable paths that read a cost of 0.

## Decided (the owner, 2026-10-19)

1. **The first route** is the Valley of Trials, for now. Forever's maps
   add Darkspear Islands, so trolls may start there instead of beside the
   orcs: check before the route says it is for both.
2. **The clicks** are on by default while the guide is following a route.
3. **Timings** come from the owner's own leveling with the recorder on.
4. **Classic data** is cleared for routes, for the quests Forever kept.

Still to decide: what ships at launch.
