#!/bin/bash

# ------------------------------------------------
# "No search" differences:
# - Only process downloaded torrents files
# - No notifications
# ------------------------------------------------

# Entry for docker logger
cat << EOF
===================================================================
    MANUAL RUN OF AUTO-CROSS-SEED WITHOUT SEARCH
===================================================================
Started: $(date)

---------------------------------------------------------
EOF

# Docker container parameters
auto-cross-seed \
    --no-search \
    --torrent-dir "${TORRENT_DIR}" \
    --config-path "${CONFIG_PATH}" \
    --autotorrent-output-dir "${AT_OUTPUT_DIR}" \
    --notification 'off'

# Entry for docker logger
cat << EOF
---------------------------------------------------------

Finished: $(date)
===================================================================
EOF
