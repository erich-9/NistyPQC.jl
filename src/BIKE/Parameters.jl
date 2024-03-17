module Parameters

import OrderedCollections: OrderedDict

const ℓ = 32

const category_parameters = OrderedDict(
    :Category1 => (1, 12_323, 142, 134, 5, 3, (0.00697220, 13.5300)),
    :Category3 => (3, 24_659, 206, 199, 5, 3, (0.00526500, 15.2588)),
    :Category5 => (5, 40_973, 274, 264, 5, 3, (0.00402312, 17.8785)),
)

function derived_parameters(category, base_parameters)
    (category_number, r, w, t, nb_iter, τ, (θ₀, θ₁)) = base_parameters

    r_bytes = cld(r, 8)
    d = w ÷ 2
    θ = (d + 1) ÷ 2
    threshold = (S, i) -> max(floor(Int, θ₀ * S + θ₁), θ)

    lengths = (; ek = r_bytes, dk = 2r_bytes + ℓ, K = ℓ, c = r_bytes + ℓ)

    (; identifier = "BIKE-Category$(category_number)", r_bytes, d, θ, threshold, lengths)
end

end # module
