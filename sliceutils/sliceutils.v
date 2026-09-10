module sliceutils

import arrays
import rand

// contains checks whether a target item exists in the slice using V's built-in `in` operator.
pub fn contains[T](arr []T, target T) bool {
	return target in arr
}

// unique returns a new slice containing only distinct elements, preserving order of first appearance.
pub fn unique[T](arr []T) []T {
	mut res := []T{cap: arr.len}
	for item in arr {
		if item !in res {
			res << item
		}
	}
	return res
}

// intersection returns elements present in both a and b, with duplicates removed.
pub fn intersection[T](a []T, b []T) []T {
	mut res := []T{}
	for item in a {
		if item in b && item !in res {
			res << item
		}
	}
	return res
}

// difference returns elements present in a that are not in b.
pub fn difference[T](a []T, b []T) []T {
	mut res := []T{}
	for item in a {
		if item !in b && item !in res {
			res << item
		}
	}
	return res
}

// union_slices returns all unique elements from both slices combined.
pub fn union_slices[T](a []T, b []T) []T {
	mut res := []T{cap: a.len + b.len}
	for item in a {
		if item !in res {
			res << item
		}
	}
	for item in b {
		if item !in res {
			res << item
		}
	}
	return res
}

// chunk splits a slice into smaller slices of specified size using V's built-in arrays.chunk.
pub fn chunk[T](arr []T, size int) [][]T {
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
