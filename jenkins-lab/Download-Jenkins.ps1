param([string]$Version = '2.580.1')
$ErrorActionPreference = 'Stop'
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw 'Use an LTS version such as 2.580.1.' }
$folder = Join-Path $PSScriptRoot 'downloads'
New-Item -ItemType Directory -Force -Path $folder | Out-Null
$base = "https://get.jenkins.io/war-stable/$Version"
$war = Join-Path $folder 'jenkins.war'
$temporary = Join-Path $folder 'jenkins.war.download'
$checksum = Join-Path $folder 'jenkins.war.sha256'
Invoke-WebRequest "$base/jenkins.war.sha256" -OutFile $checksum
Invoke-WebRequest "$base/jenkins.war" -OutFile $temporary
$expected = ((Get-Content $checksum -Raw).Trim() -split '\s+')[0]
if ($expected -notmatch '^[0-9a-fA-F]{64}$') { throw 'Invalid official checksum response.' }
if ((Get-FileHash $temporary -Algorithm SHA256).Hash -ne $expected) {
    throw 'Jenkins checksum mismatch. Do not run this download.'
}
Move-Item $temporary $war -Force
Set-Content (Join-Path $folder 'jenkins-version.txt') $Version
Write-Output "Downloaded and SHA-256 verified Jenkins LTS $Version."
