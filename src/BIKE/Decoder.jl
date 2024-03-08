module Decoder

import ..Ring: Element, weight, to_bits
import ..r, ..nb_iter, ..τ, ..θ, ..threshold

function decode(s::Element, h₀::Element, h₁::Element)
    e = zeros(Element, 2)

    H = [h₀ h₁]
    ŝ = [s]

    iter = 1
    while iter ≤ nb_iter && !iszero(ŝ)
        masks = bf_iter!(e, ŝ, H, threshold(weight(ŝ[]), iter))
        if iter == 1
            for mask ∈ masks
                bf_masked_iter!(mask, e, ŝ, H, θ + 1)
            end
        end
        iter += 1
    end

    e
end

function bf_iter!(e, ŝ, H, T)
    (black, gray) = ([falses(r) for _ ∈ 1:2] for _ ∈ 1:2)

    s_bits = to_bits(ŝ[])
    @inbounds for i ∈ 1:2
        v = to_bits(H[i])
        for j ∈ 1:r
            c = sum(s_bits .& v)
            if c ≥ T
                black[i][j] = true
            elseif c ≥ T - τ
                gray[i][j] = true
            end
            circshift!(v, 1)
        end
        flip!(e, ŝ, H, black, i)
    end

    (black, gray)
end

function bf_masked_iter!(mask, e, ŝ, H, T)
    s_bits = to_bits(ŝ[])
    @inbounds for i ∈ 1:2
        v = to_bits(H[i])
        for j ∈ 1:r
            if mask[i][j] && sum(s_bits .& v) < T
                mask[i][j] = false
            end
            circshift!(v, 1)
        end
        flip!(e, ŝ, H, mask, i)
    end
end

function flip!(e, ŝ, H, mask, i)
    @inbounds begin
        Δe = Element(mask[i])
        e[i] += Δe
        ŝ[] += H[i] * Δe
    end
end

end # module
