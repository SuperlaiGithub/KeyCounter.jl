module KeyCounter
const VER = v"1.0.0"

using ArgParse
using Dates
using Logging

export countkeys, install, uninstall

include("devices.jl")
include("settings.jl")
include("datatypes.jl")
include("logger.jl")
include("install.jl")

function make_output(settings)
    if !isfile(settings["output"])
        touch(settings["output"])
        settings["user"] ≠ nothing && chown(settings["output"], settings["user"])
        @debug "No output file existed, created at $(settings["output"]), owned by user $(settings["user"])"
    end
end

function get_saved_data(settings)
    try
        keys = load(settings["output"], Summary)
        @info "Loaded existing data"
        return keys
    catch exception
        @warn "Couldn't read save file" exception
        return Summary()
    end
end

function logkeys(settings)
    init_settings!(settings)
    make_output(settings)
    keys = get_saved_data(settings)
    _logkeys(settings, keys)
end

override!(settings, key, value) = settings[key] = something(value, Some(settings[key]))

function set_log_level(settings)
    log_level = Logging.Info
    settings["quiet"] && (log_level = Logging.Warn)
    settings["debug"] && (log_level = Logging.Debug)
    Logging.global_logger(ConsoleLogger(log_level))
end

function countkeys(useARGS=!isinteractive();
            keyboard    = nothing,
            event       = nothing,
            input       = nothing,
            output      = nothing,
            interval    = nothing,
            quiet       = nothing,
            debug       = nothing,
            user        = nothing
        )

    # we may need to provide output before fully processing all commandline/keyword arguments
    settings = Dict{String, Any}(
        "quiet" => quiet,
        "debug" => debug
    )
    if useARGS
        ("--quiet" ∈ ARGS || "-q" ∈ ARGS) && (settings["quiet"] = true)
        ("--debug" ∈ ARGS || "-d" ∈ ARGS) && (settings["debug"] = true)
    end
    set_log_level(settings)

    @debug "Determining settings from $(useARGS ? "command line" : "keyword") arguments"
    settings = settings_from_args(useARGS ? ARGS : [])
    useARGS && @debug "Arguments received from command line are $settings"

    override!(settings, "keyboard", keyboard)
    override!(settings, "event",    event)
    override!(settings, "input",    input)
    override!(settings, "output",   output)
    override!(settings, "interval", interval)
    override!(settings, "quiet",    quiet)
    override!(settings, "debug",    debug)
    override!(settings, "user",     user)

    @debug "Final settings are $settings"
    logkeys(settings)
end

end; #module
