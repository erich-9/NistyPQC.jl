module Ring

import ..General
import ..r, ..r_bytes

struct Element
    coeffs::BitVector

    function Element(coeffs::AbstractVector{Bool})
        new(coeffs)
    end
end

function to_bits(a::Element)
    a.coeffs
end

Element(bytes::AbstractVector{UInt8}) = Element(General.from_bytes(bytes))
to_bytes(a::Element) = General.to_bytes(to_bits(a))

Base.copy(a::Element) = Element(copy(a.coeffs))
Base.:(==)(a::Element, b::Element) = a.coeffs == b.coeffs

Base.zero(::Type{Element}) = Element(falses(r))
Base.one(::Type{Element}) = (f = zero(Element); f.coeffs[1] = true; f)

Base.zero(::Element) = zero(Element)
Base.one(::Element) = one(Element)

Base.:+(a::Element, b::Element) = Element(a.coeffs .⊻ b.coeffs)
Base.:^(a::Element, n::Integer) = Base.power_by_squaring(a, n)

weight(a::Element) = sum(a.coeffs)
isinvertible(a::Element) = isodd(weight(a))

function Base.:*(a::Element, b::Element)
    res = BitVector(undef, r)
    v = reverse(b.coeffs)
    for i ∈ r:-1:1
        res[i] = isodd(sum(a.coeffs .& v))
        circshift!(v, -1)
    end
    Element(res)
end

const iₘₐₓ = floor(Int, log2(r - 2))
const digits_rm2 = [c == '1' for c ∈ reverse(bitstring(r - 2))][2:(iₘₐₓ + 1)]

function pow_2ⁿ(a::Element, n)
    coeffs = BitVector(undef, r)
    s = powermod(2, n % (r - 1), r)
    for i ∈ 0:(r - 1)
        coeffs[(i * s) % r + 1] = a.coeffs[i + 1]
    end
    Element(coeffs)
end

function Base.inv(a::Element)
    res = copy(a)
    f = copy(a)
    for i ∈ 1:iₘₐₓ
        f *= pow_2ⁿ(f, 1 << (i - 1))
        if digits_rm2[i]
            res *= pow_2ⁿ(f, (r - 2) % (1 << i))
        end
    end
    pow_2ⁿ(res, 1)
end

end # module
