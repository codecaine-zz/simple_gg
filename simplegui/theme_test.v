module simplegui

fn test_bun_rad_studio_theme_catalog_is_available() {
	keys := list_theme_keys()
	assert keys.len == 76
	assert 'codefreelance' in keys
	assert 'mac_os_aqua' in keys
	assert 'win95' in keys

	themes := list_themes()
	assert themes.len == 87
	assert 'CodeFreelance' in themes
	assert 'Corporate Navy' in themes

	for i in 0 .. (keys.len - 1) {
		assert keys[i] <= keys[i + 1]
	}
	for i in 0 .. (themes.len - 1) {
		assert themes[i] <= themes[i + 1]
	}
}

fn test_bun_rad_studio_theme_tokens_override_legacy_palette() {
	theme := get_theme('monokai_pro')
	assert theme.name == 'Monokai Pro'
	assert theme.background_color == '#2d2a2e'
	assert theme.accent_color == '#ffd866'
	assert theme.secondary_accent == '#ff6188'
	assert theme.surface_color == '#221f22'
	assert theme.border_color == '#403e41'

	button_text := theme.button_text()
	assert button_text.r == 0
	assert button_text.g == 0
	assert button_text.b == 0
}

fn test_theme_aliases_and_legacy_themes_remain_supported() {
	assert get_theme('c64').key == 'commodore64'
	assert get_theme('Catppuccin Mocha').key == 'catppuccin'
	assert get_theme('matrix').key == 'matrix_phosphor'
	assert get_theme('corporate').name == 'Corporate Navy'

	legacy := get_theme('Corporate Navy')
	assert legacy.surface().r == 240
	assert legacy.border().r == 210
}
