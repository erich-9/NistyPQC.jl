module Parameters

import Base.Iterators: countfrom, filter, partition, take
import OrderedCollections: OrderedDict
import Primes: isprime
import SHA: sha3_256, sha3_512
import SHAKE: shake256, shake128_xof

const (lg_n, κ) = (8, 4)

const lengths = (;
    # number of bytes to take from the hash function ...
    H = 32, # ... in H once
    J = 32, # ... in J once
    K = 32, # ... in G twice
    # number of random bytes for implicit rejection
    R = 32,
)

const n = 1 << lg_n # = 256
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

H(s) = sha3_256(s)[1:(lengths.H)]
J(s) = shake256(s, UInt(lengths.J))

G(c) = Tuple(take(partition(sha3_512(c), lengths.K), 2))

const category_parameters = OrderedDict(
    :Category1 => (1, 2, (3, 2), (10, 4)), # ML-KEM-512
    :Category3 => (3, 3, (2, 2), (10, 4)), # ML-KEM-768
    :Category5 => (5, 4, (2, 2), (11, 5)), # ML-KEM-1024
)

function derived_parameters(category, base_parameters)
    (category_number, k, (η₁, η₂), (dᵤ, dᵥ)) = base_parameters

    λ = n₂ * dₘₐₓ * k # = 384k

    length_ek = λ + lengths.K
    length_dk = λ + length_ek + lengths.H + lengths.R
    length_c = n₂ * (dᵤ * k + dᵥ)

    category_lengths = (; lengths..., ek = length_ek, dk = length_dk, c = length_c)

    (; identifier = "ML-KEM-$(k * n)", λ, lengths = category_lengths)
end

end # module
