#import "../lib/style.typ": *
#import "../lib/mapcode.typ": *

#set math.equation(numbering: none)

== Description of the problem and example input outputs

Compute the number of connected components in an undirected graph $G = (V, E)$ where $|V| = n$ and $|E| = m$.

A connected component is a maximal set of vertices such that there exists a path between any pair of vertices in the set.

Formal definition:
$
"components"(G) = |{C_1, C_2, ..., C_k}|
$
where each $C_i subset.eq V$ is a maximal connected subgraph.

Examples:
- Graph with vertices ${0, 1, 2, 3}$ and edges ${(0,1), (2,3)}$ has 2 components
- Graph with vertices ${0, 1, 2}$ and edges ${(0,1), (1,2)}$ has 1 component
- Graph with $n$ isolated vertices has $n$ components

== Recursive Solution (without mapcode)

The standard recursive approach uses depth-first search (DFS):

$
"countComponents"(G) &= sum_(v in V) "newComponent"(v)\
"newComponent"(v) &= cases(
  1 & "if" v "unvisited, then" "DFS"(v) "and return" 1,
  0 & "if" v "already visited"
)\
"DFS"(v) &= cases(
  "mark" v "visited" & "base case",
  forall u in "adj"[v]: "DFS"(u) & "recursive calls to neighbors"
)
$

This recursion satisfies the non-triviality requirement because:
- The DFS function makes *multiple recursive calls* (one for each neighbor), creating a branching recursion structure.
- Each recursive call explores a strictly smaller substructure (the set of unvisited vertices decreases).
- The algorithm exhibits ≥ 2 branches when a vertex has multiple neighbors, and the overall structure combines multiple DFS traversals.
- The recursion depth can be up to $n$ (in a path graph), and each DFS may spawn multiple recursive branches.

== Mapcode

=== Primitives

Data type and domain → range:
- Domain: Graphs $G = (V, E)$ represented as $(n, m, "AdjList")$
- Range: $NN_0$ (number of connected components)

Primitives used:
- Graph adjacency structure (adjacency list): $V -> 2^V$
- Array/vector operations (assignment, comparison): ${0,1}^n$
- Logical operations (checking all vertices visited): ${0,1}^n -> "Bool"$
- Min operation (for seed selection): $2^V -> V$

=== Maps and spaces

Mapcode components:

$ 
I &= NN times NN times "AdjList" \
X &= {0,1}^n times NN_0 times (ZZ union {-1}) times "AdjList" times NN\
A &= NN_0
$

where:
- ${0,1}^n$ represents the visited array (0 = unvisited, 1 = visited)
- $NN_0$ is the component count
- $ZZ union {-1}$ is the current seed (-1 = no DFS active, $>= 0$ = DFS from seed)
- $"AdjList"$ is the adjacency list representation
- The last $NN$ stores $n$ (number of vertices)

*Initialization* $rho: I -> X$:
$
rho(n, m, "adj") & = ("visited": arrow.r 0^n, "count": 0, "seed": -1, "adj", n)
$

*Update function* $F: X -> X$:
$
F(x equiv ("vis", c, s, "adj", n)) & = cases(
  x & "if" s = -1 "and" forall i: "vis"[i] = 1 quad "(" "fixed point" ")",
  
  ("vis", c, i^*, "adj", n) & "if" s = -1 "and" exists i^*: "vis"[i^*] = 0 quad "(" "choose seed" ")",
  
  ("vis"', c, s, "adj", n) & "if" s >= 0 "and" "vis"' != "vis" quad "(" "expand reachability" ")",
  
  ("vis"', c+1, -1, "adj", n) & "if" s >= 0 "and" "vis"' = "vis" quad "(" "DFS complete" ")"
)
$

where $"vis"'$ is the reachability closure:
$
"vis"'[v] = cases(
  1 & "if" "vis"[v] = 1,
  1 & "if" exists u: "vis"[u] = 1 "and" (u,v) in E,
  0 & "otherwise"
)
$

and $i^* = min{i | "vis"[i] = 0}$ is the first unvisited vertex.

*Output function* $pi: X -> A$:
$
pi(x equiv ("vis", c, s, "adj", n)) & = c
$

*Algorithm explanation:*

The algorithm operates in two alternating phases:

1. *Seed selection phase* ($s = -1$): Find the next unvisited vertex to start a DFS from. If all vertices are visited, reach fixed point.

2. *DFS expansion phase* ($s >= 0$): Propagate reachability from the current seed by marking all neighbors of visited vertices. When no new vertices are reached (fixed point of reachability), increment component count and return to seed selection.

=== Trace

The trace visualization below demonstrates convergence to a fixed point through iterative application of $F$. Each iteration either selects a new seed vertex or expands the reachability from the current seed, showing how $x in X$ converges from the initial state $rho(n, m, "adj")$ to a fixed point where all components are counted.

#let inst = (
  n: 6,
  edges: ((0, 1), (1, 2), (3, 4))
);

#figure(
  caption: [
    Connected components computation for a graph with $n = #inst.n$ vertices and edges $#inst.edges$. 
    
    This graph has 3 components: ${0, 1, 2}$, ${3, 4}$, and ${5}$.
  ],
$
#{
  let build_adj = (n, edges) => {
    let adj = ()
    for i in range(n) {
      adj.push(())
    }
    for edge in edges {
      let (u, v) = edge
      adj.at(u).push(v)
      adj.at(v).push(u)
    }
    adj
  }

  let rho = (inp) => {
    let (n, edges) = inp
    let adj = build_adj(n, edges)
    (
      visited: range(n).map(i => 0),
      count: 0,
      seed: -1,
      adj: adj,
      n: n
    )
  }

  let F = (x) => {
    let visited = x.visited
    let count = x.count
    let seed = x.seed
    let adj = x.adj
    let n = x.n
    
    // CASE 1: no DFS active → choose next seed
    if seed == -1 {
      let next_seed = -1
      for i in range(n) {
        if visited.at(i) == 0 {
          next_seed = i
          break
        }
      }
      if next_seed == -1 {
        // all visited → fixed point
        return x
      }
      return (
        visited: visited,
        count: count,
        seed: next_seed,
        adj: adj,
        n: n
      )
    }
    
    // CASE 2: DFS active → expand reachability
    let new_visited = visited
    
    // ensure seed is marked
    new_visited.at(seed) = 1
    
    // propagate reachability
    for i in range(n) {
      if new_visited.at(i) == 1 {
        for v in adj.at(i) {
          new_visited.at(v) = 1
        }
      }
    }
    
    let changed = (new_visited != visited)
    
    if not changed {
      // DFS finished
      return (
        visited: new_visited,
        count: count + 1,
        seed: -1,
        adj: adj,
        n: n
      )
    } else {
      return (
        visited: new_visited,
        count: count,
        seed: seed,
        adj: adj,
        n: n
      )
    }
  }

  let pi = (x) => x.count

  let X_h = (x, diff_mask: none) => {
    let vis_str = x.visited.map(v => str(v)).join(",")
    let seed_str = if x.seed == -1 { "-1" } else { str(x.seed) }
    [$(#vis_str | c=#x.count | s=#seed_str)$]
  }

  let I_h = (inp) => {
    let (n, edges) = inp
    [$(n=#n)$]
  }

  mapcode-viz(
    rho, F, pi,
    I_h: I_h,
    X_h: X_h,
    rho_name: [$rho$],
    F_name: [$F$],
    pi_name: [$pi$],
    f_name: [$f$],
    group-size: 4,
    cell-size: 20mm,
    scale-fig: 60%
  )((inst.n, inst.edges))
}
$
)

#v(1em)

#figure(
  caption: [Visual representation of the graph structure],
  
  // Visual representation of the graph
  [
    #set align(center)
    #grid(
      columns: 3,
      gutter: 2em,
      [
        *Component 1*\
        #circle(radius: 8pt, fill: blue.lighten(60%))[0]\
        |#v(0.3em)\
        #circle(radius: 8pt, fill: blue.lighten(60%))[1]\
        |#v(0.3em)\
        #circle(radius: 8pt, fill: blue.lighten(60%))[2]
      ],
      [
        *Component 2*\
        #circle(radius: 8pt, fill: green.lighten(60%))[3]\
        —\
        #circle(radius: 8pt, fill: green.lighten(60%))[4]
      ],
      [
        *Component 3*\
        #circle(radius: 8pt, fill: red.lighten(60%))[5]
      ]
    )
    
    #v(1em)
    
    *Program space evolution (detailed):*
    
    #table(
      columns: (auto, auto, auto, auto),
      align: (left, left, center, left),
      [*Step*], [*Visited*], [*Seed*], [*Count*],
      [Initial], [[0,0,0,0,0,0]], [-1], [0],
      [Select seed 0], [[0,0,0,0,0,0]], [0], [0],
      [DFS expand], [[1,0,0,0,0,0]], [0], [0],
      [DFS expand], [[1,1,0,0,0,0]], [0], [0],
      [DFS expand], [[1,1,1,0,0,0]], [0], [0],
      [DFS complete], [[1,1,1,0,0,0]], [-1], [1],
      [Select seed 3], [[1,1,1,0,0,0]], [3], [1],
      [DFS expand], [[1,1,1,1,0,0]], [3], [1],
      [DFS expand], [[1,1,1,1,1,0]], [3], [1],
      [DFS complete], [[1,1,1,1,1,0]], [-1], [2],
      [Select seed 5], [[1,1,1,1,1,0]], [5], [2],
      [DFS expand], [[1,1,1,1,1,1]], [5], [2],
      [DFS complete], [[1,1,1,1,1,1]], [-1], [3],
      [Fixed point], [[1,1,1,1,1,1]], [-1], [*3*],
    )
  ]
)

The trace shows at least 5 iterations (in fact, 13 steps for this graph), demonstrating how the algorithm alternates between seed selection and DFS expansion phases. The final result of 3 components matches the known structure of the graph: ${0, 1, 2}$, ${3, 4}$, and ${5}$.

=== Correctness

Intuitively, the algorithm correctly counts connected components by:
1. *Invariant preservation*: Each DFS expansion from a seed fully explores one connected component by iteratively marking all reachable vertices.
2. *Completeness*: The seed selection phase ensures every vertex is eventually visited, so no component is missed.
3. *Counting accuracy*: The component count increments exactly once per completed DFS (when reachability reaches a fixed point), ensuring each component is counted exactly once.

The alternating phase structure ensures that:
- When $s >= 0$, the visited array expands to include all vertices reachable from the seed
- When $"vis"'= "vis"$ during DFS, the component is fully explored, so we increment count and reset to seed selection
- When $s = -1$ and all vertices are visited, we've counted all components and reach the global fixed point

=== Implementation notes

Key design decisions:
- *State representation*: The state $X$ maintains five components: visited array, count, current seed, adjacency list, and $n$. This captures both the algorithmic progress and the graph structure.
- *Phase alternation*: The seed value $s$ serves as a mode indicator: $s = -1$ means "find next component," while $s >= 0$ means "expand current component from seed $s$."
- *Convergence*: The algorithm reaches a fixed point when all vertices are visited ($forall i: "vis"[i] = 1$) and no DFS is active ($s = -1$).
- *Mapping from recursion*: The recursive DFS branching (calling DFS on each neighbor) is captured by the reachability closure operation, which simultaneously marks all neighbors of all visited vertices. This is a breadth-first parallel expansion rather than depth-first sequential exploration.
- *Non-triviality through branching*: The recursion exhibits ≥ 2 branches because DFS on a vertex with multiple neighbors spawns multiple recursive calls. The mapcode captures this through the reachability closure that explores all neighbors simultaneously.
- *Nested fixed points*: The algorithm has two levels of fixed points: (1) inner fixed point when DFS completes (no new vertices reachable), and (2) outer fixed point when all vertices are visited (no more components to find).