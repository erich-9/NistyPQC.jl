module General

import ..r, ..r_bytes

function from_bytes(bytes::AbstractVector{UInt8})
    bits = BitVector(undef, r)
    j = 1
    byte = bytes[j]
    for i ∈ 1:r
        bits[i] = isone(byte % 2)
        if iszero(i % 8)
            j += 1
            byte = bytes[j]
        else
            byte >>= 1
        end
    end
    bits
end

function to_bytes(bits::AbstractVector{Bool})
    bytes = zeros(UInt8, r_bytes)
    j = 1
    for (i, bit) ∈ enumerate(bits)
        bytes[j] |= bit << ((i - 1) % 8)
        if iszero(i % 8)
            j += 1
        end
    end
    bytes
end

end # module
