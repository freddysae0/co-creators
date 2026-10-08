# co-creators

Mis agentes (subagents) de [Claude Code](https://code.claude.com) para el día a día, organizados por categoría. Son archivos Markdown, así que funcionan en cualquier proyecto sin importar el lenguaje o el motor.

## Estructura

```
plugins/
  coordinador/   ← no pertenece a ninguna categoría: solo coordina e invoca a otros
  general/       ← cualquier proyecto
  sdd/           ← desarrollo guiado por specs, agnóstico al lenguaje
  gamedev/       ← desarrollo de videojuegos
```

Cada carpeta de `plugins/` es un plugin de Claude Code con sus agentes en `agents/`.

### Coordinador

| Agente | Para qué |
| --- | --- |
| [`coordinador`](plugins/coordinador/agents/coordinador.md) | Encuadra la tarea y la reparte al agente (o coordinador) indicado: en paralelo cuando se puede, con revisión obligatoria e iteración. **No produce nada él mismo**, y elige entre los agentes que haya instalados, sin una lista fija. |

### general

| Agente | Para qué |
| --- | --- |
| [`code-reviewer`](plugins/general/agents/code-reviewer.md) | Revisa el `git diff` buscando bugs, seguridad y mantenibilidad |
| [`debugger`](plugins/general/agents/debugger.md) | Encuentra la causa raíz de errores y tests rotos |

### sdd

Set básico para **desarrollo guiado por specs** en cualquier lenguaje. Cada cambio vive en `<carpeta>/NNN-<slug>/` con `spec.md` (requisitos EARS + criterios de aceptación `[AUTO]/[MANUAL]/[USUARIO]`), `plan.md` y `tareas.md`. Sin spec aprobada no se implementa.

**Dónde se guardan las specs:** si el repo ya tiene SDD configurado (lo dice su `CLAUDE.md` / `AGENTS.md` o ya tiene una carpeta como `specs/`), se usa esa. Si no, en `.sdd/`, **fuera de Git**: los agentes crean `.sdd/.gitignore` con `*`, así que se ignora sola sin tocar el `.gitignore` del proyecto.

| Agente | Fase | Para qué |
| --- | --- | --- |
| [`coordinador-sdd`](plugins/sdd/agents/coordinador-sdd.md) | todas | Lleva el flujo de principio a fin; solo invoca a los `spec-*` |
| [`spec-autor`](plugins/sdd/agents/spec-autor.md) | especificar | Escribe la spec contrato y las preguntas `[ACLARAR]` |
| [`spec-planificador`](plugins/sdd/agents/spec-planificador.md) | planificar | `plan.md` + `tareas.md` pequeñas y verificables |
| [`spec-implementador`](plugins/sdd/agents/spec-implementador.md) | implementar | Una tarea por encargo, test primero |
| [`spec-verificador`](plugins/sdd/agents/spec-verificador.md) | verificar | Ejecuta y aporta evidencia AC a AC (matriz de trazabilidad) |
| [`spec-revisor`](plugins/sdd/agents/spec-revisor.md) | revisar | Veredicto sobre spec, plan o implementación. Solo lectura |

Flujo: especificar → aclarar con el usuario → revisar spec → **aprobación del usuario** → planificar → revisar plan → implementar tarea a tarea → verificar → revisar → aceptación.

### gamedev

Equipo nacido en un proyecto de mundo abierto en Unreal Engine 5.7, generalizado para cualquier juego y motor. Trabaja con **desarrollo guiado por specs** (requisitos EARS, criterios de aceptación con tipo `[AUTO]/[FUNC]/[PIE]/[DIRECTOR]`) y un formato de informe común.

| Agente | Para qué |
| --- | --- |
| [`especificador`](plugins/gamedev/agents/especificador.md) | Convierte peticiones en specs contrato y decide a qué especialistas consultar |
| [`disenador-juego`](plugins/gamedev/agents/disenador-juego.md) | Sistemas, bucles, feel y tuning con números concretos |
| [`disenador-misiones`](plugins/gamedev/agents/disenador-misiones.md) | Misiones y actividades con porqué, variantes y consecuencias |
| [`guionista`](plugins/gamedev/agents/guionista.md) | Historia, personajes, diálogos, barks y textos del mundo |
| [`historiador`](plugins/gamedev/agents/historiador.md) | Investiga con fuentes el lugar o la época reales del juego |
| [`director-arte`](plugins/gamedev/agents/director-arte.md) | Dirección visual, concepts, revisión de capturas y origen de cada asset |
| [`promptista`](plugins/gamedev/agents/promptista.md) | Prompts de imagen consistentes y cola de generación |
| [`animador`](plugins/gamedev/agents/animador.md) | Locomoción, transiciones, combate, cinemáticas, rigs |
| [`musico`](plugins/gamedev/agents/musico.md) | Música adaptativa, ambientes, SFX, voces y licencias |
| [`desarrollador`](plugins/gamedev/agents/desarrollador.md) | Implementa specs aprobadas en el motor del proyecto, con tests y trazabilidad |
| [`qa-jugabilidad`](plugins/gamedev/agents/qa-jugabilidad.md) | Ejecuta y aporta evidencia, AC a AC. No arregla código |
| [`revisor`](plugins/gamedev/agents/revisor.md) | Revisor de solo lectura con checklist por tipo de entregable |
| [`cronista`](plugins/gamedev/agents/cronista.md) | Bitácora del making-of y borradores de blog |

## Instalación

### Opción 1: como plugin de Claude Code (recomendado)

Dentro de Claude Code, en cualquier proyecto:

```
/plugin marketplace add freddysae0/co-creators
/plugin install coordinador@co-creators
/plugin install gamedev@co-creators
/plugin install general@co-creators
/plugin install sdd@co-creators
```

Instala solo las categorías que necesites. Instalados como plugin, los agentes se llaman `gamedev:revisor`, `general:debugger`, etc. Para traer los últimos cambios: `/plugin marketplace update co-creators`.

### Opción 2: copiar los archivos al proyecto

Útil para versionar los agentes dentro del propio repo del proyecto (`.claude/agents/`) o editarlos por proyecto. Acepta categorías (que incluyen siempre el coordinador) o agentes sueltos.

**macOS / Linux / Git Bash**

```bash
curl -fsSL https://raw.githubusercontent.com/freddysae0/co-creators/main/install.sh | bash                       # todo
curl -fsSL https://raw.githubusercontent.com/freddysae0/co-creators/main/install.sh | bash -s -- gamedev           # una categoría + coordinador
curl -fsSL https://raw.githubusercontent.com/freddysae0/co-creators/main/install.sh | bash -s -- revisor debugger  # agentes sueltos
curl -fsSL https://raw.githubusercontent.com/freddysae0/co-creators/main/install.sh | bash -s -- --global          # en ~/.claude/agents
curl -fsSL https://raw.githubusercontent.com/freddysae0/co-creators/main/install.sh | bash -s -- --list
```

**Windows (PowerShell)**

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/freddysae0/co-creators/main/install.ps1)))
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/freddysae0/co-creators/main/install.ps1))) gamedev
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/freddysae0/co-creators/main/install.ps1))) -Global
```

Los archivos que ya existen con cambios locales no se sobrescriben salvo que pases `--force` / `-Force`.

## Usar el coordinador

Un subagente no puede lanzar a otros subagentes, así que el coordinador tiene que ser el **agente principal** de la sesión:

```bash
claude --agent coordinador:coordinador   # instalado como plugin
claude --agent coordinador               # instalado con los scripts
```

Para SDD puedes arrancar directamente con su coordinador: `claude --agent sdd:coordinador-sdd`. El coordinador general también puede delegar en él: le devuelve el plan de la fase y lo ejecuta.

O ponlo por defecto en el proyecto con `"agent": "coordinador:coordinador"` en `.claude/settings.json`. Si lo invocas como subagente, en lugar de trabajar devuelve un plan de delegación para que lo ejecute la sesión principal.

## Añadir agentes o categorías

1. Copia [`templates/agent.md`](templates/agent.md) a `plugins/<categoria>/agents/<nombre>.md` y rellena `name`, `description` (Claude decide cuándo delegar leyendo esto) y el prompt.
2. **Categoría nueva:** crea `plugins/<categoria>/.claude-plugin/plugin.json` (copia uno existente) y añádela a `.claude-plugin/marketplace.json`. Si la categoría es grande, puede tener su propio `coordinador-<categoria>`: el coordinador general delegará en él.
3. Comprueba con `claude plugin validate .` y haz commit y push.

Mantén los agentes agnósticos al proyecto: que lean `CLAUDE.md` / `AGENTS.md` y detecten el stack o el motor, en lugar de asumir rutas concretas.
