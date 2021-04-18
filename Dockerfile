FROM lsiobase/alpine:3.13

# Container labels
LABEL maintainer="Hummingbird the Second"

# Arguments Settings
ARG TZ=UTC

# Set Links
ARG CROSSSEED_URL=https://github.com/BC44/Cross-Seed-AutoDL/archive/master.tar.gz

# Environments
ENV JACKETT_URL="" \
  JACKETT_KEY="" \
  TRACKER_LIST="" \
  SEARCH_DIR='/downloads' \
  TORRENT_DIR='/torrents' \
  IGNORE_PATTERN='' \
  DELAY=10 \
  CONFIG_PATH='/config/autotorrent/autotorrent.conf' \
  AT_OUTPUT_DIR='/config/autotorrent' \
  NOTIF_OPTION='off' \
  NOTIF_CONFIG_PATH='/config/apprise/config.txt' \
  SCAN_ALL_HOUR='4' \
  SCAN_ALL_MIN=""  \
  SCAN_WEEK_DAY=""

# Installs
RUN echo -e '\n'"[ Install dockerfile dependencies ]" && \
  apk add --no-cache --virtual=dockerfile-dependencies \
    curl \
    g++ \
    gcc \
    make \
    libressl-dev \
    musl-dev \
    libffi-dev \
    python3-dev \
    cargo \
    py3-pip && \
  \
  echo -e '\n'"[ Install packages ]" && \
  apk add --no-cache \
    jq \
    python3 \
    py3-six \
    py3-requests \
    py3-cryptography \
    grep && \
  \
  echo -e '\n'"[ Update pip ]" && \
  pip3 install -U pip && \
  \
  echo -e '\n'"[ Install AutoTorrent ]" && \
  pip3 install --no-cache-dir -U \
    autotorrent && \
  \
  echo -e '\n'"[ Download Cross-Seed-AutoDL ]" && \
  mkdir -p /app/cross-seed && \
  curl -o \
    /tmp/cross-seed.tar.gz -L "${CROSSSEED_URL}" && \
  tar xf \
    /tmp/cross-seed.tar.gz -C \
    /app/cross-seed --strip-components=1 && \
  \
  echo -e '\n'"[ Install Cross-Seed-AutoDL required libraries ]" && \
  pip3 install --no-cache-dir -U -r \
    /app/cross-seed/requirements.txt && \
  \
  echo -e '\n'"[ Link Cross-Seed-AutoDL ]" && \
  echo -e '#!/bin/bash \n python3 /app/cross-seed/CrossSeedAutoDL.py "$@"' \
    > /usr/bin/cross-seed && \ 
  chmod +x /usr/bin/cross-seed && \
  \
  echo -e '\n'"[ Link auto-cross-seed ]" && \
  echo -e '#!/bin/bash \n bash /app/auto-cross-seed.sh "$@"' \
    > /usr/bin/auto-cross-seed && \ 
  chmod +x /usr/bin/auto-cross-seed && \
  \
  echo -e '\n'"[ Install apprise ]" && \
  pip3 install --no-cache-dir -U apprise && \
  \
  echo -e '\n'"[ Creates folder(s) ]" && \
  mkdir -vp \
    /script &&\
  \
  echo -e '\n'"[ Cleanup ]"&& \
  apk del --purge \
    dockerfile-dependencies && \
  rm -rf \
    /root/.cache \
    /tmp/*

# Add local files
COPY root/ /
COPY auto-cross-seed.sh /app/

# Add execute mode to bash scripts
RUN echo -e '\n'"[ Add execute mode to bash scripts ]" && \
  chmod +x /defaults/*.sh && \
  chmod +x /app/*.sh

# ports and volumes
VOLUME /config
