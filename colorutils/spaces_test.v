module colorutils

import math

fn near(a f64, b f64, eps f64) bool {
	return math.abs(a - b) <= eps
}

fn test_hsl_roundtrip_all_greys_and_samples() {
	// Previously truncation lost a unit on many colors.
	for v in 0 .. 256 {
		c := RGB{u8(v), u8(255 - v), u8((v * 7) % 256)}
		back := hsl_to_rgb(rgb_to_hsl(c))
		assert back == c, '${c} -> ${back}'
	}
	assert hsl_to_rgb(HSL{-120, 1, 0.5}) == RGB{0, 0, 255}
	assert hsl_to_rgb(HSL{-350, 1, 0.5}) == hsl_to_rgb(HSL{10, 1, 0.5})
}

fn test_hsv_cmyk() {
	for c in [RGB{255, 0, 0}, RGB{12, 200, 99}, RGB{0, 0, 0},
		RGB{255, 255, 255}] {
		assert hsv_to_rgb(rgb_to_hsv(c)) == c
		assert cmyk_to_rgb(rgb_to_cmyk(c)) == c
	}
	k := rgb_to_cmyk(RGB{0, 0, 0})
	assert k.k == 1.0
}

fn test_lab_reference_values() {
	// sRGB white = L*100, red ≈ (53.24, 80.09, 67.20)
	w := rgb_to_lab(RGB{255, 255, 255})
	assert near(w.l, 100, 0.01) && near(w.a, 0, 0.01) && near(w.b, 0, 0.01)
	r := rgb_to_lab(RGB{255, 0, 0})
	assert near(r.l, 53.24, 0.05) && near(r.a, 80.09, 0.1) && near(r.b, 67.20, 0.1)
	assert delta_e76(RGB{10, 10, 10}, RGB{10, 10, 10}) == 0
}

fn test_oklab_reference_and_roundtrip() {
	// Reference from Ottosson: white -> L=1, a=b=0; red -> (0.62796, 0.22486, 0.12585)
	w := rgb_to_oklab(RGB{255, 255, 255})
	assert near(w.l, 1.0, 1e-4) && near(w.a, 0, 1e-4) && near(w.b, 0, 1e-4)
	r := rgb_to_oklab(RGB{255, 0, 0})
	assert near(r.l, 0.62796, 1e-3) && near(r.a, 0.22486, 1e-3) && near(r.b, 0.12585, 1e-3)
	for c in [RGB{255, 0, 0}, RGB{18, 52, 86}, RGB{250, 128, 114}] {
		assert oklab_to_rgb(rgb_to_oklab(c)) == c
		assert oklch_to_rgb(rgb_to_oklch(c)) == c
	}
}

fn test_gradient_and_mix() {
	g := gradient(RGB{0, 0, 0}, RGB{255, 255, 255}, 5)
	assert g.len == 5
	assert g[0] == RGB{0, 0, 0}
	assert g[4] == RGB{255, 255, 255}
	for i in 1 .. g.len {
		assert g[i].r > g[i - 1].r
	}
	assert gradient(RGB{}, RGB{}, 0).len == 0
}

fn test_palettes_and_contrast() {
	assert complementary(RGB{255, 0, 0}) == RGB{0, 255, 255}
	tri := triadic(RGB{255, 0, 0})
	assert tri[0] == RGB{0, 255, 0} && tri[1] == RGB{0, 0, 255}
	assert readable_text_color(RGB{255, 255, 0}) == RGB{0, 0, 0}
	assert readable_text_color(RGB{0, 0, 128}) == RGB{255, 255, 255}
	fixed := ensure_contrast(RGB{200, 200, 200}, RGB{255, 255, 255}, 4.5)
	assert contrast_ratio(fixed, RGB{255, 255, 255}) >= 4.5
}

fn test_parse_color() {
	assert parse_color('#ff8800')! == RGB{255, 136, 0}
	assert parse_color('#f80c')! == RGB{255, 136, 0}
	assert parse_color('#ff880080')! == RGB{255, 136, 0}
	assert parse_color('rgb(1, 2, 3)')! == RGB{1, 2, 3}
	assert parse_color('rgba(100%, 0%, 0%, 0.5)')! == RGB{255, 0, 0}
	assert parse_color('hsl(120, 100%, 50%)')! == RGB{0, 255, 0}
	assert parse_color('Tomato')! == RGB{255, 99, 71}
	if _ := parse_color('notacolor') {
		assert false
	}
	assert to_ansi256(RGB{255, 0, 0}) == 196
	assert to_ansi256(RGB{0, 0, 0}) == 16
}
