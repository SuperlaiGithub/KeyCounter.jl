function score(settings, device)
    s = 0
    for word ∈ something(settings["keyboard"], "keyboard") |> split
        occursin(lowercase(word), lowercase(device.name)) && (s += 100)
    end
    device.events & 0x120013 == 0x120013 && (s += 50)
    "kbd" ∈ device.handlers && (s += 20)
    "leds" ∈ device.handlers && device.leds & 7 == 7 && (s += 10)
    @debug "Device $(device.name) scored $s"
    return s
end
score(settings) = device -> score(settings, device)

function device_number(settings, device)
    nums = []
    for handler ∈ device.handlers
        m = match(r"event(\d+)", handler)
        m ≠ nothing && push!(nums, only(m))
    end
    isempty(nums) && throw(ErrorException("No event handler found for device"))
    length(nums) > 1 && @warn "Device has multiple event handlers"
    return first(nums)
end

function find_keyboard(settings)
    devices = get_devices()
    scores = score(settings).(devices)
    dev_score, dev_num = findmax(scores)
    @debug "Most likely keyboard device is $dev_num" devices[dev_num]
    (length(filter(d -> dev_score - d ≤ 10, scores)) > 1 || dev_score ≤ 20) &&
        @warn "Low confidence in autodetected keyboard"
    return device_number(settings, devices[dev_num])
end

const interval_regex = Regex(
    raw"(?:(?<days>\d+)d)?" *
    raw"(?:(?<hours>\d+)h)?" *
    raw"(?:(?<minutes>\d+)m)?" *
    raw"(?:(?<seconds>\d+)s)?"
)
parse_int(n) = parse(Int, n)
function parse_interval(str)
    m = match(interval_regex, str)
    m ≡ nothing && throw(ErrorException("invalid argument: interval should be [Nd][Nh][Nm][Ns]"))
    return something.(m, "0")      .|>
        parse_int                  .|>
        [Day, Hour, Minute, Second] |>
        sum
end

const KEYBOARD_PATH = "/dev/input/event"
const DEF_SAVE_FILE = "summary.log"
const DEF_SAVE_INTERVAL = "5m"
const DEF_USER = 0 # ie root

function settings_from_args(args)
    arg_settings = ArgParseSettings(
        prog        = "keycounter",
        description = "Count keys pressed and save a summary to a log file.",
        version     = string(VER)
    )
    @add_arg_table! arg_settings begin
        "--keyboard", "-k" 
            help = "name of keyboard device to search for. Keywords like make and model works best (ie \"logitech g512\")"
        "--event", "-e"
            help = "event number of keyboard input, omit for auto detection"
            arg_type = Int
        "--input", "-I"
            help = "full path to input file (ie /dev/input/event0). Overides --event"
        "--output", "-o"
            help = "file to write summary data to"
            default = DEF_SAVE_FILE
        "--interval", "-i"
            help = "save interval"
            default = DEF_SAVE_INTERVAL
        "--quiet", "-q"
            help = "suppress all standard output"
            action = :store_true
        "--debug", "-d"
            help = "enable debugging info (overrides --quiet)"
            action = :store_true
        "--user", "-u"
            help = "user id for output file ownership, assigned automatically"
            arg_tye = Int
            default = DEF_USER
        "--uninstall"
            help = "uninstall the program (must be first and only option otherwise will be ignored)"
            action = :store_true
    end
    return parse_args(args, arg_settings)
end

function init_settings!(settings)
    if settings["input"] ≡ nothing
        settings["event"] ≡ nothing && (settings["event"] = find_keyboard(settings))
        settings["input"] = string(KEYBOARD_PATH, settings["event"])
        @debug "No input file provided, using $(settings["input"])"
    end
    settings["interval"] = parse_interval(settings["interval"])
    @debug "Autosave every $(settings["interval"])"
end

