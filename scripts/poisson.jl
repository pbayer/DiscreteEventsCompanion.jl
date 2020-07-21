using DiscreteEvents, Random, Distributions, Plots

Random.seed!(1234)    # set random number seed for reproducibility
const λ = 10          # arrival rate 10 customers per hour
const ρ = log(0.2)/10 # decay rate for customer arrivals
D = Exponential(1/λ)  # interarrival time distribution

hpp  = [0]            # counting homogeneous arrivals
nhpp = [0]            # counting non-homogeneous arrivals
t = Float64[]         # tracing variables
y1 = Int[]
y2 = Int[]

δ(t) = Int(rand() ≤ exp(ρ*t))        # time dependent decay of arrivals
trace(c) = (push!(t, c.time); push!(y1, hpp[1]); push!(y2, nhpp[1]))

# define two arrival functions
#       |   count             | schedule next arrival
arr1(c) = (hpp[1] += 1;         event!(c, fun(arr1, c), after, rand(D)))
arr2(c) = (nhpp[1]+= δ(c.time); event!(c, fun(arr2, c), after, rand(D)))

# create clock, schedule events and tracing and run
c = Clock()
event!(c, fun(arr1, c), after, rand(D))  # HPP arrivals (grocery store)
event!(c, fun(arr2, c), after, rand(D))  # NHPP (bakery)
periodic!(c, fun(trace, c))
run!(c, 10)

plot(t, y1, label="grocery", xlabel="hours", ylabel="customers", legend=:topleft)
plot!(t, y2, label="bakery")

# savefig("img/poisson.png")
