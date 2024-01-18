Shader "Unlit/StreamBoxAvMod"
{
	Properties
	{
		_ScreenTex("ScreenTex", 2D) = "black" {}
		_ShellTex("ShellTex", 2D) = "white" {}
		_MaskTex("Mask (R=Logo)", 2D) = "black" {}
		_LogoTex("Logo (RGB)", 2D) = "black" {}
		_LogoBlendColor("Logo Blend Color", Color) = (0,0,0,0)
		[Enum(Off, 0, On, 1)] _CullMainCamera("Cull Main Camera", Float) = 0
		[Enum(Off, 0, On, 1)] _CullPlayerCamera("Cull Player Camera", Float) = 0
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque"  "Queue" = "Transparent+1999" "IgnoreProjector" = "True" "IsEmissive" = "true" "ForceNoShadowCasting" = "true" }

		Pass
		{
			Cull Front
			ZTest Always
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
		// make fog work
		#pragma multi_compile_fog

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
			float2 uv2 : TEXCOORD2;
		};

		sampler2D _ScreenTex;
		float4 _ScreenTex_ST;
		sampler2D _ShellTex;
		float4 _ShellTex_ST;
		sampler2D _MaskTex;
		sampler2D _LogoTex;
		float4 _LogoTex_ST;
		uniform float4 _LogoBlendColor;

		float _CullMainCamera;
		float _CullPlayerCamera;

		float _VRChatCameraMode;

		v2f vert(appdata v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv = TRANSFORM_TEX(v.uv, _ShellTex);
			o.uv2 = TRANSFORM_TEX(v.uv, _LogoTex);

			UNITY_TRANSFER_FOG(o,o.vertex);

			if (_CullMainCamera) {
				if (_VRChatCameraMode == 0 || _VRChatCameraMode == 3)
					o.vertex = float4(0, 0, 0, 0);
			}
			if (_CullPlayerCamera) {
				if (_VRChatCameraMode == 1 || _VRChatCameraMode == 2)
					o.vertex = float4(0, 0, 0, 0);
			}

			return o;
		}

		fixed4 frag(v2f i, uint face : SV_IsFrontFace) : SV_Target
		{
			float2 grabScreenPosNorm = i.vertex.xy / _ScreenParams.xy;
			
			if (face > 0)
				return tex2D(_ShellTex, i.uv);
			
			half4 tex = tex2D(_ScreenTex, grabScreenPosNorm.xy);
			half4 mask = tex2D(_MaskTex, grabScreenPosNorm.xy);

			fixed4 black = fixed4(0, 0, 0, 0);
			half4 logoTex = tex2D(_LogoTex, grabScreenPosNorm.xy);
			logoTex = lerp(_LogoBlendColor.rgba, logoTex.rgba, logoTex.a);
			logoTex = lerp(black.rgba, logoTex.rgba, mask.r);

			fixed4 c = tex;
			c.rgb = lerp(c.rgb, logoTex.rgb, logoTex.a);

			return c;
		}
		ENDCG
	}


	Pass
	{
		Cull Off
		ZTest LEqual
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

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
				float2 uv2 : TEXCOORD2;
			};

			sampler2D _ScreenTex;
			float4 _ScreenTex_ST;
			sampler2D _ShellTex;
			float4 _ShellTex_ST;
			sampler2D _MaskTex;
			sampler2D _LogoTex;
			float4 _LogoTex_ST;
			uniform float4 _LogoBlendColor;

			float _VRChatCameraMode;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _ShellTex);
				o.uv2 = TRANSFORM_TEX(v.uv, _LogoTex);
				UNITY_TRANSFER_FOG(o,o.vertex);

				//if (_VRChatCameraMode == 1 || _VRChatCameraMode == 2)
				//	o.vertex = float4(0, 0, 0, 0);

				return o;
			}

			fixed4 frag(v2f i, uint face : SV_IsFrontFace) : SV_Target
			{
				float2 grabScreenPosNorm = i.vertex.xy / _ScreenParams.xy;
				if (face > 0)
					return tex2D(_ShellTex, i.uv);

				half4 tex = tex2D(_ScreenTex, grabScreenPosNorm.xy);
				half4 mask = tex2D(_MaskTex, grabScreenPosNorm.xy);

				fixed4 black = fixed4(0, 0, 0, 0);
				half4 logoTex = tex2D(_LogoTex, grabScreenPosNorm.xy);
				logoTex = lerp(_LogoBlendColor.rgba, logoTex.rgba, logoTex.a);
				logoTex = lerp(black.rgba, logoTex.rgba, mask.r);
				

				fixed4 c = tex;
				c.rgb = lerp(c.rgb, logoTex.rgb, logoTex.a);

				return c;
			}
			ENDCG
		}
	}
}
