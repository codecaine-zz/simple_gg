module main

import mathutils

fn main() {
	println('=== mathutils Demo ===')

	// 1. Interpolation & Mapping
	val := 50.0
	mapped := mathutils.remap(val, 0.0, 100.0, 0.0, 1.0)
	println('Remap 50 in [0, 100] -> [0, 1]: ${mapped}')
	assert mapped == 0.5

	snapped := mathutils.round_to_step(4.78, 0.25)
	println('Round 4.78 to step 0.25: ${snapped}')
	assert snapped == 4.75

	clamped := mathutils.clamp(120.0, 0.0, 100.0)
	println('Clamp 120 into [0, 100]: ${clamped}')
	assert clamped == 100.0

	// 2. Geometry
	p1 := mathutils.Point2D[f64]{
		x: 0.0
		y: 0.0
	}
	p2 := mathutils.Point2D[f64]{
		x: 3.0
		y: 4.0
	}
	dist := mathutils.distance(p1, p2)
	println('Distance (0,0) to (3,4): ${dist}')
	assert dist == 5.0

	rect := mathutils.Rect[f64]{
		x:      0.0
		y:      0.0
		width:  100.0
		height: 50.0
	}
	pt := mathutils.Point2D[f64]{
		x: 25.0
		y: 25.0
	}
	assert mathutils.rect_contains_point(rect, pt) == true
	println('Rect contains (25, 25): true')

	// 3. Number Theory
	g := mathutils.gcd(84, 18)
	l := mathutils.lcm(12, 18)
	println('GCD(84, 18): ${g}, LCM(12, 18): ${l}')
	assert g == 6
	assert l == 36

	assert mathutils.is_power_of_two(64) == true
	assert mathutils.next_power_of_two(33) == 64
	println('Power of two checks: pass')

	println('mathutils demo completed successfully!')
}
