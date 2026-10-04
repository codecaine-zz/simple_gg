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
	// POSIX rule: when BOTH day-of-month and day-of-week are restricted (not `*`),
	// a day matches if EITHER field matches. Set by parse_cron.
	dom_restricted bool
	dow_restricted bool
}

const month_names = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV',
	'DEC']
const day_names = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']

// parse_atom parses a single number or a JAN..DEC / SUN..SAT name, strictly.
fn parse_atom(s string, min_val int, max_val int) !int {
	up := s.to_upper()
	if min_val == 1 && max_val == 12 {
		idx := month_names.index(up)
		if idx >= 0 {
			return idx + 1
		}
	}
	if min_val == 0 && max_val == 7 {
		idx := day_names.index(up)
		if idx >= 0 {
			return idx
		}
	}
	if s.len == 0 || !s.bytes().all(it.is_digit()) {
		return error('invalid cron value: "${s}"')
	}
	v := s.int()
	if v < min_val || v > max_val {
		return error('cron value out of bounds: ${s}')
	}
	return v
}

fn parse_field(field_str string, min_val int, max_val int) !CronField {
	mut seen := []bool{len: max_val + 1}
	for part in field_str.split(',') {
		trimmed := part.trim_space()
		if trimmed.len == 0 {
			continue
		}
		mut base := trimmed
		mut step := 1
		if trimmed.contains('/') {
			b, st := trimmed.split_once('/') or { trimmed, '' }
			if st.len == 0 || !st.bytes().all(it.is_digit()) || st.int() <= 0 {
				return error('invalid cron step: ${trimmed}')
			}
			base = b
			step = st.int()
		}
		mut start := min_val
		mut end := max_val
		if base == '*' || base == '?' {
			// full range
		} else if base.contains('-') {
			lo, hi := base.split_once('-') or { base, '' }
			start = parse_atom(lo, min_val, max_val)!
			end = parse_atom(hi, min_val, max_val)!
			if start > end {
				return error('invalid cron range bounds: ${trimmed}')
			}
		} else {
			start = parse_atom(base, min_val, max_val)!
			// `N/step` means N..max stepping; a bare `N` is a single value.
			end = if trimmed.contains('/') { max_val } else { start }
		}
		for v := start; v <= end; v += step {
			seen[v] = true
		}
	}
	mut allowed := []int{}
	for v in min_val .. max_val + 1 {
		if seen[v] {
			allowed << v
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

// expand_macro maps @yearly/@annually/@monthly/@weekly/@daily/@midnight/@hourly to 5 fields.
fn expand_macro(expr string) string {
	return match expr.trim_space().to_lower() {
		'@yearly', '@annually' { '0 0 1 1 *' }
		'@monthly' { '0 0 1 * *' }
		'@weekly' { '0 0 * * 0' }
		'@daily', '@midnight' { '0 0 * * *' }
		'@hourly' { '0 * * * *' }
		else { expr }
	}
}

fn is_unrestricted(f string) bool {
	return f == '*' || f == '?'
}

// parse_cron parses a standard 5-part cron expression (minute hour day_of_month month day_of_week).
// Supports lists, ranges, steps on ranges (`1-30/5`), names (`MON-FRI`, `JAN`) and macros (`@daily`).
pub fn parse_cron(expr string) !CronSchedule {
	parts := expand_macro(expr).fields()
	if parts.len != 5 {
		return error('cron expression must have 5 fields, got ${parts.len}')
	}

	min_field := parse_field(parts[0], 0, 59)!
	hr_field := parse_field(parts[1], 0, 23)!
	dom_field := parse_field(parts[2], 1, 31)!
	mon_field := parse_field(parts[3], 1, 12)!
	dow_field := parse_field(parts[4], 0, 7)!

	return CronSchedule{
		expression:     expr
		minute:         min_field
		hour:           hr_field
		day:            dom_field
		month:          mon_field
		weekday:        dow_field
		dom_restricted: !is_unrestricted(parts[2])
		dow_restricted: !is_unrestricted(parts[4])
	}
}

// is_valid_cron reports whether expr parses as a cron expression.
pub fn is_valid_cron(expr string) bool {
	parse_cron(expr) or { return false }
	return true
}

fn (s CronSchedule) day_matches(t time.Time) bool {
	// V's day_of_week() returns 1 (Mon) .. 7 (Sun); cron treats 0 and 7 as Sunday.
	dow := t.day_of_week() % 7
	dow_ok := s.weekday.matches(dow) || (dow == 0 && s.weekday.matches(7))
	dom_ok := s.day.matches(t.day)
	if s.dom_restricted && s.dow_restricted {
		return dom_ok || dow_ok
	}
	return dom_ok && dow_ok
}

// matches checks if time t satisfies the cron schedule.
pub fn (s CronSchedule) matches(t time.Time) bool {
	return s.minute.matches(t.minute) && s.hour.matches(t.hour) && s.month.matches(t.month)
		&& s.day_matches(t)
}

fn mk_time(year int, month int, day int, hour int, minute int) time.Time {
	return time.new(time.Time{
		year:   year
		month:  month
		day:    day
		hour:   hour
		minute: minute
	})
}

// next_after calculates the next timestamp matching the schedule strictly after t.
// Uses field skipping (month -> day -> hour -> minute), so even rare schedules such as
// `0 0 29 2 *` (leap days) resolve instantly; searches up to 10 years ahead.
pub fn (s CronSchedule) next_after(t time.Time) !time.Time {
	mut c := mk_time(t.year, t.month, t.day, t.hour, t.minute).add_seconds(60)
	limit := t.year + 10
	for c.year <= limit {
		if !s.month.matches(c.month) {
			c = if c.month == 12 {
				mk_time(c.year + 1, 1, 1, 0, 0)
			} else {
				mk_time(c.year, c.month + 1, 1, 0, 0)
			}
			continue
		}
		if !s.day_matches(c) {
			c = mk_time(c.year, c.month, c.day, 0, 0).add_days(1)
			continue
		}
		if !s.hour.matches(c.hour) {
			c = mk_time(c.year, c.month, c.day, c.hour, 0).add_seconds(3600)
			continue
		}
		if !s.minute.matches(c.minute) {
			c = c.add_seconds(60)
			continue
		}
		return c
	}
	return error('no matching cron time found within 10 years')
}

// next_n returns the next `n` matching times strictly after t.
pub fn (s CronSchedule) next_n(t time.Time, n int) ![]time.Time {
	mut out := []time.Time{cap: if n > 0 { n } else { 0 }}
	mut cur := t
	for _ in 0 .. n {
		cur = s.next_after(cur)!
		out << cur
	}
	return out
}

// cron_to_human converts a standard cron expression into a human-readable English summary.
pub fn cron_to_human(expr string) string {
	parts := expand_macro(expr).fields()
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
