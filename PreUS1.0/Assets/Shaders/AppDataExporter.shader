Shader "Unlit/AppDataExporter"
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
		
		Tags { "RenderType"="Overlay+1" }
		Cull Off
		ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "/Assets/AudioLink/Shaders/AudioLink.cginc"

			#define EXPORTSIZE float2( 8, 40 )

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

				float4 testvar = 0;

				if( sp.y < 8 )
				{
					switch( sp.y )
					{
					case 0:
						testvar = asfloat( uint4( 0xaaaaaaaa, 0xa5a5a5a5, 0x5a5a5a5a, 0x00a500ff ) );
						break;
					case 1:
						testvar = mul( unity_ObjectToWorld, float4( 0, 0, 0, 1 ) );
						break;
					case 2:
						testvar = AudioLinkData( ALPASS_GENERALVU );
						break;
					case 3:
						testvar = AudioLinkData( ALPASS_GENERALVU_PLAYERINFO );
						break;
					case 4:
						testvar = float4( _Time.y, AudioLinkDecodeDataAsSeconds( ALPASS_GENERALVU_INSTANCE_TIME ), 0.0, 0.0 );
						break;
					case 5:
						return float4( GammaToLinearSpaceExact( sp.x / 255.0 ), GammaToLinearSpaceExact( (sp.x + 32)/255.0 ), GammaToLinearSpaceExact( (sp.x + 64)/255.0 ), 1.0 );
					case 6:
						testvar = float4( AudioLinkData( uint2(0,0) ).x, AudioLinkData( uint2(0,1) ).x, AudioLinkData( uint2(0,2) ).x, AudioLinkData( uint2(0,3) ).x );
						break;
					case 7:
						return 0;
					}
				}
				else if( sp.y >= 24 )
				{
					return AudioLinkData( ALPASS_CCLIGHTS + uint2( (sp.y-24)*8+sp.x, 0 ) );
				}

				uint4 exp = asuint( testvar );
				int spxr = sp.x & 0x7;
				float4 cc = float4( (((( spxr&1 )?exp.xy:exp.zw)>>((spxr/2)*8))&0xff) / 255.0, 0.0, 1.0 );
				return float4( GammaToLinearSpaceExact( cc.r ), GammaToLinearSpaceExact( cc.g ), GammaToLinearSpaceExact( cc.b ), GammaToLinearSpaceExact( cc.a ) );
			}
			ENDCG
		}
	}
}
