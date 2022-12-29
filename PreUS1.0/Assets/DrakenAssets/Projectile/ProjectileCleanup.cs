using UdonSharp;
using UnityEngine;

namespace Bhenaniguns
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class ProjectileCleanup : UdonSharpBehaviour
    {
        [SerializeField] private GameObject _projectileRoot = null;

        void OnEnable()
        {
            Destroy(_projectileRoot);
        }
    }
}