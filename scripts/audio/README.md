# Audio Models Fetch & Convert

This folder contains helper scripts to fetch public models and convert them to Core ML.

## Silero VAD (MIT Licensed)

One-click fetch & convert (downloads ONNX, optionally converts to .mlmodel):

```
bash scripts/audio/fetch_models.sh
```

- Output files:
  - `qinghe/Models/Audio/SileroVAD.onnx`
  - `qinghe/Models/Audio/SileroVAD.mlmodel` (if conversion succeeds)

If conversion is skipped, install coremltools and retry:

```
pip3 install --upgrade coremltools onnx
python3 scripts/audio/convert_silero_vad_to_coreml.py \
  --onnx qinghe/Models/Audio/SileroVAD.onnx \
  --out qinghe/Models/Audio/SileroVAD.mlmodel
```

## Snore/Talking Classifier

No public high-quality weights. You can provide ONNX / TorchScript and run:

```
python3 scripts/audio/convert_snore_talking_to_coreml.py \
  --onnx /path/to/snore_talking.onnx \
  --out qinghe/Models/Audio/SnoreTalking.mlmodel
```

Or share training data and we can train a small CNN and export ONNX/MLModel.

