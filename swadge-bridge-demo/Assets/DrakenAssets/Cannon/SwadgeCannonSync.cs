using UdonSharp;
using UnityEngine;
namespace DrakenStark
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class SwadgeCannonSync : UdonSharpBehaviour
    {
        [SerializeField] private SwadgeIntegration _swadgeIntegration = null;
        [SerializeField] private Transform[] _cannons = null;

        public void _setupCannons(Transform[] transforms)
        {
            _cannons = transforms;
        }
        public void _setup(SwadgeIntegration swadgeIntegration)
        {
            _swadgeIntegration = swadgeIntegration;
        }

        private void Update()
        {
            if (enabled)
            {
                for (int i = 0; i < _cannons.Length; i++)
                {
                    //Projectiles spawn with their facing already, just update positions here.
                    /*
                    Vector3 vectorExample = _cannons[i].position;
                    float floatExampleRX = _cannons[i].rotation.eulerAngles.x;
                    float floatExamplePY = _cannons[i].position.y;
                    */
                    // "forward" is actually up
                    // "right" is actually "left" (could be -x universe bug)
                    _swadgeIntegration.UpdateGun(i, _cannons[i].position, _cannons[i].up);
                }
            }
        }
    }
}