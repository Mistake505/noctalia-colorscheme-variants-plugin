--!nonstrict
-- Control-center [[shortcut]] entry: a quick-toggle tile.
--
--   shortcut.setLabel(text)
--   shortcut.setIcon(on [, off])   -- one glyph, or distinct on/off glyphs
--   shortcut.setActive(bool)       -- toggle/highlight state
--   shortcut.setEnabled(bool)
--   onClick() / onRightClick()
--
-- State is shared via noctalia.state, so the plugin's other entries (widget,
-- service) could react to the toggle.

local function render()
  shortcut.setLabel("Theme")
  shortcut.setIcon("palette")
  --shortcut.setActive(true)
  shortcut.setEnabled(true)
end

-- Initial state at load.
render()

function onClick()
  noctalia.togglePanel("uozzoku/colorscheme_variants:panel")
  render()
end
