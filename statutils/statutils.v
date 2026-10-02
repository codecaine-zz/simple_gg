module statutils

import arrays
import math
import math.stats as vstats

// ============================================================================
// Data Models
// ============================================================================

// LinearRegressionResult represents the output of simple ordinary least squares regression.
pub struct LinearRegressionResult {
pub:
	slope       f64
	intercept   f64
	r_squared   f64
	correlation f64
}

// SummaryStats contains a comprehensive descriptive profile of a dataset.
pub struct SummaryStats {
pub:
	count           int
	min             f64
	max             f64
	range           f64
	sum             f64
	mean            f64
	median          f64
	variance        f64
	sample_variance f64
	std_dev         f64
	sample_std_dev  f64
	sem             f64
	q1              f64
	q3              f64
	iqr             f64
	skewness        f64
	kurtosis        f64
}

// ============================================================================
// 1. Measures of Central Tendency
// ============================================================================

// stats_sum returns the arithmetic sum of all numbers in the slice using V's built-in arrays.sum.
pub fn stats_sum(arr []f64) f64 {
	return arrays.sum(arr) or { 0.0 }
}

// stats_mean returns the arithmetic average of a numeric slice using V's built-in math.stats.mean.
pub fn stats_mean(arr []f64) f64 {
	return vstats.mean(arr)
}

// stats_median returns the median value of a numeric slice using V's built-in math.stats.median.
pub fn stats_median(arr []f64) f64 {
	if arr.len == 0 {
		return 0.0
	}
	mut sorted := arr.clone()
	sorted.sort()
	return vstats.median(sorted)
}

// stats_mode returns the most frequently occurring value in the slice using V's built-in math.stats.mode.
pub fn stats_mode(arr []f64) ?f64 {
	if arr.len == 0 {
		return none
	}
	return vstats.mode(arr)
}

// stats_geometric_mean computes the geometric mean using V's built-in math.stats.geometric_mean.
pub fn stats_geometric_mean(arr []f64) f64 {
	return vstats.geometric_mean(arr)
}

// stats_harmonic_mean computes the harmonic mean using V's built-in math.stats.harmonic_mean.
pub fn stats_harmonic_mean(arr []f64) f64 {
	return vstats.harmonic_mean(arr)
}

// stats_rms computes the Root Mean Square (quadratic mean) using V's built-in math.stats.rms.
pub fn stats_rms(arr []f64) f64 {
	return vstats.rms(arr)
}

// stats_weighted_mean computes the weighted average of values given a slice of weights.
pub fn stats_weighted_mean(arr []f64, weights []f64) !f64 {
	if arr.len == 0 {
		return error('Cannot compute weighted mean of an empty array')
	}
	if arr.len != weights.len {
		return error('Values and weights slices must have the same length (${arr.len} vs ${weights.len})')
	}
	mut sum_w := 0.0
	mut sum_wx := 0.0
	for i, x in arr {
		w := weights[i]
		sum_wx += x * w
		sum_w += w
	}
	if sum_w == 0.0 {
		return error('Weights sum to zero; cannot divide by zero')
	}
	return sum_wx / sum_w
}

// stats_trimmed_mean computes the mean after discarding a proportion of the lowest and highest values.
// Proportion must be between 0.0 (inclusive) and 0.5 (exclusive), e.g. 0.1 for 10% trimmed mean.
pub fn stats_trimmed_mean(arr []f64, proportion f64) !f64 {
	if arr.len == 0 {
		return error('Cannot compute trimmed mean of an empty array')
	}
	if proportion < 0.0 || proportion >= 0.5 {
		return error('Trim proportion must be in range [0.0, 0.5)')
	}
	mut sorted := arr.clone()
	sorted.sort()
	k := int(math.floor(f64(sorted.len) * proportion))
	if k == 0 {
		return stats_mean(sorted)
	}
	trimmed := sorted[k..sorted.len - k].clone()
	return stats_mean(trimmed)
}

// ============================================================================
// 2. Measures of Dispersion and Spread
// ============================================================================

// stats_min returns the minimum value in the slice using V's built-in math.stats.min.
pub fn stats_min(arr []f64) ?f64 {
	if arr.len == 0 {
		return none
	}
	return vstats.min(arr)
}

// stats_max returns the maximum value in the slice using V's built-in math.stats.max.
pub fn stats_max(arr []f64) ?f64 {
	if arr.len == 0 {
		return none
	}
	return vstats.max(arr)
}

// stats_range computes the difference between the maximum and minimum values using V's built-in math.stats.range.
pub fn stats_range(arr []f64) f64 {
	return vstats.range(arr)
}

// stats_variance computes the population variance using V's built-in math.stats.population_variance.
pub fn stats_variance(arr []f64) f64 {
	return vstats.population_variance(arr)
}

// stats_sample_variance computes the sample variance (Bessel-corrected) using V's built-in math.stats.sample_variance.
pub fn stats_sample_variance(arr []f64) f64 {
	if arr.len <= 1 {
		return 0.0
	}
	return vstats.sample_variance(arr)
}

// stats_std_dev computes the population standard deviation using V's built-in math.stats.population_stddev.
pub fn stats_std_dev(arr []f64) f64 {
	return vstats.population_stddev(arr)
}

// stats_sample_std_dev computes the sample standard deviation using V's built-in math.stats.sample_stddev.
pub fn stats_sample_std_dev(arr []f64) f64 {
	if arr.len <= 1 {
		return 0.0
	}
	return vstats.sample_stddev(arr)
}

// stats_standard_error computes the standard error of the mean (SEM = s / sqrt(N)).
pub fn stats_standard_error(arr []f64) f64 {
	if arr.len <= 1 {
		return 0.0
	}
	return stats_sample_std_dev(arr) / math.sqrt(f64(arr.len))
}

// stats_percentile computes the value at percentile p (0.0 to 100.0) with linear interpolation.
pub fn stats_percentile(arr []f64, p f64) f64 {
	if arr.len == 0 {
		return 0.0
	}
	if p <= 0.0 {
		return stats_min(arr) or { 0.0 }
	}
	if p >= 100.0 {
		return stats_max(arr) or { 0.0 }
	}
	mut sorted := arr.clone()
	sorted.sort()
	rank := (p / 100.0) * f64(sorted.len - 1)
	lower := int(math.floor(rank))
	upper := int(math.ceil(rank))
	weight := rank - f64(lower)
	return sorted[lower] * (1.0 - weight) + sorted[upper] * weight
}

// stats_quartiles returns the first (25%), second (50%/median), and third (75%) quartiles.
pub fn stats_quartiles(arr []f64) (f64, f64, f64) {
	if arr.len == 0 {
		return 0.0, 0.0, 0.0
	}
	q1 := stats_percentile(arr, 25.0)
	q2 := stats_median(arr)
	q3 := stats_percentile(arr, 75.0)
	return q1, q2, q3
}

// stats_iqr computes the Interquartile Range (IQR = Q3 - Q1).
pub fn stats_iqr(arr []f64) f64 {
	if arr.len == 0 {
		return 0.0
	}
	q1, _, q3 := stats_quartiles(arr)
	return q3 - q1
}

// stats_coefficient_of_variation computes the relative dispersion (std_dev / mean).
pub fn stats_coefficient_of_variation(arr []f64) f64 {
	mean := stats_mean(arr)
	if mean == 0.0 {
		return 0.0
	}
	return stats_std_dev(arr) / mean
}

// stats_median_abs_deviation computes the Median Absolute Deviation (MAD).
pub fn stats_median_abs_deviation(arr []f64) f64 {
	if arr.len == 0 {
		return 0.0
	}
	med := stats_median(arr)
	mut diffs := []f64{cap: arr.len}
	for x in arr {
		diffs << math.abs(x - med)
	}
	return stats_median(diffs)
}

// ============================================================================
// 3. Shape of Distribution (Higher Moments)
// ============================================================================

// stats_skewness computes Fisher-Pearson sample skewness using V's built-in math.stats.skew.
pub fn stats_skewness(arr []f64) f64 {
	if arr.len <= 2 {
		return 0.0
	}
	return vstats.skew(arr)
}

// stats_kurtosis computes excess kurtosis using V's built-in math.stats.kurtosis.
pub fn stats_kurtosis(arr []f64) f64 {
	if arr.len <= 3 {
		return 0.0
	}
	return vstats.kurtosis(arr)
}

// ============================================================================
// 4. Bivariate Analysis: Covariance, Correlation & Regression
// ============================================================================

// stats_covariance computes the population covariance using V's built-in math.stats.covariance.
pub fn stats_covariance(x []f64, y []f64) !f64 {
	if x.len == 0 || x.len != y.len {
		return error('Arrays must be non-empty and of identical length (${x.len} vs ${y.len})')
	}
	return vstats.covariance(x, y)
}

// stats_sample_covariance computes the unbiased sample covariance (divided by N - 1).
pub fn stats_sample_covariance(x []f64, y []f64) !f64 {
	if x.len <= 1 || x.len != y.len {
		return error('Arrays must have length > 1 and identical length (${x.len} vs ${y.len})')
	}
	mean_x := stats_mean(x)
	mean_y := stats_mean(y)
	mut sum := 0.0
	for i in 0 .. x.len {
		sum += (x[i] - mean_x) * (y[i] - mean_y)
	}
	return sum / f64(x.len - 1)
}

// stats_pearson_correlation calculates Pearson's correlation coefficient r (-1.0 to 1.0).
pub fn stats_pearson_correlation(x []f64, y []f64) !f64 {
	if x.len == 0 || x.len != y.len {
		return error('Arrays must be non-empty and of identical length')
	}
	std_x := stats_std_dev(x)
	std_y := stats_std_dev(y)
	if std_x == 0.0 || std_y == 0.0 {
		return 0.0
	}
	cov := stats_covariance(x, y)!
	return math.clamp(cov / (std_x * std_y), -1.0, 1.0)
}

struct IndexedValue {
	val f64
	idx int
}

// compute_ranks calculates fractional ranks (handling ties with the average rank).
fn compute_ranks(arr []f64) []f64 {
	mut items := []IndexedValue{cap: arr.len}
	for i, v in arr {
		items << IndexedValue{
			val: v
			idx: i
		}
	}
	items.sort(a.val < b.val)

	mut ranks := []f64{len: arr.len, init: 0.0}
	mut i := 0
	for i < items.len {
		mut j := i
		for j + 1 < items.len && items[j + 1].val == items[i].val {
			j++
		}
		// Average rank for ties (1-based ranking)
		avg_rank := f64(i + 1 + j + 1) / 2.0
		for k in i .. (j + 1) {
			ranks[items[k].idx] = avg_rank
		}
		i = j + 1
	}
	return ranks
}

// stats_spearman_correlation computes Spearman's rank correlation coefficient.
pub fn stats_spearman_correlation(x []f64, y []f64) !f64 {
	if x.len == 0 || x.len != y.len {
		return error('Arrays must be non-empty and of identical length')
	}
	rank_x := compute_ranks(x)
	rank_y := compute_ranks(y)
	return stats_pearson_correlation(rank_x, rank_y)
}

// stats_linear_regression computes simple Ordinary Least Squares (OLS) linear regression: y = slope * x + intercept.
pub fn stats_linear_regression(x []f64, y []f64) !LinearRegressionResult {
	if x.len <= 1 || x.len != y.len {
		return error('Linear regression requires at least 2 points and equal lengths (${x.len} vs ${y.len})')
	}
	var_x := stats_variance(x)
	if var_x == 0.0 {
		return error('Variance of x is zero; cannot fit a unique linear regression slope')
	}
	cov := stats_covariance(x, y)!
	slope := cov / var_x
	intercept := stats_mean(y) - slope * stats_mean(x)
	corr := stats_pearson_correlation(x, y)!
	r_sq := corr * corr

	return LinearRegressionResult{
		slope:       slope
		intercept:   intercept
		r_squared:   r_sq
		correlation: corr
	}
}

// ============================================================================
// 5. Probability Distributions & Standardization
// ============================================================================

// stats_z_score calculates the standard score of a value given mean and standard deviation.
pub fn stats_z_score(val f64, mean f64, std_dev f64) f64 {
	if std_dev == 0.0 {
		return 0.0
	}
	return (val - mean) / std_dev
}

// stats_z_scores normalizes a dataset into standard scores (mean 0, std dev 1).
pub fn stats_z_scores(arr []f64) []f64 {
	if arr.len == 0 {
		return []f64{}
	}
	mean := stats_mean(arr)
	std := stats_std_dev(arr)
	mut res := []f64{cap: arr.len}
	for x in arr {
		res << stats_z_score(x, mean, std)
	}
	return res
}

// stats_normal_pdf calculates the probability density function of the Gaussian/Normal distribution.
pub fn stats_normal_pdf(x f64, mean f64, std_dev f64) f64 {
	if std_dev <= 0.0 {
		return 0.0
	}
	coef := 1.0 / (std_dev * math.sqrt(2.0 * math.pi))
	exp_val := -0.5 * math.pow((x - mean) / std_dev, 2.0)
	return coef * math.exp(exp_val)
}

// stats_normal_cdf calculates the cumulative distribution function of the Gaussian/Normal distribution.
pub fn stats_normal_cdf(x f64, mean f64, std_dev f64) f64 {
	if std_dev <= 0.0 {
		return 0.0
	}
	return 0.5 * (1.0 + math.erf((x - mean) / (std_dev * math.sqrt(2.0))))
}

// ============================================================================
// 6. Normalization & Outlier Detection
// ============================================================================

// stats_min_max_normalize scales all values in the slice to the range [0.0, 1.0].
pub fn stats_min_max_normalize(arr []f64) []f64 {
	if arr.len == 0 {
		return []f64{}
	}
	min_v := stats_min(arr) or { 0.0 }
	max_v := stats_max(arr) or { 0.0 }
	diff := max_v - min_v
	if diff == 0.0 {
		return []f64{len: arr.len, init: 0.0}
	}
	mut res := []f64{cap: arr.len}
	for x in arr {
		res << (x - min_v) / diff
	}
	return res
}

// stats_outliers_iqr identifies data points beyond Tukey's fences: [Q1 - k*IQR, Q3 + k*IQR].
// Multiplier k defaults to 1.5 for regular outliers (3.0 for extreme outliers).
pub fn stats_outliers_iqr(arr []f64, multiplier f64) []f64 {
	if arr.len == 0 {
		return []f64{}
	}
	q1, _, q3 := stats_quartiles(arr)
	iqr := q3 - q1
	mult := if multiplier <= 0.0 { 1.5 } else { multiplier }
	lower := q1 - mult * iqr
	upper := q3 + mult * iqr

	mut outliers := []f64{}
	for x in arr {
		if x < lower || x > upper {
			outliers << x
		}
	}
	return outliers
}

// stats_outliers_z_score identifies points whose absolute Z-score exceeds the threshold (e.g. 3.0).
pub fn stats_outliers_z_score(arr []f64, threshold f64) []f64 {
	if arr.len == 0 {
		return []f64{}
	}
	thresh := if threshold <= 0.0 { 3.0 } else { threshold }
	mean := stats_mean(arr)
	std := stats_std_dev(arr)
	if std == 0.0 {
		return []f64{}
	}
	mut outliers := []f64{}
	for x in arr {
		z := math.abs(stats_z_score(x, mean, std))
		if z > thresh {
			outliers << x
		}
	}
	return outliers
}

// ============================================================================
// 7. Time-Series & Smoothing
// ============================================================================

// stats_moving_average computes the Simple Moving Average (SMA) over a sliding window.
pub fn stats_moving_average(arr []f64, window_size int) ![]f64 {
	if window_size <= 0 || window_size > arr.len {
		return error('Window size must be between 1 and array length (${window_size} vs ${arr.len})')
	}
	mut res := []f64{cap: arr.len - window_size + 1}
	mut sum := 0.0
	for i in 0 .. window_size {
		sum += arr[i]
	}
	res << sum / f64(window_size)
	for i in window_size .. arr.len {
		sum += arr[i] - arr[i - window_size]
		res << sum / f64(window_size)
	}
	return res
}

// stats_exponential_moving_average computes the Exponential Moving Average (EMA).
// Alpha must be in range (0.0, 1.0], representing the degree of weighting decrease.
pub fn stats_exponential_moving_average(arr []f64, alpha f64) ![]f64 {
	if alpha <= 0.0 || alpha > 1.0 {
		return error('Alpha smoothing factor must be in range (0.0, 1.0]')
	}
	if arr.len == 0 {
		return []f64{}
	}
	mut res := []f64{cap: arr.len}
	mut ema := arr[0]
	res << ema
	for i in 1 .. arr.len {
		ema = alpha * arr[i] + (1.0 - alpha) * ema
		res << ema
	}
	return res
}

// ============================================================================
// 8. Comprehensive Summary Profile
// ============================================================================

// stats_summary computes a complete 17-metric descriptive statistical summary of the dataset.
pub fn stats_summary(arr []f64) SummaryStats {
	if arr.len == 0 {
		return SummaryStats{}
	}
	q1, q2, q3 := stats_quartiles(arr)
	min_v := stats_min(arr) or { 0.0 }
	max_v := stats_max(arr) or { 0.0 }

	return SummaryStats{
		count:           arr.len
		min:             min_v
		max:             max_v
		range:           max_v - min_v
		sum:             stats_sum(arr)
		mean:            stats_mean(arr)
		median:          q2
		variance:        stats_variance(arr)
		sample_variance: stats_sample_variance(arr)
		std_dev:         stats_std_dev(arr)
		sample_std_dev:  stats_sample_std_dev(arr)
		sem:             stats_standard_error(arr)
		q1:              q1
		q3:              q3
		iqr:             q3 - q1
		skewness:        stats_skewness(arr)
		kurtosis:        stats_kurtosis(arr)
	}
}
