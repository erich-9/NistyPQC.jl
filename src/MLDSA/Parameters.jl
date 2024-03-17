module Parameters

import OrderedCollections: OrderedDict
import SHAKE: shake128_xof, shake256_xof, shake256

const lg_n = 8
const q = 8_380_417
const δ_t = 13

const n = 1 << lg_n # = 256
const n₂ = n >> 3 # = 32

const ζ = findfirst(x -> powermod(x, n, q) == q - 1, 1:q) # 1753
const n⁻¹ = invmod(n, q) # = 8_347_681

const ϵ_t = Base.top_set_bit(q - 1) - δ_t # = 10

const lengths =
    (; c̃₁ = 32, ξ = 32, ρ_A = 32, ρ_S = 64, ρ_mask = 64, K = 32, tr = 64, μ = 64, rnd = 32)

H(x) = shake256_xof(x)
H(x, len) = shake256(x, len)
H₁₂₈(x) = shake128_xof(x)

const level_parameters = OrderedDict(
    :Level2 => (2, 16, (4, 4), 39, 2, 80, 44, 17), # ML-DSA-44
    :Level3 => (3, 24, (6, 5), 49, 4, 55, 16, 19), # ML-DSA-65
    :Level5 => (5, 32, (8, 7), 60, 2, 75, 16, 19), # ML-DSA-87
)

const τ_max_cld_8 = cld(maximum(getindex.(values(level_parameters), 4)), 8) # = 8

function derived_parameters(level, base_parameters)
    (level_number, λ, (k, ℓ), τ, η, ω, qm_div_2γ₂, lg_γ₁) = base_parameters

    γ₁ = 1 << lg_γ₁
    γ₂ = (q - 1) ÷ 2qm_div_2γ₂
    β = τ * η

    δ_s = Base.top_set_bit(2η)
    δ_z = Base.top_set_bit(γ₁ - 1) + 1

    length_c̃ = 2λ
    length_pk = lengths.ρ_A + n₂ * k * ϵ_t
    length_sk = lengths.ρ_A + lengths.K + lengths.tr + n₂ * ((k + ℓ) * δ_s + k * δ_t)
    length_sig = length_c̃ + n₂ * ℓ * δ_z + (ω + k)

    level_lengths = (;
        lengths...,
        (; ϵ_t, δ_t, δ_s, δ_z)...,
        (; c̃ = length_c̃, pk = length_pk, sk = length_sk, sig = length_sig)...,
    )

    (; identifier = "ML-DSA-$k$ℓ", γ₁, γ₂, β, lengths = level_lengths)
end

end # module
