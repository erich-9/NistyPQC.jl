module Sampling

import ....Utilities: peel, bytes2bits, int2lebytes
import ...Parameters: τ_max_cld_8
import ...NumberTheory: Rq, Tq
import ..Encoding: bitunpack
import ..n, ..n₂, ..q, ..k, ..ℓ, ..τ, ..η, ..γ₁, ..lengths, ..H, ..H₁₂₈

function expand_A(ρ_A)
    Â = Matrix{Tq}(undef, (k, ℓ))

    for r ∈ 0:(k - 1)
        r_bytes = int2lebytes(r, 1)
        for s ∈ 0:(ℓ - 1)
            s_bytes = int2lebytes(s, 1)
            Â[r + 1, s + 1] = rej_ntt_poly(vcat(ρ_A, s_bytes, r_bytes))
        end
    end

    Â
end

function expand_S(ρ_S)
    s₁ = [rej_bounded_poly(vcat(ρ_S, int2lebytes(r + 0, 2))) for r ∈ 0:(ℓ - 1)]
    s₂ = [rej_bounded_poly(vcat(ρ_S, int2lebytes(r + ℓ, 2))) for r ∈ 0:(k - 1)]

    (s₁, s₂)
end

function expand_mask(ρ_mask, κ)
    c_z = n₂ * lengths.δ_z
    [bitunpack(H(vcat(ρ_mask, int2lebytes(κ + r, 2)), c_z), γ₁ - 1, γ₁) for r ∈ 0:(ℓ - 1)]
end

function sample_in_ball(seed)
    c = zeros(Int, n)

    (bytes, bytestream) = peel(H(seed), τ_max_cld_8)
    (bits, j) = (bytes2bits(bytes), undef)
    for i ∈ (n - τ):(n - 1)
        while true
            (j, bytestream) = peel(bytestream)
            j ≤ i && break
        end
        c[i + 1] = c[j + 1]
        c[j + 1] = iseven(bits[i + τ - n + 1]) ? 1 : -1
    end

    Rq(c)
end

function rej_ntt_poly(seed)
    â = Vector{Int}(undef, n)

    bytestream = H₁₂₈(seed)
    j = 1
    while j ≤ n
        (bytes, bytestream) = peel(bytestream, 3)

        z = coeff_from_three_bytes(bytes...)
        if z !== nothing
            â[j] = z
            j += 1
        end
    end

    Tq(â)
end

function rej_bounded_poly(seed)
    a = Vector{Int}(undef, n)

    bytestream = H(seed)
    j = 1
    while j ≤ n
        (byte, bytestream) = peel(bytestream)
        (b₁, b₀) = divrem(Int(byte), 16)

        z₀ = coeff_from_halfbyte(b₀)
        if z₀ !== nothing
            a[j] = z₀
            j += 1
        end

        z₁ = coeff_from_halfbyte(b₁)
        if z₁ !== nothing && j ≤ n
            a[j] = z₁
            j += 1
        end
    end

    Rq(a)
end

function coeff_from_three_bytes(b₀, b₁, b₂)
    z = 2^16 * (b₂ % 128) + 2^8 * b₁ + b₀
    z < q ? z : nothing
end

@eval function coeff_from_halfbyte(b)
    if $η == 2
        b < 15 ? 2 - b % 5 : nothing
    elseif $η == 4
        b < 9 ? 4 - b : nothing
    end
end

end # module
