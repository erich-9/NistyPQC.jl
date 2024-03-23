# Byte Lengths

Below you'll find an overview of the sizes in bytes of keys, ciphertexts, shared secrets,
and signatures for each included algorithm variant in this package.

```@setup lengths
import NistyPQC

import Latexify: mdtable

function mdtable_lengths(family_names, cols)
  rows = vcat((variants(x) for x ∈ family_names)...)
  side = ["module"; rows]
  head = ["identifier"; ("`$k`" for k ∈ cols)...]
  body = [[v.identifier for v ∈ rows] [v.lengths[k] for v ∈ rows, k ∈ cols]]
  mdtable(body; head, side, latex = false)
end

function variants(family_name)
  family = @eval NistyPQC.$family_name
  categories = keys(family.Parameters.category_parameters)
  [variant(family, category) for category ∈ categories]
end

function variant(family, category)
  @eval $family.$category
end
```

## KEM

See [Usage of KEM](@ref usage_kem) for the definition of `ek`, `dk`, `c`, `K`.

```@example lengths
mdtable_lengths([:MLKEM, :BIKE], [:ek, :dk, :c, :K]) # hide
```

## DSA

See [Usage of DSA](@ref usage_kem) for the definition of `sk`, `pk`, `sig`.

```@example lengths
mdtable_lengths([:MLDSA, :SLHDSA, :Falcon], [:sk, :pk, :sig]) # hide
```
