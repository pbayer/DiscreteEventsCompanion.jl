using DiscreteEvents, YAActL, Random, DataStructures, Distributions, Printf

# define Messages
struct Setup <: Message end
struct Feed <: Message end
struct Take <: Message end
struct Finish <: Message end

mutable struct ServiceNode
    id::Int
    clk::Clock
    input::Resource  # input queue
    output::Resource # output queue
    src::Link        # link to source node actor
    act::Link        # link to node actor
    cst::Link        # link to customer node actor
    job::Int
    S::Distribution  # service time distribution
end
Base.copy(s::ServiceNode) = ServiceNode(s.id,s.clk,s.input,s.output,s.src,s.act,s.cst,s.job,s.S)

Base.get(clk::Clock, m::Message, after, Δt::Number) =
    event!(clk, (fun(send!, self(), m), yield), after, Δt)

# single service node behaviors 
setup(s::ServiceNode, ::Setup) = become(idle, s)
idle(s::ServiceNode, ::Message) = nothing
function idle(s::ServiceNode, ::Feed)
    if !isempty(s.input)
        s.job = popfirst!(s.input)
        send!(s.src, Take())
        become(busy, s)
        get(s.clk, Finish(), after, rand(s.S))
        print(s.clk, @sprintf("%5.3f: %d working on job %d\n", tau(s.clk), s.id, s.job))
    end
end
busy(s::ServiceNode, ::Message) = nothing
function busy(s::ServiceNode, ::Finish)
    print(s.clk, @sprintf("%5.3f: %d finished job %d\n", tau(s.clk), s.id, s.job))
    if !isfull(s.output)
        push!(s.output, s.job)
        send!((s.cst,self()), Feed())
        become(idle, s)
    else
        print(s.clk, @sprintf("%5.3f: %d now blocked\n", tau(s.clk), s.id))
        become(blocked, s)
    end
end
blocked(s::ServiceNode, ::Message) = nothing
blocked(s::ServiceNode, ::Take) = busy(s, Finish())

# model arrivals
function arrivals(clk::Clock, queue::Resource, lnk::Link, N::Int, A::Distribution)
    for i = 1:N # initialize customers
        delay!(clk, rand(A))
        push!(queue, i)
        print(clk, @sprintf("%5.3f: job %d arrived\n", tau(clk), i))
        send!(lnk, Feed())  # notify the next service node
    end
end

consume(::Message) = nothing

Random.seed!(8710)          # set random number seed for reproducibility
const N = 10                # total number of customers
const μ = 1.0               # service rate
const λ = 0.9               # arrival rate
const M₁ = Exponential(1/λ) # interarrival time distribution
const M₂ = Exponential(1/μ) # service time distribution

clk = Clock()
input  = Resource{Int}()
output = Resource{Int}()
source = Actor(consume)
sink   = Actor(consume)

sn = ServiceNode(4711,clk,input,output,source,Link(),sink,0,M₂)
sn.act = Actor(setup, sn)
register!(clk.channels, sn.act)
send!(sn.act, Setup())
process!(clk, Prc(0,arrivals,input,sn.act,N,M₁), 1)
run!(clk, 20)
