"""
biseccion.jl

Método de Bisección para encontrar raíces de funciones no lineales.

Función a resolver: f(x) = 12x - 3x⁴ - 2x⁶

Propósito:
 - Implementar el algoritmo de bisección para encontrar raíces
 - Visualizar la convergencia del método
 - Mostrar la evolución del intervalo de búsqueda

Dependencias:
 - Julia (>= 1.x)
 - Paquetes: Plots

Instalación rápida (desde REPL):
	] add Plots

Ejecución:
	julia examples/biseccion.jl

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
	biseccion(f, a, b; tol=1e-6, max_iter=100)

Implementa el método de bisección para encontrar una raíz de f en [a,b].

# Argumentos
- `f`: Función a resolver (debe ser continua en [a,b])
- `a`: Extremo izquierdo del intervalo inicial
- `b`: Extremo derecho del intervalo inicial
- `tol`: Tolerancia para el criterio de parada (default: 1e-6)
- `max_iter`: Número máximo de iteraciones (default: 100)

# Retorna
- `raiz`: Aproximación de la raíz
- `historia`: Vector con los puntos medios en cada iteración
- `intervalos`: Matriz con los intervalos [a,b] en cada iteración
- `iter`: Número de iteraciones realizadas

# Requisitos
- f(a) y f(b) deben tener signos opuestos: f(a)*f(b) < 0
"""
function biseccion(f, a, b; tol=1e-6, max_iter=100)
	# Verificar que f(a) y f(b) tienen signos opuestos
	if f(a) * f(b) > 0
		error("f(a) y f(b) deben tener signos opuestos. f($a) = $(f(a)), f($b) = $(f(b))")
	end
	
	# Vectores para almacenar la historia
	historia = Float64[]
	intervalos = zeros(max_iter + 1, 2)
	intervalos[1, :] = [a, b]
	
	iter = 0
	c = a  # Punto medio
	
	for i in 1:max_iter
		iter = i
		
		# Calcular punto medio
		c = (a + b) / 2
		push!(historia, c)
		
		# Evaluar función en el punto medio
		fc = f(c)
		
		# Verificar criterio de parada
		if abs(fc) < tol || (b - a) / 2 < tol
			break
		end
		
		# Determinar nuevo intervalo
		if f(a) * fc < 0
			b = c  # La raíz está en [a, c]
		else
			a = c  # La raíz está en [c, b]
		end
		
		# Guardar nuevo intervalo
		if i < max_iter
			intervalos[i + 1, :] = [a, b]
		end
	end
	
	# Recortar los intervalos no utilizados
	intervalos = intervalos[1:iter+1, :]
	
	return c, historia, intervalos, iter
end

"""
	graficar_convergencia(f, raiz, historia, intervalos)

Genera visualizaciones del proceso de convergencia del método de bisección.

# Argumentos
- `f`: Función objetivo
- `raiz`: Raíz encontrada
- `historia`: Vector con los puntos medios en cada iteración
- `intervalos`: Matriz con los intervalos en cada iteración
"""
function graficar_convergencia(f, raiz, historia, intervalos)
	# Crear subplots
	p1 = plot(layout=(2, 2), size=(1000, 800))
	
	# Subplot 1: Función y raíz encontrada
	x_range = LinRange(intervalos[1, 1] - 0.5, intervalos[1, 2] + 0.5, 200)
	plot!(p1[1], x_range, f.(x_range), 
		  label="f(x) = 12x - 3x⁴ - 2x⁶",
		  linewidth=2, color=:blue)
	hline!(p1[1], [0], label="y = 0", color=:black, linestyle=:dash)
	scatter!(p1[1], [raiz], [f(raiz)], 
			 label="Raíz ≈ $(round(raiz, digits=6))",
			 color=:red, markersize=8, markershape=:star5)
	xlabel!(p1[1], "x")
	ylabel!(p1[1], "f(x)")
	title!(p1[1], "Función y Raíz Encontrada")
	
	# Subplot 2: Convergencia del punto medio
	plot!(p1[2], 1:length(historia), historia,
		  label="Punto medio",
		  linewidth=2, color=:green, marker=:circle)
	hline!(p1[2], [raiz], label="Raíz final", color=:red, linestyle=:dash)
	xlabel!(p1[2], "Iteración")
	ylabel!(p1[2], "x")
	title!(p1[2], "Convergencia del Punto Medio")
	
	# Subplot 3: Error absoluto
	errores = abs.(historia .- raiz)
	# Reemplazar ceros por un valor muy pequeño para evitar problemas con log10
	errores_plot = replace(x -> x == 0 ? 1e-16 : x, errores)
	plot!(p1[3], 1:length(errores_plot), errores_plot,
		  label="Error absoluto",
		  linewidth=2, color=:orange, marker=:circle,
		  yscale=:log10)
	xlabel!(p1[3], "Iteración")
	ylabel!(p1[3], "|xₖ - x*|")
	title!(p1[3], "Error Absoluto (escala logarítmica)")
	
	# Subplot 4: Evolución del intervalo
	n_iter = size(intervalos, 1)
	plot!(p1[4], 1:n_iter, intervalos[:, 1],
		  label="Extremo izquierdo (a)",
		  linewidth=2, color=:purple, marker=:circle)
	plot!(p1[4], 1:n_iter, intervalos[:, 2],
		  label="Extremo derecho (b)",
		  linewidth=2, color=:cyan, marker=:square)
	hline!(p1[4], [raiz], label="Raíz final", color=:red, linestyle=:dash)
	xlabel!(p1[4], "Iteración")
	ylabel!(p1[4], "x")
	title!(p1[4], "Evolución del Intervalo [a, b]")
	
	return p1
end

# ============================================================
# EJECUCIÓN PRINCIPAL
# ============================================================

println("=" ^ 60)
println("Método de Bisección")
println("Función: f(x) = 12x - 3x⁴ - 2x⁶")
println("=" ^ 60)
println()

# Definir intervalo inicial [a, b]
# Debemos elegir a y b tal que f(a)*f(b) < 0
a = 1.0
b = 2.0

println("Intervalo inicial: [$a, $b]")
println("f($a) = $(f(a))")
println("f($b) = $(f(b))")
println()

# Verificar que hay cambio de signo
if f(a) * f(b) > 0
	println("⚠️  ADVERTENCIA: f(a) y f(b) tienen el mismo signo.")
	println("   No se garantiza una raíz en este intervalo.")
	println("   Prueba con otro intervalo.")
else
	println("✓ f(a) y f(b) tienen signos opuestos. Procediendo...")
	println()
	
	# Aplicar método de bisección
	tolerancia = 1e-6
	max_iteraciones = 100
	
	raiz, historia, intervalos, n_iter = biseccion(f, a, b, 
												   tol=tolerancia, 
												   max_iter=max_iteraciones)
	
	# Mostrar resultados
	println()
	println("=" ^ 60)
	println("RESULTADOS")
	println("=" ^ 60)
	println("Raíz encontrada: x* ≈ ", round(raiz, digits=8))
	println("f(x*) ≈ ", round(f(raiz), digits=10))
	println("Número de iteraciones: ", n_iter)
	println("Tolerancia: ", tolerancia)
	println()
	
	# Mostrar historia de iteraciones
	println("Historia de convergencia:")
	println("Iter\t  Punto medio (c)\t  f(c)\t\t  Ancho intervalo")
	println("-" ^ 70)
	for i in 1:min(10, length(historia))  # Mostrar solo las primeras 10
		c = historia[i]
		ancho = intervalos[i+1, 2] - intervalos[i+1, 1]
		println("$i\t  $(round(c, digits=8))\t  $(round(f(c), digits=6))\t  $(round(ancho, digits=8))")
	end
	if length(historia) > 10
		println("... ($(length(historia) - 10) iteraciones más)")
	end
	println()
	
	# Generar visualización
	println("Generando gráficos...")
	p = graficar_convergencia(f, raiz, historia, intervalos)
	
	# Guardar figura
	savefig(p, "biseccion_convergencia.png")
	println("✓ Gráficos guardados en: biseccion_convergencia.png")
	
	# Mostrar en pantalla
	display(p)
	
	println()
	println("=" ^ 60)
	println("Análisis:")
	println("  • El método converge linealmente")
	println("  • En cada iteración el intervalo se reduce a la mitad")
	println("  • Se necesitan aproximadamente log₂((b-a)/tol) iteraciones")
	println("  • Iteraciones teóricas: ≈ ", ceil(log2((b-a)/tolerancia)))
	println("  • Iteraciones reales: ", n_iter)
	println("=" ^ 60)
end
