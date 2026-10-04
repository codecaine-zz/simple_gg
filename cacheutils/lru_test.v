module cacheutils

import rand

fn test_lru_o1_semantics_and_stats() {
	mut c := new_lru[int](3)!
	c.set('a', 1)
	c.set('b', 2)
	c.set('c', 3)
	assert c.get('a')? == 1 // a is now most recent
	c.set('d', 4) // evicts b
	assert !c.has('b')
	assert c.keys() == ['c', 'a', 'd']
	assert c.peek('c')? == 3
	assert c.keys() == ['c', 'a', 'd'] // peek does not touch
	assert c.get('zzz') == none
	assert c.hits() == 1 && c.misses() == 1
	assert c.hit_ratio() == 0.5
	assert c.delete('a')
	assert !c.delete('a')
	c.set('e', 5) // reuses freed slot
	assert c.keys() == ['c', 'd', 'e']
	c.clear()
	assert c.len() == 0 && c.keys() == []string{}
	c.set('x', 9)
	assert c.get('x')? == 9
}

// Differential test against a trivially-correct reference model.
fn test_lru_matches_reference_model() {
	cap := 8
	mut c := new_lru[int](cap)!
	mut ref_keys := []string{}
	mut ref_vals := map[string]int{}
	for step in 0 .. 5000 {
		k := 'k${rand.intn(20) or { 0 }}'
		op := rand.intn(3) or { 0 }
		if op == 0 {
			got := c.get(k)
			if k in ref_vals {
				assert got? == ref_vals[k]
				ref_keys.delete(ref_keys.index(k))
				ref_keys << k
			} else {
				assert got == none
			}
		} else if op == 1 {
			c.set(k, step)
			if k in ref_vals {
				ref_keys.delete(ref_keys.index(k))
			} else if ref_keys.len >= cap {
				ref_vals.delete(ref_keys[0])
				ref_keys.delete(0)
			}
			ref_keys << k
			ref_vals[k] = step
		} else {
			assert c.delete(k) == (k in ref_vals)
			if k in ref_vals {
				ref_vals.delete(k)
				ref_keys.delete(ref_keys.index(k))
			}
		}
		assert c.keys() == ref_keys
	}
}
