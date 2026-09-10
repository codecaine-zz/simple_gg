module statutils

import math

fn test_statistical_calculations() {
	data := [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]

	// Sum & Mean: (2+4+4+4+5+5+7+9) = 40; 40 / 8 = 5.0
	assert stats_sum(data) == 40.0
	assert stats_mean(data) == 5.0

	// Median: (4+5)/2 = 4.5
	assert stats_median(data) == 4.5

	// Mode: 4.0
	assert stats_mode(data) or { 0.0 } == 4.0

	// Variance (pop): 32/8 = 4.0
	assert stats_variance(data) == 4.0

	// Sample Variance: 32/7 ~= 4.5714
	sample_var := stats_sample_variance(data)
	assert math.abs(sample_var - (32.0 / 7.0)) < 0.001

	// Std Dev (pop): sqrt(4) = 2.0
	assert stats_std_dev(data) == 2.0

	// Sample Std Dev: sqrt(32/7) ~= 2.138
	assert math.abs(stats_sample_std_dev(data) - math.sqrt(32.0 / 7.0)) < 0.001

	// SEM: sample_std / sqrt(8)
	sem := stats_standard_error(data)
	assert sem > 0.7 && sem < 0.8

	// Min / Max / Range
	assert stats_min(data) or { 0.0 } == 2.0
	assert stats_max(data) or { 0.0 } == 9.0
	assert stats_range(data) == 7.0

	// Percentiles & Quartiles
	p50 := stats_percentile(data, 50.0)
	assert math.abs(p50 - 4.5) < 0.01

	q1, q2, q3 := stats_quartiles(data)
	assert q2 == 4.5
	assert q3 > q1
	assert stats_iqr(data) == q3 - q1

	// Geometric & Harmonic mean
	positives := [1.0, 2.0, 4.0]
	geo := stats_geometric_mean(positives)
	assert math.abs(geo - 2.0) < 0.01

	harm := stats_harmonic_mean(positives)
	assert harm > 1.0 && harm < 2.0

	// RMS
	rms := stats_rms([3.0, 4.0])
	assert math.abs(rms - math.sqrt(12.5)) < 0.01

	// Weighted Mean
	w_vals := [10.0, 20.0, 30.0]
	weights := [1.0, 2.0, 3.0]
	// (10*1 + 20*2 + 30*3) / (1+2+3) = (10+40+90)/6 = 140/6 = 23.333
	w_mean := stats_weighted_mean(w_vals, weights) or { 0.0 }
	assert math.abs(w_mean - (140.0 / 6.0)) < 0.001

	// Trimmed Mean (10% trim of 10 items trims 1 lowest and 1 highest)
	trim_data := [-100.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 100.0]
	t_mean := stats_trimmed_mean(trim_data, 0.1) or { 0.0 }
	// remaining: [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0] -> mean = 44.0 / 8 = 5.5
	assert math.abs(t_mean - 5.5) < 0.001

	// Coefficient of variation & MAD
	cv := stats_coefficient_of_variation(data)
	assert math.abs(cv - (2.0 / 5.0)) < 0.001

	mad := stats_median_abs_deviation(data)
	assert mad >= 0.0

	// Skewness and Kurtosis
	sym_data := [1.0, 2.0, 3.0, 4.0, 5.0]
	assert math.abs(stats_skewness(sym_data)) < 0.001 // symmetric dataset has skewness 0
	_ = stats_kurtosis(data)
}

fn test_bivariate_analysis() {
	x := [1.0, 2.0, 3.0, 4.0, 5.0]
	y := [2.0, 4.0, 6.0, 8.0, 10.0] // perfect linear relationship y = 2x

	// Covariance
	cov := stats_covariance(x, y) or { 0.0 }
	assert cov == 4.0

	sample_cov := stats_sample_covariance(x, y) or { 0.0 }
	assert sample_cov == 5.0

	// Pearson Correlation: r = 1.0
	r := stats_pearson_correlation(x, y) or { 0.0 }
	assert math.abs(r - 1.0) < 0.0001

	// Spearman Rank Correlation: r_s = 1.0
	r_s := stats_spearman_correlation(x, y) or { 0.0 }
	assert math.abs(r_s - 1.0) < 0.0001

	// Linear Regression
	lr := stats_linear_regression(x, y) or { panic('Regression failed') }
	assert math.abs(lr.slope - 2.0) < 0.0001
	assert math.abs(lr.intercept - 0.0) < 0.0001
	assert math.abs(lr.r_squared - 1.0) < 0.0001
}

fn test_distributions_and_outliers() {
	// Normal PDF and CDF
	// At mean x=0, std=1: pdf = 1/sqrt(2*pi) ~= 0.3989, cdf = 0.5
	pdf := stats_normal_pdf(0.0, 0.0, 1.0)
	assert math.abs(pdf - 0.398942) < 0.001

	cdf := stats_normal_cdf(0.0, 0.0, 1.0)
	assert math.abs(cdf - 0.5) < 0.0001

	// Z-Scores
	z := stats_z_score(15.0, 10.0, 2.5)
	assert z == 2.0

	arr := [10.0, 20.0, 30.0]
	zs := stats_z_scores(arr)
	assert zs.len == 3
	assert math.abs(zs[1]) < 0.0001 // middle item is at mean

	// Min-Max Normalization
	norm := stats_min_max_normalize([10.0, 20.0, 30.0])
	assert norm[0] == 0.0
	assert norm[1] == 0.5
	assert norm[2] == 1.0

	// Outlier Detection
	outlier_data := [10.0, 11.0, 12.0, 11.5, 10.5, 100.0]
	outliers_iqr := stats_outliers_iqr(outlier_data, 1.5)
	assert outliers_iqr.len == 1
	assert outliers_iqr[0] == 100.0

	outliers_z := stats_outliers_z_score(outlier_data, 2.0)
	assert outliers_z.contains(100.0)
}

fn test_time_series_and_summary() {
	ts := [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]

	// Moving Average window 3:
	// [(1+2+3)/3=2, (2+3+4)/3=3, (3+4+5)/3=4, (4+5+6)/3=5]
	ma := stats_moving_average(ts, 3) or { []f64{} }
	assert ma.len == 4
	assert ma[0] == 2.0
	assert ma[1] == 3.0
	assert ma[2] == 4.0
	assert ma[3] == 5.0

	// EMA
	ema := stats_exponential_moving_average(ts, 0.5) or { []f64{} }
	assert ema.len == 6
	assert ema[0] == 1.0

	// Comprehensive Summary
	sum_prof := stats_summary(ts)
	assert sum_prof.count == 6
	assert sum_prof.min == 1.0
	assert sum_prof.max == 6.0
	assert sum_prof.range == 5.0
	assert sum_prof.sum == 21.0
	assert sum_prof.mean == 3.5
	assert sum_prof.median == 3.5
	assert sum_prof.sample_variance > sum_prof.variance
}
