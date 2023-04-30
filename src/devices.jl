mutable struct Device
    id::Dict{String, Any}
    name::String
    physical_path::String
    sysfs_path::String
    unique_id::String
    handlers::Vector{String}
    properties::UInt64
    events::UInt64
    keys::String
    misc::UInt64
    leds::UInt64
    other::Vector{String}
end
Device() = Device(Dict{String, Any}(), "", "", "", "", String[], 0, 0, "", 0, 0, String[])
function Device(lines::Vector{String})
    device = Device()
    for line ∈ lines
        handle!(line, device)
    end
    return device
end

parse_id(str) = split(str) |> (eqs -> split.(eqs, "=")) |>  Dict
parse_string(str) = strip(str, '"')
parse_bitmap(str) = parse(UInt64, str, base=16)
parse_handlers(str) = split(str)

parse_line(prefix, parser, noeq=false) = line -> 
    match(Regex(prefix * (noeq ? "" : "=") * "(.*)"), line) |> only |> parser

idline              = parse_line("I: ",         parse_id,       true)
nameline            = parse_line("N: Name",     parse_string)
physical_path_line  = parse_line("P: Phys",     parse_string)
sysfs_path_line     = parse_line("S: Sysfs",    parse_string)
unique_id_line      = parse_line("U: Uniq",     parse_string)
handlers_line       = parse_line("H: Handlers", parse_handlers)
properties_line     = parse_line("B: PROP",     parse_bitmap)
events_line         = parse_line("B: EV",       parse_bitmap)
keys_line           = parse_line("B: KEY",      parse_string)
misc_line           = parse_line("B: MSC",      parse_bitmap)
leds_line           = parse_line("B: LED",      parse_bitmap)

idline!             = (line, device) -> device.id               = idline(line)
nameline!           = (line, device) -> device.name             = nameline(line)
physical_path_line! = (line, device) -> device.physical_path    = physical_path_line(line)
sysfs_path_line!    = (line, device) -> device.sysfs_path       = sysfs_path_line(line)
unique_id_line!     = (line, device) -> device.unique_id        = unique_id_line(line)
handlers_line!      = (line, device) -> device.handlers         = handlers_line(line)
properties_line!    = (line, device) -> device.properties       = properties_line(line)
events_line!        = (line, device) -> device.events           = events_line(line)
keys_line!          = (line, device) -> device.keys             = keys_line(line)
misc_line!          = (line, device) -> device.misc             = misc_line(line)
leds_line!          = (line, device) -> device.leds             = leds_line(line)

other_line!         = (line, device) -> push!(device.other, line)

const dev_lines = Dict(
    "I"         => idline!,
    "N"         => nameline!,
    "P"         => physical_path_line!,
    "S"         => sysfs_path_line!,
    "U"         => unique_id_line!,
    "H"         => handlers_line!,
    "B: PROP"   => properties_line!,
    "B: EV"     => events_line!,
    "B: KEY"    => keys_line!,
    "B: MSC"    => misc_line!,
    "B: LED"    => leds_line!,
    nothing     => other_line!
)

function handle!(line, device)
    for (prefix, fn!) ∈ dev_lines
        if prefix ≠ nothing && startswith(line, prefix)
            fn!(line, device)
            return
        end
    end
    dev_lines[nothing](line, device)
end

function get_devices()
    devices = Vector{String}[]
    device = String[]
    for line ∈ eachline("/proc/bus/input/devices")
        if line == ""
            push!(devices, device)
            device = []
        else
            push!(device, line)
        end
    end
    @debug "Found $(length(devices)) input devices"
    return Device.(devices)
end

