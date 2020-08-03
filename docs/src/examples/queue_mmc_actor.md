# M/M/c with Actors

Very similar to the last implementation we can implement the servers as [`YAActL`](https://github.com/pbayer/YAActL.jl) actors. First we have to define the actor messages, the server body and a convenience function for sending a delayed message to ourselves.

```julia
using DiscreteEvents, Printf, Distributions, Random, YAActL

struct Arrive <: Message end
struct Finish <: Message end

mutable struct Server  # state machine body
    id::Int
    clk::Clock
    input::Channel
    output::Channel
    job::Int
    d::Distribution
end

Base.get(c::Clock, m::Message, after, Δt::Number) =
    event!(c, (fun(send!, self(), m), yield), after, Δt)
```

The actor realizes the same finite state machine as before by switching between two behaviors: `idle` and `busy`:

```julia
function idle(s::Server, ::Arrive)
    if isready(s.input)
        s.job = take!(s.input)
        become(busy, s)
        get(s.clk, Finish(), after, rand(s.d))
        now!(s.clk, ()->@printf("%5.3f: server %d serving customer %d\n", tau(s.clk), s.id, s.job))
    end
end
busy(s::Server, ::Message) = nothing  # this is a default transition
function busy(s::Server, ::Finish)
    put!(s.output, s.job)
    become(idle, s)
    now!(s.clk, ()->@printf("%5.3f: server %d finished serving %d\n", tau(s.clk), s.id, s.job))
end
```

When an idle server gets an `Arrive()` message, it checks its input and if there is one, it takes it and becomes busy. It schedules a `Finish()` message for itself after a random service time. When it arrives, it puts its job into the output and becomes idle. As you see, the code is almost plain text.

As before we need an arrival function:

```julia
function arrivals(clk::Clock, queue::Channel, lnk::Vector{Link}, num_customers::Int, arrival_dist::Distribution)
    for i = 1:num_customers # initialize customers
        delay!(clk, rand(arrival_dist))
        put!(queue, i)
        now!(clk, ()->@printf("%5.3f: customer %d arrived\n", tau(clk), i))
        map(l->send!(l, Arrive()), lnk) # notify the actors
    end
end
```

We setup our environment, the actors and the arrivals process:

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
lnk = Link[]
for i in 1:num_servers   # start actors
    s = Server(i, clock, input, output, 0, service_dist)
    push!(lnk, Actor(idle, s))
end
process!(clock, Prc(0, arrivals, input, lnk, num_customers, arrival_dist), 1)
run!(clock, 20)
```

... and get our expected output:

```julia
0.123: customer 1 arrived
0.123: server 1 serving customer 1
0.226: customer 2 arrived
0.226: server 2 serving customer 2
0.539: server 1 finished serving 1
0.667: server 2 finished serving 2
2.135: customer 3 arrived
....
9.475: server 2 serving customer 9
10.027: server 1 finished serving 8
10.257: customer 10 arrived
10.257: server 1 serving customer 10
10.624: server 1 finished serving 10
10.734: server 2 finished serving 9
"run! finished with 50 clock events, 0 sample steps, simulation time: 20.0"
```
