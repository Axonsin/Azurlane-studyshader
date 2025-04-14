Shader "Custom/GenericSkinShader"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _Compensationcolor("最弱环境光补偿色",Color) = (1,1,1,1)
        
        [Header(NPR Shadow Settings)]
        _ShadowBias1 ("阴影偏移", Range(-1, 1)) = 0.0
        _ShadowSmoothness ("阴影平滑度", Range(0, 0.5)) = 0.1
        _ShadowStrength ("阴影强度", Range(0, 1)) = 0.7
        
        [Header(Lighting Settings)]
        _NPRBlend ("NPR 与 PBR 混合程度", Range(0, 1)) = 0.7
        [Toggle(_ADDITIONAL_LIGHTS)] _AdditionalLights ("Enable Additional Lights", Float) = 1
        _AdditionalLightsIntensity ("Additional Lights Intensity", Range(0, 1)) = 0.5
        
        [Header(SSS Settings)]
        _SSSColor ("次表面散射颜色", Color) = (1.0, 0.4, 0.4,.0)
        _SSSScale ("次表面散射强度", Range(0, 10)) = 1.0
        _SSSPower ("次表面散射衰减", Range(0.1, 10)) = 2.0
        _SSSDistortion ("散射法线扭曲", Range(0, 1)) = 0.5
        _SSSAmbient ("环境散射强度", Range(0, 2)) = 0.2
        _ThicknessMap ("厚度贴图(G通道)", 2D) = "white" {}
        _ThicknessMapPower ("厚度影响强度", Range(0, 2)) = 1.0
        
        [Header(Outline)]
        _OutlineWidth ("Outline Width", Range(0, 0.5)) = 0.02
        _OutlineColor ("Outline Color", Color) = (0.5, 0.5, 0.5, 1)
        _OutlineZOffset ("Z Offset", Range(0, 1)) = 0.0001
        _OutlineMask ("Outline Mask (黑色区域不显示描边)", 2D) = "white" {}
    }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            // 添加光照选项
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float4 tangentWS : TEXCOORD3;
                float3 bitangentWS : TEXCOORD4;
                float3 viewDirWS : TEXCOORD5;
                float4 shadowCoord : TEXCOORD6; // Shadow coordinates
            };
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
            TEXTURE2D(_ThicknessMap);
            SAMPLER(sampler_ThicknessMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float _BumpScale;
                float4 _Compensationcolor;
                // NPR阴影参数
                float _ShadowBias1;
                float _ShadowSmoothness;
                float _ShadowStrength;
                // PBR参数
                float _NPRBlend;
                float _AdditionalLightsIntensity;
                // SSS参数
                half4 _SSSColor;
                float _SSSScale;
                float _SSSPower;
                float _SSSDistortion;
                float _SSSAmbient;
                float4 _ThicknessMap_ST;
                float _ThicknessMapPower;
                // 轮廓参数
                float _OutlineWidth;
                float4 _OutlineColor;
                float _OutlineZOffset;
            CBUFFER_END
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                
                // Transform positions
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                
                // Transform normals and tangents
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = normalInputs.normalWS;
                output.tangentWS = float4(normalInputs.tangentWS, input.tangentOS.w);
                output.bitangentWS = normalInputs.bitangentWS;
                
                // View direction
                output.viewDirWS = GetWorldSpaceViewDir(positionInputs.positionWS);
                
                // UVs
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                
                // Shadow coordinates
                output.shadowCoord = TransformWorldToShadowCoord(positionInputs.positionWS);
                
                return output;
            }
            
            // Lambert漫反射光照计算函数
            half3 CalculateLambert(float3 normal, float3 lightDir, half3 lightColor, half attenuation)
            {
                float NdotL = max(0, dot(normal, lightDir));
                return lightColor * NdotL * attenuation;
            }

            // SSS计算函数
            half3 CalculateSSS(float3 normalWS, float3 viewDirWS, float3 lightDirWS, half3 lightColor, 
                  half attenuation, half3 baseColor, float thickness)
            {
                // 1. 基础漫反射项
                float NdotL = max(0, dot(normalWS, lightDirWS));
                
                // 2. 次表面散射项
                // 使用扭曲的光线方向模拟皮肤内部散射
                float3 H = normalize(viewDirWS + normalWS * _SSSDistortion);
                float VdotH = pow(saturate(dot(viewDirWS, -H)), _SSSPower) * _SSSScale;
                
                // 使用厚度值调整散射强度
                float scatterFactor = VdotH * thickness;
                
                // 3. 组合直接光与散射光
                half3 directDiffuse = baseColor * NdotL;
                half3 scattering = _SSSColor.rgb * scatterFactor;
                
                // 最终组合
                half3 result = (directDiffuse + scattering) * lightColor * attenuation;
                
                // 添加环境散射
                half3 ambientScattering = baseColor * _SSSColor.rgb * _SSSAmbient * thickness;
                result += ambientScattering;
                
                return result;
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                // Sample base color and normal map
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half4 baseColor = baseMap * _BaseColor;
                
                // Setup normal mapping
                half3 normalMap = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv));
                normalMap.xy *= _BumpScale;
                
                // Construct TBN matrix
                float3 normalWS = normalize(input.normalWS);
                float3 tangentWS = normalize(input.tangentWS.xyz);
                float3 bitangentWS = normalize(input.bitangentWS);
                float3x3 tangentToWorld = float3x3(tangentWS, bitangentWS, normalWS);
                
                // Transform normal from tangent to world space
                float3 N = TransformTangentToWorld(normalMap, tangentToWorld, true);
                
                // Get main light with shadows
                Light mainLight = GetMainLight(input.shadowCoord);
                float mainLightAttenuation = mainLight.shadowAttenuation * mainLight.distanceAttenuation;
                
                // 基础光照计算
                float NdotL = max(0, dot(N, mainLight.direction));
                
                // 添加阴影偏移和平滑处理
                float adjustedNdotL = NdotL + _ShadowBias1;
                float shadowRamp = smoothstep(0, _ShadowSmoothness, adjustedNdotL);
                
                // 结合实时阴影与NPR阴影
                float nprShadow = lerp(1.0, shadowRamp, _ShadowStrength);
                float finalShadow = min(nprShadow, mainLightAttenuation);
                
                // NPR风格阴影
                half3 ambientLight = _Compensationcolor.rgb; // 使用补偿色调整环境光
                half3 directNPRLighting = baseColor.rgb * mainLight.color * finalShadow;
                half3 ambientLighting = baseColor.rgb * ambientLight;
                half3 nprColor = max(directNPRLighting, ambientLighting);
                
                // 计算SSS
                half thickness = pow(SAMPLE_TEXTURE2D(_ThicknessMap, sampler_ThicknessMap, input.uv).g, _ThicknessMapPower);
                half3 sssColor = CalculateSSS(N, normalize(input.viewDirWS), mainLight.direction, 
                             mainLight.color, mainLightAttenuation, 
                             baseColor.rgb, thickness);
                
                // 添加额外光源的贡献 (Additional Lights)
                half3 additionalLightsColor = half3(0, 0, 0);
                
                #ifdef _ADDITIONAL_LIGHTS
                int additionalLightsCount = GetAdditionalLightsCount();
                for (int i = 0; i < additionalLightsCount; ++i)
                {
                    Light light = GetAdditionalLight(i, input.positionWS);
                    
                    // 添加额外光源的SSS效果
                    half3 additionalSSS = CalculateSSS(N, normalize(input.viewDirWS), light.direction, 
                                               light.color, light.distanceAttenuation * light.shadowAttenuation, 
                                               baseColor.rgb, thickness) * _AdditionalLightsIntensity;
                    
                    additionalLightsColor += additionalSSS;
                }
                #endif
                
                // 混合NPR和SSS光照
                half3 finalColor = lerp(nprColor, sssColor + additionalLightsColor + ambientLighting, 1 - _NPRBlend);
                
                return half4(finalColor, baseColor.a);
            }
            ENDHLSL
        }
        
        // 轮廓描边Pass
        Pass
        {
            Name "Outline"
            Tags { }
            
            Cull Front // 剔除正面，只渲染背面
            
            HLSLPROGRAM
            #pragma vertex OutlineVert
            #pragma fragment OutlineFrag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_OutlineMask);
            SAMPLER(sampler_OutlineMask);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float _OutlineWidth;
                float4 _OutlineColor;
                float _OutlineZOffset;
            CBUFFER_END
            
            Varyings OutlineVert(Attributes input)
            {
                Varyings output;
                
                // 采样轮廓遮罩
                float2 uv = TRANSFORM_TEX(input.uv, _BaseMap);
                float outlineMask = SAMPLE_TEXTURE2D_LOD(_OutlineMask, sampler_OutlineMask, uv, 0).g;
                
                // 将顶点沿法线方向扩张
                float3 posOS = input.positionOS.xyz;
                float3 normalOS = normalize(input.normalOS);
                
                // 根据遮罩调整轮廓宽度
                float outlineWidth = _OutlineWidth * 0.01 * outlineMask;
                
                // 将顶点沿法线方向扩展
                posOS += normalOS * outlineWidth;
                
                // 变换到裁剪空间
                VertexPositionInputs vertexInput = GetVertexPositionInputs(posOS);
                output.positionCS = vertexInput.positionCS;
                
                // 应用Z偏移以避免Z-Fighting
                #if UNITY_REVERSED_Z
                    output.positionCS.z -= _OutlineZOffset * output.positionCS.w;
                #else
                    output.positionCS.z += _OutlineZOffset * output.positionCS.w;
                #endif
                
                output.uv = uv;
                return output;
            }
            
            half4 OutlineFrag(Varyings input) : SV_Target
            {
                // 简单地返回轮廓颜色
                return _OutlineColor;
            }
            ENDHLSL
        }
        
        // 阴影投射Pass
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back
            
            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            
            // Shadow相关的编译指令
            #pragma multi_compile_shadowcaster
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
            };
            
            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
            CBUFFER_END
            
            float3 _LightDirection;
            
            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                // 获取主光源方向
                #if UNITY_REVERSED_Z
                    _LightDirection = -1.0 * _MainLightPosition.xyz;
                #else
                    _LightDirection = _MainLightPosition.xyz;
                #endif
                
                // 应用阴影偏移
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                
                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif
                
                return positionCS;
            }
            
            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }
            
            half4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                return 0;
            }
            
            ENDHLSL
        }
    }
}