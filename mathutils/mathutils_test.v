module mathutils

import math

fn test_interpolation_and_clamping() {
	assert lerp(0.0, 100.0, 0.5) == 50.0
	assert lerp(10.0, 20.0, 0.25) == 12.5

	assert inverse_lerp(0.0, 100.0, 50.0) == 0.5
	assert remap(5.0, 0.0, 10.0, 100.0, 200.0) == 150.0

	assert clamp(15.0, 0.0, 10.0) == 10.0
	assert clamp(-5.0, 0.0, 10.0) == 0.0
	assert clamp(5.0, 0.0, 10.0) == 5.0

	assert clamp_int(150, 0, 100) == 100
	assert clamp_int(-5, 0, 100) == 0

	assert round_to_step(4.7, 0.5) == 4.5
	assert round_to_step(4.8, 0.5) == 5.0

	rad := deg_to_rad(180.0)
	assert math.abs(rad - math.pi) < 0.0001
	deg := rad_to_deg(math.pi)
	assert math.abs(deg - 180.0) < 0.0001
}

fn test_geometry_primitives() {
	p1 := Point2D[f64]{
		x: 0.0
		y: 0.0
	}
	p2 := Point2D[f64]{
		x: 3.0
		y: 4.0
	}
	assert distance(p1, p2) == 5.0

	r1 := Rect[f64]{
		x:      0.0
		y:      0.0
		width:  10.0
		height: 10.0
	}
	inside := Point2D[f64]{
		x: 5.0
		y: 5.0
	}
	outside := Point2D[f64]{
		x: 15.0
		y: 5.0
	}
	assert rect_contains_point(r1, inside) == true
	assert rect_contains_point(r1, outside) == false

	r2 := Rect[f64]{
		x:      5.0
		y:      5.0
		width:  10.0
		height: 10.0
	}
	r3 := Rect[f64]{
		x:      20.0
		y:      20.0
		width:  5.0
		height: 5.0
	}
	assert rects_intersect(r1, r2) == true
	assert rects_intersect(r1, r3) == false
}

fn test_number_theory() {
	assert gcd(54, 24) == 6
	assert gcd(48, 18) == 6
	assert lcm(4, 6) == 12
	assert lcm(21, 6) == 42

	assert is_power_of_two(1) == true
	assert is_power_of_two(2) == true
	assert is_power_of_two(16) == true
	assert is_power_of_two(18) == false
	assert is_power_of_two(0) == false

	assert next_power_of_two(3) == 4
	assert next_power_of_two(16) == 16
	assert next_power_of_two(17) == 32
}
