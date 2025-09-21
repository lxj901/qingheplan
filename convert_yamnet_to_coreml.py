#!/usr/bin/env python3
"""
将 YAMNet TensorFlow 模型转换为 Core ML 格式
"""

import tensorflow as tf
import coremltools as ct
import numpy as np
import os

def convert_yamnet_to_coreml():
    """转换 YAMNet 模型为 Core ML 格式"""
    
    # 模型路径
    yamnet_model_path = "qinghe/Models/Audio/yamnet-tensorflow2-yamnet-v1"
    output_path = "qinghe/qinghe/YAMNet.mlmodel"
    
    print("🔄 开始转换 YAMNet 模型...")
    
    try:
        # 加载 TensorFlow 模型
        print("📥 加载 TensorFlow 模型...")
        loaded_model = tf.saved_model.load(yamnet_model_path)

        # 获取推理函数
        infer = loaded_model.signatures['serving_default']

        # 创建示例输入 (YAMNet 期望 16kHz 音频)
        # 通常是 0.975 秒的音频 (15600 个样本)
        example_input = np.random.randn(15600).astype(np.float32)

        print("🔍 测试模型推理...")
        # 测试推理
        output = infer(tf.constant(example_input))
        print(f"✅ 模型输出形状: {[k + ': ' + str(v.shape) for k, v in output.items()]}")

        # 转换为 Core ML
        print("🔄 转换为 Core ML 格式...")

        # 直接使用 SavedModel 路径进行转换
        # YAMNet 的输入名称是 "waveform"
        coreml_model = ct.convert(
            yamnet_model_path,
            inputs=[ct.TensorType(shape=(15600,), dtype=np.float32, name="waveform")],
            source="tensorflow",
            convert_to="mlprogram",  # 使用新的 ML Program 格式
            compute_precision=ct.precision.FLOAT16,  # 使用 FP16 减小模型大小
        )
        
        # 设置模型元数据
        coreml_model.short_description = "YAMNet audio classification model"
        coreml_model.author = "Google Research"
        coreml_model.license = "Apache 2.0"
        coreml_model.version = "1.0"
        
        # 设置输入描述
        coreml_model.input_description["waveform"] = "Audio waveform (16kHz, mono, 0.975s = 15600 samples)"
        
        # 设置输出描述
        for output_name in coreml_model.output_description:
            if "scores" in output_name.lower() or "prediction" in output_name.lower():
                coreml_model.output_description[output_name] = "Classification scores for 521 audio classes"
            elif "embedding" in output_name.lower():
                coreml_model.output_description[output_name] = "Audio embedding features"
        
        # 保存模型
        print(f"💾 保存 Core ML 模型到: {output_path}")
        coreml_model.save(output_path)
        
        print("✅ YAMNet 模型转换完成！")
        
        # 验证转换后的模型
        print("🔍 验证转换后的模型...")
        loaded_model = ct.models.MLModel(output_path)
        spec = loaded_model.get_spec()
        
        print("📋 模型信息:")
        print(f"  输入: {[f'{inp.name}: {inp.type}' for inp in spec.description.input]}")
        print(f"  输出: {[f'{out.name}: {out.type}' for out in spec.description.output]}")
        
        return True
        
    except Exception as e:
        print(f"❌ 转换失败: {e}")
        return False

if __name__ == "__main__":
    success = convert_yamnet_to_coreml()
    if success:
        print("🎉 转换成功！现在可以在 iOS 应用中使用 YAMNet 模型了。")
    else:
        print("💥 转换失败，请检查错误信息。")
