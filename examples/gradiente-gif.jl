"""
Optimización por Descenso de Gradiente
=======================================
Ejemplo de minimización de f(x) = x² usando el método del gradiente descendente.

Autor: Dr. Fabián Astudillo Salinas
Curso: Fundamentos de Optimización
"""

using Plots

# ============================================================
# Definición de la función objetivo y su gradiente
# ============================================================

"Función objetivo a minimizar"
f(x) = x^2


"Gradiente de f (derivada primera)"
∇f(x) = 2x

# ============================================================
# Algoritmo de Descenso de Gradiente
# ============================================================

"""
    gradient_descent(f, ∇f, x₀; α=0.1, max_iter=50, tol=1e-6)

Minimiza una función usando el método del gradiente descendente.

# Argumentos
- `f`: función objetivo a minimizar
- `∇f`: gradiente de la función objetivo
- `x₀`: punto inicial
- `α`: tasa de aprendizaje (learning rate)
- `max_iter`: número máximo de iteraciones
- `tol`: tolerancia para criterio de parada

# Retorna
- `x_history`: historial de puntos visitados
- `x_opt`: punto óptimo encontrado
- `f_opt`: valor de la función en el óptimo
"""
function gradient_descent(f, ∇f, x₀; α=0.1, max_iter=50, tol=1e-6)
    x_current = x₀
    x_history = [x_current]
    
    for i in 1:max_iter
        gradient = ∇f(x_current)
        x_new = x_current - α * gradient
        push!(x_history, x_new)
        
        # Criterio de parada: cambio relativo pequeño
        if abs(x_new - x_current) < tol
            println("Convergencia alcanzada en iteración $i")
            break
        end
        
        x_current = x_new
    end
    
    return x_history, x_current, f(x_current)
end

# ============================================================
# Ejecución del algoritmo
# ============================================================

# Parámetros del algoritmo
learning_rate = 0.1
max_iterations = 50
initial_point = 10.0
tolerance = 1e-6

println("="^60)
println("OPTIMIZACIÓN POR DESCENSO DE GRADIENTE")
println("="^60)
println("Función objetivo: f(x) = x²")
println("Punto inicial: x₀ = $initial_point")
println("Tasa de aprendizaje: α = $learning_rate")
println("Máximo de iteraciones: $max_iterations")
println("Tolerancia: $tolerance")
println("="^60)

# Ejecutar el algoritmo
x_history, x_opt, f_opt = gradient_descent(
    f, ∇f, initial_point;
    α=learning_rate,
    max_iter=max_iterations,
    tol=tolerance
)

# Resultados
println("\nResultados:")
println("  Iteraciones realizadas: $(length(x_history) - 1)")
println("  Punto óptimo: x* = $x_opt")
println("  Valor mínimo: f(x*) = $f_opt")
println("  Error absoluto: |x* - 0| = $(abs(x_opt))")

# ============================================================
# Visualización con Animación
# ============================================================

# Rango para graficar la función
x_range = -12.0:0.1:12.0
y_values = f.(x_range)

println("\nGenerando animación...")

# Crear animación frame por frame
anim = @animate for i in 1:length(x_history)
    # Crear gráfica base
    p = plot(
        x_range, y_values,
        label="f(x) = x²",
        xlabel="x",
        ylabel="f(x)",
        title="Optimización por Descenso de Gradiente - Iteración $(i-1)",
        legend=:topright,
        linewidth=2,
        color=:blue,
        size=(800, 600),
        ylim=(-5, maximum(f.(x_history)) + 10)
    )
    
    # Añadir línea del mínimo teórico
    hline!(p, [0.0], label="Mínimo teórico", linestyle=:dash, color=:black, alpha=0.3)
    
    # Marcar el punto inicial
    scatter!(
        p, [x_history[1]], [f(x_history[1])],
        label="Inicio: x₀=$(round(x_history[1], digits=2))",
        markersize=8,
        markercolor=:green,
        markershape=:circle
    )
    
    # Agregar el recorrido hasta la iteración actual
    if i > 1
        plot!(
            p, x_history[1:i], f.(x_history[1:i]),
            label="Trayectoria",
            linewidth=1.5,
            color=:red,
            alpha=0.5,
            linestyle=:dash
        )
        
        scatter!(
            p, x_history[1:i-1], f.(x_history[1:i-1]),
            label="Iteraciones previas",
            markersize=3,
            markercolor=:red,
            alpha=0.4
        )
    end
    
    # Marcar el punto actual con un marcador grande
    scatter!(
        p, [x_history[i]], [f(x_history[i])],
        label="Actual: x=$(round(x_history[i], digits=4))",
        markersize=10,
        markercolor=:gold,
        markershape=:star5
    )
    
    # Añadir información del gradiente
    if i < length(x_history)
        grad_val = ∇f(x_history[i])
        annotate!(
            p, x_history[i], f(x_history[i]) + 10,
            text("∇f = $(round(grad_val, digits=3))", :bottom, 8)
        )
    end
end

# Guardar la animación como GIF
gif_filename = "gradiente_optimizacion.gif"
gif(anim, gif_filename, fps=3)
println("✓ Animación guardada en '$gif_filename'")

# También crear y guardar imagen estática final
p_final = plot(
    x_range, y_values,
    label="f(x) = x²",
    xlabel="x",
    ylabel="f(x)",
    title="Optimización por Descenso de Gradiente - Resultado Final",
    legend=:topright,
    linewidth=2,
    color=:blue,
    size=(800, 600)
)

# Agregar el recorrido completo del algoritmo
plot!(
    p_final, x_history, f.(x_history),
    label="Trayectoria completa",
    linewidth=1.5,
    color=:red,
    alpha=0.5,
    linestyle=:dash
)

scatter!(
    p_final, x_history, f.(x_history),
    label="Iteraciones (n=$(length(x_history)-1))",
    markersize=4,
    markercolor=:red,
    alpha=0.6
)

# Marcar el punto inicial
scatter!(
    p_final, [initial_point], [f(initial_point)],
    label="Inicio: x₀=$initial_point",
    markersize=8,
    markercolor=:green,
    markershape=:circle
)

# Marcar el punto final (óptimo)
scatter!(
    p_final, [x_opt], [f_opt],
    label="Óptimo: x*=$(round(x_opt, digits=4))",
    markersize=10,
    markercolor=:gold,
    markershape=:star5
)

# Añadir línea del mínimo teórico
hline!(p_final, [0.0], label="Mínimo teórico", linestyle=:dash, color=:black, alpha=0.3)

# Mostrar y guardar imagen estática
display(p_final)
savefig(p_final, "gradiente_optimizacion.png")
println("✓ Gráfica estática guardada en 'gradiente_optimizacion.png'")