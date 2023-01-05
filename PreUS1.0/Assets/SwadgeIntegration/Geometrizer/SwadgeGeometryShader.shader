Shader "Unlit/SwadgeGeometryShader"
{
	Properties
	{
		_BananaTex ("Banana Texture", 2D) = "white" {}
		_ShipTex ("Ship Texture", 2D) = "white" {}
		_GeometryTex ("Data", 2D) = "white" {}
		[HDR] _ColorAmbient ("Color Ambient", Color) = (0.1, 0.1, 0.1, 1)
		_Norminess ("Skylight Norminess", float) = 1 
		[HDR] _SkyLight ("Sky Light Contribution", Color) = (0.2, 0.2, 0.2, 1 )
		[ToggleUI] _ForceDisplay ("Force Display", float ) = 0
	}
	SubShader
	{
	
		Tags { "RenderType"="Opaque" }
		LOD 100
		Cull Off
	
		CGINCLUDE
		#pragma vertex vert
		#pragma geometry geo
		// make fog work
		#pragma multi_compile_fog
		#pragma target 5.0

		#include "UnityCG.cginc"
		
		//https://github.com/cnlohr/shadertrixx/blob/main/Assets/cnlohr/Shaders/hashwithoutsine/hashwithoutsine.cginc
		float3 chash33(float3 p3)
		{
			p3 = frac(p3 * float3(.1031, .1030, .0973));
			p3 += dot(p3, p3.yxz+33.33);
			return frac((p3.xxy + p3.yxx)*p3.zyx);
		}

		struct appdata
		{
			float4 vertex : POSITION;
			float3 uv : TEXCOORD0;
			float3 normal : NORMAL;
		};

		struct v2g
		{
			float3 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;
			float3 normal : NORMAL;
		};

		struct g2f
		{
			float3 _ShadowCoord : SHADOWCOORD;
			float3 uv : TEXCOORD0;
			float3 normal : NORMAL;
			float4 vertex : SV_POSITION;
			float death : DEATH;
			float4 debug : DEBUG;
			UNITY_FOG_COORDS(1)
		};

		float4 _ColorAmbient;
		sampler2D _ShipTex;
		float _ForceDisplay;
		float _Norminess;
		float4 _SkyLight;
		sampler2D _BananaTex;
		Texture2D< float4 > _GeometryTex;

		v2g vert (appdata v)
		{
			v2g o;
			o.vertex = v.vertex;
			o.uv = v.uv;
			o.normal = v.normal;
			UNITY_TRANSFER_FOG(o,o.vertex);
			return o;
		}
		

		[maxvertexcount(3)]
		void geo(triangle v2g input[3], inout TriangleStream<g2f> triStream, uint pid : SV_PrimitiveId)
		{
			g2f o;
			uint geoID = input[0].uv.z;
			uint groupNo = geoID/5;
			uint columnInGeoTex = groupNo + 6;
			bool isShip = (geoID%5)==0;
			bool isBanana = (geoID%5);
			uint bananaNo = (geoID%5)-1;
			
			//o.debug = float4( columnInGeoTex/64, 0, 0, 1 );
			o.debug = 0;
			for(int i = 0; i < 3; i++)
			{
				o.uv = input[i].uv;
				float4 objectPlace = float4(input[i].vertex);
				float3 tnorm = input[i].normal;
				o.death = 0;

				if( isShip )
				{
					float3 deathprops = _GeometryTex[uint2( columnInGeoTex, 6 )];
					if( deathprops.x > 0 )
					{
						float3 perdir = chash33( float3( groupNo, pid, 0) ) - 0.5;
						float3 colval = chash33( float3( groupNo, deathprops.x, 100+pid ) );
						o.debug = float4( colval.r-deathprops.x*0.5+1.0, 0, 0, 1 );
						{
							//Shrink the geo.
							float3 tricenter = ( input[0].vertex.xyz + input[1].vertex.xyz + input[2].vertex.xyz)/3;
							objectPlace.xyz = lerp( objectPlace.xyz, tricenter, smoothstep(0, 1,float((deathprops.x-1.5)/3)) );
						}
						o.death = 1;
						objectPlace.xyz += perdir * deathprops.x;
					}
				
					float3 hpra = _GeometryTex[uint2( columnInGeoTex, 21)];

					// from tdRotateNoMulEA on the swadge.
					float cy = cos( hpra[0] ); // NOTICE: FLIPPED CX/CY
					float sy = sin( hpra[0] );
					float cx = cos( hpra[1] );
					float sx = sin( hpra[1] );
					float cz = cos( hpra[2] );
					float sz = sin( hpra[2] );

					float3x3 rmot = float3x3(
						cy*cz, sx*sy*cz-cx*sz, cx*sy*cz+sx*sz,
						cy*sz, sx*sy*sz+cx*cz, cx*sy*sz-sx*cz,
						-sy, sx*cy, cx*cy );
					
					objectPlace.xyz = objectPlace.xzy * float3( 1, 1, -1 );  // WHY XZY HERE?  WHY COORDNIATE SHIFT?
					objectPlace.xyz = mul( rmot, objectPlace.xyz );
					tnorm.xyz = mul( rmot, tnorm.xzy  * float3( 1, 1, -1 ) );
				}
				else
				{
					// BANANA
					float3 RotationAxis = normalize( chash33( float3( groupNo, bananaNo, .373) ) );
					float RotationAngle = _GeometryTex[uint2( columnInGeoTex, 8+bananaNo)].x*10;
					float4 q = float4( RotationAxis.x * sin( RotationAngle / 2 ),
									  RotationAxis.y * sin( RotationAngle / 2 ),
									  RotationAxis.z * sin( RotationAngle / 2 ),
									  cos(RotationAngle / 2) );

					objectPlace.xyz = objectPlace.xyz + 2.0 * cross(q.xyz, cross(q.xyz, objectPlace.xyz) + q.w *objectPlace.xyz);

					tnorm.xyz = tnorm.xyz + 2.0 * cross(q.xyz, cross(q.xyz, tnorm.xyz) + q.w * tnorm.xyz);
					tnorm = normalize(tnorm);
					// If id == 0 it is a non-banana.
					if( _GeometryTex[uint2( columnInGeoTex, 8+bananaNo)].z < 0.1 || _GeometryTex[uint2( columnInGeoTex, 8+bananaNo)].x < 0 ) return;
				}
				
				float4 worldPlace = mul(unity_ObjectToWorld, objectPlace );

				if( isShip )
				{
					if( length( _GeometryTex[uint2( columnInGeoTex, 1)].xyz ) == 0 && _ForceDisplay < 0.5 ) return;
					worldPlace.xyz += _GeometryTex[uint2( columnInGeoTex, 20)];
  					if( length( o.debug ) == 0 ) o.debug.r = -2;
				}
				else
				{
					if( length( _GeometryTex[uint2( columnInGeoTex, 12+bananaNo)].xyz ) == 0 ) return;
					worldPlace.xyz += _GeometryTex[uint2( columnInGeoTex, 12+bananaNo)] +
									  _GeometryTex[uint2( columnInGeoTex, 16+bananaNo)] * _GeometryTex[uint2( columnInGeoTex, 8+bananaNo)].x * 7.629;
									  
					// Is banana.
					o.debug.r = -1;
				}
				
				o.vertex = mul(UNITY_MATRIX_VP, worldPlace);
				UNITY_TRANSFER_FOG(o,o.vertex);
				o.uv = input[i].uv;
				o.normal = UnityObjectToWorldNormal(tnorm);
				
				o._ShadowCoord = ComputeScreenPos(o.vertex);
				#if UNITY_PASS_SHADOWCASTER
				o.vertex = UnityApplyLinearShadowBias(o.vertex);
				#endif

				triStream.Append(o);
			}
			triStream.RestartStrip();
		}
		ENDCG
	  

		Pass
		{
			CGPROGRAM
			#pragma fragment frag

			float4 frag (g2f i) : SV_Target
			{
				// sample the texture
				float4 col = length(i.debug)?i.debug:float4( i.normal, 1.0 );
				if( i.debug.r < -1 )
				{
					col = tex2D( _ShipTex, float3( i.uv.xy, 0.0 ) );
				}
				else if( i.debug.r < 0 )
				{
					col = tex2D( _BananaTex, float3( i.uv.xy, 0.0 ) );
				}
				if( i.death < 0.5 )
				{
					float3 lightContrib = min( max( 0, _Norminess + i.normal.y ), 3.0 );
					
					col.rgb *= lightContrib * _SkyLight + _ColorAmbient;
				}
				UNITY_APPLY_FOG(i.fogCoord, col);
				return saturate(col);
			}
			ENDCG
		}
		
				
		Pass
		{
			Tags { "RenderType"="Opaque" "LightMode" = "ShadowCaster" }
			CGPROGRAM
			#pragma fragment fragShadow
			#pragma multi_compile_shadowcaster
			float4 fragShadow(g2f i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}   
			ENDCG
		}
	}
}
