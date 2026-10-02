module main

import cronutils
import time

fn main() {
	println('=== cronutils Demo ===')

	expr := '*/10 9-17 * * 1-5'
	sched := cronutils.parse_cron(expr) or { panic(err) }
	println('Parsed cron: ${expr}')

	human := cronutils.cron_to_human('0 0 * * *')
	println('Human description for "0 0 * * *": ${human}')
	assert human == 'Every day at midnight'

	now := time.now()
	next := sched.next_after(now) or { panic(err) }
	println('Current time: ${now}')
	println('Next matching run: ${next}')
	assert sched.matches(next) == true

	println('cronutils demo completed successfully!')
}
