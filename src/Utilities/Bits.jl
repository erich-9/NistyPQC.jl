module Bits

#=
function bits2bytes(bits)
    bytes = zeros(UInt8, cld(length(bits), 8))
    j = 1
    @inbounds for (i, bit) ∈ enumerate(bits)
        bytes[j] |= bit << ((i - 1) % 8)
        if iszero(i % 8)
            j += 1
        end
    end
    bytes
end

function bytes2bits(bytes, len = 8length(bytes))
    bits = BitVector(undef, len)
    byte = undef
    j = firstindex(bytes)
    @inbounds for i ∈ eachindex(bits)
        if iszero((i - 1) % 8)
            byte = bytes[j]
            j += 1
        end
        bits[i] = isone(byte % 2)
        byte >>= 1
    end
    bits
end
=#

function bits2bytes(bits)
    n = cld(length(bits), 8)
    bytes = Vector{UInt8}(undef, n)
    unsafe_copyto!(pointer(bytes), reinterpret(Ptr{UInt8}, pointer(bits.chunks)), n)
    bytes
end

function bytes2bits(bytes, len = 8length(bytes))
    n = cld(len, 8)
    bits = BitVector(undef, len)
    unsafe_copyto!(reinterpret(Ptr{UInt8}, pointer(bits.chunks)), pointer(bytes), n)
    bits
end

function bits2revbytes(bits)
    bitreverse.(bits2bytes(bits))
end

function revbytes2bits(bytes)
    bytes2bits(bitreverse.(bytes))
end

function bytes2int(bytes, IntType::Type{<:Integer} = Int)
    t = zero(IntType)
    for b ∈ bytes
        t = (t << 8) + b
    end
    t
end

function int2bytes(x::Integer, n::Int)
    bytes = Vector{UInt8}(undef, n)
    int2bytes!(bytes, x)
    bytes
end

function int2bytes!(bytes, x::Integer)
    @inbounds for i ∈ Iterators.reverse(eachindex(bytes))
        bytes[i] = x % UInt8
        x >>= 8
    end
end

function lebytes2int(bytes, IntType::Type{<:Integer} = Int)
    t = zero(IntType)
    for b ∈ Iterators.reverse(bytes)
        t = (t << 8) + b
    end
    t
end

function int2lebytes(x::Integer, n::Int)
    bytes = Vector{UInt8}(undef, n)
    int2lebytes(bytes, x)
    bytes
end

function int2lebytes(bytes, x::Integer)
    @inbounds for i ∈ eachindex(bytes)
        bytes[i] = x % UInt8
        x >>= 8
    end
end

function bits2uint(bits, IntType::Type{<:Integer} = Int)
    revbits2uint(Iterators.reverse(bits), IntType)
end

function bits2int(bits, IntType::Type{<:Integer} = Int)
    revbits2int(Iterators.reverse(bits), IntType)
end

function int2bits(x::Integer, n::Int)
    [c == '1' for c ∈ @view bitstring(x)[(end - n + 1):end]]
end

function revbits2uint(bits, IntType::Type{<:Integer} = Int)
    (res, y) = (zero(IntType), one(IntType))
    for c ∈ bits
        res += c * y
        y <<= 1
    end
    res
end

function revbits2int(bits, IntType::Type{<:Integer} = Int)
    (x, l) = (revbits2uint(bits, IntType), length(bits))
    iszero(x >> (l - 1)) ? x : x - (1 << l)
end

function int2revbits(x::Integer, n::Int)
    reverse!(int2bits(x, n))
end

end # module
