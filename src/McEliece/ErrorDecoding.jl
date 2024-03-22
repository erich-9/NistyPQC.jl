module ErrorDecoding

import ..Rings: Polynomial, degree, Fz̄
import ..n, ..t

function decode(c, g, α)
    g² = g^2
    L = [Polynomial([w, one(Fz̄)], :y) for w ∈ view(α, 1:n)]
    A = prod(L)
    B = sum((v / g²(w)) * (A ÷ l) for (v, w, l) ∈ zip(c, α, L))
    (d, a, b) = approximant(A, B)
    e = BitVector(iszero(a(α[i])) for i ∈ 1:n)
    if count(isone, e) == t && iszero(A % a) && degree(d) < n - 2t + degree(a)
        e
    end
end

function approximant(A::Polynomial{T, V}, B::Polynomial{T, V}) where {T, V}
    (a, ã) = (zero(Polynomial{T}, V), one(Polynomial{T}, V))
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
