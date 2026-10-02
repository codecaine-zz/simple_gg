module cronutils

import time

// CronField represents matched integer values for a single field in a cron expression.
pub struct CronField {
pub:
	min_val int
	max_val int
	values  []int
}

// matches returns true if the value v is permitted by this cron field.
pub fn (f CronField) matches(v int) bool {
	return v in f.values
}

// CronSchedule represents a parsed 5-field cron expression.
pub struct CronSchedule {
pub:
	expression string
	minute     CronField
	hour       CronField
	day        CronField
	month      CronField
	weekday    CronField // 0 = Sunday, 1 = Monday ... 6 = Saturday (or 7 = Sunday)
}

fn parse_field(field_str string, min_val int, max_val int) !CronField {
	mut allowed := []int{}
	parts := field_str.split(',')
	for part in parts {
		trimmed := part.trim_space()
		if trimmed.len == 0 {
			continue
		}
		if trimmed == '*' {
			for v in min_val .. (max_val + 1) {
				allowed << v
			}
		} else if trimmed.starts_with('*/') {
			step := trimmed[2..].int()
			if step <= 0 {
				return error('invalid cron step: ${trimmed}')
			}
			for v := min_val; v <= max_val; v += step {
				allowed << v
			}
		} else if trimmed.contains('-') {
			range_parts := trimmed.split('-')
			if range_parts.len != 2 {
				return error('invalid cron range: ${trimmed}')
			}
			start := range_parts[0].int()
			end := range_parts[1].int()
			if start < min_val || end > max_val || start > end {
				return error('invalid cron range bounds: ${trimmed}')
			}
			for v in start .. (end + 1) {
				allowed << v
			}
		} else {
			val := trimmed.int()
			if val < min_val || val > max_val {
				return error('cron value out of bounds: ${trimmed}')
			}
			allowed << val
		}
	}

	if allowed.len == 0 {
		return error('no valid values parsed for field: ${field_str}')
	}

	return CronField{
		min_val: min_val
		max_val: max_val
		values:  allowed
	}
}

// parse_cron parses a standard 5-part cron expression (minute hour day_of_month month day_of_week).
pub fn parse_cron(expr string) !CronSchedule {
	parts := expr.fields()
	if parts.len != 5 {
		return error('cron expression must have 5 fields, got ${parts.len}')
	}

	min_field := parse_field(parts[0], 0, 59)!
	hr_field := parse_field(parts[1], 0, 23)!
	dom_field := parse_field(parts[2], 1, 31)!
	mon_field := parse_field(parts[3], 1, 12)!
	dow_field := parse_field(parts[4], 0, 7)!

	return CronSchedule{
		expression: expr
		minute:     min_field
		hour:       hr_field
		day:        dom_field
		month:      mon_field
		weekday:    dow_field
	}
}

// matches checks if time t satisfies the cron schedule.
pub fn (s CronSchedule) matches(t time.Time) bool {
	if !s.minute.matches(t.minute) {
		return false
	}
	if !s.hour.matches(t.hour) {
		return false
	}
	if !s.day.matches(t.day) {
		return false
	}
	if !s.month.matches(t.month) {
		return false
	}
	// V's day_of_week() returns 1 (Mon) .. 7 (Sun)
	// Cron usually treats 0 and 7 as Sunday
	dow := t.day_of_week() % 7
	if !s.weekday.matches(dow) && !(dow == 0 && s.weekday.matches(7)) {
		return false
	}
	return true
}

// next_after calculates the next timestamp matching the schedule after t (searches up to 366 days).
pub fn (s CronSchedule) next_after(t time.Time) !time.Time {
	// Advance to next full minute
	mut curr := time.new(time.Time{
		year:       t.year
		month:      t.month
		day:        t.day
		hour:       t.hour
		minute:     t.minute
		second:     0
		nanosecond: 0
	}).add_seconds(60)

	max_iterations := 366 * 24 * 60
	for _ in 0 .. max_iterations {
		if s.matches(curr) {
			return curr
		}
		curr = curr.add_seconds(60)
	}
	return error('no matching cron time found within 1 year')
}

// cron_to_human converts a standard cron expression into a human-readable English summary.
pub fn cron_to_human(expr string) string {
	parts := expr.fields()
	if parts.len != 5 {
		return expr
	}
	m, h, dom, mon, dow := parts[0], parts[1], parts[2], parts[3], parts[4]

	if m == '*' && h == '*' && dom == '*' && mon == '*' && dow == '*' {
		return 'Every minute'
	}
	if m.starts_with('*/') && h == '*' && dom == '*' && mon == '*' && dow == '*' {
		return 'Every ${m[2..]} minutes'
	}
	if m == '0' && h == '*' && dom == '*' && mon == '*' && dow == '*' {
		return 'Every hour'
	}
	if m == '0' && h == '0' && dom == '*' && mon == '*' && dow == '*' {
		return 'Every day at midnight'
	}
	if m == '0' && h == '0' && dom == '*' && mon == '*' && dow == '1' {
		return 'Every Monday at midnight'
	}
	return 'At ${h}:${m} on day ${dom} of month ${mon}, weekday ${dow}'
}
