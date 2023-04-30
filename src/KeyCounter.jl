module KeyCounter
using ArgParse
using Dates
using Logging

export countkeys

include("devices.jl")
include("settings.jl")
include("datatypes.jl")
include("logger.jl")

function make_output(settings)
    if !isfile(settings["output"])
        touch(settings["output"])
        settings["user"] ≠ nothing && chown(settings["output"], settings["user"])
        @debug "No output file existed, created at $(settings["output"]), owned by user $(settings["user"])"
    end
end

function get_saved_data()
    try
        keys = load(settings["output"], Summary)
        @info "Loaded existing data"
        return keys
    catch
        @warn "Couldn't read save file"
        return Summary()
    end
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

    @debug "Determining settings from $(useARGS ? "command line" : "keyword") arguments"
    settings = settings_from_args(useARGS ? ARGS : [])
    useARGS && @debug "Arguments received from command line are $settings"
    for key ∈ ["keyboard", "event", "input", "output", "interval", "quiet", "debug", "user"]
        key_sym = Symbol(key)
        @eval override!(settings, $key, $key_sym)
    end
    @debug "Final settings are $settings"
    logkeys(settings)
end

end; #module
