class_name ThemeFactory
extends RefCounted

const COLORS := {
    "void": Color("0b0908"),
    "panel": Color("171310"),
    "raised": Color("241d17"),
    "line": Color("5f4a32"),
    "bright": Color("b1844f"),
    "gold": Color("c89a58"),
    "ink": Color("e7d4b0"),
    "muted": Color("a9977d"),
    "faint": Color("6d6255"),
    "red": Color("a63e2b"),
    "ember": Color("d06332"),
    "teal": Color("477e78")
}

static func build_theme() -> Theme:
    var theme := Theme.new()
    theme.default_font_size = 16
    theme.set_color("font_color", "Label", COLORS.ink)
    theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.7))
    theme.set_constant("shadow_offset_x", "Label", 1)
    theme.set_constant("shadow_offset_y", "Label", 1)
    theme.set_color("font_color", "Button", COLORS.ink)
    theme.set_color("font_hover_color", "Button", COLORS.gold)
    theme.set_color("font_pressed_color", "Button", COLORS.ink)
    theme.set_color("font_disabled_color", "Button", COLORS.faint)
    theme.set_color("font_focus_color", "Button", COLORS.gold)
    theme.set_font_size("font_size", "Button", 14)
    theme.set_font_size("font_size", "Label", 16)
    theme.set_stylebox("normal", "Button", button_style(COLORS.raised, COLORS.line))
    theme.set_stylebox("hover", "Button", button_style(Color("302219"), COLORS.bright))
    theme.set_stylebox("pressed", "Button", button_style(Color("3e2a1a"), COLORS.gold))
    theme.set_stylebox("disabled", "Button", button_style(Color("11100f"), Color("3b3329")))
    theme.set_stylebox("focus", "Button", button_style(Color("302219"), COLORS.gold))
    return theme

static func panel_style(background: Color = Color("171310"), border: Color = Color("5f4a32"), width: int = 1, radius: int = 3) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(radius)
    style.content_margin_left = 14
    style.content_margin_right = 14
    style.content_margin_top = 12
    style.content_margin_bottom = 12
    return style

static func button_style(background: Color = Color("241d17"), border: Color = Color("5f4a32")) -> StyleBoxFlat:
    var style := panel_style(background, border, 1, 2)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    return style

static func separator_style() -> StyleBoxFlat:
    return panel_style(Color(0, 0, 0, 0), Color("493521"), 0, 0)
