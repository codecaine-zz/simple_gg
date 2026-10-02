module cronutils

import time

fn test_cron_parsing_and_matching() {
	// Every 15 minutes: "*/15 * * * *"
	sched := parse_cron('*/15 * * * *') or { panic(err) }

	t1 := time.new(time.Time{
		year:   2026
		month:  10
		day:    2
		hour:   14
		minute: 30
	})
	assert sched.matches(t1) == true

	t2 := time.new(time.Time{
		year:   2026
		month:  10
		day:    2
		hour:   14
		minute: 32
	})
	assert sched.matches(t2) == false
}

fn test_cron_next_after() {
	sched := parse_cron('0 0 * * *') or { panic(err) }
	t := time.new(time.Time{
		year:   2026
		month:  10
		day:    2
		hour:   12
		minute: 0
	})
	next := sched.next_after(t) or { panic(err) }
	assert next.day == 3
	assert next.month == 10
	assert next.hour == 0
	assert next.minute == 0
}

fn test_cron_to_human() {
	assert cron_to_human('* * * * *') == 'Every minute'
	assert cron_to_human('*/5 * * * *') == 'Every 5 minutes'
	assert cron_to_human('0 * * * *') == 'Every hour'
	assert cron_to_human('0 0 * * *') == 'Every day at midnight'
}
