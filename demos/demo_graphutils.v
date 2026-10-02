module main

import graphutils

fn main() {
	println('=== graphutils Demo ===')

	// 1. Build Pipeline Dependency DAG
	mut dag := graphutils.new_graph[string]()
	dag.add_edge('fetch_deps', 'compile_c')
	dag.add_edge('fetch_deps', 'generate_code')
	dag.add_edge('compile_c', 'link_binary')
	dag.add_edge('generate_code', 'link_binary')
	dag.add_edge('link_binary', 'run_tests')
	dag.add_edge('run_tests', 'deploy_prod')

	println('Has cycle: ${dag.has_cycle()}')
	assert dag.has_cycle() == false

	order := dag.topological_sort() or { panic(err) }
	println('Execution Order: ${order}')

	// 2. Traversals
	bfs_res := dag.bfs('fetch_deps')
	println('BFS traversal from fetch_deps: ${bfs_res}')

	dfs_res := dag.dfs('fetch_deps')
	println('DFS traversal from fetch_deps: ${dfs_res}')

	println('graphutils demo completed successfully!')
}
