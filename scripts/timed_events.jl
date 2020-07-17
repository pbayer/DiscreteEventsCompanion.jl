using DiscreteEvents, Plots

c = Clock()
a = [0]
x = Float64[]; ya = Float64[]

event!(c, ()->a[1]+=1, 1)
event!(c, ()->a[1]=4, after, 5)
event!(c, fun(event!, c, ()->a[1]+=1, every, 1), at, 5)
event!(c, ()->(push!(x,tau(c)); push!(ya, a[1])), every, 0.01)

run!(c, 10.1)
plot(x, ya, linetype=:steppost, xlabel="t", ylabel="a", legend=false)

# savefig("img/tev.png")
