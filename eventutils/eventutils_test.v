module eventutils

struct TestState {
pub mut:
	count int
	last  string
}

fn test_event_emitter_on_and_emit() {
	mut em := new_emitter()
	state := &TestState{
		count: 0
		last:  ''
	}

	em.on('user_login', fn [state] (payload string) {
		unsafe {
			state.count++
			state.last = payload
		}
	})

	assert em.listener_count('user_login') == 1
	em.emit('user_login', 'alice')
	assert state.count == 1
	assert state.last == 'alice'

	em.emit('user_login', 'bob')
	assert state.count == 2
	assert state.last == 'bob'
}

fn test_event_emitter_once() {
	mut em := new_emitter()
	state := &TestState{
		count: 0
		last:  ''
	}

	em.once('startup', fn [state] (payload string) {
		unsafe {
			state.count++
			state.last = payload
		}
	})

	assert em.listener_count('startup') == 1
	em.emit('startup', 'v1.0')
	assert state.count == 1
	assert state.last == 'v1.0'

	// Second emit must not trigger handler
	em.emit('startup', 'v2.0')
	assert state.count == 1
	assert em.listener_count('startup') == 0
}

fn test_event_emitter_off_and_clear() {
	mut em := new_emitter()
	em.on('event_a', fn (p string) {})
	em.on('event_b', fn (p string) {})
	assert em.listener_count('event_a') == 1

	em.off('event_a')
	assert em.listener_count('event_a') == 0
	assert em.listener_count('event_b') == 1

	em.clear()
	assert em.listener_count('event_b') == 0
}
