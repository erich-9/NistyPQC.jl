module Hints

import ...Parameters: q
import ...General: mod⁺⁻
import ..qm_div_2γ₂, ..γ₂

function high_bits(r)
    first(decompose(r))
end

function low_bits(r)
    last(decompose(r))
end

function make_hint(z, r)
    high_bits(r) != high_bits(r + z)
end

function use_hint(h, r)
    (r₁, r₀) = decompose(r)
    h ? mod(r₁ + (r₀ > 0 ? 1 : -1), qm_div_2γ₂) : r₁
end

function decompose(r)
    r⁺ = mod(r, q)
    r₀ = mod⁺⁻(r⁺, γ₂ << 1)

    if r⁺ - r₀ == q - 1
        (0, r₀ - 1)
    else
        ((r⁺ - r₀) ÷ 2γ₂, r₀)
    end
end

end # module
