module KeyCounter
using ArgParse
using Dates

export run, countkeys

include("devices.jl")
include("settings.jl")
include("datatypes.jl")
include("logger.jl")

function make_output(settings)
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
    make_output(settings)
    keys = get_saved_data()
    _logkeys(settings, keys)
end

override!(settings, key, value) = settings[key] = something(value, Some(settings[key]))

function countkeys(useARGS=!isinteractive();
            keyboard    = nothing,
            event       = nothing,
            input       = nothing,
            output      = DEF_SAVE_FILE,
            interval    = DEF_SAVE_INTERVAL,
            quiet       = false,
            debug       = false,
            user        = DEF_USER
        )

    settings = settings_from_args(useARGS ? ARGS : [])
    for key ∈ ["keyboard", "event", "input", "output", "interval", "quiet", "debug", "user"]
        key_sym = Symbol(key)
        @eval override!(settings, $key, $key_sym)
    end
    logkeys(settings)
end

end; #module
