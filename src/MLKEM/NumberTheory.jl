module NumberTheory

import ..Parameters: ω, n, n₀, q, ζ, n₀⁻¹

bitrev(i) = parse(Int, reverse(bitstring(i))[1:(ω - 1)], base = 2)

const ζ_bitrev = [powermod(ζ, bitrev(i), q) for i ∈ 1:(n₀ - 1)]
const ζ_2bitrevp = [powermod(ζ, 2bitrev(i) + 1, q) for i ∈ 0:(n₀ - 1)]

for T ∈ [:R_q, :T_q]
    @eval begin
        struct $T
            data::Vector{Int}
        end

        Base.zero(::Type{$T}) = $T(zeros(Int, n))
        Base.zero(::$T) = zero($T)
        Base.transpose(f̂::$T) = f̂
    end

    for (op, arity, args, map_back) ∈ [
        (:getindex, 1, [:(x::Int)], false),
        (:iterate, 1, [:(x::Int)], false),
        (:getindex, 1, [], false),
        (:iterate, 1, [], false),
        (:length, 1, [], false),
        (:(==), 2, [], false),
        (:(-), 1, [], true),
        (:(+), 2, [], true),
        (:(-), 2, [], true),
    ]
        args_rhs = [x.args[1] for x ∈ args]

        lhs = :(Base.$op($((:($(Symbol(:x, i))::$T) for i ∈ 1:arity)...), $(args...)))
        rhs = :($op($((:($(Symbol(:x, i)).data) for i ∈ 1:arity)...), $(args_rhs...)))

        if map_back
            rhs = :($T(mod.($rhs, q)))
        end

        @eval $lhs = $rhs
    end
end

function Base.:(*)(f̂::T_q, ĝ::T_q)
    # @assert length(f̂) == length(ĝ) == n

    ĥ = Vector{Int}(undef, n)
    @inbounds for i ∈ 1:n₀
        (ĥ[2i - 1], ĥ[2i]) =
            basecase_multiply(f̂[2i - 1], f̂[2i], ĝ[2i - 1], ĝ[2i], ζ_2bitrevp[i])
    end

    T_q(ĥ)
end

function basecase_multiply(a₀, a₁, b₀, b₁, γ)
    mod.((a₀ * b₀ + a₁ * b₁ * γ, a₀ * b₁ + a₁ * b₀), q)
end

function ntt(f::R_q)
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

    T_q(f̂)
end

function ntt⁻¹(f̂::T_q)
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

    R_q(mod.(f * n₀⁻¹, q))
end

end # module
