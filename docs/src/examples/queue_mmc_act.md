# M/M/c Activities

Here we take the toy [example of a multi-server M/M/c queue](https://github.com/BenLauwens/SimJulia.jl/blob/master/examples/queue_mmc.ipynb) [^1] and implement it as a sequence of server activities. We first need a server body:

```julia
using DiscreteEvents, Printf, Distributions, Random

mutable struct Server
    clock::Clock
    id::Int
    input::Channel{Int}
    output::Channel{Int}
    dist::Distribution
    job::Int
end
```

Then we implement the server activities `load`, `serve` and `finish` calling each other in sequence:

```julia
load(S::Server) = event!(S.clock, fun(serve, S), fun(isready, S.input))
    # we check the availability of the input channel explicitly ↑
    # since we don't want to block.

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
```

We model the arrivals as a function calling itself repeatedly with a time delay:

```julia
function arrive(c::Clock, input::Channel, num::Int, dist::Distribution)
    @printf("%5.3f: customer %d arrived\n", tau(c), jobno[1])
    put!(input, jobno[1])
    jobno[1] += 1
    if jobno[1] ≤ num
        event!(c, fun(arrive, c, input, num, dist), after, rand(dist))
      else
        event!(c, fun(stop!, c), after, 2/μ)
    end
end
```

Then we setup our constants and a simulation environment with clock, channels, servers and arrivals and run:

```julia
Random.seed!(8710)   # set random number seed for reproducibility
const N = 10                # total number of customers generated
const c = 2                 # number of servers
const μ = 1.0 / 2           # service rate
const λ = 0.9               # arrival rate
const M₁ = Exponential(1/λ) # interarrival time distribution
const M₂ = Exponential(1/μ) # service time distribution
const jobno = [1]           # job counter

# setup the simulation environment
clk = Clock()
input = Channel{Int}(32)  # create two channels
output = Channel{Int}(32)

# create and start the servers and the arrival process
srv = [Server(clk,i,input,output,M₂,0) for i ∈ 1:c]
map(s->load(s), srv)
event!(clk, fun(arrive, clk, input, N, M₁), after, rand(M₁))

run!(clk, 20)  # run the simulation
```

We get the following output:

```julia
0.123: customer 1 arrived
0.130: server 1 took job 1
0.226: customer 2 arrived
0.230: server 2 took job 2
0.546: server 1 finished job 1
...
9.475: customer 9 arrived
9.530: server 2 took job 9
10.066: server 1 finished job 8
10.257: customer 10 arrived
10.260: server 1 took job 10
10.626: server 1 finished job 10
10.739: server 2 finished job 9
"run! halted with 21 clock events, 1426 sample steps, simulation time: 14.26"
```

Note that

- the checking of the input channel in `load ...` switches on sampling implicitly (1426 sample steps),
- the `arrive` function stops the clock

[^1]:  see also: [M/M/c queue](https://en.wikipedia.org/wiki/M/M/c_queue) on Wikipedia and an [implementation in `SimJulia`](https://github.com/BenLauwens/SimJulia.jl/blob/master/examples/queue_mmc.ipynb).