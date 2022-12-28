Shader "Unlit/H264Examine"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_MacroblockX ("Macroblock X", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

			#include "..\AudioLink\Shaders\SmoothPixelFont.cginc"
		
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

			uniform float4               _MainTex_TexelSize;

	//		#ifdef SHADER_TARGET_SURFACE_ANALYSIS
	//		#define AUDIOLINK_STANDARD_INDEXING
	//		#endif

	//		// Mechanism to index into texture.
	//		#ifdef AUDIOLINK_STANDARD_INDEXING
	//			sampler2D _MainTex;
	//			#define LData(xycoord) tex2Dlod(_MainTex, float4(uint2(xycoord) * _MainTex_TexelSize.xy, 0, 0))
	//		#else
				uniform Texture2D<float4>   _MainTex;
				#define LData(xycoord) _MainTex[uint2(xycoord)]
	//		#endif

			float _MacroblockX;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float2 uv = i.uv;
				uv.y = 1. - uv.y;
				// Albedo comes from a texture tinted by color
				float4 c;
	//            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;


				//uv.x = 1. - uv.x;
				float2 tx = uv*float2(128,16*3);
				int2 cpos = floor(tx.xy);
				float am = 0;
				int2 cell = int2( cpos.x / 8, cpos.y );

				if( (cpos.x & 7) == 7 )
				{
					am = 0;
					c = float4( ((cell.y%3)==0), ((cell.y%3)==1), ((cell.y%3)==2), 1 );
				}
				else
				{
					cpos.x &= 7;
					int2 readpos = cell/int2(1,3);
					readpos.x += int(_MacroblockX)*16;

					//readpos.y = _MainTex_TexelSize.w - readpos.y - 1;
					float4 dat = LData(readpos);
//					dat.x = LinearToGammaSpace( dat.x );
//					dat.y = LinearToGammaSpace( dat.y );
//					dat.z = LinearToGammaSpace( dat.z );
					float4 cd = dat;
					float value = ((cell.y%3)==0)?cd.x:(((cell.y%3)==1)?cd.y:cd.z);
					//value = readpos.y;
					am = PrintNumberOnLine( value*255.0 +0.0001, float2(4,8)-frac(tx)*float2(4,8), 10, cpos.x, 3, 3, 0, 0 );
					c = 0;
				}
					
				c += am.xxxx;
				return c;
            }
            ENDCG
        }
    }
}
