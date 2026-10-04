module statutils

import math

// ============================================================================
// Streaming statistics (Welford / Chan et al.) — numerically stable, O(1) memory
// ============================================================================

// RunningStats accumulates count, mean, variance, min and max in a single pass.
pub struct RunningStats {
pub mut:
	n    i64
	mean f64
	m2   f64
	min  f64 = math.inf(1)
	max  f64 = math.inf(-1)
}

// push adds one observation.
pub fn (mut r RunningStats) push(x f64) {
	r.n++
	d := x - r.mean
	r.mean += d / f64(r.n)
	r.m2 += d * (x - r.mean)
	if x < r.min {
		r.min = x
	}
	if x > r.max {
		r.max = x
	}
}

// push_all adds many observations.
pub fn (mut r RunningStats) push_all(xs []f64) {
	for x in xs {
		r.push(x)
	}
}

// variance returns the population variance.
pub fn (r RunningStats) variance() f64 {
	return if r.n > 0 { r.m2 / f64(r.n) } else { 0.0 }
}

// sample_variance returns the Bessel-corrected variance.
pub fn (r RunningStats) sample_variance() f64 {
	return if r.n > 1 { r.m2 / f64(r.n - 1) } else { 0.0 }
}

// std_dev returns the population standard deviation.
pub fn (r RunningStats) std_dev() f64 {
	return math.sqrt(r.variance())
}

// sample_std_dev returns the sample standard deviation.
pub fn (r RunningStats) sample_std_dev() f64 {
	return math.sqrt(r.sample_variance())
}

// merge combines two accumulators (parallel/distributed aggregation).
pub fn (r RunningStats) merge(o RunningStats) RunningStats {
	if r.n == 0 {
		return o
	}
	if o.n == 0 {
		return r
	}
	n := r.n + o.n
	d := o.mean - r.mean
	return RunningStats{
		n:    n
		mean: r.mean + d * f64(o.n) / f64(n)
		m2:   r.m2 + o.m2 + d * d * f64(r.n) * f64(o.n) / f64(n)
		min:  math.min(r.min, o.min)
		max:  math.max(r.max, o.max)
	}
}

// ============================================================================
// Histograms
// ============================================================================

// Bin is one histogram bucket [lo, hi) (the last bin is closed).
pub struct Bin {
pub:
	lo    f64
	hi    f64
	count int
}

// histogram splits data into `bins` equal-width buckets.
pub fn histogram(arr []f64, bins int) []Bin {
	if arr.len == 0 || bins <= 0 {
		return []
	}
	mut lo := arr[0]
	mut hi := arr[0]
	for x in arr {
		lo = math.min(lo, x)
		hi = math.max(hi, x)
	}
	if lo == hi {
		return [Bin{lo, hi, arr.len}]
	}
	w := (hi - lo) / f64(bins)
	mut counts := []int{len: bins}
	for x in arr {
		mut i := int((x - lo) / w)
		if i >= bins {
			i = bins - 1
		}
		counts[i]++
	}
	return []Bin{len: bins, init: Bin{lo + f64(index) * w, if index == bins - 1 {
		hi
	} else {
		lo + f64(index + 1) * w
	}, counts[index]}}
}

// ============================================================================
// Distributions
// ============================================================================

// stats_normal_quantile returns the inverse standard-normal CDF (probit) for p in (0,1),
// using Acklam's algorithm refined by one Halley step (|error| < 1e-12).
pub fn stats_normal_quantile(p f64) f64 {
	if p <= 0 {
		return math.inf(-1)
	}
	if p >= 1 {
		return math.inf(1)
	}
	a := [-3.969683028665376e+01, 2.209460984245205e+02, -2.759285104469687e+02, 1.383577518672690e+02,
		-3.066479806614716e+01, 2.506628277459239e+00]
	b := [-5.447609879822406e+01, 1.615858368580409e+02, -1.556989798598866e+02, 6.680131188771972e+01,
		-1.328068155288572e+01]
	c := [-7.784894002430293e-03, -3.223964580411365e-01, -2.400758277161838e+00,
		-2.549732539343734e+00, 4.374664141464968e+00, 2.938163982698783e+00]
	d := [7.784695709041462e-03, 3.224671290700398e-01, 2.445134137142996e+00, 3.754408661907416e+00]
	plow := 0.02425
	mut x := 0.0
	if p < plow {
		q := math.sqrt(-2 * math.log(p))
		x = (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) / ((((d[0] * q +
			d[1]) * q + d[2]) * q + d[3]) * q + 1)
	} else if p <= 1 - plow {
		q := p - 0.5
		r := q * q
		x = (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) * q / (((((b[0] * r +
			b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1)
	} else {
		q := math.sqrt(-2 * math.log(1 - p))
		x = -(((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) / ((((d[0] * q +
			d[1]) * q + d[2]) * q + d[3]) * q + 1)
	}
	e := 0.5 * math.erfc(-x / math.sqrt2) - p
	u := e * math.sqrt(2 * math.pi) * math.exp(x * x / 2)
	return x - u / (1 + x * u / 2)
}

// continued fraction for the regularized incomplete beta (Numerical Recipes betacf).
fn betacf(a f64, b f64, x f64) f64 {
	eps := 3.0e-15
	fpmin := 1.0e-300
	qab := a + b
	qap := a + 1
	qam := a - 1
	mut c := 1.0
	mut d := 1 - qab * x / qap
	if math.abs(d) < fpmin {
		d = fpmin
	}
	d = 1 / d
	mut h := d
	for m in 1 .. 300 {
		m2 := 2 * f64(m)
		mut aa := f64(m) * (b - f64(m)) * x / ((qam + m2) * (a + m2))
		d = 1 + aa * d
		if math.abs(d) < fpmin {
			d = fpmin
		}
		c = 1 + aa / c
		if math.abs(c) < fpmin {
			c = fpmin
		}
		d = 1 / d
		h *= d * c
		aa = -(a + f64(m)) * (qab + f64(m)) * x / ((a + m2) * (qap + m2))
		d = 1 + aa * d
		if math.abs(d) < fpmin {
			d = fpmin
		}
		c = 1 + aa / c
		if math.abs(c) < fpmin {
			c = fpmin
		}
		d = 1 / d
		del := d * c
		h *= del
		if math.abs(del - 1) < eps {
			break
		}
	}
	return h
}

// stats_incomplete_beta returns the regularized incomplete beta function I_x(a, b).
pub fn stats_incomplete_beta(x f64, a f64, b f64) f64 {
	if x <= 0 {
		return 0
	}
	if x >= 1 {
		return 1
	}
	bt := math.exp(math.log_gamma(a + b) - math.log_gamma(a) - math.log_gamma(b) + a * math.log(x) +
		b * math.log(1 - x))
	if x < (a + 1) / (a + b + 2) {
		return bt * betacf(a, b, x) / a
	}
	return 1 - bt * betacf(b, a, 1 - x) / b
}

// stats_t_cdf returns the Student-t cumulative distribution P(T <= t) with `df` degrees of freedom.
pub fn stats_t_cdf(t f64, df f64) f64 {
	x := df / (df + t * t)
	tail := 0.5 * stats_incomplete_beta(x, df / 2, 0.5)
	return if t >= 0 { 1 - tail } else { tail }
}

// TTestResult holds the outcome of a two-sample t-test.
pub struct TTestResult {
pub:
	t       f64
	df      f64
	p_value f64 // two-sided
	mean_a  f64
	mean_b  f64
}

// stats_welch_t_test performs Welch's unequal-variance two-sample t-test.
pub fn stats_welch_t_test(a []f64, b []f64) !TTestResult {
	if a.len < 2 || b.len < 2 {
		return error('each sample needs at least 2 observations')
	}
	ma := stats_mean(a)
	mb := stats_mean(b)
	va := stats_sample_variance(a) / f64(a.len)
	vb := stats_sample_variance(b) / f64(b.len)
	if va + vb == 0 {
		return error('both samples have zero variance')
	}
	t := (ma - mb) / math.sqrt(va + vb)
	df := (va + vb) * (va + vb) / (va * va / f64(a.len - 1) + vb * vb / f64(b.len - 1))
	p := 2 * (1 - stats_t_cdf(math.abs(t), df))
	return TTestResult{t, df, math.min(1.0, math.max(0.0, p)), ma, mb}
}

// stats_confidence_interval returns the (lo, hi) normal-approximation confidence interval
// for the mean at `confidence` (e.g. 0.95). For small n prefer a t-based interval.
pub fn stats_confidence_interval(arr []f64, confidence f64) !(f64, f64) {
	if arr.len < 2 {
		return error('need at least 2 observations')
	}
	if confidence <= 0 || confidence >= 1 {
		return error('confidence must be in (0, 1)')
	}
	z := stats_normal_quantile(0.5 + confidence / 2)
	m := stats_mean(arr)
	se := stats_standard_error(arr)
	return m - z * se, m + z * se
}
