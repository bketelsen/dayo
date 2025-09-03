# Justfile
# Converted from Makefile

# Default recipe
default: images

images:
  mkosi build

clean:
  mkosi clean -ff

start:
  incus start dayo || true

console: start
  incus console --type=vga dayo

launch:
  ./scripts/launch.sh

kill:
  ./scripts/kill.sh
