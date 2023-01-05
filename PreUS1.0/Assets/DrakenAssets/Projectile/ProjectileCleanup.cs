using UdonSharp;
using UnityEngine;

namespace Bhenaniguns
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class ProjectileCleanup : UdonSharpBehaviour
    {
        [SerializeField] private HandCannon _cannon = null;
        [SerializeField] private Projectile _projectile = null;

        void OnEnable()
        {
            if (_cannon._dataManager != null)
            {
                _cannon._dataManager._projectileDespawned(Time.realtimeSinceStartup % 4294, _projectile._manProjIndex);
            }
            Destroy(_projectile.gameObject);
        }
    }
}