module main

import sliceutils

fn main() {
	println('==================================================')
	println('               demo_sliceutils                    ')
	println('==================================================')

	// 1. Unique, Intersection, Difference
	nums := [1, 2, 2, 3, 4, 4, 5, 5, 5]
	uniques := sliceutils.unique(nums)
	println('Original: ${nums}')
	println('Unique: ${uniques}')
	assert uniques == [1, 2, 3, 4, 5]

	a := [1, 2, 3, 4]
	b := [3, 4, 5, 6]
	inter := sliceutils.intersection(a, b)
	diff := sliceutils.difference(a, b)
	println('Intersection of ${a} & ${b}: ${inter}')
	println('Difference of ${a} - ${b}: ${diff}')
	assert inter == [3, 4]
	assert diff == [1, 2]

	// 2. Chunking & Flattening
	chunked := sliceutils.chunk([1, 2, 3, 4, 5, 6, 7], 3)
	println('Chunked (size 3): ${chunked}')
	assert chunked.len == 3
	assert chunked[0] == [1, 2, 3]

	flattened := sliceutils.flatten(chunked)
	println('Flattened: ${flattened}')
	assert flattened == [1, 2, 3, 4, 5, 6, 7]

	// 3. Partitioning
	evens, odds := sliceutils.partition([1, 2, 3, 4, 5, 6], fn (x int) bool {
		return x % 2 == 0
	})
	println('Partitioned evens: ${evens}, odds: ${odds}')
	assert evens == [2, 4, 6]
	assert odds == [1, 3, 5]

	// 4. Numerical Stats
	scores := [10.0, 20.0, 30.0, 40.0]
	sum_val := sliceutils.sum_f64(scores)
	avg_val := sliceutils.average_f64(scores)
	min_val := sliceutils.min_f64(scores)?
	max_val := sliceutils.max_f64(scores)?
	println('Scores: ${scores} -> sum=${sum_val}, avg=${avg_val}, min=${min_val}, max=${max_val}')
	assert sum_val == 100.0
	assert avg_val == 25.0
	assert min_val == 10.0
	assert max_val == 40.0

	// 5. Sampling
	sampled := sliceutils.sample([100, 200, 300, 400, 500], 3)
	println('Sampled 3 items: ${sampled}')
	assert sampled.len == 3

	println('\n✔ sliceutils demo completed successfully!')
}
