#if UNITY_IOS
using System.IO;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode;
using UnityEngine;

namespace ShinobiZero.Editor
{
    public static class IosPostBuild
    {
        [PostProcessBuild(100)]
        public static void Configure(BuildTarget target, string path)
        {
            if (target != BuildTarget.iOS) return;
            var plistPath = Path.Combine(path, "Info.plist");
            var plist = new PlistDocument();
            plist.ReadFromFile(plistPath);
            plist.root.SetBoolean("ITSAppUsesNonExemptEncryption", false);
            File.WriteAllText(plistPath, plist.WriteToString());
            InstallAppIcons(path);
            InstallPrivacyManifest(path);
        }

        private static void InstallAppIcons(string xcodeRoot)
        {
            var source = Path.Combine(Application.dataPath, "Plugins", "iOS", "AppIcon.appiconset");
            var destination = Path.Combine(xcodeRoot, "Unity-iPhone", "Images.xcassets", "AppIcon.appiconset");
            if (!Directory.Exists(source)) throw new DirectoryNotFoundException("iOS icon set not found: " + source);
            Directory.CreateDirectory(destination);
            foreach (var file in Directory.GetFiles(source))
                File.Copy(file, Path.Combine(destination, Path.GetFileName(file)), true);
        }

        private static void InstallPrivacyManifest(string xcodeRoot)
        {
            var source = Path.Combine(Application.dataPath, "Plugins", "iOS", "PrivacyInfo.xcprivacy");
            var destination = Path.Combine(xcodeRoot, "PrivacyInfo.xcprivacy");
            if (!File.Exists(source)) throw new FileNotFoundException("Privacy manifest not found.", source);
            File.Copy(source, destination, true);

            var projectPath = PBXProject.GetPBXProjectPath(xcodeRoot);
            var project = new PBXProject();
            project.ReadFromFile(projectPath);
            const string projectRelativePath = "PrivacyInfo.xcprivacy";
            var fileGuid = project.FindFileGuidByProjectPath(projectRelativePath);
            if (string.IsNullOrEmpty(fileGuid)) fileGuid = project.AddFile(projectRelativePath, projectRelativePath);
            project.AddFileToBuild(project.GetUnityMainTargetGuid(), fileGuid);
            project.WriteToFile(projectPath);
        }
    }
}
#endif
