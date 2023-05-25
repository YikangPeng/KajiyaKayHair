Shader "Unlit/KKHair"
{
	Properties
	{
		_Diffuse("Diffuse", Color) = (1, 1, 1, 1)
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss1("Gloss1", Range(8.0, 256)) = 20
		_Gloss2("Gloss2", Range(8.0, 256)) = 20
		_Shift1("Shift1", float) = 0
		_Shift2("Shift2", float) = 0
		_NoiseTex("NoiseTex" , 2D) = "white"{}
		_AlphaTex("Alpha Tex", 2D) = "white" {}
		_MaskTex("Mask Tex", 2D) = "white" {}
	}

	SubShader
	{
		Tags{ "Queue"="Geometry" "IgnoreProjector" = "True" "RenderType"="Opaque"}
		Pass
		{
			Tags {"LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"

			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss1;
			float _Gloss2;
			float _Shift1;
			float _Shift2;
			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			float4 _AlphaTex_ST;
			sampler2D _AlphaTex;
			sampler2D _MaskTex;
			float4 _MaskTex_ST;

			struct a2v
			{
				float4 texcoord : TEXCOORD;
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float3 worldBinormal : TEXCOORD2;
				float4 uv : TEXCOORD3;
			};

			//顶点着色器当中的计算
			v2f vert(a2v v)
			{
				v2f o;
				//转换顶点空间：模型=>投影
				o.pos = UnityObjectToClipPos(v.vertex);
				//转换顶点空间：模型=>世界
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				//转换法线空间：模型=>世界
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldNormal = worldNormal;
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				o.worldBinormal = cross(worldTangent, worldNormal);
				o.uv.xy = v.texcoord.xy * _NoiseTex_ST.xy + _NoiseTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _AlphaTex_ST.xy + _AlphaTex_ST.zw;
				return o;
			}

			//片元着色器中的计算
			fixed4 frag(v2f i) : SV_Target
			{
				fixed Alpha = tex2D(_AlphaTex, i.uv.zw).r;
				clip(Alpha -0.5);

				//获取环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 reflectDir = normalize(lightDir + viewDir);

				float shift = tex2D(_NoiseTex, i.uv.xy).r - 0.5;
				float shift1 = shift - _Shift1;
				float shift2 = shift - _Shift2;
				float3 worldBinormal = i.worldBinormal;
				float3 worldNormal = i.worldNormal;
				float3 worldBinormal1 = normalize(worldBinormal + shift1 * worldNormal);
				float3 worldBinormal2 = normalize(worldBinormal + shift2 * worldNormal);

				//计算第高光  
				float3 H1 = normalize(lightDir + viewDir);
				float dotTH1 = dot(worldBinormal1, H1);
				float sinTH1 = sqrt(1.0 - dotTH1 * dotTH1);
				float dirAtten1 = smoothstep(-1, 0, dotTH1);
				float S1 = dirAtten1 * pow(sinTH1, _Gloss1);

				

				fixed3 specular = _LightColor0.rgb * _Specular.rgb * S1;
				//Lanbert光照
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(i.worldNormal, lightDir));
				//对高光范围进行遮罩
				specular *= saturate(diffuse * 2);

				//fixed4 maskTex = tex2D(_MaskTex, i.uv.xy);

				return fixed4(ambient + diffuse + specular, 1.0);
				//return maskTex;

			}
			ENDCG
		}
	}
		FallBack "Specular"
}
