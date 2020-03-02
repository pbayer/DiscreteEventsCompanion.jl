# Internals

## Clocks

`DiscreteEvents.jl` contains several clock types: [`Clock`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.Clock), [`ActiveClock`]https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.ActiveClock) and [`RTClock`](https://pbayer.github.io/DiscreteEvents.jl/dev/usage/#DiscreteEvents.RTClock). They are implemented as state machines. Their implementation are internal and not exported.
