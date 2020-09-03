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

pseed!(123)
const M₁ = Exponential(1/0.9)
const M₂ = Normal(1, 0.1)
const jobno = [4]

clk = PClock(0.1)
input = Channel{Int}(10)
buffer = [Channel{Int}(10) for _ in 2:nthreads()]
output = Channel{Int}(Inf)
foreach(i->put!(input, i), 1:3)
assyLine(clk, input, buffer[1], M₂, 10, 2, thrd=2)
for i in 2:nthreads()
    inp = buffer[i-1]
    out = i < nthreads() ? buffer[i] : output
    assyLine(clk, inp, out, M₂, 10, 2, thrd=i)
end
process!(clk, Prc(0, arrive, input, jobno, M₁))

@time run!(clk, 1000)
