module cacheutils

import time

// ============================================================================
// 1. LRU (Least-Recently-Used) Cache
// ============================================================================

struct LRUNode[T] {
mut:
	key  string
	val  T
	prev int = -1
	next int = -1
}

// LRUCache implements a fixed-capacity, Least-Recently-Used in-memory cache.
// When the capacity limit is exceeded, the least-recently accessed entry is evicted.
// All operations (get, set, delete, eviction) are O(1): entries live in a slab of nodes linked
// into a recency list by index, with a hash index from key to node slot.
pub struct LRUCache[T] {
mut:
	capacity   int
	index      map[string]int
	nodes      []LRUNode[T]
	free       []int
	head       int = -1 // least recently used
	tail       int = -1 // most recently used
	hit_count  u64
	miss_count u64
}

// new_lru initializes an LRUCache with a positive maximum capacity.
pub fn new_lru[T](capacity int) !LRUCache[T] {
	if capacity <= 0 {
		return error('LRU cache capacity must be greater than 0, got ${capacity}')
	}
	return LRUCache[T]{
		capacity: capacity
		index:    map[string]int{}
		nodes:    []LRUNode[T]{cap: capacity}
	}
}

fn (mut c LRUCache[T]) unlink(i int) {
	p := c.nodes[i].prev
	n := c.nodes[i].next
	if p >= 0 {
		c.nodes[p].next = n
	} else {
		c.head = n
	}
	if n >= 0 {
		c.nodes[n].prev = p
	} else {
		c.tail = p
	}
	c.nodes[i].prev = -1
	c.nodes[i].next = -1
}

fn (mut c LRUCache[T]) push_back(i int) {
	c.nodes[i].prev = c.tail
	c.nodes[i].next = -1
	if c.tail >= 0 {
		c.nodes[c.tail].next = i
	} else {
		c.head = i
	}
	c.tail = i
}

// get retrieves a value by key, updating its recency in the LRU order.
// Returns none if the key does not exist.
pub fn (mut c LRUCache[T]) get(key string) ?T {
	i := c.index[key] or {
		c.miss_count++
		return none
	}
	c.hit_count++
	c.touch_index(i)
	return c.nodes[i].val
}

// peek retrieves a value without changing its recency or the hit/miss statistics.
pub fn (c &LRUCache[T]) peek(key string) ?T {
	i := c.index[key] or { return none }
	return c.nodes[i].val
}

// set inserts or updates a key-value pair in the cache.
// If capacity is reached and a new key is added, the oldest key is evicted.
pub fn (mut c LRUCache[T]) set(key string, val T) {
	if i := c.index[key] {
		c.nodes[i].val = val
		c.touch_index(i)
		return
	}
	if c.index.len >= c.capacity {
		c.evict_oldest()
	}
	node := LRUNode[T]{
		key: key
		val: val
	}
	mut slot := 0
	if c.free.len > 0 {
		slot = c.free.pop()
		c.nodes[slot] = node
	} else {
		slot = c.nodes.len
		c.nodes << node
	}
	c.index[key] = slot
	c.push_back(slot)
}

// has checks whether a key is present in the cache without updating its recency.
pub fn (c &LRUCache[T]) has(key string) bool {
	return key in c.index
}

// delete removes a key from the cache, returning true if found and removed.
pub fn (mut c LRUCache[T]) delete(key string) bool {
	i := c.index[key] or { return false }
	c.unlink(i)
	c.index.delete(key)
	c.nodes[i] = LRUNode[T]{}
	c.free << i
	return true
}

// clear empties all entries from the cache.
pub fn (mut c LRUCache[T]) clear() {
	c.index.clear()
	c.nodes.clear()
	c.free.clear()
	c.head = -1
	c.tail = -1
}

// len returns the current number of cached items.
pub fn (c &LRUCache[T]) len() int {
	return c.index.len
}

// cap returns the maximum capacity of the cache.
pub fn (c &LRUCache[T]) cap() int {
	return c.capacity
}

// keys returns a list of keys currently stored, ordered from least to most recently used.
pub fn (c &LRUCache[T]) keys() []string {
	mut res := []string{cap: c.index.len}
	mut i := c.head
	for i >= 0 {
		res << c.nodes[i].key
		i = c.nodes[i].next
	}
	return res
}

// hits returns the number of successful get() lookups.
pub fn (c &LRUCache[T]) hits() u64 {
	return c.hit_count
}

// misses returns the number of get() lookups for absent keys.
pub fn (c &LRUCache[T]) misses() u64 {
	return c.miss_count
}

// hit_ratio returns hits / (hits + misses), or 0 when there were no lookups.
pub fn (c &LRUCache[T]) hit_ratio() f64 {
	total := c.hit_count + c.miss_count
	return if total == 0 { 0.0 } else { f64(c.hit_count) / f64(total) }
}

fn (mut c LRUCache[T]) touch_index(i int) {
	if c.tail == i {
		return
	}
	c.unlink(i)
	c.push_back(i)
}

fn (mut c LRUCache[T]) evict_oldest() {
	if c.head < 0 {
		return
	}
	c.delete(c.nodes[c.head].key)
}

// get_or_set_lru retrieves a cached value or executes fetcher to populate it if missing.
pub fn get_or_set_lru[T](mut cache LRUCache[T], key string, fetcher fn () !T) !T {
	if val := cache.get(key) {
		return val
	}
	new_val := fetcher()!
	cache.set(key, new_val)
	return new_val
}

// ============================================================================
// 2. TTL (Time-To-Live) Cache
// ============================================================================

struct TTLEntry[T] {
	val        T
	expires_at time.Time
}

// TTLCache stores values with an expiration duration. Expired items are ignored and can be cleaned up.
pub struct TTLCache[T] {
mut:
	default_ttl time.Duration
	items       map[string]TTLEntry[T]
}

// new_ttl initializes a TTLCache with a default expiration duration.
pub fn new_ttl[T](default_ttl time.Duration) TTLCache[T] {
	return TTLCache[T]{
		default_ttl: default_ttl
		items:       map[string]TTLEntry[T]{}
	}
}

// set inserts or updates a key using the cache default TTL.
pub fn (mut c TTLCache[T]) set(key string, val T) {
	c.set_with_ttl(key, val, c.default_ttl)
}

// set_with_ttl inserts or updates a key with a custom expiration duration.
pub fn (mut c TTLCache[T]) set_with_ttl(key string, val T, ttl time.Duration) {
	now := time.now()
	c.items[key] = TTLEntry[T]{
		val:        val
		expires_at: now.add(ttl)
	}
}

// get retrieves a value by key if it exists and has not expired.
// Expired items are lazily removed upon access.
pub fn (mut c TTLCache[T]) get(key string) ?T {
	entry := c.items[key] or { return none }
	if time.now().unix_nano() >= entry.expires_at.unix_nano() {
		c.items.delete(key)
		return none
	}
	return entry.val
}

// has checks whether a key is present and currently unexpired.
pub fn (c &TTLCache[T]) has(key string) bool {
	entry := c.items[key] or { return false }
	return time.now().unix_nano() < entry.expires_at.unix_nano()
}

// delete removes a key from the cache, returning true if it existed.
pub fn (mut c TTLCache[T]) delete(key string) bool {
	if key !in c.items {
		return false
	}
	c.items.delete(key)
	return true
}

// cleanup_expired sweeps the cache and purges all expired entries.
// Returns the number of purged items.
pub fn (mut c TTLCache[T]) cleanup_expired() int {
	now_nano := time.now().unix_nano()
	mut expired_keys := []string{}
	for key, entry in c.items {
		if now_nano >= entry.expires_at.unix_nano() {
			expired_keys << key
		}
	}
	for key in expired_keys {
		c.items.delete(key)
	}
	return expired_keys.len
}

// clear empties all entries from the cache.
pub fn (mut c TTLCache[T]) clear() {
	c.items.clear()
}

// len returns the count of items in the cache (including uncleaned expired items).
pub fn (c &TTLCache[T]) len() int {
	return c.items.len
}

// get_or_set_ttl retrieves a cached value or executes fetcher to populate it if missing or expired.
pub fn get_or_set_ttl[T](mut cache TTLCache[T], key string, fetcher fn () !T) !T {
	if val := cache.get(key) {
		return val
	}
	new_val := fetcher()!
	cache.set(key, new_val)
	return new_val
}
