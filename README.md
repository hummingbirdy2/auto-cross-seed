# Auto Cross-Seed

Bash script to search and add cross-seedable torrents (for Movies and TV).

## Features

- Make [AutoTorrent](https://github.com/JohnDoee/autotorrent) and [Cross-Seed-AutoDL](https://github.com/BC44/Cross-Seed-AutoDL) work together.
- Can filter folder by age and pattern.
- Generate logs.
- Monitor failure of AutoTorrent and Cross-Seed-AutoDL.
- Search can be skipped to use AutoTorrent alone with all other features.
- Can send kind notifications to almost all platform (thanks apprise).

### Docker features

And for lazy people like me, I provide a docker container with every things setup.

- An all in one container embedding [AutoTorrent](https://github.com/JohnDoee/autotorrent) and [Cross-Seed-AutoDL](https://github.com/BC44/Cross-Seed-AutoDL).
- Can be build on ARM.
- Running periodically the script. By default, `auto-cross-seed` will be run one time a week for all files and every other days for files younger than 24h". (Cron jobs can be modified)
- `auto-cross-seed.sh` outputs are available via `docker logs`.

## Usage

```shell
Usage:
   auto-cross-seed.sh -T [TORRENT_DIR] -u [JACKETT_URL] -k [JACKETT_KEY] -t [TRACKER_LIST] 
                      -s [SEARCH_DIR] -c [CONFIG_PATH] (-h) (-K) (-d [DELAY]) (-N)
                      (-i [IGNORE_PATTERN]) (-o {day,week,month,none}) (-r [AT_OUTPUT_DIR])
                      (-n {off,simple,list} [NOTIF_CONFIG_PATH])
```

| Options | Arguments | Description |
|---|:---:|---|
| General options |
| `-h` / `--help` |   | Print this help text and exit. |
| `-T` / `--torrent-dir` | `'TORRENT DIR'` | Directory to store downloaded torrents. |
| `-K` / `--keep-torrent` |  | Do not remove torrent files at the end. |
| Search (cross-seed) options |
| `-N` / `--no-search` |  | Disable torrent search. |
| `-i` / `--ignore-pattern` | `'IGNORE PATTERN'` | Search will be ignored on folder strating with this pattern. |
| `-u` / `--jackett-url` | `'JACKETT URL'` | URL for your Jackett instance, including port number if needed. |
| `-k` / `--jackett-key` | `'JACKETT KEY'` | API key for your Jackett instance. |
| `-d` / `--delay` | `'DELAY'` | Pause duration [in seconds] between searches. (default: 10) |
| `-t` / `--trackers` | `'TRACKER LIST'` | Comma-separated list of Jackett tracker ids to search. See [Cross-Seed-AutoDL documentation](https://github.com/BC44/Cross-Seed-AutoDL#cross-seed-autodl). |
| `-s` / `--search-dir` | `'SEARCH DIRECTORY'` | Comma-separated list of folders where movies or tv shows are stored. |
| `-o` / `--filter-old` | `day` / `week` / `month` | Filter file older than a "day", a "week" or a "month". |
| | `none` | "none" disable the filter (default: none) |
| Add torrent (autotorrent) options: |
| `-c` / `--config-path` | `'CONFIG PATH'` | Path to the AutoTorrent config file. See [AutoTorrent documentation](https://github.com/JohnDoee/autotorrent#configuration). |
| `-r` / `--autotorrent-output-dir` | `'AUTOTORRENT OUTPUT DIRECTORY'` | Directory to write AutoTorrent output. (default: temp folder) |
| Notification (apprise) option: |
| `-n` / `--notification` | `'NOTIFICATION MODE' 'NOTIFICATION CONFIGURATION PATH'` | Notification parameters |
| | Notification mode: |
| | `off` | Disabled. (default) |
| | `simple` | Send the number of added torrents. |
| | `list` | Send the name of each torrent. |
| | Configuration file path: |
| | `'NOTIFICATION CONFIGURATION PATH'` | Only requested, if notification are enabled. Should be in TEXT or YAML format. See [Apprise wiki](https://github.com/caronc/apprise/wiki/config). |

## Requires

- [RTorrent](http://rakshasa.github.io/rtorrent/), [Deluge](https://www.deluge-torrent.org/), [qBittorrent](https://www.qbittorrent.org/download.php) or [Transmission](http://rakshasa.github.io/rtorrent/) for `AutoTorrent`
- [Jackett](https://github.com/Jackett/Jackett) for `Cross-Seed-AutoDL`

## Dependencies

- `bash` :nerd_face:
- [AutoTorrent](https://github.com/JohnDoee/autotorrent) by JohnDoee (thanks !), variable path: `cross_seed`
- [Cross-Seed-AutoDL](https://github.com/BC44/Cross-Seed-AutoDL) by BC44 (thanks !), variable path: `auto_torrent`
- [Apprise](https://github.com/caronc/apprise) by caronc (thanks !) [only if the notification is enabled]
- `mktemp`, `tee`, `printf`, `grep`

## Configurations

### auto-cross-seed

This lines should be edited to match with your system requirements:
```bash
python3='python3' #-> call for Python 3
cross_seed='/app/cross-seed/CrossSeedAutoDL.py' #-> call for Cross-Seed-AutoDL
auto_torrent='/usr/bin/autotorrent' #-> call for AutoTorrent
```

### AutoTorrent

`AutoTorrent` should be configured, [link to the official documentation](https://github.com/JohnDoee/autotorrent#configuration).

### Apprise

`Apprise` need a configuration file, [link to the official documentation](https://github.com/caronc/apprise/wiki/config). Only if the notification is enabled.

## Examples

### Minimal setup

```shell
./auto-cross-seed.sh \
    --torrent-dir "/download/_autotorrent" \
    --jackett-url "http://127.0.0.1:9117" \
    --jackett-key "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
    --trackers "beyond-hd-oneurl,blutopia,hdtorrents,uhdbits" \
    --search-dir "/download/torrent" \
    --config-path "/config/autotorrent/rutorrent.conf"
```

### Full setup

```shell
./auto-cross-seed.sh \
    --torrent-dir "/download/torrent/_autotorrent/torrent" \
    --keep-torrent \
    --ignore-pattern "_" \
    --jackett-url "http://127.0.0.1:9117" \
    --jackett-key "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
    --delay "5" \
    --trackers "beyond-hd-oneurl,blutopia,hdtorrents,uhdbits" \
    --search-dir "/download/torrent/movie,/download/torrent/tv,/download/torrent/cartoon" \
    --filter-old 'week' \
    --config-path "/config/autotorrent/rutorrent.conf" \
    --autotorrent-output-dir "/config/autotorrent" \
    --notification "list"
```

## Docker

An All-in-One docker container to search and add cross-seedable torrents (for Movies and TV) based on [lsiobase/alpine:3.13](https://github.com/linuxserver/docker-baseimage-alpine).

[![badge docker hub link][badge-docker-hub]](https://hub.docker.com/r/hummingbirdy2/auto-cross-seed)
[![badge docker size][badge-docker-size]](https://hub.docker.com/r/hummingbirdy2/auto-cross-seed)

[![badge github link][badge-github]](https://github.com/hummingbirdy2/auto-cross-seed)
[![badge licence][badge-license]](https://github.com/hummingbirdy2/auto-cross-seed/blob/master/LICENSE)
[![badge release][badge-release]](https://github.com/hummingbirdy2/auto-cross-seed/releases)

### Docker Usage

#### docker-compose

```yaml
---
version: "2.1"
services:
  auto-cross-seed:
    image: hummingbirdy2/auto-cross-seed:latest
    container_name: auto-cross-seed
    restart: unless-stopped
    environment:
      - PUID=1000 #optional
      - PGID=1000 #optional
      - TZ=Europe/London #optional
      - JACKETT_URL=http://jackett:9117
      - JACKETT_KEY=<Jackett API key>
      - TRACKER_LIST=beyond-hd-oneurl,blutopia,hdtorrents,uhdbits
      - SEARCH_DIR=/download/torrent/movie,/download/torrent/tv,/download/torrent/cartoon
      - TORRENT_DIR=/download/_autotorrent #optional
      - IGNORE_PATTERN=_ #optional
      - DELAY=5 #optional
      - CONFIG_PATH=/config/autotorrent/rutorrent.conf #optional
      - AT_OUTPUT_DIR=/config/autotorrent #optional
      - NOTIF_OPTION=list #optional
      - NOTIF_CONFIG_PATH=/config/apprise/config.txt #optional
      - SCAN_WEEK_DAY=Thu #optional
      - SCAN_ALL_HOUR=4 #optional
      - SCAN_ALL_MIN=0 #optional
    volumes:
      - "<path to config>:/config"
      - "<path to download>:/download"
```

#### docker cli

```shell
docker run -d \
  --name=auto-cross-seed \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/London \
  -e JACKETT_URL=http://jackett:9117 \
  -e JACKETT_KEY=<Jackett API key> \
  -e TRACKER_LIST=beyond-hd-oneurl,blutopia,hdtorrents,uhdbits \
  -e SEARCH_DIR=/download/torrent/movie,/download/torrent/tv,/download/torrent/cartoon \
  -e TORRENT_DIR=/download/_autotorrent `#optional` \
  -e IGNORE_PATTERN=_ `#optional` \
  -e DELAY=5 `#optional` \
  -e CONFIG_PATH=/config/autotorrent/rutorrent.conf `#optional` \
  -e AT_OUTPUT_DIR=/config/autotorrent `#optional` \
  -e NOTIF_OPTION=list `#optional` \
  -e NOTIF_CONFIG_PATH=/config/apprise/config.txt `#optional` \
  -e SCAN_WEEK_DAY=Thu `#optional` \
  -e SCAN_ALL_HOUR=4 `#optional` \
  -e SCAN_ALL_MIN=0 `#optional` \
  -v <path to data>:/config \
  hummingbirdy2/auto-cross-seed:latest
```

### Parameters

Container images are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate `<external>:<internal>` respectively. For example, `-p 8080:80` would expose port `80` from inside the container to be accessible from the host's IP on port `8080` outside the container.

| Parameter | Function |
| :----: | --- |
| `-e PUID=1000` | for UserID - see below for explanation |
| `-e PGID=1000` | for GroupID - see below for explanation |
| `-e TZ=Europe/London` | Specify a timezone to use EG Europe/London. |
| `-e JACKETT_URL=http://jackett:9117` | URL for your Jackett instance, including port number if needed. |
| `-e JACKETT_KEY=<Jackett API key>` | API key for your Jackett instance. |
| `-e TRACKER_LIST=beyond-hd-oneurl,blutopia,hdtorrents,uhdbits` | Comma-separated list of Jackett tracker IDs for the research. See [Cross-Seed-AutoDL documentation](https://github.com/BC44/Cross-Seed-AutoDL#cross-seed-autodl). |
| `-e SEARCH_DIR=/download/torrent/movie,/download/torrent/tv,/download/torrent/cartoon` | Comma-separated list of folders where movies or tv shows are stored. |
| `-e TORRENT_DIR=/download/_autotorrent` | Directory to store downloaded torrents. |
| `-e IGNORE_PATTERN=_` | Search will be ignored on folder starting with this pattern. |
| `-e DELAY=5` | Pause duration [in seconds] between searches. (default: 10) |
| `-e CONFIG_PATH=/config/autotorrent/rutorrent.conf` | Path to the AutoTorrent config file. See [AutoTorrent documentation](https://github.com/JohnDoee/autotorrent#configuration). |
| `-e AT_OUTPUT_DIR=/config/autotorrent` | Directory to write AutoTorrent output. (default: temp folder) |
| `-e NOTIF_OPTION=list` | - `off`: Notification disabled. (default) <br>- `simple`: Send the number of added torrents. <br>- `list`: Send the name of each torrent. |
| `-e NOTIF_CONFIG_PATH=/config/apprise/config.txt` | Path to the apprise config file. See [Apprise wiki](https://github.com/caronc/apprise/wiki/config). |
| `-e SCAN_WEEK_DAY=Thu` | Cron job, day of the full scan. (default: Sunday) |
| `-e SCAN_ALL_HOUR=4` | Cron job, hour of each scan. (default: Random) |
| `-e SCAN_ALL_MIN=0` | Cron job, minute of each scan. (default: Random) |
| `-v /config` | Where all config files are stored. |
| `-v /downloads` | Downloads path.<br>:warning: `/download` should be edited by what ever you want in condition your torrent client see the **same path**! |

### Environment variables from files (Docker secrets)

You can set any environment variable from a file by using a special prepend `FILE__`.

As an example:

```bash
-e FILE__PASSWORD=/run/secrets/mysecretpassword
```

Will set the environment variable `PASSWORD` based on the contents of the `/run/secrets/mysecretpassword` file.

### Umask for running applications

For all of our images we provide the ability to override the default umask settings for services started within the containers using the optional `-e UMASK=022` setting.
Keep in mind umask is not chmod it subtracts from permissions based on it's value it does not add. Please read up [here](https://en.wikipedia.org/wiki/Umask) before asking for support.

### User / Group Identifiers

When using volumes (`-v` flags) permissions issues can arise between the host OS and the container, we avoid this issue by allowing you to specify the user `PUID` and group `PGID`.

Ensure any volume directories on the host are owned by the same user you specify and any permissions issues will vanish like magic.

In this instance `PUID=1000` and `PGID=1000`, to find yours use `id user` as below:

```bash
  $ id username
    uid=1000(dockeruser) gid=1000(dockergroup) groups=1000(dockergroup)
```

<!-- badges images -->
[badge-docker-hub]: https://badgen.net/badge/link/hummingbirdy2%2Fauto-cross-seed?label&icon=docker
[badge-docker-size]: https://badgen.net/docker/size/hummingbirdy2/auto-cross-seed?icon=docker&label=Image%20Size
[badge-github]: https://badgen.net/badge/link/hummingbirdy2%2Fauto-cross-seed?label&icon=github
[badge-license]: https://badgen.net/github/license/hummingbirdy2/auto-cross-seed?icon=github
[badge-release]: https://badgen.net/github/release/hummingbirdy2/auto-cross-seed?icon=github
