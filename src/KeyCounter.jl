module KeyCounter
using ArgParse
using Dates

export run, countkeys

include("settings.jl")
include("datatypes.jl")
include("logger.jl")

function make_output()
    if !isfile(settings["output"])
        touch(settings["output"])
        settings["user"] ≠ nothing && chown(settings["output"], settings["user"])
    end
end

function get_saved_data()
    # TODO fix this
    local keys
    try
        keys = load(settings["output"], Summary)
        @info "Loaded existing data"
    catch
        @warn "Couldn't read save file"
        keys = Summary()
    end
    return keys
end

function logkeys(settings)
    init_settings!(settings)
    make_output()
    keys = get_saved_data()
    _logkeys(settings, keys)
end

function countkeys(
            event       = nothing,
            input       = nothing,
            output      = DEF_SAVE_FILE,
            interval    = DEF_SAVE_INTERVAL,
            quiet       = false,
            debug       = false,
            user        = DEF_USER
        )

    logkeys(Dict{String, Any}(
        "event"     => event,
        "input"     => input,
        "output"    => output,
        "interval"  => interval,
        "quiet"     => quiet,
        "debug"     => debug,
        "user"      => user
    ))
end

run() = logkeys(settings_from_args())

end; #module
