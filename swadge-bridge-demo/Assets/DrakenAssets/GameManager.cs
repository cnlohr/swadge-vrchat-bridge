using UdonSharp;
using UnityEngine;
using VRC.SDKBase;

namespace DrakenStark
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class GameManager : UdonSharpBehaviour
    {
        [SerializeField] private DataManager _dataManager = null;
        [SerializeField] private Texel.AccessControl _accessControl = null;
        [SerializeField] private Transform[] _playerSpawnPoints = null;
        [SerializeField] private Transform[] _enemySpawnPoints = null;

        [SerializeField, UdonSynced, FieldChangeCallback("GameToggle")] private bool _gameEnabled = false;
        [SerializeField, UdonSynced] private bool _gameStarted = false;
        [SerializeField, UdonSynced, FieldChangeCallback("DualWieldToggle")] private bool _dualWielding = false;

        [SerializeField] private int _activeCannons = 0;
        [SerializeField] private int _activeEnemies = 0;

        public bool GameToggle
        {
            set
            {
                _gameEnabled = value;
                if (_gameEnabled)
                {
                    //Enable each cannon.
                    _dataManager._toggleCannons(true);

                    //Enable game start object. 

                }
                else
                {
                    //For each enemy, disable the root object.
                    _dataManager._toggleEnemies(false);

                    //For each cannon, disable the root object.

                    //Set HP of everything to their starting values.
                }
            }
            get => _gameEnabled;
        }

        public bool DualWieldToggle
        {
            set
            {
                _dualWielding = value;
            }
            get => _dualWielding;
        }

        public void _enableGame()
        {
            if (!Networking.GetOwner(gameObject).isLocal)
            {
                Networking.SetOwner(Networking.LocalPlayer, gameObject);
            }
            _gameEnabled = true;
            RequestSerialization();
        }

        public void _disableGame()
        {
            if (!Networking.GetOwner(gameObject).isLocal)
            {
                Networking.SetOwner(Networking.LocalPlayer, gameObject);
            }
            _gameEnabled = false;
            RequestSerialization();
        }

        public void _toggleGame()
        {
            if (!Networking.GetOwner(gameObject).isLocal)
            {
                Networking.SetOwner(Networking.LocalPlayer, gameObject);
            }
            _gameEnabled = !_gameEnabled;
            RequestSerialization();
        }

        public void _enableDualWeild()
        {
            if (!Networking.GetOwner(gameObject).isLocal)
            {
                Networking.SetOwner(Networking.LocalPlayer, gameObject);
            }
            _dualWielding = true;
            RequestSerialization();
        }

        public void _disableDualWeild()
        {
            if (!Networking.GetOwner(gameObject).isLocal)
            {
                Networking.SetOwner(Networking.LocalPlayer, gameObject);
            }
            _dualWielding = false;
            RequestSerialization();
        }

        public void _toggleDualWield()
        {
            if (!Networking.GetOwner(gameObject).isLocal)
            {
                Networking.SetOwner(Networking.LocalPlayer, gameObject);
            }
            _dualWielding = !_dualWielding;
            RequestSerialization();
        }

        public void _prepareGameStart()
        {
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "StartGame");
        }

        public void StartGame()
        {
            //Check how many cannons are in use.

            //Setup enabling a number of enemies based on cannons in use.

            //Steadily increase enemy count over time per cannon in use until max.

            //If additional cannons are picked up or dropped, scale count accordingly.
        }
    }
}