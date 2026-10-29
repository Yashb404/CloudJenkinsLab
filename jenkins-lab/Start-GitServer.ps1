param([string]$ProjectPath = (Join-Path $PSScriptRoot '..\festpass-java'), [int]$Port = 9418)
$ErrorActionPreference = 'Stop'
if ($Port -lt 1024 -or $Port -gt 65535) { throw 'Choose a port between 1024 and 65535.' }
$repo = (Resolve-Path $ProjectPath -ErrorAction Stop).Path
if (-not (Test-Path (Join-Path $repo '.git') -PathType Container)) {
    throw 'Initialize and commit the festpass-java repository before starting the Git server.'
}
& git -C $repo rev-parse --verify HEAD
if ($LASTEXITCODE -ne 0) { throw 'The repository needs an initial commit.' }
New-Item -ItemType File -Force -Path (Join-Path $repo '.git\git-daemon-export-ok') | Out-Null
$name = Split-Path $repo -Leaf
# Git daemon compares its allow-list lexically; use Git's own canonical spelling.
$gitRepo = (& git -C $repo rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Cannot resolve the Git repository path.' }
$gitParent = $gitRepo.Substring(0, $gitRepo.LastIndexOf('/'))
Write-Output "Read-only repository URL: git://127.0.0.1:$Port/$name"
Write-Output 'Keep this terminal open. The service binds only to your laptop.'
& git daemon --reuseaddr --verbose "--listen=127.0.0.1" "--port=$Port" "--base-path=$gitParent" $gitRepo
if ($LASTEXITCODE -ne 0) { throw "Git daemon exited with code $LASTEXITCODE." }
