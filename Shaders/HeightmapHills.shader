
Shader "dawnofender/HeightmapHills"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HeightTex ("Heightmap", 2D) = "black" {}
        _Amplitude ("Amplitude", Float) = 1.0
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

            sampler2D _MainTex;
            sampler2D _HeightTex;
            float4 _MainTex_ST;
            float4 _HeightTex_ST;
            float _Amplitude;
            
            // catmull works by specifying 4 control points p0, p1, p2, p3 and a weight. The function is used to calculate a point n between p1 and p2 based
            // on the weight. The weight is normalized, so if it's a value of 0 then the return value will be p1 and if its 1 it will return p2. 
            float catmullRom( float p0, float p1, float p2, float p3, float weight ) {
                float weight2 = weight * weight;
                return 0.5 * (
                    p0 * weight * ( ( 2.0 - weight ) * weight - 1.0 ) +
                    p1 * ( weight2 * ( 3.0 * weight - 5.0 ) + 2.0 ) +
                    p2 * weight * ( ( 4.0 - 3.0 * weight ) * weight + 1.0 ) +
                    p3 * ( weight - 1.0 ) * weight2 );
            }

            
            // Performs a horizontal catmulrom operation at a given V value.
            float textureCubicU( sampler2D samp, float2 uv00, float texel, float offsetV, float frac ) {
                return catmullRom(
                    tex2Dlod( samp, float4(uv00 + float2(-texel, offsetV ), 0.0, 0.0)),
                    tex2Dlod( samp, float4(uv00 + float2(0.0, offsetV ), 0.0, 0.0)),
                    tex2Dlod( samp, float4(uv00 + float2(texel, offsetV ), 0.0, 0.0)),
                    tex2Dlod( samp, float4(uv00 + float2(texel * 2.0, offsetV ), 0.0, 0.0)),
                frac);
            }
            
            // Samples a texture using a bicubic sampling algorithm. This essentially queries neighbouring
            // pixels to get an average value.
            float textureBicubic( sampler2D samp, float2 uv00, float2 texel, float2 frac ) {
                return catmullRom(
                    textureCubicU( samp, uv00, texel.x, -texel.y, frac.x ),
                    textureCubicU( samp, uv00, texel.x, 0.0, frac.x ),
                    textureCubicU( samp, uv00, texel.x, texel.y, frac.x ),
                    textureCubicU( samp, uv00, texel.x, texel.y * 2.0, frac.x ),
                frac.y );
            }

            float terrain(float2 uv) {
                float2 uv_scaled = uv * _HeightTex_ST.xy;
                float2 uv_frac = frac(uv_scaled * _HeightTex_ST.zw);
                float2 pixel_coord = uv_scaled * _HeightTex_ST.zw - uv_frac;
                //
                // uint2 coord00 = uint2(pixel_coord);
                // uint2 coord01 = uint2(coord00.x + 1, coord00.y);
                // uint2 coord10 = uint2(coord00.x,     coord00.y + 1);
                // uint2 coord11 = uint2(coord00.x + 1, coord00.y + 1);
                //
                // float2 heightUv = uv;//uv_scaled;
                float2 tHeightSize = _HeightTex_ST.zw;
                
                // // The size of each texel
                // float2 texel = float2( 1.0 / tHeightSize.x, 1.0 / tHeightSize.y );
                // //
                // // // Find the top-left texel we need to sample.
                // // float2 heightUv00 = ( floor( heightUv * tHeightSize ) ) / tHeightSize;
                // //
                // // // Determine the fraction across the 4-texel quad we need to compute.
                // // float2 frac = float2( heightUv - heightUv00 ) * tHeightSize;
                // 
                // float base_height = textureBicubic( _HeightTex, uv_scaled, texel, uv_frac );
                
                // return base_height * _Amplitude;
                float distance = 0.01f;
                
                return (
                    tex2Dlod(_HeightTex, float4(uv_scaled + distance * float2(0.f, 0.f), 0.0, 0.0)) + 
                    tex2Dlod(_HeightTex, float4(uv_scaled + distance * float2(0.f, 1.f), 0.0, 0.0)) + 
                    tex2Dlod(_HeightTex, float4(uv_scaled + distance * float2(1.f, 0.f), 0.0, 0.0)) + 
                    tex2Dlod(_HeightTex, float4(uv_scaled + distance * float2(1.f, 1.f), 0.0, 0.0))
                ) / 4.f * _Amplitude;

                // return tex2Dlod(_HeightTex, float4(uv_scaled, 0.0, 0.0)) * _Amplitude;
            }

            v2f vert (appdata v) {

                float4 worldScale = float4(
                    length(float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x)), // scale x axis
                    length(float3(unity_ObjectToWorld[0].y, unity_ObjectToWorld[1].y, unity_ObjectToWorld[2].y)), // scale y axis
                    length(float3(unity_ObjectToWorld[0].z, unity_ObjectToWorld[1].z, unity_ObjectToWorld[2].z)),  // scale z axis
                    1.0f
                );

                float4 vertex = v.vertex + float4(_WorldSpaceCameraPos.x, -_WorldSpaceCameraPos.z, 0, 0) / worldScale;

		        float2 uv = vertex.xy;
		        float height = terrain(uv);
		        vertex.z += height;
                
                v2f o;
                o.vertex = UnityObjectToClipPos(vertex);
                o.uv = uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
