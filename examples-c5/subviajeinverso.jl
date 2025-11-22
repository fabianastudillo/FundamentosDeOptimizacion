#!/usr/bin/env julia
################################################################################
# Animación del Algoritmo de Subviaje Inverso (2-opt)
# Problema del Viajante de Comercio (TSP)
#
# Visualiza cómo el algoritmo 2-opt mejora iterativamente el recorrido
# reemplazando arcos ineficientes por combinaciones mejor
#
# Requisitos:
#  - CairoMakie.jl
#  - Random.jl (incluido en Julia)
################################################################################

using CairoMakie, Random

# Matriz de distancias
A = [
    1000  12    10    1000  1000  1000  12;
      12 1000   8      12   1000  1000 1000;
      10   8   1000     11     3  1000   9;
    1000  12    11    1000    11    10 1000;
    1000 1000    3      11   1000     6   7;
    1000 1000  1000     10     6  1000   9;
      12 1000    9    1000     7     9 1000
]

# Umbral que indica "sin enlace" (valor grande en la matriz)
const NO_LINK_THRESHOLD = 1000.0


# Coordenadas de ciudades (distribuidas en círculo para visualización)
n_cities = 7
angles = range(0, 2π, length=n_cities+1)[1:n_cities]
coords = [(cos(angle), sin(angle)) for angle in angles]

println("=" ^ 70)
println("ALGORITMO DE SUBVIAJE INVERSO (2-OPT)")
println("=" ^ 70)
println("Ciudades: 1, 2, 3, 4, 5, 6, 7")
println("Recorrido inicial: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 1")
println()
println("Usando matriz de distancias A:")
println(A)
println()

# Función para calcular distancia total de un recorrido
function calculate_distance(tour, dist_matrix)
    total = 0.0
    for i in 1:length(tour)
        current = tour[i]
        next = tour[i % length(tour) + 1]
        d = dist_matrix[current, next]
        # Si hay un arco inexistente, considerar la distancia como infinita
        if d >= NO_LINK_THRESHOLD
            return Inf
        end
        total += d
    end
    return total
end

function format_distance(d)
    if d === Inf || isnan(d)
        return "Inf"
    else
        return string(round(d, digits=2))
    end
end

# Función para aplicar 2-opt (invertir un segmento)
function two_opt_move(tour, i, k)
    """Invierte el segmento del tour entre posiciones i y k"""
    new_tour = copy(tour)
    new_tour[i:k] = reverse(new_tour[i:k])
    return new_tour
end

# Inicio de bloque local para evitar advertencias de scope en scripts
let

# Recorrido inicial
tour = [1, 2, 3, 4, 5, 6, 7]
initial_distance = calculate_distance(tour, A)
tour_history = [copy(tour)]
distance_history = [initial_distance]
improvement_history = [0.0]

println("Recorrido inicial: $(join(tour, " → ")) → 1")
println("Distancia inicial: $(format_distance(initial_distance))")
println()
println("Ejecutando algoritmo 2-opt...")
println("-" ^ 70)

# Algoritmo 2-opt: invertir segmentos contiguos de nodos 2..n
global iteration = 0
max_iterations = 50
n = length(tour)
global improved = true

while improved && iteration < max_iterations
    iteration += 1
    improved = false
    current_distance = calculate_distance(tour, A)

    # recorrer longitudes de segmento desde 2 hasta n-1 (excluyendo el nodo 1)
    for L in 2:(n-1)
        best_distance_L = Inf
        best_tour_L = nothing
        best_start_L = nothing

        # ventanas que comienzan en posiciones 2..(n-L+1)
        for i in 2:(n - L + 1)
            k = i + L - 1
            candidate = two_opt_move(tour, i, k)
            cand_dist = calculate_distance(candidate, A)

            if cand_dist < best_distance_L
                best_distance_L = cand_dist
                best_tour_L = candidate
                best_start_L = i
            end
        end

        # si la mejor inversión para esta L mejora la solución actual, aplicarla
        if best_distance_L < current_distance
            improvement = current_distance - best_distance_L
            println("Iteración $iteration: Reversión de longitud $L empezando en posición $best_start_L (ciudades $(tour[best_start_L]) a $(tour[best_start_L + L - 1]))")
            println("  Distancia anterior: $(format_distance(current_distance))")
            println("  Distancia nueva: $(format_distance(best_distance_L))")
            println("  Mejora: $(round(improvement, digits=2))")
            println()

            tour = best_tour_L
            push!(tour_history, copy(tour))
            push!(distance_history, best_distance_L)
            push!(improvement_history, improvement)

            # actualizar la distancia actual para considerar siguientes L en este pase
            current_distance = best_distance_L
            improved = true
        end
    end
end

println("-" ^ 70)
println("Recorrido final: $(join(tour, " → ")) → 1")
println("Distancia final: $(distance_history[end])")
println("Mejora total: $(initial_distance - distance_history[end])")
println("Mejora porcentual: $(round(100 * (initial_distance - distance_history[end]) / initial_distance, digits=2))%")
println("Total de iteraciones: $(length(tour_history) - 1)")
println()
 

# Configurar tema
set_theme!(Theme(
    fonts = (regular = "Latin Modern Roman", bold = "Latin Modern Roman Bold"),
    fontsize = 18,
    Axis = (xlabelsize = 20, ylabelsize = 20, titlesize = 24)
))

println("Generando animación...")

# Función para dibujar el tour
function draw_tour(ax, tour, coords, dist_matrix, iteration_num, distance, improvement)
    # Limpiar eje
    empty!(ax)
    
    # Crear nuevo eje
    ax = Axis(ax.figure[1, 1],
              xlabel = "X",
              ylabel = "Y",
              title = "Algoritmo 2-opt (Subviaje Inverso)\nIteración: $iteration_num | Distancia: $(round(distance, digits=2))",
              aspect = DataAspect(),
              limits = (-1.5, 1.5, -1.5, 1.5))
    
    # Dibujar arcos del tour
    for i in 1:length(tour)
        current = tour[i]
        next = tour[i % length(tour) + 1]
        
        x_start, y_start = coords[current]
        x_end, y_end = coords[next]
        
        lines!(ax, [x_start, x_end], [y_start, y_end],
               color = :blue,
               linewidth = 2.5,
               alpha = 0.7)
        
        # Flecha de dirección
        dx = (x_end - x_start) * 0.8
        dy = (y_end - y_start) * 0.8
        arrows!(ax, [x_start], [y_start], [dx], [dy],
               color = :blue,
               linewidth = 2,
               arrowsize = 15)
    end
    
    # Dibujar ciudades
    city_numbers = 1:length(coords)
    xs = [coords[i][1] for i in city_numbers]
    ys = [coords[i][2] for i in city_numbers]
    
    scatter!(ax, xs, ys,
            color = :red,
            markersize = 20,
            strokecolor = :darkred,
            strokewidth = 2)
    
    # Etiquetar ciudades
    for (i, (x, y)) in enumerate(coords)
        text!(ax, x, y,
             text = string(i),
             fontsize = 16,
             align = (:center, :center),
             color = :white,
             font = :bold)
    end
    
    # Mostrar información de mejora
    if iteration_num > 0 && improvement > 0
        text!(ax, -1.3, 1.2,
             text = "Mejora: $(round(improvement, digits=2))",
             fontsize = 16,
             color = :green,
             font = :bold)
    end
    
    ax
end

# Crear figura base
fig = Figure(size = (1000, 1000))

# Generar animación
record(fig, "examples-c5/subviajeinverso-animacion.gif", 
       1:length(tour_history), 
       framerate = 1) do frame_num
    
    empty!(fig)
    
    ax = Axis(fig[1, 1],
              xlabel = "X",
              ylabel = "Y",
              title = "Algoritmo 2-opt (Subviaje Inverso)\nIteración: $(frame_num-1) | Distancia: $(round(distance_history[frame_num], digits=2))",
              aspect = DataAspect(),
              limits = (-1.5, 1.5, -1.5, 1.5),
              xlabelsize = 20,
              ylabelsize = 20,
              titlesize = 22)
    
    tour = tour_history[frame_num]
    distance = distance_history[frame_num]
    improvement = improvement_history[frame_num]
    
    # Si no es el primer frame, mostrar los enlaces punteados que se van a cambiar
    if frame_num > 1
        tour_anterior = tour_history[frame_num - 1]
        
        # Encontrar qué cambió (comparar tours)
        # Dibujar el tour anterior en gris claro con flechas
        for i in 1:length(tour_anterior)
            current = tour_anterior[i]
            next = tour_anterior[i % length(tour_anterior) + 1]
            
            x_start, y_start = coords[current]
            x_end, y_end = coords[next]
            
            lines!(ax, [x_start, x_end], [y_start, y_end],
                   color = (:lightgray, 0.5),
                   linewidth = 2,
                   alpha = 0.4,
                   linestyle = :dot)
        end
        
        # Mostrar los enlaces punteados que se van a reemplazar
        # Comparar los dos tours para encontrar los cambios
        for i in 1:length(tour_anterior)
            current_ant = tour_anterior[i]
            next_ant = tour_anterior[i % length(tour_anterior) + 1]
            
            # Verificar si este enlace cambió en el nuevo tour
            edge_exists = false
            for j in 1:length(tour)
                current_new = tour[j]
                next_new = tour[j % length(tour) + 1]
                
                if (current_ant == current_new && next_ant == next_new) ||
                   (current_ant == next_new && next_ant == current_new)
                    edge_exists = true
                    break
                end
            end
            
            # Si el enlace desaparece, dibujarlo en rojo punteado (será eliminado)
            if !edge_exists
                x_start, y_start = coords[current_ant]
                x_end, y_end = coords[next_ant]
                
                lines!(ax, [x_start, x_end], [y_start, y_end],
                       color = :red,
                       linewidth = 3,
                       alpha = 0.8,
                       linestyle = :dash,
                       label = frame_num == 2 ? "Enlaces a eliminar" : "")
                
             # Agregar distancia en el medio del enlace
             dist = A[current_ant, next_ant]
                x_mid = (x_start + x_end) / 2
                y_mid = (y_start + y_end) / 2
             lbl = dist >= NO_LINK_THRESHOLD ? "X" : string(Int(dist))
             text!(ax, x_mid, y_mid,
                 text = lbl,
                 fontsize = 16,
                 color = :red,
                 font = :bold,
                 align = (:center, :center),
                 offset = (8, 8))
            end
        end
        
        # Mostrar los enlaces nuevos en verde punteado (serán agregados)
        for i in 1:length(tour)
            current_new = tour[i]
            next_new = tour[i % length(tour) + 1]
            
            # Verificar si este enlace es nuevo
            edge_exists = false
            for j in 1:length(tour_anterior)
                current_ant = tour_anterior[j]
                next_ant = tour_anterior[j % length(tour_anterior) + 1]
                
                if (current_new == current_ant && next_new == next_ant) ||
                   (current_new == next_ant && next_new == current_ant)
                    edge_exists = true
                    break
                end
            end
            
            # Si el enlace es nuevo, dibujarlo en verde punteado
            if !edge_exists
                x_start, y_start = coords[current_new]
                x_end, y_end = coords[next_new]
                
                lines!(ax, [x_start, x_end], [y_start, y_end],
                       color = :green,
                       linewidth = 3,
                       alpha = 0.8,
                       linestyle = :dash,
                       label = frame_num == 2 ? "Enlaces a agregar" : "")
                
             # Agregar distancia en el medio del enlace
             dist = A[current_new, next_new]
                x_mid = (x_start + x_end) / 2
                y_mid = (y_start + y_end) / 2
             lbl = dist >= NO_LINK_THRESHOLD ? "X" : string(Int(dist))
             text!(ax, x_mid, y_mid,
                 text = lbl,
                 fontsize = 16,
                 color = :green,
                 font = :bold,
                 align = (:center, :center),
                 offset = (-8, -8))
            end
        end
    end
    
    # Dibujar arcos del tour actual
    for i in 1:length(tour)
        current = tour[i]
        next = tour[i % length(tour) + 1]
        
        x_start, y_start = coords[current]
        x_end, y_end = coords[next]
        
     dist = A[current, next]
     if dist >= NO_LINK_THRESHOLD
         # arco inexistente: dibujar punteado rojo tenue
         lines!(ax, [x_start, x_end], [y_start, y_end],
             color = :red,
             linewidth = 2,
             alpha = 0.4,
             linestyle = :dash)
     else
         lines!(ax, [x_start, x_end], [y_start, y_end],
             color = :blue,
             linewidth = 3,
             alpha = 0.8)
     end
        
        # Flecha de dirección
        dx = (x_end - x_start) * 0.75
        dy = (y_end - y_start) * 0.75
        arrows!(ax, [x_start], [y_start], [dx], [dy],
               color = :blue,
               linewidth = 2.5,
               arrowsize = 18)
        
       # Agregar distancia en el medio del enlace
       dist = A[current, next]
       x_mid = (x_start + x_end) / 2
       y_mid = (y_start + y_end) / 2
       lbl = dist >= NO_LINK_THRESHOLD ? "X" : string(Int(dist))
       text!(ax, x_mid, y_mid,
           text = lbl,
           fontsize = 16,
           color = :darkblue,
           font = :bold,
           align = (:center, :center))
    end
    
    # Dibujar ciudades
    city_numbers = 1:length(coords)
    xs = [coords[i][1] for i in city_numbers]
    ys = [coords[i][2] for i in city_numbers]
    
    scatter!(ax, xs, ys,
            color = :red,
            markersize = 22,
            strokecolor = :darkred,
            strokewidth = 2.5)
    
    # Etiquetar ciudades
    for (i, (x, y)) in enumerate(coords)
        text!(ax, x, y,
             text = string(i),
             fontsize = 16,
             align = (:center, :center),
             color = :white,
             font = :bold)
    end
    
    # Mostrar información de mejora
    if frame_num > 1 && improvement > 0
        text!(ax, -1.3, 1.25,
             text = "Mejora: $(round(improvement, digits=2))",
             fontsize = 16,
             color = :green,
             font = :bold,
             align = (:left, :top))
    end
    
    # Mostrar distancia total
    text!(ax, 1.3, -1.35,
         text = "Distancia total: $(round(distance, digits=2))",
         fontsize = 16,
         color = :darkblue,
         font = :bold,
         align = (:right, :bottom))
end

println("✓ Animación guardada en: examples-c5/subviajeinverso-animacion.gif")
println()
println("=" ^ 70)
println("RESUMEN DEL ALGORITMO")
println("=" ^ 70)
println("Distancia inicial: $initial_distance")
println("Distancia final: $(distance_history[end])")
println("Mejora total: $(initial_distance - distance_history[end])")
println("Mejora porcentual: $(round(100 * (initial_distance - distance_history[end]) / initial_distance, digits=2))%")
println("Número de iteraciones: $(length(tour_history) - 1)")
end
println()
