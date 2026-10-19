-- Blackthornes Pathfinder -- Locale/esES.lua
-- Spanish: the words players see, on a Spanish client (Spain or Latin America).
--
-- Each line is the English key (exactly as the code writes it) and its
-- Spanish. A key with no line here shows in English. The Spanish uses the
-- game's own words (misión, maestro de vuelo, piedra de hogar,
-- instructor, vendedor, nivel, metros) and "tú", so it reads well in Spain and Latin
-- America alike. A line may name its values by place ("%2$s ... %1$s")
-- where Spanish word order needs it; L.Format puts them in order.
--
-- Quest, NPC, zone and item names stay as the data or the client gives
-- them. tools/check_locale.py lists keys with no line here and lines no
-- longer used.

local _, ns = ...
local L = ns.L

local ok, locale = pcall(function() return GetLocale() end)
if not (ok and (locale == "esES" or locale == "esMX")) then return end

-- Core
L["Saved for Claude, /reload to write it."] = "Guardado para Claude, usa /reload para escribirlo."
L["module %s:%s failed"] = "el módulo %s:%s falló"
L["show this list"] = "muestra esta lista"
L["unknown command: %s"] = "comando desconocido: %s"
L["/bpath %s failed: %s"] = "/bpath %s falló: %s"

-- The sister note
L["and"] = "y"
L["works with other Blackthornes addons you don't have yet: %s. %s on CurseForge."] = "funciona con otros addons de Blackthornes que aún no tienes: %s. %s en CurseForge."
L["It's"] = "Lo encuentras"
L["They're"] = "Los encuentras"
L["This note shows once."] = "Este aviso sale solo una vez."
L["turn the once-only note about the other Blackthornes addons on or off"] =
    "activa o desactiva el aviso único sobre los otros addons de Blackthornes"
L["the note about the other Blackthornes addons is on. It shows once for any you don't have."] =
    "el aviso sobre los otros addons de Blackthornes está activado. Sale una vez por cada uno que no tengas."
L["the note about the other Blackthornes addons is off, in all of them."] =
    "el aviso sobre los otros addons de Blackthornes está desactivado en todos ellos."
L["where to farm any material"] = "dónde conseguir cualquier material"
L["auction prices, crafting profits and a craft queue"] =
    "precios de subasta, ganancias de fabricación y una cola de fabricación"
L["which gear is an upgrade for you, and where to get it"] =
    "qué equipo es una mejora para ti y dónde conseguirlo"
L["feeding and taming for hunter and warlock pets"] =
    "alimentar y domesticar mascotas de cazador y brujo"
L["what to do with every item in your bags"] = "qué hacer con cada objeto de tus bolsas"

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
L["Settings"] = "Configuración"
L["Also in %s"] = "También en %s"

-- The Feed buttons

-- The Pet care key

-- The pets window

-- The minimap button
L["Click to open"] = "Haz clic para abrir"
L["Right-click for settings"] = "Clic derecho para la configuración"
L["Click for settings"] = "Haz clic para la configuración"
L["Drag to move it round the minimap"] = "Arrastra para moverlo alrededor del minimapa"

-- Settings
L["Changes save as you make them."] = "Los cambios se guardan al hacerlos."
L["Reload"] = "Recargar"
L["Check"] = "Revisar"
L["WINDOWS"] = "VENTANAS"
L["ADVANCED"] = "AVANZADO"
L["GENERAL"] = "GENERAL"
L["Or type /bpath settings, or click the minimap button."] =
    "O escribe /bpath settings, o haz clic en el botón del minimapa."
L["open the settings window"] = "abre la ventana de configuración"

-- The settings pages
L["Show descriptions"] = "Mostrar descripciones"
L["Find a setting"] = "Buscar una opción"
L["Normal"] = "Normal"
L["Large"] = "Grande"
L["Larger"] = "Más grande"

-- The taming tooltip

-- The house frame
L["Close"] = "Cerrar"

-- UI/WhatsNew.lua (the same lines in every addon) and its Settings rows.
L["What's New"] = "Novedades"
L["BLACKTHORNES ADDONS"] = "ADDONS DE BLACKTHORNES"
L["Here's what changed since you last played."] = "Esto es lo que cambió desde la última vez que jugaste."
L["The newest changes in each of your Blackthornes addons."] = "Los cambios más nuevos de cada uno de tus addons de Blackthornes."
L["Show after updates"] = "Mostrar tras actualizar"
L["Motion"] = "Animación"
L["Got it"] = "Entendido"
L["there is no news to show yet."] = "aún no hay novedades que mostrar."
L["open the What's New window for every Blackthornes addon"] = "abre la ventana de Novedades de todos los addons de Blackthornes"

-- ======================================================================
-- Settings rows
L["On"] = "Activar"
L["Open"] = "Abrir"
L["Window Position:"] = "Posición de ventanas:"
L["Reset the UI windows to their defaults."] = "Devuelve las ventanas a su sitio de inicio."
L["Set Default"] = "Restablecer"
L["UI windows set to defaults."] = "Ventanas devueltas a su sitio de inicio."
L["Text Size:"] = "Tamaño de texto:"
L["Window Style:"] = "Estilo de ventana:"
L["Debug:"] = "Depuración:"
L["Extra chat messages to help track down a problem."] = "Mensajes extra en el chat para ayudar a encontrar un problema."
L["Sister Addons:"] = "Addons hermanos:"
L["Says once in chat which Blackthornes addons you don't have."] = "Dice una vez en el chat qué addons de Blackthornes no tienes."
L["What's New:"] = "Novedades:"
L["What's New After Updates:"] = "Novedades tras actualizar:"
L["Opens What's New the first time you play after an update."] = "Abre Novedades la primera vez que juegas tras una actualización."
L["What's New Motion:"] = "Animación de Novedades:"
L["Client Check:"] = "Revisión del juego:"
L["Window position, text size and debug output"] = "Posición de ventanas, tamaño de texto y mensajes de depuración"

-- About (UI/About.lua) and the note in What's New
-- ======================================================================
L["A few of you have asked if AI is used in the creation of my AddOns. It is."] = "Algunos me han preguntado si uso IA para crear mis AddOns. Sí, la uso."
L["I've spent 25 years developing software and working in IT, and I recommend developers today use it, but with care and intention. For me that means I decide what gets built, I set the rules the code has to follow, I review the code, and I test changes in game myself. AI helps me write the code, run the tests and track down bugs."] = "Llevo 25 años creando software y trabajando en informática, y recomiendo a los desarrolladores de hoy que la usen, pero con cuidado y con intención. Para mí eso significa que yo decido qué se crea, yo pongo las reglas que el código tiene que seguir, yo reviso el código y yo mismo pruebo los cambios en el juego. La IA me ayuda a escribir el código, pasar las pruebas y encontrar errores."
L["Used well, it means more features, faster bug fixes and quicker turnaround on your requests. A lot of what's in these addons started as an idea or a bug report from a player."] = "Bien usada, significa más funciones, errores arreglados antes y respuestas más rápidas a lo que pides. Mucho de lo que hay en estos addons empezó como una idea o un aviso de error de un jugador."
L["If you have an idea or something isn't working, come find me on my Discord at discord.gg/f2geDecrw2. I read every comment and report."] = "Si tienes una idea o algo no funciona, búscame en mi Discord: discord.gg/f2geDecrw2. Leo cada comentario y cada aviso."
L["%s, version %s"] = "%s, versión %s"
L["DISCORD"] = "DISCORD"
L["Click the box, then press Ctrl+C to copy the link."] = "Haz clic en el recuadro y pulsa Ctrl+C para copiar el enlace."
L["REPORT A BUG"] = "AVISAR DE UN ERROR"
L["Post it on my Discord with what you were doing when it happened. I read every comment and report."] = "Escríbelo en mi Discord y cuenta qué hacías cuando pasó. Leo cada comentario y cada aviso."
L["THANK YOU"] = "GRACIAS"
L["A lot of what's here started as a player's idea or bug report. Thank you to everyone who sent one in."] = "Mucho de lo que hay aquí empezó como la idea o el aviso de error de un jugador. Gracias a todos los que mandaron uno."
L["installed"] = "instalado"
L["turned off"] = "desactivado"
L["not installed"] = "no instalado"
L["%s (%s)"] = "%s (%s)"
L["How these addons are made"] = "Cómo se hacen estos addons"
L["A note from Blackthornes."] = "Unas palabras de Blackthornes."
L["ABOUT"] = "ACERCA DE"
L["HOW THESE ADDONS ARE MADE"] = "CÓMO SE HACEN ESTOS ADDONS"
L["How these addons are made, the version, the Discord and the other Blackthornes addons"] = "Cómo se hacen estos addons, la versión, el Discord y los otros addons de Blackthornes"

-- Off, Shift or Always for a tooltip line (UI/TooltipShift.lua).

-- Pathfinder's own words.
L["Guide:"] = "Guía:"
L["Level %d"] = "Nivel %d"
L["Lists in chat what the game tells Pathfinder about quests and travel."] = "Muestra en el chat lo que el juego le dice a Pathfinder sobre misiones y viajes."
L["Open Pathfinder settings"] = "Abrir configuración de Pathfinder"
L["Pathfinder's settings have a window of their own."] = "La configuración de Pathfinder tiene su propia ventana."
L["The guide isn't ready yet."] = "La guía aún no está lista."
L["open the guide window (so does /bpath on its own)"] = "abre la ventana de la guía (también /bpath solo)"
L["a step-by-step leveling guide"] = "una guía para subir de nivel paso a paso"
