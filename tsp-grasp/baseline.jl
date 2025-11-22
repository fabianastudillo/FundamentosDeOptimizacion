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
        # Intentar resolver exactamente con TravelingSalesmanExact. Si el
        # optimizador no consigue eliminar todos los subtours (caso observado
        # con GLPK en algunas instancias pequeñas), se reintentará activando
        # lazy constraints; si vuelve a fallar, se sugiere o ejecuta la
        # alternativa heurística (GRASP) como fallback.
        function try_exact(points, tspfile)
            try
                # intento rápido sin warmstart
                get_optimal_tour(points; verbose=false, heuristic_warmstart=false)
                @time get_optimal_tour(points; verbose=false, heuristic_warmstart=false)
                return true
            catch e
                msg = sprint(showerror, e)
                @warn "Error en solución exacta: $msg"
                if occursin("subtour", lowercase(msg)) || occursin("subtours", lowercase(msg))
                    @info "Intentando reintento con lazy_constraints=true (más robusto pero más lento)"
                    try
                        get_optimal_tour(points; verbose=true, lazy_constraints=true, heuristic_warmstart=false)
                        return true
                    catch e2
                        msg2 = sprint(showerror, e2)
                        @error "Reintento con lazy_constraints falló: $msg2"
                        # Fallback: sugerir uso de heurística o ejecutar el GRASP localmente
                        println("Fallo la resolución exacta. Ejecutando GRASP heurístico como fallback...")
                        try
                            run(`julia tsp-grasp/TSP_GRASP_Solver.jl $tspfile --time=60 --local-time=3 --k=3`)
                        catch runerr
                            println("No se pudo ejecutar el solver heurístico automáticamente. Ejecuta: julia tsp-grasp/TSP_GRASP_Solver.jl $tspfile")
                        end
                        return false
                    end
                else
                    rethrow(e)
                end
            end
        end

        try_exact(points, tsp_path)
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