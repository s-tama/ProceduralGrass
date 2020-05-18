//
// ProceduralGrass.shader
//

Shader "Custom/ProceduralGrass"
{
    Properties
    {
        _GroundColor("Ground Color", Color) = (1, 1, 1, 1)

        _TopColor("Top Color", Color) = (1, 1, 1, 1)
        _BottomColor("Bottom Color", Color) = (1, 1, 1, 1)

        _Dir("Dir", Vector) = (1, 0, 0, 1)

        // 草のサイズ
        _Width("Width", Float) = 80
        _Height("Height", Float) = 2.5

        // 草の各部の幅
        _BottomWidth("Bottom Width", Range(0, 1)) = 0.5
        _MiddleWidth("Middle Width", Range(0, 1)) = 0.4
        _TopWidth("Top Width", Range(0, 1)) = 0.3

        // 草の各部の高さ
        _BottomHeight("Bottom Height", Range(0, 1)) = 0.3
        _MiddleHeight("Middle Height", Range(0, 1)) = 0.4
        _TopHeight("Top Height", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
        }
        LOD 100

        Cull Off
        ZWrite On

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
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2g
            {
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
            };

            struct g2f
            {
                float4 pos : SV_POSITION;
                float4 col : COLOR;
            };

            // 地面の色
            fixed4 _GroundColor;

            // 草の色
            float4 _TopColor, _BottomColor;

            // 生成方向
            float4 _Dir;

            // 草全体の幅と高さ
            float _Width, _Height;
            // それぞれの幅（下部、中間部、上部）
            float _BottomWidth, _MiddleWidth, _TopWidth;
            // それぞれの高さ（下部、中間部、上部）
            float _BottomHeight, _MiddleHeight, _TopHeight;
            // それぞれの曲がり具合（下部、中間部、上部）
            float _BottomBend, _MiddleBend, _TopBend;

            // テクスチャマップ
            sampler2D _HeightTex;
            sampler2D _RotationTex;
            sampler2D _WindTex;

            v2g vert(appdata v)
            {
                v2g o;
                o.pos = v.pos;
                o.normal = v.normal;
                return o;
            }

            [maxvertexcount(10)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> stream)
            {
                // 地面
                [unroll]
                for (int i = 0; i < 3; i++)
                {
                    g2f o;
                    o.pos = UnityObjectToClipPos(input[i].pos);
                    o.col = _GroundColor;
                    stream.Append(o);
                }
                stream.RestartStrip();

                // 頂点位置
                float4 p0 = input[0].pos;
                float4 p1 = input[1].pos;
                float4 p2 = input[2].pos;

                // 法線
                float3 n0 = input[0].normal;
                float3 n1 = input[1].normal;
                float3 n2 = input[2].normal;

                // 三角形、法線の中心を算出
                float4 center = (p0 + p1 + p2) / 3.0;
                float4 normal = float4((n0 + n1 + n2) / 3.0, 1.0);

                // 各プリミティブの幅・高さ
                float width = _Width;
                float4 height = _Height;

                float bottomWidth = width * _BottomWidth;
                float middleWidth = width * _MiddleWidth;
                float topWidth = width * _TopWidth;

                float bottomHeight = height * _BottomHeight;
                float middleHeight = height * _MiddleHeight;
                float topHeight = height * _TopHeight;

                float4 dir = _Dir;

                // 草のプリミティブを生成する
                {
                    g2f o[7];

                    // Bottom
                    o[0].pos = center - dir * bottomWidth;
                    o[0].col = _BottomColor;

                    o[1].pos = center + dir * bottomWidth;
                    o[1].col = _BottomColor;

                    // Bottom to Middle
                    o[2].pos = center - dir * middleWidth + (normal * bottomHeight);
                    o[2].col = lerp(_BottomColor, _TopColor, 0.33333);

                    o[3].pos = center + dir * middleWidth + (normal * bottomHeight);
                    o[3].col = lerp(_BottomColor, _TopColor, 0.33333);

                    // Middle to Top
                    float4 middlePos = float4(center.x, o[3].pos.y, center.z, 1);
                    o[4].pos = middlePos - dir * topWidth + (normal * middleHeight);
                    o[4].col = lerp(_BottomColor, _TopColor, 0.66666);

                    o[5].pos = middlePos + dir * topWidth + (normal * middleHeight);
                    o[5].col = lerp(_BottomColor, _TopColor, 0.66666);

                    // Top
                    float4 topPos = float4(center.x, o[5].pos.y, center.z, 1);
                    o[6].pos = topPos + (normal * topHeight);
                    o[6].col = _TopColor;

                    [unroll]
                    for (int i = 0; i < 7; i++)
                    {
                        o[i].pos = UnityObjectToClipPos(o[i].pos);
                        stream.Append(o[i]);
                    }
                    stream.RestartStrip();
                }

                
            }

            fixed4 frag(g2f i) : SV_Target
            {
                return i.col;
            }
            ENDCG
        }
    }
}
