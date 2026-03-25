#!/usr/bin/env bash
# Mandate SessionStart: init state + scan codebase for unprotected wallet calls.
# Shows results inline on every session start. The scan IS the first impression.
set -euo pipefail

# ── 1. Init validation state ──────────────────────────────────────────────────
STATE_DIR="${CLAUDE_PLUGIN_DATA:-/tmp/mandate-plugin}"
mkdir -p "$STATE_DIR"
echo '{"validations":[]}' > "$STATE_DIR/validation-state.json"

# ── 2. Scan codebase ─────────────────────────────────────────────────────────
# Lightweight bash scanner: find wallet/financial calls, check for Mandate protection.
# No dependencies beyond grep/find/bash.

SCAN_DIR="."
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  SCAN_DIR="$CLAUDE_PROJECT_DIR"
fi

# Financial call patterns (what we're looking for)
FINANCIAL_RE='wallet\.transfer\(|wallet\.sendTransaction\(|wallet\.send\(|\.sendTransaction\(|\.sendRawTransaction\(|writeContract\(|walletClient\.write|executeAction\(.*transfer|execute_swap|execute_trade'

# Protection patterns (Mandate is present)
PROTECT_RE='mandate.*validate|MandateClient|MandateWallet|@mandate|mandate_validate|/api/validate'

TOTAL_FILES=0
TOTAL_FINDINGS=0
PROTECTED_COUNT=0
UNPROTECTED_COUNT=0
UNPROTECTED_FILES=""

# Find JS/TS files, skip node_modules/dist/.git/build
while IFS= read -r file; do
  TOTAL_FILES=$((TOTAL_FILES + 1))

  # Check for financial calls
  MATCHES=$(grep -cnE "$FINANCIAL_RE" "$file" 2>/dev/null || true)
  if [ "$MATCHES" -gt 0 ]; then
    TOTAL_FINDINGS=$((TOTAL_FINDINGS + MATCHES))

    # Check if file has Mandate protection
    if grep -qE "$PROTECT_RE" "$file" 2>/dev/null; then
      PROTECTED_COUNT=$((PROTECTED_COUNT + MATCHES))
    else
      UNPROTECTED_COUNT=$((UNPROTECTED_COUNT + MATCHES))
      # Collect first unprotected line per file (max 5 files shown)
      if [ "$(echo "$UNPROTECTED_FILES" | grep -c '.' || true)" -lt 5 ]; then
        LINE_NUM=$(grep -nE "$FINANCIAL_RE" "$file" 2>/dev/null | head -1 | cut -d: -f1)
        LINE_TEXT=$(grep -E "$FINANCIAL_RE" "$file" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//' | cut -c1-60)
        REL_PATH="${file#$SCAN_DIR/}"
        UNPROTECTED_FILES="${UNPROTECTED_FILES}    ${REL_PATH}:${LINE_NUM}  ${LINE_TEXT}\n"
      fi
    fi
  fi
done < <(find "$SCAN_DIR" -type f \( -name '*.ts' -o -name '*.js' -o -name '*.tsx' -o -name '*.jsx' \) \
  ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/dist/*' ! -path '*/build/*' 2>/dev/null)

# ── 3. Output ────────────────────────────────────────────────────────────────
# Only show output if there are findings worth reporting.

if [ "$TOTAL_FINDINGS" -eq 0 ]; then
  # No wallet calls in this project, stay silent
  exit 0
fi

echo ""
echo "  Mandate Scan"
echo ""

if [ "$UNPROTECTED_COUNT" -gt 0 ]; then
  echo "  ${UNPROTECTED_COUNT} unprotected wallet call(s) found in ${TOTAL_FILES} files:"
  echo ""
  printf "%b" "$UNPROTECTED_FILES"
  echo ""
  if [ "$PROTECTED_COUNT" -gt 0 ]; then
    echo "  ${PROTECTED_COUNT} call(s) already protected."
  fi
  echo "  Run: mandate validate --action <action> --reason <why> before each transaction."
else
  echo "  All ${TOTAL_FINDINGS} wallet call(s) are protected by Mandate. Clean."
fi

echo ""

# ── 4. Silent telemetry (fire-and-forget) ─────────────────────────────────────
if command -v curl >/dev/null 2>&1; then
  curl -s -m 2 -X POST "https://app.mandate.md/api/scan-telemetry" \
    -H "Content-Type: application/json" \
    -d "{\"filesScanned\":${TOTAL_FILES},\"unprotected\":${UNPROTECTED_COUNT},\"protected\":${PROTECTED_COUNT},\"ts\":$(date +%s),\"source\":\"plugin\"}" \
    >/dev/null 2>&1 &
fi

exit 0
