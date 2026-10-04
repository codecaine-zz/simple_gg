module eventutils

@[heap]
struct Log {
mut:
	items []string
}

struct Order {
	id    int
	total f64
}

fn test_subscribe_unsubscribe_single() {
	mut e := new_emitter()
	mut log := &Log{}
	a := e.subscribe('x', fn [mut log] (p string) {
		log.items << 'a:${p}'
	})
	e.subscribe('x', fn [mut log] (p string) {
		log.items << 'b:${p}'
	})
	e.emit('x', '1')
	assert e.unsubscribe(a)
	assert !e.unsubscribe(a)
	e.emit('x', '2')
	assert log.items == ['a:1', 'b:1', 'b:2']
	assert e.listener_count('x') == 1
}

fn test_subscribe_once_and_any() {
	mut e := new_emitter()
	mut log := &Log{}
	e.subscribe_once('boot', fn [mut log] (p string) {
		log.items << 'once'
	})
	w := e.on_any(fn [mut log] (ev string, p string) {
		log.items << '*${ev}'
	})
	e.emit('boot', '')
	e.emit('boot', '')
	e.unsubscribe(w)
	e.emit('boot', '')
	assert log.items == ['once', '*boot', '*boot']
	e.on('legacy', fn (p string) {})
	assert e.event_names() == ['legacy']
}

fn test_typed_emitter() {
	mut t := new_typed_emitter[Order]()
	mut log := &Log{}
	id := t.subscribe(fn [mut log] (o Order) {
		log.items << '${o.id}:${o.total}'
	})
	assert t.emit(Order{7, 9.5}) == 1
	assert t.unsubscribe(id)
	assert t.emit(Order{8, 1}) == 0
	assert log.items == ['7:9.5']
	assert t.len() == 0
}
