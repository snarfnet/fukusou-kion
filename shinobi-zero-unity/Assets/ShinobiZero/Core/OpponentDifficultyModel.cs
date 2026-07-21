using System;

namespace ShinobiZero.Core
{
    public static class OpponentDifficultyModel
    {
        public static int Level(float skill)
        {
            skill = Math.Max(0f, Math.Min(1f, skill));
            if (skill <= .40f) return 1;
            if (skill <= .55f) return 2;
            if (skill <= .70f) return 3;
            if (skill <= .84f) return 4;
            return 5;
        }

        public static string Stars(float skill)
        {
            var level = Level(skill);
            return new string('★', level) + new string('☆', 5 - level);
        }
    }
}
