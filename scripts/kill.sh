#!/usr/bin/env bash
set -euo pipefail

# kill and remove the instance

incus stop --force dayo || true
incus rm dayo || true