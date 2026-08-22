module main

import simplecli

fn main() {
	mut app := simplecli.new_app('statistics-cli', '1.0.0')
	app.set_description('Statistical Analysis & Dataset Metrics CLI')

	app.add_flag_string('data', 'd', '10,25,32,45,58,62,75,88,94', 'Comma-separated list of float numbers')
	app.add_flag_string('file', 'f', '', 'Input text/CSV file with numeric column')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive statistics calculator')

	app.parse_cli() or { return }

	app.banner('Statistics Studio CLI', 'v1.0.0 - Descriptive & Mathematical Statistics')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	data_str := app.get_flag_string('data')
	file_path := app.get_flag_string('file')

	mut numbers := []f64{}
	if file_path.len > 0 && app.file_exists(file_path) {
		lines := app.read_file(file_path).split_into_lines()
		for l in lines {
			n := l.trim_space().f64()
			if n != 0.0 || l.trim_space() == '0' {
				numbers << n
			}
		}
	} else {
		parts := data_str.split(',')
		for p in parts {
			numbers << p.trim_space().f64()
		}
	}

	if numbers.len == 0 {
		app.error('No valid numbers provided for statistical analysis.')
		return
	}

	display_stats(mut app, numbers)
}

fn display_stats(mut app simplecli.SimpleCli, data []f64) {
	app.reset_timer()
	mean_val := app.stats_mean(data)
	median_val := app.stats_median(data)
	std_dev := app.stats_std_dev(data)
	geo_mean := app.stats_geometric_mean(data)
	harm_mean := app.stats_harmonic_mean(data)
	rms_val := app.stats_rms(data)
	min_val := app.stats_min(data)
	max_val := app.stats_max(data)
	range_val := max_val - min_val

	app.table(
		['Statistical Metric', 'Calculated Value'],
		[
			['Sample Count (N)', '${data.len}'],
			['Arithmetic Mean (μ)', '${mean_val:.4f}'],
			['Median (Q2)', '${median_val:.4f}'],
			['Standard Deviation (σ)', '${std_dev:.4f}'],
			['Root Mean Square (RMS)', '${rms_val:.4f}'],
			['Geometric Mean', '${geo_mean:.4f}'],
			['Harmonic Mean', '${harm_mean:.4f}'],
			['Minimum Value', '${min_val:.4f}'],
			['Maximum Value', '${max_val:.4f}'],
			['Range (Max - Min)', '${range_val:.4f}'],
		]
	)
	app.success('Calculated in ${app.elapsed_ms()} ms.')
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Statistics REPL', 'Input numbers to calculate central tendency and dispersion.')
	input := app.prompt('Enter comma-separated numbers', '12.5, 45.2, 88.0, 102.4, 33.1, 74.9')
	mut nums := []f64{}
	for p in input.split(',') {
		nums << p.trim_space().f64()
	}
	display_stats(mut app, nums)
}
