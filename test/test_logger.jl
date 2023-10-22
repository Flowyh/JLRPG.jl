using Dates
using Logging

struct TestLogger <: AbstractLogger
  io::IO
end

TestLogger() = TestLogger(stderr)

Logging.min_enabled_level(::TestLogger) = Logging.BelowMinLevel

function Logging.shouldlog(::TestLogger, kwargs...) # level, _module, group, id)
  return true
end

Logging.catch_exceptions(logger::TestLogger) = true

const LVL_COLORS::Dict{LogLevel, Symbol} = Dict(
  Logging.Debug => :blue,
  Logging.Info => :green,
  Logging.Warn => :yellow,
  Logging.Error => :red,
)

function Logging.handle_message(
  logger::TestLogger,
  lvl, msg, _mod, group, id, file, line;
  kwargs...
)
  printstyled(logger.io, "$(Dates.format(now(), "dd-mm-yyyy HH:MM:SS")) ", color=:yellow, bold=true)
  printstyled(logger.io, "[$lvl] ", color=get(LVL_COLORS, lvl, :white), bold=true)
  printstyled(logger.io, "$msg ", color=:light_white)
  for arg in kwargs
    printstyled(logger.io, "$(String(arg[1])): $(arg[2])", color=:light_white, bold=true)
  end
  printstyled(logger.io, "\n", color=:light_white)
end
