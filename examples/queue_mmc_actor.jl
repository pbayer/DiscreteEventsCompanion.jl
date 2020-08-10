#
# actor implementation 
#
using DiscreteEvents, Printf, Distributions, Random, YAActL

struct Arrive <: Message end
struct Finish <: Message end

mutable struct Server  # state machine body
    id::Int
    clk::Clock
    input::Channel
    output::Channel
    job::Int
    S::Distribution
end

Random.seed!(8710)          # set random number seed for reproducibility
const N = 10                # total number of customers
const c = 2                 # number of servers
const μ = 1.0 / c           # service rate
const λ = 0.9               # arrival rate
const M₁ = Exponential(1/λ) # interarrival time distribution
const M₂ = Exponential(1/μ) # service time distribution

Base.get(clk::Clock, m::Message, after, Δt::Number) =
    event!(clk, (fun(send!, self(), m), yield), after, Δt)

function idle(s::Server, ::Arrive)
    if isready(s.input)
        s.job = take!(s.input)
        become(busy, s)
        get(s.clk, Finish(), after, rand(s.S))
        now!(s.clk, ()->@printf("%5.3f: server %d serving customer %d\n", tau(s.clk), s.id, s.job))
    end
end
busy(s::Server, ::Message) = nothing
function busy(s::Server, ::Finish)
    become(idle, s)
    put!(s.output, s.job)
    now!(s.clk, ()->@printf("%5.3f: server %d finished serving %d\n", tau(s.clk), s.id, s.job))
end

# model arrivals
function arrivals(clk::Clock, queue::Channel, lnk::Vector{Link}, N::Int, A::Distribution)
    for i = 1:N # initialize customers
        delay!(clk, rand(A))
        put!(queue, i)
        now!(clk, ()->@printf("%5.3f: customer %d arrived\n", tau(clk), i))
        map(l->send!(l, Arrive()), lnk) # notify the servers
    end
end

# initialize simulation environment
clock = Clock()
input = Channel{Int}(Inf)
output = Channel{Int}(Inf)
lnk = Link[]
for i in 1:c   # start actors
    s = Server(i, clock, input, output, 0, M₂)
    push!(lnk, Actor(idle, s))
    register!(clock, lnk[end])
end
process!(clock, Prc(0, arrivals, input, lnk, N, M₁), 1)
run!(clock, 20)
