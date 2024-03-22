module Sampling

import ....Utilities: bytes2bits
import ...Matrices: rref!, semisystematic_form!, swap!, swap_cols!
import ..Rings: Polynomial, variable, Fz̄, z̄, Fȳ, ȳ, coeffs_F2
import ..n, ..m, ..t, ..k, ..τ, ..μ, ..ν, ..σ₁, ..σ₂

import Base.Iterators: partition

function matgen!(α, g)
    H̃ = Matrix{Fz̄}(undef, t, n)
    H̃[1, :] = [g(x)^-1 for x ∈ α]
    for i ∈ 2:t
        H̃[i, :] = view(H̃, i - 1, :) .* α
    end

    H = vcat((hcat((coeffs_F2(H̃[i, j]) for j ∈ 1:n)...) for i ∈ 1:t)...)

    p = semisystematic_form!(H, μ, ν)
    p !== nothing || return nothing

    for s ∈ 1:μ
        i = s + m * t - μ
        swap_cols!(H, i, p[s])
        swap!(α, i, p[s])
    end

    (BitMatrix(@view H[:, (end - k + 1):end]), p)
end

function irreducible(bits)
    β = evalpoly(ȳ, [evalpoly(z̄, first(x, m)) for x ∈ partition(bits, σ₁)])

    x = Vector{Fȳ}(undef, t + 1)
    x[1] = one(Fȳ)
    for i ∈ 2:(t + 1)
        x[i] = x[i - 1] * β
    end

    x̂ = hcat((vcat(e.coeffs...) for e ∈ x)...)
    rref!(x̂) == t || return nothing

    g = Polynomial(view(x̂, :, t + 1), :y)
    g + variable(g)^t
end

function field_ordering(bits)
    a = [evalpoly(2, x) for x ∈ partition(bits, σ₂)]
    allunique(a) || return nothing
    [evalpoly(z̄, reverse(digits(x - 1; base = 2, pad = m))) for x ∈ sortperm(a)]
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
