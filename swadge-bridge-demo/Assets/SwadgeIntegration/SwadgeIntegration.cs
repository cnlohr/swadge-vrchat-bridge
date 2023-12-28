﻿using UdonSharp;
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
	
	
	private bool didUpdateBoolets;
	private int  iUniqueBooletCounter;
	private Vector4[] BooletStartLocation = new Vector4[240];
	private Vector4[] BooletStartDirection = new Vector4[240];
	private Vector4[] BooletStartDataTime = new Vector4[240]; // [in_use 0 or 1, a counter making a unique value starting at 0 and counting to 65535 and resetting to zero.]

	private Vector4[] GunLocation = new Vector4[24];
	private Vector4[] GunDirection = new Vector4[24]; // [in_use 0 or 1, a counter making a unique value starting at 0 and counting to 65535 and resetting to zero.]

	public void UpdateBoolet( int boolet, Vector3 pos, Vector3 to )
	{
		BooletStartLocation[boolet] = pos;
		BooletStartDirection[boolet] = to;

		if( ++iUniqueBooletCounter == 0 )
			++iUniqueBooletCounter;

		BooletStartDataTime[boolet] = new Vector3( 1, iUniqueBooletCounter, 0 );
		didUpdateBoolets = true;
	}
	
	public void CancelBoolet( int boolet )
	{
		BooletStartLocation[boolet] = new Vector3( 0, 0, 0 );
		BooletStartDirection[boolet] = new Vector3( 0, 0, 0 );
		BooletStartDataTime[boolet] = new Vector3( 0, 0, 0 );
		didUpdateBoolets = true;
	}
	
	public void UpdateGun( int gun, Vector3 pos, Vector3 to )
	{
		GunLocation[gun] = pos;
		GunDirection[gun] = to;
	}
	
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
				Vector3 v = p.GetBonePosition(HumanBodyBones.Hips);
				BoneData[place++] = (v.magnitude==0)?p.GetPosition():v;
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
            }
		}

		block.SetVector( "GenProps", new Vector4( updateCount, Time.timeSinceLevelLoad, 0, 0 ) );
		block.SetVectorArray( "SkeletonData", BoneData );
		
		block.SetVectorArray( "GunLocations", GunLocation );
		block.SetVectorArray( "GunDirection", GunDirection );
		
		if( didUpdateBoolets )
		{
			didUpdateBoolets = false;

			block.SetVectorArray( "BooletStartLocation", BooletStartLocation );
			block.SetVectorArray( "BooletStartDirection", BooletStartDirection );
			block.SetVectorArray( "BooletStartDataTime", BooletStartDataTime );
		}

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
				break;
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
				int place = i*12;
				int ct = 0;
				for( ct = 0; ct < 12; ct++ )
				{
					BoneData[place++] = new Vector4( 0.0f, 0.0f, 0.0f, 0.0f );
				}
				break;
			}
		}
    }
}
