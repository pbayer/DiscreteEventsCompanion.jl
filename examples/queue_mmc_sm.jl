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

Random.seed!(8710)          # set random number seed for reproducibility
const N = 10                # total number of customers
const c = 2                 # number of servers
const μ = 1.0 / c           # service rate
const λ = 0.9               # arrival rate
const M₁ = Exponential(1/λ) # interarrival time distribution
const M₂ = Exponential(1/μ) # service time distribution

act!(::Server, ::𝑋, ::𝐸) = nothing
function act!(s::Server, ::Idle, ::Arrive)
    if isready(s.input)
        s.job = take!(s.input)
        s.state = Busy()
        event!(s.clk, (fun(put!, s.com, Finish()), yield), after, rand(s.d))
        print(s.clk, @sprintf("%5.3f: server %d serving customer %d\n", tau(s.clk), s.id, s.job))
    end
end
function act!(s::Server, ::Busy, ::Finish)
    s.state = Idle()
    put!(s.output, s.job)
    print(s.clk, @sprintf("%5.3f: server %d finished serving %d\n", tau(s.clk), s.id, s.job))
end
function act!(s::Server)  # actor loop
    while true
        act!(s, s.state, take!(s.com))
    end
end

# model arrivals
function arrivals(clk::Clock, queue::Channel, srv::Vector{Server}, N::Int, M₁::Distribution)
    for i = 1:N # initialize customers
        delay!(clk, rand(M₁))
        put!(queue, i)
        print(clk, @sprintf("%5.3f: customer %d arrived\n", tau(clk), i))
        map(s->put!(s.com,Arrive()), srv) # notify the servers
    end
end

# initialize simulation environment
clock = Clock()
input = Channel{Int}(Inf)
output = Channel{Int}(Inf)
srv = Server[]
t = Task[]
for i in 1:c   # start actors
    push!(srv, Server(i, clock, Channel{𝐸}(32), input, output, Idle(), 0, M₂))
    push!(t, @task act!(srv[i]))
    yield(t[i])
end
process!(clock, Prc(0, arrivals, input, srv, N, M₁), 1)
run!(clock, 20)
