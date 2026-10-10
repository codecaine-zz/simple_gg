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

// ============================================================================
// Unweighted Graph[T] extensions
// ============================================================================

// has_edge reports whether the directed edge from -> to exists.
pub fn (g Graph[T]) has_edge(from T, to T) bool {
	if from !in g.adjacency {
		return false
	}
	return to in g.adjacency[from]
}

// neighbors returns the direct successors of `node`.
pub fn (g Graph[T]) neighbors(node T) []T {
	if node !in g.adjacency {
		return []T{}
	}
	return g.adjacency[node].clone()
}

// remove_edge deletes the directed edge from -> to if present.
pub fn (mut g Graph[T]) remove_edge(from T, to T) {
	if from !in g.adjacency {
		return
	}
	adj := g.adjacency[from]
	idx := adj.index(to)
	if idx >= 0 {
		mut na := adj.clone()
		na.delete(idx)
		g.adjacency[from] = na
		g.in_degree[to] = g.in_degree[to] - 1
	}
}

// shortest_path returns the path with the fewest edges from `from` to `to` (BFS).
pub fn (g Graph[T]) shortest_path(from T, to T) ?[]T {
	if from !in g.adjacency || to !in g.adjacency {
		return none
	}
	mut prev := map[T]T{}
	mut seen := map[T]bool{}
	seen[from] = true
	mut queue := [from]
	mut head := 0
	for head < queue.len {
		cur := queue[head]
		head++
		if cur == to {
			mut path := [to]
			mut c := to
			for c != from {
				c = prev[c] or { break }
				path << c
			}
			path.reverse_in_place()
			return path
		}
		for nb in g.adjacency[cur] {
			if !seen[nb] {
				seen[nb] = true
				prev[nb] = cur
				queue << nb
			}
		}
	}
	return none
}

// reversed returns a copy of the graph with every edge direction flipped.
pub fn (g Graph[T]) reversed() Graph[T] {
	mut r := new_graph[T]()
	for n in g.nodes {
		r.add_node(n)
	}
	for n in g.nodes {
		for m in g.adjacency[n] {
			r.add_edge(m, n)
		}
	}
	return r
}

// strongly_connected_components returns the SCCs (Kosaraju, iterative). Each inner
// slice is one component; a DAG yields only singleton components.
pub fn (g Graph[T]) strongly_connected_components() [][]T {
	// 1st pass: iterative post-order on g.
	mut visited := map[T]bool{}
	mut finish := []T{cap: g.nodes.len}
	for s in g.nodes {
		if visited[s] {
			continue
		}
		mut stack := [s]
		mut iter := [0]
		visited[s] = true
		for stack.len > 0 {
			top := stack.last()
			adj := g.adjacency[top]
			i := iter[iter.len - 1]
			if i < adj.len {
				iter[iter.len - 1] = i + 1
				nb := adj[i]
				if !visited[nb] {
					visited[nb] = true
					stack << nb
					iter << 0
				}
			} else {
				finish << stack.pop()
				iter.delete_last()
			}
		}
	}
	// 2nd pass: DFS on reversed graph in decreasing finish time.
	r := g.reversed()
	mut assigned := map[T]bool{}
	mut comps := [][]T{}
	for k := finish.len - 1; k >= 0; k-- {
		s := finish[k]
		if assigned[s] {
			continue
		}
		mut comp := []T{}
		mut stack := [s]
		assigned[s] = true
		for stack.len > 0 {
			cur := stack.pop()
			comp << cur
			for nb in r.adjacency[cur] {
				if !assigned[nb] {
					assigned[nb] = true
					stack << nb
				}
			}
		}
		comps << comp
	}
	return comps
}

// find_cycle returns one directed cycle (first node repeated at the end), or none.
pub fn (g Graph[T]) find_cycle() ?[]T {
	mut color := map[T]int{} // 0 white, 1 grey, 2 black
	mut parent := map[T]T{}
	for s in g.nodes {
		if color[s] != 0 {
			continue
		}
		mut stack := [s]
		mut iter := [0]
		color[s] = 1
		for stack.len > 0 {
			top := stack.last()
			adj := g.adjacency[top]
			i := iter[iter.len - 1]
			if i < adj.len {
				iter[iter.len - 1] = i + 1
				nb := adj[i]
				if color[nb] == 0 {
					color[nb] = 1
					parent[nb] = top
					stack << nb
					iter << 0
				} else if color[nb] == 1 {
					mut cyc := [nb]
					mut c := top
					for c != nb {
						cyc << c
						c = parent[c] or { break }
					}
					cyc << nb
					cyc.reverse_in_place()
					return cyc
				}
			} else {
				color[stack.pop()] = 2
				iter.delete_last()
			}
		}
	}
	return none
}

// ============================================================================
// Union-Find (Disjoint Set Union) with path compression + union by rank
// ============================================================================

// UnionFind tracks a partition of 0..n-1 in near-constant amortized time per op.
pub struct UnionFind {
mut:
	parent []int
	rank   []int
	sets   int
}

// new_union_find creates n singleton sets.
pub fn new_union_find(n int) UnionFind {
	return UnionFind{
		parent: []int{len: n, init: index}
		rank:   []int{len: n}
		sets:   n
	}
}

// find returns the representative of x's set.
pub fn (mut u UnionFind) find(x int) int {
	mut root := x
	for u.parent[root] != root {
		root = u.parent[root]
	}
	mut c := x
	for u.parent[c] != root {
		next := u.parent[c]
		u.parent[c] = root
		c = next
	}
	return root
}

// union merges the sets of a and b; returns false if already joined.
pub fn (mut u UnionFind) union(a int, b int) bool {
	mut ra := u.find(a)
	mut rb := u.find(b)
	if ra == rb {
		return false
	}
	if u.rank[ra] < u.rank[rb] {
		ra, rb = rb, ra
	}
	u.parent[rb] = ra
	if u.rank[ra] == u.rank[rb] {
		u.rank[ra]++
	}
	u.sets--
	return true
}

// connected reports whether a and b are in the same set.
pub fn (mut u UnionFind) connected(a int, b int) bool {
	return u.find(a) == u.find(b)
}

// count returns the number of disjoint sets.
pub fn (u UnionFind) count() int {
	return u.sets
}

// ============================================================================
// WeightedGraph[T]: Dijkstra, A*, Kruskal MST, components
// ============================================================================

struct WEdge {
	to int
	w  f64
}

// Edge is a weighted edge in a WeightedGraph.
pub struct Edge[T] {
pub:
	from   T
	to     T
	weight f64
}

// Path is a route through a weighted graph with its total cost.
pub struct Path[T] {
pub:
	nodes []T
	cost  f64
}

// WeightedGraph is a directed or undirected graph with non-negative f64 edge weights.
pub struct WeightedGraph[T] {
mut:
	index    map[T]int
	nodes    []T
	adj      [][]WEdge
	directed bool
}

// new_weighted_graph creates an empty weighted graph.
pub fn new_weighted_graph[T](directed bool) WeightedGraph[T] {
	return WeightedGraph[T]{
		directed: directed
	}
}

fn (mut g WeightedGraph[T]) id(n T) int {
	if n in g.index {
		return g.index[n]
	}
	i := g.nodes.len
	g.index[n] = i
	g.nodes << n
	g.adj << []WEdge{}
	return i
}

// add_node registers a node (no-op if present).
pub fn (mut g WeightedGraph[T]) add_node(n T) {
	g.id(n)
}

// add_edge adds an edge with a non-negative weight (both directions when undirected).
pub fn (mut g WeightedGraph[T]) add_edge(from T, to T, weight f64) ! {
	if weight < 0 || weight != weight {
		return error('edge weights must be non-negative numbers, got ${weight}')
	}
	a := g.id(from)
	b := g.id(to)
	g.adj[a] << WEdge{b, weight}
	if !g.directed && a != b {
		g.adj[b] << WEdge{a, weight}
	}
}

// node_count returns the number of nodes.
pub fn (g WeightedGraph[T]) node_count() int {
	return g.nodes.len
}

// --- minimal binary heap keyed by f64 priority -------------------------------

struct HeapItem {
	pri  f64
	node int
}

fn heap_push(mut h []HeapItem, it HeapItem) {
	h << it
	mut i := h.len - 1
	for i > 0 {
		p := (i - 1) / 2
		if h[p].pri <= h[i].pri {
			break
		}
		h[p], h[i] = h[i], h[p]
		i = p
	}
}

fn heap_pop(mut h []HeapItem) HeapItem {
	top := h[0]
	last := h.pop()
	if h.len > 0 {
		h[0] = last
		mut i := 0
		for {
			l := 2 * i + 1
			r := l + 1
			mut m := i
			if l < h.len && h[l].pri < h[m].pri {
				m = l
			}
			if r < h.len && h[r].pri < h[m].pri {
				m = r
			}
			if m == i {
				break
			}
			h[m], h[i] = h[i], h[m]
			i = m
		}
	}
	return top
}

fn (g WeightedGraph[T]) search(src int, dst int, h fn (T) f64) ?Path[T] {
	inf := 1.0e308
	mut dist := []f64{len: g.nodes.len, init: inf}
	mut prev := []int{len: g.nodes.len, init: -1}
	mut done := []bool{len: g.nodes.len}
	mut heap := []HeapItem{}
	dist[src] = 0
	heap_push(mut heap, HeapItem{h(g.nodes[src]), src})
	for heap.len > 0 {
		cur := heap_pop(mut heap).node
		if done[cur] {
			continue
		}
		done[cur] = true
		if cur == dst {
			break
		}
		for e in g.adj[cur] {
			nd := dist[cur] + e.w
			if nd < dist[e.to] {
				dist[e.to] = nd
				prev[e.to] = cur
				heap_push(mut heap, HeapItem{nd + h(g.nodes[e.to]), e.to})
			}
		}
	}
	if dist[dst] >= inf {
		return none
	}
	mut path := []T{}
	mut c := dst
	for c != -1 {
		path << g.nodes[c]
		c = prev[c]
	}
	path.reverse_in_place()
	return Path[T]{path, dist[dst]}
}

fn zero_heuristic[T](_ T) f64 {
	return 0
}

// dijkstra returns the cheapest path from `from` to `to` (O((V+E) log V)).
pub fn (g WeightedGraph[T]) dijkstra(from T, to T) ?Path[T] {
	if from !in g.index || to !in g.index {
		return none
	}
	return g.search(g.index[from], g.index[to], zero_heuristic[T])
}

// astar finds the cheapest path guided by an admissible heuristic `h(node)` that
// never overestimates the remaining cost to `to`.
pub fn (g WeightedGraph[T]) astar(from T, to T, h fn (T) f64) ?Path[T] {
	if from !in g.index || to !in g.index {
		return none
	}
	return g.search(g.index[from], g.index[to], h)
}

// distances_from returns the shortest distance from `from` to every reachable node.
pub fn (g WeightedGraph[T]) distances_from(from T) map[T]f64 {
	mut out := map[T]f64{}
	if from !in g.index {
		return out
	}
	inf := 1.0e308
	src := g.index[from]
	mut dist := []f64{len: g.nodes.len, init: inf}
	mut heap := []HeapItem{}
	dist[src] = 0
	heap_push(mut heap, HeapItem{0, src})
	for heap.len > 0 {
		it := heap_pop(mut heap)
		if it.pri > dist[it.node] {
			continue
		}
		for e in g.adj[it.node] {
			nd := dist[it.node] + e.w
			if nd < dist[e.to] {
				dist[e.to] = nd
				heap_push(mut heap, HeapItem{nd, e.to})
			}
		}
	}
	for i, d in dist {
		if d < inf {
			out[g.nodes[i]] = d
		}
	}
	return out
}

// minimum_spanning_tree returns the MST/forest edges via Kruskal (undirected semantics).
pub fn (g WeightedGraph[T]) minimum_spanning_tree() []Edge[T] {
	mut edges := []Edge[T]{}
	mut raw := [][]f64{}
	for a, list in g.adj {
		for e in list {
			raw << [f64(a), f64(e.to), e.w]
		}
	}
	raw.sort_with_compare(fn (x &[]f64, y &[]f64) int {
		return if x[2] < y[2] {
			-1
		} else if x[2] > y[2] {
			1
		} else {
			0
		}
	})
	mut uf := new_union_find(g.nodes.len)
	for r in raw {
		if uf.union(int(r[0]), int(r[1])) {
			edges << Edge[T]{g.nodes[int(r[0])], g.nodes[int(r[1])], r[2]}
		}
	}
	return edges
}

// connected_components groups nodes connected by edges, ignoring direction.
pub fn (g WeightedGraph[T]) connected_components() [][]T {
	mut uf := new_union_find(g.nodes.len)
	for a, list in g.adj {
		for e in list {
			uf.union(a, e.to)
		}
	}
	mut groups := map[int][]T{}
	mut order := []int{}
	for i, n in g.nodes {
		r := uf.find(i)
		if r !in groups {
			order << r
		}
		groups[r] << n
	}
	return order.map(groups[it])
}
