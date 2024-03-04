module NumberTheory

import ..Parameters: ω, n, n₀, q, ζ, n₀⁻¹

bitrev(i) = parse(Int, reverse(bitstring(i))[1:(ω - 1)], base = 2)

const ζ_bitrev = [powermod(ζ, bitrev(i), q) for i ∈ 1:(n₀ - 1)]
const ζ_2bitrevp = [powermod(ζ, 2bitrev(i) + 1, q) for i ∈ 0:(n₀ - 1)]

for F ∈ [:Rq, :Tq]
    @eval begin
        struct $F
            data::Vector{Int}
        end

        Base.zero(::Type{$F}) = $F(zeros(Int, n))
        Base.zero(::$F) = zero($F)
        Base.transpose(f̂::$F) = f̂
    end

    for (signatures, map_back) ∈ [
        ([([:getindex, :iterate], 1, [[], [:(x::Int)]])], false),
        ([([:length], 1, [[]]), ([:(==)], 2, [[]])], false),
        ([([:(-)], 1, [[]]), ([:(+), :(-)], 2, [[]])], true),
    ]
        for (ops, arity, argss_lhs) ∈ signatures
            for op ∈ ops
                for args_lhs ∈ argss_lhs
                    args_F_lhs = (:($(Symbol(:x, i))::$F) for i ∈ 1:arity)
                    args_F_rhs = (:($(Symbol(:x, i)).data) for i ∈ 1:arity)

                    args_rhs = [x.args[1] for x ∈ args_lhs]

                    lhs = :(Base.$op($(args_F_lhs...), $(args_lhs...)))
                    rhs = :($op($(args_F_rhs...), $(args_rhs...)))

                    if map_back
                        rhs = :($F(mod.($rhs, q)))
                    end

                    @eval $lhs = $rhs
                end
            end
        end
    end
end

function Base.:(*)(f̂::Tq, ĝ::Tq)
    # @assert length(f̂) == length(ĝ) == n

    ĥ = Vector{Int}(undef, n)
    @inbounds for i ∈ 1:n₀
        (ĥ[2i - 1], ĥ[2i]) =
            basecase_multiply(f̂[2i - 1], f̂[2i], ĝ[2i - 1], ĝ[2i], ζ_2bitrevp[i])
    end

    Tq(ĥ)
end

function basecase_multiply(a₀, a₁, b₀, b₁, γ)
    mod.((a₀ * b₀ + a₁ * b₁ * γ, a₀ * b₁ + a₁ * b₀), q)
end

function ntt(f::Rq)
    # @assert length(f) == n

    f̂ = copy(f.data)

    i = 1
    ϕ = n₀
    @inbounds while ϕ ≥ 2
        for s ∈ 0:(2ϕ):(n - 1)
            z = ζ_bitrev[i]
            i += 1
            for j ∈ (s + 1):(s + ϕ)
                t = z * f̂[j + ϕ]
                f̂[j + ϕ] = mod(f̂[j] - t, q)
                f̂[j] = mod(f̂[j] + t, q)
            end
        end
        ϕ >>= 1
    end

    Tq(f̂)
end

function ntt⁻¹(f̂::Tq)
    # @assert length(f̂) == n

    f = copy(f̂.data)

    i = n₀ - 1
    ϕ = 2
    @inbounds while ϕ ≤ n₀
        for s ∈ 0:(2ϕ):(n - 1)
            z = ζ_bitrev[i]
            i -= 1
            for j ∈ (s + 1):(s + ϕ)
                t = f[j]
                f[j] = mod(t + f[j + ϕ], q)
                f[j + ϕ] = mod(z * (f[j + ϕ] - t), q)
            end
        end
        ϕ <<= 1
    end

    Rq(mod.(f * n₀⁻¹, q))
end

end # module
