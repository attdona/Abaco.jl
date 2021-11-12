
"""
    nowts()

the current timestamp in seconds from epoch
"""
nowts = () -> Libc.TimeVal().sec

# 
# Return the universe index of `ts`: an integer between 1 and `ages`.
# 
# `width` is the correlation interval adn `ages` is the number
# of universes.
# 
mvindex(ts, width, ages) = div(ts,width) % ages + 1

"""
    ropcurrent(interval::Int64=900)::Int64

Returns the epoch start time of the current rop.
The current rop is the nearest in the present rop that satisfies the
condition: `rop.endtime < now`.
"""
function ropcurrent(interval::Int64=900)::Int64
    current = Int(round(tim()))
    current - current%interval - interval
end

"""
    rop(ts::Int64, width::Int64=900)

Returns the start_time of the `rop` time window that contains `ts`.

The ROP is the *Report Output Period* of a metric and it is the time interval
defined as:

    ROP = { t ∈ [start_time, start_time+width) }

It is customary to use the `start_time` to indicate a `rop`: the rop of ten o'clock
is the time interval `[10:00, 10:15)`.
"""
function rop(ts::Int64, width::Int64=900)
    ts - ts%width
end