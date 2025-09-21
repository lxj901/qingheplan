#!/usr/bin/env python3
"""
Convert Silero VAD (ONNX or TorchScript) to Core ML (.mlmodel) with 16k mono input.
Requires: coremltools>=7.0, onnx (if ONNX input)
Usage examples:
  python convert_silero_vad_to_coreml.py --onnx silero_vad.onnx --out SileroVAD.mlmodel
  python convert_silero_vad_to_coreml.py --ts silero_vad.ts --out SileroVAD.mlmodel
"""
import argparse
import coremltools as ct


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--onnx', type=str, help='Path to Silero VAD ONNX model')
    parser.add_argument('--ts', type=str, help='Path to Silero VAD TorchScript model')
    parser.add_argument('--out', type=str, required=True, help='Output .mlmodel path')
    args = parser.parse_args()

    if not args.onnx and not args.ts:
        raise SystemExit('Provide either --onnx or --ts')

    if args.onnx:
        mlmodel = ct.converters.onnx.convert(
            model=args.onnx,
            minimum_deployment_target=ct.target.iOS16,
            compute_units=ct.ComputeUnit.CPU_ONLY,
        )
    else:
        mlmodel = ct.convert(
            args.ts,
            convert_to='mlprogram',
            minimum_deployment_target=ct.target.iOS16,
            compute_units=ct.ComputeUnit.CPU_ONLY,
        )

    # Optionally set metadata
    mlmodel.short_description = 'Silero VAD converted to Core ML (16k mono)'
    mlmodel.save(args.out)
    print('Saved:', args.out)


if __name__ == '__main__':
    main()

