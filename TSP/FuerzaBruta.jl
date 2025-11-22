################################################################################
# Fuerza Bruta para TSP (archivo de script)
#
# Propósito:
#  - Calcular el recorrido de mínima distancia visitando todas las ciudades
#    (problema del viajante) usando fuerza bruta (permutaciones de nodos).
#
# Entrada esperada:
#  - Una matriz de distancias leída desde un archivo con separador ';'.
#    En este repositorio se usan varios archivos de ejemplo en
#    `AlgoritmoFuerzaBruta/` (comentados más abajo).
#
# Formato de la matriz:
#  - Cada fila representa distancias desde una ciudad a las otras.
#  - Un valor 0 indica "sin enlace" entre dos nodos. El script actual
#    asume que la matriz contiene distancias numéricas; si 0 significa
#    inexistencia de enlace, hay que validar o sustituir esos ceros antes
#    de usar fuerza bruta (ver notas al final).
#
# Nota importante:
#  - El recorrido construido por este script fija el nodo inicial y final en 1.
#    Cada permutación se evalúa como `[1; permutación; 1]`.
#
# Salida:
#  - Imprime (por pantalla) la mejor distancia encontrada y el camino
#    correspondiente. También muestra tiempos de ejecución.
#
# Requisitos:
#  - Julia 1.6+ (recomendado 1.10+)
#  - Paquetes: DelimitedFiles (estándar), Combinatorics
#
# Ejemplo de uso (desde el directorio raíz del repo):
#  julia AlgoritmoFuerzaBruta/fuerzabruta.jl [ruta_a_archivo]
#
# Nota: el primer parámetro de línea de comandos, si se proporciona, se interpreta
# como la ruta al archivo que contiene la matriz de distancias. Si no se pasa,
# se usa por defecto `AlgoritmoFuerzaBruta/matriz-8ciudades.txt`.
#
# Notas de mantenimiento / mejoras sugeridas:
#  - Reemplazar `println` por `Logging` para mayor control.
#  - Extraer la lógica de evaluación de caminos en funciones reutilizables.
#  - Manejar explícitamente valores 0 como "no enlace" y saltar rutas
#    que usen arcos inexistentes o asignar coste infinito (Inf).
#  - Añadir tests unitarios para la función que calcula la distancia total.
################################################################################

using DelimitedFiles
using Combinatorics
using Logging

"""
    main()

Ejecuta la búsqueda por fuerza bruta para el TSP.
Argumentos:
 - ARGS[1] (opcional): ruta al archivo que contiene la matriz de distancias
                      (separador `;`). Si no se proporciona se usa un archivo
                      por defecto relativo al repositorio.
Notas:
 - El nodo inicial/final está fijado en 1; cada permutación se evalúa como
   `[1; permutación; 1]`.
"""
function main()
    default_file = joinpath(@__DIR__, "../AlgoritmoFuerzaBruta/matriz-8ciudades.txt")
    distancias_ciudades = length(ARGS) >= 1 ? ARGS[1] : default_file
    if !isfile(distancias_ciudades)
        @error "Archivo de distancias no encontrado" archivo=distancias_ciudades
        return
    end
    @info "Usando archivo de distancias" archivo=distancias_ciudades

    ciudad_data = readdlm(distancias_ciudades, ';', header=false)
    n = size(ciudad_data)
    cols = n[1]
    rows = n[2]

    mejor_camino = []
    mejor_distancia = Inf

    elapsed_time = @elapsed begin
        for path in collect(permutations(2:cols, cols-1))
            path = [1; path; 1]
            n1 = size(path)
            distancia_actual = 0.0
            for j in 1:n1[1]-1
                distancia_actual += ciudad_data[path[j], path[j+1]]
            end
            if distancia_actual < mejor_distancia
                mejor_camino = copy(path)
                mejor_distancia = distancia_actual
                @info "Nueva mejor distancia" distancia=distancia_actual
                @info "Mejor camino" camino=mejor_camino
            end
        end
    end

    @info "Tiempo de ejecución" segundos=elapsed_time
    println("Recorrido final: ", join(mejor_camino, " → "))
    println("Distancia total: ", mejor_distancia)
end

if abspath(PROGRAM_FILE) == @__FILE__
    global_logger(SimpleLogger(stderr, Logging.Info))
    main()
end