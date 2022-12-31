Shader "Unlit/SwadgeAppDataExporter"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// shadow caster rendering pass, implemented manually
		// using macros from UnityCG.cginc
		Pass
		{
			Tags {"LightMode"="ShadowCaster"}
			Cull Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"

			struct v2f { 
				V2F_SHADOW_CASTER;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				o.pos = 0;
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				discard;
				return 0.;
			}
			ENDCG
		}
		
		Tags { "RenderType"="Opaque" "Queue"="Overlay" }
		Cull Off
		ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "/Assets/AudioLink/Shaders/AudioLink.cginc"

			// 4, 4 component wide things.
			#define EXPORTSIZE float2( 12, 608 )

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			bool isVR() {
				// USING_STEREO_MATRICES
				#if UNITY_SINGLE_PASS_STEREO
					return true;
				#else
					return false;
				#endif
			}

			float3 GunLocations[24];
			float3 GunDirection[24];
			
			float3 BooletStartLocation[240];
			float3 BooletStartDirection[240];
			float3 BooletStartDataTime[240]; // [in_use 0 or 1, a counter making a unique value starting at 0 and counting to 65535 and resetting to zero.]

			float3 SkeletonData[12*84];
			float3 GenProps;
			
			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert (appdata v)
			{
				v2f o;
				float2 uvv = v.uv;
				uvv = uvv/_ScreenParams.xy;

				if( _ProjectionParams.x < 0 )
				{
					o.vertex = float4( -1+(uvv)*EXPORTSIZE*2, 1, 1 );
				}
				else
				{
					float2 vo = -1+(uvv)*EXPORTSIZE*2;
					vo.y = -vo.y;
					o.vertex = float4( vo, 1, 1 );
				}
				o.uv = v.uv;
				
//				if( _ProjectionParams.z != 0.313 ) o.vertex = 0;
				return o;
			}

			fixed4 frag (v2f i ) : SV_Target
			{
//				if( _ProjectionParams.z != 0.313 ) discard;
				
				uint2 sp = i.vertex;

				if( _ProjectionParams.x < 0 )
				{
					sp.y = _ScreenParams.y - sp.y - 1;
				}
				else
				{
					sp.y = sp.y;
				}

				float3 testvar = 0;

				if( sp.y < 8 )
				{
					switch( sp.y )
					{
					case 0:
						if( sp.x < 8 )
							testvar = asfloat( uint3( 0xaaaaaaaa, 0xa5a5a5a5, 0x5a5a5a5a ) );
						else
							testvar = 0;
						break;
					case 1:
						return AudioLinkData( ALPASS_CCLIGHTS + uint2( sp.x, 0 ) );
						break;
					case 2:
						testvar = mul( unity_ObjectToWorld, float4( 0, 0, 0, 1 ) );
						break;
					case 3:
						testvar = AudioLinkData( ALPASS_GENERALVU_PLAYERINFO );
						break;
					case 4:
						testvar = GenProps;
						break;
					case 5:
						testvar = float3( 0, 0, 0);
						break;
					case 6:
						return float4( GammaToLinearSpaceExact( sp.x / 255.0 ), GammaToLinearSpaceExact( (sp.x + 32)/255.0 ), GammaToLinearSpaceExact( (sp.x + 64)/255.0 ), 1.0 );
					case 7:
						return 1;
					}
				}
				else
				{
					uint2 compcoord = uint2( sp.x / 4, sp.y );
					// Starting at y = 8
					if( sp.y < 248 )
					{
						// (240 boolets)
						// * Up to 256 boolets.
						//	at: <xyz> dir: <xyz>  props: <unique ID, emission time>
						//Each line: <boolet> <boolet>
					
						if( compcoord.x == 0 )
							testvar = BooletStartLocation[sp.y-8];
						else if( compcoord.x == 1 )
							testvar = BooletStartDirection[sp.y-8];
						else if( compcoord.x == 2 )
							testvar = BooletStartDataTime[sp.y-8];
						else
							return float4( 0.1, 0.0, 0.0, 1.0 );
					}
					else if( sp.y < 584 ) // 84*4+248
					{
						//Players: (2 pix high PER PLAYER) up to 84 players.
						//    <xyz> <head rel-xyz> <chest>
						//    <l knee> <r knee> <l foot>
						//    <r foot> <l elbow> <r elbow>
						//    <l hand> <r hand> <reserved>
						
						testvar = SkeletonData[(compcoord.y-248)*3 + compcoord.x];
					}
					else if( sp.y < 608 ) // 24 guns.
					{
						// Guns are
						//    <coord base> <dir xyz> <trigger amount, reserved.yz>
						if( compcoord.x == 0 )
							testvar = GunLocations[sp.y-584];
						else if( compcoord.x == 1 )
							testvar = GunDirection[sp.y-584];
						else
							return float4( 0.0, 0.1, 0.0, 1.0 );
					}
					else
					{
						// Undefined area.
						testvar = _Time.yyy;
					}
				}


				uint3 exp = asuint( testvar );
				int spxr = sp.x & 0x3;
				float4 cc = float4( (((exp.xyz)>>((spxr)*8))&0xff) / 255.0, 1.0 );
				return float4( GammaToLinearSpaceExact( cc.r ), GammaToLinearSpaceExact( cc.g ), GammaToLinearSpaceExact( cc.b ), GammaToLinearSpaceExact( cc.a ) );
			}
			ENDCG
		}
	}
}
