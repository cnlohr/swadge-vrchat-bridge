using UdonSharp;
using UnityEngine;

namespace DrakenStark
{

    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class SwadgeShip : UdonSharpBehaviour
    {
        [SerializeField] byte _targetID = 0;
        [SerializeField] Collider _collider = null;

        public Collider _getCollider()
        {
            return _collider;
        }

        public void _setup(byte  originID)
        {
            _targetID = originID;
        }
    }
}