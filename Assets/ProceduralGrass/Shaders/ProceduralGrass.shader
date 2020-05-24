//
// ProceduralGrass.shader
//

Shader "Custom/ProceduralGrass"
{
	Properties
	{
		// トグル
		[Toggle(_APPLY_GROUND)] _ApplyGround("Apply Ground", Int) = 1

		// カラー
		_GroundColor("Ground Color", Color) = (1, 1, 1, 1)
		_TopColor("Top Color", Color) = (1, 1, 1, 1)
		_BottomColor("Bottom Color", Color) = (1, 1, 1, 1)

		// サイズ
		_Width("Width", Float) = 1
		_Height("Height", Float) = 1

		// 風の向き
		_WindDir("Wind Dir", Vector) = (1, 0, 0, 0)
        // 風邪の強さ
        _WindForce("Wind Force", Float) = 1

        // マップ・テクスチャ
        _HeightTex("Height Texture", 2D) = "white"{}
        _RotationTex("Rotation Texture", 2D) = "white"{}
        _WindTex("Wind Texture", 2D) = "white"{}
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

            #pragma shader_feature _APPLY_GROUND

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

            fixed4 _GroundColor, _TopColor, _BottomColor;
            float _Width, _Height;
			float _WindDir, _WindForce;
            sampler2D _HeightTex, _RotationTex, _WindTex;

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

#ifdef _APPLY_GROUND
            [maxvertexcount(VERTEX_NUM + 3)]
#else
			[maxvertexcount(VERTEX_NUM)]
#endif
            void geom(triangle v2g input[3], inout TriangleStream<g2f> stream)
            {
                int i;

#ifdef _APPLY_GROUND
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
#endif

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

                // 草の向きを算出
                float a = (input[0].rotation + input[1].rotation + input[2].rotation) / 3.0;
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

                    if ((uint)i % 2 == 0)
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

                    if ((uint)i % 2 == 0)
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
            }

            fixed4 frag(g2f i) : SV_Target
            {
                return i.col;
            }
            ENDCG
        }
    }
}
