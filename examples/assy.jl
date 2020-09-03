using DiscreteEvents, Distributions, Random, Printf

# describe an assembly process
function assy(c::Clock, input::Channel, output::Channel, S::Distribution, id::Int)
    job = take!(input)
    # print(clk, @sprintf("%5.3f: assy %d does job %d\n", tau(clk), id, job))
    delay!(c, S)
    # print(clk, @sprintf("%5.3f: assy %d finished job %d\n", tau(clk), id, job))
    put!(output, job)
end

# setup an assembly line of N nodes between input and output
# buf is the buffer size between the nodes
function assyLine(c::Clock, input::Channel, output::Channel, S::Distribution, N::Int, buf::Int)
    inp = input
    out = N > 1 ? typeof(input)(buf) : output
    for i in 1:N
        process!(c, Prc(i, assy, inp, out, S, i))
        inp = out
        out = i < (N-1) ? typeof(input)(buf) : output
    end
end

# arrivals
function arrive(c::Clock, input::Channel, jobno::Vector{Int}, A::Distribution)
    jobno[1] += 1
    delay!(c, A)
    put!(input, jobno[1])
    # print(clk, @sprintf("%5.3f: job %d arrived\n", tau(clk), jobno[1]))
end

Random.seed!(123)
const M₁ = Exponential(1/0.9)
const M₂ = Normal(1, 0.1)
const jobno = [4]

clk = Clock()
input = Channel{Int}(10)
output = Channel{Int}(Inf)
foreach(i->put!(input, i), 1:3)
assyLine(clk, input, output, M₂, 10, 2)
process!(clk, Prc(0, arrive, input, jobno, M₁))

run!(clk, 1000)
