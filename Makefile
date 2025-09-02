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
