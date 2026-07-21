using System;
using UnityEngine;
using ShinobiZero.Core;

namespace ShinobiZero.Runtime
{
    [RequireComponent(typeof(Rigidbody), typeof(Collider))]
    public sealed class ShurikenProjectile : MonoBehaviour
    {
        [SerializeField] private float spinDegreesPerSecond = 1440f;
        [SerializeField] private float maximumLifetime = 8f;
        [SerializeField, Min(0f)] private float surfaceClearance = .015f;
        public event Action<ShurikenProjectile, TargetBoard, Vector3> BoardHit;
        public event Action<ShurikenProjectile> Missed;

        private Rigidbody _body;
        private bool _resolved;

        private void Awake()
        {
            _body = GetComponent<Rigidbody>();
            _body.collisionDetectionMode = CollisionDetectionMode.ContinuousDynamic;
            _body.interpolation = RigidbodyInterpolation.Interpolate;
        }

        public void Launch(Vector3 velocity, float spinBias)
        {
            if (velocity.sqrMagnitude > .0001f)
                transform.rotation = Quaternion.LookRotation(velocity.normalized, transform.up);
            var spin = ShurikenFlightModel.Spin(spinDegreesPerSecond, spinBias);
            _body.isKinematic = false;
            _body.maxAngularVelocity = spin.RequiredAngularLimit;
            _body.linearVelocity = velocity;
            _body.angularVelocity = transform.forward * spin.RadiansPerSecond;
            Destroy(gameObject, maximumLifetime);
        }

        public void Cancel()
        {
            _resolved = true;
            Destroy(gameObject);
        }

        private void OnCollisionEnter(Collision collision)
        {
            if (_resolved) return;
            if (!collision.collider.TryGetComponent(out TargetBoard board))
            {
                _resolved = true;
                Missed?.Invoke(this);
                Destroy(gameObject);
                return;
            }
            _resolved = true;
            var contact = collision.GetContact(0);
            _body.linearVelocity = Vector3.zero;
            _body.angularVelocity = Vector3.zero;
            _body.isKinematic = true;
            if (contact.normal.sqrMagnitude > .0001f)
                transform.rotation = Quaternion.FromToRotation(transform.forward, -contact.normal) * transform.rotation;
            transform.position = contact.point + contact.normal * surfaceClearance;
            BoardHit?.Invoke(this, board, contact.point);
        }

        private void OnDestroy()
        {
            if (_resolved) return;
            _resolved = true;
            Missed?.Invoke(this);
        }
    }
}
