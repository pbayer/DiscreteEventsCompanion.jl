# M/M/c Process based

In yet another view we look at **entities** (e.g. messages, customers, jobs, goods) undergoing a *process* as they flow through a DES. A process can be viewed as a sequence of events separated by time intervals. Often entities or processes share limited resources. Thus they have to wait for them to become available and then to undergo a transformation (e.g. transport, treatment or service) taking some time.

This view can be expressed as [processes](../processes.md) waiting and delaying on a clock or implicitly blocking until they can `take!` something from a `Channel` or `put!` it back. To implement the M/M/c we start right with describing the `server` and `arrivals` processes:

```julia
using DiscreteEvents, Printf, Distributions, Random

function server(clk::Clock, id::Int, input::Channel, output::Channel, service_dist::Distribution)
    job = take!(input)
    now!(clk, ()->@printf("%5.3f: server %d serving customer %d\n", tau(clk), id, job))
    delay!(clk, rand(service_dist))
    now!(clk, ()->@printf("%5.3f: server %d finished serving %d\n", tau(clk), id, job))
    put!(output, job)
end

function arrivals(clk::Clock, queue::Channel, N::Int, M₁::Distribution)
    for i = 1:N # initialize customers
        delay!(clk, rand(M₁))
        put!(queue, i)
        now!(clk, ()->@printf("%5.3f: customer %d arrived\n", tau(clk), i))
    end
end
```

Then we setup our constants, the simulation environment with clock, channels and processes and run:

```julia
Random.seed!(8710)          # set random number seed for reproducibility
const N = 10                # total number of customers
const c = 2                 # number of servers
const μ = 1.0 / c           # service rate
const λ = 0.9               # arrival rate
const M₁ = Exponential(1/λ) # interarrival time distribution
const M₂ = Exponential(1/μ) # service time distribution

# initialize the simulation environment and run
clock = Clock()
input = Channel{Int}(Inf)
output = Channel{Int}(Inf)
for i in 1:c
    process!(clock, Prc(i, server, i, input, output, M₂))
end
process!(clock, Prc(0, arrivals, input, N, M₁), 1)
run!(clock, 20)
```

We get the following output:

```julia
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
