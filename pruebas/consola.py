"""Pruebas del ejecutable interactivo en Windows mediante ConPTY."""
from pathlib import Path
from queue import Empty, Queue
from threading import Thread
import re
import struct
import sys
import tempfile
import time

from winpty import PtyProcess

exe = str(Path(sys.argv[1]).resolve())
menu = "Seleccione una opcion: "
ansi = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]|\x1b\][^\x07]*(?:\x07|\x1b\\)")


class Consola:
    def __init__(self, carpeta):
        self.proceso = PtyProcess.spawn([exe], cwd=carpeta, dimensions=(60, 160))
        self.cola = Queue()
        self.pendiente = ""
        Thread(target=self.leer, daemon=True).start()

    def leer(self):
        try:
            while True:
                self.cola.put(self.proceso.read(8192))
        except EOFError:
            return

    def esperar(self, marca):
        limite = time.monotonic() + 20
        while True:
            limpio = ansi.sub("", self.pendiente).replace("\r", "")
            if marca.strip() in limpio:
                antes, self.pendiente = limpio.split(marca.strip(), 1)
                return antes
            try:
                self.pendiente += self.cola.get(timeout=max(0, limite-time.monotonic()))
            except Empty:
                raise AssertionError(f"No aparecio {marca!r}. Pantalla: {limpio!r}")

    def enviar(self, valor):
        self.proceso.write(str(valor) + "\r")

    def operacion(self, opcion, campos, resultados):
        self.enviar(opcion)
        for pregunta, dato in campos:
            self.esperar(pregunta)
            self.enviar(dato)
        salida = self.esperar(menu)
        for esperado in resultados:
            assert esperado in salida, (esperado, salida)
        print("OK", opcion, campos, resultados, flush=True)

    def salir(self):
        self.enviar(7)
        assert self.proceso.wait() == 0


indice = "indice del producto (0 a 9):"
cantidad = "Ingrese la cantidad:"
codigo = "Formato ABC-123):"
nombre = "nombre del producto:"
precio = "para $15.00):"
stock = "stock inicial (0-100):"

with tempfile.TemporaryDirectory() as carpeta:
    app = Consola(carpeta)
    assert "TET-500 Te 500ml 50" in app.esperar(menu)
    app.operacion(1, [(codigo,"CAF-123"),(nombre,"Cafe"),(precio,1234),(stock,9)], ["4. CAF-123 Cafe 9"])
    app.operacion(2, [(indice,4)], ["Cafe"])
    app.operacion(2, [(indice,9)], ["Error: Opcion invalida"])
    app.operacion(1, [(codigo,"CAF-123")], ["ya existe"])
    app.operacion(1, [(codigo,"CAF0123")], ["Formato de codigo invalido"])
    app.operacion(4, [(indice,0),(cantidad,50)], ["TET-500 Te 500ml 100"])
    app.operacion(4, [(indice,0),(cantidad,1)], ["limite maximo", "TET-500 Te 500ml 100"])
    app.operacion(3, [(indice,4),(cantidad,4)], ["49.36", "CAF-123 Cafe 5"])
    app.operacion(3, [(indice,4),(cantidad,5)], ["2% de descuento", "60.47", "CAF-123 Cafe 0"])
    app.operacion(3, [(indice,4),(cantidad,1)], ["Existencias insuficientes", "CAF-123 Cafe 0"])
    app.operacion(3, [(indice,0),(cantidad,"abc")], ["Opcion invalida", "TET-500 Te 500ml 100"])
    app.operacion(5, [], ["inventario: 160", "4200.00", "109.83"])
    app.operacion(6, [], ["guardado en archivo correctamente"])
    app.salir()
    archivo = Path(carpeta, "inventario.bin")
    assert archivo.read_bytes() == struct.pack("<10I",100,30,20,10,0,0,0,0,0,0)
    app = Consola(carpeta)
    salida = app.esperar(menu)
    assert "cargado desde archivo correctamente" in salida and "TET-500 Te 500ml 100" in salida
    app.operacion(5, [], ["sesion ($ MXN): 0.00"])
    app.salir()
    archivo.write_bytes(b"X")
    app = Consola(carpeta)
    salida = app.esperar(menu)
    assert "Archivo invalido" in salida and "TET-500 Te 500ml 50" in salida
    app.salir()
    print("OK guardado, carga, reinicio y archivo incompleto")
