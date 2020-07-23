# Performance

For larger models and simulations over longer timeframes performance matters and
users can do a lot to get more of it. The generic process of getting more performant simulations is:

1. Follow the [performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-tips-1) in the Julia manual,
2. follow the hints in this chapter.

## Improving simulation performance

- for events use functions or `fun` instead of quoted expressions.

If you have tasks in your simulation,

- generate only the necessary processes/tasks for running the simulation. Avoid long queues of runnable processes or tasks unless absolutely necessary.
- consider to express parts of your simulation with event-scheduling.
- speedup your simulation performance by running it on a processor core ``x>1`` with `onthread(x) do ... end`.

For one example of how to improve simulation performance please look at the [M/M/c queue benchmarks](https://github.com/pbayer/DiscreteEventsCompanion.jl/tree/master/benchmarks/queue_mmc) or at [M/M/c model way too slow #1](https://github.com/pbayer/DiscreteEventsCompanion.jl/issues/1).


## Run and speedup

If we don't want to compete our processes against other background tasks handled also by the Julia scheduler on thread 1, we can speed up things significantly by executing them on another processor core:

```julia
onthread(2) do
    clock = Clock()
    input = Channel{Int}(Inf)
    output = Channel{Int}(Inf)
    for i in 1:num_servers
        process!(clock, Prc(i, server, i, input, output, service_dist))
    end
    process!(clock, Prc(0, arrivals, input, num_customers, arrival_dist), 1)
    run!(clock, t)
end
```

!!! note

    For that to work, [`JULIA_NUM_TREADS`](https://docs.julialang.org/en/v1/manual/environment-variables/#JULIA_NUM_THREADS-1) must be set accordingly.
