module sliceutils

import rand

// ---------------------------------------------------------------------------
// Access helpers
// ---------------------------------------------------------------------------

// first_or returns the first element, or fallback when the slice is empty.
pub fn first_or[T](arr []T, fallback T) T {
	return if arr.len > 0 { arr[0] } else { fallback }
}

// last_or returns the last element, or fallback when the slice is empty.
pub fn last_or[T](arr []T, fallback T) T {
	return if arr.len > 0 { arr[arr.len - 1] } else { fallback }
}

// get_or returns arr[index] (negative indexes count from the end), or fallback when out of range.
pub fn get_or[T](arr []T, index int, fallback T) T {
	i := if index < 0 { arr.len + index } else { index }
	return if i >= 0 && i < arr.len { arr[i] } else { fallback }
}

// find returns the first element satisfying pred, or none.
pub fn find[T](arr []T, pred fn (item T) bool) ?T {
	for item in arr {
		if pred(item) {
			return item
		}
	}
	return none
}

// find_last returns the last element satisfying pred, or none.
pub fn find_last[T](arr []T, pred fn (item T) bool) ?T {
	for i := arr.len - 1; i >= 0; i-- {
		if pred(arr[i]) {
			return arr[i]
		}
	}
	return none
}

// choice returns a uniformly random element, or none when the slice is empty.
pub fn choice[T](arr []T) ?T {
	if arr.len == 0 {
		return none
	}
	return arr[rand.intn(arr.len) or { 0 }]
}

// ---------------------------------------------------------------------------
// Slicing
// ---------------------------------------------------------------------------

fn clamp_len(n int, len int) int {
	return if n < 0 {
		0
	} else if n > len {
		len
	} else {
		n
	}
}

// take returns the first n elements (fewer if the slice is shorter).
pub fn take[T](arr []T, n int) []T {
	return arr[..clamp_len(n, arr.len)].clone()
}

// take_last returns the last n elements (fewer if the slice is shorter).
pub fn take_last[T](arr []T, n int) []T {
	return arr[arr.len - clamp_len(n, arr.len)..].clone()
}

// drop returns the slice without its first n elements.
pub fn drop[T](arr []T, n int) []T {
	return arr[clamp_len(n, arr.len)..].clone()
}

// drop_last returns the slice without its last n elements.
pub fn drop_last[T](arr []T, n int) []T {
	return arr[..arr.len - clamp_len(n, arr.len)].clone()
}

// take_while returns the longest prefix whose elements all satisfy pred.
pub fn take_while[T](arr []T, pred fn (item T) bool) []T {
	mut i := 0
	for i < arr.len && pred(arr[i]) {
		i++
	}
	return arr[..i].clone()
}

// drop_while removes the longest prefix whose elements all satisfy pred.
pub fn drop_while[T](arr []T, pred fn (item T) bool) []T {
	mut i := 0
	for i < arr.len && pred(arr[i]) {
		i++
	}
	return arr[i..].clone()
}

// split_at splits the slice into [0, index) and [index, len).
pub fn split_at[T](arr []T, index int) ([]T, []T) {
	i := clamp_len(index, arr.len)
	return arr[..i].clone(), arr[i..].clone()
}

// rotate returns a copy rotated left by k positions (negative k rotates right).
pub fn rotate[T](arr []T, k int) []T {
	if arr.len == 0 {
		return []T{}
	}
	shift := ((k % arr.len) + arr.len) % arr.len
	mut res := []T{cap: arr.len}
	res << arr[shift..]
	res << arr[..shift]
	return res
}

// ---------------------------------------------------------------------------
// Transformation
// ---------------------------------------------------------------------------

// fold reduces the slice to a single value, starting from init (a.k.a. reduce / inject / aggregate).
pub fn fold[T, R](arr []T, init R, f fn (acc R, item T) R) R {
	mut acc := init
	for item in arr {
		acc = f(acc, item)
	}
	return acc
}

// flat_map maps every element to a slice and concatenates the results.
pub fn flat_map[T, R](arr []T, f fn (item T) []R) []R {
	mut res := []R{}
	for item in arr {
		res << f(item)
	}
	return res
}

// filter_map maps every element and keeps only results that are not none.
pub fn filter_map[T, R](arr []T, f fn (item T) ?R) []R {
	mut res := []R{}
	for item in arr {
		if v := f(item) {
			res << v
		}
	}
	return res
}

// scan returns the running accumulation (prefix fold) of the slice, e.g. running totals.
pub fn scan[T, R](arr []T, init R, f fn (acc R, item T) R) []R {
	mut res := []R{cap: arr.len}
	mut acc := init
	for item in arr {
		acc = f(acc, item)
		res << acc
	}
	return res
}

// unique_by keeps the first element for each distinct key returned by key_fn.
pub fn unique_by[T, K](arr []T, key_fn fn (item T) K) []T {
	mut seen := map[K]bool{}
	mut res := []T{}
	for item in arr {
		k := key_fn(item)
		if k !in seen {
			seen[k] = true
			res << item
		}
	}
	return res
}

// index_by builds a lookup map from key_fn(item) to item (later items win on duplicate keys).
pub fn index_by[T, K](arr []T, key_fn fn (item T) K) map[K]T {
	mut res := map[K]T{}
	for item in arr {
		res[key_fn(item)] = item
	}
	return res
}

// count_by counts elements per key returned by key_fn.
pub fn count_by[T, K](arr []T, key_fn fn (item T) K) map[K]int {
	mut res := map[K]int{}
	for item in arr {
		k := key_fn(item)
		res[k] = res[k] + 1
	}
	return res
}

// count_if returns the number of elements satisfying pred.
pub fn count_if[T](arr []T, pred fn (item T) bool) int {
	mut c := 0
	for item in arr {
		if pred(item) {
			c++
		}
	}
	return c
}

// min_by returns the element with the smallest key, or none when empty (first wins on ties).
pub fn min_by[T, K](arr []T, key_fn fn (item T) K) ?T {
	if arr.len == 0 {
		return none
	}
	mut best := arr[0]
	mut best_key := key_fn(best)
	for item in arr[1..] {
		k := key_fn(item)
		if k < best_key {
			best = item
			best_key = k
		}
	}
	return best
}

// max_by returns the element with the largest key, or none when empty (first wins on ties).
pub fn max_by[T, K](arr []T, key_fn fn (item T) K) ?T {
	if arr.len == 0 {
		return none
	}
	mut best := arr[0]
	mut best_key := key_fn(best)
	for item in arr[1..] {
		k := key_fn(item)
		if k > best_key {
			best = item
			best_key = k
		}
	}
	return best
}

// sum_by sums the numeric projection of every element.
pub fn sum_by[T, N](arr []T, f fn (item T) N) N {
	mut total := N(0)
	for item in arr {
		total += f(item)
	}
	return total
}

// pairwise returns each element paired with its successor ([a,b,c] -> [(a,b), (b,c)]).
pub fn pairwise[T](arr []T) []Pair[T, T] {
	mut res := []Pair[T, T]{}
	for i := 0; i + 1 < arr.len; i++ {
		res << Pair[T, T]{
			first:  arr[i]
			second: arr[i + 1]
		}
	}
	return res
}

// unzip splits a slice of pairs back into two slices.
pub fn unzip[T, U](pairs []Pair[T, U]) ([]T, []U) {
	mut a := []T{cap: pairs.len}
	mut b := []U{cap: pairs.len}
	for p in pairs {
		a << p.first
		b << p.second
	}
	return a, b
}

// interleave alternates elements from a and b, appending the remainder of the longer slice.
pub fn interleave[T](a []T, b []T) []T {
	mut res := []T{cap: a.len + b.len}
	mut i := 0
	for i < a.len || i < b.len {
		if i < a.len {
			res << a[i]
		}
		if i < b.len {
			res << b[i]
		}
		i++
	}
	return res
}

// transpose flips rows and columns of a rectangular matrix (ragged rows are truncated to the shortest).
pub fn transpose[T](matrix [][]T) [][]T {
	if matrix.len == 0 {
		return [][]T{}
	}
	mut cols := matrix[0].len
	for row in matrix {
		if row.len < cols {
			cols = row.len
		}
	}
	mut res := [][]T{cap: cols}
	for c in 0 .. cols {
		mut col := []T{cap: matrix.len}
		for row in matrix {
			col << row[c]
		}
		res << col
	}
	return res
}

// range_int returns integers from start (inclusive) to stop (exclusive) by step (like Python's range).
pub fn range_int(start int, stop int, step int) []int {
	mut res := []int{}
	if step == 0 {
		return res
	}
	if step > 0 {
		for i := start; i < stop; i += step {
			res << i
		}
	} else {
		for i := start; i > stop; i += step {
			res << i
		}
	}
	return res
}

// ---------------------------------------------------------------------------
// Ordering & searching
// ---------------------------------------------------------------------------

// sort_stable sorts in place with a stable merge sort: equal elements keep their relative order.
// less(a, b) must return true when a should come before b.
pub fn sort_stable[T](mut arr []T, less fn (a T, b T) bool) {
	if arr.len < 2 {
		return
	}
	mut buf := arr.clone()
	merge_sort_rec(mut arr, mut buf, 0, arr.len, less)
}

fn merge_sort_rec[T](mut arr []T, mut buf []T, lo int, hi int, less fn (a T, b T) bool) {
	if hi - lo < 2 {
		return
	}
	if hi - lo <= 16 {
		// Insertion sort for small runs (stable).
		for i in lo + 1 .. hi {
			x := arr[i]
			mut j := i - 1
			for j >= lo && less(x, arr[j]) {
				arr[j + 1] = arr[j]
				j--
			}
			arr[j + 1] = x
		}
		return
	}
	mid := lo + (hi - lo) / 2
	merge_sort_rec(mut arr, mut buf, lo, mid, less)
	merge_sort_rec(mut arr, mut buf, mid, hi, less)
	if !less(arr[mid], arr[mid - 1]) {
		return
	}
	for k in lo .. hi {
		buf[k] = arr[k]
	}
	mut i := lo
	mut j := mid
	for k in lo .. hi {
		if i < mid && (j >= hi || !less(buf[j], buf[i])) {
			arr[k] = buf[i]
			i++
		} else {
			arr[k] = buf[j]
			j++
		}
	}
}

// sorted_by returns a stably sorted copy ordered by the key returned by key_fn.
pub fn sorted_by[T, K](arr []T, key_fn fn (item T) K) []T {
	mut res := arr.clone()
	sort_stable(mut res, fn [key_fn] [T, K](a T, b T) bool {
		return key_fn(a) < key_fn(b)
	})
	return res
}

// is_sorted reports whether the slice is in non-decreasing order.
pub fn is_sorted[T](arr []T) bool {
	for i := 1; i < arr.len; i++ {
		if arr[i] < arr[i - 1] {
			return false
		}
	}
	return true
}

// lower_bound returns the first index in a sorted slice whose element is >= target (arr.len if none).
pub fn lower_bound[T](sorted_items []T, target T) int {
	mut lo := 0
	mut hi := sorted_items.len
	for lo < hi {
		mid := lo + (hi - lo) / 2
		if sorted_items[mid] < target {
			lo = mid + 1
		} else {
			hi = mid
		}
	}
	return lo
}

// upper_bound returns the first index in a sorted slice whose element is > target (arr.len if none).
pub fn upper_bound[T](sorted_items []T, target T) int {
	mut lo := 0
	mut hi := sorted_items.len
	for lo < hi {
		mid := lo + (hi - lo) / 2
		if target < sorted_items[mid] {
			hi = mid
		} else {
			lo = mid + 1
		}
	}
	return lo
}

// insert_sorted inserts item into an already sorted slice, keeping it sorted (after equal elements).
pub fn insert_sorted[T](mut arr []T, item T) {
	arr.insert(upper_bound(arr, item), item)
}

// ---------------------------------------------------------------------------
// Combinatorics
// ---------------------------------------------------------------------------

// cartesian_product returns every (a, b) pair.
pub fn cartesian_product[T, U](a []T, b []U) []Pair[T, U] {
	mut res := []Pair[T, U]{cap: a.len * b.len}
	for x in a {
		for y in b {
			res << Pair[T, U]{
				first:  x
				second: y
			}
		}
	}
	return res
}

// combinations returns all k-element combinations in lexicographic index order (n choose k results).
pub fn combinations[T](arr []T, k int) [][]T {
	mut res := [][]T{}
	if k < 0 || k > arr.len {
		return res
	}
	mut idx := []int{len: k, init: index}
	for {
		res << idx.map(arr[it])
		mut i := k - 1
		for i >= 0 && idx[i] == arr.len - k + i {
			i--
		}
		if i < 0 {
			break
		}
		idx[i]++
		for j in i + 1 .. k {
			idx[j] = idx[j - 1] + 1
		}
	}
	return res
}

// permutations returns all orderings of the slice in lexicographic index order (n! results).
pub fn permutations[T](arr []T) [][]T {
	n := arr.len
	mut res := [][]T{}
	mut idx := []int{len: n, init: index}
	for {
		res << idx.map(arr[it])
		// Next permutation of indices (Knuth's Algorithm L).
		mut i := n - 2
		for i >= 0 && idx[i] >= idx[i + 1] {
			i--
		}
		if i < 0 {
			break
		}
		mut j := n - 1
		for idx[j] <= idx[i] {
			j--
		}
		idx[i], idx[j] = idx[j], idx[i]
		mut l := i + 1
		mut r := n - 1
		for l < r {
			idx[l], idx[r] = idx[r], idx[l]
			l++
			r--
		}
	}
	return res
}
