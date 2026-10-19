-- Blackthornes Pathfinder -- Locale/zhCN.lua
-- Simplified Chinese: the words players see, on a Simplified Chinese client.
--
-- Each line is the English key (exactly as the code writes it) and its
-- Chinese. A key with no line here shows in English. The Chinese uses the
-- game's own words (任务, 飞行管理员, 炉石, 训练师, 商人, 等级, 码). A line may name
-- its values by place ("%2$s ... %1$s") where Chinese word order needs it;
-- L.Format puts them in order.
--
-- Quest, NPC, zone and item names stay as the data or the client gives
-- them. tools/check_locale.py lists keys with no line here and lines no
-- longer used.

local _, ns = ...
local L = ns.L

local ok, locale = pcall(function() return GetLocale() end)
if not (ok and locale == "zhCN") then return end

-- Core
L["Saved for Claude, /reload to write it."] = "已为 Claude 保存，输入 /reload 写入。"
L["module %s:%s failed"] = "模块 %s:%s 出错"
L["show this list"] = "显示这个列表"
L["unknown command: %s"] = "未知命令：%s"
L["/bpath %s failed: %s"] = "/bpath %s 出错：%s"

-- The sister note
L["and"] = "和"
L["works with other Blackthornes addons you don't have yet: %s. %s on CurseForge."] = "可以和你还没有的其他 Blackthornes 插件一起使用：%s。%s 在 CurseForge 上。"
L["It's"] = "它"
L["They're"] = "它们都"
L["This note shows once."] = "这条提示只显示一次。"
L["turn the once-only note about the other Blackthornes addons on or off"] =
    "打开或关闭关于其他 Blackthornes 插件的一次性提示"
L["the note about the other Blackthornes addons is on. It shows once for any you don't have."] =
    "关于其他 Blackthornes 插件的提示已打开。你还没有的插件，每个只提示一次。"
L["the note about the other Blackthornes addons is off, in all of them."] =
    "关于其他 Blackthornes 插件的提示已在所有插件中关闭。"
L["where to farm any material"] = "去哪里刷任何材料"
L["auction prices, crafting profits and a craft queue"] =
    "拍卖价格、制造利润和制造队列"
L["which gear is an upgrade for you, and where to get it"] =
    "哪些装备对你是升级，以及去哪里拿到"
L["feeding and taming for hunter and warlock pets"] =
    "猎人和术士宠物的喂食与驯服"
L["what to do with every item in your bags"] = "背包里每样物品该怎么处理"

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
L["Settings"] = "设置"
L["Also in %s"] = "也在%s"

-- The Feed buttons

-- The Pet care key

-- The pets window

-- The minimap button
L["Click to open"] = "点击打开"
L["Right-click for settings"] = "右键点击打开设置"
L["Click for settings"] = "点击打开设置"
L["Drag to move it round the minimap"] = "拖动可以绕着小地图移动它"

-- Settings
L["Changes save as you make them."] = "改动会马上保存。"
L["Reload"] = "重新加载"
L["Check"] = "检查"
L["WINDOWS"] = "窗口"
L["ADVANCED"] = "高级"
L["GENERAL"] = "常规"
L["Or type /bpath settings, or click the minimap button."] =
    "也可以输入 /bpath settings，或点击小地图按钮。"
L["open the settings window"] = "打开设置窗口"

-- The settings pages
L["Show descriptions"] = "显示说明"
L["Find a setting"] = "查找设置"
L["Normal"] = "正常"
L["Large"] = "大"
L["Larger"] = "更大"

-- The taming tooltip

-- The house frame
L["Close"] = "关闭"

-- UI/WhatsNew.lua (the same lines in every addon) and its Settings rows.
L["What's New"] = "更新内容"
L["BLACKTHORNES ADDONS"] = "BLACKTHORNES 插件"
L["Here's what changed since you last played."] = "这是你上次玩之后的改动。"
L["The newest changes in each of your Blackthornes addons."] = "你每个 Blackthornes 插件的最新改动。"
L["Show after updates"] = "更新后显示"
L["Motion"] = "动画"
L["Got it"] = "知道了"
L["there is no news to show yet."] = "还没有可以显示的更新。"
L["open the What's New window for every Blackthornes addon"] = "打开所有 Blackthornes 插件的更新内容窗口"

-- ======================================================================
-- Settings rows
L["On"] = "开启"
L["Open"] = "打开"
L["Window Position:"] = "窗口位置："
L["Reset the UI windows to their defaults."] = "把窗口放回默认位置。"
L["Set Default"] = "恢复默认"
L["UI windows set to defaults."] = "窗口已放回默认位置。"
L["Text Size:"] = "文字大小："
L["Window Style:"] = "窗口样式："
L["Debug:"] = "调试："
L["Extra chat messages to help track down a problem."] = "额外的聊天信息，帮忙找出问题。"
L["Sister Addons:"] = "姊妹插件："
L["Says once in chat which Blackthornes addons you don't have."] = "在聊天框说一次你还没有哪些 Blackthornes 插件。"
L["What's New:"] = "更新内容："
L["What's New After Updates:"] = "更新后显示更新内容："
L["Opens What's New the first time you play after an update."] = "更新后第一次玩时打开更新内容。"
L["What's New Motion:"] = "更新内容动画："
L["Client Check:"] = "游戏检查："
L["Window position, text size and debug output"] = "窗口位置、文字大小和调试信息"

-- About (UI/About.lua) and the note in What's New
-- ======================================================================
L["A few of you have asked if AI is used in the creation of my AddOns. It is."] = "有些朋友问我做插件时有没有用 AI。是的，有用。"
L["I've spent 25 years developing software and working in IT, and I recommend developers today use it, but with care and intention. For me that means I decide what gets built, I set the rules the code has to follow, I review the code, and I test changes in game myself. AI helps me write the code, run the tests and track down bugs."] = "我做软件开发和 IT 工作已经 25 年了，我建议现在的开发者使用 AI，但要用心、有目的地用。对我来说，这意味着由我决定做什么，由我定下代码必须遵守的规则，由我检查代码，也由我亲自在游戏里测试改动。AI 帮我写代码、跑测试和找出 bug。"
L["Used well, it means more features, faster bug fixes and quicker turnaround on your requests. A lot of what's in these addons started as an idea or a bug report from a player."] = "用得好，就能有更多功能、更快修好 bug，也能更快完成你们的请求。这些插件里很多东西，最早都来自玩家的一个想法或一份 bug 报告。"
L["If you have an idea or something isn't working, come find me on my Discord at discord.gg/f2geDecrw2. I read every comment and report."] = "如果你有想法，或者有东西不好用，来我的 Discord 找我：discord.gg/f2geDecrw2。每条留言和报告我都会看。"
L["%s, version %s"] = "%s，版本 %s"
L["DISCORD"] = "DISCORD"
L["Click the box, then press Ctrl+C to copy the link."] = "点击方框，然后按 Ctrl+C 复制链接。"
L["REPORT A BUG"] = "报告 BUG"
L["Post it on my Discord with what you were doing when it happened. I read every comment and report."] = "在我的 Discord 上发出来，说说出问题时你在做什么。每条留言和报告我都会看。"
L["THANK YOU"] = "谢谢"
L["A lot of what's here started as a player's idea or bug report. Thank you to everyone who sent one in."] = "这里很多东西最早都来自玩家的想法或 bug 报告。谢谢每一位发来的朋友。"
L["installed"] = "已安装"
L["turned off"] = "已关闭"
L["not installed"] = "未安装"
L["%s (%s)"] = "%s（%s）"
L["How these addons are made"] = "这些插件是怎么做的"
L["A note from Blackthornes."] = "来自 Blackthornes 的一段话。"
L["ABOUT"] = "关于"
L["HOW THESE ADDONS ARE MADE"] = "这些插件是怎么做的"
L["How these addons are made, the version, the Discord and the other Blackthornes addons"] = "这些插件是怎么做的、版本、Discord 和其他 Blackthornes 插件"

-- Off, Shift or Always for a tooltip line (UI/TooltipShift.lua).

-- Pathfinder's own words.
L["Guide:"] = "指南："
L["Level %d"] = "等级 %d"
L["Lists in chat what the game tells Pathfinder about quests and travel."] = "在聊天中列出游戏告诉 Pathfinder 的任务和旅行信息。"
L["Open Pathfinder settings"] = "打开 Pathfinder 设置"
L["Pathfinder's settings have a window of their own."] = "Pathfinder 的设置有自己的窗口。"
L["The guide isn't ready yet."] = "指南还没有准备好。"
L["open the guide window (so does /bpath on its own)"] = "打开指南窗口（只输入 /bpath 也可以）"
L["a step-by-step leveling guide"] = "一步一步的升级指南"
