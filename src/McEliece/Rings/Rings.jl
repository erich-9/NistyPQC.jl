module Rings

abstract type Raw end
abstract type Ring <: Number end

include("BaseField.jl")
include("Polynomials.jl")
include("ExtensionField.jl")

import .BaseField: Fz̄, z̄, coeffs
import .Polynomials: Fz̄y, y, coeffs, degree
import .ExtensionField: Fz̄ȳ, ȳ, coeffs

end # module
