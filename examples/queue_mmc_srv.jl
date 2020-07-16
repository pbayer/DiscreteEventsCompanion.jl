using DiscreteEvents, Printf, Distributions, Random

Random.seed!(8710)   # set random number seed for reproducibility
num_customers = 10   # total number of customers generated
num_servers = 2      # number of servers
μ = 1.0 / 2          # service rate
λ = 0.9              # arrival rate
arrival_dist = Exponential(1/λ)  # interarrival time distriubtion
service_dist = Exponential(1/μ); # service time distribution

# describe the server process
function server(clk::Clock, id::Int, input::Channel, output::Channel, service_dist::Distribution)
    job = take!(input)
    now!(clk, ()->@printf("%5.3f: server %d serving customer %d\n", tau(clk), id, job))
    delay!(clk, rand(service_dist))
    now!(clk, ()->@printf("%5.3f: server %d finished serving %d\n", tau(clk), id, job))
    put!(output, job)
end

# model arrivals
function arrivals(clk::Clock, queue::Channel, num_customers::Int, arrival_dist::Distribution)
    for i = 1:num_customers # initialize customers
        delay!(clk, rand(arrival_dist))
        put!(queue, i)
        now!(clk, ()->@printf("%5.3f: customer %d arrived\n", tau(clk), i))
    end
end

# initialize simulation environment
clock = Clock()
input = Channel{Int}(Inf)
output = Channel{Int}(Inf)
for i in 1:num_servers
    process!(clock, Prc(i, server, i, input, output, service_dist))
end
process!(clock, Prc(0, arrivals, input, num_customers, arrival_dist), 1)
run!(clock, 20)