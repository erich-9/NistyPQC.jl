module Parameters

import ...Utilities: mgf1

import OrderedCollections: OrderedDict
import SHA: hmac_sha256, hmac_sha512, sha256, sha512
import SHAKE: shake256

const level_parameters = OrderedDict(
    Symbol(level, :_, hash_family) => (parameters..., hash_family) for
    hash_family ∈ [:sha2, :shake], (level, parameters) ∈ [
        :Level1s => (1, "s", 16, 7, 9, (12, 14), 4), # SLH-DSA-*-128s
        :Level1f => (1, "f", 16, 22, 3, (6, 33), 4), # SLH-DSA-*-128f
        :Level3s => (3, "s", 24, 7, 9, (14, 17), 4), # SLH-DSA-*-192s
        :Level3f => (3, "f", 24, 22, 3, (8, 33), 4), # SLH-DSA-*-192f
        :Level5s => (5, "s", 32, 8, 8, (14, 22), 4), # SLH-DSA-*-256s
        :Level5f => (5, "f", 32, 17, 4, (9, 35), 4), # SLH-DSA-*-256f
    ]
)

function derived_parameters(level, base_parameters)
    (level_number, variant, n, d, h¹, (a, k), lg_w, hash_family) = base_parameters

    (; hashers_msg, hashers) = get_hashers(hash_family, level_number, n)

    (;
        hashers_msg,
        identifier = "SLH-DSA-$(hash_family)-$(8n)$(variant)",
        parameters_adrs = get_address_parameters(hash_family),
        get_algorithm_parameters(n, d, h¹, a, k, lg_w, hashers)...,
    )
end

function get_address_parameters(hash_family)
    (;
        types = (;
            wots_hash = 0,
            wots_pk = 1,
            tree = 2,
            fors_tree = 3,
            fors_roots = 4,
            wots_prf = 5,
            fors_prf = 6,
        ),
        layout = if hash_family == :sha2
            [
                (1, [:layer_address]),
                (8, [:tree_address]),
                (1, [:type]),
                (4, [:keypair_address]),
                (4, [:chain_address, :tree_height]),
                (4, [:hash_address, :tree_index]),
            ]
        else
            [
                (4, [:layer_address]),
                (12, [:tree_address]),
                (4, [:type]),
                (4, [:keypair_address]),
                (4, [:chain_address, :tree_height]),
                (4, [:hash_address, :tree_index]),
            ]
        end,
    )
end

function get_hashers(hash_family, level_number, n)
    shake_vcat = (x, y, l) -> shake256(vcat(x, y), l)
    shake_adrs = (adrs, x, l) -> shake256(vcat(adrs.pk_seed, adrs.data, x), l)

    for ω ∈ [256, 512]
        pad = zeros(UInt8, ω ÷ 4 - n)

        (hmac_sha, sha) = (Symbol(:hmac_sha, ω), Symbol(:sha, ω))
        (hmac_sha_tr, sha_adrs_tr) = (Symbol(hmac_sha, :_tr), Symbol(sha, :_adrs_tr))

        @eval begin
            $hmac_sha_tr = (x, y, l) -> $hmac_sha(collect(x), y)[1:l]
            $sha_adrs_tr = (adrs, x, l) -> $sha(vcat(adrs.pk_seed, $pad, adrs.data, x))[1:l]
        end
    end

    mgf1_scrambler = sha -> (x, y, l) -> mgf1(sha, vcat(x, sha(vcat(x, y))), l)

    if hash_family == :sha2
        if level_number == 1
            hashers_msg = (; PRF = hmac_sha256_tr, H = mgf1_scrambler(sha256))
            hashers = (; PRF = sha256_adrs_tr, H = sha256_adrs_tr)
        else
            hashers_msg = (; PRF = hmac_sha512_tr, H = mgf1_scrambler(sha512))
            hashers = (; PRF = sha256_adrs_tr, H = sha512_adrs_tr)
        end
    else
        hashers_msg = (; PRF = shake_vcat, H = shake_vcat)
        hashers = (; PRF = shake_adrs, H = shake_adrs)
    end

    (; hashers_msg, hashers)
end

function get_algorithm_parameters(n, d, h¹, a, k, lg_w, hashers)
    (; PRF, H) = hashers

    w = 1 << lg_w
    ℓ₁ = cld(8n, lg_w)
    ℓ₂ = floor(Int, log2(ℓ₁ * (w - 1)) / lg_w) + 1
    ℓ = ℓ₁ + ℓ₂

    h² = (d - 1) * h¹

    T_idx = h² ≥ 8sizeof(UInt) ? UInt128 : UInt

    ν¹ = oneunit(T_idx) << h¹
    ν² = oneunit(T_idx) << h²

    t = oneunit(UInt) << a

    n₁ = n
    n₂ = n

    π_wots = (; n, lg_w, w, ℓ, ℓ₁, ℓ₂, PRF, H)
    π_xmss = (; h = h¹, ν = ν¹, T_idx, H)
    π_tree = (; d, h = h², ν = ν², T_idx)
    π_fors = (; n₁ = n, n₂ = n, h = a, t, k, ν = k * t, PRF, H)

    π_wots = (π_wots..., ρ = n, μ = n, σ = ℓ * n)
    π_xmss = (π_xmss..., ρ = π_wots.ρ, μ = π_wots.μ, σ = π_wots.σ + h¹ * π_wots.ρ)
    π_tree = (π_tree..., ρ = π_xmss.ρ, μ = π_xmss.μ, σ = d * π_xmss.σ)
    π_fors = (π_fors..., ρ = n, μ = cld(k * a, 8), σ = k * (n₁ + a * n₂))

    (;
        m = (;
            msg_digest = π_fors.μ,
            idx_tree = cld(π_tree.h, 8),
            idx_leaf = cld(π_xmss.h, 8),
        ),
        σ = n + π_fors.σ + π_tree.σ,
        parameters_wots = π_wots,
        parameters_xmss = π_xmss,
        parameters_tree = π_tree,
        parameters_fors = π_fors,
    )
end

end # module
