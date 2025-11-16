#!/usr/bin/env julia
################################################################################
# Animación del método del gradiente en 3D usando CairoMakie:
#   f(x,y) = xy + 4y - 3x^2 - y^2
#
# Muestra cómo el algoritmo de ascenso por gradiente encuentra el máximo
#
# Requisitos:
#  - CairoMakie.jl (backend vectorial de alta calidad)
#
# Uso:
#   julia examples/graficar3d-ejemplo4-animacion.jl
#
# Salida:
#   - examples/graficar3d-ejemplo4-animacion.gif (animación)
################################################################################

using CairoMakie

# Función objetivo
f(x, y) = x*y + 4*y - 3*x^2 - y^2

# Gradiente de f (para ascenso al máximo)
∇f_x(x, y) = y - 6*x
∇f_y(x, y) = x + 4 - 2*y

# Parámetros del algoritmo de ascenso por gradiente
learning_rate = 0.05
epsilon = 1e-6
max_iterations = 100

# Punto inicial
x_start = -2.0
y_start = -2.0

# Algoritmo de ascenso por gradiente (guardando historia)
history_x = Float64[x_start]
history_y = Float64[y_start]
history_z = Float64[f(x_start, y_start)]

x_current = x_start
y_current = y_start
iteration = 0

println("Ejecutando ascenso por gradiente...")
println("=" ^ 60)

while iteration < max_iterations
    global x_current, y_current, iteration
    
    # Calcular gradiente
    grad_x = ∇f_x(x_current, y_current)
    grad_y = ∇f_y(x_current, y_current)
    grad_norm = sqrt(grad_x^2 + grad_y^2)
    
    # Verificar convergencia
    if grad_norm < epsilon
        println("Convergencia alcanzada en iteración $iteration")
        println("Norma del gradiente: $grad_norm")
        break
    end
    
    # Actualizar posición (ascenso = suma del gradiente)
    x_new = x_current + learning_rate * grad_x
    y_new = y_current + learning_rate * grad_y
    z_new = f(x_new, y_new)
    
    # Guardar en historia
    push!(history_x, x_new)
    push!(history_y, y_new)
    push!(history_z, z_new)
    
    # Actualizar posición actual
    x_current = x_new
    y_current = y_new
    iteration += 1
    
    if iteration % 10 == 0
        println("Iteración $iteration: ($(round(x_current, digits=4)), $(round(y_current, digits=4))) → f = $(round(z_new, digits=4))")
    end
end

println("=" ^ 60)
println("Punto final: ($(round(x_current, digits=6)), $(round(y_current, digits=6)))")
println("Valor de f: $(round(f(x_current, y_current), digits=6))")
println("Total de iteraciones: $(length(history_x) - 1)")
println()

# Preparar datos para la superficie
n = 100
x_range = range(-2, 3, length=n)
y_range = range(-2, 5, length=n)
Z = [f(x, y) for y in y_range, x in x_range]

# Configurar tema
set_theme!(Theme(
    fonts = (regular = "Latin Modern Roman", bold = "Latin Modern Roman Bold"),
    fontsize = 22,
    Axis = (xlabelsize = 24, ylabelsize = 24, titlesize = 28)
))

println("Generando animación...")

# Crear figura base
fig = Figure(size = (1200, 1000))

# Crear animación frame por frame
record(fig, "examples/graficar3d-ejemplo5-animacion.gif", 1:length(history_x), framerate=5) do i
    # Limpiar figura
    empty!(fig)
    
    ax = Axis3(fig[1, 1],
               xlabel = "x",
               ylabel = "y",
               zlabel = "z",
               title = L"f(x,y) = xy + 4y - 3x^2 - y^2" * "\nIteración: $(i-1)",
               aspect = (1, 1, 0.5),
               azimuth = 1.2π,
               elevation = 0.15π,
               limits = ((-2, 3), (-2, 5), (-30, 8)),
               perspectiveness = 0.5,
               titlesize = 28,
               titlegap = 15)
    
    # Dibujar superficie
    surface!(ax, x_range, y_range, Z,
             colormap = :viridis,
             transparency = true,
             alpha = 0.85,
             shading = Makie.MultiLightShading,
             colorrange = (-4, 8))
    
    # Wireframe
    wireframe!(ax, x_range, y_range, Z,
               color = (:white, 0.1),
               linewidth = 0.5,
               overdraw = true)
    
    # Dibujar trayectoria hasta la iteración actual
    if i > 1
        lines!(ax, history_x[1:i], history_y[1:i], history_z[1:i],
               color = :red,
               linewidth = 3,
               label = "Trayectoria")
        
        # Puntos intermedios
        scatter!(ax, history_x[1:i-1], history_y[1:i-1], history_z[1:i-1],
                 color = :orange,
                 markersize = 8,
                 alpha = 0.6)
    end
    
    # Punto inicial
    scatter!(ax, [history_x[1]], [history_y[1]], [history_z[1]],
             color = :green,
             markersize = 15,
             marker = :circle,
             label = "Inicio")
    
    # Punto actual
    scatter!(ax, [history_x[i]], [history_y[i]], [history_z[i]],
             color = :red,
             markersize = 20,
             marker = :star5,
             label = "Actual")
    
    # Vector gradiente en el punto actual (si no es el primero)
    if i > 1
        grad_x = ∇f_x(history_x[i], history_y[i])
        grad_y = ∇f_y(history_x[i], history_y[i])
        grad_scale = 0.3  # Escala del vector para visualización
        
        arrows!(ax,
                [history_x[i]], [history_y[i]], [history_z[i]],
                [grad_x * grad_scale], [grad_y * grad_scale], [0.0],
                color = :blue,
                linewidth = 3,
                arrowsize = Vec3f(0.15, 0.15, 0.2))
    end
    
    # Barra de color
    Colorbar(fig[1, 2],
             limits = (-4, 8),
             colormap = :viridis,
             label = "f(x,y)",
             labelsize = 22,
             ticklabelsize = 18,
             width = 25)
end

println("✓ Animación guardada en: examples/graficar3d-ejemplo5-animacion.gif")
println()
println()