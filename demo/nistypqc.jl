### A Pluto.jl notebook ###
# v0.19.40

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 757ec163-6e38-4940-8157-77aa866724ff
using PlutoUI

# ╔═╡ bde255a7-e80d-465d-8dc1-d97b5dbff1c1
using NistyPQC

# ╔═╡ 91fd1ee0-e90e-11ee-03bc-3fbd79c3b47a
md"""
# Usage

First, load the package:
"""

# ╔═╡ a910cc58-02ab-4ffc-bf74-debb4e2ad5b2
md"""
## KEM

The key encapsulation mechanisms in this package all implement the following common interface:

  - `(; ek, dk) = generate_keys()`
  - `(; K, c) = encapsulate_secret(ek)`
  - `K = decapsulate_secret(c, dk)`

Here, all of `ek`, `dk`, `K`, and `c` are byte vectors.

### Example

Pick the key encapsulation mechanism of your choice:
"""

# ╔═╡ 0e81e434-acf9-4112-9ad6-e2dc352bc266
@bind KEM Select([
	MLKEM.Category1,
	MLKEM.Category3,
	MLKEM.Category5,
	BIKE.Category1,
	BIKE.Category3,
	BIKE.Category5,
	McEliece.Category1,
	McEliece.Category1f,
	McEliece.Category3,
	McEliece.Category3f,
	McEliece.Category5A,
	McEliece.Category5Af,
	McEliece.Category5B,
	McEliece.Category5Bf,
	McEliece.Category5C,
	McEliece.Category5Cf,
])

# ╔═╡ f0b2f9e5-3870-4dab-b86e-8b2c3e9717bd
md"Generate a key pair for encapsulation and decapsulation:"

# ╔═╡ 34a1c8f5-9732-41b2-9fa9-b59d48807119
(; ek, dk) = KEM.generate_keys()

# ╔═╡ 32e906e5-458f-4ad8-b2f3-175ae8f4f10d
md"Use the encapsulation key `ek` to produce a shared secret `K` and a ciphertext `c`:"

# ╔═╡ 6577dcf9-90bf-4314-88da-b59d5b7b724a
(; K, c) = KEM.encapsulate_secret(ek)

# ╔═╡ 176f0bc2-71d2-484f-99ac-870b578a3994
md"With the knowledge of the decapsulation key `dk` alone, it is then possible to compute `K` from `c`:"

# ╔═╡ a1aa4026-8395-4f68-b2fa-2ab5672f17e9
K == KEM.decapsulate_secret(c, dk)

# ╔═╡ ae5603d3-ff0d-4df8-a7df-f0aba00c6227
md"""
## DSA

The digital signature algorithms in this package all implement the following common interface:

  - `(; sk, pk) = generate_keys()`
  - `sig = sign_message(msg, sk)`
  - `verify_signature(msg, sig, pk)`

Here, all of `sk`, `pk`, `msg`, and `sig` are byte vectors.

### Example

Pick the digital signature algorithm of your choice:
"""

# ╔═╡ f716101e-00ef-47ab-85f3-dafbb65b48fa
@bind DSA Select([
	MLDSA.Category2,
	MLDSA.Category3,
	MLDSA.Category5,
	MLDSA.Category5,
	SLHDSA.Category1s_SHA2,
	SLHDSA.Category1s_SHAKE,
	SLHDSA.Category1f_SHA2,
	SLHDSA.Category1f_SHAKE,
	SLHDSA.Category3s_SHA2,
	SLHDSA.Category3s_SHAKE,
	SLHDSA.Category3f_SHA2,
	SLHDSA.Category3f_SHAKE,
	SLHDSA.Category5s_SHA2,
	SLHDSA.Category5s_SHAKE,
	SLHDSA.Category5f_SHA2,
	SLHDSA.Category5f_SHAKE,
	Falcon.Category1,
	Falcon.Category5,
])

# ╔═╡ 7e9406dc-f329-4290-90d9-b0810edd0a8a
md"Generate a key pair for signature generation and verification:"

# ╔═╡ 559b226f-c795-444f-8de6-96cbdbe268db
(; sk, pk) = DSA.generate_keys()

# ╔═╡ 2ec1c6e8-345c-448e-8bf4-ac27b7ea7b4a
md"Use the secret key `sk` to generate a signature for some message `msg`:"

# ╔═╡ e476d3af-efc1-4aa2-96aa-ad0fed28efa0
msg = b"Sign me!"

# ╔═╡ 4874564d-db7e-42c3-b6fb-5cba1ed2f2d6
sig = DSA.sign_message(msg, sk)

# ╔═╡ ac669f19-07cb-45e7-81c9-221606dc00cb
md"With the public key `pk` alone, it is then possible to check whether the signature for a message was indeed generated with the secret key `sk`:"

# ╔═╡ d95c296b-1779-46ad-a37e-b7aedb1fec8d
DSA.verify_signature(msg, sig, pk)

# ╔═╡ a499535b-d5be-44b5-9e42-163dbc5ceb56
DSA.verify_signature(b"another message", sig, pk)

# ╔═╡ 282991f7-3bf0-420a-ab1f-687760cf96d1
DSA.verify_signature(msg, b"invalid signature", pk)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
NistyPQC = "2b8046e5-a088-403d-a84e-acdf171f9a66"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
NistyPQC = "~0.0.2"
PlutoUI = "~0.7.58"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.2"
manifest_format = "2.0"
project_hash = "174d1edf607487f228f5ad6ce1499f1e1fd8d6ee"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "0f748c81756f2e5e6854298f11ad8b2dfae6911a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.0"

[[deps.ArgCheck]]
git-tree-sha1 = "a3a402a35a2f7e0b87828ccabbd5ebfbebe356b4"
uuid = "dce04be8-c92d-5529-be00-80e4d2c0e197"
version = "2.3.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.0+0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "8b72179abc660bfab5e28472e019392b97d0985c"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.4"

[[deps.IntegerMathUtils]]
git-tree-sha1 = "b8ffb903da9f7b8cf695a8bead8e01814aa24b30"
uuid = "18e54dd8-cb9d-406c-a71d-865a43cbb235"
version = "0.1.2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.NistyPQC]]
deps = ["ArgCheck", "Primes", "Random", "SHA", "SHAKE"]
git-tree-sha1 = "9cb5e803f45f27bac3f7dc914a37c6b1b32ff0be"
uuid = "2b8046e5-a088-403d-a84e-acdf171f9a66"
version = "0.0.2"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "71a22244e352aa8c5f0f2adde4150f62368a3f2e"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.58"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Primes]]
deps = ["IntegerMathUtils"]
git-tree-sha1 = "cb420f77dc474d23ee47ca8d14c90810cafe69e7"
uuid = "27ebfcd6-29c5-5fa9-bf4b-fb8fc14df3ae"
version = "0.5.6"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SHAKE]]
deps = ["Random", "SHA"]
git-tree-sha1 = "d653d4326b6e577e1d789f7e7a23486f24ddc2d3"
uuid = "9c8de619-9405-45f5-abce-b523323dfc2f"
version = "0.0.3"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.Tricks]]
git-tree-sha1 = "eae1bb484cd63b36999ee58be2de6c178105112f"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.8"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╠═757ec163-6e38-4940-8157-77aa866724ff
# ╟─91fd1ee0-e90e-11ee-03bc-3fbd79c3b47a
# ╠═bde255a7-e80d-465d-8dc1-d97b5dbff1c1
# ╟─a910cc58-02ab-4ffc-bf74-debb4e2ad5b2
# ╠═0e81e434-acf9-4112-9ad6-e2dc352bc266
# ╟─f0b2f9e5-3870-4dab-b86e-8b2c3e9717bd
# ╠═34a1c8f5-9732-41b2-9fa9-b59d48807119
# ╟─32e906e5-458f-4ad8-b2f3-175ae8f4f10d
# ╠═6577dcf9-90bf-4314-88da-b59d5b7b724a
# ╟─176f0bc2-71d2-484f-99ac-870b578a3994
# ╠═a1aa4026-8395-4f68-b2fa-2ab5672f17e9
# ╟─ae5603d3-ff0d-4df8-a7df-f0aba00c6227
# ╠═f716101e-00ef-47ab-85f3-dafbb65b48fa
# ╟─7e9406dc-f329-4290-90d9-b0810edd0a8a
# ╠═559b226f-c795-444f-8de6-96cbdbe268db
# ╟─2ec1c6e8-345c-448e-8bf4-ac27b7ea7b4a
# ╠═e476d3af-efc1-4aa2-96aa-ad0fed28efa0
# ╠═4874564d-db7e-42c3-b6fb-5cba1ed2f2d6
# ╟─ac669f19-07cb-45e7-81c9-221606dc00cb
# ╠═d95c296b-1779-46ad-a37e-b7aedb1fec8d
# ╠═a499535b-d5be-44b5-9e42-163dbc5ceb56
# ╠═282991f7-3bf0-420a-ab1f-687760cf96d1
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
