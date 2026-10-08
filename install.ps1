# Instala agentes de este repo en un proyecto (.claude\agents) o globalmente (~\.claude\agents).
#
# Uso:
#   .\install.ps1                        # todos los agentes en el proyecto actual
#   .\install.ps1 gamedev                # una categoria (incluye siempre el coordinador)
#   .\install.ps1 revisor guionista      # agentes sueltos
#   .\install.ps1 -Global                # en ~\.claude\agents (todos tus proyectos)
#   .\install.ps1 -List                  # lista categorias y agentes
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
$repoUrl = if ($env:CO_CREATORS_REPO) { $env:CO_CREATORS_REPO } else { 'https://github.com/freddysae0/co-creators.git' }

$target = if ($Global) { Join-Path $HOME '.claude\agents' } else { Join-Path (Get-Location) '.claude\agents' }

# Usa el repo local si el script se ejecuta desde el; si no (irm), clona en un temporal.
$tmp = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot 'plugins'))) {
    $plugins = Join-Path $PSScriptRoot 'plugins'
} else {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid())
    git clone --quiet --depth 1 $repoUrl "$tmp\repo"
    if ($LASTEXITCODE -ne 0) { throw "No se pudo clonar $repoUrl" }
    $plugins = "$tmp\repo\plugins"
}

function Get-Agents($category) { Get-ChildItem (Join-Path $plugins "$category\agents") -Filter *.md }

try {
    $categories = Get-ChildItem $plugins -Directory

    if ($List) {
        foreach ($c in $categories) {
            "$($c.Name)/"
            foreach ($f in Get-Agents $c.Name) {
                $desc = (Select-String -Path $f.FullName -Pattern '^description:\s*(.*)' | Select-Object -First 1).Matches.Groups[1].Value
                if ($desc.Length -gt 90) { $desc = $desc.Substring(0, 90) + '...' }
                '  {0,-20} {1}' -f $f.BaseName, $desc
            }
        }
        return
    }

    # Resuelve categorias y agentes a una lista de archivos.
    $files = @()
    if (-not $Names) {
        foreach ($c in $categories) { $files += Get-Agents $c.Name }
    } else {
        foreach ($name in $Names) {
            $name = $name -replace '\.md$', ''
            if ($categories.Name -contains $name) {
                $files += Get-Agents $name
                $files += Get-Agents 'coordinador'
            } else {
                $match = Get-ChildItem $plugins -Recurse -Filter "$name.md" | Select-Object -First 1
                if ($match) { $files += $match } else { Write-Warning "${name}: no existe (usa -List)" }
            }
        }
    }

    New-Item -ItemType Directory -Force $target | Out-Null
    $seen = @{}
    foreach ($file in $files) {
        $name = $file.BaseName
        if ($seen[$name]) { continue }
        $seen[$name] = $true
        $dest = Join-Path $target "$name.md"
        if ((Test-Path $dest) -and -not $Force -and ((Get-FileHash $file.FullName).Hash -ne (Get-FileHash $dest).Hash)) {
            "- ${name}: ya existe con cambios locales, se omite (usa -Force para sobrescribir)"
            continue
        }
        Copy-Item $file.FullName $dest -Force
        "+ $name -> $dest"
    }

    # Scripts de apoyo de cada categoria instalada (p. ej. sdd_check.py) -> .claude/scripts/<categoria>/
    $catDirs = $files | ForEach-Object { $_.Directory.Parent } | Sort-Object FullName -Unique
    foreach ($cat in $catDirs) {
        $scripts = Join-Path $cat.FullName 'scripts'
        if (-not (Test-Path $scripts)) { continue }
        $destDir = Join-Path (Split-Path $target -Parent) "scripts\$($cat.Name)"
        New-Item -ItemType Directory -Force $destDir | Out-Null
        Copy-Item (Join-Path $scripts '*') $destDir -Force
        "+ scripts -> $destDir"
    }
} finally {
    if ($tmp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
}
