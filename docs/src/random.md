# Randomness

The elements introduced so far (clocks, events and processes) let us describe event sequences in discrete event systems (DES). In reality those sequences often show considerable randomness and come out starkly different with varying initial conditions or intervening random events.   

If we are interested in the stochastic nature of DES, we can follow Cassandras [^1] and model them as stochastic timed automata ``(\mathcal{E},\mathcal{X},\Gamma,p,p_0,G)`` where

```math
\begin{array}{rl}
  \mathcal{E} & \textrm{countable event set} \\
  \mathcal{X} & \textrm{countable state space} \\
  \Gamma(x)   & \textrm{feasible or enabled events}: x \in \mathcal{X}, \Gamma(x) \subseteq \mathcal{E} \\
  p(x';x,e')  & \textrm{state transition probability}: x,x' \in \mathcal{X}, e' \in \mathcal{E} \\
  p_0(x)      & \textrm{pmf}\ P[X_0=x]: x \in \mathcal{X}, X_o \textrm{initial state} \\
  G_i         & \textrm{stochastic clock structure}: i \in \mathcal{E}
\end{array}
```

Everything in this definition can be expressed by combining

- clock, events and processes of `DiscreteEvents`,
- Julia's multiple dispatch and
- using the `Distributions` package.

## Automata

The feasible event function ``\Gamma(x)`` expresses the fact that events are conditional on states or that in a given state ``x`` only certain events ``\Gamma(x) \subseteq \mathcal{E}`` can happen. Julia's multiple dispatch provides a powerful feature to implement the transition function ``\mathcal{f}(x, \gamma)`` and implicitly ``\Gamma(x)``.

The process to do it is:

1. define the event set ``\,\mathcal{E} = \{\alpha, \beta, \gamma, ...\}``,
2. define the state space ``\,\mathcal{X}=\{x_i, x_j, ..., x_n\}``,
3. define all allowed transition functions ``\,\mathcal{f}(x_1, \{\alpha,\beta\}), \mathcal{f}(x_2, \gamma), ...``,
4. define a default transition function ``\,\mathcal{f}(\mathcal{X},\mathcal{E})`` doing nothing.

Since Julia specialises its function calls, it calls the default transition function  if an allowed transition is not defined. This eliminates the need to check for and delete previously scheduled events.

For example if a (modeled) server `S` breaks down randomly and takes on a state `Failed`, it cannot accept a previously scheduled event `finish_job`. If we have defined correctly the transition function `𝒇(S, Busy, finish_job)` and the default transition function, an event `𝒇(S, Failed, finish_job)` triggers the default transition and is simply ignored. 

## Random variables

Random initial states, transition probabilities or random times can simply be computed by calling `rand(d)` on a [distribution](https://juliastats.org/Distributions.jl/stable/types/#Distributions-1) `d` from the [`Distributions`](https://juliastats.org/Distributions.jl/stable/) package.

[^1]:  Cassandras, Lafortune: Introduction to Discrete Event Systems, Springer, 2008, p 334 f.
