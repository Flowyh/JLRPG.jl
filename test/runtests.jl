using JLPG
using Test

@testset "JLPG.jl" begin
  for directory in filter(isdir, readdir(@__DIR__))
    @testset "$(uppercasefirst(directory)) module" begin
      for file in filter(x -> endswith(x, ".jl"), readdir(joinpath(@__DIR__, directory)))
        include(joinpath(@__DIR__, directory, file))
      end
    end
  end
end
