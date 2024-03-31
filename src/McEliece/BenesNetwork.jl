module BenesNetwork

# This is a direct translation of the Python code in Figure 1 of the specification:
#     https://classic.mceliece.org/mceliece-spec-20221023.pdf

function permutation(c)
    m = 1
    while (2 * m - 1) << (m - 1) < length(c)
        m += 1
    end

    n = 1 << m
    pi = collect(0:(n - 1))
    for i ∈ 0:(2 * m - 2)
        gap = 1 << min(i, 2 * m - 2 - i)
        for j ∈ 0:(n ÷ 2 - 1)
            if c[i * n ÷ 2 + j + 1]
                pos = (j % gap) + 2 * gap * (j ÷ gap) + 1
                (pi[pos], pi[pos + gap]) = (pi[pos + gap], pi[pos])
            end
        end
    end

    pi
end

function composeinv(c, pi)
    [y for (x, y) ∈ sort!(collect(zip(pi, c)))]
end

function controlbits(pi)
    n = length(pi)
    m = 1
    while 1 << m < n
        m += 1
    end

    m == 1 && return [isodd(pi[1])]
    p = [pi[x ⊻ 1 + 1] for x ∈ 0:(n - 1)]
    q = [pi[x + 1] ⊻ 1 for x ∈ 0:(n - 1)]

    piinv = composeinv(0:(n - 1), pi)
    (p, q) = (composeinv(p, q), composeinv(q, p))

    c = [min(x, p[x + 1]) for x ∈ 0:(n - 1)]
    (p, q) = (composeinv(p, q), composeinv(q, p))
    for i ∈ 1:(m - 2)
        (cp, p, q) = (composeinv(c, q), composeinv(p, q), composeinv(q, p))
        c = [min(c[x + 1], cp[x + 1]) for x ∈ 0:(n - 1)]
    end

    f = [isodd(c[2 * j + 1]) for j ∈ 0:(n ÷ 2 - 1)]
    F = [x ⊻ f[x ÷ 2 + 1] for x ∈ 0:(n - 1)]
    Fpi = composeinv(F, piinv)
    l = [isodd(Fpi[2 * k + 1]) for k ∈ 0:(n ÷ 2 - 1)]
    L = [y ⊻ l[y ÷ 2 + 1] for y ∈ 0:(n - 1)]
    M = composeinv(Fpi, L)
    subM = [[M[2 * j + e + 1] ÷ 2 for j ∈ 0:(n ÷ 2 - 1)] for e ∈ 0:1]
    subz = map(controlbits, subM)
    z = [s for s0s1 ∈ zip(subz...) for s ∈ s0s1]

    [f; z; l]
end

end # module
