module TestNistyPQC

using Test

include("Aqua.jl")

include("Utilities/Utilities.jl")
include("MLKEM/runtests.jl")
include("SLHDSA/runtests.jl")

end # module
