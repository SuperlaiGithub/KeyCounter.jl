module KeyCounter

const SAVE_FILE = "summary.log"

const MODIFIERS = Set{UInt16}([
    29,     # LEFTCTRL
    42,     # LEFTSHIFT
    54,     # RIGHTSHIFT
    56,     # LEFTALT
    97,     # RIGHTCTRL
    100,    # RIGHTALT
    125,    # LEFTMETA (super/win/gui/command key)
    126,    # RIGHTMETA (super/win/gui/command key)
    127     # COMPOSE (menu key)
])

# keys that are used as both modifiers and standard keys
const STANDARD = Set{UInt16}([
    125, 126
])

struct TimeVal
    seconds::UInt64
    microseconds::UInt64
end

function Base.read(io::IO, ::Type{TimeVal})
    return TimeVal(
        read(io, UInt64),
        read(io, UInt64)
    )
end

struct InputEvent
    time::TimeVal
    type::UInt16
    code::UInt16
    value::UInt32
end

function Base.read(io::IO, ::Type{InputEvent})
    return InputEvent(
        read(io, TimeVal),
        read(io, UInt16),
        read(io, UInt16),
        read(io, UInt32)
    )
end

makekey(k) = k isa Integer ? Int(k) : Set{Int}(k)
const Key = Union{Int, Set{Int}}

struct Summary <: AbstractDict{Key, Int}
    keys::Dict{Key, Int}
end
Summary() = Summary(Dict{Key, Int}())
Summary(itr::Union{AbstractVector, Tuple}) = Summary(Dict{Key, Int}(
    [makekey(k) => Int(c) for (k, c) ∈ itr]
))
Summary(vals::Pair...) = Summary(vals)
Base.iterate(s::Summary) = iterate(s.keys)
Base.iterate(s::Summary, state) = iterate(s.keys, state)
Base.length(s::Summary) = length(s.keys)
Base.getindex(s::Summary, key) = get(s, key, 0)
Base.setindex!(s::Summary, value, key) = setindex!(s.keys, value, key)
Base.haskey(s::Summary, key) = haskey(s.keys, key)
Base.get(s::Summary, key, default) = get(s.keys, key, default)
function add!(s::Summary, key::Key)
    if haskey(s, key)
        s[key] += 1
    else
        s[key] = 1
    end
end
add!(s::Summary, key) = add!(s, makekey(key))

width(itr, default) = max(default, maximum(length, itr; init=default))
function makewidth(str, width)
    length(str) ≤ width && return lpad(str, width)
    comma = findlast(',', str[1:width])
    (comma ≡ nothing || comma ≥ width-1) && return str[1:width-1] * "…"
    return lpad(str[1:comma] * " …", width)
end

function Base.show(io::IO, ::MIME"text/plain", s::Summary)
    rows, cols = get(io, :displaysize, (25, 80))

    keys, counts = String[], String[]
    for (keycode, count) ∈ sort(collect(s), by=last, rev=true)
        keycodes = keycode isa Integer ? [keycode] : collect(keycode)
        sort!(keycodes)
        push!(keys, join(keycodes, ", "))
        push!(counts, string(count))
        length(keys) + 2 == rows && break
    end
    keywidth, countwidth = width.([keys, counts], [8, 5])
    lines = makewidth.(keys, keywidth) .* " │ " .* lpad.(counts, countwidth)

    println(io, lpad("Keycode", keywidth), " │ ", lpad("Count", countwidth))
    println(io, "╶", "─"^keywidth, "┼─", "─"^countwidth, "╴")

    #if length(s) + 2 ≤ rows
    println.(io, lines)
end

keystring(key) = string(key isa Integer ? key : key |> collect |> sort)
function Base.show(io::IO, s::Summary)
    print(io, "Summary(")
    items = String[]
    for (key, count) ∈ sort(collect(s), by=last, rev=true)
        push!(items, keystring(key) * " => " * string(count))
    end
    print(io, join(items, ", "), ")\n")
end

function save(io::IO, s::Summary)
    for (keycode, count) ∈ sort(collect(s), by=last, rev=true)
        keycodes = keycode isa Integer ? [keycode] : collect(keycode)
        sort!(keycodes)
        println(io, repr(keycodes)[2:end-1], ": ", count)
    end
    println(io, "")
end
save(s::Summary) = io -> save(io, s)
save(filename::AbstractString, s::Summary) = open(save(s), filename; append=true)

abstract type ActionType end
struct KeyPress <: ActionType end
struct KeyRelease <: ActionType end
const keypress = KeyPress()
const keyrelease = KeyRelease()

abstract type KeyType end
struct StandardKey <: KeyType end
struct ModifierKey <: KeyType end
const standardkey = StandardKey()
const modifierkey = ModifierKey()

handle!(keys, modifiers, keycode, ::ModifierKey, ::KeyPress) = push!(modifiers, keycode)
handle!(keys, modifiers, keycode, ::ModifierKey, ::KeyRelease) = delete!(modifiers, keycode)
function handle!(keys, modifiers, keycode, ::StandardKey, ::KeyPress)
    if isempty(modifiers)
        add!(keys, keycode)
    else
        add!(keys, union(modifiers, keycode))
    end
end
handle!(keys, modifiers, keycode, ::StandardKey, ::KeyRelease) = nothing

const action = Dict{UInt16, ActionType}(
    0 => keyrelease,
    1 => keypress
)

function logkeys(comm)
    keys = Summary()
    modifiers = Set{UInt16}()
    num_keys = 0
    open("/dev/input/event6", "r") do kbd
        while true
            mod(num_keys, 10) == 0 && @info "Waiting for keyboard event…"
            while eof(kbd)
                sleep(0.1)
            end
            event = read(kbd, InputEvent)
            mod(num_keys, 10) == 0 && @info "  Event found, processing…"
            if event.type == 1 && haskey(action, event.value)
                num_keys += 1
                actiontype = action[event.value]
                if event.code ∈ MODIFIERS
                    handle!(keys, modifiers, event.code, modifierkey, actiontype)
                end
                if event.code ∉ MODIFIERS || event.code ∈ STANDARD
                    handle!(keys, modifiers, event.code, standardkey, actiontype)
                end
            end
            mod(num_keys, 10) == 0 && @info "  …done!"
            mod(num_keys, 10) == 0 && @info "Channel has $(length(comm.data)) items waiting."
            while isready(comm)
                mod(num_keys, 1) == 0 && @info "  Responding to item."
                command = fetch(comm)
                command == 's' && save(SAVE_FILE, keys)
                command == 'p' && show(stdout, MIME("text/plain"), keys)
                take!(comm)
                command == 'q' && return
            end
        end
    end
    return keys
end

function test()
    open("/dev/input/event6", "r") do kbd
        quit = false
        while !quit
            event = read(kbd, InputEvent)
            if event.type == 1
                println("Event")
                println("  Type:  $(event.type)")
                println("  Code:  $(event.code)")
                println("  Value: $(event.value)")
            end
            quit = event.code == 1
        end
    end
end

function prompt()
    print("Logging keys ")
    printstyled(">>> "; color=:red)
    printstyled("p"; color=:blue)
    print("rint, ")
    printstyled("s"; color=:blue)
    print("ave, ")
    printstyled("q"; color=:blue)
    print("uit: ")
    input = readline()
    return isempty(input) ? ' ' : (input |> first |> lowercase)
end

function run()
    comm = Channel{Char}(logkeys, 10; spawn=true)
    input = ' '
    while input ≠ 'q'
        input = prompt()
        put!(comm, input)
        while !isempty(comm)
            sleep(0.1)
        end
    end
end

end;
isinteractive() || KeyCounter.run()
