module main

import time
import timeutils

fn main() {
	println('==================================================')
	println('                demo_timeutils                    ')
	println('==================================================')

	now := time.now()

	// 1. Relative time
	past_2h := now.add(-7200 * time.second)
	future_3d := now.add(86400 * 3 * time.second)
	println('Relative Time:')
	println('  2 hours ago:   "${timeutils.time_ago(past_2h)}"')
	println('  in 3 days:     "${timeutils.time_until(future_3d)}"')
	assert timeutils.time_ago(past_2h) == '2 hours ago'
	assert timeutils.time_until(future_3d) == 'in 3 days'

	// 2. Duration formatting
	dur1 := timeutils.format_duration(250 * time.millisecond)
	dur2 := timeutils.format_duration(3665 * time.second)
	println('\nFormatted Durations:')
	println('  250ms -> ${dur1}')
	println('  3665s -> ${dur2}')
	assert dur1 == '250ms'
	assert dur2 == '1h 1m 5s'

	// 3. ISO 8601 Formatting & Parsing
	iso_str := timeutils.to_iso8601(now)
	parsed_time := timeutils.from_iso8601(iso_str)!
	println('\nISO 8601:')
	println('  Encoded: ${iso_str}')
	println('  Parsed:  Year=${parsed_time.year}, Month=${parsed_time.month}, Day=${parsed_time.day}')
	assert parsed_time.year == now.year
	assert parsed_time.month == now.month

	// 4. Stopwatch Benchmarking
	mut sw := timeutils.new_stopwatch()
	time.sleep(10 * time.millisecond)
	sw.stop()
	println('\nStopwatch: ${sw.elapsed_ms():.2f} ms')
	assert sw.elapsed_ms() >= 9.0

	// 5. Benchmark harness
	bm := timeutils.benchmark_fn('loop_add', 1000, fn () {
		mut sum := 0
		for i in 0 .. 100 {
			sum += i
		}
		_ = sum
	})
	println('Benchmark result: ${bm.str()}, ops/sec: ${bm.ops_per_sec}')

	println('\n✔ timeutils demo completed successfully!')
}
