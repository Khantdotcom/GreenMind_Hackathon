# <span>**MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp**</span>

INT4 W4A16 (AWQ) quantization of `CMKL/MANGO1.5-Qwen3.5-9B`, CMKL University's dense 9B bilingual (Thai/English) fine-tune of `Qwen/Qwen3.5-9B`, for serving with [**<u>vLLM</u>**](https://github.com/vllm-project/vllm) on Ampere-class GPUs (A100 and similar). This `-mtp` variant additionally carries the model's MTP (Multi-Token-Prediction) draft head, enabling self-speculative decoding — see **About this checkpoint specifically** below.

See the [**<u>base model card</u>**](https://huggingface.co/CMKL/MANGO1.5-Qwen3.5-9B) for training data, evaluation results, and intended-use details — this card only covers the quantization itself. For a llama.cpp/GGUF build of the same fine-tune instead, see `CMKL/MANGO1.5-Qwen3.5-9B-GGUF`.

## <span>**Why AWQ W4A16, and why not GGUF, for this deployment target**</span>

This repo and the GGUF repo above are two different quantizations of the same fine-tune, built for two different runtimes:

- **This repo (AWQ W4A16,** `compressed-tensors` **format):** for **vLLM** on **A100 (Ampere)** GPUs. A100 has no native FP8 tensor cores, and serving here is decode/memory-bandwidth-bound at typical batch sizes — exactly the regime weight-only INT4 quantization is built for. vLLM runs W4A16 AWQ through the Marlin kernel on Ampere, which is where the actual throughput win comes from (not just the memory savings).
- `MANGO1.5-Qwen3.5-9B-GGUF`**:** for **llama.cpp** and anything built on it (Ollama, LM Studio, koboldcpp, etc.) — CPU or single-GPU / consumer-hardware inference.

AWQ was chosen over GPTQ for this run: it's cheaper to calibrate (activation-aware scaling, no per-layer Hessian inversion), and `llm-compressor` has explicit, tested layer-mapping support for this exact hybrid-attention architecture (see below) — GPTQ and AWQ land at comparable quality/throughput on vLLM's Marlin kernels, but AWQ's simpler calibration made it the lower-risk first attempt for a brand-new architecture.

## <span>**About this quantization**</span>

- **Method:** AWQ (activation-aware weight-only quantization), via `llm-compressor` 0.12.0. Two-stage recipe: `AWQModifier` computes per-channel smoothing scales, `QuantizationModifier` applies the actual INT4 quantization using those scales.
- **Scheme:** `W4A16_ASYM` — 4-bit integer weights, asymmetric, group size 128, activations left at bf16. Output format: `compressed-tensors` (`pack-quantized`), vLLM's native quantized-checkpoint format.
- **Architecture-aware mappings:** Qwen3.5's hybrid architecture interleaves full self-attention (every 4th layer) with linear attention (Gated DeltaNet, the other 3/4 of layers). `llm-compressor` 0.12.0 ships a dynamic AWQ mapping specifically for this architecture (`Qwen3_5ForConditionalGeneration` in its dynamic mapping registry) that knows how to smooth both layer types correctly — including the Gated DeltaNet-specific projections (`in_proj_a`, `in_proj_b`, `in_proj_qkv`, `in_proj_z`), which don't follow a standard transformer's Q/K/V/O naming. No manual mapping was needed; `llm-compressor` auto-detected it from the model class.
- **What's quantized:** all 32 layers' `Linear` sublayers — both the full-attention layers' `self_attn.{q,k,v,o}_proj` and every layer's Gated DeltaNet `linear_attn.{in_proj_a,in_proj_b,in_proj_qkv,in_proj_z,out_proj}` and MLP `{gate,up,down}_proj`. 248 tensors total, verified 1:1 against the recipe's expected coverage (120 GDN projections across 24 linear-attention layers + 32 attention projections across 8 full-attention layers + 96 MLP projections across all 32 layers).
- **What's excluded (**`ignore`**):** `lm_head`; the unused vision tower (`model.visual.*`, inherited from the base multimodal architecture but never touched during this text-only fine-tune — same as in the GGUF build); the MTP (NextN speculative-decoding) head — `transformers` doesn't load `mtp.*` weights at all (`_keys_to_ignore_on_load_unexpected`), so there was nothing present in `llm-compressor`'s forward graph to quantize during this run. This `-mtp` checkpoint variant restores the MTP head afterward as a post-hoc splice, kept unquantized (plain bf16) — see **About this checkpoint specifically** below.
- **Calibration:** 512 samples reservoir-sampled from the fine-tune's own SFT training data (65% English / 35% Thai, matching the training split exactly), covering all 17 training domains (chat, math, code, STEM, safety, medical, etc.) in roughly the same proportions as the model card's stated training mix. `max_seq_length=2048`. Reusing the model's own training distribution for calibration (rather than a generic public dataset) is `llm-compressor`'s own recommended practice for a fine-tuned model, and avoids under-representing Thai or any specific training domain in the calibration statistics.
- **Validated:** every one of the 248 `weight_scale` tensors was exhaustively scanned post-quantization for NaN/Inf/all-zero corruption (0 found) before this checkpoint was trusted, and the checkpoint was confirmed to load in vLLM and produce coherent, on-topic generations in both English and Thai.
- **Size:** \~8.1 GB (`model.safetensors`), down from \~18 GB bf16 — smaller than a naive 4x reduction would suggest, since `lm_head` and the embedding table (large: vocab size 248,320) stay at full precision.

## <span>**About this checkpoint specifically (**</span>`-mtp` <span>**variant)**</span>

This directory additionally has the base model's 15 MTP (Multi-Token-Prediction / NextN) draft-head tensors spliced back in — plain bf16, unquantized, read verbatim from the source fine-tune's own MTP shard (the source SFT run never trained an MTP head, so these are the *original, untouched* base `Qwen/Qwen3.5-9B` MTP weights; see `splice_mtp_into_awq.py` for the full provenance). `config.json`'s `quantization_config.ignore` includes an `mtp` pattern so vLLM builds the MTP draft module as plain `Linear` layers matching these unquantized weights, rather than expecting packed AWQ params — this is what makes the speculative-decoding command below actually load. Verified: 64–76% draft-token acceptance rate in our own smoke tests.

## <span>**How to use (vLLM)**</span>

```bash
vllm serve CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp \
  --served-model-name mango1.5-awq-w4a16 \
  --trust-remote-code \
  --gpu-memory-utilization 0.85 \
  --max-model-len 262144
```

The quantization method (`compressed-tensors`) and scheme are read automatically from `config.json` — no `--quantization` flag needed. The chat template (including the bilingual system-prompt default from the base model) is embedded and applied automatically by vLLM's OpenAI-compatible `/v1/chat/completions` endpoint. `--max-model-len` can be set anywhere up to the model's native 262,144 tokens; lower it (e.g. 16384) if you want more KV-cache headroom for concurrent requests instead of maximum single-request context.

### <span>**With MTP speculative decoding**</span>

```bash
vllm serve CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp \
  --served-model-name mango1.5-awq-w4a16-mtp \
  --trust-remote-code \
  --gpu-memory-utilization 0.92 \
  --max-model-len 262144 \
  --attention-backend FLASHINFER \
  --reasoning-parser qwen3 --enable-auto-tool-choice --tool-call-parser qwen3_coder \
  --speculative-config '{"model": "CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp", "num_speculative_tokens": 3, "method": "mtp"}'
```

Validated on vLLM 0.24.0 and 0.27.1 (0.27.1 recommended — it hard-fails on an MTP weight/config mismatch instead of silently mis-loading, which is how the `ignore` fix above was actually diagnosed).

## <span>**How to use (SGLang)**</span>

We have not personally validated SGLang against this AWQ checkpoint (only vLLM, above); include this for reference since SGLang lists `compressed-tensors` as a supported quantization format. If you hit a loading issue, please report specifics rather than assuming it's a config problem — this path is untested on our end.

```bash
python -m sglang.launch_server --model-path CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp \
  --port 8000 --tp-size 1 --mem-fraction-static 0.8 --context-length 262144 \
  --quantization compressed-tensors \
  --reasoning-parser qwen3 --tool-call-parser qwen3_coder
```

## <span>**License**</span>

Inherits the Apache 2.0 license of the base model. See [**<u>Qwen/Qwen3.5-9B</u>**](https://huggingface.co/Qwen/Qwen3.5-9B/blob/main/LICENSE) for exact terms.

## <span>**Credits**</span>

- Fine-tune: [**<u>CMKL/MANGO1.5-Qwen3.5-9B</u>**](https://huggingface.co/CMKL/MANGO1.5-Qwen3.5-9B) — Atikan Payungthong, Dr. Akkarit Sangpetch (CMKL University)
- Base model: [**<u>Qwen/Qwen3.5-9B</u>**](https://huggingface.co/Qwen/Qwen3.5-9B)
- Quantization tooling: [**<u>llm-compressor</u>**](https://github.com/vllm-project/llm-compressor)
- GGUF/llama.cpp build of the same fine-tune: [**<u>CMKL/MANGO1.5-Qwen3.5-9B-GGUF</u>**](https://huggingface.co/CMKL/MANGO1.5-Qwen3.5-9B-GGUF)