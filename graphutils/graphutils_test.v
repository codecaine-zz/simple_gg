module graphutils

fn test_dag_topological_sort() {
	mut g := new_graph[string]()
	// Task dependency graph: build -> test -> deploy
	g.add_edge('build', 'test')
	g.add_edge('test', 'deploy')
	g.add_edge('lint', 'test')

	order := g.topological_sort() or { panic(err) }
	assert order.len == 4

	build_idx := order.index('build')
	test_idx := order.index('test')
	deploy_idx := order.index('deploy')
	lint_idx := order.index('lint')

	assert build_idx < test_idx
	assert lint_idx < test_idx
	assert test_idx < deploy_idx

	assert g.has_cycle() == false
}

fn test_cycle_detection() {
	mut g := new_graph[string]()
	g.add_edge('a', 'b')
	g.add_edge('b', 'c')
	g.add_edge('c', 'a') // Circular!

	assert g.has_cycle() == true
	g.topological_sort() or {
		assert err.msg().contains('cycle')
		return
	}
	assert false
}

fn test_bfs_and_dfs() {
	mut g := new_graph[int]()
	g.add_edge(1, 2)
	g.add_edge(1, 3)
	g.add_edge(2, 4)
	g.add_edge(3, 5)

	bfs_res := g.bfs(1)
	assert bfs_res.len == 5
	assert bfs_res[0] == 1

	dfs_res := g.dfs(1)
	assert dfs_res.len == 5
	assert dfs_res[0] == 1
}
