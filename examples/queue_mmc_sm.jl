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
const jobno = [0]           # job counter

act!(::Server, ::𝑋, ::𝐸) = nothing
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
function act!(s::Server)  # actor loop
    while true
        act!(s, s.state, take!(s.com))
    end
end

# model arrivals
function arrive(c::Clock, input::Channel, jobno::Vector{Int}, srv::Vector{Server})
    jobno[1] += 1
    @printf("%5.3f: customer %d arrived\n", tau(c), jobno[1])
    put!(input, jobno[1])
    map(s->put!(s.com,Arrive()), srv) # notify the servers
end

# initialize simulation environment
clock = Clock()
input = Channel{Int}(Inf)
output = Channel{Int}(Inf)
srv = Server[]
t = Task[]
for i in 1:c   # start servers/actors
    push!(srv, Server(i, clock, Channel{𝐸}(32), input, output, Idle(), 0, M₂))
    push!(t, @task act!(srv[i]))
    push!(clock.channels, srv[i].com)  # register the actor channel to the clock
    yield(t[i])                        # let the actor task start
end
event!(clock, fun(arrive, clock, input, jobno, srv), every, M₁, n=N)
run!(clock, 20)
