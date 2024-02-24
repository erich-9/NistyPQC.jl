module SLHDSA

include("Parameters.jl")
include("General.jl")

import .Parameters: level_parameters

for (level, base_parameters) ∈ level_parameters
    @eval module $level

    export PublicKey, SecretKey, generate_keys, sign_message, verify_signature

    import ...rng
    import ..Parameters: derived_parameters
    import ..General: bytes2int

    import StaticArrays: MVector, StaticVector

    const (level_number, variant, n, _...) = $base_parameters
    const (;
        identifier,
        m,
        σ,
        parameters_adrs,
        parameters_wots,
        parameters_xmss,
        parameters_tree,
        parameters_fors,
        hashers_msg,
    ) = derived_parameters($level, $base_parameters)

    include("Addressing.jl")
    include("WOTS.jl")
    include("XMSS.jl")
    include("Hypertree.jl")
    include("FORS.jl")

    import .Addressing: SecretAddress, PublicAddress, change_type_to_fors_tree!

    struct PublicKey
        seed::MVector{n, UInt8}
        root::MVector{n, UInt8}
    end

    struct SecretKey
        seed::MVector{n, UInt8}
        prf::MVector{n, UInt8}
        pk::PublicKey
    end

    function generate_keys(;
        seed::Union{Nothing, @NamedTuple{sk::U, prf::V, pk::W}} = nothing,
    ) where {
        U <: StaticVector{n, UInt8},
        V <: StaticVector{n, UInt8},
        W <: StaticVector{n, UInt8},
    }
        (sk_seed, sk_prf, pk_seed) = if seed !== nothing
            (seed.sk, seed.prf, seed.pk)
        else
            MVector{n, UInt8}.(Iterators.partition(rand(rng, UInt8, 3n), n))
        end

        pk = PublicKey(pk_seed, Hypertree.pk(sk_seed, pk_seed))
        sk = SecretKey(sk_seed, sk_prf, pk)

        (; pk, sk)
    end

    function sign_message(
        msg::AbstractVector{UInt8},
        sk::SecretKey;
        randomize::Union{Bool, StaticVector{n, UInt8}} = true,
    )
        opt_rand = if randomize isa StaticVector{n, UInt8}
            randomize
        elseif randomize === false
            sk.pk.seed
        else
            rand(rng, UInt8, n)
        end

        randomizer = hashers_msg.PRF(sk.prf, vcat(opt_rand, msg), n)

        adrs = SecretAddress(sk.seed, sk.pk.seed)
        (msg_digest, idx_tree, idx_leaf) = digest_message!(adrs, msg, randomizer, sk.pk)

        sig_fors = FORS.sign_message!(adrs, msg_digest)
        sig_tree = Hypertree.sign_message(
            FORS.pk_from_signature!(adrs, sig_fors, msg_digest),
            (idx_tree, idx_leaf, sk.seed, sk.pk.seed)...,
        )

        vcat(randomizer, sig_fors, sig_tree)
    end

    function verify_signature(
        msg::AbstractVector{UInt8},
        sig::AbstractVector{UInt8},
        pk::PublicKey,
    )
        if length(sig) == σ
            randomizer = sig[1:n]
            sig_fors = sig[(n + 1):(n + parameters_fors.σ)]
            sig_tree = sig[(end - parameters_tree.σ + 1):end]

            adrs = PublicAddress(pk.seed)
            (msg_digest, idx_tree, idx_leaf) = digest_message!(adrs, msg, randomizer, pk)

            pk.root == Hypertree.pk_from_signature(
                FORS.pk_from_signature!(adrs, sig_fors, msg_digest),
                (sig_tree, idx_tree, idx_leaf, pk.seed)...,
            )
        else
            false
        end
    end

    function digest_message!(adrs, msg, randomizer, pk)
        hash = hashers_msg.H(vcat(randomizer, pk.seed), vcat(pk.root, msg), sum(m))

        msg_digest = hash[1:(m.msg_digest)]
        tmp_idx_tree = hash[(m.msg_digest + 1):(m.msg_digest + m.idx_tree)]
        tmp_idx_leaf = hash[(end - m.idx_leaf + 1):end]

        idx_tree = bytes2int(tmp_idx_tree, parameters_tree.T_idx) % parameters_tree.ν
        idx_leaf = bytes2int(tmp_idx_leaf, parameters_xmss.T_idx) % parameters_xmss.ν

        change_type_to_fors_tree!(adrs, idx_tree, idx_leaf)

        (msg_digest, idx_tree, idx_leaf)
    end

    end # module
end

end # module
