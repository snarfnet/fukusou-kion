using ShinobiZero.Core;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem;
using UnityEngine.UI;

namespace ShinobiZero.Runtime
{
    public sealed class UiNavigationController : MonoBehaviour
    {
        [SerializeField] private GameObject selectionPanel;
        [SerializeField] private GameObject resultPanel;
        [SerializeField] private GameObject calibrationPanel;
        [SerializeField] private GameObject tutorialPanel;
        [SerializeField] private GameObject settingsPanel;
        [SerializeField] private GameObject pausePanel;
        [SerializeField] private Selectable selectionDefault;
        [SerializeField] private GameFlowController flow;
        [SerializeField] private Selectable[] opponentButtons;
        [SerializeField] private Selectable resultDefault;
        [SerializeField] private Selectable calibrationDefault;
        [SerializeField] private Selectable tutorialDefault;
        [SerializeField] private Selectable settingsDefault;
        [SerializeField] private Selectable pauseDefault;
        [SerializeField] private Button changeOpponentButton;
        [SerializeField] private Button cancelCalibrationButton;
        [SerializeField] private Button tutorialSkipButton;
        [SerializeField] private Button closeSettingsButton;

        private UiFocusTarget _current = (UiFocusTarget)(-1);

        private void Update()
        {
            if (!HasNavigationDevice())
            {
                _current = (UiFocusTarget)(-1);
                return;
            }
            if (BackPressed() && HandleBack()) return;
            var target = UiFocusModel.Resolve(
                IsVisible(selectionPanel), IsVisible(resultPanel), IsVisible(calibrationPanel),
                IsVisible(tutorialPanel), IsVisible(settingsPanel), IsVisible(pausePanel));
            var eventSystem = EventSystem.current;
            if (eventSystem == null) return;
            var desired = DefaultFor(target);
            var selected = eventSystem.currentSelectedGameObject;
            var lostSelection = desired != null && (selected == null || !selected.activeInHierarchy);
            if (target == _current && !lostSelection) return;
            _current = target;
            eventSystem.SetSelectedGameObject(desired == null ? null : desired.gameObject);
        }

        private Selectable DefaultFor(UiFocusTarget target)
        {
            if (target == UiFocusTarget.Selection)
            {
                if (flow != null && opponentButtons != null && flow.SelectedOpponent >= 0
                    && flow.SelectedOpponent < opponentButtons.Length && opponentButtons[flow.SelectedOpponent] != null)
                    return opponentButtons[flow.SelectedOpponent];
                return selectionDefault;
            }
            if (target == UiFocusTarget.Result) return resultDefault;
            if (target == UiFocusTarget.Calibration) return calibrationDefault;
            if (target == UiFocusTarget.Tutorial) return tutorialDefault;
            if (target == UiFocusTarget.Settings) return settingsDefault;
            if (target == UiFocusTarget.Pause) return pauseDefault;
            return null;
        }

        private static bool IsVisible(GameObject panel) => panel != null && panel.activeInHierarchy;
        private static bool HasNavigationDevice() => Gamepad.current != null || Keyboard.current != null;

        private static bool BackPressed() =>
            (Keyboard.current != null && Keyboard.current.escapeKey.wasPressedThisFrame)
            || (Gamepad.current != null && Gamepad.current.buttonEast.wasPressedThisFrame);

        private bool HandleBack()
        {
            var target = UiFocusModel.ResolveBack(
                IsVisible(resultPanel), IsVisible(calibrationPanel), IsVisible(tutorialPanel), IsVisible(settingsPanel));
            Button button = null;
            if (target == UiBackTarget.Result) button = changeOpponentButton;
            else if (target == UiBackTarget.Calibration) button = cancelCalibrationButton;
            else if (target == UiBackTarget.Tutorial) button = tutorialSkipButton;
            else if (target == UiBackTarget.Settings) button = closeSettingsButton;
            if (button == null || !button.isActiveAndEnabled || !button.interactable) return false;
            button.onClick.Invoke();
            _current = (UiFocusTarget)(-1);
            return true;
        }
    }
}
