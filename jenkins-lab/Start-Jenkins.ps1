param([int]$Port = 8080)
$ErrorActionPreference = 'Stop'
if ($Port -lt 1024 -or $Port -gt 65535) { throw 'Choose a port between 1024 and 65535.' }
$null = Get-Command java -ErrorAction Stop
$null = Get-Command javac -ErrorAction Stop
$war = Join-Path $PSScriptRoot 'downloads\jenkins.war'
if (-not (Test-Path $war)) { throw 'Run Download-Jenkins.ps1 first.' }
$env:JENKINS_HOME = Join-Path $PSScriptRoot 'runtime\jenkins-home'
New-Item -ItemType Directory -Force -Path $env:JENKINS_HOME | Out-Null
Write-Output "Open http://127.0.0.1:$Port/ after Jenkins starts. Keep this terminal open."
Write-Output "Jenkins home: $env:JENKINS_HOME"
& java -Xms128m -Xmx768m -jar $war "--httpListenAddress=127.0.0.1" "--httpPort=$Port"
if ($LASTEXITCODE -ne 0) { throw "Jenkins exited with code $LASTEXITCODE." }
