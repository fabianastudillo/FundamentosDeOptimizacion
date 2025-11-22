#!/usr/bin/env julia
################################################################################
# Heurística constructiva voraz para TSP
#
# Construye un recorrido comenzando en una ciudad (por defecto 1) y en cada
# paso selecciona la ciudad no visitada más cercana (greedy).
#
# Uso:
#  julia TSP/HeuristicaConstructuva.jl [ruta_a_matriz] [--seed=NUM]
#
# Opciones:
#  --seed=NUM, -s NUM, --seed NUM    Fija la semilla del RNG para resultados reproducibles
#
# Notas:
#  - La matriz debe ser cuadrada y separada por `;`.
#  - Los valores que representen "sin enlace" pueden indicarse con un umbral
#    alto (por ejemplo 1000). El script detecta automáticamente 1000 si aparece
#    en la matriz, o 0 si hay ceros fuera de la diagonal.
################################################################################

using DelimitedFiles
using Random
using Logging

const DEFAULT_MATRIX = joinpath(@__DIR__, "..", "data", "matriz-8ciudades.txt")

function read_distance_matrix(path::AbstractString)
    # Leer línea a línea y separar por ';' ',' o espacios. Ignorar líneas no numéricas
    raw = readlines(path)
    rows = Float64[]
    mat_rows = Vector{Vector{Float64}}()
    for ln in raw
        line = strip(ln)
        if isempty(line) || startswith(line, "```") || startswith(line, "#")
            continue
        end
        # dividir por cualquiera de ; , o espacios (uno o más)
        parts = split(line, r"[;,:\s]+")
        # filtrar tokens vacíos
        parts = filter(x -> !isempty(x), parts)
        if isempty(parts)
            continue
        end
        row = Float64[]
        for p in parts
            try
                push!(row, parse(Float64, strip(p)))
            catch e
                # Si no se puede parsear, propagar con contexto
                throw(ArgumentError("No se pudo parsear token '$p' en la línea: $line"))
            end
        end
        push!(mat_rows, row)
    end
    if isempty(mat_rows)
        throw(ArgumentError("No se encontraron datos numéricos en $path"))
    end
    # verificar consistencia de columnas
    ncols = length(mat_rows[1])
    for (i, r) in enumerate(mat_rows)
        if length(r) != ncols
            throw(ArgumentError("Número inconsistente de columnas en la línea $i: esperado $ncols, encontrado $(length(r))"))
        end
    end
    # construir matriz
    m = zeros(Float64, length(mat_rows), ncols)
    for i in 1:length(mat_rows), j in 1:ncols
        m[i,j] = mat_rows[i][j]
    end
    @info "Matriz leída" n_rows=size(m,1) n_cols=size(m,2)
    return m
end

function parse_seed_from_args()
    # busca --seed=NN
    for a in ARGS
        if startswith(a, "--seed=")
            s = split(a, "=", limit=2)[2]
            try
                return parse(Int, s)
            catch
                return nothing
            end
        end
    end
    # buscar -s NUM o --seed NUM
    for (i, a) in enumerate(ARGS)
        if a == "-s" || a == "--seed"
            if i < length(ARGS)
                try
                    return parse(Int, ARGS[i+1])
                catch
                    return nothing
                end
            end
        end
    end
    return nothing
end

"""
    detect_no_link_threshold(mat) -> Real

Detecta un umbral útil para interpretar valores como "sin enlace".
Si hay valores >= 1000 devuelve 1000. Si hay ceros fuera de la diagonal devuelve 0.
Si no hay indicadores especiales devuelve 0.0 (no tratar ceros como inválidos).
"""
function detect_no_link_threshold(mat::AbstractMatrix{<:Real})
    n = size(mat, 1)
    # analizar valores fuera de la diagonal para detectar un candidato repetido
    off = Float64[]
    for i in 1:n, j in 1:n
        if i != j
            push!(off, float(mat[i,j]))
        end
    end
    # contar frecuencias de valores y buscar un valor grande repetido (p.ej. 1000)
    counts = Dict{Float64,Int}()
    for v in off
        counts[v] = get(counts, v, 0) + 1
    end
    for (v,c) in counts
        if v >= 1000.0 && c >= n
            return v
        end
    end
    # si hay ceros fuera de diagonal, usarlos como marcador
    if any(x -> x == 0.0, off)
        return 0.0
    end
    return 0.0
end

"""
    calculate_path_distance(path, mat; no_link_threshold=0.0) -> Real

Suma las distancias del recorrido. Devuelve Inf si encuentra un arco >= umbral
"""
function calculate_path_distance(path::AbstractVector{Int}, mat::AbstractMatrix{<:Real}; no_link_threshold::Real=0.0)
    total = 0.0
    for i in 1:length(path)-1
        a = path[i]
        b = path[i+1]
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
    construir_recorrido_voraz(mat; start=1, no_link_threshold=0.0, random_ties=false)

Construye un recorrido greedy: siempre elige la ciudad más cercana no visitada.
Devuelve (tour, distance) donde tour está cerrado (termina en start).
"""
function construir_recorrido_voraz(mat::AbstractMatrix{<:Real}; start::Int=1, no_link_threshold::Real=0.0, random_ties::Bool=false)
    n = size(mat,1)
    visited = falses(n)
    tour = Int[]
    push!(tour, start)
    visited[start] = true
    current = start

    while sum(visited) < n
        # buscar la ciudad no visitada más cercana válida
        best = 0
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
            # no hay ciudad alcanzable
            return (Int[], Inf)
        end

        if random_ties && length(candidates) > 1
            next_city = rand(candidates)
        else
            next_city = candidates[1]
        end

        push!(tour, next_city)
        visited[next_city] = true
        current = next_city
    end

    # cerrar el tour
    push!(tour, start)
    distancia = calculate_path_distance(tour, mat; no_link_threshold=no_link_threshold)
    return (tour, distancia)
end

function main()
    matrix_file = length(ARGS) >= 1 ? ARGS[1] : DEFAULT_MATRIX
    # detectar seed en ARGS (soporta --seed=NUM, -s NUM, --seed NUM)
    seed = parse_seed_from_args()
    if seed === nothing
        # generar seed a partir de milisegundos actuales
        ms = Int(Base.time_ns() ÷ 1_000_000)
        # reducir tamaño para evitar overflow en algunas plataformas
        seed = Int(ms % Int(2^31 - 1))
        @info "No se recibió seed; generando semilla a partir de milisegundos" seed=seed
    else
        @info "Fijando semilla RNG" seed=seed
    end
    Random.seed!(seed)
    @info "Leyendo matriz de distancias" archivo=matrix_file
    if !isfile(matrix_file)
        @error "Archivo de matriz no encontrado" archivo=matrix_file
        return
    end
    mat = read_distance_matrix(matrix_file)
    n = size(mat,1)
    @info "Matriz leída" n_ciudades=n

    elapsed_time = @elapsed begin
        # detectar umbral automáticamente
        no_link_threshold = detect_no_link_threshold(mat)
        if no_link_threshold > 0.0
            @info "Interpretando valores >= $no_link_threshold como 'sin enlace'"
        else
        # si el detector devolvió 0, puede que haya ceros fuera de diagonal o no
        has_zero_offdiag = any(mat[i,j] == 0.0 for i in 1:n for j in 1:n if i != j)
            if has_zero_offdiag
                @info "Interpretando ceros fuera de diagonal como 'sin enlace'"
            else
                @info "No se detectaron marcadores de 'sin enlace' (usar threshold 0 -> ceros no válidos)"
            end
        end

        # intento inicial desde la ciudad 1
        (tour, dist) = construir_recorrido_voraz(mat; start=1, no_link_threshold=no_link_threshold, random_ties=false)
        if dist == Inf
            @warn "Recorrido voraz inválido desde start=1; intentando otras estrategias (otros starts, reinicios aleatorios)."

            # 1) probar todos los posibles start
            best_tour = Int[]
            best_dist = Inf
            for s in 1:n
                (t2, d2) = construir_recorrido_voraz(mat; start=s, no_link_threshold=no_link_threshold, random_ties=false)
                if d2 < best_dist
                    best_dist = d2
                    best_tour = t2
                end
            end

            if best_dist < Inf
                @info "Se encontró recorrido válido probando distintos starts" start_used=best_tour[1] distancia=best_dist
                tour, dist = best_tour, best_dist
            else
                # 2) reinicios aleatorios con ruptura de empates
                RESTARTS = 100
                @info "Ningún start produjo tour válido; intentando $RESTARTS reinicios aleatorios (ruptura de empates)."
                best_tour = Int[]
                best_dist = Inf
                for r in 1:RESTARTS
                    start_r = rand(1:n)
                    (t2, d2) = construir_recorrido_voraz(mat; start=start_r, no_link_threshold=no_link_threshold, random_ties=true)
                    if d2 < best_dist
                        best_dist = d2
                        best_tour = t2
                    end
                end
                if best_dist < Inf
                    @info "Se encontró recorrido válido mediante reinicios aleatorios" distancia=best_dist
                    tour, dist = best_tour, best_dist
                else
                    @error "No se pudo construir un recorrido válido después de probar starts y reinicios aleatorios. El grafo parece desconectado."
                    return
                end
            end
        end
    end
    @info "Tiempo de ejecución" segundos=elapsed_time
    @info "Recorrido voraz encontrado" distancia=dist tour=tour
    # Normalizar salida para que el tour comience en la ciudad 1 si es posible
    function rotate_tour_to_start(tour::Vector{Int}, start::Int)
        # espera tour cerrado (último == primer elemento)
        if isempty(tour)
            return tour
        end
        # encontrar índice de la primera aparición de 'start' (sin contar el cierre final)
        idx = findfirst(x -> x == start, tour[1:end-1])
        if idx === nothing
            return tour
        end
        # construir tour rotado y cerrado
        rotated = vcat(tour[idx:end-1], tour[1:idx])
        push!(rotated, rotated[1])
        return rotated
    end

    if !isempty(tour) && tour[1] != 1 && 1 in tour
        tour = rotate_tour_to_start(tour, 1)
        @info "Tour rotado para comenzar en 1" tour=tour
    end
    println("Recorrido voraz: $(join(tour, " → "))")
    println("Distancia total: $(dist)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    global_logger(SimpleLogger(stderr, Logging.Info))
    main()
end
