--!nonstrict
-- Reference [[panel]] entry — a settings-style panel of interactive controls.
--
-- Panels describe their UI declaratively, exactly like desktop widgets: build a
-- tree with the ui.* constructors and hand it to panel.render(). The host diffs
-- the tree against the previous one and updates retained native controls, so
-- rendering an unchanged tree is free.
--
--   panel.render(tree)              replace the panel's UI tree
--   panel.close()                   ask the host to close this panel
--   noctalia.getConfig(key)         settings (seeded from the manifest)
--   noctalia.openColorPicker(...)   open the native color picker asynchronously
--   button/toggle/slider/...        onClick / onChange accept a closure or the
--                                   name of a plugin global; values arrive as
--                                   string args
--
-- Layout notes:
--   * a Flex (column/row/scroll) centers its children on the cross axis by
--     default — pass align = "stretch" so controls fill the panel width.
--   * panel size is host-owned: declare width/height on the [[panel]] manifest
--     entry, so the surface is the same size on every open.
--
-- Stateful controls follow a controlled/uncontrolled split:
--   * toggle / slider / select are value-driven — pass the current value each
--     render; the callback reports the user's new value.
--   * input is uncontrolled — `value` seeds the field once; the host owns the
--     text buffer afterward, so re-rendering never clobbers what the user typed.
--     Observe edits via onChange (live) / onSubmit (Enter).

local colorSchemes = require("./modules/colorSchemes")

local Theme = require("./modules/themeFunctions")

-- -- A labelled section: a heading above a control. ui.column stretches children to
-- -- the panel width by default, so the control fills the row.
local function section(title, control)
	return ui.column({ gap = 8 }, {
		ui.label({ text = title, fontWeight = "medium", color = "on_surface_variant" }),
		control,
	})
end

for colorSchemeName, colorScheme in colorSchemes do
	table.insert(Theme.Array.ThemeNames, colorSchemeName)
end

local function accentPicker(accentType: string, onChangeFunc: string)
	local accentColorName = Theme.Selection.Accents[accentType].Name
	local accentIndex = Theme.Selection.Accents[accentType].Index

	local accentColorHex =
		colorSchemes[Theme.Selection.Theme.Name][Theme.Selection.ThemeBase.Name].Accents[accentColorName]

	return ui.row({ gap = 12, align = "center" }, {
		ui.label({ text = `{accentType}:`, color = "on_surface", flexGrow = 1 }),
		ui.select({ options = Theme.Array.Accents, index = accentIndex, onChange = onChangeFunc }),
		ui.box({ width = 32, height = 32, radius = 8, fill = accentColorHex, border = "outline", borderWidth = 1 }),
	})
end

local function render()
	-- The panel surface already insets its content (Style::panelPadding), so this
	-- adds gaps between rows, not its own outer padding.

	if Theme.Selection.Theme.Name == "" then
		local saveTable = Theme.Get()
		if saveTable then
			Theme.Selection = saveTable
		else
			Theme.Reset(0, "Catppuccin")
		end

		Theme.Array.ThemeBases = {}
		for colorSchemeBaseName, colorSchemeVariant in colorSchemes[Theme.Selection.Theme.Name] do
			if colorSchemeBaseName == "Light" then
				continue
			end

			table.insert(Theme.Array.ThemeBases, colorSchemeBaseName)
		end

		Theme.Array.Accents = {}
		for colorSchemeAccentName, colorSchemeAccent in
			colorSchemes[Theme.Selection.Theme.Name][Theme.Selection.ThemeBase.Name].Accents
		do
			table.insert(Theme.Array.Accents, colorSchemeAccentName)
		end
	end

	panel.render(ui.column({ flexGrow = 1, gap = 16 }, {
		-- Header: title on the left, close button pinned to the top right —
		-- matching the built-in panels (no divider rule).
		ui.row({ align = "center", justify = "space_between", gap = 8 }, {
			ui.label({ text = "Color Scheme", fontSize = 16, fontWeight = "bold", color = "on_surface", flexGrow = 1 }),
			ui.button({ glyph = "close", onClick = "onCloseClicked" }),
		}),

		section(
			"ColorScheme",
			ui.row({ gap = 12, align = "center" }, {
				ui.select({
					options = Theme.Array.ThemeNames,
					selectedIndex = Theme.Selection.Theme.Index,
					onChange = "onColorSchemeSelected",
				}), -- theme
				ui.select({
					options = Theme.Array.ThemeBases,
					selectedIndex = Theme.Selection.ThemeBase.Index,
					onChange = "onColorSchemeBaseSelected",
				}), -- base
			})
		),

		section(
			"Accents",
			ui.column({ gap = 8 }, {
				accentPicker("Primary", "onPrimaryAccentColorSelected"),
				accentPicker("Secondary", "onSecondaryAccentColorSelected"),
				accentPicker("Tertiary", "onTertiaryAccentColorSelected"),
				accentPicker("Error", "onErrorAccentColorSelected"),
			})
		),
		ui.button({ glyph = "palette", text = "Apply Color Scheme", onClick = "onApplyClicked" }),
	}))
end

function onOpen(_context)
	render()
end

function onColorSchemeSelected(index, text)
	Theme.Reset(index, text)

	render()
end

function onColorSchemeBaseSelected(index, text)
	Theme.Selection.ThemeBase.Index = index
	Theme.Selection.ThemeBase.Name = text

	Theme.Array.Accents = {}
	for colorSchemeAccentName, colorSchemeAccent in
		colorSchemes[Theme.Selection.Theme.Name][Theme.Selection.ThemeBase.name].Accents
	do
		table.insert(Theme.Array.Accents, colorSchemeAccentName)
	end

	render()
end

function onPrimaryAccentColorSelected(index, text)
	Theme.Selection.Accents.Primary.Name = text
	Theme.Selection.Accents.Primary.Index = index

	render()
end

function onSecondaryAccentColorSelected(index, text)
	Theme.Selection.Accents.Secondary.Name = text
	Theme.Selection.Accents.Secondary.Index = index

	render()
end

function onTertiaryAccentColorSelected(index, text)
	Theme.Selection.Accents.Tertiary.Name = text
	Theme.Selection.Accents.Tertiary.Index = index

	render()
end

function onErrorAccentColorSelected(index, text)
	Theme.Selection.Accents.Error.Name = text
	Theme.Selection.Accents.Error.Index = index

	render()
end

function onApplyClicked()
	local themeDir = "~/.config/noctalia/palettes"
	local success, err = noctalia.mkdirAll(themeDir)
	if not success then
		noctalia.notifyError("Failed to create theme dir", err)
	end

	local path = themeDir .. "/custom.json"

	local saveDir = noctalia.pluginDataDir()
	local savePath = saveDir .. "/data.json"

	local saveJson, err = noctalia.json.encode(Theme.Selection, true)
	if not saveJson then
		noctalia.notifyError("Failed to save theme settings", err)

		return
	end

	noctalia.writeFile(savePath, saveJson)

	local themeJson, err = noctalia.json.encode(Theme.MakeFile(), true)
	if not themeJson then
		noctalia.notifyError("Failed to change theme", err)

		return
	end

	-- noctalia.notify("Theme json:", themeJson)
	noctalia.writeFile(path, themeJson)

	noctalia.runAsync("noctalia msg color-scheme-set custom custom")
end

function onCloseClicked()
	panel.close()
end

function update()
	render()
end
