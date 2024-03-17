module General

import ..Parameters: q, δ_t

function modq⁺⁻(x)
    mod⁺⁻(x, q)
end

function mod⁺⁻(x, y)
    r = mod(x, y)
    r ≤ y >> 1 ? r : r - y
end

function power2_round(r)
    r⁺ = mod(r, q)
    r₀ = mod⁺⁻(r⁺, 1 << δ_t)
    ((r⁺ - r₀) >> δ_t, r₀)
end

end # module
