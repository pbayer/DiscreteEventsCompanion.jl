#
# This file is part of the DiscreteEventsCompanion.jl Julia package, MIT license
#
# This example illustrates the state-based approach
#
using DiscreteEvents, Printf, Random, Distributions

const p = 0.3

abstract type 𝑋 end    # define states
struct Idle <: 𝑋 end
struct Busy <: 𝑋 end

abstract type Γ end    # events
struct Load <: Γ end
struct Release <: Γ end

mutable struct Server  # state machine body
    id::Int
    c::Clock
    state::𝑋
    job::Int
end

ex = Exponential()
jobno = 1

queue = Vector{Int}()
done  = Vector{Int}()
Base.isready(x::Array) = !isempty(x)

# transition functions
function 𝒇(A::Server, ::Idle, ::Load)
    A.job = pop!(queue)
    A.state = Busy()
    @printf("%5.2f: server %d took job %d\n", tau(A.c), A.id, A.job)
    event!(A.c, fun(𝒇, A, A.state, Release()), after, rand(ex))
end

function 𝒇(A::Server, ::Busy, ::Release)
    if rand() > p
        push!(queue, A.job)
    else
        pushfirst!(done, A.job)
        @printf("%5.2f: server %d finished job %d\n", tau(A.c), A.id, A.job)
    end
    A.job = 0
    A.state=Idle()
    event!(A.c, fun(𝒇, A, A.state, Load()), fun(isready, queue))
end

function 𝒇(A::Server, 𝑥::𝑋, γ::Γ)       # catch all
    println(stderr, "$(A.name) $(A.id) undefined transition $𝑥, $γ")
end

Random.seed!(123)
c = Clock()

A = [Server(i, c, Idle(), 0) for i ∈ 1:8]
for i ∈ shuffle(1:8)
    event!(c, fun(𝒇, A[i], A[i].state, Load()), fun(isready, queue))
end

event!(c, (fun(pushfirst!, queue, ()->jobno), ()->global jobno += 1), every, rand(ex))

run!(c, 10)
