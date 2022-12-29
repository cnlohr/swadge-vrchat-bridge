using UdonSharp;
using UnityEngine;

namespace Bhenaniguns
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class HitReporter : UdonSharpBehaviour
    {
        [SerializeField] private bool _hitReporting = true;
        [HideInInspector, UdonSynced] public string _firingPlayer = "";
        [HideInInspector, UdonSynced] public string _targetHit = "";

        public void _projectileForwardedNotice(string _player, string _target)
        {
            if (_hitReporting)
            {
                _firingPlayer = _player;
                _targetHit = _target;
                RequestSerialization();
                SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "ProjectileNetworkNotice");
            }
        }

        public void ProjectileNetworkNotice()
        {
            if (_hitReporting)
            {
                Debug.Log("\"" + _firingPlayer + "\" hit " + _targetHit + "");
            }
        }
    }
}