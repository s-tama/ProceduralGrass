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

        // 草の生成方向
        _Dir("Dir", Vector) = (1, 0, 0, 1)

        // 草全体のサイズ
        _Width("Width", Float) = 1
        _Height("Height", Float) = 1

        // 草の各部の幅
        _BottomWidth("Bottom Width", Range(0, 1)) = 0.5
        _MiddleWidth("Middle Width", Range(0, 1)) = 0.4
        _TopWidth("Top Width", Range(0, 1)) = 0.3

        // 草の各部の高さ
        _BottomHeight("Bottom Height", Range(0, 1)) = 0.3
        _MiddleHeight("Middle Height", Range(0, 1)) = 0.4
        _TopHeight("Top Height", Range(0, 1)) = 0.5

        // 草の各部の曲がり具合
        _Bend("Bend", Range(-1, 1)) = 0

        // 風邪の強さ
        _WindForce("Wind Force", Float) = 1

        // マップ・テクスチャ
        _HeightTex("Height Texture", 2D) = "white"{}
        _RotationTex("Rotation Texture", 2D) = "white"{}
        _WindTex("Wind Texture", 2D) = "white"{}

        // トグル
        [Toggle(_SIMPLE)] _Simple("Simple", Float) = 1
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

            #pragma shader_feature _SIMPLE

            #include "UnityCG.cginc"

            #define PI (3.1415)
            #define DEG2RAD (PI / 180)
            #define RAD2DEG (180 / PI)

            #define SEGMENT_NUM (6)                     // 草の分割数
            #define VERTEX_NUM (SEGMENT_NUM * 2 + 1)    // 草の頂点数

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
                float height : TEXCOORD0;
                float rotation : TEXCOORD1;
                float3 wind : TEXCOORD2;
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

            // 草全体のサイズ
            float _Width, _Height;
            // それぞれの幅（下部、中間部、上部）
            float _BottomWidth, _MiddleWidth, _TopWidth;
            // それぞれの高さ（下部、中間部、上部）
            float _BottomHeight, _MiddleHeight, _TopHeight;
            // それぞれの曲がり具合
            float _Bend;

            // 風邪の強さ
            float _WindForce;

            // マップ・テクスチャ
            sampler2D _HeightTex;
            sampler2D _RotationTex;
            sampler2D _WindTex;

            v2g vert(appdata v)
            {
                v2g o;
                o.pos = v.pos;
                o.normal = v.normal;
                o.height = tex2Dlod(_HeightTex, float4(v.uv, 0, 0)).r;
                o.rotation = tex2Dlod(_RotationTex, float4(v.uv, 0, 0)).r;
                o.wind = tex2Dlod(_WindTex, float4(v.uv, 0, 0)).rgb;
                return o;
            }

            [maxvertexcount(VERTEX_NUM + 3)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> stream)
            {
                int i;

                // 地面
                [unroll]
                for (i = 0; i < 3; i++)
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
                float h = (input[0].height + input[1].height + input[2].height) / 3.0;
                h *= 0.5;

                float width = _Width;
                float height = _Height * h;

                float bottomWidth = width * _BottomWidth;
                float middleWidth = width * _MiddleWidth;
                float topWidth = width * _TopWidth;

                float bottomHeight = h * height * _BottomHeight;
                float middleHeight = h * height * _MiddleHeight;
                float topHeight = h * height * _TopHeight;

                // 草の向きを算出
                float a = (input[0].rotation, input[1].rotation, input[2].rotation) / 3.0;
                a *= RAD2DEG;
                float4 dir = float4(cos(a), 0, sin(a), 0);

                // 風邪の向き
                float wind = float4((input[0].wind + input[1].wind + input[2].wind) / 3.0, 0);

                // 草のプリミティブを生成する
                g2f bottom[2];

                // Bottom
                bottom[0].pos = center + dir * _Width;
                bottom[0].col = _BottomColor;
                bottom[1].pos = center - dir * _Width;
                bottom[1].col = _BottomColor;

                // Top
                g2f top;
                top.pos = center + normal * height;
                top.pos += dir * wind * _WindForce * sin(_Time * 0.1);
                top.col = _TopColor;

                // BottomとTopの3点を除いた中間地点のポイントを算出
                g2f middle[VERTEX_NUM - 3];
                int segmentCount = 1;
                for (i = 0; i < VERTEX_NUM - 3; i++)
                {
                    float delta = (float)segmentCount / (float)SEGMENT_NUM;

                    if (i % 2 == 0)
                    {
                        float4 halfPos = bottom[0].pos + (normal * (height * 0.5));
                        float4 p0 = lerp(bottom[0].pos, halfPos, delta);
                        float4 p1 = lerp(halfPos, top.pos, delta);
                        middle[i].pos = lerp(p0, p1, delta);
                        middle[i].col = lerp(_BottomColor, _TopColor, delta);
                    }
                    else
                    {
                        float4 halfPos = bottom[1].pos + (normal * (height * 0.5));
                        float4 p0 = lerp(bottom[1].pos, halfPos, delta);
                        float4 p1 = lerp(halfPos, top.pos, delta);
                        middle[i].pos = lerp(p0, p1, delta);
                        middle[i].col = lerp(_BottomColor, _TopColor, delta);
                    }

                    if (i % 2 == 0)
                    {
                        segmentCount++;
                    }
                }

                // ポリゴン生成
                bottom[0].pos = UnityObjectToClipPos(bottom[0].pos);
                stream.Append(bottom[0]);
                bottom[1].pos = UnityObjectToClipPos(bottom[1].pos);
                stream.Append(bottom[1]);

                for (i = 0; i < VERTEX_NUM - 3; i++)
                {
                    middle[i].pos = UnityObjectToClipPos(middle[i].pos);
                    stream.Append(middle[i]);
                }

                top.pos = UnityObjectToClipPos(top.pos);
                stream.Append(top);

                stream.RestartStrip();

                //int count = 0;
                //int num = SEGMENT_NUM;
                //for (i = 0; i < num; i++)
                //{
                //    for (j = 0; j < 2; j++)
                //    {
                //        g2f o;
                //        if (j == 0)
                //        {
                //            o.pos = (center + dir * abs(i - num) * _Width) + (normal * i * _Height);
                //        }
                //        else if (j == 1)
                //        {
                //            o.pos = (center - dir * abs(i - num) * _Width) + (normal * i * _Height);
                //        }
                //        o.col = lerp(_BottomColor, _TopColor, (float)i / num);

                //        // 風邪の向きに揺らす
                //        o.pos += dir * _WindForce * abs(sin(_Time * i));

                //        o.pos = UnityObjectToClipPos(o.pos);
                //        stream.Append(o);
                //    }
                //    count++;
                //}
                //g2f o;
                //o.pos = center + normal * count * _Height;
                //o.col = _TopColor;
                //o.pos = UnityObjectToClipPos(o.pos);
                //o.pos += dir * _WindForce * abs(sin(_Time * count));
                //stream.Append(o);
                //stream.RestartStrip();

                /*
                g2f o[7];

                // Bottom
                o[0].pos = center - dir * bottomWidth;
                o[0].col = _BottomColor;

                o[1].pos = center + dir * bottomWidth;
                o[1].col = _BottomColor;

                // Bottom to Middle
                o[2].pos = (o[1].pos - dir * middleWidth) + (normal * bottomHeight);
                o[2].col = lerp(_BottomColor, _TopColor, 0.33333);

                o[3].pos = (o[1].pos + dir * middleWidth) + (normal * bottomHeight);
                o[3].col = lerp(_BottomColor, _TopColor, 0.33333);

                // Middle to Top
                o[4].pos = (o[3].pos - dir * topWidth) + (normal * middleHeight);
                o[4].col = lerp(_BottomColor, _TopColor, 0.66666);

                o[5].pos = (o[3].pos + dir * topWidth) + (normal * middleHeight);
                o[5].col = lerp(_BottomColor, _TopColor, 0.66666);

                // Top
                o[6].pos = (o[5].pos + dir) + (normal * topHeight);
                o[6].col = _TopColor;

                // 風邪の向きに揺らす
                float wind = float4((input[0].wind + input[1].wind + input[2].wind) / 3.0, 0);
                wind = wind * 2 - 1;    // -1～1に補正

                float speed = 0.5;
                o[2].pos += dir * _WindForce * _BottomBend * sin(_Time * wind);
                o[3].pos += dir * _WindForce * _BottomBend * sin(_Time * wind);
                o[4].pos += dir * _WindForce * _MiddleBend * sin(_Time * wind);
                o[5].pos += dir * _WindForce * _MiddleBend * sin(_Time * wind);
                o[6].pos += dir * _WindForce * _TopBend * sin(_Time * speed);

                [unroll]
                for (i = 0; i < 7; i++)
                {
                    o[i].pos = UnityObjectToClipPos(o[i].pos);
                    stream.Append(o[i]);
                }
                stream.RestartStrip();
                */
            }

            fixed4 frag(g2f i) : SV_Target
            {
                return i.col;
            }
            ENDCG
        }
    }
}
