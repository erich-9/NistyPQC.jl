module Hashing

import ..n, ..t, ..q, ..σ₁, ..σ₂, ..lengths

import CryptographicHashFunctions: shake256

H(x) = shake256(x, lengths.K)
G(x) = shake256([0x1 << 6; x], (n + σ₂ * q + σ₁ * t) ÷ 8 + lengths.δ)

end # module
