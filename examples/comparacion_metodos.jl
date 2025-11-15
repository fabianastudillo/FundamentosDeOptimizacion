"""
comparacion_metodos.jl

Comparación gráfica entre los métodos de Bisección y Newton-Raphson
para encontrar raíces de funciones no lineales.

Función a resolver: f(x) = 12x - 3x⁴ - 2x⁶

Propósito:
 - Comparar visualmente la convergencia de ambos métodos
 - Analizar velocidad de convergencia
 - Mostrar ventajas y desventajas de cada método

Dependencias:
 - Julia (>= 1.x)
 - Paquetes: Plots

Instalación rápida (desde REPL):
	] add Plots

Ejecución:
	julia examples/comparacion_metodos.jl

Autor: Dr. Fabián Astudillo Salinas
Curso: Fundamentos de Optimización
Institución: UNACH
"""

using Plots

# ============================================================
# DEFINICIÓN DE LA FUNCIÓN Y SU DERIVADA
# ============================================================

"""
	f(x)

Función objetivo: f(x) = 12x - 3x⁴ - 2x⁶
"""
function f(x)
	return 12*x - 3*x^4 - 2*x^6
end

"""
	df(x)

Derivada de la función objetivo: f'(x) = 12 - 12x³ - 12x⁵
"""
function df(x)
	return 12 - 12*x^3 - 12*x^5
end

# ============================================================
# MÉTODO DE BISECCIÓN
# ============================================================

"""
	biseccion(f, a, b; tol=1e-6, max_iter=100)

Implementa el método de bisección para encontrar una raíz de f en [a,b].
"""
function biseccion(f, a, b; tol=1e-6, max_iter=100)
	if f(a) * f(b) > 0
		error("f(a) y f(b) deben tener signos opuestos.")
	end
	
	historia = Float64[]
	errores_relativos = Float64[]
	
	c_anterior = a
	
	for i in 1:max_iter
		c = (a + b) / 2
		push!(historia, c)
		
		if i > 1
			push!(errores_relativos, abs((c - c_anterior) / c))
		end
		
		fc = f(c)
		
		if abs(fc) < tol || (b - a) / 2 < tol
			return c, historia, errores_relativos, i
		end
		
		if f(a) * fc < 0
			b = c
		else
			a = c
		end
		
		c_anterior = c
	end
	
	return (a + b) / 2, historia, errores_relativos, max_iter
end

# ============================================================
# MÉTODO DE NEWTON-RAPHSON
# ============================================================

"""
	newton_raphson(f, df, x0; tol=1e-6, max_iter=100)

Implementa el método de Newton-Raphson para encontrar una raíz de f.
"""
function newton_raphson(f, df, x0; tol=1e-6, max_iter=100)
	historia = Float64[x0]
	errores_relativos = Float64[]
	
	x = x0
	
	for i in 1:max_iter
		fx = f(x)
		dfx = df(x)
		
		if abs(dfx) < 1e-12
			@warn "Derivada muy cercana a cero. El método puede fallar."
			break
		end
		
		x_nuevo = x - fx / dfx
		push!(historia, x_nuevo)
		
		error_relativo = abs((x_nuevo - x) / x_nuevo)
		push!(errores_relativos, error_relativo)
		
		if error_relativo < tol || abs(fx) < tol
			return x_nuevo, historia, errores_relativos, i
		end
		
		x = x_nuevo
	end
	
	return x, historia, errores_relativos, length(historia) - 1
end

# ============================================================
# VISUALIZACIÓN COMPARATIVA
# ============================================================

"""
	comparar_metodos(f, df, a, b, x0, tol)

Compara visualmente los métodos de bisección y Newton-Raphson.
"""
function comparar_metodos(f, df, a, b, x0, tol)
	# Ejecutar ambos métodos
	println("Ejecutando método de Bisección...")
	raiz_bis, hist_bis, err_bis, iter_bis = biseccion(f, a, b, tol=tol)
	
	println("Ejecutando método de Newton-Raphson...")
	raiz_newton, hist_newton, err_newton, iter_newton = newton_raphson(f, df, x0, tol=tol)
	
	# Crear visualización con 6 subplots
	p = plot(layout=(3, 2), size=(1200, 1200))
	
	# ============================================================
	# SUBPLOT 1: Función con ambas raíces
	# ============================================================
	x_range = LinRange(min(a - 0.5, minimum(hist_newton) - 0.5), 
					   max(b + 0.5, maximum(hist_newton) + 0.5), 300)
	
	plot!(p[1], x_range, f.(x_range), 
		  label="f(x) = 12x - 3x⁴ - 2x⁶",
		  linewidth=3, color=:blue)
	hline!(p[1], [0], label="y = 0", color=:black, linestyle=:dash, linewidth=2)
	
	scatter!(p[1], [raiz_bis], [f(raiz_bis)], 
			 label="Bisección: $(round(raiz_bis, digits=6))",
			 color=:red, markersize=10, markershape=:square)
	scatter!(p[1], [raiz_newton], [f(raiz_newton)], 
			 label="Newton: $(round(raiz_newton, digits=6))",
			 color=:green, markersize=10, markershape=:star5)
	
	xlabel!(p[1], "x")
	ylabel!(p[1], "f(x)")
	title!(p[1], "Función y Raíces Encontradas")
	
	# ============================================================
	# SUBPLOT 2: Convergencia de aproximaciones
	# ============================================================
	plot!(p[2], 1:length(hist_bis), hist_bis,
		  label="Bisección ($iter_bis iter)",
		  linewidth=2, color=:red, marker=:square, markersize=4)
	plot!(p[2], 0:length(hist_newton)-1, hist_newton,
		  label="Newton ($iter_newton iter)",
		  linewidth=2, color=:green, marker=:star5, markersize=6)
	
	xlabel!(p[2], "Iteración")
	ylabel!(p[2], "x")
	title!(p[2], "Convergencia de las Aproximaciones")
	legend!(p[2], :right)
	
	# ============================================================
	# SUBPLOT 3: Error relativo (escala logarítmica)
	# ============================================================
	if !isempty(err_bis) && !isempty(err_newton)
		err_bis_plot = replace(x -> x == 0 ? 1e-16 : x, err_bis)
		err_newton_plot = replace(x -> x == 0 ? 1e-16 : x, err_newton)
		
		plot!(p[3], 1:length(err_bis_plot), err_bis_plot,
			  label="Bisección (lineal)",
			  linewidth=2, color=:red, marker=:square, markersize=4,
			  yscale=:log10)
		plot!(p[3], 1:length(err_newton_plot), err_newton_plot,
			  label="Newton (cuadrática)",
			  linewidth=2, color=:green, marker=:star5, markersize=6,
			  yscale=:log10)
		
		xlabel!(p[3], "Iteración")
		ylabel!(p[3], "Error relativo")
		title!(p[3], "Velocidad de Convergencia (log)")
	end
	
	# ============================================================
	# SUBPLOT 4: Número de iteraciones (gráfico de barras)
	# ============================================================
	bar!(p[4], ["Bisección", "Newton"], [iter_bis, iter_newton],
		 color=[:red :green],
		 legend=false,
		 ylabel="Iteraciones",
		 title="Número de Iteraciones",
		 fillalpha=0.7)
	
	# Añadir etiquetas con los valores
	annotate!(p[4], 1, iter_bis + 1, text("$iter_bis", :center, 10))
	annotate!(p[4], 2, iter_newton + 1, text("$iter_newton", :center, 10))
	
	# ============================================================
	# SUBPLOT 5: Evolución de |f(xₙ)|
	# ============================================================
	valores_f_bis = abs.(f.(hist_bis))
	valores_f_newton = abs.(f.(hist_newton))
	
	valores_f_bis_plot = replace(x -> x == 0 ? 1e-16 : x, valores_f_bis)
	valores_f_newton_plot = replace(x -> x == 0 ? 1e-16 : x, valores_f_newton)
	
	plot!(p[5], 1:length(valores_f_bis_plot), valores_f_bis_plot,
		  label="Bisección",
		  linewidth=2, color=:red, marker=:square, markersize=4,
		  yscale=:log10)
	plot!(p[5], 0:length(valores_f_newton_plot)-1, valores_f_newton_plot,
		  label="Newton",
		  linewidth=2, color=:green, marker=:star5, markersize=6,
		  yscale=:log10)
	
	xlabel!(p[5], "Iteración")
	ylabel!(p[5], "|f(xₙ)|")
	title!(p[5], "Valores de |f(xₙ)| (log)")
	
	# ============================================================
	# SUBPLOT 6: Tabla comparativa (como texto en el plot)
	# ============================================================
	plot!(p[6], framestyle=:none, legend=false, grid=false, 
		  xlims=(0, 1), ylims=(0, 1))
	
	# Crear tabla de comparación
	y_pos = 0.95
	dy = 0.08
	
	annotate!(p[6], 0.5, y_pos, text("TABLA COMPARATIVA", :center, 12, :bold))
	y_pos -= dy * 1.5
	
	annotate!(p[6], 0.15, y_pos, text("Característica", :left, 10, :bold))
	annotate!(p[6], 0.5, y_pos, text("Bisección", :center, 10, :bold))
	annotate!(p[6], 0.85, y_pos, text("Newton", :center, 10, :bold))
	y_pos -= dy
	
	# Fila: Iteraciones
	annotate!(p[6], 0.15, y_pos, text("Iteraciones:", :left, 9))
	annotate!(p[6], 0.5, y_pos, text("$iter_bis", :center, 9))
	annotate!(p[6], 0.85, y_pos, text("$iter_newton", :center, 9))
	y_pos -= dy
	
	# Fila: Raíz encontrada
	annotate!(p[6], 0.15, y_pos, text("Raíz (x*):", :left, 9))
	annotate!(p[6], 0.5, y_pos, text("$(round(raiz_bis, digits=7))", :center, 8))
	annotate!(p[6], 0.85, y_pos, text("$(round(raiz_newton, digits=7))", :center, 8))
	y_pos -= dy
	
	# Fila: f(x*)
	annotate!(p[6], 0.15, y_pos, text("f(x*):", :left, 9))
	annotate!(p[6], 0.5, y_pos, text("$(round(f(raiz_bis), sigdigits=3))", :center, 8))
	annotate!(p[6], 0.85, y_pos, text("$(round(f(raiz_newton), sigdigits=3))", :center, 8))
	y_pos -= dy
	
	# Fila: Convergencia
	annotate!(p[6], 0.15, y_pos, text("Convergencia:", :left, 9))
	annotate!(p[6], 0.5, y_pos, text("Lineal", :center, 9))
	annotate!(p[6], 0.85, y_pos, text("Cuadrática", :center, 9))
	y_pos -= dy
	
	# Fila: Derivada
	annotate!(p[6], 0.15, y_pos, text("Req. derivada:", :left, 9))
	annotate!(p[6], 0.5, y_pos, text("No", :center, 9))
	annotate!(p[6], 0.85, y_pos, text("Sí", :center, 9))
	y_pos -= dy
	
	# Fila: Ventaja
	velocidad_relativa = round(iter_bis / iter_newton, digits=1)
	annotate!(p[6], 0.15, y_pos, text("Ventaja:", :left, 9))
	annotate!(p[6], 0.5, y_pos, text("Robusto", :center, 8))
	annotate!(p[6], 0.85, y_pos, text("$(velocidad_relativa)x rápido", :center, 8))
	
	return p, raiz_bis, raiz_newton, iter_bis, iter_newton
end

# ============================================================
# EJECUCIÓN PRINCIPAL
# ============================================================

println("=" ^ 70)
println("COMPARACIÓN: Método de Bisección vs Newton-Raphson")
println("Función: f(x) = 12x - 3x⁴ - 2x⁶")
println("=" ^ 70)
println()

# Parámetros
a = 1.0           # Extremo izquierdo (bisección)
b = 2.0           # Extremo derecho (bisección)
x0 = 1.5          # Punto inicial (Newton)
tolerancia = 1e-6

println("CONFIGURACIÓN:")
println("  • Bisección - Intervalo inicial: [$a, $b]")
println("  • Newton - Punto inicial: x₀ = $x0")
println("  • Tolerancia: $tolerancia")
println()

# Verificar condiciones
println("VERIFICACIÓN DE CONDICIONES:")
println("  • f($a) = $(f(a))")
println("  • f($b) = $(f(b))")
println("  • f($a) × f($b) = $(f(a) * f(b)) $(f(a) * f(b) < 0 ? "< 0 ✓" : "> 0 ✗")")
println("  • f'($x0) = $(df(x0))")
println()

if f(a) * f(b) > 0
	error("f(a) y f(b) deben tener signos opuestos para bisección")
end

# Ejecutar comparación
println("=" ^ 70)
println("EJECUTANDO COMPARACIÓN...")
println("=" ^ 70)
println()

p, raiz_bis, raiz_newton, iter_bis, iter_newton = comparar_metodos(f, df, a, b, x0, tolerancia)

# Mostrar resultados
println()
println("=" ^ 70)
println("RESULTADOS DE LA COMPARACIÓN")
println("=" ^ 70)
println()

println("BISECCIÓN:")
println("  • Raíz encontrada: x* ≈ $(round(raiz_bis, digits=10))")
println("  • f(x*) ≈ $(round(f(raiz_bis), sigdigits=4))")
println("  • Iteraciones: $iter_bis")
println("  • Convergencia: Lineal (error se reduce a la mitad cada iteración)")
println()

println("NEWTON-RAPHSON:")
println("  • Raíz encontrada: x* ≈ $(round(raiz_newton, digits=10))")
println("  • f(x*) ≈ $(round(f(raiz_newton), sigdigits=4))")
println("  • Iteraciones: $iter_newton")
println("  • Convergencia: Cuadrática (el error se eleva al cuadrado)")
println()

println("COMPARACIÓN:")
println("  • Factor de velocidad: Newton es ≈$(round(iter_bis/iter_newton, digits=1))x más rápido")
println("  • Diferencia en raíces: $(abs(raiz_bis - raiz_newton)) (≈0, ambos encuentran la misma raíz)")
println()

println("=" ^ 70)
println("VENTAJAS Y DESVENTAJAS")
println("=" ^ 70)
println()

println("BISECCIÓN:")
println("  ✓ Siempre converge si f(a)×f(b) < 0")
println("  ✓ No requiere derivadas")
println("  ✓ Robusto y confiable")
println("  ✗ Convergencia lenta (lineal)")
println("  ✗ Necesita intervalo con cambio de signo")
println()

println("NEWTON-RAPHSON:")
println("  ✓ Convergencia muy rápida (cuadrática)")
println("  ✓ Solo necesita un punto inicial")
println("  ✓ Ideal cuando se conoce una aproximación")
println("  ✗ Requiere calcular f'(x)")
println("  ✗ Puede fallar si f'(x) ≈ 0")
println("  ✗ Sensible al punto inicial x₀")
println()

println("=" ^ 70)
println("RECOMENDACIONES DE USO")
println("=" ^ 70)
println()
println("Usar BISECCIÓN cuando:")
println("  • Se conoce un intervalo con cambio de signo")
println("  • No se puede calcular la derivada")
println("  • Se requiere garantía de convergencia")
println("  • La función tiene múltiples raíces cercanas")
println()
println("Usar NEWTON cuando:")
println("  • Se tiene una buena aproximación inicial")
println("  • Se puede calcular f'(x) fácilmente")
println("  • Se requiere alta velocidad de convergencia")
println("  • La derivada no se anula cerca de la raíz")
println()

# Guardar figura
println("=" ^ 70)
savefig(p, "comparacion_biseccion_newton.png")
println("✓ Gráficos guardados en: comparacion_biseccion_newton.png")

# Mostrar en pantalla
display(p)

println("=" ^ 70)
println("✓ COMPARACIÓN COMPLETADA")
println("=" ^ 70)
