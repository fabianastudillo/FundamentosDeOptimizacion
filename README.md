# Fundamentos de Optimización

Este repositorio contendrá el código y los materiales generados durante las clases de
"Fundamentos de Optimización" de la Maestría en Matemática Aplicada de la
UNACH.

## Propósito

El objetivo principal es organizar y preservar los ejemplos, notebooks, ejercicios e
implementaciones que se desarrollen en las sesiones de la asignatura. Será útil para
estudiantes, docentes y cualquier persona interesada en reproducir y aprender los
conceptos vistos en clase.

## Estructura sugerida

- `notebooks/` - Jupyter notebooks usados en clase.
- `src/` - Código fuente en Julia (o el lenguaje que se utilice) con módulos y scripts.
- `data/` - Conjuntos de datos (si aplica) o scripts para descargar/transformar datos.
- `examples/` - Pequeños ejemplos y ejercicios resueltos.

La estructura puede evolucionar con el tiempo; estos son solo carpetas iniciales.

## Cómo usar

1. Clona el repositorio:

	git clone https://github.com/fabianastudillo/FundamentosDeOptimizacion.git

2. Revisa los notebooks en `notebooks/` o el código en `src/` según la clase correspondiente.

3. Si hay dependencias (por ejemplo, para ejecutar notebooks), se añadirá un archivo
	`requirements.txt` o `environment.yml` en futuras actualizaciones.

## Instalación

A continuación se muestran pasos básicos para instalar Julia y las dependencias necesarias
para ejecutar los ejemplos en este repositorio en Ubuntu y en Windows.

### Ubuntu (20.04 / 22.04 y similares)

Opción A — instalar desde los paquetes del sistema (rápido):

```bash
sudo apt update
sudo apt install julia lld glpk-utils libglpk-dev
```

Opción B — instalar la última versión oficial de Julia (recomendado para reproducibilidad):

1. Descarga el instalador o tarball desde https://julialang.org/downloads/ y sigue las
	 instrucciones de la web.
2. Añade Julia al `PATH` (si el instalador no lo hace automáticamente) o crea un enlace
	 simbólico en `/usr/local/bin`.

Instalar paquetes Julia necesarios (desde shell):

```bash
julia -e 'using Pkg; Pkg.add.("JuMP"); Pkg.add.("GLPK"); Pkg.add.("Plots")'
```

Notas útiles en Ubuntu:
- Si ves errores relacionados con "lld" o linking, instala `lld` con `sudo apt install lld`.
- Para GLPK (si usas bindings que requieran la librería del sistema) asegúrate de tener
	`libglpk-dev` o `glpk-utils` instalados.

### Windows (10 / 11)

1. Descarga el instalador de Julia desde https://julialang.org/downloads/ y ejecútalo.
	 Durante la instalación puedes marcar "Add Julia to PATH" para acceder a Julia desde la
	 terminal.

2. Abre la aplicación `Julia` (REPL) o una terminal PowerShell y añade los paquetes:

```powershell
julia -e "using Pkg; Pkg.add.(\"JuMP\"); Pkg.add.(\"GLPK\"); Pkg.add.(\"Plots\")"
```

3. Ejecuta el ejemplo desde la carpeta del repositorio:

```powershell
julia examples/ejemplo1.jl
```

Notas útiles en Windows:
- En general los paquetes como `GLPK.jl` entregan binarios con BinaryProvider/Artifacts y
	no requieren instalar GLPK manualmente, pero si tienes problemas revisa la salida de Pkg
	y añade cualquier dependencia que indique.
- Si trabajas con WSL (Windows Subsystem for Linux), sigue las instrucciones de Ubuntu
	dentro de la instancia WSL y ejecuta Julia desde allí para un entorno más cercano a Linux.


## Contribuciones

Las contribuciones son bienvenidas. Si tienes material o correcciones, abre un pull
request o contacta al autor del repositorio.

## Licencia

Este proyecto está licenciado bajo la Apache License 2.0. Revisa el archivo
`LICENSE` en la raíz del repositorio para los términos completos.

Licencia: Apache License 2.0 — http://www.apache.org/licenses/LICENSE-2.0

---

Repositorio creado para documentar y versionar el trabajo práctico y los ejemplos
de la asignatura "Fundamentos de Optimización" (Maestría en Matemática Aplicada, UNACH).