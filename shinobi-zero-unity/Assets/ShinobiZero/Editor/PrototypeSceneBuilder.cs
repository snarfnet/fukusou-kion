using System.IO;
using System.Collections.Generic;
using ShinobiZero.Core;
using ShinobiZero.Runtime;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem.UI;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace ShinobiZero.Editor
{
    public static class PrototypeSceneBuilder
    {
        private const string GeneratedRoot = "Assets/ShinobiZero/Generated";

        [MenuItem("Tools/SHINOBI ZERO/Create 3D Prototype Scene")]
        public static void CreateScene()
        {
            EnsureFolder(GeneratedRoot);
            ConfigureTitleBackground();
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            RenderSettings.ambientLight = new Color(.07f, .09f, .1f);
            RenderSettings.fog = true;
            RenderSettings.fogMode = FogMode.ExponentialSquared;
            RenderSettings.fogColor = new Color(.025f, .035f, .045f);
            RenderSettings.fogDensity = .018f;

            var gameCamera = CreateCamera();
            var keyLight = CreateLighting();
            CreateEnvironment();
            var rain = CreateRainAtmosphere();
            var target = CreateTarget();
            var projectile = CreateShurikenPrefab();
            var mapper = CreateThrowMapper();
            var motionProfiles = CreateThrowAnimationProfiles();
            var ninjaRig = CreateProceduralNinja(motionProfiles[2]);
            var playerRig = CreateFirstPersonThrowRig();
            var opponents = CreateOpponentProfiles(motionProfiles);

            var systems = new GameObject("Game Systems");
            systems.AddComponent<IosRuntimeBootstrap>();
            systems.AddComponent<AmbientAudioController>();
            systems.AddComponent<GamepadRumbleDriver>();
            var performance = systems.AddComponent<AdaptivePerformanceController>();
            var performanceSerialized = new SerializedObject(performance);
            performanceSerialized.FindProperty("rain").objectReferenceValue = rain;
            performanceSerialized.FindProperty("keyLight").objectReferenceValue = keyLight;
            performanceSerialized.ApplyModifiedPropertiesWithoutUndo();
            var gesture = systems.AddComponent<ThrowGestureReader>();
            var coordinator = systems.AddComponent<MatchCoordinator>();
            var serialized = new SerializedObject(coordinator);
            serialized.FindProperty("gestureReader").objectReferenceValue = gesture;
            serialized.FindProperty("throwMapper").objectReferenceValue = mapper;
            serialized.FindProperty("aimCamera").objectReferenceValue = gameCamera;
            serialized.FindProperty("playerReleasePoint").objectReferenceValue = playerRig.ReleasePoint;
            serialized.FindProperty("enemyReleasePoint").objectReferenceValue = ninjaRig.ReleasePoint;
            serialized.FindProperty("target").objectReferenceValue = target;
            serialized.FindProperty("shurikenPrefab").objectReferenceValue = projectile;
            serialized.FindProperty("enemyThrowAnimator").objectReferenceValue = ninjaRig.Animator;
            serialized.FindProperty("playerThrowAnimator").objectReferenceValue = playerRig.Animator;
            serialized.ApplyModifiedPropertiesWithoutUndo();
            var reactionRuntimeSerialized = new SerializedObject(ninjaRig.Reaction);
            reactionRuntimeSerialized.FindProperty("coordinator").objectReferenceValue = coordinator;
            reactionRuntimeSerialized.ApplyModifiedPropertiesWithoutUndo();
            var alternativeInput = systems.AddComponent<AlternativeThrowController>();
            var alternativeSerialized = new SerializedObject(alternativeInput);
            alternativeSerialized.FindProperty("coordinator").objectReferenceValue = coordinator;
            alternativeSerialized.ApplyModifiedPropertiesWithoutUndo();
            var enemyDirector = systems.AddComponent<EnemyTurnDirector>();
            var enemySerialized = new SerializedObject(enemyDirector);
            enemySerialized.FindProperty("coordinator").objectReferenceValue = coordinator;
            enemySerialized.FindProperty("profile").objectReferenceValue = opponents[0];
            enemySerialized.ApplyModifiedPropertiesWithoutUndo();
            var flow = systems.AddComponent<GameFlowController>();
            var flowSerialized = new SerializedObject(flow);
            flowSerialized.FindProperty("coordinator").objectReferenceValue = coordinator;
            flowSerialized.FindProperty("enemyDirector").objectReferenceValue = enemyDirector;
            flowSerialized.FindProperty("ninjaVisual").objectReferenceValue = ninjaRig.Visual;
            flowSerialized.FindProperty("ninjaReaction").objectReferenceValue = ninjaRig.Reaction;
            var opponentArray = flowSerialized.FindProperty("opponents");
            opponentArray.arraySize = opponents.Length;
            for (var i = 0; i < opponents.Length; i++)
                opponentArray.GetArrayElementAtIndex(i).objectReferenceValue = opponents[i];
            flowSerialized.ApplyModifiedPropertiesWithoutUndo();
            var wake = systems.AddComponent<ScreenWakeController>();
            var wakeSerialized = new SerializedObject(wake);
            wakeSerialized.FindProperty("coordinator").objectReferenceValue = coordinator;
            wakeSerialized.FindProperty("flow").objectReferenceValue = flow;
            wakeSerialized.ApplyModifiedPropertiesWithoutUndo();
            var calibration = systems.AddComponent<ThrowCalibrationController>();
            var calibrationSerialized = new SerializedObject(calibration);
            calibrationSerialized.FindProperty("gestureReader").objectReferenceValue = gesture;
            calibrationSerialized.FindProperty("throwMapper").objectReferenceValue = mapper;
            calibrationSerialized.ApplyModifiedPropertiesWithoutUndo();
            var feedback = systems.AddComponent<ThrowFeedbackController>();
            var feedbackSerialized = new SerializedObject(feedback);
            feedbackSerialized.FindProperty("coordinator").objectReferenceValue = coordinator;
            feedbackSerialized.FindProperty("gameCamera").objectReferenceValue = gameCamera;
            feedbackSerialized.ApplyModifiedPropertiesWithoutUndo();
            var progress = systems.AddComponent<PlayerProgressController>();
            var progressSerialized = new SerializedObject(progress);
            progressSerialized.FindProperty("coordinator").objectReferenceValue = coordinator;
            progressSerialized.FindProperty("flow").objectReferenceValue = flow;
            progressSerialized.ApplyModifiedPropertiesWithoutUndo();
            flowSerialized = new SerializedObject(flow);
            flowSerialized.FindProperty("progress").objectReferenceValue = progress;
            flowSerialized.ApplyModifiedPropertiesWithoutUndo();
            CreateHud(flow, coordinator, calibration, progress, feedback, gesture, alternativeInput, target, gameCamera, opponents, playerRig.Animator, ninjaRig.Reaction);

            var path = GeneratedRoot + "/Prototype.unity";
            EditorSceneManager.SaveScene(scene, path);
            EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(path, true) };
            AssetDatabase.SaveAssets();
            Selection.activeObject = systems;
            Debug.Log("SHINOBI ZERO prototype created: " + path);
        }

        private static Camera CreateCamera()
        {
            var cameraObject = new GameObject("Main Camera", typeof(Camera), typeof(AudioListener));
            cameraObject.tag = "MainCamera";
            cameraObject.transform.SetPositionAndRotation(new Vector3(0, 0, -8), Quaternion.identity);
            var camera = cameraObject.GetComponent<Camera>();
            camera.fieldOfView = 44f;
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = new Color(.012f, .018f, .022f);
            return camera;
        }

        private static Light CreateLighting()
        {
            var moon = new GameObject("Moon Light", typeof(Light));
            moon.transform.rotation = Quaternion.Euler(35, -30, 0);
            var light = moon.GetComponent<Light>();
            light.type = LightType.Directional;
            light.color = new Color(.55f, .68f, .82f);
            light.intensity = 1.35f;
            light.shadows = LightShadows.Soft;

            var lantern = new GameObject("Lantern Light", typeof(Light));
            lantern.transform.position = new Vector3(-2.5f, 1f, -1f);
            var warm = lantern.GetComponent<Light>();
            warm.type = LightType.Point;
            warm.color = new Color(1f, .35f, .12f);
            warm.range = 7f;
            warm.intensity = 5f;
            return light;
        }

        private static void CreateEnvironment()
        {
            var cedar = CreateMaterial("Cedar", new Color(.055f, .038f, .03f), .18f, .05f);
            var wall = GameObject.CreatePrimitive(PrimitiveType.Cube);
            wall.name = "Wet Cedar Wall";
            wall.transform.position = new Vector3(0, 0, .5f);
            wall.transform.localScale = new Vector3(12, 8, .25f);
            wall.GetComponent<Renderer>().sharedMaterial = cedar;

            var floor = GameObject.CreatePrimitive(PrimitiveType.Plane);
            floor.name = "Stone Floor";
            floor.transform.position = new Vector3(0, -2.5f, -1f);
            floor.transform.localScale = new Vector3(1.2f, 1, 1.2f);
            floor.GetComponent<Renderer>().sharedMaterial = CreateMaterial("Wet Stone", new Color(.025f, .035f, .04f), .72f, .65f);

            CreateDojoFrame(cedar);
            CreateLanternFixture();
            CreateFloorPuddles();
        }

        private static void CreateDojoFrame(Material cedar)
        {
            var frame = new GameObject("Weathered Dojo Frame").transform;
            foreach (var x in new[] { -3.35f, 3.35f })
                CreateEnvironmentPrimitive("Cedar Pillar", PrimitiveType.Cube, frame, new Vector3(x, -.15f, .15f), new Vector3(.28f, 4.7f, .32f), cedar);
            CreateEnvironmentPrimitive("Cedar Crossbeam", PrimitiveType.Cube, frame, new Vector3(0f, 2.17f, .15f), new Vector3(7.05f, .32f, .36f), cedar);
            for (var x = -2.7f; x <= 2.7f; x += .9f)
                CreateEnvironmentPrimitive("Vertical Cedar Slat", PrimitiveType.Cube, frame, new Vector3(x, 0f, .32f), new Vector3(.055f, 3.8f, .09f), cedar);
        }

        private static void CreateLanternFixture()
        {
            var root = new GameObject("Weathered Iron Lantern").transform;
            root.localPosition = new Vector3(-2.55f, 1.05f, -.5f);
            var iron = CreateMaterial("Lantern Iron", new Color(.045f, .04f, .035f), .82f, .28f);
            var glow = CreateMaterial("Lantern Paper", new Color(.9f, .24f, .06f), .05f, .52f);
            CreateEnvironmentPrimitive("Lantern Body", PrimitiveType.Cylinder, root, Vector3.zero, new Vector3(.28f, .42f, .28f), glow);
            CreateEnvironmentPrimitive("Lantern Cap", PrimitiveType.Cylinder, root, new Vector3(0f, .47f, 0f), new Vector3(.36f, .055f, .36f), iron);
            CreateEnvironmentPrimitive("Lantern Base", PrimitiveType.Cylinder, root, new Vector3(0f, -.47f, 0f), new Vector3(.36f, .055f, .36f), iron);
            for (var side = -1; side <= 1; side += 2)
                CreateEnvironmentPrimitive("Lantern Guard", PrimitiveType.Cube, root, new Vector3(side * .29f, 0f, 0f), new Vector3(.035f, .9f, .035f), iron);
        }

        private static void CreateFloorPuddles()
        {
            var puddle = CreateMaterial("Rain Puddle", new Color(.035f, .075f, .09f), .55f, .92f);
            var root = new GameObject("Rain Puddles").transform;
            var positions = new[] { new Vector3(-2.1f, -2.47f, -2.2f), new Vector3(1.65f, -2.47f, -1.3f), new Vector3(.25f, -2.47f, 1.2f) };
            var scales = new[] { new Vector3(.16f, 1f, .07f), new Vector3(.11f, 1f, .05f), new Vector3(.14f, 1f, .06f) };
            for (var i = 0; i < positions.Length; i++)
                CreateEnvironmentPrimitive("Shallow Reflection Puddle", PrimitiveType.Plane, root, positions[i], scales[i], puddle);
        }

        private static Transform CreateEnvironmentPrimitive(string name, PrimitiveType type, Transform parent,
            Vector3 position, Vector3 scale, Material material)
        {
            var part = GameObject.CreatePrimitive(type);
            Object.DestroyImmediate(part.GetComponent<Collider>());
            part.name = name;
            part.transform.SetParent(parent, false);
            part.transform.localPosition = position;
            part.transform.localScale = scale;
            part.GetComponent<Renderer>().sharedMaterial = material;
            return part.transform;
        }

        private static ParticleSystem CreateRainAtmosphere()
        {
            var rainObject = new GameObject("Cold Rain", typeof(ParticleSystem));
            rainObject.transform.position = new Vector3(0f, 4.5f, -2f);
            var rain = rainObject.GetComponent<ParticleSystem>();
            var main = rain.main;
            main.loop = true;
            main.startLifetime = 1.35f;
            main.startSpeed = 0f;
            main.startSize = .018f;
            main.maxParticles = 520;
            main.simulationSpace = ParticleSystemSimulationSpace.World;
            main.startColor = new Color(.56f, .7f, .78f, .26f);
            var emission = rain.emission;
            emission.rateOverTime = 190f;
            var shape = rain.shape;
            shape.shapeType = ParticleSystemShapeType.Box;
            shape.scale = new Vector3(8f, .2f, 5f);
            var velocity = rain.velocityOverLifetime;
            velocity.enabled = true;
            velocity.x = new ParticleSystem.MinMaxCurve(.55f);
            velocity.y = new ParticleSystem.MinMaxCurve(-8.5f);
            var renderer = rain.GetComponent<ParticleSystemRenderer>();
            renderer.renderMode = ParticleSystemRenderMode.Stretch;
            renderer.velocityScale = .08f;
            renderer.lengthScale = 7f;
            renderer.sharedMaterial = CreateRainMaterial();
            return rain;
        }

        private static Material CreateRainMaterial()
        {
            var path = GeneratedRoot + "/Rain Streak.mat";
            var existing = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (existing != null) return existing;
            var shader = Shader.Find("Particles/Standard Unlit") ?? Shader.Find("Universal Render Pipeline/Particles/Unlit") ?? Shader.Find("Unlit/Color");
            var material = new Material(shader) { name = "Rain Streak", color = new Color(.56f, .7f, .78f, .24f) };
            AssetDatabase.CreateAsset(material, path);
            return material;
        }

        private static TargetBoard CreateTarget()
        {
            var board = new GameObject("Competition Target", typeof(BoxCollider));
            board.name = "Competition Target";
            board.GetComponent<BoxCollider>().size = new Vector3(2f, 2f, .14f);

            var backing = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            backing.name = "Round Bound Straw Backing";
            backing.transform.SetParent(board.transform, false);
            backing.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
            backing.transform.localScale = new Vector3(2.12f, .07f, 2.12f);
            Object.DestroyImmediate(backing.GetComponent<Collider>());
            backing.GetComponent<Renderer>().sharedMaterial = CreateMaterial("Target Wood", new Color(.14f, .075f, .04f), .22f, .12f);
            CreateDartboardSurface(board.transform);
            var target = board.AddComponent<TargetBoard>();
            var serialized = new SerializedObject(target);
            serialized.FindProperty("scoringRadius").floatValue = 1f;
            serialized.FindProperty("surfaceLocalZ").floatValue = -.071f;
            serialized.ApplyModifiedPropertiesWithoutUndo();
            return target;
        }

        private static void CreateDartboardSurface(Transform board)
        {
            var surface = new GameObject("Regulation Scoring Surface", typeof(MeshFilter), typeof(MeshRenderer));
            surface.transform.SetParent(board, false);
            var vertices = new List<Vector3>();
            var triangles = new[] { new List<int>(), new List<int>(), new List<int>(), new List<int>() };
            AddRing(vertices, triangles, (float)DartboardGeometry.OuterBullRadius, (float)DartboardGeometry.TripleInnerRadius, false);
            AddRing(vertices, triangles, (float)DartboardGeometry.TripleInnerRadius, (float)DartboardGeometry.TripleOuterRadius, true);
            AddRing(vertices, triangles, (float)DartboardGeometry.TripleOuterRadius, (float)DartboardGeometry.DoubleInnerRadius, false);
            AddRing(vertices, triangles, (float)DartboardGeometry.DoubleInnerRadius, 1f, true);
            AddSolidRing(vertices, triangles[2], 0f, (float)DartboardGeometry.InnerBullRadius);
            AddSolidRing(vertices, triangles[3], (float)DartboardGeometry.InnerBullRadius, (float)DartboardGeometry.OuterBullRadius);

            var mesh = new Mesh { name = "Regulation Dartboard Mesh", subMeshCount = 4 };
            mesh.SetVertices(vertices);
            for (var i = 0; i < triangles.Length; i++) mesh.SetTriangles(triangles[i], i);
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();
            surface.GetComponent<MeshFilter>().sharedMesh = mesh;
            surface.GetComponent<MeshRenderer>().sharedMaterials = new[]
            {
                CreateMaterial("Board Black", new Color(.035f, .038f, .035f), .05f, .16f),
                CreateMaterial("Board Sisal", new Color(.68f, .61f, .46f), .03f, .12f),
                CreateMaterial("Board Red", new Color(.48f, .035f, .025f), .04f, .16f),
                CreateMaterial("Board Green", new Color(.025f, .27f, .16f), .04f, .16f)
            };

            CreateDartboardWires(board);

            for (var i = 0; i < DartboardGeometry.ClockwiseNumbers.Length; i++)
            {
                var angle = i * Mathf.PI / 10f;
                var number = new GameObject("Number " + DartboardGeometry.ClockwiseNumbers[i], typeof(TextMesh));
                number.transform.SetParent(board, false);
                number.transform.localPosition = new Vector3(Mathf.Sin(angle) * 1.17f, Mathf.Cos(angle) * 1.17f, -.076f);
                var text = number.GetComponent<TextMesh>();
                text.text = DartboardGeometry.ClockwiseNumbers[i].ToString();
                text.anchor = TextAnchor.MiddleCenter;
                text.alignment = TextAlignment.Center;
                text.fontSize = 64;
                text.characterSize = .036f;
                text.color = new Color(.78f, .76f, .68f);
            }
        }

        private static void CreateDartboardWires(Transform board)
        {
            var wireRoot = new GameObject("Regulation Spider Wires").transform;
            wireRoot.SetParent(board, false);
            var wire = CreateMaterial("Board Wire", new Color(.35f, .38f, .37f), .9f, .55f);
            foreach (var radius in new[]
            {
                (float)DartboardGeometry.InnerBullRadius,
                (float)DartboardGeometry.OuterBullRadius,
                (float)DartboardGeometry.TripleInnerRadius,
                (float)DartboardGeometry.TripleOuterRadius,
                (float)DartboardGeometry.DoubleInnerRadius,
                1f
            })
            {
                var ring = new GameObject("Wire Ring", typeof(LineRenderer)).GetComponent<LineRenderer>();
                ring.transform.SetParent(wireRoot, false);
                ring.useWorldSpace = false;
                ring.loop = true;
                ring.positionCount = 80;
                ring.widthMultiplier = .008f;
                ring.sharedMaterial = wire;
                for (var i = 0; i < ring.positionCount; i++)
                {
                    var angle = i * Mathf.PI * 2f / ring.positionCount;
                    ring.SetPosition(i, new Vector3(Mathf.Sin(angle) * radius, Mathf.Cos(angle) * radius, -.074f));
                }
            }

            for (var sector = 0; sector < 20; sector++)
            {
                var angle = sector * Mathf.PI / 10f - Mathf.PI / 20f;
                var spoke = new GameObject("Sector Wire", typeof(LineRenderer)).GetComponent<LineRenderer>();
                spoke.transform.SetParent(wireRoot, false);
                spoke.useWorldSpace = false;
                spoke.positionCount = 2;
                spoke.widthMultiplier = .007f;
                spoke.sharedMaterial = wire;
                spoke.SetPosition(0, new Vector3(Mathf.Sin(angle) * (float)DartboardGeometry.OuterBullRadius, Mathf.Cos(angle) * (float)DartboardGeometry.OuterBullRadius, -.074f));
                spoke.SetPosition(1, new Vector3(Mathf.Sin(angle), Mathf.Cos(angle), -.074f));
            }
        }

        private static void AddRing(List<Vector3> vertices, List<int>[] triangles, float innerNormalized, float outerNormalized, bool premium)
        {
            for (var sector = 0; sector < 20; sector++)
            {
                var material = premium ? (sector % 2 == 0 ? 2 : 3) : (sector % 2 == 0 ? 0 : 1);
                AddWedge(vertices, triangles[material], innerNormalized, outerNormalized, sector);
            }
        }

        private static void AddSolidRing(List<Vector3> vertices, List<int> triangles, float innerNormalized, float outerNormalized)
        {
            for (var sector = 0; sector < 20; sector++) AddWedge(vertices, triangles, innerNormalized, outerNormalized, sector);
        }

        private static void AddWedge(List<Vector3> vertices, List<int> triangles, float innerNormalized, float outerNormalized, int sector)
        {
            const float localRadius = 1f;
            var start = sector * Mathf.PI / 10f - Mathf.PI / 20f;
            var end = start + Mathf.PI / 10f;
            var first = vertices.Count;
            vertices.Add(BoardVertex(innerNormalized * localRadius, start));
            vertices.Add(BoardVertex(outerNormalized * localRadius, start));
            vertices.Add(BoardVertex(outerNormalized * localRadius, end));
            vertices.Add(BoardVertex(innerNormalized * localRadius, end));
            triangles.Add(first); triangles.Add(first + 1); triangles.Add(first + 2);
            triangles.Add(first); triangles.Add(first + 2); triangles.Add(first + 3);
        }

        private static Vector3 BoardVertex(float radius, float angle) =>
            new Vector3(Mathf.Sin(angle) * radius, Mathf.Cos(angle) * radius, -.072f);

        private struct NinjaRig
        {
            public NinjaThrowAnimator Animator;
            public NinjaVisualController Visual;
            public NinjaReactionController Reaction;
            public Transform ReleasePoint;
        }

        private struct PlayerRig
        {
            public FirstPersonThrowAnimator Animator;
            public Transform ReleasePoint;
        }

        private static PlayerRig CreateFirstPersonThrowRig()
        {
            var cloth = CreateMaterial("Player Shinobi Sleeve", new Color(.018f, .022f, .024f), .14f, .22f);
            var glove = CreateMaterial("Player Wrapped Glove", new Color(.045f, .048f, .045f), .08f, .28f);
            var metal = CreateMaterial("Shuriken Steel", new Color(.28f, .32f, .34f), .9f, .72f);
            var root = new GameObject("Player First Person Arm");
            root.transform.position = new Vector3(.86f, -1.52f, -5.65f);

            var shoulder = new GameObject("Player Shoulder").transform;
            shoulder.SetParent(root.transform, false);
            var upper = CreateRigPrimitive("Player Sleeve", PrimitiveType.Capsule, shoulder, new Vector3(-.24f, .03f, 0f), new Vector3(.15f, .32f, .15f), cloth);
            upper.localRotation = Quaternion.Euler(0f, 0f, 90f);

            var elbow = new GameObject("Player Elbow").transform;
            elbow.SetParent(shoulder, false);
            elbow.localPosition = new Vector3(-.48f, .06f, .03f);
            var forearm = CreateRigPrimitive("Player Forearm", PrimitiveType.Capsule, elbow, new Vector3(-.22f, .02f, 0f), new Vector3(.13f, .29f, .13f), cloth);
            forearm.localRotation = Quaternion.Euler(0f, 0f, 90f);

            var wrist = new GameObject("Player Wrist").transform;
            wrist.SetParent(elbow, false);
            wrist.localPosition = new Vector3(-.45f, .05f, .025f);
            CreateRigPrimitive("Player Throw Hand", PrimitiveType.Sphere, wrist, new Vector3(-.08f, 0f, 0f), new Vector3(.16f, .12f, .11f), glove);

            var release = new GameObject("Player First Person Release").transform;
            release.SetParent(wrist, false);
            release.localPosition = new Vector3(-.16f, .02f, .055f);
            release.localRotation = Quaternion.identity;

            var held = CreateHeldShuriken("Held Four Point Shuriken", release, metal, .82f);

            var animator = root.AddComponent<FirstPersonThrowAnimator>();
            var serialized = new SerializedObject(animator);
            serialized.FindProperty("shoulder").objectReferenceValue = shoulder;
            serialized.FindProperty("elbow").objectReferenceValue = elbow;
            serialized.FindProperty("wrist").objectReferenceValue = wrist;
            serialized.FindProperty("heldShuriken").objectReferenceValue = held;
            serialized.ApplyModifiedPropertiesWithoutUndo();
            root.SetActive(false);
            return new PlayerRig { Animator = animator, ReleasePoint = release };
        }

        private static NinjaRig CreateProceduralNinja(ThrowAnimationProfile defaultProfile)
        {
            var cloth = CreateMaterial("Ninja Charcoal Cloth", new Color(.025f, .03f, .032f), .08f, .2f);
            var armor = CreateMaterial("Ninja Iron Plates", new Color(.095f, .11f, .115f), .72f, .38f);
            var shurikenSteel = CreateMaterial("Shuriken Steel", new Color(.28f, .32f, .34f), .9f, .72f);
            var skin = CreateMaterial("Ninja Skin", new Color(.38f, .24f, .17f), .02f, .24f);
            var root = new GameObject("Procedural Throwing Ninja");
            root.transform.position = new Vector3(-1.25f, -1.55f, -1.15f);
            var clothRenderers = new List<Renderer>();
            var accentRenderers = new List<Renderer>();

            var torso = CreateRigPrimitive("Torso", PrimitiveType.Capsule, root.transform, new Vector3(0f, .78f, 0f), new Vector3(.48f, .55f, .3f), cloth);
            clothRenderers.Add(torso.GetComponent<Renderer>());
            var chest = CreateRigPrimitive("Chest Plates", PrimitiveType.Cube, torso, new Vector3(0f, .08f, -.31f), new Vector3(.62f, .5f, .08f), armor);
            accentRenderers.Add(chest.GetComponent<Renderer>());
            var head = CreateRigPrimitive("Hooded Head", PrimitiveType.Sphere, root.transform, new Vector3(0f, 1.55f, 0f), new Vector3(.42f, .46f, .4f), cloth);
            clothRenderers.Add(head.GetComponent<Renderer>());
            CreateRigPrimitive("Face Opening", PrimitiveType.Cube, head, new Vector3(0f, -.02f, -.48f), new Vector3(.58f, .18f, .04f), skin);
            var mask = CreateRigPrimitive("Mask", PrimitiveType.Cube, head, new Vector3(0f, -.22f, -.5f), new Vector3(.62f, .22f, .045f), armor);
            accentRenderers.Add(mask.GetComponent<Renderer>());
            var leftLeg = CreateRigPrimitive("Left Leg", PrimitiveType.Capsule, root.transform, new Vector3(-.2f, .02f, 0f), new Vector3(.22f, .55f, .22f), cloth);
            var rightLeg = CreateRigPrimitive("Right Leg", PrimitiveType.Capsule, root.transform, new Vector3(.2f, .02f, 0f), new Vector3(.22f, .55f, .22f), cloth);
            clothRenderers.Add(leftLeg.GetComponent<Renderer>());
            clothRenderers.Add(rightLeg.GetComponent<Renderer>());

            var shoulder = new GameObject("Throw Shoulder Pivot").transform;
            shoulder.SetParent(root.transform, false);
            shoulder.localPosition = new Vector3(.34f, 1.15f, -.05f);
            var upperArm = CreateRigPrimitive("Upper Throw Arm", PrimitiveType.Capsule, shoulder, new Vector3(.22f, 0f, 0f), new Vector3(.14f, .29f, .14f), cloth);
            upperArm.localRotation = Quaternion.Euler(0f, 0f, 90f);
            clothRenderers.Add(upperArm.GetComponent<Renderer>());
            var elbow = new GameObject("Throw Elbow Pivot").transform;
            elbow.SetParent(shoulder, false);
            elbow.localPosition = new Vector3(.46f, 0f, 0f);
            var lowerArm = CreateRigPrimitive("Lower Throw Arm", PrimitiveType.Capsule, elbow, new Vector3(.21f, 0f, 0f), new Vector3(.125f, .27f, .125f), cloth);
            lowerArm.localRotation = Quaternion.Euler(0f, 0f, 90f);
            clothRenderers.Add(lowerArm.GetComponent<Renderer>());
            var wrist = new GameObject("Throw Wrist Pivot").transform;
            wrist.SetParent(elbow, false);
            wrist.localPosition = new Vector3(.43f, 0f, 0f);
            CreateRigPrimitive("Throw Hand", PrimitiveType.Sphere, wrist, new Vector3(.07f, 0f, 0f), new Vector3(.15f, .12f, .12f), skin);
            var release = new GameObject("Shuriken Release").transform;
            release.SetParent(wrist, false);
            release.localPosition = new Vector3(.14f, 0f, -.08f);
            var heldEnemyShuriken = CreateHeldShuriken("Enemy Held Shuriken", release, shurikenSteel, .68f);

            var styleAccessories = CreateNinjaStyleAccessories(root.transform, head, torso, armor, cloth, accentRenderers);

            var animator = root.AddComponent<NinjaThrowAnimator>();
            var serialized = new SerializedObject(animator);
            serialized.FindProperty("profile").objectReferenceValue = defaultProfile;
            serialized.FindProperty("torso").objectReferenceValue = torso;
            serialized.FindProperty("shoulder").objectReferenceValue = shoulder;
            serialized.FindProperty("elbow").objectReferenceValue = elbow;
            serialized.FindProperty("wrist").objectReferenceValue = wrist;
            serialized.FindProperty("heldShuriken").objectReferenceValue = heldEnemyShuriken;
            serialized.ApplyModifiedPropertiesWithoutUndo();
            var visual = root.AddComponent<NinjaVisualController>();
            var visualSerialized = new SerializedObject(visual);
            AssignArray(visualSerialized.FindProperty("clothRenderers"), clothRenderers.ToArray());
            AssignArray(visualSerialized.FindProperty("accentRenderers"), accentRenderers.ToArray());
            visualSerialized.FindProperty("characterRoot").objectReferenceValue = root.transform;
            AssignArray(visualSerialized.FindProperty("styleAccessories"), styleAccessories);
            visualSerialized.ApplyModifiedPropertiesWithoutUndo();
            var reaction = root.AddComponent<NinjaReactionController>();
            var reactionSerialized = new SerializedObject(reaction);
            reactionSerialized.FindProperty("throwAnimator").objectReferenceValue = animator;
            reactionSerialized.FindProperty("characterRoot").objectReferenceValue = root.transform;
            reactionSerialized.FindProperty("torso").objectReferenceValue = torso;
            reactionSerialized.FindProperty("head").objectReferenceValue = head;
            reactionSerialized.ApplyModifiedPropertiesWithoutUndo();
            return new NinjaRig { Animator = animator, Visual = visual, Reaction = reaction, ReleasePoint = release };
        }

        private static GameObject CreateHeldShuriken(string name, Transform parent, Material metal, float scale)
        {
            var held = new GameObject(name);
            held.transform.SetParent(parent, false);
            held.transform.localRotation = Quaternion.Euler(0f, 0f, 18f);
            held.transform.localScale = Vector3.one * scale;

            var blade = new GameObject("Forged Blades", typeof(MeshFilter), typeof(MeshRenderer));
            blade.transform.SetParent(held.transform, false);
            blade.GetComponent<MeshFilter>().sharedMesh = CreateShurikenMesh();
            blade.GetComponent<MeshRenderer>().sharedMaterial = metal;

            var hub = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            Object.DestroyImmediate(hub.GetComponent<Collider>());
            hub.name = "Raised Hub";
            hub.transform.SetParent(held.transform, false);
            hub.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
            hub.transform.localScale = new Vector3(.078f, .014f, .078f);
            hub.GetComponent<Renderer>().sharedMaterial = metal;

            var recess = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            Object.DestroyImmediate(recess.GetComponent<Collider>());
            recess.name = "Dark Finger Recess";
            recess.transform.SetParent(held.transform, false);
            recess.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
            recess.transform.localPosition = new Vector3(0f, 0f, -.016f);
            recess.transform.localScale = new Vector3(.038f, .016f, .038f);
            recess.GetComponent<Renderer>().sharedMaterial = CreateMaterial("Shuriken Recess", new Color(.012f, .014f, .014f), .15f, .1f);
            return held;
        }

        private static GameObject[] CreateNinjaStyleAccessories(Transform root, Transform head, Transform torso,
            Material armor, Material cloth, List<Renderer> accentRenderers)
        {
            var styles = new GameObject[5];

            styles[0] = new GameObject("Kagero Rookie Sash");
            styles[0].transform.SetParent(root, false);
            var sash = CreateRigPrimitive("Plain Waist Sash", PrimitiveType.Cylinder, styles[0].transform,
                new Vector3(0f, .55f, 0f), new Vector3(.39f, .055f, .27f), cloth);
            accentRenderers.Add(sash.GetComponent<Renderer>());

            styles[1] = new GameObject("Shigure Scout Hood Tails");
            styles[1].transform.SetParent(head, false);
            for (var side = -1; side <= 1; side += 2)
            {
                var tail = CreateRigPrimitive("Wind Hood Tail", PrimitiveType.Cube, styles[1].transform,
                    new Vector3(side * .34f, .15f, .18f), new Vector3(.09f, .42f, .035f), cloth);
                tail.localRotation = Quaternion.Euler(0f, 0f, side * 24f);
                accentRenderers.Add(tail.GetComponent<Renderer>());
            }

            styles[2] = new GameObject("Yasha Armored Shoulders");
            styles[2].transform.SetParent(torso, false);
            for (var side = -1; side <= 1; side += 2)
            {
                var guard = CreateRigPrimitive("Layered Shoulder Guard", PrimitiveType.Cube, styles[2].transform,
                    new Vector3(side * .7f, .38f, -.04f), new Vector3(.28f, .13f, .42f), armor);
                guard.localRotation = Quaternion.Euler(0f, 0f, side * 12f);
                accentRenderers.Add(guard.GetComponent<Renderer>());
            }

            styles[3] = new GameObject("Genma Veteran Back Blades");
            styles[3].transform.SetParent(torso, false);
            for (var side = -1; side <= 1; side += 2)
            {
                var scabbard = CreateRigPrimitive("Back Scabbard", PrimitiveType.Cube, styles[3].transform,
                    new Vector3(side * .25f, .05f, .38f), new Vector3(.08f, .78f, .08f), armor);
                scabbard.localRotation = Quaternion.Euler(side * 7f, 0f, side * 25f);
                accentRenderers.Add(scabbard.GetComponent<Renderer>());
            }

            styles[4] = new GameObject("Mukuro Shadow Crest");
            styles[4].transform.SetParent(head, false);
            var crest = CreateRigPrimitive("Shadow Forehead Crest", PrimitiveType.Cube, styles[4].transform,
                new Vector3(0f, .47f, -.18f), new Vector3(.08f, .25f, .06f), armor);
            crest.localRotation = Quaternion.Euler(0f, 0f, 45f);
            accentRenderers.Add(crest.GetComponent<Renderer>());

            for (var i = 0; i < styles.Length; i++) styles[i].SetActive(false);
            return styles;
        }

        private static Transform CreateRigPrimitive(string name, PrimitiveType type, Transform parent, Vector3 localPosition, Vector3 localScale, Material material)
        {
            var part = GameObject.CreatePrimitive(type);
            Object.DestroyImmediate(part.GetComponent<Collider>());
            part.name = name;
            part.transform.SetParent(parent, false);
            part.transform.localPosition = localPosition;
            part.transform.localScale = localScale;
            part.GetComponent<Renderer>().sharedMaterial = material;
            return part.transform;
        }

        private static ShurikenProjectile CreateShurikenPrefab()
        {
            var root = new GameObject("Shuriken");
            var rigidbody = root.AddComponent<Rigidbody>();
            rigidbody.useGravity = true;
            rigidbody.collisionDetectionMode = CollisionDetectionMode.ContinuousDynamic;
            rigidbody.interpolation = RigidbodyInterpolation.Interpolate;
            rigidbody.maxAngularVelocity = 40f;
            var collider = root.AddComponent<BoxCollider>();
            collider.size = new Vector3(.44f, .44f, .028f);
            var metal = CreateMaterial("Shuriken Steel", new Color(.28f, .32f, .34f), .9f, .72f);
            var blade = new GameObject("Four Point Forged Blades", typeof(MeshFilter), typeof(MeshRenderer));
            blade.transform.SetParent(root.transform, false);
            blade.GetComponent<MeshFilter>().sharedMesh = CreateShurikenMesh();
            blade.GetComponent<MeshRenderer>().sharedMaterial = metal;

            var hub = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            Object.DestroyImmediate(hub.GetComponent<Collider>());
            hub.name = "Forged Hub";
            hub.transform.SetParent(root.transform, false);
            hub.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
            hub.transform.localScale = new Vector3(.078f, .014f, .078f);
            hub.GetComponent<Renderer>().sharedMaterial = metal;

            var hole = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            Object.DestroyImmediate(hole.GetComponent<Collider>());
            hole.name = "Lacing Hole";
            hole.transform.SetParent(root.transform, false);
            hole.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
            hole.transform.localPosition = new Vector3(0f, 0f, -.017f);
            hole.transform.localScale = new Vector3(.027f, .004f, .027f);
            hole.GetComponent<Renderer>().sharedMaterial = CreateMaterial("Shuriken Recess", new Color(.012f, .014f, .014f), .15f, .1f);
            var projectile = root.AddComponent<ShurikenProjectile>();
            var path = GeneratedRoot + "/Shuriken.prefab";
            var prefab = PrefabUtility.SaveAsPrefabAsset(root, path).GetComponent<ShurikenProjectile>();
            Object.DestroyImmediate(root);
            return prefab;
        }

        private static Mesh CreateShurikenMesh()
        {
            var vertices = new List<Vector3>();
            var triangles = new List<int>();
            const float halfDepth = .012f;
            for (var blade = 0; blade < 4; blade++)
            {
                var angle = blade * Mathf.PI * .5f;
                var radial = new Vector2(Mathf.Sin(angle), Mathf.Cos(angle));
                var tangent = new Vector2(Mathf.Cos(angle), -Mathf.Sin(angle));
                var outline = new[]
                {
                    radial * .05f - tangent * .035f,
                    radial * .135f - tangent * .052f,
                    radial * .225f,
                    radial * .135f + tangent * .052f,
                    radial * .05f + tangent * .035f
                };
                var first = vertices.Count;
                for (var i = 0; i < outline.Length; i++) vertices.Add(new Vector3(outline[i].x, outline[i].y, -halfDepth));
                for (var i = 0; i < outline.Length; i++) vertices.Add(new Vector3(outline[i].x, outline[i].y, halfDepth));
                for (var i = 1; i < outline.Length - 1; i++)
                {
                    triangles.Add(first); triangles.Add(first + i); triangles.Add(first + i + 1);
                    triangles.Add(first + 5); triangles.Add(first + 5 + i + 1); triangles.Add(first + 5 + i);
                }
                for (var i = 0; i < outline.Length; i++)
                {
                    var next = (i + 1) % outline.Length;
                    triangles.Add(first + i); triangles.Add(first + next); triangles.Add(first + 5 + next);
                    triangles.Add(first + i); triangles.Add(first + 5 + next); triangles.Add(first + 5 + i);
                }
            }
            var mesh = new Mesh { name = "Extruded Four Point Shuriken" };
            mesh.SetVertices(vertices);
            mesh.SetTriangles(triangles, 0);
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();
            return mesh;
        }

        private static ThrowMapper CreateThrowMapper()
        {
            var path = GeneratedRoot + "/Default Throw Tuning.asset";
            var existing = AssetDatabase.LoadAssetAtPath<ThrowMapper>(path);
            var mapper = existing != null ? existing : ScriptableObject.CreateInstance<ThrowMapper>();
            if (existing == null) AssetDatabase.CreateAsset(mapper, path);
            var serialized = new SerializedObject(mapper);
            serialized.FindProperty("horizontalSensitivity").floatValue = .32f;
            serialized.FindProperty("verticalSensitivity").floatValue = .24f;
            serialized.FindProperty("spinSensitivity").floatValue = 45f;
            serialized.ApplyModifiedPropertiesWithoutUndo();
            return mapper;
        }

        private static ThrowAnimationProfile[] CreateThrowAnimationProfiles()
        {
            var assetNames = new[] { "Kagero", "Shigure", "Yasha", "Genma", "Mukuro" };
            var releases = new[] { .64f, .60f, .58f, .66f, .63f };
            var durations = new[] { .88f, .72f, .56f, .78f, .62f };
            var windups = new[] { 62f, 48f, 72f, 38f, 44f };
            var followThrough = new[] { 58f, 70f, 92f, 52f, 76f };
            var profiles = new ThrowAnimationProfile[assetNames.Length];
            for (var i = 0; i < assetNames.Length; i++)
            {
                var path = GeneratedRoot + "/" + assetNames[i] + " Throw.asset";
                var profile = AssetDatabase.LoadAssetAtPath<ThrowAnimationProfile>(path);
                if (profile == null)
                {
                    profile = ScriptableObject.CreateInstance<ThrowAnimationProfile>();
                    AssetDatabase.CreateAsset(profile, path);
                }
                var serialized = new SerializedObject(profile);
                serialized.FindProperty("stateName").stringValue = "Throw_" + assetNames[i];
                serialized.FindProperty("releaseNormalizedTime").floatValue = releases[i];
                serialized.FindProperty("throwDuration").floatValue = durations[i];
                serialized.FindProperty("windupDegrees").floatValue = windups[i];
                serialized.FindProperty("followThroughDegrees").floatValue = followThrough[i];
                serialized.ApplyModifiedPropertiesWithoutUndo();
                profiles[i] = profile;
            }
            return profiles;
        }

        private static OpponentProfile[] CreateOpponentProfiles(ThrowAnimationProfile[] motionProfiles)
        {
            var assetNames = new[] { "Kagero", "Shigure", "Yasha", "Genma", "Mukuro" };
            var displayNames = new[] { "カゲロウ", "シグレ", "ヤシャ", "ゲンマ", "ムクロ" };
            var englishNames = new[] { "KAGERO", "SHIGURE", "YASHA", "GENMA", "MUKURO" };
            var titles = new[] { "見習い", "下忍", "中忍", "上忍", "影" };
            var englishTitles = new[] { "Apprentice", "Genin", "Chunin", "Jonin", "Shadow" };
            var styles = new[]
            {
                "19の安全策。投数が進むと乱れやすい。",
                "十八番は18。三投目に勝負をかける連投型。",
                "トリプル優先。速く攻撃的な投擲。",
                "三投先を読む戦術型。終盤にも強い。",
                "高精度の定石。プレッシャーでほぼ崩れない。"
            };
            var englishStyles = new[]
            {
                "Steady 19s. Accuracy fades late in each turn.",
                "Builds rhythm on 18, then attacks with the third throw.",
                "Triple-first aggression with a fast, violent release.",
                "Reads three throws ahead and thrives under pressure.",
                "Near-perfect routes. Pressure barely leaves a mark."
            };
            var outfitColors = new[]
            {
                new Color(.075f, .08f, .075f), new Color(.045f, .09f, .12f),
                new Color(.14f, .045f, .035f), new Color(.065f, .045f, .03f), new Color(.012f, .016f, .018f)
            };
            var accentColors = new[]
            {
                new Color(.18f, .19f, .17f), new Color(.12f, .24f, .31f),
                new Color(.38f, .075f, .045f), new Color(.23f, .15f, .075f), new Color(.34f, .37f, .38f)
            };
            var bodyScales = new[]
            {
                new Vector3(.94f, .96f, .94f), new Vector3(.98f, 1.02f, .96f),
                new Vector3(1.08f, 1.04f, 1.08f), new Vector3(1.03f, 1.08f, 1f), new Vector3(1f, 1.12f, .98f)
            };
            var profiles = new OpponentProfile[assetNames.Length];
            for (var i = 0; i < assetNames.Length; i++)
            {
                var path = GeneratedRoot + "/" + assetNames[i] + ".asset";
                var profile = AssetDatabase.LoadAssetAtPath<OpponentProfile>(path);
                if (profile == null)
                {
                    profile = ScriptableObject.CreateInstance<OpponentProfile>();
                    AssetDatabase.CreateAsset(profile, path);
                }
                var tuning = OpponentTuningCatalog.Get(i);
                var serialized = new SerializedObject(profile);
                serialized.FindProperty("displayName").stringValue = displayNames[i];
                serialized.FindProperty("englishDisplayName").stringValue = englishNames[i];
                serialized.FindProperty("title").stringValue = titles[i];
                serialized.FindProperty("englishTitle").stringValue = englishTitles[i];
                serialized.FindProperty("styleDescription").stringValue = styles[i];
                serialized.FindProperty("englishStyleDescription").stringValue = englishStyles[i];
                serialized.FindProperty("skill").floatValue = tuning.Skill;
                serialized.FindProperty("preferredBase").intValue = tuning.PreferredBase;
                serialized.FindProperty("thinkTime").floatValue = tuning.ThinkTime;
                serialized.FindProperty("aggression").floatValue = tuning.Aggression;
                serialized.FindProperty("pressureResistance").floatValue = tuning.PressureResistance;
                serialized.FindProperty("consistency").floatValue = tuning.Consistency;
                serialized.FindProperty("horizontalBias").floatValue = tuning.HorizontalBias;
                serialized.FindProperty("strategy").enumValueIndex = (int)tuning.Strategy;
                serialized.FindProperty("animationProfile").objectReferenceValue = motionProfiles[i];
                serialized.FindProperty("outfitColor").colorValue = outfitColors[i];
                serialized.FindProperty("accentColor").colorValue = accentColors[i];
                serialized.FindProperty("visualStyle").enumValueIndex = i;
                serialized.FindProperty("bodyScale").vector3Value = bodyScales[i];
                serialized.ApplyModifiedPropertiesWithoutUndo();
                profiles[i] = profile;
            }
            return profiles;
        }

        private static Material CreateMaterial(string name, Color color, float metallic, float smoothness)
        {
            var path = $"{GeneratedRoot}/{name}.mat";
            var existing = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (existing != null) return existing;
            var shader = Shader.Find("Standard") ?? Shader.Find("Universal Render Pipeline/Lit");
            var material = new Material(shader) { name = name, color = color };
            material.SetFloat("_Metallic", metallic);
            material.SetFloat("_Glossiness", smoothness);
            AssetDatabase.CreateAsset(material, path);
            return material;
        }

        private static void CreateHud(GameFlowController flow, MatchCoordinator coordinator, ThrowCalibrationController calibration, PlayerProgressController progress, ThrowFeedbackController feedback, ThrowGestureReader gesture, AlternativeThrowController alternativeInput, TargetBoard target, Camera gameCamera, OpponentProfile[] opponents, FirstPersonThrowAnimator playerThrowAnimator, NinjaReactionController ninjaReaction)
        {
            var canvasObject = new GameObject("iPhone HUD", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            var canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            var scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080, 1920);
            scaler.matchWidthOrHeight = .5f;
            var localization = canvasObject.AddComponent<UiLocalizationController>();

            var safeArea = new GameObject("Safe Area", typeof(RectTransform), typeof(SafeAreaFitter));
            safeArea.transform.SetParent(canvasObject.transform, false);
            Stretch(safeArea.GetComponent<RectTransform>());

            var selection = CreatePanel("Selection", safeArea.transform, Color.clear);
            var titleBackground = CreateTitleBackground(selection.transform);
            CreateText("Title", selection.transform, "SHINOBI\nZERO", 92, new Vector2(0, 610), new Vector2(900, 260), TextAnchor.MiddleLeft, new Color(.88f, .86f, .8f));
            CreateText("Subtitle", selection.transform, "手裏剣ダーツ　対戦相手を選択", 30, new Vector2(0, 425), new Vector2(900, 70), TextAnchor.MiddleLeft, new Color(.65f, .68f, .68f));

            var opponentButtons = new Button[opponents.Length];
            var opponentLabels = new Text[opponents.Length];
            var opponentLineup = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/ShinobiZero/Art/Title/title-background-landscape-v1.png");
            if (opponentLineup == null) throw new FileNotFoundException("Opponent lineup texture is missing.");
            for (var i = 0; i < opponents.Length; i++)
            {
                var x = -424f + i * 212f;
                opponentButtons[i] = CreateButton("Opponent " + i, selection.transform, opponents[i].DisplayName, new Vector2(x, 180), new Vector2(190, 230), out opponentLabels[i]);
                CreateOpponentPortrait(opponentButtons[i].transform, opponentLineup, i, opponents.Length);
                SetRect(opponentLabels[i].rectTransform, new Vector2(0, -55), new Vector2(174, 38));
                opponentLabels[i].fontSize = 25;
                opponentLabels[i].resizeTextMaxSize = 25;
                var rank = CreateText("Rank", opponentButtons[i].transform, OpponentDifficultyModel.Stars(opponents[i].Skill), 22, new Vector2(0, -91), new Vector2(174, 30), TextAnchor.MiddleCenter, new Color(.72f, .62f, .44f));
                rank.raycastTarget = false;
            }
            var opponentDetail = CreateText("Opponent Detail", selection.transform, "", 22, new Vector2(0, 18), new Vector2(940, 72), TextAnchor.MiddleCenter, new Color(.76f, .68f, .54f));

            CreateText("Rule Label", selection.transform, "開始点", 26, new Vector2(-420, -55), new Vector2(150, 60), TextAnchor.MiddleLeft, Color.white);
            var score301 = CreateButton("301", selection.transform, "301", new Vector2(-220, -55), new Vector2(180, 82), out _);
            var score501 = CreateButton("501", selection.transform, "501", new Vector2(-15, -55), new Vector2(180, 82), out _);
            var doubleToggle = CreateToggle("Double Out", selection.transform, "DOUBLE OUT", new Vector2(315, -55), new Vector2(330, 82));
            var singleLeg = CreateButton("Single Leg", selection.transform, "1 LEG", new Vector2(-190, -150), new Vector2(340, 70), out _);
            var bestOfThree = CreateButton("Best of Three", selection.transform, "BEST OF 3", new Vector2(190, -150), new Vector2(340, 70), out _);
            var career = CreateText("Career", selection.transform, "階級 見習い\n戦績 0勝 0敗", 22, new Vector2(0, -225), new Vector2(920, 78), TextAnchor.MiddleCenter, new Color(.72f, .72f, .68f));
            var calibrate = CreateButton("Calibrate", selection.transform, "投げ方を調整", new Vector2(0, -315), new Vector2(620, 82), out _);
            var replayTutorial = CreateButton("Replay Tutorial", selection.transform, "遊び方", new Vector2(-210, -420), new Vector2(330, 68), out _);
            var openSettings = CreateButton("Open Settings", selection.transform, "設定", new Vector2(210, -420), new Vector2(330, 68), out _);
            var quitGame = CreateButton("Quit Game", selection.transform, "終了", new Vector2(450, -420), new Vector2(150, 68), out _);
            var start = CreateButton("Start", selection.transform, "対戦を始める", new Vector2(0, -555), new Vector2(900, 116), out _);
            var desktopQuit = canvasObject.AddComponent<DesktopQuitController>();
            var quitSerialized = new SerializedObject(desktopQuit);
            quitSerialized.FindProperty("quitButton").objectReferenceValue = quitGame;
            quitSerialized.FindProperty("progress").objectReferenceValue = progress;
            quitSerialized.ApplyModifiedPropertiesWithoutUndo();

            var match = CreatePanel("Match", safeArea.transform, Color.clear);
            var playerScore = CreateText("Player Score", match.transform, "301", 96, new Vector2(-280, 660), new Vector2(360, 145), TextAnchor.MiddleCenter, Color.white);
            var enemyScore = CreateText("Enemy Score", match.transform, "301", 96, new Vector2(280, 660), new Vector2(360, 145), TextAnchor.MiddleCenter, Color.white);
            var enemyName = CreateText("Enemy Name", match.transform, "カゲロウ", 26, new Vector2(280, 760), new Vector2(360, 52), TextAnchor.MiddleCenter, new Color(.72f, .72f, .68f));
            var round = CreateText("Round", match.transform, "ROUND 1", 28, new Vector2(0, 770), new Vector2(220, 52), TextAnchor.MiddleCenter, new Color(.72f, .72f, .68f));
            var legs = CreateText("Legs", match.transform, "LEG 1", 22, new Vector2(0, 710), new Vector2(180, 48), TextAnchor.MiddleCenter, new Color(.83f, .63f, .3f));
            var pauseButton = CreateButton("Pause", match.transform, "Ⅱ", new Vector2(460, 760), new Vector2(90, 70), out _);
            var turn = CreateText("Turn", match.transform, "あなたの番　残り3投", 34, new Vector2(0, 555), new Vector2(800, 70), TextAnchor.MiddleCenter, Color.white);
            var checkout = CreateText("Checkout", match.transform, "", 28, new Vector2(0, 485), new Vector2(850, 58), TextAnchor.MiddleCenter, new Color(.83f, .63f, .3f));
            var turnSummary = CreateText("Turn Summary", match.transform, "", 27, new Vector2(0, -545), new Vector2(920, 58), TextAnchor.MiddleCenter, new Color(.72f, .74f, .72f));
            var hit = CreateText("Hit", match.transform, "下から上へ払って投げる", 38, new Vector2(0, -660), new Vector2(900, 110), TextAnchor.MiddleCenter, Color.white);
            var reticle = CreateAimReticle(match.transform);
            var reticleController = canvasObject.AddComponent<AimReticleController>();
            var reticleSerialized = new SerializedObject(reticleController);
            reticleSerialized.FindProperty("gestureReader").objectReferenceValue = gesture;
            reticleSerialized.FindProperty("alternativeInput").objectReferenceValue = alternativeInput;
            reticleSerialized.FindProperty("coordinator").objectReferenceValue = coordinator;
            reticleSerialized.FindProperty("target").objectReferenceValue = target;
            reticleSerialized.FindProperty("aimCamera").objectReferenceValue = gameCamera;
            reticleSerialized.FindProperty("aimArea").objectReferenceValue = match.GetComponent<RectTransform>();
            reticleSerialized.FindProperty("reticle").objectReferenceValue = reticle;
            reticleSerialized.ApplyModifiedPropertiesWithoutUndo();

            var result = CreatePanel("Result", safeArea.transform, new Color(0, 0, 0, .84f));
            var resultTitle = CreateText("Result Title", result.transform, "勝利", 110, new Vector2(0, 180), new Vector2(800, 170), TextAnchor.MiddleCenter, Color.white);
            var resultDetail = CreateText("Result Detail", result.transform, "", 29, new Vector2(0, 25), new Vector2(900, 170), TextAnchor.MiddleCenter, new Color(.76f, .77f, .74f));
            var rematch = CreateButton("Rematch", result.transform, "再戦する", new Vector2(0, -160), new Vector2(720, 110), out _);
            var change = CreateButton("Change Opponent", result.transform, "相手を選び直す", new Vector2(0, -300), new Vector2(720, 92), out _);

            var calibrationPanel = CreatePanel("Throw Calibration", safeArea.transform, new Color(.01f, .015f, .018f, .97f));
            CreateText("Calibration Title", calibrationPanel.transform, "投げ方を調整", 72, new Vector2(0, 410), new Vector2(850, 120), TextAnchor.MiddleCenter, Color.white);
            CreateText("Calibration Guide", calibrationPanel.transform, "画面の下から上へ\n普段の強さで払ってください", 34, new Vector2(0, 160), new Vector2(820, 180), TextAnchor.MiddleCenter, new Color(.75f, .76f, .73f));
            var calibrationStatus = CreateText("Calibration Status", calibrationPanel.transform, "自然な速さで上へ3回払う", 42, new Vector2(0, -100), new Vector2(850, 100), TextAnchor.MiddleCenter, Color.white);
            var cancelCalibration = CreateButton("Cancel Calibration", calibrationPanel.transform, "戻る", new Vector2(0, -520), new Vector2(520, 92), out _);

            var tutorialPanel = CreatePanel("Tutorial", safeArea.transform, new Color(.008f, .012f, .015f, .98f));
            var tutorialStep = CreateText("Tutorial Step", tutorialPanel.transform, "1 / 3", 25, new Vector2(0, 600), new Vector2(300, 50), TextAnchor.MiddleCenter, new Color(.65f, .66f, .63f));
            var tutorialTitle = CreateText("Tutorial Title", tutorialPanel.transform, "手裏剣を投げる", 68, new Vector2(0, 390), new Vector2(900, 120), TextAnchor.MiddleCenter, Color.white);
            var tutorialGuide = CreateText("Tutorial Guide", tutorialPanel.transform, "", 34, new Vector2(0, 80), new Vector2(880, 300), TextAnchor.MiddleCenter, new Color(.8f, .81f, .78f));
            var tutorialNext = CreateButton("Tutorial Next", tutorialPanel.transform, "次へ", new Vector2(0, -390), new Vector2(720, 110), out _);
            var tutorialSkip = CreateButton("Tutorial Skip", tutorialPanel.transform, "スキップ", new Vector2(0, -540), new Vector2(420, 72), out _);
            var tutorial = canvasObject.AddComponent<TutorialController>();
            var tutorialSerialized = new SerializedObject(tutorial);
            tutorialSerialized.FindProperty("panel").objectReferenceValue = tutorialPanel;
            tutorialSerialized.FindProperty("stepText").objectReferenceValue = tutorialStep;
            tutorialSerialized.FindProperty("titleText").objectReferenceValue = tutorialTitle;
            tutorialSerialized.FindProperty("guideText").objectReferenceValue = tutorialGuide;
            tutorialSerialized.FindProperty("nextButton").objectReferenceValue = tutorialNext;
            tutorialSerialized.FindProperty("skipButton").objectReferenceValue = tutorialSkip;
            tutorialSerialized.FindProperty("replayButton").objectReferenceValue = replayTutorial;
            tutorialSerialized.FindProperty("localization").objectReferenceValue = localization;
            tutorialSerialized.ApplyModifiedPropertiesWithoutUndo();

            var settingsPanel = CreatePanel("Settings", safeArea.transform, new Color(.008f, .012f, .015f, .98f));
            CreateText("Settings Title", settingsPanel.transform, "設定", 72, new Vector2(0, 470), new Vector2(800, 120), TextAnchor.MiddleCenter, Color.white);
            var soundToggle = CreateToggle("Sound Setting", settingsPanel.transform, "効果音", new Vector2(0, 210), new Vector2(620, 82));
            var hapticsToggle = CreateToggle("Haptics Setting", settingsPanel.transform, "触覚フィードバック", new Vector2(0, 70), new Vector2(620, 82));
            var motionToggle = CreateToggle("Motion Setting", settingsPanel.transform, "カメラ反応を抑える", new Vector2(0, -70), new Vector2(620, 82));
            var fullscreenToggle = CreateToggle("Fullscreen Setting", settingsPanel.transform, "フルスクリーン", new Vector2(0, -210), new Vector2(620, 82));
            var englishToggle = CreateToggle("Language Setting", settingsPanel.transform, "英語UI", new Vector2(0, -330), new Vector2(620, 82));
            var closeSettings = CreateButton("Close Settings", settingsPanel.transform, "決定", new Vector2(0, -520), new Vector2(620, 100), out _);
            var settings = canvasObject.AddComponent<SettingsController>();
            var settingsSerialized = new SerializedObject(settings);
            settingsSerialized.FindProperty("panel").objectReferenceValue = settingsPanel;
            settingsSerialized.FindProperty("openButton").objectReferenceValue = openSettings;
            settingsSerialized.FindProperty("closeButton").objectReferenceValue = closeSettings;
            settingsSerialized.FindProperty("soundToggle").objectReferenceValue = soundToggle;
            settingsSerialized.FindProperty("hapticsToggle").objectReferenceValue = hapticsToggle;
            settingsSerialized.FindProperty("reducedMotionToggle").objectReferenceValue = motionToggle;
            settingsSerialized.FindProperty("englishToggle").objectReferenceValue = englishToggle;
            settingsSerialized.FindProperty("fullscreenToggle").objectReferenceValue = fullscreenToggle;
            settingsSerialized.FindProperty("feedback").objectReferenceValue = feedback;
            settingsSerialized.FindProperty("playerThrowAnimator").objectReferenceValue = playerThrowAnimator;
            settingsSerialized.FindProperty("ninjaReaction").objectReferenceValue = ninjaReaction;
            settingsSerialized.FindProperty("titleBackground").objectReferenceValue = titleBackground;
            settingsSerialized.FindProperty("localization").objectReferenceValue = localization;
            settingsSerialized.ApplyModifiedPropertiesWithoutUndo();

            var pausePanel = CreatePanel("Pause", safeArea.transform, new Color(.006f, .009f, .012f, .97f));
            CreateText("Pause Title", pausePanel.transform, "静止", 86, new Vector2(0, 250), new Vector2(800, 140), TextAnchor.MiddleCenter, Color.white);
            CreateText("Pause Guide", pausePanel.transform, "試合は止まっています", 30, new Vector2(0, 100), new Vector2(700, 70), TextAnchor.MiddleCenter, new Color(.7f, .71f, .68f));
            var resumeButton = CreateButton("Resume", pausePanel.transform, "試合へ戻る", new Vector2(0, -180), new Vector2(680, 110), out _);
            var exitMatchButton = CreateButton("Exit Match", pausePanel.transform, "対戦相手選択へ", new Vector2(0, -330), new Vector2(560, 82), out _);
            var pause = canvasObject.AddComponent<GamePauseController>();
            var pauseSerialized = new SerializedObject(pause);
            pauseSerialized.FindProperty("coordinator").objectReferenceValue = coordinator;
            pauseSerialized.FindProperty("flow").objectReferenceValue = flow;
            pauseSerialized.FindProperty("panel").objectReferenceValue = pausePanel;
            pauseSerialized.FindProperty("pauseButton").objectReferenceValue = pauseButton;
            pauseSerialized.FindProperty("resumeButton").objectReferenceValue = resumeButton;
            pauseSerialized.FindProperty("exitButton").objectReferenceValue = exitMatchButton;
            pauseSerialized.ApplyModifiedPropertiesWithoutUndo();

            var achievementToast = new GameObject("Achievement Toast", typeof(RectTransform), typeof(Image));
            achievementToast.transform.SetParent(safeArea.transform, false);
            var toastRect = achievementToast.GetComponent<RectTransform>();
            toastRect.anchorMin = toastRect.anchorMax = new Vector2(.5f, 1f);
            toastRect.pivot = new Vector2(.5f, 1f);
            toastRect.anchoredPosition = new Vector2(0f, -110f);
            toastRect.sizeDelta = new Vector2(820f, 100f);
            var toastImage = achievementToast.GetComponent<Image>();
            toastImage.color = new Color(.035f, .025f, .015f, .96f);
            toastImage.raycastTarget = false;
            var achievementTitle = CreateText("Achievement Title", achievementToast.transform, "", 27, Vector2.zero, new Vector2(760f, 76f), TextAnchor.MiddleCenter, new Color(1f, .76f, .32f));
            achievementTitle.raycastTarget = false;
            var toast = canvasObject.AddComponent<AchievementToastController>();
            var toastSerialized = new SerializedObject(toast);
            toastSerialized.FindProperty("progress").objectReferenceValue = progress;
            toastSerialized.FindProperty("panel").objectReferenceValue = achievementToast;
            toastSerialized.FindProperty("titleText").objectReferenceValue = achievementTitle;
            toastSerialized.FindProperty("localization").objectReferenceValue = localization;
            toastSerialized.ApplyModifiedPropertiesWithoutUndo();

            var responsive = canvasObject.AddComponent<ResponsiveHudLayout>();
            var responsiveSerialized = new SerializedObject(responsive);
            var layoutRoots = responsiveSerialized.FindProperty("layoutRoots");
            var responsivePanels = new[] { selection, match, result, calibrationPanel, tutorialPanel, settingsPanel, pausePanel };
            layoutRoots.arraySize = responsivePanels.Length;
            for (var i = 0; i < responsivePanels.Length; i++)
                layoutRoots.GetArrayElementAtIndex(i).objectReferenceValue = responsivePanels[i].GetComponent<RectTransform>();
            responsiveSerialized.ApplyModifiedPropertiesWithoutUndo();

            var navigation = canvasObject.AddComponent<UiNavigationController>();
            var navigationSerialized = new SerializedObject(navigation);
            navigationSerialized.FindProperty("selectionPanel").objectReferenceValue = selection;
            navigationSerialized.FindProperty("resultPanel").objectReferenceValue = result;
            navigationSerialized.FindProperty("calibrationPanel").objectReferenceValue = calibrationPanel;
            navigationSerialized.FindProperty("tutorialPanel").objectReferenceValue = tutorialPanel;
            navigationSerialized.FindProperty("settingsPanel").objectReferenceValue = settingsPanel;
            navigationSerialized.FindProperty("pausePanel").objectReferenceValue = pausePanel;
            navigationSerialized.FindProperty("selectionDefault").objectReferenceValue = opponentButtons[0];
            navigationSerialized.FindProperty("flow").objectReferenceValue = flow;
            AssignArray(navigationSerialized.FindProperty("opponentButtons"), opponentButtons);
            navigationSerialized.FindProperty("resultDefault").objectReferenceValue = rematch;
            navigationSerialized.FindProperty("calibrationDefault").objectReferenceValue = cancelCalibration;
            navigationSerialized.FindProperty("tutorialDefault").objectReferenceValue = tutorialNext;
            navigationSerialized.FindProperty("settingsDefault").objectReferenceValue = closeSettings;
            navigationSerialized.FindProperty("pauseDefault").objectReferenceValue = resumeButton;
            navigationSerialized.FindProperty("changeOpponentButton").objectReferenceValue = change;
            navigationSerialized.FindProperty("cancelCalibrationButton").objectReferenceValue = cancelCalibration;
            navigationSerialized.FindProperty("tutorialSkipButton").objectReferenceValue = tutorialSkip;
            navigationSerialized.FindProperty("closeSettingsButton").objectReferenceValue = closeSettings;
            navigationSerialized.ApplyModifiedPropertiesWithoutUndo();

            match.SetActive(false);
            result.SetActive(false);
            calibrationPanel.SetActive(false);
            tutorialPanel.SetActive(false);
            settingsPanel.SetActive(false);
            pausePanel.SetActive(false);
            achievementToast.SetActive(false);

            var hud = canvasObject.AddComponent<GameHudController>();
            var serialized = new SerializedObject(hud);
            serialized.FindProperty("flow").objectReferenceValue = flow;
            serialized.FindProperty("coordinator").objectReferenceValue = coordinator;
            serialized.FindProperty("calibration").objectReferenceValue = calibration;
            serialized.FindProperty("progress").objectReferenceValue = progress;
            serialized.FindProperty("gestureReader").objectReferenceValue = gesture;
            serialized.FindProperty("localization").objectReferenceValue = localization;
            serialized.FindProperty("selectionPanel").objectReferenceValue = selection;
            serialized.FindProperty("matchPanel").objectReferenceValue = match;
            serialized.FindProperty("resultPanel").objectReferenceValue = result;
            serialized.FindProperty("calibrationPanel").objectReferenceValue = calibrationPanel;
            AssignArray(serialized.FindProperty("opponentButtons"), opponentButtons);
            AssignArray(serialized.FindProperty("opponentLabels"), opponentLabels);
            serialized.FindProperty("score301Button").objectReferenceValue = score301;
            serialized.FindProperty("score501Button").objectReferenceValue = score501;
            serialized.FindProperty("doubleOutToggle").objectReferenceValue = doubleToggle;
            serialized.FindProperty("singleLegButton").objectReferenceValue = singleLeg;
            serialized.FindProperty("bestOfThreeButton").objectReferenceValue = bestOfThree;
            serialized.FindProperty("startButton").objectReferenceValue = start;
            serialized.FindProperty("calibrationButton").objectReferenceValue = calibrate;
            serialized.FindProperty("cancelCalibrationButton").objectReferenceValue = cancelCalibration;
            serialized.FindProperty("calibrationStatusText").objectReferenceValue = calibrationStatus;
            serialized.FindProperty("careerText").objectReferenceValue = career;
            serialized.FindProperty("opponentDetailText").objectReferenceValue = opponentDetail;
            serialized.FindProperty("playerScoreText").objectReferenceValue = playerScore;
            serialized.FindProperty("enemyScoreText").objectReferenceValue = enemyScore;
            serialized.FindProperty("enemyNameText").objectReferenceValue = enemyName;
            serialized.FindProperty("turnText").objectReferenceValue = turn;
            serialized.FindProperty("roundText").objectReferenceValue = round;
            serialized.FindProperty("hitText").objectReferenceValue = hit;
            serialized.FindProperty("checkoutText").objectReferenceValue = checkout;
            serialized.FindProperty("legsText").objectReferenceValue = legs;
            serialized.FindProperty("turnSummaryText").objectReferenceValue = turnSummary;
            serialized.FindProperty("resultTitleText").objectReferenceValue = resultTitle;
            serialized.FindProperty("resultDetailText").objectReferenceValue = resultDetail;
            serialized.FindProperty("rematchButton").objectReferenceValue = rematch;
            serialized.FindProperty("changeOpponentButton").objectReferenceValue = change;
            serialized.ApplyModifiedPropertiesWithoutUndo();

            settingsSerialized.Update();
            settingsSerialized.FindProperty("hud").objectReferenceValue = hud;
            settingsSerialized.ApplyModifiedPropertiesWithoutUndo();

            var eventSystem = new GameObject("EventSystem", typeof(EventSystem), typeof(InputSystemUIInputModule));
            eventSystem.GetComponent<InputSystemUIInputModule>().AssignDefaultActions();
        }

        private static RectTransform CreateAimReticle(Transform parent)
        {
            var root = new GameObject("Aim Reticle", typeof(RectTransform));
            root.transform.SetParent(parent, false);
            var rect = root.GetComponent<RectTransform>();
            rect.sizeDelta = new Vector2(118f, 118f);
            var color = new Color(.86f, .58f, .18f, .82f);
            CreateReticleLine("Horizontal", rect, new Vector2(80f, 3f), color);
            CreateReticleLine("Vertical", rect, new Vector2(3f, 80f), color);
            CreateReticleLine("Center", rect, new Vector2(10f, 10f), new Color(1f, .78f, .34f, .95f));
            root.SetActive(false);
            return rect;
        }

        private static void CreateReticleLine(string name, Transform parent, Vector2 size, Color color)
        {
            var line = new GameObject(name, typeof(RectTransform), typeof(Image));
            line.transform.SetParent(parent, false);
            line.GetComponent<RectTransform>().sizeDelta = size;
            var image = line.GetComponent<Image>();
            image.color = color;
            image.raycastTarget = false;
        }

        private static GameObject CreatePanel(string name, Transform parent, Color color)
        {
            var panel = new GameObject(name, typeof(RectTransform), typeof(Image));
            panel.transform.SetParent(parent, false);
            Stretch(panel.GetComponent<RectTransform>());
            panel.GetComponent<Image>().color = color;
            panel.GetComponent<Image>().raycastTarget = color.a > 0f;
            return panel;
        }

        private static TitleBackgroundController CreateTitleBackground(Transform parent)
        {
            const string portraitPath = "Assets/ShinobiZero/Art/Title/title-background-v1.png";
            const string landscapePath = "Assets/ShinobiZero/Art/Title/title-background-landscape-v1.png";
            var portrait = AssetDatabase.LoadAssetAtPath<Sprite>(portraitPath);
            var landscape = AssetDatabase.LoadAssetAtPath<Sprite>(landscapePath);
            if (portrait == null) throw new FileNotFoundException("Portrait title background was not imported.", portraitPath);
            if (landscape == null) throw new FileNotFoundException("Landscape title background was not imported.", landscapePath);

            var background = new GameObject("Title Background", typeof(RectTransform), typeof(Image), typeof(AspectRatioFitter), typeof(TitleBackgroundController));
            background.transform.SetParent(parent, false);
            Stretch(background.GetComponent<RectTransform>());
            var image = background.GetComponent<Image>();
            image.sprite = portrait;
            image.preserveAspect = true;
            image.color = new Color(.82f, .84f, .86f, 1f);
            image.raycastTarget = false;
            var fitter = background.GetComponent<AspectRatioFitter>();
            fitter.aspectMode = AspectRatioFitter.AspectMode.EnvelopeParent;
            fitter.aspectRatio = portrait.rect.width / portrait.rect.height;
            var controller = background.GetComponent<TitleBackgroundController>();
            var serialized = new SerializedObject(controller);
            serialized.FindProperty("image").objectReferenceValue = image;
            serialized.FindProperty("fitter").objectReferenceValue = fitter;
            serialized.FindProperty("portrait").objectReferenceValue = portrait;
            serialized.FindProperty("landscape").objectReferenceValue = landscape;
            serialized.ApplyModifiedPropertiesWithoutUndo();

            var veil = new GameObject("Readability Veil", typeof(RectTransform), typeof(Image));
            veil.transform.SetParent(parent, false);
            Stretch(veil.GetComponent<RectTransform>());
            veil.GetComponent<Image>().color = new Color(.008f, .012f, .014f, .56f);
            return controller;
        }

        private static void ConfigureTitleBackground()
        {
            ConfigureTitleSprite("Assets/ShinobiZero/Art/Title/title-background-v1.png");
            ConfigureTitleSprite("Assets/ShinobiZero/Art/Title/title-background-landscape-v1.png");
        }

        private static void ConfigureTitleSprite(string assetPath)
        {
            var importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;
            if (importer == null) throw new FileNotFoundException("Title background texture is missing.", assetPath);
            var changed = importer.textureType != TextureImporterType.Sprite
                || importer.spriteImportMode != SpriteImportMode.Single
                || importer.mipmapEnabled
                || importer.textureCompression != TextureImporterCompression.CompressedHQ
                || importer.maxTextureSize != 2048;
            importer.textureType = TextureImporterType.Sprite;
            importer.spriteImportMode = SpriteImportMode.Single;
            importer.mipmapEnabled = false;
            importer.alphaIsTransparency = false;
            importer.textureCompression = TextureImporterCompression.CompressedHQ;
            importer.maxTextureSize = 2048;
            if (changed) importer.SaveAndReimport();
        }

        private static Text CreateText(string name, Transform parent, string value, int size, Vector2 position, Vector2 dimensions, TextAnchor alignment, Color color)
        {
            var item = new GameObject(name, typeof(RectTransform), typeof(Text));
            item.transform.SetParent(parent, false);
            SetRect(item.GetComponent<RectTransform>(), position, dimensions);
            var text = item.GetComponent<Text>();
            text.text = value;
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = size;
            text.resizeTextForBestFit = true;
            text.resizeTextMinSize = Mathf.Min(22, size);
            text.resizeTextMaxSize = size;
            text.alignment = alignment;
            text.color = color;
            text.raycastTarget = false;
            return text;
        }

        private static Button CreateButton(string name, Transform parent, string label, Vector2 position, Vector2 dimensions, out Text text)
        {
            var item = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Button));
            item.transform.SetParent(parent, false);
            SetRect(item.GetComponent<RectTransform>(), position, dimensions);
            item.GetComponent<Image>().color = new Color(.055f, .07f, .075f, .96f);
            var button = item.GetComponent<Button>();
            var colors = button.colors;
            colors.highlightedColor = new Color(.36f, .1f, .08f, 1f);
            colors.pressedColor = new Color(.52f, .12f, .09f, 1f);
            button.colors = colors;
            text = CreateText("Label", item.transform, label, 32, Vector2.zero, dimensions - new Vector2(24, 18), TextAnchor.MiddleCenter, Color.white);
            return button;
        }

        private static void CreateOpponentPortrait(Transform parent, Texture texture, int index, int count)
        {
            var portrait = new GameObject("Portrait", typeof(RectTransform), typeof(RawImage));
            portrait.transform.SetParent(parent, false);
            portrait.transform.SetAsFirstSibling();
            SetRect(portrait.GetComponent<RectTransform>(), new Vector2(0, 31), new Vector2(174, 132));
            var image = portrait.GetComponent<RawImage>();
            image.texture = texture;
            image.uvRect = new Rect(index / (float)count, .08f, 1f / count, .84f);
            image.color = new Color(.93f, .95f, .96f, .94f);
            image.raycastTarget = false;
        }

        private static Toggle CreateToggle(string name, Transform parent, string label, Vector2 position, Vector2 dimensions)
        {
            var item = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Toggle));
            item.transform.SetParent(parent, false);
            SetRect(item.GetComponent<RectTransform>(), position, dimensions);
            var background = item.GetComponent<Image>();
            background.color = new Color(.055f, .07f, .075f, .96f);
            var mark = new GameObject("Checkmark", typeof(RectTransform), typeof(Image));
            mark.transform.SetParent(item.transform, false);
            SetRect(mark.GetComponent<RectTransform>(), new Vector2(-125, 0), new Vector2(40, 40));
            mark.GetComponent<Image>().color = new Color(.62f, .12f, .09f, 1f);
            var toggle = item.GetComponent<Toggle>();
            toggle.targetGraphic = background;
            toggle.graphic = mark.GetComponent<Image>();
            CreateText("Label", item.transform, label, 25, new Vector2(28, 0), new Vector2(235, 60), TextAnchor.MiddleCenter, Color.white);
            return toggle;
        }

        private static void AssignArray<T>(SerializedProperty property, T[] values) where T : Object
        {
            property.arraySize = values.Length;
            for (var i = 0; i < values.Length; i++) property.GetArrayElementAtIndex(i).objectReferenceValue = values[i];
        }

        private static void Stretch(RectTransform rect)
        {
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
        }

        private static void SetRect(RectTransform rect, Vector2 position, Vector2 dimensions)
        {
            rect.anchorMin = rect.anchorMax = new Vector2(.5f, .5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = dimensions;
        }

        private static void EnsureFolder(string path)
        {
            var parts = path.Split('/');
            var current = parts[0];
            for (var i = 1; i < parts.Length; i++)
            {
                var next = current + "/" + parts[i];
                if (!AssetDatabase.IsValidFolder(next)) AssetDatabase.CreateFolder(current, parts[i]);
                current = next;
            }
        }
    }
}
