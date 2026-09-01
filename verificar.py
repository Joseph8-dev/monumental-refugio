"""Verificación estática del proyecto Flutter, sin necesidad del SDK.

Detecta los errores que ya han roto el build en este proyecto:
 1. Símbolos del proyecto usados sin importar el archivo que los define.
 2. Miembros duplicados dentro de una misma clase (campo vs método).
 3. Imports que apuntan a archivos inexistentes.
 4. Llaves/paréntesis/corchetes desbalanceados.

Solo indexa declaraciones a NIVEL SUPERIOR (columna 0): los métodos de una
clase están indentados y no deben entrar al índice, o widgets de Flutter
como Row o build aparecerían como símbolos propios.
"""
import os, re, collections, sys

RAIZ = 'lib'
KEY = {'if','for','while','return','switch','try','catch','else','do','await',
       'final','const','var','new','class','enum','mixin','import','export',
       'typedef','extension','part','library'}

definido_en = {}   # símbolo público -> archivo que lo define
por_archivo = {}

re_tipo = re.compile(r'^(?:abstract\s+)?(?:class|enum|mixin)\s+(\w+)')
re_func = re.compile(r'^[A-Za-z_][\w<>,\[\]?]*(?:\s*<[^>]+>)?\s+(\w+)\s*\(')
re_getter = re.compile(r'^[A-Za-z_][\w<>,\[\]?]*\s+get\s+(\w+)')
# El tipo es opcional: 'const _pad = ...' o 'const EdgeInsets _pad = ...'.
# Sin el grupo opcional, el regex partía el nombre y capturaba la última letra.
re_const = re.compile(r'^(?:final|const)\s+(?:[\w<>,\[\]?]+\s+)?(\w+)\s*=')

for root, _, files in os.walk(RAIZ):
    for f in sorted(files):
        if not f.endswith('.dart'):
            continue
        ruta = os.path.join(root, f)
        texto = open(ruta, encoding='utf-8').read()
        por_archivo[ruta] = texto
        for linea in texto.split('\n'):
            if not linea or linea[0].isspace():   # solo columna 0
                continue
            for rx in (re_tipo, re_getter, re_func, re_const):
                m = rx.match(linea)
                if m:
                    n = m.group(1)
                    if not n.startswith('_') and n not in KEY:
                        definido_en.setdefault(n, ruta)
                    break

problemas = []

def visibles_desde(ruta, texto):
    base = os.path.dirname(ruta)
    out = {ruta}
    for m in re.findall(r"import '(?!package:|dart:)([^']+)'", texto):
        out.add(os.path.normpath(os.path.join(base, m)))
    for m in re.findall(r"import 'package:\w+/([^']+)'", texto):
        out.add(os.path.normpath(os.path.join(RAIZ, m)))
    return out

for ruta, texto in por_archivo.items():
    base = os.path.dirname(ruta)
    for m in re.findall(r"import '(?!package:|dart:)([^']+)'", texto):
        if not os.path.exists(os.path.normpath(os.path.join(base, m))):
            problemas.append(f'IMPORT ROTO  {ruta} -> {m}')

    for a, b, nom in [('{','}','llaves'), ('(',')','paréntesis'), ('[',']','corchetes')]:
        d = texto.count(a) - texto.count(b)
        if d:
            problemas.append(f'BALANCE      {ruta}: {nom} {d:+d}')

    vis = visibles_desde(ruta, texto)
    # Fuera comentarios Y cadenas: un texto en español como
    # 'Datos del censo' no significa que se use la clase Datos.
    limpio = re.sub(r'//[^\n]*|/\*.*?\*/', '', texto, flags=re.S)
    # Las interpolaciones ${...} SÍ son código: se rescatan antes de
    # borrar las cadenas, o se perdería un uso real.
    interpolado = ' '.join(re.findall(r'\$\{([^{}]*)\}', limpio))
    limpio = re.sub(r"'''.*?'''|\"\"\".*?\"\"\"", "''", limpio, flags=re.S)
    limpio = re.sub(r"'(?:\\.|[^'\\\n])*'", "''", limpio)
    limpio = re.sub(r'"(?:\\.|[^"\\\n])*"', '""', limpio)
    limpio += '\n' + interpolado
    for simbolo, origen in definido_en.items():
        if origen in vis:
            continue
        if re.search(r'(?<![\w.])' + re.escape(simbolo) + r'\b', limpio):
            problemas.append(
                f'FALTA IMPORT {ruta}: usa "{simbolo}" (definido en {origen})')

    clases = list(re.finditer(r'^class\s+(\w+)', texto, re.M))
    for i, c in enumerate(clases):
        fin = clases[i+1].start() if i+1 < len(clases) else len(texto)
        campos, metodos = [], []
        for linea in texto[c.start():fin].split('\n'):
            if not linea.startswith('  ') or linea.startswith('   '):
                continue
            t = linea[2:]
            m = re.match(r'(?:@override\s+)?(?:static\s+)?[\w<>,\s?\[\]]+?\s+(?:get\s+)?(\w+)\s*[({]', t)
            if m and m.group(1) not in KEY:
                metodos.append(m.group(1)); continue
            m = re.match(r'(?:final\s+|late\s+final\s+|late\s+|static\s+(?:const\s+|final\s+)?|const\s+)?'
                         r'[\w<>,\s?\[\]]+?\s+(\w+)\s*(?:=[^;]*)?;\s*$', t)
            if m and m.group(1) not in KEY:
                campos.append(m.group(1))
        for nombre, n in collections.Counter(campos + metodos).items():
            if n > 1:
                problemas.append(f'DUPLICADO    {ruta}: {c.group(1)}.{nombre} x{n}')

# ── 5. recursos sin liberar ─────────────────────────────────
# Controladores y temporizadores que se crean en un State y no se sueltan
# en dispose(): la pantalla se cierra pero el recurso sigue vivo.
RECURSOS = {
    r'TextEditingController\(': 'dispose',
    r'ScrollController\(': 'dispose',
    r'AnimationController\(': 'dispose',
    r'TabController\(': 'dispose',
    r'FocusNode\(': 'dispose',
    r'PageController\(': 'dispose',
    r'Timer\(': 'cancel',
    r'Timer\.periodic\(': 'cancel',
}

for ruta, texto in por_archivo.items():
    clases = list(re.finditer(r'class (\w*State\w*) extends State<', texto))
    for i, c in enumerate(clases):
        fin = clases[i + 1].start() if i + 1 < len(clases) else len(texto)
        cuerpo = texto[c.start():fin]
        nombre = c.group(1)

        hay = 'void dispose()' in cuerpo
        disp = cuerpo[cuerpo.index('void dispose()'):] if hay else ''

        for patron, metodo in RECURSOS.items():
            for m in re.finditer(r'(_\w+)\s*=\s*[^;]*' + patron, cuerpo):
                campo = m.group(1)
                # Acepta tanto campo.metodo() como campo?.metodo()
                if not re.search(re.escape(campo) + r'\??\.' + metodo + r'\(', disp):
                    problemas.append(
                        f'SIN LIBERAR  {ruta}: {nombre}.{campo} no llama a {metodo}()')

        if re.search(r'\w[\w.]*\.addListener\(', cuerpo):
            if not re.search(r'removeListener|dejarDeEscuchar', disp):
                problemas.append(
                    f'SIN LIBERAR  {ruta}: {nombre} agrega un listener y no lo quita')

        if hay and 'super.dispose()' not in disp:
            problemas.append(f'SIN LIBERAR  {ruta}: {nombre} no llama a super.dispose()')

if problemas:
    print('\n'.join(sorted(set(problemas))))
    sys.exit(1)
print('✅ Sin problemas detectados')
