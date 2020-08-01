# Clocks

In physics and most of life we [measure time](https://en.wikipedia.org/wiki/Time_in_physics) with a clock ``C`` [^1]. An event sequence ``\;S = \{e_1, e_2, ..., e_n\}\;`` has measured times ``\;t_1 < t_2 < ... < t_n``. From that order we draw inferences about causality and dependencies.

A [`Clock`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#Clocks-1) in `DiscreteEvents` schedules events and triggers them at given times or under given conditions. It doesn't measure time, it "owns" time. We can create clocks, run them for a while, stop time, step through time, skip from event to event, change event sequences … With it we can create, model or simulate discrete event systems (DES).

## Virtual clocks

Virtual clocks are not constrained by physical time. They don't have to wait an hour for the next event to occur, but can right jump to it. Time is only a number and the computer executes an event sequence as fast as possible.

```julia
julia> using DiscreteEvents

julia> clk = Clock()
Clock 0, thread 1 (+ 0 ac): state=DiscreteEvents.Undefined(), t=0.0 , Δt=0.01 , prc:0
  scheduled ev:0, cev:0, sampl:0
```

We created a new clock, running on thread 1, having time t=0.0, a sampling rate of Δt=0.01, no registered processes, no scheduled events, conditional events or sampling actions.

```julia
julia> run!(clk, 10)
"run! finished with 0 clock events, 0 sample steps, simulation time: 10.0"
```

If we run the clock for Δt=10, it jumps immediately ahead since it has nothing to do.

### Time units

## Real time clocks

A real time clock [`RTClock`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.RTClock) is bound to the computer's physical clock and measures time in seconds [s]. We create and start it with [`createRTClock`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.RTClock)

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

We can schedule events to real time clocks as to virtual clocks and they will execute at their due time.

## Parallel clocks

## Clock commands

[^1]: In essence we count the number of naturally occurring periodic events to measure time: the revolutions of a moon or planet, our heart beats, the swings of a pendulum … Sure enough our measurement methods have advanced.
