# Blackthornes Pathfinder

A WoW: Forever addon that walks you through leveling, step by step: where to
go, which quests to take and turn in, what to buy, where to fly, where to set
your hearthstone and when to train.

Built for the WoW: Forever client (`## Interface: 16001`), without Ace3 or
LibStub, matching
[Blackthornes Pets](https://github.com/Blackthornes/Blackthornes_Pets),
[Blackthornes Equipment](https://github.com/Blackthornes/Blackthornes_Equipment),
[Blackthornes Tradeskills](https://github.com/Blackthornes/Blackthornes_Tradeskills),
[Blackthornes Farmer](https://github.com/Blackthornes/Blackthornes_Farmer)
and [Blackthornes Butler](https://github.com/Blackthornes/Blackthornes_Butler).
They share a palette, a window frame and a framework on purpose.

This is the start: the guide window (empty for now, with the character's
level in its header), the settings window, a minimap button and
`/bpath probe`, which checks which quest, NPC, flight path, hearthstone,
trainer and map calls the client supports. The guide's steps come next.

## Install

### Linked to your working copy (recommended while developing)

Run this once, and from then on testing a branch is pulling it and typing
`/reload`:

```powershell
.\tools\link.ps1
```

It junctions `Interface\AddOns\Blackthornes_Pathfinder` to this folder, so
the client reads your checkout directly. Nothing is copied, so there is no
deploy step to forget.

Two things `/reload` will **not** pick up, because the client only reads them at
startup:

- a file that was **added, removed or renamed**
- any change to **`Blackthornes_Pathfinder.toc`**

After pulling a branch that did either, restart the client once.

### Copied into the client

```powershell
.\deploy.ps1              # syntax check, lint, then mirror into Interface\AddOns
.\deploy.ps1 -SkipCheck   # skip the checks (not recommended)
```

Both scripts default to `D:\Blizzard\World of Warcraft\_classic_beta_`. Pass
`-GamePath` if the client lives somewhere else.

The addon folder name has to stay `Blackthornes_Pathfinder`, matching the
`.toc` inside it. If they differ, the client ignores the folder and says
nothing.

## Use

```
/bpath            open the guide window (so does clicking the minimap button)
/bpath help       list every command
/bpath probe      check what this client supports for a leveling guide; it only reads
/bpath settings   open the settings window (so does right-clicking the minimap button)
```

Some probe readings only answer with the matching window open, so run it
again at a quest giver, a flight master, an innkeeper and a trainer.

The settings window is also under the game's Options > AddOns. Its pages
(General, About) are picked along the top. Hover a setting to see what it
does, or tick **Show descriptions** to see it under every row; **Find a
setting** searches every page. **Text size** makes all of the addon's text a
point or two bigger after a `/reload`. Every command above except help has a
button there too.

`/pathfinder` works too.

## Layout

| Folder | What is in it |
|---|---|
| `Core/` | Namespace, module registry, event dispatch, slash commands, saved variables, the sister note and the What's New text |
| `Locale/` | The words players see, in Deutsch, Simplified Chinese, French, Spanish and Russian |
| `UI/` | Theme, widgets, the house window frame and the Blizzard style, the minimap button, the guide window, the settings window, About and What's New |
| `Media/` | The window frame's art (`Frame/*.tga`), drawn by `tools/make_frame_art.py` |
| `Probe/` | `/bpath probe`, which checks what the running game actually supports instead of guessing |
| `tools/` | Checks, tests, the frame art script and the link script. Not shipped to the client |
| `docs/` | What the Forever client actually does, found with `/bpath probe`. Not shipped |

`Blackthornes_Pathfinder.toc` lists every Lua file in load order. A file that
is not in it does not load, and WoW says nothing about it.

## Development

```bash
python tools/syntaxcheck.py   # parse every Lua file with a real 5.1 parser
python tools/lintcalls.py     # find calls to methods, and constants, never defined
python tools/runtests.py      # run the logic tests outside WoW
```

`tools/` requires `lupa` (`python -m pip install --user lupa`).

The checks exist because WoW silently disables an addon whose first TOC file
fails to compile, and because a call to a method that no longer exists is valid
Lua that fails only when that line runs. `deploy.ps1` runs the first two before
it copies anything, and `.github/workflows/tests.yml` runs all of them on every
push.

The tests load the addon against a stub client (`tools/testenv.lua`), reading
the file list straight from the TOC. A new test is a new `tools/test_*.lua`
file and nothing else.

## Releasing

Releases are cut by pushing a tag like `v0.1.0`.
`.github/workflows/release.yml` then:

1. refuses the tag unless `CHANGELOG.md` opens with a `## 0.1.0` section
   (`tools/check_release.py`);
2. runs the tests;
3. builds the player-facing zip with the
   [BigWigs packager](https://github.com/BigWigsMods/packager), uploading
   nothing;
4. checks that zip is clear to post (`tools/check_package.py`): only the
   addon's own files, and nothing that looks private, such as a Windows path,
   an email address, a saved-variables dump or a token;
5. only then uploads that same zip to each site with a token, and attaches it
   to a GitHub release.

To release from GitHub Desktop: add the new version's section to the top of
`CHANGELOG.md` and merge it to `main`, pull `main`, then **History**, right-click
the newest commit, **Create Tag...**, name it `v0.1.0`, and **Push origin**.

The version is never typed by hand. The TOC says
`## Version: @project-version@` and the packager fills in the tag. Running
straight from a clone there is no packager, so the addon shows
`ns.RELEASED_VERSION` from `Core/Init.lua`, the newest version in
CHANGELOG.md: the release PR changes both, and `tools/check_release.py`
refuses a tag they disagree with. The middle number moves for new
behaviour, the last for fixes alone; a tag like `v0.2.0-beta1` is uploaded as a beta.

`.pkgmeta` leaves `tools/`, `docs/`, `deploy.ps1`, `CLAUDE.md` and this README
out of the zip. There is no CurseForge project yet; its ID goes on the `X-Curse-Project-ID` line of the TOC once it exists.
Uploading also needs a `CF_API_KEY` repository secret in the repository's
settings on github.com. Without both, the workflow
still builds and checks the zip but uploads nothing to CurseForge.
