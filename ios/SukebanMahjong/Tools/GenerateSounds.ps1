$outputDirectory = Join-Path $PSScriptRoot "..\SukebanMahjong\Resources"
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

function Write-Tone {
    param(
        [string]$Name,
        [double[]]$Frequencies,
        [double]$Duration = 0.09,
        [int]$SampleRate = 22050
    )
    $sampleCount = [int]($SampleRate * $Duration)
    $dataLength = $sampleCount * 2
    $path = Join-Path $outputDirectory "$Name.wav"
    $stream = [IO.File]::Create($path)
    $writer = New-Object IO.BinaryWriter($stream)
    $writer.Write([Text.Encoding]::ASCII.GetBytes("RIFF"))
    $writer.Write(36 + $dataLength)
    $writer.Write([Text.Encoding]::ASCII.GetBytes("WAVEfmt "))
    $writer.Write(16)
    $writer.Write([int16]1)
    $writer.Write([int16]1)
    $writer.Write($SampleRate)
    $writer.Write($SampleRate * 2)
    $writer.Write([int16]2)
    $writer.Write([int16]16)
    $writer.Write([Text.Encoding]::ASCII.GetBytes("data"))
    $writer.Write($dataLength)
    for ($i = 0; $i -lt $sampleCount; $i++) {
        $position = $i / $SampleRate
        $segment = [Math]::Min($Frequencies.Count - 1, [int]($i * $Frequencies.Count / $sampleCount))
        $wave = [Math]::Sin(2 * [Math]::PI * $Frequencies[$segment] * $position)
        $square = if ($wave -ge 0) { 1.0 } else { -1.0 }
        $fade = 1.0 - ($i / $sampleCount)
        $writer.Write([int16]($square * $fade * 8000))
    }
    $writer.Dispose()
    $stream.Dispose()
}

Write-Tone -Name "discard" -Frequencies @(330, 220) -Duration 0.055
Write-Tone -Name "call" -Frequencies @(440, 660) -Duration 0.11
Write-Tone -Name "riichi" -Frequencies @(330, 440, 880) -Duration 0.18
Write-Tone -Name "win" -Frequencies @(523, 659, 784, 1047) -Duration 0.34
Write-Tone -Name "lose" -Frequencies @(330, 247, 196, 147) -Duration 0.34
