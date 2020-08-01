# Sampling

The simplest mechanism for generating [discrete events](events.md) is to have a [clock](clocks.md) `clk` execute an action `𝜸` periodically. We can generate periodic events in various ways:

- sampling events with `periodic!(clk, 𝜸, Δt)` are executed at the clock sample rate `Δt`,
- repeating events with `event!(clk, 𝜸, every, Δt)` are executed every given interval `Δt`,
- conditional events with `event!(clk, 𝝃, 𝜸)` check the condition `𝜸` at the clock's sample rate `Δt` until it returns `true`. Then `𝝃` is executed.

Thus we can model periodic events but no stochastic event sequences. Sampling is useful if we want to model repeated or periodic events interacting with a DES, check conditions, trace or visualize the system periodically.

Sampling introduces a time uncertainty into simulations since it triggers changes, takes measurements or checks for conditions only at a given time interval Δt.
