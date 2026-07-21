using System;
using System.Collections.Generic;
using ShinobiZero.Core;
using UnityEngine;

namespace ShinobiZero.Runtime
{
    public sealed class ThrowCalibrationController : MonoBehaviour
    {
        private const string CalibrationKey = "shinobi-zero.throw-ideal-rise.v1";
        private const int RequiredThrows = 3;

        [SerializeField] private ThrowGestureReader gestureReader;
        [SerializeField] private ThrowMapper throwMapper;
        public event Action<int, int> ProgressChanged;
        public event Action<float> Completed;
        public event Action Cancelled;
        public bool IsCalibrating { get; private set; }
        public bool HasSavedCalibration { get { return PlayerPrefs.HasKey(CalibrationKey); } }

        private readonly List<float> _samples = new List<float>(RequiredThrows);

        private void Awake()
        {
            if (HasSavedCalibration)
                throwMapper.SetIdealRiseFraction(PlayerPrefs.GetFloat(CalibrationKey, throwMapper.IdealRiseFraction));
        }

        private void OnEnable() => gestureReader.Thrown += HandleThrow;
        private void OnDisable() => gestureReader.Thrown -= HandleThrow;

        public void Begin()
        {
            _samples.Clear();
            IsCalibrating = true;
            ProgressChanged?.Invoke(0, RequiredThrows);
        }

        public void Cancel()
        {
            if (!IsCalibrating) return;
            IsCalibrating = false;
            _samples.Clear();
            Cancelled?.Invoke();
        }

        public void ResetSavedCalibration()
        {
            PlayerPrefs.DeleteKey(CalibrationKey);
            throwMapper.SetIdealRiseFraction(.34f);
        }

        private void HandleThrow(ThrowGesture gesture)
        {
            if (!IsCalibrating) return;
            _samples.Add(gesture.NormalizedDelta.y);
            HapticFeedback.LightImpact();
            ProgressChanged?.Invoke(_samples.Count, RequiredThrows);
            if (_samples.Count < RequiredThrows) return;

            var ideal = ThrowCalibrationModel.ComputeIdeal(_samples.ToArray());
            throwMapper.SetIdealRiseFraction(ideal);
            PlayerPrefs.SetFloat(CalibrationKey, ideal);
            PlayerPrefs.Save();
            IsCalibrating = false;
            HapticFeedback.Success();
            Completed?.Invoke(ideal);
        }
    }
}
