$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$portfolio = [System.IO.File]::ReadAllText((Join-Path $root 'portfolio-300.json'), [System.Text.Encoding]::UTF8) | ConvertFrom-Json

$query = @'
SELECT DISTINCT ?item ?itemLabel ?itemLabelJa ?coord ?prefectureLabel WHERE {
  ?item wdt:P17 wd:Q17; wdt:P625 ?coord; wdt:P1435 ?designation; wdt:P131* ?prefecture.
  ?prefecture wdt:P31 wd:Q50337.
  OPTIONAL { ?item rdfs:label ?itemLabelJa FILTER(LANG(?itemLabelJa)="ja") }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
}
LIMIT 30000
'@
$uri = 'https://query.wikidata.org/sparql?query=' + [uri]::EscapeDataString($query) + '&format=json'
$headers = @{'User-Agent'='KASANE-editorial/0.1 (candidate discovery; contact via repository)'}
$response = Invoke-RestMethod -Uri $uri -Headers $headers -TimeoutSec 180

$prefectureBuckets = @{
  'Tokyo'='tokyo'; 'Kyoto'='kyoto'
  'Ibaraki'='kanto'; 'Tochigi'='kanto'; 'Gunma'='kanto'; 'Saitama'='kanto'; 'Chiba'='kanto'; 'Kanagawa'='kanto'
  'Osaka'='kansai'; 'Hyōgo'='kansai'; 'Nara'='kansai'; 'Wakayama'='kansai'; 'Shiga'='kansai'; 'Mie'='kansai'
  'Hokkaido'='hokkaido_tohoku'; 'Aomori'='hokkaido_tohoku'; 'Iwate'='hokkaido_tohoku'; 'Miyagi'='hokkaido_tohoku'; 'Akita'='hokkaido_tohoku'; 'Yamagata'='hokkaido_tohoku'; 'Fukushima'='hokkaido_tohoku'
  'Niigata'='chubu_hokuriku'; 'Toyama'='chubu_hokuriku'; 'Ishikawa'='chubu_hokuriku'; 'Fukui'='chubu_hokuriku'; 'Yamanashi'='chubu_hokuriku'; 'Nagano'='chubu_hokuriku'; 'Gifu'='chubu_hokuriku'; 'Shizuoka'='chubu_hokuriku'; 'Aichi'='chubu_hokuriku'
  'Tottori'='chugoku_shikoku'; 'Shimane'='chugoku_shikoku'; 'Okayama'='chugoku_shikoku'; 'Hiroshima'='chugoku_shikoku'; 'Yamaguchi'='chugoku_shikoku'; 'Tokushima'='chugoku_shikoku'; 'Kagawa'='chugoku_shikoku'; 'Ehime'='chugoku_shikoku'; 'Kochi'='chugoku_shikoku'
  'Fukuoka'='kyushu_okinawa'; 'Saga'='kyushu_okinawa'; 'Nagasaki'='kyushu_okinawa'; 'Kumamoto'='kyushu_okinawa'; 'Oita'='kyushu_okinawa'; 'Miyazaki'='kyushu_okinawa'; 'Kagoshima'='kyushu_okinawa'; 'Okinawa'='kyushu_okinawa'
}

function Get-RegionLabel([string]$bucket) {
  switch ($bucket) {
    'tokyo' { return 'Tokyo' }
    'kyoto' { return 'Kyoto' }
    'kanto' { return 'Kanto' }
    'kansai' { return 'Kansai' }
    'hokkaido_tohoku' { return 'Hokkaido & Tohoku' }
    'chubu_hokuriku' { return 'Chubu & Hokuriku' }
    'chugoku_shikoku' { return 'Chugoku & Shikoku' }
    'kyushu_okinawa' { return 'Kyushu & Okinawa' }
    default { return 'Cross-regional' }
  }
}

$records = foreach ($binding in $response.results.bindings) {
  $qid = ($binding.item.value -split '/')[-1]
  $point = $binding.coord.value -replace '^Point\(',' ' -replace '\)$',''
  $parts = $point.Trim() -split ' '
  $prefecture = $binding.prefectureLabel.value -replace ' Prefecture$',''
  $bucket = $prefectureBuckets[$prefecture]
  if (-not $bucket -or $parts.Count -ne 2) { continue }
  [pscustomobject]@{
    id = ('wikidata-' + $qid.ToLowerInvariant())
    qid = $qid
    status = 'candidate'
    bucket = $bucket
    names = [ordered]@{ ja = $binding.itemLabelJa.value; en = $binding.itemLabel.value }
    location = [ordered]@{ latitude = [double]$parts[1]; longitude = [double]$parts[0]; prefecture = $prefecture }
    designation = 'Wikidata heritage designation present'
    discoverySource = $binding.item.value
    review = [ordered]@{ selected = $false; sourceChecked = $false; locationChecked = $false }
  }
}

$uniqueByQid = @($records | Where-Object { $_.names.ja -and $_.names.en -and $_.names.en -notmatch '^Q\d+$' } | Group-Object qid | ForEach-Object { $_.Group[0] })
$unique = @($uniqueByQid | Group-Object { '{0:F5},{1:F5}' -f $_.location.latitude, $_.location.longitude } | ForEach-Object { $_.Group[0] })
$nationalPattern = 'road|route|bridge|canal|railway|station|port|harbor|aqueduct|pilgrimage|highway|tunnel'
$nationalPool = @($unique | Where-Object { $_.names.en -match $nationalPattern } | Sort-Object @{Expression='prefecture'}, @{Expression={$_.names.en}})
$selected = [System.Collections.Generic.List[object]]::new()

foreach ($bucketSpec in $portfolio.buckets) {
  if ($bucketSpec.id -eq 'national_themes') {
    $pool = $nationalPool
  } else {
    $pool = @($unique | Where-Object bucket -eq $bucketSpec.id | Sort-Object @{Expression={$_.location.prefecture}}, @{Expression={$_.names.en}})
  }
  $already = @($selected.qid)
  $take = @($pool | Where-Object qid -notin $already | Select-Object -First $bucketSpec.target)
  if ($take.Count -ne $bucketSpec.target) { throw "$($bucketSpec.id): needed $($bucketSpec.target), found $($take.Count)" }
  foreach ($item in $take) {
    $item.bucket = $bucketSpec.id
    $item.review.selected = $true
    $selected.Add($item)
  }
}

if ($selected.Count -ne 300) { throw "Expected 300 candidates, found $($selected.Count)" }
$output = Join-Path $root 'candidate-300.json'
[System.IO.File]::WriteAllText($output, ($selected | ConvertTo-Json -Depth 8), $utf8NoBom)
Write-Output "Built $output with $($selected.Count) candidates from $($unique.Count) heritage records."
$selected | Group-Object bucket | Sort-Object Name | ForEach-Object { Write-Output ("{0,-22} {1,3}" -f $_.Name, $_.Count) }

$appRoot = Split-Path $root -Parent
$seedPath = Join-Path $appRoot 'KASANE\locations.json'
$decodedSeed = [System.IO.File]::ReadAllText($seedPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$seed = @($decodedSeed)
$appLocations = [System.Collections.Generic.List[object]]::new()
foreach ($item in $seed) {
  $seedBucket = $prefectureBuckets[$item.prefecture]
  if ($seedBucket) {
    $label = Get-RegionLabel $seedBucket
    $item | Add-Member -Force -NotePropertyName region -NotePropertyValue $label
  } elseif ($item.latitude -ge 37) {
    $item | Add-Member -Force -NotePropertyName region -NotePropertyValue 'Hokkaido & Tohoku'
  }
  $appLocations.Add($item)
}
$selectedQids = @($selected.qid)
$catalogPool = @($selected) + @($unique | Where-Object qid -notin $selectedQids)
foreach ($item in $catalogPool) {
  if ($appLocations.Count -ge 300) { break }
  $duplicate = $appLocations | Where-Object {
    [math]::Abs($_.latitude - $item.location.latitude) -lt 0.002 -and [math]::Abs($_.longitude - $item.location.longitude) -lt 0.002
  }
  if ($duplicate) { continue }
  $regionLabel = Get-RegionLabel $item.bucket
  $appLocations.Add([pscustomobject][ordered]@{
    id = $item.id; kanji = $item.names.ja; name = $item.names.en; prefecture = $item.location.prefecture
    region = $regionLabel; latitude = $item.location.latitude; longitude = $item.location.longitude
    theme = 'Designated heritage place'; tier = 'record'
  })
}
if ($appLocations.Count -ne 300) { throw "Expected 300 app locations, found $($appLocations.Count)" }
$appOutput = Join-Path $appRoot 'KASANE\locations-300.json'
[System.IO.File]::WriteAllText($appOutput, ($appLocations | ConvertTo-Json -Depth 6), $utf8NoBom)
Write-Output "Built $appOutput with $($appLocations.Count) map locations."
