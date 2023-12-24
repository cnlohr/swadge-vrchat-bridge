using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
//Thank you! - DrakenStark
namespace Bhenaniguns
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class DataManager : UdonSharpBehaviour
    {
        [Tooltip("Cannons will be automatically adjusted if it comes up short. Fully define it in the editor to save a little on load time.")]
        [SerializeField] private HandCannon[] _cannons = null;
		public SwadgeIntegration swadgeIntegrator;
        private Transform[] _projectiles = null;
        private bool setup = false;

        public void _projectileFired(float timeIndex, string player, int cannon, int projectileIndex, Transform proj)
        {
            //Debug.Log("At " + timeIndex + 
            //    " Player \"" + player + "\"" + 
            //    " fired Cannon " + cannon + 
            //    " with Projectile " + projectileIndex +
            //    " from " + proj.position +
            //    " facing " + proj.rotation);
            _projectiles[projectileIndex] = proj;
			swadgeIntegrator.UpdateBoolet( projectileIndex, proj.position, proj.right );
        }

        public void _projectileDespawned(float timeIndex, int projectileIndex)
        {
            //Debug.Log("At " + timeIndex + 
             //   "despawned Projectile " + projectileIndex);
			swadgeIntegrator.CancelBoolet( projectileIndex );
        }

        private void Update()
        {
            if (setup)
            {
                for (int i = 0; i < _cannons.Length; i++)
                {
                    if (_cannons[i] != null)
                    {
                        //Projectiles spawn with their facing already, just update positions here.
						// "forward" is actually up
						// "right" is actually "left" (could be -x universe bug)
						swadgeIntegrator.UpdateGun( i, _cannons[i].transform.position, _cannons[i].transform.up );
                    }
                }
            }
        }

        public int _getCannonIndex(HandCannon cannon)
        {

            //Initialize _cannons if it isn't already.
            bool initialized = false;
            if (_cannons == null || _cannons.Length == 0)
            {
                _cannons = new HandCannon[24];
                initialized = true;
            }
            int cannonsLength = _cannons.Length;

            //If initialized, don't bother looking for the cannon.
            if (!initialized)
            {
                //Search through _cannons for the cannon.
                for (int i = 0; i < cannonsLength; i++)
                {
                    if (_cannons[i] == cannon)
                    {
                        return i;
                    }
                }
            }

            //At this point cannon isn't in _cannons so search through _cannons for an empty slot, insert it and return the index value.
            for (int i = 0; i < cannonsLength; i++)
            {
                if (_cannons[i] == null)
                {
                    _cannons[i] = cannon;
                    return i;
                }
            }

            //For any reason this should not work out increase the array size.
            int newLength = cannonsLength + 1;
            HandCannon[] cannons = new HandCannon[newLength];
            for (int i = 0; i < cannonsLength; i++)
            {
                cannons[i] = _cannons[i];
            }
            cannons[cannonsLength] = cannon;
            _cannons = cannons;
            return cannonsLength;
        }

        private void Start()
        {
            //Cannons should be getting populated at Start, so lets setup Projectiles after this phase has ended.
            SendCustomEventDelayedFrames("_lateStart", 0, VRC.Udon.Common.Enums.EventTiming.LateUpdate);
        }

        public void _lateStart()
        {
            //Cannons should be populated, time to setup Projectiles.
            int projectileLength = 0;
            for (int i = 0; i < _cannons.Length; i++)
            {
                if (_cannons[i] != null)
                {
                    _cannons[i]._manProjIndex = projectileLength;
                    projectileLength += _cannons[i]._quantityLimit;
                }
            }
            _projectiles = new Transform[projectileLength];
            setup = true;
        }

    }
}
