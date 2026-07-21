namespace ShinobiZero.Core
{
    public sealed class ThrowReleaseGate
    {
        public bool IsArmed { get; private set; }
        public void Arm() { IsArmed = true; }
        public void Reset() { IsArmed = false; }
        public bool TryRelease()
        {
            if (!IsArmed) return false;
            IsArmed = false;
            return true;
        }
    }
}
