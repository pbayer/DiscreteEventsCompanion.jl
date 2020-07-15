# Models


```math
\begin{aligned}
\hspace{5em} && \textit{All models are wrong. Some are useful. (George Box)}
\end{aligned}
```

There are different approaches in modeling *discrete event systems (DES)* for simulation. All are limiting in some way. `DiscreteEvents` tries to provide a simple, yet versatile and powerful grammar for combining the approaches.

Discrete events here are Julia functions or expressions executed at a given time.

## Sampling

The simplest mechanism for generating discrete events is to have a clock `clk` executing a function `𝑓` periodically. We can generate periodic events in various ways:

- sampling events with `periodic!(clk, 𝑓, Δt)` are executed at the clock sample rate `Δt`,
- repeating events with `event!(clk, 𝑓, every, Δt)` are executed every given interval `Δt`,
- conditional events with `event!(clk, 𝒈, 𝑓)` check the condition `𝑓` at the clock's sample rate `Δt` until it returns `true`. Then `𝑔` is executed.

Thus we can model periodic events but no stochastic event sequences, characteristic of DES. Sampling is useful if we want to model repeated or periodic events interacting with a DES, check conditions, trace or visualise the system periodically.

Sampling introduces a time uncertainty into simulations since it triggers changes, takes measurements or checks for conditions only at a given time interval Δt.

## Event scheduling

Following Cassandras [^1] we can consider discrete event systems (DES) as stochastic timed automata ``(\mathcal{E},\mathcal{X},\Gamma,p,p_0,G)`` where

```math
\begin{array}{rl}
  \mathcal{E} & \textrm{countable event set} \\
  \mathcal{X} & \textrm{countable state space} \\
  \Gamma(x)   & \textrm{feasible or enabled events}: x \in \mathcal{X}, \Gamma(x) \subseteq \mathcal{E} \\
  p(x';x,e')  & \textrm{state transition probability}: x,x' \in \mathcal{X}, e' \in \mathcal{E} \\
  p_0(x)      & \textrm{pmf} P[X_0=x]: x \in \mathcal{X}, X_o \textrm{initial state} \\
  G_i         & \textrm{stochastic clock structure}: i \in \mathcal{E}
\end{array}
```

As seen before `DiscreteEvents.jl` provides [clock structures](clocks.md) ``G_i`` and  [event generating mechanisms](events.md). Everything else can be expressed in Julia.

Choi and Kang [^2] outline three approaches to event scheduling: 1) event, 2) state and 3) activity based.

### Event based approach

We can simply schedule Julia functions as events, possibly triggering other events.

```julia
using DiscreteEvents, Distributions, Random

Random.seed!(123)
ex = Exponential()

chit(c) = (print("."), event!(c, fun(chat, c), after, rand(ex)))
chat(c) = (print(":"), event!(c, fun(chit, c), after, rand(ex)))

c = Clock()
event!(c, fun(chit, c), after, rand(ex))
event!(c, println, at, 10)
run!(c, 10)
```
```
.:.:.:.:.:.:.:.:.
"run! finished with 18 clock events, 0 sample steps, simulation time: 10.0"
```

This is useful when we don't have to care much about states.

### State based approach

Events can be expressed as state transitions ``\mathcal{f}(x, \gamma)`` with ``x \in \mathcal{X},\ \gamma \in \Gamma(x)`` of finite automata. The following example models 8 servers as state machines serving a queue of jobs:

```julia
using DiscreteEvents, Printf, Random, Distributions

const p = 0.3

abstract type 𝑋 end    # define states
struct Idle <: 𝑋 end
struct Busy <: 𝑋 end

abstract type Γ end    # events
struct Load <: Γ end
struct Release <: Γ end
struct Setup <: Γ end

mutable struct Server  # state machine body
    id::Int
    c::Clock
    state::𝑋
    job::Int
end

ex = Exponential()
queue = Vector{Int}()
done  = Vector{Int}()
Base.isready(x::Array) = !isempty(x)

# transition functions
function 𝒇(A::Server, ::Idle, ::Load)
    A.job = pop!(queue)
    A.state = Busy()
    @printf("%5.2f: server %d took job %d\n", tau(A.c), A.id, A.job)
    event!(A.c, fun(𝒇, A, A.state, Release()), after, rand(ex))
end

function 𝒇(A::Server, ::Busy, ::Release)
    if rand() > p
        push!(queue, A.job)
    else
        pushfirst!(done, A.job)
        @printf("%5.2f: server %d finished job %d\n", tau(A.c), A.id, A.job)
    end
    A.job = 0
    A.state=Idle()
    event!(A.c, fun(𝒇, A, A.state, Setup()), after, rand(ex)/5)
end

𝒇(A::Server, ::Idle, ::Setup) = event!(A.c, fun(𝒇, A, A.state, Load()), fun(isready, queue))
𝒇(A::Server, 𝑥::𝑋, γ::Γ) = println(stderr, "$(A.name) $(A.id) undefined transition $𝑥, $γ")

# model arrivals
function arrive(clk::Clock, job)
    pushfirst!(queue, job)
    event!(clk, fun(arrive, clk, job+1), after, rand(ex))
end

# setup simulation environment and run simulation
Random.seed!(123)
c = Clock()
A = [Server(i, c, Idle(), 0) for i ∈ 1:8]
for i ∈ shuffle(1:8)
    event!(c, fun(𝒇, A[i], A[i].state, Load()), fun(isready, queue))
end
event!(c, fun(arrive, c, 1), after, rand(ex))
run!(c, 10)
```

```
0.12: server 4 took job 1
0.41: server 6 took job 2
0.60: server 4 finished job 1
0.68: server 6 finished job 2
1.68: server 1 took job 3
...
9.13: server 2 took job 5
9.28: server 3 finished job 3
9.92: server 5 took job 9
9.95: server 2 finished job 5
"run! finished with 58 clock events, 1001 sample steps, simulation time: 10.0"
```

Note that we modeled the arrivals "event-based" (without considering any state).

### Activity based approach

Here we take the [example of a multi-server M/M/c queue](https://github.com/BenLauwens/SimJulia.jl/blob/master/examples/queue_mmc.ipynb) [^3] and implement it as a sequence of server activities:

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

Random.seed!(8710)   # set random number seed for reproducibility
num_customers = 10   # total number of customers generated
c = 2                # number of servers
μ = 1.0 / 2          # service rate
λ = 0.9              # arrival rate
arrival_dist = Exponential(1/λ)  # interarrival time distriubtion
service_dist = Exponential(1/μ); # service time distribution
const jobno = [1]    # job counter

# activities are functions calling each other directly or as events
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

# model the arrivals
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

# setup the simulation environment
clk = Clock()
input = Channel{Int}(32)  # create two channels
output = Channel{Int}(32)
jobno[1] = 1              # reset job counter

# create and start the servers and the arrival process
srv = [Server(clk,i,input,output,service_dist,0) for i ∈ 1:c]
map(s->load(s), srv)
event!(clk, fun(arrive, clk, input, num_customers, arrival_dist), after, rand(arrival_dist))

run!(clk, 20)  # run the simulation
```
```
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

## Process flow

In yet another view we look at **entities** (e.g. messages, customers, jobs, goods) undergoing a *process* as they flow through a DES. A process can be viewed as a sequence of events separated by time intervals. Often entities or processes share limited resources. Thus they have to wait for them to become available and then to undergo a transformation (e.g. transport, treatment or service) taking some time.

This view can be expressed as [processes](processes.md) waiting and delaying on a clock or implicitly blocking until they can `take!` something from a `Channel` or `put!` it back. An implementation of the M/M/c queue goes like this:

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

- the times deviate from the activity based implementation because here we do not use conditional events and therefore have no time divergence due to sampling [^4].
- Processes must transfer IO-operations with a [`now!`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.now!) call to the clock.

## Comparison

=====

**The following needs rework:**

The output of the last example is different from the first three approaches because we did not shuffle (the shuffling of the processes is done by the scheduler). So if the output depends very much on the sequence of events and you need to have reproducible results, explicitly controlling for the events like in the first three examples is preferable. If you are more interested in statistical evaluation - which is often the case -, the 4th approach is appropriate.

All four approaches can be expressed in `DiscreteEvents.jl`. Process based modeling seems to be the simplest and the most intuitive approach, while the first three are more complicated. But they are also more structured and controllable , which comes in handy for more complicated examples. After all, parallel processes are often tricky to control and to debug. But you can combine the approaches and take the best from all worlds.

## Combined approach

Physical systems can be modeled as *continuous systems* (nature does not jump), *discrete systems* (nature jumps here!) or *hybrid systems* (nature jumps sometimes).

While continuous systems are the domain of differential equations, discrete and hybrid systems may be modeled easier with `DiscreteEvents.jl` by combining the *event-scheduling*, the *process-based* and the *continuous-sampling* schemes.

### A hybrid system

In a hybrid system we have continuous processes and discrete events interacting in one system. A thermostat or a house heating system is a basic example of this:

- Heating changes between two states: On and Off. The thermostat switches heating on if romm temperature `Tr` is greater or equal 23°C, it switches off if temperature falls below 20°C.
- A room cools at a rate proportional to the difference between room temperature `Tr` and environment temperature `Te`.
- It heats at a rate proportional to the temperature difference between temperature of the heating fluid `Th` and room temperature `Tr`.
- The room temperature `Tr` changes proportional to the difference between heating and cooling.

First we setup the physical model with some assumptions:


```julia
using DiscreteEvents, Plots, DataFrames, Random, Distributions, LaTeXStrings

const Th = 40     # temperature of heating fluid
const R = 1e-6    # thermal resistance of room insulation
const α = 2e6     # represents thermal conductivity and capacity of the air
const β = 3e-7    # represents mass of the air and heat capacity
η = 1.0           # efficiency factor reducing R if doors or windows are open
heating = false   # initially the heating is off

Δte(t, t1, t2) = cos((t-10)*π/12) * (t2-t1)/2  # change rate of a sinusoidal Te

function Δtr(Tr, Te, heating)
    Δqc = (Tr - Te)/(R * η)             # cooling rate
    Δqh = heating ? α * (Th - Tr) : 0   # heating rate
    return β * (Δqh - Δqc)              # change of room temperature
end
```
Δtr (generic function with 1 method)

We setup a simulation for 24 hours from 0am to 12am. We update the simulation every virtual minute.


```julia
reset!(𝐶)                               # reset the clock
rng = MersenneTwister(122)              # set random number generator
Δt = 1//60                              # evaluate every minute
Te = 11                                 # starting values
Tr = 20
df = DataFrame(t=Float64[], tr=Float64[], te=Float64[], heating=Int64[])

function setTemperatures(t1=8, t2=20)   # define a sampling function
    global Te += Δte(tau(), t1, t2) * 2π/1440 + rand(rng, Normal(0, 0.1))
    global Tr += Δtr(Tr, Te, heating) * Δt
    push!(df, (tau(), Tr, Te, Int(heating)) )
end

function switch(t1=20, t2=23)           # a function simulating the thermostat
    if Tr ≥ t2
        global heating = false
        event!(fun(switch, t1, t2), @val :Tr :≤ t1)  # setup a conditional event
    elseif Tr ≤ t1
        global heating = true
        event!(fun(switch, t1, t2), @val :Tr :≥ t2)  # setup a conditional event
    end
end

periodic!(fun(setTemperatures), Δt)        # setup the sampling function
switch()                                   # start the thermostat

@time run!(𝐶, 24)                          # run the simulation
```
0.040105 seconds (89.21 k allocations: 3.435 MiB)\
"run! finished with 0 clock events, 1440 sample steps, simulation time: 24.0"

```julia
plot(df.t, df.tr, legend=:bottomright, label=L"T_r")
plot!(df.t, df.te, label=L"T_e")
plot!(df.t, df.heating, label="heating")
xlabel!("hours")
ylabel!("temperature")
title!("House heating undisturbed")
```




![svg](examples/house_heating/output_4_0.svg)



Now we have people entering the room or opening windows and thus reducing thermal resistance:


```julia
function people()
    delay!(6 + rand(Normal(0, 0.5)))         # sleep until around 6am
    sleeptime = 22 + rand(Normal(0, 0.5))    # calculate bed time
    while tau() < sleeptime
        global η = rand()                    # open door or window
        delay!(0.1 * rand(Normal(1, 0.3)))   # for some time
        global η = 1.0                       # close it again
        delay!(rand())                       # do something else
    end
end

reset!(𝐶)
rng = MersenneTwister(122)
Random.seed!(1234)
Te = 11
Tr = 20
df = DataFrame(t=Float64[], tr=Float64[], te=Float64[], heating=Int64[])

for i in 1:2                                 # put 2 people in the house
    process!(Prc(i, people), 1)               # run process only once
end
periodic!(fun(setTemperatures), Δt)    # setup sampling
switch()                                     # start the thermostat

@time run!(𝐶, 24)
```
0.114938 seconds (72.52 k allocations: 2.320 MiB)\
"run! finished with 116 clock events, 1440 sample steps, simulation time: 24.0"




```julia
plot(df.t, df.tr, legend=:bottomright, label=L"T_r")
plot!(df.t, df.te, label=L"T_e")
plot!(df.t, df.heating, label="heating")
xlabel!("hours")
ylabel!("temperature")
title!("House heating with people")
```




![svg](examples/house_heating/output_7_0.svg)



We have now all major schemes: events, continuous sampling and processes combined in one example.

**see also**: the [full house heating example](examples/house_heating/house_heating.md) for further explanations.


[^1]:  Cassandras and Lafortune: *Introduction to Discrete Event Systems*, Springer, 2008, Ch. 10
[^2]:  Choi and Kang: *Modeling and Simulation of Discrete-Event Systems*, Wiley, 2013
[^3]:  see also: [M/M/c queue](https://en.wikipedia.org/wiki/M/M/c_queue) on Wikipedia and an [implementation in `SimJulia`](https://github.com/BenLauwens/SimJulia.jl/blob/master/examples/queue_mmc.ipynb).
[^4]: the load activity in the activity-based example uses a conditional event. The condition is then checked periodically with sampling. That introduces a time divergence into the simulation. Instead in the process-based example the blocking on channels is handled by Julia internally and we need not to wait conditionally on the clock.
