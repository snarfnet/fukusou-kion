$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$utf8 = [System.Text.Encoding]::UTF8
$placesPath = Join-Path $root 'places.json'
$decodedPlaces = [System.IO.File]::ReadAllText($placesPath, $utf8) | ConvertFrom-Json
$decodedResearch = [System.IO.File]::ReadAllText((Join-Path $root 'research-01.json'), $utf8) | ConvertFrom-Json
$places = @($decodedPlaces)
$research = @($decodedResearch)

foreach ($update in $research) {
  $place = $places | Where-Object id -eq $update.id
  if (-not $place) { throw "Research target not found: $($update.id)" }
  $place.status = 'researching'
  $place.names.kana = $update.kana
  $place.story.summary = $update.summary
  $place.story.originCertainty = $update.originCertainty
  $place.story.sensitivity = $update.sensitivity
  $place.sources = $update.sources
  $place.review.researcher = 'KASANE editorial research'
  $place.review.lastReviewedAt = '2026-07-13'
  $place.review.notes = 'Initial source set collected. Claim-level source mapping, full body, timeline, nearby traces, and independent review remain.'
}

[System.IO.File]::WriteAllText($placesPath, ($places | ConvertTo-Json -Depth 12), (New-Object System.Text.UTF8Encoding($false)))
Write-Output "Applied research to $($research.Count) places."
