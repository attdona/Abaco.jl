#!/bin/bash
#=
exec julia --threads auto -e "include(popfirst!(ARGS))" --project=. --startup-file=no "${BASH_SOURCE[0]}" "$@"
=#

using Abaco
using JSON3
using Sockets

struct Context
    subscribers::Vector{TCPSocket}
    Context() = new([])
end

function handler(ctx, sock, ch)
    try
        push!(ctx.subscribers, sock)
        while isopen(sock)
            msg = readline(sock, keep=true)
            if msg !== ""
                jmsg = JSON3.read(msg, Dict{String, Any})
                put!(ch, jmsg)
            end
        end
    catch e
        # ignore connection reset by peer
        e.code !== -4077 || @error "handler: $e"
    end
    filter!(sub->isopen(sub), ctx.subscribers)
end

function server(ctx, ch)
    try
        server = listen(3333)
        while true
            sock = accept(server)
            @async handler(ctx, sock, ch)
        end
    catch e
        println("\nbye")
    end    
end


function abacod(ctx, channel)
    try
        time_window = parse(Int, get(ENV, "ABACO_INTERVAL", "-1"))

        abaco = abaco_init(handle=ctx, interval=time_window, emitone=false) do ctx, ts, sn, name, value, inputs
            msg = JSON3.write(Dict(
                                "en" => sn,
                                "ts" => ts, 
                                name => value))
            for sock in ctx.subscribers
                write(sock, msg*"\n")
            end
        end

        println("available calculus for:")
        for formula in [
            "xy_plus = x * y",
            "xy = x + y",
            "xyz = x * y * z"
        ]
            println("\t$formula")
            formula(abaco, formula)
        end
    
        while true
            metric = take!(channel)
            ingest(abaco, metric)
            for sock in ctx.subscribers
                write(sock, "DONE\n")
            end
        end
    catch e
        if isa(e, InterruptException)
            exit(0)
        end
        @error "abacod: $e"
    end    
end

function main()
    try
        ctx = Context()
        abaco_task = @async abacod(ctx, Channel{Dict{String, Any}}(16))
        @async server(ctx, channel)
        wait(abaco_task)
    catch e
        @error "$e"
    end    
end

main()
