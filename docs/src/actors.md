# Actors

DES under investigation, models and simulations tend to get bigger and more complex. Likewise we want to use the available computing power of parallel and distributed systems. Actors are a way to model larger and more complex systems and to use the available computing power.

> Actors are a more powerful computational agent than sequential
> processes ...
>
> ...  in the context of parallel systems, the degree to which a computation can be *distributed* over its lifetime is an important consideration. Creation of new actors provides the ability to abstractly increase the distributivity of the computation as it evolves. [^1]

`DiscreteEvents` introduces [actors](https://en.wikipedia.org/wiki/Actor_model) to represent entities in DES and to distribute those entities over parallel cores of modern computers.

> Actor systems and actors have the following basic characteristics:
>
> - *Communication via direct asynchronous messaging:* ...
> - *State machines:* Actor support finite state machines. When an actor transitions to some expected state, it can modify its behavior in preparation for future messages. By *becoming* another kind of message handler, the actor implements a finite state machine.
> - *Share nothing:* Actors do not share their mutable state ...
> - *Lock-free concurrency:* ... actors never need to attempt to lock their state before reacting to a message. ...
> - *Parallelism:* ... Parallelism with the Actor model tends to fit well when one higher-level actor can dispatch tasks across several subordinate actors, perhaps even in a complex task processing hierarchy.
> - *Actors come in systems:* ... [^2]

Actors integrate so well into an event framework because they are message driven. Messages are built on events since they signal that an event has happened. Therefore actors are more reactive to events than sequential processes. Furthermore actor systems allow to represent and compose DES in a new way. They can

- represent hierarchy (e.g. UML state machines, different system levels ...),
- model structural changes in systems (e.g. making more servers available if load gets too high),

!!! note

    `DiscreteEvents` has no builtin support for actors yet. For explorations into actors we use [`YAActL`](https://github.com/pbayer/YAActL.jl).

## Dynamical state machines

Actors have their [behaviors](https://pbayer.github.io/YAActL.jl/dev/usage/#Behaviors) described by functions. They can change those functions with `become`. Thus they assume a new state and act as state machines:

```julia
function idle(s::Server, ::Arrive)
    if isready(s.input)
        s.job = take!(s.input)
        become(busy, s)
        get(s.clk, Finish(), after, rand(s.d))
        ...
    end
end
busy(s::Server, ::Message) = nothing  # this is a default transition
function busy(s::Server, ::Finish)
    become(idle, s)
    put!(s.output, s.job)
    ...
end
```

If the actor starts, it assumes his initial `idle` behavior. It delivers a link (a message channel) for sending messages to it. When it gets an `Arrive()` message, it checks for a job and eventually takes it and becomes `busy` ...

```julia
lnk = Link[]
for i in 1:num_servers          # setup servers
    s = Server(i, clock, input, output, 0, service_dist)
    push!(lnk, Actor(idle, s))  # start actors
end
```

We can command the actors over the `lnk` array. For the full example see [M/M/c queue with Actors](examples/queue_mmc_actor.md).

## Composition

## Actors in parallel

[^1]: Gul Agha: Actors, A Model of Concurrent Computation in Distributed Systems.- 1986, MIT Press, 9
[^2]: Vaughn Vernon, Reactive Messaging Patterns with the Actor Model.- 2016, Pearson, 14f
[^3]: Gul Agha: 9f
