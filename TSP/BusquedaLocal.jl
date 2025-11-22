
#!/usr/bin/env julia
################################################################################
# Búsqueda local para TSP (2-opt greedy)
#
# Este archivo implementa una búsqueda local basada en la operación 2-opt
# (subviaje inverso) aplicada de forma greedy: a partir de un recorrido
# inicial válido realiza inversiones de segmentos y acepta la primera mejora
# encontrada en cada iteración hasta converger.
#
# Características principales:
#  - Lee una matriz de distancias desde un archivo con separador `;`.
#  - Trata valores grandes (por ejemplo 1000) como "sin enlace" mediante un
#    umbral `no_link_threshold` (se utiliza 1000 por defecto en este repositorio).
#  - Construye un recorrido inicial válido de forma aleatoria (intenta hasta
#    `max_initial_attempts`) y aplica 2-opt greedy sobre ese recorrido.
#  - Devuelve el recorrido final y su distancia total. Si no existe recorrido
#    válido (grafo desconectado o umbral mal configurado), informa el error.
#
# Uso:
#  julia TSP/BusquedaLocal.jl [ruta_a_matriz]
#
# Ejemplo (usa por defecto `AlgoritmoFuerzaBruta/matriz-8ciudades.txt`):
#  julia TSP/BusquedaLocal.jl
#  julia TSP/BusquedaLocal.jl AlgoritmoFuerzaBruta/matriz-8ciudades.txt
#
# Notas para mantenimiento:
#  - El comportamiento actual es greedy (acepta la primera mejora). Para una
#    búsqueda más exhaustiva se puede cambiar el criterio y probar todas las
#    inversiones en cada iteración (o usar 3-opt/ LK).
#  - Se recomienda configurar `no_link_threshold` y `max_initial_attempts` desde
#    la línea de comandos si se desea mayor control.
################################################################################

using DelimitedFiles
using Random
using Logging

const DEFAULT_MATRIX = joinpath(@__DIR__, "..", "AlgoritmoFuerzaBruta", "matriz-8ciudades.txt")

"""
	read_distance_matrix(path; sep=';') -> Matrix{Float64}

Lee una matriz de distancias desde `path`. Devuelve una matriz de Float64.
"""
function read_distance_matrix(path::AbstractString; sep=';')
	data = readdlm(path, sep, header=false)
	return Array{Float64}(data)
end

"""
	calculate_path_distance(path::AbstractVector{Int}, mat::AbstractMatrix{<:Real}; no_link_threshold=0.0)

Calcula la distancia total de `path` usando la matriz `mat`.
Si `no_link_threshold > 0` se interpretan como arcos inexistentes todos los valores
`d >= no_link_threshold` y la función devuelve `Inf` (ruta inválida) en ese caso.
Si `no_link_threshold == 0` se interpreta el valor 0 como "sin enlace" (comportamiento previo).
"""
function calculate_path_distance(path::AbstractVector{Int}, mat::AbstractMatrix{<:Real}; no_link_threshold::Real=0.0)
	total = 0.0
	n = length(path)
	for i in 1:n-1
		a = path[i]
		b = path[i+1]
		d = float(mat[a, b])
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
	two_opt(initial_tour, mat; max_iterations=10_000, treat_zero_as_inf=true, random_restarts=0)

Aplica 2-opt greedy a `initial_tour` usando `mat`. Devuelve (best_tour, best_dist, history)
`history` es un vector de (tour, distance) para cada mejora encontrada.
"""
function two_opt(initial_tour::Vector{Int}, mat::AbstractMatrix{<:Real}; max_iterations::Int=10_000, no_link_threshold::Real=0.0, random_restarts::Int=0)
	best_tour = copy(initial_tour)
	best_dist = calculate_path_distance(best_tour, mat; no_link_threshold=no_link_threshold)
	history = [(copy(best_tour), best_dist)]

	function improve_once!(tour)
		n = length(tour) - 1  # last repeats first
		for i in 2:n-1  # avoid breaking the start city at position 1
			for k in i+1:n
				new_tour = vcat(tour[1:i-1], reverse(tour[i:k]), tour[k+1:end])
				d = calculate_path_distance(new_tour, mat; no_link_threshold=no_link_threshold)
				if d < best_dist
					return (true, new_tour, d)
				end
			end
		end
		return (false, tour, best_dist)
	end

	# Greedy 2-opt loop
	iter = 0
	improved = true
	while improved && iter < max_iterations
		iter += 1
		improved = false
		# attempt improvement on current best tour
		(ok, new_tour, new_dist) = improve_once!(best_tour)
		if ok && new_dist < best_dist
			best_tour = new_tour
			best_dist = new_dist
			push!(history, (copy(best_tour), best_dist))
			improved = true
			@info "Iteración 2-opt: mejora encontrada" iter=iter distancia=best_dist
		end
	end

	# Optional random restarts
	for r in 1:random_restarts
		seed_tour = copy(initial_tour)
		shuffle!(seed_tour[2:end-1])  # keep first and last fixed (closed tour)
		(tour_r, dist_r, hist_r) = two_opt(seed_tour, mat; max_iterations=max_iterations, no_link_threshold=no_link_threshold, random_restarts=0)
		if dist_r < best_dist
			best_tour = tour_r
			best_dist = dist_r
			append!(history, hist_r)
			@info "Random restart encontró mejor solución" restart=r distancia=best_dist
		end
	end

	return (best_tour, best_dist, history)
end

function main()
	# Parámetros y archivo de entrada
	matrix_file = length(ARGS) >= 1 ? ARGS[1] : DEFAULT_MATRIX
	@info "Leyendo matriz de distancias" archivo=matrix_file

	if !isfile(matrix_file)
		@error "Archivo de matriz no encontrado" archivo=matrix_file
		return
	end

	mat = read_distance_matrix(matrix_file; sep=';')
	n = size(mat, 1)
	@info "Matriz leída" n_ciudades=n

	# Construir recorrido inicial aleatorio: generar permutaciones aleatorias hasta
	# encontrar un recorrido válido (sin arcos marcados como "no enlace").
	# Para esta matriz se usan valores grandes (1000) para indicar arcos inexistentes;
	# interpretamos valores >= 1000 como "sin enlace".
	no_link_threshold = 1000.0
	max_initial_attempts = 1000
	initial_tour = nothing
	initial_dist = Inf

	for attempt in 1:max_initial_attempts
		# Generar recorrido aleatorio que comienza y termina en 1
		middle = collect(2:n)
		shuffle!(middle)
		candidate = vcat(1, middle, 1)
		cand_dist = calculate_path_distance(candidate, mat; no_link_threshold=no_link_threshold)
		if cand_dist != Inf
			initial_tour = candidate
			initial_dist = cand_dist
			@info "Recorrido inicial válido encontrado" intento=attempt distancia=initial_dist tour=initial_tour
			break
		end
	end

	if initial_tour === nothing
		@error "No se encontró recorrido inicial válido tras $max_initial_attempts intentos. Revisa la conectividad de la matriz."
		return
	end

    elapsed_time = @elapsed begin

		# Ejecutar 2-opt partiendo del recorrido inicial válido
		(best_tour, best_dist, history) = two_opt(initial_tour, mat; max_iterations=10000, no_link_threshold=no_link_threshold, random_restarts=0)

		if best_dist == Inf
			@error "No se encontró recorrido válido (grafo desconectado o arcos inexistentes)."
			return
		end
    end

	@info "RESULTADO FINAL" distancia=best_dist tour=best_tour mejoras=length(history)-1
	@info "Tiempo de ejecución" segundos=elapsed_time
	println("Recorrido final: $(join(best_tour, " → "))")
	println("Distancia total: $(best_dist)")
end

if abspath(PROGRAM_FILE) == @__FILE__
	global_logger(SimpleLogger(stderr, Logging.Info))
    main()
end

