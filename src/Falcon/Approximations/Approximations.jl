module Approximations

include("Exp.jl")
include("Gaussian.jl")

import .Exp: polyapprox_of_2ᵅexp
import .Gaussian: w, rcdt

end # module
