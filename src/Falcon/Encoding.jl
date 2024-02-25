module Encoding

import ....Utilities: bits2bytes, bytes2bits, bits2int, bits2uint, int2bits, bytes2int
import ..lg_n, ..n, ..q, ..Fq, ..length_sig, ..length_salt
import ..PublicKey, ..SecretKey, ..Signature

import ArgCheck: @argcheck
import Base.Iterators: flatten, partition

const bitlength_coeff = (; fg = min(8, 10 - lg_n ÷ 2), FG = 8, h = ceil(Int, log(2, q)))
const length_pk = cld(n * bitlength_coeff.h + 8, 8)
const length_sk = cld(n * (2bitlength_coeff.fg + bitlength_coeff.FG) + 8, 8)
const length_sig_unsalted = length_sig - length_salt - 1

bits2revbytes(bits) = bitreverse.(bits2bytes(bits))
revbytes2bits(bytes) = bytes2bits(bitreverse.(bytes))

function encode(pk::PublicKey)
    res = headerbits([0, 0, 0, 0])

    for coeff ∈ pk.h
        append!(res, int2bits(coeff.data, bitlength_coeff.h))
    end

    bits2revbytes(res)
end

function decode(::Type{PublicKey}, bytes::AbstractVector{UInt8})
    @argcheck length(bytes) == length_pk
    @argcheck bytes[begin] == headerbyte([0, 0, 0, 0])

    bits = revbytes2bits(bytes[(begin + 1):end])

    PublicKey(map(Fq{Int} ∘ bits2uint, partition(bits, bitlength_coeff.h)))
end

function encode(sk::SecretKey)
    res = headerbits([0, 1, 0, 1])

    for coeff ∈ flatten([sk.f, sk.g])
        append!(res, int2bits(coeff, bitlength_coeff.fg))
    end

    for coeff ∈ sk.F
        append!(res, int2bits(coeff, bitlength_coeff.FG))
    end

    bits2revbytes(res)
end

function decode(::Type{SecretKey}, bytes::AbstractVector{UInt8})
    @argcheck length(bytes) == length_sk
    @argcheck bytes[begin] == headerbyte([0, 1, 0, 1])

    bits = revbytes2bits(bytes[(begin + 1):end])
    bits_fg = @view bits[begin:(begin + 2n * bitlength_coeff.fg - 1)]
    bits_F = @view bits[(end - n * bitlength_coeff.FG + 1):end]

    (f, g) = partition(map(bits2int, partition(bits_fg, bitlength_coeff.fg)), n)
    F = map(bits2int, partition(bits_F, bitlength_coeff.FG))

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
    if length(bytes) != length_sig || bytes[begin] != headerbyte([0, 0, 1, 1])
        return nothing
    end

    salt = bytes[(begin + 1):(begin + length_salt)]
    s₂ = decompress(revbytes2bits(bytes[(end - length_sig_unsalted + 1):end]))

    if s₂ === nothing
        return nothing
    else
        Signature(salt, s₂)
    end
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
    for x ∈ s
        res[p] = x < 0

        (y, k) = (abs(x) % (1 << 7), abs(x) >> 7)

        if p + 8 + k > length_out
            return nothing
        end

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
    for i ∈ 1:n
        l = findfirst(bits[(p + 8):end])

        if l === nothing
            return nothing
        end

        res[i] = (-1)^bits[p] * evalpoly(2, [reverse(bits[(p + 1):(p + 7)]); l - 1])

        p += l + 8
    end
    if any(bits[p:end])
        return nothing
    end

    res
end

end # module
