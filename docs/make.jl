using Documenter, NistyPQC

makedocs(
    sitename = "NistyPQC.jl",
    pages = [
        "Package" => ["index.md", "installation.md", "usage.md", "lengths.md"],
        "KEM" => ["mlkem.md", "bike.md"],
        "DSA" => ["mldsa.md", "slhdsa_sha2.md", "slhdsa_shake.md", "falcon.md"],
    ],
)

deploydocs(repo = "github.com/erich-9/NistyPQC.jl.git")
