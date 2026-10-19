# What the WoW: Forever client actually does, for a leveling guide

Found with `/bpath probe` in the game, not taken from documentation.
Tradeskills, Equipment, Farmer, Pets and Butler keep files like this one for
professions, the auction house, gear, talents, gathering, pets and bags;
read them too before relying on any API. Equipment's covers the quest log,
quest arrow and map pins it already uses.

Nothing has been probed here yet. What a guide needs answered first:

- **Quests:** the quest log (`C_QuestLog` or the classic calls), which
  quests are already done, and the quest events (`QUEST_ACCEPTED`,
  `QUEST_TURNED_IN` and the rest).
- **Talking to NPCs:** the gossip list (`C_GossipInfo` or the classic
  calls) and the quest window, for taking and handing in quests without a
  click each time. Run the probe with a quest giver's window open.
- **Flight paths:** the taxi calls, with a flight master's map open.
- **The hearthstone:** where it is set (`GetBindLocation`), its cooldown,
  and the innkeeper's confirm (`CONFIRM_BINDER`).
- **Trainers and vendors:** with each window open.
- **Map position:** `C_Map` and the game's own waypoint, for an arrow.

Record each run below under a heading with the class, level, place and date,
the way the sisters do.
