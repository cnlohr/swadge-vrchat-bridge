Shader "Unlit/SwadgeGeometryShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
	
		Tags { "RenderType"="Opaque" }
		LOD 100
		Cull Off
	
		CGINCLUDE
		#pragma vertex vert
		#pragma geometry geo
		// make fog work
		#pragma multi_compile_fog
		#pragma target 5.0

		#include "UnityCG.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float3 uv : TEXCOORD0;
			float2 uv2 : TEXCOORD1;
			float3 normal : NORMAL;
		};

		struct v2g
		{
			float3 uv : TEXCOORD0;
			float2 uv2 : TEXCOORD1;
			float4 vertex : SV_POSITION;
			float3 normal : NORMAL;
		};

		struct g2f
		{
			float3 _ShadowCoord : SHADOWCOORD;
			float3 uv : TEXCOORD0;
			float3 normal : NORMAL;
			float4 vertex : SV_POSITION;
			UNITY_FOG_COORDS(1)
		};

		sampler2D _MainTex;
		float4 _MainTex_ST;

		v2g vert (appdata v)
		{
			v2g o;
			o.vertex = v.vertex;
			o.uv = v.uv;
			o.uv2 = v.uv2;
			o.normal = v.normal;
			UNITY_TRANSFER_FOG(o,o.vertex);
			return o;
		}
		

		[maxvertexcount(3)]
		void geo(triangle v2g input[3], inout TriangleStream<g2f> triStream)
		{
			g2f o;
			
			for(int i = 0; i < 3; i++)
			{
				o.uv = input[i].uv;
				float4 worldPlace = mul(unity_ObjectToWorld, float4(input[i].vertex));
				
				worldPlace.z += o.uv.z;
				
				o.vertex = mul(UNITY_MATRIX_VP, worldPlace);
				UNITY_TRANSFER_FOG(o,o.vertex);
				o.uv = input[i].uv;
				o.normal = UnityObjectToWorldNormal(input[i].normal);
				
				o._ShadowCoord = ComputeScreenPos(o.vertex);
				#if UNITY_PASS_SHADOWCASTER
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				#endif

				triStream.Append(o);
			}
			triStream.RestartStrip();
		}
		ENDCG
	  

		Pass
		{
			CGPROGRAM
			#pragma fragment frag

			fixed4 frag (g2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = float4( i.normal, 1.0 );
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
		
				
		Pass
		{
		Tags { "RenderType"="Opaque" "LightMode" = "ShadowCaster" }
		LOD 100
		CGPROGRAM
			#pragma fragment fragShadow
			#pragma multi_compile_shadowcaster
			float4 fragShadow(g2f i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}   
		ENDCG
		}
	}
}
