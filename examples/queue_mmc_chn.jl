#
# this is the analog to the SimJulia M/M/c example found on
# https://github.com/BenLauwens/SimJulia.jl/blob/master/examples/queue_mmc.ipynb 
#
using DiscreteEvents, Printf, Distributions, Random

# Define Constants
Random.seed!(8710)          # set random number seed for reproducibility
const N = 10                # total number of customers
const c = 2                 # number of servers
const μ = 1.0 / c           # service rate
const λ = 0.9               # arrival rate
const M₁ = Exponential(1/λ) # interarrival time distribution
const M₂ = Exponential(1/μ) # service time distribution

# Define Customer Behavior
function customer(clk::Clock, server::Channel, id::Int, ta::Float64, ds::Distribution)
    delay!(clk, ta)       # customer arrives
    now!(clk, ()->@printf("%5.3f: customer %d arrived\n", tau(clk), id))
    s = take!(server)     # customer starts service
    now!(clk, ()->@printf("%5.3f: customer %d entered service\n", tau(clk), id))
    delay!(clk, rand(ds)) # server is busy
    put!(server, s)       # customer exits service
    now!(clk, ()->@printf("%5.3f: customer %d exited service\n", tau(clk), id))
end

# Setup and Run Simulation
clk = Clock() # initialize simulation environment
server = Channel{Int}(c)  # initialize servers
for i in 1:c
    put!(server, i)
end
arrival_time = 0.0
for i = 1:N # initialize customers
    global arrival_time += rand(M₁)
    process!(clk, Prc(i, customer, server, i, arrival_time, M₂), 1)
end
run!(clk, 20) # run simulation
