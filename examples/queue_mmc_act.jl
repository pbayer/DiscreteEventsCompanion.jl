using DiscreteEvents, Printf, Distributions, Random

mutable struct Server
    clock::Clock
    id::Int
    input::Channel{Int}
    output::Channel{Int}
    dist::Distribution
    job::Int
end

Random.seed!(8710)   # set random number seed for reproducibility
num_customers = 10   # total number of customers generated
num_servers = 2      # number of servers
μ = 1.0 / 2          # service rate
λ = 0.9              # arrival rate
arrival_dist = Exponential(1/λ)  # interarrival time distriubtion
service_dist = Exponential(1/μ); # service time distribution

load(S::Server) = event!(S.clock, fun(serve, S), fun(isready, S.input))

function serve(S::Server)
    S.job = take!(S.input)
    @printf("%5.3f: server %d took job %d\n", tau(S.clock), S.id, S.job)
    event!(S.clock, (fun(finish, S)), after, rand(S.dist))
end

function finish(S::Server)
    put!(S.output, S.job)
    @printf("%5.3f: server %d finished job %d\n", tau(S.clock), S.id, S.job)
    S.job=0
    load(S)
end

input = Channel{Int}(32)  # create two channels
output = Channel{Int}(32)
jobno = 1

function arrive(c)
    @printf("%5.3f: customer %d arrived\n", tau(c), jobno)
    put!(input, jobno)
    global jobno += 1
    if jobno ≤ num_customers
        event!(c, fun(arrive, c), after, rand(arrival_dist))
    end
end

c = Clock()
S = [Server(c,i,input,output,service_dist,0) for i ∈ 1:num_servers]
map(s->load(s), S)
arrive(c)
run!(c, 10)
