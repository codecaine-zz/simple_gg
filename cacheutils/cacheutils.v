module cacheutils

import time

// ============================================================================
// 1. LRU (Least-Recently-Used) Cache
// ============================================================================

// LRUCache implements a fixed-capacity, Least-Recently-Used in-memory cache.
// When the capacity limit is exceeded, the least-recently accessed entry is evicted.
pub struct LRUCache[T] {
mut:
	capacity int
	items    map[string]T
	order    []string // Oldest accessed key at index 0, most recently used at end
}

// new_lru initializes an LRUCache with a positive maximum capacity.
pub fn new_lru[T](capacity int) !LRUCache[T] {
	if capacity <= 0 {
		return error('LRU cache capacity must be greater than 0, got ${capacity}')
	}
	return LRUCache[T]{
		capacity: capacity
		items:    map[string]T{}
		order:    []string{cap: capacity}
	}
}

// get retrieves a value by key, updating its recency in the LRU order.
// Returns none if the key does not exist.
pub fn (mut c LRUCache[T]) get(key string) ?T {
	val := c.items[key] or { return none }
	c.touch(key)
	return val
}

// set inserts or updates a key-value pair in the cache.
// If capacity is reached and a new key is added, the oldest key is evicted.
pub fn (mut c LRUCache[T]) set(key string, val T) {
	if key in c.items {
		c.items[key] = val
		c.touch(key)
		return
	}

	if c.items.len >= c.capacity {
		c.evict_oldest()
	}

	c.items[key] = val
	c.order << key
}

// has checks whether a key is present in the cache without updating its recency.
pub fn (c &LRUCache[T]) has(key string) bool {
	return key in c.items
}

// delete removes a key from the cache, returning true if found and removed.
pub fn (mut c LRUCache[T]) delete(key string) bool {
	if key !in c.items {
		return false
	}
	c.items.delete(key)
	for i, k in c.order {
		if k == key {
			c.order.delete(i)
			break
		}
	}
	return true
}

// clear empties all entries from the cache.
pub fn (mut c LRUCache[T]) clear() {
	c.items.clear()
	c.order.clear()
}

// len returns the current number of cached items.
pub fn (c &LRUCache[T]) len() int {
	return c.items.len
}

// cap returns the maximum capacity of the cache.
pub fn (c &LRUCache[T]) cap() int {
	return c.capacity
}

// keys returns a list of keys currently stored, ordered from least to most recently used.
pub fn (c &LRUCache[T]) keys() []string {
	return c.order.clone()
}

fn (mut c LRUCache[T]) touch(key string) {
	for i, k in c.order {
		if k == key {
			c.order.delete(i)
			c.order << key
			return
		}
	}
}

fn (mut c LRUCache[T]) evict_oldest() {
	if c.order.len == 0 {
		return
	}
	oldest_key := c.order[0]
	c.order.delete(0)
	c.items.delete(oldest_key)
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
