module Hypertree

import ..Addressing: SecretAddress, PublicAddress, set_layer_address!, set_tree_address!
import ..XMSS
import ..parameters_tree as π

function pk(sk_seed, pk_seed)
    adrs = SecretAddress(sk_seed, pk_seed)
    set_layer_address!(adrs, π.d - 1)

    XMSS.pk!(adrs)
end

function sign_message(msg, idx_tree::π.T_idx, idx_leaf::π.T_idx, sk_seed, pk_seed)
    # @assert 0 ≤ idx_tree < π.ν

    sig_tree = Vector{UInt8}(undef, π.σ)
    pos = 1

    adrs = SecretAddress(sk_seed, pk_seed)
    sig_xmss = undef
    node = msg

    for j ∈ 0:(π.d - 1)
        if j > 0
            node = XMSS.pk_from_signature!(adrs, sig_xmss, node, idx_leaf)

            idx_leaf = idx_tree % XMSS.π.ν
            idx_tree >>= XMSS.π.h

            set_layer_address!(adrs, j)
        end

        set_tree_address!(adrs, idx_tree)

        sig_xmss = XMSS.sign_message!(adrs, node, idx_leaf)

        sig_tree[pos:(pos + XMSS.π.σ - 1)] = sig_xmss
        pos += XMSS.π.σ
    end

    sig_tree
end

function pk_from_signature(msg, sig_tree, idx_tree::π.T_idx, idx_leaf::π.T_idx, pk_seed)
    # @assert length(sig_tree) == π.σ

    pos = 1

    adrs = PublicAddress(pk_seed)
    node = msg

    for j ∈ 0:(π.d - 1)
        if j > 0
            idx_leaf = idx_tree % XMSS.π.ν
            idx_tree >>= XMSS.π.h

            set_layer_address!(adrs, j)
        end

        set_tree_address!(adrs, idx_tree)

        sig_xmss = sig_tree[pos:(pos + XMSS.π.σ - 1)]
        pos += XMSS.π.σ

        node = XMSS.pk_from_signature!(adrs, sig_xmss, node, idx_leaf)
    end

    node
end

end # module
