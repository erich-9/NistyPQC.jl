module Encoding

import ....Utilities: peel, revbits2uint, int2revbits, bits2bytes, bytes2bits
import ...NumberTheory: Rq
import ..n, ..n₂, ..q, ..k, ..ℓ, ..η, ..ω, ..qm_div_2γ₂, ..γ₁, ..γ₂, ..lengths

import ArgCheck: @argcheck
import Base.Iterators: partition

const e_t = 2^(lengths.δ_t - 1)
const f_t = 2^lengths.ϵ_t

function pk_encode(ρ_A, t₁)
    vcat(ρ_A, (simple_bitpack(c, f_t - 1) for c ∈ t₁)...)
end

function pk_decode(pk)
    @argcheck length(pk) == lengths.pk

    c_t = n₂ * lengths.ϵ_t
    (ρ_A, t₁_bytes) = peel(pk, [lengths.ρ_A, k * c_t])
    t₁ = [simple_bitunpack(x, f_t - 1) for x ∈ partition(t₁_bytes, c_t)]

    (ρ_A, t₁)
end

function sk_encode(ρ_A, K, tr, s₁, s₂, t₀)
    vcat(
        (ρ_A, K, tr)...,
        (bitpack(c, η, η) for c ∈ s₁)...,
        (bitpack(c, η, η) for c ∈ s₂)...,
        (bitpack(c, e_t - 1, e_t) for c ∈ t₀)...,
    )
end

function sk_decode(sk)
    @argcheck length(sk) == lengths.sk

    (c_s, c_t) = (n₂ * lengths.δ_s, n₂ * lengths.δ_t)
    (ρ_A, K, tr, s₁_bytes, s₂_bytes, t₀_bytes) =
        peel(sk, [lengths.ρ_A, lengths.K, lengths.tr, ℓ * c_s, k * c_s, k * c_t])

    s₁ = [bitunpack(x, η, η) for x ∈ partition(s₁_bytes, c_s)]
    s₂ = [bitunpack(x, η, η) for x ∈ partition(s₂_bytes, c_s)]
    t₀ = [bitunpack(x, e_t - 1, e_t) for x ∈ partition(t₀_bytes, c_t)]

    (ρ_A, K, tr, s₁, s₂, t₀)
end

function sig_encode(c̃, z, h)
    vcat(c̃, (bitpack(c, γ₁ - 1, γ₁) for c ∈ z)..., hint_bitpack(h))
end

function maybe_sig_decode(σ)
    length(σ) !== lengths.sig && return nothing

    c_z = n₂ * lengths.δ_z
    (c̃, z_bytes, h_bytes) = peel(σ, [lengths.c̃, ℓ * c_z, ω + k])

    z = [bitunpack(x, γ₁ - 1, γ₁) for x ∈ partition(z_bytes, c_z)]
    h = hint_bitunpack(h_bytes)

    h === nothing && return nothing

    (c̃, z, h)
end

function w₁_encode(w₁)
    vcat((simple_bitpack(c, qm_div_2γ₂ - 1) for c ∈ w₁)...)
end

function bitpack(w, a, b)
    simple_bitpack(Rq([b - c for c ∈ w]), a + b)
end

function bitunpack(bytes, a, b)
    Rq([b - c for c ∈ simple_bitunpack(bytes, a + b)])
end

function simple_bitpack(w, b)
    # @assert all(0 ≤ c ≤ b for c ∈ w)

    l = Base.top_set_bit(b)
    bits = BitVector()
    sizehint!(bits, l * length(w))
    for c ∈ w
        append!(bits, int2revbits(c, l))
        int2revbits(c, l)
    end
    bits2bytes(bits)
end

function simple_bitunpack(bytes, b)
    Rq(revbits2uint.(partition(bytes2bits(bytes), Base.top_set_bit(b))))
end

function hint_bitpack(h)
    # @assert length(h) == k && all(length(w) == n for w ∈ h)
    # @assert count(x for v ∈ h for x ∈ v) ≤ ω

    bytes = zeros(UInt8, ω + k)
    index = 0
    for i ∈ 1:k
        for j ∈ 1:n
            if h[i][j]
                bytes[index + 1] = j - 1
                index += 1
            end
        end
        bytes[ω + i] = index
    end
    bytes
end

function hint_bitunpack(bytes)
    h = [falses(n) for _ ∈ 1:k]
    index = 0
    for i ∈ 1:k
        index ≤ bytes[ω + i] ≤ ω || return nothing
        while index < bytes[ω + i]
            h[i][bytes[index + 1] + 1] = true
            index += 1
        end
    end
    while index < ω
        iszero(bytes[index + 1]) || return nothing
        index += 1
    end
    h
end

end # module
