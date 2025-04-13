Shader "Custom/SkinStockingsShader"
{
    Properties
    {
        // 基础贴图
        [MainTexture] _BaseMap("基础贴图", 2D) = "white" {}
        [MainColor] _BaseColor("基础颜色", Color) = (1,1,1,1)
        _Cutoff("透明度剪裁阈值", Range(0.0, 1.0)) = 0.5
        
        // 法线贴图
        [Normal] _BumpMap("法线贴图", 2D) = "bump" {}
        _BumpScale("法线强度", Range(0, 2)) = 1.0
        
        // ILM贴图和光照映射
        [Header(ILM)]
        _ILMMap("ILM贴图", 2D) = "white" {}
        _RampMap("渐变贴图", 2D) = "white" {}
        
        // Matcap相关
        [Header(Matcap)]
        _MatcapAlphaMap("高光Matcap贴图A通道", 2D) = "white" {}
        _MatcapRGBMap("高光Matcap贴图rgb通道", 2D) = "white"{}
        _MatcapHighlightTint("Matcap高光色调", Color) = (1,1,1,1)
        _MatcapShadowTint("Matcap阴影色调", Color) = (0.5,0.5,0.5,1)
        
        // 丝袜相关
        [Header(Stocking)]
        _StockingMap("丝袜贴图", 2D) = "white" {}
        _StockingMaskMap("丝袜蒙版贴图", 2D) = "white" {}
        _StockingEnable("丝袜启用", Range(0, 1)) = 1
        _StockingColor("丝袜颜色", Color) = (0,0,0,1)
        _StockingShadowColor("丝袜阴影颜色", Color) = (0,0,0,1)
        _StockingShadingRemap("丝袜阴影重映射", Vector) = (0,1,0,1)
        _StockingPower("丝袜效果强度", Range(0, 10)) = 1
        _StockingFresnelTint("丝袜菲涅尔色调", Color) = (1,1,1,1)
        _StockingFresnelPower("丝袜菲涅尔强度", Range(0, 10)) = 1
        _StockingStretching("丝袜拉伸", Range(-1, 1)) = 0
        _StockingThicknessMulti("丝袜厚度乘数", Range(0, 2)) = 1
        _StockingThickness("丝袜厚度", Range(0, 1)) = 0.5
        
        // 皮肤相关
        [Header(Skin)]
        _SkinPower("皮肤效果强度", Range(0, 10)) = 1
        _SkinTransmittanceTint("皮肤透射色调", Color) = (1,0.5,0.3,1)
        
        // 高光相关
        [Header(Specular)]
        _Shininess("光泽度", Range(0, 1)) = 0.7
        _SpecularRemap("高光重映射", Vector) = (0,1,0,1)
        _SpecularSize("高光大小", Range(0, 1)) = 1
        _ActualSpecularTint("实际高光色调", Color) = (1,1,1,1)
        _BaseColorAffected("基础颜色影响", Range(0, 1)) = 0.5
        _SpecularAttenRemap("高光衰减重映射", Vector) = (0,0,1,0)
        
        
        // 阴影相关
        [Header(Shadow)]
        _SelfShadowEnable("自阴影启用", Range(0, 1)) = 1
        _ShadingOffsetRemap("阴影偏移重映射强度", Range(0,0.5)) = 0.1
        _ShadingOffsetStrength("阴影偏移强度", Range(0, 1)) = 0.5
        _DirShadowEnable("方向阴影启用", Range(0, 1)) = 1
        _DirShadowRemap("方向阴影重映射", Range(0,0.5)) = 0.1
        _DirShadowStrength("方向阴影强度", Range(0, 1)) = 1
        _DirShadowTint("方向阴影色调", Color) = (0.5,0.5,0.5,1)
        _ShadowAffectRemap("阴影影响重映射", Vector) = (0,1,0,1)
        
        
        //描边相关
        [Header(Outline)]
        _OutlineWidth ("Outline Width", Range(0, 0.002)) = 0.00005
        _OutlineColor ("Outline Color", Color) = (0.5, 0.5, 0.5, 1)
        _OutlineZOffset ("Z Offset", Range(0, 1)) = 0.0001
        _OutlineMask ("Outline Mask (黑色区域不显示描边)", 2D) = "white" {}
        
        // 边缘光相关
        [Header(Rimlight)]
        _ScreenSpaceRimShadowEnable("屏幕空间边缘阴影启用", Range(0, 1)) = 0
        _DisableScreenSpaceRim("启用屏幕空间边缘光", Range(0, 1)) = 0
        _ActualRimLightTint("实际边缘光色调", Color) = (1,1,1,1)
        _RimlightThreshold("边缘光阈值", Range(0, 1)) = 0.5
        _RimlightFeather("边缘光羽化", Range(0, 1)) = 0.1
        
        // 发光相关和附加光
        [Header(Emission_AdditiveLight)]
        _ActualEmissionTint("实际发光色调", Color) = (0,0,0,0)
        _AdditiveLightIntensity("附加光强度", Range(0, 2)) = 1
    }
    
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque" 
            "RenderPipeline" = "UniversalPipeline" 
            "Queue" = "Geometry"
        }
        
        LOD 300

        
        Pass
        {
            Name "BLHX_General"
            Tags { "LightMode" = "UniversalForward" }
            
            Blend Off
            ZWrite On
            Cull Back
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            // 编译选项
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            
            // 包含文件
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
            // 纹理和采样器
            TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);            SAMPLER(sampler_BumpMap);
            TEXTURE2D(_ILMMap);             SAMPLER(sampler_ILMMap);
            TEXTURE2D(_RampMap);            SAMPLER(sampler_RampMap);
            TEXTURE2D(_CombineMatcapMap);   SAMPLER(sampler_CombineMatcapMap);
            TEXTURE2D(_MatcapAlphaMap);     SAMPLER(sampler_MatcapAlphaMap);
            TEXTURE2D(_MatcapRGBMap);  SAMPLER(sampler_MatcapRGBMap);
            TEXTURE2D(_StockingMap);        SAMPLER(sampler_StockingMap);
            TEXTURE2D(_StockingMaskMap);    SAMPLER(sampler_StockingMaskMap);
            TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
            
            // 常量缓冲区
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float _Cutoff;
                float _BumpScale;
                float _CombineMatcap;
                float _MatcapMultiplyEnable;
                float4 _MatcapHighlightTint;
                float4 _MatcapShadowTint;
                float _MatcapMultiIntensity;
                float _StockingEnable;
                float4 _StockingColor;
                float4 _StockingShadowColor;
                float4 _StockingShadingRemap;
                float _StockingPower;
                float4 _StockingFresnelTint;
                float _StockingFresnelPower;
                float _StockingStretching;
                float _StockingThicknessMulti;
                float _StockingThickness;
                float _SkinPower;
                float4 _SkinTransmittanceTint;
                float _Shininess;
                float4 _SpecularRemap;
                float _SpecularSize;
                float4 _ActualSpecularTint;
                float _BaseColorAffected;
                float4 _SpecularAttenRemap;
                float _SpecialHighlightEnable;
                float _ParallaxScale;
                float _HighlightSize;
                float4 _ActualSpecialHighlightTint;
                float _SelfShadowEnable;
                float _ShadingOffsetRemap;
                float _ShadingOffsetStrength;
                float _DirShadowEnable;
                float _DirShadowRemap;
                float _DirShadowStrength;
                float4 _DirShadowTint;
                float4 _ShadowAffectRemap;
                float _ScreenSpaceRimShadowEnable;
                float _DisableScreenSpaceRim;
                float4 _ActualRimLightTint;
                float _RimlightThreshold;
                float _RimlightFeather;
                float4 _ActualEmissionTint;
                float _AdditiveLightIntensity;
                float4 _ShadowingRemap;
            CBUFFER_END
            
            // 顶点着色器输入
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
            };
            
            // 顶点着色器输出/片段着色器输入
            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                float4 tangentWS    : TEXCOORD3;
                float3 bitangentWS  : TEXCOORD4;
                float3 viewDirWS    : TEXCOORD5;
                float3 lightDirWS   : TEXCOORD6;
                float3 viewReflectWS : TEXCOORD7;
                float4 screenPos    : TEXCOORD8;
                float3 vertLighting : TEXCOORD9;
            };
            
            // 顶点着色器
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                // 转换空间坐标
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
                // 设置输出
                Light mainlight =  GetMainLight();
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.normalWS = normalInput.normalWS;
                output.tangentWS = float4(normalInput.tangentWS, input.tangentOS.w);
                output.bitangentWS = normalInput.bitangentWS;
                output.viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
                output.lightDirWS = mainlight.direction;
                output.viewReflectWS = reflect(-output.viewDirWS, output.normalWS);
                output.screenPos = ComputeScreenPos(vertexInput.positionCS);
                
                // 顶点光照
                float3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                output.vertLighting = vertexLight;
                
                return output;
            }
            
            // 片段着色器
            half4 frag(Varyings input) : SV_Target
            {
                // 采样基础纹理
                float2 uv = input.uv;
                float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv) * _BaseColor;
                
                // 透明度裁剪
                clip(baseColor.a - _Cutoff);
                
                // 法线贴图处理
                float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv), _BumpScale);
                float3 normalWS = TransformTangentToWorld(normalTS, 
                    half3x3(input.tangentWS.xyz, input.bitangentWS, input.normalWS));
                normalWS = normalize(normalWS);
                
                // ILM贴图
                float4 ilmMap = SAMPLE_TEXTURE2D(_ILMMap, sampler_ILMMap, uv);
                
                // 计算光照方向和视线方向
                float3 viewDirWS = normalize(input.viewDirWS);
                float3 lightDirWS = normalize(input.lightDirWS);
                float3 viewReflectWS = normalize(input.viewReflectWS);
                
                // 主光源
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(input.positionWS));
                float3 mainLightColor = mainLight.color * mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                
                // 法线点乘光照方向 (N·L)
                float NdotL = dot(normalWS, lightDirWS);
                NdotL = saturate(NdotL);
                
                // 计算视线与法线夹角 (N·V)
                float NdotV = dot(normalWS, viewDirWS);
                NdotV = saturate(NdotV);
                
                // 边缘光计算
                float oneMinusNdotV = 1.0 - NdotV;

                // 定义边缘光的起始和结束阈值
                float rimStart = _RimlightThreshold - _RimlightFeather; // 开始过渡的点
                float rimEnd = _RimlightThreshold; // 结束过渡的点

                // 在过渡区间内进行平滑插值
                float rimFactor = smoothstep(rimStart, rimEnd, oneMinusNdotV);
                // 或者手动实现smoothstep:
                // float rimFactor = saturate((oneMinusNdotV - rimStart) / (rimEnd - rimStart));
                // rimFactor = rimFactor * rimFactor * (3.0 - 2.0 * rimFactor); // 平滑过渡

                // 应用ILM控制
                rimFactor = rimFactor * ilmMap.y;
                
               // 阴影因子计算
                float shadowOffset = ilmMap.y * _ShadingOffsetRemap;
                shadowOffset = saturate(shadowOffset);
                shadowOffset = shadowOffset - 1.0;
                shadowOffset = _ShadingOffsetStrength * shadowOffset + 1.0;
                float shadowFactor = NdotL * shadowOffset;
                shadowFactor = saturate(shadowFactor);

                // 方向阴影
                float dirShadow = mainLight.shadowAttenuation;
                dirShadow = dirShadow * _DirShadowRemap;
                dirShadow = saturate(dirShadow);
                dirShadow = dirShadow - 1.0;
                // 修正：加回1.0，使范围与shadowOffset一致
                dirShadow = _DirShadowStrength * _DirShadowEnable * dirShadow + 1.0;
                
                
                // 最终阴影因子
                float finalShadow = shadowFactor * dirShadow*_SelfShadowEnable;
                
                // 渐变贴图采样
                float2 rampUV;
                // 渐变贴图X坐标（水平方向）- 用于光照明暗过渡
                rampUV.x = finalShadow; 

                // 渐变贴图Y坐标（垂直方向）- 用于选择不同的材质渐变带
                // rampUV.y = (ilmMap.x + 0.125) * 0.5;
                rampUV.y = (0) * 0.5;

                // 采样渐变贴图
                float3 rampColor = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, rampUV).rgb;
                
                // 阴影ramp影响颜色
                float3 shadowColor = rampColor;
                
                // Matcap效果 这一段的matcap主要是用于高光模拟
                float3 viewReflectVS = mul((float3x3)UNITY_MATRIX_V, input.viewReflectWS);
                float2 matcapUV = normalize(float3(viewReflectVS.xy, viewReflectVS.z + 1.0)).xy * 0.5 + 0.5;
                //float2 matcapUV = normalize(float3(input.viewReflectWS.xy, input.viewReflectWS.z + 1.0)).xy * 0.5 + 0.5;
                //float2 matcapUV = (input.viewReflectWS.xy * 0.5) + 0.5;
                float matcapalpha = SAMPLE_TEXTURE2D(_MatcapAlphaMap, sampler_MatcapAlphaMap, matcapUV).a;
                float3 matcap0 = SAMPLE_TEXTURE2D(_MatcapRGBMap, sampler_MatcapRGBMap, matcapUV).rgb;
                
                float3 matcapColor;
                float matcapAlpha;
                
                matcapColor = matcap0.rgb;
                matcapAlpha = matcapalpha;
                
                // 计算Matcap效果影响
                float matcapIntensity = ilmMap.x;
                matcapIntensity = saturate(matcapIntensity);
                matcapIntensity = matcapAlpha * matcapIntensity;
                
                float3 matcapTint = lerp(_MatcapShadowTint.rgb, _MatcapHighlightTint.rgb, matcapIntensity);
                //float3 matcapTint = matcapColor*matcapIntensity;
                
                
                // 应用Matcap和特殊高光到基础颜色
                float3 colorWithMatcap = baseColor.rgb * (1.0 + matcapTint);
                float3 finalBaseColor = colorWithMatcap;
                
                // 丝袜效果
                float4 stockingColor = SAMPLE_TEXTURE2D(_StockingMap, sampler_StockingMap, uv) * _StockingColor;
                float4 stockingMask = SAMPLE_TEXTURE2D(_StockingMaskMap, sampler_StockingMaskMap, uv);
                
                // 丝袜阴影计算
                float stockingShadow = finalShadow * _StockingShadingRemap.z + _StockingShadingRemap.w;
                stockingShadow = saturate(stockingShadow);
                stockingShadow = stockingShadow * stockingShadow;
                stockingShadow = stockingShadow * (3.0 - 2.0 * stockingShadow);
                // float3 stockingShadowColor = lerp(_StockingShadowColor.rgb, float3(1.0, 1.0, 1.0), stockingShadow);
                float3 stockingShadowColor = lerp(_StockingShadowColor.rgb, float3(1.0, 1.0, 1.0), stockingShadow);
                
                // 丝袜菲涅尔效果
                float stockingFresnel = 1.0 - saturate(NdotV);
                stockingFresnel = max(stockingFresnel, 0.003) * (1.0 - stockingMask.w);
                stockingFresnel = stockingFresnel * _StockingFresnelPower;
                float3 stockingFresnelTint = lerp(float3(1.0, 1.0, 1.0), _StockingFresnelTint.rgb, stockingFresnel);
                
                // 丝袜厚度
                float stockingThickness = stockingMask.z + stockingMask.y * _StockingStretching * _StockingThicknessMulti;
                stockingThickness = saturate(stockingThickness);
                stockingThickness = stockingThickness * (3.0 - 2.0 * stockingThickness) - 1.0;
                
                float skinEffect = pow(NdotV, _SkinPower);
                stockingThickness = stockingThickness * skinEffect + 1.0;
                stockingThickness = stockingThickness * _StockingThickness;
                stockingThickness = saturate(stockingThickness);
                
                float stockingOpacity = stockingFresnel * (1.0 - stockingThickness) + stockingThickness;
                
                // 皮肤透射
                float3 skinTransmittance = finalBaseColor * shadowColor * _SkinTransmittanceTint.rgb;
                
                // 组合丝袜和皮肤效果
                float3 stockingFinalColor = stockingColor.rgb * stockingShadowColor * stockingFresnelTint;
                float3 skinStockingColor = lerp(skinTransmittance, stockingFinalColor, stockingOpacity);
                float3 finalDiffuse = lerp(finalBaseColor * shadowColor, skinStockingColor, stockingMask.x * _StockingEnable);
                
                // 高光计算
                float3 viewDir = normalize(_WorldSpaceCameraPos - input.positionWS);
                float3 halfVector = normalize(input.lightDirWS + viewDir);
                float NdotH = max(dot(input.normalWS, halfVector), 0.0);
                float specPower = exp2(_Shininess * 11.0) + 1.0; // 更符合物理的高光指数映射
                float specular = pow(NdotH, specPower);

                //蒙版指定增强高光
                float specularMask = ilmMap.z;
                specular = specular * specularMask * _SpecularSize;
                // 阴影对高光的影响
                float specShadowMask = finalShadow * _ShadowAffectRemap.z + _ShadowAffectRemap.w;
                specular = specular * specShadowMask;
                specular = specular * _SpecularAttenRemap.z + _SpecularAttenRemap.w;
                specular = saturate(specular);
                
                // 高光颜色
                float3 specularColor = specular * _ActualSpecularTint.rgb;
                float3 baseColorEffect = max(finalBaseColor, float3(0.04, 0.04, 0.04));
                baseColorEffect = baseColorEffect - float3(1.0, 1.0, 1.0);
                baseColorEffect = _BaseColorAffected * baseColorEffect + float3(1.0, 1.0, 1.0);
                specularColor = specularColor * baseColorEffect;
                
                // 附加光源处理
                float3 additionalLighting = float3(0, 0, 0);
                int additionalLightsCount = GetAdditionalLightsCount();
                for (int i = 0; i < additionalLightsCount; i++)
                {
                    Light light = GetAdditionalLight(i, input.positionWS);
                    float addNdotL = dot(normalWS, light.direction);
                    addNdotL = saturate(addNdotL);
                    additionalLighting += light.color * light.distanceAttenuation * light.shadowAttenuation * addNdotL;
                }
                additionalLighting *= _AdditiveLightIntensity;
                
                // 边缘光
                float rimShadow = finalShadow;
                float3 rimLight = _ActualRimLightTint.rgb * rimFactor*_DisableScreenSpaceRim;
                //float3 rimLight = _ActualRimLightTint.rgb * rimFactor * rimShadow;
                //rimshadow出了问题
                
                // 加法Matcap
                float matcapAddMask = ilmMap.x;
                matcapAddMask = saturate(matcapAddMask);
                float3 matcapAddColor = matcapColor * matcapAddMask;
                
                // 最终颜色计算
                float3 finalColor = finalDiffuse * mainLightColor;
                 finalColor += baseColor.rgb * additionalLighting * 0.318309873;
                //finalColor += specularColor * mainLightColor;
                finalColor += specularColor * 1;
                 finalColor += _ActualEmissionTint.rgb * baseColor.rgb;
                 finalColor += rimLight;
                finalColor = finalColor + matcapAddColor*0.1;
                
                // 最终透明度计算
                float finalAlpha;
                if (_StockingEnable > 0)
                {
                    finalAlpha = lerp(baseColor.a, stockingOpacity, stockingMask.w * _StockingEnable);
                }
                else
                {
                    // finalAlpha = baseColor.a;
                    finalAlpha = 1;
                }
                
                return half4(finalColor, finalAlpha);
            }
            ENDHLSL
        }
        
        // Outline Pass
        Pass
        {
            Name "BLHX_Outline"
            Tags {"LightMode" = "SRPDefaultUnlit"}
            
            Cull Front // 只渲染背面
            ZWrite On
            
            HLSLPROGRAM
            #pragma vertex OutlineVertex
            #pragma fragment OutlineFragment
            
            // 包含文件
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            // 纹理和采样器
            TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_OutlineMask);        SAMPLER(sampler_OutlineMask);
            
            // 常量缓冲区 - 只包含描边所需的属性
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float _Cutoff;
                float _BumpScale;
                float _OutlineWidth;
                float4 _OutlineColor;
                float _OutlineZOffset;
                // 其他相关变量...
            CBUFFER_END
            
            // 顶点着色器输入
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
            };
            
            // 顶点着色器输出/片段着色器输入
            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };
            
            // 顶点着色器
            Varyings OutlineVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                // 视图空间描边实现
                // 先转换到世界空间
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                // 转换到视图空间 (View Space)
                float3 positionVS = TransformWorldToView(positionWS);
                float3 normalVS = TransformWorldToViewDir(normalWS, true);
                
                // 在视图空间扩展顶点
                positionVS += normalVS * _OutlineWidth;
                
                // 转换回裁剪空间
                output.positionCS = TransformWViewToHClip(positionVS);
                
                // 应用Z偏移以防止Z-fighting
                #if UNITY_REVERSED_Z
                    output.positionCS.z -= _OutlineZOffset * output.positionCS.w;
                #else
                    output.positionCS.z += _OutlineZOffset * output.positionCS.w;
                #endif
                
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                
                return output;
            }
            
            // 片段着色器
            half4 OutlineFragment(Varyings input) : SV_Target
            {
                // 基础颜色采样用于透明度裁剪
                float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                clip(baseColor.a - _Cutoff);
                
                // 采样描边蒙版
                float outlineMask = SAMPLE_TEXTURE2D(_OutlineMask, sampler_OutlineMask, input.uv).r;
                
                // 应用蒙版（黑色区域不显示描边）
                clip(outlineMask - 0.01);
                
                return _OutlineColor;
            }
            ENDHLSL
        }

        // ShadowCaster Pass
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float _Cutoff;
            CBUFFER_END
            
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

            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, 0));
            
                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
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
                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
                clip(baseColor.a - _Cutoff);
                return 0;
            }
            ENDHLSL
        }
        
        // DepthOnly Pass
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float _Cutoff;
            CBUFFER_END

            struct Attributes
            {
                float4 position     : POSITION;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
            };

            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = TransformObjectToHClip(input.position.xyz);
                return output;
            }

            half4 DepthOnlyFragment(Varyings input) : SV_TARGET
            {
                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
                clip(baseColor.a - _Cutoff);
                return 0;
            }
            ENDHLSL
        }

        //Depth Normal Pass
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap); SAMPLER(sampler_BumpMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float _Cutoff;
                float _BumpScale;
            CBUFFER_END
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 tangentWS    : TEXCOORD2;
                float3 bitangentWS  : TEXCOORD3;
            };

            Varyings DepthNormalsVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = normalInput.normalWS;
                output.tangentWS = normalInput.tangentWS;
                output.bitangentWS = normalInput.bitangentWS;
                
                return output;
            }

            half4 DepthNormalsFragment(Varyings input) : SV_TARGET
            {
                // 透明度剪裁
                float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                clip(baseMap.a * _BaseColor.a - _Cutoff);
                
                // 法线贴图
                float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv), _BumpScale);
                float3 normalWS = TransformTangentToWorld(normalTS, 
                    half3x3(input.tangentWS, input.bitangentWS, input.normalWS));
                normalWS = NormalizeNormalPerPixel(normalWS);
                
                // 输出编码的法线和深度
                return float4(normalWS * 0.5 + 0.5, 0);
            }
            ENDHLSL
        }


    }
    
    FallBack "Universal Render Pipeline/Lit"
}