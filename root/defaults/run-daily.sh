#!/bin/bash

# ------------------------------------------------
# Daily difference:
# - Only check new file (younger than 24h)
# - Don't record any history (if the file is not completed yet)
# ------------------------------------------------

# Entry for docker logger
cat << EOF
===================================================================
    DAILY RUN OF AUTO-CROSS-SEED
===================================================================
Started: $(date)

---------------------------------------------------------
EOF

# Workaround to use the temp SearchHistory.json
rm /app/cross-seed/SearchHistory.json
tempDir="$(mktemp -d)"
touch "${tempDir}/SearchHistory.json"
ln -s "${tempDir}/SearchHistory.json" /app/cross-seed/SearchHistory.json

# Workaround to save the Cross-Seed-AutoDL
cd /config/cross-seed/ || exit

# Docker container parameters
auto-cross-seed \
    --torrent-dir "${TORRENT_DIR}" \
    --ignore-pattern "${IGNORE_PATTERN}" \
    --jackett-url "${JACKETT_URL}" \
    --jackett-key "${JACKETT_KEY}" \
    --delay "${DELAY}" \
    --trackers "${TRACKER_LIST}" \
    --search-dir "${SEARCH_DIR}" \
    --filter-old 'day' \
    --config-path "${CONFIG_PATH}" \
    --autotorrent-output-dir "${AT_OUTPUT_DIR}" \
    --notification "${NOTIF_OPTION}" "${NOTIF_CONFIG_PATH}"

# Put back SearchHistory.json as normal
rm /app/cross-seed/SearchHistory.json
rm -rf "${tempDir}"
ln -s /config/cross-seed/SearchHistory.json /app/cross-seed/SearchHistory.json

# Entry for docker logger
cat << EOF
---------------------------------------------------------

Finished: $(date)
===================================================================
EOF
