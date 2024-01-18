using UdonSharp;
using UnityEngine;
using VRC.SDK3.Components;
using VRC.SDKBase;

namespace DrakenStark
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class HandCannon : UdonSharpBehaviour
    {
        [Header("Basic Settings")]
        [SerializeField] private DataManager _dataManager = null;
        [SerializeField] private Transform _respawnPoint = null;
        [SerializeField] private Collider _pickupCollider = null;
        [SerializeField] private Collider _enemySenseCollider = null;
        [SerializeField] private SkinnedMeshRenderer _skinnedMeshRenderer = null;
        [SerializeField] private byte _targetID = 0;
        [UdonSynced] private Vector3 _firePosition = Vector3.zero;
        [UdonSynced] private Vector3 _fireRotationV = Vector3.zero;
        private float _fireTime = 0f;
        [SerializeField] private GameObject _fireOrigin = null;
        [SerializeField] private Animator _cannonAnimator = null;
        [SerializeField] private VRCPickup _cannonPickup = null;
        [SerializeField] private VRCObjectSync _cannonObjectSync = null;
        private bool _notCheckingOwnership = true;
        [SerializeField] private float _droppedTimeout = 10f;
        private bool _droppedTimingOut = false;
        private int _droppedIterations = 0;

        [Header("Player Settings")]
        [SerializeField] byte _startingHitPoints = 10;
        private byte _hitPoints = 10;

        [Header("Cannon States")]
        [SerializeField] GameObject _chargingGO = null;
        private bool _notWielding = false;
        //[SerializeField] GameObject _chargedChamber = null;

        [Header("Projectile Settings")]
        [SerializeField] private Projectile[] _projectiles = null;
        private int _projectileIndex = 0;
        private bool _useLock = false;
        [SerializeField] float _cooldown = 0.33f;
        [SerializeField] float _coyoteFireWindow = 0.15f;
        private bool _isCooled = true;
        private int _cooldownCount = 0;
        private bool _queuedFire = false;
        private bool _coyoteUse = false;
        private int _pressIterations0 = 0;
        private int _pressIterations1 = 0;
        private int _pressIterations2 = 0;
        private int _pressIterations3 = 0;
        [SerializeField] float _chargeShotTime = 3f;
        private bool _fireReleaseNorm = false;
        private bool _fireReleaseChar = false;
        private bool _poweredUp = false;
        private VRCPlayerApi _firingPlayer = null;
        [SerializeField] private Vector3 _shotVelocity = Vector3.zero;

        [Header("Audio Settings")]
        [SerializeField] AudioSource _cannonAudioSource = null;
        [SerializeField] AudioClip _charging = null;
        [SerializeField] AudioClip _sustaining = null;
        [SerializeField] AudioSource _healthAudioSource = null;
        [SerializeField] AudioClip _ow = null;
        [SerializeField] AudioClip _defeated = null;
        private int _defeatedIterations = 0;


        public void _setup(DataManager dataManager, byte element, Projectile[] projectiles)
        {
            _dataManager = dataManager;
            _targetID = element;
            _projectiles = projectiles;
        }
        public void _setRespawnPoint(Transform newRespawnPoint)
        {
            _respawnPoint = newRespawnPoint;
        }
        public void _cannonDisable()
        {
            //Disable Seeing and Carrying
            _cannonPickup.Drop();
            _enemySenseCollider.enabled = false;
            _skinnedMeshRenderer.enabled = false;
            _cannonPickup.pickupable = false;

            //Disable existing projectiles
            for (int i = 0; i < _projectiles.Length; i++)
            {
                _projectiles[i].gameObject.SetActive(false);
            }

            //Disable Firing
            _chargingGO.SetActive(false);
            _fireReleaseChar = false;
            _fireReleaseNorm = false;
            _cannonAnimator.SetBool("Charging", false);

            //Reset Cannon
            _cannonObjectSync.TeleportTo(_respawnPoint);
            _hitPoints = _startingHitPoints;
    }
        public void _cannonEnable()
        {
            _cannonObjectSync.TeleportTo(_respawnPoint);
            _hitPoints = _startingHitPoints;
            _enemySenseCollider.enabled = true;
            _skinnedMeshRenderer.enabled = true;
            _cannonPickup.pickupable = true;
        }

        public VRCPickup _getPickup()
        {
            return _cannonPickup;
        }

        public Transform _getRespawnPoint()
        {
            return _respawnPoint;
        }

        public Collider _getCollider()
        {
            return _pickupCollider;
        }

        public VRCPlayerApi _getFiringPlayer()
        {
            return _firingPlayer;
        }

        public void _hit(byte damage, Vector3 sourcePos)
        {
            damage++;
            if (damage >= _hitPoints)
            {
                _hitPoints = 0;
                SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "Defeated");
            }
            else
            {
                _hitPoints -= damage;
                if (_dataManager._getAudioEnabled())
                {
                    _healthAudioSource.clip = _ow;
                    _healthAudioSource.Play();
                }
            }
            //Update Player Displays
        }

        public void Defeated()
        {
            if (_hitPoints == 0)
            {
                if (_dataManager._getAudioEnabled())
                {
                    _healthAudioSource.clip = _defeated;
                    _healthAudioSource.Play();
                }

                //Stop players and enemies from interacting with the cannon.
                _enemySenseCollider.enabled = false;
                _dataManager._targetDefeated(_targetID);

                //Cancel Firing
                _cannonAnimator.SetBool("Charging", false);
                _chargingGO.SetActive(false);
                _fireReleaseChar = false;
                _fireReleaseNorm = false;

                //Relocate the Cannon after audio finishes
                _cannonPickup.Drop();
                _notWielding = true;
                _dataManager._togglePickups(false);

                SendCustomEventDelayedSeconds("_defeatedDelay", _defeated.length);
            }
        }

        public void _defeatedDelay()
        {
            _cannonObjectSync.TeleportTo(_respawnPoint);
            _hitPoints = _startingHitPoints;
            _enemySenseCollider.enabled = true;

            if (_dataManager._getDualWielding())
            {
                _dataManager._togglePickups(_notWielding);
            }
            else
            {
                _dataManager._togglePickups(_dataManager._getGameEnabled());
            }
        }

        public void _proxyOnPickup()
        {
            _droppedTimingOut = false;
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "netOnPickup");
            if (Utilities.IsValid(_cannonPickup.currentPlayer) && _cannonPickup.currentPlayer.isLocal)
            {
                _firingPlayer = _cannonPickup.currentPlayer;
                if (_dataManager._getDualWielding())
                {
                    _dataManager._togglePickups(false);
                }
                _notWielding = false;
            }

            //Ownership requests can fail, start checking periodically to ensure it succeeds.
            if (_notCheckingOwnership)
            {
                Networking.SetOwner(Networking.LocalPlayer, gameObject);
                _notCheckingOwnership = false;
                SendCustomEventDelayedSeconds("_doubleCheckOwnership", 1);
            }

            //Check enemy current targets
            _dataManager._validateTarget(_targetID);

            //Debug.LogWarning("Cannon: Origin " + _originID, gameObject);
        }

        public void netOnPickup()
        {
            //Update the player using the cannon.
            if (Utilities.IsValid(_cannonPickup.currentPlayer))
            {
                _firingPlayer = _cannonPickup.currentPlayer;
            }
        }

        public void _doubleCheckOwnership()
        {
            //Ownership requests can fail, try periodically until it succeeds as long as the Cannon is held.
            if (_cannonPickup.currentPlayer == Networking.LocalPlayer && !Networking.IsOwner(gameObject))
            {
                Networking.SetOwner(Networking.LocalPlayer, gameObject);
                SendCustomEventDelayedSeconds("_doubleCheckOwnership", 1);
                return;
            }
            _notCheckingOwnership = true;
        }

        public void _proxyOnDrop()
        {
            _useLock = false;
            _droppedTimingOut = true;
            _fireReleaseNorm = false;
            _fireReleaseChar = false;
            _chargingGO.SetActive(false);
            if (Utilities.IsValid(_firingPlayer) && _firingPlayer.isLocal)
            {
                _notWielding = true;
                _dataManager._togglePickups(true);
            }

            //Check enemy current targets (Don't check if the local player is leaving. Stops a false alarm StopError.)
            if (Utilities.IsValid(Networking.LocalPlayer))
            {
                _dataManager._validateTarget(_targetID);
            }

            _droppedIterations++;
            SendCustomEventDelayedSeconds("_timedout", _droppedTimeout);
        }
        public void _timedout()
        {
            _droppedIterations--;
            if (_droppedIterations == 0 && _droppedTimingOut)
            {
                //Debug.LogWarning("Attempted to respawn " + _cannonObjectSync.name, _cannonObjectSync.gameObject);
                //Respawn is broken for some reason and just teleports the cannon back to where it was dropped the frame after it is respawned to where it should be staying.
                //_cannonObjectSync.Respawn();
                _cannonObjectSync.TeleportTo(_respawnPoint);
                _dataManager._targetDefeated(_targetID);
            }
        }

        public void _proxyOnPickupUseDown()
        {
            if (!_useLock)
            {
                _useLock = true;


                if (_isCooled)
                {
                    //If fired while cooled, fire immediately.
                    SendCustomEvent("_prepToFire");
                    _cooldownCount++;
                    SendCustomEventDelayedSeconds("_cooledDown", _cooldown);
                }
                else
                {
                    _pressIterations0++;
                    SendCustomEventDelayedSeconds("_chargingShot0", _cooldown - _coyoteFireWindow);
                }
                /*else
                {
                    //Attempting fire again while cooling will enable a shot to be fired as soon as the gun is cooled.
                    _queuedFire = true;
                    _coyoteUse = true;
                    SendCustomEventDelayedSeconds("_coyoteWindowClosed", _coyoteFireWindow);
                }*/
            }
        }

        public void _coyoteWindowClosed()
        {
            _coyoteUse = false;
        }

        public void _cooledDown()
        {
            _cooldownCount--;
            if (_cooldownCount == 0)
            {
                //If the button is still being held from the cooling period, fire right away.
                if ((_useLock || _coyoteUse) && _queuedFire)
                {
                    SendCustomEvent("_prepToFire");
                    SendCustomEventDelayedSeconds("_cooledDown", _cooldown);
                }
                else
                {
                    _isCooled = true;
                }
                _queuedFire = false;
            }
        }

        public void _prepToFire()
        {
            _isCooled = false;
            //Give the player instant feedback
            //_cannonAnimator.SetTrigger("CannonFired");

            //Provide the HandCannon orientation for all players.
            _firePosition = _fireOrigin.transform.position;
            _fireRotationV = _fireOrigin.transform.rotation.eulerAngles;
            _fireTime = Time.realtimeSinceStartup % 4294;
            RequestSerialization();

            //Immediately fire a normal shot.
            if (_poweredUp)
            {
                SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "pewpew1");
            }
            else
            {
                SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "pewpew0");
            }

            //Check if held longer than the cooldown or chargeTime.
            _pressIterations0++;
            SendCustomEventDelayedSeconds("_chargingShot0", _cooldown - _coyoteFireWindow);
        }

        public void _chargingShot0()
        {
            //CoyoteTime of Cooldown
            //Held: Enable Queued Normal Shot
            //Released: Do nothing

            _pressIterations0--;
            if (_pressIterations0.Equals(0) && _useLock)
            {
                _chargingGO.SetActive(true);
                if (_dataManager._getAudioEnabled())
                {
                    _cannonAudioSource.clip = _charging;
                    _cannonAudioSource.Play();
                }
                _cannonAnimator.SetBool("Charging", true);
                _pressIterations1++;
                SendCustomEventDelayedSeconds("_chargingShot1", _coyoteFireWindow);
            }
        }

        public void _chargingShot1()
        {
            //Cooldown Reached
            //Held: Continue progression and Fire Norm upon release
            //Released: Fire Norm

            _pressIterations1--;
            if (_pressIterations0.Equals(0) && _pressIterations1.Equals(0) && _useLock)
            {
                _fireReleaseNorm = true;
                _pressIterations2++;
                SendCustomEventDelayedSeconds("_chargingShot2", _chargeShotTime - _cooldown - _coyoteFireWindow);
            }
            else
            {
                if (_isCooled)
                {
                    //Fire Norm
                    _fireNorm();
                }
            }
        }

        public void _chargingShot2()
        {
            //Cooldown Reached
            //Held: Queue Fire Char
            //Released: Do nothing

            _pressIterations2--;
            if (_pressIterations0.Equals(0) && _pressIterations1.Equals(0) && _pressIterations2.Equals(0) && _useLock)
            {
                _fireReleaseNorm = false;
                _pressIterations3++;
                SendCustomEventDelayedSeconds("_chargingShot3", _coyoteFireWindow);
            }
        }
        public void _chargingShot3()
        {
            //ChargeTime Reached
            //Held: Fire Char upon release
            //Released: Fire Char
            _pressIterations3--;
            if (_pressIterations0.Equals(0) && _pressIterations1.Equals(0) && _pressIterations2.Equals(0) && _pressIterations3.Equals(0) && _useLock)
            {
                if (_dataManager._getAudioEnabled())
                {
                    _cannonAudioSource.clip = _sustaining;
                    _cannonAudioSource.Play();
                }
                //_chargedChamber.SetActive(true);
                _fireReleaseChar = true;
            }
            else
            {
                if (_isCooled)
                {
                    //Fire Char
                    _fireCharged();
                }
            }
        }

        public void _proxyOnPickupUseUp()
        {
            if (_dataManager._getAudioEnabled())
            {
                _cannonAudioSource.Stop();
            }
            _cannonAnimator.SetBool("Charging", false);
            _chargingGO.SetActive(false);

            if (_useLock)
            {
                _useLock = false;

                if (_isCooled)
                {
                    if (_fireReleaseNorm)
                    {
                        _fireNorm();
                    }
                    else if (_fireReleaseChar)
                    {
                        _fireCharged();
                    }
                }
            }
        }

        private void _fireNorm()
        {
            //Fire Norm
            _fireReleaseNorm = false;

            //Start Cooldown Process
            _cooldownCount++;
            SendCustomEventDelayedSeconds("_cooledDown", _cooldown);
            _isCooled = false;

            //Provide the HandCannon orientation for all players.
            _firePosition = _fireOrigin.transform.position;
            _fireRotationV = _fireOrigin.transform.rotation.eulerAngles;
            _fireTime = Time.realtimeSinceStartup % 4294;
            RequestSerialization();

            if (_poweredUp)
            {
                SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "pewpew1");
            }
            else
            {
                SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "pewpew0");
            }
        }

        private void _fireCharged()
        {
            //Fire Char
            _fireReleaseChar = false;
            //_chargedChamber.SetActive(false);

            //Start Cooldown Process
            _cooldownCount++;
            SendCustomEventDelayedSeconds("_cooledDown", _cooldown);
            _isCooled = false;

            //Provide the HandCannon orientation for all players.
            _firePosition = _fireOrigin.transform.position;
            _fireRotationV = _fireOrigin.transform.rotation.eulerAngles;
            _fireTime = Time.realtimeSinceStartup % 4294;
            RequestSerialization();

            if (_poweredUp)
            {
                SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "pewpew3");
            }
            else
            {
                SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "pewpew2");
            }
        }

        public void pewpew0()
        {
            pewpewCommon(0);
        }
        public void pewpew1()
        {
            pewpewCommon(1);
        }
        public void pewpew2()
        {
            pewpewCommon(2);
        }
        public void pewpew3()
        {
            pewpewCommon(3);
        }

        private void pewpewCommon(byte level)
        {
            netOnPickup();

            //Prepare next Projectile at level.
            _projectileIndex++;
            if (_projectileIndex >= _projectiles.Length)
            {
                _projectileIndex = 0;
            }

            //Detect if Projectile at Index is in use, remove it if so.
            if (_projectiles[_projectileIndex].gameObject.activeSelf)
            {
                _projectiles[_projectileIndex].gameObject.SetActive(false);
                //Report Despawned Projectile
                _dataManager._projectileDespawned(_projectiles[_projectileIndex]._getProjectileID());
            }


            //Give the Projectile at Index the synced HandCannon orientation.
            _projectiles[_projectileIndex].transform.position = _firePosition;
            _projectiles[_projectileIndex].transform.rotation = Quaternion.Euler(_fireRotationV);

            //Report Fired Projectile
            if (_dataManager._getIsSwadgeHost())
            {
                _dataManager._projectileFired(_projectiles[_projectileIndex]._getProjectileID(), _projectiles[_projectileIndex].transform, _fireTime);
            }
            //Debug.Log("t" + _fireTime + ",py" + _firePosition.y + ",px" + _firePosition.x + ",pz" + _firePosition.z + ",rw" + _fireRotation.w + ",rx" + _fireRotation.x + ",ry" + _fireRotation.y + ",rz" + _fireRotation.z, gameObject);

            //Enable the Projectile at Index.
            _projectiles[_projectileIndex]._setupVelocity(_shotVelocity);
            _projectiles[_projectileIndex]._cannonFiring(level, _firingPlayer);
            _projectiles[_projectileIndex].gameObject.SetActive(true);
            //Debug.LogWarning("Firing Cannon " + _manCanIndex + ", Projectile " + _projectiles[_projectileIndex]._getProjectileID() + ", Power " + level);
        }
    }
}