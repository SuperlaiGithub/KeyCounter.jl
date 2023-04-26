using ArgParse

function get_devices()
    devices = []
    device = []
    for line ∈ eachline("/proc/bus/input/devices")
        if line == ""
            push!(devices, device)
            device = []
        else
            push!(device, line)
        end
    end
    return devices
end

function score(device)
    dev_str = device |> join |> lowercase
    s = 0
    contains(lowercase(dev_str), "keyboard") && (s += 100)
    contains(dev_str, "kbd") && (s += 50)
    contains(dev_str, "Sysfs=/devices/pci") && (s += 10)
    return s
end

function device_number(device)
    line = findfirst(startswith("H:"), device)
    line ≡ nothing && throw(ErrorException("No handler for chosen device"))
    m = match(r"event(\d+)", device[line])
    m ≡ nothing && throw(ErrorException("No event handler for chosen device"))
    num = tryparse(Int, m |> only)
    num ≡ nothing && throw(ErrorException("No event number for chosen device"))
    return num
end

function find_keyboard()
    devices = get_devices()
    dev_num = findmax(score, devices) |> last
    return device_number(devices[dev_num])
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
    return something.(m, fill("0", 4))  .|>
        parse_int                       .|>
        [Day, Hour, Minute, Second]      |>
        sum
end

const settings = Dict{String, Any}()

const DEF_SAVE_FILE = "summary.log"
const DEF_SAVE_INTERVAL = "5m"

const KEYBOARD_PATH = "/dev/input/event"

function init_settings()
    arg_settings = ArgParseSettings()
    @add_arg_table! arg_settings begin
        "--event", "-e"
            help = "event number of keyboard input, omit for auto detection"
            arg_type = Int
        #"--keyboard", "-k"
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
    end
    empty!(settings)
    merge!(settings, parse_args(ARGS, arg_settings))
    !haskey(settings, "event") && (settings["event"] = find_keyboard())
    settings["input"] = string(KEYBOARD_PATH, settings["event"])
    settings["interval"] = parse_interval(settings["interval"])
end

