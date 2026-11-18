# Sistema de ventas e inventario · Unidad 3

**Jesús Pavel Montoya Cerpa**  
Lenguaje ensamblador · Ingeniería en Sistemas Computacionales · TecNM Culiacán

Aplicación de consola en MASM x86 con Irvine32. Permite registrar hasta diez productos, buscarlos por índice, recibir mercancía, vender y consultar el resumen de la sesión. El descuento por mayoreo es del 2 % a partir de cinco unidades del mismo producto.

## Compilación

1. En Windows, instala Visual Studio 2022 con **Desarrollo para el escritorio con C++**, el compilador MSVC v143 y el SDK de Windows.
2. Descarga **Irvine.zip** del [repositorio de Kip Irvine](https://github.com/surferkip/asmbook). Extrae los archivos de modo que existan `C:\Irvine\Irvine32.inc` y `C:\Irvine\Irvine32.lib`.
3. Abre `Ventas.sln`. Selecciona **Debug | x86** y compila con **Ctrl+Mayús+B**. Ejecuta con **Ctrl+F5**.
4. Si utilizas otra carpeta, desde Developer Command Prompt ejecuta `msbuild Ventas.sln /p:Configuration=Debug /p:Platform=x86 /p:IrvineDir=D:\Bibliotecas\Irvine`.

## Prueba rápida

Al iniciar por primera vez, compara las cuatro filas con `inventario-inicial.txt`. En la opción 3, vende cinco unidades del índice 1. Debe aparecer el aviso de mayoreo, un importe de **$147.00** y un saldo de **25 unidades** para ese producto. La opción 6 guarda las existencias en `inventario.bin` dentro del directorio de trabajo. Sal con 7 y vuelve a abrir desde el mismo directorio para comprobar la carga. Como en la Unidad 2, los ingresos y las altas pertenecen a la sesión.

[Reporte de la Unidad 3 y tabla de pruebas](INFORME.md) · [Código fuente](AddTwo.asm) · [Proyecto base de la Unidad 2](https://github.com/Jesusmontya/ventas-inventario-asm)
