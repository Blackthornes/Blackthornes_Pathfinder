-- Blackthornes Pathfinder -- Locale/deDE.lua
-- Deutsch (German): the words players see, on a German client.
--
-- Each line is the English key (exactly as the code writes it) and its
-- German. A key with no line here shows in English. The German speaks to
-- the player as "du", the way the game's own German does, and uses the
-- game's words (Quest, Flugmeister, Ruhestein, Lehrer, Händler, Stufe,
-- Meter). A line may name its values by place ("%2$s ... %1$s") where
-- German word order needs it; L.Format puts them in order.
--
-- Quest, NPC, zone and item names stay as the data or the client gives
-- them. tools/check_locale.py lists keys with no line here and lines no
-- longer used.

local _, ns = ...
local L = ns.L

local ok, locale = pcall(function() return GetLocale() end)
if not (ok and locale == "deDE") then return end

-- Core
L["Saved for Claude, /reload to write it."] = "Für Claude gespeichert, /reload schreibt es."
L["module %s:%s failed"] = "Modul %s:%s fehlgeschlagen"
L["show this list"] = "zeigt diese Liste"
L["unknown command: %s"] = "unbekannter Befehl: %s"
L["/bpath %s failed: %s"] = "/bpath %s fehlgeschlagen: %s"

-- The sister note
L["and"] = "und"
L["works with other Blackthornes addons you don't have yet: %s. %s on CurseForge."] = "arbeitet mit weiteren Blackthornes-Addons zusammen, die dir noch fehlen: %s. %s auf CurseForge."
L["It's"] = "Du findest es"
L["They're"] = "Du findest sie"
L["This note shows once."] = "Dieser Hinweis erscheint nur einmal."
L["turn the once-only note about the other Blackthornes addons on or off"] =
    "schaltet den einmaligen Hinweis auf die anderen Blackthornes-Addons ein oder aus"
L["the note about the other Blackthornes addons is on. It shows once for any you don't have."] =
    "der Hinweis auf die anderen Blackthornes-Addons ist an. Er erscheint einmal für jedes, das dir fehlt."
L["the note about the other Blackthornes addons is off, in all of them."] =
    "der Hinweis auf die anderen Blackthornes-Addons ist aus, in allen."
L["where to farm any material"] = "wo du jedes Material farmen kannst"
L["auction prices, crafting profits and a craft queue"] =
    "Auktionspreise, Gewinne beim Herstellen und eine Herstellungsliste"
L["which gear is an upgrade for you, and where to get it"] =
    "welche Ausrüstung für dich besser ist und wo du sie bekommst"
L["feeding and taming for hunter and warlock pets"] =
    "Füttern und Zähmen für Begleiter von Jägern und Hexenmeistern"
L["what to do with every item in your bags"] = "was du mit jedem Gegenstand in deinen Taschen tun solltest"

-- Diets

-- The beast arrow

-- The compendium's data

-- Food

-- The pet's status

-- Tames and pet skills

-- TomTom

-- Map pins

-- The arrow's window

-- The compendium window
L["Settings"] = "Einstellungen"
L["Also in %s"] = "Auch in %s"

-- The Feed buttons

-- The Pet care key

-- The pets window

-- The minimap button
L["Click to open"] = "Klicken zum Öffnen"
L["Right-click for settings"] = "Rechtsklick für die Einstellungen"
L["Click for settings"] = "Klicken für die Einstellungen"
L["Drag to move it round the minimap"] = "Ziehen verschiebt ihn um die Minikarte"

-- Settings
L["Changes save as you make them."] = "Änderungen werden sofort gespeichert."
L["Reload"] = "Neu laden"
L["Check"] = "Prüfen"
L["WINDOWS"] = "FENSTER"
L["ADVANCED"] = "ERWEITERT"
L["GENERAL"] = "ALLGEMEIN"
L["Or type /bpath settings, or click the minimap button."] =
    "Oder tippe /bpath settings, oder klicke auf den Minikartenknopf."
L["open the settings window"] = "öffnet das Einstellungsfenster"

-- The settings pages
L["Show descriptions"] = "Beschreibungen zeigen"
L["Find a setting"] = "Einstellung suchen"
L["Normal"] = "Normal"
L["Large"] = "Groß"
L["Larger"] = "Größer"

-- The taming tooltip

-- The house frame
L["Close"] = "Schließen"

-- UI/WhatsNew.lua (the same lines in every addon) and its Settings rows.
L["What's New"] = "Neuigkeiten"
L["BLACKTHORNES ADDONS"] = "BLACKTHORNES-ADDONS"
L["Here's what changed since you last played."] = "Das hat sich seit deinem letzten Spiel geändert."
L["The newest changes in each of your Blackthornes addons."] = "Die neuesten Änderungen in jedem deiner Blackthornes-Addons."
L["Show after updates"] = "Nach Updates zeigen"
L["Motion"] = "Bewegung"
L["Got it"] = "Alles klar"
L["there is no news to show yet."] = "es gibt noch keine Neuigkeiten."
L["open the What's New window for every Blackthornes addon"] = "öffnet das Neuigkeiten-Fenster für alle Blackthornes-Addons"

-- ======================================================================
-- Settings rows (the owner's walk-through, 2026-10-15)
L["On"] = "An"
L["Open"] = "Öffnen"
L["Window Position:"] = "Fensterposition:"
L["Reset the UI windows to their defaults."] = "Setzt die Fenster auf ihre Standardplätze zurück."
L["Set Default"] = "Zurücksetzen"
L["UI windows set to defaults."] = "Fenster auf ihre Standardplätze zurückgesetzt."
L["Text Size:"] = "Textgröße:"
L["Window Style:"] = "Fensterstil:"
L["Debug:"] = "Debug:"
L["Extra chat messages to help track down a problem."] = "Zusätzliche Chat-Nachrichten, um einem Problem auf die Spur zu kommen."
L["Sister Addons:"] = "Schwester-Addons:"
L["Says once in chat which Blackthornes addons you don't have."] = "Sagt einmal im Chat, welche Blackthornes-Addons dir fehlen."
L["What's New:"] = "Neuigkeiten:"
L["What's New After Updates:"] = "Neuigkeiten nach Updates:"
L["Opens What's New the first time you play after an update."] = "Öffnet die Neuigkeiten, wenn du nach einem Update zum ersten Mal spielst."
L["What's New Motion:"] = "Bewegung der Neuigkeiten:"
L["Client Check:"] = "Spiel prüfen:"
L["Window position, text size and debug output"] = "Fensterposition, Textgröße und Debug-Ausgabe"

-- About (UI/About.lua) and the note in What's New
-- ======================================================================
L["A few of you have asked if AI is used in the creation of my AddOns. It is."] = "Einige von euch haben gefragt, ob beim Erstellen meiner AddOns KI genutzt wird. Ja, das wird sie."
L["I've spent 25 years developing software and working in IT, and I recommend developers today use it, but with care and intention. For me that means I decide what gets built, I set the rules the code has to follow, I review the code, and I test changes in game myself. AI helps me write the code, run the tests and track down bugs."] = "Ich entwickle seit 25 Jahren Software und arbeite in der IT, und ich empfehle Entwicklern heute, KI zu nutzen, aber mit Sorgfalt und Absicht. Für mich heißt das: Ich entscheide, was gebaut wird, ich lege die Regeln fest, an die sich der Code halten muss, ich prüfe den Code, und ich teste Änderungen selbst im Spiel. KI hilft mir, den Code zu schreiben, die Tests laufen zu lassen und Fehler aufzuspüren."
L["Used well, it means more features, faster bug fixes and quicker turnaround on your requests. A lot of what's in these addons started as an idea or a bug report from a player."] = "Gut eingesetzt heißt das mehr Funktionen, schnellere Fehlerbehebungen und schnellere Umsetzung eurer Wünsche. Vieles in diesen Addons begann als Idee oder Fehlermeldung eines Spielers."
L["If you have an idea or something isn't working, come find me on my Discord at discord.gg/f2geDecrw2. I read every comment and report."] = "Wenn du eine Idee hast oder etwas nicht funktioniert, schau auf meinem Discord unter discord.gg/f2geDecrw2 vorbei. Ich lese jeden Kommentar und jede Meldung."
L["%s, version %s"] = "%s, Version %s"
L["DISCORD"] = "DISCORD"
L["Click the box, then press Ctrl+C to copy the link."] = "Klicke in das Feld und drücke Strg+C, um den Link zu kopieren."
L["REPORT A BUG"] = "FEHLER MELDEN"
L["Post it on my Discord with what you were doing when it happened. I read every comment and report."] = "Schreib es auf meinem Discord, mit dem, was du gerade gemacht hast, als es passiert ist. Ich lese jeden Kommentar und jede Meldung."
L["THANK YOU"] = "DANKE"
L["A lot of what's here started as a player's idea or bug report. Thank you to everyone who sent one in."] = "Vieles hier begann als Idee oder Fehlermeldung eines Spielers. Danke an alle, die eine geschickt haben."
L["installed"] = "installiert"
L["turned off"] = "ausgeschaltet"
L["not installed"] = "nicht installiert"
L["%s (%s)"] = "%s (%s)"
L["How these addons are made"] = "Wie diese Addons entstehen"
L["A note from Blackthornes."] = "Ein Hinweis von Blackthornes."
L["ABOUT"] = "ÜBER"
L["HOW THESE ADDONS ARE MADE"] = "WIE DIESE ADDONS ENTSTEHEN"
L["How these addons are made, the version, the Discord and the other Blackthornes addons"] = "Wie diese Addons entstehen, die Version, der Discord und die anderen Blackthornes-Addons"

-- Off, Shift or Always for a tooltip line (UI/TooltipShift.lua).

-- Pathfinder's own words.
L["Guide:"] = "Leitfaden:"
L["Level %d"] = "Stufe %d"
L["Lists in chat what the game tells Pathfinder about quests and travel."] = "Zeigt im Chat, was das Spiel Pathfinder über Quests und Reisen sagt."
L["Open Pathfinder settings"] = "Einstellungen von Pathfinder öffnen"
L["Pathfinder's settings have a window of their own."] = "Die Einstellungen von Pathfinder haben ein eigenes Fenster."
L["The guide isn't ready yet."] = "Der Leitfaden ist noch nicht fertig."
L["open the guide window (so does /bpath on its own)"] = "öffnet das Leitfadenfenster (wie /bpath allein)"
L["a step-by-step leveling guide"] = "ein Leitfaden zum Leveln, Schritt für Schritt"
