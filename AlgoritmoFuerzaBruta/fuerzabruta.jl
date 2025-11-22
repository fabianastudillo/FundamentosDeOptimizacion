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
# Salida:
#  - Imprime (por pantalla) la mejor distancia encontrada y el camino
#    correspondiente. También muestra tiempos de ejecución.
#
# Requisitos:
#  - Julia 1.6+ (recomendado 1.10+)
#  - Paquetes: DelimitedFiles (estándar), Combinatorics
#
# Ejemplo de uso (desde el directorio raíz del repo):
#  julia AlgoritmoFuerzaBruta/fuerzabruta.jl
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

#distancias_ciudades = "AlgoritmoFuerzaBruta/matriz-7ciudades.csv"
distancias_ciudades = "AlgoritmoFuerzaBruta/matriz-8ciudades.txt"
#distancias_ciudades = "AlgoritmoFuerzaBruta/matriz-9ciudades.txt"
#distancias_ciudades = "AlgoritmoFuerzaBruta/matriz-10ciudades.txt"
#distancias_ciudades = "AlgoritmoFuerzaBruta/matriz-11ciudades.txt"
#distancias_ciudades = "AlgoritmoFuerzaBruta/matriz-13ciudades.txt"
#distancias_ciudades = "AlgoritmoFuerzaBruta/tsp_p01_d.txt"
#distancias_ciudades = "AlgoritmoFuerzaBruta/SienaBldgs.txt"

ciudad_data = readdlm(distancias_ciudades, ';', header=false)
n=size(ciudad_data)
cols=n[1]
rows=n[2]

mejor_camino=[]

mejor_distancia=10000000

elapsed_time = @elapsed begin
    for path in collect(permutations(2:cols,cols-1))
        #pushfirst!(path,1)
        #push!(path,1)
        path=[1; path; 1]
        n1=size(path)
        distancia_actual=0
        for j in 1:n1[1]-1
            distancia_actual+=ciudad_data[path[j],path[j+1]]
        end
        if (distancia_actual<mejor_distancia)
            global mejor_camino=path
            global mejor_distancia=distancia_actual
            @info "Nueva mejor distancia" distancia=distancia_actual
            @info "Mejor camino" camino=mejor_camino
        end
    end
end
@info "Tiempo de ejecución" segundos=elapsed_time