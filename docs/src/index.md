```@meta
CurrentModule = Abaco
```

# Abaco

Abaco computes formulas output from a stream of metric values as soon as all needed input values are collected.

In a real world scenario values are coming asynchronously, delayed and out of orders. Abaco may manage values referring to different times.

## Basic Concepts

An input value is associated with a node entity identified by a unique name.

A node may be seen as a data source or a data fusion domain: all variables that belong to the same node can be used by some formula. 

Abaco manages a hierarchy of nodes, more on that later.

A node must be provisioned before sending metric values associated with the node:

```julia
julia> add_node(abaco, "my_node") 
```

A metric data point is a measure associated with a node.
A metric is defined by: 
    
* a node unique name      
* a timestamp
* a metric name
* a metric value

Abaco understands metric values ingested in a "flat" `Dict{String,Any}`.

`en` and `ts` are reserved keyword for the unique node name and the
timestamp whereas the others properties represent metrics values.

A record with a single metric example:

```julia
julia> x_metric = Dict(
    "en" => "my_network_element",
    "ts" => 1642605647,
    "x" => 1.5
)

julia> y_metric = Dict(
    "en" => "my_network_element",
    "ts" => 1642605647,
    "y" => 8.5
)

```

And a record with a batch of metrics:

```julia
julia> metrics = Dict(
    "en" => "my_network_element",
    "ts" => 1642605647,
    "x" => 1.5,
    "y" => 25,
    "z" => 999
)
```
Metrics names are the names of the indipendent variables used by Abaco formulas.

A formula is named math expression defined by a string:

```julia
                        # formula name   expr
julia> add_formula(abaco, "my_formula", "x + y")
```

As soon as all inputs variables are collected and belong to the same [time window](#time-window) the formula result is calculated.

Using the above example as soon as both `x` and `y` are collected formula `my_formula` is evaluated and [onresult](#Abaco.abaco_init-Tuple{Any}) default callback is triggered.

The default callback print the result summary to the console.
```julia
julia> add_metrics(abaco, x_metric)

julia> add_metrics(abaco, y_metric)
my_formula(ts:1642605647, sn:my_network_element) = 10.0
```

### time span

A time span includes all the timestamps in a time interval:

```span = { t ∈ N | START_INTERVAL <= t < END_TIME }```

Timestamps `t` are integer values with second granularity. 

For example suppose that a data collection system uses a 15 minutes span interval:
in this case an hour is divided into 4 intervals and from ten to eleven of some (omitted) day you have:

* span1 =  { t ∈ [10:00:00, 10:15:00) }
* span2 =  { t ∈ [10:15:00, 10:30:00) }
* span3 =  { t ∈ [10:30:00, 10:45:00) }
* span4 =  { t ∈ [10:45:00, 11:00:00) }

By convention the span interval is identified by its START_TIME.

The formula value computed from inputs with timestamps included into the span `[START_TIME, END_TIME)` has timestamp equal to `START_TIME`.

The `width` of the span interval is an abaco setting, user-defined at startup.

### ages

The number of `ages` defines how many consecutive time spans are managed.

For example, for a time span of 15 minutes, set `ages` to 4 if your network devices may send data with a maximum delay of an hour. A received value marked with a timestamp distant 4 or more spans from the latest span is discarded.

The number of `ages` is an abaco setting, user-defined at startup.

This is the minimal background theory, the below example should help to clarify the Abaco mechanics.

## Getting Started

Installation:

```julia
julia> using Pkg; Pkg.add("Abaco")    
```

Usage:

```julia
using Abaco

# Initialize abaco context with a time_window of 60 seconds and handle
# input values with timestamp ts up to 4 contiguous spans.
abaco = abaco_init(interval=60, ages=4) do ts, node, formula_name, value, inputs
    @info "[$ts][$node] function $formula_name=$value"
end

# Add desired outputs in terms of inputs variables x, y, z, v, w
outputs = ["xysum = x + y", "rsigma = x * exp(y-1)", "wsum = (x*w + z*v)"]

for formula in outputs
    add_formula(abaco, formula)
end

# Start receiving some inputs values
# normally ts is the UTC timestamp from epoch in seconds.
# but for semplicity assume time start from zero.

# the node AG101 sends the x value at timestamp 0.
ts = 0
node = "AG101"
add_value(abaco, ts, node, "x", 10)

# Time flows and about 1 minute later ...

# the node CE987 sends the y value at timestamp 65.
ts = 65
node = "CE987"
add_value(abaco, ts, node, "y", 10)

# Time flows and more than 1 minute later ...

# Finally the node AG101 sends the y value calculated at timestamp 0.
# At this instant the formulas that depends on x and y are computable
# for the element AG101 at timestamp 0.
ts = 0
node = "AG101"
add_value(abaco, ts, node, "y", 20)
[ Info: [0][AG101] function xysum=30
[ Info: [0][AG101] function rsigma=1.7848230096318724e9

# Now arrives the variable x from CE987 that make some formulas computables.
# Note that x timestamp is 65, y timestamp is 101
# and the formulas timestamp is 60: the START_TIME of the span. 
ts = 101
node = "CE987"
add_value(abaco, ts, node, "x", 10)
[ Info: [60][CE987] function xysum=20
[ Info: [60][CE987] function rsigma=81030.83927575384

```

In the formula callback the first argument may be a user defined object, like a Socket a Channel or whatsoever communication endpoint.

For example:

```julia
sock = connect(3001)

abaco = abaco_init(handle=sock, interval=900) do sock, ts, node, formula_name, value, inputs
    @info "age [$ts]: [$node] $formula_name = $value"
    msg = JSON3.write(Dict(
                        "node" => node,
                        "age" => ts, 
                        "formula" => formula_name,
                        "value" => value))
    write(sock, msg*"\n")
end
```

## API

```@index
```

```@autodocs
Modules = [Abaco]
```
