module graphutils

import math

fn test_deep_graph_no_stack_overflow() {
	mut g := new_graph[int]()
	for i in 0 .. 200000 {
		g.add_edge(i, i + 1)
	}
	assert g.dfs(0).len == 200001
	assert g.bfs(0).len == 200001
	assert g.topological_sort()!.len == 200001
}

fn test_dfs_order_preserved() {
	mut g := new_graph[string]()
	g.add_edge('a', 'b')
	g.add_edge('a', 'c')
	g.add_edge('b', 'd')
	g.add_edge('c', 'd')
	assert g.dfs('a') == ['a', 'b', 'd', 'c']
}

fn test_shortest_path_and_edges() {
	mut g := new_graph[string]()
	g.add_edge('a', 'b')
	g.add_edge('b', 'c')
	g.add_edge('a', 'c')
	assert g.shortest_path('a', 'c')? == ['a', 'c']
	assert g.shortest_path('c', 'a') == none
	assert g.has_edge('a', 'b')
	g.remove_edge('a', 'c')
	assert !g.has_edge('a', 'c')
	assert g.shortest_path('a', 'c')? == ['a', 'b', 'c']
	assert g.neighbors('a') == ['b']
}

fn test_scc_and_cycle() {
	mut g := new_graph[int]()
	g.add_edge(1, 2)
	g.add_edge(2, 3)
	g.add_edge(3, 1)
	g.add_edge(3, 4)
	g.add_edge(4, 5)
	g.add_edge(5, 4)
	mut comps := g.strongly_connected_components().map(it.sorted())
	comps.sort(a[0] < b[0])
	assert comps == [[1, 2, 3], [4, 5]]
	cyc := g.find_cycle()?
	assert cyc.first() == cyc.last()
	for i in 0 .. cyc.len - 1 {
		assert g.has_edge(cyc[i], cyc[i + 1])
	}
	mut dag := new_graph[int]()
	dag.add_edge(1, 2)
	assert dag.find_cycle() == none
}

fn test_union_find() {
	mut u := new_union_find(5)
	assert u.count() == 5
	assert u.union(0, 1)
	assert u.union(3, 4)
	assert !u.union(1, 0)
	assert u.connected(0, 1)
	assert !u.connected(1, 3)
	assert u.count() == 3
}

fn test_dijkstra_astar_mst() {
	mut g := new_weighted_graph[string](false)
	g.add_edge('A', 'B', 4)!
	g.add_edge('A', 'C', 2)!
	g.add_edge('C', 'B', 1)!
	g.add_edge('B', 'D', 5)!
	g.add_edge('C', 'D', 8)!
	g.add_edge('D', 'E', 3)!
	p := g.dijkstra('A', 'E')?
	assert p.nodes == ['A', 'C', 'B', 'D', 'E']
	assert p.cost == 11
	a := g.astar('A', 'E', fn (n string) f64 {
		return 0
	})?
	assert a.cost == 11
	d := g.distances_from('A')
	assert d['B'] == 3 && d['D'] == 8
	mst := g.minimum_spanning_tree()
	assert mst.len == 4
	mut total := 0.0
	for e in mst {
		total += e.weight
	}
	assert total == 11 // 2 + 1 + 5 + 3
	if _ := g.add_edge('X', 'Y', -1) {
		assert false
	}
}

fn test_astar_grid() {
	mut g := new_weighted_graph[int](false)
	w := 20
	for y in 0 .. w {
		for x in 0 .. w {
			if x + 1 < w {
				g.add_edge(y * w + x, y * w + x + 1, 1)!
			}
			if y + 1 < w {
				g.add_edge(y * w + x, (y + 1) * w + x, 1)!
			}
		}
	}
	goal := w * w - 1
	p := g.astar(0, goal, fn [w, goal] (n int) f64 {
		return math.abs(f64(n % w - goal % w)) + math.abs(f64(n / w - goal / w))
	})?
	assert p.cost == 2 * (w - 1)
	assert g.connected_components().len == 1
	mut dg := new_weighted_graph[int](true)
	dg.add_edge(1, 2, 1)!
	assert dg.dijkstra(2, 1) == none
}
