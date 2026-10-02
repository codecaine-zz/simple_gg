module mathutils

import math

// ============================================================================
// 1. Interpolation, Clamping & Mapping
// ============================================================================

// lerp performs linear interpolation between a and b by factor t (0.0 to 1.0).
pub fn lerp(a f64, b f64, t f64) f64 {
	return a + (b - a) * t
}

// inverse_lerp returns the normalized interpolation factor (0.0 to 1.0) of v between a and b.
pub fn inverse_lerp(a f64, b f64, v f64) f64 {
	if a == b {
		return 0.0
	}
	return (v - a) / (b - a)
}

// remap maps a value v from one range [in_min, in_max] to a new range [out_min, out_max].
pub fn remap(v f64, in_min f64, in_max f64, out_min f64, out_max f64) f64 {
	t := inverse_lerp(in_min, in_max, v)
	return lerp(out_min, out_max, t)
}

// clamp bounds a floating-point value between min and max inclusive.
pub fn clamp(v f64, min f64, max f64) f64 {
	if v < min {
		return min
	}
	if v > max {
		return max
	}
	return v
}

// clamp_int bounds an integer value between min and max inclusive.
pub fn clamp_int(v int, min int, max int) int {
	if v < min {
		return min
	}
	if v > max {
		return max
	}
	return v
}

// round_to_step snaps a value v to the nearest multiple of step.
pub fn round_to_step(v f64, step f64) f64 {
	if step == 0.0 {
		return v
	}
	return math.round(v / step) * step
}

// deg_to_rad converts degrees to radians.
pub fn deg_to_rad(deg f64) f64 {
	return deg * (math.pi / 180.0)
}

// rad_to_deg converts radians to degrees.
pub fn rad_to_deg(rad f64) f64 {
	return rad * (180.0 / math.pi)
}

// ============================================================================
// 2. 2D Geometry & Spatial Primitives
// ============================================================================

// Point2D represents a 2D Cartesian coordinate.
pub struct Point2D[T] {
pub mut:
	x T
	y T
}

// distance calculates the Euclidean distance between two 2D points.
pub fn distance[T](p1 Point2D[T], p2 Point2D[T]) f64 {
	dx := f64(p2.x) - f64(p1.x)
	dy := f64(p2.y) - f64(p1.y)
	return math.sqrt(dx * dx + dy * dy)
}

// angle_between calculates the angle in radians from p1 to p2.
pub fn angle_between[T](p1 Point2D[T], p2 Point2D[T]) f64 {
	dx := f64(p2.x) - f64(p1.x)
	dy := f64(p2.y) - f64(p1.y)
	return math.atan2(dy, dx)
}

// Rect represents a 2D axis-aligned bounding box.
pub struct Rect[T] {
pub mut:
	x      T
	y      T
	width  T
	height T
}

// rect_contains_point checks if point p is contained inside rectangle r.
pub fn rect_contains_point[T](r Rect[T], p Point2D[T]) bool {
	return p.x >= r.x && p.x <= r.x + r.width && p.y >= r.y && p.y <= r.y + r.height
}

// rects_intersect checks if two axis-aligned rectangles intersect.
pub fn rects_intersect[T](r1 Rect[T], r2 Rect[T]) bool {
	return r1.x < r2.x + r2.width && r1.x + r1.width > r2.x && r1.y < r2.y + r2.height
		&& r1.y + r1.height > r2.y
}

// ============================================================================
// 3. Integer Arithmetic & Number Theory
// ============================================================================

// gcd calculates the Greatest Common Divisor of two integers using the Euclidean algorithm.
pub fn gcd(a i64, b i64) i64 {
	mut x := if a < 0 { -a } else { a }
	mut y := if b < 0 { -b } else { b }
	for y != 0 {
		temp := y
		y = x % y
		x = temp
	}
	return x
}

// lcm calculates the Least Common Multiple of two integers.
pub fn lcm(a i64, b i64) i64 {
	if a == 0 || b == 0 {
		return 0
	}
	g := gcd(a, b)
	val := (a / g) * b
	return if val < 0 { -val } else { val }
}

// is_power_of_two returns true if n is an exact power of two (1, 2, 4, 8, ...).
pub fn is_power_of_two(n u64) bool {
	return n > 0 && (n & (n - 1)) == 0
}

// next_power_of_two returns the smallest power of two greater than or equal to n.
pub fn next_power_of_two(n u64) u64 {
	if n == 0 {
		return 1
	}
	mut v := n - 1
	v |= v >> 1
	v |= v >> 2
	v |= v >> 4
	v |= v >> 8
	v |= v >> 16
	v |= v >> 32
	return v + 1
}
