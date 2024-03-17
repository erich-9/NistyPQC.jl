module NistyPQC

export MLKEM, MLDSA, SLHDSA, Falcon, BIKE

import Random: AbstractRNG, default_rng

rng = default_rng()

function set_rng(rng::AbstractRNG)
    NistyPQC.rng = rng
end

function set_rng(f::Function, rng::AbstractRNG)
    old_rng = NistyPQC.rng
    set_rng(rng)
    try
        return f()
    finally
        set_rng(old_rng)
    end
end

include("Utilities/Utilities.jl")
include("MLKEM/MLKEM.jl")
include("MLDSA/MLDSA.jl")
include("SLHDSA/SLHDSA.jl")
include("Falcon/Falcon.jl")
include("BIKE/BIKE.jl")

end # module
