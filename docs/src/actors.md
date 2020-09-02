# Actors

DES under investigation, models and simulations tend to get bigger and more complex. Likewise we want to use the available computing power of parallel and distributed systems. Actors are a way to model larger and more complex systems and to use the available computing power.

> Actors are a more powerful computational agent than sequential
> processes ...
>
> ...  in the context of parallel systems, the degree to which a computation can be *distributed* over its lifetime is an important consideration. Creation of new actors provides the ability to abstractly increase the distributivity of the computation as it evolves. [^1]

`DiscreteEvents` introduces [Actors](https://en.wikipedia.org/wiki/Actor_model) to represent entities in DES and to distribute those entities over parallel cores of modern computers.

> Actor systems and actors have the following basic characteristics:
>
> - *Communication via direct asynchronous messaging:* ...
> - *State machines:* Actors support finite state machines. When an actor transitions to some expected state, it can modify its behavior in preparation for future messages. By *becoming* another kind of message handler, the actor implements a finite state machine.
> - *Share nothing:* Actors do not share their mutable state ...
> - *Lock-free concurrency:* ... actors never need to attempt to lock their state before reacting to a message. ...
> - *Parallelism:* ... Parallelism with the Actor model tends to fit well when one higher-level actor can dispatch tasks across several subordinate actors, perhaps even in a complex task processing hierarchy.
> - *Actors come in systems:* ... [^2]

Actors integrate so well into an event framework because they are message driven. Messages are built on events since they signal that an event has happened. Therefore actors are more reactive to events than sequential processes. Furthermore actor systems allow to represent and compose DES in a new way. They can

- represent hierarchy (e.g. UML state machines, different system levels ...),
- model structural changes in systems (e.g. making more servers available if load gets too high).

## An Operational Definition

Now given the descriptions above, we have to say what the `DiscreteEvents` framework *minimally* assumes an *actor* to be:

- An actor is represented by a Julia [`Channel`](https://docs.julialang.org/en/v1/base/parallel/#Base.Channel).
- [`Any`](https://docs.julialang.org/en/v1/base/base/#Core.Any) messages to the actor are sent to it over this channel. An Actor Framework may specify further the type of messages.
- The actor is a [`Task`] listening and responding to messages it receives over that channel.
- The actor is responsive to those messages and carries out its actions immediately and without further blocking.
- Therefore any actions by an actor are discrete and can be completed within one time step.

## Actor Support

Given those assumptions and to work within the `DiscreteEvents` framework an actor registers (`push!`es) its message channel into the `clk.channels` vector of the thread-local `Clock` variable `clk`. When `run!`ning the clock will not proceed to the next time step before all registered actor channels are empty and therefore the associated actors have completed their actions for that time step.

Actors must not use blocking calls like `delay!` or `wait!`. Instead they work with `event!`s sending messages to themselves after some time or under some conditions. In order to get the sequence right it is recommended that they work as [finite state machines](automata.md). This is illustrated in the [M/M/c with State-machines](examples/queue_mmc_sm.md) example.

!!! note "Minimal actor support"

    `DiscreteEvents` only has minimal actor support and therefore does not depend on any specific actor library.

## Dynamical state machines

For the following exploration into actors we use [`YAActL`](https://github.com/pbayer/YAActL.jl) `Actor`s. They have [behaviors](https://pbayer.github.io/YAActL.jl/dev/usage/#Behaviors) described by functions. They can change their behaviors with `become`. Thus they assume a new state and act as state machines. They can send delayed messages to themselves over the clock. The following code snippet is taken from the [M/M/c with Actors](examples/queue_mmc_actor.md) example:

```julia
using YAActL, DiscreteEvents

...
Base.get(clk::Clock, m::Message, after, Δt::Distribution) =
    event!(clk, fun(send!, self(), m), after, Δt)

...

function idle(s::Server, ::Arrive)        # on arrival message
    if isready(s.input)                   # check the input ...
        s.job = take!(s.input)            # ... in order not to block
        become(busy, s)                   # change behavior
        get(s.clk, Finish(), after, s.d)  # send delayed message
        ...
    end
end
busy(s::Server, ::Message) = nothing      # a default transition
function busy(s::Server, ::Finish)
    become(idle, s)                       # change behavior
    put!(s.output, s.job)
    ...
end
```

If the actor starts, it assumes his initial `idle` behavior. It returns a link (a message channel) for sending messages to it, which we `register!` to the `clock.channels` vector. When it gets an `Arrive()` message, it checks for a job and eventually takes it and becomes `busy` ...

```julia
for i in 1:c   # start actors
    s = Server(i, clock, input, output, 0, M₂)
    register!(clock.channels, Actor(idle, s))
end
```

We then can command the actors over the `clock.channels` vector. For the full example see [M/M/c Queue with Actors](examples/queue_mmc_actor.md).

## Actor Composition

## Actors in parallel

[^1]: Gul Agha: Actors, A Model of Concurrent Computation in Distributed Systems.- 1986, MIT Press, 9
[^2]: Vaughn Vernon: Reactive Messaging Patterns with the Actor Model.- 2016, Pearson, 14f
