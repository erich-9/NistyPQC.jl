module Sampling

import ..Parameters: n, n₁, q, β, ξ
import ..General: bytes2bits
import ..NumberTheory: R_q, T_q

function sample_ntt(B)
    # @assert Base.IteratorSize(B) == Base.IsInfinite()

    â = Vector{Int}(undef, n)

    j = 1
    while j ≤ n
        b₁, B = Iterators.peel(B)
        b₂, B = Iterators.peel(B)
        b₃, B = Iterators.peel(B)

        d₁ = b₁ + β * (b₂ % ξ)
        d₂ = b₂ ÷ ξ + ξ * b₃

        if d₁ < q
            â[j] = d₁
            j += 1
        end
        if d₂ < q && j ≤ n
            â[j] = d₂
            j += 1
        end
    end

    T_q(â)
end

function sample_polycbd(B)
    # @assert length(B) % n₁ == 0

    η = length(B) ÷ n₁
    b = bytes2bits(B)

    f = Vector{Int}(undef, n)
    for i ∈ 0:(n - 1)
        x = sum(b[2i * η + j] for j ∈ 1:η)
        y = sum(b[2i * η + η + j] for j ∈ 1:η)

        f[i + 1] = mod(x - y, q)
    end

    R_q(f)
end

end # module
