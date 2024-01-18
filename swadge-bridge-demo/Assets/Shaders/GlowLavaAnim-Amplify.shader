// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "GlowLavaAnim-Amplify"
{
	Properties
	{
		_BaseColor("BaseColor", Color) = (0,0.792293,0.8584906,1)
		_BaseColor1("BaseColor", Color) = (0.7735849,0.7735849,0.7735849,1)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform float4 _BaseColor;
		uniform float4 _BaseColor1;


		float2 voronoihash34( float2 p )
		{
			
			p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
			return frac( sin( p ) *43758.5453);
		}


		float voronoi34( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
		{
			float2 n = floor( v );
			float2 f = frac( v );
			float F1 = 8.0;
			float F2 = 8.0; float2 mg = 0;
			for ( int j = -1; j <= 1; j++ )
			{
				for ( int i = -1; i <= 1; i++ )
			 	{
			 		float2 g = float2( i, j );
			 		float2 o = voronoihash34( n + g );
					o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
					float d = 0.5 * dot( r, r );
			 		if( d<F1 ) {
			 			F2 = F1;
			 			F1 = d; mg = g; mr = r; id = o;
			 		} else if( d<F2 ) {
			 			F2 = d;
			
			 		}
			 	}
			}
			return F1;
		}


		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float time34 = ( _Time.w * 0.0 );
			float2 voronoiSmoothId34 = 0;
			float2 uv_TexCoord25 = i.uv_texcoord * float2( 10,10 );
			float2 coords34 = ( uv_TexCoord25 + ( float2( 1,1 ) * _Time.y ) ) * float2( 0.4,10 ).x;
			float2 id34 = 0;
			float2 uv34 = 0;
			float voroi34 = voronoi34( coords34, time34, id34, uv34, 0, voronoiSmoothId34 );
			float4 temp_cast_1 = (voroi34).xxxx;
			float4 blendOpSrc24 = _BaseColor;
			float4 blendOpDest24 = temp_cast_1;
			o.Albedo = ( saturate( (( blendOpSrc24 > 0.5 )? ( blendOpDest24 + 2.0 * blendOpSrc24 - 1.0 ) : ( blendOpDest24 + 2.0 * ( blendOpSrc24 - 0.5 ) ) ) )).rgb;
			float4 temp_cast_3 = (pow( voroi34 , 1.35 )).xxxx;
			float4 blendOpSrc22 = temp_cast_3;
			float4 blendOpDest22 = _BaseColor1;
			o.Emission = ( ( saturate( (( blendOpDest22 > 0.5 ) ? ( 1.0 - 2.0 * ( 1.0 - blendOpDest22 ) * ( 1.0 - blendOpSrc22 ) ) : ( 2.0 * blendOpDest22 * blendOpSrc22 ) ) )) * 2.0 ).rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.ColorNode;21;-400.1761,-78.89636;Inherit;False;Property;_BaseColor;BaseColor;0;0;Create;True;0;0;0;False;0;False;0,0.792293,0.8584906,1;0.702,0.1168953,0,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BlendOpsNode;24;1.650459,-51.83134;Inherit;True;LinearLight;True;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.VoronoiNode;34;-279.9153,368.1342;Inherit;True;0;0;1;0;1;False;1;False;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;3;FLOAT;0;FLOAT2;1;FLOAT2;2
Node;AmplifyShaderEditor.Vector2Node;35;-560.3801,654.1166;Inherit;False;Constant;_Vector2;Vector 1;3;0;Create;True;0;0;0;False;0;False;0.4,10;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;691.4694,-35.80508;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;GlowLavaAnim-Amplify;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;17;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;27;-749.3152,574.846;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;33;-1089.015,771.8461;Inherit;False;Property;_VoronoiSpeed;VoronoiSpeed;2;0;Create;True;0;0;0;False;0;False;1;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;25;-852.3683,239.2726;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;28;-526.6763,293.5037;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-764.3152,450.8459;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;30;-989.9212,385.3163;Inherit;False;Constant;_Vector1;Vector 1;3;0;Create;True;0;0;0;False;0;False;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;26;-1108.516,202.1458;Inherit;False;Constant;_Vector0;Vector 0;2;0;Create;True;0;0;0;False;0;False;10,10;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TimeNode;31;-1202.315,537.846;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;32;-258.6224,728.912;Inherit;False;Property;_BaseColor1;BaseColor;1;0;Create;True;0;0;0;False;0;False;0.7735849,0.7735849,0.7735849,1;1,0.6894006,0,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;36;501.6267,315.067;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;37;415.0271,496.8669;Inherit;False;Constant;_Float0;Float 0;2;0;Create;True;0;0;0;False;0;False;2;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;39;-93.05768,416.996;Inherit;False;Constant;_Float1;Float 0;2;0;Create;True;0;0;0;False;0;False;1.35;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.BlendOpsNode;22;153.3776,450.9118;Inherit;True;Overlay;True;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.PowerNode;40;40.94232,217.9959;Inherit;True;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
WireConnection;24;0;21;0
WireConnection;24;1;34;0
WireConnection;34;0;28;0
WireConnection;34;1;27;0
WireConnection;34;2;35;0
WireConnection;0;0;24;0
WireConnection;0;2;36;0
WireConnection;27;0;31;4
WireConnection;25;0;26;0
WireConnection;28;0;25;0
WireConnection;28;1;29;0
WireConnection;29;0;30;0
WireConnection;29;1;31;2
WireConnection;36;0;22;0
WireConnection;36;1;37;0
WireConnection;22;0;40;0
WireConnection;22;1;32;0
WireConnection;40;0;34;0
WireConnection;40;1;39;0
ASEEND*/
//CHKSM=3570F87CD27BB3C788E6389E6638C7841782E526