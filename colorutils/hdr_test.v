module colorutils

import math

fn test_hdr_color_creation() {
	c := new_hdr_color(1.5, 0.5, 0.2, 1.0)
	assert c.is_hdr()
	assert c.r == 1.5
	assert c.headroom == 1.5
	assert c.peak_luminance() == 1.5
	assert c.linear_exposure() == 1.5
}

fn test_hdr_color_from_rgb() {
	rgb := RGB{
		r: 255
		g: 128
		b: 0
	}
	hdr := hdr_color_from_rgb(rgb, 2.0)
	assert hdr.is_hdr()
	assert math.abs(hdr.r - 2.0) < 0.01
	assert math.abs(hdr.g - (128.0 / 255.0 * 2.0)) < 0.01
	assert hdr.headroom == 2.0
	assert hdr.linear_exposure() >= 1.99

	sdr := hdr.standard_dynamic_range()
	assert sdr.r == 255
	assert sdr.g == 128
	assert sdr.b == 0
}

fn test_hdr_color_from_exposure() {
	rgb := RGB{
		r: 100
		g: 200
		b: 50
	}
	hdr := hdr_color_from_exposure(rgb, 1.0) // 1 stop = 2x
	assert hdr.is_hdr()
	assert math.abs(hdr.headroom - 2.0) < 0.01
	assert math.abs(hdr.exposure - 1.0) < 0.01

	sdr := hdr.standard_dynamic_range()
	assert sdr.r == 100
	assert sdr.g == 200
	assert sdr.b == 50
}

fn test_applying_content_headroom() {
	rgb := RGB{
		r: 255
		g: 255
		b: 255
	}
	hdr := hdr_color_from_rgb(rgb, 1.5)
	scaled := hdr.applying_content_headroom(3.0)
	assert math.abs(scaled.r - 3.0) < 0.01
	assert scaled.headroom == 3.0
	assert scaled.is_hdr()
}

fn test_tone_mapping() {
	hdr := new_hdr_color(4.0, 2.0, 1.0, 1.0)
	reinhard := hdr.tone_map_reinhard()
	assert reinhard.r > reinhard.g
	assert reinhard.g > reinhard.b

	aces := hdr.tone_map_aces()
	assert aces.r > aces.g
	assert aces.g > aces.b
}
