Shader "CustomRenderTexture/H264CRTIngress"
{
    Properties
    {
        _MainTex("InputTex", 2D) = "white" {}
     }

     SubShader
     {
        Lighting Off
        Blend One Zero

		CGINCLUDE
		
		#define _SelfTexture2D _SelfTexture2D_Dummy
		#include "UnityCustomRenderTexture.cginc"
		#undef _SelfTexture2D
		
		#pragma vertex CustomRenderTextureVertexShader
		#pragma fragment frag
		#pragma target 5.0
		
		Texture2D< float4 > _SelfTexture2D;

		Texture2D< float4 >  _MainTex;
		float4 _MainTex_TexelSize;
		
		uint InData( uint2 coord ) { return _MainTex[coord].x*255.4; }
		float4 SelfData( uint2 coord ) { return _SelfTexture2D[uint2(coord.x, coord.y )]; }
		
		// Selects correct macroblock + skip.
		uint DecodeShipData( uint ship, uint field )
		{
			// Ships are organized as 128x96
			uint macroblock = (ship / 2)+3;
			int2 mbxy = uint2( macroblock % 8, macroblock / 8 ) * 16;  // resolution-dependent.
			int dpfield = (field * 3 + 1) / 2;
			int2 fieldxy = uint2( dpfield % 16, dpfield / 16 + (ship % 2) * 8 );
			return _MainTex[fieldxy+mbxy].x*255.4;
			// 0 1 2 3 4 5 6
			// 0 2 3 5 6 8 9 
		}
		ENDCG

        Pass
        {
			Name "InternalArea"
			
			CGPROGRAM
			float4 frag( v2f_customrendertexture IN) : COLOR
			{
				uint2 selfCoord = IN.globalTexcoord.xy * _CustomRenderTextureInfo.xy;
				uint virtualclock = asfloat(SelfData(int2(1,0)).x);
				
				if( selfCoord.x == 0 )
				{
					if( selfCoord.y == 0 )
						return float4( frac( _Time.y ),  asuint( 370000001 ), 0, 1 );
					else
						return _SelfTexture2D[int2(selfCoord.xy)-int2(0,1)];
				}
				if( selfCoord.x == 1 )
				{
					// Step 1: Decode encoded time
					uint dectime = InData(int2( 16, 0 )) + ( InData(int2( 18, 0 )) << 8 ) + ( InData( int2(20, 0 )) << 16 ) + ( InData(int2( 22, 0 )) << 24 );
					uint lastutime = asfloat(SelfData(int2(1,0)).z);

					float computedTimeOmega = atan2( _SinTime.w, _CosTime.w );
					float lastTimeOmega = SelfData(int2(1,1)).x;
					
					// Trick to get accurate deltaTime.
					float deltaOmega = computedTimeOmega - lastTimeOmega;
					if( deltaOmega < 0 ) deltaOmega += 3.1415926*2;
					
					virtualclock += deltaOmega * 1000000;

					if( dectime != lastutime || virtualclock - dectime > 4000000 )  // Reset virtual clock after a while.
					{
						// Updated times.
						int diff = dectime - lastutime;  // Diff is the length of time that has passed between last and now.
						if( diff > 1000000 || diff < 0 )
						{
							virtualclock = dectime;
						}
						else
						{
							int clockdiff = dectime - virtualclock;
							
							// Asymmetric timing filter.
							if( clockdiff < 0 )
							{
								// That's fine, tighten back on virtualclock a hair.
								virtualclock -= uint(-clockdiff) / 10;
							}
							else
							{
								//In the future! We must scoot scoot!
								virtualclock += clockdiff;
							}
						}
						virtualclock = dectime;
						lastutime = dectime;
					}

					if( selfCoord.y == 0 )
						return float4( asuint(virtualclock) , asuint(dectime), asuint(lastutime), 1 );
					else if( selfCoord.y == 1 )
						return float4( computedTimeOmega, deltaOmega, 0, 1 );  // @1,1
					else
						return 0;
				}
				else if( selfCoord.x == 2 )
				{
					// Debugging/validation // 0x5AAA0fff
					uint dectime    =      InData(int2( 16, 0 ))  + (      InData(int2( 18, 0 ))  << 8 ) + (      InData( int2(20, 0 ))  << 16 ) + (      InData(int2( 22, 0 )) << 24 );
					uint invdectime = (255-InData(int2( 17, 0 ))) + ( (255-InData(int2( 19, 0 ))) << 8 ) + ( (255-InData( int2(21, 0 ))) << 16 ) + ( (255-InData(int2( 23, 0 ))) << 24 );
					
					return float4( dectime != invdectime, asfloat(SelfData(int2(0,0)).y) == 370000001, (virtualclock-dectime)/1000000.0, 1 );
				}
				
				return 0.;
			}
			ENDCG
		}

        Pass
        {
			Name "DecodeArea"

            CGPROGRAM

            float4 frag(v2f_customrendertexture IN) : COLOR
            {
				uint2 selfCoord = IN.globalTexcoord.xy * _CustomRenderTextureInfo.xy;
				//selfCoord.y = _CustomRenderTextureInfo.y - selfCoord.y - 1; // 0,0 at top-left.
				uint virtualclock = asfloat(SelfData(int2(1,0)).x);
				float 

				//Our first 3 columns can be used for internal bookkeeping.
				
				
				// Otherwise we are a ship/boolet.
				// We have access to all the ship data + virtualclock
				
				int shipno = selfCoord.x - 3;
				
				switch( selfCoord.y )
				{
				case 0:  // Determine visibility + get feed-forward for ship.
				{
					uint basePeerFlags = DecodeShipData( shipno, 16 );
					uint shiptou = DecodeShipData( shipno, 0 ) + (DecodeShipData( shipno, 1 )<<8) + (DecodeShipData( shipno, 2 )<<16) + (DecodeShipData( shipno, 3 )<<24);
					return float4( ( shiptou - virtualclock ) / 1000000.0, basePeerFlags != 0, 0.0, 1.0 ); //NOTE SPARE FIELD
				}
				case 1: // Ship's position
				{
					uint3 sp = uint3(
						DecodeShipData( shipno, 4 ) + (DecodeShipData( shipno, 5)<<8),
						DecodeShipData( shipno, 6 ) + (DecodeShipData( shipno, 7)<<8),
						DecodeShipData( shipno, 8 ) + (DecodeShipData( shipno, 9)<<8),
						);
					// 16-bit sign extension.
					if( sp.x >= 0x8000 ) sp.x += 0xffff0000;
					if( sp.y >= 0x8000 ) sp.y += 0xffff0000;
					if( sp.z >= 0x8000 ) sp.z += 0xffff0000;
					int3 spworld = sp;
					return float4( spworld / 64.0, 1.0 );
				}
				case 2: // Ship's velocity
				{
					uint3 sp = uint3(
						DecodeShipData( shipno, 10 ),
						DecodeShipData( shipno, 11 ),
						DecodeShipData( shipno, 12 ),
						);
					// 8-bit sign extension.
					if( sp.x >= 0x80 ) sp.x += 0xffffff00;
					if( sp.y >= 0x80 ) sp.y += 0xffffff00;
					if( sp.z >= 0x00 ) sp.z += 0xffffff00;
					int3 svworld = sp;
					return float4( svworld / 64.0, 1.0 ); // XXX TODO: Figure out units.
				}
				case 3: // Ship's rotation
				{
					uint3 sp = uint3(
						DecodeShipData( shipno, 13 ),
						DecodeShipData( shipno, 14 ),
						DecodeShipData( shipno, 15 ),
						);
					// 8-bit sign extension.
					if( sp.x >= 0x80 ) sp.x += 0xffffff00;
					if( sp.y >= 0x80 ) sp.y += 0xffffff00;
					if( sp.z >= 0x80 ) sp.z += 0xffffff00;
					int3 srworld = sp;
					return float4( srworld / 255.0 * 3.1415926 * 2, 1.0 );
				}
				case 4:
				{
					uint basePeerFlags = DecodeShipData( shipno, 16 );
					uint auxPeerFlags =  DecodeShipData( shipno, 17 ) + ( DecodeShipData( shipno, 18 ) << 8 );
					
					// Time since exploded.
					float4 self = SelfData( selfCoord );
					float timeSinceExplodedSeconds = self.z;
					if( basePeerFlags & 2 )
					{
						// We're dead.
						timeSinceExplodedSeconds += SelfData( uint2( 1, 1 ).y;
					}

					// Other flags.
					return float4(
						basePeerFlags,
						auxPeerFlags,
						timeSinceExplodedSeconds,
						0.0, 1.0 ); // Spare!
				}
				case 5:
				{
					// Ship color
					uint baseColor = DecodeShipData( shipno, 19 );
					uint blueAmt = baseColor % 6;
					baseColor /= 6;
					uint grnAmt = baseColor % 6;
					baseColor /= 6;
					uint redAmt = baseColor % 6;
					return float4( redAmt / 5.0, grnAmt / 5.0, bluAmt / 5.0, 1.0 );					
				}
				case 6:
				case 7:
					return 0;
				case 8:
				case 12:
				case 16:
				case 20:
				{
					// Boolet
					uint boolettou = DecodeShipData( shipno, 20+ ) + (DecodeShipData( shipno, 1 )<<8) + (DecodeShipData( shipno, 2 )<<16) + (DecodeShipData( shipno, 3 )<<24);
					 // PICK UP HERE TOMORROW.
				}
				
				
				
				}
				
				/*
				
									case 20 ... 35:
										color = (b+((pxid-20)/4))->timeOfLaunch >> ( (pxid&3) * 8 );
										break;
									case 36 ... 59:
										color = (b+((pxid-36)/6))->launchLocation[((pxid-36)/2)%3] >> ( (pxid&1) * 8 );
										break;
									case 60 ... 75:
										color = (b+((pxid-60)/4))->launchRotation[((pxid-60)/2)%3] >> ( (pxid&1) * 8 );
										break;
									case 76 ... 83:
										color = (b+((pxid-76)/2))->flags >> ( ( pxid & 1 ) * 8);
										break;
									case 84:
										color = 0x7f; // Present or not?
										break;
									}
				*/
				
                return _MainTex[selfCoord];
            }

            ENDCG
		}
    }
}