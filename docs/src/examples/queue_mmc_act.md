# M/M/c Activities

Here we take the toy [example of a multi-server M/M/c queue](https://github.com/BenLauwens/SimJulia.jl/blob/master/examples/queue_mmc.ipynb) [^1] and implement it as a sequence of server activities. 

We first need a server body:

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

The server activities `load`, `serve` and `finish` are functions calling each other in sequence:

```julia
load(S::Server) = event!(S.clock, fun(serve, S), fun(isready, S.input))
# we check the availability of the input channel ↑ since we don't want to block

function serve(S::Server)
    S.job = take!(S.input)  # this would block on an empty channel
    @printf("%5.3f: server %d took job %d\n", tau(S.clock), S.id, S.job)
    event!(S.clock, (fun(finish, S)), after, S.dist)
end

function finish(S::Server)
    put!(S.output, S.job)
    @printf("%5.3f: server %d finished job %d\n", tau(S.clock), S.id, S.job)
    S.job < N && load(S)
end
```

Note that:

- we must check the input channel in `load` since everything runs in the user process and a `take!` on an empty input channel would block. So we setup a conditional `event!` to call `serve` when the channel is ready.
- The checking of the input channel in `load` switches on sampling implicitly (1027 sample steps). This ensures that the simulation runs and does not block.
- The sampling introduces an uncertainty into a simulation since it causes a time delay between the completion of a condition and its detection at the next sampling step.


A simple function (triggered by a repeating event) models the arrivals:

```julia
function arrive(c::Clock, input::Channel, jobno::Vector{Int})
    jobno[1] += 1
    @printf("%5.3f: customer %d arrived\n", tau(c), jobno[1])
    put!(input, jobno[1])
end
```

We setup our constants and a simulation environment with a clock, two channels, two servers and an arrival process and then run:

```julia
Random.seed!(8710)   # set random number seed for reproducibility
const N = 10                # total number of customers generated
const c = 2                 # number of servers
const μ = 1.0 / 2           # service rate
const λ = 0.9               # arrival rate
const M₁ = Exponential(1/λ) # interarrival time distribution
const M₂ = Exponential(1/μ) # service time distribution
const jobno = [0]           # job counter

# setup the simulation environment
clk = Clock()
input = Channel{Int}(32)  # create two channels
output = Channel{Int}(32)

# create and start the servers and the arrival process
srv = [Server(clk,i,input,output,M₂,0) for i ∈ 1:c]
map(s->load(s), srv)
event!(clk, fun(arrive, clk, input, jobno), every, M₁, n=N)

run!(clk, 20)  # run the simulation
```

We get the following output:

```julia
0.123: customer 1 arrived
0.130: server 1 took job 1
0.226: customer 2 arrived
0.230: server 2 took job 2
0.546: server 1 finished job 1
0.671: server 2 finished job 2
2.135: customer 3 arrived
2.140: server 1 took job 3
...
9.475: customer 9 arrived
9.480: server 2 took job 9
10.036: server 1 finished job 8
10.257: customer 10 arrived
10.260: server 1 took job 10
10.626: server 1 finished job 10
10.739: server 2 finished job 9
"run! finished with 20 clock events, 1027 sample steps, simulation time: 20.0"
```


[^1]:  see also: [M/M/c queue](https://en.wikipedia.org/wiki/M/M/c_queue) on Wikipedia and an [implementation in `SimJulia`](https://github.com/BenLauwens/SimJulia.jl/blob/master/examples/queue_mmc.ipynb).
