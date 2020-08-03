# M/M/c Process based

In yet another view we look at **entities** (e.g. messages, customers, jobs, goods) undergoing a *process* as they flow through a DES. A process can be viewed as a sequence of events separated by time intervals. Often entities or processes share limited resources. Thus they have to wait for them to become available and then to undergo a transformation (e.g. transport, treatment or service) taking some time.

This view can be expressed as [processes](../processes.md) waiting and delaying on a clock or implicitly blocking until they can `take!` something from a `Channel` or `put!` it back. An implementation of the M/M/c queue goes like this:

```julia
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

# initialize the simulation environment and run
clock = Clock()
input = Channel{Int}(Inf)
output = Channel{Int}(Inf)
for i in 1:num_servers
    process!(clock, Prc(i, server, i, input, output, service_dist))
end
process!(clock, Prc(0, arrivals, input, num_customers, arrival_dist), 1)
run!(clock, 20)
```

```
0.123: customer 1 arrived
0.123: server 1 serving customer 1
0.226: customer 2 arrived
0.226: server 2 serving customer 2
....
9.475: customer 9 arrived
9.475: server 2 serving customer 9
10.027: server 1 finished serving 8
10.257: customer 10 arrived
10.257: server 1 serving customer 10
10.624: server 1 finished serving 10
10.734: server 2 finished serving 9
"run! finished with 50 clock events, 0 sample steps, simulation time: 20.0"
```

Note that

- the times deviate from the activity based implementation because here we do not use conditional events and therefore have no time divergence due to sampling [^1].
- Processes must transfer IO-operations with a [`now!`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.now!) call to the clock.

[^1]: the load activity in the activity-based example uses a conditional event. The condition is then checked periodically with sampling. That introduces a time divergence into the simulation. Instead in the process-based example the blocking on channels is handled by Julia internally and we need not to wait conditionally on the clock.
