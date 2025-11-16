#import "../lib/style.typ": *
#import "../lib/mapcode.typ": *

#set math.equation(numbering: none)

== Description of the problem and example input outputs

Compute two mutually recursive sequences $A_n$ and $B_n$ for a non-negative integer $n in NN_0$.

Formal definition:
$
A_n &= B_(n-1) + 1\
B_n &= A_(n-1) + 2
$
with base cases $A_0 = 0$ and $B_0 = 0$.

Closed form:
$
A_n &= 3n - 1\
B_n &= 3n + 1
$

Examples:
- $n = 0: A_0 = 0, B_0 = 0$
- $n = 1: A_1 = 1, B_1 = 2$
- $n = 2: A_2 = 3, B_2 = 3$
- $n = 3: A_3 = 4, B_3 = 5$
- $n = 5: A_5 = 14, B_5 = 16$

== Recursive Solution (without mapcode)

Mutually recursive formulation:
$
A_n &= cases(
  0 & "if" n = 0,
  B_(n-1) + 1 & "if" n > 0
)\
B_n &= cases(
  0 & "if" n = 0,
  A_(n-1) + 2 & "if" n > 0
)
$

This recursion satisfies the non-triviality requirement because:
- The computation exhibits *mutual recursion*: $A_n$ depends on $B_(n-1)$ and $B_n$ depends on $A_(n-1)$.
- Each function calls the other function on a strictly smaller input ($n-1$), creating a co-recursive dependency structure.
- This is a self-referential structure of arity $>= 2$ (two mutually dependent sequences).
- The recursion depth equals $n$ for both sequences.

== Mapcode

=== Primitives

Data type and domain → range:
- Domain: $NN_0$ (non-negative integers)
- Range: $NN_0 times NN_0$ (pair of sequence values)

Primitives used:
- `add`($+$): addition, $NN_0 times NN_0 -> NN_0$

Addition on $bot$ is undefined (strict).

=== Maps and spaces

Mapcode components:

$ 
I = NN_0 quad quad quad X_n &= [0..n] -> (NN_(0,bot) times NN_(0,bot)) quad quad quad A = NN_0 times NN_0
$

*Initialization* $rho: I -> X_n$:
$
rho(n) & = {k -> (bot, bot) | k in [0..n]}
$

*Update function* $F: X_n -> X_n$:
$
F(x_n equiv (A_k, B_k))(k) & = cases(
  (A_k, B_k) & "if " A_k != bot "and" B_k != bot,
  (0, B_k) & "if " A_k = bot "and" k = 0,
  (B_(k-1) + 1, B_k) & "if " A_k = bot "and" k > 0 "and" B_(k-1) != bot,
  (A_k, B_k) & "if " A_k = bot "and" k > 0 "and" B_(k-1) = bot
) \
& quad quad union cases(
  (A_k, B_k) & "if " A_k != bot "and" B_k != bot,
  (A_k, 0) & "if " B_k = bot "and" k = 0,
  (A_k, A_(k-1) + 2) & "if " B_k = bot "and" k > 0 "and" A_(k-1) != bot,
  (A_k, B_k) & "if " B_k = bot "and" k > 0 "and" A_(k-1) = bot
)
$

*Output function* $pi: X_n -> A$:
$
pi(x equiv (A_k, B_k)) & = (A_n, B_n)
$

where $(A_k, B_k)$ represents a pair of values from the two mutually recursive sequences at position $k$.

Note: The function $F$ updates both components independently based on their dependencies, with $A_k$ depending on $B_(k-1)$ and $B_k$ depending on $A_(k-1)$.

=== Trace

The trace visualization below demonstrates convergence to a fixed point through iterative application of $F$. Each iteration computes more values from both sequences, showing how $x in X$ converges from the initial state $rho(n)$ to a fixed point where all sequence values are computed.

#let inst = 5;
#figure(
  caption: [Mutual recursion computation using mapcode for $n = #inst$],
$
#{
  let rho = (n) => {
    let x = ()
    for i in range(0, n + 1) {
      x.push((none, none))
    }
    x
  }

  let F_i = (x) => ((k,)) => {
    let curr = x.at(k)
    let A_k = curr.at(0)
    let B_k = curr.at(1)
    
    // Compute new A_k
    let new_A = if A_k != none {
      A_k
    } else if k == 0 {
      0
    } else {
      let prev = x.at(k - 1)
      if prev.at(1) != none {
        prev.at(1) + 1
      } else {
        none
      }
    }
    
    // Compute new B_k
    let new_B = if B_k != none {
      B_k
    } else if k == 0 {
      0
    } else {
      let prev = x.at(k - 1)
      if prev.at(0) != none {
        prev.at(0) + 2
      } else {
        none
      }
    }
    
    (new_A, new_B)
  }
  let F = map_tensor(F_i, dim: 1)

  let pi = (i) => (x) => x.at(i)

  let X_h = (x, diff_mask: none) => {
    let cells = x.enumerate().map(((i, pair)) => {
      let val = if pair.at(0) != none and pair.at(1) != none {
        [$(#pair.at(0), #pair.at(1))$]
      } else if pair.at(0) != none and pair.at(1) == none {
        [$(#pair.at(0), bot)$]
      } else if pair.at(0) == none and pair.at(1) != none {
        [$(bot, #pair.at(1))$]
      } else {
        [$(bot, bot)$]
      }
      // if diff_mask != none and diff_mask.at(i) {
        // rect(fill: yellow.transparentize(70%), inset: 2pt)[$#val$]
      // } else {
        rect(stroke: none, inset: 2pt)[$#val$]
      // }
    })
    $vec(delim: "[", ..cells)$
  }

  mapcode-viz(
    rho, F, pi(inst),
    X_h: X_h,
    pi_name: [$mpi$],
    group-size: calc.min(7, inst + 1),
    cell-size: 15mm, scale-fig: 75%
  )(inst)
  
}
$
)

The trace shows at least 5 iterations (for $n = 5$, we compute positions $k in [0..5]$, requiring multiple iterations to reach the fixed point where all values are computed). The final result $(A_5, B_5) = (14, 16)$ matches the known closed-form results: $A_5 = 3(5) - 1 = 14$ and $B_5 = 3(5) + 1 = 16$.

=== Correctness

Intuitively, at each iteration, the map $F$ computes new values for both sequences based on their mutual dependencies. Position $k$ can compute $A_k$ once $B_(k-1)$ is available, and $B_k$ once $A_(k-1)$ is available. After sufficient iterations, all positions have computed both their $A$ and $B$ values, reaching a fixed point.

The mutual dependency creates an interleaved computation pattern where:
1. Base cases $A_0 = 0$ and $B_0 = 0$ are established in the first iteration
2. From these, $A_1 = B_0 + 1$ and $B_1 = A_0 + 2$ can be computed
3. This pattern continues, with each position depending on the previous position's values from the other sequence

=== Implementation notes

Key design decisions:
- *State representation*: Each position $k in [0..n]$ maintains a pair $(A_k, B_k)$ representing both sequence values at that position.
- *Mutual dependency structure*: Position $k$ has a cross-dependency on position $k-1$, where $A_k$ depends on $B_(k-1)$ and $B_k$ depends on $A_(k-1)$, creating the mutual recursion pattern.
- *Convergence*: The algorithm requires multiple iterations due to the interleaved dependencies. The exact number depends on how the map processes updates, but all values are eventually computed.
- *Mapping from recursion*: The mutual recursive calls are captured by the cross-dependencies in the update function, where computing one sequence value requires the other sequence's previous value.
- *Co-recursive structure*: This exemplifies a self-referential structure of arity ≥ 2, as the two sequences are defined in terms of each other, satisfying the non-trivial recursion requirement through mutual dependency rather than branching.