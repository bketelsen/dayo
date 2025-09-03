#!/usr/bin/env bash
set -euo pipefail

incus init dayo --empty --vm
incus config device override dayo root size=50GiB
incus config set dayo limits.cpu=4 limits.memory=8GiB
incus config set dayo security.secureboot=false

incus config device add dayo install disk source=/home/bjk/projects/mkosistuff/dayo/mkosi.output/DayoServer_202509031113_x86-64.raw boot.priority=90
incus start dayo --console=vga