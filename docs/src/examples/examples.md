# Examples

The examples should show how to use `DiscreteEvents` and how to employ and combine different approaches to modeling and simulation.

## Introductory Examples

- [Table tennis](tabletennis.md): a state-based model,
- [Single server](singleserver.md): activity-based model,

## M/M/c Queue

The following examples illustrate different implementations of a simple M/M/2 queue:

- [M/M/c activity-based](queue_mmc_act.md),
- [M/M/c process-based](queue_mmc_srv.md),
- [M/M/c state-based](queue_mmc_sm.md), a finite state machine actor,
- [M/M/c actor](queue_mmc_actor.md), with  `YAActL` actors,

The following examples simulate server failures:

- [M/M/c process-based + interrupts](queue_mmc_srv_fail.md)

## Multi-Threading

- An [assembly line of several sections](assy_thrd.md) running on different threads

## Other Examples:

- [House heating](house_heating/house_heating.md): a hybrid system combining events, continuous sampling and processes,
- [Post office](postoffice/postoffice.md): a process-based simulation of a post-office,
- [Goldratt's dice game](dicegame/dicegame.md): parallel simulations of assembly lines.

## Working with the examples

If you would like to play with the examples, you can look at:

-  [Jupyter notebooks](https://github.com/pbayer/DiscreteEventsCompanion.jl/tree/master/notebooks) or
-  [Julia program files](https://github.com/pbayer/DiscreteEventsCompanion.jl/tree/master/examples).
