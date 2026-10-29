param([int]$Port = 8080)
$ErrorActionPreference = 'Stop'
if ($Port -lt 1024 -or $Port -gt 65535) { throw 'Choose a port between 1024 and 65535.' }
$null = Get-Command java -ErrorAction Stop
$null = Get-Command javac -ErrorAction Stop
$url = "http://127.0.0.1:$Port/"
$runtime = Join-Path $PSScriptRoot 'runtime'
$private = Join-Path $runtime 'agent-private'
$work = Join-Path $runtime 'agent-work'
New-Item -ItemType Directory -Force -Path $private,$work | Out-Null
$acl = Get-Acl $private
$acl.SetAccessRuleProtection($true, $false)
$identity = [Security.Principal.WindowsIdentity]::GetCurrent().User
$rule = New-Object Security.AccessControl.FileSystemAccessRule(
    $identity, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
$acl.SetAccessRule($rule)
Set-Acl -Path $private -AclObject $acl
$agentJar = Join-Path $runtime 'agent.jar'
Invoke-WebRequest "${url}jnlpJars/agent.jar" -OutFile $agentJar
$secretFile = Join-Path $private ('secret-' + [guid]::NewGuid().ToString('N') + '.txt')
$secret = Read-Host 'Paste the secret from the student-laptop node page (input hidden)' -AsSecureString
$pointer = [IntPtr]::Zero
try {
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
    $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    if ([string]::IsNullOrWhiteSpace($plain)) { throw 'Agent secret cannot be empty.' }
    [IO.File]::WriteAllText($secretFile, $plain, [Text.Encoding]::ASCII)
    $plain = $null
} finally {
    if ($pointer -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
    $secret.Dispose()
}
try {
    Write-Output 'Connecting student-laptop agent. Keep this terminal open.'
    & java -Xmx512m -jar $agentJar -url $url -secret "@$secretFile" -name student-laptop -webSocket -workDir $work
    if ($LASTEXITCODE -ne 0) { throw "Agent exited with code $LASTEXITCODE." }
} finally {
    if (Test-Path $secretFile) { Remove-Item -LiteralPath $secretFile }
}
