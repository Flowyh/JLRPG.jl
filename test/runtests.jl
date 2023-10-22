using JLPG
using Test
using Logging

include("test_logger.jl")

# Enable debug logging
debuglogger = TestLogger(stderr)
global_logger(debuglogger)

@testset "JLPG.jl" begin
  t = @elapsed for directory in filter(isdir, readdir(@__DIR__))
    @testset "$(uppercasefirst(directory)) module" begin
      @info "[?] Testing $(directory) module"
      for file in filter(x -> endswith(x, ".jl"), readdir(joinpath(@__DIR__, directory)))
        @info "  [?] Testing $(file)"
        include(joinpath(@__DIR__, directory, file))
        @info "  [+] Tests passed successfully!"
      end
      @info "[+] $(uppercasefirst(directory)) tests passed successfully!"
    end
  end
  @info "Finished testing JLPG.jl"
  @info "Total time elapsed: $(t)s"
end
