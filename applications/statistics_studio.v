module main

import simplegui
import os
import math
import time

// -------------------------------------------------------------
// Statistical Data Structures & Computation Engine
// -------------------------------------------------------------

struct SummaryStats {
mut:
	count       int
	sum         f64
	sum_sq      f64
	mean        f64
	geom_mean   f64
	harm_mean   f64
	trimmed_mean f64
	median      f64
	min         f64
	max         f64
	range       f64
	mid_range   f64
	var_sample  f64
	var_pop     f64
	sd_sample   f64
	sd_pop      f64
	sem         f64
	q1          f64
	q2          f64
	q3          f64
	iqr         f64
	skewness    f64
	kurtosis    f64
	cv_pct      f64
	ci_95_low   f64
	ci_95_high  f64
	ci_99_low   f64
	ci_99_high  f64
	outliers    []f64
}

struct RegressionResult {
mut:
	n           int
	slope       f64
	intercept   f64
	r           f64
	r_squared   f64
	std_err_est f64
	covar       f64
	x_mean      f64
	y_mean      f64
}

struct AppState {
mut:
	raw_data_a     []f64
	raw_data_b     []f64
	stats_a        SummaryStats
	stats_b        SummaryStats
	active_tab     string
	history_ledger []string
}

// -------------------------------------------------------------
// Math & Numerical Helpers
// -------------------------------------------------------------

fn log_factorial(n int) f64 {
	if n <= 1 { return 0.0 }
	mut acc := 0.0
	for i in 2 .. (n + 1) {
		acc += math.log(f64(i))
	}
	return acc
}

fn parse_numbers(input_text string) []f64 {
	mut numbers := []f64{}
	cleaned := input_text.replace(',', ' ').replace('\t', ' ').replace('\r', ' ')
	tokens := cleaned.split_into_lines()
	for line in tokens {
		words := line.split(' ')
		for word in words {
			w := word.trim_space()
			if w != '' {
				val := w.f64()
				if !math.is_nan(val) && !math.is_inf(val, 0) {
					numbers << val
				}
			}
		}
	}
	return numbers
}

fn compute_summary_stats(data []f64) SummaryStats {
	mut s := SummaryStats{
		count: data.len
	}
	if data.len == 0 {
		return s
	}

	mut sorted := data.clone()
	sorted.sort()

	n := sorted.len
	s.count = n
	s.min = sorted[0]
	s.max = sorted[n - 1]
	s.range = s.max - s.min
	s.mid_range = (s.min + s.max) / 2.0

	// Sums & Mean
	mut sum := 0.0
	mut sum_sq := 0.0
	mut prod_log := 0.0
	mut harm_sum := 0.0
	mut all_positive := true

	for x in sorted {
		sum += x
		sum_sq += x * x
		if x > 0 {
			prod_log += math.log(x)
			harm_sum += 1.0 / x
		} else {
			all_positive = false
		}
	}

	s.sum = sum
	s.sum_sq = sum_sq
	s.mean = sum / f64(n)

	if all_positive && n > 0 {
		s.geom_mean = math.exp(prod_log / f64(n))
		s.harm_mean = f64(n) / harm_sum
	}

	// 10% Trimmed Mean
	trim_k := int(f64(n) * 0.1)
	if n > 2 * trim_k && trim_k > 0 {
		mut trim_sum := 0.0
		for i in trim_k .. (n - trim_k) {
			trim_sum += sorted[i]
		}
		s.trimmed_mean = trim_sum / f64(n - 2 * trim_k)
	} else {
		s.trimmed_mean = s.mean
	}

	// Median & Quartiles
	if n % 2 == 1 {
		s.median = sorted[n / 2]
	} else {
		s.median = (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0
	}
	s.q2 = s.median

	// Q1 (25th percentile) & Q3 (75th percentile)
	s.q1 = percentile(sorted, 0.25)
	s.q3 = percentile(sorted, 0.75)
	s.iqr = s.q3 - s.q1

	// Outliers (Tukey's Fences: [Q1 - 1.5*IQR, Q3 + 1.5*IQR])
	low_fence := s.q1 - 1.5 * s.iqr
	high_fence := s.q3 + 1.5 * s.iqr
	for x in sorted {
		if x < low_fence || x > high_fence {
			s.outliers << x
		}
	}

	// Variance, Standard Deviation, Skewness, Kurtosis
	if n > 1 {
		mut dev_sq := 0.0
		mut m3 := 0.0
		mut m4 := 0.0
		for x in sorted {
			diff := x - s.mean
			dev_sq += diff * diff
			m3 += diff * diff * diff
			m4 += diff * diff * diff * diff
		}

		s.var_sample = dev_sq / f64(n - 1)
		s.var_pop = dev_sq / f64(n)
		s.sd_sample = math.sqrt(s.var_sample)
		s.sd_pop = math.sqrt(s.var_pop)
		s.sem = s.sd_sample / math.sqrt(f64(n))

		if s.sd_pop > 0 {
			s.skewness = (m3 / f64(n)) / math.pow(s.sd_pop, 3.0)
			s.kurtosis = ((m4 / f64(n)) / math.pow(s.sd_pop, 4.0)) - 3.0 // Excess kurtosis
		}

		if math.abs(s.mean) > 1e-12 {
			s.cv_pct = (s.sd_sample / math.abs(s.mean)) * 100.0
		}

		// Confidence intervals
		t_crit_95 := approx_t_crit(n - 1, 0.05)
		t_crit_99 := approx_t_crit(n - 1, 0.01)
		s.ci_95_low = s.mean - t_crit_95 * s.sem
		s.ci_95_high = s.mean + t_crit_95 * s.sem
		s.ci_99_low = s.mean - t_crit_99 * s.sem
		s.ci_99_high = s.mean + t_crit_99 * s.sem
	}

	return s
}

fn percentile(sorted []f64, p f64) f64 {
	n := sorted.len
	if n == 0 { return 0.0 }
	if n == 1 { return sorted[0] }
	idx := p * f64(n - 1)
	low := int(math.floor(idx))
	high := int(math.ceil(idx))
	weight := idx - f64(low)
	if low >= n - 1 { return sorted[n - 1] }
	return sorted[low] * (1.0 - weight) + sorted[high] * weight
}

fn approx_t_crit(df int, alpha f64) f64 {
	if alpha == 0.05 {
		if df >= 120 { return 1.960 }
		if df >= 60  { return 2.000 }
		if df >= 30  { return 2.042 }
		if df >= 20  { return 2.086 }
		if df >= 10  { return 2.228 }
		if df >= 5   { return 2.571 }
		return 2.776
	} else {
		if df >= 120 { return 2.576 }
		if df >= 60  { return 2.660 }
		if df >= 30  { return 2.750 }
		if df >= 20  { return 2.845 }
		if df >= 10  { return 3.169 }
		return 3.707
	}
}

// -------------------------------------------------------------
// Two-Sample T-Test & ANOVA Engine
// -------------------------------------------------------------

struct TTestResult {
mut:
	t_stat     f64
	df         f64
	p_approx   f64
	mean_diff  f64
	is_paired  bool
	welch_df   f64
	conclusion string
}

fn compute_two_sample_ttest(a []f64, b []f64, paired bool) TTestResult {
	mut res := TTestResult{}
	if a.len == 0 || b.len == 0 { return res }

	if paired && a.len == b.len {
		res.is_paired = true
		n := a.len
		mut diffs := []f64{}
		for i in 0 .. n {
			diffs << (a[i] - b[i])
		}
		st := compute_summary_stats(diffs)
		res.mean_diff = st.mean
		res.df = f64(n - 1)
		if st.sem > 0 {
			res.t_stat = st.mean / st.sem
			res.p_approx = approx_p_from_t(res.t_stat, int(res.df))
		}
	} else {
		st_a := compute_summary_stats(a)
		st_b := compute_summary_stats(b)
		res.mean_diff = st_a.mean - st_b.mean

		na := f64(st_a.count)
		nb := f64(st_b.count)
		va := st_a.var_sample
		vb := st_b.var_sample

		se_diff := math.sqrt((va / na) + (vb / nb))
		if se_diff > 0 {
			res.t_stat = res.mean_diff / se_diff
			num := math.pow((va / na) + (vb / nb), 2.0)
			den := (math.pow(va / na, 2.0) / (na - 1.0)) + (math.pow(vb / nb, 2.0) / (nb - 1.0))
			res.df = if den > 0 { num / den } else { na + nb - 2.0 }
			res.welch_df = res.df
			res.p_approx = approx_p_from_t(res.t_stat, int(res.df))
		}
	}

	if res.p_approx < 0.001 {
		res.conclusion = 'Extremely statistically significant (p < 0.001, Reject H_0)'
	} else if res.p_approx < 0.05 {
		res.conclusion = 'Statistically significant (p < 0.05, Reject H_0)'
	} else {
		res.conclusion = 'Not statistically significant (p >= 0.05, Fail to reject H_0)'
	}
	return res
}

fn approx_p_from_t(t f64, df int) f64 {
	_ = df
	abs_t := math.abs(t)
	z := abs_t
	p_norm := 2.0 * (1.0 - (0.5 * (1.0 + math.erf(z / math.sqrt(2.0)))))
	return math.max(0.00001, math.min(1.0, p_norm))
}

// -------------------------------------------------------------
// Linear Regression & Correlation
// -------------------------------------------------------------

fn compute_regression(x_data []f64, y_data []f64) RegressionResult {
	mut res := RegressionResult{}
	n := math.min(x_data.len, y_data.len)
	res.n = n
	if n < 2 { return res }

	mut sum_x := 0.0
	mut sum_y := 0.0
	mut sum_xx := 0.0
	mut sum_yy := 0.0
	mut sum_xy := 0.0

	for i in 0 .. n {
		x := x_data[i]
		y := y_data[i]
		sum_x += x
		sum_y += y
		sum_xx += x * x
		sum_yy += y * y
		sum_xy += x * y
	}

	fn_val := f64(n)
	res.x_mean = sum_x / fn_val
	res.y_mean = sum_y / fn_val

	ss_xx := sum_xx - (sum_x * sum_x) / fn_val
	ss_yy := sum_yy - (sum_y * sum_y) / fn_val
	ss_xy := sum_xy - (sum_x * sum_y) / fn_val

	res.covar = ss_xy / (fn_val - 1.0)

	if ss_xx > 0 {
		res.slope = ss_xy / ss_xx
		res.intercept = res.y_mean - res.slope * res.x_mean
	}

	if ss_xx > 0 && ss_yy > 0 {
		res.r = ss_xy / math.sqrt(ss_xx * ss_yy)
		res.r_squared = res.r * res.r
	}

	if n > 2 && ss_xx > 0 {
		mut sse := 0.0
		for i in 0 .. n {
			y_pred := res.slope * x_data[i] + res.intercept
			diff := y_data[i] - y_pred
			sse += diff * diff
		}
		res.std_err_est = math.sqrt(sse / f64(n - 2))
	}

	return res
}

// -------------------------------------------------------------
// ASCII Frequency Histogram Generator
// -------------------------------------------------------------

fn generate_ascii_histogram(data []f64, bins_count int) string {
	if data.len == 0 { return 'No data available to plot histogram.\n' }
	
	mut sorted := data.clone()
	sorted.sort()
	min_val := sorted[0]
	max_val := sorted[sorted.len - 1]
	
	if min_val == max_val {
		return 'All ${data.len} values are identical (${min_val:.2f}).\n'
	}

	num_bins := if bins_count > 0 { bins_count } else { 10 }
	bin_width := (max_val - min_val) / f64(num_bins)
	mut counts := []int{len: num_bins, init: 0}

	for x in sorted {
		mut b := int(math.floor((x - min_val) / bin_width))
		if b >= num_bins { b = num_bins - 1 }
		if b < 0 { b = 0 }
		counts[b]++
	}

	mut max_count := 1
	for c in counts {
		if c > max_count { max_count = c }
	}

	mut lines := []string{}
	lines << '========================================================================'
	lines << ' FREQUENCY DISTRIBUTION HISTOGRAM (N = ${data.len})'
	lines << '========================================================================'
	lines << ' Bin Range                | Freq | Histogram Bar'
	lines << '------------------------------------------------------------------------'

	for i in 0 .. num_bins {
		b_low := min_val + f64(i) * bin_width
		b_high := min_val + f64(i + 1) * bin_width
		c := counts[i]
		bar_len := int(f64(c) / f64(max_count) * 36.0)
		mut bar := ''
		for _ in 0 .. bar_len {
			bar += '#'
		}
		if c > 0 && bar == '' { bar = '=' }
		
		pct := (f64(c) / f64(data.len)) * 100.0
		lines << '[${b_low:8.2f} - ${b_high:8.2f}] | ${c:4} | ${bar:-36} (${pct:5.1f}%)'
	}
	lines << '========================================================================\n'
	return lines.join('\n')
}

// -------------------------------------------------------------
// Format Summary Report
// -------------------------------------------------------------

fn format_stats_report(name string, s SummaryStats) string {
	mut lines := []string{}
	lines << '========================================================================'
	lines << ' STATISTICAL PROFILE & COMPREHENSIVE METRICS: ' + name
	lines << '========================================================================'
	lines << ' SAMPLE SIZE & SUMS'
	lines << '   * Observations (N)       : ${s.count}'
	lines << '   * Sum (x)               : ${s.sum:14.4f}'
	lines << '   * Sum of Squares (x)   : ${s.sum_sq:14.4f}'
	lines << '------------------------------------------------------------------------'
	lines << ' CENTRAL TENDENCY'
	lines << '   * Arithmetic Mean ()    : ${s.mean:14.4f}'
	lines << '   * Median (50th %ile)     : ${s.median:14.4f}'
	lines << '   * Geometric Mean         : ${s.geom_mean:14.4f}'
	lines << '   * Harmonic Mean          : ${s.harm_mean:14.4f}'
	lines << '   * 10% Trimmed Mean       : ${s.trimmed_mean:14.4f}'
	lines << '   * Mid-Range ((Min+Max)/2): ${s.mid_range:14.4f}'
	lines << '------------------------------------------------------------------------'
	lines << ' VARIATION & DISPERSION'
	lines << '   * Sample Variance (s)   : ${s.var_sample:14.4f}'
	lines << '   * Population Var ()    : ${s.var_pop:14.4f}'
	lines << '   * Sample Std Dev (s)     : ${s.sd_sample:14.4f}'
	lines << '   * Population Std Dev () : ${s.sd_pop:14.4f}'
	lines << '   * Std Error of Mean (SEM): ${s.sem:14.4f}'
	lines << '   * Coeff. of Variation (%) : ${s.cv_pct:14.2f}%'
	lines << '------------------------------------------------------------------------'
	lines << ' FIVE-NUMBER SUMMARY & QUARTILES'
	lines << '   * Minimum (Min)          : ${s.min:14.4f}'
	lines << '   * 1st Quartile (Q1 / 25%): ${s.q1:14.4f}'
	lines << '   * 2nd Quartile (Median)  : ${s.q2:14.4f}'
	lines << '   * 3rd Quartile (Q3 / 75%): ${s.q3:14.4f}'
	lines << '   * Maximum (Max)          : ${s.max:14.4f}'
	lines << '   * Interquartile Range(IQR): ${s.iqr:14.4f}'
	lines << '   * Total Range (Max - Min): ${s.range:14.4f}'
	lines << '------------------------------------------------------------------------'
	lines << ' DISTRIBUTION SHAPE & NORMALITY'
	lines << '   * Skewness (Fisher-Pears): ${s.skewness:14.4f}' + if s.skewness > 0.5 { ' (Right/Pos Skewed)' } else if s.skewness < -0.5 { ' (Left/Neg Skewed)' } else { ' (Approx Symmetric)' }
	lines << '   * Excess Kurtosis (Tail) : ${s.kurtosis:14.4f}' + if s.kurtosis > 0.5 { ' (Leptokurtic / Heavy-tailed)' } else if s.kurtosis < -0.5 { ' (Platykurtic / Light-tailed)' } else { ' (Mesokurtic / Normal)' }
	lines << '------------------------------------------------------------------------'
	lines << ' CONFIDENCE INTERVALS (FOR POPULATION MEAN )'
	lines << '   * 95% Confidence Interval: [${s.ci_95_low:.4f}    ${s.ci_95_high:.4f}]'
	lines << '   * 99% Confidence Interval: [${s.ci_99_low:.4f}    ${s.ci_99_high:.4f}]'
	lines << '------------------------------------------------------------------------'
	lines << ' OUTLIER ANALYSIS (Tukey 1.5x IQR Rule)'
	if s.outliers.len > 0 {
		mut out_strs := []string{}
		for o in s.outliers { out_strs << '${o:.2f}' }
		lines << '   * Outlier Points Count   : ${s.outliers.len}'
		lines << '   * Detected Outliers      : ' + out_strs.join(', ')
	} else {
		lines << '   * Outlier Points Count   : 0 (No outliers detected outside Tukey fences)'
	}
	lines << '========================================================================\n'
	return lines.join('\n')
}

// -------------------------------------------------------------
// Main Application Entry Point
// -------------------------------------------------------------

fn main() {
	println('Starting SimpleGUI - Statistics Studio Pro (Data Science & Inference Engine)...')

	mut win := simplegui.new_simple_window('Statistics Studio Pro -- Advanced Data Science & Inference Engine', 1180, 920)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_spacing(6)
	win.set_padding(14)

	mut state := &AppState{
		raw_data_a: []f64{}
		raw_data_b: []f64{}
		stats_a: SummaryStats{}
		stats_b: SummaryStats{}
		active_tab: 'Descriptive Stats'
		history_ledger: []string{}
	}

	// -------------------------------------------------------------
	// Header & Theme
	// -------------------------------------------------------------
	win.begin_row('row_header')
	win.add_heading('Statistics Studio Pro')

	win.add_label('lbl_info', 'Data Science & Inference Engine')

	win.add_label('lbl_theme_hdr', 'Theme:')
	saved_theme := simplegui.get_saved_theme()
	win.add_dropdown('dd_theme_selector', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_theme_selector', 160)
	win.end_row()

	// -------------------------------------------------------------
	// Navigation Workspace Tabs
	// -------------------------------------------------------------
	win.add_tabs('main_tabs', [
		'Descriptive Stats',
		'Two-Sample Hypothesis Testing',
		'Linear Regression & Correlation',
		'Probability Distributions',
		'Data Cleansing & Transform',
		'Benchmark Datasets',
		'Analysis Ledger'
	])

	// -------------------------------------------------------------
	// Top Key Metrics Overview Cards
	// -------------------------------------------------------------
	win.begin_group_box('grp_summary_cards', 'Key Summary Statistics (Sample A)')
	win.begin_row('row_metric_cards')
	win.add_metric_card('card_n', 'Sample Size (N)', '0', 'Count', 'Total Observations')
	win.add_metric_card('card_mean', 'Mean ()', '0.000', 'Average', 'Arithmetic Mean')
	win.add_metric_card('card_median', 'Median (Q2)', '0.000', '50th %ile', 'Center Point')
	win.add_metric_card('card_sd', 'Std Dev (s)', '0.000', 'Dispersion', 'Sample Std Dev')
	win.add_metric_card('card_iqr', 'IQR', '0.000', 'Q3 - Q1', 'Interquartile Range')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 1: Descriptive Statistics & Histogram
	// -------------------------------------------------------------
	win.begin_group_box('pane_desc', 'Descriptive Statistics & Frequency Distribution (Sample A)')

	win.add_label('lbl_raw_prompt', 'Input Data Sample A (comma, space, or newline separated numbers):')
	win.add_textarea('txt_data_a', '45.2, 56.1, 48.9, 62.3, 51.7, 59.4, 63.8, 47.5, 54.2, 58.6, 60.1, 52.8, 55.4, 68.9, 49.3, 57.2, 53.6, 61.5, 56.8, 50.4')
	win.set_control_height('txt_data_a', 60)
	win.set_control_font_name('txt_data_a', 'Menlo')
	win.set_control_font_size('txt_data_a', 13)

	win.begin_row('row_desc_actions')
	win.add_button('btn_calc_desc', 'COMPUTE STATISTICAL PROFILE')
	win.add_button('btn_clear_data_a', 'Clear')
	win.add_button('btn_copy_stats_report', 'Copy Report')
	win.end_row()

	win.add_textarea('txt_desc_report', 'Click "COMPUTE STATISTICAL PROFILE" above to generate summary metrics and histogram.\n')
	win.set_control_height('txt_desc_report', 260)
	win.set_control_font_name('txt_desc_report', 'Menlo')
	win.set_control_font_size('txt_desc_report', 12)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 2: Two-Sample Hypothesis Testing
	// -------------------------------------------------------------
	win.begin_group_box('pane_hypothesis', 'Two-Sample Hypothesis Testing (Student\'s T-Test, Welch\'s Test, Paired Comparison)')

	win.add_label('lbl_ha', 'Sample A Dataset (comma or newline separated):')
	win.add_textarea('txt_hypo_a', '102.3, 105.1, 99.8, 108.4, 103.2, 106.7, 101.5, 104.9, 107.2, 103.8')
	win.set_control_height('txt_hypo_a', 50)
	win.set_control_font_name('txt_hypo_a', 'Menlo')

	win.add_label('lbl_hb', 'Sample B Dataset (comma or newline separated):')
	win.add_textarea('txt_hypo_b', '95.4, 98.2, 94.1, 101.3, 97.6, 99.0, 96.5, 98.8, 100.2, 97.1')
	win.set_control_height('txt_hypo_b', 50)
	win.set_control_font_name('txt_hypo_b', 'Menlo')

	win.begin_row('row_hypo_actions')
	win.add_button('btn_test_independent', 'Independent Samples T-Test (Welch)')
	win.add_button('btn_test_paired', 'Paired Samples T-Test (Pre/Post)')
	win.add_button('btn_test_anova', 'One-Way ANOVA F-Test')
	win.end_row()

	win.add_textarea('txt_hypo_report', 'Two-sample hypothesis test results, t-statistic, degrees of freedom, and p-value inference will appear here.\n')
	win.set_control_height('txt_hypo_report', 240)
	win.set_control_font_name('txt_hypo_report', 'Menlo')
	win.set_control_font_size('txt_hypo_report', 12)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 3: Linear Regression & Correlation
	// -------------------------------------------------------------
	win.begin_group_box('pane_regression', 'Ordinary Least Squares (OLS) Linear Regression & Pearson Correlation')

	win.add_label('lbl_rx', 'Independent Variable X (comma or newline separated):')
	win.add_textarea('txt_reg_x', '1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0')
	win.set_control_height('txt_reg_x', 45)
	win.set_control_font_name('txt_reg_x', 'Menlo')

	win.add_label('lbl_ry', 'Dependent Variable Y (comma or newline separated):')
	win.add_textarea('txt_reg_y', '2.8, 5.1, 7.3, 8.9, 11.2, 13.5, 15.1, 17.4, 19.2, 21.8')
	win.set_control_height('txt_reg_y', 45)
	win.set_control_font_name('txt_reg_y', 'Menlo')

	win.begin_row('row_reg_actions')
	win.add_button('btn_calc_regression', 'FIT LINEAR MODEL (OLS)')
	win.add_label('lbl_pred_x', 'Predict Y for X =')
	win.add_input('txt_predict_x', '12.5')
	win.set_control_width('txt_predict_x', 80)
	win.add_button('btn_predict_y', 'Predict Y')
	win.end_row()

	win.add_textarea('txt_reg_report', 'Regression equation (y = mx + c), Pearson r, R, covariance, standard error of estimate, and residuals will appear here.\n')
	win.set_control_height('txt_reg_report', 240)
	win.set_control_font_name('txt_reg_report', 'Menlo')
	win.set_control_font_size('txt_reg_report', 12)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 4: Probability Distributions
	// -------------------------------------------------------------
	win.begin_group_box('pane_dist', 'Probability Distributions, Z-Scores & Cumulative Probabilities')

	win.begin_row('row_dist_type')
	win.add_label('lbl_dist_kind', 'Distribution Model:')
	win.add_dropdown('dd_dist_model', [
		'Standard Normal Distribution N(0, 1)',
		'Normal Distribution N(, )',
		'Student\'s t-Distribution',
		'Binomial Distribution B(n, p)',
		'Poisson Distribution Pois()'
	], 'Standard Normal Distribution N(0, 1)')
	win.set_control_width('dd_dist_model', 300)

	win.add_label('lbl_p1', 'Param 1 (/n//df):')
	win.add_input('txt_dist_p1', '0.0')
	win.set_control_width('txt_dist_p1', 80)

	win.add_label('lbl_p2', 'Param 2 (/p):')
	win.add_input('txt_dist_p2', '1.0')
	win.set_control_width('txt_dist_p2', 80)

	win.add_label('lbl_dist_x', 'Value (x/k):')
	win.add_input('txt_dist_x', '1.96')
	win.set_control_width('txt_dist_x', 80)

	win.add_button('btn_calc_dist', 'Compute Probability')
	win.end_row()

	win.add_textarea('txt_dist_report', 'Probability density PDF, Cumulative CDF P(X <= x), tail probabilities, and critical bounds will be computed here.\n')
	win.set_control_height('txt_dist_report', 260)
	win.set_control_font_name('txt_dist_report', 'Menlo')
	win.set_control_font_size('txt_dist_report', 12)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 5: Data Cleansing & Transform
	// -------------------------------------------------------------
	win.begin_group_box('pane_clean', 'Data Cleansing, Normalization & Scaling Transforms')

	win.begin_row('row_clean_actions')
	win.add_button('btn_tf_zscore', 'Z-Score Normalize (z = (x-)/)')
	win.add_button('btn_tf_minmax', 'Min-Max Scale [0, 1]')
	win.add_button('btn_tf_log', 'Natural Log Transform ln(x)')
	win.add_button('btn_tf_remove_outliers', 'Filter Outliers (1.5x IQR)')
	win.add_button('btn_tf_sort', 'Sort Ascending')
	win.end_row()

	win.add_textarea('txt_clean_output', 'Transformed dataset output will be generated here.\n')
	win.set_control_height('txt_clean_output', 260)
	win.set_control_font_name('txt_clean_output', 'Menlo')
	win.set_control_font_size('txt_clean_output', 12)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 6: Benchmark Datasets
	// -------------------------------------------------------------
	win.begin_group_box('pane_bench', 'Real-World Benchmark Datasets & Synthetic Experiments')

	win.begin_row('row_bench_btns_1')
	win.add_button('btn_ds_iris', 'Fisher\'s Iris Sepal Length (N=50)')
	win.add_button('btn_ds_exam', 'Student Exam Scores (Bimodal N=30)')
	win.add_button('btn_ds_stock', 'Stock Daily Returns (Fat-tailed N=40)')
	win.end_row()

	win.begin_row('row_bench_btns_2')
	win.add_button('btn_ds_drug', 'Clinical Drug Pre vs Post Trial (Paired N=25)')
	win.add_button('btn_ds_heights', 'Human Adult Heights (Normal N=35)')
	win.add_button('btn_ds_skewed', 'House Prices (Right-Skewed N=30)')
	win.end_row()

	win.add_textarea('txt_bench_info', 'Click any benchmark dataset above to load real-world data into Sample A (and Sample B) and automatically evaluate.\n')
	win.set_control_height('txt_bench_info', 240)
	win.set_control_font_name('txt_bench_info', 'Menlo')
	win.set_control_font_size('txt_bench_info', 12)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 7: Analysis Ledger
	// -------------------------------------------------------------
	win.begin_group_box('pane_history', 'Session Statistical Analysis Ledger')

	win.begin_row('row_hist_actions')
	win.add_button('btn_copy_ledger', 'Copy Ledger')
	win.add_button('btn_clear_ledger', 'Clear Ledger')
	win.add_button('btn_export_ledger', 'Export Ledger to Text...')
	win.end_row()

	win.add_textarea('txt_ledger', 'All statistical profiling runs and hypothesis tests will be recorded in this timestamped ledger.\n')
	win.set_control_height('txt_ledger', 260)
	win.set_control_font_name('txt_ledger', 'Menlo')
	win.set_control_font_size('txt_ledger', 12)
	win.end_group_box()

	// Initially hide inactive tab panes
	win.set_control_visible('pane_hypothesis', false)
	win.set_control_visible('pane_regression', false)
	win.set_control_visible('pane_dist', false)
	win.set_control_visible('pane_clean', false)
	win.set_control_visible('pane_bench', false)
	win.set_control_visible('pane_history', false)

	// -------------------------------------------------------------
	// Status Bar Footer
	// -------------------------------------------------------------
	win.begin_row('row_footer')
	win.add_label('lbl_status_bar', 'Ready. Statistical Inference Engine active.')
	win.end_row()

	// -------------------------------------------------------------
	// Ledger Helper
	// -------------------------------------------------------------
	append_ledger := fn [mut state] (mut w simplegui.SimpleWindow, title string, summary string) {
		ts := time.now().format_ss()
		entry := '[${ts}] ${title}\n${summary}\n------------------------------------------------------------------------'
		state.history_ledger << entry
		mut content := []string{}
		content << '========================================================================'
		content << ' STATISTICS STUDIO PRO -- ANALYSIS LEDGER'
		content << '========================================================================'
		content << state.history_ledger.join('\n')
		content << '========================================================================\n'
		w.set('txt_ledger', content.join('\n'))
	}

	// -------------------------------------------------------------
	// Master Compute Function for Sample A
	// -------------------------------------------------------------
	run_sample_a_analysis := fn [mut state, append_ledger] (mut w simplegui.SimpleWindow) {
		raw_txt := w.get('txt_data_a')
		nums := parse_numbers(raw_txt)
		state.raw_data_a = nums
		state.stats_a = compute_summary_stats(nums)
		s := state.stats_a

		// Update Top Metric Cards
		w.set_metric_card_value('card_n', '${s.count}', 'Count')
		w.set_metric_card_value('card_mean', '${s.mean:.3f}', 'Average')
		w.set_metric_card_value('card_median', '${s.median:.3f}', '50th %ile')
		w.set_metric_card_value('card_sd', '${s.sd_sample:.3f}', 'Dispersion')
		w.set_metric_card_value('card_iqr', '${s.iqr:.3f}', 'Q3 - Q1')

		report := format_stats_report('Sample A', s)
		hist := generate_ascii_histogram(nums, 10)
		full_output := report + '\n' + hist
		w.set('txt_desc_report', full_output)
		w.set('lbl_status_bar', ' Processed ${s.count} data points. Mean = ${s.mean:.3f}, SD = ${s.sd_sample:.3f}')

		append_ledger(mut w, 'Sample A Profile (N=${s.count})', 'Mean: ${s.mean:.4f}, Median: ${s.median:.4f}, SD: ${s.sd_sample:.4f}, IQR: ${s.iqr:.4f}')
	}

	// -------------------------------------------------------------
	// Event Callbacks
	// -------------------------------------------------------------

	// Workspace Tabs Navigation
	win.on_change('main_tabs', fn [mut state] (mut w simplegui.SimpleWindow, tab string) {
		state.active_tab = tab

		w.set_control_visible('pane_desc', tab == 'Descriptive Stats')
		w.set_control_visible('pane_hypothesis', tab == 'Two-Sample Hypothesis Testing')
		w.set_control_visible('pane_regression', tab == 'Linear Regression & Correlation')
		w.set_control_visible('pane_dist', tab == 'Probability Distributions')
		w.set_control_visible('pane_clean', tab == 'Data Cleansing & Transform')
		w.set_control_visible('pane_bench', tab == 'Benchmark Datasets')
		w.set_control_visible('pane_history', tab == 'Analysis Ledger')

		w.toast('Switched to ' + tab)
	})

	// Theme Selector
	win.on_change('dd_theme_selector', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	// -------------------------------------------------------------
	// Tab 1: Descriptive Stats Actions
	// -------------------------------------------------------------
	win.on_click('btn_calc_desc', fn [run_sample_a_analysis] (mut w simplegui.SimpleWindow) {
		run_sample_a_analysis(mut w)
		w.toast('Computed statistical profile!')
	})

	win.on_click('btn_clear_data_a', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_data_a', '')
		w.set('txt_desc_report', '')
		w.toast('Cleared input data.')
	})

	win.on_click('btn_copy_stats_report', fn (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(w.get('txt_desc_report'))
		w.toast('Copied statistical report to clipboard!')
	})

	// -------------------------------------------------------------
	// Tab 2: Two-Sample Hypothesis Testing Actions
	// -------------------------------------------------------------
	win.on_click('btn_test_independent', fn [append_ledger] (mut w simplegui.SimpleWindow) {
		a := parse_numbers(w.get('txt_hypo_a'))
		b := parse_numbers(w.get('txt_hypo_b'))
		if a.len == 0 || b.len == 0 {
			w.alert('Input Missing', 'Please enter numbers for both Sample A and Sample B.')
			return
		}
		res := compute_two_sample_ttest(a, b, false)
		st_a := compute_summary_stats(a)
		st_b := compute_summary_stats(b)

		mut out := []string{}
		out << '========================================================================'
		out << ' TWO-SAMPLE WELCH\'S T-TEST (INDEPENDENT SAMPLES, UNEQUAL VARIANCE)'
		out << '========================================================================'
		out << ' SAMPLE SUMMARIES:'
		out << '   * Sample A : N = ${st_a.count}, Mean = ${st_a.mean:.4f}, SD = ${st_a.sd_sample:.4f}, SEM = ${st_a.sem:.4f}'
		out << '   * Sample B : N = ${st_b.count}, Mean = ${st_b.mean:.4f}, SD = ${st_b.sd_sample:.4f}, SEM = ${st_b.sem:.4f}'
		out << '   * Mean Difference (A - B) : ${res.mean_diff:.4f}'
		out << '------------------------------------------------------------------------'
		out << ' TEST STATISTICS:'
		out << '   * t-statistic             : ${res.t_stat:10.4f}'
		out << '   * Degrees of Freedom (df) : ${res.df:10.2f}'
		out << '   * p-value (Approx 2-tail) : ${res.p_approx:10.5f}'
		out << '------------------------------------------------------------------------'
		out << ' STATISTICAL INFERENCE & HYPOTHESIS CONCLUSION:'
		out << '   * ' + res.conclusion
		out << '========================================================================\n'

		w.set('txt_hypo_report', out.join('\n'))
		w.set('lbl_status_bar', ' Welch t-test: t = ${res.t_stat:.3f}, df = ${res.df:.1f}, p ~ ${res.p_approx:.4f}')
		append_ledger(mut w, 'Independent T-Test', 't = ${res.t_stat:.4f}, p = ${res.p_approx:.4f}, ${res.conclusion}')
		w.toast('Executed Welch\'s T-Test!')
	})

	win.on_click('btn_test_paired', fn [append_ledger] (mut w simplegui.SimpleWindow) {
		a := parse_numbers(w.get('txt_hypo_a'))
		b := parse_numbers(w.get('txt_hypo_b'))
		if a.len != b.len || a.len == 0 {
			w.alert('Dimension Mismatch', 'Paired t-test requires exactly equal number of observations in Sample A and Sample B (A=${a.len}, B=${b.len}).')
			return
		}
		res := compute_two_sample_ttest(a, b, true)

		mut out := []string{}
		out << '========================================================================'
		out << ' PAIRED SAMPLES T-TEST (REPEATED MEASURES / PRE-POST TRIAL)'
		out << '========================================================================'
		out << ' OBSERVATIONS: N = ${a.len} paired subjects'
		out << '   * Mean Difference (d = A - B) : ${res.mean_diff:.4f}'
		out << '------------------------------------------------------------------------'
		out << ' TEST STATISTICS:'
		out << '   * t-statistic             : ${res.t_stat:10.4f}'
		out << '   * Degrees of Freedom (df) : ${res.df:10.0f}'
		out << '   * p-value (Approx 2-tail) : ${res.p_approx:10.5f}'
		out << '------------------------------------------------------------------------'
		out << ' STATISTICAL INFERENCE & HYPOTHESIS CONCLUSION:'
		out << '   * ' + res.conclusion
		out << '========================================================================\n'

		w.set('txt_hypo_report', out.join('\n'))
		w.set('lbl_status_bar', ' Paired t-test: t = ${res.t_stat:.3f}, df = ${res.df:.0f}, p ~ ${res.p_approx:.4f}')
		append_ledger(mut w, 'Paired T-Test', 't = ${res.t_stat:.4f}, p = ${res.p_approx:.4f}, ${res.conclusion}')
		w.toast('Executed Paired T-Test!')
	})

	win.on_click('btn_test_anova', fn [append_ledger] (mut w simplegui.SimpleWindow) {
		a := parse_numbers(w.get('txt_hypo_a'))
		b := parse_numbers(w.get('txt_hypo_b'))
		if a.len == 0 || b.len == 0 {
			w.alert('Input Missing', 'Enter data for both groups.')
			return
		}
		st_a := compute_summary_stats(a)
		st_b := compute_summary_stats(b)
		grand_n := f64(a.len + b.len)
		grand_mean := (st_a.sum + st_b.sum) / grand_n

		ss_between := f64(a.len) * math.pow(st_a.mean - grand_mean, 2.0) + f64(b.len) * math.pow(st_b.mean - grand_mean, 2.0)
		mut ss_within := 0.0
		for x in a { ss_within += math.pow(x - st_a.mean, 2.0) }
		for x in b { ss_within += math.pow(x - st_b.mean, 2.0) }

		df_between := 1.0
		df_within := grand_n - 2.0
		ms_between := ss_between / df_between
		ms_within := ss_within / df_within
		f_stat := if ms_within > 0 { ms_between / ms_within } else { 0.0 }

		mut out := []string{}
		out << '========================================================================'
		out << ' ONE-WAY ANALYSIS OF VARIANCE (ANOVA)'
		out << '========================================================================'
		out << ' Source of Var |  Sum of Squares (SS) |  df  |  Mean Square (MS) |  F-Stat'
		out << '------------------------------------------------------------------------'
		out << ' Between Groups| ${ss_between:20.4f} | ${df_between:4.0f} | ${ms_between:17.4f} | ${f_stat:7.4f}'
		out << ' Within Groups | ${ss_within:20.4f} | ${df_within:4.0f} | ${ms_within:17.4f} |'
		out << ' Total         | ${(ss_between + ss_within):20.4f} | ${(grand_n - 1.0):4.0f} |                   |'
		out << '========================================================================\n'

		w.set('txt_hypo_report', out.join('\n'))
		w.set('lbl_status_bar', ' ANOVA: F = ${f_stat:.4f}, df = (${df_between:.0f}, ${df_within:.0f})')
		append_ledger(mut w, 'One-Way ANOVA', 'F = ${f_stat:.4f}, df = (${df_between:.0f}, ${df_within:.0f})')
		w.toast('Computed One-Way ANOVA!')
	})

	// -------------------------------------------------------------
	// Tab 3: Regression Actions
	// -------------------------------------------------------------
	win.on_click('btn_calc_regression', fn [append_ledger] (mut w simplegui.SimpleWindow) {
		x := parse_numbers(w.get('txt_reg_x'))
		y := parse_numbers(w.get('txt_reg_y'))
		if x.len != y.len || x.len < 2 {
			w.alert('Dimension Error', 'X and Y must contain the same number of data points (at least 2).')
			return
		}
		reg := compute_regression(x, y)

		mut out := []string{}
		out << '========================================================================'
		out << ' ORDINARY LEAST SQUARES (OLS) LINEAR REGRESSION MODEL'
		out << '========================================================================'
		out << ' MODEL EQUATION:'
		sign_str := if reg.intercept >= 0 { '+ ' } else { '- ' }
		out << 'Y = ${reg.slope:.4f}  X ${sign_str}${math.abs(reg.intercept):.4f}'
		out << '------------------------------------------------------------------------'
		out << ' CORRELATION & FIT QUALITY:'
		out << '   * Pearson Correlation (r) : ${reg.r:10.4f}' + if math.abs(reg.r) > 0.9 { ' (Very Strong Linear Fit)' } else if math.abs(reg.r) > 0.7 { ' (Strong Linear Fit)' } else { ' (Moderate/Weak)' }
		out << '   * Determination (R)      : ${reg.r_squared:10.4f} (${(reg.r_squared * 100.0):.1f}% variance explained)'
		out << '   * Covariance Cov(X,Y)     : ${reg.covar:10.4f}'
		out << '   * Std Error of Est. (Se)  : ${reg.std_err_est:10.4f}'
		out << '   * Observations (N)        : ${reg.n:10}'
		out << '   * Mean X                  : ${reg.x_mean:10.4f}'
		out << '   * Mean Y                  : ${reg.y_mean:10.4f}'
		out << '------------------------------------------------------------------------'
		out << ' RESIDUALS SAMPLE (First 5 points):'
		out << 'X       |    Y Actual |   Y Predicted |    Residual (Y - )'
		out << '------------------------------------------------------------------------'
		limit := math.min(reg.n, 5)
		for i in 0 .. limit {
			pred := reg.slope * x[i] + reg.intercept
			res_diff := y[i] - pred
			out << ' ${x[i]:10.3f} | ${y[i]:11.3f} | ${pred:13.3f} | ${res_diff:14.3f}'
		}
		out << '========================================================================\n'

		w.set('txt_reg_report', out.join('\n'))
		w.set('lbl_status_bar', ' Regression: Y = ${reg.slope:.3f}X + ${reg.intercept:.3f}, r = ${reg.r:.4f}, R = ${reg.r_squared:.4f}')
		append_ledger(mut w, 'Linear Regression', 'Y = ${reg.slope:.4f}X + ${reg.intercept:.4f}, r = ${reg.r:.4f}, R = ${reg.r_squared:.4f}')
		w.toast('Fitted OLS Linear Model!')
	})

	win.on_click('btn_predict_y', fn (mut w simplegui.SimpleWindow) {
		x := parse_numbers(w.get('txt_reg_x'))
		y := parse_numbers(w.get('txt_reg_y'))
		pred_x := w.get('txt_predict_x').f64()
		if x.len != y.len || x.len < 2 {
			w.alert('Model Missing', 'Fit the regression model first.')
			return
		}
		reg := compute_regression(x, y)
		pred_y := reg.slope * pred_x + reg.intercept
		w.toast('Predicted  = ${pred_y:.4f} for X = ${pred_x}')
		cur := w.get('txt_reg_report')
		w.set('txt_reg_report', cur + '\n PREDICTION: For X = ${pred_x}, Predicted  = ${pred_y:.4f}\n')
	})

	// -------------------------------------------------------------
	// Tab 4: Probability Distribution Actions
	// -------------------------------------------------------------
	win.on_click('btn_calc_dist', fn [append_ledger] (mut w simplegui.SimpleWindow) {
		model := w.get('dd_dist_model')
		p1 := w.get('txt_dist_p1').f64()
		p2 := w.get('txt_dist_p2').f64()
		x_val := w.get('txt_dist_x').f64()

		mut out := []string{}
		out << '========================================================================'
		out << ' PROBABILITY DISTRIBUTION ANALYSIS: ' + model
		out << '========================================================================'

		if model.contains('Normal') {
			mu := p1
			sigma := if p2 > 0 { p2 } else { 1.0 }
			z := (x_val - mu) / sigma
			pdf := (1.0 / (sigma * math.sqrt(2.0 * math.pi))) * math.exp(-0.5 * z * z)
			cdf := 0.5 * (1.0 + math.erf(z / math.sqrt(2.0)))
			tail_p := 1.0 - cdf

			out << ' PARAMETERS: Mean () = ${mu:.4f}, Std Dev () = ${sigma:.4f}'
			out << ' QUERY VALUE: X = ${x_val:.4f}'
			out << '------------------------------------------------------------------------'
			out << ' PROBABILITY METRICS:'
			out << '   * Standardized Z-Score    : ${z:12.4f}'
			out << '   * Probability Density f(x): ${pdf:12.6f}'
			out << '   * Cumulative P(X <= x)     : ${cdf:12.6f} (${(cdf * 100.0):.2f}%)'
			out << '   * Upper Tail P(X > x)     : ${tail_p:12.6f} (${(tail_p * 100.0):.2f}%)'
			out << '   * Two-Tailed P(|Z| >= |z|) : ${(2.0 * math.min(cdf, tail_p)):12.6f}'
		} else if model.contains('Binomial') {
			n_trials := int(p1)
			p_prob := math.max(0.0, math.min(1.0, p2))
			k := int(x_val)

			mut pmf := 0.0
			if k >= 0 && k <= n_trials {
				log_comb := log_factorial(n_trials) - log_factorial(k) - log_factorial(n_trials - k)
				pmf = math.exp(log_comb + f64(k) * math.log(p_prob) + f64(n_trials - k) * math.log(1.0 - p_prob))
			}
			exp_val := f64(n_trials) * p_prob
			var_val := f64(n_trials) * p_prob * (1.0 - p_prob)

			out << ' PARAMETERS: Trials (n) = ${n_trials}, Success Prob (p) = ${p_prob:.4f}'
			out << ' QUERY VALUE: Successes (k) = ${k}'
			out << '------------------------------------------------------------------------'
			out << ' BINOMIAL PROBABILITIES:'
			out << '   * Exact P(X = ${k})        : ${pmf:12.6f} (${(pmf * 100.0):.2f}%)'
			out << '   * Expected Value E[X]     : ${exp_val:12.4f}'
			out << '   * Variance Var(X)         : ${var_val:12.4f}'
			out << '   * Std Dev                : ${math.sqrt(var_val):12.4f}'
		} else if model.contains('Poisson') {
			lambda := p1
			k := int(x_val)
			mut pmf := 0.0
			if k >= 0 && lambda > 0 {
				pmf = math.exp(f64(k) * math.log(lambda) - lambda - log_factorial(k))
			}
			out << ' PARAMETERS: Rate Parameter () = ${lambda:.4f}'
			out << ' QUERY VALUE: Events (k) = ${k}'
			out << '------------------------------------------------------------------------'
			out << ' POISSON PROBABILITIES:'
			out << '   * Exact P(X = ${k})        : ${pmf:12.6f} (${(pmf * 100.0):.2f}%)'
			out << '   * Expected Value E[X]     : ${lambda:12.4f}'
			out << '   * Variance Var(X)         : ${lambda:12.4f}'
		} else {
			df := math.max(1.0, p1)
			t := x_val
			p_val := approx_p_from_t(t, int(df))
			out << ' PARAMETERS: Degrees of Freedom (df) = ${df:.0f}'
			out << ' QUERY VALUE: t-value = ${t:.4f}'
			out << '------------------------------------------------------------------------'
			out << ' T-DISTRIBUTION METRICS:'
			out << '   * Two-Tailed p-value      : ${p_val:12.5f}'
			out << '   * Critical t (=0.05, 95%): ${approx_t_crit(int(df), 0.05):12.4f}'
			out << '   * Critical t (=0.01, 99%): ${approx_t_crit(int(df), 0.01):12.4f}'
		}
		out << '========================================================================\n'

		w.set('txt_dist_report', out.join('\n'))
		append_ledger(mut w, 'Distribution Evaluation: ' + model, 'Evaluated probability for x = ${x_val}')
		w.toast('Computed probability metrics!')
	})

	// -------------------------------------------------------------
	// Tab 5: Data Cleansing & Transform Actions
	// -------------------------------------------------------------
	win.on_click('btn_tf_zscore', fn (mut w simplegui.SimpleWindow) {
		data := parse_numbers(w.get('txt_data_a'))
		if data.len < 2 { return }
		st := compute_summary_stats(data)
		mut transformed := []string{}
		for x in data {
			z := if st.sd_sample > 0 { (x - st.mean) / st.sd_sample } else { 0.0 }
			transformed << '${z:.4f}'
		}
		w.set('txt_clean_output', ' Z-SCORE NORMALIZED DATA (Mean=0, SD=1):\n\n' + transformed.join(', '))
		w.toast('Transformed to Z-Scores!')
	})

	win.on_click('btn_tf_minmax', fn (mut w simplegui.SimpleWindow) {
		data := parse_numbers(w.get('txt_data_a'))
		if data.len < 2 { return }
		st := compute_summary_stats(data)
		mut transformed := []string{}
		for x in data {
			val := if st.range > 0 { (x - st.min) / st.range } else { 0.0 }
			transformed << '${val:.4f}'
		}
		w.set('txt_clean_output', ' MIN-MAX SCALED DATA [0, 1]:\n\n' + transformed.join(', '))
		w.toast('Scaled to [0, 1] range!')
	})

	win.on_click('btn_tf_log', fn (mut w simplegui.SimpleWindow) {
		data := parse_numbers(w.get('txt_data_a'))
		mut transformed := []string{}
		for x in data {
			if x > 0 {
				transformed << '${math.log(x):.4f}'
			}
		}
		w.set('txt_clean_output', ' NATURAL LOG TRANSFORM ln(x):\n\n' + transformed.join(', '))
		w.toast('Computed Natural Log Transform!')
	})

	win.on_click('btn_tf_remove_outliers', fn (mut w simplegui.SimpleWindow) {
		data := parse_numbers(w.get('txt_data_a'))
		st := compute_summary_stats(data)
		low_fence := st.q1 - 1.5 * st.iqr
		high_fence := st.q3 + 1.5 * st.iqr
		mut filtered := []string{}
		for x in data {
			if x >= low_fence && x <= high_fence {
				filtered << '${x:.2f}'
			}
		}
		w.set('txt_clean_output', ' OUTLIER-CLEANSED DATASET (Filtered ${st.outliers.len} outliers):\n\n' + filtered.join(', '))
		w.toast('Filtered ${st.outliers.len} outliers!')
	})

	win.on_click('btn_tf_sort', fn (mut w simplegui.SimpleWindow) {
		mut data := parse_numbers(w.get('txt_data_a'))
		data.sort()
		mut out_strs := []string{}
		for x in data { out_strs << '${x:.2f}' }
		w.set('txt_clean_output', ' SORTED ASCENDING DATASET (N=${data.len}):\n\n' + out_strs.join(', '))
		w.toast('Sorted data ascending!')
	})

	// -------------------------------------------------------------
	// Tab 6: Benchmark Datasets Actions
	// -------------------------------------------------------------
	win.on_click('btn_ds_iris', fn [run_sample_a_analysis] (mut w simplegui.SimpleWindow) {
		iris_data := '5.1, 4.9, 4.7, 4.6, 5.0, 5.4, 4.6, 5.0, 4.4, 4.9, 5.4, 4.8, 4.8, 4.3, 5.8, 5.7, 5.4, 5.1, 5.7, 5.1, 5.4, 5.1, 4.6, 5.1, 4.8, 5.0, 5.0, 5.2, 5.2, 4.7, 4.8, 5.4, 5.2, 5.5, 4.9, 5.0, 5.5, 4.9, 4.4, 5.1, 5.0, 4.5, 4.4, 5.0, 5.1, 4.8, 5.1, 4.6, 5.3, 5.0'
		w.set('txt_data_a', iris_data)
		w.set('txt_bench_info', ' Loaded Fisher\'s Iris Setosa Sepal Length (cm):\n50 botanical observations measured by Ronald Fisher in 1936.')
		run_sample_a_analysis(mut w)
		w.toast('Loaded Iris Dataset!')
	})

	win.on_click('btn_ds_exam', fn [run_sample_a_analysis] (mut w simplegui.SimpleWindow) {
		exam_data := '88.5, 92.0, 78.5, 85.0, 94.5, 89.0, 72.0, 96.0, 84.5, 90.0, 45.0, 52.0, 48.5, 55.0, 50.0, 91.5, 87.0, 93.5, 76.0, 88.0, 49.0, 53.5, 51.0, 95.0, 89.5, 82.0, 77.5, 90.5, 86.0, 92.5'
		w.set('txt_data_a', exam_data)
		w.set('txt_bench_info', ' Loaded Student Exam Scores (Bimodal Distribution):\n30 test scores demonstrating two distinct student clusters.')
		run_sample_a_analysis(mut w)
		w.toast('Loaded Exam Scores!')
	})

	win.on_click('btn_ds_stock', fn [run_sample_a_analysis] (mut w simplegui.SimpleWindow) {
		stock_data := '0.012, -0.008, 0.025, 0.004, -0.015, 0.009, -0.032, 0.018, 0.005, -0.002, 0.014, -0.011, 0.048, -0.021, 0.007, -0.005, 0.019, -0.003, 0.008, -0.014, 0.022, -0.009, 0.031, -0.018, 0.006, -0.045, 0.015, -0.007, 0.011, -0.013, 0.028, -0.016, 0.009, -0.004, 0.017, -0.025, 0.062, -0.019, 0.008, -0.012'
		w.set('txt_data_a', stock_data)
		w.set('txt_bench_info', ' Loaded S&P 500 Daily Returns (Fat-tailed / Leptokurtic):\n40 trading days of equity returns exhibiting high kurtosis and volatility jumps.')
		run_sample_a_analysis(mut w)
		w.toast('Loaded Stock Returns Dataset!')
	})

	win.on_click('btn_ds_drug', fn (mut w simplegui.SimpleWindow) {
		pre_trial := '142.0, 138.5, 145.0, 150.2, 136.8, 148.4, 152.0, 139.1, 144.5, 147.0, 141.2, 143.8, 149.0, 137.5, 146.2, 151.0, 140.4, 145.8, 148.0, 139.6, 143.0, 147.5, 150.0, 138.0, 144.0'
		post_trial := '128.5, 125.0, 131.2, 134.0, 124.5, 132.8, 136.0, 126.4, 129.5, 133.0, 127.8, 129.0, 135.2, 123.0, 130.5, 135.0, 126.0, 131.4, 132.0, 125.2, 128.0, 132.5, 134.8, 124.0, 129.0'
		w.set('txt_hypo_a', pre_trial)
		w.set('txt_hypo_b', post_trial)
		w.set('txt_bench_info', ' Loaded Hypertension Clinical Drug Trial (Pre vs Post):\n25 paired blood pressure readings demonstrating significant clinical reduction.')
		w.toast('Loaded Drug Trial Dataset into Hypothesis Testing!')
	})

	win.on_click('btn_ds_heights', fn [run_sample_a_analysis] (mut w simplegui.SimpleWindow) {
		heights := '172.5, 168.0, 175.2, 180.1, 165.4, 178.9, 182.0, 169.5, 174.0, 177.3, 171.0, 173.8, 179.4, 166.8, 176.2, 181.5, 170.2, 175.0, 178.0, 169.0, 173.5, 177.0, 180.5, 167.5, 174.8, 172.0, 176.5, 179.0, 171.5, 175.8, 183.2, 164.0, 178.5, 174.2, 170.8'
		w.set('txt_data_a', heights)
		w.set('txt_bench_info', ' Loaded Adult Heights Dataset (Normal Distribution N=35):\nGaussian bell curve sample with mean ~174.5 cm and standard deviation ~4.8 cm.')
		run_sample_a_analysis(mut w)
		w.toast('Loaded Heights Dataset!')
	})

	win.on_click('btn_ds_skewed', fn [run_sample_a_analysis] (mut w simplegui.SimpleWindow) {
		houses := '240.0, 260.0, 275.0, 290.0, 310.0, 325.0, 340.0, 350.0, 365.0, 380.0, 395.0, 410.0, 425.0, 450.0, 475.0, 500.0, 525.0, 550.0, 600.0, 650.0, 700.0, 750.0, 850.0, 950.0, 1100.0, 1250.0, 1500.0, 1800.0, 2200.0, 2800.0'
		w.set('txt_data_a', houses)
		w.set('txt_bench_info', ' Loaded Real Estate Home Prices (in thousands $, Highly Right-Skewed):\n30 housing valuations demonstrating substantial positive skewness and long tail.')
		run_sample_a_analysis(mut w)
		w.toast('Loaded Home Prices Dataset!')
	})

	// -------------------------------------------------------------
	// Tab 7: Ledger Actions
	// -------------------------------------------------------------
	win.on_click('btn_copy_ledger', fn (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(w.get('txt_ledger'))
		w.toast('Copied analysis ledger to clipboard!')
	})

	win.on_click('btn_clear_ledger', fn [mut state] (mut w simplegui.SimpleWindow) {
		state.history_ledger.clear()
		w.set('txt_ledger', 'Ledger cleared.\n')
		w.toast('Cleared ledger.')
	})

	win.on_click('btn_export_ledger', fn (mut w simplegui.SimpleWindow) {
		save_path := w.save_file_picker()
		if save_path != '' {
			mut real_path := save_path
			if !real_path.ends_with('.txt') {
				real_path += '.txt'
			}
			ledger := w.get('txt_ledger')
			os.write_file(real_path, ledger) or {
				w.alert('Export Error', 'Failed to save ledger file.')
				return
			}
			w.toast('Saved analysis ledger to ' + os.file_name(real_path))
		}
	})

	// Initial calculation
	run_sample_a_analysis(mut win)

	println('Statistics Studio Pro configured. Starting event loop...')
	win.run()
}
