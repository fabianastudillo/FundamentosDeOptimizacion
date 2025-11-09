"""
ejemplo2.jl

Ejemplo de optimización no lineal usando JuMP e Ipopt.

Descripción:
 - Variables: vector `x[1:2]` (dos variables reales).
 - Función objetivo (no lineal): minimizar (x1 - 3)^3 + (x2 - 4)^2.
 - Restricción no lineal: (x1 - 1)^2 + (x2 + 1)^3 + exp(-x1) <= 1.

Este archivo muestra la sintaxis básica para problemas no lineales en JuMP:
 - `@NLobjective` para la función objetivo no lineal.
 - `@NLconstraint` para restricciones no lineales.

Dependencias: JuMP, Ipopt
Instalación rápida (REPL):
	] add JuMP Ipopt

Ejecución:
	julia examples/ejemplo2.jl

Notas:
 - Ipopt es un solver para problemas de optimización no lineal; en muchos casos
	 se instala automáticamente como artefacto de `Ipopt.jl`, pero puede requerir
	 dependencias del sistema en entornos particulares.
 - Si el solver no converge o da errores, revisa el estado de terminación y la
	 salida del solver para diagnosticar (tolerancias, derivadas, puntos iniciales).
"""

using JuMP, Ipopt

# Crear el modelo con Ipopt
m = Model(Ipopt.Optimizer)

## Asi se declara un problema de optimizacion no lineal (tanto la FO como las restricciones)
@variable(m, x[1:2])
# si la funcion objetivo es no lineal se usa la macro @NLobjective
@NLobjective(m, Min, (x[1]-3)^3 + (x[2]-4)^2)

# si la restricciones no son lineales se usa la macro @NLconstraint
@NLconstraint(m, (x[1]-1)^2 + (x[2]+1)^3 + exp(-x[1]) <= 1)


## Asi se declara un problema de optimizacion lineal (tanto la FO como las restricciones
## Declaring variables
#@variable(m, 0<= x1 <=10)
#@variable(m, x2 >=0)
#@variable(m, x3 >=0)

## Setting the objective
# Si el objetivo es lineal se usa la macro @objective
#@objective(m, Max, x1 + 2x2 + 5x3)

## Adding constraints
# Si las restricciones son lineales se usa la macro @constraint
#@constraint(m, constraint1, -x1 +  x2 + 3x3 <= -5)
#@constraint(m, constraint2,  x1 + 3x2 - 7x3 <= 10)

JuMP.optimize!(m)

status = JuMP.termination_status(m)
println("Termination status: ", status)

if JuMP.is_terminated(m)
		println("Objective value = ", JuMP.objective_value(m))
		println("Solution x = ", JuMP.value.(x))
else
		println("El solver no terminó correctamente. Revisa la salida del solver para más detalles.")
end