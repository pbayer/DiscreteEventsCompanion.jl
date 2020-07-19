# A hybrid system

In a hybrid system we have continuous processes and discrete events interacting in one system. A thermostat or a house heating system is a basic example of this:

- Heating changes between two states: On and Off. The thermostat switches heating on if romm temperature `Tr` is greater or equal 23°C, it switches off if temperature falls below 20°C.
- A room cools at a rate proportional to the difference between room temperature `Tr` and environment temperature `Te`.
- It heats at a rate proportional to the temperature difference between temperature of the heating fluid `Th` and room temperature `Tr`.
- The room temperature `Tr` changes proportional to the difference between heating and cooling.

First we setup the physical model with some assumptions:


```julia
using DiscreteEvents, Plots, DataFrames, Random, Distributions, LaTeXStrings

const Th = 40     # temperature of heating fluid
const R = 1e-6    # thermal resistance of room insulation
const α = 2e6     # represents thermal conductivity and capacity of the air
const β = 3e-7    # represents mass of the air and heat capacity
η = 1.0           # efficiency factor reducing R if doors or windows are open
heating = false   # initially the heating is off

Δte(t, t1, t2) = cos((t-10)*π/12) * (t2-t1)/2  # change rate of a sinusoidal Te

function Δtr(Tr, Te, heating)
    Δqc = (Tr - Te)/(R * η)             # cooling rate
    Δqh = heating ? α * (Th - Tr) : 0   # heating rate
    return β * (Δqh - Δqc)              # change of room temperature
end
```
Δtr (generic function with 1 method)

We setup a simulation for 24 hours from 0am to 12am. We update the simulation every virtual minute.


```julia
reset!(𝐶)                               # reset the clock
rng = MersenneTwister(122)              # set random number generator
Δt = 1//60                              # evaluate every minute
Te = 11                                 # starting values
Tr = 20
df = DataFrame(t=Float64[], tr=Float64[], te=Float64[], heating=Int64[])

function setTemperatures(t1=8, t2=20)   # define a sampling function
    global Te += Δte(tau(), t1, t2) * 2π/1440 + rand(rng, Normal(0, 0.1))
    global Tr += Δtr(Tr, Te, heating) * Δt
    push!(df, (tau(), Tr, Te, Int(heating)) )
end

function switch(t1=20, t2=23)           # a function simulating the thermostat
    if Tr ≥ t2
        global heating = false
        event!(fun(switch, t1, t2), @val :Tr :≤ t1)  # setup a conditional event
    elseif Tr ≤ t1
        global heating = true
        event!(fun(switch, t1, t2), @val :Tr :≥ t2)  # setup a conditional event
    end
end

periodic!(fun(setTemperatures), Δt)        # setup the sampling function
switch()                                   # start the thermostat

@time run!(𝐶, 24)                          # run the simulation
```
0.040105 seconds (89.21 k allocations: 3.435 MiB)\
"run! finished with 0 clock events, 1440 sample steps, simulation time: 24.0"

```julia
plot(df.t, df.tr, legend=:bottomright, label=L"T_r")
plot!(df.t, df.te, label=L"T_e")
plot!(df.t, df.heating, label="heating")
xlabel!("hours")
ylabel!("temperature")
title!("House heating undisturbed")
```




![svg](examples/house_heating/output_4_0.svg)



Now we have people entering the room or opening windows and thus reducing thermal resistance:


```julia
function people()
    delay!(6 + rand(Normal(0, 0.5)))         # sleep until around 6am
    sleeptime = 22 + rand(Normal(0, 0.5))    # calculate bed time
    while tau() < sleeptime
        global η = rand()                    # open door or window
        delay!(0.1 * rand(Normal(1, 0.3)))   # for some time
        global η = 1.0                       # close it again
        delay!(rand())                       # do something else
    end
end

reset!(𝐶)
rng = MersenneTwister(122)
Random.seed!(1234)
Te = 11
Tr = 20
df = DataFrame(t=Float64[], tr=Float64[], te=Float64[], heating=Int64[])

for i in 1:2                                 # put 2 people in the house
    process!(Prc(i, people), 1)               # run process only once
end
periodic!(fun(setTemperatures), Δt)    # setup sampling
switch()                                     # start the thermostat

@time run!(𝐶, 24)
```
0.114938 seconds (72.52 k allocations: 2.320 MiB)\
"run! finished with 116 clock events, 1440 sample steps, simulation time: 24.0"




```julia
plot(df.t, df.tr, legend=:bottomright, label=L"T_r")
plot!(df.t, df.te, label=L"T_e")
plot!(df.t, df.heating, label="heating")
xlabel!("hours")
ylabel!("temperature")
title!("House heating with people")
```




![svg](examples/house_heating/output_7_0.svg)



We have now all major schemes: events, continuous sampling and processes combined in one example.

**see also**: the [full house heating example](examples/house_heating/house_heating.md) for further explanations.
