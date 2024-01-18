using UdonSharp;
using UnityEngine;
using UnityEngine.AI;
using VRC.SDKBase;

namespace DrakenStark
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class EnemyMovementObject : UdonSharpBehaviour
    {
        //This script must not be enabled without first having _setupTarget called.
        private Transform target = null;
        [SerializeField] private NavMeshAgent _navAgent = null;

        public void _setupTarget(Transform newTarget)
        {
            target = newTarget;
        }

        public void _setNavMeshAgent(bool toggle)
        {
            _navAgent.enabled = toggle;
        }

        private void FixedUpdate()
        {
            if (!Utilities.IsValid(target)) { enabled = false; }
            if (_navAgent.enabled) _navAgent.destination = target.position;
        }
    }
}