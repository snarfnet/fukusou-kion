using System;

namespace ShinobiZero.Core
{
    public enum RuntimeQualityTier { Performance, Balanced, High }

    public sealed class PerformanceGovernor
    {
        public RuntimeQualityTier Tier { get; private set; }
        private int _slowWindows;
        private int _stableWindows;

        public PerformanceGovernor(RuntimeQualityTier initialTier) { Tier = initialTier; }

        public bool Sample(float averageFrameMilliseconds)
        {
            if (averageFrameMilliseconds <= 0f || float.IsNaN(averageFrameMilliseconds) || float.IsInfinity(averageFrameMilliseconds))
                throw new ArgumentOutOfRangeException("averageFrameMilliseconds");
            var slowThreshold = Tier == RuntimeQualityTier.High ? 20f : 24f;
            if (averageFrameMilliseconds > slowThreshold)
            {
                _slowWindows++;
                _stableWindows = 0;
                if (Tier == RuntimeQualityTier.Performance) { _slowWindows = 0; return false; }
                if (_slowWindows < 3) return false;
                Tier--;
                _slowWindows = 0;
                return true;
            }
            if (averageFrameMilliseconds < 17.5f)
            {
                _stableWindows++;
                _slowWindows = 0;
                if (Tier == RuntimeQualityTier.High) { _stableWindows = 0; return false; }
                if (_stableWindows < 12) return false;
                Tier++;
                _stableWindows = 0;
                return true;
            }
            _slowWindows = 0;
            _stableWindows = 0;
            return false;
        }

        public bool HandleMemoryPressure()
        {
            _slowWindows = 0;
            _stableWindows = 0;
            if (Tier == RuntimeQualityTier.Performance) return false;
            Tier = RuntimeQualityTier.Performance;
            return true;
        }

        public static RuntimeQualityTier InitialTier(int systemMemoryMb, int graphicsMemoryMb, bool mobile)
        {
            if (systemMemoryMb > 0 && systemMemoryMb < 2500) return RuntimeQualityTier.Performance;
            if (mobile && ((systemMemoryMb > 0 && systemMemoryMb < 4000) || (graphicsMemoryMb > 0 && graphicsMemoryMb < 1000)))
                return RuntimeQualityTier.Balanced;
            return RuntimeQualityTier.High;
        }
    }
}
