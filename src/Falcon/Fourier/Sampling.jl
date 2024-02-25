module Sampling

import ...Sampling: sample_int
import ..Rings: F0
import ..Transforms: merge_dft, split_dft
import ..Tree: InnerNode

function sample_dft_pair(t₁, t₂, node::InnerNode)
    (child₁, child₂) = node.children

    z₂ = sample_dft_pair(t₂, child₂)
    z₁ = sample_dft_pair(t₁ .+ (t₂ .- z₂) .* node.value, child₁)

    (z₁, z₂)
end

function sample_dft_pair(t, node)
    merge_dft(sample_dft_pair(split_dft(t)..., node)...)
end

function sample_dft_pair(t₁, t₂, leaf::T) where {T}
    ([F0{T}(sample_int(real(x[]), leaf))] for x ∈ (t₁, t₂))
end

end # module
