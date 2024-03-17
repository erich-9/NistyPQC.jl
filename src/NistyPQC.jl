module NistyPQC

export MLKEM, MLDSA, SLHDSA, Falcon, BIKE

import Random: AbstractRNG, default_rng

rng = default_rng()

function with_rng(f::Function, tmp_rng::AbstractRNG)
    old_rng = NistyPQC.rng
    NistyPQC.rng = tmp_rng
    try
        return f()
    finally
        NistyPQC.rng = old_rng
    end
end

include("Utilities/Utilities.jl")
include("MLKEM/MLKEM.jl")
include("MLDSA/MLDSA.jl")
include("SLHDSA/SLHDSA.jl")
include("Falcon/Falcon.jl")
include("BIKE/BIKE.jl")

end # module
