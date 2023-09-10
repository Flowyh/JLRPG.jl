using JLPG
using Test

@testset "JLPG.jl" begin
  @testset "Regex module" begin
    include("regex/tokenize_tests.jl")
  end
end
