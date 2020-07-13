#
# This example is an activity based implementation of an M/M/c queue
# with 10 customers and two servers
#
using DiscreteEvents, Distributions, Random, BenchmarkTools
using Plots, Printf
const _bench = [false]

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
c = 2                # number of servers
μ = 1.0 / 2          # service rate
λ = 0.9              # arrival rate
arrival_dist = Exponential(1/λ)  # interarrival time distriubtion
service_dist = Exponential(1/μ); # service time distribution
const jobno = [1]    # job counter

# activities are functions calling each other directly or as events
load(S::Server) = event!(S.clock, fun(serve, S), fun(isready, S.input))

function serve(S::Server)
    S.job = take!(S.input)
    _bench[end] || @printf("%5.3f: server %d took job %d\n", tau(S.clock), S.id, S.job)
    event!(S.clock, (fun(finish, S)), after, rand(S.dist))
end

function finish(S::Server)
    put!(S.output, S.job)
    _bench[end] || @printf("%5.3f: server %d finished job %d\n", tau(S.clock), S.id, S.job)
    S.job=0
    load(S)
end

# model the arrivals
function arrive(c::Clock, input::Channel, num::Int, dist::Distribution)
    _bench[end] || @printf("%5.3f: customer %d arrived\n", tau(c), jobno[1])
    put!(input, jobno[1])
    jobno[1] += 1
    if jobno[1] ≤ num
        event!(c, fun(arrive, c, input, num, dist), after, rand(dist))
    else
        event!(c, fun(stop!, c), after, 2/μ) # stop the clock
    end
end

function run_model(arrival_dist, service_dist, num_customers, num_servers, t)
    # setup the simulation environment
    clk = Clock()
    input = Channel{Int}(Inf)  # create two channels
    output = Channel{Int}(Inf)
    jobno[1] = 1              # reset job counter

    # create and start the servers and the arrival process
    srv = [Server(clk,i,input,output,service_dist,0) for i ∈ 1:c]
    map(s->load(s), srv)
    event!(clk, fun(arrive, clk, input, num_customers, arrival_dist), after, rand(arrival_dist))

    run!(clk, t)  # run the simulation
end

function run_model(num_customers)
    result = @benchmark run_model($arrival_dist, $service_dist, $num_customers, $c, 2000000)
    return mean(result).time*1e-9
end

_bench[end] = true
N = [10,1000,2000,4000]

times = run_model.(N)
plot(N, times, xlabel="Customers", ylabel="Time (seconds)", leg=false, grid=false)
savefig("img/bench_queue_mmc_act.png")
