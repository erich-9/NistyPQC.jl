module Hashing

import ..Ring
import ..ℓ

import SHA: sha3_384

function K̂(m::AbstractVector{UInt8}, c::AbstractVector{UInt8})
    sha3_384([m; c])[1:ℓ]
end

function L̂(e₀::Ring.Element, e₁::Ring.Element)
    sha3_384([Ring.to_bytes(e₀); Ring.to_bytes(e₁)])[1:ℓ]
end

end # module
