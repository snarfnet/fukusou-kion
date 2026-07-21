using System;
using ShinobiZero.Core;

namespace ShinobiZero.Runtime
{
    [Serializable]
    public sealed class ActiveMatchSave
    {
        public int Version = 1;
        public int Opponent;
        public int NextStarter;
        public MatchStateSnapshot Match;
        public MatchPerformanceSnapshot Performance;
        public CareerStats Career;
    }
}
