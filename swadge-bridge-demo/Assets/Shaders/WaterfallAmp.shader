// Made with Amplify Shader Editor v1.9.1.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "WaterfallAmp"
{
	Properties
	{
		_BaseColor("BaseColor", Color) = (0,0.792293,0.8584906,1)
		_VoronoiSpeed("VoronoiSpeed", Float) = 3
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		Blend SrcAlpha OneMinusSrcAlpha
		
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform float4 _BaseColor;
		uniform float _VoronoiSpeed;


		float2 voronoihash19( float2 p )
		{
			
			p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
			return frac( sin( p ) *43758.5453);
		}


		float voronoi19( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
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
			 		float2 o = voronoihash19( n + g );
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
			float time19 = ( _Time.y * _VoronoiSpeed );
			float2 voronoiSmoothId19 = 0;
			float2 uv_TexCoord43 = i.uv_texcoord * float2( 5,5 );
			float2 coords19 = ( uv_TexCoord43 + ( float2( 1,5 ) * _Time.y ) ) * 1.0;
			float2 id19 = 0;
			float2 uv19 = 0;
			float voroi19 = voronoi19( coords19, time19, id19, uv19, 0, voronoiSmoothId19 );
			float4 temp_cast_0 = (voroi19).xxxx;
			float4 blendOpSrc26 = _BaseColor;
			float4 blendOpDest26 = temp_cast_0;
			float4 temp_output_26_0 = ( saturate( (( blendOpSrc26 > 0.5 )? ( blendOpDest26 + 2.0 * blendOpSrc26 - 1.0 ) : ( blendOpDest26 + 2.0 * ( blendOpSrc26 - 0.5 ) ) ) ));
			o.Albedo = temp_output_26_0.rgb;
			o.Emission = temp_output_26_0.rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19102
Node;AmplifyShaderEditor.ColorNode;6;-682.5,-307.4;Inherit;False;Property;_BaseColor;BaseColor;0;0;Create;True;0;0;0;False;0;False;0,0.792293,0.8584906,1;0.647606,0.8014816,0.9339623,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BlendOpsNode;28;-282.9462,181.4081;Inherit;True;ColorDodge;True;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;29;-592.9462,423.4081;Inherit;False;Property;_BaseColor1;BaseColor;1;0;Create;True;0;0;0;False;0;False;0.7735849,0.7735849,0.7735849,1;0,0.792293,0.8584906,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;-282.5,-47;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.BlendOpsNode;26;-280.6733,-280.335;Inherit;True;LinearLight;True;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;333,-295;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;WaterfallAmp;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;2;5;False;;10;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;43;-1134.692,10.76898;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;44;-1358.339,-1.657776;Inherit;False;Constant;_Vector0;Vector 0;2;0;Create;True;0;0;0;False;0;False;5,5;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleAddOpNode;49;-809,65;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;51;-1045.339,222.3422;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.VoronoiNode;19;-562.239,139.6304;Inherit;True;0;0;1;0;1;False;1;False;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;3;FLOAT;0;FLOAT2;1;FLOAT2;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;47;-1030.339,346.3422;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;46;-1205.339,485.3422;Inherit;False;Property;_VoronoiSpeed;VoronoiSpeed;2;0;Create;True;0;0;0;False;0;False;3;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TimeNode;45;-1383.339,300.3422;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;52;-1270.945,156.8126;Inherit;False;Constant;_Vector1;Vector 1;3;0;Create;True;0;0;0;False;0;False;1,5;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
WireConnection;28;0;19;0
WireConnection;28;1;29;0
WireConnection;7;0;6;0
WireConnection;7;1;19;0
WireConnection;26;0;6;0
WireConnection;26;1;19;0
WireConnection;0;0;26;0
WireConnection;0;2;26;0
WireConnection;43;0;44;0
WireConnection;49;0;43;0
WireConnection;49;1;51;0
WireConnection;51;0;52;0
WireConnection;51;1;45;2
WireConnection;19;0;49;0
WireConnection;19;1;47;0
WireConnection;47;0;45;2
WireConnection;47;1;46;0
ASEEND*/
//CHKSM=EBF0DF6EF3CD27AAE61EB2EE39156FF7B1B75EE1