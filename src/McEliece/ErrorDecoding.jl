module ErrorDecoding

import ..Rings: Fz̄, Fz̄y, degree
import ..n, ..t

function decode(c, g, α)
    g² = g^2
    L = [Fz̄y([w, one(Fz̄)]) for w ∈ view(α, 1:n)]
    A = prod(L)
    B = sum((v / g²(w)) * (A ÷ l) for (v, w, l) ∈ zip(c, α, L))
    (d, a, b) = approximant(A, B)
    e = BitVector(iszero(a(α[i])) for i ∈ 1:n)
    if count(isone, e) == t && iszero(A % a) && degree(d) < n - 2t + degree(a)
        e
    end
end

function approximant(A::Fz̄y, B::Fz̄y)
    (a, ã) = (zero(Fz̄y), one(Fz̄y))
    (d, d̃) = (A, B)

    while degree(ã) ≤ t
        x = d ÷ d̃
        (a, ã) = (ã, a - x * ã)
        (d, d̃) = (d̃, d - x * d̃)

        if iszero(d̃)
            if degree(ã) ≤ t
                a = ã
                d = d̃
            end
            break
        end
    end

    (d, a, (a * B) ÷ A)
end

end # module
