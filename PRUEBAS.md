# Pruebas del sistema

La [tabla actualizada del reporte](INFORME.md#tabla-de-pruebas-actualizada) reúne las entradas, los resultados esperados y los obtenidos en Windows. La secuencia parte de una carpeta vacía y conserva el estado entre operaciones.

Para repetirla en Windows, compila la solución en Release x86, instala la dependencia con `py -3.12 -m pip install pywinpty==2.0.15` y ejecuta `py -3.12 pruebas/consola.py Release/Ventas.exe` desde la raíz del repositorio. Si el ejecutable está en otra carpeta, sustituye el último argumento por su ruta. El script crea su propio inventario temporal.

[Ver la ejecución en GitHub Actions](https://github.com/Jesusmontya/ventas-inventario-u3/actions/runs/44250569784)
