using System;
using System.Globalization;

namespace ShinobiZero.Core
{
    public struct BuildIdentity
    {
        public readonly string Version;
        public readonly int BuildNumber;

        public BuildIdentity(string version, int buildNumber)
        {
            Version = version;
            BuildNumber = buildNumber;
        }
    }

    public static class BuildIdentityResolver
    {
        public const string DefaultVersion = "0.1.0";
        public const int DefaultBuildNumber = 1;

        public static BuildIdentity Resolve(string version, string buildNumber)
        {
            version = string.IsNullOrWhiteSpace(version) ? DefaultVersion : version.Trim();
            buildNumber = string.IsNullOrWhiteSpace(buildNumber) ? DefaultBuildNumber.ToString(CultureInfo.InvariantCulture) : buildNumber.Trim();
            var parts = version.Split('.');
            if (parts.Length != 3) throw new FormatException("Version must use MAJOR.MINOR.PATCH.");
            for (var i = 0; i < parts.Length; i++)
            {
                int value;
                if (!int.TryParse(parts[i], NumberStyles.None, CultureInfo.InvariantCulture, out value) || value < 0
                    || value.ToString(CultureInfo.InvariantCulture) != parts[i])
                    throw new FormatException("Version segments must be canonical non-negative integers.");
            }
            int build;
            if (!int.TryParse(buildNumber, NumberStyles.None, CultureInfo.InvariantCulture, out build) || build < 1)
                throw new FormatException("Build number must be a positive integer.");
            return new BuildIdentity(version, build);
        }
    }
}
