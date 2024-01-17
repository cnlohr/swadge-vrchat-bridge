using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using VRC.SDK3.Rendering;
using VRC.Udon.Common.Interfaces;

public class SwadgeIntegration : UdonSharpBehaviour
{
	public RenderTexture H264FunIngress;
	
	private SkinnedMeshRenderer mr;
	private MaterialPropertyBlock block;
	
	private int[] PlayerLastFlags = new int[90];
	
	
	private const int playerArrayCount = 84;
	
	// We use a hard-coded 84 max, i.e. 80 + 4 staff.
	private VRCPlayerApi[] playerArray = new VRCPlayerApi[playerArrayCount];
	private Vector4[] BoneData = new Vector4[84*12];

	// 48 Entities (not counting VRChat players)
	private Vector4[] EnemyPositions = new Vector4[48];
	private Vector4[] EnemyRotations = new Vector4[48];	

	private int updateCount = 0;
	
	
	private bool didUpdateBoolets;
	private bool didUpdateEnemies;
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
	
	//Implemented
	public void UUpdateEnemy(int enemyID, int enemyType, Vector3 Position, Quaternion Q) // Call this over and over
	{
		// TODO: cnlohr code goes here.
		// THIS is called FROM Draken's code
		EnemyPositions[enemyID] = new Vector4( Position.x, Position.y, Position.z, (float)enemyType );
		EnemyRotations[enemyID] = new Vector4( Q.x, Q.y, Q.z, Q.w );
		didUpdateEnemies = true;
	}

	//Implemented
	public void URemoveEnemy(int enemyID) // Only call when you are done
	{
		// TODO: cnlohr code goes here.
		// THIS is called FROM Draken's code
		EnemyPositions[enemyID] = new Vector4( 0, 0, 0, -1 );
		didUpdateEnemies = true;
	}

	//Implemented
	public void UpdateBooletArrayFromSwadges(Vector3[] BooletPos, Vector3[] BooletTo, float[] BooletTimes, byte[] SwadgeID)
	{
		// Call this from my stuff.
		//dataManager._updateBooletArrayFromSwadges(BooletPos, BooletTo, SwadgeID);
	}

	//Implemented
	public void UpdateSwadgeShips(Vector3[] SwadgeShipPos, byte[] SwadgeID)
	{
		// Call this from my stuff.
		// dataManager._updateSwadgeShips(SwadgeShipPos, SwadgeShipQuat, SwadgeID);
	}

	//Implemented
	public void SwadgeDefeated(byte SwadgeID)
	{
		// Call this from my stuff.
		//dataManager._swadgeDefeated(SwadgeID);
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

		if( didUpdateEnemies )
		{
			didUpdateEnemies = false;
			block.SetVectorArray( "EnemyPositions", EnemyPositions );
			block.SetVectorArray( "EnemyRotations", EnemyRotations );			
		}

		mr.SetPropertyBlock(block);
		updateCount++;
		
		VRCAsyncGPUReadback.Request(H264FunIngress, 0, (IUdonEventReceiver)this);
	}
	
	
	public override void OnAsyncGpuReadbackComplete(VRCAsyncGPUReadbackRequest request)
	{
		if (request.hasError)
		{
			Debug.LogError("GPU readback error!");
			return;
		}
		else
		{
			var px = new Color32[H264FunIngress.width * H264FunIngress.height];
			if( request.TryGetData(px) )
			{
				int i;
				int h = H264FunIngress.height;
				int hindex = 6;
				
				byte[] SwadgeID = new byte[90];
				Vector3[] SwadgeShipPos = new Vector3[90];
				
				Vector3[] BooletPos = new Vector3[90*4];
				Vector3[] BooletTo = new Vector3[90*4];
				float [] BooletTime = new float[90*4];
				byte[] BooletSwadgeID = new byte[90*4];

				int bid = 0;
				for( i = 0; i < 90; i++ )
				{
					int flags = (int)px[hindex+h*4].r;
					int lastflags = PlayerLastFlags[i];
					if( ( ( flags ^ lastflags ) & 2 ) != 0 )
					{
						// Change to alive state.
						if( ( flags & 2 ) != 0 )
						{
							SwadgeDefeated( (byte)i );
						}
					}
					
					Color32 Pos = px[hindex+h*1];
					SwadgeShipPos[i] = new Vector3( Pos.r, Pos.g, Pos.b );
					SwadgeID[i] = (byte)i;

					Color32 BPos = px[hindex+h*12];
					BooletPos[bid] = new Vector3( BPos.r, BPos.g, BPos.b );
					Color32 BTo = px[hindex+h*16];
					BooletTo[bid] = new Vector3( BTo.r, BTo.g, BTo.b );
					Color32 BTime = px[hindex+h*8];
					BooletTime[bid] = BTime.r;
					BooletSwadgeID[bid] = (byte)i;
					bid++;

					hindex++;
				}
				
				UpdateBooletArrayFromSwadges( BooletPos, BooletTo, BooletTime, BooletSwadgeID );
				UpdateSwadgeShips( SwadgeShipPos, SwadgeID );
			}
			else
			{
				Debug.Log("GPU readback failure");
			}
		}
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
