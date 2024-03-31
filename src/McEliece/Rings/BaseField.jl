module BaseField

import ...m, ...f
import ..Raw, ..Ring

const (T_Fz̄, T_double_Fz̄) = (UInt16, UInt32)

const f̃ = T_Fz̄(sum(1 << i for i ∈ f))

struct Fz̄ <: Ring
    d::T_Fz̄
    Fz̄(::Type{Raw}, d) = new(d)
end

const z̄ = Fz̄(Raw, 1 << 1)
Base.zero(::Type{Fz̄}) = Fz̄(Raw, 0)
Base.one(::Type{Fz̄}) = Fz̄(Raw, 1)

Base.zero(::Fz̄) = zero(Fz̄)
Base.one(::Fz̄) = one(Fz̄)

Base.iszero(a::Fz̄) = iszero(a.d)
Base.isone(a::Fz̄) = isone(a.d)

Base.promote_rule(::Type{Fz̄}, ::Type{<:Integer}) = Fz̄
Base.convert(::Type{Fz̄}, a::Integer) = Fz̄(Raw, isodd(a))

coeffs(::Type{Bool}, a::Fz̄; pad::Integer = m) = digits(Bool, a.d; base = 2, pad)

function Fz̄(coeffs::AbstractVector{Bool})
    d = zero(T_Fz̄)
    for x ∈ reverse(coeffs)
        d = d << 1 + x
    end
    Fz̄(Raw, d)
end

Base.copy(a::Fz̄) = Fz̄(Raw, a.d)
Base.:(==)(a::Fz̄, b::Fz̄) = a.d == b.d
Base.:+(a::Fz̄, b::Fz̄) = Fz̄(Raw, a.d ⊻ b.d)
Base.:-(a::Fz̄, b::Fz̄) = a + b
Base.:-(a::Fz̄) = a
Base.:^(a::Fz̄, p::Integer) = Base.power_by_squaring(a, p)
Base.:/(a::Fz̄, b::Fz̄) = a * inv(b)

Base.:*(a::Fz̄, b::Fz̄) = Fz̄(Raw, _mul(a.d, b.d))
Base.inv(a::Fz̄) = Fz̄(Raw, @inbounds __inv[a.d])

function _mod(a)
    e = []
    (u, v, w) = (1 << m, m - f[2], m + f[2])
    mask = (1 << v - 1) << (w - 1)
    while !iszero(mask)
        push!(e, :(w = $a & $mask))
        append!(e, (:($a ⊻= w >> $(m - j)) for j ∈ f[2:end]))
        mask = (mask >> v) & ~(u - 1)
    end
    push!(e, :($T_Fz̄($a % $u)))
    e
end

@generated function _mul(a, b)
    e = [:(c::$T_double_Fz̄ = 0)]
    append!(e, (:(c ⊻= a * (b & T_double_Fz̄($(1 << i)))) for i ∈ 0:(m - 1)))
    append!(e, _mod(:c))
    Expr(:block, e...)
end

function _inv(a)
    (r₀, r) = (a, f̃)
    (s₀, s) = (one(T_Fz̄), zero(T_Fz̄))
    (len_r₀, len_r) = Base.top_set_bit.((r₀, r))
    while !iszero(r)
        while len_r₀ ≥ len_r
            len = len_r₀ - len_r
            r₀ ⊻= r << len
            s₀ ⊻= s << len
            len_r₀ = Base.top_set_bit(r₀)
        end
        (r₀, r) = (r, r₀)
        (s₀, s) = (s, s₀)
        (len_r₀, len_r) = (len_r, len_r₀)
    end
    s₀
end

const __inv = [_inv(a) for a ∈ 1:(2^m - 1)]

end # module
