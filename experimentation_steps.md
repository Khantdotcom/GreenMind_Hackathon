# vLLM Experimentation Plan — MANGO1.5 AWQ W4A16 MTP

## Goal

Find the highest reproducible score `S` on the 300-request benchmark while preserving accuracy and meeting the benchmark's TTFT/TPOT SLOs.

**Model under test:** `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp`  
**Reference baseline:** untuned vLLM BF16; `η_base = 0.00163` SLO-met requests/J; macro-accuracy `87.8%`.  
**Full-energy target:** `η = 3 × 0.00163 = 0.00489` SLO-met requests/J.

Do not assume an optimization is successful from tokens/s, draft acceptance, or raw latency alone. Use the actual scored `S` and all accuracy/SLO gates.

## 1. Freeze the experimental environment

Before benchmarking, record:

- GPU model/count and available VRAM; driver and CUDA versions.
- Exact vLLM, Python, PyTorch, attention-kernel, and model-revision versions.
- Server command, environment variables, tensor-parallel settings, and all engine arguments.
- Dataset revision, all 300 request IDs, prompt/token lengths, generation parameters, arrival times, and peak-phase boundaries.
- Accuracy evaluator version, family labels, and scoring script revision.

Pin the environment for the entire experiment. The model card lists vLLM 0.27.1 as a validated version; verify compatibility with the chosen VM and kernels before using it. Do not silently change versions between runs.

## 2. Make the 300-request workload reproducible

Use one fixed manifest for all runs. Store at least:

`request_id, family, prompt_hash, input_tokens, max_output_tokens, arrival_time, peak_phase, expected_answer_or_evaluator_id`

The originally described stress slices sum to 170 requests if treated as mutually exclusive (50 shared-prefix + 20 long-output + 10 burst-long-prompt + 30 math + 30 code + 30 Thai). Specify the remaining 130 requests from the benchmark's normal mix, or explicitly document overlaps. Do not change request composition between experiments.

Suggested stress behavior:

- 50 requests use an identical approximately 20k-token prefix and distinct final questions.
- 20 short-input requests require long outputs.
- During decode activity, inject a burst of 10 approximately 30k-token prompts requiring short outputs.
- Include at least 30 math/exact-arithmetic, 30 code, and 30 Thai/non-English cases, with family assignment fixed in the manifest.

Confirm that each prompt plus the requested output fits `--max-model-len`. Do not silently truncate input or output to make a configuration pass.

## 3. Establish the reference baseline

Run the untuned default-BF16 baseline using the exact baseline checkpoint and serving settings required by the benchmark.

1. Start the server and wait until initialization is complete.
2. Run an unmeasured warm-up that is not included in the timed-window energy counter.
3. Execute the fixed 300-request workload using the prescribed request schedule.
4. Capture streamed/finished/truncated status, TTFT, TPOT, output tokens, accuracy, per-family accuracy, and peak-phase SLO pass/fail.
5. Read the NVML total-energy counter immediately before and after the measured window; use the difference as GPU joules.
6. Reproduce the reported baseline values where possible, especially macro-accuracy `87.8%` and `η_base = 0.00163`. Investigate deviations before comparing candidates.

Use the benchmark evaluator's exact rules for counting requests and calculating p95 metrics. Keep the warm-up, startup, model-download, and unrelated GPU activity outside the measured window unless the official harness explicitly includes them.

## 4. Candidate configuration and first integrated run

The model card provides the following MTP setup as a starting point. The example below adds APC and an initial scheduler budget for experimentation; these added values are hypotheses, not model-card guarantees.

```bash
vllm serve CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp \
  --served-model-name mango-awq-mtp \
  --trust-remote-code \
  --gpu-memory-utilization 0.92 \
  --max-model-len 40960 \
  --attention-backend FLASHINFER \
  --enable-prefix-caching \
  --enable-chunked-prefill \
  --max-num-batched-tokens 8192 \
  --max-num-seqs 32 \
  --speculative-config '{"model":"CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp","num_speculative_tokens":3,"method":"mtp"}'
```

Before the run:

- Check that these arguments are supported by the pinned vLLM version and that the model loads without warnings/errors about MTP weights, quantization, or attention kernels.
- The model card states that its AWQ quantization metadata is read from `config.json`; do not add a quantization override unless the model card or the pinned vLLM version requires it.
- `40960` is an initial context length chosen to cover the described 20k/30k prompts plus answer headroom. Increase it if the actual manifest needs more total tokens, or reduce it if the test's maximum sequence length permits more KV-cache capacity.
- `max-num-seqs=32`, `max-num-batched-tokens=8192`, and GPU-memory utilization `0.92` are initial settings, not guaranteed optimal values. If there are preemptions or memory errors, record them and adjust in a separate sweep.
- Only add reasoning/tool-call parser flags if the benchmark calls for those serving features.

## 5. Run controlled experiments in this order

Change one factor at a time so the effect of each technique can be attributed. Keep the same software, prompts, request schedule, sampling settings, maximum output lengths, and measurement protocol.

### Experiment A — Establish the AWQ candidate without APC or MTP

Run the AWQ W4A16 target without speculative decoding and with prefix caching disabled, if supported by the pinned engine. Keep the scheduler settings fixed. Record this as the candidate-model control; it separates quantization/model differences from serving optimizations.

Compare its macro-accuracy and family accuracy against the 87.8% BF16 reference. If the accuracy gate or family penalty is unacceptable, diagnose that before interpreting performance wins.

### Experiment B — Automatic Prefix Caching (APC)

Compare APC off vs. on with the same AWQ model, MTP setting, and scheduler configuration.

- Use the repeated 20k-token prefix cohort.
- Keep the system prompt, chat template, and all tokens preceding each unique final question identical.
- Capture prefix-cache hit metrics, TTFT, GPU joules, p95 TTFT, and SLO-met requests.
- Verify that any gain is concentrated where shared prefixes are present; unique-prefix requests may see little benefit.

Keep APC enabled for later experiments only if it improves the aggregate score or serves as a useful non-regression with no meaningful resource penalty.

### Experiment C — MTP speculative-token sweep

With the best APC setting fixed, test:

| Run | MTP setting |
|---|---|
| C0 | MTP disabled |
| C1 | `num_speculative_tokens = 1` |
| C2 | `num_speculative_tokens = 2` |
| C3 | `num_speculative_tokens = 3` |

For each run, record acceptance rate, output tokens/s, TPOT, GPU joules, SLO-met requests/J, and accuracy. The model card reports 64–76% acceptance in its own smoke tests, but acceptance may differ on this workload. Choose the setting with the best measured `S`, not the highest acceptance rate.

If the version/model combination does not support a given setting, record it as unsupported rather than treating a failed run as a low score.

### Experiment D — Chunked-prefill scheduler sweep

With APC and the winning MTP setting fixed, compare these `--max-num-batched-tokens` values:

| Run | Token budget |
|---|---:|
| D1 | 4096 |
| D2 | 8192 |
| D3 | 16384 |

Keep chunked prefill explicitly enabled if the pinned vLLM version supports the option. Check whether it is enabled by default in the selected engine version. Observe TPOT during long-prompt bursts, TTFT for long-prefill requests, peak-phase SLO pass rate, and preemption/eviction metrics.

Smaller budgets may protect ongoing decode latency, while larger budgets can improve prefill throughput. Let the measurements decide.

### Experiment E — Concurrency refinement (only after A–D)

If GPU memory and KV-cache capacity allow, test a small set of `--max-num-seqs` values such as 16, 32, and 64 while holding all other settings fixed. Stop increasing concurrency if p95 TPOT, preemptions, accuracy, or SLO failures worsen enough to reduce `S`.

Avoid a full Cartesian sweep of all settings initially. The staged design uses fewer runs and makes results easier to interpret.

## 6. Measurements to record for every run

Use one row per run with at least these columns:

```text
run_id,model_revision,vllm_version,gpu,apc_enabled,mtp_tokens,
chunked_prefill,max_num_batched_tokens,max_num_seqs,max_model_len,
requests_total,requests_streamed,requests_finished,requests_truncated,
requests_slo_met,peak_requests,peak_slo_met,gpu_joules,
eta_requests_per_joule,macro_accuracy,accuracy_retention_R,accuracy_factor_A,
min_family_retention,family_penalty_applied,p95_ttft_ms,p95_tpot_ms,
sE,sT,sL,S,prefix_cache_hit_rate,mtp_acceptance_rate,preemption_count,notes
```

Store per-request results separately so every SLO decision and accuracy result can be audited. For energy efficiency, count only requests that streamed, finished without truncation, and met both TTFT and TPOT requirements.

## 7. Calculate the score consistently

For each run:

1. Compute `η = SLO-met requests / GPU joules` over the official timed window.
2. Compute `sE = clip(ln(η / 0.00163) / ln(3), 0, 1)`.
3. Compute accuracy retention `R = candidate macro-accuracy / 0.878` when accuracy is represented as a fraction, or equivalently candidate percent divided by `87.8%`.
4. Apply the exact main accuracy smoothstep and any qualifying task-family penalty from the evaluator.
5. Compute `sT` from the share of peak-phase requests meeting the SLO.
6. Compute `sL` from the evaluator's exact p95 TTFT/SLO normalization and p95 TPOT formula.
7. Compute `S = 100 × A × sE^0.6 × sT^0.2 × sL^0.2`.
8. Apply the tie-breaker: higher retention `R`, then lower p95 TTFT.

Sanity check: energy marks saturate at `η = 0.00489` requests/J. Improving `η` above that value does not increase `sE`, so further optimization should focus on accuracy, throughput, or latency if those subscores remain below 1.

## 8. Final validation protocol

1. Select the best configuration from the controlled sweeps.
2. Rerun the full fixed 300-request suite with the selected configuration; repeat if practical to estimate run-to-run variability.
3. Check total macro-accuracy and every task family with at least 20 items. Investigate any family below the 75%-of-baseline threshold.
4. Verify truncation count, all request-level SLO conditions, p95 metrics, peak-phase pass share, and measured GPU energy.
5. Ensure the measured run used the required timed window, not server startup or warm-up energy.
6. Save the launch command, environment versions, manifest hash, raw per-request output, GPU energy readings, and final score calculation together.

## 9. Decision rule

Choose the configuration with the highest correctly calculated `S`, subject to valid output, accuracy, and SLO requirements. Do not select solely for highest throughput, lowest average latency, lowest memory use, or highest MTP acceptance.

If no candidate improves the score reproducibly, retain the baseline or the best non-regressing configuration and report which factor limited the score (accuracy gate, energy efficiency, peak SLO share, p95 latency, or measurement variability).

## References

- Model card and validated MTP example: <https://huggingface.co/CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp>
- vLLM speculative decoding: <https://docs.vllm.ai/en/stable/features/speculative_decoding/>
- vLLM APC design: <https://docs.vllm.ai/en/latest/design/prefix_caching/>
- vLLM chunked prefill and optimization guidance: <https://docs.vllm.ai/en/stable/configuration/optimization/>
- vLLM serve CLI options: <https://docs.vllm.ai/en/stable/cli/serve/>

*This plan specifies experiments, not predicted results. Final conclusions must be based on measured data from the required benchmark environment.*
