module General

import ...Utilities: bits2bytes, bytes2bits
import ..Parameters: n, n₂, q, dₘₐₓ

function compress(d, x::Integer)
    div(x << d, q, RoundNearestTiesUp)
end

function decompress(d, y::Integer)
    div(y * q, 1 << d, RoundNearestTiesUp)
end

function compress(d, x)
    compress.(d, x)
end

function decompress(d, y)
    decompress.(d, y)
end

function byte_encode(d, F)
    # @assert length(F) % n == 0

    m = d < dₘₐₓ ? 1 << d : q
    l = length(F)

    b = BitVector(undef, l * d)
    @inbounds for i ∈ 0:(l - 1)
        a = F[i + 1]
        for j ∈ 1:d
            x = b[i * d + j] = a % 2
            a = (a - x) >> 1
        end
    end

    bits2bytes(b)
end

function byte_decode(d, B)
    # @assert length(B) % (d * n₂) == 0

    m = d < dₘₐₓ ? 1 << d : q
    b = bytes2bits(B)
    l = length(b) ÷ d

    F = Vector{Int}(undef, l)
    @inbounds for i ∈ 0:(l - 1)
        F[i + 1] = mod(sum(b[i * d + j] << (j - 1) for j ∈ 1:d), m)
    end

    F
end

end # module
