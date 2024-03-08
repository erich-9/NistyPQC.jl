module Gaussian

import Base.Iterators: countfrom, takewhile

ρ(σ, z) = exp(-(big(z) / σ)^2 / 2)

function w(σ::Real, θ::Integer, lg_Q_bs::Integer)
    setprecision(BigFloat, 2(θ + lg_Q_bs + 2)) do
        renyi_divergence_bound = 1 / big(2)^(lg_Q_bs + 2)
        eps = renyi_divergence_bound / big(2)^θ

        ρ_sum_uint = sum(takewhile(>(eps), ρ(σ, z) for z ∈ countfrom(0)))
        ρ_sum_w = zero(BigFloat)

        w = 0
        while true
            ρ_sum_w += ρ(σ, w)
            if ρ_sum_uint / ρ_sum_w ≤ 1 + renyi_divergence_bound
                break
            end
            w += 1
        end
        return w
    end
end

function rcdt(σ::Real, θ::Integer, w::Integer, IntType::Type{<:Integer} = Int128)
    setprecision(BigFloat, 2θ) do
        ρ_sum_w = sum(ρ(σ, z) for z ∈ 0:w)
        D_w(σ, z) = ρ(σ, z) / ρ_sum_w

        rcdt = Vector{IntType}(undef, w)
        rcdt[w] = 0
        for z ∈ (w - 1):-1:1
            rcdt[z] = rcdt[z + 1] + floor(IntType, big(2)^θ * D_w(σ, z))
        end
        return rcdt
    end
end

end #module
