#import "../lib/style.typ": *
#import "../lib/mapcode.typ": *

== Sum of Digits
#set math.equation(numbering: none)

Compute the sum of digits of a positive integer $n$. i.e $n in NN, n > 0$

Formal definition:
$
"digitsum"(n) = sum_(i=0)^(d-1) floor(n / 10^i) mod 10
$
where $d$ is the number of digits in $n$.

Equivalently (recursive):
$
"digitsum"(n) = cases(
  n & "if" n < 10,
  (n mod 10) + "digitsum"(floor(n / 10)) & "if" n >= 10
)
$

Examples:
- $"digitsum"(123) -> 6$ (since $1 + 2 + 3 = 6$)
- $"digitsum"(5) -> 5$
- $"digitsum"(8296) -> 25$ (since $8 + 2 + 9 + 6 = 25$)

*As mapcode:*

_primitives_: 
- `div`($\/$): integer division (quotient)
- `mod`($mod$): modulo operation (remainder)
- `add`($+$): addition
- `numdigits`: returns number of digits in a number

These operations on $bot$ are undefined (strict).

$ 
I = NN quad quad quad X_n &= [0..d-1] -> (NN_bot times NN) quad quad quad A = NN
$

where $d = "numdigits"(n)$

$
rho(n) & = {i -> (bot, n) | i in [0..d-1]}\
F(x_n equiv (a_i, r_i))(i) & = cases(
  (a_i, r_i) & "if " a_i != bot,
  (r_i mod 10, floor(r_i / 10)) & "if " a_i = bot "and" i = 0,
  (a_(i-1) + (r_(i-1) mod 10), floor(r_(i-1) / 10)) & "if " a_i = bot "and" i > 0 "and" a_(i-1) != bot,
  (a_i, floor(r_i / 10)) & "if " a_i = bot "and" i > 0 "and" a_(i-1) = bot
)\
pi(x) & = a_(d-1)
$

where $x_i = (a_i, r_i)$ represents a pair of (accumulated sum, remaining number).

#let inst = 8296;
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
    pi_name: [$pi$],
    group-size: calc.min(7, d),
    cell-size: 15mm, scale-fig: 85%
  )(inst)
}
$
)