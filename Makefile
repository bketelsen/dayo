.PHONY: default
default: images

.PHONY: images
images:
	mkosi build

clean:
	rm -rf mkosi.output
	rm -rf mkosi.cache

iso:
	sudo ./scripts/convert-img-to-iso.sh mkosi.output/DayoServerInstaller_202508262004_x86-64.raw

start:
	incus start dayo || true

console: start
	incus console --type=vga dayo

dd:
	mkosi burn --force /dev/nvme1n1