module Rings

import ...n, ...q

struct F0{T}
    data::Complex{T}
    F0{T}(x::Number) where {T} = new(x)
end

struct Fq{T <: Integer}
    data::T
    Fq{T}(x::Integer, reduce::Bool = true) where {T} = new(reduce ? mod(x, q) : x)
end

for F ∈ [:F0, :Fq]
    @eval begin
        $F{T}(x::AbstractArray) where {T} = $F{T}.(x)

        Base.zero(::Type{$F{T}}) where {T} = $F{T}(zero(T))
        Base.zero(::$F{T}) where {T} = zero($F{T})

        Base.one(::Type{$F{T}}) where {T} = $F{T}(one(T))
        Base.one(::$F{T}) where {T} = one($F{T})
    end
end

ζ₀(::Type{F0{T}}) where {T} = F0{T}(exp(T(π) * im / n))
ζ₀(::Type{Fq{T}}) where {T} = Fq{T}(findfirst(x -> Fq{T}(x)^n == Fq{T}(-1), 1:q))

for (Fs, signatures, map_back) ∈ [
    ([:F0, :Fq], [([:(-)], 1, []), ([:(+), :(-), :(*)], 2, [])], true),
    ([:F0], [([:inv, :conj], 1, []), ([:/], 2, []), ([:^], 1, [:(y::Integer)])], true),
    ([:F0], [([:abs2, :real, :imag], 1, []), ([:≈], 2, [])], false),
]
    for F ∈ Fs
        for (ops, arity, args_lhs) ∈ signatures
            for op ∈ ops
                args_F_lhs = (:($(Symbol(:x, i))::$F{T}) for i ∈ 1:arity)
                args_F_rhs = (:($(Symbol(:x, i)).data) for i ∈ 1:arity)

                args_rhs = [x.args[1] for x ∈ args_lhs]

                lhs = :(Base.$op($(args_F_lhs...), $(args_lhs...)) where {T})
                rhs = :($op($(args_F_rhs...), $(args_rhs...)))

                if map_back
                    rhs = :($F{T}($rhs))
                end

                @eval $lhs = $rhs
            end
        end
    end
end

Base.inv(x::Fq{T}) where {T} = Fq{T}(invmod(x.data, q), false)
Base.:/(x::Fq{T}, y::Fq{T}) where {T} = x * inv(y)
Base.:^(x::Fq{T}, y::Integer) where {T} = Fq{T}(powermod(x.data, y, q), false)

Base.convert(::Type{T}, x::F0) where {T <: Integer} = round(T, real(x))
Base.convert(::Type{T}, x::Fq) where {T <: Integer} = mod(x.data, cld(-q, 2):fld(q, 2))

const big_ζs = Vector{F0{BigFloat}}(undef, 2n)

# The precision of BigFloat is not bound to the type,
# so type-dependent "constants" must be recomputable.
function recompute_big_ζs()
    ζ_curr = ζ_init = ζ₀(F0{BigFloat})
    for i ∈ 1:(2n)
        big_ζs[i] = ζ_curr
        ζ_curr *= ζ_init
    end
    big_ζs
end

for (F, Ts) ∈ [(:F0, [Float64, BigFloat]), (:Fq, [Int])]
    for T ∈ Ts
        @eval begin
            one_half_F = $F{$T}(2)^-1
            ζ_F = ζ₀($F{$T})
        end

        ζs_F = T == BigFloat ? recompute_big_ζs() : [ζ_F^x for x ∈ 1:(2n)]

        @eval begin
            one_half(::Type{$F{$T}}) = $one_half_F
            ζ(::Type{$F{$T}}, i) = $ζs_F[i]
            ζ(::Type{$F{$T}}, k, j; inv = false) =
                (i = (2j - 1) * n ÷ k; $ζs_F[inv ? 2n - i : i])
        end
    end
end

end # module
