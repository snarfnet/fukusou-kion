$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$sourcePaths = (Get-ChildItem (Join-Path $projectRoot 'Assets\ShinobiZero\Core\*.cs')).FullName
Add-Type -Path $sourcePaths

$checks = 0
function Assert-Equal($actual, $expected, $message) {
    if ($actual -ne $expected) {
        throw "$message — expected $expected, got $actual"
    }
    $script:checks++
}
function Assert-Close($actual, $expected, $tolerance, $message) {
    if ([Math]::Abs($actual - $expected) -gt $tolerance) {
        throw "$message — expected $expected ± $tolerance, got $actual"
    }
    $script:checks++
}

$bull = [ShinobiZero.Core.DartboardGeometry]::Score(0, 0)
Assert-Equal $bull.Score 50 'Centre scores bull'
$tripleTwenty = [ShinobiZero.Core.DartboardGeometry]::Score(0, [ShinobiZero.Core.DartboardGeometry]::TripleAimRadius)
Assert-Equal $tripleTwenty.Score 60 'Top triple scores sixty'
$doubleTwenty = [ShinobiZero.Core.DartboardGeometry]::Score(0, [ShinobiZero.Core.DartboardGeometry]::DoubleAimRadius)
Assert-Equal $doubleTwenty.Score 40 'Top double scores forty'
$miss = [ShinobiZero.Core.DartboardGeometry]::Score(1.1, 0)
Assert-Equal $miss.Score 0 'Outside board misses'
Assert-Close ([ShinobiZero.Core.DartboardGeometry]::InnerBullRadius * 170) 6.35 0.0001 'Inner bull uses regulation radius'
for ($sectorIndex = 0; $sectorIndex -lt 20; $sectorIndex++) {
    $angle = $sectorIndex * [Math]::PI / 10
    $sectorHit = [ShinobiZero.Core.DartboardGeometry]::Score([Math]::Sin($angle) * 0.4, [Math]::Cos($angle) * 0.4)
    Assert-Equal $sectorHit.Base ([ShinobiZero.Core.DartboardGeometry]::ClockwiseNumbers[$sectorIndex]) "Sector $sectorIndex follows regulation order"
}

$checkout = [ShinobiZero.Core.DartsRules]::Resolve(40, 40, [ShinobiZero.Core.DartHit]::new(20, 2), $true)
Assert-Equal $checkout.Win $true 'Double twenty checks out forty'
$invalid = [ShinobiZero.Core.DartsRules]::Resolve(20, 20, [ShinobiZero.Core.DartHit]::new(20, 1), $true)
Assert-Equal $invalid.Bust $true 'Single cannot double out'
Assert-Equal $invalid.Remaining 20 'Invalid checkout restores turn start'
$leaveOne = [ShinobiZero.Core.DartsRules]::Resolve(20, 60, [ShinobiZero.Core.DartHit]::new(19, 1), $false)
Assert-Equal $leaveOne.Remaining 1 'Straight out permits leaving one'
Assert-Equal $leaveOne.Bust $false 'Straight out one is not bust'
$doubleOutOne = [ShinobiZero.Core.DartsRules]::Resolve(20, 60, [ShinobiZero.Core.DartHit]::new(19, 1), $true)
Assert-Equal $doubleOutOne.Bust $true 'Double out cannot leave one'

$platformCareer = [ShinobiZero.Core.CareerStats]::new()
$platformCareer.Matches = 12
$platformCareer.Wins = 7
$platformCareer.Losses = 5
$platformCareer.BestCheckout = 104
$platformSnapshot = [ShinobiZero.Core.PlatformProgressSnapshot]::From($platformCareer)
Assert-Equal $platformSnapshot.Stats.Length 9 'Platform snapshot exposes complete stable stats'
Assert-Equal (($platformSnapshot.Stats | Where-Object Id -eq 'SZ_STAT_WINS').Value) 7 'Platform wins use Steam-ready ID'
Assert-Equal ($platformSnapshot.Achievements -contains 'SZ_FIRST_VICTORY') $true 'Platform snapshot publishes achievements'
Assert-Equal ($platformSnapshot.Achievements -contains 'SZ_CHECKOUT_100') $true 'Platform snapshot publishes checkout achievement'

$standardImpact = [ShinobiZero.Core.ImpactFeedbackModel]::Evaluate(
    [ShinobiZero.Core.ThrowOutcome]::new([ShinobiZero.Core.Combatant]::Player, [ShinobiZero.Core.DartHit]::new(20, 1), [ShinobiZero.Core.ScoreResolution]::new(281, $false, $false, $false), $false, $false, $false))
$tripleImpact = [ShinobiZero.Core.ImpactFeedbackModel]::Evaluate(
    [ShinobiZero.Core.ThrowOutcome]::new([ShinobiZero.Core.Combatant]::Player, [ShinobiZero.Core.DartHit]::new(20, 3), [ShinobiZero.Core.ScoreResolution]::new(241, $false, $false, $false), $false, $false, $false))
$victoryImpact = [ShinobiZero.Core.ImpactFeedbackModel]::Evaluate(
    [ShinobiZero.Core.ThrowOutcome]::new([ShinobiZero.Core.Combatant]::Player, [ShinobiZero.Core.DartHit]::new(20, 2), [ShinobiZero.Core.ScoreResolution]::new(0, $false, $false, $true), $true, $true, $true))
Assert-Equal $standardImpact.Tier ([ShinobiZero.Core.ImpactTier]::Standard) 'Single hit uses standard impact'
Assert-Equal $tripleImpact.Tier ([ShinobiZero.Core.ImpactTier]::Triple) 'Triple uses premium impact'
Assert-Equal $victoryImpact.Tier ([ShinobiZero.Core.ImpactTier]::MatchVictory) 'Player checkout selects victory finish'
Assert-Equal ($victoryImpact.CameraStrength -gt $tripleImpact.CameraStrength) $true 'Victory finish has strongest camera response'
Assert-Equal ($victoryImpact.SparkCount -gt $tripleImpact.SparkCount) $true 'Victory finish has richest spark burst'

$softPlayerMotion = [ShinobiZero.Core.PlayerThrowMotionModel]::Tune(0.1, 0, $false)
$strongPlayerMotion = [ShinobiZero.Core.PlayerThrowMotionModel]::Tune(0.95, 0, $false)
$spinRightMotion = [ShinobiZero.Core.PlayerThrowMotionModel]::Tune(0.5, 500, $false)
$spinLeftMotion = [ShinobiZero.Core.PlayerThrowMotionModel]::Tune(0.5, -500, $false)
$reducedPlayerMotion = [ShinobiZero.Core.PlayerThrowMotionModel]::Tune(0.95, 500, $true)
Assert-Equal ($strongPlayerMotion.Duration -lt $softPlayerMotion.Duration) $true 'Strong first-person throw releases faster'
Assert-Equal ($strongPlayerMotion.FollowThrough -gt $softPlayerMotion.FollowThrough) $true 'Strong throw has deeper follow-through'
Assert-Equal ($spinRightMotion.WristBias -gt 0) $true 'Positive spin turns first-person wrist right'
Assert-Equal ($spinLeftMotion.WristBias -lt 0) $true 'Negative spin turns first-person wrist left'
Assert-Equal ($reducedPlayerMotion.Windup -lt ($strongPlayerMotion.Windup * 0.4)) $true 'Reduced motion softens first-person windup'

Assert-Equal ([ShinobiZero.Core.ResponsiveLayoutModel]::IsLandscape(1080, 1920)) $false 'iPhone portrait keeps authored HUD'
Assert-Equal ([ShinobiZero.Core.ResponsiveLayoutModel]::IsLandscape(1920, 1080)) $true 'Steam desktop selects landscape HUD'
Assert-Equal ([ShinobiZero.Core.ResponsiveLayoutModel]::LandscapeReferenceWidth) 1600 'Landscape canvas uses readable Steam reference width'
Assert-Equal ([ShinobiZero.Core.ResponsiveLayoutModel]::LandscapeReferenceHeight) 900 'Landscape canvas uses readable Steam reference height'
Assert-Equal ([ShinobiZero.Core.ResponsiveLayoutModel]::PhysicalPixels(22, 1280, 800, $true) -ge 18) $true 'Steam Deck smallest text remains at least eighteen pixels'
$deckButtonHeight = [ShinobiZero.Core.ResponsiveLayoutModel]::Size(330, 68, $true).Y
Assert-Equal ([ShinobiZero.Core.ResponsiveLayoutModel]::PhysicalPixels($deckButtonHeight, 1280, 800, $true) -ge 40) $true 'Steam Deck smallest action remains at least forty pixels high'
$landscapeTop = [ShinobiZero.Core.ResponsiveLayoutModel]::Position(0, 760, $true)
$landscapeBottom = [ShinobiZero.Core.ResponsiveLayoutModel]::Position(0, -760, $true)
$landscapeLeft = [ShinobiZero.Core.ResponsiveLayoutModel]::Position(-424, 180, $true)
$landscapeRight = [ShinobiZero.Core.ResponsiveLayoutModel]::Position(424, 180, $true)
Assert-Equal ($landscapeTop.Y -lt 540) $true 'Top HUD content fits 1080p reference'
Assert-Equal ($landscapeBottom.Y -gt -540) $true 'Bottom HUD content fits 1080p reference'
Assert-Equal ($landscapeLeft.X -gt -960) $true 'Leftmost opponent fits 1080p reference'
Assert-Equal ($landscapeRight.X -lt 960) $true 'Rightmost opponent fits 1080p reference'

Assert-Equal ([ShinobiZero.Core.UiFocusModel]::Resolve($true, $false, $false, $false, $false, $false)) ([ShinobiZero.Core.UiFocusTarget]::Selection) 'Selection screen receives controller focus'
Assert-Equal ([ShinobiZero.Core.UiFocusModel]::Resolve($true, $true, $false, $false, $false, $false)) ([ShinobiZero.Core.UiFocusTarget]::Result) 'Result focus overrides selection'
Assert-Equal ([ShinobiZero.Core.UiFocusModel]::Resolve($true, $true, $true, $true, $true, $false)) ([ShinobiZero.Core.UiFocusTarget]::Settings) 'Settings overlay receives focus'
Assert-Equal ([ShinobiZero.Core.UiFocusModel]::Resolve($true, $true, $true, $true, $true, $true)) ([ShinobiZero.Core.UiFocusTarget]::Pause) 'Pause overlay has highest focus priority'
Assert-Equal ([ShinobiZero.Core.UiFocusModel]::Resolve($false, $false, $false, $false, $false, $false)) ([ShinobiZero.Core.UiFocusTarget]::None) 'Active match leaves UI focus clear for throwing'
Assert-Equal ([ShinobiZero.Core.UiFocusModel]::ResolveBack($false, $false, $false, $false)) ([ShinobiZero.Core.UiBackTarget]::None) 'Back does nothing without a closable screen'
Assert-Equal ([ShinobiZero.Core.UiFocusModel]::ResolveBack($true, $false, $false, $false)) ([ShinobiZero.Core.UiBackTarget]::Result) 'Back leaves the result screen'
Assert-Equal ([ShinobiZero.Core.UiFocusModel]::ResolveBack($true, $true, $false, $false)) ([ShinobiZero.Core.UiBackTarget]::Calibration) 'Calibration overrides the result back target'
Assert-Equal ([ShinobiZero.Core.UiFocusModel]::ResolveBack($true, $true, $true, $false)) ([ShinobiZero.Core.UiBackTarget]::Tutorial) 'Tutorial overrides lower back targets'
Assert-Equal ([ShinobiZero.Core.UiFocusModel]::ResolveBack($true, $true, $true, $true)) ([ShinobiZero.Core.UiBackTarget]::Settings) 'Settings receives the topmost back action'

$settingsJapanese = "$([char]0x8A2D)$([char]0x5B9A)"
$beginDuelJapanese = "$([char]0x5BFE)$([char]0x6226)$([char]0x3092)$([char]0x59CB)$([char]0x3081)$([char]0x308B)"
Assert-Equal ([ShinobiZero.Core.LocalizationCatalog]::Literal($settingsJapanese, [ShinobiZero.Core.GameLanguage]::Japanese)) $settingsJapanese 'Japanese UI remains the iOS default'
Assert-Equal ([ShinobiZero.Core.LocalizationCatalog]::Literal($beginDuelJapanese, [ShinobiZero.Core.GameLanguage]::English)) 'BEGIN DUEL' 'Steam UI translates primary action'
$quitJapanese = "$([char]0x7D42)$([char]0x4E86)"
Assert-Equal ([ShinobiZero.Core.LocalizationCatalog]::Literal($quitJapanese, [ShinobiZero.Core.GameLanguage]::English)) 'QUIT' 'Steam UI translates desktop quit action'
Assert-Equal ([ShinobiZero.Core.OpponentStrategyNames]::English([ShinobiZero.Core.OpponentStrategy]::CheckoutSpecialist)) 'Tactician' 'Enemy tactics have English labels'
Assert-Equal ([ShinobiZero.Core.AchievementCatalog]::EnglishTitle([ShinobiZero.Core.AchievementCatalog]::MaximumTurn)) 'Perfect 180' 'Achievements have Steam-ready English titles'
Assert-Equal ([ShinobiZero.Core.AchievementCatalog]::Title([ShinobiZero.Core.AchievementCatalog]::MaximumTurn, [ShinobiZero.Core.GameLanguage]::Japanese)) ([ShinobiZero.Core.AchievementCatalog]::JapaneseTitle([ShinobiZero.Core.AchievementCatalog]::MaximumTurn)) 'Stable achievement ID resolves Japanese at display time'
Assert-Equal ([ShinobiZero.Core.AchievementCatalog]::Title([ShinobiZero.Core.AchievementCatalog]::MaximumTurn, [ShinobiZero.Core.GameLanguage]::English)) 'Perfect 180' 'Stable achievement ID resolves English at display time'
Assert-Equal ([ShinobiZero.Core.AchievementCatalog]::Title('MOD_UNKNOWN', [ShinobiZero.Core.GameLanguage]::English)) 'MOD_UNKNOWN' 'Unknown achievement ID remains diagnosable'
$legacyPreferences = [ShinobiZero.Core.PreferencesCodec]::Decode(256 + 1 + 2)
Assert-Equal $legacyPreferences.EnglishUi $false 'Existing settings remain Japanese after upgrade'
Assert-Equal $legacyPreferences.Fullscreen $true 'Existing desktop settings migrate to fullscreen'
$englishPreferences = [ShinobiZero.Core.GamePreferences]::new($true, $true, $false, $true)
$decodedEnglishPreferences = [ShinobiZero.Core.PreferencesCodec]::Decode([ShinobiZero.Core.PreferencesCodec]::Encode($englishPreferences))
Assert-Equal $decodedEnglishPreferences.EnglishUi $true 'English preference survives save round trip'
$windowedPreferences = [ShinobiZero.Core.GamePreferences]::new($true, $true, $false, $true, $false)
$decodedWindowedPreferences = [ShinobiZero.Core.PreferencesCodec]::Decode([ShinobiZero.Core.PreferencesCodec]::Encode($windowedPreferences))
Assert-Equal $decodedWindowedPreferences.Fullscreen $false 'Steam windowed preference survives save round trip'

$turnHistory = [ShinobiZero.Core.TurnHistoryTracker]::new()
$turnHistory.Record([ShinobiZero.Core.ThrowOutcome]::new([ShinobiZero.Core.Combatant]::Player, [ShinobiZero.Core.DartHit]::new(20, 3), [ShinobiZero.Core.ScoreResolution]::new(241, $false, $false, $false), $false, $false, $false))
$turnHistory.Record([ShinobiZero.Core.ThrowOutcome]::new([ShinobiZero.Core.Combatant]::Player, [ShinobiZero.Core.DartHit]::new(20, 1), [ShinobiZero.Core.ScoreResolution]::new(221, $false, $false, $false), $false, $false, $false))
Assert-Equal $turnHistory.Count 2 'Turn history retains each shuriken'
Assert-Equal $turnHistory.Total 80 'Turn history totals scoring throws'
$turnHistory.Record([ShinobiZero.Core.ThrowOutcome]::new([ShinobiZero.Core.Combatant]::Player, [ShinobiZero.Core.DartHit]::new(20, 3), [ShinobiZero.Core.ScoreResolution]::new(301, $true, $false, $false), $true, $false, $false))
Assert-Equal $turnHistory.Bust $true 'Turn history marks bust'
Assert-Equal $turnHistory.Total 0 'Bust contributes zero counted turn score'
$turnHistory.Record([ShinobiZero.Core.ThrowOutcome]::new([ShinobiZero.Core.Combatant]::Enemy, [ShinobiZero.Core.DartHit]::new(19, 3), [ShinobiZero.Core.ScoreResolution]::new(244, $false, $false, $false), $false, $false, $false))
Assert-Equal $turnHistory.Count 1 'New thrower starts a fresh history'
Assert-Equal $turnHistory.Total 57 'Enemy history starts from its first throw'

Assert-Equal ([ShinobiZero.Core.ApplicationLifecycleModel]::ShouldPauseAudio($true, $false, $false)) $false 'Foreground menu keeps audio active'
Assert-Equal ([ShinobiZero.Core.ApplicationLifecycleModel]::ShouldPauseAudio($false, $false, $false)) $true 'Focus loss pauses audio'
Assert-Equal ([ShinobiZero.Core.ApplicationLifecycleModel]::ShouldPauseAudio($true, $true, $false)) $true 'OS suspension pauses audio'
Assert-Equal ([ShinobiZero.Core.ApplicationLifecycleModel]::ShouldPauseAudio($true, $false, $true)) $true 'Focus return preserves match pause audio state'
Assert-Equal ([ShinobiZero.Core.ApplicationLifecycleModel]::ShouldPauseAudio($true, $false, $false, $true)) $true 'Steam overlay pauses audio in menus and matches'
Assert-Equal ([ShinobiZero.Core.ApplicationLifecycleModel]::CanResume($true, $false, $false)) $true 'Foreground app can resume match'
Assert-Equal ([ShinobiZero.Core.ApplicationLifecycleModel]::CanResume($false, $false, $false)) $false 'Unfocused app cannot resume match'
Assert-Equal ([ShinobiZero.Core.ApplicationLifecycleModel]::CanResume($true, $true, $false)) $false 'Suspended app cannot resume match'
Assert-Equal ([ShinobiZero.Core.ApplicationLifecycleModel]::CanResume($true, $false, $true)) $false 'Steam overlay blocks match resume'
Assert-Equal ([ShinobiZero.Core.ScreenWakePolicy]::ShouldPreventSleep($true, $false, $false, $true, $false)) $true 'Active foreground match keeps iPhone awake'
Assert-Equal ([ShinobiZero.Core.ScreenWakePolicy]::ShouldPreventSleep($false, $false, $false, $true, $false)) $false 'Selection screen follows system sleep setting'
Assert-Equal ([ShinobiZero.Core.ScreenWakePolicy]::ShouldPreventSleep($true, $false, $true, $true, $false)) $false 'Paused match follows system sleep setting'
Assert-Equal ([ShinobiZero.Core.ScreenWakePolicy]::ShouldPreventSleep($true, $false, $false, $false, $false)) $false 'Unfocused match follows system sleep setting'
Assert-Equal ([ShinobiZero.Core.ScreenWakePolicy]::ShouldPreventSleep($true, $false, $false, $true, $true)) $false 'Suspended match follows system sleep setting'

$invalidCareer = [ShinobiZero.Core.CareerStats]::new()
$invalidCareer.Version = 1
$invalidCareer.Revision = -5
$invalidCareer.Matches = -1
$invalidCareer.Wins = 3
$invalidCareer.Losses = 2
$invalidCareer.PlayerThrows = 4
$invalidCareer.ScoringThrows = 9
$invalidCareer.BestTurn = 999
$invalidCareer.BestCheckout = 999
$invalidCareer.Normalize(5)
Assert-Equal $invalidCareer.Version 2 'Legacy career migrates to current schema'
Assert-Equal $invalidCareer.Revision 0 'Negative cloud revision is repaired'
Assert-Equal $invalidCareer.Matches 5 'Career matches cannot trail wins and losses'
Assert-Equal $invalidCareer.ScoringThrows 4 'Career scoring hits cannot exceed throws'
Assert-Equal $invalidCareer.BestTurn 180 'Career best turn respects darts maximum'
Assert-Equal $invalidCareer.BestCheckout 170 'Career checkout respects darts maximum'
$localCareerCandidate = [ShinobiZero.Core.CareerStats]::new()
$cloudCareerCandidate = [ShinobiZero.Core.CareerStats]::new()
$localCareerCandidate.Revision = 4
$localCareerCandidate.Matches = 20
$cloudCareerCandidate.Revision = 5
$cloudCareerCandidate.Matches = 10
Assert-Equal ([object]::ReferenceEquals([ShinobiZero.Core.CareerSaveResolver]::Choose($localCareerCandidate, $cloudCareerCandidate), $cloudCareerCandidate)) $true 'Higher revision wins cloud conflict'
$cloudCareerCandidate.Revision = 4
$cloudCareerCandidate.Matches = 21
Assert-Equal ([object]::ReferenceEquals([ShinobiZero.Core.CareerSaveResolver]::Choose($localCareerCandidate, $cloudCareerCandidate), $cloudCareerCandidate)) $true 'Match count resolves legacy revision tie'
$activeCheckpointCareer = [ShinobiZero.Core.CareerStats]::new()
$activeCheckpointCareer.Revision = 4
$activeCheckpointCareer.Matches = 8
$newerCloudCareer = [ShinobiZero.Core.CareerStats]::new()
$newerCloudCareer.Revision = 5
$newerCloudCareer.Matches = 9
Assert-Equal ([ShinobiZero.Core.CareerSaveResolver]::CanRestoreCheckpoint($activeCheckpointCareer, $newerCloudCareer)) $false 'Old active match cannot roll back newer cloud career'
Assert-Equal ([ShinobiZero.Core.CareerSaveResolver]::CanRestoreCheckpoint($activeCheckpointCareer, $activeCheckpointCareer)) $true 'Matching active checkpoint can resume'
Assert-Equal ([ShinobiZero.Core.CareerSaveResolver]::CanRestoreCheckpoint($activeCheckpointCareer, $null)) $true 'Active checkpoint can restore when career is missing'

$enemyVictoryReaction = [ShinobiZero.Core.NinjaReactionModel]::Evaluate([ShinobiZero.Core.ThrowOutcome]::new([ShinobiZero.Core.Combatant]::Enemy, [ShinobiZero.Core.DartHit]::new(20, 2), [ShinobiZero.Core.ScoreResolution]::new(0, $false, $false, $true), $true, $true, $true))
$playerVictoryReaction = [ShinobiZero.Core.NinjaReactionModel]::Evaluate([ShinobiZero.Core.ThrowOutcome]::new([ShinobiZero.Core.Combatant]::Player, [ShinobiZero.Core.DartHit]::new(20, 2), [ShinobiZero.Core.ScoreResolution]::new(0, $false, $false, $true), $true, $true, $true))
$enemyBustReaction = [ShinobiZero.Core.NinjaReactionModel]::Evaluate([ShinobiZero.Core.ThrowOutcome]::new([ShinobiZero.Core.Combatant]::Enemy, [ShinobiZero.Core.DartHit]::new(20, 3), [ShinobiZero.Core.ScoreResolution]::new(60, $true, $false, $false), $true, $false, $false))
$playerTripleReaction = [ShinobiZero.Core.NinjaReactionModel]::Evaluate([ShinobiZero.Core.ThrowOutcome]::new([ShinobiZero.Core.Combatant]::Player, [ShinobiZero.Core.DartHit]::new(20, 3), [ShinobiZero.Core.ScoreResolution]::new(241, $false, $false, $false), $false, $false, $false))
$ordinaryReaction = [ShinobiZero.Core.NinjaReactionModel]::Evaluate([ShinobiZero.Core.ThrowOutcome]::new([ShinobiZero.Core.Combatant]::Player, [ShinobiZero.Core.DartHit]::new(20, 1), [ShinobiZero.Core.ScoreResolution]::new(281, $false, $false, $false), $false, $false, $false))
Assert-Equal $enemyVictoryReaction.Type ([ShinobiZero.Core.NinjaReactionType]::Victory) 'Enemy checkout triggers victory stance'
Assert-Equal $playerVictoryReaction.Type ([ShinobiZero.Core.NinjaReactionType]::Defeat) 'Player victory breaks enemy stance'
Assert-Equal $enemyBustReaction.Type ([ShinobiZero.Core.NinjaReactionType]::Frustration) 'Enemy bust triggers frustration'
Assert-Equal $playerTripleReaction.Type ([ShinobiZero.Core.NinjaReactionType]::Frustration) 'Player triple challenges enemy composure'
Assert-Equal $ordinaryReaction.Type ([ShinobiZero.Core.NinjaReactionType]::None) 'Ordinary single keeps ninja restrained'
Assert-Equal ($enemyVictoryReaction.Duration -gt $enemyBustReaction.Duration) $true 'Match reaction outlasts minor reaction'
Assert-Equal ($playerVictoryReaction.VerticalShift -lt 0) $true 'Defeat stance visibly drops'

$lightPulse = [ShinobiZero.Core.HapticPulseModel]::Get([ShinobiZero.Core.HapticCue]::Light)
$mediumPulse = [ShinobiZero.Core.HapticPulseModel]::Get([ShinobiZero.Core.HapticCue]::Medium)
$successPulse = [ShinobiZero.Core.HapticPulseModel]::Get([ShinobiZero.Core.HapticCue]::Success)
$errorPulse = [ShinobiZero.Core.HapticPulseModel]::Get([ShinobiZero.Core.HapticCue]::Error)
Assert-Equal ($lightPulse.HighFrequency -gt $lightPulse.LowFrequency) $true 'Light haptic favors crisp gamepad motor'
Assert-Equal ($mediumPulse.HighFrequency -gt $lightPulse.HighFrequency) $true 'Impact haptic is stronger than launch cue'
Assert-Equal ($successPulse.Duration -gt $mediumPulse.Duration) $true 'Success haptic sustains finish feedback'
Assert-Equal ($errorPulse.LowFrequency -gt $errorPulse.HighFrequency) $true 'Bust haptic uses heavy low motor'
Assert-Equal ($lightPulse.Duration -gt 0) $true 'Light haptic has positive duration'
Assert-Equal ($successPulse.LowFrequency -le 1) $true 'Success low motor remains bounded'
Assert-Equal ($successPulse.HighFrequency -le 1) $true 'Success high motor remains bounded'

$performanceGovernor = [ShinobiZero.Core.PerformanceGovernor]::new([ShinobiZero.Core.RuntimeQualityTier]::High)
Assert-Equal ($performanceGovernor.Sample(22)) $false 'One slow window does not lower quality'
Assert-Equal ($performanceGovernor.Sample(22)) $false 'Two slow windows do not lower quality'
Assert-Equal ($performanceGovernor.Sample(22)) $true 'Three slow windows lower quality'
Assert-Equal $performanceGovernor.Tier ([ShinobiZero.Core.RuntimeQualityTier]::Balanced) 'Quality lowers one tier at a time'
$recoveryGovernor = [ShinobiZero.Core.PerformanceGovernor]::new([ShinobiZero.Core.RuntimeQualityTier]::Performance)
for ($stableWindow = 0; $stableWindow -lt 11; $stableWindow++) { $recoveryGovernor.Sample(16.7) | Out-Null }
Assert-Equal $recoveryGovernor.Tier ([ShinobiZero.Core.RuntimeQualityTier]::Performance) 'Quality recovery requires sustained stability'
Assert-Equal ($recoveryGovernor.Sample(16.7)) $true 'Twelfth stable window recovers quality'
Assert-Equal $recoveryGovernor.Tier ([ShinobiZero.Core.RuntimeQualityTier]::Balanced) 'Recovery raises only one tier'
Assert-Equal ([ShinobiZero.Core.PerformanceGovernor]::InitialTier(2000, 512, $true)) ([ShinobiZero.Core.RuntimeQualityTier]::Performance) 'Low-memory iPhone starts safely'
Assert-Equal ([ShinobiZero.Core.PerformanceGovernor]::InitialTier(3000, 0, $true)) ([ShinobiZero.Core.RuntimeQualityTier]::Balanced) 'Mid-memory iPhone starts balanced'
Assert-Equal ([ShinobiZero.Core.PerformanceGovernor]::InitialTier(16000, 0, $false)) ([ShinobiZero.Core.RuntimeQualityTier]::High) 'Steam desktop starts high quality'
$memoryGovernor = [ShinobiZero.Core.PerformanceGovernor]::new([ShinobiZero.Core.RuntimeQualityTier]::High)
Assert-Equal ($memoryGovernor.HandleMemoryPressure()) $true 'iOS memory warning changes quality immediately'
Assert-Equal $memoryGovernor.Tier ([ShinobiZero.Core.RuntimeQualityTier]::Performance) 'Memory warning selects minimum allocation tier'
for ($memoryRecovery = 0; $memoryRecovery -lt 11; $memoryRecovery++) { $memoryGovernor.Sample(16.7) | Out-Null }
Assert-Equal $memoryGovernor.Tier ([ShinobiZero.Core.RuntimeQualityTier]::Performance) 'Memory pressure recovery waits for sustained stability'
Assert-Equal ($memoryGovernor.Sample(16.7)) $true 'Stable memory-pressure session recovers one tier after twelve windows'
Assert-Equal $memoryGovernor.Tier ([ShinobiZero.Core.RuntimeQualityTier]::Balanced) 'Memory recovery cannot jump directly to high quality'

function New-RankCareer($wins, $defeated) {
    $rankCareer = [ShinobiZero.Core.CareerStats]::new()
    $rankCareer.Wins = $wins
    $rankCareer.OpponentWins = [int[]]::new(5)
    for ($rankOpponent = 0; $rankOpponent -lt $defeated; $rankOpponent++) { $rankCareer.OpponentWins[$rankOpponent] = 1 }
    return $rankCareer
}
Assert-Equal ([ShinobiZero.Core.CareerRankModel]::Evaluate((New-RankCareer 0 0)).Rank) ([ShinobiZero.Core.CareerRank]::Initiate) 'New player starts as initiate'
Assert-Equal ([ShinobiZero.Core.CareerRankModel]::Evaluate((New-RankCareer 1 1)).Rank) ([ShinobiZero.Core.CareerRank]::Genin) 'First distinct victory awards genin'
Assert-Equal ([ShinobiZero.Core.CareerRankModel]::Evaluate((New-RankCareer 3 2)).Rank) ([ShinobiZero.Core.CareerRank]::Chunin) 'Three wins over two rivals awards chunin'
Assert-Equal ([ShinobiZero.Core.CareerRankModel]::Evaluate((New-RankCareer 7 4)).Rank) ([ShinobiZero.Core.CareerRank]::Jonin) 'Seven wins over four rivals awards jonin'
$shadowProgress = [ShinobiZero.Core.CareerRankModel]::Evaluate((New-RankCareer 10 5))
Assert-Equal $shadowProgress.Rank ([ShinobiZero.Core.CareerRank]::Shadow) 'Ten wins over all rivals awards shadow'
Assert-Equal $shadowProgress.IsMaximum $true 'Shadow rank is maximum'
Assert-Equal ([ShinobiZero.Core.CareerRankModel]::Evaluate((New-RankCareer 20 1)).Rank) ([ShinobiZero.Core.CareerRank]::Genin) 'Wins alone cannot skip rival mastery'
$chuninProgress = [ShinobiZero.Core.CareerRankModel]::Evaluate((New-RankCareer 3 2))
Assert-Equal $chuninProgress.NextWins 7 'Rank progress exposes next win target'
Assert-Equal $chuninProgress.NextOpponents 4 'Rank progress exposes next rival target'
Assert-Equal ([ShinobiZero.Core.CareerRankModel]::English([ShinobiZero.Core.CareerRank]::Shadow)) 'SHADOW' 'Career rank has English Steam label'
Assert-Equal ([ShinobiZero.Core.CareerRankModel]::IsPromotion([ShinobiZero.Core.CareerRank]::Initiate, [ShinobiZero.Core.CareerRank]::Genin)) $true 'Higher career rank triggers promotion'
Assert-Equal ([ShinobiZero.Core.CareerRankModel]::IsPromotion([ShinobiZero.Core.CareerRank]::Chunin, [ShinobiZero.Core.CareerRank]::Chunin)) $false 'Same rank does not repeat promotion'
Assert-Equal ([ShinobiZero.Core.CareerRankModel]::IsPromotion([ShinobiZero.Core.CareerRank]::Jonin, [ShinobiZero.Core.CareerRank]::Genin)) $false 'Lower rank cannot trigger promotion'

$stillTitle = [ShinobiZero.Core.TitleMotionModel]::Evaluate(99, $false, $true)
Assert-Close $stillTitle.Scale 1 0.0001 'Reduced motion stops title zoom'
Assert-Close $stillTitle.X 0 0.0001 'Reduced motion stops title horizontal drift'
Assert-Close $stillTitle.Y 0 0.0001 'Reduced motion stops title vertical drift'
for ($titleSecond = 0; $titleSecond -le 120; $titleSecond++) {
    $portraitTitleMotion = [ShinobiZero.Core.TitleMotionModel]::Evaluate($titleSecond, $false, $false)
    $landscapeTitleMotion = [ShinobiZero.Core.TitleMotionModel]::Evaluate($titleSecond, $true, $false)
    Assert-Equal ($portraitTitleMotion.Scale -ge 1.018 -and $portraitTitleMotion.Scale -le 1.026) $true "Portrait title zoom is subtle at $titleSecond seconds"
    Assert-Equal ([Math]::Abs($portraitTitleMotion.X) -le 8.001) $true "Portrait title drift is bounded at $titleSecond seconds"
    Assert-Equal ([Math]::Abs($landscapeTitleMotion.X) -le 13.001) $true "Landscape title drift is bounded at $titleSecond seconds"
}

$enemyStartMatch = [ShinobiZero.Core.MatchEngine]::new()
$enemyStartMatch.Start([ShinobiZero.Core.MatchConfig]::new(301, $false, 2, [ShinobiZero.Core.Combatant]::Enemy))
Assert-Equal $enemyStartMatch.Turn ([ShinobiZero.Core.Combatant]::Enemy) 'Enemy can start a match'
Assert-Equal $enemyStartMatch.Config.StartingPlayer ([ShinobiZero.Core.Combatant]::Enemy) 'Match retains chosen starter'
Assert-Equal ([ShinobiZero.Core.MatchOrder]::Opponent([ShinobiZero.Core.Combatant]::Player)) ([ShinobiZero.Core.Combatant]::Enemy) 'Completed match rotates player starter'

$enemyRoundMatch = [ShinobiZero.Core.MatchEngine]::new()
$enemyRoundMatch.Start([ShinobiZero.Core.MatchConfig]::new(301, $false, 1, [ShinobiZero.Core.Combatant]::Enemy))
for ($roundThrow = 0; $roundThrow -lt 3; $roundThrow++) { $enemyRoundMatch.Submit([ShinobiZero.Core.DartHit]::Miss) | Out-Null }
Assert-Equal $enemyRoundMatch.Round 1 'Enemy starter remains in round one after first turn'
Assert-Equal $enemyRoundMatch.Turn ([ShinobiZero.Core.Combatant]::Player) 'Player takes second turn when enemy starts'
for ($roundThrow = 0; $roundThrow -lt 3; $roundThrow++) { $enemyRoundMatch.Submit([ShinobiZero.Core.DartHit]::Miss) | Out-Null }
Assert-Equal $enemyRoundMatch.Round 2 'Enemy-started round advances after both turns'
Assert-Equal $enemyRoundMatch.Turn ([ShinobiZero.Core.Combatant]::Enemy) 'Enemy opens the next round again'

$alternatingLegRound = [ShinobiZero.Core.MatchEngine]::new()
$alternatingLegRound.Start([ShinobiZero.Core.MatchConfig]::new(301, $false, 2, [ShinobiZero.Core.Combatant]::Player))
for ($legThrow = 0; $legThrow -lt 3; $legThrow++) { $alternatingLegRound.Submit([ShinobiZero.Core.DartHit]::new(20, 3)) | Out-Null }
for ($legThrow = 0; $legThrow -lt 3; $legThrow++) { $alternatingLegRound.Submit([ShinobiZero.Core.DartHit]::Miss) | Out-Null }
$alternatingLegRound.Submit([ShinobiZero.Core.DartHit]::new(20, 3)) | Out-Null
$alternatingLegRound.Submit([ShinobiZero.Core.DartHit]::new(20, 3)) | Out-Null
$alternatingLegRound.Submit([ShinobiZero.Core.DartHit]::new(1, 1)) | Out-Null
Assert-Equal $alternatingLegRound.Turn ([ShinobiZero.Core.Combatant]::Enemy) 'Second leg alternates to enemy starter'
for ($legThrow = 0; $legThrow -lt 3; $legThrow++) { $alternatingLegRound.Submit([ShinobiZero.Core.DartHit]::Miss) | Out-Null }
Assert-Equal $alternatingLegRound.Round 1 'Alternated leg stays in round one after starter turn'
for ($legThrow = 0; $legThrow -lt 3; $legThrow++) { $alternatingLegRound.Submit([ShinobiZero.Core.DartHit]::Miss) | Out-Null }
Assert-Equal $alternatingLegRound.Round 2 'Alternated leg advances after both turns'

$snapshotSource = [ShinobiZero.Core.MatchEngine]::new()
$snapshotSource.Start([ShinobiZero.Core.MatchConfig]::new(501, $true, 2, [ShinobiZero.Core.Combatant]::Enemy))
$snapshotSource.Submit([ShinobiZero.Core.DartHit]::new(20, 3)) | Out-Null
$matchSnapshot = $snapshotSource.Capture()
$snapshotRestored = [ShinobiZero.Core.MatchEngine]::new()
Assert-Equal ($snapshotRestored.TryRestore($matchSnapshot)) $true 'Active match snapshot restores'
Assert-Equal $snapshotRestored.EnemyScore 441 'Restored match retains enemy score'
Assert-Equal $snapshotRestored.DartsLeft 2 'Restored match retains darts left'
Assert-Equal $snapshotRestored.Config.StartingPlayer ([ShinobiZero.Core.Combatant]::Enemy) 'Restored match retains starter'
$sourceAfterRestore = $snapshotSource.Submit([ShinobiZero.Core.DartHit]::new(19, 3))
$restoredAfterRestore = $snapshotRestored.Submit([ShinobiZero.Core.DartHit]::new(19, 3))
Assert-Equal $restoredAfterRestore.Score.Remaining $sourceAfterRestore.Score.Remaining 'Restored match resolves next throw identically'
$invalidMatchSnapshot = [ShinobiZero.Core.MatchStateSnapshot]::new()
$invalidMatchSnapshot.StartScore = 301
$invalidMatchSnapshot.LegsToWin = 1
$invalidMatchSnapshot.PlayerScore = -1
$invalidMatchSnapshot.EnemyScore = 301
$invalidMatchSnapshot.DartsLeft = 3
$invalidMatchSnapshot.Round = 1
$unstartedRestore = [ShinobiZero.Core.MatchEngine]::new()
Assert-Equal ($unstartedRestore.TryRestore($invalidMatchSnapshot)) $false 'Invalid active match snapshot is rejected'
Assert-Equal $unstartedRestore.HasStarted $false 'Rejected snapshot cannot partially start a match'

$performanceSource = [ShinobiZero.Core.MatchPerformanceTracker]::new()
$performanceSource.Record([ShinobiZero.Core.DartHit]::new(20, 3), $false, $false, $false)
$performanceRestored = [ShinobiZero.Core.MatchPerformanceTracker]::new()
Assert-Equal ($performanceRestored.TryRestore($performanceSource.Capture())) $true 'Match performance snapshot restores'
$performanceRestored.Record([ShinobiZero.Core.DartHit]::new(20, 1), $false, $true, $false)
Assert-Equal $performanceRestored.Performance.CountedScore 80 'Restored performance retains current turn score'

$resumeCareer = [ShinobiZero.Core.CareerStats]::new()
$careerBeforeRestart = [ShinobiZero.Core.CareerTracker]::new($resumeCareer)
$careerBeforeRestart.BeginMatch(2, 5)
$careerBeforeRestart.RecordPlayerThrow([ShinobiZero.Core.DartHit]::new(20, 3), $false, $true, $false, $false)
$careerAfterRestart = [ShinobiZero.Core.CareerTracker]::new($resumeCareer)
$careerAfterRestart.BeginMatch(2, 5)
$careerAfterRestart.RecordPlayerThrow([ShinobiZero.Core.DartHit]::new(20, 2), $false, $true, $true, $true)
Assert-Equal $resumeCareer.PlayerThrows 2 'Turn-boundary resume does not duplicate player throws'
Assert-Equal $resumeCareer.Matches 1 'Resumed career completes exactly one match'
Assert-Equal $resumeCareer.Wins 1 'Resumed career records exactly one win'

$developmentBuild = [ShinobiZero.Core.BuildIdentityResolver]::Resolve($null, $null)
Assert-Equal $developmentBuild.Version '0.1.0' 'Missing build version uses development default'
Assert-Equal $developmentBuild.BuildNumber 1 'Missing build number uses development default'
$storeBuild = [ShinobiZero.Core.BuildIdentityResolver]::Resolve('1.4.12', '803')
Assert-Equal $storeBuild.Version '1.4.12' 'Store semantic version is retained'
Assert-Equal $storeBuild.BuildNumber 803 'Store build number is retained'
$badVersionRejected = $false
try { [ShinobiZero.Core.BuildIdentityResolver]::Resolve('1.2.beta', '1') | Out-Null } catch [System.FormatException] { $badVersionRejected = $true }
Assert-Equal $badVersionRejected $true 'Invalid store version is rejected before build'
$badBuildRejected = $false
try { [ShinobiZero.Core.BuildIdentityResolver]::Resolve('1.2.3', '0') | Out-Null } catch [System.FormatException] { $badBuildRejected = $true }
Assert-Equal $badBuildRejected $true 'Non-positive store build number is rejected'

$standardShurikenSpin = [ShinobiZero.Core.ShurikenFlightModel]::Spin(1440, 0)
Assert-Close $standardShurikenSpin.RadiansPerSecond (8 * [Math]::PI) 0.001 'Standard shuriken spins four revolutions per second'
Assert-Equal ($standardShurikenSpin.RequiredAngularLimit -gt [Math]::Abs($standardShurikenSpin.RadiansPerSecond)) $true 'Angular limit exceeds standard requested spin'
$boostedShurikenSpin = [ShinobiZero.Core.ShurikenFlightModel]::Spin(1440, 360)
Assert-Equal ($boostedShurikenSpin.RequiredAngularLimit -gt [Math]::Abs($boostedShurikenSpin.RadiansPerSecond)) $true 'Angular limit expands for spin bias'
$reverseShurikenSpin = [ShinobiZero.Core.ShurikenFlightModel]::Spin(-1440, 0)
Assert-Equal ($reverseShurikenSpin.RequiredAngularLimit -gt [Math]::Abs($reverseShurikenSpin.RadiansPerSecond)) $true 'Angular limit supports reverse spin'
Assert-Equal ([ShinobiZero.Core.MatchOrder]::Opponent([ShinobiZero.Core.Combatant]::Enemy)) ([ShinobiZero.Core.Combatant]::Player) 'Completed match rotates enemy starter'
$enemyStartMatch.Submit([ShinobiZero.Core.DartHit]::Miss) | Out-Null
$enemyStartMatch.Submit([ShinobiZero.Core.DartHit]::Miss) | Out-Null
$enemyStartMatch.Submit([ShinobiZero.Core.DartHit]::Miss) | Out-Null
Assert-Equal $enemyStartMatch.Turn ([ShinobiZero.Core.Combatant]::Player) 'Enemy opening turn passes to player after three throws'

$match = [ShinobiZero.Core.MatchEngine]::new()
$rejected = $false
try { $match.Submit([ShinobiZero.Core.DartHit]::Miss) | Out-Null } catch [System.InvalidOperationException] { $rejected = $true }
Assert-Equal $rejected $true 'Throw before match start is rejected'
$match.Start([ShinobiZero.Core.MatchConfig]::new(301, $false))
$match.Submit([ShinobiZero.Core.DartHit]::Miss) | Out-Null
$match.Submit([ShinobiZero.Core.DartHit]::Miss) | Out-Null
$match.Submit([ShinobiZero.Core.DartHit]::Miss) | Out-Null
Assert-Equal $match.Turn ([ShinobiZero.Core.Combatant]::Enemy) 'Three throws pass turn'
Assert-Equal $match.DartsLeft 3 'New turn starts with three darts'

function Complete-SeriesLeg($seriesMatch) {
    $seriesMatch.Submit([ShinobiZero.Core.DartHit]::new(20, 3)) | Out-Null
    $seriesMatch.Submit([ShinobiZero.Core.DartHit]::new(20, 3)) | Out-Null
    $seriesMatch.Submit([ShinobiZero.Core.DartHit]::new(20, 3)) | Out-Null
    $seriesMatch.Submit([ShinobiZero.Core.DartHit]::Miss) | Out-Null
    $seriesMatch.Submit([ShinobiZero.Core.DartHit]::Miss) | Out-Null
    $seriesMatch.Submit([ShinobiZero.Core.DartHit]::Miss) | Out-Null
    $seriesMatch.Submit([ShinobiZero.Core.DartHit]::new(20, 3)) | Out-Null
    $seriesMatch.Submit([ShinobiZero.Core.DartHit]::new(20, 3)) | Out-Null
    return $seriesMatch.Submit([ShinobiZero.Core.DartHit]::new(1, 1))
}
$series = [ShinobiZero.Core.MatchEngine]::new()
$series.Start([ShinobiZero.Core.MatchConfig]::new(301, $false, 2))
$firstLeg = Complete-SeriesLeg $series
Assert-Equal $firstLeg.LegEnded $true 'First checkout ends leg'
Assert-Equal $firstLeg.MatchEnded $false 'First leg does not end best of three'
Assert-Equal $series.PlayerLegs 1 'Player leads by one leg'
Assert-Equal $series.Turn ([ShinobiZero.Core.Combatant]::Enemy) 'Second leg starter alternates'
$secondLeg = Complete-SeriesLeg $series
Assert-Equal $series.EnemyLegs 1 'Enemy can level series'
Assert-Equal $series.Turn ([ShinobiZero.Core.Combatant]::Player) 'Deciding leg returns starter to player'
$decider = Complete-SeriesLeg $series
Assert-Equal $decider.MatchEnded $true 'Second leg win ends best of three'
Assert-Equal $series.LegNumber 3 'Best of three ends on third leg'

$brain = [ShinobiZero.Core.OpponentBrain]::new()
$aimForty = $brain.Choose(40, $true, 0.8, 20)
Assert-Equal $aimForty.Base 20 'AI aims twenty at forty'
Assert-Equal $aimForty.Multiplier 2 'AI chooses double for checkout'
$aggressive = $brain.Choose(301, $false, 0.5, 20, 0.8)
Assert-Equal $aggressive.Multiplier 3 'Aggressive fighter chooses triples'
$cautious = $brain.Choose(301, $false, 0.5, 20, 0.2)
Assert-Equal $cautious.Multiplier 1 'Cautious fighter chooses singles'
$safeStrategy = $brain.Choose(301, $false, 0.5, 20, 0.5, 3, [ShinobiZero.Core.OpponentStrategy]::Conservative)
$attackStrategy = $brain.Choose(301, $false, 0.5, 20, 0.5, 3, [ShinobiZero.Core.OpponentStrategy]::Aggressive)
$checkoutStrategy = $brain.Choose(104, $true, 0.55, 20, 0.5, 3, [ShinobiZero.Core.OpponentStrategy]::CheckoutSpecialist)
Assert-Equal $safeStrategy.Multiplier 1 'Conservative strategy protects scoring floor'
Assert-Equal $attackStrategy.Multiplier 3 'Aggressive strategy attacks triples'
Assert-Equal $checkoutStrategy.Base 18 'Checkout specialist sees 104 route early'
for ($oddRemainder = 3; $oddRemainder -lt 40; $oddRemainder += 2) {
    $safeOddAim = $brain.Choose($oddRemainder, $true, 0.2, 20)
    $safeOddLeave = $oddRemainder - ($safeOddAim.Base * $safeOddAim.Multiplier)
    Assert-Equal $safeOddAim.Multiplier 1 "Low-skill AI uses a single setup from $oddRemainder"
    Assert-Equal ($safeOddLeave -gt 0) $true "Odd setup from $oddRemainder avoids zero bust"
    Assert-Equal ($safeOddLeave % 2) 0 "Odd setup from $oddRemainder leaves an even finish"
}
Assert-Equal ($brain.Choose(39, $true, 0.2, 20).Base) 7 'AI leaves D16 from thirty-nine'
Assert-Equal ($brain.Choose(31, $true, 0.2, 20).Base) 1 'AI makes odd low remainder even with single one'
$strategyNames = @()
for ($strategyIndex = 0; $strategyIndex -lt [ShinobiZero.Core.OpponentTuningCatalog]::Count; $strategyIndex++) {
    $tuningStrategy = [ShinobiZero.Core.OpponentTuningCatalog]::Get($strategyIndex).Strategy
    $strategyNames += [ShinobiZero.Core.OpponentStrategyNames]::Japanese($tuningStrategy)
}
Assert-Equal (($strategyNames | Select-Object -Unique).Count) 5 'Five enemies expose distinct tactical identities'

$noviceSpread = [ShinobiZero.Core.OpponentAccuracyModel]::Sigma(0.3, 0.7, 0.7, $false, 3)
$masterSpread = [ShinobiZero.Core.OpponentAccuracyModel]::Sigma(0.9, 0.7, 0.7, $false, 3)
Assert-Equal ($masterSpread -lt $noviceSpread) $true 'Higher skill tightens aim distribution'
$nervousSpread = [ShinobiZero.Core.OpponentAccuracyModel]::Sigma(0.7, 0.7, 0.1, $true, 3)
$calmSpread = [ShinobiZero.Core.OpponentAccuracyModel]::Sigma(0.7, 0.7, 0.95, $true, 3)
Assert-Equal ($calmSpread -lt $nervousSpread) $true 'Pressure resistance preserves checkout accuracy'
$earlySpread = [ShinobiZero.Core.OpponentAccuracyModel]::Sigma(0.6, 0.1, 0.5, $false, 3)
$lateSpread = [ShinobiZero.Core.OpponentAccuracyModel]::Sigma(0.6, 0.1, 0.5, $false, 1)
Assert-Equal ($lateSpread -gt $earlySpread) $true 'Low consistency fades across a turn'
$sampleA = [ShinobiZero.Core.OpponentAccuracyModel]::Sample(0.1, 0.02, 0.5, 0.25)
$sampleB = [ShinobiZero.Core.OpponentAccuracyModel]::Sample(0.1, 0.02, 0.5, 0.25)
Assert-Close $sampleA.X $sampleB.X 0.000001 'Accuracy sample X is deterministic'
Assert-Close $sampleA.Y $sampleB.Y 0.000001 'Accuracy sample Y is deterministic'

$career = [ShinobiZero.Core.CareerStats]::new()
$tracker = [ShinobiZero.Core.CareerTracker]::new($career)
$tracker.BeginMatch(2, 5)
$tracker.RecordPlayerThrow([ShinobiZero.Core.DartHit]::new(20, 3), $false, $false, $false, $false)
$tracker.RecordPlayerThrow([ShinobiZero.Core.DartHit]::new(20, 2), $false, $true, $true, $true)
Assert-Equal $career.Matches 1 'Career records completed match'
Assert-Equal $career.Wins 1 'Career records win'
Assert-Equal $career.OpponentWins[2] 1 'Career records opponent-specific win'
Assert-Equal $career.BestCheckout 100 'Career records checkout total'
$lossTracker = [ShinobiZero.Core.CareerTracker]::new($career)
$lossTracker.BeginMatch(4, 5)
$lossTracker.RecordEnemyWin()
Assert-Equal $career.Losses 1 'Career records loss'

$tutorial = [ShinobiZero.Core.TutorialFlow]::new()
Assert-Equal $tutorial.Page ([ShinobiZero.Core.TutorialPage]::Throwing) 'Tutorial begins with throwing'
$tutorial.Next() | Out-Null
Assert-Equal $tutorial.Page ([ShinobiZero.Core.TutorialPage]::Scoring) 'Tutorial advances to scoring'
$tutorial.Next() | Out-Null
$tutorial.Next() | Out-Null
Assert-Equal $tutorial.IsComplete $true 'Tutorial completes after three advances'
$tutorial.Restart()
Assert-Equal $tutorial.PageNumber 1 'Tutorial can restart'

$defaultPreferences = [ShinobiZero.Core.PreferencesCodec]::Decode(0)
Assert-Equal $defaultPreferences.SoundEnabled $true 'Sound defaults on'
Assert-Equal $defaultPreferences.HapticsEnabled $true 'Haptics default on'
Assert-Equal $defaultPreferences.ReducedMotion $false 'Reduced motion defaults off'
Assert-Equal $defaultPreferences.Fullscreen $true 'Desktop defaults to borderless fullscreen'
$customPreferences = [ShinobiZero.Core.GamePreferences]::new($false, $true, $true)
$decodedPreferences = [ShinobiZero.Core.PreferencesCodec]::Decode([ShinobiZero.Core.PreferencesCodec]::Encode($customPreferences))
Assert-Equal $decodedPreferences.SoundEnabled $false 'Sound preference round trips'
Assert-Equal $decodedPreferences.HapticsEnabled $true 'Haptics preference round trips'
Assert-Equal $decodedPreferences.ReducedMotion $true 'Motion preference round trips'
$volumePreferences = [ShinobiZero.Core.GamePreferences]::new($true, $true, $false, $false, $true, 6)
$decodedVolume = [ShinobiZero.Core.PreferencesCodec]::Decode([ShinobiZero.Core.PreferencesCodec]::Encode($volumePreferences))
Assert-Equal $decodedVolume.VolumeStep 6 'Master volume survives save round trip'
Assert-Equal ([ShinobiZero.Core.PreferencesCodec]::Decode(0).VolumeStep) 8 'New players start at safe volume'
Assert-Equal ([ShinobiZero.Core.PreferencesCodec]::Decode(512 + 1 + 2 + 16).VolumeStep) 10 'Previous settings retain former full volume'
Assert-Equal ([ShinobiZero.Core.GamePreferences]::new($true, $true, $false, $false, $true, 99).VolumeStep) 10 'Master volume clamps to ten steps'
$aimPreferences = [ShinobiZero.Core.GamePreferences]::new($true, $true, $false, $false, $true, 8, 8)
$decodedAim = [ShinobiZero.Core.PreferencesCodec]::Decode([ShinobiZero.Core.PreferencesCodec]::Encode($aimPreferences))
Assert-Equal $decodedAim.AimSensitivityStep 8 'Aim sensitivity survives save round trip'
Assert-Close $decodedAim.AimSensitivityMultiplier 1.3 0.0001 'Aim sensitivity maps to a stable multiplier'
Assert-Equal ([ShinobiZero.Core.PreferencesCodec]::Decode(1024 + 1 + 16 + (7 * 2048)).AimSensitivityStep) 5 'Volume-era settings migrate to standard aim sensitivity'
Assert-Equal ([ShinobiZero.Core.GamePreferences]::new($true, $true, $false, $false, $true, 8, 99).AimSensitivityStep) 10 'Aim sensitivity clamps to ten steps'

$endurance = [ShinobiZero.Core.MatchEnduranceSimulator]::Run(3200, 23063)
Assert-Equal $endurance.Matches 3200 'Endurance simulation completes every configured match'
Assert-Equal ($endurance.Throws -gt 9600) $true 'Endurance simulation exercises many throws'
Assert-Equal ($endurance.Legs -ge 3200) $true 'Endurance simulation completes every leg'
Assert-Equal ($endurance.Busts -gt 0) $true 'Endurance simulation exercises bust recovery'
Assert-Equal ($endurance.MaximumThrowsInMatch -lt 600) $true 'Every endurance match terminates within guard'

$ballistic = [ShinobiZero.Core.BallisticSolver]::SolveLowArc(0, 0, 0, 0, 2, 10, 16, 9.81)
Assert-Equal $ballistic.Reachable $true 'Nearby board is ballistically reachable'
$flightTime = $ballistic.FlightTime
$arrivalY = $ballistic.VelocityY * $flightTime - 0.5 * 9.81 * $flightTime * $flightTime
$arrivalZ = $ballistic.VelocityZ * $flightTime
Assert-Close $arrivalY 2 0.001 'Ballistic arc reaches requested height'
Assert-Close $arrivalZ 10 0.001 'Ballistic arc reaches requested distance'
$launchMagnitude = [Math]::Sqrt($ballistic.VelocityX * $ballistic.VelocityX + $ballistic.VelocityY * $ballistic.VelocityY + $ballistic.VelocityZ * $ballistic.VelocityZ)
Assert-Close $launchMagnitude 16 0.001 'Ballistic arc preserves launch speed'
$unreachable = [ShinobiZero.Core.BallisticSolver]::SolveLowArc(0, 0, 0, 0, 100, 100, 1, 9.81)
Assert-Equal $unreachable.Reachable $false 'Impossible ballistic target is rejected'

$motionStart = [ShinobiZero.Core.ThrowMotionModel]::Evaluate(0, 0.6, 50, 70)
Assert-Close $motionStart.Shoulder 0 0.001 'Throw motion starts at rest'
$motionWindup = [ShinobiZero.Core.ThrowMotionModel]::Evaluate(0.5999, 0.6, 50, 70)
Assert-Close $motionWindup.Shoulder -50 0.01 'Throw motion reaches windup before release'
$motionFinish = [ShinobiZero.Core.ThrowMotionModel]::Evaluate(1, 0.6, 50, 70)
Assert-Close $motionFinish.Shoulder 70 0.001 'Throw motion reaches follow through'
Assert-Equal ([ShinobiZero.Core.ThrowMotionModel]::CrossedRelease(0.59, 0.61, 0.6)) $true 'Throw releases when threshold is crossed'

$centerAim = [ShinobiZero.Core.ScreenAimModel]::Map(500, 900, 500, 900, 300, 1.25)
Assert-Close $centerAim.X 0 0.0001 'Screen center aims board center X'
Assert-Close $centerAim.Y 0 0.0001 'Screen center aims board center Y'
$ringAim = [ShinobiZero.Core.ScreenAimModel]::Map(800, 900, 500, 900, 300, 1.25)
Assert-Close $ringAim.X 1 0.0001 'Projected board edge maps to unit radius'
$clampedAim = [ShinobiZero.Core.ScreenAimModel]::Map(1100, 1500, 500, 900, 300, 1.25)
$clampedLength = [Math]::Sqrt($clampedAim.X * $clampedAim.X + $clampedAim.Y * $clampedAim.Y)
Assert-Close $clampedLength 1.25 0.0001 'Aim outside board is directionally clamped'

$achievementStats = [ShinobiZero.Core.CareerStats]::new()
Assert-Equal ([ShinobiZero.Core.AchievementCatalog]::Evaluate($achievementStats).Length) 0 'Empty career unlocks no achievements'
$achievementStats.Wins = 10
$achievementStats.BestCheckout = 100
$achievementStats.BestTurn = 180
$achievementStats.Bulls = 25
$achievementStats.OpponentWins = [int[]]@(1, 1, 1, 1, 1)
$achievementIds = [ShinobiZero.Core.AchievementCatalog]::Evaluate($achievementStats)
Assert-Equal ($achievementIds -contains [ShinobiZero.Core.AchievementCatalog]::FirstVictory) $true 'First victory achievement unlocks'
Assert-Equal ($achievementIds -contains [ShinobiZero.Core.AchievementCatalog]::CenturyCheckout) $true 'Century checkout achievement unlocks'
Assert-Equal ($achievementIds -contains [ShinobiZero.Core.AchievementCatalog]::MaximumTurn) $true 'Maximum turn achievement unlocks'
Assert-Equal ($achievementIds -contains [ShinobiZero.Core.AchievementCatalog]::FiveShadows) $true 'Five opponent achievement unlocks'

$performanceTracker = [ShinobiZero.Core.MatchPerformanceTracker]::new()
$performanceTracker.Record([ShinobiZero.Core.DartHit]::new(20, 3), $false, $false, $false)
$performanceTracker.Record([ShinobiZero.Core.DartHit]::new(20, 3), $false, $false, $false)
$performanceTracker.Record([ShinobiZero.Core.DartHit]::new(20, 3), $false, $true, $false)
Assert-Close $performanceTracker.Performance.ThreeDartAverage 180 0.001 'Performance calculates three dart average'
Assert-Equal $performanceTracker.Performance.BestTurn 180 'Performance records best turn'
$performanceTracker.Reset()
$performanceTracker.Record([ShinobiZero.Core.DartHit]::new(20, 3), $false, $false, $false)
$performanceTracker.Record([ShinobiZero.Core.DartHit]::new(20, 3), $true, $true, $false)
Assert-Equal $performanceTracker.Performance.CountedScore 0 'Bust contributes no counted score'
Assert-Close $performanceTracker.Performance.HitRate 1 0.001 'Bust still counts physical hit rate'
$performanceTracker.Reset()
$performanceTracker.Record([ShinobiZero.Core.DartHit]::new(20, 3), $false, $false, $false)
$performanceTracker.Record([ShinobiZero.Core.DartHit]::new(20, 2), $false, $true, $true)
Assert-Equal $performanceTracker.Performance.BestCheckout 100 'Performance records checkout turn'

Assert-Equal ([ShinobiZero.Core.ThrowInputModel]::Validate(-0.1, 0.3, 0.08, 0.18, 1.4)) ([ShinobiZero.Core.ThrowRejectionReason]::WrongDirection) 'Downward throw reports direction'
Assert-Equal ([ShinobiZero.Core.ThrowInputModel]::Validate(0.04, 0.1, 0.08, 0.18, 1.4)) ([ShinobiZero.Core.ThrowRejectionReason]::TooShort) 'Small throw reports distance'
Assert-Equal ([ShinobiZero.Core.ThrowInputModel]::Validate(0.1, 1, 0.08, 0.18, 1.4)) ([ShinobiZero.Core.ThrowRejectionReason]::TooSlow) 'Slow throw reports speed'
Assert-Equal ([ShinobiZero.Core.ThrowInputModel]::Validate(0.3, 1.5, 0.08, 0.18, 1.4)) ([ShinobiZero.Core.ThrowRejectionReason]::TooLong) 'Held throw reports duration'
Assert-Equal ([ShinobiZero.Core.ThrowInputModel]::Validate(0.2, 0.35, 0.08, 0.18, 1.4)) ([ShinobiZero.Core.ThrowRejectionReason]::None) 'Deliberate flick validates'

$previousExpectedScore = 0
for ($opponentIndex = 0; $opponentIndex -lt [ShinobiZero.Core.OpponentTuningCatalog]::Count; $opponentIndex++) {
    $tuning = [ShinobiZero.Core.OpponentTuningCatalog]::Get($opponentIndex)
    $expectedScore = [ShinobiZero.Core.OpponentBalanceSimulator]::ExpectedThreeDartScore($tuning, 20000, 1977)
    Assert-Equal ($expectedScore -gt ($previousExpectedScore + 1)) $true "Opponent $opponentIndex has measurably higher expected score"
    $previousExpectedScore = $expectedScore
}
$simulationA = [ShinobiZero.Core.OpponentBalanceSimulator]::ExpectedThreeDartScore([ShinobiZero.Core.OpponentTuningCatalog]::Get(4), 5000, 42)
$simulationB = [ShinobiZero.Core.OpponentBalanceSimulator]::ExpectedThreeDartScore([ShinobiZero.Core.OpponentTuningCatalog]::Get(4), 5000, 42)
Assert-Close $simulationA $simulationB 0.000001 'Opponent balance simulation is deterministic'

$abortedMatch = [ShinobiZero.Core.MatchEngine]::new()
$abortedMatch.Start([ShinobiZero.Core.MatchConfig]::new(301, $true))
Assert-Equal ($abortedMatch.Abort()) $true 'Active match can be aborted'
Assert-Equal $abortedMatch.IsFinished $true 'Aborted match is closed'
Assert-Equal $abortedMatch.Winner $null 'Aborted match has no winner'
Assert-Equal ($abortedMatch.Abort()) $false 'Closed match cannot be aborted twice'
$abortStats = [ShinobiZero.Core.CareerStats]::new()
$abortTracker = [ShinobiZero.Core.CareerTracker]::new($abortStats)
$abortTracker.BeginMatch(0, 5)
$abortTracker.AbortMatch()
Assert-Equal $abortStats.Matches 0 'Abort does not add career match'

Assert-Equal ([ShinobiZero.Core.ButtonThrowModel]::Map(0, 0, 0.01, 0).Valid) $false 'Short button hold is rejected'
Assert-Equal ([ShinobiZero.Core.ButtonThrowModel]::Map(0, 0, 1.5, 0).Valid) $false 'Long button hold is rejected'
$idealButtonThrow = [ShinobiZero.Core.ButtonThrowModel]::Map(0.3, -0.2, 0.48, 0)
Assert-Equal $idealButtonThrow.Valid $true 'Ideal button hold is valid'
Assert-Close $idealButtonThrow.BoardY -0.2 0.0001 'Ideal button hold preserves vertical aim'
Assert-Close $idealButtonThrow.Power 1 0.0001 'Ideal button hold reaches full power'
Assert-Close ([ShinobiZero.Core.ButtonThrowModel]::Map(0, 0, 0.48, 1).Spin) 24 0.0001 'Right stick controls button throw spin'

$missingCheckouts = @()
$allCheckoutRoutesValid = $true
for ($checkoutScore = 2; $checkoutScore -le 170; $checkoutScore++) {
    $route = [ShinobiZero.Core.CheckoutAdvisor]::Find($checkoutScore, 3, $true)
    if (-not $route.IsPossible) { $missingCheckouts += $checkoutScore; continue }
    $routeTotal = 0
    foreach ($routeHit in $route.Hits) { $routeTotal += $routeHit.Score }
    if ($routeTotal -ne $checkoutScore -or -not $route.Hits[$route.Hits.Length - 1].IsDouble) { $allCheckoutRoutesValid = $false }
}
Assert-Equal ($missingCheckouts -join ',') '159,162,163,165,166,168,169' 'Only official bogey numbers lack checkout'
Assert-Equal $allCheckoutRoutesValid $true 'Every checkout route totals correctly and ends on double'

$finishForty = [ShinobiZero.Core.CheckoutAdvisor]::Find(40, 1, $true)
Assert-Equal ([ShinobiZero.Core.CheckoutAdvisor]::Format($finishForty)) 'D20' 'Forty finishes on double twenty'
$finishBull = [ShinobiZero.Core.CheckoutAdvisor]::Find(50, 1, $true)
Assert-Equal ([ShinobiZero.Core.CheckoutAdvisor]::Format($finishBull)) 'BULL' 'Fifty finishes on bull'
$finishHundred = [ShinobiZero.Core.CheckoutAdvisor]::Find(100, 2, $true)
Assert-Equal $finishHundred.Hits.Length 2 'Hundred uses two darts'
Assert-Equal $finishHundred.Hits[0].Score 60 'Hundred opens on triple twenty'
Assert-Equal $finishHundred.Hits[1].Score 40 'Hundred closes on double twenty'
$finishMaximum = [ShinobiZero.Core.CheckoutAdvisor]::Find(170, 3, $true)
Assert-Equal $finishMaximum.Hits.Length 3 'Maximum checkout uses three darts'
Assert-Equal $finishMaximum.Hits[0].Score 60 'Maximum checkout first dart'
Assert-Equal $finishMaximum.Hits[1].Score 60 'Maximum checkout second dart'
Assert-Equal $finishMaximum.Hits[2].Score 50 'Maximum checkout closes on bull'
Assert-Equal ([ShinobiZero.Core.CheckoutAdvisor]::Find(169, 3, $true).IsPossible) $false 'Bogey number has no checkout'
$straightSixty = [ShinobiZero.Core.CheckoutAdvisor]::Find(60, 1, $false)
Assert-Equal ([ShinobiZero.Core.CheckoutAdvisor]::Format($straightSixty)) 'T20' 'Straight out allows triple twenty'

$idealThrow = [ShinobiZero.Core.ThrowInputModel]::Map(0, 0.34, 0.35, 0.1, -0.1, 0.34, 1, 1.1, 45)
Assert-Close $idealThrow.BoardX 0.1 0.0001 'Ideal throw keeps aim X'
Assert-Close $idealThrow.BoardY -0.1 0.0001 'Ideal rise keeps aim Y'
Assert-Equal ([ShinobiZero.Core.ThrowInputModel]::IsValid(0.1, 1.2, 0.08, 0.18, 1.4)) $false 'Slow drag is rejected'
Assert-Equal ([ShinobiZero.Core.ThrowInputModel]::IsValid(0.2, 0.35, 0.08, 0.18, 1.4)) $true 'Deliberate flick is accepted'
$sideThrow = [ShinobiZero.Core.ThrowInputModel]::Map(0.12, 0.34, 0.3, 0, 0, 0.34, 1, 1.1, 45)
Assert-Equal ($sideThrow.Spin -gt 0) $true 'Horizontal movement creates spin'

$calibrated = [ShinobiZero.Core.ThrowCalibrationModel]::ComputeIdeal([float[]]@(0.34, 0.35, 0.9))
Assert-Close $calibrated 0.35 0.0001 'Calibration uses median'
$shortCalibration = [ShinobiZero.Core.ThrowCalibrationModel]::ComputeIdeal([float[]]@(0.1, 0.12, 0.14))
Assert-Close $shortCalibration 0.22 0.0001 'Calibration clamps short motion'
$longCalibration = [ShinobiZero.Core.ThrowCalibrationModel]::ComputeIdeal([float[]]@(0.6, 0.7, 0.8))
Assert-Close $longCalibration 0.48 0.0001 'Calibration clamps long motion'
$calibrationRejected = $false
try { [ShinobiZero.Core.ThrowCalibrationModel]::ComputeIdeal([float[]]@(0.3, 0.35)) | Out-Null } catch [System.ArgumentException] { $calibrationRejected = $true }
Assert-Equal $calibrationRejected $true 'Calibration requires three throws'

$touchGuideEn = [ShinobiZero.Core.TutorialThrowGuide]::Text([ShinobiZero.Core.TutorialInputMode]::Touch, [ShinobiZero.Core.GameLanguage]::English)
$gamepadGuideEn = [ShinobiZero.Core.TutorialThrowGuide]::Text([ShinobiZero.Core.TutorialInputMode]::Gamepad, [ShinobiZero.Core.GameLanguage]::English)
$keyboardGuideEn = [ShinobiZero.Core.TutorialThrowGuide]::Text([ShinobiZero.Core.TutorialInputMode]::KeyboardMouse, [ShinobiZero.Core.GameLanguage]::English)
Assert-Equal ($touchGuideEn.Contains('finger')) $true 'Touch tutorial explains the swipe gesture'
Assert-Equal ($gamepadGuideEn.Contains('left stick')) $true 'Gamepad tutorial explains aiming'
Assert-Equal ($gamepadGuideEn.Contains('RT')) $true 'Gamepad tutorial explains throw charging'
Assert-Equal ($gamepadGuideEn.Contains('right stick')) $true 'Gamepad tutorial explains spin'
Assert-Equal ($keyboardGuideEn.Contains('WASD')) $true 'Keyboard tutorial explains aiming'
Assert-Equal ($keyboardGuideEn.Contains('F')) $true 'Keyboard tutorial explains throw charging'
$touchPromptEn = [ShinobiZero.Core.ThrowPromptCatalog]::Text([ShinobiZero.Core.TutorialInputMode]::Touch, [ShinobiZero.Core.GameLanguage]::English)
$gamepadPromptEn = [ShinobiZero.Core.ThrowPromptCatalog]::Text([ShinobiZero.Core.TutorialInputMode]::Gamepad, [ShinobiZero.Core.GameLanguage]::English)
$keyboardPromptEn = [ShinobiZero.Core.ThrowPromptCatalog]::Text([ShinobiZero.Core.TutorialInputMode]::KeyboardMouse, [ShinobiZero.Core.GameLanguage]::English)
Assert-Equal ($touchPromptEn.Contains('SWIPE')) $true 'Match touch prompt explains swipe input'
Assert-Equal ($gamepadPromptEn.Contains('LEFT STICK')) $true 'Match gamepad prompt explains aiming'
Assert-Equal ($gamepadPromptEn.Contains('RT')) $true 'Match gamepad prompt explains release input'
Assert-Equal ($keyboardPromptEn.Contains('WASD')) $true 'Match keyboard prompt explains aiming'
Assert-Equal ($keyboardPromptEn.Contains('F')) $true 'Match keyboard prompt explains release input'
Assert-Equal ($touchPromptEn -ne $gamepadPromptEn) $true 'Match prompt changes with active device'

for ($difficultyIndex = 0; $difficultyIndex -lt [ShinobiZero.Core.OpponentTuningCatalog]::Count; $difficultyIndex++) {
    $difficultyTuning = [ShinobiZero.Core.OpponentTuningCatalog]::Get($difficultyIndex)
    Assert-Equal ([ShinobiZero.Core.OpponentDifficultyModel]::Level($difficultyTuning.Skill)) ($difficultyIndex + 1) "Opponent $difficultyIndex has distinct visible difficulty"
}
Assert-Equal ([ShinobiZero.Core.OpponentDifficultyModel]::Level(-1)) 1 'Difficulty clamps skill below range'
Assert-Equal ([ShinobiZero.Core.OpponentDifficultyModel]::Level(2)) 5 'Difficulty clamps skill above range'
Assert-Equal ([ShinobiZero.Core.OpponentDifficultyModel]::Stars(0.62).Length) 5 'Difficulty always renders five stars'

$softImpact = [ShinobiZero.Core.ImpactSettleModel]::Amplitude(4, 8)
$hardImpact = [ShinobiZero.Core.ImpactSettleModel]::Amplitude(12, 8)
Assert-Equal ($hardImpact -gt $softImpact) $true 'Hard impact produces stronger embedded wobble'
Assert-Close ([ShinobiZero.Core.ImpactSettleModel]::Amplitude(100, 8)) 8 0.0001 'Impact wobble respects authored cap'
Assert-Close ([ShinobiZero.Core.ImpactSettleModel]::Angle(0, 8)) 0 0.0001 'Embedded wobble starts from scored contact pose'
Assert-Close ([ShinobiZero.Core.ImpactSettleModel]::Angle(1, 8)) 0 0.0001 'Embedded wobble settles to scored contact pose'

Write-Output "SHINOBI ZERO C# core: $checks checks passed"
