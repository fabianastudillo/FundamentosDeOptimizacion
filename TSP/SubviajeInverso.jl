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

const DEFAULT_MATRIX = joinpath(@__DIR__, "..", "AlgoritmoFuerzaBruta", "matriz-8ciudades.txt")

"""
    read_matrix(path) -> Matrix{Float64}

Lee una matriz de distancias desde `path` usando `;` como separador.
"""
function read_matrix(path::AbstractString)
    data = readdlm(path, ';', header=false)
    return Array{Float64}(data)
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
        if d >= no_link_threshold
            return Inf
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
    @info "Leyendo matriz" archivo=matrix_file
    if !isfile(matrix_file)
        @error "Archivo no encontrado" archivo=matrix_file
        return
    end

    mat = read_matrix(matrix_file)
    n = size(mat,1)
    @info "Matriz leída" n_ciudades=n

	elapsed_time = @elapsed begin
		no_link_threshold = 1000.0
		@info "Umbral 'no enlace'" threshold=no_link_threshold

		# generar recorrido inicial aleatorio con nodo 1 fijo
		initial = random_initial_tour(n; start=1, mat=mat, no_link_threshold=no_link_threshold, max_attempts=1000)
		if initial === nothing
			@error "No se encontró recorrido inicial válido tras intentos. Revisa la matriz o el umbral."
			return
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
