using UdonSharp;
using UnityEngine;

namespace DrakenStark
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class EnemyTarget : UdonSharpBehaviour
    {
        [SerializeField] private int _targetID = -1;
        [SerializeField] private int _entityType = 4;
        [SerializeField] private Collider _collider;
        [SerializeField] private SwadgeEnemyPosSync _swadgeSync = null;
        [SerializeField, UdonSynced] private int _hitpoints = 20;

        public void _prepHit()
        {

        }

        public void hit()
        {

        }

        public Collider _getCollider()
        {
            return _collider;
        }

        public void _setup(int originID, SwadgeEnemyPosSync swadgeSync)
        {
            _targetID = originID;
            _swadgeSync = swadgeSync;
        }

        public void _toggleSwadgeHosting(bool toggle)
        {
            _swadgeSync._localSetup(_targetID, _entityType, transform);
            _swadgeSync.enabled = toggle;
        }
    }
}