# Processes

[Processes](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#Processes-1) are functions describing sequences of events and running as asynchronous Julia tasks. They can wait or delay and are suspended and reactivated by Julia's scheduler according to background events or resources available. They keep their own data.

## Syntax

Processes use a syntax different from event handling. They

- [`delay!`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.delay!):  suspend and get reactivated (by the clock) at/after a given time,
- [`wait!`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.wait!):  suspend and get reactivated after a given condition becomes true,
- [`now!`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.now!):  transfer IO-operations to the clock,
- [`take!`](https://docs.julialang.org/en/v1/base/parallel/#Base.take!-Tuple{Channel}): take an item from a channel or wait until it becomes available,
- [`put!`](https://docs.julialang.org/en/v1/base/parallel/#Base.put!-Tuple{Channel,Any}): put something into a channel or wait if it is full until it becomes available.

The following code example defines two processes:

```julia
# describe the server process
function server(clk::Clock, id::Int, input::Channel, output::Channel, service_dist::Distribution)
    job = take!(input)
    now!(clk, ()->@printf("%5.3f: server %d serving customer %d\n", tau(clk), id, job))
    delay!(clk, rand(service_dist))
    now!(clk, ()->@printf("%5.3f: server %d finished serving %d\n", tau(clk), id, job))
    put!(output, job)
end

# describe the arrivals process
function arrivals(clk::Clock, queue::Channel, num_customers::Int, arrival_dist::Distribution)
    for i = 1:num_customers # initialize customers
        delay!(clk, rand(arrival_dist))
        put!(queue, i)
        now!(clk, ()->@printf("%5.3f: customer %d arrived\n", tau(clk), i))
    end
end
```

Note that to run as processes functions must have a `::Clock` variable as their first argument.

## Startup

With the following commands we can register and start processes under the clock.

- [`Prc`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.Prc): prepares a function to run as a process in a simulation,
- [`process!`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.process!): Register a `Prc` to a clock, start it in a loop as an asynchronous process and return its id.

The following code example starts our processes (we assume the variables to be defined before):

```julia
for i in 1:num_servers  # start server processes
    process!(clock, Prc(i, server, i, input, output, service_dist))
end
process!(clock, Prc(0, arrivals, input, num_customers, arrival_dist), 1)
```

Now the `server` processes run their function in an infinite loop (default) while the `arrivals` process runs only once and then terminates. The `server` processes wait for jobs in their input channels and the `arrivals` process waits for the clock to tick.

## Diagnosis

We can see that the processes have been registered to the clock:

```julia
julia> clock.processes
Dict{Any,Prc} with 3 entries:
  0 => Prc(0, Task (runnable) @0x000000010fc82ad0, Clock 0, thrd 1 (+ 0 ac): state=DiscreteEvents.Undefined(), t=0.0 , Δt=0.01 , prc:3…
  2 => Prc(2, Task (runnable) @0x000000010d13db10, Clock 0, thrd 1 (+ 0 ac): state=DiscreteEvents.Undefined(), t=0.0 , Δt=0.01 , prc:3…
  1 => Prc(1, Task (runnable) @0x000000013a183190, Clock 0, thrd 1 (+ 0 ac): state=DiscreteEvents.Undefined(), t=0.0 , Δt=0.01 , prc:3…
```

We can check the `arrivals` process 0 with

```julia
julia> clock.processes[0].task
Task (runnable) @0x000000010fc82ad0
```

If the task had failed, we would get the stacktrace with that command.

## Run and speedup

If we then run the clock (e.g. `run!(clock, 20)`), it increments time, the `arrivals` process puts the first item into the queue, the first `server` process can take it and so on. The three processes run and are handled by the Julia scheduler asynchronously to the main task (where the `clock` runs in).

If we don't want to compete our processes against other background tasks handled also by the Julia scheduler, we can speed up things significantly by executing them on another processor core:

```julia
onthread(2) do
    clock = Clock()
    input = Channel{Int}(Inf)
    output = Channel{Int}(Inf)
    for i in 1:num_servers
        process!(clock, Prc(i, server, i, input, output, service_dist))
    end
    process!(clock, Prc(0, arrivals, input, num_customers, arrival_dist), 1)
    run!(clock, t)
end
```

!!! note

    For that to work, [`JULIA_NUM_TREADS`](https://docs.julialang.org/en/v1/manual/environment-variables/#JULIA_NUM_THREADS-1) must be set accordingly.
