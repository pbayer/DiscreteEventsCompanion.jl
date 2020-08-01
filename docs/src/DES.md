# Discrete Event Systems

In studying and building discrete event systems (DES) we find, analyze or generate timed sequences of events

```math
\{(e_1,t_1),(e_2,t_2),(e_3,t_3),\hspace{1em}...\hspace{1em}, (e_n,t_n)\}
```

Something ``e_i`` happens at a time ``t_i``, then another event happens later and so on. From the sequence of events we draw inferences about causality. But times and sequences change due to the often stochastic nature of those systems.

We can follow Cassandras [^1] and view DES as stochastic timed automata ``(\mathcal{E},\mathcal{X},\Gamma,p,p_0,G)`` where

```math
\begin{array}{rl}
  \mathcal{E} & \textrm{countable event set} \\
  \mathcal{X} & \textrm{countable state space} \\
  \Gamma(x)   & \textrm{feasible event function}: x \in \mathcal{X}, \Gamma(x) \subseteq \mathcal{E} \\
  p(x';x,e')  & \textrm{state transition probability}: x,x' \in \mathcal{X}, e' \in \mathcal{E} \\
  p_0(x)      & \textrm{pmf}\ P[X_0=x]: x \in \mathcal{X}, X_o \textrm{initial state} \\
  G_i         & \textrm{stochastic clock structure}: i \in \mathcal{E}
\end{array}
```

We want to model DES correctly in order to analyze and to understand them. So our approach must be able to express computationally all elements in the above definition:

- ``\Gamma(x)`` means that not all events cause a system to change in a given situation or state,
- ``p(x';x,e'), p_0(x), G_i`` mean that changes, initial states and times or time intervals often are uncertain.

`DiscreteEvents` builds on [`Julia`](https://www.julialang.org) and aims to provide a fresh and modern approach to model and analyse 1) event sequences, 2) the timing and the 3) stochastic nature of discrete event systems.

In the following pages we introduce how to setup clocks, define actions, ... schedule events, build timed automata and much more.

[^1]:  Cassandras, Lafortune: Introduction to Discrete Event Systems, Springer, 2008, p 334 f.
