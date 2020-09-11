#
# This file is part of the DiscreteEventsCompanion.jl Julia package, MIT license
#
# This example illustrates simple event scheduling
#

using DiscreteEvents, Distributions, Random

Random.seed!(030)

chit() = print(".")
chat() = print(":")

c = Clock()
event!(c, chit, every, Exponential(), n=8)
event!(c, chat, every, Exponential(), n=8)
event!(c, println, after, 10)
run!(c, 10)
