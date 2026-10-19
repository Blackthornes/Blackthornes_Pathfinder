# What the WoW: Forever client actually does, for a leveling guide

Found with `/bpath probe` in the game, not taken from documentation.
Tradeskills, Equipment, Farmer, Pets and Butler keep files like this one for
professions, the auction house, gear, talents, gathering, pets and bags;
read them too before relying on any API. Equipment's covers the quest log,
quest arrow and map pins it already uses.

What a guide needs answered (the first runs are below):

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

## Orc mage, level 1, Valley of Trials, 2026-10-19

Four runs, each with one window open (or none).

**No window.** Everything a guide reads is there in its retail shape:
`C_QuestLog` (count, info, objectives, `IsQuestFlaggedCompleted`,
`GetAllCompletedQuestIDs`; room for 40 quests; one quest already counts as
done at level 1, likely a hidden flag), all of `C_GossipInfo` (including
`SelectAvailableQuest`, `SelectActiveQuest`, `SelectOption`), the quest
window calls (`GetQuestID`, `AcceptQuest`, `CompleteQuest`,
`GetQuestReward`), the taxi calls with `C_TaxiMap` and `TaxiNodeCost`,
`GetBindLocation` (answered "Valley of Trials"), `C_Container.GetItemCooldown`
for the hearthstone (plus `C_Container.PlayerHasHearthstone` and
`UseHearthstone`), the trainer calls, `BuyMerchantItem`, `C_Map` positions
(map 1411 for Durotar) and the game's own waypoint (`C_Map.SetUserWaypoint`,
`C_SuperTrack`, `C_Navigation.GetDistance`). Every event on the probe's list
registers. Missing are classic's names only: `GetNumQuestLogEntries`,
`GetQuestLogTitle`, `IsQuestFlaggedCompleted`, `GetQuestsCompleted`, the
classic gossip calls, `GetItemCooldown`, **`ConfirmBinder`** and
**`GetMerchantItemInfo`**. The last two have no replacement checked yet.

**A quest offer (Kaltunk, one quest).** `GetQuestID` answered 4641, the
quest on offer, so a step can check the window shows its quest before
accepting. The gossip lists were empty: an NPC with one quest skips the
gossip list and opens the quest window straight away. Whether
`AcceptQuest` from addon code takes the quest is still to be seen.

**A class trainer's gossip.** `C_GossipInfo.GetOptions` answered one option
as a full table: `gossipOptionID=96831`, `name="I am interested in mage
training."`, `icon`, `orderIndex`, `status`, `flags`, `rewards` and
`selectOptionWhenOnlyOption=false`. The trainer calls read 0 because the
training list itself was not open yet.

**A vendor (opens straight to its list).** `GetMerchantNumItems` answered 11.
The item details could not be read, since `GetMerchantItemInfo` is gone.
Butler's probe already found `C_MerchantFrame.GetItemInfo` and
`GetMerchantItemLink` on the client (Butler and Equipment read vendors that
way), so the probe now reads the first item with those and
`GetMerchantItemID`, and says which kind of NPC is open through
`C_PlayerInteractionManager.IsInteractingWithNpcOfType` (Gossip, QuestGiver,
Merchant, Trainer, TaxiNode, Binder), with
`C_PlayerInteractionManager.ConfirmationInteraction` added as the likely
innkeeper confirm.

**The vendor again, with the new readings: vendors can be read.** "Talking
to" answered Merchant, so `IsInteractingWithNpcOfType` works and the
`Enum.PlayerInteractionType` names are there. `C_MerchantFrame.GetItemInfo(1)`
answered a table: `name="Tough Hunk of Bread"`, `price=25`, `stackCount=5`,
`numAvailable=-1` (no limit), `isPurchasable`, `isUsable`,
`isQuestStartItem`, `hasExtendedCost` (and one more field past the
probe's eight). `GetMerchantItemID(1)` answered 4540 and
`GetMerchantItemLink(1)` a link, so a "buy X" step can find its item by ID.
`C_PlayerInteractionManager` has `ConfirmationInteraction`, `InteractUnit`,
`ClearInteraction`, `ReopenInteraction`, `IsValidNPCInteraction`,
`IsReplacingUnit` and `ShardTransferConfirm`; whether
`ConfirmationInteraction` confirms the innkeeper waits for an innkeeper run.

**The class trainer's spell list, open.** "Talking to" answered Trainer.
`GetNumTrainerServices` answered 6 and `GetTrainerServiceInfo(1)` answered
`"Arcane Intellect", "available", 135932, 1, "Rank 1", ""`: the name, the
state (available), what looks like the icon's file ID, a 1, the rank and an
empty string. That is not classic's order (name, rank, category, expanded),
so read it by value, not by place, until a second spell confirms the order.
The cost and level of a spell are not read yet (`GetTrainerServiceCost`,
`GetTrainerServiceLevelReq` are not in the probe).

**A turn-in (Gornek, quest 4641 in the log, a talk-to quest).** "Talking
to" answered QuestGiver and `GetQuestID` answered 4641, so the turn-in
window names its quest too. `C_QuestLog.GetNumQuestLogEntries` answered
2 entries, 1 quest; entry 1 is the zone header, a 25-field table with
`isHeader=true`, so a step skips headers to find its quest.
`IsQuestCompletable` answered false, which says nothing here: it speaks to
the progress page, and a talk-to quest usually opens on the reward page.
The probe could not tell the pages apart, so it now has a "quest page"
line (which of `QuestFrameDetailPanel`, `QuestFrameProgressPanel`,
`QuestFrameRewardPanel` and `QuestFrameGreetingPanel` shows) with
`GetNumQuestChoices` and `GetNumQuestRewards`.

**A second turn-in, level 2, meant for the reward page (missed).** The
saved run found no window open: "talking to" nobody, `GetQuestID` 0 and no
quest page showing. All four quest page frames exist (none was missing).
`GetNumQuestChoices` still answered 2 with no window, so it keeps the last
quest's count after the window shuts; read it only while the reward page
shows. Only the last run is saved, so the progress-page run before it was
overwritten.

**The reward page (quest 788, a kill quest, before picking a reward).**
"Talking to" answered QuestGiver, `GetQuestID` 788, the quest page
"reward", `GetNumQuestChoices` 2 and `GetNumQuestRewards` 0 (the two
items are a choice, nothing comes regardless). `IsQuestCompletable`
answered false on the reward page, so a turn-in step must not wait on it
here; on this page it calls `GetQuestReward(choice)`. Three quests counted
as done with this one still in the log, so the count includes one quest
besides 4641 and the hidden flag seen at level 1.

**Gornek's list, before clicking the quest (the gossip quest list).** The
list an NPC shows first is the gossip window, not the quest window's list
page: "talking to" answered Gossip and no quest page showed.
`C_GossipInfo.GetActiveQuests` answered one quest as a table with
`questID=788` and `isComplete=true` (also `isImportant`, `isLegendary`,
`isMeta`, `isTrivial`, `isIgnored`, `frequency`; the title is past the
probe's eight fields). So a turn-in step finds its quest by ID and that it
is ready, without reading the text, then `C_GossipInfo.SelectActiveQuest`
should open its reward page. For this kill quest the game went from the
list straight to the reward page, with no progress page between.

**The progress page (a quest that collects items).** "Wayward Weapons"
from Kzan Thornslash, the Weaponsmith in the Den, asks for 6 Abandoned
Training Weapons. Its window opened straight on the quest (no gossip), on
the progress page: "talking to" QuestGiver, quest page "progress",
`IsQuestCompletable` true, the required items listed and a **Continue**
button (the game's label for Complete Quest). So a turn-in step calls
`CompleteQuest` when the progress page shows and `IsQuestCompletable` is
true, then `GetQuestReward` on the reward page. `GetNumQuestChoices`
answered 2 here, the last quest's count again, since no reward page was
open.

**An offer, with the page line (Vile Familiars, quest 792, Zureetha
Fargaze).** "Talking to" QuestGiver, `GetQuestID` 792, quest page "offer"
(Accept and Decline buttons), `GetNumQuestChoices` 4 (the four weapons the
offer shows, so on the offer page the count is this quest's).
`IsQuestCompletable` answered true on an offer, so it means nothing outside
the progress page. Accepting needs only these three readings and then
`AcceptQuest()`; whether the client lets addon code call it is the one
thing left, and only a real step can show that.

**Forever's own quests, in the first zone.** `GetQuestID` answered
**97279**, far past Classic's quest IDs, and Wayward Weapons is not a
Classic quest. Forever adds new quests from level 1, with IDs Classic data
does not have, so a guide's quest facts must come from the client (or
from data learned in game), not from a Classic quest list alone.

## Troll warlock, level 21, Orgrimmar, 2026-10-19

**An innkeeper's gossip (Valley of Strength), before picking anything.**
"Talking to" answered Gossip, not Binder: the binder interaction likely
starts only once "Make this inn your home." is picked. `C_GossipInfo.GetOptions`
answered 4 options, the window showing Trick or Treat!, Make this inn your
home., Tell me about dungeons I could explore. and I would like to buy from
you. The first entry the client handed back was `orderIndex=4`
(`gossipOptionID=95572`, the dungeons line), so the list comes back in the
client's own order: sort by `orderIndex`, or better pick by
`gossipOptionID`. The probe showed only that first option, so it now lists
every option with its order, ID, name and icon. `GetBindLocation` answered
Orgrimmar and `C_Container.GetItemCooldown(6948)` answered a start time
and 3600 seconds, so the hearthstone's cooldown reads.

**The innkeeper again, every option.** `[0] 95575 Trick or Treat! (icon
132053); [2] 95573 Make this inn your home. (icon 132052); [4] 95572 Tell
me about dungeons I could explore. (icon 132053); [10] 142282 I would like
to buy from you. (icon 132060)`. The order numbers have gaps (0, 2, 4, 10),
so they are not places in the list. The icon names the kind of option: 132052
the innkeeper's, 132060 a vendor's, 132053 plain talk (the trainer option
earlier had 132058). A step can pick "make this your home" by its icon at
any innkeeper, without knowing that innkeeper's option ID or reading the
words, which differ by language. The option IDs likely differ by NPC (and
season options come and go), so a step that names one may only fit that NPC.

**The confirm, after picking "Make this inn your home." (already bound
there).** The game asked anyway: a popup "Do you want to make Orgrimmar
your new home?" with Accept and Cancel. The gossip window shut (0 options)
and "talking to" turned to **Binder**, so the interaction type moves from
Gossip to Binder at the confirm, and a step can tell the popup is the
innkeeper's. Picking the option from code would be
`C_GossipInfo.SelectOption(id)` with the option found by its icon; the
retail popup's Accept calls
`C_PlayerInteractionManager.ConfirmationInteraction(Enum.PlayerInteractionType.Binder)`,
which exists here. Whether addon code may call it (rather than the player
clicking Accept) is still to be seen, and a guide may well leave this one
click to the player.

**A flight master's gossip (Doras, Wind Rider Master, Valley of
Strength), before the map.** One option: `[0] 98541 I need a ride. (icon
132057)`. "Talking to" answered Gossip and the taxi calls read 0, since
the map was not open yet. Icon 132057 marks the flight option, so a step
can open the map at any flight master by that icon.

**The flight map, open.** "Talking to" answered **TaxiNode**.
`NumTaxiNodes` answered 22, the first "Thunder Bluff, Mulgore",
`REACHABLE`, while the map drew about 8 paths: the count includes paths
the character has not learned, so a step reads each path's type
(`CURRENT`, `REACHABLE`, or not learned) rather than trusting the count.
Names are the client's, in its language. The probe read only the first
path, so it now counts the paths by type, lists each one the character can
fly to with `TaxiNodeCost`, and reads `C_TaxiMap.GetAllTaxiNodes` for the
map `GetTaxiMapID` names (for a path ID that does not change with the
language).

**The flight map again, with the new readings.** 22 paths: `CURRENT 1,
DISTANT 14, REACHABLE 7` (DISTANT is the client's word for not learned).
Each the character can fly to, with `TaxiNodeCost`: Thunder Bluff 45
copper, Orgrimmar (CURRENT) 0, Crossroads 99, Sun Rock Retreat 0,
Zoram'gar Outpost 0, Splintertree Post 477, Camp Taurajo 0, Ratchet 0.
**Four reachable paths cost 0, which is not explained yet**: check the
price the map shows over one of them (Ratchet) before a step trusts
`TaxiNodeCost`. `GetTaxiMapID` answered 1464 and
`C_TaxiMap.GetAllTaxiNodes(1464)` a table of 22, the first with
`nodeID=22`, `name="Thunder Bluff, Mulgore"`, `slotIndex=1`, `state=1`,
`position` (a table), `isMapLayerTransition` and `useSpecialIcon`. So a
"fly to X" step names the path by `nodeID`, which does not change with the
language, finds its `slotIndex`, checks it is reachable, and calls
`TakeTaxiNode(slotIndex)`. Whether addon code may call `TakeTaxiNode` is
still to be seen.

Every window a guide needs has now been probed once.
