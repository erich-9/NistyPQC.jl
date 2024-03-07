module Addressing

import ...General: int2bytes, int2bytes!
import ..n, ..parameters_adrs

import OrderedCollections: OrderedDict

const (components, length_data, length_type) = begin
    x = OrderedDict()
    local start = 1
    for (length, names) ∈ parameters_adrs.layout
        for name ∈ names
            x[name] = (; length, range = start:(start + length - 1))
        end
        start += length
    end
    (x, start - 1, x[:type].length)
end

const types = map(x -> int2bytes(x, length_type), parameters_adrs.types)

abstract type Address end

for (A, ks) ∈ [(:SecretAddress, [:sk_seed, :pk_seed]), (:PublicAddress, [:pk_seed])]
    ks_lhs = :($([:($k::Vector{UInt8}) for k ∈ ks]))
    ks_rhs = :($([:(adrs.$k) for k ∈ ks]))

    @eval begin
        struct $A <: Address
            $(ks_lhs...)
            data::Vector{UInt8}
            $A($(ks...)) = new($(ks...), zeros(UInt8, length_data))
            $A($(ks...), data) = new($(ks...), data)
        end

        Base.copy(adrs::$A) = $A($(ks_rhs...), copy(adrs.data))
    end
end

for (name, (; range)) ∈ components
    eraser = Symbol(:erase_, name, :(!))
    setter = Symbol(:set_, name, :(!))

    @eval begin
        $eraser(adrs::Address) = (adrs.data[$range] .= 0x0; adrs)
        $setter(adrs::Address, bytes::AbstractVector{UInt8}) =
            (setindex!(adrs.data, bytes, $range); adrs)
        $setter(adrs::Address, x::Integer) = (int2bytes!(view(adrs.data, $range), x); adrs)
    end
end

function change_type_to_wots_hash!(adrs::Address, idx)
    set_type!(adrs, types.wots_hash)
    set_keypair_address!(adrs, idx)
end

function change_type_to_wots_pk!(adrs::Address)
    set_type!(adrs, types.wots_pk)
    erase_chain_address!(adrs)
    erase_hash_address!(adrs)
end

function change_type_to_tree!(adrs::Address)
    set_type!(adrs, types.tree)
    erase_keypair_address!(adrs)
end

function change_type_to_fors_tree!(adrs::Address, idx_tree, idx_leaf)
    set_type!(adrs, types.fors_tree)
    set_tree_address!(adrs, idx_tree)
    set_keypair_address!(adrs, idx_leaf)
end

function change_type_to_fors_roots!(adrs::Address)
    set_type!(adrs, types.fors_roots)
    erase_tree_height!(adrs)
    erase_tree_index!(adrs)
end

function change_type_to_wots_prf!(adrs::Address)
    set_type!(adrs, types.wots_prf)
    erase_hash_address!(adrs)
end

function change_type_to_fors_prf!(adrs::Address, idx)
    set_type!(adrs, types.fors_prf)
    set_tree_index!(adrs, idx)
    erase_tree_height!(adrs)
end

end # module
