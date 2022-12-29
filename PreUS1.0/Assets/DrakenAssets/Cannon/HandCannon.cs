using UdonSharp;
using UnityEngine;
using VRC.SDK3.Components;
using VRC.SDKBase;

namespace Bhenaniguns
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class HandCannon : UdonSharpBehaviour
    {
        [UdonSynced] private Vector3 _firePosition = new Vector3(0f, 0f, 0f);
        [UdonSynced] private Quaternion _fireRotation = new Quaternion(0f, 0f, 0f, 0f);
        [UdonSynced] private float _fireTime = 0f;
        [SerializeField] private GameObject _fireOrigin = null;
        [SerializeField] private Animator _cannonAnimator = null;
        [SerializeField] private VRCPickup _cannonPickup = null;
        private bool _notCheckingOwnership = true;

        [Header("Projectile Settings")]
        [SerializeField] private GameObject _projectile = null;
        [Range(1, 16)]
        [SerializeField] private int _quantityLimit = 4;
        private GameObject[] _projectiles = null;
        private int _projectileIndex = 0;
        private bool _useLock = false;
        [SerializeField] float _cooldown = 0.33f;
        [SerializeField] float _coyoteFireWindow = 0.15f;
        private bool _isCooled = true;
        private bool _queuedFire = false;
        private bool _coyoteUse = false;

        private void Start()
        {
            _projectiles = new GameObject[_quantityLimit];
        }

        public void _proxyOnPickup()
        {
            if (_notCheckingOwnership)
            {
                Networking.SetOwner(Networking.LocalPlayer, gameObject);
                _notCheckingOwnership = false;
                SendCustomEventDelayedSeconds("_doubleCheckOwnership", 1);
            }
        }

        public void _doubleCheckOwnership()
        {
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
        }

        public void _proxyOnPickupUseUp()
        {
            if (_useLock)
            {
                _useLock = false;
            }
        }

        public void _proxyOnPickupUseDown()
        {
			Debug.Log( "_proxyOnPickupUseDown " + _useLock );
            if (!_useLock)
            {
                _useLock = true;


                if (_isCooled)
                {
                    //If fired while cooled, fire immediately.
                    SendCustomEvent("_prepToFire");
                    SendCustomEventDelayedSeconds("_cooledDown", _cooldown);
                }
                else
                {
                    //Attempting fire again while cooling will enable a shot to be fired as soon as the gun is cooled.
                    _queuedFire = true;
                    _coyoteUse = true;
                    SendCustomEventDelayedSeconds("_coyoteWindowClosed", _coyoteFireWindow);
                }

            }
        }

        public void _coyoteWindowClosed()
        {
            _coyoteUse = false;
        }

        public void _cooledDown()
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

        public void _prepToFire()
        {
            _isCooled = false;
            //Give the player instant feedback
            _cannonAnimator.SetTrigger("CannonFired");

            _firePosition = _fireOrigin.transform.position;
            _fireRotation = _fireOrigin.transform.rotation;
            _fireTime = Time.realtimeSinceStartup % 4294;
            RequestSerialization();

            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "pewpew");
        }

        public void pewpew()
        {
            if (_projectiles[_projectileIndex] != null)
            {
                Destroy(_projectiles[_projectileIndex]);
            }
            GameObject _fired = VRCInstantiate(_projectile);
            _projectiles[_projectileIndex] = _fired;
            _projectileIndex++;
            if (_projectileIndex >= _quantityLimit)
            {
                _projectileIndex = 0;
            }
            _fired.transform.position = _firePosition;
            _fired.transform.rotation = _fireRotation;
            Debug.Log("t" + _fireTime + ",py" + _firePosition.y + ",px" + _firePosition.x + ",pz" + _firePosition.z + ",rw" + _fireRotation.w + ",rx" + _fireRotation.x + ",ry" + _fireRotation.y + ",rz" + _fireRotation.z, gameObject);
			// XXX CNL XXX
			// Hook up "fired" bananas here to plug into SwadgeIntegration.
			
			// XXX CNL XXX
            _fired.SetActive(true);
        }
    }
}