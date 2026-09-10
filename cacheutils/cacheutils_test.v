module cacheutils

import time

fn test_lru_cache_basic_ops() {
	mut lru := new_lru[string](3)!
	assert lru.len() == 0
	assert lru.cap() == 3

	lru.set('a', 'apple')
	lru.set('b', 'banana')
	lru.set('c', 'cherry')
	assert lru.len() == 3
	assert lru.has('a') == true
	assert lru.has('z') == false

	assert lru.get('a') or { '' } == 'apple'
	assert lru.get('b') or { '' } == 'banana'
}

fn test_lru_cache_eviction() {
	mut lru := new_lru[int](3)!
	lru.set('1', 10)
	lru.set('2', 20)
	lru.set('3', 30)

	// Access key 1 to make it most recently used; order now: 2, 3, 1
	_ = lru.get('1') or { 0 }

	// Inserting key 4 should evict key 2 (least recently used)
	lru.set('4', 40)
	assert lru.has('2') == false
	assert lru.has('1') == true
	assert lru.has('3') == true
	assert lru.has('4') == true
	assert lru.len() == 3
}

fn test_lru_delete_and_clear() {
	mut lru := new_lru[string](2)!
	lru.set('x', '100')
	lru.set('y', '200')

	assert lru.delete('x') == true
	assert lru.delete('x') == false
	assert lru.len() == 1

	lru.clear()
	assert lru.len() == 0
	assert lru.get('y') == none
}

fn test_lru_get_or_set() {
	mut lru := new_lru[string](2)!
	val := get_or_set_lru(mut lru, 'greeting', fn () !string {
		return 'hello world'
	}) or { '' }
	assert val == 'hello world'
	assert lru.get('greeting') or { '' } == 'hello world'
}

fn test_ttl_cache_expiration() {
	mut ttl := new_ttl[string](time.millisecond * 50)
	ttl.set('session', 'active_token')
	assert ttl.has('session') == true
	assert ttl.get('session') or { '' } == 'active_token'

	time.sleep(time.millisecond * 70)
	assert ttl.has('session') == false
	assert ttl.get('session') == none
}

fn test_ttl_cache_custom_duration_and_cleanup() {
	mut ttl := new_ttl[int](time.second * 10)
	ttl.set_with_ttl('short', 1, time.millisecond * 30)
	ttl.set_with_ttl('long', 2, time.second * 10)

	time.sleep(time.millisecond * 50)
	purged := ttl.cleanup_expired()
	assert purged == 1
	assert ttl.has('short') == false
	assert ttl.has('long') == true
}

fn test_ttl_get_or_set() {
	mut ttl := new_ttl[int](time.minute)
	val := get_or_set_ttl(mut ttl, 'answer', fn () !int {
		return 42
	}) or { 0 }
	assert val == 42
	assert ttl.get('answer') or { 0 } == 42
}
