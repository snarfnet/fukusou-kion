using System;
using System.Collections.Generic;
using System.Text;

namespace ShinobiZero.Core
{
    public struct CheckoutRoute
    {
        public readonly DartHit[] Hits;
        public bool IsPossible { get { return Hits != null && Hits.Length > 0; } }

        public CheckoutRoute(DartHit[] hits) { Hits = hits; }
        public static CheckoutRoute None { get { return new CheckoutRoute(null); } }
    }

    public static class CheckoutAdvisor
    {
        private static readonly DartHit[] SetupHits = BuildSetupHits();
        private static readonly DartHit[] DoubleFinishes = BuildDoubleFinishes();

        public static CheckoutRoute Find(int remaining, int dartsAvailable, bool doubleOut)
        {
            if (remaining <= 0 || dartsAvailable <= 0) return CheckoutRoute.None;
            dartsAvailable = Math.Min(3, dartsAvailable);
            for (var length = 1; length <= dartsAvailable; length++)
            {
                var route = new DartHit[length];
                if (Search(remaining, 0, route, doubleOut)) return new CheckoutRoute(route);
            }
            return CheckoutRoute.None;
        }

        public static string Format(CheckoutRoute route)
        {
            if (!route.IsPossible) return string.Empty;
            var text = new StringBuilder();
            for (var i = 0; i < route.Hits.Length; i++)
            {
                if (i > 0) text.Append(" → ");
                text.Append(Label(route.Hits[i]));
            }
            return text.ToString();
        }

        public static string Label(DartHit hit)
        {
            if (hit.Score == 0) return "MISS";
            if (hit.Base == 25) return hit.Multiplier == 2 ? "BULL" : "25";
            if (hit.Multiplier == 3) return "T" + hit.Base;
            if (hit.Multiplier == 2) return "D" + hit.Base;
            return "S" + hit.Base;
        }

        private static bool Search(int remaining, int index, DartHit[] route, bool doubleOut)
        {
            if (index == route.Length) return remaining == 0;
            var last = index == route.Length - 1;
            var candidates = last && doubleOut ? DoubleFinishes : SetupHits;
            for (var i = 0; i < candidates.Length; i++)
            {
                var hit = candidates[i];
                var next = remaining - hit.Score;
                if (next < 0 || (!last && (next == 0 || (doubleOut && next == 1)))) continue;
                if (last && next != 0) continue;
                route[index] = hit;
                if (Search(next, index + 1, route, doubleOut)) return true;
            }
            return false;
        }

        private static DartHit[] BuildSetupHits()
        {
            var hits = new List<DartHit>();
            for (var value = 20; value >= 1; value--) hits.Add(new DartHit(value, 3));
            hits.Add(DartHit.Bull);
            for (var value = 20; value >= 1; value--) hits.Add(new DartHit(value, 1));
            hits.Add(DartHit.OuterBull);
            var preferredDoubles = new[] { 20, 16, 18, 12, 10, 8, 4, 2, 1, 14, 6, 5, 15, 13, 11, 9, 7, 3, 19, 17 };
            for (var i = 0; i < preferredDoubles.Length; i++) hits.Add(new DartHit(preferredDoubles[i], 2));
            return hits.ToArray();
        }

        private static DartHit[] BuildDoubleFinishes()
        {
            var values = new[] { 20, 16, 18, 12, 10, 8, 4, 2, 1, 14, 6, 5, 15, 13, 11, 9, 7, 3, 19, 17 };
            var hits = new DartHit[values.Length + 1];
            for (var i = 0; i < values.Length; i++) hits[i] = new DartHit(values[i], 2);
            hits[hits.Length - 1] = DartHit.Bull;
            return hits;
        }
    }
}
