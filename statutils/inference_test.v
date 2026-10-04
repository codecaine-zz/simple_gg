module statutils

import math

fn close(a f64, b f64, eps f64) bool {
	return math.abs(a - b) <= eps
}

fn test_running_stats_matches_batch_and_merge() {
	data := [2.0, 4, 4, 4, 5, 5, 7, 9]
	mut r := RunningStats{}
	r.push_all(data)
	assert r.n == 8
	assert r.mean == 5.0
	assert close(r.std_dev(), 2.0, 1e-12)
	assert close(r.sample_variance(), stats_sample_variance(data), 1e-12)
	assert r.min == 2 && r.max == 9
	mut a := RunningStats{}
	mut b := RunningStats{}
	a.push_all(data[..3])
	b.push_all(data[3..])
	m := a.merge(b)
	assert close(m.mean, r.mean, 1e-12) && close(m.m2, r.m2, 1e-9)
	assert m.min == 2 && m.max == 9
	// Catastrophic-cancellation case: huge offset, tiny variance.
	mut big := RunningStats{}
	big.push_all([1e9 + 4, 1e9 + 7, 1e9 + 13, 1e9 + 16])
	assert close(big.sample_variance(), 30.0, 1e-6)
}

fn test_histogram() {
	h := histogram([1.0, 2, 2, 3, 3, 3, 4, 4, 4, 4], 4)
	assert h.map(it.count) == [1, 2, 3, 4]
	assert h[0].lo == 1 && h[3].hi == 4
	assert histogram([5.0, 5], 3).len == 1
	assert histogram([]f64{}, 3).len == 0
}

fn test_normal_quantile_reference() {
	assert close(stats_normal_quantile(0.5), 0, 1e-12)
	assert close(stats_normal_quantile(0.975), 1.959963984540054, 1e-9)
	assert close(stats_normal_quantile(0.001), -3.090232306167814, 1e-9)
	for p in [0.01, 0.2, 0.7, 0.999] {
		assert close(stats_normal_cdf(stats_normal_quantile(p), 0, 1), p, 1e-9)
	}
}

fn test_t_distribution_reference() {
	// Known critical values: t_{0.975, 10} = 2.228139, t_{0.95, 5} = 2.015048
	assert close(stats_t_cdf(2.228138851986, 10), 0.975, 1e-7)
	assert close(stats_t_cdf(2.015048372669, 5), 0.95, 1e-7)
	assert close(stats_t_cdf(0, 3), 0.5, 1e-12)
	assert close(stats_incomplete_beta(0.5, 2, 2), 0.5, 1e-12)
}

fn test_welch_t_test() {
	a := [27.5, 21.0, 19.0, 23.6, 17.0, 17.9, 16.9, 20.1, 21.9, 22.6, 23.1, 19.6, 19.0, 21.7, 21.4]
	b := [27.1, 22.0, 20.8, 23.4, 23.4, 23.5, 25.8, 22.0, 24.8, 20.2, 21.9, 22.1, 22.9, 20.5, 24.4]
	r := stats_welch_t_test(a, b)!
	// Reference: SciPy ttest_ind(a, b, equal_var=False)
	assert close(r.t, -2.455356398286006, 1e-9)
	assert close(r.df, 24.988529290231416, 1e-9)
	assert close(r.p_value, 0.021378001462867, 1e-7)
	if _ := stats_welch_t_test([1.0], [2.0, 3]) {
		assert false
	}
	lo, hi := stats_confidence_interval([1.0, 2, 3, 4, 5], 0.95)!
	assert lo < 3 && hi > 3
}
