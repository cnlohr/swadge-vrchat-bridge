using UdonSharp;
using UnityEngine;
using VRC.SDKBase;

namespace Bhenaniguns
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class MovingTarget : UdonSharpBehaviour
    {
        [SerializeField] private Animator _selfAnimator = null;

        void Start()
        {
            if (Networking.IsOwner(gameObject))
            {
                _selfAnimator.enabled = true;
            }
        }

        public override void OnOwnershipTransferred(VRCPlayerApi player)
        {
            if (Networking.IsOwner(gameObject))
            {
                _selfAnimator.enabled = true;
            }
        }
    }
}