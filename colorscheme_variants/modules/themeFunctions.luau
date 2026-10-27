export type themeSelection = {
	theme: { name: string, index: number },
	themeBase: { name: string, index: number },
	accents: {
		["Primary"]: { name: string, index: number },
		["Secondary"]: { name: string, index: number },
		["Tertiary"]: { name: string, index: number },
		["Error"]: { name: string, index: number },
	},
}

local function length(t: { [any]: any })
	local n = 0

	for _ in t do
		n += 1
	end

	return n
end

local colorSchemes = require("./colorSchemes.luau")

local Theme = {}

Theme.ThemeNames = {}
Theme.Dir = "~/.config/noctalia/palettes"

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

function Theme.MakeFile(themeSelection: themeSelection)
	local themeFile = Theme.JSON

	local themeName = themeSelection.theme.name
	local themeBase = themeSelection.themeBase.name

	local baseColors = colorSchemes[themeName][themeBase].Base
	local lightBaseColors = colorSchemes[themeName].Light.Base

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

	for k, v in themeSelection.accents do
		local color = accentColorsList[themeSelection.accents[k].name]
		themeFile.dark[`m{k}`] = color
	end

	for k, v in themeSelection.accents do
		local color = lightAccentsColorsList[themeSelection.accents[k].name]
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

function Theme.Array(themeSelection: themeSelection)
	local array = {}

	array.bases = {}
	for colorSchemeBaseName: string, colorSchemeVariant in colorSchemes[themeSelection.theme.name] do
		if colorSchemeBaseName == "Light" then
			continue
		end

		table.insert(array.bases, colorSchemeBaseName)
	end

	if themeSelection.themeBase.name == "" then
		return array
	end

	array.accents = {}
	for colorSchemeAccentName: string, colorSchemeAccent: string in
		colorSchemes[themeSelection.theme.name][themeSelection.themeBase.name].Accents
	do
		table.insert(array.accents, colorSchemeAccentName)
	end

	return array
end

function Theme.RandomSelection(index: number, themeName: string): themeSelection
	local themeSelection: themeSelection = {
		theme = { name = themeName, index = index },
		themeBase = { name = "", index = 0 },
		accents = {
			["Primary"] = { name = "", index = 0 },
			["Secondary"] = { name = "", index = 0 },
			["Tertiary"] = { name = "", index = 0 },
			["Error"] = { name = "", index = 0 },
		},
	}

	local themeBaseIndex = math.random(1, #Theme.Array(themeSelection).bases)
	themeSelection.themeBase.index = themeBaseIndex - 1
	local themeBaseName = Theme.Array(themeSelection).bases[themeBaseIndex]
	themeSelection.themeBase.name = themeBaseName

	for accentType in themeSelection.accents do
		local accentIndex = math.random(1, #Theme.Array(themeSelection).accents)
		themeSelection.accents[accentType].Index = accentIndex - 1
		themeSelection.accents[accentType].name = Theme.Array(themeSelection).accents[accentIndex]
	end

	return themeSelection
end

function Theme.Apply(themeSelection)
	local success, err = noctalia.mkdirAll(Theme.Dir)
	if not success then
		noctalia.notifyError("Failed to create theme dir", err)
	end

	local path = Theme.Dir .. "/custom.json"

	local saveDir = noctalia.pluginDataDir()
	local savePath = saveDir .. "/data.json"

	local saveJson, err = noctalia.json.encode(themeSelection, true)
	if not saveJson then
		noctalia.notifyError("Failed to save theme settings", err)

		return
	end

	noctalia.writeFile(savePath, saveJson)

	local themeJson, err = noctalia.json.encode(Theme.MakeFile(themeSelection), true)
	if not themeJson then
		noctalia.notifyError("Failed to change theme", err)

		return
	end

	-- noctalia.notify("Theme json:", themeJson)
	noctalia.writeFile(path, themeJson)

	noctalia.runAsync("noctalia msg color-scheme-set custom custom")
end

function Theme.AccentTable(themeSelection: themeSelection)
	local t = {}

	for k, v in themeSelection.accents do
		local themeName = themeSelection.theme.name
		local themeBaseName = themeSelection.themeBase.name

		local accentHex = colorSchemes[themeName][themeBaseName].Accents[v.name]

		t[k] = accentHex
	end

	return t
end

for colorSchemeName, colorScheme in colorSchemes do
	table.insert(Theme.ThemeNames, colorSchemeName)
end

return Theme
