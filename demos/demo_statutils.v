module main

import statutils

fn main() {
	println('==================================================')
	println('                demo_statutils                    ')
	println('==================================================')

	data := [12.0, 15.0, 18.0, 20.0, 22.0, 25.0, 30.0, 45.0, 45.0, 50.0]
	println('Dataset: ${data}')

	// 1. Descriptive stats
	summary := statutils.stats_summary(data)
	println('Count:     ${summary.count}')
	println('Min / Max: ${summary.min} / ${summary.max}')
	println('Mean:      ${summary.mean:.2f}')
	println('Median:    ${summary.median:.2f}')
	println('StdDev:    ${summary.sample_std_dev:.2f}')
	println('IQR:       ${summary.iqr:.2f}')
	println('Skewness:  ${summary.skewness:.2f}')
	assert summary.count == 10
	assert summary.min == 12.0
	assert summary.max == 50.0

	// 2. Linear Regression (OLS)
	xs := [1.0, 2.0, 3.0, 4.0, 5.0]
	ys := [2.1, 4.0, 6.2, 8.0, 9.9]
	reg := statutils.stats_linear_regression(xs, ys)!
	println('\nOLS Linear Regression (x -> y):')
	println('  Slope:     ${reg.slope:.2f}')
	println('  Intercept: ${reg.intercept:.2f}')
	println('  R²:        ${reg.r_squared:.4f}')
	println('  Corr:      ${reg.correlation:.4f}')
	assert reg.slope > 1.9
	assert reg.r_squared > 0.99

	// 3. Moving Average
	ma := statutils.stats_moving_average([10.0, 20.0, 30.0, 40.0, 50.0], 3)!
	println('\n3-point Moving Average: ${ma}')
	assert ma.len == 3
	assert ma[0] == 20.0 // (10+20+30)/3
	assert ma[1] == 30.0 // (20+30+40)/3
	assert ma[2] == 40.0 // (30+40+50)/3

	println('\n✔ statutils demo completed successfully!')
}
