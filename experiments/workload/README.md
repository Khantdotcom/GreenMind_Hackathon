# Fixed 300-request manifest

Every experiment uses one manifest. [`manifest.template.csv`](manifest.template.csv) has the columns from `experimentation_steps.md` plus `stress_slice` so overlaps can be tagged. It has no request rows. Do not invent them.

```bash
python3 experiments/workload/check_manifest.py experiments/workload/manifest.template.csv
python3 experiments/workload/check_manifest.py path/to/filled.csv
python3 experiments/workload/check_manifest.py path/to/filled.csv --strict-stress
```

The official Final mix to preserve is chat 90, RAG 60, agentic 60, math/code 45, Thai 30, long-context 15 (300). The plan's stress slices are tags on those rows, not extra requests:

| Tag | Minimum rows |
|---|---:|
| `shared_prefix` | 50 |
| `long_output` | 20 |
| `burst_long_prompt` | 10 |
| `math` | 30 |
| `code` | 30 |
| `thai` | 30 |

Thirty math plus thirty code cannot be added on top of the official math/code bucket of 45. Tag rows that already belong to that class, and record the overlap in the ledger notes. `--strict-stress` checks the tag minimums only after the file has 300 rows.

Each row's `input_tokens + max_output_tokens` must fit `--max-model-len 40960`. The checker rejects a longer row. Do not truncate a prompt to make a profile pass.

Keep the same prompt hashes, arrival times, and peak-phase marks across A–E and `final-combined`.
