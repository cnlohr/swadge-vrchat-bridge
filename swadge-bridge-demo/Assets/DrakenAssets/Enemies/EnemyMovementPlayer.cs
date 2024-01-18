using UdonSharp;
using UnityEngine;
using UnityEngine.AI;
using VRC.SDKBase;

namespace DrakenStark
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class EnemyMovementPlayer : UdonSharpBehaviour
    {
        //This script must not be enabled without first having _setupTarget called.
        private VRCPlayerApi target = null;
        [SerializeField] private NavMeshAgent _navAgent = null;

        public void _setupTarget(VRCPlayerApi newTarget)
        {
            target = newTarget;
        }

        private void FixedUpdate()
        {
            if (!Utilities.IsValid(target)) { enabled = false; }
            if (_navAgent.enabled) _navAgent.destination = target.GetPosition();
        }
    }
}