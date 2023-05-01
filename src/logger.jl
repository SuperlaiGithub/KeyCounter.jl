const TIME_FMT = dateformat"yyyy-mm-ddTHH:MM:SS"
timestamp() = "[$(Dates.format(now(), TIME_FMT))]"

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

function _logkeys(settings, keys)
    modifiers = Set{UInt16}()

    @info "$(timestamp()) Starting counter…"
    kbd = open(settings["input"], "r")
    last_save = now()
    Base.exit_on_sigint(false)
    try
        while true
            if eof(kbd)
                @warn "Event file closed, reopening"
                close(kbd)
                kbd = open(settings["input"], "r")
            end
            event = read(kbd, InputEvent)
            if event.type == 1 && haskey(action, event.value)
                actiontype = action[event.value]
                if event.code ∈ MODIFIERS
                    handle!(keys, modifiers, event.code, modifierkey, actiontype)
                end
                if event.code ∉ MODIFIERS || event.code ∈ STANDARD
                    handle!(keys, modifiers, event.code, standardkey, actiontype)
                end
            end
            if (now() - last_save) > settings["interval"]
                @info "$(timestamp()) $(sum(last, keys)) events recorded, saving to file."
                save(settings["output"], keys)
                last_save = now()
            end
        end
    catch e
        close(kbd)
        e isa InterruptException && @info "Saving and quitting"
        save(settings["output"], keys)
    end
end

