module cronutils

import time

fn at(y int, mo int, d int, h int, mi int) time.Time {
	return time.new(time.Time{
		year:   y
		month:  mo
		day:    d
		hour:   h
		minute: mi
	})
}

fn test_steps_on_ranges_and_names() {
	s := parse_cron('1-30/10 9-17 * JAN-MAR MON-FRI')!
	assert s.minute.values == [1, 11, 21]
	assert s.hour.values.len == 9
	assert s.month.values == [1, 2, 3]
	assert s.weekday.values == [1, 2, 3, 4, 5]
	assert parse_cron('5/20 * * * *')!.minute.values == [5, 25, 45]
}

fn test_strict_rejects_garbage() {
	assert !is_valid_cron('abc * * * *')
	assert !is_valid_cron('1-5/x * * * *')
	assert !is_valid_cron('60 * * * *')
	assert !is_valid_cron('* * * *')
	assert is_valid_cron('@daily')
	assert is_valid_cron('0 12 ? * SUN')
}

fn test_macros() {
	assert parse_cron('@hourly')!.minute.values == [0]
	assert cron_to_human('@daily') == 'Every day at midnight'
}

fn test_posix_dom_or_dow() {
	// "1st of month OR Monday": 2026-10-05 is a Monday, not the 1st.
	s := parse_cron('0 0 1 * MON')!
	assert s.matches(at(2026, 10, 5, 0, 0))
	assert s.matches(at(2026, 10, 1, 0, 0))
	assert !s.matches(at(2026, 10, 6, 0, 0))
	// Only one restricted -> AND semantics (classic behaviour).
	s2 := parse_cron('0 0 * * MON')!
	assert !s2.matches(at(2026, 10, 1, 0, 0))
}

fn test_next_after_leap_day_far_away() {
	s := parse_cron('0 0 29 2 *')!
	n := s.next_after(at(2026, 3, 1, 0, 0))!
	assert n.year == 2028 && n.month == 2 && n.day == 29
}

fn test_next_n() {
	s := parse_cron('30 9 * * MON-FRI')!
	// 2026-10-02 is a Friday.
	ts := s.next_n(at(2026, 10, 2, 10, 0), 3)!
	assert ts.len == 3
	assert ts[0].day == 5 && ts[0].hour == 9 && ts[0].minute == 30
	assert ts[1].day == 6
	assert ts[2].day == 7
}
