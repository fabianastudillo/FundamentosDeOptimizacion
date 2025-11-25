"""
Algoritmos Genéticos con Evolutionary.jl
========================================

Este script demuestra el uso de algoritmos genéticos para optimización de funciones
utilizando la biblioteca Evolutionary.jl de Julia.

CONCEPTOS PRINCIPALES:
- Población: Conjunto de soluciones candidatas
- Selección: Proceso de elegir individuos para reproducción
- Cruzamiento: Combinación de características de dos padres
- Mutación: Modificación aleatoria para mantener diversidad
- Elitismo: Preservación de los mejores individuos
- Presión selectiva: Intensidad de la selección hacia mejores individuos

OPCIONES DE CONFIGURACIÓN:
- populationSize: Tamaño de la población (típicamente 50-200)
- crossoverRate: Probabilidad de cruzamiento (típicamente 0.6-0.9)
- mutationRate: Probabilidad de mutación (típicamente 0.01-0.1)
- ɛ (epsilon): Tamaño del elitismo (número de mejores individuos preservados)
- iterations: Número máximo de iteraciones
- abstol: Tolerancia absoluta para convergencia
- reltol: Tolerancia relativa para convergencia

FUNCIONES DE PRUEBA:
- Función cuadrática simple: f(x) = sum(x.^2) [Óptimo: origen]
- Función objetivo con desplazamiento: f(x) = (x[1]-5)^2 + (x[2]-6)^2 [Óptimo: (5,6)]
- Función de Rosenbrock: f(x) = (1-x[1])^2 + 100*(x[2]-x[1]^2)^2 [Óptimo: (1,1)]
- Función de Griewank: f(x) = (1/4000)*sum(x²) - prod(cos(x/√i)) + 1 [Multimodal]
- Función de Rastrigin: f(x) = 10n + sum(x² - 10cos(2πx)) [Altamente multimodal]
- Función de Ackley: f(x) = -20exp(-0.2√(sum(x²)/n)) - exp(sum(cos(2πx))/n) + 20 + e
- Función de Schwefel: f(x) = 418.9829n - sum(x*sin(√|x|))
- Función de Sphere: f(x) = sum(x²) [Convexa unimodal]

OPERADORES DISPONIBLES:
Selección:
- susinv: Selección por ranking estocástico universal inverso
- uniformranking(n): Ranking uniforme con presión selectiva n
- roulette: Selección por ruleta (proporcional a fitness)
- tournament(k): Torneo con k individuos
- truncation(T): Selección por truncamiento con fracción T
- sus: Muestreo estocástico universal
- rws: Selección por ruleta ponderada
- linear(s): Ranking lineal con presión s
- nonlinear(α): Ranking no lineal con parámetro α

Cruzamiento:
- DC: Cruzamiento diferencial
- SPX: Cruzamiento simplex
- uniformbin: Cruzamiento binario uniforme
- intermediate(α): Cruzamiento intermedio con parámetro α
- UNDX(n,σ): Cruzamiento direccional unimodal normal distribuido
- PCX(η,ζ): Cruzamiento de centros parentales
- average: Cruzamiento promedio
- discrete: Cruzamiento discreto
- heuristic(α): Cruzamiento heurístico con factor α
- laplace(a,b): Cruzamiento de Laplace con parámetros a,b
- SBX(η): Cruzamiento binario simulado con índice η

Mutación:
- PLM(η): Mutación de línea polinomial con índice η
- gaussian(σ): Mutación gaussiana con desviación σ
- flip: Mutación por intercambio de bits
- uniform(range): Mutación uniforme en rango especificado
- PM(η): Mutación polinomial con índice de distribución η
- BGA(σ,p): Mutación del algoritmo genético de Breeder con σ y probabilidad p
- power(k): Mutación de potencia con exponente k
- domainrange(bounds): Mutación dentro de los límites del dominio
- cauchy(γ): Mutación de Cauchy con parámetro de escala γ
- laplace(b): Mutación de Laplace con parámetro de dispersión b
"""

using Evolutionary
using LinearAlgebra  # Para la función norm()

# =============================================================================
# EJEMPLOS DE FUNCIONES DE OPTIMIZACIÓN
# =============================================================================

# Función cuadrática simple - Óptimo en el origen (0,0,...)
# Usada para probar convergencia básica del algoritmo
#función_cuadrática(x) = sum(x.^2)

# Función con óptimo desplazado - Óptimo en (5,6)
# Útil para probar la capacidad de encontrar óptimos no centrados
#función_desplazada(x) = (x[1]-5)^2 + (x[2]-6)^2

# Función de Rosenbrock - Función de prueba clásica en optimización
# Óptimo global en (1,1) con valor 0
# Características: valle estrecho, difícil de optimizar
funcion_rosenbrock(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2
funcion_griewank(x) = (1.0/4000) * sum(x.^2) - prod(cos.(x ./ sqrt.(1:length(x)))) + 1
funcion_rastrigin(x) = 10length(x) + sum(x.^2 .- 10cos.(2pi .* x))


# =============================================================================
# CONFIGURACIÓN DEL ALGORITMO GENÉTICO
# =============================================================================

# Punto inicial (puede ser cualquier punto factible)
x0 = [1.0, 1.0]

# Configuración del algoritmo genético
println("Optimizando función de Rosenbrock con Algoritmo Genético...")
println("Función objetivo: f(x) = (1-x₁)² + 100(x₂-x₁²)²")
println("Óptimo teórico: x* = (1,1), f(x*) = 0")
println("="^50)

resultado = Evolutionary.optimize(
    funcion_rosenbrock,           # Función objetivo a minimizar
    x0,                          # Punto inicial
    GA(                          # Algoritmo Genético con parámetros:
        populationSize = 100,     # Tamaño de población: 100 individuos
        selection = susinv,       # Selección: ranking estocástico universal inverso
        crossover = DC,           # Cruzamiento: diferencial
        mutation = PLM()          # Mutación: línea polinomial
    )
)

# =============================================================================
# CONFIGURACIONES ALTERNATIVAS (COMENTADAS)
# =============================================================================

# Ejemplo 1: Configuración con ranking uniforme
#ga_ranking = GA(
#    populationSize = 100,
#    selection = uniformranking(5),    # Ranking uniforme con presión 5
#    mutation = flip,                  # Mutación por intercambio
#    crossover = SPX                   # Cruzamiento simplex
#)

# Ejemplo 2: Configuración con mutación gaussiana
#ga_gaussiano = GA(
#    populationSize = 100,
#    selection = uniformranking(3),    # Ranking uniforme con presión 3
#    mutation = gaussian(),            # Mutación gaussiana
#    crossover = uniformbin()          # Cruzamiento binario uniforme
#)

# Ejemplo 3: Con opciones de iteración específicas
#opciones = Evolutionary.Options(iterations=10)
#resultado_limitado = Evolutionary.optimize(funcion_rosenbrock, x0, ga_ranking, opciones)

# =============================================================================
# ANÁLISIS DE RESULTADOS
# =============================================================================

println("\n📊 RESULTADOS DE LA OPTIMIZACIÓN:")
println("="^50)
print(resultado)

println("\n🎯 SOLUCIÓN ENCONTRADA:")
sol_encontrada = Evolutionary.minimizer(resultado)
println("x* = $(sol_encontrada)")
println("f(x*) = $(funcion_rosenbrock(sol_encontrada))")

println("\n📈 ANÁLISIS:")
println("• Iteraciones realizadas: $(resultado.iterations)")
println("• Evaluaciones de función: $(resultado.f_calls)")
println("• Valor final: $(resultado.minimum)")

# Calcular error respecto al óptimo teórico
optimo_teorico = [1.0, 1.0]
error = norm(sol_encontrada - optimo_teorico)
println("• Error respecto al óptimo teórico: $(round(error, digits=6))")

println("\n✨ La optimización ha finalizado exitosamente!")

# =============================================================================
# NOTAS ADICIONALES SOBRE LOS OPERADORES
# =============================================================================

"""
GUÍA DE SELECCIÓN DE OPERADORES:

1. SELECCIÓN:
   - susinv: Bueno para mantener diversidad, evita convergencia prematura
   - uniformranking(n): n alto = más presión selectiva, n bajo = más diversidad
   - tournament(k): Simple y efectivo, k típicamente entre 2-7
   - roulette: Clásico, sensible a diferencias grandes de fitness
   - truncation(T): Selección determinística, T=0.5 típico
   - linear(s): Presión selectiva controlable, s entre 1.1-2.0

2. CRUZAMIENTO:
   - DC (Diferencial): Excelente para optimización continua
   - SPX (Simplex): Bueno para problemas multimodales
   - uniformbin: Clásico para representaciones binarias
   - SBX(η): Muy efectivo, η=20 típico para exploración
   - UNDX: Preserva diversidad en alta dimensionalidad
   - PCX: Bueno para problemas de alta dimensión
   - intermediate(α): α=0.5 para promedio, α>0.5 para extrapolación

3. MUTACIÓN:
   - PLM(η): Adaptativa, η=20 típico, buena para ajuste fino
   - PM(η): Similar a PLM, distribución polinomial
   - gaussian(σ): σ pequeña para ajuste fino, σ grande para exploración
   - uniform(): Exploración amplia del espacio de búsqueda
   - BGA(σ,p): Buena para problemas complejos, σ=0.1, p=0.1
   - cauchy(γ): Mejor que gaussiana para escapar óptimos locales

RECOMENDACIONES POR TIPO DE PROBLEMA:

🎯 FUNCIONES UNIMODALES (Sphere, Rosenbrock):
   - Selección: susinv o uniformranking(3)
   - Cruzamiento: DC o SBX(20)
   - Mutación: PLM() o PM(20)
   - Configuración: población pequeña (50-100), alta tasa de cruzamiento

🌍 FUNCIONES MULTIMODALES (Rastrigin, Griewank):
   - Selección: tournament(3) o uniformranking(5)
   - Cruzamiento: SPX o UNDX
   - Mutación: gaussian(0.1) o cauchy(0.1)
   - Configuración: población grande (100-200), diversidad alta

🔬 PROBLEMAS DE ALTA DIMENSIÓN:
   - Selección: tournament(2) para mantener diversidad
   - Cruzamiento: UNDX o PCX
   - Mutación: BGA o gaussian adaptativa
   - Configuración: población muy grande, convergencia lenta

⚡ OPTIMIZACIÓN RÁPIDA:
   - Selección: truncation(0.5) o linear(2.0)
   - Cruzamiento: intermediate(0.5) o average
   - Mutación: uniform con rango pequeño
   - Configuración: alta presión selectiva, convergencia rápida

PARAMETROS TÍPICOS:
- Población: 50-200 individuos
- Tasa de cruzamiento: 0.7-0.9
- Tasa de mutación: 0.01-0.1
- Elitismo: 1-5% de la población
- Generaciones: 100-1000 dependiendo del problema
"""