#!/bin/bash

# Entry for docker logger
cat << EOF
===================================================================
    FULL RUN OF AUTO-CROSS-SEED
===================================================================
Started: $(date)

---------------------------------------------------------
EOF

# Workaround to use the SearchHistory.json from the config
[[ ! -e /config/cross-seed/run-daily.sh ]] && \
	touch /config/cross-seed/SearchHistory.json
rm /app/cross-seed/SearchHistory.json
ln -s /config/cross-seed/SearchHistory.json /app/cross-seed/SearchHistory.json

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
    --config-path "${CONFIG_PATH}" \
    --autotorrent-output-dir "${AT_OUTPUT_DIR}" \
    --notification "${NOTIF_OPTION}" "${NOTIF_CONFIG_PATH}"

# Entry for docker logger
cat << EOF
---------------------------------------------------------

Finished: $(date)
===================================================================
EOF
