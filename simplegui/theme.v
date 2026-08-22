// Module simplegui - Core UI Framework for V
// File: theme.v
//
// Description:
//   This file manages visual themes, color palettes, and color utilities for SimpleGUI applications.
//   It defines the `Theme` struct, hex color parsing routines, and preset theme lookup dictionaries
//   including macOS Light/Dark, Midnight, Cyberpunk, Nord, Catppuccin, Corporate Navy, and more.

module simplegui

import gg
import os

// Theme represents a complete color palette configuration for the application UI.
// Controls reference these colors to render consistent backgrounds, text, accents, and hover states.
pub struct Theme {
pub mut:
	name             string // Human-readable name of the theme (e.g., 'Apple Dark', 'Nord')
	background_color string // Main window canvas background color in hex (e.g., '#1c1c1e')
	font_color       string // Primary text font color in hex (e.g., '#f2f2f7')
	accent_color     string // Active interactive highlight color for buttons/sliders (e.g., '#0a84ff')
	hover_color      string // Hover highlight tint color when mouse is positioned over elements
	surface_hover    string // Background tint color for hovered containers or list rows
	description      string // Brief description of theme aesthetics
	is_dark          bool   // True for dark mode palettes, false for light mode palettes
}

// hex_char_val converts a single ASCII hex character byte (`0`-`9`, `a`-`f`, `A`-`F`)
// into its integer numerical value (0..15).
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

// parse_hex_color parses a CSS-style hex color string (e.g. "#007aff", "007aff", or "#07f")
// into a V `gg.Color` struct (RGB bytes: Red, Green, Blue).
pub fn parse_hex_color(hex string) gg.Color {
	mut s := hex.trim_space().trim_left('#')
	// Expand 3-character shorthand "#abc" to 6-character "#aabbcc"
	if s.len == 3 {
		s = '${s[0..1]}${s[0..1]}${s[1..2]}${s[1..2]}${s[2..3]}${s[2..3]}'
	}
	if s.len < 6 {
		return gg.rgb(0, 0, 0) // Default fallback to black if hex string is invalid
	}
	r := u8((hex_char_val(s[0]) << 4) | hex_char_val(s[1]))
	g := u8((hex_char_val(s[2]) << 4) | hex_char_val(s[3]))
	b := u8((hex_char_val(s[4]) << 4) | hex_char_val(s[5]))
	return gg.rgb(r, g, b)
}

// list_themes returns a list of all pre-packaged visual theme names supported by SimpleGUI.
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
		'Synthwave 84',
		'Neon Matrix',
		'Holodeck Cyan',
		'Sci-Fi HUD Orange',
		'Quantum Violet',
		'Corporate Navy',
		'Executive Slate',
		'Financial Gold',
		'Enterprise Light',
		'Modern Minimalist',
		'Pro Charcoal',
		'Tokyo Night',
		'One Dark Pro',
		'Gruvbox Dark',
		'Monokai Pro',
		'Rosé Pine',
		'Coffee Roast',
		'Solarized Light',
		'Solarized Dark',
		'GitHub Dark',
		'GitHub Light',
		'Navy Blue',
		'Forest Green',
	]
}

// get_theme looks up a `Theme` preset configuration by name (case-insensitive, ignoring spaces and dashes).
// If an unknown theme name is supplied, it gracefully defaults to 'Apple Light'.
pub fn get_theme(theme_name string) Theme {
	normalized := theme_name.to_lower().replace(' ', '').replace('_', '').replace('-', '').replace('é', 'e')
	return match normalized {
		'appledark', 'dark' {
			Theme{
				name: 'Apple Dark'
				background_color: '#1c1c1e'
				font_color: '#f2f2f7'
				accent_color: '#0a84ff'
				hover_color: '#409cff'
				surface_hover: '#2c2c2e'
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
				hover_color: '#38bdf8'
				surface_hover: '#27272a'
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
				hover_color: '#ff8833'
				surface_hover: '#3a2533'
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
				hover_color: '#4ade80'
				surface_hover: '#163327'
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
				hover_color: '#ffaa33'
				surface_hover: '#332621'
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
				hover_color: '#f4a261'
				surface_hover: '#f2eae1'
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
				hover_color: '#f5c2e7'
				surface_hover: '#313244'
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
				hover_color: '#81a1c1'
				surface_hover: '#3b4252'
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
				hover_color: '#ff79c6'
				surface_hover: '#44475a'
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
				hover_color: '#7000ff'
				surface_hover: '#1f1f2e'
				description: 'Neon glow dark contrast palette'
				is_dark: true
			}
		}
		'synthwave84', 'synthwave', 'synth' {
			Theme{
				name: 'Synthwave 84'
				background_color: '#261535'
				font_color: '#ffeefd'
				accent_color: '#ff7edb'
				hover_color: '#36f9f6'
				surface_hover: '#361d4a'
				description: 'Retro 80s synthwave neon twilight theme'
				is_dark: true
			}
		}
		'neonmatrix', 'matrix' {
			Theme{
				name: 'Neon Matrix'
				background_color: '#05100a'
				font_color: '#00ff66'
				accent_color: '#39ff14'
				hover_color: '#00ffaa'
				surface_hover: '#0e2417'
				description: 'Digital phosphor green cyber terminal theme'
				is_dark: true
			}
		}
		'holodeckcyan', 'holodeck', 'holo' {
			Theme{
				name: 'Holodeck Cyan'
				background_color: '#050b14'
				font_color: '#e0f7fc'
				accent_color: '#00f0ff'
				hover_color: '#70f3ff'
				surface_hover: '#0e1e38'
				description: 'Futuristic glowing holographic cyan display'
				is_dark: true
			}
		}
		'scifihudorange', 'scifihud', 'hud' {
			Theme{
				name: 'Sci-Fi HUD Orange'
				background_color: '#121316'
				font_color: '#ffaa00'
				accent_color: '#ff6600'
				hover_color: '#ffcc00'
				surface_hover: '#22252d'
				description: 'Tactical amber futuristic cockpit HUD theme'
				is_dark: true
			}
		}
		'quantumviolet', 'quantum' {
			Theme{
				name: 'Quantum Violet'
				background_color: '#110926'
				font_color: '#f3e8ff'
				accent_color: '#9d4edd'
				hover_color: '#c77dff'
				surface_hover: '#211242'
				description: 'Quantum glow electric purple dark palette'
				is_dark: true
			}
		}
		'corporatenavy', 'corporate' {
			Theme{
				name: 'Corporate Navy'
				background_color: '#f8fafc'
				font_color: '#0f172a'
				accent_color: '#1e40af'
				hover_color: '#2563eb'
				surface_hover: '#e2e8f0'
				description: 'Professional enterprise corporate navy light theme'
				is_dark: false
			}
		}
		'executiveslate', 'executive' {
			Theme{
				name: 'Executive Slate'
				background_color: '#1e293b'
				font_color: '#f8fafc'
				accent_color: '#3b82f6'
				hover_color: '#60a5fa'
				surface_hover: '#334155'
				description: 'Dark executive slate enterprise dashboard theme'
				is_dark: true
			}
		}
		'financialgold', 'finance', 'gold' {
			Theme{
				name: 'Financial Gold'
				background_color: '#181614'
				font_color: '#fef3c7'
				accent_color: '#d97706'
				hover_color: '#f59e0b'
				surface_hover: '#2a241e'
				description: 'Fintech luxury gold & dark bronze financial theme'
				is_dark: true
			}
		}
		'enterpriselight', 'enterprise' {
			Theme{
				name: 'Enterprise Light'
				background_color: '#f3f4f6'
				font_color: '#1f2937'
				accent_color: '#0d9488'
				hover_color: '#14b8a6'
				surface_hover: '#e5e7eb'
				description: 'Clean modern enterprise admin & SaaS dashboard'
				is_dark: false
			}
		}
		'modernminimalist', 'minimalist', 'monochrome' {
			Theme{
				name: 'Modern Minimalist'
				background_color: '#ffffff'
				font_color: '#111111'
				accent_color: '#18181b'
				hover_color: '#3f3f46'
				surface_hover: '#f4f4f5'
				description: 'High-contrast sleek monochrome minimalist theme'
				is_dark: false
			}
		}
		'procharcoal', 'charcoal' {
			Theme{
				name: 'Pro Charcoal'
				background_color: '#18181b'
				font_color: '#fafafa'
				accent_color: '#6366f1'
				hover_color: '#818cf8'
				surface_hover: '#27272a'
				description: 'Sleek pro charcoal dark mode for SaaS apps'
				is_dark: true
			}
		}
		'tokyonight', 'tokyo' {
			Theme{
				name: 'Tokyo Night'
				background_color: '#1a1b26'
				font_color: '#c0caf5'
				accent_color: '#7aa2f7'
				hover_color: '#bb9af7'
				surface_hover: '#24283b'
				description: 'Iconic Tokyo neon night developer dark palette'
				is_dark: true
			}
		}
		'onedarkpro', 'onedark' {
			Theme{
				name: 'One Dark Pro'
				background_color: '#282c34'
				font_color: '#abb2bf'
				accent_color: '#61afef'
				hover_color: '#c678dd'
				surface_hover: '#353b45'
				description: 'Popular Atom One Dark editor palette'
				is_dark: true
			}
		}
		'gruvboxdark', 'gruvbox' {
			Theme{
				name: 'Gruvbox Dark'
				background_color: '#282828'
				font_color: '#ebdbb2'
				accent_color: '#fabd2f'
				hover_color: '#fe8019'
				surface_hover: '#3c3836'
				description: 'Retro warm dark orange & green developer theme'
				is_dark: true
			}
		}
		'monokaipro', 'monokai' {
			Theme{
				name: 'Monokai Pro'
				background_color: '#2d2a2e'
				font_color: '#fcfcfa'
				accent_color: '#ff6188'
				hover_color: '#ffd866'
				surface_hover: '#403c40'
				description: 'Classic Monokai vivid dark contrast theme'
				is_dark: true
			}
		}
		'rosepine', 'rose' {
			Theme{
				name: 'Rosé Pine'
				background_color: '#191724'
				font_color: '#e0def4'
				accent_color: '#ebbcba'
				hover_color: '#c4a7e7'
				surface_hover: '#26233a'
				description: 'Soothing natural rose gold & purple dark theme'
				is_dark: true
			}
		}
		'coffeeroast', 'coffee', 'warm' {
			Theme{
				name: 'Coffee Roast'
				background_color: '#1c1613'
				font_color: '#fef3c7'
				accent_color: '#d97706'
				hover_color: '#f59e0b'
				surface_hover: '#2d231e'
				description: 'Warm cozy coffee roast espresso dark theme'
				is_dark: true
			}
		}
		'solarizedlight' {
			Theme{
				name: 'Solarized Light'
				background_color: '#fdf6e3'
				font_color: '#657b83'
				accent_color: '#268bd2'
				hover_color: '#2aa198'
				surface_hover: '#eee8d5'
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
				hover_color: '#268bd2'
				surface_hover: '#073642'
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
				hover_color: '#79c0ff'
				surface_hover: '#161b22'
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
				hover_color: '#218bff'
				surface_hover: '#f6f8fa'
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
				hover_color: '#60a5fa'
				surface_hover: '#1e293b'
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
				hover_color: '#86efac'
				surface_hover: '#166534'
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
				hover_color: '#3395ff'
				surface_hover: '#e5e5ea'
				description: 'Clean macOS Aqua system light canvas'
				is_dark: false
			}
		}
	}
}

// get_theme_config_path returns the file path used to persist the active window theme.
fn get_theme_config_path() string {
	base := os.config_dir() or { os.join_path(os.home_dir(), '.config') }
	return os.join_path(base, 'simplegui', 'theme.txt')
}

// get_saved_theme retrieves the persisted theme preference, defaulting to 'GitHub Dark'.
pub fn get_saved_theme() string {
	path := get_theme_config_path()
	if os.exists(path) {
		val := os.read_file(path) or { '' }.trim_space()
		if val != '' {
			return val
		}
	}
	return 'GitHub Dark'
}

// save_theme persists the active theme preference to disk.
pub fn save_theme(theme_name string) bool {
	path := get_theme_config_path()
	dir := os.dir(path)
	if !os.exists(dir) {
		os.mkdir_all(dir) or { return false }
	}
	os.write_file(path, theme_name.trim_space()) or { return false }
	return true
}

// save_theme persists the chosen theme for the window and saves it to user preferences.
pub fn (win &SimpleWindow) save_theme(theme_name string) &SimpleWindow {
	save_theme(theme_name)
	return win
}

// restore_saved_theme loads and applies the saved theme from disk.
pub fn (mut win SimpleWindow) restore_saved_theme() &SimpleWindow {
	saved := get_saved_theme()
	win.set_theme(saved)
	return win
}

