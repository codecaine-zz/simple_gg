module mathutils

import math
import math.bits

// ============================================================================
// 4. Floating point & numerics
// ============================================================================

// approx_equal compares floats with combined absolute and relative tolerance (Python's math.isclose).
pub fn approx_equal(a f64, b f64, rel_tol f64, abs_tol f64) bool {
	if a == b {
		return true
	}
	if math.is_nan(a) || math.is_nan(b) || math.is_inf(a, 0) || math.is_inf(b, 0) {
		return false
	}
	diff := math.abs(a - b)
	return diff <= math.max(rel_tol * math.max(math.abs(a), math.abs(b)), abs_tol)
}

// round_to rounds v to the given number of decimal places (half away from zero).
pub fn round_to(v f64, decimals int) f64 {
	p := math.pow(10, f64(decimals))
	return math.round(v * p) / p
}

// sign returns -1, 0 or 1 according to the sign of v.
pub fn sign(v f64) int {
	return if v > 0 {
		1
	} else if v < 0 {
		-1
	} else {
		0
	}
}

// smoothstep performs Hermite interpolation between edge0 and edge1 (0 below, 1 above, smooth in between).
pub fn smoothstep(edge0 f64, edge1 f64, x f64) f64 {
	t := clamp(inverse_lerp(edge0, edge1, x), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
}

// wrap maps v into the half-open range [min, max) (e.g. wrap(370, 0, 360) == 10).
pub fn wrap(v f64, min f64, max f64) f64 {
	range := max - min
	if range == 0 {
		return min
	}
	mut r := math.fmod(v - min, range)
	if r < 0 {
		r += range
	}
	return r + min
}

// percent returns part as a percentage of whole (0 when whole is 0).
pub fn percent(part f64, whole f64) f64 {
	return if whole == 0 { 0.0 } else { part / whole * 100.0 }
}

// percent_change returns the percentage change from old to new (e.g. 50 -> 75 == 50.0).
pub fn percent_change(old f64, new f64) f64 {
	return if old == 0 { 0.0 } else { (new - old) / math.abs(old) * 100.0 }
}

// kahan_sum sums floats with Neumaier compensated summation, eliminating most rounding error.
pub fn kahan_sum(values []f64) f64 {
	mut sum := 0.0
	mut c := 0.0
	for v in values {
		t := sum + v
		if math.abs(sum) >= math.abs(v) {
			c += (sum - t) + v
		} else {
			c += (v - t) + sum
		}
		sum = t
	}
	return sum + c
}

// ============================================================================
// 5. Overflow-checked integer arithmetic
// ============================================================================

// checked_add returns a + b, or none on i64 overflow.
pub fn checked_add(a i64, b i64) ?i64 {
	if (b > 0 && a > max_i64 - b) || (b < 0 && a < min_i64 - b) {
		return none
	}
	return a + b
}

// checked_sub returns a - b, or none on i64 overflow.
pub fn checked_sub(a i64, b i64) ?i64 {
	if (b < 0 && a > max_i64 + b) || (b > 0 && a < min_i64 + b) {
		return none
	}
	return a - b
}

// checked_mul returns a * b, or none on i64 overflow.
pub fn checked_mul(a i64, b i64) ?i64 {
	if a == 0 || b == 0 {
		return 0
	}
	if (a == -1 && b == min_i64) || (b == -1 && a == min_i64) {
		return none
	}
	r := a * b
	if r / b != a {
		return none
	}
	return r
}

// ============================================================================
// 6. Number theory
// ============================================================================

// factorial returns n! or none if it does not fit in u64 (n > 20).
pub fn factorial(n int) ?u64 {
	if n < 0 || n > 20 {
		return none
	}
	mut r := u64(1)
	for i in 2 .. n + 1 {
		r *= u64(i)
	}
	return r
}

// binomial returns "n choose k", or none on u64 overflow. Uses gcd reduction so intermediate
// values stay as small as possible (binomial(66, 33) still fits).
pub fn binomial(n int, k int) ?u64 {
	if k < 0 || n < 0 || k > n {
		return u64(0)
	}
	kk := if k > n - k { n - k } else { k }
	mut r := u64(1)
	for i in 1 .. kk + 1 {
		mut num := u64(n - kk + i)
		mut den := u64(i)
		g1 := u64(gcd(i64(r), i64(den)))
		r /= g1
		den /= g1
		g2 := u64(gcd(i64(num), i64(den)))
		num /= g2
		den /= g2
		hi, lo := bits.mul_64(r, num)
		if hi != 0 {
			return none
		}
		r = lo / den
	}
	return r
}

// fibonacci returns the nth Fibonacci number (F0 = 0) or none if n > 93 (u64 overflow).
pub fn fibonacci(n int) ?u64 {
	if n < 0 || n > 93 {
		return none
	}
	mut a, mut b := u64(0), u64(1)
	for _ in 0 .. n {
		a, b = b, a + b
	}
	return a
}

fn mul_mod(a u64, b u64, m u64) u64 {
	hi, lo := bits.mul_64(a % m, b % m)
	_, rem := bits.div_64(hi, lo, m)
	return rem
}

// mod_pow computes (base ^ exp) mod m without overflow (square-and-multiply).
pub fn mod_pow(base u64, exp u64, m u64) u64 {
	if m == 1 {
		return 0
	}
	mut result := u64(1)
	mut b := base % m
	mut e := exp
	for e > 0 {
		if e & 1 == 1 {
			result = mul_mod(result, b, m)
		}
		b = mul_mod(b, b, m)
		e >>= 1
	}
	return result
}

// mod_inverse returns x such that (a * x) mod m == 1, or none if a and m are not coprime.
pub fn mod_inverse(a i64, m i64) ?i64 {
	if m <= 1 {
		return none
	}
	mut old_r, mut r := ((a % m) + m) % m, m
	mut old_s, mut s := i64(1), i64(0)
	for r != 0 {
		q := old_r / r
		old_r, r = r, old_r - q * r
		old_s, s = s, old_s - q * s
	}
	if old_r != 1 {
		return none
	}
	return ((old_s % m) + m) % m
}

// is_prime is a deterministic Miller-Rabin primality test, exact for every u64.
pub fn is_prime(n u64) bool {
	if n < 2 {
		return false
	}
	small := [u64(2), 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]
	for p in small {
		if n % p == 0 {
			return n == p
		}
	}
	mut d := n - 1
	mut r := 0
	for d & 1 == 0 {
		d >>= 1
		r++
	}
	for a in small {
		mut x := mod_pow(a, d, n)
		if x == 1 || x == n - 1 {
			continue
		}
		mut composite := true
		for _ in 1 .. r {
			x = mul_mod(x, x, n)
			if x == n - 1 {
				composite = false
				break
			}
		}
		if composite {
			return false
		}
	}
	return true
}

// primes_up_to returns all primes <= limit using the Sieve of Eratosthenes.
pub fn primes_up_to(limit int) []int {
	if limit < 2 {
		return []int{}
	}
	mut composite := []bool{len: limit + 1}
	mut primes := []int{}
	for i in 2 .. limit + 1 {
		if composite[i] {
			continue
		}
		primes << i
		for j := i64(i) * i; j <= limit; j += i {
			composite[int(j)] = true
		}
	}
	return primes
}

// prime_factors returns the prime factorisation of n in ascending order (e.g. 360 -> [2,2,2,3,3,5]).
pub fn prime_factors(n u64) []u64 {
	mut res := []u64{}
	mut x := n
	if x < 2 {
		return res
	}
	for x % 2 == 0 {
		res << 2
		x /= 2
	}
	mut f := u64(3)
	for f <= x / f {
		for x % f == 0 {
			res << f
			x /= f
		}
		f += 2
	}
	if x > 1 {
		res << x
	}
	return res
}

// isqrt returns floor(sqrt(n)) exactly for every u64 (no floating point error).
pub fn isqrt(n u64) u64 {
	if n < 2 {
		return n
	}
	mut x := u64(math.sqrt(f64(n)))
	for x > 0 && x > n / x {
		x--
	}
	for (x + 1) <= n / (x + 1) {
		x++
	}
	return x
}

// ============================================================================
// 7. Vectors & computational geometry
// ============================================================================

// Vec2 is a 2D vector of f64 with the usual operations.
pub struct Vec2 {
pub:
	x f64
	y f64
}

// add returns a + b.
pub fn (a Vec2) add(b Vec2) Vec2 {
	return Vec2{a.x + b.x, a.y + b.y}
}

// sub returns a - b.
pub fn (a Vec2) sub(b Vec2) Vec2 {
	return Vec2{a.x - b.x, a.y - b.y}
}

// scale returns a * k.
pub fn (a Vec2) scale(k f64) Vec2 {
	return Vec2{a.x * k, a.y * k}
}

// dot returns the dot product.
pub fn (a Vec2) dot(b Vec2) f64 {
	return a.x * b.x + a.y * b.y
}

// cross returns the z component of the 3D cross product (positive when b is counter-clockwise of a).
pub fn (a Vec2) cross(b Vec2) f64 {
	return a.x * b.y - a.y * b.x
}

// length returns the Euclidean length.
pub fn (a Vec2) length() f64 {
	return math.hypot(a.x, a.y)
}

// normalize returns a unit vector in the same direction (zero vector stays zero).
pub fn (a Vec2) normalize() Vec2 {
	l := a.length()
	return if l == 0 { a } else { a.scale(1.0 / l) }
}

// rotate returns the vector rotated by angle radians counter-clockwise.
pub fn (a Vec2) rotate(angle f64) Vec2 {
	c := math.cos(angle)
	s := math.sin(angle)
	return Vec2{a.x * c - a.y * s, a.x * s + a.y * c}
}

// polygon_area returns the signed area via the shoelace formula (positive for counter-clockwise).
pub fn polygon_area(pts []Vec2) f64 {
	if pts.len < 3 {
		return 0.0
	}
	mut s := 0.0
	for i in 0 .. pts.len {
		s += pts[i].cross(pts[(i + 1) % pts.len])
	}
	return s / 2.0
}

// polygon_centroid returns the centroid of a simple polygon (falls back to vertex mean if degenerate).
pub fn polygon_centroid(pts []Vec2) Vec2 {
	a := polygon_area(pts)
	if pts.len == 0 {
		return Vec2{}
	}
	if a == 0 {
		mut sx, mut sy := 0.0, 0.0
		for p in pts {
			sx += p.x
			sy += p.y
		}
		return Vec2{sx / pts.len, sy / pts.len}
	}
	mut cx, mut cy := 0.0, 0.0
	for i in 0 .. pts.len {
		p := pts[i]
		q := pts[(i + 1) % pts.len]
		f := p.cross(q)
		cx += (p.x + q.x) * f
		cy += (p.y + q.y) * f
	}
	return Vec2{cx / (6 * a), cy / (6 * a)}
}

// point_in_polygon tests containment with the even-odd ray casting rule.
pub fn point_in_polygon(p Vec2, pts []Vec2) bool {
	mut inside := false
	mut j := pts.len - 1
	for i in 0 .. pts.len {
		a := pts[i]
		b := pts[j]
		if (a.y > p.y) != (b.y > p.y) && p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x {
			inside = !inside
		}
		j = i
	}
	return inside
}

// convex_hull returns the hull in counter-clockwise order using Andrew's monotone chain, O(n log n).
// Collinear boundary points are omitted.
pub fn convex_hull(points []Vec2) []Vec2 {
	mut pts := points.clone()
	if pts.len < 3 {
		return pts
	}
	pts.sort_with_compare(fn (a &Vec2, b &Vec2) int {
		if a.x != b.x {
			return if a.x < b.x { -1 } else { 1 }
		}
		return if a.y < b.y {
			-1
		} else if a.y > b.y {
			1
		} else {
			0
		}
	})
	mut hull := []Vec2{}
	for p in pts {
		for hull.len >= 2 && hull[hull.len - 1].sub(hull[hull.len - 2]).cross(p.sub(hull[hull.len - 2])) <= 0 {
			hull.delete_last()
		}
		hull << p
	}
	lower_len := hull.len + 1
	for i := pts.len - 2; i >= 0; i-- {
		p := pts[i]
		for hull.len >= lower_len
			&& hull[hull.len - 1].sub(hull[hull.len - 2]).cross(p.sub(hull[hull.len - 2])) <= 0 {
			hull.delete_last()
		}
		hull << p
	}
	hull.delete_last()
	return hull
}

const earth_radius_km = 6371.0088

// haversine_km returns the great-circle distance in kilometres between two lat/lon points in degrees.
pub fn haversine_km(lat1 f64, lon1 f64, lat2 f64, lon2 f64) f64 {
	p1 := deg_to_rad(lat1)
	p2 := deg_to_rad(lat2)
	dp := deg_to_rad(lat2 - lat1)
	dl := deg_to_rad(lon2 - lon1)
	a := math.sin(dp / 2) * math.sin(dp / 2) + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) * math.sin(dl / 2)
	return 2 * earth_radius_km * math.asin(math.sqrt(math.min(1.0, a)))
}
