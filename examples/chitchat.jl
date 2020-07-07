#
# This file is part of the DiscreteEventsCompanion.jl Julia package, MIT license
#
# This example illustrates simple event scheduling
#

using DiscreteEvents, Distributions, Random

Random.seed!(123)
ex = Exponential()

chit(c) = (print("."), event!(c, fun(chat, c), after, rand(ex)))
chat(c) = (print(":"), event!(c, fun(chit, c), after, rand(ex)))

c = Clock()
chit(c)
run!(c, 10)