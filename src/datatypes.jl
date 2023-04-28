struct TimeVal
    seconds::UInt64
    microseconds::UInt64
end
TimeVal() = TimeVal(UInt64(0), UInt64(0))

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
InputEvent() = InputEvent(TimeVal(), UInt16(0), UInt16(0), UInt32(0))

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
    rows = get(io, :displaysize, displaysize(io)) |> first

    num_lines = length(s)
    ellipsis = num_lines > rows - 6
    ellipsis && (num_lines = rows - 7)

    keys, counts = String[], String[]
    for (keycode, count) ∈ sort(collect(s), by=last, rev=true)
        keycodes = keycode isa Integer ? [keycode] : collect(keycode)
        sort!(keycodes)
        push!(keys, join(keycodes, ", "))
        push!(counts, string(count))
        length(keys) == num_lines && break
    end
    keywidth, countwidth = width.([keys, counts], [8, 5])
    lines = makewidth.(keys, keywidth) .* " │ " .* lpad.(counts, countwidth)

    println(io, lpad("Keycode", keywidth), " │ ", lpad("Count", countwidth))
    println(io, "╶", "─"^keywidth, "┼─", "─"^countwidth, "╴")
    println.(io, lines)
    ellipsis && println(io, lpad("⋮", keywidth), " │ ", lpad("", countwidth))
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

function load(io::IO, ::Type{Summary})
    s = Summary()
    for line ∈ eachline(io)
        keys_str, count_str = split(line, ": ")
        keycodes_str = split(keys_str, ", ")
        keycodes, count = parse.(Int, keycodes_str), parse(Int, count_str)
        length(keycodes) == 1 && (keycodes = only(keycodes))
        key = makekey(keycodes)
        if haskey(s, key)
            s[key] += count
        else
            s[key] = count
        end
    end
    return s
end
load(::Type{Summary}) = io -> load(io, Summary)
load(filename::AbstractString, ::Type{Summary}) = open(load(Summary), filename)

function save(io::IO, s::Summary)
    for (keycode, count) ∈ sort(collect(s), by=last, rev=true)
        keycodes = keycode isa Integer ? [keycode] : collect(keycode)
        sort!(keycodes)
        println(io, repr(keycodes)[2:end-1], ": ", count)
    end
end
save(s::Summary) = io -> save(io, s)
save(filename::AbstractString, s::Summary) = open(save(s), filename; truncate=true)

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
