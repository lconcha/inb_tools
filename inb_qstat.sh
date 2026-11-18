#!/bin/bash
#
# myqstat.sh [user]
#
# Pretty summary of SGE jobs for a user (default: $USER): counts by state,
# running jobs by name, slots-per-node usage, and any jobs in error.

u=${1:-$USER}
tmp=$(mktemp /tmp/myqstat.XXXXXX) || exit 1
trap 'rm -f "$tmp"' EXIT

SGE_LONG_QNAMES=-1 qstat -u "$u" -g d >"$tmp" 2>/dev/null

if [[ -t 1 ]]; then
    bold=$'\e[1m'; dim=$'\e[2m'; reset=$'\e[0m'
    cyan=$'\e[36m'; yellow=$'\e[33m'; red=$'\e[31m'; green=$'\e[32m'
else
    bold=; dim=; reset=; cyan=; yellow=; red=; green=
fi

total=$(awk 'NR>2' "$tmp" | wc -l)

echo "${bold}${cyan}== qstat summary for ${u}  ($(date '+%Y-%m-%d %H:%M:%S'))${reset}"

if [[ "$total" -eq 0 ]]; then
    echo "${dim}  No jobs queued or running.${reset}"
    exit 0
fi

echo
echo "${bold}-- Totals by state --${reset}"
echo "  total: $total"
awk 'NR>2{c[$5]++} END{for (s in c) printf "  %-4s %d\n", s, c[s]}' "$tmp" | sort

echo
echo "${bold}-- Running jobs (by name) --${reset}"
awk 'NR>2 && $5 ~ /r/ {c[$3]++} END{for (j in c) printf "  %-30s %d\n", j, c[j]}' "$tmp" | sort

echo
echo "${bold}-- Slots in use per node --${reset}"
node_tbl=$(awk 'NR>2 && $8 ~ /@/ {
        split($8, q, "@"); host = q[2]; sub(/\..*$/, "", host)
        slots[host] += $9; jobs[host]++
    }
    END { for (h in slots) printf "%s\t%d\t%d\n", h, slots[h], jobs[h] }' "$tmp" | sort -t$'\t' -k2,2 -nr)

if [[ -z "$node_tbl" ]]; then
    echo "${dim}  No jobs currently running.${reset}"
else
    echo "$node_tbl" | awk -F'\t' -v g="$green" -v r="$reset" \
        '{printf "  %s%-22s%s %4d slots  (%d job%s)\n", g, $1, r, $2, $3, ($3==1?"":"s")}'
    node_count=$(echo "$node_tbl" | wc -l)
    slot_total=$(echo "$node_tbl" | awk -F'\t' '{s+=$2} END{print s+0}')
    cluster_total=$(qstat -g c 2>/dev/null | awk 'NR>2 && $1=="all.q"{print $6}')
    nodes_available=$(qstat -f 2>/dev/null | awk '/^all\.q@/{ if (NF<6 || $6 !~ /[duE]/) c++ } END{print c+0}')
    pct=""
    if [[ -n "$cluster_total" && "$cluster_total" -gt 0 ]]; then
        pct=$(awk -v u="$slot_total" -v c="$cluster_total" 'BEGIN{printf " (%.1f%% of %d cluster slots)", u*100/c, c}')
    fi
    printf "  %s%-22s %4d slots across %d/%d available node%s%s%s\n" \
        "$bold" "TOTAL" "$slot_total" "$node_count" "$nodes_available" "$([[ $nodes_available == 1 ]] && echo '' || echo s)" "$pct" "$reset"
fi

errs=$(awk 'NR>2 && $5 ~ /E/' "$tmp")
if [[ -n "$errs" ]]; then
    echo
    echo "${bold}${red}-- Errors --${reset}"
    echo "$errs"
fi
