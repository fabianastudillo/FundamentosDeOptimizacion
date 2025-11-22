"""
TSP_GRASP_Solver.jl

Breve descripción:
    Implementación sencilla de GRASP + búsqueda local para instancias TSP en
    formato tipo TSPLIB. Este script incluye funciones para leer la instancia,
    construir una solución inicial (greedy), aplicar la construcción GRASP y
    mejorarla con búsqueda local por inversiones de subsegmentos.

Dependencias:
    - Sólo Base y Random; no se requieren paquetes externos adicionales.

Uso:
    julia TSP_GRASP_Solver.jl
    o llamar a `TSP_Solver("./data/bier127.tsp")` desde otro script.

Notas:
    - El algoritmo es heurístico: no garantiza obtener el óptimo global. Se
        usa para comparar con soluciones exactas (ILP) y evaluar calidad/tiempo.
    - Hay parámetros configurables (tamaño de la lista restringida `k` en GRASP,
        límite de tiempo para la búsqueda local y tiempo total de ejecución en
        `TSP_Solver`).
"""

import Random
import Dates

""" readInstance(filename) -> (coord, dim)
Lee una instancia TSP en un formato simple tipo TSPLIB.

Devuelve:
    - coord: matriz Float32 (dim x 2) con las coordenadas de los nodos.
    - dim: número entero de ciudades.

Supuestos:
    - El archivo contiene una línea con `DIMENSION : <n>` y una sección de
        coordenadas con filas `indice x y`.
"""
function readInstance(filename)
    file = open(filename)
    name = split(readline(file),":")[2] # name of the instance (not used)
    readline(file); readline(file) # skip 2 lines
    dim = parse(Int32, split(readline(file),":")[2]) # the number of cities
    readline(file); readline(file) # skip 2 lines
    coord = zeros(Float32, dim, 2) # coordinates
    for i in 1:dim
        data = parse.(Float32, split(readline(file)))
        coord[i, :] = data[2:3]
    end
    close(file)
    return coord, dim
end

""" getDistanceMatrix(coord, dim) -> dist
Calcula la matriz de distancias euclídeas (redondeadas) para las coordenadas
proporcionadas.

Argumentos:
    - coord: matriz (dim x 2) con coordenadas (x,y).
    - dim: número de ciudades (filas de coord).

Devuelve:
    - dist: matriz (dim x dim) simétrica con distancias (Float32).
"""
function getDistanceMatrix(coord::Array{Float32,2}, dim::Int32)
    dist = zeros(Float32, dim, dim)
    for i in 1:dim
        for j in 1:dim
            if i != j
                dist[i, j] = round(sqrt((coord[i, 1] - coord[j, 1])^2 + (coord[i, 2] - coord[j, 2])^2), digits=0)
            end
        end
    end
    return dist
end

""" findPathGreedy(dist) -> visitsequence
Construye un recorrido voraz por vecino más cercano empezando en la ciudad 1.

Devuelve un arreglo con el orden de visita (índices 1..dim).
"""
function findPathGreedy(dist)
    dim = length(dist[1, : ])
    visited = zeros(Int32, dim)
    vistsequence = zeros(Int32, dim)
    visited[1] = 1     # start from city 1
    vistsequence[1] = 1
    next = 1
    index = 0

    for i in 2:dim
        minDist = sum(dist[next, :]) # give a large initial value
        for j in 1:dim
            if visited[j] == 0
                if 0 < dist[next, j] <= minDist
                    minDist = dist[next, j]
                    index = j
                end
            end
        end
        next = index
        vistsequence[i] = index
        visited[next] = 1
    end
    return vistsequence
end

#GRASP
""" findNext(visited, curDist, bound) -> index

En la fase constructiva GRASP, construye una Lista Restringida de Candidatos
(RCL) de tamaño `bound` con los vecinos no visitados más cercanos y elige uno
aleatoriamente.
"""
function findNext(visited, curDist, bound::Int64)
    indexedDist = []
    neighbors = [] # store n neighbors

    for i in 1:length(curDist) # sort cities by distance
        append!(indexedDist, [(curDist[i], i)])
    end
    sortedDist = sort(indexedDist, by = first)
    for j in 1:length(curDist) # find neighbors
        if bound == 0
            break
        end
        if visited[sortedDist[j][2]] == 0 # ensure neighbor not visited
            append!(neighbors, sortedDist[j][2])
            bound -= 1
        end
    end

    neighborIndex = rand(1:length(neighbors))
    return neighbors[neighborIndex]
end

""" GRASP_findRoute(dist, dim, route, k) -> (route, cost)

Construye un recorrido usando la construcción GRASP (voraz aleatorizada).

Argumentos:
    - dist: matriz de distancias
    - dim: número de ciudades
    - route: arreglo usado para almacenar el recorrido construido (modificado in-place)
    - k: tamaño de la RCL (lista restringida de candidatos)

Devuelve una tupla (route, cost).
"""
function GRASP_findRoute(dist, dim, route, k)
    visited = zeros(Int32, dim)
    next = rand(1:dim)
    visited[next] = 1
    route[1] = next
    for i in 2:dim
        index = findNext(visited, dist[next, :], k)
        next = index
        route[i] = next
        visited[next] = 1
    end
    cost = getCost(route, dist)
    return route, cost
end


""" getCost(route, dist) -> totalDist

Calcula la longitud total de un recorrido cerrado representado por `route`.
Asume que el recorrido retorna a la ciudad 1 al final.
"""
function getCost(route, dist)
    totalDist = 0
    for i in 1:length(route)-1
        totalDist += dist[route[i], route[i+1]]
    end
    totalDist += dist[route[length(route)], 1] # closed circle
    return totalDist
end



#local search
""" getCandidate(route) -> candidate
Genera un candidato vecino seleccionando dos índices aleatorios i<=j y
revirtiendo el subsegmento route[i:j]. Es un movimiento tipo 2-opt (inversión
de segmento).
"""
function getCandidate(route)
    candidate = copy(route)
    i = rand(1:length(candidate))
    j = rand(1:length(candidate))
    if i > j
        i, j = j, i
    end
    candidate[i:j] = reverse(candidate[i:j])
    return candidate
end

""" Local_search(dist, route, time_limit_sec) -> (route_optimal, minCost)

Realiza una búsqueda local aleatorizada usando inversiones de subsegmentos
durante hasta `time_limit_sec` segundos. Devuelve la mejor solución local
encontrada y su coste.
"""
function Local_search(dist, route, time_limit_sec::Real)
    count = 0
    route_optimal = copy(route)
    minCost = getCost(route, dist)
    startTime = time_ns()
    while round((time_ns() - startTime) / 1e9, digits=3) < float(time_limit_sec)
        candidate_route = getCandidate(route_optimal)
        cost_local = getCost(candidate_route, dist)
        if cost_local < minCost
            route_optimal = copy(candidate_route)
            minCost = cost_local
            count = 0
        else
            count += 1
        end
    end
    return route_optimal, minCost
end

""" TSP_Solver(filename)

Controlador principal del solver GRASP. Ejecuta iterativamente una fase de
construcción GRASP seguida de búsqueda local hasta alcanzar el límite de
tiempo global (60 segundos).

Imprime el mejor recorrido y su costo encontrados.
"""
function TSP_Solver(filename, k::Int=3, time_limit::Int=60, local_time_limit::Real=3.0)
    # prepare data
    coord, dim = readInstance(filename)
    dist = getDistanceMatrix(coord, dim)
    startTime = time_ns()

    # initial solution
    initroute = findPathGreedy(dist)
    greedy_solution = getCost(initroute, dist)
    final_route, final_solution = GRASP_findRoute(dist, dim, initroute, k)

    # repeat until time limit
    while round((time_ns() - startTime) / 1e9, digits=3) < time_limit
        # Construction phase (GRASP)
        route, cost = GRASP_findRoute(dist, dim, final_route, k)

        # Local search phase
    local_route, local_cost = Local_search(dist, route, local_time_limit)

        if local_cost < final_solution
            final_solution = local_cost
            final_route = local_route
            println(final_solution)
        end
    end
    println("Ruta final: ", final_route)
    println("Solución: ", final_solution)
end

# parameters record
#01 set
#   GRASP_findRoute(dist, dim, final_route, 3)
#   Local_search(dist, route, 10)
#   time 60s

# parse CLI flags: --k=NUM, --time=NUM, --local-time=NUM, --seed=NUM
function parse_cli_args(args)
    tspfile = "./data/bier127.tsp"
    k = 3
    time_limit = 60
    local_time_limit = 3.0
    seed = nothing
    for a in args
        if startswith(a, "--k=")
            k = tryparse(Int, split(a, "=")[2]) === nothing ? 3 : parse(Int, split(a, "=")[2])
        elseif startswith(a, "--time=")
            time_limit = tryparse(Int, split(a, "=")[2]) === nothing ? 60 : parse(Int, split(a, "=")[2])
        elseif startswith(a, "--local-time=")
            local_time_limit = tryparse(Float64, split(a, "=")[2]) === nothing ? 3.0 : parse(Float64, split(a, "=")[2])
        elseif startswith(a, "--seed=")
            seed = tryparse(Int, split(a, "=")[2])
        elseif startswith(a, "-")
            # unknown flag: ignore or extend later
        else
            # positional argument: tsp file (first one wins)
            if tspfile == "./data/bier127.tsp"
                tspfile = a
            end
        end
    end
    return tspfile, k, time_limit, local_time_limit, seed
end

if abspath(PROGRAM_FILE) == @__FILE__
    tspfile, k, time_limit, local_time_limit, seed = parse_cli_args(ARGS)

    # seed default: milliseconds since epoch mod 2^31-1
    if seed === nothing
        ms = round(Int, time() * 1000)
        seed = Int(mod(ms, 2^31 - 1))
    end
    Random.seed!(seed)
    println("Usando seed = $seed")

    println("Ejecutando TSP_Solver(file=$(tspfile), k=$(k), time_limit=$(time_limit)s, local_time_limit=$(local_time_limit)s)")
    elapsed_time = @elapsed begin
        TSP_Solver(tspfile, k, time_limit, local_time_limit)
    end
    println("Tiempo de ejecución: $elapsed_time segundos")
end