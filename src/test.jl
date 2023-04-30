module Test
using Logging

function set_log_level()
    Logging.global_logger(ConsoleLogger(Logging.LogLevel(-2000)))
end

function test()
    set_log_level()
    @debug "This should display"
end

end;
