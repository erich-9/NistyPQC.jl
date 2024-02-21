module FORS

import ..Addressing:
    change_type_to_fors_roots!, change_type_to_fors_prf!, set_tree_height!, set_tree_index!
import ...General: base_2ᵇ
import ..parameters_fors as π

function sk_at_index(adrs, idx::UInt)
    sk_adrs = copy(adrs)
    change_type_to_fors_prf!(sk_adrs, idx)

    π.PRF(sk_adrs, adrs.sk_seed, π.n₁)
end

function pk_from_roots(adrs, roots)
    fors_pk_adrs = copy(adrs)
    change_type_to_fors_roots!(fors_pk_adrs)

    π.H(fors_pk_adrs, roots, π.ρ)
end

function node!(adrs, height, idx::UInt)
    # @assert 0 ≤ height ≤ π.h
    # @assert 0 ≤ idx < π.ν >> height

    if iszero(height)
        set_tree_height!(adrs, 0)
        set_tree_index!(adrs, idx)

        π.PRF(adrs, sk_at_index(adrs, idx), π.n₂)
    else
        lnode = node!(adrs, height - 1, 2idx)
        rnode = node!(adrs, height - 1, 2idx + 1)

        set_tree_height!(adrs, height)
        set_tree_index!(adrs, idx)

        π.H(adrs, vcat(lnode, rnode), π.n₂)
    end
end

function pk!(adrs)
    roots = vcat((node!(adrs, π.h, UInt(i)) for i ∈ 0:(π.k - 1))...)
    pk_from_roots(adrs, roots)
end

function sign_message!(adrs, msg)
    # @assert length(msg) == π.μ

    sig_fors = Vector{UInt8}(undef, π.σ)
    pos = 1

    indices = base_2ᵇ(msg, π.h, π.k)

    for i ∈ zero(UInt):(π.k - 1)
        sig_fors[pos:(pos + π.n₁ - 1)] = sk_at_index(adrs, i * π.t + indices[i + 1])
        pos += π.n₁

        idx⁰ = π.t
        idx¹ = indices[i + 1]

        for j ∈ 0:(π.h - 1)
            sig_fors[pos:(pos + π.n₂ - 1)] = node!(adrs, j, i * idx⁰ + (idx¹ ⊻ 1))
            pos += π.n₂

            idx⁰ >>= 1
            idx¹ >>= 1
        end
    end

    sig_fors
end

function pk_from_signature!(adrs, sig_fors, msg)
    # @assert length(sig_fors) == π.σ
    # @assert length(msg) == π.μ

    pos = 1

    indices = base_2ᵇ(msg, π.h, π.k)

    roots = Vector{UInt8}(undef, π.k * π.n₂)

    for i ∈ zero(UInt):(π.k - 1)
        set_tree_height!(adrs, 0)
        set_tree_index!(adrs, i << π.h + indices[i + 1])

        node = π.PRF(adrs, sig_fors[pos:(pos + π.n₂ - 1)], π.n₂)
        pos += π.n₂

        idx = indices[i + 1]
        idx¹ = i << π.h + (idx ⊻ 1)

        for j ∈ 0:(π.h - 1)
            auth = sig_fors[pos:(pos + π.n₂ - 1)]
            pos += π.n₂

            y = iseven(idx) ? vcat(node, auth) : vcat(auth, node)

            idx >>= 1
            idx¹ >>= 1

            set_tree_height!(adrs, j + 1)
            set_tree_index!(adrs, idx¹)

            node = π.H(adrs, y, π.n₂)
        end

        roots[(π.n₂ * i + 1):(π.n₂ * (i + 1))] = node
    end

    pk_from_roots(adrs, roots)
end

end # module
