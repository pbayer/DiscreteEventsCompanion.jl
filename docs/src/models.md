# Modeling

```math
\begin{aligned}
\hspace{5em} && \textit{All models are wrong. Some are useful. (George Box)}
\end{aligned}
```

We have seen different approaches in modeling *discrete event systems (DES)* for simulation. Most of them are limiting in some way. But `DiscreteEvents` provides a simple, yet versatile and powerful grammar for combining them.

- **Sampling**: for periodic actions,
- **Event scheduling**: for scheduling single events at given times or under given conditions,
- **Activities**: for expressing an event and the time until another event as an overlapping activities in a system,
- **Processes**: for expressing entities with typical sequences of events interacting in a system,
- **State Machines**: for expressing entities reacting differently to events based on their current state,
- **Actor systems**: for representing systems consisting of multiple nested and parallel interacting components.

The following examples show how those different approaches to modeling DES can be employed and combined.
