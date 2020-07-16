# Events

We consider time as something given or measured by a clock. An event can then be viewed as something happening at a time instant, a change in data or a state transition.

## Actions

In order to represent an event we want to take some action at time t. An [`Action`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.Action) is an [expression](https://docs.julialang.org/en/v1/manual/metaprogramming/#Expressions-and-evaluation-1), a [function object](https://docs.julialang.org/en/v1/manual/functions/) or a [tuple](https://docs.julialang.org/en/v1/manual/functions/#Tuples-1) of them, which is executed at event time:

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

julia> (:(a+1), println) isa Action  # a tuple of expressions and function objects
true
```

Note that simple expressions like `a+1` or function calls like `println()` are not `Action`s since they get executed immediately and cannot be stored for later execution.

## Data

To execute a parameterized function at event time, we need a mechanism to store the function or expression object together with its data for later execution. For that we can use an anonymous function or we create a function closure with [`fun`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.fun):

```julia
julia> a = 1; b = 2; c = 3;         # create some data

julia> f(x, y, z) = x^y + z         # create a function
f (generic function with 1 method)

julia> ff = fun(f, a, b, c)         # create a function closure, capture the data
#8 (generic function with 1 method)

julia> ff isa Action                # this is an action
true

julia> ff()                         # which we can execute later
4
```  

### Referencing data

But in simulations most often we want our actions to be sensitive to changed data at execution time. To achieve this, we change our `ff` closure:

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

Note that you got a warning because this is not recommended.


### Modifying data

The best way to reference data is to have your actions work with mutable values (like `Array`s)[^1]. Then you can also modify your data at event time, which is what you often want:

```julia
julia> mutable struct Counter         # define a counter type
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

## Timed events

## Conditional events

see [`event!`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#Events-1)


[^1]: This is faster because you avoid type instabilities associated with [global variables](https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-global-variables-1).
