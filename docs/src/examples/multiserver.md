# Multi-Server State-based

Events can be expressed as state transitions ``\mathcal{f}(x, \gamma)`` with ``x \in \mathcal{X},\ \gamma \in \Gamma(x)`` of finite automata. The following example models 8 servers as state machines serving a queue of jobs:

```julia
using DiscreteEvents, Printf, Random, Distributions

const p = 0.3

abstract type 𝑋 end    # define states
struct Idle <: 𝑋 end
struct Busy <: 𝑋 end

abstract type 𝐸 end    # events
struct Load <: 𝐸 end
struct Release <: 𝐸 end
struct Setup <: 𝐸 end

mutable struct Server  # state machine body
    id::Int
    c::Clock
    state::𝑋
    job::Int
end

ex = Exponential()
queue = Vector{Int}()
done  = Vector{Int}()
Base.isready(x::Array) = !isempty(x)

# transition functions
function 𝒇!(A::Server, ::Idle, ::Load)
    A.job = pop!(queue)
    A.state = Busy()
    @printf("%5.2f: server %d took job %d\n", tau(A.c), A.id, A.job)
    event!(A.c, fun(𝒇!, A, A.state, Release()), after, rand(ex))
end

function 𝒇!(A::Server, ::Busy, ::Release)
    if rand() > p
        push!(queue, A.job)
    else
        pushfirst!(done, A.job)
        @printf("%5.2f: server %d finished job %d\n", tau(A.c), A.id, A.job)
    end
    A.job = 0
    A.state=Idle()
    event!(A.c, fun(𝒇!, A, A.state, Setup()), after, rand(ex)/5)
end

𝒇!(A::Server, ::Idle, ::Setup) = event!(A.c, fun(𝒇!, A, A.state, Load()), fun(isready, queue))
𝒇!(A::Server, 𝑥::𝑋, γ::𝐸) = println(stderr, "$(A.name) $(A.id) undefined transition $𝑥, $γ")

# model arrivals
function arrive(clk::Clock, job)
    pushfirst!(queue, job)
    event!(clk, fun(arrive, clk, job+1), after, rand(ex))
end

# setup simulation environment and run simulation
Random.seed!(123)
c = Clock()
A = [Server(i, c, Idle(), 0) for i ∈ 1:8]
for i ∈ shuffle(1:8)
    event!(c, fun(𝒇!, A[i], A[i].state, Load()), fun(isready, queue))
end
event!(c, fun(arrive, c, 1), after, rand(ex))
run!(c, 10)
```

```
0.12: server 4 took job 1
0.41: server 6 took job 2
0.60: server 4 finished job 1
0.68: server 6 finished job 2
1.68: server 1 took job 3
...
9.13: server 2 took job 5
9.28: server 3 finished job 3
9.92: server 5 took job 9
9.95: server 2 finished job 5
"run! finished with 58 clock events, 1001 sample steps, simulation time: 10.0"
```

Note that we modeled the arrivals "event-based" (without considering any state).
