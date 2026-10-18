"""Cuenta los argumentos de las llamadas a la capa de datos (DBQuery, DBExec,
DBExists, DBScalar y el helper P) aunque ocupen varias lineas con "_".
"""
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "site"))
FUNCS = {"DBQuery": 2, "DBExec": 2, "DBExists": 2, "DBScalar": 3, "P": 3}
bad = []
checked = 0


def scan(text, start):
    """Desde el '(' de apertura: devuelve (num_args, texto_args)."""
    depth, i, n = 0, start, len(text)
    top_commas = 0
    in_str = False
    while i < n:
        c = text[i]
        if c == '"':
            in_str = not in_str
        elif not in_str:
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    return top_commas + 1, text[start:i]
            elif c == "," and depth == 1:
                top_commas += 1
        i += 1
    return None, text[start:start + 60]


for dirpath, _, files in os.walk(ROOT):
    for fn in sorted(files):
        if not fn.lower().endswith(".asp"):
            continue
        path = os.path.join(dirpath, fn)
        rel = os.path.relpath(path, ROOT)
        raw = open(path, encoding="utf-8").read()
        body = "\n".join(re.findall(r'<%(?!@)(.*?)%>', raw, re.S))
        # quita comentarios de linea
        body = "\n".join(re.sub(r"(^|\s)'(\s.*)?$", "", l) for l in body.splitlines())
        for name, expected in FUNCS.items():
            for m in re.finditer(r'(?<![\w.])' + name + r'\s*\(', body):
                paren = body.index("(", m.start())
                args, txt = scan(body, paren)
                checked += 1
                if args is None:
                    bad.append(f"{rel}: {name}( sin cierre -> {txt!r}")
                elif args != expected:
                    line_no = body[:m.start()].count("\n") + 1
                    snippet = " ".join(txt.split())[:90]
                    bad.append(f"{rel}:{line_no}: {name}() con {args} args (espera {expected}): {snippet}")

print("Llamadas revisadas:", checked)
if bad:
    print("PROBLEMAS:")
    for b in bad:
        print("  -", b)
else:
    print("Todas las llamadas a la capa de datos tienen el numero correcto de argumentos.")
