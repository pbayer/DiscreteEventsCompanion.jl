# Parallel simulations

Currently `Simulate.jl` enables two approaches to parallel simulations.

## Simulations in parallel

Multiple simulations can be executed on parallel threads using the `@threads`-
macro. Such simulations have different clocks with different times. One example of
this is given in the [dice game example](examples/dicegame/dicegame.md). This
approach is useful if you do multiple simulations to investigate their response
to parameter variation. Basically you write a function, accepting parameters and doing a simulation on them. You then can invoke multiple simulations in a for loop:

```julia
```

## Multithreading of events and processes  

!!! compat "Julia 1.3"

    Multithreading requires Julia ≥ 1.3.

!!! warning "Not user-ready !!!"

    Multithreading is still experimental and in active development.

Simulations consist of multiple events, sampling functions and asynchronous
processes. The clock executes them sequentially on one thread. But modern computers have multiple cores, each being able to execute at least one distinct thread of operations. In order to speed things up, you may want to use the other cores (threads) as well:

### Uncertainty of event sequence

Multithreading introduces an **uncertainty** into simulations: If an event ``e_x`` has a scheduling time before event ``e_y`` on another thread both lying inside the same time interval ``t_x + Δt``, maybe – depending on differing thread loads – ``e_y`` gets executed before ``e_x``. There are several techniques to reduce this uncertainty:

1. If there is a causal connection between two events such that ``e_y`` depends on ``e_x``, the first one can be scheduled as [`event!`](https://pbayer.github.io/Simulate.jl/dev/usage/#Simulate.event!) with `sync=true` to *force* its execution before the second. But such dependencies are not always known beforehand in simulations.
2. You can choose to *group* causally connected events on one thread by scheduling them together on a specific parallel clock, such that they are executed in sequence. Consider a factory simulation: in real factories shops are often decoupled by buffers. You can allocate processes, events and samples of each shop  together on a thread. See [grouping](@ref grouping) below.
3. You can generally reduce the synchronization cycle Δt such that clocks get synchronized more often.

There is a tradeoff between parallel efficiency and uncertainty: if threads must be synchronized more often, there is more cost of synchronization relative to execution. You have to choose the uncertainty you are willing to pay to gain parallel efficiency. Often in simulations as in life fluctuations in event sequence cancel out statistically and can be neglected.

### [Grouping of events and processes](@id grouping)

- explicit grouping of events, processes and samples to parallel clocks,
- grouping them with the `@threads` macro,

### Parallel efficiency
- number of threads to use,

see the chapter in performance

### Thread safety
- using random numbers on parallel threads,
- synchronizing write access to shared variables,
