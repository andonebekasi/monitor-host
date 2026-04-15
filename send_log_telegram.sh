#!/bin/bash

BOT_TOKEN="isi"
CHAT_ID="isi"  # Chat ID channel
LOG_DIR="./logs"

for host_dir in "$LOG_DIR"/*/; do
    for log_file in "$host_dir"*.log; do
        HOSTNAME=$(basename "$host_dir")
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
            -F chat_id="$CHAT_ID" \
            -F document=@"$log_file" \
            -F caption="System monitor log from host: $HOSTNAME"
    done
done
