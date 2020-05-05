//
// ProceduralGrass.shader
//

Shader "Custom/ProceduralGrass"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Height("Height", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry+1" }
        LOD 100

        Cull Back
        ZWrite On
        ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma target 5.0

            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2g
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            struct g2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 lightDir : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Height;

            v2g vert(appdata v)
            {
                v2g o;
                o.pos = v.pos;
                o.uv = v.uv;
                return o;
            }

            [maxvertexcount(3)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> outStream)
            {
                float4 pos0 = input[0].pos;
                float4 pos1 = input[1].pos;
                float4 pos2 = input[2].pos;

                // 三角形の中心点を算出
                float4 center = (pos0 + pos1 + pos2) * 0.33333;
                center += float4(0.0, 0.0, -_Height, 1.0);

                /*
                g2f o0;
                o0.pos = UnityObjectToClipPos(p0);
                o0.uv = input[0].uv;

                g2f o1;
                o1.pos = UnityObjectToClipPos(p1);
                o1.uv = input[1].uv;

                g2f o2;
                o2.pos = UnityObjectToClipPos(p2);
                o2.uv = input[2].uv;

                g2f o;
                o.pos = UnityObjectToClipPos(center);
                o.uv = 
                */

                float4 v0 = pos1 - pos0;
                float4 v1 = pos2 - pos0;
                float3 normal = cross(v0, v1);

                for (int i = 0; i < 3; i++)
                {
                    g2f o;

                    o.pos = UnityObjectToClipPos(input[i].pos);
                    o.uv = input[i].uv;
                    o.normal = UnityObjectToWorldNormal(normal);
                    o.lightDir = WorldSpaceLightDir(input[i].pos);

                    outStream.Append(o);
                }

                outStream.RestartStrip();
            }

            fixed4 frag(g2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                
                float3 normal = normalize(i.normal);
                float3 lightDir = normalize(i.lightDir);
                float diff = saturate(dot(normal, lightDir));
                col.rgb *= diff;
                return col;
            }
            ENDCG
        }
    }
}
