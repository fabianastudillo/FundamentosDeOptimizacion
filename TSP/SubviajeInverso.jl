#!/usr/bin/env julia
################################################################################
# Subviaje inverso (2-opt) - implementación limpia
#
# Implementa la heurística de inversión de segmentos (2-opt) para TSP.
# - Lee una matriz de distancias (separador `;`).
# - Trata valores >= `no_link_threshold` como "sin arco" (Inf).
# - Construye un recorrido inicial aleatorio (nodo 1 fijo como inicio/fin).
# - Aplica 2-opt greedy (acepta la primera mejora encontrada) hasta converger.
#
# Uso:
#  julia TSP/SubviajeInverso.jl [ruta_a_matriz]
#
# Ejemplo:
#  julia TSP/SubviajeInverso.jl AlgoritmoFuerzaBruta/matriz-8ciudades.txt
################################################################################

using DelimitedFiles
using Random
using Logging

const DEFAULT_MATRIX = joinpath(@__DIR__, "..", "data", "matriz-8ciudades.txt")

"""
    read_matrix(path) -> Matrix{Float64}

Lee una matriz de distancias desde `path` usando `;` como separador.
"""
function read_matrix(path::AbstractString)
    # Leer línea a línea y parsear tokens separados por ; , o espacios
    raw = readlines(path)
    mat_rows = Vector{Vector{Float64}}()
    for ln in raw
        line = strip(ln)
        if isempty(line) || startswith(line, "```") || startswith(line, "#")
            continue
        end
        parts = split(line, r"[;,:\s]+")
        parts = filter(x -> !isempty(x), parts)
        if isempty(parts)
            continue
        end
        row = Float64[]
        for p in parts
            try
                push!(row, parse(Float64, strip(p)))
            catch e
                throw(ArgumentError("No se pudo parsear token '$p' en la línea: $line"))
            end
        end
        push!(mat_rows, row)
    end
    if isempty(mat_rows)
        throw(ArgumentError("No se encontraron datos numéricos en $path"))
    end
    ncols = length(mat_rows[1])
    for (i, r) in enumerate(mat_rows)
        if length(r) != ncols
            throw(ArgumentError("Número inconsistente de columnas en la línea $i: esperado $ncols, encontrado $(length(r))"))
        end
    end
    m = zeros(Float64, length(mat_rows), ncols)
    for i in 1:length(mat_rows), j in 1:ncols
        m[i,j] = mat_rows[i][j]
    end
    @info "Matriz leída" n_rows=size(m,1) n_cols=size(m,2)
    return m
end

function parse_no_link_from_args()
    for a in ARGS
        if startswith(a, "--no-link=")
            s = split(a, "=", limit=2)[2]
            try
                return parse(Float64, s)
            catch
                return nothing
            end
        end
    end
    # support `--no-link NUM`
    for (i,a) in enumerate(ARGS)
        if a == "--no-link"
            if i < length(ARGS)
                try
                    return parse(Float64, ARGS[i+1])
                catch
                    return nothing
                end
            end
        end
    end
    return nothing
end

# Greedy nearest-neighbour constructive heuristic used as fallback
function construir_recorrido_voraz(mat::AbstractMatrix{<:Real}; start::Int=1, no_link_threshold::Real=0.0, random_ties::Bool=false)
    n = size(mat,1)
    visited = falses(n)
    tour = Int[]
    push!(tour, start)
    visited[start] = true
    current = start

    while sum(visited) < n
        best_d = Inf
        candidates = Int[]
        for j in 1:n
            if !visited[j]
                d = float(mat[current,j])
                is_invalid = (no_link_threshold > 0.0) ? (d >= no_link_threshold) : (d == 0.0)
                if !is_invalid
                    if d < best_d - 1e-12
                        best_d = d
                        candidates = [j]
                    elseif abs(d - best_d) <= 1e-12
                        push!(candidates, j)
                    end
                end
            end
        end
        if isempty(candidates)
            return (Int[], Inf)
        end
        next_city = random_ties && length(candidates) > 1 ? rand(candidates) : candidates[1]
        push!(tour, next_city)
        visited[next_city] = true
        current = next_city
    end
    push!(tour, start)
    dist = tour_distance(tour, mat; no_link_threshold=no_link_threshold)
    return (tour, dist)
end

function detect_no_link_threshold(mat::AbstractMatrix{<:Real})
    n = size(mat,1)
    off = Float64[]
    for i in 1:n, j in 1:n
        if i != j
            push!(off, float(mat[i,j]))
        end
    end
    counts = Dict{Float64,Int}()
    for v in off
        counts[v] = get(counts, v, 0) + 1
    end
    for (v,c) in counts
        if v >= 1000.0 && c >= n
            return v
        end
    end
    if any(x -> x == 0.0, off)
        return 0.0
    end
    return 0.0
end

"""
    tour_distance(tour, mat; no_link_threshold=1000.0) -> Float64

Calcula la distancia total de `tour` usando `mat`.
Si algún arco tiene distancia >= no_link_threshold devuelve `Inf`.
"""
function tour_distance(tour::AbstractVector{Int}, mat::AbstractMatrix{<:Real}; no_link_threshold::Real=1000.0)
    total = 0.0
    for i in 1:length(tour)-1
        a = tour[i]
        b = tour[i+1]
        d = float(mat[a,b])
        if no_link_threshold > 0.0
            if d >= no_link_threshold
                return Inf
            end
        else
            if d == 0.0
                return Inf
            end
        end
        total += d
    end
    return total
end

"""
    two_opt_greedy(initial_tour, mat; no_link_threshold=1000.0, max_iterations=10_000)

Aplica la heurística 2-opt (greedy) sobre `initial_tour`.
Devuelve (best_tour, best_dist, history) donde history contiene mejoras.
"""
function two_opt_greedy(initial_tour::Vector{Int}, mat::AbstractMatrix{<:Real}; no_link_threshold::Real=1000.0, max_iterations::Int=10_000)
    best_tour = copy(initial_tour)
    best_dist = tour_distance(best_tour, mat; no_link_threshold=no_link_threshold)
    history = [(copy(best_tour), best_dist)]

    n = length(best_tour) - 1  # closed tour with repeat of start
    iter = 0
    improved = true

    while improved && iter < max_iterations
        iter += 1
        improved = false
        # explorar inversiones i..k (evitar la ciudad 1 en i=1)
        for i in 2:n-1
            for k in i+1:n
                new_tour = vcat(best_tour[1:i-1], reverse(best_tour[i:k]), best_tour[k+1:end])
                d = tour_distance(new_tour, mat; no_link_threshold=no_link_threshold)
                if d < best_dist
                    best_tour = new_tour
                    best_dist = d
                    push!(history, (copy(best_tour), best_dist))
                    @info "Mejora 2-opt" iter=iter i=i k=k distancia=best_dist
                    improved = true
                    break  # greedy: aceptar la primera mejora
                end
            end
            if improved
                break
            end
        end
    end

    return (best_tour, best_dist, history)
end

"""
    random_initial_tour(n; start=1, mat, no_link_threshold=1000.0, max_attempts=1000)

Genera recorridos aleatorios que comienzan y terminan en `start` hasta
encontrar uno válido (distancia < Inf) o agotar `max_attempts`.
Devuelve tour o nothing si no encuentra.
"""
function random_initial_tour(n::Int; start::Int=1, mat::AbstractMatrix{<:Real}, no_link_threshold::Real=1000.0, max_attempts::Int=1000)
    middle = collect(2:n)
    for attempt in 1:max_attempts
        shuffle!(middle)
        candidate = vcat(start, middle, start)
        if tour_distance(candidate, mat; no_link_threshold=no_link_threshold) < Inf
            return candidate
        end
    end
    return nothing
end

function main()
    matrix_file = length(ARGS) >= 1 ? ARGS[1] : DEFAULT_MATRIX
    # opcional: segundo argumento con recorrido inicial como lista separada por comas, p.ej. "1,2,3,1"
    function parse_initial_tour_arg(s::AbstractString)
        parts = split(s, r"[,;:\s]+")
        parts = filter(x->!isempty(x), parts)
        if isempty(parts)
            return nothing
        end
        try
            tour = [parse(Int, strip(p)) for p in parts]
            return tour
        catch
            return nothing
        end
    end
    initial_arg = length(ARGS) >= 2 ? parse_initial_tour_arg(ARGS[2]) : nothing
    @info "Leyendo matriz" archivo=matrix_file
    if !isfile(matrix_file)
        @error "Archivo no encontrado" archivo=matrix_file
        return
    end

    mat = read_matrix(matrix_file)
    n = size(mat,1)
    @info "Matriz leída" n_ciudades=n

    elapsed_time = @elapsed begin
        # allow CLI override of no-link threshold
        cli_no_link = parse_no_link_from_args()
        no_link_threshold = cli_no_link === nothing ? detect_no_link_threshold(mat) : cli_no_link
        if no_link_threshold > 0.0
            @info "Umbral 'no enlace'" threshold=no_link_threshold
        else
            @info "No se detectó umbral 'no enlace' explícito; usar umbral 0 -> ceros inválidos" 
        end

        # si se pasó un recorrido inicial por ARGS usarlo (validarlo)
        initial = nothing
        if initial_arg !== nothing
            cand = initial_arg
            if length(cand) == n+1 && cand[1] == cand[end]
                if tour_distance(cand, mat; no_link_threshold=no_link_threshold) < Inf
                    initial = cand
                    @info "Usando recorrido inicial pasado por ARGS" tour=initial
                else
                    @warn "Recorrido inicial pasado por ARGS no es válido bajo el umbral" tour=cand
                end
            else
                @warn "Recorrido inicial pasado por ARGS no tiene formato esperado (debe incluir cierre)" arg=ARGS[2]
            end
        end
        if initial === nothing
            initial = random_initial_tour(n; start=1, mat=mat, no_link_threshold=no_link_threshold, max_attempts=1000)
        end
        if initial === nothing
            @warn "Recorrido aleatorio inicial inválido; intentando heurística constructiva y otros starts"

            # 1) intentar heurística constructiva desde start=1
            (c_tour, c_dist) = construir_recorrido_voraz(mat; start=1, no_link_threshold=no_link_threshold, random_ties=false)
            if c_dist < Inf
                initial = c_tour
                @info "Recorrido encontrado por heurística constructiva" distancia=c_dist tour=initial
            else
                # 2) probar todos los starts con heurística constructiva
                best_t = Int[]
                best_d = Inf
                for s in 1:n
                    (t2, d2) = construir_recorrido_voraz(mat; start=s, no_link_threshold=no_link_threshold, random_ties=false)
                    if d2 < best_d
                        best_d = d2
                        best_t = t2
                    end
                end
                if best_d < Inf
                    initial = best_t
                    @info "Recorrido encontrado probando distintos starts" distancia=best_d
                else
                    # 3) reinicios aleatorios con ruptura de empates
                    RESTARTS = 200
                    best_t = Int[]
                    best_d = Inf
                    for r in 1:RESTARTS
                        (t2, d2) = construir_recorrido_voraz(mat; start=rand(1:n), no_link_threshold=no_link_threshold, random_ties=true)
                        if d2 < best_d
                            best_d = d2
                            best_t = t2
                        end
                    end
                    if best_d < Inf
                        initial = best_t
                        @info "Recorrido encontrado mediante reinicios aleatorios" distancia=best_d
                    else
                        @error "No se encontró recorrido inicial válido tras múltiples estrategias. Revisa la matriz o el umbral." 
                        return
                    end
                end
            end
        end

        @info "Recorrido inicial válido" tour=initial distancia=tour_distance(initial, mat; no_link_threshold=no_link_threshold)

        # ejecutar 2-opt greedy
        (best_tour, best_dist, history) = two_opt_greedy(initial, mat; no_link_threshold=no_link_threshold)
    end
    @info "Tiempo de ejecución" segundos=elapsed_time
    @info "Resultado final" distancia=best_dist mejoras=length(history)-1
    println("Recorrido final: $(join(best_tour, " → "))")
    println("Distancia total: $(best_dist)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    global_logger(SimpleLogger(stderr, Logging.Info))
    main()
end
