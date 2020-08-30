# Activities

We *think* of an activity as taking some time while an event is instantaneous. One useful definition for activity is:

> A pair of events, one initiating and the other completing an operation that transforms the state of an entity. Time elapses in an activity. [^1]

Usually there are different entities in a DES. In a timed sequence of events

```math
\{(e_1,t_1),(e_2,t_2),(e_3,t_3),\hspace{1em}...\hspace{1em}, (e_n,t_n)\}
```

an activity may span two or more events in a system. E.g. a server starts to serve a customer at a given time. This activity takes a certain interval in time. Within that interval other customers may arrive or leave or other servers may proceed in their work.

## Sequences of Activities

For certain problems it is useful to describe a DES as a sequence of activities. An activity-based approach models a DES as sequences of activities of multiple entities overlapping each other in time. For practical purposes an activity is a function combining

- some operations to describe the activity with
- an event to call the next activity.

This is still a form of event scheduling. The following [code snippet](examples/queue_mmc_act.md) implements three activities of a server:

```julia
load(S::Server) = event!(S.clock, fun(serve, S), fun(isready, S.input))

function serve(S::Server)
    S.job = take!(S.input)
    @printf("%5.3f: server %d took job %d\n", tau(S.clock), S.id, S.job)
    event!(S.clock, (fun(finish, S)), after, S.dist)
end

function finish(S::Server)
    put!(S.output, S.job)
    @printf("%5.3f: server %d finished job %d\n", tau(S.clock), S.id, S.job)
    S.job < N && load(S)
end
```

The three activities call each other under conditions or after time intervals:

1. The first activity `load` uses a conditional `event!` to check  the input channel [^2]. This switches on clock sampling. If the condition is true, it triggers `serve`.
2. `serve` `take!`s a job from the input channel and then uses a timed `event!` to call `finish` and
3. `finish` switches back to `load`.

In a practical example we can create several instances of activity-based `Server`s interacting with each other.

## Limitations

If in that example the boss – or a customer or a computer failure ... – interrupts those activities, we are in trouble - as in life - and would have to implement a mechanism for handling such anomalies.

Either we had to delete the next scheduled event to branch into another activity like `handle_interrupt` or we had to introduce a state variable to represent different branches of activities and make activities state dependent. 

----

see also: [`event!`](https://pbayer.github.io/DiscreteEvents.jl/dev/events/#Timed-events), [`fun`](https://pbayer.github.io/DiscreteEvents.jl/dev/events/#DiscreteEvents.fun), [`tau`](https://pbayer.github.io/DiscreteEvents.jl/dev/clocks/#DiscreteEvents.tau), [`stop!`](https://pbayer.github.io/DiscreteEvents.jl/dev/clocks/#DiscreteEvents.stop!)

[^1]: George S. Fishman: Discrete-Event Simulation – Modeling, Programming, and Analysis, Springer, 2001, p 39
[^2]: It has to check it before `take!` is called because that blocks. Everything here runs in the user process and therefore we must not block. 
