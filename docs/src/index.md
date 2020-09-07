# Overview

This is the companion site to [`DiscreteEvents.jl`](https://pbayer.github.io/DiscreteEvents.jl/dev/). It is a documentation in development, still not and possibly never perfect.

## Quick Intro

With `DiscreteEvents` you can schedule and run Julia functions and expressions as *events* on a timeline represented by a *clock*:

```julia
using DiscreteEvents, Distributions, Random

Random.seed!(030)
ex = Exponential()

chit() = print(".")
chat() = print(":")

c = Clock()
event!(c, chit, every, ex, n=8)
event!(c, chat, every, ex, n=8)
event!(c, println, after, 10)
```

Now this gives us two independent Poisson processes chitting and chatting on the console:

```julia
julia> run!(c, 10)
.:..::.:.:...:::
"run! finished with 17 clock events, 0 sample steps, simulation time: 10.0"
```

**Author:** Paul Bayer
**License:** MIT
