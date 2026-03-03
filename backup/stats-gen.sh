#!/bin/bash
CPU=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {printf "%.1f", usage}')
RAM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
RAM_FREE=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024)}')
RAM_USED=$((RAM_TOTAL - RAM_FREE))
DISK_TOTAL=$(df / | tail -1 | awk '{printf "%.1f", $2/1024/1024}')
DISK_USED=$(df / | tail -1 | awk '{printf "%.1f", $3/1024/1024}')
DISK_PCT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
UPTIME_SECS=$(cat /proc/uptime | awk '{print int($1)}')
UPTIME_HRS=$(( (UPTIME_SECS%86400)/3600 ))
UPTIME_MINS=$(( (UPTIME_SECS%3600)/60 ))
UPTIME="${UPTIME_HRS}h ${UPTIME_MINS}m"
LOAD=$(cat /proc/loadavg | awk '{print $1}')

# --- Battery Status ---
BAT_PCT=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "0")
BAT_STAT=$(cat /sys/class/power_supply/battery/status 2>/dev/null || echo "Unknown")

# --- Thermals ---
# Battery (Tenths of a degree)
BAT_RAW=$(cat /sys/class/power_supply/battery/temp 2>/dev/null || echo "0")
BAT_TEMP=$(awk "BEGIN {printf \"%.1f\", $BAT_RAW/10}")

# CPU, GPU, and Chassis (Millidegrees)
CPU_RAW=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "0")
CPU_TEMP=$(awk "BEGIN {printf \"%.1f\", $CPU_RAW/1000}")

GPU_RAW=$(cat /sys/class/thermal/thermal_zone3/temp 2>/dev/null || echo "0")
GPU_TEMP=$(awk "BEGIN {printf \"%.1f\", $GPU_RAW/1000}")

CHAS_RAW=$(cat /sys/class/thermal/thermal_zone5/temp 2>/dev/null || echo "0")
CHAS_TEMP=$(awk "BEGIN {printf \"%.1f\", $CHAS_RAW/1000}")

# Output updated JSON
echo "{\"cpu\":\"${CPU}\",\"ram_used\":${RAM_USED},\"ram_total\":${RAM_TOTAL},\"disk_used\":\"${DISK_USED}\",\"disk_total\":\"${DISK_TOTAL}\",\"disk_pct\":\"${DISK_PCT}\",\"uptime\":\"${UPTIME}\",\"load\":\"${LOAD}\",\"cpu_info\":\"Exynos 9820 · ARM64\",\"battery_pct\":${BAT_PCT},\"battery_status\":\"${BAT_STAT}\",\"bat_temp\":\"${BAT_TEMP}\",\"cpu_temp\":\"${CPU_TEMP}\",\"gpu_temp\":\"${GPU_TEMP}\",\"chas_temp\":\"${CHAS_TEMP}\"}"

