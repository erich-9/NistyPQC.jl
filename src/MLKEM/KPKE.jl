module KPKE

import ....Utilities: split_equally
import ...Parameters: n₂, dₘₐₓ, lengths, PRF, XOF, G
import ...General: compress, decompress, byte_encode, byte_decode
import ...NumberTheory: Rq, Tq, ntt, ntt⁻¹
import ...Sampling: sample_ntt, sample_polycbd

import ..rng, ..k, ..η₁, ..η₂, ..dᵤ, ..dᵥ, ..λ

import Base.Iterators: partition

function generate_keys(; d = rand(rng, UInt8, n₂))
    (ρ, σ) = G(d)

    B̂ = [sample_ntt(XOF(ρ, j, i)) for i ∈ 0:(k - 1), j ∈ 0:(k - 1)]
    ŝ = ntt.([sample_polycbd(PRF(η₁, σ, i + 0k)) for i ∈ 0:(k - 1)])
    ê = ntt.([sample_polycbd(PRF(η₁, σ, i + 1k)) for i ∈ 0:(k - 1)])

    t̂ = B̂ * ŝ + ê

    ek = [byte_encode.(dₘₐₓ, t̂)...; ρ]
    dk = [byte_encode.(dₘₐₓ, ŝ)...;]

    (; ek, dk)
end

function encrypt(ek, m, r)
    t̂ = Tq.(split_equally(byte_decode(dₘₐₓ, ek[begin:(end - lengths.K)]), k))
    ρ = ek[(end - lengths.K + 1):end]

    B̂ = [sample_ntt(XOF(ρ, j, i)) for i ∈ 0:(k - 1), j ∈ 0:(k - 1)]
    r̂ = ntt.([sample_polycbd(PRF(η₁, r, i + 0k)) for i ∈ 0:(k - 1)])
    e₁ = [sample_polycbd(PRF(η₂, r, i + 1k)) for i ∈ 0:(k - 1)]
    e₂ = sample_polycbd(PRF(η₂, r, 2k))

    u = ntt⁻¹.(transpose(B̂) * r̂) + e₁
    μ = Rq(decompress(1, byte_decode(1, m)))
    v = ntt⁻¹(transpose(t̂) * r̂) + e₂ + μ

    c₁ = byte_encode.(dᵤ, compress.(dᵤ, u))
    c₂ = byte_encode(dᵥ, compress(dᵥ, v))

    [c₁...; c₂]
end

function decrypt(dk, c)
    c₁ = partition(c[begin:(begin + n₂ * dᵤ * k - 1)], n₂ * dᵤ)
    c₂ = c[(end - n₂ * dᵥ + 1):end]

    u = Rq.(decompress.(dᵤ, byte_decode.(dᵤ, c₁)))
    v = Rq(decompress(dᵥ, byte_decode(dᵥ, c₂)))
    ŝ = Tq.(byte_decode.(dₘₐₓ, split_equally(dk, k)))

    w = v - ntt⁻¹(transpose(ŝ) * ntt.(u))

    byte_encode(1, compress(1, w))
end

end # module
