// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "HologramTrees"
{
	Properties
	{
		_Hologramcolor("Hologram color", Color) = (0.3973832,0.7720588,0.7410512,0)
		_Speed("Speed", Range( 0 , 100)) = 26
		_ScanLines("Scan Lines", Range( 0 , 10)) = 3
		_RimNormalMap("Rim Normal Map", 2D) = "bump" {}
		_RimPower("Rim Power", Range( 0 , 10)) = 5
		_Intensity("Intensity", Range( 1 , 10)) = 1
		_TextureSample0("Texture Sample 0", 2D) = "white" {}
		_CCIndex("CCIndex", Int) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldPos;
			float2 uv_texcoord;
			float3 viewDir;
			INTERNAL_DATA
		};

		uniform float4 _Hologramcolor;
		uniform float _ScanLines;
		uniform float _Speed;
		uniform sampler2D _RimNormalMap;
		uniform float _RimPower;
		uniform float _Intensity;
		uniform int _CCIndex;
		uniform sampler2D _TextureSample0;
		uniform float4 _TextureSample0_ST;


		float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }

		float snoise( float2 v )
		{
			const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
			float2 i = floor( v + dot( v, C.yy ) );
			float2 x0 = v - i + dot( i, C.xx );
			float2 i1;
			i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
			float4 x12 = x0.xyxy + C.xxzz;
			x12.xy -= i1;
			i = mod2D289( i );
			float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
			float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
			m = m * m;
			m = m * m;
			float3 x = 2.0 * frac( p * C.www ) - 1.0;
			float3 h = abs( x ) - 0.5;
			float3 ox = floor( x + 0.5 );
			float3 a0 = x - ox;
			m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
			float3 g;
			g.x = a0.x * x0.x + h.x * x0.y;
			g.yz = a0.yz * x12.xz + h.yz * x12.yw;
			return 130.0 * dot( m, g );
		}


		inline float4 AudioLinkLerp1_g3( float Position )
		{
			return AudioLinkLerp( ALPASS_CCSTRIP + float2( Position * 128., 0 ) ).rgba;;
		}


		inline float AudioLinkData1_g2( float Filter )
		{
			return AudioLinkLerp(ALPASS_FILTEREDVU_INTENSITY + int2(Filter, 0)).r;
		}


		void surf( Input i , inout SurfaceOutputStandard o )
		{
			o.Normal = float3(0,0,1);
			float4 HologramColor51 = _Hologramcolor;
			float3 ase_worldPos = i.worldPos;
			float Speed4 = _Speed;
			float temp_output_27_0 = sin( ( ( ( _ScanLines * ase_worldPos.y ) + (( 1.0 - ( Speed4 * _Time ) )).x ) * UNITY_PI ) );
			float clampResult38 = clamp( (0.0 + (temp_output_27_0 - -1.0) * (1.0 - 0.0) / (1.0 - -1.0)) , 0.0 , 1.0 );
			float4 lerpResult42 = lerp( float4(1,1,1,0) , float4(0,0,0,0) , clampResult38);
			float2 temp_cast_0 = (( ( ase_worldPos.z / 100.0 ) * _Time.x )).xx;
			float simplePerlin2D31 = snoise( temp_cast_0 );
			float myVarName340 = ( simplePerlin2D31 * temp_output_27_0 );
			float4 temp_cast_1 = (myVarName340).xxxx;
			float4 ScanLines48 = ( lerpResult42 - temp_cast_1 );
			float3 normalizeResult30 = normalize( i.viewDir );
			float dotResult33 = dot( UnpackNormal( tex2D( _RimNormalMap, ( ( ( Speed4 / 1000.0 ) * _Time ) + float4( i.uv_texcoord, 0.0 , 0.0 ) ).xy ) ) , normalizeResult30 );
			float temp_output_45_0 = pow( ( 1.0 - saturate( dotResult33 ) ) , ( 10.0 - _RimPower ) );
			float Rim47 = temp_output_45_0;
			float4 color75 = IsGammaSpace() ? float4(1,1,1,0) : float4(1,1,1,0);
			float Position1_g3 = ( i.uv_texcoord.y * _CCIndex );
			float4 localAudioLinkLerp1_g3 = AudioLinkLerp1_g3( Position1_g3 );
			float temp_output_8_0_g2 = 0.0;
			float Filter1_g2 = temp_output_8_0_g2;
			float localAudioLinkData1_g2 = AudioLinkData1_g2( Filter1_g2 );
			float4 lerpResult74 = lerp( color75 , localAudioLinkLerp1_g3 , saturate( ( localAudioLinkData1_g2 * 100.0 ) ));
			float4 blendOpSrc65 = ( ( HologramColor51 * ( ScanLines48 + Rim47 ) ) * _Intensity );
			float4 blendOpDest65 = lerpResult74;
			o.Emission = ( saturate( (( blendOpDest65 > 0.5 ) ? ( 1.0 - 2.0 * ( 1.0 - blendOpDest65 ) * ( 1.0 - blendOpSrc65 ) ) : ( 2.0 * blendOpDest65 * blendOpSrc65 ) ) )).xyz;
			float2 uv_TextureSample0 = i.uv_texcoord * _TextureSample0_ST.xy + _TextureSample0_ST.zw;
			o.Alpha = ( tex2D( _TextureSample0, uv_TextureSample0 ).a * 0.2 );
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard alpha:fade keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.viewDir = IN.tSpace0.xyz * worldViewDir.x + IN.tSpace1.xyz * worldViewDir.y + IN.tSpace2.xyz * worldViewDir.z;
				surfIN.worldPos = worldPos;
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D( _DitherMaskLOD, float3( vpos.xy * 0.25, o.Alpha * 0.9375 ) ).a;
				clip( alphaRef - 0.01 );
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.CommentaryNode;1;-29.58289,-874.4673;Inherit;False;614.0698;167.2261;Comment;2;4;2;Speed;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;2;20.41711,-822.2412;Float;False;Property;_Speed;Speed;1;0;Create;True;0;0;0;False;0;False;26;48.5;0;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;3;-1502.391,128.9574;Inherit;False;2377.06;920.5361;Comment;26;48;44;42;40;39;38;35;34;32;31;28;27;24;23;22;21;19;17;16;15;12;10;9;7;6;5;Scan Lines;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;4;350.4872,-824.4673;Float;False;Speed;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TimeNode;5;-1452.391,847.4943;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;6;-1448.118,743.6943;Inherit;False;4;Speed;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;-1224.353,809.6703;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CommentaryNode;8;-1477.382,-556.6166;Inherit;False;2344.672;617.4507;Comment;18;53;52;47;45;43;41;37;36;33;30;29;26;25;20;18;14;13;11;Rim;1,1,1,1;0;0
Node;AmplifyShaderEditor.OneMinusNode;9;-1066.256,780.1843;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;10;-1238.691,530.5699;Float;False;Property;_ScanLines;Scan Lines;2;0;Create;True;0;0;0;False;0;False;3;6.46;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;11;-1427.382,-506.6166;Inherit;False;4;Speed;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;12;-1209.184,623.9163;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;13;-1175.664,-476.189;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1000;False;1;FLOAT;0
Node;AmplifyShaderEditor.TimeNode;14;-1423.819,-397.7775;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;15;-855.8159,667.2612;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;6.06;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;16;-889.5728,783.6403;Inherit;False;True;False;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;17;-1064.808,178.9574;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TextureCoordinatesNode;18;-1218.731,-180.4595;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PiNode;19;-648.3218,779.2513;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-1044.826,-422.7033;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;21;-663.1548,648.4833;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;22;-457.1438,651.9343;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;23;-817.2439,231.1059;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;100;False;1;FLOAT;0
Node;AmplifyShaderEditor.TimeNode;24;-1152.297,323.7923;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;25;-663.5879,-237.2424;Float;False;Tangent;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;26;-874.2849,-408.2758;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SinOpNode;27;-302.6309,736.1853;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;-722.7278,377.0116;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;30;-509.5559,-210.1547;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;31;-518.8049,336.6563;Inherit;False;Simplex2D;False;False;2;0;FLOAT2;100,100;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;32;-93.96484,696.6033;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-1;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;34;-87.36682,328.1902;Float;False;Constant;_Color0;Color 0;2;0;Create;True;0;0;0;False;0;False;1,1,1,0;0,0,0,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;35;-265.6989,450.8042;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;36;-142.1908,-276.5427;Inherit;False;1;0;FLOAT;1.23;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;37;-613.0188,-77.64594;Float;False;Property;_RimPower;Rim Power;5;0;Create;True;0;0;0;False;0;False;5;9.8;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;38;99.98218,686.5613;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;39;-89.26587,502.9178;Float;False;Constant;_Color1;Color 1;2;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;40;-111.0748,234.1883;Float;False;myVarName3;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;41;26.81421,-234.2433;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;42;292.1501,515.4827;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;43;-197.1808,-148.9352;Inherit;False;2;0;FLOAT;10;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;44;477.3531,447.8911;Inherit;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.PowerNode;45;219.6122,-210.8428;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;46;-736.3889,-922.7424;Inherit;False;590.8936;257.7873;Comment;2;51;49;Hologram Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;47;633.2897,-194.6886;Float;False;Rim;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;48;640.6683,464.6665;Float;False;ScanLines;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;49;-686.3889,-872.7424;Float;False;Property;_Hologramcolor;Hologram color;0;0;Create;True;0;0;0;False;0;False;0.3973832,0.7720588,0.7410512,0;0,0.735849,0.4203839,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;50;768.2206,-758.7651;Inherit;False;47;Rim;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;51;-418.4558,-833.5981;Float;False;HologramColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;52;462.0122,-195.6432;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;53;176.5892,-54.16583;Inherit;False;51;HologramColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;54;1402.251,-725.9482;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;57;1242.703,-833.5366;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;58;1021.335,-880.8438;Inherit;False;51;HologramColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;60;1226.593,-180.3783;Inherit;False;Constant;_Float0;Float 0;8;0;Create;True;0;0;0;False;0;False;0.2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;61;703.5823,-947.0046;Inherit;False;48;ScanLines;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;62;1024.641,-772.118;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;29;-682.9709,-461.2348;Inherit;True;Property;_RimNormalMap;Rim Normal Map;4;0;Create;True;0;0;0;False;0;False;-1;None;8f66c1c8460e4419a467d27f526fad23;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DotProductOpNode;33;-330.4618,-333.0966;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;63;995.911,-654.0975;Float;False;Property;_Intensity;Intensity;6;0;Create;True;0;0;0;False;0;False;1;1.880435;1;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;55;934.21,-320.0696;Inherit;True;Property;_TextureSample0;Texture Sample 0;7;0;Create;True;0;0;0;False;0;False;-1;None;85da564d8252f4f4f9ef8e0834e994dc;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;56;1426.593,-349.3784;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;2740.148,-748.7607;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;HologramTrees;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Transparent;0.5;True;True;0;False;Transparent;;Transparent;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;2;5;False;;10;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;17;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.BlendOpsNode;65;2409.951,-698.6459;Inherit;True;Overlay;True;3;0;COLOR;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;1;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;64;1425.948,-570.1274;Inherit;False;ColorChordLights;-1;;1;e4ce5853eedcd214da09ba336aadbc9e;0;1;2;INT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;67;980.5275,-568.0112;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;68;1229.528,-536.0111;Inherit;False;2;2;0;FLOAT;0;False;1;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;66;1042.203,-442.1353;Inherit;False;Property;_CCIndex;CCIndex;8;0;Create;True;0;0;0;False;0;False;1;5;False;0;1;INT;0
Node;AmplifyShaderEditor.RangedFloatNode;59;1369.974,-439.4714;Float;False;Property;_Opacity;Opacity;3;0;Create;True;0;0;0;False;0;False;0.5;0.081;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;70;1480.566,-191.3605;Inherit;False;VUFiltered;-1;;2;9e3a3efd07ae5af42820ceacf2214050;0;1;8;FLOAT;0;False;2;FLOAT;0;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;73;1553.474,-56.46701;Inherit;False;Constant;_Float1;Float 1;9;0;Create;True;0;0;0;False;0;False;100;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;72;1762.839,-171.0661;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;75;1833.362,-74.0977;Inherit;False;Constant;_Color2;Color 2;9;0;Create;True;0;0;0;False;0;False;1,1,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;71;1934.738,-189.7987;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;74;2123.165,-251.5058;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;76;1768.545,-596.2789;Inherit;False;ColorChordStrip;-1;;3;cfa8e3a605f54d2409f0ae5a9706c295;0;1;2;FLOAT;0;False;1;FLOAT4;0
WireConnection;4;0;2;0
WireConnection;7;0;6;0
WireConnection;7;1;5;0
WireConnection;9;0;7;0
WireConnection;13;0;11;0
WireConnection;15;0;10;0
WireConnection;15;1;12;2
WireConnection;16;0;9;0
WireConnection;20;0;13;0
WireConnection;20;1;14;0
WireConnection;21;0;15;0
WireConnection;21;1;16;0
WireConnection;22;0;21;0
WireConnection;22;1;19;0
WireConnection;23;0;17;3
WireConnection;26;0;20;0
WireConnection;26;1;18;0
WireConnection;27;0;22;0
WireConnection;28;0;23;0
WireConnection;28;1;24;1
WireConnection;30;0;25;0
WireConnection;31;0;28;0
WireConnection;32;0;27;0
WireConnection;35;0;31;0
WireConnection;35;1;27;0
WireConnection;36;0;33;0
WireConnection;38;0;32;0
WireConnection;40;0;35;0
WireConnection;41;0;36;0
WireConnection;42;0;34;0
WireConnection;42;1;39;0
WireConnection;42;2;38;0
WireConnection;43;1;37;0
WireConnection;44;0;42;0
WireConnection;44;1;40;0
WireConnection;45;0;41;0
WireConnection;45;1;43;0
WireConnection;47;0;45;0
WireConnection;48;0;44;0
WireConnection;51;0;49;0
WireConnection;52;0;45;0
WireConnection;52;1;53;0
WireConnection;54;0;57;0
WireConnection;54;1;63;0
WireConnection;57;0;58;0
WireConnection;57;1;62;0
WireConnection;62;0;61;0
WireConnection;62;1;50;0
WireConnection;29;1;26;0
WireConnection;33;0;29;0
WireConnection;33;1;30;0
WireConnection;56;0;55;4
WireConnection;56;1;60;0
WireConnection;0;2;65;0
WireConnection;0;9;56;0
WireConnection;65;0;54;0
WireConnection;65;1;74;0
WireConnection;68;0;67;2
WireConnection;68;1;66;0
WireConnection;72;0;70;0
WireConnection;72;1;73;0
WireConnection;71;0;72;0
WireConnection;74;0;75;0
WireConnection;74;1;76;0
WireConnection;74;2;71;0
WireConnection;76;2;68;0
ASEEND*/
//CHKSM=A53A3D32FFAB1600A5AD95942297C307EC628034