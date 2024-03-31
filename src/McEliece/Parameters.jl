module Parameters

const (ℓ, (σ₁, σ₂)) = (32, (16, 32))

const μν_slow = (0, 0)
const μν_fast = (32, 64)

const fs = Dict(first(f) => f for f ∈ [
    [12, 3, 0],       # z¹² + z³ + 1
    [13, 4, 3, 1, 0], # z¹³ + z⁴ + z³ + z + 1
])

const fFs = Dict(
    (m, first(first(F))) => (fs[m], F) for (m, F) ∈ [
        12 => [(64, [0]), (3, [0]), (1, [0]), (0, [1])],            # y⁶⁴ + y³ + y + z̄
        13 => [(96, [0]), (10, [0]), (9, [0]), (6, [0]), (0, [0])], # y⁹⁶ + y¹⁰ + y⁹ + y⁶ + 1
        13 => [(119, [0]), (8, [0]), (0, [0])],                     # y¹¹⁹ + y⁸ + 1
        13 => [(128, [0]), (7, [0]), (2, [0]), (1, [0]), (0, [0])], # y¹²⁸ + y⁷ + y² + y + 1
    ]
)

const category_parameters = [
    (fast_variant ? Symbol(category, :f) : category) => (v..., fast_variant) for
    (category, v) ∈ [
        :Category1 => (1, 3488, fFs[(12, 64)]...),   # mceliece348864*
        :Category3 => (3, 4608, fFs[(13, 96)]...),   # mceliece460896*
        :Category5A => (5, 6688, fFs[(13, 128)]...), # mceliece6688128*
        :Category5B => (5, 6960, fFs[(13, 119)]...), # mceliece6960119*
        :Category5C => (5, 8192, fFs[(13, 128)]...), # mceliece8192128*
    ] for fast_variant ∈ [false, true]
]

function derived_parameters(category, base_parameters)
    (category_number, n, f, F, fast_variant) = base_parameters

    m = first(f)
    t = first(first(F))
    k = n - m * t
    q = 2^m
    τ = t << Base.top_set_bit((q - 1) ÷ n)

    (μ, ν) = fast_variant ? μν_fast : μν_slow

    category_lengths = (;
        δ = ℓ,
        p = fast_variant ? (ν ÷ 8) : 8,
        g = t * cld(m, 8),
        α = (2m - 1) << (m - 4),
        s = n ÷ 8,
    )

    category_lengths = (;
        category_lengths...,
        ek = m * t * cld(k, 8),
        dk = sum(category_lengths[x] for x ∈ (:δ, :p, :g, :α, :s)),
        K = ℓ,
        c = cld(m * t, 8),
    )

    (;
        identifier = "mceliece$n$t" * (fast_variant ? "f" : ""),
        (; m, t, k, q, τ, μ, ν)...,
        lengths = category_lengths,
    )
end

end # module
