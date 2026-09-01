local colorSchemes = require("./colorSchemes")

local Theme = {}

Theme.JSON = {
	["dark"] = {
		["mPrimary"] = "",
		["mOnPrimary"] = "",
		["mSecondary"] = "",
		["mOnSecondary"] = "",
		["mTertiary"] = "",
		["mOnTertiary"] = "",
		["mError"] = "",
		["mOnError"] = "",
		["mSurface"] = "",
		["mOnSurface"] = "",
		["mSurfaceVariant"] = "",
		["mOnSurfaceVariant"] = "",
		["mOutline"] = "",
		["mShadow"] = "",
		["mHover"] = "",
		["mOnHover"] = "",
		["terminal"] = {
			["foreground"] = "",
			["background"] = "",
			["normal"] = {
				["black"] = "",
				["red"] = "",
				["green"] = "",
				["yellow"] = "",
				["blue"] = "",
				["magenta"] = "",
				["cyan"] = "",
				["white"] = "",
			},
			["bright"] = {
				["black"] = "",
				["red"] = "",
				["green"] = "",
				["yellow"] = "",
				["blue"] = "",
				["magenta"] = "",
				["cyan"] = "",
				["white"] = "",
			},
			["cursor"] = "",
			["cursorText"] = "",
			["selectionFg"] = "",
			["selectionBg"] = "",
		},
	},
	["light"] = {
		["mPrimary"] = "",
		["mOnPrimary"] = "",
		["mSecondary"] = "",
		["mOnSecondary"] = "",
		["mTertiary"] = "",
		["mOnTertiary"] = "",
		["mError"] = "",
		["mOnError"] = "",
		["mSurface"] = "",
		["mOnSurface"] = "",
		["mSurfaceVariant"] = "",
		["mOnSurfaceVariant"] = "",
		["mOutline"] = "",
		["mShadow"] = "",
		["mHover"] = "",
		["mOnHover"] = "",
		["terminal"] = {
			["foreground"] = "",
			["background"] = "",
			["normal"] = {
				["black"] = "",
				["red"] = "",
				["green"] = "",
				["yellow"] = "",
				["blue"] = "",
				["magenta"] = "",
				["cyan"] = "",
				["white"] = "",
			},
			["bright"] = {
				["black"] = "",
				["red"] = "",
				["green"] = "",
				["yellow"] = "",
				["blue"] = "",
				["magenta"] = "",
				["cyan"] = "",
				["white"] = "",
			},
			["cursor"] = "",
			["cursorText"] = "",
			["selectionFg"] = "",
			["selectionBg"] = "",
		},
	},
}

Theme.Selection = {
	Theme = { Name = "", Index = 0 },
	ThemeBase = { Name = "", Index = 0 },
	Accents = {
		["Primary"] = { Name = "", Index = 0 },
		["Secondary"] = { Name = "", Index = 0 },
		["Tertiary"] = { Name = "", Index = 0 },
		["Error"] = { Name = "", Index = 0 },
	},
}

Theme.Array = {
	ThemeNames = {},
	ThemeBases = {},
	Accents = {},
}

function Theme.MakeFile()
	local themeFile = Theme.JSON

	local themeName = Theme.Selection.Theme.Name
	local themeBase = Theme.Selection.ThemeBase.Name

	local baseColors = colorSchemes[themeName][themeBase].Base
	local lightBaseColors = colorSchemes[themeBase].Light.Base

	local accentColorsList = colorSchemes[themeName][themeBase].Accents
	local lightAccentsColorsList = colorSchemes[themeName].Light.Accents

	local termColors = colorSchemes[themeName][themeBase].Terminal
	local lightTermColors = colorSchemes[themeName].Light.Terminal

	for k, v in baseColors do
		themeFile.dark[k] = v
	end
	for k, v in lightBaseColors do
		themeFile.light[k] = v
	end

	for k, v in termColors do
		themeFile.dark.terminal[k] = v
	end

	for k, v in lightTermColors do
		themeFile.light.terminal[k] = v
	end

	for k, v in Theme.Selection.accents do
		local color = accentColorsList[Theme.Selection.accents[k].name]
		themeFile.dark[`m{k}`] = color
	end

	for k, v in Theme.Selection.accents do
		local color = lightAccentsColorsList[Theme.Selection.accents[k].name]
		themeFile.light[`m{k}`] = color
	end

	themeFile.dark.terminal.cursor = themeFile.dark.mPrimary
	themeFile.light.terminal.cursor = themeFile.light.mPrimary

	return themeFile
end

function Theme.Get()
	local saveDir = noctalia.pluginDataDir()
	local savePath = saveDir .. "/data.json"

	local rawFile, err = noctalia.readFile(savePath)

	if not rawFile then
		noctalia.notifyError("Failed to retreive theme settings", err)
		return
	end

	-- noctalia.notify("Save json:", rawFile)
	local saveTable, err = noctalia.json.decode(rawFile)

	if not saveTable then
		noctalia.notifyError("Failed to retreive theme settings", err)
		return
	end

	return saveTable
end

function Theme.Reset(index: number, themeName: string)
	Theme.Selection.Theme.Index = index
	Theme.Selection.Theme.Name = themeName

	Theme.Array.ThemeBases = {}

	for colorSchemeBaseName, colorSchemeVariant in colorSchemes[themeName] do
		if colorSchemeBaseName == "Light" then
			continue
		end

		table.insert(Theme.Array.ThemeBases, colorSchemeBaseName)
	end

	Theme.Selection.ThemeBase.Index = 0
	local themeBaseName = Theme.Array.ThemeBases[1]

	Theme.Selection.ThemeBase.Name = themeBaseName

	Theme.Array.Accents = {}
	for colorSchemeAccentName, colorSchemeAccent in colorSchemes[themeName][themeBaseName].Accents do
		table.insert(Theme.Array.Accents, colorSchemeAccentName)
	end

	for k, v in Theme.Selection.accents do
		Theme.Selection.accents[k].Index = 0
		Theme.Selection.accents[k].name = Theme.Array.Accents[1]
	end
end

return Theme
