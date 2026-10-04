module sliceutils

import arrays
import rand

// contains checks whether a target item exists in the slice using V's built-in `in` operator.
pub fn contains[T](arr []T, target T) bool {
	return target in arr
}

// unique returns a new slice containing only distinct elements, preserving order of first appearance.
// Runs in O(n) for hashable element types (integers, strings, runes) and O(n²) otherwise.
pub fn unique[T](arr []T) []T {
	mut res := []T{cap: arr.len}
	$if T is $int || T is string || T is rune {
		mut seen := map[T]bool{}
		for item in arr {
			if item !in seen {
				seen[item] = true
				res << item
			}
		}
	} $else {
		for item in arr {
			if item !in res {
				res << item
			}
		}
	}
	return res
}

// intersection returns elements present in both a and b, with duplicates removed.
pub fn intersection[T](a []T, b []T) []T {
	mut res := []T{}
	$if T is $int || T is string || T is rune {
		mut in_b := map[T]bool{}
		for item in b {
			in_b[item] = true
		}
		mut seen := map[T]bool{}
		for item in a {
			if item in in_b && item !in seen {
				seen[item] = true
				res << item
			}
		}
	} $else {
		for item in a {
			if item in b && item !in res {
				res << item
			}
		}
	}
	return res
}

// difference returns elements present in a that are not in b.
pub fn difference[T](a []T, b []T) []T {
	mut res := []T{}
	$if T is $int || T is string || T is rune {
		mut excluded := map[T]bool{}
		for item in b {
			excluded[item] = true
		}
		for item in a {
			if item !in excluded {
				excluded[item] = true
				res << item
			}
		}
	} $else {
		for item in a {
			if item !in b && item !in res {
				res << item
			}
		}
	}
	return res
}

// union_slices returns all unique elements from both slices combined.
pub fn union_slices[T](a []T, b []T) []T {
	mut combined := []T{cap: a.len + b.len}
	combined << a
	combined << b
	return unique(combined)
}

// chunk splits a slice into smaller slices of specified size using V's built-in arrays.chunk.
// Returns an empty result when size <= 0.
pub fn chunk[T](arr []T, size int) [][]T {
	if size <= 0 || arr.len == 0 {
		return [][]T{}
	}
	return arrays.chunk(arr, size)
}

// flatten converts a 2D slice into a 1D slice using V's built-in arrays.flatten.
pub fn flatten[T](matrix [][]T) []T {
	return arrays.flatten(matrix)
}

// find_index returns the index of the first element satisfying the predicate, or none.
pub fn find_index[T](arr []T, pred fn (item T) bool) ?int {
	for i, item in arr {
		if pred(item) {
			return i
		}
	}
	return none
}

// partition splits a slice into two slices: those satisfying the predicate and those that do not.
pub fn partition[T](arr []T, pred fn (item T) bool) ([]T, []T) {
	return arrays.partition(arr, pred)
}

// count returns the number of times target appears in the slice.
pub fn count[T](arr []T, target T) int {
	mut c := 0
	for item in arr {
		if item == target {
			c++
		}
	}
	return c
}

// sample randomly selects n items from the slice without replacement.
pub fn sample[T](arr []T, n int) []T {
	if n <= 0 || arr.len == 0 {
		return []T{}
	}
	if n >= arr.len {
		mut copy := arr.clone()
		shuffle(mut copy)
		return copy
	}
	mut indices := []int{cap: arr.len}
	for i in 0 .. arr.len {
		indices << i
	}
	rand.shuffle(mut indices) or {}
	mut res := []T{cap: n}
	for i in 0 .. n {
		res << arr[indices[i]]
	}
	return res
}

// shuffle randomly reorders elements in place using V's built-in rand.shuffle.
pub fn shuffle[T](mut arr []T) {
	rand.shuffle(mut arr) or {}
}

// sum_int returns the sum of all elements in an integer slice using V's built-in arrays.sum.
pub fn sum_int(arr []int) int {
	return arrays.sum(arr) or { 0 }
}

// average_int returns the arithmetic mean of an integer slice, or 0.0 if empty.
pub fn average_int(arr []int) f64 {
	if arr.len == 0 {
		return 0.0
	}
	return f64(sum_int(arr)) / f64(arr.len)
}

// min_int returns the smallest integer in the slice, or none if empty using V's built-in arrays.min.
pub fn min_int(arr []int) ?int {
	res := arrays.min(arr) or { return none }
	return res
}

// max_int returns the largest integer in the slice, or none if empty using V's built-in arrays.max.
pub fn max_int(arr []int) ?int {
	res := arrays.max(arr) or { return none }
	return res
}

// sum_f64 returns the sum of all elements in a float slice using V's built-in arrays.sum.
pub fn sum_f64(arr []f64) f64 {
	return arrays.sum(arr) or { 0.0 }
}

// average_f64 returns the arithmetic mean of a float slice, or 0.0 if empty.
pub fn average_f64(arr []f64) f64 {
	if arr.len == 0 {
		return 0.0
	}
	return sum_f64(arr) / f64(arr.len)
}

// min_f64 returns the minimum float in the slice, or none if empty using V's built-in arrays.min.
pub fn min_f64(arr []f64) ?f64 {
	res := arrays.min(arr) or { return none }
	return res
}

// max_f64 returns the maximum float in the slice, or none if empty using V's built-in arrays.max.
pub fn max_f64(arr []f64) ?f64 {
	res := arrays.max(arr) or { return none }
	return res
}

// Pair represents a 2-tuple of generic types.
pub struct Pair[T, U] {
pub:
	first  T
	second U
}

// zip combines elements of two slices into a slice of Pairs up to the shorter slice's length.
pub fn zip[T, U](a []T, b []U) []Pair[T, U] {
	min_len := if a.len < b.len { a.len } else { b.len }
	mut res := []Pair[T, U]{cap: min_len}
	for i in 0 .. min_len {
		res << Pair[T, U]{
			first:  a[i]
			second: b[i]
		}
	}
	return res
}

// frequency counts the number of occurrences of each distinct element in a slice.
pub fn frequency[T](items []T) map[T]int {
	mut counts := map[T]int{}
	for item in items {
		counts[item] = counts[item] + 1
	}
	return counts
}

// group_by partitions elements of a slice into a map grouped by keys returned by key_fn.
pub fn group_by[T, K](items []T, key_fn fn (T) K) map[K][]T {
	mut groups := map[K][]T{}
	for item in items {
		key := key_fn(item)
		groups[key] << item
	}
	return groups
}

// window returns overlapping or non-overlapping sliding windows of size with the specified step.
pub fn window[T](items []T, size int, step int) [][]T {
	if size <= 0 || step <= 0 || items.len < size {
		return [][]T{}
	}
	mut windows := [][]T{}
	mut i := 0
	for i + size <= items.len {
		windows << items[i..i + size].clone()
		i += step
	}
	return windows
}

// binary_search performs binary search on a sorted slice and returns the index of target, or -1 if not found.
pub fn binary_search[T](sorted_items []T, target T) int {
	mut low := 0
	mut high := sorted_items.len - 1
	for low <= high {
		mid := low + (high - low) / 2
		if sorted_items[mid] == target {
			return mid
		} else if sorted_items[mid] < target {
			low = mid + 1
		} else {
			high = mid - 1
		}
	}
	return -1
}
