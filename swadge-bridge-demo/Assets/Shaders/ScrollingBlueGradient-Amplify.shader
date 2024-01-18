// Upgrade NOTE: upgraded instancing buffer 'ScrollingBlueGradientAmplify' to new syntax.

// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ScrollingBlueGradient-Amplify"
{
	Properties
	{
		_ScrollSpeed("ScrollSpeed", Float) = 0.5
		_EmitMultiplier("EmitMultiplier", Float) = 1
		_ColorOverlay("ColorOverlay", Color) = (0,0.6777537,1,1)
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
		#pragma multi_compile_instancing
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform float4 _ColorOverlay;
		uniform float _ScrollSpeed;

		UNITY_INSTANCING_BUFFER_START(ScrollingBlueGradientAmplify)
			UNITY_DEFINE_INSTANCED_PROP(float, _EmitMultiplier)
#define _EmitMultiplier_arr ScrollingBlueGradientAmplify
		UNITY_INSTANCING_BUFFER_END(ScrollingBlueGradientAmplify)


		struct Gradient
		{
			int type;
			int colorsLength;
			int alphasLength;
			float4 colors[8];
			float2 alphas[8];
		};


		Gradient NewGradient(int type, int colorsLength, int alphasLength, 
		float4 colors0, float4 colors1, float4 colors2, float4 colors3, float4 colors4, float4 colors5, float4 colors6, float4 colors7,
		float2 alphas0, float2 alphas1, float2 alphas2, float2 alphas3, float2 alphas4, float2 alphas5, float2 alphas6, float2 alphas7)
		{
			Gradient g;
			g.type = type;
			g.colorsLength = colorsLength;
			g.alphasLength = alphasLength;
			g.colors[ 0 ] = colors0;
			g.colors[ 1 ] = colors1;
			g.colors[ 2 ] = colors2;
			g.colors[ 3 ] = colors3;
			g.colors[ 4 ] = colors4;
			g.colors[ 5 ] = colors5;
			g.colors[ 6 ] = colors6;
			g.colors[ 7 ] = colors7;
			g.alphas[ 0 ] = alphas0;
			g.alphas[ 1 ] = alphas1;
			g.alphas[ 2 ] = alphas2;
			g.alphas[ 3 ] = alphas3;
			g.alphas[ 4 ] = alphas4;
			g.alphas[ 5 ] = alphas5;
			g.alphas[ 6 ] = alphas6;
			g.alphas[ 7 ] = alphas7;
			return g;
		}


		float4 SampleGradient( Gradient gradient, float time )
		{
			float3 color = gradient.colors[0].rgb;
			UNITY_UNROLL
			for (int c = 1; c < 8; c++)
			{
			float colorPos = saturate((time - gradient.colors[c-1].w) / ( 0.00001 + (gradient.colors[c].w - gradient.colors[c-1].w)) * step(c, (float)gradient.colorsLength-1));
			color = lerp(color, gradient.colors[c].rgb, lerp(colorPos, step(0.01, colorPos), gradient.type));
			}
			#ifndef UNITY_COLORSPACE_GAMMA
			color = half3(GammaToLinearSpaceExact(color.r), GammaToLinearSpaceExact(color.g), GammaToLinearSpaceExact(color.b));
			#endif
			float alpha = gradient.alphas[0].x;
			UNITY_UNROLL
			for (int a = 1; a < 8; a++)
			{
			float alphaPos = saturate((time - gradient.alphas[a-1].y) / ( 0.00001 + (gradient.alphas[a].y - gradient.alphas[a-1].y)) * step(a, (float)gradient.alphasLength-1));
			alpha = lerp(alpha, gradient.alphas[a].x, lerp(alphaPos, step(0.01, alphaPos), gradient.type));
			}
			return float4(color, alpha);
		}


		void surf( Input i , inout SurfaceOutputStandard o )
		{
			Gradient gradient1 = NewGradient( 0, 2, 2, float4( 0, 0, 0, 0.4382391 ), float4( 1, 1, 1, 1 ), 0, 0, 0, 0, 0, 0, float2( 1, 0 ), float2( 1, 1 ), 0, 0, 0, 0, 0, 0 );
			float2 temp_cast_0 = (( ( _Time.y * _ScrollSpeed ) * -1 )).xx;
			float2 uv_TexCoord3 = i.uv_texcoord * float2( 1,1 ) + temp_cast_0;
			float4 blendOpSrc23 = _ColorOverlay;
			float4 blendOpDest23 = SampleGradient( gradient1, frac( uv_TexCoord3.y ) );
			float4 temp_output_23_0 = ( saturate( ( blendOpSrc23 * blendOpDest23 ) ));
			o.Albedo = temp_output_23_0.rgb;
			float _EmitMultiplier_Instance = UNITY_ACCESS_INSTANCED_PROP(_EmitMultiplier_arr, _EmitMultiplier);
			o.Emission = ( temp_output_23_0 * _EmitMultiplier_Instance ).rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.TextureCoordinatesNode;3;-709.6138,47.59257;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;4;-924.7059,12.62683;Inherit;False;Constant;_Vector0;Vector 0;0;0;Create;True;0;0;0;False;0;False;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.GradientSampleNode;2;-262.1489,-143.9211;Inherit;True;2;0;OBJECT;;False;1;FLOAT;0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FractNode;13;-459.324,17.68435;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;714.3624,-150.2104;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;ScrollingBlueGradient-Amplify;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;17;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.BlendOpsNode;23;129.0427,-192.028;Inherit;False;Multiply;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;18;456.4885,2.123312;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;22;-120.3343,-371.7135;Inherit;False;Property;_ColorOverlay;ColorOverlay;2;0;Create;True;0;0;0;False;0;False;0,0.6777537,1,1;0,0.6777537,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;19;242.8188,86.21259;Inherit;False;InstancedProperty;_EmitMultiplier;EmitMultiplier;1;0;Create;True;0;0;0;False;0;False;1;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GradientNode;1;-643.2046,-149.9912;Inherit;False;0;2;2;0,0,0,0.4382391;1,1,1,1;1,0;1,1;0;1;OBJECT;0
Node;AmplifyShaderEditor.TimeNode;14;-1498.921,82.11508;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;21;-1535.515,380.0347;Inherit;False;Property;_ScrollSpeed;ScrollSpeed;0;0;Create;True;0;0;0;False;0;False;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;24;-940.1375,223.5936;Inherit;False;2;2;0;FLOAT;0;False;1;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-1218.471,201.6205;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;26;-1176.927,404.2922;Inherit;False;Constant;_Int0;Int 0;3;0;Create;True;0;0;0;False;0;False;-1;0;False;0;1;INT;0
WireConnection;3;0;4;0
WireConnection;3;1;24;0
WireConnection;2;0;1;0
WireConnection;2;1;13;0
WireConnection;13;0;3;2
WireConnection;0;0;23;0
WireConnection;0;2;18;0
WireConnection;23;0;22;0
WireConnection;23;1;2;0
WireConnection;18;0;23;0
WireConnection;18;1;19;0
WireConnection;24;0;20;0
WireConnection;24;1;26;0
WireConnection;20;0;14;2
WireConnection;20;1;21;0
ASEEND*/
//CHKSM=B462E5505D49EB263FF71F1A46BCEE115CA12633