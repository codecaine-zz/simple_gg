module timeutils

import time

// time_ago returns a human-friendly relative time string describing how long ago t was.
pub fn time_ago(t time.Time) string {
	now := time.now()
	diff := now.unix() - t.unix()
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
	months := days / 30
	if months < 12 {
		return if months == 1 { '1 month ago' } else { '${months} months ago' }
	}
	years := days / 365
	return if years == 1 { '1 year ago' } else { '${years} years ago' }
}

// time_until returns a human-friendly relative time string describing how far in the future t is.
pub fn time_until(t time.Time) string {
	now := time.now()
	diff := t.unix() - now.unix()
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
	months := days / 30
	if months < 12 {
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
	return time.parse_rfc3339(s) or { time.parse_iso8601(s) }
}

// start_of_day returns a Time set to 00:00:00.000 for the date of t.
pub fn start_of_day(t time.Time) time.Time {
	return time.new(time.Time{
		year: t.year
		month: t.month
		day: t.day
		hour: 0
		minute: 0
		second: 0
		nanosecond: 0
	})
}

// end_of_day returns a Time set to 23:59:59.999999999 for the date of t.
pub fn end_of_day(t time.Time) time.Time {
	return time.new(time.Time{
		year: t.year
		month: t.month
		day: t.day
		hour: 23
		minute: 59
		second: 59
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
		name: name
		iterations: iters
		total_duration_ms: total_ms
		avg_duration_ms: avg_ms
		ops_per_sec: ops_sec
	}
}

