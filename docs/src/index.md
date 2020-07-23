# Overview

This is the companion site to [`DiscreteEvents.jl`](https://pbayer.github.io/DiscreteEvents.jl/dev/). It is a documentation in development, still not and possibly never perfect.

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
