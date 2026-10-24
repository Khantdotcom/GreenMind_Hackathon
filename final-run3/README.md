# final-run3: scheduler budget 8192

**Final #5 on the grader.** Final baseline: η 0.00163, macro-accuracy 87.8%. Plan and evidence: [CYCLE_PLAN.md](../CYCLE_PLAN.md).

**What changes:** `--max-num-batched-tokens 8192` (A100 default 2048) on the best-known base. No cap, no MTP, prefix caching on by default.

**Why:** the Final peak saturates the GPU. In final-run1 the engine averaged 620–1,660 generated tokens/s at 64 running while it prefilled 5–8k prompt tokens/s, which is 38–100 ms per token. A token budget of 2048 splits prefill across many mixed steps, and a mixed step is far slower than a pure decode step: decode-only steps ran at 9–12 ms with 8–15 running. A budget of 8192 clears pending prefill in fewer steps, so more steps are fast pure-decode steps, which lowers average TPOT. It also starts queued prompts sooner, which lowers TTFT. The average TPOT per request is what the SLO checks, so a few longer steps cost less than many slow mixed ones.

**Compare with:** the run6 Final (127/300, p95 TTFT 2.16 s, p95 TPOT 82 ms, 221 J/request).

Do **not** run a Validation on this container before the Final unless you have confirmed with the organizers that it is allowed. The Validation's 100 prompts are the first 100 of the Final, so a Validation leaves them in the prefix cache.

```bash
./final-run3/flag-check.sh && REPLACE=1 ./final-run3/start.sh
python3 lib/warmup.py
./lib/watch.sh        # second terminal, just before Submit
# Submit the Final. When it finishes, Ctrl-C watch.sh, then:
python3 lib/summarize.py ~/greenmind-runs/latest/telemetry.csv --slo-met <N> --track final
```
