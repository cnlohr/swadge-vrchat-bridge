using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class SwadgeIntegration : UdonSharpBehaviour
{
	private SkinnedMeshRenderer mr;
	private MaterialPropertyBlock block;
	
	private const int playerArrayCount = 84;
	
	// We use a hard-coded 84 max, i.e. 80 + 4 staff.
    private VRCPlayerApi[] playerArray = new VRCPlayerApi[playerArrayCount];
	private Vector4[] BoneData = new Vector4[84*12];
	private int updateCount = 0;
	
    void Start()
    {
		block = new MaterialPropertyBlock();
		mr = GetComponent<SkinnedMeshRenderer>();
    }

	void Update()
	{
		mr.GetPropertyBlock(block);

		for( int i = 0; i < playerArrayCount; i++ )
		{
			VRCPlayerApi p = playerArray[i];
            if( Utilities.IsValid( p ) )
            {
				int place = i*12;
				BoneData[place++] = p.GetPosition();
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.Head);
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.Neck);
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.LeftLowerLeg);
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.RightLowerLeg);
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.LeftFoot);
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.RightFoot);
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.LeftLowerArm);
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.RightLowerArm);
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.LeftHand);
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.RightHand);
				BoneData[place++] = p.GetVelocity();
                break;
            }
		}

		block.SetVector( "GenProps", new Vector4( updateCount, Time.timeSinceLevelLoad, 0, 0 ) );
		block.SetVectorArray( "SkeletonData", BoneData );
		mr.SetPropertyBlock(block);
		updateCount++;
	}
	
	
    public override void OnPlayerJoined(VRC.SDKBase.VRCPlayerApi player)
	{
		for( int i = 0; i < playerArrayCount; i++ )
		{
			if( !Utilities.IsValid( playerArray[i] ) )
			{
				playerArray[i] = player;
			}
		}
    }

    public override void OnPlayerLeft(VRC.SDKBase.VRCPlayerApi player)
	{
		for( int i = 0; i < playerArrayCount; i++ )
		{
			if( player == playerArray[i] )
			{
				playerArray[i] = null;
				break;
			}
		}
    }
}
