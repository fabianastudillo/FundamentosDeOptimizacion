#!/usr/bin/env julia
################################################################################
# Curvas de nivel de alta calidad usando CairoMakie:
#   f(x,y) = xy + 4y - 3x^2 - y^2
#
# Requisitos:
#  - CairoMakie.jl (backend vectorial de alta calidad, no requiere display)
#
# Uso:
#  julia examples/curvas_nivel-ejemplo4.jl
#  Genera `examples/curvas_nivel-ejemplo4.png` de alta resolución.
################################################################################

using CairoMakie

# Definir la función
f(x, y) = x*y + 4*y - 3*x^2 - y^2

# Rango y resolución
n = 400  # resolución alta para curvas suaves
xs = LinRange(-2.0, 2.0, n)
ys = LinRange(-2.0, 3.0, n)

# Construir la malla Z
Z = [f(x, y) for x in xs, y in ys]

# Punto máximo (analíticamente calculado)
# ∂f/∂x = y - 6x = 0 => y = 6x
# ∂f/∂y = x + 4 - 2y = 0 => x + 4 - 12x = 0 => x = 4/11
x_max = 4/11
y_max = 24/11

# Crear figura con tema mejorado y alta resolución
set_theme!(theme_latexfonts(), fontsize = 20)

fig = Figure(size = (1200, 1000), fontsize = 20)
ax = Axis(fig[1, 1];
    xlabel = "x",
    ylabel = "y",
    title = L"Curvas de nivel: $f(x,y) = xy + 4y - 3x^2 - y^2$",
    titlesize = 32,
    xlabelsize = 22,
    ylabelsize = 22,
    aspect = DataAspect())

# Curvas de nivel con colormap :viridis
contourf!(ax, xs, ys, Z;
    colormap = :viridis,
    levels = 20)  # 20 niveles de contorno

# Líneas de contorno negras para mayor claridad
contour!(ax, xs, ys, Z;
    color = :black,
    linewidth = 1.0,
    levels = 20,
    linestyle = :solid)

# Marcar el punto inicial (0,0) con un punto rojo
scatter!(ax, [0.0], [0.0]; 
    color = :red, 
    markersize = 15,
    strokecolor = :black,
    strokewidth = 1.5)

# Etiquetar el punto inicial
text!(ax, 0.0, 0.0;
    text = L"$(x_0, y_0)$",
    fontsize = 24,
    align = (:left, :bottom),
    offset = (10, 10),  # desplazar texto hacia arriba-derecha
    color = :black)

# Flecha desde (0,0) al máximo (1/5 del tamaño, doble de gruesa)
arrows!(ax, [0.0], [0.0], [x_max], [y_max];
    color = :blue,
    linewidth = 6,
    arrowsize = 20,
    lengthscale = 0.2)

# Calcular el punto en la punta de la flecha (1/5 del camino hacia el máximo)
x1 = 0.0 + 0.2 * x_max
y1 = 0.0 + 0.2 * y_max

# Marcar el punto en la punta de la flecha
scatter!(ax, [x1], [y1]; 
    color = :red, 
    markersize = 15,
    strokecolor = :black,
    strokewidth = 1.5)

# Etiquetar el punto en la punta de la flecha
text!(ax, x1, y1;
    text = L"$(x_1, y_1)$",
    fontsize = 24,
    align = (:left, :bottom),
    offset = (10, 10),
    color = :black)

# Marcar el punto máximo
scatter!(ax, [x_max], [y_max]; 
    color = :orange, 
    markersize = 15,
    strokecolor = :black,
    strokewidth = 1.5)

# Etiquetar el máximo
text!(ax, x_max, y_max;
    text = L"$\mathrm{máximo}$",
    fontsize = 24,
    align = (:left, :bottom),
    offset = (10, 10),
    color = :black)

# Barra de color con etiqueta
Colorbar(fig[1, 2], 
    label = "z", 
    labelsize = 22,
    ticklabelsize = 18,
    colormap = :viridis,
    limits = (minimum(Z), maximum(Z)))

# Guardar PNG de alta resolución
save("examples/curvas_nivel-ejemplo4.png", fig; px_per_unit = 3)
println("✓ Figura guardada en: examples/graficar3d-ejemplo4-paso5.png (alta resolución)")
println("  Tamaño: 1200×1000 @ 3× = 3600×3000 px efectivos")

# Opcional: guardar versiones vectoriales (PDF, SVG)
# save("examples/curvas_nivel-ejemplo4.pdf", fig)
# save("examples/curvas_nivel-ejemplo4.svg", fig)
