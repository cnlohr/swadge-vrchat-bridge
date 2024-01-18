// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Guitar-Strings"
{
	Properties
	{
		_ScrollSpeed("ScrollSpeed", Float) = 0.5
		_CCIndexMultiplier("CCIndexMultiplier", Int) = 0
		_DefaultColor("DefaultColor", Color) = (1,1,1,0)
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

		uniform float4 _DefaultColor;
		uniform int _CCIndexMultiplier;
		uniform float _ScrollSpeed;


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
			float Position1_g2 = ( i.uv_texcoord.x * _CCIndexMultiplier );
			float4 localAudioLinkLerp1_g2 = AudioLinkLerp1_g2( Position1_g2 );
			float temp_output_8_0_g3 = 0.0;
			float Filter1_g3 = temp_output_8_0_g3;
			float localAudioLinkData1_g3 = AudioLinkData1_g3( Filter1_g3 );
			float4 lerpResult29 = lerp( _DefaultColor , localAudioLinkLerp1_g2 , saturate( ( localAudioLinkData1_g3 * 100.0 ) ));
			Gradient gradient10 = NewGradient( 0, 3, 2, float4( 0.3333333, 0.3333333, 0.3333333, 0 ), float4( 1, 1, 1, 0.9176471 ), float4( 0.3333333, 0.3333333, 0.3333333, 1 ), 0, 0, 0, 0, 0, float2( 1, 0 ), float2( 1, 0.8941177 ), 0, 0, 0, 0, 0, 0 );
			float2 temp_cast_2 = (( ( _Time.y * _ScrollSpeed ) * -1 )).xx;
			float2 uv_TexCoord1 = i.uv_texcoord * float2( 1,1 ) + temp_cast_2;
			float4 blendOpSrc17 = lerpResult29;
			float4 blendOpDest17 = SampleGradient( gradient10, frac( uv_TexCoord1.y ) );
			float4 temp_output_17_0 = ( saturate( ( blendOpSrc17 * blendOpDest17 ) ));
			o.Emission = temp_output_17_0.rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;0,0;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;Guitar-Strings;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;17;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;1;-2594.92,433.4353;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;2;-2810.012,398.4695;Inherit;False;Constant;_Vector0;Vector 0;0;0;Create;True;0;0;0;False;0;False;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.GradientSampleNode;3;-2147.455,241.9215;Inherit;True;2;0;OBJECT;;False;1;FLOAT;0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FractNode;4;-2344.63,403.527;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TimeNode;5;-3384.227,467.9578;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;6;-3420.821,765.8772;Inherit;False;Property;_ScrollSpeed;ScrollSpeed;0;0;Create;True;0;0;0;False;0;False;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;-2825.443,609.4362;Inherit;False;2;2;0;FLOAT;0;False;1;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;8;-3103.777,587.463;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;9;-3062.233,790.1348;Inherit;False;Constant;_Int0;Int 0;3;0;Create;True;0;0;0;False;0;False;-1;0;False;0;1;INT;0
Node;AmplifyShaderEditor.FunctionNode;11;-2257.457,-202.7162;Inherit;False;ColorChordLights;-1;;1;e4ce5853eedcd214da09ba336aadbc9e;0;1;2;INT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;12;-2260.103,-281.2456;Inherit;False;ColorChordStrip;-1;;2;cfa8e3a605f54d2409f0ae5a9706c295;0;1;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;13;-2735.894,-164.8929;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;14;-2451.893,-119.8929;Inherit;False;2;2;0;FLOAT;0;False;1;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;15;-2692.894,-21.89274;Inherit;False;Property;_CCIndexMultiplier;CCIndexMultiplier;7;0;Create;True;0;0;0;False;0;False;0;0;False;0;1;INT;0
Node;AmplifyShaderEditor.ColorNode;16;-2690.842,-488.4982;Inherit;False;Property;_ColorOverlay;ColorOverlay;2;0;Create;True;0;0;0;False;0;False;0,0.6777537,1,1;0,0.6777537,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;18;-766.6336,821.2857;Inherit;False;InstancedProperty;_EmitMultiplier;EmitMultiplier;1;0;Create;True;0;0;0;False;0;False;1;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;19;-481.0988,726.5619;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.BlendOpsNode;20;-781.4595,589.8452;Inherit;False;Multiply;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;22;-520.6968,387.0901;Inherit;True;Property;_AlbedoTransparent;AlbedoTransparent;4;0;Create;True;0;0;0;False;0;False;-1;None;9cb73e05e8232b14bb91d77a07021a7a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;23;-508.0828,932.3004;Inherit;True;Property;_MetallicSmoothness;MetallicSmoothness;6;0;Create;True;0;0;0;False;0;False;-1;None;135c53c174d5f374bbad0bc24c5f6314;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;24;-1223.457,728.2256;Inherit;True;Property;_EmissionOverlay;EmissionOverlay;3;0;Create;True;0;0;0;False;0;False;-1;None;02eab6c5762558048a18a54917381cb5;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;25;-2209.403,-73.62214;Inherit;False;VUFiltered;-1;;3;9e3a3efd07ae5af42820ceacf2214050;0;1;8;FLOAT;0;False;2;FLOAT;0;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;26;-2136.495,61.27122;Inherit;False;Constant;_Float1;Float 1;9;0;Create;True;0;0;0;False;0;False;100;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;27;-1927.13,-53.32788;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;28;-1755.231,-72.06049;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;29;-1566.804,-133.7676;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ColorNode;30;-1856.607,43.64053;Inherit;False;Property;_DefaultColor;DefaultColor;8;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;21;-996.1743,1009.497;Inherit;True;Property;_NormalMap;NormalMap;5;0;Create;True;0;0;0;False;0;False;-1;None;080b04714c36115429aa7e0c4136854a;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BlendOpsNode;17;-1070.92,173.2646;Inherit;True;Multiply;True;3;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.GradientNode;10;-2579.511,281.8515;Inherit;False;0;3;2;0.3333333,0.3333333,0.3333333,0;1,1,1,0.9176471;0.3333333,0.3333333,0.3333333,1;1,0;1,0.8941177;0;1;OBJECT;0
WireConnection;0;2;17;0
WireConnection;1;0;2;0
WireConnection;1;1;7;0
WireConnection;3;0;10;0
WireConnection;3;1;4;0
WireConnection;4;0;1;2
WireConnection;7;0;8;0
WireConnection;7;1;9;0
WireConnection;8;0;5;2
WireConnection;8;1;6;0
WireConnection;12;2;14;0
WireConnection;14;0;13;1
WireConnection;14;1;15;0
WireConnection;19;0;20;0
WireConnection;19;1;18;0
WireConnection;20;0;24;0
WireConnection;20;1;17;0
WireConnection;27;0;25;0
WireConnection;27;1;26;0
WireConnection;28;0;27;0
WireConnection;29;0;30;0
WireConnection;29;1;12;0
WireConnection;29;2;28;0
WireConnection;17;0;29;0
WireConnection;17;1;3;0
ASEEND*/
//CHKSM=841358B7AD15F2EA6E68AB409AE15ADDFFA48A26