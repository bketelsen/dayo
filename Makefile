.PHONY: default
default: images

.PHONY: images
images:
	mkosi -B

clean:
	rm -rf mkosi.output
	rm -rf mkosi.cache

iso:
	sudo ./scripts/convert-img-to-iso.sh mkosi.output/DayoServerInstaller_202508262004_x86-64.raw

copy:
	scp mkosi.output/*.efi bjk@10.0.1.47:~/dayo/
	scp mkosi.output/*.raw bjk@10.0.1.47:~/dayo/