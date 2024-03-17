# Usage

First, load the package:

```jldoctest usage; output = false
import NistyPQC

# output

```

Then, pick a seeded pseudorandom number generator:

```jldoctest usage; output = false
import Random

NistyPQC.set_rng(Random.MersenneTwister(4711))

# output

Random.MersenneTwister(4711)
```

This last step is only necessary to guarantee reproducible outputs below.

## KEM

The key encapsulation mechanisms in this package all implement the following common interface:

  - `(; ek, dk) = generate_keys()`
  - `(; K, c) = encapsulate_secret(ek)`
  - `K = decapsulate_secret(c, dk)`

Here, all of `ek`, `dk`, `K`, and `c` are byte vectors.

### Example

For instance, to work with ML-KEM in security category 5 define:

```jldoctest usage; output = false
KEM = NistyPQC.MLKEM.Category5

# output

NistyPQC.MLKEM.Category5
```

Generate a key pair for encapsulation and decapsulation:

```jldoctest usage
(; ek, dk) = KEM.generate_keys()

# output

(ek = UInt8[0x1e, 0xf7, 0x9d, 0xc3, 0x3a, 0xbe, 0x57, 0x23, 0xa5, 0x9c  …  0x91, 0x59, 0x27, 0x07, 0x94, 0xb4, 0x88, 0xd8, 0x67, 0x1d], dk = UInt8[0x4a, 0x79, 0xa3, 0x5c, 0xc6, 0x9c, 0xd9, 0x70, 0x3c, 0x63  …  0x3c, 0x39, 0xc6, 0xc7, 0x2c, 0xdd, 0xb3, 0x54, 0x41, 0x09])
```

Use the encapsulation key `ek` to produce a shared secret `K` and a ciphertext `c`:

```jldoctest usage
(; K, c) = KEM.encapsulate_secret(ek)

# output

(K = UInt8[0x1a, 0x2a, 0xe9, 0x9c, 0xd9, 0x5b, 0x35, 0xc3, 0xe6, 0x3e  …  0xac, 0x0c, 0x28, 0xe6, 0xf5, 0x37, 0xc1, 0x66, 0x95, 0xb8], c = UInt8[0x66, 0xca, 0x48, 0x05, 0xe1, 0x4f, 0xd3, 0x77, 0xa7, 0xa1  …  0xbb, 0x44, 0xf3, 0x98, 0x52, 0xa6, 0x58, 0xab, 0x7f, 0xb4])
```

With the knowledge of the decapsulation key `dk` alone, it is then possible to compute `K` from `c`:

```jldoctest usage
K = KEM.decapsulate_secret(c, dk)

# output

32-element Vector{UInt8}:
 0x1a
 0x2a
 0xe9
 0x9c
 0xd9
 0x5b
 0x35
 0xc3
 0xe6
 0x3e
    ⋮
 0x0c
 0x28
 0xe6
 0xf5
 0x37
 0xc1
 0x66
 0x95
 0xb8
```

## DSA

The digital signature algorithms in this package all implement the following common interface:

  - `(; sk, pk) = generate_keys()`
  - `sig = sign_message(msg, sk)`
  - `verify_signature(msg, sig, pk)`

Here, all of `sk`, `pk`, `msg`, and `sig` are byte vectors.

### Example

For instance, to work with ML-DSA in security category 5 define:

```jldoctest usage; output = false
DSA = NistyPQC.MLDSA.Category5

# output

NistyPQC.MLDSA.Category5
```

Generate a key pair for encapsulation and decapsulation:

```jldoctest usage
(; sk, pk) = DSA.generate_keys()

# output

(sk = UInt8[0x6f, 0xde, 0x80, 0x88, 0x11, 0xed, 0x6d, 0x3f, 0x4a, 0xab  …  0xb2, 0x4f, 0x22, 0x9c, 0x91, 0x91, 0xf8, 0xda, 0x38, 0x8e], pk = UInt8[0x6f, 0xde, 0x80, 0x88, 0x11, 0xed, 0x6d, 0x3f, 0x4a, 0xab  …  0xed, 0x22, 0xbb, 0xf2, 0xa9, 0xdc, 0xfd, 0xbc, 0xe6, 0x46])
```

Use the secret key `sk` to generate a signature for some message `msg`:

```jldoctest usage
msg = b"Sign me!"
sig = DSA.sign_message(msg, sk)

# output

4627-element Vector{UInt8}:
 0x23
 0xf1
 0x4a
 0xdb
 0x2a
 0xe7
 0x0d
 0x78
 0xb6
 0x69
    ⋮
 0x00
 0x08
 0x0a
 0x10
 0x17
 0x1e
 0x25
 0x2e
 0x33
```

With the public key `pk` alone, it is then possible to check whether the signature for a message was indeed generated with the secret key `sk`:

```jldoctest usage
DSA.verify_signature(msg, sig, pk)

# output

true
```

```jldoctest usage
DSA.verify_signature(b"another message", sig, pk)

# output

false
```

```jldoctest usage
DSA.verify_signature(msg, b"invalid signature", pk)

# output

false
```
