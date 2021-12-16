# Abaco

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://attdona.github.io/Abaco.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://attdona.github.io/Abaco.jl/dev)
[![Runtests](https://github.com/attdona/Abaco.jl/actions/workflows/Runtests.yml/badge.svg)](https://github.com/attdona/Abaco.jl/actions/workflows/Runtests.yml)

Abaco computes formulas from a stream of input variables.

Abaco aims to target the case where a number of IoT sensor, network devices or other types of objects that send periodic variable values must be combined into output values defined by math expressions.

In a real world scenario values are coming asynchronously, delayed and out of orders. Abaco may manage values referring to different times.

![timeline](https://github.com/attdona/Abaco.jl/blob/main/docs/images/timeline.png?raw=true)

## Getting Started

Installation:

```julia
julia> using Pkg; Pkg.add("Abaco")    
```

Minimal example:

```julia
using Abaco

# Initialize abaco context with a time span of 60 seconds and handle
# input values with timestamp ts up to 4 (ages) contiguous time intervals.
# When a formula is evaluated because all inputs variables are known traces
# an info record.
abaco = abaco_init(interval=60, ages=4) do ts, sn, fname, value, inputs
    @info "[$ts][$sn] function $fname=$value"
end

# Add desired outputs in terms of inputs variables x, y, z, v, w
outputs = ["xysum = x + y", "rsigma = x * exp(y-1)", "wsum = (x*w + z*v)"]

for formula in outputs
    add_formula(abaco, formula)
end

# Start receiving some inputs values
# normally ts is the UTC timestamp from epoch in seconds.
# but for semplicity assume time start from zero.

# the device AG101 sends the x value at timestamp 0.
ts = 0
device = "AG101"
add_value(abaco, ts, device, "x", 10)

# Time flows and about 1 minute later ...

# the device CE987 sends the y value at timestamp 65.
ts = 65
device = "CE987"
add_value(abaco, ts, device, "y", 10)

# Time flows and more than 1 minute later ...

# the device AG101 sends the y value calculated at timestamp 0.
# At this instant the formulas that depends on x and y are computable
# for the element AG101 at timestamp 0.
ts = 0
device = "AG101"
add_value(abaco, ts, device, "y", 20)
[ Info: [0][AG101] function xysum=30
[ Info: [0][AG101] function rsigma=1.7848230096318724e9

# Now arrives the variable x from CE987 that make some formulas computables
# because the received values for x and y are included into time interval [60, 120).
# Note that x timestamp is 65, y timestamp is 101
# and the formulas timestamp is 60: the START_TIME of the time interval
# where formula is computable. 
ts = 101
device = "CE987"
add_value(abaco, ts, device, "x", 10)
[ Info: [60][CE987] function xysum=20
[ Info: [60][CE987] function rsigma=81030.83927575384

```
