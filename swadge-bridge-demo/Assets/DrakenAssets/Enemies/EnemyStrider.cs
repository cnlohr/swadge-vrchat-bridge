using UdonSharp;
using UnityEngine;
using VRC.SDKBase;

namespace DrakenStark
{
    public class EnemyStrider : UdonSharpBehaviour
    {
        [SerializeField] private DataManager _dataManager = null;
        [SerializeField] private Collider _enemyRangeCollider = null;
        [SerializeField] private EnemyLogic _enemyLogic = null;
        [SerializeField] private Transform _enemyCannon = null;
        [SerializeField] private Transform _enemyCannonFacing = null;
        [SerializeField] private EnemyMovementObject _enemyMovementObject = null;
        [SerializeField] private EnemyMovementPlayer _enemyMovementPlayer = null;

        [SerializeField] private Projectile[] _projectiles = null;
        private int _projectileIndex = 0;
        private float _fireTime = 0f;
        [SerializeField] private float _cooldownTime = 2f;
        [SerializeField] private Vector3 _shotVelocity = new Vector3(0f, 0f, 0f);
        [SerializeField] private Vector3 _lookOffset = new Vector3(0f, 0f, 90f);
        private byte _targetType = 0;
        private int _coolIterations = 0;

        [Header("Raycast Variables")]
        [SerializeField] private LayerMask _blockingLayerMask = 2049;
        [SerializeField] private LayerMask _objectLayerMask = 33554432;
        [SerializeField] private LayerMask _playerLayerMask = 134219264;
        private RaycastHit _raycastHit = new RaycastHit();
        private bool _searching = false;
        private uint _ticksSearching = 0;
        [SerializeField] private uint _searchGiveupTicks = 15;
        [SerializeField] private bool _sceneDebugRays = false;
        private bool _isActive = false;

        private void OnEnable()
        {
            //Debug.LogWarning("Blocking: " + _blockingLayerMask.value + " Object: " + _objectLayerMask.value + " Player: " + _playerLayerMask.value);
            _ticksSearching = 0;
            _isActive = true;
            _searching = false;
            _periodic();
        }
        private void OnDisable()
        {
            _isActive = false;

            //Disable existing projectiles
            for (int i = 0; i < _projectiles.Length; i++)
            {
                _projectiles[i].gameObject.SetActive(false);
            }
        }

        public void _periodic()
        {
            if (_isActive)
            {
                //New target selected, check if the collider contains the target. If so, turn head and begin firing.
                if (!Utilities.IsValid(_enemyLogic._getTargetObject()))
                {
                    if (!Utilities.IsValid(_enemyLogic._getTargetPlayer()))
                    {
                        //There is no current target.
                        //Debug.LogWarning(transform.parent.name + " has no target.", transform.parent.gameObject);
                        _targetType = 0;
                    }
                    else
                    {
                        //Target is a player.
                        Vector3 playerCenter = Vector3.Lerp(_enemyLogic._getTargetPlayer().GetPosition(), _enemyLogic._getTargetPlayer().GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position, .5f);
                        _enemyCannon.LookAt(playerCenter, Vector3.up);
                        _targetType = 1;
                        if (_searching)
                        {
                            if (!Physics.Raycast(_enemyCannon.position, playerCenter - _enemyCannon.position, out _raycastHit, Vector3.Distance(_enemyCannon.position, playerCenter), _blockingLayerMask, QueryTriggerInteraction.Collide) &&
                                Physics.Raycast(_enemyCannon.position, playerCenter - _enemyCannon.position, out _raycastHit, 10, _playerLayerMask.value, QueryTriggerInteraction.UseGlobal))
                            {
                                if (_sceneDebugRays)
                                {
                                    Debug.DrawRay(_enemyCannon.position, playerCenter - _enemyCannon.position, Color.cyan, 1f);
                                }

                                _enemyMovementPlayer.enabled = false;
                                _enemyMovementObject._setupTarget(_enemyLogic.transform);
                                _enemyMovementObject.enabled = true;
                                _searching = false;
                                _prepFire();
                            }
                            else
                            {
                                if (_sceneDebugRays)
                                {
                                    //Debug.LogWarning(transform.parent.name + " is Searching and cannot see the target player " + _enemyLogic._getTargetPlayer().displayName, transform.parent.gameObject);
                                    Debug.DrawRay(_enemyCannon.position, playerCenter - _enemyCannon.position, Color.magenta, 1f);
                                    Debug.DrawRay(_raycastHit.point, Vector3.up, Color.magenta, 2f);
                                }

                                _enemyMovementObject.enabled = false;
                                _enemyMovementPlayer._setupTarget(_enemyLogic._getTargetPlayer());
                                _enemyMovementPlayer.enabled = true;

                                if (_enemyLogic.newTarget > 0 && _enemyLogic.newTarget < _dataManager._getAboveCannonID())
                                {
                                    ++_ticksSearching;
                                    if (_ticksSearching > _searchGiveupTicks)
                                    {
                                        _enemyLogic._targetDefeated(_enemyLogic.newTarget);
                                    }
                                }
                            }

                        }
                    }
                }
                else
                {
                    //Target is an object.
                    _enemyCannon.LookAt(_enemyLogic._getTargetObject().position, Vector3.up);
                    _targetType = 2;
                    //If searching and the raycast hits, stop and continue firing.
                    if (_searching)
                    {
                        if (!Physics.Raycast(_enemyCannon.position, (_enemyLogic._getTargetObject().position - _enemyCannon.position), out _raycastHit, Vector3.Distance(_enemyCannon.position, _enemyLogic._getTargetObject().position), _blockingLayerMask, QueryTriggerInteraction.Collide) &&
                            Physics.Raycast(_enemyCannon.position, (_enemyLogic._getTargetObject().position - _enemyCannon.position), out _raycastHit, 10, _objectLayerMask.value, QueryTriggerInteraction.UseGlobal))
                        {
                            if (_sceneDebugRays)
                            {
                                Debug.DrawRay(_enemyCannon.position, (_enemyLogic._getTargetObject().position - _enemyCannon.position), Color.blue, 1f);
                            }

                            _enemyMovementPlayer.enabled = false;
                            _enemyMovementObject._setupTarget(_enemyLogic.transform);
                            _enemyMovementObject.enabled = true;
                            _searching = false;
                            _prepFire();
                        }
                        else
                        {
                            if (_sceneDebugRays)
                            {
                                //Debug.LogWarning(transform.parent.name + " is Searching and cannot see the target object " + _enemyLogic._getTargetObject().name, transform.parent.gameObject);
                                Debug.DrawRay(_enemyCannon.position, (_enemyLogic._getTargetObject().position - _enemyCannon.position), Color.red, 2f);
                                Debug.DrawRay(_raycastHit.point, Vector3.up, Color.red, 2f);
                            }

                            _enemyMovementPlayer.enabled = false;
                            _enemyMovementObject._setupTarget(_enemyLogic._getTargetObject());
                            _enemyMovementObject.enabled = true;

                            if (_enemyLogic.newTarget > 0 && _enemyLogic.newTarget < _dataManager._getAboveCannonID())
                            {
                                ++_ticksSearching;
                                if (_ticksSearching > _searchGiveupTicks)
                                {
                                    _enemyLogic._targetDefeated(_enemyLogic.newTarget);
                                }
                            }
                        }

                    }
                }

                SendCustomEventDelayedSeconds("_periodic", 1f);
            }
        }

        public void _setup(DataManager dataManager, Projectile[] projectiles)
        {
            _dataManager = dataManager;
            _projectiles = projectiles;
        }

        public void _refreshTargeting()
        {
            //New target selected, check if the collider contains the target. If so, turn head and begin firing.
            if (!Utilities.IsValid(_enemyLogic._getTargetObject()))
            {
                if (!Utilities.IsValid(_enemyLogic._getTargetPlayer()))
                {
                    //There is no current target.
                    _targetType = 0;
                    //Debug.LogWarning(transform.parent.name + " has no target.", transform.parent.gameObject);
                }
                else
                {
                    //Target is a player.
                    _targetType = 1;
                    if (_enemyRangeCollider.bounds.Contains(_enemyLogic._getTargetPlayer().GetPosition()))
                    {
                        _attackPlayer(_enemyLogic._getTargetPlayer());
                    }
                    else
                    {
                        _reachPlayer(_enemyLogic._getTargetPlayer());
                    }
                }
            }
            else
            {
                //Target is an object.
                _targetType = 2;
                if (_enemyRangeCollider.bounds.Contains(_enemyLogic._getTargetObject().position))
                {
                    _attackObject(_enemyLogic._getTargetObject());
                }
                else
                {
                    _reachObject(_enemyLogic._getTargetObject());
                }
            }
        }

        public override void OnPlayerTriggerEnter(VRCPlayerApi player)
        {
            if (_enemyLogic._noPlayerTarget())
            {
                byte cannonID = _dataManager._findCannonID(player);
                //Debug.LogWarning(transform.parent.name + " sees " + player.displayName + " with cannonID " + cannonID, transform.parent.gameObject);
                if (cannonID != 0)
                {
                    //Debug.LogWarning(transform.parent.name + " found (" + cannonID + ")" + player.displayName);
                    _enemyLogic._detectedPlayer(cannonID);
                }
            }

            //Check if the player is the current target.
            if (_enemyLogic._getTargetPlayer() != null && player == _enemyLogic._getTargetPlayer())
            {
                _enemyMovementPlayer.enabled = false;
                _enemyMovementObject._setupTarget(_enemyLogic.transform);
                _enemyMovementObject.enabled = true;
                _attackPlayer(player);
            }
        }
        public override void OnPlayerTriggerExit(VRCPlayerApi player)
        {
            //Check if the player is the current target.
            if (_enemyLogic._getTargetPlayer() != null && player == _enemyLogic._getTargetPlayer())
            {
                _reachPlayer(player);
            }
        }

        private void OnTriggerEnter(Collider other)
        {
            if (_enemyLogic._noPlayerTarget())
            {
                byte swadgeID = _dataManager._findEntityID(other, 2);

                if (swadgeID != 0)
                {
                    _enemyLogic._detectedPlayer(swadgeID);
                }
            }

            //Debug.LogWarning(transform.parent.name + " found " + other.transform.parent.name);
            //Check if the object is the current target.
            //Debug.LogWarning(transform.parent.name + " reached " + other.name);
            if (Utilities.IsValid(_enemyLogic._getTargetObject()) && other.transform == _enemyLogic._getTargetObject())
            {
                _enemyMovementPlayer.enabled = false;
                _enemyMovementObject._setupTarget(_enemyLogic.transform);
                _enemyMovementObject.enabled = true;
                _attackObject(other.transform);
            }
        }
        private void OnTriggerExit(Collider other)
        {
            //Check if the object is the current target.
            //Debug.LogWarning(transform.parent.name + " out of range " + other.name);
            if (Utilities.IsValid(_enemyLogic._getTargetObject()) && other.transform == _enemyLogic._getTargetObject())
            {
                _reachObject(other.transform);
            }
        }
        private void OnCollisionEnter(Collision other)
        {
            //Debug.LogWarning(transform.parent.name + " found " + other.transform.parent.name);
            //Check if the object is the current target.
            //Debug.LogWarning(transform.parent.name + " reached " + other.name);
            if (Utilities.IsValid(_enemyLogic._getTargetObject()) && other.transform == _enemyLogic._getTargetObject())
            {
                _enemyMovementPlayer.enabled = false;
                _enemyMovementObject._setupTarget(_enemyLogic.transform);
                _enemyMovementObject.enabled = true;
                _attackObject(other.transform);
            }
        }
        private void OnCollisionExit(Collision other)
        {
            //Check if the object is the current target.
            //Debug.LogWarning(transform.parent.name + " out of range " + other.name);
            if (Utilities.IsValid(_enemyLogic._getTargetObject()) && other.transform.parent == _enemyLogic._getTargetObject())
            {
                _reachObject(other.transform.parent);
            }
        }

        private void _attackPlayer(VRCPlayerApi player)
        {
            _enemyMovementPlayer.enabled = false;
            _enemyMovementObject._setupTarget(transform.parent);
            _enemyMovementObject.enabled = true;
            _enemyCannon.LookAt(Vector3.Lerp(player.GetPosition(), player.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position, .5f), Vector3.up);
            //Debug.LogWarning(transform.parent.name + " found target: " + player.displayName, transform.parent.gameObject);

            //Fire Projectile
            //_prepFire();
            _searching = true;
            _ticksSearching = 0;
        }
        private void _reachPlayer(VRCPlayerApi player)
        {
            _enemyMovementObject.enabled = false;
            _enemyMovementPlayer._setupTarget(player);
            _enemyMovementPlayer.enabled = true;
            _enemyCannon.LookAt(Vector3.Lerp(player.GetPosition(), player.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position, .5f), Vector3.up);
        }

        private void _attackObject(Transform target)
        {
            _enemyMovementPlayer.enabled = false;
            _enemyMovementObject._setupTarget(transform.parent);
            _enemyMovementObject.enabled = true;
            _enemyCannon.LookAt(target.position);
            //Debug.LogWarning(transform.parent.name + " found target: " + target.name + " (Parent is " + target.parent.name +")", transform.parent.gameObject);

            //Fire Projectile
            //_prepFire();
            _searching = true;
            _ticksSearching = 0;
        }
        private void _reachObject(Transform target)
        {
            _enemyMovementPlayer.enabled = false;
            _enemyMovementObject._setupTarget(target);
            _enemyMovementObject.enabled = true;
            _enemyCannon.LookAt(target.position);
        }

        private void _prepFire()
        {
            if (_coolIterations == 0 && _isActive)
            {
                SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "fireCommon");
            }
        }

        public void fireCommon()
        {
            _coolIterations++;
            SendCustomEventDelayedSeconds("_cooled", _cooldownTime);
            _ticksSearching = 0;

            //Prepare next Projectile at level.
            _projectileIndex++;
            if (_projectileIndex >= _projectiles.Length)
            {
                _projectileIndex = 0;
            }
            _fireTime = Time.realtimeSinceStartup % 4294;

            //Detect if Projectile at Index is in use, remove it if so.
            if (_projectiles[_projectileIndex].gameObject.activeSelf)
            {
                _projectiles[_projectileIndex].gameObject.SetActive(false);
                //Report Despawned Projectile
                _dataManager._projectileDespawned(_projectiles[_projectileIndex]._getProjectileID());
            }


            //Point the Projectile at the target.
            switch(_targetType)
            {
                case 1:
                    {
                        _enemyCannon.LookAt(Vector3.Lerp(_enemyLogic._getTargetPlayer().GetPosition(), _enemyLogic._getTargetPlayer().GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position, .5f), Vector3.up);
                        break;
                    }
                case 2:
                    {
                        _enemyCannon.LookAt(_enemyLogic._getTargetObject().position);
                        break;
                    }
            }
            _projectiles[_projectileIndex].transform.position = _enemyCannonFacing.position;
            _projectiles[_projectileIndex].transform.rotation = _enemyCannonFacing.rotation * Quaternion.Euler(_lookOffset);

            //Report Fired Projectile
            if (_dataManager._getIsSwadgeHost())
            {
                _dataManager._projectileFired(_projectiles[_projectileIndex]._getProjectileID(), _projectiles[_projectileIndex].transform, _fireTime);
            }
            //Debug.Log("t" + _fireTime + ",py" + _firePosition.y + ",px" + _firePosition.x + ",pz" + _firePosition.z + ",rw" + _fireRotation.w + ",rx" + _fireRotation.x + ",ry" + _fireRotation.y + ",rz" + _fireRotation.z, gameObject);

            //Enable the Projectile at Index.
            _projectiles[_projectileIndex]._setupVelocity(_shotVelocity);
            _projectiles[_projectileIndex]._enemyFiring(_enemyLogic._getCollider());
            _projectiles[_projectileIndex].gameObject.SetActive(true);
            //Debug.LogWarning("Firing Cannon " + _manCanIndex + ", Projectile " + _projectiles[_projectileIndex]._getProjectileID() + ", Power " + level);

        }

        public void _cooled()
        {
            _coolIterations--;
            if (_coolIterations == 0 && _isActive)
            {
                Vector3 targetPos = Vector3.zero;
                int targetLayerMask = 0;
                switch (_targetType)
                {
                    case 0:
                        {
                            //There is no target
                            return;
                        }
                    case 1:
                        {
                            targetPos = Vector3.Lerp(_enemyLogic._getTargetPlayer().GetPosition(), _enemyLogic._getTargetPlayer().GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position, .5f);
                            targetLayerMask = _playerLayerMask.value;
                            break;
                        }
                    case 2:
                        {
                            targetPos = _enemyLogic._getTargetObject().position;
                            targetLayerMask = _objectLayerMask.value;
                            break;
                        }
                }
                if (!Physics.Raycast(_enemyCannon.position, targetPos - _enemyCannon.position, out _raycastHit, Vector3.Distance(_enemyCannon.position, targetPos), _blockingLayerMask, QueryTriggerInteraction.Collide) &&
                    Physics.Raycast(_enemyCannon.position, targetPos - _enemyCannon.position, out _raycastHit, 10, targetLayerMask, QueryTriggerInteraction.Collide))
                {
                    //Target was not blocked and hit by the appropriate Raycast
                    if (_sceneDebugRays)
                    {
                        Debug.DrawRay(_enemyCannon.position, targetPos - _enemyCannon.position, Color.green, 2f);
                        //Debug.LogWarning(transform.parent.name + " can see targetID " + _enemyLogic.newTarget + "." + Time.deltaTime);
                    }

                    SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "fireCommon");
                    return;
                }

                if (_sceneDebugRays)
                {
                    //Debug.LogWarning(transform.parent.name + " is Attacking and cannot see its target.", transform.parent.gameObject);
                    Debug.DrawRay(_enemyCannon.position, targetPos - _enemyCannon.position, Color.yellow, 2f);
                    Debug.DrawRay(_raycastHit.point, Vector3.up, Color.yellow, 2f);
                }

                _searching = true;
                _ticksSearching = 0;
                switch (_targetType)
                {
                    case 1:
                        {
                            _enemyMovementObject.enabled = false;
                            _enemyMovementPlayer._setupTarget(_enemyLogic._getTargetPlayer());
                            _enemyMovementPlayer.enabled = true;
                            break;
                        }
                    case 2:
                        {
                            _enemyMovementPlayer.enabled = false;
                            _enemyMovementObject._setupTarget(_enemyLogic._getTargetObject());
                            _enemyMovementObject.enabled = true;
                            break;
                        }
                }
            }
        }
    }
}