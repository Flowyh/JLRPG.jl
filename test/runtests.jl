using JLPG
using Test
using Logging

# Enable debug logging
debuglogger = ConsoleLogger(stderr, Logging.Debug)
global_logger(debuglogger)

@testset "JLPG.jl" begin
  for directory in filter(isdir, readdir(@__DIR__))
    @testset "$(uppercasefirst(directory)) module" begin
      for file in filter(x -> endswith(x, ".jl"), readdir(joinpath(@__DIR__, directory)))
        include(joinpath(@__DIR__, directory, file))
      end
    end
  end
end
