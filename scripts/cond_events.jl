using DiscreteEvents, Plots

c = Clock()
a = [0.0]; b = [0]
x = Float64[]; ya = Float64[]; yb = Float64[]

event!(c, ()->a[1]=tau(c)^2, every, 0.1)
event!(c, ()->b[1]=25, ()->a[1]≈25)
event!(c, ()->(push!(x,tau(c)); push!(ya,a[1]); push!(yb,b[1])), every, 0.01)

run!(c, 10)
plot(x, ya, xlabel="t", ylabel="y", label="a", legend=:topleft)
plot!(x, yb, label="b")

# savefig("img/cev.png")
