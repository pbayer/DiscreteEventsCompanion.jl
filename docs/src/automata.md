# Automata

Automata are also called state machines or the state-based approach to simulation.

In the definition of a [stochastic timed automaton](DES.md) ``\Gamma(x)`` expresses the fact that transitions are conditional on states or that in a given state ``x`` only certain events ``\Gamma(x) \subseteq \mathcal{E}`` cause a transition. The transition function ``\mathcal{f}:\mathcal{X}\times\mathcal{E} \rightarrow \mathcal{X}`` therefore is only partially defined on its domain. In stochastic systems event sequences change unpredictably and can lead to undefined combinations ``(x,e)`` that must be handled somehow.


Julia's [multiple dispatch](https://docs.julialang.org/en/v1/manual/methods/#Methods-1) provides a powerful way to implement the transition function ``\mathcal{f}``:

1. define the event set ``\,\mathcal{E} = \{\alpha, \beta, \gamma, ...\}``,
2. define the state space ``\,\mathcal{X}=\{x_1, x_2, ..., x_n\}``,
3. implement methods for the defined transitions ``\,\mathcal{f}(x_1, \{\alpha,\beta\}), \mathcal{f}(x_2, \gamma), ..., \mathcal{f}(x_n, \omega)``,
4. define a default transition ``\,\mathcal{f}(\mathcal{X},\mathcal{E})=\text{\O}\,``.

Defined transitions call one of the defined methods and undefined transitions fallback to the default transition. This eliminates the need to check for and delete previously scheduled events. Unfeasible events are simply ignored.

### A server breaks down

If a server `s` breaks down randomly, it has state `Failed` and cannot accept previously scheduled events `Finish` or `Setup` (a job). With correctly defined  transition functions `𝒇!(s,Busy,Finish)` and `𝒇!(s,𝑋,𝐸) = ∅`, the event `𝒇!(s,Failed,Finish)` triggers `nothing` [^1]. Code example:

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
𝒇!(::Server, ::𝑋, ::𝐸) = nothing   # default transition
𝒇!(s::Server, ::Idle, ::Setup) = event!(s.c, fun(𝒇!, s, s.state, Load()), fun(isready, queue))
function 𝒇!(s::Server, ::Idle, ::Load)
    s.job = pop!(queue)
    s.state = Busy()
    event!(s.c, fun(𝒇!, s, s.state, Finish()), after, rand(EX))
end
function 𝒇!(s::Server, ::𝑋, ::Fail)
    s.state = Failed()
    event!(s.c, fun(𝒇!, s, s.state, Repair(), after, rand(MTTR)))
end
function 𝒇!(s::Server, ::Busy, ::Finish)
    pushfirst!(done, s.job)
    s.job = 0
    s.state = Idle()
    event!(s.c, fun(𝒇!, s, s.state, Setup(), after, rand(EX)/5))
end
function 𝒇!(s::Server, ::Failed, ::Repair)
    if s.job != 0
        s.state = Busy()
        event!(s.c, fun(𝒇!, s, s.state, Finish()), after, rand(ex)) # start job anew
    else
        s.state = Idle()
        event!(s.c, fun(𝒇!, s, s.state, Setup(), after, rand(EX)/5))
    end
end

...
```

[^1]: Here we include the server `s` as function argument. But then - since we change the argument - it is Julia convention to add an exclamation point (`!`) to the function name.
