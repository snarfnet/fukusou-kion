using System;
using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class BuildIdentityTests
    {
        [Test] public void MissingValuesUseDevelopmentIdentity()
        {
            var identity = BuildIdentityResolver.Resolve(null, null);
            Assert.That(identity.Version, Is.EqualTo("0.1.0"));
            Assert.That(identity.BuildNumber, Is.EqualTo(1));
        }

        [Test] public void StoreIdentityRoundTrips()
        {
            var identity = BuildIdentityResolver.Resolve("1.4.12", "803");
            Assert.That(identity.Version, Is.EqualTo("1.4.12"));
            Assert.That(identity.BuildNumber, Is.EqualTo(803));
        }

        [TestCase("1.2")]
        [TestCase("1.2.beta")]
        [TestCase("01.2.3")]
        [TestCase("1.2.3.4")]
        public void InvalidStoreVersionIsRejected(string version)
        {
            Assert.Throws<FormatException>(() => BuildIdentityResolver.Resolve(version, "1"));
        }

        [TestCase("0")]
        [TestCase("-1")]
        [TestCase("build")]
        public void InvalidBuildNumberIsRejected(string build)
        {
            Assert.Throws<FormatException>(() => BuildIdentityResolver.Resolve("1.2.3", build));
        }
    }
}
