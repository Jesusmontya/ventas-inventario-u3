# Sistema de ventas e inventario

**Jesús Pavel Montoya Cerpa · TecNM Culiacán · Lenguaje ensamblador**

## Antecedentes de la Unidad 2

### Objetivo

Desarrollar en ensamblador x86 un sistema de consola para administrar ventas e inventario de una tienda. El sistema mantiene hasta diez productos, controla existencias y conserva el inventario entre ejecuciones.

### Diseño

Los códigos, nombres, precios y stocks se almacenan en arreglos paralelos. Los precios se representan en centavos (`DWORD`) y el formato de salida divide entre 100 para mostrar pesos mexicanos. Cada producto admite hasta 100 unidades.

Las rutinas principales son `RegistrarProducto`, `BuscarProductoUI`, `RealizarVenta`, `RecibirMercancia`, `MostrarResumen`, `CargarInventarioInicio` y `GuardarInventarioArchivo`.

### Reglas implementadas

- Máximo de 10 productos.
- Validación del separador `-` en el código y detección de códigos duplicados.
- Rechazo de índices inválidos, ventas mayores al stock y entradas que rebasen 100 unidades.
- Descuento de 2% en ventas de cinco o más unidades.
- Persistencia de stocks en `inventario.bin`.

### Limitaciones de la versión original

La validación actual comprueba el guion del código; como mejora se puede validar estrictamente cada carácter del patrón `ABC-123`. También puede ampliarse el archivo persistente para almacenar altas de productos, además de las existencias.

## Versión de la Unidad 3

Retomé el proyecto de equipo de la Unidad 2. Conservé el menú de siete opciones, el catálogo inicial, la búsqueda por índice y el archivo de existencias. Al separar la lectura del índice, pude aplicar la misma validación a las tres operaciones que seleccionan un producto.

### Antes y después

| Parte del programa | Problema en la Unidad 2 | Cambio en la Unidad 3 | Beneficio |
|---|---|---|---|
| Catálogo inicial | Se escribía cada letra por separado. Algunos nombres arrancaban a 16 bytes de distancia aunque la consulta avanzaba de 20 en 20. | Declaré los códigos y nombres directamente en celdas de 12 y 20 bytes. | Los cuatro nombres se muestran completos y el tamaño de cada fila es uniforme. |
| Mensajes | Cada aviso necesitaba cargar una dirección y llamar a Irvine32. | La macro parametrizada `MostrarTexto` reúne las dos instrucciones. | En cada punto de uso se identifica el mensaje por su nombre. |
| Captura de texto | El registro repetía la preparación del búfer y su longitud. | `LeerCampo` comparte la secuencia de captura y usa el tamaño declarado del búfer. | Código y nombre pasan por la misma rutina de lectura. |
| Índices y cantidades | Búsqueda, venta y recepción repetían la captura y las comparaciones. La conversión aceptaba caracteres ajenos a un número. | `LeerNumero` comprueba dígitos y desbordamiento. `LeerIndice` verifica el índice contra el número de productos activos. | Una entrada como `abc` se rechaza antes de modificar el stock. |
| Ventas y resumen | El descuento estaba mezclado con la pantalla. Tres bloques dividían importes y podían mostrar un solo decimal. | Separé `CalcularImporte` y `MostrarDinero`. Utilicé dos registros para los importes de 64 bits. | El descuento se calcula en centavos enteros y todos los importes tienen dos decimales. |
| Registros y pila | Había bloques con `pushad/popad` y varias salidas con restauraciones manuales. | Cada `PROC USES` conserva los registros que necesita su llamador. | MASM genera la restauración en cada retorno y los resultados permanecen disponibles. |
| Archivo | Una lectura parcial podía modificar las existencias y después anunciar éxito. | Leo en una tabla temporal y verifico 40 bytes exactos y diez valores de 0 a 100 antes de copiar. | Un archivo incompleto conserva el inventario inicial. El archivo de la Unidad 2 sigue siendo compatible. |

### Fragmentos del programa

Los tres ejemplos se encuentran en `AddTwo.asm`.

**Procedimiento reutilizado.** La búsqueda, la venta y la recepción llaman a `LeerIndice`. La comparación sin signo también rechaza el valor de error −1. EAX entrega el índice y EDX recupera su valor original al regresar.

```asm
LeerIndice PROC USES edx
    mov edx, OFFSET msgPedirIndice
    call LeerNumero
    cmp eax, numProductos
    jb listo
    mov eax, -1
listo:
    ret
LeerIndice ENDP
```

**Macro y puntos de uso.** Elegí una macro para una secuencia corta donde solo cambia la dirección del texto. MASM expande estas dos instrucciones en cada uso. Como la macro carece de etiquetas internas, no requiere `LOCAL`.

```asm
MostrarTexto MACRO mensaje
    mov edx, OFFSET mensaje
    call WriteString
ENDM

; En main, antes de listar los productos
    MostrarTexto msgTitulo
; En RegistrarProducto, cuando se detecta un duplicado
    MostrarTexto msgCodDupl
```

**Resultados y USES.** En el cálculo de la venta, ESI recibe el índice y EBX la cantidad. El resultado ocupa EDX:EAX. Ambos registros quedan fuera de `USES`. El procedimiento conserva ECX, ESI y EDI, y solo lee EBX.

```asm
CalcularImporte PROC USES ecx esi edi
    mov eax, precios[esi*4]
    mul ebx
    cmp ebx, 5
    jb listo
    ; Para mayoreo, el cuerpo resta la parte entera del subtotal entre 50.
```

Elegí procedimientos para las validaciones y el formato monetario porque incluyen decisiones y ciclos. En `MostrarDinero`, cada dígito entero genera un `push` y aumenta EDI. La salida hace un `pop` por dígito hasta que EDI vuelve a cero. Al llegar a `ret`, solo queda pendiente la restauración que genera `USES`.

### Comparación de líneas

Se contó únicamente `AddTwo.asm` en cada versión. Cada línea con al menos un elemento de código cuenta una vez, incluidas directivas, datos, etiquetas y definiciones de macros. Se excluyeron líneas vacías y comentarios de línea completa. En ambas versiones se puede reproducir el conteo con `rg -c '^\s*[^;\s]' AddTwo.asm`.

| Unidad 2 | Unidad 3 | Reducción |
|---:|---:|---:|
| 697 | 473 | 224 líneas (32.1 %) |

La mayor reducción proviene de declarar el catálogo como datos. También desaparecieron las copias del formato monetario, la selección de índice y la impresión de mensajes. El conteo corresponde al archivo fuente antes de la expansión de macros.

### Tabla de pruebas actualizada

Ejecuté la solución en modo **Release | x86** en Windows con MSBuild, MASM e Irvine32. El script `pruebas/consola.py` interactúa con el ejecutable por consola. Los casos se realizaron en orden, en una carpeta temporal que al inicio estaba vacía. Se puede consultar el [registro de compilación y ejecución](https://github.com/Jesusmontya/ventas-inventario-u3/actions/runs/44250569784).

| Caso | Entrada | Resultado esperado | Resultado obtenido |
|---|---|---|---|
| Arranque | Abrir sin archivo previo | Usar el catálogo base | El índice 0 mostró `TET-500 Te 500ml 50`. |
| Registro | 1 → CAF-123 → Cafe → 1234 → 9 | Crear el quinto producto a $12.34 | Apareció `4. CAF-123 Cafe 9`. El precio se verificó en la venta posterior. |
| Búsqueda | 2 → 4 | Encontrar Cafe | Apareció Cafe en la salida. |
| Índice sin producto | 2 → 9 | Rechazar la consulta | Apareció el aviso de opción inválida. |
| Código duplicado | 1 → CAF-123 | Rechazar el segundo registro | Apareció el aviso de código existente. |
| Código sin guion | 1 → CAF0123 | Rechazar el formato | Apareció el aviso de formato inválido. |
| Entrada al límite | 4 → 0 → 50 | Pasar de 50 a 100 unidades | TET-500 quedó con 100. |
| Entrada excedida | 4 → 0 → 1 | Rechazar la unidad 101 | Se mostró el aviso de límite y quedaron 100. |
| Venta normal | 3 → 4 → 4 | Cobrar $49.36 y dejar 5 unidades | La consola mostró 49.36 y stock 5. |
| Venta con mayoreo | 3 → 4 → 5 | Sobre 6170 centavos, descontar 123 y cobrar $60.47 | Aparecieron el aviso del 2 %, el total 60.47 y stock 0. |
| Venta rechazada | 3 → 4 → 1 | Rechazar por falta de stock | Se mostraron existencias insuficientes y stock 0. |
| Cantidad no numérica | 3 → 0 → abc | Rechazar la captura | Apareció el aviso de dato inválido y TET-500 conservó 100 unidades. |
| Resumen | 5 | 160 unidades, $4200.00 de inventario, $109.83 de ingresos | La consola mostró los tres valores esperados. |
| Guardado | 6 → 7 | Escribir diez existencias de 32 bits | Se mostró la confirmación. Se comparó el archivo completo de 40 bytes con los valores 100, 30, 20, 10 y seis ceros. |
| Carga | Volver a abrir en la misma carpeta → 5 | Recuperar existencias y reiniciar ingresos | Aparecieron la confirmación de carga, TET-500 con 100 e ingresos de $0.00. |
| Archivo incompleto | Sustituir el archivo de prueba por un byte y reiniciar | Avisar y conservar el catálogo inicial | Apareció el aviso de archivo inválido y TET-500 volvió a 50 unidades. |

El archivo conserva las existencias por posición, igual que en la Unidad 2. Los códigos, nombres y precios de las altas pertenecen a la sesión. Por eso la prueba de recarga verifica un producto del catálogo base.
