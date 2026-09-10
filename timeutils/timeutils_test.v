module timeutils

import time

fn test_relative_time() {
	now := time.now()

	past_5m := now.add(-300 * time.second)
	assert time_ago(past_5m) == '5 minutes ago'

	past_2h := now.add(-7200 * time.second)
	assert time_ago(past_2h) == '2 hours ago'

	past_1d := now.add(-86400 * time.second)
	assert time_ago(past_1d) == 'yesterday'

	future_10m := now.add(600 * time.second)
	assert time_until(future_10m) == 'in 10 minutes'

	future_1d := now.add(86400 * time.second)
	assert time_until(future_1d) == 'tomorrow'
}

fn test_format_duration() {
	assert format_duration(350 * time.millisecond) == '350ms'
	assert format_duration(45 * time.second) == '45s'
	assert format_duration(125 * time.second) == '2m 5s'
	assert format_duration(3665 * time.second) == '1h 1m 5s'
}

fn test_iso8601() {
	iso_str := '2026-09-10T12:00:00.000Z'
	t := from_iso8601(iso_str) or { time.Time{} }
	assert t.year == 2026
	assert t.month == 9
	assert t.day == 10
}

fn test_calendar_helpers() {
	t := time.new(time.Time{
		year: 2026
		month: 9
		day: 10
		hour: 14
		minute: 30
		second: 15
	})

	sod := start_of_day(t)
	assert sod.hour == 0 && sod.minute == 0 && sod.second == 0

	eod := end_of_day(t)
	assert eod.hour == 23 && eod.minute == 59 && eod.second == 59

	// 2026-09-10 is Thursday, 2026-09-12 is Saturday
	sat := time.new(time.Time{
		year: 2026
		month: 9
		day: 12
	})
	assert is_weekend(sat) == true
	assert is_weekend(t) == false

	t2 := time.new(time.Time{
		year: 2026
		month: 9
		day: 15
	})
	assert days_between(t, t2) == 5
}

fn test_stopwatch() {
	mut sw := new_stopwatch()
	time.sleep(10 * time.millisecond)
	sw.stop()

	assert sw.elapsed_ms() >= 5.0
	assert !sw.is_running()

	sw.reset()
	assert sw.elapsed_ms() == 0.0

	// measure function
	d := measure(fn () {
		time.sleep(5 * time.millisecond)
	})
	assert d.milliseconds() >= 3
}

fn test_benchmark_fn() {
	res := benchmark_fn('arithmetic_test', 100, fn () {
		mut x := 0
		for i in 0 .. 1000 {
			x += i
		}
	})
	assert res.iterations == 100
	assert res.total_duration_ms > 0.0
	assert res.ops_per_sec > 0.0
	assert res.str().contains('arithmetic_test')
}

