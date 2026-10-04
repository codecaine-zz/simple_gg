module sliceutils

struct Emp {
	name string
	dept string
	age  int
}

fn test_set_ops_fast_and_generic_paths() {
	assert unique([3, 1, 3, 2, 1]) == [3, 1, 2]
	assert unique(['b', 'a', 'b']) == ['b', 'a']
	assert unique([1.5, 1.5, 2.0]) == [1.5, 2.0]
	assert intersection([1, 2, 2, 3], [2, 3, 4]) == [2, 3]
	assert difference([1, 2, 2, 3], [3]) == [1, 2]
	assert union_slices([1, 2], [2, 3]) == [1, 2, 3]
	assert chunk([1, 2, 3], 0) == [][]int{}
	big := []int{len: 20000, init: index % 100}
	assert unique(big).len == 100
}

fn test_access_helpers() {
	assert first_or([]int{}, 7) == 7
	assert last_or([1, 2], 7) == 2
	assert get_or([1, 2, 3], -1, 0) == 3
	assert get_or([1, 2, 3], 5, 0) == 0
	assert find([1, 4, 6], fn (x int) bool {
		return x % 2 == 0
	})? == 4
	assert find_last([1, 4, 6], fn (x int) bool {
		return x % 2 == 0
	})? == 6
	assert choice([]int{}) == none
	assert choice([9])? == 9
}

fn test_slicing() {
	a := [1, 2, 3, 4, 5]
	assert take(a, 2) == [1, 2]
	assert take(a, 99) == a
	assert take(a, -1) == []int{}
	assert take_last(a, 2) == [4, 5]
	assert drop(a, 2) == [3, 4, 5]
	assert drop_last(a, 2) == [1, 2, 3]
	lt3 := fn (x int) bool {
		return x < 3
	}
	assert take_while(a, lt3) == [1, 2]
	assert drop_while(a, lt3) == [3, 4, 5]
	l, r := split_at(a, 3)
	assert l == [1, 2, 3] && r == [4, 5]
	assert rotate(a, 2) == [3, 4, 5, 1, 2]
	assert rotate(a, -1) == [5, 1, 2, 3, 4]
}

fn test_transformations() {
	assert fold([1, 2, 3], '', fn (acc string, x int) string {
		return acc + x.str()
	}) == '123'
	assert flat_map([1, 2], fn (x int) []int {
		return [x, x * 10]
	}) == [1, 10, 2, 20]
	assert filter_map[string, int](['1', 'x', '3'], fn (s string) ?int {
		if s.is_int() {
			return s.int()
		}
		return none
	}) == [1, 3]
	assert scan([1, 2, 3], 0, fn (acc int, x int) int {
		return acc + x
	}) == [1, 3, 6]
	emps := [Emp{'ann', 'eng', 30}, Emp{'bob', 'ops', 25}, Emp{'cy', 'eng', 41}]
	dept := fn (e Emp) string {
		return e.dept
	}
	assert unique_by(emps, dept).len == 2
	by_name := index_by(emps, fn (e Emp) string {
		return e.name
	})
	assert by_name['bob'].age == 25
	assert count_by(emps, dept)['eng'] == 2
	assert count_if([1, 2, 3, 4], fn (x int) bool {
		return x > 2
	}) == 2
	age := fn (e Emp) int {
		return e.age
	}
	assert min_by(emps, age)?.name == 'bob'
	assert max_by(emps, age)?.name == 'cy'
	assert sum_by(emps, age) == 96
	p := pairwise([1, 2, 3])
	assert p.len == 2 && p[1].first == 2 && p[1].second == 3
	xs, ys := unzip(zip([1, 2], ['a', 'b']))
	assert xs == [1, 2] && ys == ['a', 'b']
	assert interleave([1, 3, 5, 7], [2, 4]) == [1, 2, 3, 4, 5, 7]
	assert transpose([[1, 2, 3], [4, 5, 6]]) == [[1, 4], [2, 5], [3, 6]]
	assert range_int(0, 10, 3) == [0, 3, 6, 9]
	assert range_int(5, 0, -2) == [5, 3, 1]
	assert range_int(0, 5, 0) == []int{}
}

fn test_ordering() {
	emps := [Emp{'a', 'x', 30}, Emp{'b', 'y', 25}, Emp{'c', 'z', 30}, Emp{'d', 'w', 25}]
	sorted := sorted_by(emps, fn (e Emp) int {
		return e.age
	})
	assert sorted.map(it.name) == ['b', 'd', 'a', 'c'] // stable
	mut big := []int{len: 500, init: (index * 7919) % 500}
	sort_stable(mut big, fn (a int, b int) bool {
		return a < b
	})
	assert is_sorted(big)
	assert !is_sorted([2, 1])
	s := [1, 2, 2, 2, 5]
	assert lower_bound(s, 2) == 1
	assert upper_bound(s, 2) == 4
	assert lower_bound(s, 9) == 5
	mut ins := [1, 3, 5]
	insert_sorted(mut ins, 4)
	assert ins == [1, 3, 4, 5]
}

fn test_combinatorics() {
	assert cartesian_product([1, 2], ['a']).len == 2
	assert combinations([1, 2, 3, 4], 2) == [[1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]]
	assert combinations([1, 2], 3) == [][]int{}
	assert combinations([1, 2], 0) == [[]int{}]
	assert permutations([1, 2, 3]) == [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2],
		[3, 2, 1]]
	assert permutations([1, 2, 3, 4]).len == 24
}
