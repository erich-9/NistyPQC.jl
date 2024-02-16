module General

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
    for i ∈ length(bytes):-1:1
        bytes[i] = t % UInt8
        t >>= 8
    end
end

function base_2ᵇ(bytes, b, out_len, IntType = Int)
    # @assert out_len * b ≤ 8 * length(bytes)

    i = 1
    b̂ = 0
    t = zero(IntType)
    ys = Vector{IntType}(undef, out_len)
    for j ∈ 1:out_len
        while b̂ < b
            t = (t << 8) + bytes[i]
            i += 1
            b̂ += 8
        end
        b̂ -= b
        ys[j] = (t >> b̂) & (oneunit(IntType) << b - 1)
    end
    ys
end

end # General
