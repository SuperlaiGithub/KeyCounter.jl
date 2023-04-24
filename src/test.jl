using Dates

const TIME_FMT = dateformat"yyyy-mm-ddTHH:MM:SS"

struct InputEvent
    seconds::UInt64
    microseconds::UInt64
    type::UInt16
    code::UInt16
    value::UInt32
end

function Base.read(io::IO, ::Type{InputEvent})
    return InputEvent(
        read(io, UInt64),
        read(io, UInt64),
        read(io, UInt16),
        read(io, UInt16),
        read(io, UInt32)
    )
end

function test()
    open("/dev/input/event6", "r") do kbd
        @info "[$(Dates.format(now(), TIME_FMT))]"
        @info "Monitoring keyboard events…"
        try
            num_events = 1
            was_at_end = false
            while true
                is_at_end = eof(kbd)
                if !is_at_end
                    read(kbd, InputEvent)
                    num_events += 1
                    mod(num_events, 100) == 0 && @info "Received $num_events keyboard events"
                end
                if is_at_end ≠ was_at_end
                    @info "[$(Dates.format(now(), TIME_FMT))]"
                    @info "Change in status, file is now " * (is_at_end ? "" : "not ") * "empty"
                end
                sleep(0.1)
                was_at_end = is_at_end
            end
        catch e
            e isa InterruptException || rethrow(e)
            @info "Done"
        end            
    end
end

if !isinteractive()
    Base.exit_on_sigint(false)
    test()
end
