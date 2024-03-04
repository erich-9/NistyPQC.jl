module Parameters

import OrderedCollections: OrderedDict

const ℓ = 32

const level_parameters = OrderedDict(
    :Level1 => (1, 12_323, 142, 134, 5, 3, (0.00697220, 13.5300)),
    :Level3 => (3, 24_659, 206, 199, 5, 3, (0.00526500, 15.2588)),
    :Level5 => (5, 40_973, 274, 264, 5, 3, (0.00402312, 17.8785)),
)

function derived_parameters(level, base_parameters)
    (level_number, r, w, t, nb_iter, τ, (θ₀, θ₁)) = base_parameters

    r_bytes = cld(r, 8)
    d = w ÷ 2
    θ = (d + 1) ÷ 2
    threshold = (S, i) -> max(floor(Int, θ₀ * S + θ₁), θ)

    (; identifier = "BIKE-Level$(level_number)", r_bytes, d, θ, threshold)
end

end # module
