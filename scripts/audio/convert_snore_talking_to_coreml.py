#!/usr/bin/env python3
"""
Convert a simple snore/talking binary classifier to Core ML.
Expected input: log-mel spectrogram tensor [T, F] or [1, 1, T, F]
Requires: coremltools>=7.0, onnx (if ONNX input) or PyTorch (for torchscript)
Usage examples:
  python convert_snore_talking_to_coreml.py --onnx snore_talking.onnx --out SnoreTalking.mlmodel
  python convert_snore_talking_to_coreml.py --ts snore_talking.ts --out SnoreTalking.mlmodel
"""
import argparse
import coremltools as ct


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--onnx', type=str, help='Path to classifier ONNX model')
    parser.add_argument('--ts', type=str, help='Path to classifier TorchScript model')
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

    mlmodel.short_description = 'Snore vs Talking binary classifier (Core ML)'
    mlmodel.save(args.out)
    print('Saved:', args.out)


if __name__ == '__main__':
    main()

