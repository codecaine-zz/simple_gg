module main

import eventutils

struct DemoCounter {
pub mut:
	count int
}

fn main() {
	println('=== eventutils Demo ===')

	mut em := eventutils.new_emitter()
	counter := &DemoCounter{
		count: 0
	}

	// Register recurring listener
	em.on('order_created', fn [counter] (order_id string) {
		unsafe {
			counter.count++
		}
		println('[Listener] Order processed: ${order_id}')
	})

	// Register one-time listener
	em.once('system_init', fn (status string) {
		println('[One-Time Listener] System initialized: ${status}')
	})

	println('Emitting system_init...')
	em.emit('system_init', 'v1.0 Ready')
	em.emit('system_init', 'Second trigger ignored')

	println('Emitting order_created events...')
	em.emit('order_created', 'ORD-1001')
	em.emit('order_created', 'ORD-1002')

	assert counter.count == 2
	println('Active listeners for order_created: ${em.listener_count('order_created')}')

	em.clear()
	assert em.listener_count('order_created') == 0
	println('eventutils demo completed successfully!')
}
