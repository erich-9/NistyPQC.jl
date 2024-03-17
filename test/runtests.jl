module TestNistyPQC

using Test

include("Aqua.jl")

include("Utilities/Utilities.jl")
include("MLKEM/runtests.jl")
include("MLDSA/runtests.jl")
include("SLHDSA/runtests.jl")
include("BIKE/runtests.jl")
include("Falcon/runtests.jl")

end # module
