param(
    [string]$ApiKey = $env:OPENAI_API_KEY,
    [string]$GuideId = "all",
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

function Convert-CodePointsToString([int[]]$CodePoints) {
    return -join ($CodePoints | ForEach-Object { [char]$_ })
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
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $projectDir "NeruMaeOkyo\Audio"
}
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$heartSutraText = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("44G244Gj44Gb44Gk44G+44GL44Gv44KT44Gr44KD44Gv44KJ44G/44Gf44GX44KT44GO44KH44GG44CCCuOBi+OCk+OBmOOBluOBhOOBvOOBleOBpOOAguOBjuOCh+OBhuOBmOOCk+OBr+OCk+OBq+OCg+OBr+OCieOBv+OBn+OBmOOAggrjgZfjgofjgYbjgZHjgpPjgZTjgYbjgpPjgYvjgYTjgY/jgYbjgILjganjgYTjgaPjgZXjgYTjgY/jgoTjgY/jgIIK44GX44KD44KK44GX44CC44GX44GN44G144GE44GP44GG44CC44GP44GG44G144GE44GX44GN44CCCuOBl+OBjeOBneOBj+OBnOOBj+OBhuOAguOBj+OBhuOBneOBj+OBnOOBl+OBjeOAggrjgZjjgoXjgZ3jgYbjgY7jgofjgYbjgZfjgY3jgILjgoTjgY/jgbbjgavjgofjgZzjgIIK44GX44KD44KK44GX44CC44Gc44GX44KH44G744GG44GP44GG44Gd44GG44CCCuOBteOBl+OCh+OBhuOBteOCgeOBpOOAguOBteOBj+OBteOBmOOCh+OBhuOAguOBteOBnuOBhuOBteOBkuOCk+OAggrjgZzjgZPjgY/jgYbjgaHjgoXjgYbjgILjgoDjgZfjgY3jgILjgoDjgZjjgoXjgZ3jgYbjgY7jgofjgYbjgZfjgY3jgIIK44KA44GS44KT44Gr44Gz44Gc44Gj44GX44KT44Gr44CC44KA44GX44GN44GX44KH44GG44GT44GG44G/44Gd44GP44G744GG44CCCuOCgOOBkuOCk+OBi+OBhOOAguOBquOBhOOBl+OCgOOBhOOBl+OBjeOBi+OBhOOAggrjgoDjgoDjgb/jgofjgYbjgILjgoTjgY/jgoDjgoDjgb/jgofjgYbjgZjjgpPjgIIK44Gq44GE44GX44KA44KN44GG44GX44CC44KE44GP44KA44KN44GG44GX44GY44KT44CCCuOCgOOBj+OBl+OCheOBhuOCgeOBpOOBqeOBhuOAguOCgOOBoeOChOOBj+OCgOOBqOOBj+OAggrjgYTjgoDjgZfjgofjgajjgY/jgZPjgIIK44G844Gg44GE44GV44Gj44Gf44CC44GI44Gv44KT44Gr44KD44Gv44KJ44G/44Gf44GT44CCCuOBl+OCk+OCgOOBkeOBhOOBkuOAguOCgOOBkeOBhOOBkuOBk+OAggrjgoDjgYbjgY/jgbXjgILjgYrjgpPjgorjgYTjgaPjgZXjgYTjgabjgpPjganjgYbjgoDjgZ3jgYbjgIIK44GP44GN44KH44GG44Gt44Gv44KT44CCCuOBleOCk+OBnOOBl+OCh+OBtuOBpOOAguOBiOOBr+OCk+OBq+OCg+OBr+OCieOBv+OBn+OBk+OAggrjgajjgY/jgYLjga7jgY/jgZ/jgonjgZXjgpPjgb/jgoPjgY/jgZXjgpPjgbzjgaDjgYTjgIIK44GT44Gh44Gv44KT44Gr44KD44Gv44KJ44G/44Gf44CCCuOBnOOBoOOBhOOBmOOCk+OBl+OCheOAguOBnOOBoOOBhOOBv+OCh+OBhuOBl+OCheOAggrjgZzjgoDjgZjjgofjgYbjgZfjgoXjgILjgZzjgoDjgajjgYbjganjgYbjgZfjgoXjgIIK44Gu44GG44GY44KH44GE44Gj44GV44GE44GP44CC44GX44KT44GY44Gk44G144GT44CCCuOBk+OBm+OBpOOBr+OCk+OBq+OCg+OBr+OCieOBv+OBn+OBl+OCheOAggrjgZ3jgY/jgZvjgaTjgZfjgoXjgo/jgaTjgIIK44GO44KD44Gm44GE44CC44GO44KD44Gm44GE44CC44Gv44KJ44GO44KD44Gm44GE44CCCuOBr+OCieOBneOBhuOBjuOCg+OBpuOBhOOAguOBvOOBmOOBneOCj+OBi+OAggrjga/jgpPjgavjgoPjgZfjgpPjgY7jgofjgYbjgII="))
$commonChant = " Chant the full Heart Sutra in Japanese kana reading. Sound like a real person quietly chanting beside the listener: natural breath, soft consonants, warm chest resonance, slow and steady tempo, calm pauses at punctuation. Do not sound robotic, synthetic, theatrical, or over-processed."
$commonAvoid = " Keep it sleep-safe. Avoid whisper noise, harsh breath, loudness, fear, pressure, horror, or comedy."
$profiles = @(
    @{
        id = "genkai"; file = "guide_genkai.mp3"; voice = "cedar";
        instructions = $commonChant + "Speak Japanese in a deep, warm elder voice. Very slow, steady, reassuring, with long quiet pauses. Gentle bedtime meditation tone." + $commonAvoid;
        text = $heartSutraText
    },
    @{
        id = "toma"; file = "guide_toma.mp3"; voice = "marin";
        instructions = $commonChant + "Speak Japanese in a soft young adult male voice. Calm, sincere, clear, and gentle. Keep the pace slow with natural pauses. Make it feel safe and modern." + $commonAvoid;
        text = $heartSutraText
    },
    @{
        id = "myono"; file = "guide_myono.mp3"; voice = "marin";
        instructions = $commonChant + "Speak Japanese in a warm elderly female voice, like a kind grandmother. Low volume, soft smile, slow and reassuring." + $commonAvoid;
        text = $heartSutraText
    },
    @{
        id = "seigaku"; file = "guide_seigaku.mp3"; voice = "cedar";
        instructions = $commonChant + "Speak Japanese in a calm scholarly middle-aged male voice. Measured, precise, kind, and low. Use spacious pauses. It should feel orderly and reassuring." + $commonAvoid;
        text = $heartSutraText
    },
    @{
        id = "sangen"; file = "guide_sangen.mp3"; voice = "cedar";
        instructions = $commonChant + "Speak Japanese in a low rustic mountain-hermit voice. Dry, quiet, slow, and kind. Add long pauses and a grounded feeling." + $commonAvoid;
        text = $heartSutraText
    },
    @{
        id = "fukusho"; file = "guide_fukusho.mp3"; voice = "marin";
        instructions = $commonChant + "Speak Japanese in a round, warm, slightly cheerful priest voice. Very gentle, slow, and sleepy. Smile in the voice without becoming energetic." + $commonAvoid;
        text = $heartSutraText
    },
    @{
        id = "shodo"; file = "guide_shodo.mp3"; voice = "cedar";
        instructions = $commonChant + "Speak Japanese in a solemn but gentle bell-keeper voice. Low, slow, spacious, and safe. Each phrase should fade softly." + $commonAvoid;
        text = $heartSutraText
    }
)

$selected = if ($GuideId -eq "all") {
    $profiles
} else {
    @($profiles | Where-Object { $_.id -eq $GuideId })
}

if ($selected.Count -eq 0) {
    throw "Unknown GuideId: $GuideId"
}

foreach ($profile in $selected) {
    $chantText = $profile.text
    $bodyObject = @{
        model = "gpt-4o-mini-tts"
        voice = $profile.voice
        input = $chantText
        instructions = $profile.instructions
        response_format = "mp3"
    }
    $body = $bodyObject | ConvertTo-Json -Depth 5
    $out = Join-Path $OutputDir $profile.file
    Write-Host "Generating $($profile.id) -> $out"
    Invoke-WebRequest `
        -Uri "https://api.openai.com/v1/audio/speech" `
        -Method Post `
        -Headers @{ Authorization = "Bearer $ApiKey" } `
        -ContentType "application/json; charset=utf-8" `
        -Body ([Text.Encoding]::UTF8.GetBytes($body)) `
        -OutFile $out

    Write-Host "Saved natural TTS voice without post-processing."
}

Write-Host "Done."
