module Utilities

export split_equally
export mgf1

include("General.jl")
include("Hashing.jl")

import .General: split_equally
import .Hashing: mgf1

end # module
