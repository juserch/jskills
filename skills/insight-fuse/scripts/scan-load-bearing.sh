#!/usr/bin/env bash
# scan-load-bearing.sh — Detect LOAD_BEARING sources for Check 18 (v3.4)
#
# Usage:   scan-load-bearing.sh <merged-report.md>
# Output:  Plain text — LOAD_BEARING list, one source per block, to stdout.
# Exit:    0 always (advisory; main agent decides blocking).
#
# Algorithm:
#   1. Walk the file; track current `## ` section number.
#   2. Extract every `[Name](url)` inline citation; key by host.
#   3. For each section, note whether it contains any line starting with `[F]`
#      (proxy for "this section makes quantitative claims").
#   4. A source is LOAD_BEARING iff:
#        - host appears in ≥ 2 distinct `## ` sections, AND
#        - at least 1 of those sections contains an `[F]` line.
#   5. Print one block per LOAD_BEARING source with sections + names seen.
#
# Dependencies: bash 4+, awk, grep, sed (POSIX). No yq/jq/python.

set -euo pipefail

REPORT="${1:-}"
if [[ -z "$REPORT" || ! -f "$REPORT" ]]; then
    echo "Usage: $0 <merged-report.md>" >&2
    echo "  Provide a single merged markdown file (cat multi-file outputs first)." >&2
    exit 2
fi

# ---- Pass 1: extract (host, section_id, name, has_fact_in_section) tuples ----
# Output format per line, tab-separated:
#   <host>\t<section_id>\t<section_title>\t<name>

TUPLES=$(awk '
BEGIN { sec_id = 0; sec_title = "(preamble)"; }

# Section header
/^##[[:space:]]/ {
    # Skip inside fenced code blocks
    if (in_fence) next
    sec_id++
    sec_title = $0
    sub(/^##[[:space:]]+/, "", sec_title)
    next
}

# Track fenced code blocks (avoid extracting inside them)
/^```/ { in_fence = !in_fence; next }
in_fence { next }

# Mark whether this section contains an [F] line (output as separate signal lines)
/^\[F\]/ { print "FACT_LINE\t" sec_id }

# Extract every [Name](url) on this line
{
    line = $0
    while (match(line, /\[[^]]+\]\([^)]+\)/)) {
        cite = substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)

        # Parse name and url
        name_end = index(cite, "](")
        if (name_end == 0) continue
        name = substr(cite, 2, name_end - 2)
        url = substr(cite, name_end + 2)
        sub(/\)[[:space:]]*$/, "", url)
        sub(/[){]+.*$/, "", url)

        # Skip non-http (anchors, relative paths)
        if (url !~ /^https?:\/\//) continue

        # Extract host
        host = url
        sub(/^https?:\/\//, "", host)
        sub(/\/.*$/, "", host)
        sub(/^www\./, "", host)
        if (host == "") continue

        print "CITATION\t" host "\t" sec_id "\t" sec_title "\t" name
    }
}
' "$REPORT")

if [[ -z "$TUPLES" ]]; then
    echo "scan-load-bearing: no inline citations found in $REPORT"
    exit 0
fi

# ---- Pass 2: aggregate ----
# Sections containing [F]:
FACT_SECTIONS=$(echo "$TUPLES" | awk -F'\t' '$1 == "FACT_LINE" { print $2 }' | sort -u)

# Per-host: distinct section IDs + names seen
LOAD_BEARING_REPORT=$(echo "$TUPLES" \
    | awk -F'\t' '$1 == "CITATION" { print $2 "\t" $3 "\t" $4 "\t" $5 }' \
    | sort -u \
    | awk -F'\t' -v fact_secs="$FACT_SECTIONS" '
        BEGIN {
            n = split(fact_secs, fs, "\n")
            for (i = 1; i <= n; i++) is_fact[fs[i]] = 1
        }
        {
            host = $1; sec = $2; title = $3; name = $4
            sec_count[host]++
            if (!(host SUBSEP sec in seen_sec)) {
                seen_sec[host SUBSEP sec] = 1
                distinct_sec[host]++
                sec_list[host] = sec_list[host] (sec_list[host] ? ", " : "") "§" sec " (" title ")"
                if (sec in is_fact) fact_section_count[host]++
            }
            if (!(host SUBSEP name in seen_name)) {
                seen_name[host SUBSEP name] = 1
                name_list[host] = name_list[host] (name_list[host] ? "; " : "") name
            }
        }
        END {
            for (h in distinct_sec) {
                if (distinct_sec[h] >= 2 && fact_section_count[h] >= 1) {
                    print "LOAD_BEARING\t" h "\t" distinct_sec[h] "\t" fact_section_count[h] "\t" sec_list[h] "\t" name_list[h]
                }
            }
        }
    ' | sort -t$'\t' -k3,3rn)

# ---- Output ----
if [[ -z "$LOAD_BEARING_REPORT" ]]; then
    echo "scan-load-bearing: no LOAD_BEARING sources detected (all citations either single-section or no [F] support)"
    exit 0
fi

echo "scan-load-bearing.sh — Check 18 advisory output"
echo "Report: $REPORT"
echo "Detected $(echo "$LOAD_BEARING_REPORT" | wc -l) LOAD_BEARING source(s)"
echo
echo "$LOAD_BEARING_REPORT" | while IFS=$'\t' read -r _tag host sec_count fact_count sec_list name_list; do
    echo "---"
    echo "host: $host"
    echo "sections: $sec_count distinct ($fact_count with [F] claims)"
    echo "section_list: $sec_list"
    echo "citation_names: $name_list"
    echo "advisory: REVIEWER must verify ≥1 independent cross-validation source"
    echo "          (independent issuer + independent method + independent timeframe)."
    echo "          If unreplaceable: insert > [SINGLE_SOURCE_RISK]: ... in affected sections."
done
echo "---"
exit 0
