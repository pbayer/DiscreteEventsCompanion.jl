# Parallel Simulation

Currently `DiscreteEvents.jl` supports two approaches to parallel simulations.

## Distributed Simulations

Several simulations can be executed in parallel on

- multiple cores of one machine using the [`@threads`- macro](https://docs.julialang.org/en/v1/manual/multi-threading/#The-@threads-Macro) or on
- multiple processes, potentially on different machines using the [`Distributed`](https://docs.julialang.org/en/v1/manual/distributed-computing/) library.

They then have different clocks with different times. This approach is useful if you do multiple simulations to investigate their response to parameter variation or for machine learning.

See the [dice game example](examples/dicegame/dicegame.md).

## [Multi-Threading (Experimental)](@id multi-threading)

`DiscreteEvents` introduces with `v0.3` and some cautions a way to distribute the computation of one simulation over multiple cores of one machine.

This **breaks** the concept of a universally uniform time in a simulation:

> The concept of a unique global clock is not meaningful in the context of a distributed system of self-contained parallel agents. ...
>
> ... a unique (linear) global time is not definable. ...
>
> This is not to imply that it is impossible to construct a distributed system whose behavior is such that the elements of the system can be abstractly construed as acting synchronously. ... Assume one element, called the global master, controls when each of the elements in the system may continue; ...
>
> The important point to be made is that any such global synchronization creates a bottleneck which can be extremely inefficient in the context of a distributed environment. [^1]

In a distributed system we must find a compromise between maintaining a global order of events and being able to do efficient local computations. The key insight is that not all events in a discrete event system have strong causal relations with each other and therefore not all events need to be tightly synchronized.

## Thread-local Time

`DiscreteEvents` introduces parallel clocks with *thread local time*. It maintains *partial orderings of events* on each thread. By synchronizing the parallel clocks each given time interval ``ϵ`` it ensures that for all parallel clocks ``C_i, C_j: |t_i - t_j| < ϵ``.

It is up to the user to take care that associated events or entities from subsystems in a DES get grouped together to run on a thread. Thus causal relations get maintained locally.

In reality subsystems of DES are often decoupled by buffers or queues:

- In factories there are buffers between different sections of the fabrication process,
- in hospitals an operating room is decoupled from wards by a preparation area,
- in traffic systems there are crossways to join and to separate different urban zones from each other,
- in product development different sub-projects are (or should be) separated from each other by time buffers ...

Those decouplings are natural interfaces between subsystems and can be used to distribute a model over multiple threads.

### Parallel efficiency

- number of threads to use,
- relieving thread 1

see the chapter in performance

### Thread safety

- using random numbers on parallel threads,
- avoid shared variables,

[^1]: Gul Agha: Actors, A Model of Concurrent Computation in Distributed Systems.- 1986, MIT Press, 9ff
