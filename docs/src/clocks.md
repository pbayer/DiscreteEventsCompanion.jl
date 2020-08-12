# Clocks

We think of a clock as a device to [measure time](https://en.wikipedia.org/wiki/Time_in_physics)   [^1]. An event sequence ``\;S = \{e_1, e_2, ..., e_n\}\;`` has measured times ``\;t_1 < t_2 < ... < t_n``. From that order we draw inferences about causality.

A [`Clock`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#Clocks-1) in `DiscreteEvents` schedules events and triggers them at given times or under given conditions. It doesn't measure, it represents time. We can create a clock, run it for a while, stop time, step through time, skip from event to event, change event sequences … With it we can create, model or simulate discrete event systems (DES).

## Virtual clocks

A virtual clock is not constrained by physical time. It doesn't wait a physical time period for the next event to occur, but jumps right to it. It executes an event sequence as fast as possible.

```julia
julia> using DiscreteEvents

julia> clk = Clock()
Clock 0, thread 1 (+ 0 ac): state=DiscreteEvents.Undefined(), t=0.0 , Δt=0.01 , prc:0
  scheduled ev:0, cev:0, sampl:0
```

We created a new clock, running on thread 1, having time ``t=0.0``, a sampling rate of ``Δt=0.01``, no registered processes, no scheduled events, conditional events or sampling actions.

```julia
julia> run!(clk, 10)
"run! finished with 0 clock events, 0 sample steps, simulation time: 10.0"
```

If we run the clock for a duration ``Δt=10``, it jumps immediately ahead since it has nothing to do.

### Time units

## Real time clocks

A real time clock [`RTClock`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.RTClock) is bound to the computer's physical clock and measures time in seconds ``[s]``. We create and start it with [`createRTClock`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.RTClock)

```julia
julia> rtc = createRTClock(0.01, 99)
Real time clock 99 on thread 8: state=DiscreteEvents.Idle(), t=0.0001193 s, T=0.01 s, prc:0
   scheduled ev:0, cev:0, sampl:0
```

Here we have created a real time clock with id=99 on thread 8. It has a clock period of T=0.01 s and synchronizes at that resolution with the system clock running in nano-seconds. When the start message was created, the clock had just advanced 0.0001193 s. When we query its time thereafter, it returns the time in seconds passed since startup:

```julia
julia> tau(rtc)         # query time
14.045107885001926

julia> rtc.time         # synonymous way to get time
17.910258978001366
```

We can schedule events to real time clocks as to virtual clocks and they will execute at their due physical time.

## [Clock concurrency](@id clock_concurrency)

`DiscreteEvents` can represent entities in DES as processes or actors running as asynchronous tasks. Those tasks run concurrently to the clock. If a task after activation by the clock gives control back to the Julia scheduler (e.g. by reading from a channel or by doing an IO-operation), it enqueues for its next schedule behind the clock. The clock may then increment time to ``t_{i+1}`` before the task can finish its job at current event time ``t_i``.

There are several ways to solve this problem:

1. The clock does a 2ⁿᵈ `yield()` after invoking a task and enqueues again at the end of the scheduling queue. This is implemented for `delay!` and `wait!` of processes and should be enough for most those cases.
2. Actors `push!` their message channel to the `clock.channels` vector and the clock will only proceed to the next event if all registered channels are empty [^2].
3. Asynchronous tasks use `now!` to let the clock do IO-operations for them. They can also `print` via the clock.

## Parallel clocks

The situation gets worse with multithreading and tasks running in parallel. To maintain the order of cause and effect we want to avoid than an event scheduled for a time ``t_{i+1}`` executes on a parallel thread *before* an event scheduled for ``t_i`` completes.

In short we take at least four steps to distribute simulations of DES over multiple threads in order to introduce not too much skew into the ordering of events:

1. By introducing parallel clocks we maintain a local order of events on each thread and
2. synchronize the parallel clocks often.
3. A user keeps associated entities and events (subsystems) together on a thread and
4. takes care that distributed DES subsystems are sufficiently decoupled.

This is described at greater length in [distributed simulations](@ref distributed_simulations). Here we illustrate how to create parallel clocks:

```julia
```

## Clock commands

[^1]: In essence we count the number of naturally occurring periodic events to measure time: the revolutions of a moon or planet, our heart beats, the swings of a pendulum … or more advanced measurement methods.
[^2]: In [`YAActL`](https://github.com/pbayer/YAActL.jl) you can  `register!` to a `Vector{Channel}`. To register actors is also useful for diagnosis.
