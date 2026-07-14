$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$utf8 = [System.Text.Encoding]::UTF8
$placesPath = Join-Path $root 'places.json'
$decodedPlaces = [System.IO.File]::ReadAllText($placesPath, $utf8) | ConvertFrom-Json
$decodedDrafts = [System.IO.File]::ReadAllText((Join-Path $root 'research-02-drafts.json'), $utf8) | ConvertFrom-Json
$places = @($decodedPlaces)
$drafts = @($decodedDrafts)

foreach ($draft in $drafts) {
  $place = $places | Where-Object id -eq $draft.id
  if (-not $place) { throw "Draft target not found: $($draft.id)" }
  $place.status = 'drafted'
  $place.story.body = $draft.body
  if ($place.story.psobject.Properties.Name -contains 'claims') { $place.story.claims = $draft.claims } else { $place.story | Add-Member -NotePropertyName claims -NotePropertyValue $draft.claims }
  $place.story.placeNameOrigin = $draft.placeNameOrigin
  $place.timeline = $draft.timeline
  $place.nearby = $draft.nearby
  $allSources = @($place.sources) + @($draft.additionalSources)
  $place.sources = @($allSources | Group-Object id | ForEach-Object { $_.Group[0] })
  $place.review.notes = 'First English draft complete with claim-level source mapping. English edit, independent source review, and coordinate review remain.'
}

[System.IO.File]::WriteAllText($placesPath, ($places | ConvertTo-Json -Depth 15), (New-Object System.Text.UTF8Encoding($false)))
Write-Output "Applied full drafts to $($drafts.Count) places."
