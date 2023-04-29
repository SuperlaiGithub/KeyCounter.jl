function score(settings, device)
    s = 0
    for word ∈ something(settings["keyboard"] |> split, ["keyboard"])
        word ∈ lowercase(device.name) && (s += 100)
    end
    device.events & 0x120013 == 0x120013 && (s += 50)
    "kbd" ∈ handlers && (s += 20)
    "leds" ∈ handlers && device.leds & 7 == 7 && (s += 10)
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
    return first(num)
end

function find_keyboard(settings)
    devices = get_devices()
    dev_num = findmax(score(settings), devices) |> last
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
    arg_settings = ArgParseSettings()
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
            help = "enable debugging info"
            action = :store_true
        "--user", "-u"
            help = "user id for output file ownership, assigned automatically"
            default = DEF_USER
    end
    return parse_args(args, arg_settings)
end

function init_settings!(settings)
    if settings["input"] ≡ nothing
        settings["event"] ≡ nothing && (settings["event"] = find_keyboard())
        settings["input"] = string(KEYBOARD_PATH, settings["event"])
    end
    settings["interval"] = parse_interval(settings["interval"])
end

