-- Blackthornes Pathfinder -- Locale/frFR.lua
-- French: the words players see, on a French client.
--
-- Each line is the English key (exactly as the code writes it) and its
-- French. A key with no line here shows in English. The French speaks to
-- the player as "tu" and uses the game's own words (quête, maître de
-- vol, pierre de foyer, maître, marchand, niveau, mètres). A line may
-- name its values by place ("%2$s ... %1$s") where French word order needs
-- it; L.Format puts them in order.
--
-- Quest, NPC, zone and item names stay as the data or the client gives
-- them. tools/check_locale.py lists keys with no line here and lines no
-- longer used.

local _, ns = ...
local L = ns.L

local ok, locale = pcall(function() return GetLocale() end)
if not (ok and locale == "frFR") then return end

-- Core
L["Saved for Claude, /reload to write it."] = "Gardé pour Claude, /reload pour l'écrire."
L["module %s:%s failed"] = "le module %s:%s a échoué"
L["show this list"] = "affiche cette liste"
L["unknown command: %s"] = "commande inconnue : %s"
L["/bpath %s failed: %s"] = "/bpath %s a échoué : %s"

-- The sister note
L["and"] = "et"
L["works with other Blackthornes addons you don't have yet: %s. %s on CurseForge."] = "marche avec d'autres addons Blackthornes que tu n'as pas encore : %s. %s sur CurseForge."
L["It's"] = "Tu le trouves"
L["They're"] = "Tu les trouves"
L["This note shows once."] = "Ce message ne s'affiche qu'une fois."
L["turn the once-only note about the other Blackthornes addons on or off"] =
    "active ou coupe le message unique sur les autres addons Blackthornes"
L["the note about the other Blackthornes addons is on. It shows once for any you don't have."] =
    "le message sur les autres addons Blackthornes est activé. Il s'affiche une fois pour chaque addon que tu n'as pas."
L["the note about the other Blackthornes addons is off, in all of them."] =
    "le message sur les autres addons Blackthornes est coupé, dans tous."
L["where to farm any material"] = "où farmer chaque matériau"
L["auction prices, crafting profits and a craft queue"] =
    "les prix de l'hôtel des ventes, les gains d'artisanat et une liste de fabrication"
L["which gear is an upgrade for you, and where to get it"] =
    "quel équipement est mieux pour toi, et où le trouver"
L["feeding and taming for hunter and warlock pets"] =
    "nourrir et apprivoiser les familiers des chasseurs et des démonistes"
L["what to do with every item in your bags"] = "quoi faire de chaque objet dans tes sacs"

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
L["Settings"] = "Options"
L["Also in %s"] = "Aussi dans %s"

-- The Feed buttons

-- The Pet care key

-- The pets window

-- The minimap button
L["Click to open"] = "Clique pour ouvrir"
L["Right-click for settings"] = "Clic droit pour les options"
L["Click for settings"] = "Clique pour les options"
L["Drag to move it round the minimap"] = "Fais-le glisser pour le déplacer autour de la minicarte"

-- Settings
L["Changes save as you make them."] = "Tes changements sont gardés tout de suite."
L["Reload"] = "Recharger"
L["Check"] = "Vérifier"
L["WINDOWS"] = "FENÊTRES"
L["ADVANCED"] = "AVANCÉ"
L["GENERAL"] = "GÉNÉRAL"
L["Or type /bpath settings, or click the minimap button."] =
    "Ou tape /bpath settings, ou clique sur le bouton de la minicarte."
L["open the settings window"] = "ouvre la fenêtre des options"

-- The settings pages
L["Show descriptions"] = "Afficher les descriptions"
L["Find a setting"] = "Chercher une option"
L["Normal"] = "Normal"
L["Large"] = "Grand"
L["Larger"] = "Plus grand"

-- The taming tooltip

-- The house frame
L["Close"] = "Fermer"

-- UI/WhatsNew.lua (the same lines in every addon) and its Settings rows.
L["What's New"] = "Nouveautés"
L["BLACKTHORNES ADDONS"] = "ADDONS BLACKTHORNES"
L["Here's what changed since you last played."] = "Voici ce qui a changé depuis ta dernière partie."
L["The newest changes in each of your Blackthornes addons."] = "Les derniers changements de chacun de tes addons Blackthornes."
L["Show after updates"] = "Afficher après les mises à jour"
L["Motion"] = "Animation"
L["Got it"] = "Compris"
L["there is no news to show yet."] = "il n'y a pas encore de nouveautés à montrer."
L["open the What's New window for every Blackthornes addon"] = "ouvre la fenêtre des nouveautés pour tous les addons Blackthornes"

-- ======================================================================
-- Settings rows (the owner's walk-through, 2026-10-15)
L["On"] = "Activé"
L["Open"] = "Ouvrir"
L["Window Position:"] = "Position des fenêtres :"
L["Reset the UI windows to their defaults."] = "Remet les fenêtres à leur place de départ."
L["Set Default"] = "Par défaut"
L["UI windows set to defaults."] = "Fenêtres remises à leur place de départ."
L["Text Size:"] = "Taille du texte :"
L["Window Style:"] = "Style des fenêtres :"
L["Debug:"] = "Débogage :"
L["Extra chat messages to help track down a problem."] = "Plus de messages dans la discussion pour aider à trouver un problème."
L["Sister Addons:"] = "Addons associés :"
L["Says once in chat which Blackthornes addons you don't have."] = "Dit une fois dans la discussion quels addons Blackthornes tu n'as pas."
L["What's New:"] = "Nouveautés :"
L["What's New After Updates:"] = "Nouveautés après les mises à jour :"
L["Opens What's New the first time you play after an update."] = "Ouvre les nouveautés la première fois que tu joues après une mise à jour."
L["What's New Motion:"] = "Animation des nouveautés :"
L["Client Check:"] = "Vérifier le jeu :"
L["Window position, text size and debug output"] = "Position des fenêtres, taille du texte et messages de débogage"

-- About (UI/About.lua) and the note in What's New
-- ======================================================================
L["A few of you have asked if AI is used in the creation of my AddOns. It is."] = "Certains d'entre vous m'ont demandé si l'IA sert à créer mes AddOns. Oui, elle sert."
L["I've spent 25 years developing software and working in IT, and I recommend developers today use it, but with care and intention. For me that means I decide what gets built, I set the rules the code has to follow, I review the code, and I test changes in game myself. AI helps me write the code, run the tests and track down bugs."] = "Je développe des logiciels et je travaille dans l'informatique depuis 25 ans, et je conseille aux développeurs d'aujourd'hui de s'en servir, mais avec soin et en sachant pourquoi. Pour moi, ça veut dire que je décide de ce qui est construit, je fixe les règles que le code doit suivre, je relis le code, et je teste moi-même les changements en jeu. L'IA m'aide à écrire le code, à lancer les tests et à trouver les bugs."
L["Used well, it means more features, faster bug fixes and quicker turnaround on your requests. A lot of what's in these addons started as an idea or a bug report from a player."] = "Bien utilisée, elle apporte plus de fonctions, des bugs corrigés plus vite et des réponses plus rapides à vos demandes. Une bonne partie de ces addons a commencé par une idée ou un rapport de bug d'un joueur."
L["If you have an idea or something isn't working, come find me on my Discord at discord.gg/f2geDecrw2. I read every comment and report."] = "Si tu as une idée ou si quelque chose ne marche pas, viens me voir sur mon Discord : discord.gg/f2geDecrw2. Je lis chaque commentaire et chaque rapport."
L["%s, version %s"] = "%s, version %s"
L["DISCORD"] = "DISCORD"
L["Click the box, then press Ctrl+C to copy the link."] = "Clique dans la case, puis appuie sur Ctrl+C pour copier le lien."
L["REPORT A BUG"] = "SIGNALER UN BUG"
L["Post it on my Discord with what you were doing when it happened. I read every comment and report."] = "Écris-le sur mon Discord, avec ce que tu faisais quand c'est arrivé. Je lis chaque commentaire et chaque rapport."
L["THANK YOU"] = "MERCI"
L["A lot of what's here started as a player's idea or bug report. Thank you to everyone who sent one in."] = "Une bonne partie de ce qui est ici a commencé par l'idée ou le rapport de bug d'un joueur. Merci à tous ceux qui en ont envoyé un."
L["installed"] = "installé"
L["turned off"] = "désactivé"
L["not installed"] = "pas installé"
L["%s (%s)"] = "%s (%s)"
L["How these addons are made"] = "Comment ces addons sont faits"
L["A note from Blackthornes."] = "Un mot de Blackthornes."
L["ABOUT"] = "À PROPOS"
L["HOW THESE ADDONS ARE MADE"] = "COMMENT CES ADDONS SONT FAITS"
L["How these addons are made, the version, the Discord and the other Blackthornes addons"] = "Comment ces addons sont faits, la version, le Discord et les autres addons Blackthornes"

-- Off, Shift or Always for a tooltip line (UI/TooltipShift.lua).

-- Pathfinder's own words.
L["Guide:"] = "Guide :"
L["Level %d"] = "Niveau %d"
L["Lists in chat what the game tells Pathfinder about quests and travel."] = "Affiche dans le chat ce que le jeu dit à Pathfinder sur les quêtes et les voyages."
L["Open Pathfinder settings"] = "Ouvrir les options de Pathfinder"
L["Pathfinder's settings have a window of their own."] = "Les options de Pathfinder ont leur propre fenêtre."
L["The guide isn't ready yet."] = "Le guide n'est pas encore prêt."
L["open the guide window (so does /bpath on its own)"] = "ouvre la fenêtre du guide (/bpath tout seul aussi)"
L["a step-by-step leveling guide"] = "un guide pour monter de niveau, étape par étape"
