# Overview

This is the companion site to [`DiscreteEvents.jl`](https://pbayer.github.io/DiscreteEvents.jl/dev/). It is a documentation in development, still not and possibly never perfect about

- [**Clocks**](clocks.md): clock structures for discrete event systems (DES),
- [**Events**](events.md): how to generate events,
- [**Processes**](processes.md): how to define and start processes,
- [**Randomness**](random.md): how to express stochasticity,
- [**Models**](models.md): approaches to modeling and simulation,
- [**A hybrid system**](hybrid.md): combining the approaches,
- [**Examples**](examples/examples.md): examples to look at and learn from,
- [**Performance**](performance.md): good performance for simulations,
- [**Parallel simulation**](parallel.md): parallelizing simulations,
- [**Benchmarks**](benchmarks.md): some speed measurements,
- [**Internals**](internals.md): internal functions

## Quick Intro

With `DiscreteEvents` you can schedule and run Julia functions and expressions as *events* on a timeline represented by a *clock*:

```julia
using DiscreteEvents, Distributions, Random

Random.seed!(123)
ex = Exponential()

chit(c) = (print("."), event!(c, fun(chat, c), after, rand(ex)))
chat(c) = (print(":"), event!(c, fun(chit, c), after, rand(ex)))

c = Clock()
event!(c, fun(chit, c), after, rand(ex))
event!(c, println, at, 10)
run!(c, 10)
```
```
.:.:.:.:.:.:.:.:.
"run! finished with 18 clock events, 0 sample steps, simulation time: 10.0"
```


**Author:** Paul Bayer
**License:** MIT
