using DiscreteEvents, Printf, Distributions, Random

struct Failure end

mutable struct Server
    id::Int
    input::Channel
    output::Channel
    Ts::Distribution  # service time distribution
    Tr::Distribution  # repair time distribution
    job::Int
    failed::Bool
end

Random.seed!(8710)          # set random number seed for reproducibility
const N = 10                # total number of customers
const c = 2                 # number of servers
const μ = 1.0 / c           # service rate
const λ = 0.9               # arrival rate
const M₁ = Exponential(1/λ) # interarrival time distribution
const M₂ = Exponential(1/μ) # service time distribution
const F₁ = Exponential(8)   # interfailure time distribution
const F₂ = Exponential(2)   # repair time distribution 
const jobno = [0]           # job counter

# describe the server process
function serve(c::Clock, s::Server)
    try
        if !s.failed
            if s.job == 0 
                s.job = take!(s.input)
                print(c, @sprintf("%5.3f: server %d serving customer %d\n", tau(c), s.id, s.job))
            end
            if s.job > 0
                delay!(c, s.Ts)
                print(c, @sprintf("%5.3f: server %d finished serving %d\n", tau(c), s.id, s.job))
                put!(s.output, s.job)
                s.job = 0
            end
        else
            print(c, @sprintf("%5.3f: server %d fails\n", tau(c), s.id))
            delay!(c, s.Tr)
            print(c, @sprintf("%5.3f: server %d back to work\n", tau(c), s.id))
            s.failed = false
        end
    catch exc
        if exc isa PrcException && exc.event isa Failure
            s.failed = true
        else
            rethrow(exc)
        end
    end
end

# model the arrivals
function arrive(c::Clock, input::Channel, jobno::Vector{Int})
    jobno[1] += 1
    @printf("%5.3f: customer %d arrived\n", tau(c), jobno[1])
    put!(input, jobno[1])
end

# initialize simulation environment
clock = Clock()
input = Channel{Int}(Inf)
output = Channel{Int}(Inf)
for i in 1:c
    s = Server(i, input, output, M₂, F₂, 0, false)
    p = Prc(i, serve, s)
    process!(clock, p)
    event!(clock, fun(interrupt!, p, Failure(), nothing), every, F₁)
end
event!(clock, fun(arrive, clock, input, jobno), every, M₁, n=N)

run!(clock, 20)
