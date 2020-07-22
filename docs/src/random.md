# Randomness

The elements introduced so far (clocks, events and processes) let us describe event sequences in discrete event systems (DES). In reality those sequences often show considerable randomness and come out starkly different with varying initial conditions or intervening random events.   

If we are interested in the stochastic nature of DES, we can follow Cassandras [^1] and view them as stochastic timed automata ``(\mathcal{E},\mathcal{X},\Gamma,p,p_0,G)`` where

```math
\begin{array}{rl}
  \mathcal{E} & \textrm{countable event set} \\
  \mathcal{X} & \textrm{countable state space} \\
  \Gamma(x)   & \textrm{feasible or enabled events}: x \in \mathcal{X}, \Gamma(x) \subseteq \mathcal{E} \\
  p(x';x,e')  & \textrm{state transition probability}: x,x' \in \mathcal{X}, e' \in \mathcal{E} \\
  p_0(x)      & \textrm{pmf}\ P[X_0=x]: x \in \mathcal{X}, X_o \textrm{initial state} \\
  G_i         & \textrm{stochastic clock structure}: i \in \mathcal{E}
\end{array}
```

Everything in this definition can be expressed by combining

- clock, events and processes of `DiscreteEvents`,
- Julia's [multiple dispatch](https://docs.julialang.org/en/v1/manual/methods/#Methods-1) and
- using the [`Distributions`](https://github.com/JuliaStats/Distributions.jl) package.

## Automata

The feasible event function ``\Gamma(x)`` expresses the fact that transitions are conditional on states or that in a given state ``x`` only certain events ``\Gamma(x) \subseteq \mathcal{E}`` can lead to transitions. The transition function ``\mathcal{f}:\mathcal{X}\times\mathcal{E} \rightarrow \mathcal{X}`` is only partially defined on the domain ``\mathcal{X}\times\mathcal{E}``. In stochastic systems events happen unpredictably and can lead to undefined combinations ``(x,e)``.

Julia's multiple dispatch provides a powerful way to implement the transition function ``\mathcal{f}``.

The process to do it is:

1. define the event set ``\,\mathcal{E} = \{\alpha, \beta, \gamma, ...\}``,
2. define the state space ``\,\mathcal{X}=\{x_1, x_2, ..., x_n\}``,
3. implement methods for the defined transitions ``\,\mathcal{f}(x_1, \{\alpha,\beta\}), \mathcal{f}(x_2, \gamma), ..., \mathcal{f}(x_n, \omega)``,
4. define a default transition ``\,\mathcal{f}(\mathcal{X},\mathcal{E})=\text{\O}\,`` as one method doing nothing.

Thus any undefined transitions fallback to the default transition. This eliminates the need to check for and delete previously scheduled events. Unfeasible events are simply ignored.

### A server breaks down

For example if a server `s` breaks down randomly and takes on a state `Failed`, it cannot accept previously scheduled events `Finish` or `Setup` job. If we have defined correctly the transition function `𝒇(s, Busy, Finish)` and the default transition function, the event `𝒇(s, Failed, Finish)` triggers the default transition and is simply ignored [^2]. Code example:

```julia
abstract type 𝑋 end    # define states
struct Idle <: 𝑋 end
struct Busy <: 𝑋 end
struct Failed <: 𝑋 end

abstract type 𝐸 end    # describe events
struct Setup <: 𝐸 end
struct Load <: 𝐸 end
struct Finish <: 𝐸 end
struct Fail <: 𝐸 end
struct Repair <: 𝐸 end

mutable struct Server  # state machine body
    id::Int
    c::Clock
    state::𝑋
    job::Int
end

# defined transitions
𝒇(::Server, ::𝑋, ::𝐸) = nothing   # default transition
𝒇(s::Server, ::Idle, ::Setup) = event!(s.c, fun(𝒇, s, s.state, Load()), fun(isready, queue))
function 𝒇(s::Server, ::Idle, ::Load)
    s.job = pop!(queue)
    s.state = Busy()
    event!(s.c, fun(𝒇, s, s.state, Finish()), after, rand(EX))
end
function 𝒇(s::Server, ::𝑋, ::Fail)
    s.state = Failed()
    event!(s.c, fun(𝒇, s, s.state, Repair(), after, rand(MTTR)))
end
function 𝒇(s::Server, ::Busy, ::Finish)
    pushfirst!(done, s.job)
    s.job = 0
    s.state = Idle()
    event!(s.c, fun(𝒇, s, s.state, Setup(), after, rand(EX)/5))
end
function 𝒇(s::Server, ::Failed, ::Repair)
    if s.job != 0
        s.state = Busy()
        event!(s.c, fun(𝒇, s, s.state, Finish()), after, rand(ex)) # start job anew
    else
        s.state = Idle()
        event!(s.c, fun(𝒇, s, s.state, Setup(), after, rand(EX)/5))
    end
end

...
```

## Random variables

Random initial states, transition probabilities or stochastic event times can simply be computed by calling `rand(d)` on a [distribution](https://juliastats.org/Distributions.jl/stable/types/#Distributions-1) `d` from the [`Distributions`](https://juliastats.org/Distributions.jl/stable/) package.

### Two poisson processes

In the following example we simulate two arrival processes, one homogeneous poisson process (HPP) say for a grocery store and one non-homogeneous poisson process (NHPP) where the number of arrivals diminish over time e.g. for a bakery.

```julia
using DiscreteEvents, Random, Distributions, Plots

Random.seed!(1234)    # set random number seed for reproducibility
const λ = 10          # arrival rate 10 customers per hour
const ρ = log(0.2)/10 # decay constant for customer arrivals
D = Exponential(1/λ)  # interarrival time distribution

hpp  = [0]            # counting homogeneous poisson arrivals
nhpp = [0]            # counting non-homogeneous poisson arrivals
t = Float64[]         # tracing variables
y1 = Int[]
y2 = Int[]

δ(t) = Int(rand() ≤ exp(ρ*t))   # model time dependent decay of arrivals
trace(c) = (push!(t, c.time); push!(y1, hpp[1]); push!(y2, nhpp[1]))

# define two arrival functions
#       |   count             | schedule next arrival
arr1(c) = (hpp[1] += 1;         event!(c, fun(arr1, c), after, rand(D)))
arr2(c) = (nhpp[1]+= δ(c.time); event!(c, fun(arr2, c), after, rand(D)))

# create clock, schedule events and tracing and run
c = Clock()
event!(c, fun(arr1, c), after, rand(D))  # HPP arrivals (grocery store)
event!(c, fun(arr2, c), after, rand(D))  # NHPP (bakery)
periodic!(c, fun(trace, c))
run!(c, 10)

plot(t, y1, label="grocery", xlabel="hours", ylabel="customers", legend=:topleft)
plot!(t, y2, label="bakery")
```
![poisson arrivals](img/poisson.png)

Here `δ(t)` models a time dependent probability of a state transition (customer arrival) and the calls to `rand(D)` creates stochastic time sequences ``(t_1, t_2, t_3, ...)`` of poisson processes.

[^1]:  Cassandras, Lafortune: Introduction to Discrete Event Systems, Springer, 2008, p 334 f.
[^2]: In order to be able to use the same transition function for several agents in a DES, it is convenient to include the agent (e.g. the server `S`) into the function arguments.
