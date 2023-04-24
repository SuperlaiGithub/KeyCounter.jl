using Dates

const TIME_FMT = dateformat"yyyy-mm-ddTHH:MM:SS"

function test()
    open("/dev/input/event6", "r") do kbd
        @info "Monitoring keyboard events…"
        try
            was_at_end = false
            while true
                is_at_end = eof(kbd)
                if is_at_end ≠ was_at_end
                    @info "[$(Dates.format(now(), TIME_FMT))]"
                    @info "Change in status, file is now " * (is_at_end ? "" : "not ") * empty
                end
                sleep(0.1)
                was_at_end = is_at_end
            end
        catch e
            e isa InterruptException && @info "Exiting…"
        end            
    end
end

if !isinteractive()
    Base.exit_on_sigint(false)
    test()
end
