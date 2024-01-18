using UdonSharp;
using UnityEngine;
using VRC.SDKBase;

namespace DrakenStark
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class EnemyLogic : UdonSharpBehaviour
    {
        [Header("Controller Management")]
        [SerializeField] private DataManager _dataManager = null;
        [SerializeField] private GameObject _enemyRootObject = null;
        [SerializeField] private byte _enemyType = 0;
        [SerializeField] private SwadgeEnemyPosSync _swadgeSync = null;
        [SerializeField] private int _enemyID = -1;
        private byte _hitpoints = 5;
        [SerializeField] private byte _startingHP = 5;
        [SerializeField] private float _respawnTime = 3f;

        [Header("AI Management")]
        [SerializeField] private EnemyMovementPlayer _enemyMovementPlayer = null;
        [SerializeField] private EnemyMovementObject _enemyMovementObject = null;
        [SerializeField] private UdonSharpBehaviour _initialTarget = null;
        [SerializeField] private uint _initialPriority = 1;
        [SerializeField] private uint _firstHitBonusPriority = 1;
        //Cannot use Transform as a synced variable, so a lookup table through the DataManager is used and called when the variable is updated.
        [UdonSynced, FieldChangeCallback("newTarget")] private byte _currentTarget = 0;
        private VRCPlayerApi _currentTargetPlayer = null;
        private Transform _currentTargetObject = null;
        private byte[] _knownTargets = new byte[256];
        private byte _targetCount = 0;
        private uint[] _targetPriority = new uint[256];
        private uint _currentPriority = 0;
        private bool _unknownTarget = true;
        [SerializeField] private UdonSharpBehaviour _enemyTypeScript = null;

        [Header("Enemy Management")]
        [SerializeField] private MeshRenderer _meshRenderer = null;
        [SerializeField] private SkinnedMeshRenderer[] _skinnedRenderers = null;
        [SerializeField] private Collider _collider = null;
        private Color _normColor = Color.white;
        private int _hitIterations = 0;
        [SerializeField] private HitManager _hitManager = null;


        [Header("Debug Options")]
        [SerializeField] private Vector3 _startingPos = Vector3.zero;

        public byte newTarget
        {
            set
            {
                _currentTarget = value;
                if (_currentTarget.Equals(0))
                {
                    _currentTargetPlayer = null;
                    _currentTargetObject = null;
                    _enemyTypeScript.SendCustomEvent("_refreshTargeting");
                }
                else if (_currentTarget < _dataManager._getAboveCannonID())
                {
                    //It's more immersive to have the AI hunt the player location itself rather than the pickup, which may still be used as a fallback.
                    if (Utilities.IsValid(_dataManager._getCannonPickup(_currentTarget)))
                    {
                        if (Utilities.IsValid(_dataManager._getCannonPickup(_currentTarget).currentPlayer))
                        {
                            _currentTargetObject = null;
                            _currentTargetPlayer = _dataManager._getCannonPickup(_currentTarget).currentPlayer;
                            _enemyTypeScript.SendCustomEvent("_refreshTargeting");
                        }
                        else
                        {
                            _currentTargetPlayer = null;
                            _currentTargetObject = _dataManager._getTargetID(this, _currentTarget);
                            _enemyTypeScript.SendCustomEvent("_refreshTargeting");
                        }
                    }
                }
                else
                {
                    _currentTargetPlayer = null;
                    _currentTargetObject = _dataManager._getTargetID(this, _currentTarget);
                    _enemyTypeScript.SendCustomEvent("_refreshTargeting");
                }

                //Debug.LogWarning(transform.parent.name + " (HP:" + _hitpoints + ") is now targeting " + _currentTarget + " (" + _dataManager._getTargetID(this, _currentTarget).parent.name + ")", transform.parent.gameObject);
            }
            get => _currentTarget;
        }

        private void OnEnable()
        {
            //Debug.LogWarning(transform.parent.name + " respawned.");

            //Initialize Enemy NavMesh Agent
            _enemyMovementObject._setNavMeshAgent(true);

            //Initialize Enmity System
            if (Utilities.IsValid(_initialTarget))
            {
                newTarget = _dataManager._getTarget(_initialTarget);
                _targetPriority[0] = _initialPriority;
                _currentPriority = _initialPriority;
                _knownTargets[0] = newTarget;
                _targetCount = 1;
            }
            else
            {
                newTarget = 0;
                _currentPriority = 0;
                _targetCount = 0;
            }
            //Commented out for testing.
            //RequestSerialization();

            _hitpoints = _startingHP;

            //Setup Swadge Communication if Local Player is the Swadge Host
            _toggleSwadgeHosting(_dataManager._getIsSwadgeHost());
            
            RequestSerialization();
            //Randomized targets is only for testing.
            //SendCustomEventDelayedFrames("_initializeTargeting", 1);
        }

        public void _toggleSwadgeHosting(bool toggle)
        {
            _swadgeSync._localSetup(_enemyID, _enemyType, _collider.transform);
            _swadgeSync.enabled = toggle;
        }

        public void _setup(DataManager dataManager, int element)
        {
            _dataManager = dataManager;
            _enemyID = element;
            _startingPos = _collider.transform.position;

            //Record the starting color for reference when damage is taken.
            if (Utilities.IsValid(_meshRenderer))
            {
                _normColor = _meshRenderer.sharedMaterial.color;
            }
            else
            {
                _normColor = _skinnedRenderers[0].sharedMaterial.color;
            }
        }

        public void _enemyDisable()
        {

        }

        public void _enemyEnable()
        {

        }

        /*
        public void _initializeTargeting()
        {
            newTarget = (byte)Random.Range(1, _dataManager._getAboveCannonID());
            RequestSerialization();
            //Debug.LogWarning(name + " " + _entityID + " has been given TargetID: " + newTarget, gameObject);
        }*/

        public Collider _getCollider()
        {
            return _collider;
        }

        public HitManager _getHitManager()
        {
            return _hitManager;
        }

        public int _getEnemyID()
        {
            return _enemyID;
        }

        public VRCPlayerApi _getTargetPlayer()
        {
            if (Utilities.IsValid(_currentTargetPlayer))
            {
                return _currentTargetPlayer;
            }
            return null;
        }
        public Transform _getTargetObject()
        {
            if (Utilities.IsValid(_currentTargetObject))
            {
                return _currentTargetObject;
            }
            return null;
        }

        #region Receiving Damage and Removal

        public bool _noPlayerTarget()
        {
            //Debug.LogWarning(transform.parent.name + " currentPriority: " + _currentPriority + " initialPriority: " + _initialPriority, transform.parent.gameObject);
            return !(_currentPriority > _initialPriority);
        }

        public void _detectedPlayer(byte cannonID)
        {
            //Debug.LogWarning(transform.parent.name + " detected " + cannonID + ".");
            //If _targetCount is zero, add to the first element.
            if (_targetCount == 0)
            {
                _knownTargets[_targetCount] = cannonID;
                _targetPriority[_targetCount] = 1 + _firstHitBonusPriority;
                if (_targetPriority[_targetCount] > _currentPriority)
                {
                    newTarget = cannonID;
                    _currentPriority = _targetPriority[_targetCount];
                }
                _targetCount++;
            }
            else
            {
                _unknownTarget = true;
                //Since _targetCount is more than zero, check _knownTargets for the new target.
                for (byte i = 0; i < _targetCount; i++)
                {
                    if (_knownTargets[i] == cannonID)
                    {
                        _unknownTarget = false;
                        break;
                    }
                }

                if (_unknownTarget)
                {
                    //This code will not be reached unless it is an unknown target.
                    _knownTargets[_targetCount] = cannonID;
                    _targetPriority[_targetCount] = 1 + _firstHitBonusPriority;
                    if (_targetPriority[_targetCount] > _currentPriority)
                    {
                        newTarget = cannonID;
                        _currentPriority = _targetPriority[_targetCount];
                    }
                    _targetCount++;
                }
            }
        }

        public void _hit(byte swadge)
        {
            _adjustPriority(swadge, 0);
        }

        public void _hit(byte cannon, byte level)
        {
            //Debug.LogWarning(cannon + " fired projectile at level " + level, gameObject);
            _adjustPriority(cannon, level);
        }

        private void _adjustPriority(byte targetID, byte damage)
        {
            //Debug.LogWarning(transform.parent.name + " was hit for " + damage + " out of " + _hitpoints + " by originID: " + targetID, transform.parent.gameObject);
            uint newEnmity = 0;

            damage++;
            //Refect damage was made
            if (_hitpoints <= damage)
            {
                _hitpoints = 0;
                defeated();
                //Debug.LogWarning("Hit Damage " + damage + " (Remaining HP " + _hitpoints + ") Origin Target " + targetID + ", Enmity " + newEnmity + " vs Current Target " + newTarget + " & Enmity " + _currentPriority, gameObject);
                return;
            }
            else
            {
                _hitpoints -= damage;

                //Flash model to show it was hit
                if (Utilities.IsValid(_skinnedRenderers) && _skinnedRenderers.Length > 0)
                {
                    for (int i = 0; i < _skinnedRenderers.Length; i++)
                    {
                        _skinnedRenderers[i].materials[0].color = Color.red;
                    }
                }
                if (Utilities.IsValid(_meshRenderer))
                {
                    _meshRenderer.materials[0].color = Color.red;
                }
                _hitIterations++;
                SendCustomEventDelayedSeconds("postDamaged", 0.25f);
            }

            //If _targetCount is zero, add to the first element.
            if (_targetCount == 0)
            {
                _knownTargets[_targetCount] = targetID;
                _targetPriority[_targetCount] = damage + _firstHitBonusPriority;
                newEnmity = _targetPriority[_targetCount];
                if (_targetPriority[_targetCount] > _currentPriority)
                {
                    newTarget = targetID;
                    _currentPriority = _targetPriority[_targetCount];
                }
                //Debug.LogWarning(name + " noticed it was hit by " + player + " with TargetID: " + targetID + " Enmity: " + _targetPriority[_targetCount], gameObject);
                _targetCount++;
            }
            else
            {
                _unknownTarget = true;
                //Since _targetCount is more than zero, check _knownTargets for the new target.
                for (byte i = 0; i < _targetCount; i++)
                {
                    if (_knownTargets[i] == targetID)
                    {
                        _targetPriority[i] += damage;
                        newEnmity = _targetPriority[i];
                        if (_targetPriority[i] > _currentPriority)
                        {
                            newTarget = targetID;
                            _currentPriority = _targetPriority[i];
                        }
                        //Debug.LogWarning(name + " noticed it was hit by " + player + " with TargetID: " + targetID + " Enmity: " + _targetPriority[i], gameObject);
                        _unknownTarget = false;
                        break;
                    }
                }

                if (_unknownTarget)
                {
                    //This code will not be reached unless it is an unknown target.
                    _knownTargets[_targetCount] = targetID;
                    _targetPriority[_targetCount] = damage + _firstHitBonusPriority;
                    newEnmity = _targetPriority[_targetCount];
                    if (_targetPriority[_targetCount] > _currentPriority)
                    {
                        newTarget = targetID;
                        _currentPriority = _targetPriority[_targetCount];
                    }
                    //Debug.LogWarning(name + " noticed it was hit by " + player + " with TargetID: " + targetID + " Enmity: " + _targetPriority[_targetCount], gameObject);
                    _targetCount++;
                }
            }
            //Debug.LogWarning("Hit Damage " + damage + " (Remaining HP " + _hitpoints + ") Origin Target " + targetID + ", Enmity " + newEnmity + " vs Current Target " + newTarget + " & Enmity " + _currentPriority, gameObject);

            RequestSerialization();
        }

        public void _targetDefeated(byte targetID)
        {
            if (targetID > 0)
            {
                //string debugString1 = "KnownTargets Before: ";
                //string debugString2 = "KnownTargets After: ";
                //int removedTarget = -1;
                bool foundTarget = false;
                byte nextTarget = 0;
                
                /*
                for (byte i = 0; i < _targetCount; i++)
                {
                    debugString1 += i + "(" + _knownTargets[i] + ", " + _targetPriority[i] + ") ";
                }*/

                for (byte i = 0; i < _targetCount; i++)
                {
                    if (_knownTargets[i] == targetID)
                    {
                        //removedTarget = i;
                        foundTarget = true;
                        _targetCount--;
                    }
                    if (foundTarget && i <= _targetCount)
                    {
                        _knownTargets[i] = _knownTargets[i + 1];
                    }
                    if (_targetPriority[i] > nextTarget)
                    {
                        nextTarget = _knownTargets[i];
                        _currentPriority = _targetPriority[i];
                    }
                }
                newTarget = nextTarget;

                /*
                for (byte i = 0; i < _targetCount; i++)
                {
                    debugString2 += i + "(" + _knownTargets[i] + ", " + _targetPriority[i] + ") ";
                }

                if (foundTarget)
                {
                    Debug.LogWarning(transform.parent.name + " defeated " + removedTarget + ". Moving on to " + nextTarget, transform.parent.gameObject);
                    Debug.LogWarning(debugString1);
                    Debug.LogWarning(debugString2);
                }*/
            }
        }

        public void postDamaged()
        {
            _hitIterations--;
            //Stay visually hurt until not being hurt.
            if (_hitIterations == 0)
            {
                if (Utilities.IsValid(_skinnedRenderers) && _skinnedRenderers.Length > 0)
                {
                    for (int i = 0; i < _skinnedRenderers.Length; i++)
                    {
                        _skinnedRenderers[i].materials[0].color = _normColor;
                    }
                }
                if (Utilities.IsValid(_meshRenderer))
                {
                    _meshRenderer.materials[0].color = _normColor;
                }
            }
        }

        private void OnDisable()
        {
            //Cancel any existing AI Navigation.
            _enemyMovementPlayer.enabled = false;
            _enemyMovementObject.enabled = false;
            _enemyMovementObject._setNavMeshAgent(false);

            //Ensure Swadges aren't rendering this EntityID.
            _swadgeSync.enabled = false;
            _dataManager._removeSwadgeEntity(_enemyID);

            //Put the EntityID in a disabled state.
            _enemyRootObject.SetActive(false);
        }

        public void defeated()
        {
            //Cancel any existing AI Navigation.
            _enemyMovementPlayer.enabled = false;
            _enemyMovementObject.enabled = false;
            _enemyMovementObject._setNavMeshAgent(false);

            //Ensure Swadges aren't rendering this EntityID.
            _swadgeSync.enabled = false;
            _dataManager._removeSwadgeEntity(_enemyID);

            //Put the EntityID in a disabled state.
            _enemyRootObject.SetActive(false);

            //Start the process to spawn back in.
            SendCustomEventDelayedSeconds("_startRespawn", _respawnTime);
        }

        public void _startRespawn()
        {
            if (Networking.GetOwner(gameObject).isLocal)
            {
                SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "respawn");
            }
        }

        public void respawn()
        {
            _enemyRootObject.transform.position = _startingPos;
            _enemyRootObject.SetActive(true);
        }

        #endregion
    }
}