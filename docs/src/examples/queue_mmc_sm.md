# M/M/c with State Machines

Here we implement a simple state machine as an actor. An *actor* is a task listening to an event channel. It has an internal state and reacts accordingly to the events. Here we did a native actor implementation without any libraries.

As before with state machines we define first *states* and *events* and a *state machine body*:

```julia
using DiscreteEvents, Printf, Distributions, Random

abstract type 𝑋 end    # define states
struct Idle <: 𝑋 end
struct Busy <: 𝑋 end

abstract type 𝐸 end    # events
struct Arrive <: 𝐸 end
struct Finish <: 𝐸 end

mutable struct Server  # state machine body
    id::Int
    clk::Clock
    com::Channel       # this is the actor's communication channel
    input::Channel
    output::Channel
    state::𝑋
    job::Int
    d::Distribution
end
```

Then we implement the transition functions and the actor loop running them:

```julia
act!(::Server, ::𝑋, ::𝐸) = nothing   # a default transition
function act!(s::Server, ::Idle, ::Arrive)
    if isready(s.input)
        s.job = take!(s.input)
        s.state = Busy()
        event!(s.clk, fun(put!, s.com, Finish()), after, s.d)
        print(s.clk, @sprintf("%5.3f: server %d serving customer %d\n", tau(s.clk), s.id, s.job))
    end
end
function act!(s::Server, ::Busy, ::Finish)
    s.state = Idle()
    put!(s.output, s.job)
    print(s.clk, @sprintf("%5.3f: server %d finished serving %d\n", tau(s.clk), s.id, s.job))
end
function act!(s::Server)  # a simple actor loop, take something
    while true            # from the com channel and act! on it
        act!(s, s.state, take!(s.com))
    end
end
```

The `arrive` function sends an `Arrive()` event to the server actors over their `com` channels:

```julia
function arrive(c::Clock, input::Channel, jobno::Vector{Int}, srv::Vector{Server})
    jobno[1] += 1
    @printf("%5.3f: customer %d arrived\n", tau(c), jobno[1])
    put!(input, jobno[1])
    map(s->put!(s.com, Arrive()), srv) # notify the servers
end
```

We setup our global constants, the simulation environment, the actors and the arrivals process and run:

```julia
Random.seed!(8710)          # set random number seed for reproducibility
const N = 10                # total number of customers
const c = 2                 # number of servers
const μ = 1.0 / c           # service rate
const λ = 0.9               # arrival rate
const M₁ = Exponential(1/λ) # interarrival time distribution
const M₂ = Exponential(1/μ) # service time distribution

# initialize simulation environment
clock = Clock()
input = Channel{Int}(Inf)
output = Channel{Int}(Inf)
srv = Server[]
for i in 1:c   # start servers/actors
    push!(srv, Server(i, clock, Channel{𝐸}(32), input, output, Idle(), 0, M₂))
    push!(clock.channels, srv[i].com)  # register the actor channel to the clock
    yield(@task act!(srv[i]))          # let the actor task start
end
event!(clock, fun(arrive, clock, input, jobno, srv), every, M₁, n=N)
run!(clock, 20)
```

Note that we registered the actor `com` channel to the clock in order to avoid [clock concurrency](@ref clock_concurrency).

Then we get our usual output:

```julia
0.123: customer 1 arrived
0.123: server 1 serving customer 1
0.226: customer 2 arrived
0.226: server 2 serving customer 2
0.539: server 1 finished serving 1
0.667: server 2 finished serving 2
2.135: customer 3 arrived
....
10.027: server 1 finished serving 8
10.257: customer 10 arrived
10.257: server 1 serving customer 10
10.624: server 1 finished serving 10
10.734: server 2 finished serving 9
"run! finished with 50 clock events, 0 sample steps, simulation time: 20.0"
```

The state machine setup seems more complicated than for processes but this disadvantage goes away for more complicated situations.
