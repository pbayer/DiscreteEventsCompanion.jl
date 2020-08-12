# Actions

We consider time as given or measured by a clock ``C``. Furthermore we characterize a discrete event system (DES) by

```math
\begin{array}{lll}
  \mathcal{X}&=\{x_i, x_j, ..., x_n\} & \textrm{a discrete set of states}, \\
  \mathcal{E}&=\{\alpha, \beta, \gamma, ...\} & \textrm{a countable set of events eventually causing state transitions}
\end{array}
```

In an observed event sequence ``\,\{e_1, e_2, e_3, ...\}\,`` each event ``\;e_i \in \mathcal{E}\;`` is associated with a time ``\,t_i`` [^1]. We can write that as a sequence of tuples:

```math
\{(e_1,t_1),(e_2,t_2),(e_3,t_3),\hspace{1em}...\hspace{1em}, (e_n,t_n)\}
```

In `DiscreteEvents` we want to represent an event always as that tuple ``\,(e_i,t_i)\,``. For representing ``\,e_i\,`` computationally, we introduce the term *action* [^2]. An [`Action`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.Action) is a Julia [expression](https://docs.julialang.org/en/v1/manual/metaprogramming/#Expressions-and-evaluation-1), a [function](https://docs.julialang.org/en/v1/manual/functions/) object or a [tuple](https://docs.julialang.org/en/v1/manual/functions/#Tuples-1) of them, which will be executed at a given time:

```julia
julia> using DiscreteEvents

julia> :(a+1) isa Action     # :(a+1) can be executed later
true

julia> println isa Action    # a function object can be called later
true

julia> ()->println()         # we create an anyonymous function
#23 (generic function with 1 method)

julia> ans isa Action        # this too is an action
true

julia> (:(a+1), println) isa Action  # a tuple of actions too is an action
true
```

Simple expressions like `a+1` or function calls like `println()` are not `Action`s since they get executed immediately and cannot be stored for later execution.

!!! note "Use functions!"

    Use functions instead of expressions because it is much faster. If you use expressions, you will get a one-time warning.

## Data

Actions (expressions and functions) have access to data within their scope, but often we want to pass the data to functions as arguments. We can use [`fun`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.fun) to create an executable closure object, containing the function with its arguments:

```julia
julia> a = 1; b = 2; c = 3;         # create some global data

julia> f(x, y, z) = x^y + z         # define a function
f (generic function with 1 method)

julia> ff = fun(f, a, b, c)         # create a function closure with captured data
#8 (generic function with 1 method)

julia> ff isa Action                # this is an action
true

julia> ff()                         # which we can execute later
4
```  

## Current data

In simulations most often we want our actions at execution time to get the current data. To achieve this, we change our `ff` closure:

```julia
julia> ff = fun(f, ()->a, ()->b, ()->c)  # capture the data at execution time
#8 (generic function with 1 method)

julia> ff()                         # execute the closure
4

julia> a = 2                        # change one of the data values
2

julia> ff()                         # ff now captures the changed data
7
```

Another way is to pass the data symbolically to the function closure:

```julia
julia> ff = fun(f, :a, :b, :c)
#8 (generic function with 1 method)

julia> ff()
┌ Warning: Evaluating expressions is slow, use functions instead
└ @ DiscreteEvents ~/.julia/packages/DiscreteEvents/vyBMT/src/fclosure.jl:37
7

julia> a = 3
3

julia> ff()
12
```

Note that you got a warning because this is slow and not recommended.

## Modifying data

The best way to reference data, is to have your actions work with mutable values (like `Array`s)[^3]. Then you can also modify your data in an action, which is what you often want:

```julia
julia> mutable struct Counter       # define a counter type
           x::Int
       end

julia> cc = Counter(0)                # setup a counter
Counter(0)

julia> g(ctr::Counter) = ctr.x += 1   # a function to increment a counter
g (generic function with 1 method)

julia> gg = fun(g, cc)                # put it in a closure with a counter variable
#8 (generic function with 1 method)

julia> gg()                           # execute it
1

julia> cc                             # the counter variable has increased
Counter(1)
```

[^1]: We follow Cassandras: Discrete Event Systems, 2008, p. 27 and don't attempt to define what an "event" is. "We only wish to emphasize that an event should be thought of as occurring instantaneously and eventually causing transitions from one state value to another."
[^2]: This means simply a computational action. It does not have to be a state transition of the represented system. It could be also a check if an event is feasible.
[^3]: This is faster because you avoid type instabilities associated with [global variables](https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-global-variables-1).
