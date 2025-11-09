"""
ejemplo1.jl

Ejemplo mínimo de modelado lineal usando JuMP y GLPK.

Propósito:
 - Mostrar cómo declarar variables, objetivo y restricciones en JuMP.
 - Resolver el problema y guardar un gráfico sencillo con la solución.

Dependencias:
 - Julia (>= 1.x)
 - Paquetes: JuMP, GLPK, Plots

Instalación rápida (desde REPL):
	] add JuMP GLPK Plots

Ejecución:
	julia examples/ejemplo1.jl

Descripción del modelo:
 - Variables: x en [0,4], y en [0,6]
 - Objetivo: maximizar 3*x + 5*y
 - Restricción: 3*x + 2*y <= 18

Salida:
 - Imprime el valor objetivo y las variables.
 - Guarda un gráfico simple en `plot.pdf` mostrando la recta de restricción
	 y una línea horizontal de referencia.

Notas:
 - El nombre `xs` se usa para el vector de puntos en el plotting para evitar
	 sombrear/solapar la variable JuMP `x` (evita sombras de nombres).
"""

using JuMP, GLPK
using Plots

# Crear modelo con GLPK
m = Model(GLPK.Optimizer)

# Variables de decisión
@variable(m, 0 <= x <= 4)
@variable(m, 0 <= y <= 6)

# Objetivo (maximización)
@objective(m, Max, 3*x + 5*y)

# Restricciones
# (ejemplo de restricción lineal)
#@constraint(m, 9x^2 + 5y^2 <= 216.0 )
@constraint(m, 3x + 2y <= 18)

# Resolver el modelo
JuMP.optimize!(m)

# Mostrar resultados en consola
println("Objective value: ", JuMP.objective_value(m))
println("x = ", JuMP.value(x))
println("y = ", JuMP.value(y))

# Preparar datos para dibujo (no sobreescribir la variable `x` del modelo)
xs = LinRange(0, 6, 61) # puntos para trazar la recta

# Recta derivada de 3*x + 2*y = 18 -> y = (18 - 3x)/2 = 9 - 1.5x
plot(xs, 9 .- 1.5 .* xs, label = "Restricción: 3x + 2y = 18", color = :red)

# Línea horizontal de referencia en y = 6 (límite superior de y)
hline!([6], label = "y = 6", color = :green)

# Marcar la solución óptima en el gráfico
scatter!([JuMP.value(x)], [JuMP.value(y)], label = "Óptimo", color = :blue)

# Guardar figura
savefig("plot.pdf")
