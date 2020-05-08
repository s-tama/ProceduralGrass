//
// ProceduralGrass.shader
//

Shader "Custom/ProceduralGrass"
{
    Properties
    {
        _Height("Height", Range(0, 1)) = 1.0
        _TopColor("Top Color", Color) = (1, 1, 1, 1)
        _BottomColor("Bottom Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry+1" }
        LOD 100

        Cull Off
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
            };

            struct v2g
            {
                float4 pos : SV_POSITION;
            };

            struct g2f
            {
                float4 pos : SV_POSITION;
                float4 col : COLOR;
            };

            float _Height;
            float4 _TopColor;
            float4 _BottomColor;

            v2g vert(appdata v)
            {
                v2g o;
                o.pos = v.pos;
                return o;
            }

            [maxvertexcount(12)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> outStream)
            {
                float4 p0 = input[0].pos;
                float4 p1 = input[1].pos;
                float4 p2 = input[2].pos;

                // 三角形の中心点を算出
                float4 center = float4(0.0, 0.0, -_Height, 1.0)
                    + (p0 + p1 + p2) * 0.33333;

                g2f o0;
                o0.pos = UnityObjectToClipPos(p0);
                o0.col = _BottomColor;

                g2f o1;
                o1.pos = UnityObjectToClipPos(p1);
                o1.col = _BottomColor;

                g2f o2;
                o2.pos = UnityObjectToClipPos(p2);
                o2.col = _BottomColor;

                g2f o;
                o.pos = UnityObjectToClipPos(center);
                o.col = _TopColor;

                // bottom
                outStream.Append(o0);
                outStream.Append(o1);
                outStream.Append(o2);
                outStream.RestartStrip();

                // sides
                outStream.Append(o0);
                outStream.Append(o1);
                outStream.Append(o);
                outStream.RestartStrip();

                outStream.Append(o1);
                outStream.Append(o2);
                outStream.Append(o);
                outStream.RestartStrip();

                outStream.Append(o2);
                outStream.Append(o0);
                outStream.Append(o);
                outStream.RestartStrip();
            }

            fixed4 frag(g2f i) : SV_Target
            {
                return i.col;
            }
            ENDCG
        }
    }
}
