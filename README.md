# 碧蓝航线逆向尝试——能代Shader
## 技术栈
- 使用RenderDoc接入安卓设备调试进行逆向，安卓端刷入Google Experience作为系统版本，刷入magisk在termux中开启ro.debuggable（强制允许设备调试），并配以Magisk、HMA和Shizuku等模块进行伪装绕过反作弊检测（但是我确实没有作弊）
## 目前开发特性
通过RenderDoc获取目标Shader变量，结合贴图进行猜想并编写实Shader。对于部分莫名其妙的特性做了删减：如多重Matcap。
- iLM贴图蒙版支持（高光 漫反射 ao）
- 渐变Ramp阴影支持 高光Matcap支持
- 丝袜蒙版支持（还有一堆变量）
- 常规高光Metallic工作流支持
- 自阴影投射/软阴影/方向阴影指定支持
- 阴影Offset支持
- 基于背面剔除的描边
- 屏幕空间边缘光支持
- 面部sdf图支持
- 使用forward+管线多灯光照明支持。
## 删除/精简掉的特性：
- 视差高光/阴影贴图
- 多采样matcap
- 删除部分法线贴图（草台班子.jpg）
- 精简高光对阴影的影响（直接smoothstep）
- 对于部分重映射直接用乘数因子代替线性映射
## 目前属于开发状态：
- 使用stencil眼透
- 头发的KajiyaKay高光模型
- 根据ilm贴图动态切换ramp阴影

## Demo

![Image_1744651565030](Image_1744651565030.png)