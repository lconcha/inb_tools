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
echo "${bold}-- Slots & RAM in use per node --${reset}"

# job-id -> peak RAM (maxvmem, normalized to GB) for this user, from live scheduler usage
mem_by_job=$(qstat -j '*' 2>/dev/null | awk -v u="$u" '
    /^job_number:/ {job=$2}
    /^owner:/ {owner=$2}
    /^usage/ && owner==u && match($0, /maxvmem=[0-9.]+[A-Za-z]*/) {
        val = substr($0, RSTART+8, RLENGTH-8)
        unit = substr(val, length(val), 1)
        num = substr(val, 1, length(val)-1) + 0
        if (unit=="T") num *= 1024
        else if (unit=="M") num /= 1024
        else if (unit=="K") num /= 1024*1024
        printf "%s\t%.2f\n", job, num
    }')

# host -> total RAM (GB), from live host status
mem_by_host=$(qhost 2>/dev/null | awk '
    NR>3 && $1!="global" && $8!="-" {
        host=$1; val=$8
        unit = substr(val, length(val), 1)
        num = substr(val, 1, length(val)-1) + 0
        if (unit=="T") num *= 1024
        else if (unit=="M") num /= 1024
        else if (unit=="K") num /= 1024*1024
        printf "%s\t%.1f\n", host, num
    }')

node_tbl=$(awk -v memlist="$mem_by_job" -v hostmemlist="$mem_by_host" '
    BEGIN {
        n = split(memlist, lines, "\n")
        for (i=1;i<=n;i++) { split(lines[i], kv, "\t"); memof[kv[1]] = kv[2] }
        m = split(hostmemlist, hlines, "\n")
        for (i=1;i<=m;i++) { split(hlines[i], hkv, "\t"); hostmemtot[hkv[1]] = hkv[2] }
    }
    NR>2 && $8 ~ /@/ {
        split($8, q, "@"); host = q[2]; sub(/\..*$/, "", host)
        slots[host] += $9; jobs[host]++
        ram[host] += memof[$1]
        seen[host] = 1
    }
    END { for (h in seen) printf "%s\t%d\t%d\t%.1f\t%.1f\n", h, slots[h], jobs[h], ram[h], hostmemtot[h]+0 }' "$tmp" | sort -t$'\t' -k2,2 -nr)

if [[ -z "$node_tbl" ]]; then
    echo "${dim}  No jobs currently running.${reset}"
else
    echo "$node_tbl" | awk -F'\t' -v g="$green" -v r="$reset" -v rd="$red" \
        '{pct = ($5>0) ? $4*100/$5 : 0
          rc = (pct>=90) ? rd : ""
          printf "  %s%-22s%s %4d slots  (%d job%s)  %s%6.1f / %5.1f GB RAM (%.0f%%)%s\n", g, $1, r, $2, $3, ($3==1?"":"s"), rc, $4, $5, pct, r}'
    node_count=$(echo "$node_tbl" | wc -l)
    slot_total=$(echo "$node_tbl" | awk -F'\t' '{s+=$2} END{print s+0}')
    ram_total=$(echo "$node_tbl" | awk -F'\t' '{s+=$4} END{print s+0}')
    node_ram_cap_total=$(echo "$node_tbl" | awk -F'\t' '{s+=$5} END{print s+0}')
    cluster_total=$(qstat -g c 2>/dev/null | awk 'NR>2 && $1=="all.q"{print $6}')
    cluster_ram_total=$(echo "$mem_by_host" | awk -F'\t' '{s+=$2} END{print s+0}')
    nodes_available=$(qstat -f 2>/dev/null | awk '/^all\.q@/{ if (NF<6 || $6 !~ /[duE]/) c++ } END{print c+0}')
    pct=""
    if [[ -n "$cluster_total" && "$cluster_total" -gt 0 ]]; then
        pct=$(awk -v u="$slot_total" -v c="$cluster_total" 'BEGIN{printf " (%.1f%% of %d cluster slots)", u*100/c, c}')
    fi
    rampct=""
    if [[ -n "$cluster_ram_total" ]] && awk -v c="$cluster_ram_total" 'BEGIN{exit !(c>0)}'; then
        rampct=$(awk -v u="$ram_total" -v c="$cluster_ram_total" 'BEGIN{printf " (%.1f%% of %.1f GB cluster RAM)", u*100/c, c}')
    fi
    ram_color=""
    if awk -v c="$node_ram_cap_total" 'BEGIN{exit !(c>0)}' && \
       awk -v u="$ram_total" -v c="$node_ram_cap_total" 'BEGIN{exit !(u*100/c>=90)}'; then
        ram_color="$red"
    fi
    printf "  %s%-22s %4d slots across %d/%d available node%s  %s%6.1f / %.1f GB RAM%s%s%s%s\n" \
        "$bold" "TOTAL" "$slot_total" "$node_count" "$nodes_available" "$([[ $nodes_available == 1 ]] && echo '' || echo s)" "$ram_color" "$ram_total" "$node_ram_cap_total" "$reset$bold" "$pct" "$rampct" "$reset"
fi

errs=$(awk 'NR>2 && $5 ~ /E/' "$tmp")
if [[ -n "$errs" ]]; then
    echo
    echo "${bold}${red}-- Errors --${reset}"
    echo "$errs"
fi
