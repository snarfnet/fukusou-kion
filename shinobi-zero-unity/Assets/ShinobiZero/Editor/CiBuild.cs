using System;

namespace ShinobiZero.Editor
{
    public static class CiBuild
    {
        public static void BuildIos()
        {
            Prepare();
            ProductBuildMenu.BuildIos();
        }

        public static void BuildWindows() { Prepare(); ProductBuildMenu.BuildWindows(); }
        public static void BuildMacOs() { Prepare(); ProductBuildMenu.BuildMacOs(); }
        public static void BuildLinux() { Prepare(); ProductBuildMenu.BuildLinux(); }

        private static void Prepare()
        {
            ApplyArgument("-szVersion", "SHINOBI_ZERO_VERSION");
            ApplyArgument("-szBuildNumber", "SHINOBI_ZERO_BUILD_NUMBER");
            PrototypeSceneBuilder.CreateScene();
        }

        private static void ApplyArgument(string argument, string environmentVariable)
        {
            var args = Environment.GetCommandLineArgs();
            for (var i = 0; i + 1 < args.Length; i++)
            {
                if (!string.Equals(args[i], argument, StringComparison.Ordinal)) continue;
                Environment.SetEnvironmentVariable(environmentVariable, args[i + 1]);
                return;
            }
        }
    }
}
