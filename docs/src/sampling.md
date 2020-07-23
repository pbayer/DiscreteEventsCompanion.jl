# Sampling

The simplest mechanism for generating [discrete events](events.md) is to have a [clock](clocks.md) `clk` executing a function `𝑓` periodically. We can generate periodic events in various ways:

- sampling events with `periodic!(clk, 𝑓, Δt)` are executed at the clock sample rate `Δt`,
- repeating events with `event!(clk, 𝑓, every, Δt)` are executed every given interval `Δt`,
- conditional events with `event!(clk, 𝒈, 𝑓)` check the condition `𝑓` at the clock's sample rate `Δt` until it returns `true`. Then `𝑔` is executed.

Thus we can model periodic events but no stochastic event sequences, characteristic of DES. Sampling is useful if we want to model repeated or periodic events interacting with a DES, check conditions, trace or visualise the system periodically.

Sampling introduces a time uncertainty into simulations since it triggers changes, takes measurements or checks for conditions only at a given time interval Δt.
