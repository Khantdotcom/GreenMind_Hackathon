# vLLM Inference Benchmark — Input Specification

## Objective

Recommend and evaluate the three most-promising vLLM inference techniques for improving score **S** for the model `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp`, using a 300-request benchmark and the scoring rules below.

## Baseline and reference values

- **Baseline:** untuned vLLM, default BF16.
- **Baseline energy efficiency:** `η_base = 0.00163` SLO-met requests per GPU joule.
- **Energy multiplier:** `K = 3×` for full energy marks.
- **Reference macro-accuracy:** `87.8%`.
- **Candidate model:** `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp` (AWQ W4A16 with an MTP draft head).
- **Benchmark size:** 300 requests.
- **Energy measurement:** GPU board energy from the NVML total-energy counter. CPU/DRAM RAPL and BMC/PDU energy are not readable on the benchmark VMs.

## Score definition

The master score is:

\[
S = 100 \cdot A \cdot s_E^{0.6} \cdot s_T^{0.2} \cdot s_L^{0.2}
\]

For ties, prefer higher accuracy retention `R`, then lower p95 TTFT.

### Accuracy gate (`A`)

- `R = candidate macro-accuracy / baseline macro-accuracy`.
- `A = smoothstep((R - 0.85) / 0.13)`, with a floor of `0.05`.
- The accuracy factor reaches `1` at `R ≥ 0.98`.
- For any task family with at least 20 items, if its accuracy falls below 75% of that family's baseline accuracy, apply the specified smooth family penalty; the penalty reaches its minimum at 50% of baseline family accuracy.

### Energy (`sE`)

- `η = SLO-met requests / GPU joules over the timed window`.
- `sE = clip(ln(η / η_base) / ln(K), 0, 1)`.
- `η_base = 0.00163` and `K = 3`.
- Therefore, the efficiency target for full energy marks is `η = 0.00489` SLO-met requests/J.

A request counts as SLO-met for this metric only if it streamed, finished without truncation, and met both latency conditions:

- `TTFT ≤ 0.5 seconds + 0.25 seconds per 1,000 input tokens`.
- `TPOT ≤ 50 ms`.

### Throughput (`sT`)

- `sT = share of peak-phase requests that met their SLO`.

### Latency (`sL`)

\[
s_L = \sqrt{\min\left(1,\frac{1}{p95\ TTFT/SLO}\right)
\cdot \min\left(1,\frac{50\text{ ms}}{p95\ TPOT}\right)}
\]

Use the benchmark evaluator's precise TTFT-SLO normalization when calculating `p95 TTFT/SLO`, because the TTFT threshold depends on input length.

## Proposed stress workload

The workload should expose KV-cache pressure, prefill/decode interference, quantization-related accuracy loss, and differences in speculative decoding.

1. **Shared-prefix / APC slice:** 50 requests share an identical approximately 20k-token system prompt (for example, a codebase or RAG context) and append different final questions.
2. **Long-output / decode slice:** 20 short prompts ask for long completions (for example, a roughly 3,000-word essay).
3. **Prefill burst:** While long-output requests are decoding, inject 10 long prompts of approximately 30k tokens that require short answers.
4. **Math and exact arithmetic:** 30 requests requiring multi-step arithmetic or precise numerical extraction.
5. **Code generation:** 30 requests requiring exact syntax and structured code output.
6. **Thai / non-English:** 30 requests testing Thai and other relevant non-English language tasks.
7. **Other benchmark requests:** Use the remaining workload from the benchmark's normal mix as needed to reach 300 requests. Document any overlap between the stress slices above. If the listed counts are treated as mutually exclusive, they specify 170 requests, so the remaining 130 requests must be explicitly defined before the test is reproducible.

## Initial optimization hypotheses

1. **Automatic Prefix Caching (APC):** likely beneficial for repeated long prefixes by avoiding repeated prefill work, reducing TTFT and GPU energy when cache hits occur.
2. **MTP speculative decoding:** the candidate checkpoint includes an MTP draft head; test whether fewer target-model decoding iterations improve energy efficiency and TPOT under the actual workload.
3. **Chunked prefill and scheduler tuning:** tune the token budget and concurrency to reduce decode interference during long-prompt bursts while preserving TTFT and peak-phase SLO pass rate.

These are hypotheses to measure, not guaranteed results. Accuracy and all SLO conditions must be checked on the complete 300-request workload.

## Key risks and constraints

- Aggressive quantization can increase speed or reduce memory use while damaging macro-accuracy or a particular task family. The candidate is already W4A16 AWQ, so test it against the reference rather than applying additional quantization first.
- Speculative decoding gains depend on draft-token acceptance, workload, concurrency, and hardware. A high acceptance rate alone does not prove better `S`.
- Prefix caching only helps where prefixes match and cached KV blocks remain available.
- The test must use identical prompts, input ordering, generation parameters, completion limits, concurrency schedule, and timed-window rules across configurations.
- No benchmark score is assumed until the evaluator's exact formulas are applied to measured results.

## References

- Model card and model-specific vLLM/MTP configuration: <https://huggingface.co/CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp>
- vLLM speculative decoding guide: <https://docs.vllm.ai/en/stable/features/speculative_decoding/>
- vLLM automatic prefix caching design: <https://docs.vllm.ai/en/latest/design/prefix_caching/>
- vLLM optimization and chunked-prefill guidance: <https://docs.vllm.ai/en/stable/configuration/optimization/>

*Prepared from the supplied benchmark specification. Confirm the evaluator's exact implementation before treating any derived score as authoritative.*
