"""
hessiana.jl

Calcula la Hessiana de f(x,y)=x^3 - 2 x y - y^6 en el punto (1,2).
Se muestra la expresión analítica de las segundas derivadas y una verificación
numérica por diferencias finitas.

Ejecución:
    julia examples/hessiana.jl

"""

# Necesitamos LinearAlgebra para determinantes y autovalores
using LinearAlgebra

# Función f toma un vector x = [x, y]
function f_vec(v)
    x = v[1]
    y = v[2]
    return x^3 - 2*x*y - y^6
end

# Derivadas parciales analíticas de segundo orden (funciones explícitas)
"""
    f_xx(x, y)

Segunda derivada parcial respecto a x: ∂²f/∂x² = 6x
"""
function f_xx(x, y)
    return 6.0 * x
end

"""
    f_xy(x, y)

Derivada mixta: ∂²f/∂x∂y = -2
"""
function f_xy(x, y)
    return -2.0
end

"""
    f_yx(x, y)

Derivada mixta en orden invertido: ∂²f/∂y∂x = -2 (igual a f_xy por teorema de Schwarz)
"""
function f_yx(x, y)
    return -2.0
end

"""
    f_yy(x, y)

Segunda derivada parcial respecto a y: ∂²f/∂y² = -30 y^4
"""
function f_yy(x, y)
    return -30.0 * y^4
end

function hessian_analitica(x, y)
    # Construimos la Hessiana usando las funciones de derivadas parciales.
    # Usamos f_xy y f_yx por separado para dejar explícita la simetría.
    return [f_xx(x,y) f_xy(x,y); f_yx(x,y) f_yy(x,y)]
end

# Verificación por diferencias finitas centrales
function hessian_fd(fun, v; h=1e-6)
    n = length(v)
    H = zeros(n, n)
    # central second differences
    for i in 1:n
        for j in i:n
            ei = zeros(n); ej = zeros(n)
            ei[i] = 1.0; ej[j] = 1.0
            if i == j
                # second derivative wrt i twice
                H[i,i] = ( fun(v + h*ei) - 2*fun(v) + fun(v - h*ei) ) / (h^2)
            else
                # mixed partial derivative: d^2 f / (dx_i dx_j)
                H_ij = ( fun(v + h*ei + h*ej) - fun(v + h*ei - h*ej) - fun(v - h*ei + h*ej) + fun(v - h*ei - h*ej) ) / (4*h^2)
                H[i,j] = H_ij
                H[j,i] = H_ij
            end
        end
    end
    return H
end

# Punto de interés
pt = [1.0, 2.0]

println("Punto evaluado: (x, y) = ($(pt[1]), $(pt[2]))")

H_anal = hessian_analitica(pt[1], pt[2])
println("Hessiana analítica:")
println(H_anal)

H_num = hessian_fd(f_vec, pt; h=1e-6)
println("Hessiana (diferencias finitas, h=1e-6):")
println(H_num)

# Diferencia absoluta
diff = abs.(H_anal - H_num)
println("Diferencia absoluta (analítica - numérica):")
println(diff)

# Mark todos done by printing a short summary
println("\nResumen:")
println("  f_xx(1,2) = ", H_anal[1,1])
println("  f_xy(1,2) = ", H_anal[1,2])
println("  f_yx(1,2) = ", f_yx(pt[1], pt[2]))
println("  f_yy(1,2) = ", H_anal[2,2])

# Comprobación de simetría (f_xy == f_yx)
is_equal = isapprox(H_anal[1,2], H_anal[2,1]; atol=1e-12, rtol=0)
println("\nComprobación: f_xy == f_yx? ", is_equal)

# --------------------
# Análisis de determinantes y definitud
# --------------------
function classify_hessian(H; tol=1e-8)
    # autovalores
    vals = eigen(H).values
    minv = minimum(vals)
    maxv = maximum(vals)
    # Clasificación basada en signos de autovalores
    if minv > tol
        return "Positiva definida (todos los autovalores > 0)"
    elseif maxv < -tol
        return "Negativa definida (todos los autovalores < 0)"
    elseif all(abs.(vals) .<= tol)
        return "Nula (todos los autovalores ≈ 0)"
    else
        # revisar semidefinida
        if minv >= -tol && maxv > tol
            # some zero or positive, none negative beyond tol
            if minv >= -tol
                return "Positiva semidefinida (ningún autovalor negativo)"
            end
        elseif maxv <= tol && minv < -tol
            return "Negativa semidefinida (ningún autovalor positivo)"
        end
        return "Indefinida (autovalores de signos mixtos)"
    end
end

det_H = det(H_anal)
minor1 = H_anal[1,1]

println("\nAnálisis de determinantes y definitud:")
println("  Menor principal de orden 1 (f_xx): ", minor1)
println("  Determinante det(H): ", det_H)
println("  Autovalores de H: ", eigen(H_anal).values)
println("  Clasificación: ", classify_hessian(H_anal))

# Cálculo de menores principales líderes (Sylvester)
function leading_principal_minors(H)
    n = size(H,1)
    D = Float64[]
    for k in 1:n
        push!(D, det(H[1:k,1:k]))
    end
    return D
end

function sylvester_test(H; tol=1e-12)
    # Devuelve la clasificación según los menores principales líderes
    D = leading_principal_minors(H)
    n = length(D)
    # Positiva definida: todos D_k > 0
    if all(D .> tol)
        return ("Positiva definida", D)
    end
    # Negativa definida: (-1)^k * D_k > 0 para todo k (alternancia)
    signs_ok = true
    for k in 1:n
        if ((-1.0)^k * D[k]) <= tol
            signs_ok = false
            break
        end
    end
    if signs_ok
        return ("Negativa definida", D)
    end
    return ("No satisface Sylvester (no definida según menores líderes)", D)
end

# Aplicar prueba de Sylvester y clasificar punto crítico
syl_label, Dlist = sylvester_test(H_anal)
println("\nPrueba de Sylvester (menores principales líderes):")
for (k, val) in enumerate(Dlist)
    println("  D_$(k) = ", val)
end
println("  Resultado Sylvester: ", syl_label)

# Clasificación del punto crítico usando la Hessiana
crit_class = "Indeterminado"
if syl_label == "Positiva definida"
    crit_class = "Mínimo local (H positiva definida)"
elseif syl_label == "Negativa definida"
    crit_class = "Máximo local (H negativa definida)"
else
    # usar autovalores para detectar silla
    vals = eigen(H_anal).values
    if any(vals .> 0) && any(vals .< 0)
        crit_class = "Punto silla (H indefinida)"
    elseif all(abs.(vals) .<= 1e-12)
        crit_class = "Hessiana nula (degenerado/inconcluso)"
    else
        crit_class = "Semidefinida o degenerado (inconcluso)"
    end
end
println("\nClasificación del punto crítico en (1,2): ", crit_class)

