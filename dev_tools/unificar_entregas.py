#!/usr/bin/env python3
"""
Unifica todos los archivos de un árbol en un solo .txt.

Para cada carpeta encontrada, agrega un encabezado con el nombre de la carpeta
y, debajo, el contenido en texto plano de cada archivo.

Uso:
    python unificar_entregas.py /ruta/a/INFORMATICA_25_ENTREGA2 \
        --salida entrega_unificada.txt
"""

from __future__ import annotations

import argparse
import os
import re
import sys
import zipfile
from xml.etree import ElementTree


class ExtractionError(Exception):
    """Error al extraer texto de un archivo."""


class MissingDependency(ExtractionError):
    """Falta una dependencia opcional (por ejemplo PyPDF2)."""


def guess_text_encoding(data: bytes) -> str:
    """
    Devuelve una codificación plausible para bytes de texto.
    Intenta utf-8 y, si falla, recurre a latin-1 con reemplazo.
    """
    try:
        data.decode("utf-8")
        return "utf-8"
    except UnicodeDecodeError:
        return "latin-1"


def is_probably_text(data: bytes) -> bool:
    """
    Heurística simple para detectar binarios.
    Considera texto si no hay bytes nulos y la mayoría son imprimibles.
    """
    if b"\0" in data:
        return False
    # Cuenta bytes imprimibles básicos.
    printable = sum(1 for b in data if 9 <= b <= 13 or 32 <= b <= 126)
    return printable / max(len(data), 1) > 0.9


def extract_plain_text(path: str) -> str:
    with open(path, "rb") as f:
        data = f.read()
    if not data:
        return ""
    if not is_probably_text(data):
        raise ExtractionError("Archivo parece binario; no se pudo leer como texto.")
    encoding = guess_text_encoding(data)
    return data.decode(encoding, errors="replace")


def extract_docx_text(path: str) -> str:
    try:
        with zipfile.ZipFile(path) as zf:
            xml = zf.read("word/document.xml")
    except KeyError as exc:
        raise ExtractionError("No se encontró word/document.xml en el .docx") from exc
    except zipfile.BadZipFile as exc:
        raise ExtractionError("El archivo .docx está corrupto") from exc

    root = ElementTree.fromstring(xml)
    texts: list[str] = []
    # Extrae texto de los nodos <w:t> y agrega saltos en cada párrafo <w:p>.
    for node in root.iter():
        tag = node.tag.split("}")[-1]  # elimina el namespace
        if tag == "t" and node.text:
            texts.append(node.text)
        elif tag == "p":
            texts.append("\n")
    return "".join(texts)


def extract_pdf_text(path: str) -> str:
    try:
        import PyPDF2  # type: ignore
    except ImportError as exc:
        raise MissingDependency("PyPDF2") from exc

    try:
        with open(path, "rb") as f:
            reader = PyPDF2.PdfReader(f)
            pages = [page.extract_text() or "" for page in reader.pages]
            return "\n".join(pages)
    except Exception as exc:  # pragma: no cover - dependencias externas
        raise ExtractionError(f"Error al leer PDF: {exc}") from exc


def extract_text(path: str) -> str:
    ext = os.path.splitext(path)[1].lower()
    if ext == ".docx":
        return extract_docx_text(path)
    if ext == ".pdf":
        return extract_pdf_text(path)
    # Para otros tipos, intentar lectura plana.
    return extract_plain_text(path)


def iter_files_by_folder(root: str):
    """
    Genera (carpeta_relativa, [lista de archivos]) en orden alfabético.
    """
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames.sort()
        filenames.sort()
        if not filenames:
            continue
        rel_dir = os.path.relpath(dirpath, root)
        yield rel_dir, [os.path.join(dirpath, name) for name in filenames]


def unificar(root: str, salida: str) -> None:
    root = os.path.abspath(root)
    with open(salida, "w", encoding="utf-8") as out:
        for rel_dir, files in iter_files_by_folder(root):
            carpeta = rel_dir if rel_dir != "." else os.path.basename(root)
            out.write(f"===== CARPETA: {carpeta} =====\n")
            for path in files:
                rel_file = os.path.relpath(path, root)
                out.write(f"\n--- ARCHIVO: {rel_file} ---\n")
                try:
                    contenido = extract_text(path)
                    if contenido and not contenido.endswith("\n"):
                        contenido += "\n"
                    out.write(contenido)
                except MissingDependency as exc:
                    out.write(f"[Instala la dependencia faltante: {exc}]\n")
                except ExtractionError as exc:
                    out.write(f"[No se pudo convertir a texto plano: {exc}]\n")
                except Exception as exc:  # pragma: no cover
                    out.write(f"[Error inesperado: {exc}]\n")
            out.write("\n")  # separador entre carpetas


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Unifica todos los archivos en texto plano."
    )
    parser.add_argument(
        "raiz",
        help="Carpeta raíz con las entregas (p. ej. G:\\Mi unidad\\INFORMATICA_25_ENTREGA2).",
    )
    parser.add_argument(
        "-o",
        "--salida",
        default="entrega_unificada.txt",
        help="Ruta del archivo .txt resultante (por defecto: entrega_unificada.txt en la raíz).",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    raiz = args.raiz
    if not os.path.isdir(raiz):
        print(f"No existe la carpeta: {raiz}", file=sys.stderr)
        return 1

    salida = args.salida
    if not os.path.isabs(salida):
        salida = os.path.join(os.path.abspath(raiz), salida)

    print(f"Procesando {raiz} -> {salida}")
    unificar(raiz, salida)
    print("Listo.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
