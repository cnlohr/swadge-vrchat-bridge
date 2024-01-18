using UdonSharp;
using UnityEngine;

namespace DrakenStark
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class SwadgeEnemyPosSync : UdonSharpBehaviour
    {
        [SerializeField] private Transform _enemyTransform = null;
        [SerializeField] private SwadgeIntegration _swadgeIntegration = null;

        [SerializeField] private int _enemyID = 0;
        [SerializeField] private int _enemyType = 0;

        public void _setup(SwadgeIntegration swadgeIntegration)
        {
            _swadgeIntegration = swadgeIntegration;
        }

        public void _localSetup(int enemyID, int enemyType, Transform enemyTransform)
        {
            _enemyID = enemyID;
            _enemyType = enemyType;
            _enemyTransform = enemyTransform;
        }

        private void Update()
        {
            if (enabled) _swadgeIntegration.UUpdateEnemy(_enemyID, _enemyType, _enemyTransform.position, _enemyTransform.rotation);
        }
    }
}