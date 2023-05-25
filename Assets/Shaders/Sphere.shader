Shader "Unlit/Sphere"
{
    Properties
    {
        
        _Lightpos("_Lightpos",Vector) = (0.5,0.5,0.5)
        _Pow("_Pow",Float) = 1.0
        _ShiftScale("_ShiftScale",Float) = 0.0       
        _SphereCenter("_SphereCenter",Vector) = (0.0,0.0,0.0)
        _RotateBitangent("_RotateBitangent",Vector) = (0.0,0.0,0.0)
        _MaskScale("MaskScale",Float) = 20.0
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
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 uv4 : TEXCOORD3;
                
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                //float4 tangent : TANGENT;
                float3 normal : TEXCOORD1;
                float4 worldpos : TEXCOORD2;
                float3 worldnormal : TEXCOORD3;
                float3 worldtangent : TEXCOORD4;
                float3 worldbtangent : TEXCOORD5;
                float2 uv4 : TEXCOORD6;
                float3 fixnormal : TEXCOORD7;
            };

            
            float3 _Lightpos;
            float _Pow;
            float _ShiftScale;            
            float3 _SphereCenter;
            float3 _RotateBitangent;
            float _MaskScale;

            float4 qmul(float4 q1, float4 q2)
            {
                return float4(
                    q2.xyz * q1.w + q1.xyz * q2.w + cross(q1.xyz, q2.xyz),
                    q1.w * q2.w - dot(q1.xyz, q2.xyz)
                    );
            }

            // Vector rotation with a quaternion
            
            float3 rotate_vector(float3 v, float4 r)
            {
                float4 r_c = r * float4(-1, -1, -1, 1);
                return qmul(r, qmul(float4(v, 0), r_c)).xyz;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);                

                o.normal = v.normal;
                o.worldpos.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldpos.w = atan2(v.vertex.z , v.vertex.x);

                //float3 worldTangent = mul(unity_ObjectToWorld, v.tangent.xyz).xyz;
                //o.worldtangent = normalize(worldTangent);
                float3 worldNormal = mul(v.normal, unity_WorldToObject);
                o.worldnormal = normalize(worldNormal);
                // BiNormal
                //float3 worldBiTangent = cross(worldNormal, worldTangent) * v.tangent.w;
                //o.worldbtangent = normalize(worldBiTangent);
                //o.worldbtangent = normalize(worldTangent);

                //calculate bitangent by sphere
                o.fixnormal = normalize(v.vertex.xyz - _SphereCenter);
                float3 caltangent = normalize(cross(float3( 0,1,0 ), o.fixnormal));
                o.worldbtangent = mul(unity_ObjectToWorld, normalize(cross(o.fixnormal, caltangent)));

                //rotate bitangent
                float4 q = 0;
                q.x = sin(_RotateBitangent.x/2) * cos(_RotateBitangent.y/2) * cos(_RotateBitangent.z/2) - cos(_RotateBitangent.x/2) * sin(_RotateBitangent.y/2) * sin(_RotateBitangent.z/2);
                q.y = cos(_RotateBitangent.x / 2) * sin(_RotateBitangent.y / 2) * cos(_RotateBitangent.z / 2) + sin(_RotateBitangent.x / 2) * cos(_RotateBitangent.y / 2) * sin(_RotateBitangent.z / 2);
                q.z = cos(_RotateBitangent.x / 2) * cos(_RotateBitangent.y / 2) * sin(_RotateBitangent.z / 2) - sin(_RotateBitangent.x / 2) * sin(_RotateBitangent.y / 2) * cos(_RotateBitangent.z / 2);
                q.w = cos(_RotateBitangent.x / 2) * cos(_RotateBitangent.y / 2) * cos(_RotateBitangent.z / 2) + sin(_RotateBitangent.x / 2) * sin(_RotateBitangent.y / 2) * sin(_RotateBitangent.z / 2);

                o.worldbtangent = rotate_vector(o.worldbtangent, q);

                o.uv4 = v.uv4;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                

                float3 V = _WorldSpaceCameraPos.xyz - i.worldpos.xyz;
                V = normalize(V);

                float3 N = normalize(i.normal);

                float shift = sin(i.worldpos.w * 20);
                float mask = saturate(sin(i.worldpos.w * _MaskScale));

                float3 L = normalize(_Lightpos) + _ShiftScale  * i.worldnormal;
                //float3 L = normalize(_WorldSpaceLightPos0) + shift * i.worldnormal;

                float3 H = normalize(V + L);

                
                float HdotT = dot(H, i.worldbtangent);

                float sinTH = sqrt(1.0 - HdotT * HdotT);             
                                

                float NdotV = dot(N, V);
                float NdotH = dot(N, H);

                
                
                float exp = pow(sinTH, _Pow) * mask;
                

                return float4(exp, exp, exp,1);
                
                
            }
            ENDCG
        }
    }
}
