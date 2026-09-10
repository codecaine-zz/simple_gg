module colorutils

import math

// ============================================================================
// Data Models
// ============================================================================

// RGB represents an 8-bit per channel Red-Green-Blue color.
pub struct RGB {
pub:
	r u8
	g u8
	b u8
}

// hex formats the RGB color as a lowercase hexadecimal string (e.g. "#ff007f").
pub fn (c RGB) hex() string {
	return '#${c.r:02x}${c.g:02x}${c.b:02x}'
}

// str returns a CSS-compatible rgb(r, g, b) string.
pub fn (c RGB) str() string {
	return 'rgb(${c.r}, ${c.g}, ${c.b})'
}

// HSL represents a Hue (0.0 - 360.0), Saturation (0.0 - 1.0), and Lightness (0.0 - 1.0) color.
pub struct HSL {
pub:
	h f64
	s f64
	l f64
}

// str returns a CSS-compatible hsl(h, s%, l%) string.
pub fn (c HSL) str() string {
	s_pct := int(c.s * 100.0)
	l_pct := int(c.l * 100.0)
	return 'hsl(${int(c.h)}, ${s_pct}%, ${l_pct}%)'
}

// ============================================================================
// 1. Color Space Conversions
// ============================================================================

// hex_to_rgb parses a hex color string (supports "#RRGGBB", "RRGGBB", "#RGB", "RGB").
pub fn hex_to_rgb(hex_str string) !RGB {
	mut s := hex_str.trim_space()
	if s.starts_with('#') {
		s = s[1..]
	}

	if s.len == 3 {
		// Expand shorthand RGB -> RRGGBB
		s = '${s[0..1]}${s[0..1]}${s[1..2]}${s[1..2]}${s[2..3]}${s[2..3]}'
	}

	if s.len != 6 {
		return error('Invalid hex color "${hex_str}", expected 3 or 6 hex digits')
	}

	r := parse_hex_byte(s[0..2])!
	g := parse_hex_byte(s[2..4])!
	b := parse_hex_byte(s[4..6])!

	return RGB{
		r: r
		g: g
		b: b
	}
}

fn parse_hex_byte(two_chars string) !u8 {
	for ch in two_chars {
		if !ch.is_hex_digit() {
			return error('Invalid hex character "${ch.ascii_str()}"')
		}
	}
	val := ('0x' + two_chars).int()
	return u8(val)
}

// rgb_to_hex formats an RGB struct into a 6-character hex string with leading hash.
pub fn rgb_to_hex(c RGB) string {
	return c.hex()
}

// rgb_to_hsl converts an RGB color into Hue, Saturation, Lightness.
pub fn rgb_to_hsl(c RGB) HSL {
	r := f64(c.r) / 255.0
	g := f64(c.g) / 255.0
	b := f64(c.b) / 255.0

	max := math.max(r, math.max(g, b))
	min := math.min(r, math.min(g, b))
	delta := max - min

	mut h := 0.0
	mut s := 0.0
	l := (max + min) / 2.0

	if delta != 0.0 {
		s = if l > 0.5 { delta / (2.0 - max - min) } else { delta / (max + min) }
		if max == r {
			h = (g - b) / delta + (if g < b { 6.0 } else { 0.0 })
		} else if max == g {
			h = (b - r) / delta + 2.0
		} else {
			h = (r - g) / delta + 4.0
		}
		h *= 60.0
	}

	return HSL{
		h: h
		s: s
		l: l
	}
}

// hsl_to_rgb converts Hue, Saturation, Lightness into an RGB color.
pub fn hsl_to_rgb(hsl HSL) RGB {
	h := math.fmod(hsl.h, 360.0)
	s := math.max(0.0, math.min(1.0, hsl.s))
	l := math.max(0.0, math.min(1.0, hsl.l))

	if s == 0.0 {
		val := u8(l * 255.0)
		return RGB{
			r: val
			g: val
			b: val
		}
	}

	q := if l < 0.5 { l * (1.0 + s) } else { l + s - l * s }
	p := 2.0 * l - q

	hk := h / 360.0
	tr := hk + 1.0 / 3.0
	tg := hk
	tb := hk - 1.0 / 3.0

	return RGB{
		r: u8(hue_to_rgb(p, q, tr) * 255.0)
		g: u8(hue_to_rgb(p, q, tg) * 255.0)
		b: u8(hue_to_rgb(p, q, tb) * 255.0)
	}
}

fn hue_to_rgb(p f64, q f64, t f64) f64 {
	mut tc := t
	if tc < 0.0 {
		tc += 1.0
	}
	if tc > 1.0 {
		tc -= 1.0
	}
	if tc < 1.0 / 6.0 {
		return p + (q - p) * 6.0 * tc
	}
	if tc < 1.0 / 2.0 {
		return q
	}
	if tc < 2.0 / 3.0 {
		return p + (q - p) * (2.0 / 3.0 - tc) * 6.0
	}
	return p
}

// ============================================================================
// 2. Color Transformations & Manipulation
// ============================================================================

// lighten increases color lightness by a given percentage (0.0 to 1.0).
pub fn lighten(c RGB, percent f64) RGB {
	hsl := rgb_to_hsl(c)
	new_l := math.min(1.0, hsl.l + (1.0 - hsl.l) * math.max(0.0, percent))
	return hsl_to_rgb(HSL{
		h: hsl.h
		s: hsl.s
		l: new_l
	})
}

// darken decreases color lightness by a given percentage (0.0 to 1.0).
pub fn darken(c RGB, percent f64) RGB {
	hsl := rgb_to_hsl(c)
	new_l := math.max(0.0, hsl.l * (1.0 - math.max(0.0, math.min(1.0, percent))))
	return hsl_to_rgb(HSL{
		h: hsl.h
		s: hsl.s
		l: new_l
	})
}

// invert returns the inverse / negative color (255 - channel).
pub fn invert(c RGB) RGB {
	return RGB{
		r: 255 - c.r
		g: 255 - c.g
		b: 255 - c.b
	}
}

// blend linearly interpolates between two colors with a factor from 0.0 (c1) to 1.0 (c2).
pub fn blend(c1 RGB, c2 RGB, factor f64) RGB {
	f := math.max(0.0, math.min(1.0, factor))
	return RGB{
		r: u8(f64(c1.r) + (f64(c2.r) - f64(c1.r)) * f)
		g: u8(f64(c1.g) + (f64(c2.g) - f64(c1.g)) * f)
		b: u8(f64(c1.b) + (f64(c2.b) - f64(c1.b)) * f)
	}
}

// grayscale converts an RGB color to perceptually weighted grayscale.
pub fn grayscale(c RGB) RGB {
	gray := u8(0.299 * f64(c.r) + 0.587 * f64(c.g) + 0.114 * f64(c.b))
	return RGB{
		r: gray
		g: gray
		b: gray
	}
}

// ============================================================================
// 3. Accessibility & WCAG Contrast Ratio
// ============================================================================

// luminance calculates relative luminance according to the WCAG 2.1 specification (0.0 to 1.0).
pub fn luminance(c RGB) f64 {
	r := srgb_channel_to_linear(f64(c.r) / 255.0)
	g := srgb_channel_to_linear(f64(c.g) / 255.0)
	b := srgb_channel_to_linear(f64(c.b) / 255.0)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
}

fn srgb_channel_to_linear(val f64) f64 {
	if val <= 0.04045 {
		return val / 12.92
	}
	return math.pow((val + 0.055) / 1.055, 2.4)
}

// contrast_ratio computes the WCAG contrast ratio between two colors (ranging from 1.0:1 to 21.0:1).
pub fn contrast_ratio(c1 RGB, c2 RGB) f64 {
	l1 := luminance(c1)
	l2 := luminance(c2)
	lighter := math.max(l1, l2)
	darker := math.min(l1, l2)
	return (lighter + 0.05) / (darker + 0.05)
}

// is_accessible checks if two colors meet WCAG contrast thresholds:
// - "AA": standard text (ratio >= 4.5)
// - "AAA": enhanced text (ratio >= 7.0)
// - "AA_large": large text or UI components (ratio >= 3.0)
pub fn is_accessible(foreground RGB, background RGB, level string) bool {
	ratio := contrast_ratio(foreground, background)
	match level {
		'AAA' {
			return ratio >= 7.0
		}
		'AA_large' {
			return ratio >= 3.0
		}
		else {
			return ratio >= 4.5
		}
	}
}

// ============================================================================
// 4. Terminal Truecolor (24-bit ANSI) Formatting
// ============================================================================

// fg_rgb colors text using 24-bit RGB truecolor terminal escape sequences.
pub fn fg_rgb(text string, c RGB) string {
	return '\x1b[38;2;${c.r};${c.g};${c.b}m${text}\x1b[39m'
}

// bg_rgb sets background color using 24-bit RGB truecolor terminal escape sequences.
pub fn bg_rgb(text string, c RGB) string {
	return '\x1b[48;2;${c.r};${c.g};${c.b}m${text}\x1b[49m'
}
