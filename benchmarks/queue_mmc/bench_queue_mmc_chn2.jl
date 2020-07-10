#
# with this 2nd modification arrivals occur during simulation
# and thus the customer/process queue gets shorter.
# --> the simulation should scale better
#
using DiscreteEvents, Distributions, Random, BenchmarkTools
using Plots, Printf
const _bench = [false]

Random.seed!(8710) # set random number seed for reproducibility
num_customers = 10 # total number of customers generated
num_servers = 2 # number of servers
mu = 1.0 / 2 # service rate
lam = 0.9 # arrival rate
arrival_dist = Exponential(1 / lam) # interarrival time distriubtion
service_dist = Exponential(1 / mu); # service time distribution

# Define Customer Behavior
function customer(clk::Clock, server::Channel, id::Int, ds::Distribution)
    # customer arrives
    _bench[end] || now!(clk, ()->@printf("%5.3f: customer %d arrived\n", tau(clk), id))
    s = take!(server)     # customer starts service
    _bench[end] || now!(clk, ()->@printf("%5.3f: customer %d entered service\n", tau(clk), id))
    delay!(clk, rand(ds)) # server is busy
    put!(server, s)       # customer exits service
    _bench[end] || now!(clk, ()->@printf("%5.3f: customer %d exited service\n", tau(clk), id))
end

# model arrivals
function arrivals(clock, server, num_customers, arrival_dist)
    for i = 1:num_customers # initialize customers
        delay!(clock, rand(arrival_dist))
        process!(clock, Prc(i, customer, server, i, service_dist), 1)
    end
end

function run_model(arrival_dist, service_dist, num_customers, num_servers, t)
    clock = Clock() # initialize simulation environment
    server = Channel{Int}(num_servers)  # initialize servers
    for i in 1:num_servers
        put!(server, i)
    end
    process!(clock, Prc(0, arrivals, server, num_customers, arrival_dist), 1)
    run!(clock, t)
end

function run_model(num_customers)
    result = @benchmark run_model($arrival_dist, $service_dist, $num_customers, $num_servers, 2000000)
    return mean(result).time*1e-9
end

_bench[end] = true
N = [10,1000,2000,4000]

times = run_model.(N)
plot(N, times, xlabel="Customers", ylabel="Time (seconds)", leg=false, grid=false)
savefig("bench_queue_mmc_chn2.png")
