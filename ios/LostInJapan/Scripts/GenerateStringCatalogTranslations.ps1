param(
    [string]$CatalogPath = (Join-Path $PSScriptRoot '..\LostInJapan\Resources\Localizable.xcstrings')
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new()

$catalog = Get-Content -Raw -Encoding UTF8 -LiteralPath $CatalogPath | ConvertFrom-Json

$seed = [ordered]@{
    'error.title'='Something went wrong'; 'error.photo'='The photos could not be loaded.'; 'error.category'='Select at least one item.'
    'registration.photoCount %lld'='%lld photos selected'
    'status.draft'='Draft'; 'status.searching'='Searching'; 'status.found'='Found'; 'status.completed'='Completed'
    'item.passport'='Passport'; 'item.wallet'='Wallet'; 'item.smartphone'='Smartphone'; 'item.creditCard'='Credit card'; 'item.cash'='Cash'; 'item.suitcase'='Suitcase'; 'item.bag'='Backpack or bag'; 'item.camera'='Camera'; 'item.keys'='Keys'; 'item.earphones'='Earphones'; 'item.transitCard'='Transit card'; 'item.residenceCard'='Residence card'; 'item.airlineTicket'='Airline ticket'; 'item.medicine'='Prescription medicine'; 'item.childItem'="Child's belongings"; 'item.other'='Other'
    'location.train'='Train'; 'location.station'='Station'; 'location.bulletTrain'='Shinkansen'; 'location.subway'='Subway'; 'location.bus'='Bus'; 'location.taxi'='Taxi'; 'location.airport'='Airport'; 'location.hotel'='Hotel'; 'location.restaurant'='Restaurant'; 'location.convenienceStore'='Convenience store'; 'location.mall'='Shopping center'; 'location.attraction'='Tourist attraction'; 'location.park'='Park'; 'location.street'='Street'; 'location.restroom'='Restroom'; 'location.locker'='Coin locker'; 'location.rentalCar'='Rental car'; 'location.unknown'='Not sure'
    'emergency.passport'='Lost passport'; 'emergency.wallet'='Lost wallet'; 'emergency.phone'='Lost smartphone'; 'emergency.card'='Lost credit card'; 'emergency.medicine'='Lost medicine'; 'emergency.child'='Separated from a child'; 'emergency.theft'='Possible theft'; 'emergency.departure'='Departure date is near'; 'emergency.warning'='If theft is possible, explain the situation to the police.'
    'found.doNow'='What to do now'; 'found.station'='At a station: give it to station staff'; 'found.store'='Inside a store: give it to store staff'; 'found.street'='On the street: take it to a police box'; 'found.dontInspect'='Do not inspect the contents more than necessary'; 'found.card'='Show this Japanese card'
}

foreach ($entry in $seed.GetEnumerator()) {
    if (-not $catalog.strings.PSObject.Properties[$entry.Key]) {
        $localizations = [pscustomobject]@{
            en = [pscustomobject]@{ stringUnit = [pscustomobject]@{ state = 'translated'; value = $entry.Value } }
        }
        $catalog.strings | Add-Member -NotePropertyName $entry.Key -NotePropertyValue ([pscustomobject]@{ localizations = $localizations })
    }
}

$targets = @('zh-Hans','zh-Hant','ko','es','fr','de','th','ja')
$separatorToken = '__LIJSEP__'
$separator = "`n$separatorToken`n"

foreach ($language in $targets) {
    $missing = @($catalog.strings.PSObject.Properties | Where-Object {
        $_.Value.localizations.en.stringUnit.value -and -not $_.Value.localizations.PSObject.Properties[$language]
    })
    if ($missing.Count -eq 0) { continue }

    for ($offset = 0; $offset -lt $missing.Count; $offset += 12) {
        $last = [Math]::Min($offset + 11, $missing.Count - 1)
        $batch = @($missing[$offset..$last])
        $source = ($batch | ForEach-Object { $_.Value.localizations.en.stringUnit.value }) -join $separator
        $targetCode = if ($language -eq 'zh-Hans') { 'zh-CN' } elseif ($language -eq 'zh-Hant') { 'zh-TW' } else { $language }
        $response = Invoke-RestMethod -Method Post -Uri 'https://translate.googleapis.com/translate_a/single' -Body @{
            client='gtx'; sl='en'; tl=$targetCode; dt='t'; q=$source
        }
        $translatedText = ($response[0] | ForEach-Object { $_[0] }) -join ''
        $translations = @($translatedText -split "\s*__LIJSEP__\s*")
        if ($translations.Count -ne $batch.Count) {
            throw "Translation count mismatch for $language at $offset. Expected $($batch.Count), received $($translations.Count)."
        }
        for ($index = 0; $index -lt $batch.Count; $index++) {
            $unit = [pscustomobject]@{ stringUnit = [pscustomobject]@{ state = 'translated'; value = $translations[$index].Trim() } }
            $batch[$index].Value.localizations | Add-Member -NotePropertyName $language -NotePropertyValue $unit
        }
    }
}

# Short labels can be ambiguous without screen context. Keep reviewed wording here.
$corrections = @(
    [pscustomobject]@{ Key = 'location.train'; Language = 'fr'; Value = 'Train' }
)
foreach ($correction in $corrections) {
    $catalog.strings.PSObject.Properties[$correction.Key].Value.localizations.PSObject.Properties[$correction.Language].Value.stringUnit.value = $correction.Value
}

$json = $catalog | ConvertTo-Json -Depth 20
[IO.File]::WriteAllText((Resolve-Path $CatalogPath), $json, [Text.UTF8Encoding]::new($false))
Write-Output "Updated $CatalogPath with $($catalog.strings.PSObject.Properties.Count) keys across 9 languages."
