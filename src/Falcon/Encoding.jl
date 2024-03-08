module Encoding

import ....Utilities: bits2revbytes, revbytes2bits, bits2int, bits2uint, int2bits
import ..lg_n, ..n, ..Fq, ..bitlengths, ..lengths
import ..PublicKey, ..SecretKey, ..Signature

import ArgCheck: @argcheck
import Base.Iterators: flatten, partition

const length_sig_unsalted = lengths.sig - lengths.salt - 1

function encode(pk::PublicKey)
    res = headerbits([0, 0, 0, 0])
    for coeff ∈ pk.h
        append!(res, int2bits(coeff.data, bitlengths.h))
    end
    bits2revbytes(res)
end

function decode(::Type{PublicKey}, bytes::AbstractVector{UInt8})
    @argcheck length(bytes) == lengths.pk
    @argcheck bytes[begin] == headerbyte([0, 0, 0, 0])

    bits = revbytes2bits(@view bytes[(begin + 1):end])
    PublicKey(map(Fq{Int} ∘ bits2uint, partition(bits, bitlengths.h)))
end

function encode(sk::SecretKey)
    res = headerbits([0, 1, 0, 1])
    for coeff ∈ flatten([sk.f, sk.g])
        append!(res, int2bits(coeff, bitlengths.fg))
    end
    for coeff ∈ sk.F
        append!(res, int2bits(coeff, bitlengths.FG))
    end
    bits2revbytes(res)
end

function decode(::Type{SecretKey}, bytes::AbstractVector{UInt8})
    @argcheck length(bytes) == lengths.sk
    @argcheck bytes[begin] == headerbyte([0, 1, 0, 1])

    bits = revbytes2bits(@view bytes[(begin + 1):end])
    bits_fg = @view bits[begin:(begin + 2n * bitlengths.fg - 1)]
    bits_F = @view bits[(end - n * bitlengths.FG + 1):end]

    (f, g) = partition(map(bits2int, partition(bits_fg, bitlengths.fg)), n)
    F = map(bits2int, partition(bits_F, bitlengths.FG))

    SecretKey(f, g, F)
end

function maybe_encode(sig::Signature)
    s₂_compressed = compress(sig.s₂)

    if s₂_compressed === nothing
        return nothing
    end

    res = [headerbyte([0, 0, 1, 1])]
    append!(res, sig.salt)
    append!(res, bits2revbytes(s₂_compressed))
    res
end

function maybe_decode(::Type{Signature}, bytes::AbstractVector{UInt8})
    if length(bytes) != lengths.sig || bytes[begin] != headerbyte([0, 0, 1, 1])
        return nothing
    end

    salt = @view bytes[(begin + 1):(begin + lengths.salt)]
    s₂ = decompress(revbytes2bits(@view bytes[(end - length_sig_unsalted + 1):end]))

    s₂ === nothing ? nothing : Signature(salt, s₂)
end

function headerbits(typecode)
    BitVector([typecode; int2bits(lg_n, 4)])
end

function headerbyte(typecode)
    bits2revbytes(headerbits(typecode))[]
end

function compress(s::AbstractVector{Int}, length_out::Integer = 8length_sig_unsalted)
    res = BitVector(undef, length_out)

    p = firstindex(res)
    @inbounds for x ∈ s
        res[p] = x < 0

        (y, k) = (abs(x) % (1 << 7), abs(x) >> 7)

        p + 8 + k > length_out && return nothing

        res[(p + 1):(p + 7)] = int2bits(y, 7)
        res[(p + 8):(p + 8 + k - 1)] .= false
        res[p + 8 + k] = true

        p += k + 9
    end
    res[p:end] .= false

    res
end

function decompress(bits::AbstractVector{Bool})
    res = Vector{Int}(undef, n)

    p = firstindex(bits)
    @inbounds for i ∈ 1:n
        l = findfirst(bits[(p + 8):end])
        l === nothing && return nothing

        res[i] = (-1)^bits[p] * evalpoly(2, [reverse(bits[(p + 1):(p + 7)]); l - 1])

        p += l + 8
    end
    any(bits[p:end]) && return nothing

    res
end

end # module
