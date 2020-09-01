# Processes

Often in discrete event systems (DES) we find typical sequences of events ``\,S_i = \{e_i, e_j, e_k, ..., e_m\}\,`` repeated over and over and carried out asynchronously by similar agents. For example servers in a data center may

1. take a job from an input queue,
2. process it for a service time,
3. release the job and put it into an output queue.

Those typical event sequences are called *processes* [^1]. If processes *interact*, their event sequences overlap and generate the event sequence ``\,S=\{e_1,e_2,e_3, ..., e_n\}\,`` of the greater system.

[Processes](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#Processes-1) in `DiscreteEvents`

- use functions to describe a characteristic sequence ``S_i`` and
- run as asynchronous Julia tasks.

They keep their own data, states and code in their function body.

## Syntax

Processes execute Julia code, wait or delay on the clock or wait for available resources. For operations regarding time, IO and resources they use:

- [`delay!`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.delay!):  suspend and get reactivated (by the clock) at/after a given time,
- [`wait!`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.wait!):  suspend and get reactivated after a given condition becomes true,
- [`now!`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.now!):  transfer IO-operations to the clock, or [`print`](https://pbayer.github.io/DiscreteEvents.jl/dev/processes/#Base.print-Tuple{Clock,IO,Any,Any}) via the clock,
- [`take!`](https://docs.julialang.org/en/v1/base/parallel/#Base.take!-Tuple{Channel}): take an item from a channel or block until it becomes available,
- [`put!`](https://docs.julialang.org/en/v1/base/parallel/#Base.put!-Tuple{Channel,Any}): put something into a channel or block if it is full until it becomes available.

The first three commands: `delay!`, `wait!` and `now!` schedule events to the clock, `take!` and `put!` on channels are handled directly by the Julia scheduler. All blocking commands should only be used in processes (asynchronous tasks) and never within the main loop (e.g. event- or activity-based implementations) from the Julia REPL [^2].

The [following code snippet](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/examples/queue_mmc_srv/) the two functions define processes:

```julia
# describe the server process
function server(clk::Clock, id::Int, input::Channel, output::Channel, X::Distribution)
    job = take!(input)
    print(clk, @sprintf("%5.3f: server %d serving customer %d\n", tau(clk), id, job))
    delay!(clk, X)
    print(clk, @sprintf("%5.3f: server %d finished serving %d\n", tau(clk), id, job))
    put!(output, job)
end

# describe the arrivals process
function arrivals(clk::Clock, queue::Channel, N::Int, X::Distribution)
    for i = 1:N # initialize customers
        delay!(clk, X)
        put!(queue, i)
        print(clk, @sprintf("%5.3f: customer %d arrived\n", tau(clk), i))
    end
end
```

!!! note "Rules for processes"

    1. to run as processes, functions must have a `Clock` variable as their first argument,
    2. processes (or asynchronous tasks in general) must `print` via the clock in order to avoid [clock concurrency](@ref clock_concurrency).

We can start multiple instances of those processes representing e.g. multiple servers or different arrival processes.

## Startup

To register functions as processes to the clock and start them we use:

- [`Prc`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.Prc): prepare a function to run as a process,
- [`process!`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.process!): register a `Prc` to a clock, start it in a loop as an asynchronous task and return its id.

The following code example starts our processes (we assume the variables to be defined before):

```julia
for i in 1:c
    process!(clock, Prc(i, server, i, input, output, M₂))
end
process!(clock, Prc(0, arrivals, input, N, M₁), 1)
```

The `server` processes run their function body in an infinite loop (default) while the `arrivals` process runs it only once and then terminates. The `server` processes wait for jobs in their input channels and the `arrivals` process waits for the clock to tick. If we start the clock, the processes begin to interact: customers are produced by the arrivals process, the servers then serve them …

## Limitations

Interacting sequential processes depend on "a rendezvous between the processes involved in sending and receiving the message, i.e. the sender cannot transmit a message until the receiver is ready to accept it". [^3] In our case the "message" is a reactivation of a blocked process by the clock or by the Julia scheduler.

If typical event sequences ``S_i`` (e.g. waiting for a resource or time delays) are interrupted by stochastic events (e.g. server breakdowns, customers reneging …), the processes are not ready and must use [exception handling](https://docs.julialang.org/en/v1/manual/control-flow/#Exception-Handling-1) to tackle them. This means that we have to treat natural occurrences in a stochastic DES as *errors* in our program.

This a severe limitation of "processes" as used in simulations. If we have to handle different interrupting events requiring different responses, things are getting complicated. This is a barrier to represent more complex systems with sequential processes.

There is an [example showing how to handle interrupts to processes](examples/queue_mmc_srv_fail.md).

[^1]: see: Banks, Carson, Nelson, Nicol: Discrete-Event System Simulation, 4th ed, 2005, p. 74-77
[^2]: If you want to use `take!` or `put!` on channels inside the main program, make sure that they are available (with `isready(ch)` or `length(ch.data) < ch.sz_max`) before calling them in order to avoid blocking.
[^3]: see: [Communicating Sequential Processes](https://en.wikipedia.org/wiki/Communicating_sequential_processes) (CSP) on Wikipedia.
