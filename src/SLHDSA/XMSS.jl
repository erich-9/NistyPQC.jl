module XMSS

import ..Addressing:
    change_type_to_wots_hash!, change_type_to_tree!, set_tree_height!, set_tree_index!
import ..WOTS
import ..parameters_xmss as π

function node!(adrs, height, idx::π.T_idx)
    # @assert 0 ≤ height ≤ π.h
    # @assert 0 ≤ idx < π.ν >> height

    if iszero(height)
        change_type_to_wots_hash!(adrs, idx)

        WOTS.pk!(adrs)
    else
        lnode = node!(adrs, height - 1, 2idx)
        rnode = node!(adrs, height - 1, 2idx + 1)

        change_type_to_tree!(adrs)
        set_tree_height!(adrs, height)
        set_tree_index!(adrs, idx)

        π.H(adrs, vcat(lnode, rnode), π.ρ)
    end
end

function pk!(adrs)
    node!(adrs, π.h, zero(π.T_idx))
end

function sign_message!(adrs, msg, idx::π.T_idx)
    # @assert 0 ≤ idx < π.ν

    sig_xmss = Vector{UInt8}(undef, π.σ)
    pos = WOTS.π.σ + 1

    idx¹ = idx

    for j ∈ 0:(π.h - 1)
        sig_xmss[pos:(pos + π.ρ - 1)] = node!(adrs, j, idx¹ ⊻ 1)
        pos += π.ρ

        idx¹ >>= 1
    end

    change_type_to_wots_hash!(adrs, idx)

    sig_xmss[1:(WOTS.π.σ)] = WOTS.sign_message!(adrs, msg)

    sig_xmss
end

function pk_from_signature!(adrs, sig_xmss, msg, idx::π.T_idx)
    # @assert length(sig_xmss) == π.σ
    # @assert 0 ≤ idx < π.ν

    sig_wots = sig_xmss[1:(WOTS.π.σ)]
    pos = WOTS.π.σ + 1

    change_type_to_wots_hash!(adrs, idx)

    node = WOTS.pk_from_signature!(adrs, sig_wots, msg)

    change_type_to_tree!(adrs)

    for k ∈ 0:(π.h - 1)
        auth = sig_xmss[pos:(pos + π.ρ - 1)]
        pos += π.ρ

        y = iszero(idx % 2) ? vcat(node, auth) : vcat(auth, node)

        idx >>= 1

        set_tree_height!(adrs, k + 1)
        set_tree_index!(adrs, idx)

        node = π.H(adrs, y, π.ρ)
    end

    node
end

end # module
