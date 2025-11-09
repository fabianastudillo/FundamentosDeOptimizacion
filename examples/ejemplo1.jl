using JuMP, GLPK
using Plots
m = Model(GLPK.Optimizer)

@variable(m, 0 <= x <= 4 )
@variable(m, 0 <= y <= 6)

@objective(m, Max, 3*x + 5*y )

#@constraint(m, 9x^2 + 5y^2 <= 216.0 )
@constraint(m, 3x + 2y <= 18 )

JuMP.optimize!(m)

#plot!([value.(x)], [value.(y)], seriestype = :scatter, label="Optimum")

println("Objective value: ", JuMP.objective_value(m))
println("x = ", JuMP.value(x))
println("y = ", JuMP.value(y))

# Desde 0, hasta 6, numero de elementos
x=LinRange(0, 6, 7)
plot([x], [9 .- 1.5x], label = "G0", color = "red")
#plot!([0,6],[9,0], fillrange = 1, fillalpha = 0.05, fillcolor = "red", label = "")
hline!([6 6], label = "G1", color = "green")

savefig("plot.pdf")
