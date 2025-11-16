#import "@preview/arkheion:0.1.1": arkheion, arkheion-appendices

#show: arkheion.with(
  title: "Mapcode : Recursion Modeling",
  authors: (
    (name: "Raunak Seksaria (2023113019)", email: "raunak.seksaria@research.iiit.ac.in", affiliation: "IIIT Hyderabad"),
  ),
  abstract: [
    Recursion modeling in the `mapcode` framework for A5 of course Principles of Programming Languages (POPL) 2025 at IIIT Hyderabad.
  ],
  keywords: ("Mapcode", "Recursion", "Programming"),
  date: datetime.today().display()
)


#import "lib/style.typ": *

#set math.equation(numbering:none)

= Algorithms Chosen
1. Sum of Digits of a positive number
2. Prefix Sum of an integer array
3. Mutual Recursion (Custom two sequence-coupled equations)
4. Connected Components in an undirected graph

= Notations and Conventions

A vector is (zero-)indexed as follows that has size $n+1$:
$ vec(x_0, dots.v, x_n,
   delim: "["
  )_(n+1)
$

A matrix is also (zero-)indexed as follows that has size $m times n$:
$ mat(
    delim: "[",
    x_(0,0), x_(0,1), dots, x_(0,n-1);
    x_(1,0), x_(1,1), dots, x_(1,n-1);
    dots, dots, dots, dots;
    x_(m-1,0), x_(m-1,1), dots, x_(m-1,n-1)
  )_(m times n)
$

All primitives are _strict_ meaning they do not allow for undefined values (i.e., $bot$) to be used in their computations.

#pagebreak()

= Algorithm 1: Sum of Digits of a positive number

#include "algorithms/sum_of_digits.typ"
#pagebreak()
= Algorithm 2: Prefix Sum of an integer array
#include "algorithms/prefix_sum.typ"
#pagebreak()
= Algorithm 3: Mutual Recursion (Custom two sequence-coupled equations)
#include "algorithms/mutual_recursion.typ"
#pagebreak()
= Algorithm 4: Connected Components in an undirected graph
#include "algorithms/connected_components.typ"
