module eventutils

// EventHandler defines the callback signature for event notifications.
pub type EventHandler = fn (string)

// EventEmitter implements an in-memory publish-subscribe event dispatcher.
@[heap]
pub struct EventEmitter {
mut:
	listeners      map[string][]EventHandler
	once_listeners map[string][]EventHandler
	// Handle-based subscriptions (see subscriptions.v).
	subs    map[string][]Subscription
	any     []Subscription
	next_id int = 1
}

// new_emitter creates and initializes a new EventEmitter instance.
pub fn new_emitter() &EventEmitter {
	return &EventEmitter{
		listeners:      map[string][]EventHandler{}
		once_listeners: map[string][]EventHandler{}
	}
}

// on registers a persistent listener callback for the specified event name.
pub fn (mut e EventEmitter) on(event string, handler EventHandler) {
	e.listeners[event] << handler
}

// once registers a one-time listener callback that automatically unregisters after first execution.
pub fn (mut e EventEmitter) once(event string, handler EventHandler) {
	e.once_listeners[event] << handler
}

// off removes all registered persistent and one-time listeners for the specified event.
pub fn (mut e EventEmitter) off(event string) {
	e.listeners.delete(event)
	e.once_listeners.delete(event)
	e.subs.delete(event)
}

// emit dispatches an event to all registered listeners with the provided payload string.
pub fn (mut e EventEmitter) emit(event string, payload string) {
	if event in e.listeners {
		for handler in e.listeners[event] {
			handler(payload)
		}
	}

	if event in e.once_listeners {
		once_handlers := e.once_listeners[event].clone()
		e.once_listeners.delete(event)
		for handler in once_handlers {
			handler(payload)
		}
	}
	e.dispatch_subscriptions(event, payload)
}

// listener_count returns the total number of active listeners for the given event name.
pub fn (e EventEmitter) listener_count(event string) int {
	mut count := 0
	if event in e.listeners {
		count += e.listeners[event].len
	}
	if event in e.once_listeners {
		count += e.once_listeners[event].len
	}
	if event in e.subs {
		count += e.subs[event].len
	}
	return count
}

// clear removes all registered listeners across all events.
pub fn (mut e EventEmitter) clear() {
	e.listeners.clear()
	e.once_listeners.clear()
	e.subs.clear()
	e.any.clear()
}
