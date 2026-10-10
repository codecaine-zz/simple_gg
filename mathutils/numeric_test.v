module mathutils

import math

fn test_float_helpers() {
	assert approx_equal(0.1 + 0.2, 0.3, 1e-9, 0.0)
	assert !approx_equal(1.0, 1.1, 1e-9, 0.0)
	assert approx_equal(0.0, 1e-12, 0.0, 1e-9)
	assert !approx_equal(math.nan(), math.nan(), 1e-9, 1e-9)
	assert round_to(3.14159, 2) == 3.14
	assert sign(-2.5) == -1 && sign(0) == 0 && sign(9) == 1
	assert smoothstep(0, 1, 0.5) == 0.5
	assert smoothstep(0, 1, -3) == 0.0
	assert wrap(370, 0, 360) == 10
	assert wrap(-10, 0, 360) == 350
	assert percent(1, 4) == 25.0 && percent(1, 0) == 0.0
	assert percent_change(50, 75) == 50.0
	mut vals := []f64{len: 10, init: 0.1}
	assert kahan_sum(vals) == 1.0
	assert kahan_sum([1e100, 1.0, -1e100]) == 1.0
}

fn test_checked_arithmetic() {
	assert checked_add(max_i64, 1) == none
	assert checked_add(1, 2)? == 3
	assert checked_sub(min_i64, 1) == none
	assert checked_sub(5, 7)? == -2
	assert checked_mul(max_i64 / 2 + 1, 2) == none
	assert checked_mul(min_i64, -1) == none
	assert checked_mul(-4, 5)? == -20
}

fn test_number_theory() {
	assert factorial(0)? == 1
	assert factorial(20)? == 2432902008176640000
	assert factorial(21) == none
	assert binomial(5, 2)? == 10
	assert binomial(66, 33)? == 7219428434016265740
	assert binomial(5, 7)? == 0
	assert binomial(100, 50) == none
	assert fibonacci(10)? == 55
	assert fibonacci(93)? == 12200160415121876738
	assert fibonacci(94) == none
	assert mod_pow(2, 10, 1000) == 24
	assert mod_pow(4, 13, 497) == 445
	assert mod_inverse(3, 11)? == 4
	assert mod_inverse(-3, 11)? == 7
	assert mod_inverse(2, 4) == none
}

fn test_primes() {
	assert !is_prime(0) && !is_prime(1) && is_prime(2) && is_prime(97) && !is_prime(91)
	assert is_prime(18446744073709551557) // largest u64 prime
	assert !is_prime(3215031751) // strong pseudoprime to bases 2,3,5,7
	assert is_prime(1000000007)
	assert primes_up_to(30) == [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
	assert primes_up_to(1) == []int{}
	assert prime_factors(360) == [u64(2), 2, 2, 3, 3, 5]
	assert prime_factors(97) == [u64(97)]
	assert isqrt(0) == 0 && isqrt(15) == 3 && isqrt(16) == 4
	assert isqrt(18446744073709551615) == 4294967295
}

fn test_vectors_and_geometry() {
	v := Vec2{3, 4}
	assert v.length() == 5
	assert v.normalize().length() == 1
	assert v.dot(Vec2{1, 0}) == 3
	assert Vec2{1, 0}.cross(Vec2{0, 1}) == 1
	r := Vec2{1, 0}.rotate(math.pi / 2)
	assert approx_equal(r.x, 0, 0, 1e-12) && approx_equal(r.y, 1, 0, 1e-12)
	square := [Vec2{0, 0}, Vec2{4, 0}, Vec2{4, 4}, Vec2{0, 4}]
	assert polygon_area(square) == 16
	c := polygon_centroid(square)
	assert c.x == 2 && c.y == 2
	assert point_in_polygon(Vec2{1, 1}, square)
	assert !point_in_polygon(Vec2{5, 1}, square)
	cloud := [Vec2{0, 0}, Vec2{2, 2}, Vec2{4, 0}, Vec2{4, 4},
		Vec2{0, 4}, Vec2{1, 3}, Vec2{2, 0}]
	hull := convex_hull(cloud)
	assert hull.len == 4
	assert polygon_area(hull) == 16
	// London -> Paris is ~343.5 km.
	d := haversine_km(51.5074, -0.1278, 48.8566, 2.3522)
	assert d > 343 && d < 344.5
}
