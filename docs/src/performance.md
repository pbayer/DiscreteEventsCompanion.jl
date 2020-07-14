# Performance

For larger models and simulations over longer timeframes performance matters and
users can do a lot to get more of it. The generic process of getting more performant simulations is:

1. Follow the [performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-tips-1) in the Julia manual,
2. follow the hints in this chapter.

## Improving simulation performance

- for events use functions or `fun` instead of quoted expressions.

If you have a process-based simulation,

- generate only the necessary processes/tasks for running the simulation. Avoid long queues of runnable processes or tasks unless absolutely necessary.
- consider to express parts of your simulation with event-scheduling.
- speedup your simulation performance by running it on a processor core ``x>1`` with `onthread(x) do ... end`.

For one example of how to improve simulation performance please look at the [M/M/c queue benchmarks](https://github.com/pbayer/DiscreteEventsCompanion.jl/tree/master/benchmarks/queue_mmc) or at [M/M/c model way too slow #1](https://github.com/pbayer/DiscreteEventsCompanion.jl/issues/1).
