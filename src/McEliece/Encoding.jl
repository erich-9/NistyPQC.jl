module Encoding

import ....Utilities: peel, bits2bytes, bytes2bits
import ...Parameters: μν_fast
import ..Rings: Fz̄, Fz̄y, coeffs
import ..fast_variant, ..m, ..t, ..k, ..μ, ..lengths

include("BenesNetwork.jl")

import Base.Iterators: flatten, partition, repeated

@generated function ek_encode(T)
    pad = mod(-k, 8)
    bits = if iszero(pad)
        :(collect(flatten(eachrow(T))))
    else
        :(vcat(flatten(zip(eachrow(T), partition(repeated(false), $pad)))...))
    end
    :(bits2bytes($bits))
end

function ek_decode(pk)
    permutedims(reshape(bytes2bits(pk), (8cld(k, 8), m * t)))[:, 1:k]
end

function dk_encode(δ, p, g, α, s)
    p̃ = fast_variant ? p : collect((1:μν_fast[1]) .+ m * t)
    p̂ = (x = falses(8lengths.p); x[p̃ .- (m * t - μ)] .= true; x)
    ĝ = vcat((BitVector(coeffs(Bool, g[i]; pad = 8cld(m, 8))) for i ∈ 0:(t - 1))...)
    α̂ = BenesNetwork.controlbits([evalpoly(2, reverse(coeffs(Bool, w))) for w ∈ α])

    [δ; bits2bytes([p̂; ĝ; α̂]); s]
end

function dk_decode(dk)
    (δ, p̄, ḡ, ᾱ, s) = peel(dk, [lengths[x] for x ∈ (:δ, :p, :g, :α, :s)])

    p = fast_variant ? findall(bytes2bits(p̄)) .+ (m * t - μ) : Int[]
    g = Fz̄y([(Fz̄(bytes2bits(x)) for x ∈ partition(ḡ, cld(m, 8)))...; one(Fz̄)])
    α = [
        Fz̄(digits(Bool, x; base = 2, pad = m); high2low = true) for
        x ∈ BenesNetwork.permutation(bytes2bits(ᾱ))
    ]

    (δ, p, g, α, s)
end

end # module
