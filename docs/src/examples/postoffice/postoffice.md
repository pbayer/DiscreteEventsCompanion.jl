# A Post Office – A Real Life Story

*Paul Bayer, 2020-09-14, v0.4*

Let us begin with an everyday story: there is a small post office with one clerk serving the arriving customers. Customers have differing wishes leading to different serving times, from `1 - 5 minutes`. We have to add a little variation to serving times counting for variation in customer habits and clerk performance. The arrival rate of customers is about 18 per hour, every `3.33 minutes` or `3 minutes, 20 seconds` on average. Our post office is small and customer patience is limited, so queue length is limited to 5 customers. 

We have provided 10% extra capacity, so our expectation is that there should not be too many customers discouraged for long waiting times or for full queues.

![post office](PostOffice.png)

Let's do a process-based simulation using [`DiscreteEvents`](https://github.com/pbayer/DiscreteEvents.jl). We need 

1. a source: all the **people**, providing an unlimited supply for customers,
2. **customers** with their demands and their limited patience,
3. a **queue** and
4. our good old **clerk**.

First we must load the needed modules, describe a customer and define some needed helper functions. 


```julia
using DiscreteEvents, Random, Distributions, DataFrames

mutable struct Customer
    id::Int64
    arrival::Float64
    request::Int64

    Customer(n::Int64, arrival::Float64) = new(n, arrival, rand(DiscreteUniform(1, 5)))
end

full(q::Channel) = length(q.data) >= q.sz_max
logevent(nr, queue::Channel, info::AbstractString, wt::Number) =
    push!(df, (round(tau(), digits=2), nr, length(queue.data), info, wt))
```




    logevent (generic function with 1 method)



Then we define functions for our processes: people and clerk.


```julia
function people(clk::Clock, output::Channel, β::Float64)
    i = 1
    while true
        Δt = rand(Exponential(β))
        delay!(clk, Δt)
        if !full(output)
            put!(output, Customer(i, tau(clk)))
            logevent(i, output, "enqueues", 0)
         else
            logevent(i, output, "leaves - queue is full!", -1)
        end
        i += 1
    end
end

function clerk(clk::Clock, input::Channel)
    cust = take!(input)
    Δt = cust.request + randn()*0.2
    logevent(cust.id, input, "now being served", tau(clk) - cust.arrival)
    delay!(clk, Δt)
    logevent(cust.id, input, "leaves", tau(clk) - cust.arrival)
end
```




    clerk (generic function with 1 method)



Then we have to create out data, register and startup the processes:


```julia
resetClock!(𝐶)  # for repeated runs it is easier if we reset our central clock here
Random.seed!(2019)  # seed random number generator for reproducibility
queue = Channel(5)  # thus we determine the max size of the queue

df = DataFrame(time=Float64[], cust=Int[], qlen=Int64[], status=String[], wtime=Float64[])

process!(Prc(1, people, queue, 3.333)) # register the functions as processes
process!(Prc(2, clerk, queue))
```




    2



Then we can simply run the simulation. We assume our time unit being minutes, so we run for 600 units:


```julia
println(run!(𝐶, 600))
println("$(length(queue.data)) customers yet in queue")
```

    run! finished with 348 clock events, 0 sample steps, simulation time: 600.0
    0 customers yet in queue


Our table has registered it all:


```julia
df
```




<table class="data-frame"><thead><tr><th></th><th>time</th><th>cust</th><th>qlen</th><th>status</th><th>wtime</th></tr><tr><th></th><th>Float64</th><th>Int64</th><th>Int64</th><th>String</th><th>Float64</th></tr></thead><tbody><p>518 rows × 5 columns</p><tr><th>1</th><td>1.2</td><td>1</td><td>1</td><td>enqueues</td><td>0.0</td></tr><tr><th>2</th><td>1.2</td><td>1</td><td>0</td><td>now being served</td><td>0.0</td></tr><tr><th>3</th><td>2.42</td><td>1</td><td>0</td><td>leaves</td><td>1.22333</td></tr><tr><th>4</th><td>14.46</td><td>2</td><td>1</td><td>enqueues</td><td>0.0</td></tr><tr><th>5</th><td>14.46</td><td>2</td><td>0</td><td>now being served</td><td>0.0</td></tr><tr><th>6</th><td>15.33</td><td>2</td><td>0</td><td>leaves</td><td>0.869507</td></tr><tr><th>7</th><td>15.59</td><td>3</td><td>1</td><td>enqueues</td><td>0.0</td></tr><tr><th>8</th><td>15.59</td><td>3</td><td>0</td><td>now being served</td><td>0.0</td></tr><tr><th>9</th><td>16.03</td><td>4</td><td>1</td><td>enqueues</td><td>0.0</td></tr><tr><th>10</th><td>17.8</td><td>3</td><td>1</td><td>leaves</td><td>2.20916</td></tr><tr><th>11</th><td>17.8</td><td>4</td><td>0</td><td>now being served</td><td>1.76564</td></tr><tr><th>12</th><td>23.05</td><td>4</td><td>0</td><td>leaves</td><td>7.01425</td></tr><tr><th>13</th><td>27.45</td><td>5</td><td>1</td><td>enqueues</td><td>0.0</td></tr><tr><th>14</th><td>27.45</td><td>5</td><td>0</td><td>now being served</td><td>0.0</td></tr><tr><th>15</th><td>27.5</td><td>6</td><td>1</td><td>enqueues</td><td>0.0</td></tr><tr><th>16</th><td>30.71</td><td>7</td><td>2</td><td>enqueues</td><td>0.0</td></tr><tr><th>17</th><td>32.32</td><td>5</td><td>2</td><td>leaves</td><td>4.86645</td></tr><tr><th>18</th><td>32.32</td><td>6</td><td>1</td><td>now being served</td><td>4.81794</td></tr><tr><th>19</th><td>35.49</td><td>6</td><td>1</td><td>leaves</td><td>7.99158</td></tr><tr><th>20</th><td>35.49</td><td>7</td><td>0</td><td>now being served</td><td>4.77958</td></tr><tr><th>21</th><td>35.73</td><td>8</td><td>1</td><td>enqueues</td><td>0.0</td></tr><tr><th>22</th><td>37.47</td><td>9</td><td>2</td><td>enqueues</td><td>0.0</td></tr><tr><th>23</th><td>38.26</td><td>7</td><td>2</td><td>leaves</td><td>7.54359</td></tr><tr><th>24</th><td>38.26</td><td>8</td><td>1</td><td>now being served</td><td>2.5265</td></tr><tr><th>25</th><td>41.92</td><td>8</td><td>1</td><td>leaves</td><td>6.1911</td></tr><tr><th>26</th><td>41.92</td><td>9</td><td>0</td><td>now being served</td><td>4.44906</td></tr><tr><th>27</th><td>42.26</td><td>10</td><td>1</td><td>enqueues</td><td>0.0</td></tr><tr><th>28</th><td>44.22</td><td>9</td><td>1</td><td>leaves</td><td>6.74951</td></tr><tr><th>29</th><td>44.22</td><td>10</td><td>0</td><td>now being served</td><td>1.96307</td></tr><tr><th>30</th><td>45.62</td><td>11</td><td>1</td><td>enqueues</td><td>0.0</td></tr><tr><th>&vellip;</th><td>&vellip;</td><td>&vellip;</td><td>&vellip;</td><td>&vellip;</td><td>&vellip;</td></tr></tbody></table>




```julia
last(df, 5)
```




<table class="data-frame"><thead><tr><th></th><th>time</th><th>cust</th><th>qlen</th><th>status</th><th>wtime</th></tr><tr><th></th><th>Float64</th><th>Int64</th><th>Int64</th><th>String</th><th>Float64</th></tr></thead><tbody><p>5 rows × 5 columns</p><tr><th>1</th><td>592.49</td><td>177</td><td>0</td><td>now being served</td><td>2.89088</td></tr><tr><th>2</th><td>594.74</td><td>178</td><td>1</td><td>enqueues</td><td>0.0</td></tr><tr><th>3</th><td>595.95</td><td>177</td><td>1</td><td>leaves</td><td>6.35064</td></tr><tr><th>4</th><td>595.95</td><td>178</td><td>0</td><td>now being served</td><td>1.21605</td></tr><tr><th>5</th><td>598.03</td><td>178</td><td>0</td><td>leaves</td><td>3.29656</td></tr></tbody></table>




```julia
describe(df[df[!, :wtime] .> 0, :wtime])
```

    Summary Stats:
    Length:         314
    Missing Count:  0
    Mean:           7.326661
    Minimum:        0.070575
    1st Quartile:   3.690368
    Median:         6.139574
    3rd Quartile:   9.958741
    Maximum:        23.627103
    Type:           Float64


In $600$ minutes simulation time, we registered $178$ customers and $518$ status changes. The mean and median waiting times were around $7$ minutes.


```julia
by(df, :status, df -> size(df, 1))
```




<table class="data-frame"><thead><tr><th></th><th>status</th><th>x1</th></tr><tr><th></th><th>String</th><th>Int64</th></tr></thead><tbody><p>4 rows × 2 columns</p><tr><th>1</th><td>enqueues</td><td>170</td></tr><tr><th>2</th><td>now being served</td><td>170</td></tr><tr><th>3</th><td>leaves</td><td>170</td></tr><tr><th>4</th><td>leaves - queue is full!</td><td>8</td></tr></tbody></table>



Of the $178$ customers, $170$ of them participated in the whole process and were served, but $8$ left beforehand because the queue was full: 


```julia
df[df.wtime .< 0,:]
```




<table class="data-frame"><thead><tr><th></th><th>time</th><th>cust</th><th>qlen</th><th>status</th><th>wtime</th></tr><tr><th></th><th>Float64</th><th>Int64</th><th>Int64</th><th>String</th><th>Float64</th></tr></thead><tbody><p>8 rows × 5 columns</p><tr><th>1</th><td>134.96</td><td>36</td><td>5</td><td>leaves - queue is full!</td><td>-1.0</td></tr><tr><th>2</th><td>140.39</td><td>38</td><td>5</td><td>leaves - queue is full!</td><td>-1.0</td></tr><tr><th>3</th><td>166.69</td><td>47</td><td>5</td><td>leaves - queue is full!</td><td>-1.0</td></tr><tr><th>4</th><td>169.14</td><td>49</td><td>5</td><td>leaves - queue is full!</td><td>-1.0</td></tr><tr><th>5</th><td>169.2</td><td>50</td><td>5</td><td>leaves - queue is full!</td><td>-1.0</td></tr><tr><th>6</th><td>212.92</td><td>64</td><td>5</td><td>leaves - queue is full!</td><td>-1.0</td></tr><tr><th>7</th><td>237.76</td><td>72</td><td>5</td><td>leaves - queue is full!</td><td>-1.0</td></tr><tr><th>8</th><td>575.38</td><td>172</td><td>5</td><td>leaves - queue is full!</td><td>-1.0</td></tr></tbody></table>




```julia
using PyPlot
step(df.time, df.wtime)
step(df.time, df.qlen)
axhline(y=0, color="k")
grid()
xlabel("time [min]")
ylabel("wait time [min], queue length")
title("Waiting Time in the Post Office")
legend(["wait_time", "queue_len"]);
```


![png](output_17_0.png)


Many customers had waiting times of more than 10, 15 up to even more than 20 minutes. The negative waiting times were the 5 customers, which left because the queue was full.

So many customers will remain angry. If this is the situation all days, our post office will have an evil reputation. What should we do?

## Conclusion

Even if our process runs within predetermined bounds (queue length, customer wishes …), it seems to fluctuate wildly and to produce unpredicted effects. We see here the **effects of variation** in arrivals, in demands and in serving time on system performance. In this case 10% extra capacity is not enough to provide enough buffer for variation and for customer service – even if our post clerk is the most willing person.

Even for such a simple everyday system, we cannot say beforehand – without reality check – which throughput, waiting times, mean queue length, capacity utilization or customer satisfaction will emerge. Even more so for more complicated systems in production, service, projects and supply chains with multiple dependencies.

If we had known the situation beforehand, we could have provided standby for our clerk or install an automatic stamp dispenser for cutting the short tasks … 

We should have done a simulation. We should have known `DiscreteEvents` before …  😄


```julia

```
