using NUnit.Framework;
using ShinobiZero.Editor;
using ShinobiZero.Runtime;
using UnityEditor;
using UnityEngine;
using UnityEngine.InputSystem.UI;
using UnityEngine.UI;

namespace ShinobiZero.Tests
{
    public sealed class GeneratedSceneAcceptanceTests
    {
        private MatchCoordinator _coordinator;

        [OneTimeSetUp]
        public void BuildScene()
        {
            PrototypeSceneBuilder.CreateScene();
            _coordinator = Object.FindObjectOfType<MatchCoordinator>();
        }

        [Test] public void CoreGameplayReferencesAreAssigned()
        {
            Assert.That(_coordinator, Is.Not.Null);
            var serialized = new SerializedObject(_coordinator);
            var playerRelease = Reference<Transform>(serialized, "playerReleasePoint");
            var enemyRelease = Reference<Transform>(serialized, "enemyReleasePoint");
            Assert.That(playerRelease, Is.Not.SameAs(enemyRelease));
            Assert.That(Reference<TargetBoard>(serialized, "target"), Is.Not.Null);
            var shuriken = Reference<ShurikenProjectile>(serialized, "shurikenPrefab");
            Assert.That(shuriken, Is.Not.Null);
            Assert.That(shuriken.GetComponent<Rigidbody>().collisionDetectionMode, Is.EqualTo(CollisionDetectionMode.ContinuousDynamic));
            Assert.That(shuriken.GetComponent<Rigidbody>().maxAngularVelocity, Is.GreaterThanOrEqualTo(40f));
            Assert.That(new SerializedObject(shuriken).FindProperty("surfaceClearance").floatValue, Is.EqualTo(.015f).Within(.0001f));
            Assert.That(new SerializedObject(shuriken).FindProperty("maximumImpactWobble").floatValue, Is.InRange(4f, 10f));
            Assert.That(new SerializedObject(shuriken).FindProperty("impactSettleDuration").floatValue, Is.InRange(.15f, .4f));
            var enemyAnimator = Reference<NinjaThrowAnimator>(serialized, "enemyThrowAnimator");
            Assert.That(enemyAnimator, Is.Not.Null);
            var heldEnemyShuriken = Reference<GameObject>(new SerializedObject(enemyAnimator), "heldShuriken");
            Assert.That(heldEnemyShuriken.name, Is.EqualTo("Enemy Held Shuriken"));
            Assert.That(heldEnemyShuriken.GetComponentInChildren<MeshFilter>(), Is.Not.Null);
            var playerAnimator = Reference<FirstPersonThrowAnimator>(serialized, "playerThrowAnimator");
            Assert.That(playerAnimator, Is.Not.Null);
            var heldPlayerShuriken = Reference<GameObject>(new SerializedObject(playerAnimator), "heldShuriken");
            Assert.That(heldPlayerShuriken.transform.Find("Forged Blades"), Is.Not.Null);
            Assert.That(heldPlayerShuriken.transform.Find("Raised Hub"), Is.Not.Null);
            Assert.That(heldPlayerShuriken.transform.Find("Dark Finger Recess"), Is.Not.Null);
            Assert.That(Object.FindObjectOfType<NinjaReactionController>(), Is.Not.Null);
            Assert.That(Object.FindObjectOfType<GamepadRumbleDriver>(), Is.Not.Null);
            Assert.That(Object.FindObjectOfType<AdaptivePerformanceController>(), Is.Not.Null);
            Assert.That(Object.FindObjectOfType<ScreenWakeController>(), Is.Not.Null);
            Assert.That(Object.FindObjectOfType<TitleBackgroundController>(true), Is.Not.Null);
            Assert.That(Reference<Camera>(serialized, "aimCamera"), Is.EqualTo(Camera.main));
            Assert.That(serialized.FindProperty("openingInputDelay").floatValue, Is.GreaterThanOrEqualTo(.35f));
            var flow = Object.FindObjectOfType<GameFlowController>();
            Assert.That(Reference<PlayerProgressController>(new SerializedObject(flow), "progress"), Is.Not.Null);
            var target = Reference<TargetBoard>(serialized, "target");
            var localAim = target.transform.InverseTransformPoint(target.BoardPointToWorld(Vector2.zero));
            Assert.That(localAim.z, Is.EqualTo(target.SurfaceLocalZ).Within(.0001f));
            Assert.That(localAim.z, Is.EqualTo(-.071f).Within(.0001f));
        }

        [Test] public void AllFiveOpponentsHaveCompleteProfiles()
        {
            var flow = Object.FindObjectOfType<GameFlowController>();
            Assert.That(flow, Is.Not.Null);
            Assert.That(flow.OpponentCount, Is.EqualTo(5));
            for (var i = 0; i < flow.OpponentCount; i++)
            {
                var opponent = flow.GetOpponent(i);
                Assert.That(opponent, Is.Not.Null);
                Assert.That(opponent.DisplayName, Is.Not.Empty);
                Assert.That(opponent.Title, Is.Not.Empty);
                Assert.That(opponent.StyleDescription, Is.Not.Empty);
                Assert.That(opponent.EnglishDisplayName, Is.Not.Empty);
                Assert.That(opponent.EnglishTitle, Is.Not.Empty);
                Assert.That(opponent.EnglishStyleDescription, Is.Not.Empty);
                Assert.That(OpponentStrategyNames.Japanese(opponent.Strategy), Is.Not.Empty);
                Assert.That(opponent.AnimationProfile, Is.Not.Null);
                Assert.That((int)opponent.VisualStyle, Is.EqualTo(i));
                Assert.That(opponent.BodyScale.x, Is.GreaterThan(.9f));
            }
            var visual = Object.FindObjectOfType<NinjaVisualController>();
            Assert.That(visual, Is.Not.Null);
            Assert.That(new SerializedObject(visual).FindProperty("styleAccessories").arraySize, Is.EqualTo(5));
        }

        [Test] public void RegulationBoardVisualIsGenerated()
        {
            var surface = GameObject.Find("Regulation Scoring Surface");
            Assert.That(surface, Is.Not.Null);
            Assert.That(surface.GetComponent<MeshFilter>().sharedMesh.subMeshCount, Is.EqualTo(4));
            var board = surface.transform.parent;
            var numberCount = 0;
            for (var i = 0; i < board.childCount; i++)
                if (board.GetChild(i).name.StartsWith("Number ")) numberCount++;
            Assert.That(numberCount, Is.EqualTo(20));
            var wireRoot = GameObject.Find("Regulation Spider Wires");
            Assert.That(wireRoot, Is.Not.Null);
            Assert.That(wireRoot.GetComponentsInChildren<LineRenderer>(true).Length, Is.EqualTo(26));
        }

        [Test] public void PortraitHudAndInputSystemArePresent()
        {
            var hud = Object.FindObjectOfType<GameHudController>();
            Assert.That(hud, Is.Not.Null);
            var bundledFont = Reference<Font>(new SerializedObject(hud), "bundledFont");
            Assert.That(AssetDatabase.GetAssetPath(bundledFont), Is.EqualTo("Assets/ShinobiZero/Fonts/NotoSansJP-Variable.ttf"));
            var canvas = hud.GetComponent<Canvas>();
            var scaler = hud.GetComponent<CanvasScaler>();
            Assert.That(canvas.renderMode, Is.EqualTo(RenderMode.ScreenSpaceOverlay));
            Assert.That(scaler.referenceResolution, Is.EqualTo(new Vector2(1080f, 1920f)));
            Assert.That(Object.FindObjectOfType<SafeAreaFitter>(), Is.Not.Null);
            var responsive = Object.FindObjectOfType<ResponsiveHudLayout>();
            Assert.That(responsive, Is.Not.Null);
            responsive.Apply(1280, 800, true);
            Assert.That(scaler.referenceResolution, Is.EqualTo(new Vector2(1600f, 900f)));
            responsive.Apply(1080, 1920, true);
            Assert.That(Object.FindObjectOfType<UiNavigationController>(), Is.Not.Null);
            var navigation = Object.FindObjectOfType<UiNavigationController>();
            var navigationSerialized = new SerializedObject(navigation);
            Assert.That(Reference<GameFlowController>(navigationSerialized, "flow"), Is.Not.Null);
            Assert.That(navigationSerialized.FindProperty("opponentButtons").arraySize, Is.EqualTo(5));
            Assert.That(Object.FindObjectOfType<UiLocalizationController>(), Is.Not.Null);
            Assert.That(Object.FindObjectOfType<InputSystemUIInputModule>(), Is.Not.Null);
            Assert.That(Reference<Text>(new SerializedObject(hud), "turnSummaryText"), Is.Not.Null);
        }

        [Test] public void ProductControllersAreConnected()
        {
            Assert.That(Object.FindObjectOfType<PlayerProgressController>(), Is.Not.Null);
            var settings = Object.FindObjectOfType<SettingsController>();
            Assert.That(settings, Is.Not.Null);
            Assert.That(Reference<GameHudController>(new SerializedObject(settings), "hud"), Is.Not.Null);
            Assert.That(Object.FindObjectOfType<TutorialController>(), Is.Not.Null);
            Assert.That(Object.FindObjectOfType<GamePauseController>(), Is.Not.Null);
            Assert.That(Object.FindObjectOfType<AimReticleController>(), Is.Not.Null);
            Assert.That(Object.FindObjectOfType<AchievementToastController>(), Is.Not.Null);
            Assert.That(Object.FindObjectOfType<AmbientAudioController>(), Is.Not.Null);
            Assert.That(Object.FindObjectOfType<AlternativeThrowController>(), Is.Not.Null);
            Assert.That(Object.FindObjectOfType<FirstPersonThrowAnimator>(true), Is.Not.Null);
            Assert.That(GameObject.Find("Cold Rain"), Is.Not.Null);
            Assert.That(GameObject.Find("Weathered Dojo Frame"), Is.Not.Null);
            Assert.That(GameObject.Find("Weathered Iron Lantern"), Is.Not.Null);
            Assert.That(GameObject.Find("Rain Puddles"), Is.Not.Null);
            var reverb = Object.FindObjectOfType<AudioReverbZone>();
            Assert.That(reverb, Is.Not.Null);
            Assert.That(reverb.reverbPreset, Is.EqualTo(AudioReverbPreset.StoneCorridor));
            Assert.That(RenderSettings.fog, Is.True);
        }

        private static T Reference<T>(SerializedObject serialized, string propertyName) where T : Object
        {
            var property = serialized.FindProperty(propertyName);
            Assert.That(property, Is.Not.Null, propertyName + " property is missing");
            Assert.That(property.objectReferenceValue, Is.Not.Null, propertyName + " is not assigned");
            return property.objectReferenceValue as T;
        }
    }
}
