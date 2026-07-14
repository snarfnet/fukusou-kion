param([switch]$BuildPublished)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$utf8 = [System.Text.Encoding]::UTF8
$portfolio = [System.IO.File]::ReadAllText((Join-Path $root 'portfolio.json'), $utf8) | ConvertFrom-Json
$places = [System.IO.File]::ReadAllText((Join-Path $root 'places.json'), $utf8) | ConvertFrom-Json
$selection = [System.IO.File]::ReadAllText((Join-Path $root 'batch-01-selection.json'), $utf8) | ConvertFrom-Json
$errors = [System.Collections.Generic.List[string]]::new()
$candidate300Path = Join-Path $root 'candidate-300.json'
$portfolio300Path = Join-Path $root 'portfolio-300.json'
$map300Path = Join-Path (Split-Path $root -Parent) 'KASANE\locations-300.json'

if (Test-Path $candidate300Path) {
  $candidate300 = [System.IO.File]::ReadAllText($candidate300Path, $utf8) | ConvertFrom-Json
  $portfolio300 = [System.IO.File]::ReadAllText($portfolio300Path, $utf8) | ConvertFrom-Json
  $map300 = [System.IO.File]::ReadAllText($map300Path, $utf8) | ConvertFrom-Json
  if (@($candidate300).Count -ne 300) { $errors.Add("Candidate 300 file must contain 300 records; found $(@($candidate300).Count).") }
  if (@($map300).Count -lt 300) { $errors.Add("iOS map catalog must contain at least 300 records; found $(@($map300).Count).") }
  if (@($candidate300.qid | Sort-Object -Unique).Count -ne 300) { $errors.Add('Candidate 300 contains duplicate Wikidata IDs.') }
  if (@($map300.id | Sort-Object -Unique).Count -ne @($map300).Count) { $errors.Add('iOS map catalog contains duplicate IDs.') }
  foreach ($bucket in $portfolio300.buckets) {
    $count = @($candidate300 | Where-Object bucket -eq $bucket.id).Count
    if ($count -ne $bucket.target) { $errors.Add("Candidate 300 bucket $($bucket.id) requires $($bucket.target); found $count.") }
  }
}

if (($portfolio.buckets | Measure-Object target -Sum).Sum -ne $portfolio.target) { $errors.Add('Portfolio bucket targets do not equal the overall target.') }
if ($selection.Count -ne 30) { $errors.Add("Batch 01 must contain exactly 30 selections; found $($selection.Count).") }
$prioritySequence = @($selection.priority | Sort-Object)
if (($prioritySequence -join ',') -ne ((1..30) -join ',')) { $errors.Add('Batch 01 priorities must be unique and sequential from 1 to 30.') }
$selectionDuplicateIds = $selection | Group-Object id | Where-Object Count -gt 1
if ($selectionDuplicateIds) { $errors.Add('Duplicate Batch 01 IDs: ' + (($selectionDuplicateIds.Name) -join ', ')) }
foreach ($selected in $selection) {
  if (-not ($portfolio.buckets.id -contains $selected.bucket)) { $errors.Add("$($selected.id): unknown selection bucket") }
  $totalScore = 0; foreach ($value in $selected.score.psobject.Properties.Value) { $totalScore += $value }
  if ($totalScore -lt 8) { $errors.Add("$($selected.id): selection score below 8") }
}
$batchTargets = @{tokyo=6;kyoto=4;kanto=4;kansai=4;hokkaido_tohoku=2;chubu_hokuriku=3;chugoku_shikoku=3;kyushu_okinawa=3;national_themes=1}
foreach ($key in $batchTargets.Keys) { if (@($selection | Where-Object bucket -eq $key).Count -ne $batchTargets[$key]) { $errors.Add("Batch 01 bucket $key does not match its target.") } }
$duplicateIds = $places | Group-Object id | Where-Object Count -gt 1
if ($duplicateIds) { $errors.Add('Duplicate place IDs: ' + (($duplicateIds.Name) -join ', ')) }

$allowedStatus = @('candidate','researching','drafted','translated','source_checked','location_checked','publishable')
foreach ($place in $places) {
  if ($place.id -notmatch '^[a-z0-9-]+$') { $errors.Add("$($place.id): invalid ID") }
  if ($place.status -notin $allowedStatus) { $errors.Add("$($place.id): invalid status") }
  if (-not ($portfolio.buckets.id -contains $place.bucket)) { $errors.Add("$($place.id): unknown bucket") }
  if ($place.location.latitude -lt 20 -or $place.location.latitude -gt 46 -or $place.location.longitude -lt 122 -or $place.location.longitude -gt 154) { $errors.Add("$($place.id): coordinates outside Japan validation bounds") }
  if ($place.status -in @('drafted','translated','source_checked','location_checked','publishable')) {
    $wordCount = @($place.story.body -split '\s+' | Where-Object { $_ }).Count
    if ($wordCount -lt 200 -or $wordCount -gt 400) { $errors.Add("$($place.id): body must be 200-400 words; found $wordCount") }
    if (@($place.story.claims).Count -lt 4) { $errors.Add("$($place.id): needs at least four claim mappings") }
    if (@($place.timeline).Count -lt 4) { $errors.Add("$($place.id): needs at least four timeline entries") }
    if (@($place.nearby).Count -lt 2 -or @($place.nearby).Count -gt 5) { $errors.Add("$($place.id): needs two to five nearby traces") }
    $sourceIds = @($place.sources.id)
    foreach ($mapping in @($place.story.claims) + @($place.timeline) + @($place.nearby)) {
      foreach ($sourceId in @($mapping.sourceIds)) { if ($sourceId -notin $sourceIds) { $errors.Add("$($place.id): unknown source ID $sourceId") } }
    }
  }
  if ($place.status -eq 'publishable') {
    if ($place.story.body.Length -lt 900) { $errors.Add("$($place.id): published body is too short") }
    if ($place.timeline.Count -lt 4) { $errors.Add("$($place.id): needs at least four timeline entries") }
    if ($place.nearby.Count -lt 2 -or $place.nearby.Count -gt 5) { $errors.Add("$($place.id): needs two to five nearby traces") }
    if ($place.sources.Count -lt 2) { $errors.Add("$($place.id): needs at least two sources") }
    $authority = $place.sources | Where-Object type -in @('government','museum','archive','academic','municipal')
    if (-not $authority) { $errors.Add("$($place.id): needs an authoritative source") }
    foreach ($role in @('researcher','englishEditor','sourceReviewer','locationReviewer','lastReviewedAt')) { if (-not $place.review.$role) { $errors.Add("$($place.id): missing review field $role") } }
  }
}

if ($errors.Count) { $errors | ForEach-Object { Write-Error $_ }; exit 1 }
$published = @($places | Where-Object status -eq 'publishable')
if ($BuildPublished) {
  $out = Join-Path (Split-Path $root -Parent) 'KASANE\published-places.json'
  $json = if ($published.Count -eq 0) { '[]' } else { $published | ConvertTo-Json -Depth 12 }
  [System.IO.File]::WriteAllText($out, $json, (New-Object System.Text.UTF8Encoding($false)))
  Write-Output "Built $out"
}
Write-Output "Editorial data valid: $($places.Count) records, $($published.Count) publishable, target $($portfolio.target)."
Write-Output "Batch 01 selection valid: $($selection.Count) places."
foreach ($bucket in $portfolio.buckets) {
  $bucketPlaces = @($places | Where-Object bucket -eq $bucket.id)
  $bucketPublished = @($bucketPlaces | Where-Object status -eq 'publishable')
  Write-Output ("{0,-32} {1,3}/{2,-3} candidates - {3,3} published" -f $bucket.label, $bucketPlaces.Count, $bucket.target, $bucketPublished.Count)
}
