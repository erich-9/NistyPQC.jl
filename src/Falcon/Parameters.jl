module Parameters

include("Approximations/Approximations.jl")

import Base.Iterators: countfrom, filter
import OrderedCollections: OrderedDict
import Primes: isprime

const level_parameters = OrderedDict(
    :Level1 => (1, 7, 9, 666),    # Falcon-512
    :Level5 => (5, 8, 10, 1_280), # Falcon-1024
)

const (_, lg_λ_max, lg_n_max) = maximum(stack(values(level_parameters)), dims = 2)

const q = first(filter(isprime, countfrom(1, 2^(lg_n_max + 1)))) # = 12_289

const lg_Q_s = 64
const lg_Q_bs = lg_Q_s + lg_n_max + 2 # = 76
const length_salt = cld(2^lg_λ_max + lg_Q_s, 8) # = 40

const τ_sig = 1.1
const (σ_max_exact, θ) = (1_8205 // 1_0000, 72) # picked based on experiments
const σ_max = Float64(σ_max_exact)

const sqrt_e_div_2 = round(√(exp(1) / 2), digits = 2) # = 1.17
const e_div_2 = sqrt_e_div_2^2
const σ̄ = sqrt_e_div_2 * √q

# see https://eprint.iacr.org/2019/1411.pdf
const Δw = 1 # correction term (I can't reproduce w = 19 otherwise)
const w = Approximations.w(σ_max_exact, θ, lg_Q_bs) + Δw # = 19  
const rcdt = Approximations.rcdt(σ_max_exact, θ, w)

const C = Approximations.polyapprox_of_2ᵅexp()

function derived_parameters(level, base_parameters)
    (level_number, lg_λ, lg_n, length_sig) = base_parameters

    n = 2^lg_n

    ϵ⁻¹ = 2^((lg_λ + lg_Q_s) / 2)
    η = √(log(4n * (1 + ϵ⁻¹)) / 2) / π

    σ_fg = σ̄ / √(2n)
    σ = η * σ̄
    σ_min = σ / σ̄

    β = τ_sig * σ√(2n)
    β² = floor(Int, β^2)

    bitlengths = (; fg = min(8, 10 - lg_n ÷ 2), FG = 8, h = Base.top_set_bit(q))

    length_pk = cld(n * bitlengths.h + 8, 8)
    length_sk = cld(n * (2bitlengths.fg + bitlengths.FG) + 8, 8)

    lengths = (; sk = length_sk, pk = length_pk, sig = length_sig, salt = length_salt)

    (; identifier = "Falcon-$n", n, σ_fg, σ, σ_min, β², bitlengths, lengths)
end

end # module
