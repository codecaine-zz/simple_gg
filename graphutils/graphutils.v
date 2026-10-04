module graphutils

// Graph represents a generic directed graph for dependency resolution and network traversal.
pub struct Graph[T] {
pub mut:
	nodes     []T
	adjacency map[T][]T
	in_degree map[T]int
}

// new_graph creates an empty directed graph.
pub fn new_graph[T]() Graph[T] {
	return Graph[T]{
		nodes:     []T{}
		adjacency: map[T][]T{}
		in_degree: map[T]int{}
	}
}

// add_node adds a node to the graph if it is not already present.
pub fn (mut g Graph[T]) add_node(node T) {
	// O(1) membership via the adjacency map (was a linear scan of `nodes`).
	if node !in g.adjacency {
		g.nodes << node
		g.adjacency[node] = []T{}
		g.in_degree[node] = 0
	}
}

// add_edge adds a directed edge from `from` node to `to` node. Automatically adds missing nodes.
pub fn (mut g Graph[T]) add_edge(from T, to T) {
	g.add_node(from)
	g.add_node(to)

	if to !in g.adjacency[from] {
		g.adjacency[from] << to
		g.in_degree[to] = g.in_degree[to] + 1
	}
}

// topological_sort performs Kahn's algorithm to return an ordered dependency list, or error if cyclic.
pub fn (g Graph[T]) topological_sort() ![]T {
	mut in_deg := g.in_degree.clone()
	mut queue := []T{}

	for node in g.nodes {
		if in_deg[node] == 0 {
			queue << node
		}
	}

	mut order := []T{}
	mut head := 0 // index-based queue: O(V+E) instead of O(V^2) front deletions
	for head < queue.len {
		curr := queue[head]
		head++
		order << curr

		for neighbor in g.adjacency[curr] {
			in_deg[neighbor] = in_deg[neighbor] - 1
			if in_deg[neighbor] == 0 {
				queue << neighbor
			}
		}
	}

	if order.len != g.nodes.len {
		return error('graph contains a circular dependency / cycle')
	}

	return order
}

// has_cycle checks whether the graph contains any cycle.
pub fn (g Graph[T]) has_cycle() bool {
	g.topological_sort() or { return true }
	return false
}

// bfs performs Breadth-First Search starting from start node, returning visited nodes in order.
pub fn (g Graph[T]) bfs(start T) []T {
	if start !in g.adjacency {
		return []T{}
	}
	mut visited := map[T]bool{}
	mut order := []T{}
	mut queue := [start]
	visited[start] = true

	mut head := 0
	for head < queue.len {
		curr := queue[head]
		head++
		order << curr

		for neighbor in g.adjacency[curr] {
			if !visited[neighbor] {
				visited[neighbor] = true
				queue << neighbor
			}
		}
	}
	return order
}

// dfs performs Depth-First Search starting from start node, returning visited nodes in order.
pub fn (g Graph[T]) dfs(start T) []T {
	if start !in g.adjacency {
		return []T{}
	}
	// Iterative pre-order DFS (same visiting order as the recursive version, but cannot
	// overflow the call stack on deep graphs).
	mut visited := map[T]bool{}
	mut order := []T{}
	mut stack := [start]
	for stack.len > 0 {
		curr := stack.pop()
		if visited[curr] {
			continue
		}
		visited[curr] = true
		order << curr
		adj := g.adjacency[curr]
		for i := adj.len - 1; i >= 0; i-- {
			if !visited[adj[i]] {
				stack << adj[i]
			}
		}
	}
	return order
}
