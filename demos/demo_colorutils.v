module main

import colorutils

fn main() {
	println('==================================================')
	println('               demo_colorutils                    ')
	println('==================================================')

	// 1. Parsing and converting colors
	println('1. Color Space Conversions:')
	c1 := colorutils.hex_to_rgb('#3498db') or { panic(err) }
	println('  Hex #3498db -> ${c1}')
	hsl1 := colorutils.rgb_to_hsl(c1)
	println('  RGB to HSL  -> ${hsl1}')
	rgb_back := colorutils.hsl_to_rgb(hsl1)
	println('  HSL to RGB  -> ${rgb_back} (${rgb_back.hex()})')

	// 2. Manipulations
	println('\n2. Color Transformations:')
	lighter := colorutils.lighten(c1, 0.2)
	darker := colorutils.darken(c1, 0.2)
	inverted := colorutils.invert(c1)
	gray := colorutils.grayscale(c1)
	blended := colorutils.blend(c1, colorutils.RGB{ r: 255, g: 255, b: 0 }, 0.5)

	println('  Original: ${c1.hex()}')
	println('  Lighten:  ${lighter.hex()}')
	println('  Darken:   ${darker.hex()}')
	println('  Invert:   ${inverted.hex()}')
	println('  Gray:     ${gray.hex()}')
	println('  Blend:    ${blended.hex()} (50% with yellow)')

	// 3. WCAG Accessibility
	println('\n3. WCAG Contrast & Accessibility:')
	white := colorutils.RGB{ r: 255, g: 255, b: 255 }
	black := colorutils.RGB{ r: 0, g: 0, b: 0 }
	ratio_white := colorutils.contrast_ratio(c1, white)
	ratio_black := colorutils.contrast_ratio(c1, black)
	println('  Contrast against white: ${ratio_white:.2f}:1 (AA normal: ${colorutils.is_accessible(c1, white, 'AA')})')
	println('  Contrast against black: ${ratio_black:.2f}:1 (AA normal: ${colorutils.is_accessible(c1, black, 'AA')})')

	// 4. Truecolor Terminal Output
	println('\n4. Truecolor ANSI Output:')
	colored_text := colorutils.fg_rgb('  ★ Vivid 24-bit Truecolor Text ★  ', c1)
	bg_text := colorutils.bg_rgb('  [ Background Color Highlight ]  ', c1)
	println(colored_text)
	println(bg_text)

	println('\n✔ colorutils demo completed successfully!')
}
