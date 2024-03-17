# NistyPQC

*Nifty PQC promoted by NIST.*

These are implementations in [Julia](https://julialang.org/) of various [post-quantum cryptography](https://en.wikipedia.org/wiki/Post-quantum_cryptography) (PQC) algorithms that were picked as (candidate) winners in the [Post-Quantum Cryptography Standardization Project](https://csrc.nist.gov/Projects/post-quantum-cryptography/post-quantum-cryptography-standardization) run by the [National Institute of Standards and Technology](https://www.nist.gov/) (NIST).
They fall in two categories:

  - [key encapsulation mechanisms](https://en.wikipedia.org/wiki/Key_encapsulation_mechanism) (KEM)
  - [digital signature schemes/algorithms](https://en.wikipedia.org/wiki/Digital_signature) (DSA)

All implementations in this package strive for simplicity and close resemblance with the specifications.
The focus is not on performance, let alone on security.

## Algorithms

### Winners

At the moment, NIST has published draft [Federal Information Processing Standards](https://en.wikipedia.org/wiki/Federal_Information_Processing_Standards) (FIPS) for three of the winners:

  - ML-KEM

      + derived from [CRYSTALS-Kyber](https://pq-crystals.org/kyber/)
      + specified in [FIPS 203, Module-Lattice-Based Key-Encapsulation Mechanism Standard](https://csrc.nist.gov/pubs/fips/203/ipd)

  - ML-DSA

      + derived from [CRYSTALS-Dilithium](https://pq-crystals.org/dilithium/)
      + specified in [FIPS 204, Module-Lattice-Based Digital Signature Standard](https://csrc.nist.gov/pubs/fips/204/ipd)

  - SLH-DSA

      + derived from [SPHINCS+](https://sphincs.org/)
      + specified in [FIPS 205, Stateless Hash-Based Digital Signature Standard](https://csrc.nist.gov/pubs/fips/205/ipd)

There is one more winner with no draft standard available yet:

  - [Falcon](https://falcon-sign.info/) (Fast-Fourier Lattice-based Compact Signatures over NTRU)

### Candidates

The team of winners might be joined by some of the submissions to [Round 4](https://csrc.nist.gov/Projects/post-quantum-cryptography/round-4-submissions) of the standardization project.
Up to now, three of the candidates remain unbroken.
All of them are [code-based](https://en.wikipedia.org/wiki/Post-quantum_cryptography#Code-based_cryptography) KEM's.
For the time being, I've included one of them in this package:

  - [BIKE](https://bikesuite.org/) (Bit Flipping Key Encapsulation)

## Security Categories

Each algorithm comes in multiple variants. They are categorized according to the believed security strength. Namely, NIST defined the following five [security strength categories](https://csrc.nist.gov/projects/post-quantum-cryptography/post-quantum-cryptography-standardization/evaluation-criteria/security-(evaluation-criteria)) based on corresponding attacks on symmetric ciphers:

| category | successful attack at least as hard as                               |
|:--------:|:-------------------------------------------------------------------:|
| 1        | key search on a block cipher with a 128-bit key (e.g. AES128)       |
| 2        | collision search on a 256-bit hash function (e.g. SHA256/ SHA3-256) |
| 3        | key search on a block cipher with a 192-bit key (e.g. AES192)       |
| 4        | collision search on a 384-bit hash function (e.g. SHA384/ SHA3-384) |
| 5        | key search on a block cipher with a 256-bit key (e.g. AES 256)      |
