namespace ShinobiZero.Core
{
    public enum UiFocusTarget
    {
        None,
        Selection,
        Result,
        Calibration,
        Tutorial,
        Settings,
        Pause
    }

    public enum UiBackTarget
    {
        None,
        Result,
        Calibration,
        Tutorial,
        Settings
    }

    public static class UiFocusModel
    {
        public static UiFocusTarget Resolve(bool selection, bool result, bool calibration, bool tutorial, bool settings, bool pause)
        {
            if (pause) return UiFocusTarget.Pause;
            if (settings) return UiFocusTarget.Settings;
            if (tutorial) return UiFocusTarget.Tutorial;
            if (calibration) return UiFocusTarget.Calibration;
            if (result) return UiFocusTarget.Result;
            if (selection) return UiFocusTarget.Selection;
            return UiFocusTarget.None;
        }

        public static UiBackTarget ResolveBack(bool result, bool calibration, bool tutorial, bool settings)
        {
            if (settings) return UiBackTarget.Settings;
            if (tutorial) return UiBackTarget.Tutorial;
            if (calibration) return UiBackTarget.Calibration;
            if (result) return UiBackTarget.Result;
            return UiBackTarget.None;
        }
    }
}
