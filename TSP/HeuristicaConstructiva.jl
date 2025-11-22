#!/usr/bin/env julia
################################################################################
# Heurística constructiva voraz para TSP
#
# Construye un recorrido comenzando en una ciudad (por defecto 1) y en cada
# paso selecciona la ciudad no visitada más cercana (greedy).
#
# Uso:
#  julia TSP/HeuristicaConstructuva.jl [ruta_a_matriz]
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

const DEFAULT_MATRIX = joinpath(@__DIR__, "..", "AlgoritmoFuerzaBruta", "matriz-8ciudades.txt")

function read_distance_matrix(path::AbstractString; sep=';')
    data = readdlm(path, sep, header=false)
    return Array{Float64}(data)
end

"""
    detect_no_link_threshold(mat) -> Real

Detecta un umbral útil para interpretar valores como "sin enlace".
Si hay valores >= 1000 devuelve 1000. Si hay ceros fuera de la diagonal devuelve 0.
Si no hay indicadores especiales devuelve 0.0 (no tratar ceros como inválidos).
"""
function detect_no_link_threshold(mat::AbstractMatrix{<:Real})
    n = size(mat, 1)
    has_large = any(x -> x >= 1000.0, mat)
    if has_large
        return 1000.0
    end
    # comprobar ceros fuera de diagonal
    for i in 1:n, j in 1:n
        if i != j && mat[i,j] == 0.0
            return 0.0
        end
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
    @info "Leyendo matriz de distancias" archivo=matrix_file
    if !isfile(matrix_file)
        @error "Archivo de matriz no encontrado" archivo=matrix_file
        return
    end
    mat = read_distance_matrix(matrix_file; sep=';')
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

        (tour, dist) = construir_recorrido_voraz(mat; start=1, no_link_threshold=no_link_threshold, random_ties=false)
        if dist == Inf
            @error "No se pudo construir un recorrido válido con la estrategia voraz (grafo posiblemente desconectado)."
            return
        end
    end
    @info "Tiempo de ejecución" segundos=elapsed_time
    @info "Recorrido voraz encontrado" distancia=dist tour=tour
    println("Recorrido voraz: $(join(tour, " → "))")
    println("Distancia total: $(dist)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    global_logger(SimpleLogger(stderr, Logging.Info))
    main()
end
