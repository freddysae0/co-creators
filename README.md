# co-creators

Mis agentes (subagents) de [Claude Code](https://code.claude.com) para el día a día. Son archivos Markdown, así que funcionan en cualquier proyecto sin importar el lenguaje.

## Agentes

| Agente | Para qué |
| --- | --- |
| [`code-reviewer`](agents/code-reviewer.md) | Revisa el `git diff` buscando bugs, seguridad y mantenibilidad |
| [`debugger`](agents/debugger.md) | Encuentra la causa raíz de errores y tests rotos |

## Instalación

### Opción 1: como plugin de Claude Code (recomendado)

Dentro de Claude Code, en cualquier proyecto:

```
/plugin marketplace add freddysae0/co-creators
/plugin install co-creators@freddysae0
```

Para traer los últimos cambios: `/plugin marketplace update freddysae0`.

### Opción 2: copiar los archivos al proyecto

Útil si quieres versionar los agentes dentro del propio repo del proyecto (`.claude/agents/`) o editarlos por proyecto.

**macOS / Linux / Git Bash**

```bash
# todos los agentes en el proyecto actual
curl -fsSL https://raw.githubusercontent.com/freddysae0/co-creators/main/install.sh | bash

# solo algunos / globalmente / listar
curl -fsSL https://raw.githubusercontent.com/freddysae0/co-creators/main/install.sh | bash -s -- code-reviewer
curl -fsSL https://raw.githubusercontent.com/freddysae0/co-creators/main/install.sh | bash -s -- --global
curl -fsSL https://raw.githubusercontent.com/freddysae0/co-creators/main/install.sh | bash -s -- --list
```

**Windows (PowerShell)**

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/freddysae0/co-creators/main/install.ps1)))
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/freddysae0/co-creators/main/install.ps1))) code-reviewer
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/freddysae0/co-creators/main/install.ps1))) -Global
```

Los archivos que ya existen con cambios locales no se sobrescriben salvo que pases `--force` / `-Force`.

## Añadir un agente nuevo

1. Copia [`templates/agent.md`](templates/agent.md) a `agents/<nombre>.md`.
2. Rellena `name`, `description` (Claude decide cuándo delegar leyendo esto) y el prompt.
3. Commit y push. Se actualiza en todos lados con `/plugin marketplace update` o volviendo a correr el instalador.

Mantén los agentes agnósticos al lenguaje: que detecten el stack (package.json, pyproject.toml, go.mod, Cargo.toml…) en lugar de asumirlo.
