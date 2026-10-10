#!/bin/bash
# DRY RUN of the macOS round 2 evaluations on a LOCAL 1.3.0 test build (branch local/try-1.3.0) — NOT release
# evidence: the build is not the owner's freeze commit. Everything lands in sandbox/dryrun-1.3.0/ (git-ignored);
# accept-native's records in evals/acceptance/ are copied here and the committed files restored afterwards.
#
#   caffeinate -i -s bash sandbox/dryrun-1.3.0/run_all.sh [all|l4|cpu|daemon|l3]     (from the repo root)
#
# Stages, as in the 1.3.0 gate rules (release-1.3.0 plan) and macOS plan §0 round 2:
#   l4      L4 on Metal: 4B and 1.7B x ffmpeg and documents, in process (KNAIF_NO_DAEMON=1), success verifier,
#           safety on the binary, accept-native verdict per cell
#   cpu     the pre-drawn t15 sample rows on the Metal-less tree, plus both safety sets on it (not composed here)
#   daemon  plan equality: `knaif plan --batch --json` over every eval.jsonl utterance, in process vs through a
#           daemon, both models; must be byte-identical
#   l3      L3 parity, packaged binary vs Python (llama-cpp-python on Metal), bounds ffmpeg 0.0411, documents 0.0183
set -uo pipefail

R=sandbox/dryrun-1.3.0
BIN=sandbox/macos/knaif/bin/knaif
CPUBIN=sandbox/macos/knaif-cpu/bin/knaif
MODELS="4b 1.7b"
SKILLS="ffmpeg documents"
gguf() { case "$1" in 4b) echo models/knaif-qwen3-4b-v2-q4_k_m.gguf ;; 1.7b) echo models/knaif-qwen3-1.7b-v2-q6_k.gguf ;; esac; }
pyname() { case "$1" in 4b) echo knaif-qwen3-4b-v2 ;; 1.7b) echo knaif-qwen3-1.7b-v2 ;; esac; }
export PATH="$HOME/.local/share/mise/shims:$PATH"
mkdir -p "$R"
log() { echo "$(date '+%F %T') $*" | tee -a "$R/COMPLETE"; }
failed() { log "FAILED: $*"; }

# -- preflight ------------------------------------------------------------------------------------------
[ -f Cargo.toml ] && [ -x "$BIN" ] && [ -x "$CPUBIN" ] || { echo "run from the repo root after unpacking the build"; exit 2; }
[ "$("$BIN" --version)" = "knaif 1.3.0 (inference: llama.cpp)" ] || { failed "binary is not the 1.3.0 test build"; exit 2; }
ls "$CPUBIN"/../libggml-metal.* >/dev/null 2>&1 && { failed "CPU tree still has the Metal backend"; exit 2; }
STAGE="${1:-all}"
for pair in "a9c26005e94622d63d1c6e64cb1c1b42084dcc37f6be7d69f8d5967f9c13aab7 models/knaif-qwen3-4b-v2-q4_k_m.gguf" \
            "d59cad240f5e0f157f093868479cf92132156097394805a9cccd102e14f04ac5 models/knaif-qwen3-1.7b-v2-q6_k.gguf"; do
  want="${pair%% *}" file="${pair#* }"
  [ "$(shasum -a 256 "$file" | cut -d' ' -f1)" = "$want" ] || { failed "model hash mismatch: $file"; exit 2; }
done
export KNAIF_NO_DAEMON=1

# The committed acceptance records: snapshot the file list, restore them on exit whatever happens.
ACC_BEFORE="$R/.acceptance-files-before"
git ls-files evals/acceptance > "$ACC_BEFORE"
restore_acceptance() {
  git checkout -- evals/acceptance 2>/dev/null
  # remove only files this run created there (not tracked, not present before)
  git ls-files --others --exclude-standard evals/acceptance | while read -r f; do rm -f "$f"; done
}
trap restore_acceptance EXIT

placement() { # board -> compute_backend the lane measured
  python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('compute_backend'))" "$1" 2>/dev/null
}

# -- L4 on Metal ----------------------------------------------------------------------------------------
stage_l4() {
  log "L4 Metal: start"
  for skill in $SKILLS; do uv run python -m knaif.evalsuite fixtures regen --skill "$skill" >> "$R/fixtures.log" 2>&1; done
  for model in $MODELS; do
    local lane="mac-$model" d="$R/l4/$model"
    mkdir -p "$d"
    for skill in $SKILLS; do
      log "L4 $model $skill: native (lane $lane)"
      uv run python -m knaif.evalsuite native --skill "$skill" --lane "$lane" --verifier success --verbose \
        --config eval_backends.yaml --save "$d" > "$d/$skill.log" 2>&1 || log "L4 $model $skill: native exit $?"
      local board="$d/${skill}_${lane}_success.json"
      [ -s "$board" ] || { failed "L4 $model $skill: no scoreboard"; continue; }
      log "L4 $model $skill: placement $(placement "$board")"
      uv run python -m knaif.evalsuite safety --skill "$skill" --lane "$lane" --config eval_backends.yaml \
        --save "$d/${skill}_safety.json" > "$d/${skill}_safety.log" 2>&1 || log "L4 $model $skill: safety exit $?"
      uv run python -m knaif.evalsuite accept-native --skill "$skill" --current "$board" \
        --safety "$d/${skill}_safety.json" > "$d/${skill}_accept.log" 2>&1
      log "L4 $model $skill: $(grep -m1 -E '^(NOT )?ACCEPTED' "$d/${skill}_accept.log" || echo 'no verdict line')"
      cp evals/acceptance/"$skill".json "$d/${skill}_acceptance-record.json" 2>/dev/null
      restore_acceptance
    done
  done
  log "L4 Metal: done"
}

# -- CPU sample -----------------------------------------------------------------------------------------
stage_cpu() {
  log "CPU sample: start"
  for skill in $SKILLS; do uv run python -m knaif.evalsuite fixtures regen --skill "$skill" >> "$R/fixtures.log" 2>&1; done
  for model in $MODELS; do
    local lane="mac-cpu-$model" d="$R/cpu/$model"
    mkdir -p "$d"
    for skill in $SKILLS; do
      local only="evals/runs/2026-09-29_r5c-linux_success/t15_sample_${model}_${skill}.json"
      log "CPU $model $skill: sample $(python3 -c "import json,sys; print(len(json.load(open(sys.argv[1]))))" "$only" 2>/dev/null) rows"
      uv run python -m knaif.evalsuite native --skill "$skill" --lane "$lane" --only "$only" --verifier success \
        --verbose --config eval_backends.yaml --save "$d" > "$d/$skill.log" 2>&1 || log "CPU $model $skill: native exit $?"
      [ -s "$d/${skill}_${lane}_success.json" ] && log "CPU $model $skill: placement $(placement "$d/${skill}_${lane}_success.json")"
      uv run python -m knaif.evalsuite safety --skill "$skill" --lane "$lane" --config eval_backends.yaml \
        --save "$d/${skill}_safety.json" > "$d/${skill}_safety.log" 2>&1 || log "CPU $model $skill: safety exit $?"
      log "CPU $model $skill: safety $(grep -m1 -i -E 'safety|rejected|passed' "$d/${skill}_safety.log" | cut -c1-120)"
    done
  done
  log "CPU sample: done"
}

# -- daemon plan equality -------------------------------------------------------------------------------
stage_daemon() {
  log "daemon equality: start"
  for model in $MODELS; do
    local d="$R/daemon/$model" m; m="$(gguf "$model")"
    mkdir -p "$d"
    for skill in $SKILLS; do
      python3 -c "
import json, sys
for line in open(sys.argv[1], encoding='utf-8'):
    line = line.strip()
    if line:
        for u in json.loads(line).get('utterances', []):
            print(u.replace('\n', ' '))" "skills/$skill/data/eval.jsonl" > "$d/$skill.utterances.txt"
      ( cd "sandbox/fixtures/$skill" && KNAIF_NO_DAEMON=1 "$OLDPWD/$BIN" plan --skill "$skill" --model "$OLDPWD/$m" \
          --batch "$OLDPWD/$d/$skill.utterances.txt" --json ) > "$d/$skill.inprocess.jsonl" 2> "$d/$skill.inprocess.err"
      log "daemon $model $skill: in process exit $?, $(wc -l < "$d/$skill.inprocess.jsonl") lines"
    done
    env -u KNAIF_NO_DAEMON "$BIN" daemon start --model "$m" > "$d/daemon-start.log" 2>&1
    env -u KNAIF_NO_DAEMON "$BIN" daemon status >> "$d/daemon-start.log" 2>&1
    for skill in $SKILLS; do
      ( cd "sandbox/fixtures/$skill" && env -u KNAIF_NO_DAEMON "$OLDPWD/$BIN" plan --skill "$skill" --model "$OLDPWD/$m" \
          --batch "$OLDPWD/$d/$skill.utterances.txt" --json ) > "$d/$skill.daemon.jsonl" 2> "$d/$skill.daemon.err"
      local a b; a="$(shasum -a 256 < "$d/$skill.inprocess.jsonl" | cut -c1-16)"; b="$(shasum -a 256 < "$d/$skill.daemon.jsonl" | cut -c1-16)"
      if [ "$a" = "$b" ]; then log "daemon $model $skill: IDENTICAL ($a)"; else log "daemon $model $skill: DIFFERENT (in process $a, daemon $b)"; fi
    done
    env -u KNAIF_NO_DAEMON "$BIN" daemon status >> "$d/daemon-start.log" 2>&1
    env -u KNAIF_NO_DAEMON "$BIN" daemon stop >> "$d/daemon-start.log" 2>&1
  done
  log "daemon equality: done"
}

# -- L3 parity ------------------------------------------------------------------------------------------
stage_l3() {
  log "L3: start"
  for model in $MODELS; do
    for skill in $SKILLS; do
      local bound=0.0411 out="$R/l3/$model-$skill"
      [ "$skill" = documents ] && bound=0.0183
      mkdir -p "$out"
      uv run python -m knaif.evalsuite fixtures regen --skill "$skill" >> "$R/fixtures.log" 2>&1
      KNAIF_PARITY_BACKEND=metal uv run python scripts/parity_check.py --skill "$skill" --native-bin "$PWD/$BIN" \
        --model-path "$PWD/$(gguf "$model")" --python-model "$(pyname "$model")" --cwd "$PWD/sandbox/fixtures/$skill" \
        --out "$out/report.json" --label "dryrun-1.3.0-l3-$model-$skill" --max-plan-disagreement "$bound" \
        --purpose "DRY RUN, not evidence: macOS L3 on a local 1.3.0 test build (packaged metal tree)" \
        > "$out/l3.log" 2>&1
      log "L3 $model $skill: parity_check exit $? (bound $bound); $(grep -m1 -i -E 'verdict|PASS|FAIL' "$out/l3.log" | cut -c1-140)"
    done
  done
  log "L3: done"
}

case "$STAGE" in
  l4) stage_l4 ;;
  cpu) stage_cpu ;;
  daemon) stage_daemon ;;
  l3) stage_l3 ;;
  all) log "DRY RUN all stages: $("$BIN" --version), branch $(git branch --show-current) at $(git rev-parse --short HEAD)"
       stage_l4; stage_cpu; stage_daemon; stage_l3; log "ALL STAGES DONE" ;;
  *) echo "usage: run_all.sh [all|l4|cpu|daemon|l3]"; exit 2 ;;
esac
