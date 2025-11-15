"""
newton.jl

Método de Newton-Raphson para encontrar raíces de funciones no lineales.

Función a resolver: f(x) = 12x - 3x⁴ - 2x⁶

Propósito:
 - Implementar el algoritmo de Newton-Raphson para encontrar raíces
 - Visualizar la convergencia del método
 - Comparar con el método de bisección

Dependencias:
 - Julia (>= 1.x)
 - Paquetes: Plots

Instalación rápida (desde REPL):
	] add Plots

Ejecución:
	julia examples/newton.jl

Autor: Dr. Fabián Astudillo Salinas
Curso: Fundamentos de Optimización
Institución: UNACH
"""

using Plots

"""
	f(x)

Función objetivo: f(x) = 12x - 3x⁴ - 2x⁶

# Argumentos
- `x`: Valor en el cual evaluar la función

# Retorna
- Valor de f(x)
"""
function f(x)
	return 12*x - 3*x^4 - 2*x^6
end

"""
	df(x)

Derivada de la función objetivo: f'(x) = 12 - 12x³ - 12x⁵

# Argumentos
- `x`: Valor en el cual evaluar la derivada

# Retorna
- Valor de f'(x)
"""
function df(x)
	return 12 - 12*x^3 - 12*x^5
end

"""
	newton_raphson(f, df, x0; tol=1e-6, max_iter=100)

Implementa el método de Newton-Raphson para encontrar una raíz de f.

# Argumentos
- `f`: Función a resolver
- `df`: Derivada de la función
- `x0`: Punto inicial
- `tol`: Tolerancia para el criterio de parada (default: 1e-6)
- `max_iter`: Número máximo de iteraciones (default: 100)

# Retorna
- `raiz`: Aproximación de la raíz
- `historia`: Vector con los puntos en cada iteración
- `errores`: Vector con los errores absolutos en cada iteración
- `iter`: Número de iteraciones realizadas
- `convergencia`: true si convergió, false si no

# Fórmula
xₙ₊₁ = xₙ - f(xₙ)/f'(xₙ)

# Requisitos
- f'(x) ≠ 0 en el punto inicial y durante las iteraciones
- El punto inicial x0 debe estar suficientemente cerca de la raíz
"""
function newton_raphson(f, df, x0; tol=1e-6, max_iter=100)
	# Vectores para almacenar la historia
	historia = Float64[x0]
	errores = Float64[]
	
	x = x0
	iter = 0
	convergencia = false
	
	for i in 1:max_iter
		iter = i
		
		# Evaluar función y derivada
		fx = f(x)
		dfx = df(x)
		
		# Verificar si la derivada es cero
		if abs(dfx) < 1e-12
			@warn "Derivada muy cercana a cero en x = $x. El método puede fallar."
			break
		end
		
		# Calcular siguiente punto: x_{n+1} = x_n - f(x_n)/f'(x_n)
		x_nuevo = x - fx / dfx
		push!(historia, x_nuevo)
		
		# Calcular error
		error = abs(x_nuevo - x)
		push!(errores, error)
		
		# Verificar criterio de parada
		if error < tol || abs(fx) < tol
			convergencia = true
			x = x_nuevo
			break
		end
		
		x = x_nuevo
	end
	
	if !convergencia
		@warn "El método no convergió en $max_iter iteraciones."
	end
	
	return x, historia, errores, iter, convergencia
end

"""
	graficar_convergencia_newton(f, df, raiz, historia, errores, x0)

Genera visualizaciones del proceso de convergencia del método de Newton-Raphson.

# Argumentos
- `f`: Función objetivo
- `df`: Derivada de la función
- `raiz`: Raíz encontrada
- `historia`: Vector con los puntos en cada iteración
- `errores`: Vector con los errores en cada iteración
- `x0`: Punto inicial
"""
function graficar_convergencia_newton(f, df, raiz, historia, errores, x0)
	# Crear subplots
	p1 = plot(layout=(2, 2), size=(1000, 800))
	
	# Subplot 1: Función, derivada y raíz encontrada
	# Determinar rango apropiado
	x_min = min(minimum(historia) - 0.5, x0 - 0.5)
	x_max = max(maximum(historia) + 0.5, x0 + 0.5)
	x_range = LinRange(x_min, x_max, 200)
	
	plot!(p1[1], x_range, f.(x_range), 
		  label="f(x) = 12x - 3x⁴ - 2x⁶",
		  linewidth=2, color=:blue)
	hline!(p1[1], [0], label="y = 0", color=:black, linestyle=:dash)
	
	# Mostrar las líneas tangentes de las primeras iteraciones
	n_tangentes = min(5, length(historia) - 1)
	for i in 1:n_tangentes
		x_i = historia[i]
		y_i = f(x_i)
		m = df(x_i)
		# Línea tangente: y - y_i = m(x - x_i)
		x_tang = LinRange(x_i - 0.3, x_i + 0.3, 50)
		y_tang = y_i .+ m .* (x_tang .- x_i)
		plot!(p1[1], x_tang, y_tang, 
			  label=(i == 1 ? "Tangentes" : ""),
			  color=:gray, linestyle=:dot, alpha=0.5)
	end
	
	scatter!(p1[1], [x0], [f(x0)], 
			 label="x₀ (inicial)",
			 color=:green, markersize=8, markershape=:circle)
	scatter!(p1[1], [raiz], [f(raiz)], 
			 label="Raíz ≈ $(round(raiz, digits=6))",
			 color=:red, markersize=8, markershape=:star5)
	xlabel!(p1[1], "x")
	ylabel!(p1[1], "f(x)")
	title!(p1[1], "Función y Raíz Encontrada")
	
	# Subplot 2: Convergencia de las aproximaciones
	plot!(p1[2], 0:length(historia)-1, historia,
		  label="Aproximaciones xₙ",
		  linewidth=2, color=:green, marker=:circle)
	hline!(p1[2], [raiz], label="Raíz final", color=:red, linestyle=:dash)
	xlabel!(p1[2], "Iteración")
	ylabel!(p1[2], "x")
	title!(p1[2], "Convergencia de las Aproximaciones")
	
	# Subplot 3: Error absoluto
	if !isempty(errores)
		# Reemplazar ceros por un valor muy pequeño para evitar problemas con log10
		errores_plot = replace(x -> x == 0 ? 1e-16 : x, errores)
		plot!(p1[3], 1:length(errores_plot), errores_plot,
			  label="Error absoluto |xₙ₊₁ - xₙ|",
			  linewidth=2, color=:orange, marker=:circle,
			  yscale=:log10)
		xlabel!(p1[3], "Iteración")
		ylabel!(p1[3], "|xₙ₊₁ - xₙ|")
		title!(p1[3], "Error Absoluto (escala logarítmica)")
	end
	
	# Subplot 4: Valores de f(xₙ)
	valores_f = abs.(f.(historia))
	valores_f_plot = replace(x -> x == 0 ? 1e-16 : x, valores_f)
	plot!(p1[4], 0:length(historia)-1, valores_f_plot,
		  label="|f(xₙ)|",
		  linewidth=2, color=:purple, marker=:square,
		  yscale=:log10)
	xlabel!(p1[4], "Iteración")
	ylabel!(p1[4], "|f(xₙ)|")
	title!(p1[4], "Valores de |f(xₙ)| (escala logarítmica)")
	
	return p1
end

# ============================================================
# EJECUCIÓN PRINCIPAL
# ============================================================

println("=" ^ 60)
println("Método de Newton-Raphson")
println("Función: f(x) = 12x - 3x⁴ - 2x⁶")
println("Derivada: f'(x) = 12 - 12x³ - 12x⁵")
println("=" ^ 60)
println()

# Definir punto inicial
x0 = 1.5

println("Punto inicial: x₀ = $x0")
println("f(x₀) = $(f(x0))")
println("f'(x₀) = $(df(x0))")
println()

# Aplicar método de Newton-Raphson
tolerancia = 1e-6
max_iteraciones = 100

raiz, historia, errores, n_iter, convergencia = newton_raphson(f, df, x0, 
															   tol=tolerancia, 
															   max_iter=max_iteraciones)

# Mostrar resultados
println()
println("=" ^ 60)
println("RESULTADOS")
println("=" ^ 60)
if convergencia
	println("✓ El método convergió exitosamente")
else
	println("⚠️  El método no convergió")
end
println("Raíz encontrada: x* ≈ ", round(raiz, digits=10))
println("f(x*) ≈ ", round(f(raiz), digits=12))
println("Número de iteraciones: ", n_iter)
println("Tolerancia: ", tolerancia)
println()

# Mostrar historia de iteraciones
println("Historia de convergencia:")
println("Iter\t  xₙ\t\t\t  f(xₙ)\t\t  |xₙ₊₁ - xₙ|")
println("-" ^ 70)
for i in 1:length(historia)
	x_n = historia[i]
	f_n = f(x_n)
	error_str = i <= length(errores) ? "$(round(errores[i], digits=10))" : "-"
	println("$(i-1)\t  $(round(x_n, digits=10))\t  $(round(f_n, digits=8))\t  $error_str")
end
println()

# Generar visualización
println("Generando gráficos...")
p = graficar_convergencia_newton(f, df, raiz, historia, errores, x0)

# Guardar figura
savefig(p, "newton_convergencia.png")
println("✓ Gráficos guardados en: newton_convergencia.png")

# Mostrar en pantalla
display(p)

println()
println("=" ^ 60)
println("Análisis:")
println("  • El método de Newton-Raphson converge cuadráticamente")
println("  • En cada iteración: xₙ₊₁ = xₙ - f(xₙ)/f'(xₙ)")
println("  • Requiere calcular la derivada de f")
println("  • Converge mucho más rápido que bisección (cuando converge)")
println("  • Sensible al punto inicial x₀")
println("=" ^ 60)
println()

# Comparación con bisección (si existe la misma raíz)
println("=" ^ 60)
println("Comparación con Bisección:")
println("  • Bisección: ~20 iteraciones para tol=1e-6")
println("  • Newton-Raphson: $n_iter iteraciones para tol=1e-6")
println("  • Ventaja de Newton: ≈$(round(20/n_iter, digits=1))x más rápido")
println("=" ^ 60)
