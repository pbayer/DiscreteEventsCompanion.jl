# Events

We consider time as given or measured by a clock. An event can then be viewed as something happening at a time instant, a change in data or a state transition. In order to represent an event we want to take some action at time `t`.

## Actions

An [`Action`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.Action) is an [expression](https://docs.julialang.org/en/v1/manual/metaprogramming/#Expressions-and-evaluation-1), a [function](https://docs.julialang.org/en/v1/manual/functions/) object or a [tuple](https://docs.julialang.org/en/v1/manual/functions/#Tuples-1) of them, which will be executed at that time:

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

!!! note

    It is preferable to use functions instead of expressions because it is so much faster. If you use expressions you will get a one-time warning.

## Data

Actions (expressions and functions) have access to data within their scope but often we want to pass the data to functions as arguments. Then we can use [`fun`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.fun) to create an executable closure object, containing the function with its arguments:

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

### Current data

But in simulations most often we want our actions at execution time to get the current data. To achieve this, we change our `ff` closure:

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

## Scheduling

Scheduling introduces a time delay between the definition of an event and its execution. *Timed events* are actions scheduled at a given time. *Conditional events* are actions scheduled until a given condition becomes true. Events can be scheduled on a clock before or during it is running. But they are executed only by a running clock at their due time.

### Timed events

With a clock `G`, an action `γᵢ` and a known event time `t` we can schedule timed events:

- `event!(G, γᵢ, t)` or `event!(G, γᵢ, at, t)`: `G` executes `γᵢ` **at** time `t`,
- `event!(G, γᵢ, after, Δt)`: `G` executes `γᵢ` **after** a time interval `Δt`,
- `event!(G, γᵢ, every, Δt)`: `G` executes `γᵢ` **every** time interval `Δt`.

```julia
using DiscreteEvents, Plots

c = Clock()
a = [0]                                                       # a counting variable
x = Float64[]; ya = Float64[]                                 # tracing variables

event!(c, ()->a[1]+=1, 1)                                     # increment a[1] at t=1
event!(c, ()->a[1]=4, after, 5)                               # set a[1]=4 after Δt=5
event!(c, fun(event!, c, ()->a[1]+=1, every, 1), at, 5)       # starting at t=5 trigger a repeating event
event!(c, ()->(push!(x,tau(c)); push!(y, a[1])), every, 0.01) # trace t and a[1] every Δt=0.01

run!(c, 10.1)
plot(x, y, linetype=:steppost, xlabel="t", ylabel="a", legend=false)
```

![timed events](img/tev.png)

### Conditional events

With a conditional event: `event!(G, γⱼ, γᵩ)` the clock `G` executes the pseudo action `γᵩ` at its sample rate `Δt`. `γᵩ` must check for event conditions. As soon as it returns `true`, the clock executes `γⱼ`. If `γᵩ` is a tuple of actions, all of them must return `true` to trigger the execution of `γⱼ`.

```julia
c = Clock()
a = [0.0]; b = [0]
x = Float64[]; ya = Float64[]; yb = Float64[]

event!(c, ()->a[1]=tau(c)^2, every, 0.1)            # calculate a[1]=t^2 every Δt=0.1
event!(c, ()->b[1]=25, ()->a[1]≈25)                 # set b[1]=25 if a[1]≈25
event!(c, ()->(push!(x,tau(c)); push!(ya,a[1]); push!(yb,b[1])), every, 0.01) # trace t, a[1], b[1],

run!(c, 10)
plot(x, ya, xlabel="t", ylabel="y", label="a", legend=:topleft)
plot!(x, yb, label="b")
```

![conditional event](img/cev.png)

A conditional event introduces a time uncertainty ≤ Δt into simulations caused by the clock sample rate `Δt`.

see [`event!`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#Events-1)


[^1]: This is faster because you avoid type instabilities associated with [global variables](https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-global-variables-1).
