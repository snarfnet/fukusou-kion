$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$utf8 = [System.Text.Encoding]::UTF8
$selection = [System.IO.File]::ReadAllText((Join-Path $root 'batch-01-selection.json'), $utf8) | ConvertFrom-Json
$placesPath = Join-Path $root 'places.json'
$decodedPlaces = [System.IO.File]::ReadAllText($placesPath, $utf8) | ConvertFrom-Json
$places = @($decodedPlaces | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_.id) })
$existing = @{}; foreach ($place in $places) { $existing[$place.id] = $place }
foreach ($place in $places) {
  if (-not ($place.story.psobject.Properties.Name -contains 'claims')) { $place.story | Add-Member -NotePropertyName claims -NotePropertyValue @() }
}

foreach ($item in $selection) {
  if ($existing.ContainsKey($item.id)) { continue }
  $parts = $item.municipality -split ', ', 2
  $municipality = $parts[0]
  $prefecture = if ($parts.Count -gt 1) { $parts[1] } else { $parts[0] }
  $record = [ordered]@{
    id=$item.id; status='candidate'; bucket=$item.bucket
    names=[ordered]@{ja=$item.nameJa;kana='';en=$item.nameEn;former=@()}
    location=[ordered]@{latitude=$item.latitude;longitude=$item.longitude;prefecture=$prefecture;municipality=$municipality;accuracyMeters=100}
    story=[ordered]@{headline=$item.angle;summary='';body='';claims=@();placeNameOrigin='';originCertainty='unknown';sensitivity='standard'}
    timeline=@(); nearby=@(); sources=@()
    review=[ordered]@{researcher=$null;englishEditor=$null;sourceReviewer=$null;locationReviewer=$null;lastReviewedAt=$null;notes='Batch 01 seed candidate; kana, coordinates, sensitivity, and sources require review.'}
  }
  $places += [pscustomobject]$record
}

$priority = @{}; foreach ($item in $selection) { $priority[$item.id] = [int]$item.priority }
$ordered = @($places | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_.id) } | Sort-Object { if ($priority.ContainsKey($_.id)) { $priority[$_.id] } else { 9999 } })
[System.IO.File]::WriteAllText($placesPath, ($ordered | ConvertTo-Json -Depth 12), (New-Object System.Text.UTF8Encoding($false)))
Write-Output "Editorial master contains $($ordered.Count) records."
