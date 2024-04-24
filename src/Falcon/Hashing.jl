module Hashing

import ....Utilities: bytes2int
import ..n, ..q

import CryptographicHashFunctions: digest!, shake256

function hash_to_point(bytes::AbstractVector{UInt8})
    res = Vector{Int}(undef, n)
    xof = shake256(bytes)
    i = 1
    while true
        bytes = digest!(xof, 2)
        if i > n
            break
        end
        t = bytes2int(bytes)
        if t < ((1 << 16) ÷ q) * q
            res[i] = t % q
            i += 1
        end
    end
    return res
end

end # module
