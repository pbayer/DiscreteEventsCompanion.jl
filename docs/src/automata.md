# State Machines

In DES usually a lot of events happen, but not all of them cause state transitions. On the other hand some events cause a system to change its path. If event sequences ...

```math
\{(e_1,t_1),(e_2,t_2),(e_3,t_3),\hspace{1em}...\hspace{1em}, (e_n,t_n)\}
```

are not predictable and can change stochastically, the system behavior can be expressed as a [finite state machine](https://en.wikipedia.org/wiki/Finite-state_machine). In our [stochastic timed automaton](DES.md) ``\,(\mathcal{E},\mathcal{X},\Gamma,p,p_0,G)\,`` the feasible event function ``\,\Gamma(x) : x \in \mathcal{X},\,\Gamma(x) \subseteq \mathcal{E}\,`` is the set of all events ``e`` for which a transition function ``\mathcal{f}(x,e)`` is defined. Given the current state of the system other events can happen, but are unfeasible.

## The transition function

``\mathcal{f}:\mathcal{X}\times\mathcal{E} \rightarrow \mathcal{X}`` describes the transitions in the system and is only partially defined on its domain. Julia's [multiple dispatch](https://docs.julialang.org/en/v1/manual/methods/#Methods-1) allows to implement it as different methods of one function:

1. define the event set ``\,\mathcal{E} = \{\alpha, \beta, \gamma, ...\}``,
2. define the state space ``\,\mathcal{X}=\{x_1, x_2, ..., x_n\}``,
3. implement methods for the defined transitions ``\,\mathcal{f}(x_1, \{\alpha,\beta\}), \mathcal{f}(x_2, \gamma), ..., \mathcal{f}(x_n, \omega)``,
4. define a default transition ``\,\mathcal{f}(x,\mathcal{E})=x\,``.

Defined transitions call one of the defined methods and undefined transitions fall back to the default transition.

## An example

We have to model a system where servers break down from time to time. First we implement the states and the events occurring in the system and a server type:

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
```

Then we implement the transition function as `f!(s,x,e)` [^1] with `s` for the server instance and different methods for all defined ``(x,e)\rightarrow x'`` transitions and a default transition. This enables us to dispatch on them:

```julia
𝒇!(::Server, ::𝑋, ::𝐸) = nothing   # default transition
𝒇!(s::Server, ::Idle, ::Setup) =   # a setup event for an idle machine
    event!(s.c, fun(𝒇!, s, s.state, Load()), fun(isready, queue))
function 𝒇!(s::Server, ::Idle, ::Load) # a load event for an idle machine
    s.job = pop!(queue)
    s.state = Busy()
    event!(s.c, fun(𝒇!, s, s.state, Finish()), after, rand(EX))
end
function 𝒇!(s::Server, ::Union{Idle,Busy}, ::Fail) # a fail event for idle and busy machines
    s.state = Failed()
    event!(s.c, fun(𝒇!, s, s.state, Repair(), after, rand(MTTR)))
end
function 𝒇!(s::Server, ::Busy, ::Finish) # a finish event for a busy machine
    pushfirst!(done, s.job)
    s.job = 0
    s.state = Idle()
    event!(s.c, fun(𝒇!, s, s.state, Setup(), after, rand(EX)/5))
end
function 𝒇!(s::Server, ::Failed, ::Repair) # a repair event for a failed machine
    if s.job != 0
        s.state = Busy()
        event!(s.c, fun(𝒇!, s, s.state, Finish()), after, rand(EX)) # start job anew
    else
        s.state = Idle()
        event!(s.c, fun(𝒇!, s, s.state, Setup(), after, rand(EX)/5))
    end
end
```

Out of 15 possible state-event combinations only six are defined. All others are ignored and let the current state unchanged:

|  *X × E*     | Setup | Load | Finish | Fail   | Repair    |
|-------------:|:-----:|:----:|:------:|:------:|:---------:|
| ⭑ → **Idle** | Idle  | Busy |   -    | Failed |    -      |
| **Busy**     |   -   |  -   | Idle   | Failed |    -      |
| **Failed**   |   -   |  -   |   -    |   -     | Idle/Busy |

If a `Busy` server gets a `Fail` event, it becomes `Failed` and cannot accept the previously scheduled `Finish` event. This is only defined for a `Busy` server and the undefined event `𝒇!(s,Failed,Finish)` triggers the default transition. The server will get `Busy` again when a `Repair` event arrives and then schedule a new `Finish` event.

## A system of state machines

By creating several server instances we can represent different entities of state machines in the system. This is shown in the [multi-server example](examples/multiserver.md).

A more elegant and dynamic way is to work with actors: By changing their behavior they can express state machines natively, they can have state machines as behaviors, they can create new actors dynamically ...

[^1]: Here we include the server `s` as function argument. But then - since we change its state - it is [Julia convention](https://docs.julialang.org/en/v1/base/punctuation/) to add an exclamation mark to the function name `f!`.
