| **#** | **Started** | **Model** | **Score S** | **A** | **R** | **sE** | **sT** | **sL** | **η vs base** | **J/request** | **p95 TTFT** | **p95 TPOT** | **SLO-met** | **Accuracy** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 6 | 2026-10-24 17:42:20 | mango1.5-awq-w4a16 | **0.0** | 1.00 | 0.987 | 0.00 | 0.00 | 0.13 | 0.15× | 260 | 8.84s | 229 ms | 19/300 | 86.7% |

How each column is computed

- **Score S** — 100 · A · sE0.6 · sT0.2 · sL0.2. Ties: higher retention R, then lower p95 TTFT.
- **A (accuracy gate)** — R = macro-accuracy ÷ the baseline's macro-accuracy; A = smoothstep((R − 0.85) ÷ 0.13): 1 at R ≥ 0.98, fading smoothly below it, floor 0.05. A task family (≥ 20 items) keeping under 75% of the baseline's accuracy multiplies A by a smooth penalty (full at 75%, minimum at 50%).
- **sE (energy)** — η = SLO-met requests ÷ GPU joules over the timed window; sE = clip(ln(η ÷ ηbase) ÷ ln K, 0, 1). A request counts only if it streamed, finished (not truncated), TTFT ≤ 0.5 s + 0.25 s per 1k input tokens and TPOT ≤ 50 ms.
- **sT (throughput)** — share of peak-phase requests that met their SLO.
- **sL (latency)** — √(min(1, 1 ÷ p95 TTFT/SLO) · min(1, 50 ms ÷ p95 TPOT)).
- Energy = GPU board energy from the NVML total-energy counter (CPU/DRAM RAPL and BMC/PDU are not readable on these VMs).

run 20261024T174400: 300 calls | 1 models x 300 tasks x 1\
\[1/300\] mango1.5-awq-w4a16         mxv2_411_instruction  0.00    1.3s\
\[2/300\] mango1.5-awq-w4a16         mxv2_215_rag_grounded  1.00    4.1s\
\[3/300\] mango1.5-awq-w4a16         mxv2_243_rag_grounded  1.00    0.9s\
\[4/300\] mango1.5-awq-w4a16         mxv2_199_longctx  1.00    6.2s\
\[5/300\] mango1.5-awq-w4a16         mxv2_198_longctx  1.00    3.0s\
\[6/300\] mango1.5-awq-w4a16         ag097_inbox_flag  0.00    7.1s\
\[7/300\] mango1.5-awq-w4a16         mxv2_144_math     1.00    5.9s\
\[8/300\] mango1.5-awq-w4a16         mxv2_489_complexity  1.00    1.5s\
\[9/300\] mango1.5-awq-w4a16         mx429_instruction  0.00    4.5s\
\[10/300\] mango1.5-awq-w4a16         mxv2_295_thai     1.00    2.4s\
\[11/300\] mango1.5-awq-w4a16         ag081_pages_agg   0.00    2.6s\
\[12/300\] mango1.5-awq-w4a16         mxv2_450_instruction  1.00   10.1s\
\[13/300\] mango1.5-awq-w4a16         mxv2_155_longctx  1.00    8.5s\
\[14/300\] mango1.5-awq-w4a16         mx193_longctx     1.00    2.6s\
\[15/300\] mango1.5-awq-w4a16         mxv2_018_code_output  1.00    2.4s\
\[16/300\] mango1.5-awq-w4a16         mxv2_485_complexity  1.00    2.2s\
\[17/300\] mango1.5-awq-w4a16         mxv2_242_rag_grounded  1.00    1.0s

\[11/300\] mango1.5-awq-w4a16         ag081_pages_agg   0.00    2.6s\
\[12/300\] mango1.5-awq-w4a16         mxv2_450_instruction  1.00   10.1s\
\[13/300\] mango1.5-awq-w4a16         mxv2_155_longctx  1.00    8.5s\
\[14/300\] mango1.5-awq-w4a16         mx193_longctx     1.00    2.6s\
\[15/300\] mango1.5-awq-w4a16         mxv2_018_code_output  1.00    2.4s\
\[16/300\] mango1.5-awq-w4a16         mxv2_485_complexity  1.00    2.2s\
\[17/300\] mango1.5-awq-w4a16         mxv2_242_rag_grounded  1.00    1.0s\
\[18/300\] mango1.5-awq-w4a16         mxv2_431_instruction  1.00    2.4s\
\[19/300\] mango1.5-awq-w4a16         ag061_calc_chain  1.00    4.6s\
\[20/300\] mango1.5-awq-w4a16         mxv2_111_math     1.00    5.6s\
\[21/300\] mango1.5-awq-w4a16         ag018_kv_prefix_sum  0.00    5.8s\
\[22/300\] mango1.5-awq-w4a16         mxv2_221_rag_grounded  1.00    4.0s\
\[23/300\] mango1.5-awq-w4a16         mxv2_209_rag_grounded  1.00    6.2s\
\[24/300\] mango1.5-awq-w4a16         mxv2_222_rag_grounded  1.00    7.0s\
\[25/300\] mango1.5-awq-w4a16         mxv2_245_rag_grounded  1.00    7.7s\
\[26/300\] mango1.5-awq-w4a16         ag079_pages_agg   0.00   10.3s\
\[27/300\] mango1.5-awq-w4a16         mxv2_207_rag_grounded  1.00   13.2s\
\[28/300\] mango1.5-awq-w4a16         mx169_longctx     1.00    9.3s\
\[29/300\] mango1.5-awq-w4a16         mxv2_229_rag_grounded  1.00   10.0s\
\[30/300\] mango1.5-awq-w4a16         mxv2_045_code_output  1.00   13.3s\
\[31/300\] mango1.5-awq-w4a16         mx170_longctx     0.00    9.5s\
\[32/300\] mango1.5-awq-w4a16         mxv2_227_rag_grounded  1.00   21.9s\
\[33/300\] mango1.5-awq-w4a16         mxv2_023_code_output  1.00   36.7s\
\[34/300\] mango1.5-awq-w4a16         mxv2_201_rag_grounded  1.00   19.2s\
\[35/300\] mango1.5-awq-w4a16         mxv2_142_math     1.00   30.2s\
\[36/300\] mango1.5-awq-w4a16         mx188_longctx     0.00   30.2s\
\[37/300\] mango1.5-awq-w4a16         mxv2_236_rag_grounded  1.00   28.2s\
\[38/300\] mango1.5-awq-w4a16         mxv2_293_thai     1.00   23.7s\
\[39/300\] mango1.5-awq-w4a16         ag040_files_fix_conflict  0.00   37.8s\
\[40/300\] mango1.5-awq-w4a16         ag085_pages_agg   0.00   34.7s

\[51/300\] mango1.5-awq-w4a16         mxv2_277_thai     1.00   16.7s\
\[52/300\] mango1.5-awq-w4a16         mxv2_249_rag_grounded  1.00   10.5s\
\[53/300\] mango1.5-awq-w4a16         mxv2_403_instruction  0.00   36.0s\
\[54/300\] mango1.5-awq-w4a16         mxv2_235_rag_grounded  1.00   35.7s\
\[55/300\] mango1.5-awq-w4a16         mxv2_202_rag_grounded  1.00   15.7s\
\[56/300\] mango1.5-awq-w4a16         mxv2_230_rag_grounded  1.00   13.4s\
\[57/300\] mango1.5-awq-w4a16         mxv2_420_instruction  1.00   33.1s\
\[58/300\] mango1.5-awq-w4a16         mxv2_220_rag_grounded  1.00   16.3s\
\[59/300\] mango1.5-awq-w4a16         mxv2_423_instruction  1.00   44.6s\
\[60/300\] mango1.5-awq-w4a16         mxv2_248_rag_grounded  1.00   12.3s\
\[61/300\] mango1.5-awq-w4a16         ag089_inbox_flag  1.00   50.2s\
\[62/300\] mango1.5-awq-w4a16         mxv2_212_rag_grounded  1.00   41.7s\
\[63/300\] mango1.5-awq-w4a16         mxv2_433_instruction  1.00   51.2s\
\[64/300\] mango1.5-awq-w4a16         mxv2_237_rag_grounded  1.00   32.0s\
\[65/300\] mango1.5-awq-w4a16         mxv2_217_rag_grounded  1.00   15.4s\
\[66/300\] mango1.5-awq-w4a16         mxv2_125_math     1.00   11.9s\
\[67/300\] mango1.5-awq-w4a16         mx421_instruction  1.00   42.0s\
\[68/300\] mango1.5-awq-w4a16         mxv2_218_rag_grounded  1.00   15.8s\
\[69/300\] mango1.5-awq-w4a16         mxv2_185_longctx  0.00   14.0s\
\[70/300\] mango1.5-awq-w4a16         mxv2_136_math     1.00   45.8s\
\[71/300\] mango1.5-awq-w4a16         mxv2_246_rag_grounded  1.00   13.9s\
\[72/300\] mango1.5-awq-w4a16         ag066_calc_chain  0.00   58.0s\
\[73/300\] mango1.5-awq-w4a16         mxv2_193_longctx  1.00   48.5s\
\[74/300\] mango1.5-awq-w4a16         ag045_files_find_port  1.00   50.1s\
\[75/300\] mango1.5-awq-w4a16         m\[51/300\] mango1.5-awq-w4a16         mxv2_277_thai     1.00   16.7s

\[52/300\] mango1.5-awq-w4a16         mxv2_249_rag_grounded  1.00   10.5s

\[53/300\] mango1.5-awq-w4a16         mxv2_403_instruction  0.00   36.0s

\[54/300\] mango1.5-awq-w4a16         mxv2_235_rag_grounded  1.00   35.7s

\[55/300\] mango1.5-awq-w4a16         mxv2_202_rag_grounded  1.00   15.7s

\[56/300\] mango1.5-awq-w4a16         mxv2_230_rag_grounded  1.00   13.4s

\[57/300\] mango1.5-awq-w4a16         mxv2_420_instruction  1.00   33.1s

\[58/300\] mango1.5-awq-w4a16         mxv2_220_rag_grounded  1.00   16.3s

\[59/300\] mango1.5-awq-w4a16         mxv2_423_instruction  1.00   44.6s

\[60/300\] mango1.5-awq-w4a16         mxv2_248_rag_grounded  1.00   12.3s

\[61/300\] mango1.5-awq-w4a16         ag089_inbox_flag  1.00   50.2s

\[62/300\] mango1.5-awq-w4a16         mxv2_212_rag_grounded  1.00   41.7s

\[63/300\] mango1.5-awq-w4a16         mxv2_433_instruction  1.00   51.2s

\[64/300\] mango1.5-awq-w4a16         mxv2_237_rag_grounded  1.00   32.0s

\[65/300\] mango1.5-awq-w4a16         mxv2_217_rag_grounded  1.00   15.4s

\[66/300\] mango1.5-awq-w4a16         mxv2_125_math     1.00   11.9s

\[67/300\] mango1.5-awq-w4a16         mx421_instruction  1.00   42.0s

\[68/300\] mango1.5-awq-w4a16         mxv2_218_rag_grounded  1.00   15.8s

\[69/300\] mango1.5-awq-w4a16         mxv2_185_longctx  0.00   14.0s

\[70/300\] mango1.5-awq-w4a16         mxv2_136_math     1.00   45.8s

\[71/300\] mango1.5-awq-w4a16         mxv2_246_rag_grounded  1.00   13.9s

\[72/300\] mango1.5-awq-w4a16         ag066_calc_chain  0.00   58.0s

\[73/300\] mango1.5-awq-w4a16         mxv2_193_longctx  1.00   48.5s

\[74/300\] mango1.5-awq-w4a16         ag045_files_find_port  1.00   50.1s

\[75/300\] mango1.5-awq-w4a16         mx411_instruction  1.00   50.4s

\[76/300\] mango1.5-awq-w4a16         mxv2_239_rag_grounded  1.00   16.7s

\[77/300\] mango1.5-awq-w4a16         mxv2_241_rag_grounded  1.00   24.3s

\[78/300\] mango1.5-awq-w4a16         mxv2_253_thai     1.00   22.4s

\[79/300\] mango1.5-awq-w4a16         mxv2_267_thai     1.00   18.2s

\[80/300\] mango1.5-awq-w4a16         mxv2_256_thai     1.00   36.9s

x411_instruction  1.00   50.4s\
\[76/300\] mango1.5-awq-w4a16         mxv2_239_rag_grounded  1.00   16.7s\
\[77/300\] mango1.5-awq-w4a16         mxv2_241_rag_grounded  1.00   24.3s\
\[78/300\] mango1.5-awq-w4a16         mxv2_253_thai     1.00   22.4s\
\[79/300\] mango1.5-awq-w4a16         mxv2_267_thai     1.00   18.2s\
\[80/300\] mango1.5-awq-w4a16         mxv2_256_thai     1.00   36.9s

\[92/300\] mango1.5-awq-w4a16         mxv2_283_thai     1.00   22.4s\
\[93/300\] mango1.5-awq-w4a16         mxv2_233_rag_grounded  1.00   19.9s\
\[94/300\] mango1.5-awq-w4a16         mx199_longctx     1.00   35.9s\
\[95/300\] mango1.5-awq-w4a16         mxv2_164_longctx  1.00   38.4s\
\[96/300\] mango1.5-awq-w4a16         mxv2_409_instruction  1.00   54.5s\
\[97/300\] mango1.5-awq-w4a16         mxv2_492_complexity  1.00   32.0s\
\[98/300\] mango1.5-awq-w4a16         mxv2_183_longctx  1.00   41.5s\
\[99/300\] mango1.5-awq-w4a16         ag004_kv_swap     1.00   63.3s\
\[100/300\] mango1.5-awq-w4a16         mxv2_407_instruction  1.00   52.9s\
\[101/300\] mango1.5-awq-w4a16         mxv2_272_thai     1.00   53.2s\
\[102/300\] mango1.5-awq-w4a16         mxv2_211_rag_grounded  1.00   26.1s\
\[103/300\] mango1.5-awq-w4a16         mx417_instruction  1.00   35.0s\
\[104/300\] mango1.5-awq-w4a16         mxv2_173_longctx  1.00   30.9s\
\[105/300\] mango1.5-awq-w4a16         mx402_instruction  1.00   33.7s\
\[106/300\] mango1.5-awq-w4a16         mxv2_032_code_output  1.00   48.7s\
\[107/300\] mango1.5-awq-w4a16         mxv2_206_rag_grounded  1.00   19.3s\
\[108/300\] mango1.5-awq-w4a16         mx409_instruction  1.00   41.1s\
\[109/300\] mango1.5-awq-w4a16         mxv2_447_instruction  1.00   50.0s\
\[110/300\] mango1.5-awq-w4a16         ag100_inbox_flag  0.00   66.2s\
\[111/300\] mango1.5-awq-w4a16         mxv2_042_code_output  1.00   35.9s\
\[112/300\] mango1.5-awq-w4a16         mx448_instruction  1.00   27.4s\
\[113/300\] mango1.5-awq-w4a16         mxv2_247_rag_grounded  1.00   33.1s\
\[114/300\] mango1.5-awq-w4a16         mx416_instruction  1.00   57.1s\
\[115/300\] mango1.5-awq-w4a16         mxv2_279_thai     1.00   43.7s\
\[116/300\] mango1.5-awq-w4a16         mx173_longctx     1.00   33.4s\
\[117/300\] mango1.5-awq-w4a16         mxv2_133_math     1.00   51.1s\
\[118/300\] mango1.5-awq-w4a16         mxv2_223_rag_grounded  1.00   21.0s\
\[119/300\] mango1.5-awq-w4a16         mx439_instruction  1.00   44.0s\
\[120/300\] mango1.5-awq-w4a16         mx422_instruction  1.00   63.1s\
\[121/300\] mango1.5-awq-w4a16         ag053_files_find_port  1.00   77.7s

\[127/300\] mango1.5-awq-w4a16         mxv2_129_math     1.00   50.8s\
\[128/300\] mango1.5-awq-w4a16         ag049_files_find_port  1.00   40.6s\
\[129/300\] mango1.5-awq-w4a16         mxv2_288_thai     1.00   34.5s\
\[130/300\] mango1.5-awq-w4a16         ag006_kv_prefix_sum  0.00   46.9s\
\[131/300\] mango1.5-awq-w4a16         mx436_instruction  1.00   31.0s\
\[132/300\] mango1.5-awq-w4a16         mxv2_165_longctx  0.00   78.1s\
\[133/300\] mango1.5-awq-w4a16         mx412_instruction  1.00   72.9s\
\[134/300\] mango1.5-awq-w4a16         mxv2_444_instruction  0.00   49.0s\
\[135/300\] mango1.5-awq-w4a16         mxv2_432_instruction  1.00   50.3s\
\[136/300\] mango1.5-awq-w4a16         mx424_instruction  1.00   58.0s\
\[137/300\] mango1.5-awq-w4a16         mx432_instruction  1.00   49.0s\
\[138/300\] mango1.5-awq-w4a16         mxv2_434_instruction  1.00   79.3s\
\[139/300\] mango1.5-awq-w4a16         mxv2_014_code_output  1.00   58.0s\
\[140/300\] mango1.5-awq-w4a16         ag075_pages_agg   1.00   68.6s\
\[141/300\] mango1.5-awq-w4a16         mx440_instruction  1.00   63.9s\
\[142/300\] mango1.5-awq-w4a16         mxv2_416_instruction  1.00   55.6s\
\[143/300\] mango1.5-awq-w4a16         mx442_instruction  1.00   39.5s\
\[144/300\] mango1.5-awq-w4a16         mxv2_465_complexity  1.00   69.1s\
\[145/300\] mango1.5-awq-w4a16         mxv2_435_instruction  0.00   46.1s\
\[146/300\] mango1.5-awq-w4a16         ag067_calc_chain  1.00   78.2s\
\[147/300\] mango1.5-awq-w4a16         mxv2_493_complexity  1.00   36.9s\
\[148/300\] mango1.5-awq-w4a16         mxv2_179_longctx  1.00   34.1s\
\[149/300\] mango1.5-awq-w4a16         mxv2_016_code_output  1.00   22.1s\
\[150/300\] mango1.5-awq-w4a16         mxv2_269_thai     1.00   19.7s\
\[151/300\] mango1.5-awq-w4a16         mxv2_174_longctx  1.00   41.5s\
\[152/300\] mango1.5-awq-w4a16         mxv2_414_instruction  1.00   60.7s\
\[153/300\] mango1.5-awq-w4a16         mx433_instruction  1.00   77.7s\
\[154/300\] mango1.5-awq-w4a16         mxv2_264_thai     1.00   37.5s\
\[155/300\] mango1.5-awq-w4a16         mxv2_448_instruction  1.00   53.2s\
\[156/300\] mango1.5-awq-w4a16         ag010_kv_swap     1.00   62.9s

\[155/300\] mango1.5-awq-w4a16         mxv2_448_instruction  1.00   53.2s\
\[156/300\] mango1.5-awq-w4a16         ag010_kv_swap     1.00   62.9s\
\[157/300\] mango1.5-awq-w4a16         mxv2_476_complexity  1.00   65.9s\
\[158/300\] mango1.5-awq-w4a16         mxv2_425_instruction  1.00   61.6s\
\[159/300\] mango1.5-awq-w4a16         ag051_files_find_port  1.00   64.0s\
\[160/300\] mango1.5-awq-w4a16         mxv2_428_instruction  1.00   34.3s\
\[161/300\] mango1.5-awq-w4a16         ag087_inbox_flag  1.00   52.4s\
\[162/300\] mango1.5-awq-w4a16         mx427_instruction  1.00   79.2s\
\[163/300\] mango1.5-awq-w4a16         mxv2_039_code_output  1.00   75.9s\
\[164/300\] mango1.5-awq-w4a16         ag047_files_find_port  1.00   44.2s\
\[165/300\] mango1.5-awq-w4a16         mxv2_231_rag_grounded  1.00   18.3s\
\[166/300\] mango1.5-awq-w4a16         ag024_orders_policy  0.00   69.7s\
\[167/300\] mango1.5-awq-w4a16         mxv2_160_longctx  1.00   81.2s\
\[168/300\] mango1.5-awq-w4a16         mx178_longctx     1.00   54.1s\
\[169/300\] mango1.5-awq-w4a16         mxv2_281_thai     1.00   77.8s\
\[170/300\] mango1.5-awq-w4a16         mxv2_440_instruction  1.00   56.4s\
\[171/300\] mango1.5-awq-w4a16         ag050_files_fix_conflict  0.00   51.0s\
\[172/300\] mango1.5-awq-w4a16         mxv2_180_longctx  1.00   79.7s\
\[173/300\] mango1.5-awq-w4a16         mxv2_030_code_output  1.00   23.6s\
\[174/300\] mango1.5-awq-w4a16         mxv2_426_instruction  1.00   68.0s\
\[175/300\] mango1.5-awq-w4a16         ag057_calc_chain  1.00   64.5s\
\[176/300\] mango1.5-awq-w4a16         mx164_longctx     0.00   19.1s\
\[177/300\] mango1.5-awq-w4a16         mx443_instruction  0.00   90.4s\
\[178/300\] mango1.5-awq-w4a16         mxv2_200_longctx  1.00   82.7s\
\[179/300\] mango1.5-awq-w4a16         mx404_instruction  1.00   14.7s\
\[180/300\] mango1.5-awq-w4a16         mxv2_213_rag_grounded  1.00    9.4s\
\[181/300\] mango1.5-awq-w4a16         ag090_inbox_flag  1.00   67.3s\
\[182/300\] mango1.5-awq-w4a16         mxv2_282_thai     1.00   68.9s\
\[183/300\] mango1.5-awq-w4a16         ag088_inbox_flag  0.00   46.1s\
\[184/300\] mango1.5-awq-w4a16         mx407_instruction  1.00   52.6s

\[176/300\] mango1.5-awq-w4a16         mx164_longctx     0.00   19.1s\
\[177/300\] mango1.5-awq-w4a16         mx443_instruction  0.00   90.4s\
\[178/300\] mango1.5-awq-w4a16         mxv2_200_longctx  1.00   82.7s\
\[179/300\] mango1.5-awq-w4a16         mx404_instruction  1.00   14.7s\
\[180/300\] mango1.5-awq-w4a16         mxv2_213_rag_grounded  1.00    9.4s\
\[181/300\] mango1.5-awq-w4a16         ag090_inbox_flag  1.00   67.3s\
\[182/300\] mango1.5-awq-w4a16         mxv2_282_thai     1.00   68.9s\
\[183/300\] mango1.5-awq-w4a16         ag088_inbox_flag  0.00   46.1s\
\[184/300\] mango1.5-awq-w4a16         mx407_instruction  1.00   52.6s\
\[185/300\] mango1.5-awq-w4a16         ag058_calc_chain  0.00   46.9s\
\[186/300\] mango1.5-awq-w4a16         mxv2_225_rag_grounded  1.00    7.9s\
\[187/300\] mango1.5-awq-w4a16         mxv2_438_instruction  1.00   54.9s\
\[188/300\] mango1.5-awq-w4a16         ag096_inbox_flag  0.00   46.4s\
\[189/300\] mango1.5-awq-w4a16         ag076_pages_agg   1.00   64.3s\
\[190/300\] mango1.5-awq-w4a16         ag099_inbox_flag  1.00   73.0s\
\[191/300\] mango1.5-awq-w4a16         ag048_files_fix_conflict  0.00   28.2s\
\[192/300\] mango1.5-awq-w4a16         ag063_calc_chain  1.00   59.2s\
\[193/300\] mango1.5-awq-w4a16         mxv2_234_rag_grounded  1.00   11.3s\
\[194/300\] mango1.5-awq-w4a16         mx423_instruction  0.00   56.8s\
\[195/300\] mango1.5-awq-w4a16         mxv2_424_instruction  1.00   61.7s\
\[196/300\] mango1.5-awq-w4a16         mxv2_402_instruction  1.00   57.3s\
\[197/300\] mango1.5-awq-w4a16         mxv2_190_longctx  1.00  105.9s\
\[198/300\] mango1.5-awq-w4a16         ag041_files_find_port  1.00   66.7s\
\[199/300\] mango1.5-awq-w4a16         mxv2_404_instruction  1.00   32.6s\
\[200/300\] mango1.5-awq-w4a16         mxv2_412_instruction  1.00   55.9s\
\[201/300\] mango1.5-awq-w4a16         mxv2_287_thai     1.00   20.2s\
\[202/300\] mango1.5-awq-w4a16         ag084_pages_agg   1.00   97.0s\
\[203/300\] mango1.5-awq-w4a16         ag064_calc_chain  0.00   98.8s\
\[204/300\] mango1.5-awq-w4a16         ag070_calc_chain  0.00   82.2s\
\[205/300\] mango1.5-awq-w4a16         mxv2_408_instruction  1.00   58.1s

\[196/300\] mango1.5-awq-w4a16         mxv2_402_instruction  1.00   57.3s\
\[197/300\] mango1.5-awq-w4a16         mxv2_190_longctx  1.00  105.9s\
\[198/300\] mango1.5-awq-w4a16         ag041_files_find_port  1.00   66.7s\
\[199/300\] mango1.5-awq-w4a16         mxv2_404_instruction  1.00   32.6s\
\[200/300\] mango1.5-awq-w4a16         mxv2_412_instruction  1.00   55.9s\
\[201/300\] mango1.5-awq-w4a16         mxv2_287_thai     1.00   20.2s\
\[202/300\] mango1.5-awq-w4a16         ag084_pages_agg   1.00   97.0s\
\[203/300\] mango1.5-awq-w4a16         ag064_calc_chain  0.00   98.8s\
\[204/300\] mango1.5-awq-w4a16         ag070_calc_chain  0.00   82.2s\
\[205/300\] mango1.5-awq-w4a16         mxv2_408_instruction  1.00   58.1s\
\[206/300\] mango1.5-awq-w4a16         mxv2_240_rag_grounded  1.00   10.3s\
\[207/300\] mango1.5-awq-w4a16         mxv2_170_longctx  1.00   59.1s\
\[208/300\] mango1.5-awq-w4a16         mxv2_077_sql_result  1.00  108.0s\
\[209/300\] mango1.5-awq-w4a16         mx430_instruction  1.00   92.9s\
\[210/300\] mango1.5-awq-w4a16         mx446_instruction  1.00   14.4s\
\[211/300\] mango1.5-awq-w4a16         mxv2_120_math     1.00   29.9s\
\[212/300\] mango1.5-awq-w4a16         mx437_instruction  1.00   43.6s\
\[213/300\] mango1.5-awq-w4a16         mx441_instruction  1.00   23.1s\
\[214/300\] mango1.5-awq-w4a16         mxv2_419_instruction  0.00   11.0s\
\[215/300\] mango1.5-awq-w4a16         mx435_instruction  1.00  102.8s\
\[216/300\] mango1.5-awq-w4a16         ag009_kv_prefix_sum  0.00   36.2s\
\[217/300\] mango1.5-awq-w4a16         mxv2_449_instruction  1.00   71.9s\
\[218/300\] mango1.5-awq-w4a16         mxv2_044_code_output  1.00   89.3s\
\[219/300\] mango1.5-awq-w4a16         ag052_files_fix_conflict  0.00   38.2s\
\[220/300\] mango1.5-awq-w4a16         mxv2_004_code_output  1.00   24.6s\
\[221/300\] mango1.5-awq-w4a16         ag022_orders_policy  1.00   86.8s\
\[222/300\] mango1.5-awq-w4a16         ag037_orders_policy  1.00   85.9s\
\[223/300\] mango1.5-awq-w4a16         mxv2_455_complexity  1.00   99.9s\
\[224/300\] mango1.5-awq-w4a16         mxv2_422_instruction  1.00   47.6s\
\[225/300\] mango1.5-awq-w4a16         ag060_calc_chain  0.00   71.6s

\[211/300\] mango1.5-awq-w4a16         mxv2_120_math     1.00   29.9s\
\[212/300\] mango1.5-awq-w4a16         mx437_instruction  1.00   43.6s\
\[213/300\] mango1.5-awq-w4a16         mx441_instruction  1.00   23.1s\
\[214/300\] mango1.5-awq-w4a16         mxv2_419_instruction  0.00   11.0s\
\[215/300\] mango1.5-awq-w4a16         mx435_instruction  1.00  102.8s\
\[216/300\] mango1.5-awq-w4a16         ag009_kv_prefix_sum  0.00   36.2s\
\[217/300\] mango1.5-awq-w4a16         mxv2_449_instruction  1.00   71.9s\
\[218/300\] mango1.5-awq-w4a16         mxv2_044_code_output  1.00   89.3s\
\[219/300\] mango1.5-awq-w4a16         ag052_files_fix_conflict  0.00   38.2s\
\[220/300\] mango1.5-awq-w4a16         mxv2_004_code_output  1.00   24.6s\
\[221/300\] mango1.5-awq-w4a16         ag022_orders_policy  1.00   86.8s\
\[222/300\] mango1.5-awq-w4a16         ag037_orders_policy  1.00   85.9s\
\[223/300\] mango1.5-awq-w4a16         mxv2_455_complexity  1.00   99.9s\
\[224/300\] mango1.5-awq-w4a16         mxv2_422_instruction  1.00   47.6s\
\[225/300\] mango1.5-awq-w4a16         ag060_calc_chain  0.00   71.6s\
\[226/300\] mango1.5-awq-w4a16         ag029_orders_policy  1.00   88.3s\
\[227/300\] mango1.5-awq-w4a16         mxv2_178_longctx  1.00   16.2s\
\[228/300\] mango1.5-awq-w4a16         mxv2_070_sql_result  1.00   99.8s\
\[229/300\] mango1.5-awq-w4a16         mx426_instruction  1.00   14.9s\
\[230/300\] mango1.5-awq-w4a16         ag001_kv_swap     1.00   28.3s\
\[231/300\] mango1.5-awq-w4a16         mxv2_061_sql_result  1.00  110.8s\
\[232/300\] mango1.5-awq-w4a16         mxv2_294_thai     1.00  101.9s\
\[233/300\] mango1.5-awq-w4a16         mx401_instruction  1.00   42.1s\
\[234/300\] mango1.5-awq-w4a16         ag034_orders_policy  1.00  108.0s\
\[235/300\] mango1.5-awq-w4a16         ag033_orders_policy  1.00  117.6s\
\[236/300\] mango1.5-awq-w4a16         mx408_instruction  1.00   16.8s\
\[237/300\] mango1.5-awq-w4a16         mxv2_443_instruction  0.00   92.2s\
\[238/300\] mango1.5-awq-w4a16         ag020_orders_policy  1.00  115.8s\
\[239/300\] mango1.5-awq-w4a16         mxv2_276_thai     1.00  112.4s\
\[240/300\] mango1.5-awq-w4a16         mxv2_401_instruction  1.00   15.9s

\[228/300\] mango1.5-awq-w4a16         mxv2_070_sql_result  1.00   99.8s\
\[229/300\] mango1.5-awq-w4a16         mx426_instruction  1.00   14.9s\
\[230/300\] mango1.5-awq-w4a16         ag001_kv_swap     1.00   28.3s\
\[231/300\] mango1.5-awq-w4a16         mxv2_061_sql_result  1.00  110.8s\
\[232/300\] mango1.5-awq-w4a16         mxv2_294_thai     1.00  101.9s\
\[233/300\] mango1.5-awq-w4a16         mx401_instruction  1.00   42.1s\
\[234/300\] mango1.5-awq-w4a16         ag034_orders_policy  1.00  108.0s\
\[235/300\] mango1.5-awq-w4a16         ag033_orders_policy  1.00  117.6s\
\[236/300\] mango1.5-awq-w4a16         mx408_instruction  1.00   16.8s\
\[237/300\] mango1.5-awq-w4a16         mxv2_443_instruction  0.00   92.2s\
\[238/300\] mango1.5-awq-w4a16         ag020_orders_policy  1.00  115.8s\
\[239/300\] mango1.5-awq-w4a16         mxv2_276_thai     1.00  112.4s\
\[240/300\] mango1.5-awq-w4a16         mxv2_401_instruction  1.00   15.9s\
\[241/300\] mango1.5-awq-w4a16         ag014_kv_winner   1.00  120.7s\
\[242/300\] mango1.5-awq-w4a16         mxv2_130_math     1.00  101.5s\
\[243/300\] mango1.5-awq-w4a16         mxv2_415_instruction  1.00   19.9s\
\[244/300\] mango1.5-awq-w4a16         mxv2_268_thai     1.00   44.2s\
\[245/300\] mango1.5-awq-w4a16         mxv2_051_sql_result  1.00   60.9s\
\[246/300\] mango1.5-awq-w4a16         mx447_instruction  1.00   20.0s\
\[247/300\] mango1.5-awq-w4a16         ag038_orders_policy  1.00  104.8s\
\[248/300\] mango1.5-awq-w4a16         mxv2_298_thai     1.00  102.1s\
\[249/300\] mango1.5-awq-w4a16         mxv2_418_instruction  1.00   77.6s\
\[250/300\] mango1.5-awq-w4a16         mxv2_262_thai     1.00   49.5s\
\[251/300\] mango1.5-awq-w4a16         mxv2_439_instruction  1.00   19.6s\
\[252/300\] mango1.5-awq-w4a16         mx450_instruction  1.00   76.0s\
\[253/300\] mango1.5-awq-w4a16         mx434_instruction  1.00   26.0s\
\[254/300\] mango1.5-awq-w4a16         mxv2_257_thai     1.00   29.4s\
\[255/300\] mango1.5-awq-w4a16         ag036_orders_policy  1.00   84.4s\
\[256/300\] mango1.5-awq-w4a16         mxv2_437_instruction  0.00   46.4s\
\[257/300\] mango1.5-awq-w4a16         ag002_kv_winner   1.00  145.2s

\[240/300\] mango1.5-awq-w4a16         mxv2_401_instruction  1.00   15.9s\
\[241/300\] mango1.5-awq-w4a16         ag014_kv_winner   1.00  120.7s\
\[242/300\] mango1.5-awq-w4a16         mxv2_130_math     1.00  101.5s\
\[243/300\] mango1.5-awq-w4a16         mxv2_415_instruction  1.00   19.9s\
\[244/300\] mango1.5-awq-w4a16         mxv2_268_thai     1.00   44.2s\
\[245/300\] mango1.5-awq-w4a16         mxv2_051_sql_result  1.00   60.9s\
\[246/300\] mango1.5-awq-w4a16         mx447_instruction  1.00   20.0s\
\[247/300\] mango1.5-awq-w4a16         ag038_orders_policy  1.00  104.8s\
\[248/300\] mango1.5-awq-w4a16         mxv2_298_thai     1.00  102.1s\
\[249/300\] mango1.5-awq-w4a16         mxv2_418_instruction  1.00   77.6s\
\[250/300\] mango1.5-awq-w4a16         mxv2_262_thai     1.00   49.5s\
\[251/300\] mango1.5-awq-w4a16         mxv2_439_instruction  1.00   19.6s\
\[252/300\] mango1.5-awq-w4a16         mx450_instruction  1.00   76.0s\
\[253/300\] mango1.5-awq-w4a16         mx434_instruction  1.00   26.0s\
\[254/300\] mango1.5-awq-w4a16         mxv2_257_thai     1.00   29.4s\
\[255/300\] mango1.5-awq-w4a16         ag036_orders_policy  1.00   84.4s\
\[256/300\] mango1.5-awq-w4a16         mxv2_437_instruction  0.00   46.4s\
\[257/300\] mango1.5-awq-w4a16         ag002_kv_winner   1.00  145.2s\
\[258/300\] mango1.5-awq-w4a16         mxv2_100_sql_result  1.00   70.7s\
\[259/300\] mango1.5-awq-w4a16         mxv2_046_code_output  1.00   44.2s\
\[260/300\] mango1.5-awq-w4a16         ag008_kv_winner   1.00  118.2s\
\[261/300\] mango1.5-awq-w4a16         mxv2_066_sql_result  1.00  127.1s\
\[262/300\] mango1.5-awq-w4a16         mx425_instruction  1.00  128.5s\
\[263/300\] mango1.5-awq-w4a16         ag023_orders_policy  1.00   68.4s\
\[264/300\] mango1.5-awq-w4a16         ag021_orders_policy  1.00   66.4s\
\[265/300\] mango1.5-awq-w4a16         ag093_inbox_flag  1.00   64.1s\
\[266/300\] mango1.5-awq-w4a16         ag072_pages_agg   1.00   56.3s\
\[267/300\] mango1.5-awq-w4a16         mx445_instruction  1.00   90.0s\
\[268/300\] mango1.5-awq-w4a16         mx414_instruction  1.00  145.9s\
\[269/300\] mango1.5-awq-w4a16         mxv2_254_thai     1.00  102.4s

\[251/300\] mango1.5-awq-w4a16         mxv2_439_instruction  1.00   19.6s\
\[252/300\] mango1.5-awq-w4a16         mx450_instruction  1.00   76.0s\
\[253/300\] mango1.5-awq-w4a16         mx434_instruction  1.00   26.0s\
\[254/300\] mango1.5-awq-w4a16         mxv2_257_thai     1.00   29.4s\
\[255/300\] mango1.5-awq-w4a16         ag036_orders_policy  1.00   84.4s\
\[256/300\] mango1.5-awq-w4a16         mxv2_437_instruction  0.00   46.4s\
\[257/300\] mango1.5-awq-w4a16         ag002_kv_winner   1.00  145.2s\
\[258/300\] mango1.5-awq-w4a16         mxv2_100_sql_result  1.00   70.7s\
\[259/300\] mango1.5-awq-w4a16         mxv2_046_code_output  1.00   44.2s\
\[260/300\] mango1.5-awq-w4a16         ag008_kv_winner   1.00  118.2s\
\[261/300\] mango1.5-awq-w4a16         mxv2_066_sql_result  1.00  127.1s\
\[262/300\] mango1.5-awq-w4a16         mx425_instruction  1.00  128.5s\
\[263/300\] mango1.5-awq-w4a16         ag023_orders_policy  1.00   68.4s\
\[264/300\] mango1.5-awq-w4a16         ag021_orders_policy  1.00   66.4s\
\[265/300\] mango1.5-awq-w4a16         ag093_inbox_flag  1.00   64.1s\
\[266/300\] mango1.5-awq-w4a16         ag072_pages_agg   1.00   56.3s\
\[267/300\] mango1.5-awq-w4a16         mx445_instruction  1.00   90.0s\
\[268/300\] mango1.5-awq-w4a16         mx414_instruction  1.00  145.9s\
\[269/300\] mango1.5-awq-w4a16         mxv2_254_thai     1.00  102.4s\
\[270/300\] mango1.5-awq-w4a16         mxv2_126_math     1.00  148.8s\
\[271/300\] mango1.5-awq-w4a16         ag028_orders_policy  1.00  137.8s\
\[272/300\] mango1.5-awq-w4a16         mx428_instruction  1.00  101.1s\
\[273/300\] mango1.5-awq-w4a16         mx420_instruction  1.00   67.5s\
\[274/300\] mango1.5-awq-w4a16         mxv2_284_thai     1.00   60.1s\
\[275/300\] mango1.5-awq-w4a16         mxv2_430_instruction  1.00  121.5s\
\[276/300\] mango1.5-awq-w4a16         ag082_pages_agg   1.00   88.9s\
\[277/300\] mango1.5-awq-w4a16         mxv2_292_thai     1.00   75.6s\
\[278/300\] mango1.5-awq-w4a16         mxv2_064_sql_result  1.00   65.6s\
\[279/300\] mango1.5-awq-w4a16         mxv2_421_instruction  1.00  128.0s\
\[280/300\] mango1.5-awq-w4a16         mxv2_297_thai     1.00  156.8s

\[259/300\] mango1.5-awq-w4a16         mxv2_046_code_output  1.00   44.2s\
\[260/300\] mango1.5-awq-w4a16         ag008_kv_winner   1.00  118.2s\
\[261/300\] mango1.5-awq-w4a16         mxv2_066_sql_result  1.00  127.1s\
\[262/300\] mango1.5-awq-w4a16         mx425_instruction  1.00  128.5s\
\[263/300\] mango1.5-awq-w4a16         ag023_orders_policy  1.00   68.4s\
\[264/300\] mango1.5-awq-w4a16         ag021_orders_policy  1.00   66.4s\
\[265/300\] mango1.5-awq-w4a16         ag093_inbox_flag  1.00   64.1s\
\[266/300\] mango1.5-awq-w4a16         ag072_pages_agg   1.00   56.3s\
\[267/300\] mango1.5-awq-w4a16         mx445_instruction  1.00   90.0s\
\[268/300\] mango1.5-awq-w4a16         mx414_instruction  1.00  145.9s\
\[269/300\] mango1.5-awq-w4a16         mxv2_254_thai     1.00  102.4s\
\[270/300\] mango1.5-awq-w4a16         mxv2_126_math     1.00  148.8s\
\[271/300\] mango1.5-awq-w4a16         ag028_orders_policy  1.00  137.8s\
\[272/300\] mango1.5-awq-w4a16         mx428_instruction  1.00  101.1s\
\[273/300\] mango1.5-awq-w4a16         mx420_instruction  1.00   67.5s\
\[274/300\] mango1.5-awq-w4a16         mxv2_284_thai     1.00   60.1s\
\[275/300\] mango1.5-awq-w4a16         mxv2_430_instruction  1.00  121.5s\
\[276/300\] mango1.5-awq-w4a16         ag082_pages_agg   1.00   88.9s\
\[277/300\] mango1.5-awq-w4a16         mxv2_292_thai     1.00   75.6s\
\[278/300\] mango1.5-awq-w4a16         mxv2_064_sql_result  1.00   65.6s\
\[279/300\] mango1.5-awq-w4a16         mxv2_421_instruction  1.00  128.0s\
\[280/300\] mango1.5-awq-w4a16         mxv2_297_thai     1.00  156.8s\
\[281/300\] mango1.5-awq-w4a16         mxv2_478_complexity  1.00  128.0s\
\[282/300\] mango1.5-awq-w4a16         mxv2_092_sql_result  1.00  154.7s\
\[283/300\] mango1.5-awq-w4a16         mx415_instruction  1.00  128.5s\
\[284/300\] mango1.5-awq-w4a16         mxv2_074_sql_result  1.00  178.1s\
\[285/300\] mango1.5-awq-w4a16         mxv2_108_math     1.00  156.5s\
\[286/300\] mango1.5-awq-w4a16         mxv2_413_instruction  1.00  117.2s\
\[287/300\] mango1.5-awq-w4a16         mx198_longctx     1.00  220.8s\
\[288/300\] mango1.5-awq-w4a16         mxv2_405_instruction  1.00  233.8s

\[270/300\] mango1.5-awq-w4a16         mxv2_126_math     1.00  148.8s\
\[271/300\] mango1.5-awq-w4a16         ag028_orders_policy  1.00  137.8s\
\[272/300\] mango1.5-awq-w4a16         mx428_instruction  1.00  101.1s\
\[273/300\] mango1.5-awq-w4a16         mx420_instruction  1.00   67.5s\
\[274/300\] mango1.5-awq-w4a16         mxv2_284_thai     1.00   60.1s\
\[275/300\] mango1.5-awq-w4a16         mxv2_430_instruction  1.00  121.5s\
\[276/300\] mango1.5-awq-w4a16         ag082_pages_agg   1.00   88.9s\
\[277/300\] mango1.5-awq-w4a16         mxv2_292_thai     1.00   75.6s\
\[278/300\] mango1.5-awq-w4a16         mxv2_064_sql_result  1.00   65.6s\
\[279/300\] mango1.5-awq-w4a16         mxv2_421_instruction  1.00  128.0s\
\[280/300\] mango1.5-awq-w4a16         mxv2_297_thai     1.00  156.8s\
\[281/300\] mango1.5-awq-w4a16         mxv2_478_complexity  1.00  128.0s\
\[282/300\] mango1.5-awq-w4a16         mxv2_092_sql_result  1.00  154.7s\
\[283/300\] mango1.5-awq-w4a16         mx415_instruction  1.00  128.5s\
\[284/300\] mango1.5-awq-w4a16         mxv2_074_sql_result  1.00  178.1s\
\[285/300\] mango1.5-awq-w4a16         mxv2_108_math     1.00  156.5s\
\[286/300\] mango1.5-awq-w4a16         mxv2_413_instruction  1.00  117.2s\
\[287/300\] mango1.5-awq-w4a16         mx198_longctx     1.00  220.8s\
\[288/300\] mango1.5-awq-w4a16         mxv2_405_instruction  1.00  233.8s\
\[289/300\] mango1.5-awq-w4a16         mxv2_131_math     1.00  230.4s\
\[290/300\] mango1.5-awq-w4a16         mx444_instruction  0.00  292.0s\
\[291/300\] mango1.5-awq-w4a16         mxv2_149_math     0.00  288.9s\
\[292/300\] mango1.5-awq-w4a16         mxv2_278_thai     1.00  289.7s\
\[293/300\] mango1.5-awq-w4a16         mxv2_119_math     0.00  289.7s\
\[294/300\] mango1.5-awq-w4a16         mxv2_442_instruction  0.00  281.1s\
\[295/300\] mango1.5-awq-w4a16         mxv2_134_math     0.00  279.6s\
\[296/300\] mango1.5-awq-w4a16         mxv2_195_longctx  1.00  273.2s\
\[297/300\] mango1.5-awq-w4a16         mx410_instruction  0.00  258.4s\
\[298/300\] mango1.5-awq-w4a16         mx405_instruction  0.00  258.2s\
\[299/300\] mango1.5-awq-w4a16         mxv2_429_instruction  1.00  255.7s

\[273/300\] mango1.5-awq-w4a16         mx420_instruction  1.00   67.5s\
\[274/300\] mango1.5-awq-w4a16         mxv2_284_thai     1.00   60.1s\
\[275/300\] mango1.5-awq-w4a16         mxv2_430_instruction  1.00  121.5s\
\[276/300\] mango1.5-awq-w4a16         ag082_pages_agg   1.00   88.9s\
\[277/300\] mango1.5-awq-w4a16         mxv2_292_thai     1.00   75.6s\
\[278/300\] mango1.5-awq-w4a16         mxv2_064_sql_result  1.00   65.6s\
\[279/300\] mango1.5-awq-w4a16         mxv2_421_instruction  1.00  128.0s\
\[280/300\] mango1.5-awq-w4a16         mxv2_297_thai     1.00  156.8s\
\[281/300\] mango1.5-awq-w4a16         mxv2_478_complexity  1.00  128.0s\
\[282/300\] mango1.5-awq-w4a16         mxv2_092_sql_result  1.00  154.7s\
\[283/300\] mango1.5-awq-w4a16         mx415_instruction  1.00  128.5s\
\[284/300\] mango1.5-awq-w4a16         mxv2_074_sql_result  1.00  178.1s\
\[285/300\] mango1.5-awq-w4a16         mxv2_108_math     1.00  156.5s\
\[286/300\] mango1.5-awq-w4a16         mxv2_413_instruction  1.00  117.2s\
\[287/300\] mango1.5-awq-w4a16         mx198_longctx     1.00  220.8s\
\[288/300\] mango1.5-awq-w4a16         mxv2_405_instruction  1.00  233.8s\
\[289/300\] mango1.5-awq-w4a16         mxv2_131_math     1.00  230.4s\
\[290/300\] mango1.5-awq-w4a16         mx444_instruction  0.00  292.0s\
\[291/300\] mango1.5-awq-w4a16         mxv2_149_math     0.00  288.9s\
\[292/300\] mango1.5-awq-w4a16         mxv2_278_thai     1.00  289.7s\
\[293/300\] mango1.5-awq-w4a16         mxv2_119_math     0.00  289.7s\
\[294/300\] mango1.5-awq-w4a16         mxv2_442_instruction  0.00  281.1s\
\[295/300\] mango1.5-awq-w4a16         mxv2_134_math     0.00  279.6s\
\[296/300\] mango1.5-awq-w4a16         mxv2_195_longctx  1.00  273.2s\
\[297/300\] mango1.5-awq-w4a16         mx410_instruction  0.00  258.4s\
\[298/300\] mango1.5-awq-w4a16         mx405_instruction  0.00  258.2s\
\[299/300\] mango1.5-awq-w4a16         mxv2_429_instruction  1.00  255.7s\
\[300/300\] mango1.5-awq-w4a16         mxv2_252_thai     1.00  195.2s\
\
wrote /app/results/team-team17-final-20261024T174220-99b912-r1.jsonl