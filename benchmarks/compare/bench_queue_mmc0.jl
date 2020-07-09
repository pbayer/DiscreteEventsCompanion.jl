#
# implements the queue_mmc problem in DiscreteEvents
# -------------------------------------------------------
# based on issue #1 and on @dfish's code
#
using DiscreteEvents, DataStructures, Distributions, Random, BenchmarkTools

const _bench = [false]

mutable struct Server
    capacity::Int
    ids::Vector{Int}
end

Server(capacity) = Server(capacity, Int[])

is_full(s) = length(s.ids) ≥ s.capacity

remove!(s, id) = filter!(x-> x != id, s.ids)

add!(s, id) = push!(s.ids, id)

Random.seed!(8710) # set random number seed for reproducibility
num_customers = 10 # total number of customers generated
num_servers = 2 # number of servers
mu = 1.0 / 2 # service rate
lam = 0.9 # arrival rate
arrival_dist = Exponential(1 / lam) # interarrival time distriubtion
service_dist = Exponential(1 / mu); # service time distribution

function enter_line(clock, server, id, service_dist, arrival_time)
    delay!(clock, arrival_time)
    _bench[end] ||  now!(clock, fun(println, "Customer $id arrived: ", clock.time))
    if is_full(server)
        _bench[end] || now!(clock, fun(println, "Customer $id is waiting: ", clock.time))
        wait!(clock, ()->!is_full(server))
    end
    _bench[end] ||  now!(clock, fun(println,"Customer $id starting service: ", clock.time))
    add!(server, id)
    tΔ = rand(service_dist)
    delay!(clock, tΔ)
    leave(clock, server, id)
    # now!(clock, fun(println, "servers available ", server.capacity-length(server.ids), " ", clock.time))
    # now!(clock, fun(println, "servers full ", is_full(server), " ", clock.time))
end

function leave(clock, server, id)
    _bench[end] || now!(clock, fun(println, "Customer $id finishing service: ", clock.time))
    remove!(server, id)
end

function initialize!(clock, arrival_dist, service_dist, num_customers, server)
    arrival_time = 0.0
    for i in 1:num_customers
        arrival_time += rand(arrival_dist)
        process!(clock, Prc(i, enter_line, server, i, service_dist, arrival_time), 1)
    end
end

function run_model(arrival_dist, service_dist, num_customers, num_servers, t)
    clock = Clock()
    server = Server(num_servers)
    initialize!(clock, arrival_dist, service_dist, num_customers, server)
    run!(clock, t)
end

# run_model(arrival_dist, service_dist, num_customers, num_servers, 20)

_bench[end] = true
@benchmark run_model(arrival_dist, service_dist, num_customers, num_servers, 20)
