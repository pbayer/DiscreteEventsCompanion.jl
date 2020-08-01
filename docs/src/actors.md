# Actors

Investigated DES, models and simulations tend to get bigger and more complex. Likewise we want to use the available computing power of parallel and distributed systems. Actors are a way to model larger and more complex systems and at the same time to use the available computing power.

> Actors are a more powerful computational agent than sequential
> processes ...
>
> ...  in the context of parallel systems, the degree to which a computation can be *distributed* over its lifetime is an important consideration. Creation of new actors provides the ability to abstractly increase the distributivity of the computation as it evolves. [^1]

!!! note

    `DiscreteEvents` has no builtin support for actors yet. Therefore I want to mention and show some of the possibilities right now. But this has to be explored further.

For explorations into actors I have written a basic actor library: [`YAActL`](https://github.com/pbayer/YAActL.jl).

## Dynamical state machines

## Actors in parallel

Most computers now come with parallel cores that can be used for computation. The problem with parallel simulations is the synchronization of parallel event sequences in time:

> The concept of a unique global clock is not meaningful in the context of a distributed system of self-contained parallel agents. ...
>
> ... a *unique (linear) global time* is not definable. Instead, each computational agent has a local time which linearly orders the events as they occur at that agent, or alternately, orders the local states of that agent. These local orderings of events are related to each other by the activation ordering. The activation ordering represents the causal relationships between events happening at different agents. [^2]

Following this reasoning `DiscreteEvents` works with local times on each thread. In the parallel case the main clock is on thread one and operates as a global synchronizer for the local clocks on each thread. For its operation an actor gets from the main clock a reference to its local clock and thereby can access local time.

[^1]: Gul Agha: Actors, A Model of Concurrent Computation in Distributed Systems.- 1986, MIT Press, 9
[^2]: Ibid. 9f
