#import "../lib/style.typ": *
#import "../lib/mapcode.typ": *

#set math.equation(numbering: none)

== Description of the problem and example input outputs

Compute the prefix sum of an array of integers. Given an array $A = [a_0, a_1, ..., a_(n-1)]$, compute the prefix sum array where each element is the sum of all elements up to that position.

Formal definition:
$
"prefixsum"(A)[i] = sum_(j=0)^(i) A[j]
$

Examples:
- $"prefixsum"([1, 2, 3, 4]) -> [1, 3, 6, 10]$
- $"prefixsum"([5, -2, 3]) -> [5, 3, 6]$
- $"prefixsum"([10]) -> [10]$

== Recursive Solution (without mapcode)

Recursive formulation:
$
"prefixsum"(A)[i] = cases(
  A[0] & "if" i = 0,
  "prefixsum"(A)[i-1] + A[i] & "if" i > 0
)
$

This recursion satisfies the non-triviality requirement because:
- Each recursive call operates on a strictly smaller substructure: computing $"prefixsum"(A)[i-1]$ before $"prefixsum"(A)[i]$.
- The function makes a single recursive call for the previous position $i-1$, combined with a base case when $i = 0$.
- The recursion depth equals the array length $n$.

== Mapcode

=== Primitives

Data type and domain → range:
- Domain: $ZZ^*$ (arrays of integers)
- Range: $ZZ^n$ (prefix sum array)

Primitives used:
- `add`($+$): addition, $ZZ times ZZ -> ZZ$
- `size`: returns the length of an array, $ZZ^* -> NN$

Addition on $bot$ is undefined (strict).

=== Maps and spaces

Mapcode components:

$ 
I = NN times ZZ^* quad quad quad X_n &= [0..n-1] -> (ZZ_bot times ZZ) quad quad quad A = ZZ^n
$

where $n = |A|$ is the size of the input array.

*Initialization* $rho: I -> X_n$:
$
rho(n, A) & = {i -> (bot, A[i]) | i in [0..n-1]}
$

*Update function* $F: X_n -> X_n$:
$
F(x_n equiv (p_i, a_i))(i) & = cases(
  (p_i, a_i) & "if " p_i != bot,
  (a_i, a_i) & "if " p_i = bot "and" i = 0,
  (p_(i-1) + a_i, a_i) & "if " p_i = bot "and" i > 0 "and" p_(i-1) != bot,
  (bot, a_i) & "if " p_i = bot "and" i > 0 "and" p_(i-1) = bot
)
$

*Output function* $pi: X_n -> A$:
$
pi(x equiv (p_i, a_i)) & = [p_0, p_1, ..., p_(n-1)]
$

where $(p_i, a_i)$ represents a pair of (prefix sum, array element).

=== Trace

The trace visualization below demonstrates convergence to a fixed point through iterative application of $F$. Each iteration computes one more prefix sum value, showing how $x in X$ converges from the initial state $rho(n, A)$ to a fixed point where all prefix sums are computed.

#let inst = (1, 2, 3, 4, 5, 6);
#figure(
  caption: [Prefix sum computation using mapcode for array $#inst$],
$
#{
  let rho = (arr) => {
    let x = ()
    for val in arr {
      x.push((none, val))
    }
    x
  }

  let F_i = (x) => ((i,)) => {
    let curr = x.at(i)
    if curr.at(0) != none {
      // Already computed, return as-is
      curr
    } else {
      if i == 0 {
        (curr.at(1), curr.at(1))
      } else {
        let prev = x.at(i - 1)
        if prev.at(0) != none {
          (prev.at(0) + curr.at(1), curr.at(1))
        } else {
          (curr.at(0), curr.at(1))
        }
      }
    }
  }
  let F = map_tensor(F_i, dim: 1)

  let pi = (x) => {
    x.map(pair => pair.at(0))
  }

  let X_h = (x, diff_mask: none) => {
    let cells = x.enumerate().map(((i, pair)) => {
      let val = if pair.at(0) != none and pair.at(1) != none {
        [$(#pair.at(0), #pair.at(1))$]
      } else if pair.at(0) == none and pair.at(1) != none {
        [$(bot, #pair.at(1))$]
      } else {
        [$(bot, bot)$]
      }
      // if diff_mask != none and diff_mask.at(i) {
      //   rect(fill: yellow.transparentize(70%), inset: 2pt)[$#val$]
      // } else {
        rect(stroke: none, inset: 2pt)[$#val$]
      // }
    })
    $vec(delim: "[", ..cells)$
  }

  mapcode-viz(
    rho, F, pi,
    X_h: X_h,
    pi_name: [$mpi$],
    group-size: calc.min(7, inst.len()),
    cell-size: 15mm, scale-fig: 75%
  )(inst)
}
$
)

The trace shows at least 5 iterations (for the array $[1, 2, 3, 4, 5, 6]$, we have $n = 6$ elements, requiring 6 iterations to reach the fixed point). The final result $[1, 3, 6, 10, 15, 21]$ matches the known mathematical result: cumulative sums at each position.

=== Correctness

Intuitively, at each iteration, the map $F$ computes one more prefix sum value by adding the current array element to the previous prefix sum. After $n$ iterations, all prefix sums have been computed, and the state contains the complete prefix sum array.

=== Implementation notes

Key design decisions:
- *State representation*: Each position $i in [0..n-1]$ maintains a pair $(p_i, a_i)$ where $p_i$ accumulates the prefix sum up to position $i$ and $a_i$ stores the original array element.
- *Dependency structure*: Position $i$ depends on position $i-1$, creating a sequential dependency chain that naturally mirrors the recursive structure of prefix sum computation.
- *Convergence*: The algorithm reaches a fixed point in exactly $n$ iterations, where $n$ is the array length.
- *Mapping from recursion*: The recursive call $"prefixsum"(A)[i-1]$ is captured by the dependency on $p_(i-1)$, while the base case $A[0]$ is handled at position $i = 0$.
- *Preservation of input*: The original array elements $a_i$ are preserved throughout the computation, allowing $pi$ to extract the computed prefix sums while maintaining access to the input values.