module Sampling

import ....Utilities: bytes2bits
import ...Matrices: rref!, semisystematic_form!, swap!, swap_cols!
import ..Rings: Fz̄, Fz̄y, Fz̄ȳ, coeffs
import ..n, ..m, ..t, ..k, ..τ, ..μ, ..ν, ..σ₁, ..σ₂

import Base.Iterators: partition

function matgen!(α, g)
    H̃ = Matrix{Fz̄}(undef, t, n)
    H̃[1, :] = [inv(g(x)) for x ∈ α]
    for i ∈ 2:t
        H̃[i, :] = view(H̃, i - 1, :) .* α
    end

    H̄ = [BitVector(undef, n) for _ ∈ 1:(m * t)]
    for i ∈ 1:t
        i₀ = m * (i - 1)
        for j ∈ 1:n
            for (i₁, x) ∈ enumerate(coeffs(Bool, H̃[i, j]))
                H̄[i₀ + i₁][j] = x
            end
        end
    end

    p = semisystematic_form!(H̄, μ, ν)
    p !== nothing || return nothing

    H = [H̄[i][j] for i ∈ 1:(m * t), j ∈ 1:n]

    for s ∈ 1:μ
        i = s + m * t - μ
        swap_cols!(H, i, p[s])
        swap!(α, i, p[s])
    end

    (BitMatrix(@view H[:, (end - k + 1):end]), p)
end

function irreducible(bits)
    β = Fz̄ȳ([Fz̄(first(x, m)) for x ∈ partition(bits, σ₁)])

    x = Vector{Fz̄ȳ}(undef, t + 1)
    x[1] = one(Fz̄ȳ)
    for i ∈ 2:(t + 1)
        x[i] = x[i - 1] * β
    end

    x̂ = hcat((vcat(coeffs(Fz̄, a)...) for a ∈ x)...)
    rref!(x̂) == t || return nothing

    Fz̄y([view(x̂, :, t + 1); one(Fz̄)])
end

function field_ordering(bits)
    a = [evalpoly(2, x) for x ∈ partition(bits, σ₂)]
    allunique(a) || return nothing
    [Fz̄(digits(Bool, x - 1; base = 2, pad = m); high2low = true) for x ∈ sortperm(a)]
end

function fixed_weight(rng)
    while true
        bits = bytes2bits(rand(rng, UInt8, σ₁ * τ ÷ 8))
        d = [evalpoly(2, first(coeffs, m)) + 1 for coeffs ∈ partition(bits, σ₁)]
        a = first(filter(≤(n), d), t)
        (length(a) == t && allunique(a)) || continue
        return (e = falses(n); e[a] .= true; e)
    end
end

end # module
