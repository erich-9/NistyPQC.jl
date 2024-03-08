module Sampling

import ..Parameters: n, n₁, q, β, ξ
import ..General: bytes2bits
import ..NumberTheory: Rq, Tq

function sample_ntt(B)
    # @assert Base.IteratorSize(B) == Base.IsInfinite()

    â = Vector{Int}(undef, n)

    j = 1
    B3 = Iterators.partition(B, 3)
    @inbounds while j ≤ n
        (b₁, b₂, b₃), B3 = Iterators.peel(B3)

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

    Tq(â)
end

function sample_polycbd(B)
    # @assert length(B) % n₁ == 0

    η = length(B) ÷ n₁
    b = bytes2bits(B)

    f = Vector{Int}(undef, n)
    @inbounds for i ∈ 0:(n - 1)
        x = sum(b[2i * η + j] for j ∈ 1:η)
        y = sum(b[2i * η + η + j] for j ∈ 1:η)

        f[i + 1] = mod(x - y, q)
    end

    Rq(f)
end

end # module
