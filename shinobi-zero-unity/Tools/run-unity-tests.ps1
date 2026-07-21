param(
    [Parameter(Mandatory = $true)]
    [string]$UnityPath
)

$projectPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$resultRoot = Join-Path $projectPath 'TestResults'
New-Item -ItemType Directory -Force -Path $resultRoot | Out-Null
$resultPath = Join-Path $resultRoot 'editmode-results.xml'
$logPath = Join-Path $resultRoot 'editmode.log'

& $UnityPath `
    -batchmode `
    -nographics `
    -projectPath $projectPath `
    -runTests `
    -testPlatform EditMode `
    -testResults $resultPath `
    -logFile $logPath `
    -quit

if ($LASTEXITCODE -ne 0) {
    throw "Unity EditMode tests failed with exit code $LASTEXITCODE. See $logPath"
}

Write-Output "SHINOBI ZERO Unity EditMode tests passed: $resultPath"
