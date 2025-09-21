#!/usr/bin/env python3
"""
Download Silero VAD model using PyTorch Hub (official method)
This bypasses network issues with direct downloads and uses the official API.
"""
import os
import sys
import torch
import torchaudio
from pathlib import Path

def main():
    # Set paths
    script_dir = Path(__file__).parent
    root_dir = script_dir.parent.parent
    models_dir = root_dir / "qinghe" / "Models" / "Audio"
    models_dir.mkdir(parents=True, exist_ok=True)
    
    onnx_path = models_dir / "SileroVAD.onnx"
    jit_path = models_dir / "SileroVAD.jit"
    
    print("🔄 Downloading Silero VAD using PyTorch Hub...")
    
    try:
        # Download using official PyTorch Hub
        torch.set_num_threads(1)
        model, utils = torch.hub.load(
            repo_or_dir='snakers4/silero-vad', 
            model='silero_vad',
            force_reload=True
        )
        
        print("✅ Model downloaded successfully!")
        
        # Save as TorchScript (.jit)
        print(f"💾 Saving TorchScript model to: {jit_path}")
        torch.jit.save(model, str(jit_path))
        
        # Try to save as ONNX if possible
        try:
            print(f"🔄 Converting to ONNX: {onnx_path}")
            
            # Create dummy input for ONNX export
            dummy_input = torch.randn(1, 512)  # Batch size 1, 512 samples (32ms at 16kHz)
            
            torch.onnx.export(
                model,
                dummy_input,
                str(onnx_path),
                export_params=True,
                opset_version=16,
                do_constant_folding=True,
                input_names=['input'],
                output_names=['output'],
                dynamic_axes={
                    'input': {0: 'batch_size', 1: 'sequence'},
                    'output': {0: 'batch_size'}
                }
            )
            print(f"✅ ONNX model saved: {onnx_path}")
            
        except Exception as e:
            print(f"⚠️  ONNX export failed: {e}")
            print("   TorchScript model is still available and will work fine.")
        
        # Try Core ML conversion if coremltools is available
        try:
            import coremltools as ct
            print(f"🔄 Converting to Core ML...")
            
            if onnx_path.exists():
                # Convert from ONNX
                mlmodel = ct.converters.onnx.convert(
                    model=str(onnx_path),
                    minimum_deployment_target=ct.target.iOS16,
                    compute_units=ct.ComputeUnit.CPU_ONLY,
                )
            else:
                # Convert from TorchScript
                mlmodel = ct.convert(
                    model,
                    convert_to='mlprogram',
                    minimum_deployment_target=ct.target.iOS16,
                    compute_units=ct.ComputeUnit.CPU_ONLY,
                )
            
            mlmodel_path = models_dir / "SileroVAD.mlmodel"
            mlmodel.short_description = 'Silero VAD v6.0 (16k mono)'
            mlmodel.save(str(mlmodel_path))
            print(f"✅ Core ML model saved: {mlmodel_path}")
            
        except ImportError:
            print("ℹ️  coremltools not installed, skipping Core ML conversion")
            print("   Install with: pip install coremltools")
        except Exception as e:
            print(f"⚠️  Core ML conversion failed: {e}")
        
        print("\n🎉 Download complete!")
        print(f"📁 Models saved in: {models_dir}")
        
        # List what we have
        for model_file in models_dir.glob("SileroVAD.*"):
            size_mb = model_file.stat().st_size / (1024 * 1024)
            print(f"   📄 {model_file.name} ({size_mb:.1f} MB)")
        
        return True
        
    except Exception as e:
        print(f"❌ Download failed: {e}")
        print("\n💡 Troubleshooting:")
        print("   1. Check internet connection")
        print("   2. Try with VPN if in restricted region")
        print("   3. Install required packages: pip install torch torchaudio")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
