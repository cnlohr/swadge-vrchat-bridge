Shader "Unlit/SwadgeDebugInfo"
{
    Properties
    {
        _IngressRenderTexture ("_IngressRenderTexture", 2D) = "white" {}
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


			#pragma target 5.0
			
			#include "/Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
			#include "/Packages/com.llealloo.audiolink/Runtime/Shaders/SmoothPixelFont.cginc"
			
            #include "UnityCG.cginc"

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

            Texture2D< float4 > _IngressRenderTexture;
            float4 _IngressRenderTexture_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
			
			float4 Ingress( uint x, uint y ) { return _IngressRenderTexture[uint2( x, y )]; }

            fixed4 frag (v2f i) : SV_Target
            {
//                fixed4 col = _IngressRenderTexture[i.uv*_IngressRenderTexture_TexelSize.zw];

				float4 c = 0.0;
                float2 iuv =  i.uv;
                iuv.y = 1.-iuv.y;
                const uint rows = 12;
                const uint cols = 13;
                const uint number_area_cols = 11;
                
                float2 pos = iuv*float2(cols,rows);
                uint2 dig = (uint2)(pos);

                // This line of code is tricky;  We determine how much we should soften the edge of the text
                // based on how quickly the text is moving across our field of view.  This gives us realy nice
                // anti-aliased edges.
                float2 softness = 2./pow( length( float2( ddx( pos.x ), ddy( pos.y ) ) ), 0.5 );

                // Another option would be to set softness to 20 and YOLO it.

                float2 fmxy = float2( 4, 6 ) - (glsl_mod(pos,1.)*float2(4.,6.));

                float value = 0;
                int xoffset = 5;
                bool leadingzero = false;
                int points_after_decimal = 0; 
                int max_decimals = 5;

				if( dig.y < 8 )
				{
					uint sendchar = 0;
					const uint sendarr[80] = { 
						'S', 't', 'r', 'e', 'a', 'm', ' ', 'O', 'k', ' ',
						'N', 'o', ' ', 's', 't', 'r', 'e', 'a', 'm', ' ',
						'I', 'n', 'i', 't', ' ', 'F', 'a', 'i', 'l', ' ',
						'B', 'a', 'd', ' ', 'r', 'a', 'n', 'g', 'e', ' ',
						'C', 'h', 'e', 'c', 'k', ' ', 'V', 'i', 'd', ' ',
						'S', 'e', 't', 't', 'i', 'n', 'g', 's', ' ', ' ',
						'C', 'h', 'e', 'c', 'k', ' ', 'F', 'a', 'i', 'l',
						'T', 'i', 'm', 'e', ' ', 'f', 'a', 'i', 'l', ' '
						};
					sendchar = sendarr[dig.x+dig.y*10];
					float4 tc = PrintChar( sendchar, fmxy, softness, 0.0 );
					if( dig.x >= 10 ) tc *= 0;
					switch( dig.y )
					{
					case 0:
						if( length(Ingress( 2, 0 ).rgb) > 0.1 || length(Ingress( 2, 8 ).rgb) > 0.1 ) tc *= 0;
						break;
					case 1:
						if( Ingress( 2, 8 ).g < 0.5 ) tc *= 0; else tc *= float4( 1., 0., 0., 1.);
						break;
					case 2:
						if( Ingress( 2, 8 ).b < 0.5 ) tc *= 0; else tc *= float4( 1., 0., 0., 1.);
						break;
					case 3:
					case 4:
					case 5:
						if( Ingress( 2, 8 ).r < 0.5 ) tc *= 0; else tc *= float4( 1., 0., 0., 1.);
						break;
					case 6:
						if( Ingress( 2, 0 ).b < 0.5 ) tc *= 0; else tc *= float4( 1., 0., 0., 1.);
						break;
					case 7:
						if( Ingress( 2, 0 ).r < 0.5 ) tc *= 0; else tc *= float4( 1., 0., 0., 1.);
						break;
					}
					
					c += tc;
				}
				else
				{
					dig.y -= 8;
					const uint sendarr[20] = { 
						'D', 'e', 'l', 't', 'a', 
						'F', 'P', 'S', ' ', ' ',
						'O', 'm', 'e', 'g', 'a',
						'C', 'T', 'i', 'm', 'e',
						};
					if( dig.x > 4 )
					{
						dig.x -= 4;
						switch( dig.y )
						{
						case 0:
							value = Ingress( 1, 1 ).g;
							break;
						case 1:
							value = 1.0/Ingress( 1, 1 ).g;
							break;
						case 2:
							value = Ingress( 1, 1 ).r;
							break;
						case 3:
							value = asuint( Ingress( 1, 0 ).r ) & 0xffffff;
							xoffset = 9;
							leadingzero = 0;
							break;
						default:
							c = 0;
							break;
						}
						float num = PrintNumberOnLine( value, fmxy, softness, dig.x - xoffset, points_after_decimal, max_decimals, leadingzero, 0 );
						c.rgb = lerp( c.rgb, 1.0, num );
						c.a += num;
					}
					else
					{
						float4 tc = PrintChar( sendarr[dig.x+dig.y*5], fmxy, softness, 0.0 );
						c+= tc;
					}
				}
				
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, c);
                return c;
            }
            ENDCG
        }
    }
}
