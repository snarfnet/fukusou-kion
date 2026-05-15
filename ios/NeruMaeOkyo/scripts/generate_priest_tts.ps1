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
$heartSutraText = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("44G244Gj44Gb44Gk44G+44O844GL44O844Gv44KT44Gr44KD44O844Gv44O844KJ44O844G/44O844Gf44O844GX44O844KT44GO44KH44GG44O844CCCuOBi+OCk+OBmOODvOOBluOBhOOBvOODvOOBleODvOOAguOBjuOCh+OBhuOBmOOCk+OBr+OCk+OBq+OCg+ODvOOBr+ODvOOCieODvOOBv+ODvOOBn+ODvOOAggrjgZjjg7zjgZfjgofjgYbjgZHjgpPjgZTjg7zjgYbjgpPjgYvjgYTjgY/jg7zjgILjganjg7zjgYTjgaPjgZXjgYTjgY/jg7zjgoTjgY/jgIIK44GX44KD44O844KK44O844GX44O844CC44GX44GN44G144O844GE44O844GP44GG44CC44GP44GG44G144O844GE44O844GX44GN44CC44GX44GN44Gd44GP44Gc44O844GP44GG44CCCuOBj+OBhuOBneOBj+OBnOODvOOBl+OBjeOAguOBmOOCheODvOOBneOBhuOBjuOCh+OBhuOBl+OBjeOAguOChOOBj+OBtuODvOOBq+OCh+ODvOOBnOODvOOAggrjgZfjgoPjg7zjgorjg7zjgZfjg7zjgILjgZzjg7zjgZfjgofjgYbjgbvjgYbjgY/jgYbjgZ3jgYbjgILjgbXjg7zjgZfjgofjgYbjgbXjg7zjgoHjgaTjgILjgbXjg7zjgY/jg7zjgbXjg7zjgZjjgofjgYbjgIIK44G144O844Ge44GG44G144O844GS44KT44CC44Gc44O844GT44O844GP44GG44Gh44KF44GG44CC44KA44O844GX44GN44CC44KA44O844GY44KF44O844Gd44GG44GO44KH44GG44GX44GN44CC44KA44O844GS44KT44Gr44O844CCCuOBs+ODvOOBnOOBo+OBl+OCk+OBhOODvOOAguOCgOODvOOBl+OBjeOBl+OCh+OBhuOBk+OBhuOBv+ODvOOBneOBj+OBu+OBhuOAguOCgOODvOOBkuOCk+OBi+OBhOOAguOBquOBhOOBl+ODvOOAggrjgoDjg7zjgYTjg7zjgZfjgY3jgYvjgYTjgILjgoDjg7zjgoDjg7zjgb/jgofjgYbjgILjgoTjgY/jgoDjg7zjgoDjg7zjgb/jgofjgYbjgZjjgpPjgILjgarjgYTjgZfjg7zjgILjgoDjg7zjgo3jgYbjgZfjg7zjgoTjgY/jgIIK44KA44O844KN44GG44GX44O844GY44KT44CC44KA44O844GP44O844GX44KF44GG44KB44Gk44Gp44GG44CC44KA44O844Gh44O844KE44GP44KA44O844Go44GP44GE44O844CCCuOCgOODvOOBl+OCh+ODvOOBqOOBo+OBk+ODvOOAguOBvOODvOOBoOOBhOOBleOBo+OBn+ODvOOAguOBiOODvOOBr+OCk+OBq+OCg+ODvOOBr+ODvOOCieODvOOBv+ODvOOBn+ODvOOAggrjgZPjg7zjgZfjgpPjgoDjg7zjgZHjg7zjgZLjg7zjgILjgoDjg7zjgZHjg7zjgZLjg7zjgZPjg7zjgILjgoDjg7zjgYbjg7zjgY/jg7zjgbXjg7zjgILjgYrjgpPjgorjg7zjgYTjgaPjgZXjgYTjgabjgpPjganjgYbjgIIK44KA44O844Gd44GG44GP44O844GO44KH44GG44Gt44O844Gv44KT44CC44GV44KT44Gc44O844GX44KH44O844G244Gk44CC44GI44O844Gv44KT44Gr44KD44O844Gv44O844KJ44O844G/44O844Gf44O844CCCuOBk+ODvOOBqOOBj+OBguODvOOBruOBj+OBn+ODvOOCieODvOOBleOCk+OBv+OCg+OBj+OBleOCk+OBvOODvOOBoOOBhOOAguOBk+ODvOOBoeODvOOBr+OCk+OBq+OCg+ODvOOBr+ODvOOCieODvOOBv+ODvOOBn+ODvOOAggrjgZzjg7zjgaDjgYTjgZjjgpPjgZfjgoXjgILjgZzjg7zjgaDjgYTjgb/jgofjgYbjgZfjgoXjgILjgZzjg7zjgoDjg7zjgZjjgofjgYbjg7zjgZfjgoXjgILjgZzjg7zjgoDjg7zjgajjgYbjgajjgYbjgZfjgoXjgIIK44Gu44GG44GY44KH44O844GE44Gj44GV44GE44GP44O844CC44GX44KT44GY44Gk44G144O844GT44O844CC44GT44O844Gb44Gk44Gv44KT44Gr44KD44O844Gv44O844KJ44O844G/44O844Gf44O844CCCuOBl+OCheODvOOBneOBj+OBm+OBpOOBl+OCheODvOOCj+OBpOOAguOBjuOCg+ODvOOBpuODvOOAguOBjuOCg+ODvOOBpuODvOOAguOBr+ODvOOCieODvOOBjuOCg+ODvOOBpuODvOOAguOBr+OCieOBneODvOOBjuOCg+ODvOOBpuODvOOAggrjgbzjg7zjgZjjg7zjgZ3jgo/jgYvjg7zjgILjga/jgpPjgavjgoPjg7zjgZfjg7zjgpPjgY7jgofjgYbjg7zjgII="))
$commonChant = " Chant the full Heart Sutra in Japanese kana reading exactly as written. Very slow and heavy temple sutra cadence. Hold vowels marked with ー, make it resonant and cool, with deep calm pauses at punctuation."
$commonAvoid = " Keep it sleep-safe. Avoid whisper noise, harsh breath, loudness, fear, pressure, horror, or comedy."
$profiles = @(
    @{
        id = "genkai"; file = "guide_genkai.mp3";
        instructions = $commonChant + "Speak Japanese in a deep, warm elder voice. Very slow, steady, reassuring, with long quiet pauses. Gentle bedtime meditation tone." + $commonAvoid;
        text = $heartSutraText
    },
    @{
        id = "toma"; file = "guide_toma.mp3";
        instructions = $commonChant + "Speak Japanese in a soft young adult male voice. Calm, sincere, clear, and gentle. Keep the pace slow with natural pauses. Make it feel safe and modern." + $commonAvoid;
        text = $heartSutraText
    },
    @{
        id = "myono"; file = "guide_myono.mp3";
        instructions = $commonChant + "Speak Japanese in a warm elderly female voice, like a kind grandmother. Low volume, soft smile, slow and reassuring." + $commonAvoid;
        text = $heartSutraText
    },
    @{
        id = "seigaku"; file = "guide_seigaku.mp3";
        instructions = $commonChant + "Speak Japanese in a calm scholarly middle-aged male voice. Measured, precise, kind, and low. Use spacious pauses. It should feel orderly and reassuring." + $commonAvoid;
        text = $heartSutraText
    },
    @{
        id = "sangen"; file = "guide_sangen.mp3";
        instructions = $commonChant + "Speak Japanese in a low rustic mountain-hermit voice. Dry, quiet, slow, and kind. Add long pauses and a grounded feeling." + $commonAvoid;
        text = $heartSutraText
    },
    @{
        id = "fukusho"; file = "guide_fukusho.mp3";
        instructions = $commonChant + "Speak Japanese in a round, warm, slightly cheerful priest voice. Very gentle, slow, and sleepy. Smile in the voice without becoming energetic." + $commonAvoid;
        text = $heartSutraText
    },
    @{
        id = "shodo"; file = "guide_shodo.mp3";
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
        voice = "cedar"
        input = $chantText
        instructions = $profile.instructions
        response_format = "mp3"
    }
    $body = $bodyObject | ConvertTo-Json -Depth 5
    $out = Join-Path $OutputDir $profile.file
    $dryOut = Join-Path $OutputDir ("dry_" + $profile.file)
    Write-Host "Generating $($profile.id) -> $out"
    Invoke-WebRequest `
        -Uri "https://api.openai.com/v1/audio/speech" `
        -Method Post `
        -Headers @{ Authorization = "Bearer $ApiKey" } `
        -ContentType "application/json; charset=utf-8" `
        -Body ([Text.Encoding]::UTF8.GetBytes($body)) `
        -OutFile $dryOut

    $ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($ffmpeg) {
        $reverbFilter = "atempo=0.72,equalizer=f=120:t=q:w=1:g=2,aecho=0.70:0.84:140|300|620:0.14|0.08|0.035,alimiter=limit=0.90"
        & $ffmpeg.Source -y -i $dryOut -af $reverbFilter -codec:a libmp3lame -b:a 128k $out | Out-Null
        Remove-Item -Force $dryOut
        Write-Host "Added slow heavy temple reverb."
    } else {
        Move-Item -Force $dryOut $out
        Write-Host "ffmpeg was not found. Saved dry voice without reverb."
    }
}

Write-Host "Done."
