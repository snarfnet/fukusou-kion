$ErrorActionPreference = "Stop"

$vsShell = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\Launch-VsDevShell.ps1"
if (-not (Test-Path -LiteralPath $vsShell)) {
    throw "Visual Studio Build Tools 2022 was not found."
}

$toolchain = Get-ChildItem -LiteralPath "$env:LOCALAPPDATA\Programs\Swift\Toolchains" -Directory |
    Sort-Object Name -Descending |
    Select-Object -First 1
$runtime = Get-ChildItem -LiteralPath "$env:LOCALAPPDATA\Programs\Swift\Runtimes" -Directory |
    Sort-Object Name -Descending |
    Select-Object -First 1
if (-not $toolchain -or -not $runtime) {
    throw "Swift Toolchain or Runtime was not found."
}

& $vsShell -Arch amd64 -HostArch amd64 -SkipAutomaticLocation
$env:Path = "$($toolchain.FullName)\usr\bin;$($runtime.FullName)\usr\bin;$env:Path"
$env:SDKROOT = [Environment]::GetEnvironmentVariable("SDKROOT", "User")
if (-not $env:SDKROOT -or -not (Test-Path -LiteralPath $env:SDKROOT)) {
    throw "Swift Windows SDK was not found."
}

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    swift --version
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    swift test
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $sourceDirectories = @(
        "$projectRoot\SukebanMahjong",
        "$projectRoot\SukebanMahjongTests",
        "$projectRoot\SukebanMahjongUITests"
    )
    $swiftSources = $sourceDirectories |
        ForEach-Object { Get-ChildItem -LiteralPath $_ -Filter "*.swift" -File }
    foreach ($source in $swiftSources) {
        swiftc -frontend -parse $source.FullName
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }

    Write-Output "Parsed $($swiftSources.Count) app and test Swift source files."
    Write-Output "Windows Swift Package tests passed."
} finally {
    Pop-Location
}
