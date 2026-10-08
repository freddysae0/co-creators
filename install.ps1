# Instala agentes de este repo en un proyecto (.claude\agents) o globalmente (~\.claude\agents).
#
# Uso:
#   .\install.ps1                         # todos los agentes en el proyecto actual
#   .\install.ps1 code-reviewer debugger  # solo los agentes indicados
#   .\install.ps1 -Global                 # en ~\.claude\agents (todos tus proyectos)
#   .\install.ps1 -List                   # lista los agentes disponibles
#
# Remoto (sin clonar):
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/freddysae0/co-creators/main/install.ps1))) [opciones]
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Names,
    [switch]$Global,
    [switch]$List,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repoUrl = if ($env:CLAUDE_AGENTS_REPO) { $env:CLAUDE_AGENTS_REPO } else { 'https://github.com/freddysae0/co-creators.git' }

$target = if ($Global) { Join-Path $HOME '.claude\agents' } else { Join-Path (Get-Location) '.claude\agents' }

# Usa el repo local si el script se ejecuta desde el; si no (irm | iex), clona en un temporal.
$tmp = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot 'agents'))) {
    $src = Join-Path $PSScriptRoot 'agents'
} else {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid())
    git clone --quiet --depth 1 $repoUrl "$tmp\repo"
    if ($LASTEXITCODE -ne 0) { throw "No se pudo clonar $repoUrl" }
    $src = "$tmp\repo\agents"
}

try {
    $available = Get-ChildItem $src -Filter *.md

    if ($List) {
        foreach ($f in $available) {
            $desc = (Select-String -Path $f.FullName -Pattern '^description:\s*(.*)' | Select-Object -First 1).Matches.Groups[1].Value
            '  {0,-20} {1}' -f $f.BaseName, $desc
        }
        return
    }

    if (-not $Names) { $Names = $available.BaseName }

    New-Item -ItemType Directory -Force $target | Out-Null
    foreach ($name in $Names) {
        $name = $name -replace '\.md$', ''
        $file = Join-Path $src "$name.md"
        if (-not (Test-Path $file)) {
            Write-Warning "${name}: no existe (usa -List)"
            continue
        }
        $dest = Join-Path $target "$name.md"
        if ((Test-Path $dest) -and -not $Force -and ((Get-FileHash $file).Hash -ne (Get-FileHash $dest).Hash)) {
            "- ${name}: ya existe con cambios locales, se omite (usa -Force para sobrescribir)"
            continue
        }
        Copy-Item $file $dest -Force
        "+ $name -> $dest"
    }
} finally {
    if ($tmp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
}
