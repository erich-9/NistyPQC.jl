import Aqua
import NistyPQC

@testset "Aqua.jl" begin
    Aqua.test_all(NistyPQC; ambiguities = false, unbound_args = false)
end
