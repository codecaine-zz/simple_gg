module colorutils

import math

// ============================================================================
// 5. Additional color spaces: HSV, CMYK, CIE XYZ/Lab, OKLab/OKLCH
// ============================================================================

// HSV represents Hue (0-360), Saturation (0-1), Value (0-1).
pub struct HSV {
pub:
	h f64
	s f64
	v f64
}

// CMYK represents Cyan, Magenta, Yellow, Key (black), each 0-1.
pub struct CMYK {
pub:
	c f64
	m f64
	y f64
	k f64
}

// Lab represents CIE L*a*b* (D65 white point).
pub struct Lab {
pub:
	l f64
	a f64
	b f64
}

// OKLab represents Björn Ottosson's perceptually uniform OKLab space.
pub struct OKLab {
pub:
	l f64
	a f64
	b f64
}

// OKLCH is the polar form of OKLab (lightness, chroma, hue in degrees).
pub struct OKLCH {
pub:
	l f64
	c f64
	h f64
}

fn clamp01(x f64) f64 {
	return if x < 0 {
		0.0
	} else if x > 1 {
		1.0
	} else {
		x
	}
}

fn to_u8(x f64) u8 {
	return u8(math.round(clamp01(x) * 255.0))
}

fn linear_to_srgb(v f64) f64 {
	return if v <= 0.0031308 { 12.92 * v } else { 1.055 * math.pow(v, 1.0 / 2.4) - 0.055 }
}

// rgb_to_hsv converts RGB to HSV.
pub fn rgb_to_hsv(c RGB) HSV {
	r, g, b := f64(c.r) / 255.0, f64(c.g) / 255.0, f64(c.b) / 255.0
	mx := math.max(r, math.max(g, b))
	mn := math.min(r, math.min(g, b))
	d := mx - mn
	mut h := 0.0
	if d != 0 {
		h = if mx == r {
			math.fmod((g - b) / d + 6.0, 6.0)
		} else if mx == g {
			(b - r) / d + 2.0
		} else {
			(r - g) / d + 4.0
		}
		h *= 60.0
	}
	return HSV{h, if mx == 0 { 0.0 } else { d / mx }, mx}
}

// hsv_to_rgb converts HSV to RGB.
pub fn hsv_to_rgb(hsv HSV) RGB {
	mut h := math.fmod(hsv.h, 360.0)
	if h < 0 {
		h += 360.0
	}
	s, v := clamp01(hsv.s), clamp01(hsv.v)
	c := v * s
	x := c * (1.0 - math.abs(math.fmod(h / 60.0, 2.0) - 1.0))
	m := v - c
	r, g, b := match int(h / 60.0) {
		0 { c, x, 0.0 }
		1 { x, c, 0.0 }
		2 { 0.0, c, x }
		3 { 0.0, x, c }
		4 { x, 0.0, c }
		else { c, 0.0, x }
	}
	return RGB{to_u8(r + m), to_u8(g + m), to_u8(b + m)}
}

// rgb_to_cmyk converts RGB to CMYK.
pub fn rgb_to_cmyk(c RGB) CMYK {
	r, g, b := f64(c.r) / 255.0, f64(c.g) / 255.0, f64(c.b) / 255.0
	k := 1.0 - math.max(r, math.max(g, b))
	if k >= 1.0 {
		return CMYK{0, 0, 0, 1}
	}
	return CMYK{(1 - r - k) / (1 - k), (1 - g - k) / (1 - k), (1 - b - k) / (1 - k), k}
}

// cmyk_to_rgb converts CMYK to RGB.
pub fn cmyk_to_rgb(c CMYK) RGB {
	k := clamp01(c.k)
	return RGB{to_u8((1 - clamp01(c.c)) * (1 - k)), to_u8((1 - clamp01(c.m)) * (1 - k)), to_u8((1 - clamp01(c.y)) * (1 - k))}
}

fn linear_rgb(c RGB) (f64, f64, f64) {
	return srgb_channel_to_linear(f64(c.r) / 255.0), srgb_channel_to_linear(f64(c.g) / 255.0), srgb_channel_to_linear(f64(c.b) / 255.0)
}

// rgb_to_lab converts sRGB to CIE L*a*b* (D65).
pub fn rgb_to_lab(c RGB) Lab {
	r, g, b := linear_rgb(c)
	x := (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047
	y := (0.2126729 * r + 0.7151522 * g + 0.0721750 * b)
	z := (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883
	f := fn (t f64) f64 {
		return if t > 216.0 / 24389.0 { math.cbrt(t) } else { (24389.0 / 27.0 * t + 16.0) / 116.0 }
	}
	fx, fy, fz := f(x), f(y), f(z)
	return Lab{116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz)}
}

// delta_e76 is the CIE76 color difference (Euclidean distance in Lab). ~2.3 = just noticeable.
pub fn delta_e76(c1 RGB, c2 RGB) f64 {
	a := rgb_to_lab(c1)
	b := rgb_to_lab(c2)
	return math.sqrt(math.pow(a.l - b.l, 2) + math.pow(a.a - b.a, 2) + math.pow(a.b - b.b, 2))
}

// rgb_to_oklab converts sRGB to OKLab.
pub fn rgb_to_oklab(c RGB) OKLab {
	r, g, b := linear_rgb(c)
	l := math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
	m := math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
	s := math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
	return OKLab{0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s, 1.9779984951 * l - 2.4285922050 * m +
		0.4505937099 * s, 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s}
}

// oklab_to_rgb converts OKLab to sRGB (out-of-gamut values are clamped).
pub fn oklab_to_rgb(o OKLab) RGB {
	l := math.pow(o.l + 0.3963377774 * o.a + 0.2158037573 * o.b, 3)
	m := math.pow(o.l - 0.1055613458 * o.a - 0.0638541728 * o.b, 3)
	s := math.pow(o.l - 0.0894841775 * o.a - 1.2914855480 * o.b, 3)
	r := 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
	g := -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
	b := -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
	return RGB{to_u8(linear_to_srgb(r)), to_u8(linear_to_srgb(g)), to_u8(linear_to_srgb(b))}
}

// rgb_to_oklch converts sRGB to OKLCH.
pub fn rgb_to_oklch(c RGB) OKLCH {
	o := rgb_to_oklab(c)
	mut h := math.degrees(math.atan2(o.b, o.a))
	if h < 0 {
		h += 360.0
	}
	return OKLCH{o.l, math.sqrt(o.a * o.a + o.b * o.b), h}
}

// oklch_to_rgb converts OKLCH to sRGB.
pub fn oklch_to_rgb(c OKLCH) RGB {
	hr := math.radians(c.h)
	return oklab_to_rgb(OKLab{c.l, c.c * math.cos(hr), c.c * math.sin(hr)})
}

// mix_oklab blends two colors in perceptual OKLab space (no muddy midpoints).
pub fn mix_oklab(c1 RGB, c2 RGB, t f64) RGB {
	f := clamp01(t)
	a := rgb_to_oklab(c1)
	b := rgb_to_oklab(c2)
	return oklab_to_rgb(OKLab{a.l + (b.l - a.l) * f, a.a + (b.a - a.a) * f, a.b + (b.b - a.b) * f})
}

// gradient returns `steps` colors evenly interpolated (in OKLab) from c1 to c2 inclusive.
pub fn gradient(c1 RGB, c2 RGB, steps int) []RGB {
	if steps <= 0 {
		return []
	}
	if steps == 1 {
		return [c1]
	}
	return []RGB{len: steps, init: mix_oklab(c1, c2, f64(index) / f64(steps - 1))}
}

// ============================================================================
// 6. Palettes & accessibility helpers
// ============================================================================

fn rotate_hue(c RGB, deg f64) RGB {
	h := rgb_to_hsl(c)
	return hsl_to_rgb(HSL{math.fmod(h.h + deg + 360.0, 360.0), h.s, h.l})
}

// complementary returns the color opposite on the color wheel.
pub fn complementary(c RGB) RGB {
	return rotate_hue(c, 180)
}

// triadic returns the two colors 120° apart from c.
pub fn triadic(c RGB) []RGB {
	return [rotate_hue(c, 120), rotate_hue(c, 240)]
}

// analogous returns neighbours at ±`spread` degrees.
pub fn analogous(c RGB, spread f64) []RGB {
	return [rotate_hue(c, -spread), rotate_hue(c, spread)]
}

// readable_text_color returns black or white, whichever contrasts more with `bg`.
pub fn readable_text_color(bg RGB) RGB {
	black := RGB{0, 0, 0}
	white := RGB{255, 255, 255}
	return if contrast_ratio(black, bg) >= contrast_ratio(white, bg) { black } else { white }
}

// ensure_contrast darkens or lightens `fg` (keeping hue) until it reaches `min_ratio`
// against `bg`, falling back to black/white when the target is unreachable.
pub fn ensure_contrast(fg RGB, bg RGB, min_ratio f64) RGB {
	if contrast_ratio(fg, bg) >= min_ratio {
		return fg
	}
	toward_dark := luminance(bg) > 0.18
	mut lo, mut hi := 0.0, 1.0
	mut best := readable_text_color(bg)
	for _ in 0 .. 24 {
		mid := (lo + hi) / 2.0
		cand := if toward_dark { darken(fg, mid) } else { lighten(fg, mid) }
		if contrast_ratio(cand, bg) >= min_ratio {
			best = cand
			hi = mid
		} else {
			lo = mid
		}
	}
	return best
}

// parse_color parses "#rgb", "#rrggbb", "#rrggbbaa" (alpha ignored), "rgb(r, g, b)",
// "hsl(h, s%, l%)" or a basic CSS color name.
pub fn parse_color(input string) !RGB {
	s := input.trim_space().to_lower()
	if s.starts_with('rgb(') || s.starts_with('rgba(') {
		inner := s.all_after('(').all_before(')')
		p := inner.replace('/', ',').split(',').map(it.trim_space()).filter(it != '')
		if p.len < 3 {
			return error('invalid rgb() color "${input}"')
		}
		mut ch := []u8{}
		for i in 0 .. 3 {
			ch << if p[i].ends_with('%') {
				to_u8(p[i].trim_right('%').f64() / 100.0)
			} else {
				u8(math.min(255.0, math.max(0.0, p[i].f64())))
			}
		}
		return RGB{ch[0], ch[1], ch[2]}
	}
	if s.starts_with('hsl(') || s.starts_with('hsla(') {
		p := s.all_after('(').all_before(')').replace('/', ',').split(',').map(it.trim_space()).filter(it != '')
		if p.len < 3 {
			return error('invalid hsl() color "${input}"')
		}
		return hsl_to_rgb(HSL{p[0].trim_right('deg').f64(), p[1].trim_right('%').f64() / 100.0, p[2].trim_right('%').f64() / 100.0})
	}
	if v := css_names[s] {
		return hex_to_rgb(v)
	}
	mut h := s.trim_left('#')
	if h.len == 8 {
		h = h[..6]
	} else if h.len == 4 {
		h = h[..3]
	}
	return hex_to_rgb(h)
}

const css_names = {
	'black':   '000000'
	'white':   'ffffff'
	'red':     'ff0000'
	'lime':    '00ff00'
	'green':   '008000'
	'blue':    '0000ff'
	'yellow':  'ffff00'
	'cyan':    '00ffff'
	'aqua':    '00ffff'
	'magenta': 'ff00ff'
	'fuchsia': 'ff00ff'
	'silver':  'c0c0c0'
	'gray':    '808080'
	'grey':    '808080'
	'maroon':  '800000'
	'olive':   '808000'
	'purple':  '800080'
	'teal':    '008080'
	'navy':    '000080'
	'orange':  'ffa500'
	'pink':    'ffc0cb'
	'brown':   'a52a2a'
	'gold':    'ffd700'
	'indigo':  '4b0082'
	'violet':  'ee82ee'
	'coral':   'ff7f50'
	'salmon':  'fa8072'
	'tomato':  'ff6347'
	'crimson': 'dc143c'
	'khaki':   'f0e68c'
}

// to_ansi256 returns the nearest xterm-256 palette index (for terminals without truecolor).
pub fn to_ansi256(c RGB) int {
	if c.r == c.g && c.g == c.b {
		if c.r < 8 {
			return 16
		}
		if c.r > 248 {
			return 231
		}
		return int(math.round((f64(c.r) - 8.0) / 247.0 * 24.0)) + 232
	}
	q := fn (v u8) int {
		return int(math.round(f64(v) / 255.0 * 5.0))
	}
	return 16 + 36 * q(c.r) + 6 * q(c.g) + q(c.b)
}
