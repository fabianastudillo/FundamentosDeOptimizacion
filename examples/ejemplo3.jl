using JuMP
using GLPK

# Definir el modelo de optimización
model = Model(GLPK.Optimizer)

# Variables de decisión no negativas (x1, x2, s1, s2, s3)
@variable(model, x1 >= 0)
@variable(model, x2 >= 0)
@variable(model, s1 >= 0) # Variable de holgura para la restricción 1
@variable(model, s2 >= 0) # Variable de holgura para la restricción 2
@variable(model, s3 >= 0) # Variable de holgura para la restricción 3

# Función objetivo (min c'x)
# Asumiendo que el problema original era 'Maximizar 3x1 + 5x2'
# lo convertimos a 'Minimizar -3x1 - 5x2'
@objective(model, Min, -3*x1 - 5*x2)

# Restricciones en forma de igualdad (Ax = b)
@constraint(model, con1, x1 + s1 == 4)
@constraint(model, con2, 2*x2 + s2 == 12)
@constraint(model, con3, 3*x1 + 2*x2 + s3 == 18)

# Resolver el problema
optimize!(model)

# Imprimir los resultados
println("Estado de la solución: ", JuMP.primal_status(model))
println("Valor óptimo de la función objetivo: ", JuMP.objective_value(model))
println("Valor de x1: ", JuMP.value(x1))
println("Valor de x2: ", JuMP.value(x2))
println("Valor de s1: ", JuMP.value(s1))
println("Valor de s2: ", JuMP.value(s2))
println("Valor de s3: ", JuMP.value(s3))