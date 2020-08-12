using DiscreteEvents, Printf, Distributions, Random

Random.seed!(8710)          # set random number seed for reproducibility
const N = 10                # total number of customers
const c = 2                 # number of servers
const μ = 1.0 / c           # service rate
const λ = 0.9               # arrival rate
const M₁ = Exponential(1/λ) # interarrival time distribution
const M₂ = Exponential(1/μ) # service time distribution

# describe the server process
function server(clk::Clock, id::Int, input::Channel, output::Channel, M₂::Distribution)
    job = take!(input)
    print(clk, @sprintf("%5.3f: server %d serving customer %d\n", tau(clk), id, job))
    delay!(clk, rand(M₂))
    print(clk, @sprintf("%5.3f: server %d finished serving %d\n", tau(clk), id, job))
    put!(output, job)
end

# model arrivals
function arrivals(clk::Clock, queue::Channel, N::Int, M₁::Distribution)
    for i = 1:N # initialize customers
        delay!(clk, rand(M₁))
        put!(queue, i)
        print(clk, @sprintf("%5.3f: customer %d arrived\n", tau(clk), i))
    end
end

# initialize simulation environment
clock = Clock()
input = Channel{Int}(Inf)
output = Channel{Int}(Inf)
for i in 1:c
    process!(clock, Prc(i, server, i, input, output, M₂))
end
process!(clock, Prc(0, arrivals, input, N, M₁), 1)
run!(clock, 20)
