#!/usr/bin/env bash
# Instala agentes de este repo en un proyecto (.claude/agents) o globalmente (~/.claude/agents).
#
# Uso:
#   ./install.sh                      # todos los agentes en el proyecto actual
#   ./install.sh code-reviewer        # solo los agentes indicados
#   ./install.sh --global             # en ~/.claude/agents (todos tus proyectos)
#   ./install.sh --list               # lista los agentes disponibles
#
# Remoto (sin clonar):
#   curl -fsSL https://raw.githubusercontent.com/freddysae0/co-creators/main/install.sh | bash -s -- [opciones]
set -euo pipefail

REPO_URL="${CLAUDE_AGENTS_REPO:-https://github.com/freddysae0/co-creators.git}"

target="$PWD/.claude/agents"
list=0
force=0
names=()

for arg in "$@"; do
  case "$arg" in
    -g|--global) target="$HOME/.claude/agents" ;;
    -l|--list)   list=1 ;;
    -f|--force)  force=1 ;;
    -h|--help)   sed -n '2,12p' "${BASH_SOURCE[0]:-/dev/null}" 2>/dev/null || true; exit 0 ;;
    -*)          echo "Opción desconocida: $arg" >&2; exit 1 ;;
    *)           names+=("${arg%.md}") ;;
  esac
done

# Usa el repo local si el script se ejecuta desde él; si no (curl | bash), clona en un temporal.
src=""
if [[ -n "${BASH_SOURCE[0]:-}" && -d "$(dirname "${BASH_SOURCE[0]}")/agents" ]]; then
  src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agents"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  git clone --quiet --depth 1 "$REPO_URL" "$tmp/repo"
  src="$tmp/repo/agents"
fi

if [[ $list -eq 1 ]]; then
  for f in "$src"/*.md; do
    name="$(basename "$f" .md)"
    desc="$(sed -n 's/^description:[[:space:]]*//p' "$f" | head -1)"
    printf '  %-20s %s\n' "$name" "$desc"
  done
  exit 0
fi

if [[ ${#names[@]} -eq 0 ]]; then
  for f in "$src"/*.md; do names+=("$(basename "$f" .md)"); done
fi

mkdir -p "$target"
for name in "${names[@]}"; do
  file="$src/$name.md"
  if [[ ! -f "$file" ]]; then
    echo "✗ $name: no existe (usa --list)" >&2
    continue
  fi
  dest="$target/$name.md"
  if [[ -f "$dest" && $force -eq 0 ]] && ! cmp -s "$file" "$dest"; then
    echo "• $name: ya existe con cambios locales, se omite (usa --force para sobrescribir)"
    continue
  fi
  cp "$file" "$dest"
  echo "✓ $name → $dest"
done
