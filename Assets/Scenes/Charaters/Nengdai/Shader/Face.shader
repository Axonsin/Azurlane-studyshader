Shader "Custom/CartoonFaceShader"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _FaceShadingGradeMap ("Face Shadow Map", 2D) = "white" {}
        _Compensationcolor("最弱环境光阴影补偿色",Color) = (1,1,1,1)
        _AddLipTexture("Add LipTexture", 2D) = "white" {}
        
        [Header(Face Settings)]
        _FaceShadingOffset ("Face Shading Offset", Range(-1, 1)) = 0
        _FaceShadingSoftness ("Face Shading Softness", Range(0, 0.1)) = 0.02
        _FaceGradient ("Face Gradient Intensity", Range(0, 1)) = 0.5
        _FaceGradientColor ("Face Gradient Color", Color) = (1, 0.8, 0.8, 1)
        _FaceGradientOffset ("Face Gradient Offset", Range(-1, 1)) = 0
        _FaceLocalHeightBound ("Face Local Height Bound (X:Scale, Y:Offset)", Vector) = (1, 0, 0, 0)
        _CharacterForward ("Character Forward", Vector) = (0, 0, -1, 0)
        _CharacterUp ("Character Up", Vector) = (0, 1, 0, 0)
        
        [Header(Face Shadow Settings)]
        _FaceShadowSampleCount ("Face Shadow Sample Count", Range(1, 5)) = 3
        _FaceShadowThreshold ("Face Shadow Threshold", Range(0, 1)) = 0.5
        _FaceShadowSmoothness ("Face Shadow Smoothness", Range(0, 0.5)) = 0.2
        _FaceShadowStrength ("Face Shadow Strength", Range(0, 1)) = 0.8
        
        [Header(Face Dynamic Tracking)]
        _FaceForward ("Face Forward Vector", Vector) = (0, 0, 1, 0)
        _FaceUp ("Face Up Vector", Vector) = (0, 1, 0, 0)
        
        [Header(Face Shadow Blending)]
        _SdfShadowDominance("SDF阴影主导度", Range(0, 1)) = 0.7
        _RealTimeShadowOffset("实时阴影偏移", Range(0, 1)) = 0.3
        
        [Header(Outline)]
        _OutlineWidth ("Outline Width", Range(0, 0.5)) = 0.02
        _OutlineColor ("Outline Color", Color) = (0.5, 0.5, 0.5, 1)
        _OutlineZOffset ("Z Offset", Range(0, 1)) = 0.0001
        _OutlineMask ("Outline Mask (黑色区域不显示描边)", 2D) = "white" {}
        
        [Header(PBR Settings)]
        _LambertIntensity ("Lambert Lighting Intensity/目前已弃用，更换为SSS", Range(0, 1)) = 0.5
        _NPRBlend ("NPR 与 PBR 混合程度", Range(0, 1)) = 0.7
        [Toggle(_ADDITIONAL_LIGHTS)] _AdditionalLights ("Enable Additional Lights", Float) = 1
        _AdditionalLightsIntensity ("Additional Lights Intensity", Range(0, 1)) = 0.5
        
        [Header(SSS Settings)]
        _SSSColor ("次表面散射颜色", Color) = (1.0, 0.4, 0.4, 1.0)
        _SSSScale ("次表面散射强度", Range(0, 10)) = 1.0
        _SSSPower ("次表面散射衰减", Range(0.1, 10)) = 2.0
        _SSSDistortion ("散射法线扭曲", Range(0, 1)) = 0.5
        _SSSAmbient ("环境散射强度", Range(0, 2)) = 0.2
        _ThicknessMap ("厚度贴图(G通道)", 2D) = "white" {}
        _ThicknessMapPower ("厚度影响强度", Range(0, 2)) = 1.0
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
                float3 positionLS : TEXCOORD6; // Local space position for face height
                float4 shadowCoord : TEXCOORD7; // Shadow coordinates
            };
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
            TEXTURE2D(_FaceShadingGradeMap);
            SAMPLER(sampler_FaceShadingGradeMap);
            TEXTURE2D(_ThicknessMap);
            SAMPLER(sampler_ThicknessMap);
            TEXTURE2D(_AddLipTexture);
            SAMPLER(sampler_AddLipTexture);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float _BumpScale;
                float _FaceShadingOffset;
                float _FaceShadingSoftness;
                float _FaceGradient;
                float4 _FaceGradientColor;
                float _FaceGradientPow;
                float _FaceGradientOffset;
                float4 _FaceLocalHeightBound;
                float4 _CharacterForward;
                float4 _CharacterUp;
                float4 _Compensationcolor;
                float _FaceShadowSampleCount;
                float _FaceShadowThreshold;
                float _FaceShadowSmoothness;
                float _FaceShadowStrength;
                float4 _FaceForward;
                float4 _FaceUp;
                float _SdfShadowDominance;
                float _RealTimeShadowOffset;
                // PBR参数
                float _LambertIntensity;
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
                output.positionLS = input.positionOS.xyz;
                
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

            //SSS
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
            
            float CalculateFaceAverageShadow(float3 positionWS, float3 normalWS)
            {
                // 预定义面部偏移点（相对于中心点）
                float3 offsets[5] = {
                    float3(0, 0.06, 0.04),   // 前额
                    float3(0, 0, 0.05),      // 鼻尖
                    float3(0, -0.05, 0.04),  // 下巴
                    float3(0.03, 0, 0.04),   // 右脸颊
                    float3(-0.03, 0, 0.04)   // 左脸颊
                };
                
                int sampleCount = min(5, max(1, (int)_FaceShadowSampleCount));
                float shadowSum = 0;
                
                for(int i = 0; i < sampleCount; i++)
                {
                    // 使用法线方向和偏移计算采样点
                    float3 offset = offsets[i];
                    // 将偏移从模型空间转换到世界空间
                    float3 offsetWS = offset.x * cross(float3(0,1,0), normalWS) + 
                                      offset.y * float3(0,1,0) + 
                                      offset.z * normalWS;
                    
                    float3 samplePos = positionWS + offsetWS * 0.1; // 缩放系数控制偏移量
                    float4 shadowCoord = TransformWorldToShadowCoord(samplePos);
                    Light sampleLight = GetMainLight(shadowCoord);
                    shadowSum += sampleLight.shadowAttenuation;
                }
                
                // 计算平均值并应用平滑过渡
                float avgShadow = shadowSum / float(sampleCount);
                return smoothstep(_FaceShadowThreshold - _FaceShadowSmoothness, 
                                 _FaceShadowThreshold + _FaceShadowSmoothness, 
                                 avgShadow);
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                
                // Sample base color and normal map
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half4 baseColor = baseMap * _BaseColor;
                
                // Sample face shadow mask R代表sdf，G代表蒙版
                half4 faceShadowMapL = SAMPLE_TEXTURE2D(_FaceShadingGradeMap, sampler_FaceShadingGradeMap, input.uv);
                
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
                float3 L = mainLight.direction;
                float mainLightAttenuation = mainLight.shadowAttenuation * mainLight.distanceAttenuation;
                
                
                // Character orientation vectors
                _CharacterForward = _FaceForward;
                _CharacterUp = _FaceUp;
                float3 Front = normalize(_CharacterForward.xyz);
                float3 UP = normalize(_CharacterUp.xyz);
                float3 Left = normalize(cross(UP, Front));
                float3 Right = -Left;
                
                // Flatten vectors to xz plane for 2D face shadow calculation
                float3 FrontXZ = normalize(float3(Front.x, 0, Front.z));
                float3 LeftXZ = normalize(float3(Left.x, 0, Left.z));
                float3 RightXZ = normalize(float3(Right.x, 0, Right.z));
                float3 LightXZ = normalize(float3(L.x, 0, L.z));
                
                // Calculate dot products for face shading
                float FrontL = dot(FrontXZ, LightXZ);
                float LeftL = dot(LeftXZ, LightXZ);
                float RightL = dot(RightXZ, LightXZ);
                
                // Shadow map value (typically stored in red channel)
                float shadowMapValueL = 1-faceShadowMapL.r;
                float shadowMapMask = faceShadowMapL.g;
                
                // Calculate face shadow
                // If light comes from behind (FrontL < 0), apply full shadow
                // Otherwise check left and right sides with lightmap value
                float leftCheck = (shadowMapValueL > LeftL) ? 1.0 : 0.0;
                float rightCheck = (1.0 - shadowMapValueL < RightL) ? 0.0 : 1.0;
                
                // Final shadow attenuation - only apply if light is in front
                float lightAttenuation = (FrontL > 0) ? min(leftCheck, rightCheck) : 0.0;
                
               // Apply softness to shadow edge if needed
                float softShadow = lightAttenuation;
                if (_FaceShadingSoftness > 0) {
                    // 确定光源主要来自哪一侧
                    bool lightFromLeft = LeftL > RightL;
                    
                    // 根据光源位置选择正确的软化计算方式
                    float softEdge;
                    if (lightFromLeft) {
                        // 光源从左侧照射，使用左侧柔和过渡
                        softEdge = (shadowMapValueL - LeftL + _FaceShadingOffset) / max(0.0001, _FaceShadingSoftness);
                    } else {
                        //更新并反转uv 采样反方向的阴影图
                        half4 faceShadowMapR = SAMPLE_TEXTURE2D(_FaceShadingGradeMap, sampler_FaceShadingGradeMap, float2((1-input.uv.x),input.uv.y));
                        float shadowMapValueR = 1-faceShadowMapR.r;
                        // 光源从右侧照射，使用右侧柔和过渡
                        softEdge = ( shadowMapValueR - RightL + _FaceShadingOffset) / max(0.0001, _FaceShadingSoftness);
                    }
                    //乘以蒙版
                    softEdge = saturate(softEdge)*shadowMapMask;
                    softEdge = softEdge * softEdge * (3.0 - 2.0 * softEdge); // Smoothstep
                    
                    // 只在光线从前方照射时应用软化
                    softShadow = (FrontL > 0) ? softEdge : 0.0;
                }
                
                // 原始NPR光照
                float faceShadowFactor = CalculateFaceAverageShadow(input.positionWS, normalWS);
                float sdfShadow = softShadow;//将面部SDF和外部的实时阴影分开处理
                float realTimeShadow = faceShadowFactor;
                float sdfDominance = _SdfShadowDominance;
                float rtOffset = _RealTimeShadowOffset;
                //float combinedShadow = softShadow * lerp(1.0, faceShadowFactor, _FaceShadowStrength);
                //float combinedShadow = min(sdfShadow + (1.0 - _FaceShadowStrength), realTimeShadow + _FaceShadowThreshold);
                float combinedShadow = lerp(
                    min(sdfShadow, realTimeShadow + rtOffset), // 实时阴影会减弱SDF阴影
                    sdfShadow, // 纯SDF阴影
                    sdfDominance // 控制两者混合程度
                );

                half3 ambientLight = _Compensationcolor.rgb; // 使用补偿色调整环境光
                // half3 directNPRLighting = baseColor.rgb * mainLight.color * combinedShadow;
                half3 directNPRLighting = baseColor.rgb * mainLight.color * combinedShadow;
                half3 ambientLighting = baseColor.rgb * ambientLight;
                half3 nprColor = max(directNPRLighting, ambientLighting);
                
                // 计算Lambert漫反射
                // half3 lambertColor = baseColor.rgb * CalculateLambert(N, mainLight.direction, mainLight.color, mainLightAttenuation) * _LambertIntensity;
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
                    
                    // Lambert漫反射
                    half3 additionalLambert = CalculateLambert(N, light.direction, light.color, light.distanceAttenuation * light.shadowAttenuation);
                    
                    additionalLightsColor += baseColor.rgb * additionalLambert * _AdditionalLightsIntensity;
                }
                #endif
                
                // 混合NPR和PBR光照
                half3 finalColor = lerp(nprColor, sssColor + additionalLightsColor + ambientLighting, 1 - _NPRBlend);
                half3 AddLipMap = SAMPLE_TEXTURE2D(_AddLipTexture, sampler_AddLipTexture, input.uv);
                // 应用面部渐变
                finalColor = lerp(finalColor, _FaceGradientColor.rgb, _FaceGradient * 0.5)*AddLipMap;
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
        
        // 阴影投射Pass - 使用更兼容的实现
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