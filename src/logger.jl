using Logging

struct AbacoLogger <: AbstractLogger
    groups::Vector{Symbol}
    modules::Vector{Module}
end

function logging(;debug=[])
    groups = [item for item in debug if isa(item, Symbol)]
    modules = [item for item in debug if isa(item, Module)]
    AbacoLogger(groups, modules) |> global_logger
end

function Logging.min_enabled_level(logger::AbacoLogger) 
    Logging.Debug
end

function Logging.shouldlog(logger::AbacoLogger, level, _module, group, id)
    level >= Logging.Info || group in logger.groups || _module in logger.modules
end

function Logging.handle_message(logger::AbacoLogger, level, message, _module, group, id, file, line; kwargs...)
    println("[$(now())][$_module][$(Threads.threadid())][$level] $message")
end

