#!/bin/bash

# Go to Wazuh base directory
LOCAL_DIR="$(dirname "$0")"
cd "$LOCAL_DIR/../" || exit 1
BASE_DIR="$(pwd)"

LOG_FILE="${BASE_DIR}/../logs/active-responses.log"

# Read JSON input from Wazuh (one line)
read INPUT_JSON

# Extract file path and command from JSON
FILENAME=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.data.virustotal.source.file')
COMMAND=$(echo "$INPUT_JSON" | jq -r '.command')

# Only act for "add" (when AR is triggered)
if [ "$COMMAND" = "add" ]; then
  # Ask wazuh-execd if we can continue (standard AR handshake)
  printf '{"version":1,"origin":{"name":"remove-threat","module":"active-response"},"command":"check_keys","parameters":{"keys":[]}}\n'

  read RESPONSE
  DECISION=$(echo "$RESPONSE" | jq -r '.command')

  if [ "$DECISION" != "continue" ]; then
    echo "$(date '+%Y/%m/%d %H:%M:%S') remove-threat.sh: Aborted by execd: $INPUT_JSON" >> "$LOG_FILE"
    exit 0
  fi
fi
