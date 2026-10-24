# Repo sync manifest

Source: local machine `/home/khahtay/Documents/greenmind/GreenMind_Hackathon` (Team 17 VM workspace).  
Target Project cloud repo: `Khantdotcom/GreenMind_Hackathon`.

Copy each payload path into the listed repo destination. Do not invent digests; image/container IDs below are from recorded launches on the hackathon VM.

## Files

| Sync path | Land in Project repo as | Notes |
|---|---|---|
| `docs-src/scoring_criteria.md` | `scoring_criteria.md` | Final baseline η `0.00163`, macro-accuracy `87.8%`, formula. Prefer overwrite if cloud copy is older. |
| `docs-src/aboutmodel.md` | `aboutmodel.md` | AWQ W4A16-mtp model card excerpt used on the VM. |
| `final-run3/flag-check.sh` | `final-run3/flag-check.sh` | Thin wrapper → `lib/flag-check.sh`. |
| `final-run3/preflight.sh` | `final-run3/preflight.sh` | Thin wrapper → `lib/preflight.sh` (preflight itself not fully synced; see blockers). |
| `final-run3/start.sh` | `final-run3/start.sh` | Sets `GREENMIND_*` then execs `lib/start.sh`. |
| `final-run3/profile.args` | `final-run3/profile.args` | Budget `8192`; MTP off; no seq cap. |
| `final-run3/README.md` | `final-run3/README.md` | Launch / compare instructions. |
| `final-run3/log.md` | `final-run3/log.md` | Graded console scrape for Final #5; **History score row blank** (not copied from grader). |
| `lib/flag-check.sh` | `lib/flag-check.sh` | Required by every run's `flag-check.sh`. |
| `lib/start.sh` | `lib/start.sh` | Shared docker launcher. |
| `run-records/environment-example.txt` | `docs/ops/environment-example.txt` (or `run-records/`) | Recorded digest / vLLM version / GPU power. |
| `run-records/container-id-example.txt` | `docs/ops/container-id-example.txt` (or `run-records/`) | One historical container id (`d753a4a7…`), not the live process. |
| `run-records/run5-profile.args` | `run5/profile.args` | Profile that served the best Final (`S=19.1`) after warm Validations. |
| `docker-defaults.md` | `docs/ops/docker-defaults.md` | Endpoint, image pin, env vars, flag-check usage. |
| `MANIFEST.md` | (keep in sync payload / optional `docs/ops/MANIFEST-sync.md`) | This file. |

## Not included (exist on local machine; pull separately if needed)

- Full `lib/` helpers (`preflight.sh`, `preflight_checks.py`, `warmup.py`, `watch.sh`, `summarize.py`, `replay.py`, `power.sh`)
- `CYCLE_PLAN.md`, `run6/ANALYSIS.md`, graded Final logs for final-run1/2
- `GreenMind_Participant_Briefing.pdf` (large; already on local)
- Live docker image layers (pin by digest instead)
