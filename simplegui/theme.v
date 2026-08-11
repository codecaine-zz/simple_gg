module simplegui

import gg

pub struct Theme {
pub mut:
	name             string
	background_color string
	font_color       string
	accent_color     string
	description      string
	is_dark          bool
}

fn hex_char_val(c u8) u32 {
	if c >= `0` && c <= `9` {
		return u32(c - `0`)
	}
	if c >= `a` && c <= `f` {
		return u32(c - `a` + 10)
	}
	if c >= `A` && c <= `F` {
		return u32(c - `A` + 10)
	}
	return 0
}

pub fn parse_hex_color(hex string) gg.Color {
	mut s := hex.trim_space().trim_left('#')
	if s.len == 3 {
		s = '${s[0..1]}${s[0..1]}${s[1..2]}${s[1..2]}${s[2..3]}${s[2..3]}'
	}
	if s.len < 6 {
		return gg.rgb(0, 0, 0)
	}
	r := u8((hex_char_val(s[0]) << 4) | hex_char_val(s[1]))
	g := u8((hex_char_val(s[2]) << 4) | hex_char_val(s[3]))
	b := u8((hex_char_val(s[4]) << 4) | hex_char_val(s[5]))
	return gg.rgb(r, g, b)
}

pub fn list_themes() []string {
	return [
		'Apple Light',
		'Apple Dark',
		'Midnight Space Gray',
		'Apple Sunset',
		'Sonoma Emerald',
		'Ventura Amber',
		'Soft Pastel',
		'Catppuccin Mocha',
		'Nord',
		'Dracula',
		'Cyberpunk',
		'Solarized Light',
		'Solarized Dark',
		'GitHub Dark',
		'GitHub Light',
		'Navy Blue',
		'Forest Green',
	]
}

pub fn get_theme(theme_name string) Theme {
	normalized := theme_name.to_lower().replace(' ', '').replace('_', '').replace('-', '')
	return match normalized {
		'appledark', 'dark' {
			Theme{
				name: 'Apple Dark'
				background_color: '#1c1c1e'
				font_color: '#f2f2f7'
				accent_color: '#0a84ff'
				description: 'Vibrant macOS Dark Mode surface'
				is_dark: true
			}
		}
		'midnightspacegray', 'midnight' {
			Theme{
				name: 'Midnight Space Gray'
				background_color: '#161618'
				font_color: '#ebebf5'
				accent_color: '#0a84ff'
				description: 'Pro dark titanium space gray theme'
				is_dark: true
			}
		}
		'applesunset', 'sunset' {
			Theme{
				name: 'Apple Sunset'
				background_color: '#281a24'
				font_color: '#fdf7f4'
				accent_color: '#ff6b00'
				description: 'Warm macOS Mojave twilight sunset hues'
				is_dark: true
			}
		}
		'sonomaemerald', 'emerald' {
			Theme{
				name: 'Sonoma Emerald'
				background_color: '#0d1f18'
				font_color: '#f0fdf4'
				accent_color: '#30d158'
				description: 'macOS Sonoma dark forest glass palette'
				is_dark: true
			}
		}
		'venturaamber', 'amber' {
			Theme{
				name: 'Ventura Amber'
				background_color: '#211815'
				font_color: '#fff8f0'
				accent_color: '#ff9500'
				description: 'macOS Ventura golden sunset dark hues'
				is_dark: true
			}
		}
		'softpastel', 'pastel' {
			Theme{
				name: 'Soft Pastel'
				background_color: '#faf6f0'
				font_color: '#2d2b2a'
				accent_color: '#e07a5f'
				description: 'Apple Studio warm soft light theme'
				is_dark: false
			}
		}
		'catppuccinmocha', 'catppuccin' {
			Theme{
				name: 'Catppuccin Mocha'
				background_color: '#1e1e2e'
				font_color: '#cdd6f4'
				accent_color: '#cba6f7'
				description: 'Soothing lavender catppuccin dark mode'
				is_dark: true
			}
		}
		'nord' {
			Theme{
				name: 'Nord'
				background_color: '#2e3440'
				font_color: '#eceff4'
				accent_color: '#88c0d0'
				description: 'Arctic frost nord developer palette'
				is_dark: true
			}
		}
		'dracula' {
			Theme{
				name: 'Dracula'
				background_color: '#282a36'
				font_color: '#f8f8f2'
				accent_color: '#bd93f9'
				description: 'High-contrast vampire purple palette'
				is_dark: true
			}
		}
		'cyberpunk' {
			Theme{
				name: 'Cyberpunk'
				background_color: '#0d0d15'
				font_color: '#00f5d4'
				accent_color: '#ff007f'
				description: 'Neon glow dark contrast palette'
				is_dark: true
			}
		}
		'solarizedlight' {
			Theme{
				name: 'Solarized Light'
				background_color: '#fdf6e3'
				font_color: '#657b83'
				accent_color: '#268bd2'
				description: 'Precision engineered light palette'
				is_dark: false
			}
		}
		'solarizeddark' {
			Theme{
				name: 'Solarized Dark'
				background_color: '#002b36'
				font_color: '#839496'
				accent_color: '#2aa198'
				description: 'Precision engineered dark palette'
				is_dark: true
			}
		}
		'githubdark' {
			Theme{
				name: 'GitHub Dark'
				background_color: '#0d1117'
				font_color: '#c9d1d9'
				accent_color: '#58a6ff'
				description: 'Official GitHub dark interface palette'
				is_dark: true
			}
		}
		'githublight' {
			Theme{
				name: 'GitHub Light'
				background_color: '#ffffff'
				font_color: '#24292f'
				accent_color: '#0969da'
				description: 'Clean GitHub light canvas palette'
				is_dark: false
			}
		}
		'navyblue', 'navy' {
			Theme{
				name: 'Navy Blue'
				background_color: '#0f172a'
				font_color: '#f8fafc'
				accent_color: '#38bdf8'
				description: 'Deep slate navy dark theme'
				is_dark: true
			}
		}
		'forestgreen', 'forest' {
			Theme{
				name: 'Forest Green'
				background_color: '#14532d'
				font_color: '#f0fdf4'
				accent_color: '#4ade80'
				description: 'Rich emerald green dark theme'
				is_dark: true
			}
		}
		else {
			Theme{
				name: 'Apple Light'
				background_color: '#ffffff'
				font_color: '#1c1c1e'
				accent_color: '#007aff'
				description: 'Clean macOS Aqua system light canvas'
				is_dark: false
			}
		}
	}
}
