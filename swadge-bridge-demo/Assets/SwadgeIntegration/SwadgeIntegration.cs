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
	public void UpdateBooletArrayFromSwadges(Vector3[] BooletPos, Vector3[] BooletTo, float[] BooletTimes )
	{
		// Call this from my stuff.
		//dataManager._updateBooletArrayFromSwadges(BooletPos, BooletTo, SwadgeID);
		//Debug.Log(BooletPos[0] + " " + BooletTo[0] + " " + BooletTimes[0] );
		//
		//					Current Place = BooletPos + BooletTo * BooletTimes
	}

	//Implemented
	public void UpdateSwadgeShips(Vector3[] SwadgeShipPos )
	{
		//int i;
		//for( i = 0; i < 90; i++ )
		//{
		//	Debug.Log(SwadgeShipPos[i]);
		//}
		//Debug.Log("-------------------");
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
		
		for (int i = 0; i < EnemyPositions.Length; i++)
		{
			EnemyPositions[i].w = -1;
		}
		didUpdateEnemies = true;
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
		
		/*
		// TEST TEST TEST ENEMY TEST
		float f = Time.timeSinceLevelLoad;
		for( int i = 0; i < 48; i++ )
		{
			Vector3 Pos = new Vector3( (float)System.Math.Cos( f )*10.0f, 10.0f, (float)System.Math.Sin( f )*10.0f );
			Quaternion Q = new Quaternion( 0, 0, 0, 1 );
			UUpdateEnemy( i, 0, Pos, Q);
			f += 0.01f;
		}
		*/

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
			var px = new Color[H264FunIngress.width * H264FunIngress.height];
			if( request.TryGetData(px) )
			{
				int i;
				int h = H264FunIngress.height;
				int w = H264FunIngress.width;
				int hindex = 6;
				
				Vector3[] SwadgeShipPos = new Vector3[90];
				
				Vector3[] BooletPos = new Vector3[90*4];
				Vector3[] BooletTo = new Vector3[90*4];
				float [] BooletTime = new float[90*4];

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
					
					Color Pos = px[hindex+w*1];
					SwadgeShipPos[i] = new Vector3( Pos.r, Pos.g, Pos.b );

					Color BPos = px[hindex+w*12];
					BooletPos[bid+0] = new Vector3( BPos.r, BPos.g, BPos.b );
					BPos = px[hindex+w*13];
					BooletPos[bid+1] = new Vector3( BPos.r, BPos.g, BPos.b );
					BPos = px[hindex+w*14];
					BooletPos[bid+2] = new Vector3( BPos.r, BPos.g, BPos.b );
					BPos = px[hindex+w*15];
					BooletPos[bid+3] = new Vector3( BPos.r, BPos.g, BPos.b );

					Color BTo = px[hindex+w*16];
					BooletTo[bid+0] = new Vector3( BTo.r, BTo.g, BTo.b );
					BTo = px[hindex+w*17];
					BooletTo[bid+1] = new Vector3( BTo.r, BTo.g, BTo.b );
					BTo = px[hindex+w*18];
					BooletTo[bid+2] = new Vector3( BTo.r, BTo.g, BTo.b );
					BTo = px[hindex+w*19];
					BooletTo[bid+3] = new Vector3( BTo.r, BTo.g, BTo.b );
					
					Color BTime = px[hindex+w*8];
					BooletTime[bid+0] = BTime.r;
					BTime = px[hindex+w*9];
					BooletTime[bid+1] = BTime.r;
					BTime = px[hindex+w*10];
					BooletTime[bid+2] = BTime.r;
					BTime = px[hindex+w*11];
					BooletTime[bid+3] = BTime.r;
					bid+=4;

					hindex++;
				}
				
				UpdateBooletArrayFromSwadges( BooletPos, BooletTo, BooletTime );
				UpdateSwadgeShips( SwadgeShipPos );
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
