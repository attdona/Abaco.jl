
"""
    nowts()

the current timestamp in seconds from epoch
"""
nowts = () -> Libc.TimeVal().sec

# 
# Return the universe index of `ts`: an integer between 1 and `ages`.
# 
# `interval` is the correlation interval and `ages` is the number
# of universes.
# 
mvindex(ts, interval, ages) = div(ts,interval) % ages + 1

"""
    lastspan(interval::Int64=900)::Int64

Returns the epoch start time of the last span.
The last span is the nearest in the present time interval that satisfies the
condition: `span.endtime < now`.
"""
function lastspan(interval::Int64=900)::Int64
    current = Int(round(tim()))
    current - current%interval - interval
end

"""
    span(ts::Int64, interval::Int64=900)

Returns the start_time of the time interval that contains `ts`.
"""
function span(ts::Int64, interval::Int64=900)
    ts - ts%interval
end