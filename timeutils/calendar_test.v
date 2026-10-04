module timeutils

import time

fn mk_date(y int, m int, day int) time.Time {
	return time.new(time.Time{
		year:  y
		month: m
		day:   day
	})
}

fn test_relative_time_fixes() {
	now := mk_date(2026, 10, 4)
	assert time_ago_at(now.add_days(-362), now) == '12 months ago' // used to be "0 years ago"
	assert time_ago_at(now.add_days(-400), now) == '1 year ago'
	assert time_ago_at(now.add(3 * time.hour), now) == 'in 3 hours'
	assert time_until_at(now.add(-3 * time.hour), now) == '3 hours ago'
	assert time_ago_at(now, now) == 'just now'
}

fn test_parse_duration_fixes() {
	assert parse_duration('1w 2d')! == time.Duration(9 * 24 * time.hour)
	assert parse_duration('-5m')! == -5 * time.minute
	assert parse_duration('1 hour, 30 mins')! == 90 * time.minute
	assert parse_duration('250µs')! == 250 * time.microsecond
	if _ := parse_duration('10') {
		assert false, 'unitless numbers must be rejected'
	}
	if _ := parse_duration('5s!') {
		assert false
	}
}

fn test_month_math() {
	assert is_leap_year(2024) && !is_leap_year(1900) && is_leap_year(2000)
	assert days_in_month(2024, 2) == 29
	assert days_in_month(2023, 2) == 28
	assert days_in_month(2023, 4) == 30
	jan31 := mk_date(2023, 1, 31)
	feb := add_months(jan31, 1)
	assert feb.month == 2 && feb.day == 28
	assert add_months(mk_date(2024, 1, 31), 1).day == 29
	back := add_months(mk_date(2024, 3, 15), -14)
	assert back.year == 2023 && back.month == 1 && back.day == 15
	assert add_years(mk_date(2024, 2, 29), 1).day == 28
}

fn test_boundaries() {
	wed := mk_date(2026, 10, 7).add(15 * time.hour)
	mon := start_of_week(wed, true)
	assert mon.day == 5 && mon.hour == 0
	sun := start_of_week(wed, false)
	assert sun.day == 4
	assert end_of_week(wed, true).day == 11
	assert start_of_month(wed).day == 1
	eom := end_of_month(mk_date(2024, 2, 10))
	assert eom.day == 29 && eom.hour == 23
	assert start_of_year(wed).month == 1
	assert end_of_year(wed).day == 31
	assert quarter(wed) == 4
	assert quarter(mk_date(2026, 3, 31)) == 1
}

fn test_iso_week() {
	y1, w1 := iso_week(mk_date(2021, 1, 1))
	assert y1 == 2020 && w1 == 53
	y2, w2 := iso_week(mk_date(2026, 10, 4))
	assert y2 == 2026 && w2 == 40
	y3, w3 := iso_week(mk_date(2024, 12, 30))
	assert y3 == 2025 && w3 == 1
}

fn test_age_business_days_next_weekday() {
	assert age(mk_date(1990, 10, 5), mk_date(2026, 10, 4)) == 35
	assert age(mk_date(1990, 10, 4), mk_date(2026, 10, 4)) == 36
	// Mon 2026-10-05 .. Mon 2026-10-19 = 10 business days.
	assert business_days_between(mk_date(2026, 10, 5), mk_date(2026, 10, 19)) == 10
	assert business_days_between(mk_date(2026, 10, 19), mk_date(2026, 10, 5)) == 10
	assert business_days_between(mk_date(2026, 10, 10), mk_date(2026, 10, 12)) == 0
	n := next_weekday(mk_date(2026, 10, 5), 1)
	assert n.day == 12
	assert next_weekday(mk_date(2026, 10, 5), 5).day == 9
}

fn test_format_duration_long() {
	assert format_duration_long(2 * 24 * time.hour + 3 * time.hour + 5 * time.minute, 2) == '2 days, 3 hours'
	assert format_duration_long(24 * time.hour + 5 * time.minute, 0) == '1 day, 5 minutes'
	assert format_duration_long(1500 * time.millisecond, 0) == '1 second'
	assert format_duration_long(250 * time.millisecond, 0) == '250 milliseconds'
	assert format_duration_long(-90 * time.second, 0) == '-1 minute, 30 seconds'
}

fn test_parse_any() {
	assert parse_any('2026-10-04')!.day == 4
	assert parse_any('2026-10-04 13:45')!.minute == 45
	assert parse_any('2026-10-04T13:45:10Z')!.second == 10
	assert parse_any('2026-10-04 13:45:10')!.hour == 13
	assert parse_any('1700000000')!.unix() == 1700000000
	assert parse_any('1700000000123')!.unix() == 1700000000
	if _ := parse_any('not a date') {
		assert false
	}
}

fn test_time_range_extras() {
	r := TimeRange{
		start: mk_date(2026, 10, 1).add(5 * time.hour)
		end:   mk_date(2026, 10, 3)
	}
	assert r.each_day().len == 3
	other := TimeRange{
		start: mk_date(2026, 10, 2)
		end:   mk_date(2026, 10, 9)
	}
	inter := r.intersection(other)?
	assert inter.start == mk_date(2026, 10, 2) && inter.end == mk_date(2026, 10, 3)
	far := TimeRange{
		start: mk_date(2027, 1, 1)
		end:   mk_date(2027, 1, 2)
	}
	assert r.intersection(far) == none
}
