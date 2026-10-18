"""Revision estatica de los .asp de PoliMusic (v2).

Comprueba:
  1. Directiva @ y Option Explicit en paginas (no en includes).
  2. Que los #include apunten a archivos existentes.
  3. Balance de bloques: If/End If, For/Next, Do/Loop, Select Case/End Select,
     Sub/End Sub, Function/End Function, With/End With.
  4. Numero de argumentos en llamadas de una sola linea a Sub/Function propias.
     (Las llamadas con continuacion de linea "_" se reportan como INFO.)
"""
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "site"))
problems = []
notes = []

# --- palabras clave (se sensibles a mayusculas para no confundir SQL: FOR XML) ---
OPEN_CLOSE = [
    (r'^\s*If\s', r'^\s*End\s+If\b', 'If'),
    (r'^\s*For\s+Each\s|^\s*For\s+\w', r'^\s*Next\b', 'For'),
    (r'^\s*Do\b', r'^\s*Loop\b', 'Do'),
    (r'^\s*Select\s+Case\s', r'^\s*End\s+Select\b', 'Select Case'),
    (r'^\s*Sub\s', r'^\s*End\s+Sub\b', 'Sub'),
    (r'^\s*Function\s', r'^\s*End\s+Function\b', 'Function'),
    (r'^\s*With\s', r'^\s*End\s+With\b', 'With'),
]

SINGLE_IF = re.compile(r'^\s*If\s.*\bThen\s+\S')


def code_lines(raw):
    """Devuelve las lineas de codigo VBScript (dentro de <% %>), sin comentarios."""
    out = []
    for m in re.finditer(r'<%(?!@)(.*?)%>', raw, re.S):
        body = m.group(1)
        if body.startswith("="):
            body = ""
        for line in body.splitlines():
            s = re.sub(r"(^|\s)'(\s.*)?$", "", line)          # comentario de apostrofo
            s = re.sub(r'^\s*REM\s.*$', "", s, flags=re.I)
            out.append(s.rstrip())
    return out


def split_args(text):
    args, depth, cur, in_str = [], 0, "", False
    for ch in text:
        if ch == '"':
            in_str = not in_str
            cur += ch
        elif in_str:
            cur += ch
        elif ch == "(":
            depth += 1
            cur += ch
        elif ch == ")":
            depth = max(0, depth - 1)
            cur += ch
        elif ch == "," and depth == 0:
            args.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        args.append(cur.strip())
    return args


def main():
    asp_files = []
    for dirpath, _, files in os.walk(ROOT):
        for f in files:
            if f.lower().endswith(".asp"):
                asp_files.append(os.path.join(dirpath, f))
    asp_files.sort()

    # firmas de Sub/Function propias
    signatures = {}
    for path in asp_files:
        code = open(path, encoding="utf-8").read()
        for m in re.finditer(r'^\s*(?:Public\s+|Private\s+)?(?:Sub|Function)\s+(\w+)\s*\(([^)]*)\)',
                             code, re.M):
            params = [p.strip() for p in m.group(2).split(",") if p.strip()]
            signatures[m.group(1)] = (len(params), os.path.relpath(path, ROOT))

    for path in asp_files:
        rel = os.path.relpath(path, ROOT)
        raw = open(path, encoding="utf-8").read()
        is_include = rel.startswith("includes") or rel.endswith("_tabs.asp")

        if not is_include:
            if not raw.lstrip().startswith("<%@"):
                problems.append(f"{rel}: no empieza con la directiva @")
            if "Option Explicit" not in raw:
                problems.append(f"{rel}: falta Option Explicit")

        # includes (ignorando los que aparecen dentro de comentarios)
        for m in re.finditer(r'<!--\s*#include\s+(?:file|virtual)\s*=\s*"([^"]+)"', raw, re.I):
            if m.group(1).strip() == "...":
                continue
            target = os.path.normpath(os.path.join(os.path.dirname(path), m.group(1)))
            if not os.path.exists(target):
                problems.append(f"{rel}: include inexistente -> {m.group(1)}")

        lines = code_lines(raw)
        code = "\n".join(lines)

        # 3) balance de bloques
        for open_re, close_re, name in OPEN_CLOSE:
            o = len([l for l in lines if re.match(open_re, l)])
            c = len([l for l in lines if re.match(close_re, l)])
            if name == "If":
                o -= len([l for l in lines if SINGLE_IF.match(l)])
            if o != c:
                problems.append(f"{rel}: desbalance {name}: abiertos={o} cerrados={c}")

        # 4) llamadas en una sola linea
        for i, line in enumerate(lines):
            if line.rstrip().endswith("_"):
                for name, (n, _) in signatures.items():
                    if re.search(r'(?<![\w.])' + name + r'\s+', line):
                        notes.append(f"{rel}:{i+1}: llamada con continuacion de linea a {name} (revisar a mano)")
                continue
            for name, (nargs, where) in signatures.items():
                m = re.search(r'(?<![\w.])(?<![=(])' + name + r'\s+(?![\(=,])', line)
                if not m:
                    continue
                rest = line[m.end():].strip()
                if rest == "":
                    continue
                args = split_args(rest)
                if len(args) != nargs:
                    problems.append(
                        f"{rel}:{i+1}: {name}() recibe {len(args)} args, definida con {nargs} ({where}): {rest[:80]!r}")

    print("Archivos revisados:", len(asp_files))
    print()
    if notes:
        print("NOTAS (revision manual):")
        for n in sorted(set(notes)):
            print("  -", n)
        print()
    if problems:
        print("POSIBLES PROBLEMAS:")
        for p in problems:
            print("  -", p)
        sys.exit(1)
    print("Sin problemas detectados.")


if __name__ == "__main__":
    main()
