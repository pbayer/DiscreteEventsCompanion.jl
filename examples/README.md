# Example programs

example programs are explained in the [documentation](https://pbayer.github.io/DiscreteEventsCompanion.jl/dev/)

## Introductory examples

- `chitchat.jl`: basic event scheduling,
- `server.jl`: a state machine example,
- `tabletennis.jl`: a state machine simulation of a game

## M/M/c queue

The following examples all implement the same M/M/c queue:

- `queue_mmc_act.jl`: an activity-based model,
- `queue_mmc_srv.jl`: a process-based model,
- `queue_mmc_sm.jl`: a state machine model,
- `queue_mmc_actor.jl`: an actor model,
- `queue_mmc_chn.jl`: yet another way to model it (slow!)

## M/M/c queue with failures

- `queue_mmc_srv_fail.jl`: a process-based model with failures,

## Parallel Simulations

The `assy...jl` examples implement parallel simulations and comparisons with single threaded ones:

- `assy_thrd.jl` is an assembly line with 10 assembly operations on each thread,
- `assy_thrd-2.jl` is the same line with only the arrival process on thread 1 and then 20 assembly steps on thread 2 and 10 on each other thread, much faster
- `assy-t1.jl` the assembly line on only thread 1
