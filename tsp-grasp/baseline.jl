# baseline.jl
#
# Propósito:
#   Ejemplo de uso del paquete TravelingSalesmanExact para resolver instancias
#   TSP (Traveling Salesman Problem) con el optimizador GLPK. Este script
#   carga puntos desde un archivo TSP, e intenta resolver el problema de forma
#   exacta mediante un modelo ILP usando el paquete `TravelingSalesmanExact`.
#   El resultado y tiempo de ejecución dependen del optimizador y de las
#   opciones (p. ej. warm-starts o lazy constraints). Para instancias grandes
#   o cuando se usan heurísticos (por ejemplo GRASP), los heurísticos pueden
#   encontrar soluciones de mejor calidad más rápidamente.
#
# Dependencias:
#   - TravelingSalesmanExact
#   - GLPK
#
# Instrucción de instalación (si no tiene el paquete):
#   Abra REPL de Julia o ponga estas líneas al inicio de un REPL/script:
#
#   import Pkg
#   Pkg.add("TravelingSalesmanExact")
#   Pkg.add("GLPK")
#
# Uso:
#   julia tsp-grasp/baseline.jl
#
# Nota: este archivo ya fue modificado por:
#   Fabian Astudillo <fabian.astudillos@ucuenca.edu.ec>

# Modified by: Fabian Astudillo <fabian.astudillos@ucuenca.edu.ec>

using TravelingSalesmanExact, GLPK

function main(tsp_path::String)
    elapsed_time = @elapsed begin
        points = simple_parse_tsp(tsp_path)
        set_default_optimizer!(GLPK.Optimizer)

        # compile run
        # Si el optimizador no soporta 'warm start' (p. ej. GLPK), desactivar
        # el heuristic_warmstart para evitar errores relacionados con
        # MathOptInterface.VariablePrimalStart.
        get_optimal_tour(points; verbose=false, heuristic_warmstart=false)

        @time get_optimal_tour(points; verbose=false, heuristic_warmstart=false)
        println("Ruta final: ", points)

        final_solution = 0.0
        for i in 1:length(points)-1
            println(points[i])
            println(points[i+1])
            final_solution += TravelingSalesmanExact.euclidean_distance(points[i], points[i+1])
        end

        println("Solución: ", final_solution)
    end
    println("Tiempo de ejecución: $elapsed_time segundos")
end

# When run as a script, accept the TSP filename as first argument.
if abspath(PROGRAM_FILE) == @__FILE__
    tspfile = length(ARGS) > 0 ? ARGS[1] : "./data/bier127.tsp"
    main(tspfile)
end