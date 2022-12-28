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
		
		#define WORLDSCALE 64.0
		
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
			uint dpfield = ( uint(field * 3) + 1) / 2;
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
				uint virtualclock = asuint(SelfData(int2(1,0)).x);
				
				if( selfCoord.x == 0 )
				{
					if( selfCoord.y == 0 )
						return float4( frac( _Time.y ), asfloat( 370000001 ), 0, 1 );
					else
						return _SelfTexture2D[int2(selfCoord.xy)-int2(0,1)];
				}
				if( selfCoord.x == 1 )
				{
					// Step 1: Decode encoded time
					uint dectime = InData(int2( 16, 0 )) + ( InData(int2( 18, 0 )) << 8 ) + ( InData( int2(20, 0 )) << 16 ) + ( InData(int2( 22, 0 )) << 24 );
					uint lastutime = asuint(SelfData(int2(1,0)).z);

					float computedTimeOmega = atan2( _SinTime.w, _CosTime.w );
					float lastTimeOmega = SelfData(int2(1,1)).x;
					
					// Trick to get accurate deltaTime.
					float deltaOmega = computedTimeOmega - lastTimeOmega;
					if( deltaOmega < 0 ) deltaOmega += 3.1415926*2;
					float debug = 0;
					
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
						return float4( asfloat(virtualclock) , asfloat(dectime), asfloat(lastutime), 1 );
					else if( selfCoord.y == 1 )
						return float4( computedTimeOmega, deltaOmega, debug, 1 );  // @1,1
					else
						return 0;
				}
				else if( selfCoord.x == 2 )
				{
					// Debugging/validation SHOLD BE BLACK
					uint dectime    =      InData(int2( 16, 0 ))  + (      InData(int2( 18, 0 ))  << 8 ) + (      InData( int2(20, 0 ))  << 16 ) + (      InData(int2( 22, 0 )) << 24 );
					uint invdectime = (255-InData(int2( 17, 0 ))) + ( (255-InData(int2( 19, 0 ))) << 8 ) + ( (255-InData( int2(21, 0 ))) << 16 ) + ( (255-InData(int2( 23, 0 ))) << 24 );
					
					uint sentr    =      InData(int2( 16, 1 ))  + (      InData(int2( 18, 1 ))  << 8 ) + (      InData( int2(20, 1 ))  << 16 ) + (      InData(int2( 22, 1 )) << 24 );
					uint invsentr = (255-InData(int2( 17, 1 ))) + ( (255-InData(int2( 19, 1 ))) << 8 ) + ( (255-InData( int2(21, 1 ))) << 16 ) + ( (255-InData(int2( 23, 1 ))) << 24 );
					//|| sentr != invsentr
					return float4( dectime != invdectime , asuint(SelfData(int2(0,0)).y) != 370000001,  sentr != 0x5AAA0fff, 1 );
					
					//Can debug (virtualclock-dectime)/1000000.0
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
				uint virtualclock = asuint(SelfData(int2(1,0)).x);

				//Our first 3 columns can be used for internal bookkeeping.
				
				
				// Otherwise we are a ship/boolet.
				// We have access to all the ship data + virtualclock
				
				int shipno = selfCoord.x - 6;
				
				switch( selfCoord.y )
				{
				case 0:  // Determine visibility + get feed-forward for ship.
				{
					uint basePeerFlags = DecodeShipData( shipno, 16 );
					uint shiptou = DecodeShipData( shipno, 0 ) + (DecodeShipData( shipno, 1 )<<8) + (DecodeShipData( shipno, 2 )<<16) + (DecodeShipData( shipno, 3 )<<24);
					uint lastutime = asuint(SelfData(int2(1,0)).z);
					return float4( ( int(lastutime - virtualclock) ) / 1000000.0, basePeerFlags != 0, 0.0, 1.0 ); //NOTE SPARE FIELD
				}
				case 1: // Ship's position
				{
					uint3 sp = uint3(
						DecodeShipData( shipno, 4 ) + (DecodeShipData( shipno, 5)<<8),
						DecodeShipData( shipno, 6 ) + (DecodeShipData( shipno, 7)<<8),
						DecodeShipData( shipno, 8 ) + (DecodeShipData( shipno, 9)<<8)
						);
					// 16-bit sign extension.
					if( sp.x >= 0x8000 ) sp.x += 0xffff0000;
					if( sp.y >= 0x8000 ) sp.y += 0xffff0000;
					if( sp.z >= 0x8000 ) sp.z += 0xffff0000;
					int3 spworld = sp;
					return float4( spworld / float(WORLDSCALE), 1.0 );
				}
				case 2: // Ship's velocity
				{
					uint3 sp = uint3(
						DecodeShipData( shipno, 10 ),
						DecodeShipData( shipno, 11 ),
						DecodeShipData( shipno, 12 )
						);
					// 8-bit sign extension.
					if( sp.x >= 0x80 ) sp.x += 0xffffff00;
					if( sp.y >= 0x80 ) sp.y += 0xffffff00;
					if( sp.z >= 0x80 ) sp.z += 0xffffff00;
					int3 svworld = sp;
					return float4( svworld * 1000000.0 / 65536.0 / float(WORLDSCALE), 1.0 ); // Output in Meters / Second
				}
				case 3: // Ship's rotation
				{
					uint3 sp = uint3(
						DecodeShipData( shipno, 13 ),
						DecodeShipData( shipno, 14 ),
						DecodeShipData( shipno, 15 )
						);
					// 8-bit sign extension.
					if( sp.x >= 0x80 ) sp.x += 0xffffff00;
					if( sp.y >= 0x80 ) sp.y += 0xffffff00;
					if( sp.z >= 0x80 ) sp.z += 0xffffff00;
					int3 srworld = sp;
					return float4( srworld / 255.0 * 3.1415926 * 2, 1.0 );  // Output in radians.
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
						timeSinceExplodedSeconds += SelfData( uint2( 1, 1 ) ).y;
					}

					// Other flags.
					return float4(
						basePeerFlags,
						auxPeerFlags,
						timeSinceExplodedSeconds,
						1.0 );
				}
				case 5:
				{
					// Ship color
					uint baseColor = DecodeShipData( shipno, 19 );
					uint bluAmt = baseColor % 6;
					baseColor /= 6;
					uint grnAmt = baseColor % 6;
					baseColor /= 6;
					uint redAmt = baseColor % 6;
					return float4( redAmt / 5.0, grnAmt / 5.0, bluAmt / 5.0, 1.0 );					
				}
				case 6:
				{
					uint basePeerFlags = DecodeShipData( shipno, 16 );
					float accurateDeltaTime = SelfData(uint2(1,1)).y;
					float4 last = SelfData(selfCoord);
					if( basePeerFlags & 2 )
					{
						last.x += accurateDeltaTime;
					}
					else
					{
						last.x = 0;
					}
					
					// debug
					//last.x = SelfData(uint2(1,1)).x+2.0;
					
					// last.x = time dead.
					return last;
				}
				case 7:
					// Reserved
					return 0;
				case 8:
				case 9:
				case 10:
				case 11:
				{
					// Time of Launch
					uint bno = selfCoord.y - 8;
					uint boolettol = DecodeShipData( shipno, 20+bno*4 ) + (DecodeShipData( shipno, 21+bno*4 )<<8) + (DecodeShipData( shipno, 22+bno*4 )<<16) + (DecodeShipData( shipno, 23+bno*4 )<<24);					
					uint flags = DecodeShipData( shipno, 76+bno*2 ) + (DecodeShipData( shipno, 77+bno*2 )<<8);
					uint genpresent = DecodeShipData( shipno, 84 );
					return float4( (virtualclock-boolettol)/1000000.0, flags, genpresent, 1 );
				}
				case 12:
				case 13:
				case 14:
				case 15:
				{
					// Launch Locations
					uint bno = selfCoord.y - 12;
					uint blaunch_1 = DecodeShipData( shipno, 36+bno*6 ) + (DecodeShipData( shipno, 37+bno*6 )<<8);
					uint blaunch_2 = DecodeShipData( shipno, 38+bno*6 ) + (DecodeShipData( shipno, 39+bno*6 )<<8);
					uint blaunch_3 = DecodeShipData( shipno, 40+bno*6 ) + (DecodeShipData( shipno, 41+bno*6 )<<8);
					if( blaunch_1 & 0x8000 ) blaunch_1 |= 0xffff0000;
					if( blaunch_2 & 0x8000 ) blaunch_2 |= 0xffff0000;
					if( blaunch_3 & 0x8000 ) blaunch_3 |= 0xffff0000;
					return float4( int3( blaunch_1, blaunch_2, blaunch_3 ) / float( WORLDSCALE ), 1.0 );
				}
				case 16:
				case 17:
				case 18:
				case 19:
				{
					// Launch Directions
					uint bno = selfCoord.y - 16;
					uint blaunch_1 = DecodeShipData( shipno, 60+bno*4 ) + (DecodeShipData( shipno, 61+bno*4 )<<8);
					uint blaunch_2 = DecodeShipData( shipno, 62+bno*4 ) + (DecodeShipData( shipno, 63+bno*4 )<<8);
					if( blaunch_1 & 0x8000 ) blaunch_1 |= 0xffff0000;
					if( blaunch_2 & 0x8000 ) blaunch_2 |= 0xffff0000;
					
					float2 hpr2 = float2( blaunch_1, blaunch_2 ) / 11.0 / 180.0 * 3.14159;
					
					float yawDivisor = cos( hpr2.y );
					float3 direction = float3( sin( hpr2.x ) * yawDivisor, cos( hpr2.x ) * yawDivisor, -sin( hpr2.y ) );

					return float4( direction, 1.0 );
				}
				default:
					return 0.0;
				}

				// Never called.
                return _MainTex[selfCoord];
            }

            ENDCG
		}
    }
}