module Tree

import ...σ
import ..Rings: F0
import ..Transforms: gramdata, split_dft

struct InnerNode{T}
    value::AbstractVector{F0{T}}
    children::Union{NTuple{2, T}, NTuple{2, InnerNode{T}}}
end

function generate(f, g, F, G)
    (f₊, _, g₊, _, fg) = gramdata(f, g)
    (F₊, F₋, G₊, G₋, FG) = gramdata(F, G)

    (; f₊, g₊, F₊, G₊, root = node(fg, f₊ .* F₋ + g₊ .* G₋, FG))
end

function node(
    g₁₁::AbstractVector{F0{T}},
    g₁₂::AbstractVector{F0{T}},
    g₂₂::AbstractVector{F0{T}},
) where {T}
    (l, d₁, d₂) = ld(g₁₁, g₁₂, g₂₂)

    if length(l) == 2
        InnerNode{T}(l, (leaf(d₁), leaf(d₂)))
    else
        InnerNode{T}(l, (node(d₁), node(d₂)))
    end
end

function leaf(d)
    σ ./ √real(d[1])
end

function node(d)
    (d₁, d₂) = split_dft(d)

    node(d₁, d₂, d₁)
end

function ld(g₁₁, g₁₂, g₂₂)
    l = conj.(g₁₂ ./ g₁₁)

    (; l, d₁ = g₁₁, d₂ = g₂₂ - l .* g₁₂)
end

end # module
