# Internals

```@meta
CurrentModule = DiscreteEventsCompanion
```

## Clocks

`Simulate.jl` contains several clock types: [`Clock`](https://pbayer.github.io/Simulate.jl/dev/usage/#Simulate.Clock), [`ActiveClock`]https://pbayer.github.io/Simulate.jl/dev/usage/#Simulate.ActiveClock) and [`RTClock`](https://pbayer.github.io/Simulate.jl/dev/usage/#Simulate.RTClock). They are implemented as state machines. Their implementation are internal and not exported.
