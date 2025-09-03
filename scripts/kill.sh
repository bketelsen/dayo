#!/usr/bin/env bash
set -euo pipefail

incus stop --force dayo || true
incus rm dayo || true