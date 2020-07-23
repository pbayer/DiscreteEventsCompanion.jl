# Processes

Often in discrete event systems (DES) we find typical sequences of events ``\,S_i = \{e_i, e_j, e_k, ..., e_m\}\,`` repeated over and over and carried out asynchronously by similar agents. For example servers in a data center may

1. take a job from an input queue,
2. process it for a service time,
3. release the job and put it into an output queue.

Those typical event sequences are called *processes* in simulation literature [^1]. If they *interact*, they generate the event sequence ``\,S=\{e_1,e_2,e_3, ..., e_n\}\,`` of the entire DES.

[Processes](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#Processes-1) in `DiscreteEvents`

- use functions to describe a characteristic sequence ``S_i`` and
- run as asynchronous Julia tasks.

They keep their own data, states and code in their function body.

## Syntax

Processes execute Julia code, wait or delay on the clock and are suspended and reactivated by Julia's scheduler according to available resources. For operations regarding time, IO and resources they use:

- [`delay!`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.delay!):  suspend and get reactivated (by the clock) at/after a given time,
- [`wait!`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.wait!):  suspend and get reactivated after a given condition becomes true,
- [`now!`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.now!):  transfer IO-operations to the clock,
- [`take!`](https://docs.julialang.org/en/v1/base/parallel/#Base.take!-Tuple{Channel}): take an item from a channel or block until it becomes available,
- [`put!`](https://docs.julialang.org/en/v1/base/parallel/#Base.put!-Tuple{Channel,Any}): put something into a channel or block if it is full until it becomes available.

The first three commands: `delay!`, `wait!` and `now!` create events on the clock's event scheduler, `take!` and `put!` are handled directly by the Julia scheduler. All blocking commands should only be used in processes (asynchronous tasks) and never within the main program or in the Julia REPL [^2].

The following two functions define processes:

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

Note that to run as processes, functions must have a `Clock` variable as their first argument.

We can start multiple instances of processes representing e.g. multiple servers and different arrival processes.

## Startup

To register functions as processes to the clock and start them we use:

- [`Prc`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.Prc): prepare a function to run as a process,
- [`process!`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.process!): register a `Prc` to a clock, start it in a loop as an asynchronous task and return its id.

The following code example starts our processes (we assume the variables to be defined before):

```julia
for i in 1:num_servers  # start multiple server processes
    process!(clock, Prc(i, server, i, input, output, service_dist))
end
process!(clock, Prc(0, arrivals, input, num_customers, arrival_dist), 1)
```

The `server` processes run their function body in an infinite loop (default) while the `arrivals` process runs it only once and then terminates. The `server` processes wait for jobs in their input channels and the `arrivals` process waits for the clock to tick. If we start the clock, the processes begin to interact: customers are produced by the arrivals process, the servers then serve them …

## Limitations

The process-interaction scheme describes typical event sequences ``S_i``. If those typical event sequences are altered by stochastic events, the scheme is in trouble and we must use [exception handling](https://docs.julialang.org/en/v1/manual/control-flow/#Exception-Handling-1) to tackle those alterations. This is a severe limitation of "processes" as used in simulations.

Actors are a way to overcome the limitations of processes and still to maintain their conveniences.

[^1]: see: Banks, Carson, Nelson, Nicol: Discrete-Event System Simulation, 4th ed, 2005, p. 74-77
[^2]: If you want to use `take!` or `put!` on channels inside the main program, make sure that they are available (with `isready(ch)` or `length(ch.data) < ch.sz_max`) before calling them in order to avoid blocking.
