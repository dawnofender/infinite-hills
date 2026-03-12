
Shader "dawnofender/CosineHills"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            float4 _MainTex_ST;
            
            float terrain(float2 uv) {
                return (cos(uv.x * 0.03) + cos(uv.y * 0.03)) * 10;
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
