# M/M/c Process-based with Failures

Processes represent typical event sequences. But if those sequences are altered by "external" events like failures, we have to handle those unusual events as *interrupts* or exceptions.

The following example shows how this can be done. We assume here  external streams of failure events (Poisson processes) causing interrupts to our server processes. We also assume that failures and repairs are independent from each other and therefore that a repair can be interrupted by another failure.

We introduce state variables tracking whether a failure has occurred and whether a job is worked on. Therefore we define a server structure:

```julia
using DiscreteEvents, Printf, Distributions, Random

struct Failure end      # a failure event

mutable struct Server
    id::Int
    input::Channel
    output::Channel
    Ts::Distribution    # service time distribution
    Tr::Distribution    # repair time distribution
    job::Int
    failed::Bool
end
```

Our `serve` process then has two branches: one for regular service and another for failure handling. With a `try ... catch ... end` block we capture any exceptions and let a `Failure` event switch the process to the failure handling branch. 

The regular service branch also has to be modified: We must `take!` a job from the input channel only if no other job is present and we must reset the job status variable when a job is finished. We assume here that either service time or repair time are restarted anew after any failure:

```julia
# describe the server process
function serve(c::Clock, s::Server)
    try
        if !s.failed
            if s.job == 0 
                s.job = take!(s.input)
                print(c, @sprintf("%5.3f: server %d serving customer %d\n", tau(c), s.id, s.job))
            end
            if s.job > 0
                delay!(c, s.Ts)
                print(c, @sprintf("%5.3f: server %d finished serving %d\n", tau(c), s.id, s.job))
                put!(s.output, s.job)
                s.job = 0
            end
        else
            print(c, @sprintf("%5.3f: server %d fails\n", tau(c), s.id))
            delay!(c, s.Tr)
            print(c, @sprintf("%5.3f: server %d back to work\n", tau(c), s.id))
            s.failed = false
        end
    catch exc
        if exc isa PrcException && exc.event isa Failure
            s.failed = true
        else
            rethrow(exc)
        end
    end
end
```

If you compare the `serve` process with [the previous one without failures](queue_mmc_srv.md), it certainly has become more complicated.

Next we need an arrivals function for a repeating event and some constants:

```julia
# model the arrivals
function arrive(c::Clock, input::Channel, jobno::Vector{Int})
    jobno[1] += 1
    @printf("%5.3f: customer %d arrived\n", tau(c), jobno[1])
    put!(input, jobno[1])
end

Random.seed!(8710)          # set random number seed for reproducibility
const N = 10                # total number of customers
const c = 2                 # number of servers
const μ = 1.0 / c           # service rate
const λ = 0.9               # arrival rate
const M₁ = Exponential(1/λ) # inter-arrival time distribution
const M₂ = Exponential(1/μ) # service time distribution
const F₁ = Exponential(8)   # inter-failure time distribution
const F₂ = Exponential(2)   # repair time distribution 
const jobno = [0]           # job counter
```

Parallel to the two servers and their `serve` processes we start two Poisson processes `interrupt!`ing them every simulated random inter-failure time.

```julia
# initialize simulation environment
clock = Clock()
input = Channel{Int}(Inf)
output = Channel{Int}(Inf)
for i in 1:c
    s = Server(i, input, output, M₂, F₂, 0, false)
    p = Prc(i, serve, s)
    process!(clock, p)
    event!(clock, fun(interrupt!, p, Failure(), nothing), every, F₁)
end
event!(clock, fun(arrive, clock, input, jobno), every, M₁, n=N)

run!(clock, 20)
```

We get the following output:

```julia
0.231: customer 1 arrived
0.231: server 1 serving customer 1
0.672: server 1 finished serving 1
0.743: server 2 fails
0.885: server 1 fails
1.478: server 2 back to work
2.140: customer 2 arrived
2.140: server 2 serving customer 2
2.439: server 1 fails
3.040: customer 3 arrived
3.979: server 1 back to work
3.979: server 1 serving customer 3
...
11.035: server 2 back to work
11.035: server 2 serving customer 8
11.193: customer 10 arrived
11.375: server 1 finished serving 4
11.375: server 1 serving customer 9
11.658: server 1 finished serving 9
11.658: server 1 serving customer 10
12.059: server 2 finished serving 8
12.526: server 1 finished serving 10
12.870: server 1 fails
12.877: server 1 fails
13.034: server 1 back to work
"run! finished with 71 clock events, 0 sample steps, simulation time: 20.0"
```

As you see we get repeating failures, longer cycle times and more disturbance in job service sequence than in the example without failures.
