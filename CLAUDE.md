# Notes for Claude

Read this before working in this repo. The owner runs one Claude project per
addon: this one (**Blackthornes_Pathfinder**), **Blackthornes_Pets**
(`Blackthornes/Blackthornes_Pets`), **Blackthornes_Equipment**
(`Blackthornes/Blackthornes_Equipment`), **Blackthornes_Tradeskills**
(`Blackthornes/Blackthornes_Tradeskills`), **Blackthornes_Farmer**
(`Blackthornes/Blackthornes_Farmer`) and **Blackthornes_Butler**
(`Blackthornes/Blackthornes_Butler`). The projects cannot read each other's
memory, so what one needs to know about another lives in the repos, in this
file and in theirs. Keep them current: when a change here leans on something
new in another addon, or a standing rule from the owner applies to all of them,
add it to each file.

Nothing private goes in this file (no local paths, emails or account names).
It never ships: `.pkgmeta` leaves it out of the zip and
`tools/check_package.py` refuses it.

## What this addon is for

A hand-holding **leveling guide** for WoW: Forever, the sixth Blackthornes
addon (started 2026-10-18): step by step, where to go, which quests to take
and turn in, what to buy, where to fly, where to set the hearthstone and when
to train. It aims to match and beat the paid and free guides players know,
and stays free.

**The owner's direction (2026-10-18):** the guide uses the house's top-level
UI design, motion animations and visual style at their best, and it must
seem like magic. Every step should feel like the addon already knows what
the player needs next. Build each feature on the shared look (Titanforged,
the Blizzard style, `UI/Widgets.lua`, `ns.Motion`) and polish it until it
reads as the best-looking window in the set; never ship a plain or
placeholder look as a feature.

**The guide content is ours.** Routes and steps are written from scratch.
Never copy another guide's routes, text or step data (paid guides' routes
are proprietary; several free addons are GPL, CC BY-NC-ND or All Rights
Reserved), and never copy their code. Quest, NPC and place facts can come
from the client itself (the probe, and in-game learning like Equipment's) or
from data the project has cleared; check the project's notes before using a
new source.

What there is so far is the frame: an empty guide window that shows the
character's level, settings, a minimap button and a read-only `/bpath
probe` for the calls a guide needs. The feature ideas and the open
decisions (the first starting zone, what ships at launch) are in the
project's notes, not in the repo.

How routes are written, ticked off and planned is drafted in
`docs/STEP_FORMAT.md` (2026-10-19, not built yet). The owner's aim
(2026-10-19): Claude works out the fastest route to level, so routes come
from a planner over quest facts and are made faster with times from real
runs, never copied from another guide. Whatever can be gathered without
playing comes first (the owner, 2026-10-19): `tools/make_quest_facts.py
<pfQuest> <mangoszero database> <tables folder>` writes the planner's
`tools/facts/` from Classic data (cleared for routes, 2026-10-19), the
Forever client's game tables and Equipment's learned quests and spots.
Never commit the sources or the tables, never name where the tables were
downloaded, and rerun it when they are pulled again.

## How this repo was set up

It copies its sisters on purpose, most closely Pets (copied 2026-10-18, the
newest with every shared file), so check them before inventing a convention:

- **Layout** `Core/ Data/ Logic/ UI/ Probe/ tools/ docs/`, one module per
  file through `ns.NewModule`, no Ace3 or LibStub. `Core/Init.lua` is Pets'
  (itself Equipment's and Farmer's), renamed, without Pets' player-and-pet
  event filter. The global is `_G.BlackthornesPathfinder`, the commands
  `/bpath` and `/pathfinder`, the saved data `BlackthornesPathfinderDB`
  (account: window positions, minimap, debug, the shared settings) and
  `BlackthornesPathfinderCharDB` (per character, because each character is
  at its own step of the guide).
- **Palette** is the house one (`ns.COLORS`). `UI/Theme.lua`,
  `UI/Widgets.lua`, `UI/Minimap.lua` and `UI/Settings.lua` are Pets' with
  the pet parts taken out. The minimap button starts at 320 degrees, clear
  of Tradeskills' at 170, Farmer's at 200, Equipment's at 230, Pets' at 260
  and Butler's at 290.
- **Tools** (`syntaxcheck`, `lintcalls`, `runtests`, `check_release`,
  `check_package`, `check_locale`, `check_private_files`, `make_whatsnew`,
  `announce_discord`, `post_general`, `make_frame_art` and their tests,
  `link.ps1`) are Pets' with the names changed. If one of them gets a fix in
  a sister repo, bring it here too. One difference: before the first
  release `tools/test_check_release.py` accepts `ns.RELEASED_VERSION =
  "0.0.0"` while CHANGELOG.md has no version yet.
- **Tests** are `tools/test_*.lua`, found by name, run with `python
  tools/runtests.py` (Lua 5.1 through `lupa`). `tools/testenv.lua` loads
  the files the TOC lists, so there is no second list to keep.
- **PRs** follow the sisters' habit: a "Before:" and an "After:" paragraph
  in plain words, then a short "How" naming the functions and tests touched,
  that the checks pass, and whether `/reload` is enough. Release PRs are
  `release/X.Y.Z` branches titled "Changelog for X.Y.Z".
- **API findings** go in `docs/FOREVER_API_FINDINGS.md`. The sisters' files
  of the same name record what the Forever client does for their areas;
  read them before relying on an API. Equipment's quest arrow, waypoints,
  map pins and in-game quest learning (`Logic/QuestArrow.lua`,
  `Logic/Waypoints.lua`, `UI/MapPins.lua`, `Logic/QuestLearn.lua`) are
  the place to start for a guide arrow and quest data; copy, don't call.

Nothing here calls the other addons, and nothing calls this one. If that
changes, write down the global and the calls in both repos' `CLAUDE.md`,
the way Farmer and Tradeskills do for prices and goals. When a guide arrow
comes, it joins the one-arrow rule (`_G.BlackthornesArrows`, see Pets' and
Equipment's notes) and TomTom handling the same way the other arrows do.

There is no CurseForge project yet: the TOC's `X-Curse-Project-ID` line stays
commented until the owner creates one. **Never copy a sister's ID here**: the
copy from Pets first carried Pets' ID, and a tag would have uploaded
Pathfinder to the Pets page. The first release is 0.1.0.

## Pathfinder in the sisters' shared lists

`Core/SisterNote.lua`, `UI/About.lua` and `UI/WhatsNew.lua` here list
Pathfinder beside the other five (`SisterNote.ADDONS`, `About.TITLES`,
`WhatsNew.ADDONS`, with its map icon). The other five repos do not list it
yet, so the files differ by those lines only. Add Pathfinder to all their
copies (and the "a step-by-step leveling guide" line to each one's
translations) in the same round as Pathfinder's first release, not before,
and only when the owner says so: while Pathfinder is being built, nothing
here may change the five live addons (the owner, 2026-10-18), so copy from
them and never into them:
a sister note naming an addon players cannot get yet would send them
looking for nothing. Until then the What's New window drawn by a sister's
copy leaves Pathfinder out.

## The settings pages (from Tradeskills)

The owner asked (2026-10-09) for Tradeskills' Settings upgrade in Pets,
Equipment and Farmer. `UI/SettingsPages.lua` is the same file in all three
(a fix to it belongs in all three): category pages along the top
(`settingsPage`, the one left on), two columns a page, what a setting does
as the row's tooltip ("Show descriptions", `settingsDescriptions`, off by
default, puts it back under the rows), "Find a setting", and Text size
(`textSize` normal/large/larger adds 0/1/2 to `Theme.sizes`, now a lookup
over `Theme.BASE_SIZES`; read once, so it waits for /reload). The window
fits its fullest page, so no page scrolls. Add a setting with
`pages:Row(page, column, label, description)` and
`pages:Section(page, column, "HEADING")` in `UI/Settings.lua`; every
`/bpath` command has a button there, except the ones that only list things
in chat (help), which are typed only (the owner, 2026-10-15). Pathfinder
has only the General and About pages so far. The minimap button always
shows: no row and no `/bpath minimap` (2026-10-15); a saved `minimapHidden` is kept but not read.

## Off, Shift or Always on tooltips

A player asked, the owner said yes (2026-10-18): each tooltip line an
addon adds is Off, Shift (only while Shift is held) or Always, picked on a
stepper in Settings. `UI/TooltipShift.lua` is the same file in the five
other addons (a fix to it belongs in all of them). Pathfinder adds no
tooltip line yet, so it has no copy; the first line it adds brings
`UI/TooltipShift.lua` and its test over from Pets and follows the same rule
(the Shift choice kept account wide in `tooltipShift[key] = true`).

## German translation

The owner said yes (2026-10-11) to a German translation, piloted in Pets
before the others. Players are told the language as "Deutsch", or
"Deutsch (German)" where English readers need it; the code names stay
`deDE` and `Locale/deDE.lua`.

- **English is the key and the fallback.** `Locale/Locale.lua` (first in
  the TOC) makes `ns.L`, whose missing keys answer the key itself, so
  `L["Feed"]` is "Feed" until a translation fills it in. `L.Format(key,
  ...)` is `string.format` on the translation, and puts values named by
  place (`%2$s ... %1$d`) in order where German word order needs them,
  since the tests' Lua 5.1 cannot.
- **Adding a string:** write it as `L["English text"]` or
  `L.Format("English %s", value)`, a literal where it is written (a key
  built at run time cannot be checked), add its line to `Locale/deDE.lua`
  (informal "du" and the game's own German words: Quest, Flugmeister,
  Ruhestein, Lehrer, Händler, Stufe, Meter), and run
  `python tools/check_locale.py`, which lists keys with no German line and
  German lines no longer used. It only warns (the tests workflow runs it
  as a warning); keep it at 0 missing. `tools/test_locale.lua` loads the
  addon as a German client.
- **Left in English on purpose:** slash command words, saved and internal
  keys, anything compared against data, data names (quests, NPCs,
  zones; item and spell names come from the client), `Probe/` output and
  debug lines (they are for us), and spell names a macro casts.
- German runs about 30% longer: buttons grow to fit, settings rows wrap,
  and a new fixed width must wrap or grow, never end in "...".
- `Locale/Locale.lua` and `tools/check_locale.py` are meant to be the same
  in all six addons; a fix to either belongs in all six. `Core/SisterNote.lua`, `UI/SettingsPages.lua` and
  `UI/Titanforged.lua` read `ns.L` with an English stand-in, so they still
  work unchanged in an addon without `Locale/`.

## Simplified Chinese translation

The owner said yes (2026-10-18) to Simplified Chinese, piloted in Pets as
German was, after a player asked for it. It is written by us from the
English keys: never take a translation file or text from a player or
anyone outside (the owner turned down a player's zip for safety). Talk to
the owner about "Simplified Chinese"; the code names are `zhCN` and
`Locale/zhCN.lua`, which works the same way as `Locale/deDE.lua` (loads
only when `GetLocale()` is "zhCN"; a missing line shows English). Use the
game's own Chinese words (任务, 飞行管理员, 炉石, 训练师, 商人, 等级, 码) and
full-width punctuation. Every new string gets a zhCN line beside its
deDE line; `tools/check_locale.py` checks both. The fonts come from the
client (`Theme.FONT` reads `GameFontNormal`), so Chinese shows on a
Chinese client. Tested in `tools/test_locale.lua`. Not yet seen in game.

## French, Spanish and Russian translations

The owner asked (2026-10-18) for French, Spanish and Russian in every
addon, beside Simplified Chinese. They follow the same rules as German and
Simplified Chinese: written by us from the English keys, never from a
player's or anyone else's file. `Locale/frFR.lua` (informal "tu"),
`Locale/esES.lua` (one Spanish for both Spanish clients: it loads on
"esES" and "esMX", neutral words, "tú") and `Locale/ruRU.lua` ("ты"),
each in the game's own words, yards shown as metres as in German. Every
new string gets a line in each of the five files; `tools/check_locale.py`
checks them all. Tested in `tools/test_locale.lua`. Not yet seen in game.

## The house frame (Titanforged)

The owner picked this look for all four addons on 2026-10-04 from two mockups
(the other was "Arcane Glass"), and Tradeskills got it first. It's the
game's own window shape with the light turned up: a gold metal rim with
corner gems, a round portrait with the addon's emblem, the name on a plate
across the top edge and a red close gem. Buttons are raised metal with gold
labels, and the main action is solid gold with dark "ink" lettering; a
primary button given its own dark `baseColor` keeps a gold label, or it
reads as an empty box (Tradeskills' first bug with the look, checked in
`tools/test_titanforged.lua`).

It lives in `UI/Titanforged.lua` (`Titanforged:Dress(frame, opts)`,
`:Opened(frame)`), with the art in `Media/Frame/*.tga`, drawn by
`tools/make_frame_art.py`. All are Tradeskills' copies; Pathfinder's emblem is the
**compass** (`EMBLEM = "compass"`), a compass rose drawn here (four long
points over four short ones, a diamond hub cut out) so it reads at the
36 px the portrait shows it. The guide window wears the full frame;
Settings has the plate and close gem but no portrait, which would sit
over its first heading. Pathfinder has no Window effects setting yet, so `Motion.Level()` is always "full" and the glint always
runs; if one is added, the glint and portrait light already follow it.

## The Blizzard window style

The owner asked (2026-10-10) for a choice of the game's own look beside
Titanforged, in all four addons. "Window style" in Settings (`windowStyle`,
`titanforged` or `blizzard`, Titanforged by default; read once at login,
so a change waits for /reload, as Text size does). `UI/BlizzardLook.lua`
is the same file in all four (a fix to it belongs in all four): picked, it
lays the game's colours over `Theme.colors` (grey metal, the game's gold,
plain rows with a blue bar for the one picked) and puts out the halos;
`Titanforged:Dress` hands the window to `BlizzardLook.Dress` (silver rim,
a title tab where the plate sits, a silver-ringed portrait and the game's
`UIPanelCloseButton`, with the same trim fields); and the widgets call
`BlizzardLook.Button`, `.Checkbox` and `.Thumb` (a scroll thumb) to wear
the game's own texture files. Window style's Settings row is a stepper
like Text size.
It never touches a Blizzard frame. Each file is checked once
(`BlizzardLook.HasArt`); a client without one keeps that widget in the
house look, and `/bpath probe` lists what is missing. Not yet seen in game.
New widgets should look right in both styles.

## Reading the probe

The owner asked (2026-10-10) for check results without screenshots, in all
four addons. `ns.KeepCheck(name, fn)` in `Core/Init.lua` runs a check that
prints to chat, keeps every line it prints (colours and links taken out, a
secret value kept as "(secret)") and saves them in the account save as
`lastProbe = { check, at, version, lines }`, replacing the last one; chat
adds "Saved for Claude, /reload to write it." It wraps `/bts probe`
(Tradeskills, saved under `BlackthornesTSDB.global`), `/beq probe` and
`/beq arrow check` (Equipment), `/bpet probe` and `/bpet arrow check`
(Pets), `/bpath probe` (Pathfinder), and `/farm arrow check` and `/farm gathering check` (Farmer, which
has no probe). Each has a Settings button. Never rename `lastProbe`; a new
check that players run for a report goes through `ns.KeepCheck` too, and a
fix to it belongs in all four.

When the owner says "read the probe": he has run the check and typed
`/reload` (or logged out). In the thread, connect to his device, ask for
his game's WTF folder (already approved; the path is in the project's
memory) and stage the addon's account save from
`WTF\Account\<account>\SavedVariables\` (`Blackthornes_TS.lua`,
`Blackthornes_Farmer.lua`, `Blackthornes_Equipment.lua`,
`Blackthornes_Pets.lua` or `Blackthornes_Pathfinder.lua`), read only. Read its `lastProbe`: `check` says
which one ran and `at` when; one older than his message means the save was
not written yet, so ask him to `/reload`. Use only the probe lines; never
commit the save or copy anything else out of it.

## Discord

The addons share a Discord server, Blackthornes AddOns (public invite
https://discord.gg/f2geDecrw2, set up 2026-10-05). After a release uploads,
`release.yml` runs `tools/announce_discord.py`, which posts the version's
CHANGELOG section to the server's #announcements through a channel webhook
kept in the `DISCORD_WEBHOOK_URL` repository secret. The owner sets that secret
himself; never ask him to paste the webhook address anywhere. Without it the
step does nothing, and a failed post never undoes the upload. The tool is the
same in all four repos; a fix to it belongs in all four.

The owner asked (2026-10-09) for one post in #general per release too,
and (2026-10-10) for it to be short: a few bullets in plain words, a
sixth-grade reading level, warm, in his voice (short, contractions, no
jargon, no file or setting names, never his name), saying what players will
notice. Each release PR writes the new version's section in `NEWS.md`
(`## X.Y.Z`, like CHANGELOG.md; it never ships) next to the CHANGELOG
section: the bullets, then one line of thanks. After the upload
`tools/post_general.py` scans it with `check_package.py`'s PRIVATE list and
posts it through the `DISCORD_GENERAL_WEBHOOK_URL` secret, which the owner
sets himself, under a line with the addon's name and version (so each
addon's bullets are their own group) and "(full list of changes in
#announcements)". It carries no CurseForge link and no card (link previews
are turned off). No section or no secret means no post.
A player's name never goes in a report (the owner, 2026-10-09): no
CHANGELOG, #announcements post, commit or PR text names a player, and
`check_release.py` refuses a CHANGELOG section that credits one
(`names_a_player` in `post_general.py`). The #general post is the one
exception: its last line thanks, by their Discord name, everyone who asked
for or reported the changes, each name once ("Thanks Ana and Bob for the
ideas and reports!"); leave it out when nobody asked. Find who asked from
the project's threads.
The thanks line no longer goes out with the webhook post (the owner,
2026-10-13: thank each player with a real @mention, so they get a
notification): `post_general.py` leaves out the paragraph that starts
"Thanks" (`without_thanks`), and the owner's bot, on his PC, posts it under
the release post with the mentions once he approves the wording, looking
the Discord names up there. Discord IDs never go in a repo. NEWS.md keeps
the thanks line, by Discord name, as before; ask the owner for any name
that isn't known.
This tool is also the same in all four repos.
Changes to the Discord bots, the digest or the release posting tools
(like this one) never go in a CHANGELOG, #announcements or #general
section (the owner, 2026-10-10): they are not changes to the addon.

The language is "Deutsch" in every post (the owner, 2026-10-11): a
CHANGELOG.md or NEWS.md section about the German translation or German
clients says "Deutsch", or "Deutsch (German)" where English readers need
the hint, never "German" alone. `tools/check_release.py` warns (it does
not refuse) when this version's CHANGELOG.md or NEWS.md section says
German without Deutsch. This rule is in every addon's notes; keep them
the same.

## What's New

The owner asked (2026-10-12) for the Discord #general post to show in game,
the first time it loads after an update, in one window for every addon.
`UI/WhatsNew.lua` is the same file in all five (a fix to it belongs in all
five), and so are `tools/test_whatsnew.lua`, `tools/make_whatsnew.py` and
`tools/test_make_whatsnew.py`. There is no shared core addon: every copy
signs up in `_G.BlackthornesWhatsNew` as it loads, the first to reach
PLAYER_LOGIN starts the only timer (`WhatsNew.DELAY`, 5 s, never in a
fight), and that one check gathers what is new in all of them. The copy
with the highest `FILE_VERSION` draws the window (first in
`WhatsNew.ADDONS` on a tie); raise it when a change needs the newer copy.

The words are NEWS.md's: it never ships, so `tools/make_whatsnew.py` writes
its newest three sections, bullets only (the thanks line names players and
never ships), into `Core/WhatsNewText.lua` (`ns.WHATS_NEW`; never edit it by
hand). The window shows new features only (the owner,
2026-10-13): a section's
fixes and other changes go under a "Fixes and changes:" line, which go to
Discord but not the window, and every line is plain words with no hype,
no questions to the reader, no exclamation marks and no dashes as
punctuation (the tool notes one that trips `STYLE`). **Every release PR that writes a NEWS.md section runs
`python tools/make_whatsnew.py` too**; `check_release.py` refuses a tag
while the file is behind, and `tools/test_make_whatsnew.py` fails on every
push. The bullets stay in English, also on a German client.

Shown once a version: each addon keeps the newest version shown in its own
account save (`whatsNewSeen`); after an update the sections newer than that
(at most three) show, and an addon that never kept one shows its newest.
"After an update" (`whatsNewPopup`) and "What's New motion"
(`whatsNewMotion`) are on unless unticked, off in all when off in any;
`whatsNewScale` is the size grip's, where the addon has one. Never rename
them. The `whatsnew` command and a Settings button open it any time, with
each addon's newest. It rises in, its divider draws out, each addon's card
slides up with its icon popping and a light crossing it, and the Got it
button glows (one looping animation the game plays, only while it shows);
Motion off lands it all at once. Not yet seen in game.

## The About page and the note

The owner asked (2026-10-13) for a note on how the addons are made, once at
the top of What's New and kept on an About page in every addon's Settings.
`UI/About.lua` is the same file in all five (a fix to it belongs in all
five): `About.NOTE` is the owner's wording, a paragraph a key; change it
only when he asks, in all five, with each `Locale/deDE.lua`. `About:Note`
and `About:Info` build the page's two columns (the version, the Discord in
a box to copy, how to report a bug, a thank-you that names no player, a
What's New button and the other Blackthornes addons from
`SisterNote.ADDONS`); each addon's Settings places them on its "about"
page. `UI/WhatsNew.lua` (FILE_VERSION 3) puts the note at the top of the
next window that comes up by itself, alone when nothing is new, then sets
`aboutNoteSeen` in every sister's account save (never rename it); with the
window turned off it waits. Tested in `tools/test_whatsnew.lua`.

One-time cards (the owner, 2026-10-13): an addon can put cards in
`ns.WHATS_NEW_TIPS`, each `{ key, title, icon, paragraphs, hint, button,
run, due }`. The next window that comes up by itself shows each one after
the note, only when `due()` says so (in a pcall), with a button that calls
`run()` and closes the window. Looked at once either way: the key goes in
that addon's account save as `whatsNewTipsSeen[key]` (never rename it), so
a card never comes back; with the window turned off it waits.
`UI/WhatsNew.lua` is at FILE_VERSION 4 for it. Equipment's
`Logic/UpgradeQuest.lua` has the first, for the upgrade quest, due while
it is off.

## The sister note

The owner asked (2026-10-11) for the addons to say, once, which of the
others a player does not have. `Core/SisterNote.lua` is the same file in
all five (a fix to it belongs in all five), and so is
`tools/test_sisternote.lua`. Every copy signs up in `_G.BlackthornesSisterNote`
as it loads; the first to reach PLAYER_LOGIN starts the only timer
(`SisterNote.DELAY`, 8 s, no ticker), and that one check prints one line for
all of them: the sisters not installed (`C_AddOns.DoesAddOnExist`, else
`GetAddOnInfo`'s "MISSING"), each with what it adds. One installed but
turned off is never named. Once per account: what it named is kept in every
loaded addon's account save as `sisterNoteTold[folder] = true`, so only a
sister never named before (one released later) brings it back. "Sister
addons" in Settings (`sisterNote`, on unless unticked) and the `sisters`
command on each addon: off in any is off in all, and changing it writes all.
Never rename `sisterNote` or `sisterNoteTold`. A new addon goes in
`SisterNote.ADDONS` in all the copies. It names only our own addons.

## One key per character

The owner asked (2026-10-11) that a character can never be mistaken for
another again. Old records had sent errands to the character playing:
Butler filled a mail to itself and told a player to mail Medium Leather to,
and log out for, the character they were on (an old "Name-Realm" record of
Tradeskills' beside the GUID one), and a reload wiped alts' saved gear in
Equipment. The rule, in every addon:

- **A character is its GUID** (`UnitGUID("player")`) in saved data and in
  every call between the addons. Never a first name, "Name-Realm" or a
  short name: Forever lets characters share a first name. Names are for
  showing and for a mail's To line only, always first and last.
- **A GUID the client won't read (a dungeon) means "not sure who's
  playing":** write nothing under another key, and offer nothing for an
  alt. Tradeskills remembers each character's GUID in its own file
  (`BlackthornesTSCharDB.guid`) for that case.
- **Old records stay readable and count as the same character; nothing is
  deleted.** Tradeskills folds an old "Name-Realm" record into the GUID one
  at login, once (`Config:AdoptLegacyCharacter`): it is kept whole in
  `formerCharacters[old key]` with `retiredInto` (never rename either), what
  the GUID record lacks is filled from it when it carries that GUID, and
  the queue's references to the old key follow. Farmer reads a goal tagged
  "Name-Realm" as the character's and tags it with the GUID once the
  character gathers toward it or changes it.
- **One test per addon answers "the same character?" and "the one
  playing?"; never compare keys or names by hand.** Tradeskills:
  `Characters:Same`, `:IsPlaying` and `:Canonical` (`Core/Characters.lua`),
  and `playing` on each `Butler:Holdings()` entry. Butler:
  `Errands:IsMe(name)` (full name, first name alone, any old record's name,
  any case, with or without a realm). Farmer: `Goals:IsOwner`. Equipment:
  `Alts.PlayerGUID()`.
- **Every errand that targets a character asks that test right before it
  acts and refuses the character playing:** a mail, a gold top-up, a Log
  out, an alt's upgrade, a learned habit, the disenchanter.
- Tested in Tradeskills' `tools/test_onecharacter.lua`, Butler's
  `tools/test_notme.lua`, Farmer's `tools/test_goals.lua` and Equipment's
  `tools/test_alts.lua`. This rule is in every addon's notes; keep them the
  same.

## Writing for players

Every word a player reads (labels, buttons, tooltips, Settings rows and
their descriptions, empty lists, chat lines, slash command help) reads the
way a friend who plays would say it: plain, warm and human. Write it at a sixth grade reading level. Short
sentences in everyday words, contractions welcome. Say what the player
sees or does, not how the addon works inside. No hype or sales words
("seamlessly", "effortlessly", "now you can", "powerful"), no filler, no
em-dashes, and no questions to the reader. The German in
`Locale/deDE.lua` changes with the English, in the same informal "du"
voice. Farmer's play cheers keep their "!" (drop-quality cheers, goal
marks, streaks, "Up to #N!", "Goal done: X!"), and `About.NOTE` is the
owner's own wording. This rule is in every addon's notes; keep them the
same.

## The owner's standing rules (all the addons)

- **Every list is dark glass** (the owner, 2026-10-12: "keep this as the
  standard across all Blackthornes addons", after Farmer's Kills & Loot
  panel was given the look of Tradeskills' queue). Rows or lines take
  `glass` and `glassAlt` in turn, by place, with a 1 px `border` line
  (alpha 0.6) under each; under the mouse `glassHover` and a gold edge,
  only on that row; the row picked or open is `glassActive` with a bright
  gold edge down its left. Never the older `row`/`rowAlt` bands for a
  list, a panel's lines or cards. A gradient fades through
  `Theme.LightGradient` or is hidden, never with SetAlpha alone (it stayed
  lit on Forever). This rule is in every addon's notes; keep them the same.
- **"Always check that it's clear to post."** Anything that goes public (a
  release, a CurseForge page, a post) is checked for private or unexpected
  content first, and nothing is published or uploaded without the owner's
  go-ahead. He tags releases himself.
- **Keep his data safe.** Never commit saved variables, tokens or anything
  from his machine; the upload keys are repository secrets he sets himself,
  so never ask him to paste one anywhere.
- **Changelogs come from git history.** Work out what changed since the last
  tag from the merged PRs and commits (`git log vX.Y.Z..origin/main --merges`);
  never ask the owner what went in. Claude drafts the CHANGELOG section in a PR;
  The owner merges, pulls `main`, tags and pushes.
- **A checkout shows the real version number** (the owner,
  2026-10-12). `ns.RELEASED_VERSION` in `Core/Init.lua` is the newest
  `## X.Y.Z` in CHANGELOG.md, shown when the packager has not filled in the
  TOC's `@project-version@` (he plays from a clone). The release PR that
  writes the CHANGELOG section changes it too; `tools/check_release.py`
  refuses a tag it does not match, and `tools/test_check_release.py` fails
  while the two disagree. This rule is in every addon's notes.
- **Every reply that ships code ends with the GitHub Desktop steps,** naming
  the branch: merge the PR on github.com (Ready for review, then Merge pull
  request); in GitHub Desktop switch **Current branch** to **main** and click
  **Pull origin**; then say whether the game needs `/reload` or a full restart
  (a full restart when a file is added, removed or renamed, or the TOC
  changes). For a release, add: History, right-click the newest commit,
  Create Tag, `vX.Y.Z`, Push origin. Remind him to pull `main` first, or the
  tag lands on an old commit and nothing runs.
- **CurseForge descriptions are features only.** Leave out privacy notes and
  any explanation of public emotes or their switches. Those belong in the
  README and CHANGELOG.
- **Forever is not retail, and not 1.12 either.** The owner: "keep in mind
  this is WoW: Forever." Classes have classic-style talent trees, held on
  Forever in one trait tree per class (see Equipment's findings), and
  Forever adds zones and quests that Classic data does not have. Never
  assume a retail or classic API exists for quests, gossip, auto-accept and
  turn-in, flight paths, the hearthstone or trainers: check with `/bpath
  probe` (run it at a quest giver, a flight master, an innkeeper and a
  trainer too) and record what it finds in `docs/FOREVER_API_FINDINGS.md`.
- **Smooth play comes first, but never at the cost of looks** (the owner,
  2026-10-09, after a hitch while crafting). Nothing on a timer or
  OnUpdate rebuilds or re-places a whole list, map or set of markers when
  only one thing moved: keep what is drawn, and redo only rows or pins
  whose inputs changed (a per-row key, a version number). Bag, loot,
  cast, skill and profession-list events arrive in bursts, several per
  craft or loot: coalesce them, read only what they changed, and skip
  work for windows that are hidden. Work over hundreds of items (recipes,
  sources, saved spots) is spread over frames (a worker with a small
  per-frame budget) rather than done in one frame, and shown when done.
  Clicks and typing still answer at once. The two causes found: Farmer's
  minimap markers gathered, sorted and re-placed every saved spot once a
  second because the clock second was in their redraw key (now only the
  fade moves, `MapMarkers:FadeMinimap`); and on every craft Tradeskills
  re-read every recipe in the profession window and repriced the whole
  craft pane in one frame (now `Recipes:NothingNewMidCraft` skips the
  re-read mid-run and `CraftPanel:RefreshInSlices` spreads the pane over
  frames). Visuals and usability are never traded away for speed. This
  rule is in all four addons' notes; keep them the same.
- **The client is WoW: Forever, a retail engine** (`## Interface: 16001`,
  modern Lua), not 1.12. Instances hand addons secret values that raise when
  compared, concatenated or formatted, so read client values inside a pcall.
  Registering an event the client does not know raises too, which is why
  `ns.RegisterEvent` wraps it.
