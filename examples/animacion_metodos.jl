"""
animacion_metodos.jl

Animación GIF comparando Bisección y Newton-Raphson paso a paso.

Función a resolver: f(x) = 12x - 3x⁴ - 2x⁶

Propósito:
 - Crear una animación visual del proceso de convergencia
 - Mostrar cada iteración de ambos métodos simultáneamente
 - Generar un GIF educativo para enseñanza

Dependencias:
 - Julia (>= 1.x)
 - Paquetes: Plots

Instalación rápida (desde REPL):
	] add Plots

Ejecución:
	julia examples/animacion_metodos.jl

Salida:
	- biseccion_animacion.gif
	- newton_animacion.gif
	- comparacion_animacion.gif (ambos métodos lado a lado)

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
# MÉTODO DE BISECCIÓN (CON HISTORIA DETALLADA)
# ============================================================

"""
	biseccion_detallada(f, a, b; tol=1e-6, max_iter=100)

Versión del método de bisección que guarda información detallada
de cada iteración para animación.
"""
function biseccion_detallada(f, a, b; tol=1e-6, max_iter=100)
	if f(a) * f(b) > 0
		error("f(a) y f(b) deben tener signos opuestos.")
	end
	
	historia_puntos = Float64[]      # Puntos medios
	historia_intervalos_a = Float64[a]  # Extremos izquierdos
	historia_intervalos_b = Float64[b]  # Extremos derechos
	
	a_actual = a
	b_actual = b
	
	for i in 1:max_iter
		c = (a_actual + b_actual) / 2
		push!(historia_puntos, c)
		
		fc = f(c)
		
		if abs(fc) < tol || (b_actual - a_actual) / 2 < tol
			push!(historia_intervalos_a, a_actual)
			push!(historia_intervalos_b, b_actual)
			return c, historia_puntos, historia_intervalos_a, historia_intervalos_b, i
		end
		
		if f(a_actual) * fc < 0
			b_actual = c
		else
			a_actual = c
		end
		
		push!(historia_intervalos_a, a_actual)
		push!(historia_intervalos_b, b_actual)
	end
	
	c = (a_actual + b_actual) / 2
	return c, historia_puntos, historia_intervalos_a, historia_intervalos_b, max_iter
end

# ============================================================
# MÉTODO DE NEWTON-RAPHSON (CON HISTORIA DETALLADA)
# ============================================================

"""
	newton_raphson_detallado(f, df, x0; tol=1e-6, max_iter=100)

Versión del método de Newton-Raphson que guarda información detallada
de cada iteración para animación.
"""
function newton_raphson_detallado(f, df, x0; tol=1e-6, max_iter=100)
	historia_puntos = Float64[x0]
	historia_tangentes = []  # Guardar información de tangentes
	
	x = x0
	
	for i in 1:max_iter
		fx = f(x)
		dfx = df(x)
		
		if abs(dfx) < 1e-12
			@warn "Derivada muy cercana a cero. El método puede fallar."
			break
		end
		
		# Guardar información de la tangente para graficar
		push!(historia_tangentes, (x, fx, dfx))
		
		x_nuevo = x - fx / dfx
		push!(historia_puntos, x_nuevo)
		
		if abs(x_nuevo - x) < tol || abs(fx) < tol
			return x_nuevo, historia_puntos, historia_tangentes, i
		end
		
		x = x_nuevo
	end
	
	return x, historia_puntos, historia_tangentes, length(historia_puntos) - 1
end

# ============================================================
# ANIMACIÓN BISECCIÓN
# ============================================================

"""
	animar_biseccion(f, a, b, tol)

Crea una animación GIF del método de bisección.
"""
function animar_biseccion(f, a, b, tol)
	println("Ejecutando bisección...")
	raiz, hist_puntos, hist_a, hist_b, n_iter = biseccion_detallada(f, a, b, tol=tol)
	
	println("Creando animación de bisección...")
	
	# Rango para graficar la función
	x_range = LinRange(a - 0.5, b + 0.5, 300)
	y_range = f.(x_range)
	
	anim = @animate for i in 1:n_iter
		# Graficar la función
		plot(x_range, y_range, 
			 label="f(x) = 12x - 3x⁴ - 2x⁶",
			 linewidth=3, color=:blue,
			 size=(800, 600),
			 xlabel="x", ylabel="f(x)",
			 title="Método de Bisección - Iteración $i de $n_iter")
		
		hline!([0], label="y = 0", color=:black, linestyle=:dash, linewidth=2)
		
		# Graficar el intervalo actual
		a_i = hist_a[i]
		b_i = hist_b[i]
		c_i = hist_puntos[i]
		
		# Sombrear el intervalo [a, b]
		plot!([a_i, a_i], [minimum(y_range), maximum(y_range)], 
			  color=:red, linestyle=:dot, linewidth=2, label="")
		plot!([b_i, b_i], [minimum(y_range), maximum(y_range)], 
			  color=:red, linestyle=:dot, linewidth=2, label="Intervalo [$a_i, $b_i]")
		
		# Marcar puntos importantes
		scatter!([a_i], [f(a_i)], color=:red, markersize=8, 
				 markershape=:circle, label="a = $(round(a_i, digits=4))")
		scatter!([b_i], [f(b_i)], color=:red, markersize=8, 
				 markershape=:circle, label="b = $(round(b_i, digits=4))")
		scatter!([c_i], [f(c_i)], color=:green, markersize=10, 
				 markershape=:star5, label="c = $(round(c_i, digits=4))")
		
		# Añadir información textual
		ancho = b_i - a_i
		annotate!(a + 0.25, maximum(y_range) * 0.8, 
				 text("Ancho intervalo: $(round(ancho, digits=6))\nf(c) = $(round(f(c_i), digits=6))", 
				 	  :left, 10))
		
		# Mostrar historial de puntos anteriores
		if i > 1
			scatter!(hist_puntos[1:i-1], f.(hist_puntos[1:i-1]), 
					color=:gray, markersize=4, alpha=0.5, label="Iteraciones previas")
		end
	end
	
	return anim, raiz, n_iter
end

# ============================================================
# ANIMACIÓN NEWTON-RAPHSON
# ============================================================

"""
	animar_newton(f, df, x0, tol)

Crea una animación GIF del método de Newton-Raphson.
"""
function animar_newton(f, df, x0, tol)
	println("Ejecutando Newton-Raphson...")
	raiz, hist_puntos, hist_tangentes, n_iter = newton_raphson_detallado(f, df, x0, tol=tol)
	
	println("Creando animación de Newton-Raphson...")
	
	# Rango para graficar la función
	x_min = min(minimum(hist_puntos) - 0.5, x0 - 0.5)
	x_max = max(maximum(hist_puntos) + 0.5, x0 + 0.5)
	x_range = LinRange(x_min, x_max, 300)
	y_range = f.(x_range)
	
	anim = @animate for i in 0:n_iter
		# Graficar la función
		plot(x_range, y_range, 
			 label="f(x) = 12x - 3x⁴ - 2x⁶",
			 linewidth=3, color=:blue,
			 size=(800, 600),
			 xlabel="x", ylabel="f(x)",
			 title="Método de Newton-Raphson - Iteración $i de $n_iter")
		
		hline!([0], label="y = 0", color=:black, linestyle=:dash, linewidth=2)
		
		# Marcar punto actual
		x_i = hist_puntos[i+1]
		scatter!([x_i], [f(x_i)], color=:green, markersize=10, 
				 markershape=:star5, label="xₙ = $(round(x_i, digits=6))")
		
		# Si no es la última iteración, mostrar la tangente
		if i < n_iter && i < length(hist_tangentes)
			x_tang, y_tang, m_tang = hist_tangentes[i+1]
			
			# Graficar línea tangente
			x_tang_range = LinRange(x_tang - 0.4, x_tang + 0.4, 50)
			y_tang_range = y_tang .+ m_tang .* (x_tang_range .- x_tang)
			plot!(x_tang_range, y_tang_range, 
				  color=:red, linestyle=:dash, linewidth=2, 
				  label="Tangente (m = $(round(m_tang, digits=2)))")
			
			# Marcar el siguiente punto (intersección con eje x)
			x_next = hist_puntos[i+2]
			scatter!([x_next], [0], color=:orange, markersize=8, 
					markershape=:diamond, label="xₙ₊₁ = $(round(x_next, digits=6))")
			
			# Flechas indicando el movimiento
			plot!([x_tang, x_next], [y_tang, 0], 
				  arrow=true, color=:orange, linewidth=2, label="")
		end
		
		# Añadir información textual
		annotate!(x_min + 0.1, maximum(y_range) * 0.85, 
				 text("f(xₙ) = $(round(f(x_i), digits=8))\nf'(xₙ) = $(round(df(x_i), digits=4))", 
				 	  :left, 10))
		
		# Mostrar historial de puntos anteriores
		if i > 0
			scatter!(hist_puntos[1:i], f.(hist_puntos[1:i]), 
					color=:gray, markersize=4, alpha=0.5, label="Iteraciones previas")
		end
	end
	
	return anim, raiz, n_iter
end

# ============================================================
# ANIMACIÓN COMPARATIVA (LADO A LADO)
# ============================================================

"""
	animar_comparacion(f, df, a, b, x0, tol)

Crea una animación GIF comparando ambos métodos lado a lado.
"""
function animar_comparacion(f, df, a, b, x0, tol)
	println("Ejecutando ambos métodos para comparación...")
	
	# Ejecutar bisección
	raiz_bis, hist_puntos_bis, hist_a, hist_b, n_iter_bis = biseccion_detallada(f, a, b, tol=tol)
	
	# Ejecutar Newton
	raiz_newton, hist_puntos_newton, hist_tangentes, n_iter_newton = newton_raphson_detallado(f, df, x0, tol=tol)
	
	println("Creando animación comparativa...")
	
	# Usar el máximo de iteraciones para la animación
	max_iter = max(n_iter_bis, n_iter_newton)
	
	# Rangos para graficar
	x_range_bis = LinRange(a - 0.5, b + 0.5, 300)
	x_min_newton = min(minimum(hist_puntos_newton) - 0.5, x0 - 0.5)
	x_max_newton = max(maximum(hist_puntos_newton) + 0.5, x0 + 0.5)
	x_range_newton = LinRange(x_min_newton, x_max_newton, 300)
	
	anim = @animate for i in 1:max_iter
		p = plot(layout=(1, 2), size=(1400, 600))
		
		# ============================================================
		# SUBPLOT 1: BISECCIÓN
		# ============================================================
		if i <= n_iter_bis
			y_range = f.(x_range_bis)
			
			plot!(p[1], x_range_bis, y_range, 
				  label="f(x)",
				  linewidth=2, color=:blue,
				  xlabel="x", ylabel="f(x)",
				  title="Bisección - Iter $i/$n_iter_bis")
			
			hline!(p[1], [0], label="", color=:black, linestyle=:dash, linewidth=1)
			
			a_i = hist_a[i]
			b_i = hist_b[i]
			c_i = hist_puntos_bis[i]
			
			# Intervalo actual
			plot!(p[1], [a_i, a_i], [minimum(y_range), maximum(y_range)], 
				  color=:red, linestyle=:dot, linewidth=1, label="")
			plot!(p[1], [b_i, b_i], [minimum(y_range), maximum(y_range)], 
				  color=:red, linestyle=:dot, linewidth=1, label="")
			
			scatter!(p[1], [a_i], [f(a_i)], color=:red, markersize=6, label="a, b")
			scatter!(p[1], [b_i], [f(b_i)], color=:red, markersize=6, label="")
			scatter!(p[1], [c_i], [f(c_i)], color=:green, markersize=8, 
					markershape=:star5, label="c = $(round(c_i, digits=4))")
			
			# Historial
			if i > 1
				scatter!(p[1], hist_puntos_bis[1:i-1], f.(hist_puntos_bis[1:i-1]), 
						color=:gray, markersize=3, alpha=0.4, label="")
			end
			
			ancho = b_i - a_i
			annotate!(p[1], a + 0.2, maximum(y_range) * 0.9, 
					 text("Ancho: $(round(ancho, digits=5))", :left, 9))
		else
			plot!(p[1], x_range_bis, f.(x_range_bis), 
				  linewidth=2, color=:blue,
				  xlabel="x", ylabel="f(x)",
				  title="Bisección - COMPLETADO ($n_iter_bis iter)")
			hline!(p[1], [0], color=:black, linestyle=:dash, linewidth=1, label="")
			scatter!(p[1], [raiz_bis], [f(raiz_bis)], color=:green, markersize=10, 
					markershape=:star5, label="Raíz: $(round(raiz_bis, digits=6))")
		end
		
		# ============================================================
		# SUBPLOT 2: NEWTON-RAPHSON
		# ============================================================
		if i <= n_iter_newton + 1
			y_range = f.(x_range_newton)
			
			iter_newton = i - 1  # Newton comienza en iteración 0
			
			plot!(p[2], x_range_newton, y_range, 
				  label="f(x)",
				  linewidth=2, color=:blue,
				  xlabel="x", ylabel="f(x)",
				  title="Newton - Iter $iter_newton/$n_iter_newton")
			
			hline!(p[2], [0], label="", color=:black, linestyle=:dash, linewidth=1)
			
			x_i = hist_puntos_newton[min(i, length(hist_puntos_newton))]
			scatter!(p[2], [x_i], [f(x_i)], color=:green, markersize=8, 
					markershape=:star5, label="xₙ = $(round(x_i, digits=6))")
			
			# Tangente
			if iter_newton > 0 && iter_newton <= length(hist_tangentes)
				x_tang, y_tang, m_tang = hist_tangentes[iter_newton]
				x_tang_range = LinRange(x_tang - 0.3, x_tang + 0.3, 50)
				y_tang_range = y_tang .+ m_tang .* (x_tang_range .- x_tang)
				plot!(p[2], x_tang_range, y_tang_range, 
					  color=:red, linestyle=:dash, linewidth=2, label="Tangente")
				
				if i < length(hist_puntos_newton)
					x_next = hist_puntos_newton[i+1]
					scatter!(p[2], [x_next], [0], color=:orange, markersize=6, 
							markershape=:diamond, label="xₙ₊₁")
				end
			end
			
			# Historial
			if iter_newton > 0
				scatter!(p[2], hist_puntos_newton[1:min(i, length(hist_puntos_newton)-1)], 
						f.(hist_puntos_newton[1:min(i, length(hist_puntos_newton)-1)]), 
						color=:gray, markersize=3, alpha=0.4, label="")
			end
			
			annotate!(p[2], x_min_newton + 0.1, maximum(y_range) * 0.9, 
					 text("f(xₙ): $(round(f(x_i), digits=6))", :left, 9))
		else
			plot!(p[2], x_range_newton, f.(x_range_newton), 
				  linewidth=2, color=:blue,
				  xlabel="x", ylabel="f(x)",
				  title="Newton - COMPLETADO ($n_iter_newton iter)")
			hline!(p[2], [0], color=:black, linestyle=:dash, linewidth=1, label="")
			scatter!(p[2], [raiz_newton], [f(raiz_newton)], color=:green, markersize=10, 
					markershape=:star5, label="Raíz: $(round(raiz_newton, digits=6))")
		end
	end
	
	return anim, raiz_bis, raiz_newton, n_iter_bis, n_iter_newton
end

# ============================================================
# EJECUCIÓN PRINCIPAL
# ============================================================

println("=" ^ 70)
println("GENERACIÓN DE ANIMACIONES: Bisección vs Newton-Raphson")
println("Función: f(x) = 12x - 3x⁴ - 2x⁶")
println("=" ^ 70)
println()

# Parámetros
a = 1.0
b = 2.0
x0 = 1.5
tolerancia = 1e-6

println("CONFIGURACIÓN:")
println("  • Bisección - Intervalo: [$a, $b]")
println("  • Newton - Punto inicial: x₀ = $x0")
println("  • Tolerancia: $tolerancia")
println()

# ============================================================
# 1. ANIMACIÓN BISECCIÓN
# ============================================================
println("=" ^ 70)
println("1. GENERANDO ANIMACIÓN DE BISECCIÓN")
println("=" ^ 70)
anim_bis, raiz_bis, iter_bis = animar_biseccion(f, a, b, tolerancia)
gif(anim_bis, "biseccion_animacion.gif", fps=2)
println("✓ Guardado: biseccion_animacion.gif")
println("  • Raíz: $(round(raiz_bis, digits=8))")
println("  • Iteraciones: $iter_bis")
println()

# ============================================================
# 2. ANIMACIÓN NEWTON-RAPHSON
# ============================================================
println("=" ^ 70)
println("2. GENERANDO ANIMACIÓN DE NEWTON-RAPHSON")
println("=" ^ 70)
anim_newton, raiz_newton, iter_newton = animar_newton(f, df, x0, tolerancia)
gif(anim_newton, "newton_animacion.gif", fps=2)
println("✓ Guardado: newton_animacion.gif")
println("  • Raíz: $(round(raiz_newton, digits=8))")
println("  • Iteraciones: $iter_newton")
println()

# ============================================================
# 3. ANIMACIÓN COMPARATIVA
# ============================================================
println("=" ^ 70)
println("3. GENERANDO ANIMACIÓN COMPARATIVA (LADO A LADO)")
println("=" ^ 70)
anim_comp, r_bis, r_newton, it_bis, it_newton = animar_comparacion(f, df, a, b, x0, tolerancia)
gif(anim_comp, "comparacion_animacion.gif", fps=2)
println("✓ Guardado: comparacion_animacion.gif")
println()

# ============================================================
# RESUMEN FINAL
# ============================================================
println("=" ^ 70)
println("✓ TODAS LAS ANIMACIONES GENERADAS EXITOSAMENTE")
println("=" ^ 70)
println()
println("ARCHIVOS GENERADOS:")
println("  1. biseccion_animacion.gif")
println("     • Muestra paso a paso el método de bisección")
println("     • Visualiza cómo el intervalo se reduce a la mitad")
println("     • $it_bis iteraciones, 2 fps")
println()
println("  2. newton_animacion.gif")
println("     • Muestra paso a paso el método de Newton-Raphson")
println("     • Visualiza las líneas tangentes en cada iteración")
println("     • $it_newton iteraciones, 2 fps")
println()
println("  3. comparacion_animacion.gif")
println("     • Compara ambos métodos lado a lado")
println("     • Muestra la velocidad de convergencia de cada uno")
println("     • $(max(it_bis, it_newton)) frames, 2 fps")
println()
println("COMPARACIÓN FINAL:")
println("  • Bisección: $it_bis iteraciones → $(round(r_bis, digits=8))")
println("  • Newton: $it_newton iteraciones → $(round(r_newton, digits=8))")
println("  • Ventaja de Newton: $(round(it_bis/it_newton, digits=1))x más rápido")
println("=" ^ 70)
