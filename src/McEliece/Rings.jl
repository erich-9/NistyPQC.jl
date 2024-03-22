module Rings

import ..m, ..t, ..q, ..f, ..F

import GaloisFields: GaloisField
import Polynomials: Polynomial, degree, variable

const (Fz̄, z̄) = GaloisField(2, :z̄ => [i ∈ f for i ∈ 0:m])

const (Fȳ, ȳ) = GaloisField(Fz̄, :ȳ => let
    coeffs = zeros(Fz̄, t + 1)
    for x ∈ F
        if x isa Tuple
            coeffs[first(x) + 1] = sum(z̄^i for i ∈ last(x))
        else
            coeffs[x + 1] = one(Fz̄)
        end
    end
    coeffs
end)

function coeffs_F2(x::Fz̄)
    digits(Bool, x.n; base = 2, pad = m)
end

end # module
