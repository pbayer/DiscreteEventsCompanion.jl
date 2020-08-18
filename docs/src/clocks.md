# Clocks

We think of a clock as a device to [measure time](https://en.wikipedia.org/wiki/Time_in_physics)   [^1]. An event sequence ``\;S = \{e_1, e_2, ..., e_n\}\;`` has measured times ``\;t_1 < t_2 < ... < t_n``. From that order we draw inferences about causality.

A [`Clock`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#Clocks-1) in `DiscreteEvents` schedules events and triggers them at given times or under given conditions. It doesn't measure, it represents time. We can create a clock, run it for a while, stop time, step through time, skip from event to event, change event sequences … With it we can create, model or simulate discrete event systems (DES).

## Virtual clocks

A virtual clock is not constrained by physical time. It doesn't wait a physical time period for the next event to occur, but jumps right to it. It executes an event sequence as fast as possible.

```@repl clocks
using DiscreteEvents
clk = Clock()
```

We created a new clock, running on thread 1, having time ``t=0.0``, a sampling rate of ``Δt=0.01``, no registered processes, no scheduled events, conditional events or sampling actions.

```@repl clocks
run!(clk, 10)
```

If we run the clock for a duration ``Δt=10``, it jumps immediately ahead since it has nothing to do.

### Time units

## Real time clocks

A real time clock [`RTClock`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.RTClock) is bound to the computer's physical clock and measures time in seconds ``[s]``. We create and start it with [`createRTClock`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.RTClock)

```@repl clocks
rtc = createRTClock(0.01, 99)
```

Here we have created a real time clock with id=99 on thread 8. It has a clock period of T=0.01 s and synchronizes at that resolution with the system clock running in nano-seconds. When the start message was created, the clock had just advanced 0.0001193 s. When we query its time thereafter, it returns the time in seconds passed since startup:

```@repl clocks
sleep(1) # hide
tau(rtc)         # query time
sleep(1) # hide
rtc.time         # synonymous way to get time
```

We can schedule events to real time clocks as to virtual clocks and they will execute at their due physical time.

## [Clock concurrency](@id clock_concurrency)

`DiscreteEvents` can represent entities in DES as tasks (e.g. processes, actors) running concurrently to the clock. We want them to coordinate with the clock and not to go out of time.

The user must take two precautions:

1. Actors must register (`push!`) their message channels to the clock and the clock will only proceed to the next event if all registered channels are empty.
2. Tasks use `now!` for IO-operations or `print` via the clock.

## Parallel clocks

With multithreading and tasks running in parallel we want to maintain the order of cause and effect and to avoid than an event scheduled for a time ``t_{i+1}`` executes on a parallel thread *before* an event scheduled for ``t_i`` completes.

In parallel simulations we take at least four steps in order to limit time skew and event disorder:

1. With thread local clocks we maintain a local order of events on each thread and
2. synchronize the local clocks often with the global clock on thread 1.
3. Users keep associated entities and events (subsystems) together on threads and
4. take care that distributed DES subsystems are sufficiently decoupled.

This is described at greater length in [distributed simulations](@ref distributed_simulations). Here we illustrate how to create and access parallel clocks:

```@repl
pc = PClock()           # create a master clock with parallel clocks
pc2 = pclock(pc, 2)     # access the active clock on thread 2
pc2.clock               # access the parallel clock on thread 2
pc2.clock.ac[]          # back to the active clock 2
pc2.clock.ac[].master[] # back to master on thread 1
```

Note that the master clock is a shared variable of active clock 2. This is an intermediate solution and will change soon. Otherwise the interaction between the global (master) clock on thread 1 and the parallel local clocks is happening via message channels. Parallel clocks have message channels to master but not to each other.

## Clock commands

[^1]: In essence we count the number of naturally occurring periodic events to measure time: the revolutions of a moon or planet, our heart beats, the swings of a pendulum … or more advanced measurement methods.
