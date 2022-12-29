using UdonSharp;
using UnityEngine;
using UnityEngine.Animations;
using VRC.SDKBase;

namespace Bhenaniguns
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class Projectile : UdonSharpBehaviour
    {
        [Header("Components")]
        [SerializeField] private Collider _cannonCollider = null;
        [SerializeField] private HitReporter _hitReporter = null;
        private string _firingPlayer = "";
        private string _targetHit = "";
        [SerializeField] private Rigidbody _selfRigidBody = null;
        [SerializeField] private Animator _selfAnimator = null;
        [SerializeField] private Collider _selfCollider = null;
        [SerializeField] private ParentConstraint _parentConstraint = null;

        [Header("Projectile Settings")]
        [SerializeField] private int _hitLayer = 0;
        [SerializeField] private Vector3 _velocity = new Vector3(0f, 2f, 0f);
        [SerializeField] private float _timeout = 5f;
        private Vector3 _fullstop = new Vector3(0f, 0f, 0f);
        [SerializeField] private bool _useExperimentalStick = false;
        [SerializeField] private Transform _exerimentalRayOrigin = null;

        [Header("Audio Settings")]
        [SerializeField] private AudioSource _audioFired = null;
        [SerializeField] private AudioSource _audioHit = null;
        [SerializeField] private AudioSource _audioMissed = null;
        [SerializeField] private float _audioPitchMin = 0.8f;
        [SerializeField] private float _audioPitchMax = 1.2f;

        private bool _noCollision = true;

        private void OnEnable()
        {
            _audioFired.pitch = Random.Range(_audioPitchMin, _audioPitchMax);
            _audioHit.pitch = Random.Range(_audioPitchMin, _audioPitchMax);
            _audioMissed.pitch = Random.Range(_audioPitchMin, _audioPitchMax);
            _audioFired.Play();
            _selfRigidBody.AddRelativeForce(_velocity);
            SendCustomEventDelayedSeconds("_timedout", _timeout);
            _firingPlayer = Networking.GetOwner(_cannonCollider.gameObject).displayName;
        }

        public void _timedout()
        {
            //If a collision has happened, don't timeout immediately so the appropriate collision animation can play.
            if (_noCollision)
            {
                _selfAnimator.SetTrigger("ProjectileWoosh");
            }
        }

        private void OnTriggerEnter(Collider _other)
        {
            if (_other != _cannonCollider && _noCollision)
            {
                _noCollision = false;

                //Stop the projectile so it doesn't continue to move after it has hit something.
                _selfCollider.enabled = false;
                _selfRigidBody.useGravity = false;
                _selfRigidBody.velocity = _fullstop;

                //if ( 0 ) //_useExperimentalStick && Physics.Raycast(_exerimentalRayOrigin.position, (_exerimentalRayOrigin.rotation * _exerimentalRayOrigin.right), out RaycastHit _raycastHit, 3, _hitLayer, QueryTriggerInteraction.UseGlobal))
                //{
                    //Debug.LogWarning("Raycast Hit", gameObject);
                    //transform.position = _raycastHit.point;
                    //Relocate Projectile to contact position
                    //Parent Projectile to contacted object
                //}
               // else
                //{
                    //Debug.LogWarning("No Raycast", gameObject);
                    //Grab what the current scale is, so it can be hopefully adjusted to remain the same after being parented to whatever it hit. Parented objects will have to be scaled uniformly for this to work as intended.
                    Vector3 _oldWorldscale = transform.lossyScale;
                    ConstraintSource _constSource = new ConstraintSource();
                    _constSource.sourceTransform = _other.transform;
                    _constSource.weight = 1;
                    _parentConstraint.SetSource(0, _constSource);
                    _parentConstraint.SetTranslationOffset(0, Quaternion.Inverse(_other.transform.rotation) * (transform.position - _other.transform.position));
                    _parentConstraint.SetRotationOffset(0, (Quaternion.Inverse(_other.transform.rotation) * transform.rotation).eulerAngles);
                    _parentConstraint.constraintActive = true;
                    //transform.SetParent(_other.transform);
                    transform.localScale += (_oldWorldscale - transform.lossyScale);
               // }

                if (_other.gameObject.layer == _hitLayer)
                {
                    if (Networking.LocalPlayer.displayName == _firingPlayer)
                    {
                        _targetHit = _other.name;
                        _hitReporter._projectileForwardedNotice(_firingPlayer, _targetHit);
                    }
                    _selfAnimator.SetTrigger("ProjectileHit");
                }
                else
                {
                    _selfAnimator.SetTrigger("ProjectileMissed");
                }
            }
        }
    }
}