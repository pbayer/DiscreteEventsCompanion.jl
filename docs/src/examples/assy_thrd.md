# Multi-Threaded Assembly

An assembly line in a car or engine plant consists of several sections, which are decoupled by intermediary buffers for some cars or engines. Inside a section workers or work stations are more strongly coupled with buffers of one or two items in between. Usually those assembly lines are quite long with dozens or even hundreds of work stations.

This is an ideal scenario for a multithreaded simulation where we can simulate the sections on different threads, connected by channels of some capacity for decoupling. We assume that assembly operations have a normal distribution ``\mathcal{N}(\mu,\sigma^2)\;|\; \mu=1.0,\sigma=0.1`` constraining line throughput.

We will define an `assy` operation as a simple sequential process, an `assyLine` setting up ``N`` such operations with ``\textrm{buf}`` buffers between each two sequential work stations on a thread-local clock with thread id ``\textrm{thrd}`` it will run on. The arrival process is as usual.

```julia
using DiscreteEvents, Distributions, Random, Printf, .Threads

# describe an assembly process
function assy(c::Clock, input::Channel, output::Channel, S::Distribution, id::Int)
    job = take!(input)
    delay!(c, S)
    put!(output, job)
end

# setup an assembly line of N nodes between input and output
# buf is the buffer size between the nodes
function assyLine(c::Clock, input::Channel, output::Channel, 
                  S::Distribution, N::Int, buf::Int; thrd=1)
    inp = input
    out = N > 1 ? typeof(input)(buf) : output
    for i in 1:N
        process!(c, Prc(i, assy, inp, out, S, i), cid=thrd)
        inp = out
        out = i < (N-1) ? typeof(input)(buf) : output
    end
end

# arrivals
function arrive(c::Clock, input::Channel, jobno::Vector{Int}, A::Distribution)
    jobno[1] += 1
    delay!(c, A)
    put!(input, jobno[1])
end
```

We seed the default random number generators on each thread with `pseed`, setup a `PClock` with parallel clocks, create input and output buffers for the entire line and the buffers between the sections. For simplicity we take the number of threads `nthreads()` of our local machine as the number of sections of our assembly line.
We setup an `assyLine` section on each thread connected by buffers. Then we start the `arrive` process on the master clock of thread 1.

```julia
pseed!(123)
const M₁ = Exponential(1/0.9)
const M₂ = Normal(1, 0.1)
const jobno = [4]

clk = PClock(0.1)
input = Channel{Int}(10)
buffer = [Channel{Int}(10) for _ in 2:nthreads()]
output = Channel{Int}(Inf)
foreach(i->put!(input, i), 1:3)
for i in 1:nthreads()
    inp = i == 1 ? input : buffer[i-1]
    out = i < nthreads() ? buffer[i] : output
    assyLine(clk, inp, out, M₂, 10, 2, thrd=i)
end
process!(clk, Prc(0, arrive, input, jobno, M₁))
```

If we run the simulation, we get the following output:

```julia
julia> @time run!(clk, 1000)
  1.582942 seconds (5.72 M allocations: 284.722 MiB, 2.65% gc time)
"run! finished with 63452 clock events, 10000 sample steps, simulation time: 1000.0"

julia> length(output)
748
```

It took 1.6 seconds for an assembly line with 8 sections of each 10 workstations to simulate a throughput of 748 cars/engines.

Below I give the platform information:

```julia
julia> versioninfo()
Julia Version 1.5.1
Commit 697e782ab8 (2020-08-25 20:08 UTC)
Platform Info:
  OS: macOS (x86_64-apple-darwin19.5.0)
  CPU: Intel(R) Core(TM) i9-9880H CPU @ 2.30GHz
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-9.0.1 (ORCJIT, skylake)
Environment:
  JULIA_NUM_THREADS = 8
  JULIA_EDITOR = "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
```
