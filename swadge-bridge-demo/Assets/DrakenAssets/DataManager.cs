using UdonSharp;
using UnityEngine;
using VRC.SDK3.Components;
using VRC.SDKBase;

namespace DrakenStark
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class DataManager : UdonSharpBehaviour
    {
        [SerializeField] private bool _isSwadgeHost = false;
        [SerializeField] private bool _audioEnabled = false;
        [SerializeField] private bool _dualwielding = false;
        [SerializeField] private bool _gameEnabled = false;
        [SerializeField] private float _swadgeProjectSpeed = 9f;
        [SerializeField] private SwadgeIntegration _swadgeIntegration = null;
        [Tooltip("Cannons will be automatically adjusted if it comes up short. Fully define it in the editor to save a little on load time.")]
        [SerializeField] private HandCannon[] _cannons = new HandCannon[0];
        [SerializeField] private VRCPickup[] _pickups = new VRCPickup[0];
        [SerializeField] private Collider[] _cannonColliders = new Collider[0];
        [SerializeField] private SwadgeCannonSync _cannonSync = null;
        [SerializeField] private int _aboveCannonID = 0;
        [SerializeField] private Projectile[] _vRCProjectiles = new Projectile[0];
        [SerializeField] private EnemyLogic[] _enemyLogics = new EnemyLogic[0];
        [SerializeField] private Collider[] _enemyColliders = new Collider[0];
        [SerializeField] private EnemyTarget[] _enemyTargets = new EnemyTarget[0];
        [SerializeField] private int _aboveEnemyTargetID = 0;
        [SerializeField] private SwadgeShip[] _swadgeShips = new SwadgeShip[0];
        [SerializeField] private Transform[] _swadgeShipTrans = new Transform[0];
        [SerializeField] private Projectile[] _swadgeProjectiles = new Projectile[0];
        [SerializeField] private int _aboveSwadgeShipID = 0;

        //Enemy Types
        //
        // 0 walkers  (12)
        // 1 turrets  (10)
        // 2 planters (10)
        // 3 fliers    (8)
        // 4 targets   (8)
        // 5 battery  (replaces planters)
        // 6 exploded battery (replaces batteries)

        //Swadge Limits
        //
        // enemyTypes = 0 to 7
        // boolets = 0 to 239
        //
        // cannons = 0 to 23   (24)
        // swadges = 0 to 102 (103)
        // enemies = 0 to 47   (48)
        //
        // Only need to account for players that pickup cannons
        // Players = 0 to 83   (84)

        private void Start()
        {
            if (_isSwadgeHost)
            {
                _toggleSwadgeHosting(true);
            }
        }

        public void _audioToggle(bool toggle)
        {
            _audioEnabled = toggle;
        }

        public void _toggleSwadgeHosting(bool toggle)
        {
            _isSwadgeHost = toggle;
            _cannonSync.enabled = toggle;
            for (int i = 0; i < _enemyLogics.Length; i++)
            {
                _enemyLogics[i]._toggleSwadgeHosting(toggle);
            }
        }

        public void _toggleGameEnabled(bool toggle)
        {
            _gameEnabled = toggle;
        }
        public bool _getGameEnabled()
        {
            return _gameEnabled;
        }

        public void _toggleCannons(bool toggle)
        {
            if (toggle)
            {
                for (int i = 0; i < _cannons.Length; i++)
                {
                    _cannons[i]._cannonEnable();
                }
            }
            else
            {
                for (int i = 0; i < _cannons.Length; i++)
                {
                    _cannons[i]._cannonDisable();
                }
            }
        }


        public void _toggleEnemies(bool toggle)
        {
            if (toggle)
            {
                for (int i = 0; i < _cannons.Length; i++)
                {
                    _enemyLogics[i]._enemyEnable();
                }
            }
            else
            {
                for (int i = 0; i < _cannons.Length; i++)
                {
                    _enemyLogics[i]._enemyDisable();
                }
            }
        }

        public bool _getDualWielding()
        {
            return _dualwielding;
        }

        public bool _getIsSwadgeHost()
        {
            return _isSwadgeHost;
        }

        public bool _getAudioEnabled()
        {
            return _audioEnabled;
        }

        public void _updateBooletArrayFromSwadges(Vector3[] booletPos, Vector3[] booletTo, float[] booletTimes)
        {
            for (int i = 0; i < _swadgeProjectiles.Length; i++)
            {
                _swadgeProjectiles[i].transform.SetPositionAndRotation(booletPos[i] + (booletTo[i] * _swadgeProjectSpeed * booletTimes[i]), Quaternion.identity);
                _swadgeProjectiles[i]._swadgeFiring();
            }
        }

        public void _updateSwadgeShips(Vector3[] swadgeShipPos)
        {
            for (int i = 0; i < _swadgeShipTrans.Length; i++)
            {
                _swadgeShipTrans[i].position = swadgeShipPos[i];
            }
        }

        public void _swadgeDefeated(byte Element)
        {
            _targetDefeated((byte)(Element + _aboveEnemyTargetID)); //Offset for TargetID lookup via the start of the assigned range.
        }

        public int _getAboveCannonID()
        {
            return _aboveCannonID;
        }
        public int _getAboveEnemyTargetID()
        {
            return _aboveEnemyTargetID;
        }

        public VRCPickup _getCannonPickup(byte cannonID)
        {
            cannonID--;
            if (cannonID < _pickups.Length)
            {
                return _pickups[cannonID];
            }
            else
            {
                return null;
            }
        }
        public VRCPickup _getCannonPickup(Collider other)
        {
            for (int i = 0; i < _cannonColliders.Length; i++)
            {
                if (_cannonColliders[i] == other)
                {
                    return _pickups[i];
                }
            }
            return null;
        }
        public void _togglePickups(bool toggle)
        {
            for (int i = 0; i < _pickups.Length; i++)
            {
                _pickups[i].pickupable = toggle;
            }
        }

        public byte _findEntityID(Collider other, byte filter)
        {
            switch (filter)
            {
                case 0:
                    {
                        for (byte i = 0; i < _pickups.Length; i++)
                        {
                            if (_cannons[i]._getCollider() == other)
                            {
                                return ++i;
                            }
                        }
                        break;
                    }
                case 1:
                    {
                        for (byte i = 0; i < _enemyTargets.Length; i++)
                        {
                            if (_enemyTargets[i]._getCollider() == other)
                            {
                                i += (byte)_aboveCannonID;
                                return i;
                            }
                        }
                        break;
                    }
                case 2:
                    {
                        for (byte i = 0; i < _swadgeShips.Length; i++)
                        {
                            if (_swadgeShips[i]._getCollider() == other)
                            {
                                i += (byte)_aboveSwadgeShipID;
                                return i;
                            }
                        }
                        break;
                    }
                case 3:
                    {
                        for (byte i = 0; i < _pickups.Length; i++)
                        {
                            if (_cannons[i]._getCollider() == other)
                            {
                                return ++i;
                            }
                        }
                        for (byte i = 0; i < _enemyTargets.Length; i++)
                        {
                            if (_enemyTargets[i]._getCollider() == other)
                            {
                                i += (byte)_aboveCannonID;
                                return i;
                            }
                        }
                        for (byte i = 0; i < _swadgeShips.Length; i++)
                        {
                            if (_swadgeShips[i]._getCollider() == other)
                            {
                                i += (byte)_aboveSwadgeShipID;
                                return i;
                            }
                        }
                        break;
                    }
            }
            return 0;
        }

        public byte _findCannonID(VRCPlayerApi player)
        {
            for (byte i = 0; i < _pickups.Length; i++)
            {
                if (player.Equals(_pickups[i].currentPlayer))
                {
                    return ++i;
                }
            }
            return 0;
        }

        public EnemyTarget _getEnemyTarget(byte entityID)
        {
            if (entityID >= _aboveCannonID && entityID < _aboveEnemyTargetID)
            {
                return _enemyTargets[entityID - _aboveCannonID];
            }
            else
            {
                return null;
            }
        }

        public HandCannon _getCannon(byte entityID)
        {
            if (entityID > 0 && entityID < _aboveCannonID)
            {
                return _cannons[entityID - 1];
            }
            else
            {
                return null;
            }
        }

        public HandCannon[] _getCannons()
        {
            return _cannons;
        }
        public VRCPickup[] _getPickups()
        {
            return _pickups;
        }

        #region Projectile Data Management
        //Hit processing is under Enemy Data Management

        public void _projectileFired(int projectileIndex, Transform projTrans, float timeIndex)
        {
            /*
            Debug.Log("At " + timeIndex + 
                " Player \"" + player + "\"" + 
                " fired Cannon " + cannon + 
                " with Projectile " + projectileIndex +
                " from " + proj.position +
                " facing " + proj.rotation);
            */
            _swadgeIntegration.UpdateBoolet(projectileIndex, projTrans.position, projTrans.right);
        }

        public void _projectileDespawned(int projectileIndex)
        {
            //Debug.Log("At " + timeIndex + 
            //    "despawned Projectile " + projectileIndex);
            _swadgeIntegration.CancelBoolet(projectileIndex);
        }

        #endregion

        #region Enemey Data Management

        public void _findHitEnemy(Collider other, byte originID, byte firedLevel)
        {
            //Debug.LogWarning("other: " + other.transform.parent.name + " originID: " + originID + " level: " + firedLevel + " _aboveCannonID: " + _aboveCannonID);
            for (int i = 0; i < _enemyColliders.Length; i++)
            {
                if (_enemyColliders[i] == other)
                {
                    if (originID < _aboveCannonID)
                    {
                        _enemyLogics[i]._getHitManager()._cannonHit(originID, firedLevel);
                    }
                    else
                    {
                        _enemyLogics[i]._getHitManager()._swadgeHit(originID);
                    }
                    return;
                }
            }
        }

        public void _targetDefeated(byte entityId)
        {
            //Check enemies if any have a knownTarget of this entityId. If so, remove the entityId from knownTargets.
            for (int i = 0; i < _enemyLogics.Length; i++)
            {
                _enemyLogics[i]._targetDefeated(entityId);
            }
        }

        public void _validateTarget(int entityId)
        {
            //Ignore if local player is leaving. Prevents a stop error false alarm.
            if (Utilities.IsValid(Networking.LocalPlayer))
            {
                //Used when a player pickups or drops a cannon to orient enemy shots.
                for (int i = 0; i < _enemyLogics.Length; i++)
                {
                    if (_enemyLogics[i].newTarget == entityId)
                    {
                        _enemyLogics[i].newTarget = _enemyLogics[i].newTarget;
                    }
                }
            }
        }

        public void _removeSwadgeEntity(int entityId)
        {
            if (_isSwadgeHost)
            {
                _swadgeIntegration.URemoveEnemy(entityId);
            }
        }

        //Order of Sorting
        //
        // HandCannons
        // EnemyTargets
        // SwadgeShips

        public byte _getTarget(UdonSharpBehaviour target)
        {
            //Debug.LogWarning("_getTarget: " + (byte)target.GetProgramVariable("_originID") + " _getTargetID: " + _getTargetID(null, (byte)target.GetProgramVariable("_originID")).name, gameObject);
            //All possibilities have 1 added to them to reserve 0 as a null repalcement, which would be self.
            return (byte)target.GetProgramVariable("_targetID");
            /*
            switch (target.GetUdonTypeName())
            {
                case "DrakenStark.HandCannon":
                    {
                        for (byte i = 0; i < _cannons.Length; i++)
                        {
                            if (_cannons[i] == target)
                            {
                                return i++;
                            }
                        }
                        break;
                    }
                case "DrakenStark.EnemyTarget":
                    {
                        for (int i = 0; i < _enemyTargets.Length; i++)
                        {
                            if (_enemyTargets[i] == target)
                            {
                                i += _cannons.Length;
                                return (byte)i++;
                            }
                        }
                        break;
                    }
                case "DrakenStark.SwadgeShip":
                    {
                        for (int i = 0; i < _swadgeShips.Length; i++)
                        {
                            if (_swadgeShips[i] == target)
                            {
                                i += _cannons.Length;
                                i += _enemyTargets.Length;
                                return (byte)i++;
                            }
                        }
                        break;
                    }
            }

            //0 is Self and is used in place of null.
            return 0;*/
        }

        //Cannons(24 | 1 - 24 | 25) EnemyTargets(1 | 25 - 25 | 26) SwadgeShips(25 | 26 - 50 | 51)
        public Transform _getTargetID(EnemyLogic self, int targetID)
        {
            //Debug.LogWarning("targetID: " + targetID + " (" + _aboveCannonID + ", " + _aboveEnemyTargetID + ", " + _aboveSwadgeShipID + ")");
            if (targetID == 0)
            {
                //0 is Self and is used in place of null.
                return self.transform;
            }
            else
            {
                if (targetID < _aboveCannonID)
                {
                    targetID -= 1;
                    //Debug.LogWarning("Adjusted TargetID: " + targetID + " | " + _cannons[targetID].transform.parent.name, _cannons[targetID].transform.parent.gameObject);
                    return _pickups[targetID].transform;
                }
                else if (targetID < _aboveEnemyTargetID)
                {
                    targetID -= _aboveCannonID;
                    //Debug.LogWarning("Adjusted TargetID: " + targetID + " | " + _enemyTargets[targetID].transform.parent.name, _enemyTargets[targetID].transform.parent.gameObject);
                    return _enemyTargets[targetID].transform;
                }
                else if (targetID < _aboveSwadgeShipID)
                {
                    targetID -= _aboveEnemyTargetID;
                    //Debug.LogWarning("Adjusted TargetID: " + targetID + " | " + _swadgeShips[targetID].transform.name, _swadgeShips[targetID].transform.gameObject);
                    return _swadgeShips[targetID].transform;
                }

                //Debug.LogWarning("_getTargetID: " + targetID + ", " + self.transform.parent.name, self.transform.parent.gameObject);

            }

            //0 is Self and is used in place of null.
            return self.transform;
        }

        #endregion


    }
}