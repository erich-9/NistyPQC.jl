# Usage

First, load the package:

```@example usage
import NistyPQC
```

Then, pick a seeded pseudorandom number generator:

```@example usage
import Random

NistyPQC.set_rng(Random.MersenneTwister(4711))
```

This last step is only necessary to guarantee reproducible outputs below.

## [KEM](@id usage_kem)

The key encapsulation mechanisms in this package all implement the following common interface:

  - `(; ek, dk) = generate_keys()`
  - `(; K, c) = encapsulate_secret(ek)`
  - `K = decapsulate_secret(c, dk)`

Here, all of `ek`, `dk`, `K`, and `c` are byte vectors.

### Example

For instance, to work with ML-KEM in security category 5 define:

```@example usage
KEM = NistyPQC.MLKEM.Category5
```

Generate a key pair for encapsulation and decapsulation:

```@example usage
(; ek, dk) = KEM.generate_keys()
```

Use the encapsulation key `ek` to produce a shared secret `K` and a ciphertext `c`:

```@example usage
(; K, c) = KEM.encapsulate_secret(ek)
```

With the knowledge of the decapsulation key `dk` alone, it is then possible to compute `K` from `c`:

```@example usage
K = KEM.decapsulate_secret(c, dk)
```

## [DSA](@id usage_dsa)

The digital signature algorithms in this package all implement the following common interface:

  - `(; sk, pk) = generate_keys()`
  - `sig = sign_message(msg, sk)`
  - `verify_signature(msg, sig, pk)`

Here, all of `sk`, `pk`, `msg`, and `sig` are byte vectors.

### Example

For instance, to work with ML-DSA in security category 5 define:

```@example usage
DSA = NistyPQC.MLDSA.Category5
```

Generate a key pair for signature generation and verification:

```@example usage
(; sk, pk) = DSA.generate_keys()
```

Use the secret key `sk` to generate a signature for some message `msg`:

```@example usage
msg = b"Sign me!"
sig = DSA.sign_message(msg, sk)
```

With the public key `pk` alone, it is then possible to check whether the signature for a message was indeed generated with the secret key `sk`:

```@example usage
DSA.verify_signature(msg, sig, pk)
```

```@example usage
DSA.verify_signature(b"another message", sig, pk)
```

```@example usage
DSA.verify_signature(msg, b"invalid signature", pk)
```
