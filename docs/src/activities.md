# Activities

We *think* of an activity as taking some time while an event is instantaneous. One useful definition for activity is:

> A pair of events, one initiating and the other completing an operation that transforms the state of an entity. Time elapses in an activity. [^1]

Usually there are different entities in a DES. In a timed sequence of events

```math
\{(e_1,t_1),(e_2,t_2),(e_3,t_3),\hspace{1em}...\hspace{1em}, (e_n,t_n)\}
```

an activity may extend over two or more events. E.g. a server starts to serve a customer at a given time. This activity stretches a certain interval in time. Within that interval other customers may arrive or leave or other servers may proceed in their work.

For certain problems it is useful to describe a DES as a sequence of activities. The activity based approach models a DES as sequences of activities of multiple entities overlapping each other in time. For practical purposes an activity is a function combining

- some operations to describe the activity with
- an event to call the next activity.

This is still a form of event scheduling. The following [code snippet](examples/queue_mmc_act.md) implements three activities of a server:

```julia
load(S::Server) = event!(S.clock, fun(serve, S), fun(isready, S.input))

function serve(S::Server)
    S.job = take!(S.input)
    @printf("%5.3f: server %d took job %d\n", tau(S.clock), S.id, S.job)
    event!(S.clock, (fun(finish, S)), after, rand(S.dist))
end

function finish(S::Server)
    put!(S.output, S.job)
    @printf("%5.3f: server %d finished job %d\n", tau(S.clock), S.id, S.job)
    S.job=0
    load(S)
end
```

If in our example the boss – or another customer or a computer failure ... – interrupts the `serve` activity, we are in trouble - as in life - and would have to implement a mechanism for handling such exceptions.

[^1]: George S. Fishman: Discrete-Event Simulation – Modeling, Programming, and Analysis, Springer, 2001, p 39
