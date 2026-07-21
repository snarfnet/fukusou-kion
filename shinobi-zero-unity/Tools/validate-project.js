const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const required = [
  'Packages/manifest.json',
  'ProjectSettings/ProjectVersion.txt',
  'Assets/ShinobiZero/Core/DartsRules.cs',
  'Assets/ShinobiZero/Core/DartboardGeometry.cs',
  'Assets/ShinobiZero/Core/MatchEngine.cs',
  'Assets/ShinobiZero/Core/OpponentBrain.cs',
  'Assets/ShinobiZero/Core/CheckoutAdvisor.cs',
  'Assets/ShinobiZero/Core/OpponentAccuracyModel.cs',
  'Assets/ShinobiZero/Core/OpponentDifficultyModel.cs',
  'Assets/ShinobiZero/Core/CareerStats.cs',
  'Assets/ShinobiZero/Core/TutorialFlow.cs',
  'Assets/ShinobiZero/Core/TutorialThrowGuide.cs',
  'Assets/ShinobiZero/Core/GamePreferences.cs',
  'Assets/ShinobiZero/Core/BallisticSolver.cs',
  'Assets/ShinobiZero/Core/ThrowMotionModel.cs',
  'Assets/ShinobiZero/Core/ScreenAimModel.cs',
  'Assets/ShinobiZero/Core/AchievementCatalog.cs',
  'Assets/ShinobiZero/Core/PlatformProgress.cs',
  'Assets/ShinobiZero/Core/ImpactFeedbackModel.cs',
  'Assets/ShinobiZero/Core/ImpactSettleModel.cs',
  'Assets/ShinobiZero/Core/PlayerThrowMotionModel.cs',
  'Assets/ShinobiZero/Core/ResponsiveLayoutModel.cs',
  'Assets/ShinobiZero/Core/UiFocusModel.cs',
  'Assets/ShinobiZero/Core/LocalizationCatalog.cs',
  'Assets/ShinobiZero/Core/TurnHistoryTracker.cs',
  'Assets/ShinobiZero/Core/ApplicationLifecycleModel.cs',
  'Assets/ShinobiZero/Core/NinjaReactionModel.cs',
  'Assets/ShinobiZero/Core/HapticPulseModel.cs',
  'Assets/ShinobiZero/Core/PerformanceGovernor.cs',
  'Assets/ShinobiZero/Core/CareerRankModel.cs',
  'Assets/ShinobiZero/Core/MatchPerformance.cs',
  'Assets/ShinobiZero/Core/TitleMotionModel.cs',
  'Assets/ShinobiZero/Core/BuildIdentity.cs',
  'Assets/ShinobiZero/Core/ShurikenFlightModel.cs',
  'Assets/ShinobiZero/Core/ScreenWakePolicy.cs',
  'Assets/ShinobiZero/Core/OpponentTuningCatalog.cs',
  'Assets/ShinobiZero/Core/ButtonThrowModel.cs',
  'Assets/ShinobiZero/Core/ThrowInputModel.cs',
  'Assets/ShinobiZero/Core/ThrowPromptCatalog.cs',
  'Assets/ShinobiZero/Core/ThrowCalibrationModel.cs',
  'Assets/ShinobiZero/Core/ThrowReleaseGate.cs',
  'Assets/ShinobiZero/Runtime/ThrowGestureReader.cs',
  'Assets/ShinobiZero/Runtime/InputModeDetector.cs',
  'Assets/ShinobiZero/Runtime/ShurikenProjectile.cs',
  'Assets/ShinobiZero/Runtime/EnemyTurnDirector.cs',
  'Assets/ShinobiZero/Runtime/NinjaThrowAnimator.cs',
  'Assets/ShinobiZero/Runtime/GameFlowController.cs',
  'Assets/ShinobiZero/Runtime/GameHudController.cs',
  'Assets/ShinobiZero/Runtime/SafeAreaFitter.cs',
  'Assets/ShinobiZero/Runtime/HapticFeedback.cs',
  'Assets/ShinobiZero/Runtime/ThrowCalibrationController.cs',
  'Assets/ShinobiZero/Runtime/ThrowFeedbackController.cs',
  'Assets/ShinobiZero/Runtime/PlayerProgressController.cs',
  'Assets/ShinobiZero/Runtime/TutorialController.cs',
  'Assets/ShinobiZero/Runtime/SettingsController.cs',
  'Assets/ShinobiZero/Runtime/GamePauseController.cs',
  'Assets/ShinobiZero/Runtime/DesktopQuitController.cs',
  'Assets/ShinobiZero/Runtime/AimReticleController.cs',
  'Assets/ShinobiZero/Runtime/NinjaVisualController.cs',
  'Assets/ShinobiZero/Runtime/AchievementToastController.cs',
  'Assets/ShinobiZero/Runtime/AmbientAudioController.cs',
  'Assets/ShinobiZero/Runtime/AlternativeThrowController.cs',
  'Assets/ShinobiZero/Runtime/FirstPersonThrowAnimator.cs',
  'Assets/ShinobiZero/Runtime/ResponsiveHudLayout.cs',
  'Assets/ShinobiZero/Runtime/UiNavigationController.cs',
  'Assets/ShinobiZero/Runtime/UiLocalizationController.cs',
  'Assets/ShinobiZero/Runtime/NinjaReactionController.cs',
  'Assets/ShinobiZero/Runtime/GamepadRumbleDriver.cs',
  'Assets/ShinobiZero/Runtime/AdaptivePerformanceController.cs',
  'Assets/ShinobiZero/Runtime/TitleBackgroundController.cs',
  'Assets/ShinobiZero/Runtime/ActiveMatchSave.cs',
  'Assets/ShinobiZero/Runtime/ScreenWakeController.cs',
  'Assets/ShinobiZero/Tests/SceneAcceptance/ShinobiZero.SceneAcceptance.asmdef',
  'Assets/ShinobiZero/Tests/SceneAcceptance/GeneratedSceneAcceptanceTests.cs',
  'Assets/ShinobiZero/Tests/EditMode/TargetBoardTests.cs',
  'Assets/ShinobiZero/Tests/EditMode/ThrowReleaseGateTests.cs',
  'Assets/ShinobiZero/Tests/EditMode/ImpactSettleModelTests.cs',
  'Tools/run-unity-tests.ps1',
  'Assets/Plugins/iOS/ShinobiHaptics.mm',
  'Assets/Plugins/iOS/AppIcon.appiconset/Contents.json',
  'Assets/Plugins/iOS/AppIcon.appiconset/Icon-Marketing.png',
  'Assets/Plugins/iOS/PrivacyInfo.xcprivacy',
  'Docs/Privacy/PRIVACY_POLICY_JA.md',
  'Docs/Privacy/APP_STORE_PRIVACY_ANSWERS.md',
  'Assets/ShinobiZero/Runtime/PlatformServices.cs',
  'Assets/ShinobiZero/Tests/EditMode/PlatformServicesTests.cs',
  'Assets/ShinobiZero/Editor/PrototypeSceneBuilder.cs',
  'Assets/ShinobiZero/Editor/ProductBuildMenu.cs',
  'Assets/ShinobiZero/Editor/CiBuild.cs',
  'Docs/Art/opponents-lineup-v1.png',
  'Docs/Art/throw-motion-reference-v1.png',
  'Assets/ShinobiZero/Art/Title/title-background-v1.png',
  'Assets/ShinobiZero/Art/Title/title-background-landscape-v1.png',
  'Docs/Art/title-background-v1-prompt.md',
  'Docs/CHARACTER_BIBLE.md',
  'Docs/THROW_ANIMATION_SPEC.md',
  'Docs/STEAM_RELEASE.md'
];

const missing = required.filter(file => !fs.existsSync(path.join(root, file)));
if (missing.length) throw new Error(`Missing files:\n${missing.join('\n')}`);

const manifest = JSON.parse(fs.readFileSync(path.join(root, 'Packages/manifest.json'), 'utf8'));
for (const packageName of ['com.unity.inputsystem', 'com.unity.test-framework', 'com.unity.ugui']) {
  if (!manifest.dependencies[packageName]) throw new Error(`Missing package: ${packageName}`);
}

const version = fs.readFileSync(path.join(root, 'ProjectSettings/ProjectVersion.txt'), 'utf8');
if (!version.includes('6000.3')) throw new Error('Project must target Unity 6.3 LTS.');

const sourceFiles = [];
function collect(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const full = path.join(directory, entry.name);
    if (entry.isDirectory()) collect(full);
    else if (entry.name.endsWith('.cs')) sourceFiles.push(full);
  }
}
collect(path.join(root, 'Assets'));
const unfinished = sourceFiles.filter(file => /TODO|NotImplementedException/.test(fs.readFileSync(file, 'utf8')));
if (unfinished.length) throw new Error(`Unfinished source markers:\n${unfinished.join('\n')}`);

const buildMenu = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Editor/ProductBuildMenu.cs'), 'utf8');
for (const setting of ['UIOrientation.Portrait', 'targetOSVersionString = "15.0"', 'ScriptingImplementation.IL2CPP', 'GraphicsDeviceType.Metal', 'activeInputHandler', 'PlayerSettings.iOS.buildNumber']) {
  if (!buildMenu.includes(setting)) throw new Error(`Missing iOS build setting: ${setting}`);
}
for (const identityBehavior of ['SHINOBI_ZERO_VERSION', 'SHINOBI_ZERO_BUILD_NUMBER', 'BuildIdentityResolver.Resolve', 'WriteBuildManifest', 'build-manifest.json', 'Application.unityVersion', 'DateTime.UtcNow.ToString("O")']) {
  if (!buildMenu.includes(identityBehavior)) throw new Error(`Build is missing reproducible identity behavior: ${identityBehavior}`);
}
for (const desktopBuild of ['BuildTarget.StandaloneWindows64', 'BuildTarget.StandaloneOSX', 'BuildTarget.StandaloneLinux64']) {
  if (!buildMenu.includes(desktopBuild)) throw new Error(`Missing desktop store build target: ${desktopBuild}`);
}
const desktopPlatformServices = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/PlatformServices.cs'), 'utf8');
for (const cloudBehavior of ['career-cloud.json', 'File.WriteAllBytes(temporary, data)', 'File.Copy(_cloudPath, backup, true)', 'MaximumCloudBytes']) {
  if (!desktopPlatformServices.includes(cloudBehavior)) throw new Error(`Steam Auto Cloud save is incomplete: ${cloudBehavior}`);
}

const sceneBuilder = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Editor/PrototypeSceneBuilder.cs'), 'utf8');
for (const environmentDetail of ['Weathered Dojo Frame', 'Weathered Iron Lantern', 'Rain Puddles', 'FogMode.ExponentialSquared', 'fogDensity = .018f']) {
  if (!sceneBuilder.includes(environmentDetail)) throw new Error(`Realistic dojo environment is incomplete: ${environmentDetail}`);
}
for (const sourceBinding of ['FindProperty("playerReleasePoint")', 'FindProperty("enemyReleasePoint")', 'FindProperty("enemyThrowAnimator")', 'FindProperty("playerThrowAnimator")']) {
  if (!sceneBuilder.includes(sourceBinding)) throw new Error(`Generated scene misses thrower binding: ${sourceBinding}`);
}
const ninjaThrowAnimator = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/NinjaThrowAnimator.cs'), 'utf8');
for (const releaseBehavior of ['heldShuriken.SetActive(false)', 'heldShuriken.SetActive(true)', '_releaseGate.TryRelease()', '_releaseGate.Arm()']) {
  if (!ninjaThrowAnimator.includes(releaseBehavior)) throw new Error(`Enemy held shuriken release is incomplete: ${releaseBehavior}`);
}
const playerThrowAnimator = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/FirstPersonThrowAnimator.cs'), 'utf8');
for (const releaseBehavior of ['_releaseGate.Arm()', '_releaseGate.TryRelease()', '_releaseGate.Reset()']) {
  if (!playerThrowAnimator.includes(releaseBehavior)) throw new Error(`Player throw release is not single-fire: ${releaseBehavior}`);
}
for (const heldDetail of ['CreateHeldShuriken("Held Four Point Shuriken"', 'Raised Hub', 'Dark Finger Recess']) {
  if (!sceneBuilder.includes(heldDetail)) throw new Error(`First-person shuriken lacks forged detail: ${heldDetail}`);
}
for (const heldShurikenBinding of ['CreateHeldShuriken("Enemy Held Shuriken"', 'FindProperty("heldShuriken")']) {
  if (!sceneBuilder.includes(heldShurikenBinding)) throw new Error(`Generated ninja misses held shuriken: ${heldShurikenBinding}`);
}
for (const realisticBoard of ['Round Bound Straw Backing', 'Regulation Spider Wires', 'CreateDartboardWires(board)', 'FindProperty("scoringRadius").floatValue = 1f', 'const float localRadius = 1f']) {
  if (!sceneBuilder.includes(realisticBoard)) throw new Error(`Competition target still lacks production geometry: ${realisticBoard}`);
}
if (!sceneBuilder.includes('AddComponent<ResponsiveHudLayout>()')) throw new Error('Generated HUD is not adaptive for Steam landscape displays.');
const responsiveHud = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/ResponsiveHudLayout.cs'), 'utf8');
for (const deckBehavior of ['ResponsiveLayoutModel.LandscapeReferenceWidth', 'ResponsiveLayoutModel.LandscapeReferenceHeight', 'matchWidthOrHeight = .5f']) {
  if (!responsiveHud.includes(deckBehavior)) throw new Error(`Steam Deck HUD scaling is incomplete: ${deckBehavior}`);
}
if (!sceneBuilder.includes('"Opponent Detail", selection.transform, "", 22') || !sceneBuilder.includes('"Legs", match.transform, "LEG 1", 22'))
  throw new Error('Generated HUD contains text below the Steam Deck 18px physical minimum.');
if (!sceneBuilder.includes('text.resizeTextMinSize = Mathf.Min(22, size)'))
  throw new Error('Best-fit text can shrink below the Steam Deck physical minimum.');
if (!sceneBuilder.includes('AddComponent<UiNavigationController>()')) throw new Error('Generated HUD has no keyboard/gamepad focus controller.');
const uiNavigation = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/UiNavigationController.cs'), 'utf8');
for (const focusBehavior of ['flow.SelectedOpponent', 'opponentButtons[flow.SelectedOpponent]', 'return selectionDefault']) {
  if (!uiNavigation.includes(focusBehavior)) throw new Error(`Controller focus does not return to selected rival: ${focusBehavior}`);
}
for (const focusBinding of ['FindProperty("flow")', 'FindProperty("opponentButtons")']) {
  if (!sceneBuilder.includes(focusBinding)) throw new Error(`Generated controller navigation misses rival binding: ${focusBinding}`);
}
if (!sceneBuilder.includes('AddComponent<UiLocalizationController>()')) throw new Error('Generated HUD has no Japanese/English localization controller.');
for (const titleVisual of ['ConfigureTitleBackground()', 'CreateTitleBackground(selection.transform)', 'AspectRatioFitter.AspectMode.EnvelopeParent', 'TitleBackgroundController', 'FindProperty("landscape")', 'Readability Veil']) {
  if (!sceneBuilder.includes(titleVisual)) throw new Error(`Generated selection screen misses title art behavior: ${titleVisual}`);
}
const titlePng = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Art/Title/title-background-v1.png'));
if (titlePng.readUInt32BE(16) !== 1024 || titlePng.readUInt32BE(20) !== 1536)
  throw new Error('Title background must remain the approved 1024x1536 portrait master.');
const landscapeTitlePng = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Art/Title/title-background-landscape-v1.png'));
if (landscapeTitlePng.readUInt32BE(16) !== 1672 || landscapeTitlePng.readUInt32BE(20) !== 941)
  throw new Error('Steam title background must remain the approved 1672x941 landscape master.');
const titleBackground = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/TitleBackgroundController.cs'), 'utf8');
for (const responsiveBehavior of ['Screen.width > Screen.height', 'image.sprite = sprite', 'fitter.aspectRatio = sprite.rect.width / sprite.rect.height', 'TitleMotionModel.Evaluate', 'Time.unscaledTime', 'public bool ReducedMotion']) {
  if (!titleBackground.includes(responsiveBehavior)) throw new Error(`Title background is not responsive: ${responsiveBehavior}`);
}
for (const titleSetting of ['FindProperty("titleBackground")', 'titleBackground.ReducedMotion = preferences.ReducedMotion']) {
  if (!sceneBuilder.includes(titleSetting) && !fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/SettingsController.cs'), 'utf8').includes(titleSetting))
    throw new Error(`Title motion is not connected to accessibility settings: ${titleSetting}`);
}
const settingsController = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/SettingsController.cs'), 'utf8');
for (const displaySetting of ['fullscreenToggle.gameObject.SetActive(!Application.isMobilePlatform)', 'FullScreenMode.FullScreenWindow', 'FullScreenMode.Windowed', 'preferences.Fullscreen']) {
  if (!settingsController.includes(displaySetting)) throw new Error(`Missing desktop display preference: ${displaySetting}`);
}
const adaptiveAtmosphere = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/AdaptivePerformanceController.cs'), 'utf8');
for (const scalableAtmosphere of ['RenderSettings.fogDensity', '.018f', '.012f', '.006f']) {
  if (!adaptiveAtmosphere.includes(scalableAtmosphere)) throw new Error(`Atmosphere does not scale for iPhone and Steam Deck: ${scalableAtmosphere}`);
}
for (const accessibilityBinding of ['hud.ReducedMotion = preferences.ReducedMotion', '[SerializeField] private GameHudController hud']) {
  if (!settingsController.includes(accessibilityBinding)) throw new Error(`Score callout ignores reduced-motion setting: ${accessibilityBinding}`);
}
for (const displayBinding of ['FindProperty("fullscreenToggle")', 'フルスクリーン']) {
  if (!sceneBuilder.includes(displayBinding)) throw new Error(`Generated settings miss fullscreen control: ${displayBinding}`);
}
const preferenceCodec = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Core/GamePreferences.cs'), 'utf8');
for (const migrationBehavior of ['LegacyVersionFlag', 'value.Fullscreen ? 16 : 0', '(value & 16) != 0']) {
  if (!preferenceCodec.includes(migrationBehavior)) throw new Error(`Fullscreen preference migration is incomplete: ${migrationBehavior}`);
}

const feedback = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/ThrowFeedbackController.cs'), 'utf8');
for (const behavior of ['ThrowLaunched += HandleLaunched', 'ThrowImpactResolved += HandleResolved', 'ImpactFeedbackModel.Evaluate', 'CreateImpactSparks', 'EmitSparks', 'HapticFeedback.Success', 'MakeNoiseClip', 'KickCamera']) {
  if (!feedback.includes(behavior)) throw new Error(`Missing throw feedback behavior: ${behavior}`);
}

const coordinator = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/MatchCoordinator.cs'), 'utf8');
if (!coordinator.includes('ThrowLaunched?.Invoke(power, spin)')) throw new Error('Throw feedback is not connected to launch power and spin.');
if (!coordinator.includes('ThrowImpactResolved?.Invoke(outcome, worldPoint, true)')) throw new Error('Board impact position is not exposed to feedback.');
for (const releasePoint of ['playerReleasePoint', 'enemyReleasePoint', 'enemyThrowAnimator']) {
  if (!coordinator.includes(releasePoint)) throw new Error(`Missing separated thrower source: ${releasePoint}`);
}
const projectile = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/ShurikenProjectile.cs'), 'utf8');
for (const settleBehavior of ['collision.relativeVelocity.magnitude', 'ImpactSettleModel.Amplitude', 'ImpactSettleModel.Angle', 'embeddedRotation * Quaternion.AngleAxis']) {
  if (!projectile.includes(settleBehavior)) throw new Error(`Embedded shuriken has no physical settle: ${settleBehavior}`);
}
for (const flightBehavior of ['CollisionDetectionMode.ContinuousDynamic', 'Quaternion.LookRotation(velocity.normalized, transform.up)', 'ShurikenFlightModel.Spin', '_body.maxAngularVelocity = spin.RequiredAngularLimit', 'transform.forward * spin.RadiansPerSecond', 'Quaternion.FromToRotation(transform.forward, -contact.normal)', 'contact.point + contact.normal * surfaceClearance']) {
  if (!projectile.includes(flightBehavior)) throw new Error(`Shuriken flight is missing high-speed behavior: ${flightBehavior}`);
}
if (projectile.includes('transform.SetParent(board.transform'))
  throw new Error('Embedded shuriken inherits the board non-uniform scale and can render distorted.');
if (!sceneBuilder.includes('rigidbody.maxAngularVelocity = 40f'))
  throw new Error('Generated shuriken prefab clamps its authored spin speed.');
const targetBoard = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/TargetBoard.cs'), 'utf8');
for (const surfaceBehavior of ['surfaceLocalZ = -.071f', 'surfaceLocalZ + surfaceOffset', 'float surfaceOffset = 0f']) {
  if (!targetBoard.includes(surfaceBehavior)) throw new Error(`Board aim does not target the physical scoring surface: ${surfaceBehavior}`);
}
if (!sceneBuilder.includes('FindProperty("surfaceLocalZ").floatValue = -.071f'))
  throw new Error('Generated board does not bind its physical scoring surface depth.');
for (const playerMotionBehavior of ['_pendingPlayerIntent', 'playerThrowAnimator.PlayThrow(power, spin)', 'HandlePlayerAnimationRelease', 'UpdatePlayerHand(outcome)']) {
  if (!coordinator.includes(playerMotionBehavior)) throw new Error(`Missing synchronized first-person throw behavior: ${playerMotionBehavior}`);
}
for (const openingInputBehavior of ['gestureReader.CancelTracking()', 'Time.unscaledTime + openingInputDelay', 'openingInputDelay = .4f']) {
  if (!coordinator.includes(openingInputBehavior)) throw new Error(`Match start can inherit a UI touch as a throw: ${openingInputBehavior}`);
}
const throwGestureSource = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/ThrowGestureReader.cs'), 'utf8');
for (const cancelBehavior of ['public bool CancelTracking()', '_tracking = false', 'PointerTracked?.Invoke(_start, false)', 'private void OnDisable() => CancelTracking()']) {
  if (!throwGestureSource.includes(cancelBehavior)) throw new Error(`Throw gesture cannot clear stale pointer state: ${cancelBehavior}`);
}
for (const pauseBehavior of ['public bool IsPaused', 'PausedChanged?.Invoke(paused)', 'if (IsPaused || _throwInFlight']) {
  if (!coordinator.includes(pauseBehavior)) throw new Error(`Missing match pause behavior: ${pauseBehavior}`);
}
for (const projectileBehavior of ['_embeddedProjectiles.Add(projectile)', '_projectileOwner.Value != Match.Turn', 'ClearEmbeddedProjectiles()']) {
  if (!coordinator.includes(projectileBehavior)) throw new Error(`Missing embedded projectile lifecycle: ${projectileBehavior}`);
}

const enemyDirector = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/EnemyTurnDirector.cs'), 'utf8');
if (!enemyDirector.includes('PausedChanged += HandlePausedChanged')) throw new Error('Enemy AI is not connected to pause lifecycle.');
if (!enemyDirector.includes('AnimateLaunchAtBoard')) throw new Error('Enemy throws are not synchronized to ninja animation.');
for (const openingBehavior of ['BeginTurnIfNeeded', 'coordinator.Match.Turn != Combatant.Enemy', 'ScheduleThrow(transitionDelay)']) {
  if (!enemyDirector.includes(openingBehavior)) throw new Error(`Missing enemy opening-turn behavior: ${openingBehavior}`);
}

const gameFlow = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/GameFlowController.cs'), 'utf8');
for (const starterBehavior of ['NextStarter', 'StartMatch(StartScore, DoubleOut, LegsToWin, NextStarter)', 'if (!outcome.MatchEnded) return', 'MatchOrder.Opponent(NextStarter)']) {
  if (!gameFlow.includes(starterBehavior)) throw new Error(`Missing fair rematch starter behavior: ${starterBehavior}`);
}
if (!gameFlow.includes('enemyDirector.BeginTurnIfNeeded(.35f)')) throw new Error('Enemy starter is not scheduled when a match begins.');
for (const resumeBehavior of ['ActiveMatchSlot', 'SaveCheckpoint(CareerStats career)', 'TryLoadCheckpoint(false', 'TryLoadCheckpoint(true', 'TryApplyCheckpoint', 'SaveRecovered', 'ClearCheckpoint()']) {
  if (!gameFlow.includes(resumeBehavior)) throw new Error(`Missing active match recovery behavior: ${resumeBehavior}`);
}
if (!gameFlow.includes('CareerSaveResolver.CanRestoreCheckpoint(save.Career, progress.Stats)'))
  throw new Error('Old active match can overwrite newer Steam/iOS cloud career progress.');
if ((gameFlow.match(/ClearCheckpoint\(\);/g) || []).length < 3)
  throw new Error('Active match checkpoint is not cleared after both completion and abort.');

const pauseController = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/GamePauseController.cs'), 'utf8');
for (const lifecycleBehavior of ['_applicationFocused', '_applicationSuspended', '_platformOverlay', 'PlatformActivityState.OverlayChanged += HandleOverlayChanged', 'ApplicationLifecycleModel.ShouldPauseAudio', 'ApplicationLifecycleModel.CanResume', 'if (_platformOverlay) return', 'RefreshAudioPause()']) {
  if (!pauseController.includes(lifecycleBehavior)) throw new Error(`Missing unified iOS lifecycle behavior: ${lifecycleBehavior}`);
}
if (!pauseController.includes('Gamepad.current.buttonEast.wasPressedThisFrame'))
  throw new Error('Controller back button does not toggle match pause.');
for (const backBehavior of ['UiFocusModel.ResolveBack', 'Gamepad.current.buttonEast.wasPressedThisFrame', 'button.onClick.Invoke()', 'changeOpponentButton', 'cancelCalibrationButton', 'tutorialSkipButton', 'closeSettingsButton']) {
  if (!uiNavigation.includes(backBehavior)) throw new Error(`Missing common controller back behavior: ${backBehavior}`);
}
for (const backBinding of ['FindProperty("changeOpponentButton")', 'FindProperty("cancelCalibrationButton")', 'FindProperty("tutorialSkipButton")', 'FindProperty("closeSettingsButton")']) {
  if (!sceneBuilder.includes(backBinding)) throw new Error(`Generated scene misses back button binding: ${backBinding}`);
}
const overlayPlatformServices = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/PlatformServices.cs'), 'utf8');
for (const overlayBoundary of ['public static class PlatformActivityState', 'public static event Action<bool> OverlayChanged', 'SetOverlayActive(bool active)']) {
  if (!overlayPlatformServices.includes(overlayBoundary)) throw new Error(`Steam adapter has no overlay pause boundary: ${overlayBoundary}`);
}
const runtimeBootstrap = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/IosRuntimeBootstrap.cs'), 'utf8');
if (runtimeBootstrap.includes('OnApplicationFocus')) throw new Error('Audio focus is controlled by two competing lifecycle components.');
if (!runtimeBootstrap.includes('Screen.sleepTimeout = SleepTimeout.SystemSetting')) throw new Error('iOS bootstrap drains battery outside active matches.');
const screenWake = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/ScreenWakeController.cs'), 'utf8');
for (const wakeBehavior of ['ScreenWakePolicy.ShouldPreventSleep', 'SleepTimeout.NeverSleep', 'SleepTimeout.SystemSetting', 'coordinator.PausedChanged += HandlePausedChanged', 'coordinator.MatchAborted += HandleMatchAborted']) {
  if (!screenWake.includes(wakeBehavior)) throw new Error(`Missing match-scoped iOS wake behavior: ${wakeBehavior}`);
}
if (!sceneBuilder.includes('AddComponent<ScreenWakeController>()')) throw new Error('Generated scene has no match-scoped screen wake controller.');
const adaptivePerformance = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/AdaptivePerformanceController.cs'), 'utf8');
for (const memoryBehavior of ['Application.lowMemory += HandleLowMemory', 'Application.lowMemory -= HandleLowMemory', '_governor.HandleMemoryPressure()', 'Apply(_governor.Tier)']) {
  if (!adaptivePerformance.includes(memoryBehavior)) throw new Error(`Adaptive quality ignores iOS memory pressure: ${memoryBehavior}`);
}

const ninjaAnimator = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/NinjaThrowAnimator.cs'), 'utf8');
for (const motionBehavior of ['PlayProcedural()', 'ReleaseShuriken()', 'FinishThrow()', 'ReleaseNormalizedTime']) {
  if (!ninjaAnimator.includes(motionBehavior)) throw new Error(`Missing ninja motion behavior: ${motionBehavior}`);
}
const ninjaReaction = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/NinjaReactionController.cs'), 'utf8');
for (const reactionBehavior of ['NinjaReactionModel.Evaluate', 'throwAnimator.IsThrowing', 'PausedChanged += HandlePausedChanged', 'MatchAborted += CancelReaction', 'ReducedMotion']) {
  if (!ninjaReaction.includes(reactionBehavior)) throw new Error(`Missing synchronized ninja reaction behavior: ${reactionBehavior}`);
}
for (const reactionBinding of ['FindProperty("ninjaReaction")', 'ninjaRig.Reaction', 'FindProperty("head")']) {
  if (!sceneBuilder.includes(reactionBinding)) throw new Error(`Generated scene misses ninja reaction binding: ${reactionBinding}`);
}

const reticle = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/AimReticleController.cs'), 'utf8');
for (const reticleBehavior of ['PointerTracked += HandlePointer', 'ScreenAimModel.Map', 'match.Turn == Combatant.Player']) {
  if (!reticle.includes(reticleBehavior)) throw new Error(`Missing aim reticle behavior: ${reticleBehavior}`);
}

const progress = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/PlayerProgressController.cs'), 'utf8');
for (const checkpointBinding of ['flow.SaveCheckpoint(Stats)', 'RestoreCheckpoint(CareerStats checkpoint)', 'SaveCareerCheckpoint(true)']) {
  if (!progress.includes(checkpointBinding)) throw new Error(`Career is not synchronized with active match recovery: ${checkpointBinding}`);
}
if (!progress.includes('TryLoadBackup') || !progress.includes('TryDeserialize'))
  throw new Error('Career progress does not recover from a corrupt primary save.');
for (const promotionBehavior of ['RankPromoted', '_rankAtMatchStart', 'CareerRankModel.IsPromotion']) {
  if (!progress.includes(promotionBehavior)) throw new Error(`Missing career promotion behavior: ${promotionBehavior}`);
}
const achievementToast = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/AchievementToastController.cs'), 'utf8');
for (const toastBehavior of ['progress.RankPromoted += ShowRank', 'PROMOTED', 'CareerRankModel.Japanese', 'CareerRankModel.English']) {
  if (!achievementToast.includes(toastBehavior)) throw new Error(`Missing localized rank promotion toast: ${toastBehavior}`);
}
for (const localizedAchievement of ['AchievementId', 'AchievementCatalog.Title(message.AchievementId, language)']) {
  if (!achievementToast.includes(localizedAchievement)) throw new Error(`Achievement toast does not localize stable ID at display time: ${localizedAchievement}`);
}
if (!progress.includes('AchievementUnlocked?.Invoke(snapshot.Achievements[i])'))
  throw new Error('Platform achievement event discards its stable Steam-ready ID.');
for (const platformBehavior of ['PlatformServiceRegistry.Create()', 'PlatformProgressSnapshot.From(Stats)', 'SaveCloud(Encoding.UTF8.GetBytes(json))', '_platform.Flush()']) {
  if (!progress.includes(platformBehavior)) throw new Error(`Missing platform sync behavior: ${platformBehavior}`);
}
for (const exitSaveBehavior of ['public void FlushForExit()', 'if (_exitFlushed) return', 'OnApplicationQuit() => FlushForExit()', 'flow.SaveCheckpoint(Stats)', '_platform.Flush()', 'PlayerPrefs.Save()']) {
  if (!progress.includes(exitSaveBehavior)) throw new Error(`Desktop exit does not flush progress safely: ${exitSaveBehavior}`);
}
const desktopQuit = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/DesktopQuitController.cs'), 'utf8');
for (const quitBehavior of ['!Application.isMobilePlatform', 'progress.FlushForExit()', 'HapticFeedback.Stop()', 'Application.Quit()']) {
  if (!desktopQuit.includes(quitBehavior)) throw new Error(`Missing Steam-safe quit behavior: ${quitBehavior}`);
}
for (const quitBinding of ['AddComponent<DesktopQuitController>()', 'FindProperty("quitButton")', 'FindProperty("progress")']) {
  if (!sceneBuilder.includes(quitBinding)) throw new Error(`Generated scene misses desktop quit binding: ${quitBinding}`);
}

const gameHud = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/GameHudController.cs'), 'utf8');
for (const calloutBehavior of ['PlayHitCallout(ImpactFeedbackModel.Evaluate(outcome))', 'profile.CalloutScale', 'profile.CalloutHoldSeconds', 'Time.unscaledDeltaTime', 'ReducedMotion ? 1f']) {
  if (!gameHud.includes(calloutBehavior)) throw new Error(`Impact score callout is incomplete: ${calloutBehavior}`);
}
for (const resumeHud of ['flow.MatchStarted += HandleMatchStarted', 'matchPanel.SetActive(true)', 'flow.LastMatchWasResumed', 'MATCH RESTORED']) {
  if (!gameHud.includes(resumeHud)) throw new Error(`HUD does not reveal restored match state: ${resumeHud}`);
}
if (!gameHud.includes('FIRST THROW') || !gameHud.includes('先攻')) throw new Error('Opponent selection does not disclose the next starter.');
if (!gameHud.includes('OpponentDifficultyModel.Stars(opponent.Skill)') || !gameHud.includes('DIFFICULTY') || !gameHud.includes('難易度'))
  throw new Error('Opponent selection does not disclose difficulty from actual tuning.');
for (const portraitBehavior of ['CreateOpponentPortrait', 'typeof(RawImage)', 'image.uvRect = new Rect(index / (float)count', 'portrait.transform.SetAsFirstSibling()', 'title-background-landscape-v1.png']) {
  if (!sceneBuilder.includes(portraitBehavior)) throw new Error(`Opponent cards do not use the realistic five-ninja lineup: ${portraitBehavior}`);
}
for (const turnHistoryBehavior of ['TurnHistoryTracker', '_turnHistory.Record(outcome)', 'RenderTurnSummary()', 'CompactHit']) {
  if (!gameHud.includes(turnHistoryBehavior)) throw new Error(`Missing three-throw HUD history: ${turnHistoryBehavior}`);
}
for (const careerRankBehavior of ['CareerRankModel.Evaluate', 'CareerRankModel.Japanese', 'CareerRankModel.English', 'rank.NextOpponents']) {
  if (!gameHud.includes(careerRankBehavior)) throw new Error(`Missing career rank HUD behavior: ${careerRankBehavior}`);
}
if (/HandleThrowResolved[\s\S]{0,260}HapticFeedback\./.test(gameHud))
  throw new Error('Game HUD duplicates impact haptics owned by ThrowFeedbackController.');

const platformServices = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/PlatformServices.cs'), 'utf8');
for (const adapterBehavior of ['PlatformServiceRegistry', 'Register(Func<IPlatformServices> factory)', 'TryLoadCloud(out byte[] data)', 'void Flush()']) {
  if (!platformServices.includes(adapterBehavior)) throw new Error(`Missing replaceable platform adapter behavior: ${adapterBehavior}`);
}
for (const cloudRecoveryBehavior of ['CareerSaveResolver.Choose(local, cloud)', '_platform.TryLoadCloud', 'ReferenceEquals(selected, cloud)', '_store.SaveRecovered']) {
  if (!progress.includes(cloudRecoveryBehavior)) throw new Error(`Missing cloud career recovery behavior: ${cloudRecoveryBehavior}`);
}
if (!progress.includes('cloud.Normalize(opponentCount)') || !progress.includes('local.Normalize(opponentCount)'))
  throw new Error('Local and cloud career candidates are not normalized before conflict resolution.');

const opponentProfile = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/OpponentProfile.cs'), 'utf8');
for (const identityField of ['StyleDescription', 'EnglishDisplayName', 'EnglishTitle', 'EnglishStyleDescription', 'Strategy', 'OutfitColor', 'AccentColor', 'VisualStyle', 'BodyScale']) {
  if (!opponentProfile.includes(identityField)) throw new Error(`Missing opponent identity field: ${identityField}`);
}
const ninjaVisual = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/NinjaVisualController.cs'), 'utf8');
for (const visualBehavior of ['profile.BodyScale', 'profile.VisualStyle', 'styleAccessories[i].SetActive']) {
  if (!ninjaVisual.includes(visualBehavior)) throw new Error(`Five rivals do not have distinct silhouettes: ${visualBehavior}`);
}
for (const accessory of ['Kagero Rookie Sash', 'Shigure Scout Hood Tails', 'Yasha Armored Shoulders', 'Genma Veteran Back Blades', 'Mukuro Shadow Crest']) {
  if (!sceneBuilder.includes(accessory)) throw new Error(`Missing rival equipment set: ${accessory}`);
}

const achievementCatalog = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Core/AchievementCatalog.cs'), 'utf8');
for (const platformId of ['SZ_FIRST_VICTORY', 'SZ_CHECKOUT_100', 'SZ_MAXIMUM_180', 'SZ_DEFEAT_ALL_FIVE']) {
  if (!achievementCatalog.includes(platformId)) throw new Error(`Missing stable achievement ID: ${platformId}`);
}

const gestureReader = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/ThrowGestureReader.cs'), 'utf8');
if (!gestureReader.includes('Rejected?.Invoke(rejection)')) throw new Error('Rejected throw reasons are not emitted to the HUD.');
for (const pointerBoundary of ['IsOverInteractiveUi(position)', 'GetComponentInParent<Selectable>()', 'eventSystem.RaycastAll', 'OnApplicationPause(bool paused)', 'OnApplicationFocus(bool focused)', 'CancelTracking();']) {
  if (!gestureReader.includes(pointerBoundary)) throw new Error(`Throw input can leak through UI or lifecycle boundaries: ${pointerBoundary}`);
}
const tutorialController = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/TutorialController.cs'), 'utf8');
for (const adaptiveGuide of ['TutorialThrowGuide.Text', 'InputModeDetector.Detect', 'InputModeDetector.Default']) {
  if (!tutorialController.includes(adaptiveGuide)) throw new Error(`Tutorial does not adapt to the active input device: ${adaptiveGuide}`);
}
const inputModeDetector = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/InputModeDetector.cs'), 'utf8');
for (const inputSignal of ['Touchscreen.current.primaryTouch', 'Gamepad.current', 'Keyboard.current.anyKey', 'Mouse.current.leftButton']) {
  if (!inputModeDetector.includes(inputSignal)) throw new Error(`Shared input mode detection misses device signal: ${inputSignal}`);
}
for (const matchPrompt of ['ThrowPromptCatalog.Text', 'InputModeDetector.Detect', 'ShowThrowPrompt()', 'ShowRivalOpening()', '_showingInputPrompt']) {
  if (!gameHud.includes(matchPrompt)) throw new Error(`Match HUD does not adapt throw guidance: ${matchPrompt}`);
}

const rumbleDriver = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/GamepadRumbleDriver.cs'), 'utf8');
for (const rumbleBehavior of ['SetMotorSpeeds', 'Time.unscaledTime', 'InputSystem.onDeviceChange', 'InputDeviceChange.Disconnected', 'StopCurrent()']) {
  if (!rumbleDriver.includes(rumbleBehavior)) throw new Error(`Missing Steam gamepad rumble behavior: ${rumbleBehavior}`);
}
if (!sceneBuilder.includes('AddComponent<GamepadRumbleDriver>()')) throw new Error('Generated scene has no gamepad rumble driver.');

const performanceController = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/AdaptivePerformanceController.cs'), 'utf8');
for (const performanceBehavior of ['PerformanceGovernor.InitialTier', 'main.maxParticles = 160', 'emission.rateOverTime = 55f', 'LightShadows.None', 'Time.timeScale <= 0f']) {
  if (!performanceController.includes(performanceBehavior)) throw new Error(`Missing adaptive performance behavior: ${performanceBehavior}`);
}
if (!sceneBuilder.includes('AddComponent<AdaptivePerformanceController>()')) throw new Error('Generated scene has no adaptive performance controller.');

const ambient = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/AmbientAudioController.cs'), 'utf8');
for (const ambientBehavior of ['new System.Random(1977)', 'source.loop = true', 'fadeSamples']) {
  if (!ambient.includes(ambientBehavior)) throw new Error(`Missing deterministic seamless ambience behavior: ${ambientBehavior}`);
}

const alternativeInput = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Runtime/AlternativeThrowController.cs'), 'utf8');
for (const controlBinding of ['leftStick.ReadValue()', 'rightTrigger.wasPressedThisFrame', 'Keyboard.current.fKey', 'TryPlayerThrow']) {
  if (!alternativeInput.includes(controlBinding)) throw new Error(`Missing desktop throw binding: ${controlBinding}`);
}

const acceptanceAsmdef = JSON.parse(fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Tests/SceneAcceptance/ShinobiZero.SceneAcceptance.asmdef'), 'utf8'));
for (const assembly of ['ShinobiZero.Core', 'ShinobiZero.Runtime', 'ShinobiZero.Editor']) {
  if (!acceptanceAsmdef.references.includes(assembly)) throw new Error(`Scene acceptance tests miss assembly reference: ${assembly}`);
}

const sceneBuilderTuning = fs.readFileSync(path.join(root, 'Assets/ShinobiZero/Editor/PrototypeSceneBuilder.cs'), 'utf8');
if (!sceneBuilderTuning.includes('OpponentTuningCatalog.Get(i)')) throw new Error('Generated opponent profiles can drift from the tested tuning catalog.');
if (!sceneBuilderTuning.includes('FindProperty("strategy").enumValueIndex = (int)tuning.Strategy'))
  throw new Error('Generated opponent profiles do not receive their tested strategy.');

for (const abortBinding of ['MatchAborted?.Invoke()', 'enemyThrowAnimator.CancelThrow()', '_embeddedProjectiles[i].Cancel()']) {
  if (!coordinator.includes(abortBinding)) throw new Error(`Incomplete match abort cleanup: ${abortBinding}`);
}

console.log(`SHINOBI ZERO Unity structure: ${required.length} required files, ${sourceFiles.length} C# files, 3 packages and iOS settings validated`);
