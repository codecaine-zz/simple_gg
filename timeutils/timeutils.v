module timeutils

import time

// time_ago returns a human-friendly relative time string describing how long ago t was.
pub fn time_ago(t time.Time) string {
	return time_ago_at(t, time.now())
}

// time_ago_at is time_ago relative to an explicit `now` (deterministic; ideal for tests and servers).
pub fn time_ago_at(t time.Time, now time.Time) string {
	diff := now.unix() - t.unix()
	if diff <= -5 {
		return time_until_at(t, now)
	}
	if diff < 5 {
		return 'just now'
	}
	if diff < 60 {
		return '${diff} seconds ago'
	}
	if diff < 120 {
		return '1 minute ago'
	}
	minutes := diff / 60
	if minutes < 60 {
		return '${minutes} minutes ago'
	}
	if minutes < 120 {
		return '1 hour ago'
	}
	hours := minutes / 60
	if hours < 24 {
		return '${hours} hours ago'
	}
	if hours < 48 {
		return 'yesterday'
	}
	days := hours / 24
	if days < 30 {
		return '${days} days ago'
	}
	if days < 365 {
		months := days / 30
		return if months == 1 { '1 month ago' } else { '${months} months ago' }
	}
	years := days / 365
	return if years == 1 { '1 year ago' } else { '${years} years ago' }
}

// time_until returns a human-friendly relative time string describing how far in the future t is.
pub fn time_until(t time.Time) string {
	return time_until_at(t, time.now())
}

// time_until_at is time_until relative to an explicit `now`.
pub fn time_until_at(t time.Time, now time.Time) string {
	diff := t.unix() - now.unix()
	if diff <= -5 {
		return time_ago_at(t, now)
	}
	if diff < 5 {
		return 'just now'
	}
	if diff < 60 {
		return 'in ${diff} seconds'
	}
	if diff < 120 {
		return 'in 1 minute'
	}
	minutes := diff / 60
	if minutes < 60 {
		return 'in ${minutes} minutes'
	}
	if minutes < 120 {
		return 'in 1 hour'
	}
	hours := minutes / 60
	if hours < 24 {
		return 'in ${hours} hours'
	}
	if hours < 48 {
		return 'tomorrow'
	}
	days := hours / 24
	if days < 30 {
		return 'in ${days} days'
	}
	if days < 365 {
		months := days / 30
		return if months == 1 { 'in 1 month' } else { 'in ${months} months' }
	}
	years := days / 365
	return if years == 1 { 'in 1 year' } else { 'in ${years} years' }
}

// format_duration returns a formatted string for a duration (e.g. "1h 23m 45s" or "250ms").
pub fn format_duration(d time.Duration) string {
	ms := d.milliseconds()
	if ms < 1000 {
		return '${ms}ms'
	}
	seconds := int(ms / 1000)
	if seconds < 60 {
		return '${seconds}s'
	}
	mut s := seconds % 60
	mut m := (seconds / 60) % 60
	h := seconds / 3600

	mut parts := []string{}
	if h > 0 {
		parts << '${h}h'
	}
	if m > 0 || h > 0 {
		parts << '${m}m'
	}
	if s > 0 || parts.len == 0 {
		parts << '${s}s'
	}
	return parts.join(' ')
}

// to_iso8601 converts a time.Time into an ISO 8601 / RFC 3339 formatted string.
pub fn to_iso8601(t time.Time) string {
	return t.format_rfc3339()
}

// from_iso8601 parses an ISO 8601 or RFC 3339 formatted string into a time.Time.
pub fn from_iso8601(s string) !time.Time {
	// Try parsing as rfc3339 first, fallback to parse_iso8601
	return time.parse_rfc3339(s) or { time.parse_iso8601(s)! }
}

// start_of_day returns a Time set to 00:00:00.000 for the date of t.
pub fn start_of_day(t time.Time) time.Time {
	return time.new(time.Time{
		year:       t.year
		month:      t.month
		day:        t.day
		hour:       0
		minute:     0
		second:     0
		nanosecond: 0
	})
}

// end_of_day returns a Time set to 23:59:59.999999999 for the date of t.
pub fn end_of_day(t time.Time) time.Time {
	return time.new(time.Time{
		year:       t.year
		month:      t.month
		day:        t.day
		hour:       23
		minute:     59
		second:     59
		nanosecond: 999_999_999
	})
}

// is_weekend returns true if t falls on Saturday (6) or Sunday (7).
pub fn is_weekend(t time.Time) bool {
	dow := t.day_of_week()
	return dow == 6 || dow == 7
}

// days_between returns the absolute number of calendar days between two times.
pub fn days_between(a time.Time, b time.Time) int {
	a_sod := start_of_day(a).unix()
	b_sod := start_of_day(b).unix()
	diff := if a_sod > b_sod { a_sod - b_sod } else { b_sod - a_sod }
	return int((diff + 43200) / 86400)
}

// Stopwatch represents a high-resolution timer for benchmarking and profiling.
pub struct Stopwatch {
mut:
	start_time time.Time
	stop_time  time.Time
	running    bool
}

// new_stopwatch creates and starts a new Stopwatch.
pub fn new_stopwatch() Stopwatch {
	mut sw := Stopwatch{
		start_time: time.now()
		running:    true
	}
	return sw
}

// start resets and starts the stopwatch.
pub fn (mut sw Stopwatch) start() {
	sw.start_time = time.now()
	sw.running = true
}

// stop stops the stopwatch.
pub fn (mut sw Stopwatch) stop() {
	if sw.running {
		sw.stop_time = time.now()
		sw.running = false
	}
}

// reset clears the stopwatch state.
pub fn (mut sw Stopwatch) reset() {
	sw.start_time = time.Time{}
	sw.stop_time = time.Time{}
	sw.running = false
}

// is_running returns whether the stopwatch is currently active.
pub fn (sw Stopwatch) is_running() bool {
	return sw.running
}

// elapsed returns the duration recorded by the stopwatch.
pub fn (sw Stopwatch) elapsed() time.Duration {
	end := if sw.running { time.now() } else { sw.stop_time }
	return end - sw.start_time
}

// elapsed_ms returns the elapsed time in milliseconds as a float.
pub fn (sw Stopwatch) elapsed_ms() f64 {
	d := sw.elapsed()
	return f64(d.nanoseconds()) / 1_000_000.0
}

// elapsed_seconds returns the elapsed time in seconds as a float.
pub fn (sw Stopwatch) elapsed_seconds() f64 {
	d := sw.elapsed()
	return f64(d.nanoseconds()) / 1_000_000_000.0
}

// measure executes a function and returns the duration it took to complete.
pub fn measure(action fn ()) time.Duration {
	start := time.now()
	action()
	return time.now() - start
}

// BenchmarkResult contains timing and throughput metrics from a benchmark run.
pub struct BenchmarkResult {
pub:
	name              string
	iterations        int
	total_duration_ms f64
	avg_duration_ms   f64
	ops_per_sec       f64
}

// str returns a formatted summary of the benchmark result.
pub fn (b BenchmarkResult) str() string {
	return '${b.name}: ${b.iterations} iters, total=${b.total_duration_ms:.2f}ms, avg=${b.avg_duration_ms:.4f}ms, ops/sec=${b.ops_per_sec:.1f}'
}

// benchmark_fn runs a function for N iterations and returns throughput and timing metrics.
pub fn benchmark_fn(name string, iterations int, f fn ()) BenchmarkResult {
	iters := if iterations > 0 { iterations } else { 1 }
	start := time.now()
	for _ in 0 .. iters {
		f()
	}
	total_duration := time.now() - start
	total_ms := f64(total_duration.nanoseconds()) / 1_000_000.0
	avg_ms := total_ms / f64(iters)
	total_sec := total_ms / 1000.0
	ops_sec := if total_sec > 0.0 { f64(iters) / total_sec } else { 0.0 }

	return BenchmarkResult{
		name:              name
		iterations:        iters
		total_duration_ms: total_ms
		avg_duration_ms:   avg_ms
		ops_per_sec:       ops_sec
	}
}

// parse_duration parses a human duration string (e.g. "1h 30m", "500ms", "10s", "2d", "1w", "-5m") into time.Duration.
pub fn parse_duration(s string) !time.Duration {
	mut clean := s.trim_space().to_lower().replace('µs', 'us')
	if clean.len == 0 {
		return error('empty duration string')
	}
	mut sign := i64(1)
	if clean.starts_with('-') || clean.starts_with('+') {
		if clean[0] == `-` {
			sign = -1
		}
		clean = clean[1..].trim_space()
	}
	mut total_ns := i64(0)
	mut num_buf := ''
	mut i := 0
	for i < clean.len {
		ch := clean[i]
		if (ch >= `0` && ch <= `9`) || ch == `.` {
			num_buf += ch.ascii_str()
			i++
		} else if ch == ` ` || ch == `\t` || ch == `,` {
			i++
		} else {
			// Extract unit
			mut unit_buf := ''
			for i < clean.len && clean[i] >= `a` && clean[i] <= `z` {
				unit_buf += clean[i].ascii_str()
				i++
			}
			if unit_buf.len == 0 {
				return error('unexpected character in duration: ${clean[i..i + 1]}')
			}
			if num_buf.len == 0 {
				return error('missing numeric value before unit: ${unit_buf}')
			}
			val := num_buf.f64()
			num_buf = ''
			match unit_buf {
				'ns' {
					total_ns += i64(val)
				}
				'us' {
					total_ns += i64(val * 1_000.0)
				}
				'ms' {
					total_ns += i64(val * 1_000_000.0)
				}
				's', 'sec', 'secs', 'second', 'seconds' {
					total_ns += i64(val * 1_000_000_000.0)
				}
				'm', 'min', 'mins', 'minute', 'minutes' {
					total_ns += i64(val * 60_000_000_000.0)
				}
				'h', 'hr', 'hrs', 'hour', 'hours' {
					total_ns += i64(val * 3_600_000_000_000.0)
				}
				'd', 'day', 'days' {
					total_ns += i64(val * 86_400_000_000_000.0)
				}
				'w', 'wk', 'week', 'weeks' {
					total_ns += i64(val * 604_800_000_000_000.0)
				}
				else {
					return error('unknown duration unit: ${unit_buf}')
				}
			}
		}
	}
	if num_buf.len > 0 {
		return error('missing unit after "${num_buf}" (e.g. "${num_buf}s")')
	}
	return time.Duration(sign * total_ns)
}

// add_business_days adds or subtracts N business days to t, skipping Saturdays and Sundays.
pub fn add_business_days(start time.Time, days int) time.Time {
	if days == 0 {
		return start
	}
	step := if days > 0 { 1 } else { -1 }
	mut remaining := if days > 0 { days } else { -days }
	mut current := start
	for remaining > 0 {
		current = current.add_days(step)
		dow := current.day_of_week()
		// 1=Mon .. 5=Fri, 6=Sat, 7=Sun
		if dow >= 1 && dow <= 5 {
			remaining--
		}
	}
	return current
}

// TimeRange represents an inclusive time span between start and end.
pub struct TimeRange {
pub:
	start time.Time
	end   time.Time
}

// contains returns true if the specified time is within this range.
pub fn (r TimeRange) contains(t time.Time) bool {
	return t >= r.start && t <= r.end
}

// overlaps returns true if this range intersects with another TimeRange.
pub fn (r TimeRange) overlaps(other TimeRange) bool {
	return r.start <= other.end && r.end >= other.start
}

// duration returns the total duration between start and end.
pub fn (r TimeRange) duration() time.Duration {
	return r.end - r.start
}
