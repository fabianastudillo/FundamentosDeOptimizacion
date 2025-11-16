
#!/usr/bin/env julia
################################################################################
# Gráfica 3D de alta calidad usando CairoMakie:
#   z(x,y) = 6 * exp(-3x^2 - y^2) + x/2 + y
#
# Requisitos:
#  - CairoMakie.jl (backend vectorial de alta calidad, no requiere display)
#
# Uso:
#  julia examples/graficar3d.jl
#  Genera `examples/graficar3d.png` (y opcionalmente .pdf/.svg) de alta resolución.
#
# Nota: Para visualización interactiva con rotación 3D en vivo, usa GLMakie
#       (requiere servidor X activo). CairoMakie genera imágenes estáticas
#       de calidad de publicación.
################################################################################

using CairoMakie

# Definir la función
f(x, y) = 6 * exp(-3x^2 - y^2) + x/2 + y

# Rango solicitado: -3 .. 3 usando LinRange
n = 400  # resolución alta para superficie suave
xs = LinRange(-2.0, 2.0, n)
ys = LinRange(-2.0, 3.0, n)

# Construir la malla Z (nota: en Makie, Z[i,j] = f(xs[i], ys[j]))
Z = [f(x, y) for x in xs, y in ys]

# Crear figura con tema mejorado y alta resolución
set_theme!(theme_latexfonts(), fontsize = 20)  # fuentes estilo LaTeX

fig = Figure(size = (1400, 1000), fontsize = 20)
ax = Axis3(fig[1, 1];
    xlabel = "x",
    ylabel = "y",
    zlabel = "z",
    title = L"z(x,y) = 6e^{-3x^2 - y^2} + \frac{x}{2} + y",
    titlesize = 48,
    titlegap = -60,  # Reducir espacio entre título y gráfico (bajarlo)
    xlabelsize = 22,
    ylabelsize = 22,
    zlabelsize = 22,
    azimuth = 1.2π,     # ángulo horizontal (~216°, vista desde atrás-derecha)
    elevation = 0.15π,  # ángulo vertical (~27°)
    aspect = (1, 1, 0.5),  # z tiene la mitad del tamaño de x e y
    perspectiveness = 0.5,
    limits = (nothing, nothing, (-4, 8)))  # Fijar límites de z entre -4 y 8

# Superficie 3D con colormap :viridis y sombreado suave
surface!(ax, xs, ys, Z;
    colormap = :viridis,
    shading = Makie.MultiLightShading,  # sombreado múltiple (realista)
    interpolate = true,                  # interpolación suave de colores
    transparency = false)

# Agregar malla cuadriculada sobre la superficie
wireframe!(ax, xs, ys, Z;
    color = (:black, 0.15),  # negro semi-transparente
    linewidth = 0.5,
    overdraw = true)  # dibujar encima de la superficie

# Barra de color con etiqueta
Colorbar(fig[1, 2], 
    label = "z", 
    labelsize = 22,
    ticklabelsize = 18,
    colormap = :viridis, 
    limits = (-4, 8))  # Rango de z fijo entre -4 y 8

# Guardar PNG de muy alta resolución (también PDF/SVG si quieres)
save("examples/graficar3d-ejemplo1.png", fig; px_per_unit = 3)  # 3× resolución base
println("✓ Figura guardada en: examples/graficar3d-ejemplo1.png (alta resolución)")
println("  Tamaño: 1400×1000 @ 3× = 4200×3000 px efectivos")

# Opcional: guardar versiones vectoriales (PDF, SVG)
# save("examples/graficar3d.pdf", fig)
# save("examples/graficar3d.svg", fig)
