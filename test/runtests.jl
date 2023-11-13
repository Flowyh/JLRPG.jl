using JLPG
using Test
using Logging

include("test_logger.jl")

# Enable debug logging
debuglogger = TestLogger(stderr)
global_logger(debuglogger)

OMIT_DIRECTORIES::Set{String} = Set("resources", "regex")

@testset "JLPG.jl" begin
  time = @elapsed for directory in filter(isdir, readdir(@__DIR__))
    if directory in OMIT_DIRECTORIES
      continue
    end
    @testset "$(uppercasefirst(directory)) module" begin
      @info "Testing $(directory) module"
      files = filter(x -> endswith(x, ".jl"), readdir(joinpath(@__DIR__, directory)))
      for (i, file) in enumerate(files)
        file_prefix = (i == length(files) ? "└─" : "├─")
        test_result_prefix = (i == length(files) ? "  └─" : "│ └─")
        @info "$(file_prefix)Testing $(file)"
        test_time = @elapsed include(joinpath(@__DIR__, directory, file))
        @info "$(test_result_prefix)Tests finished! ($(round(test_time; digits=3))s)"
      end
      @info "$(uppercasefirst(directory)) tests finshed!"
      @info ""
    end
  end
  @info "Finished testing JLPG.jl"
  @info "Total time elapsed: $(round(time; digits=3))s"
end
