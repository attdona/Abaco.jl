using ArgParse
using JSON3
using Sockets

function parse_commandline(args)
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--en"
            help = "entity name"
        "--var"
            help = "variable name"
            required = true
        "--val"
            help = "variable value"
            arg_type = Float64
        "--ts"
            help = "timestamp"
            arg_type = Int
            default = Int(floor(time()))
    end

    return parse_args(args, s)
end

function script_main()
    parsed_args = parse_commandline(ARGS)
    sock = connect(3333)
    write(sock, JSON3.write(Dict(
            "sn" => parsed_args["en"],
            "ts" => parsed_args["ts"],
            parsed_args["var"] => parsed_args["val"],
        )) * "\n")

    response = readline(sock)
    while response !== "DONE"
        msg = JSON3.read(response)
        println(msg)
        response = readline(sock)
    end
    close(sock)
end

script_main()