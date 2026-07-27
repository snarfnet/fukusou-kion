#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using System.IO;

namespace GlassCraft.Editor
{
    [InitializeOnLoad]
    public static class IOSProjectSetup
    {
        static IOSProjectSetup()
        {
            PlayerSettings.productName = "Glass Craft";
            PlayerSettings.companyName = "Independent Studio";
            PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.iOS, "com.tokyonasu.glasscraft");
            PlayerSettings.defaultInterfaceOrientation = UIOrientation.LandscapeLeft;
            PlayerSettings.allowedAutorotateToPortrait = false;
            PlayerSettings.allowedAutorotateToPortraitUpsideDown = false;
            PlayerSettings.allowedAutorotateToLandscapeLeft = true;
            PlayerSettings.allowedAutorotateToLandscapeRight = true;
            PlayerSettings.iOS.targetOSVersionString = "15.0";
            PlayerSettings.iOS.appleEnableAutomaticSigning = false;
            var appIcon = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/AppIcon.png");
            if (appIcon != null)
            {
                var iconSizes = PlayerSettings.GetIconSizesForTargetGroup(BuildTargetGroup.iOS);
                var icons = new Texture2D[iconSizes.Length];
                for (var index = 0; index < icons.Length; index++) icons[index] = appIcon;
                PlayerSettings.SetIconsForTargetGroup(BuildTargetGroup.iOS, icons);
            }
            EditorApplication.delayCall += EnsureStartupScene;
        }

        private static void EnsureStartupScene()
        {
            const string sceneFolder = "Assets/Scenes";
            const string scenePath = sceneFolder + "/Main.unity";
            if (!Directory.Exists(sceneFolder)) Directory.CreateDirectory(sceneFolder);

            if (!File.Exists(scenePath))
            {
                var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
                EditorSceneManager.SaveScene(scene, scenePath);
                AssetDatabase.Refresh();
            }

            var scenes = EditorBuildSettings.scenes;
            if (scenes.Length != 1 || scenes[0].path != scenePath || !scenes[0].enabled)
                EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(scenePath, true) };
        }
    }
}
#endif
