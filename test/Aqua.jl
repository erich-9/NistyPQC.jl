import Aqua
import NistyPQC

@testset "Aqua.jl" begin
    Aqua.test_all(NistyPQC; unbound_args = false)
end
