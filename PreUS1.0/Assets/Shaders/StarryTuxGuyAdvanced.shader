Shader "Custom/StarryTuxGuyAdvanced"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _FunctionTex ("Function", 2D) = "white" {}
        _NormalTex ("Normal", 2D) = "white" {}
        _DiffuseTex ("Diffuse", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        // shadow caster rendering pass, implemented manually
        // using macros from UnityCG.cginc
        Pass
        {
            Tags {"LightMode"="ShadowCaster"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f { 
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }


		Tags { "RenderQueue"="AlphaTest" "RenderType"="TransparentCutout" }
		AlphaToMask On
		
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert keepalpha

        #pragma target 4.0

		#include "/Assets/AudioLink/Shaders/AudioLink.cginc"

        sampler2D _FunctionTex;
        sampler2D _NormalTex;
        sampler2D _DiffuseTex;
		float4 _FunctionTex_TexelSize;
		float4 _NormalTex_TexelSize;
		float4 _DiffuseTex_TexelSize;


        struct Input
        {
            float4 screenPos:SV_POSITION;
            float2 uv_FunctionTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

 
		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);
			o.screenPos = ComputeScreenPos( UnityObjectToClipPos( v.vertex ) );
		}
 
        void surf (Input IN, inout SurfaceOutputStandard o )
        {
            // Albedo comes from a texture tinted by color
			fixed4 diffuse = tex2D (_DiffuseTex, IN.uv_FunctionTex);
            fixed4 function = tex2D (_FunctionTex, IN.uv_FunctionTex);
			fixed4 normal = tex2D (_NormalTex, IN.uv_FunctionTex);
			fixed4 normnorm = pow( normal, 0.5 );
			diffuse *= _Color;

            o.Metallic = _Metallic;

            o.Albedo = diffuse.rgb;

			if( length( function.xyz ) > 1.7 )
			{
				// Shiny.
				o.Normal = normal;
				o.Metallic = 1.;
				o.Albedo = .1;
			}
			else if( function.b > function.r && function.b > function.g && function.b > 0.5 )
			{
				//Emissive.
				o.Emission = diffuse;
				o.Albedo = diffuse;
			}
			else if( function.b > function.r && function.b > function.g && function.b > 0.1 )
			{
				float4 ALI = AudioLinkData( ALPASS_CCINTERNAL + int2( 1, 0 ) );
				o.Emission = AudioLinkCCtoRGB( ALI.x, 1., ALI.y/25. );
				o.Albedo = diffuse;
			}
			else if( function.r > function.g && function.r > 0.5)
			{
				// ColorChord, Linear
				o.Emission = AudioLinkLerp( ALPASS_CCSTRIP + float2( normnorm.x * 128, 0 ) );
				o.Albedo = diffuse;
			}
			else if( function.g > function.r && function.g > 0.5 )
			{
				// AudioLink, Scan
				o.Emission = AudioLinkLerp( ALPASS_AUDIOLINK + float2( normnorm.x * 128, normnorm.y * 3.9 ) );
				o.Albedo = diffuse;
			}
			
            // Metallic and smoothness come from slider variables
            o.Smoothness = _Glossiness;
            o.Alpha = diffuse.a;

        }
        ENDCG
    }
    FallBack "Diffuse"
}
