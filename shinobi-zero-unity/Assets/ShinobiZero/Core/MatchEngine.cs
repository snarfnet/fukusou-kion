using System;

namespace ShinobiZero.Core
{
    public enum Combatant { Player, Enemy }

    public static class MatchOrder
    {
        public static Combatant Opponent(Combatant combatant)
        {
            return combatant == Combatant.Player ? Combatant.Enemy : Combatant.Player;
        }
    }

    public struct MatchConfig
    {
        public readonly int StartScore;
        public readonly bool DoubleOut;
        public readonly int LegsToWin;
        public readonly Combatant StartingPlayer;

        public MatchConfig(int startScore, bool doubleOut, int legsToWin = 1, Combatant startingPlayer = Combatant.Player)
        {
            if (startScore != 301 && startScore != 501)
                throw new ArgumentOutOfRangeException("startScore", "Start score must be 301 or 501.");
            StartScore = startScore;
            DoubleOut = doubleOut;
            if (legsToWin != 1 && legsToWin != 2)
                throw new ArgumentOutOfRangeException("legsToWin", "Legs to win must be 1 or 2.");
            LegsToWin = legsToWin;
            if (startingPlayer != Combatant.Player && startingPlayer != Combatant.Enemy)
                throw new ArgumentOutOfRangeException("startingPlayer");
            StartingPlayer = startingPlayer;
        }
    }

    public struct ThrowOutcome
    {
        public readonly Combatant Thrower;
        public readonly DartHit Hit;
        public readonly ScoreResolution Score;
        public readonly bool TurnEnded;
        public readonly bool MatchEnded;
        public readonly bool LegEnded;

        public ThrowOutcome(Combatant thrower, DartHit hit, ScoreResolution score, bool turnEnded, bool legEnded, bool matchEnded)
        {
            Thrower = thrower;
            Hit = hit;
            Score = score;
            TurnEnded = turnEnded;
            LegEnded = legEnded;
            MatchEnded = matchEnded;
        }
    }

    [Serializable]
    public sealed class MatchStateSnapshot
    {
        public int Version = 1;
        public int StartScore;
        public bool DoubleOut;
        public int LegsToWin;
        public int StartingPlayer;
        public int PlayerScore;
        public int EnemyScore;
        public int Turn;
        public int DartsLeft;
        public int Round;
        public int PlayerLegs;
        public int EnemyLegs;
        public int TurnStart;
    }

    public sealed class MatchEngine
    {
        public MatchConfig Config { get; private set; }
        public int PlayerScore { get; private set; }
        public int EnemyScore { get; private set; }
        public Combatant Turn { get; private set; }
        public int DartsLeft { get; private set; }
        public int Round { get; private set; }
        public bool IsFinished { get; private set; }
        public bool HasStarted { get; private set; }
        public Combatant? Winner { get; private set; }
        public int PlayerLegs { get; private set; }
        public int EnemyLegs { get; private set; }
        public int LegNumber { get { return IsFinished ? PlayerLegs + EnemyLegs : PlayerLegs + EnemyLegs + 1; } }

        private int _turnStart;

        public void Start(MatchConfig config)
        {
            Config = config;
            PlayerScore = config.StartScore;
            EnemyScore = config.StartScore;
            Turn = config.StartingPlayer;
            DartsLeft = 3;
            Round = 1;
            IsFinished = false;
            HasStarted = true;
            Winner = null;
            PlayerLegs = 0;
            EnemyLegs = 0;
            _turnStart = config.StartScore;
        }

        public ThrowOutcome Submit(DartHit hit)
        {
            if (!HasStarted) throw new InvalidOperationException("The match has not started.");
            if (IsFinished) throw new InvalidOperationException("The match is already finished.");
            var thrower = Turn;
            var remaining = thrower == Combatant.Player ? PlayerScore : EnemyScore;
            var resolution = DartsRules.Resolve(remaining, _turnStart, hit, Config.DoubleOut);

            if (thrower == Combatant.Player) PlayerScore = resolution.Remaining;
            else EnemyScore = resolution.Remaining;

            if (resolution.Win)
            {
                if (thrower == Combatant.Player) PlayerLegs++;
                else EnemyLegs++;
                var matchEnded = PlayerLegs >= Config.LegsToWin || EnemyLegs >= Config.LegsToWin;
                if (matchEnded)
                {
                    IsFinished = true;
                    Winner = thrower;
                }
                else StartNextLeg();
                return new ThrowOutcome(thrower, hit, resolution, true, true, matchEnded);
            }

            DartsLeft--;
            var turnEnded = resolution.Bust || DartsLeft == 0;
            if (turnEnded) AdvanceTurn();
            return new ThrowOutcome(thrower, hit, resolution, turnEnded, false, false);
        }

        public bool Abort()
        {
            if (!HasStarted || IsFinished) return false;
            IsFinished = true;
            Winner = null;
            return true;
        }

        public MatchStateSnapshot Capture()
        {
            if (!HasStarted || IsFinished) throw new InvalidOperationException("Only an active match can be captured.");
            return new MatchStateSnapshot
            {
                StartScore = Config.StartScore,
                DoubleOut = Config.DoubleOut,
                LegsToWin = Config.LegsToWin,
                StartingPlayer = (int)Config.StartingPlayer,
                PlayerScore = PlayerScore,
                EnemyScore = EnemyScore,
                Turn = (int)Turn,
                DartsLeft = DartsLeft,
                Round = Round,
                PlayerLegs = PlayerLegs,
                EnemyLegs = EnemyLegs,
                TurnStart = _turnStart
            };
        }

        public bool TryRestore(MatchStateSnapshot snapshot)
        {
            if (!IsValid(snapshot)) return false;
            Config = new MatchConfig(snapshot.StartScore, snapshot.DoubleOut, snapshot.LegsToWin, (Combatant)snapshot.StartingPlayer);
            PlayerScore = snapshot.PlayerScore;
            EnemyScore = snapshot.EnemyScore;
            Turn = (Combatant)snapshot.Turn;
            DartsLeft = snapshot.DartsLeft;
            Round = snapshot.Round;
            PlayerLegs = snapshot.PlayerLegs;
            EnemyLegs = snapshot.EnemyLegs;
            _turnStart = snapshot.TurnStart;
            HasStarted = true;
            IsFinished = false;
            Winner = null;
            return true;
        }

        private static bool IsValid(MatchStateSnapshot snapshot)
        {
            if (snapshot == null || snapshot.Version != 1) return false;
            if (snapshot.StartScore != 301 && snapshot.StartScore != 501) return false;
            if (snapshot.LegsToWin != 1 && snapshot.LegsToWin != 2) return false;
            if (snapshot.StartingPlayer < 0 || snapshot.StartingPlayer > 1 || snapshot.Turn < 0 || snapshot.Turn > 1) return false;
            if (snapshot.PlayerScore < 1 || snapshot.PlayerScore > snapshot.StartScore
                || snapshot.EnemyScore < 1 || snapshot.EnemyScore > snapshot.StartScore) return false;
            if (snapshot.DartsLeft < 1 || snapshot.DartsLeft > 3 || snapshot.Round < 1 || snapshot.Round > 1000) return false;
            if (snapshot.PlayerLegs < 0 || snapshot.EnemyLegs < 0
                || snapshot.PlayerLegs >= snapshot.LegsToWin || snapshot.EnemyLegs >= snapshot.LegsToWin
                || snapshot.PlayerLegs + snapshot.EnemyLegs > snapshot.LegsToWin * 2 - 2) return false;
            var activeScore = snapshot.Turn == (int)Combatant.Player ? snapshot.PlayerScore : snapshot.EnemyScore;
            return snapshot.TurnStart >= activeScore && snapshot.TurnStart <= snapshot.StartScore;
        }

        private void StartNextLeg()
        {
            PlayerScore = Config.StartScore;
            EnemyScore = Config.StartScore;
            Round = 1;
            DartsLeft = 3;
            Turn = (PlayerLegs + EnemyLegs) % 2 == 0
                ? Config.StartingPlayer
                : MatchOrder.Opponent(Config.StartingPlayer);
            _turnStart = Config.StartScore;
        }

        private void AdvanceTurn()
        {
            // A round is complete only after both combatants have taken a turn.
            // The second thrower changes when the enemy starts the match or leg.
            if (Turn == MatchOrder.Opponent(CurrentLegStarter())) Round++;
            Turn = Turn == Combatant.Player ? Combatant.Enemy : Combatant.Player;
            DartsLeft = 3;
            _turnStart = Turn == Combatant.Player ? PlayerScore : EnemyScore;
        }

        private Combatant CurrentLegStarter()
        {
            var completedLegs = PlayerLegs + EnemyLegs;
            return completedLegs % 2 == 0
                ? Config.StartingPlayer
                : MatchOrder.Opponent(Config.StartingPlayer);
        }
    }
}
