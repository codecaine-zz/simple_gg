module main

import time
import cacheutils

fn main() {
	println('==================================================')
	println('               demo_cacheutils                    ')
	println('==================================================')

	// 1. LRU Cache (Capacity 2)
	println('--- Testing LRUCache ---')
	mut lru := cacheutils.new_lru[string](2)!
	lru.set('a', 'alpha')
	lru.set('b', 'beta')
	println('Inserted "a" and "b", len: ${lru.len()}')
	assert lru.get('a')? == 'alpha'

	// Adding "c" evicts "b" because "a" was accessed more recently
	lru.set('c', 'charlie')
	has_b := lru.has('b')
	println('After inserting "c": has "b" = ${has_b}, has "a" = ${lru.has('a')}, has "c" = ${lru.has('c')}')
	assert has_b == false
	assert lru.get('c')? == 'charlie'
	assert lru.get('a')? == 'alpha'

	// 2. TTL Cache (Expiring entries)
	println('\n--- Testing TTLCache ---')
	mut ttl := cacheutils.new_ttl[string](50 * time.millisecond)
	ttl.set('token1', 'active_session')
	ttl.set_with_ttl('token2', 'custom_session', 500 * time.millisecond)

	println('Immediate check: token1=${ttl.get('token1')?}, token2=${ttl.get('token2')?}')
	assert ttl.has('token1') == true
	assert ttl.has('token2') == true

	// Sleep past token1 TTL
	time.sleep(70 * time.millisecond)
	token1_after := ttl.get('token1')
	println('After 70ms: token1=${token1_after}, token2 has=${ttl.has('token2')}')
	assert token1_after == none
	assert ttl.has('token2') == true

	println('\n✔ cacheutils demo completed successfully!')
}
