# Definimos la función (función objetivo)
f(x) = x^2

# Definimos la derivada parcial respecto a x
df_dx(x) = 2x

# Configuración de parámetros
learning_rate = 0.1
initial_point = 10.0 # Punto inicial para la optimización
epsilon = 1e-6  # Criterio de parada

# Bucle de optimización (Descenso de Gradiente)
x_current = initial_point
x_history = [x_current]
iteration = 0
error = Inf  # Inicializar el error como infinito

while error >= epsilon
    global x_current, iteration, error  # Declarar como global para evitar problemas de scope
    iteration += 1
    gradient = df_dx(x_current)
    x_temp = x_current
    x_current = x_current - learning_rate * gradient
    error = abs(x_temp - x_current)
    
    println("Iteración $iteration: x = $x_current, gradiente = $gradient, error = $error")
    push!(x_history, x_current)
end

println("\n✓ Convergencia alcanzada en iteración $iteration (error = $error < ε = $epsilon)")

# Visualización usando Plots.jl
using Plots

# Rango para dibujar la función
x_range = -10.0:0.1:10.0
y_values = f.(x_range)

# Dibujamos la función
p = plot(x_range, y_values, label="f(x) = x^2", xlabel="x", ylabel="f(x)", title="Optimización por Descenso de Gradiente", legend=:topright)

# Añadimos los puntos del historial de optimización
scatter!(p, x_history, f.(x_history), label="Recorrido del optimizador", markersize=4, markercolor=:red)

# Opcional: mostrar el punto final
scatter!(p, [x_history[end]], [f(x_history[end])], label="Punto Final", markersize=6, markercolor=:blue, shape=:star)

# Guardar el plot en PNG
savefig(p, "examples/gradiente_x2.png")
println("✓ Figura guardada en: examples/gradiente_x2.png")