include Irvine32.inc

; Unidad 3 - Jesus Pavel Montoya Cerpa
; La base corresponde al proyecto de equipo de la Unidad 2.

MostrarTexto MACRO mensaje
    mov edx, OFFSET mensaje
    call WriteString
ENDM

LeerCampo MACRO mensaje
    MostrarTexto mensaje
    mov edx, OFFSET inputBuffer
    mov ecx, SIZEOF inputBuffer - 1
    call ReadString
ENDM

.data
    MAX_PROD        EQU 10
    
    msgTitulo       BYTE 13, 10, "=========================================", 13, 10
                    BYTE "   SISTEMA DE GESTION Y VENTAS TEOLONGI  ", 13, 10
                    BYTE "=========================================", 13, 10, 0

    msgMenu         BYTE 13, 10, "1. Registrar Nuevo Producto", 13, 10
                    BYTE "2. Listar y Buscar Productos", 13, 10
                    BYTE "3. Realizar Venta (Con regla de 2% mayoreo)", 13, 10
                    BYTE "4. Recibir Mercancia (Max 100 unidades)", 13, 10
                    BYTE "5. Mostrar Resumen (Inventario e Ingresos)", 13, 10
                    BYTE "6. Guardar existencias (carga al iniciar)", 13, 10
                    BYTE "7. Salir", 13, 10
                    BYTE "Seleccione una opcion: ", 0
    
    msgOpcionInv    BYTE 13, 10, "Error: Opcion invalida o dato incorrecto.", 13, 10, 0
    msgPedirCod     BYTE "Ingrese codigo (Formato ABC-123): ", 0
    msgPedirNombre  BYTE "Ingrese nombre del producto: ", 0
    msgPedirPrecio  BYTE "Ingrese precio en centavos (ej. 1500 para $15.00): ", 0
    msgPedirStock   BYTE "Ingrese stock inicial (0-100): ", 0
    msgProdLleno    BYTE 13, 10, "Error: Capacidad maxima alcanzada (10 productos).", 13, 10, 0
    msgCodDupl      BYTE 13, 10, "Error: El codigo de producto ya existe.", 13, 10, 0
    msgErrFormato   BYTE 13, 10, "Error: Formato de codigo invalido (Use ABC-123).", 13, 10, 0
    msgMaxStock     BYTE 13, 10, "Error: Supera el limite maximo permitido de 100 unidades.", 13, 10, 0

    msgPedirIndice  BYTE 13, 10, "Ingrese el indice del producto (0 a 9): ", 0
    msgPedirCant    BYTE "Ingrese la cantidad: ", 0
    msgStockInsuf   BYTE 13, 10, "Error: Existencias insuficientes o stock excedido.", 13, 10, 0
    msgVentaExito   BYTE 13, 10, "Operacion exitosa!", 13, 10, 0
    msgTotalTxt     BYTE "Importe total ($ MXN): ", 0
    msgDescApli     BYTE "Aviso: Se aplico el 2% de descuento por mayoreo!", 13, 10, 0
    
    msgResumenTit   BYTE 13, 10, "=== RESUMEN GENERAL DE LA SESION ===", 13, 10, 0
    msgTotalUnid    BYTE "Total de unidades en inventario: ", 0
    msgValInventario BYTE "Valor total del inventario ($ MXN): ", 0
    msgIngresosAcum BYTE "Ingresos acumulados de la sesion ($ MXN): ", 0

    msgArchivoGuard BYTE 13, 10, "Inventario guardado en archivo correctamente.", 13, 10, 0
    msgArchivoCarg  BYTE 13, 10, "Inventario cargado desde archivo correctamente.", 13, 10, 0
    msgErrorArch    BYTE 13, 10, "Aviso: No se encontro archivo previo. Usando base inicial.", 13, 10, 0

    filename        BYTE "inventario.bin", 0
    fileHandle      HANDLE ?

    ingresosAcumulados DWORD 0
    ingresosAltos DWORD 0
    numProductos    DWORD 4
    
    codigos BYTE "TET-500",5 DUP(0),"TET-1LT",5 DUP(0)
            BYTE "TET-2LT",5 DUP(0),"TET-5LT",5 DUP(0),72 DUP(0)
    nombres BYTE "Te 500ml",12 DUP(0),"Te 1 Litro",10 DUP(0)
            BYTE "Te 2 Litros",9 DUP(0),"Te 5 Litros",9 DUP(0),120 DUP(0)
    precios DWORD 1500,3000,4500,9000,6 DUP(0)
    stocks DWORD 50,30,20,10,6 DUP(0)
    stocksLeidos DWORD 10 DUP(?)
    inputBuffer BYTE 128 DUP(0)
    msgErrorGuardar BYTE "Error al guardar inventario.",13,10,0
    msgArchivoInvalido BYTE "Archivo invalido. Se mantiene el inventario inicial.",13,10,0
.code
; Sin entrada. Controla el menu y termina el proceso con codigo cero.
main PROC
    call CargarInventarioInicio
menu_principal:
    MostrarTexto msgTitulo
    call MostrarInventarioMemoria
    mov edx, OFFSET msgMenu
    call LeerNumero
    cmp eax, 1
    je alta
    cmp eax, 2
    je consulta
    cmp eax, 3
    je venta
    cmp eax, 4
    je entrada
    cmp eax, 5
    je resumen
    cmp eax, 6
    je guardar
    cmp eax, 7
    je salir
    MostrarTexto msgOpcionInv
    jmp menu_principal
alta:
    call RegistrarProducto
    jmp menu_principal
consulta:
    call BuscarProductoUI
    jmp menu_principal
venta:
    call RealizarVenta
    jmp menu_principal
entrada:
    call RecibirMercancia
    jmp menu_principal
resumen:
    call MostrarResumen
    jmp menu_principal
guardar:
    call GuardarInventarioArchivo
    jmp menu_principal
salir:
    invoke ExitProcess, 0
main ENDP

; Contrato general: USES conserva los registros indicados. Salvo indicacion,
; los procedimientos sin resultado conservan los registros de uso general.
; Las banderas son temporales. Los importes internos estan en centavos.

; EDX = mensaje. EAX = entero decimal entre 0 y 2147483647, o -1 por error.
LeerNumero PROC USES ecx edx esi ebx
    call WriteString
    mov edx, OFFSET inputBuffer
    mov ecx, SIZEOF inputBuffer - 1
    call ReadString
    test eax, eax
    jz invalido
    cmp eax, SIZEOF inputBuffer - 1
    jae invalido
    mov esi, OFFSET inputBuffer
    xor eax, eax
digito:
    movzx ebx, BYTE PTR [esi]
    sub ebx, '0'
    cmp ebx, 9
    ja invalido
    imul eax, 10
    jo invalido
    add eax, ebx
    jo invalido
    inc esi
    cmp BYTE PTR [esi], 0
    jne digito
    ret
invalido:
    mov eax, -1
    ret
LeerNumero ENDP

; Sin parametros. EAX = indice existente, o -1 si la entrada es invalida.
LeerIndice PROC USES edx
    mov edx, OFFSET msgPedirIndice
    call LeerNumero
    cmp eax, numProductos
    jb listo
    mov eax, -1
listo:
    ret
LeerIndice ENDP

; inputBuffer = codigo. EAX = 1 si existe, 0 si esta disponible.
VerificarDuplicado PROC USES ecx edx esi edi
    xor edx, edx
siguiente:
    imul edi, edx, 12
    add edi, OFFSET codigos
    mov esi, OFFSET inputBuffer
    mov ecx, 8
    cld
    repe cmpsb
    je encontrado
    inc edx
    cmp edx, numProductos
    jb siguiente
    xor eax, eax
    ret
encontrado:
    mov eax, 1
    ret
VerificarDuplicado ENDP

; Lee codigo, nombre, precio y stock. Publica la nueva fila al incrementar
; numProductos tras validar todos los campos. Sin resultado en registros.
RegistrarProducto PROC USES eax ebx ecx edx esi edi
    mov ebx, numProductos
    cmp ebx, MAX_PROD
    jae lleno
    LeerCampo msgPedirCod
    cmp eax, 7
    jne formato
    cmp BYTE PTR inputBuffer[3], '-'
    jne formato
    call VerificarDuplicado
    test eax, eax
    jnz duplicado
    imul edi, ebx, 12
    add edi, OFFSET codigos
    mov esi, OFFSET inputBuffer
    mov ecx, 8
    cld
    rep movsb
    LeerCampo msgPedirNombre
    cmp eax, 19
    ja datoInvalido
    test eax, eax
    jz datoInvalido
    lea ecx, [eax+1]
    imul edi, ebx, 20
    add edi, OFFSET nombres
    mov esi, OFFSET inputBuffer
    cld
    rep movsb
    mov edx, OFFSET msgPedirPrecio
    call LeerNumero
    test eax, eax
    js datoInvalido
    mov precios[ebx*4], eax
    mov edx, OFFSET msgPedirStock
    call LeerNumero
    test eax, eax
    js datoInvalido
    cmp eax, 100
    ja exceso
    mov stocks[ebx*4], eax
    inc numProductos
    MostrarTexto msgVentaExito
    ret
lleno:
    MostrarTexto msgProdLleno
    ret
formato:
    MostrarTexto msgErrFormato
    ret
duplicado:
    MostrarTexto msgCodDupl
    ret
datoInvalido:
    MostrarTexto msgOpcionInv
    ret
exceso:
    MostrarTexto msgMaxStock
    ret
RegistrarProducto ENDP

; Sin parametros. Imprime indice, codigo, nombre y existencias de cada fila.
MostrarInventarioMemoria PROC USES eax edx esi
    xor esi, esi
fila:
    mov eax, esi
    call WriteDec
    mov al, '.'
    call WriteChar
    mov al, ' '
    call WriteChar
    imul edx, esi, 12
    add edx, OFFSET codigos
    call WriteString
    mov al, ' '
    call WriteChar
    imul edx, esi, 20
    add edx, OFFSET nombres
    call WriteString
    mov al, ' '
    call WriteChar
    mov eax, stocks[esi*4]
    call WriteDec
    call Crlf
    inc esi
    cmp esi, numProductos
    jb fila
    ret
MostrarInventarioMemoria ENDP

; Sin parametros. Imprime el nombre asociado al indice capturado o el error.
BuscarProductoUI PROC USES eax edx
    call LeerIndice
    cmp eax, -1
    je incorrecto
    imul edx, eax, 20
    add edx, OFFSET nombres
    call WriteString
    call Crlf
    ret
incorrecto:
    MostrarTexto msgOpcionInv
    ret
BuscarProductoUI ENDP

; EDX:EAX = centavos sin signo. Imprime pesos con dos decimales y salto.
; Se divide primero la mitad alta para admitir totales de 64 bits.
MostrarDinero PROC USES eax ebx ecx edx esi edi
    mov esi, eax
    mov eax, edx
    xor edx, edx
    mov ecx, 100
    div ecx
    mov ebx, eax
    mov eax, esi
    div ecx
    mov esi, edx
    ; EBX:EAX contiene pesos. Convierte hasta 20 digitos sobre la pila.
    mov ecx, 10
    xor edi, edi
convertir:
    mov edx, eax
    mov eax, ebx
    mov ebx, edx
    xor edx, edx
    div ecx
    xchg eax, ebx
    div ecx
    add edx, '0'
    push edx
    inc edi
    test ebx, ebx
    jnz convertir
    test eax, eax
    jnz convertir
imprimir:
    pop eax
    call WriteChar
    dec edi
    jnz imprimir
    mov al, '.'
    call WriteChar
    mov eax, esi
    xor edx, edx
    div ecx
    add al, '0'
    call WriteChar
    mov eax, edx
    add al, '0'
    call WriteChar
    call Crlf
    ret
MostrarDinero ENDP

; ESI = indice, EBX = cantidad positiva. EDX:EAX = importe neto en centavos.
; Con cinco unidades o mas, resta floor(subtotal / 50), equivalente al 2%.
CalcularImporte PROC USES ecx esi edi
    mov eax, precios[esi*4]
    mul ebx
    cmp ebx, 5
    jb listo
    mov esi, eax
    mov edi, edx
    mov ecx, 50
    ; El subtotal maximo es 100 * INT_MAX; el descuento cabe en DWORD.
    div ecx
    sub esi, eax
    sbb edi, 0
    mov eax, esi
    mov edx, edi
listo:
    ret
CalcularImporte ENDP

; Sin parametros. Valida la venta antes de actualizar stock e ingresos.
RealizarVenta PROC USES eax ebx edx esi
    call LeerIndice
    cmp eax, -1
    je invalida
    mov esi, eax
    mov edx, OFFSET msgPedirCant
    call LeerNumero
    cmp eax, 1
    jl invalida
    mov ebx, eax
    cmp ebx, stocks[esi*4]
    ja insuficiente
    cmp ebx, 5
    jb cobrar
    MostrarTexto msgDescApli
cobrar:
    MostrarTexto msgTotalTxt
    call CalcularImporte
    add ingresosAcumulados, eax
    adc ingresosAltos, edx
    sub stocks[esi*4], ebx
    call MostrarDinero
    MostrarTexto msgVentaExito
    ret
insuficiente:
    MostrarTexto msgStockInsuf
    ret
invalida:
    MostrarTexto msgOpcionInv
    ret
RealizarVenta ENDP

; Sin parametros. Solo actualiza stocks si la suma queda entre 1 y 100.
RecibirMercancia PROC USES eax edx esi
    call LeerIndice
    cmp eax, -1
    je invalida
    mov esi, eax
    mov edx, OFFSET msgPedirCant
    call LeerNumero
    cmp eax, 1
    jl invalida
    add eax, stocks[esi*4]
    cmp eax, 100
    ja exceso
    mov stocks[esi*4], eax
    MostrarTexto msgVentaExito
    ret
exceso:
    MostrarTexto msgMaxStock
    ret
invalida:
    MostrarTexto msgOpcionInv
    ret
RecibirMercancia ENDP

; Sin parametros. Recorre filas activas una vez; solo imprime resultados.
MostrarResumen PROC USES eax ebx ecx edx esi edi
    xor esi, esi
    xor ebx, ebx
    xor ecx, ecx
    xor edi, edi
fila:
    mov eax, stocks[esi*4]
    add ebx, eax
    mul precios[esi*4]
    add edi, eax
    adc ecx, edx
    inc esi
    cmp esi, numProductos
    jb fila
    MostrarTexto msgResumenTit
    MostrarTexto msgTotalUnid
    mov eax, ebx
    call WriteDec
    call Crlf
    MostrarTexto msgValInventario
    mov eax, edi
    mov edx, ecx
    call MostrarDinero
    MostrarTexto msgIngresosAcum
    mov eax, ingresosAcumulados
    mov edx, ingresosAltos
    call MostrarDinero
    ret
MostrarResumen ENDP

; Sin parametros. Lee el formato U2 de diez DWORD sin modificar el stock
; activo hasta comprobar longitud, fin de archivo y rango de cada valor.
CargarInventarioInicio PROC USES eax ecx edx esi edi
    mov edx, OFFSET filename
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je ausente
    mov fileHandle, eax
    mov edx, OFFSET stocksLeidos
    mov ecx, SIZEOF stocksLeidos
    call ReadFromFile
    jc fallo
    cmp eax, SIZEOF stocksLeidos
    jne fallo
    mov eax, fileHandle
    mov edx, OFFSET inputBuffer
    mov ecx, 1
    call ReadFromFile
    jc fallo
    test eax, eax
    jnz fallo
    mov eax, fileHandle
    call CloseFile
    xor esi, esi
validar:
    cmp stocksLeidos[esi*4], 100
    ja invalido
    inc esi
    cmp esi, MAX_PROD
    jb validar
    mov esi, OFFSET stocksLeidos
    mov edi, OFFSET stocks
    mov ecx, MAX_PROD
    cld
    rep movsd
    MostrarTexto msgArchivoCarg
    ret
fallo:
    mov eax, fileHandle
    call CloseFile
invalido:
    MostrarTexto msgArchivoInvalido
    ret
ausente:
    MostrarTexto msgErrorArch
    ret
CargarInventarioInicio ENDP

; Sin parametros. Escribe las diez existencias en el archivo de la Unidad 2.
GuardarInventarioArchivo PROC USES eax ebx ecx edx
    mov edx, OFFSET filename
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je fallo
    mov fileHandle, eax
    mov edx, OFFSET stocks
    mov ecx, SIZEOF stocks
    call WriteToFile
    mov ebx, eax
    mov eax, fileHandle
    call CloseFile
    test eax, eax
    jz fallo
    cmp ebx, SIZEOF stocks
    jne fallo
    MostrarTexto msgArchivoGuard
    ret
fallo:
    MostrarTexto msgErrorGuardar
    ret
GuardarInventarioArchivo ENDP

END main
