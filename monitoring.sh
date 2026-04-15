#!/bin/bash

# Folder log tetap
LOG_DIR="/home/andi/log_monitoring"

# Gunakan environment HOST_IP yang diberikan oleh playbook
LOGFILE="${LOG_DIR}/system_monitor_${HOST_IP}.log"

# Pastikan folder log ada
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"

echo "===============================================================" > "$LOGFILE"
echo "                  SYSTEM RESOURCE CHECK                        " >> "$LOGFILE"
echo "Host IP: $HOST_IP" >> "$LOGFILE"
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOGFILE"
echo "===============================================================" >> "$LOGFILE"
echo "" >> "$LOGFILE"

# 1. Overall CPU, Memory & Swap
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
mem_used=$(free | awk '/Mem:/ {printf("%.2f"), $3/$2 * 100}')
swap_used=$(free | awk '/Swap:/ {printf("%.2f"), $3/$2 * 100}')

echo ">>> Overall CPU & Memory Usage:" >> "$LOGFILE"
echo "CPU Usage    : $cpu_usage %" >> "$LOGFILE"
echo "Memory Usage : $mem_used %" >> "$LOGFILE"
echo "Swap Usage   : $swap_used %" >> "$LOGFILE"
echo "" >> "$LOGFILE"

# 2. Top 10 CPU processes
echo ">>> Top 10 processes by CPU usage:" >> "$LOGFILE"
printf "%-8s %-8s %-40s %-8s %-8s\n" "PID" "PPID" "COMMAND" "%MEM" "%CPU" >> "$LOGFILE"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n11 | tail -n10 | \
while read pid ppid cmd mem cpu; do
    printf "%-8s %-8s %-40s %-8s %-8s\n" "$pid" "$ppid" "$cmd" "$mem" "$cpu" >> "$LOGFILE"
done
echo "" >> "$LOGFILE"

# 3. Top 10 Memory processes
echo ">>> Top 10 processes by Memory usage:" >> "$LOGFILE"
printf "%-8s %-8s %-40s %-8s %-8s\n" "PID" "PPID" "COMMAND" "%MEM" "%CPU" >> "$LOGFILE"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n11 | tail -n10 | \
while read pid ppid cmd mem cpu; do
    printf "%-8s %-8s %-40s %-8s %-8s\n" "$pid" "$ppid" "$cmd" "$mem" "$cpu" >> "$LOGFILE"
done
echo "" >> "$LOGFILE"

# 4. Disk Usage
echo ">>> Disk Usage per Partition:" >> "$LOGFILE"
printf "%-20s %-8s %-10s %-10s %-10s %-8s %-20s\n" "Filesystem" "Type" "Size" "Used" "Avail" "Use%" "Mount" >> "$LOGFILE"
df -h --output=source,fstype,size,used,avail,pcent,target | tail -n +2 | \
while read fs type size used avail usep mount; do
    printf "%-20s %-8s %-10s %-10s %-10s %-8s %-20s\n" "$fs" "$type" "$size" "$used" "$avail" "$usep" "$mount" >> "$LOGFILE"
done
echo "" >> "$LOGFILE"

# 5. Docker Containers
if command -v docker >/dev/null 2>&1; then
    echo ">>> Docker Running Containers and Uptime:" >> "$LOGFILE"
    printf "%-20s %-12s %-12s %-20s\n" "CONTAINER" "STATUS" "UPTIME" "IMAGE" >> "$LOGFILE"
    docker ps --format "{{.Names}} {{.Status}} {{.Image}}" | \
    while read name status image; do
        uptime=$(echo "$status" | awk '{print $2,$3,$4,$5}')
        printf "%-20s %-12s %-12s %-20s\n" "$name" "$status" "$uptime" "$image" >> "$LOGFILE"
    done
else
    echo "Docker not installed or not running." >> "$LOGFILE"
fi
echo "" >> "$LOGFILE"

# 6. Top 5 services by Memory
echo ">>> Top 5 services by Memory:" >> "$LOGFILE"
printf "%-8s %-20s\n" "MEM%" "SERVICE" >> "$LOGFILE"
ps -eo comm,%mem --sort=-%mem | awk 'NR>1{arr[$1]+=$2} END {for(i in arr) print arr[i], i}' | \
sort -nr | head -n5 | while read mem svc; do
    printf "%-8s %-20s\n" "$mem" "$svc" >> "$LOGFILE"
done
echo "" >> "$LOGFILE"

# 7. Top 5 services by CPU
echo ">>> Top 5 services by CPU:" >> "$LOGFILE"
printf "%-8s %-20s\n" "CPU%" "SERVICE" >> "$LOGFILE"
ps -eo comm,%cpu --sort=-%cpu | awk 'NR>1{arr[$1]+=$2} END {for(i in arr) print arr[i], i}' | \
sort -nr | head -n5 | while read cpu svc; do
    printf "%-8s %-20s\n" "$cpu" "$svc" >> "$LOGFILE"
done
echo "" >> "$LOGFILE"

# 8. Top 10 largest log files in /var/log
echo ">>> Top 10 largest log files in /var/log:" >> "$LOGFILE"
printf "%-10s %-50s\n" "SIZE" "FILE" >> "$LOGFILE"
find /var/log -type f -exec du -h {} + 2>/dev/null | sort -hr | head -n10 | \
while read size file; do
    printf "%-10s %-50s\n" "$size" "$file" >> "$LOGFILE"
done

echo "===============================================================" >> "$LOGFILE"
