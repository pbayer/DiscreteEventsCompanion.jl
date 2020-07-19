# Clocks

In physics and most of life we [measure time](https://en.wikipedia.org/wiki/Time_in_physics) with a clock [^1]. An event sequence Γ = {γ₁, γ₂, ...} has measured times t₁ < t₂ < ... From that we draw inferences about causality and dependencies.

A [`Clock`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#Clocks-1) in `DiscreteEvents` registers events and triggers them at given times or under given conditions. It doesn't measure time, it owns time. We can create clocks, run them for a while, stop time, step through time, skip from event to event, change event sequences … With it we can create, model or simulate discrete event systems (DES).

## Virtual clocks

Virtual clocks are not constrained by any physical time measurement. They don't have to wait an hour for the next event to occur, but can right jump to it. Time is only a number and the computer executes an event sequence as fast as possible.

```julia
julia> using DiscreteEvents

julia> clk = Clock()
Clock 0, thrd 1 (+ 0 ac): state=DiscreteEvents.Undefined(), t=0.0 , Δt=0.01 , prc:0
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

Here we have created a real time clock with id=99 on thread 8. It has a clock period of T=0.01 s and synchronizes at that resolution with the system clock running in ns. When the start message was created, the clock had just advanced 0.0001193 s. When we query its time thereafter, it returns the time in seconds passed since startup:

```julia
julia> tau(rtc)         # query time
14.045107885001926

julia> rtc.time         # synonymous way to get time
17.910258978001366
```

We can schedule events to real time clocks as to virtual clocks and they will execute at their due time.

## Parallel clocks

## Clock commands

## Diagnosis

As usual in Julia you can access clock parameters by `clock.parameter`:

```julia
julia> clk                  # normally pretty printing is enabled
Clock 0, thread 1 (+ 0 ac): state=DiscreteEvents.Undefined(), t=0.0 , Δt=0.01 , prc:0
  scheduled ev:0, cev:0, sampl:0


julia> clk.                 # with clk. + tab + tab you get the parameters
ac        end_time   evcount    id         processes  sc         scount     state      tev        time       tn         unit       Δt
julia> clk.time             # then you can select one of them
0.0
```

You can switch off pretty printing and then get the Julia `Base.show_default` display:

```julia
julia> DiscreteEvents.prettyClock(false)

julia> clk
Clock(0, DiscreteEvents.Undefined(), 0.0, , 0.01, DiscreteEvents.ClockChannel[], DiscreteEvents.Schedule(DataStructures.PriorityQueue{DiscreteEvents.DiscreteEvent,Float64,Base.Order.ForwardOrdering}(), DiscreteEvents.DiscreteCond[], DiscreteEvents.Sample[]), Dict{Any,Prc}(), 0.01, 0.0, 0.0, 0, 0)
```

In [Juno](http://docs.junolab.org/)'s workspace then you can access a `Clock` variable's structure and dig deeper into it:

![atom workspace](img/clock.png)


[^1]: In essence we count the number of naturally occurring periodic events to measure time: the revolutions of a moon or planet, our heart beats, the swings of a pendulum … Sure enough our measurement methods have advanced.
