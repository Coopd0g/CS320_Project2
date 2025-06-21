Shader "Unlit/ParallaxMapping"
{
    Properties {
        _Diffuse      ("Diffuse",       2D) = "white" {}
        _Normal       ("Normal",        2D) = "bump"  {}
        _Specular     ("Specular",      2D) = "white" {}
        _Gloss        ("Gloss",         2D) = "white" {}
        _Displacement ("Displacement",  2D) = "black" {}
        _HeightScale  ("Height Scale",  Range(0,0.1)) = 0.02
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _Diffuse, _Normal, _Specular, _Gloss, _Displacement;
            float    _HeightScale;
            float4   _LightColor0;

            struct appdata {
                float4 vertex  : POSITION;
                float2 uv      : TEXCOORD0;
                float3 normal  : NORMAL;
                float4 tangent : TANGENT;
            };
            struct v2f {
                float4 pos       : SV_POSITION;
                float2 uv        : TEXCOORD0;
                float3 viewDirT  : TEXCOORD1;
            };

            v2f vert(appdata v) {
                v2f o;
                o.pos      = UnityObjectToClipPos(v.vertex);
                o.uv       = v.uv;

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 viewDir  = _WorldSpaceCameraPos - worldPos;

                float3 T = normalize(mul((float3x3)unity_ObjectToWorld, v.tangent.xyz));
                float3 N = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));
                float3 B = cross(N, T) * v.tangent.w;
                float3x3 TBN = float3x3(T, B, N);

                o.viewDirT = mul(TBN, viewDir);
                return o;
            }

            float2 ParallaxOffset(float2 uv, float3 viewDir) {
                float height = tex2D(_Displacement, uv).r;
                return uv + viewDir.xy / viewDir.z * (height * _HeightScale);
            }

            fixed4 frag(v2f i) : SV_Target {
                float3 viewDir = normalize(i.viewDirT);
                float2 uvP      = saturate(ParallaxOffset(i.uv, viewDir));

                fixed4 diff  = tex2D(_Diffuse,     uvP);
                fixed3 nrm   = UnpackNormal(tex2D(_Normal,   uvP));
                fixed  spec  = tex2D(_Specular,    uvP).r;
                fixed  gloss = tex2D(_Gloss,       uvP).r;

                float3 L      = normalize(float3(0.5, 1, 0.5));
                float  NdotL  = max(dot(nrm, L), 0);
                float3 diffuse  = diff.rgb * NdotL;
                float3 H        = normalize(L + viewDir);
                float  NdotH    = max(dot(nrm, H), 0);
                float3 specular = pow(NdotH, gloss * 128) * spec;

                return fixed4(diffuse + specular, diff.a);
            }

            ENDCG
        }
    }
}
