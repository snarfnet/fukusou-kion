using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;
using UnityEngine.Rendering;
using ShinobiZero.Core;

namespace ShinobiZero.Editor
{
    public static class ProductBuildMenu
    {
        private const string ProductName = "SHINOBI ZERO";
        private const string Identifier = "com.shinobizero.game";
        private const string VersionEnvironment = "SHINOBI_ZERO_VERSION";
        private const string BuildEnvironment = "SHINOBI_ZERO_BUILD_NUMBER";

        [Serializable]
        private sealed class BuildManifest
        {
            public string Product;
            public string Version;
            public int BuildNumber;
            public string Target;
            public string UnityVersion;
            public string BuiltUtc;
            public string Output;
            public string SizeBytes;
        }

        [MenuItem("Tools/SHINOBI ZERO/Configure Product Settings")]
        public static void Configure()
        {
            var identity = ConfigureProductSettings();
            Debug.Log($"SHINOBI ZERO product settings configured: {identity.Version} ({identity.BuildNumber}).");
        }

        private static BuildIdentity ConfigureProductSettings()
        {
            var identity = BuildIdentityResolver.Resolve(
                Environment.GetEnvironmentVariable(VersionEnvironment),
                Environment.GetEnvironmentVariable(BuildEnvironment));
            PlayerSettings.companyName = "SHINOBI ZERO Studio";
            PlayerSettings.productName = ProductName;
            PlayerSettings.bundleVersion = identity.Version;
            PlayerSettings.iOS.buildNumber = identity.BuildNumber.ToString(System.Globalization.CultureInfo.InvariantCulture);
            PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.iOS, Identifier);
            PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Standalone, Identifier);
            PlayerSettings.defaultScreenWidth = 1920;
            PlayerSettings.defaultScreenHeight = 1080;
            PlayerSettings.runInBackground = false;
            PlayerSettings.fullScreenMode = FullScreenMode.FullScreenWindow;
            PlayerSettings.iOS.targetDevice = iOSTargetDevice.iPhoneAndiPad;
            PlayerSettings.iOS.targetOSVersionString = "15.0";
            PlayerSettings.iOS.appleEnableAutomaticSigning = false;
            PlayerSettings.iOS.requiresFullScreen = true;
            PlayerSettings.statusBarHidden = true;
            PlayerSettings.defaultInterfaceOrientation = UIOrientation.Portrait;
            PlayerSettings.allowedAutorotateToPortrait = false;
            PlayerSettings.allowedAutorotateToPortraitUpsideDown = false;
            PlayerSettings.allowedAutorotateToLandscapeLeft = false;
            PlayerSettings.allowedAutorotateToLandscapeRight = false;
            PlayerSettings.colorSpace = ColorSpace.Linear;
            PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.iOS, false);
            PlayerSettings.SetGraphicsAPIs(BuildTarget.iOS, new[] { GraphicsDeviceType.Metal });
            PlayerSettings.SetScriptingBackend(BuildTargetGroup.iOS, ScriptingImplementation.IL2CPP);
            PlayerSettings.SetScriptingBackend(BuildTargetGroup.Standalone, ScriptingImplementation.IL2CPP);
            ConfigureInputSystem();
            AssetDatabase.SaveAssets();
            return identity;
        }

        private static void ConfigureInputSystem()
        {
            var assets = AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/ProjectSettings.asset");
            if (assets.Length == 0) return;
            var settings = new SerializedObject(assets[0]);
            var activeInputHandler = settings.FindProperty("activeInputHandler");
            if (activeInputHandler == null) return;
            activeInputHandler.intValue = 1;
            settings.ApplyModifiedPropertiesWithoutUndo();
        }

        [MenuItem("Tools/SHINOBI ZERO/Build/iOS Xcode Project")]
        public static void BuildIos() => Build(BuildTarget.iOS, "Builds/iOS");

        [MenuItem("Tools/SHINOBI ZERO/Build/Windows x64")]
        public static void BuildWindows() => Build(BuildTarget.StandaloneWindows64, "Builds/Windows/SHINOBI ZERO.exe");

        [MenuItem("Tools/SHINOBI ZERO/Build/macOS Universal")]
        public static void BuildMacOs() => Build(BuildTarget.StandaloneOSX, "Builds/macOS/SHINOBI ZERO.app");

        [MenuItem("Tools/SHINOBI ZERO/Build/Linux x64")]
        public static void BuildLinux() => Build(BuildTarget.StandaloneLinux64, "Builds/Linux/SHINOBI ZERO.x86_64");

        private static void Build(BuildTarget target, string output)
        {
            var identity = ConfigureProductSettings();
            var scenes = EditorBuildSettings.scenes.Where(scene => scene.enabled).Select(scene => scene.path).ToArray();
            if (scenes.Length == 0) throw new InvalidOperationException("No enabled scenes. Create the prototype scene first.");
            Directory.CreateDirectory(Path.GetDirectoryName(output) ?? "Builds");
            var report = BuildPipeline.BuildPlayer(new BuildPlayerOptions
            {
                scenes = scenes,
                locationPathName = output,
                target = target,
                options = BuildOptions.StrictMode
            });
            if (report.summary.result != BuildResult.Succeeded)
                throw new InvalidOperationException($"Build failed: {report.summary.result}");
            WriteBuildManifest(target, output, identity, report.summary.totalSize);
            Debug.Log($"Build complete: {output} ({report.summary.totalSize} bytes)");
        }

        private static void WriteBuildManifest(BuildTarget target, string output, BuildIdentity identity, ulong sizeBytes)
        {
            var directory = target == BuildTarget.iOS ? output : Path.GetDirectoryName(output);
            if (string.IsNullOrEmpty(directory)) directory = "Builds";
            Directory.CreateDirectory(directory);
            var manifest = new BuildManifest
            {
                Product = ProductName,
                Version = identity.Version,
                BuildNumber = identity.BuildNumber,
                Target = target.ToString(),
                UnityVersion = Application.unityVersion,
                BuiltUtc = DateTime.UtcNow.ToString("O"),
                Output = output.Replace('\\', '/'),
                SizeBytes = sizeBytes.ToString(System.Globalization.CultureInfo.InvariantCulture)
            };
            File.WriteAllText(Path.Combine(directory, "build-manifest.json"), JsonUtility.ToJson(manifest, true));
        }
    }
}
