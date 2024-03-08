module SLHDSA

include("Parameters.jl")
include("General.jl")

import .Parameters: level_parameters

for (level, base_parameters) ∈ level_parameters
    @eval module $level

    export generate_keys, sign_message, verify_signature

    import ...rng
    import ...Utilities: peel, bytes2int
    import ..Parameters: derived_parameters

    import ArgCheck: @argcheck
    import Base.Iterators: partition

    const (level_number, variant, n, _...) = $base_parameters
    const (;
        identifier,
        m,
        parameters_adrs,
        parameters_wots,
        parameters_xmss,
        parameters_tree,
        parameters_fors,
        hashers_msg,
        lengths,
    ) = derived_parameters($level, $base_parameters)

    include("Addressing.jl")
    include("WOTS.jl")
    include("XMSS.jl")
    include("Hypertree.jl")
    include("FORS.jl")

    import .Addressing: SecretAddress, PublicAddress, change_type_to_fors_tree!

    function generate_keys(;
        seed::Union{Nothing, @NamedTuple{sk::U, prf::V, pk::W}} = nothing,
    ) where {
        U <: AbstractVector{UInt8},
        V <: AbstractVector{UInt8},
        W <: AbstractVector{UInt8},
    }
        (sk_seed, sk_prf, pk_seed) = if seed !== nothing
            @argcheck length(seed.sk) == n
            @argcheck length(seed.prf) == n
            @argcheck length(seed.pk) == n
            (seed.sk, seed.prf, seed.pk)
        else
            partition(rand(rng, UInt8, 3n), n)
        end

        pk = vcat(pk_seed, Hypertree.pk(sk_seed, pk_seed))
        sk = vcat(sk_seed, sk_prf, pk)

        (; sk, pk)
    end

    function sign_message(
        msg::AbstractVector{UInt8},
        sk::AbstractVector{UInt8};
        randomize::Union{Bool, AbstractVector{UInt8}} = true,
    )
        @argcheck length(sk) == lengths.sk

        (sk_seed, sk_prf, pk_seed, pk_root) = partition(sk, n)

        opt_rand = if randomize isa AbstractVector{UInt8}
            @argcheck length(randomize) == n
            randomize
        elseif randomize === false
            pk_seed
        else
            rand(rng, UInt8, n)
        end

        randomizer = hashers_msg.PRF(sk_prf, vcat(opt_rand, msg), n)

        adrs = SecretAddress(sk_seed, pk_seed)
        (msg_digest, idx_tree, idx_leaf) =
            digest_message!(adrs, msg, randomizer, pk_seed, pk_root)

        sig_fors = FORS.sign_message!(adrs, msg_digest)
        sig_tree = Hypertree.sign_message(
            FORS.pk_from_signature!(adrs, sig_fors, msg_digest),
            (idx_tree, idx_leaf, sk_seed, pk_seed)...,
        )

        vcat(randomizer, sig_fors, sig_tree)
    end

    function verify_signature(
        msg::AbstractVector{UInt8},
        sig::AbstractVector{UInt8},
        pk::AbstractVector{UInt8},
    )
        @argcheck length(pk) == lengths.pk

        (pk_seed, pk_root) = partition(pk, n)

        length(sig) == lengths.sig || return false

        (randomizer, sig_fors, sig_tree) =
            peel(sig, [n, parameters_fors.σ, parameters_tree.σ])

        adrs = PublicAddress(pk_seed)
        (msg_digest, idx_tree, idx_leaf) =
            digest_message!(adrs, msg, randomizer, pk_seed, pk_root)

        pk_root == Hypertree.pk_from_signature(
            FORS.pk_from_signature!(adrs, sig_fors, msg_digest),
            (sig_tree, idx_tree, idx_leaf, pk_seed)...,
        )
    end

    function digest_message!(adrs, msg, randomizer, pk_seed, pk_root)
        hash = hashers_msg.H(vcat(randomizer, pk_seed), vcat(pk_root, msg), sum(m))

        (msg_digest, tmp_idx_tree, tmp_idx_leaf) =
            peel(hash, [m.msg_digest, m.idx_tree, m.idx_leaf])

        idx_tree = bytes2int(tmp_idx_tree, parameters_tree.T_idx) % parameters_tree.ν
        idx_leaf = bytes2int(tmp_idx_leaf, parameters_xmss.T_idx) % parameters_xmss.ν

        change_type_to_fors_tree!(adrs, idx_tree, idx_leaf)

        (msg_digest, idx_tree, idx_leaf)
    end

    end # module
end

end # module
