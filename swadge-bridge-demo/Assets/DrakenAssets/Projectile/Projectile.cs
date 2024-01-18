using UdonSharp;
using UnityEngine;
using UnityEngine.Animations;
using VRC.SDKBase;

namespace DrakenStark
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class Projectile : UdonSharpBehaviour
    {
        [Header("Components")]
        [SerializeField] private DataManager _dataManager = null;
        [SerializeField] private byte _originID = 0;
        [SerializeField] private Collider _sourceCollider = null;
        //[SerializeField] private HitReporter _hitReporter = null;
        private VRCPlayerApi _reportingPlayer = null;
        [SerializeField] private Rigidbody _selfRigidBody = null;
        private bool _usesGravity = false;
        [SerializeField] private Animator _selfAnimator = null;
        [SerializeField] private Collider _selfCollider = null;
        [SerializeField] private ParentConstraint _parentConstraint = null;
        private ConstraintSource _parentConstSource = new ConstraintSource();
        [SerializeField] private int _projectileID = -1;

        [Header("Projectile Visual States")]
        private byte _firedLevel = 0;
        [SerializeField] private GameObject[] _pending = null;
        [SerializeField] private GameObject[] _hit = null;
        [SerializeField] private GameObject[] _missed = null;

        [Header("Projectile Settings")]
        [SerializeField] private int _enemyLayer = 0;
        //[SerializeField] private Vector3 _velocity = new Vector3(0f, 2f, 0f);
        [SerializeField] private Vector3 _velocity = new Vector3(0.1f, 0f, 0f);
        [SerializeField] private float _timeout = 5f;
        private int _timeoutIterations = 0;
        private bool _noCollision = true;
        private Vector3 _fullstop = Vector3.zero;
        //[SerializeField] private bool _useExperimentalStick = false;
        //[SerializeField] private Transform _exerimentalRayOrigin = null;

        [Header("Audio Settings")]
        [SerializeField] private AudioSource _audioSource = null;
        [SerializeField] private AudioClip[] _audioClipFired = null;
        [SerializeField] private AudioClip _audioClipHit = null;
        [SerializeField] private AudioClip _audioClipOther = null;
        [SerializeField] private float _audioPitchMin = 0.8f;
        [SerializeField] private float _audioPitchMax = 1.2f;


        public void _setupProjectile()
        {
            _usesGravity = _selfRigidBody.useGravity;
        }
        public void _setup(DataManager dataManager, int element, byte originID)
        {
            _dataManager = dataManager;
            _projectileID = element;
            _originID = originID;
        }
        public void _setupVelocity(Vector3 velocity)
        {
            _velocity = velocity;
        }

        public int _getProjectileID()
        {
            return _projectileID;
        }

        public void _enemyFiring(Collider _cannonFiring)
        {
            _reportingPlayer = null;
            _sourceCollider = _cannonFiring;
            _parentConstraint.constraintActive = false;
            _parentConstSource.weight = 0;
            _selfCollider.enabled = true;
            _selfRigidBody.useGravity = false;
            _noCollision = true;
            for (int i = 0; i < _pending.Length; i++)
            {
                _pending[i].SetActive(false);
                _hit[i].SetActive(false);
                _missed[i].SetActive(false);
            }
            _pending[0].SetActive(true);
            _firedLevel = 0;

            //Randomize Audio Pitch slightly.
            if (_dataManager._getAudioEnabled())
            {
                _audioSource.pitch = Random.Range(_audioPitchMin, _audioPitchMax);
                _audioSource.clip = _audioClipFired[0];
            }
        }

        public void _swadgeFiring()
        {
            if (_dataManager._getIsSwadgeHost())
            {
                _reportingPlayer = Networking.LocalPlayer;
            }
            else
            {
                _reportingPlayer = null;
            }
            _parentConstraint.constraintActive = false;
            _parentConstSource.weight = 0;
            _selfCollider.enabled = true;
            _selfRigidBody.useGravity = _usesGravity;
            _noCollision = true;
            for (int i = 0; i < _pending.Length; i++)
            {
                _pending[i].SetActive(false);
                _hit[i].SetActive(false);
                _missed[i].SetActive(false);
            }
            _pending[0].SetActive(true);
            _firedLevel = 0;

            //Send the Projectile forward.
            _selfRigidBody.velocity = Vector3.zero;
            _selfRigidBody.velocity = transform.rotation * _velocity;

            _timeoutIterations++;
            SendCustomEventDelayedSeconds("_timedout", _timeout);
            //Randomize Audio Pitch slightly.
            if (_dataManager._getAudioEnabled())
            {
                _audioSource.pitch = Random.Range(_audioPitchMin, _audioPitchMax);
                _audioSource.clip = _audioClipFired[0];
            }
        }

        public void _cannonFiring(byte level, VRCPlayerApi player)
        {
            _reportingPlayer = player;
            _parentConstraint.constraintActive = false;
            _parentConstSource.weight = 0;
            _selfCollider.enabled = true;
            _selfRigidBody.useGravity = false;
            _noCollision = true;
            for (int i = 0; i < _pending.Length; i++)
            {
                _pending[i].SetActive(false);
                _hit[i].SetActive(false);
                _missed[i].SetActive(false);
            }
            _pending[level].SetActive(true);
            _firedLevel = level;

            //Randomize Audio Pitch slightly.
            if (_dataManager._getAudioEnabled())
            {
                _audioSource.pitch = Random.Range(_audioPitchMin, _audioPitchMax);
                _audioSource.clip = _audioClipFired[level];
            }
        }

        private void OnEnable()
        {
            transform.SetParent(null);

            _selfAnimator.SetInteger("State", 0);

            if (_dataManager._getAudioEnabled())
            {
                _audioSource.Play();
            }

            //Send the Projectile forward.
            _selfRigidBody.velocity = Vector3.zero;
            //_selfRigidBody.AddRelativeForce(_velocity);
            //Still experimenting on a better solution that isn't physics/frames bound
            _selfRigidBody.velocity = transform.rotation * _velocity;

            //Allow the Projectile to timeout if it doesn't hit anything.
            _timeoutIterations++;
            SendCustomEventDelayedSeconds("_timedout", _timeout);
        }

        public void _timedout()
        {
            _timeoutIterations--;
            //If a collision has happened, don't timeout immediately so the appropriate collision animation can play.
            if (_noCollision && _timeoutIterations == 0)
            {
                _selfAnimator.SetInteger("State", 3);
            }
        }

        public void _cleanup()
        {
            if (_projectileID > -1)
            {
                _dataManager._projectileDespawned(/*Time.realtimeSinceStartup % 4294,*/ _projectileID);
            }
            gameObject.SetActive(false);
        }

        public override void OnPlayerTriggerEnter(VRCPlayerApi player)
        {
            //If the player hit is local and has a cannon associated, allow it to take damage.
            if (gameObject.layer == _enemyLayer && player.isLocal)
            {
                //string debugString = "Enemy Projectile (" + _originID + ") hit " + player.displayName;
                bool targetHit = false;
                HandCannon[] cannons = _dataManager._getCannons();
                //Must not use break in case player was manipulating any cannons before holding their current one.
                for (int i = 0; i < cannons.Length; i++)
                {
                    if (Utilities.IsValid(cannons[i]._getFiringPlayer()) && cannons[i]._getFiringPlayer().isLocal)
                    {
                        cannons[i]._hit(_firedLevel, _sourceCollider.transform.position);
                        targetHit = true;
                    }
                }

                if (targetHit)
                {
                    //Debug.LogWarning(debugString);

                    _noCollision = false;

                    //Stop the projectile so it doesn't continue to move after it has hit something.
                    _selfCollider.enabled = false;
                    _selfRigidBody.useGravity = false;
                    _selfRigidBody.velocity = _fullstop;

                    _selfAnimator.SetInteger("State", 1);
                    _pending[_firedLevel].SetActive(false);
                    _hit[_firedLevel].SetActive(false);
                    _missed[_firedLevel].SetActive(false);
                }
            }
        }

        private void OnTriggerEnter(Collider other)
        {
            if (gameObject.layer == _enemyLayer)
            {
                //string debugString = "Enemy Projectile (" + _originID + ") hit " + other.name;
                bool targetHit = false;
                if (other != _sourceCollider && _noCollision)
                {
                    //If projectile hit a cannon and the last player to use it was the local player, allow damage to be taken.
                    byte entityID = _dataManager._findEntityID(other, 3);
                    //debugString += " (" + entityID + ")";
                    if (entityID != 0)
                    {

                        if (entityID < _dataManager._getAboveCannonID())
                        {
                            HandCannon cannon = _dataManager._getCannon(entityID);
                            if (Utilities.IsValid(cannon._getFiringPlayer()) && cannon._getFiringPlayer().isLocal)
                            {
                                cannon._hit(_firedLevel, _sourceCollider.transform.position);
                                targetHit = true;
                            }
                        }
                        else if (entityID < _dataManager._getAboveEnemyTargetID())
                        {
                            _dataManager._getEnemyTarget(entityID)._prepHit();
                            targetHit = true;
                        }
                    }
                }


                if (targetHit)
                {
                    //Debug.LogWarning(debugString);

                    _noCollision = false;

                    //Stop the projectile so it doesn't continue to move after it has hit something.
                    _selfCollider.enabled = false;
                    _selfRigidBody.useGravity = false;
                    _selfRigidBody.velocity = _fullstop;

                    _selfAnimator.SetInteger("State", 1);
                    _pending[_firedLevel].SetActive(false);
                    _hit[_firedLevel].SetActive(false);
                    _missed[_firedLevel].SetActive(false);
                }
            }
            else
            {
                if (other != _sourceCollider && _noCollision)
                {
                    _noCollision = false;
                    //Debug.LogWarning("Projectile: Origin " + _originID, gameObject);

                    //Stop the projectile so it doesn't continue to move after it has hit something.
                    _selfCollider.enabled = false;
                    _selfRigidBody.useGravity = false;
                    _selfRigidBody.velocity = _fullstop;

                    /*if (_useExperimentalStick && Physics.Raycast(_exerimentalRayOrigin.position, (_exerimentalRayOrigin.rotation * _exerimentalRayOrigin.right), out RaycastHit _raycastHit, 3, _hitLayer, QueryTriggerInteraction.UseGlobal))
                    {
                        Debug.LogWarning("Raycast Hit", gameObject);
                        transform.position = _raycastHit.point;
                        //Relocate Projectile to contact position
                        //Parent Projectile to contacted object
                    }
                    else
                    {*/
                    //Debug.LogWarning("No Raycast", gameObject);
                    //Grab what the current scale is, so it can be hopefully adjusted to remain the same after being parented to whatever it hit. Parented objects will have to be scaled uniformly for this to work as intended.
                    Vector3 _oldWorldscale = transform.lossyScale;
                    _parentConstSource.sourceTransform = other.transform;
                    _parentConstSource.weight = 1;
                    _parentConstraint.SetSource(0, _parentConstSource);
                    _parentConstraint.SetTranslationOffset(0, Quaternion.Inverse(other.transform.rotation) * (transform.position - other.transform.position));
                    _parentConstraint.SetRotationOffset(0, (Quaternion.Inverse(other.transform.rotation) * transform.rotation).eulerAngles);
                    _parentConstraint.constraintActive = true;
                    //transform.SetParent(_other.transform);
                    transform.localScale += (_oldWorldscale - transform.lossyScale);
                    //}

                    if (other.gameObject.layer == _enemyLayer)
                    {
                        if (_reportingPlayer.isLocal)
                        {
                            //Debug.LogWarning("Projectile " + _manProjIndex + " from " + _firingPlayer + " has hit " + other.name + " at Power " + _firedLevel);
                            _dataManager._findHitEnemy(other, _originID, _firedLevel);
                            //_hitReporter._projectileForwardedNotice(_firingPlayer, _targetHit);
                        }
                        _selfAnimator.SetInteger("State", 1);
                        _pending[_firedLevel].SetActive(false);
                        _hit[_firedLevel].SetActive(true);
                        _missed[_firedLevel].SetActive(false);
                        if (_dataManager._getAudioEnabled())
                        {
                            _audioSource.clip = _audioClipHit;
                            _audioSource.Play();
                        }
                    }
                    else
                    {
                        _selfAnimator.SetInteger("State", 2);
                        _pending[_firedLevel].SetActive(false);
                        _hit[_firedLevel].SetActive(false);
                        _missed[_firedLevel].SetActive(true);
                        if (_dataManager._getAudioEnabled())
                        {
                            _audioSource.clip = _audioClipOther;
                            _audioSource.Play();
                        }
                    }
                }
            }
        }
    }
}