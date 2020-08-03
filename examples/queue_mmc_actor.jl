#
# simple actor implementation (without YAActL)
#
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
    com::Channel
    input::Channel
    output::Channel
    state::𝑋
    job::Int
    d::Distribution
end

Random.seed!(8710)   # set random number seed for reproducibility
const num_customers = 10   # total number of customers generated
const num_servers = 2      # number of servers
const μ = 1.0 / 2          # service rate
const λ = 0.9              # arrival rate
const arrival_dist = Exponential(1/λ)  # interarrival time distriubtion
const service_dist = Exponential(1/μ); # service time distribution

act!(::Server, ::𝑋, ::𝐸) = nothing
function act!(s::Server, ::Idle, ::Arrive)
    if isready(s.input)
        s.job = take!(s.input)
        s.state = Busy()
        event!(s.clk, (fun(put!, s.com, Finish()), yield), after, rand(s.d))
        now!(s.clk, ()->@printf("%5.3f: server %d serving customer %d\n", tau(s.clk), s.id, s.job))
    end
end
function act!(s::Server, ::Busy, ::Finish)
    s.state = Idle()
    put!(s.output, s.job)
    now!(s.clk, ()->@printf("%5.3f: server %d finished serving %d\n", tau(s.clk), s.id, s.job))
end
function act!(s::Server)  # actor loop
    while true
        act!(s, s.state, take!(s.com))
    end
end

# model arrivals
function arrivals(clk::Clock, queue::Channel, srv::Vector{Server}, num_customers::Int, arrival_dist::Distribution)
    for i = 1:num_customers # initialize customers
        delay!(clk, rand(arrival_dist))
        put!(queue, i)
        now!(clk, ()->@printf("%5.3f: customer %d arrived\n", tau(clk), i))
        map(s->put!(s.com,Arrive()), srv) # notify the servers
    end
end

# initialize simulation environment
clock = Clock()
input = Channel{Int}(Inf)
output = Channel{Int}(Inf)
srv = Server[]
t = Task[]
for i in 1:num_servers   # start actors
    push!(srv, Server(i, clock, Channel{𝐸}(32), input, output, Idle(), 0, service_dist))
    push!(t, @task act!(srv[i]))
    yield(t[i])
end
process!(clock, Prc(0, arrivals, input, srv, num_customers, arrival_dist), 1)
run!(clock, 20)
