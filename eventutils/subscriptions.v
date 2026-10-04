module eventutils

// AnyHandler receives every event (name + payload); useful for logging/tracing.
pub type AnyHandler = fn (string, string)

struct Subscription {
	id      int
	handler EventHandler = unsafe { nil }
	any     AnyHandler   = unsafe { nil }
	once    bool
}

fn (mut e EventEmitter) dispatch_subscriptions(event string, payload string) {
	if event in e.subs {
		current := e.subs[event].clone()
		if current.any(it.once) {
			remaining := current.filter(!it.once)
			if remaining.len == 0 {
				e.subs.delete(event)
			} else {
				e.subs[event] = remaining
			}
		}
		for s in current {
			s.handler(payload)
		}
	}
	if e.any.len > 0 {
		for s in e.any.clone() {
			s.any(event, payload)
		}
	}
}

// subscribe registers a handler and returns an id that can be passed to `unsubscribe`
// (unlike `off`, this removes just one listener).
pub fn (mut e EventEmitter) subscribe(event string, handler EventHandler) int {
	id := e.next_id
	e.next_id++
	e.subs[event] << Subscription{
		id:      id
		handler: handler
	}
	return id
}

// subscribe_once is like subscribe but the handler fires at most once.
pub fn (mut e EventEmitter) subscribe_once(event string, handler EventHandler) int {
	id := e.next_id
	e.next_id++
	e.subs[event] << Subscription{
		id:      id
		handler: handler
		once:    true
	}
	return id
}

// on_any registers a wildcard handler invoked for every emitted event.
pub fn (mut e EventEmitter) on_any(handler AnyHandler) int {
	id := e.next_id
	e.next_id++
	e.any << Subscription{
		id:  id
		any: handler
	}
	return id
}

// unsubscribe removes a single subscription by id. Returns true if one was removed.
pub fn (mut e EventEmitter) unsubscribe(id int) bool {
	for ev, list in e.subs {
		idx := list.map(it.id).index(id)
		if idx >= 0 {
			mut nl := list.clone()
			nl.delete(idx)
			if nl.len == 0 {
				e.subs.delete(ev)
			} else {
				e.subs[ev] = nl
			}
			return true
		}
	}
	idx := e.any.map(it.id).index(id)
	if idx >= 0 {
		e.any.delete(idx)
		return true
	}
	return false
}

// event_names returns the names of all events that currently have listeners.
pub fn (e EventEmitter) event_names() []string {
	mut seen := map[string]bool{}
	for k, _ in e.listeners {
		seen[k] = true
	}
	for k, _ in e.once_listeners {
		seen[k] = true
	}
	for k, _ in e.subs {
		seen[k] = true
	}
	mut names := seen.keys()
	names.sort()
	return names
}

// ============================================================================
// Typed event bus
// ============================================================================

// TypedEmitter is a generic single-topic event channel carrying payloads of type T.
@[heap]
pub struct TypedEmitter[T] {
mut:
	handlers map[int]fn (T)
	order    []int
	next_id  int = 1
}

// new_typed_emitter creates a typed emitter.
pub fn new_typed_emitter[T]() &TypedEmitter[T] {
	return &TypedEmitter[T]{}
}

// subscribe registers a handler and returns its id.
pub fn (mut t TypedEmitter[T]) subscribe(handler fn (T)) int {
	id := t.next_id
	t.next_id++
	t.handlers[id] = handler
	t.order << id
	return id
}

// unsubscribe removes a handler by id.
pub fn (mut t TypedEmitter[T]) unsubscribe(id int) bool {
	if id !in t.handlers {
		return false
	}
	t.handlers.delete(id)
	t.order = t.order.filter(it != id)
	return true
}

// emit delivers `value` to all handlers in subscription order; returns the count.
pub fn (mut t TypedEmitter[T]) emit(value T) int {
	ids := t.order.clone()
	mut n := 0
	for id in ids {
		if h := t.handlers[id] {
			h(value)
			n++
		}
	}
	return n
}

// len returns the number of handlers.
pub fn (t TypedEmitter[T]) len() int {
	return t.order.len
}
