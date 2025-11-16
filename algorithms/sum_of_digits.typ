#import "../lib/style.typ": *
#import "../lib/mapcode.typ": *

#set math.equation(numbering: none)

== Description of the problem and example input outputs

Compute the sum of digits of a positive integer $n$. i.e $n in NN, n > 0$

Formal definition:
$
"digitsum"(n) = sum_(i=0)^(d-1) floor(n / 10^i) mod 10
$
where $d$ is the number of digits in $n$.

Examples:
- $"digitsum"(123) -> 6$ (since $1 + 2 + 3 = 6$)
- $"digitsum"(5) -> 5$
- $"digitsum"(8296) -> 25$ (since $8 + 2 + 9 + 6 = 25$)

== Recursive Solution (without mapcode)

Recursive formulation:
$
"digitsum"(n) = cases(
  n & "if" n < 10,
  (n mod 10) + "digitsum"(floor(n / 10)) & "if" n >= 10
)
$

This recursion satisfies the non-triviality requirement because:
- Each recursive call operates on a strictly smaller substructure: $floor(n / 10)$ has fewer digits than $n$.
- The function makes a single recursive call on $floor(n / 10)$, combined with a base case when $n < 10$.
- The recursion depth equals the number of digits $d$ in $n$.

== Mapcode
=== Primitives

Data type and domain → range:
- Domain: $NN$ (positive integers)
- Range: $NN$ (sum of digits)

Primitives used:
- `div`($\/$): integer division (quotient), $NN times NN -> NN$
- `mod`($mod$): modulo operation (remainder), $NN times NN -> NN$
- `add`($+$): addition, $NN times NN -> NN$
- `numdigits`: returns number of digits in a number, $NN -> NN$

These operations on $bot$ are undefined (strict).

=== Maps and spaces

Mapcode components:

$ 
I = NN quad quad quad X_n &= [0..d-1] -> (NN_bot times NN) quad quad quad A = NN
$

where $d = "numdigits"(n)$

*Initialization* $rho: I -> X_n$:
$
rho(n) & = {i -> (bot, n) | i in [0..d-1]}
$

*Update function* $F: X_n -> X_n$:
$
F(x_n equiv (a_i, r_i))(i) & = cases(
  (a_i, r_i) & "if " a_i != bot,
  (r_i mod 10, floor(r_i / 10)) & "if " a_i = bot "and" i = 0,
  (a_(i-1) + (r_i mod 10), floor(r_i / 10)) & "if " a_i = bot "and" i > 0 "and" a_(i-1) != bot,
  (a_i, floor(r_i / 10)) & "if " a_i = bot "and" i > 0 "and" a_(i-1) = bot
)
$

*Output function* $pi: X_n -> A$:
$
pi(x equiv (a, r)) & = a
$

where $x_i = (a_i, r_i)$ represents a pair of (accumulated sum, remaining number).

=== Trace

The trace visualization below demonstrates convergence to a fixed point through iterative application of $F$. Each iteration computes one more digit's contribution to the sum, showing how $x in X$ converges from the initial state $rho(n)$ to a fixed point where all accumulator values are computed.

F direction below is reversed but that is a Typst error.

#let inst = 829632;
#figure(
  caption: [Sum of digits computation using mapcode for $n = #inst$],
$
#{
  let num_digits = (n) => {
    if n == 0 { return 1 }
    let count = 0
    while n > 0 {
      count += 1
      n = calc.quo(n, 10)
    }
    count
  }

  let rho = (inst) => {
    let d = num_digits(inst)
    let x = ()
    for i in range(0, d) {
      x.push((none, inst))
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
        (calc.rem(curr.at(1), 10), calc.quo(curr.at(1), 10))
      } else {
        let prev = x.at(i - 1)
        if prev.at(0) != none {
          (prev.at(0) + calc.rem(prev.at(1), 10), calc.quo(prev.at(1), 10))
        } else {
          (curr.at(0), calc.quo(curr.at(1), 10))
        }
      }
    }
  }
  let F = map_tensor(F_i, dim: 1)

  let pi = (i) => (x) => x.at(i).at(0)

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

  let d = num_digits(inst)
  mapcode-viz(
    rho, F, pi(d - 1),
    X_h: X_h,
    pi_name: [$mpi$],
    group-size: calc.min(7, d),
    cell-size: 15mm, scale-fig: 70%
  )(inst)
}
$
)

The trace shows at least 5 iterations (for $n = 829632$, we have $d = 6$ digits, requiring 6 iterations to reach the fixed point). The final result $a_5 = 30$ matches the known mathematical result: $8 + 2 + 9 + 6 + 3 + 2 = 30$.

=== Correctness
Intuitively, at each iteration, the map $F$ computes the contribution of one more digit to the accumulated sum in the appropriate position. After $d$ iterations, all digits have been processed, and the accumulator at position $d-1$ contains the total sum of digits.

=== Implementation notes

Key design decisions:
- *State representation*: Each position $i in [0..d-1]$ maintains a pair $(a_i, r_i)$ where $a_i$ accumulates the partial sum and $r_i$ tracks the remaining number to process.
- *Dependency structure*: Position $i$ depends on position $i-1$, creating a sequential dependency chain that naturally mirrors the recursive structure.
- *Convergence*: The algorithm reaches a fixed point in exactly $d$ iterations, where $d$ is the number of digits in $n$.
- *Mapping from recursion*: The recursive call $"digitsum"(floor(n / 10))$ is captured by the dependency on $a_(i-1)$, while the base case $(n mod 10)$ is computed at each position.
- What is important is that *$i/(10^i)$ is not explicitly represented*; instead, the map F implicitly handles the positional value through these operations.