param(
    [string]$ApiKey = $env:OPENAI_API_KEY,
    [string]$OutputPath = "",
    [string]$Text = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Text)) {
    $DefaultTextCodePoints = @(
        0x4ECA, 0x65E5, 0x3082, 0x304A, 0x3064, 0x304B, 0x308C, 0x3055,
        0x307E, 0x3067, 0x3057, 0x305F, 0x3002, 0x3053, 0x3053, 0x306F,
        0x9759, 0x304B, 0x306A, 0x591C, 0x306E, 0x304A, 0x5802, 0x3067,
        0x3059, 0x3002, 0x606F, 0x3092, 0x3086, 0x3063, 0x304F, 0x308A,
        0x5410, 0x3044, 0x3066, 0x3001, 0x4F53, 0x306E, 0x529B, 0x3092,
        0x5C11, 0x3057, 0x305A, 0x3064, 0x629C, 0x3044, 0x3066, 0x3044,
        0x304D, 0x307E, 0x3057, 0x3087, 0x3046, 0x3002, 0x4F55, 0x3082,
        0x6025, 0x304C, 0x306A, 0x304F, 0x3066, 0x5927, 0x4E08, 0x592B,
        0x3067, 0x3059, 0x3002
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
    instructions = "Speak Japanese in a low, warm, reassuring bedtime voice. Make it gentle and human, with long pauses and a slow pace. Keep the tone peaceful, safe, and non-religious meditation-like. Avoid whisper noise, harsh breath, theatrical chanting, fear, pressure, or dramatic temple horror."
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
