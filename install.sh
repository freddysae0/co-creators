#!/usr/bin/env bash
# Instala agentes de este repo en un proyecto (.claude/agents) o globalmente (~/.claude/agents).
#
# Uso:
#   ./install.sh                      # todos los agentes en el proyecto actual
#   ./install.sh gamedev              # una categoría (incluye siempre el coordinador)
#   ./install.sh revisor guionista    # agentes sueltos
#   ./install.sh --global             # en ~/.claude/agents (todos tus proyectos)
#   ./install.sh --list               # lista categorías y agentes
#
# Remoto (sin clonar):
#   curl -fsSL https://raw.githubusercontent.com/freddysae0/co-creators/main/install.sh | bash -s -- [opciones]
set -euo pipefail

REPO_URL="${CO_CREATORS_REPO:-https://github.com/freddysae0/co-creators.git}"

target="$PWD/.claude/agents"
list=0
force=0
names=()

for arg in "$@"; do
  case "$arg" in
    -g|--global) target="$HOME/.claude/agents" ;;
    -l|--list)   list=1 ;;
    -f|--force)  force=1 ;;
    -h|--help)   sed -n '2,13p' "${BASH_SOURCE[0]:-/dev/null}" 2>/dev/null || true; exit 0 ;;
    -*)          echo "Opción desconocida: $arg" >&2; exit 1 ;;
    *)           names+=("${arg%.md}") ;;
  esac
done

# Usa el repo local si el script se ejecuta desde él; si no (curl | bash), clona en un temporal.
if [[ -n "${BASH_SOURCE[0]:-}" && -d "$(dirname "${BASH_SOURCE[0]}")/plugins" ]]; then
  plugins="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/plugins"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  git clone --quiet --depth 1 "$REPO_URL" "$tmp/repo"
  plugins="$tmp/repo/plugins"
fi

if [[ $list -eq 1 ]]; then
  for dir in "$plugins"/*/; do
    echo "$(basename "$dir")/"
    for f in "$dir"agents/*.md; do
      desc="$(sed -n 's/^description:[[:space:]]*//p' "$f" | head -1 | cut -c1-90)"
      printf '  %-20s %s…\n' "$(basename "$f" .md)" "$desc"
    done
  done
  exit 0
fi

# Resuelve categorías y agentes a una lista de archivos.
files=()
if [[ ${#names[@]} -eq 0 ]]; then
  files=("$plugins"/*/agents/*.md)
else
  for name in "${names[@]}"; do
    if [[ -d "$plugins/$name/agents" ]]; then
      files+=("$plugins/$name/agents"/*.md "$plugins/coordinador/agents"/*.md)
    else
      match=("$plugins"/*/agents/"$name".md)
      if [[ -f "${match[0]}" ]]; then
        files+=("${match[0]}")
      else
        echo "✗ $name: no existe (usa --list)" >&2
      fi
    fi
  done
fi

mkdir -p "$target"
seen=" "
for file in "${files[@]}"; do
  name="$(basename "$file" .md)"
  [[ "$seen" == *" $name "* ]] && continue
  seen+="$name "
  dest="$target/$name.md"
  if [[ -f "$dest" && $force -eq 0 ]] && ! cmp -s "$file" "$dest"; then
    echo "• $name: ya existe con cambios locales, se omite (usa --force para sobrescribir)"
    continue
  fi
  cp "$file" "$dest"
  echo "✓ $name → $dest"
done
