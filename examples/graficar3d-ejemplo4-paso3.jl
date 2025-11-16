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

# Marcar el punto (0,0) con un punto rojo
scatter!(ax, [0.0], [0.0]; 
    color = :red, 
    markersize = 15,
    strokecolor = :black,
    strokewidth = 1.5)

# Etiquetar el punto
text!(ax, 0.0, 0.0;
    text = L"$(x_0, y_0)$",
    fontsize = 24,
    align = (:left, :bottom),
    offset = (10, 10),  # desplazar texto hacia arriba-derecha
    color = :black)

# Encontrar el punto mínimo de la función
min_idx = argmin(Z)
x_min = xs[min_idx[1]]
y_min = ys[min_idx[2]]
z_min = Z[min_idx]

# Marcar el punto mínimo
scatter!(ax, [x_min], [y_min]; 
    color = :cyan, 
    markersize = 15,
    strokecolor = :black,
    strokewidth = 1.5)

# Etiquetar el punto mínimo
text!(ax, x_min, y_min;
    text = L"$\text{mín}$",
    fontsize = 24,
    align = (:left, :top),
    offset = (10, -10),
    color = :black)

# Agregar flecha desde (0,0) hacia el mínimo
arrows!(ax, [0.0], [0.0], [x_min - 0.0], [y_min - 0.0];
    color = :red,
    linewidth = 3,
    arrowsize = 20,
    lengthscale = 0.9)  # 90% de la longitud para que no tape el punto

# Barra de color con etiqueta
Colorbar(fig[1, 2], 
    label = "z", 
    labelsize = 22,
    ticklabelsize = 18,
    colormap = :viridis,
    limits = (minimum(Z), maximum(Z)))

# Guardar PNG de alta resolución
save("examples/graficar3d-ejemplo4-paso3.png", fig; px_per_unit = 3)
println("✓ Figura guardada en: examples/graficar3d-ejemplo4-paso3.png (alta resolución)")
println("  Tamaño: 1200×1000 @ 3× = 3600×3000 px efectivos")
println("  Punto mínimo: ($(round(x_min, digits=3)), $(round(y_min, digits=3))) con z = $(round(z_min, digits=3))")

# Opcional: guardar versiones vectoriales (PDF, SVG)
# save("examples/curvas_nivel-ejemplo4.pdf", fig)
# save("examples/curvas_nivel-ejemplo4.svg", fig)
