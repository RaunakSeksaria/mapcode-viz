#import "../lib/style.typ": *
#import "../lib/mapcode.typ": *

#set math.equation(numbering: none)

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
- $n = 1: A_1 = 2, B_1 = 2$
- $n = 2: A_2 = 5, B_2 = 4$
- $n = 3: A_3 = 8, B_3 = 7$
- $n = 5: A_5 = 14, B_5 = 16$

*As mapcode:*

_primitives_: 
- `add`($+$): addition

Addition on $bot$ is undefined (strict).

$ 
I = NN_0 quad quad quad X_n &= [0..n] -> (NN_(0,bot) times NN_(0,bot)) quad quad quad A = NN_0 times NN_0
$

$
rho(n) & = {k -> (bot, bot) | k in [0..n]}\
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
)\
pi(x equiv (A_k, B_k)) & = (A_n, B_n)
$

where $(A_k, B_k)$ represents a pair of values from the two mutually recursive sequences at position $k$.

Note: The function $F$ updates both components independently based on their dependencies, with $A_k$ depending on $B_(k-1)$ and $B_k$ depending on $A_(k-1)$.

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
    pi_name: [$pi$],
    group-size: calc.min(7, inst + 1),
    cell-size: 15mm, scale-fig: 85%
  )(inst)
  
}
$
)