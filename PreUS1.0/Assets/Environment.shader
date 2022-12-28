Shader "Unlit/Environment"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 100
		Cull Off
		ZWrite Off
		Blend One One // Additive

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geo
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float4 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2g
			{
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};
			
			struct g2f
			{
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 barycentric : BARY;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2g vert (appdata v)
			{
				v2g o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = v.normal;
				return o;
			}

			[maxvertexcount(3)]
			void geo(triangle v2g input[3], inout TriangleStream<g2f> triStream)
			{
				g2f o;
				
							
				float2 WIN_SCALE = float2(_ScreenParams.x/2.0, _ScreenParams.y/2.0);
				


				//frag position
				float2 p0 = WIN_SCALE * input[0].vertex.xy / input[0].vertex.w;
				float2 p1 = WIN_SCALE * input[1].vertex.xy / input[1].vertex.w;
				float2 p2 = WIN_SCALE * input[2].vertex.xy / input[2].vertex.w;
				
				float2 v0 = p2-p1;
				float2 v1 = p2-p0;
				float2 v2 = p1-p0;
				
				//triangles area
				float area = abs(v1.x*v2.y - v1.y * v2.x);
				
				for(int i = 0; i < 3; i++)
				{
					o.vertex = input[i].vertex;

					
					UNITY_TRANSFER_FOG(o,o.vertex);
					o.uv = input[i].uv;
					o.normal = UnityObjectToWorldNormal(input[i].normal);
					
					o.barycentric = float3( ((i==0)?area/length(v0):0), ((i==1)?area/length(v1):0), ((i==2)?area/length(v2):0) );
					//o._ShadowCoord = ComputeScreenPos(o.vertex);
					#if UNITY_PASS_SHADOWCASTER
					o.vertex = UnityApplyLinearShadowBias(o.vertex);
					#endif
					triStream.Append(o);
				}
				triStream.RestartStrip();
			}

			fixed4 frag (g2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = float4( i.normal/2.0 + 0.5, 1.0 );//tex2D(_MainTex, i.uv);
				
				float minbary = min( min( i.barycentric.x, i.barycentric.y ), i.barycentric.z );
				
				//col *= clamp( minbary-0.6, 0, 1 )*0.5;
				col *= clamp( 1.6-minbary, 0, 1 )*0.5;
				
				return col;
			}
			ENDCG
		}
		
	Pass {
		Tags {"LightMode" = "ShadowCaster"}
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile_instancing
		#pragma multi_compile_shadowcaster
		#include "UnityCG.cginc"

		struct appdata {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		struct v2f {
			float4 pos : SV_POSITION;
			UNITY_VERTEX_INPUT_INSTANCE_ID 
			UNITY_VERTEX_OUTPUT_STEREO
		};

		v2f vert (appdata v){
			v2f o = (v2f)0;
			UNITY_SETUP_INSTANCE_ID(v);
			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
			TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
			return o;
		}

		float4 frag (v2f i) : SV_Target {
			UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
			discard;
			return 0;
		}
		ENDCG
	}
	}
}
