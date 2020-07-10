#
# This is the queue_mmc SimJulia example found on
# https://github.com/BenLauwens/SimJulia.jl/blob/master/examples/queue_mmc.ipynb
#
# only modified for benchmarking
#
cd(@__DIR__)
using Distributions, SimJulia, ResumableFunctions, Random
using BenchmarkTools, Plots

const _bench = [false]

Random.seed!(8710) # set random number seed for reproducibility
num_customers = 10 # total number of customers generated
num_servers = 2 # number of servers
mu = 1.0 / 2 # service rate
lam = 0.9 # arrival rate
arrival_dist = Exponential(1 / lam) # interarrival time distriubtion
service_dist = Exponential(1 / mu); # service time distribution

@resumable function customer(env::Environment, server::Resource, id::Integer, time_arr::Float64, dist_serve::Distribution)
    @yield timeout(env, time_arr) # customer arrives
    _bench[end] || println("Customer $id arrived: ", now(env))
    @yield request(server) # customer starts service
    _bench[end] || println("Customer $id entered service: ", now(env))
    @yield timeout(env, rand(dist_serve)) # server is busy
    @yield release(server) # customer exits service
    _bench[end] || println("Customer $id exited service: ", now(env))
end

function run_model(arrival_dist, service_dist, num_customers, num_servers)
    sim = Simulation() # initialize simulation environment
    server = Resource(sim, num_servers) # initialize servers
    arrival_time = 0.0
    for i = 1:num_customers # initialize customers
        arrival_time += rand(arrival_dist)
        @process customer(sim, server, i, arrival_time, service_dist)
    end
    run(sim) # run simulation
end

function run_model(num_customers)
    result = @benchmark run_model($arrival_dist, $service_dist, $num_customers, $num_servers)
    return mean(result).time*1e-9
end

_bench[end] = true
N = [10,1000,2000,4000]

times = run_model.(N)
plot(N, times, xlabel="Customers", ylabel="Time (seconds)", leg=false, grid=false)
savefig("img/bench_queue_mmc_SimJulia.png")
