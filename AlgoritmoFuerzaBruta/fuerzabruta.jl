using DelimitedFiles
using Combinatorics

elapsed_time = @elapsed begin
#distancias_ciudades = "matriz-7ciudades.csv"
#distancias_ciudades = "matriz-8ciudades.txt"
#distancias_ciudades = "matriz-9ciudades.txt"
#distancias_ciudades = "matriz-10ciudades.txt"
#distancias_ciudades = "matriz-11ciudades.txt"
distancias_ciudades = "matriz-13ciudades.txt"
#distancias_ciudades = "tsp_p01_d.txt"
ciudad_data = readdlm(distancias_ciudades, ';', header=false)
n=size(ciudad_data)
cols=n[1]
rows=n[2]

mejor_camino=[]

mejor_distancia=10000000

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
        println(distancia_actual)
        println(mejor_camino)
    end
end
end
println("Tiempo de ejecución: $elapsed_time segundos")
