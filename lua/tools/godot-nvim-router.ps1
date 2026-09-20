param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [string]$Line = "1",
    [string]$Column = "1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Normalize-ProjectPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $full = [System.IO.Path]::GetFullPath($Path)
    $normalized = $full.Replace('\', '/')

    if ($normalized -notmatch '^[A-Za-z]:/$' -and $normalized -ne '/') {
        $normalized = $normalized.TrimEnd('/')
    }

    return $normalized.ToLowerInvariant()
}

function Find-GodotProjectRoot {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullFile = [System.IO.Path]::GetFullPath($Path)
    $directory = [System.IO.Path]::GetDirectoryName($fullFile)

    while (-not [string]::IsNullOrEmpty($directory)) {
        if (Test-Path -LiteralPath (Join-Path $directory 'project.godot') -PathType Leaf) {
            return [System.IO.Path]::GetFullPath($directory)
        }

        $parent = [System.IO.Directory]::GetParent($directory)
        if ($null -eq $parent) {
            break
        }

        $directory = $parent.FullName
    }

    return $null
}

function Get-Sha256Hex {
    param([Parameter(Mandatory = $true)][string]$Text)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        $hash = $sha.ComputeHash($bytes)
        return (($hash | ForEach-Object { $_.ToString('x2') }) -join '')
    }
    finally {
        $sha.Dispose()
    }
}

[int]$lineNumber = 1
[int]$columnNumber = 1

if (-not [int]::TryParse($Line, [ref]$lineNumber) -or $lineNumber -lt 1) {
    $lineNumber = 1
}
if (-not [int]::TryParse($Column, [ref]$columnNumber) -or $columnNumber -lt 1) {
    $columnNumber = 1
}

$resolvedFile = [System.IO.Path]::GetFullPath($FilePath)
if (-not (Test-Path -LiteralPath $resolvedFile -PathType Leaf)) {
    exit 10
}

$root = Find-GodotProjectRoot -Path $resolvedFile
if ([string]::IsNullOrEmpty($root)) {
    exit 11
}

$rootKey = Normalize-ProjectPath -Path $root
$hash = Get-Sha256Hex -Text $rootKey
$server = "//./pipe/nvim-godot-project-$hash"

# Fail closed: never guess another Nvim and never fall back to a shared TCP port.
& nvim --server $server --remote-expr "1" *> $null
if ($LASTEXITCODE -ne 0) {
    exit 20
}

# --remote is implemented as :drop, so an already-open buffer is reused.
& nvim --server $server --remote $resolvedFile *> $null
if ($LASTEXITCODE -ne 0) {
    exit 21
}

& nvim --server $server --remote-expr "cursor($lineNumber, $columnNumber)" *> $null
if ($LASTEXITCODE -ne 0) {
    exit 22
}

exit 0
