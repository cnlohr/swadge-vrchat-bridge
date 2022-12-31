using UdonSharp;
using UnityEngine;
using VRC.Udon;

namespace Bhenaniguns
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class ManualSyncProxy : UdonSharpBehaviour
    {
        [SerializeField] private HandCannon _targetScript = null;

        public HandCannon _getTargetScript()
        {
            return _targetScript;
        }

        public override void OnDrop()
        {
            _targetScript.SendCustomEvent("_proxyOnDrop");
        }

        public override void OnPickupUseUp()
        {
            _targetScript.SendCustomEvent("_proxyOnPickupUseUp");
        }

        public override void OnPickupUseDown()
        {
            _targetScript.SendCustomEvent("_proxyOnPickupUseDown");
        }

        public override void OnPickup()
        {
            _targetScript.SendCustomEvent("_proxyOnPickup");
        }
    }
}