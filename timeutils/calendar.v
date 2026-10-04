module timeutils

import time

fn at_midnight(year int, month int, day int) time.Time {
	return time.new(time.Time{
		year:  year
		month: month
		day:   day
	})
}

fn with_date(t time.Time, year int, month int, day int) time.Time {
	return time.new(time.Time{
		year:       year
		month:      month
		day:        day
		hour:       t.hour
		minute:     t.minute
		second:     t.second
		nanosecond: t.nanosecond
	})
}

// is_leap_year reports whether year is a Gregorian leap year.
pub fn is_leap_year(year int) bool {
	return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
}

// days_in_month returns the number of days in the given month (1-12) of year.
pub fn days_in_month(year int, month int) int {
	return match month {
		2 {
			if is_leap_year(year) { 29 } else { 28 }
		}
		4, 6, 9, 11 { 30 }
		else { 31 }
	}
}

// add_months adds n calendar months (negative to subtract), clamping the day to the target month's
// length so Jan 31 + 1 month = Feb 28/29 (never rolls into March). Time of day is preserved.
pub fn add_months(t time.Time, n int) time.Time {
	total := t.year * 12 + (t.month - 1) + n
	year := total / 12
	month := total % 12 + 1
	day := if t.day > days_in_month(year, month) { days_in_month(year, month) } else { t.day }
	return with_date(t, year, month, day)
}

// add_years adds n years, clamping Feb 29 to Feb 28 in non-leap years.
pub fn add_years(t time.Time, n int) time.Time {
	return add_months(t, n * 12)
}

// start_of_week returns midnight of the first day of t's week (Monday when monday_first, else Sunday).
pub fn start_of_week(t time.Time, monday_first bool) time.Time {
	dow := t.day_of_week() // 1 = Monday .. 7 = Sunday
	back := if monday_first { dow - 1 } else { dow % 7 }
	return start_of_day(t.add_days(-back))
}

// end_of_week returns the last nanosecond of t's week.
pub fn end_of_week(t time.Time, monday_first bool) time.Time {
	return end_of_day(start_of_week(t, monday_first).add_days(6))
}

// start_of_month returns midnight on the first day of t's month.
pub fn start_of_month(t time.Time) time.Time {
	return at_midnight(t.year, t.month, 1)
}

// end_of_month returns the last nanosecond of t's month.
pub fn end_of_month(t time.Time) time.Time {
	return end_of_day(at_midnight(t.year, t.month, days_in_month(t.year, t.month)))
}

// start_of_year returns midnight on January 1st of t's year.
pub fn start_of_year(t time.Time) time.Time {
	return at_midnight(t.year, 1, 1)
}

// end_of_year returns the last nanosecond of December 31st of t's year.
pub fn end_of_year(t time.Time) time.Time {
	return end_of_day(at_midnight(t.year, 12, 31))
}

// quarter returns the calendar quarter (1-4) of t.
pub fn quarter(t time.Time) int {
	return (t.month - 1) / 3 + 1
}

// iso_week returns the ISO 8601 week-numbering year and week (1-53) for t.
// Note the year can differ from t.year near January 1st (e.g. 2021-01-01 is week 53 of 2020).
pub fn iso_week(t time.Time) (int, int) {
	dow := t.day_of_week()
	// Thursday of the current ISO week decides the year.
	thursday := at_midnight(t.year, t.month, t.day).add_days(4 - dow)
	year := thursday.year
	week := (thursday.year_day() - 1) / 7 + 1
	return year, week
}

// age returns the number of full years between birth and at (e.g. for age verification).
pub fn age(birth time.Time, at time.Time) int {
	mut years := at.year - birth.year
	if at.month < birth.month || (at.month == birth.month && at.day < birth.day) {
		years--
	}
	return years
}

// business_days_between counts weekdays (Mon-Fri) in [a, b), independent of argument order.
pub fn business_days_between(a time.Time, b time.Time) int {
	mut start := start_of_day(a)
	mut end := start_of_day(b)
	if start > end {
		start, end = end, start
	}
	total := days_between(start, end)
	full_weeks := total / 7
	mut count := full_weeks * 5
	mut cur := start.add_days(full_weeks * 7)
	for _ in 0 .. total % 7 {
		if cur.day_of_week() <= 5 {
			count++
		}
		cur = cur.add_days(1)
	}
	return count
}

// next_weekday returns the next date strictly after t falling on weekday (1 = Monday .. 7 = Sunday).
pub fn next_weekday(t time.Time, weekday int) time.Time {
	mut delta := (weekday - t.day_of_week() + 7) % 7
	if delta == 0 {
		delta = 7
	}
	return t.add_days(delta)
}

// format_duration_long renders a duration in words (e.g. "2 days, 3 hours, 5 minutes").
// Shows at most max_units of the largest non-zero units; sub-second durations render as milliseconds.
pub fn format_duration_long(d time.Duration, max_units int) string {
	neg := d < 0
	mut ns := if neg { -i64(d) } else { i64(d) }
	if ns < i64(time.second) {
		ms := ns / i64(time.millisecond)
		return (if neg { '-' } else { '' }) + plural(ms, 'millisecond')
	}
	units := [i64(86400) * i64(time.second), i64(time.hour), i64(time.minute), i64(time.second)]
	names := ['day', 'hour', 'minute', 'second']
	mut parts := []string{}
	limit := if max_units <= 0 { 4 } else { max_units }
	for i, u in units {
		v := ns / u
		ns %= u
		if v > 0 && parts.len < limit {
			parts << plural(v, names[i])
		}
	}
	return (if neg { '-' } else { '' }) + parts.join(', ')
}

fn plural(n i64, unit string) string {
	return if n == 1 { '1 ${unit}' } else { '${n} ${unit}s' }
}

// parse_any parses the most common timestamp layouts: RFC 3339 / ISO 8601, "YYYY-MM-DD",
// "YYYY-MM-DD HH:MM[:SS]", RFC 2822 / HTTP dates, and unix seconds or milliseconds.
pub fn parse_any(s string) !time.Time {
	v := s.trim_space()
	if v.len == 0 {
		return error('empty timestamp')
	}
	if v.is_int() {
		n := v.i64()
		// Heuristic: 13+ digits is milliseconds.
		return if v.trim_left('-').len >= 13 { time.unix_milli(n) } else { time.unix(n) }
	}
	if t := time.parse_rfc3339(v) {
		return t
	}
	if t := time.parse_iso8601(v) {
		return t
	}
	if v.len == 10 && v[4] == `-` && v[7] == `-` {
		return time.parse('${v} 00:00:00')
	}
	if v.len == 16 && v[10] in [` `, `T`] {
		return time.parse(v[..10] + ' ' + v[11..] + ':00')
	}
	if t := time.parse(v.replace('T', ' ')) {
		return t
	}
	if t := time.parse_rfc2822(v) {
		return t
	}
	return error('unrecognised timestamp format: "${s}"')
}

// each_day returns midnight of every calendar day in the range (inclusive of both ends).
pub fn (r TimeRange) each_day() []time.Time {
	mut days := []time.Time{}
	mut cur := start_of_day(r.start)
	last := start_of_day(r.end)
	for cur <= last {
		days << cur
		cur = cur.add_days(1)
	}
	return days
}

// intersection returns the overlapping part of two ranges, or none if they do not overlap.
pub fn (r TimeRange) intersection(other TimeRange) ?TimeRange {
	if !r.overlaps(other) {
		return none
	}
	return TimeRange{
		start: if r.start > other.start { r.start } else { other.start }
		end:   if r.end < other.end { r.end } else { other.end }
	}
}
