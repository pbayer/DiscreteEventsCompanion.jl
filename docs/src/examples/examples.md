# Examples

The examples should show how to use `DiscreteEvents` and how to employ and combine different approaches to modeling and simulation.

- [**Table tennis**](tabletennis.md): a state-based simulation,
- [**Single server**](singleserver.md): an activity-based simulation of a single server,
- [**M/M/c queue (activity)**](queue_mmc_act.md): an activity based simulation of an M/M/c queue,
- [**M/M/c queue (processes)**](queue_mmc_srv.md): process based simulation of the M/M/c queue,
- [**M/M/c queue (processes and interrupts)**](queue_mmc_srv.md): processes with failures,
- [**M/M/c queue (state machine)**](queue_mmc_sm.md): a finite state machine of the M/M/c queue,
- [**M/M/c queue (actor)**](queue_mmc_actor.md): an actor implementation with `YAActL`,
- [**House heating**](house_heating/house_heating.md): a simulation of a hybrid system, combining three schemes: events, continuous sampling and processes.
- [**Post office**](postoffice/postoffice.md): a process-based simulation of a
  post-office,
- [**Goldratt's dice game**](dicegame/dicegame.md): a simulation of assembly lines, illustrating what can be done with multiple simulations and parameter variation on parallel threads,

**Working with the examples** – If you would like to play with the examples:

- Jupyter notebooks are [here in the repo](https://github.com/pbayer/DiscreteEventsCompanion.jl/tree/master/notebooks),
- Julia program files are [here in the repo](https://github.com/pbayer/DiscreteEventsCompanion.jl/tree/master/examples).
