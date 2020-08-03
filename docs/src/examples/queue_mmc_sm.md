# M/M/c with State Machines

Here we implement simple state machine as actors. As seen before we define first the states and events and a state machine body:

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

Then we implement the state transition function and the actor loop running it:

```julia
act!(::Server, ::𝑋, ::𝐸) = nothing   # a default transition
function act!(s::Server, ::Idle, ::Arrive)
    if isready(s.input)
        s.job = take!(s.input)
        s.state = Busy()       # note that we must yield↓↓ to the actor here
        event!(s.clk, (fun(put!, s.com, Finish()), yield), after, rand(s.d))
        now!(s.clk, ()->@printf("%5.3f: server %d serving customer %d\n", tau(s.clk), s.id, s.job))
    end
end
function act!(s::Server, ::Busy, ::Finish)
    s.state = Idle()
    put!(s.output, s.job)
    now!(s.clk, ()->@printf("%5.3f: server %d finished serving %d\n", tau(s.clk), s.id, s.job))
end
function act!(s::Server)  # actor loop, take something
    while true            # from the com channel and act! on it
        act!(s, s.state, take!(s.com))
    end
end
```

We need also our arrival process. It communicates arrivals over the servers' com channels.

```julia
function arrivals(clk::Clock, queue::Channel, srv::Vector{Server}, num_customers::Int, arrival_dist::Distribution)
    for i = 1:num_customers # initialize customers
        delay!(clk, rand(arrival_dist))
        put!(queue, i)
        now!(clk, ()->@printf("%5.3f: customer %d arrived\n", tau(clk), i))
        map(s->put!(s.com,Arrive()), srv) # notify the servers
    end
end
```

Then we setup our global constants, the simulation environment, the actors and the arrivals process and run:

```julia
Random.seed!(8710)   # set random number seed for reproducibility
const num_customers = 10   # total number of customers generated
const num_servers = 2      # number of servers
const μ = 1.0 / 2          # service rate
const λ = 0.9              # arrival rate
const arrival_dist = Exponential(1/λ)  # interarrival time distriubtion
const service_dist = Exponential(1/μ); # service time distribution

# initialize simulation environment
clock = Clock()
input = Channel{Int}(Inf)
output = Channel{Int}(Inf)
for i in 1:num_servers   # start actors
    s = Server(i, clock, Channel{𝐸}(32), input, output, Idle(), 0, service_dist)
    yield(@task act!(s)) # we yield immediately to the actor task
end
process!(clock, Prc(0, arrivals, input, srv, num_customers, arrival_dist), 1)

run!(clock, 20)
```

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
