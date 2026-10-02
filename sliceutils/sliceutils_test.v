module sliceutils

fn test_unique() {
	nums := [1, 2, 2, 3, 1, 4, 3]
	u := unique(nums)
	assert u == [1, 2, 3, 4]

	words := ['apple', 'banana', 'apple', 'orange']
	uw := unique(words)
	assert uw == ['apple', 'banana', 'orange']
}

fn test_set_operations() {
	a := [1, 2, 3, 4]
	b := [3, 4, 5, 6]

	inter := intersection(a, b)
	assert inter == [3, 4]

	diff := difference(a, b)
	assert diff == [1, 2]

	u := union_slices(a, b)
	assert u == [1, 2, 3, 4, 5, 6]
}

fn test_chunk_and_flatten() {
	arr := [1, 2, 3, 4, 5, 6, 7]
	chunks := chunk(arr, 3)
	assert chunks.len == 3
	assert chunks[0] == [1, 2, 3]
	assert chunks[1] == [4, 5, 6]
	assert chunks[2] == [7]

	flat := flatten(chunks)
	assert flat == arr
}

fn test_find_and_partition() {
	arr := [10, 15, 20, 25, 30]
	idx := find_index(arr, fn (x int) bool {
		return x > 18
	}) or { -1 }
	assert idx == 2

	passed, failed := partition(arr, fn (x int) bool {
		return x % 2 == 0
	})
	assert passed == [10, 20, 30]
	assert failed == [15, 25]

	assert count(arr, 20) == 1
	assert count(arr, 99) == 0
}

fn test_numeric_aggregations() {
	ints := [5, 2, 9, 1, 7]
	assert sum_int(ints) == 24
	assert average_int(ints) == 4.8
	assert min_int(ints) or { 0 } == 1
	assert max_int(ints) or { 0 } == 9

	assert min_int([]int{}) == none
	assert max_int([]int{}) == none

	floats := [1.5, 2.5, 3.0]
	assert sum_f64(floats) == 7.0
	assert average_f64(floats) == 7.0 / 3.0
	assert min_f64(floats) or { 0.0 } == 1.5
	assert max_f64(floats) or { 0.0 } == 3.0
}

fn test_sample_and_shuffle() {
	arr := [1, 2, 3, 4, 5]
	s := sample(arr, 3)
	assert s.len == 3
	for item in s {
		assert contains(arr, item)
	}

	mut to_shuffle := [1, 2, 3, 4, 5]
	shuffle(mut to_shuffle)
	assert to_shuffle.len == 5
}

fn test_advanced_slice_ops() {
	a := ['a', 'b', 'c']
	b := [1, 2, 3, 4]
	zipped := zip[string, int](a, b)
	assert zipped.len == 3
	assert zipped[0].first == 'a'
	assert zipped[0].second == 1
	assert zipped[2].first == 'c'
	assert zipped[2].second == 3

	words := ['apple', 'banana', 'apple', 'cherry', 'apple', 'banana']
	freq := frequency[string](words)
	assert freq['apple'] == 3
	assert freq['banana'] == 2
	assert freq['cherry'] == 1

	nums := [1, 2, 3, 4, 5, 6]
	groups := group_by[int, string](nums, fn (n int) string {
		return if n % 2 == 0 { 'even' } else { 'odd' }
	})
	assert groups['even'] == [2, 4, 6]
	assert groups['odd'] == [1, 3, 5]

	windows := window[int]([1, 2, 3, 4, 5], 3, 1)
	assert windows.len == 3
	assert windows[0] == [1, 2, 3]
	assert windows[1] == [2, 3, 4]
	assert windows[2] == [3, 4, 5]

	sorted := [10, 20, 30, 40, 50, 60]
	assert binary_search[int](sorted, 30) == 2
	assert binary_search[int](sorted, 10) == 0
	assert binary_search[int](sorted, 60) == 5
	assert binary_search[int](sorted, 99) == -1
}
