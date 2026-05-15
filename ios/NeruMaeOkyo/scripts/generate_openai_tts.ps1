param(
    [string]$ApiKey = $env:OPENAI_API_KEY,
    [string]$OutputPath = "",
    [string]$Text = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Text)) {
    $DefaultTextCodePoints = @(
        0x6469, 0x8A36, 0x822C, 0x82E5, 0x6CE2, 0x7F85, 0x871C, 0x591A,
        0x5FC3, 0x7D4C, 0x3002, 0x89B3, 0x81EA, 0x5728, 0x83E9, 0x85A9,
        0x3002, 0x6DF1, 0x304F, 0x9759, 0x304B, 0x306B, 0x3001, 0x606F,
        0x3092, 0x6574, 0x3048, 0x307E, 0x3059, 0x3002
    )
    $Text = -join ($DefaultTextCodePoints | ForEach-Object { [char]$_ })
}

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    $secureKey = Read-Host "OpenAI API key" -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    try {
        $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    throw "OpenAI API key is missing. Pass -ApiKey or set OPENAI_API_KEY."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $projectDir "NeruMaeOkyo\Audio\okyo_low.mp3"
}

$outputDir = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$bodyObject = @{
    model = "gpt-4o-mini-tts"
    voice = "cedar"
    input = $Text
    instructions = "Speak in a very low, slow, soft Japanese meditation chant. Keep it calm, non-dramatic, warm, and suitable for bedtime relaxation. Avoid a frightening or theatrical tone."
    response_format = "mp3"
}

$body = $bodyObject | ConvertTo-Json -Depth 5
$headers = @{
    Authorization = "Bearer $ApiKey"
}

Write-Host "Generating OpenAI TTS audio..."

Invoke-WebRequest `
    -Uri "https://api.openai.com/v1/audio/speech" `
    -Method Post `
    -Headers $headers `
    -ContentType "application/json; charset=utf-8" `
    -Body ([Text.Encoding]::UTF8.GetBytes($body)) `
    -OutFile $OutputPath

Write-Host "Done: $OutputPath"
