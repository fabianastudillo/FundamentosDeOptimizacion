# Nombres
# El cambio de alfa

using JuMP, Ipopt
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

println("** Optimal objective function value = ", JuMP.objective_value(m))
println("** Optimal solution = ", JuMP.value.(x))