# Task 09: NVDEC Video Pipeline

**Phase:** 3 — Runtime and Systems Literacy
**Prerequisites:** Task 07
**Estimated sessions:** 3-4

---

## Objective

Build a complete video decode → preprocess → inference pipeline using NVDEC hardware decode, and compare it against CPU-based decode. Identify whether decode is the bottleneck in your Endosight video pipeline.

## Why This Matters

Your Endosight clinical pipeline processes endoscopy video. Your AGENTS.md notes that `browser_video.py` uses `h264_nvenc` for transcoding, and that NVDEC (`h264_cuvid`) is available in ffmpeg but "may not be bit-exact vs CPU decoders for MPEG4 inputs." Your DGX Spark has exactly 1 NVDEC engine. This lab teaches you whether hardware decode is worth the complexity for your specific workload.

## Instructions

### Part A: CPU Decode Baseline

Implement video decode with OpenCV (CPU):

```python
import cv2
cap = cv2.VideoCapture("test_video.mp4")
while True:
    ret, frame = cap.read()
    if not ret: break
    # frame is in BGR format on CPU
    # Preprocess: resize, normalize, convert to tensor
    # Upload to GPU
    tensor = torch.from_numpy(frame).cuda()
```

Measure:
- Frames per second
- Decode latency per frame
- CPU utilization
- Memory copies (CPU decode → CPU memory → GPU upload)

### Part B: FFmpeg CPU Decode

```bash
ffmpeg -i test_video.mp4 -f rawvideo -pix_fmt bgr24 - | ./your_consumer
```

Or use PyAV:
```python
import av
container = av.open("test_video.mp4")
for frame in container.decode(video=0):
    img = frame.to_ndarray(format="bgr24")
```

### Part C: NVDEC Hardware Decode

Use PyNvVideoCodec (available in your exp environment):

```python
import PyNvVideoCodec

# Create hardware decoder
nvdec = PyNvVideoCodec.create_decoder("test_video.mp4", codec="h264")
for frame in nvdec:
    # frame is already on GPU as NV12 surface
    # Convert to RGB, preprocess on GPU
    pass
```

Or use ffmpeg with h264_cuvid:
```bash
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i test_video.mp4 \
    -f rawvideo -pix_fmt nv12 - | ./gpu_consumer
```

**Note from AGENTS.md:** PyNvVideoCodec is in the isolated exp target only, not in `3d_recon`. You may need to install it or use the exp conda environment.

### Part D: GPU-Side Preprocessing

After NVDEC decode, the frame is on GPU as NV12. Do preprocessing on GPU:

```python
# Convert NV12 to RGB on GPU
# Resize on GPU (use cvcuda or torch)
# Normalize on GPU
# No CPU↔GPU copy needed!
```

Your AGENTS.md notes that `cvcuda 0.16.0` is installed in `3d_recon` with morphology/gaussian/cvtcolor/threshold/label/resize ops. Use it.

### Part E: Full Pipeline Comparison

Build 5 pipeline variants and measure end-to-end:

| Pipeline | Decode | Preprocess | Inference | Expected bottleneck |
|----------|--------|------------|-----------|---------------------|
| 1. OpenCV CPU | CPU (OpenCV) | CPU (numpy) | GPU | CPU decode + upload |
| 2. FFmpeg CPU | CPU (ffmpeg) | CPU (numpy) | GPU | CPU decode + upload |
| 3. NVDEC + CPU preprocess | GPU (NVDEC) | CPU (numpy) | GPU | GPU↔CPU roundtrip |
| 4. NVDEC + GPU preprocess | GPU (NVDEC) | GPU (cvcuda) | GPU | Inference (ideal) |
| 5. NVDEC + GPU preprocess + CUDA Graph | GPU (NVDEC) | GPU (cvcuda) | GPU (graph) | Inference |

For each, measure:
- Frames per second
- End-to-end latency per frame
- CPU utilization (%)
- GPU utilization (%)
- NVDEC utilization (if applicable: `nvidia-smi --query-gpu=utilization.decoder`)
- Memory copies count
- Pipeline latency breakdown (decode → preprocess → inference)

### Part F: Nsight Systems Timeline

```bash
nsys profile --stats=true --trace=cuda,nvtx,osrt ./video_pipeline
```

Add NVTX ranges:
```python
import torch
# Or use nvtx Python module
nvtx.range_push("decode")
# ... decode ...
nvtx.range_pop()

nvtx.range_push("preprocess")
# ... preprocess ...
nvtx.range_pop()

nvtx.range_push("inference")
# ... inference ...
nvtx.range_pop()
```

### Part G: The Single-NVDEC Lesson

Your GB10 has exactly 1 NVDEC engine. Test what happens when you:
1. Run 1 decode stream — measure FPS
2. Run 2 concurrent decode streams — does FPS per stream drop by 50%?
3. Run 4 concurrent decode streams — are they time-sliced?

This tells you whether multi-stream video processing is decode-bound on GB10.

### Part H: Endosight Video Analysis

Take a real Endosight clinical video and trace the full path:

```
NVMe → filesystem/page cache → decoder → frame surfaces → preprocessing → inference
```

Identify:
- Where are the memory copies?
- Where is the CPU involved?
- Where is the GPU idle?
- Is decode the bottleneck, or is inference?

## Deliverable

1. **5 pipeline implementations** working with a test video
2. **Comparison table**: FPS, latency, CPU%, GPU%, NVDEC%, memory copies for all 5
3. **Nsight Systems timeline** for pipeline 4 (NVDEC + GPU preprocess)
4. **Multi-stream NVDEC test**: 1, 2, 4 concurrent streams FPS
5. **Endosight video trace**: memory copy map and bottleneck identification
6. **Written analysis** answering:
   - Is NVDEC faster than CPU decode for your workload?
   - Is decode the bottleneck, or is inference?
   - How much does GPU-side preprocessing help?
   - Can you run multiple video streams simultaneously on 1 NVDEC?

## Acceptance Criteria

- [ ] 5 pipeline variants implemented and benchmarked
- [ ] FPS and latency measured for all 5
- [ ] Nsight Systems timeline captured with NVTX ranges
- [ ] Multi-stream NVDEC contention tested (1, 2, 4 streams)
- [ ] Real Endosight video traced through the pipeline
- [ ] Bottleneck identified with profiler evidence
- [ ] Written analysis answers all 4 questions

## Resources

- [DGX Spark Hardware Guide](https://docs.nvidia.com/dgx/dgx-spark/hardware.html) — 1x NVDEC, 1x NVENC
- [PyNvVideoCodec documentation](https://docs.nvidia.com/video-technologies/video-codec-sdk/12.0/python-binding/index.html)
- [NVIDIA Video Codec SDK](https://developer.nvidia.com/video-codec-sdk)
- [cvcuda documentation](https://docs.nvidia.com/cuda/cvcuda/)
- [FFmpeg hardware acceleration guide](https://trac.ffmpeg.org/wiki/HWAccelIntro)
- Your AGENTS.md notes on `browser_video.py` and NVDEC caveats

## AI Agent Prompt Template

```
I need to build a video decode → preprocess → inference pipeline on my GB10 DGX Spark 
(SM121, 1x NVDEC, 1x NVENC, unified memory, cvcuda 0.16.0 installed).

I need 5 variants:
1. OpenCV CPU decode + CPU preprocess + GPU inference
2. FFmpeg CPU decode + CPU preprocess + GPU inference  
3. NVDEC hardware decode (PyNvVideoCodec) + CPU preprocess + GPU inference
4. NVDEC decode + GPU preprocess (cvcuda) + GPU inference
5. NVDEC + GPU preprocess + GPU inference with CUDA Graphs

IMPORTANT NOTES:
- GB10 has only 1 NVDEC engine. Test 1, 2, 4 concurrent streams.
- PyNvVideoCodec is in the exp environment, not 3d_recon.
- NVDEC may not be bit-exact vs CPU decoders for MPEG4 inputs.
- On unified memory, H2D copies may be near-instant.

Measure: FPS, latency, CPU%, GPU%, NVDEC%, memory copies.
Profile with: nsys profile --trace=cuda,nvtx,osrt
Add NVTX ranges for decode, preprocess, and inference stages.
```
