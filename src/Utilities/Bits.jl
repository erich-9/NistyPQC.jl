module Bits

function bits2bytes(bits)
    bytes = Vector{UInt8}(undef, cld(length(bits), 8))
    unsafe_copyto!(
        pointer(bytes),
        reinterpret(Ptr{UInt8}, pointer(bits.chunks)),
        length(bytes),
    )
    bytes
end

function bytes2bits(bytes, len = 8length(bytes))
    bits = BitVector(undef, len)
    unsafe_copyto!(
        reinterpret(Ptr{UInt8}, pointer(bits.chunks)),
        pointer(bytes),
        cld(len, 8),
    )
    bits
end

function bytes2int(bytes::AbstractVector{UInt8}, IntType::Type{<:Integer} = UInt)
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

function int2bytes!(bytes::AbstractVector{UInt8}, x::Integer)
    t = x
    for i ∈ Iterators.reverse(eachindex(bytes))
        bytes[i] = t % UInt8
        t >>= 8
    end
end

function bits2uint(bits::AbstractVector{Bool})
    evalpoly(2, reverse(bits))
end

function bits2int(bits::AbstractVector{Bool})
    x = bits2uint(bits)
    l = length(bits)

    iszero(x >> (l - 1)) ? x : x - (1 << l)
end

function int2bits(x::Integer, len::Integer)
    [c == '1' for c ∈ @view bitstring(x)[(end - len + 1):end]]
end

end # module
