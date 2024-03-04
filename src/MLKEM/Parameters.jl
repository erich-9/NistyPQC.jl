module Parameters

import Base.Iterators: countfrom, filter, partition, take
import OrderedCollections: OrderedDict
import Primes: isprime
import SHA: sha3_256, sha3_512
import SHAKE: shake256, shake128_xof

const (ω, κ) = (8, 4)

# number of bytes to take from the hash function ...
const length_H = 32 # ... in H once
const length_J = 32 # ... in J once
const length_K = 32 # ... in G twice

# number of random bytes for implicit rejection
const length_R = 32

const n = 1 << ω # = 256
const n₀ = n >> 1 # = 128
const n₁ = n >> 2 # = 64
const n₂ = n >> 3 # = 32

const q = first(filter(isprime, countfrom(κ * n + 1, n))) # = 3329

const dₘₐₓ = ceil(Int, log2(q)) # = 12
const ζ = findfirst(x -> powermod(x, n₀, q) == q - 1, 1:q) # 17
const n₀⁻¹ = invmod(n₀, q) # = 3303

const β = typemax(UInt8) + 1 # = 256
const ξ = (1 << dₘₐₓ) ÷ β # = 16

PRF(η, s, b) = shake256([s; UInt8(b)], UInt(n₁ * η))
XOF(ρ, i, j) = shake128_xof([ρ; UInt8(i); UInt8(j)])

H(s) = sha3_256(s)[1:length_H]
J(s) = shake256(s, UInt(length_J))

G(c) = Tuple(take(partition(sha3_512(c), length_K), 2))

const level_parameters = OrderedDict(
    :Level1 => (1, 2, (3, 2), (10, 4)), # ML-KEM-512
    :Level3 => (3, 3, (2, 2), (10, 4)), # ML-KEM-768
    :Level5 => (5, 4, (2, 2), (11, 5)), # ML-KEM-1024
)

function derived_parameters(level, base_parameters)
    (level_number, k, (η₁, η₂), (dᵤ, dᵥ)) = base_parameters

    (;
        identifier = "ML-KEM-$(k * n)",
        λ = n₂ * dₘₐₓ * k, # = 384k
    )
end

end # module
