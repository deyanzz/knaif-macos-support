# Dry run of the macOS round 2 evaluations on a local 1.3.0 test build — NOT release evidence

Run 2026-10-10 03:55–18:25 (14 h 30 min) on the M1 Pro, macOS 27.2, by the Mac contributor, before the
1.3.0 freeze. **This is not release evidence and grades nothing for the gate:** the build is a local
version bump (`local/try-1.3.0` at `3516145`: `release/1.3.0` with the "Zero KB" size fix plus a
local 1.2.1 → 1.3.0 bump), not the owner's freeze commit. Round 2 repeats every stage on the frozen,
signed build. It answers two questions ahead of the freeze: do the round 2 commands work on this Mac,
and how long do they take.

`accept-native` writes its verdicts into `evals/acceptance/`; the run script copied each record here
(`l4/<model>/<skill>_acceptance-record.json`, local) and restored the committed files after every
verdict, so the repository's evidence is unchanged. `*_verdict.txt` below are the `accept-native`
outputs as printed: their "recorded L4 evidence" line refers to that restored file.

## Setup

- Binary: the unpacked `knaif-1.3.0-macos-arm64.zip` (`knaif 1.3.0 (inference: llama.cpp)`, sha256
  `1dd736d7…`), lanes `mac-4b` / `mac-1.7b` in `sandbox/macos/knaif`; the same tree with
  `libggml-metal.so` removed for `mac-cpu-*` (D2). Unsigned.
- Models: `knaif-qwen3-4b-v2` (sha256 `a9c26005…`) and `knaif-qwen3-1.7b-v2` (`d59cad24…`), both
  checked against the manifest. In process (`KNAIF_NO_DAEMON=1`) except the daemon stage.
- L3's Python side: `llama-cpp-python` 0.3.36 on Metal, as in the earlier Mac L3 runs.
- Script: `run_all.sh` here, one invocation for all stages, under `caffeinate`. The gate rules it
  follows are the release-1.3.0 plan's, pre-registered 2026-10-07; nothing was amended.

## Results

**L4, Metal** (03:55–07:29). Every cell placed on `MTL0`, coverage 1.0.

| Cell | Requests | Outcome | knaif score | Safety (whole corpus, on the binary) | Verdict |
|---|---|---|---|---|---|
| 4B ffmpeg | 861 | 0.9384 | 0.9857 | 11/11 | ACCEPTED (46/46) |
| 4B documents | 164 | 0.9756 | 0.9851 | 9/9 | ACCEPTED (43/43) |
| 1.7B ffmpeg | 861 | 0.9187 | 0.9780 | 11/11 | NOT ACCEPTED: slice `batch` 0.862 (25/29) < 0.896 |
| 1.7B documents | 164 | 0.9634 | 0.9945 | 9/9 | ACCEPTED (43/43) |

The 1.7B ffmpeg miss is the `batch` miss the owner waived for macOS on 2026-10-07 (the waiver rule in
the release-1.3.0 plan); it is not waived here, since nothing here is graded. Every figure equals the
1.2.1 run (`2026-10-05_mac-l3l4-1.2.1_success`) to the fourth decimal: on Metal the 1.3.0 changes
(daemon, retrying downloader, run prompting, the `documents_105` fix) change no graded result. The
threshold count grows by one per cell against 1.2.1 (45 → 46, 42 → 43): the 1.3.0 check that safety
covers the whole safety corpus.

**CPU sample** (07:29–10:05). The pre-drawn rows (`2026-09-29_r5c-linux_success/t15_sample_*`) on
the tree without the Metal backend, placement `CPU`, plus both safety sets on that binary. Not
composed or graded here (round 2 composes them on the Windows box).

| Sample | Rows | Outcome | knaif score | Safety |
|---|---|---|---|---|
| 4B ffmpeg | 115 | 0.9130 | 0.9789 | 11/11, 0 breaches |
| 4B documents | 35 | 1.0000 | 0.9926 | 9/9, 0 breaches |
| 1.7B ffmpeg | 115 | 0.9304 | 0.9694 | 11/11, 0 breaches |
| 1.7B documents | 35 | 0.9429 | 0.9905 | 9/9, 0 breaches |

Also identical to the 1.2.1 run's CPU sample.

**Daemon plan equality** (10:05–15:43). `knaif plan --skill <skill> --batch <utterances> --json`
over every utterance of `eval.jsonl`, once in process and once through `knaif daemon start`, per model.

| Model | ffmpeg (861) | documents (164) |
|---|---|---|
| 4B | **identical** (`00a44bba…`) | **identical** (`06f23d2c…`) |
| 1.7B | **identical** (`1dc86320…`) | **identical** (`ae3e633f…`) |

The gate rule ("byte-identical, Windows CUDA and macOS Metal over both corpora, both models") holds on
Metal; until now it had only been run on Windows CUDA with the 4B.

**L3** (15:43–18:25). Packaged binary vs Python, both on Metal, command mode, the 1.2.0 bounds.
Reports: `evals/parity/2026-10-10_mac-l3-dryrun-1.3.0-<model>-<skill>/`.

| Cell | Rows | Port bugs | Not implemented | Plan disagreement | Result |
|---|---|---|---|---|---|
| 4B ffmpeg | 328 | 0 | 0 | 0.0000 (≤ 0.0411) | PASS |
| 4B documents | 143 | 0 | 0 | 0.0070 (≤ 0.0183) | PASS |
| 1.7B ffmpeg | 328 | 0 | 0 | 0.0000 (≤ 0.0411) | PASS |
| 1.7B documents | 143 | 0 | 0 | 0.0070 (≤ 0.0183) | PASS |

The one documents disagreement is `documents_057` ("put page numbers at the bottom of sample.pdf") for
both models, present in every Mac L3 run since 2026-10-03. The 4B documents L3 that failed on
`documents_105` before its fix passes with 0 port bugs.

## Time, for round 2's budgets

| Stage | Wall time on the M1 Pro |
|---|---|
| L4 Metal, both models × both skills, with safety and verdicts | 3 h 34 min (4B ffmpeg alone 2 h 10 min) |
| CPU sample, both models, with safety | 2 h 36 min |
| Daemon plan equality, both models × both corpora, two passes each | 5 h 38 min (~7.6 s per 4B ffmpeg plan) |
| L3, both models × both skills | 2 h 42 min (4B ffmpeg 1 h 31 min) |
| **Total** | **14 h 30 min** |

The daemon stage is the one to budget: it plans all 1,025 utterances four times per model, at Metal
speed (about 16× slower per plan than the 2026-10-06 Windows CUDA run).

## Files

Committed: this report, `run_all.sh`, `<model>/metal/<skill>_verdict.txt`, and the L3 `report.json` +
`meta.json` under `evals/parity/`. Local only (git-ignored, as in the earlier Mac runs): the
scoreboards, safety results and logs under `l4/`, `cpu/`, `daemon/`, and `COMPLETE`, the stage log.
