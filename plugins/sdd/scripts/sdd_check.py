#!/usr/bin/env python3
"""Comprueba una carpeta de spec SDD (spec.md, plan.md, tareas.md) y calcula las olas de ejecución.

Uso:  python sdd_check.py <carpeta-de-la-spec> [--spec-only]

Errores (exit 1): [ACLARAR]/[APORTE] pendientes, REQ sin AC, AC sin tipo o con REQ inexistente,
tareas sin Cubre/Archivos/Verificar, dependencias inexistentes o en ciclo, REQ sin tarea.
Avisos: palabras vagas, plan sin alternativas, dos tareas de la misma ola tocando el mismo archivo,
tareas demasiado grandes.
Solo usa la biblioteca estándar.
"""
import re
import sys
from pathlib import Path

REQ_RE = re.compile(r"\bREQ-(?:[A-Z]+-)?\d+\b")
AC_RE = re.compile(r"\bAC-(?:[A-Z]+-)?\d+\b")
TSK_RE = re.compile(r"\bTSK-\d+\b")
DEF_PREFIX = r"^\s*(?:[-*|#>]+\s*)?(?:\*\*)?\s*(?:\[[ xX]\]\s*)?"
TYPE_RE = re.compile(r"\[(AUTO|MANUAL|USUARIO|FUNC|PIE|DIRECTOR)\]")
VAGUE = ["rápido", "rápida", "intuitivo", "intuitiva", "fluido", "fácil", "varios", "varias",
         "etc.", "adecuado", "adecuada", "razonable", "suficiente", "user-friendly", "fast", "easy"]
MAX_FILES_PER_TASK = 8

errors, warnings = [], []


def definitions(text, id_re):
    """Bloques {id: texto} para cada ID definido al principio de una línea."""
    pattern = re.compile(DEF_PREFIX + "(" + id_re.pattern + ")")
    blocks, current = {}, None
    for line in text.splitlines():
        m = pattern.match(line)
        if m:
            current = m.group(1)
            blocks.setdefault(current, "")
        elif re.match(r"^\s*#", line) or (current and re.match(DEF_PREFIX + r"(REQ|AC|TSK)-", line)):
            current = None
        if current:
            blocks[current] += line + "\n"
    return blocks


def check_spec(spec_path):
    text = spec_path.read_text(encoding="utf-8")
    for tag in ("[ACLARAR", "[APORTE"):
        n = text.count(tag)
        if n:
            errors.append(f"spec.md: {n} {tag}] pendiente(s)")
    reqs = definitions(text, REQ_RE)
    acs = definitions(text, AC_RE)
    if not reqs:
        errors.append("spec.md: no hay requisitos REQ-…")
    if not acs:
        errors.append("spec.md: no hay criterios AC-…")
    covered = {}
    for ac, block in acs.items():
        if not TYPE_RE.search(block):
            errors.append(f"spec.md: {ac} sin tipo [AUTO|MANUAL|USUARIO]")
        refs = set(REQ_RE.findall(block))
        for r in refs - set(reqs):
            errors.append(f"spec.md: {ac} cubre {r}, que no existe")
        covered[ac] = refs & set(reqs)
    for r in reqs:
        if not any(r in refs for refs in covered.values()):
            errors.append(f"spec.md: {r} no tiene ningún AC")
    lower = text.lower()
    found = [w for w in VAGUE if re.search(r"(?<!\w)" + re.escape(w) + r"(?!\w)", lower)]
    if found:
        warnings.append("spec.md: palabras vagas (revisa si son criterios medibles): " + ", ".join(found))
    return reqs, covered


def field(block, name):
    m = re.search(r"^\s*" + name + r"\s*:\s*(.+)$", block, re.MULTILINE | re.IGNORECASE)
    return m.group(1).strip() if m else ""


def check_tasks(tareas_path, reqs, ac_cover):
    text = tareas_path.read_text(encoding="utf-8")
    tasks = definitions(text, TSK_RE)
    if not tasks:
        errors.append("tareas.md: no hay tareas TSK-…")
        return
    info = {}
    for t, block in tasks.items():
        cubre = field(block, "Cubre")
        archivos = field(block, "Archivos")
        verificar = field(block, "Verificar")
        depende = field(block, "Depende de")
        for name, value in (("Cubre", cubre), ("Archivos", archivos), ("Verificar", verificar)):
            if not value or value in ("—", "-"):
                errors.append(f"tareas.md: {t} sin '{name}'")
        files = [f.strip(" `") for f in re.split(r"[,;]", archivos) if f.strip(" `—-")]
        if len(files) > MAX_FILES_PER_TASK:
            warnings.append(f"tareas.md: {t} toca {len(files)} archivos; ¿se puede partir?")
        deps = set(TSK_RE.findall(depende))
        for d in deps - set(tasks):
            errors.append(f"tareas.md: {t} depende de {d}, que no existe")
        info[t] = {"deps": deps & set(tasks), "files": set(files),
                   "reqs": set(REQ_RE.findall(cubre)), "acs": set(AC_RE.findall(cubre))}

    # Cobertura: REQ cubierto directamente o a través de un AC que lo cubre.
    if reqs:
        done = set()
        for i in info.values():
            done |= i["reqs"]
            for ac in i["acs"]:
                done |= ac_cover.get(ac, set())
        for r in reqs:
            if r not in done:
                errors.append(f"tareas.md: {r} no lo cubre ninguna tarea")

    # Olas: niveles topológicos. Si queda algo sin nivel, hay un ciclo.
    level, remaining = {}, dict(info)
    wave = 0
    while remaining:
        ready = [t for t, i in remaining.items() if i["deps"] <= set(level)]
        if not ready:
            errors.append("tareas.md: dependencias en ciclo entre " + ", ".join(sorted(remaining)))
            break
        wave += 1
        for t in ready:
            level[t] = wave
            del remaining[t]

    waves = {}
    for t, w in level.items():
        waves.setdefault(w, []).append(t)
    print("\nOlas de ejecución (las tareas de una misma ola pueden ir en paralelo):")
    for w in sorted(waves):
        ts = sorted(waves[w], key=lambda x: int(x.split("-")[1]))
        print(f"  Ola {w}: {', '.join(ts)}")
        for a_i, a in enumerate(ts):
            for b in ts[a_i + 1:]:
                shared = info[a]["files"] & info[b]["files"]
                if shared:
                    warnings.append(f"tareas.md: {a} y {b} están en la ola {w} y tocan {', '.join(sorted(shared))}; "
                                    "añade una dependencia o no las lances en paralelo")


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except AttributeError:
        pass
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) != 1:
        print(__doc__)
        return 2
    folder = Path(args[0])
    spec = folder / "spec.md"
    if not spec.is_file():
        print(f"No existe {spec}")
        return 2
    reqs, ac_cover = check_spec(spec)
    if "--spec-only" not in sys.argv:
        plan, tareas = folder / "plan.md", folder / "tareas.md"
        if not plan.is_file():
            errors.append("falta plan.md")
        elif not re.search(r"^#+\s*Alternativas", plan.read_text(encoding="utf-8"), re.MULTILINE | re.IGNORECASE):
            warnings.append("plan.md: no tiene sección 'Alternativas'")
        if not tareas.is_file():
            errors.append("falta tareas.md")
        else:
            check_tasks(tareas, reqs, ac_cover)

    print()
    for w in warnings:
        print("AVISO  " + w)
    for e in errors:
        print("ERROR  " + e)
    print(f"\n{len(errors)} error(es), {len(warnings)} aviso(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
