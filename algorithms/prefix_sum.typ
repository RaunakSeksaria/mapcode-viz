#import "../lib/style.typ": *
#import "../lib/mapcode.typ": *

== Prefix Sum
#set math.equation(numbering: none)

Compute the prefix sum of an array of integers. Given an array $A = [a_0, a_1, ..., a_(n-1)]$, compute the prefix sum array where each element is the sum of all elements up to that position.

Formal definition:
$
"prefixsum"(A)[i] = sum_(j=0)^(i) A[j]
$

Equivalently (recursive):
$
"prefixsum"(A)[i] = cases(
  A[0] & "if" i = 0,
  "prefixsum"(A)[i-1] + A[i] & "if" i > 0
)
$

Examples:
- $"prefixsum"([1, 2, 3, 4]) -> [1, 3, 6, 10]$
- $"prefixsum"([5, -2, 3]) -> [5, 3, 6]$
- $"prefixsum"([10]) -> [10]$

*As mapcode:*

_primitives_: 
- `add`($+$): addition
- `size`: returns the length of an array

Addition on $bot$ is undefined (strict).

$ 
I = NN times ZZ^* quad quad quad X_n &= [0..n-1] -> (ZZ_bot times ZZ) quad quad quad A = ZZ^n
$

where $n = |A|$ is the size of the input array.

$
rho(n, A) & = {i -> (bot, A[i]) | i in [0..n-1]}\
F(x_n equiv (p_i, a_i))(i) & = cases(
  (p_i, a_i) & "if " p_i != bot,
  (a_i, a_i) & "if " p_i = bot "and" i = 0,
  (p_(i-1) + a_i, a_i) & "if " p_i = bot "and" i > 0 "and" p_(i-1) != bot,
  (bot, a_i) & "if " p_i = bot "and" i > 0 "and" p_(i-1) = bot
)\
pi(x equiv (p_i, a_i)) & = [p_0, p_1, ..., p_(n-1)]
$

where $(p_i, a_i)$ represents a pair of (prefix sum, array element).

#let inst = (1, 2, 3, 4, 5);
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
    pi_name: [$mpi $],
    group-size: calc.min(7, inst.len()),
    cell-size: 15mm, scale-fig: 85%
  )(inst)
}
$
)