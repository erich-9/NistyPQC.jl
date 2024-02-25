module Sampling

import ....rng
import ....Utilities: bytes2int
import ...Parameters: θ, rcdt, C
import ..σ_fg, ..σ_min, ..σ_max

import Base.Iterators: countfrom, filter

const k_fg = first(filter(≥((σ_fg / σ_max)^2), countfrom(1)))

function sample_σ_fg_int()
    return sum(sample_int(0, σ_fg / √k_fg) for _ ∈ 1:k_fg)
end

function sample_int(μ, σ¹)
    @assert σ_min ≤ σ¹ ≤ σ_max

    (r, ccs) = (μ - floor(μ), σ_min / σ¹)
    while true
        z₀ = base_sampler()
        z = uniform_bits(1) * (2z₀ + 1) - z₀
        if bernoulli_exp((((z - r) / σ¹)^2 - (z₀ / σ_max)^2) / 2, ccs)
            return z + floor(Int, μ)
        end
    end
end

function base_sampler()
    u = uniform_bits(θ, Int128)
    sum(u < v for v ∈ rcdt)
end

function bernoulli_exp(x, ccs, polyapprox = C)
    @assert 0 ≤ x

    (s, y) = divrem(x, log(2))
    z = (2 * approx_exp(y, ccs, polyapprox) - 1) >> min(Int(s), polyapprox.α)
    i = polyapprox.α + 1
    while true
        i -= 8
        w = uniform_bits(8) - Int(z >> i % (1 << 8))
        if !(iszero(w) && i > 0)
            return w < 0
        end
    end
end

function approx_exp(x, ccs, polyapprox)
    @assert 0 ≤ x ≤ log(2)
    @assert 0 ≤ ccs ≤ 1

    y = polyapprox.coeffs[begin]
    z = floor(Int128, exp2(polyapprox.α) * x)
    for coeff ∈ @view polyapprox.coeffs[(begin + 1):end]
        y = coeff - UInt((z * y) >> polyapprox.α)
    end
    z = floor(Int128, exp2(polyapprox.α) * ccs)
    UInt((z * y) >> polyapprox.α)
end

function uniform_bits(k, IntType = Int)
    bytes = rand(rng, UInt8, cld(k, 8))
    if !iszero(k % 8)
        bytes[begin] %= 0x01 << (k % 8)
    end
    bytes2int(bytes, IntType)
end

end # module
