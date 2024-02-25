module Hashing

import ....Utilities: bytes2int
import ..n, ..q

import SHAKE: shake256_xof

function hash_to_point(bytes::AbstractVector{UInt8})
    res = Vector{Int}(undef, n)
    i = 1
    for bytes ∈ Iterators.partition(shake256_xof(bytes), 2)
        if i > n
            break
        end
        t = bytes2int(bytes)
        if t < ((1 << 16) ÷ q) * q
            res[i] = t % q
            i += 1
        end
    end
    res
end

end # module
