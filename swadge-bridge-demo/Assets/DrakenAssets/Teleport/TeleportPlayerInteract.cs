using UdonSharp;
using UnityEngine;
using VRC.SDKBase;

namespace DrakenStark
{
	[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
	public class TeleportPlayerInteract : UdonSharpBehaviour
	{
		[Header("Teleport Location")]
		[Tooltip("This will be the location the player will be teleported to.")]
		[SerializeField] private Transform _teleportLocation = null;
		[Tooltip("If enabled, players will keep their position from this scripts GameObject when they teleport to the Teleport Location.\n(Useful for teleporting players between identical spaces; aka Seamless Teleporting.)\nIf disabled, players will be teleported exactly where the Teleport Location GameObject is.")]
		[SerializeField] private bool _keepPlayerPositionOffset = false;
		[Tooltip("If enabled, players will face the direction they had relative to this scripts GameObject when they teleport to the Teleport Location.\nIf this is disabled, players will be turned to face the same direction as the Teleport Location's GameObject.")]
		[SerializeField] private bool _keepPlayerRotationOffset = true;
		private Vector3 _newPosition = new Vector3(0f, 0f, 0f);
		private Quaternion _newRotation = new Quaternion(0f, 0f, 0f, 0f);
        [SerializeField] private bool _preserveVelocity = true;
		private Vector3 _previousVelocity = new Vector3(0f, 0f, 0f);

        public override void Interact()
		{
			if (Networking.LocalPlayer != null)
            {
				VRCPlayerApi player = Networking.LocalPlayer;

				if (_preserveVelocity)
				{
					_previousVelocity = player.GetVelocity();
				}

				//Position Handling
				if (_keepPlayerPositionOffset)
				{
					_newPosition = (_teleportLocation.rotation * (Quaternion.Inverse(gameObject.transform.rotation) * (player.GetPosition() - gameObject.transform.position))) + _teleportLocation.position;
				}
				else
				{
					_newPosition = _teleportLocation.position;
				}

				//Rotation Handling
				if (_keepPlayerRotationOffset)
				{
					_newRotation = (_teleportLocation.rotation * (Quaternion.Inverse(gameObject.transform.rotation) * player.GetRotation()));
				}
				else
				{
					_newRotation = _teleportLocation.rotation;
				}
				if (_preserveVelocity)
				{
					player.SetVelocity(_teleportLocation.TransformDirection(transform.InverseTransformDirection(_previousVelocity))); 
                }
				else
				{
					player.SetVelocity(Vector3.zero);
				}
				Networking.LocalPlayer.TeleportTo(_newPosition, _newRotation, VRC_SceneDescriptor.SpawnOrientation.Default, false);
			}
		}
	}
}