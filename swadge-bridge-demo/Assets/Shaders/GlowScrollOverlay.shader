// Upgrade NOTE: upgraded instancing buffer 'GlowScrollOverlay' to new syntax.

// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "GlowScrollOverlay"
{
	Properties
	{
		_ScrollSpeed("ScrollSpeed", Float) = 0.5
		_EmitMultiplier("EmitMultiplier", Float) = 1
		_EmissionOverlay("EmissionOverlay", 2D) = "white" {}
		_AlbedoTransparent("AlbedoTransparent", 2D) = "white" {}
		_NormalMap("NormalMap", 2D) = "white" {}
		_MetallicSmoothness("MetallicSmoothness", 2D) = "white" {}
		_CCIndexMultiplier("CCIndexMultiplier", Int) = 0
		_DefaultColor("DefaultColor", Color) = (1,1,1,0)
		_SmoothnessMult("SmoothnessMult", Range( 0 , 1)) = 0
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
		#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform sampler2D _NormalMap;
		uniform sampler2D _AlbedoTransparent;
		uniform sampler2D _EmissionOverlay;
		uniform float4 _DefaultColor;
		uniform int _CCIndexMultiplier;
		uniform float _ScrollSpeed;
		uniform sampler2D _MetallicSmoothness;
		uniform float _SmoothnessMult;

		UNITY_INSTANCING_BUFFER_START(GlowScrollOverlay)
			UNITY_DEFINE_INSTANCED_PROP(float4, _NormalMap_ST)
#define _NormalMap_ST_arr GlowScrollOverlay
			UNITY_DEFINE_INSTANCED_PROP(float4, _AlbedoTransparent_ST)
#define _AlbedoTransparent_ST_arr GlowScrollOverlay
			UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionOverlay_ST)
#define _EmissionOverlay_ST_arr GlowScrollOverlay
			UNITY_DEFINE_INSTANCED_PROP(float4, _MetallicSmoothness_ST)
#define _MetallicSmoothness_ST_arr GlowScrollOverlay
			UNITY_DEFINE_INSTANCED_PROP(float, _EmitMultiplier)
#define _EmitMultiplier_arr GlowScrollOverlay
		UNITY_INSTANCING_BUFFER_END(GlowScrollOverlay)


		inline float4 AudioLinkLerp1_g2( float Position )
		{
			return AudioLinkLerp( ALPASS_CCSTRIP + float2( Position * 128., 0 ) ).rgba;;
		}


		inline float AudioLinkData1_g3( float Filter )
		{
			return AudioLinkLerp(ALPASS_FILTEREDVU_INTENSITY + int2(Filter, 0)).r;
		}


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
			float4 _NormalMap_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_NormalMap_ST_arr, _NormalMap_ST);
			float2 uv_NormalMap = i.uv_texcoord * _NormalMap_ST_Instance.xy + _NormalMap_ST_Instance.zw;
			o.Normal = tex2D( _NormalMap, uv_NormalMap ).rgb;
			float4 _AlbedoTransparent_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_AlbedoTransparent_ST_arr, _AlbedoTransparent_ST);
			float2 uv_AlbedoTransparent = i.uv_texcoord * _AlbedoTransparent_ST_Instance.xy + _AlbedoTransparent_ST_Instance.zw;
			o.Albedo = tex2D( _AlbedoTransparent, uv_AlbedoTransparent ).rgb;
			float4 _EmissionOverlay_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_EmissionOverlay_ST_arr, _EmissionOverlay_ST);
			float2 uv_EmissionOverlay = i.uv_texcoord * _EmissionOverlay_ST_Instance.xy + _EmissionOverlay_ST_Instance.zw;
			float Position1_g2 = ( i.uv_texcoord.y * _CCIndexMultiplier );
			float4 localAudioLinkLerp1_g2 = AudioLinkLerp1_g2( Position1_g2 );
			float temp_output_8_0_g3 = 0.0;
			float Filter1_g3 = temp_output_8_0_g3;
			float localAudioLinkData1_g3 = AudioLinkData1_g3( Filter1_g3 );
			float4 lerpResult36 = lerp( _DefaultColor , localAudioLinkLerp1_g2 , saturate( ( localAudioLinkData1_g3 * 100.0 ) ));
			Gradient gradient9 = NewGradient( 0, 2, 2, float4( 0, 0, 0, 0.4382391 ), float4( 1, 1, 1, 1 ), 0, 0, 0, 0, 0, 0, float2( 1, 0 ), float2( 1, 1 ), 0, 0, 0, 0, 0, 0 );
			float2 temp_cast_4 = (( ( _Time.y * _ScrollSpeed ) * -1 )).xx;
			float2 uv_TexCoord1 = i.uv_texcoord * float2( 1,1 ) + temp_cast_4;
			float4 blendOpSrc5 = lerpResult36;
			float4 blendOpDest5 = SampleGradient( gradient9, frac( uv_TexCoord1.y ) );
			float4 blendOpSrc17 = tex2D( _EmissionOverlay, uv_EmissionOverlay );
			float4 blendOpDest17 = ( saturate( ( blendOpSrc5 * blendOpDest5 ) ));
			float _EmitMultiplier_Instance = UNITY_ACCESS_INSTANCED_PROP(_EmitMultiplier_arr, _EmitMultiplier);
			o.Emission = ( ( saturate( ( blendOpSrc17 * blendOpDest17 ) )) * _EmitMultiplier_Instance ).rgb;
			float4 _MetallicSmoothness_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_MetallicSmoothness_ST_arr, _MetallicSmoothness_ST);
			float2 uv_MetallicSmoothness = i.uv_texcoord * _MetallicSmoothness_ST_Instance.xy + _MetallicSmoothness_ST_Instance.zw;
			float4 tex2DNode24 = tex2D( _MetallicSmoothness, uv_MetallicSmoothness );
			o.Metallic = tex2DNode24.r;
			o.Smoothness = ( tex2DNode24.b * _SmoothnessMult );
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.TextureCoordinatesNode;1;-665.0813,-49.65099;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;2;-880.1734,-84.61676;Inherit;False;Constant;_Vector0;Vector 0;0;0;Create;True;0;0;0;False;0;False;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.GradientSampleNode;3;-217.6164,-241.1648;Inherit;True;2;0;OBJECT;;False;1;FLOAT;0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FractNode;4;-414.7915,-79.55923;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TimeNode;10;-1454.388,-15.12849;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;11;-1490.982,282.7911;Inherit;False;Property;_ScrollSpeed;ScrollSpeed;0;0;Create;True;0;0;0;False;0;False;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;12;-895.6049,126.35;Inherit;False;2;2;0;FLOAT;0;False;1;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;13;-1173.938,104.3769;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;14;-1132.394,307.0486;Inherit;False;Constant;_Int0;Int 0;3;0;Create;True;0;0;0;False;0;False;-1;0;False;0;1;INT;0
Node;AmplifyShaderEditor.GradientNode;9;-649.6721,-201.2348;Inherit;False;0;2;2;0,0,0,0.4382391;1,1,1,1;1,0;1,1;0;1;OBJECT;0
Node;AmplifyShaderEditor.FunctionNode;25;-327.618,-685.8024;Inherit;False;ColorChordLights;-1;;1;e4ce5853eedcd214da09ba336aadbc9e;0;1;2;INT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;26;-330.2644,-764.3318;Inherit;False;ColorChordStrip;-1;;2;cfa8e3a605f54d2409f0ae5a9706c295;0;1;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;27;-806.0549,-647.9791;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;-522.0547,-602.9791;Inherit;False;2;2;0;FLOAT;0;False;1;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;30;-763.0549,-504.979;Inherit;False;Property;_CCIndexMultiplier;CCIndexMultiplier;7;0;Create;True;0;0;0;False;0;False;0;0;False;0;1;INT;0
Node;AmplifyShaderEditor.ColorNode;7;-761.0037,-971.5845;Inherit;False;Property;_ColorOverlay;ColorOverlay;2;0;Create;True;0;0;0;False;0;False;0,0.6777537,1,1;0,0.6777537,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BlendOpsNode;5;812.4539,-143.6205;Inherit;True;Multiply;True;3;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;8;1163.205,338.1996;Inherit;False;InstancedProperty;_EmitMultiplier;EmitMultiplier;1;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;6;1448.74,243.4758;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.BlendOpsNode;17;1148.379,106.7591;Inherit;False;Multiply;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1889.519,67.01131;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;GlowScrollOverlay;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;17;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.SamplerNode;23;981.6644,446.4109;Inherit;True;Property;_NormalMap;NormalMap;5;0;Create;True;0;0;0;False;0;False;-1;None;18010d0a04811244a8ec65b26b2388a8;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;22;1409.142,-95.99623;Inherit;True;Property;_AlbedoTransparent;AlbedoTransparent;4;0;Create;True;0;0;0;False;0;False;-1;None;7a9902e2db07d8c40827394000e192e8;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;15;706.3818,245.1395;Inherit;True;Property;_EmissionOverlay;EmissionOverlay;3;0;Create;True;0;0;0;False;0;False;-1;None;e2bf69ef966cc064c87ea488209c8ed3;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;31;-279.5645,-556.7084;Inherit;False;VUFiltered;-1;;3;9e3a3efd07ae5af42820ceacf2214050;0;1;8;FLOAT;0;False;2;FLOAT;0;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;32;-206.6566,-421.815;Inherit;False;Constant;_Float1;Float 1;9;0;Create;True;0;0;0;False;0;False;100;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;33;2.708467,-536.4141;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;35;174.6075,-555.1467;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;36;363.0343,-616.8538;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ColorNode;34;73.23161,-439.4457;Inherit;False;Property;_DefaultColor;DefaultColor;8;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;24;1152.537,702.1872;Inherit;True;Property;_MetallicSmoothness;MetallicSmoothness;6;0;Create;True;0;0;0;False;0;False;-1;None;8ef75e5769c0be74e9c432137594efd2;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;38;1563.331,758.9549;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;37;1368.379,917.9331;Inherit;False;Property;_SmoothnessMult;SmoothnessMult;9;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
WireConnection;1;0;2;0
WireConnection;1;1;12;0
WireConnection;3;0;9;0
WireConnection;3;1;4;0
WireConnection;4;0;1;2
WireConnection;12;0;13;0
WireConnection;12;1;14;0
WireConnection;13;0;10;2
WireConnection;13;1;11;0
WireConnection;26;2;28;0
WireConnection;28;0;27;2
WireConnection;28;1;30;0
WireConnection;5;0;36;0
WireConnection;5;1;3;0
WireConnection;6;0;17;0
WireConnection;6;1;8;0
WireConnection;17;0;15;0
WireConnection;17;1;5;0
WireConnection;0;0;22;0
WireConnection;0;1;23;0
WireConnection;0;2;6;0
WireConnection;0;3;24;1
WireConnection;0;4;38;0
WireConnection;33;0;31;0
WireConnection;33;1;32;0
WireConnection;35;0;33;0
WireConnection;36;0;34;0
WireConnection;36;1;26;0
WireConnection;36;2;35;0
WireConnection;38;0;24;3
WireConnection;38;1;37;0
ASEEND*/
//CHKSM=A8BBA51149FD142DF6D2A3DD9145D0FCA4F5B14D