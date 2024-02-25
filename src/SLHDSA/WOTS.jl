module WOTS

import ....Utilities: int2bytes
import ...General: base_2ᵇ
import ..Addressing:
    change_type_to_wots_pk!, change_type_to_wots_prf!, set_chain_address!, set_hash_address!
import ..parameters_wots as π

function pk!(adrs)
    pk_from_chain_value(adrs, chain_value!(adrs, Iterators.repeated(π.w - 1)))
end

function sign_message!(adrs, msg)
    chain_value!(adrs, base_2ᵇ_with_csum(msg))
end

function pk_from_signature!(adrs, sig_wots, msg)
    # @assert length(sig_wots) == π.σ

    msg_2ᵇ = base_2ᵇ_with_csum(msg)

    value = Vector{UInt8}(undef, π.σ)
    for i ∈ 0:(π.ℓ - 1)
        set_chain_address!(adrs, i)

        x = msg_2ᵇ[i + 1]
        r = (π.n * i + 1):(π.n * (i + 1))
        value[r] = chain!(adrs, sig_wots[r], x, π.w - 1 - x)
    end

    pk_from_chain_value(adrs, value)
end

function chain_value!(adrs, steps)
    value = Vector{UInt8}(undef, π.σ)

    sk_adrs = copy(adrs)
    change_type_to_wots_prf!(sk_adrs)

    for (i, s) ∈ zip(0:(π.ℓ - 1), steps)
        set_chain_address!(adrs, i)
        set_chain_address!(sk_adrs, i)

        value[(π.n * i + 1):(π.n * (i + 1))] =
            chain!(adrs, π.PRF(sk_adrs, adrs.sk_seed, π.n), 0, s)
    end

    value
end

function chain!(adrs, bytes, i, s)
    # @assert length(bytes) == π.n
    # @assert i + s < π.w

    tmp = bytes

    for j ∈ i:(i + s - 1)
        set_hash_address!(adrs, j)
        tmp = π.PRF(adrs, tmp, π.n)
    end

    tmp
end

function pk_from_chain_value(adrs, value)
    wots_pk_adrs = copy(adrs)
    change_type_to_wots_pk!(wots_pk_adrs)

    π.H(wots_pk_adrs, value, π.ρ)
end

const exp_csum = mod(-(π.ℓ₂ * π.lg_w), 8)
const len_csum = cld(π.ℓ₂ * π.lg_w, 8)

function base_2ᵇ_with_csum(msg)
    # @assert length(msg) == π.n

    res = Vector{Int}(undef, π.ℓ)

    res[1:(π.ℓ₁)] = base_2ᵇ(msg, π.lg_w, π.ℓ₁)

    csum = sum(π.w - 1 - x for x ∈ res[1:(π.ℓ₁)]) << exp_csum
    csum_bytes = int2bytes(csum, len_csum)

    res[(π.ℓ₁ + 1):(π.ℓ)] = base_2ᵇ(csum_bytes, π.lg_w, π.ℓ₂)

    res
end

end # module
