# Parallel simulations

Currently `DiscreteEvents.jl` enables two approaches to parallel simulations.

## Simulations in parallel

Multiple simulations can be executed on parallel to each other using the `@threads`- macro. They have different clocks with different times. This approach is useful if you do multiple simulations to investigate their response to parameter variation. Basically you write a function, accepting parameters and doing a simulation on them. You then can invoke multiple simulations in a for loop:

```julia
```

See the [dice game example](examples/dicegame/dicegame.md).

## [Distributed simulations](@id distributed_simulations)

An other way is to distribute a simulation over multiple cores of one machine. But this breaks the concept of a universally uniform time in a simulation:

> The concept of a unique global clock is not meaningful in the context of a distributed system of self-contained parallel agents. ...
>
> ... a unique (linear) global time is not definable. ...
>
> This is not to imply that it is impossible to construct a distributed system whose behavior is such that the elements of the system can be abstractly construed as acting synchronously. ... Assume one element, called the global master, controls when each of the elements in the system may continue; ...
>
> The important point to be made is that any such global synchronization creates a bottleneck which can be extremely inefficient in the context of a distributed environment. [^1]

In a distributed system we must find a compromise between maintaining a global order of events and being able to do efficient local computations. The key insight is that not all events in a system have causal relations with each other and therefore not all events need to be synchronized.

`DiscreteEvents` introduces parallel clocks with *thread local time*. Thus it maintains *partial orderings of events* on each thread. By synchronizing the parallel clocks each given time interval ``ϵ`` it ensures that for all parallel clocks ``C_i, C_j: |t_i - t_j| < ϵ``.

It is then up to the user to take care that associated events or entities in a DES get grouped together to run on a thread. Thus causal relations get maintained. In reality subsystems of DES are often decoupled by buffers or queues. Those decouplings are the natural interfaces between subsystems to be used to divide a model over multiple threads.

### Parallel efficiency

- number of threads to use,

see the chapter in performance

### Thread safety

- using random numbers on parallel threads,
- synchronizing write access to shared variables,

[^1]: Gul Agha: Actors, A Model of Concurrent Computation in Distributed Systems.- 1986, MIT Press, 9ff
