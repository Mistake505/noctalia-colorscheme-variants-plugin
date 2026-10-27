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

local colorSchemes = require("./modules/colorSchemes.luau")

local Theme = require("./modules/themeFunctions.luau")

local themeSelection = Theme.RandomSelection(0, "Catppuccin")

-- -- A labelled section: a heading above a control. ui.column stretches children to
-- -- the panel width by default, so the control fills the row.
local function section(title, control)
	return ui.column({ gap = 8 }, {
		ui.label({ text = title, fontWeight = "medium", color = "on_surface_variant" }),
		control,
	})
end

local function accentPicker(accentType: string, onChangeFunc: string)
	local accentIndex = themeSelection.accents[accentType].index

	return ui.row({ gap = 12, align = "center" }, {
		ui.label({ text = `{accentType}:`, color = "on_surface", flexGrow = 1 }),
		ui.select({
			options = Theme.Array(themeSelection).accents,
			selectedIndex = accentIndex,
			onChange = onChangeFunc,
		}),
		--ui.box({ width = 32, height = 32, radius = 8, fill = accentColorHex, border = "outline", borderWidth = 1 }),
	})
end

local function render()
	-- The panel surface already insets its content (Style::panelPadding), so this
	-- adds gaps between rows, not its own outer padding.

	if themeSelection.theme.name == "" then
		local saveTable = Theme.Get()
		if saveTable then
			themeSelection = saveTable
		else
			themeSelection = Theme.RandomSelection(themeSelection.theme.index, themeSelection.theme.name)
		end
	end

	local accentList = Theme.AccentTable(themeSelection)
	local themeArray = Theme.Array(themeSelection)

	local themeName = themeSelection.theme.name
	local themeBaseName = themeSelection.themeBase.name
	local currentTheme = colorSchemes[themeName][themeBaseName]

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
					options = Theme.ThemeNames,
					selectedIndex = themeSelection.theme.index,
					onChange = "onColorSchemeSelected",
				}), -- theme
				ui.select({
					options = themeArray.bases,
					selectedIndex = themeSelection.themeBase.index,
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
		ui.row({ gap = 12, align = "center" }, {
			ui.box({
				width = 32,
				height = 32,
				radius = 8,
				fill = accentList.Primary,
				border = "outline",
				borderWidth = 1,
			}),
			ui.box({
				width = 32,
				height = 32,
				radius = 8,
				fill = accentList.Secondary,
				border = "outline",
				borderWidth = 1,
			}),
			ui.box({
				width = 32,
				height = 32,
				radius = 8,
				fill = accentList.Tertiary,
				border = "outline",
				borderWidth = 1,
			}),
			ui.box({
				width = 32,
				height = 32,
				radius = 8,
				fill = accentList.Error,
				border = "outline",
				borderWidth = 1,
			}),
			ui.box({
				width = 32,
				height = 32,
				radius = 8,
				fill = currentTheme.Base.mSurface,
				border = "outline",
				borderWidth = 1,
			}),
			ui.box({
				width = 32,
				height = 32,
				radius = 8,
				fill = currentTheme.Base.mSurfaceVariant,
				border = "outline",
				borderWidth = 1,
			}),
		}),
		ui.button({ glyph = "palette", text = "Apply Color Scheme", onClick = "onApplyClicked" }),
	}))
end

function onOpen(_context)
	render()
end

function onColorSchemeSelected(index, text)
	themeSelection = Theme.RandomSelection(index, text)

	render()
end

local function getKey(index: number?, text: string?)
	return {
		index = tonumber(index) or 0,
		name = text,
	}
end

function onColorSchemeBaseSelected(index, text)
	themeSelection.themeBase = getKey(index, text)

	render()
end

function onPrimaryAccentColorSelected(index, text)
	themeSelection.accents.Primary = getKey(index, text)

	render()
end

function onSecondaryAccentColorSelected(index, text)
	themeSelection.accents.Secondary = getKey(index, text)

	render()
end

function onTertiaryAccentColorSelected(index, text)
	themeSelection.accents.Tertiary = getKey(index, text)

	render()
end

function onErrorAccentColorSelected(index, text)
	themeSelection.accents.Error = getKey(index, text)

	render()
end

function onApplyClicked()
	Theme.Apply(themeSelection)
end

function onCloseClicked()
	panel.close()
end

function update()
	render()
end
