module colorutils

import math

fn test_hex_conversions() {
	c1 := hex_to_rgb('#ff007f')!
	assert c1.r == 255
	assert c1.g == 0
	assert c1.b == 127
	assert rgb_to_hex(c1) == '#ff007f'

	// Shorthand #RGB
	c2 := hex_to_rgb('#fff')!
	assert c2.r == 255
	assert c2.g == 255
	assert c2.b == 255
	assert rgb_to_hex(c2) == '#ffffff'

	// Invalid hex
	if _ := hex_to_rgb('xy') {
		assert false
	} else {
		assert err.msg() == 'Invalid hex color "xy", expected 3 or 6 hex digits'
	}
	if _ := hex_to_rgb('xyz') {
		assert false
	} else {
		assert err.msg() == 'Invalid hex character "x"'
	}
}

fn test_hsl_conversions() {
	// Pure red #ff0000 -> hsl(0, 100%, 50%)
	red := RGB{
		r: 255
		g: 0
		b: 0
	}
	hsl := rgb_to_hsl(red)
	assert math.abs(hsl.h - 0.0) < 0.1
	assert math.abs(hsl.s - 1.0) < 0.01
	assert math.abs(hsl.l - 0.5) < 0.01

	// Round-trip back to RGB
	roundtrip := hsl_to_rgb(hsl)
	assert roundtrip.r == 255
	assert roundtrip.g == 0
	assert roundtrip.b == 0
}

fn test_color_transformations() {
	white := RGB{
		r: 255
		g: 255
		b: 255
	}
	black := RGB{
		r: 0
		g: 0
		b: 0
	}

	// Invert
	inv := invert(white)
	assert inv.r == 0 && inv.g == 0 && inv.b == 0

	// Blend 50% between black and white -> mid gray (~127)
	mid := blend(black, white, 0.5)
	assert mid.r == 127 && mid.g == 127 && mid.b == 127

	// Grayscale
	blue := RGB{
		r: 0
		g: 0
		b: 255
	}
	gray := grayscale(blue)
	assert gray.r == gray.g && gray.g == gray.b
}

fn test_wcag_contrast_and_accessibility() {
	white := RGB{
		r: 255
		g: 255
		b: 255
	}
	black := RGB{
		r: 0
		g: 0
		b: 0
	}

	// Black on white is maximum contrast 21:1
	ratio := contrast_ratio(white, black)
	assert math.abs(ratio - 21.0) < 0.1
	assert is_accessible(black, white, 'AA') == true
	assert is_accessible(black, white, 'AAA') == true

	// Low contrast test: light gray on white
	light_gray := RGB{
		r: 240
		g: 240
		b: 240
	}
	low_ratio := contrast_ratio(light_gray, white)
	assert low_ratio < 2.0
	assert is_accessible(light_gray, white, 'AA') == false
}

fn test_terminal_truecolor_ansi() {
	orange := RGB{
		r: 255
		g: 165
		b: 0
	}
	colored := fg_rgb('Antigravity', orange)
	assert colored.contains('\x1b[38;2;255;165;0mAntigravity\x1b[39m')
}
