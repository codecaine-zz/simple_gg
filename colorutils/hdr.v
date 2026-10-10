module colorutils

import math

// HDRColor represents a High Dynamic Range color in extended linear or Display P3 color space.
// Unlike standard 8-bit sRGB (0..255) or clamped floats [0.0..1.0], HDRColor channels
// can exceed 1.0 to represent extended dynamic range (EDR) luminance exceeding standard UI white.
pub struct HDRColor {
pub:
	r        f64 // Red component (can exceed 1.0 in extended range)
	g        f64 // Green component (can exceed 1.0 in extended range)
	b        f64 // Blue component (can exceed 1.0 in extended range)
	a        f64 = 1.0 // Alpha channel [0.0..1.0]
	headroom f64 = 1.0 // Display/content headroom multiplier (>= 1.0; 1.0 = SDR, 2.0 = 2x peak brightness, etc.)
	exposure f64 = 0.0 // Linear exposure in stops (0.0 = SDR 1x, +1.0 = 2x, +2.0 = 4x)
}

// new_hdr_color creates an HDRColor with direct extended float values.
pub fn new_hdr_color(r f64, g f64, b f64, a f64) HDRColor {
	return HDRColor{
		r:        r
		g:        g
		b:        b
		a:        math.max(0.0, math.min(1.0, a))
		headroom: math.max(1.0, math.max(r, math.max(g, b)))
		exposure: 0.0
	}
}

// hdr_color_from_rgb creates an HDRColor from standard RGB with a specified EDR headroom multiplier.
// For example, headroom = 2.0 makes the color radiate at 2x standard SDR peak brightness.
pub fn hdr_color_from_rgb(c RGB, headroom f64) HDRColor {
	hr := math.max(1.0, headroom)
	r := (f64(c.r) / 255.0) * hr
	g := (f64(c.g) / 255.0) * hr
	b := (f64(c.b) / 255.0) * hr
	return HDRColor{
		r:        r
		g:        g
		b:        b
		a:        1.0
		headroom: hr
		exposure: math.log2(hr)
	}
}

// hdr_color_from_exposure creates an HDRColor from standard RGB boosted by linear exposure stops.
// e.g. exposure_stops = +1.0 doubles luminance (2x), +2.0 quadruples luminance (4x).
pub fn hdr_color_from_exposure(c RGB, exposure_stops f64) HDRColor {
	mult := math.pow(2.0, exposure_stops)
	r := (f64(c.r) / 255.0) * mult
	g := (f64(c.g) / 255.0) * mult
	b := (f64(c.b) / 255.0) * mult
	return HDRColor{
		r:        r
		g:        g
		b:        b
		a:        1.0
		headroom: math.max(1.0, mult)
		exposure: exposure_stops
	}
}

// linear_exposure calculates the linear exposure multiplier relative to standard 1.0 SDR white.
// Mirrors Cocoa's `NSColor.linearExposure`.
pub fn (c HDRColor) linear_exposure() f64 {
	peak := math.max(c.r, math.max(c.g, c.b))
	return math.max(1.0, peak)
}

// applying_content_headroom returns a new HDRColor scaled to the target display headroom.
// Mirrors Cocoa's `-[NSColor applyingContentHeadroom:]` (macOS 14+).
pub fn (c HDRColor) applying_content_headroom(headroom f64) HDRColor {
	target_headroom := math.max(1.0, headroom)
	ratio := target_headroom / math.max(1.0, c.headroom)
	return HDRColor{
		r:        c.r * ratio
		g:        c.g * ratio
		b:        c.b * ratio
		a:        c.a
		headroom: target_headroom
		exposure: math.log2(target_headroom)
	}
}

// standard_dynamic_range recovers a standard [0..255] RGB color from this HDR color.
// Mirrors Cocoa's `-[NSColor standardDynamicRange]`.
pub fn (c HDRColor) standard_dynamic_range() RGB {
	divisor := if c.headroom > 1.0 {
		c.headroom
	} else if c.exposure > 0.0 {
		math.pow(2.0, c.exposure)
	} else {
		math.max(1.0, math.max(c.r, math.max(c.g, c.b)))
	}
	r := clamp01(c.r / divisor)
	g := clamp01(c.g / divisor)
	b := clamp01(c.b / divisor)
	return RGB{
		r: u8(math.round(r * 255.0))
		g: u8(math.round(g * 255.0))
		b: u8(math.round(b * 255.0))
	}
}

// is_hdr returns true if any color channel exceeds 1.0 or target headroom > 1.0.
pub fn (c HDRColor) is_hdr() bool {
	return c.r > 1.0 || c.g > 1.0 || c.b > 1.0 || c.headroom > 1.0
}

// peak_luminance calculates the peak color channel intensity.
pub fn (c HDRColor) peak_luminance() f64 {
	return math.max(c.r, math.max(c.g, c.b))
}

// tone_map_reinhard tone-maps the HDR color using the classic Reinhard operator: L / (1 + L).
pub fn (c HDRColor) tone_map_reinhard() RGB {
	tm_r := c.r / (1.0 + c.r)
	tm_g := c.g / (1.0 + c.g)
	tm_b := c.b / (1.0 + c.b)
	return RGB{
		r: u8(math.round(clamp01(tm_r) * 255.0))
		g: u8(math.round(clamp01(tm_g) * 255.0))
		b: u8(math.round(clamp01(tm_b) * 255.0))
	}
}

// tone_map_aces tone-maps the HDR color using the ACES filmic tone reproduction curve.
pub fn (c HDRColor) tone_map_aces() RGB {
	aces := fn (x f64) f64 {
		a := 2.51
		b := 0.03
		d := 2.43
		e := 0.59
		return clamp01((x * (a * x + b)) / (x * (d * x + 0.14) + e))
	}
	return RGB{
		r: u8(math.round(aces(c.r) * 255.0))
		g: u8(math.round(aces(c.g) * 255.0))
		b: u8(math.round(aces(c.b) * 255.0))
	}
}

// str returns a descriptive string representation of the HDR color.
pub fn (c HDRColor) str() string {
	return 'hdr_rgb(${c.r:.2f}, ${c.g:.2f}, ${c.b:.2f}, a: ${c.a:.2f}, headroom: ${c.headroom:.2f}x)'
}

// hex returns the hex color string of the recovered SDR representation.
pub fn (c HDRColor) hex() string {
	return c.standard_dynamic_range().hex()
}
