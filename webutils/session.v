module webutils

import sync
import time

// ============================================================================
// Sessions (replaces express-session + connect-flash)
//
//   app.use(webutils.sessions())
//   c.session_set('user_id', '42')
//   uid := c.session_get('user_id') or { '' }
//   c.session_regenerate()   // after login: prevents session fixation
//   c.session_destroy()      // logout
//
// The browser only receives a random 256-bit id in an HMAC-signed, HttpOnly,
// SameSite=Lax cookie; data stays server-side in a pluggable SessionStore.
// ============================================================================

// SessionStore persists session data. Implement it to back sessions with
// SQLite, Redis, files, etc. Implementations must be thread-safe.
pub interface SessionStore {
mut:
	load(id string) ?map[string]string
	save(id string, data map[string]string, ttl_secs int)
	destroy(id string)
}

struct MemEntry {
	data    map[string]string
	expires i64
}

// MemoryStore is the default in-process, thread-safe session store with
// automatic expiry. Data is lost on restart and not shared across processes.
@[heap]
pub struct MemoryStore {
mut:
	mu     &sync.Mutex = sync.new_mutex()
	items  map[string]MemEntry
	writes int
}

// new_memory_store creates an empty in-memory session store.
pub fn new_memory_store() &MemoryStore {
	return &MemoryStore{}
}

pub fn (mut s MemoryStore) load(id string) ?map[string]string {
	s.mu.lock()
	defer {
		s.mu.unlock()
	}
	e := s.items[id] or { return none }
	if e.expires <= time.now().unix() {
		s.items.delete(id)
		return none
	}
	return e.data.clone()
}

pub fn (mut s MemoryStore) save(id string, data map[string]string, ttl_secs int) {
	s.mu.lock()
	defer {
		s.mu.unlock()
	}
	now := time.now().unix()
	s.items[id] = MemEntry{data.clone(), now + i64(ttl_secs)}
	s.writes++
	if s.writes % 256 == 0 {
		mut dead := []string{}
		for k, e in s.items {
			if e.expires <= now {
				dead << k
			}
		}
		for k in dead {
			s.items.delete(k)
		}
	}
}

pub fn (mut s MemoryStore) destroy(id string) {
	s.mu.lock()
	s.items.delete(id)
	s.mu.unlock()
}

// len returns the number of stored sessions (including not-yet-swept expired ones).
pub fn (mut s MemoryStore) len() int {
	s.mu.lock()
	n := s.items.len
	s.mu.unlock()
	return n
}

@[params]
pub struct SessionConfig {
pub:
	cookie_name string   = 'sid'
	ttl_secs    int      = 86400 // idle lifetime
	rolling     bool     = true  // extend expiry on every request
	same_site   SameSite = .lax
	secure      bool // force Secure (auto-on for HTTPS requests anyway)
	domain      string
}

// sessions enables server-side sessions backed by an in-memory store.
pub fn sessions(cfg SessionConfig) Handler {
	return sessions_with_store(new_memory_store(), cfg)
}

// sessions_with_store enables sessions with a custom SessionStore.
pub fn sessions_with_store(store SessionStore, cfg SessionConfig) Handler {
	mut st := store
	return fn [mut st, cfg] (mut c Context) ! {
		mut sid := ''
		if raw := c.signed_cookie(cfg.cookie_name) {
			if data := st.load(raw) {
				sid = raw
				c.sess = data.clone()
			}
		}
		c.session_on = true
		c.next() or {
			session_commit(mut c, mut st, sid, cfg)
			return err
		}
		session_commit(mut c, mut st, sid, cfg)
	}
}

fn session_commit(mut c Context, mut st SessionStore, sid_in string, cfg SessionConfig) {
	mut sid := sid_in
	opts := CookieOptions{
		max_age:   cfg.ttl_secs
		same_site: cfg.same_site
		secure:    cfg.secure
		domain:    cfg.domain
	}
	if c.session_kill {
		if sid != '' {
			st.destroy(sid)
		}
		if cfg.cookie_name in c.cookies {
			c.clear_cookie(cfg.cookie_name, domain: cfg.domain)
		}
		return
	}
	if c.session_regen && sid != '' {
		st.destroy(sid)
		sid = ''
	}
	if c.sess.len == 0 {
		if sid != '' && c.session_dirty {
			st.destroy(sid)
			c.clear_cookie(cfg.cookie_name, domain: cfg.domain)
		}
		return
	}
	if sid == '' || c.session_dirty || cfg.rolling {
		if sid == '' {
			sid = random_token(32)
		}
		st.save(sid, c.sess, cfg.ttl_secs)
		c.set_signed_cookie(cfg.cookie_name, sid, opts)
	}
}

// session_get returns a session value.
pub fn (c &Context) session_get(key string) ?string {
	return c.sess[key] or { return none }
}

// session_data returns a copy of all session values.
pub fn (c &Context) session_data() map[string]string {
	return c.sess.clone()
}

// session_set stores a session value (requires the `sessions()` middleware).
pub fn (mut c Context) session_set(key string, value string) {
	c.sess[key] = value
	c.session_dirty = true
}

// session_delete removes a session value.
pub fn (mut c Context) session_delete(key string) {
	if key in c.sess {
		c.sess.delete(key)
		c.session_dirty = true
	}
}

// session_destroy ends the session (logout): data deleted, cookie cleared.
pub fn (mut c Context) session_destroy() {
	c.sess = map[string]string{}
	c.session_kill = true
}

// session_regenerate issues a new session id while keeping the data. Call it
// right after login/privilege changes to prevent session fixation.
pub fn (mut c Context) session_regenerate() {
	c.session_regen = true
	c.session_dirty = true
}

// flash stores a one-time message shown on the next request (e.g. after a redirect).
pub fn (mut c Context) flash(key string, message string) {
	c.session_set('_flash.${key}', message)
}

// take_flash returns and removes a flash message ('' when none).
pub fn (mut c Context) take_flash(key string) string {
	k := '_flash.${key}'
	v := c.sess[k] or { return '' }
	c.session_delete(k)
	return v
}
